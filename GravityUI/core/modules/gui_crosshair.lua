---------------------------------------------------------------------------
-- GravityUI Crosshair Module
-- A simple screen center crosshair overlay
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local gui = ns.gui or {}
ns.gui = gui

local crosshairFrame, horizLine, vertLine, horizBorder, vertBorder

-- Separater Frame für Reichweiten-Prüfung (immer sichtbar damit OnUpdate auch bei verstecktem Crosshair läuft)
local rangeCheckFrame

-- Reichweiten-Tracking-Status
local isOutOfRange = false
local rangeCheckElapsed = 0
local RANGE_CHECK_INTERVAL = 0.1  -- Check range 10 times per second


---------------------------------------------------------------------------
-- Get settings from database
---------------------------------------------------------------------------
local function GetSettings()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.crosshair then
        return guiCore.db.profile.crosshair
    end
    return nil
end

---------------------------------------------------------------------------
-- Check if target is out of melee range
-- Uses action bar scanning with IsActionInRange for 12.x PTR compatibility
---------------------------------------------------------------------------

-- Nahkampf-Fähigkeiten zum Scannen auf Aktionsleisten (Modul-Scope um Neuerstellung zu vermeiden)
-- ALLE Fähigkeiten müssen 5-Yard-Nahkampf-Reichweite sein für genaue Erkennung
local MELEE_RANGE_ABILITIES = {
    -- Melee Interrupts (5 yards only)
    96231,  -- Paladin: Rebuke
    6552,   -- Warrior: Pummel
    1766,   -- Rogue: Kick
    116705, -- Monk: Spear Hand Strike
    183752, -- Demon Hunter: Disrupt (Havoc)
    -- NOTE: Mind Freeze (15yd) and Skull Bash (13yd) excluded - not true melee range
    -- Vengeance Demon Hunter (5 yards) - Disrupt may be talented away
    228478, -- Soul Cleave
    263642, -- Fracture
    -- Death Knight melee abilities (5 yards)
    49143,  -- Frost Strike
    85948,  -- Festering Strike
    206930, -- Heart Strike
    -- Mistweaver Monk (healers don't have interrupts in Midnight)
    100780, -- Tiger Palm
    100784, -- Blackout Kick
    107428, -- Rising Sun Kick
    -- Druid cat form (5 yards)
    5221,   -- Shred
    3252,   -- Shred (alternate ID)
    1822,   -- Rake
    22568,  -- Ferocious Bite
    22570,  -- Maim
    -- Guardian Druid (5 yards)
    33917,  -- Mangle
    6807,   -- Maul
}

local function IsOutOfMeleeRange()
    -- Kein Ziel = nicht außerhalb Reichweite (verwende normale Farbe)
    if not UnitExists("target") then
        return false
    end

    -- Muss ein angreifbares Ziel sein
    if not UnitCanAttack("player", "target") then
        return false
    end

    -- Tote Ziele zählen nicht
    if UnitIsDeadOrGhost("target") then
        return false
    end

    -- Priorität 1: Scanne Aktionsleiste nach Nahkampf-Fähigkeit und nutze IsActionInRange
    -- Dies ist die Methode, die auf Aktionsleisten im 12.x PTR funktioniert
    if IsActionInRange then
        -- Scanne nach Nahkampf-Fähigkeiten mit Reichweitendaten
        -- Prüfe sowohl direkte Zauber ALS AUCH Makros, die Zauber wirken (subType == "spell")
        for slot = 1, 180 do
            local actionType, id, subType = GetActionInfo(slot)
            -- Direkte Zauber ODER Makros, die einen Zauber wirken, abgleichen
            if id and (actionType == "spell" or (actionType == "macro" and subType == "spell")) then
                for _, abilityID in ipairs(MELEE_RANGE_ABILITIES) do
                    if id == abilityID then
                        local inRange = IsActionInRange(slot)
                        if inRange == true then
                            return false  -- In Reichweite
                        elseif inRange == false then
                            return true   -- Außerhalb Reichweite
                        end
                        -- nil = keine Reichweitendaten für diesen Slot, Scan fortsetzen
                    end
                end
            end
        end
    end

    -- Priorität 2: Versuche Legacy IsSpellInRange mit Zauber-Namen (11.x Retail)
    if IsSpellInRange then
        local attackInRange = IsSpellInRange("Attack", "target")
        if attackInRange == 1 then
            return false  -- In Nahkampfreichweite
        elseif attackInRange == 0 then
            return true   -- Außerhalb Nahkampfreichweite
        end
        -- nil = nicht verfügbar, weiter prüfen
    end

    -- Priorität 3: Versuche C_Spell.IsSpellInRange mit Nahkampf-Fähigkeiten (11.x Retail Fallback)
    if C_Spell and C_Spell.IsSpellInRange then
        for _, spellID in ipairs(MELEE_RANGE_ABILITIES) do
            local spellKnown = IsSpellKnown and IsSpellKnown(spellID)
            if spellKnown then
                local inRange = C_Spell.IsSpellInRange(spellID, "target")
                if inRange == true then
                    return false
                elseif inRange == false then
                    return true
                end
                -- nil = Nahkampfzauber haben in 12.x keine Reichweite, weiter prüfen
            end
        end
    end

    -- Priorität 4: CheckInteractDistance Index 3 (~10 Yards)
    -- Fallback - nicht ideal, aber besser als nichts
    local inRange = CheckInteractDistance("target", 3)
    if inRange ~= nil then
        return not inRange
    end

    return false
end

---------------------------------------------------------------------------
-- Crosshair-Farbe basierend auf Reichweitenstatus anwenden
---------------------------------------------------------------------------
local function ApplyCrosshairColor(settings, outOfRange)
    if not horizLine or not vertLine then return end
    
    local r, g, b, a
    
    if outOfRange and settings.changeColorOnRange then
        -- Verwende Außer-Reichweite-Farbe
        local oorColor = settings.outOfRangeColor or { 1, 0.2, 0.2, 1 }
        r = oorColor[1] or 1
        g = oorColor[2] or 0.2
        b = oorColor[3] or 0.2
        a = oorColor[4] or 1
    else
        -- Verwende normale Farbe
        r = settings.r or 1
        g = settings.g or 0.949
        b = settings.b or 0
        a = settings.a or 1
    end
    
    horizLine:SetColorTexture(r, g, b, a)
    vertLine:SetColorTexture(r, g, b, a)
end

---------------------------------------------------------------------------
-- Reichweitenprüfung OnUpdate Handler
---------------------------------------------------------------------------
local function OnRangeUpdate(self, elapsed)
    rangeCheckElapsed = rangeCheckElapsed + elapsed
    if rangeCheckElapsed < RANGE_CHECK_INTERVAL then return end
    rangeCheckElapsed = 0

    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.changeColorOnRange then
        -- Feature deaktiviert, stoppe Prüfung
        self:SetScript("OnUpdate", nil)
        return
    end

    local inCombat = InCombatLockdown()

    -- Prüfe ob wir Reichweite nur im Kampf tracken sollen
    if settings.rangeColorInCombatOnly and not inCombat then
        -- Nicht im Kampf und "nur im Kampf" ist aktiviert, verwende normale Farbe
        if isOutOfRange then
            isOutOfRange = false
            ApplyCrosshairColor(settings, false)
        end
        -- Falls hideUntilOutOfRange, verstecke Crosshair wenn nicht im Kampf
        if settings.hideUntilOutOfRange and crosshairFrame then
            crosshairFrame:Hide()
        end
        return
    end

    local newOutOfRange = IsOutOfMeleeRange()
    if newOutOfRange ~= isOutOfRange then
        isOutOfRange = newOutOfRange
        ApplyCrosshairColor(settings, isOutOfRange)
    end
    
    -- Behandle hideUntilOutOfRange-Sichtbarkeit
    if settings.hideUntilOutOfRange and crosshairFrame then
        if inCombat and isOutOfRange then
            crosshairFrame:Show()
        else
            crosshairFrame:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- Reichweitenprüfung basierend auf Einstellungen starten oder stoppen
---------------------------------------------------------------------------
local function UpdateRangeChecking()
    if not crosshairFrame then return end
    
    -- Erstelle den Reichweiten-Prüf-Frame falls nötig (separater Frame damit OnUpdate auch bei verstecktem Crosshair läuft)
    if not rangeCheckFrame then
        rangeCheckFrame = CreateFrame("Frame", "GravityUI_CrosshairRangeCheck", UIParent)
        rangeCheckFrame:SetSize(1, 1)
        rangeCheckFrame:SetPoint("CENTER")
        rangeCheckFrame:Show()  -- Immer sichtbar
    end
    
    local settings = GetSettings()
    if settings and settings.enabled and settings.changeColorOnRange then
        -- Aktiviere Reichweiten-Prüfung auf dem immer-sichtbaren Frame
        rangeCheckElapsed = 0
        rangeCheckFrame:SetScript("OnUpdate", OnRangeUpdate)
        
        local inCombat = InCombatLockdown()
        
        -- Sofortige Reichweiten-Prüfung (beachte Nur-Kampf-Einstellung)
        if settings.rangeColorInCombatOnly and not inCombat then
            isOutOfRange = false
            ApplyCrosshairColor(settings, false)
        else
            isOutOfRange = IsOutOfMeleeRange()
            ApplyCrosshairColor(settings, isOutOfRange)
        end
        
        -- Behandle hideUntilOutOfRange initiale Sichtbarkeit
        if settings.hideUntilOutOfRange then
            if inCombat and isOutOfRange then
                crosshairFrame:Show()
            else
                crosshairFrame:Hide()
            end
        end
    else
        -- Deaktiviere Reichweiten-Prüfung
        if rangeCheckFrame then
            rangeCheckFrame:SetScript("OnUpdate", nil)
        end
        isOutOfRange = false
    end
end

---------------------------------------------------------------------------
-- Crosshair-Frame und Texturen erstellen
---------------------------------------------------------------------------
local function CreateCrosshair()
    if crosshairFrame then return end
    
    crosshairFrame = CreateFrame("Frame", "GravityUI_Crosshair", UIParent)
    crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    crosshairFrame:SetSize(1, 1)
    crosshairFrame:SetFrameStrata("HIGH")
    
    -- Rand-Texturen (hinter Hauptlinien gezeichnet)
    horizBorder = crosshairFrame:CreateTexture(nil, "BACKGROUND")
    horizBorder:SetPoint("CENTER", crosshairFrame)
    horizBorder:SetColorTexture(0, 0, 0, 1)
    
    vertBorder = crosshairFrame:CreateTexture(nil, "BACKGROUND")
    vertBorder:SetPoint("CENTER", crosshairFrame)
    vertBorder:SetColorTexture(0, 0, 0, 1)
    
    -- Haupt-Crosshair-Linien (oberhalb Rand gezeichnet)
    horizLine = crosshairFrame:CreateTexture(nil, "ARTWORK")
    horizLine:SetPoint("CENTER", crosshairFrame)
    horizLine:SetColorTexture(1, 0.949, 0, 1)  -- Standard Gelb
    
    vertLine = crosshairFrame:CreateTexture(nil, "ARTWORK")
    vertLine:SetPoint("CENTER", crosshairFrame)
    vertLine:SetColorTexture(1, 0.949, 0, 1)  -- Standard Gelb
    
    crosshairFrame:Hide()
end

---------------------------------------------------------------------------
-- Crosshair-Aussehen aus den Einstellungen aktualisieren
---------------------------------------------------------------------------
local function UpdateCrosshair()
    if not crosshairFrame then
        CreateCrosshair()
    end
    
    local settings = GetSettings()
    if not settings then
        crosshairFrame:Hide()
        return
    end
    
    -- Hole Einstellungen mit Standardwerten
    local enabled = settings.enabled
    local size = settings.size or 12
    local thickness = settings.thickness or 3
    local borderSize = settings.borderSize or 2
    local offsetX = settings.offsetX or 0
    local offsetY = settings.offsetY or 0
    local borderR = settings.borderR or 0
    local borderG = settings.borderG or 0
    local borderB = settings.borderB or 0
    local borderA = settings.borderA or 1
    local strata = settings.strata or "HIGH"
    local onlyInCombat = settings.onlyInCombat
    
    -- Wende Strata und Position an
    crosshairFrame:SetFrameStrata(strata)
    crosshairFrame:ClearAllPoints()
    crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    
    -- Skaliere die Rand-Texturen (etwas größer als Hauptlinien)
    horizBorder:SetSize((size * 2) + borderSize * 2, thickness + borderSize * 2)
    vertBorder:SetSize(thickness + borderSize * 2, (size * 2) + borderSize * 2)
    horizBorder:SetColorTexture(borderR, borderG, borderB, borderA)
    vertBorder:SetColorTexture(borderR, borderG, borderB, borderA)
    
    -- Skaliere die Haupt-Crosshair-Linien
    horizLine:SetSize(size * 2, thickness)
    vertLine:SetSize(thickness, size * 2)
    
    -- Wende Farbe basierend auf Reichweiten-Status an (falls Feature aktiviert)
    if settings.changeColorOnRange then
        isOutOfRange = IsOutOfMeleeRange()
        ApplyCrosshairColor(settings, isOutOfRange)
    else
        -- Use normal color
        local r = settings.r or 1
        local g = settings.g or 0.949
        local b = settings.b or 0
        local a = settings.a or 1
        horizLine:SetColorTexture(r, g, b, a)
        vertLine:SetColorTexture(r, g, b, a)
    end
    
    -- Zeige/verstecke basierend auf Einstellungen
    if not enabled then
        crosshairFrame:Hide()
        crosshairFrame:SetScript("OnUpdate", nil)
    elseif onlyInCombat then
        crosshairFrame:SetShown(InCombatLockdown())
    else
        crosshairFrame:Show()
    end
    
    -- Aktualisiere Reichweiten-Prüf-Status
    UpdateRangeChecking()
end

---------------------------------------------------------------------------
-- Combat visibility handling
---------------------------------------------------------------------------
local function OnCombatStart()
    local settings = GetSettings()
    if settings and settings.enabled and settings.onlyInCombat then
        if crosshairFrame then
            crosshairFrame:Show()
            UpdateRangeChecking()
        end
    end
end

local function OnCombatEnd()
    local settings = GetSettings()
    if settings and settings.onlyInCombat then
        if crosshairFrame then
            crosshairFrame:Hide()
            crosshairFrame:SetScript("OnUpdate", nil)
        end
    end
end

---------------------------------------------------------------------------
-- Target changed handler
---------------------------------------------------------------------------
local function OnTargetChanged()
    local settings = GetSettings()
    if settings and settings.enabled and settings.changeColorOnRange then
        -- Sofortige Farb-Aktualisierung wenn Ziel sich ändert
        isOutOfRange = IsOutOfMeleeRange()
        ApplyCrosshairColor(settings, isOutOfRange)
    end
end

---------------------------------------------------------------------------
-- Initialize
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            CreateCrosshair()
            UpdateCrosshair()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()
    elseif event == "PLAYER_TARGET_CHANGED" then
        OnTargetChanged()
    end
end)

---------------------------------------------------------------------------
-- Global refresh function for GUI
---------------------------------------------------------------------------
_G.GravityUI_RefreshCrosshair = UpdateCrosshair

gui.Crosshair = {
    Update = UpdateCrosshair,
    Create = CreateCrosshair,
}

