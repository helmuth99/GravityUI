-- GravityUI - Buff Borders Module
-- Adds configurable borders to Blizzard's default Buff/Debuff frames
local ADDON_NAME, ns = ...

-- Helper: Get Settings
local function GetSettings()
    local db = ns.GetDB()
    if not db then return nil end
    if not db.uiimprovements then db.uiimprovements = {} end
    if not db.uiimprovements.buffBorders then
        db.uiimprovements.buffBorders = {
            enableBuffs = true,
            enableDebuffs = true,
            hideBuffFrame = false,
            hideDebuffFrame = false,
            borderSize = 2,
            fontSize = 12,
        }
    end
    return db.uiimprovements.buffBorders
end

-- Border Colors
local BORDER_COLOR_BUFF = {0, 0, 0, 1}        -- Black for Buffs
local BORDER_COLOR_DEBUFF = {0.5, 0, 0, 1}    -- Dark Red for Debuffs

-- Track bordered buttons
local borderedButtons = {}

-- Add border to a single button
local function AddBorderToButton(button, isBuff)
    if not button or borderedButtons[button] then return end
    
    local settings = GetSettings()
    if not settings then return end
    
    if isBuff and not settings.enableBuffs then return end
    if not isBuff and not settings.enableDebuffs then return end
    
    local icon = button.Icon or button.icon
    if not icon then return end

    if not button.CreateTexture or type(button.CreateTexture) ~= "function" then return end
    
    local borderSize = settings.borderSize or 2
    local borderColor = isBuff and BORDER_COLOR_BUFF or BORDER_COLOR_DEBUFF
    
    if not button.GravityBorderTop then
        -- Top
        button.GravityBorderTop = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.GravityBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        
        -- Bottom
        button.GravityBorderBottom = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        button.GravityBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        
        -- Left
        button.GravityBorderLeft = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.GravityBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        
        -- Right
        button.GravityBorderRight = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        button.GravityBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    end
    
    -- Update Color
    button.GravityBorderTop:SetColorTexture(unpack(borderColor))
    button.GravityBorderBottom:SetColorTexture(unpack(borderColor))
    button.GravityBorderLeft:SetColorTexture(unpack(borderColor))
    button.GravityBorderRight:SetColorTexture(unpack(borderColor))
    
    -- Update Size
    button.GravityBorderTop:SetHeight(borderSize)
    button.GravityBorderBottom:SetHeight(borderSize)
    button.GravityBorderLeft:SetWidth(borderSize)
    button.GravityBorderRight:SetWidth(borderSize)
    
    button.GravityBorderTop:Show()
    button.GravityBorderBottom:Show()
    button.GravityBorderLeft:Show()
    button.GravityBorderRight:Show()
    
    borderedButtons[button] = true
end

-- Apply Font Settings
local function ApplyFontSettings(button)
    if not button then return end
    local settings = GetSettings()
    if not settings then return end

    -- Use standard font available in WoW or fallback
    local font = "Fonts\\FRIZQT__.TTF" 
    local duration = button.Duration or button.duration
    
    if duration and duration.SetFont then
        local fontSize = settings.fontSize or 12
        duration:SetFont(font, fontSize, "OUTLINE")
    end
end

-- Process Container
local function ProcessAuraContainer(container, isBuff)
    if not container then return end
    for i = 1, select("#", container:GetChildren()) do
        local frame = select(i, container:GetChildren())
        if frame.Icon or frame.icon then
            AddBorderToButton(frame, isBuff)
            ApplyFontSettings(frame)
        end
    end
end

-- Apply Frame Hiding
local function ApplyFrameHiding()
    local settings = GetSettings()
    if not settings then return end

    if BuffFrame then
        if settings.hideBuffFrame then
            BuffFrame:Hide()
        else
            BuffFrame:Show()
        end
        
        if not BuffFrame._gui_ShowHooked then
            BuffFrame._gui_ShowHooked = true
            hooksecurefunc(BuffFrame, "Show", function(self)
                local s = GetSettings()
                if s and s.hideBuffFrame then self:Hide() end
            end)
        end
    end

    if DebuffFrame then
        if settings.hideDebuffFrame then
            DebuffFrame:Hide()
        else
            DebuffFrame:Show()
        end

        if not DebuffFrame._gui_ShowHooked then
            DebuffFrame._gui_ShowHooked = true
            hooksecurefunc(DebuffFrame, "Show", function(self)
                local s = GetSettings()
                if s and s.hideDebuffFrame then self:Hide() end
            end)
        end
    end
end

-- Main Apply Function
local function ApplyBuffBorders()
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
            AddBorderToButton(frame, true)
            ApplyFontSettings(frame)
        end
    end
end

-- Debounce
local buffBorderPending = false
local function ScheduleBuffBorders()
    if buffBorderPending then return end
    buffBorderPending = true
    C_Timer.After(0.15, function()
        buffBorderPending = false
        ApplyBuffBorders()
    end)
end

-- Hook Updates
local function HookAuraUpdates()
    if BuffFrame and BuffFrame.Update then hooksecurefunc(BuffFrame, "Update", ScheduleBuffBorders) end
    if BuffFrame and BuffFrame.AuraContainer and BuffFrame.AuraContainer.Update then hooksecurefunc(BuffFrame.AuraContainer, "Update", ScheduleBuffBorders) end
    if DebuffFrame and DebuffFrame.Update then hooksecurefunc(DebuffFrame, "Update", ScheduleBuffBorders) end
    if DebuffFrame and DebuffFrame.AuraContainer and DebuffFrame.AuraContainer.Update then hooksecurefunc(DebuffFrame.AuraContainer, "Update", ScheduleBuffBorders) end
    if type(AuraButton_Update) == "function" then hooksecurefunc("AuraButton_Update", ScheduleBuffBorders) end
end

-- Export
ns.BuffBorders = {
    Apply = ApplyBuffBorders,
    Refresh = function()
        borderedButtons = {} -- Clear cache to force redraw
        ApplyBuffBorders()
    end
}

-- Init
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, HookAuraUpdates)
        ScheduleBuffBorders()
    elseif event == "UNIT_AURA" and arg == "player" then
        ScheduleBuffBorders()
    end
end)
