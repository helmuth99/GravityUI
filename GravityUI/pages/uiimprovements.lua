-- GravityUI - Quality of Life Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

-- ═══════════════════════════════════════════════════════════════
-- SHARED HELPERS
-- ═══════════════════════════════════════════════════════════════
local ROW_HEIGHT = 30
local LABEL_WIDTH = 220
local WIDGET_WIDTH = 250

local function CreatePropertyRow(parent, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
    
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then
        ns.GUI:SetFont(label, 12, "OUTLINE")
    else
        label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
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
    return row
end

local function AddRow(container, label, type, ...)
    local row = CreatePropertyRow(container, label, type, ...)
    local count = container.rowCount or 0
    row:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
    container.rowCount = count + 1
    return row
end

local function CreateSubHeader(parent, text)
     local row = parent.rowCount or 0
     local y = -10 - (row * (ROW_HEIGHT+5))
     
     local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
     label:SetPoint("TOPLEFT", 10, y)
     label:SetText(text)
     label:SetTextColor(unpack(C.accent))
     
     local line = parent:CreateTexture(nil, "ARTWORK")
     line:SetHeight(2)
     line:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
     line:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
     line:SetColorTexture(unpack(C.accent))
     
     parent.rowCount = row + 1.0
end

-- ═══════════════════════════════════════════════════════════════
-- BUILDERS
-- ═══════════════════════════════════════════════════════════════

-- 1. Automation
local function BuildAutomation(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Automation")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0

    AddRow(content, "Auto Insert M+ Keys", "checkbox", "autoInsertKey", dbUI, nil)
    AddRow(content, "Auto Combat Log in M+", "checkbox", "autoCombatLog", dbUI, nil)
    AddRow(content, "Auto Log Raid (Normal)", "checkbox", "autoCombatLogRaidNormal", dbUI, nil)
    AddRow(content, "Auto Log Raid (Heroic)", "checkbox", "autoCombatLogRaidHeroic", dbUI, nil)
    AddRow(content, "Auto Log Raid (Mythic)", "checkbox", "autoCombatLogRaidMythic", dbUI, nil)
    AddRow(content, "Sell Gray Items", "checkbox", "sellJunk", dbUI, nil)
    
    local repairOptions = {{value="off", text="Off"}, {value="personal", text="Personal Gold"}, {value="guild", text="Guild Bank First"}}
    AddRow(content, "Auto Repair", "dropdown", repairOptions, "autoRepair", dbUI, nil)
    
    AddRow(content, "Auto Accept Role Check", "checkbox", "autoRoleAccept", dbUI, nil)
    
    local inviteOptions = {{value="off", text="Off"}, {value="all", text="All Invites"}, {value="friends", text="Friends Only"}, {value="guild", text="Guild Only"}, {value="both", text="Friends & Guild"}}
    AddRow(content, "Auto Accept Invites", "dropdown", inviteOptions, "autoAcceptInvites", dbUI, nil)
    
    AddRow(content, "Auto Accept Quests", "checkbox", "autoAcceptQuest", dbUI, nil)
    AddRow(content, "Auto Turn-In Quests", "checkbox", "autoTurnInQuest", dbUI, nil)
    AddRow(content, "Shift Pauses Accept & Turn-In", "checkbox", "questHoldShift", dbUI, nil)
    
    AddRow(content, "Faster Auto Loot", "checkbox", "fastAutoLoot", dbUI, function(enabled) if enabled then SetCVar("autoLootDefault", "1") end end)
    local lootDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lootDesc:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    lootDesc:SetWidth(GUI.CONTENT_WIDTH - 40)
    lootDesc:SetJustifyH("LEFT")
    lootDesc:SetText("Note: Faster Auto Loot instantly loots all items and enables WoW's Auto Loot setting.")
    lootDesc:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 0.6
    
    AddRow(content, "Enable Delete Fix", "checkbox", "deleteFix", dbUI, function(enabled) if ns.ToggleDeleteFix then ns.ToggleDeleteFix(enabled) end end)
    local delDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    delDesc:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    delDesc:SetWidth(GUI.CONTENT_WIDTH - 40)
    delDesc:SetJustifyH("LEFT")
    delDesc:SetText("Note: Allows destroying Good/Superior items without typing DELETE.")
    delDesc:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 0.6
    
    AddRow(content, "Faster Movie Skip", "checkbox", "fasterMovieSkip", dbUI, nil)
    local movieDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    movieDesc:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    movieDesc:SetWidth(GUI.CONTENT_WIDTH - 40)
    movieDesc:SetJustifyH("LEFT")
    movieDesc:SetText("Note: Use ESC, SPACE, or ENTER to skip cancel Cinematic/Movie dialogs instantly.")
    movieDesc:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 0.6
    
    AddRow(content, "Auto-Select Single Gossip Option", "checkbox", "autoSelectGossip", dbUI, nil)
    
    -- Quick Salvage moved here? Original logic was inside Automation section. Yes.
    CreateSubHeader(content, "Quick Salvage")
    AddRow(content, "Enable Quick Salvage", "checkbox", "enabled", dbUI.quickSalvage, nil)
    local modOptions = {{value="ALT", text="Alt"}, {value="ALTSHIFT", text="Alt + Shift"}, {value="ALTCTRL", text="Alt + Ctrl"}}
    AddRow(content, "Quick Salvage Modifier", "dropdown", modOptions, "modifier", dbUI.quickSalvage, nil)
    local qsDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    qsDesc:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    qsDesc:SetWidth(GUI.CONTENT_WIDTH - 40)
    qsDesc:SetJustifyH("LEFT")
    qsDesc:SetText("Note: Hold the modifier and hover over items in your bags to Mill, Prospect, or Disenchant instantly.")
    qsDesc:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 0.8

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. Autohide
local function BuildAutohide(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0
    
    local function RefreshAutohide() if ns.ApplyAutohideSettings then ns.ApplyAutohideSettings() end end
    
    -- Ensure subtable
    if not dbUI.hideObjectiveTrackerInstanceTypes then
        dbUI.hideObjectiveTrackerInstanceTypes = {mythicPlus=false, mythicDungeon=false, normalDungeon=false, heroicDungeon=false, followerDungeon=false, raid=false, pvp=false, arena=false}
    end

    CreateSubHeader(content, "Objective Tracker")
    AddRow(content, "Hide Always", "checkbox", "hideObjectiveTrackerAlways", dbUI, RefreshAutohide)

    local instanceTypes = {
        {key="mythicPlus", label="Hide in Mythic+"}, {key="mythicDungeon", label="Hide in Mythic Dungeons"},
        {key="heroicDungeon", label="Hide in Heroic Dungeons"}, {key="normalDungeon", label="Hide in Normal Dungeons"},
        {key="followerDungeon", label="Hide in Follower Dungeons"}, {key="raid", label="Hide in Raids"},
        {key="pvp", label="Hide in Battlegrounds"}, {key="arena", label="Hide in Arenas"},
    }
    for _, it in ipairs(instanceTypes) do
        AddRow(content, "   - " .. it.label, "checkbox", it.key, dbUI.hideObjectiveTrackerInstanceTypes, RefreshAutohide)
    end
    content.rowCount = content.rowCount + 0.5 

    CreateSubHeader(content, "Frames & Buttons")
    AddRow(content, "Hide Compact Raid Frame Manager", "checkbox", "hideRaidFrameManager", dbUI, RefreshAutohide)
    AddRow(content, "Hide Buff Frame Collapse Button", "checkbox", "hideBuffCollapseButton", dbUI, RefreshAutohide)
    AddRow(content, "Hide Talking Head Frame", "checkbox", "hideTalkingHead", dbUI, RefreshAutohide)
    AddRow(content, "Mute Talking Head Voice", "checkbox", "muteTalkingHead", dbUI, RefreshAutohide)
    AddRow(content, "Hide World Map Blackout", "checkbox", "hideWorldMapBlackout", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Nameplates")
    AddRow(content, "Hide Friendly Player Nameplates", "checkbox", "hideFriendlyPlayerNameplates", dbUI, RefreshAutohide)
    AddRow(content, "Hide Friendly NPC Nameplates", "checkbox", "hideFriendlyNPCNameplates", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Status Bars")
    AddRow(content, "Hide Experience Bar (XP)", "checkbox", "hideXPBar", dbUI, RefreshAutohide)
    AddRow(content, "Hide Reputation Bar", "checkbox", "hideReputationBar", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Combat & Messages")
    AddRow(content, "Hide Error Messages (Red Text)", "checkbox", "hideErrorMessages", dbUI, RefreshAutohide)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 3. Combat
local function BuildCombat(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Combat")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0
    
    AddRow(content, "Show Damage Numbers", "checkbox", "showDamageNumbers", dbUI, function(enabled) SetCVar("floatingCombatTextCombatDamage", enabled and "1" or "0") end)
    AddRow(content, "Show Healing Numbers", "checkbox", "showHealingNumbers", dbUI, function(enabled) SetCVar("floatingCombatTextCombatHealing", enabled and "1" or "0") end)
    
    if dbUI.spellQueueWindow == nil then dbUI.spellQueueWindow = tonumber(GetCVar("SpellQueueWindow")) or 400 end
    AddRow(content, "Spell Queue Window (ms)", "slider", 0, 400, "spellQueueWindow", dbUI, function(val) SetCVar("SpellQueueWindow", tostring(val)) end, 10)
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 4. Buffs & Debuffs
local function BuildBuffs(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "World of Warcraft Buffs & Debuffs Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0
    
    local buffDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    buffDesc:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * ROW_HEIGHT))
    buffDesc:SetWidth(GUI.CONTENT_WIDTH - 40)
    buffDesc:SetJustifyH("LEFT")
    buffDesc:SetText("Modifies borders and font size of Blizzard default Buff and Debuff frames.")
    buffDesc:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 1.2

    if not dbUI.buffBorders then dbUI.buffBorders = {} end
    local dbBuffs = dbUI.buffBorders
    local function RefreshBuffs() if ns.BuffBorders and ns.BuffBorders.Refresh then ns.BuffBorders.Refresh() end end

    AddRow(content, "Enable Buff Borders", "checkbox", "enableBuffs", dbBuffs, RefreshBuffs)
    AddRow(content, "Enable Debuff Borders", "checkbox", "enableDebuffs", dbBuffs, RefreshBuffs)
    AddRow(content, "Border Size", "slider", 1, 5, "borderSize", dbBuffs, RefreshBuffs, 0.5)
    AddRow(content, "Font Size", "slider", 8, 24, "fontSize", dbBuffs, RefreshBuffs, 1)
    
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Hide Blizzard Default Frames")
    AddRow(content, "Hide Buffs", "checkbox", "hideBuffFrame", dbBuffs, RefreshBuffs)
    AddRow(content, "Hide Debuffs", "checkbox", "hideDebuffFrame", dbBuffs, RefreshBuffs)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 5. Chat
local function BuildChat(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local function RefreshChat() if ns.Chat and ns.Chat.Refresh then ns.Chat.Refresh() end end
    local dbChat = dbUI.chat or {}
    -- defaults
    if not dbChat.glass then dbChat.glass = {enabled=true, bgAlpha=0.25, bgColor={0,0,0,1}} end
    if not dbChat.timestamps then dbChat.timestamps = {enabled=true, format="24h", color={0.6,0.6,0.6,1}} end
    if not dbChat.urls then dbChat.urls = {enabled=true, color={0,0.75,1,1}} end
    if not dbChat.editBox then dbChat.editBox = {enabled=true, positionTop=false, bgAlpha=0.4, bgColor={0,0,0,1}} end
    if not dbChat.fade then dbChat.fade = {enabled=true, delay=15} end

    CreateSubHeader(content, "Chat Background")
    AddRow(content, "Chat Background Texture", "checkbox", "enabled", dbChat.glass, RefreshChat)
    AddRow(content, "Background Opacity", "slider", 0, 1, "bgAlpha", dbChat.glass, RefreshChat, 0.05)
    AddRow(content, "Background Color", "color", "bgColor", dbChat.glass, RefreshChat)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Input Box Background")
    AddRow(content, "Input Box Background Texture", "checkbox", "enabled", dbChat.editBox, RefreshChat)
    AddRow(content, "Background Opacity", "slider", 0, 1, "bgAlpha", dbChat.editBox, RefreshChat, 0.05)
    AddRow(content, "Background Color", "color", "bgColor", dbChat.editBox, RefreshChat)
    AddRow(content, "Position Input Box at Top", "checkbox", "positionTop", dbChat.editBox, RefreshChat)
    AddRow(content, "Width (0 = Auto)", "slider", 0, 1000, "width", dbChat.editBox, RefreshChat, 5)
    AddRow(content, "Height", "slider", 10, 100, "height", dbChat.editBox, RefreshChat, 1)
    AddRow(content, "X Offset", "slider", -100, 100, "offsetX", dbChat.editBox, RefreshChat, 1)
    AddRow(content, "Y Offset", "slider", -100, 100, "offsetY", dbChat.editBox, RefreshChat, 1)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Message Fade")
    AddRow(content, "Fade Messages After Inactivity", "checkbox", "enabled", dbChat.fade, RefreshChat)
    AddRow(content, "Fade Delay (seconds)", "slider", 5, 120, "delay", dbChat.fade, RefreshChat, 5)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "URL Detection")
    AddRow(content, "Make URLs Clickable", "checkbox", "enabled", dbChat.urls, RefreshChat)
    local noteUrl = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteUrl:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    noteUrl:SetWidth(GUI.CONTENT_WIDTH - 40)
    noteUrl:SetJustifyH("LEFT")
    noteUrl:SetText("Click any URL in chat to open a copy dialog.")
    noteUrl:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 0.8
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Copy Button")
    local copyOptions = {{value="always", text="Always Show"}, {value="hover", text="Show on Hover"}, {value="disabled", text="Disabled"}}
    AddRow(content, "Copy Button", "dropdown", copyOptions, "copyButtonMode", dbChat, RefreshChat)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Timestamps")
    AddRow(content, "Show Timestamps", "checkbox", "enabled", dbChat.timestamps, RefreshChat)
    local timeOptions = {{value="12h", text="12-Hour (03:27 PM)"}, {value="24h", text="24-Hour (15:27)"}}
    AddRow(content, "Format", "dropdown", timeOptions, "format", dbChat.timestamps, RefreshChat)
    AddRow(content, "Timestamp Color", "color", "color", dbChat.timestamps, RefreshChat)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "UI Cleanup")
    AddRow(content, "Hide Chat Buttons", "checkbox", "hideButtons", dbChat, RefreshChat)
    AddRow(content, "Auto Hide Chat Tabs", "checkbox", "hideTabs", dbChat, RefreshChat)
    AddRow(content, "Unclamp Chat (Allow off-screen)", "checkbox", "unclamp", dbChat, RefreshChat)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 6. Tooltip
local function BuildTooltip(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local function RefreshTooltip() if ns.Tooltip and ns.Tooltip.Refresh then ns.Tooltip.Refresh() end end
    local dbTT = dbUI.tooltip or {}
    if dbTT.enabled == nil then dbTT.enabled = true end
    if not dbTT.visibility then dbTT.visibility = {npcs="SHOW", abilities="SHOW", items="SHOW", frames="SHOW", cdm="SHOW", customTrackers="SHOW"} end

    CreateSubHeader(content, "General Tooltip Settings")
    AddRow(content, "Enable Tooltip Module", "checkbox", "enabled", dbTT, RefreshTooltip)
    AddRow(content, "Anchor to Cursor", "checkbox", "anchorToCursor", dbTT, RefreshTooltip)
    AddRow(content, "Class Color Names", "checkbox", "classColorName", dbTT, RefreshTooltip)
    AddRow(content, "Show IDs (Spells/Items)", "checkbox", "showIDs", dbTT, RefreshTooltip)
    AddRow(content, "Use Theme Color for IDs", "checkbox", "useThemeColorID", dbTT, RefreshTooltip)
    AddRow(content, "Custom ID Color", "color", "idColor", dbTT, RefreshTooltip)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Combat & Visibility")
    AddRow(content, "Hide in Combat", "checkbox", "hideInCombat", dbTT, RefreshTooltip)
    local modOptions = {{value="NONE", text="None"}, {value="SHIFT", text="Shift"}, {value="CTRL", text="Ctrl"}, {value="ALT", text="Alt"}}
    AddRow(content, "Combat Override Key", "dropdown", modOptions, "combatKey", dbTT, RefreshTooltip)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Context Visibility")
    local visOptions = {{value="SHOW", text="Always Show"}, {value="HIDE", text="Always Hide"}, {value="SHIFT", text="Show on Shift"}, {value="CTRL", text="Show on Ctrl"}, {value="ALT", text="Show on Alt"}}
    AddRow(content, "World Units (NPCs/Players)", "dropdown", visOptions, "npcs", dbTT.visibility, RefreshTooltip)
    AddRow(content, "Abilities (Action Bars)", "dropdown", visOptions, "abilities", dbTT.visibility, RefreshTooltip)
    AddRow(content, "Items (Bags/Bank)", "dropdown", visOptions, "items", dbTT.visibility, RefreshTooltip)
    AddRow(content, "Unit Frames", "dropdown", visOptions, "frames", dbTT.visibility, RefreshTooltip)
    AddRow(content, "CDM Icons", "dropdown", visOptions, "cdm", dbTT.visibility, RefreshTooltip)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Tooltip Styling")
    AddRow(content, "Enable Custom Square Style", "checkbox", "customStyle", dbTT, RefreshTooltip)
    AddRow(content, "Hide Health Bar", "checkbox", "hideHealthBar", dbTT, RefreshTooltip)
    AddRow(content, "Font Size", "slider", 8, 24, "fontSize", dbTT, RefreshTooltip, 1)
    AddRow(content, "Background Opacity", "slider", 0, 1, "bgAlpha", dbTT, RefreshTooltip, 0.05)
    AddRow(content, "Background Color", "color", "bgColor", dbTT, RefreshTooltip)
    AddRow(content, "Use Theme Color for Border", "checkbox", "useThemeColor", dbTT, RefreshTooltip)
    AddRow(content, "Custom Border Color", "color", "borderColor", dbTT, RefreshTooltip)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 7. Character Panel
local function BuildCharacter(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local function RefreshChar()
        if ns.Character and ns.Character.RefreshCharacterPane then ns.Character.RefreshCharacterPane() end
        if ns.Character and ns.Character.RefreshAllFonts then ns.Character.RefreshAllFonts() end
        if ns.Inspect and ns.Inspect.UpdateInspectFrame then ns.Inspect.UpdateInspectFrame() end
    end
    local dbChar = dbUI.character or {}
    if dbChar.enabled == nil then dbChar.enabled = true end

    CreateSubHeader(content, "Appearance")
    AddRow(content, "Enable Character Panel Styling", "checkbox", "enabled", dbChar, RefreshChar)
    AddRow(content, "Enable Inspect Panel Styling", "checkbox", "inspectEnabled", dbChar, function() if ns.Inspect and ns.Inspect.UpdateInspectFrame then ns.Inspect.UpdateInspectFrame() end end)
    AddRow(content, "Panel Scale", "slider", 0.75, 1.5, "panelScale", dbChar, function(val)
        if CharacterFrame then CharacterFrame:SetScale(1.30 * val) end
        if ns.Inspect and ns.Inspect.UpdateInspectFrame then ns.Inspect.UpdateInspectFrame() end
    end, 0.05)
    AddRow(content, "Background Color", "color", "panelBgColor", dbChar, function() if ns.Character and ns.Character.RefreshBackground then ns.Character.RefreshBackground() end end)
    AddRow(content, "Background Opacity", "slider", 0, 100, "panelOpacity", dbChar, function() if ns.Character and ns.Character.RefreshBackground then ns.Character.RefreshBackground() end end, 1)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Slot Overlays")
    AddRow(content, "Show Equipment Name", "checkbox", "showItemName", dbChar, RefreshChar)
    AddRow(content, "Show Item Level & Track", "checkbox", "showItemLevel", dbChar, RefreshChar)
    AddRow(content, "Show Enchant Status", "checkbox", "showEnchants", dbChar, RefreshChar)
    AddRow(content, "Show Gem Indicators", "checkbox", "showGems", dbChar, RefreshChar)
    AddRow(content, "Show Durability Bars", "checkbox", "showDurability", dbChar, RefreshChar)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Stats Panel")
    AddRow(content, "Show Stat Tooltips", "checkbox", "showTooltips", dbChar, RefreshChar)
    local statFormats = {{value="percent", text="Percentage (19.5%)"}, {value="rating", text="Rating (1234)"}, {value="both", text="Both"}}
    AddRow(content, "Secondary Stat Format", "dropdown", statFormats, "secondaryStatFormat", dbChar, RefreshChar)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Text Sizes")
    AddRow(content, "Slot Text Size", "slider", 6, 24, "slotTextSize", dbChar, RefreshChar, 1)
    AddRow(content, "Header Text Size", "slider", 6, 24, "headerTextSize", dbChar, RefreshChar, 1)
    AddRow(content, "Stats Text Size", "slider", 6, 24, "statsTextSize", dbChar, RefreshChar, 1)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Text Colors")
    AddRow(content, "Stats Text Color", "color", "statsTextColor", dbChar, RefreshChar)
    AddRow(content, "Header Class Color", "checkbox", "headerClassColor", dbChar, RefreshChar)
    AddRow(content, "Custom Header Color", "color", "headerColor", dbChar, RefreshChar)
    AddRow(content, "Enchant Class Color", "checkbox", "enchantClassColor", dbChar, RefreshChar)
    AddRow(content, "Custom Enchant Color", "color", "enchantTextColor", dbChar, RefreshChar)
    AddRow(content, "No Enchant Color", "color", "noEnchantTextColor", dbChar, RefreshChar)
    AddRow(content, "Upgrade Track Color", "color", "upgradeTrackColor", dbChar, RefreshChar)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 8. Dragonriding (Skyriding)
local function BuildDragonriding(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    
    local function RefreshSkyriding() if ns.RefreshSkyriding then ns.RefreshSkyriding() end end
    
    local dbSky = db.skyriding
    if not dbSky then dbSky = {}; db.skyriding = dbSky end
    -- Initializer defaults (simplified for brevity, main logic in skyriding.lua)
    if dbSky.enabled == nil then dbSky.enabled = true end

    CreateSubHeader(content, "Enable")
    AddRow(content, "Enable Vigor Bar", "checkbox", "enabled", dbSky, RefreshSkyriding)
    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * ROW_HEIGHT))
    desc:SetWidth(GUI.CONTENT_WIDTH - 40)
    desc:SetJustifyH("LEFT")
    desc:SetText("Displays vigor charges, recharge progress, and speed while skyriding.")
    desc:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 0.8
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Visibility")
    local visOptions = {{value="ALWAYS", text="Always Visible"}, {value="FLYING_ONLY", text="Only When Flying"}, {value="AUTO", text="Auto (fade)"}}
    AddRow(content, "Visibility Mode", "dropdown", visOptions, "visibility", dbSky, RefreshSkyriding)
    AddRow(content, "Fade Delay (sec)", "slider", 0, 10, "fadeDelay", dbSky, RefreshSkyriding, 0.5)
    AddRow(content, "Fade Speed (sec)", "slider", 0.1, 1.0, "fadeDuration", dbSky, RefreshSkyriding, 0.1)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Bar Size")
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

    CreateSubHeader(content, "Position")
    AddRow(content, "Lock Position", "checkbox", "locked", dbSky, RefreshSkyriding)
    AddRow(content, "X Offset", "slider", -1000, 1000, "offsetX", dbSky, RefreshSkyriding, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "offsetY", dbSky, RefreshSkyriding, 1)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Colors & Style")
    AddRow(content, "Use Theme Color for Vigor", "checkbox", "useThemeColorVigor", dbSky, RefreshSkyriding)
    AddRow(content, "Vigor Fill Color", "color", "barColor", dbSky, RefreshSkyriding)
    AddRow(content, "Use Theme Color for Second Wind", "checkbox", "useThemeColorSecondWind", dbSky, RefreshSkyriding)
    AddRow(content, "Second Wind Color", "color", "secondWindColor", dbSky, RefreshSkyriding)
    AddRow(content, "Background Color", "color", "backgroundColor", dbSky, RefreshSkyriding)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Text Display")
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

-- 9. Combat Timer
local function BuildCombatTimer(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Combat Timer")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0

    local function RefreshCT() if _G.GravityUI_RefreshCombatTimer then _G.GravityUI_RefreshCombatTimer() end end
    local dbCT = dbUI.combatTimer
    
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

    local previewBtn = GUI:CreateButton(content, "Toggle Preview", 120, 26, function()
        if _G.GravityUI_ToggleCombatTimerPreview then
            local isPreview = _G.GravityUI_IsCombatTimerPreviewMode and _G.GravityUI_IsCombatTimerPreviewMode()
            _G.GravityUI_ToggleCombatTimerPreview(not isPreview)
        end
    end)
    previewBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    content.rowCount = content.rowCount + 1.2

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 10. M+ Teleport
local function BuildTeleport(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "M+ Teleport")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0

    AddRow(content, "Enable M+ Teleports", "checkbox", "mplusTeleportEnabled", dbUI, nil)
    
    local tpDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tpDesc:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    tpDesc:SetWidth(GUI.CONTENT_WIDTH - 40)
    tpDesc:SetJustifyH("LEFT")
    tpDesc:SetText("Note: Allows you to click dungeon icons in the Mythic+ Challenges frame to cast teleport spells.")
    tpDesc:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 1.2
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 11. World Marks
local function BuildWorldMarks(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "World Marks Bar")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 2.0
    
    local function RefreshMarks() if _G.GravityUI_RefreshWorldMarks then _G.GravityUI_RefreshWorldMarks() end end
    local dbMarks = dbUI.marks
    
    AddRow(content, "Enable Marks Bar", "checkbox", "enabled", dbMarks, RefreshMarks)
    AddRow(content, "Show on Mouseover Only", "checkbox", "mouseover", dbMarks, RefreshMarks)
    AddRow(content, "Button Size", "slider", 10, 60, "size", dbMarks, RefreshMarks, 1)
    AddRow(content, "Spacing", "slider", 0, 20, "spacing", dbMarks, RefreshMarks, 1)
    AddRow(content, "X Offset", "slider", -1000, 1000, "offsetX", dbMarks, RefreshMarks, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "offsetY", dbMarks, RefreshMarks, 1)
    AddRow(content, "Hide Border", "checkbox", "hideBorder", dbMarks, RefreshMarks)
    AddRow(content, "Use Theme Color for Border", "checkbox", "useThemeColorBorder", dbMarks, RefreshMarks)
    AddRow(content, "Border Color", "color", "borderColor", dbMarks, RefreshMarks)
    
    local marksDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    marksDesc:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    marksDesc:SetWidth(GUI.CONTENT_WIDTH - 40)
    marksDesc:SetJustifyH("LEFT")
    marksDesc:SetText("Note: Left-Click to set Raid Target. Shift-Click to set World Marker.")
    marksDesc:SetTextColor(unpack(C.textMuted))
    content.rowCount = content.rowCount + 1.2
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN PAGE
-- ═══════════════════════════════════════════════════════════════
ns.GUI:RegisterPage("uiimprovements", {
    title = "UI Improvements",
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
            { name = "Automation", builder = BuildAutomation },
            { name = "Autohide", builder = BuildAutohide },
            { name = "Combat", builder = BuildCombat },
            { name = "Buffs & Debuffs", builder = BuildBuffs },
            { name = "Chat", builder = BuildChat },
            { name = "Tooltip", builder = BuildTooltip },
            { name = "Character Panel", builder = BuildCharacter },
            { name = "Dragonriding", builder = BuildDragonriding },
            { name = "Combat Timer", builder = BuildCombatTimer },
            { name = "M+ Teleport", builder = BuildTeleport },
            { name = "World Marks", builder = BuildWorldMarks },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
