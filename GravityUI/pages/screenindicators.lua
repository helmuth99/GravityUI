-- GravityUI - UI Indicators Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

-- ═══════════════════════════════════════════════════════════════
-- HELPER: PROPERTY ROW
-- ═══════════════════════════════════════════════════════════════
local ROW_HEIGHT = 30
local LABEL_WIDTH = 220
local WIDGET_WIDTH = 250

local function CreatePropertyRow(parent, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
    
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(label, 12, "")
    label:SetJustifyH("LEFT")
    label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
    label:SetPoint("LEFT", 0, 0)
    label:SetText(labelText)
    label:SetTextColor(unpack(ns.Colors.text))
    
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
        widget.editBox:SetWidth(WIDGET_WIDTH)
    end
    return row
end

local function AddRow(container, label, type, ...)
    local row = CreatePropertyRow(container, label, type, ...)
    local count = container.rowCount or 0
    row:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
    container.rowCount = count + 1
    -- container:SetHeight(10 + (container.rowCount * (ROW_HEIGHT + 5))) -- Done at end
    return row
end

local function CreateSubLabel(container, text)
    local count = container.rowCount or 0
    local sh = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sh:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
    sh:SetText(text)
    sh:SetTextColor(unpack(GUI.Colors.accent))
    GUI:SetFont(sh, 12, "")
    container.rowCount = count + 1
end

-- ═══════════════════════════════════════════════════════════════
-- BUILDERS
-- ═══════════════════════════════════════════════════════════════

-- 1. Cursor
local function BuildCursor(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbS = db.screenindicators
    local c = dbS.cursor
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
    
    local reticleStyles = {{value="dot", text="Dot"},{value="cross", text="Crosshair (Atlas)"},{value="chevron", text="Chevron (Atlas)"},{value="diamond", text="Diamond (Atlas)"}}
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

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. Crosshair
local function BuildCrosshair(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbS = db.screenindicators
    local ch = dbS.crosshair
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

-- 3. Combat Status
local function BuildCombatStatus(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbS = db.screenindicators
    local cs = dbS.combatStatus
    content.rowCount = 0
    local refresh = function() if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end end

    local header = GUI:CreateSectionHeader(content, "Combat Status Indicator")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    CreateSubLabel(content, "Enable & Preview")
    AddRow(content, "Enable Indicator", "checkbox", "enabled", cs, refresh)
    
    local previewRow = CreateFrame("Frame", nil, content)
    previewRow:SetSize(content:GetWidth() - 20, 30)
    previewRow:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    
    local btnEnter = GUI:CreateButton(previewRow, "+Combat", 180, 24, function() ns.ScreenIndicators.PreviewCombatStatus("+Combat") end)
    btnEnter:SetPoint("LEFT", previewRow, "LEFT", 140, 0)
    
    local btnLeave = GUI:CreateButton(previewRow, "-Combat", 180, 24, function() ns.ScreenIndicators.PreviewCombatStatus("-Combat") end)
    btnLeave:SetPoint("LEFT", btnEnter, "RIGHT", 10, 0)
    
    content.rowCount = content.rowCount + 1.3
    
    CreateSubLabel(content, "Appearance")
    AddRow(content, "Font Size", "slider", 10, 60, "fontSize", cs, refresh, 1)
    AddRow(content, "Display Time (sec)", "slider", 0.1, 5, "displayTime", cs, refresh, 0.1)
    AddRow(content, "Fade Duration (sec)", "slider", 0.1, 2, "fadeTime", cs, refresh, 0.1)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Position")
    AddRow(content, "X Offset", "slider", -1000, 1000, "xOffset", cs, refresh, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "yOffset", cs, refresh, 1)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Colors")
    AddRow(content, "Enter Combat Color", "color", "enterCombatColor", cs, refresh)
    AddRow(content, "Leave Combat Color", "color", "leaveCombatColor", cs, refresh)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 4. Pet
local function BuildPet(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbS = db.screenindicators
    local ps = dbS.petWarnings
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
    
    local btnMover = GUI:CreateButton(petPreviewRow, "Toggle Mover", 120, 24, function() 
        if ns.ScreenIndicators and ns.ScreenIndicators.ToggleMover then 
            ns.ScreenIndicators.ToggleMover("pet") 
        end 
    end)
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
    
    local strataOptions = {
        {value="BACKGROUND", text="Background"},
        {value="LOW", text="Low"},
        {value="MEDIUM", text="Medium"},
        {value="HIGH", text="High"},
        {value="DIALOG", text="Dialog"},
        {value="FULLSCREEN", text="Fullscreen"},
        {value="FULLSCREEN_DIALOG", text="Fullscreen Dialog"},
        {value="TOOLTIP", text="Tooltip"},
    }
    AddRow(content, "Frame Strata", "dropdown", strataOptions, "strata", ps, refresh)
    
    content.rowCount = content.rowCount + 0.3
    
    CreateSubLabel(content, "Colors")
    AddRow(content, "Warning use Theme Color", "checkbox", "useThemeColor", ps, refresh)
    AddRow(content, "Warning Color", "color", "warningColor", ps, refresh)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 5. Missing Buffs
local function BuildMissingBuffs(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local rbDb = db.raidBuffs
    
    content.rowCount = 0
    local refresh = function() if ns.RaidBuffs and ns.RaidBuffs.Refresh then ns.RaidBuffs:Refresh() end end
    
    -- Helper to access RaidBuffs module data
    local RB = ns.RaidBuffs
    if not RB then
        local err = content:CreateFontString(nil, "OVERLAY", "GameFontRed")
        err:SetPoint("TOPLEFT", 10, -10)
        err:SetText("Error: RaidBuffs module not loaded.")
        return
    end

    local header = GUI:CreateSectionHeader(content, "Missing Raid Buffs")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    -- Open Standalone Config Button
    local btnConfig = GUI:CreateButton(content, "Toggle Mover / Unlock Position", 250, 24, function() 
        if RB.ToggleMover then RB:ToggleMover() end 
    end)
    btnConfig:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    content.rowCount = content.rowCount + 0.8

    -- ════════════════════════════════════════════════
    -- BEHAVIOR
    -- ════════════════════════════════════════════════
    AddRow(content, "Enable Missing Buffs", "checkbox", "enabled", rbDb, refresh)
    AddRow(content, "Show 'Buff' Reminder Text", "checkbox", "showBuffReminder", rbDb, refresh)
    
    -- Reminder Text Customization
    -- Reminder Text Customization
    AddRow(content, "   Size", "slider", 8, 32, "reminderFontSize", rbDb, refresh, 1)
    AddRow(content, "   Color", "color", "reminderColor", rbDb, refresh)
    
    AddRow(content, "Show Only In Group/Raid", "checkbox", "showOnlyInGroup", rbDb, refresh)
    AddRow(content, "Show Only In Instance", "checkbox", "showOnlyInInstance", rbDb, refresh)
    AddRow(content, "Show Only On Ready Check", "checkbox", "showOnlyOnReadyCheck", rbDb, refresh)
    AddRow(content, "Ready Check Duration", "slider", 5, 60, "readyCheckDuration", rbDb, refresh, 1)
    AddRow(content, "Show Only My Class Buffs", "checkbox", "showOnlyPlayerClassBuff", rbDb, refresh)
    AddRow(content, "Show Only My Missing Buffs", "checkbox", "showOnlyPlayerMissing", rbDb, refresh)

    content.rowCount = content.rowCount + 0.5

    -- ════════════════════════════════════════════════
    -- APPEARANCE
    -- ════════════════════════════════════════════════
    CreateSubLabel(content, "Appearance")
    AddRow(content, "Icon Size", "slider", 16, 128, "iconSize", rbDb, refresh, 4)
    AddRow(content, "Text Size", "slider", 8, 32, "labelFontSize", rbDb, refresh, 1)
    AddRow(content, "Spacing", "slider", 0, 50, "spacing", rbDb, refresh, 1)
    -- Grow direction
    local growOptions = {{value="LEFT", text="Left"}, {value="CENTER", text="Center"}, {value="RIGHT", text="Right"}}
    AddRow(content, "Grow Direction", "dropdown", growOptions, "growDirection", rbDb, refresh)
    
    -- Expiration Warning
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Expiration Warning")
    AddRow(content, "Show Glow Warning", "checkbox", "showExpirationGlow", rbDb, refresh)
    AddRow(content, "Warning Threshold (min)", "slider", 1, 30, "expirationThreshold", rbDb, refresh, 1)
    

    AddRow(content, "Glow Color", "color", "glowColor", rbDb, refresh)
    content.rowCount = content.rowCount + 0.8

    -- ════════════════════════════════════════════════
    -- CATEGORY & SPLIT SETTINGS
    -- ════════════════════════════════════════════════
    content.rowCount = content.rowCount + 0.8
    CreateSubLabel(content, "Category Frames (Split Bars)")
    
    local function AddCategoryControl(label, key)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(GUI.CONTENT_WIDTH - 20, 24)
        row:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
        
        -- Label
        local txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        txt:SetPoint("LEFT", 0, 0)
        txt:SetText(label)
        txt:SetWidth(120)
        
        -- Helper to create styled checkbutton
        local function CreateStyledCheck(parent, labelText, dbTable, dbKey, onClick)
            local cb = CreateFrame("Button", nil, parent, "BackdropTemplate")
            cb:SetSize(20, 20)
            
            cb:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            cb:SetBackdropColor(0.15, 0.15, 0.15, 1)
            cb:SetBackdropBorderColor(0, 0, 0, 1)
            
            local check = cb:CreateTexture(nil, "OVERLAY")
            check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            check:SetPoint("CENTER")
            check:SetSize(16, 16)
            check:SetDesaturated(true)
            check:SetVertexColor(unpack(GUI.Colors.accent))
            
            local function UpdateState()
                local val = dbTable[dbKey]
                if val == nil then val = true end -- specific logic for these tables
                check:SetShown(val)
            end
            UpdateState()
            
            cb:SetScript("OnClick", function()
                local val = dbTable[dbKey]
                if val == nil then val = true end
                dbTable[dbKey] = not val
                UpdateState()
                if onClick then onClick() end
            end)
            
            cb:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(GUI.Colors.accent[1], GUI.Colors.accent[2], GUI.Colors.accent[3], 1) end)
            cb:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end)
            
            if labelText then
                cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
                cb.text:SetText(labelText)
            end
            
            return cb
        end
        
        -- Enable Checkbox
        if not rbDb.categorySettings[key] then rbDb.categorySettings[key] = {} end
        local cbEnable = CreateStyledCheck(row, "Enable", rbDb.categorySettings[key], "enabled", refresh)
        cbEnable:SetPoint("LEFT", 130, 0)
        
        -- Split Checkbox
        local cbSplit = CreateStyledCheck(row, "Detach / Split", rbDb.splitCategories, key, refresh)
        cbSplit:SetPoint("LEFT", 220, 0)
        
        content.rowCount = content.rowCount + 0.8
    end
    
    AddCategoryControl("Raid Buffs", "raid")
    AddCategoryControl("Self Buffs", "self")
    AddCategoryControl("Presence Buffs", "presence")
    AddCategoryControl("Targeted Buffs", "targeted")
    AddCategoryControl("Custom Buffs", "custom")

    -- ════════════════════════════════════════════════
    -- BUFF LISTS
    -- ════════════════════════════════════════════════
    local function AddBuffToggle(buff)
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(GUI.CONTENT_WIDTH - 20, 24)
        row:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
        
        -- Styled Checkbox
        local cb = CreateFrame("Button", nil, row, "BackdropTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("LEFT", 0, 0)
        
        cb:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        cb:SetBackdropColor(0.15, 0.15, 0.15, 1)
        cb:SetBackdropBorderColor(0, 0, 0, 1)
        
        local check = cb:CreateTexture(nil, "OVERLAY")
        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        check:SetPoint("CENTER")
        check:SetSize(16, 16)
        check:SetDesaturated(true)
        check:SetVertexColor(unpack(GUI.Colors.accent))
        
        local function UpdateState()
             local val = rbDb.enabledBuffs[buff.key]
             if val == nil then val = true end
             check:SetShown(val)
        end
        UpdateState()
        
        cb:SetScript("OnClick", function()
             local val = rbDb.enabledBuffs[buff.key]
             if val == nil then val = true end
             rbDb.enabledBuffs[buff.key] = not val
             UpdateState()
             refresh()
        end)
        
        cb:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(GUI.Colors.accent[1], GUI.Colors.accent[2], GUI.Colors.accent[3], 1) end)
        cb:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end)
        
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        
        local tex = buff.iconOverride
        if not tex then
             local id = type(buff.spellID) == "table" and buff.spellID[1] or buff.spellID
             if C_Spell and C_Spell.GetSpellTexture then
                 tex = C_Spell.GetSpellTexture(id)
             else
                 tex = GetSpellTexture(id)
             end
        end
        icon:SetTexture(tex)
        
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        label:SetText(buff.name or "Unknown Buff")
        
        content.rowCount = content.rowCount + 0.8
        return row
    end

    content.rowCount = content.rowCount + 0.8
    if RB.RAID_BUFFS then
        CreateSubLabel(content, "Raid Buffs (Group)")
        for _, buff in ipairs(RB.RAID_BUFFS) do AddBuffToggle(buff) end
    end
    
    content.rowCount = content.rowCount + 0.5
    if RB.PRESENCE_BUFFS then
        CreateSubLabel(content, "Presence Buffs (One Per Group)")
        for _, buff in ipairs(RB.PRESENCE_BUFFS) do AddBuffToggle(buff) end
    end
    
    content.rowCount = content.rowCount + 0.5
    if RB.TARGETED_BUFFS then
        CreateSubLabel(content, "Targeted Buffs (On Others)")
        for _, buff in ipairs(RB.TARGETED_BUFFS) do AddBuffToggle(buff) end
    end
    
    content.rowCount = content.rowCount + 0.5
    if RB.SELF_BUFFS then
        CreateSubLabel(content, "Self Buffs (Personal)")
        for _, buff in ipairs(RB.SELF_BUFFS) do AddBuffToggle(buff) end
    end
    
    -- ════════════════════════════════════════════════
    -- CUSTOM BUFFS
    -- ════════════════════════════════════════════════
    content.rowCount = content.rowCount + 0.8
    CreateSubLabel(content, "Custom Buffs")
    
    -- Info Text
    local infoText = "|cffFFCC00Info:|r Add custom spellids for buffs, food or potions.\nUse |cff00ccff/guienchants|r to find your weapon enchant and add your enchantid like this: |cff00ccff7495:224107|r (enchantid:itemid)"
    local infoBox = GUI:CreateInfoBox(content, infoText)
    infoBox:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.2
    
    -- Add Input and Button
    local rowAdd = CreateFrame("Frame", nil, content)
    rowAdd:SetSize(GUI.CONTENT_WIDTH - 20, 30)
    rowAdd:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    
    local editBox = CreateFrame("EditBox", nil, rowAdd, "BackdropTemplate")
    editBox:SetSize(120, 24)
    editBox:SetPoint("LEFT", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(false) -- Changed to false to allow ":"
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetTextInsets(8, 8, 0, 0)
    
    -- Style matches Framework Input
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.15, 0.15, 0.15, 1)
    editBox:SetBackdropBorderColor(0, 0, 0, 1)
    
    editBox:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0, 0.6, 1, 1) end)
    editBox:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0, 0, 0, 1) end)

    editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox.tipText = "Enter Spell ID"
    editBox:SetText("Spell ID")
    editBox:SetScript("OnEditFocusGained", function(self) if self:GetText() == "Spell ID" then self:SetText("") end end)
    
    local btnAdd = GUI:CreateButton(rowAdd, "+ Add Custom Buff", 140, 24, function() 
        local text = editBox:GetText()
        -- text can be "12345" or "7494:224107"
        
        -- Basic Validation
        local isValid = tonumber(text) or string.find(text, "^%d+:%d+$") or string.find(text, "^%d+%s*:%s*%d+$")
        
        if isValid and RB and RB.AddCustomBuff then
            local success, err = RB:AddCustomBuff(text)
            if success then
                print("GravityUI: Custom Buff Added:", text)
                
                -- Refresh UI by rebuilding this tab
                if scroll then scroll:Hide() end
                if BuildMissingBuffs then 
                     BuildMissingBuffs(parent) 
                else
                     print("GravityUI: Please switch tabs to refresh list.")
                end
            else
                print("|cffff0000GravityUI Error:|r " .. (err or "Unknown error in AddCustomBuff"))
            end
        else
             if not isValid then print("|cffff0000GravityUI:|r Invalid format. Use 'SpellID' or 'EnchantID:ItemID'.") end
             if not RB then print("|cffff0000GravityUI:|r RaidBuffs module missing from closure.") end
             if RB and not RB.AddCustomBuff then print("|cffff0000GravityUI:|r AddCustomBuff function missing on RaidBuffs object.") end
        end
    end)
    btnAdd:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
    
    content.rowCount = content.rowCount + 1.2
    
    -- List Custom Buffs
    local customList = rbDb.customBuffs or {}
    local sortedKeys = {}
    for k in pairs(customList) do table.insert(sortedKeys, k) end
    table.sort(sortedKeys)
    
    for _, k in ipairs(sortedKeys) do
        local buff = customList[k]
        
        -- Reuse standardized AddBuffToggle which handles styling and rowCount
        -- We need `AddBuffToggle` to return the frame to add buttons
        -- Assuming I update AddBuffToggle to return 'row' (I will do that below)
        local row = AddBuffToggle(buff) 
        
        if row then
            local btnDel = GUI:CreateButton(row, "Del", 40, 20, function()
                if RB.DeleteCustomBuff then 
                    RB:DeleteCustomBuff(buff.key)
                    -- Refresh UI
                    if scroll then scroll:Hide() end
                    if BuildMissingBuffs then BuildMissingBuffs(parent) end
                end
            end)
            btnDel:SetPoint("RIGHT", row, "RIGHT", -25, 0)
        end
    end


    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN PAGE
-- ═══════════════════════════════════════════════════════════════
ns.GUI:RegisterPage("screenindicators", {
    title = "UI Indicators",
    OnBuild = function(content)
        -- Hide default scrollframe parent
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
-- 6. Raid Warnings
local function BuildRaidWarnings(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    
    -- Ensure DB table exists
    if not db.raidWarnings then db.raidWarnings = {} end
    local dbRW = db.raidWarnings
    
    -- Defaults
    if dbRW.enabled == nil then dbRW.enabled = true end
    if dbRW.showInGroup == nil then dbRW.showInGroup = true end
    if dbRW.showInRaid == nil then dbRW.showInRaid = true end
    if dbRW.soundEnabled == nil then dbRW.soundEnabled = true end
    if not dbRW.events then dbRW.events = {soulwell=true, ritual=true, feast=true, repair=true, magetable=true, portal=false} end
    
    local function RefreshRW()
        if ns.RaidWarnings and ns.RaidWarnings.ApplySettings then ns.RaidWarnings.ApplySettings() end
    end

    content.rowCount = 0
    local header = GUI:CreateSectionHeader(content, "Raid Warnings (Soulwell, Feast, etc.)")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    local infoBox = GUI:CreateInfoBox(content, "Displays an alert when a group member places a Feast, Soulwell, Repair Bot, or Summoning Ritual.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Raid Warnings", "checkbox", "enabled", dbRW, RefreshRW)
    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Visibility Filters")
    AddRow(content, "Show in Party", "checkbox", "showInGroup", dbRW, RefreshRW)
    AddRow(content, "Show in Raid", "checkbox", "showInRaid", dbRW, RefreshRW)
    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Events to Track")
    AddRow(content, "Soulwells", "checkbox", "soulwell", dbRW.events, RefreshRW)
    AddRow(content, "Summoning Rituals", "checkbox", "ritual", dbRW.events, RefreshRW)
    AddRow(content, "Feasts", "checkbox", "feast", dbRW.events, RefreshRW)
    AddRow(content, "Repair Bots", "checkbox", "repair", dbRW.events, RefreshRW)
    AddRow(content, "Refreshment Tables (Mage)", "checkbox", "magetable", dbRW.events, RefreshRW)
    AddRow(content, "Portals Settings", "checkbox", "portal", dbRW.events, RefreshRW)
    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Sound Alert")
    AddRow(content, "Enable Sound", "checkbox", "soundEnabled", dbRW, RefreshRW)
    
    local soundOptions = {{value="Sound\\Interface\\RaidWarning.ogg", text="Raid Warning"}, {value="Sound\\Interface\\ReadyCheck.ogg", text="Ready Check"}}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        soundOptions = {}
        for name, _ in pairs(LSM:HashTable("sound")) do table.insert(soundOptions, {value=name, text=name}) end
        table.sort(soundOptions, function(a,b) return a.text < b.text end)
    end
    AddRow(content, "Alert Sound", "dropdown", soundOptions, "soundFile", dbRW, RefreshRW)
    
    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Appearance")
    AddRow(content, "Font Size", "slider", 12, 64, "fontSize", dbRW, RefreshRW, 1)
    AddRow(content, "Text Color", "color", "color", dbRW, RefreshRW)
    AddRow(content, "X Offset", "slider", -500, 500, "x", dbRW, RefreshRW, 1)
    AddRow(content, "Y Offset", "slider", -500, 500, "y", dbRW, RefreshRW, 1)
    
    -- Font Selection
    local fontOptions = {{value="Fonts\\FRIZQT__.TTF", text="Friz Quadrata"}}
    if LSM then
        fontOptions = {}
        for name, _ in pairs(LSM:HashTable("font")) do table.insert(fontOptions, {value=name, text=name}) end
         table.sort(fontOptions, function(a,b) return a.text < b.text end)
    end
    AddRow(content, "Font", "dropdown", fontOptions, "font", dbRW, RefreshRW)
    
    content.rowCount = content.rowCount + 0.8
    
    local testBtn = GUI:CreateButton(content, "Test Alert", 120, 24, function()
        if ns.RaidWarnings and ns.RaidWarnings.TestAlert then ns.RaidWarnings.TestAlert() end
    end)
    testBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    
    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 120, 24, function()
        if ns.RaidWarnings and ns.RaidWarnings.ToggleMover then ns.RaidWarnings.ToggleMover() end
    end)
    moverBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    
    content.rowCount = content.rowCount + 1.2
    
    -- ════════════════════════════════════════════════
    -- CUSTOM SPELLS
    -- ════════════════════════════════════════════════
    CreateSubLabel(content, "Custom Spells")
    content.rowCount = content.rowCount + 0.2
    
    local rowAdd = CreateFrame("Frame", nil, content)
    rowAdd:SetSize(GUI.CONTENT_WIDTH - 20, 30)
    rowAdd:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    
    -- 1. Spell ID Input
    local inputID = GUI:CreateInput(rowAdd, "ID", "tempID", {}, function() end)
    inputID:SetPoint("LEFT", 0, 0)
    inputID:SetWidth(80)
    inputID.editBox:SetWidth(80)
    inputID.editBox:SetNumeric(true)
    inputID.editBox:SetText("")
    inputID.editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    
    -- 2. Type Dropdown
    local typeOptions = {
        {value="feast", text="Feast"},
        {value="soulwell", text="Soulwell"},
        {value="portal", text="Portal"},
        {value="ritual", text="Ritual"},
        {value="repair", text="Repair Bot"},
        {value="magetable", text="Mage Table"},
        {value="extra", text="Extra"}, -- Added "Extra"
    }
    -- Hacky dropdown creation since GUI:CreateDropdown binds to DB
    -- We'll just use a local table to store the temp selection
    local tempDB = { type = "feast" }
    local dropType = GUI:CreateDropdown(rowAdd, "", typeOptions, "type", tempDB, function() end)
    dropType:SetPoint("LEFT", inputID, "RIGHT", 10, 0)
    dropType:SetWidth(110)
    dropType.dropdown:SetPoint("LEFT", dropType, "LEFT", 0, 0)
    dropType.dropdown:SetPoint("RIGHT", dropType, "RIGHT", 0, 0)
    
    -- 3. Add Button
    local btnAdd = GUI:CreateButton(rowAdd, "+", 30, 24, function() 
        local id = inputID.editBox:GetText()
        local type = tempDB.type
        
        if ns.RaidWarnings and ns.RaidWarnings.AddCustomSpell then
            local success, err = ns.RaidWarnings.AddCustomSpell(id, type)
            if success then
                inputID.editBox:SetText("")
                -- Rebuild parent to show new item
                if scroll then scroll:Hide() end
                if BuildRaidWarnings then BuildRaidWarnings(parent) end
            else
                print("|cffff0000GravityUI Error:|r " .. (err or "Invalid Input"))
            end
        end
    end)
    -- Align with input box content (approx -10y to account for "ID" label)
    btnAdd:SetPoint("LEFT", dropType, "RIGHT", 10, -10)
    
    content.rowCount = content.rowCount + 1.2
    
    -- List Custom Spells
    if dbRW.customSpells then
        local sorted = {}
        for id, type in pairs(dbRW.customSpells) do table.insert(sorted, {id=id, type=type}) end
        table.sort(sorted, function(a,b) return a.id < b.id end)
        
        for _, data in ipairs(sorted) do
             local row = CreateFrame("Frame", nil, content)
             row:SetSize(GUI.CONTENT_WIDTH - 20, 24)
             row:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
             
             local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
             label:SetPoint("LEFT", 0, 0)
             
             -- Try to get spell info
             local name = "Unknown"
             local spellInfo = C_Spell.GetSpellInfo(data.id)
             if spellInfo then name = spellInfo.name end
             
             label:SetText(string.format("|cff00ccff%s|r (%s): %s", data.id, data.type, name))
             
             local btnDel = GUI:CreateButton(row, "X", 20, 20, function()
                 if ns.RaidWarnings and ns.RaidWarnings.RemoveCustomSpell then
                     ns.RaidWarnings.RemoveCustomSpell(data.id)
                     -- Rebuild
                     if scroll then scroll:Hide() end
                     if BuildRaidWarnings then BuildRaidWarnings(parent) end
                 end
             end)
             -- Adjusted position to prevent clipping
             btnDel:SetPoint("RIGHT", row, "RIGHT", -35, 0)
             
             content.rowCount = content.rowCount + 0.8
        end
    end
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

        -- Create SubTabs
        local subTabs = GUI:CreateSubTabs(scrollFrame, {
            { name = "Cursor", builder = BuildCursor },
            { name = "Crosshair", builder = BuildCrosshair },
            { name = "Combat Status", builder = BuildCombatStatus },
            { name = "Pet", builder = BuildPet },
            { name = "Missing Buffs", builder = BuildMissingBuffs },
            { name = "Raid Warnings", builder = BuildRaidWarnings },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
