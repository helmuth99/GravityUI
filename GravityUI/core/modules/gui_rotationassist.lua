-- gui_rotationassist.lua
-- Zeigt ein eigenständiges Icon mit Blizzards nächster empfohlener Fähigkeit
-- Nutzt C_AssistedCombat API (Starter Build / Rotationshilfe)

local ADDON_NAME, gui = ...
local LSM = LibStub("LibSharedMedia-3.0")

-- Lokale Variablen für Performance
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists

-- Update-Intervalle
local UPDATE_INTERVAL_COMBAT = 0.3
local UPDATE_INTERVAL_IDLE = 1.0

-- Icon-Status-Farben
local COLOR_USABLE = { 1, 1, 1 }
local COLOR_UNUSABLE = { 0.4, 0.4, 0.4 }
local COLOR_NO_MANA = { 0.5, 0.5, 1 }
local COLOR_OUT_OF_RANGE = { 0.8, 0.2, 0.2 }

-- Frame-Referenzen
local iconFrame = nil
local isInitialized = false
local lastSpellID = nil
local inCombat = false

-- Performance: Ticker statt OnUpdate
local updateTicker = nil

-- Cache für Keybind-Lookup (Wiederverwendung von keybinds.lua)
local spellToKeybind = {}
local lastKeybindCacheTime = 0
local KEYBIND_CACHE_INTERVAL = 1.0

-- GCD Spell-ID (Standard-Global-Cooldown-Referenz)
local GCD_SPELL_ID = 61304
-- Vorwärtsdeklarationen
local CreateIconFrame, RefreshIconFrame, UpdateIconDisplay, UpdateVisibility

--------------------------------------------------------------------------------
-- Keybind Lookup (uses shared formatter from keybinds.lua)
--------------------------------------------------------------------------------

local function FormatKeybind(keybind)
    if gui.FormatKeybind then
        return gui.FormatKeybind(keybind)
    end
    return keybind -- fallback if not available
end

local function GetKeybindForSpell(spellID)
    if not spellID then return nil end

    local keybind = nil

    -- Nutze gui.Keybinds falls verfügbar (von keybinds.lua)
    if gui.Keybinds and gui.Keybinds.GetKeybindForSpell then
        keybind = gui.Keybinds.GetKeybindForSpell(spellID)

        -- Falls kein Keybind gefunden, versuche BASE-Spell zu finden (für Proc-Fähigkeiten)
        -- z.B. Thunder Blast → Thunder Clap
        if not keybind then
            local ok, baseSpellID = pcall(function()
                return FindBaseSpellByID and FindBaseSpellByID(spellID)
            end)
            if ok and baseSpellID and baseSpellID ~= spellID then
                keybind = gui.Keybinds.GetKeybindForSpell(baseSpellID)
            end
        end

        -- Also try C_Spell.GetOverrideSpell in reverse
        if not keybind then
            local ok, overrideID = pcall(function()
                return C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(spellID)
            end)
            if ok and overrideID and overrideID ~= spellID then
                keybind = gui.Keybinds.GetKeybindForSpell(overrideID)
            end
        end

        if keybind then return keybind end
    end

    -- Fallback: Finde Action-Buttons mit diesem Spell (versuche auch Base-Spell)
    local baseSpellID = FindBaseSpellByID and FindBaseSpellByID(spellID) or spellID
    local slots = C_ActionBar.FindSpellActionButtons(baseSpellID)

    if slots and #slots > 0 then
        for _, slot in ipairs(slots) do
            -- Versuche Keybind für diesen Action-Slot zu bekommen
            local actionName = "ACTIONBUTTON" .. slot
            if slot > 12 and slot <= 24 then
                actionName = "ACTIONBUTTON" .. (slot - 12)
            elseif slot > 24 and slot <= 36 then
                actionName = "MULTIACTIONBAR3BUTTON" .. (slot - 24)
            elseif slot > 36 and slot <= 48 then
                actionName = "MULTIACTIONBAR4BUTTON" .. (slot - 36)
            elseif slot > 48 and slot <= 60 then
                actionName = "MULTIACTIONBAR1BUTTON" .. (slot - 48)
            elseif slot > 60 and slot <= 72 then
                actionName = "MULTIACTIONBAR2BUTTON" .. (slot - 60)
            end

            local key1 = GetBindingKey(actionName)
            if key1 then
                return FormatKeybind(key1)
            end
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- GCD Cooldown Helpers (handles Midnight 12.0+ secret values)
--------------------------------------------------------------------------------

local function ReadSpellCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local a, b, c, d = C_Spell.GetSpellCooldown(spellID)
        if type(a) == "table" then
            -- Midnight 12.0+ gibt Tabelle zurück
            local start = a.startTime or a.start
            local duration = a.duration
            local modRate = a.modRate
            return start, duration, modRate
        else
            -- 11.x returns tuple: start, duration, enable, modRate
            return a, b, d
        end
    end
    return nil, nil, nil
end

local function IsCooldownActive(start, duration)
    if not start or not duration then return false end
    local ok, result = pcall(function()
        return duration > 0 and start > 0
    end)
    -- Falls Vergleich Error warf = Secret Value = Cooldown IST aktiv
    if not ok then return true end
    return result
end

--------------------------------------------------------------------------------																	
-- Database Access
--------------------------------------------------------------------------------

local function GetDB()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if guiCore and guiCore.db and guiCore.db.profile then
        return guiCore.db.profile.rotationAssistIcon
    end
    return nil
end

--------------------------------------------------------------------------------
-- Icon Frame Creation
--------------------------------------------------------------------------------

CreateIconFrame = function()
    if iconFrame then return iconFrame end

    -- Haupt-Frame
    iconFrame = CreateFrame("Button", "GravityUI_RotationAssistIcon", UIParent, "BackdropTemplate")
    iconFrame:SetSize(56, 56)
    iconFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    iconFrame:SetFrameStrata("MEDIUM")
    iconFrame:SetClampedToScreen(true)
    iconFrame:EnableMouse(true)
    iconFrame:SetMovable(true)
    iconFrame:RegisterForDrag("LeftButton")

    -- Icon-Textur (eingerückt um 2px Standard für Rand-Sichtbarkeit)
    iconFrame.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    iconFrame.icon:SetPoint("TOPLEFT", 2, -2)
    iconFrame.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    iconFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Crop edges

    -- Cooldown-Frame (passt Icon-Einrückung)
    iconFrame.cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
    iconFrame.cooldown:SetPoint("TOPLEFT", 2, -2)
    iconFrame.cooldown:SetPoint("BOTTOMRIGHT", -2, 2)
    iconFrame.cooldown:SetDrawSwipe(true)
    iconFrame.cooldown:SetDrawEdge(false)
    iconFrame.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    iconFrame.cooldown:SetHideCountdownNumbers(true)

    -- Keybind-Text
    iconFrame.keybindText = iconFrame:CreateFontString(nil, "OVERLAY")
    iconFrame.keybindText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    iconFrame.keybindText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    iconFrame.keybindText:SetTextColor(1, 1, 1, 1)
    iconFrame.keybindText:SetShadowOffset(1, -1)
    iconFrame.keybindText:SetShadowColor(0, 0, 0, 1)

    -- Drag-Handler
    iconFrame:SetScript("OnDragStart", function(self)
        local db = GetDB()
        if db and not db.isLocked then
            self:StartMoving()
        end
    end)

    iconFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        -- Speichere Position relativ zum Bildschirm-Zentrum
        local db = GetDB()
        if db then
            local selfX, selfY = self:GetCenter()
            local parentX, parentY = UIParent:GetCenter()
            if selfX and selfY and parentX and parentY then
                db.positionX = selfX - parentX
                db.positionY = selfY - parentY
            end
        end
    end)

    -- Initial versteckt
    iconFrame:Hide()

    return iconFrame
end

--------------------------------------------------------------------------------
-- Icon Display Update
--------------------------------------------------------------------------------

UpdateIconDisplay = function(spellID)
    if not iconFrame then return end

    local db = GetDB()
    if not db or not db.enabled then
        iconFrame:Hide()
        return
    end

    if not spellID or spellID == 0 then
        -- Kein Spell empfohlen - verstecke Icon komplett
        iconFrame:Hide()
        return
    end

    -- Wir haben einen Spell - stelle sicher dass Frame sichtbar ist (beachte Sichtbarkeits-Modus)
    UpdateVisibility()

    -- Hole Spell-Textur
    local texture = C_Spell.GetSpellTexture(spellID)
    if texture then
        iconFrame.icon:SetTexture(texture)
    end

    -- Hole Nutzbarkeits-Status für Icon-Färbung
    local isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellID)
    local inRange = true

    -- Prüfe Reichweite falls Spell Reichweite hat
    local hasRange = C_Spell.SpellHasRange(spellID)
    if hasRange and UnitExists("target") then
        local rangeCheck = C_Spell.IsSpellInRange(spellID, "target")
        if rangeCheck == false then
            inRange = false
        end
    end

    -- Wende Icon-Färbung basierend auf Status an
    local color
    if not inRange then
        color = COLOR_OUT_OF_RANGE
    elseif notEnoughMana then
        color = COLOR_NO_MANA
    elseif not isUsable then
        color = COLOR_UNUSABLE
    else
        color = COLOR_USABLE
    end
    iconFrame.icon:SetVertexColor(color[1], color[2], color[3], 1)

    -- GCD-Cooldown-Swipe wird separat durch UpdateGCDCooldown() behandelt
    -- (ausgelöst durch SPELL_UPDATE_COOLDOWN Events für Reaktionsgeschwindigkeit)

    -- Aktualisiere Keybind-Text
    if db.showKeybind then
        local keybind = GetKeybindForSpell(spellID)
        iconFrame.keybindText:SetText(keybind or "")
        iconFrame.keybindText:Show()
    else
        iconFrame.keybindText:Hide()
    end
end

--------------------------------------------------------------------------------
-- GCD Cooldown Update (event-driven for responsiveness)
--------------------------------------------------------------------------------

local function UpdateGCDCooldown()
    if not iconFrame or not iconFrame.cooldown then return end

    local db = GetDB()
    if not db or not db.cooldownSwipeEnabled then
        iconFrame.cooldown:Hide()
        return
    end

        -- Zeige nur GCD-Swipe wenn das Icon selbst sichtbar ist
    if not iconFrame:IsShown() then return end

    local start, duration, modRate = ReadSpellCooldown(GCD_SPELL_ID)

    if IsCooldownActive(start, duration) then
        iconFrame.cooldown:Show()
        if modRate then
            iconFrame.cooldown:SetCooldown(start, duration, modRate)
        else
            iconFrame.cooldown:SetCooldown(start, duration)
        end
    else
        iconFrame.cooldown:Clear()
    end
end

--------------------------------------------------------------------------------																		
-- Visibility Management
--------------------------------------------------------------------------------

UpdateVisibility = function()
    if not iconFrame then return end

    local db = GetDB()
    if not db or not db.enabled then
        iconFrame:Hide()
        return
    end

    local shouldShow = false
    local visibility = db.visibility or "always"

    if visibility == "always" then
        shouldShow = true
    elseif visibility == "combat" then
        shouldShow = inCombat
    elseif visibility == "hostile" then
        shouldShow = UnitExists("target") and UnitCanAttack("player", "target")
    end

    if shouldShow then
        iconFrame:Show()
    else
        iconFrame:Hide()
    end
end

--------------------------------------------------------------------------------
-- Ticker-based Update (Performance: runs only when needed, not every frame)
--------------------------------------------------------------------------------

local function DoUpdate()
    local db = GetDB()
    if not db or not db.enabled then return end

    -- Prüfe ob C_AssistedCombat API verfügbar ist
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return
    end

    -- Hole nächsten empfohlenen Spell
    local ok, spellID = pcall(C_AssistedCombat.GetNextCastSpell, false)
    if not ok then
        spellID = nil
    end

    -- Nur volles Update falls Spell sich geändert hat
    if spellID ~= lastSpellID then
        lastSpellID = spellID
        UpdateIconDisplay(spellID)
    end
end

local function StartUpdateTicker()
    -- Breche existierenden Ticker ab falls vorhanden
    if updateTicker then updateTicker:Cancel() end

    local db = GetDB()
    if not db or not db.enabled then return end

    -- Nutze passendes Intervall basierend auf Kampf-Status
    local interval = inCombat and UPDATE_INTERVAL_COMBAT or UPDATE_INTERVAL_IDLE
    updateTicker = C_Timer.NewTicker(interval, DoUpdate)
end

local function StopUpdateTicker()
    if updateTicker then
        updateTicker:Cancel()
        updateTicker = nil
    end
end

--------------------------------------------------------------------------------
-- Frame Refresh (Apply Settings)
--------------------------------------------------------------------------------

RefreshIconFrame = function()
    if not iconFrame then
        CreateIconFrame()
    end

    local db = GetDB()
    if not db then
        if iconFrame then iconFrame:Hide() end
        return
    end

    if not db.enabled then
        iconFrame:Hide()
        StopUpdateTicker()
        return
    end

    -- Stelle sicher dass Ticker läuft wenn aktiviert (könnte gestoppt worden sein)
    StartUpdateTicker()

    -- Größe (schütze mit pcall um Secret-Value-Crash zu verhindern wenn Backdrop neu berechnet)
    -- SetSize triggert Backdrop-Texturkoordinaten-Neuberechnung die im Kampf fehlschlagen kann
    local size = db.iconSize or 56
    pcall(iconFrame.SetSize, iconFrame, size, size)

    -- Position (immer am Bildschirm-CENTER verankert)
    iconFrame:ClearAllPoints()
    local posX = db.positionX or 0
    local posY = db.positionY or -180
    iconFrame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)

    -- Frame strata
    iconFrame:SetFrameStrata(db.frameStrata or "MEDIUM")

    -- Rand (nutzt SafeSetBackdrop um Secret-Value-Errors im Kampf zu vermeiden)
    local inset = 0
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    local SafeSetBackdrop = guiCore and guiCore.SafeSetBackdrop

    if db.showBorder then
        local borderColor = db.borderColor or { 0, 0, 0, 1 }
        local thickness = db.borderThickness or 2
        inset = thickness

        -- Use backdrop for border
        local backdropInfo = {
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = thickness,
        }
        if not db.isLocked then
            -- Grüner Rand wenn entsperrt
            if SafeSetBackdrop then
                SafeSetBackdrop(iconFrame, backdropInfo, { 0, 1, 0, 1 })
            else
                iconFrame:SetBackdrop(backdropInfo)
                iconFrame:SetBackdropBorderColor(0, 1, 0, 1)
            end
        else
            if SafeSetBackdrop then
                SafeSetBackdrop(iconFrame, backdropInfo, borderColor)
            else
                iconFrame:SetBackdrop(backdropInfo)
                iconFrame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
            end
        end
    else
        if SafeSetBackdrop then
            SafeSetBackdrop(iconFrame, nil)
        else
            iconFrame:SetBackdrop(nil)
        end
    end

    -- Passe Icon- und Cooldown-Einrückung basierend auf Rand an
    iconFrame.icon:ClearAllPoints()
    iconFrame.icon:SetPoint("TOPLEFT", inset, -inset)
    iconFrame.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    iconFrame.cooldown:ClearAllPoints()
    iconFrame.cooldown:SetPoint("TOPLEFT", inset, -inset)
    iconFrame.cooldown:SetPoint("BOTTOMRIGHT", -inset, inset)

    -- Aktualisiere Cooldown-Swipe-Sichtbarkeit basierend auf Einstellung
    iconFrame.cooldown:SetDrawSwipe(db.cooldownSwipeEnabled)
    if not db.cooldownSwipeEnabled then
        iconFrame.cooldown:Hide()
    end
    -- Sperr-/Entsperr-Status
    iconFrame:EnableMouse(not db.isLocked or true) -- Always enable for visibility, but drag only when unlocked

    -- Keybind-Text-Styling
    if db.showKeybind then
        -- Hole Font: nutze keybindFont falls gesetzt, sonst Fallback auf general.font
        local fontName = db.keybindFont
        if not fontName then
            local guiCore = _G.GravityUI and _G.GravityUI.guiCore
            if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.general then
                fontName = guiCore.db.profile.general.font
            end
        end
        local fontPath = LSM:Fetch("font", fontName) or STANDARD_TEXT_FONT
        local fontSize = db.keybindSize or 13
        local outline = db.keybindOutline and "OUTLINE" or ""
        iconFrame.keybindText:SetFont(fontPath, fontSize, outline)

        local color = db.keybindColor or { 1, 1, 1, 1 }
        iconFrame.keybindText:SetTextColor(color[1], color[2], color[3], color[4] or 1)

        -- Anker-Position
        local anchor = db.keybindAnchor or "BOTTOMRIGHT"
        local offsetX = db.keybindOffsetX or -2
        local offsetY = db.keybindOffsetY or 2
        iconFrame.keybindText:ClearAllPoints()
        iconFrame.keybindText:SetPoint(anchor, iconFrame, anchor, offsetX, offsetY)
    end

    -- Rufe UpdateVisibility() hier NICHT auf - lass OnUpdate den Frame zeigen
    -- erst nachdem ein Spell geholt wurde, um leeren Border-Flash zu vermeiden
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")											 

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            if not isInitialized then
                CreateIconFrame()
                isInitialized = true
            end
            local db = GetDB()
            if db and db.enabled then
                RefreshIconFrame()
                -- Starte Ticker für Spell-Updates (Performance: ersetzt OnUpdate)
                StartUpdateTicker()
            end
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        local db = GetDB()
        if db and db.enabled then
            UpdateVisibility()
            -- Starte Ticker neu mit Idle-Intervall (1.0s statt 0.3s)
            StartUpdateTicker()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        local db = GetDB()
        if db and db.enabled then
            UpdateVisibility()
            -- Starte Ticker neu mit Kampf-Intervall (0.3s für schnellere Reaktion)
            StartUpdateTicker()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateVisibility()
        -- Erzwinge Spell-Update bei Zielwechsel
        lastSpellID = nil
        DoUpdate()  -- Sofortiges Update bei Zielwechsel
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
        UpdateGCDCooldown()		   
    end
end)

--------------------------------------------------------------------------------
-- Global Refresh Function
--------------------------------------------------------------------------------

local function RefreshRotationAssistIcon()
    RefreshIconFrame()
end

_G.GravityUI_RefreshRotationAssistIcon = RefreshRotationAssistIcon

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

gui.RotationAssistIcon = {
    Refresh = RefreshRotationAssistIcon,
    GetFrame = function() return iconFrame end,
}
