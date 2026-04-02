local ADDON_NAME, ns = ...
local addon = ns.CooldownTracker
local mini = addon.Core.Framework

---@class FriendlyCooldownTalents
local M = {}
addon.Core.FriendlyCooldownTalents = M

-- playerName -> talentRanks (spellId -> rank purchased)
local unitTalentRanks = {}
-- playerName -> specId (captured when talent string was decoded)
local unitTalentSpecId = {}
-- playerName -> set of active PvP talent IDs ({ [talentId] = true })
local unitPvPTalentIds = {}

local db

local ClassCooldownModifiers = {
	DEATHKNIGHT = {
		[205727] = { { { SpellId = 48707, Amount = -20 } } },
		[457574] = { { { SpellId = 48707, Amount = 20 } } },
	},
	DEMONHUNTER = {},
	HUNTER = {
		[1258485] = { { { SpellId = 186265, Amount = -30 } } },
		[266921] = {
			{ { SpellId = 186265, Amount = -15 } },
			{ { SpellId = 186265, Amount = -30 } },
		},
	},
	MAGE = {
		[382424] = {
			{ { SpellId = 45438, Amount = -30 }, { SpellId = 414659, Amount = -30 } },
			{ { SpellId = 45438, Amount = -60 }, { SpellId = 414659, Amount = -60 } },
		},
		[1265517] = { { { SpellId = 45438, Amount = -30 }, { SpellId = 414659, Amount = -30 } } },
		[1255166] = { { { SpellId = 342246, Amount = -10 } } },
	},
	PALADIN = {
		[384909] = { { { SpellId = 1022, Amount = -60 }, { SpellId = 204018, Amount = -60 } } },
		[114154] = {
			{
				{ SpellId = 642, Amount = -30, Mult = true },
				{ SpellId = 498, Amount = -30, Mult = true },
				{ SpellId = 31850, Amount = -30, Mult = true },
				{ SpellId = 403876, Amount = -30, Mult = true },
			},
		},
	},
	MONK = {},
	SHAMAN = { [381647] = { { { SpellId = 108271, Amount = -30 } } } },
	WARLOCK = { [386659] = { { { SpellId = 104773, Amount = -45 } } } },
	WARRIOR = {
		[391271] = {
			{
				{ SpellId = 118038, Amount = -10, Mult = true },
			},
		},
	},
}

local SpecCooldownModifiers = {
	[581] = { [389732] = { { { SpellId = 204021, Amount = -12 } } } },
	[102] = {
		[468743] = { { { SpellId = 102560, Amount = -60 } } },
		[390378] = { { { SpellId = 102560, Amount = -60 } } },
	},
	[103] = {
		[391174] = { { { SpellId = 102543, Amount = -60 }, { SpellId = 106951, Amount = -60 } } },
		[391548] = { { { SpellId = 102543, Amount = -30 }, { SpellId = 106951, Amount = -30 } } },
	},
	[105] = { [382552] = { { { SpellId = 102342, Amount = -20 } } } },
	[1468] = { [376204] = { { { SpellId = 357170, Amount = -10 } } } },
	[1473] = { [412713] = { { { SpellId = 363916, Amount = -10, Mult = true } } } },
	[254] = { [260404] = { { { SpellId = 288613, Amount = -30 } } } },
	[255] = { [1251790] = {
		{ { SpellId = 1250646, Amount = -15 } },
		{ { SpellId = 1250646, Amount = -30 } },
	} },
	[63] = { [1254194] = { { { SpellId = 190319, Amount = -60 } } } },
	[268] = {
		[450989] = { { { SpellId = 132578, Amount = -25 } } },
		[388813] = { { { SpellId = 115203, Amount = -120 } } },
	},
	[269] = { [388813] = { { { SpellId = 115203, Amount = -30 } } } },
	[270] = {
		[202424] = { { { SpellId = 116849, Amount = -45 } } },
		[388813] = { { { SpellId = 115203, Amount = -30 } } },
	},
	[257] = {
		[419110] = { { { SpellId = 64843, Amount = -60 } } },
		[200209] = { { { SpellId = 47788, Amount = 60, PostBuff = true } } },
	},
	[65] = {
		[384820] = { { { SpellId = 6940, Amount = -15 } } },
		[1241511] = {
			{ { SpellId = 31884, Amount = -15 }, { SpellId = 216331, Amount = -7.5 } },
			{ { SpellId = 31884, Amount = -30 }, { SpellId = 216331, Amount = -15 } },
		},
	},
	[66] = {
		[384820] = { { { SpellId = 6940, Amount = -60 } } },
		[378425] = {
			{
				{ SpellId = 642, Amount = -15, Mult = true },
				{ SpellId = 1022, Amount = -15, Mult = true },
				{ SpellId = 204018, Amount = -15, Mult = true },
			},
		},
		[204074] = { { { SpellId = 31884, Amount = -50, Mult = true }, { SpellId = 389539, Amount = -50, Mult = true } } },
	},
	[70] = { [384820] = { { { SpellId = 6940, Amount = -60 } } } },
	[258] = { [288733] = { { { SpellId = 47585, Amount = -30 } } } },
	[73] = { [397103] = { { { SpellId = 871, Amount = -60 } } } },
}

local ClassPvPCooldownModifiers = {}

local SpecPvPCooldownModifiers = {
	[268] = { [666] = { { SpellId = 115203, Amount = -50, Mult = true } } },
	[250] = { [5592] = { { SpellId = 48707, Amount = -10 } } },
	[251] = { [5591] = { { SpellId = 48707, Amount = -10 } } },
	[252] = { [5590] = { { SpellId = 48707, Amount = -10 } } },
	[261] = { [354825] = { { SpellId = 121471, Amount = -20, Mult = true } } },
}

local ClassDurationModifiers = {
	DEATHKNIGHT = {
		[205727] = { { { SpellId = 48707, Amount = 40, Mult = true } } },
	},
	DRUID = {
		[327993] = { { { SpellId = 22812, Amount = 4 } } },
	},
	HUNTER = {
		[388039] = { { { SpellId = 264735, Amount = 2 } } },
	},
}

local SpecDurationModifiers = {
	[66] = {
		[204074] = { { { SpellId = 31884, Amount = -40, Mult = true }, { SpellId = 389539, Amount = -40, Mult = true } } },
	},
	[250] = {
		[317133] = {
			{ { SpellId = 55233, Amount = 2 } },
			{ { SpellId = 55233, Amount = 4 } },
		},
	},
	[255] = { [1253830] = { { { SpellId = 1250646, Amount = 2 } } } },
	[72] = { [383468] = { { { SpellId = 184364, Amount = 3 } } } },
}

local ClassDefaultTalentRanks = {
	DEATHKNIGHT = { [205727] = 1 },
	HUNTER = { [1258485] = 1 },
	MAGE = { [382424] = 2, [1265517] = 1 },
	MONK = { [388813] = 1 },
	PALADIN = { [114154] = 1 },
	SHAMAN = { [381647] = 1 },
	WARRIOR = { [107574] = 1, [184364] = 1 },
}

local SpecDefaultTalentRanks = {
	[102] = { [468743] = 1 }, -- Balance Druid
	[254] = { [260404] = 1 }, -- MM Hunter
	[103] = { [102543] = 1, [391174] = 1, [391548] = 1 }, -- Feral
	[63] = { [1254194] = 1 }, -- Fire Mage
	[257] = { [419110] = 1 }, -- Holy Priest
	[105] = { [382552] = 1 }, -- Resto Druid
	[258] = { [288733] = 1 }, -- Shadow Priest
	[270] = { [202424] = 1 }, -- MW Monk
	[1468] = { [376204] = 1 }, -- Pres Evoker
	[65] = { [384820] = 1, [216331] = 1 }, -- Holy Paladin
	[66] = { [384820] = 1 }, -- Prot Paladin
	[70] = { [458359] = 1, [384820] = 1 }, -- Ret
	[72] = { [383468] = 1 }, -- Fury
}

local talentMapCache = {}

local function BuildTalentToSpellMap(specId)
	if talentMapCache[specId] then return talentMapCache[specId] end
	if not (C_ClassTalents and C_Traits and Constants and Constants.TraitConsts) then return nil end

	local configId = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
	C_ClassTalents.InitializeViewLoadout(specId, 100)
	C_ClassTalents.ViewLoadout({})
	local configInfo = C_Traits.GetConfigInfo(configId)
	if not configInfo then return nil end

	local talentmap = {}
	for _, treeId in ipairs(configInfo.treeIDs) do
		for _, nodeId in ipairs(C_Traits.GetTreeNodes(treeId)) do
			local node = C_Traits.GetNodeInfo(configId, nodeId)
			if node and node.ID ~= 0 then
				for choiceIndex, talentId in ipairs(node.entryIDs) do
					local entryInfo = C_Traits.GetEntryInfo(configId, talentId)
					if node.type == Enum.TraitNodeType.SubTreeSelection then
						talentmap[node.ID .. "_" .. choiceIndex] = {
							spellId = -1, maxRank = -1, type = node.type, subTreeID = entryInfo.subTreeID,
						}
					end
					if entryInfo and entryInfo.definitionID then
						local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
						if definitionInfo.spellID then
							talentmap[node.ID .. "_" .. choiceIndex] = {
								spellId = definitionInfo.spellID, maxRank = node.maxRanks, type = node.type, subTreeID = node.subTreeID,
							}
						end
					end
				end
			end
		end
	end

	talentMapCache[specId] = talentmap
	return talentmap
end

local function DecodeTalent(stream)
	local function readbool(s) return s:ExtractValue(1) == 1 end
	local selected = readbool(stream)
	local purchased = nil
	local rank = nil
	local choiceIndex = 1
	local notMaxRank = true
	if selected then
		purchased = readbool(stream)
		if purchased then
			notMaxRank = readbool(stream)
			if notMaxRank then rank = stream:ExtractValue(6) end
			local choiceNode = readbool(stream)
			if choiceNode then choiceIndex = stream:ExtractValue(2) + 1 end
		end
	end
	return selected, purchased, notMaxRank, rank, choiceIndex
end

local function GetTalentRanks(specId, talentExportString)
	if not (C_Traits and C_Traits.GetLoadoutSerializationVersion and ImportDataStreamMixin and C_ClassTalents) then return nil end
	local talentIdToSpellMap = BuildTalentToSpellMap(specId)
	if not talentIdToSpellMap then return nil end

	local stream = CreateAndInitFromMixin(ImportDataStreamMixin, talentExportString)
	local version = stream:ExtractValue(8)
	local encodedSpec = stream:ExtractValue(16)
	stream:ExtractValue(128) -- discard treeHash

	if C_Traits.GetLoadoutSerializationVersion() ~= 2 or version ~= 2 then return nil end
	if encodedSpec ~= specId then return nil end

	local traitTree = C_ClassTalents.GetTraitTreeForSpec(specId)
	if not traitTree then return nil end

	local fullRecords = {}
	local heroChoice
	for _, talentId in ipairs(C_Traits.GetTreeNodes(traitTree)) do
		local selected, purchased, _, rank, choiceIndex = DecodeTalent(stream)
		local spell = talentIdToSpellMap[talentId .. "_" .. choiceIndex]
		local record = {
			spellId = spell and spell.spellId or -1,
			selected = selected,
			purchased = purchased,
			rank = rank,
			maxRank = spell and spell.maxRank or nil,
			subTreeId = spell and spell.subTreeID or nil,
			type = spell and spell.type or nil,
		}
		fullRecords[#fullRecords + 1] = record
		if record.type == Enum.TraitNodeType.SubTreeSelection then heroChoice = spell.subTreeID end
	end

	local talentRanks = {}
	for _, record in ipairs(fullRecords) do
		if record.subTreeId == nil or record.subTreeId == heroChoice then
			talentRanks[record.spellId] = not record.selected and 0 or record.rank or record.maxRank
		end
	end
	return talentRanks
end

local function GetEffectiveTalentRanks(playerName, classToken, specId)
	local ranks = unitTalentRanks[playerName]
	if ranks then return ranks end
	local classDef = ClassDefaultTalentRanks[classToken]
	local specDef = specId and SpecDefaultTalentRanks[specId]
	if not classDef and not specDef then return nil end
	local merged = {}
	if classDef then for k, v in pairs(classDef) do merged[k] = v end end
	if specDef then for k, v in pairs(specDef) do merged[k] = v end end
	return merged
end

function M:GetUnitCooldown(unit, specId, classToken, abilityId, baseCooldown, measuredDuration)
	local playerName = UnitNameUnmodified(unit)
	if not playerName or issecretvalue(playerName) then return baseCooldown end
	local talentRanks = GetEffectiveTalentRanks(playerName, classToken, specId)
	if not talentRanks then return baseCooldown end

	local addAmount = 0
	local multAmount = 0
	local postBuffRemaining = nil
	local classMods = ClassCooldownModifiers[classToken]
	local resolvedSpec = unitTalentSpecId[playerName] or specId
	local specMods = resolvedSpec and SpecCooldownModifiers[resolvedSpec]

	local function applyModTable(modTable)
		if not modTable then return end
		for talentSpellId, rankList in pairs(modTable) do
			local rank = talentRanks[talentSpellId]
			if rank and rank > 0 then
				local mods = rankList[rank]
				if mods then
					for _, mod in ipairs(mods) do
						if mod.SpellId == abilityId then
							if mod.PostBuff then
								postBuffRemaining = mod.Amount
							elseif mod.Mult then
								multAmount = multAmount + mod.Amount
							else
								addAmount = addAmount + mod.Amount
							end
						end
					end
				end
			end
		end
	end
	applyModTable(classMods)
	applyModTable(specMods)

	local pvpIds = unitPvPTalentIds[playerName]
	if postBuffRemaining then return math.max((measuredDuration or 0) + postBuffRemaining, 0) end

	local cd = baseCooldown + addAmount + (baseCooldown * multAmount / 100)
	local pvpAddAmount = 0
	local pvpMultAmount = 0
	local function applyPvPModTable(modTable)
		if not modTable or not pvpIds then return end
		for pvpTalentId, mods in pairs(modTable) do
			if pvpIds[pvpTalentId] then
				for _, mod in ipairs(mods) do
					if mod.SpellId == abilityId then
						if mod.Mult then
							pvpMultAmount = pvpMultAmount + mod.Amount
						else
							pvpAddAmount = pvpAddAmount + mod.Amount
						end
					end
				end
			end
		end
	end
	applyPvPModTable(ClassPvPCooldownModifiers[classToken])
	applyPvPModTable(resolvedSpec and SpecPvPCooldownModifiers[resolvedSpec])

	cd = cd + pvpAddAmount + (cd * pvpMultAmount / 100)
	return math.max(cd, 0)
end

function M:GetUnitBuffDuration(unit, specId, classToken, abilityId, baseDuration)
	local playerName = UnitNameUnmodified(unit)
	if not playerName or issecretvalue(playerName) then return baseDuration end
	local talentRanks = GetEffectiveTalentRanks(playerName, classToken, specId)
	if not talentRanks then return baseDuration end

	local addAmount = 0
	local multAmount = 0
	local resolvedSpec = unitTalentSpecId[playerName] or specId

	local function applyDurationModTable(modTable)
		if not modTable then return end
		for talentSpellId, rankList in pairs(modTable) do
			local rank = talentRanks[talentSpellId]
			if rank and rank > 0 then
				local mods = rankList[rank]
				if mods then
					for _, mod in ipairs(mods) do
						if mod.SpellId == abilityId then
							if mod.Mult then
								multAmount = multAmount + mod.Amount
							else
								addAmount = addAmount + mod.Amount
							end
						end
					end
				end
			end
		end
	end
	applyDurationModTable(ClassDurationModifiers[classToken])
	applyDurationModTable(resolvedSpec and SpecDurationModifiers[resolvedSpec])

	return math.max(baseDuration + addAmount + (baseDuration * multAmount / 100), 0)
end

function M:UnitHasTalent(unit, talentSpellId, callerSpecId)
	local playerName = UnitNameUnmodified(unit)
	if not playerName or issecretvalue(playerName) then return false end
	local talentRanks = unitTalentRanks[playerName]
	if talentRanks ~= nil and (talentRanks[talentSpellId] or 0) > 0 then return true end
	local pvpIds = unitPvPTalentIds[playerName]
	if pvpIds ~= nil and pvpIds[talentSpellId] == true then return true end
	if talentRanks == nil then
		local _, classToken = UnitClass(unit)
		local specId = unitTalentSpecId[playerName] or callerSpecId
		local effectiveRanks = GetEffectiveTalentRanks(playerName, classToken, specId)
		if effectiveRanks and (effectiveRanks[talentSpellId] or 0) > 0 then return true end
	end
	return false
end

function M:GetUnitSpecId(unit)
	local playerName = UnitNameUnmodified(unit)
	if not playerName or issecretvalue(playerName) then return nil end
	return unitTalentSpecId[playerName]
end

local talentCallbacks = {}
function M:RegisterTalentCallback(fn) talentCallbacks[#talentCallbacks + 1] = fn end
local function FireTalentCallbacks(playerName)
	for _, fn in ipairs(talentCallbacks) do fn(playerName) end
end

local function OnLibSpecUpdate(specId, playerName, talentString)
	if not talentString then return end
	local ranks = GetTalentRanks(specId, talentString)
	if ranks then
		local name = playerName:match("^([^%-]+)") or playerName
		unitTalentRanks[name] = ranks
		unitTalentSpecId[name] = specId
		if db then
			db.TalentCache[name] = { SpecId = specId, TalentString = talentString, Time = time() }
		end
		FireTalentCallbacks(name)
	end
end

local function UpdateLocalPlayer()
	if not (GetSpecialization and GetSpecializationInfo) then return end
	local specIdx = GetSpecialization()
	if not specIdx then return end
	local specId = GetSpecializationInfo(specIdx)
	if not specId then return end
	local configId = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
	if not configId then return end
	local talentString = C_Traits and C_Traits.GenerateImportString and C_Traits.GenerateImportString(configId)
	if not talentString then return end
	local playerName = UnitNameUnmodified("player")
	local ranks = GetTalentRanks(specId, talentString)
	if ranks then
		unitTalentRanks[playerName] = ranks
		unitTalentSpecId[playerName] = specId
		if db then
			db.TalentCache[playerName] = { SpecId = specId, TalentString = talentString, Time = time() }
		end
		FireTalentCallbacks(playerName)
	end
end

function M:Refresh() end

function M:Init()
	db = mini:GetSavedVars()
	db.TalentCache = db.TalentCache or {}
	db.PvPTalentCache = db.PvPTalentCache or {}

	local now = time()
	local maxAge = 86400
	for name, entry in pairs(db.TalentCache) do
		if not entry.Time or (now - entry.Time) > maxAge then
			db.TalentCache[name] = nil
		else
			local ranks = GetTalentRanks(entry.SpecId, entry.TalentString)
			if ranks then
				unitTalentRanks[name] = ranks
				unitTalentSpecId[name] = entry.SpecId
			else
				db.TalentCache[name] = nil
			end
		end
	end
	for name, entry in pairs(db.PvPTalentCache) do
		if not entry.Time or (now - entry.Time) > maxAge then
			db.PvPTalentCache[name] = nil
		else
			local set = {}
			for _, id in ipairs(entry.Ids) do set[id] = true end
			unitPvPTalentIds[name] = set
		end
	end

	local libSpec = LibStub and LibStub("LibSpecialization", true)
	if libSpec then
		libSpec.RegisterGroup(addon, function(specId, _, _, playerName, talentString)
			OnLibSpecUpdate(specId, playerName, talentString)
		end)
	end

	local frame = CreateFrame("Frame")
	frame:SetScript("OnEvent", UpdateLocalPlayer)
	frame:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED")
	frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
	frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	frame:RegisterEvent("PLAYER_LOGIN")

	addon.Utils.PvPTalentSync:RegisterCallback(function(playerName, pvpTalentIds)
		local name = playerName:match("^([^%-]+)") or playerName
		if pvpTalentIds then
			local ids = {}
			for _, id in ipairs(pvpTalentIds) do ids[#ids + 1] = id end
			db.PvPTalentCache[name] = { Ids = ids, Time = time() }
			local set = {}
			for _, id in ipairs(ids) do set[id] = true end
			unitPvPTalentIds[name] = set
		else
			db.PvPTalentCache[name] = nil
			unitPvPTalentIds[name] = nil
		end
	end)
end
