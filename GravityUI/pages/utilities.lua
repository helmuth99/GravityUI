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
-- DEBUFFS
--==============================================================================================================================================================================================

local function BuildDebuffs(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.debuffMirror then
        db.debuffMirror = { enabled = false, iconSize = 32, spacing = 4, iconsPerRow = 8, maxDebuffs = 16, growDirection = "RIGHT", hideOriginal = false,
            position = { point = "CENTER", relPoint = "CENTER", x = 0, y = -200 } }
    end
    local dmDB = db.debuffMirror
    content.rowCount = 0

    -- Header
    local header = GUI:CreateSectionHeader(content, "Debuff Mirror")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    -- Info
    local infoBox = GUI:CreateInfoBox(content, "|cffFFCC00Info:|r Creates a 1:1 copy of your active debuffs with a clean 1px border, freely positionable anywhere on screen.\n\n|cFFFFFFFFNote:|r Use the 'Toggle Mover' button below to drag the frame to your desired position.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    infoBox:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.3

    -- Refresh helper
    local function Refresh()
        if ns.DebuffMirror and ns.DebuffMirror.ApplySettings then
            ns.DebuffMirror:ApplySettings()
        end
    end

    -- Master enable
    AddRow(content, "Enable Debuff Mirror", "checkbox", "enabled", dmDB, Refresh)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Appearance")
    content.rowCount = content.rowCount + 0.3

    AddRow(content, "Icon Size",            "slider", 16, 64, "iconSize",    dmDB, Refresh, 2)
    AddRow(content, "Icon Spacing",         "slider", 0,  20, "spacing",     dmDB, Refresh, 1)
    AddRow(content, "Icons per Row",        "slider", 1,  32, "iconsPerRow", dmDB, Refresh, 1)
    AddRow(content, "Max Debuffs",          "slider", 1,  40, "maxDebuffs",  dmDB, Refresh, 1)

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Layout")
    content.rowCount = content.rowCount + 0.3

    local growOptions = {
        { value = "RIGHT", text = "Right" },
        { value = "LEFT",  text = "Left"  },
        { value = "DOWN",  text = "Down"  },
        { value = "UP",    text = "Up"    },
    }
    AddRow(content, "Grow Direction", "dropdown", growOptions, "growDirection", dmDB, Refresh)

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Original Frame")
    content.rowCount = content.rowCount + 0.3

    AddRow(content, "Hide Blizzard Debuff Frame", "checkbox", "hideOriginal", dmDB, Refresh)

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Text")
    content.rowCount = content.rowCount + 0.3

    AddRow(content, "Duration Font Size", "slider", 6, 24, "textFontSize",  dmDB, Refresh, 1)
    AddRow(content, "Stack Count Font Size", "slider", 6, 24, "countFontSize", dmDB, Refresh, 1)

    local outlineOptions = {
        { value = "OUTLINE",      text = "Outline" },
        { value = "THICKOUTLINE", text = "Thick Outline" },
        { value = "MONOCHROME",   text = "Monochrome" },
        { value = "",             text = "No Outline" },
    }
    AddRow(content, "Text Outline", "dropdown", outlineOptions, "textOutline", dmDB, Refresh)

    AddRow(content, "Show Stack Count", "checkbox", "showCount",    dmDB, Refresh)
    AddRow(content, "Show Duration",    "checkbox", "showDuration", dmDB, Refresh)
    AddRow(content, "Show Tooltips",    "checkbox", "showTooltip",  dmDB, Refresh)

    local countAnchorOptions = {
        { value = "BOTTOMRIGHT", text = "Bottom Right" },
        { value = "BOTTOMLEFT",  text = "Bottom Left"  },
        { value = "TOPRIGHT",    text = "Top Right"    },
        { value = "TOPLEFT",     text = "Top Left"     },
    }
    AddRow(content, "Stack Count Position", "dropdown", countAnchorOptions, "countAnchor", dmDB, Refresh)

    local durAnchorOptions = {
        { value = "TOP",    text = "Top"    },
        { value = "BOTTOM", text = "Bottom" },
        { value = "CENTER", text = "Center" },
    }
    AddRow(content, "Duration Position", "dropdown", durAnchorOptions, "durationAnchor", dmDB, Refresh)

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Position")
    content.rowCount = content.rowCount + 0.3

    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 160, 24, function()
        if ns.DebuffMirror and ns.DebuffMirror.ToggleMover then
            ns.DebuffMirror:ToggleMover()
        end
    end)
    moverBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))

    local resetBtn = GUI:CreateButton(content, "Reset Position", 160, 24, function()
        if ns.DebuffMirror and ns.DebuffMirror.ResetPosition then
            ns.DebuffMirror:ResetPosition()
        end
    end)
    resetBtn:SetPoint("LEFT", moverBtn, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.2

    -- =========================================================================
    -- BLACKLIST
    -- =========================================================================
    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Blacklist")
    content.rowCount = content.rowCount + 0.3

    local blInfo = GUI:CreateInfoBox(content,
        "|cffFFCC00Info:|r Enter a spell name or spell ID number to hide that debuff from the mirror. " ..
        "Hover a debuff icon (with tooltips on) to see its name.")
    blInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    blInfo:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + (blInfo:GetHeight() / (ROW_HEIGHT + 5)) + 0.3

    -- Input row: EditBox + Add button
    local inputY = -(content.rowCount * (ROW_HEIGHT + 5)) - 4

    local inputBox = CreateFrame("EditBox", nil, content, "BackdropTemplate")
    inputBox:SetHeight(26)
    inputBox:SetPoint("TOPLEFT", 10, inputY)
    inputBox:SetPoint("RIGHT", content, "RIGHT", -80, 0)
    inputBox:SetAutoFocus(false)
    if ns.GUI.SetFont then ns.GUI:SetFont(inputBox, 11, "") end
    inputBox:SetTextInsets(6, 6, 0, 0)
    inputBox:SetMaxLetters(120)
    inputBox:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    inputBox:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
    inputBox:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() self:SetText("") end)

    -- Placeholder text
    local placeholder = inputBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", inputBox, "LEFT", 8, 0)
    placeholder:SetText("Spell name or ID…")
    inputBox:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    inputBox:SetScript("OnEditFocusLost", function(s)
        if s:GetText() == "" then placeholder:Show() end
    end)

    local addBtn = GUI:CreateButton(content, "Add", 64, 26, nil)
    addBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, inputY)

    content.rowCount = content.rowCount + 1.3

    -- Pre-allocate rows (WoW cannot destroy frames; show/hide instead)
    local MAX_BL = 20
    local blStartRow = content.rowCount
    local blRows = {}
    for i = 1, MAX_BL do
        local rowY = -((blStartRow + (i - 1) * 1.1) * (ROW_HEIGHT + 5)) - 4
        local rf = CreateFrame("Frame", nil, content)
        rf:SetHeight(ROW_HEIGHT - 4)
        rf:SetPoint("TOPLEFT", 10, rowY)
        rf:SetPoint("RIGHT", content, "RIGHT", -10, 0)
        rf:Hide()

        local lbl = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", 4, 0)
        lbl:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)

        local rb = GUI:CreateButton(rf, "Remove", 70, ROW_HEIGHT - 6, nil)
        rb:SetPoint("RIGHT", rf, "RIGHT", 0, 0)

        blRows[i] = { frame = rf, label = lbl, btn = rb }
    end

    -- RebuildBlacklist: shows current entries and updates content height
    local function RebuildBlacklist()
        for _, r in ipairs(blRows) do r.frame:Hide() end
        local i = 1
        if dmDB.blacklist then
            for key in pairs(dmDB.blacklist) do
                if i > MAX_BL then break end
                local r = blRows[i]
                r.label:SetText(tostring(key))
                local k = key
                r.btn:SetScript("OnClick", function()
                    dmDB.blacklist[k] = nil
                    RebuildBlacklist()
                    Refresh()
                end)
                r.frame:Show()
                i = i + 1
            end
        end
        local usedRows = i - 1
        local totalCount = blStartRow + usedRows * 1.1 + 1.5
        content:SetHeight(50 + (totalCount * (ROW_HEIGHT + 5)))
    end

    -- Wire up Add button and Enter key
    local function DoAdd()
        local raw = inputBox:GetText()
        local text = raw:match("^%s*(.-)%s*$")  -- trim whitespace
        if text == "" then return end
        if not dmDB.blacklist then dmDB.blacklist = {} end
        dmDB.blacklist[text] = true
        inputBox:SetText("")
        placeholder:Show()
        inputBox:ClearFocus()
        RebuildBlacklist()
        Refresh()
    end
    addBtn:SetScript("OnClick", DoAdd)
    inputBox:SetScript("OnEnterPressed", DoAdd)

    -- Initial build
    RebuildBlacklist()
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
        { value = 2, text = "Relaxed" },
        { value = 1, text = "Moderate" },
        { value = 3, text = "Hardcore" },
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
-- PAGE REGISTRATION
--==============================================================================================================================================================================================
ns.GUI:RegisterPage("utilities", {
    title = "Utilities",
    subTabs = {
        { name = "Sound Alerts",  builder = BuildSoundAlerts },
        { name = "Debuffs",       builder = BuildDebuffs },
        { name = "Tracked Bars",  builder = BuildTrackedBars },
        { name = "Color Picker",  builder = BuildColorPickerSettings },
        { name = "Premade Group",  builder = BuildPremadeGroup },
    },
    OnBuild = function(content)
        local scrollFrame = content:GetParent()
        content:Hide()
        if scrollFrame.ScrollBar then scrollFrame.ScrollBar:Hide(); scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end) end
        local opts = GUI.pages["utilities"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["utilities"]
        if not opts.subTabsContainer then return end
        subIndex = subIndex or 1
        for _, cf in pairs(opts.subTabsContainer.tabContents) do cf:Hide() end
        if opts.subTabsContainer.tabContents[subIndex] then opts.subTabsContainer.tabContents[subIndex]:Show() end
    end
})
