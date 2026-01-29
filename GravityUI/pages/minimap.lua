-- GravityUI - Minimap Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: SETTINGS TAB (Tab 1)
-- ═══════════════════════════════════════════════════════════════
local function BuildSettingsTab(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local db = ns.GetDB()
    if not db or not db.minimap then return end
    
    local m = db.minimap
    local z = m.zoneTextConfig or {}
    local refresh = ns.RefreshMinimap or function() end
    
    local ROW_HEIGHT = 30
    local LABEL_WIDTH = 220
    local WIDGET_WIDTH = 250
    
    -- Helper: Property Row
    local function CreatePropertyRow(container, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
        local row = CreateFrame("Frame", nil, container)
        row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
        
        -- Label
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        GUI:SetFont(label, 12, "OUTLINE")
        label:SetJustifyH("LEFT")
        label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
        label:SetPoint("LEFT", 0, 0)
        label:SetText(labelText)
        label:SetTextColor(unpack(GUI.Colors.text))
        
        -- Widget
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
    
    -- Helper: Add Row to layout
    local function AddRow(container, label, type, ...)
        local row = CreatePropertyRow(container, label, type, ...)
        local count = container.rowCount or 0
        row:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
        container.rowCount = count + 1
        return row
    end

    local y = -10
    local PAD = 10
    
    -- To simulate content flow with sections, we use yOffset and content.rowCount logic manually or adapting Helpers
    -- Since we are inside a new container, we can just use CreateSectionHeader which automatically spaces
    content._hasContent = false
    
    -- 1. Minimap Settings
    local genHeader = GUI:CreateSectionHeader(content, "General Settings")
    genHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - genHeader.gap
    
    -- Use a clean Frame container for rows to manage relative Y easily? 
    -- Or just keep using y. Let's use y.
    
    -- We need to Bridge AddRow to use 'y' instead of container.rowCount?
    -- No, let's make a container for each section to use existing AddRow logic.
    
    local genContainer = CreateFrame("Frame", nil, content)
    genContainer:SetPoint("TOPLEFT", PAD, y)
    genContainer:SetWidth(GUI.CONTENT_WIDTH - 20)
    genContainer.rowCount = 0
    
    AddRow(genContainer, "Show Minimap", "checkbox", "enabled", m, refresh)
    AddRow(genContainer, "Lock Minimap", "checkbox", "lock", m, refresh)
    AddRow(genContainer, "Show Who Pinged", "checkbox", "showPing", m, refresh)
    AddRow(genContainer, "Auto Zoom Out", "checkbox", "autoZoom", m, refresh)
    AddRow(genContainer, "Rotate Minimap", "checkbox", "rotate", m, refresh)
    
    local shapeOptions = { {value = "SQUARE", text = "Square"}, {value = "ROUND", text = "Round"} }
    AddRow(genContainer, "Shape", "dropdown", shapeOptions, "shape", m, refresh)
    AddRow(genContainer, "Size", "slider", 100, 300, "size", m, refresh, 1)
    AddRow(genContainer, "Scale", "slider", 0.5, 2.0, "scale", m, refresh, 0.1)
    
    genContainer:SetHeight(10 + (genContainer.rowCount * (ROW_HEIGHT + 5)))
    y = y - genContainer:GetHeight() - 10
    
    -- 2. Style
    local styleHeader = GUI:CreateSectionHeader(content, "Style")
    styleHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - styleHeader.gap
    
    local styleContainer = CreateFrame("Frame", nil, content)
    styleContainer:SetPoint("TOPLEFT", PAD, y)
    styleContainer:SetWidth(GUI.CONTENT_WIDTH - 20)
    styleContainer.rowCount = 0
    
    AddRow(styleContainer, "Border Size", "slider", 0, 10, "borderSize", m, refresh, 1)
    AddRow(styleContainer, "Use Theme Color", "checkbox", "useThemeColorBorder", m, refresh)
    AddRow(styleContainer, "Border Color", "color", "borderColor", m, refresh)
    AddRow(styleContainer, "Hide Blizzard Borders", "checkbox", "hideBlizzardBorder", m, refresh)
    
    styleContainer:SetHeight(10 + (styleContainer.rowCount * (ROW_HEIGHT + 5)))
    y = y - styleContainer:GetHeight() - 10
    
    -- 3. Zone Label Settings
    local zoneHeader = GUI:CreateSectionHeader(content, "Zone Label Settings")
    zoneHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - zoneHeader.gap
    
    local zoneContainer = CreateFrame("Frame", nil, content)
    zoneContainer:SetPoint("TOPLEFT", PAD, y)
    zoneContainer:SetWidth(GUI.CONTENT_WIDTH - 20)
    zoneContainer.rowCount = 0
    
    AddRow(zoneContainer, "Show Zone Text", "checkbox", "showZoneText", m, refresh)
    AddRow(zoneContainer, "All Caps", "checkbox", "allCaps", z, refresh)
    AddRow(zoneContainer, "Use Theme Color", "checkbox", "useThemeColor", z, refresh)
    AddRow(zoneContainer, "Use Blizzard Zone Colors", "checkbox", "useBlizzardZoneColors", z, refresh)
    AddRow(zoneContainer, "Font Color", "color", "colorNormal", z, refresh)
    AddRow(zoneContainer, "Font Size", "slider", 8, 32, "fontSize", z, refresh, 1)
    AddRow(zoneContainer, "X Offset", "slider", -100, 100, "offsetX", z, refresh, 1)
    AddRow(zoneContainer, "Y Offset", "slider", -50, 50, "offsetY", z, refresh, 1)
    
    zoneContainer:SetHeight(10 + (zoneContainer.rowCount * (ROW_HEIGHT + 5)))
    y = y - zoneContainer:GetHeight() - 10
    
    content:SetHeight(math.abs(y) + 50)
end

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: ELEMENTS TAB (Tab 2)
-- ═══════════════════════════════════════════════════════════════
local function BuildElementsTab(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local db = ns.GetDB()
    if not db or not db.minimap then return end
    
    local m = db.minimap
    local e = m.dungeonEye or {}
    local refresh = ns.RefreshMinimap or function() end
    
    local ROW_HEIGHT = 30
    local LABEL_WIDTH = 220
    local WIDGET_WIDTH = 250
    
    -- Helper: Property Row (Duplicated for closure access)
    local function CreatePropertyRow(container, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
        local row = CreateFrame("Frame", nil, container)
        row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
        
        -- Label
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        GUI:SetFont(label, 12, "OUTLINE")
        label:SetJustifyH("LEFT")
        label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
        label:SetPoint("LEFT", 0, 0)
        label:SetText(labelText)
        label:SetTextColor(unpack(GUI.Colors.text))
        
        -- Widget
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
        end
        return row
    end
    
    -- Helper: Add Row
    local function AddRow(container, label, type, ...)
        local row = CreatePropertyRow(container, label, type, ...)
        local count = container.rowCount or 0
        row:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
        container.rowCount = count + 1
        return row
    end

    local y = -10
    local PAD = 10
    content._hasContent = false
    
    -- 1. Minimap Elements (Toggles)
    local elemHeader = GUI:CreateSectionHeader(content, "Minimap Elements (Toggles)")
    elemHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - elemHeader.gap
    
    -- Info Text
    local info = GUI:CreateInfoBox(content, "|cffFFCC00Note:|r Some elements may require a /reload.")
    info:SetPoint("TOPLEFT", PAD, y)
    y = y - info:GetHeight() - 10
    
    local elemContainer = CreateFrame("Frame", nil, content)
    elemContainer:SetPoint("TOPLEFT", PAD, y)
    elemContainer:SetWidth(GUI.CONTENT_WIDTH - 20)
    elemContainer.rowCount = 0
    
    AddRow(elemContainer, "Preview / Drag & Drop Mode", "checkbox", "settingsPreview", m, refresh)
    AddRow(elemContainer, "Show Coordinates", "checkbox", "showCoords", m, refresh)
    AddRow(elemContainer, "Show Clock", "checkbox", "showClock", m, refresh)
    AddRow(elemContainer, "Show Calendar", "checkbox", "showCalendar", m, refresh)
    AddRow(elemContainer, "Show Mail", "checkbox", "showMail", m, refresh)
    AddRow(elemContainer, "Show Tracking", "checkbox", "showTracking", m, refresh)
    AddRow(elemContainer, "Hide Quest Blobs", "checkbox", "hideQuestBlobs", m, refresh)
    AddRow(elemContainer, "Show Crafting", "checkbox", "showCraftingOrder", m, refresh)
    AddRow(elemContainer, "Show Missions", "checkbox", "showMissions", m, refresh)
    AddRow(elemContainer, "Show Difficulty", "checkbox", "showDifficulty", m, refresh)
    AddRow(elemContainer, "Show Addon Compartment", "checkbox", "showAddonCompartment", m, refresh)
    AddRow(elemContainer, "Show Zoom Buttons", "checkbox", "showZoomButtons", m, refresh)
    
    elemContainer:SetHeight(10 + (elemContainer.rowCount * (ROW_HEIGHT + 5)))
    y = y - elemContainer:GetHeight() - 10
    
    -- 2. Dungeon Eye
    local eyeHeader = GUI:CreateSectionHeader(content, "Dungeon Eye (LFG)")
    eyeHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - eyeHeader.gap
    
    local eyeContainer = CreateFrame("Frame", nil, content)
    eyeContainer:SetPoint("TOPLEFT", PAD, y)
    eyeContainer:SetWidth(GUI.CONTENT_WIDTH - 20)
    eyeContainer.rowCount = 0
    
    AddRow(eyeContainer, "Enable Dungeon Eye", "checkbox", "enabled", e, refresh)
    AddRow(eyeContainer, "Show Preview", "checkbox", "preview", e, refresh)
    
    local cornerOpts = {
        {value = "TOPLEFT", text = "Top Left"},
        {value = "TOPRIGHT", text = "Top Right"},
        {value = "BOTTOMLEFT", text = "Bottom Left"},
        {value = "BOTTOMRIGHT", text = "Bottom Right"},
    }
    AddRow(eyeContainer, "Corner Position", "dropdown", cornerOpts, "corner", e, refresh)
    AddRow(eyeContainer, "X Offset", "slider", -50, 50, "offsetX", e, refresh, 0.5)
    AddRow(eyeContainer, "Y Offset", "slider", -50, 50, "offsetY", e, refresh, 0.5)
    AddRow(eyeContainer, "Scale", "slider", 0.5, 2.0, "scale", e, refresh, 0.1)
    
    eyeContainer:SetHeight(10 + (eyeContainer.rowCount * (ROW_HEIGHT + 5)))
    y = y - eyeContainer:GetHeight() - 10
    
    -- 3. Advanced Positioning
    local posHeader = GUI:CreateSectionHeader(content, "Advanced Positioning")
    posHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - posHeader.gap
    
    local posContainer = CreateFrame("Frame", nil, content)
    posContainer:SetPoint("TOPLEFT", PAD, y)
    posContainer:SetWidth(GUI.CONTENT_WIDTH - 20)
    -- Manual layout inside posContainer
    local posY = -10
    
    local function CreatePosRow(label, key)
        if m[key] == nil then m[key] = {} end
        local cfg = m[key]
        
        -- Label
        local l = posContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        GUI:SetFont(l, 13, "OUTLINE", C.accentLight)
        l:SetPoint("TOPLEFT", 10, posY)
        l:SetText(label)
        posY = posY - 20
        
        -- X
        local s1 = GUI:CreateSlider(posContainer, "X", -500, 500, "offsetX", cfg, refresh, 0.5)
        s1:SetPoint("TOPLEFT", 10, posY)
        s1:SetSize(180, 40)
        
        -- Y
        local s2 = GUI:CreateSlider(posContainer, "Y", -500, 500, "offsetY", cfg, refresh, 0.5)
        s2:SetPoint("TOPLEFT", 210, posY)
        s2:SetSize(180, 40)
        
        -- Scale
        local s3 = GUI:CreateSlider(posContainer, "Scale", 0.5, 2.0, "scale", cfg, refresh, 0.1)
        s3:SetPoint("TOPLEFT", 410, posY)
        s3:SetSize(180, 40)
        
        posY = posY - 50
    end

    CreatePosRow("Mail Icon", "mailConfig")
    CreatePosRow("Tracking Icon", "trackingConfig")
    CreatePosRow("Crafting Icon", "craftingConfig")
    CreatePosRow("Missions Icon", "missionsConfig")
    CreatePosRow("Difficulty Icon", "difficultyConfig")
    CreatePosRow("Addon Compartment", "addonCompartmentConfig")
    CreatePosRow("Zoom Buttons", "zoomConfig")
    CreatePosRow("Calendar Icon", "calendarConfig")
    CreatePosRow("Clock", "clockConfig")
    CreatePosRow("Coordinates", "coordsConfig")
    
    posContainer:SetHeight(math.abs(posY) + 10)
    y = y - posContainer:GetHeight() - 10

    content:SetHeight(math.abs(y) + 50)
end


ns.GUI:RegisterPage("minimap", {
    title = "Minimap",
    OnBuild = function(content)
        -- Hide default scrollframe of the main container
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Create SubTabs
        local subTabs = GUI:CreateSubTabs(scrollFrame, {
            { name = "Minimap Settings", builder = BuildSettingsTab },
            { name = "Minimap Elements", builder = BuildElementsTab },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
