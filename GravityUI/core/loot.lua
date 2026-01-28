local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = ns.Colors

-- Module
ns.Loot = {}
local Loot = ns.Loot

-------------------------------------------------------------------------------
-- CONSTANTS & HELPERS
-------------------------------------------------------------------------------
local MAX_LOOT_SLOTS = 10
local MAX_ROLL_FRAMES = 8
local SLOT_HEIGHT = 32
local SLOT_WIDTH = 230
local HEADER_HEIGHT = 30
local ROLL_FRAME_HEIGHT = 50
local ROLL_FRAME_WIDTH = 340

local function GetDB()
    if ns.db and ns.db.profile and ns.db.profile.styling then
        return ns.db.profile.styling
    end
    return nil
end

local function GetFont()
    local path, outline = ns.GetFont()
    return path, 11, outline
end

local function GetAccent()
    return ns.GetAccentColor()
end

local function IsUncollectedTransmog(itemLink)
    if not itemLink then return false end
    if not C_TransmogCollection or not C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance then
        return false
    end
    
    local itemID = GetItemInfoInstant(itemLink)
    if not itemID then return false end

    -- Check if it's equipment (Weapon or Armor)
    local _, _, _, _, _, classID = GetItemInfoInstant(itemLink)
    if classID ~= 2 and classID ~= 4 then return false end

    -- Check if we can learn it
    local _, sourceID = C_TransmogCollection.GetItemInfo(itemLink)
    if sourceID then
        local _, canCollect = C_TransmogCollection.PlayerCanCollectSource(sourceID)
        if canCollect then
            local collected = C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID)
            return not collected
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- LOOT WINDOW
-------------------------------------------------------------------------------
local lootFrame = nil

local function CreateLootSlot(parent, index)
    local slot = CreateFrame("Button", nil, parent)
    slot:SetSize(SLOT_WIDTH, SLOT_HEIGHT)
    slot:SetPoint("TOP", parent, "TOP", 0, -HEADER_HEIGHT - ((index-1) * (SLOT_HEIGHT + 2)))

    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetSize(28, 28)
    slot.icon:SetPoint("LEFT", 4, 0)
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    slot.iconBorder = CreateFrame("Frame", nil, slot, "BackdropTemplate")
    slot.iconBorder:SetSize(30, 30)
    slot.iconBorder:SetPoint("CENTER", slot.icon, "CENTER")
    slot.iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

    slot.name = slot:CreateFontString(nil, "OVERLAY")
    slot.name:SetFont(GetFont())
    slot.name:SetPoint("LEFT", slot.icon, "RIGHT", 6, 0)
    slot.name:SetPoint("RIGHT", slot, "RIGHT", -10, 0)
    slot.name:SetJustifyH("LEFT")
    slot.name:SetWordWrap(false)

    slot.count = slot:CreateFontString(nil, "OVERLAY")
    slot.count:SetFont(GetFont())
    slot.count:SetPoint("BOTTOMRIGHT", slot.icon, "BOTTOMRIGHT", -2, 1)

    -- Transmog marker
    slot.transmogMarker = slot:CreateFontString(nil, "OVERLAY")
    slot.transmogMarker:SetFont(GetFont())
    slot.transmogMarker:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -4, -4)
    slot.transmogMarker:SetText("*")
    slot.transmogMarker:SetTextColor(1, 0.82, 0)
    slot.transmogMarker:Hide()

    slot:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    slot:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.1)

    slot:SetScript("OnClick", function(self) if self.slotIndex then LootSlot(self.slotIndex) end end)
    slot:SetScript("OnEnter", function(self)
        if self.slotIndex then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetLootItem(self.slotIndex)
            GameTooltip:Show()
        end
    end)
    slot:SetScript("OnLeave", GameTooltip_Hide)

    return slot
end

local function UpdateLootFrameStyling(f)
    if not f then return end
    local db = GetDB()
    if not db or not db.loot then return end
    
    local sr, sg, sb, sa = GetAccent()
    local bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    if db.loot.disableThemeColorBackground then
        bgr, bgg, bgb, bga = unpack(db.loot.customBackgroundColor)
    end
    
    f:SetBackdropColor(bgr, bgg, bgb, bga)
    f:SetBackdropBorderColor(sr, sg, sb, sa)
    
    local tr, tg, tb, ta = sr, sg, sb, sa -- Default to Theme Color
    if db.loot.disableThemeColorFont then
        tr, tg, tb, ta = unpack(db.loot.customFontColor)
    end
    if f.header then f.header:SetTextColor(tr, tg, tb, ta) end
end

function Loot:RefreshStyling()
    if lootFrame then
        UpdateLootFrameStyling(lootFrame)
    end
end

function Loot:RefreshHistoryStyling()
    local f = _G.GroupLootHistoryFrame
    if f and f.guiBackdrop then
        local db = GetDB()
        if not db or not db.lootResults then return end
        
        local sr, sg, sb, sa = GetAccent()
        local bgr, bgg, bgb, bga = ns.GetThemeBgColor()
        if db.lootResults.disableThemeColorBackground then
            bgr, bgg, bgb, bga = unpack(db.lootResults.customBackgroundColor)
        end
        f.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        f.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        
        if f.ScrollBox then
            f.ScrollBox:ForEachFrame(function(frame)
                frame.guiSkinned = false -- Force re-skin
                SkinLootHistoryElement(frame)
            end)
        end
    end
end

local function CreateLootWindow()
    local f = CreateFrame("Frame", "GravityUI_LootFrame", UIParent, "BackdropTemplate")
    f:SetSize(250, 200)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:Hide()

    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

    f.header = f:CreateFontString(nil, "OVERLAY")
    table.insert(ns.trackedFonts, f.header) -- Track for global font changes
    f.header:SetFont(GetFont())
    f.header:SetPoint("TOP", 0, -8)
    f.header:SetText("Loot")

    UpdateLootFrameStyling(f)

    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) if self._previewMode or IsShiftKeyDown() then self:StartMoving() end end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = GetDB()
        if db and db.loot then
             local p, _, rp, x, y = self:GetPoint()
             db.loot.position = { point = p, relPoint = rp, x = x, y = y }
        end
    end)

    f:SetScript("OnHide", function(self)
        self._previewMode = false
    end)

    f.slots = {}
    for i = 1, MAX_LOOT_SLOTS do f.slots[i] = CreateLootSlot(f, i) end

    return f
end

-------------------------------------------------------------------------------
-- LOOT HISTORY (Roll Results)
-------------------------------------------------------------------------------

local function SkinLootHistoryElement(frame)
    if not frame or frame.guiSkinned then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    
    local db = GetDB()
    local sr, sg, sb, sa = GetAccent()
    local font, size, outline = GetFont()
    
    local tr, tg, tb, ta = sr, sg, sb, sa -- Default to Theme Color
    local customFont = db and db.lootResults and db.lootResults.disableThemeColorFont
    if customFont then
        tr, tg, tb, ta = unpack(db.lootResults.customFontColor)
    end

    if frame.Name then
        pcall(function() frame.Name:SetFont(font, 12, outline) end)
    end
    
    if frame.WinnerName then
        pcall(function() 
            frame.WinnerName:SetFont(font, 12, outline)
            frame.WinnerName:SetTextColor(tr, tg, tb, ta)
        end)
    end
    
    if frame.Icon then
        pcall(function()
            frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if not frame.iconBorder then
                frame.iconBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                frame.iconBorder:SetPoint("TOPLEFT", frame.icon, -1, 1)
                frame.iconBorder:SetPoint("BOTTOMRIGHT", frame.icon, 1, -1)
                frame.iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
                frame.iconBorder:SetBackdropBorderColor(sr, sg, sb, 1)
            end
        end)
    end
    
    frame.guiSkinned = true
end

local function SkinGroupLootHistoryFrame()
    local f = _G.GroupLootHistoryFrame
    if not f or f.guiSkinned then return end
    
    local db = GetDB()
    local sr, sg, sb, sa = GetAccent()
    
    if f.NineSlice then f.NineSlice:SetAlpha(0) end
    if f.Bg then f.Bg:SetAlpha(0) end
    
    if not f.guiBackdrop then
        f.guiBackdrop = CreateFrame("Frame", nil, f, "BackdropTemplate")
        f.guiBackdrop:SetAllPoints()
        f.guiBackdrop:SetFrameLevel(f:GetFrameLevel())
        f.guiBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        
        local bgr, bgg, bgb, bga = ns.GetThemeBgColor()
        if db and db.lootResults and db.lootResults.disableThemeColorBackground then
            bgr, bgg, bgb, bga = unpack(db.lootResults.customBackgroundColor)
        end
        f.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        f.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end

    if f.ScrollBox then
        hooksecurefunc(f.ScrollBox, "Update", function(box)
            if not box or (box.IsForbidden and box:IsForbidden()) then return end
            -- Using pcall here to prevent crash if ForEachFrame hits a restricted internal frame
            pcall(function() 
                box:ForEachFrame(SkinLootHistoryElement)
            end)
        end)
    end
    
    f.guiSkinned = true
end

-------------------------------------------------------------------------------
-- EVENT HANDLERS
-------------------------------------------------------------------------------

local function OnLootOpened()
    local db = GetDB()
    if not db or not db.loot or not db.loot.enabled then return end
    
    local numItems = GetNumLootItems()
    if numItems == 0 then return end

    if not lootFrame then lootFrame = CreateLootWindow() end
    
    -- Position
    if db.loot.lootUnderMouse then
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x/scale, y/scale)
    elseif db.loot.position and db.loot.position.point then
        local p = db.loot.position
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end

    local visible = 0
    for i = 1, numItems do
        local texture, name, qty, _, quality, locked, isQuestItem, questID = GetLootSlotInfo(i)
        if texture then
            local slot = lootFrame.slots[i]
            slot.slotIndex = i
            slot.icon:SetTexture(texture)
            slot.name:SetText(name)
            local r, g, b = GetItemQualityColor(quality or 1)
            slot.iconBorder:SetBackdropBorderColor(r, g, b, 1)
            slot.name:SetTextColor(r, g, b)
            slot.count:SetText(qty > 1 and qty or "")
            
            -- Transmog marker
            if db.loot.showTransmogMarkers then
                local link = GetLootSlotLink(i)
                slot.transmogMarker:SetShown(IsUncollectedTransmog(link))
            else
                slot.transmogMarker:Hide()
            end
            
            slot:Show()
            visible = visible + 1
        end
    end
    for i = numItems + 1, MAX_LOOT_SLOTS do lootFrame.slots[i]:Hide() end

    lootFrame:SetHeight(HEADER_HEIGHT + 10 + (visible * (SLOT_HEIGHT + 2)))
    lootFrame:Show()
end

function Loot:ToggleMover()
    if not lootFrame then lootFrame = CreateLootWindow() end
    
    if lootFrame:IsShown() and lootFrame._previewMode then
        lootFrame:Hide()
        lootFrame._previewMode = false
    else
        lootFrame._previewMode = true
        
        -- Apply Position
        local db = GetDB()
        if db and db.loot and db.loot.position and db.loot.position.point then
            local p = db.loot.position
            lootFrame:ClearAllPoints()
            lootFrame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
        else
            lootFrame:ClearAllPoints()
            lootFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        end

        -- Show with dummy data
        for i = 1, 3 do
            local slot = lootFrame.slots[i]
            slot.icon:SetTexture("Interface\\Icons\\inv_misc_bag_08")
            slot.name:SetText("Loot Item Preview " .. i)
            slot.name:SetTextColor(1, 0.82, 0)
            slot.iconBorder:SetBackdropBorderColor(1, 0.82, 0, 1)
            slot.count:SetText("")
            slot.transmogMarker:Hide()
            slot.slotIndex = nil
            slot:Show()
        end
        for i = 4, MAX_LOOT_SLOTS do lootFrame.slots[i]:Hide() end
        lootFrame:SetHeight(HEADER_HEIGHT + 10 + (3 * (SLOT_HEIGHT + 2)))
        lootFrame:Show()
    end
end

function Loot:ResetPosition()
    local db = GetDB()
    if db and db.loot then
        db.loot.position = nil
    end
    if lootFrame then
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end
end

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

function Loot:Initialize()
    local db = GetDB()
    if not db then return end

    -- Custom Loot Window
    if db.loot and db.loot.enabled then
        LootFrame:UnregisterAllEvents()
        LootFrame:Hide()

        if not self.eventFrame then
            self.eventFrame = CreateFrame("Frame")
            self.eventFrame:RegisterEvent("LOOT_OPENED")
            self.eventFrame:RegisterEvent("LOOT_READY")
            self.eventFrame:RegisterEvent("LOOT_CLOSED")
            self.eventFrame:SetScript("OnEvent", function(self, event)
                if event == "LOOT_CLOSED" then
                    if lootFrame then lootFrame:Hide() end
                else
                    OnLootOpened()
                end
            end)
        end
    end
    
    -- Loot History
    if db.lootResults and db.lootResults.enabled then
        if _G.GroupLootHistoryFrame then
            SkinGroupLootHistoryFrame()
        else
            local f = CreateFrame("Frame")
            f:RegisterEvent("ADDON_LOADED")
            f:SetScript("OnEvent", function(self, event, addon)
                if addon == "Blizzard_GroupLootUI" then
                    SkinGroupLootHistoryFrame()
                    self:UnregisterEvent("ADDON_LOADED")
                end
            end)
        end
    end
end
