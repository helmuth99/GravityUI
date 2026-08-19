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
    frame:RegisterForDrag("LeftButton")
    frame:EnableMouse(false)

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local centerX, centerY = self:GetCenter()
        local screenCenterX, screenCenterY = UIParent:GetCenter()
        if centerX and screenCenterX then
            local x = math.floor(centerX - screenCenterX + 0.5)
            local y = math.floor(centerY - screenCenterY + 0.5)
            local settings = GetSettings()
            if settings then
                settings.xOffset = x
                settings.yOffset = y
                if ns.GUI and ns.GUI.Refresh then ns.GUI:Refresh() end
            end
        end
    end)

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

    -- Preview Highlight
    if CombatTimerState.isPreviewMode then
        if not settings.showBackdrop then
            frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            local r, g, b = ns.GetAccentColor()
            frame:SetBackdropBorderColor(r, g, b, 1)
            frame:SetBackdropColor(r, g, b, 0.2)
        else
            -- If user HAS a backdrop, maybe just a subtle glow or nothing to keep it clean
            -- We already checked showBackdrop above, so we have the user's colors.
        end
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

-- PERF: File-scope AnimTicker — runs in the WoW Animation engine (C-side).
-- Previously used Tick.Add which called every frame (~100/s) with manual throttle.
local _combatTicker = nil

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

    -- Start the 1Hz ticker (C-side throttle, zero Lua between ticks)
    if not _combatTicker then
        _combatTicker = ns.Tick.NewAnimTicker(function()
            UpdateTimerDisplay()
            return true
        end, 1.0)
    end
    _combatTicker.Start()
end

local function StopTimer()
    CombatTimerState.isInCombat = false
    if _combatTicker then _combatTicker.Stop() end
    if CombatTimerState.timerFrame then
        CombatTimerState.timerFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- EVENTS
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Register Mover
        if ns.Movers and ns.Movers.Register then
             -- We need to ensure frame exists or create it lazily. 
             -- Since Register needs a frame, we might need to create it now or update registry to support callbacks that return frames? 
             -- My Mover system takes a frame arg. 
             -- If I pass nil, the callback `TogglePreview(enabled)` works fine because it creates the frame.
             -- But standard UpdateDisplay might try to Show/Hide `data.frame`.
             -- So I should create the frame hidden.
             local frame = CreateTimerFrame()
             ns.Movers:Register("CombatTimer", frame, function(frame, enabled, force) CombatTimer.TogglePreview(enabled, force) end, "Combat Timer")
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
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
function CombatTimer.TogglePreview(show, isForceEditMode)
    CombatTimerState.isPreviewMode = show
    local frame = CombatTimerState.timerFrame or CreateTimerFrame()
    
    if show then
        if _combatTicker then _combatTicker.Stop() end
        frame:EnableMouse(true)
        UpdateAppearance()
        frame.text:SetText("01:23")

        -- Apply Standard Edit Mode Style
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            frame:SetBackdropColor(0, 0, 0, 0)
            frame:SetBackdropBorderColor(0, 0, 0, 0)
            ns.Movers:ApplyEditModeStyle(frame, true, "CombatTimer")
        end

        frame:Show()
    else
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(frame, false, "CombatTimer")
        end
        frame:EnableMouse(false)
        if not InCombatLockdown() then
            StopTimer()
        else
            -- If we were actually in combat, resume normal state
            local settings = GetSettings()
            if settings and settings.enabled then
                UpdateAppearance()
                if _combatTicker and not _combatTicker.IsPlaying() then
                    _combatTicker.Start()
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
