local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = ns.Colors

-- Module
ns.Alerts = {}
local Alerts = ns.Alerts

-------------------------------------------------------------------------------
-- CONSTANTS & HELPERS
-------------------------------------------------------------------------------
local ICON_TEX_COORDS = { 0.08, 0.92, 0.08, 0.92 }

local function GetDB()
    if ns.db and ns.db.profile and ns.db.profile.styling then
        return ns.db.profile.styling.alerts
    end
    return nil
end

local function GetFontPath()
    if ns.Styling and ns.Styling.GetFontPath then
        return ns.Styling:GetFontPath()
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function Kill(obj)
    if not obj then return end
    if obj.UnregisterAllEvents then obj:UnregisterAllEvents() end
    if obj.SetAlpha then obj:SetAlpha(0) end
    if obj.Hide then obj:Hide() end
end

local function ForceAlpha(frame, alpha, forced)
    if alpha ~= 1 and forced ~= true then
        frame:SetAlpha(1, true)
    end
end

-------------------------------------------------------------------------------
-- SKINNING HELPERS
-------------------------------------------------------------------------------

local function CreateAlertBackdrop(frame, x1, y1, x2, y2)
    if frame.guiBackdrop then return end
    
    local sr, sg, sb, sa = ns.GetAccentColor()
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
    
    local db = GetDB()
    if db and db.disableThemeColorBackground then
        local c = db.customBackgroundColor
        if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
    else
        local themeBg = ns.db.profile.general.themeBgColor
        if themeBg then bgr, bgg, bgb, bga = themeBg[1], themeBg[2], themeBg[3], themeBg[4] end
    end
    
    local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", x1 or 0, y1 or 0)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", x2 or 0, y2 or 0)
    bg:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
    
    bg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bg:SetBackdropColor(bgr, bgg, bgb, bga)
    bg:SetBackdropBorderColor(sr, sg, sb, sa)
    
    frame.guiBackdrop = bg
end

local function StyleIcon(icon, parent, qualityColor)
    if not icon then return end
    icon:SetTexCoord(unpack(ICON_TEX_COORDS))
    
    if not icon.guiBorder then
        local sr, sg, sb, sa = ns.GetAccentColor()
        local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        border:SetSize(icon:GetWidth() + 4, icon:GetHeight() + 4)
        border:SetPoint("CENTER", icon, "CENTER")
        border:SetBackdrop({
            bgFile = nil,
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        if qualityColor then
            border:SetBackdropBorderColor(qualityColor.r or qualityColor[1], qualityColor.g or qualityColor[2], qualityColor.b or qualityColor[3], 1)
        else
            border:SetBackdropBorderColor(sr, sg, sb, sa)
        end
        icon.guiBorder = border
    end
end

-------------------------------------------------------------------------------
-- SKINNING FUNCTIONS
-------------------------------------------------------------------------------

local function SkinAchievementAlert(frame)
    if not frame or frame.guiSkinned then return end
    frame:SetAlpha(1)
    if not frame.guiHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.guiHooked = true
    end
    CreateAlertBackdrop(frame, -2, -6, -2, 6)
    Kill(frame.Background)
    Kill(frame.glow)
    Kill(frame.shine)
    if frame.Icon and frame.Icon.Texture then
        StyleIcon(frame.Icon.Texture, frame)
    end
    
    local sr, sg, sb, sa = ns.GetAccentColor()
    local db = GetDB()
    local tr, tg, tb, ta = sr, sg, sb, sa
    
    if db and db.disableThemeColorFont then
        local c = db.customFontColor
        if c then
            tr, tg, tb, ta = c[1], c[2], c[3], c[4]
        end
    end

    if frame.Name then frame.Name:SetTextColor(tr, tg, tb, ta) end
    if frame.Label then frame.Label:SetTextColor(tr, tg, tb, ta) end
    if frame.GuildName then frame.GuildName:SetTextColor(tr, tg, tb, ta) end
    
    frame.guiSkinned = true
end

local function SkinLootWonAlert(frame)
    if not frame or frame.guiSkinned then return end
    frame:SetAlpha(1)
    if not frame.guiHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.guiHooked = true
    end
    Kill(frame.Background)
    Kill(frame.glow)
    Kill(frame.shine)
    Kill(frame.BGAtlas)
    
    local lootItem = frame.lootItem or frame
    local qualityColor = nil
    local hyperlink = frame.hyperlink or (lootItem and lootItem.hyperlink)
    if hyperlink then
        local quality = C_Item.GetItemQualityByID(hyperlink)
        if quality and quality >= 1 then
            local r, g, b = GetItemQualityColor(quality)
            qualityColor = { r = r, g = g, b = b }
        end
    end
    StyleIcon(lootItem.Icon, frame, qualityColor)
    
    if not frame.guiBackdrop and lootItem.Icon.guiBorder then
        local sr, sg, sb, sa = ns.GetAccentColor()
        local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
        
        local db = GetDB()
        if db and db.disableThemeColorBackground then
            local c = db.customBackgroundColor
            if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
        else
             local themeBg = ns.db.profile.general.themeBgColor
             if themeBg then bgr, bgg, bgb, bga = themeBg[1], themeBg[2], themeBg[3], themeBg[4] end
        end

        local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        bg:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        bg:SetPoint("TOPLEFT", lootItem.Icon.guiBorder, "TOPLEFT", -4, 4)
        bg:SetPoint("BOTTOMRIGHT", lootItem.Icon.guiBorder, "BOTTOMRIGHT", 180, -4)
        bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        bg:SetBackdropColor(bgr, bgg, bgb, bga)
        bg:SetBackdropBorderColor(sr, sg, sb, sa)
        frame.guiBackdrop = bg
    end
    
    local sr, sg, sb, sa = ns.GetAccentColor()
    local db = GetDB()
    local tr, tg, tb, ta = sr, sg, sb, sa
    
    if db and db.disableThemeColorFont then
        local c = db.customFontColor
        if c then
            tr, tg, tb, ta = c[1], c[2], c[3], c[4]
        end
    end
    
    if frame.Label then frame.Label:SetTextColor(tr, tg, tb, ta) end
    
    frame.guiSkinned = true
end

local function SkinDungeonCompletionAlert(frame)
    if not frame or frame.guiSkinned then return end
    frame:SetAlpha(1)
    if not frame.guiHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.guiHooked = true
    end
    CreateAlertBackdrop(frame, -2, -6, -2, 6)
    Kill(frame.glowFrame)
    Kill(frame.shine)
    Kill(frame.raidArt)
    Kill(frame.dungeonArt1)
    if frame.dungeonTexture then
        StyleIcon(frame.dungeonTexture, frame)
    end
    
    local sr, sg, sb, sa = ns.GetAccentColor()
    local db = GetDB()
    local tr, tg, tb, ta = sr, sg, sb, sa
    
    if db and db.disableThemeColorFont then
        local c = db.customFontColor
        if c then
            tr, tg, tb, ta = c[1], c[2], c[3], c[4]
        end
    end
    
    if frame.dungeonName then frame.dungeonName:SetTextColor(tr, tg, tb, ta) end
    if frame.instanceName then frame.instanceName:SetTextColor(tr, tg, tb, ta) end
    
    frame.guiSkinned = true
end

-------------------------------------------------------------------------------
-- MOVER LOGIC
-------------------------------------------------------------------------------

local alertHolder = nil
local alertMover = nil
local toastHolder = nil
local toastMover = nil

function Alerts:SavePosition(type, point, relPoint, x, y)
    local db = GetDB()
    if db then
        if type == "alert" then db.alertPosition = { point = point, relPoint = relPoint, x = x, y = y }
        else db.toastPosition = { point = point, relPoint = relPoint, x = x, y = y } end
    end
end

function Alerts:ResetPositions()
    local db = GetDB()
    if db then
        db.alertPosition = nil
        db.toastPosition = nil
    end
    if alertHolder then
        alertHolder:ClearAllPoints()
        alertHolder:SetPoint("TOP", UIParent, "TOP", 0, -20)
    end
    if toastHolder then
        toastHolder:ClearAllPoints()
        toastHolder:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end
    
    if AlertFrame then
        AlertFrame:ClearAllPoints()
        if alertHolder then 
            AlertFrame:SetPoint("TOP", alertHolder, "TOP") 
        end
        AlertFrame:UpdateAnchors()
    end
    
    if EventToastManagerFrame and EventToastManagerFrame.UpdateAnchor then 
        EventToastManagerFrame:UpdateAnchor() 
    end
end

function Alerts:CreateHolders()
    if alertHolder then return end
    
    -- Alert Holder
    alertHolder = CreateFrame("Frame", "GravityUIAlertHolder", UIParent)
    alertHolder:SetSize(180, 20)
    local pos = (GetDB() or {}).alertPosition
    if pos then alertHolder:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else alertHolder:SetPoint("TOP", UIParent, "TOP", 0, -20) end
    alertHolder:SetMovable(true)
    
    -- Toast Holder
    toastHolder = CreateFrame("Frame", "GravityUIToastHolder", UIParent)
    toastHolder:SetSize(300, 20)
    local tpos = (GetDB() or {}).toastPosition
    if tpos then toastHolder:SetPoint(tpos.point, UIParent, tpos.relPoint, tpos.x, tpos.y)
    else toastHolder:SetPoint("TOP", UIParent, "TOP", 0, -150) end
    toastHolder:SetMovable(true)
end

local function ReplaceSubSystemAnchors(subSystem)
    if not subSystem or subSystem.guiHooked then return end
    
    subSystem.AdjustAnchors = function(self, relativeAlert)
        -- FORCE the root anchor to be our holder
        if alertHolder and (not relativeAlert or relativeAlert == AlertFrame or relativeAlert == UIParent or (relativeAlert.GetName and relativeAlert:GetName() == "UIParent")) then
            relativeAlert = alertHolder
        end
        
        -- Get growth direction config
        local db = GetDB()
        local growDown = not db or (db.alertGrowDirection == "DOWN")
        local point = growDown and "TOP" or "BOTTOM"
        local relPoint = growDown and "BOTTOM" or "TOP"
        local offset = growDown and -10 or 10
        local yOffset = (db and db.alertYOffset) or 0
        
        -- Re-implement Blizzard's basic logic but with our forced direction
        if self.alertFramePool then
            for alert in self.alertFramePool:EnumerateActive() do
                alert:ClearAllPoints()
                -- First alert in chain takes our Y offset
                local finalY = (relativeAlert == alertHolder) and (offset + yOffset) or offset
                alert:SetPoint(point, relativeAlert, relPoint, 0, finalY)
                relativeAlert = alert
            end
        elseif self.alertFrame and self.alertFrame:IsShown() then
            self.alertFrame:ClearAllPoints()
            local finalY = (relativeAlert == alertHolder) and (offset + yOffset) or offset
            self.alertFrame:SetPoint(point, relativeAlert, relPoint, 0, finalY)
            relativeAlert = self.alertFrame
        end
        
        return relativeAlert
    end
    subSystem.guiHooked = true
end

function Alerts:ToggleMovers()
    if not alertHolder then Alerts:CreateHolders() end

    if not alertMover then
        -- Alert Mover Overlay
        alertMover = CreateFrame("Frame", nil, alertHolder, "BackdropTemplate")
        alertMover:SetAllPoints()
        alertMover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        alertMover:SetBackdropColor(0.2, 0.8, 0.8, 0.5)
        alertMover:SetBackdropBorderColor(0.2, 0.8, 0.8, 1)
        alertMover:EnableMouse(true)
        alertMover:RegisterForDrag("LeftButton")
        alertMover:SetScript("OnDragStart", function() alertHolder:StartMoving() end)
        alertMover:SetScript("OnDragStop", function(self)
            alertHolder:StopMovingOrSizing()
            local p, _, rp, x, y = alertHolder:GetPoint()
            Alerts:SavePosition("alert", p, rp, x, y)
            if AlertFrame then AlertFrame:UpdateAnchors() end
        end)
        
        local alertText = alertMover:CreateFontString(nil, "OVERLAY")
        alertText:SetFont(GetFontPath(), 11, "OUTLINE")
        alertText:SetPoint("CENTER")
        alertText:SetText("Alerts")
        alertText:SetTextColor(1, 1, 1)

        -- Toast Mover Overlay
        toastMover = CreateFrame("Frame", nil, toastHolder, "BackdropTemplate")
        toastMover:SetAllPoints()
        toastMover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        toastMover:SetBackdropColor(0.8, 0.6, 0.2, 0.5)
        toastMover:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
        toastMover:EnableMouse(true)
        toastMover:RegisterForDrag("LeftButton")
        toastMover:SetScript("OnDragStart", function() toastHolder:StartMoving() end)
        toastMover:SetScript("OnDragStop", function(self)
            toastHolder:StopMovingOrSizing()
            local p, _, rp, x, y = toastHolder:GetPoint()
            Alerts:SavePosition("toast", p, rp, x, y)
            if EventToastManagerFrame and EventToastManagerFrame.UpdateAnchor then EventToastManagerFrame:UpdateAnchor() end
        end)

        local toastText = toastMover:CreateFontString(nil, "OVERLAY")
        toastText:SetFont(GetFontPath(), 11, "OUTLINE")
        toastText:SetPoint("CENTER")
        toastText:SetText("Toasts")
        toastText:SetTextColor(1, 1, 1)
    end

    if alertMover:IsShown() then
        alertMover:Hide()
        toastMover:Hide()
    else
        alertMover:Show()
        toastMover:Show()
    end
end

function Alerts:Test()
    PlaySound(SOUNDKIT.RAID_WARNING)
    
    if AlertFrame then
        AlertFrame:ClearAllPoints()
        if alertHolder then AlertFrame:SetPoint("TOP", alertHolder, "TOP") end
        AlertFrame:UpdateAnchors()
    end

    -- Trigger alerts
    if AchievementAlertSystem then AchievementAlertSystem:AddAlert(6) end
    if LootAlertSystem then
        local itemLink = "|cffa335ee|Hitem:19019::::::::::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r"
        LootAlertSystem:AddAlert(itemLink, 1, nil, nil, nil, nil, nil, nil)
    end
    
    -- Force re-anchor after alerts are created
    C_Timer.After(0.2, function()
        if AlertFrame then AlertFrame:UpdateAnchors() end
    end)

    -- 3. Fake Toast
    if toastHolder then
        local fakeToast = CreateFrame("Frame", "GravityUITestToast", UIParent, "BackdropTemplate")
        fakeToast:SetSize(250, 50)
        local db = GetDB()
        local growUp = (db and db.toastGrowDirection == "UP")
        local yOffset = (db and db.toastYOffset) or 0
        fakeToast:ClearAllPoints()
        fakeToast:SetPoint(growUp and "BOTTOM" or "TOP", toastHolder, growUp and "BOTTOM" or "TOP", 0, (growUp and 10 or -10) + yOffset)
        
        local sr, sg, sb, sa = ns.GetAccentColor()
        local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
        if db and db.disableThemeColorBackground then
             local c = db.customBackgroundColor
             if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
        else
             local themeBg = ns.db.profile.general.themeBgColor
             if themeBg then bgr, bgg, bgb, bga = themeBg[1], themeBg[2], themeBg[3], themeBg[4] end
        end
        
        fakeToast:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        fakeToast:SetBackdropColor(bgr, bgg, bgb, bga)
        fakeToast:SetBackdropBorderColor(sr, sg, sb, sa)
        
        local text = fakeToast:CreateFontString(nil, "OVERLAY")
        text:SetFont(GetFontPath(), 14, "OUTLINE")
        text:SetPoint("CENTER", 0, 5)
        text:SetText("Test Toast Notification")
        
        local sub = fakeToast:CreateFontString(nil, "OVERLAY")
        sub:SetFont(GetFontPath(), 11, "OUTLINE")
        sub:SetPoint("TOP", text, "BOTTOM", 0, -4)
        sub:SetText("Verifying Position & Style")
        sub:SetTextColor(1, 0.8, 0)
        
        if db and db.disableThemeColorFont then
            local c = db.customFontColor
            if c then text:SetTextColor(c[1], c[2], c[3], c[4]) end
        end
        
        fakeToast:SetAlpha(0)
        UIFrameFadeIn(fakeToast, 0.5, 0, 1)
        C_Timer.After(4, function()
            UIFrameFadeOut(fakeToast, 1, 1, 0)
            C_Timer.After(1, function() fakeToast:Hide() end)
        end)
    end
end

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

function Alerts:Initialize()
    local db = GetDB()
    if not db or not db.enabled then return end
    
    Alerts:CreateHolders()

    if AchievementAlertSystem then hooksecurefunc(AchievementAlertSystem, "setUpFunction", SkinAchievementAlert) end
    if DungeonCompletionAlertSystem then hooksecurefunc(DungeonCompletionAlertSystem, "setUpFunction", SkinDungeonCompletionAlert) end
    if LootAlertSystem then hooksecurefunc(LootAlertSystem, "setUpFunction", SkinLootWonAlert) end

    if AlertFrame then
        for _, sub in ipairs(AlertFrame.alertFrameSubSystems) do ReplaceSubSystemAnchors(sub) end
        hooksecurefunc(AlertFrame, "AddAlertFrameSubSystem", function(_, sub) ReplaceSubSystemAnchors(sub) end)
        
        -- Aggressive container anchoring
        hooksecurefunc(AlertFrame, "SetPoint", function(self, point, relTo, relPoint, x, y)
            if alertHolder and (not relTo or relTo ~= alertHolder) then
                self:ClearAllPoints()
                self:SetPoint("TOP", alertHolder, "TOP")
            end
        end)
        
        if alertHolder then
            AlertFrame:ClearAllPoints()
            AlertFrame:SetPoint("TOP", alertHolder, "TOP")
        end
    end
    
    if EventToastManagerFrame then
        hooksecurefunc(EventToastManagerFrame, "UpdateAnchor", function(self)
            if toastHolder then
                local db = GetDB()
                local growUp = (db and db.toastGrowDirection == "UP")
                local yOffset = (db and db.toastYOffset) or 0
                self:ClearAllPoints()
                self:SetPoint(growUp and "BOTTOM" or "TOP", toastHolder, growUp and "BOTTOM" or "TOP", 0, yOffset)
            end
        end)
    end
end
