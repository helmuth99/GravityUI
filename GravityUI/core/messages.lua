local ADDON_NAME, ns = ...
local Messages = {}
ns.Messages = Messages

local LSM = LibStub("LibSharedMedia-3.0", true)

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local MISDIRECTION_SPELL_ID = 34477
local TRICKS_OF_THE_TRADE_SPELL_ID = 57934
local STEALTH_SPELL_IDS = { [1784] = true, [115191] = true }
local SHROUD_SPELL_ID = 114018

local UPDATE_THROTTLE = 0.05
local timeSinceLastUpdate = 0

-- State tracking
local activeTrackingBars = {} -- Tracks Misdirection & Tricks
local trackingFramesPool = {}

local StealthState = {
    active = false,
    textFrame = nil,
}

local DurabilityState = {
    active = false,
    textFrame = nil,
}

local ShroudState = {
    ticker = nil,
    endTime = 0,
}

-- ============================================================================
-- HELPER: GET SETTINGS
-- ============================================================================
local function GetSettings()
    local db = ns.GetDB()
    return db and db.screenindicators and db.screenindicators.messages
end

-- ============================================================================
-- TEXT FRAMES (DURABILITY & STEALTH)
-- ============================================================================
local function CreateTextFrame(name)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(300, 50)
    f:SetFrameStrata("HIGH")
    f:Hide()
    
    local text = f:CreateFontString(nil, "OVERLAY")
    text:SetAllPoints()
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    f.text = text
    
    return f
end

local function UpdateTextFrameAppearance(f, s_group)
    if not f or not s_group then return end
    
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", s_group.x or 0, s_group.y or 0)
    
    local font = LSM and LSM:Fetch("font", s_group.font or "Gravity") or "Fonts\\FRIZQT__.TTF"
    local flags = s_group.fontOutline or "OUTLINE"
    f.text:SetFont(font, s_group.fontSize or 24, flags)
    
    local color = s_group.textColor or {1, 1, 1, 1}
    f.text:SetTextColor(unpack(color))
end

-- ============================================================================
-- TRACKING BARS (MISDIRECT / TRICKS)
-- ============================================================================
local function CreateTrackingBar()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetFrameStrata("HIGH")
    f:Hide()
    
    -- Status Bar
    f.bar = CreateFrame("StatusBar", nil, f)
    f.bar:SetAllPoints()
    f.bar:SetMinMaxValues(0, 1)
    
    -- Background
    f.bg = f.bar:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Icon
    f.icon = f.bar:CreateTexture(nil, "ARTWORK")
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Text (Name)
    f.name = f.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.name:SetJustifyH("LEFT")
    f.name:SetPoint("LEFT", f.bar, "LEFT", 4, 0)
    
    -- Text (Time)
    f.time = f.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.time:SetJustifyH("RIGHT")
    f.time:SetPoint("RIGHT", f.bar, "RIGHT", -4, 0)
    
    -- Backdrop (Border)
    local bd = {
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    }
    f:SetBackdrop(bd)
    f:SetBackdropColor(0, 0, 0, 0)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    
    return f
end

local function GetTrackingBar()
    for _, f in ipairs(trackingFramesPool) do
        if not f.inUse then
            f.inUse = true
            return f
        end
    end
    local f = CreateTrackingBar()
    f.inUse = true
    table.insert(trackingFramesPool, f)
    return f
end

local function StyleTrackingBar(f, s_group, spellName, spellIcon)
    if not f or not s_group then return end
    
    local width = s_group.width or 200
    local height = s_group.height or 20
    f:SetSize(width, height)
    
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", s_group.x or 0, s_group.y or 0)
    
    local texture = LSM and LSM:Fetch("statusbar", s_group.texture or "Gravity") or "Interface\\TargetingFrame\\UI-StatusBar"
    f.bar:SetStatusBarTexture(texture)
    f.bg:SetTexture(texture)
    
    local font = LSM and LSM:Fetch("font", s_group.font or "Gravity") or "Fonts\\FRIZQT__.TTF"
    local flags = s_group.fontOutline or "OUTLINE"
    local size = s_group.fontSize or 10
    
    f.name:SetFont(font, size, flags)
    f.time:SetFont(font, size, flags)
    
    local tc = s_group.textColor or {1, 1, 1, 1}
    f.name:SetTextColor(unpack(tc))
    f.time:SetTextColor(unpack(tc))
    
    local bc = s_group.barColor or {0, 0.75, 1, 1}
    f.bar:SetStatusBarColor(unpack(bc))
    f.bg:SetVertexColor(bc[1], bc[2], bc[3], 0.3)
    
    f.icon:SetTexture(spellIcon)
    f.icon:ClearAllPoints()
    f.icon:SetSize(height, height)
    f.icon:SetPoint("RIGHT", f, "LEFT", 0, 0)
    
    f.name:SetText(spellName)
end

-- ============================================================================
-- CORE LOGIC
-- ============================================================================

local updateFrame = CreateFrame("Frame")
updateFrame:Hide()

local function UpdateTrackingBars(elapsed)
    local s = GetSettings()
    if not (s and s.enabled) then
        for _, bar in ipairs(activeTrackingBars) do
            bar.frame.inUse = false
            bar.frame:Hide()
        end
        activeTrackingBars = {}
        updateFrame:Hide()
        return
    end

    local now = GetTime()
    for i = #activeTrackingBars, 1, -1 do
        local info = activeTrackingBars[i]
        if now >= info.expiration then
            info.frame.inUse = false
            info.frame:Hide()
            table.remove(activeTrackingBars, i)
        else
            local remaining = info.expiration - now
            local pct = remaining / info.duration
            info.frame.bar:SetValue(pct)
            info.frame.time:SetText(string.format("%.1f", remaining))
        end
    end
    
    if #activeTrackingBars == 0 then
        updateFrame:Hide()
    end
end

local function ApplyTrackingBar(spellID, duration, expiration)
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    local s_group = nil
    if spellID == MISDIRECTION_SPELL_ID and s.hunter and s.hunter.misdirect then
        if not s.hunter.misdirect.enabled then return end
        s_group = s.hunter.misdirect
    elseif spellID == TRICKS_OF_THE_TRADE_SPELL_ID and s.rogue and s.rogue.tricks then
        if not s.rogue.tricks.enabled then return end
        s_group = s.rogue.tricks
    end
    
    if not s_group then return end
    
    -- Check if it already exists
    for _, info in ipairs(activeTrackingBars) do
        if info.spellID == spellID then
            info.duration = duration
            info.expiration = expiration
            info.frame:Show()
            updateFrame:Show()
            return
        end
    end
    
    local name, _, icon = C_Spell.GetSpellName(spellID), nil, C_Spell.GetSpellTexture(spellID)
    local frame = GetTrackingBar()
    StyleTrackingBar(frame, s_group, name, icon)
    frame:Show()
    
    table.insert(activeTrackingBars, {
        spellID = spellID,
        duration = duration,
        expiration = expiration,
        frame = frame,
    })
    updateFrame:Show()
end

local function RemoveTrackingBar(spellID)
    for i = #activeTrackingBars, 1, -1 do
        if activeTrackingBars[i].spellID == spellID then
            activeTrackingBars[i].frame.inUse = false
            activeTrackingBars[i].frame:Hide()
            table.remove(activeTrackingBars, i)
        end
    end
    if #activeTrackingBars == 0 then
        updateFrame:Hide()
    end
end

-- Evaluate Auras for the player
local function EvaluatePlayerAuras()
    local s = GetSettings()
    if not (s and s.enabled) then return end
    
    -- Reset state indicators
    local hasMisdirect = false
    local hasTricks = false
    local hasStealth = false

    -- Use C_UnitAuras iteration (efficient for Retail)
    local function ProcessAura(aura)
        local spellID = aura.spellId
        
        -- Misdirection
        if spellID == MISDIRECTION_SPELL_ID then
            hasMisdirect = true
            ApplyTrackingBar(spellID, aura.duration, aura.expirationTime)
        -- Tricks of the trade
        elseif spellID == TRICKS_OF_THE_TRADE_SPELL_ID then
            hasTricks = true
            ApplyTrackingBar(spellID, aura.duration, aura.expirationTime)
        -- Stealth
        elseif STEALTH_SPELL_IDS[spellID] then
            hasStealth = true
        end
        return false -- Continue iterating
    end
    
    -- Scan Helpful Auras using ContinuationToken
    local continuationToken
    repeat
        local slots = C_UnitAuras.GetAuraSlots("player", "HELPFUL", 40, continuationToken)
        if not slots then break end
        continuationToken = slots.continuationToken
        for _, slot in ipairs(slots) do
            local auraInfo = C_UnitAuras.GetAuraDataBySlot("player", slot)
            if auraInfo then
                ProcessAura(auraInfo)
            end
        end
    until continuationToken == nil
    
    -- Removals
    if not hasMisdirect then RemoveTrackingBar(MISDIRECTION_SPELL_ID) end
    if not hasTricks then RemoveTrackingBar(TRICKS_OF_THE_TRADE_SPELL_ID) end
    
    -- Handle Stealth Text
    if hasStealth and s.rogue and s.rogue.stealth and s.rogue.stealth.enabled then
        if not StealthState.textFrame then
            StealthState.textFrame = CreateTextFrame("GravityUI_StealthText")
        end
        UpdateTextFrameAppearance(StealthState.textFrame, s.rogue.stealth)
        StealthState.textFrame.text:SetText("Stealth")
        StealthState.textFrame:Show()
        StealthState.active = true
    else
        if StealthState.textFrame then
            StealthState.textFrame:Hide()
        end
        StealthState.active = false
    end
end

-- Evaluate Durability
local function EvaluateDurability()
    local s = GetSettings()
    if not (s and s.enabled and s.general and s.general.durability and s.general.durability.enabled) then
        if DurabilityState.textFrame then DurabilityState.textFrame:Hide() end
        return
    end
    
    local lowestDurability = 1.0
    local isBroken = false
    
    for slot = 1, 18 do
        local current, maximum = GetInventoryItemDurability(slot)
        if current and maximum and maximum > 0 then
            local pct = current / maximum
            if pct < lowestDurability then
                lowestDurability = pct
            end
        end
    end
    
    if lowestDurability < 0.25 then
        if not DurabilityState.textFrame then
            DurabilityState.textFrame = CreateTextFrame("GravityUI_DurabilityText")
        end
        UpdateTextFrameAppearance(DurabilityState.textFrame, s.general.durability)
        DurabilityState.textFrame.text:SetText("Durability Low")
        -- Pulse animation or simple show
        DurabilityState.textFrame:Show()
        DurabilityState.active = true
    else
        if DurabilityState.textFrame then
            DurabilityState.textFrame:Hide()
        end
        DurabilityState.active = false
    end
end

-- Evaluate Shroud
local function StartShroudCountdown()
    local s = GetSettings()
    if not (s and s.enabled and s.rogue and s.rogue.shroud and s.rogue.shroud.enabled) then return end
    
    ShroudState.endTime = GetTime() + 15 -- Shroud lasts 15sec
    
    if ShroudState.ticker then ShroudState.ticker:Cancel() end
    
    ShroudState.ticker = C_Timer.NewTicker(1, function()
        local remaining = math.ceil(ShroudState.endTime - GetTime())
        -- Say logic
        if remaining > 0 then
            if remaining == 15 or remaining <= 5 then
                local inInstance, instanceType = IsInInstance()
                if inInstance and (instanceType == "party" or instanceType == "raid") then
                    SendChatMessage("Shroud is up " .. remaining .. " seconds", "SAY")
                else
                    -- If not in instance, just print to prevent spamming cities
                    print("GravityUI: Shroud is up " .. remaining .. " seconds")
                end
            end
        else
            if ShroudState.ticker then ShroudState.ticker:Cancel() end
        end
    end, 15)
end

-- ============================================================================
-- EVENTS & UPDATE
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if event == "UNIT_AURA" and unit == "player" then
        EvaluatePlayerAuras()
    elseif event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_ENTERING_WORLD" then
        EvaluateDurability()
        if event == "PLAYER_ENTERING_WORLD" then
            EvaluatePlayerAuras()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        if spellID == SHROUD_SPELL_ID then
            StartShroudCountdown()
        end
    end
end)

updateFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= UPDATE_THROTTLE then
        UpdateTrackingBars(timeSinceLastUpdate)
        timeSinceLastUpdate = 0
    end
end)

-- ============================================================================
-- PREVIEW APIs
-- ============================================================================

local previewTimers = {}

function Messages.PreviewDurability()
    local s = GetSettings()
    if not (s and s.general and s.general.durability) then return end
    if not DurabilityState.textFrame then DurabilityState.textFrame = CreateTextFrame("GravityUI_DurabilityText") end
    
    UpdateTextFrameAppearance(DurabilityState.textFrame, s.general.durability)
    DurabilityState.textFrame.text:SetText("Durability Low")
    DurabilityState.textFrame:Show()
    
    if previewTimers.durability then previewTimers.durability:Cancel() end
    previewTimers.durability = C_Timer.NewTimer(3, function() 
        if not DurabilityState.active then DurabilityState.textFrame:Hide() end
    end)
end

function Messages.PreviewStealth()
    local s = GetSettings()
    if not (s and s.rogue and s.rogue.stealth) then return end
    if not StealthState.textFrame then StealthState.textFrame = CreateTextFrame("GravityUI_StealthText") end
    
    UpdateTextFrameAppearance(StealthState.textFrame, s.rogue.stealth)
    StealthState.textFrame.text:SetText("Stealth")
    StealthState.textFrame:Show()
    
    if previewTimers.stealth then previewTimers.stealth:Cancel() end
    previewTimers.stealth = C_Timer.NewTimer(3, function() 
        if not StealthState.active then StealthState.textFrame:Hide() end
    end)
end

function Messages.PreviewMisdirect()
    local s = GetSettings()
    if not (s and s.hunter and s.hunter.misdirect) then return end
    -- Force set active to disable logic for a bit
    ApplyTrackingBar(MISDIRECTION_SPELL_ID, 8, GetTime() + 8)
end

function Messages.PreviewTricks()
    local s = GetSettings()
    if not (s and s.rogue and s.rogue.tricks) then return end
    -- Force set active to disable logic for a bit
    ApplyTrackingBar(TRICKS_OF_THE_TRADE_SPELL_ID, 6, GetTime() + 6)
end
