---------------------------------------------------------------------------
-- GravityUI Inspect Module
-- Custom inspect panel styling with equipment overlays
-- Ported from GravityUI
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
ns.Inspect = ns.Inspect or {}
local Inspect = ns.Inspect

local C = ns.Colors or {}
local GEM_SIZE = 12
local GEM_SPACING = 2

-- Track font strings for dynamic resizing
local trackedItemNameFonts = {}
local trackedILvlFonts = {}
local trackedEnchantFonts = {}

-- Gem colors for fallback
local GEM_COLORS = {
    Prismatic = {1, 1, 1, 1},
    Red = {1, 0.2, 0.2, 1},
    Blue = {0.2, 0.4, 1, 1},
    Yellow = {1, 0.9, 0, 1},
    Purple = {0.6, 0.2, 0.8, 1},
    Green = {0.2, 0.8, 0.2, 1},
    Orange = {1, 0.5, 0, 1},
    Empty = {0.5, 0.5, 0.5, 0.5},
}

-- Optimized Defaults
local DEFAULT_UPGRADE_TRACK_COLOR = {0.98, 0.60, 0.35, 1}
local DEFAULT_ENCHANT_TEXT_COLOR = {0.2, 0.8, 0.6}
local DEFAULT_NO_ENCHANT_COLOR = {0.5, 0.5, 0.5}

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
local function GetSettings()
    local db = ns.GetDB and ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.character then
        return db.uiimprovements.character
    end
    return {}
end

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local INSPECT_CONFIG = {
    FRAME_TARGET_WIDTH = 500,
    FRAME_DEFAULT_WIDTH = 338,
    CLOSE_BUTTON_EXTENDED_X = -2,
    CLOSE_BUTTON_NORMAL_X = -2,
    CLOSE_BUTTON_Y = -2,
    MAINHAND_X_OFFSET = -25,
    MAINHAND_Y_OFFSET = -42,
    OFFHAND_SPACING = 30,
    BASE_SCALE = 1.30,
}

local INSPECT_SLOT_NAMES = {
    "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot",
    "InspectBackSlot", "InspectChestSlot", "InspectShirtSlot",
    "InspectTabardSlot", "InspectWristSlot", "InspectHandsSlot",
    "InspectWaistSlot", "InspectLegsSlot", "InspectFeetSlot",
    "InspectFinger0Slot", "InspectFinger1Slot",
    "InspectTrinket0Slot", "InspectTrinket1Slot",
    "InspectMainHandSlot", "InspectSecondaryHandSlot",
}

local SLOT_INFO = {
    [1] = { name = "HeadSlot", id = 1, side = "left" },
    [2] = { name = "NeckSlot", id = 2, side = "left" },
    [3] = { name = "ShoulderSlot", id = 3, side = "left" },
    [4] = { name = "ShirtSlot", id = 4, side = "left" },
    [5] = { name = "ChestSlot", id = 5, side = "left" },
    [6] = { name = "WaistSlot", id = 6, side = "right" },
    [7] = { name = "LegsSlot", id = 7, side = "right" },
    [8] = { name = "FeetSlot", id = 8, side = "right" },
    [9] = { name = "WristSlot", id = 9, side = "left" },
    [10] = { name = "HandsSlot", id = 10, side = "right" },
    [11] = { name = "Finger0Slot", id = 11, side = "right" },
    [12] = { name = "Finger1Slot", id = 12, side = "right" },
    [13] = { name = "Trinket0Slot", id = 13, side = "right" },
    [14] = { name = "Trinket1Slot", id = 14, side = "right" },
    [15] = { name = "BackSlot", id = 15, side = "left" },
    [16] = { name = "MainHandSlot", id = 16, side = "bottom" },
    [17] = { name = "SecondaryHandSlot", id = 17, side = "bottom" },
    [19] = { name = "TabardSlot", id = 19, side = "left" },
}

---------------------------------------------------------------------------
-- State & Caching
---------------------------------------------------------------------------
local inspectPaneInitialized = false
local currentInspectGUID = nil
local inspectOverlays = {}
local inspectLayoutApplied = false

-- Performance Cache: GUID -> SlotID -> Data
-- Data = { link = link, ilvl = ilvl, enchant = text, gems = { {icon, filled}, ... } }
local inspectCache = {}

local function ClearInspectCache(guid)
    if not guid then
        inspectCache = {}
    else
        inspectCache[guid] = nil
    end
end

---------------------------------------------------------------------------
-- Helpers (Optimized)
---------------------------------------------------------------------------
local function GetGlobalFont()
    if ns.GetFont then return ns.GetFont() end
    return "Fonts\\FRIZQT__.TTF"
end

local function GetItemQualityColor(quality)
    if quality and quality >= 1 then
        return C_Item.GetItemQualityColor(quality)
    end
    return 1, 1, 1
end

-- Pre-calculate pattern
local ILVL_PATTERN
if ITEM_LEVEL then
    ILVL_PATTERN = ITEM_LEVEL:gsub("%%d", "(%%d+)")
else
    ILVL_PATTERN = "Item Level (%d+)"
end

local function GetSlotItemLevel(unit, slotId, itemLink)
    itemLink = itemLink or GetInventoryItemLink(unit, slotId)
    if not itemLink then return nil end

    local itemLevel = nil

    -- 1. Try generic API first (Fastest)
    if C_Item and C_Item.GetItemInfo then
        local _, _, _, ilvl = C_Item.GetItemInfo(itemLink)
        if ilvl then itemLevel = ilvl end
    end
    
    -- 2. Try Detailed API (Base Fallback)
    if not itemLevel then
        itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
    end

    -- 3. Parse tooltip for ACTUAL displayed ilvl (Auth Fallback - Heavy)
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local tooltipData = C_TooltipInfo.GetInventoryItem(unit, slotId)
        if tooltipData and tooltipData.lines then
            for _, line in ipairs(tooltipData.lines) do
                local text = line.leftText or ""
                local tooltipIlvl = text:match(ILVL_PATTERN)
                if tooltipIlvl then
                    local parsed = tonumber(tooltipIlvl)
                    if parsed then
                        itemLevel = parsed  -- Tooltip is authoritative
                    end
                    break
                end
            end
        end
    end

    return itemLevel
end

---------------------------------------------------------------------------
-- Background
---------------------------------------------------------------------------
-- (Duplicate function removed, merged into refined Version below)

---------------------------------------------------------------------------
-- Helper: Enchant Detection
---------------------------------------------------------------------------
-- Pre-calculate Enchant Patterns
local ENCHANTED_PREFIX = "^Enchanted:"
local ENCHANT_PREFIX = "^Enchant:"
local SCOPE_PREFIX = "^Scope:"

local function GetEnchantText(unit, slotId)
    local itemLink = GetInventoryItemLink(unit, slotId)
    if not itemLink then return nil, false end

    -- Check if slot is enchantable
    -- Only show "No Enchant" for slots that ARE enchantable but missing one
    -- Updated for parity with character.lua: Head(1), Shoulder(3), Chest(5), Legs(7), Feet(8), Finger(11/12), MainHand(16), OffHand(17)
    local enchantableSlots = { 
        [1]=true, [3]=true, [5]=true, [7]=true, [8]=true,
        [11]=true, [12]=true, [16]=true, [17]=true 
    }
    
    -- If not in the list, we don't care if it has an enchant or not for the "No Enchant" warning
    if not enchantableSlots[slotId] then
        return nil, false
    end

    -- Ignore Shields and Held In Off-hand (Frills)
    if slotId == 17 then -- INVSLOT_OFFHAND
        local itemID = GetInventoryItemID(unit, slotId)
        if itemID then
            local _, _, _, itemEquipLoc = GetItemInfoInstant(itemID)
            if itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_HOLDABLE" then
                return nil, false -- Not enchantable
            end
        end
    end

    -- Scan tooltip
    local data = C_TooltipInfo.GetInventoryItem(unit, slotId)
    if data and data.lines then
        for _, line in ipairs(data.lines) do
            -- Type 2 = Enchant (usually), but scanning text is safer
            if line.leftText then 
                local text = line.leftText
                -- Detect "Enchanted: +Stat" or just "+Stat" or "Scope"
                if text:match(ENCHANTED_PREFIX) or text:match(ENCHANT_PREFIX) or text:match(SCOPE_PREFIX) then
                     local enchant = text:gsub("Enchanted: ", ""):gsub("Enchant: ", ""):gsub("Scope: ", "")
                     -- Strip "Enchant SlotType - " prefix (e.g. "Enchant Helm - ", "Enchant Ring - ")
                     enchant = enchant:gsub("^Enchant%s+.-%s*%-%s*", "")
                     return enchant, true
                end
            end
        end
    end
    
    return nil, true
end

---------------------------------------------------------------------------
-- Main Refresh
---------------------------------------------------------------------------



local UPGRADE_TRACK_PATTERN = "Upgrade Level:%s*(.+)%s+(%d+)%s*/%s*(%d+)"
local UPGRADE_TRACK_PATTERN_ALT = ": (.+)%s+(%d+)%s*/%s*(%d+)"

local function GetUpgradeTrack(unit, slotId)
    if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then return nil, nil, nil end
    local tooltipData = C_TooltipInfo.GetInventoryItem(unit, slotId)
    if not tooltipData or not tooltipData.lines then return nil, nil, nil end
    for _, line in ipairs(tooltipData.lines) do
        local text = line.leftText or ""
        local track, current, max = text:match(UPGRADE_TRACK_PATTERN)
        if track then return track, current, max end
        track, current, max = text:match(UPGRADE_TRACK_PATTERN_ALT)
        if track then return track, current, max end
    end
    return nil, nil, nil
end

local function GetGemInfo(unit, slotId)
    local itemLink = GetInventoryItemLink(unit, slotId)
    if not itemLink then return {}, 0 end
    local gems = {}
    local totalSockets = 0

    -- Count sockets via tooltip
    local data = C_TooltipInfo.GetInventoryItem(unit, slotId)
    if data and data.lines then
        for _, line in ipairs(data.lines) do
            if line.type == 3 then totalSockets = totalSockets + 1 end
        end
    end

    -- Get filled gems
    local filled = 0
    for i = 1, 4 do
        -- Use C_Item.GetItemGemID for Retail stability
        local gemID = C_Item.GetItemGemID(itemLink, i)
        if gemID then
            filled = filled + 1
            local texture = C_Item.GetItemIconByID(gemID)
            local _, gemLink = GetItemInfo(gemID)
            table.insert(gems, { filled = true, icon = texture, link = gemLink or ("item:"..gemID) })
        end
    end

    if totalSockets < filled then totalSockets = filled end
    for i = 1, totalSockets - filled do
        table.insert(gems, { filled = false, type = "Empty" })
    end
    return gems, totalSockets
end

---------------------------------------------------------------------------
-- Skinning Logic
---------------------------------------------------------------------------
local function BlockInspectIconBorder(iconBorder)
    if not iconBorder or iconBorder._guiBlocked then return end
    iconBorder._guiBlocked = true
    iconBorder:SetAlpha(0)
    if iconBorder.SetTexture then iconBorder:SetTexture(nil) end
    if iconBorder.SetAtlas then
        hooksecurefunc(iconBorder, "SetAtlas", function(self)
            if self.SetTexture then self:SetTexture(nil) end
            if self.SetAlpha then self:SetAlpha(0) end
        end)
    end
end

local function SkinInspectEquipmentSlot(slot)
    if not slot or slot._guiSkinned then return end
    slot._guiSkinned = true

    local normalTex = slot:GetNormalTexture()
    if normalTex then normalTex:SetAlpha(0) end
    if slot.BottomRightSlotTexture then slot.BottomRightSlotTexture:Hide() end

    for i = 1, select("#", slot:GetRegions()) do
        local region = select(i, slot:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local isIcon = region == slot.icon or region == slot.Icon
            if not isIcon then region:SetAlpha(0) end
        end
    end

    if slot.IconBorder then BlockInspectIconBorder(slot.IconBorder) end

    local iconTex = slot.icon or slot.Icon
    if iconTex and iconTex.SetTexCoord then
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    if not slot._guiBorderFrame then
        slot._guiBorderFrame = CreateFrame("Frame", nil, slot, "BackdropTemplate")
        slot._guiBorderFrame:SetFrameLevel(slot:GetFrameLevel() + 10)
        slot._guiBorderFrame:SetAllPoints(slot)
        slot._guiBorderFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    end
end

local function UpdateInspectSlotBorder(slot, unit)
    if not slot or not slot._guiBorderFrame then return end
    local slotID = slot:GetID()
    unit = unit or "target"
    local quality = GetInventoryItemQuality(unit, slotID)
    if quality and quality >= 1 then
        local r, g, b = GetItemQualityColor(quality)
        slot._guiBorderFrame:SetBackdropBorderColor(r, g, b, 1)
        slot._guiBorderFrame:Show()
    else
        slot._guiBorderFrame:Hide()
    end
end

local function UpdateAllInspectSlotBorders(unit)
    for _, slotName in ipairs(INSPECT_SLOT_NAMES) do
        local slot = _G[slotName]
        if slot then
            UpdateInspectSlotBorder(slot, unit)
        end
    end
end

---------------------------------------------------------------------------
-- Overlays
---------------------------------------------------------------------------
local function CreateSlotOverlay(slotFrame, slotInfo, unit)
    if not slotFrame then return nil end
    local settings = GetSettings()
    local scale = 1.0

    local overlay = CreateFrame("Frame", nil, slotFrame)
    overlay:SetAllPoints(slotFrame)
    overlay:SetFrameLevel(slotFrame:GetFrameLevel() + 10)
    overlay.unit = unit or "target"
    overlay.slotInfo = slotInfo

    local slotFont = GetGlobalFont()
    local slotTextSize = settings.slotTextSize or 12
    local FONT_FLAGS = "OUTLINE"
    local TEXT_WIDTH = 140

    -- Name
    overlay.itemName = overlay:CreateFontString(nil, "OVERLAY")
    overlay.itemName:SetFont(slotFont, slotTextSize, FONT_FLAGS)
    overlay.itemName:SetWidth(TEXT_WIDTH)
    overlay.itemName:SetWordWrap(false)
    table.insert(trackedItemNameFonts, overlay.itemName)

    -- ILvl
    overlay.itemLevel = overlay:CreateFontString(nil, "OVERLAY")
    overlay.itemLevel:SetFont(slotFont, slotTextSize, FONT_FLAGS)
    overlay.itemLevel:SetWordWrap(false)
    table.insert(trackedILvlFonts, overlay.itemLevel)

    -- Enchant
    overlay.enchant = overlay:CreateFontString(nil, "OVERLAY")
    overlay.enchant:SetFont(slotFont, slotTextSize, FONT_FLAGS)
    overlay.enchant:SetWidth(TEXT_WIDTH)
    overlay.enchant:SetWordWrap(false)
    table.insert(trackedEnchantFonts, overlay.enchant)

    -- Gems
    overlay.gems = {}
    for i=1,4 do
        local gem = CreateFrame("Button", nil, overlay)
        gem:SetSize(GEM_SIZE, GEM_SIZE)
        
        gem.icon = gem:CreateTexture(nil, "ARTWORK")
        gem.icon:SetAllPoints()
        gem.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        gem:SetScript("OnEnter", function(self)
            if self.link then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.link)
                GameTooltip:Show()
            end
        end)
        gem:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        table.insert(overlay.gems, gem)
    end

    -- === ITEM BAR BACKDROP ===
    -- Subtle soft-fading bar for text readability (gradient via WHITE8X8 + SetGradient)
    overlay.backdropBar = overlay:CreateTexture(nil, "BACKGROUND", nil, 5)
    overlay.backdropBar:SetTexture("Interface\\Buttons\\WHITE8X8")
    overlay.backdropBar:SetHeight(40)
    overlay.backdropBar:SetWidth(160)
    overlay.backdropBar:Hide()

    -- Positioning
    if slotInfo.side == "left" then
        overlay.itemName:SetPoint("TOPLEFT", overlay, "TOPRIGHT", 4, 2)
        overlay.itemName:SetJustifyH("LEFT")
        overlay.itemLevel:SetPoint("TOPLEFT", overlay.itemName, "BOTTOMLEFT", 0, -1)
        overlay.itemLevel:SetJustifyH("LEFT")
        overlay.enchant:SetPoint("TOPLEFT", overlay.itemLevel, "BOTTOMLEFT", 0, -1)
        overlay.enchant:SetJustifyH("LEFT")
        for i, gem in ipairs(overlay.gems) do
            gem:SetPoint("TOPRIGHT", overlay, "TOPLEFT", -2, -(i-1)*(GEM_SIZE+GEM_SPACING))
        end
        -- Anchor backdropBar
        overlay.backdropBar:SetPoint("LEFT", overlay, "LEFT", 40, 0)
        overlay.backdropBar:SetTexCoord(0, 1, 0, 1)
    elseif slotInfo.side == "right" then
        overlay.itemName:SetPoint("TOPRIGHT", overlay, "TOPLEFT", -4, 2)
        overlay.itemName:SetJustifyH("RIGHT")
        overlay.itemLevel:SetPoint("TOPRIGHT", overlay.itemName, "BOTTOMRIGHT", 0, -1)
        overlay.itemLevel:SetJustifyH("RIGHT")
        overlay.enchant:SetPoint("TOPRIGHT", overlay.itemLevel, "BOTTOMRIGHT", 0, -1)
        overlay.enchant:SetJustifyH("RIGHT")
        for i, gem in ipairs(overlay.gems) do
            gem:SetPoint("TOPLEFT", overlay, "TOPRIGHT", 2, -(i-1)*(GEM_SIZE+GEM_SPACING))
        end
        -- Anchor backdropBar
        overlay.backdropBar:SetPoint("RIGHT", overlay, "RIGHT", -40, 0)
        overlay.backdropBar:SetTexCoord(1, 0, 0, 1)
    elseif slotInfo.id == 16 then -- Mainhand
        overlay.itemName:SetPoint("TOPRIGHT", overlay, "TOPLEFT", -4, 2)
        overlay.itemName:SetJustifyH("RIGHT")
        overlay.itemLevel:SetPoint("TOPRIGHT", overlay.itemName, "BOTTOMRIGHT", 0, -1)
        overlay.itemLevel:SetJustifyH("RIGHT")
        overlay.enchant:SetPoint("TOPRIGHT", overlay.itemLevel, "BOTTOMRIGHT", 0, -1)
        overlay.enchant:SetJustifyH("RIGHT")
        for i, gem in ipairs(overlay.gems) do
            gem:SetPoint("TOPLEFT", overlay, "TOPRIGHT", 2, -(i-1)*(GEM_SIZE+GEM_SPACING))
        end
        -- Anchor backdropBar
        overlay.backdropBar:SetPoint("RIGHT", overlay, "RIGHT", -40, 0)
        overlay.backdropBar:SetTexCoord(1, 0, 0, 1)
    else -- Offhand
        overlay.itemName:SetPoint("TOPLEFT", overlay, "TOPRIGHT", 4, 2)
        overlay.itemName:SetJustifyH("LEFT")
        overlay.itemLevel:SetPoint("TOPLEFT", overlay.itemName, "BOTTOMLEFT", 0, -1)
        overlay.itemLevel:SetJustifyH("LEFT")
        overlay.enchant:SetPoint("TOPLEFT", overlay.itemLevel, "BOTTOMLEFT", 0, -1)
        overlay.enchant:SetJustifyH("LEFT")
        for i, gem in ipairs(overlay.gems) do
            gem:SetPoint("TOPRIGHT", overlay, "TOPLEFT", -2, -(i-1)*(GEM_SIZE+GEM_SPACING))
        end
        -- Anchor backdropBar
        overlay.backdropBar:SetPoint("LEFT", overlay, "LEFT", 40, 0)
        overlay.backdropBar:SetTexCoord(0, 1, 0, 1)
    end

    return overlay
end

local function UpdateSlotOverlay(overlay, unit, cachedData)
    if not overlay or not overlay.slotInfo then return end
    local settings = GetSettings()
    
    local showName = settings.showInspectItemName ~= false
    local showLevel = settings.showInspectItemLevel ~= false
    local showEnchant = settings.showInspectEnchants ~= false
    local showGem = settings.showInspectGems ~= false
    
    if not cachedData then 
        overlay:Hide()
        return 
    end
    overlay:Show()

    local itemName = cachedData.name
    local r, g, b = GetItemQualityColor(cachedData.quality or 1)

    -- Name
    if showName and itemName then
        overlay.itemName:SetText(itemName)
        overlay.itemName:SetTextColor(r, g, b, 1)
        overlay.itemName:Show()
    else
        overlay.itemName:Hide()
    end

    -- ILvl
    if showLevel and cachedData.ilvl then
        local text = cachedData.ilvl
        if cachedData.track then
             local trackColor = settings.upgradeTrackColor or DEFAULT_UPGRADE_TRACK_COLOR
             local hex = string.format("%02x%02x%02x", trackColor[1]*255, trackColor[2]*255, trackColor[3]*255)
             local trackStr = string.format("|cff%s(%s %s/%s)|r", hex, cachedData.track, cachedData.curTrack, cachedData.maxTrack)
             if overlay.slotInfo.side == "right" or overlay.slotInfo.id == 16 then
                  text = trackStr .. " " .. cachedData.ilvl
             else
                  text = cachedData.ilvl .. " " .. trackStr
             end
        end
        overlay.itemLevel:SetText(text)
        overlay.itemLevel:Show()
    else
        overlay.itemLevel:Hide()
    end

    -- Enchant
    if showEnchant and (cachedData.enchant or cachedData.enchantable) then
        local color
        if cachedData.enchant then
             color = settings.inspectEnchantTextColor or settings.enchantTextColor or DEFAULT_ENCHANT_TEXT_COLOR
             if settings.inspectEnchantClassColor or settings.enchantClassColor then
                  local _, class = UnitClass(unit)
                  local c = RAID_CLASS_COLORS[class]
                  if c then color = {c.r, c.g, c.b} end
             end
             overlay.enchant:SetText(cachedData.enchant)
        else
             color = settings.inspectNoEnchantTextColor or settings.noEnchantTextColor or DEFAULT_NO_ENCHANT_COLOR
             overlay.enchant:SetText("No Enchant")
        end
        overlay.enchant:SetTextColor(color[1], color[2], color[3], 1)
        overlay.enchant:Show()
    else
        overlay.enchant:Hide()
    end

    -- Gems
    if showGem and cachedData.gems then
        for i, gemBtn in ipairs(overlay.gems) do
            local gemInfo = cachedData.gems[i]
            if gemInfo then
                gemBtn:Show()
                if gemInfo.filled then
                    gemBtn.icon:SetTexture(gemInfo.icon)
                    gemBtn.icon:SetDesaturated(false)
                    gemBtn.icon:SetVertexColor(1, 1, 1, 1)
                    gemBtn.link = gemInfo.link
                else
                    gemBtn.icon:SetTexture("Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
                    gemBtn.icon:SetDesaturated(true)
                    gemBtn.icon:SetVertexColor(0.6, 0.6, 0.6, 1)
                    gemBtn.link = nil
                end
            else
                gemBtn:Hide()
                gemBtn.link = nil
            end
        end
    else
        for _, gemBtn in ipairs(overlay.gems) do 
            gemBtn:Hide() 
            gemBtn.link = nil
        end
    end

    -- Update Item Bar Backdrop
    if overlay.backdropBar then
        if settings.showBackdrops ~= false and cachedData.link then
            local r, g, b = 0, 0, 0
            local alpha = 0.4

            if settings.backdropFixedColor and settings.backdropColor then
                local c = settings.backdropColor
                r, g, b, alpha = c[1], c[2], c[3], c[4] or 0.4
            else
                local quality = cachedData.quality or 1
                -- If quality >= uncommon (2), use a more distinct quality tint
                if quality >= 2 then
                    local qr, qg, qb = C_Item.GetItemQualityColor(quality)
                    r, g, b = qr * 0.4, qg * 0.4, qb * 0.4
                    alpha = 0.7
                end
            end

            -- Apply gradient: fade from solid color to transparent
            -- Left column: text is on the RIGHT → fade LEFT (opaque) → RIGHT (transparent)
            -- Right column / Mainhand: text is on the LEFT → fade RIGHT (opaque) → LEFT (transparent)
            local side = overlay.slotInfo and overlay.slotInfo.side
            local slotId = overlay.slotInfo and overlay.slotInfo.id
            local solidColor = CreateColor(r, g, b, alpha)
            local clearColor  = CreateColor(r, g, b, 0)
            if side == "left" or slotId == 17 then -- 17 = INVSLOT_OFFHAND
                overlay.backdropBar:SetGradient("HORIZONTAL", solidColor, clearColor)
            else
                overlay.backdropBar:SetGradient("HORIZONTAL", clearColor, solidColor)
            end

            overlay.backdropBar:Show()
        else
            overlay.backdropBar:Hide()
        end
    end
end

local function InitializeInspectOverlays()
    if inspectPaneInitialized then return end
    for slotID, slotInfo in pairs(SLOT_INFO) do
         local slotName = "Inspect" .. slotInfo.name
         local slotFrame = _G[slotName]
         if slotFrame then
             inspectOverlays[slotID] = CreateSlotOverlay(slotFrame, slotInfo, "target")
         end
    end
    inspectPaneInitialized = true
end

---------------------------------------------------------------------------
-- Header / Title
---------------------------------------------------------------------------
local function CalculateInspectAverageILvl(guid)
    local total = 0
    local count = 0
    local cache = inspectCache[guid]
    if not cache then return 0 end

    for id, _ in pairs(SLOT_INFO) do
        if id ~= 4 and id ~= 19 then
            local data = cache[id]
            local ilvl = data and data.ilvl
            if ilvl and ilvl > 0 then
                total = total + ilvl
                count = count + 1
            end
        end
    end
    -- 2H Weapon check
    local mainData = cache[16]
    local offData = cache[17]
    if mainData and not offData then
        local ilvl = mainData.ilvl
        if ilvl then
             total = total + ilvl
             count = count + 1
        end
    end
    if count > 0 then return total / count end
    return 0
end

local function UpdateInspectILvlDisplay()
    if not InspectFrame or not InspectFrame._guiILvlDisplay then return end
    local unit = InspectFrame.unit or "target"
    local guid = UnitGUID(unit)
    if not guid then return end

    local name = UnitName(unit) or "Unknown"
    local level = UnitLevel(unit)
    local _, class = UnitClass(unit)
    local specID = GetInspectSpecialization(unit)
    local specName = ""
    if specID and specID ~= 0 then
        specName = select(2, GetSpecializationInfoByID(specID)) or ""
    end
    
    -- Forcefully update 3D model to actually match the current unit
    -- (Bypasses Blizzard bug where global inspect cache holds previous target's model)
    -- Added guard to prevent jitter by redundant loading
    if InspectModelFrame and InspectModelFrame.SetUnit then
        if InspectModelFrame._guiGUID ~= guid then
            InspectModelFrame:SetUnit(unit)
            InspectModelFrame._guiGUID = guid
        end
    end
    
    local color = RAID_CLASS_COLORS[class] or {r=1, g=1, b=1}
    
    -- Name & Title
    local pvpName = UnitPVPName(unit) or name
    if pvpName ~= name and InspectFrame._guiILvlDisplay.titleText then
        local title = pvpName:gsub(name, ""):gsub("^%s*", ""):gsub("%s*$", "")
        InspectFrame._guiILvlDisplay.text:SetText(name)
        InspectFrame._guiILvlDisplay.titleText:SetText(title)
        InspectFrame._guiILvlDisplay.titleText:Show()

        if pvpName:find("^" .. name) then
            -- Suffix (ex: "Saftpresser the Patient" or "Cronîx, Veteran" in DE locale)
            -- If title starts with punctuation (comma etc.), use 0 gap to avoid "Name , Title"
            local suffixGap = title:match("^[%p]") and 0 or 2
            InspectFrame._guiILvlDisplay.text:ClearAllPoints()
            InspectFrame._guiILvlDisplay.text:SetPoint("TOPLEFT", InspectFrame._guiILvlDisplay, "TOPLEFT", 0, 0)
            InspectFrame._guiILvlDisplay.titleText:ClearAllPoints()
            InspectFrame._guiILvlDisplay.titleText:SetPoint("LEFT", InspectFrame._guiILvlDisplay.text, "RIGHT", suffixGap, 0)
        else
            -- Prefix (ex: Firelord Saftpresser)
            InspectFrame._guiILvlDisplay.titleText:ClearAllPoints()
            InspectFrame._guiILvlDisplay.titleText:SetPoint("TOPLEFT", InspectFrame._guiILvlDisplay, "TOPLEFT", 0, 0)
            InspectFrame._guiILvlDisplay.text:ClearAllPoints()
            InspectFrame._guiILvlDisplay.text:SetPoint("LEFT", InspectFrame._guiILvlDisplay.titleText, "RIGHT", 2, 0)
        end
    else
        InspectFrame._guiILvlDisplay.text:SetText(name)
        InspectFrame._guiILvlDisplay.text:ClearAllPoints()
        InspectFrame._guiILvlDisplay.text:SetPoint("TOPLEFT", InspectFrame._guiILvlDisplay, "TOPLEFT", 0, 0)
        if InspectFrame._guiILvlDisplay.titleText then InspectFrame._guiILvlDisplay.titleText:Hide() end
    end
    InspectFrame._guiILvlDisplay.text:SetTextColor(color.r, color.g, color.b, 1)
    
    -- Ensure it is not buried under TitleContainer
    InspectFrame._guiILvlDisplay:SetFrameLevel(InspectFrame:GetFrameLevel() + 50)
    
    local classInfo = C_CreatureInfo.GetClassInfo(select(3, UnitClass(unit)))
    local className = classInfo and classInfo.className or ""
    -- Level (white) + Spec/Class (class colored) — avoid double space when spec is empty
    local levelClassStr
    if specName ~= "" then
        levelClassStr = string.format("|cffffffff%s|r %s %s", level, specName, className)
    else
        levelClassStr = string.format("|cffffffff%s|r %s", level, className)
    end
    InspectFrame._guiILvlDisplay.spec:SetText(levelClassStr)
    InspectFrame._guiILvlDisplay.spec:SetTextColor(color.r, color.g, color.b, 1)
    
    -- If spec data wasn't ready yet (specID == 0), schedule a retry to pick it up once server delivers it
    if (not specID or specID == 0) and InspectFrame:IsShown() then
        C_Timer.After(1.0, function()
            if InspectFrame and InspectFrame:IsShown() then
                UpdateInspectILvlDisplay()
            end
        end)
    end
    
    -- Always align with the left edge of the container
    InspectFrame._guiILvlDisplay.spec:ClearAllPoints()
    InspectFrame._guiILvlDisplay.spec:SetPoint("TOPLEFT", InspectFrame._guiILvlDisplay, "TOPLEFT", 0, -18)

    local ilvl = CalculateInspectAverageILvl(guid)
    if ilvl > 0 then
        -- Character panel defines GetILvlColor, we can use a local copy or just define it here if needed
        -- For Inspect, we'll implement the same quality color logic
        local function GetQualityColor(val)
            if val >= 252 then return "ffff8000" -- Orange
            elseif val >= 233 then return "ffa335ee" -- Purple
            elseif val >= 220 then return "ff0070dd" -- Blue
            elseif val >= 210 then return "ff1eff00" -- Green
            elseif val >= 200 then return "ffffffff" -- White
            else return "ff9d9d9d" -- Grey
            end
        end
        InspectFrame._guiCenterILvl.text:SetText(string.format("|c%s%.1f|r", GetQualityColor(ilvl), ilvl))
    else
        InspectFrame._guiCenterILvl.text:SetText("")
    end
end

local function SetupInspectTitleArea()
    if not InspectFrame then return end
    
    if InspectFrame.TitleContainer and InspectFrame.TitleContainer.TitleText then
        InspectFrame.TitleContainer.TitleText:Hide()
        InspectFrame.TitleContainer.TitleText:SetAlpha(0)
    end
    if InspectLevelText then 
        InspectLevelText:Hide() 
        InspectLevelText:SetAlpha(0)
    end

    if not InspectFrame._guiILvlDisplay then
        local display = CreateFrame("Frame", nil, InspectFrame)
        display:SetSize(400, 30)
        display:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 19, -10)
        display:SetFrameStrata("DIALOG")
        display:SetFrameLevel(50)
        
        local name = display:CreateFontString(nil, "OVERLAY")
        name:SetFont(GetGlobalFont(), 14, "OUTLINE")
        name:SetPoint("TOPLEFT", 0, 0)
        display.text = name

        local title = display:CreateFontString(nil, "OVERLAY")
        title:SetFont(GetGlobalFont(), 12, "OUTLINE")
        title:SetTextColor(1, 1, 1, 1)
        title:SetJustifyH("LEFT")
        display.titleText = title
        
        local spec = display:CreateFontString(nil, "OVERLAY")
        spec:SetFont(GetGlobalFont(), 11, "OUTLINE")
        spec:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
        spec:SetJustifyH("LEFT")
        display.spec = spec
        
        InspectFrame._guiILvlDisplay = display
    end

    if not InspectFrame._guiCenterILvl then
        local center = CreateFrame("Frame", nil, InspectFrame)
        center:SetSize(200, 20)
        center:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", -70, -18)  -- Shifted Down to -18 for better centering
        center:SetFrameStrata("DIALOG")
        center:SetFrameLevel(50)
        local text = center:CreateFontString(nil, "OVERLAY")
        text:SetFont(GetGlobalFont(), 18, "OUTLINE")
        text:SetPoint("RIGHT")
        center.text = text
        InspectFrame._guiCenterILvl = center
    end
end

---------------------------------------------------------------------------
-- Layout Positioning
---------------------------------------------------------------------------
local function RepositionInspectCloseButton(extended)
    if not InspectFrame or not InspectFrame.CloseButton then return end
    
    InspectFrame.CloseButton:ClearAllPoints()
    if extended then
        -- Position for wide layout
        InspectFrame.CloseButton:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", INSPECT_CONFIG.CLOSE_BUTTON_EXTENDED_X, INSPECT_CONFIG.CLOSE_BUTTON_Y)
    else
        -- Position for normal layout
        InspectFrame.CloseButton:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", INSPECT_CONFIG.CLOSE_BUTTON_NORMAL_X, INSPECT_CONFIG.CLOSE_BUTTON_Y)
    end
    InspectFrame.CloseButton:SetFrameLevel(InspectFrame:GetFrameLevel() + 20)
end

local function RepositionInspectSlots()
    if not InspectFrame then return end

    local vpad = 14
    local SLOT_SCALE = 0.90
    local TOP_OFFSET = -75
    local LEFT_X = 20
    local RIGHT_X = 493

    local allSlots = {
        InspectHeadSlot, InspectNeckSlot, InspectShoulderSlot,
        InspectBackSlot, InspectChestSlot, InspectShirtSlot,
        InspectTabardSlot, InspectWristSlot,
        InspectHandsSlot, InspectWaistSlot, InspectLegsSlot,
        InspectFeetSlot, InspectFinger0Slot, InspectFinger1Slot,
        InspectTrinket0Slot, InspectTrinket1Slot,
        InspectMainHandSlot, InspectSecondaryHandSlot,
    }

    for _, slot in ipairs(allSlots) do
        if slot then slot:SetScale(SLOT_SCALE) end
    end

    -- LEFT COLUMN
    if InspectHeadSlot then InspectHeadSlot:ClearAllPoints(); InspectHeadSlot:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", LEFT_X, TOP_OFFSET) end
    if InspectNeckSlot then InspectNeckSlot:ClearAllPoints(); InspectNeckSlot:SetPoint("TOPLEFT", InspectHeadSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectShoulderSlot then InspectShoulderSlot:ClearAllPoints(); InspectShoulderSlot:SetPoint("TOPLEFT", InspectNeckSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectBackSlot then InspectBackSlot:ClearAllPoints(); InspectBackSlot:SetPoint("TOPLEFT", InspectShoulderSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectChestSlot then InspectChestSlot:ClearAllPoints(); InspectChestSlot:SetPoint("TOPLEFT", InspectBackSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectShirtSlot then InspectShirtSlot:ClearAllPoints(); InspectShirtSlot:SetPoint("TOPLEFT", InspectChestSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectTabardSlot then InspectTabardSlot:ClearAllPoints(); InspectTabardSlot:SetPoint("TOPLEFT", InspectShirtSlot, "BOTTOMLEFT", 0, -vpad) end

    -- RIGHT COLUMN
    if InspectHandsSlot then InspectHandsSlot:ClearAllPoints(); InspectHandsSlot:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", RIGHT_X, TOP_OFFSET) end
    if InspectWaistSlot then InspectWaistSlot:ClearAllPoints(); InspectWaistSlot:SetPoint("TOPLEFT", InspectHandsSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectLegsSlot then InspectLegsSlot:ClearAllPoints(); InspectLegsSlot:SetPoint("TOPLEFT", InspectWaistSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectFeetSlot then InspectFeetSlot:ClearAllPoints(); InspectFeetSlot:SetPoint("TOPLEFT", InspectLegsSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectFinger0Slot then InspectFinger0Slot:ClearAllPoints(); InspectFinger0Slot:SetPoint("TOPLEFT", InspectFeetSlot, "BOTTOMLEFT", 0, -vpad) end
    if InspectFinger1Slot then InspectFinger1Slot:ClearAllPoints(); InspectFinger1Slot:SetPoint("TOPLEFT", InspectFinger0Slot, "BOTTOMLEFT", 0, -vpad) end
    if InspectTrinket0Slot then InspectTrinket0Slot:ClearAllPoints(); InspectTrinket0Slot:SetPoint("TOPLEFT", InspectFinger1Slot, "BOTTOMLEFT", 0, -vpad) end
    if InspectTrinket1Slot then InspectTrinket1Slot:ClearAllPoints(); InspectTrinket1Slot:SetPoint("TOPLEFT", InspectTrinket0Slot, "BOTTOMLEFT", 0, -vpad) end

    -- EXTRAS
    if InspectWristSlot and InspectTrinket1Slot and InspectHeadSlot then
        InspectWristSlot:ClearAllPoints()
        InspectWristSlot:SetPoint("TOP", InspectTrinket1Slot, "TOP", 0, 0)
        InspectWristSlot:SetPoint("LEFT", InspectHeadSlot, "LEFT", 0, 0)
    end

    if InspectMainHandSlot then
        InspectMainHandSlot:ClearAllPoints()
        InspectMainHandSlot:SetPoint("BOTTOM", InspectFrame, "BOTTOM", INSPECT_CONFIG.MAINHAND_X_OFFSET, INSPECT_CONFIG.MAINHAND_Y_OFFSET)
    end
    if InspectSecondaryHandSlot and InspectMainHandSlot then
        InspectSecondaryHandSlot:ClearAllPoints()
        InspectSecondaryHandSlot:SetPoint("LEFT", InspectMainHandSlot, "RIGHT", INSPECT_CONFIG.OFFHAND_SPACING, 0)
    end
    
    -- Position all 3 tabs at the bottom of the background (bg extends to y=-60)
    local allTabs = { InspectFrameTab1, InspectFrameTab2, InspectFrameTab3 }
    local prevTab = nil
    for _, tab in ipairs(allTabs) do
        if tab then
            tab:ClearAllPoints()
            if prevTab then
                tab:SetPoint("LEFT", prevTab, "RIGHT", 2, 0)
            else
                tab:SetPoint("BOTTOMLEFT", InspectFrame, "BOTTOMLEFT", 10, -92)
            end
            prevTab = tab
        end
    end

    -- Show InspectTalents button at bottom right
    local talentsBtn = InspectPaperDollItemsFrame and InspectPaperDollItemsFrame.InspectTalents
    if talentsBtn then
        talentsBtn:ClearAllPoints()
        talentsBtn:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT", -10, -35)
        talentsBtn:Show()
    end
end

local function PositionInspectModelScene()
    if not InspectModelFrame then return end
    -- Suppress Blizzard model control frame
    if InspectModelFrame.ControlFrame then InspectModelFrame.ControlFrame:Hide() end

    -- Anchor to slot frames so the model stands on the ground (not fixed pixels)
    InspectModelFrame:ClearAllPoints()
    if InspectHeadSlot and InspectHandsSlot then
        InspectModelFrame:SetPoint("TOPLEFT",  InspectHeadSlot,  "TOPRIGHT",  0, 0)
        InspectModelFrame:SetPoint("TOPRIGHT", InspectHandsSlot, "TOPLEFT",   0, 0)
        if InspectMainHandSlot then
            InspectModelFrame:SetPoint("BOTTOM", InspectMainHandSlot, "TOP", 0, 0)
        else
            InspectModelFrame:SetPoint("BOTTOM", InspectFrame, "BOTTOM", 0, 80)
        end
    else
        -- Fallback: improved fixed offsets that reduce floating
        InspectModelFrame:SetPoint("TOPLEFT",     InspectFrame, "TOPLEFT",     55, -80)
        InspectModelFrame:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT", -55, 55)
    end
    InspectModelFrame:SetFrameLevel(2)
    InspectModelFrame:Show()
end

---------------------------------------------------------------------------
-- Background
---------------------------------------------------------------------------
local function CreateInspectBackground()
    local settings = GetSettings()
    local customColor = settings.panelBgColor
    local opacity = (settings.panelOpacity or 80) / 100
    
    local sr, sg, sb, sa = C.border[1], C.border[2], C.border[3], 1
    local bgr, bgg, bgb, bga
    
    if customColor then
        bgr, bgg, bgb, bga = customColor[1], customColor[2], customColor[3], opacity
    else
        bgr, bgg, bgb, bga = C.bg[1], C.bg[2], C.bg[3], opacity
        local gui = ns.GUI
        if gui and gui.GetSkinColor then
            sr, sg, sb, sa = gui:GetSkinColor()
        end
        if gui and gui.GetSkinBgColor then
            local skinR, skinG, skinB = gui:GetSkinBgColor()
            bgr, bgg, bgb, bga = skinR, skinG, skinB, opacity
        end
    end

    if not InspectFrame.customBg then
        InspectFrame.customBg = CreateFrame("Frame", nil, InspectFrame, "BackdropTemplate")
        InspectFrame.customBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        InspectFrame.customBg:SetFrameStrata("BACKGROUND")
        InspectFrame.customBg:SetFrameLevel(0)
    end

    InspectFrame.customBg:ClearAllPoints()
    InspectFrame.customBg:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 0, 0)
    InspectFrame.customBg:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT", 2, -60)
    
    InspectFrame.customBg:SetBackdropColor(bgr, bgg, bgb, bga)
    InspectFrame.customBg:SetBackdropBorderColor(sr, sg, sb, sa)
    InspectFrame.customBg:Show()
    
    -- Create a hidden gravity well if needed
    if not ns.HiddenFrame then
        ns.HiddenFrame = CreateFrame("Frame")
        ns.HiddenFrame:Hide()
    end

    -- Banish Candidates (Robust List including Legacy Frames)
    local banishCandidates = {
        "InspectFramePortrait", "InspectFrameBg", "InspectFrameInset", "InspectModelFrameBorder",
        "InspectModelFrameBackgroundTopLeft", "InspectModelFrameBackgroundBotLeft",
        "InspectModelFrameBackgroundTopRight", "InspectModelFrameBackgroundBotRight",
        "InspectModelFrameBackgroundOverlay",
        "InspectFrameTitleBg", "InspectFrameTopBorder", 
        "InspectFrameBottomBorder", "InspectFrameLeftBorder", "InspectFrameRightBorder",
        -- Legacy GravityUI targets (Frames that are children, not layers)
        "InspectModelFrameBorderTopLeft", "InspectModelFrameBorderTopRight", 
        "InspectModelFrameBorderTop", "InspectModelFrameBorderLeft", 
        "InspectModelFrameBorderRight", "InspectModelFrameBorderBottomLeft", 
        "InspectModelFrameBorderBottomRight", "InspectModelFrameBorderBottom", 
        "InspectModelFrameBorderBottom2",
        "InspectFramePortraitFrame", "InspectFrameTitleBg", "InspectFrameTopBorder",
        "InspectFrame.PortraitContainer", "InspectFrame.TitleContainer",
        "InspectModelFrameControlFrame" 
    }
    
    -- Process Global Banishes
    for _, name in ipairs(banishCandidates) do
        local frame = _G[name]
        if frame and frame:GetParent() ~= ns.HiddenFrame then
            frame:SetParent(ns.HiddenFrame)
            frame:Hide()
            frame:SetAlpha(0)
        end
    end

    -- Process Nested Banishes
    local nestedCandidates = {
        { InspectFrame, "Background" }, { InspectFrame, "NineSlice" },
        { InspectFrame, "Inset" }, { InspectFrame, "TitleBg" },
        { InspectFrame, "TopTileStreaks" }, { InspectFrame, "Bg" },
        { InspectModelFrame, "BackgroundOverlay" },
        { InspectPaperDollFrame, "ClassBackground" },
        { InspectModelFrame, "ControlFrame" },
    }

    for _, entry in ipairs(nestedCandidates) do
        local parent, key = entry[1], entry[2]
        if parent and parent[key] then
            local frame = parent[key]
            if frame:GetParent() ~= ns.HiddenFrame then
                frame:SetParent(ns.HiddenFrame)
                frame:Hide()
                frame:SetAlpha(0)
            end
        end
    end

    -- Helper to banish a texture by re-parenting and stripping
    local function BanishRegion(region)
        if not region then return end
        if region:GetParent() ~= ns.HiddenFrame then
            pcall(region.SetParent, region, ns.HiddenFrame)
        end
        region:SetAlpha(0)
    end

    -- Nuclear Option: Disable Draw Layers on Model/PaperDoll
    if InspectModelFrame then
        if InspectModelFrame.DisableDrawLayer then
            InspectModelFrame:DisableDrawLayer("BACKGROUND")
            InspectModelFrame:DisableDrawLayer("BORDER")
            InspectModelFrame:DisableDrawLayer("ARTWORK")
            InspectModelFrame:DisableDrawLayer("OVERLAY")
        end
        -- Banish background regions
        for i = 1, InspectModelFrame:GetNumRegions() do
            BanishRegion(select(i, InspectModelFrame:GetRegions()))
        end
    end
    if InspectPaperDollFrame then
        if InspectPaperDollFrame.DisableDrawLayer then
            InspectPaperDollFrame:DisableDrawLayer("BACKGROUND")
            InspectPaperDollFrame:DisableDrawLayer("BORDER")
            InspectPaperDollFrame:DisableDrawLayer("ARTWORK")
            InspectPaperDollFrame:DisableDrawLayer("OVERLAY")
        end
        for i = 1, InspectPaperDollFrame:GetNumRegions() do
            BanishRegion(select(i, InspectPaperDollFrame:GetRegions()))
        end
    end

    -- Texture Hunter: Periodic check to kill any large textures that reappear
    if not InspectFrame._textureHunterHooked then
        InspectFrame:HookScript("OnUpdate", function(self, elapsed)
            self._timer = (self._timer or 0) + elapsed
            if self._timer > 1.0 then 
                self._timer = 0
                if InspectModelFrame then
                    for i = 1, InspectModelFrame:GetNumRegions() do
                        local region = select(i, InspectModelFrame:GetRegions())
                        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                            if region:GetAlpha() > 0 then region:SetAlpha(0); region:SetTexture("") end
                        end
                    end
                end
                if InspectPaperDollFrame then
                    for i = 1, InspectPaperDollFrame:GetNumRegions() do
                        local region = select(i, InspectPaperDollFrame:GetRegions())
                        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                             if region:GetAlpha() > 0 then region:SetAlpha(0); region:SetTexture("") end
                        end
                    end
                end
            end
        end)
        InspectFrame._textureHunterHooked = true
    end
end


---------------------------------------------------------------------------
-- One-time structural layout setup
---------------------------------------------------------------------------
local function InitializeInspectUI()
    if not InspectFrame then return end
    
    local settings = GetSettings()
    if not settings.inspectEnabled then return end
    
    if not inspectPaneInitialized then
        for _, slotName in ipairs(INSPECT_SLOT_NAMES) do
            local slot = _G[slotName]
            if slot then SkinInspectEquipmentSlot(slot) end
        end
        InitializeInspectOverlays()
        SetupInspectTitleArea()
    end
    
    if not inspectLayoutApplied then
        InspectFrame:SetWidth(INSPECT_CONFIG.FRAME_TARGET_WIDTH)
        CreateInspectBackground()
        RepositionInspectSlots()
        RepositionInspectCloseButton(true)
        PositionInspectModelScene()
        inspectLayoutApplied = true
    end
end

---------------------------------------------------------------------------
-- Main Refresh
---------------------------------------------------------------------------
local function UpdateInspectFrame()
    if not InspectFrame or not InspectFrame:IsShown() then return end
    
    local settings = GetSettings()
    if not settings.inspectEnabled then return end
    
    InitializeInspectUI()
    
    local unit = InspectFrame.unit or "target"
    if UnitExists(unit) then
        local guid = UnitGUID(unit)
        if not guid then return end
        
        -- Start Cache Populating
        if not inspectCache[guid] then inspectCache[guid] = {} end
        local cache = inspectCache[guid]
        
        -- Process all slots in a single pass
        for slotID, _ in pairs(SLOT_INFO) do
            local link = GetInventoryItemLink(unit, slotID)
            if link then
                local isCached = cache[slotID] and cache[slotID].link == link
                -- Force a re-scan if we previously cached it but data was missing (e.g., name was Loading or ilvl was nil)
                if isCached and (cache[slotID].name == "Loading..." or not cache[slotID].ilvl) then
                    isCached = false
                end

                if not isCached then
                    -- New or different item, or data was missing: Full scan
                    local ilvl = GetSlotItemLevel(unit, slotID, link)
                    local track, cur, max = GetUpgradeTrack(unit, slotID)
                    local enchant, enchantable = GetEnchantText(unit, slotID)
                    local gems = GetGemInfo(unit, slotID)
                    local name, _, quality = GetItemInfo(link)
                    
                    cache[slotID] = {
                        link = link,
                        ilvl = ilvl,
                        track = track,
                        curTrack = cur,
                        maxTrack = max,
                        enchant = enchant,
                        enchantable = enchantable,
                        gems = gems,
                        name = name or "Loading...",
                        quality = quality or 1
                    }
                end
            else
                cache[slotID] = nil
            end
        end

        UpdateAllInspectSlotBorders(unit)
        for slotID, overlay in pairs(inspectOverlays) do
            UpdateSlotOverlay(overlay, unit, cache[slotID])
        end

        UpdateInspectILvlDisplay()
        currentInspectGUID = guid
    end
    
    local baseScale = INSPECT_CONFIG.BASE_SCALE
    local userScale = settings.panelScale or 1.0
    InspectFrame:SetScale(baseScale * userScale)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Throttled Update System
---------------------------------------------------------------------------
local lastInspectUpdate = 0
local function ThrottledUpdate()
    local now = GetTime()
    if (now - lastInspectUpdate) < 0.1 then return end
    lastInspectUpdate = now
    UpdateInspectFrame()
end

local function TriggerInspectUpdates(force)
    -- 1. Immediate Throttled Update
    ThrottledUpdate()
    
    -- 2. Single Delayed Update for data latency (server delay)
    -- We only need one retry at 0.5s to catch most missing item links
    if not force then
        C_Timer.After(0.5, ThrottledUpdate)
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("INSPECT_READY")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_InspectUI" then
        InspectFrame:HookScript("OnShow", function()
            InitializeInspectUI() -- Run synchronously to avoid FOUC
            TriggerInspectUpdates()
        end)
        InspectFrame:HookScript("OnHide", function()
            inspectLayoutApplied = false
        end)
    elseif event == "INSPECT_READY" then
        TriggerInspectUpdates()
        -- Spec data can arrive slightly after INSPECT_READY; always do a second pass to catch it
        C_Timer.After(0.8, function()
            if InspectFrame and InspectFrame:IsShown() then
                UpdateInspectILvlDisplay()
            end
        end)
    elseif event == "GET_ITEM_INFO_RECEIVED" or event == "UNIT_INVENTORY_CHANGED" then
         -- Debounce update for item info flow
         if InspectFrame and InspectFrame:IsShown() and not self.updatePending then
             self.updatePending = true
             C_Timer.After(0.1, function()
                 UpdateInspectFrame()
                 self.updatePending = false
             end)
         end
    end
end
eventFrame:SetScript("OnEvent", OnEvent)

-- Immediate check if Blizzard_InspectUI is already loaded
if C_AddOns.IsAddOnLoaded("Blizzard_InspectUI") and InspectFrame then
    -- Hook if not already hooked (this script runs once, but for safety)
    if not InspectFrame.gravityAndInsetHooked then
        InspectFrame:HookScript("OnShow", TriggerInspectUpdates)
        InspectFrame:HookScript("OnHide", function()
            inspectLayoutApplied = false
        end)
        InspectFrame.gravityAndInsetHooked = true
    end
    -- If frame is currently open (reload scenario), update immediately
    if InspectFrame:IsShown() then
        TriggerInspectUpdates()
    end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
Inspect.UpdateInspectFrame = UpdateInspectFrame
