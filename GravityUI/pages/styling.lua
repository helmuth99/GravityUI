local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = GUI.Colors

-- Initialize styling database structure if missing is handled in core/defaults.lua now

local ROW_HEIGHT = 30
local LABEL_WIDTH = 220
local WIDGET_WIDTH = 250

local function CreateStylingRow(container, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
    local row = CreateFrame("Frame", nil, container)
    row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
    
    -- Label
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(label, 12, "")
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
        
        if widget.editBox then
            widget.editBox:ClearAllPoints()
            widget.editBox:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
        end
        if widget.slider then
            widget.slider:ClearAllPoints()
            widget.slider:SetPoint("LEFT", widget, "LEFT", 0, 0)
            widget.slider:SetPoint("RIGHT", widget.editBox, "LEFT", -10, 0)
        end
        
    elseif widgetType == "dropdown" then
        -- Handle variable argument order for Dropdowns
        -- Pattern A (Existing): items, key, db, onChange
        -- Pattern B (New): key, db, onChange, items
        
        local items, key, db, change
        if type(arg1) == "table" and arg1[1] then
            -- Pattern A: arg1 is the items table
            items = arg1
            key = arg2
            db = arg3
            change = arg4
        else
            -- Pattern B: arg4 is the items table (or we assume standard order)
            items = arg4
            key = arg1
            db = arg2
            change = arg3
        end
        
        widget = GUI:CreateDropdown(row, "", items, key, db, change)
        widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
        widget:SetWidth(WIDGET_WIDTH)
        if widget.dropdown then
            widget.dropdown:ClearAllPoints()
            widget.dropdown:SetPoint("LEFT", widget, "LEFT", 0, 0)
            widget.dropdown:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
        end
        
    elseif widgetType == "color" then
         widget = GUI:CreateColorPicker(row, "", arg1, arg2, arg3)
         widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
    end
    
    return row, widget
end

--==============================================================================================================================================================================================
-- BUILDER: GAME MENU (Tab 1)
--==============================================================================================================================================================================================
local function BuildGameMenuPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    
    local header = GUI:CreateSectionHeader(content, "Game Menu Skinning")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    local row1 = CreateStylingRow(content, "Enable Game Menu Skinning", "checkbox", "enabled", ns.db.profile.styling.gamemenu, function()
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    local row2 = CreateStylingRow(content, "Show Gravity UI Button", "checkbox", "showGravityButton", ns.db.profile.styling.gamemenu, function()
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    row2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local row3 = CreateStylingRow(content, "Button Font Size", "slider", 8, 24, "buttonFontSize", ns.db.profile.styling.gamemenu, function()
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end, 1)
    row3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Background Color Customization
    local bgPickerRow -- Forward declare
    local row4 = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorBackground", ns.db.profile.styling.gamemenu, function(value)
        if bgPickerRow then
            if value then bgPickerRow:Show() else bgPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    row4:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRow = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", ns.db.profile.styling.gamemenu, function()
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    bgPickerRow:SetPoint("TOPLEFT", PAD, yOffset) -- Indenting not strictly needed if label is distinct, but let's keep consistent left align
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Initialize Visibility
    if not ns.db.profile.styling.gamemenu.disableThemeColorBackground then
        bgPickerRow:Hide()
    end
    
    -- Font Color Customization
    local fontPickerRow -- Forward declare
    local row6 = CreateStylingRow(content, "Don't Use Theme for Font", "checkbox", "disableThemeColorFont", ns.db.profile.styling.gamemenu, function(value)
        if fontPickerRow then
            if value then fontPickerRow:Show() else fontPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    row6:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    fontPickerRow = CreateStylingRow(content, "Font Color", "color", "customFontColor", ns.db.profile.styling.gamemenu, function()
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    fontPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Initialize Visibility
    if not ns.db.profile.styling.gamemenu.disableThemeColorFont then
        fontPickerRow:Hide()
    end
    

    
    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: CHAT BUBBLES (Tab 2)
--==============================================================================================================================================================================================
local function BuildChatBubblesPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    
    local header = GUI:CreateSectionHeader(content, "Chat Bubbles")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    local row1 = CreateStylingRow(content, "Enable Chat Bubble Skinning", "checkbox", "enabled", ns.db.profile.styling.chatBubbles, function()
        if ns.Styling and ns.Styling.SkinChatBubbles then ns.Styling:SkinChatBubbles() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local row2 = CreateStylingRow(content, "Font Size", "slider", 1, 32, "fontSize", ns.db.profile.styling.chatBubbles, function()
        if ns.Styling and ns.Styling.SkinChatBubbles then ns.Styling:SkinChatBubbles() end
    end, 1)
    row2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local outlineOptions = {
        { text = "None", value = "NONE" },
        { text = "Outline", value = "OUTLINE" },
        { text = "Thick Outline", value = "THICKOUTLINE" },
        { text = "Monochrome", value = "MONOCHROME" },
    }
    
    local row3 = CreateStylingRow(content, "Font Outline", "dropdown", outlineOptions, "fontOutline", ns.db.profile.styling.chatBubbles, function()
        if ns.Styling and ns.Styling.SkinChatBubbles then ns.Styling:SkinChatBubbles() end
    end)
    row3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: READY CHECK (Tab 3)
--==============================================================================================================================================================================================
local function BuildReadyCheckPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    local db = ns.db.profile.styling
    local rbDb = ns.db.profile.raidBuffs
    
    -- 1. READY CHECK FRAME STYLING
    local header = GUI:CreateSectionHeader(content, "Ready Check Frame")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    local row1 = CreateStylingRow(content, "Skin Ready Check Frame", "checkbox", "skinReadyCheck", db, function()
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    yOffset = yOffset - 5

    -- Background Color Customization
    local bgPickerRow -- Forward declare
    local rowBg = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorBackground", ns.db.profile.styling.readyCheck, function(value)
        if bgPickerRow then
            if value then bgPickerRow:Show() else bgPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    rowBg:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRow = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", ns.db.profile.styling.readyCheck, function()
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    bgPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not ns.db.profile.styling.readyCheck.disableThemeColorBackground then
        bgPickerRow:Hide()
    end
    
    -- Font Color Customization
    local fontPickerRow -- Forward declare
    local rowFn = CreateStylingRow(content, "Don't Use Theme for Font", "checkbox", "disableThemeColorFont", ns.db.profile.styling.readyCheck, function(value)
        if fontPickerRow then
            if value then fontPickerRow:Show() else fontPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    rowFn:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    fontPickerRow = CreateStylingRow(content, "Font Color", "color", "customFontColor", ns.db.profile.styling.readyCheck, function()
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    fontPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not ns.db.profile.styling.readyCheck.disableThemeColorFont then
        fontPickerRow:Hide()
    end
    yOffset = yOffset - 5

    local moveBtn = GUI:CreateButton(content, "Toggle Mover", 160, 24, function()
        if ns.Styling and ns.Styling.ToggleReadyCheckMover then ns.Styling:ToggleReadyCheckMover() end
    end)
    moveBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtn = GUI:CreateButton(content, "Reset Position", 160, 24, function()
        if ns.Styling and ns.Styling.ResetReadyCheckPosition then ns.Styling:ResetReadyCheckPosition() end
    end)
    resetBtn:SetPoint("LEFT", moveBtn, "RIGHT", 10, 0)
    yOffset = yOffset - 40
    

    
    content:SetHeight(math.abs(yOffset) + 40)
end

--==============================================================================================================================================================================================
-- BUILDER: KEYSTONE (Tab 4)
--==============================================================================================================================================================================================
local function BuildKeystonePanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    
    local header = GUI:CreateSectionHeader(content, "Keystone Frame")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    

    
    local row1 = CreateStylingRow(content, "Skin Keystone Window", "checkbox", "enabled", ns.db.profile.styling.keystone, function()
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Background Color Customization
    local bgPickerRow -- Forward declare
    local rowBg = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorBackground", ns.db.profile.styling.keystone, function(value)
        if bgPickerRow then
            if value then bgPickerRow:Show() else bgPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    rowBg:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRow = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", ns.db.profile.styling.keystone, function()
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    bgPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not ns.db.profile.styling.keystone.disableThemeColorBackground then
        bgPickerRow:Hide()
    end
    
    -- Font Color Customization
    local fontPickerRow -- Forward declare
    local rowFn = CreateStylingRow(content, "Don't Use Theme for Font", "checkbox", "disableThemeColorFont", ns.db.profile.styling.keystone, function(value)
        if fontPickerRow then
            if value then fontPickerRow:Show() else fontPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    rowFn:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    fontPickerRow = CreateStylingRow(content, "Font Color", "color", "customFontColor", ns.db.profile.styling.keystone, function()
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    fontPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not ns.db.profile.styling.keystone.disableThemeColorFont then
        fontPickerRow:Hide()
    end
    
    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: POWER BAR (Tab 5)
--==============================================================================================================================================================================================
local function BuildPowerBarPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    
    local header = GUI:CreateSectionHeader(content, "Encounter Power Bar")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    local infoBox = GUI:CreateInfoBox(content, "Replaces the encounter/quest power bar (e.g. Boss mechanics) with a styled version.")
    infoBox:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox:GetHeight() - 10
    
    local row1 = CreateStylingRow(content, "Enable Skinning", "checkbox", "enabled", ns.db.profile.styling.powerBar, function()
        if ns.Styling and ns.Styling.SkinPowerBar then ns.Styling:SkinPowerBar() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    

    
    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 140, 24, function()
        if ns.Styling and ns.Styling.TogglePowerBarMover then ns.Styling:TogglePowerBarMover() end
    end)
    moverBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtn = GUI:CreateButton(content, "Reset Position", 140, 24, function()
        if ns.Styling and ns.Styling.ResetPowerBarPosition then ns.Styling:ResetPowerBarPosition() end
    end)
    resetBtn:SetPoint("LEFT", moverBtn, "RIGHT", 10, 0)
    
    yOffset = yOffset - 50
    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: ALERTS (Tab 6)
--==============================================================================================================================================================================================
local function BuildAlertsPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    local db = ns.db.profile.styling.alerts
    
    local header = GUI:CreateSectionHeader(content, "Alert Frames & Toasts")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    local infoBox = GUI:CreateInfoBox(content, "Skins Blizzard alert frames (Achievements, Loot, etc.) and allows custom positioning.")
    infoBox:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox:GetHeight() - 10
    
    local row1 = CreateStylingRow(content, "Enable Skinning", "checkbox", "enabled", db, function()
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    

    
    -- Background Color Customization
    local bgPickerRow -- Forward declare
    local rowBg = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorBackground", db, function(value)
        if bgPickerRow then
            if value then bgPickerRow:Show() else bgPickerRow:Hide() end
        end
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    rowBg:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRow = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", db, function()
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    bgPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.disableThemeColorBackground then
        bgPickerRow:Hide()
    end
    
    -- Font Color Customization
    local fontPickerRow -- Forward declare
    local rowFn = CreateStylingRow(content, "Don't Use Theme for Font", "checkbox", "disableThemeColorFont", db, function(value)
        if fontPickerRow then
            if value then fontPickerRow:Show() else fontPickerRow:Hide() end
        end
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    rowFn:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    fontPickerRow = CreateStylingRow(content, "Font Color", "color", "customFontColor", db, function()
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    fontPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.disableThemeColorFont then
        fontPickerRow:Hide()
    end
    yOffset = yOffset - 5
    
    local moverBtn = GUI:CreateButton(content, "Toggle Movers", 140, 24, function()
        if ns.Alerts and ns.Alerts.ToggleMovers then ns.Alerts:ToggleMovers() end
    end)
    moverBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtn = GUI:CreateButton(content, "Reset Positions", 140, 24, function()
        if ns.Alerts and ns.Alerts.ResetPositions then ns.Alerts:ResetPositions() end
    end)
    resetBtn:SetPoint("LEFT", moverBtn, "RIGHT", 10, 0)
    
    local testBtn = GUI:CreateButton(content, "Test Alerts", 140, 24, function()
        if ns.Alerts and ns.Alerts.Test then ns.Alerts:Test() end
    end)
    testBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)
    yOffset = yOffset - 40

    local growOptions = {
        { text = "Grow Up", value = "UP" },
        { text = "Grow Down", value = "DOWN" },
    }

    local rowGrow1 = CreateStylingRow(content, "Alert Frame Growth", "dropdown", growOptions, "alertGrowDirection", db, function()
        if AlertFrame and AlertFrame.UpdateAnchors then AlertFrame:UpdateAnchors() end
    end)
    rowGrow1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    local rowGrow2 = CreateStylingRow(content, "Event Toast Growth", "dropdown", growOptions, "toastGrowDirection", db, function()
        if EventToastManagerFrame and EventToastManagerFrame.UpdateAnchor then EventToastManagerFrame:UpdateAnchor() end
    end)
    rowGrow2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    local rowOff1 = CreateStylingRow(content, "Alert Y-Offset", "slider", -400, 400, "alertYOffset", db, function()
        if AlertFrame and AlertFrame.UpdateAnchors then AlertFrame:UpdateAnchors() end
    end, 1)
    rowOff1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    local rowOff2 = CreateStylingRow(content, "Toast Y-Offset", "slider", -400, 400, "toastYOffset", db, function()
        if EventToastManagerFrame and EventToastManagerFrame.UpdateAnchor then EventToastManagerFrame:UpdateAnchor() end
    end, 1)
    rowOff2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: LOOT (Tab 7)
--==============================================================================================================================================================================================
local function BuildLootPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    local db = ns.db.profile.styling
    
    -- 1. LOOT WINDOW
    local header = GUI:CreateSectionHeader(content, "Loot Window")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    
    local infoBox1 = GUI:CreateInfoBox(content, "Replace Blizzard's loot window with a custom GUI-styled frame.")
    infoBox1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox1:GetHeight() - 10
    
    local row1 = CreateStylingRow(content, "Skin Loot Window", "checkbox", "enabled", db.loot, function()
        if ns.Loot and ns.Loot.Initialize then ns.Loot:Initialize() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local row2 = CreateStylingRow(content, "Loot Under Mouse", "checkbox", "lootUnderMouse", db.loot)
    row2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local row3 = CreateStylingRow(content, "Show Transmog Markers", "checkbox", "showTransmogMarkers", db.loot)
    row3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    -- Background Color Customization
    local bgPickerRow -- Forward declare
    local rowBg = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorBackground", db.loot, function(value)
        if bgPickerRow then
            if value then bgPickerRow:Show() else bgPickerRow:Hide() end
        end
        if ns.Loot and ns.Loot.RefreshStyling then ns.Loot.RefreshStyling() end
    end)
    rowBg:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRow = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", db.loot, function()
        if ns.Loot and ns.Loot.RefreshStyling then ns.Loot.RefreshStyling() end
    end)
    bgPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.loot.disableThemeColorBackground then
        bgPickerRow:Hide()
    end
    
    -- Font Color Customization
    local fontPickerRow -- Forward declare
    local rowFn = CreateStylingRow(content, "Don't Use Theme for Font", "checkbox", "disableThemeColorFont", db.loot, function(value)
        if fontPickerRow then
            if value then fontPickerRow:Show() else fontPickerRow:Hide() end
        end
        if ns.Loot and ns.Loot.RefreshStyling then ns.Loot.RefreshStyling() end
    end)
    rowFn:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    fontPickerRow = CreateStylingRow(content, "Font Color", "color", "customFontColor", db.loot, function()
        if ns.Loot and ns.Loot.RefreshStyling then ns.Loot.RefreshStyling() end
    end)
    fontPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.loot.disableThemeColorFont then
        fontPickerRow:Hide()
    end

    yOffset = yOffset - 10

    local moveBtn = GUI:CreateButton(content, "Toggle Mover", 160, 24, function()
        if ns.Loot and ns.Loot.ToggleMover then ns.Loot:ToggleMover() end
    end)
    moveBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtn = GUI:CreateButton(content, "Reset Position", 160, 24, function()
        if ns.Loot and ns.Loot.ResetPosition then ns.Loot:ResetPosition() end
    end)
    resetBtn:SetPoint("LEFT", moveBtn, "RIGHT", 10, 0)
    yOffset = yOffset - 50
    
    -- 2. LOOT ROLLS (GroupLoot)
    local header3 = GUI:CreateSectionHeader(content, "Loot Rolls (Group Loot)")
    header3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header3.gap
    yOffset = yOffset - 10
    
    local infoBox3 = GUI:CreateInfoBox(content, "Skin the Need/Greed roll frames.")
    infoBox3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox3:GetHeight() - 10
    
    local rowL1 = CreateStylingRow(content, "Enable Skinning", "checkbox", "enabled", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end)
    rowL1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Dimensions
    local rowL2 = CreateStylingRow(content, "Width", "slider", 150, 600, "width", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end, 1)
    rowL2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Renamed from Height to Item Icon Size per request
    local rowL3 = CreateStylingRow(content, "Item Icon Size", "slider", 20, 100, "height", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end, 1)
    rowL3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowL3a = CreateStylingRow(content, "Timer Bar Height", "slider", 1, 30, "timerHeight", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end, 1)
    rowL3a:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    -- Texture dropdown
    local textureList = {}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for _, name in pairs(LSM:List("statusbar")) do
            table.insert(textureList, { text = name, value = name })
        end
        table.sort(textureList, function(a, b) return a.text < b.text end)
    end
    
    local rowL4 = CreateStylingRow(content, "Bar Texture", "dropdown", textureList, "texture", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end)
    rowL4:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Font Settings
    local fontList = {}
    if LSM then
        for _, name in pairs(LSM:List("font")) do
            table.insert(fontList, { text = name, value = name })
        end
        table.sort(fontList, function(a, b) return a.text < b.text end)
    end
    
    local rowF1 = CreateStylingRow(content, "Item Name Font", "dropdown", fontList, "nameFont", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end)
    rowF1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowF2 = CreateStylingRow(content, "Item Name Size", "slider", 8, 32, "nameFontSize", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end, 1)
    rowF2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowF3 = CreateStylingRow(content, "Item Name Outline", "dropdown", {
        { text = "NONE", value = "NONE" },
        { text = "OUTLINE", value = "OUTLINE" },
        { text = "THICKOUTLINE", value = "THICKOUTLINE" },
        { text = "MONOCHROME", value = "MONOCHROME" },
        { text = "OUTLINE, MONOCHROME", value = "OUTLINE, MONOCHROME" },
    }, "nameFontOutline", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end)
    rowF3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowF4 = CreateStylingRow(content, "Item Name Color", "color", "nameFontColor", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end)
    rowF4:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5


    -- Background Settings
    local bgPickerRowRoll
    local rowBgRoll = CreateStylingRow(content, "Enable Background", "checkbox", "enableBackgroundColor", db.lootRoll, function(value)
        if bgPickerRowRoll then
            if value then bgPickerRowRoll:Show() else bgPickerRowRoll:Hide() end
        end
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end)
    rowBgRoll:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRowRoll = CreateStylingRow(content, "Background Color", "color", "backgroundColor", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end)
    bgPickerRowRoll:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    if not db.lootRoll.enableBackgroundColor then
        bgPickerRowRoll:Hide()
    end
    
    -- Spacing
    local rowL5 = CreateStylingRow(content, "Vertical Spacing", "slider", 0, 50, "spacing", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end, 1)
    rowL5:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    -- Growth Direction
    local growOptions = {
        { text = "Down", value = "DOWN" },
        { text = "Up", value = "UP" },
    }
    local rowL6 = CreateStylingRow(content, "Growth Direction", "dropdown", growOptions, "growDirection", db.lootRoll, function()
        if ns.Loot and ns.Loot.RefreshRolls then ns.Loot:RefreshRolls() end
    end)
    rowL6:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5


    -- Move Button
    local moveBtnRolls = GUI:CreateButton(content, "Toggle Mover", 160, 24, function()
         if ns.Loot and ns.Loot.ToggleRollMover then ns.Loot:ToggleRollMover() end
    end)
    moveBtnRolls:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtnRolls = GUI:CreateButton(content, "Reset Position", 160, 24, function()
         if ns.Loot and ns.Loot.ResetRollPosition then ns.Loot:ResetRollPosition() end
    end)
    resetBtnRolls:SetPoint("LEFT", moveBtnRolls, "RIGHT", 10, 0)
    
    yOffset = yOffset - 50

    -- Bonus Roll skinning toggle
    local rowBonus = CreateStylingRow(content, "Skin Bonus Roll Window", "checkbox", "skinBonusRoll", db.lootRoll, function(value)
        local f = _G.BonusRollFrame
        if f then
            if value then
                if ns.Loot and ns.Loot.SkinBonusRollFrame then
                    f.guiSkinned = nil
                    if f.guiBackdrop then f.guiBackdrop:Hide() end
                    ns.Loot.SkinBonusRollFrame()
                end
            else
                -- Restore Blizzard default: remove our backdrop
                if f.guiBackdrop then f.guiBackdrop:Hide() end
                f.guiSkinned = nil
            end
        end
    end)
    rowBonus:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    yOffset = yOffset - 10

    -- 3. LOOT HISTORY
    local header2 = GUI:CreateSectionHeader(content, "Loot History")
    header2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header2.gap
    yOffset = yOffset - 10
    
    
    local infoBox2 = GUI:CreateInfoBox(content, "Apply GUI styling to the loot roll results panel.")
    infoBox2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox2:GetHeight() - 10
    
    local rowH1 = CreateStylingRow(content, "Skin Loot History", "checkbox", "enabled", db.lootResults)
    rowH1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    -- Background Color
    local bgPickerRow2 -- Forward declare
    local rowBg2 = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorBackground", db.lootResults, function(value)
        if bgPickerRow2 then
            if value then bgPickerRow2:Show() else bgPickerRow2:Hide() end
        end
        if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot.RefreshHistoryStyling() end
    end)
    rowBg2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRow2 = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", db.lootResults, function()
        if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot.RefreshHistoryStyling() end
    end)
    bgPickerRow2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.lootResults.disableThemeColorBackground then
        bgPickerRow2:Hide()
    end
    
    -- Font Color
    local fontPickerRow2 -- Forward declare
    local rowFn2 = CreateStylingRow(content, "Don't Use Theme for Font", "checkbox", "disableThemeColorFont", db.lootResults, function(value)
        if fontPickerRow2 then
            if value then fontPickerRow2:Show() else fontPickerRow2:Hide() end
        end
        if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot.RefreshHistoryStyling() end
    end)
    rowFn2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    fontPickerRow2 = CreateStylingRow(content, "Font Color", "color", "customFontColor", db.lootResults, function()
        if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot.RefreshHistoryStyling() end
    end)
    fontPickerRow2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.lootResults.disableThemeColorFont then
        fontPickerRow2:Hide()
    end

    yOffset = yOffset - 60
    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: OBJECTIVES (Tab 9)
--==============================================================================================================================================================================================
local function BuildObjectivesPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    local db = ns.db.profile.styling.objectives
    
    local header = GUI:CreateSectionHeader(content, "Objective Tracker")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    
    local infoBox = GUI:CreateInfoBox(content, "Skin the default Blizzard Objective Tracker to match GravityUI.")
    infoBox:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox:GetHeight() - 10
    
    local row1 = CreateStylingRow(content, "Enable Styling", "checkbox", "objectiveTrackerSkinning", db, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowWidth = CreateStylingRow(content, "Header Width", "slider", 180, 400, "width", db, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end, 1)
    rowWidth:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Background Color
    local bgPickerRow -- Forward declare
    local rowBg = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorForBackground", db, function(value)
        if bgPickerRow then
            if value then bgPickerRow:Show() else bgPickerRow:Hide() end
        end
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    rowBg:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRow = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", db, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    bgPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.disableThemeColorForBackground then
        bgPickerRow:Hide()
    end

    local rowOpacity = CreateStylingRow(content, "Background Opacity", "slider", 0, 1, "backgroundOpacity", db, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end, 0.1)
    rowOpacity:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Font Color
    local fontPickerRow -- Forward declare
    local rowFont = CreateStylingRow(content, "Don't Use Theme for Headers", "checkbox", "disableThemeColorForHeaderFont", db, function(value)
        if fontPickerRow then
             if value then fontPickerRow:Show() else fontPickerRow:Hide() end
        end
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    rowFont:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    fontPickerRow = CreateStylingRow(content, "Header Text Color", "color", "customHeaderFontColor", db, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    fontPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.disableThemeColorForHeaderFont then
        fontPickerRow:Hide()
    end
    


    -- Cosmetic Bar Color
    local barPickerRow -- Forward declare
    local rowBar = CreateStylingRow(content, "Don't Use Theme for Cosmetic Bar", "checkbox", "disableThemeColor", db.cosmeticBar, function(value)
        if barPickerRow then
             if value then barPickerRow:Show() else barPickerRow:Hide() end
        end
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    rowBar:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    barPickerRow = CreateStylingRow(content, "Cosmetic Bar Color", "color", "color", db.cosmeticBar, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    barPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.cosmeticBar.disableThemeColor then
        barPickerRow:Hide()
    end

    -- Text Color
    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: WIP PANELS (Placeholder)
--==============================================================================================================================================================================================
local function BuildPlaceholderPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local label = GUI:CreateLabel(content, "Work in progress...", 14, C.textMuted)
    label:SetPoint("TOPLEFT", 10, -10)
    content:SetHeight(50)
end

--==============================================================================================================================================================================================
-- BUILDER: INSTANCE (Tab 10)
--==============================================================================================================================================================================================
local function BuildInstancePanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    
    local header = GUI:CreateSectionHeader(content, "Instance Frames")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    local infoBox = GUI:CreateInfoBox(content, "Skins the PVE Frame (Dungeon Finder, Raid Finder, Premade Groups) and Mythic+ frames.")
    infoBox:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox:GetHeight() - 10
    
    local row1 = CreateStylingRow(content, "Enable Custom Instance Styling", "checkbox", "enabled", ns.db.profile.styling.instanceFrames, function()
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    

    

    
    local db = ns.db.profile.styling.instanceFrames
    
    -- Background Color Customization
    local bgPickerRow -- Forward declare
    local rowBg = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorBackground", db, function(value)
        if bgPickerRow then
            if value then bgPickerRow:Show() else bgPickerRow:Hide() end
        end
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    rowBg:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    bgPickerRow = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", db, function()
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    bgPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.disableThemeColorBackground then
        bgPickerRow:Hide()
    end
    
    -- Border Color Customization
    local borderPickerRow -- Forward declare
    local rowBr = CreateStylingRow(content, "Don't Use Theme for Border", "checkbox", "disableThemeColorBorder", db, function(value)
        if borderPickerRow then
            if value then borderPickerRow:Show() else borderPickerRow:Hide() end
        end
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    rowBr:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    borderPickerRow = CreateStylingRow(content, "Border Color", "color", "customBorderColor", db, function()
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    borderPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    if not db.disableThemeColorBorder then
        borderPickerRow:Hide()
    end
    
    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: XP / REP (Tab 11)
--==============================================================================================================================================================================================
local function BuildXPRepPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local yOffset = -10
    local PAD = 10
    
    local header = GUI:CreateSectionHeader(content, "Experience & Reputation Bars")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10
    
    local db = ns.db.profile.styling.xpRep
    
    local row1 = CreateStylingRow(content, "Enable XP/Rep Module", "checkbox", "enabled", db, function(val)
        if val then
            -- Automate hiding Blizzard bars when GravityUI module is enabled
            local dbUI = ns.db.profile.uiimprovements
            dbUI.hideXPBar = true
            dbUI.hideReputationBar = true
            if ns.ApplyAutohideSettings then ns.ApplyAutohideSettings() end
        end

        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end

        -- Refresh the page to update the Blizzard hide checkboxes visually
        local page = GUI.pages["Styling"]
        if page and page.subTabsContainer and GUI.MainFrame and GUI.MainFrame:IsShown() then
            local subIndex = GUI.currentSubTabIndex or 1
            local contentFrame = page.subTabsContainer.tabContents[subIndex]
            local tabInfo = page.subTabs[subIndex]
            
            if contentFrame and tabInfo and tabInfo.builder then
                GUI:ClearPageContent(contentFrame)
                tabInfo.builder(contentFrame)
            end
        end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Size
    local rowW = CreateStylingRow(content, "Bar Width", "slider", 100, 1000, "width", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end, 1)
    rowW:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowH = CreateStylingRow(content, "Bar Height", "slider", 2, 50, "height", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end, 1)
    rowH:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Font
    local rowFS = CreateStylingRow(content, "Font Size", "slider", 6, 32, "fontSize", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end, 1)
    rowFS:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local outlineOptions = {
        { text = "None", value = "NONE" },
        { text = "Outline", value = "OUTLINE" },
        { text = "Thick Outline", value = "THICKOUTLINE" },
        { text = "Monochrome", value = "MONOCHROME" },
    }
    local rowFO = CreateStylingRow(content, "Font Outline", "dropdown", outlineOptions, "fontOutline", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowFO:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Toggles
    local rowXP = CreateStylingRow(content, "Show Experience", "checkbox", "showXP", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowXP:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowRep = CreateStylingRow(content, "Show Reputation", "checkbox", "showRep", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowRep:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowMO = CreateStylingRow(content, "Show on Mouseover", "checkbox", "mouseover", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowMO:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowHide = CreateStylingRow(content, "Always Hide Bars", "checkbox", "alwaysHide", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowHide:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    local rowShowText = CreateStylingRow(content, "Always Show Text", "checkbox", "alwaysShowText", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowShowText:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Extra spacing for Dropdown (Height 40 vs Row 30)
    yOffset = yOffset - 5 
    
    local strataOptions = {
        { text = "Background", value = "BACKGROUND" },
        { text = "Low", value = "LOW" },
        { text = "Medium", value = "MEDIUM" },
        { text = "High", value = "HIGH" },
        { text = "Dialog", value = "DIALOG" },
        { text = "Fullscreen", value = "FULLSCREEN" },
        { text = "Fullscreen Dialog", value = "FULLSCREEN_DIALOG" },
        { text = "Tooltip", value = "TOOLTIP" },
    }
    
    local rowStrata = CreateStylingRow(content, "Frame Strata", "dropdown", "strata", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end, strataOptions)
    
    rowStrata:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 10 -- Extra 5px for dropdown bottom overflow
    
    -- yOffset = yOffset - ROW_HEIGHT - 5 (Removed to reduce gap)
    
    local dbUI = ns.db.profile.uiimprovements
    local function RefreshAutohide() if ns.ApplyAutohideSettings then ns.ApplyAutohideSettings() end end
    
    local rowHideXP = CreateStylingRow(content, "Hide Blizzard XP Bar", "checkbox", "hideXPBar", dbUI, RefreshAutohide)
    rowHideXP:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowHideRep = CreateStylingRow(content, "Hide Blizzard Rep Bar", "checkbox", "hideReputationBar", dbUI, RefreshAutohide)
    rowHideRep:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Colors
    local rowC1 = CreateStylingRow(content, "XP Color", "color", "xpColor", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowC1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowC2 = CreateStylingRow(content, "Rested Color", "color", "restedColor", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowC2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rowC3 = CreateStylingRow(content, "Reputation Color", "color", "repColor", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowC3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Texture dropdown
    local textureList = {}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for _, name in pairs(LSM:List("statusbar")) do
            table.insert(textureList, { text = name, value = name })
        end
        table.sort(textureList, function(a, b) return a.text < b.text end)
    end
    
    local rowTex = CreateStylingRow(content, "Texture", "dropdown", textureList, "texture", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    end)
    rowTex:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Mover
    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 140, 24, function()
        if ns.XPRep and ns.XPRep.ToggleMover then ns.XPRep:ToggleMover() end
    end)
    moverBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local previewBtn = GUI:CreateButton(content, "Toggle Preview", 140, 24, function()
        if ns.XPRep and ns.XPRep.TogglePreview then ns.XPRep:TogglePreview() end
    end)
    previewBtn:SetPoint("LEFT", moverBtn, "RIGHT", 10, 0)
    
    yOffset = yOffset - 40
    
    content:SetHeight(math.abs(yOffset) + 20)
end

-- 5. Chat
local function BuildChat(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    
    local yOffset = -10
    local PAD = 10

    local function RefreshChat() if ns.Chat and ns.Chat.Refresh then ns.Chat.Refresh() end end
    local dbChat = dbUI.chat or {}
    
    local header = GUI:CreateSectionHeader(content, "Chat")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap - 10
    
    local chatInfo = GUI:CreateInfoBox(content, "Disabling GUI Chatbox will leave the chat at WoW defaults.\n\n|cffFFCC00Note:|r Requires /reload to fully disable this Module.")
    chatInfo:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - chatInfo:GetHeight() - 10
    
    local r1 = CreateStylingRow(content, "Enable GUI Chatbox", "checkbox", "enabled", dbChat, function(v)
        RefreshChat()
    end)
    r1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 35

    -- defaults
    if not dbChat.glass then dbChat.glass = {enabled=true, bgAlpha=0.25, bgColor={0,0,0,1}} end
    if not dbChat.timestamps then dbChat.timestamps = {enabled=true, format="24h", color={0.6,0.6,0.6,1}} end
    if not dbChat.urls then dbChat.urls = {enabled=true, color={0,0.75,1,1}} end
    if not dbChat.editBox then dbChat.editBox = {enabled=true, positionTop=false, bgAlpha=0.4, bgColor={0,0,0,1}} end
    if not dbChat.fade then dbChat.fade = {enabled=true, delay=15} end
    -- Chat Tabs Defaults
    if not dbChat.tabs then 
        dbChat.tabs = {
            style = "button",
            activeTab = {useThemeColor = true, customColor = {1, 0.82, 0, 1}, alpha = 1.0},
            inactiveTab = {alpha = 0.5}
        }
    end
    -- Ensure sub-tables
    if not dbChat.tabs.activeTab then dbChat.tabs.activeTab = {useThemeColor = true, customColor = {1, 0.82, 0, 1}, alpha = 1.0, disableBox = false, disableBackground = false} end
    if dbChat.tabs.activeTab.disableBox == nil then dbChat.tabs.activeTab.disableBox = false end
    if dbChat.tabs.activeTab.disableBackground == nil then dbChat.tabs.activeTab.disableBackground = false end
    if not dbChat.tabs.inactiveTab then dbChat.tabs.inactiveTab = {alpha = 0.5} end
    if dbChat.tabs.modernDesign == nil then dbChat.tabs.modernDesign = false end

        local function MakeSubHeader(txt)
        local h = CreateFrame("Frame", nil, content)
        h:SetSize(GUI.CONTENT_WIDTH - 20, 20)
        local t = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if ns.GUI.SetFont then ns.GUI:SetFont(t, 12, "") end
        t:SetPoint("LEFT")
        t:SetText(txt)
        t:SetTextColor(unpack(GUI.Colors.accent))
        h:SetPoint("TOPLEFT", PAD, yOffset)
        yOffset = yOffset - 25
        return h
    end

    local function MakeRow(...)
        local row = CreateStylingRow(content, ...)
        row:SetPoint("TOPLEFT", PAD, yOffset)
        yOffset = yOffset - 35
        return row
    end

    MakeSubHeader("Chat Background")
    MakeRow("Chat Background Texture", "checkbox", "enabled", dbChat.glass, RefreshChat)
    MakeRow("Background Opacity", "slider", 0, 1, "bgAlpha", dbChat.glass, RefreshChat, 0.05)
    MakeRow("Background Color", "color", "bgColor", dbChat.glass, RefreshChat)

    MakeSubHeader("Chat Tabs")
    MakeRow("Enable Modern GUI Design", "checkbox", "modernDesign", dbChat.tabs, RefreshChat)
    MakeRow("Disable Box Base & Border", "checkbox", "disableBox", dbChat.tabs.activeTab, RefreshChat)
    MakeRow("Disable Background Entirely", "checkbox", "disableBackground", dbChat.tabs.activeTab, RefreshChat)
    MakeRow("Use Theme Color for Active Tab", "checkbox", "useThemeColor", dbChat.tabs.activeTab, RefreshChat)
    MakeRow("Custom Active Color", "color", "customColor", dbChat.tabs.activeTab, RefreshChat)
    MakeRow("Active Tab Opacity", "slider", 0, 1, "alpha", dbChat.tabs.activeTab, RefreshChat, 0.1)
    MakeRow("Inactive Tab Opacity", "slider", 0, 1, "alpha", dbChat.tabs.inactiveTab, RefreshChat, 0.1)
    MakeRow("Auto Hide Chat Tabs", "checkbox", "hideTabs", dbChat, RefreshChat)

    MakeSubHeader("Input Box Background")
    MakeRow("Input Box Background Texture", "checkbox", "enabled", dbChat.editBox, RefreshChat)
    MakeRow("Background Opacity", "slider", 0, 1, "bgAlpha", dbChat.editBox, RefreshChat, 0.05)
    MakeRow("Background Color", "color", "bgColor", dbChat.editBox, RefreshChat)
    MakeRow("Position Input Box at Top", "checkbox", "positionTop", dbChat.editBox, RefreshChat)
    MakeRow("Width (0 = Auto)", "slider", 0, 1000, "width", dbChat.editBox, RefreshChat, 5)
    MakeRow("Height", "slider", 10, 100, "height", dbChat.editBox, RefreshChat, 1)
    MakeRow("X Offset", "slider", -100, 100, "offsetX", dbChat.editBox, RefreshChat, 1)
    MakeRow("Y Offset", "slider", -100, 100, "offsetY", dbChat.editBox, RefreshChat, 1)

    MakeSubHeader("Message Fade")
    MakeRow("Fade Messages After Inactivity", "checkbox", "enabled", dbChat.fade, RefreshChat)
    MakeRow("Fade Delay (seconds)", "slider", 5, 120, "delay", dbChat.fade, RefreshChat, 5)

    MakeSubHeader("URL Detection")
    MakeRow("Make URLs Clickable", "checkbox", "enabled", dbChat.urls, RefreshChat)
    local noteUrl = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteUrl:SetPoint("TOPLEFT", PAD, yOffset)
    noteUrl:SetWidth(GUI.CONTENT_WIDTH - 40)
    noteUrl:SetJustifyH("LEFT")
    noteUrl:SetText("Click any URL in chat to open a copy dialog.")
    noteUrl:SetTextColor(unpack(C.textMuted))
    yOffset = yOffset - 30

    MakeSubHeader("Copy Button")
    local copyOptions = {{value="always", text="Always Show"}, {value="hover", text="Show on Hover"}, {value="disabled", text="Disabled"}}
    MakeRow("Copy Button", "dropdown", copyOptions, "copyButtonMode", dbChat, RefreshChat)

    MakeSubHeader("Timestamps")
    MakeRow("Show Timestamps", "checkbox", "enabled", dbChat.timestamps, RefreshChat)
    local timeOptions = {{value="12h", text="12-Hour (03:27 PM)"}, {value="24h", text="24-Hour (15:27)"}}
    MakeRow("Format", "dropdown", timeOptions, "format", dbChat.timestamps, RefreshChat)
    MakeRow("Timestamp Color", "color", "color", dbChat.timestamps, RefreshChat)



    MakeSubHeader("UI Cleanup")
    MakeRow("Hide Chat Buttons", "checkbox", "hideButtons", dbChat, RefreshChat)
    MakeRow("Unclamp Chat (Allow off-screen)", "checkbox", "unclamp", dbChat, RefreshChat)

    MakeSubHeader("Auto Jump Down")
    if not dbChat.jumpDown then dbChat.jumpDown = {enabled = false, delay = 10} end
    MakeRow("Jump to Bottom After Inactivity", "checkbox", "enabled", dbChat.jumpDown, RefreshChat)
    MakeRow("Delay (seconds)", "slider", 3, 60, "delay", dbChat.jumpDown, RefreshChat, 1)

    content:SetHeight(math.abs(yOffset) + 20)
end

-- 6. Tooltip
local function BuildTooltip(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements

    local yOffset = -10
    local PAD = 10

    local function RefreshTooltip() if ns.Tooltip and ns.Tooltip.Refresh then ns.Tooltip.Refresh() end end
    local dbTT = dbUI.tooltip or {}
    if dbTT.enabled == nil then dbTT.enabled = true end
    if not dbTT.visibility then dbTT.visibility = {npcs="SHOW", abilities="SHOW", items="SHOW", frames="SHOW", cdm="SHOW", customTrackers="SHOW"} end

    local header = GUI:CreateSectionHeader(content, "Tooltip")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap - 10

    local function MakeSubHeader(txt)
        local h = CreateFrame("Frame", nil, content)
        h:SetSize(GUI.CONTENT_WIDTH - 20, 20)
        local t = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if ns.GUI.SetFont then ns.GUI:SetFont(t, 12, "") end
        t:SetPoint("LEFT")
        t:SetText(txt)
        t:SetTextColor(unpack(GUI.Colors.accent))
        h:SetPoint("TOPLEFT", PAD, yOffset)
        yOffset = yOffset - 25
        return h
    end

    local function MakeRow(...)
        local row = CreateStylingRow(content, ...)
        row:SetPoint("TOPLEFT", PAD, yOffset)
        yOffset = yOffset - 35
        return row
    end

    -- -------------------------------------------------------
    MakeSubHeader("General")
    -- -------------------------------------------------------
    MakeRow("Enable Tooltip Module", "checkbox", "enabled", dbTT, RefreshTooltip)
    MakeRow("Anchor to Cursor", "checkbox", "anchorToCursor", dbTT, RefreshTooltip)
    MakeRow("Class Color Names", "checkbox", "classColorName", dbTT, RefreshTooltip)

    -- -------------------------------------------------------
    MakeSubHeader("Player Info")
    -- -------------------------------------------------------
    MakeRow("Show Guild Name & Rank", "checkbox", "showGuildInfo", dbTT, RefreshTooltip)
    MakeRow("Guild Name Color", "color", "guildColor", dbTT, RefreshTooltip)
    MakeRow("Show Faction (Horde/Alliance)", "checkbox", "showFaction", dbTT, RefreshTooltip)
    MakeRow("Color Level by Difficulty", "checkbox", "showColoredLevel", dbTT, RefreshTooltip)
    MakeRow("Show Spec & Class", "checkbox", "showSpecAndClass", dbTT, RefreshTooltip)

    -- -------------------------------------------------------
    MakeSubHeader("Mount")
    -- -------------------------------------------------------
    MakeRow("Show Mount Name", "checkbox", "showMount", dbTT, RefreshTooltip)
    MakeRow("Show Server Name (cross-realm only)", "checkbox", "showServer", dbTT, RefreshTooltip)

    -- -------------------------------------------------------
    MakeSubHeader("Health Bar")
    -- -------------------------------------------------------
    MakeRow("Hide Health Bar", "checkbox", "hideHealthBar", dbTT, RefreshTooltip)
    MakeRow("Class Color Health Bar", "checkbox", "useClassColorHealth", dbTT, RefreshTooltip)

    -- Bar Texture dropdown via LSM
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local textureList = {}
    if LSM then
        for _, name in pairs(LSM:List("statusbar")) do
            table.insert(textureList, { text = name, value = name })
        end
        table.sort(textureList, function(a, b) return a.text < b.text end)
    end
    if #textureList > 0 then
        MakeRow("Health Bar Texture", "dropdown", textureList, "healthBarTexture", dbTT, RefreshTooltip)
    end

    -- -------------------------------------------------------
    MakeSubHeader("ID Display")
    -- -------------------------------------------------------
    MakeRow("Show Spell ID", "checkbox", "showSpellID", dbTT, RefreshTooltip)
    MakeRow("Show Aura ID", "checkbox", "showAuraID", dbTT, RefreshTooltip)
    MakeRow("Show NPC ID", "checkbox", "showNPCID", dbTT, RefreshTooltip)
    MakeRow("Show Item ID", "checkbox", "showIDs", dbTT, RefreshTooltip)
    MakeRow("Show Icon ID", "checkbox", "showIconID", dbTT, RefreshTooltip)
    MakeRow("Show Texture ID", "checkbox", "showTextureID", dbTT, RefreshTooltip)
    MakeRow("Use Theme Color for IDs", "checkbox", "useThemeColorID", dbTT, RefreshTooltip)
    MakeRow("Custom ID Color", "color", "idColor", dbTT, RefreshTooltip)

    -- -------------------------------------------------------
    MakeSubHeader("Combat & Visibility")
    -- -------------------------------------------------------
    MakeRow("Hide in Combat", "checkbox", "hideInCombat", dbTT, RefreshTooltip)
    local modOptions = {{value="NONE", text="None"}, {value="SHIFT", text="Shift"}, {value="CTRL", text="Ctrl"}, {value="ALT", text="Alt"}}
    MakeRow("Combat Override Key", "dropdown", modOptions, "combatKey", dbTT, RefreshTooltip)

    -- -------------------------------------------------------
    MakeSubHeader("Context Visibility")
    -- -------------------------------------------------------
    local visOptions = {{value="SHOW", text="Always Show"}, {value="HIDE", text="Always Hide"}, {value="SHIFT", text="Shift"}, {value="CTRL", text="Ctrl"}, {value="ALT", text="Alt"}}
    MakeRow("World (NPCs/Players)", "dropdown", visOptions, "npcs", dbTT.visibility, RefreshTooltip)
    MakeRow("Abilities (Action Bars)", "dropdown", visOptions, "abilities", dbTT.visibility, RefreshTooltip)
    MakeRow("Items (Bags/Bank)", "dropdown", visOptions, "items", dbTT.visibility, RefreshTooltip)
    MakeRow("Unit Frames", "dropdown", visOptions, "frames", dbTT.visibility, RefreshTooltip)
    MakeRow("CDM Icons", "dropdown", visOptions, "cdm", dbTT.visibility, RefreshTooltip)

    -- -------------------------------------------------------
    MakeSubHeader("Tooltip Styling")
    -- -------------------------------------------------------
    MakeRow("Enable Custom Square Style", "checkbox", "customStyle", dbTT, RefreshTooltip)
    MakeRow("Font Size", "slider", 8, 24, "fontSize", dbTT, RefreshTooltip, 1)
    MakeRow("Background Opacity", "slider", 0, 1, "bgAlpha", dbTT, RefreshTooltip, 0.05)
    MakeRow("Background Color", "color", "bgColor", dbTT, RefreshTooltip)
    MakeRow("Use Theme Color for Border", "checkbox", "useThemeColor", dbTT, RefreshTooltip)
    MakeRow("Custom Border Color", "color", "borderColor", dbTT, RefreshTooltip)


    content:SetHeight(math.abs(yOffset) + 20)
end

-- 7. Character Panel
local function BuildCharacter(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    
    local yOffset = -10
    local PAD = 10

    local function RefreshChar()
        if ns.Character and ns.Character.RefreshCharacterPane then ns.Character.RefreshCharacterPane() end
        if ns.Character and ns.Character.RefreshAllFonts then ns.Character.RefreshAllFonts() end
        if ns.Inspect and ns.Inspect.UpdateInspectFrame then ns.Inspect.UpdateInspectFrame() end
    end
    local dbChar = dbUI.character or {}
    if dbChar.enabled == nil then dbChar.enabled = true end

    local header = GUI:CreateSectionHeader(content, "Character Panel")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap - 10

        local function MakeSubHeader(txt)
        local h = CreateFrame("Frame", nil, content)
        h:SetSize(GUI.CONTENT_WIDTH - 20, 20)
        local t = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        if ns.GUI.SetFont then ns.GUI:SetFont(t, 12, "") end
        t:SetPoint("LEFT")
        t:SetText(txt)
        t:SetTextColor(unpack(GUI.Colors.accent))
        h:SetPoint("TOPLEFT", PAD, yOffset)
        yOffset = yOffset - 25
        return h
    end

    local function MakeRow(...)
        local row = CreateStylingRow(content, ...)
        row:SetPoint("TOPLEFT", PAD, yOffset)
        yOffset = yOffset - 35
        return row
    end

    MakeSubHeader("Appearance")
    MakeRow("Enable Character Panel Styling", "checkbox", "enabled", dbChar, RefreshChar)
    MakeRow("Enable Inspect Panel Styling", "checkbox", "inspectEnabled", dbChar, function() if ns.Inspect and ns.Inspect.UpdateInspectFrame then ns.Inspect.UpdateInspectFrame() end end)
    MakeRow("Panel Scale", "slider", 0.75, 1.5, "panelScale", dbChar, function(val)
        if CharacterFrame then CharacterFrame:SetScale(1.30 * val) end
        if ns.Inspect and ns.Inspect.UpdateInspectFrame then ns.Inspect.UpdateInspectFrame() end
    end, 0.05)
    MakeRow("Use Theme Color for Background", "checkbox", "useThemeBackground", dbChar, function() if ns.Character and ns.Character.RefreshBackground then ns.Character.RefreshBackground() end end)
    MakeRow("Background Color", "color", "panelBgColor", dbChar, function() if ns.Character and ns.Character.RefreshBackground then ns.Character.RefreshBackground() end end)
    MakeRow("Background Opacity", "slider", 0, 100, "panelOpacity", dbChar, function() if ns.Character and ns.Character.RefreshBackground then ns.Character.RefreshBackground() end end, 1)

    MakeSubHeader("Slot Overlays")
    MakeRow("Show Equipment Name", "checkbox", "showItemName", dbChar, RefreshChar)
    MakeRow("Show Item Level & Track", "checkbox", "showItemLevel", dbChar, RefreshChar)
    MakeRow("Show Enchant Status", "checkbox", "showEnchants", dbChar, RefreshChar)
    MakeRow("Show Gem Indicators", "checkbox", "showGems", dbChar, RefreshChar)
    MakeRow("Show Durability Bars", "checkbox", "showDurability", dbChar, RefreshChar)
    
    local bpRow -- Forward declare
    MakeRow("Show Item Color Backdrop", "checkbox", "showBackdrops", dbChar, RefreshChar)
    MakeRow("Use Fixed Backdrop Color", "checkbox", "backdropFixedColor", dbChar, function(val)
        if bpRow then if val then bpRow:Show() else bpRow:Hide() end end
        RefreshChar()
    end)
    bpRow = MakeRow("Fixed Backdrop Color", "color", "backdropColor", dbChar, RefreshChar)
    if not dbChar.backdropFixedColor then bpRow:Hide() end

    MakeSubHeader("Stats Panel")
    MakeRow("Show Stat Tooltips", "checkbox", "showTooltips", dbChar, RefreshChar)
    local statFormats = {{value="percent", text="Percentage (19.5%)"}, {value="rating", text="Rating (1234)"}, {value="both", text="Both"}}
    MakeRow("Secondary Stat Format", "dropdown", statFormats, "secondaryStatFormat", dbChar, RefreshChar)

    MakeSubHeader("Text Sizes")
    MakeRow("Slot Text Size", "slider", 6, 24, "slotTextSize", dbChar, RefreshChar, 1)
    MakeRow("Header Text Size", "slider", 6, 24, "headerTextSize", dbChar, RefreshChar, 1)
    MakeRow("Stats Text Size", "slider", 6, 24, "statsTextSize", dbChar, RefreshChar, 1)

    MakeSubHeader("Text Colors")
    MakeRow("Stats Text Color", "color", "statsTextColor", dbChar, RefreshChar)
    MakeRow("Header Class Color", "checkbox", "headerClassColor", dbChar, RefreshChar)
    MakeRow("Custom Header Color", "color", "headerColor", dbChar, RefreshChar)
    MakeRow("Enchant Class Color", "checkbox", "enchantClassColor", dbChar, RefreshChar)
    MakeRow("Custom Enchant Color", "color", "enchantTextColor", dbChar, RefreshChar)
    MakeRow("No Enchant Color", "color", "noEnchantTextColor", dbChar, RefreshChar)
    MakeRow("Upgrade Track Color", "color", "upgradeTrackColor", dbChar, RefreshChar)

    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- BUILDER: STATIC POPUPS
--==============================================================================================================================================================================================
local function BuildStaticPopupsPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local yOffset = -10
    local PAD = 10

    if not ns.db.profile.styling.staticPopups then
        ns.db.profile.styling.staticPopups = {
            enabled = true,
            disableThemeColorBackground = false,
            customBackgroundColor = { 0.07, 0.07, 0.07, 0.97 },
            disableThemeColorFont = false,
            customFontColor = { 1, 1, 1, 1 },
            hideBorder = false,
            disableThemeColorBorder = false,
            customBorderColor = { 1, 1, 1, 1 },
        }
    else
        -- Backfill border keys for existing profiles missing them
        local sp = ns.db.profile.styling.staticPopups
        if sp.hideBorder == nil then sp.hideBorder = false end
        if sp.disableThemeColorBorder == nil then sp.disableThemeColorBorder = false end
        if sp.customBorderColor == nil then sp.customBorderColor = { 1, 1, 1, 1 } end
    end
    local db = ns.db.profile.styling.staticPopups

    local header = GUI:CreateSectionHeader(content, "Static Popup Dialogs")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap
    yOffset = yOffset - 10

    local infoBox = GUI:CreateInfoBox(content, "Skins Blizzard's popup dialogs: Group Invite, Duel, Resurrection, Trade requests, and more.")
    infoBox:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox:GetHeight() - 10

    local row1 = CreateStylingRow(content, "Enable Popup Skinning", "checkbox", "enabled", db, function()
        if ns.Styling and ns.Styling.SkinStaticPopups then ns.Styling:SkinStaticPopups() end
    end)
    row1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    -- Background Color
    local bgPickerRow
    local rowBg = CreateStylingRow(content, "Don't Use Theme for BG", "checkbox", "disableThemeColorBackground", db, function(value)
        if bgPickerRow then
            if value then bgPickerRow:Show() else bgPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.RefreshStaticPopups then ns.Styling:RefreshStaticPopups() end
    end)
    rowBg:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    bgPickerRow = CreateStylingRow(content, "Background Color", "color", "customBackgroundColor", db, function()
        if ns.Styling and ns.Styling.RefreshStaticPopups then ns.Styling:RefreshStaticPopups() end
    end)
    bgPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    if not db.disableThemeColorBackground then bgPickerRow:Hide() end

    -- Font Color
    local fontPickerRow
    local rowFn = CreateStylingRow(content, "Don't Use Theme for Font", "checkbox", "disableThemeColorFont", db, function(value)
        if fontPickerRow then
            if value then fontPickerRow:Show() else fontPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.RefreshStaticPopups then ns.Styling:RefreshStaticPopups() end
    end)
    rowFn:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    fontPickerRow = CreateStylingRow(content, "Font Color", "color", "customFontColor", db, function()
        if ns.Styling and ns.Styling.RefreshStaticPopups then ns.Styling:RefreshStaticPopups() end
    end)
    fontPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    if not db.disableThemeColorFont then fontPickerRow:Hide() end

    -- Border
    local borderPickerRow
    local rowHideBorder = CreateStylingRow(content, "Hide Border", "checkbox", "hideBorder", db, function()
        if ns.Styling and ns.Styling.RefreshStaticPopups then ns.Styling:RefreshStaticPopups() end
    end)
    rowHideBorder:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    local rowBorderCustom = CreateStylingRow(content, "Don't Use Theme for Border", "checkbox", "disableThemeColorBorder", db, function(value)
        if borderPickerRow then
            if value then borderPickerRow:Show() else borderPickerRow:Hide() end
        end
        if ns.Styling and ns.Styling.RefreshStaticPopups then ns.Styling:RefreshStaticPopups() end
    end)
    rowBorderCustom:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    borderPickerRow = CreateStylingRow(content, "Border Color", "color", "customBorderColor", db, function()
        if ns.Styling and ns.Styling.RefreshStaticPopups then ns.Styling:RefreshStaticPopups() end
    end)
    borderPickerRow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    if not db.disableThemeColorBorder then borderPickerRow:Hide() end

    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- MAIN STYLING PAGE
--==============================================================================================================================================================================================
GUI:RegisterPage("Styling", {
    title = "UI Styling",
    subTabs = {
        { name = "Character Panel", builder = BuildCharacter },
        { name = "Chat", builder = BuildChat },
        { name = "Tooltip", builder = BuildTooltip },
        { name = "Objective Tracker", builder = BuildObjectivesPanel },
        { name = "Loot", builder = BuildLootPanel },
        { name = "Game Menu", builder = BuildGameMenuPanel },
        { name = "Ready Check", builder = BuildReadyCheckPanel },
        { name = "Keystone", builder = BuildKeystonePanel },
        { name = "Power Bar", builder = BuildPowerBarPanel },
        { name = "Alert Frames", builder = BuildAlertsPanel },
        { name = "Chat Bubbles", builder = BuildChatBubblesPanel },
        { name = "Instance", builder = BuildInstancePanel },
        { name = "XP / Rep", builder = BuildXPRepPanel },
        { name = "Static Popups", builder = BuildStaticPopupsPanel },
    },
    OnBuild = function(content)
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Create SubTabs container
        local opts = GUI.pages["Styling"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["Styling"]
        if not opts.subTabsContainer then return end
        
        subIndex = subIndex or 1
        
        -- Hide all
        for _, cf in pairs(opts.subTabsContainer.tabContents) do
            cf:Hide()
        end
        
        -- Show active
        if opts.subTabsContainer.tabContents[subIndex] then
            opts.subTabsContainer.tabContents[subIndex]:Show()
        end
    end
})




