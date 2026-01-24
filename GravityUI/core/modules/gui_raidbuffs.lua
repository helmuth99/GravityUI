local ADDON_NAME, ns = ...
local guiCore = ns.Addon
local IsSecretValue = function(v) return ns.Utils and ns.Utils.IsSecretValue and ns.Utils.IsSecretValue(v) or false end																													   

---------------------------------------------------------------------------
-- gui Fehlende Raid-Buffs Anzeige
-- Zeigt fehlende Raid-Buffs wenn eine Buff-gebende Klasse in der Gruppe ist
---------------------------------------------------------------------------

local gui_RaidBuffs = {}
ns.RaidBuffs = gui_RaidBuffs

---------------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------------

local ICON_SIZE = 32
local ICON_SPACING = 4
local FRAME_PADDING = 6
local UPDATE_THROTTLE = 0.5
local MAX_AURA_INDEX = 40  -- WoW maximum buff slots

-- Raid-Buffs-Konfiguration
-- spellId: Primäre Spell-ID für Icon-Lookup (kann einzelne ID oder Tabelle von IDs sein)
-- name: Buff-Name für Fallback-Erkennung (erkennt Talent-Varianten)
-- stat: Was der Buff bietet (für Tooltip)
-- providerClass: Welche Klasse diesen Buff bietet
-- range: Reichweite in Yards zum Prüfen ob Provider/Target erreichbar ist
-- HINWEIS: Name-basierter Fallback erkennt Talent-geänderte Buffs mit anderen Spell-IDs																			   
local RAID_BUFFS = {
    {
        spellId = 21562,
        name = "Power Word: Fortitude",
        stat = "Stamina",
        providerClass = "PRIEST",
        range = 40,
    },
    {
        spellId = 6673,
        name = "Battle Shout",
        stat = "Attack Power",
        providerClass = "WARRIOR",
        range = 100,
    },
    {
        spellId = 1459,
        name = "Arcane Intellect",
        stat = "Intellect",
        providerClass = "MAGE",
        range = 40,
    },
    {
        spellId = 1126,
        name = "Mark of the Wild",
        stat = "Versatility",
        providerClass = "DRUID",
        range = 40,
    },
    {
        -- 381748 ist der Buff der auf Spielern erscheint, 364342 ist die Fähigkeit
        spellId = 381748,
        name = "Blessing of the Bronze",
        stat = "Movement Speed",
        providerClass = "EVOKER",
        range = 40,
    },
    {
        spellId = 462854,
        name = "Skyfury",
        stat = "Mastery",
        providerClass = "SHAMAN",
        range = 100,
    },
}

-- Hole Spell-Icon dynamisch (behandelt Erweiterungs-Unterschiede)
local function GetBuffIcon(spellId)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellId)
    elseif GetSpellTexture then
        return GetSpellTexture(spellId)
    end
    return 134400  -- Fragezeichen-Fallback
end

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------

local mainFrame
local buffIcons = {}
local lastUpdate = 0
local groupClasses = {}
local previewMode = false
local previewBuffs = nil  -- Gecachte Preview-Buffs (nicht bei jedem Update neu mischen)

---------------------------------------------------------------------------
-- DATABASE ACCESS
---------------------------------------------------------------------------

local function GetSettings()
    if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.raidBuffs then
        return guiCore.db.profile.raidBuffs
    end
    return {
        enabled = true,
        showOnlyInGroup = true,
        showOnlyInInstance = false,  -- Nur in Dungeon/Raid-Instanzen zeigen																		   
        providerMode = false,
        hideLabelBar = false,        -- Verstecke die "Missing Buffs" Label-Leiste
        iconSize = 32,
        labelFontSize = 12,
        labelTextColor = nil,        -- nil = weiß, sonst {r, g, b, a}
        position = nil,
    }
end

---------------------------------------------------------------------------
-- HELPER FUNCTIONS
---------------------------------------------------------------------------

-- Sichere Wert-Prüfung - gibt nil zurück wenn Secret Value, sonst gibt Wert zurück
local function SafeBooleanCheck(value)								   
    if IsSecretValue(value) then
        return nil
    end
    return value					
end
   
-- Prüfe ob Einheit in spezifischer Reichweite ist (in Yards)
-- Nutzt UnitDistanceSquared für genaue Distanz, fällt zurück auf andere Methoden
local function IsUnitInRange(unit, rangeYards)
    rangeYards = rangeYards or 40  -- Standard auf 40 Yards
    local rangeSquared = rangeYards * rangeYards

    -- Methode 1: UnitDistanceSquared - genaueste für eigene Reichweiten
    if UnitDistanceSquared then
        local ok, distSq = pcall(UnitDistanceSquared, unit)
        if ok and distSq then
            local dist = SafeBooleanCheck(distSq)
            if dist and type(dist) == "number" then
                return dist <= rangeSquared
            end
        end
    end

    -- Methode 2: CheckInteractDistance (1 = inspizieren, ~28 Yards) - Fallback für kurze Reichweite
    if rangeYards <= 30 then
        local ok2, canInteract = pcall(CheckInteractDistance, unit, 1)
        if ok2 and canInteract ~= nil then
            local result = SafeBooleanCheck(canInteract)
            if result ~= nil then
                return result
            end
        end
    end

    -- Methode 3: UnitInRange (~28 Yards) - Fallback
    local ok, inRange, checkedRange = pcall(UnitInRange, unit)
    if ok then
        local safeChecked = SafeBooleanCheck(checkedRange)
        if safeChecked then
            local safeInRange = SafeBooleanCheck(inRange)
            if safeInRange ~= nil then
                -- UnitInRange ist ~28 Yards, falls längere Reichweite geprüft wird annehmen in Reichweite wenn UnitInRange true zurückgibt
                if rangeYards > 28 and safeInRange then
                    return true
                end
                return safeInRange
            end
        end
    end

    -- Kann Reichweite nicht bestimmen, annehmen in Reichweite
    return true
end

-- Sichere Einheiten-Prüfung für Midnight Beta (mehrere APIs geben Secret Values zurück)
-- Gibt true zurück wenn Einheit gültig, lebendig, verbunden und in Reichweite
local function IsUnitAvailable(unit, rangeYards)
    -- Prüfe jede Bedingung separat, handhabe Secret Values
    local exists = SafeBooleanCheck(UnitExists(unit))
    if not exists then return false end

    local dead = SafeBooleanCheck(UnitIsDeadOrGhost(unit))
    if dead == nil or dead then return false end  -- nil = Secret, behandle als nicht verfügbar

    local connected = SafeBooleanCheck(UnitIsConnected(unit))
    if connected == nil or not connected then return false end

    return IsUnitInRange(unit, rangeYards)
end

-- Sicherer Wrapper für UnitClass (behandelt potentielle Secret Values in Midnight)
local function SafeUnitClass(unit)
    local ok, localized, class = pcall(UnitClass, unit)
    if ok and class and type(class) == "string" then
        return class
    end
    return nil
end

-- Sicherer Aura-Feld-Zugriff für Midnight Beta
-- In 12.x Beta können Aura-Daten-Felder "Secret Values" sein die bei Zugriff Error werfen
-- BUG-006: Validiere auch dass Wert in Vergleichen genutzt werden kann
local function SafeGetAuraField(auraData, fieldName)
    local success, value = pcall(function() return auraData[fieldName] end)
    if not success then return nil end
    -- Validiere dass Wert in Vergleichen genutzt werden kann (Secret Values scheitern bei ==-Operationen)
    local compareOk = pcall(function() return value == value end)
    if not compareOk then return nil end
    return value
end

local function ScanGroupClasses()
    wipe(groupClasses)

    -- Immer Spieler einschließen
    local playerClass = SafeUnitClass("player")
    if playerClass then
        groupClasses[playerClass] = true
    end

    -- Scanne alle Gruppenmitglieder nach ihren Klassen (keine Reichweiten-Prüfung - müssen nur wissen welche Klassen existieren)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local exists = SafeBooleanCheck(UnitExists(unit))
            local connected = SafeBooleanCheck(UnitIsConnected(unit))
            if exists and connected then
                local class = SafeUnitClass(unit)
                if class then
                    groupClasses[class] = true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            local exists = SafeBooleanCheck(UnitExists(unit))
            local connected = SafeBooleanCheck(UnitIsConnected(unit))
            if exists and connected then
                local class = SafeUnitClass(unit)
                if class then
                    groupClasses[class] = true
                end
            end
        end
    end
end

-- Prüfe ob eine Einheit einen Buff nach Spell-ID hat, mit Name-basiertem Fallback
-- Nutzt 3-Methoden-Ansatz für maximale Kompatibilität über WoW-Versionen
local function UnitHasBuff(unit, spellId, spellName)
    if not unit then return false end
    local exists = SafeBooleanCheck(UnitExists(unit))
    if not exists then return false end

    -- Methode 1: AuraUtil.ForEachAura (zuverlässigste)
    if AuraUtil and AuraUtil.ForEachAura then
        local found = false
        AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(auraData)
            if auraData then
                -- Nutze sicheren Feld-Zugriff für Midnight Beta (12.x) Secret Values
                local auraSpellId = SafeGetAuraField(auraData, "spellId")
                local auraName = SafeGetAuraField(auraData, "name")													 
                if auraSpellId and auraSpellId == spellId then
                    found = true
                elseif spellName and auraName and auraName == spellName then
                    found = true
                end
            end
            if found then return true end
        end, true)
        if found then return true end
    end

    -- Methode 2: GetAuraDataBySpellName
    if spellName and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local success, auraData = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, spellName, "HELPFUL")
        if success and auraData then return true end                                         
    end

    -- Methode 3: GetAuraDataByIndex-Iteration
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, MAX_AURA_INDEX do
            local success, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if not success or not auraData then break end
            -- Nutze sicheren Feld-Zugriff für Midnight Beta (12.x) Secret Values
            local auraSpellId = SafeGetAuraField(auraData, "spellId")
            local auraName = SafeGetAuraField(auraData, "name")																
            if auraSpellId and auraSpellId == spellId then
                return true
            elseif spellName and auraName and auraName == spellName then
                return true
            end
        end
    end

    return false
end

-- Prüfe ob Spieler einen Buff hat (Convenience-Wrapper)
local function PlayerHasBuff(spellId, spellName)
    return UnitHasBuff("player", spellId, spellName)
end
-- Prüfe ob ein verfügbares Gruppenmitglied einen spezifischen Buff vermisst
local function AnyGroupMemberMissingBuff(spellId, spellName, rangeYards)
    -- Prüfe Spieler zuerst
    if not PlayerHasBuff(spellId, spellName) then
        return true
    end

    -- Prüfe Party/Raid-Mitglieder
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local isPlayer = UnitIsUnit(unit, "player")
            if IsUnitAvailable(unit, rangeYards) and not IsSecretValue(isPlayer) and not isPlayer then
                if not UnitHasBuff(unit, spellId, spellName) then
                    return true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            if IsUnitAvailable(unit, rangeYards) then
                if not UnitHasBuff(unit, spellId, spellName) then
                    return true
                end
            end
        end
    end

    return false
end

-- Hole Spieler-Klasse
local function GetPlayerClass()
    return SafeUnitClass("player")
end

-- Prüfe ob eine Einheit einer gegebenen Klasse in Reichweite ist (zum Empfangen von Buffs von ihnen)
local function IsProviderClassInRange(providerClass, rangeYards)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local isPlayer = UnitIsUnit(unit, "player")
            if not IsSecretValue(isPlayer) and not isPlayer then						
                local class = SafeUnitClass(unit)
                if class == providerClass and IsUnitAvailable(unit, rangeYards) then
                    return true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            local class = SafeUnitClass(unit)
            if class == providerClass and IsUnitAvailable(unit, rangeYards) then
                return true
            end
        end
    end
    return false
end

local function GetMissingBuffs()
    local missing = {}
    local settings = GetSettings()

    -- Preview-Modus: gebe gecachte Preview-Buffs zurück (einmal generiert wenn Preview aktiviert)
    if previewMode and previewBuffs then
        return previewBuffs
    end

    -- Prüfe ob wir nur in Gruppe zeigen sollen
    if settings.showOnlyInGroup and not IsInGroup() then
        return missing
    end

    -- Prüfe ob wir nur in Instanz zeigen sollen
    if settings.showOnlyInInstance and not ns.Utils.IsInInstancedContent() then
        return missing
    end
    -- Nur außerhalb Kampf zeigen (immer erzwungen)
    if InCombatLockdown() then
        return missing
    end

    -- Deaktiviere während M+-Keystones - Aura-Daten sind geschützt während Challenge-Modus
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
        return missing
    end
    -- Scanne Gruppen-Zusammensetzung
    ScanGroupClasses()

    local playerClass = GetPlayerClass()

    -- Prüfe jeden Raid-Buff
    for _, buff in ipairs(RAID_BUFFS) do
        local dominated = false
        local buffRange = buff.range or 40

        -- Zeige immer Buffs die DU vermisst wenn Provider in Gruppe UND in Reichweite
        if groupClasses[buff.providerClass] and not PlayerHasBuff(buff.spellId, buff.name) then
            if IsProviderClassInRange(buff.providerClass, buffRange) then
                table.insert(missing, buff)
                dominated = true
            end
        end

        -- Provider-Modus zeigt AUCH Buffs die DU bereitstellen kannst die jemandem fehlen
        -- (aber nicht duplizieren wenn wir es bereits oben hinzugefügt haben)
        if settings.providerMode and not dominated then
            if buff.providerClass == playerClass and AnyGroupMemberMissingBuff(buff.spellId, buff.name, buffRange) then
                table.insert(missing, buff)
            end
        end
    end

    return missing
end

---------------------------------------------------------------------------
-- UI CREATION
---------------------------------------------------------------------------

local function CreateBuffIcon(parent, index)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(ICON_SIZE, ICON_SIZE)

    -- Hintergrund/Rand mit Backdrop
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    button:SetBackdropColor(0, 0, 0, 0.8)

    -- Icon-Textur (eingerückt um 1px für Rand)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        if self.buffData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.buffData.name, 1, 1, 1)
            GameTooltip:AddLine(self.buffData.stat, 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ")
            local className = LOCALIZED_CLASS_NAMES_MALE[self.buffData.providerClass] or self.buffData.providerClass
            GameTooltip:AddLine("Provided by: " .. className, 0.5, 0.8, 1)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

local function CreateMainFrame()
    if mainFrame then return mainFrame end

    -- Haupt-Container (unsichtbar, nur für Positionierung und Ziehen)
    mainFrame = CreateFrame("Frame", "GravityUI_MissingRaidBuffs", UIParent)
    mainFrame:SetSize(200, 70)
    mainFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Speichere Position
        local settings = GetSettings()
        if settings then
            local point, _, relPoint, x, y = self:GetPoint()
            settings.position = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)

    -- Container für Buff-Icons (Icons gehen hier rein)
    mainFrame.iconContainer = CreateFrame("Frame", nil, mainFrame)
    mainFrame.iconContainer:SetPoint("TOP", mainFrame, "TOP", 0, 0)
    mainFrame.iconContainer:SetSize(200, ICON_SIZE)

    -- Label-Leiste unter Icons (geskinnter Hintergrund mit Text)
    mainFrame.labelBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    mainFrame.labelBar:SetPoint("TOP", mainFrame.iconContainer, "BOTTOM", 0, -2)
    mainFrame.labelBar:SetSize(100, 18)
    mainFrame.labelBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    mainFrame.labelBar:SetBackdropColor(0.05, 0.05, 0.05, 0.95)

    -- Label-Text
    mainFrame.labelBar.text = mainFrame.labelBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainFrame.labelBar.text:SetPoint("CENTER", 0, 0)
    mainFrame.labelBar.text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    mainFrame.labelBar.text:SetText("Missing Buffs")

    -- Erstelle Icon-Slots vor
    for i = 1, #RAID_BUFFS do
        buffIcons[i] = CreateBuffIcon(mainFrame.iconContainer, i)
        buffIcons[i]:Hide()
    end

    mainFrame:Hide()

    return mainFrame
end

---------------------------------------------------------------------------
-- SKINNING
---------------------------------------------------------------------------

local function ApplySkin()
    if not mainFrame then return end

    local gui = _G.GravityUI
    local sr, sg, sb, sa = 0.2, 1.0, 0.6, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    if gui and gui.GetSkinColor then
        sr, sg, sb, sa = gui:GetSkinColor()
    end
    if gui and gui.GetSkinBgColor then
        bgr, bgg, bgb, bga = gui:GetSkinBgColor()
    end

    -- Wende Skin auf Label-Leiste an
    if mainFrame.labelBar then
        mainFrame.labelBar:SetBackdropColor(bgr, bgg, bgb, bga)
        mainFrame.labelBar:SetBackdropBorderColor(sr, sg, sb, sa)
        if mainFrame.labelBar.text then
            -- Nutze eigene Text-Farbe falls gesetzt, sonst Standard weiß für Lesbarkeit
            local settings = GetSettings()
            local textColor = settings.labelTextColor
            if textColor then
                mainFrame.labelBar.text:SetTextColor(textColor[1], textColor[2], textColor[3], 1)
            else
                mainFrame.labelBar.text:SetTextColor(1, 1, 1, 1)  -- Weiß-Standard
            end
        end
    end   

    -- Wende Rand-Farbe auf Icons an
    for _, icon in ipairs(buffIcons) do
        icon:SetBackdropBorderColor(sr, sg, sb, sa)
        icon:SetBackdropColor(0, 0, 0, 0.8)
    end

    mainFrame.guiSkinColor = { sr, sg, sb, sa }
    mainFrame.guiBgColor = { bgr, bgg, bgb, bga }
end

-- Exponiere Refresh-Funktion für Live-Farb-Updates
function gui_RaidBuffs:RefreshColors()
    ApplySkin()
end

_G.GravityUI_RefreshRaidBuffColors = function()
    gui_RaidBuffs:RefreshColors()
end

---------------------------------------------------------------------------
-- UPDATE LOGIC
---------------------------------------------------------------------------

local function UpdateDisplay()
    local settings = GetSettings()
    if not settings.enabled then
        if mainFrame then mainFrame:Hide() end
        return
    end

    if not mainFrame then
        CreateMainFrame()
        ApplySkin()
    end
    
    local missing = GetMissingBuffs()

    if #missing == 0 then
        mainFrame:Hide()
        return
    end

    -- Positioniere Icons
    local iconSize = settings.iconSize or ICON_SIZE
    local totalWidth = (#missing * iconSize) + ((#missing - 1) * ICON_SPACING)
    local startX = -totalWidth / 2 + iconSize / 2

    for i, icon in ipairs(buffIcons) do
        if i <= #missing then
            local buff = missing[i]
            icon:SetSize(iconSize, iconSize)
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", mainFrame.iconContainer, "CENTER", startX + (i - 1) * (iconSize + ICON_SPACING), 0)
            icon.icon:SetTexture(GetBuffIcon(buff.spellId))
            icon.buffData = buff
            icon:Show()
        else
            icon:Hide()
        end
    end

    -- Aktualisiere Label-Schriftgröße und berechne Leisten-Höhe
    local fontSize = settings.labelFontSize or 12
    local labelBarHeight = fontSize + 8  -- Font size + padding
    local labelBarGap = 2

    mainFrame.labelBar.text:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    mainFrame.labelBar.text:SetText("Missing Buffs")

    -- Skaliere Frames (Mindestbreite basierend auf Icons und Text)
    local hideLabelBar = settings.hideLabelBar
    local minIconsWidth = (3 * iconSize) + (2 * ICON_SPACING)  -- 3 Icons Minimum
    local minTextWidth = fontSize * 8 + 10  -- Ungefähre Text-Breite + Abstand
    local minWidth = math.max(minIconsWidth, minTextWidth)
    local frameWidth = math.max(totalWidth, hideLabelBar and 0 or minWidth)

    mainFrame.iconContainer:SetSize(frameWidth, iconSize)

    -- Zeige/verstecke Label-Leiste basierend auf Einstellung
    if hideLabelBar then
        mainFrame.labelBar:Hide()
        mainFrame:SetSize(totalWidth, iconSize)
    else
        mainFrame.labelBar:SetSize(frameWidth, labelBarHeight)
        mainFrame.labelBar:Show()
        mainFrame:SetSize(frameWidth, iconSize + labelBarGap + labelBarHeight)
    end   

    -- Stelle gespeicherte Position wieder her
    if settings.position then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(settings.position.point, UIParent, settings.position.relPoint, settings.position.x, settings.position.y)
    end

    mainFrame:Show()
end

local function ThrottledUpdate()
    local now = GetTime()
    if now - lastUpdate < UPDATE_THROTTLE then return end
    lastUpdate = now
    UpdateDisplay()
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

-- Vorwärtsdeklaration für Reichweiten-Prüf-Funktionen (definiert nach Event-Handling)
local StartRangeCheck, StopRangeCheck

local function OnEvent(self, event, ...)
    local settings = GetSettings()

    -- Handhabe Reichweiten-Prüf-Ticker Start/Stopp unabhängig vom Aktiviert-Status
    if event == "PLAYER_LOGIN" or event == "GROUP_ROSTER_UPDATE" then
        if settings and settings.enabled and IsInGroup() then
            if StartRangeCheck then StartRangeCheck() end
        else
            if StopRangeCheck then StopRangeCheck() end
        end
    end

    if not settings or not settings.enabled then return end

    if event == "PLAYER_LOGIN" then
        CreateMainFrame()
        ApplySkin()
        C_Timer.After(2, UpdateDisplay)
    elseif event == "GROUP_ROSTER_UPDATE" then
        ThrottledUpdate()
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            -- Spieler-Aura-Änderungen nutzen kurzen Throttle um Spam während Buff/Debuff-Anwendung zu verhindern
            ThrottledUpdate()
        elseif unit and settings.providerMode and (unit:match("^party") or unit:match("^raid")) then
            -- Im Provider-Modus auch aktualisieren wenn sich Party/Raid-Mitglieder-Auren ändern
            ThrottledUpdate()
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        ThrottledUpdate()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(1, UpdateDisplay)
    elseif event == "UNIT_FLAGS" then
        -- Triggert wenn Einheit stirbt oder wiederbelebt wird
        local unit = ...
        if unit and (unit:match("^party") or unit:match("^raid")) then
            ThrottledUpdate()
        end
    elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" then
        -- Spieler-Tod/Wiederbelebung
        ThrottledUpdate()
    end
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("UNIT_FLAGS")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_UNGHOST")
eventFrame:SetScript("OnEvent", OnEvent)

-- Periodische Reichweiten-Prüfung (alle 5 Sekunden wenn außerhalb Kampf und in Gruppe)
local rangeCheckTicker

StopRangeCheck = function()
    if rangeCheckTicker then
        rangeCheckTicker:Cancel()
        rangeCheckTicker = nil
    end
end

StartRangeCheck = function()
    if rangeCheckTicker then return end
    rangeCheckTicker = C_Timer.NewTicker(5, function()
        local settings = GetSettings()
        if not settings or not settings.enabled then
            StopRangeCheck()
            return
        end
        if InCombatLockdown() then return end
        if not IsInGroup() then
            StopRangeCheck()
            return
        end
        UpdateDisplay()
    end)
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------

function gui_RaidBuffs:Toggle()
    local settings = GetSettings()
    settings.enabled = not settings.enabled
    UpdateDisplay()
end

function gui_RaidBuffs:ForceUpdate()
    UpdateDisplay()
    ApplySkin()			   
end

function gui_RaidBuffs:Debug()
    local settings = GetSettings()
    local lines = {}
    local playerClass = SafeUnitClass("player")
    table.insert(lines, "gui RaidBuffs Debug")
    table.insert(lines, "Provider Mode: " .. (settings.providerMode and "ON" or "OFF"))
    table.insert(lines, "Player Class: " .. (playerClass or "UNKNOWN"))
    table.insert(lines, "In Group: " .. (IsInGroup() and "YES" or "NO"))
    table.insert(lines, "In Raid: " .. (IsInRaid() and "YES" or "NO"))
    table.insert(lines, "In Combat: " .. (InCombatLockdown() and "YES" or "NO"))

    -- Scan and show group classes
    ScanGroupClasses()
    local classes = {}
    for class, _ in pairs(groupClasses) do
        table.insert(classes, class)
    end
    table.insert(lines, "Group Classes: " .. (#classes > 0 and table.concat(classes, ", ") or "NONE"))

    -- Show party members and their status
    table.insert(lines, "")
    table.insert(lines, "Party Members:")
    local numMembers = GetNumGroupMembers()
    table.insert(lines, "  GetNumGroupMembers: " .. numMembers)
    if IsInGroup() and not IsInRaid() then
        for i = 1, numMembers - 1 do
            local unit = "party" .. i
            local exists = SafeBooleanCheck(UnitExists(unit))
            local connected = SafeBooleanCheck(UnitIsConnected(unit))
            local dead = SafeBooleanCheck(UnitIsDeadOrGhost(unit))
            local available = IsUnitAvailable(unit)
            local name = UnitName(unit) or "?"
            local uClass = SafeUnitClass(unit)

            -- Detailed range check info (wrap everything for secret values)
            local uirRange, uirChecked = "?", "?"
            local ok1, r1, r2 = pcall(UnitInRange, unit)
            if ok1 then
                uirRange = IsSecretValue(r1) and "SECRET" or tostring(r1)
                uirChecked = IsSecretValue(r2) and "SECRET" or tostring(r2)
            end
            local cidResult = "?"
            local ok2, cid = pcall(CheckInteractDistance, unit, 1)
            if ok2 then
                cidResult = IsSecretValue(cid) and "SECRET" or tostring(cid)
            end
            local udsResult = "N/A"
            if UnitDistanceSquared then
                local ok3, distSq = pcall(UnitDistanceSquared, unit)
                if ok3 then
                    udsResult = IsSecretValue(distSq) and "SECRET" or tostring(distSq)
                end
            end
            local rangeInfo = " UnitInRange:" .. uirRange .. "/" .. uirChecked .. " CheckInteract:" .. cidResult .. " DistSq:" .. udsResult

            table.insert(lines, "  " .. unit .. ": " .. name .. " (" .. (uClass or "?") .. ") exists:" .. tostring(exists) .. " connected:" .. tostring(connected) .. " dead:" .. tostring(dead) .. " available:" .. tostring(available))
            table.insert(lines, "    Range APIs:" .. rangeInfo)
        end
    end

    -- Check each buff
    table.insert(lines, "")
    table.insert(lines, "Buff Status:")
    for _, buff in ipairs(RAID_BUFFS) do
        local buffRange = buff.range or 40
        local hasProvider = groupClasses[buff.providerClass] and true or false
        local providerInRange = IsProviderClassInRange(buff.providerClass, buffRange)
        local playerHas = PlayerHasBuff(buff.spellId, buff.name)
        local canProvide = buff.providerClass == playerClass
        local anyMissing = AnyGroupMemberMissingBuff(buff.spellId, buff.name, buffRange)
        local status = ""
        if hasProvider and not playerHas then
            if providerInRange then
                status = "MISSING"
            else
                status = "MISSING (out of range)"
            end
        elseif playerHas then
            status = "HAVE"
        else
            status = "No provider"
        end
        local providerInfo = " range:" .. buffRange .. "yd canProvide:" .. tostring(canProvide) .. " anyMissing:" .. tostring(anyMissing) .. " providerInRange:" .. tostring(providerInRange)
        table.insert(lines, "  " .. buff.name .. ": " .. status .. " (provider:" .. buff.providerClass .. " inGroup:" .. tostring(hasProvider) .. " hasBuff:" .. tostring(playerHas) .. providerInfo .. ")")

        -- If player can provide this buff and provider mode is on, show who's missing it
        if canProvide and settings.providerMode and IsInGroup() and not IsInRaid() then
            for i = 1, numMembers - 1 do
                local unit = "party" .. i
                if IsUnitAvailable(unit, buffRange) then
                    local has = UnitHasBuff(unit, buff.spellId, buff.name)
                    local name = UnitName(unit) or "?"
                    table.insert(lines, "    -> " .. unit .. " (" .. name .. "): " .. (has and "HAS" or "MISSING"))
                end
            end
        end
    end

    -- Output as error so it can be copied
    error(table.concat(lines, "\n"), 0)
end

-- Slash command for debug
SLASH_guiRAIDBUFFS1 = "/guibuffs"
SlashCmdList["guiRAIDBUFFS"] = function()
    if ns.RaidBuffs then
        ns.RaidBuffs:Debug()
    end
end

function gui_RaidBuffs:GetFrame()
    return mainFrame
end

function gui_RaidBuffs:TogglePreview()
    previewMode = not previewMode
    if previewMode then
        -- Show all raid buffs in preview mode
        previewBuffs = {}
        for i, buff in ipairs(RAID_BUFFS) do
            previewBuffs[i] = buff
        end
    else
        previewBuffs = nil
    end
    UpdateDisplay()
    return previewMode
end

function gui_RaidBuffs:IsPreviewMode()
    return previewMode
end

-- Global function for options panel
_G.GravityUI_ToggleRaidBuffsPreview = function()
    if ns.RaidBuffs then
        return ns.RaidBuffs:TogglePreview()
    end
    return false
end
