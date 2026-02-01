local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = GUI.Colors

-- ═══════════════════════════════════════════════════════════════
-- HELPERS & CONSTANTS (Ported from actionbars.lua)
-- ═══════════════════════════════════════════════════════════════
local ROW_HEIGHT = 30
local LABEL_WIDTH = 220
local WIDGET_WIDTH = 250

local function CreatePropertyRow(parent, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
    
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then
        ns.GUI:SetFont(label, 12, "")
    else
         label:SetFont(STANDARD_TEXT_FONT, 12, "")
    end
    label:SetJustifyH("LEFT")
    label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
    label:SetPoint("LEFT", 0, 0)
    label:SetText(labelText)
    label:SetTextColor(unpack(GUI.Colors.text))
    
    local widget
    if widgetType == "checkbox" then
        widget = GUI:CreateCheckbox(row, "", arg1, arg2, arg3)
        widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
    elseif widgetType == "slider" then
        widget = GUI:CreateSlider(row, "", arg1, arg2, arg3, arg4, arg5, arg6)
        widget:SetHeight(ROW_HEIGHT)
        widget:SetWidth(220)
        widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
        widget.editBox:ClearAllPoints()
        widget.editBox:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
        widget.slider:ClearAllPoints()
        widget.slider:SetPoint("LEFT", widget, "LEFT", 0, 0)
        widget.slider:SetPoint("RIGHT", widget.editBox, "LEFT", -10, 0)
    elseif widgetType == "dropdown" then
        widget = GUI:CreateDropdown(row, "", arg1, arg2, arg3, arg4)
        widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
        widget:SetWidth(WIDGET_WIDTH)
        widget.dropdown:ClearAllPoints()
        widget.dropdown:SetPoint("LEFT", widget, "LEFT", 0, 0)
        widget.dropdown:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
    elseif widgetType == "color" then
         widget = GUI:CreateColorPicker(row, "", arg1, arg2, arg3)
         widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
    end
    
    return row
end

local function AddRow(parent, label, type, key, dbTable, onChange, min, max, step)
    local row = CreatePropertyRow(parent, label, type, key, dbTable, onChange, min, max, step)
    row:SetParent(parent)
    row:SetPoint("TOPLEFT", 10, -parent.rowCount * (ROW_HEIGHT + 5))
    parent.rowCount = parent.rowCount + 1
    return row
end

local function CreateSubLabel(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then
        ns.GUI:SetFont(label, 12, "")
    else
         label:SetFont(STANDARD_TEXT_FONT, 12, "")
    end
    label:SetText(text)
    label:SetTextColor(unpack(GUI.Colors.accent))
    label:SetPoint("TOPLEFT", 10, -parent.rowCount * (ROW_HEIGHT + 5))
    parent.rowCount = parent.rowCount + 0.8
    return label
end

local anchorOptions = {
    {value = "TOPLEFT", text = "Top Left"},
    {value = "TOP", text = "Top"},
    {value = "TOPRIGHT", text = "Top Right"},
    {value = "LEFT", text = "Left"},
    {value = "CENTER", text = "Center"},
    {value = "RIGHT", text = "Right"},
    {value = "BOTTOMLEFT", text = "Bottom Left"},
    {value = "BOTTOM", text = "Bottom"},
    {value = "BOTTOMRIGHT", text = "Bottom Right"},
}

-- ═══════════════════════════════════════════════════════════════
-- BUILDERS
-- ═══════════════════════════════════════════════════════════════

-- 1. Keybindings
local function BuildGUICDMKeybinds(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local abs = db.actionbars
    local guicdm = abs.guicdm
    if not guicdm then -- safe init if defaults failed or old profile
        guicdm = { enabled = true, fontSize = 12, anchor = "TOPRIGHT", offsetX = 0, offsetY = 0, color = {1,1,1,1} }
        abs.guicdm = guicdm
    end
    if not guicdm.barStyles then
        guicdm.barStyles = {
            essential = { fontSize = 12, color = {1, 1, 1, 1} },
            utility = { fontSize = 12, color = {1, 1, 1, 1} },
            custom = { fontSize = 12, color = {1, 1, 1, 1} },
            additionalCustom = { fontSize = 12, color = {1, 1, 1, 1} },
            trinket = { fontSize = 12, color = {1, 1, 1, 1} },
            item = { fontSize = 12, color = {1, 1, 1, 1} },
            itemSpell = { fontSize = 12, color = {1, 1, 1, 1} },
        }
    end

    content.rowCount = 0
    local refresh = function() if ns.RefreshGUICDMKeybinds then ns.RefreshGUICDMKeybinds() end end

    local header = GUI:CreateSectionHeader(content, "Cooldown Manager Keybindings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    -- Info Box
    local infoBox = GUI:CreateInfoBox(content, "Maps your Action Bar keybinds to the cooldown icons.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.5

    AddRow(content, "Enable Keybinds on CDM", "checkbox", "enabled", guicdm, refresh)
    

    
    CreateSubLabel(content, "Global Appearance (Fallback)")
    AddRow(content, "Global Font Size", "slider", 8, 32, "fontSize", guicdm, refresh, 1)
    AddRow(content, "Global Text Color", "color", "color", guicdm, refresh)
    
    CreateSubLabel(content, "Global Position")
    AddRow(content, "Anchor Point", "dropdown", anchorOptions, "anchor", guicdm, refresh)
    AddRow(content, "X-Offset", "slider", -20, 20, "offsetX", guicdm, refresh, 1)
    AddRow(content, "Y-Offset", "slider", -20, 20, "offsetY", guicdm, refresh, 1)

    local barList = {
        { key = "essential", label = "Essential Bar" },
        { key = "utility", label = "Utility Bar" },
        { key = "custom", label = "Custom Bar" },
        { key = "additionalCustom", label = "Additional Custom Bar" },
        { key = "trinket", label = "Trinket Bar" },
        { key = "item", label = "Item Bar" },
        { key = "itemSpell", label = "Item Spell Bar" },
    }

    for _, barInfo in ipairs(barList) do
        CreateSubLabel(content, barInfo.label)
        local barStyle = guicdm.barStyles[barInfo.key]
        AddRow(content, "Enable on " .. barInfo.label, "checkbox", barInfo.key, guicdm.bars, refresh)
        AddRow(content, "Font Size", "slider", 8, 32, "fontSize", barStyle, refresh, 1)
        AddRow(content, "Text Color", "color", "color", barStyle, refresh)
        content.rowCount = content.rowCount + 0.5
    end

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. CDM Centering
local function BuildCDMCentering(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local centering = db.actionbars.cdmCentering
    if not centering then
        centering = { enabled = true, essential = true, utility = true }
        db.actionbars.cdmCentering = centering
    end

    content.rowCount = 0
    local refresh = function() 
        -- Trigger centering logic (impl pending)
        if ns.GUICDM_Keybinds and ns.GUICDM_Keybinds.UpdateCentering then
            ns.GUICDM_Keybinds:UpdateCentering()
        end
    end
    
    local header = GUI:CreateSectionHeader(content, "Horizontal Centering")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    -- Info Box
    local infoBox = GUI:CreateInfoBox(content, "Centers the second row of icons relative to the first row (if multiple rows exist).")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.2
    
    AddRow(content, "Enable Centering for BCDM", "checkbox", "enabled", centering, refresh)
    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Module Specific Settings")
    AddRow(content, "Enable Centering for Essential Bar", "checkbox", "essential", centering, refresh)
    AddRow(content, "Enable Centering for Utility Bar", "checkbox", "utility", centering, refresh)
    

    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 3. Utils (Button Glow)
local function BuildUtils(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local utils = db.actionbars.guicdm.utils
    if not utils then
        utils = { buttonGlow = false }
        db.actionbars.guicdm.utils = utils
    end

    content.rowCount = 0
    local refresh = function() 
        if ns.GUICDM_Keybinds and ns.GUICDM_Keybinds.UpdateUtils then
            ns.GUICDM_Keybinds:UpdateUtils()
        end
    end
    
    local header = GUI:CreateSectionHeader(content, "Button Glow on Key press")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    local infoBox = GUI:CreateInfoBox(content, "Shows a highlight on BCDM icons when their keybind is pressed.\n\n|cffFFCC00Note:|r Keybindings and the specific bar (Essential, Utility, etc.) must be enabled for this to work.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.2
    
    AddRow(content, "Enable Button Glow on Keybind Press", "checkbox", "buttonGlow", utils, refresh)
    

    
    AddRow(content, "Hide Keybind Text (Glow still works)", "checkbox", "hideKeybindText", utils, refresh)
    AddRow(content, "Glow Color", "color", "buttonGlowColor", utils, refresh)
    

    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 4. Castbar Ticks
local function BuildCastbar(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local ticks = db.general.castbarTicks
    if not ticks then return end 

    content.rowCount = 0
    local refresh = function() 
        if ns.CastbarTicks and ns.CastbarTicks.SetupHooks then
            ns.CastbarTicks:SetupHooks()
        end
    end
    
    -- Disintegrate
    local dHeader = GUI:CreateSectionHeader(content, "Disintegrate Ticks (Evoker)")
    dHeader:SetPoint("TOPLEFT", 10, -10)
    
    local dFrame = CreateFrame("Frame", nil, content)
    dFrame:SetSize(600, 200) -- Increased height for vertical stack
    dFrame:SetPoint("TOPLEFT", dHeader, "BOTTOMLEFT", 0, -10)
    
    GUI:CreateCheckbox(dFrame, "Enable on UnhaltedUnitFrames", "enableUUF", ticks.disintegrate, function(v) 
        refresh()
    end):SetPoint("TOPLEFT", 0, 0)
    
    GUI:CreateCheckbox(dFrame, "Enable on BetterCooldownManager", "enableBCDM", ticks.disintegrate, function(v) 
        refresh()
    end):SetPoint("TOPLEFT", 0, -30)
    
    local dWidth = GUI:CreateSlider(dFrame, "Width", 1, 10, "tickWidth", ticks.disintegrate, function(v)
        refresh()
    end)
    dWidth:SetPoint("TOPLEFT", 0, -70)
    dWidth.label:SetText("Tick Width")
    
    local dHeight = GUI:CreateSlider(dFrame, "Height %", 0.1, 1.0, "tickHeight", ticks.disintegrate, function(v)
        refresh()
    end, 0.05)
    dHeight:SetPoint("TOPLEFT", 0, -110)
    dHeight.label:SetText("Tick Height")
    
    local dColor = GUI:CreateColorPicker(dFrame, "Color", "tickColor", ticks.disintegrate, function(r, g, b, a)
        refresh()
    end)
    dColor:SetPoint("TOPLEFT", 0, -150)
    dColor.label:SetText("Tick Color")

    -- Mind Flay
    local mHeader = GUI:CreateSectionHeader(content, "Mind Flay Ticks (Priest)")
    mHeader:SetPoint("TOPLEFT", dFrame, "BOTTOMLEFT", 0, -10)
    
    local mFrame = CreateFrame("Frame", nil, content)
    mFrame:SetSize(600, 200)
    mFrame:SetPoint("TOPLEFT", mHeader, "BOTTOMLEFT", 0, -10)
    
    GUI:CreateCheckbox(mFrame, "Enable on UnhaltedUnitFrames", "enableUUF", ticks.mindflay, function(v) 
        refresh()
    end):SetPoint("TOPLEFT", 0, 0)
    
    GUI:CreateCheckbox(mFrame, "Enable on BetterCooldownManager", "enableBCDM", ticks.mindflay, function(v) 
        refresh()
    end):SetPoint("TOPLEFT", 0, -30)
    
    local mWidth = GUI:CreateSlider(mFrame, "Width", 1, 10, "tickWidth", ticks.mindflay, function(v)
        refresh()
    end)
    mWidth:SetPoint("TOPLEFT", 0, -70)
    mWidth.label:SetText("Tick Width")
    
    local mHeight = GUI:CreateSlider(mFrame, "Height %", 0.1, 1.0, "tickHeight", ticks.mindflay, function(v)
        refresh()
    end, 0.05)
    mHeight:SetPoint("TOPLEFT", 0, -110)
    mHeight.label:SetText("Tick Height")
    
    local mColor = GUI:CreateColorPicker(mFrame, "Color", "tickColor", ticks.mindflay, function(r, g, b, a)
        refresh()
    end)
    mColor:SetPoint("TOPLEFT", 0, -150)
    mColor.label:SetText("Tick Color")
    
    content.rowCount = 15
    content:SetHeight(500)
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN PAGE REGISTER
-- ═══════════════════════════════════════════════════════════════

ns.GUI:RegisterPage("cdmutils", {
    title = "UI Utilities",
    OnBuild = function(content)
        -- Hide default scrollframe parent
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Create SubTabs
        local subTabs = GUI:CreateSubTabs(scrollFrame, {
            { name = "Keybindings", builder = BuildGUICDMKeybinds },
            { name = "CDM Centering", builder = BuildCDMCentering },
            { name = "Button Glow", builder = BuildUtils },
            { name = "Castbar", builder = BuildCastbar },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
