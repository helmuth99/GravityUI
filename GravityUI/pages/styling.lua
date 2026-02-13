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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: GAME MENU (Tab 1)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: CHAT BUBBLES (Tab 2)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: READY CHECK (Tab 3)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: KEYSTONE (Tab 4)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: POWER BAR (Tab 5)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: ALERTS (Tab 6)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: LOOT (Tab 7)
-- ═══════════════════════════════════════════════════════════════
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
    
    local rowF4 = CreateStylingRow(content, "Item Name Color", "color", nil, "nameFontColor", db.lootRoll, function()
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: OBJECTIVES (Tab 9)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: WIP PANELS (Placeholder)
-- ═══════════════════════════════════════════════════════════════
local function BuildPlaceholderPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local label = GUI:CreateLabel(content, "Work in progress...", 14, C.textMuted)
    label:SetPoint("TOPLEFT", 10, -10)
    content:SetHeight(50)
end

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: INSTANCE (Tab 10)
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: XP / REP (Tab 11)
-- ═══════════════════════════════════════════════════════════════
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
    
    local row1 = CreateStylingRow(content, "Enable XP/Rep Module", "checkbox", "enabled", db, function()
        if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
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

-- ═══════════════════════════════════════════════════════════════
-- MAIN STYLING PAGE
-- ═══════════════════════════════════════════════════════════════
GUI:RegisterPage("Styling", {
    title = "UI Styling",
    OnBuild = function(content)
        -- Hide default scrollframe parent (since we use SubTabs which create their own content areas)
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Create SubTabs
        local subTabs = GUI:CreateSubTabs(scrollFrame, {
            { name = "Game Menu", builder = BuildGameMenuPanel },
            { name = "Chat Bubbles", builder = BuildChatBubblesPanel },
            { name = "Ready Check", builder = BuildReadyCheckPanel },
            { name = "Keystone", builder = BuildKeystonePanel },
            { name = "Power Bar", builder = BuildPowerBarPanel },
            { name = "Alert Frames", builder = BuildAlertsPanel },
            { name = "Loot", builder = BuildLootPanel },
            { name = "Objectives", builder = BuildObjectivesPanel },
            { name = "Instance", builder = BuildInstancePanel },
            { name = "XP / Rep", builder = BuildXPRepPanel },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
