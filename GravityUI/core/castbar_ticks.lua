local ADDON_NAME, ns = ...
local M = {}
ns.CastbarTicks = M

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION & DATA
-- ═══════════════════════════════════════════════════════════════

local SPELL_DATA = {
    -- EVOKER: Disintegrate
    [356995] = {
        key = "DISINTEGRATE",
        baseDuration = 3,
        baseTicks = 3, 
        tickCount = 4, 
        talentID = 1219723, -- Scintillation
        talentBonusTicks = 1,
        eternityID = 369913, -- Eternity Surge
        eternityDurationMod = 0.8,
    },
    -- PRIEST: Mind Flay
    [15407] = {
        key = "MINDFLAY",
        baseDuration = 3, -- Standard Retail
        tickCount = 4,    -- Standard Retail (0.75s interval)
    },
    [391403] = { -- Mind Flay: Insanity
        key = "MINDFLAY",
        baseDuration = 3,
        tickCount = 4,
    },
     -- German Localization Backup Check (Names)
    ["Disintegrate"] = { type = "DISINTEGRATE" },
    ["Desintegration"] = { type = "DISINTEGRATE" },
    ["Mind Flay"] = { type = "MINDFLAY" },
    ["Gedankenschinden"] = { type = "MINDFLAY" },
}

-- ═══════════════════════════════════════════════════════════════
-- MODULE STATE
-- ═══════════════════════════════════════════════════════════════

local EventFrame = CreateFrame("Frame")
EventFrame.Ticks = {}
EventFrame.ChainedTicks = {}
EventFrame.ActiveSpell = nil

EventFrame.CastBarInfo = {
    width = 0,
    height = 0,
    anchor = nil,
}

EventFrame.State = {
    isChanneling = false,
    isChaining = false,
    numTicks = 0,
    duration = 0,
    tickInterval = 0,
}

-- ═══════════════════════════════════════════════════════════════
-- CORE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function CreateTick(parent)
    local texture = parent:CreateTexture(nil, "OVERLAY")
    texture:SetColorTexture(1, 1, 1, 0.7) -- Slightly transparent to look cleaner
    texture:SetSize(2, parent:GetHeight() * 0.9)
    texture:Hide()
    return texture
end

function EventFrame:UpdateLayout()
    if not self.CastBarInfo.anchor then return end

    -- Fetch config
    local db = ns.GetDB()
    local category = (self.ActiveSpell == "DISINTEGRATE" and "disintegrate") or "mindflay"
    local cfg = db and db.general.castbarTicks[category]
    
    local cWidth = cfg and cfg.tickWidth or 2
    local cHeight = cfg and cfg.tickHeight or 0.6
    local cColor = cfg and cfg.tickColor or {1, 1, 1, 0.7}

    local width = self.CastBarInfo.width
    local height = self.CastBarInfo.height
    local numMarks = math.max(0, self.State.numTicks - 1)
    
    local tickWidth = width / self.State.numTicks
    
    for i = 1, numMarks do
        -- Create if needed
        if not self.Ticks[i] then self.Ticks[i] = self.CastBarInfo.anchor:CreateTexture(nil, "OVERLAY") end
        local t = self.Ticks[i]
        
        -- Parent Check (if anchor changed newly)
        if t:GetParent() ~= self.CastBarInfo.anchor then
             t:Hide()
             self.Ticks[i] = self.CastBarInfo.anchor:CreateTexture(nil, "OVERLAY")
             t = self.Ticks[i]
        end
        
        t:SetColorTexture(cColor[1], cColor[2], cColor[3], cColor[4] or 1)
        t:SetSize(cWidth, height * cHeight)
        t:ClearAllPoints()
        
        t:SetPoint("CENTER", self.CastBarInfo.anchor, "RIGHT", -(i * tickWidth), 0)
        
        -- Hide initially, shown in Channel Start usually, but let's hide here to be safe
        t:Hide()
        
        -- If we are ALREADY channeling, show it immediately (live update support)
        if self.State.isChanneling then t:Show() end
    end
    
    -- Hide unused
    for i = numMarks + 1, #self.Ticks do
        if self.Ticks[i] then self.Ticks[i]:Hide() end
    end
end

function EventFrame:UpdateChainedLayout()
    -- Similar logic but relative to 'active' bar portion
end

function EventFrame:Reset()
    for _, t in pairs(self.Ticks) do t:Hide() end
    self.State.isChanneling = false
    self.State.isChaining = false
end

-- ═══════════════════════════════════════════════════════════════
-- DATA CALCULATIONS
-- ═══════════════════════════════════════════════════════════════

function EventFrame:GetTickConfig(spellID, spellName)
    local data = SPELL_DATA[spellID] or SPELL_DATA[spellName]
    
    if not data then return nil end
    
    local ticks = data.tickCount or 4
    local duration = data.baseDuration or 3
    
    -- Evoker Specifics
    if data.key == "DISINTEGRATE" then
        local isScintillation = C_SpellBook.IsSpellKnown(data.talentID)
        if isScintillation then ticks = ticks + (data.talentBonusTicks or 1) end
        
        local isEternity = C_SpellBook.IsSpellKnown(data.eternityID)
        if isEternity then duration = duration * (data.eternityDurationMod or 0.8) end
    end
    
    return ticks, duration
end

-- ═══════════════════════════════════════════════════════════════
-- HANDLERS
-- ═══════════════════════════════════════════════════════════════

EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        M:SetupHooks()
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit ~= "player" then return end
        
        local name, _, _, startTimeMs, endTimeMs, _, _, spellID = UnitChannelInfo("player")
        
        -- Detect Spell
        local ticks, baseDuration = self:GetTickConfig(spellID, name)
        if not ticks then 
            self:Reset()
            return 
        end
        
        self.State.numTicks = ticks
        self.State.duration = (endTimeMs - startTimeMs) / 1000
        self.State.tickInterval = self.State.duration / self.State.numTicks
        
        -- Rebuild/Update Ticks
        self:UpdateLayout()
        
        -- Show Ticks
        for i = 1, math.max(0, ticks - 1) do
            if self.Ticks[i] then self.Ticks[i]:Show() end
        end
        
        self.State.isChanneling = true

    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        local unit = ...
        if unit ~= "player" then return end
        
        local name, _, _, startTimeMs, endTimeMs, _, _, spellID = UnitChannelInfo("player")
        if not name or not self.State.tickInterval or self.State.tickInterval == 0 then return end
        
        local newDuration = (endTimeMs - startTimeMs) / 1000
        local newTicks = math.floor((newDuration / self.State.tickInterval) + 0.5)
        
        if newTicks ~= self.State.numTicks then
             self.State.numTicks = newTicks
             self.State.duration = newDuration
             self:UpdateLayout()
             
             -- Ensure visibility of new ticks
             for i = 1, math.max(0, newTicks - 1) do
                if self.Ticks[i] then self.Ticks[i]:Show() end
             end
        end
        
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        self:Reset()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- LIFECYCLE
-- ═══════════════════════════════════════════════════════════════

function M:SetupHooks()
    local db = ns.GetDB()
    if not db then return end
    
    -- Determine category
    local _, _, classID = UnitClass("player")
    local specID = PlayerUtil.GetCurrentSpecID()
    
    local category = nil
    if classID == 13 and specID == 1467 then category = "disintegrate"
    elseif classID == 5 and specID == 258 then category = "mindflay"
    end
    
    if not category then return end
    
    local cfg = db.general.castbarTicks[category]
    if not cfg then return end

    -- Helper to attach
    local function Attach(bar, isBCDM)
        if not bar then return end
        
        -- Hook Showing
        if not EventFrame.HookedBars then EventFrame.HookedBars = {} end
        if EventFrame.HookedBars[bar] then return end
        
        hooksecurefunc(bar, "Show", function(self)
             local w, h = self:GetSize()
             EventFrame.CastBarInfo.width = w
             EventFrame.CastBarInfo.height = h
             EventFrame.CastBarInfo.anchor = isBCDM and (self.Status or self) or self
             EventFrame:UpdateLayout()
        end)
        
        -- Attach immediately if visible
        if bar:IsVisible() then
             local w, h = bar:GetSize()
             EventFrame.CastBarInfo.width = w
             EventFrame.CastBarInfo.height = h
             EventFrame.CastBarInfo.anchor = isBCDM and (bar.Status or bar) or bar
             EventFrame:UpdateLayout()
        end
        
        EventFrame.HookedBars[bar] = true
    end

    -- Hook UUF
    if cfg.enableUUF and C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") then
        local ace = LibStub("AceAddon-3.0", true)
        if ace then
            local ok, UUF = pcall(ace.GetAddon, ace, "UnhaltedUnitFrames", true)
            if ok and UUF then
                if UUF.OnEnable then
                    hooksecurefunc(UUF, "OnEnable", function()
                        if UUF_Player_CastBar then Attach(UUF_Player_CastBar, false) end
                    end)
                end
            end
        end
        -- Try direct if already loaded
        if UUF_Player_CastBar then Attach(UUF_Player_CastBar, false) end
    end

    -- Hook BCDM
    if cfg.enableBCDM and C_AddOns.IsAddOnLoaded("BetterCooldownManager") then
        local ace = LibStub("AceAddon-3.0", true)
        if ace then
            local ok, BCDM = pcall(ace.GetAddon, ace, "BetterCooldownManager", true)
            if ok and BCDM then
                if BCDM.OnEnable then
                     hooksecurefunc(BCDM, "OnEnable", function()
                        if BCDM_CastBar then Attach(BCDM_CastBar, true) end
                     end)
                end
            end
        end
        -- Try direct
        if BCDM_CastBar then Attach(BCDM_CastBar, true) end
    end
end

function M:Initialize()
    EventFrame:RegisterEvent("PLAYER_LOGIN") -- Essential for DB init
    EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player") -- For Chaining support later
    EventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    
    -- Removed direct call to SetupHooks as it fails before DB load
end

M:Initialize()
