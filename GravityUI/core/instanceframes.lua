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
    local db = ns.db.profile.styling.instanceFrames
    if db and db.disableThemeColorBorder then
        return unpack(db.customBorderColor)
    end
    return ns.GetAccentColor()
end

local function GetThemeBg()
    local db = ns.db.profile.styling.instanceFrames
    if db and db.disableThemeColorBackground then
        return unpack(db.customBackgroundColor)
    end
    return ns.GetThemeBgColor()
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
    if not f then return end

    local sr, sg, sb, sa = GetAccent()
    
    StripTextures(f)
    if f.NineSlice then f.NineSlice:SetAlpha(0) end
    if f.PortraitContainer then f.PortraitContainer:Hide() end
    
    -- Use raw textures instead of BackdropTemplate to avoid mouse interception.
    -- BackdropTemplate frames can block clicks on role buttons, dropdowns, etc.
    if not f._guiBg then
        local bgr, bgg, bgb, bga = GetThemeBg()
        
        -- Background fill
        f._guiBg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
        f._guiBg:SetPoint("TOPLEFT", 1, -1)
        f._guiBg:SetPoint("BOTTOMRIGHT", -1, 1)
        f._guiBg:SetColorTexture(bgr, bgg, bgb, bga)
        
        -- Border edges (1px)
        f._guiBorderTop = f:CreateTexture(nil, "BORDER")
        f._guiBorderTop:SetPoint("TOPLEFT"); f._guiBorderTop:SetPoint("TOPRIGHT")
        f._guiBorderTop:SetHeight(1)
        f._guiBorderTop:SetColorTexture(sr, sg, sb, sa)
        
        f._guiBorderBottom = f:CreateTexture(nil, "BORDER")
        f._guiBorderBottom:SetPoint("BOTTOMLEFT"); f._guiBorderBottom:SetPoint("BOTTOMRIGHT")
        f._guiBorderBottom:SetHeight(1)
        f._guiBorderBottom:SetColorTexture(sr, sg, sb, sa)
        
        f._guiBorderLeft = f:CreateTexture(nil, "BORDER")
        f._guiBorderLeft:SetPoint("TOPLEFT"); f._guiBorderLeft:SetPoint("BOTTOMLEFT")
        f._guiBorderLeft:SetWidth(1)
        f._guiBorderLeft:SetColorTexture(sr, sg, sb, sa)
        
        f._guiBorderRight = f:CreateTexture(nil, "BORDER")
        f._guiBorderRight:SetPoint("TOPRIGHT"); f._guiBorderRight:SetPoint("BOTTOMRIGHT")
        f._guiBorderRight:SetWidth(1)
        f._guiBorderRight:SetColorTexture(sr, sg, sb, sa)
    else
        local bgr, bgg, bgb, bga = GetThemeBg()
        f._guiBg:SetColorTexture(bgr, bgg, bgb, bga)
        f._guiBorderTop:SetColorTexture(sr, sg, sb, sa)
        f._guiBorderBottom:SetColorTexture(sr, sg, sb, sa)
        f._guiBorderLeft:SetColorTexture(sr, sg, sb, sa)
        f._guiBorderRight:SetColorTexture(sr, sg, sb, sa)
    end

    -- Tabs
    for i = 1, 4 do
        local tab = _G["PVEFrameTab"..i]
        if tab then
            StripTextures(tab)
            if not tab._guiBg then
                local bgr, bgg, bgb, bga = GetThemeBg()
                tab._guiBg = tab:CreateTexture(nil, "BACKGROUND", nil, -8)
                tab._guiBg:SetPoint("TOPLEFT", 3, -3)
                tab._guiBg:SetPoint("BOTTOMRIGHT", -3, 0)
                tab._guiBg:SetColorTexture(bgr, bgg, bgb, bga)
                
                tab._guiBorder = tab:CreateTexture(nil, "BORDER")
                tab._guiBorder:SetPoint("TOPLEFT", 3, -3)
                tab._guiBorder:SetPoint("BOTTOMRIGHT", -3, 0)
                tab._guiBorder:SetColorTexture(sr, sg, sb, 0) -- transparent fill
                -- Simple bottom accent line
                tab._guiBorderLine = tab:CreateTexture(nil, "BORDER")
                tab._guiBorderLine:SetPoint("BOTTOMLEFT", tab._guiBg, "BOTTOMLEFT")
                tab._guiBorderLine:SetPoint("BOTTOMRIGHT", tab._guiBg, "BOTTOMRIGHT")
                tab._guiBorderLine:SetHeight(1)
                tab._guiBorderLine:SetColorTexture(sr, sg, sb, sa)
            else
                local bgr, bgg, bgb, bga = GetThemeBg()
                tab._guiBg:SetColorTexture(bgr, bgg, bgb, bga)
                tab._guiBorderLine:SetColorTexture(sr, sg, sb, sa)
            end
            
            -- Fix Text Color
            if tab.GetFontString then
                local fs = tab:GetFontString()
                if fs then
                    fs:SetTextColor(1, 1, 1, 1)
                end
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
