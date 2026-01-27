---------------------------------------------------------------------------
-- GravityUI Skyriding Module
-- Unified continuous vigor bar with segment markers
-- Ported 1:1 from GravityUI
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")

local skyridingFrame
local vigorBar, vigorBackground, rechargeOverlay, shadowTexture
local flashTexture, flashAnim
local segmentMarkers = {}
local secondWindPips = {}
local vigorText, speedText
local secondWindText, secondWindMiniBar
local swBackground, swBorder, swRechargeOverlay
local swSegmentMarkers = {}
local abilityIcon, abilityIconCooldown

-- State
local lastVigorCharges = -1
local lastMaxCharges = -1
local lastSecondWind = -1
local isGliding = false
local canGlide = false
local groundedTime = 0
local fadeStart = 0
local fadeStartAlpha = 1
local fadeTargetAlpha = 1
local inCombat = false

-- Smooth animation state
local currentBarValue = 0
local targetBarValue = 0
local swCurrentValue = 0
local swTargetValue = 0
local swMaxCharges = 0
local LERP_SPEED = 8
local UPDATE_THROTTLE = 0.05
local elapsed = 0

-- Constants
local VIGOR_SPELL_ID = 372608
local SECOND_WIND_SPELL_ID = 425782
local WHIRLING_SURGE_SPELL_ID = 361584
local DOT_TEXTURE = "Interface/AddOns/GravityUI/assets/cursor/gui_reticle_dot"

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local cachedSettings
local function GetSettings()
    if not cachedSettings then
        cachedSettings = ns.db and ns.db.profile and ns.db.profile.skyriding
    end
    return cachedSettings
end

local function GetFontPath()
    local fontPath, _ = ns.GetFont()
    return fontPath
end

local function GetVigorInfo()
    local data = C_Spell.GetSpellCharges(VIGOR_SPELL_ID)
    if not data then return 0, 6, 0, 0, 1 end
    
    -- API restriction check (IsSecretValue replacement)
    -- If we are in combat and data looks suspicious (0/6 is typical "unknown" state), treat as invalid
    if inCombat and data.currentCharges == 0 and data.maxCharges == 6 then
        return 0, 6, 0, 0, 1 -- Return as is, letting logic handle hide
    end
    
    return data.currentCharges or 0,
           data.maxCharges or 6,
           data.cooldownStartTime or 0,
           data.cooldownDuration or 0,
           data.chargeModRate or 1
end

local function GetSecondWindInfo()
    local data = C_Spell.GetSpellCharges(SECOND_WIND_SPELL_ID)
    if not data then return 0, 0, 0, 0, 1 end
    return data.currentCharges or 0,
           data.maxCharges or 0,
           data.cooldownStartTime or 0,
           data.cooldownDuration or 0,
           data.chargeModRate or 1
end

local function GetGlidingInfo()
    local g, c, s = C_PlayerInfo.GetGlidingInfo()
    return g or false, c or false, s or 0
end

local function ApplyCooldownFont(cooldown, fontSize)
    if not cooldown then return end
    local fontPath = GetFontPath()
    local ok, regions = pcall(function() return { cooldown:GetRegions() } end)
    if ok and regions then
        for _, region in ipairs(regions) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                region:SetFont(fontPath, fontSize, "OUTLINE")
            end
        end
    end
end

---------------------------------------------------------------------------
-- Fade Animation
---------------------------------------------------------------------------
local function StartSkyridingFade(targetAlpha)
    if not skyridingFrame then return end
    
    -- Prevent repeated restarts if already fading to the same target
    if fadeStart > 0 and math.abs(fadeTargetAlpha - targetAlpha) < 0.01 then
        return
    end

    local currentAlpha = skyridingFrame:GetAlpha()
    if math.abs(currentAlpha - targetAlpha) < 0.01 then 
        -- Already at target, ensure clean state
        skyridingFrame:SetAlpha(targetAlpha)
        fadeStart = 0
        if targetAlpha < 0.01 then skyridingFrame:Hide() end
        return 
    end
    
    fadeStart = GetTime()
    fadeStartAlpha = currentAlpha
    fadeTargetAlpha = targetAlpha
end

local function UpdateVisibility()
    local settings = GetSettings()
    if not settings or not skyridingFrame then return end

    if not settings.enabled then
        skyridingFrame:Hide()
        return
    end

    local gliding, canGlideNow, _ = GetGlidingInfo()
    isGliding = gliding
    canGlide = canGlideNow

    local visibility = settings.visibility or "AUTO"
    local fadeDelay = settings.fadeDelay or 3

    -- Hide when in combat with secret/invalid values (Legacy behavior)
    if inCombat and canGlideNow then
        local current, max = GetVigorInfo()
        if current == 0 and max == 6 then
            skyridingFrame:Hide()
            return
        end
    end

    if visibility == "ALWAYS" then
        skyridingFrame:Show()
        StartSkyridingFade(1)
        
    elseif visibility == "FLYING_ONLY" then
        if canGlideNow then
            skyridingFrame:Show()
            StartSkyridingFade(1)
        else
            StartSkyridingFade(0)
        end
        
    elseif visibility == "AUTO" then
        if isGliding then
            -- Flying - show immediately
            groundedTime = 0
            fadeStart = 0
            skyridingFrame:SetAlpha(1)
            skyridingFrame:Show()
            if abilityIcon then abilityIcon:SetAlpha(1) end
            if abilityIconCooldown then abilityIconCooldown:SetAlpha(1) end
        elseif canGlideNow then
            -- Grounded but in zone
            if groundedTime >= fadeDelay then
                StartSkyridingFade(0)
            else
                skyridingFrame:Show()
                StartSkyridingFade(1)
            end
        else
            -- Cannot fly here
            StartSkyridingFade(0)
        end
    end
end

-- ...

local function UpdateSegmentMarkers(maxCharges)
    local settings = GetSettings()
    if not settings or not skyridingFrame then return end
    
    local showSegments = settings.showSegments
    local barWidth = skyridingFrame:GetWidth()
    local barHeight = skyridingFrame:GetHeight()
    local segmentWidth = barWidth / maxCharges
    local thickness = settings.segmentThickness or 1
    
    -- Color Logic: Prefer setting, fallback to calculated soft color
    local color
    if settings.segmentColor then
        color = settings.segmentColor
    else
        local barColor = settings.barColor or {0.2, 0.8, 1.0, 1}
        color = {barColor[1] * 0.25, barColor[2] * 0.25, barColor[3] * 0.25, 0.6}
    end
    
    for i = 1, 10 do
        local marker = segmentMarkers[i]
        if showSegments and i < maxCharges then
            local xPos = i * segmentWidth
            marker:ClearAllPoints()
            marker:SetPoint("LEFT", vigorBar, "LEFT", xPos - (thickness/2), 0)
            marker:SetWidth(math.max(1, thickness))
            marker:SetHeight(barHeight)
            marker:SetVertexColor(unpack(color))
            marker:Show()
        else
            marker:Hide()
        end
    end
end

local function UpdateVigorBar()
    local settings = GetSettings()
    local current, max = GetVigorInfo()
    
    if max ~= lastMaxCharges then
        UpdateSegmentMarkers(max)
        lastMaxCharges = max
    end
    
    if current > lastVigorCharges and lastVigorCharges >= 0 then
        -- Snap
        currentBarValue = current / max
        vigorBar:SetValue(currentBarValue)
        
        -- Flash
        if flashAnim and not flashAnim:IsPlaying() then
            local barWidth = skyridingFrame:GetWidth()
            local segmentWidth = barWidth / max
            local segmentStart = lastVigorCharges * segmentWidth
            flashTexture:ClearAllPoints()
            flashTexture:SetPoint("LEFT", vigorBar, "LEFT", segmentStart, 0)
            flashTexture:SetWidth(segmentWidth)
            flashTexture:SetHeight(skyridingFrame:GetHeight())
            flashAnim:Play()
        end
    end
    
    targetBarValue = current / max
    
    if settings.showVigorText then
        if settings.vigorTextFormat == "FRACTION" then
            vigorText:SetText(string.format("%d/%d", current, max))
        else
            vigorText:SetText(tostring(current))
        end
        vigorText:Show()
    else
        vigorText:Hide()
    end
    
    lastVigorCharges = current
end

local function UpdateRechargeAnimation()
    local settings = GetSettings()
    local current, max, startTime, duration, modRate = GetVigorInfo()
    
    if current >= max or duration == 0 then
        rechargeOverlay:Hide()
        return
    end
    
    local now = GetTime()
    local elapsedTime = (now - startTime) * modRate
    local progress = math.min(1, elapsedTime / duration)
    
    local barWidth = skyridingFrame:GetWidth()
    local segmentWidth = barWidth / max
    local segmentStart = current * segmentWidth
    local fillWidth = math.max(1, progress * segmentWidth)
    
    local color = settings.rechargeColor or {0.4, 0.9, 1.0, 0.6}
    
    rechargeOverlay:ClearAllPoints()
    rechargeOverlay:SetPoint("LEFT", vigorBar, "LEFT", segmentStart, 0)
    rechargeOverlay:SetWidth(fillWidth)
    rechargeOverlay:SetHeight(skyridingFrame:GetHeight())
    
    local pulse = 0.7 + 0.3 * math.sin(now * 4)
    rechargeOverlay:SetVertexColor(color[1], color[2], color[3], (color[4] or 0.6) * pulse)
    rechargeOverlay:Show()
end

local function UpdateSecondWind()
    local settings = GetSettings()
    local mode = settings.secondWindMode or "PIPS"
    local current, max = GetSecondWindInfo()
    
    -- Color
    local color = settings.secondWindColor or {1, 0.8, 0.2, 1}
    if settings.useThemeColorSecondWind then
        local r, g, b, a = ns.GetAccentColor()
        color = {r, g, b, a}
    end
    
    -- Hide all
    for i=1,5 do
        secondWindPips[i]:Hide()
        if secondWindPips[i].glow then secondWindPips[i].glow:Hide() end
        if swSegmentMarkers[i] then swSegmentMarkers[i]:Hide() end
    end
    secondWindText:Hide()
    secondWindMiniBar:Hide()
    
    if max == 0 or mode == "HIDDEN" then return end
    
    if mode == "PIPS" then
        local scale = settings.secondWindScale or 1.0
        local pipSize = 6 * scale
        local pipGap = 4 * scale
        local glowSize = 14 * scale
        local totalWidth = (max * pipSize) + ((max-1) * pipGap)
        local startX = -totalWidth / 2
        
        for i=1, max do
            local pip = secondWindPips[i]
            local xPos = startX + ((i-1)*(pipSize+pipGap))
            
            pip:ClearAllPoints()
            pip:SetPoint("BOTTOM", skyridingFrame, "TOP", xPos + (pipSize/2), 3)
            pip:SetSize(pipSize, pipSize)
            
            if pip.glow then
                pip.glow:SetSize(glowSize, glowSize)
                pip.glow:ClearAllPoints()
                pip.glow:SetPoint("CENTER", pip, "CENTER", 0, 0)
            end
            
            if i <= current then
                pip:SetVertexColor(unpack(color))
                pip:Show()
                if pip.glow then
                    pip.glow:SetVertexColor(color[1], color[2], color[3], 0.5)
                    pip.glow:Show()
                end
            else
                pip:SetVertexColor(0.25, 0.25, 0.25, 0.5)
                pip:Show()
            end
        end
        
    elseif mode == "TEXT" then
        secondWindText:SetText(string.format("SW: %d/%d", current, max))
        secondWindText:SetTextColor(unpack(color))
        secondWindText:Show()
        
    elseif mode == "MINIBAR" then
        local swHeight = settings.secondWindHeight or 6
        secondWindMiniBar:ClearAllPoints()
        secondWindMiniBar:SetPoint("TOPLEFT", skyridingFrame, "BOTTOMLEFT", 0, -2)
        secondWindMiniBar:SetPoint("TOPRIGHT", skyridingFrame, "BOTTOMRIGHT", 0, -2)
        secondWindMiniBar:SetHeight(swHeight)
        secondWindMiniBar:SetMinMaxValues(0, max)
        
        -- Logic: snap if charge gained
        if current > lastSecondWind and lastSecondWind >= 0 then
            swCurrentValue = current / max
            secondWindMiniBar:SetValue(swCurrentValue * max)
        end
        swTargetValue = current / max
        swMaxCharges = max
        
        secondWindMiniBar:SetStatusBarColor(unpack(color))
        secondWindMiniBar:Show()
        
        -- Segments
        local barWidth = skyridingFrame:GetWidth()
        local segmentWidth = barWidth / max
        local thickness = settings.segmentThickness or 1
        local softColor = { color[1]*0.25, color[2]*0.25, color[3]*0.25, 0.6 }
        
        for i=1,5 do
            if i < max then
                local marker = swSegmentMarkers[i]
                local xPos = i * segmentWidth
                marker:ClearAllPoints()
                marker:SetPoint("LEFT", secondWindMiniBar, "LEFT", xPos - (thickness/2), 0)
                marker:SetWidth(math.max(1, thickness))
                marker:SetHeight(swHeight)
                marker:SetVertexColor(unpack(softColor))
                marker:Show()
            end
        end
    end
    lastSecondWind = current
end

local function UpdateSecondWindRecharge()
    local settings = GetSettings()
    if not settings or not secondWindMiniBar or not swRechargeOverlay then return end

    -- Only show for MINIBAR mode
    local mode = settings.secondWindMode or "PIPS"
    if mode ~= "MINIBAR" then
        swRechargeOverlay:Hide()
        return
    end

    local current, max, startTime, duration, modRate = GetSecondWindInfo()

    -- If no Second Wind available, fully charged, or not recharging, hide overlay
    if max == 0 or current >= max or duration == 0 then
        swRechargeOverlay:Hide()
        return
    end

    -- Calculate progress of current charge
    local now = GetTime()
    local elapsedTime = (now - startTime) * modRate
    local progress = math.min(1, elapsedTime / duration)

    -- Position recharge overlay within the current segment
    local barWidth = secondWindMiniBar:GetWidth()
    local barHeight = secondWindMiniBar:GetHeight()
    local segmentWidth = barWidth / max
    local segmentStart = current * segmentWidth
    local fillWidth = math.max(1, progress * segmentWidth)

    -- Use SW color (with theme color support)
    local color
    if settings.useThemeColorSecondWind then
        local r, g, b = ns.GetAccentColor()
        color = {r, g, b, 0.6}
    else
        color = {1, 0.9, 0.4, 0.6}  -- Slightly brighter gold
    end

    swRechargeOverlay:ClearAllPoints()
    swRechargeOverlay:SetPoint("LEFT", secondWindMiniBar, "LEFT", segmentStart, 0)
    swRechargeOverlay:SetWidth(fillWidth)
    swRechargeOverlay:SetHeight(barHeight)

    -- Pulse alpha for visual feedback
    local pulse = 0.7 + 0.3 * math.sin(now * 4)
    swRechargeOverlay:SetVertexColor(color[1], color[2], color[3], color[4] * pulse)
    swRechargeOverlay:Show()
end

local function UpdateSpeed()
    local settings = GetSettings()
    if not settings.showSpeed then
        speedText:Hide()
        return
    end
    
    local _, _, speed = GetGlidingInfo()
    
    -- Fallback: If GetGlidingInfo returns 0 or nil, use real unit speed
    if not speed or speed == 0 then
        speed = GetUnitSpeed("player")
    end
    
    local format = settings.speedFormat
    if format == "PERCENT" then
        -- Default run speed is ~7 y/s. Legacy typically formatted as * 10.
        speedText:SetText(string.format("%d%%", math.floor(speed * 10)))
    else
        speedText:SetText(string.format("%.1f", speed))
    end
    speedText:Show()
end

local function UpdateAbilityIcon()
    local settings = GetSettings()
    if not settings.showAbilityIcon then
        abilityIcon:Hide()
        return
    end
    
    local vigorHeight = settings.vigorHeight
    local swMode = settings.secondWindMode
    local _, swMax = GetSecondWindInfo()
    
    local totalHeight = vigorHeight
    local yOffset = 0
    if swMode == "MINIBAR" and swMax > 0 then
        local swHeight = settings.secondWindHeight or 6
        totalHeight = vigorHeight + 2 + swHeight
        yOffset = -(2 + swHeight) / 2
    end
    
    abilityIcon:SetSize(totalHeight, totalHeight)
    abilityIcon:ClearAllPoints()
    abilityIcon:SetPoint("LEFT", skyridingFrame, "RIGHT", 2, yOffset)
    
    local cd = C_Spell.GetSpellCooldown(WHIRLING_SURGE_SPELL_ID)
    if cd and cd.duration and cd.duration > 0 then
        abilityIconCooldown:SetCooldown(cd.startTime, cd.duration)
    else
        abilityIconCooldown:Clear()
    end
    
    abilityIcon:Show() -- Only shown if parent is shown
end

---------------------------------------------------------------------------
-- OnUpdate
---------------------------------------------------------------------------
local function OnUpdate(self, delta)
    elapsed = elapsed + delta
    if elapsed < UPDATE_THROTTLE then return end
    elapsed = 0
    
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    
    -- Grounded time tracking
    local gliding, canGlideNow, _ = GetGlidingInfo()
    if not gliding and canGlideNow then
        groundedTime = groundedTime + UPDATE_THROTTLE
    else
        groundedTime = 0
    end
    
    -- Smooth Vigor
    if currentBarValue ~= targetBarValue then
        local diff = targetBarValue - currentBarValue
        if math.abs(diff) < 0.005 then
            currentBarValue = targetBarValue
        else
            currentBarValue = currentBarValue + diff * LERP_SPEED * UPDATE_THROTTLE
        end
        vigorBar:SetValue(currentBarValue)
    end

    -- Smooth Second Wind
    if secondWindMiniBar and secondWindMiniBar:IsShown() then
        if swCurrentValue ~= swTargetValue then
            local diff = swTargetValue - swCurrentValue
            if math.abs(diff) < 0.005 then
                swCurrentValue = swTargetValue
            else
                swCurrentValue = swCurrentValue + diff * LERP_SPEED * UPDATE_THROTTLE
            end
            if swMaxCharges and swMaxCharges > 0 then
                secondWindMiniBar:SetValue(swCurrentValue * swMaxCharges)
            end
        end
    end
    
    -- Fade Logic
    if fadeStart > 0 then
        local now = GetTime()
        local elapsedTime = now - fadeStart
        local fadeDuration = settings.fadeDuration or 0.3
        local progress = math.min(elapsedTime / fadeDuration, 1)
        
        local alpha = fadeStartAlpha + (fadeTargetAlpha - fadeStartAlpha) * progress
        skyridingFrame:SetAlpha(alpha)
        
        if abilityIcon then
            abilityIcon:SetAlpha(alpha)
            if abilityIconCooldown then abilityIconCooldown:SetAlpha(alpha) end
        end
        
        if progress >= 1 then
            fadeStart = 0
            if fadeTargetAlpha < 0.01 then
                skyridingFrame:Hide()
            end
        end
    end
    
    UpdateVigorBar()
    UpdateRechargeAnimation()
    UpdateSecondWind()
    UpdateSecondWindRecharge()
    UpdateSpeed()
    UpdateAbilityIcon()
    UpdateVisibility()
end

---------------------------------------------------------------------------
-- ApplySettings
---------------------------------------------------------------------------
local function ApplySettings()
    cachedSettings = nil
    local settings = GetSettings()
    if not skyridingFrame then ns.CreateSkyridingFrame() end
    if not settings then 
        if skyridingFrame then skyridingFrame:Hide() end 
        return 
    end
    
    local width = settings.width or 250
    local height = settings.vigorHeight or 12
    local offsetX = settings.offsetX or 0
    local offsetY = settings.offsetY or -150
    local locked = (settings.locked ~= false)
    
    skyridingFrame:SetSize(width, height)
    skyridingFrame:ClearAllPoints()
    skyridingFrame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    skyridingFrame:EnableMouse(not locked)
    
    -- Texture
    local textureName = settings.barTexture or "Solid"
    local texturePath = LSM:Fetch("statusbar", textureName) or "Interface\\Buttons\\WHITE8x8"
    vigorBar:SetStatusBarTexture(texturePath)
    if secondWindMiniBar then secondWindMiniBar:SetStatusBarTexture(texturePath) end
    
    -- Colors
    local barColor = settings.barColor or {0.2, 0.8, 1.0, 1}
    if settings.useThemeColorVigor then
        local r, g, b, a = ns.GetAccentColor()
        barColor = {r, g, b, a}
    end
    vigorBar:SetStatusBarColor(unpack(barColor))
    
    local bgColor = settings.backgroundColor or {0.1, 0.1, 0.1, 0.8}
    vigorBackground:SetColorTexture(unpack(bgColor))
    
    if swBackground then
        local swBg = settings.secondWindBackgroundColor or bgColor
        swBackground:SetColorTexture(unpack(swBg))
    end
    
    rechargeOverlay:SetHeight(height)
    
    -- Fonts
    local vSize = settings.vigorFontSize or 11
    local sSize = settings.speedFontSize or 11
    local font = GetFontPath()
    vigorText:SetFont(font, vSize, "OUTLINE")
    speedText:SetFont(font, sSize, "OUTLINE")
    
    if abilityIconCooldown then ApplyCooldownFont(abilityIconCooldown, vSize) end
    
    local _, max = GetVigorInfo()
    UpdateSegmentMarkers(max)
    
    UpdateVigorBar()
    UpdateRechargeAnimation()
    UpdateSecondWind()
    UpdateSpeed()
    UpdateAbilityIcon()
    UpdateVisibility()
end

-- Export for settings menu
ns.RefreshSkyriding = ApplySettings

---------------------------------------------------------------------------
-- Frame Creation
---------------------------------------------------------------------------
function ns.CreateSkyridingFrame()
    if skyridingFrame then return end
    
    local settings = GetSettings()
    local width = settings.width or 250
    local height = settings.vigorHeight or 12
    
    skyridingFrame = CreateFrame("Frame", "GravityUI_Skyriding", UIParent)
    skyridingFrame:SetSize(width, height)
    skyridingFrame:SetPoint("CENTER", UIParent, "CENTER", settings.offsetX, settings.offsetY)
    skyridingFrame:SetFrameStrata("MEDIUM")
    skyridingFrame:SetClampedToScreen(true)
    
    -- Shadow
    shadowTexture = skyridingFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
    shadowTexture:SetColorTexture(0,0,0,0) -- Placeholder
    shadowTexture:SetAllPoints()
    
    -- Background
    vigorBackground = skyridingFrame:CreateTexture(nil, "BACKGROUND")
    vigorBackground:SetAllPoints()
    
    -- Vigor Bar
    vigorBar = CreateFrame("StatusBar", nil, skyridingFrame)
    vigorBar:SetAllPoints()
    vigorBar:SetMinMaxValues(0, 1)
    vigorBar:SetValue(0)
    
    rechargeOverlay = vigorBar:CreateTexture(nil, "OVERLAY")
    rechargeOverlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    rechargeOverlay:Hide()
    
    flashTexture = vigorBar:CreateTexture(nil, "OVERLAY", nil, 7)
    flashTexture:SetTexture("Interface\\Buttons\\WHITE8x8")
    flashTexture:SetBlendMode("ADD")
    flashTexture:Hide()
    
    flashAnim = flashTexture:CreateAnimationGroup()
    local f1 = flashAnim:CreateAnimation("Alpha")
    f1:SetFromAlpha(0); f1:SetToAlpha(0.5); f1:SetDuration(0.08); f1:SetOrder(1)
    local f2 = flashAnim:CreateAnimation("Alpha")
    f2:SetFromAlpha(0.5); f2:SetToAlpha(0); f2:SetDuration(0.25); f2:SetOrder(2)
    flashAnim:SetScript("OnPlay", function() flashTexture:Show() end)
    flashAnim:SetScript("OnFinished", function() flashTexture:Hide() end)
    
    skyridingFrame.border = CreateFrame("Frame", nil, skyridingFrame, "BackdropTemplate")
    skyridingFrame.border:SetPoint("TOPLEFT", -1, 1)
    skyridingFrame.border:SetPoint("BOTTOMRIGHT", 1, -1)
    skyridingFrame.border:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    skyridingFrame.border:SetBackdropBorderColor(0,0,0,1)
    
    vigorText = vigorBar:CreateFontString(nil, "OVERLAY")
    if ns.GetFont then
        local font, _ = ns.GetFont()
        vigorText:SetFont(font or STANDARD_TEXT_FONT, 11, "OUTLINE")
    else
        vigorText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    end
    vigorText:SetPoint("LEFT", 4, 0)
    
    speedText = vigorBar:CreateFontString(nil, "OVERLAY")
    if ns.GetFont then
        local font, _ = ns.GetFont()
        speedText:SetFont(font or STANDARD_TEXT_FONT, 11, "OUTLINE")
    else
        speedText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    end
    speedText:SetPoint("RIGHT", -4, 0)
    
    secondWindText = skyridingFrame:CreateFontString(nil, "OVERLAY")
    if ns.GetFont then
        local font, _ = ns.GetFont()
        secondWindText:SetFont(font or STANDARD_TEXT_FONT, 10, "OUTLINE")
    else
        secondWindText:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    end
    secondWindText:SetPoint("TOP", skyridingFrame, "BOTTOM", 0, -2)
    
    for i=1,10 do
        local m = vigorBar:CreateTexture(nil, "ARTWORK", nil, 3)
        m:SetTexture("Interface\\Buttons\\WHITE8x8")
        segmentMarkers[i] = m
    end
    
    for i=1,5 do
        local pip = skyridingFrame:CreateTexture(nil, "OVERLAY")
        pip:SetTexture(DOT_TEXTURE)
        local glow = skyridingFrame:CreateTexture(nil, "ARTWORK", nil, -1)
        glow:SetTexture(DOT_TEXTURE)
        glow:SetBlendMode("ADD")
        pip.glow = glow
        secondWindPips[i] = pip
    end
    
    secondWindMiniBar = CreateFrame("StatusBar", nil, skyridingFrame)
    swBackground = secondWindMiniBar:CreateTexture(nil, "BACKGROUND")
    swBackground:SetAllPoints()
    
    swBorder = CreateFrame("Frame", nil, secondWindMiniBar, "BackdropTemplate")
    swBorder:SetPoint("TOPLEFT", -1, 1); swBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    swBorder:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    swBorder:SetBackdropBorderColor(0,0,0,1)
    
    swRechargeOverlay = secondWindMiniBar:CreateTexture(nil, "OVERLAY")
    
    for i=1,5 do
        swSegmentMarkers[i] = secondWindMiniBar:CreateTexture(nil, "ARTWORK", nil, 3)
    end
    
    abilityIcon = CreateFrame("Frame", nil, skyridingFrame)
    abilityIcon.texture = abilityIcon:CreateTexture(nil, "ARTWORK")
    abilityIcon.texture:SetAllPoints()
    abilityIcon.texture:SetTexture(C_Spell.GetSpellTexture(WHIRLING_SURGE_SPELL_ID))
    abilityIcon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    abilityIcon.border = CreateFrame("Frame", nil, abilityIcon, "BackdropTemplate")
    abilityIcon.border:SetPoint("TOPLEFT", -1, 1)
    abilityIcon.border:SetPoint("BOTTOMRIGHT", 1, -1)
    abilityIcon.border:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    abilityIcon.border:SetBackdropBorderColor(0,0,0,1)
    
    abilityIconCooldown = CreateFrame("Cooldown", nil, abilityIcon, "CooldownFrameTemplate")
    abilityIconCooldown:SetAllPoints()
    abilityIconCooldown:SetDrawEdge(true)
    
    skyridingFrame:SetMovable(true)
    skyridingFrame:RegisterForDrag("LeftButton")
    skyridingFrame:SetScript("OnDragStart", function(self)
        if ns.db.profile.skyriding.locked == false then self:StartMoving() end
    end)
    skyridingFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local settings = GetSettings()
        local cx, cy = self:GetCenter()
        local ux, uy = UIParent:GetCenter()
        local s = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
        settings.offsetX = (cx - ux) * s
        settings.offsetY = (cy - uy) * s
    end)
    
    skyridingFrame:Hide()
end

-- Initialization
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_CAN_GLIDE_CHANGED")
eventFrame:RegisterEvent("PLAYER_IS_GLIDING_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            ns.CreateSkyridingFrame()
            ApplySettings()
            if skyridingFrame then skyridingFrame:SetScript("OnUpdate", OnUpdate) end
        end)
    elseif event == "PLAYER_CAN_GLIDE_CHANGED" or event == "PLAYER_IS_GLIDING_CHANGED" then
        if event == "PLAYER_CAN_GLIDE_CHANGED" then canGlide = arg1
        else isGliding = arg1; groundedTime = 0 end
        UpdateVisibility()
    elseif event == "PLAYER_REGEN_DISABLED" then inCombat = true; UpdateVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then inCombat = false; UpdateVisibility()
    else
        -- Updates
        if skyridingFrame and skyridingFrame:IsShown() then
            if event == "SPELL_UPDATE_COOLDOWN" then UpdateAbilityIcon()
            else UpdateVigorBar(); UpdateSecondWind() end
        end
    end
end)
