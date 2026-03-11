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
-- Static Framework Palette (Gravity Glassmorphic 2026)
-- This ensures the options UI stays consistent regardless of user's UnitFrame theme choices
local C = {
    -- Glassmorphic Backgrounds
    bg = {0.11, 0.11, 0.13, 0.98}, -- Charcoal Dark Gray (Main Shell)
    bgGlass = {0.11, 0.11, 0.13, 0.98}, -- Added missing key
    bgLight = {0.15, 0.15, 0.18, 1}, -- Solid Widgets (Buttons)
    bgDark = {0.07, 0.07, 0.09, 1}, -- Inset Panels
    
    -- Branding
    accent = {0, 0.6, 1, 1}, -- Gravity Blue (Dynamic)
    accentLight = {0.4, 0.8, 1, 1}, -- Highlight
    
    -- Typography
    text = {0.9, 0.92, 0.95, 1},
    textMuted = {0.6, 0.65, 0.7, 1},
    textBright = {1, 1, 1, 1},
    
    -- UI Elements
    border = {0, 0, 0, 1}, -- Flat / Subtle
    borderAccent = {0, 0.6, 1, 1},
    sectionHeader = {0, 0.6, 1, 1},
    
    -- Functional Colors
    warning = {0.96, 0.62, 0.04, 1},
    toggleOff = {0.2, 0.2, 0.2, 1},
    toggleThumb = {0.9, 0.9, 0.9, 1},
    sliderTrack = {0.1, 0.1, 0.1, 1},
    sliderThumb = {0, 0.6, 1, 1},
    
    -- Interactive States
    tabHover = {0.2, 0.25, 0.3, 0.5},
    tabSelected = {0.15, 0.15, 0.18, 0.3},
    tabSelectedText = {0.4, 0.8, 1, 1},
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

-- Helper: Create Standard Backdrop (Flat)
local function CreateBackdrop(frame, bgColor, borderColor)
    if not frame then return end
    
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    
    local defaultBg = bgColor or C.bg
    
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = nil, -- Flat Design (No 3D borders)
        edgeSize = 0,
    })
    
    frame:SetBackdropColor(unpack(defaultBg))
    
    -- Simulate 1px border using an inset frame if borderColor is provided
    if borderColor then
        if not frame.border then
            frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            frame.border:SetPoint("TOPLEFT", -1, 1)
            frame.border:SetPoint("BOTTOMRIGHT", 1, -1)
            frame.border:SetFrameLevel(frame:GetFrameLevel()) -- Same level, allow sorting
            frame.border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            frame.border:SetBackdropBorderColor(unpack(borderColor))
        else
            frame.border:SetBackdropBorderColor(unpack(borderColor))
        end
    end
end

function GUI:CreateBackdrop(frame, ...) 
    CreateBackdrop(frame, ...) 
end

-- Helper: Glass Backdrop (Semi-Transparent + Shadow)
function GUI:CreateGlassBackdrop(frame)
    CreateBackdrop(frame, C.bgGlass, C.border)
    
    -- Add Depth Shadow
    if not frame.shadow then
        frame.shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        frame.shadow:SetPoint("TOPLEFT", -4, 4)
        frame.shadow:SetPoint("BOTTOMRIGHT", 4, -4)
        frame.shadow:SetColorTexture(0, 0, 0, 0.5)
        
        -- Optional: Use a real shadow asset if available, but pure color with inset works for "Glass" feel
    end
end
    
---------------------------------------------------------------------------
-- DYNAMIC THEMING
---------------------------------------------------------------------------
function GUI:UpdateThemeColors()
    local db = ns.db and ns.db.profile
    if not db then return end
    
    local r, g, b = 0, 0.6, 1 -- Default Blue
    
    -- 1. Class Color Priority
    if db.general and db.general.useClassColorTheme then
        local _, class = UnitClass("player")
        if class then
            local c = C_ClassColor.GetClassColor(class)
            if c then r, g, b = c.r, c.g, c.b end
        end
    -- 2. Theme Color Priority
    elseif db.general and db.general.themeColor then
        local c = db.general.themeColor
        r, g, b = c[1], c[2], c[3]
    end
    
    -- Update Palette
    C.accent = {r, g, b, 1}
    C.accentLight = {math.min(r*1.3, 1), math.min(g*1.3, 1), math.min(b*1.3, 1), 1}
    C.borderAccent = {r, g, b, 1}
    C.sectionHeader = {r, g, b, 1}
    C.tabSelectedText = {r, g, b, 1}
    C.sliderThumb = {r, g, b, 1}
    
    -- Update Recursive
    if self.MainFrame and self.MainFrame.RefreshColors then
        self.MainFrame:RefreshColors()
    end
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
    local function ClearChildren(...)
        for i = 1, select("#", ...) do
            local child = select(i, ...)
            if not child.isStepHeader then
                child:Hide()
                child:SetParent(nil)
            end
        end
    end
    ClearChildren(content:GetChildren())
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
    
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.15, 0.15, 0.15, 1)
    container:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
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
function GUI:CreateInfoBox(parent, text, width, styleOverride)
    if parent._hasContent ~= nil then
        parent._hasContent = true
    end

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    -- Use CONTENT_WIDTH if available for perfect alignment, otherwise safe fallback
    -- Use CONTENT_WIDTH if available for perfect alignment, otherwise safe fallback
    local defaultWidth = (GUI.CONTENT_WIDTH and (GUI.CONTENT_WIDTH - 20)) or 660
    frame:SetWidth(width or defaultWidth)
    
    -- Defaults
    local bgFile = "Interface\\Buttons\\WHITE8x8"
    local edgeFile = nil -- Default: No Border
    local edgeSize = 0
    local bgColor = {0.15, 0.15, 0.15, 1}
    local borderColor = C.border
    
    -- Style Overrides
    if styleOverride and styleOverride.noBorder then
        edgeFile = nil
        edgeSize = 0
    end
    
    -- Modern Gradient Background
    -- Create texture layer for the gradient instead of using flat BackdropColor
    if not frame.bgTexture then
        frame.bgTexture = frame:CreateTexture(nil, "BACKGROUND")
        frame.bgTexture:SetAllPoints()
        frame.bgTexture:SetTexture("Interface\\Buttons\\WHITE8x8")
    end

    -- Apply Gradient: Dark -> Transparent
    -- Start with solid dark gray/black and fade to transparent on the right
    local r, g, b = unpack(bgColor)
    -- Use 0.6 alpha for start, fade to SAME COLOR transparent (r,g,b,0) to avoid blackness
    frame.bgTexture:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.6), CreateColor(r, g, b, 0)) 
    
    frame:SetBackdrop({
        bgFile = nil, 
        edgeFile = edgeFile,
        edgeSize = edgeSize,
    })
    frame:SetBackdropColor(0, 0, 0, 0) -- Ensure backdrop is purely transparent so it doesnt show through 
    
    frame:SetBackdrop({
        bgFile = nil, -- Disable backdrop bg to let texture show
        edgeFile = edgeFile,
        edgeSize = edgeSize,
    })
    -- frame:SetBackdropColor(unpack(bgColor)) -- Handled by gradient texture now

    if edgeFile then
         frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
    end
    
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(label, 12, "")
    label:SetParent(frame)
    label:SetPoint("TOPLEFT", 12, -12)
    label:SetWidth(frame:GetWidth() - 100) -- Reduce text width so it doesn't overlap the faded out part
    label:SetJustifyH("LEFT")
    
    -- Standardize Text (Strip "Note:" or "Info:" prefixes if present)
    text = text:gsub("^|c%x%x%x%x%x%x%x%xNote:|r%s*", "")
    text = text:gsub("^Note:%s*", "")
    text = text:gsub("^|c%x%x%x%x%x%x%x%xInfo:|r%s*", "")
    text = text:gsub("^Info:%s*", "")

    -- Color Configuration
    local prefixColor = "|cffaaaaaa" -- Default Light Gray
    local bodyColor = "|cff88ccff" -- Default Light Blue
    local prefix = "Info:"
    
    if styleOverride then
        if styleOverride.prefixColorStr then prefixColor = styleOverride.prefixColorStr end
        if styleOverride.bodyColorStr then bodyColor = styleOverride.bodyColorStr end
        if styleOverride.useNote then prefix = "Note:" end
    end

    -- Format Text
    
    -- Colorize internal "Note:" to match prefix color (break body color, gray note, resume body color)
    -- We assume 'text' is wrapped in bodyColor below, so we need to:
    -- 1. Close the current bodyColor tag (|r)
    -- 2. Open prefixColor for "Note:"
    -- 3. Close prefixColor (|r)
    -- 4. Re-open bodyColor for following text
    
    -- The pattern needs to match potential existing colors or just raw text.
    -- Simple approach: Replace "Note:" with the sequence
    text = text:gsub("Note:", "|r" .. prefixColor .. "Note:|r" .. bodyColor)

    -- "Info:" (Prefix) | Body Text
    label:SetText(prefixColor .. prefix .. "|r " .. bodyColor .. text .. "|r")
    
    frame.label = label
    
    self:RegisterInSearchIndex(text, frame)
    
    -- Dynamic Height
    frame:SetHeight(label:GetStringHeight() + 24)
    
    frame.SetText = function(self, newText)
        -- Keep prefix logic simple for updates or re-apply based on stored settings? 
        -- For now, just set raw text, or re-apply styling if we stored it. 
        -- Simplest is just set the label text directly assume it's pre-formatted or just raw.
        -- Let's stick to the formatted update:
        self.label:SetText(prefixColor .. prefix .. "|r " .. bodyColor .. newText .. "|r")
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
    
    -- Glow Hover
    local glow = btn:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints()
    glow:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.1)
    glow:SetAlpha(0)
    btn.glow = glow
    
    btn:SetScript("OnEnter", function(self)
        -- Animate Glow
        UIFrameFadeIn(self.glow, 0.1, 0, 0.2)
        -- Border Highlight
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    
    btn:SetScript("OnLeave", function(self)
        UIFrameFadeOut(self.glow, 0.2, 0.2, 0)
        
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    end)
    
    btn.RefreshColors = function(self)
        if self.glow then
            self.glow:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.1)
        end
    end
    
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
    
    local function SetValue(val, suppressCallback)
        if dbTable and dbKey then
            dbTable[dbKey] = val
        end
        
        -- Animate thumb
        if val then
            thumb:ClearAllPoints()
            thumb:SetPoint("RIGHT", switch, "RIGHT", -2, 0)
            switch:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1) -- Solid Active (Matches Slider)
        else
            thumb:ClearAllPoints()
            thumb:SetPoint("LEFT", switch, "LEFT", 2, 0)
            switch:SetBackdropColor(C.toggleOff[1], C.toggleOff[2], C.toggleOff[3], 1)
        end
        
        if onChange and not suppressCallback then
            onChange(val)
        end
    end
    
    container.RefreshColors = function(self)
        if GetValue() then
             switch:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end
    end
    
    -- Initialize (without triggering callback)
    local initVal = GetValue()
    if initVal then
        thumb:ClearAllPoints()
        thumb:SetPoint("RIGHT", switch, "RIGHT", -2, 0)
        switch:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)
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
    
    -- [FIX] method wrapper to discard 'self'
    container.SetValue = function(self, val, suppress)
        SetValue(val, suppress)
    end
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
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.15, 0.15, 0.15, 1)
    editBox:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
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
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    slider:SetBackdropColor(0.15, 0.15, 0.15, 1)
    slider:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
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
    
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.15, 0.15, 0.15, 1)
    editBox:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
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
    
    editBox:SetScript("OnEditFocusLost", function(self)
        SetValue(self:GetText())
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
    
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.15, 0.15, 0.15, 1)
    dropdown:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
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
            
            if item.previewFunc then
                local playBtn = CreateFrame("Button", nil, btn)
                playBtn:SetSize(18, 18)
                playBtn:SetPoint("RIGHT", -6, 0)
                
                local playIcon = playBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                SetFont(playIcon, 10, "", C.text)
                playIcon:SetText("▶")
                playIcon:SetPoint("CENTER", 1, 0)
                
                playBtn:SetScript("OnEnter", function(self) 
                    btn:GetScript("OnEnter")(btn)
                    SetFont(playIcon, 10, "", C.accent)
                end)
                playBtn:SetScript("OnLeave", function(self) 
                    btn:GetScript("OnLeave")(btn)
                    SetFont(playIcon, 10, "", C.text)
                end)
                
                playBtn:SetScript("OnClick", function()
                    item.previewFunc(item.value)
                end)
                
                -- Adjust text width so it doesn't overlap the play button
                btnText:SetWidth(isScrollable and 140 or 160)
            end
            
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
function GUI:CreateColorPicker(parent, label, dbKey, dbTable, callbackFunc)
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
        
        -- Strict check for callback
        if type(callbackFunc) == "function" then 
            callbackFunc(r, g, b, a) 
        end
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
-- WIDGET: SECTION HEADER (Standard Text + Underline)
---------------------------------------------------------------------------
function GUI:CreateSectionHeader(parent, text)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(GUI.CONTENT_WIDTH - 20, 30)
    
    local headerText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(headerText, 14, "", C.sectionHeader) -- Uses Theme Color (Gravity Blue)
    headerText:SetText(text or "Header")
    headerText:SetPoint("BOTTOMLEFT", 0, 5)
    
    local underline = container:CreateTexture(nil, "ARTWORK")
    underline:SetHeight(2)
    underline:SetPoint("TOPLEFT", headerText, "BOTTOMLEFT", 0, -2)
    underline:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    underline:SetTexture("Interface\\Buttons\\WHITE8x8")
    underline:SetGradient("HORIZONTAL", CreateColor(C.accent[1], C.accent[2], C.accent[3], 1), CreateColor(C.accent[1], C.accent[2], C.accent[3], 0))
    
    -- Register for search
    self:RegisterInSearchIndex(text, container)
    
    -- Expose properties
    container.text = headerText
    container.underline = underline
    container.gap = 34 -- Standard gap for layout calculations
    
    -- Helper to update colors dynamically (if needed, though C.sectionHeader is static-ish)
    container.RefreshColors = function()
        headerText:SetTextColor(unpack(C.sectionHeader))
        underline:SetGradient("HORIZONTAL", CreateColor(C.accent[1], C.accent[2], C.accent[3], 1), CreateColor(C.accent[1], C.accent[2], C.accent[3], 0))
    end
    
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
    underline:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    
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
    local db = ns.GetDB()
    local isSideTop = db and db.general.menuStyle == "SIDE_TOP"
    
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 0, 0)
    container:SetPoint("TOPRIGHT", 0, 0)
    
    local tabButtons = {}
    local tabContents = {}
    
    if isSideTop then
        container:SetHeight(36)
        
        -- Create a background for the tab bar
        local bg = container:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.3)
        
        local underline = container:CreateTexture(nil, "ARTWORK")
        underline:SetHeight(1)
        underline:SetPoint("BOTTOMLEFT", 0, 0)
        underline:SetPoint("BOTTOMRIGHT", 0, 0)
        underline:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.5)
        
        local xOffset = 0
        local yOffset = 0
        local rowHeight = 28
        local spacing = 2
        local maxWidth = (parent:GetWidth() > 0) and (parent:GetWidth() - 20) or (GUI.CONTENT_WIDTH - 20)
        
        for i, tabInfo in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
            
            -- Calculate width based on text or use a minimum
            -- More compact padding (20px total)
            local textWidth = tabInfo.name and (string.len(tabInfo.name) * 8) or 60
            local btnWidth = math.max(60, textWidth + 20)
            
            -- Wrap to next row?
            if xOffset + btnWidth > maxWidth then
                xOffset = 0
                yOffset = yOffset - rowHeight - spacing
            end
            
            btn:SetSize(btnWidth, rowHeight)
            btn:SetPoint("TOPLEFT", xOffset, yOffset)
            
            xOffset = xOffset + btnWidth + spacing
            
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            GUI:SetFont(text, 12, "")
            text:SetPoint("CENTER", 0, 0)
            text:SetText(tabInfo.name or ("Tab " .. i))
            text:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
            btn.text = text
            
            local activeLine = btn:CreateTexture(nil, "OVERLAY")
            activeLine:SetHeight(1)
            activeLine:SetPoint("BOTTOMLEFT", 4, 1)
            activeLine:SetPoint("BOTTOMRIGHT", -4, 1)
            activeLine:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.8)
            activeLine:Hide()
            btn.activeLine = activeLine

            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            btn:SetBackdropColor(0, 0, 0, 0)
            
            btn:SetScript("OnEnter", function(self)
                if not self.isActive then
                    self:SetBackdropColor(C.tabHover[1], C.tabHover[2], C.tabHover[3], C.tabHover[4])
                    self.text:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3], 1)
                end
            end)
            
            btn:SetScript("OnLeave", function(self)
                if not self.isActive then
                    self:SetBackdropColor(0, 0, 0, 0)
                    self.text:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
                end
            end)
            
            btn:SetScript("OnClick", function()
                local pageId = GUI.currentPageId
                if pageId then
                     local idx
                     for t, id in ipairs(GUI.pageOrder) do if id == pageId then idx = t; break end end
                     if idx then GUI:ShowPage(idx, i) end
                end
            end)
            
            tabButtons[i] = btn
        end
        
        -- Set container height based on rows used
        container:SetHeight(math.abs(yOffset) + rowHeight + 4)
    else
        container:SetHeight(1)
    end
    
    for i, tabInfo in ipairs(tabs) do
        local contentFrame = CreateFrame("Frame", nil, parent)
        contentFrame:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, 0)
        contentFrame:SetPoint("BOTTOMRIGHT", 0, 0)
        contentFrame:Hide()
        tabContents[i] = contentFrame
        
        if tabInfo.builder then
            if GUI.currentSearchContext then
                GUI:SetSearchContext(GUI.currentSearchContext.pageId, i)
            end
            tabInfo.builder(contentFrame)
            if GUI.currentSearchContext then
                GUI:SetSearchContext(GUI.currentSearchContext.pageId, 0)
            end
        end
    end
    
    container.tabContents = tabContents
    container.tabButtons = tabButtons
    
    -- Function to update button states (called by ShowPage)
    container.UpdateButtons = function(self, activeIndex)
        if not isSideTop then return end
        for i, btn in ipairs(self.tabButtons) do
            if i == activeIndex then
                btn.isActive = true
                btn.text:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
                btn.activeLine:Show()
            else
                btn.isActive = false
                btn.text:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
                btn.activeLine:Hide()
            end
        end
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
