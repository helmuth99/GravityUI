-- GravityUI - Action Bars Page
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
            local modifier = GetModifiedClick("PICKUPACTION") or "SHIFT"
            if modifier == "NONE" then return "none" end
            return modifier:lower()
        end
    end,
    __newindex = function(t, k, v)
        if k == "buttonLock" and type(v) == "string" then
            if v == "unlocked" then
                SetCVar("lockActionBars", "0")
            else
                SetCVar("lockActionBars", "1")
                local modifier = (v == "none") and "NONE" or v:upper()
                SetModifiedClick("PICKUPACTION", modifier)
                SaveBindings(GetCurrentBindingSet())
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
    local settingsHeader = GUI:CreateSectionHeader(content, "Settings")
    settingsHeader:SetPoint("TOPLEFT", 10, -content.rowCount * 35)
    settingsHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + 1.3

    -- Info Box
    local infoText = "Enable your Action Bars in World of Warcraft > Action Bars.\n\n|cFFFFFFFFNote:|r GravityUI is only styling the Default Actionbars, for more extras use AddOns like Dominos, Bartender4."
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
        local dominosCheck = GUI:CreateCheckbox(content, "Skin Dominos Buttons (matching style)", "skinDominos", abs, function(enabled)
            if enabled then
                if ns.SkinDominosButtons then ns.SkinDominosButtons() end
            else
                -- Strip our skinning from Dominos buttons
                for i = 1, 24 do
                    local btn = _G["DominosActionButton" .. i]
                    if btn then
                        if btn._guiStripped then
                            local icon = btn.icon or btn.Icon
                            if icon then icon:SetTexCoord(0, 1, 0, 1); icon:SetAllPoints(btn) end
                        end
                        if btn._guiBackdrop then btn._guiBackdrop:Hide() end
                        if btn._guiNormal then btn._guiNormal:Hide() end
                        if btn._guiGloss then btn._guiGloss:Hide() end
                    end
                end
            end
        end)
        dominosCheck:SetPoint("TOPLEFT", 10, -content.rowCount * 35)
        content.rowCount = content.rowCount + 1.0
    end

    -- Bartender4 Skinning (only shown if Bartender4 is loaded)
    if C_AddOns.IsAddOnLoaded("Bartender4") then
        local bt4Check = GUI:CreateCheckbox(content, "Skin Bartender4 Buttons (matching style)", "skinBartender4", abs, function(enabled)
            if not enabled then
                -- Strip our skinning from BT4 buttons
                for i = 1, 120 do
                    local btn = _G["BT4Button" .. i]
                    if btn then
                        if btn._guiStripped then
                            local icon = btn.icon or btn.Icon
                            if icon then icon:SetTexCoord(0, 1, 0, 1); icon:SetAllPoints(btn) end
                        end
                        if btn._guiBackdrop then btn._guiBackdrop:Hide() end
                        if btn._guiNormal then btn._guiNormal:Hide() end
                        if btn._guiGloss then btn._guiGloss:Hide() end
                    end
                end
            else
                ns.RefreshActionBars()
            end
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
             -- Fallback if Addon method missing for some reason
            if not C_AddOns.IsAddOnLoaded("Blizzard_QuickKeybind") then
                C_AddOns.LoadAddOn("Blizzard_QuickKeybind")
            end
            if QuickKeybindFrame then 
                if QuickKeybindFrame:IsShown() then HideUIPanel(QuickKeybindFrame) else ShowUIPanel(QuickKeybindFrame) end
            end
        end
    end)
    kbBtn:SetPoint("LEFT", 0, 0)
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
    AddRow(content, "Unthrottled CPU Usage", "checkbox", "fastUsabilityUpdates", g, refresh)
    content.rowCount = content.rowCount + 0.5
    
    -- Text Display Section
    CreateSubLabel(content, "Text Display")
    -- Keybinds
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

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. Mouseover Settings
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
    AddRow(content, "Link Action Bars 1-8", "checkbox", "linkBars1to8", f, refresh)
    content.rowCount = content.rowCount + 0.5

    -- Always Show Toggles
    CreateSubLabel(content, "Always Show (Ignore Mouseover)")
    
    local barList = {
        { key = "bar1", label = "Bar 1" },
        { key = "bar2", label = "Bar 2" },
        { key = "bar3", label = "Bar 3" },
        { key = "bar4", label = "Bar 4" },
        { key = "bar5", label = "Bar 5" },
        { key = "bar6", label = "Bar 6" },
        { key = "bar7", label = "Bar 7" },
        { key = "bar8", label = "Bar 8" },
        { key = "pet", label = "Pet Bar" },
        { key = "stance", label = "Stance Bar" },
        { key = "microbar", label = "Micro Menu" },
        { key = "bags", label = "Bags" },
        { key = "extraActionButton", label = "Extra Action Button" },
        { key = "zoneAbility", label = "Zone Ability" },
    }
    
    for _, info in ipairs(barList) do
        if abs.bars[info.key] then
            AddRow(content, "Always Show " .. info.label, "checkbox", "alwaysShow", abs.bars[info.key], refresh)
        end
    end

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 3. Special Buttons
local function BuildSpecialButtons(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local abs = db.actionbars
    content.rowCount = 0
    local refresh = function() if ns.RefreshActionBars then ns.RefreshActionBars() end end

    local header = GUI:CreateSectionHeader(content, "Special Buttons Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local eb = abs.bars.extraActionButton
    AddRow(content, "Extra Action Button Scale", "slider", 0.5, 2.0, "scale", eb, refresh, 0.05)
    AddRow(content, "Hide Extra Action Art", "checkbox", "hideArtwork", eb, refresh)
    content.rowCount = content.rowCount + 0.5
    
    local zb = abs.bars.zoneAbility
    AddRow(content, "Zone Ability Scale", "slider", 0.5, 2.0, "scale", zb, refresh, 0.05)
    AddRow(content, "Hide Zone Ability Art", "checkbox", "hideArtwork", zb, refresh)
    content.rowCount = content.rowCount + 0.5
    
    local movRow = CreateFrame("Frame", nil, content)
    movRow:SetSize(content:GetWidth() - 20, 30)
    movRow:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    
    local mBtn = GUI:CreateButton(movRow, "Toggle Position Movers", 220, 24, function() 
        if ns.ActionBars and ns.ActionBars.ToggleExtraButtonMovers then
            ns.ActionBars.ToggleExtraButtonMovers()
        end
    end)
    mBtn:SetPoint("LEFT", 0, 0)
    content.rowCount = content.rowCount + 1.5
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN PAGE
-- ═══════════════════════════════════════════════════════════════
ns.GUI:RegisterPage("actionbars", {
    title = "Action Bars",
    OnBuild = function(content)
        -- Hide default scrollframe parent
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Create SubTabs
        local subTabs = GUI:CreateSubTabs(scrollFrame, {
            { name = "Action Bars Settings", builder = BuildActionBarsSettings },
            { name = "Mouseover Settings", builder = BuildMouseoverSettings },
            { name = "Special Buttons", builder = BuildSpecialButtons },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
