local ADDON_NAME, ns = ...
local addon = ns.CooldownTracker
local mini = addon.Core.Framework
local array = addon.Utils.Array
local wowEx = addon.Utils.WoWEx

-- Frames.lua starts here
local maxParty = MAX_PARTY_MEMBERS or 4
local maxRaid = MAX_RAID_MEMBERS or 40
local maxTestFrames = 3
local testPartyFrames = {}
local testFramesContainer = nil
local db
local initialised = false

---@class Frames
local F = {}
addon.Core.Frames = F

local function CreateTestFrame(i)
	local frame = CreateFrame("Frame", "GravityUIDefensiveTestFrame" .. i, UIParent, "BackdropTemplate")
	frame:SetSize(144, 72)
	local _, class = UnitClass("player")
	local colour = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR

	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame:SetBackdropColor(colour.r, colour.g, colour.b, 0.9)
	frame:SetBackdropBorderColor(0, 0, 0, 1)

	frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.Text:SetPoint("CENTER")
	frame.Text:SetText(("party%d"):format(i))
	frame.Text:SetTextColor(1, 1, 1)
	frame.unit = "party" .. i
	frame:Hide()
	return frame
end

local function CreateTestFrames()
	testFramesContainer = CreateFrame("Frame", "GravityUIDefensiveTestContainer")
	testFramesContainer:SetClampedToScreen(true)
	testFramesContainer:EnableMouse(true)
	testFramesContainer:SetMovable(true)
	testFramesContainer:RegisterForDrag("LeftButton")
	testFramesContainer:SetScript("OnDragStart", function(containerSelf) containerSelf:StartMoving() end)
	testFramesContainer:SetScript("OnDragStop", function(containerSelf) containerSelf:StopMovingOrSizing() end)
	testFramesContainer:SetPoint("CENTER", UIParent, "CENTER", -450, 0)
	testFramesContainer:Hide()

	local width, height = 144, 72
	local padding = 10
	for i = 1, maxTestFrames do
		local frame = testPartyFrames[i]
		if not frame then
			frame = CreateTestFrame(i)
			testPartyFrames[i] = frame
		end
		frame:ClearAllPoints()
		frame:SetSize(width, height)
		frame:SetPoint("TOP", testFramesContainer, "TOP", 0, (i - 1) * -frame:GetHeight() - padding)
	end
	testFramesContainer:SetSize(width + padding * 2, height * maxTestFrames + padding * 2)
end

function F:BlizzardFrames(visibleOnly)
	local frames = {}
	for i = 1, maxParty + 1 do
		local frame = _G["CompactPartyFrameMember" .. i]
		if frame and (frame:IsVisible() or not visibleOnly) then frames[#frames + 1] = frame end
	end
	for i = 1, maxRaid do
		local frame = _G["CompactRaidFrame" .. i]
		if frame and (frame:IsVisible() or not visibleOnly) then frames[#frames + 1] = frame end
	end
	return frames
end

function F:BlizzardPartyFrames(visibleOnly)
	if not PartyFrame then return {} end
	local frames = {}
	for i = 1, maxParty + 1 do
		local frame = PartyFrame["MemberFrame" .. i]
		if frame and (frame:IsVisible() or not visibleOnly) then frames[#frames + 1] = frame end
	end
	return frames
end

function F:DandersFrames()
	local frames
	if DandersFrames_GetAllFrames then
		local s, r = pcall(DandersFrames_GetAllFrames)
		if s then frames = r end
	end
	return frames or {}
end

function F:Grid2Frames(visibleOnly)
	if not Grid2 or not Grid2.GetUnitFrames then return {} end
	local frames = {}
	local s, r = pcall(Grid2.GetUnitFrames, Grid2, "player")
	local pf = s and r and next(r)
	if pf and (pf:IsVisible() or not visibleOnly) then frames[#frames + 1] = pf end
	for i = 1, maxParty do
		local ps, pr = pcall(Grid2.GetUnitFrames, Grid2, "party" .. i)
		local frame = ps and pr and next(pr)
		if not frame then break end
		if frame:IsVisible() or not visibleOnly then frames[#frames + 1] = frame end
	end
	for i = 1, maxRaid do
		local rs, rr = pcall(Grid2.GetUnitFrames, Grid2, "raid" .. i)
		local frame = rs and rr and next(rr)
		if frame and (frame:IsVisible() or not visibleOnly) then frames[#frames + 1] = frame end
	end
	return frames
end

function F:ElvUIFrames(visibleOnly)
	if not ElvUI then return {} end
	local s, E = pcall(unpack, ElvUI)
	if not s or not E then return {} end
	local ufs, UF = pcall(E.GetModule, E, "UnitFrames")
	if not ufs or not UF then return {} end
	local frames = {}
	for groupName in pairs(UF.headers) do
		local group = UF[groupName]
		if group and group.GetChildren then
			for _, frame in ipairs({group:GetChildren()}) do
				if not frame.Health then
					for _, child in ipairs({frame:GetChildren()}) do
						if child.unit and (child:IsVisible() or not visibleOnly) then frames[#frames + 1] = child end
					end
				elseif frame.unit and (frame:IsVisible() or not visibleOnly) then
					frames[#frames + 1] = frame
				end
			end
		end
	end
	return frames
end

function F:ShadowedUFFrames(visibleOnly)
	if not SUFUnitplayer and not SUFHeaderpartyUnitButton1 and not SUFHeaderraidUnitButton1 then return {} end
	local frames = {}
	local function Add(frame)
		if not frame then return end
		if frame.IsForbidden and frame:IsForbidden() then return end
		if (not visibleOnly) or frame:IsVisible() then frames[#frames + 1] = frame end
	end
	for _, unitName in ipairs({"player", "pet", "pettarget", "target", "targettarget", "targettargettarget", "focus", "focustarget"}) do
		Add(_G["SUFUnit" .. unitName])
	end
	for i = 1, maxParty do Add(_G["SUFHeaderpartyUnitButton" .. i]); Add(_G["SUFUnitparty" .. i]) end
	for i = 1, maxRaid do Add(_G["SUFHeaderraidUnitButton" .. i]); Add(_G["SUFUnitraid" .. i]) end
	return frames
end

function F:PlexusFrames(visibleOnly)
	if not PlexusLayoutHeader1 then return {} end
	local frames, seen = {}, {}
	local function Add(frame)
		if not frame or seen[frame] then return end
		if frame.IsForbidden and frame:IsForbidden() then return end
		if visibleOnly and not frame:IsVisible() then return end
		seen[frame] = true; frames[#frames + 1] = frame
	end
	local idx = 1
	while true do
		local header = _G["PlexusLayoutHeader" .. idx]
		if not header then break end
		for _, child in ipairs({header:GetChildren()}) do
			local unit = child.unit or (child.GetAttribute and child:GetAttribute("unit"))
			if unit and unit ~= "" then Add(child) end
		end
		idx = idx + 1
	end
	return frames
end

function F:CellFrames(visibleOnly)
	if not CellPartyFrameHeader and not CellRaidFrameHeader0 then return {} end
	local frames = {}
	local headers = { CellPartyFrameHeader, CellSoloFrame }
	for i = 0, 8 do
		local header = _G["CellRaidFrameHeader" .. i]
		if header then headers[#headers + 1] = header end
	end
	for _, header in ipairs(headers) do
		if header then
			for _, child in ipairs({header:GetChildren()}) do
				local unit = child.unit or (child.GetAttribute and child:GetAttribute("unit"))
				if unit and unit ~= "" then
					if child.IsForbidden and child:IsForbidden() then
					elseif child:IsVisible() or not visibleOnly then
						frames[#frames + 1] = child
					end
				end
			end
		end
	end
	return frames
end

function F:TPerlFrames(visibleOnly)
	if not TPerl_Party_SecureHeader then return {} end
	local frames = {}
	for _, child in ipairs({TPerl_Party_SecureHeader:GetChildren()}) do
		local unit = child.unit or (child.GetAttribute and child:GetAttribute("unit"))
		if unit and unit ~= "" then
			if child.IsForbidden and child:IsForbidden() then
			elseif child:IsVisible() or not visibleOnly then
				frames[#frames + 1] = child
			end
		end
	end
	return frames
end

function F:EnhancedQoLFrames(visibleOnly)
	local hasAny = EQOLUFPartyHeader
	for i = 1, 8 do if _G["EQOLUFRaidGroupHeader" .. i] then hasAny = true; break end end
	if not hasAny then return {} end
	local frames, headers = {}, { EQOLUFPartyHeader }
	for i = 1, 8 do
		local header = _G["EQOLUFRaidGroupHeader" .. i]
		if header then headers[#headers + 1] = header end
	end
	for _, header in ipairs(headers) do
		if header then
			for _, child in ipairs({header:GetChildren()}) do
				local unit = child.unit or (child.GetAttribute and child:GetAttribute("unit"))
				if unit and unit ~= "" then
					if child.IsForbidden and child:IsForbidden() then
					elseif child:IsVisible() or not visibleOnly then
						frames[#frames + 1] = child
					end
				end
			end
		end
	end
	return frames
end

function F:CustomFrames(visibleOnly)
	local frames = {}
	-- Skipping config based custom anchors since we don't carry the anchor textboxes yet
	return frames
end

function F:GetTestFrameContainer() return testFramesContainer end
function F:GetTestFrames() return testPartyFrames end

function F:GetAll(visibleOnly, includeTestFrames)
	local anchors = {}
	local elvui = F:ElvUIFrames(visibleOnly)
	local grid2 = F:Grid2Frames(visibleOnly)
	local danders = F:DandersFrames()
	local blizzard = not wowEx:IsDandersEnabled() and F:BlizzardFrames(visibleOnly) or {}
	local blizzardParty = not wowEx:IsDandersEnabled() and F:BlizzardPartyFrames(visibleOnly) or {}
	local suf = F:ShadowedUFFrames(visibleOnly)
	local plexus = F:PlexusFrames(visibleOnly)
	local cell = F:CellFrames(visibleOnly)
	local tperl = F:TPerlFrames(visibleOnly)
	local eqol = F:EnhancedQoLFrames(visibleOnly)
	local custom = F:CustomFrames(visibleOnly)

	array:Append(blizzard, anchors)
	array:Append(blizzardParty, anchors)
	array:Append(elvui, anchors)
	array:Append(grid2, anchors)
	array:Append(danders, anchors)
	array:Append(suf, anchors)
	array:Append(plexus, anchors)
	array:Append(cell, anchors)
	array:Append(tperl, anchors)
	array:Append(eqol, anchors)
	array:Append(custom, anchors)

	if includeTestFrames then
		local testFrames = F:GetTestFrames()
		array:Append(testFrames, anchors)
	end
	return anchors
end

local strataOrder = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local strataIndex = {}
for i, v in ipairs(strataOrder) do strataIndex[v] = i end

function F:GetNextStrata(strata)
	return strataOrder[math.min((strataIndex[strata] or 1) + 1, #strataOrder)]
end

function F:IsFriendlyCuf(frame)
	if not frame or issecretvalue(frame) then return false end
	if frame:IsForbidden() then return false end
	local name = frame:GetName()
	if not name then return false end
	if string.find(name, "CompactParty") ~= nil or string.find(name, "CompactRaid") ~= nil then return true end
	if PartyFrame and frame:GetParent() == PartyFrame then return true end
	return false
end

function F:ShowHideFrame(frame, anchor, isTest, excludePlayer)
	if anchor:IsForbidden() then frame:Hide(); return end
	local unit = frame:GetAttribute("unit") or anchor.unit or anchor:GetAttribute("unit")
	if unit and unit ~= "" then
		if excludePlayer and UnitIsUnit(unit, "player") then frame:Hide(); return end
	end
	if anchor:IsVisible() then
		frame:SetAlpha(1)
		frame:Show()
	else
		frame:Hide()
	end
end

function F:Init()
	if initialised then return end
	db = mini:GetSavedVars()
	CreateTestFrames()
	initialised = true
end

-- IconSlotContainer.lua starts here
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
local Masque = LibStub and LibStub("Masque", true)
local masqueReskinPending = {}
local fontUtil = addon.Utils.FontUtil
local cachedDb = nil
local layoutScratch = {}
local frameIdCounter = 0

local function NextFrameName(frameType)
	frameIdCounter = frameIdCounter + 1
	return "GravityUICDTracker_" .. frameType .. "_" .. frameIdCounter
end

---@class IconSlotContainer
local M = {}
M.__index = M
addon.Core.IconSlotContainer = M

local function GetDb()
	if not cachedDb then cachedDb = mini:GetSavedVars() end
	return cachedDb
end

local function ScheduleMasqueReSkin(group)
	if not group or masqueReskinPending[group] then return end
	masqueReskinPending[group] = true
	C_Timer.After(0, function() masqueReskinPending[group] = nil; group:ReSkin() end)
end

local function CreateLayer(parentFrame, level, iconSize, noBorder)
	local f = CreateFrame("Frame", NextFrameName("Layer"), parentFrame)
	f:SetAllPoints()
	if level then f:SetFrameLevel(level) end

	local bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 1)

	local icon = f:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local cd = CreateFrame("Cooldown", NextFrameName("Cooldown"), f, "CooldownFrameTemplate")
	cd:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
	cd:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
	cd:SetDrawEdge(false)
	cd:SetDrawBling(false)
	cd:SetHideCountdownNumbers(false)
	cd:SetSwipeColor(0, 0, 0, 0.8)

	local border
	if not noBorder then
		border = CreateFrame("Frame", nil, f, "BackdropTemplate")
		border:SetAllPoints()
		border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
		border:Hide()
		border.SetVertexColor = function(self, r, g, b, a) self:SetBackdropBorderColor(r, g, b, a) end
	end

	if iconSize then
		cd.DesiredIconSize = iconSize
		cd.FontScale = 1.0
		fontUtil:UpdateCooldownFontSize(cd, iconSize, nil, cd.FontScale)
	end
	return { Frame = f, Border = border, Icon = icon, Cooldown = cd }
end

local function EnsureContainer(slot, iconSize, group, noBorder)
	if slot.Container then return slot.Container end
	local slotLevel = slot.Frame:GetFrameLevel() or 0
	slot.Container = CreateLayer(slot.Frame, slotLevel + 1, iconSize, noBorder)
	if group then group:AddButton(slot.Container.Frame, { Icon = slot.Container.Icon, Cooldown = slot.Container.Cooldown }) end
	return slot.Container
end

local function EnsureExtraLayer(slot, layerIndex, iconSize)
	local extraIdx = layerIndex - 1
	if not slot.ExtraLayers then slot.ExtraLayers = {} end
	local slotLevel = slot.Frame:GetFrameLevel() or 0
	local baseLevel = slotLevel + 1

	for l = #slot.ExtraLayers + 1, extraIdx do
		slot.ExtraLayers[l] = CreateLayer(slot.Frame, baseLevel + l * 2, iconSize)
	end
	if slot.LastExtraBaseLevel ~= baseLevel then
		slot.LastExtraBaseLevel = baseLevel
		for l = 1, #slot.ExtraLayers do
			local el = slot.ExtraLayers[l]
			if el and el.Frame then el.Frame:SetFrameLevel(baseLevel + l * 2) end
		end
	end
	return slot.ExtraLayers[extraIdx]
end

local function ApplyAlpha(target, alpha)
	if type(alpha) == "number" then target:SetAlpha(alpha) else target:SetAlphaFromBoolean(alpha) end
end

local function EnsureFlipbookGlow(parent)
	if parent._FlipbookGlow then return parent._FlipbookGlow end
	local cg = CreateFrame("Frame", NextFrameName("FlipbookGlow"), parent)
	cg:SetFrameLevel(parent:GetFrameLevel() + 5)
	cg.Texture = cg:CreateTexture(nil, "OVERLAY")
	cg.Texture:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Textures\\FlipbookWhite.tga")
	cg.Texture:SetAllPoints()
	cg.Texture:SetBlendMode("ADD")
	cg.Anim = cg:CreateAnimationGroup()
	cg.Anim:SetLooping("REPEAT")
	local flip = cg.Anim:CreateAnimation("FlipBook")
	flip:SetChildKey("Texture"); flip:SetFlipBookRows(6); flip:SetFlipBookColumns(5); flip:SetFlipBookFrames(30); flip:SetDuration(1.0)
	cg.Anim:Play()
	parent:HookScript("OnSizeChanged", function(self, width)
		if self._FlipbookGlow then
			local padding = width / 3
			self._FlipbookGlow:SetPoint("TOPLEFT", self, "TOPLEFT", -padding, padding)
			self._FlipbookGlow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", padding, -padding)
		end
	end)
	local width = parent:GetWidth()
	local initPadding = (width and width > 0) and (width / 3) or 9
	cg:SetPoint("TOPLEFT", parent, "TOPLEFT", -initPadding, initPadding)
	cg:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", initPadding, -initPadding)
	cg:Hide()
	parent._FlipbookGlow = cg
	return cg
end

local function ClearLayerData(layer, glowFrame)
	if not layer then return end
	layer.Icon:SetTexture(nil)
	layer.Cooldown:Clear()
	if LCG then
		if glowFrame._ProcGlow and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(glowFrame) end
		if glowFrame._PixelGlow and LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(glowFrame) end
		if glowFrame._AutoCastGlow and LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(glowFrame) end
	end
	if glowFrame._FlipbookGlow then glowFrame._FlipbookGlow:Hide() end
end

local function UpdateGlow(layerFrame, options)
	local db = GetDb()
	local glowType = (db and db.GlowType) or "Proc Glow"

	if options.Glow then
		local hasProcGlow = layerFrame._ProcGlow ~= nil
		local hasPixelGlow = layerFrame._PixelGlow ~= nil
		local hasAutoCastGlow = layerFrame._AutoCastGlow ~= nil
		local hasCustomGlow = layerFrame._FlipbookGlow ~= nil
		local colorChanged = false
		local newColorKey = nil

		if options.Color then
			newColorKey = string.format("%.2f_%.2f_%.2f_%.2f", options.Color.r or 1, options.Color.g or 1, options.Color.b or 1, options.Color.a or 1)
		end
		if not newColorKey or not issecretvalue(newColorKey) then
			if layerFrame._GlowColorKey ~= newColorKey then
				colorChanged = true
				layerFrame._GlowColorKey = newColorKey
			end
		elseif newColorKey and issecretvalue(newColorKey) then
			colorChanged = true
		end

		local needsGlow = false
		if glowType == "Proc Glow" and (not hasProcGlow or colorChanged) then
			needsGlow = true
			if hasPixelGlow and LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(layerFrame) end
			if hasAutoCastGlow and LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(layerFrame) end
			if hasProcGlow and colorChanged and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(layerFrame) end
			if hasCustomGlow then layerFrame._FlipbookGlow:Hide() end
		elseif glowType == "Pixel Glow" and (not hasPixelGlow or colorChanged) then
			needsGlow = true
			if hasProcGlow and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(layerFrame) end
			if hasAutoCastGlow and LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(layerFrame) end
			if hasPixelGlow and colorChanged and LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(layerFrame) end
			if hasCustomGlow then layerFrame._FlipbookGlow:Hide() end
		elseif glowType == "Autocast Shine" and (not hasAutoCastGlow or colorChanged) then
			needsGlow = true
			if hasProcGlow and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(layerFrame) end
			if hasPixelGlow and LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(layerFrame) end
			if hasAutoCastGlow and colorChanged and LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(layerFrame) end
			if hasCustomGlow then layerFrame._FlipbookGlow:Hide() end
		elseif glowType == "Rotation Assist" and (not hasCustomGlow or colorChanged or not layerFrame._FlipbookGlow:IsShown()) then
			needsGlow = true
			if hasProcGlow and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(layerFrame) end
			if hasPixelGlow and LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(layerFrame) end
			if hasAutoCastGlow and LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(layerFrame) end
		end

		if needsGlow then
			local glowOptions = { startAnim = false }
			if options.Color then glowOptions.color = { options.Color.r, options.Color.g, options.Color.b, options.Color.a } end

			if glowType == "Pixel Glow" and LCG and LCG.PixelGlow_Start then
				LCG.PixelGlow_Start(layerFrame, glowOptions.color)
			elseif glowType == "Autocast Shine" and LCG and LCG.AutoCastGlow_Start then
				LCG.AutoCastGlow_Start(layerFrame, glowOptions.color)
			elseif glowType == "Rotation Assist" then
				local cg = EnsureFlipbookGlow(layerFrame)
				if options.Color then
					cg.Texture:SetVertexColor(options.Color.r or 1, options.Color.g or 1, options.Color.b or 1, options.Color.a or 1)
				else
					cg.Texture:SetVertexColor(1, 1, 1, 1)
				end
				cg:Show()
			else
				if LCG and LCG.ProcGlow_Start then LCG.ProcGlow_Start(layerFrame, glowOptions) end
			end
		end

		local alpha = options.Alpha
		if glowType == "Proc Glow" and layerFrame._ProcGlow then ApplyAlpha(layerFrame._ProcGlow, alpha)
		elseif glowType == "Pixel Glow" and layerFrame._PixelGlow then ApplyAlpha(layerFrame._PixelGlow, alpha)
		elseif glowType == "Autocast Shine" and layerFrame._AutoCastGlow then ApplyAlpha(layerFrame._AutoCastGlow, alpha)
		elseif glowType == "Rotation Assist" and layerFrame._FlipbookGlow then ApplyAlpha(layerFrame._FlipbookGlow, alpha)
		end

		if glowType == "Proc Glow" and layerFrame._ProcGlow and LCG and LCG.ProcGlow_Start then
			local glowOptions = { startAnim = false }
			if options.Color then glowOptions.color = { options.Color.r, options.Color.g, options.Color.b, options.Color.a } end
			LCG.ProcGlow_Start(layerFrame, glowOptions)
		end
	else
		if layerFrame._ProcGlow and LCG and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(layerFrame) end
		if layerFrame._PixelGlow and LCG and LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(layerFrame) end
		if layerFrame._AutoCastGlow and LCG and LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(layerFrame) end
		if layerFrame._FlipbookGlow then layerFrame._FlipbookGlow:Hide() end
		layerFrame._GlowColorKey = nil
	end
end

function M:New(parent, count, size, spacing, groupName, noBorder)
	local instance = setmetatable({}, M)
	count, size, spacing = count or 3, size or 20, spacing or 2

	instance.Frame = CreateFrame("Frame", NextFrameName("Container"), parent)
	instance.Frame:SetIgnoreParentScale(true)
	instance.Frame:SetIgnoreParentAlpha(true)
	instance.Slots = {}
	instance.Count = 0
	instance.Size = size
	instance.Spacing = spacing
	instance.NumRows = nil
	instance.RowAlignment = nil
	instance.InvertLayout = false
	instance.NoBorder = noBorder or false
	instance.MiniCCModule = groupName or nil
	instance.MasqueGroup = Masque and groupName and Masque:Group("MiniCC", groupName) or nil

	instance:SetCount(count)
	return instance
end

function M:Layout()
	local n = 0
	for i = 1, self.Count do
		if self.Slots[i] and self.Slots[i].IsUsed then
			n = n + 1
			layoutScratch[n] = i
		end
	end

	local numRows = (self.NumRows and self.NumRows > 1) and self.NumRows or nil
	local sig = self.Size .. ":" .. (numRows or 1) .. ":" .. (self.RowAlignment or "C") .. ":" .. (self.OverflowRowAlignment or "C") .. ":" .. (self.InvertLayout and "1" or "0") .. ":" .. table.concat(layoutScratch, ",", 1, n)
	if self.LayoutSignature == sig then return end
	self.LayoutSignature = sig

	for i = n + 1, #layoutScratch do layoutScratch[i] = nil end
	local usedCount = n

	if usedCount == 0 then
		self.Frame:SetSize(self.Size, self.Size)
	elseif numRows then
		local iconsPerRow = math.max(1, math.ceil(usedCount / numRows))
		local actualRows = math.ceil(usedCount / iconsPerRow)
		local rowWidth = iconsPerRow * self.Size + (iconsPerRow - 1) * self.Spacing
		local totalHeight = actualRows * self.Size + (actualRows - 1) * self.Spacing
		self.Frame:SetSize(rowWidth, totalHeight)
		self.Frame:SetAlpha(1)

		local row1Alignment = self.RowAlignment or "CENTER"
		local overflowAlignment = self.OverflowRowAlignment or row1Alignment

		for displayIndex = 1, usedCount do
			local slot = self.Slots[layoutScratch[displayIndex]]
			local rowIndex = math.floor((displayIndex - 1) / iconsPerRow)
			local rawCol = (displayIndex - 1) % iconsPerRow
			local colIndex = self.InvertLayout and (iconsPerRow - 1 - rawCol) or rawCol
			local rowIcons = (rowIndex == actualRows - 1) and (usedCount - (actualRows - 1) * iconsPerRow) or iconsPerRow

			local x
			if self.InvertLayout then
				x = colIndex * (self.Size + self.Spacing) - (rowWidth / 2) + (self.Size / 2)
			else
				local alignment = rowIndex == 0 and row1Alignment or overflowAlignment
				if alignment == "LEFT" then
					x = colIndex * (self.Size + self.Spacing) - (rowWidth / 2) + (self.Size / 2)
				elseif alignment == "RIGHT" then
					local shift = (iconsPerRow - rowIcons) * (self.Size + self.Spacing)
					x = colIndex * (self.Size + self.Spacing) - (rowWidth / 2) + (self.Size / 2) + shift
				else
					local thisRowWidth = rowIcons * self.Size + (rowIcons - 1) * self.Spacing
					x = colIndex * (self.Size + self.Spacing) - (thisRowWidth / 2) + (self.Size / 2)
				end
			end
			local y = (totalHeight / 2) - (self.Size / 2) - rowIndex * (self.Size + self.Spacing)

			slot.Frame:ClearAllPoints()
			slot.Frame:SetPoint("CENTER", self.Frame, "CENTER", x, y)
			slot.Frame:SetSize(self.Size, self.Size)
			slot.Frame:Show()
		end
	else
		local totalWidth = usedCount * self.Size + (usedCount - 1) * self.Spacing
		self.Frame:SetSize(totalWidth, self.Size)
		self.Frame:SetAlpha(1)

		for displayIndex = 1, usedCount do
			local slot = self.Slots[layoutScratch[displayIndex]]
			local effIndex = self.InvertLayout and (usedCount - displayIndex + 1) or displayIndex
			local x = (effIndex - 1) * (self.Size + self.Spacing) - (totalWidth / 2) + (self.Size / 2)
			slot.Frame:ClearAllPoints()
			slot.Frame:SetPoint("CENTER", self.Frame, "CENTER", x, 0)
			slot.Frame:SetSize(self.Size, self.Size)
			slot.Frame:Show()
		end
	end

	for i = 1, self.Count do
		local slot = self.Slots[i]
		if slot and not slot.IsUsed then slot.Frame:Hide() end
	end
	for i = self.Count + 1, #self.Slots do
		local slot = self.Slots[i]
		if slot then slot.IsUsed = false; slot.Frame:Hide() end
	end
	ScheduleMasqueReSkin(self.MasqueGroup)
end

function M:SetSpacing(newSpacing)
	newSpacing = tonumber(newSpacing)
	if not newSpacing or newSpacing < 0 or self.Spacing == newSpacing then return end
	self.Spacing = newSpacing; self.LayoutSignature = nil; self:Layout()
end

function M:SetRows(numRows, alignment, invertLayout)
	numRows = (numRows and numRows > 1) and math.floor(numRows) or nil
	alignment = alignment or "CENTER"
	local overflowAlignment
	if alignment == "LEFT" then overflowAlignment = "RIGHT"
	elseif alignment == "RIGHT" then overflowAlignment = "LEFT"
	else overflowAlignment = alignment end
	invertLayout = invertLayout and true or false
	if self.NumRows == numRows and self.RowAlignment == alignment and self.OverflowRowAlignment == overflowAlignment and self.InvertLayout == invertLayout then return end
	self.NumRows = numRows; self.RowAlignment = alignment; self.OverflowRowAlignment = overflowAlignment; self.InvertLayout = invertLayout
	self.LayoutSignature = nil; self:Layout()
end

function M:SetIconSize(newSize)
	newSize = tonumber(newSize)
	if not newSize or newSize <= 0 or self.Size == newSize then return end
	self.Size = newSize
	for i = 1, self.Count do
		local slot = self.Slots[i]
		if slot and slot.Frame then
			slot.Frame:SetSize(self.Size, self.Size)
			local layer = slot.Container
			if layer and layer.Cooldown then
				layer.Cooldown.DesiredIconSize = self.Size
				local fontScale = layer.Cooldown.FontScale or 1.0
				fontUtil:UpdateCooldownFontSize(layer.Cooldown, self.Size, nil, fontScale)
			end
			if slot.ExtraLayers then
				for _, el in ipairs(slot.ExtraLayers) do
					if el and el.Frame then el.Frame:SetSize(self.Size, self.Size) end
					if el and el.Cooldown then
						el.Cooldown.DesiredIconSize = self.Size
						local fontScale = el.Cooldown.FontScale or 1.0
						fontUtil:UpdateCooldownFontSize(el.Cooldown, self.Size, nil, fontScale)
					end
				end
			end
		end
	end
	ScheduleMasqueReSkin(self.MasqueGroup)
	self:Layout()
end

function M:SetCount(newCount)
	newCount = math.max(0, newCount or 0)
	if newCount < self.Count then
		for i = newCount + 1, #self.Slots do
			local slot = self.Slots[i]
			if slot then slot.IsUsed = false; self:ClearSlot(i); slot.Frame:Hide() end
		end
	end
	self.Count = newCount
	for i = #self.Slots + 1, newCount do
		local slotFrame = CreateFrame(self.MasqueGroup and "Button" or "Frame", NextFrameName("Slot"), self.Frame)
		slotFrame:SetSize(self.Size, self.Size)
		slotFrame:EnableMouse(false)
		self.Slots[i] = { Frame = slotFrame, Container = nil, ExtraLayers = {}, IsUsed = false }
	end
	self:Layout()
end

function M:SetSlot(slotIndex, options)
	if slotIndex < 1 or slotIndex > self.Count then return end
	if not options.Texture then return end
	local slot = self.Slots[slotIndex]
	if not slot then return end

	if not slot.IsUsed then slot.IsUsed = true; self:Layout() end

	slot.SpellId = options.SpellId
	if options.SpellId and not slot.MouseEnabled then
		slot.MouseEnabled = true
		slot.Frame:EnableMouse(true)
		slot.Frame:SetScript("OnEnter", function(self)
			if slot.SpellId then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetSpellByID(slot.SpellId); GameTooltip:Show() end
		end)
		slot.Frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end

	local layerIndex = options.Layer or 1
	local layer = (layerIndex <= 1) and EnsureContainer(slot, self.Size, self.MasqueGroup, self.NoBorder) or EnsureExtraLayer(slot, layerIndex, self.Size)

	local db = GetDb()
	layer.Icon:SetTexture(options.Texture)
	layer.Cooldown:SetReverse(options.ReverseCooldown)
	if options.DurationObject then
		layer.Cooldown:SetCooldownFromDurationObject(options.DurationObject)
		layer.Cooldown:SetDrawSwipe(not (db and db.DisableSwipe))
	else
		layer.Cooldown:Clear()
		layer.Cooldown:SetDrawSwipe(false)
	end

	ApplyAlpha(layer.Frame, options.Alpha)

	if options.Color and layer.Border then
		layer.Border:SetVertexColor(options.Color.r or 1, options.Color.g or 1, options.Color.b or 1, options.Color.a or 1)
		layer.Border:Show()
	elseif layer.Border then
		layer.Border:Hide()
	end

	if options.FontScale then
		layer.Cooldown.FontScale = options.FontScale
		fontUtil:UpdateCooldownFontSize(layer.Cooldown, self.Size, nil, options.FontScale)
	end

	UpdateGlow(layer.Frame, options)
end

function M:ClearSlot(slotIndex)
	if slotIndex < 1 or slotIndex > #self.Slots then return end
	local slot = self.Slots[slotIndex]
	if not slot or not slot.Container then return end

	slot.SpellId = nil
	ClearLayerData(slot.Container, slot.Container.Frame)

	if slot.ExtraLayers then
		for _, el in ipairs(slot.ExtraLayers) do
			if el then ClearLayerData(el, el.Frame) end
		end
	end
end

function M:SetSlotUnused(slotIndex)
	if slotIndex < 1 or slotIndex > self.Count then return end
	local slot = self.Slots[slotIndex]
	if not slot then return end

	if slot.IsUsed then
		slot.IsUsed = false
		self:ClearSlot(slotIndex)
		self:Layout()
	end
end

function M:GetUsedSlotCount()
	local count = 0
	for i = 1, self.Count do
		if self.Slots[i] and self.Slots[i].IsUsed then count = count + 1 end
	end
	return count
end

function M:ResetAllSlots()
	local needsLayout = false
	for i = 1, self.Count do
		local slot = self.Slots[i]
		if slot and slot.IsUsed then
			slot.IsUsed = false
			self:ClearSlot(i)
			needsLayout = true
		end
	end
	if needsLayout then self:Layout() end
end
