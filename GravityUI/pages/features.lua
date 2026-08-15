-- GravityUI - Features Page
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

-- 1. Dragonriding (Skyriding)
local function BuildDragonriding(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local function RefreshSkyriding() if ns.RefreshSkyriding then ns.RefreshSkyriding() end end
    local dbSky = db.skyriding
    if not dbSky then dbSky = {}; db.skyriding = dbSky end
    if dbSky.enabled == nil then dbSky.enabled = true end

    local header = GUI:CreateSectionHeader(content, "Dragonriding")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    CreateSubLabel(content, "Enable")
    local infoBox = GUI:CreateInfoBox(content, "Displays vigor charges, recharge progress, and speed while skyriding.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Vigor Bar", "checkbox", "enabled", dbSky, RefreshSkyriding)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Visibility")
    local visOptions = {{value="ALWAYS", text="Always Visible"}, {value="FLYING_ONLY", text="Only When Flying"}, {value="AUTO", text="Auto (fade)"}}
    AddRow(content, "Visibility Mode", "dropdown", visOptions, "visibility", dbSky, RefreshSkyriding)
    AddRow(content, "Fade Delay (sec)", "slider", 0, 10, "fadeDelay", dbSky, RefreshSkyriding, 0.5)
    AddRow(content, "Fade Speed (sec)", "slider", 0.1, 1.0, "fadeDuration", dbSky, RefreshSkyriding, 0.1)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Bar Size")
    AddRow(content, "Width", "slider", 100, 500, "width", dbSky, RefreshSkyriding, 1)
    AddRow(content, "Vigor Height", "slider", 4, 30, "vigorHeight", dbSky, RefreshSkyriding, 1)
    AddRow(content, "Second Wind Height", "slider", 2, 20, "secondWindHeight", dbSky, RefreshSkyriding, 1)
    
    local textureOptions = {{value="Solid", text="Solid"}, {value="Interface/AddOns/GravityUI/assets/textures/Flat.tga", text="Flat"}}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then 
        textureOptions = {}
        for name, _ in pairs(LSM:HashTable("statusbar")) do table.insert(textureOptions, {value=name, text=name}) end
        table.sort(textureOptions, function(a,b) return a.text < b.text end)
    end
    AddRow(content, "Bar Texture", "dropdown", textureOptions, "barTexture", dbSky, RefreshSkyriding)
    
    local swModeOptions = {{value="PIPS", text="Pips"}, {value="MINIBAR", text="Minibar"}, {value="TEXT", text="Text"}, {value="HIDDEN", text="Disabled"}}
    AddRow(content, "Second Wind Mode", "dropdown", swModeOptions, "secondWindMode", dbSky, RefreshSkyriding)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Position")
    AddRow(content, "Lock Position", "checkbox", "locked", dbSky, RefreshSkyriding)
    AddRow(content, "X Offset", "slider", -1000, 1000, "offsetX", dbSky, RefreshSkyriding, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "offsetY", dbSky, RefreshSkyriding, 1)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Colors & Style")
    AddRow(content, "Use Theme Color for Vigor", "checkbox", "useThemeColorVigor", dbSky, RefreshSkyriding)
    AddRow(content, "Vigor Fill Color", "color", "barColor", dbSky, RefreshSkyriding)
    AddRow(content, "Use Theme Color for Second Wind", "checkbox", "useThemeColorSecondWind", dbSky, RefreshSkyriding)
    AddRow(content, "Second Wind Color", "color", "secondWindColor", dbSky, RefreshSkyriding)
    AddRow(content, "Background Color", "color", "backgroundColor", dbSky, RefreshSkyriding)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Text Display")
    AddRow(content, "Show Vigor Count", "checkbox", "showVigorText", dbSky, RefreshSkyriding)
    local vigorFormatOptions = {{value="FRACTION", text="Fraction (4/6)"}, {value="CURRENT", text="Current (4)"}}
    AddRow(content, "Vigor Format", "dropdown", vigorFormatOptions, "vigorTextFormat", dbSky, RefreshSkyriding)
    AddRow(content, "Show Speed", "checkbox", "showSpeed", dbSky, RefreshSkyriding)
    local speedFormatOptions = {{value="PERCENT", text="Percentage"}, {value="RAW", text="Raw Speed"}}
    AddRow(content, "Speed Format", "dropdown", speedFormatOptions, "speedFormat", dbSky, RefreshSkyriding)
    AddRow(content, "Show Whirling Surge Icon", "checkbox", "showAbilityIcon", dbSky, RefreshSkyriding)
    AddRow(content, "Text Font Size", "slider", 8, 24, "vigorFontSize", dbSky, RefreshSkyriding, 1)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. M+ Teleport
local function BuildTeleport(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "M+ Teleport")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local tpInfo = GUI:CreateInfoBox(content, "|cffFFCC00Note:|r Allows you to click dungeon icons in the Mythic+ Challenges frame to cast teleport spells.")
    tpInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (tpInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable M+ Teleports Overlay", "checkbox", "mplusTeleportEnabled", dbUI, function() if ns.MPlusTeleport and ns.MPlusTeleport.ApplySettings then ns.MPlusTeleport:ApplySettings() end end)
    local function RefreshTP() if ns.MPlusTeleport and ns.MPlusTeleport.ApplySettings then ns.MPlusTeleport:ApplySettings() end end

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Group Key List")
    AddRow(content, "Show Group Key List", "checkbox", "groupKeyListEnabled", dbUI, RefreshTP)
    AddRow(content, "Hide Background", "checkbox", "groupkeysHideBackground", dbUI, function() if ns.MPlusTeleport and ns.MPlusTeleport.ApplyGroupKeyAppearance then ns.MPlusTeleport:ApplyGroupKeyAppearance() end end)
    AddRow(content, "Hide Label Bar", "checkbox", "groupkeysHideTitleBar", dbUI, function() if ns.MPlusTeleport and ns.MPlusTeleport.ApplyGroupKeyAppearance then ns.MPlusTeleport:ApplyGroupKeyAppearance() end end)
    AddRow(content, "Enable !key / !keys / !score", "checkbox", "groupChatCommands", dbUI, nil)
    content.rowCount = content.rowCount + 0.2
    local cmdInfo = GUI:CreateInfoBox(content, "Responds to !key or !keys in party/raid/whisper with all group keystones.\n!score posts your own M+ rating.")
    cmdInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (cmdInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    local btnGroupPreview = GUI:CreateButton(content, "Toggle Mover & Preview", 180, 26, function()
        if ns.MPlusTeleport and ns.MPlusTeleport.ToggleGroupKeyListPreview then
            ns.MPlusTeleport.groupKeyPreview = not ns.MPlusTeleport.groupKeyPreview
            ns.MPlusTeleport:ToggleGroupKeyListPreview(ns.MPlusTeleport.groupKeyPreview)
        end
    end)
    btnGroupPreview:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    content.rowCount = content.rowCount + 1.2

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 3. World Marks
local function BuildWorldMarks(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "World Marks")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    local function RefreshMarks() if _G.GravityUI_RefreshWorldMarks then _G.GravityUI_RefreshWorldMarks() end end
    local dbMarks = dbUI.marks
    
    local infoBox = GUI:CreateInfoBox(content, "|cffFFCC00Note:|r Left-Click to set Raid Target. Shift-Click to set World Marker.\nPulltimer can be changed on the bar with Right-Click.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Marks Bar", "checkbox", "enabled", dbMarks, RefreshMarks)
    AddRow(content, "Enable Ready Check & Pull Bar", "checkbox", "showTimerBar", dbMarks, RefreshMarks)
    AddRow(content, "Show on Mouseover Only", "checkbox", "mouseover", dbMarks, RefreshMarks)
    AddRow(content, "Button Size", "slider", 10, 60, "size", dbMarks, RefreshMarks, 1)
    AddRow(content, "Spacing", "slider", 0, 20, "spacing", dbMarks, RefreshMarks, 1)
    AddRow(content, "X Offset", "slider", -1000, 1000, "offsetX", dbMarks, RefreshMarks, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "offsetY", dbMarks, RefreshMarks, 1)
    AddRow(content, "Hide Border", "checkbox", "hideBorder", dbMarks, RefreshMarks)
    AddRow(content, "Use Theme Color for Border", "checkbox", "useThemeColorBorder", dbMarks, RefreshMarks)
    AddRow(content, "Border Color", "color", "borderColor", dbMarks, RefreshMarks)
    
    local btnMover = GUI:CreateButton(content, "Toggle Mover", 120, 26, function() if ns.WorldMarks and ns.WorldMarks.ToggleMover then ns.WorldMarks:ToggleMover() end end)
    btnMover:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    content.rowCount = content.rowCount + 1.2
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 4. Mail
local function BuildMailExtras(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Mail")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    local function RefreshMail() if ns.Mail and ns.Mail.ApplySettings then ns.Mail.ApplySettings() end end
    local dbMail = dbUI.mail
    if not dbMail then dbMail = {}; dbUI.mail = dbMail end
    
    local infoBox = GUI:CreateInfoBox(content, "Improves the Mailbox with an Open All button, Address Book with Alts/Friends/Guild/Contacts, and gold tracking.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Mail Module", "checkbox", "enabled", dbMail, RefreshMail)
    AddRow(content, "Enable Open All Button", "checkbox", "openAll", dbMail, RefreshMail)
    AddRow(content, "Enable Address Book (Send Mail)", "checkbox", "addressBook", dbMail, RefreshMail)
    AddRow(content, "Track Gold in Chat", "checkbox", "trackGold", dbMail, RefreshMail)
    content.rowCount = content.rowCount + 0.5
    
    CreateSubLabel(content, "Contacts")
    local contactInfo = GUI:CreateInfoBox(content, "To manage contacts, open the Mailbox Send Mail tab, type a name in the 'To' field, click the Address Book dropdown and select 'Add Contact' or 'Remove Contact'.")
    contactInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (contactInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 5. Guildtools
local function BuildTools(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    if not dbUI.tools then dbUI.tools = { guildInviteRanks = {}, autoAssistNames = "", autoTankNames = "" } end
    local dbTools = dbUI.tools
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Group & Guild Tools")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    CreateSubLabel(content, "Guild Invite Tool")
    local guildInfo = GUI:CreateInfoBox(content, "Select the ranks to invite. Use |cffFFCC00/guiinv|r to automatically invite online members of these ranks.")
    guildInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (guildInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2

    if IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    local numRanks = (C_GuildInfo and C_GuildInfo.GetNumRanks and C_GuildInfo.GetNumRanks()) or (_G.GetNumGuildRanks and _G.GetNumGuildRanks()) or 10

    for i = 0, numRanks - 1 do
        local name = (C_GuildInfo and C_GuildInfo.GetRankName and C_GuildInfo.GetRankName(i + 1)) or (_G.GuildControlGetRankName and _G.GuildControlGetRankName(i + 1))
        if name and name ~= "" then
            AddRow(content, "   - Invite " .. name .. " (|cffAAAAAARank " .. i .. "|r)", "checkbox", i, dbTools.guildInviteRanks, nil)
        elseif not IsInGuild() then
            AddRow(content, "   - Invite Rank " .. i, "checkbox", i, dbTools.guildInviteRanks, nil)
        end
    end

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "Role Promotion")
    local roleInfo = GUI:CreateInfoBox(content, "Promotes players to Assistant automatically when they join your group/raid. (Requires Leader)")
    roleInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (roleInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    AddRow(content, "Auto Assist Names (comma separated)", "input", "autoAssistNames", dbTools, nil)
    local btnUpdateRoles = GUI:CreateButton(content, "Update Roles Now", 160, 26, function() if ns.UpdateGroupRoles then ns.UpdateGroupRoles() end end)
    btnUpdateRoles:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    content.rowCount = content.rowCount + 1.2

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 6. Interrupt Tracker
local function BuildInterruptTracker(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.screenindicators.interruptTracker then
         db.screenindicators.interruptTracker = { enabled = false, width = 200, height = 20, texture = "Gravity Normal", font = "Gravity", fontSize = 12, fontOutline = "OUTLINE", barColor = {0.129, 0.129, 0.129, 0.85}, textColor = {1, 1, 1, 1}, useClassColor = false, growDirection = "UP", x = 0, y = 0, sayKick = false, sayKickText = "Interrupted %t!" }
    end
    local c = db.screenindicators.interruptTracker
    content.rowCount = 0
    local function Refresh()
        if ns.InterruptTracker and ns.InterruptTracker.ApplySettings then ns.InterruptTracker.ApplySettings() end
        C_Timer.After(0.05, function() if ns.GUI and ns.GUI.RefreshAll then ns.GUI:RefreshAll() end end)
    end
    local header = GUI:CreateSectionHeader(content, "Interrupt Tracker")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    AddRow(content, "Enable Tracker", "checkbox", "enabled", c, Refresh)
    local testBtn = GUI:CreateButton(content, "Toggle Test Mode", 140, 24, function() if ns.InterruptTracker.TestMode then ns.InterruptTracker.TestMode() end end)
    testBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 120, 24, function() if ns.InterruptTracker.ToggleMover then ns.InterruptTracker.ToggleMover() end end)
    moverBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.2
    CreateSubLabel(content, "Dimensions & Layout")
    AddRow(content, "Width", "slider", 50, 400, "width", c, Refresh, 1)
    AddRow(content, "Bar Height", "slider", 10, 50, "height", c, Refresh, 1)
    AddRow(content, "Bar Spacing", "slider", 0, 20, "spacing", c, Refresh, 1)
    AddRow(content, "X Offset", "slider", -500, 500, "x", c, Refresh, 1)
    AddRow(content, "Y Offset", "slider", -500, 500, "y", c, Refresh, 1)
    local directions = {{value="UP", text="Grow Up"},{value="DOWN", text="Grow Down"}}
    AddRow(content, "Grow Direction", "dropdown", directions, "growDirection", c, Refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Appearance")
    local texOptions = {{value="Interface\\TargetingFrame\\UI-StatusBar", text="Blizzard"}}; local fontOptions = {{value="Fonts\\FRIZQT__.TTF", text="Friz Quadrata"}}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        fontOptions = {}; texOptions = {}
        for name, _ in pairs(LSM:HashTable("font")) do table.insert(fontOptions, {value=name, text=name}) end
        table.sort(fontOptions, function(a,b) return a.text < b.text end)
        for name, _ in pairs(LSM:HashTable("statusbar")) do table.insert(texOptions, {value=name, text=name}) end
        table.sort(texOptions, function(a,b) return a.text < b.text end)
    end
    AddRow(content, "Texture", "dropdown", texOptions, "texture", c, Refresh)
    AddRow(content, "Font", "dropdown", fontOptions, "font", c, Refresh)
    AddRow(content, "Font Size", "slider", 8, 32, "fontSize", c, Refresh, 1)
    local outlines = {{value="NONE", text="None"},{value="OUTLINE", text="Outline"},{value="THICKOUTLINE", text="Thick Outline"}}
    AddRow(content, "Font Outline", "dropdown", outlines, "fontOutline", c, Refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Colors")
    AddRow(content, "Use Class Colors for Bar", "checkbox", "useClassColor", c, Refresh)
    AddRow(content, "Use Theme Color for Bar", "checkbox", "useThemeBarColor", c, Refresh)
    AddRow(content, "Bar Color", "color", "barColor", c, Refresh)
    content.rowCount = content.rowCount + 0.2
    AddRow(content, "Use Class Colors for Text", "checkbox", "useClassColorText", c, Refresh)
    AddRow(content, "Use Theme Color for Text", "checkbox", "useThemeFontColor", c, Refresh)
    AddRow(content, "Text Color", "color", "textColor", c, Refresh)
    content.rowCount = content.rowCount + 0.2
    AddRow(content, "Use different Color for Cooldown", "checkbox", "useSpecificCooldownColor", c, Refresh)
    if c.useSpecificCooldownColor then AddRow(content, "Cooldown Text Color", "color", "cooldownTextColor", c, Refresh) end
    AddRow(content, "Use Ready Text", "checkbox", "showReadyText", c, Refresh)
    content.rowCount = content.rowCount + 0.3
    CreateSubLabel(content, "Backdrop Color")
    AddRow(content, "Use Class Colors for Background", "checkbox", "useClassColorBackdrop", c, Refresh)
    AddRow(content, "Use Theme Bar Background", "checkbox", "useThemeBackdropColor", c, Refresh)
    AddRow(content, "Bar Background Color", "color", "backdropColor", c, Refresh)
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 7. Targeted Spells
local function BuildTargetedSpells(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.screenindicators then db.screenindicators = {} end
    if not db.screenindicators.targetedSpells then
        db.screenindicators.targetedSpells = {}
    end
    local c = db.screenindicators.targetedSpells

    -- Ensure defaults exist on live profile
    if c.enabled == nil then c.enabled = false end
    if c.showBars == nil then c.showBars = true end
    if c.showIcons == nil then c.showIcons = false end
    if c.showSelf == nil then c.showSelf = true end
    if c.showParty == nil then c.showParty = true end
    if c.onlyKickable == nil then c.onlyKickable = false end

    if c.width == nil then c.width = 200 end
    if c.height == nil then c.height = 20 end
    if c.spacing == nil then c.spacing = 4 end
    if c.maxBars == nil then c.maxBars = 5 end
    if c.growDirection == nil then c.growDirection = "UP" end
    if c.texture == nil then c.texture = "Gravity Normal" end
    if c.font == nil then c.font = "Gravity" end
    if c.fontSize == nil then c.fontSize = 12 end
    if c.fontOutline == nil then c.fontOutline = "OUTLINE" end

    if c.iconSize == nil then c.iconSize = 36 end
    if c.iconSpacing == nil then c.iconSpacing = 4 end
    if c.iconMax == nil then c.iconMax = 5 end
    if c.iconGrowDirection == nil then c.iconGrowDirection = "RIGHT" end
    if c.iconFont == nil then c.iconFont = "Gravity" end
    if c.iconFontSize == nil then c.iconFontSize = 13 end
    if c.iconFontOutline == nil then c.iconFontOutline = "OUTLINE" end
    if c.iconShowTargetName == nil then c.iconShowTargetName = true end
    if c.iconShowSweep == nil then c.iconShowSweep = true end

    if c.castingColor == nil then c.castingColor = { 1.00, 0.82, 0.00, 0.90 } end
    if c.channelingColor == nil then c.channelingColor = { 0.60, 0.25, 0.95, 0.90 } end
    if c.shieldColor == nil then c.shieldColor = { 0.50, 0.50, 0.50, 0.90 } end
    if c.backdropColor == nil then c.backdropColor = { 0.08, 0.08, 0.08, 0.85 } end
    if c.textColor == nil then c.textColor = { 1, 1, 1, 1 } end
    if c.targetClassColor == nil then c.targetClassColor = true end

    c.soundEnabled = false
    if c.soundFile == nil then c.soundFile = "Targeted" end
    if c.soundChannel == nil then c.soundChannel = "Master" end

    if c.x == nil then c.x = 0 end
    if c.y == nil then c.y = -140 end
    if c.iconX == nil then c.iconX = 0 end
    if c.iconY == nil then c.iconY = -80 end

    content.rowCount = 0

    local function Refresh()
        if ns.TargetedSpells and ns.TargetedSpells.ApplySettings then ns.TargetedSpells.ApplySettings() end
        C_Timer.After(0.05, function() if ns.GUI and ns.GUI.RefreshAll then ns.GUI:RefreshAll() end end)
    end

    local header = GUI:CreateSectionHeader(content, "Targeted Spells")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    AddRow(content, "Enable Targeted Spells", "checkbox", "enabled", c, Refresh)
    content.rowCount = content.rowCount + 0.2
    AddRow(content, "Enable Bar Display", "checkbox", "showBars", c, Refresh)
    AddRow(content, "Enable Icon Display", "checkbox", "showIcons", c, Refresh)
    content.rowCount = content.rowCount + 0.3

    -- Action Buttons (Test Mode & Movers)
    local testBtn = GUI:CreateButton(content, "Toggle Test Mode", 130, 24, function()
        if ns.TargetedSpells and ns.TargetedSpells.TestMode then ns.TargetedSpells.TestMode() end
    end)
    testBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))

    local barMoverBtn = GUI:CreateButton(content, "Bar Mover", 100, 24, function()
        if ns.TargetedSpells and ns.TargetedSpells.ToggleBarMover then ns.TargetedSpells.ToggleBarMover() end
    end)
    barMoverBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)

    local iconMoverBtn = GUI:CreateButton(content, "Icon Mover", 100, 24, function()
        if ns.TargetedSpells and ns.TargetedSpells.ToggleIconMover then ns.TargetedSpells.ToggleIconMover() end
    end)
    iconMoverBtn:SetPoint("LEFT", barMoverBtn, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.2

    CreateSubLabel(content, "Filters & Triggers")
    AddRow(content, "Show Spells Targeting You", "checkbox", "showSelf", c, Refresh)
    AddRow(content, "Show Spells Targeting Party", "checkbox", "showParty", c, Refresh)
    AddRow(content, "Only Show Kickable Spells", "checkbox", "onlyKickable", c, Refresh)
    content.rowCount = content.rowCount + 0.3

    -- ICON MODE SETTINGS
    CreateSubLabel(content, "Icon Mode Settings")
    AddRow(content, "Only Show Icons Targeted on You", "checkbox", "iconOnlySelf", c, Refresh)
    AddRow(content, "Icon Size", "slider", 20, 80, "iconSize", c, Refresh, 1)
    AddRow(content, "Icon Spacing", "slider", 0, 20, "iconSpacing", c, Refresh, 1)
    AddRow(content, "Max Icons", "slider", 1, 10, "iconMax", c, Refresh, 1)
    local iconDirections = {
        { value = "CENTER", text = "Centered (Horizontal)" },
        { value = "RIGHT",  text = "Grow Right" },
        { value = "LEFT",   text = "Grow Left" },
        { value = "UP",     text = "Grow Up" },
        { value = "DOWN",   text = "Grow Down" },
    }
    AddRow(content, "Icon Grow Direction", "dropdown", iconDirections, "iconGrowDirection", c, Refresh)
    AddRow(content, "Show Target Name under Icon", "checkbox", "iconShowTargetName", c, Refresh)
    AddRow(content, "Show Cooldown Sweep", "checkbox", "iconShowSweep", c, Refresh)
    AddRow(content, "Icon Font Size", "slider", 8, 24, "iconFontSize", c, Refresh, 1)
    content.rowCount = content.rowCount + 0.3

    -- BAR MODE SETTINGS
    CreateSubLabel(content, "Bar Mode Settings")
    AddRow(content, "Bar Width", "slider", 50, 400, "width", c, Refresh, 1)
    AddRow(content, "Bar Height", "slider", 10, 50, "height", c, Refresh, 1)
    AddRow(content, "Bar Spacing", "slider", 0, 20, "spacing", c, Refresh, 1)
    AddRow(content, "Max Bars", "slider", 1, 10, "maxBars", c, Refresh, 1)
    local barDirections = { { value = "UP", text = "Grow Up" }, { value = "DOWN", text = "Grow Down" } }
    AddRow(content, "Grow Direction", "dropdown", barDirections, "growDirection", c, Refresh)

    local texOptions = { { value = "Interface\\TargetingFrame\\UI-StatusBar", text = "Blizzard" } }
    local fontOptions = { { value = "Fonts\\FRIZQT__.TTF", text = "Friz Quadrata" } }
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        fontOptions = {}
        texOptions = {}
        for name, _ in pairs(LSM:HashTable("font")) do table.insert(fontOptions, { value = name, text = name }) end
        table.sort(fontOptions, function(a, b) return a.text < b.text end)
        for name, _ in pairs(LSM:HashTable("statusbar")) do table.insert(texOptions, { value = name, text = name }) end
        table.sort(texOptions, function(a, b) return a.text < b.text end)
    end
    AddRow(content, "Texture", "dropdown", texOptions, "texture", c, Refresh)
    AddRow(content, "Font", "dropdown", fontOptions, "font", c, Refresh)
    AddRow(content, "Font Size", "slider", 8, 32, "fontSize", c, Refresh, 1)
    local outlines = { { value = "NONE", text = "None" }, { value = "OUTLINE", text = "Outline" }, { value = "THICKOUTLINE", text = "Thick Outline" } }
    AddRow(content, "Font Outline", "dropdown", outlines, "fontOutline", c, Refresh)
    content.rowCount = content.rowCount + 0.3

    -- COLORS
    CreateSubLabel(content, "Colors")
    AddRow(content, "Casting Bar Color (Interruptible)", "color", "castingColor", c, Refresh)
    AddRow(content, "Channeling Bar Color", "color", "channelingColor", c, Refresh)
    AddRow(content, "Shielded / Non-Interruptible Color", "color", "shieldColor", c, Refresh)
    AddRow(content, "Bar Track Background Color", "color", "backdropColor", c, Refresh)
    AddRow(content, "Text Color", "color", "textColor", c, Refresh)
    content.rowCount = content.rowCount + 0.2
    AddRow(content, "Use Class Color for Target Name (» Name)", "checkbox", "targetClassColor", c, Refresh)
    content.rowCount = content.rowCount + 0.3

    -- AUDIO ALERT (Deactivated in WoW 12.0)
    CreateSubLabel(content, "Audio Alert |cffff4444(Deactivated)|r")
    
    local noteBox = GUI:CreateInfoBox(content, "|cffFFCC00Audio Alerts Deactivated|r\nAudio alerts for targeted enemy casts are currently deactivated until a reliable, secret-safe target resolution API is available in WoW 12.0.")
    content.rowCount = content.rowCount + 1.8

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- PAGE REGISTRATION
--==============================================================================================================================================================================================
ns.GUI:RegisterPage("features", {
    title = "Features",
    subTabs = {
        { name = "Dragonriding",      builder = BuildDragonriding },
        { name = "M+ Teleport",       builder = BuildTeleport },
        { name = "World Marks",       builder = BuildWorldMarks },
        { name = "Mail",              builder = BuildMailExtras },
        { name = "Guildtools",        builder = BuildTools },
        { name = "Interrupt Tracker", builder = BuildInterruptTracker },
        { name = "Targeted Spells",   builder = BuildTargetedSpells },
    },
    OnBuild = function(content)
        local scrollFrame = content:GetParent()
        content:Hide()
        if scrollFrame.ScrollBar then scrollFrame.ScrollBar:Hide(); scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end) end
        local opts = GUI.pages["features"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["features"]
        if not opts.subTabsContainer then return end
        subIndex = subIndex or 1
        for _, cf in pairs(opts.subTabsContainer.tabContents) do cf:Hide() end
        if opts.subTabsContainer.tabContents[subIndex] then opts.subTabsContainer.tabContents[subIndex]:Show() end
    end
})
