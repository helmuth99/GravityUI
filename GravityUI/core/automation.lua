-- GravityUI - Automation Module
local ADDON_NAME, ns = ...

local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements then
        return db.uiimprovements
    end
    return nil
end

local automationFrame = CreateFrame("Frame")

---------------------------------------------------------------------------
-- MERCHANT: SELL JUNK + AUTO REPAIR
---------------------------------------------------------------------------

local function OnMerchantShow()
    local settings = GetSettings()
    if not settings then return end

    -- Sell Junk
    if settings.sellJunk then
        for bag = 0, 4 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.quality == Enum.ItemQuality.Poor then
                    C_Container.UseContainerItem(bag, slot)
                end
            end
        end
    end

    -- Auto Repair (Dropdown: "off", "personal", "guild")
    local repairMode = settings.autoRepair
    if repairMode and repairMode ~= "off" and CanMerchantRepair() then
        local repairCost = GetRepairAllCost()
        if repairCost and repairCost > 0 then
            if repairMode == "guild" and CanGuildBankRepair() then
                RepairAllItems(true)
                print("|cFF30D1FFGravityUI:|r Auto Repaired (Guild Bank)")
            else
                if GetMoney() >= repairCost then
                    RepairAllItems(false)
                    print("|cFF30D1FFGravityUI:|r Auto Repaired (Personal)")
                else
                    print("|cFF30D1FFGravityUI:|r Not enough money to repair!")
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- ROLE CHECK: AUTO ACCEPT
---------------------------------------------------------------------------

local function OnRoleCheckShow()
    local settings = GetSettings()
    if settings and settings.autoRoleAccept then
        CompleteLFGRoleCheck(true)
    end
end

---------------------------------------------------------------------------
-- LFG QUICK JOIN: DOUBLE CLICK TO APPLY
---------------------------------------------------------------------------

local function HandleGravityLfgClick(self)
    local cfg = GetSettings()
    if not cfg or not cfg.lfgQuickJoin then return end
    
    local isAvailable = not LFGListFrame.SearchPanel.SignUpButton.tooltip
    if isAvailable and _G.LFGListSearchPanel_SignUp then
        _G.LFGListSearchPanel_SignUp(self:GetParent():GetParent():GetParent())
    end
end

local function InjectGravityLfgListeners()
    if not LFGListFrame or not LFGListFrame.SearchPanel or not LFGListFrame.SearchPanel.ScrollBox then return end
    
    local targetNode = LFGListFrame.SearchPanel.ScrollBox:GetScrollTarget()
    if not targetNode then return end
    
    local entryNodes = {targetNode:GetChildren()}
    for _, node in ipairs(entryNodes) do
        if node and node:GetObjectType() == "Button" and not node.guiLfgAttached then
            node:SetScript("OnDoubleClick", HandleGravityLfgClick)
            node:RegisterForClicks("AnyUp")
            node.guiLfgAttached = true
        end
    end
end

local function OverrideLfgApplicationDialog()
    if LFGListApplicationDialog then
        LFGListApplicationDialog:HookScript("OnShow", function()
            local cfg = GetSettings()
            if not cfg or not cfg.lfgQuickJoin then return end
            
            if not IsShiftKeyDown() and LFGListApplicationDialog.SignUpButton then
                LFGListApplicationDialog.SignUpButton:Click()
            end
        end)
    end
    if LFDRoleCheckPopupAcceptButton then
        LFDRoleCheckPopupAcceptButton:HookScript("OnShow", function()
            local cfg = GetSettings()
            if cfg and cfg.autoRoleAccept then
                LFDRoleCheckPopupAcceptButton:Click()
            end
        end)
    end
end

---------------------------------------------------------------------------
-- PARTY INVITES: AUTO ACCEPT
---------------------------------------------------------------------------

local function IsFriendOrBNet(name)
    if not name then return false end
    -- Check normal friends
    if C_FriendList.IsFriend(name) then return true end
    -- Check BattleNet friends
    local numBNetTotal = BNGetNumFriends()
    for i = 1, numBNetTotal do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo then
            local charName = accountInfo.gameAccountInfo.characterName
            local realmName = accountInfo.gameAccountInfo.realmName
            if charName then
                local fullName = realmName and (charName .. "-" .. realmName) or charName
                if fullName == name or charName == name:match("^([^-]+)") then
                    return true
                end
            end
        end
    end
    return false
end

local function IsGuildMemberByName(name)
    if not name or not IsInGuild() then return false end
    local numMembers = GetNumGuildMembers()
    local searchName = name:match("^([^-]+)") or name
    for i = 1, numMembers do
        local memberName = GetGuildRosterInfo(i)
        if memberName then
            local memberShort = memberName:match("^([^-]+)") or memberName
            if memberShort == searchName then
                return true
            end
        end
    end
    return false
end

local function OnPartyInvite(inviterName)
    local settings = GetSettings()
    if not settings then return end

    -- Dropdown: "off", "all", "friends", "guild", "both"
    local mode = settings.autoAcceptInvites
    if not mode or mode == "off" then return end

    local shouldAccept = false

    if mode == "all" then
        shouldAccept = true
    elseif mode == "friends" then
        shouldAccept = IsFriendOrBNet(inviterName)
    elseif mode == "guild" then
        shouldAccept = IsGuildMemberByName(inviterName)
    elseif mode == "both" then
        shouldAccept = IsFriendOrBNet(inviterName) or IsGuildMemberByName(inviterName)
    end

    if shouldAccept then
        AcceptGroup()
        StaticPopup_Hide("PARTY_INVITE")
    end
end

---------------------------------------------------------------------------
-- QUESTS: AUTO ACCEPT & AUTO TURN-IN
---------------------------------------------------------------------------

local function ShouldPauseQuest(settings)
    return settings.questHoldShift and IsShiftKeyDown()
end

local function OnQuestDetail()
    local settings = GetSettings()
    if not settings or not settings.autoAcceptQuest then return end
    if ShouldPauseQuest(settings) then return end

    AcceptQuest()
end

local function OnQuestComplete()
    local settings = GetSettings()
    if not settings or not settings.autoTurnInQuest then return end
    if ShouldPauseQuest(settings) then return end

    -- If multiple choices exist, let user choose
    local numChoices = GetNumQuestChoices()
    if numChoices > 1 then return end

    GetQuestReward(numChoices > 0 and 1 or nil)
end

---------------------------------------------------------------------------
-- GOSSIP: AUTO-SELECT SINGLE OPTION
---------------------------------------------------------------------------

local gossipClicked = {}

local function OnGossipShow()
    local settings = GetSettings()
    if not settings then return end

    -- Shift-Bypass
    if settings.questHoldShift and IsShiftKeyDown() then return end

    -- 1. Auto Turn-In (Active Quests)
    if settings.autoTurnInQuest then
        local activeQuests = C_GossipInfo.GetActiveQuests()
        if activeQuests then
            for _, quest in ipairs(activeQuests) do
                if quest.isComplete then
                    C_GossipInfo.SelectActiveQuest(quest.questID)
                    return
                end
            end
        end
    end

    -- 2. Auto Accept (Available Quests)
    if settings.autoAcceptQuest then
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        if availableQuests then
            for _, quest in ipairs(availableQuests) do
                C_GossipInfo.SelectAvailableQuest(quest.questID)
                return
            end
        end
    end

    -- 3. Auto Select Gossip (Only if enabled)
    if not settings.autoSelectGossip then return end

    -- SAFETY: Don't auto-select gossip if there are ANY quests (Active or Available)
    -- This prevents skipping quest pickup/turn-in if automation above didn't handle it (e.g. turned off)
    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local activeQuests = C_GossipInfo.GetActiveQuests() -- Using GetActiveQuests table check for consistency
    
    if (availableQuests and #availableQuests > 0) or (activeQuests and #activeQuests > 0) then
        return
    end

    -- Get Gossip Options
    local options = C_GossipInfo.GetOptions()
    if not options or #options == 0 then return end

    local validOptions = {}
    for _, option in pairs(options) do
        if option.gossipOptionID then
            table.insert(validOptions, option)
        end
    end

    -- Select ONLY if exactly 1 option
    if #validOptions == 1 then
        local option = validOptions[1]
        local optionID = option.gossipOptionID

        if optionID and not gossipClicked[optionID] then
            gossipClicked[optionID] = true
            C_GossipInfo.SelectOption(optionID)

            local optionName = option.name or "gossip"
            print(string.format("|cFF30D1FFGravityUI:|r %s", optionName))
        end   
    end
end

local function OnGossipClosed()
    gossipClicked = {}
end

---------------------------------------------------------------------------
-- FAST AUTO LOOT
---------------------------------------------------------------------------

local lootRetryPending = false

local function TryLootAll()
    local numItems = GetNumLootItems()
    for slotIndex = 1, numItems do
        if LootSlotHasItem(slotIndex) then
            LootSlot(slotIndex)
        end
    end
end

local function CheckRemainingLoot()
    lootRetryPending = false
    local settings = GetSettings()
    if not settings or not settings.fastAutoLoot then return end

    local numItems = GetNumLootItems()
    for slotIndex = 1, numItems do
        if LootSlotHasItem(slotIndex) then
            TryLootAll()
            return
        end
    end
end

local function OnLootReady()
    local settings = GetSettings()
    if not settings or not settings.fastAutoLoot then return end

    if not GetCVarBool("autoLootDefault") then
        SetCVar("autoLootDefault", "1")
    end

    TryLootAll()

    if not lootRetryPending then
        lootRetryPending = true
        C_Timer.After(0.1, CheckRemainingLoot)
    end
end

---------------------------------------------------------------------------
-- M+ COMBAT LOGGING
---------------------------------------------------------------------------

local wasLoggingBeforeChallenge = false

local function OnChallengeModeStart()
    local settings = GetSettings()
    if not settings or not settings.autoCombatLog then return end

    wasLoggingBeforeChallenge = LoggingCombat()

    if not wasLoggingBeforeChallenge then
        LoggingCombat(true)
        print("|cFF30D1FFGravityUI:|r Combat logging started for M+")
    end
end

local function OnChallengeModeEnd()
    local settings = GetSettings()
    if not settings or not settings.autoCombatLog then return end

    if not wasLoggingBeforeChallenge and LoggingCombat() then
        LoggingCombat(false)
        print("|cFF30D1FFGravityUI:|r Combat logging stopped")
    end
    wasLoggingBeforeChallenge = false
end

---------------------------------------------------------------------------
-- RAID COMBAT LOGGING
---------------------------------------------------------------------------

local wasLoggingBeforeRaid = false
local isRaidLoggingActive = false

local function CheckRaidLogging()
    local settings = GetSettings()
    if not settings then return end
    
    local _, instanceType, difficultyID = GetInstanceInfo()
    local isRaid = (instanceType == "raid")
    
    local shouldLog = false
    
    if isRaid then
        -- Difficulty Checks
        if difficultyID == 14 and settings.autoCombatLogRaidNormal then -- Normal
            shouldLog = true
        elseif difficultyID == 15 and settings.autoCombatLogRaidHeroic then -- Heroic
            shouldLog = true
        elseif difficultyID == 16 and settings.autoCombatLogRaidMythic then -- Mythic
            shouldLog = true
        end
    end
    
    local isLogging = LoggingCombat()

    if shouldLog then
        if not isLogging then
            -- Enable Logging
            wasLoggingBeforeRaid = false
            isRaidLoggingActive = true
            LoggingCombat(true)
            print("|cFF30D1FFGravityUI:|r Combat logging started for Raid")
        elseif not isRaidLoggingActive then
            -- Already logging, but not stored by us (User manually enabled)
            wasLoggingBeforeRaid = true
            isRaidLoggingActive = true
        end
    else
        -- Should NOT log (left raid or disabled)
        if isRaidLoggingActive then
            if not wasLoggingBeforeRaid and isLogging then
                LoggingCombat(false)
                print("|cFF30D1FFGravityUI:|r Combat logging stopped (Raid)")
            end
            isRaidLoggingActive = false
            wasLoggingBeforeRaid = false
        end
    end
end

---------------------------------------------------------------------------
-- ZONE/LOGGING CHECK
---------------------------------------------------------------------------

local function CheckResumeLogging()
    -- M+ Check
    local settings = GetSettings()
    if settings and settings.autoCombatLog then
        if C_ChallengeMode.IsChallengeModeActive() and not LoggingCombat() then
            LoggingCombat(true)
            print("|cFF30D1FFGravityUI:|r Combat logging resumed (reconnected to M+)")
        end
    end
    
    -- Raid Check
    CheckRaidLogging()
end

local function OnKeyStoneInsert()
    local settings = GetSettings()
    if not settings or not settings.autoInsertKey then return end

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, slot)
            if (id and C_Item.IsItemKeystoneByID(id)) then
                C_Container.UseContainerItem(bag, slot)
                print("|cFF30D1FFGravityUI:|r Auto-inserted Keystone")
                return
            end
        end
    end
end

local function InitMovieSkip()
    local function hookRef(frame, btnProvider)
        if not frame then return end
        frame:HookScript("OnKeyUp", function(self, key)
            local s = GetSettings()
            if not s or not s.fasterMovieSkip then return end
            
            if key == "ESCAPE" or key == "SPACE" or key == "ENTER" then
                local btn = btnProvider()
                if btn and btn:IsShown() then
                    btn:Click()
                end
            end
        end)
    end
    
    hookRef(CinematicFrame, function() return CinematicFrameCloseDialogConfirmButton end)
    hookRef(MovieFrame, function() return MovieFrame and MovieFrame.CloseDialog and MovieFrame.CloseDialog.ConfirmButton end)
end

local originalDeleteGood = nil
local originalDeleteQuest = nil

local function ToggleDeleteFix(enable)
    if enable then
        -- Apply Fix
        if not originalDeleteGood then originalDeleteGood = StaticPopupDialogs.DELETE_GOOD_ITEM end
        if not originalDeleteQuest then originalDeleteQuest = StaticPopupDialogs.DELETE_GOOD_QUEST_ITEM end
        
        StaticPopupDialogs.DELETE_GOOD_ITEM = StaticPopupDialogs.DELETE_ITEM
        StaticPopupDialogs.DELETE_GOOD_QUEST_ITEM = StaticPopupDialogs.DELETE_ITEM
    else
        -- Revert Fix
        if originalDeleteGood then StaticPopupDialogs.DELETE_GOOD_ITEM = originalDeleteGood end
        if originalDeleteQuest then StaticPopupDialogs.DELETE_GOOD_QUEST_ITEM = originalDeleteQuest end
    end
end

-- Export for UI callback
ns.ToggleDeleteFix = ToggleDeleteFix

local function InitDeleteFix()
    local settings = GetSettings()
    -- Only enable if set. If disabled, do nothing (originals stay nil, untouched)
    if settings and settings.deleteFix then
        ToggleDeleteFix(true)
    end
end

---------------------------------------------------------------------------
-- EVENT REGISTRATION
---------------------------------------------------------------------------

-- Init Hooks immediately
InitMovieSkip()

automationFrame:RegisterEvent("ADDON_LOADED")
automationFrame:RegisterEvent("MERCHANT_SHOW")
automationFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
automationFrame:RegisterEvent("PARTY_INVITE_REQUEST")
automationFrame:RegisterEvent("QUEST_DETAIL")
automationFrame:RegisterEvent("QUEST_COMPLETE")
automationFrame:RegisterEvent("GOSSIP_SHOW")
automationFrame:RegisterEvent("GOSSIP_CLOSED")
automationFrame:RegisterEvent("LOOT_READY")
automationFrame:RegisterEvent("CHALLENGE_MODE_START")
automationFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
automationFrame:RegisterEvent("CHALLENGE_MODE_RESET")
automationFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
automationFrame:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN")
automationFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
automationFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
automationFrame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")

automationFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        -- (LFG hook moved to dedicated file)
    elseif event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "LFG_ROLE_CHECK_SHOW" then
        OnRoleCheckShow()
    elseif event == "PARTY_INVITE_REQUEST" then
        OnPartyInvite(...)
    elseif event == "QUEST_DETAIL" then
        OnQuestDetail()
    elseif event == "QUEST_COMPLETE" then
        OnQuestComplete()
    elseif event == "GOSSIP_SHOW" then
        OnGossipShow()
    elseif event == "GOSSIP_CLOSED" then
        OnGossipClosed()
    elseif event == "LOOT_READY" then
        OnLootReady()
    elseif event == "CHALLENGE_MODE_START" then
        OnChallengeModeStart()
    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        OnChallengeModeEnd()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_DIFFICULTY_CHANGED" then
        if event == "PLAYER_ENTERING_WORLD" then
             local s = GetSettings()
             if s then
                 if s.showDamageNumbers ~= nil then SetCVar("floatingCombatTextCombatDamage", s.showDamageNumbers and "1" or "0") end
                 if s.showHealingNumbers ~= nil then SetCVar("floatingCombatTextCombatHealing", s.showHealingNumbers and "1" or "0") end
                 if s.spellQueueWindow then SetCVar("SpellQueueWindow", tostring(s.spellQueueWindow)) end
             end
             InitDeleteFix()
             OverrideLfgApplicationDialog()
        end
        C_Timer.After(2, CheckResumeLogging)
    elseif event == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" then
        OnKeyStoneInsert()
    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        C_Timer.After(0.1, InjectGravityLfgListeners)
    end
end)
