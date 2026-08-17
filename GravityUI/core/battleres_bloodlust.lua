-- GravityUI - Battle Res & Bloodlust Tracker Module
local ADDON_NAME, ns = ...

ns.BattleResTracker = ns.BattleResTracker or {}
ns.BloodlustTracker = ns.BloodlustTracker or {}

local BREZ_SPELL_ID = 20484 -- Rebirth (shared brez pool)
local SATED_DEBUFFS = {
    [57723]  = true, -- Exhaustion (Heroism)
    [57724]  = true, -- Sated (Bloodlust)
    [80354]  = true, -- Temporal Displacement (Time Warp)
    [95809]  = true, -- Insanity (Ancient Hysteria)
    [160455] = true, -- Fatigued (Netherwinds)
    [264689] = true, -- Fatigued (Primal Rage)
    [390435] = true, -- Exhaustion (Fury of the Aspects)
}

local function GetBR_DB()
    local db = ns.GetDB and ns.GetDB()
    if db and db.screenindicators then
        if not db.screenindicators.battleRes then
            db.screenindicators.battleRes = {
                enabled       = true,
                visibility    = "MPLUS_AND_RAID",
                iconSize      = 36,
                fontSize      = 12,
                countFontSize = 11,
                borderSize    = 1,
                borderColor   = { 0, 0, 0, 1 },
                position      = { point = "CENTER", relativePoint = "CENTER", x = -40, y = 140 },
            }
        end
        return db.screenindicators.battleRes
    end
    return nil
end

local function GetBL_DB()
    local db = ns.GetDB and ns.GetDB()
    if db and db.screenindicators then
        if not db.screenindicators.bloodlust then
            db.screenindicators.bloodlust = {
                enabled     = true,
                visibility  = "MPLUS_AND_RAID",
                iconSize    = 36,
                fontSize    = 12,
                borderSize  = 1,
                borderColor = { 0, 0, 0, 1 },
                position    = { point = "CENTER", relativePoint = "CENTER", x = 40, y = 140 },
            }
        end
        return db.screenindicators.bloodlust
    end
    return nil
end

local function CheckVisibility(visMode)
    if visMode == "ALWAYS" then return true end
    if visMode == "NEVER" then return false end

    local inInstance, instanceType = IsInInstance()
    local isRaid = inInstance and instanceType == "raid"
    local isParty = inInstance and instanceType == "party"
    local isMPlus = isParty and C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()

    if visMode == "MPLUS_AND_RAID" then
        return isRaid or isMPlus or (IsInRaid() or IsInGroup())
    elseif visMode == "MPLUS" then
        return isMPlus or (isParty and IsInGroup())
    elseif visMode == "RAID" then
        return isRaid or IsInRaid()
    end

    return true
end

--==============================================================================================================================================================================================
-- 1. BATTLE RES TRACKER
--==============================================================================================================================================================================================
local brFrame, brIcon, brBorder, brCountText, brCooldownText, brCD
local brIsPreview = false

local function CreateBRFrame()
    if brFrame then return brFrame end

    brFrame = CreateFrame("Frame", "GravityUI_BattleResTracker", UIParent, "BackdropTemplate")
    brFrame:SetSize(36, 36)
    brFrame:SetClampedToScreen(true)
    brFrame:SetMovable(true)
    brFrame:SetFrameStrata("MEDIUM")

    local db = GetBR_DB()
    local pos = db and db.position
    if pos and pos.point then
        brFrame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or -40, pos.y or 140)
    else
        brFrame:SetPoint("CENTER", UIParent, "CENTER", -40, 140)
    end

    brFrame:RegisterForDrag("LeftButton")
    brFrame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    brFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        local d = GetBR_DB()
        if d then
            d.position = { point = p, relativePoint = rp, x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
        end
    end)

    brIcon = brFrame:CreateTexture(nil, "ARTWORK")
    brIcon:SetAllPoints()
    brIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local brezIconPath = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(BREZ_SPELL_ID) or 136080
    brIcon:SetTexture(brezIconPath)

    brCD = CreateFrame("Cooldown", nil, brFrame, "CooldownFrameTemplate")
    brCD:SetAllPoints()
    brCD:SetDrawEdge(false)
    brCD:SetDrawSwipe(true)
    brCD:SetReverse(true)
    brCD:SetHideCountdownNumbers(true)

    brBorder = brFrame:CreateTexture(nil, "OVERLAY", nil, 1)
    brBorder:SetAllPoints()
    brBorder:SetColorTexture(0, 0, 0, 0)

    brCountText = brFrame:CreateFontString(nil, "OVERLAY", nil, 2)
    if ns.GUI and ns.GUI.SetFont then ns.GUI:SetFont(brCountText, 11, "OUTLINE") else brCountText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE") end
    brCountText:SetPoint("BOTTOMRIGHT", brFrame, "BOTTOMRIGHT", -2, 2)
    brCountText:SetTextColor(1, 1, 1, 1)

    brCooldownText = brFrame:CreateFontString(nil, "OVERLAY", nil, 2)
    if ns.GUI and ns.GUI.SetFont then ns.GUI:SetFont(brCooldownText, 12, "OUTLINE") else brCooldownText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE") end
    brCooldownText:SetPoint("CENTER", brFrame, "CENTER", 0, 0)
    brCooldownText:SetTextColor(1, 0.82, 0, 1)

    brFrame:Hide()

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("BattleResTracker", brFrame, function(frame, enabled, force)
            if enabled then
                brIsPreview = true
                frame:Show()
                frame:EnableMouse(true)
                brCountText:SetText("2")
                brCooldownText:SetText("3:45")
                brIcon:SetDesaturated(false)
                frame:SetAlpha(1)
            else
                brIsPreview = false
                frame:EnableMouse(false)
                ns.BattleResTracker.Update()
            end
        end, "Battle Res")
    end

    return brFrame
end

function ns.BattleResTracker.ToggleMover()
    CreateBRFrame()
    if brIsPreview then
        brIsPreview = false
        brFrame:EnableMouse(false)
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(brFrame, false, "BattleResTracker")
        end
        ns.BattleResTracker.Update()
    else
        brIsPreview = true
        brFrame:Show()
        brFrame:EnableMouse(true)
        brCountText:SetText("2")
        brCooldownText:SetText("3:45")
        brIcon:SetDesaturated(false)
        brFrame:SetAlpha(1)
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(brFrame, true, "BattleResTracker")
        end
    end
end

function ns.BattleResTracker.Update()
    CreateBRFrame()
    if brIsPreview then return end

    local db = GetBR_DB()
    if not (db and db.enabled) then
        brFrame:Hide()
        return
    end

    if not CheckVisibility(db.visibility) then
        brFrame:Hide()
        return
    end

    -- Sizing & styling
    local sz = db.iconSize or 36
    brFrame:SetSize(sz, sz)
    if ns.GUI and ns.GUI.SetFont then
        ns.GUI:SetFont(brCountText, db.countFontSize or 11, "OUTLINE")
        ns.GUI:SetFont(brCooldownText, db.fontSize or 12, "OUTLINE")
    end

    local tc = db.timerColor or { 1, 0.82, 0, 1 }
    local cc = db.countColor or { 1, 1, 1, 1 }
    brCooldownText:SetTextColor(tc[1] or 1, tc[2] or 0.82, tc[3] or 0, tc[4] or 1)
    brCountText:SetTextColor(cc[1] or 1, cc[2] or 1, cc[3] or 1, cc[4] or 1)

    local chargeInfo = C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(BREZ_SPELL_ID)
    local currentCharges, maxCharges, cooldownStart, cooldownDuration
    if chargeInfo then
        currentCharges = chargeInfo.currentCharges
        maxCharges = chargeInfo.maxCharges
        cooldownStart = chargeInfo.cooldownStartTime
        cooldownDuration = chargeInfo.cooldownDuration
    else
        currentCharges, maxCharges, cooldownStart, cooldownDuration = GetSpellCharges(BREZ_SPELL_ID)
    end

    if currentCharges and maxCharges and maxCharges > 0 then
        brFrame:Show()
        brCountText:SetText(tostring(currentCharges))

        if currentCharges == 0 then
            brIcon:SetDesaturated(true)
            brFrame:SetAlpha(0.6)
        else
            brIcon:SetDesaturated(false)
            brFrame:SetAlpha(1)
        end

        if cooldownDuration and cooldownDuration > 0 and currentCharges < maxCharges then
            local remain = (cooldownStart + cooldownDuration) - GetTime()
            if remain > 0 then
                local m = math.floor(remain / 60)
                local s = math.floor(remain % 60)
                brCooldownText:SetText(string.format("%d:%02d", m, s))
                brCD:SetCooldown(cooldownStart, cooldownDuration)
            else
                brCooldownText:SetText("")
                brCD:Clear()
            end
        else
            brCooldownText:SetText("")
            brCD:Clear()
        end
    else
        -- Fallback when charges info is unavailable (solo out of instance)
        if db.visibility == "ALWAYS" then
            brFrame:Show()
            brCountText:SetText("-")
            brCooldownText:SetText("")
            brIcon:SetDesaturated(false)
        else
            brFrame:Hide()
        end
    end
end

--==============================================================================================================================================================================================
-- 2. BLOODLUST TRACKER
--==============================================================================================================================================================================================
local blFrame, blIcon, blBorder, blCooldownText, blCD
local blIsPreview = false

local function CreateBLFrame()
    if blFrame then return blFrame end

    blFrame = CreateFrame("Frame", "GravityUI_BloodlustTracker", UIParent, "BackdropTemplate")
    blFrame:SetSize(36, 36)
    blFrame:SetClampedToScreen(true)
    blFrame:SetMovable(true)
    blFrame:SetFrameStrata("MEDIUM")

    local db = GetBL_DB()
    local pos = db and db.position
    if pos and pos.point then
        blFrame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 40, pos.y or 140)
    else
        blFrame:SetPoint("CENTER", UIParent, "CENTER", 40, 140)
    end

    blFrame:RegisterForDrag("LeftButton")
    blFrame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    blFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        local d = GetBL_DB()
        if d then
            d.position = { point = p, relativePoint = rp, x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
        end
    end)

    blIcon = blFrame:CreateTexture(nil, "ARTWORK")
    blIcon:SetAllPoints()
    blIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local blIconPath = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(2825) or 136012
    blIcon:SetTexture(blIconPath)

    blCD = CreateFrame("Cooldown", nil, blFrame, "CooldownFrameTemplate")
    blCD:SetAllPoints()
    blCD:SetDrawEdge(false)
    blCD:SetDrawSwipe(true)
    blCD:SetReverse(true)
    blCD:SetHideCountdownNumbers(true)

    blBorder = blFrame:CreateTexture(nil, "OVERLAY", nil, 1)
    blBorder:SetAllPoints()
    blBorder:SetColorTexture(0, 0, 0, 0)

    blCooldownText = blFrame:CreateFontString(nil, "OVERLAY", nil, 2)
    if ns.GUI and ns.GUI.SetFont then ns.GUI:SetFont(blCooldownText, 12, "OUTLINE") else blCooldownText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE") end
    blCooldownText:SetPoint("CENTER", blFrame, "CENTER", 0, 0)
    blCooldownText:SetTextColor(1, 0.2, 0.2, 1)

    blFrame:Hide()

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("BloodlustTracker", blFrame, function(frame, enabled, force)
            if enabled then
                blIsPreview = true
                frame:Show()
                frame:EnableMouse(true)
                blCooldownText:SetText("5:30")
                blIcon:SetDesaturated(false)
                frame:SetAlpha(1)
            else
                blIsPreview = false
                frame:EnableMouse(false)
                ns.BloodlustTracker.Update()
            end
        end, "Bloodlust")
    end

    return blFrame
end

function ns.BloodlustTracker.ToggleMover()
    CreateBLFrame()
    if blIsPreview then
        blIsPreview = false
        blFrame:EnableMouse(false)
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(blFrame, false, "BloodlustTracker")
        end
        ns.BloodlustTracker.Update()
    else
        blIsPreview = true
        blFrame:Show()
        blFrame:EnableMouse(true)
        blCooldownText:SetText("5:30")
        blIcon:SetDesaturated(false)
        blFrame:SetAlpha(1)
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(blFrame, true, "BloodlustTracker")
        end
    end
end

function ns.BloodlustTracker.Update()
    CreateBLFrame()
    if blIsPreview then return end

    local db = GetBL_DB()
    if not (db and db.enabled) then
        blFrame:Hide()
        return
    end

    if not CheckVisibility(db.visibility) then
        blFrame:Hide()
        return
    end

    local sz = db.iconSize or 36
    blFrame:SetSize(sz, sz)
    if ns.GUI and ns.GUI.SetFont then
        ns.GUI:SetFont(blCooldownText, db.fontSize or 12, "OUTLINE")
    end

    local tc = db.timerColor or { 1, 0.2, 0.2, 1 }
    blCooldownText:SetTextColor(tc[1] or 1, tc[2] or 0.2, tc[3] or 0.2, tc[4] or 1)

    -- Check player debuffs for Sated/Exhaustion
    local satedFound = false
    local satedExpTime = 0
    local satedDuration = 0
    local satedIcon

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HARMFUL")
            if not aura then break end
            if SATED_DEBUFFS[aura.spellId] then
                satedFound = true
                satedExpTime = aura.expirationTime or 0
                satedDuration = aura.duration or 0
                satedIcon = aura.icon
                break
            end
        end
    end

    if satedFound and satedExpTime > 0 then
        blFrame:Show()
        if satedIcon then blIcon:SetTexture(satedIcon) end
        local remain = satedExpTime - GetTime()
        if remain > 0 then
            local m = math.floor(remain / 60)
            local s = math.floor(remain % 60)
            blCooldownText:SetText(string.format("%d:%02d", m, s))
            blCD:SetCooldown(satedExpTime - satedDuration, satedDuration)
        else
            blCooldownText:SetText("")
            blCD:Clear()
        end
    else
        blFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- INITIALIZATION & EVENT HANDLING
---------------------------------------------------------------------------
CreateBRFrame()
CreateBLFrame()

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        CreateBRFrame()
        CreateBLFrame()
        C_Timer.NewTicker(1.0, function()
            ns.BattleResTracker.Update()
            ns.BloodlustTracker.Update()
        end)
    elseif event == "UNIT_AURA" then
        if unit == "player" then
            ns.BloodlustTracker.Update()
        end
    else
        ns.BattleResTracker.Update()
        ns.BloodlustTracker.Update()
    end
end)
