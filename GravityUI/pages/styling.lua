local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = GUI.Colors

-- Initialize styling database structure if missing is handled in core/defaults.lua now

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
    
    local toggle = GUI:CreateCheckbox(content, "Enable Game Menu Skinning", "enabled", ns.db.profile.styling.gamemenu, function(value)
        if ns.Styling and ns.Styling.SkinGameMenu then
            ns.Styling:SkinGameMenu()
        end
    end)
    toggle:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30

    local showBtn = GUI:CreateCheckbox(content, "Show Gravity UI Button", "showGravityButton", ns.db.profile.styling.gamemenu, function(value)
        if ns.Styling and ns.Styling.SkinGameMenu then
            ns.Styling:SkinGameMenu()
        end
    end)
    showBtn:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    local btnSize = GUI:CreateSlider(content, "Button Font Size", 8, 24, "buttonFontSize", ns.db.profile.styling.gamemenu, function(value)
        if ns.Styling and ns.Styling.SkinGameMenu then
            ns.Styling:SkinGameMenu()
        end
    end, 1)
    btnSize:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50
    
    -- Background Color Customization
    local bgPicker -- Forward declare
    local bgCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Background", "disableThemeColorBackground", ns.db.profile.styling.gamemenu, function(value)
        if bgPicker then
            if value then bgPicker:Show() else bgPicker:Hide() end
        end
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    bgCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    bgPicker = GUI:CreateColorPicker(content, "Background Color", "customBackgroundColor", ns.db.profile.styling.gamemenu, function()
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    bgPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not ns.db.profile.styling.gamemenu.disableThemeColorBackground then
        bgPicker:Hide()
    end
    
    -- Font Color Customization
    local fontPicker -- Forward declare
    local fontCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Font", "disableThemeColorFont", ns.db.profile.styling.gamemenu, function(value)
        if fontPicker then
            if value then fontPicker:Show() else fontPicker:Hide() end
        end
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    fontCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    fontPicker = GUI:CreateColorPicker(content, "Font Color", "customFontColor", ns.db.profile.styling.gamemenu, function()
        if ns.Styling and ns.Styling.SkinGameMenu then ns.Styling:SkinGameMenu() end
    end)
    fontPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not ns.db.profile.styling.gamemenu.disableThemeColorFont then
        fontPicker:Hide()
    end
    
    local note = GUI:CreateLabel(content, "Note: Requires UI Reload to fully apply/remove.", 12, C.textMuted)
    GUI:SetFont(note, 12, "OUTLINE")
    note:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 20
    
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
    
    local toggle = GUI:CreateCheckbox(content, "Enable Chat Bubble Skinning", "enabled", ns.db.profile.styling.chatBubbles, function(value)
        if ns.Styling and ns.Styling.SkinChatBubbles then
            ns.Styling:SkinChatBubbles()
        end
    end)
    toggle:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 40
    
    local fontSize = GUI:CreateSlider(content, "Font Size", 1, 32, "fontSize", ns.db.profile.styling.chatBubbles, function(value)
        if ns.Styling and ns.Styling.SkinChatBubbles then
            ns.Styling:SkinChatBubbles()
        end
    end, 1)
    fontSize:SetPoint("TOPLEFT", PAD, yOffset)
    fontSize:SetWidth(400)
    yOffset = yOffset - 50
    
    local outlineOptions = {
        { text = "None", value = "NONE" },
        { text = "Outline", value = "OUTLINE" },
        { text = "Thick Outline", value = "THICKOUTLINE" },
        { text = "Monochrome", value = "MONOCHROME" },
    }
    
    local fontOutline = GUI:CreateDropdown(content, "Font Outline", outlineOptions, "fontOutline", ns.db.profile.styling.chatBubbles, function(value)
        if ns.Styling and ns.Styling.SkinChatBubbles then
            ns.Styling:SkinChatBubbles()
        end
    end)
    fontOutline:SetPoint("TOPLEFT", PAD, yOffset)
    fontOutline:SetWidth(400)
    yOffset = yOffset - 50
    
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
    
    local skinCheck = GUI:CreateCheckbox(content, "Skin Ready Check Frame", "skinReadyCheck", db, function(value)
        if ns.Styling and ns.Styling.SkinReadyCheck then
            ns.Styling:SkinReadyCheck()
        end
    end)
    skinCheck:SetPoint("TOPLEFT", PAD, yOffset)
    
    local extraNote = GUI:CreateLabel(content, "Skin the ready check popup with GUI styling.", 12, C.textMuted)
    extraNote:SetPoint("TOPLEFT", skinCheck, "BOTTOMLEFT", 26, -4)
    yOffset = yOffset - 50

    -- Background Color Customization
    local bgPicker -- Forward declare
    local bgCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Background", "disableThemeColorBackground", ns.db.profile.styling.readyCheck, function(value)
        if bgPicker then
            if value then bgPicker:Show() else bgPicker:Hide() end
        end
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    bgCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    bgPicker = GUI:CreateColorPicker(content, "Background Color", "customBackgroundColor", ns.db.profile.styling.readyCheck, function()
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    bgPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not ns.db.profile.styling.readyCheck.disableThemeColorBackground then
        bgPicker:Hide()
    end
    
    -- Font Color Customization
    local fontPicker -- Forward declare
    local fontCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Font", "disableThemeColorFont", ns.db.profile.styling.readyCheck, function(value)
        if fontPicker then
            if value then fontPicker:Show() else fontPicker:Hide() end
        end
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    fontCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    fontPicker = GUI:CreateColorPicker(content, "Font Color", "customFontColor", ns.db.profile.styling.readyCheck, function()
        if ns.Styling and ns.Styling.SkinReadyCheck then ns.Styling:SkinReadyCheck() end
    end)
    fontPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not ns.db.profile.styling.readyCheck.disableThemeColorFont then
        fontPicker:Hide()
    end
    yOffset = yOffset - 10

    local moveBtn = GUI:CreateButton(content, "Toggle Mover", 160, 24, function()
        if ns.Styling and ns.Styling.ToggleReadyCheckMover then
             ns.Styling:ToggleReadyCheckMover()
        end
    end)
    moveBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtn = GUI:CreateButton(content, "Reset Position", 160, 24, function()
        if ns.Styling and ns.Styling.ResetReadyCheckPosition then
             ns.Styling:ResetReadyCheckPosition()
        end
    end)
    resetBtn:SetPoint("LEFT", moveBtn, "RIGHT", 10, 0)
    yOffset = yOffset - 50
    
    -- 2. CONSUMABLE CHECK
    local header2 = GUI:CreateSectionHeader(content, "Consumable Check")
    header2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header2.gap
    
    local toggle = GUI:CreateCheckbox(content, "Enable Consumable Check", "consumableCheckEnabled", db, nil)
    toggle:SetPoint("TOPLEFT", PAD, yOffset)
    local note2 = GUI:CreateLabel(content, "Display consumable status icons when triggered by events below.", 12, C.textMuted)
    note2:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 26, -4)
    yOffset = yOffset - 50
    
    -- Show On Group
    local showOnLabel = GUI:CreateLabel(content, "Show On:", 13, C.text)
    showOnLabel:SetPoint("TOPLEFT", PAD + 10, yOffset)
    yOffset = yOffset - 25
    
    local showReady = GUI:CreateCheckbox(content, "Ready Check", "consumableOnReadyCheck", db, nil)
    showReady:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local showDungeon = GUI:CreateCheckbox(content, "Dungeon Entrance", "consumableOnDungeon", db, nil)
    showDungeon:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local showRaid = GUI:CreateCheckbox(content, "Raid Entrance", "consumableOnRaid", db, nil)
    showRaid:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local showRez = GUI:CreateCheckbox(content, "Instanced Resurrect", "consumableOnResurrect", db, nil)
    showRez:SetPoint("TOPLEFT", PAD + 20, yOffset)
    
    local rezNote = GUI:CreateLabel(content, "Shows when resurrected in a dungeon or raid with missing buffs.", 11, C.textMuted)
    rezNote:SetPoint("TOPLEFT", showRez, "BOTTOMLEFT", 26, -2)
    rezNote:SetWidth(600)
    yOffset = yOffset - 50
    
    -- Buffs to Check group
    
    -- Buffs to Check group
    local buffsLabel = GUI:CreateLabel(content, "Buffs to Check:", 13, C.text)
    buffsLabel:SetPoint("TOPLEFT", PAD + 10, yOffset)
    yOffset = yOffset - 25
    
    local checkFood = GUI:CreateCheckbox(content, "Food Buff", "consumableFood", db, nil)
    checkFood:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local checkFlask = GUI:CreateCheckbox(content, "Flask Buff", "consumableFlask", db, nil)
    checkFlask:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local checkOilMH = GUI:CreateCheckbox(content, "Weapon Oil (Main Hand)", "consumableOilMH", db, nil)
    checkOilMH:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local checkOilOH = GUI:CreateCheckbox(content, "Weapon Oil (Off Hand)", "consumableOilOH", db, nil)
    checkOilOH:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local checkRune = GUI:CreateCheckbox(content, "Augment Rune", "consumableRune", db, nil)
    checkRune:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local checkHS = GUI:CreateCheckbox(content, "Healthstones", "consumableHealthstone", db, nil)
    checkHS:SetPoint("TOPLEFT", PAD + 20, yOffset)
    local hsNote = GUI:CreateLabel(content, "Only shows when a Warlock is in the group.", 11, C.textMuted)
    hsNote:SetPoint("TOPLEFT", checkHS, "BOTTOMLEFT", 26, -2)
    yOffset = yOffset - 45
    
    -- Expiration Warning
    local expLabel = GUI:CreateLabel(content, "Expiration Warning", 13, C.text)
    expLabel:SetPoint("TOPLEFT", PAD + 10, yOffset)
    yOffset = yOffset - 25
    
    local expWarn = GUI:CreateCheckbox(content, "Warn When Buffs Expiring", "consumableExpirationWarning", db, nil)
    expWarn:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 30
    
    local noteExp = GUI:CreateLabel(content, "Show consumables window when food/flask/rune is about to expire (instanced content only).", 11, C.textMuted)
    noteExp:SetPoint("TOPLEFT", expWarn, "BOTTOMLEFT", 26, -2)
    noteExp:SetWidth(600)
    yOffset = yOffset - 35
    
    local warnThresh = GUI:CreateSlider(content, "Warning Threshold (seconds)", 60, 600, "consumableExpirationThreshold", db, nil)
    warnThresh:SetPoint("TOPLEFT", PAD + 20, yOffset)
    warnThresh:SetWidth(400)
    yOffset = yOffset - 50
    
    -- Positioning
    local posLabel = GUI:CreateLabel(content, "Positioning", 13, C.text)
    posLabel:SetPoint("TOPLEFT", PAD + 10, yOffset)
    yOffset = yOffset - 25
    
    local anchorCheck = GUI:CreateCheckbox(content, "Anchor to Ready Check", "consumableAnchorMode", db, nil)
    anchorCheck:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    local notePos = GUI:CreateLabel(content, "When enabled, icons anchor above the Ready Check frame. When disabled, use the mover to position freely.", 11, C.textMuted)
    notePos:SetPoint("TOPLEFT", anchorCheck, "BOTTOMLEFT", 26, -2)
    notePos:SetWidth(600)
    yOffset = yOffset - 35
    
    local showMover2 = GUI:CreateButton(content, "Show Mover", 160, 24, function()
         if _G.gui_ShowConsumablesMover then _G.gui_ShowConsumablesMover() end
    end)
    showMover2:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    local iconOffset = GUI:CreateSlider(content, "Icon Offset", -50, 50, "consumableIconOffset", db, function(value)
         if _G.GravityUI_RepositionConsumables then _G.GravityUI_RepositionConsumables() end
    end)
    iconOffset:SetPoint("TOPLEFT", PAD, yOffset)
    iconOffset:SetWidth(400)
    yOffset = yOffset - 50
    
    local iconSize = GUI:CreateSlider(content, "Icon Size", 20, 60, "consumableIconSize", db, function(value)
        if _G.GravityUI_RefreshConsumables then _G.GravityUI_RefreshConsumables() end
    end)
    iconSize:SetPoint("TOPLEFT", PAD, yOffset)
    iconSize:SetWidth(400)
    yOffset = yOffset - 60
    
    -- 3. MISSING RAID BUFFS
    local header3 = GUI:CreateSectionHeader(content, "Missing Raid Buffs")
    header3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header3.gap
    
    local note3 = GUI:CreateLabel(content, "Display missing raid buffs when a buff-providing class is in your group.", 12, C.textMuted)
    note3:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    local enableRB = GUI:CreateCheckbox(content, "Enable Missing Raid Buffs", "enabled", rbDb, function(v) 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    enableRB:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    local showGroup = GUI:CreateCheckbox(content, "Show Only When In Group", "showOnlyInGroup", rbDb, function(v) 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    showGroup:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    local showInst = GUI:CreateCheckbox(content, "Show Only In Instance", "showOnlyInInstance", rbDb, function(v) 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    showInst:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    local provMode = GUI:CreateCheckbox(content, "Also Show Buffs You Can Provide", "providerMode", rbDb, function(v) 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    provMode:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    local hideLbl = GUI:CreateCheckbox(content, "Hide Label Bar", "hideLabelBar", rbDb, function(v) 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    hideLbl:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 40

    local rbIconSize = GUI:CreateSlider(content, "Icon Size", 16, 64, "iconSize", rbDb, function(v) 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbIconSize:SetPoint("TOPLEFT", PAD, yOffset)
    rbIconSize:SetWidth(400)
    yOffset = yOffset - 50
    
    local rbFontSize = GUI:CreateSlider(content, "Label Font Size", 8, 24, "labelFontSize", rbDb, function(v) 
        if ns.RaidBuffs then ns.RaidBuffs:Refresh() end 
    end)
    rbFontSize:SetPoint("TOPLEFT", PAD, yOffset)
    rbFontSize:SetWidth(400)
    yOffset = yOffset - 50
    
    -- Checkbox toggle preview
    local prevBtn = GUI:CreateButton(content, "Toggle Preview", 140, 24, function()
        if ns.RaidBuffs then ns.RaidBuffs:TogglePreview() end
    end)
    prevBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    content:SetHeight(math.abs(yOffset) + 20)
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
    
    local note = GUI:CreateLabel(content, "Skin the M+ keystone insertion window with GUI styling.", 12, C.textMuted)
    note:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    local enable = GUI:CreateCheckbox(content, "Skin Keystone Window", "enabled", ns.db.profile.styling.keystone, function(v)
        if ns.Styling and ns.Styling.SkinKeystone then
             ns.Styling:SkinKeystone()
        end
    end)
    enable:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 40
    
    -- Background Color Customization
    local bgPicker -- Forward declare
    local bgCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Background", "disableThemeColorBackground", ns.db.profile.styling.keystone, function(value)
        if bgPicker then
            if value then bgPicker:Show() else bgPicker:Hide() end
        end
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    bgCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    bgPicker = GUI:CreateColorPicker(content, "Background Color", "customBackgroundColor", ns.db.profile.styling.keystone, function()
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    bgPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not ns.db.profile.styling.keystone.disableThemeColorBackground then
        bgPicker:Hide()
    end
    
    -- Font Color Customization
    local fontPicker -- Forward declare
    local fontCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Font", "disableThemeColorFont", ns.db.profile.styling.keystone, function(value)
        if fontPicker then
            if value then fontPicker:Show() else fontPicker:Hide() end
        end
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    fontCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    fontPicker = GUI:CreateColorPicker(content, "Font Color", "customFontColor", ns.db.profile.styling.keystone, function()
        if ns.Styling and ns.Styling.SkinKeystone then ns.Styling:SkinKeystone() end
    end)
    fontPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not ns.db.profile.styling.keystone.disableThemeColorFont then
        fontPicker:Hide()
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
    
    local enable = GUI:CreateCheckbox(content, "Enable Skinning", "enabled", ns.db.profile.styling.powerBar, function(v)
        if ns.Styling and ns.Styling.SkinPowerBar then
             ns.Styling:SkinPowerBar()
        end
    end)
    enable:SetPoint("TOPLEFT", PAD, yOffset)
    
    local note = GUI:CreateLabel(content, "Replaces the encounter/quest power bar (e.g. Boss mechanics) with a styled version.", 12, C.textMuted)
    note:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 26, -4)
    note:SetWidth(600)
    yOffset = yOffset - 50
    
    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 140, 24, function()
        if ns.Styling and ns.Styling.TogglePowerBarMover then
            ns.Styling:TogglePowerBarMover()
        end
    end)
    moverBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtn = GUI:CreateButton(content, "Reset Position", 140, 24, function()
        if ns.Styling and ns.Styling.ResetPowerBarPosition then
            ns.Styling:ResetPowerBarPosition()
        end
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
    
    local enable = GUI:CreateCheckbox(content, "Enable Skinning", "enabled", db, function(v)
        if ns.Alerts and ns.Alerts.Initialize then
             ns.Alerts:Initialize()
        end
    end)
    enable:SetPoint("TOPLEFT", PAD, yOffset)
    
    local note = GUI:CreateLabel(content, "Skins Blizzard alert frames (Achievements, Loot, etc.) and allows custom positioning.", 12, C.textMuted)
    note:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 26, -4)
    note:SetWidth(600)
    yOffset = yOffset - 40
    
    -- Background Color Customization
    local bgPicker -- Forward declare
    local bgCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Background", "disableThemeColorBackground", db, function(value)
        if bgPicker then
            if value then bgPicker:Show() else bgPicker:Hide() end
        end
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    bgCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    bgPicker = GUI:CreateColorPicker(content, "Background Color", "customBackgroundColor", db, function()
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    bgPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not db.disableThemeColorBackground then
        bgPicker:Hide()
    end
    
    -- Font Color Customization
    local fontPicker -- Forward declare
    local fontCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Font", "disableThemeColorFont", db, function(value)
        if fontPicker then
            if value then fontPicker:Show() else fontPicker:Hide() end
        end
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    fontCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    fontPicker = GUI:CreateColorPicker(content, "Font Color", "customFontColor", db, function()
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
    end)
    fontPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not db.disableThemeColorFont then
        fontPicker:Hide()
    end
    
    yOffset = yOffset - 10
    
    local moverBtn = GUI:CreateButton(content, "Toggle Movers", 140, 24, function()
        if ns.Alerts and ns.Alerts.ToggleMovers then
            ns.Alerts:ToggleMovers()
        end
    end)
    moverBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtn = GUI:CreateButton(content, "Reset Positions", 140, 24, function()
        if ns.Alerts and ns.Alerts.ResetPositions then
            ns.Alerts:ResetPositions()
        end
    end)
    resetBtn:SetPoint("LEFT", moverBtn, "RIGHT", 10, 0)
    
    local testBtn = GUI:CreateButton(content, "Test Alerts", 140, 24, function()
        if ns.Alerts and ns.Alerts.Test then
            ns.Alerts:Test()
        end
    end)
    testBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)
    
    yOffset = yOffset - 50

    local growOptions = {
        { text = "Grow Up", value = "UP" },
        { text = "Grow Down", value = "DOWN" },
    }

    local alertGrow = GUI:CreateDropdown(content, "Alert Frame Growth", growOptions, "alertGrowDirection", db, function()
        if AlertFrame and AlertFrame.UpdateAnchors then
            AlertFrame:UpdateAnchors()
        end
    end)
    alertGrow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50

    local toastGrow = GUI:CreateDropdown(content, "Event Toast Growth", growOptions, "toastGrowDirection", db, function()
        if EventToastManagerFrame and EventToastManagerFrame.UpdateAnchor then
            EventToastManagerFrame:UpdateAnchor()
        end
    end)
    toastGrow:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50

    local alertOffset = GUI:CreateSlider(content, "Alert Y-Offset", -400, 400, "alertYOffset", db, function(value)
        if AlertFrame and AlertFrame.UpdateAnchors then
            AlertFrame:UpdateAnchors()
        end
    end, 1)
    alertOffset:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50

    local toastOffset = GUI:CreateSlider(content, "Toast Y-Offset", -400, 400, "toastYOffset", db, function(value)
        if EventToastManagerFrame and EventToastManagerFrame.UpdateAnchor then
            EventToastManagerFrame:UpdateAnchor()
        end
    end, 1)
    toastOffset:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50
    
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
    
    local desc1 = GUI:CreateLabel(content, "Replace Blizzard's loot window with a custom GUI-styled frame.", 12, C.textMuted)
    desc1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 35
    
    local skinLoot = GUI:CreateCheckbox(content, "Skin Loot Window", "enabled", db.loot, function(v)
        if ns.Loot and ns.Loot.Initialize then
             ns.Loot:Initialize()
        end
    end)
    skinLoot:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 40
    
    local underMouse = GUI:CreateCheckbox(content, "Loot Under Mouse", "lootUnderMouse", db.loot)
    underMouse:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 40
    
    local transmog = GUI:CreateCheckbox(content, "Show Transmog Markers", "showTransmogMarkers", db.loot)
    transmog:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 40

    -- Background Color Customization
    local bgPicker1 -- Forward declare
    local bgCheck1 = GUI:CreateCheckbox(content, "Don't Use Theme Color for Background", "disableThemeColorBackground", db.loot, function(value)
        if bgPicker1 then
            if value then bgPicker1:Show() else bgPicker1:Hide() end
        end
        if ns.Loot and ns.Loot.RefreshStyling then ns.Loot.RefreshStyling() end
    end)
    bgCheck1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    bgPicker1 = GUI:CreateColorPicker(content, "Background Color", "customBackgroundColor", db.loot, function()
        if ns.Loot and ns.Loot.RefreshStyling then ns.Loot.RefreshStyling() end
    end)
    bgPicker1:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not db.loot.disableThemeColorBackground then
        bgPicker1:Hide()
    end
    
    -- Font Color Customization
    local fontPicker1 -- Forward declare
    local fontCheck1 = GUI:CreateCheckbox(content, "Don't Use Theme Color for Font", "disableThemeColorFont", db.loot, function(value)
        if fontPicker1 then
            if value then fontPicker1:Show() else fontPicker1:Hide() end
        end
        if ns.Loot and ns.Loot.RefreshStyling then ns.Loot.RefreshStyling() end
    end)
    fontCheck1:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    fontPicker1 = GUI:CreateColorPicker(content, "Font Color", "customFontColor", db.loot, function()
        if ns.Loot and ns.Loot.RefreshStyling then ns.Loot.RefreshStyling() end
    end)
    fontPicker1:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not db.loot.disableThemeColorFont then
        fontPicker1:Hide()
    end

    yOffset = yOffset - 10

    local moveBtn = GUI:CreateButton(content, "Toggle Mover", 160, 24, function()
        if ns.Loot and ns.Loot.ToggleMover then
             ns.Loot:ToggleMover()
        end
    end)
    moveBtn:SetPoint("TOPLEFT", PAD, yOffset)
    
    local resetBtn = GUI:CreateButton(content, "Reset Position", 160, 24, function()
        if ns.Loot and ns.Loot.ResetPosition then
             ns.Loot:ResetPosition()
        end
    end)
    resetBtn:SetPoint("LEFT", moveBtn, "RIGHT", 10, 0)
    yOffset = yOffset - 50
    
    -- 2. LOOT HISTORY
    local header2 = GUI:CreateSectionHeader(content, "Loot History")
    header2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header2.gap
    
    local desc2 = GUI:CreateLabel(content, "Apply GUI styling to the loot roll results panel.", 12, C.textMuted)
    desc2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 35
    
    local skinHistory = GUI:CreateCheckbox(content, "Skin Loot History", "enabled", db.lootResults)
    skinHistory:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 40

    -- Background Color Customization
    local bgPicker2 -- Forward declare
    local bgCheck2 = GUI:CreateCheckbox(content, "Don't Use Theme Color for Background", "disableThemeColorBackground", db.lootResults, function(value)
        if bgPicker2 then
            if value then bgPicker2:Show() else bgPicker2:Hide() end
        end
        -- History skinning might only apply on reload or new frames, but we'll call any refresh available
        if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot.RefreshHistoryStyling() end
    end)
    bgCheck2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    bgPicker2 = GUI:CreateColorPicker(content, "Background Color", "customBackgroundColor", db.lootResults, function()
        if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot.RefreshHistoryStyling() end
    end)
    bgPicker2:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not db.lootResults.disableThemeColorBackground then
        bgPicker2:Hide()
    end
    
    -- Font Color Customization
    local fontPicker2 -- Forward declare
    local fontCheck2 = GUI:CreateCheckbox(content, "Don't Use Theme Color for Font", "disableThemeColorFont", db.lootResults, function(value)
        if fontPicker2 then
            if value then fontPicker2:Show() else fontPicker2:Hide() end
        end
        if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot.RefreshHistoryStyling() end
    end)
    fontCheck2:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    fontPicker2 = GUI:CreateColorPicker(content, "Font Color", "customFontColor", db.lootResults, function()
        if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot.RefreshHistoryStyling() end
    end)
    fontPicker2:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Visibility
    if not db.lootResults.disableThemeColorFont then
        fontPicker2:Hide()
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
    
    local wipNote = GUI:CreateLabel(content, "Work-in-progress: Enable only if you want to test. Still being polished.", 12, C.warning)
    wipNote:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 25
    
    local desc = GUI:CreateLabel(content, "Apply GUI styling to quest objectives, achievement tracking, and bonus objectives.", 12, C.textMuted)
    desc:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 35
    
    local enable = GUI:CreateCheckbox(content, "Skin Objective Tracker", "enabled", db, function(v)
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    enable:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 40
    
    local heightSlider = GUI:CreateSlider(content, "Max Height", 200, 1000, "height", db, function(v)
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end, 10)
    heightSlider:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50
    
    local moduleFontSlider = GUI:CreateSlider(content, "Module Header Font (QUESTS, etc.)", 8, 24, "moduleFontSize", db, function(v)
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end, 1)
    moduleFontSlider:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50

    local titleFontSlider = GUI:CreateSlider(content, "Quest/Achievement Title Font", 8, 24, "titleFontSize", db, function(v)
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end, 1)
    titleFontSlider:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50

    local textFontSlider = GUI:CreateSlider(content, "Objective Text Font", 8, 24, "textFontSize", db, function(v)
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end, 1)
    textFontSlider:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50
    
    local widthSlider = GUI:CreateSlider(content, "Max Width", 200, 400, "width", db, function(v)
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end, 1)
    widthSlider:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 50
    
    local hideBorder = GUI:CreateCheckbox(content, "Hide Border", "hideBorder", db, function(v)
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    hideBorder:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 45

    local moduleColor = GUI:CreateColorPicker(content, "Module Header Color (QUESTS, etc.)", "moduleColor", db, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    moduleColor:SetPoint("TOPLEFT", PAD, yOffset)
    moduleColor:SetWidth(400)
    yOffset = yOffset - 40

    local titleColor = GUI:CreateColorPicker(content, "Quest/Achievement Title Color", "titleColor", db, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    titleColor:SetPoint("TOPLEFT", PAD, yOffset)
    titleColor:SetWidth(400)
    yOffset = yOffset - 40

    local textColor = GUI:CreateColorPicker(content, "Objective Text Color", "textColor", db, function()
        if ns.Objectives and ns.Objectives.Refresh then ns.Objectives:Refresh() end
    end)
    textColor:SetPoint("TOPLEFT", PAD, yOffset)
    textColor:SetWidth(400)
    yOffset = yOffset - 40
    
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
    
    local enable = GUI:CreateCheckbox(content, "Enable Custom Instance Frame Styling", "enabled", ns.db.profile.styling.instanceFrames, function(v)
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then
             ns.InstanceFrames:Initialize()
        end
    end)
    enable:SetPoint("TOPLEFT", PAD, yOffset)
    
    local note = GUI:CreateLabel(content, "Skins the PVE Frame (Dungeon Finder, Raid Finder, Premade Groups) and Mythic+ frames.", 12, C.textMuted)
    note:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 26, -4)
    note:SetWidth(600)
    
    yOffset = yOffset - 40
    
    local db = ns.db.profile.styling.instanceFrames
    
    -- Background Color Customization
    local bgPicker -- Forward declare
    local bgCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Background", "disableThemeColorBackground", db, function(value)
        if bgPicker then
            if value then bgPicker:Show() else bgPicker:Hide() end
        end
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    bgCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    bgPicker = GUI:CreateColorPicker(content, "Background Color", "customBackgroundColor", db, function()
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    bgPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Background Visibility
    if not db.disableThemeColorBackground then
        bgPicker:Hide()
    end
    
    -- Border Color Customization
    local borderPicker -- Forward declare
    local borderCheck = GUI:CreateCheckbox(content, "Don't Use Theme Color for Border", "disableThemeColorBorder", db, function(value)
        if borderPicker then
            if value then borderPicker:Show() else borderPicker:Hide() end
        end
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    borderCheck:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 30
    
    borderPicker = GUI:CreateColorPicker(content, "Border Color", "customBorderColor", db, function()
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    borderPicker:SetPoint("TOPLEFT", PAD + 20, yOffset)
    yOffset = yOffset - 40
    
    -- Initialize Border Visibility
    if not db.disableThemeColorBorder then
        borderPicker:Hide()
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
