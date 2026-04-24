local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = ns.Colors
local LSM = LibStub("LibSharedMedia-3.0", true)

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

-- Ensure LSM is available locally if not already (it is used in GetStatusbarTexture later)
-- We will resolve it inside the function to be safe or use ns.LSM if it exists


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

    -- Close Button
    f.close = CreateFrame("Button", nil, f, "BackdropTemplate")
    f.close:SetSize(16, 16)
    f.close:SetPoint("TOPRIGHT", -5, -5)
    f.close:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f.close:SetBackdropColor(0.8, 0.2, 0.2, 0.6)
    f.close:SetBackdropBorderColor(1, 1, 1, 0.4)
    
    f.close.text = f.close:CreateFontString(nil, "OVERLAY")
    f.close.text:SetFont(ns.GetFont(), 10, "OUTLINE")
    f.close.text:SetPoint("CENTER", 0, 0)
    f.close.text:SetText("X")
    f.close.text:SetTextColor(1, 1, 1, 1)

    f.close:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1, 0.2, 0.2, 1)
        self:SetBackdropBorderColor(1, 1, 1, 1)
    end)
    f.close:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.8, 0.2, 0.2, 0.6)
        self:SetBackdropBorderColor(1, 1, 1, 0.4)
    end)
    f.close:SetScript("OnClick", function()
        CloseLoot()
        f:Hide()
    end)

    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })

    f.header = f:CreateFontString(nil, "OVERLAY")
    local _, defaultFlags = ns.GetFont()
    ns.trackedFonts[f.header] = {size = 11, flags = defaultFlags} -- Track for global font changes
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

local function UpdateLootHistorySize()
    local f = _G.GroupLootHistoryFrame
    if not f then return end
    
    local db = GetDB()
    if db and db.lootResults and db.lootResults.size then
        f:SetSize(db.lootResults.size.width, db.lootResults.size.height)
    end
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

    -- Make Resizable
    f:SetResizable(true)
    f:SetResizeBounds(200, 100, 800, 1000)
    
    -- Resize Grip
    if not f.guiResizeGrip then
        local grip = CreateFrame("Button", nil, f)
        grip:SetSize(16, 16)
        grip:SetPoint("BOTTOMRIGHT", -1, 1)
        grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        
        grip:SetScript("OnMouseDown", function() 
            f:StartSizing("BOTTOMRIGHT")
            f.isResizing = true 
        end)
        grip:SetScript("OnMouseUp", function() 
            f:StopMovingOrSizing()
            f.isResizing = false
            
            -- Save Size
            local db = GetDB()
            if db and db.lootResults then
                db.lootResults.size = { width = f:GetWidth(), height = f:GetHeight() }
            end
        end)
        f.guiResizeGrip = grip
    end
    
    -- Restore saved size
    UpdateLootHistorySize()

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
            if not lootFrame.slots[i] then
                lootFrame.slots[i] = CreateLootSlot(lootFrame, i)
            end
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
    
    -- Hide unused slots, checking against total created slots
    for i = numItems + 1, #lootFrame.slots do 
        if lootFrame.slots[i] then lootFrame.slots[i]:Hide() end
    end

    -- Sizing fix: Use numItems (total loot) instead of 'visible' to ensure height is correct even if textures lag
    lootFrame:SetHeight(HEADER_HEIGHT + 10 + (numItems * (SLOT_HEIGHT + 2)))
    lootFrame:Show()
end

function Loot:ToggleMover(forceState)
    if not lootFrame then lootFrame = CreateLootWindow() end
    
    local shouldShow = false
    if forceState ~= nil then
        shouldShow = forceState
    else
        -- Toggle logic
        shouldShow = not (lootFrame:IsShown() and lootFrame._previewMode)
    end

    -- Register with Movers System
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("LootWindow", lootFrame, function(frame, enabled) Loot:ToggleMover(enabled) end, "Loot Window")
    end
    
    if not shouldShow then
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(lootFrame, false)
        end
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
        
        -- Apply Standard Edit Mode Style
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(lootFrame, forceState == true)
        end
        
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
-- LOOT ROLLS (Group Loot)
-------------------------------------------------------------------------------

local function GetStatusbarTexture(name)
    if LSM then
        return LSM:Fetch("statusbar", name or "Gravity")
    end
    return "Interface\\TargetingFrame\\UI-StatusBar"
end

local function UpdateGroupLootStyle(frame)
    if not frame then return end
    local db = GetDB()
    if not db or not db.lootRoll or not db.lootRoll.enabled then return end

    local cfg = db.lootRoll
    frame:SetSize(cfg.width, cfg.height)
    frame:SetScale(1)

    -- Background (Transparent or Colored)
    if not frame.guiBackground then
        frame.guiBackground = frame:CreateTexture(nil, "BACKGROUND")
        frame.guiBackground:SetAllPoints()
    end
    
    if cfg.enableBackgroundColor then
        frame.guiBackground:Show()
        if cfg.backgroundColor then
            frame.guiBackground:SetColorTexture(unpack(cfg.backgroundColor))
        else
            frame.guiBackground:SetColorTexture(0, 0, 0, 0.5)
        end
    else
        frame.guiBackground:Hide()
    end
    
    local textureParams = GetStatusbarTexture(cfg.texture)

    -- Timer (StatusBar) - Bottom Strip
    if frame.Timer then
        frame.Timer:SetStatusBarTexture(textureParams)
        frame.Timer:ClearAllPoints()
        frame.Timer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        frame.Timer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        frame.Timer:SetHeight(cfg.timerHeight or 8) 
        
        frame.Timer:SetFrameLevel(frame:GetFrameLevel() + 1)
        frame.Timer:SetAlpha(1)
        
        -- Hide default background of the timer if any
        if frame.Timer.Background then frame.Timer.Background:Hide() end
        if frame.Timer.Text then frame.Timer.Text:Hide() end 
        
        -- Add Background to Timer Frame if missing
        if not frame.TimerBg then
             frame.TimerBg = frame.Timer:CreateTexture(nil, "BACKGROUND")
             frame.TimerBg:SetAllPoints(frame.Timer)
             frame.TimerBg:SetTexture(GetStatusbarTexture(cfg.texture))
             frame.TimerBg:SetVertexColor(0.1, 0.1, 0.1, 1) -- Dark background
        end
    end

    -- Icon
    if frame.IconFrame then
        frame.IconFrame:ClearAllPoints()
        frame.IconFrame:SetPoint("LEFT", frame, "LEFT", -cfg.height - 5, 0) 
        frame.IconFrame:SetSize(cfg.height, cfg.height)
        
        -- Ensure Icon fills the frame
        if frame.IconFrame.Icon then
            frame.IconFrame.Icon:ClearAllPoints()
            frame.IconFrame.Icon:SetAllPoints(frame.IconFrame)
        end
        
        if frame.IconFrame.Border then frame.IconFrame.Border:Hide() end
        if frame.IconFrame.Count then frame.IconFrame.Count:SetFont(GetFont()) end
        
        if frame.guiIconBorder then frame.guiIconBorder:Hide() end
    end
    
    -- Name
    if frame.Name then
        frame.Name:ClearAllPoints()
        local timerHeight = cfg.timerHeight or 8
        frame.Name:SetPoint("LEFT", frame, "LEFT", 0, timerHeight / 2) 
        
        local fontName = cfg.nameFont or "Gravity"
        local fontPath = (LSM and LSM:Fetch("font", fontName)) or "Fonts\\FRIZQT__.TTF"
        local fontSize = cfg.nameFontSize or 12
        local fontOutline = cfg.nameFontOutline or "OUTLINE"

        frame.Name:SetFont(fontPath, fontSize, fontOutline)
        
        if cfg.nameFontColor then
             frame.Name:SetTextColor(unpack(cfg.nameFontColor))
        end

        frame.Name:SetDrawLayer("OVERLAY")
    end
    
    -- 5. Item Level Text
    local ilvlParent = frame.IconFrame or frame
    if not frame.guiIlvl then
        frame.guiIlvl = ilvlParent:CreateFontString(nil, "OVERLAY")
        frame.guiIlvl:SetFont(GetFont(), 10, "OUTLINE") 
        frame.guiIlvl:SetTextColor(1, 0.8, 0)
    else
        frame.guiIlvl:SetParent(ilvlParent)
    end

    if frame.IconFrame then
        frame.guiIlvl:ClearAllPoints()
        frame.guiIlvl:SetPoint("BOTTOM", frame.IconFrame, "BOTTOM", 0, 1)
        frame.guiIlvl:SetDrawLayer("OVERLAY", 7) 
    end

    -- Bind Text (BoP / BoE)
    if not frame.guiBindText then
        frame.guiBindText = frame:CreateFontString(nil, "OVERLAY")
    end
    
    local font = GetFont() 
    frame.guiBindText:SetFont(font, 10, "OUTLINE")
    frame.guiBindText:ClearAllPoints()
    
    if frame.Name then
        frame.guiBindText:SetPoint("LEFT", frame.Name, "RIGHT", 5, 0)
    else
        frame.guiBindText:SetPoint("LEFT", frame.IconFrame, "RIGHT", 5, 0)
    end

    local btnSize = 22 
    
    local function SkinButton(btn)
        if not btn then return end
        btn:SetSize(btnSize, btnSize)
        btn:ClearAllPoints()
        btn:SetFrameLevel(frame:GetFrameLevel() + 5)
    end

    -- Disable default decoration
    if frame.Background then frame.Background:Hide() end
    if frame.Border then frame.Border:Hide() end
    if frame.SetBackdrop then frame:SetBackdrop(nil) end
    
    -- Item Quality Border (Clean 1px)
    if not frame.IconBorder then
        local borderParent = frame.IconFrame or frame
        frame.IconBorder = CreateFrame("Frame", nil, borderParent, "BackdropTemplate")
        if frame.IconFrame then
             frame.IconBorder:SetPoint("TOPLEFT", frame.IconFrame, "TOPLEFT", -1, 1)
             frame.IconBorder:SetPoint("BOTTOMRIGHT", frame.IconFrame, "BOTTOMRIGHT", 1, -1)
             frame.IconBorder:SetBackdrop({
                 edgeFile = "Interface\\Buttons\\WHITE8x8",
                 edgeSize = 1,
             })
        end
    end
    local link
    if frame.rollID then
        link = GetLootRollItemLink(frame.rollID)
    end
    
    -- Color by Quality (Always apply if we have quality)
    if quality then
        local r, g, b = GetItemQualityColor(quality)
        if frame.IconBorder then frame.IconBorder:SetBackdropBorderColor(r, g, b, 1) end
    end
    
    if link then
        -- Any logic that strictly needs link
    end
    
    -- Check for Transmog Button texture safety on Real Frames too
    if frame.TransmogButton then
        -- Default texture is usually fine on real frames, but let's ensure it's not nil if user reported 'missing'.
        -- Actually, Game usually handles this. If it's invisible, it might be the texture file is gone.
        -- We won't force a texture on the REAL button unless necessary, but we can verify regions.
    end

    
    -- Re-arrange buttons. Order: Pass (Rightmost) <- Transmog <- Greed <- Need
    
    -- 1. Pass (Rightmost)
    local lastAnchor = frame
    -- Shift Up to center above bar (Height 40, Bar 8, Btn 26)
    -- Layout: Button Bottom = 8px + 4px padding = 12px from bottom.
    local btnY = 12
    
    if frame.PassButton then 
        SkinButton(frame.PassButton)
        frame.PassButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, btnY)
        lastAnchor = frame.PassButton
        xOffset = -2
    end
    
    -- 2. Transmog
    if frame.TransmogButton then 
        SkinButton(frame.TransmogButton)
        frame.TransmogButton:SetPoint("RIGHT", lastAnchor, "LEFT", xOffset, 0)
        lastAnchor = frame.TransmogButton
        xOffset = -2
    end
    
    -- 2.5 Disenchant
    if frame.DisenchantButton then 
        SkinButton(frame.DisenchantButton)
        frame.DisenchantButton:SetPoint("RIGHT", lastAnchor, "LEFT", xOffset, 0)
        lastAnchor = frame.DisenchantButton
        xOffset = -2
    end
    
    -- 3. Greed
    if frame.GreedButton then 
        SkinButton(frame.GreedButton)
        frame.GreedButton:SetPoint("RIGHT", lastAnchor, "LEFT", xOffset, 0)
        lastAnchor = frame.GreedButton
        xOffset = -2
    end
    
    -- 4. Need
    if frame.NeedButton then 
        SkinButton(frame.NeedButton)
        frame.NeedButton:SetPoint("RIGHT", lastAnchor, "LEFT", xOffset, 0)
        lastAnchor = frame.NeedButton
        xOffset = -2
    end
    
    -- Store leftmost button for anchoring Name/BindText
    frame.leftmostButton = lastAnchor
    
    -- Helper: Tooltip on Icon
    if frame.IconFrame then
        frame.IconFrame:EnableMouse(true)
        frame.IconFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            
            local valid = false
            -- 1. Try Live Loot Roll
            if frame.rollID and frame.rollID < 100 then -- Real IDs are small integers usually, fake are 100+
                GameTooltip:SetLootRollItem(frame.rollID)
                -- Check if it actually worked? Hard to tell, but usually does for valid IDs
                valid = true
            end
            
            -- 2. Fallback to cached link (Test Mode or if Roll functions fail)
            if not valid or GameTooltip:NumLines() == 0 then
                 if frame.gravityLootLink then
                     GameTooltip:SetHyperlink(frame.gravityLootLink)
                 end
            end
            
            GameTooltip:Show()
        end)
        frame.IconFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    
    -- Dynamic Anchoring for Name & BindText (Decoupled for perfect centering)
    local timerHeight = cfg.timerHeight or 8
    local centerY = timerHeight / 2
    
    -- Calculate reserved width for buttons
    local reservedWidth = 5 
    if frame.PassButton then reservedWidth = reservedWidth + 22 + 2 end
    if frame.TransmogButton then reservedWidth = reservedWidth + 22 + 2 end
    if frame.GreedButton then reservedWidth = reservedWidth + 22 + 2 end
    if frame.NeedButton then reservedWidth = reservedWidth + 22 + 2 end
    -- Add Disenchant if it exists
    if frame.DisenchantButton then reservedWidth = reservedWidth + 22 + 2 end

    if frame.Name then
        frame.Name:ClearAllPoints()
        frame.Name:SetPoint("LEFT", frame, "LEFT", 0, centerY)
            
        if frame.guiBindText then
            frame.guiBindText:ClearAllPoints()
            -- Anchor BindText to the right limit
            frame.guiBindText:SetPoint("RIGHT", frame, "RIGHT", -reservedWidth, centerY)
            
            frame.Name:SetPoint("RIGHT", frame.guiBindText, "LEFT", -5, 0)
        else
            -- Anchor Name to the right limit
            frame.Name:SetPoint("RIGHT", frame, "RIGHT", -reservedWidth, centerY)
        end
        frame.Name:SetJustifyH("LEFT")
        frame.Name:SetWordWrap(false)
        frame.Name:SetNonSpaceWrap(false)
    end
end

local function OnGroupLootShow(frame)
    local db = GetDB()
    if not db or not db.lootRoll or not db.lootRoll.enabled then return end
    
    UpdateGroupLootStyle(frame)
    
    -- Color by Quality
    local quality = 1
    if frame.rollID then
        local _, _, _, q, bindOnPickUp = GetLootRollItemInfo(frame.rollID)
        quality = q
        
        -- Item Level
        if frame.guiIlvl then
             frame.guiIlvl:SetText("")
             local link = GetLootRollItemLink(frame.rollID)
             frame.gravityLootLink = link -- Store for tooltip fallback
             
             if link then
                 local _, _, _, ilvl = GetItemInfo(link)
                 if ilvl then
                     frame.guiIlvl:SetText(ilvl)
                 else
                     -- Sometimes GetItemInfo returns nil for ilvl initially
                     local item = Item:CreateFromItemLink(link)
                     item:ContinueOnItemLoad(function()
                        local level = item:GetCurrentItemLevel()
                        if level then frame.guiIlvl:SetText(level) end
                     end)
                 end
             end
        end

        -- Bind Text
        local showBind = false
        if frame.guiBindText then
            local bindText = ""
            
            -- User req: Do NOT show BoP. Only show BoE in Green with White parens.
            if not bindOnPickUp then
                local link = GetLootRollItemLink(frame.rollID)
                if link then
                    local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(link)
                    if bindType == 2 then -- LE_ITEM_BIND_ON_EQUIP
                         -- Green text, no parens
                         bindText = "|cff1eff00BoE|r"
                         showBind = true
                    elseif bindType == 3 then -- Use
                         bindText = "|cff1eff00BoU|r"
                         showBind = true
                    end
                end
            end
            frame.guiBindText:SetText(bindText)
        end
        
        -- Anchor Name and BindText dynamically
        -- Only if we have a leftmost button to anchor to
        -- Anchor Name and BindText dynamically
        -- Decouple from Buttons to ensure perfect vertical centering
        if frame.Name then
             local timerHeight = (db and db.lootRoll and db.lootRoll.timerHeight) or 8
             local centerY = timerHeight / 2 -- Visual center above timer
             
             -- Calculate reserved width for buttons
             local reservedWidth = 5 
             if frame.PassButton then reservedWidth = reservedWidth + 22 + 2 end
             if frame.TransmogButton then reservedWidth = reservedWidth + 22 + 2 end
             if frame.GreedButton then reservedWidth = reservedWidth + 22 + 2 end
             if frame.NeedButton then reservedWidth = reservedWidth + 22 + 2 end
             -- Add Disenchant if it exists
             if frame.DisenchantButton then reservedWidth = reservedWidth + 22 + 2 end
             
             frame.Name:ClearAllPoints()
             frame.Name:SetPoint("LEFT", frame, "LEFT", 0, centerY)
             
             if showBind and frame.guiBindText then
                 frame.guiBindText:Show()
                 frame.guiBindText:ClearAllPoints()
                 -- Anchor BindText to the right limit
                 frame.guiBindText:SetPoint("RIGHT", frame, "RIGHT", -reservedWidth, centerY)
                 
                 frame.Name:SetPoint("RIGHT", frame.guiBindText, "LEFT", -5, 0)
             else
                 if frame.guiBindText then frame.guiBindText:Hide() end
                 -- Anchor Name to the right limit
                 frame.Name:SetPoint("RIGHT", frame, "RIGHT", -reservedWidth, centerY)
             end
        end
    end
    
    local r, g, b = GetItemQualityColor(quality or 1)
    
    if frame.Timer then
        frame.Timer:SetStatusBarColor(r, g, b, 1)
        -- Also update the timer background if we want it to match or be darker
        if frame.TimerBg then frame.TimerBg:SetVertexColor(r * 0.3, g * 0.3, b * 0.3, 1) end
    end
    
    if frame.IconBorder then
        frame.IconBorder:SetBackdropBorderColor(r, g, b, 1)
    end
end

function Loot:RefreshRolls()
    for i = 1, NUM_GROUP_LOOT_FRAMES or 4 do
        local frame = _G["GroupLootFrame"..i]
        if frame and frame:IsShown() then
            UpdateGroupLootStyle(frame)
            OnGroupLootShow(frame) -- Refreshes colors/text logic too
        end
    end
    -- Update Preview Mover if active
    if self.rollMover and self.rollMover:IsShown() then
         self:ToggleRollMover() -- Hide
         self:ToggleRollMover() -- Show (reloads settings)
    end
end

function Loot:ToggleRollMover(forceState)
    local shouldShow = not (self.rollMover and self.rollMover:IsShown())
    if forceState ~= nil then shouldShow = forceState end

    if not shouldShow then
        if self.rollMover then
            self.rollMover:Hide()
            self.rollMover = nil
        end
        return
    end

    if self.rollMover then return end -- Already shown

    local db = GetDB()
    if not db or not db.lootRoll then return end

    -- Fix Memory Leak: Reuse existing frame if available
    local f = _G["GravityUI_LootRollMover"]
    if not f then
        f = CreateFrame("Frame", "GravityUI_LootRollMover", UIParent) -- Removed BackdropTemplate
        f:SetFrameStrata("DIALOG")
        f:SetClampedToScreen(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relPoint, x, y = self:GetPoint()
            db.lootRoll.position = { point = point, relPoint = relPoint, x = x, y = y }
        end)
        
        -- Performance: Width is set on Show/Refresh rather than per-frame OnUpdate
        -- No OnUpdate needed here - width is static and controlled by Settings
    end
    
    -- Always update properties on Show
    f:SetSize(db.lootRoll.width, db.lootRoll.height)
    if db.lootRoll.position then
        local p = db.lootRoll.position
        f:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
    
    self.rollMover = f
    self.rollMover:Show()

    -- Visual Config
    -- Visual Config
    local barHeight = db.lootRoll.timerHeight or 8
    local btnSize = 22 
    local iconSize = db.lootRoll.height or 30
    
    -- Helper to create a single preview row
    local function CreatePreviewRow(parent, index, data)
        local pName = "previewRow"..index
        local p = parent[pName]
        
        if not p then
            p = CreateFrame("Frame", nil, parent) 
            p:SetSize(db.lootRoll.width, db.lootRoll.height)
            parent[pName] = p
        end
        p:Show()
        
        -- Row Background (Dynamic)
        if not p.rowBg then
            p.rowBg = p:CreateTexture(nil, "BACKGROUND")
            p.rowBg:SetAllPoints()
        end
        if db.lootRoll.enableBackgroundColor then
            p.rowBg:Show()
            if db.lootRoll.backgroundColor and #db.lootRoll.backgroundColor >= 3 then
                p.rowBg:SetColorTexture(unpack(db.lootRoll.backgroundColor))
            else
                p.rowBg:SetColorTexture(0, 0, 0, 0.5)
            end
        else
            p.rowBg:Hide()
        end
        
        -- Position based on Grow Direction
        p:ClearAllPoints()
        local dir = db.lootRoll.growDirection or "DOWN"
        local spacing = db.lootRoll.spacing or 5
        
        if index == 1 then
            p:SetPoint("TOP", parent, "TOP", 0, 0)
        else
            local prev = parent["previewRow"..(index-1)]
            if dir == "UP" then
                p:SetPoint("BOTTOM", prev, "TOP", 0, spacing)
            else
                p:SetPoint("TOP", prev, "BOTTOM", 0, -spacing)
            end
        end
        
        -- Timer Bar Background (Dark Trough)
        if not p.timerBg then
             p.timerBg = p:CreateTexture(nil, "BACKGROUND")
             p.timerBg:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 0)
             p.timerBg:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
             p.timerBg:SetHeight(barHeight)
             p.timerBg:SetTexture(GetStatusbarTexture(db.lootRoll.texture))
             p.timerBg:SetVertexColor(0.1, 0.1, 0.1, 1) 
        else
             p.timerBg:Show()
             p.timerBg:SetVertexColor(0.1, 0.1, 0.1, 1)
        end

        -- Timer Bar (Status)
        if not p.statusBar then
            p.statusBar = CreateFrame("StatusBar", nil, p)
            p.statusBar:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 0)
            p.statusBar:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
            p.statusBar:SetHeight(barHeight)
            p.statusBar:SetStatusBarTexture(GetStatusbarTexture(db.lootRoll.texture))
        end
        p.statusBar:SetStatusBarColor(unpack(data.color))
        p.statusBar:SetMinMaxValues(0, 1)
        p.statusBar:SetValue(data.time or 1)
        
        -- Icon Button (Interactive)
        if not p.iconBtn then
             p.iconBtn = CreateFrame("Button", nil, p)
             p.iconBtn:SetSize(iconSize, iconSize)
             p.iconBtn:SetPoint("LEFT", p, "LEFT", -iconSize - 5, 0)
             p.iconBtn:EnableMouse(true)
             p.iconBtn:RegisterForClicks("AnyUp")
             
             p.icon = p.iconBtn:CreateTexture(nil, "ARTWORK")
             p.icon:SetAllPoints()
        end
        p.icon:SetTexture(data.icon)
        
        -- Item Level on Icon
        if not p.ilvl then
             p.ilvl = p.iconBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
             p.ilvl:SetFont(GameFontNormal:GetFont(), 10, "OUTLINE")
             p.ilvl:SetTextColor(1, 0.8, 0)
        end
        p.ilvl:ClearAllPoints()
        p.ilvl:SetPoint("BOTTOM", p.iconBtn, "BOTTOM", 0, 1)
        p.ilvl:SetText(data.ilvl or "")

        -- Tooltip Script
        p.iconBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if data.itemID then
                GameTooltip:SetHyperlink("item:"..data.itemID)
            else
                GameTooltip:SetText(data.name)
            end
            GameTooltip:Show()
        end)
        p.iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        -- Icon Border (Quality)
        if not p.iconBorder then
            p.iconBorder = CreateFrame("Frame", nil, p.iconBtn, "BackdropTemplate")
            p.iconBorder:SetPoint("TOPLEFT", p.iconBtn, "TOPLEFT", -1, 1)
            p.iconBorder:SetPoint("BOTTOMRIGHT", p.iconBtn, "BOTTOMRIGHT", 1, -1)
            p.iconBorder:SetBackdrop({
                 edgeFile = "Interface\\Buttons\\WHITE8x8",
                 edgeSize = 1,
            })
        end
        p.iconBorder:SetBackdropBorderColor(unpack(data.color))
        
        -- Background Texture
        if not p.guiBackground then
            p.guiBackground = p:CreateTexture(nil, "BACKGROUND")
            p.guiBackground:SetAllPoints()
            p.guiBackground:SetColorTexture(0, 0, 0, 0.5)
        end
        
        if db.lootRoll.enableBackgroundColor then
            p.guiBackground:Show()
            if db.lootRoll.backgroundColor then
                p.guiBackground:SetColorTexture(unpack(db.lootRoll.backgroundColor))
            end
        else
            p.guiBackground:Hide()
        end

        -- Name (Aligned to Bar Start)
        if not p.name then
             p.name = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
             -- User: "Not left aligned with timer bar". Changed offset from 10 to 0.
             p.name:SetPoint("LEFT", p, "LEFT", 0, 0)
             p.name:SetTextColor(1, 1, 1)
        end
        p.name:SetText(data.name)
        
        -- Buttons (Raised slightly above bar)
        local btnY = barHeight + 4 
        
        -- 1. Pass
        if not p.btnPass then
            p.btnPass = p:CreateTexture(nil, "OVERLAY")
            p.btnPass:SetSize(btnSize, btnSize)
            p.btnPass:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -5, btnY)
            p.btnPass:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        end
        
        -- 2. Transmog
        if not p.btnTransmog then
            p.btnTransmog = p:CreateTexture(nil, "OVERLAY")
            p.btnTransmog:SetSize(btnSize, btnSize)
            p.btnTransmog:SetPoint("RIGHT", p.btnPass, "LEFT", -2, 0)
            -- FIX: User says "Transmog item missing completely". 
            -- Using a reliable Icon ID (Ethereal / Trans mog concept) to guarantee visibility.
            p.btnTransmog:SetTexture(132060) -- Interface\Icons\Inv_Ethereal_Helmet
        end

        -- 3. Greed
        if not p.btnGreed then
            p.btnGreed = p:CreateTexture(nil, "OVERLAY")
            p.btnGreed:SetSize(btnSize, btnSize)
            p.btnGreed:SetPoint("RIGHT", p.btnTransmog, "LEFT", -2, 0)
            p.btnGreed:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")
        end

        -- 4. Need
        if not p.btnNeed then
            p.btnNeed = p:CreateTexture(nil, "OVERLAY")
            p.btnNeed:SetSize(btnSize, btnSize)
            p.btnNeed:SetPoint("RIGHT", p.btnGreed, "LEFT", -2, 0)
            p.btnNeed:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
        end
        
        if data.needDisabled then
             p.btnNeed:SetDesaturated(true)
             p.btnNeed:SetVertexColor(0.6, 0.6, 0.6)
        else
             p.btnNeed:SetDesaturated(false)
             p.btnNeed:SetVertexColor(1, 1, 1)
        end
        
        -- Name (Aligned to Bar Start, with Truncation)
        if not p.name then
             p.name = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
             p.name:SetPoint("LEFT", p, "LEFT", 0, barHeight / 2) -- Sync with Live
        end
        
        -- Apply Font Settings
        local fontName = db.lootRoll.nameFont or "Gravity"
        local fontPath = (LSM and LSM:Fetch("font", fontName)) or "Fonts\\FRIZQT__.TTF"
        local fontSize = db.lootRoll.nameFontSize or 12
        local fontOutline = db.lootRoll.nameFontOutline or "OUTLINE"
        
        p.name:SetFont(fontPath, fontSize, fontOutline)
        
        if db.lootRoll.nameFontColor then
             p.name:SetTextColor(unpack(db.lootRoll.nameFontColor))
        else
             p.name:SetTextColor(1, 1, 1)
        end
        
        p.name:SetJustifyH("LEFT")
        p.name:SetWordWrap(false)
        p.name:SetNonSpaceWrap(false)
        p.name:SetText(data.name)
        
        -- Bind Text (BoP/BoE)
        if not p.bindText then
             p.bindText = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
             p.bindText:SetFont(GameFontNormal:GetFont(), 10, "OUTLINE")
             -- Anchor handled below
        end
        
        -- Dynamic Anchoring (Decoupled Sync)
        local centerY = barHeight / 2
        -- Calculate reserved width (Standard 4 buttons + spacing)
        -- 5 (edge) + 22(Pass) + 2 + 22(Tm) + 2 + 22(Greed) + 2 + 22(Need) = 99
        local reservedWidth = 99
        
        p.name:ClearAllPoints()
        p.name:SetPoint("LEFT", p, "LEFT", 0, centerY)
        
        if data.bind then
            p.bindText:ClearAllPoints()
            p.bindText:SetPoint("RIGHT", p, "RIGHT", -reservedWidth, centerY)
            p.bindText:SetText(data.bind)
            if data.bindColor then
                p.bindText:SetTextColor(unpack(data.bindColor))
            else
                p.bindText:SetTextColor(0.5, 0.5, 0.5)
            end
            p.bindText:Show()
            
            -- Name ends at BindText
            p.name:SetPoint("RIGHT", p.bindText, "LEFT", -5, 0)
        else
            p.bindText:Hide()
            -- Name ends at reserved width
            p.name:SetPoint("RIGHT", p, "RIGHT", -reservedWidth, centerY)
        end    
    end

    -- Define 3 sample states
    -- Create 3 Preview Rows inside the Mover Frame
    -- FIX: Use valid Texture FileIDs for icons, not ItemIDs
    CreatePreviewRow(f, 1, {
         name = "Thunderfury",
         itemID = 19019,
         icon = 135339, -- Inv_Sword_39 (Thunderfury texture)
         color = {1, 0.5, 0}, 
         ilvl = "13",
         -- bind = nil, -- BoP hidden
         time = 1.0,
         need = "1", greed = "0", transmog = "0", pass = "0",
         needDisabled = false
    })
    
    CreatePreviewRow(f, 2, {
         name = "Example Epic",
         itemID = 19364, -- Ashkandi
         icon = 133966, -- Inv_Sword_04 (Ashkandi texture)
         color = {0.64, 0.21, 0.93}, 
         bind = "|cff1eff00BoE|r",
         ilvl = "81",
         time = 0.6,
         need = "1", greed = "4", transmog = "1", pass = "2",
         needDisabled = true
    })
    
    CreatePreviewRow(f, 3, {
         name = "Rare Item",
         itemID = 12345, -- Placeholder
         icon = 132060, -- Inv_Ethereal_Helmet
         color = {0, 0.44, 0.87},
         ilvl = "55",
         -- bind = nil, -- BoP hidden
         time = 0.3,
         need = "0", greed = "1", transmog = "0", pass = "0",
         needDisabled = false 
    })
    
    -- Cleanup unused rows if any (e.g. if we had 4 before)
    if f.previewRow4 then f.previewRow4:Hide() end

    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        db.lootRoll.position = { point = p, relPoint = rp, x = x, y = y }
        Loot:UpdateRollPositions()
    end)
    
    -- Apply Standard Edit Mode Style
    if ns.Movers and ns.Movers.ApplyEditModeStyle then
        ns.Movers:ApplyEditModeStyle(f, forceState == true)
    end
    
    f:Show()
    self.rollMover = f
end

function Loot:ResetRollPosition()
    local db = GetDB()
    if db and db.lootRoll then db.lootRoll.position = nil end
    if self.rollMover then self.rollMover:ClearAllPoints(); self.rollMover:SetPoint("CENTER", 0, 200) end
    Loot:UpdateRollPositions()
end

function Loot:UpdateRollPositions()
    local db = GetDB()
    if not db or not db.lootRoll then return end

    -- Layout Settings
    local dir = db.lootRoll.growDirection or "DOWN"
    local spacing = db.lootRoll.spacing or 5
    local width = db.lootRoll.width or 320
    
    -- Anchor Point (Mover or Saved Position)
    local anchor = self.rollMover or UIParent
    local point, relativeTo, relativePoint, x, y = "CENTER", UIParent, "CENTER", 0, 200
    
    if db.lootRoll.position then
        local p = db.lootRoll.position
        -- If mover is hidden, we use saved config. If mover is shown, we use Mover's current pos.
        if not self.rollMover then
             point, relativeTo, relativePoint, x, y = p.point, UIParent, p.relPoint, p.x, p.y
        else
             point, relativeTo, relativePoint, x, y = self.rollMover:GetPoint()
        end
    end
    
    -- Blizzard GroupLootContainer Management
    -- We want to completely override its layout logic.
    local container = _G.GroupLootContainer
    if container then
        container:EnableMouse(false)
        container:SetSize(1, 1) 
        container:ClearAllPoints()
        -- Move it off-screen or hide it conceptually so it doesn't interfere, 
        -- BUT we need it visible for the frames to be shown? 
        -- Actually GroupLootFrame1..4 are children of UIParent usually (or re-parented to Container).
        -- Let's check parentage. Usually they are UIParent.
        -- We just need to position the frames ourselves.
        
        -- To prevent Blizzard from re-anchoring them, we might need to hook/overwrite GroupLootContainer_Update?
        -- We already hooked it to call this function.
        -- So essentially, we just re-do the anchoring *after* Blizzard does it.
    end

    local lastFrame = nil
    
    for i = 1, NUM_GROUP_LOOT_FRAMES or 4 do
        local frame = _G["GroupLootFrame"..i]
        if frame and frame:IsShown() then
            frame:ClearAllPoints()
            frame:SetWidth(width) -- Enforce Width
            
            if not lastFrame then
                -- First Frame: Anchor to Position
                if self.rollMover and self.rollMover:IsShown() then
                     -- Anchor to Mover
                     if dir == "UP" then
                         frame:SetPoint("BOTTOM", self.rollMover, "TOP", 0, spacing)
                     else
                         frame:SetPoint("TOP", self.rollMover, "BOTTOM", 0, -spacing)
                     end
                else
                     -- Anchor to Saved Position
                     frame:SetPoint(point, relativeTo, relativePoint, x, y)
                end
            else
                -- Subsequent Frames: Anchor to Last Frame
                if dir == "UP" then
                    frame:SetPoint("BOTTOM", lastFrame, "TOP", 0, spacing)
                else
                    frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, -spacing)
                end
            end
            
            lastFrame = frame
        end
    end
end

-------------------------------------------------------------------------------
-- BONUS ROLL FRAME
-------------------------------------------------------------------------------
local function SkinBonusRollFrame()
    local f = _G.BonusRollFrame
    if not f then return end
    if f.IsForbidden and f:IsForbidden() then return end

    local db = GetDB()
    if not db or not db.lootRoll or not db.lootRoll.enabled then return end
    -- Respect the 'Skin Bonus Roll Window' toggle (default true if key missing)
    if db.lootRoll.skinBonusRoll == false then return end

    local sr, sg, sb = GetAccent()
    local bgr, bgg, bgb, bga = ns.GetThemeBgColor()

    local prompt = f.PromptFrame
    if not prompt then return end

    -- 1. Hide only specifically-named chrome textures/frames (safe — no accidental hiding)
    local function HideNamedChrome(frame)
        for _, key in ipairs({"NineSlice","Bg","Background","Border","FrameDecor","Shadow","GlowOverlay"}) do
            local obj = frame[key]
            if obj and obj.SetAlpha then obj:SetAlpha(0) end
        end
    end
    HideNamedChrome(f)
    HideNamedChrome(prompt)

    -- 2. BACKDROP: parented to UIParent (sibling of BonusRollFrame), anchored to prompt.
    --    Must NOT be a child of f: child frames ride along with every FrameLevel bump Blizzard
    --    applies (e.g. when GroupLootHistoryFrame opens and reshuffles DIALOG strata), which would
    --    push the backdrop ABOVE the prompt buttons and eat their clicks.
    --    EnableMouse(false) ensures it can never intercept clicks even if level order drifts.
    --    The OnShow hook re-syncs strata + level each time f appears so it always sits just below.
    if not f.guiBackdrop then
        local bd = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        bd:SetPoint("TOPLEFT",     prompt, "TOPLEFT",     0,  0)
        bd:SetPoint("BOTTOMRIGHT", prompt, "BOTTOMRIGHT", 0,  0)
        bd:EnableMouse(false) -- never intercept clicks
        bd:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        bd:Hide()
        f.guiBackdrop = bd

        -- Accent line on the backdrop
        bd.topLine = bd:CreateTexture(nil, "OVERLAY", nil, 7)
        bd.topLine:SetHeight(2)
        bd.topLine:SetPoint("TOPLEFT",  bd, "TOPLEFT",  1, -1)
        bd.topLine:SetPoint("TOPRIGHT", bd, "TOPRIGHT", -1, -1)
        bd.topLine:SetTexture("Interface\\Buttons\\WHITE8x8")

        -- Re-sync strata + level each time f shows so we always track f's current position.
        -- This guards against GroupLootHistoryFrame (and others) reshuffling DIALOG levels.
        f:HookScript("OnShow", function(self)
            if not self.guiBackdrop then return end
            local bd2 = self.guiBackdrop
            local strata = self:GetFrameStrata()
            local level  = math.max(1, self:GetFrameLevel() - 1)
            pcall(function() bd2:SetFrameStrata(strata) end)
            pcall(function() bd2:SetFrameLevel(level)   end)
            bd2:Show()
        end)
        f:HookScript("OnHide", function(self)
            if self.guiBackdrop then self.guiBackdrop:Hide() end
        end)
    end

    -- Re-sync level now (covers the test command / initial skin path where OnShow already fired)
    pcall(function()
        f.guiBackdrop:SetFrameStrata(f:GetFrameStrata())
        f.guiBackdrop:SetFrameLevel(math.max(1, f:GetFrameLevel() - 1))
    end)

    -- Show backdrop if f is currently shown (e.g. test command)
    if f:IsShown() then f.guiBackdrop:Show() end

    f.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    f.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, 1)
    f.guiBackdrop.topLine:SetVertexColor(sr, sg, sb, 0.85)

    -- 3. GravityUI font on text elements
    local font, size, outline = GetFont()
    for _, fs in ipairs({ prompt.prompt, prompt.currencyName, prompt.rollLabel, prompt.passLabel }) do
        if fs and fs.SetFont then
            pcall(function() fs:SetFont(font, size, outline) end)
        end
    end

    -- 4. Currency icon: clean crop
    if prompt.currencyTexture and prompt.currencyTexture.SetTexCoord then
        pcall(function() prompt.currencyTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92) end)
    end

    -- 5. Button chrome: hide named chrome only, keep dice/pass icon visible
    for _, btn in ipairs({ prompt.rollButton, prompt.passButton }) do
        if btn and not btn.guiSkinned then
            btn.guiSkinned = true
            if btn.NineSlice  then btn.NineSlice:SetAlpha(0)  end
            if btn.Border     then btn.Border:SetAlpha(0)     end
            if btn.Background then btn.Background:SetAlpha(0) end
        end
    end

    -- 6. Buttons: ensure roll/pass are on a high frame level so they're always clickable.
    --    We do NOT call SetFrameStrata() on BonusRollFrame itself – Blizzard internally
    --    clears the frame's anchor points whenever strata is set, even to the same value,
    --    which causes the position to be lost when GroupLootHistoryFrame reshuffles levels.
    --    BonusRollFrame is already on DIALOG by default, so the call was redundant.
    for _, btn in ipairs({ prompt.rollButton, prompt.passButton }) do
        if btn then
            pcall(function()
                btn:SetFrameLevel(math.max(1, f:GetFrameLevel() + 10))
            end)
        end
    end

    f.guiSkinned = true
end

-- Export so styling panel can call it
Loot.SkinBonusRollFrame = SkinBonusRollFrame

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
        
        -- Register with Movers (Lazy Load safe)
        if ns.Movers and ns.Movers.Register then
            ns.Movers:Register("LootWindow", nil, function(frame, enabled) Loot:ToggleMover(enabled) end, "Loot Window")
            ns.Movers:Register("LootRolls", nil, function(frame, enabled) Loot:ToggleRollMover(enabled) end, "Loot Rolls")
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

    -- Loot Rolls (Group Loot)
    if db.lootRoll and db.lootRoll.enabled then
        -- Initial Skinning
        for i = 1, NUM_GROUP_LOOT_FRAMES or 4 do
            local f = _G["GroupLootFrame"..i]
            if f then 
                UpdateGroupLootStyle(f) 
                f:HookScript("OnShow", OnGroupLootShow)
                
                -- Robustness: Add OnUpdate to retry data loading and enforce layout
                f:HookScript("OnUpdate", function(self, elapsed)
                    if not self.gravityUpdateTimer then self.gravityUpdateTimer = 0 end
                    self.gravityUpdateTimer = self.gravityUpdateTimer + elapsed
                    if self.gravityUpdateTimer > 0.2 then
                        self.gravityUpdateTimer = 0
                        -- 1. Enforce Width (Blizzard likes to reset this)
                         local db = GetDB()
                         if db and db.lootRoll and db.lootRoll.width then
                             if self:GetWidth() ~= db.lootRoll.width then
                                 self:SetWidth(db.lootRoll.width)
                             end
                         end
                         
                         -- 2. Retry Ilvl / Link / Color
                         if self.rollID then
                             local link = GetLootRollItemLink(self.rollID)
                             local _, _, _, quality = GetLootRollItemInfo(self.rollID)
                             
                             if quality then
                                 local r, g, b = GetItemQualityColor(quality)
                                 -- Force Border Color
                                 if self.IconBorder then self.IconBorder:SetBackdropBorderColor(r, g, b, 1) end
                                 -- Force Timer Color
                                 if self.Timer then self.Timer:SetStatusBarColor(r, g, b, 1) end
                             end
                             
                             -- Retry Ilvl
                             if self.guiIlvl and link then
                                 local effectiveLevel = GetDetailedItemLevelInfo(link)
                                 local _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, isCrafted = GetItemInfo(link)
                                 
                                 -- Fallback to standard GetItemInfo if detailed fails
                                 if not effectiveLevel then
                                     local _, _, _, ilvl = GetItemInfo(link)
                                     effectiveLevel = ilvl
                                 end

                                 if effectiveLevel then
                                     self.guiIlvl:SetText(effectiveLevel)
                                     self.guiIlvl:Show()
                                 else
                                     -- Try Loading if still nil
                                      if not self.itemLoadingChecked then
                                         self.itemLoadingChecked = true
                                         local item = Item:CreateFromItemLink(link)
                                         item:ContinueOnItemLoad(function()
                                            local level = GetDetailedItemLevelInfo(link) or item:GetCurrentItemLevel()
                                            if level then 
                                                self.guiIlvl:SetText(level) 
                                                self.guiIlvl:Show()
                                            end
                                         end)
                                      end
                                 end
                             end
                             
                             -- Retry Bind Text
                             if self.guiBindText and (not self.guiBindText:GetText() or self.guiBindText:GetText() == "") and link then
                                 local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(link)
                                 if bindType == 2 then 
                                     self.guiBindText:SetText("|cff1eff00BoE|r")
                                 elseif bindType == 3 then
                                     self.guiBindText:SetText("|cff1eff00BoU|r")
                                 end
                             end
                         end
                         
                         -- 3. Enforce Layout Position (Aggressive)
                         -- Only if not moving
                         if not self.isMoving and not (Loot.rollMover and Loot.rollMover:IsShown()) then
                              -- Force layout update to snap any rogue frames back
                              Loot:UpdateRollPositions()
                         end
                    end
                end)
            end
        end

        ------------------------------------------------------------
        -- Hook Container Update to enforce position
        ------------------------------------------------------------
        if _G.GroupLootContainer_Update then
            hooksecurefunc("GroupLootContainer_Update", function()
               Loot:UpdateRollPositions()
            end)
        end
        
        Loot:UpdateRollPositions()
    end

    -- Bonus Roll Frame
    if db.lootRoll and db.lootRoll.enabled then
        if _G.BonusRollFrame then
            SkinBonusRollFrame()
            _G.BonusRollFrame:HookScript("OnShow", SkinBonusRollFrame)
        else
            -- BonusRollFrame is part of Blizzard_BonusRoll in some versions
            local bonusFrame = CreateFrame("Frame")
            bonusFrame:RegisterEvent("ADDON_LOADED")
            bonusFrame:RegisterEvent("BONUS_ROLL_STARTED")
            bonusFrame:SetScript("OnEvent", function(self, event, arg1)
                if event == "ADDON_LOADED" and arg1 == "Blizzard_BonusRoll" then
                    self:UnregisterEvent("ADDON_LOADED")
                end
                if _G.BonusRollFrame then
                    SkinBonusRollFrame()
                    if not _G.BonusRollFrame._guiShowHooked then
                        _G.BonusRollFrame._guiShowHooked = true
                        _G.BonusRollFrame:HookScript("OnShow", SkinBonusRollFrame)
                    end
                    if event ~= "ADDON_LOADED" then
                        self:UnregisterAllEvents()
                    end
                end
            end)
        end
    end
end


-- Test Command
SLASH_GRAVITYLOOTTEST1 = "/gravitytestloot"
SlashCmdList["GRAVITYLOOTTEST"] = function()
    -- Spawn 3 frames to test spacing/growth
    for i = 1, 3 do
        local f = _G["GroupLootFrame"..i]
        if f then
            -- Stop Blizzard scripts
            f:SetScript("OnUpdate", nil)
            f:SetScript("OnShow", nil) 
            f:SetScript("OnEvent", nil)
            
            f.rollID = 100 + i 
            
            f:SetParent(UIParent)
            f:SetFrameStrata("DIALOG")
            f:SetAlpha(1)
            
            f:Show()
            UpdateGroupLootStyle(f)
            
            -- Mock Data
            local texture = 135339 -- Thunderfury
            local name = "Thunderfury, Blessed Blade of the Windseeker"
            local quality = 5 -- Legendary
            local link = "item:19019::::::::80:::::"
            
            if i == 2 then
                texture = 133966 -- Ashkandi
                name = "Ashkandi, Greatsword of the Brotherhood"
                quality = 4 -- Epic
                link = "item:19364::::::::76:::::"
            elseif i == 3 then
                texture = 132060 -- Ethereal
                name = "Strange Dust"
                quality = 3 -- Rare
                link = "item:10940:::::::::::::"
            end
            
            f.gravityLootLink = link

            local r, g, b = GetItemQualityColor(quality)
            
            if f.IconFrame then
                 if f.IconFrame.Icon then f.IconFrame.Icon:SetTexture(texture) end
                 if f.IconBorder then f.IconBorder:SetBackdropBorderColor(r, g, b, 1) end
            end
            
            if f.Name then
                f.Name:SetText(name)
                f.Name:SetTextColor(1, 1, 1) 
            end
            
            if f.Timer then
                f.Timer:SetMinMaxValues(0, 100)
                f.Timer:SetValue(50 + (i*10))
                f.Timer:SetStatusBarColor(r, g, b, 1)
                if f.TimerBg then f.TimerBg:SetVertexColor(r * 0.3, g * 0.3, b * 0.3, 1) end
            end
        end
    end
    
    Loot:UpdateRollPositions()
    print("|cff00ccffGravityUI|r: Test Loot Frames Updated.")
end

-- Bonus Roll Test Command
SLASH_GRAVITYBONUSTEST1 = "/gravitytestbonus"
SlashCmdList["GRAVITYBONUSTEST"] = function()
    local f = _G.BonusRollFrame
    if not f then
        print("|cff00ccffGravityUI|r: BonusRollFrame nicht gefunden.")
        return
    end

    -- Show the frame itself (don't touch children — Blizzard manages their state)
    f:SetAlpha(1)
    f:Show()

    local prompt = f.PromptFrame
    if prompt then
        prompt:Show()
        prompt:SetAlpha(1)

        -- Populate known text/icon fields only
        if prompt.prompt     then pcall(function() prompt.prompt:SetText("Auf Bonus-Loot würfeln?") end) end
        if prompt.currencyName then pcall(function() prompt.currencyName:SetText("Münze des Glücks (x1)") end) end
        if prompt.currencyTexture then pcall(function() prompt.currencyTexture:SetTexture(133784) end) end

        -- Show rollButton and passButton (they may be hidden in default state)
        if prompt.rollButton then pcall(function() prompt.rollButton:Show() end) end
        if prompt.passButton then pcall(function() prompt.passButton:Show() end) end
    end

    -- Apply fresh skinning
    f.guiSkinned = nil
    if f.guiBackdrop then f.guiBackdrop:Hide() end
    SkinBonusRollFrame()

    print("|cff00ccffGravityUI|r: BonusRollFrame Vorschau. Spec-Icon wird erst beim echten Bonus-Roll befüllt.")
end
