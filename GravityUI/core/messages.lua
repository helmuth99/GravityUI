local ADDON_NAME, ns = ...
local Messages = {}
ns.Messages = Messages

local LSM = LibStub("LibSharedMedia-3.0", true)

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local MISDIRECTION_SPELL_ID = 34477
local MISDIRECTION_TARGET_ID = 35079
local TRICKS_OF_THE_TRADE_SPELL_ID = 57934
local TRICKS_TARGET_ID = 59628
local STEALTH_SPELL_IDS = { [1784] = true, [115191] = true, [5215] = true, [199483] = true } -- Rogue, Rogue Subtlety, Druid Prowl, Hunter Camouflage
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
-- (Tracker Bar logic removed per user request)

local STEALTH_SPELL_IDS = {
    [115191] = true, -- Rogue Stealth
    [199483] = true, -- Rogue Camouflage (Talent)
    [1784]   = true, -- Rogue Stealth (Classic/Base)
    [5215]   = true, -- Druid Prowl
}

local SHROUD_SPELL_ID = 114018

-- ============================================================================
-- CORE LOGIC
-- ============================================================================

-- Evaluate Auras for the player for Stealth
local function EvaluateAuras()
    local s = GetSettings()
    
    -- Absolute Master Toggle + Stealth Toggle Verification
    if not (s and s.enabled and s.general and s.general.stealth and s.general.stealth.enabled) then
        if StealthState.textFrame then
            StealthState.textFrame:Hide()
        end
        StealthState.active = false
        return
    end
    
    local hasStealth = false

    local function ProcessAura(aura, unit)
        -- Guard against 12.0 restricted auras returning 'secret' values
        -- Restricted auras usually have nil or restricted names
        if not aura.name or type(aura.spellId) ~= "number" then return false end
        
        local spellID = aura.spellId
        
        -- Stealth (Only track on player if they are a Rogue or Druid)
        if unit == "player" then
            -- Using pcall here as final defense because some "secret" values still report as type 'number'
            -- but will throw "table index is secret" if used as an actual key in a table lookup.
            local ok, isStealth = pcall(function() return STEALTH_SPELL_IDS[spellID] end)
            if ok and isStealth then
                local _, class = UnitClass("player")
                if class == "ROGUE" or class == "DRUID" or class == "HUNTER" then
                    hasStealth = true
                end
            end
        end
        return false
    end
    
    for i = 1, 40 do
        local auraInfo = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not auraInfo then break end
        ProcessAura(auraInfo, "player")
    end
    
    -- Handle Stealth Text
    if hasStealth then
        if not StealthState.textFrame then
            StealthState.textFrame = CreateTextFrame("GravityUI_StealthText")
        end
        UpdateTextFrameAppearance(StealthState.textFrame, s.general.stealth)
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
    -- Absolute Master Toggle + Durability Toggle Verification
    if not (s and s.enabled and s.general and s.general.durability and s.general.durability.enabled) then
        if DurabilityState.textFrame then DurabilityState.textFrame:Hide() end
        DurabilityState.active = false
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
-- PREVIEW FUNCTIONS
-- ============================================================================

function Messages.PreviewDurability()
    local s = GetSettings()
    if not (s and s.general and s.general.durability) then return end
    
    if not DurabilityState.textFrame then
        DurabilityState.textFrame = CreateTextFrame("GravityUI_DurabilityText")
    end
    
    UpdateTextFrameAppearance(DurabilityState.textFrame, s.general.durability)
    DurabilityState.textFrame.text:SetText("Durability Low (Preview)")
    DurabilityState.textFrame:Show()
    
    if DurabilityState.previewTimer then DurabilityState.previewTimer:Cancel() end
    DurabilityState.previewTimer = C_Timer.NewTimer(3, function()
        if not DurabilityState.active then
            DurabilityState.textFrame:Hide()
        else
            DurabilityState.textFrame.text:SetText("Durability Low")
        end
    end)
end

function Messages.PreviewStealth()
    local s = GetSettings()
    if not (s and s.general and s.general.stealth) then return end
    
    if not StealthState.textFrame then
        StealthState.textFrame = CreateTextFrame("GravityUI_StealthText")
    end
    
    UpdateTextFrameAppearance(StealthState.textFrame, s.general.stealth)
    StealthState.textFrame.text:SetText("Stealth (Preview)")
    StealthState.textFrame:Show()
    
    if StealthState.previewTimer then StealthState.previewTimer:Cancel() end
    StealthState.previewTimer = C_Timer.NewTimer(3, function()
        if not StealthState.active then
            StealthState.textFrame:Hide()
        else
            StealthState.textFrame.text:SetText("Stealth")
        end
    end)
end

-- ============================================================================
-- EVENTS & UPDATE
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
eventFrame:RegisterEvent("PET_BAR_UPDATE")
eventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, unit, castGUID, spellID)
    if event == "UNIT_AURA" and unit == "player" then
        EvaluateAuras()
    elseif event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_ENTERING_WORLD" then
        EvaluateDurability()
        if event == "PLAYER_ENTERING_WORLD" then
            EvaluateAuras()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        if spellID == SHROUD_SPELL_ID then
            local _, class = UnitClass("player")
            if class == "ROGUE" then
                StartShroudCountdown()
            end
        end
    end
end)

