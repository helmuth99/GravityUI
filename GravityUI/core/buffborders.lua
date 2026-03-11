-- GravityUI - Buff Borders Module
-- Adds configurable borders and styling to Blizzard's default Buff/Debuff frames
local ADDON_NAME, ns = ...

-- Helper: Get Settings
local function GetSettings()
    local db = ns.GetDB()
    if not db or not db.uiimprovements or not db.uiimprovements.buffBorders then return nil end
    return db.uiimprovements.buffBorders
end

-- Border Colors (Internal Defaults)
local BORDER_COLOR_BUFF = {0, 0, 0, 1}
local BORDER_COLOR_DEBUFF = {0.5, 0, 0, 1}

-- Cache for bordered buttons
local borderedButtons = {}

-----------------------------------------------------------
-- 1. TEXT STYLING ENGINE
-----------------------------------------------------------

local function ReapplyAuraTextSettings(text, isCount)
    if not text or text._gui_Applying then return end
    local settings = GetSettings()
    if not settings or not settings.enableStyling then return end

    -- Data Retrieval
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local fontPath = ns.FONT_PATH
    if LSM and settings.font then
        local fetched = LSM:Fetch("font", settings.font)
        if fetched then fontPath = fetched end
    end
    
    local fontSize = isCount and (settings.countFontSize or 12) or (settings.fontSize or 12)
    local fontOutline = settings.fontOutline or "OUTLINE"
    local color = isCount and (settings.countColor or {1, 1, 1, 1}) or (settings.fontColor or {1, 1, 1, 1})

    text._gui_Applying = true
    
    -- Apply Font & Color
    text:SetFont(fontPath, fontSize, fontOutline)
    text:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    if text.SetVertexColor then text:SetVertexColor(color[1], color[2], color[3], color[4] or 1) end
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)
    
    -- Position Management (Secret Number fix)
    if not text._gui_OriginalPoint then
        local p, rel, rp, x, y = text:GetPoint()
        -- Scrub tainted/secret values: if it's not a normal number, it's a "secret" one.
        local safeX = type(x) == "number" and x or 0
        local safeY = type(y) == "number" and y or 0
        -- Also scrub points just in case they are tainted (less common but possible)
        local safeP = tostring(p or (isCount and "BOTTOMRIGHT" or "BOTTOM"))
        local safeRP = tostring(rp or (isCount and "BOTTOMRIGHT" or "BOTTOM"))
        
        text._gui_OriginalPoint = { safeP, rel, safeRP, safeX, safeY }
    end

    if text._gui_OriginalPoint then
        local p = text._gui_OriginalPoint
        text:ClearAllPoints()
        text:SetPoint(p[1], p[2], p[3], p[4], p[5]) -- Offsets removed as requested
    end
    
    text:SetDrawLayer("OVERLAY", 7)
    text._gui_Applying = nil
end

-----------------------------------------------------------
-- 2. BUTTON MODERNIZATION
-----------------------------------------------------------

local function StyleAuraButton(button)
    if not button then return end
    local settings = GetSettings()
    if not settings or not settings.enableStyling then return end

    local icon = button.Icon or button.icon
    if not icon then return end

    -- icon layering
    if icon.SetDrawLayer then
        icon:SetDrawLayer("BACKGROUND", -8)
    end

    -- Blink Suppression
    if settings.noBlink then
        if button.Flash then 
            button.Flash:SetAlpha(0) 
            button.Flash:Hide()
            if not button._gui_FlashHooked then
                button._gui_FlashHooked = true
                hooksecurefunc(button.Flash, "Show", function(self) self:Hide() end)
                hooksecurefunc(button.Flash, "SetAlpha", function(self, a) if a > 0 then self:SetAlpha(0) end end)
            end
        end
        if button.FlashAnimationGroup then 
            button.FlashAnimationGroup:Stop()
            if not button._gui_AnimHooked then
                button._gui_AnimHooked = true
                hooksecurefunc(button.FlashAnimationGroup, "Play", function(self) self:Stop() end)
            end
        end
        
        -- Alpha Lock (Expiring Fade)
        if not button._gui_AlphaHooked then
            button._gui_AlphaHooked = true
            hooksecurefunc(button, "SetAlpha", function(self, alpha)
                if self._gui_SettingAlpha then return end
                local s = GetSettings()
                if s and s.enableStyling and s.noBlink and alpha < 1.0 then
                    self._gui_SettingAlpha = true
                    self:SetAlpha(1.0)
                    self._gui_SettingAlpha = nil
                end
            end)
        end
        if button:GetAlpha() < 1.0 then 
            button._gui_SettingAlpha = true
            button:SetAlpha(1.0)
            button._gui_SettingAlpha = nil
        end
    end

    -- Duration Text Hook
    local duration = button.Duration or button.duration
    if duration and duration.SetFont then
        if not duration._gui_Hooked then
            duration._gui_Hooked = true
            hooksecurefunc(duration, "SetFont", function(self) ReapplyAuraTextSettings(self, false) end)
            hooksecurefunc(duration, "SetPoint", function(self) ReapplyAuraTextSettings(self, false) end)
            hooksecurefunc(duration, "SetTextColor", function(self) ReapplyAuraTextSettings(self, false) end)
            hooksecurefunc(duration, "SetVertexColor", function(self) ReapplyAuraTextSettings(self, false) end)
        end
        ReapplyAuraTextSettings(duration, false)
    end
    
    -- Count Text Hook
    local count = button.Count or button.count
    if count and count.SetFont then
        if not count._gui_Hooked then
            count._gui_Hooked = true
            hooksecurefunc(count, "SetFont", function(self) ReapplyAuraTextSettings(self, true) end)
            hooksecurefunc(count, "SetPoint", function(self) ReapplyAuraTextSettings(self, true) end)
            hooksecurefunc(count, "SetTextColor", function(self) ReapplyAuraTextSettings(self, true) end)
            hooksecurefunc(count, "SetVertexColor", function(self) ReapplyAuraTextSettings(self, true) end)
        end
        ReapplyAuraTextSettings(count, true)
    end
end

-----------------------------------------------------------
-- 3. BORDER ENGINE
-----------------------------------------------------------

local function AddBorderToButton(button, isBuff)
    if not button or borderedButtons[button] then return end
    local settings = GetSettings()
    if not settings then return end
    
    button._gui_IsBuff = isBuff
    if not isBuff and not settings.enableDebuffs then return end
    if not isBuff and not settings.enableDebuffs then 
        borderedButtons[button] = true -- Mark as processed even if debuffs are disabled
        return 
    end
    
    local icon = button.Icon or button.icon
    if not icon or not button.CreateTexture then 
        borderedButtons[button] = true -- Mark as processed if no icon or cannot create texture
        return 
    end

    local borderSize = settings.borderSize or 2
    local borderColor = {0, 0, 0, 1} -- Default Black
    local isShown = borderSize > 0
    
    if not button.GravityBorderTop then
        button.GravityBorderTop = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderBottom = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderLeft = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderRight = button:CreateTexture(nil, "OVERLAY", nil, 7)

        button.GravityBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.GravityBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        
        button.GravityBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        button.GravityBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        
        button.GravityBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.GravityBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        
        button.GravityBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        button.GravityBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    end
    
    if isShown then
        button.GravityBorderTop:SetColorTexture(unpack(borderColor))
        button.GravityBorderBottom:SetColorTexture(unpack(borderColor))
        button.GravityBorderLeft:SetColorTexture(unpack(borderColor))
        button.GravityBorderRight:SetColorTexture(unpack(borderColor))
        
        button.GravityBorderTop:SetHeight(borderSize)
        button.GravityBorderBottom:SetHeight(borderSize)
        button.GravityBorderLeft:SetWidth(borderSize)
        button.GravityBorderRight:SetWidth(borderSize)
        
        button.GravityBorderTop:Show()
        button.GravityBorderBottom:Show()
        button.GravityBorderLeft:Show()
        button.GravityBorderRight:Show()
    else
        button.GravityBorderTop:Hide()
        button.GravityBorderBottom:Hide()
        button.GravityBorderLeft:Hide()
        button.GravityBorderRight:Hide()
    end
    
    borderedButtons[button] = true
end

-----------------------------------------------------------
-- 4. CONTAINER & VISIBILITY
-----------------------------------------------------------

local function ProcessAuraContainer(container, isBuff)
    if not container then return end
    for i = 1, select("#", container:GetChildren()) do
        local frame = select(i, container:GetChildren())
        if frame and (frame.Icon or frame.icon) then
            AddBorderToButton(frame, isBuff)
            StyleAuraButton(frame)
        end
    end
end

local function ApplyFrameHiding()
    local settings = GetSettings()
    if not settings then return end

    if BuffFrame then
        BuffFrame:SetShown(not settings.hideBuffFrame)
        if not BuffFrame._gui_HidingHooked then
            BuffFrame._gui_HidingHooked = true
            hooksecurefunc(BuffFrame, "Show", function(self) if GetSettings().hideBuffFrame then self:Hide() end end)
        end
    end

    if DebuffFrame then
        DebuffFrame:SetShown(not settings.hideDebuffFrame)
        if not DebuffFrame._gui_HidingHooked then
            DebuffFrame._gui_HidingHooked = true
            hooksecurefunc(DebuffFrame, "Show", function(self) if GetSettings().hideDebuffFrame then self:Hide() end end)
        end
    end
end

local function ApplyBuffBorders()
    local settings = GetSettings()
    if not settings then return end

    ApplyFrameHiding()
    
    if BuffFrame and BuffFrame.AuraContainer then
        ProcessAuraContainer(BuffFrame.AuraContainer, true)
    end
    
    if DebuffFrame and DebuffFrame.AuraContainer then
        ProcessAuraContainer(DebuffFrame.AuraContainer, false)
    end
    
    if TemporaryEnchantFrame then
        for i = 1, select("#", TemporaryEnchantFrame:GetChildren()) do
            local frame = select(i, TemporaryEnchantFrame:GetChildren())
            if frame and (frame.Icon or frame.icon) then
                frame._gui_IsTemp = true
                AddBorderToButton(frame, true)
                StyleAuraButton(frame)
            end
        end
    end
end

-----------------------------------------------------------
-- 5. INITIALIZATION & HOOKS
-----------------------------------------------------------

local buffBorderPending = false
local function ScheduleBuffBorders()
    if buffBorderPending then return end
    buffBorderPending = true
    C_Timer.After(0.1, function()
        buffBorderPending = false
        ApplyBuffBorders()
    end)
end

local function HookAuraUpdates()
    if BuffFrame and BuffFrame.Update then hooksecurefunc(BuffFrame, "Update", ScheduleBuffBorders) end
    if BuffFrame and BuffFrame.AuraContainer and BuffFrame.AuraContainer.Update then hooksecurefunc(BuffFrame.AuraContainer, "Update", ScheduleBuffBorders) end
    if DebuffFrame and DebuffFrame.Update then hooksecurefunc(DebuffFrame, "Update", ScheduleBuffBorders) end
    if DebuffFrame and DebuffFrame.AuraContainer and DebuffFrame.AuraContainer.Update then hooksecurefunc(DebuffFrame.AuraContainer, "Update", ScheduleBuffBorders) end
    
    -- Hook Aura Button Updates
    if type(AuraButton_Update) == "function" then
        hooksecurefunc("AuraButton_Update", function(button) StyleAuraButton(button) end)
    end
    if type(AuraButton_UpdateDuration) == "function" then
        hooksecurefunc("AuraButton_UpdateDuration", function(button) StyleAuraButton(button) end)
    end
end

-- Export
ns.BuffBorders = {
    Apply = ApplyBuffBorders,
    Refresh = function()
        borderedButtons = {} -- Clear cache
        ApplyBuffBorders()
    end
}

-- Init
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "PLAYER_ENTERING_WORLD" then
        HookAuraUpdates()
        C_Timer.After(1, ApplyBuffBorders)
    elseif event == "UNIT_AURA" and arg == "player" then
        ScheduleBuffBorders()
    end
end)
