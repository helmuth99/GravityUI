-- GravityUI - World Marks Module
-- Quick bar for raid markers and world markers
local ADDON_NAME, ns = ...

local WorldMarks = {}
ns.WorldMarks = WorldMarks

local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.marks then
        return db.uiimprovements.marks
    end
    return nil
end

---------------------------------------------------------------------------
-- REFRESH LOGIC
---------------------------------------------------------------------------
function WorldMarks.Refresh()
    local frame = WorldMarks.frame
    if not frame then return end
    
    if InCombatLockdown() then return end
    
    local settings = GetSettings()
    if not settings then return end

    local padding = settings.spacing -- Assuming padding is equal to spacing for now
    
    -- Calculate Width/Height
    -- Width = (9 buttons * size) + (8 spaces) + (2 padding)
    local width = (9 * settings.size) + (8 * settings.spacing) + (padding * 2)
    
    -- Height depends on showTimerBar
    -- Base: (size) + (2 padding)
    -- If timer bar: (size * 2) + (spacing) + (2 padding)
    local height = settings.size + (padding * 2)
    local showTimerBar = true
    if settings.showTimerBar ~= nil then showTimerBar = settings.showTimerBar end

    -- Height depends on showTimerBar
    -- Base: (size) + (2 padding)
    -- If timer bar: (size * 2) + (spacing) + (2 padding)
    local height = settings.size + (padding * 2)
    if showTimerBar then
         height = (settings.size * 2) + settings.spacing + (padding * 2)
    end
    
    frame:SetSize(width, height)
    
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.offsetX or 0, settings.offsetY or 100)
    
    if settings.enabled then 
        frame:Show() 
    else 
        frame:Hide() 
    end
    
    if settings.mouseover then 
        frame:SetAlpha(0) 
    else 
        frame:SetAlpha(1) 
    end

    -- Update Buttons
    for i = 1, 11 do
        local btn = frame.buttons[i]
        if btn then
            -- Hide/Show Row 2 buttons based on settings.showTimerBar
            if i >= 10 then
                if showTimerBar then
                    btn:Show()
                else
                    btn:Hide()
                end
            end

            if i <= 9 then
                -- Row 1: Markers (Square)
                btn:SetSize(settings.size, settings.size)
                btn:ClearAllPoints()
                local xOffset = padding + ((i-1) * (settings.size + settings.spacing))
                btn:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, -padding)
                
                if btn.text then btn.text:Hide() end
                if btn.icon then btn.icon:Show() end
            else
                -- Row 2: Tools (Wide Buttons)
                local totalRow1Width = (9 * settings.size) + (8 * settings.spacing)
                local btnWidth = (totalRow1Width - settings.spacing) / 2
                
                btn:SetSize(btnWidth, settings.size)
                btn:ClearAllPoints()
                
                -- yOffset = padding (top) + row1 height (size) + spacing
                local yOffset = -(padding + settings.size + settings.spacing)
                
                if i == 10 then
                    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, yOffset)
                elseif i == 11 then
                    btn:SetPoint("LEFT", frame.buttons[10], "RIGHT", settings.spacing, 0)
                end
                
                if btn.text then btn.text:Show() end
                if btn.icon then btn.icon:Hide() end
                
                -- Ensure backdrop for visibility
                if not btn:GetBackdrop() then
                    Mixin(btn, BackdropTemplateMixin)
                    btn:SetBackdrop({
                         bgFile = "Interface\\Buttons\\WHITE8x8",
                         edgeFile = "Interface\\Buttons\\WHITE8x8",
                         edgeSize = 1,
                    })
                end
                btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
                btn:SetBackdropBorderColor(0, 0, 0, 1)
            end
        end
    end
    
    -- Update Border
    if settings.hideBorder then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = nil,
            edgeSize = 0,
        })
    else
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        
        local r, g, b, a
        if settings.useThemeColorBorder then
            r, g, b, a = ns.GetAccentColor()
        else
            r, g, b, a = unpack(settings.borderColor or {0, 0, 0, 1})
        end
        frame:SetBackdropBorderColor(r, g, b, a or 1)
    end
    
    frame:SetBackdropColor(0, 0, 0, 0.6)
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local function CreateMarksBar()
    if WorldMarks.frame then return end
    
    local settings = GetSettings()
    if not settings then return end

    local frame = CreateFrame("Frame", "GravityUI_MarksBar", UIParent, "BackdropTemplate")
    frame.buttons = {}
    
    frame:EnableMouse(true)
    frame:SetFrameStrata("MEDIUM")
    
    -- Initial backdrop will be set by Refresh()
    
    local function UpdateAlpha(alpha)
        local s = GetSettings()
        if s and s.mouseover then 
            frame:SetAlpha(alpha) 
        else 
            frame:SetAlpha(1) 
        end
    end

    frame:SetScript("OnEnter", function() UpdateAlpha(1) end)
    frame:SetScript("OnLeave", function() if not frame:IsMouseOver() then UpdateAlpha(0) end end)

    -- Button Creation
    for i = 1, 11 do
        local btn = CreateFrame("Button", "GravityUIMarkerBtn"..i, frame, "SecureActionButtonTemplate, BackdropTemplate")
        btn:RegisterForClicks("AnyUp", "AnyDown") 
        btn:SetAttribute("type", "macro") 

        -- Icon Texture (std name 'icon' for easier handling)
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetPoint("TOPLEFT", 2, -2)
        btn.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        
        -- Text Label (for wide buttons)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER", 0, 0)
        btn.text:Hide()
        
        if i < 9 then
            btn.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
            SetRaidTargetIconTexture(btn.icon, i)
            local wmMap = { [1]=5, [2]=6, [3]=3, [4]=2, [5]=7, [6]=1, [7]=4, [8]=8 }
            local wmID = wmMap[i] or i
            btn:SetAttribute("macrotext", "/tm [nomod:shift] " .. i .. "\n/wm [mod:shift] " .. wmID)
        elseif i == 9 then
            -- Clear Button
            btn.icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            btn:SetAttribute("macrotext", "/tm [target=player,nomod:shift] 0\n/tm [nomod:shift] 0\n/clearraidmarkers [nomod:shift]\n/cwm [mod:shift] all")
        elseif i == 10 then
            -- Ready Check
            btn:SetAttribute("macrotext", "/readycheck")
            btn.text:SetText("Ready Check")
            btn.text:Show()
            btn.icon:Hide()
        elseif i == 11 then
            -- Pull Timer
            -- Default check
            local settings = GetSettings()
            if not settings.pullTimer then settings.pullTimer = 10 end
            
            local function UpdatePullButton(val)
                if InCombatLockdown() then return end
                btn:SetAttribute("type1", "macro")
                btn:SetAttribute("macrotext1", "/pull " .. val)
                btn.text:SetText("Pull " .. val)
            end
            
            UpdatePullButton(settings.pullTimer)
            
            btn.text:Show()
            btn.icon:Hide()
            
            -- Tooltip + Menu
            btn:SetScript("OnEnter", function(self) 
                if frame:GetAlpha() > 0 then
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine("Left-Click: Start Pull")
                    GameTooltip:AddLine("Right-Click: Set Duration", 1, 1, 1)
                    GameTooltip:Show()
                end
                UpdateAlpha(1)
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() if not frame:IsMouseOver() then UpdateAlpha(0) end end)
            
            btn:SetScript("OnMouseUp", function(self, button)
                if button == "RightButton" and not InCombatLockdown() then
                    MenuUtil.CreateContextMenu(self, function(_, root)
                        root:CreateTitle("Pull Timer Duration")
                        local options = {5, 8, 10, 15}
                        for _, v in ipairs(options) do
                            root:CreateButton(v .. " seconds", function()
                                settings.pullTimer = v
                                UpdatePullButton(v)
                            end)
                        end
                    end)
                end
            end)
        end
        
        -- Alpha hover only for icon buttons usually, but let's apply to all for consistency with bar
        btn:HookScript("OnEnter", function() UpdateAlpha(1) end)
        btn:HookScript("OnLeave", function() if not frame:IsMouseOver() then UpdateAlpha(0) end end)
        
        frame.buttons[i] = btn
    end

    WorldMarks.frame = frame
    WorldMarks.Refresh()
    
    -- Hide if initially needed (Refesh handles it but let's be sure)
    UpdateAlpha(0)
end

-- Export to ns for init
ns.RefreshWorldMarks = WorldMarks.Refresh

-- Auto-Init
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    CreateMarksBar()
end)

-- Hook into global color refresh
local originalRefreshColors = ns.RefreshAccentColors
ns.RefreshAccentColors = function()
    if originalRefreshColors then originalRefreshColors() end
    if WorldMarks.Refresh then WorldMarks.Refresh() end
end

-- Export for GUI
_G.GravityUI_RefreshWorldMarks = WorldMarks.Refresh
