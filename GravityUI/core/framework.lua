-- GravityUI GUI Framework
-- Modern widget library with Blue Condition theme
local ADDON_NAME, ns = ...

-- Create GUI namespace
ns.GUI = ns.GUI or {}
local GUI = ns.GUI

-- Get color palette (Global for other modules)
local GlobalColors = ns.Colors

-- Static Framework Palette (Gravity Blue Branding)
-- This ensures the options UI stays consistent regardless of user's UnitFrame theme choices
local C = {
    bg = {0.117, 0.121, 0.133, 1},
    bgLight = {0.122, 0.161, 0.216, 1},
    bgDark = {0.04, 0.05, 0.08, 1},
    accent = {0, 0.749, 1, 1},
    accentLight = {0.529, 0.808, 0.980, 1},
    text = {0.9, 0.92, 0.95, 1},
    textMuted = {0.6, 0.65, 0.7, 1},
    border = {0.2, 0.23, 0.28, 1},
    borderAccent = {0, 0.749, 1, 1},
    sectionHeader = {0.529, 0.808, 0.980, 1},
    warning = {0.961, 0.620, 0.043, 1},
    toggleOff = {0.15, 0.15, 0.15, 1},
    toggleThumb = {0.9, 0.9, 0.9, 1},
    sliderTrack = {0.15, 0.15, 0.15, 1},
    sliderThumb = {0, 0.749, 1, 1},
    textBright = {1, 1, 1, 1},
    tabHover = {0.2, 0.25, 0.3, 0.5},
    tabSelected = {0, 0.749, 1, 0.2},
    tabSelectedText = {0.529, 0.808, 0.980, 1},
}
GUI.Colors = C

-- LibSharedMedia for fonts
local LSM = LibStub("LibSharedMedia-3.0")

-- Font path
local FONT_PATH = ns.FONT_PATH or "Interface/AddOns/GravityUI/assets/Gravity.ttf"

-- Panel dimensions
GUI.PANEL_WIDTH = 750
GUI.CONTENT_WIDTH = 700

-- Page registry
GUI.pages = {}
GUI.pageOrder = {}

-- Search Index
GUI.searchIndex = {}
GUI.currentSearchContext = nil -- { pageId = "", tabIndex = 0 }

function GUI:SetSearchContext(pageId, tabIndex)
    self.currentSearchContext = { pageId = pageId, tabIndex = tabIndex }
end

function GUI:ClearSearchContext()
    self.currentSearchContext = nil
end

function GUI:RegisterInSearchIndex(text, widget)
    if not self.currentSearchContext or not text or text == "" then return end
    
    local pageId = self.currentSearchContext.pageId
    local tabIndex = self.currentSearchContext.tabIndex
    local page = self.pages[pageId]
    
    local tabName
    if tabIndex and tabIndex > 0 and page and page.lastSubTabsData then
        tabName = page.lastSubTabsData[tabIndex] and page.lastSubTabsData[tabIndex].name
    end
    
    table.insert(self.searchIndex, {
        text = text:lower(),
        displayText = text,
        widget = widget,
        pageId = pageId,
        pageTitle = page and page.title or pageId,
        tabIndex = tabIndex,
        tabName = tabName
    })
end

---------------------------------------------------------------------------
-- LOCAL HELPERS (Must be defined before use)
---------------------------------------------------------------------------

-- Helper: Set font on fontstring
local function SetFont(fontString, size, flags, color)
    fontString:SetFont(FONT_PATH, size or 12, flags or "")
    if color then
        fontString:SetTextColor(unpack(color))
    end
end

function GUI:SetFont(...) SetFont(...) end

-- Helper: Create backdrop
local function CreateBackdrop(frame, bgColor, borderColor)
    if not frame or not frame.SetBackdrop then return end
    
    local defaultBg = bgColor or C.bg
    
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(defaultBg))
    frame:SetBackdropBorderColor(unpack(borderColor or C.border))
end

function GUI:CreateBackdrop(frame, ...) 
    CreateBackdrop(frame, ...) 
end

function GUI:ClearPageContent(content)
    if not content then return end
    
    -- Clear regions (FontStrings, Textures)
    local regions = {content:GetRegions()}
    for _, region in ipairs(regions) do
        if not region.isStepHeader then
            region:Hide()
            if region.SetText then region:SetText("") end
        end
    end
    
    -- Clear children (Frames)
    local children = {content:GetChildren()}
    for _, child in ipairs(children) do
        if not child.isStepHeader then
            child:Hide()
            child:SetParent(nil)
        end
    end
end

---------------------------------------------------------------------------
-- UTILITY: SCROLLABLE CONTENT
---------------------------------------------------------------------------
function GUI:CreateScrollableContent(parent)
    -- Provide a unique name to the ScrollFrame so we can safely access its children
    local name = "GUI_ScrollFrame_" .. (self.__scrollCount or 1)
    self.__scrollCount = (self.__scrollCount or 1) + 1
    
    local scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(parent:GetWidth() - 20, 1) -- Initial size
    scroll:SetScrollChild(content)
    
    scroll:SetScript("OnSizeChanged", function(self, width, height)
        content:SetWidth(width - 20)
    end)
    
    -- Customize scrollbar
    local scrollBar = _G[name .. "ScrollBar"]
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 26, -18)
        scrollBar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 26, 18)
    end
    
    return scroll, content
end

function GUI:CreateScrollableTextBox(parent, height, initialText, readOnly)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetHeight(height)
    
    self:CreateBackdrop(container, {0.05, 0.05, 0.05, 0.8}, C.border)
    
    local scroll = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    
    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetAutoFocus(false)
    SetFont(editBox, 11)
    
    -- Set initial width if parent already has it, otherwise it will be set in OnSizeChanged
    local initialWidth = scroll:GetWidth()
    if initialWidth > 0 then
        editBox:SetWidth(initialWidth)
    else
        editBox:SetWidth(200) -- Fallback
    end
    
    editBox:SetText(initialText or "")
    
    scroll:SetScrollChild(editBox)
    
    -- Handle resizing
    scroll:SetScript("OnSizeChanged", function(self, width, height)
        editBox:SetWidth(width)
    end)
    
    -- Read-only handling
    if readOnly then
        local originalText = initialText or ""
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                self:SetText(originalText)
                self:HighlightText()
            end
        end)
    end

    -- Make it easier to focus (click anywhere in the box)
    container:EnableMouse(true)
    container:SetScript("OnMouseDown", function() editBox:SetFocus() end)
    scroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)
    
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    container.editBox = editBox
    container.scroll = scroll
    return container
end

---------------------------------------------------------------------------
-- WIDGET: LABEL
---------------------------------------------------------------------------
function GUI:CreateLabel(parent, text, size, color, anchor, x, y)
    if parent._hasContent ~= nil then
        parent._hasContent = true
    end
    
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(label, size or 12, "", color or C.text)
    label:SetText(text or "")
    
    if parent.isStepHeader and not text then -- Only inherit if text is nil (static elements)
        label.isStepHeader = true
    end
    
    if anchor then
        label:SetPoint(anchor, parent, anchor, x or 0, y or 0)
    end
    
    self:RegisterInSearchIndex(text, label)
    
    return label
end

---------------------------------------------------------------------------
-- WIDGET: INFO BOX
---------------------------------------------------------------------------
function GUI:CreateInfoBox(parent, text, width)
    if parent._hasContent ~= nil then
        parent._hasContent = true
    end

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetWidth(width or (GUI.CONTENT_WIDTH - 20))
    
    -- Subdued Blue Condition Theme
    local bg = {0, 0.75, 1, 0.05}
    local border = {0, 0.75, 1, 0.2}
    CreateBackdrop(frame, bg, border)
    
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(label, 12, "OUTLINE")
    label:SetParent(frame)
    label:SetPoint("TOPLEFT", 12, -12)
    label:SetWidth(frame:GetWidth() - 24)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    frame.label = label
    
    self:RegisterInSearchIndex(text, frame)
    
    -- Dynamic Height
    frame:SetHeight(label:GetStringHeight() + 24)
    
    frame.SetText = function(self, newText)
        self.label:SetText(newText)
        self:SetHeight(self.label:GetStringHeight() + 24)
    end
    
    return frame
end

---------------------------------------------------------------------------
-- WIDGET: BUTTON
---------------------------------------------------------------------------
function GUI:CreateButton(parent, text, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 120, height or 26)
    
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetFont(FONT_PATH, 12, "")
    btnText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    btnText:SetPoint("CENTER", 0, 0)
    btnText:SetText(text or "Button")
    btn.text = btnText
    
    self:RegisterInSearchIndex(text, btn)
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    end)
    
    if onClick then
        btn:SetScript("OnClick", onClick)
    end
    
    function btn:SetText(newText)
        btnText:SetText(newText)
    end
    
    return btn
end

---------------------------------------------------------------------------
-- WIDGET: SECTION HEADER
---------------------------------------------------------------------------
function GUI:CreateSectionHeader(parent, text)
    local isFirstElement = (parent._hasContent == false)
    if parent._hasContent ~= nil then
        parent._hasContent = true
    end
    
    local topMargin = isFirstElement and 0 or 12
    local containerHeight = isFirstElement and 18 or 30
    
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(containerHeight)
    
    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(header, 13, "", C.sectionHeader)
    header:SetText(text or "Section")
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -topMargin)
    
    if parent.isStepHeader and not text then -- Only inherit if text is nil (static elements like headers in search)
        header.isStepHeader = true
        container.isStepHeader = true
    end
    
    self:RegisterInSearchIndex(text, container)
    
    container.text = header
    container.parent = parent
    container.gap = isFirstElement and 34 or 46
    
    container.SetText = function(self, newText)
        header:SetText(newText)
    end
    
    local originalSetPoint = container.SetPoint
    container.SetPoint = function(self, point, ...)
        originalSetPoint(self, point, ...)
        if point == "TOPLEFT" then
            originalSetPoint(self, "RIGHT", parent, "RIGHT", -10, 0)
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
-- WIDGET: CHECKBOX (Toggle Switch Style)
---------------------------------------------------------------------------
function GUI:CreateCheckbox(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 24)
    
    -- Modern toggle switch
    local switch = CreateFrame("Frame", nil, container, "BackdropTemplate")
    switch:SetSize(40, 20)
    switch:SetPoint("LEFT", 0, 0)
    
    CreateBackdrop(switch, C.toggleOff, C.border)
    
    -- Thumb (circle)
    local thumb = CreateFrame("Frame", nil, switch, "BackdropTemplate")
    thumb:SetSize(16, 16)
    thumb:SetPoint("LEFT", 2, 0)
    
    thumb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    thumb:SetBackdropColor(C.toggleThumb[1], C.toggleThumb[2], C.toggleThumb[3], 1)
    thumb:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
    -- Label text
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", switch, "RIGHT", 8, 0)
    
    container.switch = switch
    container.thumb = thumb
    container.label = text
    
    self:RegisterInSearchIndex(label, container)
    
    -- Get/Set value
    local function GetValue()
        if dbTable and dbKey then
            return dbTable[dbKey] == true
        end
        return false
    end
    
    local function SetValue(val)
        if dbTable and dbKey then
            dbTable[dbKey] = val
        end
        
        -- Animate thumb
        if val then
            thumb:ClearAllPoints()
            thumb:SetPoint("RIGHT", switch, "RIGHT", -2, 0)
            switch:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        else
            thumb:ClearAllPoints()
            thumb:SetPoint("LEFT", switch, "LEFT", 2, 0)
            switch:SetBackdropColor(C.toggleOff[1], C.toggleOff[2], C.toggleOff[3], 1)
        end
        
        if onChange then
            onChange(val)
        end
    end
    
    -- Initialize (without triggering callback)
    local initVal = GetValue()
    if initVal then
        thumb:ClearAllPoints()
        thumb:SetPoint("RIGHT", switch, "RIGHT", -2, 0)
        switch:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    else
        thumb:ClearAllPoints()
        thumb:SetPoint("LEFT", switch, "LEFT", 2, 0)
        switch:SetBackdropColor(C.toggleOff[1], C.toggleOff[2], C.toggleOff[3], 1)
    end
    
    -- Click handler
    switch:SetScript("OnMouseDown", function()
        SetValue(not GetValue())
    end)
    
    -- Hover effect
    switch:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    
    switch:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    end)
    
    container.GetValue = GetValue
    container.SetValue = SetValue
    
    -- Add Enable/Disable/SetChecked methods for consistency
    container.Enable = function()
        container.disabled = false
        switch:EnableMouse(true)
        switch:SetAlpha(1)
        if container.label then container.label:SetAlpha(1) end
    end
    
    container.Disable = function()
        container.disabled = true
        switch:EnableMouse(false)
        switch:SetAlpha(0.5)
        if container.label then container.label:SetAlpha(0.5) end
    end
    
    container.SetChecked = function(self, val)
        if self.disabled then return end
        SetValue(val)
    end
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: SLIDER
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- WIDGET: SLIDER
---------------------------------------------------------------------------
function GUI:CreateSlider(parent, label, min, max, dbKey, dbTable, onChange, step)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 40)
    
    -- Label
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(labelText, 12, "", C.text)
    labelText:SetText(label or "Slider")
    labelText:SetPoint("TOPLEFT", 0, 0)
    
    -- EditBox for manual input (next to slider)
    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetSize(50, 20)
    editBox:SetPoint("TOPRIGHT", 0, -18)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetJustifyH("CENTER")
    editBox:SetTextInsets(3, 3, 0, 0)
    
    -- Square 1px border styling
    CreateBackdrop(editBox, {0.1, 0.1, 0.1, 0.8}, C.border)
    
    -- Slider
    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", 0, -20)
    slider:SetPoint("RIGHT", editBox, "LEFT", -10, 0) -- Dynamic width, ends before EditBox
    slider:SetOrientation("HORIZONTAL")
    
    -- Use integer math for slider to avoid floating point jumpiness
    -- Multiply everything by 100 internally
    local MULTIPLIER = 100
    
    slider:SetMinMaxValues((min or 0) * MULTIPLIER, (max or 100) * MULTIPLIER)
    slider:SetValueStep((step or 1) * MULTIPLIER)
    slider:SetObeyStepOnDrag(true)
    
    -- Track
    CreateBackdrop(slider, C.sliderTrack, C.border)
    
    -- Thumb
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(12, 16)
    thumb:SetColorTexture(C.sliderThumb[1], C.sliderThumb[2], C.sliderThumb[3], 1)
    slider:SetThumbTexture(thumb)
    
    container.slider = slider
    container.label = labelText
    container.editBox = editBox
    
    self:RegisterInSearchIndex(label, container)
    
    -- Get/Set value
    local function GetValue()
        if dbTable and dbKey then
            return dbTable[dbKey] or min or 0
        end
        return min or 0
    end
    
    local function SetValue(val, triggerCallback, source)
        -- Ensure value is within bounds
        val = math.max(min or 0, math.min(max or 100, val))
        
        -- Update slider widget visual only (using internal integer scale)
        -- Don't trigger OnValueChanged if source is slider itself loop
        if source ~= "slider" then
            slider:SetValue(val * MULTIPLIER)
        end
        
        -- Update EditBox visual (unless source is editbox being typed in)
        if source ~= "editbox" then
            editBox:SetText(string.format("%.2f", val))
        end
        
        -- Only save and trigger callback if requested (e.g. on mouse up or enter)
        if triggerCallback then
            if dbTable and dbKey then
                dbTable[dbKey] = val
            end
            
            if onChange then
                onChange(val)
            end
        end
    end
    
    -- Initialize
    SetValue(GetValue(), false)
    
    -- Slider Change Handler (Visual update only)
    slider:SetScript("OnValueChanged", function(self, val, userInput)
        if userInput then
            -- Convert internal integer scale back to float
            local realVal = val / MULTIPLIER
            
            -- Round to nearest step
            local s = step or 0.01
            realVal = math.floor(realVal / s + 0.5) * s
            
            -- Update editbox text
            editBox:SetText(string.format("%.2f", realVal))
        end
    end)
    
    -- Apply changes when dragging stops
    slider:SetScript("OnMouseUp", function(self)
        local val = self:GetValue() / MULTIPLIER
        local s = step or 0.01
        val = math.floor(val / s + 0.5) * s
        
        -- Trigger callback and save
        SetValue(val, true, "slider")
    end)
    
    -- EditBox Handlers
    editBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        local val = tonumber(text)
        if val then
            SetValue(val, true, "editbox") -- Apply and update slider position
            self:ClearFocus()
        else
            -- Invalid input, reset to current value
            self:SetText(string.format("%.2f", GetValue()))
            self:ClearFocus()
        end
    end)
    
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format("%.2f", GetValue()))
        self:ClearFocus()
    end)
    
    -- Tooltip for EditBox
    editBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Type value and press Enter", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    editBox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    container.GetValue = GetValue
    container.SetValue = SetValue
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: COLOR PICKER
---------------------------------------------------------------------------
function GUI:CreateColorPicker(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 24)
    
    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(text, 12, "", C.text)
    text:SetText(label or "Color")
    text:SetPoint("LEFT", 0, 0)
    
    self:RegisterInSearchIndex(label, container)
    
    local button = CreateFrame("Button", nil, container, "BackdropTemplate")
    button:SetSize(24, 24)
    button:SetPoint("RIGHT", 0, 0)
    GUI:CreateBackdrop(button, {1,1,1,1}, C.border)
    
    local texture = button:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetColorTexture(1, 1, 1, 1)
    
    local function UpdateColor()
        local color = dbTable[dbKey] or {1,1,1,1}
        texture:SetColorTexture(unpack(color))
    end
    
    button:SetScript("OnClick", function()
        local color = dbTable[dbKey] or {1,1,1,1}
        local r, g, b, a = unpack(color)
        
        local picker = ColorPickerFrame
        picker:SetColorRGB(r, g, b)
        picker.hasOpacity = true
        picker.opacity = 1 - (a or 1)
        picker.previousValues = {r, g, b, a}
        
        picker.func = function()
            local r, g, b = picker:GetColorRGB()
            local a = 1 - OpacitySliderFrame:GetValue()
            dbTable[dbKey] = {r, g, b, a}
            UpdateColor()
            if onChange then onChange({r, g, b, a}) end
        end
        
        picker.opacityFunc = picker.func
        
        picker.cancelFunc = function()
            dbTable[dbKey] = picker.previousValues
            UpdateColor()
            if onChange then onChange(picker.previousValues) end
        end
        
        picker:Hide() -- Reset
        picker:Show()
    end)
    
    UpdateColor()
    return container
end

---------------------------------------------------------------------------
-- WIDGET: INPUT (EditBox)
---------------------------------------------------------------------------
function GUI:CreateInput(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 40)
    
    -- Label
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(labelText, 12, "", C.text)
    labelText:SetText(label or "Input")
    labelText:SetPoint("TOPLEFT", 0, 0)
    
    -- EditBox
    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetSize(200, 24)
    editBox:SetPoint("TOPLEFT", 0, -18)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetTextInsets(8, 8, 0, 0)
    
    CreateBackdrop(editBox, C.bgDark, C.border)
    
    container.editBox = editBox
    container.label = labelText
    
    self:RegisterInSearchIndex(label, container)
    
    local function GetValue()
        if dbTable and dbKey then
            return dbTable[dbKey] or ""
        end
        return ""
    end
    
    local function SetValue(val)
        if dbTable and dbKey then
            dbTable[dbKey] = val
        end
        editBox:SetText(val)
        if onChange then onChange(val) end
    end
    
    -- Initialize
    editBox:SetText(GetValue())
    
    -- Handlers
    editBox:SetScript("OnEnterPressed", function(self)
        SetValue(self:GetText())
        self:ClearFocus()
    end)
    
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(GetValue())
        self:ClearFocus()
    end)
    
    -- Hover effect
    editBox:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    
    editBox:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    end)
    
    container.GetValue = GetValue
    container.SetValue = SetValue
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: DROPDOWN
---------------------------------------------------------------------------
-- Singleton infrastructure for dropdowns
local activeDropdownMenu = nil
local dropdownCatcher = nil

local function CloseActiveDropdown()
    if activeDropdownMenu then
        activeDropdownMenu:Hide()
        activeDropdownMenu = nil
    end
    if dropdownCatcher then
        dropdownCatcher:Hide()
    end
end

-- Initialize persistent catcher
local function GetDropdownCatcher()
    if not dropdownCatcher then
        dropdownCatcher = CreateFrame("Button", "GravityUIDropdownCatcher", UIParent)
        dropdownCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
        dropdownCatcher:SetFrameLevel(995)
        dropdownCatcher:SetAllPoints(UIParent)
        dropdownCatcher:EnableMouse(true)
        dropdownCatcher:Hide()
        
        dropdownCatcher:SetScript("OnMouseDown", CloseActiveDropdown)
        dropdownCatcher:SetScript("OnMouseWheel", function() end) -- Consume scroll
    end
    return dropdownCatcher
end

function GUI:CreateDropdown(parent, label, items, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 40)
    
    -- Label
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(labelText, 12, "", C.text)
    labelText:SetText(label or "Dropdown")
    labelText:SetPoint("TOPLEFT", 0, 0)
    
    -- Dropdown button
    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetSize(200, 24)
    dropdown:SetPoint("TOPLEFT", 0, -18)
    
    CreateBackdrop(dropdown, C.bgDark, C.border)
    
    -- Selected text
    local selectedText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(selectedText, 11, "", C.text)
    selectedText:SetPoint("LEFT", 8, 0)
    selectedText:SetPoint("RIGHT", -20, 0)
    selectedText:SetJustifyH("LEFT")
    
    -- Arrow icon
    local arrow = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(arrow, 10, "", C.textMuted)
    arrow:SetText("▼")
    arrow:SetPoint("RIGHT", -6, 0)
    
    container.dropdown = dropdown
    container.selectedText = selectedText
    container.label = labelText
    
    self:RegisterInSearchIndex(label, container)
    
    -- Get/Set value
    local currentValue = nil
    
    local function GetValue()
        if dbTable and dbKey then
            return dbTable[dbKey]
        end
        return currentValue
    end
    
    local function SetValue(val)
        currentValue = val
        if dbTable and dbKey then
            dbTable[dbKey] = val
        end
        
        -- Update display text
        local found = false
        for _, item in ipairs(items) do
            if item.value == val then
                selectedText:SetText(item.text or item.value)
                found = true
                break
            end
        end
        if not found then selectedText:SetText("") end
        
        if onChange then
            onChange(val)
        end
    end
    
    -- Initialize
    SetValue(GetValue())
    
    -- Click handler (Robust Singleton Menu)
    dropdown:SetScript("OnClick", function(self)
        -- Close any existing menu first
        CloseActiveDropdown()
        
        -- Create/Get catcher
        local catcher = GetDropdownCatcher()
        catcher:Show()
        
        -- Create menu container
        local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        local itemHeight = 22
        local maxVisible = 10
        local totalItems = #items
        local isScrollable = totalItems > maxVisible
        
        local dropdownWidth = self:GetWidth()
        local menuHeight = (isScrollable and (maxVisible * itemHeight) or (totalItems * itemHeight)) + 4
        
        menu:SetSize(dropdownWidth, menuHeight)
        menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetFrameLevel(1000)
        
        activeDropdownMenu = menu
        
        -- Ensure catcher updates when menu closes naturally (e.g. ESC or other means)
        menu:HookScript("OnHide", function()
             if activeDropdownMenu == menu then
                 CloseActiveDropdown()
             end
        end)
        
        CreateBackdrop(menu, C.bg, C.borderAccent)
        
        -- Create ScrollFrame if needed
        local content
        local scrollFrame
        
        if isScrollable then
            scrollFrame = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", 2, -2)
            scrollFrame:SetPoint("BOTTOMRIGHT", -22, 2)
            
            content = CreateFrame("Frame", nil, scrollFrame)
            content:SetSize(176, totalItems * itemHeight)
            scrollFrame:SetScrollChild(content)
            
            -- Hide standard scrollbar elements
            local scrollBar = scrollFrame.ScrollBar
            if scrollBar then
                scrollBar.ScrollUpButton:Hide()
                scrollBar.ScrollDownButton:Hide()
                local thumb = scrollBar:GetThumbTexture()
                if thumb then
                    thumb:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
                    thumb:SetWidth(8)
                end
            end
        else
            content = menu
        end
        
        -- Populate Items
        for i, item in ipairs(items) do
            local parent = content
            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            
            if isScrollable then
                btn:SetSize(dropdownWidth - 24, itemHeight)
                btn:SetPoint("TOPLEFT", 0, -(i - 1) * itemHeight)
            else
                btn:SetSize(dropdownWidth - 4, itemHeight)
                btn:SetPoint("TOPLEFT", 2, -2 - (i - 1) * itemHeight)
            end
            btn:Show()
            
            btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
            btn:SetBackdropColor(0, 0, 0, 0)
            
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            SetFont(btnText, 11, "", C.text)
            btnText:SetText(item.text or item.value)
            btnText:SetPoint("LEFT", 6, 0)
            btnText:SetWidth(isScrollable and 160 or 180)
            btnText:SetJustifyH("LEFT")
            btnText:SetWordWrap(false)
            
            btn:SetScript("OnEnter", function(self) self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.3) end)
            btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
            
            btn:SetScript("OnClick", function()
                CloseActiveDropdown() -- Close fully BEFORE value change
                SetValue(item.value)
            end)
        end
        
        -- Wheel scrolling
        if isScrollable and scrollFrame then
            menu:EnableMouseWheel(true)
            menu:SetScript("OnMouseWheel", function(_, delta)
                local current = scrollFrame:GetVerticalScroll()
                local new = current - (delta * itemHeight)
                if new < 0 then new = 0 end
                local max = scrollFrame:GetVerticalScrollRange()
                if new > max then new = max end
                scrollFrame:SetVerticalScroll(new)
            end)
        end
        
        -- ESC key
        menu:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                CloseActiveDropdown()
            end
        end)
        
        menu:EnableKeyboard(true)
        menu:Show()
    end)
    
    -- Hover effect
    dropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    
    dropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    end)
    
    container.GetValue = GetValue
    container.SetValue = SetValue
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: COLOR PICKER
---------------------------------------------------------------------------
function GUI:CreateColorPicker(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 20)
    
    -- Color swatch button
    local swatch = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetPoint("LEFT", 0, 0)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Label
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
    
    -- Initialize color (visual only)
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
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    swatch:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end)
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: COLLAPSIBLE HEADER
---------------------------------------------------------------------------
function GUI:CreateCollapsibleHeader(parent, text, defaultExpanded)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(30)
    
    -- Header button (clickable)
    local header = CreateFrame("Button", nil, container, "BackdropTemplate")
    header:SetHeight(24)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    
    -- Arrow icon (v when expanded, > when collapsed)
    local arrow = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(arrow, 14, "", C.accent)
    arrow:SetText(defaultExpanded and "v" or ">")
    arrow:SetPoint("LEFT", 0, 0)
    
    -- Header text
    local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(headerText, 13, "", C.sectionHeader)
    headerText:SetText(text or "Section")
    headerText:SetPoint("LEFT", arrow, "RIGHT", 6, 0)
    
    self:RegisterInSearchIndex(text, container)
    
    -- Underline (always visible)
    local underline = container:CreateTexture(nil, "ARTWORK")
    underline:SetHeight(2)
    underline:SetPoint("TOPLEFT", headerText, "BOTTOMLEFT", 0, -2)
    underline:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    underline:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.6)
    
    -- Content container (holds the collapsible content)
    local content = CreateFrame("Frame", nil, container)
    content:SetPoint("TOPLEFT", 0, -30)
    content:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    content:SetHeight(0)
    content._hasContent = false
    
    container.header = header
    container.arrow = arrow
    container.headerText = headerText
    container.content = content
    container.underline = underline
    container.isExpanded = defaultExpanded or false
    
    -- Toggle function
    local function Toggle()
        container.isExpanded = not container.isExpanded
        
        if container.isExpanded then
            arrow:SetText("v")
            -- Show content
            content:Show()
            -- Update container height to include content
            local contentHeight = content:GetHeight() or 0
            container:SetHeight(30 + contentHeight)
        else
            arrow:SetText(">")
            -- Hide content
            content:Hide()
            -- Collapse container
            container:SetHeight(30)
        end

        if container.OnToggle then
            container.OnToggle(container.isExpanded)
        end
    end
    
    -- Click handler
    header:SetScript("OnClick", Toggle)
    
    -- Hover effect
    header:SetScript("OnEnter", function(self)
        arrow:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
        headerText:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
    end)
    
    header:SetScript("OnLeave", function(self)
        arrow:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
        headerText:SetTextColor(C.sectionHeader[1], C.sectionHeader[2], C.sectionHeader[3], 1)
    end)
    
    -- Initialize state
    if not container.isExpanded then
        content:Hide()
    end
    
    container.Toggle = Toggle
    container.SetExpanded = function(self, expanded)
        if expanded ~= container.isExpanded then
            Toggle()
        end
    end
    
    return container
end

---------------------------------------------------------------------------
-- WIDGET: SUB-TABS (Horizontal top-bar style)
---------------------------------------------------------------------------
function GUI:CreateSubTabs(parent, tabs)
    local container = CreateFrame("Frame", nil, parent)
    -- Initial height, updated by layout
    container:SetHeight(35)
    
    local tabButtons = {}
    local tabContents = {}
    
    -- Store for indexing context
    if GUI.currentSearchContext then
        local page = GUI.pages[GUI.currentSearchContext.pageId]
        if page then
            page.lastSubTabsData = tabs
        end
    end
    
    -- Store for layout update
    container.tabButtons = tabButtons
    
    local BUTTON_HEIGHT = 28
    local SPACING_X = 5
    local SPACING_Y = 5
    
    for i, tabInfo in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
        btn:SetHeight(BUTTON_HEIGHT)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(text, 12, "OUTLINE", C.text)
        text:SetText(tabInfo.name)
        text:SetPoint("CENTER", 0, 0)
        btn.text = text
        
        local width = text:GetStringWidth() + 30
        btn:SetSize(width, BUTTON_HEIGHT)
        
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        
        local contentFrame = CreateFrame("Frame", nil, parent)
        contentFrame:SetPoint("BOTTOMRIGHT", 0, 0)
        contentFrame:Hide()
        tabContents[i] = contentFrame
        
        if tabInfo.builder then
            -- Set search context for the tab
            if GUI.currentSearchContext then
                GUI:SetSearchContext(GUI.currentSearchContext.pageId, i)
            end
            
            tabInfo.builder(contentFrame)
            
            -- Restore page-level context (no tab)
            if GUI.currentSearchContext then
                GUI:SetSearchContext(GUI.currentSearchContext.pageId, 0)
            end
        end
        
        btn:SetScript("OnClick", function()
            for j, otherBtn in ipairs(tabButtons) do
                local isSelected = (i == j)
                if isSelected then
                    otherBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.3)
                    otherBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    tabContents[j]:Show()
                else
                    otherBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
                    otherBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                    tabContents[j]:Hide()
                end
            end
            if tabInfo.fn then
                tabInfo.fn()
            end
        end)
        
        tabButtons[i] = btn
    end
    
    -- Dynamic Layout Update
    local function UpdateLayout()
        local width = container:GetWidth()
        if not width or width < 10 then return end
        
        local x = 0
        local y = 0
        
        for _, btn in ipairs(container.tabButtons) do
            local btnWidth = btn:GetWidth()
            
            -- Wrap?
            if (x + btnWidth) > width and x > 0 then
                x = 0
                y = y - (BUTTON_HEIGHT + SPACING_Y)
            end
            
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", x, y)
            
            x = x + btnWidth + SPACING_X
        end
        
        local totalHeight = math.abs(y) + BUTTON_HEIGHT + 5
        container:SetHeight(totalHeight)
    end
    
    container:SetScript("OnSizeChanged", UpdateLayout)
    
    -- Content Anchoring
    for _, cf in pairs(tabContents) do
         cf:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -10)
    end
    
    -- Select first tab
    if tabButtons[1] then
        tabButtons[1]:GetScript("OnClick")(tabButtons[1])
    end
    
    return container
end

---------------------------------------------------------------------------
-- CONFIRMATION DIALOG
---------------------------------------------------------------------------
local confirmDialog = nil

function GUI:ShowConfirmation(options)
    -- options = {
    --   title = "Confirm",
    --   message = "Message here.",
    --   warningText = "Warning text.",
    --   acceptText = "Accept",
    --   cancelText = "Cancel",
    --   onAccept = function() end,
    --   onCancel = function() end,
    --   isDestructive = true,
    -- }

    if not confirmDialog then
        confirmDialog = CreateFrame("Frame", "GUI_ConfirmDialog", UIParent, "BackdropTemplate")
        confirmDialog:SetSize(350, 180)
        confirmDialog:SetPoint("CENTER")
        confirmDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        confirmDialog:SetFrameLevel(1000)
        confirmDialog:EnableMouse(true)
        confirmDialog:SetMovable(true)
        confirmDialog:RegisterForDrag("LeftButton")
        confirmDialog:SetScript("OnDragStart", function(self) self:StartMoving() end)
        confirmDialog:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        confirmDialog:SetClampedToScreen(true)
        confirmDialog:Hide()

        CreateBackdrop(confirmDialog, C.bg, C.borderAccent)

        -- Title
        confirmDialog.title = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.title, 14, "OUTLINE", C.accentLight)
        confirmDialog.title:SetPoint("TOP", 0, -18)

        -- Message
        confirmDialog.message = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.message, 12, "", C.text)
        confirmDialog.message:SetPoint("TOP", 0, -55)
        confirmDialog.message:SetWidth(310)
        confirmDialog.message:SetJustifyH("CENTER")

        -- Warning text
        confirmDialog.warning = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.warning, 11, "OUTLINE", C.warning)
        confirmDialog.warning:SetPoint("TOP", confirmDialog.message, "BOTTOM", 0, -10)

        -- Accept button
        confirmDialog.acceptBtn = GUI:CreateButton(confirmDialog, "Accept", 120, 30)
        confirmDialog.acceptBtn:SetPoint("BOTTOMLEFT", 35, 20)

        -- Cancel button
        confirmDialog.cancelBtn = GUI:CreateButton(confirmDialog, "Cancel", 120, 30)
        confirmDialog.cancelBtn:SetPoint("BOTTOMRIGHT", -35, 20)

        -- ESC to close
        confirmDialog:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false)
                self:Hide()
                if self._onCancel then self._onCancel() end
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)
    end

    -- Configure
    confirmDialog.title:SetText(options.title or "Confirm")
    confirmDialog.message:SetText(options.message or "")
    
    if options.warningText then
        confirmDialog.warning:SetText(options.warningText)
        confirmDialog.warning:Show()
    else
        confirmDialog.warning:Hide()
    end

    confirmDialog.acceptBtn:SetText(options.acceptText or "Accept")
    if options.isDestructive then
        confirmDialog.acceptBtn.text:SetTextColor(C.warning[1], C.warning[2], C.warning[3], 1)
    else
        confirmDialog.acceptBtn.text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    end

    confirmDialog.cancelBtn:SetText(options.cancelText or "Cancel")

    confirmDialog.acceptBtn:SetScript("OnClick", function()
        confirmDialog:Hide()
        if options.onAccept then options.onAccept() end
    end)

    confirmDialog.cancelBtn:SetScript("OnClick", function()
        confirmDialog:Hide()
        if options.onCancel then options.onCancel() end
    end)

    confirmDialog._onCancel = options.onCancel

    confirmDialog:Show()
    confirmDialog:EnableKeyboard(true)
end

---------------------------------------------------------------------------
-- PAGE REGISTRATION SYSTEM
---------------------------------------------------------------------------
function GUI:RegisterPage(id, opts)
    if type(id) ~= "string" or self.pages[id] then return end
    self.pages[id] = opts or {}
    self.pageOrder[#self.pageOrder + 1] = id
end

---------------------------------------------------------------------------
-- REFRESH FUNCTIONS
---------------------------------------------------------------------------
function GUI:RefreshColors()
    -- Update GLOBAL palette for other modules (UnitFrames, etc.)
    -- The Framework itself (C) remains static
    
    local r, g, b, a = ns.GetAccentColor()
    GlobalColors.accent = {r, g, b, a}
    GlobalColors.borderAccent = {r, g, b, a}
    GlobalColors.sectionHeader = {r, g, b, a}
    
    local br, bg, bb, ba = ns.GetThemeBgColor()
    GlobalColors.bg = {br, bg, bb, ba}

    -- We intentionally do NOT update MainWindow style here to preserve branding
end

function GUI:RefreshAll()
    -- Explicitly refresh core modules
    if ns.RefreshMinimap then ns.RefreshMinimap() end
    if ns.RefreshDatapanels then ns.RefreshDatapanels() end
    
    -- Refresh entire UI
    if ns.RefreshActionBars then ns.RefreshActionBars() end
    
    if self.MainFrame and self.MainFrame:IsShown() then
        if self.RefreshPage then
            self:RefreshPage()
        end
    end
end
