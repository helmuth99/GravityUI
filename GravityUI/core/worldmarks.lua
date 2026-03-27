-- GravityUI - World Marks Module
-- Quick bar for raid markers and world markers
local ADDON_NAME, ns = ...

local WorldMarks = {}
ns.WorldMarks = WorldMarks

local function GetSettings()
    local db = ns.GetDB()
    return db and db.uiimprovements and db.uiimprovements.marks
end

local function GetAccentColor()
    if ns.GetAccentColor then return ns.GetAccentColor() end
    return 0, 0.5, 1, 1 -- Fallback Blue
end

---------------------------------------------------------------------------
-- REFRESH LOGIC
---------------------------------------------------------------------------
function WorldMarks.Refresh()
    local frame = WorldMarks.frame
    if not frame then return end
    
    local settings = GetSettings()
    if not settings then return end

    -- Visual Updates (Safe in Combat)
    if settings.enabled then frame:Show() else frame:Hide() end
    frame:SetAlpha(settings.mouseover and 0 or 1)
    
    local r, g, b, a = 0, 0, 0, 1
    if settings.useThemeColorBorder then
        r, g, b, a = GetAccentColor()
    elseif settings.borderColor then
        r, g, b, a = unpack(settings.borderColor)
    end
    
    if not frame.bg then
        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints()
    end
    frame.bg:SetColorTexture(0, 0, 0, 0.7)

    if not frame.border then
        frame.border = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        frame.border:SetPoint("TOPLEFT", -1, 1)
        frame.border:SetPoint("BOTTOMRIGHT", 1, -1)
    end
    
    if settings.hideBorder then
        frame.border:Hide()
    else
        frame.border:Show()
        frame.border:SetColorTexture(r, g, b, a or 1)
    end

    -- Secure Updates (Deferred if in combat)
    if InCombatLockdown() then
        if not WorldMarks.isQueued then
            WorldMarks.isQueued = true
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            f:SetScript("OnEvent", function(self)
                WorldMarks.Refresh()
                WorldMarks.isQueued = nil
                self:UnregisterAllEvents()
            end)
        end
        return
    end

    local padding = settings.spacing or 2 
    local size = settings.size or 32
    local spacing = settings.spacing or 2
    local width = (9 * size) + (8 * spacing) + (padding * 2)
    local showTimerBar = settings.showTimerBar ~= false
    local height = showTimerBar and ((size * 2) + spacing + (padding * 2)) or (size + (padding * 2))
    
    frame:SetSize(width, height)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.offsetX or 0, settings.offsetY or 100)

    for i = 1, 11 do
        local btn = frame.buttons[i]
        if btn then
            if i >= 10 then if showTimerBar then btn:Show() else btn:Hide() end end
            if i <= 9 then
                btn:SetSize(size, size)
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", frame, "TOPLEFT", padding + ((i-1)*(size+spacing)), -padding)
            else
                local btnWidth = ((9 * size) + (8 * spacing) - spacing) / 2
                btn:SetSize(btnWidth, size)
                btn:ClearAllPoints()
                local yOffset = -(padding + size + spacing)
                if i == 10 then btn:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, yOffset)
                else btn:SetPoint("LEFT", frame.buttons[10], "RIGHT", spacing, 0) end
            end
        end
    end
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local function CreateMarksBar()
    if WorldMarks.frame then return end
    local settings = GetSettings()
    if not settings then return end

    local frame = CreateFrame("Frame", "GravityUI_MarksBar", UIParent)
    frame.buttons = {}
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetUserPlaced(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    
    local function UpdateAlpha(a)
        local s = GetSettings()
        if s and s.mouseover then frame:SetAlpha(a) else frame:SetAlpha(1) end
    end

    frame:SetScript("OnEnter", function() UpdateAlpha(1) end)
    frame:SetScript("OnLeave", function() if not frame:IsMouseOver() then UpdateAlpha(0) end end)

    for i = 1, 11 do
        local btn = CreateFrame("Button", "GravityUIMarkerBtn"..i, frame, "SecureActionButtonTemplate, BackdropTemplate")
        btn:RegisterForClicks("AnyDown", "AnyUp") 
        btn:SetFrameLevel(110)
        btn:SetHighlightTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]], "ADD")
        
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetPoint("TOPLEFT", 2, -2); btn.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER", 0, 0); btn.text:Hide()
        
        if i < 9 then
            btn.icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
            SetRaidTargetIconTexture(btn.icon, i)
            
            local iconToTargetID = { 1, 2, 3, 4, 5, 6, 7, 8 }
            local iconToWorldID  = { 5, 6, 3, 2, 7, 1, 4, 8 }
            
            local targetID = iconToTargetID[i]
            local worldID = iconToWorldID[i]
            
            -- LEFT CLICK: Target Marker
            btn:SetAttribute("type1", "macro")
            btn:SetAttribute("macrotext1", "/tm " .. targetID)
            
            -- SHIFT+LEFT CLICK: World Marker
            btn:SetAttribute("shift-type1", "macro")
            btn:SetAttribute("shift-macrotext1", "/wm " .. worldID)

            -- RIGHT CLICK: World Marker (Convenience)
            btn:SetAttribute("type2", "macro")
            btn:SetAttribute("macrotext2", "/wm " .. worldID)

        elseif i == 9 then
            -- Clear Button
            btn.icon:SetTexture([[Interface\Buttons\UI-GroupLoot-Pass-Up]])
            -- Left (1): Clear Target
            btn:SetAttribute("type1", "macro")
            btn:SetAttribute("macrotext1", "/tm 0")
            -- Shift+Left (1): Clear All World Markers
            btn:SetAttribute("shift-type1", "macro")
            btn:SetAttribute("shift-macrotext1", "/cwm all")
            -- Right (2): Clear All World Markers
            btn:SetAttribute("type2", "macro")
            btn:SetAttribute("macrotext2", "/cwm all")

        elseif i == 10 then
            btn.text:SetText("Ready Check"); btn.text:Show(); btn.icon:Hide()
            btn:SetAttribute("type1", "macro"); btn:SetAttribute("macrotext1", "/readycheck")

        elseif i == 11 then
            local pSettings = settings
            if not pSettings.pullTimer then pSettings.pullTimer = 10 end
            local function UpdatePullButton(val)
                if InCombatLockdown() then return end
                btn:SetAttribute("type1", "macro"); btn:SetAttribute("macrotext1", "/pull " .. val)
                btn.text:SetText("Pull " .. val)
            end
            UpdatePullButton(pSettings.pullTimer)
            btn.text:Show(); btn.icon:Hide()

            btn:SetScript("OnEnter", function(self)
                if frame:GetAlpha() > 0 then
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine("Left: Mark | Shift+Left or Right: World Mark")
                    GameTooltip:Show()
                end
                UpdateAlpha(1)
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide(); if not frame:IsMouseOver() then UpdateAlpha(0) end end)

            btn:SetScript("OnMouseUp", function(self, button)
                if button == "RightButton" and not InCombatLockdown() then
                    MenuUtil.CreateContextMenu(self, function(_, root)
                        root:CreateTitle("Duration")
                        for _, v in ipairs({5, 8, 10, 15}) do
                            root:CreateButton(v .. "s", function() pSettings.pullTimer = v; UpdatePullButton(v) end)
                        end
                    end)
                end
            end)
        end
        
        btn:HookScript("OnEnter", function() UpdateAlpha(1) end)
        btn:HookScript("OnLeave", function() if not frame:IsMouseOver() then UpdateAlpha(0) end end)
        frame.buttons[i] = btn
    end

    WorldMarks.frame = frame
    WorldMarks.Refresh()
    UpdateAlpha(0)
    if WorldMarks.RegisterMover then WorldMarks:RegisterMover() end
end

---------------------------------------------------------------------------
-- MOVER/INIT
---------------------------------------------------------------------------
function WorldMarks:ToggleMover(forceState)
    if not self.mover then self:CreateMover() end
    local shouldShow = (forceState ~= nil) and forceState or not self.mover:IsShown()
    if self.mover then
        if shouldShow then
            self.mover:Show(); frame:Show(); frame:SetAlpha(1)
            if ns.Movers and ns.Movers.ApplyEditModeStyle then ns.Movers:ApplyEditModeStyle(self.mover, forceState == true) end
        else
            if ns.Movers and ns.Movers.ApplyEditModeStyle then ns.Movers:ApplyEditModeStyle(self.mover, false) end
            self.mover:Hide(); self.Refresh()
        end
    end
end

function WorldMarks:CreateMover()
    if self.mover then return end
    local f = self.frame
    if not f then return end
    self.mover = CreateFrame("Frame", "GravityUI_WorldMarks_Mover", UIParent, "BackdropTemplate")
    self.mover:SetAllPoints(f)
    self.mover:SetBackdrop({bgFile = [[Interface\ChatFrame\ChatFrameBackground]], edgeFile = [[Interface\ChatFrame\ChatFrameBackground]], edgeSize = 1})
    self.mover:SetBackdropColor(0, 0.5, 0, 0.5); self.mover:SetBackdropBorderColor(0, 1, 0, 1)
    self.mover:EnableMouse(true); self.mover:SetMovable(true); self.mover:RegisterForDrag("LeftButton")
    self.mover:SetFrameStrata("DIALOG"); self.mover:Hide()
    local text = self.mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER"); text:SetText("World Marks")
    self.mover:SetScript("OnDragStart", function() f:StartMoving(); self.mover:SetAllPoints(f) end)
    self.mover:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local centerX, centerY = UIParent:GetCenter()
        local frameX, frameY = f:GetCenter()
        local s = GetSettings()
        if s and frameX and centerX then s.offsetX, s.offsetY = frameX - centerX, frameY - centerY end
        self.mover:ClearAllPoints(); self.mover:SetAllPoints(f)
    end)
    hooksecurefunc(f, "SetSize", function() if self.mover then self.mover:SetSize(f:GetSize()) end end)
end

function WorldMarks:RegisterMover()
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("WorldMarks", self.frame, function(f, e, force) self:ToggleMover(force) end, "World Marks")
    end
end

ns.RefreshWorldMarks = WorldMarks.Refresh
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then CreateMarksBar() else C_Timer.After(1, function() WorldMarks.Refresh() end) end
end)

local orc = ns.RefreshAccentColors
ns.RefreshAccentColors = function() if orc then orc() end; if WorldMarks.Refresh then WorldMarks.Refresh() end end
_G.GravityUI_RefreshWorldMarks = WorldMarks.Refresh
