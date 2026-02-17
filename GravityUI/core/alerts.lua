local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = ns.Colors

-- Module
ns.Alerts = {}
local Alerts = ns.Alerts

-------------------------------------------------------------------------------
-- POLYFILLS
-------------------------------------------------------------------------------
if not AchievementShield_SetPoints then
    function AchievementShield_SetPoints(points, anchorFrame)
        if not anchorFrame then return end
        anchorFrame:SetText(points)
    end
end

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
    -- Force color after a tick because Blizzard resets it
    C_Timer.After(0.05, function() 
        if frame.Label then frame.Label:SetTextColor(1, 1, 1, 1) end
        
        -- Fallback: Bruteforce search for "Achievement Earned" text
        for _, region in ipairs({frame:GetRegions()}) do
            if region:IsObjectType("FontString") then
                local text = region:GetText()
                if text == "Achievement Earned" or text == ACHIEVEMENT_TITLE then
                     region:SetTextColor(1, 1, 1, 1)
                end
            end
        end
    end)
    
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
    
    if frame.Label then frame.Label:SetTextColor(1, 1, 1, 1) end
    
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
    
    if frame.dungeonName then frame.dungeonName:SetTextColor(1, 1, 1, 1) end
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

function Alerts:ToggleMovers(forceState)
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
        
        -- Default to hidden initially if just created
        alertMover:Hide()
        toastMover:Hide()
    end

    local shouldShow = false
    if forceState ~= nil then
        shouldShow = forceState
    else
        shouldShow = not alertMover:IsShown()
    end

    if shouldShow then
        alertMover:Show()
        toastMover:Show()
        
        -- Apply Standard Edit Mode Style (Blue) if forced, otherwise keep custom colors
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            if forceState == true then
                -- Global Edit Mode: Hide base color, show Overlay
                alertMover:SetBackdropColor(0, 0, 0, 0)
                alertMover:SetBackdropBorderColor(0, 0, 0, 0)
                ns.Movers:ApplyEditModeStyle(alertMover, true)
                
                toastMover:SetBackdropColor(0, 0, 0, 0)
                toastMover:SetBackdropBorderColor(0, 0, 0, 0)
                ns.Movers:ApplyEditModeStyle(toastMover, true)
            else
                -- Manual Mode: Restore Colors, Hide Overlay
                alertMover:SetBackdropColor(0.2, 0.8, 0.8, 0.5)
                alertMover:SetBackdropBorderColor(0.2, 0.8, 0.8, 1)
                ns.Movers:ApplyEditModeStyle(alertMover, false)
                
                toastMover:SetBackdropColor(0.8, 0.6, 0.2, 0.5)
                toastMover:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
                ns.Movers:ApplyEditModeStyle(toastMover, false)
            end
        end
    else
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
             ns.Movers:ApplyEditModeStyle(alertMover, false)
             ns.Movers:ApplyEditModeStyle(toastMover, false)
        end
        alertMover:Hide()
        toastMover:Hide()
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
    
    -- Register with Movers
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("Alerts", alertHolder, function(frame, enabled) Alerts:ToggleMovers(enabled) end, "Alerts Anchor")
        -- Note: ToggleMovers toggles BOTH. We only need to register one "Callback" effectively, or register both frames but handle the callback carefully.
        -- Since ToggleMovers toggles BOTH, registering just "Alerts" and relying on it to toggle Toasts is fine, 
        -- BUT if we want separate movers in the list (if we list them), we might want separate callbacks.
        -- However, `ToggleMovers` implementation couples them. I will stick to coupled for now or register the second one as a dummy or separate if possible.
        -- Actually, Register checks if name exists. I'll register "Toasts" as well, but pass the same callback? 
        -- If I pass the same callback, calling it for Alerts toggles Toasts. Calling it for Toasts toggles Alerts. 
        -- If UpdateDisplay calls both, we toggle twice? 
        -- Solution: Update ToggleMovers to be idempotent for a specific frame? Or just register one "Group".
        -- I'll register "Alerts & Toasts" as one entry? 
        -- Or just register both with same callback, but `ToggleMovers(enabled)` sets both. 
        -- `UpdateDisplay` calls toggleFunc for EACH registered mover.
        -- If I register "Alerts" -> ToggleMovers(true) -> Sets Both True.
        -- If I register "Toasts" -> ToggleMovers(true) -> Sets Both True. (Redundant but harmless).
        -- BUT, creating the overlay/registry entry for "Toasts" might be needed if `ns.Movers` manages the frame visibility directly???
        -- My `movers.lua` logic: `pcall(data.toggleFunc, data.frame, shouldShow)`.
        -- So it will call ToggleMovers(alertHolder, true) then ToggleMovers(toastHolder, true).
        -- `ToggleMovers` signature I wrote: `function Alerts:ToggleMovers(forceState)`. 
        -- If called as `Alerts:ToggleMovers(enabled)`, `self` is missing if called with dot notation from pcall? 
        -- `ns.Movers` stores `toggleFunc`. I passed `function(frame, enabled) Alerts:ToggleMovers(enabled) end`. 
        -- This closure ignores the frame arg and calls `Alerts:ToggleMovers(enabled)`.
        -- So it works. Redundancy is fine.
        
        ns.Movers:Register("Toasts", toastHolder, function(frame, enabled) end, "Toasts Anchor") 
        -- Wait, if I pass `function() end` for Toasts, it won't toggle. 
        -- But `Alerts` toggle handles both. So "Toasts" registration is just for... tracking? 
        -- If `ns.Movers` uses the list to Show/Hide frames directly if no toggleFunc? 
        -- `alertHolder` and `toastHolder` are just frames. 
        -- If I don't register Toasts, will it be hidden? 
        -- No, `ToggleMovers` handles it.
        -- If I register Toasts, `UpdateDisplay` iterates it.
        -- If I give it a toggleFunc that does nothing, `ToggleMovers` (called by Alerts) already did the job.
        -- So empty function is fine.
    end

    -- Prevent repeated hooking on refresh
    if self.initialized then 
        -- Just update anchors if needed
        if alertHolder and AlertFrame then
            AlertFrame:ClearAllPoints()
            AlertFrame:SetPoint("TOP", alertHolder, "TOP")
        end
        return 
    end
    self.initialized = true
    
    if AchievementAlertSystem then hooksecurefunc(AchievementAlertSystem, "setUpFunction", SkinAchievementAlert) end
    if DungeonCompletionAlertSystem then hooksecurefunc(DungeonCompletionAlertSystem, "setUpFunction", SkinDungeonCompletionAlert) end
    if LootAlertSystem then hooksecurefunc(LootAlertSystem, "setUpFunction", SkinLootWonAlert) end

    if AlertFrame then
        for _, sub in ipairs(AlertFrame.alertFrameSubSystems) do ReplaceSubSystemAnchors(sub) end
        hooksecurefunc(AlertFrame, "AddAlertFrameSubSystem", function(_, sub) ReplaceSubSystemAnchors(sub) end)
        
        -- Aggressive container anchoring
        hooksecurefunc(AlertFrame, "SetPoint", function(self, point, relTo, relPoint, x, y)
             -- Safety check to prevent recursion if our setpoint triggers this hook again internally (unlikely with securehook but possible with dirty chains)
             if self.isSettingPoint then return end
             
             if alertHolder and (not relTo or relTo ~= alertHolder) then
                self.isSettingPoint = true
                self:ClearAllPoints()
                self:SetPoint("TOP", alertHolder, "TOP")
                self.isSettingPoint = false
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
