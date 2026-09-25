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

    content.rowCount = content.rowCount + 0.5
    CreateSubLabel(content, "LFG Teleport Reminder")
    local lfgInfo = GUI:CreateInfoBox(content, "Shows a popup with a one-click teleport button when you join a dungeon group via the Group Finder.")
    lfgInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (lfgInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    AddRow(content, "Show LFG Teleport Reminder", "checkbox", "lfgTeleportReminder", dbUI, function() if ns.LFGTeleport and ns.LFGTeleport.ApplySettings then ns.LFGTeleport.ApplySettings() end end)

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

-- 8. Death Announcer
local function BuildDeathAnnouncer(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.deathAnnouncer then
        db.deathAnnouncer = {
            enabled = true,
            inDungeon = true,
            inRaid = true,
            inGroup = true,
            useClassColor = true,
            messageFormat = "%s died!",
            fontSize = 24,
            font = "Gravity",
            fontOutline = "OUTLINE",
            textColor = { 1, 1, 1, 1 },
            duration = 3.0,
            x = 0,
            y = 140,
            soundEnabled = false,
            soundFile = "Warning",
            soundChannel = "Master",
            chatAnnouncement = "DISABLED",
        }
    end
    local c = db.deathAnnouncer
    content.rowCount = 0

    local function Refresh()
        if ns.DeathAnnouncer and ns.DeathAnnouncer.ApplySettings then ns.DeathAnnouncer.ApplySettings() end
        C_Timer.After(0.05, function() if ns.GUI and ns.GUI.RefreshAll then ns.GUI:RefreshAll() end end)
    end

    local header = GUI:CreateSectionHeader(content, "Death Announcer")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local infoBox = GUI:CreateInfoBox(content, "Displays an on-screen alert whenever a group or raid member dies with class colors.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.2

    AddRow(content, "Enable Death Announcer", "checkbox", "enabled", c, Refresh)
    content.rowCount = content.rowCount + 0.3

    -- Action Buttons (Test Mode & Mover)
    local testBtn = GUI:CreateButton(content, "Toggle Test Mode", 140, 24, function()
        if ns.DeathAnnouncer and ns.DeathAnnouncer.TestMode then ns.DeathAnnouncer.TestMode() end
    end)
    testBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))

    local moverBtn = GUI:CreateButton(content, "Toggle Mover", 120, 24, function()
        if ns.DeathAnnouncer and ns.DeathAnnouncer.ToggleMover then ns.DeathAnnouncer.ToggleMover() end
    end)
    moverBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.2

    -- TRIGGERS & INSTANCES
    CreateSubLabel(content, "Instance & Group Triggers")
    AddRow(content, "In Dungeons", "checkbox", "inDungeon", c, Refresh)
    AddRow(content, "In Raid", "checkbox", "inRaid", c, Refresh)
    AddRow(content, "Always in a Group / Raid", "checkbox", "inGroup", c, Refresh)
    content.rowCount = content.rowCount + 0.3

    -- DISPLAY SETTINGS
    CreateSubLabel(content, "Display & Typography")
    local fontOptions = { { value = "Fonts\\FRIZQT__.TTF", text = "Friz Quadrata" } }
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        fontOptions = {}
        for name, _ in pairs(LSM:HashTable("font")) do table.insert(fontOptions, { value = name, text = name }) end
        table.sort(fontOptions, function(a, b) return a.text < b.text end)
    end
    AddRow(content, "Font", "dropdown", fontOptions, "font", c, Refresh)
    AddRow(content, "Font Size", "slider", 12, 48, "fontSize", c, Refresh, 1)
    local outlines = { { value = "NONE", text = "None" }, { value = "OUTLINE", text = "Outline" }, { value = "THICKOUTLINE", text = "Thick Outline" } }
    AddRow(content, "Font Outline", "dropdown", outlines, "fontOutline", c, Refresh)
    AddRow(content, "Text Color", "color", "textColor", c, Refresh)
    AddRow(content, "Use Class Color for Player Name", "checkbox", "useClassColor", c, Refresh)
    AddRow(content, "Display Duration (sec)", "slider", 1, 10, "duration", c, Refresh, 0.5)
    content.rowCount = content.rowCount + 0.3

    -- AUDIO ALERT
    CreateSubLabel(content, "Audio Alert")
    AddRow(content, "Enable Sound Alert", "checkbox", "soundEnabled", c, Refresh)
    
    local function PlayPreviewSound(soundName)
        soundName = soundName or (c and c.soundFile)
        if not soundName or soundName == "None" or soundName == "" then return end
        local lsm = LibStub("LibSharedMedia-3.0", true)
        local soundPath = lsm and lsm:Fetch("sound", soundName)
        local channel = (c and c.soundChannel) or "Master"
        if soundPath then
            PlaySoundFile(soundPath, channel)
        else
            PlaySound(SOUNDKIT.RAID_WARNING or 8959, channel)
        end
    end

    local soundOptions = { { value = "Warning", text = "Warning", previewFunc = PlayPreviewSound } }
    if LSM then
        soundOptions = {}
        for name, _ in pairs(LSM:HashTable("sound")) do
            table.insert(soundOptions, { value = name, text = name, previewFunc = PlayPreviewSound })
        end
        table.sort(soundOptions, function(a, b) return a.text < b.text end)
    end
    AddRow(content, "Sound Alert", "dropdown", soundOptions, "soundFile", c, Refresh)
    local channels = { { value = "Master", text = "Master" }, { value = "SFX", text = "SFX" }, { value = "Ambience", text = "Ambience" }, { value = "Dialog", text = "Dialog" } }
    AddRow(content, "Sound Channel", "dropdown", channels, "soundChannel", c, Refresh)
    content.rowCount = content.rowCount + 0.3

    -- CHAT ANNOUNCEMENT
    CreateSubLabel(content, "Chat Announcement (Optional)")
    local chatOptions = {
        { value = "DISABLED", text = "Disabled" },
        { value = "SELF",     text = "Self Only (Chat Frame)" },
        { value = "PARTY",    text = "Party Chat" },
        { value = "RAID",     text = "Raid Chat" },
        { value = "AUTO",     text = "Auto (Party / Raid)" },
    }
    AddRow(content, "Chat Output", "dropdown", chatOptions, "chatAnnouncement", c, Refresh)
    content.rowCount = content.rowCount + 0.3

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end
ns._BuildDeathAnnouncer = BuildDeathAnnouncer -- exposed for indicators page

-- 9. Gravity Alt Manager
local function BuildAltManager(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.altManager then
        db.altManager = {
            enabled = true,
            openOnRightClick = true,
            showVault = true,
            showPrey = true,
            showDelves = true,
            showMPlus = true,
            showRaids = true,
            showCurrencies = true,
            onlyMaxLevel = false,
            showZeroRated = true,
            sortOrder = "lastPlayed",
            customOrder = {},
            visibleColumns = 5,
            announceParty = true,
        }
    end
    local c = db.altManager
    content.rowCount = 0

    local function refreshDashboard()
        if ns.AltManager and ns.AltManager.UI and ns.AltManager.UI.Refresh then
            ns.AltManager.UI:Refresh()
        end
    end

    local header = GUI:CreateSectionHeader(content, "Gravity Alt Manager")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local infoBox = GUI:CreateInfoBox(content, "Account-wide dashboard tracking Mythic+ Keystones, Great Vault status, Raid lockouts, and Currencies across all your characters. Open with /guialt or via Right-Click on the GravityUI minimap icon.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.2

    CreateSubLabel(content, "General")
    AddRow(content, "Enable Alt Manager", "checkbox", "enabled", c, refreshDashboard)
    AddRow(content, "Open with Right-Click on Minimap Icon", "checkbox", "openOnRightClick", c, refreshDashboard)
    AddRow(content, "Auto Announce on Keystone Loot", "checkbox", "announceParty", c, refreshDashboard)
    content.rowCount = content.rowCount + 0.33

    local RebuildCharList

    local function onFilterChange()
        refreshDashboard()
        if RebuildCharList then RebuildCharList() end
    end

    CreateSubLabel(content, "Display & Filter")
    AddRow(content, "Show Great Vault Status", "checkbox", "showVault", c, refreshDashboard)
    AddRow(content, "Show Prey Hunts", "checkbox", "showPrey", c, refreshDashboard)
    AddRow(content, "Show Delves (Bounty Map)", "checkbox", "showDelves", c, refreshDashboard)
    AddRow(content, "Show Mythic+ Dungeons", "checkbox", "showMPlus", c, refreshDashboard)
    AddRow(content, "Show Raid Lockouts", "checkbox", "showRaids", c, refreshDashboard)
    AddRow(content, "Show Currencies (Crests/Valor)", "checkbox", "showCurrencies", c, refreshDashboard)

    -- Per-currency filter: compact icon grid with checkmarks
    if c.showCurrencies ~= false then
        if not c.hiddenCurrencies then c.hiddenCurrencies = {} end
        local currIDs = ns.AltManager and ns.AltManager.Data and ns.AltManager.Data.GetTrackedCurrencyIDs and ns.AltManager.Data:GetTrackedCurrencyIDs() or {}

        local ITEM_W, ITEM_H = 170, 24
        local COLS = 2
        local PAD_X, PAD_Y = 8, 4
        local count = content.rowCount or 0
        local gridY = -10 - (count * (ROW_HEIGHT + 5)) - 4

        local col, row = 0, 0
        for _, currID in ipairs(currIDs) do
            local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currID)
            if info and info.name and info.name ~= "" then
                local btn = CreateFrame("Button", nil, content)
                btn:SetSize(ITEM_W, ITEM_H)
                btn:SetPoint("TOPLEFT", 20 + col * (ITEM_W + PAD_X), gridY - row * (ITEM_H + PAD_Y))

                -- Icon
                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:SetSize(18, 18)
                icon:SetPoint("LEFT", 0, 0)
                icon:SetTexture(info.iconFileID or 134400)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                -- Name
                local name = btn:CreateFontString(nil, "OVERLAY")
                if ns.GUI.SetFont then ns.GUI:SetFont(name, 11, "") end
                name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                name:SetPoint("RIGHT", btn, "RIGHT", -22, 0)
                name:SetJustifyH("LEFT")
                name:SetWordWrap(false)
                name:SetText(info.name)

                -- Checkmark
                local check = btn:CreateTexture(nil, "OVERLAY")
                check:SetSize(14, 14)
                check:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
                check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")

                local isHidden = c.hiddenCurrencies[currID]
                if isHidden then
                    name:SetTextColor(0.4, 0.4, 0.4, 1)
                    icon:SetDesaturated(true)
                    icon:SetAlpha(0.4)
                    check:Hide()
                else
                    name:SetTextColor(0.9, 0.9, 0.9, 1)
                    icon:SetDesaturated(false)
                    icon:SetAlpha(1)
                    check:Show()
                end

                btn:SetScript("OnClick", function()
                    if c.hiddenCurrencies[currID] then
                        c.hiddenCurrencies[currID] = nil
                        name:SetTextColor(0.9, 0.9, 0.9, 1)
                        icon:SetDesaturated(false)
                        icon:SetAlpha(1)
                        check:Show()
                    else
                        c.hiddenCurrencies[currID] = true
                        name:SetTextColor(0.4, 0.4, 0.4, 1)
                        icon:SetDesaturated(true)
                        icon:SetAlpha(0.4)
                        check:Hide()
                    end
                    refreshDashboard()
                end)

                btn:SetScript("OnEnter", function(self)
                    if not c.hiddenCurrencies[currID] then
                        name:SetTextColor(1, 1, 1, 1)
                    end
                end)
                btn:SetScript("OnLeave", function(self)
                    if not c.hiddenCurrencies[currID] then
                        name:SetTextColor(0.9, 0.9, 0.9, 1)
                    end
                end)

                col = col + 1
                if col >= COLS then
                    col = 0
                    row = row + 1
                end
            end
        end
        -- Account for grid height in content layout
        local totalRows = row + (col > 0 and 1 or 0)
        content.rowCount = count + math.ceil(totalRows * (ITEM_H + PAD_Y) / (ROW_HEIGHT + 5)) + 0.3
    end

    AddRow(content, "Only Max Level Characters", "checkbox", "onlyMaxLevel", c, onFilterChange)
    AddRow(content, "Show 0-Rated Characters", "checkbox", "showZeroRated", c, onFilterChange)
    AddRow(content, "Visible Characters", "slider", 3, 8, "visibleColumns", c, refreshDashboard, 1)

    local sortOptions = {
        { value = "lastPlayed", text = "Last Played (Active First)" },
        { value = "custom",     text = "Custom Order" },
        { value = "ilvl",       text = "Equipped Item Level" },
        { value = "score",      text = "Mythic+ Rating" },
        { value = "name",       text = "Character Name" },
    }
    AddRow(content, "Character Sort Order", "dropdown", sortOptions, "sortOrder", c, onFilterChange)
    content.rowCount = content.rowCount + 0.3

    CreateSubLabel(content, "Actions")
    local btnRow = CreateFrame("Frame", nil, content)
    btnRow:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
    local bCount = content.rowCount or 0
    btnRow:SetPoint("TOPLEFT", 10, -10 - (bCount * (ROW_HEIGHT + 5)))
    content.rowCount = bCount + 1.2

    local btnOpen = GUI:CreateButton(btnRow, "Open Alt Manager", 160, 24, function()
        if ns.AltManager and ns.AltManager.UI and ns.AltManager.UI.ToggleWindow then
            ns.AltManager.UI:ToggleWindow()
        end
    end)
    btnOpen:SetPoint("LEFT", 0, 0)

    local btnAnnounce = GUI:CreateButton(btnRow, "Announce Keys", 140, 24, function()
        if ns.AltManager and ns.AltManager.Data and ns.AltManager.Data.AnnounceKeystones then
            ns.AltManager.Data:AnnounceKeystones()
        end
    end)
    btnAnnounce:SetPoint("LEFT", btnOpen, "RIGHT", 10, 0)

    local btnPurge = GUI:CreateButton(btnRow, "Reset All Alt Data", 150, 24, function()
        if ns.AltManager and ns.AltManager.Data and ns.AltManager.Data.PurgeAll then
            ns.AltManager.Data:PurgeAll()
            if RebuildCharList then RebuildCharList() end
            print("|cff00c0ffGravityUI|r: Alt Manager database reset.")
        end
    end)
    btnPurge:SetPoint("LEFT", btnAnnounce, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 0.3

    -- Character Management Section
    CreateSubLabel(content, "Tracked Characters (Reorder & Delete)")

    local charListContainer = CreateFrame("Frame", nil, content)
    local baseTopOffset = 10 + (content.rowCount * (ROW_HEIGHT + 5))
    charListContainer:SetPoint("TOPLEFT", 10, -baseTopOffset)
    charListContainer:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    charListContainer:SetHeight(50)

    local charCards = {}
    local emptyRowFrame = nil

    RebuildCharList = function()
        for _, card in ipairs(charCards) do
            card:Hide()
        end
        if emptyRowFrame then emptyRowFrame:Hide() end

        local altsList = (ns.AltManager and ns.AltManager.Data and ns.AltManager.Data.GetAllAltsList and ns.AltManager.Data:GetAllAltsList()) or {}
        local yOffset = 0

        if #altsList == 0 then
            if not emptyRowFrame then
                emptyRowFrame = CreateFrame("Frame", nil, charListContainer)
                emptyRowFrame:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
                local emptyTxt = emptyRowFrame:CreateFontString(nil, "OVERLAY")
                emptyTxt:SetPoint("LEFT", 10, 0)
                emptyTxt:SetFont((ns.Styling and ns.Styling.GetFontPath and ns.Styling:GetFontPath()) or "Fonts\\FRIZQT__.TTF", 11, "")
                emptyTxt:SetTextColor(0.6, 0.6, 0.6, 1)
                emptyTxt:SetText("No characters tracked yet. Log onto your characters to populate.")
                emptyRowFrame.txt = emptyTxt
            end
            emptyRowFrame:ClearAllPoints()
            emptyRowFrame:SetPoint("TOPLEFT", charListContainer, "TOPLEFT", 0, 0)
            emptyRowFrame:Show()
            yOffset = ROW_HEIGHT + 10
        else
            for idx, alt in ipairs(altsList) do
                local charCard = charCards[idx]
                if not charCard then
                    charCard = CreateFrame("Frame", nil, charListContainer, "BackdropTemplate")
                    charCard:SetSize(GUI.CONTENT_WIDTH - 20, 28)
                    charCard:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                    charCard:SetBackdropColor(0.08, 0.10, 0.14, 0.8)
                    charCard:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.8)

                    local icon = charCard:CreateTexture(nil, "ARTWORK")
                    icon:SetSize(18, 18)
                    icon:SetPoint("LEFT", charCard, "LEFT", 8, 0)
                    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    charCard.icon = icon

                    local nameTxt = charCard:CreateFontString(nil, "OVERLAY")
                    nameTxt:SetPoint("LEFT", icon, "RIGHT", 8, 0)
                    nameTxt:SetFont((ns.Styling and ns.Styling.GetFontPath and ns.Styling:GetFontPath()) or "Fonts\\FRIZQT__.TTF", 11, "")
                    charCard.nameTxt = nameTxt

                    local btnDel = GUI:CreateButton(charCard, "Remove", 75, 20)
                    btnDel:SetPoint("RIGHT", charCard, "RIGHT", -6, 0)
                    charCard.btnDel = btnDel

                    local btnDown = GUI:CreateButton(charCard, "v", 26, 20)
                    btnDown:SetPoint("RIGHT", btnDel, "LEFT", -6, 0)
                    charCard.btnDown = btnDown

                    local btnUp = GUI:CreateButton(charCard, "^", 26, 20)
                    btnUp:SetPoint("RIGHT", btnDown, "LEFT", -4, 0)
                    charCard.btnUp = btnUp

                    charCards[idx] = charCard
                end

                charCard:ClearAllPoints()
                charCard:SetPoint("TOPLEFT", charListContainer, "TOPLEFT", 0, -yOffset)
                charCard:Show()

                if alt.specIcon and alt.specIcon ~= 0 then
                    charCard.icon:SetTexture(alt.specIcon)
                else
                    local classFile = alt.class or "WARRIOR"
                    charCard.icon:SetTexture("Interface\\Icons\\ClassIcon_" .. classFile)
                end

                local classCol = RAID_CLASS_COLORS and RAID_CLASS_COLORS[alt.class] or { colorStr = "ffffffff" }
                charCard.nameTxt:SetText(string.format("|c%s%s|r  |cff888888(%s)|r  -  |cffa335ee%.1f iLvl|r  -  |cff00c0ff%d Rating|r",
                    classCol.colorStr or "ffffffff",
                    alt.name or "Unknown",
                    alt.realm or "",
                    alt.ilvlEquipped or 0,
                    alt.mythicplus and alt.mythicplus.rating or 0
                ))

                local altGuid = alt.guid
                charCard.btnDel:SetScript("OnClick", function()
                    if ns.AltManager and ns.AltManager.Data and ns.AltManager.Data.DeleteAlt then
                        ns.AltManager.Data:DeleteAlt(altGuid)
                        RebuildCharList()
                    end
                end)

                charCard.btnDown:SetScript("OnClick", function()
                    if ns.AltManager and ns.AltManager.Data and ns.AltManager.Data.MoveAltOrder then
                        ns.AltManager.Data:MoveAltOrder(altGuid, 1)
                        RebuildCharList()
                    end
                end)

                charCard.btnUp:SetScript("OnClick", function()
                    if ns.AltManager and ns.AltManager.Data and ns.AltManager.Data.MoveAltOrder then
                        ns.AltManager.Data:MoveAltOrder(altGuid, -1)
                        RebuildCharList()
                    end
                end)

                yOffset = yOffset + 34
            end
        end

        charListContainer:SetHeight(yOffset)
        content:SetHeight(baseTopOffset + yOffset + 40)
    end

    RebuildCharList()
end

-- 10. Frame Mover (BlizzMove / Shifter)
local function BuildFrameMover(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    if not db.frameMover then db.frameMover = { enabled = true, rememberPositions = true, positions = {} } end
    local fm = db.frameMover
    content.rowCount = 0

    local refresh = function()
        if ns.FrameMover and ns.FrameMover.Refresh then
            ns.FrameMover.Refresh()
        end
    end

    local header = GUI:CreateSectionHeader(content, "Frame Mover")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local infoBox = GUI:CreateInfoBox(content, "Allows you to freely drag and reposition all standard Blizzard panels (Character, Bank, Merchant, Quest, Spellbook, Talents, Collections, Housing, Delves, etc.) using your mouse.\n\n• |cff30d1ffLeft Click & Drag:|r Move frame by its title bar / header.\n• |cff30d1ffCtrl + Right Click:|r Reset frame position back to default.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.3

    CreateSubLabel(content, "General Settings")
    AddRow(content, "Enable Frame Mover",       "checkbox", "enabled",           fm, refresh)
    AddRow(content, "Remember Frame Positions",  "checkbox", "rememberPositions", fm, nil)
    content.rowCount = content.rowCount + 0.3

    CreateSubLabel(content, "Position Management")
    local btnResetAll = GUI:CreateButton(content, "Reset All Frame Positions", 220, 24, function()
        if ns.FrameMover and ns.FrameMover.ResetAllPositions then
            ns.FrameMover.ResetAllPositions()
        end
    end)
    btnResetAll:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT + 5)))
    content.rowCount = content.rowCount + 1.2

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- STUFF
--==============================================================================================================================================================================================
local function BuildEllesmereUI(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local yOffset = -10

    local header = GUI:CreateSectionHeader(content, "Stuff")
    header:SetPoint("TOPLEFT", 10, yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    local info = GUI:CreateInfoBox(content, "Additional tweaks and integrations. Changes require /reload to take effect.")
    info:SetPoint("TOPLEFT", 10, yOffset)
    info:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - (info:GetHeight() + 15)

    local db = ns.GetDB and ns.GetDB() or {}

    -- Default to true if not set
    if db.eabrLeftAlign == nil then db.eabrLeftAlign = true end

    local chk = GUI:CreateCheckbox(content, "AuraBuff Reminders: Left-Aligned (grow right)", "eabrLeftAlign", db, nil)
    chk:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 30

    local note = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetText("|cffAAAAAA(Requires /reload to toggle)|r")
    note:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 40

    -- CDM Center X toggle
    if db.cdmCenterX == nil then db.cdmCenterX = true end

    local cdmChk = GUI:CreateCheckbox(content, "EllesmereUI CDM Bar: Force Centered (X=0)", "cdmCenterX", db, nil)
    cdmChk:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 30

    local cdmNote = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cdmNote:SetText("|cffAAAAAA(Centers the Cooldown Manager bar horizontally. Disable to use EllesmereUI's default position. Requires /reload)|r")
    cdmNote:SetPoint("TOPLEFT", 15, yOffset)
    cdmNote:SetPoint("RIGHT", content, "RIGHT", -15, 0)
    yOffset = yOffset - 40

    -- Liquid Luster Bar
    local llHdr = GUI:CreateSectionHeader(content, "Liquid Luster Bar")
    llHdr:SetPoint("TOPLEFT", 10, yOffset)
    llHdr:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    local llInfo = GUI:CreateInfoBox(content, "Shows a progress bar when you use the Liquid Luster potion. Tracks the Lustrous Gleam buff (5 stacks, +420 Versa per stack every 6s).\n\n• Displays current Versatility value, stack count, and time remaining.\n• 6-second tick markers for visual pacing.\n• Drag to reposition. Uses your theme accent color.\n• Test: /lltest")
    llInfo:SetPoint("TOPLEFT", 10, yOffset)
    llInfo:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - (llInfo:GetHeight() + 12)

    local dbUI = db.uiimprovements or {}
    if not dbUI.liquidLuster then dbUI.liquidLuster = { enabled = false, width = 260, height = 20 } end
    local llDB = dbUI.liquidLuster
    local function RefreshLL() if ns.LiquidLuster and ns.LiquidLuster.ApplySettings then ns.LiquidLuster.ApplySettings() end end

    local llChk = GUI:CreateCheckbox(content, "Enable Liquid Luster Bar", "enabled", llDB, RefreshLL)
    llChk:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 32

    local llWidthLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(llWidthLabel, 12, "") end
    llWidthLabel:SetText("Bar Width")
    llWidthLabel:SetTextColor(unpack(GUI.Colors.text))
    llWidthLabel:SetPoint("TOPLEFT", 15, yOffset)

    local llWidthSlider = GUI:CreateSlider(content, "", 100, 500, "width", llDB, RefreshLL, 10)
    llWidthSlider:SetHeight(ROW_HEIGHT)
    llWidthSlider:SetWidth(220)
    llWidthSlider:SetPoint("LEFT", llWidthLabel, "RIGHT", 10, 0)
    llWidthSlider.editBox:ClearAllPoints()
    llWidthSlider.editBox:SetPoint("RIGHT", llWidthSlider, "RIGHT", 0, 0)
    llWidthSlider.slider:ClearAllPoints()
    llWidthSlider.slider:SetPoint("LEFT", llWidthSlider, "LEFT", 0, 0)
    llWidthSlider.slider:SetPoint("RIGHT", llWidthSlider.editBox, "LEFT", -10, 0)
    yOffset = yOffset - 32

    local llHeightLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(llHeightLabel, 12, "") end
    llHeightLabel:SetText("Bar Height")
    llHeightLabel:SetTextColor(unpack(GUI.Colors.text))
    llHeightLabel:SetPoint("TOPLEFT", 15, yOffset)

    local llHeightSlider = GUI:CreateSlider(content, "", 10, 40, "height", llDB, RefreshLL, 1)
    llHeightSlider:SetHeight(ROW_HEIGHT)
    llHeightSlider:SetWidth(220)
    llHeightSlider:SetPoint("LEFT", llHeightLabel, "RIGHT", 10, 0)
    llHeightSlider.editBox:ClearAllPoints()
    llHeightSlider.editBox:SetPoint("RIGHT", llHeightSlider, "RIGHT", 0, 0)
    llHeightSlider.slider:ClearAllPoints()
    llHeightSlider.slider:SetPoint("LEFT", llHeightSlider, "LEFT", 0, 0)
    llHeightSlider.slider:SetPoint("RIGHT", llHeightSlider.editBox, "LEFT", -10, 0)
    yOffset = yOffset - 32

    local LL_LABEL_X = 15
    local LL_WIDGET_X = 120  -- consistent left edge for all widgets

    -- Texture Dropdown
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local texOptions = {}
    if LSM then
        for name, _ in pairs(LSM:HashTable("statusbar")) do
            table.insert(texOptions, { value = name, text = name })
        end
        table.sort(texOptions, function(a, b) return a.text < b.text end)
    end

    local llTexLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(llTexLabel, 12, "") end
    llTexLabel:SetText("Bar Texture")
    llTexLabel:SetTextColor(unpack(GUI.Colors.text))
    llTexLabel:SetPoint("TOPLEFT", LL_LABEL_X, yOffset)

    local llTexDD = GUI:CreateDropdown(content, "", texOptions, "texture", llDB, RefreshLL)
    llTexDD:SetPoint("LEFT", llTexLabel, "RIGHT", 10, 0)
    llTexDD:SetWidth(220)
    if llTexDD.dropdown then
        llTexDD.dropdown:ClearAllPoints()
        llTexDD.dropdown:SetPoint("LEFT", llTexDD, "LEFT", 0, 0)
        llTexDD.dropdown:SetPoint("RIGHT", llTexDD, "RIGHT", 0, 0)
    end
    yOffset = yOffset - 34

    -- Font Dropdown
    local fontOptions = {}
    if LSM then
        for name, _ in pairs(LSM:HashTable("font")) do
            table.insert(fontOptions, { value = name, text = name })
        end
        table.sort(fontOptions, function(a, b) return a.text < b.text end)
    end
    table.insert(fontOptions, 1, { value = "", text = "(Use Global Font)" })

    local llFontLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(llFontLabel, 12, "") end
    llFontLabel:SetText("Font")
    llFontLabel:SetTextColor(unpack(GUI.Colors.text))
    llFontLabel:SetPoint("TOPLEFT", LL_LABEL_X, yOffset)

    local llFontDD = GUI:CreateDropdown(content, "", fontOptions, "font", llDB, RefreshLL)
    llFontDD:SetPoint("LEFT", llFontLabel, "RIGHT", 10, 0)
    llFontDD:SetWidth(220)
    if llFontDD.dropdown then
        llFontDD.dropdown:ClearAllPoints()
        llFontDD.dropdown:SetPoint("LEFT", llFontDD, "LEFT", 0, 0)
        llFontDD.dropdown:SetPoint("RIGHT", llFontDD, "RIGHT", 0, 0)
    end
    yOffset = yOffset - 34

    -- Use Theme Color toggle
    local llThemeChk = GUI:CreateCheckbox(content, "Use Theme Color", "useThemeColor", llDB, RefreshLL)
    llThemeChk:SetPoint("TOPLEFT", LL_LABEL_X, yOffset)
    yOffset = yOffset - 32

    -- Color Pickers Row 1: Bar Color + Background (only when theme color off)
    local llBarColorLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(llBarColorLabel, 12, "") end
    llBarColorLabel:SetText("Bar Color")
    llBarColorLabel:SetTextColor(unpack(GUI.Colors.text))
    llBarColorLabel:SetPoint("TOPLEFT", LL_LABEL_X, yOffset)

    local llBarColorPicker = GUI:CreateColorPicker(content, "", "barColor", llDB, RefreshLL)
    llBarColorPicker:SetPoint("LEFT", llBarColorLabel, "RIGHT", 10, 0)

    local llBgColorLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(llBgColorLabel, 12, "") end
    llBgColorLabel:SetText("Background")
    llBgColorLabel:SetTextColor(unpack(GUI.Colors.text))
    llBgColorLabel:SetPoint("TOPLEFT", 220, yOffset)

    local llBgColorPicker = GUI:CreateColorPicker(content, "", "bgColor", llDB, RefreshLL)
    llBgColorPicker:SetPoint("LEFT", llBgColorLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 28

    -- Color Picker Row 2: Max Stack Color (always visible)
    local llLastColorLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(llLastColorLabel, 12, "") end
    llLastColorLabel:SetText("Max Stack Color")
    llLastColorLabel:SetTextColor(unpack(GUI.Colors.text))
    llLastColorLabel:SetPoint("TOPLEFT", LL_LABEL_X, yOffset)

    local llLastColorPicker = GUI:CreateColorPicker(content, "", "lastStackColor", llDB, RefreshLL)
    llLastColorPicker:SetPoint("LEFT", llLastColorLabel, "RIGHT", 10, 0)
    yOffset = yOffset - 32

    -- Show/hide color pickers based on useThemeColor
    local function UpdateColorVisibility()
        local show = not llDB.useThemeColor
        llBarColorLabel:SetShown(show)
        llBarColorPicker:SetShown(show)
        llBgColorLabel:SetShown(show)
        llBgColorPicker:SetShown(show)
    end
    UpdateColorVisibility()

    -- Hook the theme checkbox switch to update visibility
    local themeSwitch = llThemeChk.switch
    if themeSwitch then
        local origMouseDown = themeSwitch:GetScript("OnMouseDown")
        themeSwitch:SetScript("OnMouseDown", function(self, ...)
            if origMouseDown then origMouseDown(self, ...) end
            UpdateColorVisibility()
        end)
    end

    local llTestBtn = GUI:CreateButton(content, "Test Bar", 100, 24, function()
        if ns.LiquidLuster and ns.LiquidLuster.TestBar then ns.LiquidLuster.TestBar() end
    end)
    llTestBtn:SetPoint("TOPLEFT", LL_LABEL_X, yOffset)
    yOffset = yOffset - 40

    -- Focus Castbar Sound Alert
    local focusHdr = GUI:CreateSectionHeader(content, "Focus Castbar Sound")
    focusHdr:SetPoint("TOPLEFT", 10, yOffset)
    focusHdr:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    local focusInfo = GUI:CreateInfoBox(content, "Plays a sound alert when your Focus target starts casting a spell.")
    focusInfo:SetPoint("TOPLEFT", 10, yOffset)
    focusInfo:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - (focusInfo:GetHeight() + 12)

    local dbUI = db.uiimprovements or {}
    if not dbUI.focusCastSound then dbUI.focusCastSound = { enabled = false, soundFile = "Focus", soundChannel = "Master" } end
    local fcs = dbUI.focusCastSound
    local function RefreshFCS() if ns.FocusCastSound and ns.FocusCastSound.ApplySettings then ns.FocusCastSound.ApplySettings() end end

    local fcsChk = GUI:CreateCheckbox(content, "Enable Focus Cast Sound", "enabled", fcs, RefreshFCS)
    fcsChk:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 32

    -- Sound dropdown with preview
    local function PlayPreviewFCS(soundName)
        soundName = soundName or fcs.soundFile
        if not soundName or soundName == "" then return end
        local lsm = LibStub("LibSharedMedia-3.0", true)
        local soundPath = lsm and lsm:Fetch("sound", soundName)
        if soundPath then PlaySoundFile(soundPath, fcs.soundChannel or "Master") end
    end

    local soundOptions = { { value = "Focus", text = "Focus", previewFunc = PlayPreviewFCS } }
    local LSM_local = LibStub("LibSharedMedia-3.0", true)
    if LSM_local then
        soundOptions = {}
        for name, _ in pairs(LSM_local:HashTable("sound")) do
            table.insert(soundOptions, { value = name, text = name, previewFunc = PlayPreviewFCS })
        end
        table.sort(soundOptions, function(a, b) return a.text < b.text end)
    end

    local soundLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(soundLabel, 12, "") end
    soundLabel:SetText("Sound File")
    soundLabel:SetTextColor(unpack(GUI.Colors.text))
    soundLabel:SetPoint("TOPLEFT", 15, yOffset)

    local soundDD = GUI:CreateDropdown(content, "", soundOptions, "soundFile", fcs, RefreshFCS)
    soundDD:SetPoint("LEFT", soundLabel, "RIGHT", 10, 0)
    soundDD:SetWidth(WIDGET_WIDTH)
    soundDD.dropdown:ClearAllPoints()
    soundDD.dropdown:SetPoint("LEFT", soundDD, "LEFT", 0, 0)
    soundDD.dropdown:SetPoint("RIGHT", soundDD, "RIGHT", 0, 0)
    yOffset = yOffset - 32

    local channelOptions = {
        { value = "Master", text = "Master" },
        { value = "SFX", text = "SFX" },
        { value = "Ambience", text = "Ambience" },
        { value = "Dialog", text = "Dialog" },
    }

    local chanLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(chanLabel, 12, "") end
    chanLabel:SetText("Sound Channel")
    chanLabel:SetTextColor(unpack(GUI.Colors.text))
    chanLabel:SetPoint("TOPLEFT", 15, yOffset)

    local chanDD = GUI:CreateDropdown(content, "", channelOptions, "soundChannel", fcs, RefreshFCS)
    chanDD:SetPoint("LEFT", chanLabel, "RIGHT", 10, 0)
    chanDD:SetWidth(WIDGET_WIDTH)
    chanDD.dropdown:ClearAllPoints()
    chanDD.dropdown:SetPoint("LEFT", chanDD, "LEFT", 0, 0)
    chanDD.dropdown:SetPoint("RIGHT", chanDD, "RIGHT", 0, 0)
    yOffset = yOffset - 32

    local testBtn = GUI:CreateButton(content, "Test Sound", 100, 24, function()
        if ns.FocusCastSound and ns.FocusCastSound.TestSound then ns.FocusCastSound.TestSound() end
    end)
    testBtn:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 35

    content:SetHeight(math.abs(yOffset) + 20)
end

--==============================================================================================================================================================================================
-- 10. PLAYER MARKS
--==============================================================================================================================================================================================
local _pmScroll, _pmContent  -- cached to avoid duplication on rebuild

local function BuildPlayerMarks(parent)
    -- On rebuild: clear old content instead of creating duplicate scroll frames
    if _pmContent then
        for _, child in ipairs({ _pmContent:GetChildren() }) do
            child:Hide(); child:SetParent(nil)
        end
        -- Clear font strings too
        for _, region in ipairs({ _pmContent:GetRegions() }) do
            region:Hide(); region:SetParent(nil)
        end
        _pmContent.rowCount = 0
    end

    if not _pmScroll then
        _pmScroll, _pmContent = GUI:CreateScrollableContent(parent)
        _pmScroll:SetAllPoints()
    end

    local content = _pmContent
    local PM = ns.PlayerMarks
    if not PM then return end
    local pdb = PM.GetDB()
    if not pdb then return end

    -- Mark dropdown options (shared between all dropdowns)
    local markOptions = {{ value = 0, text = "None" }}
    for i = 1, 8 do
        markOptions[#markOptions + 1] = {
            value = i,
            text = (PM.MARK_ICONS[i] or "") .. " " .. PM.MARK_NAMES[i],
        }
    end

    local header = GUI:CreateSectionHeader(content, "Player Marks")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local infoBox = GUI:CreateInfoBox(content, "Assign raid target icons to players. When a Ready Check starts, a 'Set Marks' button appears. Click it to apply all configured marks.\n\nRequires: Raid Leader or Assistant (Raid) / Party Leader (Dungeon).\n\nSlash Command: /gravitymarks")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT + 5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT + 5)) + 0.2

    AddRow(content, "Enable Player Marks", "checkbox", "enabled", pdb, function() end)
    content.rowCount = content.rowCount + 0.8

    -- ================================================================
    -- TRACK raidListStart for both columns
    -- ================================================================
    local raidListStart = content.rowCount

    -- ================================================================
    -- LEFT COLUMN: RAID / PARTY MARKS
    -- ================================================================
    local raidSection = GUI:CreateSectionHeader(content, "Raid — Player Marks")
    raidSection:SetPoint("TOPLEFT", 10, -raidListStart * (ROW_HEIGHT + 5))
    raidSection:SetPoint("RIGHT", content, "CENTER", -5, 0)

    local leftY = -(raidListStart + 1) * (ROW_HEIGHT + 5)
    local playerCount = 0

    local function AddPlayerRow(unit)
        local name = UnitName(unit)
        local _, cls = UnitClass(unit)
        -- TAINT FIX: UnitName/UnitClass can return secrets in M+/Raid
        if name and issecretvalue and issecretvalue(name) then name = nil end
        if cls and issecretvalue and issecretvalue(cls) then cls = nil end
        if not name or not cls then return end

        local row = CreateFrame("Frame", nil, content)
        row:SetSize(GUI.CONTENT_WIDTH / 2 - 35, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 10, leftY)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        if ns.GUI.SetFont then ns.GUI:SetFont(label, 11, "") end
        label:SetPoint("LEFT", 0, 0)
        label:SetWidth(120)
        label:SetJustifyH("LEFT")
        local color = RAID_CLASS_COLORS[cls]
        if color then
            label:SetText(string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, name))
        else
            label:SetText(name)
        end

        local playerWrapper = { selected = pdb.raid.players[name] or 0 }
        local dd = GUI:CreateDropdown(row, "", markOptions, "selected", playerWrapper, function(val)
            pdb.raid.players[name] = val
            if val == 0 then pdb.raid.players[name] = nil end
        end)
        dd:SetPoint("LEFT", label, "RIGHT", 5, 0)
        dd:SetWidth(130)
        dd.dropdown:ClearAllPoints()
        dd.dropdown:SetPoint("LEFT", dd, "LEFT", 0, 0)
        dd.dropdown:SetPoint("RIGHT", dd, "RIGHT", 0, 0)

        leftY = leftY - (ROW_HEIGHT + 2)
        playerCount = playerCount + 1
    end

    -- Clean up stale player marks (players no longer in raid)
    if IsInRaid() then
        local currentNames = {}
        for i = 1, GetNumGroupMembers() do
            local u = "raid" .. i
            if UnitExists(u) then
                local n = UnitName(u)
                -- TAINT FIX: UnitName can return a secret in M+/Raid
                if n and (not issecretvalue or not issecretvalue(n)) then currentNames[n] = true end
            end
        end
        for savedName, _ in pairs(pdb.raid.players) do
            if not currentNames[savedName] then
                pdb.raid.players[savedName] = nil
            end
        end
        -- Build rows
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitExists(unit) then
                AddPlayerRow(unit)
            end
        end
    end

    if playerCount == 0 then
        local noGroup = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        noGroup:SetPoint("TOPLEFT", 10, leftY)
        if IsInRaid() then
            noGroup:SetText("No other raid members found.")
        else
            noGroup:SetText("Join a raid to assign player marks.\nUse M+ Dungeon for party/dungeon marks.")
        end
        if ns.GUI.SetFont then ns.GUI:SetFont(noGroup, 11, "") end
        leftY = leftY - ROW_HEIGHT
        playerCount = 1
    end

    -- Refresh button
    local refreshBtn = GUI:CreateButton(content, "Refresh List", 100, 22, function()
        BuildPlayerMarks(parent)
    end)
    refreshBtn:SetPoint("TOPLEFT", 10, leftY - 5)

    -- Clear All Marks button (raid only — M+ role marks are persistent)
    local clearBtn = GUI:CreateButton(content, "Clear All Marks", 120, 22, function()
        -- 1. Clear saved assignments
        wipe(pdb.raid.players)
        wipe(pdb.raid.customTargets)

        -- 2. Remove actual in-game raid target icons from all group members
        if ns.PlayerMarks.CanSetMarks() then
            if IsInRaid() then
                for i = 1, GetNumGroupMembers() do
                    local u = "raid" .. i
                    if UnitExists(u) then
                        pcall(SetRaidTarget, u, 0)
                    end
                end
            else
                pcall(SetRaidTarget, "player", 0)
                for i = 1, GetNumSubgroupMembers() do
                    local u = "party" .. i
                    if UnitExists(u) then
                        pcall(SetRaidTarget, u, 0)
                    end
                end
            end
        end

        print("|cFF30D1FF[GravityUI]|r All player marks cleared (saved + in-game icons).")
        BuildPlayerMarks(parent)
    end)
    clearBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 8, 0)
    leftY = leftY - 35

    -- Custom Targets section
    leftY = leftY - 10
    local customHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customHeader:SetPoint("TOPLEFT", 10, leftY)
    customHeader:SetText("Custom Targets (Bosses/NPCs)")
    customHeader:SetTextColor(unpack(GUI.Colors.accent))
    if ns.GUI.SetFont then ns.GUI:SetFont(customHeader, 12, "") end
    leftY = leftY - (ROW_HEIGHT + 5)

    -- Custom target input row (all elements on same line)
    local customRow = CreateFrame("Frame", nil, content)
    customRow:SetSize(GUI.CONTENT_WIDTH / 2 - 25, 28)
    customRow:SetPoint("TOPLEFT", 10, leftY)

    -- Plain EditBox (no CreateInput wrapper to avoid label offset)
    local editBox = CreateFrame("EditBox", nil, customRow, "BackdropTemplate")
    editBox:SetSize(140, 24)
    editBox:SetPoint("LEFT", 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetTextInsets(8, 8, 0, 0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.15, 0.15, 0.15, 1)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local tempCustomDB = { mark = 1 }
    local customDD = GUI:CreateDropdown(customRow, "", markOptions, "mark", tempCustomDB, function() end)
    customDD:SetPoint("LEFT", editBox, "RIGHT", 5, 0)
    customDD:SetWidth(100)
    customDD.dropdown:ClearAllPoints()
    customDD.dropdown:SetPoint("LEFT", customDD, "LEFT", 0, 0)
    customDD.dropdown:SetPoint("RIGHT", customDD, "RIGHT", 0, 0)

    local addBtn = GUI:CreateButton(customRow, "+", 30, 24, function()
        local targetName = editBox:GetText() or ""
        if targetName == "" then return end
        table.insert(pdb.raid.customTargets, { name = targetName, mark = tempCustomDB.mark })
        editBox:SetText("")
        BuildPlayerMarks(parent)
    end)
    addBtn:SetPoint("LEFT", customDD, "RIGHT", 5, 0)

    leftY = leftY - (ROW_HEIGHT + 5)

    -- Show existing custom targets
    for idx, entry in ipairs(pdb.raid.customTargets) do
        local ctRow = CreateFrame("Frame", nil, content)
        ctRow:SetSize(GUI.CONTENT_WIDTH / 2 - 25, 24)
        ctRow:SetPoint("TOPLEFT", 10, leftY)

        local ctLabel = ctRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        if ns.GUI.SetFont then ns.GUI:SetFont(ctLabel, 11, "") end
        ctLabel:SetPoint("LEFT", 0, 0)
        local markIcon = PM.MARK_ICONS[entry.mark] or ""
        ctLabel:SetText(markIcon .. " " .. entry.name)

        local delBtn = GUI:CreateButton(ctRow, "X", 20, 20, function()
            table.remove(pdb.raid.customTargets, idx)
            BuildPlayerMarks(parent)
        end)
        delBtn:SetPoint("LEFT", ctLabel, "RIGHT", 10, 0)

        leftY = leftY - 28
    end

    -- ================================================================
    -- RIGHT COLUMN: M+ DUNGEON MARKS
    -- ================================================================
    local dungeonSection = GUI:CreateSectionHeader(content, "M+ Dungeon — Role Marks")
    dungeonSection:ClearAllPoints()
    dungeonSection:SetPoint("TOPLEFT", content, "TOP", 5, -raidListStart * (ROW_HEIGHT + 5))
    dungeonSection:SetPoint("RIGHT", content, "RIGHT", -10, 0)

    local rightY = -(raidListStart + 1) * (ROW_HEIGHT + 5)

    -- Tank dropdown
    local tankRow = CreateFrame("Frame", nil, content)
    tankRow:SetSize(GUI.CONTENT_WIDTH / 2 - 25, ROW_HEIGHT)
    tankRow:SetPoint("TOPLEFT", content, "TOP", 5, rightY)

    local tankLabel = tankRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(tankLabel, 12, "") end
    tankLabel:SetPoint("LEFT", 0, 0)
    tankLabel:SetWidth(80)
    tankLabel:SetJustifyH("LEFT")
    tankLabel:SetText("Tank")
    tankLabel:SetTextColor(unpack(GUI.Colors.text))

    local tankDD = GUI:CreateDropdown(tankRow, "", markOptions, "TANK", pdb.dungeon, function() end)
    tankDD:SetPoint("LEFT", tankLabel, "RIGHT", 10, 0)
    tankDD:SetWidth(150)
    tankDD.dropdown:ClearAllPoints()
    tankDD.dropdown:SetPoint("LEFT", tankDD, "LEFT", 0, 0)
    tankDD.dropdown:SetPoint("RIGHT", tankDD, "RIGHT", 0, 0)

    rightY = rightY - (ROW_HEIGHT + 5)

    -- Healer dropdown
    local healerRow = CreateFrame("Frame", nil, content)
    healerRow:SetSize(GUI.CONTENT_WIDTH / 2 - 25, ROW_HEIGHT)
    healerRow:SetPoint("TOPLEFT", content, "TOP", 5, rightY)

    local healerLabel = healerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(healerLabel, 12, "") end
    healerLabel:SetPoint("LEFT", 0, 0)
    healerLabel:SetWidth(80)
    healerLabel:SetJustifyH("LEFT")
    healerLabel:SetText("Healer")
    healerLabel:SetTextColor(unpack(GUI.Colors.text))

    local healerDD = GUI:CreateDropdown(healerRow, "", markOptions, "HEALER", pdb.dungeon, function() end)
    healerDD:SetPoint("LEFT", healerLabel, "RIGHT", 10, 0)
    healerDD:SetWidth(150)
    healerDD.dropdown:ClearAllPoints()
    healerDD.dropdown:SetPoint("LEFT", healerDD, "LEFT", 0, 0)
    healerDD.dropdown:SetPoint("RIGHT", healerDD, "RIGHT", 0, 0)

    rightY = rightY - (ROW_HEIGHT + 5) * 2

    -- Info text
    local dungeonInfo = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    dungeonInfo:SetPoint("TOPLEFT", content, "TOP", 5, rightY)
    dungeonInfo:SetPoint("RIGHT", content, "RIGHT", -15, 0)
    dungeonInfo:SetJustifyH("LEFT")
    dungeonInfo:SetText("Role-based marks are auto-assigned\nto the Tank and Healer in your M+ group.\n\nCustom Targets are only available in Raid.")
    if ns.GUI.SetFont then ns.GUI:SetFont(dungeonInfo, 10, "") end

    -- Test button at bottom
    local bottomY = math.min(leftY, rightY) - 20
    local testBtn = GUI:CreateButton(content, "Test 'Set Marks' Button", 170, 26, function()
        if not ns.PlayerMarks then return end
        -- Force-show without group check for testing
        local btn = ns.PlayerMarks._createButton and ns.PlayerMarks._createButton()
        if not btn then
            -- Fallback: just show via normal path
            ns.PlayerMarks.ShowMarkButton()
            return
        end
        if InCombatLockdown() then
            print("|cFF30D1FF[GravityUI]|r Cannot show in combat.")
            return
        end
        btn:SetAttribute("macrotext", "/run print('|cFF30D1FF[GravityUI]|r Player Marks test — would set marks here!')")
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        btn:SetAlpha(1)
        btn:Show()
    end)
    testBtn:SetPoint("TOPLEFT", 10, bottomY)

    content:SetHeight(math.abs(bottomY) + 50)
end

--==============================================================================================================================================================================================
-- 11. BONUS ROLL SECURITY
--==============================================================================================================================================================================================
local function BuildBonusRoll(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    if not dbUI.bonusRollConfirm then dbUI.bonusRollConfirm = { enabled = true, passPromptEnabled = true } end
    local brc = dbUI.bonusRollConfirm
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Bonus Roll Security")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local infoBox = GUI:CreateInfoBox(content, "Adds a safety confirmation dialog before using or passing on a Bonus Roll.\n\nThe confirmation shows your current |cffFFCC00Loot Specialization|r so you can double-check before spending your roll token.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2

    AddRow(content, "Enable Bonus Roll Security", "checkbox", "enabled", brc, nil)
    AddRow(content, "Enable Pass Prompt", "checkbox", "passPromptEnabled", brc, nil)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Test Mode")
    local testRollBtn = GUI:CreateButton(content, "Test Roll Confirm", 160, 26, function()
        if ns.BonusRollConfirm and ns.BonusRollConfirm.TestRollConfirm then
            ns.BonusRollConfirm.TestRollConfirm()
        end
    end)
    testRollBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))

    local testPassBtn = GUI:CreateButton(content, "Test Pass Confirm", 160, 26, function()
        if ns.BonusRollConfirm and ns.BonusRollConfirm.TestPassConfirm then
            ns.BonusRollConfirm.TestPassConfirm()
        end
    end)
    testPassBtn:SetPoint("LEFT", testRollBtn, "RIGHT", 10, 0)
    content.rowCount = content.rowCount + 1.5

    local noteInfo = GUI:CreateInfoBox(content, "|cffAAAAAA• Test Roll Confirm: Shows the roll confirmation popup with your current loot spec.\n• Test Pass Confirm: Shows the pass confirmation popup.\n\nThese test buttons only show the popup — no actual bonus roll is consumed.|r")
    noteInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (noteInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- PAGE REGISTRATION
--==============================================================================================================================================================================================
ns.GUI:RegisterPage("features", {
    title = "Features",
    subTabs = {
        { name = "Dragonriding",        builder = BuildDragonriding },
        { name = "M+ Teleport",         builder = BuildTeleport },
        { name = "World Marks",         builder = BuildWorldMarks },
        { name = "Mail",                builder = BuildMailExtras },
        { name = "Guildtools",          builder = BuildTools },
        { name = "Player Marks",        builder = BuildPlayerMarks },
        { name = "Interrupt Tracker",   builder = BuildInterruptTracker },
        { name = "Gravity Alt Manager", builder = BuildAltManager },
        { name = "Frame Mover",         builder = BuildFrameMover },
        { name = "Bonus Roll",          builder = BuildBonusRoll },
        { name = "Stuff",               builder = BuildEllesmereUI },
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

