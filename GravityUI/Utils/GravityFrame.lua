--[[-----------------------------------------------------------------------------
GravityFrame Container
-------------------------------------------------------------------------------]]
local Type, Version = "GravityFrame", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, type = pairs, assert, type
local wipe = table.wipe

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Button_OnClick(frame)
	PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
	frame.obj:Hide()
end

local function Frame_OnShow(frame)
	frame.obj:Fire("OnShow")
end

local function Frame_OnClose(frame)
	frame.obj:Fire("OnClose")
end

local function Frame_OnMouseDown(frame)
	AceGUI:ClearFocus()
end

local function Title_OnMouseDown(frame)
	frame:GetParent():StartMoving()
	AceGUI:ClearFocus()
end

local function MoverSizer_OnMouseUp(mover)
	local frame = mover:GetParent()
	frame:StopMovingOrSizing()
	local self = frame.obj
	local status = self.status or self.localstatus
	status.width = frame:GetWidth()
	status.height = frame:GetHeight()
	status.top = frame:GetTop()
	status.left = frame:GetLeft()
end

local function SizerSE_OnMouseDown(frame)
	frame:GetParent():StartSizing("BOTTOMRIGHT")
	AceGUI:ClearFocus()
end

local function SizerS_OnMouseDown(frame)
	frame:GetParent():StartSizing("BOTTOM")
	AceGUI:ClearFocus()
end

local function SizerE_OnMouseDown(frame)
	frame:GetParent():StartSizing("RIGHT")
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self.frame:SetParent(UIParent)
		self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		self.frame:SetFrameLevel(100)
		self:SetTitle()
		self:ApplyStatus()
		self:Show()
		self:EnableResize(true)
	end,

	["OnRelease"] = function(self)
		self.status = nil
		wipe(self.localstatus)
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.content
		local contentwidth = width - 34
		if contentwidth < 0 then contentwidth = 0 end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		local contentheight = height - 57
		if contentheight < 0 then contentheight = 0 end
		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	["SetTitle"] = function(self, title)
		self.titletext:SetText(title)
		
	end,

	["Hide"] = function(self) self.frame:Hide() end,
	["Show"] = function(self) self.frame:Show() end,

	["EnableResize"] = function(self, state)
		local func = state and "Show" or "Hide"
		self.sizer_se[func](self.sizer_se)
		self.sizer_s[func](self.sizer_s)
		self.sizer_e[func](self.sizer_e)
	end,

	["SetStatusTable"] = function(self, status)
		assert(type(status) == "table")
		self.status = status
		self:ApplyStatus()
	end,

	["ApplyStatus"] = function(self)
		local status = self.status or self.localstatus
		local frame = self.frame
		self:SetWidth(status.width or 700)
		self:SetHeight(status.height or 500)
		frame:ClearAllPoints()
		if status.top and status.left then
			frame:SetPoint("TOP", UIParent, "BOTTOM", 0, status.top)
			frame:SetPoint("LEFT", UIParent, "LEFT", status.left, 0)
		else
			frame:SetPoint("CENTER")
		end
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local FrameBackdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Addons\\CronixUIMedia\\Media\\border\\SeerahScalloped.tga]",
    tile = true, tileSize = 32, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}
local TitleBackdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Addons\\CronixUIMedia\\Media\\border\\SeerahScalloped.tga]",
    tile = true, tileSize = 32, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(false)
	frame:SetToplevel(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(100)
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetBackdropBorderColor(0.11764705882353, 0.56470588235294, 1)
    frame:SetSize(800, 400)

	

	frame:SetScript("OnShow", Frame_OnShow)
	frame:SetScript("OnHide", Frame_OnClose)
	frame:SetScript("OnMouseDown", Frame_OnMouseDown)

	-- ❌ Close Button (Top-Right)
	local closebutton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closebutton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
	closebutton:SetScript("OnClick", Button_OnClick)
	closebutton:SetNormalTexture("Interface\\AddOns\\CronixUIMedia\\Media\\buttons\\close.tga")
	closebutton:SetPushedTexture("Interface\\AddOns\\CronixUIMedia\\Media\\buttons\\close.tga")
	closebutton:SetHighlightTexture("Interface\\AddOns\\CronixUIMedia\\Media\\buttons\\close.tga")
	closebutton:SetDisabledTexture("Interface\\AddOns\\CronixUIMedia\\Media\\buttons\\close.tga")

	-- Title Area
	

	local title = CreateFrame("Frame", nil, frame,"BackdropTemplate")
    title:EnableMouse(true)
    title:SetScript("OnMouseDown", Title_OnMouseDown)
    title:SetScript("OnMouseUp", MoverSizer_OnMouseUp)
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
	title:SetToplevel(true)
	title:SetFrameStrata("FULLSCREEN_DIALOG")
	title:SetFrameLevel(110)
	title:SetBackdrop(TitleBackdrop)
	title:SetBackdropColor(0, 0, 0, 1)
	title:SetBackdropBorderColor(0, 0, 0, 1)
    title:SetHeight(26)

	local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titletext:SetPoint("TOPLEFT", title, "TOPLEFT", 0, 0)
	titletext:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", 0, 0)
	titletext:SetJustifyV("MIDDLE")
	titletext:SetJustifyH("CENTER")
	titletext:SetTextColor(1,1,1,1)
	titletext:SetFont("Interface\\Addons\\CronixUIMedia\\Media\\font\\Cronix.ttf", 20, "OUTLINE")

	-- Resizers
	local sizer_se = CreateFrame("Frame", nil, frame)
	sizer_se:SetPoint("BOTTOMRIGHT")
	sizer_se:SetSize(25, 25)
	sizer_se:EnableMouse(true)
	sizer_se:SetScript("OnMouseDown", SizerSE_OnMouseDown)
	sizer_se:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	local sizer_s = CreateFrame("Frame", nil, frame)
	sizer_s:SetPoint("BOTTOMRIGHT", -25, 0)
	sizer_s:SetPoint("BOTTOMLEFT")
	sizer_s:SetHeight(25)
	sizer_s:EnableMouse(true)
	sizer_s:SetScript("OnMouseDown", SizerS_OnMouseDown)
	sizer_s:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	local sizer_e = CreateFrame("Frame", nil, frame)
	sizer_e:SetPoint("BOTTOMRIGHT", 0, 25)
	sizer_e:SetPoint("TOPRIGHT")
	sizer_e:SetWidth(25)
	sizer_e:EnableMouse(true)
	sizer_e:SetScript("OnMouseDown", SizerE_OnMouseDown)
	sizer_e:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	-- Content Area
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 17, -27)
	content:SetPoint("BOTTOMRIGHT", -17, 17)

	-- Widget Object
	local widget = {
		localstatus = {},
		type = Type,

		-- Main frame parts
		frame = frame,
		content = content,
		closebutton = closebutton,
		title = title,
		titletext = titletext,
		sizer_se = sizer_se,
		sizer_s = sizer_s,
		sizer_e = sizer_e,
	}

	for method, func in pairs(methods) do
		widget[method] = func
	end

	closebutton.obj = widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
