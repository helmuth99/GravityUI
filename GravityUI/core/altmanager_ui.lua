-- ============================================================================
-- GravityUI - Alt Manager Datagrid Dashboard
-- Pixel-perfect, glassmorphic account-wide character matrix (AlterEgo style)
-- ============================================================================
local ADDON_NAME, ns = ...

local LSM = LibStub("LibSharedMedia-3.0", true)

ns.AltManager = ns.AltManager or {}
local AM = ns.AltManager
AM.UI = {}
local UI = AM.UI

local mainFrame = nil
local leftRowFrames = {}
local charRowFrames = {}
UI.currentScrollX = 0

local LABEL_WIDTH = 155
local CHAR_WIDTH = 120
local ROW_HEIGHT = 20
local HEADER_ROW_HEIGHT = 22
local DEFAULT_VISIBLE_ALTS = 5

-- Great Vault Threshold Types (Enum.WeeklyRewardChestThresholdType)
local RAID_VAULT_TYPE    = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.Raid) or 0
local DUNGEON_VAULT_TYPE = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.Activities) or 1
local WORLD_VAULT_TYPE   = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.World) or 3

-- Season Dungeons with Teleport Spell IDs
local SEASON_DUNGEONS = {
    { name = "Altar of Fangs",        abbr = "AOF", mapId = 2993, challengeModeID = 588, teleports = {1286812} },
    { name = "Den of Nalorakk",       abbr = "DON", mapId = 2825, challengeModeID = 586, teleports = {1286807} },
    { name = "Kings' Rest",           abbr = "KR",  mapId = 1762, challengeModeID = 249, teleports = {1286831} },
    { name = "Murder Row",            abbr = "MR",  mapId = 2813, challengeModeID = 587, teleports = {1286809} },
    { name = "Ruby Life Pools",       abbr = "RLP", mapId = 2521, challengeModeID = 399, teleports = {393256} },
    { name = "Temple of Sethraliss",  abbr = "TOS", mapId = 1877, challengeModeID = 250, teleports = {1286828} },
    { name = "The Blinding Vale",     abbr = "TBV", mapId = 2859, challengeModeID = 584, teleports = {1286801} },
    { name = "Voidscar Arena",        abbr = "VA",  mapId = 2923, challengeModeID = 585, teleports = {1286804} },
}

local function GetDB()
    local db = ns.GetDB and ns.GetDB()
    if db and db.altManager then return db.altManager end
    return ns.Defaults and ns.Defaults.altManager
end

local function GetAccentColor()
    if ns.GetAccentColor then return ns.GetAccentColor() end
    return 0, 0.75, 1, 1
end

local function GetFont()
    local font = (ns.Styling and ns.Styling.GetFontPath and ns.Styling:GetFontPath()) or
                 (LSM and LSM:Fetch("font", ns.GetDB() and ns.GetDB().general and ns.GetDB().general.font or "Gravity")) or
                 "Fonts\\FRIZQT__.TTF"
    return font
end

local function GetKnownTeleport(dungeon)
    if not dungeon or not dungeon.teleports then return nil end
    for _, spellID in ipairs(dungeon.teleports) do
        if (C_SpellBook and C_SpellBook.IsSpellInSpellBook and C_SpellBook.IsSpellInSpellBook(spellID))
            or (IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID))
            or (IsSpellKnown and IsSpellKnown(spellID)) then
            return spellID
        end
    end
    return nil
end

-- ============================================================================
-- TOOLTIPS (1:1 with AlterEgo)
-- ============================================================================

local function ShowCharacterTooltip(anchor, alt)
    if not alt then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[alt.class] or { colorStr = "ffffffff" }
    GameTooltip:AddLine(string.format("|c%s%s|r |cffffffff(%s)|r", classColor.colorStr or "ffffffff", alt.name or "Unknown", alt.realm or ""))

    if alt.guild and alt.guild ~= "" then
        GameTooltip:AddLine(string.format("<%s>", alt.guild), 0.2, 0.9, 0.3)
    end

    GameTooltip:AddLine(string.format("Level %d %s", alt.level or 80, alt.race or ""), 1, 1, 1)
    if alt.faction and alt.faction ~= "" then
        GameTooltip:AddLine(alt.faction, 1, 1, 1)
    end

    local moneyAmount = alt.money or (alt.guid == UnitGUID("player") and GetMoney()) or 0
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(GetMoneyString(moneyAmount, true), 1, 1, 1)

    if alt.lastUpdated then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Last update:\n|cffffffff%s|r", date("%a %b %d %H:%M:%S %Y", alt.lastUpdated)), 1, 0.82, 0)
    end

    GameTooltip:Show()
end

local function ShowItemLevelTooltip(anchor, alt)
    if not alt then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(string.format("Item Level: |cffffffff%.1f|r", alt.ilvlEquipped or 0), 1, 1, 1)
    if alt.ilvlOverall and alt.ilvlOverall > 0 and alt.ilvlOverall ~= alt.ilvlEquipped then
        GameTooltip:AddLine(string.format("Equipped: %.1f  Overall: %.1f", alt.ilvlEquipped or 0, alt.ilvlOverall), 0.8, 0.8, 0.8)
    end
    GameTooltip:Show()
end

local function ShowRatingTooltip(anchor, alt)
    if not alt then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Mythic+ Rating", 1, 1, 1)

    local score = alt.mythicplus and alt.mythicplus.rating or 0
    GameTooltip:AddDoubleLine("Current Season:", string.format("|cffffffff%d|r", score), 1, 0.82, 0, 1, 1, 1)

    local history = alt.mythicplus and alt.mythicplus.runHistory or {}
    local numRuns = #history
    GameTooltip:AddDoubleLine("Runs this Season:", string.format("|cffffffff%d|r", numRuns), 1, 0.82, 0, 1, 1, 1)

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Highest Keys:", 1, 0.82, 0)
    for _, d in ipairs(SEASON_DUNGEONS) do
        local dInfo = alt.mythicplus and alt.mythicplus.dungeons and alt.mythicplus.dungeons[d.challengeModeID]
        local lvlStr = "-"
        local colStr = "ff888888"
        if dInfo and dInfo.bestLevel and dInfo.bestLevel > 0 then
            lvlStr = "+" .. dInfo.bestLevel
            colStr = dInfo.inTime and "ff4ade80" or "ffef4444"
        end
        GameTooltip:AddDoubleLine(d.name, string.format("|c%s%s|r", colStr, lvlStr), 1, 1, 1, 1, 1, 1)
    end

    GameTooltip:Show()
end

local function ShowKeystoneTooltip(anchor, alt)
    if not alt or not alt.keystone then return end
    if alt.keystone.link and alt.keystone.link ~= "" then
        GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(alt.keystone.link)
        GameTooltip:Show()
    else
        GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
        GameTooltip:AddLine(alt.keystone.name or "Current Keystone", 1, 1, 1)
        if alt.keystone.level and alt.keystone.level > 0 then
            GameTooltip:AddLine(string.format("Level +%d", alt.keystone.level), 1, 1, 1)
        else
            GameTooltip:AddLine("No Keystone", 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end
end

local function ShowVaultTooltip(anchor, alt, vaultType)
    if not alt then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Vault Progress", 1, 1, 1)

    local slots = {}
    if alt.vault and alt.vault.slots then
        for _, s in ipairs(alt.vault.slots) do
            if s.type == vaultType then
                table.insert(slots, s)
            end
        end
    end
    table.sort(slots, function(a, b) return (a.index or 0) < (b.index or 0) end)

    if vaultType == RAID_VAULT_TYPE then
        local thresholds = { 2, 4, 6 }
        for i = 1, 3 do
            local slot = slots[i]
            local thresh = thresholds[i] or (i * 2)
            local label = string.format("%d bosses:", thresh)
            local status = "Locked (0/" .. thresh .. ")"
            local colR, colG, colB = 0.55, 0.58, 0.65
            if slot and slot.completed then
                status = string.format("Unlocked (%s)", (slot.itemLevel and slot.itemLevel > 0 and (slot.itemLevel .. "+")) or "Heroic")
                colR, colG, colB = 1, 1, 1
            elseif slot and slot.progress then
                status = string.format("Locked (%d/%d)", slot.progress, thresh)
            end
            GameTooltip:AddDoubleLine(label, status, 1, 0.82, 0, colR, colG, colB)
        end

        -- Boss progress
        local seasonRaids = (AM.Data and AM.Data.GetSeasonRaids and AM.Data:GetSeasonRaids()) or {}
        local diffData = alt.raids and (alt.raids.Heroic or alt.raids.Normal or alt.raids.LFR)
        for _, raid in ipairs(seasonRaids) do
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(raid.name, 1, 0.82, 0)
            for _, bName in ipairs(raid.encounters) do
                local isKilled = false
                if diffData and diffData.bosses then
                    for _, b in ipairs(diffData.bosses) do
                        if b.name == bName and b.killed then isKilled = true; break end
                    end
                end
                if isKilled then
                    GameTooltip:AddLine(bName, 0.2, 0.9, 0.3)
                else
                    GameTooltip:AddLine(bName, 0.55, 0.58, 0.65)
                end
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Next Step:", 1, 0.82, 0)
        GameTooltip:AddLine("Defeat 1 more boss this week to unlock your next Great Vault reward.", 1, 1, 1, true)

    elseif vaultType == DUNGEON_VAULT_TYPE then
        local thresholds = { 1, 4, 8 }
        for i = 1, 3 do
            local slot = slots[i]
            local thresh = thresholds[i] or (i == 1 and 1 or (i == 2 and 4 or 8))
            local label = string.format("%d %s:", thresh, thresh == 1 and "dungeon" or "dungeons")
            local status = "Locked (0/" .. thresh .. ")"
            local colR, colG, colB = 0.55, 0.58, 0.65
            if slot and slot.completed then
                local lvlName = (slot.level and slot.level > 0) and ("Mythic " .. slot.level) or "Mythic 0"
                local ilvlStr = (slot.itemLevel and slot.itemLevel > 0 and (" (" .. slot.itemLevel .. "+)")) or ""
                status = lvlName .. ilvlStr
                colR, colG, colB = 1, 1, 1
            elseif slot and slot.progress then
                status = string.format("Locked (%d/%d)", slot.progress, thresh)
            end
            GameTooltip:AddDoubleLine(label, status, 1, 0.82, 0, colR, colG, colB)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Top Runs This Week:", 1, 0.82, 0)
        local topRuns = 0
        if alt.mythicplus and alt.mythicplus.runHistory then
            for _, r in ipairs(alt.mythicplus.runHistory) do
                if r.thisWeek then
                    topRuns = topRuns + 1
                    local rLvl = r.level or 0
                    local rName = (rLvl > 0) and ("Mythic " .. rLvl) or "Mythic 0"
                    GameTooltip:AddLine(rName, 1, 1, 1)
                    if topRuns >= 8 then break end
                end
            end
        end
        if topRuns == 0 then
            GameTooltip:AddLine("No runs recorded this week.", 0.6, 0.6, 0.6)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Next Step:", 1, 0.82, 0)
        GameTooltip:AddLine("Complete Mythic dungeons on level 2 or higher to improve your Great Vault rewards.", 1, 1, 1, true)

    elseif vaultType == WORLD_VAULT_TYPE then
        local thresholds = { 2, 4, 8 }
        for i = 1, 3 do
            local slot = slots[i]
            local thresh = thresholds[i] or (i == 1 and 2 or (i == 2 and 4 or 8))
            local label = string.format("%d activities:", thresh)
            local status = "Locked (0/" .. thresh .. ")"
            local colR, colG, colB = 0.55, 0.58, 0.65
            if slot and slot.completed then
                local ilvlStr = (slot.itemLevel and slot.itemLevel > 0 and (" (" .. slot.itemLevel .. "+)")) or ""
                status = string.format("Tier %d%s", slot.level or 8, ilvlStr)
                colR, colG, colB = 1, 1, 1
            elseif slot and slot.progress then
                status = string.format("Locked (%d/%d)", slot.progress, thresh)
            end
            GameTooltip:AddDoubleLine(label, status, 1, 0.82, 0, colR, colG, colB)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Next Step:", 1, 0.82, 0)
        GameTooltip:AddLine("Good job - You are done! There are no more rewards to improve.", 1, 1, 1, true)
    end

    GameTooltip:Show()
end

local function ShowPreyTooltip(anchor, alt, preyKey)
    if not alt then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Prey Hunt Progress", 1, 1, 1)

    local diffTitle = preyKey:gsub("^%l", string.upper)
    GameTooltip:AddDoubleLine("Difficulty:", diffTitle, 1, 0.82, 0, 1, 1, 1)

    local count = (alt.prey and alt.prey[preyKey]) or 0
    local colR, colG, colB = (count >= 4) and 0.2 or 1, (count >= 4) and 0.9 or 1, (count >= 4) and 0.3 or 1
    GameTooltip:AddDoubleLine("Hunts Completed:", string.format("%d / 4", count), 1, 0.82, 0, colR, colG, colB)
    GameTooltip:Show()
end

local function ShowDungeonTooltip(anchor, dungeon)
    if not dungeon then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    local spellID = GetKnownTeleport(dungeon)
    if spellID then
        GameTooltip:ClearLines()
        if GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(spellID)
        else
            GameTooltip:SetText(dungeon.name, 1, 1, 1)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("<Click to Teleport>", 0.2, 0.9, 0.3)
    else
        GameTooltip:SetText(dungeon.name, 1, 1, 1)
        GameTooltip:AddLine("Time this dungeon on level +10 or above to unlock teleportation.", 0.75, 0.75, 0.75, true)
    end
    GameTooltip:Show()
end

local function ShowRaidTooltip(anchor, alt, diffKey)
    if not alt then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Raid Progress", 1, 1, 1)
    GameTooltip:AddLine(string.format("Difficulty: |cffffffff%s|r", diffKey or "Normal"))

    local seasonRaids = (AM.Data and AM.Data.GetSeasonRaids and AM.Data:GetSeasonRaids()) or {}
    local diffData = alt and alt.raids and alt.raids[diffKey]

    for _, raid in ipairs(seasonRaids) do
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(raid.name, 1, 0.82, 0)
        for _, bName in ipairs(raid.encounters) do
            local isKilled = false
            if diffData and diffData.bosses then
                for _, b in ipairs(diffData.bosses) do
                    if b.name == bName and b.killed then
                        isKilled = true
                        break
                    end
                end
            end

            if isKilled then
                GameTooltip:AddLine(bName, 0.2, 0.9, 0.3)
            else
                GameTooltip:AddLine(bName, 0.55, 0.58, 0.65)
            end
        end
    end
    GameTooltip:Show()
end

local function ShowCurrencyTooltip(anchor, alt, currId)
    if not alt or not currId then return end
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    GameTooltip:SetCurrencyByID(currId)
    local cData = alt.currencies and alt.currencies[currId]
    if cData then
        local cHex = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[alt.class] and RAID_CLASS_COLORS[alt.class].colorStr) or "ffffffff"
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(string.format("|c%s%s|r's Owned:", cHex, alt.name or "Character"), string.format("|cffffffff%d|r", cData.quantity or 0), 1, 0.82, 0, 1, 1, 1)
        if cData.maxQuantity and cData.maxQuantity > 0 then
            GameTooltip:AddDoubleLine("Season Maximum:", string.format("|cffffffff%d|r", cData.maxQuantity), 1, 0.82, 0, 1, 1, 1)
            if cData.totalEarned and cData.totalEarned > 0 then
                local hasMax = (cData.totalEarned >= cData.maxQuantity)
                local col = hasMax and "|cffef4444" or "|cffffffff"
                GameTooltip:AddDoubleLine("Total Earned this Season:", string.format("%s%d / %d|r", col, cData.totalEarned, cData.maxQuantity), 1, 0.82, 0, 1, 1, 1)
            end
        end
        if cData.maxWeeklyQuantity and cData.maxWeeklyQuantity > 0 then
            local hasMaxW = (cData.quantityEarnedThisWeek or 0) >= cData.maxWeeklyQuantity
            local colW = hasMaxW and "|cffef4444" or "|cffffffff"
            GameTooltip:AddDoubleLine("Weekly Cap:", string.format("%s%d / %d|r", colW, cData.quantityEarnedThisWeek or 0, cData.maxWeeklyQuantity), 1, 0.82, 0, 1, 1, 1)
        end
    end
    GameTooltip:Show()
end

-- ============================================================================
-- ROW DEFINITIONS
-- ============================================================================

local function BuildRowDefinitions()
    local db = GetDB()
    local rows = {}

    -- 1. Character Section (Always shown)
    table.insert(rows, { type = "header", label = "Character" })
    table.insert(rows, { id = "char_name",     label = "Character",        category = "char" })
    table.insert(rows, { id = "char_realm",    label = "Realm",            category = "char" })
    table.insert(rows, { id = "char_ilvl",     label = "Item Level",       category = "char" })
    table.insert(rows, { id = "char_rating",   label = "Rating",           category = "char" })
    table.insert(rows, { id = "char_key",      label = "Current Keystone", category = "char" })

    -- 2. Great Vault Section
    if not db or db.showVault ~= false then
        table.insert(rows, { type = "header", label = "Great Vault" })
        table.insert(rows, { id = "vault_raid",    label = "Raids",            category = "vault", vaultType = RAID_VAULT_TYPE })
        table.insert(rows, { id = "vault_dungeon", label = "Dungeons",         category = "vault", vaultType = DUNGEON_VAULT_TYPE })
        table.insert(rows, { id = "vault_world",   label = "World",            category = "vault", vaultType = WORLD_VAULT_TYPE })
    end

    -- 3. Prey Hunts Section
    if not db or db.showPrey ~= false then
        table.insert(rows, { type = "header", label = "Prey Hunts" })
        table.insert(rows, { id = "prey_normal",    label = "Normal",    category = "prey", preyKey = "normal" })
        table.insert(rows, { id = "prey_hard",      label = "Hard",      category = "prey", preyKey = "hard" })
        table.insert(rows, { id = "prey_nightmare", label = "Nightmare", category = "prey", preyKey = "nightmare" })
    end

    -- 4. Dungeons Section (Season 18 / Current Season Dungeons)
    if not db or db.showMPlus ~= false then
        table.insert(rows, { type = "header", label = "Dungeons" })
        for _, d in ipairs(SEASON_DUNGEONS) do
            local texture = 0
            if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
                local _, _, _, tex = C_ChallengeMode.GetMapUIInfo(d.challengeModeID)
                texture = tex or 0
            end
            table.insert(rows, {
                id = "dungeon_" .. d.challengeModeID,
                label = d.name,
                icon = texture,
                category = "dungeon",
                dungeon = d,
                challengeModeID = d.challengeModeID,
                mapId = d.mapId,
            })
        end
    end

    -- 5. Raids Section
    if not db or db.showRaids ~= false then
        table.insert(rows, { type = "header", label = "Raids" })
        table.insert(rows, { id = "raid_lfr",    label = "LFR",    category = "raid", diffKey = "LFR" })
        table.insert(rows, { id = "raid_normal", label = "Normal", category = "raid", diffKey = "Normal" })
        table.insert(rows, { id = "raid_heroic", label = "Heroic", category = "raid", diffKey = "Heroic" })
        table.insert(rows, { id = "raid_mythic", label = "Mythic", category = "raid", diffKey = "Mythic" })
    end

    -- 6. Currencies Section (Current Season Mistcrests & Delves)
    if not db or db.showCurrencies ~= false then
        table.insert(rows, { type = "header", label = "Currencies" })
        local currIDs = AM.Data and AM.Data.GetTrackedCurrencyIDs and AM.Data:GetTrackedCurrencyIDs() or {}
        for _, currID in ipairs(currIDs) do
            local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currID)
            if info and info.name and info.name ~= "" then
                table.insert(rows, {
                    id = "currency_" .. currID,
                    label = info.name,
                    icon = info.iconFileID or 0,
                    category = "currency",
                    currId = currID,
                    quality = info.quality or 1,
                })
            end
        end
    end

    return rows
end

-- ============================================================================
-- HORIZONTAL SCROLL & NAVIGATION
-- ============================================================================

function UI:GetMaxScroll(numAlts, visibleAlts)
    return math.max(0, (numAlts - visibleAlts) * CHAR_WIDTH)
end

function UI:UpdateNavControls(numAlts, visibleAlts)
    if not mainFrame or not mainFrame.navFrame then return end
    local nav = mainFrame.navFrame
    if numAlts <= visibleAlts then
        nav:Hide()
        return
    end

    nav:Show()
    local maxScroll = self:GetMaxScroll(numAlts, visibleAlts)
    local cur = self.currentScrollX or 0

    local firstVisible = math.floor(cur / CHAR_WIDTH) + 1
    local lastVisible = math.min(numAlts, firstVisible + visibleAlts - 1)

    nav.text:SetText(string.format("|cff00c0ff%d|r-|cff00c0ff%d|r / |cffffffff%d|r", firstVisible, lastVisible, numAlts))

    if cur <= 0 then
        nav.btnPrev:SetAlpha(0.3)
        nav.btnPrev:EnableMouse(false)
    else
        nav.btnPrev:SetAlpha(1.0)
        nav.btnPrev:EnableMouse(true)
    end

    if cur >= maxScroll - 1 then
        nav.btnNext:SetAlpha(0.3)
        nav.btnNext:EnableMouse(false)
    else
        nav.btnNext:SetAlpha(1.0)
        nav.btnNext:EnableMouse(true)
    end
end

function UI:ScrollHorizontal(delta)
    local alts = (AM.Data and AM.Data.GetAllAltsList and AM.Data:GetAllAltsList()) or {}
    local numAlts = #alts
    local db = GetDB()
    local maxVisible = (db and db.visibleColumns and db.visibleColumns > 0 and db.visibleColumns) or DEFAULT_VISIBLE_ALTS
    local visibleAlts = math.min(math.max(numAlts, 1), maxVisible)
    local maxScroll = self:GetMaxScroll(numAlts, visibleAlts)

    if maxScroll <= 0 then
        self.currentScrollX = 0
        if mainFrame and mainFrame.charsScrollFrame then
            mainFrame.charsScrollFrame:SetHorizontalScroll(0)
        end
        self:UpdateNavControls(numAlts, visibleAlts)
        return
    end

    local cur = self.currentScrollX or 0
    local step = CHAR_WIDTH
    local target = cur - (delta * step)
    target = math.max(0, math.min(maxScroll, target))

    self.currentScrollX = target
    if mainFrame and mainFrame.charsScrollFrame then
        mainFrame.charsScrollFrame:SetHorizontalScroll(target)
    end
    self:UpdateNavControls(numAlts, visibleAlts)
end

-- ============================================================================
-- WINDOW CREATION
-- ============================================================================

function UI:CreateMainWindow()
    if mainFrame then return mainFrame end

    local f = CreateFrame("Frame", "GravityUI_AltManagerFrame", UIParent, "BackdropTemplate")
    f:SetSize(780, 800)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- Glassmorphic Dark Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.05, 0.07, 0.09, 0.96)
    f:SetBackdropBorderColor(0.16, 0.22, 0.30, 1)

    -- Top Accent Line
    local topGlow = f:CreateTexture(nil, "OVERLAY")
    topGlow:SetHeight(2)
    topGlow:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    topGlow:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    topGlow:SetColorTexture(GetAccentColor())
    f.topGlow = topGlow

    -- Title Bar
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -4)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -4)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
    title:SetFont(GetFont(), 13, "OUTLINE")
    title:SetText("|cff00c0ffGravity|r |cffffffffAlt Manager|r")
    f.title = title

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", 0, 0)
    closeBtn:SetNormalFontObject("GameFontNormalLarge")
    closeBtn:SetText("|cffaaaaaa×|r")
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    closeBtn:SetScript("OnEnter", function(self) self:SetText("|cffff5555×|r") end)
    closeBtn:SetScript("OnLeave", function(self) self:SetText("|cffaaaaaa×|r") end)

    -- Refresh Button
    local btnRefresh = CreateFrame("Button", nil, titleBar)
    btnRefresh:SetSize(18, 18)
    btnRefresh:SetPoint("RIGHT", closeBtn, "LEFT", -8, 0)
    local refreshIcon = btnRefresh:CreateTexture(nil, "ARTWORK")
    refreshIcon:SetAllPoints()
    refreshIcon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    refreshIcon:SetVertexColor(0.6, 0.8, 1, 0.9)
    btnRefresh.icon = refreshIcon
    btnRefresh:SetScript("OnClick", function()
        if AM.Data and AM.Data.UpdateAll then AM.Data:UpdateAll() end
        UI:Refresh()
    end)
    btnRefresh:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Refresh Alt Data", 1, 1, 1)
        GameTooltip:Show()
    end)
    btnRefresh:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(0.6, 0.8, 1, 0.9)
        GameTooltip:Hide()
    end)

    -- Announce Button (Chat Bubble Texture)
    local btnAnnounce = CreateFrame("Button", nil, titleBar)
    btnAnnounce:SetSize(18, 18)
    btnAnnounce:SetPoint("RIGHT", btnRefresh, "LEFT", -8, 0)
    local announceIcon = btnAnnounce:CreateTexture(nil, "ARTWORK")
    announceIcon:SetAllPoints()
    announceIcon:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Up")
    announceIcon:SetVertexColor(0.4, 0.9, 0.5, 0.9)
    btnAnnounce.icon = announceIcon
    btnAnnounce:SetScript("OnClick", function()
        if AM.Data and AM.Data.AnnounceKeystones then
            AM.Data:AnnounceKeystones()
        end
    end)
    btnAnnounce:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(0.6, 1, 0.7, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Announce Keystones", 1, 1, 1)
        GameTooltip:AddLine("Broadcasts all alts' keys to Party / Guild", 0.7, 0.8, 0.9)
        GameTooltip:Show()
    end)
    btnAnnounce:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(0.4, 0.9, 0.5, 0.9)
        GameTooltip:Hide()
    end)

    -- Horizontal Navigation Controls (<  1-5 / 12  >)
    local navFrame = CreateFrame("Frame", nil, titleBar)
    navFrame:SetSize(140, 22)
    navFrame:SetPoint("RIGHT", btnAnnounce, "LEFT", -14, 0)
    f.navFrame = navFrame

    local btnPrev = CreateFrame("Button", nil, navFrame, "BackdropTemplate")
    btnPrev:SetSize(18, 18)
    btnPrev:SetPoint("LEFT", navFrame, "LEFT", 0, 0)
    btnPrev:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    btnPrev:SetBackdropColor(0.12, 0.16, 0.22, 0.8)
    btnPrev:SetBackdropBorderColor(0.25, 0.35, 0.48, 1)
    local prevText = btnPrev:CreateFontString(nil, "OVERLAY")
    prevText:SetPoint("CENTER", btnPrev, "CENTER", -1, 0)
    prevText:SetFont(GetFont(), 11, "OUTLINE")
    prevText:SetText("<")
    prevText:SetTextColor(0.8, 0.9, 1, 1)
    btnPrev:SetScript("OnClick", function()
        UI:ScrollHorizontal(1)
    end)
    btnPrev:SetScript("OnEnter", function(self)
        local r, g, b = GetAccentColor()
        self:SetBackdropBorderColor(r, g, b, 1)
        prevText:SetTextColor(r, g, b, 1)
    end)
    btnPrev:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.35, 0.48, 1)
        prevText:SetTextColor(0.8, 0.9, 1, 1)
    end)
    navFrame.btnPrev = btnPrev

    local navText = navFrame:CreateFontString(nil, "OVERLAY")
    navText:SetPoint("CENTER", navFrame, "CENTER", 0, 0)
    navText:SetFont(GetFont(), 10, "")
    navText:SetTextColor(0.85, 0.88, 0.92, 1)
    navFrame.text = navText

    local btnNext = CreateFrame("Button", nil, navFrame, "BackdropTemplate")
    btnNext:SetSize(18, 18)
    btnNext:SetPoint("RIGHT", navFrame, "RIGHT", 0, 0)
    btnNext:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    btnNext:SetBackdropColor(0.12, 0.16, 0.22, 0.8)
    btnNext:SetBackdropBorderColor(0.25, 0.35, 0.48, 1)
    local nextText = btnNext:CreateFontString(nil, "OVERLAY")
    nextText:SetPoint("CENTER", btnNext, "CENTER", 1, 0)
    nextText:SetFont(GetFont(), 11, "OUTLINE")
    nextText:SetText(">")
    nextText:SetTextColor(0.8, 0.9, 1, 1)
    btnNext:SetScript("OnClick", function()
        UI:ScrollHorizontal(-1)
    end)
    btnNext:SetScript("OnEnter", function(self)
        local r, g, b = GetAccentColor()
        self:SetBackdropBorderColor(r, g, b, 1)
        nextText:SetTextColor(r, g, b, 1)
    end)
    btnNext:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.35, 0.48, 1)
        nextText:SetTextColor(0.8, 0.9, 1, 1)
    end)
    navFrame.btnNext = btnNext

    -- 1. Left Fixed Column Container (Labels)
    local leftContainer = CreateFrame("Frame", "GravityUI_AltManagerLeftCol", f)
    leftContainer:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -36)
    leftContainer:SetWidth(LABEL_WIDTH)
    leftContainer:SetHeight(800)
    f.leftContainer = leftContainer

    -- 2. Right Characters Scrollable Container
    local charsScrollFrame = CreateFrame("ScrollFrame", "GravityUI_AltManagerScroll", f)
    charsScrollFrame:SetPoint("TOPLEFT", leftContainer, "TOPRIGHT", 2, 0)
    charsScrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    charsScrollFrame:EnableMouseWheel(true)
    charsScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        UI:ScrollHorizontal(delta)
    end)
    f.charsScrollFrame = charsScrollFrame

    local charsContent = CreateFrame("Frame", "GravityUI_AltManagerCharsContent", charsScrollFrame)
    charsContent:SetSize(600, 800)
    charsContent:EnableMouseWheel(true)
    charsContent:SetScript("OnMouseWheel", function(self, delta)
        UI:ScrollHorizontal(delta)
    end)
    charsScrollFrame:SetScrollChild(charsContent)
    f.charsContent = charsContent

    tinsert(UISpecialFrames, "GravityUI_AltManagerFrame")
    f:Hide()

    mainFrame = f
    return f
end

-- ============================================================================
-- DATAGRID RENDERING
-- ============================================================================

local function FormatVaultSummary(alt, vaultType)
    if not alt or not alt.vault or not alt.vault.slots then return "|cff666666-  -  -|r" end
    local slots = {}
    for _, s in ipairs(alt.vault.slots) do
        if s.type == vaultType then
            table.insert(slots, s)
        end
    end
    table.sort(slots, function(a, b) return (a.index or 0) < (b.index or 0) end)

    local texts = {}
    for i = 1, 3 do
        local text = "-"
        local colStr = "ff666666" -- Grey

        local act = slots[i]
        if act and act.threshold and act.threshold > 0 and act.progress and act.progress >= act.threshold then
            colStr = "ff4ade80" -- Green
            if vaultType == RAID_VAULT_TYPE then
                local lvl = act.level or 0
                if lvl == 17 or lvl == 1 then text = "L"
                elseif lvl == 14 or lvl == 2 then text = "N"
                elseif lvl == 15 or lvl == 3 then text = "H"
                elseif lvl == 16 or lvl == 4 then text = "M"
                else text = "H" end
            elseif vaultType == DUNGEON_VAULT_TYPE then
                local difficultyID = C_WeeklyRewards and C_WeeklyRewards.GetDifficultyIDForActivityTier and C_WeeklyRewards.GetDifficultyIDForActivityTier(act.activityTierID or 0)
                if difficultyID == (DifficultyUtil and DifficultyUtil.ID and DifficultyUtil.ID.DungeonHeroic or 2) then
                    text = "H"
                else
                    text = tostring(act.level or 0)
                end
            elseif vaultType == WORLD_VAULT_TYPE then
                text = tostring(act.level or 0)
            else
                text = tostring(act.level or 0)
            end
        end

        table.insert(texts, string.format("|c%s%s|r", colStr, text))
    end
    return table.concat(texts, "  ")
end

function UI:Refresh()
    if not mainFrame or not mainFrame:IsShown() then return end

    local alts = (AM.Data and AM.Data.GetAllAltsList and AM.Data:GetAllAltsList()) or {}
    local numAlts = #alts
    local rowDefs = BuildRowDefinitions()
    local db = GetDB()

    local maxVisible = (db and db.visibleColumns and db.visibleColumns > 0 and db.visibleColumns) or DEFAULT_VISIBLE_ALTS
    local visibleAlts = math.min(math.max(numAlts, 1), maxVisible)
    local charsVisibleWidth = visibleAlts * CHAR_WIDTH
    local charsTotalWidth = math.max(numAlts * CHAR_WIDTH, charsVisibleWidth)

    -- Dynamic Window Width: Compact 1080p fit, fits up to visibleAlts
    local totalWinWidth = LABEL_WIDTH + 2 + charsVisibleWidth + 20
    totalWinWidth = math.max(totalWinWidth, 340)
    mainFrame:SetWidth(totalWinWidth)

    mainFrame.leftContainer:SetWidth(LABEL_WIDTH)
    mainFrame.charsScrollFrame:SetWidth(charsVisibleWidth)
    mainFrame.charsContent:SetWidth(charsTotalWidth)

    local currentY = 0

    for rIdx, row in ipairs(rowDefs) do
        local isHeader = (row.type == "header")
        local rHeight = isHeader and HEADER_ROW_HEIGHT or ROW_HEIGHT

        -- Zebra Background Colors
        local bgR, bgG, bgB, bgA
        if isHeader then
            bgR, bgG, bgB, bgA = 0.04, 0.06, 0.09, 0.95
        else
            local isEven = (rIdx % 2 == 0)
            bgR = isEven and 0.08 or 0.05
            bgG = isEven and 0.10 or 0.07
            bgB = isEven and 0.14 or 0.10
            bgA = 0.65
        end

        -- ==========================================
        -- 1. LEFT LABEL ROW (FIXED / STICKY)
        -- ==========================================
        if not leftRowFrames[rIdx] then
            local lrf = CreateFrame("Frame", nil, mainFrame.leftContainer, "BackdropTemplate")
            lrf:SetHeight(ROW_HEIGHT)
            lrf:SetWidth(LABEL_WIDTH)
            lrf:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })

            local labelBtn = CreateFrame("Button", nil, lrf, "InsecureActionButtonTemplate")
            labelBtn:RegisterForClicks("AnyUp", "AnyDown")
            labelBtn:SetAllPoints()
            lrf.labelBtn = labelBtn

            local icon = labelBtn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(14, 14)
            icon:SetPoint("LEFT", labelBtn, "LEFT", 6, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            lrf.icon = icon

            local label = labelBtn:CreateFontString(nil, "OVERLAY")
            label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            label:SetPoint("RIGHT", labelBtn, "RIGHT", -6, 0)
            label:SetFont(GetFont(), 10, "")
            label:SetJustifyH("LEFT")
            lrf.label = label

            leftRowFrames[rIdx] = lrf
        end

        local lrf = leftRowFrames[rIdx]
        lrf.isHeader = isHeader
        lrf.bgR, lrf.bgG, lrf.bgB, lrf.bgA = bgR, bgG, bgB, bgA
        lrf:SetHeight(rHeight)
        lrf:SetPoint("TOPLEFT", mainFrame.leftContainer, "TOPLEFT", 0, -currentY)
        lrf:SetBackdropColor(bgR, bgG, bgB, bgA)
        lrf:Show()

        lrf.labelBtn:SetScript("OnEnter", nil)
        lrf.labelBtn:SetScript("OnLeave", nil)
        if not InCombatLockdown() then
            lrf.labelBtn:SetAttribute("type", nil)
            lrf.labelBtn:SetAttribute("spell", nil)
        end

        local function SetRowHover(highlight)
            local crf = charRowFrames[rIdx]
            if highlight then
                local r, g, b = GetAccentColor()
                lrf:SetBackdropColor(r, g, b, 0.18)
                if crf then crf:SetBackdropColor(r, g, b, 0.18) end
            else
                lrf:SetBackdropColor(lrf.bgR, lrf.bgG, lrf.bgB, lrf.bgA)
                if crf then crf:SetBackdropColor(crf.bgR, crf.bgG, crf.bgB, crf.bgA) end
            end
        end

        lrf:SetScript("OnEnter", function()
            if not isHeader then SetRowHover(true) end
        end)
        lrf:SetScript("OnLeave", function()
            if not isHeader then SetRowHover(false) end
        end)

        if row.category == "dungeon" and row.dungeon then
            local spellID = GetKnownTeleport(row.dungeon)
            if spellID and not InCombatLockdown() then
                lrf.labelBtn:SetAttribute("type", "spell")
                lrf.labelBtn:SetAttribute("spell", spellID)
            end
            lrf.labelBtn:SetScript("OnEnter", function(self)
                ShowDungeonTooltip(self, row.dungeon)
                SetRowHover(true)
            end)
            lrf.labelBtn:SetScript("OnLeave", function()
                GameTooltip:Hide()
                SetRowHover(false)
            end)
        elseif row.category == "raid" then
            lrf.labelBtn:SetScript("OnEnter", function(self)
                local firstAlt = alts and alts[1]
                ShowRaidTooltip(self, firstAlt, row.diffKey)
                SetRowHover(true)
            end)
            lrf.labelBtn:SetScript("OnLeave", function()
                GameTooltip:Hide()
                SetRowHover(false)
            end)
        elseif row.category == "currency" then
            lrf.labelBtn:SetScript("OnEnter", function(self)
                SetRowHover(true)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetCurrencyByID(row.currId)
                GameTooltip:Show()
            end)
            lrf.labelBtn:SetScript("OnLeave", function()
                GameTooltip:Hide()
                SetRowHover(false)
            end)
        end

        if isHeader then
            lrf.icon:Hide()
            lrf.label:ClearAllPoints()
            lrf.label:SetPoint("LEFT", lrf.labelBtn, "LEFT", 8, 0)
            lrf.label:SetFont(GetFont(), 10, "OUTLINE")
            lrf.label:SetTextColor(0.92, 0.75, 0.18, 1) -- Gold Header
            lrf.label:SetText(row.label:upper())
        else
            lrf.label:ClearAllPoints()
            if row.icon and row.icon ~= 0 then
                lrf.icon:SetTexture(row.icon)
                lrf.icon:Show()
                lrf.label:SetPoint("LEFT", lrf.icon, "RIGHT", 6, 0)
            else
                lrf.icon:Hide()
                lrf.label:SetPoint("LEFT", lrf.labelBtn, "LEFT", 8, 0)
            end
            lrf.label:SetPoint("RIGHT", lrf.labelBtn, "RIGHT", -6, 0)
            lrf.label:SetFont(GetFont(), 10, "")
            if row.category == "currency" and row.quality then
                local qualityColors = {
                    [0] = { 0.62, 0.62, 0.62 }, -- Poor
                    [1] = { 1.00, 1.00, 1.00 }, -- Common
                    [2] = { 0.12, 1.00, 0.00 }, -- Uncommon (Green)
                    [3] = { 0.00, 0.44, 0.87 }, -- Rare (Blue)
                    [4] = { 0.64, 0.21, 0.93 }, -- Epic (Purple)
                    [5] = { 1.00, 0.50, 0.00 }, -- Legendary (Orange)
                    [6] = { 0.90, 0.80, 0.50 }, -- Artifact
                }
                local qCol = qualityColors[row.quality] or { 0.85, 0.88, 0.92 }
                lrf.label:SetTextColor(qCol[1], qCol[2], qCol[3], 1)
            else
                lrf.label:SetTextColor(0.85, 0.88, 0.92, 1)
            end
            lrf.label:SetText(row.label)
        end

        -- ==========================================
        -- 2. CHARACTERS ROW (IN SCROLL CONTAINER)
        -- ==========================================
        if not charRowFrames[rIdx] then
            local crf = CreateFrame("Frame", nil, mainFrame.charsContent, "BackdropTemplate")
            crf:SetHeight(ROW_HEIGHT)
            crf:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            crf:EnableMouseWheel(true)
            crf:SetScript("OnMouseWheel", function(self, delta)
                UI:ScrollHorizontal(delta)
            end)
            crf.cells = {}
            charRowFrames[rIdx] = crf
        end

        local crf = charRowFrames[rIdx]
        crf.isHeader = isHeader
        crf.bgR, crf.bgG, crf.bgB, crf.bgA = bgR, bgG, bgB, bgA
        crf:SetHeight(rHeight)
        crf:SetWidth(charsTotalWidth)
        crf:SetPoint("TOPLEFT", mainFrame.charsContent, "TOPLEFT", 0, -currentY)
        crf:SetBackdropColor(bgR, bgG, bgB, bgA)
        crf:Show()

        crf:SetScript("OnEnter", function()
            if not isHeader then SetRowHover(true) end
        end)
        crf:SetScript("OnLeave", function()
            if not isHeader then SetRowHover(false) end
        end)

        -- Character Cells per Row
        for cIdx, alt in ipairs(alts) do
            if not crf.cells[cIdx] then
                local cell = CreateFrame("Button", nil, crf, "InsecureActionButtonTemplate")
                cell:RegisterForClicks("AnyUp", "AnyDown")
                cell:SetHeight(rHeight)
                cell:SetWidth(CHAR_WIDTH)
                cell:EnableMouseWheel(true)
                cell:SetScript("OnMouseWheel", function(self, delta)
                    UI:ScrollHorizontal(delta)
                end)

                local icon = cell:CreateTexture(nil, "ARTWORK")
                icon:SetSize(14, 14)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                cell.icon = icon

                local text = cell:CreateFontString(nil, "OVERLAY")
                text:SetPoint("CENTER", cell, "CENTER", 0, 0)
                text:SetFont(GetFont(), 10, "")
                cell.text = text

                -- Skulls frame for Raids (9 skulls)
                local skullsFrame = CreateFrame("Frame", nil, cell)
                skullsFrame:SetAllPoints()
                cell.skullsFrame = skullsFrame
                cell.skulls = {}
                for s = 1, 9 do
                    local skull = skullsFrame:CreateTexture(nil, "ARTWORK")
                    skull:SetSize(10, 10)
                    local xOffset = (s == 1) and 4 or (4 + ((s - 1) * 12) + 3)
                    skull:SetPoint("LEFT", skullsFrame, "LEFT", xOffset, 0)
                    skull:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                    cell.skulls[s] = skull
                end

                crf.cells[cIdx] = cell
            end

            local cell = crf.cells[cIdx]
            cell:SetHeight(rHeight)
            cell:SetPoint("LEFT", crf, "LEFT", (cIdx - 1) * CHAR_WIDTH, 0)
            cell:Show()

            cell.icon:Hide()
            cell.skullsFrame:Hide()
            cell.text:Show()
            cell.text:SetTextColor(0.9, 0.9, 0.9, 1)
            cell:SetScript("OnEnter", nil)
            cell:SetScript("OnLeave", nil)
            cell:SetScript("OnMouseUp", nil)

            if not InCombatLockdown() then
                cell:SetAttribute("type", nil)
                cell:SetAttribute("spell", nil)
            end

            if isHeader then
                cell.text:SetText("")
            elseif row.id == "char_name" then
                local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[alt.class] or { r = 1, g = 1, b = 1 }
                local charNameStr = string.format("|c%s%s|r", classColor.colorStr or "ffffffff", alt.name or "Unknown")
                cell.text:SetText(charNameStr)
                cell.text:Show()

                local iconTex = (alt.specIcon and alt.specIcon ~= 0 and alt.specIcon) or
                                (alt.class and ("Interface\\Icons\\ClassIcon_" .. alt.class)) or
                                nil

                if iconTex then
                    cell.icon:SetTexture(iconTex)
                    cell.icon:ClearAllPoints()
                    cell.icon:SetPoint("RIGHT", cell.text, "LEFT", -4, 0)
                    cell.icon:Show()
                    cell.text:ClearAllPoints()
                    cell.text:SetPoint("CENTER", cell, "CENTER", 8, 0)
                else
                    cell.icon:Hide()
                    cell.text:ClearAllPoints()
                    cell.text:SetPoint("CENTER", cell, "CENTER", 0, 0)
                end

                cell:SetScript("OnMouseUp", function(_, btn)
                    if btn == "RightButton" and alt.guid ~= UnitGUID("player") then
                        AM.Data:PurgeAlt(alt.guid)
                    end
                end)
                cell:SetScript("OnEnter", function(self)
                    ShowCharacterTooltip(self, alt)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.id == "char_realm" then
                cell.text:ClearAllPoints(); cell.text:SetPoint("CENTER")
                cell.text:SetTextColor(0.65, 0.72, 0.8, 1)
                cell.text:SetText(alt.realm or "")
                cell:SetScript("OnEnter", function(self)
                    ShowCharacterTooltip(self, alt)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.id == "char_ilvl" then
                cell.text:ClearAllPoints(); cell.text:SetPoint("CENTER")
                cell.text:SetTextColor(0.66, 0.45, 0.95, 1) -- Epic Purple
                cell.text:SetText(string.format("%.1f", alt.ilvlEquipped or 0))
                cell:SetScript("OnEnter", function(self)
                    ShowItemLevelTooltip(self, alt)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.id == "char_rating" then
                cell.text:ClearAllPoints(); cell.text:SetPoint("CENTER")
                local score = (alt.mythicplus and alt.mythicplus.rating) or 0
                local scoreHex = "ffffffff"
                if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
                    local scCol = C_ChallengeMode.GetDungeonScoreRarityColor(score)
                    if scCol and scCol.GenerateHexColor then scoreHex = scCol:GenerateHexColor() end
                end
                cell.text:SetText(string.format("|c%s%d|r", scoreHex, score))
                cell:SetScript("OnEnter", function(self)
                    ShowRatingTooltip(self, alt)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.id == "char_key" then
                cell.text:ClearAllPoints(); cell.text:SetPoint("CENTER")
                local key = alt.keystone
                if key and key.level and key.level > 0 then
                    cell.text:SetText(string.format("|c%s+%d %s|r", key.color or "ffffffff", key.level, (key.name or ""):sub(1, 10)))
                else
                    cell.text:SetText("|cff666666-|r")
                end
                cell:SetScript("OnEnter", function(self)
                    ShowKeystoneTooltip(self, alt)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.category == "vault" then
                cell.text:ClearAllPoints(); cell.text:SetPoint("CENTER")
                cell.text:SetText(FormatVaultSummary(alt, row.vaultType))
                cell:SetScript("OnEnter", function(self)
                    ShowVaultTooltip(self, alt, row.vaultType)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.category == "prey" then
                cell.text:ClearAllPoints(); cell.text:SetPoint("CENTER")
                local count = (alt.prey and alt.prey[row.preyKey]) or 0
                if count >= 4 then
                    cell.text:SetText(string.format("|cff4ade80%d / 4|r", count))
                elseif count > 0 then
                    cell.text:SetText(string.format("|cffffffff%d / 4|r", count))
                else
                    cell.text:SetText("|cff666666-|r")
                end
                cell:SetScript("OnEnter", function(self)
                    ShowPreyTooltip(self, alt, row.preyKey)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.category == "dungeon" then
                cell.text:ClearAllPoints(); cell.text:SetPoint("CENTER")
                local dInfo = alt.mythicplus and alt.mythicplus.dungeons and alt.mythicplus.dungeons[row.challengeModeID]
                if dInfo and dInfo.bestLevel and dInfo.bestLevel > 0 then
                    local colStr = dInfo.inTime and "|cff4ade80+" or "|cffef4444+"
                    cell.text:SetText(colStr .. dInfo.bestLevel .. "|r")
                else
                    cell.text:SetText("|cff666666-|r")
                end

                if row.dungeon then
                    local spellID = GetKnownTeleport(row.dungeon)
                    if spellID and not InCombatLockdown() then
                        cell:SetAttribute("type", "spell")
                        cell:SetAttribute("spell", spellID)
                    end
                end

                cell:SetScript("OnEnter", function(self)
                    ShowDungeonTooltip(self, row.dungeon)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.category == "raid" then
                cell.text:Hide()
                cell.skullsFrame:Show()
                local diff = alt.raids and alt.raids[row.diffKey]
                for s = 1, 9 do
                    local skull = cell.skulls[s]
                    if skull then
                        if diff and diff.bosses and diff.bosses[s] and diff.bosses[s].killed then
                            skull:SetVertexColor(0.2, 0.9, 0.3, 1)
                            skull:SetAlpha(1.0)
                        else
                            skull:SetVertexColor(0.35, 0.38, 0.45, 0.25)
                            skull:SetAlpha(0.25)
                        end
                    end
                end

                cell:SetScript("OnEnter", function(self)
                    ShowRaidTooltip(self, alt, row.diffKey)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)

            elseif row.category == "currency" then
                cell.text:ClearAllPoints(); cell.text:SetPoint("CENTER")
                local cData = alt.currencies and alt.currencies[row.currId]
                local meta = (AM.Data and AM.Data.GetCurrencyMetadata and AM.Data:GetCurrencyMetadata(row.currId)) or {}
                
                local charQuantity = cData and cData.quantity or 0
                local totalEarned = cData and cData.totalEarned or charQuantity

                local globalTbl = (_G.GravityUI_DB and _G.GravityUI_DB.global and _G.GravityUI_DB.global.altManager) or (ns.db and ns.db.global and ns.db.global.altManager)
                local globalMax = globalTbl and globalTbl.currencyCaps and globalTbl.currencyCaps[row.currId] or 0
                
                local maxQuantity = (cData and cData.maxQuantity and cData.maxQuantity > 0 and cData.maxQuantity) or (globalMax > 0 and globalMax) or meta.defaultMax or 0
                local maxWeekly = cData and cData.maxWeeklyQuantity or 0
                local earnedThisWeek = cData and cData.quantityEarnedThisWeek or 0
                local useTotal = (meta.useTotalEarned == true) or (cData and cData.useTotalEarnedForMaxQty == true)

                local hasEarnedMax = false
                if maxQuantity > 0 then
                    if useTotal then
                        hasEarnedMax = (totalEarned >= maxQuantity) or (charQuantity >= maxQuantity)
                    else
                        hasEarnedMax = (charQuantity >= maxQuantity)
                    end
                end
                if maxWeekly > 0 and earnedThisWeek >= maxWeekly then
                    hasEarnedMax = true
                end

                local iconStr = ""
                if row.icon and row.icon ~= 0 then
                    iconStr = string.format("|T%s:13:13:0:0:64:64:5:59:5:59|t ", tostring(row.icon))
                end

                if charQuantity > 0 then
                    if hasEarnedMax then
                        cell.text:SetText(string.format("%s|cffef4444%d|r", iconStr, charQuantity))
                    else
                        cell.text:SetText(string.format("%s|cffffffff%d|r", iconStr, charQuantity))
                    end
                else
                    if cData and totalEarned > 0 then
                        if hasEarnedMax then
                            cell.text:SetText(string.format("%s|cffef44440|r", iconStr))
                        else
                            cell.text:SetText(string.format("%s|cff8888880|r", iconStr))
                        end
                    elseif cData then
                        cell.text:SetText(string.format("%s|cff8888880|r", iconStr))
                    else
                        cell.text:SetText("|cff666666-|r")
                    end
                end

                cell:SetScript("OnEnter", function(self)
                    ShowCurrencyTooltip(self, alt, row.currId)
                    SetRowHover(true)
                end)
                cell:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                    SetRowHover(false)
                end)
            end
        end

        -- Hide unused cells in this row
        for unused = numAlts + 1, #crf.cells do
            if crf.cells[unused] then crf.cells[unused]:Hide() end
        end

        currentY = currentY + rHeight
    end

    -- Hide unused rows
    for remRow = #rowDefs + 1, #leftRowFrames do
        if leftRowFrames[remRow] then leftRowFrames[remRow]:Hide() end
    end
    for remRow = #rowDefs + 1, #charRowFrames do
        if charRowFrames[remRow] then charRowFrames[remRow]:Hide() end
    end

    -- Dynamically set window height so all content fits perfectly on screen
    local neededHeight = currentY + 46
    mainFrame:SetHeight(neededHeight)
    mainFrame.leftContainer:SetHeight(currentY)
    mainFrame.charsScrollFrame:SetHeight(currentY)
    mainFrame.charsContent:SetHeight(currentY)

    -- Scroll clamping & update controls
    local maxScroll = self:GetMaxScroll(numAlts, visibleAlts)
    self.currentScrollX = math.max(0, math.min(maxScroll, self.currentScrollX or 0))
    mainFrame.charsScrollFrame:SetHorizontalScroll(self.currentScrollX)
    self:UpdateNavControls(numAlts, visibleAlts)
end

function UI:ToggleWindow()
    local f = self:CreateMainWindow()
    if f:IsShown() then
        f:Hide()
    else
        if AM.Data and AM.Data.UpdateAll then AM.Data:UpdateAll() end
        f:Show()
        self:Refresh()
    end
end

-- Slash Commands
SLASH_GRAVITYALT1 = "/guialt"
SLASH_GRAVITYALT2 = "/galt"
SLASH_GRAVITYALT3 = "/alt"
SlashCmdList["GRAVITYALT"] = function()
    UI:ToggleWindow()
end
