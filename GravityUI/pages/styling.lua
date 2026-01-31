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
        widget = GUI:CreateDropdown(row, "", arg1, arg2, arg3, arg4)
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
    
    -- 3. MISSING RAID BUFFS
    local header3 = GUI:CreateSectionHeader(content, "Missing Raid Buffs")
    header3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header3.gap
    yOffset = yOffset - 10
    

    
    local rbr1 = CreateStylingRow(content, "Enable Missing Raid Buffs", "checkbox", "enabled", rbDb, function() 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbr1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rbr2 = CreateStylingRow(content, "Show Only When In Group", "checkbox", "showOnlyInGroup", rbDb, function() 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbr2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rbr3 = CreateStylingRow(content, "Show Only In Instance", "checkbox", "showOnlyInInstance", rbDb, function() 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbr3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rbr4 = CreateStylingRow(content, "Also Show Buffs You Can Provide", "checkbox", "providerMode", rbDb, function() 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbr4:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rbr5 = CreateStylingRow(content, "Hide Label Bar", "checkbox", "hideLabelBar", rbDb, function() 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbr5:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5

    local rbr6 = CreateStylingRow(content, "Icon Size", "slider", 16, 64, "iconSize", rbDb, function() 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbr6:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    local rbr7 = CreateStylingRow(content, "Label Font Size", "slider", 8, 24, "labelFontSize", rbDb, function() 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbr7:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - ROW_HEIGHT - 5
    
    -- Checkbox toggle preview
    local prevBtn = GUI:CreateButton(content, "Toggle Preview", 140, 24, function()
        if ns.RaidBuffs then ns.RaidBuffs:TogglePreview() end
    end)
    prevBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
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
    
    -- 2. LOOT HISTORY
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
            { name = "Ready Check & Buffs", builder = BuildReadyCheckPanel },
            { name = "Keystone", builder = BuildKeystonePanel },
            { name = "Power Bar", builder = BuildPowerBarPanel },
            { name = "Alert Frames", builder = BuildAlertsPanel },
            { name = "Loot", builder = BuildLootPanel },
            { name = "Objectives", builder = BuildObjectivesPanel },
            { name = "Instance", builder = BuildInstancePanel },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
