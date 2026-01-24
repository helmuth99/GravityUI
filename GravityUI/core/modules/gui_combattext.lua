---------------------------------------------------------------------------
-- GravityUI Combat Text Indicator
-- Zeigt +Combat oder -Combat beim Betreten/Verlassen des Kampfes an
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local gui = ns.gui or {}
ns.gui = gui

---------------------------------------------------------------------------
-- Status-Tracking für Fade-Animation
---------------------------------------------------------------------------
local CombatTextState = {
    fadeStart = 0,
    fadeStartAlpha = 1,
    fadeTargetAlpha = 0,
    fadeFrame = nil,
    textFrame = nil,
    displayTimer = nil,
}

---------------------------------------------------------------------------
-- Hole Einstellungen aus der Datenbank
---------------------------------------------------------------------------
local function GetSettings()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.combatText then
        return guiCore.db.profile.combatText
    end
    return nil
end

---------------------------------------------------------------------------
-- Erstelle das Text-Frame (einmalige Initialisierung)
---------------------------------------------------------------------------
local function CreateTextFrame()
    if CombatTextState.textFrame then return end

    local frame = CreateFrame("Frame", "GravityUI_CombatText", UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetSize(200, 50)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(100)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    text:SetTextColor(0, 0.74901960784314, 1, 1)  -- GravityUI Blauton-Akzent
    text:SetJustifyH("CENTER")
    frame.text = text

    frame:Hide()
    CombatTextState.textFrame = frame
end

---------------------------------------------------------------------------
-- OnUpdate-Handler für Fade-Animation
---------------------------------------------------------------------------
local function OnFadeUpdate(self, elapsed)
    local settings = GetSettings()
    local duration = (settings and settings.fadeTime) or 0.3

    local now = GetTime()
    local progress = math.min((now - CombatTextState.fadeStart) / duration, 1)

    -- Lineare Interpolation
    local alpha = CombatTextState.fadeStartAlpha +
        (CombatTextState.fadeTargetAlpha - CombatTextState.fadeStartAlpha) * progress

    if CombatTextState.textFrame then
        CombatTextState.textFrame:SetAlpha(alpha)
    end

    -- Prüfe ob Fade abgeschlossen ist
    if progress >= 1 then
        if CombatTextState.textFrame then
            CombatTextState.textFrame:Hide()
        end
        self:SetScript("OnUpdate", nil)
    end
end

---------------------------------------------------------------------------
-- Starte Fade-Animation
---------------------------------------------------------------------------
local function StartFade()
    if not CombatTextState.textFrame then return end

    local currentAlpha = CombatTextState.textFrame:GetAlpha()

    CombatTextState.fadeStart = GetTime()
    CombatTextState.fadeStartAlpha = currentAlpha
    CombatTextState.fadeTargetAlpha = 0

    -- Erstelle Fade-Frame falls benötigt
    if not CombatTextState.fadeFrame then
        CombatTextState.fadeFrame = CreateFrame("Frame")
    end
    CombatTextState.fadeFrame:SetScript("OnUpdate", OnFadeUpdate)
end

---------------------------------------------------------------------------
-- Zeige Combat-Text mit Nachricht an
---------------------------------------------------------------------------
local function ShowCombatText(message)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Erstelle Frame falls benötigt
    CreateTextFrame()

    if not CombatTextState.textFrame then return end

    -- Breche ausstehende Display-Timer ab
    if CombatTextState.displayTimer then
        CombatTextState.displayTimer:Cancel()
        CombatTextState.displayTimer = nil
    end

    -- Stoppe laufende Fade-Animation
    if CombatTextState.fadeFrame then
        CombatTextState.fadeFrame:SetScript("OnUpdate", nil)
    end

    -- Aktualisiere Position
    local xOffset = settings.xOffset or 0
    local yOffset = settings.yOffset or 100
    CombatTextState.textFrame:ClearAllPoints()
    CombatTextState.textFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)

    -- Aktualisiere Schriftgröße
    local fontSize = settings.fontSize or 24
    CombatTextState.textFrame.text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")

    -- Bestimme und setze Farbe basierend auf Nachricht
    local color
    if message == "+Combat" then
        color = settings.enterCombatColor or {0.204, 0.827, 0.6, 1}
    else
        color = settings.leaveCombatColor or {0.204, 0.827, 0.6, 1}
    end
    CombatTextState.textFrame.text:SetTextColor(color[1], color[2], color[3], color[4] or 1)

    -- Setze Text und zeige an
    CombatTextState.textFrame.text:SetText(message)
    CombatTextState.textFrame:SetAlpha(1)
    CombatTextState.textFrame:Show()

    -- Plane Fade-Animation nach Anzeigezeit
    local displayTime = settings.displayTime or 0.8
    CombatTextState.displayTimer = C_Timer.NewTimer(displayTime, function()
        StartFade()
        CombatTextState.displayTimer = nil
    end)
end

---------------------------------------------------------------------------
-- Kampf-Event-Handler
---------------------------------------------------------------------------
local function OnCombatStart()
    ShowCombatText("+Combat")
end

local function OnCombatEnd()
    ShowCombatText("-Combat")
end

---------------------------------------------------------------------------
-- Refresh-Funktion (wird bei Einstellungsänderungen aufgerufen)
---------------------------------------------------------------------------
local function RefreshCombatText()
    local settings = GetSettings()

    -- Bei Deaktivierung, verstecke sichtbaren Text
    if not settings or not settings.enabled then
        if CombatTextState.displayTimer then
            CombatTextState.displayTimer:Cancel()
            CombatTextState.displayTimer = nil
        end
        if CombatTextState.fadeFrame then
            CombatTextState.fadeFrame:SetScript("OnUpdate", nil)
        end
        if CombatTextState.textFrame then
            CombatTextState.textFrame:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- Initialisierung
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            CreateTextFrame()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()
    end
end)

---------------------------------------------------------------------------
-- Globale Refresh-Funktion für GUI
---------------------------------------------------------------------------
_G.GravityUI_RefreshCombatText = RefreshCombatText

---------------------------------------------------------------------------
-- Globale Preview-Funktion für Options-Panel
---------------------------------------------------------------------------
_G.GravityUI_PreviewCombatText = function(message)
    -- Umgehe Aktivierungs-Prüfung temporär für Preview
    local settings = GetSettings()
    if not settings then return end

    -- Erstelle Frame falls benötigt
    CreateTextFrame()

    if not CombatTextState.textFrame then return end

    -- Breche ausstehende Display-Timer ab
    if CombatTextState.displayTimer then
        CombatTextState.displayTimer:Cancel()
        CombatTextState.displayTimer = nil
    end

    -- Stoppe laufende Fade-Animation
    if CombatTextState.fadeFrame then
        CombatTextState.fadeFrame:SetScript("OnUpdate", nil)
    end

    -- Aktualisiere Position
    local xOffset = settings.xOffset or 0
    local yOffset = settings.yOffset or 100
    CombatTextState.textFrame:ClearAllPoints()
    CombatTextState.textFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)

    -- Aktualisiere Schriftgröße
    local fontSize = settings.fontSize or 24
    CombatTextState.textFrame.text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")

    -- Bestimme und setze Farbe basierend auf Nachricht
    local color
    if message == "+Combat" then
        color = settings.enterCombatColor or {0.204, 0.827, 0.6, 1}
    else
        color = settings.leaveCombatColor or {0.204, 0.827, 0.6, 1}
    end
    CombatTextState.textFrame.text:SetTextColor(color[1], color[2], color[3], color[4] or 1)

    -- Setze Text und zeige an
    CombatTextState.textFrame.text:SetText(message or "+Combat")
    CombatTextState.textFrame:SetAlpha(1)
    CombatTextState.textFrame:Show()

    -- Plane Fade-Animation nach Anzeigezeit
    local displayTime = settings.displayTime or 0.8
    CombatTextState.displayTimer = C_Timer.NewTimer(displayTime, function()
        StartFade()
        CombatTextState.displayTimer = nil
    end)
end

gui.CombatText = {
    Refresh = RefreshCombatText,
    Show = ShowCombatText,
    Preview = _G.GravityUI_PreviewCombatText,
}
