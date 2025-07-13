--[[-----------------------------------------------------------------------------
GravityInlineGroup Container
A simple invisible container with an optional title.
-------------------------------------------------------------------------------]]
local Type, Version = "GravityInlineGroup", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs
local CreateFrame = CreateFrame
local UIParent = UIParent

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(300)
		self:SetHeight(100)
		self:SetTitle("")
	end,

	["SetTitle"] = function(self, title)
		self.titletext:SetText(title)
	end,

	["LayoutFinished"] = function(self, width, height)
		if self.noAutoHeight then return end
		self:SetHeight((height or 0) + 20)
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.content
		content:SetWidth(width or 0)
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		content:SetHeight((height or 0) - 20)
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")

	local titletext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titletext:SetPoint("TOPLEFT", 0, 0)
	titletext:SetPoint("TOPRIGHT", 0, 0)
	titletext:SetJustifyH("LEFT")
	titletext:SetHeight(0)

	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 0, -20)
	content:SetPoint("BOTTOMRIGHT", 0, 0)

	local widget = {
		frame     = frame,
		content   = content,
		titletext = titletext,
		type      = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
