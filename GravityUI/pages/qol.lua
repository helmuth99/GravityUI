-- GravityUI - Quality of Life Page
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

local function CreateSubLabel(parent, text)
     local row = parent.rowCount or 0
     local y = -10 - (row * (ROW_HEIGHT+5))
     
     local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
     label:SetPoint("TOPLEFT", 10, y)
     label:SetText(text)
     label:SetTextColor(unpack(C.accent))
     
     parent.rowCount = row + 1.0
end

--==============================================================================================================================================================================================
-- BUILDERS
--==============================================================================================================================================================================================

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
    content.rowCount = 1.3

    AddRow(content, "Auto Insert M+ Keys", "checkbox", "autoInsertKey", dbUI, nil)
    AddRow(content, "Auto Combat Log in M+", "checkbox", "autoCombatLog", dbUI, nil)
    AddRow(content, "Auto Log Raid (Normal)", "checkbox", "autoCombatLogRaidNormal", dbUI, nil)
    AddRow(content, "Auto Log Raid (Heroic)", "checkbox", "autoCombatLogRaidHeroic", dbUI, nil)
    AddRow(content, "Auto Log Raid (Mythic)", "checkbox", "autoCombatLogRaidMythic", dbUI, nil)
    AddRow(content, "Sell Gray Items", "checkbox", "sellJunk", dbUI, nil)
    
    local repairOptions = {{value="off", text="Off"}, {value="personal", text="Personal Gold"}, {value="guild", text="Guild Bank First"}}
    AddRow(content, "Auto Repair", "dropdown", repairOptions, "autoRepair", dbUI, nil)
    
    AddRow(content, "Auto Accept Role Check (Group)", "checkbox", "autoRoleAccept", dbUI, nil)
    AddRow(content, "LFG Queue on double click", "checkbox", "lfgQuickJoin", dbUI, nil)
    
    -- Per-character LFG role selections (flat keys in ns.db.char to avoid AceDB nested-table bug)
    local dbChar = ns.db and ns.db.char
    if dbChar then
        -- Determine which roles are available for this class
        local _, classFilename = UnitClass("player")
        local canTank = classFilename == "WARRIOR" or classFilename == "PALADIN" or classFilename == "DRUID"
                     or classFilename == "DEATHKNIGHT" or classFilename == "MONK" or classFilename == "DEMONHUNTER"
        local canHeal = classFilename == "PALADIN" or classFilename == "PRIEST" or classFilename == "SHAMAN"
                     or classFilename == "DRUID" or classFilename == "MONK" or classFilename == "EVOKER"
        
        content.rowCount = content.rowCount + 0.3
        local roleInfo = GUI:CreateInfoBox(content, "|cffFFCC00LFG Roles (per Character):|r Select which roles to auto-apply when double-clicking a group. Icons also appear in the LFG window (top right).")
        roleInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
        content.rowCount = content.rowCount + (roleInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
        
        -- Flat keys in char scope: persists correctly across reloads
        AddRow(content, "   - DPS",    "checkbox", "lfgRole_dps",    dbChar, nil)
        if canHeal then
            AddRow(content, "   - Healer", "checkbox", "lfgRole_healer", dbChar, nil)
        end
        if canTank then
            AddRow(content, "   - Tank",   "checkbox", "lfgRole_tank",   dbChar, nil)
        end
    end
    
    local inviteOptions = {{value="off", text="Off"}, {value="all", text="All Invites"}, {value="friends", text="Friends Only"}, {value="guild", text="Guild Only"}, {value="both", text="Friends & Guild"}}
    AddRow(content, "Auto Accept Invites", "dropdown", inviteOptions, "autoAcceptInvites", dbUI, nil)
    
    content.rowCount = content.rowCount + 0.2
    AddRow(content, "Invite on Whisper", "checkbox", "inviteOnWhisper", dbUI, nil)
    AddRow(content, "   - Invite All", "checkbox", "inviteOnWhisperAll", dbUI, nil)
    AddRow(content, "   - Only Friends / BNet", "checkbox", "inviteOnWhisperFriends", dbUI, nil)
    AddRow(content, "   - Only Guild Members", "checkbox", "inviteOnWhisperGuild", dbUI, nil)
    AddRow(content, "   - Keywords (comma separated)", "input", "inviteOnWhisperKeywords", dbUI, nil)
    
    content.rowCount = content.rowCount + 0.2
    local whisperInfo = GUI:CreateInfoBox(content, "Auto invite players who whisper a keyword. Filter Priority: Invite All > Friends/Guild.")
    whisperInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (whisperInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Auto Accept Quests", "checkbox", "autoAcceptQuest", dbUI, nil)
    AddRow(content, "Auto Turn-In Quests", "checkbox", "autoTurnInQuest", dbUI, nil)
    AddRow(content, "Shift Pauses Accept & Turn-In", "checkbox", "questHoldShift", dbUI, nil)
    
    content.rowCount = content.rowCount + 0.5
    local usefulHeader = GUI:CreateSectionHeader(content, "Useful Stuff")
    usefulHeader:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    usefulHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + 1.0
    
    AddRow(content, "Faster Auto Loot", "checkbox", "fastAutoLoot", dbUI, function(enabled) if enabled then SetCVar("autoLootDefault", "1") end end)
    content.rowCount = content.rowCount + 0.2
    local lootInfo = GUI:CreateInfoBox(content, "Faster Auto Loot instantly loots all items and enables WoW's Auto Loot setting.")
    lootInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (lootInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Delete Fix", "checkbox", "deleteFix", dbUI, function(enabled) if ns.ToggleDeleteFix then ns.ToggleDeleteFix(enabled) end end)
    content.rowCount = content.rowCount + 0.2
    local delInfo = GUI:CreateInfoBox(content, "Allows destroying Good/Superior items without typing DELETE.")
    delInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (delInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Death Release Protection", "checkbox", "deathReleaseProtection", dbUI, nil)
    content.rowCount = content.rowCount + 0.2
    local deathInfo = GUI:CreateInfoBox(content, "Forces you to hold ALT for 1 second before 'Release Spirit' can be clicked.")
    deathInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (deathInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Faster Movie Skip", "checkbox", "fasterMovieSkip", dbUI, nil)
    content.rowCount = content.rowCount + 0.2
    local movieInfo = GUI:CreateInfoBox(content, "Use ESC, SPACE, or ENTER to skip cancel Cinematic/Movie dialogs instantly.")
    movieInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (movieInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Auto Skip Cinematics", "checkbox", "autoSkipCinematics", dbUI, nil)
    content.rowCount = content.rowCount + 0.2
    local cinInfo = GUI:CreateInfoBox(content, "Automatically skips in-game cinematics and movies without any key press. All cutscene types (real cinematics, in-game scenes, and movies) are cancelled automatically.")
    cinInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (cinInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2

    
    AddRow(content, "Auto-Select Single Gossip Option", "checkbox", "autoSelectGossip", dbUI, nil)
    AddRow(content, "Auto Check EditMode on Spec Switch", "checkbox", "checkEditmodeOnSpecSwitch", dbUI, nil)
    AddRow(content, "AH: Filter Current Expansion", "checkbox", "ahCurrentExpansionFilter", dbUI, nil)
    content.rowCount = content.rowCount + 0.2
    local ahInfo = GUI:CreateInfoBox(content, "Automatically sets the filter to the current expansion when opening the auction house.")
    ahInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (ahInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Show Widget Power Value (Prey)", "checkbox", "showWidgetPowerValue", dbUI, function(enabled) if ns.UpdateWidgetPowerValueVisibility then ns.UpdateWidgetPowerValueVisibility(enabled) end end)

    
    -- Quick Salvage moved here? Original logic was inside Automation section. Yes.
    content.rowCount = content.rowCount + 0.5
    AddRow(content, "Enable Quick Salvage", "checkbox", "enabled", dbUI.quickSalvage, nil)
    local modOptions = {{value="ALT", text="Alt"}, {value="ALTSHIFT", text="Alt + Shift"}, {value="ALTCTRL", text="Alt + Ctrl"}}
    AddRow(content, "Quick Salvage Modifier", "dropdown", modOptions, "modifier", dbUI.quickSalvage, nil)
    content.rowCount = content.rowCount + 0.2
    local qsInfo = GUI:CreateInfoBox(content, "Hold the modifier and hover over items in your bags to Mill, Prospect, or Disenchant instantly.")
    qsInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (qsInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2

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
    
    local header = GUI:CreateSectionHeader(content, "Autohide")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    -- Ensure subtable
    if not dbUI.hideObjectiveTrackerInstanceTypes then
        dbUI.hideObjectiveTrackerInstanceTypes = {mythicPlus=false, mythicDungeon=false, normalDungeon=false, heroicDungeon=false, followerDungeon=false, raid=false, pvp=false, arena=false}
    end

    CreateSubLabel(content, "Objective Tracker")
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

    CreateSubLabel(content, "Frames & Buttons")
    AddRow(content, "Hide Compact Raid Frame Manager", "checkbox", "hideRaidFrameManager", dbUI, RefreshAutohide)
    AddRow(content, "Hide Buff Frame Collapse Button", "checkbox", "hideBuffCollapseButton", dbUI, RefreshAutohide)
    AddRow(content, "Hide Talking Head Frame", "checkbox", "hideTalkingHead", dbUI, RefreshAutohide)
    AddRow(content, "Mute Talking Head Voice", "checkbox", "muteTalkingHead", dbUI, RefreshAutohide)
    AddRow(content, "Hide World Map Blackout", "checkbox", "hideWorldMapBlackout", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Nameplates")
    AddRow(content, "Hide Friendly Player Nameplates", "checkbox", "hideFriendlyPlayerNameplates", dbUI, RefreshAutohide)
    AddRow(content, "Hide Friendly NPC Nameplates", "checkbox", "hideFriendlyNPCNameplates", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "Combat & Messages")
    AddRow(content, "Hide Error Messages (Red Text)", "checkbox", "hideErrorMessages", dbUI, RefreshAutohide)
    AddRow(content, "Suppress HelpTip Popups", "checkbox", "suppressHelpTips", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.2
    local helpTipInfo = GUI:CreateInfoBox(content, "Hides Blizzard's yellow tutorial popup bubbles (e.g. 'Focus on a quest by clicking its icon'). Existing tips are dismissed immediately; new ones are suppressed automatically.")
    helpTipInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (helpTipInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    content.rowCount = content.rowCount + 0.5

    CreateSubLabel(content, "World Quest Minigames/Petbattles")
    AddRow(content, "Hide Interface on Minigame/Petbattle", "checkbox", "hideOnWorldQuestMinigame", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

--==============================================================================================================================================================================================
-- PAGE REGISTRATION
--==============================================================================================================================================================================================
ns.GUI:RegisterPage("qol", {
    title = "Quality of Life",
    subTabs = {
        { name = "Automation / Stuff", builder = BuildAutomation },
        { name = "Autohide",           builder = BuildAutohide },
    },
    OnBuild = function(content)
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        local opts = GUI.pages["qol"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["qol"]
        if not opts.subTabsContainer then return end
        
        subIndex = subIndex or 1
        for _, cf in pairs(opts.subTabsContainer.tabContents) do cf:Hide() end
        if opts.subTabsContainer.tabContents[subIndex] then
            opts.subTabsContainer.tabContents[subIndex]:Show()
        end
    end
})
