---------------------------------------------------------------------------
-- GravityUI Kampf-Timer
-- Zeigt verstrichene Zeit im Kampf (setzt beim Kampf-Ende zurück)
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local gui = ns.gui or {}
ns.gui = gui

---------------------------------------------------------------------------
-- Status-Tracking
---------------------------------------------------------------------------
local CombatTimerState = {
    combatStartTime = 0,
    timerFrame = nil,
    isInCombat = false,
    isPreviewMode = false,
    isInEncounter = false,  -- Tracke Boss-Encounter-State														 
}

---------------------------------------------------------------------------
-- Hole Einstellungen von Datenbank
---------------------------------------------------------------------------
local function GetSettings()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.combatTimer then
        return guiCore.db.profile.combatTimer
    end
    return nil
end

---------------------------------------------------------------------------
-- Backdrop-Template für moderne WoW-API
---------------------------------------------------------------------------
local LSM = LibStub("LibSharedMedia-3.0", true)

local function GetBackdropInfo(borderTextureName, borderSize)
    local edgeFile = nil
    local edgeSize = 0

    -- Nutze LSM Border-Textur falls angegeben und nicht "None"
    if borderTextureName and borderTextureName ~= "None" and LSM then
        edgeFile = LSM:Fetch("border", borderTextureName)
        edgeSize = borderSize or 1
    end

    return {	
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = edgeFile,
    tile = false,
    tileSize = 0,
    edgeSize = edgeSize,
    insets = { left = 0, right = 1, top = 0, bottom = 1 },
}
end

---------------------------------------------------------------------------
-- Erstelle einheitliche Rand-Linien (für soliden "None"-Rand)
---------------------------------------------------------------------------
local function CreateBorderLines(frame)
    if frame.borderLines then return frame.borderLines end

    local borders = {}

    -- Nutze OVERLAY-Layer zum Rendern über Backdrop, verhindert Blend-Artefakte
    borders.top = frame:CreateTexture(nil, "OVERLAY")
    borders.top:SetColorTexture(0, 0, 0, 1)
    borders.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, 0)

    borders.bottom = frame:CreateTexture(nil, "OVERLAY")
    borders.bottom:SetColorTexture(0, 0, 0, 1)
    borders.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 1)
    borders.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

    borders.left = frame:CreateTexture(nil, "OVERLAY")
    borders.left:SetColorTexture(0, 0, 0, 1)
    borders.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 1)

    borders.right = frame:CreateTexture(nil, "OVERLAY")
    borders.right:SetColorTexture(0, 0, 0, 1)
    borders.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 1)

    frame.borderLines = borders
    return borders
end

local function UpdateBorderLines(frame, size, r, g, b, a, hide)
    local borders = frame.borderLines
    if not borders then return end

    -- Verstecke alle falls angefordert oder Größe ist 0
    if hide or size <= 0 then
        for _, line in pairs(borders) do
            line:Hide()
        end
        return
    end

    -- Setze Größe und Farbe
    borders.top:SetHeight(size)
    borders.bottom:SetHeight(size)
    borders.left:SetWidth(size)
    borders.right:SetWidth(size)

    borders.top:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
    borders.bottom:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
    borders.left:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
    borders.right:SetColorTexture(r or 0, g or 0, b or 0, a or 1)

    for _, line in pairs(borders) do
        line:Show()
    end
end

---------------------------------------------------------------------------
-- Hole Font-Pfad von LibSharedMedia
---------------------------------------------------------------------------
local function GetFontPath(fontName)
    if LSM and fontName then
        local path = LSM:Fetch("font", fontName)
        if path then return path end
    end
    return "Fonts\\FRIZQT__.TTF"
end

---------------------------------------------------------------------------
-- Erstelle den Timer-Frame (einmalige Einrichtung)
---------------------------------------------------------------------------
local function CreateTimerFrame()
    if CombatTimerState.timerFrame then return end

    local frame = CreateFrame("Frame", "GravityUI_CombatTimer", UIParent, "BackdropTemplate")
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    frame:SetSize(80, 30)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(50)

    -- Richte Backdrop ein (nur Hintergrund)
    frame:SetBackdrop(GetBackdropInfo())
    frame:SetBackdropColor(0, 0, 0, 0.6)

    -- Erstelle manuelle Rand-Linien für einheitliche Kanten
    CreateBorderLines(frame)
    UpdateBorderLines(frame, 1, 0, 0, 0, 1)
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("Left", frame, "Left", 0, 0)
    text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetJustifyH("Left")
    text:SetJustifyV("MIDDLE")
    text:SetText("0:00")
    frame.text = text

    frame:Hide()
    CombatTimerState.timerFrame = frame
end

---------------------------------------------------------------------------
-- Formatiere verstrichene Zeit als MM:SS
---------------------------------------------------------------------------
local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

---------------------------------------------------------------------------
-- OnUpdate-Handler für Timer
---------------------------------------------------------------------------
local function OnTimerUpdate(self, elapsed)
    if not CombatTimerState.isInCombat then return end

    local now = GetTime()
    local elapsedTime = now - CombatTimerState.combatStartTime

    if CombatTimerState.timerFrame and CombatTimerState.timerFrame.text then
        CombatTimerState.timerFrame.text:SetText(FormatTime(elapsedTime))
    end
end

---------------------------------------------------------------------------
-- Hole globale Addon-Font-Einstellung
---------------------------------------------------------------------------
local function GetGlobalFont()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.general and guiCore.db.profile.general.font then
        return guiCore.db.profile.general.font
    end
    return "Gravity"
end

---------------------------------------------------------------------------
-- Hole Spieler-Klassen-Farbe
---------------------------------------------------------------------------
local function GetClassColor()
    local _, class = UnitClass("player")
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return {c.r, c.g, c.b, 1}
    end
    return {1, 1, 1, 1}  -- Fallback auf Weiß
end

---------------------------------------------------------------------------
-- Aktualisiere Timer-Erscheinung von Einstellungen
---------------------------------------------------------------------------
local function UpdateTimerAppearance()
    if not CombatTimerState.timerFrame then
        CreateTimerFrame()
    end

    local settings = GetSettings()
    if not settings then return end
    local align = settings.align or "LEFT" -- "LEFT", "CENTER" oder "RIGHT" von DB
    local frame = CombatTimerState.timerFrame

    -- Aktualisiere Größe
    local width = settings.width or 80
    local height = settings.height or 30
    frame:SetSize(width, height)

    -- Aktualisiere Position
    local xOffset = settings.xOffset or 0
    local yOffset = settings.yOffset or -150
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)

    -- Aktualisiere Font (nutze LSM) - prüfe ob eigener Font oder globaler genutzt wird
    local fontSize = settings.fontSize or 16
    local fontName = settings.useCustomFont and settings.font or GetGlobalFont()
    local fontPath = GetFontPath(fontName)
    frame.text:SetFont(fontPath, fontSize, "OUTLINE")

    -- Aktualisiere Text-Farbe (nutze Klassen-Farbe oder eigene Farbe)
    local textColor
    if settings.useClassColorText then
        textColor = GetClassColor()
    else
        textColor = settings.textColor or {1, 1, 1, 1}
    end
    frame.text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)

    -- Aktualisiere Backdrop und Rand
    local showBackdrop = settings.showBackdrop
    if showBackdrop == nil then showBackdrop = true end

    local borderSize = settings.borderSize or 1
    local borderTexture = settings.borderTexture or "None"
    local useLSMBorder = borderTexture ~= "None" and borderSize > 0

    -- Hole Rand-Farbe
    local borderColor
    if settings.useClassColorBorder then
        borderColor = GetClassColor()
    else
        borderColor = settings.borderColor or {0, 0, 0, 1}
    end

    -- Richte Backdrop mit oder ohne LSM-Rand ein
    -- Überspringe LSM-Rand falls hideBorder aktiviert ist
    local hideBorder = settings.hideBorder
    local effectiveUseLSMBorder = useLSMBorder and not hideBorder
																	    
    if showBackdrop or effectiveUseLSMBorder then
        frame:SetBackdrop(GetBackdropInfo(hideBorder and "None" or borderTexture, hideBorder and 0 or borderSize))

        if showBackdrop then
            local bgColor = settings.backdropColor or {0, 0, 0, 0.6}
            frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.6)
        else
            frame:SetBackdropColor(0, 0, 0, 0)
        end

        if effectiveUseLSMBorder then
            frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        end
    else
        frame:SetBackdrop(nil)
    end

    -- Aktualisiere manuelle Rand-Linien (nur genutzt wenn kein LSM-Rand ausgewählt)
    -- Verstecke alle Ränder falls hideBorder aktiviert ist
    local hideBorder = settings.hideBorder
    CreateBorderLines(frame)  -- Stelle sicher dass Ränder existieren
    UpdateBorderLines(frame, borderSize, borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1, useLSMBorder or hideBorder)

    -- Stelle sicher dass Text immer zentriert ist
    frame.text:ClearAllPoints()
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, 1)
end

---------------------------------------------------------------------------
-- Kampf-Start-Handler
---------------------------------------------------------------------------
local function OnCombatStart()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Starte keinen Kampf-Timer wenn wir im Preview-Modus sind
    if CombatTimerState.isPreviewMode then return end

    -- Falls Nur-Encounter-Modus aktiviert ist und wir nicht in einem Encounter sind, nicht zeigen
    if settings.onlyShowInEncounters and not CombatTimerState.isInEncounter then
        CombatTimerState.isInCombat = true  -- Tracke Kampf-State aber zeige Timer nicht
        return
    end
    CreateTimerFrame()
    UpdateTimerAppearance()

    CombatTimerState.combatStartTime = GetTime()
    CombatTimerState.isInCombat = true

    if CombatTimerState.timerFrame then
        CombatTimerState.timerFrame.text:SetText("00:00")
        CombatTimerState.timerFrame:Show()
        CombatTimerState.timerFrame:SetScript("OnUpdate", OnTimerUpdate)
    end
end

---------------------------------------------------------------------------
-- Kampf-Ende-Handler
---------------------------------------------------------------------------
local function OnCombatEnd()
    -- Verstecke nicht falls im Preview-Modus
    if CombatTimerState.isPreviewMode then return end

    CombatTimerState.isInCombat = false

    if CombatTimerState.timerFrame then
        CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
        CombatTimerState.timerFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- Encounter-Start-Handler (Boss-Encounters)
---------------------------------------------------------------------------
local function OnEncounterStart()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    CombatTimerState.isInEncounter = true

    -- Störe Preview-Modus nicht
    if CombatTimerState.isPreviewMode then return end

    -- Falls Nur-Encounter-Modus und wir im Kampf sind aber Timer nicht gezeigt, zeige ihn jetzt
    if settings.onlyShowInEncounters and CombatTimerState.isInCombat then
        CreateTimerFrame()
        UpdateTimerAppearance()

        CombatTimerState.combatStartTime = GetTime()

        if CombatTimerState.timerFrame then
            CombatTimerState.timerFrame.text:SetText("00:00")
            CombatTimerState.timerFrame:Show()
            CombatTimerState.timerFrame:SetScript("OnUpdate", OnTimerUpdate)
        end
    end
end

---------------------------------------------------------------------------
-- Encounter-Ende-Handler
---------------------------------------------------------------------------
local function OnEncounterEnd()
    CombatTimerState.isInEncounter = false

    local settings = GetSettings()
    if not settings then return end

    -- Verstecke nicht falls im Preview-Modus
    if CombatTimerState.isPreviewMode then return end

    -- Falls Nur-Encounter-Modus aktiviert ist, verstecke Timer wenn Encounter endet
    -- (selbst wenn noch im Kampf)
    if settings.onlyShowInEncounters and CombatTimerState.timerFrame then														 
        CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
        CombatTimerState.timerFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- Refresh-Funktion (aufgerufen wenn Einstellungen sich ändern)
---------------------------------------------------------------------------
local function RefreshCombatTimer()
    local settings = GetSettings()

    -- Falls deaktiviert und nicht im Preview-Modus, verstecke Timer
    if (not settings or not settings.enabled) and not CombatTimerState.isPreviewMode then
        CombatTimerState.isInCombat = false
        if CombatTimerState.timerFrame then
            CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
            CombatTimerState.timerFrame:Hide()
        end
        return
    end

    -- Aktualisiere Erscheinung falls Einstellungen sich geändert haben
    UpdateTimerAppearance()

    -- Falls aktuell im Kampf (und nicht Preview), stelle sicher dass sichtbar
    if InCombatLockdown() and CombatTimerState.timerFrame and not CombatTimerState.isPreviewMode then
        if not CombatTimerState.isInCombat then
            -- Kampf betreten während Feature deaktiviert war, starte jetzt
            CombatTimerState.combatStartTime = GetTime()
            CombatTimerState.isInCombat = true
            CombatTimerState.timerFrame.text:SetText("0:00")
            CombatTimerState.timerFrame:Show()
            CombatTimerState.timerFrame:SetScript("OnUpdate", OnTimerUpdate)
        end
    end
end

---------------------------------------------------------------------------
-- Toggle Preview-Modus (für Options-Panel)
---------------------------------------------------------------------------
local function TogglePreview(enable)
    CreateTimerFrame()
    if not CombatTimerState.timerFrame then return end

    CombatTimerState.isPreviewMode = enable

    if enable then
        -- Zeige Preview
        UpdateTimerAppearance()
        CombatTimerState.timerFrame.text:SetText("01:23")
        CombatTimerState.timerFrame:Show()
        CombatTimerState.timerFrame:SetScript("OnUpdate", nil)  -- Kein Zählen im Preview
    else
        -- Verstecke Preview (außer tatsächlich im Kampf mit aktiviertem Feature)
        local settings = GetSettings()
        if settings and settings.enabled and InCombatLockdown() then
            -- Nicht verstecken, wir sind im Kampf mit aktiviertem Feature
            CombatTimerState.isInCombat = true
            CombatTimerState.combatStartTime = GetTime()
            CombatTimerState.timerFrame.text:SetText("0:00")
            CombatTimerState.timerFrame:SetScript("OnUpdate", OnTimerUpdate)
        else
            CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
            CombatTimerState.timerFrame:Hide()
        end
    end
end

local function IsPreviewMode()
    return CombatTimerState.isPreviewMode
end

---------------------------------------------------------------------------
-- Initialisierung
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")					 
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            CreateTimerFrame()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()
    elseif event == "ENCOUNTER_START" then
        OnEncounterStart()
    elseif event == "ENCOUNTER_END" then
        OnEncounterEnd()				
    end
end)

---------------------------------------------------------------------------
-- Globale Funktionen für GUI
---------------------------------------------------------------------------
_G.GravityUI_RefreshCombatTimer = RefreshCombatTimer
_G.GravityUI_ToggleCombatTimerPreview = TogglePreview
_G.GravityUI_IsCombatTimerPreviewMode = IsPreviewMode

gui.CombatTimer = {
    Refresh = RefreshCombatTimer,
    TogglePreview = TogglePreview,
    IsPreviewMode = IsPreviewMode,
}