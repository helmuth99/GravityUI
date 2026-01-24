-- gui_spellscanner.lua
-- Spell-Scanner-System für kampfsichere Buff-Erkennung
--
-- Scannt Spell/Item → Buff-Zuordnungen außerhalb des Kampfes
-- Erkennt aktive Zustände via UNIT_SPELLCAST_SUCCEEDED (überall funktionierend)
-- Ermöglicht genaues Tracking von Schmuckstücken, Tränken und Klassen-Fähigkeiten im Kampf

local ADDON_NAME, _ = ...
local gui = GravityUI

---------------------------------------------------------------------------
-- MODULE STATE
---------------------------------------------------------------------------
local SpellScanner = {}
gui.SpellScanner = SpellScanner

-- Laufzeit-Status: aktuell aktive Buffs
-- Struktur: { [spellID] = { startTime, duration, expirationTime, source, sourceId } }
SpellScanner.activeBuffs = {}

-- Wartende Scans: im Kampf gewirkte Sprüche, die wir nach dem Kampf scannen
-- Struktur: { [spellID] = { timestamp, itemID (optional) } }
SpellScanner.pendingScanning = {}

-- Scan-Modus umschalten (explizit /guiscan)
SpellScanner.scanMode = false

-- Auto-Scan: versuche unbekannte Sprüche zu scannen wenn außerhalb Kampf gewirkt (Standard aus)
-- In Datenbank für Persistenz gespeichert
SpellScanner.autoScan = false

-- Callback für UI-Aktualisierung wenn Spell gescannt wurde (gesetzt vom Options-Panel)
SpellScanner.onScanCallback = nil

---------------------------------------------------------------------------
-- DATABASE ACCESS
-- Uses GravityUI.db.global.spellScanner for cross-character persistence
---------------------------------------------------------------------------

local function GetDB()
    if gui and gui.db and gui.db.global then
        if not gui.db.global.spellScanner then
            gui.db.global.spellScanner = {
                spells = {},  -- [castSpellID] = { buffSpellID, duration, icon, name }
                items = {},   -- [itemID] = { useSpellID, buffSpellID, duration, icon, name }
                autoScan = false,  -- Auto-scan setting (off by default)
            }
        end
        -- Lade autoScan aus DB in Laufzeit-Status
        if gui.db.global.spellScanner.autoScan ~= nil then
            SpellScanner.autoScan = gui.db.global.spellScanner.autoScan
        end
        return gui.db.global.spellScanner
    end
    return nil
end

local function GetScannedSpell(spellID)
    local db = GetDB()
    if db and db.spells and db.spells[spellID] then
        return db.spells[spellID]
    end
    return nil
end

local function GetScannedItem(itemID)
    local db = GetDB()
    if db and db.items and db.items[itemID] then
        return db.items[itemID]
    end
    return nil
end

local function SaveScannedSpell(castSpellID, data)
    local db = GetDB()
    if not db then return false end

    db.spells[castSpellID] = {
        buffSpellID = data.buffSpellID,
        duration = data.duration,
        icon = data.icon,
        name = data.name,
        scannedAt = time(),
    }
    return true
end

local function SaveScannedItem(itemID, data)
    local db = GetDB()
    if not db then return false end

    db.items[itemID] = {
        useSpellID = data.useSpellID,
        buffSpellID = data.buffSpellID,
        duration = data.duration,
        icon = data.icon,
        name = data.name,
        scannedAt = time(),
    }
    return true
end

---------------------------------------------------------------------------
-- SCANNING LOGIC
---------------------------------------------------------------------------

local function ScanSpellFromBuffs(castSpellID, itemID)
    if InCombatLockdown() then
        -- Warteschlange für Scan nach Kampf
        SpellScanner.pendingScanning[castSpellID] = {
            timestamp = GetTime(),
            itemID = itemID,
        }
        return false
    end

    -- Bereits gescannt?
    if GetScannedSpell(castSpellID) then
        return true
    end

    -- Scanne Spieler-Buffs nach kürzlich angewendeten
    local now = GetTime()
    local bestMatch = nil

    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end

        -- Secret Values in Midnight: Lesen wirft keinen Error, aber Vergleiche/Arithmetik schon
        local spellId = aura.spellId
        local duration = aura.duration
        local expirationTime = aura.expirationTime
        local icon = aura.icon
        local name = aura.name

        -- Berechne wie kürzlich dieser Buff angewendet wurde - umhülle Arithmetik mit pcall
        local buffAge = 999
        pcall(function()
            if expirationTime and duration and duration > 0 then
                buffAge = duration - (expirationTime - now)
            end
        end)

        -- Suche nach Buffs die in den letzten 2 Sekunden angewendet wurden mit aussagekräftiger Dauer (>= 3s)
        -- Umhülle Vergleich mit pcall
        local isRecentBuff = false
        pcall(function()
            isRecentBuff = buffAge < 2 and duration and duration >= 3
        end)

        if isRecentBuff then
            if not bestMatch or buffAge < bestMatch.age then
                bestMatch = {
                    spellId = spellId,
                    duration = duration,
                    icon = icon,
                    name = name,
                    age = buffAge,
                    expirationTime = expirationTime,
                }
            end
        end
    end

    if bestMatch then
        -- Speichere die Zuordnung
        local success = SaveScannedSpell(castSpellID, {
            buffSpellID = bestMatch.spellId,
            duration = bestMatch.duration,
            icon = bestMatch.icon,
            name = bestMatch.name,
        })

        if success then
            -- Speichere auch Item-Zuordnung falls dies eine Item-Nutzung war
            if itemID then
                SaveScannedItem(itemID, {
                    useSpellID = castSpellID,
                    buffSpellID = bestMatch.spellId,
                    duration = bestMatch.duration,
                    icon = bestMatch.icon,
                    name = bestMatch.name,
                })
            end

            -- Aktiviere den Buff sofort
            SpellScanner.activeBuffs[castSpellID] = {
                startTime = bestMatch.expirationTime - bestMatch.duration,
                duration = bestMatch.duration,
                expirationTime = bestMatch.expirationTime,
                source = itemID and "item" or "spell",
                sourceId = itemID or castSpellID,
            }

            -- Benachrichtige User im Scan-Modus
            if SpellScanner.scanMode then
                print(string.format("|cff00ff00GravityUI:|r Scanned: %s = %.1fs",
                    bestMatch.name, bestMatch.duration))
            end

            -- Triggere UI-Aktualisierungs-Callback falls registriert
            if SpellScanner.onScanCallback then
                SpellScanner.onScanCallback()
            end

            return true
        end
    end

    return false
end

local function ProcessPendingScanning()
    if InCombatLockdown() then return end
    if not next(SpellScanner.pendingScanning) then return end

    for spellID, data in pairs(SpellScanner.pendingScanning) do
        -- Versuche diesen Spell jetzt zu scannen
        ScanSpellFromBuffs(spellID, data.itemID)
        SpellScanner.pendingScanning[spellID] = nil
    end
end

---------------------------------------------------------------------------
-- SPELL CAST DETECTION
---------------------------------------------------------------------------

local function OnSpellCastSucceeded(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if not spellID or spellID <= 0 then return end

    -- Prüfe ob dieser Spell bereits gescannt ist
    local data = GetScannedSpell(spellID)

    if data then
        -- Bekannter Spell: aktiviere Buff-Tracking (falls wir gültige Dauer-Daten haben)
        local duration = data.duration
        if duration and type(duration) == "number" and duration > 0 then
            local now = GetTime()
            SpellScanner.activeBuffs[spellID] = {
                startTime = now,
                duration = duration,
                expirationTime = now + duration,
                source = "spell",
                sourceId = spellID,
            }
        end
        -- Auch ohne Dauer-Daten behandeln wir dies als "bekannt" und überspringen weitere Scans																		 
        return
    end

    -- Unbekannter Spell: versuche zu scannen falls aktiviert
    if SpellScanner.scanMode or SpellScanner.autoScan then
        if InCombatLockdown() then
            -- Warteschlange für Scan nach Kampf
            SpellScanner.pendingScanning[spellID] = {
                timestamp = GetTime(),
                itemID = nil,
            }
        else
            -- Scanne sofort (mit kleiner Verzögerung damit Buff erscheint)
            C_Timer.After(0.3, function()
                ScanSpellFromBuffs(spellID, nil)
            end)
        end
    end
end

---------------------------------------------------------------------------
-- CACHE MAINTENANCE
---------------------------------------------------------------------------

local function CleanupExpiredBuffs()
    local now = GetTime()
    for spellID, data in pairs(SpellScanner.activeBuffs) do
        if data.expirationTime and data.expirationTime < now then
            SpellScanner.activeBuffs[spellID] = nil
        end
    end
end

---------------------------------------------------------------------------
-- PUBLIC API (for Custom Trackers)
---------------------------------------------------------------------------

-- Prüfe ob ein Spell-Buff aktuell aktiv ist
-- Rückgabe: isActive, expirationTime, duration
function SpellScanner.IsSpellActive(spellID)
    if not spellID then return false end

    local buff = SpellScanner.activeBuffs[spellID]
    if buff and buff.expirationTime > GetTime() then
        return true, buff.expirationTime, buff.duration
    end

    -- Prüfe auch ob dies ein bekannter Spell mit noch angewendetem Buff ist
    -- (behandelt Fälle wo wir das Cast-Event verpasst haben)
    local data = GetScannedSpell(spellID)
    if data and data.buffSpellID and not InCombatLockdown() then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, data.buffSpellID)
        if ok and aura and aura.expirationTime then
            return true, aura.expirationTime, aura.duration
        end
    end

    return false
end

-- Prüfe ob ein Item-Buff aktuell aktiv ist
-- Rückgabe: isActive, expirationTime, duration
function SpellScanner.IsItemActive(itemID)
    if not itemID then return false end

    local data = GetScannedItem(itemID)
    if data and data.useSpellID then
        return SpellScanner.IsSpellActive(data.useSpellID)
    end

    return false
end

-- Prüfe ob eine spellID gescannt wurde
function SpellScanner.IsSpellScanned(spellID)
    return GetScannedSpell(spellID) ~= nil
end

-- Hole gescannte Dauer für einen Spell (oder nil falls nicht gescannt)
function SpellScanner.GetScannedDuration(spellID)
    local data = GetScannedSpell(spellID)
    return data and data.duration or nil
end

-- Schalte Scan-Modus um
function SpellScanner.ToggleScanMode()
    SpellScanner.scanMode = not SpellScanner.scanMode
    return SpellScanner.scanMode
end

-- Schalte Auto-Scan um und persistiere in DB
function SpellScanner.ToggleAutoScan()
    SpellScanner.autoScan = not SpellScanner.autoScan
    local db = GetDB()
    if db then
        db.autoScan = SpellScanner.autoScan
    end
    return SpellScanner.autoScan
end

-- Setze Auto-Scan und persistiere in DB
function SpellScanner.SetAutoScan(enabled)
    SpellScanner.autoScan = enabled
    local db = GetDB()
    if db then
        db.autoScan = enabled
    end
end

-- Manueller Trigger zum Scannen eines Spells (zum Testen)
function SpellScanner.ScanSpell(spellID, itemID)
    return ScanSpellFromBuffs(spellID, itemID)
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "PLAYER_LOGIN" then
        -- Initialisiere Datenbank
        GetDB()

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Verarbeite wartende Scans nach Kampf
        C_Timer.After(0.3, ProcessPendingScanning)

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnSpellCastSucceeded(arg1, arg2, arg3)
    end
end)

-- Periodische Bereinigung abgelaufener Buffs (gespeicherte Referenz für mögliche Abbruch)
SpellScanner.cleanupTicker = C_Timer.NewTicker(1, CleanupExpiredBuffs)

---------------------------------------------------------------------------
-- SLASH COMMANDS
---------------------------------------------------------------------------

-- /guiscan - Toggle scan mode
SLASH_GUISCAN1 = "/guiscan"
SlashCmdList["GUISCAN"] = function()
    local enabled = SpellScanner.ToggleScanMode()
    if enabled then
        print("|cff00ff00GravityUI:|r Scan mode |cff00ff00ENABLED|r")
        print("|cffff8800-|r Cast abilities to scan their durations")
        print("|cffff8800-|r Type /guiscan again to stop")
    else
        print("|cff00ff00GravityUI:|r Scan mode |cffff0000DISABLED|r")
    end
end

-- /guiscanned - List scanned spells
SLASH_GUISCANNED1 = "/guiscanned"
SlashCmdList["GUISCANNED"] = function()
    local db = GetDB()
    if not db then
        print("|cffff0000GravityUI:|r Database not available")
        return
    end

    print("|cff00ff00GravityUI Scanned Spells:|r")
    local spellCount = 0
    for spellID, data in pairs(db.spells or {}) do
        print(string.format("  [%d] %s = %.1fs", spellID, data.name or "?", data.duration or 0))
        spellCount = spellCount + 1
    end
    if spellCount == 0 then
        print("  |cff888888(none)|r")
    else
        print(string.format("  |cff888888Total: %d spells|r", spellCount))
    end

    print("|cff00ff00GravityUI Scanned Items:|r")
    local itemCount = 0
    for itemID, data in pairs(db.items or {}) do
        local itemName = C_Item.GetItemNameByID(itemID) or "Item " .. itemID
        print(string.format("  [%d] %s = %.1fs", itemID, itemName, data.duration or 0))
        itemCount = itemCount + 1
    end
    if itemCount == 0 then
        print("  |cff888888(none)|r")
    end

    -- Show pending queue
    local pendingCount = 0
    for spellID, data in pairs(SpellScanner.pendingScanning) do
        pendingCount = pendingCount + 1
    end
    if pendingCount > 0 then
        print(string.format("|cffff8800Pending scanning: %d spells|r", pendingCount))
    end

    -- Show active buffs
    local activeCount = 0
    for _ in pairs(SpellScanner.activeBuffs) do
        activeCount = activeCount + 1
    end
    print(string.format("|cff888888Active buffs tracked: %d|r", activeCount))
end

-- /guiclearspell <spellID> - Remove a scanned spell
SLASH_GUICLEARSPELL1 = "/guiclearspell"
SlashCmdList["GUICLEARSPELL"] = function(msg)
    local spellID = tonumber(msg:trim())
    if not spellID then
        print("|cffff0000GravityUI:|r Usage: /guiclearspell <spellID>")
        return
    end

    local db = GetDB()
    if db and db.spells and db.spells[spellID] then
        local name = db.spells[spellID].name or "Unknown"
        db.spells[spellID] = nil
        print(string.format("|cff00ff00GravityUI:|r Cleared spell: %s [%d]", name, spellID))
    else
        print(string.format("|cffff8800GravityUI:|r Spell %d not found in scanned list", spellID))
    end
end
