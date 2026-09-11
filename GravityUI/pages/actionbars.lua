-- GravityUI - Action Bars Page (Updated for own-button architecture)
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

-- ═══════════════════════════════════════════════════════════════
-- HELPERS & CONSTANTS
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

local orientationOptions = {
    {value = "horizontal", text = "Horizontal"},
    {value = "vertical", text = "Vertical"},
}

local lockOptions = {
    {value = "unlocked", text = "Unlocked"},
    {value = "shift", text = "Locked - Shift to drag"},
    {value = "alt", text = "Locked - Alt to drag"},
    {value = "ctrl", text = "Locked - Ctrl to drag"},
    {value = "none", text = "Fully Locked"},
}

local lockProxy = setmetatable({}, {
    __index = function(t, k)
        if k == "buttonLock" then
            local isLocked = GetCVar("lockActionBars") == "1"
            if not isLocked then return "unlocked" end
            local db = ns.GetDB()
            local saved = db and db.actionbars and db.actionbars.global and db.actionbars.global.lockModifier
            return saved or "shift"
        end
    end,
    __newindex = function(t, k, v)
        if k == "buttonLock" and type(v) == "string" then
            if v == "unlocked" then
                SetCVar("lockActionBars", "0")
            else
                SetCVar("lockActionBars", "1")
            end
            local db = ns.GetDB()
            if db and db.actionbars and db.actionbars.global then
                db.actionbars.global.lockModifier = (v ~= "unlocked") and v or nil
            end
        end
    end
})

-- ═══════════════════════════════════════════════════════════════
-- BUILDERS
-- ═══════════════════════════════════════════════════════════════

-- 1. Action Bars Settings
local function BuildActionBarsSettings(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local abs = db.actionbars
    content.rowCount = 0
    local refresh = function() if ns.RefreshActionBars then ns.RefreshActionBars() end end

    -- Settings Header
    content.rowCount = content.rowCount + 0.5
    local settingsHeader = GUI:CreateSectionHeader(content, "Action Bars Settings")
    settingsHeader:SetPoint("TOPLEFT", 10, -content.rowCount * 35)
    settingsHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + 1.3

    -- Info Box
    local infoText = "GravityUI creates its own action bar buttons for zero-taint cooldown rendering.\nCooldowns will never disappear during raids or M+ starts.\n\n|cFFFFFFFFNote:|r Positions are set via /gui > Mover Mode. Bar 9 & 10 keybinds are set in WoW Key Bindings > GravityUI."
    local infoBox = GUI:CreateInfoBox(content, infoText)
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * 35)
    content.rowCount = content.rowCount + (infoBox:GetHeight() / 35) + 0.2

    -- Master Enable Checkbox
    local masterEnable = GUI:CreateCheckbox(content, "Enable GravityUI Action Bars", "enabled", abs, function()
        ns.RefreshActionBars()
    end)
    masterEnable:SetPoint("TOPLEFT", 10, -content.rowCount * 35)
    content.rowCount = content.rowCount + 1.0

    -- Dominos Skinning (only shown if Dominos is loaded)
    if C_AddOns.IsAddOnLoaded("Dominos") then
        local dominosCheck = GUI:CreateCheckbox(content, "Skin Dominos Buttons (matching style)", "skinDominos", abs, function()
            ns.RefreshActionBars()
        end)
        dominosCheck:SetPoint("TOPLEFT", 10, -content.rowCount * 35)
        content.rowCount = content.rowCount + 1.0
    end

    -- Bartender4 Skinning (only shown if Bartender4 is loaded)
    if C_AddOns.IsAddOnLoaded("Bartender4") then
        local bt4Check = GUI:CreateCheckbox(content, "Skin Bartender4 Buttons (matching style)", "skinBartender4", abs, function()
            ns.RefreshActionBars()
        end)
        bt4Check:SetPoint("TOPLEFT", 10, -content.rowCount * 35)
        content.rowCount = content.rowCount + 1.0
    end

    local qaRow = CreateFrame("Frame", nil, content)
    qaRow:SetSize(content:GetWidth() - 20, 30)
    qaRow:SetPoint("TOPLEFT", 10, -content.rowCount * 35)
    
    local kbBtn = GUI:CreateButton(qaRow, "Quick Keybind Mode", 220, 24, function() 
        if ns.Addon and ns.Addon.SlashCommandKeybind then
            ns.Addon:SlashCommandKeybind()
        else
            if not C_AddOns.IsAddOnLoaded("Blizzard_QuickKeybind") then
                C_AddOns.LoadAddOn("Blizzard_QuickKeybind")
            end
            if QuickKeybindFrame then 
                if QuickKeybindFrame:IsShown() then HideUIPanel(QuickKeybindFrame) else ShowUIPanel(QuickKeybindFrame) end
            end
        end
    end)
    kbBtn:SetPoint("LEFT", 0, 0)

    local importBtn = GUI:CreateButton(qaRow, "Import from Blizzard Bars", 220, 24, function()
        if ns.ImportBlizzardPositions then
            ns.ImportBlizzardPositions()
        end
    end)
    importBtn:SetPoint("LEFT", kbBtn, "RIGHT", 8, 0)

    content.rowCount = content.rowCount + 1

    -- Appearance Section
    local g = abs.global
    CreateSubLabel(content, "Button Appearance")
    AddRow(content, "Show Backdrop", "checkbox", "showBackdrop", g, refresh)
    AddRow(content, "Backdrop Opacity", "slider", 0, 1, "backdropAlpha", g, refresh, 0.05)
    AddRow(content, "Show Gloss Effect", "checkbox", "showGloss", g, refresh)
    AddRow(content, "Gloss Opacity", "slider", 0, 1, "glossAlpha", g, refresh, 0.05)
    AddRow(content, "Show Button Borders", "checkbox", "showBorders", g, refresh)
    content.rowCount = content.rowCount + 0.5
    
    -- Layout Section
    CreateSubLabel(content, "Bar Layout")
    AddRow(content, "Hide Empty Slots", "checkbox", "hideEmptySlots", g, refresh)
    AddRow(content, "Action Button Lock", "dropdown", lockOptions, "buttonLock", lockProxy, refresh)
    AddRow(content, "Dim Unusable Buttons", "checkbox", "usabilityIndicator", g, refresh)
    AddRow(content, "Desaturate Unusable", "checkbox", "usabilityDesaturate", g, refresh)
    content.rowCount = content.rowCount + 0.5
    
    -- Text Display Section
    CreateSubLabel(content, "Text Display")
    AddRow(content, "Show Keybind Text", "checkbox", "showKeybinds", g, refresh)
    AddRow(content, "Hide Empty Keybinds", "checkbox", "hideEmptyKeybinds", g, refresh)
    AddRow(content, "Keybind Text Size", "slider", 8, 32, "keybindFontSize", g, refresh, 1)
    AddRow(content, "Keybind Text Anchor", "dropdown", anchorOptions, "keybindAnchor", g, refresh)
    AddRow(content, "Keybind Text X-Offset", "slider", -20, 20, "keybindOffsetX", g, refresh, 1)
    AddRow(content, "Keybind Text Y-Offset", "slider", -20, 20, "keybindOffsetY", g, refresh, 1)
    AddRow(content, "Keybind Text Color", "color", "keybindColor", g, refresh)
    content.rowCount = content.rowCount + 0.5
    
    -- Macro Names
    AddRow(content, "Show Macro Names", "checkbox", "showMacroNames", g, refresh)
    AddRow(content, "Macro Name Text Size", "slider", 8, 32, "macroNameFontSize", g, refresh, 1)
    AddRow(content, "Macro Name Anchor", "dropdown", anchorOptions, "macroNameAnchor", g, refresh)
    AddRow(content, "Macro Name X-Offset", "slider", -20, 20, "macroNameOffsetX", g, refresh, 1)
    AddRow(content, "Macro Name Y-Offset", "slider", -20, 20, "macroNameOffsetY", g, refresh, 1)
    AddRow(content, "Macro Name Color", "color", "macroNameColor", g, refresh)
    content.rowCount = content.rowCount + 0.5
    
    -- Stack Counts
    AddRow(content, "Show Stack Counts", "checkbox", "showCounts", g, refresh)
    AddRow(content, "Stack Text Size", "slider", 8, 32, "countFontSize", g, refresh, 1)
    AddRow(content, "Stack Text Anchor", "dropdown", anchorOptions, "countAnchor", g, refresh)
    AddRow(content, "Stack Text X-Offset", "slider", -20, 20, "countOffsetX", g, refresh, 1)
    AddRow(content, "Stack Text Y-Offset", "slider", -20, 20, "countOffsetY", g, refresh, 1)
    AddRow(content, "Stack Count Color", "color", "countColor", g, refresh)
    content.rowCount = content.rowCount + 0.5

    -- Cooldown Countdown Text
    AddRow(content, "Cooldown Text Size", "slider", 6, 28, "cooldownFontSize", g, refresh, 1)
    AddRow(content, "Cooldown Text X-Offset", "slider", -20, 20, "cooldownTextXOffset", g, refresh, 1)
    AddRow(content, "Cooldown Text Y-Offset", "slider", -20, 20, "cooldownTextYOffset", g, refresh, 1)
    AddRow(content, "Cooldown Text Color", "color", "cooldownTextColor", g, refresh)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. Bar Layout (per-bar settings)
local function BuildBarLayoutSettings(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local abs = db.actionbars
    content.rowCount = 0
    local refresh = function() if ns.RefreshActionBars then ns.RefreshActionBars() end end

    local header = GUI:CreateSectionHeader(content, "Per-Bar Layout")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local barConfigs = {
        { key = "MainBar",   label = "Action Bar 1 (Main)" },
        { key = "Bar2",      label = "Action Bar 2" },
        { key = "Bar3",      label = "Action Bar 3" },
        { key = "Bar4",      label = "Action Bar 4" },
        { key = "Bar5",      label = "Action Bar 5" },
        { key = "Bar6",      label = "Action Bar 6" },
        { key = "Bar7",      label = "Action Bar 7" },
        { key = "Bar8",      label = "Action Bar 8" },
        { key = "Bar9",      label = "Action Bar 9" },
        { key = "Bar10",     label = "Action Bar 10" },
        { key = "StanceBar", label = "Stance Bar" },
        { key = "PetBar",    label = "Pet Bar" },
    }

    for _, cfg in ipairs(barConfigs) do
        if not abs.bars[cfg.key] then
            abs.bars[cfg.key] = {}
        end
        local barDB = abs.bars[cfg.key]
        CreateSubLabel(content, cfg.label)
        AddRow(content, "Enabled", "checkbox", "enabled", barDB, refresh)
        AddRow(content, "Columns", "slider", 1, 12, "columns", barDB, refresh, 1)
        AddRow(content, "Rows", "slider", 1, 12, "rows", barDB, refresh, 1)
        AddRow(content, "Button Width", "slider", 20, 80, "buttonWidth", barDB, refresh, 1)
        AddRow(content, "Button Height", "slider", 20, 80, "buttonHeight", barDB, refresh, 1)
        AddRow(content, "Spacing", "slider", 0, 20, "spacing", barDB, refresh, 1)
        AddRow(content, "Orientation", "dropdown", orientationOptions, "orientation", barDB, refresh)
        content.rowCount = content.rowCount + 0.5
    end

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 3. Mouseover Settings
local function BuildMouseoverSettings(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local abs = db.actionbars
    content.rowCount = 0
    local refresh = function() if ns.RefreshActionBars then ns.RefreshActionBars() end end
    
    local header = GUI:CreateSectionHeader(content, "Mouseover Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local f = abs.fade
    AddRow(content, "Enable Mouseover Hide", "checkbox", "enabled", f, refresh)
    AddRow(content, "Fade In Duration", "slider", 0, 1, "fadeInDuration", f, refresh, 0.05)
    AddRow(content, "Fade Out Duration", "slider", 0, 1, "fadeOutDuration", f, refresh, 0.05)
    AddRow(content, "Min Brightness (Alpha)", "slider", 0, 1, "fadeOutAlpha", f, refresh, 0.05)
    AddRow(content, "Fade Out Delay", "slider", 0, 2, "fadeOutDelay", f, refresh, 0.1)
    AddRow(content, "Always Show in Combat", "checkbox", "alwaysShowInCombat", f, refresh)
    AddRow(content, "Link all Mouseover Bars", "checkbox", "linkBars1to8", f, refresh)
    content.rowCount = content.rowCount + 0.5

    local function AddInvertedRow(parent, label, barKey)
        local barDB = abs.bars[barKey]
        if not barDB then
            abs.bars[barKey] = {}
            barDB = abs.bars[barKey]
        end
        local proxy = { mouseoverFade = not barDB.alwaysShow }
        local row = CreatePropertyRow(parent, label, "checkbox", "mouseoverFade", proxy, function()
            barDB.alwaysShow = not proxy.mouseoverFade
            refresh()
        end)
        row:SetParent(parent)
        row:SetPoint("TOPLEFT", 10, -parent.rowCount * (ROW_HEIGHT + 5))
        parent.rowCount = parent.rowCount + 1
        return row
    end

    CreateSubLabel(content, "Action Bars")
    AddInvertedRow(content, "Mouseover Fade Bar 1 (Main)", "MainBar")
    for i = 2, 10 do
        AddInvertedRow(content, "Mouseover Fade Bar " .. i, "Bar" .. i)
    end

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Other Bars")
    local otherBars = {
        { key = "StanceBar",  label = "Mouseover Fade Stance Bar" },
        { key = "PetBar",     label = "Mouseover Fade Pet Bar" },
        { key = "MicroBar",   label = "Mouseover Fade Micro Menu" },
        { key = "BagBar",     label = "Mouseover Fade Bags" },
    }
    
    for _, info in ipairs(otherBars) do
        AddInvertedRow(content, info.label, info.key)
    end

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 4. Special Buttons
local function BuildSpecialButtons(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local abs = db.actionbars
    content.rowCount = 0
    local refresh = function() if ns.RefreshActionBars then ns.RefreshActionBars() end end

    local header = GUI:CreateSectionHeader(content, "Extra Action Buttons Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local eb = abs.bars.extraActionButton
    if not eb then abs.bars.extraActionButton = {}; eb = abs.bars.extraActionButton end
    AddRow(content, "Hide Extra Action Art", "checkbox", "hideArtwork", eb, refresh)
    content.rowCount = content.rowCount + 0.5
    
    local zb = abs.bars.zoneAbility
    if not zb then abs.bars.zoneAbility = {}; zb = abs.bars.zoneAbility end
    AddRow(content, "Hide Zone Ability Art", "checkbox", "hideArtwork", zb, refresh)
    AddRow(content, "Mirror Zone/ExtraActionButton Keybind", "checkbox", "mirrorExtraKeybind", zb, function()
        if ns.ActionBars and ns.ActionBars.RefreshZoneAbilityKeybind then
            ns.ActionBars.RefreshZoneAbilityKeybind()
        end
    end)
    -- Position note
    local noteRow = CreateFrame("Frame", nil, content)
    noteRow:SetSize(content:GetWidth() - 20, 30)
    noteRow:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    local noteText = noteRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteText:SetPoint("LEFT", 0, 0)
    noteText:SetText("|cff88aaccPosition these buttons via Blizzard's Edit Mode (Esc > Edit Mode)|r")
    content.rowCount = content.rowCount + 1
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN PAGE
-- ═══════════════════════════════════════════════════════════════
ns.GUI:RegisterPage("actionbars", {
    title = "Action Bars",
    subTabs = {
        { name = "Action Bars Settings", builder = BuildActionBarsSettings },
        { name = "Bar Layout",           builder = BuildBarLayoutSettings },
        { name = "Mouseover Settings",   builder = BuildMouseoverSettings },
        { name = "Extra Action Buttons", builder = BuildSpecialButtons },
    },
    OnBuild = function(content)
        -- Hide default scrollframe parent
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        local opts = GUI.pages["actionbars"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["actionbars"]
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
