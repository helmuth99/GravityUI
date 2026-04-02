local ADDON_NAME, ns = ...
local addon = ns.CooldownTracker

-- >> FontUtil.lua (Placeholder for missing util, simple proxy)
local FontUtil = {}
addon.Utils.FontUtil = FontUtil
function FontUtil:UpdateCooldownFontSize(cd, size, _, fontScale)
    if cd and cd.GetRegions then
        local regions = {cd:GetRegions()}
        for _, region in ipairs(regions) do
            if region:GetObjectType() == "FontString" then
                local font, _, flags = region:GetFont()
                if font then
                    local calculatedSize = math.max(8, (size * 0.45) * (fontScale or 1))
                    region:SetFont(font, calculatedSize, flags)
                end
            end
        end
    end
end

-- >> Array.lua
local ArrayUtil = {}
addon.Utils.Array = ArrayUtil
function ArrayUtil:Reverse(array)
	local i, j = 1, #array
	while i < j do
		array[i], array[j] = array[j], array[i]
		i = i + 1
		j = j - 1
	end
	return array
end
function ArrayUtil:Append(src, dst)
	for i = 1, #src do
		dst[#dst + 1] = src[i]
	end
end

-- >> Units.lua
local UnitUtil = {}
addon.Utils.Units = UnitUtil
local allPartyUnitsIds = {"player", "pet"}
local allRaidUnitsIds = {}
for i = 1, MAX_PARTY_MEMBERS do allPartyUnitsIds[#allPartyUnitsIds + 1] = "party" .. i end
for i = 1, MAX_PARTY_MEMBERS do allPartyUnitsIds[#allPartyUnitsIds + 1] = "partypet" .. i end
for i = 1, MAX_RAID_MEMBERS do allRaidUnitsIds[#allRaidUnitsIds + 1] = "raid" .. i end
for i = 1, MAX_RAID_MEMBERS do allRaidUnitsIds[#allRaidUnitsIds + 1] = "raidpet" .. i end

function UnitUtil:FriendlyUnits()
	if not IsInGroup() then return {} end
	local isRaid = IsInRaid()
	local units = isRaid and allRaidUnitsIds or allPartyUnitsIds
	local results = {}
	for i = 1, #units do
		local unit = units[i]
		local exists = UnitExists(unit)
		if not issecretvalue(exists) and exists then
			results[#results + 1] = unit
		end
	end
	return results
end

function UnitUtil:IsPet(unit)
	if string.find(unit, "pet", 1, true) then return true end
	if UnitIsUnit(unit, "pet") then return true end
	if UnitIsOtherPlayersPet(unit) then return true end
	return false
end

function UnitUtil:IsHealer(unit)
	local role = UnitGroupRolesAssigned(unit)
	return role == "HEALER"
end

function UnitUtil:FindHealers()
	local units = UnitUtil:FriendlyUnits()
	local healers = {}
	for _, unit in ipairs(units) do
		if UnitUtil:IsHealer(unit) then
			healers[#healers + 1] = unit
		end
	end
	return healers
end

function UnitUtil:IsFriend(unitToken) return UnitIsFriend("player", unitToken) end
function UnitUtil:IsEnemy(unitToken) return UnitIsEnemy("player", unitToken) end
function UnitUtil:IsCompoundUnit(unitToken) return string.find(unitToken, "target") ~= nil end

-- >> WoWEx.lua
local WoWEx = {}
addon.Utils.WoWEx = WoWEx
function WoWEx:IsAddOnEnabled(addonName)
    return C_AddOns.GetAddOnEnableState(addonName, UnitName("player")) == 2
end
function WoWEx:IsDandersEnabled()
    return WoWEx:IsAddOnEnabled("DandersFrames")
end
function WoWEx:CreateDuration(startTime, duration, modRate)
    local d = C_DurationUtil.CreateDuration()
    d:SetTimeFromStart(startTime, duration, modRate)
    return d
end

-- >> SpellCache.lua
local SpellCache = {}
addon.Utils.SpellCache = SpellCache
local spellTextureCache = {}
function SpellCache:GetSpellTexture(spellId)
	if not spellId then return nil end
	if issecretvalue(spellId) then return C_Spell.GetSpellTexture(spellId) end
	local cached = spellTextureCache[spellId]
	if not cached then
		cached = C_Spell.GetSpellTexture(spellId)
		spellTextureCache[spellId] = cached
	end
	return cached
end
function SpellCache:ClearCache()
	spellTextureCache = {}
end

-- >> SlotDistribution.lua
local SlotDistribution = {}
addon.Utils.SlotDistribution = SlotDistribution
function SlotDistribution.Calculate(containerCount, ccCount, defensiveCount, importantCount)
	local ccSlots, defensiveSlots, importantSlots = 0, 0, 0
	local activeCategories = 0
	if ccCount > 0 then activeCategories = activeCategories + 1 end
	if defensiveCount > 0 then activeCategories = activeCategories + 1 end
	if importantCount > 0 then activeCategories = activeCategories + 1 end

	if activeCategories == 0 then return 0, 0, 0 end

	if containerCount >= activeCategories then
		if ccCount > 0 then ccSlots = 1 end
		if defensiveCount > 0 then defensiveSlots = 1 end
		if importantCount > 0 then importantSlots = 1 end
		local remaining = containerCount - activeCategories
		while remaining > 0 do
			local allocated = false
			if ccCount > ccSlots then
				ccSlots = ccSlots + 1; remaining = remaining - 1; allocated = true
			end
			if defensiveCount > defensiveSlots and remaining > 0 then
				defensiveSlots = defensiveSlots + 1; remaining = remaining - 1; allocated = true
			end
			if importantCount > importantSlots and remaining > 0 then
				importantSlots = importantSlots + 1; remaining = remaining - 1; allocated = true
			end
			if not allocated then break end
		end
	else
		local remaining = containerCount
		while remaining > 0 do
			local allocated = false
			if ccCount > ccSlots then
				ccSlots = ccSlots + 1; remaining = remaining - 1; allocated = true
			end
			if defensiveCount > defensiveSlots and remaining > 0 then
				defensiveSlots = defensiveSlots + 1; remaining = remaining - 1; allocated = true
			end
			if importantCount > importantSlots and remaining > 0 then
				importantSlots = importantSlots + 1; remaining = remaining - 1; allocated = true
			end
			if not allocated then break end
		end
	end
	return ccSlots, defensiveSlots, importantSlots
end
