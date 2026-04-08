
local ADDON_NAME, ns = ...

---------------------------------------------------------------------------
-- RAID BUFFS / BUFF REMINDERS
-- Ported from BuffReminders
---------------------------------------------------------------------------

local RaidBuffs = {}
ns.RaidBuffs = RaidBuffs
local visibilityCache = {}

-- ============================================================================
-- CONSTANTS & DEFINITIONS
-- ============================================================================

local ICON_SIZE = 32
local STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF" -- Default, updated in InitializeFrames

local function GetFontPath()
    if ns.Styling and type(ns.Styling.GetFontPath) == "function" then
        return ns.Styling:GetFontPath()
    end
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local general = ns.db and ns.db.profile and ns.db.profile.general
    local fontName = (general and general.font) or "Gravity"
    if LSM then return LSM:Fetch("font", fontName) end
    return "Fonts\\FRIZQT__.TTF"
end
local TEXCOORD_INSET = 0.08

-- Buff Definitions
local RAID_BUFFS = {
    { spellID = 1459, key = "intellect", name = "Arcane Intellect", class = "MAGE" },
    { spellID = 6673, key = "attackPower", name = "Battle Shout", class = "WARRIOR" },
    {
        spellID = { 381732, 381741, 381746, 381748, 381749, 381750, 381751, 381752, 381753, 381754, 381756, 381757, 381758 },
        key = "bronze",
        name = "Blessing of the Bronze",
        class = "EVOKER",
    },
    { spellID = 1126, key = "versatility", name = "Mark of the Wild", class = "DRUID" },
    { spellID = 21562, key = "stamina", name = "Power Word: Fortitude", class = "PRIEST" },
    { spellID = 462854, key = "skyfury", name = "Skyfury", class = "SHAMAN" },
}

local PRESENCE_BUFFS = {
    {
        spellID = { 381637, 5761 },
        key = "atrophicNumbingPoison",
        name = "Atrophic/Numbing Poison",
        class = "ROGUE",
        missingText = "NO\nPOISON",
    },
    { spellID = 465, key = "devotionAura", name = "Devotion Aura", class = "PALADIN", missingText = "NO\nAURA" },
    {
        spellID = 20707,
        key = "soulstone",
        name = "Soulstone",
        class = "WARLOCK",
        missingText = "NO\nSTONE",
        infoTooltip = "Ready Check Only|This buff is only shown during ready checks.",
    },
}

local TARGETED_BUFFS = {
    {
        spellID = 156910,
        key = "beaconOfFaith",
        name = "Beacon of Faith",
        class = "PALADIN",
        missingText = "NO\nFAITH",
        groupId = "beacons",
    },
    {
        spellID = 53563,
        key = "beaconOfLight",
        name = "Beacon of Light",
        class = "PALADIN",
        missingText = "NO\nLIGHT",
        groupId = "beacons",
        excludeTalentSpellID = 200025,
        iconOverride = 236247,
    },
    {
        spellID = 974,
        key = "earthShieldOthers",
        name = "Earth Shield",
        class = "SHAMAN",
        missingText = "NO\nES",
        infoTooltip = "May Show Extra Icon|Until you cast this, you might see both this and the Water/Lightning Shield reminder.",
    },
    {
        spellID = 369459,
        key = "sourceOfMagic",
        name = "Source of Magic",
        class = "EVOKER",
        beneficiaryRole = "HEALER",
        missingText = "NO\nSOURCE",
    },
    {
        spellID = 474750,
        key = "symbioticRelationship",
        name = "Symbiotic Relationship",
        class = "DRUID",
        missingText = "NO\nLINK",
    },
}

local SELF_BUFFS = {
    {
        spellID = 433583,
        key = "riteOfAdjuration",
        name = "Rite of Adjuration",
        class = "PALADIN",
        missingText = "NO\nRITE",
        enchantID = 7144,
        groupId = "paladinRites",
    },
    {
        spellID = 433568,
        key = "riteOfSanctification",
        name = "Rite of Sanctification",
        class = "PALADIN",
        missingText = "NO\nRITE",
        enchantID = 7143,
        groupId = "paladinRites",
    },
    {
        spellID = 2823,
        key = "roguePoisons",
        name = "Rogue Poisons",
        class = "ROGUE",
        missingText = "NO\nSELF\nPOISON",
        customCheck = function()
            local lethalPoisons = { 315584, 8679, 2823, 381664 }
            local nonLethalPoisons = { 5761, 381637, 3408 }
            local lethalCount = 0
            local nonLethalCount = 0

            for _, id in ipairs(lethalPoisons) do
               if C_UnitAuras.GetUnitAuraBySpellID("player", id) then lethalCount = lethalCount + 1 end
            end
            for _, id in ipairs(nonLethalPoisons) do
               if C_UnitAuras.GetUnitAuraBySpellID("player", id) then nonLethalCount = nonLethalCount + 1 end
            end

            local hasDragonTemperedBlades = IsPlayerSpell(381801)
            local requiredLethal = hasDragonTemperedBlades and 2 or 1
            local requiredNonLethal = hasDragonTemperedBlades and 2 or 1

            return lethalCount < requiredLethal or nonLethalCount < requiredNonLethal
        end,
    },
    {
        spellID = 232698, -- Shadowform (used for icon / IsPlayerSpell check)
        key = "shadowform",
        name = "Shadowform",
        class = "PRIEST",
        missingText = "NO\nFORM",
        customCheck = function()
            -- Shadowform is a shapeshift stance, NOT a normal aura.
            -- C_UnitAuras.GetUnitAuraBySpellID will NOT detect it.
            -- We must use the shapeshift API. Voidform and Dark Ascension
            -- appear as normal buffs and count as valid "form" states.

            -- 1. Check shapeshift forms (covers Shadowform stance)
            local numForms = GetNumShapeshiftForms()
            for i = 1, numForms do
                local _, active = GetShapeshiftFormInfo(i)
                if active then return false end -- In a form -> not missing
            end

            -- 2. Check Voidform / Dark Ascension buffs (replace Shadowform visually)
            local voidformIDs = { 194249, 391109 } -- Voidform aura, Dark Ascension aura
            for _, id in ipairs(voidformIDs) do
                if C_UnitAuras.GetUnitAuraBySpellID("player", id) then return false end
            end

            -- Not in any shadow form -> show reminder
            return true
        end,
    },
    {
        spellID = 382021,
        key = "earthlivingWeapon",
        name = "Earthliving Weapon",
        class = "SHAMAN",
        missingText = "NO\nEL",
        enchantID = 6498,
        groupId = "shamanImbues",
    },
    {
        spellID = 318038,
        key = "flametongueWeapon",
        name = "Flametongue Weapon",
        class = "SHAMAN",
        missingText = "NO\nFT",
        enchantID = 5400,
        groupId = "shamanImbues",
    },
    {
        spellID = 33757,
        key = "windfuryWeapon",
        name = "Windfury Weapon",
        class = "SHAMAN",
        missingText = "NO\nWF",
        enchantID = 5401,
        groupId = "shamanImbues",
    },
    {
        spellID = 974,
        buffIdOverride = 383648,
        key = "earthShieldSelfEO",
        name = "Earth Shield (Self)",
        class = "SHAMAN",
        missingText = "NO\nSELF ES",
        requiresTalentSpellID = 383010,
        groupId = "shamanShields",
    },
    {
        spellID = { 192106, 52127 },
        key = "waterLightningShieldEO",
        name = "Water/Lightning Shield",
        class = "SHAMAN",
        missingText = "NO\nSHIELD",
        requiresTalentSpellID = 383010,
        groupId = "shamanShields",
        iconByRole = { HEALER = 52127, DAMAGER = 192106, TANK = 192106 },
    },
    {
        spellID = { 974, 192106, 52127 },
        key = "shamanShieldBasic",
        name = "Shield (No Talent)",
        class = "SHAMAN",
        missingText = "NO\nSHIELD",
        excludeTalentSpellID = 383010,
        groupId = "shamanShields",
        iconByRole = { HEALER = 52127, DAMAGER = 192106, TANK = 192106 },
    },
}

local BUFF_GROUPS = {
    beacons = { displayName = "Beacons", missingText = "NO\nBEACONS" },
    shamanImbues = { displayName = "Shaman Imbues" },
    paladinRites = { displayName = "Paladin Rites" },
    shamanShields = { displayName = "Shaman Shields" },
}

-- Expose for Options Page
RaidBuffs.RAID_BUFFS = RAID_BUFFS
RaidBuffs.PRESENCE_BUFFS = PRESENCE_BUFFS
RaidBuffs.TARGETED_BUFFS = TARGETED_BUFFS
RaidBuffs.SELF_BUFFS = SELF_BUFFS
RaidBuffs.BUFF_GROUPS = BUFF_GROUPS

local CATEGORIES = { "raid", "presence", "targeted", "self", "custom" }
local CATEGORY_LABELS = {
    raid = "Raid",
    presence = "Presence",
    targeted = "Targeted",
    self = "Self",
    custom = "Custom",
}

local DEFAULTS = {
    customBuffs = {},
    position = { point = "CENTER", x = 0, y = 0 },
    locked = true,
    enabledBuffs = {},
    iconSize = 40,
    spacing = 2,
    showBuffReminder = true,
    reminderFontSize = 10,
    reminderColor = {1, 0.1, 0.1, 1},
    showOnlyInGroup = false,
    showOnlyInInstance = false,
    showOnlyPlayerClassBuff = false,
    showOnlyPlayerMissing = false,
    showOnlyOnReadyCheck = false,
    readyCheckDuration = 15,
    growDirection = "CENTER",
    showExpirationGlow = true,
    expirationThreshold = 15,
    glowColor = {0.95, 0.95, 0.32, 1},
    glowStyle = 1,
    optionsPanelScale = 1.2,
    splitCategories = {
        raid = false,
        presence = false,
        targeted = false,
        self = false,
        custom = false,
    },
    categorySettings = {
        main = {
            position = { point = "CENTER", x = 0, y = 0 },
            iconSize = 64,
            spacing = 0.2,
            growDirection = "CENTER",
            iconZoom = 8,
            borderSize = 2,
        },
        raid = { position = { point = "CENTER", x = 0, y = 60 } },
        presence = { position = { point = "CENTER", x = 0, y = 20 } },
        targeted = { position = { point = "CENTER", x = 0, y = -20 } },
        self = { position = { point = "CENTER", x = 0, y = -60 } },
        custom = { position = { point = "CENTER", x = 0, y = -100 } },
    },
}

-- Fill missing category defaults with main defaults
for k, v in pairs(DEFAULTS.categorySettings) do
    if k ~= "main" then
        for dk, dv in pairs(DEFAULTS.categorySettings.main) do
            if v[dk] == nil then v[dk] = dv end
        end
    end
end

-- ============================================================================
-- STATE
-- ============================================================================

local mainFrame
local buffFrames = {}
local categoryFrames = {}
local updateTicker
local inReadyCheck = false
local inCombat = false
local testMode = false
local testModeData = nil
local playerClass = nil
local optionsPanel

-- PERF: Hoisted to module scope to avoid per-call table allocation (GC pressure).
-- wipe() is called at the start of each UpdateDisplay pass.
local visibleBuffs = {
    main = {},
    raid = {},
    presence = {},
    targeted = {},
    self = {},
    custom = {},
}

-- ============================================================================
-- HELPERS
-- ============================================================================

local function GetSettings()
    if not ns.db.profile.raidBuffs then
        ns.db.profile.raidBuffs = CopyTable(DEFAULTS)
    end
     -- Migrate old settings if present and in old format (simple check: if enabledBuffs missing)
    if ns.db.profile.raidBuffs.enabledBuffs == nil then
         -- Backup old
         local old = CopyTable(ns.db.profile.raidBuffs)
         ns.db.profile.raidBuffs = CopyTable(DEFAULTS)
         if old.position then ns.db.profile.raidBuffs.position = old.position end
    end
    return ns.db.profile.raidBuffs
end

local function GetCategorySettings(category)
    local db = GetSettings()
    if db.categorySettings and db.categorySettings[category] then
        return db.categorySettings[category]
    end
    return DEFAULTS.categorySettings[category] or DEFAULTS.categorySettings.main
end

local function IsCategorySplit(category)
    local db = GetSettings()
    return db.splitCategories and db.splitCategories[category] == true
end

local function GetEffectiveCategory(frame)
    if frame.buffCategory and IsCategorySplit(frame.buffCategory) then
        return frame.buffCategory
    end
    return "main"
end

local function GetFontSize(scale, iconSizeOverride)
    local mainSettings = GetCategorySettings("main")
    local iconSize = iconSizeOverride or mainSettings.iconSize or 64
    local baseSize = iconSize * 0.32 -- TEXT_SCALE_RATIO
    return math.floor(baseSize * (scale or 1))
end

local function GetFrameFontSize(frame, scale)
    local effectiveCat = GetEffectiveCategory(frame)
    local catSettings = GetCategorySettings(effectiveCat)
    local iconSize = catSettings.iconSize or 64
    return GetFontSize(scale, iconSize)
end

local function FormatRemainingTime(seconds)
    local mins = math.floor(seconds / 60)
    if mins > 0 then return mins .. "m" else return math.floor(seconds) .. "s" end
end

local function UnitHasBuff(unit, spellIDs)
    if type(spellIDs) == "string" then
        -- Check for comma separated
        if spellIDs:find(",") then
            local ids = {}
            for id in string.gmatch(spellIDs, "([^,]+)") do
                local n = tonumber(strtrim(id))
                if n then table.insert(ids, n) end
            end
            spellIDs = ids
        else
            spellIDs = { tonumber(spellIDs) }
        end
    elseif type(spellIDs) ~= "table" then 
        spellIDs = { spellIDs } 
    end

    for _, id in ipairs(spellIDs) do
        if id then
            local auraData = C_UnitAuras.GetUnitAuraBySpellID(unit, id)
            if auraData then
                local remaining = nil
                if auraData.expirationTime and auraData.expirationTime > 0 then
                    remaining = auraData.expirationTime - GetTime()
                end
                return true, remaining, auraData.sourceUnit
            end
        end
    end
    return false, nil, nil
end

    -- Valid members check (Throttled visibility)
local function IsValid(unit)
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) or not UnitCanAssist("player", unit) then
        return false
    end
    
    -- Throttle UnitIsVisible (expensive C-API call)
    local now = GetTime()
    if not visibilityCache[unit] or (now - visibilityCache[unit].time > 5) then
        visibilityCache[unit] = { val = UnitIsVisible(unit), time = now }
    end
    return visibilityCache[unit].val
end

local function CountMissingBuff(spellIDs, buffKey, playerOnly, checkAny, unitList)
    local missing = 0
    local total = 0
    local minRemaining = nil
    

    if playerOnly or (not unitList or #unitList == 0) then
        total = 1
        local hasBuff, remaining = UnitHasBuff("player", spellIDs)
        if not hasBuff then missing = 1
        elseif remaining then minRemaining = remaining end
        return missing, total, minRemaining
    end

    local foundAny = false
    for _, unit in ipairs(unitList) do
         total = total + 1
         local hasBuff, remaining = UnitHasBuff(unit, spellIDs)
         if hasBuff then
             foundAny = true
             if remaining then
                 if not minRemaining or remaining < minRemaining then minRemaining = remaining end
             end
         else
             missing = missing + 1
         end
    end

    if checkAny and foundAny then
        missing = 0
    end

    return missing, total, minRemaining
end

local function ShouldShowSelfBuff(spellID, requiredClass, enchantID, requiresTalent, excludeTalent, buffIdOverride, customCheck)
    if playerClass ~= requiredClass then return nil end
    if requiresTalent and not IsPlayerSpell(requiresTalent) then return nil end
    if excludeTalent and IsPlayerSpell(excludeTalent) then return nil end
    if customCheck then return customCheck() end

    if enchantID then
        local _, _, _, mainHandEnchantID, _, _, _, offHandEnchantID = GetWeaponEnchantInfo()
        return mainHandEnchantID ~= enchantID and offHandEnchantID ~= enchantID
    end

    local ids = type(spellID) == "table" and spellID or { spellID }
    local knowsAny = false
    for _, id in ipairs(ids) do if IsPlayerSpell(id) then knowsAny = true break end end
    if not knowsAny then return nil end

    local hasBuff = UnitHasBuff("player", buffIdOverride or spellID)
    return not hasBuff
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function IsProviderAvailable(requiredClass)
    if not requiredClass then return true end
    if playerClass == requiredClass then return true end
    
    if not IsInGroup() then return false end
    
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
             local _, cls = UnitClass("raid"..i)
             if cls == requiredClass then return true end
        end
    else
        for i = 1, GetNumGroupMembers() - 1 do
             local _, cls = UnitClass("party"..i)
             if cls == requiredClass then return true end
        end
    end
    return false
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function CreateBuffFrame(buff, category)
    local frame = CreateFrame("Frame", "GravityUI_Buff_" .. buff.key, mainFrame)
    frame.key = buff.key
    frame.buffCategory = category
    frame.buffDef = buff
    
    local settings = GetCategorySettings(category)
    frame:SetSize(settings.iconSize, settings.iconSize)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints()
    frame.icon:SetTexCoord(TEXCOORD_INSET, 1-TEXCOORD_INSET, TEXCOORD_INSET, 1-TEXCOORD_INSET)
    
    local tex = buff.iconOverride
    if not tex then
         local id = type(buff.spellID) == "table" and buff.spellID[1] or buff.spellID
         tex = C_Spell.GetSpellTexture(id)
    end
    frame.icon:SetTexture(tex)

    frame.border = frame:CreateTexture(nil, "BACKGROUND")
    frame.border:SetPoint("TOPLEFT", -2, 2)
    frame.border:SetPoint("BOTTOMRIGHT", 2, -2)
    frame.border:SetColorTexture(0, 0, 0, 1)

    frame.count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
    frame.count:SetPoint("CENTER", 0, 0)
    frame.count:SetFont(STANDARD_TEXT_FONT, GetFontSize(1), "OUTLINE")
    frame.count:SetTextColor(1, 1, 1, 1)
    
    -- Tooltip
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(buff.name)
        if buff.spellID then 
             local id = type(buff.spellID) == "table" and buff.spellID[1] or buff.spellID
             GameTooltip:AddLine("ID: " .. id, 0.7, 0.7, 0.7) 
        end
        if buff.missingText then GameTooltip:AddLine(buff.missingText:gsub("\n", " "), 1, 1, 1) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame:Hide()
    return frame
end

local LCG = LibStub("LibCustomGlow-1.0", true)

-- Helper to stop glows
local function StopGlow(frame)
    if not LCG then return end
    LCG.PixelGlow_Stop(frame)
    LCG.AutoCastGlow_Stop(frame)
    LCG.ButtonGlow_Stop(frame)
end

-- Helper to start glow
local function ShowGlow(frame, style)
    if not LCG then return end
    StopGlow(frame)
    
    local db = GetSettings()
    local color = db.glowColor or {0.95, 0.95, 0.32, 1} 
    LCG.PixelGlow_Start(frame, color, 8, 0.25, 8, 2, 0, 0, false, nil)
end

local categoryFrames = {}

-- Helper to get category frame
local function GetFrameForCategory(cat)
    local db = GetSettings()
    if not categoryFrames[cat] then
         categoryFrames[cat] = CreateFrame("Frame", "GravityUI_RaidBuffs_"..cat, UIParent)
         categoryFrames[cat]:SetSize(1,1)
         local pos = db.categorySettings[cat].position or { point = "CENTER", x = 0, y = 0 }
         categoryFrames[cat]:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
         categoryFrames[cat].catKey = cat
         categoryFrames[cat]:EnableMouse(false)
    end
    return categoryFrames[cat]
end

local function UpdateDisplay()
    -- Allow UpdateDisplay in combat if Test Mode checks? No, strict hide in combat usually.
    if inCombat then 
        mainFrame:Hide() 
        for _, f in pairs(categoryFrames) do f:Hide() end
        return 
    end
    
    local db = GetSettings()
    local isTestMode = RaidBuffs.isTestMode
    
    if not db.enabled and not isTestMode then
        mainFrame:Hide()
        for _, f in pairs(categoryFrames) do f:Hide() end
        return
    end
    
    if isTestMode then
        mainFrame:Show() -- Ensure main frame base is shown logic-wise
    else
        -- Global Checks
        local hidden = false
        if db.showOnlyInGroup and GetNumGroupMembers() == 0 then hidden = true end
        if db.showOnlyInInstance then 
            local inInst, type = IsInInstance()
            if not inInst or type == "none" then hidden = true end 
        end
        if db.showOnlyOnReadyCheck and not inReadyCheck then hidden = true end
        
        if hidden then
            mainFrame:Hide()
            for _, f in pairs(categoryFrames) do f:Hide() end
            return
        end
    end

    -- PERF: Reuse module-scope table instead of allocating a new one each call.
    wipe(visibleBuffs.main)
    wipe(visibleBuffs.raid)
    wipe(visibleBuffs.presence)
    wipe(visibleBuffs.targeted)
    wipe(visibleBuffs["self"])
    wipe(visibleBuffs.custom)

    local function ProcessBuffFrame(buff, frame, isGroupCategory, catKey, unitList)
        if not frame then return end
        
        -- Check if Category Enabled
        if db.categorySettings[catKey] and db.categorySettings[catKey].enabled == false then
            frame:Hide(); StopGlow(frame); return
        end
        
        if db.enabledBuffs[buff.key] == false then 
            frame:Hide(); StopGlow(frame); return 
        end
        
        local showFrame = false
        local showGlow = false
        local showReminder = false
        local counterText = ""
        
        if isTestMode then
            showFrame = true
            showGlow = true
            showReminder = true
            counterText = "TEST"
        else
            -- Logic Checks
            if db.showOnlyPlayerClassBuff and buff.class and buff.class ~= playerClass and not buff.isCustom then
                frame:Hide(); StopGlow(frame); return
            end

            -- 1. Check Provider Availability (New Check)
            -- Only for group/targeted buffs that depend on a class.
            -- Self buffs are implicit (filtered by ShouldShowSelfBuff which checks playerClass)
            if buff.class and not isGroupCategory and catKey ~= "self" and catKey ~= "custom" then
                 -- Actually Targeted Buffs (e.g. Source of Magic from Evoker)
                 if not IsProviderAvailable(buff.class) then
                     frame:Hide(); StopGlow(frame); return
                 end
            elseif isGroupCategory then
                 -- Raid Buffs
                 if not IsProviderAvailable(buff.class) then
                     frame:Hide(); StopGlow(frame); return
                 end
            elseif catKey == "presence" then
                 if not IsProviderAvailable(buff.class) then
                     frame:Hide(); StopGlow(frame); return
                 end
            end
            
            if not isGroupCategory and not buff.isCustom then
                 local shouldShow = ShouldShowSelfBuff(buff.spellID, buff.class, buff.enchantID, buff.requiresTalentSpellID, buff.excludeTalentSpellID, buff.buffIdOverride, buff.customCheck)
                 if not shouldShow then 
                     frame:Hide(); StopGlow(frame); return 
                 end
            end

            local missing, total, minRem

            if buff.isCustom and buff.enchantID then
                local _, mainHandExp, _, mainHandEnchantID, _, offHandExp, _, offHandEnchantID = GetWeaponEnchantInfo()
                
                -- Check for Offhand Weapon (not Shield/Offhand Item)
                -- Slot 17 is Offhand
                local offHandLink = GetInventoryItemLink("player", 17)
                local requiresOffhand = false
                if offHandLink then
                    local _, _, _, _, _, _, _, _, _, _, _, classID = C_Item.GetItemInfo(offHandLink)
                    -- ClassID 2 is Weapon. 4 is Armor (Shields/Offhands).
                    if classID == 2 then requiresOffhand = true end
                end

                total = requiresOffhand and 2 or 1
                local found = 0
                if mainHandEnchantID == buff.enchantID then found = found + 1 end
                if requiresOffhand and offHandEnchantID == buff.enchantID then found = found + 1 end
                
                missing = total - found
                
                if missing == 0 then
                    -- Calculate minRem for glowing (GetWeaponEnchantInfo returns ms)
                    if mainHandEnchantID == buff.enchantID and mainHandExp then
                        minRem = mainHandExp / 1000
                    end
                    if requiresOffhand and offHandEnchantID == buff.enchantID and offHandExp then
                        local offRem = offHandExp / 1000
                        if not minRem or offRem < minRem then minRem = offRem end
                    end
                end
            else
                local playerOnly = (catKey == "self") or (catKey == "custom") or db.showOnlyPlayerMissing
                local checkAny = (catKey == "targeted" or catKey == "presence")
                missing, total, minRem = CountMissingBuff(buff.spellID, buff.key, playerOnly, checkAny, unitList)
            end
            local isExpiring = false
            if minRem and db.showExpirationGlow and db.expirationThreshold and minRem < (db.expirationThreshold * 60) then isExpiring = true end
            
            if not isGroupCategory and not missing and not buff.isCustom then
                 local hasBuff, rem = UnitHasBuff("player", buff.buffIdOverride or buff.spellID)
                 if hasBuff and rem and db.showExpirationGlow and db.expirationThreshold and rem < (db.expirationThreshold * 60) then
                     isExpiring = true
                     minRem = rem
                 elseif hasBuff then
                     frame:Hide(); StopGlow(frame); return
                 end
            end
            
            if missing > 0 then
                 showFrame = true
                 if isGroupCategory then
                     counterText = db.showOnlyPlayerMissing and "" or (total-missing).."/"..total
                 else
                     counterText = buff.missingText or ""
                 end
                 -- Reminder Logic
                 if db.showBuffReminder then
                      local canBuff = false
                      if frame.buffCategory == "self" or buff.isCustom then canBuff = true
                      elseif buff.class == playerClass then canBuff = true end
                      if canBuff then showReminder = true end
                 end
            elseif isExpiring then
                 showFrame = true
                 showGlow = true
                 counterText = FormatRemainingTime(minRem)
            end
        end

        if showFrame then
             frame.count:SetText(counterText)
             if showGlow then ShowGlow(frame, db.glowStyle or 1) else StopGlow(frame) end
             
             if frame.reminderText then
                  if showReminder and (isTestMode or db.showBuffReminder) then 
                      frame.reminderText:Show() 
                  else 
                      frame.reminderText:Hide() 
                  end
             end

             frame:Show()
             
             -- Assign to list
             if db.splitCategories[catKey] then
                 table.insert(visibleBuffs[catKey], frame)
             else
                 table.insert(visibleBuffs.main, frame)
             end
        else
             frame:Hide(); StopGlow(frame)
        end
    end

    -- Process All
    -- In Test Mode, we want to show at least ONE per category if available?
    -- Currently it loops ALL. If user has 20 enabled buffs, Test Mode shows 20 icons.
    -- This might be clutter, but it's accurate to "what if everything is missing".
    -- Accepted for now.
    -- Build valid unit list once per update
    local validUnits = {}
    if GetNumGroupMembers() > 0 then
        local inRaid = IsInRaid()
        for i = 1, GetNumGroupMembers() do
            local unit = inRaid and "raid"..i or (i==1 and "player" or "party"..(i-1))
            if IsValid(unit) then
                table.insert(validUnits, unit)
            end
        end
    end

    -- Process All
    for _, buff in ipairs(RAID_BUFFS) do ProcessBuffFrame(buff, buffFrames[buff.key], true, "raid", validUnits) end
    for _, buff in ipairs(PRESENCE_BUFFS) do 
        if isTestMode or buff.class == playerClass then ProcessBuffFrame(buff, buffFrames[buff.key], false, "presence", validUnits) 
        else if buffFrames[buff.key] then buffFrames[buff.key]:Hide() end end
    end
    for _, buff in ipairs(TARGETED_BUFFS) do ProcessBuffFrame(buff, buffFrames[buff.key], false, "targeted", validUnits) end
    for _, buff in ipairs(SELF_BUFFS) do ProcessBuffFrame(buff, buffFrames[buff.key], false, "self", validUnits) end
    if db.customBuffs then for k, b in pairs(db.customBuffs) do ProcessBuffFrame(b, buffFrames[k], false, "custom", validUnits) end end

    -- Layout Function
    local function LayoutFrames(frameList, parentFrame)
        if #frameList == 0 then 
            parentFrame:Hide()
            return 
        end
        parentFrame:Show()
        
        table.sort(frameList, function(a,b) return a.key < b.key end)
        
        local iconSize = db.iconSize or 64
        local spacing = db.spacing or (iconSize * 0.2)
        local totalWidth = #frameList * iconSize + (#frameList - 1) * spacing
        parentFrame:SetSize(totalWidth, iconSize)
        
        local grow = db.growDirection or "CENTER"
        for i, f in ipairs(frameList) do
            f:ClearAllPoints()
            f:SetParent(parentFrame) 
            if grow == "CENTER" then
                f:SetPoint("LEFT", parentFrame, "LEFT", (i-1)*(iconSize+spacing), 0)
            elseif grow == "LEFT" then
                f:SetPoint("RIGHT", parentFrame, "RIGHT", -(i-1)*(iconSize+spacing), 0)
            elseif grow == "RIGHT" then
                f:SetPoint("LEFT", parentFrame, "LEFT", (i-1)*(iconSize+spacing), 0)
            end
        end
    end

    -- Layout Main
    LayoutFrames(visibleBuffs.main, mainFrame)
    -- Layout Categories
    for cat, list in pairs(visibleBuffs) do
        if cat ~= "main" then
            LayoutFrames(list, GetFrameForCategory(cat))
        end
    end
end

local function UpdateAppearance()
    local db = GetSettings()
    local iconSize = db.iconSize or 64
    local labelSize = db.labelFontSize or 12
    local fontPath = STANDARD_TEXT_FONT
    
    for _, f in pairs(buffFrames) do
        f:SetSize(iconSize, iconSize)
        if f.count then f.count:SetFont(fontPath, labelSize, "OUTLINE") end
        
        if not f.reminderText then
             f.reminderText = f:CreateFontString(nil, "OVERLAY", "GameFontRedLarge")
             f.reminderText:SetPoint("TOP", f, "BOTTOM", 0, -5)
             f.reminderText:SetText("Buff")
             f.reminderText:Hide()
        end
        
        local remSize = db.reminderFontSize or 10
        local remColor = db.reminderColor or {1, 0.1, 0.1, 1}
        f.reminderText:SetFont(fontPath, remSize, "OUTLINE")
        f.reminderText:SetTextColor(remColor[1], remColor[2], remColor[3], remColor[4] or 1)
    end
end

function RaidBuffs:Refresh()
    UpdateAppearance()
    UpdateDisplay()
end

-- Mover Logic
local movers = {}

local function CreateSingleMover(name, frame, label)
    if movers[name] then return movers[name] end
    local m = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    m:SetSize(100, 50) 
    m:SetPoint("CENTER")
    m:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    m:SetBackdropColor(0, 0.75, 1, 0.3)
    m:SetBackdropBorderColor(0, 0.75, 1, 1)
    m:EnableMouse(true)
    m:SetMovable(true)
    m:RegisterForDrag("LeftButton")
    m:SetFrameStrata("DIALOG")
    
    local t = m:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("CENTER")
    t:SetText(label)
    
    m:SetScript("OnDragStart", function(self) self:StartMoving() end)
    m:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        local db = GetSettings()
        if frame == mainFrame then
             db.position = { point = point, x = x, y = y }
             frame:ClearAllPoints()
             frame:SetPoint(point, UIParent, point, x, y)
        elseif frame.catKey then
             if not db.categorySettings[frame.catKey] then db.categorySettings[frame.catKey] = {} end
             db.categorySettings[frame.catKey].position = { point = point, x = x, y = y }
             frame:ClearAllPoints()
             frame:SetPoint(point, UIParent, point, x, y)
        end
    end)
    m:Hide()
    movers[name] = m
    return m
end

function RaidBuffs:ToggleMover(forceState)
    local db = GetSettings()
    
    local mainMover = CreateSingleMover("GravityUI_Mover_Main", mainFrame, "Main / Shared Buffs")
    
    local shouldShow = false
    if forceState ~= nil then
        shouldShow = forceState
    else
        shouldShow = not mainMover:IsShown()
    end
    
    if not shouldShow then
        -- Toggle OFF
        RaidBuffs.isTestMode = false
        mainMover:Hide()
        for _, m in pairs(movers) do m:Hide() end
    else
        -- Show Main
        RaidBuffs.isTestMode = true
        mainMover:ClearAllPoints()
        mainMover:SetPoint(db.position.point, UIParent, db.position.point, db.position.x, db.position.y)
        mainMover:SetSize(math.max(200, db.iconSize*3), db.iconSize+10)
        mainMover:Show()
        
        -- Show Split Movers
        if db.splitCategories then
            for cat, split in pairs(db.splitCategories) do
                if split then
                    local catFrame = GetFrameForCategory(cat)
                    local m = CreateSingleMover("GravityUI_Mover_"..cat, catFrame, cat.." Buffs")
                    local pos = (db.categorySettings[cat] and db.categorySettings[cat].position) or { point="CENTER", x=0, y=0 }
                    m:ClearAllPoints()
                    m:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
                    m:SetSize(math.max(150, db.iconSize*2), db.iconSize+10)
                    m:Show()
                end
            end
        end
    end
    -- Trigger display update to show test patterns
    UpdateDisplay()
end

-- Custom Buffs Logic
function RaidBuffs:AddCustomBuff(spellID)
    local db = GetSettings()
    
    local isEnchant = false
    local originalInput = spellID
    local firstID = spellID
    
    -- Check for comma separated IDs (e.g. "123, 456, 789")
    if type(spellID) == "string" and spellID:find(",") then
        -- Extract first ID for metadata lookup
        local f = spellID:match("([^,%s]+)")
        if f then firstID = tonumber(strtrim(f)) end
    end

    -- Hybrid Input Support: "EnchantID:ItemID"
    -- Example: "7494:224440" (Tracks Enchant 7494, uses Icon/Name from Item 224440)
    local enchantID, itemID = string.match(spellID, "^(%d+)%s*:%s*(%d+)$")
    
    local spellName, icon
    
    if enchantID and itemID then
        firstID = tonumber(enchantID) -- Use Enchant ID as primary ID for key
        spellID = firstID -- For enchants, we store the ID as number usually
        itemID = tonumber(itemID)
        isEnchant = true
        local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(itemID)
        
        -- If item info isn't cached yet, it might return nil. 
        -- We can try to load it, but for now fallback or set immediately if available.
        if itemName then
            spellName = itemName
            icon = itemIcon
        else
            -- Fallback if item not cached (User might need to reload or re-add)
            spellName = "Enchant " .. enchantID .. " (Item " .. itemID .. ")"
            icon = 136244
            -- Trigger item load for next time
            C_Item.RequestLoadItemDataByID(itemID)
        end
    else
        -- Standard Spell Check
        -- Use firstID (which might be the only one)
        local lookupID = tonumber(firstID) or firstID
        if C_Spell and C_Spell.GetSpellInfo then
             local info = C_Spell.GetSpellInfo(lookupID)
             if info then spellName = info.name; icon = info.iconID end
        else
             spellName, _, icon = GetSpellInfo(lookupID)
        end
    end
    
    -- Fallback for raw Enchant ID (no item provided)
    if not spellName then
        local id = tonumber(spellID)
        if id then
            spellName = "Enchant " .. id
            icon = 136244 
            isEnchant = true
            
            -- Tooltip Scan Logic (Keep as fallback)
            local _, _, _, mainID, _, _, _, offID = GetWeaponEnchantInfo()
    -- ... (Keep existing tooltip scan logic below)
            
            -- Try to find the actual name from the weapon tooltip if currently equipped
            local _, _, _, mainID, _, _, _, offID = GetWeaponEnchantInfo()
            local slotID = nil
            if mainID == id then slotID = 16
            elseif offID == id then slotID = 17 end
            
            if slotID then
                local tooltipData = C_TooltipInfo and C_TooltipInfo.GetInventoryItem("player", slotID)
                if tooltipData and tooltipData.lines then
                    for _, line in ipairs(tooltipData.lines) do
                         local text = line.leftText
                         if text then
                             -- Logic: GetWeaponEnchantInfo ONLY tracks Temporary Enchants (Oils, Stones).
                             -- Temporary enchants always have a duration in the tooltip, e.g. "Name (2 hours)" or "Enchanted: Name (10 min)"
                             -- Permanent enchants (Runeforges) do NOT have a duration.
                             -- So we only accept lines that contain a duration pattern `(%d+ `
                             if text:find("%(%d+") then
                                 -- Try to strip the "Enchanted: " prefix if present
                                 local enchantName = text:match("^" .. (ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)")))
                                 
                                 -- If standard prefix failed, maybe it's just "Name (Duration)"
                                 if not enchantName then
                                     enchantName = text:match("^(.+) %(.+%)")
                                 end
                                 
                                 -- Clean up: Remove duration from the name if it was captured in the first regex (it shouldn't be if greedy, but safety)
                                 if enchantName then
                                     enchantName = enchantName:gsub(" %(.+%)", "")
                                     spellName = enchantName
                                     
                                     -- Better Icon Detection
                                     if spellName:find("Oil") or spellName:find("öl") then icon = 463543 end 
                                     if spellName:find("Stone") or spellName:find("stein") then icon = 136284 end
                                     break
                                 end
                             end
                         end
                    end
                end
            end
        end
    end

    if not spellName then return false, "Invalid Spell ID" end
    
    -- Safety: Ensure customBuffs table exists
    if not db.customBuffs then db.customBuffs = {} end
    
    local key = "custom_" .. spellID
    db.customBuffs[key] = {
        spellID = spellID,
        key = key,
        name = spellName,
        iconOverride = icon,
        -- Custom buffs treated as "Self" tracking (Always Check if enabled)
        isCustom = true,
        enchantID = isEnchant and tonumber(spellID) or nil,
    }
    
    -- Rebuild/Refresh
    if buffFrames[key] and buffFrames[key]:IsShown() then buffFrames[key]:Hide() end
    buffFrames[key] = CreateBuffFrame(db.customBuffs[key], "custom")
    RaidBuffs:Refresh()
    return true
end

function RaidBuffs:DeleteCustomBuff(key)
    local db = GetSettings()
    db.customBuffs[key] = nil
    if buffFrames[key] then
        buffFrames[key]:Hide()
        buffFrames[key] = nil
    end
    RaidBuffs:Refresh()
end

local function InitializeFrames()
    STANDARD_TEXT_FONT = GetFontPath()
    local db = GetSettings()
    
    mainFrame = CreateFrame("Frame", "GravityUI_RaidBuffs", UIParent)
    mainFrame:SetSize(200, 50)
    mainFrame:SetPoint(db.position.point, UIParent, db.position.point, db.position.x, db.position.y)
    mainFrame:EnableMouse(false) 
    
    -- Create Category Frames by default if split
    if db.splitCategories then
        for cat, split in pairs(db.splitCategories) do
            if split then GetFrameForCategory(cat) end
        end
    end
    
    -- Create Frames
    for _, buff in ipairs(RAID_BUFFS) do buffFrames[buff.key] = CreateBuffFrame(buff, "raid") end
    for _, buff in ipairs(SELF_BUFFS) do buffFrames[buff.key] = CreateBuffFrame(buff, "self") end
    for _, buff in ipairs(PRESENCE_BUFFS) do buffFrames[buff.key] = CreateBuffFrame(buff, "presence") end
    for _, buff in ipairs(TARGETED_BUFFS) do buffFrames[buff.key] = CreateBuffFrame(buff, "targeted") end
    
    if db.customBuffs then
        for key, buff in pairs(db.customBuffs) do
            buffFrames[key] = CreateBuffFrame(buff, "custom")
        end
    end

    -- Initial Appearance
    UpdateAppearance()
    -- Initial Display Trigger
    UpdateDisplay()

    -- Register with Movers
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("RaidBuffs", mainFrame, function(frame, enabled) RaidBuffs:ToggleMover(enabled) end, "Raid Buffs")
    end
end

-- ============================================================================
-- EVENT DRIVER (Replaces Ticker)
-- ============================================================================
local pendingUpdate = false
local function RequestUpdate(event)
    if pendingUpdate then return end
    
    local delay = 0.5
    if event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
        delay = 2.0 -- Throttle standard aura changes
    elseif event == "PLAYER_REGEN_DISABLED" or event == "READY_CHECK" then
        delay = 0.05 -- High priority
    end
    
    pendingUpdate = true
    C_Timer.After(delay, function()
        pendingUpdate = false
        UpdateDisplay()
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED") -- For weapon enchants
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("READY_CHECK_FINISHED")
eventFrame:RegisterEvent("READY_CHECK_CONFIRM")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        _, playerClass = UnitClass("player")
        InitializeFrames()
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        UpdateDisplay() -- Instant update on combat start (usually to hide)
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        RequestUpdate(event)
    elseif event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
        -- Simple filter: only care about player/party/raid
        if arg1 and (arg1 == "player" or string.find(arg1, "^party") or string.find(arg1, "^raid")) then
            RequestUpdate(event)
        end
    elseif event == "READY_CHECK" then
        inReadyCheck = true
        RequestUpdate(event)
    elseif event == "READY_CHECK_FINISHED" then
        inReadyCheck = false
        RequestUpdate(event)
    else
        -- Group updates
        RequestUpdate(event)
    end
end)

-- Slash command
SLASH_GRAVITYRAIDBUFFS1 = "/guibuffs"
SlashCmdList["GRAVITYRAIDBUFFS"] = function() RaidBuffs:ToggleMover() end

SLASH_GUIENCHANTS1 = "/guienchants"
SlashCmdList["GUIENCHANTS"] = function()
    local hasMain, mainExp, mainCharges, mainID, hasOff, offExp, offCharges, offID = GetWeaponEnchantInfo()
    print("GravityUI Enchants:")
    print("Main Hand: Has=", hasMain, "ID=", mainID)
    print("Off Hand: Has=", hasOff, "ID=", offID)
end
