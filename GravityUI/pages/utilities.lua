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
    local infoBox = GUI:CreateInfoBox(content, "|cffFFCC00Info:|r Erstellt eine 1:1 Kopie deiner aktiven Debuffs mit einem sauberen 1px-Border an einer frei positionierbaren Stelle.\n\n|cFFFFFFFFNote:|r Den Frame kannst du im Blizzard Edit-Mode verschieben (Checkbox \"Show GravityUI Elements\" aktivieren).")
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
    AddRow(content, "Debuff Mirror aktivieren", "checkbox", "enabled", dmDB, Refresh)
    content.rowCount = content.rowCount + 0.5

    -- Sub-label: Darstellung
    CreateSubLabel(content, "Darstellung")
    content.rowCount = content.rowCount + 0.3

    -- Icon Size
    AddRow(content, "Icon-Größe",             "slider", 16, 64, "iconSize",   dmDB, Refresh, 2)

    -- Spacing
    AddRow(content, "Abstand zwischen Icons", "slider", 0,  20, "spacing",    dmDB, Refresh, 1)

    -- Icons per row
    AddRow(content, "Icons pro Reihe",        "slider", 1,  32, "iconsPerRow", dmDB, Refresh, 1)

    -- Max debuffs
    AddRow(content, "Maximale Anzahl Debuffs","slider", 1,  40, "maxDebuffs", dmDB, Refresh, 1)

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Layout")
    content.rowCount = content.rowCount + 0.3

    -- Grow direction
    local growOptions = {
        { value = "RIGHT", text = "Nach rechts" },
        { value = "LEFT",  text = "Nach links" },
        { value = "DOWN",  text = "Nach unten" },
        { value = "UP",    text = "Nach oben" },
    }
    AddRow(content, "Wachstumsrichtung", "dropdown", growOptions, "growDirection", dmDB, Refresh)

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Original Frame")
    content.rowCount = content.rowCount + 0.3

    -- Hide original
    AddRow(content, "Blizzard Debuff-Frame ausblenden", "checkbox", "hideOriginal", dmDB, Refresh)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- PAGE REGISTRATION
--==============================================================================================================================================================================================
ns.GUI:RegisterPage("utilities", {
    title = "Utilities",
    subTabs = {
        { name = "Sound Alerts", builder = BuildSoundAlerts },
        { name = "Debuffs",      builder = BuildDebuffs },
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
