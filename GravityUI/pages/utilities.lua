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


local function BuildCastbar(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local ticks = db.general.castbarTicks; if not ticks then return end 
    content.rowCount = 0
    local refresh = function() if ns.CastbarTicks and ns.CastbarTicks.SetupHooks then ns.CastbarTicks:SetupHooks() end end
    local function CreateSpecSection(title, dbPath, startY)
        local header = GUI:CreateSectionHeader(content, title)
        header:SetPoint("TOPLEFT", 10, startY)
        local frame = CreateFrame("Frame", nil, content); frame:SetSize(GUI.CONTENT_WIDTH - 20, 240); frame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
        GUI:CreateCheckbox(frame, "Enable on UnhaltedUnitFrames", "enableUUF", dbPath, refresh):SetPoint("TOPLEFT", 0, 0)
        GUI:CreateCheckbox(frame, "Enable on Ayije CDM", "enableAyije", dbPath, refresh):SetPoint("TOPLEFT", 0, -30)
        local slW = GUI:CreateSlider(frame, "Tick Width", 1, 10, "tickWidth", dbPath, refresh, 1); slW:SetPoint("TOPLEFT", 0, -100); slW.label:SetText("Tick Width")
        local slH = GUI:CreateSlider(frame, "Tick Height %", 0.1, 1.0, "tickHeight", dbPath, refresh, 0.05); slH:SetPoint("TOPLEFT", 0, -140); slH.label:SetText("Tick Height")
        local cp = GUI:CreateColorPicker(frame, "Tick Color", "tickColor", dbPath, refresh); cp:SetPoint("TOPLEFT", 0, -180); cp.label:SetText("Tick Color")
        return 280
    end
    local y = -10
    y = y - CreateSpecSection("Disintegrate Ticks (Evoker)", ticks.disintegrate, y)
    y = y - CreateSpecSection("Mind Flay Ticks (Priest)", ticks.mindflay, y)
    content:SetHeight(-y + 50)
end

-- 4. Sound Alerts
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
-- PAGE REGISTRATION
--==============================================================================================================================================================================================
ns.GUI:RegisterPage("utilities", {
    title = "Utilities",
    subTabs = {
        { name = "Castbar Ticks",    builder = BuildCastbar },
        { name = "Sound Alerts",     builder = BuildSoundAlerts },
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
