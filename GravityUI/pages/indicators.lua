-- GravityUI - Indicators Page
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
    elseif widgetType == "input" then
         widget = GUI:CreateInput(row, "", arg1, arg2, arg3)
         widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
         widget:SetWidth(WIDGET_WIDTH)
         if widget.editBox then
             widget.editBox:ClearAllPoints()
             widget.editBox:SetPoint("LEFT", widget, "LEFT", 0, 0)
             widget.editBox:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
         end
    end
    
    if ns.GUI and ns.GUI.RegisterInSearchIndex then
        ns.GUI:RegisterInSearchIndex(labelText, row)
    end
    
    return row
end

local function AddRow(container, label, type, ...)
    local row = CreatePropertyRow(container, label, type, ...)
    local count = container.rowCount or 0
    row:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
    container.rowCount = count + 1
    return row
end

local function CreateSubLabel(container, text)
    local count = container.rowCount or 0
    local sh = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sh:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
    sh:SetText(text)
    sh:SetTextColor(unpack(GUI.Colors.accent))
    if ns.GUI.SetFont then ns.GUI:SetFont(sh, 12, "") end
    container.rowCount = count + 1
end

--==============================================================================================================================================================================================
-- BUILDERS
--==============================================================================================================================================================================================

-- 1. Cursor
local function BuildCursor(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local c = db.screenindicators.cursor
    content.rowCount = 0
    local refresh = function() if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end end
    local header = GUI:CreateSectionHeader(content, "Cursor Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    CreateSubLabel(content, "Enable & Logic")
    AddRow(content, "Enable Cursor Ring", "checkbox", "enabled", c, refresh)
    AddRow(content, "Hide Out of Combat", "checkbox", "hideOutOfCombat", c, refresh)
    AddRow(content, "Hide on Right Click", "checkbox", "hideOnRightClick", c, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Appearance")
    local ringStyles = {{value="thin", text="Thin"},{value="standard", text="Standard"},{value="thick", text="Thick"},{value="solid", text="Solid"}}
    AddRow(content, "Ring Style", "dropdown", ringStyles, "ringStyle", c, refresh)
    AddRow(content, "Ring Size", "slider", 10, 100, "ringSize", c, refresh, 1)
    local reticleStyles = {{value="none", text="None"}, {value="dot", text="Dot"},{value="cross", text="Crosshair (Atlas)"},{value="chevron", text="Chevron (Atlas)"},{value="diamond", text="Diamond (Atlas)"}}
    AddRow(content, "Reticle Style", "dropdown", reticleStyles, "reticleStyle", c, refresh)
    AddRow(content, "Reticle Size", "slider", 1, 40, "reticleSize", c, refresh, 1)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Colors & Alpha")
    AddRow(content, "Use Theme Color", "checkbox", "useThemeColor", c, refresh)
    AddRow(content, "Custom Color", "color", "customColor", c, refresh)
    AddRow(content, "Combat Alpha", "slider", 0, 1, "inCombatAlpha", c, refresh, 0.1)
    AddRow(content, "Out of Combat Alpha", "slider", 0, 1, "outCombatAlpha", c, refresh, 0.1)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Global Cooldown (GCD)")
    AddRow(content, "Track GCD", "checkbox", "gcdEnabled", c, refresh)
    AddRow(content, "GCD Ring Fade", "slider", 0, 1, "gcdFadeRing", c, refresh, 0.05)
    AddRow(content, "Reverse Animation", "checkbox", "gcdReverse", c, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Cooldown Indicators")
    AddRow(content, "Taunt CD on Cursor", "checkbox", "tauntCursorEnabled", c, refresh)
    AddRow(content, "Dispel CD on Cursor", "checkbox", "dispelCursorEnabled", c, refresh)
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. Crosshair
local function BuildCrosshair(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local ch = db.screenindicators.crosshair
    content.rowCount = 0
    local refresh = function() if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end end
    local header = GUI:CreateSectionHeader(content, "Crosshair Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    CreateSubLabel(content, "Enable & Core Settings")
    AddRow(content, "Enable Crosshair", "checkbox", "enabled", ch, refresh)
    AddRow(content, "Only in Combat", "checkbox", "onlyInCombat", ch, refresh)
    AddRow(content, "Hide until Out of Range", "checkbox", "hideUntilOutOfRange", ch, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Size & Scale")
    AddRow(content, "Size", "slider", 2, 50, "size", ch, refresh, 1)
    AddRow(content, "Thickness", "slider", 1, 10, "thickness", ch, refresh, 1)
    AddRow(content, "Border Size", "slider", 0, 5, "borderSize", ch, refresh, 1)
    local strataOptions = {{value="BACKGROUND", text="Background"},{value="LOW", text="Low"},{value="MEDIUM", text="Medium"},{value="HIGH", text="High"},{value="DIALOG", text="Dialog"}}
    AddRow(content, "Frame Strata", "dropdown", strataOptions, "strata", ch, refresh)
    CreateSubLabel(content, "Colors")
    AddRow(content, "Use Theme Color", "checkbox", "useThemeColor", ch, refresh)
    AddRow(content, "Crosshair Color", "color", "customColor", ch, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Range Check")
    AddRow(content, "Change Color on Range", "checkbox", "changeColorOnRange", ch, refresh)
    AddRow(content, "Out of Range Color", "color", "outOfRangeColor", ch, refresh)
    AddRow(content, "Combat Only (Range)", "checkbox", "rangeColorInCombatOnly", ch, refresh)
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 3. Pet Info
local function BuildPet(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local ps = db.screenindicators.petWarnings
    content.rowCount = 0
    local refresh = function() if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end end
    local header = GUI:CreateSectionHeader(content, "Pet Info Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    CreateSubLabel(content, "Enable & Preview")
    AddRow(content, "Enable Pet Warnings", "checkbox", "enabled", ps, refresh)
    local petPreviewRow = CreateFrame("Frame", nil, content)
    petPreviewRow:SetSize(content:GetWidth() - 20, 30)
    petPreviewRow:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    local btnMover = GUI:CreateButton(petPreviewRow, "Toggle Mover", 120, 24, function() if ns.ScreenIndicators and ns.ScreenIndicators.ToggleMover then ns.ScreenIndicators.ToggleMover("pet") end end)
    btnMover:SetPoint("LEFT", petPreviewRow, "LEFT", 0, 0)
    local btnDead = GUI:CreateButton(petPreviewRow, "Dead / Missing", 120, 24, function() ns.ScreenIndicators.PreviewPetWarning("petDead") end)
    btnDead:SetPoint("LEFT", btnMover, "RIGHT", 10, 0)
    local btnIdle = GUI:CreateButton(petPreviewRow, "Not Attacking", 120, 24, function() ns.ScreenIndicators.PreviewPetWarning("petIdle") end)
    btnIdle:SetPoint("LEFT", btnDead, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.3
    CreateSubLabel(content, "Warning Types")
    AddRow(content, "Pet Dead / Missing", "checkbox", "petDeadWarning", ps, refresh)
    AddRow(content, "Pet Not Attacking", "checkbox", "petAttackWarning", ps, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Custom Warning Text")
    AddRow(content, "Dead / Missing Text", "input", "petDeadText", ps, refresh)
    AddRow(content, "Not Attacking Text", "input", "petAttackText", ps, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Appearance")
    AddRow(content, "Font Size", "slider", 10, 60, "fontSize", ps, refresh, 1)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Position")
    AddRow(content, "X Offset", "slider", -1000, 1000, "xOffset", ps, refresh, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "yOffset", ps, refresh, 1)
    local strataOptions = {{value="BACKGROUND", text="Background"},{value="LOW", text="Low"},{value="MEDIUM", text="Medium"},{value="HIGH", text="High"},{value="DIALOG", text="Dialog"},{value="FULLSCREEN", text="Fullscreen"},{value="FULLSCREEN_DIALOG", text="Fullscreen Dialog"},{value="TOOLTIP", text="Tooltip"}}
    AddRow(content, "Frame Strata", "dropdown", strataOptions, "strata", ps, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Colors")
    AddRow(content, "Warning use Theme Color", "checkbox", "useThemeColor", ps, refresh)
    AddRow(content, "Warning Color", "color", "warningColor", ps, refresh)
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 4. Combat Timer (Ported from uiimprovements.lua)
local function BuildCombatTimer(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbCT = db.uiimprovements.combatTimer
    content.rowCount = 0
    local function RefreshCT() if _G.GravityUI_RefreshCombatTimer then _G.GravityUI_RefreshCombatTimer() end end
    local header = GUI:CreateSectionHeader(content, "Combat Timer")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    AddRow(content, "Enable Combat Timer", "checkbox", "enabled", dbCT, RefreshCT)
    AddRow(content, "Only show in Boss Encounters", "checkbox", "onlyEncounter", dbCT, RefreshCT)
    AddRow(content, "Width", "slider", 40, 300, "width", dbCT, RefreshCT, 1)
    AddRow(content, "Height", "slider", 10, 100, "height", dbCT, RefreshCT, 1)
    AddRow(content, "X Offset", "slider", -500, 500, "xOffset", dbCT, RefreshCT, 1)
    AddRow(content, "Y Offset", "slider", -500, 500, "yOffset", dbCT, RefreshCT, 1)
    local strataOptions = {{value="BACKGROUND", text="Background"}, {value="LOW", text="Low"}, {value="MEDIUM", text="Medium"}, {value="HIGH", text="High"}, {value="DIALOG", text="Dialog"}, {value="FULLSCREEN", text="Fullscreen"}, {value="TOOLTIP", text="Tooltip"}}
    AddRow(content, "Frame Strata", "dropdown", strataOptions, "strata", dbCT, RefreshCT)
    AddRow(content, "Font Size", "slider", 8, 48, "fontSize", dbCT, RefreshCT, 1)
    local alignOptions = {{value="LEFT", text="Left"}, {value="CENTER", text="Center"}, {value="RIGHT", text="Right"}}
    AddRow(content, "Text Alignment", "dropdown", alignOptions, "textAlign", dbCT, RefreshCT)
    AddRow(content, "Use Theme Color for Text", "checkbox", "useThemeColorText", dbCT, RefreshCT)
    AddRow(content, "Text Color", "color", "textColor", dbCT, RefreshCT)
    AddRow(content, "Show Backdrop", "checkbox", "showBackdrop", dbCT, RefreshCT)
    AddRow(content, "Backdrop Color", "color", "backdropColor", dbCT, RefreshCT)
    AddRow(content, "Hide Border", "checkbox", "hideBorder", dbCT, RefreshCT)
    AddRow(content, "Border Size", "slider", 0, 10, "borderSize", dbCT, RefreshCT, 1)
    AddRow(content, "Use Theme Color for Border", "checkbox", "useThemeColorBorder", dbCT, RefreshCT)
    AddRow(content, "Border Color", "color", "borderColor", dbCT, RefreshCT)
    local previewBtn = GUI:CreateButton(content, "Toggle Mover", 120, 26, function() if _G.GravityUI_ToggleCombatTimerPreview then local isPreview = _G.GravityUI_IsCombatTimerPreviewMode and _G.GravityUI_IsCombatTimerPreviewMode(); _G.GravityUI_ToggleCombatTimerPreview(not isPreview) end end)
    previewBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    content.rowCount = content.rowCount + 1.2
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 5. Missing Buffs
local function BuildMissingBuffs(parent)
    -- Prevent overlapping elements by clearing existing content if we are rebuilding
    if parent.scroll then
        parent.scroll:Hide()
        parent.scroll:SetParent(nil)
        parent.scroll = nil
    end

    local scroll, content = GUI:CreateScrollableContent(parent)
    parent.scroll = scroll
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local rbDb = db.raidBuffs
    content.rowCount = 0
    local refresh = function() if ns.RaidBuffs and ns.RaidBuffs.Refresh then ns.RaidBuffs:Refresh() end end
    local RB = ns.RaidBuffs
    if not RB then local err = content:CreateFontString(nil, "OVERLAY", "GameFontRed"); err:SetPoint("TOPLEFT", 10, -10); err:SetText("Error: RaidBuffs module not loaded."); return end
    local header = GUI:CreateSectionHeader(content, "Missing Raid Buffs")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    local btnConfig = GUI:CreateButton(content, "Toggle Mover / Unlock Position", 250, 24, function() if RB.ToggleMover then RB:ToggleMover() end end)
    btnConfig:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    content.rowCount = content.rowCount + 0.8
    AddRow(content, "Enable Missing Buffs", "checkbox", "enabled", rbDb, refresh)
    AddRow(content, "Show 'Buff' Reminder Text", "checkbox", "showBuffReminder", rbDb, refresh)
    AddRow(content, "   Size", "slider", 8, 32, "reminderFontSize", rbDb, refresh, 1)
    AddRow(content, "   Color", "color", "reminderColor", rbDb, refresh)
    AddRow(content, "Show Only In Group/Raid", "checkbox", "showOnlyInGroup", rbDb, refresh)
    AddRow(content, "Show Only In Instance", "checkbox", "showOnlyInInstance", rbDb, refresh)
    AddRow(content, "Show Only On Ready Check", "checkbox", "showOnlyOnReadyCheck", rbDb, refresh)
    AddRow(content, "Ready Check Duration", "slider", 5, 60, "readyCheckDuration", rbDb, refresh, 1)
    AddRow(content, "Show Only My Class Buffs", "checkbox", "showOnlyPlayerClassBuff", rbDb, refresh)
    AddRow(content, "Show Only My Missing Buffs", "checkbox", "showOnlyPlayerMissing", rbDb, refresh)
    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Appearance")
    AddRow(content, "Icon Size", "slider", 16, 128, "iconSize", rbDb, refresh, 4)
    AddRow(content, "Text Size", "slider", 8, 32, "labelFontSize", rbDb, refresh, 1)
    AddRow(content, "Spacing", "slider", 0, 50, "spacing", rbDb, refresh, 1)
    local growOptions = {{value="LEFT", text="Left"}, {value="CENTER", text="Center"}, {value="RIGHT", text="Right"}}
    AddRow(content, "Grow Direction", "dropdown", growOptions, "growDirection", rbDb, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Expiration Warning")
    AddRow(content, "Show Glow Warning", "checkbox", "showExpirationGlow", rbDb, refresh)
    AddRow(content, "Warning Threshold (min)", "slider", 1, 30, "expirationThreshold", rbDb, refresh, 1)
    AddRow(content, "Glow Color", "color", "glowColor", rbDb, refresh)
    content.rowCount = content.rowCount + 0.8
    CreateSubLabel(content, "Category Frames (Split Bars)")
    local function AddCategoryControl(label, key)
        local row = CreateFrame("Frame", nil, content); row:SetSize(GUI.CONTENT_WIDTH-20, 24); row:SetPoint("TOPLEFT", 10, -10-(content.rowCount*(ROW_HEIGHT+5)))
        local txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); txt:SetPoint("LEFT", 0, 0); txt:SetText(label); txt:SetWidth(120)
        local function CreateStyledCheck(parent, labelText, dbTable, dbKey, onClick)
            local cb = CreateFrame("Button", nil, parent, "BackdropTemplate"); cb:SetSize(20, 20); cb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1}); cb:SetBackdropColor(0.15, 0.15, 0.15, 1); cb:SetBackdropBorderColor(0, 0, 0, 1)
            local check = cb:CreateTexture(nil, "OVERLAY"); check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); check:SetPoint("CENTER"); check:SetSize(16, 16); check:SetDesaturated(true); check:SetVertexColor(unpack(GUI.Colors.accent))
            local function UpdateState() local val = dbTable[dbKey]; if val == nil then val = true end; check:SetShown(val) end; UpdateState()
            cb:SetScript("OnClick", function() local val = dbTable[dbKey]; if val == nil then val = true end; dbTable[dbKey] = not val; UpdateState(); if onClick then onClick() end end)
            cb:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(GUI.Colors.accent[1], GUI.Colors.accent[2], GUI.Colors.accent[3], 1) end); cb:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end)
            if labelText then cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0); cb.text:SetText(labelText) end
            return cb
        end
        if not rbDb.categorySettings[key] then rbDb.categorySettings[key] = {} end
        local cbEnable = CreateStyledCheck(row, "Enable", rbDb.categorySettings[key], "enabled", refresh); cbEnable:SetPoint("LEFT", 130, 0)
        local cbSplit = CreateStyledCheck(row, "Detach / Split", rbDb.splitCategories, key, refresh); cbSplit:SetPoint("LEFT", 220, 0)
        content.rowCount = content.rowCount + 0.8
    end
    AddCategoryControl("Raid Buffs", "raid"); AddCategoryControl("Self Buffs", "self"); AddCategoryControl("Presence Buffs", "presence"); AddCategoryControl("Targeted Buffs", "targeted"); AddCategoryControl("Consumables", "consumables"); AddCategoryControl("Custom Buffs", "custom")
    local function AddBuffToggle(buff)
        local row = CreateFrame("Frame", nil, content); row:SetSize(GUI.CONTENT_WIDTH-20, 24); row:SetPoint("TOPLEFT", 10, -10-(content.rowCount*(ROW_HEIGHT + 5)))
        local cb = CreateFrame("Button", nil, row, "BackdropTemplate"); cb:SetSize(20, 20); cb:SetPoint("LEFT", 0, 0); cb:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1}); cb:SetBackdropColor(0.15, 0.15, 0.15, 1); cb:SetBackdropBorderColor(0, 0, 0, 1)
        local check = cb:CreateTexture(nil, "OVERLAY"); check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); check:SetPoint("CENTER"); check:SetSize(16, 16); check:SetDesaturated(true); check:SetVertexColor(unpack(GUI.Colors.accent))
        local function UpdateState() local val = rbDb.enabledBuffs[buff.key]; if val == nil then val = true end; check:SetShown(val) end; UpdateState()
        cb:SetScript("OnClick", function() local val = rbDb.enabledBuffs[buff.key]; if val == nil then val = true end; rbDb.enabledBuffs[buff.key] = not val; UpdateState(); refresh() end)
        cb:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(GUI.Colors.accent[1], GUI.Colors.accent[2], GUI.Colors.accent[3], 1) end); cb:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end)
        local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(20, 20); icon:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        local tex = buff.iconOverride; if not tex then local id = type(buff.spellID) == "table" and buff.spellID[1] or buff.spellID; tex = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)) or (GetSpellTexture and GetSpellTexture(id)) end; icon:SetTexture(tex)
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); label:SetPoint("LEFT", icon, "RIGHT", 8, 0); label:SetText(buff.name or "Unknown Buff")
        content.rowCount = content.rowCount + 0.8; return row
    end
    content.rowCount = content.rowCount + 0.8; if RB.RAID_BUFFS then CreateSubLabel(content, "Raid Buffs (Group)"); for _, buff in ipairs(RB.RAID_BUFFS) do AddBuffToggle(buff) end end
    content.rowCount = content.rowCount + 0.5; if RB.PRESENCE_BUFFS then CreateSubLabel(content, "Presence Buffs (One Per Group)"); for _, buff in ipairs(RB.PRESENCE_BUFFS) do AddBuffToggle(buff) end end
    content.rowCount = content.rowCount + 0.5; if RB.TARGETED_BUFFS then CreateSubLabel(content, "Targeted Buffs (On Others)"); for _, buff in ipairs(RB.TARGETED_BUFFS) do AddBuffToggle(buff) end end
    content.rowCount = content.rowCount + 0.5; 
    if RB.SELF_BUFFS then 
        CreateSubLabel(content, "Self Buffs (Personal)")
        for _, buff in ipairs(RB.SELF_BUFFS) do 
            if buff.groupId ~= "consumables" then AddBuffToggle(buff) end
        end
        content.rowCount = content.rowCount + 0.5
        CreateSubLabel(content, "Self Buffs (Consumables)")
        for _, buff in ipairs(RB.SELF_BUFFS) do 
            if buff.groupId == "consumables" then AddBuffToggle(buff) end
        end
    end
    content.rowCount = content.rowCount + 0.8; CreateSubLabel(content, "Custom Buffs")
    local infoBox = GUI:CreateInfoBox(content, "|cffFFCC00Info:|r Add custom spellids for buffs, food or potions.\nYou can track multiple buffs (e.g. food) by separating their IDs with a comma.\nUse |cff00ccff/guienchants|r to find your weapon enchant and add your enchantid like this: |cff00ccff7495:224107|r (enchantid:itemid)")
    infoBox:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5))); content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.2
    local rowAdd = CreateFrame("Frame", nil, content); rowAdd:SetSize(GUI.CONTENT_WIDTH - 20, 30); rowAdd:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    local editBox = CreateFrame("EditBox", nil, rowAdd, "BackdropTemplate"); editBox:SetSize(120, 24); editBox:SetPoint("LEFT", 0, 0); editBox:SetAutoFocus(false); editBox:SetNumeric(false); editBox:SetFontObject("ChatFontNormal"); editBox:SetTextInsets(8, 8, 0, 0); editBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1}); editBox:SetBackdropColor(0.15, 0.15, 0.15, 1); editBox:SetBackdropBorderColor(0, 0, 0, 1)
    editBox:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0, 0.6, 1, 1) end); editBox:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end); editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end); editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); editBox.tipText = "Enter Spell ID"; editBox:SetText("Spell ID"); editBox:SetScript("OnEditFocusGained", function(self) if self:GetText() == "Spell ID" then self:SetText("") end end)
    local btnAdd = GUI:CreateButton(rowAdd, "+ Add Custom Buff", 140, 24, function() local text = editBox:GetText(); local isValid = tonumber(text) or string.find(text, "^%d+%s*:%s*%d+$") or string.find(text, "^[%d%s,]+$"); if isValid and RB and RB.AddCustomBuff then local success, err = RB:AddCustomBuff(text); if success then if BuildMissingBuffs then BuildMissingBuffs(parent) end else print("|cffff0000GravityUI Error:|r " .. (err or "Unknown error in AddCustomBuff")) end end end); btnAdd:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.2; local customList = rbDb.customBuffs or {}; local sortedKeys = {}; for k in pairs(customList) do table.insert(sortedKeys, k) end; table.sort(sortedKeys)
    for _, k in ipairs(sortedKeys) do 
        local buff = customList[k]; local row = AddBuffToggle(buff)
        if row then
            local btnDel = GUI:CreateButton(row, "Del", 40, 20, function() if RB.DeleteCustomBuff then RB:DeleteCustomBuff(buff.key); if BuildMissingBuffs then BuildMissingBuffs(parent) end end end); btnDel:SetPoint("RIGHT", row, "RIGHT", -25, 0)
            local btnEdit = GUI:CreateButton(row, "Edit", 40, 20, function() GUI.EditingCustomBuffKey = (GUI.EditingCustomBuffKey == buff.key) and nil or buff.key; if BuildMissingBuffs then BuildMissingBuffs(parent) end end); btnEdit:SetPoint("RIGHT", btnDel, "LEFT", -5, 0)
            if GUI.EditingCustomBuffKey == buff.key then
                content.rowCount = content.rowCount + 0.2; local editRow = CreateFrame("Frame", nil, content); editRow:SetSize(GUI.CONTENT_WIDTH - 20, 30); editRow:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
                local inlineEdit = CreateFrame("EditBox", nil, editRow, "BackdropTemplate"); inlineEdit:SetSize(180, 24); inlineEdit:SetPoint("LEFT", 46, 0); inlineEdit:SetAutoFocus(true); inlineEdit:SetFontObject("ChatFontNormal"); inlineEdit:SetTextInsets(8, 8, 0, 0); inlineEdit:SetText(tostring(buff.spellID)); inlineEdit:HighlightText(); inlineEdit:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1}); inlineEdit:SetBackdropColor(0.15, 0.15, 0.15, 1); inlineEdit:SetBackdropBorderColor(GUI.Colors.accent[1], GUI.Colors.accent[2], GUI.Colors.accent[3], 1)
                inlineEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); GUI.EditingCustomBuffKey = nil; if BuildMissingBuffs then BuildMissingBuffs(parent) end end)
                local saveFunc = function() local text = inlineEdit:GetText(); if text and text ~= "" and RB and RB.DeleteCustomBuff and RB.AddCustomBuff then if tonumber(text) or string.find(text, "^%d+%s*:%s*%d+$") or string.find(text, "^[%d%s,]+$") then RB:DeleteCustomBuff(buff.key); RB:AddCustomBuff(text) end; GUI.EditingCustomBuffKey = nil; if BuildMissingBuffs then BuildMissingBuffs(parent) end end end
                inlineEdit:SetScript("OnEnterPressed", saveFunc); local btnSave = GUI:CreateButton(editRow, "Save", 60, 24, saveFunc); btnSave:SetPoint("LEFT", inlineEdit, "RIGHT", 10, 0); local btnCancel = GUI:CreateButton(editRow, "Cancel", 60, 24, function() GUI.EditingCustomBuffKey = nil; if BuildMissingBuffs then BuildMissingBuffs(parent) end end); btnCancel:SetPoint("LEFT", btnSave, "RIGHT", 5, 0); content.rowCount = content.rowCount + 1.2
            end
        end
    end
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 6. Raid Warnings
local function BuildRaidWarnings(parent)
    -- Prevent overlapping elements by clearing existing content if we are rebuilding
    if parent.scroll then
        parent.scroll:Hide()
        parent.scroll:SetParent(nil)
        parent.scroll = nil
    end

    local scroll, content = GUI:CreateScrollableContent(parent)
    parent.scroll = scroll
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbRW = db.raidWarnings
    local function RefreshRW() if ns.RaidWarnings and ns.RaidWarnings.ApplySettings then ns.RaidWarnings.ApplySettings() end end
    content.rowCount = 0
    local header = GUI:CreateSectionHeader(content, "Raid Warnings (Soulwell, Feast, etc.)")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    local infoBox = GUI:CreateInfoBox(content, "Displays alerts from party members with GravityUI.\nNon-users can use this macro (|cffFF9900replace SPELL_ID|r):")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5)); content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.1
    local macroRow = CreateFrame("Frame", nil, content); macroRow:SetSize(GUI.CONTENT_WIDTH - 40, 26); macroRow:SetPoint("TOPLEFT", 10, -5 - (content.rowCount * (ROW_HEIGHT + 5)))
    local editBox = CreateFrame("EditBox", nil, macroRow, "BackdropTemplate"); editBox:SetSize(GUI.CONTENT_WIDTH - 60, 18); editBox:SetPoint("LEFT", 0, 0); editBox:SetAutoFocus(false); editBox:SetFontObject("GameFontHighlightSmall"); editBox:SetText('/run C_ChatInfo.SendAddonMessage("GravityUI","RW:SPELL_ID",IsInGroup(2)and"INSTANCE_CHAT"or IsInRaid()and"RAID"or"PARTY")'); editBox:SetCursorPosition(0); editBox:SetTextInsets(5, 5, 0, 0); editBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1}); editBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8); editBox:SetBackdropBorderColor(0, 0, 0, 1)
    editBox:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(GUI.Colors.accent[1], GUI.Colors.accent[2], GUI.Colors.accent[3], 1) end); editBox:SetScript("OnLeave", function(self) if not self:HasFocus() then self:SetBackdropBorderColor(0, 0, 0, 1) end end); editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText(); self:SetBackdropBorderColor(GUI.Colors.accent[1], GUI.Colors.accent[2], GUI.Colors.accent[3], 1) end); editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetBackdropBorderColor(0, 0, 0, 1) end); editBox:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end); editBox:SetScript("OnTextChanged", function(self, user) if user then self:SetText('/run C_ChatInfo.SendAddonMessage("GravityUI","RW:SPELL_ID",IsInGroup(2)and"INSTANCE_CHAT"or IsInRaid()and"RAID"or"PARTY")'); self:HighlightText() end end)
    content.rowCount = content.rowCount + 1.2; AddRow(content, "Enable Raid Warnings", "checkbox", "enabled", dbRW, RefreshRW); content.rowCount = content.rowCount + 0.5; CreateSubLabel(content, "Visibility Filters"); AddRow(content, "Show in Party", "checkbox", "showInGroup", dbRW, RefreshRW); AddRow(content, "Show in Raid", "checkbox", "showInRaid", dbRW, RefreshRW); content.rowCount = content.rowCount + 0.5; CreateSubLabel(content, "Text Infos"); local ti = dbRW.textInfos; if not ti then ti = { durabilityEnabled = false, durabilityThreshold = 25, durabilitySize = 24, durabilityColor = {1, 0.2, 0.2, 1}, durabilityX = 0, durabilityY = 200 }; dbRW.textInfos = ti end; AddRow(content, "Durability Check (<25%)", "checkbox", "durabilityEnabled", ti, RefreshRW); AddRow(content, "Durability Threshold %", "slider", 1, 100, "durabilityThreshold", ti, RefreshRW, 1); AddRow(content, "Text Size", "slider", 10, 72, "durabilitySize", ti, RefreshRW, 1); AddRow(content, "Text Color", "color", "durabilityColor", ti, RefreshRW); AddRow(content, "X-Position", "slider", -800, 800, "durabilityX", ti, RefreshRW, 1); AddRow(content, "Y-Position", "slider", -800, 800, "durabilityY", ti, RefreshRW, 1); local previewTIBtn = GUI:CreateButton(content, "Preview Durability Info", 160, 24, function() if ns.TextInfoFrame then if ns.TextInfoFrame:IsShown() then ns.TextInfoFrame:Hide() else RefreshRW(); if ns.TextInfoFrame.text then ns.TextInfoFrame.text:SetText("Durability low") end; ns.TextInfoFrame:Show(); C_Timer.After(5, function() if ns.TextInfoFrame then ns.TextInfoFrame:Hide() end end) end end end); previewTIBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5))); content.rowCount = content.rowCount + 1.2; content.rowCount = content.rowCount + 0.5; CreateSubLabel(content, "Events to Track"); AddRow(content, "Soulwells", "checkbox", "soulwell", dbRW.events, RefreshRW); AddRow(content, "Summoning Rituals", "checkbox", "ritual", dbRW.events, RefreshRW); AddRow(content, "Feasts", "checkbox", "feast", dbRW.events, RefreshRW); AddRow(content, "Repair Bots", "checkbox", "repair", dbRW.events, RefreshRW); AddRow(content, "Refreshment Tables (Mage)", "checkbox", "magetable", dbRW.events, RefreshRW); AddRow(content, "Demonic Gateway", "checkbox", "gateway", dbRW.events, RefreshRW); AddRow(content, "Portals Settings", "checkbox", "portal", dbRW.events, RefreshRW); content.rowCount = content.rowCount + 0.5; CreateSubLabel(content, "Sound Alert"); AddRow(content, "Enable Sound", "checkbox", "soundEnabled", dbRW, RefreshRW); local soundOptions = {{value="Sound\\Interface\\RaidWarning.ogg", text="Raid Warning"}, {value="Sound\\Interface\\ReadyCheck.ogg", text="Ready Check"}}; local LSM = LibStub("LibSharedMedia-3.0", true); if LSM then soundOptions = {}; for name, _ in pairs(LSM:HashTable("sound")) do table.insert(soundOptions, {value=name, text=name}) end; table.sort(soundOptions, function(a,b) return a.text < b.text end) end; AddRow(content, "Alert Sound", "dropdown", soundOptions, "soundFile", dbRW, RefreshRW); content.rowCount = content.rowCount + 0.5; CreateSubLabel(content, "Appearance"); AddRow(content, "Font Size", "slider", 12, 64, "fontSize", dbRW, RefreshRW, 1); AddRow(content, "Text Color", "color", "color", dbRW, RefreshRW); AddRow(content, "X Offset", "slider", -500, 500, "x", dbRW, RefreshRW, 1); AddRow(content, "Y Offset", "slider", -500, 500, "y", dbRW, RefreshRW, 1); local fontOptions = {{value="Fonts\\FRIZQT__.TTF", text="Friz Quadrata"}}; if LSM then fontOptions = {}; for name, _ in pairs(LSM:HashTable("font")) do table.insert(fontOptions, {value=name, text=name}) end; table.sort(fontOptions, function(a,b) return a.text < b.text end) end; AddRow(content, "Font", "dropdown", fontOptions, "font", dbRW, RefreshRW); content.rowCount = content.rowCount + 0.8; local testBtn = GUI:CreateButton(content, "Test Alert", 120, 24, function() if ns.RaidWarnings and ns.RaidWarnings.TestAlert then ns.RaidWarnings.TestAlert() end end); testBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5))); local moverBtn = GUI:CreateButton(content, "Toggle Mover", 120, 24, function() if ns.RaidWarnings and ns.RaidWarnings.ToggleMover then ns.RaidWarnings.ToggleMover() end end); moverBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0); content.rowCount = content.rowCount + 1.2; CreateSubLabel(content, "Custom Spells"); content.rowCount = content.rowCount + 0.2; local rowAdd = CreateFrame("Frame", nil, content); rowAdd:SetSize(GUI.CONTENT_WIDTH - 20, 30); rowAdd:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5))); local inputID = GUI:CreateInput(rowAdd, "ID", "tempID", {}, function() end); inputID:SetPoint("LEFT", 0, 0); inputID:SetWidth(80); inputID.editBox:SetWidth(80); inputID.editBox:SetNumeric(true); inputID.editBox:SetText(""); local typeOptions = { {value="feast", text="Feast"}, {value="soulwell", text="Soulwell"}, {value="portal", text="Portal"}, {value="ritual", text="Ritual"}, {value="repair", text="Repair Bot"}, {value="magetable", text="Mage Table"}, {value="extra", text="Extra"} }; local tempDB = { type = "feast" }; local dropType = GUI:CreateDropdown(rowAdd, "", typeOptions, "type", tempDB, function() end); dropType:SetPoint("LEFT", inputID, "RIGHT", 10, 0); dropType:SetWidth(110); dropType.dropdown:SetPoint("LEFT", dropType, "LEFT", 0, 0); dropType.dropdown:SetPoint("RIGHT", dropType, "RIGHT", 0, 0); local btnAdd = GUI:CreateButton(rowAdd, "+", 30, 24, function() local id = inputID.editBox:GetText(); local type = tempDB.type; if ns.RaidWarnings and ns.RaidWarnings.AddCustomSpell then if ns.RaidWarnings.AddCustomSpell(id, type) then inputID.editBox:SetText(""); if BuildRaidWarnings then BuildRaidWarnings(parent) end end end end); btnAdd:SetPoint("LEFT", dropType, "RIGHT", 10, -10); content.rowCount = content.rowCount + 1.2; if dbRW.customSpells then local sorted = {}; for id, type in pairs(dbRW.customSpells) do table.insert(sorted, {id=id, type=type}) end; table.sort(sorted, function(a,b) return a.id < b.id end); for _, data in ipairs(sorted) do local row = CreateFrame("Frame", nil, content); row:SetSize(GUI.CONTENT_WIDTH - 20, 24); row:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5))); local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); label:SetPoint("LEFT", 0, 0); local name = "Unknown"; local spellInfo = C_Spell.GetSpellInfo(data.id); if spellInfo then name = spellInfo.name end; label:SetText(string.format("|cff00ccff%s|r (%s): %s", data.id, data.type, name)); local btnDel = GUI:CreateButton(row, "X", 20, 20, function() if ns.RaidWarnings and ns.RaidWarnings.RemoveCustomSpell then ns.RaidWarnings.RemoveCustomSpell(data.id); if BuildRaidWarnings then BuildRaidWarnings(parent) end end end); btnDel:SetPoint("RIGHT", row, "RIGHT", -35, 0); content.rowCount = content.rowCount + 0.8 end end
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 7. Difficulty Changer
local function BuildDifficulty(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local c = db.screenindicators.difficulty
    content.rowCount = 0
    local refresh = function() if ns.ScreenIndicators and ns.ScreenIndicators.UpdateDifficultyPosition then ns.ScreenIndicators.UpdateDifficultyPosition() end end
    local header = GUI:CreateSectionHeader(content, "Difficulty Indicator")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    local infoBox = GUI:CreateInfoBox(content, "Automatically shows a difficulty selection bar for 15s when you become Group/Raid Leader.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    CreateSubLabel(content, "General")
    AddRow(content, "Enable Indicator", "checkbox", "enabled", c, refresh)
    AddRow(content, "Instant Dungeon Mythic (Skip UI)", "checkbox", "instantDungeon", c, refresh)
    AddRow(content, "Instant Raid Mythic (Skip UI)", "checkbox", "instantRaid", c, refresh)
    AddRow(content, "Auto-Set Mythic on Timeout", "checkbox", "autoMythic", c, refresh)
    AddRow(content, "Duration (sec)", "slider", 5, 60, "duration", c, refresh, 1)
    content.rowCount = content.rowCount + 0.5
    local previewBtn = GUI:CreateButton(content, "Preview Bar", 140, 24, function() if ns.ScreenIndicators.PreviewDifficulty then ns.ScreenIndicators.PreviewDifficulty() end end)
    previewBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 120, 24, function() if ns.Movers and ns.Movers.Toggle then ns.Movers:Toggle("GravityUI_Difficulty") end end)
    moverBtn:SetPoint("LEFT", previewBtn, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.2
    CreateSubLabel(content, "Dimensions")
    AddRow(content, "Scale", "slider", 0.5, 2.0, "scale", c, refresh, 0.1)
    AddRow(content, "X Offset (Mover)", "slider", -800, 800, "x", c, refresh, 1)
    AddRow(content, "Y Offset (Mover)", "slider", -800, 800, "y", c, refresh, 1)
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 8. AFK Screen
local function BuildAFKScreen(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local c = db.screenindicators.afkScreen
    content.rowCount = 0
    local refresh = function() end
    local header = GUI:CreateSectionHeader(content, "AFK Screen")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    local infoBox = GUI:CreateInfoBox(content, "Replaces the default UI with a cinematic character view while you are Away From Keyboard.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5)); content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    CreateSubLabel(content, "General"); AddRow(content, "Enable AFK Screen", "checkbox", "enabled", c, refresh); AddRow(content, "Prevent in Auction/Professions", "checkbox", "preventInAh", c, refresh); content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Cinematic Camera"); AddRow(content, "Turn Speed", "slider", 1, 10, "camTurnSpeed", c, refresh, 1); local dirOptions = { {text="Left", value=1}, {text="Right", value=2}, {text="Random", value=3} }; AddRow(content, "Rotation Direction", "dropdown", dirOptions, "rotationDirection", c, refresh); content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Appearance & Colors"); AddRow(content, "Use Class Color (Border & Name)", "checkbox", "useClassColor", c, refresh); AddRow(content, "Use Theme Color (If Class Color Off)", "checkbox", "useThemeColor", c, refresh); AddRow(content, "Custom Color (If Both Off)", "color", "customColor", c, refresh); content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Character Model"); AddRow(content, "Show Character Model", "checkbox", "showCharacter", c, refresh); local animOptions = { {text="Stand", value=0}, {text="Walk", value=4}, {text="Dance", value=69} }; AddRow(content, "Display Animation", "dropdown", animOptions, "animationState", c, refresh); content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Text & Information"); AddRow(content, "Show Character Title", "checkbox", "showTitle", c, refresh); AddRow(content, "Show Guild Name", "checkbox", "showGuild", c, refresh); AddRow(content, "Show Guild Brackets (< >)", "checkbox", "showBrackets", c, refresh); AddRow(content, "Show Guild Rank", "checkbox", "showRank", c, refresh); content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Time & Timer Settings"); AddRow(content, "Show Current Time", "checkbox", "showClock", c, refresh); local timeOptions = { {text="24-Hour", value=1}, {text="12-Hour", value=2}, {text="12-Hour (No Leading 0)", value=3} }; AddRow(content, "Time Format", "dropdown", timeOptions, "timeFormat", c, refresh); if c.timeFormat ~= 1 then AddRow(content, "Show AM/PM", "checkbox", "showAmPm", c, refresh) end; AddRow(content, "Show AFK Duration", "checkbox", "showTimer", c, refresh); AddRow(content, "Display Timer Seconds", "checkbox", "displaySeconds", c, refresh)
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 10. Healer Mana
local function BuildHealerMana(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local hm = db.screenindicators.healerMana
    content.rowCount = 0
    local refresh = function() if ns.RefreshHealerMana then ns.RefreshHealerMana() end end
    local header = GUI:CreateSectionHeader(content, "Healer Mana Tracker")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    local infoBox = GUI:CreateInfoBox(content, "Displays spec icon, name and mana% of all healers in the current party or raid. Only visible while grouped.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5)); content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    CreateSubLabel(content, "General")
    AddRow(content, "Enable Healer Mana",       "checkbox", "enabled",        hm, refresh)
    AddRow(content, "Only if I am a Healer",    "checkbox", "onlyIfHealer",   hm, refresh)
    AddRow(content, "Enable in Dungeons",        "checkbox", "enableInDungeon",hm, refresh)
    AddRow(content, "Enable in Raids",           "checkbox", "enableInRaid",   hm, refresh)
    AddRow(content, "Max Healers Shown",         "slider",   1, 5, "maxHealers", hm, refresh, 1)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Layout")
    local growOpts = { {value=true, text="Down"}, {value=false, text="Up"} }
    AddRow(content, "Grow Direction",            "dropdown", growOpts, "growDown", hm, refresh)
    AddRow(content, "Icon Size",                 "slider",   16, 48, "iconSize",     hm, refresh, 1)
    AddRow(content, "Font Size",                 "slider",   8,  20, "fontSize",     hm, refresh, 1)
    AddRow(content, "Frame Spacing",             "slider",   0,  20, "frameSpacing", hm, refresh, 1)
    AddRow(content, "Frame Width",               "slider",   80, 280, "frameWidth",  hm, refresh, 1)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Colors")
    AddRow(content, "Mana % Color",              "color",    "highManaColor", hm, refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Position")
    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 140, 24, function()
        if ns.HealerMana and ns.HealerMana.ToggleMover then
            ns.HealerMana:ToggleMover()
        end
    end)
    moverBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    content.rowCount = content.rowCount + 1.2
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

local function BuildConsumables(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local c = db.screenindicators.consumables
    content.rowCount = 0
    local refresh = function() if ns.Consumables and ns.Consumables.ApplySettings then ns.Consumables:ApplySettings() end end
    local header = GUI:CreateSectionHeader(content, "Consumables Tracker")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    local infoBox = GUI:CreateInfoBox(content, "Displays missing consumables like food and flasks for yourself and your group members during a Ready Check.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5)); content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    CreateSubLabel(content, "Player Consumables Frame"); AddRow(content, "Enable Personal Frame", "checkbox", "enabled", c, refresh); content.rowCount = content.rowCount + 0.5; CreateSubLabel(content, "Raid Status Frame"); AddRow(content, "Enable Raid Frame", "checkbox", "showRaidFrame", c, refresh)
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- PAGE REGISTRATION
--==============================================================================================================================================================================================
ns.GUI:RegisterPage("indicators", {
    title = "Indicators",
    subTabs = {
        { name = "Cursor",             builder = BuildCursor },
        { name = "Crosshair",          builder = BuildCrosshair },
        { name = "Healer Mana",        builder = BuildHealerMana },
        { name = "Pet Info",           builder = BuildPet },
        { name = "Combat Timer",       builder = BuildCombatTimer },
        { name = "Cooldown Text",      builder = ns.CooldownText and ns.CooldownText.AddOptions or function() end },
        { name = "Missing Buffs",      builder = BuildMissingBuffs },
        { name = "Raid Warnings",      builder = BuildRaidWarnings },
        { name = "Consumables",        builder = BuildConsumables },
        { name = "Difficulty Changer", builder = BuildDifficulty },
        { name = "AFK Screen",         builder = BuildAFKScreen },
    },
    OnBuild = function(content)
        local scrollFrame = content:GetParent()
        content:Hide()
        if scrollFrame.ScrollBar then scrollFrame.ScrollBar:Hide(); scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end) end
        local opts = GUI.pages["indicators"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["indicators"]
        if not opts.subTabsContainer then return end
        subIndex = subIndex or 1
        for _, cf in pairs(opts.subTabsContainer.tabContents) do cf:Hide() end
        if opts.subTabsContainer.tabContents[subIndex] then opts.subTabsContainer.tabContents[subIndex]:Show() end
    end
})
