local ADDON_NAME, ns = ...
local Mail = {}
ns.Mail = Mail
LibStub("AceEvent-3.0"):Embed(Mail)

-- ============================================================================
-- CONSTANTS & VARIABLES
-- ============================================================================
local L = ns.L -- Optional if you have localization
local OpenAllButton, AddressBookButton
local isOpeningAll = false
local totalGoldLooted = 0
local lootUpdateFrame = CreateFrame("Frame")
lootUpdateFrame:Hide()

local recentMails = {}
local altList = {}

-- WoW 10.0+ requires PLAYER_INTERACTION_MANAGER_FRAME_SHOW
local interactionTypeMail = Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo or 17

-- ============================================================================
-- HELPERS
-- ============================================================================
local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.mail then
        return db.uiimprovements.mail
    end
    return nil
end

local function FormatMoneyWithIcons(money)
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    
    local str = ""
    if gold > 0 then str = str .. gold .. " |TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t " end
    if silver > 0 then str = str .. silver .. " |TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t " end
    if copper > 0 or str == "" then str = str .. copper .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t" end
    return str
end

-- ============================================================================
-- OPEN ALL LOGIC
-- ============================================================================
local function ProcessNextMail()
    if not isOpeningAll then return end
    
    local numItems, totalItems = GetInboxNumItems()
    if numItems == 0 then
        -- Done!
        isOpeningAll = false
        OpenAllButton:SetText("Open All")
        ns.Print("Finished opening all mail.")
        if totalGoldLooted > 0 then
            ns.Print("|cFF00FF00Looted:|r " .. FormatMoneyWithIcons(totalGoldLooted))
        end
        return
    end
    
    -- Check if we can loot the first mail
    local _, _, sender, _, money, CODAmount, _, hasItem, _, _, _, _, isGM = GetInboxHeaderInfo(1)
    
    if (CODAmount and CODAmount > 0) or isGM then
        -- Skip COD or GM mail
        ns.Print("Skipped COD/GM mail from " .. tostring(sender) .. ".")
        -- You would normally move to the next index, but the API automatically shifts messages 
        -- down when one is fully deleted. Since we can't delete a COD mail without paying, 
        -- a simple robust implementation is to just stop the process here or skip it by 
        -- keeping track of an offset. For simplicity in a basic module, we stop.
        isOpeningAll = false
        OpenAllButton:SetText("Open All")
        return
    end

    -- Has item to loot?
    if hasItem then
        -- Just take the first attachment
        TakeInboxItem(1, 1)
        lootUpdateFrame.waitTimer = 0.3 -- Wait a bit for the server to process
        lootUpdateFrame:Show()
        return
    end
    
    -- Has money to loot?
    if money > 0 then
        totalGoldLooted = totalGoldLooted + money
        TakeInboxMoney(1, money)
        lootUpdateFrame.waitTimer = 0.3
        lootUpdateFrame:Show()
        return
    end
    
    -- Mail is empty, delete it
    DeleteInboxItem(1)
    lootUpdateFrame.waitTimer = 0.3
    lootUpdateFrame:Show()
end

lootUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    if self.waitTimer > 0 then
        self.waitTimer = self.waitTimer - elapsed
    else
        self:Hide()
        ProcessNextMail()
    end
end)

local function OnOpenAllClicked()
    local s = GetSettings()
    if not s or not s.enabled or not s.openAll then return end
    
    if isOpeningAll then
        -- Stop
        isOpeningAll = false
        OpenAllButton:SetText("Open All")
        return
    end
    
    isOpeningAll = true
    totalGoldLooted = 0
    OpenAllButton:SetText("Stop")
    ProcessNextMail()
end

-- ============================================================================
-- ADDRESS BOOK LOGIC
-- ============================================================================
local function PopulateAlts()
    local realm = GetRealmName()
    local faction = UnitFactionGroup("player")
    local player = UnitName("player")
    local class = select(2, UnitClass("player"))
    local level = UnitLevel("player")
    
    local db = ns.db.global
    if not db.mailAlts then db.mailAlts = {} end
    
    local altString = string.format("%s|%s|%s|%s|%s", player, realm, faction, class, level)
    
    -- Remove self if existing to update level/class, then re-insert
    for i = #db.mailAlts, 1, -1 do
        local p, r, f = strsplit("|", db.mailAlts[i])
        if p == player and r == realm and f == faction then
            table.remove(db.mailAlts, i)
        end
    end
    table.insert(db.mailAlts, altString)
end

local function SetSendMailTarget(name)
    if SendMailNameEditBox then
        SendMailNameEditBox:SetText(name)
        SendMailNameEditBox:HighlightText()
        if SendMailSubjectEditBox then
            SendMailSubjectEditBox:SetFocus()
        end
    end
    CloseDropDownMenus()
end

local function BuildAddressBookMenu(frame, level, menuList)
    if not level then return end
    
    local info = UIDropDownMenu_CreateInfo()
    local s = GetSettings()
    if not s then return end

    if level == 1 then
        info.isTitle = true
        info.text = "GravityUI Address Book"
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)

        info.isTitle = false
        info.disabled = false
        info.notCheckable = true
        
        -- Contacts Base
        if s.contacts and #s.contacts > 0 then
            for _, name in ipairs(s.contacts) do
                info.text = name
                info.arg1 = name
                info.func = function(_, arg1) SetSendMailTarget(arg1) end
                UIDropDownMenu_AddButton(info, level)
            end
        end
        
        -- Add/Remove Contacts logic based on current input
        local currentName = SendMailNameEditBox and strtrim(SendMailNameEditBox:GetText()) or ""
        if currentName ~= "" then
            local isContact = false
            if s.contacts then
                for _, name in ipairs(s.contacts) do
                    if string.lower(name) == string.lower(currentName) then
                        isContact = true
                        break
                    end
                end
            end
            
            info.text = nil
            info.func = nil
            info.arg1 = nil
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
            info.disabled = false
            
            if isContact then
                info.text = "Remove Contact: " .. currentName
                info.func = function()
                    for i, name in ipairs(s.contacts) do
                        if string.lower(name) == string.lower(currentName) then
                            table.remove(s.contacts, i)
                            ns.Print("Removed " .. currentName .. " from Contacts.")
                            break
                        end
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            else
                info.text = "Add Contact: " .. currentName
                info.func = function()
                    if not s.contacts then s.contacts = {} end
                    table.insert(s.contacts, currentName)
                    table.sort(s.contacts)
                    ns.Print("Added " .. currentName .. " to Contacts.")
                end
                UIDropDownMenu_AddButton(info, level)
            end
            
            info.text = nil
            info.func = nil
            info.arg1 = nil
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
            info.disabled = false
        end
        
        -- Alts Menu
        info.text = "Alts"
        info.hasArrow = true
        info.menuList = "alts"
        info.func = nil
        UIDropDownMenu_AddButton(info, level)
        
        -- Guild Menu
        info.text = "Guild"
        info.hasArrow = true
        info.menuList = "guild"
        info.func = nil
        UIDropDownMenu_AddButton(info, level)
        
        -- Friends Menu
        info.text = "Friends"
        info.hasArrow = true
        info.menuList = "friends"
        info.func = nil
        UIDropDownMenu_AddButton(info, level)
        
    elseif level == 2 then
        info.notCheckable = true
        if menuList == "alts" then
            local db = ns.db.global
            if db and db.mailAlts then
                local realm = GetRealmName()
                local faction = UnitFactionGroup("player")
                local player = UnitName("player")
                for _, altData in ipairs(db.mailAlts) do
                    local p, r, f, c, l = strsplit("|", altData)
                    -- Show all same-faction alts. For cross-realm, we need to format the target string
                    if f == faction and p ~= player then
                        local classColor = c and RAID_CLASS_COLORS[c]
                        local colorStr = classColor and string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255) or "|cFFFFFFFF"
                        
                        local rFormatted = r:gsub("%s+", "")
                        local targetStr = (r == realm) and p or (p .. "-" .. rFormatted)
                        
                        -- For display, only append realm if it's different
                        local displayStr = (r == realm) and p or (p .. "-" .. r)
                        
                        info.text = string.format("%s%s|r |cFFFFFFFF(%s)|r", colorStr, displayStr, l or "?")
                        info.arg1 = targetStr
                        info.func = function(_, arg1) SetSendMailTarget(arg1) end
                        UIDropDownMenu_AddButton(info, level)
                    end
                end
            end
        elseif menuList == "guild" then
            if IsInGuild() then
                for i = 1, GetNumGuildMembers() do
                    local name, _, _, charLevel, _, _, _, _, online, _, classFileName = GetGuildRosterInfo(i)
                    if name and online then
                        local classColor = RAID_CLASS_COLORS[classFileName]
                        local colorStr = classColor and string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255) or "|cFFFFFFFF"
                        -- The name from GetGuildRosterInfo already includes the realm if they are cross-realm!
                        local shortName = strsplit("-", name)
                        -- Display short name to save space, but if they have a realm attached, show it
                        local displayStr = (name == shortName) and shortName or name
                        info.text = string.format("%s%s|r |cFFFFFFFF(%s)|r", colorStr, displayStr, charLevel)
                        info.arg1 = name -- Important! Use the full name including realm
                        info.func = function(_, arg1) SetSendMailTarget(arg1) end
                        UIDropDownMenu_AddButton(info, level)
                    end
                end
            end
        elseif menuList == "friends" then
             local numFriends = C_FriendList.GetNumFriends()
             for i = 1, numFriends do
                 local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
                 if friendInfo and friendInfo.connected then
                     info.text = friendInfo.name
                     info.arg1 = friendInfo.name
                     info.func = function(_, arg1) SetSendMailTarget(arg1) end
                     UIDropDownMenu_AddButton(info, level)
                 end
             end
             
             local numBNet, numBNetOnline = BNGetNumFriends()
             for i = 1, numBNetOnline do
                 local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                 if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName then
                     if accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW and accountInfo.gameAccountInfo.wowProjectID == 1 then
                         local charName = accountInfo.gameAccountInfo.characterName
                         local altRealm = accountInfo.gameAccountInfo.realmName
                         local fullCharName = altRealm and (charName .. "-" .. altRealm:gsub("%s+", "")) or charName
                         
                         local classColor = RAID_CLASS_COLORS[accountInfo.gameAccountInfo.className]
                         local colorStr = classColor and string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255) or "|cFFFFFFFF"
                         
                         info.text = string.format("%s |cFFFFFFFF-|r %s%s|r |cFFFFFFFF(%s)|r", accountInfo.accountName, colorStr, fullCharName, accountInfo.gameAccountInfo.characterLevel or "?")
                         info.arg1 = fullCharName
                         info.func = function(_, arg1) SetSendMailTarget(arg1) end
                         UIDropDownMenu_AddButton(info, level)
                     end
                 end
             end
        end
    end
end

-- Hook SendMail to save recent targets
local hasHookedSendMail = false
local function HookSendMail()
    if hasHookedSendMail then return end
    hooksecurefunc("SendMail", function(target, subject, body)
        local name = strtrim(tostring(target))
        if name ~= "" then
            local s = GetSettings()
            if s and s.addressBook then
                -- Remove if exists
                for i, v in ipairs(recentMails) do
                    if string.lower(v) == string.lower(name) then
                        table.remove(recentMails, i)
                        break
                    end
                end
                table.insert(recentMails, 1, name)
                if #recentMails > 10 then table.remove(recentMails) end
            end
        end
    end)
    hasHookedSendMail = true
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
local AddressBookDropdown = CreateFrame("Frame", "GravityUIAddressBookDropdown", UIParent, "UIDropDownMenuTemplate")

local function CreateUIElements()
    local s = GetSettings()
    if not s or not s.enabled then return end

    if s.openAll and not OpenAllButton then
        OpenAllButton = CreateFrame("Button", "GravityUIOpenAllButton", InboxFrame, "UIPanelButtonTemplate")
        OpenAllButton:SetWidth(120)
        OpenAllButton:SetHeight(25)
        OpenAllButton:SetPoint("CENTER", InboxFrame, "TOP", -36, -399)
        OpenAllButton:SetText("Open All")
        OpenAllButton:SetScript("OnClick", OnOpenAllClicked)
        OpenAllButton:SetFrameLevel(OpenAllButton:GetFrameLevel() + 1)
        
        -- Hide Blizzard button
        if OpenAllMail then OpenAllMail:Hide() end
    end
    
    if s.addressBook and not AddressBookButton then
        AddressBookButton = CreateFrame("Button", "GravityUIAddressBookButton", SendMailFrame)
        AddressBookButton:SetWidth(25)
        AddressBookButton:SetHeight(25)
        AddressBookButton:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", -2, 2)
        AddressBookButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        AddressBookButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
        AddressBookButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
        AddressBookButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
        
        AddressBookButton:SetScript("OnClick", function(self)
            UIDropDownMenu_Initialize(AddressBookDropdown, BuildAddressBookMenu, "MENU")
            ToggleDropDownMenu(1, nil, AddressBookDropdown, self:GetName(), 0, 0)
        end)
    end
end

function Mail:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(event, paneType)
    if paneType == interactionTypeMail then
        local s = GetSettings()
        if not s or not s.enabled then return end
        
        CreateUIElements()
        if OpenAllButton and s.openAll then OpenAllButton:Show() end
        if AddressBookButton and s.addressBook then AddressBookButton:Show() end
    end
end

function Mail:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(event, paneType)
    if paneType == interactionTypeMail then
        isOpeningAll = false
        if OpenAllButton then OpenAllButton:SetText("Open All") end
    end
end

function Mail:PLAYER_ENTERING_WORLD()
    PopulateAlts()
    local s = GetSettings()
    if s and s.enabled and s.addressBook then
        HookSendMail()
    end
end

function Mail.Initialize()
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    Mail:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    Mail:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    Mail:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Mail.ApplySettings()
    local s = GetSettings()
    if s and s.enabled then
        Mail:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
        Mail:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
        HookSendMail()
        if OpenAllMail and s.openAll then OpenAllMail:Hide() end
    else
        Mail:UnregisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
        Mail:UnregisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
        isOpeningAll = false
        if OpenAllButton then OpenAllButton:Hide() end
        if AddressBookButton then AddressBookButton:Hide() end
        if OpenAllMail then OpenAllMail:Show() end
    end
end
