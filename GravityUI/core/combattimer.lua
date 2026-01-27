-- GravityUI - Combat Timer Module
-- Tracks and displays time elapsed in combat
local ADDON_NAME, ns = ...

local CombatTimer = {}
ns.CombatTimer = CombatTimer

local CombatTimerState = {
    combatStartTime = 0,
    timerFrame = nil,
    isInCombat = false,
    isPreviewMode = false,
    isInEncounter = false,
}

local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.combatTimer then
        return db.uiimprovements.combatTimer
    end
    return nil
end

---------------------------------------------------------------------------
-- FRAME CREATION
---------------------------------------------------------------------------
local function CreateTimerFrame()
    if CombatTimerState.timerFrame then return CombatTimerState.timerFrame end

    local frame = CreateFrame("Frame", "GravityUI_CombatTimer", UIParent, "BackdropTemplate")
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    frame:SetSize(80, 30)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(false) -- Allow clicking through in combat unless in configuration/preview

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER", 0, 0)
    text:SetText("00:00")
    frame.text = text

    frame:Hide()
    CombatTimerState.timerFrame = frame
    return frame
end

---------------------------------------------------------------------------
-- APPEARANCE
---------------------------------------------------------------------------
local function UpdateAppearance()
    local frame = CombatTimerState.timerFrame
    if not frame then return end

    local settings = GetSettings()
    if not settings then return end

    frame:SetSize(settings.width, settings.height)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.xOffset, settings.yOffset)
    
    frame:SetFrameStrata(settings.strata or "HIGH")
    frame:SetFrameLevel(settings.level or 50)

    -- Text
    local textColor
    if settings.useThemeColorText then
        textColor = {ns.GetAccentColor()}
    else
        textColor = settings.textColor
    end
    frame.text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
    
    -- Alignment
    frame.text:ClearAllPoints()
    if settings.textAlign == "LEFT" then
        frame.text:SetPoint("LEFT", 5, 1)
        frame.text:SetJustifyH("LEFT")
    elseif settings.textAlign == "RIGHT" then
        frame.text:SetPoint("RIGHT", -5, 1)
        frame.text:SetJustifyH("RIGHT")
    else -- CENTER
        frame.text:SetPoint("CENTER", 0, 1)
        frame.text:SetJustifyH("CENTER")
    end
    
    if ns.GUI and ns.GUI.SetFont then
        ns.GUI:SetFont(frame.text, settings.fontSize, "OUTLINE")
    else
        frame.text:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
    end

    -- Backdrop & Border
    if settings.showBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = not settings.hideBorder and "Interface\\Buttons\\WHITE8x8" or nil,
            edgeSize = not settings.hideBorder and settings.borderSize or 0,
        })
        frame:SetBackdropColor(unpack(settings.backdropColor))
        
        if not settings.hideBorder then
            local borderColor
            if settings.useThemeColorBorder then
                borderColor = {ns.GetAccentColor()}
            else
                borderColor = settings.borderColor
            end
            frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        end
    else
        frame:SetBackdrop(nil)
    end
end

---------------------------------------------------------------------------
-- LOGIC
---------------------------------------------------------------------------
local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function UpdateTimerDisplay()
    if not CombatTimerState.isInCombat then return end
    local elapsedCombatTime = GetTime() - CombatTimerState.combatStartTime
    if CombatTimerState.timerFrame and CombatTimerState.timerFrame.text then
        CombatTimerState.timerFrame.text:SetText(FormatTime(elapsedCombatTime))
    end
end

local function StartTimer()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    if settings.onlyEncounter and not CombatTimerState.isInEncounter then return end

    local frame = CreateTimerFrame()
    UpdateAppearance()
    
    CombatTimerState.combatStartTime = GetTime()
    CombatTimerState.isInCombat = true
    frame.text:SetText("00:00")
    frame:Show()

    -- Efficiency: Use a 1-second ticker instead of OnUpdate
    if CombatTimerState.ticker then CombatTimerState.ticker:Cancel() end
    CombatTimerState.ticker = C_Timer.NewTicker(1, UpdateTimerDisplay)
end

local function StopTimer()
    CombatTimerState.isInCombat = false
    if CombatTimerState.ticker then
        CombatTimerState.ticker:Cancel()
        CombatTimerState.ticker = nil
    end
    if CombatTimerState.timerFrame then
        CombatTimerState.timerFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- EVENTS
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        StartTimer()
    elseif event == "PLAYER_REGEN_ENABLED" then
        StopTimer()
    elseif event == "ENCOUNTER_START" then
        CombatTimerState.isInEncounter = true
        local settings = GetSettings()
        if settings and settings.enabled and settings.onlyEncounter and InCombatLockdown() then
            StartTimer()
        end
    elseif event == "ENCOUNTER_END" then
        CombatTimerState.isInEncounter = false
        local settings = GetSettings()
        if settings and settings.onlyEncounter then
            StopTimer()
        end
    end
end)

---------------------------------------------------------------------------
-- PREVIEW / API
---------------------------------------------------------------------------
function CombatTimer.TogglePreview(show)
    CombatTimerState.isPreviewMode = show
    if show then
        if CombatTimerState.ticker then CombatTimerState.ticker:Cancel(); CombatTimerState.ticker = nil end
        local frame = CreateTimerFrame()
        UpdateAppearance()
        frame.text:SetText("01:23")
        frame:Show()
    else
        if not InCombatLockdown() then
            StopTimer()
        else
            -- If we were actually in combat, resume normal state
            local settings = GetSettings()
            if settings and settings.enabled then
                UpdateAppearance()
                if not CombatTimerState.ticker then
                    CombatTimerState.ticker = C_Timer.NewTicker(1, UpdateTimerDisplay)
                end
            else
                StopTimer()
            end
        end
    end
end

function CombatTimer.Refresh()
    if CombatTimerState.timerFrame then
        UpdateAppearance()
        local settings = GetSettings()
        if settings and not settings.enabled then
            StopTimer()
        end
    end
end

function CombatTimer.IsPreviewMode()
    return CombatTimerState.isPreviewMode
end

-- Export for GUI
_G.GravityUI_RefreshCombatTimer = CombatTimer.Refresh
_G.GravityUI_ToggleCombatTimerPreview = CombatTimer.TogglePreview
_G.GravityUI_IsCombatTimerPreviewMode = CombatTimer.IsPreviewMode

-- Export for Core
ns.RefreshCombatTimer = CombatTimer.Refresh
