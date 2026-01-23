--[[
    GravityUI Custom GUI Framework
    Style: Horizontal tab grid at top
    Accent Color: #56D1FF
]]

local ADDON_NAME, ns = ...
local gui = GravityUI
local LSM = LibStub("LibSharedMedia-3.0")

-- Create GUI namespace
gui.GUI = gui.GUI or {}
local GUI = gui.GUI

---------------------------------------------------------------------------
-- THEME COLORS - "Blue Condition" Palette
---------------------------------------------------------------------------
GUI.Colors = {
    -- Backgrounds
    bg = {0.117, 0.121, 0.133, 1},         -- #1e1f22ff Deep Cool Grey (Main Background)
    bgLight = {0.122, 0.161, 0.216, 1},       -- #1F2937 Lighter Sidebar/Headers
    bgDark = {0.04, 0.05, 0.08, 1},           -- Even darker for inputs/contrast
    bgContent = {0, 0, 0, 0},                 -- Transparent (content uses main bg)
    
    -- Accent colors
    accent = {0, 0.749, 1, 1},                -- #00BFFF Deep Sky Blue (Primary Accent)
    accentLight = {0.529, 0.808, 0.980, 1},   -- #87CEFA Light Sky Blue (Secondary/Text)
    accentDark = {0, 0.4, 0.6, 1},            -- Darker blue for interactions
    accentHover = {0.2, 0.8, 1, 1},           -- Hover state
    
    -- Tab colors (Sidebar)
    tabSelected = {0.122, 0.161, 0.216, 1},   -- Matches bgLight
    tabSelectedText = {0, 0.749, 1, 1},       -- Deep Sky Blue text
    tabNormal = {0, 0, 0, 0},                 -- Transparent background
    tabHover = {0.15, 0.2, 0.25, 0.5},        -- Subtle hover effect
    
    -- Text colors
    text = {0.9, 0.92, 0.95, 1},              -- #E5E7EB Light Grey (Main Text)
    textBright = {1, 1, 1, 1},                -- White
    textMuted = {0.6, 0.65, 0.7, 1},          -- Muted Grey
    
    -- Borders
    border = {0.2, 0.23, 0.28, 1},            -- Subtle dark border
    borderLight = {0.3, 0.35, 0.4, 1},        -- Slightly lighter
    borderAccent = {0, 0.749, 1, 1},          -- Deep Sky Blue border
    
    -- Section headers
    sectionHeader = {0.529, 0.808, 0.980, 1}, -- Light Sky Blue
    
    -- Slider colors
    sliderTrack = {0.12, 0.15, 0.2, 1},       -- Dark track
    sliderThumb = {1, 1, 1, 1},               -- White thumb
    sliderThumbBorder = {0, 0.749, 1, 1},     -- Blue border
    
    -- Toggle switch colors
    toggleOff = {0.2, 0.23, 0.28, 1},         -- Dark grey track
    toggleThumb = {1, 1, 1, 1},               -- White circle
    
    -- Warning/secondary accent
    warning = {0.961, 0.620, 0.043, 1},       -- #F59E0B Amber
}

local C = GUI.Colors

-- Panel dimensions (used for widget sizing)
GUI.PANEL_WIDTH = 750
GUI.CONTENT_WIDTH = 700  -- Panel width minus padding (20 each side)

-- Settings Registry for search functionality
GUI.SettingsRegistry = {}

-- Search context (auto-populated by page builders)
GUI._searchContext = {
    tabIndex = nil,
    tabName = nil,
    subTabIndex = nil,
    subTabName = nil,
    sectionName = nil,
}

-- Suppress auto-registration when rebuilding widgets for search results
GUI._suppressSearchRegistration = false

-- Deduplication keys to prevent duplicate registry entries when tabs are re-clicked
GUI.SettingsRegistryKeys = {}

-- Widget instance tracking for cross-widget synchronization (search results <-> original tabs)
GUI.WidgetInstances = {}

-- Generate unique key for widget instance tracking
local function GetWidgetKey(dbTable, dbKey)
    if not dbTable or not dbKey then return nil end
    return tostring(dbTable) .. "_" .. dbKey
end

-- Register a widget instance for sync tracking
local function RegisterWidgetInstance(widget, dbTable, dbKey)
    local widgetKey = GetWidgetKey(dbTable, dbKey)
    if not widgetKey then return end
    GUI.WidgetInstances[widgetKey] = GUI.WidgetInstances[widgetKey] or {}
    table.insert(GUI.WidgetInstances[widgetKey], widget)
    widget._widgetKey = widgetKey
end

-- Unregister a widget instance (called during cleanup)
local function UnregisterWidgetInstance(widget)
    if not widget._widgetKey then return end
    local instances = GUI.WidgetInstances[widget._widgetKey]
    if not instances then return end
    for i = #instances, 1, -1 do
        if instances[i] == widget then
            table.remove(instances, i)
            break
        end
    end
end

-- Broadcast value change to all sibling widget instances
local function BroadcastToSiblings(widget, val)
    if not widget._widgetKey then return end
    local instances = GUI.WidgetInstances[widget._widgetKey]
    if not instances then return end
    for _, sibling in ipairs(instances) do
        if sibling ~= widget and sibling.UpdateVisual then
            sibling.UpdateVisual(val)
        end
    end
end
-- Set search context for auto-registration (call at start of page builder)
function GUI:SetSearchContext(info)
    self._searchContext.tabIndex = info.tabIndex
    self._searchContext.tabName = info.tabName
    self._searchContext.subTabIndex = info.subTabIndex or nil
    self._searchContext.subTabName = info.subTabName or nil
    self._searchContext.sectionName = info.sectionName or nil
end

-- Set current section (call when entering a new section within a page)
function GUI:SetSearchSection(sectionName)
    self._searchContext.sectionName = sectionName
end

-- Clear search context (optional, for safety)
function GUI:ClearSearchContext()
    self._searchContext = {
        tabIndex = nil,
        tabName = nil,
        subTabIndex = nil,
        subTabName = nil,
        sectionName = nil,
    }
end

-- Flag to track if search index has been built
GUI._searchIndexBuilt = false

-- Force-load all tabs to populate search registry
function GUI:ForceLoadAllTabs()
    local frame = self.MainFrame
    if not frame or not frame.pages then return end

    -- Initialize registry if needed (don't clear - keep registrations from already-visited tabs)
    if not self.SettingsRegistry then
        self.SettingsRegistry = {}
    end
    if not self.SettingsRegistryKeys then
        self.SettingsRegistryKeys = {}
    end

    -- Build each tab that hasn't been built yet
    for tabIndex, page in pairs(frame.pages) do
        if tabIndex ~= self._searchTabIndex then  -- Skip Search tab itself
            if page and page.createFunc and not page.built then
                -- Create hidden frame if needed
                if not page.frame then
                    page.frame = CreateFrame("Frame", nil, frame.contentArea)
                    page.frame:SetAllPoints()
                    page.frame:EnableMouse(false)  -- Container frame - let children handle clicks
                end
                page.frame:Hide()  -- Keep hidden during build

                -- Run the builder to register widgets (only once)
                page.createFunc(page.frame)
                page.built = true  -- Prevent duplicate widget creation
            end
        end
    end
end

---------------------------------------------------------------------------
-- FONT PATH (uses bundled Gravity font for consistent panel formatting)
---------------------------------------------------------------------------
local FONT_PATH = LSM:Fetch("font", "Gravity") or [[Interface\AddOns\GravityUI\assets\Gravity.ttf]]
GUI.FONT_PATH = FONT_PATH

-- Helper for future configurability
local function GetFontPath()
    return FONT_PATH
end

---------------------------------------------------------------------------
-- UTILITY FUNCTIONS
---------------------------------------------------------------------------
local function CreateBackdrop(frame, bgColor, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bgColor or C.bg))
    frame:SetBackdropBorderColor(unpack(borderColor or C.border))
end

local function SetFont(fontString, size, flags, color)
    fontString:SetFont(GetFontPath(), size or 12, flags or "")
    if color then
        fontString:SetTextColor(unpack(color))
    end
end

---------------------------------------------------------------------------
-- WIDGET: LABEL
---------------------------------------------------------------------------
function GUI:CreateLabel(parent, text, size, color, anchor, x, y)
    -- Mark content as added (for section header auto-spacing)
    if parent._hasContent ~= nil then
        parent._hasContent = true
    end
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(label, size or 12, "", color or C.text)
    label:SetText(text or "")
    if anchor then
        label:SetPoint(anchor, parent, anchor, x or 0, y or 0)
    end
    return label
end

---------------------------------------------------------------------------
-- WIDGET: THEMED BUTTON (Neutral style - accent border on hover only)
---------------------------------------------------------------------------
function GUI:CreateButton(parent, text, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 120, height or 26)

    -- Normal state: dark background with grey border (neutral)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

    -- Button text (off-white, not accent)
    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetFont(GetFontPath(), 12, "")
    btnText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    btnText:SetPoint("CENTER", 0, 0)
    btnText:SetText(text or "Button")
    btn.text = btnText

    -- Hover effect: accent border only (no background change)
    btn:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, C.accent[1], C.accent[2], C.accent[3], 1)
    end)

    btn:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, C.border[1], C.border[2], C.border[3], 1)
    end)

    -- Click handler
    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    -- Method to update text
    function btn:SetText(newText)
        btnText:SetText(newText)
    end

    return btn
end

---------------------------------------------------------------------------
-- CONFIRMATION DIALOG (gui-styled replacement for StaticPopup)
-- Singleton frame, lazy-created and reused
---------------------------------------------------------------------------
local confirmDialog = nil

function GUI:ShowConfirmation(options)
    -- options = {
    --   title = "Delete Profile?",
    --   message = "Delete profile 'ProfileName'?",
    --   warningText = "This cannot be undone.",  -- optional, amber text
    --   acceptText = "Delete",
    --   cancelText = "Cancel",
    --   onAccept = function() end,
    --   onCancel = function() end,  -- optional
    --   isDestructive = true,       -- amber text on accept button
    -- }

    if not confirmDialog then
        -- Create singleton dialog frame
        confirmDialog = CreateFrame("Frame", "gui_ConfirmDialog", UIParent, "BackdropTemplate")
        confirmDialog:SetSize(320, 160)
        confirmDialog:SetPoint("CENTER")
        confirmDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        confirmDialog:SetFrameLevel(500)
        confirmDialog:EnableMouse(true)
        confirmDialog:SetMovable(true)
        confirmDialog:RegisterForDrag("LeftButton")
        confirmDialog:SetScript("OnDragStart", function(self) self:StartMoving() end)
        confirmDialog:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        confirmDialog:SetClampedToScreen(true)
        confirmDialog:Hide()

        -- Backdrop
        confirmDialog:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        confirmDialog:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.98)
        confirmDialog:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        -- Title
        confirmDialog.title = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.title, 14, "", C.accentLight)
        confirmDialog.title:SetPoint("TOP", 0, -18)

        -- Message
        confirmDialog.message = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.message, 12, "", C.text)
        confirmDialog.message:SetPoint("TOP", 0, -50)
        confirmDialog.message:SetWidth(280)
        confirmDialog.message:SetJustifyH("CENTER")

        -- Warning text
        confirmDialog.warning = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.warning, 11, "", C.warning)
        confirmDialog.warning:SetPoint("TOP", confirmDialog.message, "BOTTOM", 0, -8)

        -- Accept button (left)
        confirmDialog.acceptBtn = CreateFrame("Button", nil, confirmDialog, "BackdropTemplate")
        confirmDialog.acceptBtn:SetSize(100, 28)
        confirmDialog.acceptBtn:SetPoint("BOTTOMLEFT", 40, 20)
        confirmDialog.acceptBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        confirmDialog.acceptBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        confirmDialog.acceptBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        confirmDialog.acceptBtn.text = confirmDialog.acceptBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        confirmDialog.acceptBtn.text:SetFont(GetFontPath(), 12, "")
        confirmDialog.acceptBtn.text:SetPoint("CENTER", 0, 0)

        confirmDialog.acceptBtn:SetScript("OnEnter", function(self)
            pcall(self.SetBackdropBorderColor, self, C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        confirmDialog.acceptBtn:SetScript("OnLeave", function(self)
            pcall(self.SetBackdropBorderColor, self, C.border[1], C.border[2], C.border[3], 1)
        end)

        -- Cancel button (right)
        confirmDialog.cancelBtn = CreateFrame("Button", nil, confirmDialog, "BackdropTemplate")
        confirmDialog.cancelBtn:SetSize(100, 28)
        confirmDialog.cancelBtn:SetPoint("BOTTOMRIGHT", -40, 20)
        confirmDialog.cancelBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        confirmDialog.cancelBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        confirmDialog.cancelBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        confirmDialog.cancelBtn.text = confirmDialog.cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        confirmDialog.cancelBtn.text:SetFont(GetFontPath(), 12, "")
        confirmDialog.cancelBtn.text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
        confirmDialog.cancelBtn.text:SetPoint("CENTER", 0, 0)

        confirmDialog.cancelBtn:SetScript("OnEnter", function(self)
            pcall(self.SetBackdropBorderColor, self, C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        confirmDialog.cancelBtn:SetScript("OnLeave", function(self)
            pcall(self.SetBackdropBorderColor, self, C.border[1], C.border[2], C.border[3], 1)
        end)

        -- ESC to close
        confirmDialog:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false)
                if self._onCancel then self._onCancel() end
                self:Hide()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)
    end

    -- Configure for this call
    confirmDialog.title:SetText(options.title or "Confirm")
    confirmDialog.message:SetText(options.message or "")

    if options.warningText then
        confirmDialog.warning:SetText(options.warningText)
        confirmDialog.warning:Show()
    else
        confirmDialog.warning:Hide()
    end

    -- Accept button styling
    confirmDialog.acceptBtn.text:SetText(options.acceptText or "OK")
    if options.isDestructive then
        confirmDialog.acceptBtn.text:SetTextColor(C.warning[1], C.warning[2], C.warning[3], 1)
    else
        confirmDialog.acceptBtn.text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    end

    -- Cancel button
    confirmDialog.cancelBtn.text:SetText(options.cancelText or "Cancel")

    -- Store callbacks
    confirmDialog._onCancel = options.onCancel

    -- Button click handlers
    confirmDialog.acceptBtn:SetScript("OnClick", function()
        confirmDialog:Hide()
        if options.onAccept then options.onAccept() end
    end)

    confirmDialog.cancelBtn:SetScript("OnClick", function()
        confirmDialog:Hide()
        if options.onCancel then options.onCancel() end
    end)

    -- Show and enable keyboard
    confirmDialog:Show()
    confirmDialog:EnableKeyboard(true)
end

---------------------------------------------------------------------------
-- WIDGET: SECTION HEADER (Blue colored text with underline)
-- Auto-detects if first element in panel (no top margin) vs subsequent (12px margin)
---------------------------------------------------------------------------
function GUI:CreateSectionHeader(parent, text)
    -- Auto-detect if this is the first element (for compact spacing at top of panels)
    local isFirstElement = (parent._hasContent == false)
    if parent._hasContent ~= nil then
        parent._hasContent = true
    end

    -- First element: no top margin (18px), others: 12px top margin (30px)
    local topMargin = isFirstElement and 0 or 12
    local containerHeight = isFirstElement and 18 or 30

    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(containerHeight)

    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(header, 13, "", C.sectionHeader)
    header:SetText(text or "Section")
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -topMargin)

    -- Store references and recommended gap for calling code
    container.text = header
    container.parent = parent
    container.gap = isFirstElement and 34 or 46  -- Adjusted gap for y positioning

    -- Expose SetText for convenience
    container.SetText = function(self, newText)
        header:SetText(newText)
    end

    -- Hook SetPoint to also set width and create underline after positioning
    local originalSetPoint = container.SetPoint
    container.SetPoint = function(self, point, ...)
        originalSetPoint(self, point, ...)
        -- After TOPLEFT is set, also anchor RIGHT to give container width
        if point == "TOPLEFT" then
            originalSetPoint(self, "RIGHT", parent, "RIGHT", -10, 0)
            -- Create underline now that we have positioning
            if not container.underline then
                local underline = container:CreateTexture(nil, "ARTWORK")
                underline:SetHeight(2)
                underline:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
                underline:SetPoint("RIGHT", container, "RIGHT", 0, 0)
                underline:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.6)
                container.underline = underline
            end
        end
    end

    return container
end

---------------------------------------------------------------------------
-- WIDGET: SECTION BOX (Bordered group like old GUI)
-- Auto-calculates height based on content added via box:AddElement()
---------------------------------------------------------------------------
function GUI:CreateSectionBox(parent, title)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.05, 0.05, 0.08, 0.8)
    box:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    -- Title (Blue colored, positioned at top-left inside border)
    if title and title ~= "" then
        local titleText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetFont(GetFontPath(), 12, "")
        titleText:SetTextColor(unpack(C.accentLight))
        titleText:SetText(title)
        titleText:SetPoint("TOPLEFT", 10, -8)
        box.title = titleText
    end
    
    -- Track current Y position for auto-layout
    box.currentY = -30  -- Starting Y position for content inside the box
    box.padding = 12    -- Left/right padding
    box.elementSpacing = 8  -- Default spacing between elements
    
    -- Helper to add element and auto-position it
    function box:AddElement(element, height, spacing)
        local sp = spacing or self.elementSpacing
        element:SetPoint("TOPLEFT", self.padding, self.currentY)
        if element.SetPoint then
            -- If element supports right anchor, stretch it
            element:SetPoint("TOPRIGHT", -self.padding, self.currentY)
        end
        self.currentY = self.currentY - (height or 25) - sp
    end
    
    -- Call this after adding all elements to set the box height
    function box:FinishLayout(bottomPadding)
        local pad = bottomPadding or 12
        self:SetHeight(math.abs(self.currentY) + pad)
        return math.abs(self.currentY) + pad  -- Return height for parent tracking
    end
    
    return box
end

---------------------------------------------------------------------------
-- WIDGET: COLLAPSIBLE SECTION
-- Expandable/collapsible container with clickable header
---------------------------------------------------------------------------
function GUI:CreateCollapsibleSection(parent, title, isExpandedByDefault, badgeConfig)
    local container = CreateFrame("Frame", nil, parent)
    local isExpanded = isExpandedByDefault ~= false  -- Default true

    -- Header (clickable, full width)
    local header = CreateFrame("Button", nil, container, "BackdropTemplate")
    header:SetHeight(28)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    header:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.6)
    header:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.5)

    -- Chevron indicator
    local chevron = header:CreateFontString(nil, "OVERLAY")
    chevron:SetFont(GetFontPath(), 12, "")
    chevron:SetPoint("LEFT", 10, 0)
    chevron:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)

    -- Title text
    local titleText = header:CreateFontString(nil, "OVERLAY")
    SetFont(titleText, 12, "", C.accent)
    titleText:SetText(title or "Section")
    titleText:SetPoint("LEFT", chevron, "RIGHT", 6, 0)

    -- Optional badge (e.g., "Override" indicator)
    local badge = nil
    if badgeConfig and badgeConfig.text then
        badge = CreateFrame("Frame", nil, header, "BackdropTemplate")
        badge:SetHeight(18)
        badge:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        badge:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.2)
        badge:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)

        local badgeText = badge:CreateFontString(nil, "OVERLAY")
        badgeText:SetFont(GetFontPath(), 10, "")
        badgeText:SetText(badgeConfig.text)
        badgeText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
        badgeText:SetPoint("CENTER", 0, 0)

        -- Auto-width based on text
        local textWidth = badgeText:GetStringWidth() or 40
        badge:SetWidth(textWidth + 12)
        badge:SetPoint("RIGHT", header, "RIGHT", -10, 0)

        -- Initial visibility based on showFunc
        if badgeConfig.showFunc then
            badge:SetShown(badgeConfig.showFunc())
        end
    end

    -- Content area
    local content = CreateFrame("Frame", nil, container)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    content:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    content._hasContent = false

    -- Update function
    local function UpdateState()
        if isExpanded then
            chevron:SetText("v")  -- Down arrow
            content:Show()
            container:SetHeight(header:GetHeight() + 4 + (content:GetHeight() or 0))
        else
            chevron:SetText(">")  -- Right arrow
            content:Hide()
            container:SetHeight(header:GetHeight())
        end
    end

    -- Click handler
    header:SetScript("OnClick", function()
        isExpanded = not isExpanded
        UpdateState()
        if container.OnExpandChanged then
            container.OnExpandChanged(isExpanded)
        end
    end)

    -- Hover effects
    header:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
    end)
    header:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.5)
    end)

    -- API methods
    container.SetExpanded = function(self, expanded)
        isExpanded = expanded
        UpdateState()
    end

    container.GetExpanded = function()
        return isExpanded
    end

    container.UpdateHeight = function()
        UpdateState()
    end

    container.SetTitle = function(self, newTitle)
        titleText:SetText(newTitle)
    end

    -- Badge update method
    container.UpdateBadge = function()
        if badge and badgeConfig and badgeConfig.showFunc then
            badge:SetShown(badgeConfig.showFunc())
        end
    end

    container.content = content
    container.header = header
    container.badge = badge

    UpdateState()
    return container
end

---------------------------------------------------------------------------
-- WIDGET: COLOR PICKER
---------------------------------------------------------------------------
function GUI:CreateColorPicker(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 20)
    
    -- Color swatch button (same size as checkbox: 16x16)
    local swatch = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetPoint("LEFT", 0, 0)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Label (same font size as checkbox: 12)
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Color")
    text:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    
    container.swatch = swatch
    container.label = text
    
    local function GetColor()
        if dbTable and dbKey then
            local c = dbTable[dbKey]
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
        end
        return 1, 1, 1, 1
    end
    
    local function SetColor(r, g, b, a)
        swatch:SetBackdropColor(r, g, b, a or 1)
        if dbTable and dbKey then
            dbTable[dbKey] = {r, g, b, a or 1}
        end
        if onChange then onChange(r, g, b, a) end
    end
    
    -- Initialize color
    local r, g, b, a = GetColor()
    swatch:SetBackdropColor(r, g, b, a)
    
    container.GetColor = GetColor
    container.SetColor = SetColor
    
    -- Open color picker on click
    swatch:SetScript("OnClick", function()
        local r, g, b, a = GetColor()
        local originalA = a or 1					
        
        local info = {
            r = r,
            g = g,
            b = b,
            opacity = originalA,
            hasOpacity = true,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                SetColor(newR, newG, newB, newA)
            end,
            opacityFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                SetColor(newR, newG, newB, newA)
            end,
            cancelFunc = function(prev)
                SetColor(prev.r, prev.g, prev.b, originalA)
            end,
        }
        
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    -- Hover effect
    swatch:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
    end)
    swatch:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.4, 0.4, 0.4, 1)
    end)
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: SUB-TABS (Horizontal tabs within a page)
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- WIDGET: SUB-TABS (Horizontal top-bar style)
---------------------------------------------------------------------------
function GUI:CreateSubTabs(parent, tabs)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(35)
    container:SetPoint("TOPLEFT", 0, 0)
    container:SetPoint("TOPRIGHT", 0, 0)
    
    local tabButtons = {}
    local tabContents = {}
    local spacing = 20
    
    for i, tabInfo in ipairs(tabs) do
        -- Tab button (transparent, text only)
        local btn = CreateFrame("Button", nil, container)
        btn:SetHeight(30)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(btn.text, 12, "", C.textBright)
        btn.text:SetText(tabInfo.name)
        btn.text:SetPoint("CENTER", 0, 0)
        
        -- Auto-width based on text
        local textWidth = btn.text:GetStringWidth()
        btn:SetWidth(textWidth + 20)
        
        -- Selection Indicator (Underline)
        local underline = btn:CreateTexture(nil, "OVERLAY")
        underline:SetHeight(2)
        underline:SetPoint("BOTTOMLEFT", 0, 0)
        underline:SetPoint("BOTTOMRIGHT", 0, 0)
        underline:SetColorTexture(unpack(C.accent))
        underline:Hide()
        btn.underline = underline

        btn.index = i
        tabButtons[i] = btn
        
        -- Content frame for this tab
        local scrollframe, content = GUI:CreateScrollableContent(parent)
        scrollframe:SetPoint("TOPLEFT", 0, -40) -- Start below sub-tabs
        scrollframe:SetPoint("BOTTOMRIGHT", -5, 0)
        scrollframe:Hide()
        scrollframe:EnableMouse(false)
        scrollframe._hasContent = false
        tabContents[i] = scrollframe
        		
        if tabInfo.builder then
            tabInfo.builder(content)
        end
        
    end

    -- Layout function
    local function RelayoutSubTabs()
        local xOffset = 20
        local yOffset = -2
        -- Use parent width for accurate wrapping calculation
        local totalWidth = parent:GetWidth()
        if totalWidth == 0 or totalWidth < 100 then 
            totalWidth = GUI.CONTENT_WIDTH or 700 -- Use GUI.CONTENT_WIDTH constant
        end
        
        local rowHeight = 32
        for i, btn in ipairs(tabButtons) do
            -- Re-measure text width to ensure accuracy (handling font loading delays)
            local textWidth = btn.text:GetStringWidth()
            btn:SetWidth(textWidth + 20)

            local width = btn:GetWidth()
            
            -- Check if this button would exceed the width (with adjusted safety margin)
            -- Account for left padding (20px) + right padding (20px) + some buffer (40px)
            if xOffset + width > (totalWidth - 80) and i > 1 then
                xOffset = 20
                yOffset = yOffset - rowHeight
            end
            
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", xOffset, yOffset - 5) -- Add -5 offset from top
            xOffset = xOffset + width + spacing
        end
        
        local newHeight = math.abs(yOffset) + rowHeight + 10 -- Extra 10px buffer
        container:SetHeight(newHeight)
        
        -- Adjust contents to start below the wrapped tabs
        for i = 1, #tabContents do
            tabContents[i]:ClearAllPoints()
            tabContents[i]:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -newHeight - 10)
            tabContents[i]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 5)
        end
    end
    
    -- Listen for container size changes to re-wrap
    container:SetScript("OnSizeChanged", function()
        RelayoutSubTabs()
    end)
    RelayoutSubTabs()

    -- Tab selection function
    local function SelectSubTab(index)
        for i, btn in ipairs(tabButtons) do
            if i == index then
                -- ACTIVE
                btn.text:SetTextColor(unpack(C.accent))
                btn.underline:Show()
                tabContents[i]:Show()
            else
                -- INACTIVE
                btn.text:SetTextColor(unpack(C.textBright))
                btn.underline:Hide()
                tabContents[i]:Hide()
            end
        end
        container.selectedTab = index
    end
    
    -- Button click handlers
    for i, btn in ipairs(tabButtons) do
        
        if tabs[i].fn then
            btn:SetScript("OnClick", function() tabs[i].fn() end)
        else
            btn:SetScript("OnClick", function() SelectSubTab(i) end)
        end
        --temp solution for installer end
        btn:SetScript("OnEnter", function(self)
            if container.selectedTab ~= i then
                self.text:SetTextColor(unpack(C.textBright))
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if container.selectedTab ~= i then
                self.text:SetTextColor(unpack(C.textBright))
            end
        end)
    end
    
    container.tabButtons = tabButtons
    container.tabContents = tabContents
    container.SelectTab = SelectSubTab
    container.RelayoutSubTabs = RelayoutSubTabs

    -- Select first tab by default
    SelectSubTab(1)

    return container
end

---------------------------------------------------------------------------
-- WIDGET: DESCRIPTION TEXT
---------------------------------------------------------------------------
function GUI:CreateDescription(parent, text, color)
    local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(desc, 11, "", color or C.textMuted)
    desc:SetText(text)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    return desc
end

---------------------------------------------------------------------------
-- WIDGET: CHECKBOX
---------------------------------------------------------------------------
function GUI:CreateCheckbox(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(300, 20)
    
    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Checkmark (blue-colored using standard check but tinted)
    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check:SetPoint("CENTER", 0, 0)
    box.check:SetSize(20, 20)
    box.check:SetVertexColor(0, 0.74901960784314, 1)  -- deepbluesky
    box.check:SetDesaturated(true)  -- Remove yellow, then apply blue
    box.check:Hide()
    
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)  -- Bumped from 11 to 12
    text:SetText(label or "Option")
    text:SetPoint("LEFT", box, "RIGHT", 6, 0)
    
    container.box = box
    container.label = text
    
    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.checked
    end
    
    local function SetValue(val)
        container.checked = val
        if val then
            box.check:Show()
            box:SetBackdropBorderColor(unpack(C.accent))  -- Blue when checked
            box:SetBackdropColor(0.102, 0.165, 0.200, 1)
        else
            box.check:Hide()
            box:SetBackdropBorderColor(unpack(C.border))
            box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange then onChange(val) end
    end
    
    container.GetValue = GetValue
    container.SetValue = SetValue
    SetValue(GetValue())
    
    box:SetScript("OnClick", function() SetValue(not GetValue()) end)
    box:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover)) end)
    box:SetScript("OnLeave", function(self)
        if GetValue() then
            pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        else
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: CHECKBOX CENTERED (label centered above checkbox)
---------------------------------------------------------------------------
function GUI:CreateCheckboxCentered(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(100, 40)  -- Taller to fit label above
    
    -- Label on top, centered
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 11, "", C.accentLight)  -- Blue like slider labels
    text:SetText(label or "Option")
    text:SetPoint("TOP", container, "TOP", 0, 0)
    
    -- Checkbox box below label, centered
    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("TOP", text, "BOTTOM", 0, -4)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Checkmark
    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check:SetPoint("CENTER", 0, 0)
    box.check:SetSize(20, 20)
    box.check:SetVertexColor(0, 0.74901960784314, 1)
    box.check:SetDesaturated(true)
    box.check:Hide()
    
    container.box = box
    container.label = text
    
    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.checked
    end
    
    local function SetValue(val)
        container.checked = val
        if val then
            box.check:Show()
            box:SetBackdropBorderColor(unpack(C.accent))
            box:SetBackdropColor(0.102, 0.157, 0.200, 1)
        else
            box.check:Hide()
            box:SetBackdropBorderColor(unpack(C.border))
            box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange then onChange(val) end
    end
    
    container.GetValue = GetValue
    container.SetValue = SetValue
    SetValue(GetValue())
    
    box:SetScript("OnClick", function() SetValue(not GetValue()) end)
    box:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover)) end)
    box:SetScript("OnLeave", function(self)
        if GetValue() then
            pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        else
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: COLOR PICKER CENTERED (label centered above swatch)
---------------------------------------------------------------------------
function GUI:CreateColorPickerCentered(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(100, 40)  -- Taller to fit label above
    
    -- Label on top, centered (blue like slider labels)
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 11, "", C.accentLight)
    text:SetText(label or "Color")
    text:SetPoint("TOP", container, "TOP", 0, 0)
    
    -- Color swatch below label, centered
    local swatch = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetPoint("TOP", text, "BOTTOM", 0, -4)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    container.swatch = swatch
    container.label = text
    
    local function GetColor()
        if dbTable and dbKey then
            local c = dbTable[dbKey]
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
        end
        return 1, 1, 1, 1
    end
    
    local function SetColor(r, g, b, a)
        swatch:SetBackdropColor(r, g, b, a or 1)
        if dbTable and dbKey then
            dbTable[dbKey] = {r, g, b, a or 1}
        end
        if onChange then onChange(r, g, b, a) end
    end
    
    -- Initialize color
    local r, g, b, a = GetColor()
    swatch:SetBackdropColor(r, g, b, a)
    
    container.GetColor = GetColor
    container.SetColor = SetColor
    
    -- Open color picker on click
    swatch:SetScript("OnClick", function()
        local r, g, b, a = GetColor()
        local originalA = a or 1								
        local info = {
            hasOpacity = true,
            opacity = originalA,
            r = r, g = g, b = b,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                SetColor(newR, newG, newB, newA)
            end,
            opacityFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                SetColor(newR, newG, newB, newA)
            end,
            cancelFunc = function(prev)
                SetColor(prev.r, prev.g, prev.b, originalA)
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    
    swatch:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
    end)
    swatch:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.4, 0.4, 0.4, 1)
    end)
    
    return container
end

---------------------------------------------------------------------------
-- Inverted Checkbox: checked = false in DB, unchecked = true in DB
-- Use for "Hide X" options where DB stores "showX"
---------------------------------------------------------------------------
function GUI:CreateCheckboxInverted(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(300, 20)
    
    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check:SetPoint("CENTER", 0, 0)
    box.check:SetSize(20, 20)
    box.check:SetVertexColor(0, 0.74901960784314, 1)
    box.check:SetDesaturated(true)
    box.check:Hide()
    
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", box, "RIGHT", 6, 0)
    
    container.box = box
    container.label = text
    
    -- INVERTED: DB true = unchecked, DB false = checked
    local function GetDBValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return true
    end
    
    local function IsChecked()
        return not GetDBValue()  -- Invert for display
    end
    
    local function SetChecked(checked)
        container.checked = checked
        local dbVal = not checked  -- Invert for storage
        if checked then
            box.check:Show()
            box:SetBackdropBorderColor(unpack(C.accent))
            box:SetBackdropColor(0.102, 0.173, 0.200, 1)
        else
            box.check:Hide()
            box:SetBackdropBorderColor(unpack(C.border))
            box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
        if dbTable and dbKey then dbTable[dbKey] = dbVal end
        if onChange then onChange(dbVal) end
    end
    
    container.GetValue = IsChecked
    container.SetValue = SetChecked
    SetChecked(IsChecked())
    
    box:SetScript("OnClick", function() SetChecked(not IsChecked()) end)
    box:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover)) end)
    box:SetScript("OnLeave", function(self)
        if IsChecked() then
            pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        else
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: SLIDER (Full-width, stacks vertically like old GUI)
-- Layout: Label centered on top, slider bar below, min|editbox|max at bottom
-- Options table (optional 8th param): { deferOnDrag = true } to defer onChange until mouse release
---------------------------------------------------------------------------
function GUI:CreateSlider(parent, label, min, max, step, dbKey, dbTable, onChange, options)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(60)
    container:EnableMouse(true)  -- Block clicks from passing through to frames behind
    -- Width will be set by anchoring TOPLEFT and TOPRIGHT

    -- Parse options
    options = options or {}
    local deferOnDrag = options.deferOnDrag or false

    -- Label (top, centered, blue colored)
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 11, "", C.accentLight)
    text:SetText(label or "Setting")
    text:SetPoint("TOP", 0, 0)

    -- Track container (for the filled + unfilled portions)
    local trackContainer = CreateFrame("Frame", nil, container)
    trackContainer:SetHeight(5)  -- Reduced height from 6 to 5
    trackContainer:SetPoint("TOPLEFT", 35, -18)
    trackContainer:SetPoint("TOPRIGHT", -35, -18)

    -- Unfilled track (background)
    local trackBg = CreateFrame("Frame", nil, trackContainer, "BackdropTemplate")
    trackBg:SetAllPoints()
    trackBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    trackBg:SetBackdropColor(0.25, 0.25, 0.25, 1) -- Lighter Dark Grey (0.25)
    trackBg:SetBackdropBorderColor(0.2, 0.22, 0.25, 1)

    -- Filled track (blue portion from left to thumb)
    local trackFill = CreateFrame("Frame", nil, trackContainer, "BackdropTemplate")
    trackFill:SetPoint("TOPLEFT", 1, -1)
    trackFill:SetPoint("BOTTOMLEFT", 1, 1)
    trackFill:SetWidth(1)
    trackFill:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    trackFill:SetBackdropColor(0.7, 0.7, 0.7, 1) -- Light Grey filled track

    -- Actual slider (invisible, just for interaction)
    local slider = CreateFrame("Slider", nil, trackContainer)
    slider:SetAllPoints()
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)
    slider:SetHitRectInsets(0, 0, -10, -10)  -- Expand hit area 10px above/below for reliable hover detection

    -- Thumb frame (white circle with border)
    -- Thumb frame (Blue circle)
    local thumbFrame = CreateFrame("Frame", nil, slider)
    thumbFrame:SetSize(14, 14)
    
    local thumbTex = thumbFrame:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    
    local thumbMask = thumbFrame:CreateMaskTexture()
    thumbMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    thumbMask:SetAllPoints()
    thumbTex:AddMaskTexture(thumbMask)

    thumbFrame:SetFrameLevel(slider:GetFrameLevel() + 2)
    thumbFrame:EnableMouse(false)  -- Let clicks pass through to slider

    -- Hidden thumb texture for slider mechanics
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(14, 14)
    thumb:SetAlpha(0)

    -- Min label (left of slider)
    local minText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(minText, 10, "", C.textMuted)
    minText:SetText(tostring(min or 0))
    minText:SetPoint("RIGHT", trackContainer, "LEFT", -5, 0)

    -- Max label (right of slider)
    local maxText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(maxText, 10, "", C.textMuted)
    maxText:SetText(tostring(max or 100))
    maxText:SetPoint("LEFT", trackContainer, "RIGHT", 5, 0)

    -- Editbox for value (center, below slider)
    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetSize(70, 22)
    editBox:SetPoint("TOP", trackContainer, "BOTTOM", 0, -6)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
    editBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    editBox:SetFont(GetFontPath(), 11, "")
    editBox:SetTextColor(unpack(C.text))
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)

    -- Configure slider
    slider:SetMinMaxValues(min or 0, max or 100)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)

    container.slider = slider
    container.editBox = editBox
    container.trackFill = trackFill
    container.thumbFrame = thumbFrame
    container.trackContainer = trackContainer
    container.min = min or 0
    container.max = max or 100
    container.step = step or 1

    -- Track dragging state for deferOnDrag mode
    local isDragging = false

    -- Update filled track and thumb position
    local function UpdateTrackFill(value)
        local minVal, maxVal = container.min, container.max
        local pct = (value - minVal) / (maxVal - minVal)
        pct = math.max(0, math.min(1, pct))

        local trackWidth = trackContainer:GetWidth() - 2
        local fillWidth = math.max(1, pct * trackWidth)
        trackFill:SetWidth(fillWidth)

        local thumbX = pct * (trackWidth - 14) + 7
        thumbFrame:ClearAllPoints()
        thumbFrame:SetPoint("CENTER", trackContainer, "LEFT", thumbX + 1, 0)
    end

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] or container.min end
        return container.value or container.min
    end

    local function FormatVal(val)
        if container.step >= 1 then
            return tostring(math.floor(val))
        else
            return string.format("%.2f", val)
        end
    end

    local function SetValue(val, skipCallback)
        val = math.max(container.min, math.min(container.max, val))
        if container.step >= 1 then
            val = math.floor(val / container.step + 0.5) * container.step
        else
            local mult = 1 / container.step
            val = math.floor(val * mult + 0.5) / mult
        end

        container.value = val
        slider:SetValue(val)
        editBox:SetText(FormatVal(val))
        UpdateTrackFill(val)

        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange and not skipCallback then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue

    -- Slider drag callback
    slider:SetScript("OnValueChanged", function(self, value)
        if container.step >= 1 then
            value = math.floor(value / container.step + 0.5) * container.step
        else
            local mult = 1 / container.step
            value = math.floor(value * mult + 0.5) / mult
        end
        editBox:SetText(FormatVal(value))
        container.value = value
        UpdateTrackFill(value)
        if dbTable and dbKey then dbTable[dbKey] = value end

        -- If deferOnDrag, only call onChange when not dragging (or on release)
        if deferOnDrag then
            if not isDragging then
                if onChange then onChange(value) end
            end
        else
            if onChange then onChange(value) end
        end
    end)

    -- Track mouse down/up for deferOnDrag mode
    slider:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
        end
    end)

    slider:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and isDragging then
            isDragging = false
            if deferOnDrag and onChange then
                local value = self:GetValue()
                if container.step >= 1 then
                    value = math.floor(value / container.step + 0.5) * container.step
                else
                    local mult = 1 / container.step
                    value = math.floor(value * mult + 0.5) / mult
                end
                onChange(value)
            end
        end
    end)

    -- Hover effects
    -- Hover effects
    slider:SetScript("OnEnter", nil)
    slider:SetScript("OnLeave", nil)

    editBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then SetValue(val) end
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        editBox:SetText(FormatVal(GetValue()))
        self:ClearFocus()
    end)

    -- Hover effect on editbox
    editBox:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    end)
    editBox:SetScript("OnLeave", function(self)
        if not self:HasFocus() then
            self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end)

    -- Initialize after a brief delay to ensure width is calculated
    C_Timer.After(0, function()
        SetValue(GetValue(), true)
    end)

    return container
end

---------------------------------------------------------------------------
-- WIDGET: DROPDOWN (Matches slider width with same 35px inset, same height for alignment)
---------------------------------------------------------------------------
local CHEVRON_ZONE_WIDTH = 28
local CHEVRON_BG_ALPHA = 0.15
local CHEVRON_BG_ALPHA_HOVER = 0.25
local CHEVRON_TEXT_ALPHA = 0.7

function GUI:CreateDropdown(parent, label, options, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(60)  -- Match slider height for vertical alignment
    container:SetWidth(200)  -- Default width, can be overridden by SetWidth()

    -- Label on top (if provided) - blue green like slider labels, centered
    if label and label ~= "" then
        local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(text, 11, "", C.accentLight)  -- Blue green like other labels
        text:SetText(label)
        text:SetPoint("TOP", container, "TOP", 0, 0)  -- Centered
    end

    -- Dropdown button (same width as slider track - inset 35px on each side)
    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetHeight(24)  -- Increased from 20 for better tap target
    dropdown:SetPoint("TOPLEFT", container, "TOPLEFT", 35, -16)
    dropdown:SetPoint("RIGHT", container, "RIGHT", -35, 0)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    dropdown:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)  -- Increased from 0.25 for better visibility

    -- Chevron zone (right side with accent tint)
    local chevronZone = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    chevronZone:SetWidth(CHEVRON_ZONE_WIDTH)
    chevronZone:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -1, -1)
    chevronZone:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -1, 1)
    chevronZone:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)

    -- Separator line (left edge of chevron zone)
    local separator = chevronZone:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPLEFT", chevronZone, "TOPLEFT", 0, 0)
    separator:SetPoint("BOTTOMLEFT", chevronZone, "BOTTOMLEFT", 0, 0)
    separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)

    -- Line chevron (two angled lines forming a V pointing DOWN)
    local chevronLeft = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronLeft:SetSize(7, 2)
    chevronLeft:SetPoint("CENTER", chevronZone, "CENTER", -2, -1)
    chevronLeft:SetRotation(math.rad(-45))

    local chevronRight = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronRight:SetSize(7, 2)
    chevronRight:SetPoint("CENTER", chevronZone, "CENTER", 2, -1)
    chevronRight:SetRotation(math.rad(45))

    dropdown.chevronLeft = chevronLeft
    dropdown.chevronRight = chevronRight
    dropdown.chevronZone = chevronZone
    dropdown.separator = separator

    -- Selected text - centered, accounting for chevron zone
    dropdown.selected = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(dropdown.selected, 11, "", C.text)
    dropdown.selected:SetPoint("LEFT", 8, 0)
    dropdown.selected:SetPoint("RIGHT", chevronZone, "LEFT", -5, 0)
    dropdown.selected:SetJustifyH("CENTER")

    -- Hover effect
    dropdown:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA_HOVER)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.35, 0.35, 0.35, 1)
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    end)
    
    container.dropdown = dropdown
    
    -- Normalize options to {value, text} format
    local normalizedOptions = {}
    if type(options) == "table" then
        for i, opt in ipairs(options) do
            if type(opt) == "table" then
                normalizedOptions[i] = opt
            else
                -- Simple string array like {"Up", "Down"}
                normalizedOptions[i] = {value = opt:lower(), text = opt}
            end
        end
    end
    container.options = normalizedOptions
    
    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.value
    end
    
    local function GetDisplayText(val)
        for _, opt in ipairs(container.options) do
            if opt.value == val then return opt.text end
        end
        -- If not found, capitalize first letter
        if type(val) == "string" then
            return val:sub(1,1):upper() .. val:sub(2)
        end
        return tostring(val or "Select...")
    end
    
    local function SetValue(val, skipCallback)
        container.value = val
        dropdown.selected:SetText(GetDisplayText(val))
        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange and not skipCallback then onChange(val) end
    end
    
    container.GetValue = GetValue
    container.SetValue = SetValue
    
    -- Initialize with current value
    SetValue(GetValue(), true)
    
    -- Dropdown menu frame (created once, reused)
    local menuFrame = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menuFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menuFrame:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    menuFrame:SetBackdropBorderColor(unpack(C.accent))
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:Hide()
    
    local menuButtons = {}
    local buttonHeight = 22
    
    for i, opt in ipairs(container.options) do
        local btn = CreateFrame("Button", nil, menuFrame, "BackdropTemplate")
        btn:SetHeight(buttonHeight)
        btn:SetPoint("TOPLEFT", 2, -2 - (i-1) * buttonHeight)
        btn:SetPoint("TOPRIGHT", -2, -2 - (i-1) * buttonHeight)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(btn.text, 11, "", C.text)
        btn.text:SetText(opt.text)
        btn.text:SetPoint("LEFT", 8, 0)
        
        btn:SetScript("OnEnter", function(self)
            pcall(function()
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
                self:SetBackdropColor(0, 0.74901960784314, 1, 0.25)  -- deepbluesky at 25% opacity (ghost)
            end)
            -- Keep text white
        end)
        btn:SetScript("OnLeave", function(self)
            pcall(function()
                self:SetBackdrop(nil)
            end)
        end)
        btn:SetScript("OnClick", function()
            SetValue(opt.value)
            menuFrame:Hide()
        end)
        
        menuButtons[i] = btn
    end
    
    menuFrame:SetHeight(4 + #container.options * buttonHeight)
    
    -- Toggle menu on click
    dropdown:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
        end
    end)
    
    -- Close menu when clicking elsewhere (with delay to handle gap)
    local closeTimer = 0
    local CLOSE_DELAY = 0.15  -- 150ms grace period
    
    menuFrame:SetScript("OnShow", function()
        closeTimer = 0
        menuFrame.__checkElapsed = 0
        menuFrame:SetScript("OnUpdate", function(self, elapsed)
            -- Throttle checks to ~15 FPS (66ms) for CPU efficiency
            self.__checkElapsed = self.__checkElapsed + elapsed
            if self.__checkElapsed < 0.066 then return end
            local deltaTime = self.__checkElapsed
            self.__checkElapsed = 0

            -- Check if mouse is over dropdown button OR menu (with tolerance)
            local isOverDropdown = dropdown:IsMouseOver()
            local isOverMenu = self:IsMouseOver()

            -- Also check if mouse is in the gap between them
            local scale = dropdown:GetEffectiveScale()
            local mouseX, mouseY = GetCursorPosition()
            mouseX, mouseY = mouseX / scale, mouseY / scale

            local dLeft, dBottom, dWidth, dHeight = dropdown:GetRect()
            local mLeft, mBottom, mWidth, mHeight = self:GetRect()

            if dLeft and mLeft then
                -- Check if mouse X is within the dropdown/menu horizontal bounds
                local inHorizontalBounds = mouseX >= dLeft and mouseX <= (dLeft + dWidth)
                -- Check if mouse Y is between the bottom of dropdown and top of menu (the gap)
                local inGap = mouseY >= mBottom and mouseY <= (dBottom + dHeight) and inHorizontalBounds

                if isOverDropdown or isOverMenu or inGap then
                    closeTimer = 0
                else
                    closeTimer = closeTimer + deltaTime
                    if closeTimer > CLOSE_DELAY then
                        self:Hide()
                    end
                end
            else
                -- Fallback if GetRect fails
                if not isOverDropdown and not isOverMenu then
                    closeTimer = closeTimer + deltaTime
                    if closeTimer > CLOSE_DELAY then
                        self:Hide()
                    end
                else
                    closeTimer = 0
                end
            end
        end)
    end)
    
    menuFrame:SetScript("OnHide", function()
        menuFrame:SetScript("OnUpdate", nil)
        closeTimer = 0
    end)
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: DROPDOWN FULL WIDTH (For pages like Spec Profiles - no inset)
---------------------------------------------------------------------------
function GUI:CreateDropdownFullWidth(parent, label, options, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(45)  -- Compact height for full-width dropdowns
    container:SetWidth(200)  -- Default width, can be overridden by SetWidth()

    -- Label on top (if provided) - blue green, centered
    if label and label ~= "" then
        local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(text, 11, "", C.accentLight)
        text:SetText(label)
        text:SetPoint("TOP", container, "TOP", 0, 0)
    end

    -- Dropdown button (full width, no inset)
    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetHeight(24)
    dropdown:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -18)
    dropdown:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    dropdown:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)  -- Increased from 0.25

    -- Chevron zone (right side with accent tint)
    local chevronZone = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    chevronZone:SetWidth(CHEVRON_ZONE_WIDTH)
    chevronZone:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -1, -1)
    chevronZone:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -1, 1)
    chevronZone:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)

    -- Separator line (left edge of chevron zone)
    local separator = chevronZone:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPLEFT", chevronZone, "TOPLEFT", 0, 0)
    separator:SetPoint("BOTTOMLEFT", chevronZone, "BOTTOMLEFT", 0, 0)
    separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)

    -- Line chevron (two angled lines forming a V pointing DOWN)
    local chevronLeft = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronLeft:SetSize(7, 2)
    chevronLeft:SetPoint("CENTER", chevronZone, "CENTER", -2, -1)
    chevronLeft:SetRotation(math.rad(-45))

    local chevronRight = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronRight:SetSize(7, 2)
    chevronRight:SetPoint("CENTER", chevronZone, "CENTER", 2, -1)
    chevronRight:SetRotation(math.rad(45))

    dropdown.chevronLeft = chevronLeft
    dropdown.chevronRight = chevronRight
    dropdown.chevronZone = chevronZone
    dropdown.separator = separator

    -- Selected text - centered, accounting for chevron zone
    dropdown.selected = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(dropdown.selected, 11, "", C.text)
    dropdown.selected:SetPoint("LEFT", 10, 0)
    dropdown.selected:SetPoint("RIGHT", chevronZone, "LEFT", -5, 0)
    dropdown.selected:SetJustifyH("CENTER")

    -- Hover effect
    dropdown:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA_HOVER)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.35, 0.35, 0.35, 1)
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    end)

    container.dropdown = dropdown

    -- Normalize options
    local normalizedOptions = {}
    if type(options) == "table" then
        for i, opt in ipairs(options) do
            if type(opt) == "table" then
                normalizedOptions[i] = opt
            else
                normalizedOptions[i] = {value = opt:lower(), text = opt}
            end
        end
    end
    container.options = normalizedOptions
    
    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.value
    end
    
    local function GetDisplayText(val)
        for _, opt in ipairs(container.options) do
            if opt.value == val then return opt.text end
        end
        if type(val) == "string" then
            return val:sub(1,1):upper() .. val:sub(2)
        end
        return tostring(val or "Select...")
    end
    
    local function SetValue(val, skipCallback)
        container.value = val
        dropdown.selected:SetText(GetDisplayText(val))
        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange and not skipCallback then onChange(val) end
    end
    
    container.GetValue = GetValue
    container.SetValue = SetValue
    SetValue(GetValue(), true)
    
    -- Dropdown menu
    local menuFrame = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menuFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menuFrame:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    menuFrame:SetBackdropBorderColor(unpack(C.accent))
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:Hide()
    
    local buttonHeight = 22
    for i, opt in ipairs(container.options) do
        local btn = CreateFrame("Button", nil, menuFrame, "BackdropTemplate")
        btn:SetHeight(buttonHeight)
        btn:SetPoint("TOPLEFT", 2, -2 - (i-1) * buttonHeight)
        btn:SetPoint("TOPRIGHT", -2, -2 - (i-1) * buttonHeight)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(btn.text, 11, "", C.text)
        btn.text:SetText(opt.text)
        btn.text:SetPoint("LEFT", 8, 0)
        
        btn:SetScript("OnEnter", function(self)
            pcall(function()
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
                self:SetBackdropColor(0, 0.74901960784314, 1, 0.25)  -- Blue at 25% opacity (ghost)
            end)
            -- Keep text white
        end)
        btn:SetScript("OnLeave", function(self)
            pcall(function() self:SetBackdrop(nil) end)
        end)
        btn:SetScript("OnClick", function()
            SetValue(opt.value)
            menuFrame:Hide()
        end)
    end
    
    menuFrame:SetHeight(4 + #container.options * buttonHeight)
    
    dropdown:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
        end
    end)
    
    -- Close menu when clicking elsewhere
    local closeTimer = 0
    menuFrame:SetScript("OnShow", function()
        closeTimer = 0
        menuFrame.__checkElapsed = 0
        menuFrame:SetScript("OnUpdate", function(self, elapsed)
            -- Throttle checks to ~15 FPS (66ms) for CPU efficiency
            self.__checkElapsed = self.__checkElapsed + elapsed
            if self.__checkElapsed < 0.066 then return end
            local deltaTime = self.__checkElapsed
            self.__checkElapsed = 0

            local isOverDropdown = dropdown:IsMouseOver()
            local isOverMenu = self:IsMouseOver()
            if not isOverDropdown and not isOverMenu then
                closeTimer = closeTimer + deltaTime
                if closeTimer > 0.15 then
                    self:Hide()
                end
            else
                closeTimer = 0
            end
        end)
    end)

    menuFrame:SetScript("OnHide", function()
        menuFrame:SetScript("OnUpdate", nil)
        closeTimer = 0
    end)

    return container
end

---------------------------------------------------------------------------
-- FORM WIDGETS (Label on left, widget on right)
---------------------------------------------------------------------------

local FORM_ROW_HEIGHT = 28

---------------------------------------------------------------------------
-- WIDGET: iOS-STYLE TOGGLE SWITCH (Premium)
-- Track: 40x22px, rounded capsule
-- Thumb: 18x18px, circle
-- Smooth animation on toggle
---------------------------------------------------------------------------
local function Lerp(a, b, t)
    return a + (b - a) * t
end

function GUI:CreateFormToggle(parent, label, dbKey, dbTable, onChange, registryInfo)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)

    -- Label on left (off-white text)
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", 0, 0)

    -- Toggle track (the pill-shaped background)
    local track = CreateFrame("Button", nil, container, "BackdropTemplate")
    track:SetSize(34, 6) -- Narrower background (was 34x10)
    track:SetPoint("LEFT", container, "LEFT", 200, 0)
    track:SetHitRectInsets(0, 0, -6, -6) -- Expand click area even more since it's thinner
    
    -- Track textures
    track:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    -- Thumb (the sliding circle)
    local thumb = CreateFrame("Frame", nil, track)
    thumb:SetSize(14, 14) -- Larger than track height (sticks out top/bottom)
    
    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(1, 1, 1, 1)
    
    -- Use standard WoW circle mask
    local thumbMask = thumb:CreateMaskTexture()
    thumbMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    thumbMask:SetAllPoints()
    thumbTex:AddMaskTexture(thumbMask)

    container.track = track
    container.thumb = thumb
    container.thumbTex = thumbTex
    container.label = text

    -- State
    container.targetPos = 0 -- Target X position
    container.currentPos = 0
    container.isAnimating = false

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.checked
    end

    local function UpdateVisual(val, instant)
        -- Constant track style (does not change color)
        track:SetBackdropColor(0.25, 0.25, 0.25, 1) -- Lighter Dark Grey (0.25)
        track:SetBackdropBorderColor(0.2, 0.22, 0.25, 1) -- Subtle border (Matches Slider)

        if val then
            -- ON state: Blue Thumb
            thumbTex:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
            container.targetPos = 20 -- (TrackWidth 34 - ThumbWidth 14 = 20)
        else
            -- OFF state: Grey Thumb
            thumbTex:SetVertexColor(0.6, 0.6, 0.6, 1)
            container.targetPos = 0
        end

        if instant then
            container.currentPos = container.targetPos
            thumb:SetPoint("LEFT", track, "LEFT", container.currentPos, 0)
            container.isAnimating = false
            track:SetScript("OnUpdate", nil)
        else
            if not container.isAnimating then
                container.isAnimating = true
                track:SetScript("OnUpdate", function(self, elapsed)
                    local diff = container.targetPos - container.currentPos
                    if math.abs(diff) < 0.1 then
                        container.currentPos = container.targetPos
                        container.isAnimating = false
                        self:SetScript("OnUpdate", nil)
                    else
                        container.currentPos = Lerp(container.currentPos, container.targetPos, elapsed * 15)
                    end
                    thumb:SetPoint("LEFT", track, "LEFT", container.currentPos, 0)
                end)
            end
        end
    end

    local function SetValue(val, skipCallback)
        container.checked = val
        UpdateVisual(val, skipCallback) -- Instant on init (skipCallback=true)
        if dbTable and dbKey then dbTable[dbKey] = val end
        BroadcastToSiblings(container, val)
        if onChange and not skipCallback then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    container.UpdateVisual = UpdateVisual

    -- Register for cross-widget sync
    RegisterWidgetInstance(container, dbTable, dbKey)
    SetValue(GetValue(), true)  -- Skip callback on init

    -- Click to toggle
    track:SetScript("OnClick", function() SetValue(not GetValue()) end)

    -- Hover effects (Removed to match slider)
    track:SetScript("OnEnter", nil)
    track:SetScript("OnLeave", nil)

    -- Enable/disable the toggle (for conditional UI)
    container.SetEnabled = function(self, enabled)
        track:EnableMouse(enabled)
        -- Visual feedback: dim when disabled
        container:SetAlpha(enabled and 1 or 0.4)
    end

    -- Auto-register for search using current context
    if GUI._searchContext.tabIndex and label and not GUI._suppressSearchRegistration then
        local regKey = label .. "_" .. (GUI._searchContext.tabIndex or 0) .. "_" .. (GUI._searchContext.subTabIndex or 0)
        if not GUI.SettingsRegistryKeys[regKey] then
            GUI.SettingsRegistryKeys[regKey] = true
            table.insert(GUI.SettingsRegistry, {
                label = label,
                widgetType = "toggle",
                tabIndex = GUI._searchContext.tabIndex,
                tabName = GUI._searchContext.tabName,
                subTabIndex = GUI._searchContext.subTabIndex,
                subTabName = GUI._searchContext.subTabName,
                sectionName = GUI._searchContext.sectionName,
                widgetBuilder = function(p)
                    return GUI:CreateFormToggle(p, label, dbKey, dbTable, onChange)
                end,
            })
        end
    end

    return container
end

-- Inverted toggle: checked = DB false, unchecked = DB true (for "Hide X" options)
function GUI:CreateFormToggleInverted(parent, label, dbKey, dbTable, onChange)
    -- Reuse the main toggle logic, just wrap the getters/setters
    local container = GUI:CreateFormToggle(parent, label, nil, nil, nil) -- No DB, manual handling
    
    local function GetDBValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return true
    end

    local function IsOn()
        return not GetDBValue()  -- Invert for display
    end

    -- Override internal SetValue to handle inversion
    local originalSetValue = container.SetValue
    container.SetValue = function(isOn, skipCallback)
        local dbVal = not isOn
        if dbTable and dbKey then dbTable[dbKey] = dbVal end
        originalSetValue(isOn, true) -- Call internal update visual only
        if onChange and not skipCallback then onChange(dbVal) end
    end
    
    -- Sync initial state
    container.SetValue(IsOn(), true)
    
    -- Override click handler to use our inverted logic
    container.track:SetScript("OnClick", function() 
        container.SetValue(not IsOn()) 
    end)

    return container
end

---------------------------------------------------------------------------
-- WIDGET: FORM CHECKBOX (Now uses Toggle Switch style!)
---------------------------------------------------------------------------
function GUI:CreateFormCheckbox(parent, label, dbKey, dbTable, onChange, registryInfo)
    -- Redirect to toggle for the premium look
    return GUI:CreateFormToggle(parent, label, dbKey, dbTable, onChange, registryInfo)
end

-- Keep original checkbox available for multi-select scenarios
function GUI:CreateFormCheckboxOriginal(parent, label, dbKey, dbTable, onChange)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)

    -- Label on left (off-white text)
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", 0, 0)

    -- Checkbox aligned with other widgets (starts at 200px from left)
    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    box:SetSize(18, 18)
    box:SetPoint("LEFT", container, "LEFT", 200, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Checkmark
    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check:SetPoint("CENTER", 0, 0)
    box.check:SetSize(22, 22)
    box.check:SetVertexColor(0, 0.74901960784314, 1)
    box.check:SetDesaturated(true)
    box.check:Hide()

    container.box = box
    container.label = text

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.checked
    end

    local function UpdateVisual(val)
							   
        if val then
            box.check:Show()
            box:SetBackdropBorderColor(unpack(C.accent))
            box:SetBackdropColor(0.1, 0.2, 0.15, 1)
        else
            box.check:Hide()
            box:SetBackdropBorderColor(unpack(C.border))
            box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
    end

    local function SetValue(val, skipCallback)
        container.checked = val
        UpdateVisual(val)
        if dbTable and dbKey then dbTable[dbKey] = val end
        BroadcastToSiblings(container, val)
        if onChange and not skipCallback then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    container.UpdateVisual = UpdateVisual

    -- Register for cross-widget sync
    RegisterWidgetInstance(container, dbTable, dbKey)

    SetValue(GetValue(), true)

    box:SetScript("OnClick", function() SetValue(not GetValue()) end)
    box:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover)) end)
    box:SetScript("OnLeave", function(self)
        if GetValue() then
            pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        else
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)

    return container
end

-- Form Checkbox Inverted: checked = DB false, unchecked = DB true (for "Hide X" options)
function GUI:CreateFormCheckboxInverted(parent, label, dbKey, dbTable, onChange)
    -- Redirect to toggle inverted for the premium look
    return GUI:CreateFormToggleInverted(parent, label, dbKey, dbTable, onChange)
end

function GUI:CreateFormSlider(parent, label, min, max, step, dbKey, dbTable, onChange, options, registryInfo)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)
    container:EnableMouse(true)  -- Block clicks from passing through to frames behind

    options = options or {}
    local deferOnDrag = options.deferOnDrag or false
    local precision = options.precision
    local formatStr = precision and string.format("%%.%df", precision) or (step < 1 and "%.2f" or "%d")																							   

    -- Label on left (off-white text)
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Setting")
    text:SetPoint("LEFT", 0, 0)

    -- Track container (for the filled + unfilled portions)
    local trackContainer = CreateFrame("Frame", nil, container)
    trackContainer:SetHeight(5)  -- Thicker track (was 6, now 5)
    trackContainer:SetPoint("LEFT", container, "LEFT", 200, 0)
    trackContainer:SetPoint("RIGHT", container, "RIGHT", -70, 0)

    -- Unfilled track (background) - rounded appearance via backdrop
    local trackBg = CreateFrame("Frame", nil, trackContainer, "BackdropTemplate")
    trackBg:SetAllPoints()
    trackBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0},
    })
    trackBg:SetBackdropColor(0.25, 0.25, 0.25, 1)
    trackBg:SetBackdropBorderColor(0.2, 0.22, 0.25, 1)

    -- Filled track (blue portion from left to thumb)
    local trackFill = CreateFrame("Frame", nil, trackContainer, "BackdropTemplate")
    trackFill:SetPoint("TOPLEFT", 1, -1)
    trackFill:SetPoint("BOTTOMLEFT", 1, 1)
    trackFill:SetWidth(1)  -- Will be updated dynamically
    trackFill:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    trackFill:SetBackdropColor(0.7, 0.7, 0.7, 1) -- Light Grey filled track

    -- Actual slider (invisible, just for interaction)
    local slider = CreateFrame("Slider", nil, trackContainer)
    slider:SetAllPoints()
    slider:SetOrientation("HORIZONTAL")
    slider:SetHitRectInsets(0, 0, -10, -10)  -- Expand hit area 10px above/below for reliable hover detection

    -- Thumb frame (white circle with border)
    -- Thumb frame (Blue circle)
    local thumbFrame = CreateFrame("Frame", nil, slider)
    thumbFrame:SetSize(14, 14)
    
    local thumbTex = thumbFrame:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    
    local thumbMask = thumbFrame:CreateMaskTexture()
    thumbMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    thumbMask:SetAllPoints()
    thumbTex:AddMaskTexture(thumbMask)

    thumbFrame:SetFrameLevel(slider:GetFrameLevel() + 2)
    thumbFrame:EnableMouse(false)  -- Let clicks pass through to slider

    -- Round the thumb corners using a mask texture overlay
    local thumbRound = thumbFrame:CreateTexture(nil, "OVERLAY")
    thumbRound:SetAllPoints()
    thumbRound:SetColorTexture(1, 1, 1, 0)  -- Invisible, just for structure

    -- Use the thumb frame as the visual, position it manually
    slider.thumbFrame = thumbFrame

    -- Hidden thumb texture for slider mechanics
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(14, 14)
    thumb:SetAlpha(0)  -- Hide the actual thumb, we use thumbFrame instead

    -- Editbox for value (far right)
    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetSize(60, 22)
    editBox:SetPoint("RIGHT", 0, 0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
    editBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    editBox:SetFont(GetFontPath(), 11, "")
    editBox:SetTextColor(unpack(C.text))
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)

    -- Configure slider
    slider:SetMinMaxValues(min or 0, max or 100)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouse(true)

    container.slider = slider
    container.editBox = editBox
    container.trackFill = trackFill
    container.thumbFrame = thumbFrame
    container.trackContainer = trackContainer
    container.min = min or 0
    container.max = max or 100
    container.step = step or 1

    local isDragging = false

    -- Update filled track and thumb position
    local function UpdateTrackFill(value)
        local minVal, maxVal = container.min, container.max
        local pct = (value - minVal) / (maxVal - minVal)
        pct = math.max(0, math.min(1, pct))

        local trackWidth = trackContainer:GetWidth() - 2  -- Account for border
        local fillWidth = math.max(1, pct * trackWidth)
        trackFill:SetWidth(fillWidth)

        -- Position the thumb frame
        local thumbX = pct * (trackWidth - 14) + 7  -- Center thumb on fill edge
        thumbFrame:SetPoint("CENTER", trackContainer, "LEFT", thumbX + 1, 0)
    end

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] or container.min end
        return container.value or container.min
    end

    local function UpdateVisual(val)
        val = math.max(container.min, math.min(container.max, val))
        if not precision then
            val = math.floor(val / container.step + 0.5) * container.step
        end
        slider:SetValue(val)
        editBox:SetText(string.format(formatStr, val))
        UpdateTrackFill(val)
    end

    local function SetValue(val, skipOnChange)
        val = math.max(container.min, math.min(container.max, val))
        if precision then
            local factor = 10 ^ precision
            val = math.floor(val * factor + 0.5) / factor
        else
            val = math.floor(val / container.step + 0.5) * container.step
        end	   
        container.value = val
        UpdateVisual(val)
        if dbTable and dbKey then dbTable[dbKey] = val end
        BroadcastToSiblings(container, val)
        if not skipOnChange and onChange then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    container.UpdateVisual = UpdateVisual

    -- Register for cross-widget sync
    RegisterWidgetInstance(container, dbTable, dbKey)

    slider:SetScript("OnValueChanged", function(self, value, userInput)
        -- Ignore user input if slider is disabled
        if userInput and container.isEnabled == false then return end

        value = math.floor(value / container.step + 0.5) * container.step
        editBox:SetText(string.format(formatStr, value))
        UpdateTrackFill(value)
        if dbTable and dbKey then dbTable[dbKey] = value end
        if userInput then
            BroadcastToSiblings(container, value)
            if deferOnDrag and isDragging then return end
            if onChange then onChange(value) end
        end
    end)

    slider:SetScript("OnMouseDown", function() isDragging = true end)
    slider:SetScript("OnMouseUp", function()
        if isDragging and deferOnDrag then
            isDragging = false
            if onChange then onChange(slider:GetValue()) end
        end
        isDragging = false
    end)

    -- Hover effects on thumb
    -- Hover effects on thumb
    slider:SetScript("OnEnter", nil)
    slider:SetScript("OnLeave", nil)

    editBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or container.min
        SetValue(val)
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format(formatStr, GetValue()))
        self:ClearFocus()
    end)

    -- Hover effect on editbox
    editBox:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    end)
    editBox:SetScript("OnLeave", function(self)
        if not self:HasFocus() then
            self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end)

    -- Re-update track fill when container size changes (fixes initial layout timing)
    trackContainer:SetScript("OnSizeChanged", function(self, width, height)
        if width and width > 0 then
            UpdateTrackFill(GetValue())
        end
    end)

    -- Initialize value (visual update will happen via OnSizeChanged when layout completes)
    SetValue(GetValue(), true)

    -- Enable/disable the slider (for conditional UI)
    -- Note: Uses self parameter for colon-call syntax (widget:SetEnabled(bool))
    container.SetEnabled = function(self, enabled)
        slider:EnableMouse(enabled)
        editBox:EnableMouse(enabled)
        editBox:SetEnabled(enabled)

        -- Store state for scripts to check
        container.isEnabled = enabled

        -- Visual feedback: dim when disabled (matches HUD Visibility pattern)
        container:SetAlpha(enabled and 1 or 0.4)
    end

    -- Initialize enabled state
    container.isEnabled = true

    -- Auto-register for search using current context (if context is set)
    if GUI._searchContext.tabIndex and label and not GUI._suppressSearchRegistration then
        local regKey = label .. "_" .. (GUI._searchContext.tabIndex or 0) .. "_" .. (GUI._searchContext.subTabIndex or 0)
        if not GUI.SettingsRegistryKeys[regKey] then
            GUI.SettingsRegistryKeys[regKey] = true
            table.insert(GUI.SettingsRegistry, {
                label = label,
                widgetType = "slider",
                tabIndex = GUI._searchContext.tabIndex,
                tabName = GUI._searchContext.tabName,
                subTabIndex = GUI._searchContext.subTabIndex,
                subTabName = GUI._searchContext.subTabName,
                sectionName = GUI._searchContext.sectionName,
                widgetBuilder = function(p)
                    return GUI:CreateFormSlider(p, label, min, max, step, dbKey, dbTable, onChange, options)
                end,
            })
        end
    end

    return container
end

function GUI:CreateFormDropdown(parent, label, options, dbKey, dbTable, onChange, registryInfo)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)

    -- Label on left (off-white text)
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Setting")
    text:SetPoint("LEFT", 0, 0)

    -- Dropdown button (right side)
    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetHeight(24)  -- Increased from 22
    dropdown:SetPoint("LEFT", container, "LEFT", 200, 0)
    dropdown:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    dropdown:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)  -- Increased from 0.25

    -- Chevron zone (right side with accent tint)
    local chevronZone = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    chevronZone:SetWidth(CHEVRON_ZONE_WIDTH)
    chevronZone:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -1, -1)
    chevronZone:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -1, 1)
    chevronZone:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)

    -- Separator line (left edge of chevron zone)
    local separator = chevronZone:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPLEFT", chevronZone, "TOPLEFT", 0, 0)
    separator:SetPoint("BOTTOMLEFT", chevronZone, "BOTTOMLEFT", 0, 0)
    separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)

    -- Line chevron (two angled lines forming a V pointing DOWN)
    local chevronLeft = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronLeft:SetSize(7, 2)
    chevronLeft:SetPoint("CENTER", chevronZone, "CENTER", -2, -1)
    chevronLeft:SetRotation(math.rad(-45))

    local chevronRight = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronRight:SetSize(7, 2)
    chevronRight:SetPoint("CENTER", chevronZone, "CENTER", 2, -1)
    chevronRight:SetRotation(math.rad(45))

    dropdown.chevronLeft = chevronLeft
    dropdown.chevronRight = chevronRight
    dropdown.chevronZone = chevronZone
    dropdown.separator = separator

    -- Selected text, accounting for chevron zone
    dropdown.selected = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(dropdown.selected, 11, "", C.text)
    dropdown.selected:SetPoint("LEFT", 8, 0)
    dropdown.selected:SetPoint("RIGHT", chevronZone, "LEFT", -5, 0)
    dropdown.selected:SetJustifyH("LEFT")

    -- Hover effect
    dropdown:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA_HOVER)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.35, 0.35, 0.35, 1)
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    end)

    -- Menu frame
    local menuFrame = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menuFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menuFrame:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    menuFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    menuFrame:SetFrameStrata("TOOLTIP")									
    menuFrame:SetClipsChildren(true)
    menuFrame:Hide()

    -- Scroll frame for long option lists
    local scrollFrame = CreateFrame("ScrollFrame", nil, menuFrame)
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    scrollFrame:EnableMouseWheel(true)

    -- Scroll content (child frame)
    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(menuFrame:GetWidth() or 200)
    scrollFrame:SetScrollChild(scrollContent)
    menuFrame.scrollContent = scrollContent

    -- Mouse wheel scrolling
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentScroll = self:GetVerticalScroll()
        local maxScroll = math.max(0, scrollContent:GetHeight() - menuFrame:GetHeight())
        local newScroll = currentScroll - (delta * 20)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

    -- Update scroll content width when menu opens
    menuFrame:SetScript("OnShow", function(self)
        scrollContent:SetWidth(self:GetWidth() - 2)
    end)

    container.dropdown = dropdown
    container.menuFrame = menuFrame
    container.options = options or {}

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.selectedValue
    end

    local function UpdateVisual(val)													  
        for _, opt in ipairs(container.options) do
            if opt.value == val then
                dropdown.selected:SetText(opt.text)
                break
            end
        end
    end

    local function SetValue(val, skipOnChange)
        container.selectedValue = val
        if dbTable and dbKey then dbTable[dbKey] = val end
        UpdateVisual(val)
        BroadcastToSiblings(container, val)
        if not skipOnChange and onChange then onChange(val) end
    end

    local function BuildMenu()						 
        -- Clear existing children from scroll content
        local scrollContent = menuFrame.scrollContent
        if scrollContent then
            for _, child in ipairs({scrollContent:GetChildren()}) do child:Hide() end
        end

        local yOff = -4
        local itemHeight = 20
        local maxVisibleItems = 8
        local numItems = #container.options

        for i, opt in ipairs(container.options) do
            local btn = CreateFrame("Button", nil, scrollContent or menuFrame)
            btn:SetHeight(itemHeight)
            btn:SetPoint("TOPLEFT", 4, yOff)
            btn:SetPoint("TOPRIGHT", -4, yOff)
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            SetFont(btnText, 11, "", C.text)
            btnText:SetText(opt.text)
            btnText:SetPoint("LEFT", 4, 0)
            btn:SetScript("OnClick", function()
                SetValue(opt.value)
                menuFrame:Hide()
            end)
            btn:SetScript("OnEnter", function() btnText:SetTextColor(unpack(C.accent)) end)
            btn:SetScript("OnLeave", function() btnText:SetTextColor(unpack(C.text)) end)
            yOff = yOff - itemHeight
        end

        local totalHeight = math.abs(yOff) + 4
        local maxHeight = (maxVisibleItems * itemHeight) + 8

        -- Update scroll content height
        if scrollContent then
            scrollContent:SetHeight(totalHeight)
        end

        -- Set menu height (capped at maxHeight)
        menuFrame:SetHeight(math.min(totalHeight, maxHeight))							 
    end

    dropdown:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            BuildMenu()
            menuFrame:Show()
        end
    end)

    local function SetOptions(newOptions)
        container.options = newOptions or {}
        -- Check if current value still exists in new options
        local currentVal = GetValue()
        local found = false
        for _, opt in ipairs(container.options) do
            if opt.value == currentVal then
                dropdown.selected:SetText(opt.text)
                found = true
                break
            end
        end
        if not found then
            dropdown.selected:SetText("")
            container.selectedValue = nil
            if dbTable and dbKey then dbTable[dbKey] = "" end
        end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    container.SetOptions = SetOptions
    container.UpdateVisual = UpdateVisual

    -- Register for cross-widget sync
    RegisterWidgetInstance(container, dbTable, dbKey)
    SetValue(GetValue(), true)

    -- Enable/disable the dropdown (for conditional UI)
    container.SetEnabled = function(self, enabled)
        dropdown:EnableMouse(enabled)
        container.isEnabled = enabled
        container:SetAlpha(enabled and 1 or 0.4)
    end
    container.isEnabled = true

    -- Auto-register for search using current context (if context is set)
    if GUI._searchContext.tabIndex and label and not GUI._suppressSearchRegistration then
        local regKey = label .. "_" .. (GUI._searchContext.tabIndex or 0) .. "_" .. (GUI._searchContext.subTabIndex or 0)
        if not GUI.SettingsRegistryKeys[regKey] then
            GUI.SettingsRegistryKeys[regKey] = true
            table.insert(GUI.SettingsRegistry, {
                label = label,
                widgetType = "dropdown",
                tabIndex = GUI._searchContext.tabIndex,
                tabName = GUI._searchContext.tabName,
                subTabIndex = GUI._searchContext.subTabIndex,
                subTabName = GUI._searchContext.subTabName,
                sectionName = GUI._searchContext.sectionName,
                widgetBuilder = function(p)
                    return GUI:CreateFormDropdown(p, label, options, dbKey, dbTable, onChange)
                end,
            })
        end
    end

    return container
end

function GUI:CreateFormColorPicker(parent, label, dbKey, dbTable, onChange, options)
    options = options or {}
    local noAlpha = options.noAlpha or false

    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)

    -- Label on left (off-white text)
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Color")
    text:SetPoint("LEFT", 0, 0)

    -- Color swatch aligned with other widgets (starts at 200px from left)
    local swatch = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatch:SetSize(50, 18)
    swatch:SetPoint("LEFT", container, "LEFT", 200, 0)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    container.swatch = swatch
    container.label = text

    local function GetColor()
        if dbTable and dbKey then
            local c = dbTable[dbKey]
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
        end
        return 1, 1, 1, 1
    end

    local function SetColor(r, g, b, a)
        local finalAlpha = noAlpha and 1 or (a or 1)
        swatch:SetBackdropColor(r, g, b, finalAlpha)
        if dbTable and dbKey then
            dbTable[dbKey] = {r, g, b, finalAlpha}
        end
        if onChange then onChange(r, g, b, finalAlpha) end
    end

    container.GetColor = GetColor
    container.SetColor = SetColor

    local r, g, b, a = GetColor()
    swatch:SetBackdropColor(r, g, b, a)

    swatch:SetScript("OnClick", function()
        local currentR, currentG, currentB, currentA = GetColor()
        local originalA = currentA					  
        ColorPickerFrame:SetupColorPickerAndShow({
            r = currentR, g = currentG, b = currentB, opacity = currentA,
            hasOpacity = not noAlpha,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = noAlpha and 1 or ColorPickerFrame:GetColorAlpha()
                SetColor(r, g, b, a)
            end,
            cancelFunc = function(prev)
                SetColor(prev.r, prev.g, prev.b, noAlpha and 1 or originalA)
            end,
        })
    end)

    swatch:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accent)) end)
    swatch:SetScript("OnLeave", function(self) pcall(self.SetBackdropBorderColor, self, 0.4, 0.4, 0.4, 1) end)

    -- Enable/disable (for conditional UI)
    container.SetEnabled = function(self, enabled)
        swatch:EnableMouse(enabled)
        container:SetAlpha(enabled and 1 or 0.4)
    end

    -- Auto-register for search using current context (if context is set)
    if GUI._searchContext.tabIndex and label and not GUI._suppressSearchRegistration then
        local regKey = label .. "_" .. (GUI._searchContext.tabIndex or 0) .. "_" .. (GUI._searchContext.subTabIndex or 0)
        if not GUI.SettingsRegistryKeys[regKey] then
            GUI.SettingsRegistryKeys[regKey] = true
            table.insert(GUI.SettingsRegistry, {
                label = label,
                widgetType = "colorpicker",
                tabIndex = GUI._searchContext.tabIndex,
                tabName = GUI._searchContext.tabName,
                subTabIndex = GUI._searchContext.subTabIndex,
                subTabName = GUI._searchContext.subTabName,
                sectionName = GUI._searchContext.sectionName,
                widgetBuilder = function(p)
                    return GUI:CreateFormColorPicker(p, label, dbKey, dbTable, onChange, options)
                end,
            })
        end
    end

    return container
end

---------------------------------------------------------------------------
-- SEARCH FUNCTIONALITY
---------------------------------------------------------------------------
local SEARCH_DEBOUNCE = 0.15  -- 150ms debounce
local SEARCH_MIN_CHARS = 2    -- Minimum characters before searching
local SEARCH_MAX_RESULTS = 30 -- Cap results to prevent UI overload

-- Search timer reference (for cleanup)
GUI._searchTimer = nil

-- Create the search box widget for the top bar
function GUI:CreateSearchBox(parent)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(160, 20)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    container:SetBackdropBorderColor(0.25, 0.28, 0.32, 1)

    -- Search icon (magnifying glass character)
    local icon = container:CreateFontString(nil, "OVERLAY")
    SetFont(icon, 11, "", C.textMuted)
    icon:SetText("|TInterface\\Common\\UI-Searchbox-Icon:12:12:0:0|t")
    icon:SetPoint("LEFT", 6, 0)

    -- EditBox for search input
    local editBox = CreateFrame("EditBox", nil, container)
    editBox:SetPoint("LEFT", 24, 0)
    editBox:SetPoint("RIGHT", container, "RIGHT", -24, 0)
    editBox:SetHeight(16)
    editBox:SetAutoFocus(false)
    editBox:SetFont(GetFontPath(), 11, "")
    editBox:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    editBox:SetMaxLetters(50)

    -- Placeholder text
    local placeholder = editBox:CreateFontString(nil, "OVERLAY")
    SetFont(placeholder, 11, "", {C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.6})
    placeholder:SetText("Search settings...")
    placeholder:SetPoint("LEFT", 0, 0)

    -- Clear button (X)
    local clearBtn = CreateFrame("Button", nil, container)
    clearBtn:SetSize(14, 14)
    clearBtn:SetPoint("RIGHT", -4, 0)
    clearBtn:Hide()

    local clearText = clearBtn:CreateFontString(nil, "OVERLAY")
    SetFont(clearText, 12, "", C.textMuted)
    clearText:SetText("x")
    clearText:SetPoint("CENTER", 0, 0)

    clearBtn:SetScript("OnEnter", function()
        clearText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    end)
    clearBtn:SetScript("OnLeave", function()
        clearText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
    end)
    clearBtn:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:ClearFocus()
        -- OnTextChanged handler will trigger result clearing
    end)

    -- Text changed handler with debounce
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end

        local text = self:GetText()

        -- Show/hide placeholder and clear button
        placeholder:SetShown(text == "")
        clearBtn:SetShown(text ~= "")

        -- Cancel pending search timer
        if GUI._searchTimer then
            GUI._searchTimer:Cancel()
            GUI._searchTimer = nil
        end

        -- Debounce search execution (handled by parent via onSearch callback)
        if text:len() >= SEARCH_MIN_CHARS then
            GUI._searchTimer = C_Timer.NewTimer(SEARCH_DEBOUNCE, function()
                if container.onSearch then
                    container.onSearch(text)
                end
            end)
        elseif text == "" then
            if container.onClear then
                container.onClear()
            end
        end
    end)

    -- Focus effects
    editBox:SetScript("OnEditFocusGained", function()
        container:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusLost", function()
        container:SetBackdropBorderColor(0.25, 0.28, 0.32, 1)
    end)

    -- ESC clears search
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        if container.onClear then
            container.onClear()
        end
    end)

    -- Enter also clears focus (search already happened via debounce)
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    container.editBox = editBox
    container.placeholder = placeholder
    container.clearBtn = clearBtn

    return container
end

-- Execute search against the settings registry (returns filtered results)
function GUI:ExecuteSearch(searchTerm)
    if not searchTerm or searchTerm:len() < SEARCH_MIN_CHARS then
        return {}
    end

    local results = {}
    local lowerSearch = searchTerm:lower()

    for _, entry in ipairs(self.SettingsRegistry) do
        local score = 0

        -- Label match (highest priority)
        local lowerLabel = (entry.label or ""):lower()
        if lowerLabel:find(lowerSearch, 1, true) then
            score = 100
            -- Bonus for starts-with match
            if lowerLabel:sub(1, lowerSearch:len()) == lowerSearch then
                score = score + 50
            end
        end

        -- Keyword match (secondary)
        if score == 0 and entry.keywords then
            for _, keyword in ipairs(entry.keywords) do
                if keyword:lower():find(lowerSearch, 1, true) then
                    score = 50
                    break
                end
            end
        end

        -- Section name matching removed - causes too many false positives

        if score > 0 then
            table.insert(results, {data = entry, score = score})
        end
    end

    -- Sort by score (highest first), then alphabetically
    table.sort(results, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end
        return (a.data.label or "") < (b.data.label or "")
    end)

    -- Limit results
    if #results > SEARCH_MAX_RESULTS then
        for i = SEARCH_MAX_RESULTS + 1, #results do
            results[i] = nil
        end
    end

    return results
end

-- Render search results into a content frame (for Search tab)
function GUI:RenderSearchResults(content, results, searchTerm)
    if not content then return end

    -- Clear previous child frames (unregister from widget sync first)
    for _, child in ipairs({content:GetChildren()}) do
        UnregisterWidgetInstance(child)		   
        child:Hide()
        child:SetParent(nil)
    end

    -- Clear previous font strings
    if content._fontStrings then
        for _, fs in ipairs(content._fontStrings) do
            fs:Hide()
            fs:SetText("")
        end
    end
    content._fontStrings = {}

    -- Clear previous textures
    if content._textures then
        for _, tex in ipairs(content._textures) do
            tex:Hide()
        end
    end
    content._textures = {}

    local y = -10
    local PADDING = 15
    local FORM_ROW = 32

    -- No results message
    if not results or #results == 0 then
        if searchTerm and searchTerm ~= "" then
            local noResults = content:CreateFontString(nil, "OVERLAY")
            SetFont(noResults, 12, "", C.textMuted)
            noResults:SetText("No settings found for \"" .. searchTerm .. "\"")
            noResults:SetPoint("TOPLEFT", PADDING, y)
            table.insert(content._fontStrings, noResults)
            y = y - 30

            local tip = content:CreateFontString(nil, "OVERLAY")
            SetFont(tip, 10, "", {C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.7})
            tip:SetText("Try different keywords, or visit other tabs first to index their settings")
            tip:SetPoint("TOPLEFT", PADDING, y)
            table.insert(content._fontStrings, tip)
            y = y - 30
        else
            -- Empty state - show instructions
            local instructions = content:CreateFontString(nil, "OVERLAY")
            SetFont(instructions, 12, "", C.textMuted)
            instructions:SetText("Type at least 2 characters to search settings")
            instructions:SetPoint("TOPLEFT", PADDING, y)
            table.insert(content._fontStrings, instructions)
            y = y - 30

            local tip2 = content:CreateFontString(nil, "OVERLAY")
            SetFont(tip2, 10, "", {C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.7})
            tip2:SetText("Settings are indexed when you visit each tab")
            tip2:SetPoint("TOPLEFT", PADDING, y)
            table.insert(content._fontStrings, tip2)
            y = y - 20
        end

        content:SetHeight(math.abs(y) + 20)
        return
    end

    -- Group results by tab
    local groupedResults = {}
    local tabOrder = {}

    for _, result in ipairs(results) do
        local tabName = result.data.tabName or "Other"
        if not groupedResults[tabName] then
            groupedResults[tabName] = {}
            table.insert(tabOrder, tabName)
        end
        table.insert(groupedResults[tabName], result)
    end

    -- Suppress auto-registration while creating search result widgets
    GUI._suppressSearchRegistration = true

    -- Render grouped results with actual widgets
    for _, tabName in ipairs(tabOrder) do
        local group = groupedResults[tabName]

        -- Tab header
        local header = content:CreateFontString(nil, "OVERLAY")
        SetFont(header, 12, "", C.accentLight)
        header:SetText(tabName)
        header:SetPoint("TOPLEFT", PADDING, y)
        table.insert(content._fontStrings, header)
        y = y - 24

        -- Separator line under header
        local sep = content:CreateTexture(nil, "ARTWORK")
        sep:SetPoint("TOPLEFT", PADDING, y + 2)
        sep:SetSize(content:GetWidth() - (PADDING * 2), 1)
        sep:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        table.insert(content._textures, sep)
        y = y - 12

        -- Results in this group - create actual widgets
        for _, result in ipairs(group) do
            local entry = result.data

            if entry.widgetBuilder then
                local widget = entry.widgetBuilder(content)
                if widget then
                    widget:SetPoint("TOPLEFT", PADDING, y)
                    widget:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
                    y = y - FORM_ROW
                end
            else
                -- Fallback: show label if no builder
                local fallbackLabel = content:CreateFontString(nil, "OVERLAY")
                SetFont(fallbackLabel, 11, "", C.textMuted)
                fallbackLabel:SetText(entry.label or "Unknown setting")
                fallbackLabel:SetPoint("TOPLEFT", PADDING, y)
                table.insert(content._fontStrings, fallbackLabel)
                y = y - 24
            end
        end

        y = y - 10  -- Gap between groups
    end

    -- Re-enable auto-registration
    GUI._suppressSearchRegistration = false

    content:SetHeight(math.abs(y) + 20)
end

-- Clear search results display
function GUI:ClearSearchInTab(content)
    self:RenderSearchResults(content, nil, nil)
end

---------------------------------------------------------------------------
-- MAIN OPTIONS FRAME
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- MAIN OPTIONS FRAME
---------------------------------------------------------------------------
function GUI:CreateMainFrame()
    if self.MainFrame then
        return self.MainFrame
    end
    
    local SIDEBAR_WIDTH = 200
    local FRAME_WIDTH = 950        -- Wider default to accommodate sidebar
    local FRAME_HEIGHT = 850
    local RESIZE_HANDLE_SIZE = 20
    
    -- Load saved width/height
    local savedWidth = gui.guiCore and gui.guiCore.db and gui.guiCore.db.profile.configPanelWidth or FRAME_WIDTH
    local savedHeight = gui.guiCore and gui.guiCore.db and gui.guiCore.db.profile.configPanelHeight or FRAME_HEIGHT

    local frame = CreateFrame("Frame", "GravityUI_Options", UIParent, "BackdropTemplate")
    frame:SetSize(savedWidth, savedHeight)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    
    -- Main Backdrop (Deep Cool Grey)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    local savedAlpha = gui.guiCore and gui.guiCore.db and gui.guiCore.db.profile.configPanelAlpha or 0.95
    frame:SetBackdropColor(unpack(C.bg))
    frame:SetBackdropBorderColor(unpack(C.border))
    frame:SetResizable(true) -- Enable resizing

    self.MainFrame = frame
    
    -- Title Bar (Top area of sidebar only, drag handle for whole frame)
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetHeight(60)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    
    ---------------------------------------------------------------------------
    -- SIDEBAR (Left side)
    ---------------------------------------------------------------------------
    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", 0, 0)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,  -- Right border only via separator
    })
    sidebar:SetBackdropColor(unpack(C.bgLight))
    sidebar:SetBackdropBorderColor(0,0,0,0)
    
    -- Sidebar Right Border
    local sidebarBorder = sidebar:CreateTexture(nil, "ARTWORK")
    sidebarBorder:SetWidth(1)
    sidebarBorder:SetPoint("TOPRIGHT", 0, 0)
    sidebarBorder:SetPoint("BOTTOMRIGHT", 0, 0)
    sidebarBorder:SetColorTexture(unpack(C.border))
    
    -- Logo
    local logo = sidebar:CreateTexture(nil, "OVERLAY")
    logo:SetSize(32, 32)
    logo:SetPoint("TOPLEFT", 20, -14)
    logo:SetTexture("Interface\\AddOns\\GravityUI\\assets\\GRAVITY_UI_Icon.blp")
    
    -- Title Text
    local title = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    SetFont(title, 16, "OUTLINE", C.accent)
    title:SetText("GravityUI")
    title:SetPoint("LEFT", logo, "RIGHT", 10, 0)

    -- Version (Sidebar, under title)
    local version = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(version, 11, "", C.textMuted)
    local versionText = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unknown"
    version:SetText("" .. versionText)
    version:SetPoint("TOPLEFT", title, "BOTTOMRIGHT", -29, -8)
    
    ---------------------------------------------------------------------------
    -- CONTENT AREA (Right side)
    ---------------------------------------------------------------------------
    local contentArea = CreateFrame("Frame", nil, frame)
    contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    contentArea:SetPoint("BOTTOMRIGHT", 0, 0)
    
    -- Top Bar (Breadcrumbs / Search / Close)
    local topBar = CreateFrame("Frame", nil, contentArea)
    topBar:SetHeight(50)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)
    
    -- Close Button (Top Right)
    local close = CreateFrame("Button", nil, topBar)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -10, -10)
    
    -- Normal texture
    local closeTexNormal = close:CreateTexture(nil, "ARTWORK")
    closeTexNormal:SetAllPoints()
    closeTexNormal:SetTexture("Interface\\AddOns\\GravityUI\\assets\\iconskin\\close.tga")
    close:SetNormalTexture(closeTexNormal)
    
    -- Highlight texture (lighter on hover)
    local closeTexHighlight = close:CreateTexture(nil, "HIGHLIGHT")
    closeTexHighlight:SetAllPoints()
    closeTexHighlight:SetTexture("Interface\\AddOns\\GravityUI\\assets\\iconskin\\close.tga")
    closeTexHighlight:SetVertexColor(1.2, 1.2, 1.2, 1)
    close:SetHighlightTexture(closeTexHighlight)
    
    -- Pushed texture (darker when clicked)
    local closeTexPushed = close:CreateTexture(nil, "ARTWORK")
    closeTexPushed:SetAllPoints()
    closeTexPushed:SetTexture("Interface\\AddOns\\GravityUI\\assets\\iconskin\\close.tga")
    closeTexPushed:SetVertexColor(0.8, 0.8, 0.8, 1)
    close:SetPushedTexture(closeTexPushed)
    
    close:SetScript("OnClick", function() frame:Hide() end)
    
    -- Global Search Box (Top Right)
    local searchBox = self:CreateSearchBox(topBar)
    searchBox:SetPoint("TOPRIGHT", -45, -10)
    frame.globalSearchBox = searchBox


    
    -- Panel Scale Control (Top Left)
    local scaleFrame = CreateFrame("Frame", nil, topBar)
    scaleFrame:SetSize(140, 24)
    scaleFrame:SetPoint("TOPLEFT", 20, -10)
    
    local scaleLabel = scaleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(scaleLabel, 10, "", C.textMuted)
    scaleLabel:SetText("Panel Scale")
    scaleLabel:SetPoint("LEFT", 0, 0)
    
    -- Manual Input Box (re-anchored to label)
    local ebBg = CreateFrame("Frame", nil, scaleFrame, "BackdropTemplate")
    ebBg:SetSize(40, 18)
    ebBg:SetPoint("LEFT", scaleLabel, "RIGHT", 8, 0)
    ebBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    ebBg:SetBackdropColor(0, 0, 0, 0.5)
    ebBg:SetBackdropBorderColor(unpack(C.border))

    local eb = CreateFrame("EditBox", nil, ebBg)
    eb:SetAllPoints()
    eb:SetFont(GUI.FONT_PATH, 10, "")
    eb:SetJustifyH("CENTER")
    eb:SetTextInsets(2, 2, 0, 0)
    eb:SetAutoFocus(false)
    eb:SetNumeric(false) -- Allow decimals

    -- Scale logic
    local function ApplyScale(val, skipEb)
        val = tonumber(string.format("%.2f", val))
        if val < 0.8 then val = 0.8 elseif val > 1.5 then val = 1.5 end
        
        frame:SetScale(val)
        if not skipEb then eb:SetText(string.format("%.2f", val)) end
        
        if gui.guiCore and gui.guiCore.db then
            gui.guiCore.db.profile.configPanelScale = val
        end
    end

    eb:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then
            ApplyScale(val)
        end
        self:ClearFocus()
    end)

    eb:SetScript("OnEscapePressed", function(self)
        local current = frame:GetScale()
        self:SetText(string.format("%.2f", current))
        self:ClearFocus()
    end)
    
    -- Init Scale
    local initialScale = gui.guiCore and gui.guiCore.db and gui.guiCore.db.profile.configPanelScale or 1.0
    eb:SetText(string.format("%.2f", initialScale))
    frame:SetScale(initialScale)
    
    -- Separator below top bar
    local topSep = topBar:CreateTexture(nil, "ARTWORK")
    topSep:SetHeight(1)
    topSep:SetPoint("BOTTOMLEFT", 20, 0)
    topSep:SetPoint("BOTTOMRIGHT", -20, 0)
    topSep:SetColorTexture(unpack(C.border))
    
    -- Assign areas
    frame.sidebar = sidebar
    frame.contentArea = contentArea
    frame.topBar = topBar
    
    -- Tab Container (Inside Sidebar - Scrollable)
    local tabScroll = CreateFrame("ScrollFrame", "GravityUI_SidebarScroll", sidebar, "UIPanelScrollFrameTemplate")
    tabScroll:SetPoint("TOPLEFT", 0, -80)
    tabScroll:SetPoint("BOTTOMRIGHT", 0, 10) -- Use full width
    
    -- Hide the scrollbar entirely
    local sb = tabScroll.ScrollBar
    sb:Hide()
    sb:SetWidth(0.1) -- Minimal width
    
    -- Hide arrows
    if sb.ScrollUpButton then sb.ScrollUpButton:Hide() end
    if sb.ScrollDownButton then sb.ScrollDownButton:Hide() end
    
    -- Disable mouse wheel on scrollbar if any
    sb:EnableMouse(false)
    sb:EnableMouseWheel(false)

    local tabContainer = CreateFrame("Frame", nil, tabScroll)
    tabContainer:SetSize(SIDEBAR_WIDTH, 1)
    tabScroll:SetScrollChild(tabContainer)
    frame.tabContainer = tabContainer
    
    frame.tabs = {}
    frame.pages = {}
    frame.activeTab = nil
    
    ---------------------------------------------------------------------------
    -- RESIZE HANDLE & PANEL SCALE (Bottom-right)
    ---------------------------------------------------------------------------
    local MIN_WIDTH = 650
    local MIN_HEIGHT = 650
    local MAX_WIDTH = 1200
    local MAX_HEIGHT = 1200
    
    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(20, 20)
    resizeHandle:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 20)
    
    -- Grip Texture
    local grip = resizeHandle:CreateTexture(nil, "OVERLAY")
    grip:SetAllPoints()
    grip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetVertexColor(unpack(C.accent))
    
    -- Resizing Logic (Robust manual delta tracking)
    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local startX, startY = GetCursorPosition()
            local startW, startH = frame:GetSize()
            local scale = frame:GetEffectiveScale()
            
            self:SetScript("OnUpdate", function()
                local curX, curY = GetCursorPosition()
                local deltaX = (curX - startX) / scale
                local deltaY = (startY - curY) / scale
                
                local newW = math.max(MIN_WIDTH, math.min(MAX_WIDTH, startW + deltaX))
                local newH = math.max(MIN_HEIGHT, math.min(MAX_HEIGHT, startH + deltaY))
                
                frame:SetSize(newW, newH)
            end)
        end
    end)
    
    resizeHandle:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
        -- Save Dimensions
        if gui.guiCore and gui.guiCore.db then
            gui.guiCore.db.profile.configPanelWidth = frame:GetWidth()
            gui.guiCore.db.profile.configPanelHeight = frame:GetHeight()
        end
    end)
    resizeHandle:SetScript("OnEnter", function() grip:SetVertexColor(unpack(C.accentHover)) end)
    resizeHandle:SetScript("OnLeave", function() grip:SetVertexColor(unpack(C.accent)) end)
    
    return frame
end

---------------------------------------------------------------------------
-- ADD TAB (Clean style - no left bar, blue text when active)
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- ADD TAB (Sidebar Button Style)
---------------------------------------------------------------------------
function GUI:AddTab(frame, name, pageCreateFunc, iconTexture)
    local index = #frame.tabs + 1
    local BUTTON_HEIGHT = 32
    local PADDING = 1
    
    local y = -(index - 1) * (BUTTON_HEIGHT + PADDING)
    
    -- Create tab button
    local tab = CreateFrame("Button", nil, frame.tabContainer, "BackdropTemplate")
    tab:SetSize(frame.tabContainer:GetWidth(), BUTTON_HEIGHT)
    tab:SetPoint("TOPLEFT", frame.tabContainer, "TOPLEFT", 0, y)
    
    -- Styling: Transparent default, lighter on hover/select
    tab:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    tab:SetBackdropColor(unpack(C.tabNormal))
    
    -- Selection Indicator (Left Border Stripe)
    local indicator = tab:CreateTexture(nil, "OVERLAY")
    indicator:SetWidth(4)
    indicator:SetPoint("TOPLEFT", 0, 0)
    indicator:SetPoint("BOTTOMLEFT", 0, 0)
    indicator:SetColorTexture(unpack(C.accent))
    indicator:Hide()
    tab.indicator = indicator
    
    -- Selection Indicator (Right Border Stripe)
    local rightIndicator = tab:CreateTexture(nil, "OVERLAY")
    rightIndicator:SetWidth(4)
    rightIndicator:SetPoint("TOPRIGHT", 0, 0)
    rightIndicator:SetPoint("BOTTOMRIGHT", 0, 0)
    rightIndicator:SetColorTexture(unpack(C.accent))
    rightIndicator:Hide()
    tab.rightIndicator = rightIndicator
    
    tab.index = index
    tab.name = name
    
    -- Tab Icon (Optional)
    if iconTexture then
        local icon = tab:CreateTexture(nil, "OVERLAY")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", 15, 0)
        icon:SetTexture(iconTexture)
        icon:SetVertexColor(unpack(C.textMuted))
        tab.icon = icon
    end
    
    -- Tab text - Left aligned
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(tab.text, 12, "", C.textBright)
    tab.text:SetText(name)
    if iconTexture then
        tab.text:SetPoint("LEFT", 45, 0)
    else
        tab.text:SetPoint("LEFT", 20, 0)
    end
    tab.text:SetJustifyH("LEFT")
    
    frame.tabs[index] = tab
    frame.pages[index] = {
        createFunc = pageCreateFunc,
        frame = nil
    }
    
    -- Click handler
    tab:SetScript("OnClick", function()
        GUI:SelectTab(frame, index)
    end)
    
    tab:SetScript("OnEnter", function(self)
        if frame.activeTab ~= self.index then
            self.text:SetTextColor(unpack(C.textBright))
            self:SetBackdropColor(unpack(C.tabHover))
            if self.icon then self.icon:SetVertexColor(unpack(C.textBright)) end
        end
    end)
    
    tab:SetScript("OnLeave", function(self)
        if frame.activeTab ~= self.index then
            self.text:SetTextColor(unpack(C.textBright))
            self:SetBackdropColor(unpack(C.tabNormal))
            if self.icon then self.icon:SetVertexColor(unpack(C.textMuted)) end
        end
    end)
    
    -- Select first tab by default
    if index == 1 then
        GUI:SelectTab(frame, 1)
    end
    
    frame.tabContainer:SetHeight(math.abs(y) + BUTTON_HEIGHT)
    
    return tab
end

---------------------------------------------------------------------------
-- ADD ACTION BUTTON (Special button that executes action instead of opening page)
-- Styled like "CREATE" button - dark bg with thick blue border, centered text
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- ADD ACTION BUTTON (Vertical Sidebar Style)
---------------------------------------------------------------------------
function GUI:AddActionButton(frame, name, onClick, accentColor)
    local index = #frame.tabs + 1
    local BUTTON_HEIGHT = 32
    local PADDING = 1
    
    local y = -(index - 1) * (BUTTON_HEIGHT + PADDING)
    
    -- Create action button
    local btn = CreateFrame("Button", nil, frame.tabContainer, "BackdropTemplate")
    btn:SetSize(frame.tabContainer:GetWidth(), BUTTON_HEIGHT)
    btn:SetPoint("TOPLEFT", frame.tabContainer, "TOPLEFT", 0, y)
    
    -- Darker background with subtle border
    local bgColor = {0, 0, 0, 0}
    local borderColor = C.accent
    
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(bgColor))
    btn:SetBackdropBorderColor(0,0,0,0) -- Invisible border by default
    
    btn.index = index
    btn.name = name
    btn.isActionButton = true
    
    -- Pfeil-Text (statt Icon-Textur)
        local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(arrow, 12, "") -- Gleiche Schriftart/Größe wie beim Button-Text
        arrow:SetText(">>")
        arrow:SetPoint("LEFT", btn, "LEFT", 20, 0)
        arrow:SetTextColor(unpack(C.accentHover))
        btn.icon = arrow -- Wir nennen es intern weiter "icon", damit deine Scripte unten funktionieren

        -- Button text (Der Name)
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(btn.text, 12, "", C.textBright)
        btn.text:SetText(name)
        btn.text:SetPoint("LEFT", 45, 0)
        btn.text:SetJustifyH("LEFT")
    
    -- Store in tabs array
    frame.tabs[index] = btn
    frame.pages[index] = nil
    
    -- Click handler
    btn:SetScript("OnClick", function()
        if onClick then
            onClick()
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(C.tabHover))
        self.text:SetTextColor(unpack(C.accentHover))
        self.icon:SetVertexColor(unpack(C.accentHover))
        self.icon:SetAlpha(1)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(bgColor))
        self.text:SetTextColor(unpack(C.textBright))
        self.icon:SetVertexColor(unpack(C.accent))
        self.icon:SetAlpha(0.7)
    end)
    
    frame.tabContainer:SetHeight(math.abs(y) + BUTTON_HEIGHT)
    
    return btn
end

---------------------------------------------------------------------------
-- SELECT TAB
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- SELECT TAB
---------------------------------------------------------------------------
function GUI:SelectTab(frame, index)
    -- Skip if this is an action button (no page to show)
    local targetTab = frame.tabs[index]
    if targetTab and targetTab.isActionButton then
        return
    end

    -- Force-load all tabs when Search tab is selected
    if index == self._searchTabIndex and self._allTabsAdded and not self._searchIndexBuilt then
        self:ForceLoadAllTabs()
        self._searchIndexBuilt = true
    end

    -- Clear search if active
    if frame._searchActive then
        if frame.searchBox and frame.searchBox.editBox then
            frame.searchBox.editBox:SetText("")
        end
        self:ClearSearchResults()
    end

    -- Deselect previous
    if frame.activeTab then
        local prevTab = frame.tabs[frame.activeTab]
        if prevTab and not prevTab.isActionButton then
            prevTab.text:SetTextColor(unpack(C.textBright))
            prevTab:SetBackdropColor(unpack(C.tabNormal))
            if prevTab.indicator then prevTab.indicator:Hide() end
            if prevTab.rightIndicator then prevTab.rightIndicator:Hide() end
            if prevTab.icon then prevTab.icon:SetVertexColor(unpack(C.textMuted)) end
        end
        
        if frame.pages[frame.activeTab] and frame.pages[frame.activeTab].frame then
            frame.pages[frame.activeTab].frame:Hide()
        end
    end
    
    -- Select new
    frame.activeTab = index
    local tab = frame.tabs[index]
    if tab and not tab.isActionButton then
        tab.text:SetTextColor(unpack(C.tabSelectedText))
        tab:SetBackdropColor(unpack(C.tabSelected))
        if tab.indicator then tab.indicator:Show() end
        if tab.rightIndicator then tab.rightIndicator:Show() end
        if tab.icon then tab.icon:SetVertexColor(unpack(C.tabSelectedText)) end
    end
    
    -- Create/show page
    local page = frame.pages[index]
    if page then
        if not page.frame then
            page.frame = CreateFrame("Frame", nil, frame.contentArea)
            page.frame:SetPoint("TOPLEFT", frame.topBar, "BOTTOMLEFT", 0, -5)
            page.frame:SetPoint("BOTTOMRIGHT", 0, 0)
            page.frame:EnableMouse(false)
            if page.createFunc then
                page.createFunc(page.frame)
                page.built = true
            end
        else
            -- Reset anchor points when reusing an existing frame
            -- This fixes spacing issues when switching tabs after using search
            page.frame:ClearAllPoints()
            page.frame:SetPoint("TOPLEFT", frame.topBar, "BOTTOMLEFT", 0, -5)
            page.frame:SetPoint("BOTTOMRIGHT", 0, 0)
        end
        page.frame:Show()
        
        local function TriggerOnShow(frame)
            if frame.GetScript and frame:GetScript("OnShow") then
                frame:GetScript("OnShow")(frame)
            end
            if frame.GetChildren then
                for _, child in ipairs({frame:GetChildren()}) do
                    TriggerOnShow(child)
                end
            end
        end
        TriggerOnShow(page.frame)
    end
end

---------------------------------------------------------------------------
-- SHOW FUNCTION
---------------------------------------------------------------------------
function GUI:Show()
    if not self.MainFrame then
        self:InitializeOptions()
    end
    self.MainFrame:Show()
end

---------------------------------------------------------------------------
-- HIDE FUNCTION
---------------------------------------------------------------------------
function GUI:Hide()
    if self.MainFrame then
        self.MainFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- TOGGLE FUNCTION
---------------------------------------------------------------------------
function GUI:Toggle()
    if self.MainFrame and self.MainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Store reference
gui.GUI = GUI
