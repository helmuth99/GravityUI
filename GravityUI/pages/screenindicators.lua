-- GravityUI - UI Indicators Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

-- ═══════════════════════════════════════════════════════════════
-- HELPER: PROPERTY ROW
-- ═══════════════════════════════════════════════════════════════
local ROW_HEIGHT = 30
local LABEL_WIDTH = 220
local WIDGET_WIDTH = 250

local function CreatePropertyRow(parent, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
    
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(label, 12, "OUTLINE")
    label:SetJustifyH("LEFT")
    label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
    label:SetPoint("LEFT", 0, 0)
    label:SetText(labelText)
    label:SetTextColor(unpack(ns.Colors.text))
    
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
    elseif widgetType == "input" then
        widget = GUI:CreateInput(row, "", arg1, arg2, arg3)
        widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
        widget:SetWidth(WIDGET_WIDTH)
        widget.editBox:SetWidth(WIDGET_WIDTH)
    end
    return row
end

local function AddRow(container, label, type, ...)
    local row = CreatePropertyRow(container, label, type, ...)
    local count = container.rowCount or 0
    row:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
    container.rowCount = count + 1
    -- container:SetHeight(10 + (container.rowCount * (ROW_HEIGHT + 5))) -- Done at end
    return row
end

local function CreateSubLabel(container, text)
    local count = container.rowCount or 0
    local sh = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sh:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
    sh:SetText(text)
    sh:SetTextColor(unpack(GUI.Colors.accent))
    GUI:SetFont(sh, 12, "OUTLINE")
    container.rowCount = count + 1
end

-- ═══════════════════════════════════════════════════════════════
-- BUILDERS
-- ═══════════════════════════════════════════════════════════════

-- 1. Cursor
local function BuildCursor(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbS = db.screenindicators
    local c = dbS.cursor
    content.rowCount = 0
    local refresh = function() if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end end

    local header = GUI:CreateSectionHeader(content, "Cursor Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0

    CreateSubLabel(content, "Enable & Logic")
    AddRow(content, "Enable Cursor Ring", "checkbox", "enabled", c, refresh)
    AddRow(content, "Hide Out of Combat", "checkbox", "hideOutOfCombat", c, refresh)
    AddRow(content, "Hide on Right Click", "checkbox", "hideOnRightClick", c, refresh)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Appearance")
    local ringStyles = {{value="thin", text="Thin"},{value="standard", text="Standard"},{value="thick", text="Thick"},{value="solid", text="Solid"}}
    AddRow(content, "Ring Style", "dropdown", ringStyles, "ringStyle", c, refresh)
    AddRow(content, "Ring Size", "slider", 10, 100, "ringSize", c, refresh, 1)
    
    local reticleStyles = {{value="dot", text="Dot"},{value="cross", text="Crosshair (Atlas)"},{value="chevron", text="Chevron (Atlas)"},{value="diamond", text="Diamond (Atlas)"}}
    AddRow(content, "Reticle Style", "dropdown", reticleStyles, "reticleStyle", c, refresh)
    AddRow(content, "Reticle Size", "slider", 1, 40, "reticleSize", c, refresh, 1)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Colors & Alpha")
    AddRow(content, "Use Theme Color", "checkbox", "useThemeColor", c, refresh)
    AddRow(content, "Custom Color", "color", "customColor", c, refresh)
    AddRow(content, "Combat Alpha", "slider", 0, 1, "inCombatAlpha", c, refresh, 0.1)
    AddRow(content, "Out of Combat Alpha", "slider", 0, 1, "outCombatAlpha", c, refresh, 0.1)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Global Cooldown (GCD)")
    AddRow(content, "Track GCD", "checkbox", "gcdEnabled", c, refresh)
    AddRow(content, "GCD Ring Fade", "slider", 0, 1, "gcdFadeRing", c, refresh, 0.05)
    AddRow(content, "Reverse Animation", "checkbox", "gcdReverse", c, refresh)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. Crosshair
local function BuildCrosshair(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbS = db.screenindicators
    local ch = dbS.crosshair
    content.rowCount = 0
    local refresh = function() if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end end

    local header = GUI:CreateSectionHeader(content, "Crosshair Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0

    CreateSubLabel(content, "Enable & Core Settings")
    AddRow(content, "Enable Crosshair", "checkbox", "enabled", ch, refresh)
    AddRow(content, "Only in Combat", "checkbox", "onlyInCombat", ch, refresh)
    AddRow(content, "Hide until Out of Range", "checkbox", "hideUntilOutOfRange", ch, refresh)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Appearance")
    AddRow(content, "Size", "slider", 2, 50, "size", ch, refresh, 1)
    AddRow(content, "Thickness", "slider", 1, 10, "thickness", ch, refresh, 1)
    AddRow(content, "Border Size", "slider", 0, 5, "borderSize", ch, refresh, 1)
    
    local strataOptions = {{value="BACKGROUND", text="Background"},{value="LOW", text="Low"},{value="MEDIUM", text="Medium"},{value="HIGH", text="High"},{value="DIALOG", text="Dialog"}}
    AddRow(content, "Frame Strata", "dropdown", strataOptions, "strata", ch, refresh)
    
    CreateSubLabel(content, "Colors")
    AddRow(content, "Use Theme Color", "checkbox", "useThemeColor", ch, refresh)
    AddRow(content, "Crosshair Color", "color", "customColor", ch, refresh)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Range Check")
    AddRow(content, "Change Color on Range", "checkbox", "changeColorOnRange", ch, refresh)
    AddRow(content, "Out of Range Color", "color", "outOfRangeColor", ch, refresh)
    AddRow(content, "Combat Only (Range)", "checkbox", "rangeColorInCombatOnly", ch, refresh)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 3. Combat Status
local function BuildCombatStatus(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbS = db.screenindicators
    local cs = dbS.combatStatus
    content.rowCount = 0
    local refresh = function() if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end end

    local header = GUI:CreateSectionHeader(content, "Combat Status Indicator")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0

    CreateSubLabel(content, "Enable & Preview")
    AddRow(content, "Enable Indicator", "checkbox", "enabled", cs, refresh)
    
    local previewRow = CreateFrame("Frame", nil, content)
    previewRow:SetSize(content:GetWidth() - 20, 30)
    previewRow:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    
    local btnEnter = GUI:CreateButton(previewRow, "+Combat", 180, 24, function() ns.ScreenIndicators.PreviewCombatStatus("+Combat") end)
    btnEnter:SetPoint("LEFT", previewRow, "LEFT", 140, 0)
    
    local btnLeave = GUI:CreateButton(previewRow, "-Combat", 180, 24, function() ns.ScreenIndicators.PreviewCombatStatus("-Combat") end)
    btnLeave:SetPoint("LEFT", btnEnter, "RIGHT", 10, 0)
    
    content.rowCount = content.rowCount + 1.3
    
    CreateSubLabel(content, "Appearance")
    AddRow(content, "Font Size", "slider", 10, 60, "fontSize", cs, refresh, 1)
    AddRow(content, "Display Time (sec)", "slider", 0.1, 5, "displayTime", cs, refresh, 0.1)
    AddRow(content, "Fade Duration (sec)", "slider", 0.1, 2, "fadeTime", cs, refresh, 0.1)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Position")
    AddRow(content, "X Offset", "slider", -1000, 1000, "xOffset", cs, refresh, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "yOffset", cs, refresh, 1)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Colors")
    AddRow(content, "Enter Combat Color", "color", "enterCombatColor", cs, refresh)
    AddRow(content, "Leave Combat Color", "color", "leaveCombatColor", cs, refresh)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 4. Pet
local function BuildPet(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbS = db.screenindicators
    local ps = dbS.petWarnings
    content.rowCount = 0
    local refresh = function() if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end end

    local header = GUI:CreateSectionHeader(content, "Pet Info Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0

    CreateSubLabel(content, "Enable & Preview")
    AddRow(content, "Enable Pet Warnings", "checkbox", "enabled", ps, refresh)
    
    local petPreviewRow = CreateFrame("Frame", nil, content)
    petPreviewRow:SetSize(content:GetWidth() - 20, 30)
    petPreviewRow:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    
    local btnDead = GUI:CreateButton(petPreviewRow, "Dead / Missing", 180, 24, function() ns.ScreenIndicators.PreviewPetWarning("petDead") end)
    btnDead:SetPoint("LEFT", petPreviewRow, "LEFT", 140, 0)
    
    local btnIdle = GUI:CreateButton(petPreviewRow, "Not Attacking", 180, 24, function() ns.ScreenIndicators.PreviewPetWarning("petIdle") end)
    btnIdle:SetPoint("LEFT", btnDead, "RIGHT", 10, 0)
    
    content.rowCount = content.rowCount + 1.3
    
    CreateSubLabel(content, "Warning Types")
    AddRow(content, "Pet Dead / Missing", "checkbox", "petDeadWarning", ps, refresh)
    AddRow(content, "Pet Not Attacking", "checkbox", "petAttackWarning", ps, refresh)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Custom Warning Text")
    AddRow(content, "Dead / Missing Text", "input", "petDeadText", ps, refresh)
    AddRow(content, "Not Attacking Text", "input", "petAttackText", ps, refresh)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Appearance")
    AddRow(content, "Font Size", "slider", 10, 60, "fontSize", ps, refresh, 1)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Position")
    AddRow(content, "X Offset", "slider", -1000, 1000, "xOffset", ps, refresh, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "yOffset", ps, refresh, 1)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Colors")
    AddRow(content, "Warning use Theme Color", "checkbox", "useThemeColor", ps, refresh)
    AddRow(content, "Warning Color", "color", "warningColor", ps, refresh)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN PAGE
-- ═══════════════════════════════════════════════════════════════
ns.GUI:RegisterPage("screenindicators", {
    title = "UI Indicators",
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
            { name = "Cursor", builder = BuildCursor },
            { name = "Crosshair", builder = BuildCrosshair },
            { name = "Combat Status", builder = BuildCombatStatus },
            { name = "Pet", builder = BuildPet },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
