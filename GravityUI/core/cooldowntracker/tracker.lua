local ADDON_NAME, ns = ...
local addon = ns.CooldownTracker

local wowEx = addon.Utils.WoWEx
local iconSlotContainer = addon.Core.IconSlotContainer
local frames = addon.Core.Frames
local spellCache = addon.Utils.SpellCache
local units = addon.Utils.Units
local unitAuraWatcher = addon.Core.UnitAuraWatcher
local inspector = addon.Core.Inspector
local fcdTalents = addon.Core.FriendlyCooldownTalents
local slotDistribution = addon.Utils.SlotDistribution

local tolerance = 0.5
local castWindow = 0.15
local evidenceTolerance = 0.15

local lastDebuffTime = {}
local lastShieldTime = {}
local lastCastTime = {}
local lastUnitFlagsTime = {}
local lastFeignDeathTime = {}
local lastFeignDeathState = {}

local function BuildEvidenceSet(unit, detectionTime)
	local ev = nil
	if lastDebuffTime[unit] and math.abs(lastDebuffTime[unit] - detectionTime) <= evidenceTolerance then
		ev = ev or {}
		ev.Debuff = true
	end
	if lastShieldTime[unit] and math.abs(lastShieldTime[unit] - detectionTime) <= evidenceTolerance then
		ev = ev or {}
		ev.Shield = true
	end
	if lastFeignDeathTime[unit] and math.abs(lastFeignDeathTime[unit] - detectionTime) <= castWindow then
		ev = ev or {}
		ev.FeignDeath = true
	elseif lastUnitFlagsTime[unit] and math.abs(lastUnitFlagsTime[unit] - detectionTime) <= castWindow then
		ev = ev or {}
		ev.UnitFlags = true
	end
	if lastCastTime[unit] then
		local t = type(lastCastTime[unit]) == "table" and lastCastTime[unit].Time or lastCastTime[unit]
		local sid = type(lastCastTime[unit]) == "table" and lastCastTime[unit].SpellId or nil
		if math.abs(t - detectionTime) <= castWindow then
			ev = ev or {}
			ev.Cast = true
			ev.CastSpellId = sid
		end
	end
	return ev
end

local rules = {
	bySpec = {
		[65] = { -- Holy Paladin
			{ BuffDuration = 12, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 31884, MinDuration = true, ExcludeIfTalent = 216331 },
			{ BuffDuration = 10, Cooldown = 60, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 216331, MinDuration = true, RequiresTalent = 216331 },
			{ BuffDuration = 8, Cooldown = 300, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 },
			{ BuffDuration = 8, Cooldown = 60, BigDefensive = true, Important = true, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 498 },
			{ BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692 },
			{ BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022, ExcludeIfTalent = 5692 },
			{ BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940 },
		},
		[66] = { -- Protection Paladin
			{ BuffDuration = 25, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, MinDuration = true, RequiresEvidence = "Cast", SpellId = 31884, ExcludeIfTalent = 389539 },
			{ BuffDuration = 20, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, MinDuration = true, RequiresEvidence = "Cast", SpellId = 389539, RequiresTalent = 389539, ExcludeIfTalent = 31884 },
			{ BuffDuration = 8, Cooldown = 300, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 },
			{ BuffDuration = 8, Cooldown = 90, BigDefensive = true, Important = true, ExternalDefensive = false, SpellId = 31850, RequiresEvidence = "Cast" },
			{ BuffDuration = 8, Cooldown = 180, BigDefensive = true, Important = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 86659 },
			{ BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692 },
			{ BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022, ExcludeIfTalent = 5692 },
			{ BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940 },
		},
		[70] = { -- Retribution Paladin
			{ BuffDuration = 24, Cooldown = 60, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 31884, ExcludeIfTalent = 458359 },
			{ BuffDuration = 8, Cooldown = 300, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 },
			{ BuffDuration = 8, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = { "Cast", "Shield" }, SpellId = 403876 },
			{ BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692 },
			{ BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022, ExcludeIfTalent = 5692 },
			{ BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940 },
		},
		[62] = { { BuffDuration = 15, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 365350 } },
		[63] = { { BuffDuration = 10, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 190319, MinDuration = true } },
		[71] = {
			{ BuffDuration = 8, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 118038 },
			{ BuffDuration = 20, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 107574, MinDuration = true, RequiresTalent = 107574 },
		},
		[72] = {
			{ BuffDuration = 8, Cooldown = 108, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 184364, RequiresTalent = 184364 },
			{ BuffDuration = 11, Cooldown = 108, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 184364, RequiresTalent = 184364 },
			{ BuffDuration = 20, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 107574, MinDuration = true, RequiresTalent = 107574 },
		},
		[73] = {
			{ BuffDuration = 8, Cooldown = 180, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 871 },
			{ BuffDuration = 20, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 107574, MinDuration = true, RequiresTalent = 107574 },
		},
		[251] = { { BuffDuration = 12, Cooldown = 45, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 51271 } },
		[250] = {
			{ BuffDuration = 10, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 55233 },
			{ BuffDuration = 12, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 55233 },
			{ BuffDuration = 14, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 55233 },
			{ BuffDuration = 8, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", MinDuration = true, SpellId = 49028 },
		},
		[256] = { { BuffDuration = 8, Cooldown = 180, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 33206 } },
		[257] = {
			{ BuffDuration = 10, Cooldown = 180, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 47788 },
			{ BuffDuration = 5, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 64843 },
		},
		[258] = {
			{ BuffDuration = 6, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 47585 },
			{ BuffDuration = 20, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 228260 },
		},
		[102] = { { BuffDuration = 20, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 102560 } },
		[103] = {
			{ BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 106951, RequiresTalent = 106951, ExcludeIfTalent = 102543 },
			{ BuffDuration = 20, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 102543, RequiresTalent = 102543 },
		},
		[104] = { { BuffDuration = 30, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 102558 } },
		[105] = { { BuffDuration = 12, Cooldown = 90, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 102342 } },
		[268] = {
			{ BuffDuration = 25, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 132578 },
			{ BuffDuration = 15, Cooldown = 360, BigDefensive = true, Important = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 115203 },
		},
		[270] = { { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 116849 } },
		[577] = { { BuffDuration = 10, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 198589 } },
		[1480] = { { BuffDuration = 10, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 198589 } },
		[581] = {
			{ BuffDuration = 12, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = false, MinDuration = true, RequiresEvidence = "Cast", SpellId = 204021 },
			{ BuffDuration = 15, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 187827 },
			{ BuffDuration = 20, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 187827 },
		},
		[254] = {
			{ BuffDuration = 15, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 288613 },
			{ BuffDuration = 17, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 288613 },
		},
		[255] = {
			{ BuffDuration = 8, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 1250646 },
			{ BuffDuration = 10, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 1250646 },
		},
		[261] = {
			{ BuffDuration = 16, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 121471 },
			{ BuffDuration = 18, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 121471 },
			{ BuffDuration = 20, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 121471 },
		},
		[1467] = { { BuffDuration = 18, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 375087 } },
		[1468] = { { BuffDuration = 8, Cooldown = 60, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 357170 } },
		[1473] = { { BuffDuration = 13.4, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", MinDuration = true, SpellId = 363916 } },
		[264] = { { BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114052, RequiresTalent = 114052 } },
		[262] = {
			{ BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114050, RequiresTalent = 114050 },
			{ BuffDuration = 18, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114050, RequiresTalent = 114050 },
		},
		[263] = {
			{ BuffDuration = 8, Cooldown = 60, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 384352, RequiresTalent = 384352, ExcludeIfTalent = { 114051, 378270 } },
			{ BuffDuration = 10, Cooldown = 60, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 384352, RequiresTalent = 384352, ExcludeIfTalent = { 114051, 378270 } },
			{ BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114051, RequiresTalent = 114051 },
		},
	},
	byClass = {
		PALADIN = {
			{ BuffDuration = 8, Cooldown = 300, BigDefensive = true, Important = true, ExternalDefensive = false, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 },
			{ BuffDuration = 8, Cooldown = 25, Important = true, ExternalDefensive = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1044 },
			{ BuffDuration = 10, Cooldown = 45, ExternalDefensive = true, Important = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692 },
			{ BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, Important = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022, ExcludeIfTalent = 5692 },
		},
		WARRIOR = {},
		MAGE = {
			{ BuffDuration = 10, Cooldown = 240, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, SpellId = 45438, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, ExcludeIfTalent = 414659 },
			{ BuffDuration = 6, Cooldown = 240, BigDefensive = true, ExternalDefensive = false, Important = true, SpellId = 414659, RequiresEvidence = "Cast", RequiresTalent = 414659 },
			{ BuffDuration = 10, Cooldown = 50, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, SpellId = 342246, RequiresEvidence = "Cast" },
		},
		HUNTER = {
			{ BuffDuration = 8, Cooldown = 180, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, SpellId = 186265, RequiresEvidence = { "Cast", "UnitFlags" } },
			{ BuffDuration = 6, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, MinDuration = true, SpellId = 264735, RequiresEvidence = "Cast" },
			{ BuffDuration = 8, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, MinDuration = true, SpellId = 264735, RequiresEvidence = "Cast" },
		},
		DRUID = {
			{ BuffDuration = 8, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 22812 },
			{ BuffDuration = 12, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 22812 },
		},
		ROGUE = {
			{ BuffDuration = 10, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 5277 },
			{ BuffDuration = 5, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 31224 },
		},
		DEATHKNIGHT = {
			{ BuffDuration = 5, Cooldown = 60, BigDefensive = true, Important = true, ExternalDefensive = false, CanCancelEarly = true, SpellId = 48707, RequiresEvidence = { "Cast", "Shield" } },
			{ BuffDuration = 7, Cooldown = 60, BigDefensive = true, Important = true, ExternalDefensive = false, CanCancelEarly = true, SpellId = 48707, RequiresEvidence = { "Cast", "Shield" } },
			{ BuffDuration = 8, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 48792 },
			{ BuffDuration = 5, Cooldown = 60, BigDefensive = false, Important = true, ExternalDefensive = false, CanCancelEarly = true, SpellId = 48707, RequiresEvidence = { "Cast", "Shield" } },
			{ BuffDuration = 7, Cooldown = 60, BigDefensive = false, Important = true, ExternalDefensive = false, CanCancelEarly = true, SpellId = 48707, RequiresEvidence = { "Cast", "Shield" } },
			{ BuffDuration = 8, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", MinDuration = true, SpellId = 49028 },
		},
		DEMONHUNTER = {},
		MONK = { { BuffDuration = 15, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 115203 } },
		SHAMAN = { { BuffDuration = 12, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 108271 } },
		WARLOCK = {
			{ BuffDuration = 8, Cooldown = 180, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 104773 },
			{ BuffDuration = 3, Cooldown = 45, Important = true, BigDefensive = false, ExternalDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 212295, RequiresTalent = 3624 },
		},
		PRIEST = {
			{ BuffDuration = 10, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 19236 },
		},
		EVOKER = {
			{ BuffDuration = 12, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", MinDuration = true, SpellId = 363916 },
		},
	},
}

local offensiveSpellIds = {
	[375087] = true, [107574] = true, [121471] = true, [31884]  = true, [216331] = true, [190319] = true,
	[288613] = true, [228260] = true, [102560] = true, [102543] = true, [106951] = true, [102558] = true, [1250646] = true,
	[384352] = true, [114051] = true, [114050] = true,
}

---@class CooldownTrackerModule
local M = {}
addon.Modules.CooldownTracker = M

function M.GetRulesDatabase()
	return rules, offensiveSpellIds
end

local watchEntries = {}
local eventsFrame
local db
local testModeActive = false
local dummyStartTime = 0

local hiddenPlayerAnchor = CreateFrame("Frame")
hiddenPlayerAnchor:Hide()
hiddenPlayerAnchor:SetAttribute("unit", "player")

local function GetSpecId(unit)
	local fs = FrameSortApi and FrameSortApi.v3
	if fs and fs.Inspector then
		return fs.Inspector:GetUnitSpecId(unit)
	end
	return inspector:GetUnitSpecId(unit)
end

local function GetStaticAbilities(unit)
	local _, classToken = UnitClass(unit)
	if not classToken then return {} end

	local specId = GetSpecId(unit) or fcdTalents:GetUnitSpecId(unit)
	local seen = {}
	local result = {}

	local customSpells = {}
	if db and db.CustomSpells and type(db.CustomSpells) == "table" then
		for id in pairs(db.CustomSpells) do
			customSpells[id] = true
		end
	end

	local function addRules(ruleList)
		if not ruleList then return end
		for _, rule in ipairs(ruleList) do
			if rule.SpellId and not seen[rule.SpellId] then
				-- Check if the user has explicitly disabled this spell in the settings panel
				local isDisabled = db and db.DisabledSpells and db.DisabledSpells[rule.SpellId]
				if not isDisabled then
					local excluded = rule.ExcludeIfTalent and fcdTalents:UnitHasTalent(unit, rule.ExcludeIfTalent, specId)
					local required = rule.RequiresTalent and not fcdTalents:UnitHasTalent(unit, rule.RequiresTalent, specId)
					if not excluded and not required then
						seen[rule.SpellId] = true
						local isOffensive = offensiveSpellIds[rule.SpellId] == true or customSpells[rule.SpellId] == true
						result[#result + 1] = { SpellId = rule.SpellId, IsOffensive = isOffensive }
					end
				end
			end
		end
	end

	addRules(specId and rules.bySpec[specId])
	addRules(rules.byClass[classToken])

	for customId in pairs(customSpells) do
		if not seen[customId] then
			seen[customId] = true
			result[#result + 1] = { SpellId = customId, IsOffensive = true }
		end
	end

	return result
end

local function AuraTypeMatchesRule(auraTypes, rule)
	if rule.BigDefensive == true and not auraTypes["BIG_DEFENSIVE"] then return false end
	if rule.BigDefensive == false and auraTypes["BIG_DEFENSIVE"] then return false end
	if rule.ExternalDefensive == true and not auraTypes["EXTERNAL_DEFENSIVE"] then return false end
	if rule.ExternalDefensive == false and auraTypes["EXTERNAL_DEFENSIVE"] then return false end
	if rule.Important == true and not auraTypes["IMPORTANT"] then return false end
	return true
end

local function EvidenceMatchesReq(req, evidence)
	if req == nil then return true end
	if req == false then return not evidence or not next(evidence) end
	if type(req) == "string" then return evidence ~= nil and evidence[req] == true end
	if type(req) == "table" then
		if not evidence then return false end
		for _, k in ipairs(req) do if not evidence[k] then return false end end
		return true
	end
	return false
end

local function MatchRule(unit, auraTypes, measuredDuration, context, auraSpellId, castSpellId)
	local _, classToken = UnitClass(unit)
	if not classToken then return nil end

	local specId = GetSpecId(unit)
	local evidence = context and context.Evidence
	local activeCooldowns = context and context.ActiveCooldowns

	local function isSameSpellSecure(id1, id2)
		if not id1 or not id2 then return false end
		local ok, res = pcall(function() return id1 == id2 end)
		return ok and res
	end

	local function tryRuleList(ruleList)
		if not ruleList then return nil end
		
		-- Pass 1: Strict Exact ID Matching
		-- If we have an explicit securely-readable auraSpellId or castSpellId, look for a perfect match first.
		-- This MUST be a separate pass so that a fuzzy heuristic from an earlier rule doesn't hijack the result.
		for _, rule in ipairs(ruleList) do
			local excluded = rule.ExcludeIfTalent and fcdTalents:UnitHasTalent(unit, rule.ExcludeIfTalent, specId)
			local required = rule.RequiresTalent and not fcdTalents:UnitHasTalent(unit, rule.RequiresTalent, specId)
			if not excluded and not required then
				if isSameSpellSecure(auraSpellId, rule.SpellId) or isSameSpellSecure(castSpellId, rule.SpellId) then
					return rule
				end
			end
		end

		-- Pass 2: Fuzzy Heuristic Guessing (Fallback)
		-- Used primarily when Blizzard completely masks both aura and cast data (e.g., hidden auras/passive procs).
		local fallback = nil
		for _, rule in ipairs(ruleList) do
			local excluded = rule.ExcludeIfTalent and fcdTalents:UnitHasTalent(unit, rule.ExcludeIfTalent, specId)
			local required = rule.RequiresTalent and not fcdTalents:UnitHasTalent(unit, rule.RequiresTalent, specId)
			if not excluded and not required then
				local expectedDuration = rule.SpellId and fcdTalents:GetUnitBuffDuration(unit, specId, classToken, rule.SpellId, rule.BuffDuration) or rule.BuffDuration
				local typeMatch = AuraTypeMatchesRule(auraTypes, rule)
				if typeMatch then
					local req = rule.RequiresEvidence
					local evidenceOk = EvidenceMatchesReq(req, evidence)
					if evidenceOk then
						local durationOk
						if rule.MinDuration then durationOk = measuredDuration >= expectedDuration - tolerance
						elseif rule.CanCancelEarly == true then durationOk = measuredDuration <= expectedDuration + tolerance
						else durationOk = math.abs(measuredDuration - expectedDuration) <= tolerance end
						if durationOk then
							local alreadyOnCd = activeCooldowns and rule.SpellId and activeCooldowns[rule.SpellId]
							if not alreadyOnCd then return rule
							elseif not fallback then fallback = rule end
						end
					end
				end
			end
		end
		return fallback
	end

	return tryRuleList(specId and rules.bySpec[specId]) or tryRuleList(rules.byClass[classToken])
end

local function GetEntryForUnit(unit)
	local fallback = nil
	for _, entry in pairs(watchEntries) do
		if UnitIsUnit(entry.Unit, unit) then
			if entry.Anchor:IsShown() then return entry end
			fallback = entry
		end
	end
	return fallback
end

local function FindBestCandidate(entry, tracked, measuredDuration, auraSpellId)
	local rule = nil
	local ruleUnit = entry.Unit
	local bestTime = nil
	local isExternal = tracked.AuraTypes["EXTERNAL_DEFENSIVE"]

	local function consider(candidate, isTarget)
		local candidateEvidence = nil
		if tracked.Evidence then
			for k in pairs(tracked.Evidence) do
				if k ~= "Cast" then candidateEvidence = candidateEvidence or {}; candidateEvidence[k] = true end
			end
		end
		local castData = tracked.CastSnapshot[candidate]
		local castTime = castData and (type(castData) == "table" and castData.Time or castData) or nil
		local castSpellId = castData and (type(castData) == "table" and castData.SpellId or nil) or nil

		if castTime and math.abs(castTime - tracked.StartTime) <= castWindow then
			candidateEvidence = candidateEvidence or {}
			candidateEvidence.Cast = true
		end
		local candidateRule = MatchRule(candidate, tracked.AuraTypes, measuredDuration, { Evidence = candidateEvidence, ActiveCooldowns = entry.ActiveCooldowns }, auraSpellId, castSpellId)
		if not candidateRule then return end
		local isBetter = not rule or (castTime and (not bestTime or castTime > bestTime)) or (not castTime and not bestTime and isExternal and not isTarget)
		if isBetter then
			rule, ruleUnit, bestTime = candidateRule, candidate, castTime
		end
	end

	consider(entry.Unit, true)
	for _, e in pairs(watchEntries) do
		if e.Unit ~= entry.Unit then consider(e.Unit, false) end
	end
	return rule, ruleUnit
end

local function UpdateDisplayNow(entry)
	local container = entry.Container
	container:ResetAllSlots()

	db = addon.Core.Framework:GetSavedVars()
	local options = db
	local iconOptions = options.Icons or {}
	local showTooltips = options.ShowTooltips ~= false
	local iconsReverse = iconOptions.ReverseCooldown
	local iconsGlow = iconOptions.Glow
	local maxIcons = iconOptions.MaxIcons or 3

	local showOffensive = options.ShowOffensiveCooldowns ~= false
	local showDefensive = options.ShowDefensiveCooldowns ~= false

	if not options or (not addon.Utils.ModuleUtil.IsModuleEnabled() and not testModeActive) then
		container.Frame:Hide()
		return
	end

	-- Apply exclusion
	if options.ExcludePlayer and UnitIsUnit(entry.Unit, "player") then
		container.Frame:Hide()
		return
	end

	local now = GetTime()
	local slots = {}
	local spellHandled = {}

	if testModeActive then
		local testSpells = {
			{ SpellId = 642, Texture = 135964 }, -- Divine Shield
			{ SpellId = 33206, Texture = 135936 }, -- Pain Suppression
			{ SpellId = 22812, Texture = 136041 }, -- Barkskin
			{ SpellId = 31850, Texture = 135862 }, -- Ardent Defender
		}

		for i = 1, math.min(3, maxIcons) do
			local testSpell = testSpells[i] or testSpells[1]
			local tex = spellCache:GetSpellTexture(testSpell.SpellId) or testSpell.Texture
			local isGlow = (i == 1)
			local durationObj

			if isGlow then
				durationObj = wowEx:CreateDuration(dummyStartTime, 8)
			else
				durationObj = wowEx:CreateDuration(dummyStartTime - (i * 20), 120)
			end

			table.insert(slots, {
				Texture = tex,
				DurationObject = durationObj,
				Alpha = 1,
				ReverseCooldown = iconsReverse,
				Glow = isGlow and iconsGlow or false,
				FontScale = options.FontScale,
			})
		end
		for i, slotData in ipairs(slots) do
			if i > maxIcons then break end
			container:SetSlot(i, slotData)
		end
		container:SetCount(math.min(#slots, maxIcons))
		frames:ShowHideFrame(container.Frame, entry.Anchor, testModeActive, false)
		return
	end

	local usedAbilityIds = {}

	-- 1. Identify all active auras owned by this entry (either self-cast or outbound to group members)
	local activeOwnedAuras = {}
	if showDefensive then
		for _, targetEntry in pairs(watchEntries) do
			for _, aura in ipairs(targetEntry.Watcher:GetDefensiveState()) do
				local tracked = targetEntry.TrackedAuras[aura.AuraInstanceID]
				if tracked then
					local expectedDur = aura.DurationObject and aura.DurationObject.duration or 0
					local rule, ruleUnit = FindBestCandidate(targetEntry, tracked, expectedDur, aura.SpellId)
					
					local isOwner = false
					if ruleUnit then
						isOwner = UnitIsUnit(ruleUnit, entry.Unit)
					else
						-- Fallback if we can't guarantee a caster. Assume self-cast UNLESS explicitly external.
						if UnitIsUnit(targetEntry.Unit, entry.Unit) and not tracked.AuraTypes["EXTERNAL_DEFENSIVE"] then
							isOwner = true
						end
					end

					if isOwner and rule and rule.SpellId then
						activeOwnedAuras[rule.SpellId] = aura
					end
				end
			end
		end
	end

	-- Inject synthetic auras for active custom spells that have a duration
	if options.CustomSpells then
		for customId, cdata in pairs(options.CustomSpells) do
			if type(cdata) == "table" then
				local activeCd = entry.ActiveCooldowns[customId]
				if activeCd and activeCd.StartTime then
					local dur = tonumber(cdata.duration) or 0
					if dur > 0 and now < activeCd.StartTime + dur then
						activeOwnedAuras[customId] = {
							DurationObject = wowEx:CreateDuration(activeCd.StartTime, dur)
						}
					end
				end
			end
		end
	end

	-- 2. Build layout via strict slot assignment based on Database rules (O(1) Positioning)
	-- This rigidly locks static abilities in sequence so they never randomly shift.
	local staticAbilities = GetStaticAbilities(entry.Unit)

	for _, ability in ipairs(staticAbilities) do
		if #slots >= maxIcons then break end

		if (not ability.IsOffensive or showOffensive) and (ability.IsOffensive or showDefensive) then
			local texture = spellCache:GetSpellTexture(ability.SpellId)
			if texture then
				local slotData = {
					SpellId = options.ShowTooltips ~= false and ability.SpellId or nil,
					Texture = texture,
					Alpha = 1,
					FontScale = options.FontScale,
					ReverseCooldown = iconsReverse,
					Glow = false,
					DurationObject = nil
				}

				local activeAura = activeOwnedAuras[ability.SpellId]
				local activeCd = entry.ActiveCooldowns[ability.SpellId]

				if activeAura then
					slotData.DurationObject = activeAura.DurationObject
					slotData.Glow = iconsGlow
				elseif activeCd and type(activeCd) == "table" and now < activeCd.StartTime + activeCd.Cooldown then
					slotData.DurationObject = wowEx:CreateDuration(activeCd.StartTime, activeCd.Cooldown)
				elseif activeCd then
					entry.ActiveCooldowns[ability.SpellId] = nil
				end

				table.insert(slots, slotData)
				usedAbilityIds[ability.SpellId] = true
			end
		end
	end

	-- 3. Append remaining dynamic Active Cooldowns if they aren't physically in the static layout
	for cdKey, cd in pairs(entry.ActiveCooldowns) do
		if #slots >= maxIcons then break end
		if type(cdKey) == "string" or type(cdKey) == "number" then
			if cd.SpellId and not usedAbilityIds[cd.SpellId] then
				if now < cd.StartTime + cd.Cooldown then
					if (not cd.IsOffensive or showOffensive) and (cd.IsOffensive or showDefensive) then
						local tex = spellCache:GetSpellTexture(cd.SpellId)
						if tex then
							slots[#slots + 1] = {
								Texture = tex,
								SpellId = options.ShowTooltips ~= false and cd.SpellId or nil,
								DurationObject = wowEx:CreateDuration(cd.StartTime, cd.Cooldown),
								Alpha = 1,
								ReverseCooldown = iconsReverse,
								Glow = false,
								FontScale = options.FontScale,
							}
						end
					end
				else
					entry.ActiveCooldowns[cdKey] = nil
				end
			end
		end
	end

	for i, slotData in ipairs(slots) do
		container:SetSlot(i, slotData)
	end
	
	container:SetCount(#slots)
	frames:ShowHideFrame(container.Frame, entry.Anchor, testModeActive, false)
end

local pendingUpdates = {}
local isUpdateQueued = false

local function DoQueuedUpdate()
	isUpdateQueued = false
	local toUpdate = pendingUpdates
	pendingUpdates = {}
	for entry in pairs(toUpdate) do
		UpdateDisplayNow(entry)
	end
end

local function UpdateDisplay(entry)
	if not entry then return end
	pendingUpdates[entry] = true
	if not isUpdateQueued then
		isUpdateQueued = true
		C_Timer.After(0, DoQueuedUpdate)
	end
end

local function CommitCooldown(entry, tracked, rule, ruleUnit, measuredDuration)
	local targetEntry = ruleUnit ~= entry.Unit and (GetEntryForUnit(ruleUnit) or entry) or entry

	local cooldown = rule.Cooldown
	if rule.SpellId then
		local specId = GetSpecId(ruleUnit)
		local _, classToken = UnitClass(ruleUnit)
		if classToken then cooldown = fcdTalents:GetUnitCooldown(ruleUnit, specId, classToken, rule.SpellId, cooldown, measuredDuration) end
	end

	local MultiChargeSpells = {
		[264735] = true, -- Survival of the Fittest
		[6940] = true,   -- Blessing of Sacrifice
		[31850] = true,  -- Ardent Defender
		[61336] = true,  -- Survival Instincts
		[186265] = true, -- Aspect of the Turtle (sometimes 2 charges with talents)
		[498] = true,    -- Divine Protection
		[22812] = true,  -- Barkskin
		[47585] = true,  -- Dispersion
		[1250646] = true,-- Fortifying Brew (some monks)
	}

	local auraTypesKey = tracked.AuraTypes["BIG_DEFENSIVE"] and "BIG_DEFENSIVE" or tracked.AuraTypes["EXTERNAL_DEFENSIVE"] and "EXTERNAL_DEFENSIVE" or "IMPORTANT"
	local cdKey = rule.SpellId or (auraTypesKey .. "_" .. rule.BuffDuration .. "_" .. rule.Cooldown)
	local cdData = { StartTime = tracked.StartTime, Cooldown = cooldown, SpellId = tracked.SpellId, IsOffensive = rule.SpellId ~= nil and offensiveSpellIds[rule.SpellId] == true, EndTime = tracked.StartTime + cooldown }

	local casterEntries = {}
	local cdCommitted = false
	local isChargeSpell = rule.SpellId and MultiChargeSpells[rule.SpellId]

	for _, e in pairs(watchEntries) do
		if UnitIsUnit(e.Unit, ruleUnit) then
			local existing = e.ActiveCooldowns[cdKey]
			if isChargeSpell and existing and existing.EndTime and (existing.EndTime < cdData.EndTime) then
				-- Keep tracking the earliest charge recovery so it correctly shows when it's next available
				casterEntries[#casterEntries + 1] = e
			else
				if existing and existing.Timer then existing.Timer:Cancel(); existing.Timer = nil end
				e.ActiveCooldowns[cdKey] = cdData
				casterEntries[#casterEntries + 1] = e
				cdCommitted = true
			end
		end
	end
	if #casterEntries == 0 then
		local existing = targetEntry.ActiveCooldowns[cdKey]
		if isChargeSpell and existing and existing.EndTime and (existing.EndTime < cdData.EndTime) then
			casterEntries[1] = targetEntry
		else
			if existing and existing.Timer then existing.Timer:Cancel(); existing.Timer = nil end
			targetEntry.ActiveCooldowns[cdKey] = cdData
			casterEntries[1] = targetEntry
			cdCommitted = true
		end
	end

	for _, e in ipairs(casterEntries) do
		if e ~= entry then UpdateDisplay(e); frames:ShowHideFrame(e.Container.Frame, e.Anchor) end
	end

	if cdCommitted then
		local remaining = cooldown - measuredDuration
		if remaining <= 0 then
			for _, e in ipairs(casterEntries) do e.ActiveCooldowns[cdKey] = nil end
			return
		end
		cdData.Timer = C_Timer.NewTimer(remaining, function()
			cdData.Timer = nil
			for _, e in ipairs(casterEntries) do e.ActiveCooldowns[cdKey] = nil; UpdateDisplay(e) end
		end)
	end
end

local function OnAuraRemoved(entry, tracked, now)
	local measuredDuration = now - tracked.StartTime
	local rule, ruleUnit = FindBestCandidate(entry, tracked, measuredDuration)
	if not rule then return end
	CommitCooldown(entry, tracked, rule, ruleUnit, measuredDuration)
end

local function BuildCurrentAuraIds(unit, watcher)
	local currentIds = {}
	for _, aura in ipairs(watcher:GetDefensiveState()) do
		local id = aura.AuraInstanceID
		if id then
			local isExt = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|EXTERNAL_DEFENSIVE")
			local isImportant = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|IMPORTANT")
			local auraType = isExt and "EXTERNAL_DEFENSIVE" or "BIG_DEFENSIVE"
			local auraTypes = { [auraType] = true }
			if isImportant then auraTypes["IMPORTANT"] = true end
			currentIds[id] = { AuraTypes = auraTypes }
		end
	end
	for _, aura in ipairs(watcher:GetImportantState()) do
		local id = aura.AuraInstanceID
		if id then
			if currentIds[id] then currentIds[id].AuraTypes["IMPORTANT"] = true
			else currentIds[id] = { AuraTypes = { IMPORTANT = true } } end
		end
	end
	return currentIds
end

local function TrackNewAura(unit, trackedAuras, id, info, now)
	local evidence = BuildEvidenceSet(unit, now)
	local castSnapshot = {}
	for snapshotUnit, data in pairs(lastCastTime) do 
		if type(data) == "table" then castSnapshot[snapshotUnit] = { Time = data.Time, SpellId = data.SpellId }
		else castSnapshot[snapshotUnit] = { Time = data } end
	end

	trackedAuras[id] = { StartTime = now, AuraTypes = info.AuraTypes, Evidence = evidence, CastSnapshot = castSnapshot }

	C_Timer.After(evidenceTolerance, function()
		local tracked = trackedAuras[id]
		if not tracked then return end
		local ev = BuildEvidenceSet(unit, now)
		if ev then
			tracked.Evidence = tracked.Evidence or {}
			for k in pairs(ev) do tracked.Evidence[k] = true end
		end
		for snapshotUnit, data in pairs(lastCastTime) do
			local timeVal = type(data) == "table" and data.Time or data
			if math.abs(timeVal - now) <= castWindow and not tracked.CastSnapshot[snapshotUnit] then
				tracked.CastSnapshot[snapshotUnit] = type(data) == "table" and { Time = data.Time, SpellId = data.SpellId } or { Time = data }
			end
		end
	end)
end

local function OnWatcherChanged(entry, w)
	local watcher = entry.Watcher
	local now = GetTime()
	
	local trackedAuras = entry.TrackedAuras
	local currentIds = BuildCurrentAuraIds(entry.Unit, watcher)

	local unmatchedNewIds = {}
	for id in pairs(currentIds) do
		if not trackedAuras[id] then unmatchedNewIds[#unmatchedNewIds + 1] = id end
	end

	local function auraTypesSignature(auraTypes)
		local s = ""
		if auraTypes["BIG_DEFENSIVE"] then s = s .. "B" end
		if auraTypes["EXTERNAL_DEFENSIVE"] then s = s .. "E" end
		if auraTypes["IMPORTANT"] then s = s .. "I" end
		return s
	end

	local newIdsBySignature = {}
	for _, id in ipairs(unmatchedNewIds) do
		local sig = auraTypesSignature(currentIds[id].AuraTypes)
		newIdsBySignature[sig] = newIdsBySignature[sig] or {}
		newIdsBySignature[sig][#newIdsBySignature[sig] + 1] = id
	end

	for id, tracked in pairs(trackedAuras) do
		if not currentIds[id] then
			local sig = auraTypesSignature(tracked.AuraTypes)
			local candidates = newIdsBySignature[sig]
			if candidates and #candidates > 0 then
				local reassignedId = table.remove(candidates, 1)
				trackedAuras[reassignedId] = tracked
			else
				OnAuraRemoved(entry, tracked, now)
			end
			trackedAuras[id] = nil
		end
	end

	for id, info in pairs(currentIds) do
		if not trackedAuras[id] then TrackNewAura(entry.Unit, trackedAuras, id, info, now) end
	end
	
	for _, e in pairs(watchEntries) do UpdateDisplay(e) end
end

local function AnchorContainer(entry)
	local options = db
	if not options then return end

	local frame = entry.Container.Frame
	local anchor = entry.Anchor

	frame:ClearAllPoints()
	frame:SetAlpha(1)
	frame:SetFrameStrata(anchor:GetFrameStrata())
	frame:SetFrameLevel(anchor:GetFrameLevel() + 1)

	local x = options.AnchorOffset and options.AnchorOffset.X or 0
	local y = options.AnchorOffset and options.AnchorOffset.Y or 0

	if options.GrowDirection == "LEFT" then
		frame:SetPoint("RIGHT", anchor, "LEFT", x, y)
	elseif options.GrowDirection == "RIGHT" then
		frame:SetPoint("LEFT", anchor, "RIGHT", x, y)
	else
		frame:SetPoint("CENTER", anchor, "CENTER", x, y)
	end
end

local function EnsureEntry(anchor, unit)
	unit = unit or anchor.unit or anchor:GetAttribute("unit")
	if not unit or units:IsPet(unit) or units:IsCompoundUnit(unit) then return nil end

	db = addon.Core.Framework:GetSavedVars()
	local options = db
	if not options or (not addon.Utils.ModuleUtil.IsModuleEnabled() and not testModeActive) then return nil end

	-- We no longer abort EnsureEntry here for ExcludePlayer, 
	-- because we must keep the Watcher running on the player to track 
	-- External Defensives cast ON the player by OTHER party members!
	-- UpdateDisplay will handle visually hiding the container.

	local entry = watchEntries[anchor]

	if not entry then
		local size = options.Icons and tonumber(options.Icons.Size) or 32
		local maxIcons = options.Icons and tonumber(options.Icons.MaxIcons) or 3
		local container = iconSlotContainer:New(UIParent, maxIcons, size, db.IconSpacing or 2, "Cooldown Tracker", true)

		entry = {
			Anchor = anchor,
			Unit = unit,
			Container = container,
			TrackedAuras = {},
			ActiveCooldowns = {},
		}
		watchEntries[anchor] = entry

		local castEventFrame = CreateFrame("Frame")
		castEventFrame:SetScript("OnEvent", function(_, event, ...)
			local u = entry.Unit
			if UnitCanAttack("player", u) then return end
			if event == "UNIT_SPELLCAST_SUCCEEDED" then
				local uTarget, castGUID, spellID = ...
				local now = GetTime()
				lastCastTime[u] = { Time = now, SpellId = spellID }
				
				local currentDb = addon.Core.Framework:GetSavedVars()
				if currentDb and currentDb.CustomSpells then
					local matchedId = nil
					local matchedData = nil
					for cId, data in pairs(currentDb.CustomSpells) do
						local ok, res = pcall(function() return cId == spellID end)
						if ok and res then
							matchedId = cId
							matchedData = data
							break
						end
					end
					
					if matchedId and type(matchedData) == "table" then
						local cd = tonumber(matchedData.cooldown) or 0
						if cd == 0 and C_Spell and C_Spell.GetSpellBaseCooldown then
							local baseCd = C_Spell.GetSpellBaseCooldown(matchedId)
							if baseCd and baseCd > 0 then cd = baseCd / 1000 end
						end
						
						local cdData = { StartTime = now, Cooldown = cd, SpellId = matchedId, IsOffensive = true }
						entry.ActiveCooldowns[matchedId] = cdData
						UpdateDisplay(entry)
					end
				end
			elseif event == "UNIT_FLAGS" then
				local now = GetTime()
				local isFeign = UnitIsFeignDeath(u)
				if isFeign and not lastFeignDeathState[u] then lastFeignDeathTime[u] = now end
				lastFeignDeathState[u] = isFeign
				if not isFeign then lastUnitFlagsTime[u] = now end
			elseif event == "UNIT_AURA" then
				local _, updateInfo = ...
				if updateInfo and not updateInfo.isFullUpdate and updateInfo.addedAuras then
					for _, aura in ipairs(updateInfo.addedAuras) do
						if aura.auraInstanceID and not C_UnitAuras.IsAuraFilteredOutByInstanceID(u, aura.auraInstanceID, "HARMFUL") then
							lastDebuffTime[u] = GetTime()
							break
						end
					end
				end
			end
		end)
		castEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
		castEventFrame:RegisterUnitEvent("UNIT_FLAGS", unit)
		castEventFrame:RegisterUnitEvent("UNIT_AURA", unit)
		entry.CastEventFrame = castEventFrame

		local watcher = unitAuraWatcher:New(unit, nil, { Defensives = true, Important = true, CC = true })
		watcher:RegisterCallback(function(w) OnWatcherChanged(entry, w) end)
		entry.Watcher = watcher
		OnWatcherChanged(entry, watcher)
		
	elseif entry.Unit ~= unit then
		entry.Unit = unit
		entry.TrackedAuras = {}
		entry.ActiveCooldowns = {}
		entry.Container:ResetAllSlots()

		entry.CastEventFrame:UnregisterAllEvents()
		entry.CastEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
		entry.CastEventFrame:RegisterUnitEvent("UNIT_FLAGS", unit)
		entry.CastEventFrame:RegisterUnitEvent("UNIT_AURA", unit)

		entry.Watcher:Dispose()
		local watcher = unitAuraWatcher:New(unit, nil, { Defensives = true, Important = true, CC = true })
		watcher:RegisterCallback(function(w) OnWatcherChanged(entry, w) end)
		entry.Watcher = watcher
		OnWatcherChanged(entry, watcher)
	end

	AnchorContainer(entry)
	frames:ShowHideFrame(entry.Container.Frame, anchor, false, options.ExcludePlayer)

	return entry
end

local function EnsureAllEntries()
	local foundPlayer = false
	for _, anchor in ipairs(frames:GetAll(true, testModeActive)) do
		local unit = anchor.unit or anchor:GetAttribute("unit")
		if unit and UnitIsUnit(unit, "player") then foundPlayer = true end
		EnsureEntry(anchor)
	end
	
	if not foundPlayer then
		EnsureEntry(hiddenPlayerAnchor, "player")
	elseif watchEntries[hiddenPlayerAnchor] then
		local existing = watchEntries[hiddenPlayerAnchor]
		existing.Watcher:Dispose()
		existing.CastEventFrame:UnregisterAllEvents()
		existing.Container:ResetAllSlots()
		existing.Container.Frame:Hide()
		watchEntries[hiddenPlayerAnchor] = nil
	end
end

function M:Refresh()
	db = addon.Core.Framework:GetSavedVars()
	local options = db
	if not options then return end

	if not addon.Utils.ModuleUtil.IsModuleEnabled() and not testModeActive then
		for _, entry in pairs(watchEntries) do
			entry.Watcher:Disable()
			entry.CastEventFrame:UnregisterAllEvents()
			entry.Container:ResetAllSlots()
			entry.Container.Frame:Hide()
		end
		return
	end

	for _, entry in pairs(watchEntries) do
		entry.CastEventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", entry.Unit)
		entry.CastEventFrame:RegisterUnitEvent("UNIT_FLAGS", entry.Unit)
		entry.CastEventFrame:RegisterUnitEvent("UNIT_AURA", entry.Unit)
		entry.Watcher:Enable()
		entry.Watcher:ForceFullUpdate()
	end
	
	EnsureAllEntries()

	for anchor, entry in pairs(watchEntries) do
		if options.ExcludePlayer and UnitIsUnit(entry.Unit, "player") then
			entry.Container:ResetAllSlots()
			entry.Container.Frame:Hide()
			-- Watcher remains enabled so that auras ON the player can still
			-- be detected and attributed to their original caster in the party!
		else
			local size = options.Icons and tonumber(options.Icons.Size) or 32
			local maxIcons = options.Icons and tonumber(options.Icons.MaxIcons) or 3
			entry.Container:SetIconSize(size)
			entry.Container:SetCount(maxIcons)
			entry.Container:SetSpacing(db.IconSpacing or 2)
			AnchorContainer(entry)
			frames:ShowHideFrame(entry.Container.Frame, anchor, false, options.ExcludePlayer)
			UpdateDisplay(entry)
		end
	end
end

function M:RefreshDisplays()
	for _, entry in pairs(watchEntries) do UpdateDisplay(entry) end
end

function M:ToggleTestMode()
	testModeActive = not testModeActive
	if testModeActive then
		dummyStartTime = GetTime()
		addon.Core.Framework:Notify("Cooldown Tracker Test Mode: |cFF00FF00ON|r")
		local testContainer = frames:GetTestFrameContainer()
		if testContainer then testContainer:Show() end
		for _, frame in ipairs(frames:GetTestFrames()) do frame:Show() end
	else
		addon.Core.Framework:Notify("Cooldown Tracker Test Mode: |cFFFF0000OFF|r")
		local testContainer = frames:GetTestFrameContainer()
		if testContainer then testContainer:Hide() end
		for _, frame in ipairs(frames:GetTestFrames()) do frame:Hide() end

		for anchor, entry in pairs(watchEntries) do
			if anchor:GetName() and anchor:GetName():match("^CompactRaidFrame") and not UnitExists(entry.Unit) then
				entry.Watcher:Disable()
				entry.CastEventFrame:UnregisterAllEvents()
				entry.Container:ResetAllSlots()
				entry.Container.Frame:Hide()
				watchEntries[anchor] = nil
			end
		end
	end
	M:Refresh()
end

_G.GravityDebuggerTracker = function()
	local count = 0
	for k,v in pairs(watchEntries) do count = count + 1 end
	print("--- Gravity Tracker Debug ---")
	print("Entries total:", count)
	for anchor, entry in pairs(watchEntries) do
		local name = anchor:GetName() or "unnamed"
		print(" - ", name, "Unit:", entry.Unit, "IsVisible:", anchor:IsVisible(), "ContShown:", entry.Container.Frame:IsShown(), "Slots:", entry.Container.Count)
	end
	print("TestMode:", testModeActive, "ExcludePlayer:", db and db.ExcludePlayer)
end

function M:Init()
	fcdTalents:Init()
	frames:Init()
	
	eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", function(_, event)
		if event == "GROUP_ROSTER_UPDATE" then C_Timer.After(0, function() M:Refresh() end)
		elseif event == "PLAYER_SPECIALIZATION_CHANGED" then C_Timer.After(0, function() M:RefreshDisplays() end)
		elseif event == "UNIT_FACTION" then M:RefreshDisplays()
		elseif event == "PVP_MATCH_STATE_CHANGED" then
			if C_PvP.GetActiveMatchState() == Enum.PvPMatchState.StartUp then
				for _, entry in pairs(watchEntries) do
					entry.ActiveCooldowns = {}
					entry.TrackedAuras = {}
					UpdateDisplay(entry)
				end
			end
		end
	end)
	eventsFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	eventsFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
	eventsFrame:RegisterEvent("UNIT_FACTION")

	fcdTalents:RegisterTalentCallback(function(playerName)
		for _, entry in pairs(watchEntries) do
			local entryName = UnitNameUnmodified(entry.Unit)
			if entryName and not issecretvalue(entryName) then
				local shortName = entryName:match("^([^%-]+)") or entryName
				if shortName == playerName then UpdateDisplay(entry) end
			end
		end
	end)

	local absorbFrame = CreateFrame("Frame")
	absorbFrame:SetScript("OnEvent", function(_, _, unit) lastShieldTime[unit] = GetTime() end)
	absorbFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")

	if CompactUnitFrame_SetUnit then
		hooksecurefunc("CompactUnitFrame_SetUnit", function(frame, unit)
			if not frames:IsFriendlyCuf(frame) then return end
			db = addon.Core.Framework:GetSavedVars()
			if not addon.Utils.ModuleUtil.IsModuleEnabled() and not testModeActive then return end
			EnsureEntry(frame, unit)
		end)
	end
	if CompactUnitFrame_UpdateVisible then
		hooksecurefunc("CompactUnitFrame_UpdateVisible", function(frame)
			if not frames:IsFriendlyCuf(frame) then return end
			local entry = watchEntries[frame]
			if not entry then return end
			db = addon.Core.Framework:GetSavedVars()
			if not addon.Utils.ModuleUtil.IsModuleEnabled() and not testModeActive then
				entry.Container.Frame:Hide()
				return
			end
			frames:ShowHideFrame(entry.Container.Frame, frame, false, db.ExcludePlayer)
		end)
	end

	local fs = FrameSortApi and FrameSortApi.v3
	if not (fs and fs.Inspector) then inspector:Init() end
	if fs and fs.Sorting and fs.Sorting.RegisterPostSortCallback then
		fs.Sorting:RegisterPostSortCallback(function() M:Refresh() end)
	end

	C_Timer.After(1, function() EnsureAllEntries() end)
end
