-- GravityUI - Automation Module
local ADDON_NAME, ns = ...

local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements then
        return db.uiimprovements
    end
    return nil
end

local function GetRoleSettings()
    local char = ns.db and ns.db.char
    if not char then return nil end
    -- Return a proxy that reads/writes flat keys in ns.db.char directly
    -- This avoids the AceDB nested-table bug where sub-table refs point to defaults
    return {
        get = function(key) return char["lfgRole_" .. key] end,
        set = function(key, val) char["lfgRole_" .. key] = val end,
        tank   = char.lfgRole_tank,
        healer = char.lfgRole_healer,
        dps    = char.lfgRole_dps,
    }
end

local function SaveRole(key, val)
    if ns.db and ns.db.char then
        ns.db.char["lfgRole_" .. key] = val
    end
end

local function GetRole(key)
    if ns.db and ns.db.char then
        return ns.db.char["lfgRole_" .. key]
    end
    return false
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
        if C_MerchantFrame and C_MerchantFrame.SellAllJunkItems then
            C_MerchantFrame.SellAllJunkItems()
        else
            for bag = 0, 4 do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue then
                        C_Container.UseContainerItem(bag, slot)
                    end
                end
            end
        end
    end

    -- Auto Repair (Dropdown: "off", "personal", "guild")
    -- v2026-08 (Midnight compat): GetRepairAllCost and GetMoney return SECRET values in
    -- combat -- numeric comparisons > 0 and >= throw. Use only CanMerchantRepair() to
    -- decide; C-side enforces affordability when RepairAllItems is called.
    local repairMode = settings.autoRepair
    if repairMode and repairMode ~= "off" and CanMerchantRepair() then
        local repairCost, canRepair = GetRepairAllCost()
        if canRepair then
            -- Build a cost string only when the value is readable (not SECRET)
            local costText
            if repairCost and not (issecretvalue and issecretvalue(repairCost)) then
                local ok, txt = pcall(function()
                    local gold   = math.floor(repairCost / 10000)
                    local silver = math.floor((repairCost % 10000) / 100)
                    return gold .. "|cffffd700g|r " .. silver .. "|cffc7c7cfs|r"
                end)
                if ok then costText = txt end
            end

            if repairMode == "guild" and CanGuildBankRepair() then
                RepairAllItems(true)
                print("|cFF30D1FFGravityUI:|r Auto Repaired (Guild Bank)" .. (costText and " for " .. costText or "") .. ".")
                -- Guild funds may not cover everything; check after server round-trip.
                C_Timer.After(0.6, function()
                    if not (MerchantFrame and MerchantFrame:IsShown()) then return end
                    local _, still = GetRepairAllCost()
                    if still then
                        RepairAllItems(false)
                        print("|cFF30D1FFGravityUI:|r Guild funds insufficient — repaired remainder with personal gold.")
                    end
                end)
            else
                RepairAllItems(false)
                print("|cFF30D1FFGravityUI:|r Auto Repaired (Personal)" .. (costText and " for " .. costText or "") .. ".")
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

local function ForceApplyLfgRolesNow()
    if not _G.LFGListApplicationDialog or not _G.LFGListApplicationDialog:IsShown() then return end
    local function SetRole(btn, desiredState)
        if btn and btn.CheckButton and btn.CheckButton:IsEnabled() then
            local checked = btn.CheckButton:GetChecked() and true or false
            if checked ~= desiredState then
                btn.CheckButton:Click()
            end
        end
    end
    
    local tankBtn = _G.LFGListApplicationDialog.TankButton or _G.LFGListApplicationDialog.RoleButtonTank
    local healerBtn = _G.LFGListApplicationDialog.HealerButton or _G.LFGListApplicationDialog.RoleButtonHealer
    local dpsBtn = _G.LFGListApplicationDialog.DamagerButton or _G.LFGListApplicationDialog.RoleButtonDPS
    
    SetRole(tankBtn,   GetRole("tank"))
    SetRole(healerBtn, GetRole("healer"))
    SetRole(dpsBtn,    GetRole("dps"))
end

local function HandleGravityLfgClick(self)
    local cfg = GetSettings()
    if not cfg or not cfg.lfgQuickJoin then return end
    
    -- Validation: Check if at least one role is selected
    if not GetRole("tank") and not GetRole("healer") and not GetRole("dps") then
        print("|cffFFCC00GravityUI:|r LFG Quick-Join abgebrochen! Bitte wähle oben rechts mindestens eine Rolle (Tank/Heal/DD) aus.")
        return
    end
    
    local isAvailable = not LFGListFrame.SearchPanel.SignUpButton.tooltip
    if isAvailable and _G.LFGListSearchPanel_SignUp then
        -- Signal that this open was triggered by our automation (enables role auto-apply)
        _gravityAutoMode = true
        
        -- 1. Gruppe auswählen (öffnet den Rollen-Dialog)
        _G.LFGListSearchPanel_SignUp(self:GetParent():GetParent():GetParent())
        
        -- 2. Sofort im selben Ausführungs-Frame den Dialog bestätigen
        -- (Nutzt die Hardware-Freigabe des Doppelklicks)
        if LFGListApplicationDialog and LFGListApplicationDialog:IsShown() then
            if not IsShiftKeyDown() and LFGListApplicationDialog.SignUpButton then
                ForceApplyLfgRolesNow()
                if LFGListApplicationDialog.SignUpButton:IsEnabled() then
                    LFGListApplicationDialog.SignUpButton:Click()
                end
            end
        end
    end
end

local HooksState = {}
-- Flag: true only when the dialog was opened via GravityUI double-click automation.
-- When false (normal Sign-Up button click), we do NOT override manual role selections.
local _gravityAutoMode = false

local lfgRolePending = false
local function ScheduleForceApplyLfgRoles()
    -- Only auto-apply roles when triggered by our own double-click path
    if not _gravityAutoMode then return end
    if lfgRolePending then return end
    lfgRolePending = true
    C_Timer.After(0.15, function()
        lfgRolePending = false
        ForceApplyLfgRolesNow()
    end)
end

local function OverrideLfgApplicationDialog()
    if not HooksState.lfgAppDialog and _G.LFGListApplicationDialog then
        if _G.LFGListApplicationDialog.UpdateRoles then
            hooksecurefunc(_G.LFGListApplicationDialog, "UpdateRoles", ScheduleForceApplyLfgRoles)
        elseif _G.LFGListApplicationDialog_UpdateRoles then
            hooksecurefunc("LFGListApplicationDialog_UpdateRoles", ScheduleForceApplyLfgRoles)
        end

        _G.LFGListApplicationDialog:HookScript("OnShow", ScheduleForceApplyLfgRoles)
        -- Clear the flag whenever the dialog is closed/hidden so it doesn't
        -- bleed into a subsequent manual open.
        _G.LFGListApplicationDialog:HookScript("OnHide", function()
            _gravityAutoMode = false
        end)
        HooksState.lfgAppDialog = true
    end
    
    if not HooksState.lfdRolePopup and _G.LFDRoleCheckPopupAcceptButton then
        _G.LFDRoleCheckPopupAcceptButton:HookScript("OnShow", function()
            local cfg = GetSettings()
            if cfg and cfg.autoRoleAccept then
                -- TAINT FIX: Defer Click() out of the OnShow secure context.
                -- Calling Click() directly here fires the button's internal
                -- protected handler from a tainted call stack → ADDON_ACTION_FORBIDDEN.
                C_Timer.After(0, function()
                    if _G.LFDRoleCheckPopupAcceptButton and _G.LFDRoleCheckPopupAcceptButton:IsShown() then
                        _G.LFDRoleCheckPopupAcceptButton:Click()
                    end
                end)
            end
        end)
        HooksState.lfdRolePopup = true
    end
end

local function InjectGravityLfgListeners()
    if not LFGListFrame or not LFGListFrame.SearchPanel or not LFGListFrame.SearchPanel.ScrollBox then return end
    
    OverrideLfgApplicationDialog()
    
    local targetNode = LFGListFrame.SearchPanel.ScrollBox:GetScrollTarget()
    if not targetNode then return end
    
    -- PERF: Cache GetChildren() once to avoid double vararg allocation per iteration.
    local targetChildren = {targetNode:GetChildren()}
    for i = 1, #targetChildren do
        local node = targetChildren[i]
        if node and node:GetObjectType() == "Button" and not node.guiLfgAttached then
            node:SetScript("OnDoubleClick", HandleGravityLfgClick)
            node:RegisterForClicks("AnyUp")
            node.guiLfgAttached = true
        end
    end
end



---------------------------------------------------------------------------
-- LFG ROLE CHECKBOXES INJECTION
---------------------------------------------------------------------------

local LfgRoleCheckboxes = {}

local function CreateRoleCheckbox(parent, roleName, texCoord, anchorFrame, anchorPoint, anchorRelPoint, offsetX, offsetY, configKey)
    local btn = CreateFrame("CheckButton", "GravityUI_LFGRole_"..roleName, parent)
    btn:SetSize(22, 22)
    btn:SetPoint(anchorPoint, anchorFrame, anchorRelPoint, offsetX, offsetY)
    -- PVEFrame.TitleContainer sits at frame level 510 and blocks clicks on
    -- anything below it. Push our role buttons above the title container.
    btn:SetFrameLevel(520)
    
    -- Guard: prevents OnClick from firing when SetChecked() is called programmatically
    local isProgrammatic = false
    
    -- Dark background for contrast
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(24, 24)
    bg:SetPoint("CENTER")
    bg:SetColorTexture(0, 0, 0, 0.7)
    
    local normalTex = btn:CreateTexture(nil, "ARTWORK")
    normalTex:SetAllPoints()
    normalTex:SetTexture("Interface\\LFGFrame\\LFGRole")
    normalTex:SetTexCoord(unpack(texCoord))
    btn:SetNormalTexture(normalTex)
    
    local pushedTex = btn:CreateTexture(nil, "ARTWORK")
    pushedTex:SetAllPoints()
    pushedTex:SetTexture("Interface\\LFGFrame\\LFGRole")
    pushedTex:SetTexCoord(unpack(texCoord))
    pushedTex:SetVertexColor(0.5, 0.5, 0.5)
    btn:SetPushedTexture(pushedTex)
    
    local highlightTex = btn:CreateTexture(nil, "HIGHLIGHT")
    highlightTex:SetAllPoints()
    highlightTex:SetTexture("Interface\\LFGFrame\\LFGRole")
    highlightTex:SetTexCoord(unpack(texCoord))
    highlightTex:SetBlendMode("ADD")
    highlightTex:SetAlpha(0.6)
    btn:SetHighlightTexture(highlightTex)

    -- Better checked texture - a bright glowing border instead of a small tick
    local checkedTex = btn:CreateTexture(nil, "OVERLAY")
    checkedTex:SetSize(30, 30)
    checkedTex:SetPoint("CENTER")
    checkedTex:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    checkedTex:SetBlendMode("ADD")
    btn:SetCheckedTexture(checkedTex)
    
    local function UpdateThemeColor()
        local db = ns.GetDB()
        local general = db and db.general
        if general then
            if general.useClassColorTheme then
                local _, class = UnitClass("player")
                local color = RAID_CLASS_COLORS[class]
                if color then
                    checkedTex:SetVertexColor(color.r, color.g, color.b, 1)
                else
                    checkedTex:SetVertexColor(0.2, 1, 0.2, 1)
                end
            elseif general.themeColor then
                checkedTex:SetVertexColor(general.themeColor[1], general.themeColor[2], general.themeColor[3], 1)
            else
                checkedTex:SetVertexColor(0.2, 1, 0.2, 1)
            end
        else
            checkedTex:SetVertexColor(0.2, 1, 0.2, 1)
        end
    end

    -- Run it immediately so that the color is already registered before OnShow
    UpdateThemeColor()
    
    -- Load saved state on show
    btn:SetScript("OnShow", function(self)
        isProgrammatic = true
        self:SetChecked(GetRole(configKey))
        isProgrammatic = false
        UpdateThemeColor()
    end)
    
    -- Save state on click (only when user actually clicks, not programmatic)
    btn:SetScript("OnClick", function(self)
        if isProgrammatic then return end
        -- GetChecked() returns 1 or nil — convert to explicit boolean
        SaveRole(configKey, self:GetChecked() and true or false)
    end)
    
    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Auto-Select " .. roleName .. " (Quick Join)")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    return btn
end

local function InjectRoleTogglesLFG()
    if LfgRoleCheckboxes.injected or not _G.LFGListFrame then return end
    local sp = LFGListFrame.SearchPanel
    if not sp then return end
    
    local closeBtn = _G.PVEFrame and _G.PVEFrame.CloseButton or _G.PVEFrameCloseButton
    
    -- Determine available roles for the player's class
    local _, classFilename = UnitClass("player")
    local canTank = false
    local canHeal = false
    
    if classFilename == "WARRIOR" or classFilename == "PALADIN" or classFilename == "DRUID" or classFilename == "DEATHKNIGHT" or classFilename == "MONK" or classFilename == "DEMONHUNTER" then
        canTank = true
    end
    if classFilename == "PALADIN" or classFilename == "PRIEST" or classFilename == "SHAMAN" or classFilename == "DRUID" or classFilename == "MONK" or classFilename == "EVOKER" then
        canHeal = true
    end
    
    -- Anchor starting point
    local currentAnchor = closeBtn
    local currentPoint = "RIGHT"
    local currentRelPoint = "LEFT"
    local currentX = -10
    local currentY = -2
    
    if not closeBtn then
        currentAnchor = sp
        currentPoint = "TOPRIGHT"
        currentRelPoint = "TOPRIGHT"
        currentX = -5
        currentY = 23
    end

    -- Create buttons from right to left (DPS -> Healer -> Tank) so they stack neatly against the close button
    -- TexCoords from Interface\LFGFrame\LFGRole: Tank, Healer, DPS
    
    LfgRoleCheckboxes.dps = CreateRoleCheckbox(sp, "DPS", {0.25, 0.5, 0, 1}, currentAnchor, currentPoint, currentRelPoint, currentX, currentY, "dps")
    currentAnchor = LfgRoleCheckboxes.dps
    currentPoint = "RIGHT"
    currentRelPoint = "LEFT"
    currentX = -2
    currentY = 0
    
    if canHeal then
        LfgRoleCheckboxes.healer = CreateRoleCheckbox(sp, "Healer", {0.75, 1, 0, 1}, currentAnchor, currentPoint, currentRelPoint, currentX, currentY, "healer")
        currentAnchor = LfgRoleCheckboxes.healer
    end
    
    if canTank then
        LfgRoleCheckboxes.tank = CreateRoleCheckbox(sp, "Tank", {0.5, 0.75, 0, 1}, currentAnchor, currentPoint, currentRelPoint, currentX, currentY, "tank")
        currentAnchor = LfgRoleCheckboxes.tank
    end
    
    local label = sp:CreateFontString(nil, "OVERLAY", "GameFontNormal_NoShadow")
    label:SetPoint("RIGHT", currentAnchor, "LEFT", -8, 0)
    label:SetText("Roles:")
    label:SetTextColor(1, 0.82, 0)
    LfgRoleCheckboxes.label = label
    
    LfgRoleCheckboxes.injected = true
end

---------------------------------------------------------------------------
-- PARTY INVITES: AUTO ACCEPT
---------------------------------------------------------------------------

local function IsFriendOrBNet(sender)
    if not sender then return false end
    
    -- Split name and realm if present
    local name, realm = sender:match("^(.-)%-(.*)$")
    if not name then name = sender end
    
    -- Check Battle.net friends
    local numBNetTotal = BNGetNumFriends()
    for i = 1, numBNetTotal do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
            local charName = accountInfo.gameAccountInfo.characterName
            local charRealm = accountInfo.gameAccountInfo.realmName
            if charName then
                local exactName = charRealm and (charName .. "-" .. charRealm) or charName
                if sender == exactName then return true end
            end
        end
    end

    -- Check regular friends
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo and friendInfo.name == sender then
            return true
        end
    end

    return false
end

local function IsGuildMemberByName(sender)
    if not sender or not IsInGuild() then return false end

    for i = 1, GetNumGuildMembers() do
        local fullName = GetGuildRosterInfo(i) -- Returns Name-Realm
        if fullName and fullName == sender then
            return true
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
-- WHISPER INVITES: AUTO INVITE ON KEYWORD
---------------------------------------------------------------------------

local function OnWhisper(msg, sender, isBNet, bnGameAccountID)
    local settings = GetSettings()
    if not settings or not settings.inviteOnWhisper then return end
    if not msg or not sender then return end
    if (issecretvalue and (issecretvalue(msg) or issecretvalue(sender))) or type(msg) ~= "string" then return end

    -- Check if we are already in a group and not the leader
    if IsInGroup() and not UnitIsGroupLeader("player") then 
        return 
    end
    -- Check if group is full
    if GetNumGroupMembers() >= (IsInRaid() and 40 or 5) then 
        return 
    end

    -- Parse keywords
    local keywords = {}
    for kw in string.gmatch(settings.inviteOnWhisperKeywords or "", "([^,%s]+)") do
        table.insert(keywords, string.lower(kw))
    end
    -- print("|cFF30D1FFGravityUI Debug:|r Keywords: " .. table.concat(keywords, ", "))

    -- Match keyword (case-insensitive)
    local match = false
    local text = ""
    local lowerSuccess, lowerText = pcall(function() return strtrim(string.lower(msg)) end)
    
    if lowerSuccess and lowerText then
        text = lowerText
        for _, kw in ipairs(keywords) do
            local findSuccess, findMatch = pcall(function() 
                return text == kw or string.find(text, "%f[%a]" .. kw .. "%f[%A]") 
            end)
            if findSuccess and findMatch then
                match = true
                break
            end
        end
    end

    if not match then 
        return 
    end
    print("|cFF30D1FFGravityUI:|r Whisper Keyword Matched: " .. text .. " from " .. (isBNet and "BNet" or "Whisper"))

    -- Filter Check
    local allowed = false
    if settings.inviteOnWhisperAll then
        allowed = true
    else
        if settings.inviteOnWhisperFriends then
            if isBNet then
                allowed = true -- BNet whispers are always from friends
            else
                allowed = IsFriendOrBNet(sender)
            end
        end
        if not allowed and settings.inviteOnWhisperGuild then
            if isBNet then
                allowed = true -- BNet whisper is trusted
            else
                allowed = IsGuildMemberByName(sender)
            end
        end
    end

    if not allowed then
        return 
    end

    if isBNet then
        if bnGameAccountID then
            -- Prefer modern API invite if accessible
            local ok = false
            if C_BattleNet and C_BattleNet.InviteFriend then
                ok = pcall(C_BattleNet.InviteFriend, bnGameAccountID)
            elseif BNInviteFriend then
                ok = pcall(BNInviteFriend, bnGameAccountID)
            end
            if ok then
                print("|cFF30D1FFGravityUI:|r BNet invite sent to " .. sender)
                return
            end
        end
        -- Fallback: invite via fully qualified character name (Player-Realm)
        print("|cFF30D1FFGravityUI:|r Sending cross-realm invite to " .. sender)
        C_PartyInfo.InviteUnit(sender)
    else
        print("|cFF30D1FFGravityUI:|r Sending Invite to " .. sender)
        C_PartyInfo.InviteUnit(sender)
    end
end

---------------------------------------------------------------------------
-- QUESTS: AUTO ACCEPT & AUTO TURN-IN
---------------------------------------------------------------------------

-- v2026-08: GUID-based NPC suppression (EUI pattern).
-- Holding Shift at ANY quest event during a visit marks the current NPC's
-- GUID as suppressed. All subsequent events for that NPC stay manual even
-- after Shift is released -- so releasing Shift to click a gossip option
-- can no longer accidentally re-arm automation. The mark is cleared 0.15s
-- after a close event (NPC unit is gone by then on a true close but still
-- present during panel transitions).
local suppressedNPCGUID = nil

local function CurrentNPCGUID()
    return UnitGUID("npc") or UnitGUID("questnpc")
end

local function VisitSuppressed()
    local npc = CurrentNPCGUID()
    if IsShiftKeyDown() then
        if npc then suppressedNPCGUID = npc end
        return true
    end
    if npc and npc == suppressedNPCGUID then
        return true
    end
    return false
end

local function OnQuestDetail()
    local settings = GetSettings()
    if not settings or not settings.autoAcceptQuest then return end
    if VisitSuppressed() then
        -- Blizzard auto-accept quests are accepted server-side before addon code runs.
        -- DeclineQuest() is the only client-side undo while the detail frame is shown.
        if QuestGetAutoAccept and QuestGetAutoAccept() then
            DeclineQuest()
        end
        return
    end
    AcceptQuest()
end

local function OnQuestProgress()
    local settings = GetSettings()
    if not settings or not settings.autoTurnInQuest then return end
    if VisitSuppressed() then return end
    if IsQuestCompletable and IsQuestCompletable() then CompleteQuest() end
end

local function OnQuestComplete()
    local settings = GetSettings()
    if not settings or not settings.autoTurnInQuest then return end
    if VisitSuppressed() then return end

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

    -- 1. Auto Turn-In (Active Quests)
    if settings.autoTurnInQuest and not VisitSuppressed() then
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
    if settings.autoAcceptQuest and not VisitSuppressed() then
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
    -- Deferred clear: on a true close the npc unit is gone shortly after the event;
    -- on a panel transition it is still present. Only clear the GUID when no NPC remains
    -- so panel transitions can't corrupt suppression state.
    C_Timer.After(0.15, function()
        if not CurrentNPCGUID() then
            suppressedNPCGUID = nil
        end
    end)
end

local function OnQuestFinished()
    C_Timer.After(0.15, function()
        if not CurrentNPCGUID() then
            suppressedNPCGUID = nil
        end
    end)
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
-- COMBAT LOGGING HELPERS
---------------------------------------------------------------------------

-- Silently enables Advanced Combat Logging if it isn't already on.
-- This ensures WarcraftLogs receives full event data (source GUIDs, flags, etc.).
-- Mirrors EllesmerUI's EnsureAdvancedLogging() pattern.
local function EnsureAdvancedLogging()
    if GetCVar and GetCVar("advancedCombatLogging") ~= "1" then
        pcall(SetCVar, "advancedCombatLogging", 1)
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
        EnsureAdvancedLogging()
        LoggingCombat(true)
        print("|cFF30D1FFGravityUI:|r Combat logging started for M+")
    else
        print("|cFF30D1FFGravityUI:|r Combat logging is |cFF00FF00ACTIVE|r (already running)")
    end
end

local function OnChallengeModeEnd()
    local settings = GetSettings()
    if not settings or not settings.autoCombatLog then return end

    if not wasLoggingBeforeChallenge and LoggingCombat() then
        LoggingCombat(false)
        print("|cFF30D1FFGravityUI:|r Combat logging stopped")
    else
        print("|cFF30D1FFGravityUI:|r Combat logging session ended")
    end
    wasLoggingBeforeChallenge = false
end

---------------------------------------------------------------------------
-- RAID COMBAT LOGGING
---------------------------------------------------------------------------

local wasLoggingBeforeRaid = false
local isRaidLoggingActive = false
local resumeLoggingPending = false

local function CheckRaidLogging()
    local settings = GetSettings()
    if not settings then return end
    
    local _, instanceType, difficultyID, difficultyName = GetInstanceInfo()
    local isRaid = (instanceType == "raid")
    
    local shouldLog = false
    local lowerName = difficultyName and difficultyName:lower() or ""
    
    if isRaid then
        -- Difficulty Checks (ID-based, primary)
        if difficultyID == 14 and settings.autoCombatLogRaidNormal then -- Normal
            shouldLog = true
        elseif difficultyID == 15 and settings.autoCombatLogRaidHeroic then -- Heroic
            shouldLog = true
        elseif difficultyID == 16 and settings.autoCombatLogRaidMythic then -- Mythic (fixed 20)
            shouldLog = true
        elseif difficultyID == 233 and settings.autoCombatLogRaidMythic then -- Mythic Flexible (since Sporefall/12.0.7)
            shouldLog = true
        -- Fallback: name-based matching for new/unknown IDs
        elseif settings.autoCombatLogRaidNormal and lowerName:find("normal") then
            shouldLog = true
        elseif settings.autoCombatLogRaidHeroic and lowerName:find("heroic") then
            shouldLog = true
        elseif settings.autoCombatLogRaidMythic and lowerName:find("mythic") then
            shouldLog = true
        end
    end
    
    local isLogging = LoggingCombat()

    if shouldLog then
        if not isLogging then
            -- Enable Logging
            wasLoggingBeforeRaid = false
            isRaidLoggingActive = true
            EnsureAdvancedLogging()
            LoggingCombat(true)
            print("|cFF30D1FFGravityUI:|r Combat logging started for Raid")
        elseif not isRaidLoggingActive then
            -- Already logging, but not stored by us (User manually enabled)
            wasLoggingBeforeRaid = true
            isRaidLoggingActive = true
            print("|cFF30D1FFGravityUI:|r Combat logging is |cFF00FF00ACTIVE|r for Raid")
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
    resumeLoggingPending = false
    -- M+ Check
    local settings = GetSettings()
    if settings and settings.autoCombatLog then
        if C_ChallengeMode.IsChallengeModeActive() and not LoggingCombat() then
            EnsureAdvancedLogging()
            LoggingCombat(true)
            print("|cFF30D1FFGravityUI:|r Combat logging resumed (reconnected to M+)")
        end
    end

    -- Raid Check: CheckRaidLogging handles the full logic.
    -- If we reconnected mid-raid and logging was not yet started by us,
    -- it will start it. We track the reconnect case for a clear chat message.
    local wasActive = isRaidLoggingActive
    CheckRaidLogging()
    if not wasActive and isRaidLoggingActive then
        -- CheckRaidLogging already printed "started for Raid" – no extra message needed.
        -- But if logging was already running when we reconnected (user had it on manually),
        -- we print a reconnect notice so it's clear GravityUI noticed the raid.
        if LoggingCombat() and wasLoggingBeforeRaid then
            print("|cFF30D1FFGravityUI:|r Combat logging active (reconnected to Raid)")
        end
    end
end

local function OnKeyStoneInsert()
    local settings = GetSettings()
    if not settings or not settings.autoInsertKey then return end

    -- Guard: already slotted
    if C_ChallengeMode.HasSlottedKeystone() then return end

    -- Verify the keystone matches this dungeon (mirrors BigWigs' approach)
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local ownedMapID = C_MythicPlus.GetOwnedKeystoneMapID and C_MythicPlus.GetOwnedKeystoneMapID()
    if ownedMapID and instanceID and ownedMapID ~= instanceID then return end

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            -- Use item link check (same method as BigWigs) for reliability
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link and link:find("Hkeystone", nil, true) then
                C_Container.PickupContainerItem(bag, slot)
                C_ChallengeMode.SlotKeystone()
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
-- GravityUI: Auto Skip Cinematics
-- ==========================================
local function InitAutoSkipCinematics()
    -- Real cinematics (isRealCinematic): StopCinematic() is safe from event context.
    -- In-game scenes: CancelScene() only needs to escape the direct event call-stack;
    --   a minimal C_Timer.After(0.05) is sufficient — no key press required.
    -- Movies (PLAY_MOVIE): StopMovie() is the clean API.

    local cinFrame = CreateFrame("Frame")
    cinFrame:RegisterEvent("CINEMATIC_START")
    cinFrame:RegisterEvent("PLAY_MOVIE")
    cinFrame:SetScript("OnEvent", function(self, event)
        local s = GetSettings()
        if not s or not s.autoSkipCinematics then return end

        if event == "CINEMATIC_START" then
            if CinematicFrame and CinematicFrame.isRealCinematic then
                -- Real pre-rendered cutscene: stop immediately.
                StopCinematic()
            else
                -- In-game engine scene: escape the event call-stack with a short timer,
                -- then cancel if the setting is still on and the frame is still shown.
                C_Timer.After(0.05, function()
                    local s2 = GetSettings()
                    if not s2 or not s2.autoSkipCinematics then return end
                    if CinematicFrame and CinematicFrame:IsShown() then
                        if CanCancelScene and CanCancelScene() then
                            CancelScene()
                        else
                            -- Fallback: try StopCinematic for any remaining frame types
                            pcall(StopCinematic)
                        end
                    end
                end)
            end
        elseif event == "PLAY_MOVIE" then
            -- Use the clean Movie API; hides MovieFrame as a side-effect.
            C_Timer.After(0.05, function()
                local s2 = GetSettings()
                if not s2 or not s2.autoSkipCinematics then return end
                if StopMovie then
                    pcall(StopMovie)
                elseif MovieFrame then
                    MovieFrame:Hide()
                end
            end)
        end
    end)
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
    released = false,
    mouseHeld = false,   -- tracks left/right mouse button hold on overlay
}

function SafeRelease:Build(btnTarget)
    if self.overlay then return end
    self.overlay = CreateFrame("Button", "GravityUI_SafeReleaseBtn", btnTarget)
    self.overlay:SetAllPoints()
    self.overlay:SetFrameStrata("DIALOG")
    self.overlay:SetFrameLevel(btnTarget:GetFrameLevel() + 10)
    self.overlay:EnableMouse(true)
    self.overlay:RegisterForClicks("AnyUp", "AnyDown")
    
    local tex = self.overlay:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetColorTexture(0.08, 0.08, 0.08, 0.98)
    
    self.overlay.label = self.overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.overlay.label:SetPoint("CENTER")
    self.overlay.label:SetTextColor(1, 0.7, 0.1)

    -- Track mouse hold on the overlay itself
    self.overlay:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" or btn == "RightButton" then
            self.mouseHeld = true
        end
    end)
    self.overlay:SetScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" or btn == "RightButton" then
            self.mouseHeld = false
        end
    end)

    self.overlay:SetScript("OnClick", function() end)
end

function SafeRelease:Update()
    if self.released then
        self.overlay:Hide()
        return
    end
    
    -- Ensure we are only blocking the "DEATH" popup.
    -- If the popup was recycled for a Resurrection offer (e.g. Battle Rezz),
    -- we disable our overlay so we don't block the "Accept" button.
    if not StaticPopup_Visible("DEATH") then
        self.overlay:SetAlpha(0)
        self.overlay:EnableMouse(false)
        return
    else
        self.overlay:SetAlpha(1)
        self.overlay:EnableMouse(true)
    end
    
    -- ALT key OR mouse button held both count
    local holding = IsAltKeyDown() or self.mouseHeld
    local mode = IsAltKeyDown() and "ALT" or (self.mouseHeld and "Click" or "ALT")

    if holding then
        if self.startTime == 0 then self.startTime = GetTime() end
        local diff = self.holdTime - (GetTime() - self.startTime)
        if diff <= 0 then
            self.released = true
            self.overlay:Hide()
        else
            self.overlay.label:SetText(string.format("Hold %s  (%.1fs)", mode, diff))
        end
    else
        self.startTime = 0
        self.overlay.label:SetText("Hold ALT or Click")
    end
end

function SafeRelease:Reset()
    self.startTime = 0
    self.released = false
    self.mouseHeld = false
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
    
    -- In case the popup was reused, ensure we show it now because the type is DEATH again
    self.overlay:Show()
    self.overlay.label:SetText(string.format("Hold ALT or Click"))
    -- PERF: Use named method reference instead of anonymous closure to avoid
    -- allocating a new function object on every Trigger() call.
    self.overlay:SetScript("OnUpdate", function() self:Update() end)
end

local function ToggleDeleteFix(enable)
    -- Deprecated basic stub, UI Improvements integration dynamically updates GetSettings
end
ns.ToggleDeleteFix = ToggleDeleteFix

---------------------------------------------------------------------------
-- EDITMODE CHECK ON SPEC SWITCH
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- AUCTION HOUSE: AUTO FILTER CURRENT EXPANSION
---------------------------------------------------------------------------

local function OnAuctionHouseShow()
    local settings = GetSettings()
    if not settings or not settings.ahCurrentExpansionFilter then return end

    if AUCTION_HOUSE_DEFAULT_FILTERS then
        -- The modern AH filter uses this global table to define default active filters
        -- We just flip the boolean state.
        AUCTION_HOUSE_DEFAULT_FILTERS[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
        
        -- If AH is currently shown and has a method to reset/apply filters, trigger it
        if AuctionHouseFrame and AuctionHouseFrame.SearchBar and AuctionHouseFrame.SearchBar.FilterButton then
            AuctionHouseFrame.SearchBar.FilterButton:Reset()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Spell Queue Window Auto-Optimization
-- Spec-aware SQW tuning: categorizes specs into profiles with different
-- ping multipliers and clamp ranges. Inspired by TSpellQueueOptimizer.
-- ---------------------------------------------------------------------------
local SQW_CHANNEL_HEAVY = {
    [258]  = true,  -- Priest: Shadow
    [270]  = true,  -- Monk: Mistweaver
    [1467] = true,  -- Evoker: Devastation
    [1468] = true,  -- Evoker: Preservation
    [265]  = true,  -- Warlock: Affliction
}
local SQW_AUG_EVOKER = {
    [1473] = true,  -- Evoker: Augmentation
}
local SQW_PROC_REACTIVE = {
    [62]  = true, [63]  = true, [64]  = true,  -- Mage: Arcane / Fire / Frost
    [103] = true,                                -- Druid: Feral
    [262] = true, [263] = true,                  -- Shaman: Ele / Enh
    [577] = true, [581] = true,                  -- DH: Havoc / Vengeance
}
-- Everything not listed above falls into burst_precise (default)

--- Compute optimal SQW (ms) from current latency and active specialization.
--- Uses a "ping + offset" formula (community consensus: ping + 100–150ms),
--- with spec-aware tuning for different playstyle needs.
---
--- channel_heavy : ping + 130, clamped 130–250 ms — channels benefit from extra buffer
--- aug_evoker    : ping + 110, clamped 110–220 ms — empowered casts + buff timing
--- proc_reactive : ping + 90,  clamped 100–200 ms — tighter to avoid queuing wrong procs
--- burst_precise : ping + 100, clamped 110–220 ms — balanced default (default)
function ns.ComputeOptimalSQW()
    local _, _, homeMs, worldMs = GetNetStats()
    local ping = math.max(tonumber(homeMs) or 0, tonumber(worldMs) or 0)
    if ping <= 0 then return 150 end  -- safe default

    local specIndex = GetSpecialization and GetSpecialization()
    local specId = specIndex and GetSpecializationInfo(specIndex) or 0

    local raw
    if SQW_CHANNEL_HEAVY[specId] then
        raw = math.max(130, math.min(250, ping + 130))
    elseif SQW_AUG_EVOKER[specId] then
        raw = math.max(110, math.min(220, ping + 110))
    elseif SQW_PROC_REACTIVE[specId] then
        raw = math.max(100, math.min(200, ping + 90))
    else
        raw = math.max(110, math.min(220, ping + 100))
    end

    return math.floor((raw + 5) / 10) * 10  -- round to nearest 10
end

--- Return a human-readable label for the current spec's SQW profile.
function ns.GetSQWSpecProfile()
    local specIndex = GetSpecialization and GetSpecialization()
    local specId = specIndex and GetSpecializationInfo(specIndex) or 0
    if SQW_AUG_EVOKER[specId]   then return "Support / Empowered" end
    if SQW_CHANNEL_HEAVY[specId] then return "Channel-heavy" end
    if SQW_PROC_REACTIVE[specId] then return "Proc / Reactive" end
    return "Burst / Precise"
end

--- Apply the auto-optimized SQW if the feature is enabled.
local function ApplyAutoSQW(reason)
    local s = GetSettings()
    if not s or not s.sqwAutoOptimize then return end

    local optimal = ns.ComputeOptimalSQW()
    pcall(SetCVar, "SpellQueueWindow", tostring(optimal))
    -- Also update the saved manual value so the slider reflects the auto value
    -- when the settings panel is opened
    s.spellQueueWindow = optimal
end

local lastSpec = nil

local function OnSpecSwitchEditModeCheck()
    local settings = GetSettings()
    if not settings or not settings.checkEditmodeOnSpecSwitch then return end

    -- Give WoW a second to finish changing its internal layouts
    C_Timer.After(1.0, function()
        if not C_EditMode or not C_EditMode.GetLayouts then return end
        
        local layoutInfo = C_EditMode.GetLayouts()
        if not layoutInfo or not layoutInfo.activeLayout then return end
        
        local currentLayoutName = "Unknown"
        local gravityUILayoutID = nil
        
        -- Find current layout name and look for "GravityUI" layout ID
        for i, layout in ipairs(layoutInfo.layouts) do
            local id = layout.layoutIdentifier or layout.layoutID or layout.id
            if id and id == layoutInfo.activeLayout then
                currentLayoutName = layout.layoutName
            end
            if layout.layoutName == "GravityUI" then
                gravityUILayoutID = layout.layoutIdentifier or (i + 2) -- heuristic fallback
            end
        end
        
        if currentLayoutName == "Unknown" then
            local assumedIndex = layoutInfo.activeLayout - 2
            if assumedIndex > 0 and layoutInfo.layouts[assumedIndex] then
                currentLayoutName = layoutInfo.layouts[assumedIndex].layoutName
            end
        end
        
        -- If current is not GravityUI, and we found the GravityUI profile, prompt user
        if currentLayoutName ~= "GravityUI" and gravityUILayoutID then
            if not StaticPopupDialogs["GRAVITYUI_EDITMODE_SPEC_SWITCH"] then
                StaticPopupDialogs["GRAVITYUI_EDITMODE_SPEC_SWITCH"] = {
                    text = "Your Edit Mode profile is not GravityUI.\nWould you like to change it back to GravityUI?",
                    button1 = YES,
                    button2 = NO,
                    button3 = "Disable Check",
                    OnAccept = function(self, data)
                        if InCombatLockdown() then return end
                        -- Use the standardized Installer Sync logic for consistent scaling/positioning
                        local Installer = ns.GUI and ns.GUI.Installer
                        if Installer and Installer.Synchronize then
                            Installer:Synchronize("GravityUI", { ["EditMode"] = true })
                        else
                            -- Fallback if Installer not found
                            C_EditMode.SetActiveLayout(data)
                            C_Timer.After(0.5, function()
                                if EditModeManagerFrame and EditModeManagerFrame.UpdateActionBarLayouts then
                                    pcall(function() EditModeManagerFrame:UpdateActionBarLayouts() end)
                                end
                                pcall(function() EventRegistry:TriggerEvent("EditMode.ActiveLayoutChanged") end)
                            end)
                        end
                    end,
                    OnAlt = function(self)
                        local s = GetSettings()
                        if s then
                            s.checkEditmodeOnSpecSwitch = false
                            print("|cFF30D1FFGravityUI:|r Edit Mode Check on Spec Switch has been disabled.")
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3, -- Avoid UI taint where possible
                }
            end
            
            StaticPopup_Show("GRAVITYUI_EDITMODE_SPEC_SWITCH", "", "", gravityUILayoutID)
        end
    end)
end

---------------------------------------------------------------------------
-- EVENT REGISTRATION
---------------------------------------------------------------------------

-- Init Hooks immediately
InitMovieSkip()
InitAutoSkipCinematics()

automationFrame:RegisterEvent("ADDON_LOADED")
automationFrame:RegisterEvent("MERCHANT_SHOW")
automationFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
automationFrame:RegisterEvent("PARTY_INVITE_REQUEST")
automationFrame:RegisterEvent("QUEST_DETAIL")
automationFrame:RegisterEvent("QUEST_PROGRESS")
automationFrame:RegisterEvent("QUEST_COMPLETE")
automationFrame:RegisterEvent("QUEST_FINISHED")
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
automationFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
automationFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
automationFrame:RegisterEvent("CHAT_MSG_WHISPER")
automationFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
automationFrame:RegisterEvent("GROUP_ROSTER_UPDATE")


---------------------------------------------------------------------------
-- GROUP TOOLS: GUILD INVITE & AUTO ROLES
---------------------------------------------------------------------------

local function InviteGuildRanks()
    local settings = GetSettings()
    if not settings or not settings.tools or not settings.tools.guildInviteRanks then return end
    
    local numMembers = GetNumGuildMembers()
    local invited = 0
    local playerName = UnitName("player")
    
    for i = 1, numMembers do
        local name, _, rankIndex, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if online and name and settings.tools.guildInviteRanks[rankIndex] then
            -- Handle potential realm name in name
            local shortName = name:match("([^%-]+)") or name
            if shortName ~= playerName then
                C_PartyInfo.InviteUnit(name)
                invited = invited + 1
            end
        end
    end
    
    if invited > 0 then
        ns.Print("Invited " .. invited .. " guild members based on selected ranks.")
    else
        ns.Print("No online members found for selected ranks.")
    end
end

-- Slash command for guild invites
SLASH_GUIINV1 = "/guiinv"
SlashCmdList["GUIINV"] = function()
    InviteGuildRanks()
    -- Trigger role refresh in user context
    if ns.UpdateGroupRoles then ns.UpdateGroupRoles() end
end

-- Manual function for role assignment (User-initiated to allow protected SetPartyAssignment)
function ns.UpdateGroupRoles()
    if not IsInGroup() or not UnitIsGroupLeader("player") then 
        ns.Print("You must be the group leader to assign roles.")
        return 
    end
    local settings = GetSettings()
    if not settings or not settings.tools then return end
    
    local assistNames = settings.tools.autoAssistNames or ""
    if assistNames == "" then 
        ns.Print("Missing Auto Assist names in Tools configuration.")
        return 
    end
    
    local function IsInList(pName, pFullName, list)
        if not pName or not list or list == "" then return false end
        for part in string.gmatch(list, '([^,]+)') do
            local cleanPart = part:gsub("^%s*(.-)%s*$", "%1"):lower()
            if cleanPart == pName:lower() or (pFullName and cleanPart == pFullName:lower()) then
                return true
            end
        end
        return false
    end
    
    local numMembers = GetNumGroupMembers()
    local isRaid = IsInRaid()
    local count = 0
    
    for i = 1, numMembers do
        local unit = isRaid and ("raid"..i) or ("party"..i)
        if not UnitIsUnit(unit, "player") then
            local name = GetUnitName(unit, false)
            local fullName = GetUnitName(unit, true)
            
            if name then
                -- Assistant Promotion (Also check if missing)
                if isRaid and IsInList(name, fullName, assistNames) then
                    if not UnitIsGroupAssistant(unit) then
                        PromoteToAssistant(unit)
                        ns.Print("Promoted |cff00FF00" .. name .. "|r to Assistant.")
                        count = count + 1
                    end
                end
            end
        end
    end
    if count == 0 then ns.Print("Role check complete: No changes needed.") end
end

SLASH_GUIROLE1 = "/guirole"
SLASH_GUIROLE2 = "/guiroles"
SlashCmdList["GUIROLE"] = function()
    ns.UpdateGroupRoles()
end

local function AutoPromoteRoles()
    if not IsInGroup() or not UnitIsGroupLeader("player") then return end
    local settings = GetSettings()
    if not settings or not settings.tools then return end
    
    local assistNames = settings.tools.autoAssistNames or ""
    local tankNames = settings.tools.autoTankNames or ""
    
    if assistNames == "" and tankNames == "" then return end
    
    -- Helper to check if name is in comma-separated list
    local function IsInList(name, fullName, list)
        if not name or not list or list == "" then return false end
        for part in string.gmatch(list, '([^,]+)') do
            local cleanPart = part:gsub("^%s*(.-)%s*$", "%1"):lower()
            if cleanPart == name:lower() or (fullName and cleanPart == fullName:lower()) then
                return true
            end
        end
        return false
    end
    
    local numMembers = GetNumGroupMembers()
    local isRaid = IsInRaid()
    
    for i = 1, numMembers do
        local unit = isRaid and ("raid"..i) or ("party"..i)
        if not UnitIsUnit(unit, "player") then
            local name = GetUnitName(unit, false)
            local fullName = GetUnitName(unit, true)
            
            if name then
                -- Auto Assist (Raid only, typically not protected)
                if isRaid and IsInList(name, fullName, assistNames) then
                    if not UnitIsGroupAssistant(unit) then
                        PromoteToAssistant(unit)
                        ns.Print("Auto-Promoted |cff00FF00" .. name .. "|r to Assistant.")
                    end
                end
            end
        end
    end
end

automationFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_WHISPER" then
        -- TAINT SAFETY: CHAT_MSG_WHISPER sender (arg 2) is a secret string value.
        -- Reading it into a local in the outer event frame immediately taints that
        -- frame, propagating into Blizzard's own SetLastTellTarget which fires later
        -- in the same event dispatch — even if we defer our own logic via C_Timer.
        -- Fix: extract only msg (arg 1) here. Read sender inside a pcall so the
        -- secret value never exists in the outer stack frame. Then pass a clean,
        -- resolved string to the deferred OnWhisper call.
        local msg = (...)
        local senderResolved
        pcall(function(...) senderResolved = select(2, ...) end, ...)
        if senderResolved then
            C_Timer.After(0, function()
                OnWhisper(msg, senderResolved, false)
            end)
        end
        return
    elseif event == "CHAT_MSG_BN_WHISPER" then
        -- TAINT SAFETY: arg 13 (presenceID) may be secret in Midnight.
        -- Extract msg (arg1) and fallback character name (arg2) safely.
        local msg = (...)
        local bnSenderName, bnGameAccountID, bnFallbackName

        -- Arg 2 = sender character name in most WoW versions
        pcall(function(...) bnFallbackName = select(2, ...) end, ...)

        -- We cannot rely on C_BattleNet.GetAccountInfoByID(select(13, ...)) because arg 13 is deeply tainted in 11.0.
        -- We must dynamically resolve the BattleTag base name dynamically across our friend list.
        if bnFallbackName then
            pcall(function()
                local numFriends = BNGetNumFriends()
                for i = 1, numFriends do
                    local info = C_BattleNet.GetFriendAccountInfo(i)
                    if info and info.gameAccountInfo and info.gameAccountInfo.isOnline then
                        -- Isolate the "dpx" part from "dpx#1234"
                        local baseTag = info.accountName and string.match(info.accountName, "^([^#]+)") or ""
                        if baseTag == bnFallbackName or info.accountName == bnFallbackName then
                            local charName = info.gameAccountInfo.characterName
                            local realmName = info.gameAccountInfo.realmName
                            
                            if charName then
                                bnSenderName = realmName and (charName .. "-" .. realmName) or charName
                                bnGameAccountID = info.gameAccountInfo.gameAccountID
                                break
                            end
                        end
                    end
                end
            end)
        end

        -- Use best resolved name, fall back to arg 2
        local effectiveName = bnSenderName or bnFallbackName
        if effectiveName then
            local capturedID = bnGameAccountID
            C_Timer.After(0, function()
                OnWhisper(msg, effectiveName, true, capturedID)
            end)
        end
        return
    end

    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Blizzard_LFGList" then
            OverrideLfgApplicationDialog()
            InjectRoleTogglesLFG()
        end
    elseif event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "LFG_ROLE_CHECK_SHOW" then
        OnRoleCheckShow()
    elseif event == "PARTY_INVITE_REQUEST" then
        OnPartyInvite(...)
    elseif event == "QUEST_DETAIL" then
        OnQuestDetail()
    elseif event == "QUEST_PROGRESS" then
        OnQuestProgress()
    elseif event == "QUEST_COMPLETE" then
        OnQuestComplete()
    elseif event == "QUEST_FINISHED" then
        OnQuestFinished()
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
             lastSpec = ns.GetSpecialization()
             local s = GetSettings()
             if s then
                 -- TAINT FIX: Defer SetCVar calls out of the PLAYER_ENTERING_WORLD
                 -- event handler. SetCVar synchronously triggers Blizzard's internal
                 -- Settings → CallbackRegistry chain, which contains protected
                 -- callbacks. Calling from within the event handler taints the
                 -- entire chain, producing ADDON_ACTION_FORBIDDEN 'callback()'.
                 C_Timer.After(0, function()
                     if s.showDamageNumbers ~= nil then pcall(SetCVar, "floatingCombatTextCombatDamage", s.showDamageNumbers and "1" or "0") end
                     if s.showHealingNumbers ~= nil then pcall(SetCVar, "floatingCombatTextCombatHealing", s.showHealingNumbers and "1" or "0") end
                     -- SQW: auto-optimize overrides manual value on login
                     if s.sqwAutoOptimize then
                         ApplyAutoSQW("login")
                     elseif s.spellQueueWindow then
                         pcall(SetCVar, "SpellQueueWindow", tostring(s.spellQueueWindow))
                     end
                 end)
                 
                 if s.deleteFix then SmartDelete:InitHooks() end
             end
             OverrideLfgApplicationDialog()
             InjectRoleTogglesLFG()
        end
        if not resumeLoggingPending then
            resumeLoggingPending = true
            C_Timer.After(2, CheckResumeLogging)
        end
    elseif event == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" then
        OnKeyStoneInsert()
    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        C_Timer.After(0.1, InjectGravityLfgListeners)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit == "player" then
            local currentSpec = ns.GetSpecialization()
            if lastSpec and currentSpec and currentSpec ~= lastSpec then
                lastSpec = currentSpec
                OnSpecSwitchEditModeCheck()
                ApplyAutoSQW("spec_change")
            elseif not lastSpec and currentSpec then
                lastSpec = currentSpec
            end
        end
    elseif event == "AUCTION_HOUSE_SHOW" then
        OnAuctionHouseShow()
    elseif event == "GROUP_ROSTER_UPDATE" then
        AutoPromoteRoles()
    end
end)

---------------------------------------------------------------------------
-- DEBUG: /gravitycombatlog  (alias: /gcl)
---------------------------------------------------------------------------
local DIFFICULTY_NAMES = {
    [1]  = "Normal (Dungeon)",
    [2]  = "Heroic (Dungeon)",
    [14] = "Normal (Raid)",
    [15] = "Heroic (Raid)",
    [16] = "Mythic (Raid, fixed 20)",
    [23] = "Mythic (Dungeon)",
    [24] = "Timewalking (Dungeon)",
    [33] = "Timewalking (Raid)",
    [233] = "Mythic Flex (Raid, Sporefall+)",
}

local function CombatLogDebug()
    local settings = GetSettings()
    local p = ns.Print or function(m) print("|cFF30D1FFGravityUI:|r " .. m) end

    p("=== Combat Log Debug ===")

    -- Instance info
    local name, instanceType, difficultyID, difficultyName = GetInstanceInfo()
    local inChallenge = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
    local isLogging = LoggingCombat()

    p(string.format("Instance:   |cFFFFFF00%s|r  (type: %s)", name or "None", instanceType or "none"))
    p(string.format("Difficulty: |cFFFFFF00%s|r  (ID: %d)", difficultyName or "Unknown", difficultyID or 0))
    p(string.format("M+ Active:  |cFF%s%s|r", inChallenge and "00FF00" or "FF4444", inChallenge and "YES" or "NO"))
    p(string.format("Logging:    |cFF%s%s|r", isLogging and "00FF00" or "FF4444", isLogging and "ACTIVE ✓" or "INACTIVE ✗"))

    p("--- Settings ---")
    if not settings then
        p("|cFFFF4444Settings not found!|r")
        return
    end

    -- M+
    local mLog = settings.autoCombatLog
    p(string.format("Auto Log M+:            |cFF%s%s|r", mLog and "00FF00" or "FF4444", mLog and "ON" or "OFF"))

    -- Raid
    local rN = settings.autoCombatLogRaidNormal
    local rH = settings.autoCombatLogRaidHeroic
    local rM = settings.autoCombatLogRaidMythic
    p(string.format("Auto Log Raid Normal:   |cFF%s%s|r", rN and "00FF00" or "FF4444", rN and "ON" or "OFF"))
    p(string.format("Auto Log Raid Heroic:   |cFF%s%s|r", rH and "00FF00" or "FF4444", rH and "ON" or "OFF"))
    p(string.format("Auto Log Raid Mythic:   |cFF%s%s|r", rM and "00FF00" or "FF4444", rM and "ON" or "OFF"))

    -- Would it log?
    p("--- Logic Check ---")
    local wouldLog = false
    local reason = "No condition matched"
    if instanceType == "party" and inChallenge and mLog then
        wouldLog = true; reason = "M+ is active + Auto Log M+ = ON"
    elseif instanceType == "raid" then
        local lowerDiffName = difficultyName and difficultyName:lower() or ""
        if difficultyID == 14 and rN then wouldLog = true; reason = "Raid Normal + Auto Log Normal = ON"
        elseif difficultyID == 15 and rH then wouldLog = true; reason = "Raid Heroic + Auto Log Heroic = ON"
        elseif difficultyID == 16 and rM then wouldLog = true; reason = "Raid Mythic (fixed 20) + Auto Log Mythic = ON"
        elseif difficultyID == 233 and rM then wouldLog = true; reason = "Raid Mythic Flex (ID 233, Sporefall+) + Auto Log Mythic = ON"
        -- Fallback name-match for unknown future IDs
        elseif rN and lowerDiffName:find("normal") then wouldLog = true; reason = "Raid Normal (name match) + Auto Log Normal = ON"
        elseif rH and lowerDiffName:find("heroic") then wouldLog = true; reason = "Raid Heroic (name match) + Auto Log Heroic = ON"
        elseif rM and lowerDiffName:find("mythic") then wouldLog = true; reason = "Raid Mythic (name match) + Auto Log Mythic = ON"
        end
        if not wouldLog then
            reason = string.format("Raid (diff %d / '%s') but matching toggle is OFF", difficultyID or 0, difficultyName or "?")
        end
    end
    p(string.format("Should Log: |cFF%s%s|r  → %s",
        wouldLog and "00FF00" or "FF4444",
        wouldLog and "YES ✓" or "NO ✗",
        reason))
    p("========================")
end

SLASH_GRAVITYCOMBATLOG1 = "/gravitycombatlog"
SLASH_GRAVITYCOMBATLOG2 = "/gcl"
SLASH_GRAVITYCOMBATLOG3 = "/glog"
SLASH_GRAVITYCOMBATLOG4 = "/gravitylog"

SlashCmdList["GRAVITYCOMBATLOG"] = function(msg)
    if msg and msg:lower() == "toggle" then
        local newState = not LoggingCombat()
        LoggingCombat(newState)
        print(string.format("|cFF30D1FFGravityUI:|r Combat logging manually %s.", newState and "|cFF00FF00STARTED|r" or "|cFFFF4444STOPPED|r"))
    else
        CombatLogDebug()
    end
end

---------------------------------------------------------------------------
-- BONUS ROLL FRAME: SAFE REPOSITIONING + EDIT MODE MOVER
--
-- BonusRollFrame contains SecureActionButtons (Roll / Pass). Any direct
-- modification (SetMovable, child frames, RegisterForDrag) taints the secure
-- hierarchy and makes those buttons unclickable.
--
-- Solution: a non-secure PROXY FRAME that:
--   1. Appears in Blizzard's Edit Mode under "GravityUI Elements"
--   2. Is freely draggable (not secure → no taint)
--   3. Saves its position to GravityUI_BonusRollPos on drag-stop
--   4. When the REAL BonusRollFrame appears, it is silently repositioned
--      to that saved location without touching its mouse handlers.
---------------------------------------------------------------------------

local BONUS_ROLL_DEFAULT_POINT    = "TOP"
local BONUS_ROLL_DEFAULT_RELPOINT = "TOP"
local BONUS_ROLL_DEFAULT_X        = 0
local BONUS_ROLL_DEFAULT_Y        = -200   -- 200px below top edge

local bonusRollRepositionHooked = false
local bonusRollPreview          = nil

-- Returns the saved anchor or the default one
local function GetBonusRollPos()
    -- One-time migration from old standalone SavedVariable
    if GravityUI_BonusRollPos and ns.db and ns.db.profile and ns.db.profile.styling and ns.db.profile.styling.lootRoll then
        if not ns.db.profile.styling.lootRoll.bonusRollPos then
            ns.db.profile.styling.lootRoll.bonusRollPos = GravityUI_BonusRollPos
        end
        GravityUI_BonusRollPos = nil  -- clear old global
    end
    local pos = ns.db and ns.db.profile and ns.db.profile.styling and
                ns.db.profile.styling.lootRoll and ns.db.profile.styling.lootRoll.bonusRollPos
    if pos and pos.point and pos.x and pos.y then
        return pos.point, pos.relPoint or pos.point, pos.x, pos.y
    end
    return BONUS_ROLL_DEFAULT_POINT, BONUS_ROLL_DEFAULT_RELPOINT,
           BONUS_ROLL_DEFAULT_X,     BONUS_ROLL_DEFAULT_Y
end

-- Save position from any frame into the main GravityUI_DB
local function SaveBonusRollPos(frame)
    local p, _, rp, ox, oy = frame:GetPoint()
    if p and ns.db and ns.db.profile and ns.db.profile.styling and ns.db.profile.styling.lootRoll then
        ns.db.profile.styling.lootRoll.bonusRollPos = { point = p, relPoint = rp or p, x = ox, y = oy }
    end
end

-- Move the REAL bonus roll frame to the saved position
local function RepositionBonusRollFrame()
    if not BonusRollFrame then return end
    local point, relPoint, x, y = GetBonusRollPos()
    C_Timer.After(0, function()
        if BonusRollFrame and BonusRollFrame:IsShown() then
            BonusRollFrame:ClearAllPoints()
            BonusRollFrame:SetPoint(point, UIParent, relPoint, x, y)
        end
    end)
end

-- Hook BonusRollFrame:OnShow once it exists
local function HookBonusRollReposition()
    if bonusRollRepositionHooked then return end
    if not BonusRollFrame then return end
    bonusRollRepositionHooked = true
    BonusRollFrame:HookScript("OnShow", RepositionBonusRollFrame)
end

-- -----------------------------------------------------------------------
-- EDIT MODE PROXY FRAME
-- A draggable placeholder that looks like BonusRollFrame and is shown
-- only when the user enables "Show GravityUI Elements" in Edit Mode.
-- -----------------------------------------------------------------------
local function CreateBonusRollPreview()
    if bonusRollPreview then return bonusRollPreview end

    local f = CreateFrame("Frame", "GravityUI_BonusRollPreview", UIParent, "BackdropTemplate")
    -- Approximate BonusRollFrame dimensions (350 x 54px in Retail)
    f:SetSize(350, 54)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetFrameStrata("HIGH")

    -- Visual: styled to look like the real frame
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    f:SetBackdropBorderColor(0.85, 0.65, 0.1, 1)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("LEFT", f, "LEFT", 7, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Dice_02")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 4)
    title:SetText("|cFFFFCC00Bonus Loot|r")
    title:SetTextColor(1, 0.82, 0)

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetPoint("LEFT", icon, "RIGHT", 8, -10)
    sub:SetText("|cFFAAAAAAgravityUI Edit Mode Mover|r")

    -- Drag behaviour: save position on release
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveBonusRollPos(self)
    end)

    f:Hide() -- hidden by default; Movers toggles visibility
    bonusRollPreview = f
    return f
end

-- Register the proxy with the Movers system so it appears in Edit Mode.
-- Called after PLAYER_LOGIN so ns.Movers is guaranteed to exist.
local function RegisterBonusRollMover()
    if not ns.Movers then return end
    local preview = CreateBonusRollPreview()

    ns.Movers:Register("BonusRoll", preview, function(frame, shouldShow)
        if shouldShow then
            -- Snap preview to current saved position before showing
            local point, relPoint, x, y = GetBonusRollPos()
            frame:ClearAllPoints()
            frame:SetPoint(point, UIParent, relPoint, x, y)
            frame:Show()
            ns.Movers:ApplyEditModeStyle(frame, true)
        else
            ns.Movers:ApplyEditModeStyle(frame, false)
            frame:Hide()
        end
    end, "Bonus Loot")
end

-- Init: hook BonusRollFrame reposition + register mover on login
local bonusRollInitFrame = CreateFrame("Frame")
bonusRollInitFrame:RegisterEvent("PLAYER_LOGIN")
bonusRollInitFrame:RegisterEvent("BONUS_ROLL_STARTED")
bonusRollInitFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        RegisterBonusRollMover()
        if BonusRollFrame then HookBonusRollReposition() end

        -- Guard: when GroupLootHistoryFrame opens/closes, Blizzard reshuffles
        -- DIALOG frame-levels which can cause BonusRollFrame to lose its anchor.
        -- Re-apply our saved position after each shuffle.
        C_Timer.After(2, function()
            local hist = _G.GroupLootHistoryFrame
            if hist then
                hist:HookScript("OnShow", function()
                    RepositionBonusRollFrame()
                end)
                hist:HookScript("OnHide", function()
                    RepositionBonusRollFrame()
                end)
            end
        end)
    elseif event == "BONUS_ROLL_STARTED" then
        if BonusRollFrame then HookBonusRollReposition() end
        self:UnregisterEvent("BONUS_ROLL_STARTED")
    end
end)

---------------------------------------------------------------------------
-- Slash: /bonusroll [reset|top|center|bottom]
---------------------------------------------------------------------------
SLASH_GRAVITYBONUSROLL1 = "/gravitybonusroll"
SLASH_GRAVITYBONUSROLL2 = "/bonusroll"
SlashCmdList["GRAVITYBONUSROLL"] = function(msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""

    local presets = {
        reset  = { "TOP",    "TOP",    0,  -200 },
        top    = { "TOP",    "TOP",    0,  -100 },
        center = { "CENTER", "CENTER", 0,     0 },
        bottom = { "BOTTOM", "BOTTOM", 0,   100 },
    }

    local preset = presets[msg]
    if preset then
        if ns.db and ns.db.profile and ns.db.profile.styling and ns.db.profile.styling.lootRoll then
            ns.db.profile.styling.lootRoll.bonusRollPos = { point = preset[1], relPoint = preset[2],
                                                            x = preset[3],     y = preset[4] }
        end
        -- Move real frame if currently visible
        if BonusRollFrame and BonusRollFrame:IsShown() then
            BonusRollFrame:ClearAllPoints()
            BonusRollFrame:SetPoint(preset[1], UIParent, preset[2], preset[3], preset[4])
        end
        -- Snap preview too if Edit Mode is open
        if bonusRollPreview and bonusRollPreview:IsShown() then
            bonusRollPreview:ClearAllPoints()
            bonusRollPreview:SetPoint(preset[1], UIParent, preset[2], preset[3], preset[4])
        end
        print(string.format("|cFF30D1FFGravityUI:|r Bonus Roll position set to '%s'.", msg))
    else
        print("|cFF30D1FFGravityUI:|r Usage: /bonusroll [reset|top|center|bottom]")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- QOL 1.1: AUTO OPEN CONTAINERS
-- ═══════════════════════════════════════════════════════════════
local _openableCache = {}
local _openBusy = false

local function IsWarboundExcluded(bag, slot)
    local settings = GetSettings()
    if not settings or settings.autoOpenContainersExcludeWarbound == false then return false end
    if not (C_Bank and C_Bank.IsItemAllowedInBankType and ItemLocation and C_Item and C_Item.DoesItemExist) then return false end
    local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not (loc and C_Item.DoesItemExist(loc)) then return false end
    return C_Bank.IsItemAllowedInBankType(Enum.BankType.Account, loc) and true or false
end

local function IsOpenable(itemID, bag, slot)
    local cached = _openableCache[itemID]
    if cached ~= nil then return cached end
    local tip = C_TooltipInfo and C_TooltipInfo.GetBagItem and C_TooltipInfo.GetBagItem(bag, slot)
    if tip and tip.lines then
        for _, line in ipairs(tip.lines) do
            if line and line.leftText and line.leftText == ITEM_OPENABLE then
                _openableCache[itemID] = true
                return true
            end
        end
    end
    _openableCache[itemID] = false
    return false
end

local function ScanAndOpenContainers()
    local settings = GetSettings()
    if not (settings and settings.autoOpenContainers) then return end
    if InCombatLockdown() or (MerchantFrame and MerchantFrame:IsShown()) then return end
    if _openBusy then return end

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID and not info.isLocked then
                if not IsWarboundExcluded(bag, slot) and IsOpenable(info.itemID, bag, slot) then
                    _openBusy = true
                    C_Container.UseContainerItem(bag, slot)
                    C_Timer.After(0.4, function()
                        _openBusy = false
                        ScanAndOpenContainers()
                    end)
                    return
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- QOL 1.2: HIDE ITEM TRANSFORMS (COSMETIC FILTER)
-- ═══════════════════════════════════════════════════════════════
local TRANSFORM_SPELLS = {
    [67531] = true, -- Chef's Hat
    [16591] = true, -- Noggenfogger (Skeleton)
    [16595] = true, -- Noggenfogger (Small)
    [8063]  = true, -- Deviate Fish (Ninja)
    [8064]  = true, -- Deviate Fish (Pirate)
    [8219]  = true, -- Savory Deviate Delight
    [16379] = true, -- Gamon's Braid
    [9264]  = true, -- Elixir of Giant Growth
    [44654] = true, -- Stylin' Purple Hat
    [61989] = true, -- Stylin' Crimson Hat
    [61990] = true, -- Stylin' Adventure Hat
    [61991] = true, -- Stylin' Jungle Hat
}

local pendingTransformRemoval = false

local function CleanTransforms()
    local settings = GetSettings()
    if not (settings and settings.hideTransforms) then return end

    if InCombatLockdown() then
        pendingTransformRemoval = true
        return
    end

    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        for sid in pairs(TRANSFORM_SPELLS) do
            local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, sid)
            if ok and aura and aura.name and (not issecretvalue or not issecretvalue(aura.name)) then
                if CancelSpellByName then
                    pcall(CancelSpellByName, aura.name)
                end
            end
        end
    elseif C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or not aura then break end
            local sid = tonumber(aura.spellId)
            if sid and TRANSFORM_SPELLS[sid] then
                if CancelSpellByName and aura.name and (not issecretvalue or not issecretvalue(aura.name)) then
                    pcall(CancelSpellByName, aura.name)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- QOL 1.3: AUTO UNWRAP COLLECTIONS
-- ═══════════════════════════════════════════════════════════════
local function AckMountAlerts()
    if not (C_MountJournal and C_MountJournal.GetNumMountsNeedingFanfare and C_MountJournal.ClearFanfare) then return false end
    local pending = C_MountJournal.GetNumMountsNeedingFanfare()
    if not pending or pending <= 0 then return false end

    for i = 1, C_MountJournal.GetNumDisplayedMounts() do
        local id = C_MountJournal.GetDisplayedMountID(i)
        if id and C_MountJournal.NeedsFanfare and C_MountJournal.NeedsFanfare(id) then
            C_MountJournal.ClearFanfare(id)
        end
    end
    return true
end

local function AckPetAlerts()
    if not (C_PetJournal and C_PetJournal.GetNumPetsNeedingFanfare and C_PetJournal.ClearFanfare) then return false end
    if (C_PetJournal.GetNumPetsNeedingFanfare() or 0) == 0 then return false end
    local any = false
    for _, id in ipairs(C_PetJournal.GetOwnedPetIDs and C_PetJournal.GetOwnedPetIDs() or {}) do
        if id and C_PetJournal.PetNeedsFanfare and C_PetJournal.PetNeedsFanfare(id) then
            C_PetJournal.ClearFanfare(id)
            any = true
        end
    end
    return any
end

local function AckToyAlerts()
    if not (C_ToyBoxInfo and C_ToyBoxInfo.ClearFanfare) then return false end
    local any = false
    if ToyBox and ToyBox.fanfareToys then
        for id, needs in pairs(ToyBox.fanfareToys) do
            if needs and id and C_ToyBoxInfo.NeedsFanfare and C_ToyBoxInfo.NeedsFanfare(id) then
                C_ToyBoxInfo.ClearFanfare(id)
                any = true
            end
        end
    end
    return any
end

local function DismissCollectionAlerts()
    local settings = GetSettings()
    if not (settings and settings.autoUnwrapCollections) then return end

    AckMountAlerts()
    AckPetAlerts()
    AckToyAlerts()
end

local function SetupAutoUnwrap()
    if MainMenuMicroButton_ShowAlert then
        hooksecurefunc("MainMenuMicroButton_ShowAlert", function(_, text)
            local settings = GetSettings()
            if not (settings and settings.autoUnwrapCollections) then return end
            if text == COLLECTION_UNOPENED_PLURAL or text == COLLECTION_UNOPENED_SINGULAR then
                C_Timer.After(0.2, DismissCollectionAlerts)
            end
        end)
    end
    C_Timer.After(3, DismissCollectionAlerts)
end

-- ═══════════════════════════════════════════════════════════════
-- QOL 1.4: TRAIN ALL BUTTON
-- ═══════════════════════════════════════════════════════════════
local function AddTrainAllButton()
    if not ClassTrainerFrame or ClassTrainerFrame._trainAllBtn then return end

    local trainBtn = ClassTrainerTrainButton
    if not trainBtn then return end

    local btn = CreateFrame("Button", "GravityUI_TrainAllButton", ClassTrainerFrame, "UIPanelButtonTemplate")
    btn:SetSize(100, trainBtn:GetHeight() or 22)
    btn:SetPoint("RIGHT", trainBtn, "LEFT", -6, 0)
    btn:SetText("Train All")
    ClassTrainerFrame._trainAllBtn = btn

    btn:SetScript("OnClick", function()
        local num = GetNumTrainerServices()
        for i = 1, num do
            local _, _, serviceType = GetTrainerServiceInfo(i)
            if serviceType == "available" then
                BuyTrainerService(i)
            end
        end
    end)

    hooksecurefunc("ClassTrainerFrame_Update", function()
        local settings = GetSettings()
        if not (settings and settings.trainAllButton) then
            btn:Hide()
            return
        end

        local num = GetNumTrainerServices()
        local hasAvailable = false
        for i = 1, num do
            local _, _, serviceType = GetTrainerServiceInfo(i)
            if serviceType == "available" then
                hasAvailable = true
                break
            end
        end
        btn:SetShown(hasAvailable)
        btn:SetEnabled(hasAvailable)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- QOL 1.5: ANNOUNCE INSTANCE RESET
-- ═══════════════════════════════════════════════════════════════
local function HandleInstanceResetMsg(msg)
    local settings = GetSettings()
    if not (settings and settings.instanceResetAnnounce) then return end
    if not (IsInGroup() or IsInRaid()) then return end
    if not msg or type(msg) ~= "string" or (issecretvalue and issecretvalue(msg)) then return end

    -- Check for instance reset system message pattern safely without indexing secret values
    local resetPattern = (INSTANCE_RESET_SUCCESS and string.gsub(INSTANCE_RESET_SUCCESS, "%%s", ".+")) or "has been reset"
    local isMatch = false
    local ok, found = pcall(function()
        return string.find(msg, resetPattern)
    end)
    if ok and found then
        isMatch = true
    end

    if isMatch then
        local channel = IsInRaid() and "RAID" or "PARTY"
        pcall(SendChatMessage, "GravityUI: " .. msg, channel)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- EVENT LISTENERS FOR QOL 1.1 - 1.5
-- ═══════════════════════════════════════════════════════════════
local qolEventFrame = CreateFrame("Frame")
qolEventFrame:RegisterEvent("PLAYER_LOGIN")
qolEventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
qolEventFrame:RegisterUnitEvent("UNIT_AURA", "player")
qolEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
qolEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
qolEventFrame:RegisterEvent("ADDON_LOADED")

qolEventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        SetupAutoUnwrap()
        C_Timer.After(2, ScanAndOpenContainers)
        CleanTransforms()
    elseif event == "BAG_UPDATE_DELAYED" then
        ScanAndOpenContainers()
    elseif event == "UNIT_AURA" then
        if arg1 == "player" then C_Timer.After(0, CleanTransforms) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingTransformRemoval then
            pendingTransformRemoval = false
            CleanTransforms()
        end
        ScanAndOpenContainers()
    elseif event == "CHAT_MSG_SYSTEM" then
        HandleInstanceResetMsg(arg1)
    elseif event == "ADDON_LOADED" then
        if arg1 == "Blizzard_TrainerUI" or ClassTrainerFrame then
            AddTrainAllButton()
        end
    end
end)

