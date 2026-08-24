-- GravityUI - Utilities Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

--==============================================================================================================================================================================================
-- SHARED HELPERS
--==============================================================================================================================================================================================
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
    if ns.GUI.SetFont then ns.GUI:SetFont(label, 12, "") else label:SetFont(STANDARD_TEXT_FONT, 12, "") end
    label:SetText(text)
    label:SetTextColor(unpack(GUI.Colors.accent))
    label:SetPoint("TOPLEFT", 10, -parent.rowCount * (ROW_HEIGHT + 5))
    parent.rowCount = parent.rowCount + 0.8
    return label
end

local anchorOptions = { {value = "TOPLEFT", text = "Top Left"}, {value = "TOP", text = "Top"}, {value = "TOPRIGHT", text = "Top Right"}, {value = "LEFT", text = "Left"}, {value = "CENTER", text = "Center"}, {value = "RIGHT", text = "Right"}, {value = "BOTTOMLEFT", text = "Bottom Left"}, {value = "BOTTOM", text = "Bottom"}, {value = "BOTTOMRIGHT", text = "Bottom Right"} }

--==============================================================================================================================================================================================
-- BUILDERS
--==============================================================================================================================================================================================


local function BuildSoundAlerts(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.soundAlerts then db.soundAlerts = { enabled = false } end
    local saDB = db.soundAlerts
    content.rowCount = 0
    local header = GUI:CreateSectionHeader(content, "Sound Alerts")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    local infoBox = GUI:CreateInfoBox(content, "When enabled, all sounds registered in LibSharedMedia appear under a \"GravityUI\" section inside Blizzard's CooldownViewer alert sound dropdown.\n\nTo use: open the Cooldown Manager settings, edit an alert, select Sound, then choose a sound from the GravityUI section.\n\n|cffFFCC00Note:|r Enabling this module requires a /reload to take effect. Disabling requires a /reload as well.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5)); content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.3
    local function RefreshSA() if ns.SoundAlerts and ns.SoundAlerts.ApplySettings then ns.SoundAlerts.ApplySettings() end end
    AddRow(content, "Enable Custom Sounds in CDM", "checkbox", "enabled", saDB, RefreshSA)
    local channelOptions = { { value = "Master", text = "Master" }, { value = "SFX", text = "SFX" } }
    AddRow(content, "Sound Channel", "dropdown", channelOptions, "channel", saDB, RefreshSA)
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- TRACKED BARS
--==============================================================================================================================================================================================

local function BuildTrackedBars(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    content.rowCount = 0

    local function DB()
        local db = ns.GetDB()
        return db and db.actionbars and db.actionbars.cdmBuffbar
    end

    local function Refresh()
        local mod = ns.TrackedBuffBar
        if mod and mod.Refresh then mod:Refresh() end
    end

    -- Header
    local header = GUI:CreateSectionHeader(content, "Tracked Bars (Blizzard CDM)")
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    content.rowCount = content.rowCount + 1.5

    local infoBox = GUI:CreateInfoBox(content,
        "Skins the Blizzard \"Tracked Bars\" (BuffBarCooldownViewer / CDM) with GravityUI colours, " ..
        "bar texture and optional Dynamic Growth.\n\n" ..
        "|cffFFCC00Note:|r Bars must be visible (open a M+ or use a Tracked ability) for changes to apply.",
        GUI.CONTENT_WIDTH - 40)
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    content.rowCount = content.rowCount + 2

    -- ── Master ───────────────────────────────────────────────────────────────
    CreateSubLabel(content, "General")
    AddRow(content, "Enable Tracked Bars", "checkbox", "enabled", DB(), function(val)
        local d = DB(); if d then d.enabled = val end
        Refresh()
    end)

    -- Bar Texture (LSM statusbar list)
    local textureOptions = { { value = "Gravity Normal", text = "Gravity Normal" } }
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        textureOptions = {}
        for name, _ in pairs(LSM:HashTable("statusbar")) do
            table.insert(textureOptions, { value = name, text = name })
        end
        table.sort(textureOptions, function(a, b) return a.text < b.text end)
    end
    AddRow(content, "Bar Texture", "dropdown", textureOptions, "texture", DB(), Refresh)

    AddRow(content, "Bar Height",  "slider", 12, 40, "height",   DB(), Refresh, 1)
    AddRow(content, "Font Size",   "slider",  8, 18, "fontSize", DB(), Refresh, 1)

    -- Font (LSM font list)
    local fontOptions = { { value = "Gravity", text = "Gravity" } }
    if LSM then
        fontOptions = {}
        for name, _ in pairs(LSM:HashTable("font")) do
            table.insert(fontOptions, { value = name, text = name })
        end
        table.sort(fontOptions, function(a, b) return a.text < b.text end)
    end
    AddRow(content, "Font", "dropdown", fontOptions, "font", DB(), Refresh)

    -- ── Colors ───────────────────────────────────────────────────────────────
    CreateSubLabel(content, "Bar Color")
    AddRow(content, "Use Theme Color",    "checkbox", "useThemeColor",   DB(), Refresh)
    AddRow(content, "Bar Color",          "color",    "barColor",        DB(), Refresh)

    CreateSubLabel(content, "Background")
    AddRow(content, "Use Theme Background", "checkbox", "useThemeBackground", DB(), Refresh)
    AddRow(content, "Background Color",     "color",    "backgroundColor",   DB(), Refresh)

    CreateSubLabel(content, "Spark")
    AddRow(content, "Spark Color", "color", "sparkColor", DB(), Refresh)

    -- ── Icon ─────────────────────────────────────────────────────────────────
    CreateSubLabel(content, "Icon")
    AddRow(content, "Icon Size",         "slider", 12, 40, "iconSize",      DB(), Refresh, 1)
    AddRow(content, "Icon Border Size",  "slider",  0,  5, "iconBorderSize",DB(), Refresh, 1)
    AddRow(content, "Icon Border Color", "color",  "iconBorderColor", DB(), Refresh)

    -- ── Dynamic Growth ───────────────────────────────────────────────────────
    CreateSubLabel(content, "Dynamic Growth")
    AddRow(content, "Enable Dynamic Growth", "checkbox", "dynamicPositioning", DB(), Refresh)

    local growOptions = {
        { value = "DOWN", text = "Grow Down" },
        { value = "UP",   text = "Grow Up"   },
    }
    local growRow = CreatePropertyRow(content, "Grow Direction", "dropdown", growOptions, "growDirection", DB(), Refresh)
    growRow:SetParent(content)
    growRow:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    content.rowCount = content.rowCount + 1

    AddRow(content, "Bar Spacing", "slider", -50, 50, "spacing", DB(), Refresh, 1)

    content:SetHeight(content.rowCount * (ROW_HEIGHT + 5) + 20)
end

--==============================================================================================================================================================================================
-- COLOR PICKER SETTINGS
--==============================================================================================================================================================================================

local function BuildColorPickerSettings(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.colorPicker then
        db.colorPicker = { enabled = true, hookAllAddons = false, useSquarePicker = true, savedColors = {}, recentColors = {} }
    end
    local cpDB = db.colorPicker
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Color Picker")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local infoBox = GUI:CreateInfoBox(content,
        "A fully custom Color Picker that replaces Blizzard's built-in color selection window. " ..
        "You can use it only within GravityUI, or enable it globally so every addon uses it too.\n\n" ..
        "|cffFFCC00What's included:|r  Color selector with hue & brightness sliders  •  " ..
        "New / Prev color preview  •  Recent colors  •  Class colors  •  Theme colors  •  Saved color slots  •  Hex input (paste with Ctrl+V, copy with click + Ctrl+C)")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    infoBox:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.3

    -- ── Master Enable ────────────────────────────────────────
    AddRow(content, "Enable Custom Color Picker", "checkbox", "enabled", cpDB, function(val)
        cpDB.enabled = val
        -- If disabling GravityUI picker, also disable global hook
        if not val then
            cpDB.hookAllAddons = false
            if ns.ColorPicker then ns.ColorPicker:SetGlobalHookEnabled(false) end
        end
    end)

    content.rowCount = content.rowCount + 0.3

    local hookInfoBox = GUI:CreateInfoBox(content,
        "|cffFFCC00Use for all addons:|r When enabled, the GravityUI Color Picker replaces the color " ..
        "picker everywhere — including Blizzard's built-in picker and |cff00aaffEllesmereUI's|r " ..
        "own color picker.\n\n" ..
        "|cff888888Requires 'Enable Custom Color Picker' to be active. Cannot be undone until /reload.|r")
    hookInfoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    hookInfoBox:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + (hookInfoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.3

    AddRow(content, "Use for all addons", "checkbox", "hookAllAddons", cpDB, function(val)
        cpDB.hookAllAddons = val
        if ns.ColorPicker then ns.ColorPicker:SetGlobalHookEnabled(val) end
    end)




    -- ── Saved Colors ──────────────────────────────────────────
    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Saved Colors")
    content.rowCount = content.rowCount + 0.3

    local clearSavedBtn = GUI:CreateButton(content, "Clear Saved Colors", 160, 24, function()
        if cpDB.savedColors then wipe(cpDB.savedColors) end
        print("|cff00aaff[GravityUI]|r Saved colors cleared.")
    end)
    clearSavedBtn:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))

    local clearRecentBtn = GUI:CreateButton(content, "Clear Recent Colors", 160, 24, function()
        if cpDB.recentColors then wipe(cpDB.recentColors) end
        print("|cff00aaff[GravityUI]|r Recent colors cleared.")
    end)
    clearRecentBtn:SetPoint("LEFT", clearSavedBtn, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.2

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- PREMADE GROUP
--==============================================================================================================================================================================================

local function BuildPremadeGroup(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.uiimprovements then db.uiimprovements = {} end
    local uiDB = db.uiimprovements
    content.rowCount = 0

    -- Header
    local header = GUI:CreateSectionHeader(content, "Premade Group")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    -- Info box (compact)
    local infoBox = GUI:CreateInfoBox(content,
        "Adds a |cff30D1FFSelect Group Key|r dropdown to the Group Finder. Select a keystone to auto-fill dungeon, title and playstyle when creating a group.\n" ..
        "|cff888888Requires GravityUI, BigWigs/LittleWigs, or AstralKeys on all members.|r")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    infoBox:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.4

    -- Enable toggle
    local function Refresh()
        if ns.PremadeGroup and ns.PremadeGroup.ApplySettings then
            ns.PremadeGroup:ApplySettings()
        end
    end
    AddRow(content, "Enable Premade Group Dropdown", "checkbox", "premadeGroupEnabled", uiDB, Refresh)

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Group Creation")
    content.rowCount = content.rowCount + 0.3

    local playstyleOptions = {
        { value = 0, text = "Don't set" },
        { value = 1, text = "Learning" },
        { value = 2, text = "Relaxed" },
        { value = 3, text = "Competitive" },
        { value = 4, text = "Carry Offered" },
    }
    AddRow(content, "Default Playstyle", "dropdown", playstyleOptions, "premadeGroupPlaystyle", uiDB, Refresh)

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Season Config")
    content.rowCount = content.rowCount + 0.3

    local seasonInfo = GUI:CreateInfoBox(content,
        "|cff888888Current Season:|r |cffFFFFFFMidnight Season 2|r  |cff888888(12.1)|r\n" ..
        "Voidscar Arena, The Blinding Vale, Temple of Sethraliss, Ruby Life Pools, Murder Row, Kings' Rest, Den of Nalorakk, Altar of Fangs")
    seasonInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    seasonInfo:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + (seasonInfo:GetHeight() / (ROW_HEIGHT + 5)) + 0.3

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- INJECT INTO FEATURES & INDICATORS (no separate Utilities page)
--==============================================================================================================================================================================================

-- Tracked Bars → Indicators
local indicatorPage = GUI.pages and GUI.pages["indicators"]
if indicatorPage and indicatorPage.subTabs then
    table.insert(indicatorPage.subTabs, { name = "Tracked Bars", builder = BuildTrackedBars })
end

-- Sound Alerts, Color Picker, Premade Group → Features
local featuresPage = GUI.pages and GUI.pages["features"]
if featuresPage and featuresPage.subTabs then
    table.insert(featuresPage.subTabs, { name = "Sound Alerts",  builder = BuildSoundAlerts })
    table.insert(featuresPage.subTabs, { name = "Color Picker",  builder = BuildColorPickerSettings })
    table.insert(featuresPage.subTabs, { name = "Premade Group", builder = BuildPremadeGroup })
end
