-- GravityUI - Battle Res & Bloodlust Tracker Module
local ADDON_NAME, ns = ...

ns.BattleResTracker = ns.BattleResTracker or {}
ns.BloodlustTracker = ns.BloodlustTracker or {}

local BREZ_SPELL_ID = 20484 -- Rebirth (canonical shared brez pool spell ID)
local PREVIEW_LUST_SPELL_ID = 2825

-- Sated / Exhaustion debuff IDs (all lust variants)
local SATED_DEBUFFS = {
    57723,   -- Exhaustion (Heroism)
    57724,   -- Sated (Bloodlust)
    80354,   -- Temporal Displacement (Time Warp)
    95809,   -- Insanity (Ancient Hysteria)
    160455,  -- Fatigued (Netherwinds)
    264689,  -- Fatigued (Primal Rage)
    390435,  -- Exhaustion (Fury of the Aspects)
}

---------------------------------------------------------------------------
-- DATABASE ACCESS
---------------------------------------------------------------------------
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

---------------------------------------------------------------------------
-- TIME FORMATTING & HELPERS
---------------------------------------------------------------------------
local function FormatTime(s)
    if not s or s <= 0 then return "" end
    local m = math.floor(s / 60)
    local sec = math.floor(s % 60)
    return string.format("%d:%02d", m, sec)
end

local function GetActiveLustIcon()
    local faction = UnitFactionGroup("player")
    return (faction == "Alliance") and 132313 or 136012 -- Heroism vs Bloodlust
end

---------------------------------------------------------------------------
-- ENCOUNTER & KEYSTONE STATE TRACKING
---------------------------------------------------------------------------
local _state = {
    inEncounter     = false,
    encounterIsRaid = false,
    inChallenge     = false,
}

local function ActiveKeystoneLevel()
    if not C_ChallengeMode or not C_ChallengeMode.IsChallengeModeActive or not C_ChallengeMode.IsChallengeModeActive() then
        return nil
    end
    if C_ChallengeMode.GetActiveKeystoneInfo then
        local lvl = C_ChallengeMode.GetActiveKeystoneInfo()
        return (lvl and lvl > 0) and lvl or nil
    end
    return nil
end

local function RefreshKeystoneState()
    _state.inChallenge = (ActiveKeystoneLevel() ~= nil)
end

local function RefreshEncounterState()
    _state.inEncounter = (IsEncounterInProgress and IsEncounterInProgress()) or false
    if _state.inEncounter then
        local _, instanceType = GetInstanceInfo()
        _state.encounterIsRaid = (instanceType == "raid")
    else
        _state.encounterIsRaid = false
    end
end

local function CheckVisibility(visMode)
    if visMode == "ALWAYS" then return true end
    if visMode == "NEVER" then return false end

    -- Hard gate: must be in a party or raid instance
    local _, instanceType = GetInstanceInfo()
    if instanceType ~= "party" and instanceType ~= "raid" then return false end

    local wantMPlus = (visMode == "MPLUS_AND_RAID" or visMode == "MPLUS")
    local wantRaid  = (visMode == "MPLUS_AND_RAID" or visMode == "RAID")

    if wantMPlus and _state.inChallenge then return true end
    -- Show in raids whenever inside the raid instance (not just during boss encounters).
    -- Players need to see remaining charges between pulls.
    if wantRaid and instanceType == "raid" then return true end

    return false
end

--==============================================================================================================================================================================================
-- 1. BATTLE RES TRACKER
--==============================================================================================================================================================================================
local brFrame, brIcon, brBorder, brCountText, brCooldownText, brCD
local brIsPreview = false
local brTicker = nil

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
        self:SetUserPlaced(false)
        local p, _, rp, x, y = self:GetPoint()
        local d = GetBR_DB()
        if d then
            d.position = { point = p, relativePoint = rp, x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
        end
    end)

    brIcon = brFrame:CreateTexture(nil, "ARTWORK")
    brIcon:SetAllPoints()
    brIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local brezIconPath = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(BREZ_SPELL_ID) or 136080
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

    brFrame:EnableMouse(false)
    brFrame:Hide()

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("BattleResTracker", brFrame, function(frame, enabled, force)
            if enabled then
                brIsPreview = true
                if brTicker then brTicker:Cancel(); brTicker = nil end
                frame:Show()
                frame:EnableMouse(true)
                brCountText:SetText("2")
                brCountText:SetTextColor(1, 1, 1, 1)
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

local function PollBR()
    if not brFrame or brIsPreview then return end

    local db = GetBR_DB()
    if not (db and db.enabled) then return end

    local info = C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(BREZ_SPELL_ID)
    if not info or not info.maxCharges then
        if db.visibility == "ALWAYS" then
            brCountText:SetText("-")
            brCooldownText:SetText("")
            brIcon:SetDesaturated(false)
            brCD:Clear()
        end
        return
    end

    local charges = info.currentCharges
    local maxCharges = info.maxCharges
    local start = info.cooldownStartTime
    local dur = info.cooldownDuration
    local recharging = (charges < maxCharges and start and dur and dur > 0)

    -- Count text & color
    brCountText:SetText(tostring(charges))
    if charges <= 0 then
        brCountText:SetTextColor(1, 0.2, 0.2, 1)
        brIcon:SetDesaturated(true)
        brFrame:SetAlpha(0.7)
    else
        local cc = db.countColor or { 1, 1, 1, 1 }
        brCountText:SetTextColor(cc[1] or 1, cc[2] or 1, cc[3] or 1, cc[4] or 1)
        brIcon:SetDesaturated(false)
        brFrame:SetAlpha(1)
    end

    -- Timer text & cooldown swipe
    if recharging then
        local remaining = (start + dur) - GetTime()
        if remaining > 0 then
            brCooldownText:SetText(FormatTime(remaining))
            brCD:SetCooldown(start, dur)
        else
            brCooldownText:SetText("")
            brCD:Clear()
        end
    else
        brCooldownText:SetText("")
        brCD:Clear()
    end
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
        if brTicker then brTicker:Cancel(); brTicker = nil end
        brFrame:Show()
        brFrame:EnableMouse(true)
        brCountText:SetText("2")
        brCountText:SetTextColor(1, 1, 1, 1)
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
        if brTicker then brTicker:Cancel(); brTicker = nil end
        brFrame:Hide()
        return
    end

    local shouldShow = CheckVisibility(db.visibility)
    if shouldShow then
        -- Sizing & styling
        local sz = db.iconSize or 36
        brFrame:SetSize(sz, sz)
        if ns.GUI and ns.GUI.SetFont then
            ns.GUI:SetFont(brCountText, db.countFontSize or 11, "OUTLINE")
            ns.GUI:SetFont(brCooldownText, db.fontSize or 12, "OUTLINE")
        end

        local tc = db.timerColor or { 1, 0.82, 0, 1 }
        brCooldownText:SetTextColor(tc[1] or 1, tc[2] or 0.82, tc[3] or 0, tc[4] or 1)

        if not brFrame:IsShown() then brFrame:Show() end
        if not brTicker then
            brTicker = C_Timer.NewTicker(0.5, PollBR)
        end
        PollBR()
    else
        if brFrame:IsShown() then brFrame:Hide() end
        if brTicker then brTicker:Cancel(); brTicker = nil end
    end
end

--==============================================================================================================================================================================================
-- 2. BLOODLUST TRACKER
--==============================================================================================================================================================================================
local blFrame, blIcon, blBorder, blCooldownText, blCD
local buffOverlay, buffTex, buffCooldown, buffDurationFS
local blIsPreview = false
local blTicker = nil

local _satedActive = false
local _satedWasPresent = false
local _buffExpiry = 0
local _buffZoneGuard = 0
local _satedExpiryGuess = 0

local function FindSatedDebuff()
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return nil end
    for i = 1, #SATED_DEBUFFS do
        local sid = SATED_DEBUFFS[i]
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(sid)
        if aura then return aura, sid end
    end
    return nil
end

local _buffAccum = 0
local _lastBuffDurText = nil

local function HideBuffOverlay()
    _buffExpiry = 0
    _lastBuffDurText = nil
    if buffOverlay then
        buffOverlay:SetScript("OnUpdate", nil)
        buffOverlay:Hide()
    end
    if buffDurationFS then buffDurationFS:SetText("") end
end

local function BuffOnUpdate(_, elapsed)
    local rem = _buffExpiry - GetTime()
    if rem <= 0 then
        HideBuffOverlay()
        return
    end

    _buffAccum = _buffAccum + (elapsed or 0)
    if _buffAccum < 0.1 then return end
    _buffAccum = 0

    local s = tostring(math.ceil(rem))
    if s ~= _lastBuffDurText then
        buffDurationFS:SetText(s)
        _lastBuffDurText = s
    end
end

local function ShowBuffOverlay()
    if not buffOverlay then return end
    buffTex:SetTexture(GetActiveLustIcon())
    _buffExpiry = GetTime() + 40
    _buffAccum = 0
    _lastBuffDurText = "40"
    buffCooldown:SetCooldown(GetTime(), 40)
    buffDurationFS:SetText("40")
    buffOverlay:Show()
    buffOverlay:SetScript("OnUpdate", BuffOnUpdate)
end

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
        self:SetUserPlaced(false)
        local p, _, rp, x, y = self:GetPoint()
        local d = GetBL_DB()
        if d then
            d.position = { point = p, relativePoint = rp, x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
        end
    end)

    blIcon = blFrame:CreateTexture(nil, "ARTWORK")
    blIcon:SetAllPoints()
    blIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local blIconPath = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(PREVIEW_LUST_SPELL_ID) or 136012
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

    -- 40s Active Lust Buff Overlay (sits directly on top of the Sated debuff icon)
    buffOverlay = CreateFrame("Frame", nil, blFrame)
    buffOverlay:SetAllPoints(blFrame)
    buffOverlay:SetFrameLevel(blCD:GetFrameLevel() + 4)
    buffOverlay:Hide()

    buffTex = buffOverlay:CreateTexture(nil, "ARTWORK")
    buffTex:SetAllPoints(buffOverlay)
    buffTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    buffCooldown = CreateFrame("Cooldown", nil, buffOverlay, "CooldownFrameTemplate")
    buffCooldown:SetAllPoints(buffOverlay)
    buffCooldown:SetDrawEdge(false)
    buffCooldown:SetDrawSwipe(true)
    buffCooldown:SetReverse(true)
    buffCooldown:SetHideCountdownNumbers(true)
    buffCooldown:SetFrameLevel(buffOverlay:GetFrameLevel() + 1)

    buffDurationFS = buffCooldown:CreateFontString(nil, "OVERLAY", nil, 2)
    if ns.GUI and ns.GUI.SetFont then ns.GUI:SetFont(buffDurationFS, 12, "OUTLINE") else buffDurationFS:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE") end
    buffDurationFS:SetPoint("CENTER", buffOverlay, "CENTER", 0, 0)
    buffDurationFS:SetTextColor(1, 0.9, 0.2, 1)

    blFrame:EnableMouse(false)
    blFrame:Hide()

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("BloodlustTracker", blFrame, function(frame, enabled, force)
            if enabled then
                blIsPreview = true
                if blTicker then blTicker:Cancel(); blTicker = nil end
                HideBuffOverlay()
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

local function PollBL()
    if not blFrame or blIsPreview then return end

    local aura, sid = FindSatedDebuff()
    if not aura then
        _satedActive = false
        _satedExpiryGuess = 0
        blCooldownText:SetText("")
        blCD:Clear()
        if not blIsPreview and not CheckVisibility(GetBL_DB() and GetBL_DB().visibility) then
            if blTicker then blTicker:Cancel(); blTicker = nil end
            blFrame:Hide()
        end
        return
    end

    _satedActive = true
    local exp = aura.expirationTime
    local rawDur = aura.duration
    local dur = 600
    if rawDur and (not issecretvalue or not issecretvalue(rawDur)) then
        dur = rawDur
    end

    -- Secret-safe expiration handling
    if exp and (not issecretvalue or not issecretvalue(exp)) and exp > 0 then
        _satedExpiryGuess = exp
    end

    local remain = 0
    if exp and (not issecretvalue or not issecretvalue(exp)) and exp > 0 then
        remain = exp - GetTime()
    elseif _satedExpiryGuess > GetTime() then
        remain = _satedExpiryGuess - GetTime()
    end

    if remain > 0 then
        blCooldownText:SetText(FormatTime(remain))
        if _satedExpiryGuess > GetTime() then
            blCD:SetCooldown(_satedExpiryGuess - dur, dur)
        end
    else
        blCooldownText:SetText("")
        blCD:Clear()
    end
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
        if blTicker then blTicker:Cancel(); blTicker = nil end
        HideBuffOverlay()
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
        if blTicker then blTicker:Cancel(); blTicker = nil end
        HideBuffOverlay()
        blFrame:Hide()
        return
    end

    local aura, sid = FindSatedDebuff()
    _satedActive = (aura ~= nil)

    local shouldShow = CheckVisibility(db.visibility)
    if shouldShow and _satedActive then
        local sz = db.iconSize or 36
        blFrame:SetSize(sz, sz)
        if ns.GUI and ns.GUI.SetFont then
            ns.GUI:SetFont(blCooldownText, db.fontSize or 12, "OUTLINE")
            if buffDurationFS then ns.GUI:SetFont(buffDurationFS, db.fontSize or 12, "OUTLINE") end
        end

        local tc = db.timerColor or { 1, 0.2, 0.2, 1 }
        blCooldownText:SetTextColor(tc[1] or 1, tc[2] or 0.2, tc[3] or 0.2, tc[4] or 1)

        local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(sid)
        if not tex and C_Spell and C_Spell.GetSpellTexture then
            tex = C_Spell.GetSpellTexture(PREVIEW_LUST_SPELL_ID)
        end
        blIcon:SetTexture(tex or 136012)

        if not blFrame:IsShown() then blFrame:Show() end
        if not blTicker then
            blTicker = C_Timer.NewTicker(0.5, PollBL)
        end
        PollBL()
    else
        if blFrame:IsShown() then blFrame:Hide() end
        if blTicker then blTicker:Cancel(); blTicker = nil end
    end
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("CHALLENGE_MODE_RESET")
eventFrame:RegisterEvent("WORLD_STATE_TIMER_START")
eventFrame:RegisterEvent("WORLD_STATE_TIMER_STOP")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_DEAD")

eventFrame:SetScript("OnEvent", function(self, event, unit, updateInfo)
    if event == "PLAYER_LOGIN" then
        CreateBRFrame()
        CreateBLFrame()
        RefreshEncounterState()
        RefreshKeystoneState()
        ns.BattleResTracker.Update()
        ns.BloodlustTracker.Update()
    elseif event == "UNIT_AURA" then
        local was = _satedWasPresent
        local aura, sid = FindSatedDebuff()
        local present = (aura ~= nil)
        _satedWasPresent = present
        _satedActive = present

        local isFull = false
        if updateInfo and (not issecretvalue or not issecretvalue(updateInfo)) then
            local v = updateInfo.isFullUpdate
            if issecretvalue and issecretvalue(v) then
                isFull = false
            elseif v == true then
                isFull = true
            end
        end

        -- Rising edge: Bloodlust/Heroism was just cast!
        if present and not was and not isFull and GetTime() >= _buffZoneGuard then
            _satedExpiryGuess = GetTime() + 600
            ShowBuffOverlay()
        end

        ns.BloodlustTracker.Update()
    elseif event == "PLAYER_DEAD" then
        HideBuffOverlay()
    elseif event == "ENCOUNTER_START" then
        RefreshEncounterState()
        ns.BattleResTracker.Update()
        ns.BloodlustTracker.Update()
    elseif event == "ENCOUNTER_END" then
        RefreshEncounterState()
        ns.BattleResTracker.Update()
        ns.BloodlustTracker.Update()
    elseif event == "CHALLENGE_MODE_START" or event == "WORLD_STATE_TIMER_START" then
        RefreshKeystoneState()
        ns.BattleResTracker.Update()
        ns.BloodlustTracker.Update()
    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" or event == "WORLD_STATE_TIMER_STOP" then
        _state.inChallenge = false
        ns.BattleResTracker.Update()
        ns.BloodlustTracker.Update()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local aura = FindSatedDebuff()
        _satedActive = (aura ~= nil)
        _satedWasPresent = _satedActive
        _buffZoneGuard = GetTime() + 1.5
        RefreshEncounterState()
        RefreshKeystoneState()
        ns.BattleResTracker.Update()
        ns.BloodlustTracker.Update()
    elseif event == "SPELL_UPDATE_CHARGES" then
        ns.BattleResTracker.Update()
    end
end)
