local ADDON_NAME, ns = ...

local LDBIcon = LibStub("LibDBIcon-1.0", true)
local Masque = LibStub("Masque", true)
local MasqueGroup = Masque and Masque:Group("GravityUI", "Icon Catcher")

local Catcher = {
    caughtIcons = {},
    isExpanded = false,
}
ns.IconCatcher = Catcher

-- ---------------------------------------------------------------------------
-- UI FRAME CREATION
-- ---------------------------------------------------------------------------

local CatcherFrame = CreateFrame("Frame", "GravityUI_IconCatcherFrame", UIParent)
CatcherFrame:SetSize(40, 40)
CatcherFrame:SetFrameStrata("MEDIUM")
CatcherFrame:SetFrameLevel(1)
CatcherFrame:EnableMouse(true)
CatcherFrame:SetMovable(true)
CatcherFrame:SetClampedToScreen(true)
CatcherFrame:Hide()

-- Button for the user to click
local ToggleBtn = CreateFrame("Button", nil, CatcherFrame, "BackdropTemplate")
ToggleBtn:SetAllPoints()
ToggleBtn:RegisterForClicks("AnyUp")

-- Give it a background so it's visible
ToggleBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
ToggleBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
ToggleBtn:SetBackdropBorderColor(0, 0, 0, 1)

-- Make it look like a puzzle piece (or a nice icon)
ToggleBtn.icon = ToggleBtn:CreateTexture(nil, "ARTWORK")
ToggleBtn.icon:SetPoint("TOPLEFT", ToggleBtn, "TOPLEFT", 4, -4)
ToggleBtn.icon:SetPoint("BOTTOMRIGHT", ToggleBtn, "BOTTOMRIGHT", -4, 4)
ToggleBtn.icon:SetTexture(ns.ICON_PATH)
ToggleBtn.icon:SetTexCoord(0, 1, 0, 1)

-- Container for the trapped icons
local GridContainer = CreateFrame("Frame", "GravityUI_IconCatcherGrid", CatcherFrame)
GridContainer:SetFrameStrata("MEDIUM")
GridContainer:SetFrameLevel(5)
GridContainer:Hide()

-- The actual black backdrop must be a SEPARATE child frame with a drastically lower FrameLevel.
-- If we put the Backdrop directly on GridContainer, WoW's Z-buffer will draw its BACKGROUND
-- layer over the ARTWORK layer of older Minimap icons, creating the optical illusion of dimming.
-- PARENT TO UIPARENT TO BREAK THE ENGINE'S STRATA INHERITANCE LOCK
GridContainer.bgFrame = CreateFrame("Frame", "GravityUI_IconCatcherBg", UIParent, "BackdropTemplate")
GridContainer.bgFrame:SetAllPoints(GridContainer)
GridContainer.bgFrame:SetFrameStrata("MEDIUM") 
GridContainer.bgFrame:SetFrameLevel(5)
GridContainer.bgFrame:Hide()

-- Reject external attempts or WoW Engine inherited attempts to lift the background
hooksecurefunc(GridContainer.bgFrame, "SetFrameLevel", function(self, level)
    if not self.GravityExt_IsUpdatingLevel and level > 5 then
        self.GravityExt_IsUpdatingLevel = true
        self:SetFrameLevel(5)
        self.GravityExt_IsUpdatingLevel = false
    end
end)
hooksecurefunc(GridContainer.bgFrame, "SetFrameStrata", function(self, strata)
    if not self.GravityExt_IsUpdatingStrata and strata ~= "MEDIUM" then
        self.GravityExt_IsUpdatingStrata = true
        self:SetFrameStrata("MEDIUM")
        self.GravityExt_IsUpdatingStrata = false
    end
end)
GridContainer.bgFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
GridContainer.bgFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
GridContainer.bgFrame:SetBackdropBorderColor(0, 0, 0, 1)

-- ---------------------------------------------------------------------------
-- LOGIC
-- ---------------------------------------------------------------------------

local function GetSettings()
    local db = ns.GetDB()
    return db and db.minimap and db.minimap.catcher
end

local fadeTimer = nil

local function CancelFade()
    if fadeTimer then
        fadeTimer:Cancel()
        fadeTimer = nil
    end
    UIFrameFadeIn(CatcherFrame, 0.2, CatcherFrame:GetAlpha(), 1)
end

local function StartFade()
    CancelFade()
    local s = GetSettings()
    if s and s.fadeOutEnabled and not Catcher.isExpanded then
        local time = s.fadeOutTime or 10
        fadeTimer = C_Timer.NewTimer(time, function()
            -- Only fade if mouse is not over it, and drawer is closed
            if not ToggleBtn:IsMouseOver() and not Catcher.isExpanded then
                UIFrameFadeOut(CatcherFrame, 0.5, CatcherFrame:GetAlpha(), 0)
            end
        end)
    end
end

ToggleBtn:SetScript("OnEnter", function()
    CancelFade()
end)

ToggleBtn:SetScript("OnLeave", function()
    if not Catcher.isExpanded then
        StartFade()
    end
end)

local function ApplyThemeToGrid()
    local s = GetSettings()
    if not s then return end

    -- Calculate the active theme/custom color to apply
    local r, g, b = 1, 1, 1
    if s.useThemeColor then
        -- Native GravityUI Theme Logic
        local db = ns.GetDB()
        local general = db and (db.general or (db.profile and db.profile.general))
        
        if general and general.themeColor then
            r, g, b = general.themeColor[1], general.themeColor[2], general.themeColor[3]
        else
            r, g, b = 0, 0.749, 1 -- Default blue
        end
        
        if general and general.useClassColorTheme then
            local _, class = UnitClass("player")
            local c = RAID_CLASS_COLORS[class]
            if c then r, g, b = c.r, c.g, c.b end
        end
    else
        -- User manually picked a color
        local custom = s.customBackgroundColor or {0.1, 0.1, 0.1, 0.95}
        r, g, b = custom[1], custom[2], custom[3]
    end

    if s.mode == "BAR" then
        -- Bar background receives the same dark grid color as Icon mode
        GridContainer.bgFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        GridContainer.bgFrame:SetBackdropBorderColor(0, 0, 0, 1)
        
        -- Toggle Button itself acts as the Bar
        ToggleBtn:SetBackdropColor(r, g, b, 1)
        ToggleBtn:SetBackdropBorderColor(0, 0, 0, 1)
        ToggleBtn.icon:Hide()
    else
        -- ICON mode transparent or rigid gray panel
        GridContainer.bgFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        GridContainer.bgFrame:SetBackdropBorderColor(0, 0, 0, 1)
        
        -- Toggle Button is grey, symbol receives the theme color
        ToggleBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        ToggleBtn:SetBackdropBorderColor(0, 0, 0, 1)
        ToggleBtn.icon:Show()
        ToggleBtn.icon:SetVertexColor(r, g, b, 1)
    end
end

-- ---------------------------------------------------------------------------
-- CORE LOGIC
-- ---------------------------------------------------------------------------

-- Prevent Texture Darkening/Desaturation from Global Skinning (e.g. Masque/AddOnSkins)
local function FixTexture(tex)
    if not tex or not tex.IsObjectType or not tex:IsObjectType("Texture") then return end
    
    -- Prevent Addons from darkening the icon
    if not tex.GravityExt_HookedColor then
        tex.GravityExt_HookedColor = true
        hooksecurefunc(tex, "SetVertexColor", function(t, r, g, b)
            if not t.GravityExt_UpdatingColor and (r < 0.9 or g < 0.9 or b < 0.9) then
                t.GravityExt_UpdatingColor = true
                t:SetVertexColor(1, 1, 1, 1)
                t.GravityExt_UpdatingColor = false
            end
        end)
        
        hooksecurefunc(tex, "SetDesaturated", function(t, desat)
            if not t.GravityExt_UpdatingColor and desat then
                t.GravityExt_UpdatingColor = true
                t:SetDesaturated(false)
                t.GravityExt_UpdatingColor = false
            end
        end)
    end
    
    -- Force it bright immediately
    tex.GravityExt_UpdatingColor = true
    tex:SetVertexColor(1, 1, 1, 1)
    tex:SetDesaturated(false)
    tex.GravityExt_UpdatingColor = false
end

local function CheckAndNuke(buttonFrame, regionParam, texParam)
    local isBorder = false
    
    -- Protect the main payload
    if regionParam == buttonFrame.icon or regionParam == buttonFrame.Icon then
        return false
    end
    
    if type(texParam) == "number" then
        if texParam == 136430 or texParam == 136467 or texParam == 136441 then
            isBorder = true
        end
    elseif type(texParam) == "string" then
        local tLower = texParam:lower()
        if tLower:find("trackingborder") or tLower:find("minimap%-background") or tLower:find("minimap%-border") then
            isBorder = true
        end
        if tLower:find("border") or tLower:find("ring") then
            isBorder = true
        end
    end
    
    -- Also check by name
    if not isBorder then
        local rName = regionParam:GetName()
        if rName and (rName:match("Border$") or rName:match("Background$")) then
            isBorder = true
        end
    end
    
    -- Size check: Anonymous large textures (>= 90% of button) are borders/backgrounds
    if not isBorder then
        local rw = regionParam:GetWidth()
        local bw = buttonFrame:GetWidth()
        if rw and bw and rw > 0 and bw > 0 and (rw >= bw * 0.9) then
            isBorder = true
        end
    end
    
    -- Explicit reference checks
    if regionParam == buttonFrame.border or regionParam == buttonFrame.background then
        isBorder = true
    end
    
    if isBorder then
        regionParam.GravityExt_Hiding = true
        regionParam:SetTexture("")
        regionParam:SetAlpha(0)
        regionParam:Hide()
        regionParam.GravityExt_Hiding = false
        return true
    end
    return false
end

local function GetCaughtButtonCount()
    local count = 0
    for _ in pairs(Catcher.caughtIcons) do count = count + 1 end
    return count
end

local function LayoutGrid()
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    local count = 0
    local iconsPerRow = s.iconsPerRow or 4
    local size = s.iconSize or 30
    local spacing = 2
    local dir = s.growDirection or "DOWN"
    
    local buttons = {}
    for btn, _ in pairs(Catcher.caughtIcons) do
        table.insert(buttons, btn)
    end
    
    -- Ensure consistent order
    table.sort(buttons, function(a, b) 
        local nameA = a:GetName() or tostring(a)
        local nameB = b:GetName() or tostring(b)
        return nameA < nameB 
    end)

    local cols = math.min(#buttons, iconsPerRow)
    local rows = math.ceil(#buttons / iconsPerRow)
    if cols == 0 then cols = 1; rows = 1 end

    local totalWidth = (cols * size) + ((cols - 1) * spacing) + 4
    local totalHeight = (rows * size) + ((rows - 1) * spacing) + 4
    
    GridContainer:SetSize(math.max(totalWidth, 20), math.max(totalHeight, 20))
    GridContainer:ClearAllPoints()
    
    -- Position Grid Container relative to the Toggle Button
    local gap = 0
    if dir == "DOWN" then
        GridContainer:SetPoint("TOP", ToggleBtn, "BOTTOM", 0, -gap)
    elseif dir == "UP" then
        GridContainer:SetPoint("BOTTOM", ToggleBtn, "TOP", 0, gap)
    elseif dir == "LEFT" then
        GridContainer:SetPoint("RIGHT", ToggleBtn, "LEFT", -gap, 0)
    elseif dir == "RIGHT" then
        GridContainer:SetPoint("LEFT", ToggleBtn, "RIGHT", gap, 0)
    end

    -- Position individual buttons inside the grid
    for i, btn in ipairs(buttons) do
        local col = (i - 1) % iconsPerRow
        local row = math.floor((i - 1) / iconsPerRow)
        
        -- Minimap icons break internally if resized via SetSize. 
        -- We must use SetScale to preserve their internal texture geometry.
        local baseSize = 32
        local btnScale = size / baseSize
        
        btn:SetParent(GridContainer)
        btn:SetSize(baseSize, baseSize)
        btn:SetScale(btnScale)
        
        local visualX, visualY = 0, 0
        local anchor1, anchor2 = "TOPLEFT", "TOPLEFT"
        
        if dir == "DOWN" then
             visualX = 2 + (col * (size + spacing))
             visualY = -2 - (row * (size + spacing))
             anchor1, anchor2 = "TOPLEFT", "TOPLEFT"
        elseif dir == "UP" then
             visualX = 2 + (col * (size + spacing))
             visualY = 2 + (row * (size + spacing))
             anchor1, anchor2 = "BOTTOMLEFT", "BOTTOMLEFT"
        elseif dir == "LEFT" then
             visualX = -2 - (col * (size + spacing))
             visualY = -2 - (row * (size + spacing))
             anchor1, anchor2 = "TOPRIGHT", "TOPRIGHT"
        elseif dir == "RIGHT" then
             visualX = 2 + (col * (size + spacing))
             visualY = -2 - (row * (size + spacing))
             anchor1, anchor2 = "TOPLEFT", "TOPLEFT"
        end
        
        local xOff = visualX / btnScale
        local yOff = visualY / btnScale
        -- Save the intended position so we can enforce it
        btn.GravityExt_Anchor1 = anchor1
        btn.GravityExt_Anchor2 = anchor2
        btn.GravityExt_xOff = xOff
        btn.GravityExt_yOff = yOff
        
        -- Bypass our own hook by toggling a flag
        btn.GravityExt_IsUpdating = true
        btn:ClearAllPoints()
        btn:SetPoint(anchor1, GridContainer, anchor2, xOff, yOff)
        btn.GravityExt_IsUpdating = false
        
        -- Aggressively re-apply strata every time drawer layout is rebuilt
        -- to override Addons that reset themselves constantly (e.g Details!)
        btn:SetFrameStrata("TOOLTIP")
        btn:SetFrameLevel(50)
        
        if Catcher.isExpanded then
            btn:Show()
        else
            btn:Hide()
        end
    end
end

-- Safely hijacks a button
local function CatchButton(buttonFrame, debugName, skipLayout)
    if not buttonFrame or Catcher.caughtIcons[buttonFrame] then return end
    
    -- Save its original Parent and Scale in case user disables the feature
    buttonFrame.GravityOriginalParent = buttonFrame:GetParent()
    buttonFrame.GravityOriginalScale = buttonFrame:GetScale()
    
    Catcher.caughtIcons[buttonFrame] = true
    
    -- Parent to GridContainer so it natively inherits drawer visibility!
    buttonFrame:SetParent(GridContainer)
    buttonFrame:SetFrameStrata("MEDIUM")
    buttonFrame:SetFrameLevel(50)
    
    -- Remove LibDBIcon's and other Addons' movement scripts so it stays in the grid
    if buttonFrame:GetScript("OnDragStart") then buttonFrame:SetScript("OnDragStart", nil) end
    if buttonFrame:GetScript("OnDragStop") then buttonFrame:SetScript("OnDragStop", nil) end
    if buttonFrame.SetMovable then buttonFrame:SetMovable(false) end
    
    -- Enforce position: if the Addon tries to SetPoint (like Details! does on click), force it back.
    if not buttonFrame.GravityExt_Hooked then
        hooksecurefunc(buttonFrame, "SetPoint", function(self)
            if not self.GravityExt_IsUpdating and self.GravityExt_Anchor1 then
                self.GravityExt_IsUpdating = true
                self:ClearAllPoints()
                self:SetPoint(self.GravityExt_Anchor1, GridContainer, self.GravityExt_Anchor2, self.GravityExt_xOff, self.GravityExt_yOff)
                self.GravityExt_IsUpdating = false
            end
        end)
        hooksecurefunc(buttonFrame, "ClearAllPoints", function(self)
            if not self.GravityExt_IsUpdating and self.GravityExt_Anchor1 then
                self.GravityExt_IsUpdating = true
                self:SetPoint(self.GravityExt_Anchor1, GridContainer, self.GravityExt_Anchor2, self.GravityExt_xOff, self.GravityExt_yOff)
                self.GravityExt_IsUpdating = false
            end
        end)
        
        -- Force icons to remain on MEDIUM strata so they stay above the Level 1 background
        hooksecurefunc(buttonFrame, "SetFrameStrata", function(self, strata)
            if not self.GravityExt_IsUpdatingStrata and strata ~= "MEDIUM" then
                self.GravityExt_IsUpdatingStrata = true
                self:SetFrameStrata("MEDIUM")
                self.GravityExt_IsUpdatingStrata = false
            end
        end)
        
        -- Force icons to remain at Level 50 or higher
        hooksecurefunc(buttonFrame, "SetFrameLevel", function(self, level)
            if not self.GravityExt_IsUpdatingLevel and level < 50 then
                self.GravityExt_IsUpdatingLevel = true
                self:SetFrameLevel(50)
                self.GravityExt_IsUpdatingLevel = false
            end
        end)
        
        -- Prevent generic Addons reparenting to Minimap
        hooksecurefunc(buttonFrame, "SetParent", function(self, newParent)
            if not self.GravityExt_IsUpdating and newParent ~= GridContainer then
                self.GravityExt_IsUpdating = true
                self:SetParent(GridContainer)
                self.GravityExt_IsUpdating = false
            end
        end)
        
        -- MASQUE SUPPORT: Hand over rendering payload if active
        local s = GetSettings()
        if s and s.masque and MasqueGroup then
            -- Forcefully strip the golden Blizzard ring and the default round background 
            for _, region in ipairs({buttonFrame:GetRegions()}) do
                if region:IsObjectType("Texture") then
                    
                    -- Initial check
                    CheckAndNuke(buttonFrame, region, region:GetTexture())
                    
                    -- Secure hook to prevent delayed reappearance
                    if not region.GravityExt_MasqueBorderHooked then
                        hooksecurefunc(region, "SetTexture", function(self, newTex)
                            if self.GravityExt_Hiding then return end
                            local s_live = GetSettings()
                            if not s_live or not s_live.masque then return end
                            
                            CheckAndNuke(buttonFrame, self, newTex)
                        end)
                        
                        hooksecurefunc(region, "Show", function(self)
                            if self.GravityExt_Hiding then return end
                            local s_live = GetSettings()
                            if not s_live or not s_live.masque then return end
                            
                            -- If it has 0 alpha or no texture, it's a nuked region trying to resurrect
                            if self:GetAlpha() == 0 or not self:GetTexture() then
                                self.GravityExt_Hiding = true
                                self:Hide()
                                self.GravityExt_Hiding = false
                            end
                        end)
                        
                        region.GravityExt_MasqueBorderHooked = true
                    end
                end
            end
            MasqueGroup:AddButton(buttonFrame)
        else
            -- Fix direct icon reference if it exists
            if buttonFrame.icon then 
                FixTexture(buttonFrame.icon)
                buttonFrame.icon:SetDrawLayer("OVERLAY", 7)
            end
            
            -- Fix all internal textures
            for _, region in ipairs({buttonFrame:GetRegions()}) do
                FixTexture(region)
            end
            
            -- Force Alpha to 1. If an external Addon is forcing them to 50% opacity, 
            -- the dark background bleeds through and makes them look shadowed/behind.
            buttonFrame:SetAlpha(1)
            hooksecurefunc(buttonFrame, "SetAlpha", function(self, alpha)
                if not self.GravityExt_IsUpdatingAlpha and alpha < 1 then
                    self.GravityExt_IsUpdatingAlpha = true
                    self:SetAlpha(1)
                    self.GravityExt_IsUpdatingAlpha = false
                end
            end)
        end
        
        -- Prevent addons from hiding their buttons while the drawer is visibly open
        hooksecurefunc(buttonFrame, "Hide", function(self)
            if Catcher.isExpanded and not self.GravityExt_IsUpdating then
                self.GravityExt_IsUpdating = true
                self:Show()
                self.GravityExt_IsUpdating = false
            end
        end)
        
        -- Prevent addons from showing their buttons while the drawer is visibly closed
        hooksecurefunc(buttonFrame, "Show", function(self)
            if not Catcher.isExpanded and not self.GravityExt_IsUpdating then
                self.GravityExt_IsUpdating = true
                self:Hide()
                self.GravityExt_IsUpdating = false
            end
        end)

        -- Prevent addons from using SetShown to bypass Show/Hide hooks
        if buttonFrame.SetShown then
            hooksecurefunc(buttonFrame, "SetShown", function(self, show)
                if not self.GravityExt_IsUpdating then
                    if show and not Catcher.isExpanded then
                        self.GravityExt_IsUpdating = true
                        self:Hide()
                        self.GravityExt_IsUpdating = false
                    elseif not show and Catcher.isExpanded then
                        self.GravityExt_IsUpdating = true
                        self:Show()
                        self.GravityExt_IsUpdating = false
                    end
                end
            end)
        end
        
        buttonFrame.GravityExt_Hooked = true
    end
    
    if not skipLayout then
        LayoutGrid()
    end
end

-- Callback when LibDBIcon creates a brand new button (Event Driven)
local function OnLDBIconCreated(event, buttonFrame, name)
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    CatchButton(buttonFrame, name)
end

-- Manual catching of existing buttons (run once on load)
local function CatchExistingButtons()
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    -- Move both LibDBIcon and Hardcoded scans into the delayed Ticker
    -- This guarantees that external addons (like Masque) finish skinning the icons BEFORE we capture them,
    -- allowing our FixTexture to successfully strip the dark overlays they inject.
    
    local framesToFind = {
        LibDBIcon10_MethodRaidTools = true,
    }
    
    -- IMMEDIATE FRAME 0 SWEEP to prevent minimap UI flicker on load
    local initialCatch = false
    if LDBIcon then
        local buttons = LDBIcon:GetButtonList()
        if buttons then
            for _, name in ipairs(buttons) do
                local btn = LDBIcon:GetMinimapButton(name)
                if btn and not Catcher.caughtIcons[btn] then 
                    CatchButton(btn, name, true)
                    initialCatch = true
                end
            end
        end
    end
    for frameName, needsFinding in pairs(framesToFind) do
        if needsFinding then
            local f = _G[frameName]
            if f and type(f) == "table" and f.SetPoint then
                CatchButton(f, frameName, true)
                framesToFind[frameName] = false -- Found it!
                initialCatch = true
            end
        end
    end
    
    if initialCatch then
        LayoutGrid()
    end
    
    -- Delayed Ticker to overcome AddonSkins/Masque overwrites
    local attempts = 0
    local ticker
    ticker = C_Timer.NewTicker(1.0, function()
        attempts = attempts + 1
        
        local tickCatch = false
        -- Scan LibDBIcon dynamically during the ticker
        if LDBIcon then
            local buttons = LDBIcon:GetButtonList()
            if buttons then
                for _, name in ipairs(buttons) do
                    local btn = LDBIcon:GetMinimapButton(name)
                    if btn and not Catcher.caughtIcons[btn] then 
                        CatchButton(btn, name, true)
                        tickCatch = true
                    end
                end
            end
        end
        
        for frameName, needsFinding in pairs(framesToFind) do
            if needsFinding then
                local f = _G[frameName]
                if f and type(f) == "table" and f.SetPoint then
                    CatchButton(f, frameName, true)
                    framesToFind[frameName] = false -- Found it!
                    tickCatch = true
                end
            end
        end
        
        if tickCatch then
            LayoutGrid()
        end
        
        -- Stop after 10 loops
        if attempts >= 10 then
            ticker:Cancel()
        end
    end)
end
-- ---------------------------------------------------------------------------
-- TOGGLE & DRAG LOGIC
-- ---------------------------------------------------------------------------

local function ToggleDrawer()
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    if Catcher.isExpanded then
        Catcher.isExpanded = false
        GridContainer:Hide()
        GridContainer.bgFrame:Hide()
        for btn, _ in pairs(Catcher.caughtIcons) do
            btn:Hide()
        end
        StartFade()
    else
        Catcher.isExpanded = true
        CancelFade()
        CatcherFrame:SetAlpha(1)
        GridContainer:Show()
        GridContainer.bgFrame:Show()
        for btn, _ in pairs(Catcher.caughtIcons) do
            btn:Show()
        end
    end
end

ToggleBtn:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
        ToggleDrawer()
    elseif button == "RightButton" and ns.GUI then
        ns.GUI:Toggle()
    end
end)

ToggleBtn:SetScript("OnEnter", function(self)
    CancelFade()
    local s = GetSettings()
    if s and s.mode == "BAR" and not Catcher.isExpanded then
        ToggleDrawer()
    end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cFF30D1FFAddon Drawer|r")
    if s and s.mode == "ICON" then
        GameTooltip:AddLine("Left-click to toggle extensions", 1, 1, 1)
    end
    GameTooltip:AddLine("Right-click for GravityUI settings", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)

ToggleBtn:SetScript("OnLeave", function() 
    GameTooltip:Hide() 
    if not Catcher.isExpanded then
        StartFade()
    end
end)

local hoverGraceTimer = 0
local hoverOffTimer = 0

GridContainer:SetScript("OnUpdate", function(self, elapsed)
    if not Catcher.isExpanded then 
        hoverOffTimer = 0
        return 
    end
    
    hoverGraceTimer = hoverGraceTimer + elapsed
    if hoverGraceTimer > 0.1 then
        hoverGraceTimer = 0
        local s = GetSettings()
        if not s then return end
        
        -- Check if mouse is over the Toggle Button OR the Grid Container
        local isOverButton = ToggleBtn:IsMouseOver()
        local isOverGrid = GridContainer.bgFrame:IsMouseOver()
        
        if not isOverButton and not isOverGrid then
            hoverOffTimer = hoverOffTimer + 0.1
            -- If mouse has been off for more than 1.0 second, auto-close
            if hoverOffTimer >= 1.0 then
                if Catcher.isExpanded then
                    ToggleDrawer()
                end
                hoverOffTimer = 0
            end
        else
            -- Mouse is back inside, reset the grace timer instantly
            hoverOffTimer = 0
        end
    end
end)

local function SmartSnap(s, f)
    local left = f:GetLeft()
    local right = f:GetRight()
    local top = f:GetTop()
    local bottom = f:GetBottom()
    
    if not left or not right or not top or not bottom then return end

    local uW, uH = UIParent:GetSize()
    
    local distLeft = left
    local distRight = uW - right
    local distTop = uH - top
    local distBottom = bottom
    
    local min = math.min(distLeft, distRight, distTop, distBottom)
    
    -- Threshold of 50 UI pixels
    if min < 50 then
        local scale = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
        if min == distLeft then
            s.snapEdge = "LEFT"
            s.offsetX = (-uW/2 * scale) + (f:GetWidth() / 2 * scale)
            s.growDirection = "RIGHT"
        elseif min == distRight then
            s.snapEdge = "RIGHT"
            s.offsetX = (uW/2 * scale) - (f:GetWidth() / 2 * scale)
            s.growDirection = "LEFT"
        elseif min == distTop then
            s.snapEdge = "TOP"
            s.offsetY = (uH/2 * scale) - (f:GetHeight() / 2 * scale)
            s.growDirection = "DOWN"
        elseif min == distBottom then
            s.snapEdge = "BOTTOM"
            s.offsetY = (-uH/2 * scale) + (f:GetHeight() / 2 * scale)
            s.growDirection = "UP"
        end
    else
        s.snapEdge = "NONE"
    end
end

local function UpdateButtonPosition()
    local s = GetSettings()
    if not s then return end
    
    CatcherFrame:ClearAllPoints()
    if s.mode == "BAR" then
        -- Freely movable via Movers
        CatcherFrame:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 0)
    else
        -- Icon mode (attach to Minimap)
        local angle = math.rad(s.minimapPos or 200)
        local isSquare = false
        
        -- GravityUI overrides GetMinimapShape globally for its square mode
        if _G.GetMinimapShape and _G.GetMinimapShape() == "SQUARE" then
            isSquare = true
        elseif GetCVar("minimapShape") == "SQUARE" then
            isSquare = true
        end

        local x, y
        if isSquare then
            local radius = (Minimap:GetWidth() / 2) + 5
            local cosA, sinA = math.cos(angle), math.sin(angle)
            local scale = math.max(math.abs(cosA), math.abs(sinA))
            if scale > 0 then
                x = (cosA / scale) * radius
                y = (sinA / scale) * radius
            else
                x, y = 0, 0
            end
        else
            local radius = (Minimap:GetWidth() / 2) + 10
            x = math.cos(angle) * radius
            y = math.sin(angle) * radius
        end
        
        CatcherFrame:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end

ToggleBtn:SetScript("OnDragStart", function(self)
    local s = GetSettings()
    if not s or s.locked then return end
    
    if s.mode == "ICON" then
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local angle = math.deg(math.atan2(py - my, px - mx))
            if angle < 0 then angle = angle + 360 end
            s.minimapPos = angle
            UpdateButtonPosition()
        end)
    elseif s.mode == "BAR" then
        CatcherFrame:StartMoving()
    end
end)

ToggleBtn:SetScript("OnDragStop", function(self)
    local s = GetSettings()
    if not s or s.locked then return end
    
    if s.mode == "ICON" then
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    elseif s.mode == "BAR" then
        CatcherFrame:StopMovingOrSizing()
        local cx, cy = CatcherFrame:GetCenter()
        local ux, uy = UIParent:GetCenter()
        local scale = CatcherFrame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        s.offsetX = (cx - ux) * scale
        s.offsetY = (cy - uy) * scale
        
        SmartSnap(s, CatcherFrame)
        ns.RefreshAddonDrawer()
    end
end)

-- ---------------------------------------------------------------------------
-- INITIALIZATION 
-- ---------------------------------------------------------------------------

local LDBIconHooked = false

function ns.RefreshAddonDrawer()
    local s = GetSettings()
    
    if not s or not s.enabled then
        CatcherFrame:Hide()
        for btn, _ in pairs(Catcher.caughtIcons) do
            btn:Hide()
        end
        -- Note: Releasing icons back to minimap is complex, usually requires a reload
        return
    end
    
    if s.mode == "BAR" then
        local w = s.catcherBarWidth or 100
        local h = s.catcherBarHeight or 20
        
        -- Override dimensions if snapped vertically
        if s.snapEdge == "LEFT" or s.snapEdge == "RIGHT" then
            -- Swap width and height
            w, h = s.catcherBarHeight or 20, s.catcherBarWidth or 100
        end
        
        CatcherFrame:SetSize(w, h)
    else
        local size = s.catcherIconSize or 40
        CatcherFrame:SetSize(size, size)
    end
    
    CatcherFrame:Show()
    UpdateButtonPosition()
    ApplyThemeToGrid()
    LayoutGrid()
    
    -- Sync visibility with Toggle Drawer state
    if not Catcher.isExpanded then
        GridContainer:Hide()
        GridContainer.bgFrame:Hide()
        for btn, _ in pairs(Catcher.caughtIcons) do
            btn:Hide()
        end
    else
        GridContainer:Show()
        GridContainer.bgFrame:Show()
        for btn, _ in pairs(Catcher.caughtIcons) do
            btn:Show()
        end
    end
    
    if s.locked then
        ToggleBtn:RegisterForDrag() -- Clear drag handlers
    else
        ToggleBtn:RegisterForDrag("LeftButton") -- Let UI or our radial drag handle it
    end
    
    StartFade()
end

-- ---------------------------------------------------------------------------
-- AGGRESSIVE STARTUP HOOKS (For Late-Loaders like MRT)
-- ---------------------------------------------------------------------------
local function SetupAggressiveHooks()
    -- Hook CreateFrame to catch buttons the exact millisecond they are spawned
    -- to prevent UI flicker before the 2-second late init timer catches them.
    local originalCreateFrame = CreateFrame
    
    -- Fast lookup for known offenders
    local catchTargets = {
        ["LibDBIcon10_MethodRaidTools"] = true
    }
    
    hooksecurefunc("CreateFrame", function(frameType, name, parent, template)
        if name and catchTargets[name] then
            local f = _G[name]
            if f then
                CatchButton(f, name)
            end
        end
    end)
end

SetupAggressiveHooks()

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local s = GetSettings()
        if not s or not s.enabled then return end
        
        C_Timer.After(2, function()
            -- Late init to ensure Addons have loaded their Minimap icons
            CatchExistingButtons()
            ns.RefreshAddonDrawer()
            
            -- Hook LibDBIcon for any future buttons created during gameplay
            if LDBIcon and not LDBIconHooked then
                LDBIcon.RegisterCallback("GravityUI_IconCatcher", "LibDBIcon_IconCreated", OnLDBIconCreated)
                LDBIconHooked = true
            end
        end)
    end
end)

if ns.Movers then
    ns.Movers:Register("IconCatcher", CatcherFrame, function(frame, enabled)
         local s = GetSettings()
         if not s or s.mode ~= "BAR" then return end
         ns.Movers:ApplyEditModeStyle(frame, enabled)
         if enabled and not s.locked then
             CatcherFrame:SetScript("OnDragStart", function(f) f:StartMoving() end)
             CatcherFrame:SetScript("OnDragStop", function(f) 
                 f:StopMovingOrSizing()
                 local cx, cy = f:GetCenter()
                 local ux, uy = UIParent:GetCenter()
                 local scale = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
                 s.offsetX = (cx - ux) * scale
                 s.offsetY = (cy - uy) * scale
                 
                 SmartSnap(s, f)
                 ns.RefreshAddonDrawer()
             end)
         else
             CatcherFrame:SetScript("OnDragStart", nil)
             CatcherFrame:SetScript("OnDragStop", nil)
         end
    end, "Icon Catcher (Addon Drawer)")
end
