local ADDON_NAME, ns = ...
ns.Datatexts = {}
local DT = ns.Datatexts
local C = ns.Colors

-- Constants
local DAY_SECONDS = 86400
local HOUR_SECONDS = 3600
local MINUTE_SECONDS = 60

-- Helpers
local function GetValueColor()
    -- Use the optimized global accent color
    local r, g, b = ns.GetAccentColor()
    return r, g, b
end

local function GetLabel(fullLabel, shortLabel, useShortLabel, useNoLabel)
    if useNoLabel then return "" end
    if useShortLabel then return shortLabel end
    return fullLabel
end

local function FormatTimeRemaining(seconds)
    if not seconds or seconds <= 0 then return "0m" end
    local days = math.floor(seconds / DAY_SECONDS)
    local hours = math.floor((seconds % DAY_SECONDS) / HOUR_SECONDS)
    local minutes = math.floor((seconds % HOUR_SECONDS) / MINUTE_SECONDS)
    
    if days > 0 then return string.format("%dd %dh", days, hours)
    elseif hours > 0 then return string.format("%dh %dm", hours, minutes)
    else return string.format("%dm", minutes) end
end

-- Lockout cache for throttling RequestRaidInfo
local lockoutCache = {
    lastUpdate = 0,
    instances = {},
    worldBosses = {},
}

local function RefreshLockoutCache()
    local now = GetTime()
    if now - lockoutCache.lastUpdate < 300 then -- 5 minute cache
        return
    end

    RequestRaidInfo()
    lockoutCache.lastUpdate = now

    -- Cache saved instances
    wipe(lockoutCache.instances)
    local numSaved = GetNumSavedInstances() or 0
    for i = 1, numSaved do
        local name, _, reset, _, locked, _, _, _, maxPlayers, difficultyName = GetSavedInstanceInfo(i)
        if locked and reset > 0 then
            table.insert(lockoutCache.instances, {
                name = name,
                reset = reset,
                maxPlayers = maxPlayers,
                difficultyName = difficultyName,
            })
        end
    end

    -- Cache world bosses
    wipe(lockoutCache.worldBosses)
    if GetNumSavedWorldBosses then
        local numWorldBosses = GetNumSavedWorldBosses() or 0
        for i = 1, numWorldBosses do
            local name, _, reset = GetSavedWorldBossInfo(i)
            if name and reset > 0 then
                table.insert(lockoutCache.worldBosses, {
                    name = name,
                    reset = reset,
                })
            end
        end
    end
end

-- ============================================================================
-- SOCIAL HELPERS & CACHING
-- ============================================================================
local TIMERUNNING_ICON = "|A:timerunning-glues-icon-small:12:10:0:0|a"
local MOBILE_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat:14:14:0:0:16:16:0:16:0:16:73:177:73|t"

local function GetLevelColor(level)
    level = level or 1
    local color = GetQuestDifficultyColor(level)
    return color -- Return the color table
end

local function GetClassColor(className)
    if not className then return {r=1, g=1, b=1} end
    local c = RAID_CLASS_COLORS[className]
    if c then return c end
    return {r=1, g=1, b=1}
end

local function IsPlayerInGroup(name)
    if not name then return false end
    return UnitInParty(name) or UnitInRaid(name)
end

local function SendWhisperTo(name, isBNet)
    if not name then return end
    if isBNet then
        ChatFrameUtil.SendBNetTell(name)
    else
        SetItemRef("player:" .. name, string.format("|Hplayer:%1$s|h[%1$s]|h", name), "LeftButton")
    end
end

local function InvitePlayerToGroup(name, guid, isBNet)
    if not name then return end
    if isBNet then
        BNInviteFriend(name)
    else
        C_PartyInfo.InviteUnit(name)
    end
end

local myRealmPattern
local function StripMyRealm(name)
    if not myRealmPattern then
        local realm = GetNormalizedRealmName()
        if realm then myRealmPattern = "%-" .. realm else return name end
    end
    return (string.gsub(name, myRealmPattern, ""))
end

-- Guild Cache
local guildCache = { members = {}, lastUpdate = 0 }
local function BuildGuildCache()
    if not IsInGuild() then return end
    C_GuildInfo.GuildRoster() -- Request refresh
    wipe(guildCache.members)
    local total, online = GetNumGuildMembers()
    for i = 1, total do
        local name, rank, rankIndex, level, class, zone, note, offNote, connected, status, engClass, _, _, isMobile, _, _, guid = GetGuildRosterInfo(i)
        if name and (connected or isMobile) then
            table.insert(guildCache.members, {
                name = name, rank = rank, level = level, class = engClass, zone = zone,
                note = note, offNote = offNote, online = connected, status = status,
                isMobile = isMobile, guid = guid
            })
        end
    end
    guildCache.lastUpdate = GetTime()
end

-- ============================================================================
-- DATATEXT TYPES INITIALIZATION
-- ============================================================================
DT.Types = {}

-- 1. TIME
DT.Types.time = {
    Update = function(slot, config)
        local db = ns.GetDB()
        local useLocal = not db or not db.minimap or not db.minimap.clockConfig or db.minimap.clockConfig.timeFormat == "local"
        
        local h, m
        if useLocal then
            h, m = tonumber(date("%H")), tonumber(date("%M"))
        else
            h, m = GetGameTime()
        end
        
        local r, g, b = GetValueColor()
        local label = GetLabel("Time: ", "T: ", config.shortLabel, config.noLabel)
        
        local text = string.format("%s|cff%02x%02x%02x%02d:%02d|r", label, r*255, g*255, b*255, h, m)
        return text
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Time", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        local ar, ag, ab = GetValueColor()
        
        -- Lockouts
        RefreshLockoutCache()
        if #lockoutCache.instances > 0 then
            GameTooltip:AddLine("Saved Raid(s)", 1, 0.82, 0)
            for _, instance in ipairs(lockoutCache.instances) do
                local name = instance.difficultyName and string.format("%s (%s)", instance.name, instance.difficultyName) or instance.name
                GameTooltip:AddDoubleLine(name, FormatTimeRemaining(instance.reset), 0.8, 0.8, 0.8, ar, ag, ab)
            end
            GameTooltip:AddLine(" ")
        end

        if #lockoutCache.worldBosses > 0 then
            GameTooltip:AddLine("World Bosses", 1, 0.82, 0)
            for _, boss in ipairs(lockoutCache.worldBosses) do
                GameTooltip:AddDoubleLine(boss.name, FormatTimeRemaining(boss.reset), 0.8, 0.8, 0.8, ar, ag, ab)
            end
            GameTooltip:AddLine(" ")
        end

        -- Resets
        local dailyReset = C_DateAndTime.GetSecondsUntilDailyReset()
        if dailyReset and dailyReset > 0 then
            GameTooltip:AddDoubleLine("Daily Reset:", FormatTimeRemaining(dailyReset), 0.8, 0.8, 0.8, ar, ag, ab)
        end
        local weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
        if weeklyReset and weeklyReset > 0 then
            GameTooltip:AddDoubleLine("Weekly Reset:", FormatTimeRemaining(weeklyReset), 0.8, 0.8, 0.8, ar, ag, ab)
        end

        -- Realm Time
        GameTooltip:AddDoubleLine("Realm time:", GameTime_GetGameTime(true), 0.8, 0.8, 0.8, 1, 1, 1)
        
         GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Calendar", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Toggle Clock", ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then ToggleCalendar()
        elseif button == "RightButton" then if TimeManagerFrame then TimeManagerFrame:SetShown(not TimeManagerFrame:IsShown()) end end
    end
}

-- 2. FPS / SYSTEM
DT.Types.fps = {
    Update = function(slot, config)
        local fps = math.floor(GetFramerate() + 0.5)
        local r, g, b = GetValueColor()
        if fps < 30 then r, g, b = 1, 0.2, 0.2 end
        local label = GetLabel("FPS: ", "F: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d|r", label, r*255, g*255, b*255, fps)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("System", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local _, _, home, world = GetNetStats()
        local ar, ag, ab = GetValueColor()
        GameTooltip:AddDoubleLine("Framerate:", math.floor(GetFramerate() + 0.5) .. " fps", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:AddDoubleLine("Home Latency:", (home or 0) .. " ms", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:AddDoubleLine("World Latency:", (world or 0) .. " ms", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function() end
}

-- 3. MS (Latency)
DT.Types.ms = {
    Update = function(slot, config)
        local _, _, home, world = GetNetStats()
        local ms = world or home or 0
        local r, g, b = GetValueColor()
        
        -- Color logic for MS
        local mr, mg, mb = r, g, b
        if ms > 150 then mr, mg, mb = 1, 0.4, 0.4 
        elseif ms > 100 then mr, mg, mb = 1, 1, 0.2 end
        
        local label = GetLabel("MS: ", "L: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d|r", label, mr*255, mg*255, mb*255, ms)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("System", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local _, _, home, world = GetNetStats()
        local ar, ag, ab = GetValueColor()
        GameTooltip:AddDoubleLine("Home Latency:", (home or 0) .. " ms", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:AddDoubleLine("World Latency:", (world or 0) .. " ms", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function() end
}

-- 4. GOLD
local function FormatGold(copper)
    local gold = math.floor(copper / 10000)
    local goldStr = tostring(gold)
    if gold >= 1000 then 
        goldStr = string.format("%d,%03d", math.floor(gold / 1000), gold % 1000) 
    end
    if gold >= 1000000 then 
        local millions = math.floor(gold / 1000000)
        local thousands = math.floor((gold % 1000000) / 1000)
        goldStr = string.format("%d,%03d,%03d", millions, thousands, gold % 1000)
    end
    return goldStr .. "g"
end

local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if not name or not realm then return nil end
    return string.format("%s-%s", realm, name)
end

-- (Removed redundant local function GetClassColor)

local function SaveGold()
    local key = GetCharacterKey()
    if not key then return end
    local db = ns.GetAceDB()
    if db then
        if not db.global then db.global = {} end
        if not db.global.goldData then db.global.goldData = {} end
        local _, class = UnitClass("player")
        db.global.goldData[key] = {
            money = GetMoney() or 0,
            class = class
        }
    end
end

DT.Types.gold = {
    Update = function(slot, config)
        local money = GetMoney() or 0
        local r, g, b = GetValueColor()
        local label = GetLabel("Gold: ", "G: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%s|r", label, r*255, g*255, b*255, FormatGold(money))
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Gold", 1, 1, 1)
        GameTooltip:AddLine(" ")

        local money = GetMoney() or 0
        local gold = math.floor(money / 10000)
        local silver = math.floor((money % 10000) / 100)
        local copper = money % 100
        GameTooltip:AddDoubleLine("Current:", string.format("%dg %ds %dc", gold, silver, copper), 0.8, 0.8, 0.8, 1, 1, 1)

        -- Global Characters
        local db = ns.GetAceDB()
        if db and db.global and db.global.goldData then
            local total = 0
            local list = {}
            for k, v in pairs(db.global.goldData) do
                local m = type(v) == "table" and v.money or v
                local c = type(v) == "table" and v.class or nil
                total = total + m
                table.insert(list, {key = k, money = m, class = c})
            end
            
            if #list > 1 then
                table.sort(list, function(a, b) return a.money > b.money end)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("All Characters", 1, 1, 1)
                local currentKey = GetCharacterKey()
                for _, char in ipairs(list) do
                    local cr, cg, cb = GetClassColor(char.class)
                    local name = (char.key == currentKey) and ("• " .. char.key) or char.key
                    GameTooltip:AddDoubleLine(name, FormatGold(char.money), cr, cg, cb, 1, 1, 1)
                end
                local vr, vg, vb = GetValueColor()
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Total:", FormatGold(total), vr, vg, vb, 1, 0.82, 0)
            end
        end

        -- Warbound Bank
        if C_Bank and C_Bank.FetchDepositedMoney then
            local wbMoney = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
            if wbMoney and wbMoney > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Warbound Bank", 1, 1, 1)
                GameTooltip:AddDoubleLine("Account Gold:", FormatGold(wbMoney), 0.8, 0.8, 0.8, 1, 0.82, 0)
            end
        end

        -- WoW Token
        if C_WowTokenPublic and C_WowTokenPublic.GetCurrentMarketPrice then
            local price = C_WowTokenPublic.GetCurrentMarketPrice()
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("WoW Token", 1, 1, 1)
            if price and price > 0 then
                GameTooltip:AddDoubleLine("Market Price:", FormatGold(price), 0.8, 0.8, 0.8, 1, 0.82, 0)
            else
                GameTooltip:AddDoubleLine("Market Price:", "Updating...", 0.8, 0.8, 0.8, 0.5, 0.5, 0.5)
                C_WowTokenPublic.UpdateMarketPrice()
            end
        end

        local ar, ag, ab = GetValueColor()
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Currency", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Toggle Bags", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFMiddle Click:|r Manage Characters", ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then ToggleCharacter("TokenFrame")
        elseif button == "RightButton" then ToggleAllBags()
        elseif button == "MiddleButton" then
            local db = ns.GetAceDB()
            if not db or not db.global or not db.global.goldData then return end
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle("Manage Characters")
                local currentKey = GetCharacterKey()
                for key, data in pairs(db.global.goldData) do
                    local money = type(data) == "table" and data.money or data
                    local class = type(data) == "table" and data.class or nil
                    local c = GetClassColor(class)
                    local colorCode = string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
                    local btn = root:CreateButton(colorCode .. key .. "|r - " .. FormatGold(money), function()
                        db.global.goldData[key] = nil
                        print("|cff30D1FFGravityUI:|r Removed gold data for " .. key)
                    end)
                    if key == currentKey then btn:SetEnabled(false) end
                end
                root:CreateDivider()
                root:CreateButton("|cffFF6666Reset All (Keep Current)|r", function()
                    local currentData = db.global.goldData[currentKey]
                    db.global.goldData = { [currentKey] = currentData }
                    print("|cff30D1FFGravityUI:|r Reset all gold data.")
                end)
            end)
        end
    end
}

-- 4. GUILD
DT.Types.guild = {
    Update = function(slot, config)
        if not IsInGuild() then return "No Guild" end
        local total, online = GetNumGuildMembers()
        local r, g, b = GetValueColor()
        local guildName = GetGuildInfo("player") or "Guild"
        local label = GetLabel(guildName .. ": ", "G: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d|r", label, r*255, g*255, b*255, online or 0)
    end,
    OnEnter = function(self)
        if not IsInGuild() then return end
        if GetTime() - guildCache.lastUpdate > 1 then BuildGuildCache() end

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        local guildName = GetGuildInfo("player") or "Guild"
        local showNotes = IsShiftKeyDown()
        GameTooltip:AddLine(guildName .. (showNotes and " (Notes)" or ""), 1, 1, 1)

        local motd = GetGuildRosterMOTD()
        if motd and motd ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("MOTD:", 1, 0.8, 0)
            GameTooltip:AddLine(motd, 0.8, 0.8, 0.8, true)
        end

        local ar, ag, ab = GetValueColor()
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(showNotes and "Online Members (Notes)" or "Online Members", ar, ag, ab)

        for i, info in ipairs(guildCache.members) do
            if i > 30 then
                GameTooltip:AddLine(string.format("... and %d more", #guildCache.members - 30), 0.7, 0.7, 0.7)
                break
            end
            local classColor = GetClassColor(info.class)
            local status = info.status == 1 and " |cffFFFF00(AFK)|r" or info.status == 2 and " |cffFF0000(DND)|r" or ""
            local levelColor = GetLevelColor(info.level)
            local levelStr = string.format("|cff%02x%02x%02x%d|r ", levelColor.r*255, levelColor.g*255, levelColor.b*255, info.level or 0)
            local mobile = (info.isMobile and not info.online) and (" " .. MOBILE_ICON) or ""
            local displayName = StripMyRealm(info.name)

            local rightText, rr, rg, rb
            if showNotes then
                rightText = (info.note and info.note ~= "") and info.note or "No note"
                rr, rg, rb = 0.9, 0.9, 0.6
            else
                rightText = info.zone or "Unknown"
                rr, rg, rb = 0.7, 0.7, 0.7
            end

            GameTooltip:AddDoubleLine(
                levelStr .. displayName .. status .. mobile .. " |cff999999-|cffffffff " .. info.rank .. "|r",
                rightText, classColor.r, classColor.g, classColor.b, rr, rg, rb
            )
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Guild", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Whisper/Invite Menu", ar, ag, ab)
        GameTooltip:AddLine(showNotes and "|cffFFFFFFRelease Shift:|r Show Zones" or "|cffFFFFFFHold Shift:|r Show Notes", ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then ToggleGuildFrame()
        elseif button == "RightButton" and IsInGuild() then
            if GetTime() - guildCache.lastUpdate > 1 then BuildGuildCache() end
            local playerName = UnitName("player") .. "-" .. GetNormalizedRealmName()
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle("Guild Menu")
                local whisperMenu = root:CreateButton("Whisper")
                local inviteMenu = root:CreateButton("Invite")
                local hasWhisper, hasInvite = false, false
                for _, info in ipairs(guildCache.members) do
                    if Ambiguate(info.name, "none") ~= Ambiguate(playerName, "none") then
                        local classColor = GetClassColor(info.class)
                        local colorCode = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
                        if info.online or info.isMobile then
                            hasWhisper = true
                            local whisperName = info.name
                            whisperMenu:CreateButton(colorCode .. StripMyRealm(info.name) .. "|r", function() SendWhisperTo(whisperName, false) end)
                        end
                        if info.online and not IsPlayerInGroup(info.name) then
                            hasInvite = true
                            local inviteName, inviteGuid = info.name, info.guid
                            inviteMenu:CreateButton(colorCode .. StripMyRealm(info.name) .. "|r", function() InvitePlayerToGroup(inviteName, inviteGuid, false) end)
                        end
                    end
                end
                if not hasWhisper then whisperMenu:CreateButton("No members online"):SetEnabled(false) end
                if not hasInvite then inviteMenu:CreateButton("No invitable members"):SetEnabled(false) end
                root:CreateDivider()
                root:CreateButton("Open Guild Panel", function() ToggleGuildFrame() end)
            end)
        end
    end
}


-- Friends Cache
local friendsCache = {
    wowFriends = {}, bnetRetail = {}, bnetClassic = {}, bnetOther = {},
    lastUpdate = 0
}

local CLIENT_PRIORITY = { App = 1, BSAp = 1 }
local function GetClientPriority(client, wowProjectID)
    if client == BNET_CLIENT_WOW then
        return (wowProjectID == (WOW_PROJECT_ID or 1)) and 100 or 50
    end
    return CLIENT_PRIORITY[client] or 10
end

local function BuildFriendsCache()
    wipe(friendsCache.wowFriends)
    wipe(friendsCache.bnetRetail)
    wipe(friendsCache.bnetClassic)
    wipe(friendsCache.bnetOther)

    for i = 1, C_FriendList.GetNumFriends() do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.connected then
            table.insert(friendsCache.wowFriends, info)
        end
    end

    if BNConnected() then
        local seenAccounts = {}
        for i = 1, BNGetNumFriends() do
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
            if accountInfo then
                local bnetID = accountInfo.bnetAccountID
                local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i) or 0
                local foundGameAccount = false

                for y = 1, numGameAccounts do
                    local gameInfo = C_BattleNet.GetFriendGameAccountInfo(i, y)
                    if gameInfo and gameInfo.isOnline then
                        foundGameAccount = true
                        local priority = GetClientPriority(gameInfo.clientProgram, gameInfo.wowProjectID)
                        local existing = seenAccounts[bnetID]
                        if not existing or priority > existing.priority then
                            seenAccounts[bnetID] = { priority = priority, entry = gameInfo, accountName = accountInfo.accountName, note = accountInfo.note, isAFK = accountInfo.isAFK, isDND = accountInfo.isDND }
                        end
                    end
                end

                if not foundGameAccount and not seenAccounts[bnetID] then
                    local gameAccountInfo = accountInfo.gameAccountInfo
                    if gameAccountInfo and gameAccountInfo.isOnline then
                        seenAccounts[bnetID] = { priority = 1, entry = gameAccountInfo, accountName = accountInfo.accountName, note = accountInfo.note, isAFK = accountInfo.isAFK, isDND = accountInfo.isDND }
                    end
                end
            end
        end

        for _, data in pairs(seenAccounts) do
            local entry = data.entry
            entry.accountName = data.accountName
            entry.note = data.note
            entry.isAFK = data.isAFK
            entry.isDND = data.isDND
            if entry.clientProgram == BNET_CLIENT_WOW then
                if entry.wowProjectID == (WOW_PROJECT_ID or 1) then table.insert(friendsCache.bnetRetail, entry)
                else table.insert(friendsCache.bnetClassic, entry) end
            else table.insert(friendsCache.bnetOther, entry) end
        end
    end
    friendsCache.lastUpdate = GetTime()
end

-- 1. TIME (already implemented above)
-- 2. FPS / SYSTEM (already implemented above)
-- 3. GOLD (already implemented above)

-- 4. DURABILITY
DT.Types.durability = {
    Update = function(slot, config)
        local minVal = 100
        for i = 1, 18 do
            local cur, maxVal = GetInventoryItemDurability(i)
            if cur and maxVal and maxVal > 0 then
                local pct = (cur / maxVal) * 100
                if pct < minVal then minVal = pct end
            end
        end
        local r, g, b = GetValueColor()
        if minVal <= 25 then r, g, b = 1, 0.2, 0.2 elseif minVal <= 50 then r, g, b = 1, 1, 0 end
        local label = GetLabel("Durability: ", "Durability: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d%%|r", label, r*255, g*255, b*255, math.floor(minVal + 0.5))
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Durability", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local SLOT_NAMES = { [1]="Head", [3]="Shoulder", [5]="Chest", [6]="Waist", [7]="Legs", [8]="Feet", [9]="Wrist", [10]="Hands", [15]="Back", [16]="Main Hand", [17]="Off Hand" }
        for id, name in pairs(SLOT_NAMES) do
            local cur, maxVal = GetInventoryItemDurability(id)
            if cur and maxVal and maxVal > 0 then
                local pct = (cur / maxVal) * 100
                local r, g, b = 0.1, 1, 0.1
                if pct <= 25 then r, g, b = 1, 0.2, 0.2 elseif pct <= 50 then r, g, b = 1, 1, 0 end
                GameTooltip:AddDoubleLine(name, string.format("%d%%", pct), 0.8, 0.8, 0.8, r, g, b)
            end
        end
        GameTooltip:Show()
    end,
    OnClick = function() ToggleCharacter("PaperDollFrame") end
}

-- 5. GUILD (already implemented above)

-- 6. FRIENDS
DT.Types.friends = {
    Update = function(slot, config)
        local wowOnline = C_FriendList.GetNumOnlineFriends() or 0
        local bnetOnline = select(2, BNGetNumFriends()) or 0
        local total = wowOnline + bnetOnline
        local r, g, b = GetValueColor()
        local label = GetLabel("Friends: ", "Fr: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d|r", label, r*255, g*255, b*255, total)
    end,
    OnEnter = function(self)
        if GetTime() - friendsCache.lastUpdate > 1 then BuildFriendsCache() end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        local showNotes = IsShiftKeyDown()
        GameTooltip:AddLine(showNotes and "Friends (Notes)" or "Friends", 1, 1, 1)
        
        local ar, ag, ab = GetValueColor()
        if #friendsCache.wowFriends > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("WoW Friends", ar, ag, ab)
            for _, info in ipairs(friendsCache.wowFriends) do
                local classColor = GetClassColor(info.className)
                local levelColor = GetLevelColor(info.level)
                local levelStr = string.format("|cff%02x%02x%02x%d|r ", levelColor.r*255, levelColor.g*255, levelColor.b*255, info.level or 0)
                local right = showNotes and (info.notes ~= "" and info.notes or "No note") or (info.area or "Unknown")
                GameTooltip:AddDoubleLine(levelStr .. info.name, right, classColor.r, classColor.g, classColor.b, 0.7, 0.7, 0.7)
            end
        end

        if #friendsCache.bnetRetail > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Battle.net (Retail)", 0.31, 0.69, 0.9)
            for _, info in ipairs(friendsCache.bnetRetail) do
                local classColor = GetClassColor(info.className)
                local levelColor = GetLevelColor(info.characterLevel)
                local levelStr = string.format("|cff%02x%02x%02x%d|r ", levelColor.r*255, levelColor.g*255, levelColor.b*255, info.characterLevel or 0)
                local name = info.characterName ~= "" and (levelStr .. info.characterName .. " (" .. info.accountName .. ")") or info.accountName
                local right = showNotes and (info.note ~= "" and info.note or "No note") or (info.areaName or "Unknown")
                GameTooltip:AddDoubleLine(name, right, classColor.r, classColor.g, classColor.b, 0.7, 0.7, 0.7)
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Friends", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Whisper/Invite Menu", ar, ag, ab)
        GameTooltip:AddLine(showNotes and "|cffFFFFFFRelease Shift:|r Show Zones" or "|cffFFFFFFHold Shift:|r Show Notes", ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then ToggleFriendsFrame(1)
        elseif button == "RightButton" then
            if GetTime() - friendsCache.lastUpdate > 1 then BuildFriendsCache() end
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle("Friends Menu")
                local whisperMenu = root:CreateButton("Whisper")
                local inviteMenu = root:CreateButton("Invite")
                -- Port simplified whisper/invite logic for friends
                for _, info in ipairs(friendsCache.wowFriends) do
                    local classColor = GetClassColor(info.className)
                    local colorCode = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
                    local whisperName = info.name
                    whisperMenu:CreateButton(colorCode .. info.name .. "|r", function() SendWhisperTo(whisperName, false) end)
                    if not IsPlayerInGroup(info.name) then
                        inviteMenu:CreateButton(colorCode .. info.name .. "|r", function() InvitePlayerToGroup(whisperName, info.guid, false) end)
                    end
                end
                for _, info in ipairs(friendsCache.bnetRetail) do
                    local classColor = GetClassColor(info.className)
                    local colorCode = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
                    local whisperName = info.accountName
                    whisperMenu:CreateButton(colorCode .. (info.characterName or info.accountName) .. "|r", function() SendWhisperTo(whisperName, true) end)
                    if info.characterName and not IsPlayerInGroup(info.characterName) then
                        inviteMenu:CreateButton(colorCode .. info.characterName .. "|r", function() InvitePlayerToGroup(info.gameAccountID, info.playerGuid, true) end)
                    end
                end
            end)
        end
    end
}

-- 7. BAGS
DT.Types.bags = {
    Update = function(slot, config)
        local free, total = 0, 0
        for i = 0, NUM_BAG_SLOTS + 1 do
            local f, t = C_Container.GetContainerNumFreeSlots(i), C_Container.GetContainerNumSlots(i)
            if t and t > 0 then free, total = free + f, total + t end
        end
        local r, g, b = GetValueColor()
        local label = GetLabel("Bags: ", "B: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d/%d|r", label, r*255, g*255, b*255, total - free, total)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Bags", 1, 1, 1)
        GameTooltip:AddLine(" ")
        for i = 0, NUM_BAG_SLOTS + 1 do
            local t = C_Container.GetContainerNumSlots(i)
            if t and t > 0 then
                local f = C_Container.GetContainerNumFreeSlots(i)
                local name = C_Container.GetBagName(i) or (i == 0 and "Backpack" or "Bag "..i)
                local pct = (t-f)/t
                local r, g, b = 0.1, 1, 0.1
                if pct > 0.9 then r, g, b = 1, 0.1, 0.1 elseif pct > 0.75 then r, g, b = 1, 1, 0.1 end
                GameTooltip:AddDoubleLine(name, string.format("%d / %d", t-f, t), 1,1,1, r, g, b)
            end
        end
        GameTooltip:Show()
    end,
    OnClick = function() ToggleAllBags() end
}

-- 8. COORDS
DT.Types.coords = {
    Update = function(slot, config)
        local mapID = C_Map.GetBestMapForUnit("player")
        local x, y = 0, 0
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then x, y = pos:GetXY() end
        end
        local r, g, b = GetValueColor()
        local label = GetLabel("Coords: ", "C: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%.1f, %.1f|r", label, r*255, g*255, b*255, x*100, y*100)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Coordinates", 1, 1, 1)
        GameTooltip:AddLine(GetZoneText(), 1, 1, 1)
        local sub = GetSubZoneText()
        if sub and sub ~= "" then GameTooltip:AddLine(sub, 0.7, 0.7, 0.7) end
        GameTooltip:Show()
    end,
    OnClick = function() ToggleWorldMap() end
}

-- 9. SPEC / PLAYERSPEC
DT.Types.spec = {
    Update = function(slot, config)
        local spec = GetSpecialization()
        local _, name, _, icon = GetSpecializationInfo(spec or 1)
        local r, g, b = GetValueColor()
        local label = GetLabel("Spec: ", "S: ", config.shortLabel, config.noLabel)
        local iconText = string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t", icon or "")
        return string.format("%s %s|cff%02x%02x%02x%s|r", iconText, label, r*255, g*255, b*255, name or "None")
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Specialization", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local cur = GetSpecialization()
        for i = 1, GetNumSpecializations() do
            local _, name, _, icon = GetSpecializationInfo(i)
            local status = (i == cur) and " |cff00FF00(Active)|r" or ""
            GameTooltip:AddLine(string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s%s", icon, name, status), 1, 1, 1)
        end
        GameTooltip:AddLine(" ")
        local ar, ag, ab = GetValueColor()
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Switch Spec Menu", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Change Loot Spec", ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle("Switch Specialization")
                for i = 1, GetNumSpecializations() do
                    local _, name, _, icon = GetSpecializationInfo(i)
                    root:CreateButton(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s", icon, name), function() C_SpecializationInfo.SetSpecialization(i) end)
                end
            end)
        elseif button == "RightButton" then
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle("Loot Specialization")
                local curLoot = GetLootSpecialization()
                local _, curName = GetSpecializationInfo(GetSpecialization() or 1)
                root:CreateButton(curName .. " (Auto)" .. (curLoot == 0 and " |cff00FF00*|r" or ""), function() SetLootSpecialization(0) end)
                root:CreateDivider()
                for i = 1, GetNumSpecializations() do
                    local id, name, _, icon = GetSpecializationInfo(i)
                    root:CreateButton(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s", icon, name) .. (id == curLoot and " |cff00FF00*|r" or ""), function() SetLootSpecialization(id) end)
                end
            end)
        end
    end
}


-- ============================================================================
-- MAIN INTERFACE
-- ============================================================================

-- ============================================================================
-- LIBDATABROKER (LDB) SUPPORT
-- ============================================================================
DT.LDB_Objects = {}

local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
if LDB then
    local function RegisterLDB(name, obj)
        DT.LDB_Objects[name] = obj
        -- Signal UI to refresh if needed (e.g. if options are open)
        if ns.GUI and ns.GUI.RefreshPage then ns.GUI:RefreshPage("datapanels") end
    end

    -- Initial scan
    for name, obj in LDB:DataObjectIterator() do
        RegisterLDB(name, obj)
    end

    -- Callback for new objects
    LDB.RegisterCallback(ADDON_NAME, "LibDataBroker_DataObjectCreated", function(_, name, obj)
        RegisterLDB(name, obj)
    end)

    -- Callback for attribute changes (refresh UI when text/label changes)
    LDB.RegisterCallback(ADDON_NAME, "LibDataBroker_AttributeChanged", function(_, name, attr, value, obj)
        if attr == "text" or attr == "value" or attr == "label" then
            if ns.RefreshMinimap then ns.RefreshMinimap() end
        end
    end)
end

-- Generic LDB Wrapper
local function UpdateLDB(slot, config, hideLabelOverride)
    local name = config.content:sub(5) -- Strip "LDB:"
    local obj = DT.LDB_Objects[name]
    if not obj then return "Err: " .. name end

    local r, g, b = GetValueColor()
    local colorStr = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    
    local text = obj.text or obj.label or name
    local hide = (hideLabelOverride == true) or config.noLabel
    local label = GetLabel((obj.label or name) .. ": ", (obj.label or name):sub(1,2) .. ": ", config.shortLabel, hide)
    
    return string.format("%s%s%s|r", label, colorStr, text)
end

local function OnEnterLDB(self, config)
    local name = config.content:sub(5)
    local obj = DT.LDB_Objects[name]
    if not obj or not obj.OnEnter then return end
    obj.OnEnter(self)
end

local function OnClickLDB(self, button, config)
    local name = config.content:sub(5)
    local obj = DT.LDB_Objects[name]
    if not obj or not obj.OnClick then return end
    obj.OnClick(self, button)
end

-- ============================================================================
-- MAIN INTERFACE
-- ============================================================================

function DT:GetContentText(slot, config, hideLabelOverride)
    if not config or not config.content then return "" end
    local type = config.content
    
    -- Merge hideLabelOverride into a temporary config for individual updates
    local tempConfig = config
    if hideLabelOverride then
        tempConfig = {}
        for k, v in pairs(config) do tempConfig[k] = v end
        tempConfig.noLabel = true
    end

    -- Handle LDB
    if type:find("^LDB:") then
        return UpdateLDB(slot, tempConfig, hideLabelOverride)
    end
    
    -- Handle Internal
    if DT.Types[type] and DT.Types[type].Update then
        return DT.Types[type].Update(slot, tempConfig)
    end
    return type -- Fallback
end

function DT:HandleOnEnter(slotFrame, config)
    if not config or not config.content then return end
    local type = config.content
    
    if type:find("^LDB:") then
        OnEnterLDB(slotFrame, config)
        return
    end

    if DT.Types[type] and DT.Types[type].OnEnter then
        DT.Types[type].OnEnter(slotFrame)
    end
end

function DT:HandleOnClick(slotFrame, button, config)
    if not config or not config.content then return end
    local type = config.content
    
    if type:find("^LDB:") then
        OnClickLDB(slotFrame, button, config)
        return
    end

    if DT.Types[type] and DT.Types[type].OnClick then
        DT.Types[type].OnClick(slotFrame, button)
    end
end

-- ============================================================================
-- INITIALIZATION & EVENT HANDLING
-- ============================================================================
local dtEvents = CreateFrame("Frame")
dtEvents:RegisterEvent("PLAYER_MONEY")
dtEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
dtEvents:RegisterEvent("PLAYER_TRADE_MONEY")
dtEvents:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
dtEvents:RegisterEvent("SEND_MAIL_COD_CHANGED")

dtEvents:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_MONEY" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TRADE_MONEY" then
        SaveGold()
    end
end)
