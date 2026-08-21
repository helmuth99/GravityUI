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
-- SHARED COLUMN LAYOUT HELPERS
--==============================================================================================================================================================================================
local COL_W = 280
local COL_GAP = 15
local COL_PAD = 10

local function CreateTwoColumns(content)
    local leftCol = CreateFrame("Frame", nil, content)
    leftCol:SetPoint("TOPLEFT", COL_PAD, -10)
    leftCol:SetWidth(COL_W)
    leftCol.rowCount = 0

    local rightCol = CreateFrame("Frame", nil, content)
    rightCol:SetPoint("TOPLEFT", COL_PAD + COL_W + COL_GAP, -10)
    rightCol:SetWidth(COL_W)
    rightCol.rowCount = 0

    return leftCol, rightCol
end

local function ColAddRow(col, label, type, ...)
    local row = CreatePropertyRow(col, label, type, ...)
    local count = col.rowCount or 0
    row:SetPoint("TOPLEFT", 0, -(count * (ROW_HEIGHT + 5)))
    col.rowCount = count + 1
    return row
end

local function ColSubLabel(col, text)
    local row = col.rowCount or 0
    local y = -(row * (ROW_HEIGHT + 5))
    local label = col:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 0, y)
    label:SetText(text)
    label:SetTextColor(unpack(C.accent))
    col.rowCount = row + 1.0
end

local function ColInfoLine(col, text)
    local row = col.rowCount or 0
    local y = -(row * (ROW_HEIGHT + 5))
    local info = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if ns.GUI.SetFont then ns.GUI:SetFont(info, 10, "") end
    info:SetPoint("TOPLEFT", 4, y + 4)
    info:SetWidth(COL_W - 10)
    info:SetJustifyH("LEFT")
    info:SetText("|cff888888" .. text .. "|r")
    col.rowCount = row + 0.5
end

-- Stacked dropdown: label on one row, dropdown below it (fits column width)
local function ColDropdown(col, labelText, options, key, dbTable, callback)
    -- Label row
    local count = col.rowCount or 0
    local y = -(count * (ROW_HEIGHT + 5))
    local label = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(label, 12, "") end
    label:SetPoint("TOPLEFT", 0, y)
    label:SetText(labelText)
    label:SetTextColor(unpack(C.text))
    col.rowCount = count + 0.4

    -- Dropdown row
    local ddCount = col.rowCount
    local ddY = -(ddCount * (ROW_HEIGHT + 5))
    local widget = GUI:CreateDropdown(col, "", options, key, dbTable, callback)
    widget:SetPoint("TOPLEFT", 0, ddY)
    widget:SetWidth(COL_W - 10)
    widget.dropdown:ClearAllPoints()
    widget.dropdown:SetPoint("LEFT", widget, "LEFT", 0, 0)
    widget.dropdown:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
    col.rowCount = ddCount + 1.1

    if ns.GUI and ns.GUI.RegisterInSearchIndex then
        ns.GUI:RegisterInSearchIndex(labelText, widget)
    end
    return widget
end

-- Stacked input: label on one row, input field below it (fits column width)
local function ColInput(col, labelText, key, dbTable, callback)
    local count = col.rowCount or 0
    local y = -(count * (ROW_HEIGHT + 5))
    local label = col:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then ns.GUI:SetFont(label, 12, "") end
    label:SetPoint("TOPLEFT", 0, y)
    label:SetText(labelText)
    label:SetTextColor(unpack(C.text))
    col.rowCount = count + 0.4

    local inCount = col.rowCount
    local inY = -(inCount * (ROW_HEIGHT + 5))
    local widget = GUI:CreateInput(col, "", key, dbTable, callback)
    widget:SetPoint("TOPLEFT", 0, inY)
    widget:SetWidth(COL_W - 10)
    if widget.editBox then
        widget.editBox:ClearAllPoints()
        widget.editBox:SetPoint("LEFT", widget, "LEFT", 0, 0)
        widget.editBox:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
    end
    col.rowCount = inCount + 1.1

    if ns.GUI and ns.GUI.RegisterInSearchIndex then
        ns.GUI:RegisterInSearchIndex(labelText, widget)
    end
    return widget
end

local function FinishColumns(content, leftCol, rightCol)
    local leftH = leftCol.rowCount * (ROW_HEIGHT + 5)
    local rightH = rightCol.rowCount * (ROW_HEIGHT + 5)
    leftCol:SetHeight(leftH + 20)
    rightCol:SetHeight(rightH + 20)
    content:SetHeight(math.max(leftH, rightH) + 40)
end

--==============================================================================================================================================================================================
-- BUILDERS
--==============================================================================================================================================================================================

-- -- 1. QoL (2-column layout)
local function BuildQoL(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements

    local leftCol, rightCol = CreateTwoColumns(content)

    ---------------------------------------------------------------------------
    -- LEFT COLUMN: Useful Stuff (moved from Automation)
    ---------------------------------------------------------------------------
    ColSubLabel(leftCol, "Useful Stuff")

    ColAddRow(leftCol, "Faster Auto Loot", "checkbox", "fastAutoLoot", dbUI, function(enabled) if enabled then SetCVar("autoLootDefault", "1") end end)
    ColInfoLine(leftCol, "Instantly loots all items.")

    ColAddRow(leftCol, "Enable Delete Fix", "checkbox", "deleteFix", dbUI, function(enabled) if ns.ToggleDeleteFix then ns.ToggleDeleteFix(enabled) end end)
    ColInfoLine(leftCol, "Destroy items without typing DELETE.")

    ColAddRow(leftCol, "Death Release Protection", "checkbox", "deathReleaseProtection", dbUI, nil)
    ColInfoLine(leftCol, "Hold ALT 1s before Release Spirit.")

    ColAddRow(leftCol, "Faster Movie Skip", "checkbox", "fasterMovieSkip", dbUI, nil)
    ColInfoLine(leftCol, "ESC/SPACE/ENTER to skip movies.")

    ColAddRow(leftCol, "Auto Skip Cinematics", "checkbox", "autoSkipCinematics", dbUI, nil)
    ColInfoLine(leftCol, "Skips all cutscenes automatically.")

    ColAddRow(leftCol, "Auto-Select Gossip", "checkbox", "autoSelectGossip", dbUI, nil)
    ColInfoLine(leftCol, "Auto-pick single NPC dialog option.")

    ColAddRow(leftCol, "EditMode on Spec Switch", "checkbox", "checkEditmodeOnSpecSwitch", dbUI, nil)

    ColAddRow(leftCol, "AH: Current Expansion", "checkbox", "ahCurrentExpansionFilter", dbUI, nil)
    ColInfoLine(leftCol, "Auto-filter AH to current expansion.")

    ColAddRow(leftCol, "Widget Power (Prey)", "checkbox", "showWidgetPowerValue", dbUI, function(enabled) if ns.UpdateWidgetPowerValueVisibility then ns.UpdateWidgetPowerValueVisibility(enabled) end end)

    leftCol.rowCount = leftCol.rowCount + 0.5
    ColSubLabel(leftCol, "Quick Salvage")
    ColAddRow(leftCol, "Enable Quick Salvage", "checkbox", "enabled", dbUI.quickSalvage, nil)
    local modOptions = {{value="ALT", text="Alt"}, {value="ALTSHIFT", text="Alt + Shift"}, {value="ALTCTRL", text="Alt + Ctrl"}}
    ColDropdown(leftCol, "Modifier", modOptions, "modifier", dbUI.quickSalvage, nil)
    ColInfoLine(leftCol, "Hold modifier + hover to salvage.")

    ---------------------------------------------------------------------------
    -- RIGHT COLUMN: Original QoL items
    ---------------------------------------------------------------------------
    ColSubLabel(rightCol, "Containers & Loot")
    ColAddRow(rightCol, "Auto Open Containers", "checkbox", "autoOpenContainers", dbUI, nil)
    ColAddRow(rightCol, "   - Excl. Warbound", "checkbox", "autoOpenContainersExcludeWarbound", dbUI, nil)
    ColInfoLine(rightCol, "Auto-opens bags, caches, parcels.")

    rightCol.rowCount = rightCol.rowCount + 0.3
    ColSubLabel(rightCol, "Cosmetics & Buffs")
    ColAddRow(rightCol, "Hide Item Transforms", "checkbox", "hideTransforms", dbUI, nil)
    ColInfoLine(rightCol, "Cancels cosmetic transform buffs.")

    rightCol.rowCount = rightCol.rowCount + 0.3
    ColSubLabel(rightCol, "Collections & Trainers")
    ColAddRow(rightCol, "Auto Unwrap Collections", "checkbox", "autoUnwrapCollections", dbUI, nil)
    ColInfoLine(rightCol, "Skips fanfare animation for mounts/pets.")

    ColAddRow(rightCol, "Train All at Trainers", "checkbox", "trainAllButton", dbUI, nil)
    ColInfoLine(rightCol, "Adds 'Train All' button at trainers.")

    rightCol.rowCount = rightCol.rowCount + 0.3
    ColSubLabel(rightCol, "Instance & Party")
    ColAddRow(rightCol, "Announce Instance Reset", "checkbox", "instanceResetAnnounce", dbUI, nil)
    ColInfoLine(rightCol, "Announces resets in party/raid chat.")

    FinishColumns(content, leftCol, rightCol)
end

-- 2. Automation (2-column layout)
local function BuildAutomation(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements

    local leftCol, rightCol = CreateTwoColumns(content)

    ---------------------------------------------------------------------------
    -- LEFT COLUMN: Dungeon & Raid
    ---------------------------------------------------------------------------
    ColSubLabel(leftCol, "Dungeon & Raid")

    ColAddRow(leftCol, "Auto Insert M+ Keys", "checkbox", "autoInsertKey", dbUI, nil)
    ColInfoLine(leftCol, "Auto-insert keystone at start.")

    ColAddRow(leftCol, "Auto Combat Log in M+", "checkbox", "autoCombatLog", dbUI, nil)
    ColAddRow(leftCol, "Auto Log Raid (Normal)", "checkbox", "autoCombatLogRaidNormal", dbUI, nil)
    ColAddRow(leftCol, "Auto Log Raid (Heroic)", "checkbox", "autoCombatLogRaidHeroic", dbUI, nil)
    ColAddRow(leftCol, "Auto Log Raid (Mythic)", "checkbox", "autoCombatLogRaidMythic", dbUI, nil)
    ColInfoLine(leftCol, "Logs combat for Warcraft Logs upload.")

    leftCol.rowCount = leftCol.rowCount + 0.3
    ColSubLabel(leftCol, "Vendor")

    ColAddRow(leftCol, "Sell Gray Items", "checkbox", "sellJunk", dbUI, nil)
    ColInfoLine(leftCol, "Auto-sell junk at any vendor.")

    local repairOptions = {{value="off", text="Off"}, {value="personal", text="Personal Gold"}, {value="guild", text="Guild Bank First"}}
    ColDropdown(leftCol, "Auto Repair", repairOptions, "autoRepair", dbUI, nil)
    ColInfoLine(leftCol, "Repair gear at repair vendors.")

    leftCol.rowCount = leftCol.rowCount + 0.3
    ColSubLabel(leftCol, "Quests")

    ColAddRow(leftCol, "Auto Accept Quests", "checkbox", "autoAcceptQuest", dbUI, nil)
    ColAddRow(leftCol, "Auto Turn-In Quests", "checkbox", "autoTurnInQuest", dbUI, nil)
    ColAddRow(leftCol, "Shift Pauses Accept/Turn-In", "checkbox", "questHoldShift", dbUI, nil)
    ColInfoLine(leftCol, "Hold Shift to prevent auto-accept.")

    ---------------------------------------------------------------------------
    -- RIGHT COLUMN: Social & Group
    ---------------------------------------------------------------------------
    ColSubLabel(rightCol, "Group & LFG")

    ColAddRow(rightCol, "Auto Accept Role Check", "checkbox", "autoRoleAccept", dbUI, nil)
    ColAddRow(rightCol, "LFG Queue on Double Click", "checkbox", "lfgQuickJoin", dbUI, nil)
    ColInfoLine(rightCol, "Double-click a group to auto-apply.")

    -- Per-character LFG role selections
    local dbChar = ns.db and ns.db.char
    if dbChar then
        local _, classFilename = UnitClass("player")
        local canTank = classFilename == "WARRIOR" or classFilename == "PALADIN" or classFilename == "DRUID"
                     or classFilename == "DEATHKNIGHT" or classFilename == "MONK" or classFilename == "DEMONHUNTER"
        local canHeal = classFilename == "PALADIN" or classFilename == "PRIEST" or classFilename == "SHAMAN"
                     or classFilename == "DRUID" or classFilename == "MONK" or classFilename == "EVOKER"

        rightCol.rowCount = rightCol.rowCount + 0.3
        ColSubLabel(rightCol, "LFG Roles (per Character)")
        ColAddRow(rightCol, "   - DPS", "checkbox", "lfgRole_dps", dbChar, nil)
        if canHeal then
            ColAddRow(rightCol, "   - Healer", "checkbox", "lfgRole_healer", dbChar, nil)
        end
        if canTank then
            ColAddRow(rightCol, "   - Tank", "checkbox", "lfgRole_tank", dbChar, nil)
        end
        ColInfoLine(rightCol, "Roles for LFG quick-apply.")
    end

    rightCol.rowCount = rightCol.rowCount + 0.3
    ColSubLabel(rightCol, "Invites")

    local inviteOptions = {{value="off", text="Off"}, {value="all", text="All Invites"}, {value="friends", text="Friends Only"}, {value="guild", text="Guild Only"}, {value="both", text="Friends & Guild"}}
    ColDropdown(rightCol, "Auto Accept Invites", inviteOptions, "autoAcceptInvites", dbUI, nil)

    rightCol.rowCount = rightCol.rowCount + 0.3
    ColSubLabel(rightCol, "Invite on Whisper")
    ColAddRow(rightCol, "Enable", "checkbox", "inviteOnWhisper", dbUI, nil)
    ColAddRow(rightCol, "   - Invite All", "checkbox", "inviteOnWhisperAll", dbUI, nil)
    ColAddRow(rightCol, "   - Friends / BNet Only", "checkbox", "inviteOnWhisperFriends", dbUI, nil)
    ColAddRow(rightCol, "   - Guild Members Only", "checkbox", "inviteOnWhisperGuild", dbUI, nil)
    ColInput(rightCol, "   - Keywords (comma sep.)", "inviteOnWhisperKeywords", dbUI, nil)
    ColInfoLine(rightCol, "Priority: All > Friends > Guild.")

    FinishColumns(content, leftCol, rightCol)
end

-- 3. Autohide (2-column layout)
local function BuildAutohide(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements

    local function RefreshAutohide() if ns.ApplyAutohideSettings then ns.ApplyAutohideSettings() end end

    -- Ensure subtable
    if not dbUI.hideObjectiveTrackerInstanceTypes then
        dbUI.hideObjectiveTrackerInstanceTypes = {mythicPlus=false, mythicDungeon=false, normalDungeon=false, heroicDungeon=false, followerDungeon=false, raid=false, pvp=false, arena=false}
    end

    local leftCol, rightCol = CreateTwoColumns(content)

    ---------------------------------------------------------------------------
    -- LEFT COLUMN: Objective Tracker + Nameplates
    ---------------------------------------------------------------------------
    ColSubLabel(leftCol, "Objective Tracker")
    ColAddRow(leftCol, "Hide Always", "checkbox", "hideObjectiveTrackerAlways", dbUI, RefreshAutohide)

    local instanceTypes = {
        {key="mythicPlus", label="   - In Mythic+"},
        {key="mythicDungeon", label="   - In Mythic Dungeons"},
        {key="heroicDungeon", label="   - In Heroic Dungeons"},
        {key="normalDungeon", label="   - In Normal Dungeons"},
        {key="followerDungeon", label="   - In Follower Dungeons"},
        {key="raid", label="   - In Raids"},
        {key="pvp", label="   - In Battlegrounds"},
        {key="arena", label="   - In Arenas"},
    }
    for _, it in ipairs(instanceTypes) do
        ColAddRow(leftCol, it.label, "checkbox", it.key, dbUI.hideObjectiveTrackerInstanceTypes, RefreshAutohide)
    end

    leftCol.rowCount = leftCol.rowCount + 0.3
    ColSubLabel(leftCol, "Nameplates")
    ColAddRow(leftCol, "Hide Friendly Players", "checkbox", "hideFriendlyPlayerNameplates", dbUI, RefreshAutohide)
    ColAddRow(leftCol, "Hide Friendly NPCs", "checkbox", "hideFriendlyNPCNameplates", dbUI, RefreshAutohide)

    ---------------------------------------------------------------------------
    -- RIGHT COLUMN: Frames, Messages, Minigames, Privacy
    ---------------------------------------------------------------------------
    ColSubLabel(rightCol, "Frames & Buttons")
    ColAddRow(rightCol, "Hide Raid Frame Manager", "checkbox", "hideRaidFrameManager", dbUI, RefreshAutohide)
    ColAddRow(rightCol, "Hide Buff Collapse Button", "checkbox", "hideBuffCollapseButton", dbUI, RefreshAutohide)
    ColAddRow(rightCol, "Hide Talking Head Frame", "checkbox", "hideTalkingHead", dbUI, RefreshAutohide)
    ColAddRow(rightCol, "Mute Talking Head Voice", "checkbox", "muteTalkingHead", dbUI, RefreshAutohide)
    ColAddRow(rightCol, "Hide World Map Blackout", "checkbox", "hideWorldMapBlackout", dbUI, RefreshAutohide)

    rightCol.rowCount = rightCol.rowCount + 0.3
    ColSubLabel(rightCol, "Combat & Messages")
    ColAddRow(rightCol, "Hide Error Messages", "checkbox", "hideErrorMessages", dbUI, RefreshAutohide)
    ColInfoLine(rightCol, "Hides red error text in combat.")
    ColAddRow(rightCol, "Suppress HelpTip Popups", "checkbox", "suppressHelpTips", dbUI, RefreshAutohide)
    ColInfoLine(rightCol, "Hides yellow tutorial bubbles.")

    rightCol.rowCount = rightCol.rowCount + 0.3
    ColSubLabel(rightCol, "Minigames & Pet Battles")
    ColAddRow(rightCol, "Hide UI on Minigame/Petbattle", "checkbox", "hideOnWorldQuestMinigame", dbUI, RefreshAutohide)
    ColInfoLine(rightCol, "Cleans up UI during WQ minigames.")

    rightCol.rowCount = rightCol.rowCount + 0.3
    ColSubLabel(rightCol, "Streamer & Privacy")
    ColAddRow(rightCol, "Guild Chat Privacy Cover", "checkbox", "guildChatPrivacy", dbUI, nil)
    ColInfoLine(rightCol, "Spoiler overlay on guild chat tab.")

    FinishColumns(content, leftCol, rightCol)
end

--==============================================================================================================================================================================================
-- PAGE REGISTRATION
--==============================================================================================================================================================================================
ns.GUI:RegisterPage("qol", {
    title = "Quality of Life",
    subTabs = {
        { name = "QoL",          builder = BuildQoL },
        { name = "Automation",   builder = BuildAutomation },
        { name = "Autohide",     builder = BuildAutohide },
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
