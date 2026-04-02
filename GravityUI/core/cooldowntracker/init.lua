local ADDON_NAME, ns = ...

-- Mock MiniCC structure to allow a 1:1 drop-in of its core FCD files
ns.CooldownTracker = {
	Utils = {},
	Core = {},
	Modules = {},
}

local addon = ns.CooldownTracker

-- Framework Mock
addon.Core.Framework = {
	GetSavedVars = function()
		local db = ns.GetDB()
		if db and db.screenindicators and db.screenindicators.cooldownTracker then
			local ct = db.screenindicators.cooldownTracker
			if not ct.TalentCache then ct.TalentCache = {} end
			if not ct.PvPTalentCache then ct.PvPTalentCache = {} end
			if not ct.SpecCache then ct.SpecCache = {} end
			return ct
		end
		
		-- Fallback if DB not ready yet
		if not ns.CooldownTracker.db then
			ns.CooldownTracker.db = {
				Enabled = true,
				ShowTooltips = true,
				ShowOffensiveCooldowns = false,
				ShowCC = true,
				ShowImportant = true,
				ExcludePlayer = true,
				IconSpacing = 2,
				FontScale = 1.0,
				Icons = { MaxIcons = 3, Size = 25, ReverseCooldown = false, Glow = true, ColorByDispelType = true },
				GrowDirection = "RIGHT",
				AnchorOffset = { X = 0, Y = 0 },
				TalentCache = {},
				PvPTalentCache = {},
				SpecCache = {}
			}
		end
		return ns.CooldownTracker.db
	end,
	Notify = function(self, msg, ...)
		print("|cFF00FFFFGravityUI:|r " .. string.format(msg, ...))
	end
}

addon.Core.InstanceOptions = {
	IsRaid = function() return IsInRaid() end,
	IsArena = function() local isIn, t = IsInInstance(); return isIn and t == "arena" end,
	IsBattleground = function() local isIn, t = IsInInstance(); return isIn and t == "pvp" end,
	IsDungeon = function() local isIn, t = IsInInstance(); return isIn and t == "party" end,
	IsWorld = function() local isIn = IsInInstance(); return not isIn end,
}

addon.Utils.ModuleName = {
	FriendlyIndicator = "FriendlyIndicator",
	FriendlyCooldownTracker = "FriendlyCooldownTracker"
}

addon.Utils.ModuleUtil = {
	IsModuleEnabled = function(moduleName)
		-- Driven by the GravityUI config checkboxes
		local db = addon.Core.Framework:GetSavedVars()
		local opts = db.Enabled
		if not opts then return true end

		if addon.Core.InstanceOptions.IsArena() then return opts.Arena end
		if addon.Core.InstanceOptions.IsBattleground() then return opts.BattleGrounds end
		if addon.Core.InstanceOptions.IsDungeon() then return opts.Dungeons end
		if addon.Core.InstanceOptions.IsRaid() then return opts.Raid end
		
		return opts.World
	end
}

-- Mock PvPTalentSync
local pvpCallbacks = {}
addon.Utils.PvPTalentSync = {
	RegisterCallback = function(self, fn)
		table.insert(pvpCallbacks, fn)
	end
}
