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

-- ==========================================
-- GravityUI: Smart Item Destroyer
-- ==========================================
local SmartDelete = {}

function SmartDelete:GetItemData()
    local cType, cId, cLink = GetCursorInfo()
    if cType == "battlepet" and cId then
        local pName = C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID(cId)
        return pName and ("|cff0070dd[" .. pName .. "]|r") or nil
    elseif cType == "item" then
        return cLink
    end
end

function SmartDelete:CleanBoxText(textBody)
    if not textBody or not DELETE_GOOD_ITEM then return textBody end
    local reqString = string.match(DELETE_GOOD_ITEM, "\n(.+)$")
    if reqString then
        reqString = string.gsub(reqString, "%%s", "")
        reqString = strtrim(reqString)
        if reqString ~= "" and string.find(textBody, reqString, 1, true) then
            return strtrim(string.sub(textBody, 1, string.find(textBody, reqString, 1, true) - 1))
        end
    end
    return textBody
end

function SmartDelete.OnHover(frame, link, txt)
    if not link then return end
    local lType = string.match(link, "^(%a+)")
    if lType == "item" then
        GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    elseif lType == "battlepet" and BattlePetToolTip_ShowLink then
        GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
        BattlePetToolTip_ShowLink(link)
    end
end

function SmartDelete.OnLeave()
    GameTooltip:Hide()
    if BattlePetTooltip then BattlePetTooltip:Hide() end
end

function SmartDelete:InitHooks()
    for _, popName in pairs({"DELETE_ITEM", "DELETE_QUEST_ITEM", "DELETE_GOOD_QUEST_ITEM", "DELETE_GOOD_ITEM"}) do
        local d = StaticPopupDialogs[popName]
        if d then
            d.OnHyperlinkEnter = self.OnHover
            d.OnHyperlinkLeave = self.OnLeave
        end
    end
end

function SmartDelete:Process()
    local s = GetSettings()
    if not s or not s.deleteFix then return end

    local pFrame, pEdit, pBtn
    for i = 1, 4 do
        local f = _G["StaticPopup" .. i]
        if f and f:IsShown() then
            local e = _G["StaticPopup" .. i .. "EditBox"]
            local b = _G["StaticPopup" .. i .. "Button1"]
            if e and b then
                pFrame, pEdit, pBtn = f, e, b
                break
            end
        end
    end

    if not pFrame then return end
    local link = self:GetItemData()
    
    if pEdit then pEdit:Hide() end
    if pBtn then pBtn:Enable() end

    local txtRegion = _G[pFrame:GetName() .. "Text"]
    if txtRegion and link then
        local rawText = txtRegion:GetText() or ""
        txtRegion:SetText(self:CleanBoxText(rawText) .. "\n\n" .. link)
        if not (pEdit and pEdit:IsShown()) then
            pFrame:SetHeight(pFrame:GetHeight() + 32)
        end
    end
end

-- ==========================================
-- GravityUI: Safe Release (Death Protection)
-- ==========================================
local SafeRelease = {
    overlay = nil,
    label = nil,
    holdTime = 1.0,
    startTime = 0,
    released = false
}

function SafeRelease:Build(btnTarget)
    if self.overlay then return end
    self.overlay = CreateFrame("Button", "GravityUI_SafeReleaseBtn", btnTarget)
    self.overlay:SetAllPoints()
    self.overlay:SetFrameStrata("DIALOG")
    self.overlay:EnableMouse(true)
    self.overlay:RegisterForClicks("AnyUp", "AnyDown")
    
    local tex = self.overlay:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetColorTexture(0.05, 0.05, 0.05, 0.9)
    
    self.overlay.label = self.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.overlay.label:SetPoint("CENTER")
    self.overlay.label:SetTextColor(1, 0.5, 0)
    
    self.overlay:SetScript("OnClick", function() end)
end

function SafeRelease:Update()
    if self.released then
        self.overlay:Hide()
        return
    end
    
    if IsAltKeyDown() then
        if self.startTime == 0 then self.startTime = GetTime() end
        local diff = self.holdTime - (GetTime() - self.startTime)
        if diff <= 0 then
            self.released = true
            self.overlay:Hide()
        else
            self.overlay.label:SetText(string.format("Hold ALT (%.1fs)", diff))
        end
    else
        self.startTime = 0
        self.overlay.label:SetText(string.format("Hold ALT (%.1fs)", self.holdTime))
    end
end

function SafeRelease:Reset()
    self.startTime = 0
    self.released = false
    if self.overlay then
        self.overlay:SetScript("OnUpdate", nil)
        self.overlay:Hide()
    end
end

function SafeRelease:Trigger()
    local s = GetSettings()
    if not s or not s.deathReleaseProtection then return end

    local isVis, popupData = StaticPopup_Visible("DEATH")
    if not isVis or not popupData then return end
    
    local dBtn = popupData.GetButton and popupData:GetButton(1)
    if not dBtn then return end

    self:Build(dBtn)
    self:Reset()
    self.overlay.label:SetText(string.format("Hold ALT (%.1fs)", self.holdTime))
    self.overlay:SetScript("OnUpdate", function() self:Update() end)
    self.overlay:Show()
end

local function ToggleDeleteFix(enable)
    -- Deprecated basic stub, UI Improvements integration dynamically updates GetSettings
end
ns.ToggleDeleteFix = ToggleDeleteFix

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
automationFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
automationFrame:RegisterEvent("PLAYER_DEAD")
automationFrame:RegisterEvent("PLAYER_ALIVE")
automationFrame:RegisterEvent("PLAYER_UNGHOST")
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
    elseif event == "DELETE_ITEM_CONFIRM" then
        SmartDelete:Process()
    elseif event == "PLAYER_DEAD" then
        C_Timer.After(0.05, function() SafeRelease:Trigger() end)
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        SafeRelease:Reset()
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
                 
                 if s.deleteFix then SmartDelete:InitHooks() end
             end
             OverrideLfgApplicationDialog()
        end
        C_Timer.After(2, CheckResumeLogging)
    elseif event == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" then
        OnKeyStoneInsert()
    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        C_Timer.After(0.1, InjectGravityLfgListeners)
    end
end)
