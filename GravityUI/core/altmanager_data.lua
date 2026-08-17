-- ============================================================================
-- GravityUI - Alt Manager Data Layer
-- Account-wide character, M+, Great Vault, Raid, and Currency tracker
-- ============================================================================
local ADDON_NAME, ns = ...

ns.AltManager = ns.AltManager or {}
local AM = ns.AltManager

AM.Data = {}
local Data = AM.Data

-- Crest and currency IDs for The War Within / Current Expansion
local CURRENCY_IDS = {
    VALORSTONES = 3008,
    WEATHERED   = 2806,
    CARVED      = 2807,
    RUNED       = 2809,
    GILDED      = 2812,
    KEJ         = 3028,
    RESONANCE   = 3056,
}

local function GetDB()
    local db = ns.GetDB and ns.GetDB()
    if db and db.altManager then return db.altManager end
    return ns.Defaults and ns.Defaults.altManager
end

local function GetGlobalAltsTable()
    if _G.GravityUI_DB then
        if not _G.GravityUI_DB.global then _G.GravityUI_DB.global = {} end
        if not _G.GravityUI_DB.global.altManager then _G.GravityUI_DB.global.altManager = { alts = {}, lastWeeklyReset = 0 } end
        if not _G.GravityUI_DB.global.altManager.alts then _G.GravityUI_DB.global.altManager.alts = {} end
        return _G.GravityUI_DB.global.altManager.alts
    end
    if ns.db and ns.db.global then
        if not ns.db.global.altManager then ns.db.global.altManager = { alts = {}, lastWeeklyReset = 0 } end
        if not ns.db.global.altManager.alts then ns.db.global.altManager.alts = {} end
        return ns.db.global.altManager.alts
    end
    if not _G.GravityUI_DB then _G.GravityUI_DB = { global = { altManager = { alts = {} } } } end
    return _G.GravityUI_DB.global.altManager.alts
end

-- ============================================================================
-- DATA COLLECTION
-- ============================================================================

function Data:GetCurrentCharacterGUID()
    return UnitGUID("player")
end

function Data:GetAlt(guid)
    guid = guid or self:GetCurrentCharacterGUID()
    if not guid then return nil end
    local alts = GetGlobalAltsTable()
    return alts[guid]
end

function Data:GetOrCreateCurrentAlt()
    local guid = self:GetCurrentCharacterGUID()
    if not guid then return nil end
    local alts = GetGlobalAltsTable()
    if not alts[guid] then
        alts[guid] = {
            guid = guid,
            name = UnitName("player") or "Unknown",
            realm = GetRealmName() or "",
            class = select(2, UnitClass("player")) or "WARRIOR",
            className = UnitClass("player") or "Warrior",
            level = UnitLevel("player") or 80,
            faction = UnitFactionGroup("player") or "Neutral",
            race = select(2, UnitRace("player")) or "",
            specId = 0,
            specName = "",
            specIcon = 0,
            role = "NONE",
            ilvlEquipped = 0,
            ilvlOverall = 0,
            money = 0,
            lastUpdated = time(),
            keystone = {},
            vault = { slots = {}, hasRewards = false },
            mythicplus = { rating = 0, dungeons = {} },
            raids = {},
            currencies = {},
        }
    end
    return alts[guid]
end

function Data:UpdateCharacterInfo()
    local alt = self:GetOrCreateCurrentAlt()
    if not alt then return end

    alt.name = UnitName("player") or alt.name
    alt.realm = GetRealmName() or alt.realm
    alt.level = UnitLevel("player") or alt.level
    alt.faction = UnitFactionGroup("player") or alt.faction
    
    local m = GetMoney()
    if m and m > 0 then
        alt.money = m
    elseif not alt.money then
        alt.money = 0
    end
    alt.lastUpdated = time()

    local raceName = UnitRace("player")
    if raceName and raceName ~= "" then alt.race = raceName end

    local guildName, guildRankName = GetGuildInfo("player")
    if guildName and guildName ~= "" then
        alt.guild = guildName
        alt.guildRank = guildRankName or ""
    end

    local localizedClass, englishClass = UnitClass("player")
    alt.class = englishClass or alt.class or "WARRIOR"
    alt.className = localizedClass or englishClass or alt.className

    local currentSpec = GetSpecialization()
    if currentSpec and currentSpec > 0 then
        local id, name, desc, icon = GetSpecializationInfo(currentSpec)
        if icon and icon ~= 0 then
            alt.specId = id
            alt.specName = name
            alt.specIcon = icon
        end
    end

    if GetAverageItemLevel then
        local overall, equipped = GetAverageItemLevel()
        if equipped and equipped > 0 then
            alt.ilvlOverall = math.floor((overall or 0) * 10) / 10
            alt.ilvlEquipped = math.floor((equipped or 0) * 10) / 10
        end
    end
end

function Data:UpdateKeystone()
    local alt = self:GetOrCreateCurrentAlt()
    if not alt then return end

    local keyMapID = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local keyLevel = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()

    local keyItemLink = nil
    local keyItemID = 0

    -- Scan Bags for Keystone Link
    if C_Container and C_Container.GetContainerNumSlots then
        for bag = 0, 4 do
            local numSlots = C_Container.GetContainerNumSlots(bag) or 0
            for slot = 1, numSlots do
                local link = C_Container.GetContainerItemLink(bag, slot)
                if link and (link:find("keystone:") or link:find("item:180653") or link:find("item:151086") or link:find("item:229645")) then
                    keyItemLink = link
                    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                    keyItemID = itemInfo and itemInfo.itemID or 0
                    break
                end
            end
            if keyItemLink then break end
        end
    end

    if keyItemLink and (not keyMapID or not keyLevel or keyMapID == 0) then
        if LinkUtil and LinkUtil.ExtractLink then
            local _, linkOptions = LinkUtil.ExtractLink(keyItemLink)
            if linkOptions then
                local _, linkChallengeModeID, linkLvl = LinkUtil.SplitLinkOptions(linkOptions)
                keyMapID = tonumber(linkChallengeModeID) or keyMapID
                keyLevel = tonumber(linkLvl) or keyLevel
            end
        end
    end

    local keyName = ""
    local keyIcon = 0
    if keyMapID and keyMapID > 0 and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(keyMapID)
        keyName = name or "Mythic Keystone"
        keyIcon = texture or 525134
    end

    local colorHex = "ffffffff"
    if keyLevel and keyLevel > 0 and C_ChallengeMode and C_ChallengeMode.GetKeystoneLevelRarityColor then
        local col = C_ChallengeMode.GetKeystoneLevelRarityColor(keyLevel)
        if col and col.GenerateHexColor then
            colorHex = col:GenerateHexColor()
        end
    end

    alt.keystone = {
        mapId = keyMapID or 0,
        name = keyName,
        level = keyLevel or 0,
        link = keyItemLink or "",
        icon = keyIcon,
        color = colorHex,
    }
end

function Data:UpdateVault()
    local alt = self:GetOrCreateCurrentAlt()
    if not alt then return end

    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return end

    alt.vault = alt.vault or {}
    alt.vault.hasRewards = (C_WeeklyRewards.HasAvailableRewards and C_WeeklyRewards.HasAvailableRewards() == true)
    alt.vault.slots = {}

    local activities = C_WeeklyRewards.GetActivities()
    if activities then
        for _, act in ipairs(activities) do
            local itemLink, upgradeLink = "", ""
            if act.progress >= act.threshold and C_WeeklyRewards.GetExampleRewardItemHyperlinks then
                itemLink, upgradeLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(act.id)
            end

            local rewardLevel = act.level or 0
            local rewardIlvl = 0
            if itemLink and itemLink ~= "" and C_Item and C_Item.GetDetailedItemLevelInfo then
                rewardIlvl = C_Item.GetDetailedItemLevelInfo(itemLink) or 0
            end

            table.insert(alt.vault.slots, {
                id = act.id,
                type = act.type,
                index = act.index,
                threshold = act.threshold or 0,
                progress = act.progress or 0,
                completed = (act.threshold and act.threshold > 0 and act.progress and act.progress >= act.threshold),
                level = rewardLevel,
                activityTierID = act.activityTierID or 0,
                itemLevel = rewardIlvl,
                itemLink = itemLink or "",
                upgradeLink = upgradeLink or "",
            })
        end
    end
end

function Data:UpdateMythicPlus()
    local alt = self:GetOrCreateCurrentAlt()
    if not alt then return end

    alt.mythicplus = alt.mythicplus or {}
    alt.mythicplus.dungeons = {}
    alt.mythicplus.runHistory = {}

    -- Rating
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if ratingSummary and ratingSummary.currentSeasonScore then
            alt.mythicplus.rating = math.floor(ratingSummary.currentSeasonScore + 0.5)
        else
            alt.mythicplus.rating = 0
        end
    end

    -- Run History
    if C_MythicPlus and C_MythicPlus.GetRunHistory then
        local runs = C_MythicPlus.GetRunHistory(false, true) or {}
        for _, r in ipairs(runs) do
            table.insert(alt.mythicplus.runHistory, {
                mapChallengeModeID = r.mapChallengeModeID,
                level = r.level or 0,
                thisWeek = (r.thisWeek == true),
                completed = (r.completed == true),
            })
        end
    end

    -- Season Dungeons
    if C_ChallengeMode and C_ChallengeMode.GetMapTable then
        local maps = C_ChallengeMode.GetMapTable() or {}
        for _, mapID in ipairs(maps) do
            local name, id, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
            local bestTimed, bestNotTimed = 0, 0
            if C_MythicPlus and C_MythicPlus.GetSeasonBestForMap then
                local tRun, ntRun = C_MythicPlus.GetSeasonBestForMap(mapID)
                bestTimed = (tRun and tRun.level) or 0
                bestNotTimed = (ntRun and ntRun.level) or 0
            end

            local bestLvl = math.max(bestTimed, bestNotTimed)
            local inTime = (bestTimed >= bestNotTimed and bestTimed > 0)

            alt.mythicplus.dungeons[mapID] = {
                mapId = mapID,
                name = name or ("Dungeon " .. mapID),
                icon = texture or 0,
                timeLimit = timeLimit or 0,
                bestLevel = bestLvl,
                inTime = inTime,
            }
        end
    end
end

-- ============================================================================
-- SEASON RAIDS & ENCOUNTERS
-- ============================================================================
local SEASON_RAIDS = {
    {
        name = "The Tidebound Grotto",
        abbr = "TG",
        instanceID = 2987,
        encounters = {
            "Nymrissa Wavecaller",
        },
    },
    {
        name = "The Venomous Abyss",
        abbr = "TVA",
        instanceID = 3004,
        encounters = {
            "Nek'zali the Soulcoiler",
            "Entombed Sentinels",
            "The Lost Explorers",
            "Vashnik the Malignant",
            "Sszorak",
            "The Twin Fangs",
            "The Coiled Altar",
            "Ula'tek",
        },
    },
}

function Data:GetSeasonRaids()
    return SEASON_RAIDS
end

function Data:UpdateRaidLockouts()
    local alt = self:GetOrCreateCurrentAlt()
    if not alt then return end

    alt.raids = {
        LFR = { bosses = {} },
        Normal = { bosses = {} },
        Heroic = { bosses = {} },
        Mythic = { bosses = {} },
    }

    -- Pre-populate all 9 bosses
    for _, diffKey in ipairs({"LFR", "Normal", "Heroic", "Mythic"}) do
        for _, r in ipairs(SEASON_RAIDS) do
            for _, bName in ipairs(r.encounters) do
                table.insert(alt.raids[diffKey].bosses, {
                    name = bName,
                    raidName = r.name,
                    killed = false,
                })
            end
        end
    end

    local numSaved = GetNumSavedInstances()
    for i = 1, numSaved do
        local name, _, _, difficulty, locked, extended, _, isRaid, _, diffName, numEncounters = GetSavedInstanceInfo(i)
        if isRaid and locked then
            local diffKey = nil
            local baseDiff = (DifficultyUtil and DifficultyUtil.GetBaseDifficultyID and DifficultyUtil.GetBaseDifficultyID(difficulty)) or difficulty

            if baseDiff == 14 or (diffName and (diffName:find("Normal") or diffName:find("normal"))) then
                diffKey = "Normal"
            elseif baseDiff == 15 or (diffName and (diffName:find("Heroic") or diffName:find("heroisch"))) then
                diffKey = "Heroic"
            elseif baseDiff == 16 or baseDiff == 233 or (diffName and (diffName:find("Mythic") or diffName:find("mythisch"))) then
                diffKey = "Mythic"
            elseif baseDiff == 17 or (diffName and (diffName:find("LFR") or diffName:find("Schlachtzugsbrowser") or diffName:find("Looking For Raid"))) then
                diffKey = "LFR"
            end

            if diffKey and alt.raids[diffKey] and alt.raids[diffKey].bosses then
                for b = 1, (numEncounters or 0) do
                    local bName, _, isKilled = GetSavedInstanceEncounterInfo(i, b)
                    if isKilled and bName then
                        for _, bossObj in ipairs(alt.raids[diffKey].bosses) do
                            if bossObj.name == bName or bName:find(bossObj.name, 1, true) or bossObj.name:find(bName, 1, true) then
                                bossObj.killed = true
                            end
                        end
                    end
                end
            end
        end
    end
end

local TRACKED_CURRENCY_IDS = {
    3442, -- Adventurer Mistcrest
    3443, -- Veteran Mistcrest
    3444, -- Champion Mistcrest
    3445, -- Hero Mistcrest
    3446, -- Myth Mistcrest
    3465, -- Venomblight Manaflux
    3509, -- Tidal Spark Dust
    3310, -- Coffer Key Shards
    3028, -- Restored Coffer Key
    3356, -- Untainted Mana-Crystals
    3513, -- Nebulous Voidcore
}

local CURRENCY_METADATA = {
    [3442] = { useTotalEarned = true, type = "crest" },
    [3443] = { useTotalEarned = true, type = "crest" },
    [3444] = { useTotalEarned = true, type = "crest" },
    [3445] = { useTotalEarned = true, type = "crest" },
    [3446] = { useTotalEarned = true, type = "crest" },
    [3465] = { useTotalEarned = true, type = "catalyst" },
    [3509] = { useTotalEarned = true, type = "spark", defaultMax = 1 },
    [3310] = { useTotalEarned = false, type = "delve" },
    [3028] = { useTotalEarned = false, type = "delve" },
    [3356] = { useTotalEarned = false, type = "delve" },
    [3513] = { useTotalEarned = true, type = "bonusroll" },
}

function Data:GetTrackedCurrencyIDs()
    return TRACKED_CURRENCY_IDS
end

function Data:GetCurrencyMetadata(currId)
    return CURRENCY_METADATA[currId]
end

function Data:UpdateCurrencies()
    local alt = self:GetOrCreateCurrentAlt()
    if not alt then return end

    alt.currencies = alt.currencies or {}

    local globalTbl = (_G.GravityUI_DB and _G.GravityUI_DB.global and _G.GravityUI_DB.global.altManager) or (ns.db and ns.db.global and ns.db.global.altManager)
    if globalTbl and not globalTbl.currencyCaps then
        globalTbl.currencyCaps = {}
    end

    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end

    for _, currID in ipairs(TRACKED_CURRENCY_IDS) do
        local info = C_CurrencyInfo.GetCurrencyInfo(currID)
        if info and (info.name and info.name ~= "") then
            local meta = CURRENCY_METADATA[currID] or {}
            local maxQty = info.maxQuantity or 0
            if maxQty == 0 and info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0 then
                maxQty = info.maxWeeklyQuantity
            end
            if maxQty == 0 and meta.defaultMax then
                maxQty = meta.defaultMax
            end

            if globalTbl and globalTbl.currencyCaps and maxQty > (globalTbl.currencyCaps[currID] or 0) then
                globalTbl.currencyCaps[currID] = maxQty
            end

            alt.currencies[currID] = {
                id = currID,
                name = info.name or "",
                quantity = info.quantity or 0,
                maxQuantity = maxQty,
                maxWeeklyQuantity = info.maxWeeklyQuantity or 0,
                totalEarned = info.totalEarned or info.quantity or 0,
                quantityEarnedThisWeek = info.quantityEarnedThisWeek or 0,
                useTotalEarnedForMaxQty = (meta.useTotalEarned == true) or (info.useTotalEarnedForMaxQty == true),
                iconFileID = info.iconFileID or 0,
                quality = info.quality or 1,
                currencyType = meta.type or "other",
            }
        end
    end
end

-- ============================================================================
-- PREY HUNTS TRACKING
-- ============================================================================
local PREY_QUESTS = {
    -- Normal (1)
    { id = 91095, diff = 1 }, { id = 91096, diff = 1 }, { id = 91097, diff = 1 }, { id = 91098, diff = 1 },
    { id = 91099, diff = 1 }, { id = 91100, diff = 1 }, { id = 91101, diff = 1 }, { id = 91102, diff = 1 },
    { id = 91103, diff = 1 }, { id = 91104, diff = 1 }, { id = 91105, diff = 1 }, { id = 91106, diff = 1 },
    { id = 91107, diff = 1 }, { id = 91108, diff = 1 }, { id = 91109, diff = 1 }, { id = 91110, diff = 1 },
    { id = 91111, diff = 1 }, { id = 91112, diff = 1 }, { id = 91113, diff = 1 }, { id = 91114, diff = 1 },
    { id = 91115, diff = 1 }, { id = 91116, diff = 1 }, { id = 91117, diff = 1 }, { id = 91118, diff = 1 },
    { id = 91119, diff = 1 }, { id = 91120, diff = 1 }, { id = 91121, diff = 1 }, { id = 91122, diff = 1 },
    { id = 91123, diff = 1 }, { id = 91124, diff = 1 },
    -- Hard (2)
    { id = 91210, diff = 2 }, { id = 91212, diff = 2 }, { id = 91214, diff = 2 }, { id = 91216, diff = 2 },
    { id = 91218, diff = 2 }, { id = 91220, diff = 2 }, { id = 91222, diff = 2 }, { id = 91224, diff = 2 },
    { id = 91226, diff = 2 }, { id = 91228, diff = 2 }, { id = 91230, diff = 2 }, { id = 91232, diff = 2 },
    { id = 91234, diff = 2 }, { id = 91236, diff = 2 }, { id = 91238, diff = 2 }, { id = 91240, diff = 2 },
    { id = 91242, diff = 2 }, { id = 91243, diff = 2 }, { id = 91244, diff = 2 }, { id = 91245, diff = 2 },
    { id = 91246, diff = 2 }, { id = 91247, diff = 2 }, { id = 91248, diff = 2 }, { id = 91249, diff = 2 },
    { id = 91250, diff = 2 }, { id = 91251, diff = 2 }, { id = 91252, diff = 2 }, { id = 91253, diff = 2 },
    { id = 91254, diff = 2 }, { id = 91255, diff = 2 },
    -- Nightmare (3)
    { id = 91211, diff = 3 }, { id = 91213, diff = 3 }, { id = 91215, diff = 3 }, { id = 91217, diff = 3 },
    { id = 91219, diff = 3 }, { id = 91221, diff = 3 }, { id = 91223, diff = 3 }, { id = 91225, diff = 3 },
    { id = 91227, diff = 3 }, { id = 91229, diff = 3 }, { id = 91231, diff = 3 }, { id = 91233, diff = 3 },
    { id = 91235, diff = 3 }, { id = 91237, diff = 3 }, { id = 91239, diff = 3 }, { id = 91241, diff = 3 },
    { id = 91256, diff = 3 }, { id = 91257, diff = 3 }, { id = 91258, diff = 3 }, { id = 91259, diff = 3 },
    { id = 91260, diff = 3 }, { id = 91261, diff = 3 }, { id = 91262, diff = 3 }, { id = 91263, diff = 3 },
    { id = 91264, diff = 3 }, { id = 91265, diff = 3 }, { id = 91266, diff = 3 }, { id = 91267, diff = 3 },
    { id = 91268, diff = 3 }, { id = 91269, diff = 3 },
}

function Data:UpdatePreyHunts()
    local alt = self:GetOrCreateCurrentAlt()
    if not alt then return end
    alt.prey = { normal = 0, hard = 0, nightmare = 0 }
    if not C_QuestLog or not C_QuestLog.IsQuestFlaggedCompleted then return end

    for _, q in ipairs(PREY_QUESTS) do
        if C_QuestLog.IsQuestFlaggedCompleted(q.id) then
            if q.diff == 1 then alt.prey.normal = (alt.prey.normal or 0) + 1
            elseif q.diff == 2 then alt.prey.hard = (alt.prey.hard or 0) + 1
            elseif q.diff == 3 then alt.prey.nightmare = (alt.prey.nightmare or 0) + 1
            end
        end
    end
end

function Data:CheckWeeklyReset()
    if not C_DateAndTime or not C_DateAndTime.GetSecondsUntilWeeklyReset then return end

    local globalTbl = (_G.GravityUI_DB and _G.GravityUI_DB.global and _G.GravityUI_DB.global.altManager) or (ns.db and ns.db.global and ns.db.global.altManager)
    if not globalTbl then return end

    local now = time()
    local lastReset = globalTbl.lastWeeklyReset or 0

    if lastReset > 0 and lastReset <= now then
        local alts = GetGlobalAltsTable()
        for guid, alt in pairs(alts) do
            -- 1. Great Vault: check if rewards were unlocked, then clear slots
            if alt.vault and alt.vault.slots then
                local hadRewards = false
                for _, slot in ipairs(alt.vault.slots) do
                    if slot.threshold and slot.threshold > 0 and slot.progress and slot.progress >= slot.threshold then
                        hadRewards = true
                        break
                    end
                end
                alt.vault.hasRewards = hadRewards
                alt.vault.slots = {}
            end

            -- 2. Raids: reset all boss kill lockouts
            if alt.raids then
                for _, diffKey in ipairs({"LFR", "Normal", "Heroic", "Mythic"}) do
                    if alt.raids[diffKey] and alt.raids[diffKey].bosses then
                        for _, b in ipairs(alt.raids[diffKey].bosses) do
                            b.killed = false
                        end
                    end
                end
            end

            -- 3. Prey Hunts: reset completed count
            if alt.prey then
                alt.prey = { normal = 0, hard = 0, nightmare = 0 }
            end

            -- 4. Mythic+ Run History: flag runs as not this week
            if alt.mythicplus and alt.mythicplus.runHistory then
                for _, run in ipairs(alt.mythicplus.runHistory) do
                    run.thisWeek = false
                end
            end

            -- 5. Mythic+ Keystones: reset or clear
            if alt.keystone then
                alt.keystone.level = 0
                alt.keystone.link = ""
                alt.keystone.name = ""
            end
        end
    end

    -- Update next reset timestamp
    local secondsLeft = C_DateAndTime.GetSecondsUntilWeeklyReset()
    if secondsLeft and secondsLeft > 0 then
        globalTbl.lastWeeklyReset = now + secondsLeft
    end
end

function Data:UpdateAll()
    self:CheckWeeklyReset()
    self:UpdateCharacterInfo()
    self:UpdateKeystone()
    self:UpdateVault()
    self:UpdatePreyHunts()
    self:UpdateMythicPlus()
    self:UpdateRaidLockouts()
    self:UpdateCurrencies()
end

-- ============================================================================
-- QUERY & UTILITIES
-- ============================================================================

function Data:GetAllAltsList()
    local alts = GetGlobalAltsTable()
    local list = {}
    local db = GetDB()

    local onlyMax = db and db.onlyMaxLevel
    local showZero = db and (db.showZeroRated ~= false)
    local maxLvl = (GetMaxPlayerLevel and GetMaxPlayerLevel()) or 80

    for guid, alt in pairs(alts) do
        local keep = true
        if onlyMax and alt.level and alt.level < maxLvl then
            keep = false
        end
        if not showZero and (not alt.mythicplus or not alt.mythicplus.rating or alt.mythicplus.rating <= 0) then
            keep = false
        end

        if keep then
            table.insert(list, alt)
        end
    end

    -- Sorting
    local sortOrder = (db and db.sortOrder) or "lastPlayed"
    local currentGUID = self:GetCurrentCharacterGUID()

    table.sort(list, function(a, b)
        if sortOrder == "custom" then
            local customOrder = db and db.customOrder or {}
            local posA = customOrder[a.guid] or 999
            local posB = customOrder[b.guid] or 999
            if posA ~= posB then return posA < posB end
            return (a.name or "") < (b.name or "")
        end

        -- Always put current character first for other sort modes
        if a.guid == currentGUID then return true end
        if b.guid == currentGUID then return false end

        if sortOrder == "ilvl" then
            return (a.ilvlEquipped or 0) > (b.ilvlEquipped or 0)
        elseif sortOrder == "score" then
            return (a.mythicplus and a.mythicplus.rating or 0) > (b.mythicplus and b.mythicplus.rating or 0)
        elseif sortOrder == "name" then
            return (a.name or "") < (b.name or "")
        else -- "lastPlayed"
            return (a.lastUpdated or 0) > (b.lastUpdated or 0)
        end
    end)

    return list
end

function Data:MoveAltOrder(guid, delta)
    local db = GetDB()
    if not db then return end
    if not db.customOrder then db.customOrder = {} end

    local alts = self:GetAllAltsList()
    -- Initialize custom order indices if not present
    for i, a in ipairs(alts) do
        if not db.customOrder[a.guid] then
            db.customOrder[a.guid] = i
        end
    end

    local currentPos = nil
    for i, a in ipairs(alts) do
        if a.guid == guid then currentPos = i; break end
    end

    if currentPos then
        local targetPos = currentPos + delta
        if targetPos >= 1 and targetPos <= #alts then
            local otherAlt = alts[targetPos]
            local curOrder = db.customOrder[guid] or currentPos
            local otherOrder = db.customOrder[otherAlt.guid] or targetPos

            db.customOrder[guid] = otherOrder
            db.customOrder[otherAlt.guid] = curOrder
            db.sortOrder = "custom"

            if AM.UI and AM.UI.Refresh then AM.UI:Refresh() end
        end
    end
end

function Data:DeleteAlt(guid)
    self:PurgeAlt(guid)
end

function Data:PurgeAlt(guid)
    if not guid then return end
    local alts = GetGlobalAltsTable()
    alts[guid] = nil
    local db = GetDB()
    if db and db.customOrder then
        db.customOrder[guid] = nil
    end
    if AM.UI and AM.UI.Refresh then AM.UI:Refresh() end
end

function Data:PurgeAll()
    local alts = GetGlobalAltsTable()
    wipe(alts)
    self:UpdateAll()
    if AM.UI and AM.UI.Refresh then AM.UI:Refresh() end
end

-- ============================================================================
-- KEY ANNOUNCER & CHAT RESPONDER
-- ============================================================================

function Data:AnnounceKeystones(channel)
    channel = channel or (IsInRaid() and "RAID") or (IsInGroup() and "PARTY") or "EMOTE"
    local alts = self:GetAllAltsList()
    local lines = {}

    for _, alt in ipairs(alts) do
        if alt.keystone and alt.keystone.level and alt.keystone.level > 0 and alt.keystone.name ~= "" then
            local str = string.format("%s: +%d %s", alt.name, alt.keystone.level, alt.keystone.name)
            table.insert(lines, str)
        end
    end

    if #lines == 0 then
        print("|cff00c0ffGravityUI|r: No Mythic Keystones found on any alts.")
        return
    end

    if channel == "EMOTE" then
        print("|cff00c0ffGravityUI Alt Keystones:|r")
        for _, l in ipairs(lines) do print("  " .. l) end
    else
        SendChatMessage("--- GravityUI Alt Keystones ---", channel)
        for _, l in ipairs(lines) do
            SendChatMessage(l, channel)
        end
    end
end

-- ============================================================================
-- EVENT ENGINE
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
eventFrame:RegisterEvent("CHALLENGE_MODE_LEADERS_UPDATE")
eventFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("BOSS_KILL")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

local throttled = false
local function TriggerScan()
    if throttled then return end
    throttled = true
    C_Timer.After(0.8, function()
        throttled = false
        Data:UpdateAll()
        if AM.UI and AM.UI.Refresh then
            AM.UI:Refresh()
        end
    end)
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        Data:UpdateAll()
        C_Timer.After(1.5, function()
            Data:UpdateAll()
        end)
    elseif event == "CHAT_MSG_LOOT" then
        local msg = arg1
        local db = GetDB()
        if db and db.announceParty and msg and (msg:find("keystone:") or msg:find("item:180653") or msg:find("item:151086") or msg:find("item:229645") or msg:find("Schlüsselstein") or msg:find("Keystone")) then
            local link = msg:match("(|c%x+|Hitem:[^|]+|h%[[^%]]+%]%|h|r)") or msg:match("(|c%x+|Hkeystone:[^|]+|h%[[^%]]+%]%|h|r)")
            if link then
                local channel = (IsInRaid() and "RAID") or (IsInGroup() and "PARTY") or nil
                if channel then
                    SendChatMessage("New Keystone: " .. link, channel)
                end
            end
        end
        TriggerScan()
    elseif event == "PLAYER_LOGOUT" then
        Data:UpdateAll()
    else
        TriggerScan()
    end
end)
