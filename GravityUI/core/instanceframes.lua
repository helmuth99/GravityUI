local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = ns.Colors

-- Module
ns.InstanceFrames = {}
local InstanceFrames = ns.InstanceFrames

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------
local function GetAccent()
    return ns.GetAccentColor()
end

local function GetFont()
    local path, outline = ns.GetFont()
    return path, outline
end

local function StripTextures(frame)
    if not frame then return end
    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region:IsObjectType("Texture") then region:SetAlpha(0) end
    end
end

-------------------------------------------------------------------------------
-- SKINNING FUNCTIONS
-------------------------------------------------------------------------------

local function SkinPVEFrame()
    local f = PVEFrame
    if not f or f.guiSkinned then return end

    local sr, sg, sb, sa = GetAccent()
    
    StripTextures(f)
    if f.NineSlice then f.NineSlice:SetAlpha(0) end
    if f.PortraitContainer then f.PortraitContainer:Hide() end
    
    if not f.guiBackdrop then
        f.guiBackdrop = CreateFrame("Frame", nil, f, "BackdropTemplate")
        f.guiBackdrop:SetAllPoints()
        f.guiBackdrop:SetFrameLevel(f:GetFrameLevel())
        f.guiBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        f.guiBackdrop:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        f.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end

    -- Tabs
    for i = 1, 4 do
        local tab = _G["PVEFrameTab"..i]
        if tab then
            StripTextures(tab)
            if not tab.guiBackdrop then
                tab.guiBackdrop = CreateFrame("Frame", nil, tab, "BackdropTemplate")
                tab.guiBackdrop:SetPoint("TOPLEFT", 3, -3)
                tab.guiBackdrop:SetPoint("BOTTOMRIGHT", -3, 0)
                tab.guiBackdrop:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                tab.guiBackdrop:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
                tab.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
            end
        end
    end

    f.guiSkinned = true
end

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

function InstanceFrames:Initialize()
    local db = ns.db.profile.styling.instanceFrames
    if not db or not db.enabled then return end

    if PVEFrame then
        SkinPVEFrame()
    else
        local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(self, event, addon)
            if addon == "Blizzard_PVEUI" then
                SkinPVEFrame()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end
