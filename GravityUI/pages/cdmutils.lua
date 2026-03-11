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
    
    if ns.GUI and ns.GUI.RegisterInSearchIndex then
        ns.GUI:RegisterInSearchIndex(labelText, row)
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

-- 5. CDM Buffbar
local function BuildCDMBuffbar(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    
    -- Default to actionbars.cdmBuffbar as planned
    local dbCDM = db.actionbars.cdmBuffbar
    if not dbCDM then 
        dbCDM = {} 
        db.actionbars.cdmBuffbar = dbCDM 
    end
    
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "CDM Buffbar")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    local function RefreshCDM() 
        if ns.CDM and ns.CDM.RefreshBuffBar then ns.CDM.RefreshBuffBar() end 
    end

    -- Info Box
    local infoBox = GUI:CreateInfoBox(content, "Bar Width, Opacity, Visibility, Display Mode, Timer, Tooltips and Position can be changed in the Editmode.")
    infoBox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
    
    content.rowCount = 1.3 + (infoBox:GetHeight() / 30) + 0.5

    CreateSubLabel(content, "Tracked Buffbar")
    AddRow(content, "Enable GUI Buffbar", "checkbox", "enabled", dbCDM, RefreshCDM)
    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Dynamic Positioning")
    AddRow(content, "Enable Dynamic Positioning", "checkbox", "dynamicPositioning", dbCDM, RefreshCDM)
    
    local dirOptions = {{value="UP", text="Grow Up"}, {value="DOWN", text="Grow Down"}}
    AddRow(content, "Grow Direction", "dropdown", dirOptions, "growDirection", dbCDM, RefreshCDM)
    
    AddRow(content, "Spacing", "slider", -10, 20, "spacing", dbCDM, RefreshCDM, 1)
    
    -- Anchor is now handled automatically
    local updateBtn = GUI:CreateButton(content, "Force Layout Update", 150, 30)
    updateBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * 35))
    updateBtn:SetScript("OnClick", function() 
        if ns.TrackedBuffBar and ns.TrackedBuffBar.UpdateLayout then 
            ns.TrackedBuffBar:UpdateLayout() 
        end 
    end)
    content.rowCount = content.rowCount + 1.5

    CreateSubLabel(content, "Bar Appearance")
    
    -- Texture Dropdown
    local textureOptions = {{value="Solid", text="Solid"}, {value="Interface/AddOns/GravityUI/assets/textures/Flat.tga", text="Flat"}}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then 
        textureOptions = {}
        for name, _ in pairs(LSM:HashTable("statusbar")) do table.insert(textureOptions, {value=name, text=name}) end
        table.sort(textureOptions, function(a,b) return a.text < b.text end)
    end
    AddRow(content, "Bar Texture", "dropdown", textureOptions, "texture", dbCDM, RefreshCDM)
    
    AddRow(content, "Bar Height", "slider", 5, 50, "height", dbCDM, RefreshCDM, 1)
    -- Width removed by user request
    
    AddRow(content, "Font Size", "slider", 8, 24, "fontSize", dbCDM, RefreshCDM, 1)
    

    
    -- Font Dropdown
    local fontOptions = {{value="Gravity", text="Gravity"}}
    if LSM then
        fontOptions = {}
        for name, _ in pairs(LSM:HashTable("font")) do table.insert(fontOptions, {value=name, text=name}) end
        table.sort(fontOptions, function(a,b) return a.text < b.text end)
    end
    AddRow(content, "Font", "dropdown", fontOptions, "font", dbCDM, RefreshCDM)
    

    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Colors")
    AddRow(content, "Use Default Background Color", "checkbox", "useThemeBackground", dbCDM, RefreshCDM)
    AddRow(content, "Background Color", "color", "backgroundColor", dbCDM, RefreshCDM)
    
    AddRow(content, "Use Theme Color for Bars", "checkbox", "useThemeColor", dbCDM, RefreshCDM)
    AddRow(content, "Bar Color", "color", "barColor", dbCDM, RefreshCDM)
    AddRow(content, "Spark Color", "color", "sparkColor", dbCDM, RefreshCDM)
    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Icons")
    AddRow(content, "Icon Size", "slider", 10, 50, "iconSize", dbCDM, RefreshCDM, 1)
    AddRow(content, "Icon Border Size", "slider", 0, 5, "iconBorderSize", dbCDM, RefreshCDM, 1)
    AddRow(content, "Icon Border Color", "color", "iconBorderColor", dbCDM, RefreshCDM)
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 6. Sound Alerts
local function BuildSoundAlerts(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end

    if not db.soundAlerts then
        db.soundAlerts = { enabled = false }
    end
    local saDB = db.soundAlerts

    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Sound Alerts")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local infoBox = GUI:CreateInfoBox(content, "When enabled, all sounds registered in LibSharedMedia appear under a \"GravityUI\" section inside Blizzard's CooldownViewer alert sound dropdown.\n\nTo use: open the Cooldown Manager settings, edit an alert, select Sound, then choose a sound from the GravityUI section.\n\n|cffFFCC00Note:|r Enabling this module requires a /reload to take effect. Disabling requires a /reload as well.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.3

    local function RefreshSA()
        if ns.SoundAlerts and ns.SoundAlerts.ApplySettings then ns.SoundAlerts.ApplySettings() end
    end

    AddRow(content, "Enable Custom Sounds in CDM", "checkbox", "enabled", saDB, RefreshSA)

    local channelOptions = {
        { value = "Master", text = "Master" },
        { value = "SFX", text = "SFX" },
    }
    AddRow(content, "Sound Channel", "dropdown", channelOptions, "channel", saDB, RefreshSA)

    content.rowCount = content.rowCount + 0.5
end


-- ═══════════════════════════════════════════════════════════════
-- MAIN PAGE REGISTER
-- ═══════════════════════════════════════════════════════════════

ns.GUI:RegisterPage("cdmutils", {
    title = "UI Utilities",
    subTabs = {
        { name = "CDM Keybindings", builder = BuildGUICDMKeybinds },
        { name = "CDM Centering", builder = BuildCDMCentering },
        { name = "CDM Button Glow", builder = BuildUtils },
        { name = "Castbar Ticks", builder = BuildCastbar },
        { name = "CDM Buffbar", builder = BuildCDMBuffbar },
        { name = "Sound Alerts", builder = BuildSoundAlerts },
    },
    OnBuild = function(content)
        -- Hide default scrollframe parent
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        local opts = GUI.pages["cdmutils"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["cdmutils"]
        if not opts.subTabsContainer then return end
        
        subIndex = subIndex or 1
        
        for _, cf in pairs(opts.subTabsContainer.tabContents) do
            cf:Hide()
        end
        
        if opts.subTabsContainer.tabContents[subIndex] then
            opts.subTabsContainer.tabContents[subIndex]:Show()
        end
    end
})
