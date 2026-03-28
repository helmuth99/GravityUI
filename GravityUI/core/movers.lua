local ADDON_NAME, ns = ...
ns.Movers = {}
local Movers = ns.Movers

-- Constants
local CHECKBOX_LABEL = "Show GravityUI Elements"

-- State
Movers.registry = {} -- { [name] = { frame = frame, toggleFunc = func, label = "Label" } }
Movers.isEditMode = false
Movers.showGravityElements = false -- Default to false (User Request)

-- ============================================================================
-- REGISTRY
-- ============================================================================

function Movers:Register(name, frame, toggleFunc, label)
    if self.registry[name] then return end
    self.registry[name] = {
        frame = frame,
        toggleFunc = toggleFunc, -- Custom toggle function (e.g. preview mode)
        label = label or name
    }
end

function Movers:Toggle(name)
    local data = self.registry[name]
    if not data then return end
    
    if data.frame then
        if data.frame:IsShown() then
            data.frame:Hide()
        else
            data.frame:Show()
            -- Apply overlay style if in edit mode context, but for manual toggle usually we just want to see it
        end
    end
    
    if data.toggleFunc then
        local isShown = data.frame and data.frame:IsShown()
        pcall(data.toggleFunc, data.frame, isShown, isShown)
    end
end

-- ============================================================================
-- VISIBILITY LOGIC
-- ============================================================================

function Movers:SetEditMode(enabled)
    self.isEditMode = enabled
    self:UpdateDisplay()
end

function Movers:SetShowGravityElements(enabled)
    self.showGravityElements = enabled
    self:UpdateDisplay()
end

function Movers:UpdateDisplay()
    local shouldShow = self.isEditMode and self.showGravityElements
    
    for name, data in pairs(self.registry) do
        if data.toggleFunc then
            pcall(data.toggleFunc, data.frame, shouldShow, shouldShow)
        elseif data.frame then
            if shouldShow then
                data.frame:Show()
            else
                data.frame:Hide()
            end
        end
    end

    -- WorldMarks uses a custom mover not reliably reached via the registry loop.
    -- Call it explicitly to guarantee correct state on every display update.
    if ns.WorldMarks and ns.WorldMarks.ToggleMover then
        pcall(function() ns.WorldMarks:ToggleMover(shouldShow) end)
    end
end

-- ============================================================================
-- EDIT MODE HOOKS
-- ============================================================================

local function HookEditMode()
    if Movers.hooked then return end

    -- Helper to Init
    local function InitHook()
        if Movers.hooked then return end
        if not EditModeManagerFrame then return end
        
        -- 1. Hook Events
        if EventRegistry then
            EventRegistry:RegisterCallback("EditMode.Enter", function()
                Movers:SetEditMode(true)
                if Movers.checkbox then Movers.checkbox:Show() end
            end)
            
            EventRegistry:RegisterCallback("EditMode.Exit", function()
                Movers:SetEditMode(false)
                if Movers.checkbox then Movers.checkbox:Hide() end
            end)
        end
        
        -- 2. Create Checkbox
        -- Parent to UIParent to avoid z-order/clipping issues with Edit Mode internals, 
        -- but act as if attached.
        local cb = CreateFrame("CheckButton", "GravityUI_EditMode_Toggle", UIParent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetFrameStrata("FULLSCREEN_DIALOG") -- Ensure it's on top of everything
        -- Anchor to the right of the Layout Dropdown
        if EditModeManagerFrame.LayoutDropdown then
            cb:SetPoint("LEFT", EditModeManagerFrame.LayoutDropdown, "RIGHT", 30, 0)
        else
            -- Fallback if specific frame not found (though it should be there)
            cb:SetPoint("TOPLEFT", EditModeManagerFrame, "TOPLEFT", 300, -10)
        end
        
        -- Label
        local label = cb.Label or cb.Text or cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetText(CHECKBOX_LABEL)
        label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        cb.Label = label -- Ensure future access works if needed
        
        -- Initial State
        cb:SetChecked(Movers.showGravityElements)
        
        cb:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            Movers:SetShowGravityElements(checked)
        end)
        
        -- Hide initially, only show in Edit Mode
        cb:Hide()
        
        Movers.checkbox = cb
        Movers.hooked = true
        
    end

    -- Check if loaded
    if C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        InitHook()
    else
        local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(self, event, addon)
            if addon == "Blizzard_EditMode" then
                InitHook()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end

-- ============================================================================
-- INIT
-- ============================================================================

function Movers:Initialize()
    HookEditMode()
end

-- ============================================================================
-- STYLING
-- ============================================================================
function Movers:ApplyEditModeStyle(frame, enabled)
    if not frame then return end
    
    if enabled then
        if not frame.ag_backdrop then
            frame.ag_backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            frame.ag_backdrop:SetAllPoints(frame)
            frame.ag_backdrop:SetFrameStrata("DIALOG")
            frame.ag_backdrop:SetFrameLevel(frame:GetFrameLevel() + 10)
            frame.ag_backdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
            frame.ag_backdrop:EnableMouse(false) -- Click-through to the mover/frame below
        end
        frame.ag_backdrop:SetBackdropColor(0, 0.6, 1, 0.5) -- Blue Overlay
        frame.ag_backdrop:SetBackdropBorderColor(0, 0.8, 1, 1) -- Blue Border
        frame.ag_backdrop:Show()
    else
        if frame.ag_backdrop then
            frame.ag_backdrop:Hide()
        end
    end
end

-- Slash Command for manual toggle
SLASH_GRAVITYMOVERS1 = "/gravitymovers"
SlashCmdList["GRAVITYMOVERS"] = function()
    Movers:SetEditMode(true)
    Movers:SetShowGravityElements(true)
    print("GravityUI: Movers Force Enabled")
end

-- Auto-initialize on login so HookEditMode() actually runs
local _initFrame = CreateFrame("Frame")
_initFrame:RegisterEvent("PLAYER_LOGIN")
_initFrame:SetScript("OnEvent", function(self)
    Movers:Initialize()
    self:UnregisterAllEvents()
end)
