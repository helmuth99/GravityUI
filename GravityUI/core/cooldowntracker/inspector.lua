local ADDON_NAME, ns = ...
local addon = ns.CooldownTracker

local inspectInterval  = 0.5
local inspectTimeout   = 10
local cacheTimeout     = 60
local cacheExpiry      = 60 * 60 * 24 * 3 -- 3 days

local unitGuidToSpec      = {}
local priorityStack       = {}
local requestedUnit       = nil
local currentInspectUnit  = nil
local isOurInspect        = false
local needUpdate          = true
local inspectStarted      = nil
local callbacks           = {}

---@class Inspector
local M = {}
addon.Core.Inspector = M

local function Now()
	return GetTimePreciseSec and GetTimePreciseSec() or GetTime()
end

local function GetFriendlyUnits()
	local units = { "player" }
	local numGroup = GetNumGroupMembers()
	if IsInRaid() then
		for i = 1, numGroup do
			units[#units + 1] = "raid" .. i
		end
	else
		for i = 1, numGroup do
			units[#units + 1] = "party" .. i
		end
	end
	return units
end

local function OnSpecInformationChanged()
	for _, callback in ipairs(callbacks) do
		pcall(callback)
	end
end

local tooltipSpecMap = nil

local function GetTooltipSpecMap()
	if tooltipSpecMap then return tooltipSpecMap end
	tooltipSpecMap = {}
	if not (GetNumClasses and GetClassInfo and GetNumSpecializationsForClassID and GetSpecializationInfoForClassID) then
		return tooltipSpecMap
	end

	for classIdx = 1, GetNumClasses() do
		local className, _, classId = GetClassInfo(classIdx)
		if className and classId then
			for specIdx = 1, GetNumSpecializationsForClassID(classId) do
				local specId, specName = GetSpecializationInfoForClassID(classId, specIdx)
				if specId and specName then
					tooltipSpecMap[specName .. " " .. className] = specId
				end
			end
		end
	end
	return tooltipSpecMap
end

local function SpecFromTooltip(unit)
	if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then return nil end
	local tooltipData = C_TooltipInfo.GetUnit(unit)
	if not tooltipData then return nil end

	local specMap = GetTooltipSpecMap()
	for _, line in ipairs(tooltipData.lines) do
		if line and line.type == Enum.TooltipDataLineType.None and line.leftText then
			if not issecretvalue(line.leftText) then
				local specId = specMap[line.leftText]
				if specId then return specId end
			end
		end
	end
	return nil
end

local function PurgeOldEntries()
	local now = Now()
	for guid, entry in pairs(unitGuidToSpec) do
		if not entry or type(entry) ~= "table" or not entry.LastSeen or (now - entry.LastSeen) > cacheExpiry then
			unitGuidToSpec[guid] = nil
		end
	end
end

local function EnsureCacheEntry(unit)
	local guid = UnitGUID(unit)
	if not guid or issecretvalue(guid) then return nil end
	if not unitGuidToSpec[guid] then
		unitGuidToSpec[guid] = {}
	end
	return unitGuidToSpec[guid]
end

local function Inspect(unit)
	local specId = GetInspectSpecialization and GetInspectSpecialization(unit)
	if specId and specId > 0 then
		local cacheEntry = EnsureCacheEntry(unit)
		if cacheEntry then
			local before = cacheEntry.SpecId
			cacheEntry.SpecId = specId
			cacheEntry.LastSeen = Now()
			if before ~= specId then
				OnSpecInformationChanged()
			end
		end
	end

	if isOurInspect then
		currentInspectUnit = nil
		requestedUnit = nil
		isOurInspect = false
		ClearInspectPlayer()
	end
end

local function InvalidateEntry(unit)
	local guid = UnitGUID(unit)
	if not guid or issecretvalue(guid) then return end
	unitGuidToSpec[guid] = nil
	needUpdate = true
end

local function OnClearInspect()
	requestedUnit = nil
end

local function OnNotifyInspect(unit)
	if currentInspectUnit and unit ~= currentInspectUnit then
		currentInspectUnit = nil
	end
	requestedUnit = unit
	inspectStarted = Now()
	isOurInspect = false
end

local function GetNextTarget()
	while #priorityStack > 0 do
		local unit = priorityStack[#priorityStack]
		priorityStack[#priorityStack] = nil
		if UnitExists(unit) then
			local guid = UnitGUID(unit)
			if guid and not issecretvalue(guid) then return unit end
		end
	end

	local units = GetFriendlyUnits()
	local now = Now()

	for _, unit in ipairs(units) do
		if not UnitIsUnit(unit, "player") then
			local guid = UnitGUID(unit)
			if guid and not issecretvalue(guid) then
				local cacheEntry = unitGuidToSpec[guid]
				if not cacheEntry and CanInspect(unit) and UnitIsConnected(unit) then
					return unit
				end
			end
		end
	end

	for _, unit in ipairs(units) do
		if not UnitIsUnit(unit, "player") then
			local guid = UnitGUID(unit)
			if guid and not issecretvalue(guid) then
				local cacheEntry = unitGuidToSpec[guid]
				if cacheEntry and (not cacheEntry.SpecId or cacheEntry.SpecId == 0) and CanInspect(unit) and UnitIsConnected(unit) and (not cacheEntry.LastAttempt or (now - cacheEntry.LastAttempt > cacheTimeout)) then
					return unit
				end
			end
		end
	end

	return nil
end

local function RunLoop()
	C_Timer.After(inspectInterval, RunLoop)

	local now = Now()
	local timeSinceLastInspect = inspectStarted and (now - inspectStarted)

	if requestedUnit ~= nil and timeSinceLastInspect and timeSinceLastInspect < inspectTimeout then return end

	if requestedUnit ~= nil then
		if isOurInspect then ClearInspectPlayer() end
		requestedUnit = nil
		currentInspectUnit = nil
		isOurInspect = false
	end

	if not needUpdate then return end

	local unit = GetNextTarget()
	if not unit then
		needUpdate = false
		return
	end

	local cacheEntry = EnsureCacheEntry(unit)
	if not cacheEntry then return end

	cacheEntry.LastAttempt = now
	ClearInspectPlayer()
	NotifyInspect(unit)
	isOurInspect = true
	inspectStarted = now
	requestedUnit = unit
	currentInspectUnit = unit
end

function M:GetUnitSpecId(unit)
	if not unit then return nil end

	if UnitIsUnit(unit, "player") then
		if GetSpecialization and GetSpecializationInfo then
			local index = GetSpecialization()
			if index then
				local id = GetSpecializationInfo(index)
				return id
			end
		end
		return nil
	end

	local guid = UnitGUID(unit)
	if not guid or issecretvalue(guid) then return nil end

	local cacheEntry = unitGuidToSpec[guid]
	if cacheEntry and cacheEntry.SpecId and cacheEntry.SpecId > 0 then
		return cacheEntry.SpecId
	end

	local specId = SpecFromTooltip(unit)
	if specId then
		cacheEntry = EnsureCacheEntry(unit)
		if cacheEntry then
			cacheEntry.SpecId = specId
			cacheEntry.LastSeen = Now()
		end
		return specId
	end

	if not cacheEntry then
		priorityStack[#priorityStack + 1] = unit
		needUpdate = true
	end

	return cacheEntry and cacheEntry.SpecId
end

function M:RegisterCallback(callback)
	callbacks[#callbacks + 1] = callback
end

function M:Init()
	if not (CanInspect and NotifyInspect and ClearInspectPlayer and GetInspectSpecialization) then return end

	local db = addon.Core.Framework:GetSavedVars()
	db.SpecCache = db.SpecCache or {}
	unitGuidToSpec = db.SpecCache

	PurgeOldEntries()

	hooksecurefunc("NotifyInspect", OnNotifyInspect)
	hooksecurefunc("ClearInspectPlayer", OnClearInspect)

	local eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", function(_, event, ...)
		if event == "INSPECT_READY" then
			if requestedUnit then Inspect(requestedUnit) end
		elseif event == "GROUP_ROSTER_UPDATE" then
			needUpdate = true
		elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
			local unit = ...
			InvalidateEntry(unit)
		elseif event == "PLAYER_ENTERING_WORLD" then
			priorityStack = {}
		end
	end)
	eventsFrame:RegisterEvent("INSPECT_READY")
	eventsFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	eventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

	RunLoop()
end
