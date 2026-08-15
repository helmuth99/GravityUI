local ADDON_NAME, ns = ...
local InterruptTracker = {}
ns.InterruptTracker = InterruptTracker
LibStub("AceEvent-3.0"):Embed(InterruptTracker)

-- ============================================================================
-- CONSTANTS & DATA
-- ============================================================================
local LSM = LibStub("LibSharedMedia-3.0", true)

-- Main Config (Unified source of truth)
local INTERRUPT_CONFIG = {
    -- DEATH KNIGHT
    { class = "DEATHKNIGHT", spellID = 47528, cd = 15, isDefault = true }, -- Mind Freeze
    -- DEMON HUNTER
    { class = "DEMONHUNTER", spellID = 183752, cd = 15, isDefault = true }, -- Disrupt
    -- DRUID
    { class = "DRUID", spellID = 106839, cd = 15, isDefault = true },       -- Skull Bash (Feral/Guardian)
    { class = "DRUID", spellID = 78675, cd = 45, specID = 102 },            -- Solar Beam (Balance) – 45s not 60s
    -- EVOKER
    { class = "EVOKER", spellID = 351338, cd = 18, isDefault = true, talents = { [412713] = { pctReduction = 0.1 } } }, -- Quell – 18s not 40s
    -- HUNTER
    { class = "HUNTER", spellID = 147362, cd = 24, isDefault = true, talents = { [388039] = { reduction = 2 } } }, -- Counter Shot
    { class = "HUNTER", spellID = 187707, cd = 15, specID = 255, talents = { [388039] = { reduction = 2 } } },     -- Muzzle (Survival)
    -- MAGE
    { class = "MAGE", spellID = 2139, cd = 20, isDefault = true },          -- Counterspell – 20s not 24s
    -- MONK
    { class = "MONK", spellID = 116705, cd = 15, isDefault = true },        -- Spear Hand Strike
    -- PALADIN
    { class = "PALADIN", spellID = 96231, cd = 15, isDefault = true },      -- Rebuke
    { class = "PALADIN", spellID = 420090, cd = 15 },                       -- NPC Rebuke (Follower Dungeon)
    -- PRIEST
    { class = "PRIEST", spellID = 15487, cd = 30, specID = 258, isDefault = true }, -- Silence (Shadow) – 30s not 45s
    -- ROGUE
    { class = "ROGUE", spellID = 1766, cd = 15, isDefault = true },         -- Kick
    -- SHAMAN
    { class = "SHAMAN", spellID = 57994, cd = 12, isDefault = true, overrides = { [264] = 30 } }, -- Wind Shear (Resto: 30s)
    -- WARLOCK
    -- 12.0.5: Demo uses Axe Toss (pet, 30s) as primary. Affliction/Destro use Spell Lock (24s).
    -- The extra Spell Lock bar for Demo (SPEC_EXTRA_KICKS) was removed in 12.0.5.
    { class = "WARLOCK", spellID = 19647,  cd = 24, isDefault = true },     -- Spell Lock (Aff/Destro)
    { class = "WARLOCK", spellID = 132409, cd = 24 },                       -- Spell Lock alias (Fel Ravager)
    { class = "WARLOCK", spellID = 119914, cd = 30, specID = 266 },         -- Axe Toss (Demo, pet)
    -- WARRIOR
    { class = "WARRIOR", spellID = 6552, cd = 15, isDefault = true },       -- Pummel
}


-- Runtime Lookup Tables (Populated from CONFIG)
local INTERRUPTS = {}              -- [spellID] = baseCD
local CLASS_INTERRUPTS = {}        -- [class] = defaultSpellID
local SPEC_INTERRUPTS = {}         -- [specID] = spellID
local SPEC_COOLDOWN_OVERRIDES = {} -- [spellID] = { [specID] = cd }
local CD_REDUCTION_TALENTS = {}    -- [talentID] = { affects, reduction, pctReduction }
local CD_ON_KICK_TALENTS = {       -- [talentID] = { reduction }
    [378848] = { reduction = 3 }   -- DK: Coldthirst
}
-- 12.0.5: SPEC_EXTRA_KICKS[266] removed — Demo Warlock no longer has a second interrupt.
-- They only have Axe Toss (via Felguard pet). Grimoire of Sacrifice / Fel Ravager
-- extra bars were simplified out in the 12.0.5 rework.
local SPEC_EXTRA_KICKS = {}

local SPELL_ALIASES = {
    [1276467] = 132409, -- Fel Ravager summon -> Spell Lock extra bar
    [89766] = 119914,   -- Felguard Axe Toss (pet) -> Axe Toss (player)
}
-- String-keyed version for taint-safe lookups (tostring(taintedID) still works)
local SPELL_ALIASES_STR = {}
-- Automatically register talents that grant an extra kick
local EXTRA_KICK_TALENTS = {
    [385110] = { id = 1276467, cd = 25, name = "Fel Ravager" }, -- Warlock Grimoire of Sacrifice
}
-- Specs that have NO interrupt at all (healer specs that can't kick)
-- BliZzi SPEC_NO_INTERRUPT equivalent
local SPEC_NO_INTERRUPT = {
    [65]  = true,  -- Paladin: Holy
    [256] = true,  -- Priest: Discipline
    [257] = true,  -- Priest: Holy
    [270] = true,  -- Monk: Mistweaver
    [105] = true,  -- Druid: Restoration
    -- NOTE: Shaman Restoration (264) intentionally excluded — Resto Shaman keeps Wind Shear
}

-- Classes that keep their interrupt even as healer spec (BliZzi HEALER_KEEPS_KICK parity)
local HEALER_KEEPS_KICK = {
    SHAMAN = true,  -- Restoration Shaman keeps Wind Shear
}

local function BuildInterruptTables()
    for _, data in ipairs(INTERRUPT_CONFIG) do
        -- 1. Base Cooldown Table
        INTERRUPTS[data.spellID] = data.cd
        
        -- 2. Class Defaults
        if data.isDefault then
            CLASS_INTERRUPTS[data.class] = data.spellID
        end
        
        -- 3. Spec Specific Mappings
        if data.specID then
            SPEC_INTERRUPTS[data.specID] = data.spellID
        end
        
        -- 4. Spec Specific CD Overrides
        if data.overrides then
            SPEC_COOLDOWN_OVERRIDES[data.spellID] = data.overrides
        end

        -- 5. Talent Reductions
        if data.talents then
            for talentID, talentData in pairs(data.talents) do
                CD_REDUCTION_TALENTS[talentID] = {
                    affects = data.spellID,
                    reduction = talentData.reduction,
                    pctReduction = talentData.pctReduction
                }
            end
        end
    end

    for aliasID, targetID in pairs(SPELL_ALIASES) do
        if INTERRUPTS[targetID] then
            INTERRUPTS[aliasID] = INTERRUPTS[targetID]
        end
        SPELL_ALIASES_STR[tostring(aliasID)] = targetID
    end
end
BuildInterruptTables()

-- String-keyed INTERRUPTS for taint-safe lookups (built after BuildInterruptTables)
local INTERRUPTS_STR = {}
do
    for id in pairs(INTERRUPTS) do INTERRUPTS_STR[tostring(id)] = id end
end

-- noKick: names of party members known to have no interrupt (healer spec confirmed)
local noKickPlayers = {}   -- [name] = true

local CLASS_COLORS = {
    ["DEATHKNIGHT"] = {0.77, 0.12, 0.23},
    ["DEMONHUNTER"] = {0.64, 0.19, 0.79},
    ["DRUID"]       = {1.00, 0.49, 0.04},
    ["EVOKER"]      = {0.20, 0.58, 0.50},
    ["HUNTER"]      = {0.67, 0.83, 0.45},
    ["MAGE"]        = {0.25, 0.78, 0.92},
    ["MONK"]        = {0.00, 1.00, 0.59},
    ["PALADIN"]     = {0.96, 0.55, 0.73},
    ["PRIEST"]      = {1.00, 1.00, 1.00},
    ["ROGUE"]       = {1.00, 0.96, 0.41},
    ["SHAMAN"]      = {0.00, 0.44, 0.87},
    ["WARLOCK"]     = {0.53, 0.53, 0.93},
    ["WARRIOR"]     = {0.78, 0.61, 0.43},
}

-- Active Bars State
local activeBars = {}
local framePool = {}
-- PERF: Hoisted to module scope – wipe() instead of new-table allocation in UpdateLayout.
local sortedBars = {}
-- ============================================================================
-- DYNAMIC COOLDOWN DATA
-- ============================================================================



local activeReductions = {}
local activeSpecs = {}
local container = nil
local testModeActive = false

-- ============================================================================
-- SPELL ID LAUNDERING (Slider only – StatusBar path removed in 12.0.5)
-- ============================================================================
local launderSlider = CreateFrame("Slider", nil, UIParent)
launderSlider:SetMinMaxValues(0, 9999999)
launderSlider:SetSize(1, 1)
launderSlider:Hide()
local onSliderChangedResult = nil
launderSlider:SetScript("OnValueChanged", function(_, v) onSliderChangedResult = v end)

-- Party Registry: tracks known interrupt spell per party member
local partyRegistry = {}  -- [name] = { class, spellID, baseCd, cdEnd, guid, unit }
local recentCasts    = {}  -- [name] = { t, spellID }  used by signal-tape correlation

-- Signal-Tape Engine (BliZzi approach, 12.0.5 compatible)
local signalTape       = {}
local needsCorrelation = false
local lastCorrelateAt  = 0
local SIGNAL_RETENTION   = 0.35
local CORRELATE_INTERVAL = 0.04
local MATCH_WINDOW       = 0.055
local AURA_SUPPRESS      = 0.028

local function PushSignal(kind, unit)
    signalTape[#signalTape + 1] = { kind = kind, unit = unit, at = GetTime(), consumed = false }
    needsCorrelation = true
end

local function PruneSignalTape(now)
    local kept, minAt = {}, now - SIGNAL_RETENTION
    for i = 1, #signalTape do
        local s = signalTape[i]
        if s and s.at and s.at >= minAt then kept[#kept + 1] = s end
    end
    signalTape = kept
end

-- Back-compat stub (called from OnGroupRosterUpdate / Initialize)
local function RegisterPartyWatchers() end

-- ============================================================================
-- RESOLVE INTERRUPT SPELL (BliZzi ResolveInterruptSpell port)
-- Handles tainted spellIDs from party UNIT_SPELLCAST_SUCCEEDED in 12.0.5.
-- Priority: spell-name lookup (issecretvalue guard) → GetBaseSpell → direct ID
--           → alias lookup → slider launder
-- Returns: cleanID (number) or nil
-- ============================================================================
local function ResolveInterruptSpell(spellID)
    -- Guard: nil spellID is a no-op
    if spellID == nil then return nil end

    -- 1. Spell-name path: often works even when the ID is tainted
    local okN, spellName = pcall(C_Spell.GetSpellName, spellID)
    if okN and spellName and not issecretvalue(spellName) then
        -- fall through to ID-based paths; name used as confirmation only
    end

    -- 2. GetBaseSpell can sometimes give a clean ID
    local cleanID = spellID
    do
        local ok2, baseID = pcall(C_Spell.GetBaseSpell, spellID)
        if ok2 and baseID then cleanID = baseID end
    end

    -- 3. Direct ID lookup (cleanID may still be tainted — wrap in pcall)
    do
        local ok3, hit = pcall(function() return INTERRUPTS[cleanID] end)
        if ok3 and hit then
            local ok4, alias = pcall(function() return SPELL_ALIASES[cleanID] end)
            return (ok4 and alias) or cleanID
        end
    end

    -- 4. String-based alias lookup
    -- tostring() on a tainted value produces a tainted string;
    -- indexing a table with a tainted string also crashes → wrap everything in pcall.
    do
        local okS, idStr = pcall(tostring, spellID)
        if okS and idStr then
            local okA, aliasTarget = pcall(function() return SPELL_ALIASES_STR[idStr] end)
            if okA and aliasTarget then
                local okB, hitB = pcall(function() return INTERRUPTS[aliasTarget] end)
                if okB and hitB then return aliasTarget end
            end
            local okC, rawNum = pcall(function() return INTERRUPTS_STR[idStr] end)
            if okC and rawNum then return rawNum end
        end
    end

    -- 5. Slider launder (last resort)
    -- After SetValue the OnValueChanged fires synchronously; the result is
    -- a laundered (untainted) number if the engine accepted the value.
    onSliderChangedResult = nil
    pcall(launderSlider.SetValue, launderSlider, 0)
    onSliderChangedResult = nil
    local sliderOk = pcall(launderSlider.SetValue, launderSlider, spellID)
    if sliderOk and onSliderChangedResult and onSliderChangedResult ~= 0 then
        local okT, s = pcall(tostring, onSliderChangedResult)
        if okT and s then
            local num = tonumber(s)
            if num then
                local ok5, hit5 = pcall(function() return INTERRUPTS[num] end)
                if ok5 and hit5 then
                    local ok6, alias6 = pcall(function() return SPELL_ALIASES[num] end)
                    return (ok6 and alias6) or num
                end
            end
        end
    end

    return nil
end




-- ============================================================================
-- FRAME MANAGEMENT
-- ============================================================================

local function IsTrackerAllowed()
    if testModeActive then return true end
    if not IsInGroup() then return false end
    if IsInRaid() then return false end
    
    local _, instanceType = IsInInstance()
    if instanceType == "raid" then return false end
    
    return true
end

local function GetSettings()
    local db = ns.GetDB()
    if db and db.screenindicators then
        if not db.screenindicators.interruptTracker then
            db.screenindicators.interruptTracker = {
                enabled = false,
                x = 0, y = 0,
                width = 220, height = 20,
                barHeight = 20,
                iconSize = 20,
                fontSize = 12,
                font = "Gravity",
                texture = "Gravity Normal",
                growDirection = "UP",
                useClassColors = true,
                showBorder = true,
                showIcon = true,
                showTime = true,
                showReadyText = true,
                testMode = false,
                useSpecificCooldownColor = false,
                cooldownTextColor = {1, 1, 1, 1},
                fontOutline = "OUTLINE",
                barColor = {0.129, 0.129, 0.129, 0.85},
                textColor = {1, 1, 1, 1},
                useClassColor = false,
                sayKick = false,
                sayKickChannel = "SAY",
            }
        end
        
        return db.screenindicators.interruptTracker
    end
    return nil
end

local function CreateBarFrame()
    local f = CreateFrame("Frame", nil, container, "BackdropTemplate")
    local s = GetSettings()
    
    -- Status Bar
    f.bar = CreateFrame("StatusBar", nil, f)
    f.bar:SetAllPoints()
    f.bar:SetMinMaxValues(0, 1)
    
    -- Background
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Icon
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Text (Name)
    f.name = f.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.name:SetJustifyH("LEFT")
    
    -- Text (Time)
    f.time = f.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.time:SetJustifyH("RIGHT")
    
    -- Border/Backdrop logic applied in StyleBar
    
    return f
end

local elvuiFont = nil
local elvuiTexture = nil

local function DetectElvUI()
    if ElvUI then
        local ok, E = pcall(unpack, ElvUI)
        if ok and E and E.media then
            if E.media.normFont then elvuiFont = E.media.normFont end
            if E.media.normTex then elvuiTexture = E.media.normTex end
        end
    end
end

-- Call detection immediately
DetectElvUI()

local function StyleBar(f, class)
    local s = GetSettings()
    if not s then return end
    
    -- Safety for NPCs/Invalid Class
    if not class or not RAID_CLASS_COLORS[class] then class = "PRIEST" end
    
    local width = s.width or 200
    local height = s.height or 20
    
    f:SetSize(width, height)
    
    -- Texture
    local texture = "Interface\\TargetingFrame\\UI-StatusBar"
    if elvuiTexture then
        texture = elvuiTexture
    elseif LSM then
        texture = LSM:Fetch("statusbar", s.texture or "Gravity")
    end
    f.bar:SetStatusBarTexture(texture)
    f.bg:SetTexture(texture)
    
    -- Font
    local font = "Fonts\\FRIZQT__.TTF"
    if elvuiFont then
        font = elvuiFont
    elseif LSM then
         font = LSM:Fetch("font", s.font or "Gravity")
    end
    local flags = s.fontOutline or "OUTLINE"
    local size = s.fontSize or 10
    
    f.name:SetFont(font, size, flags)
    f.time:SetFont(font, size, flags)
    
    -- Layout
    f.icon:ClearAllPoints()
    f.icon:SetSize(height, height)
    f.icon:SetPoint("RIGHT", f, "LEFT", 0, 0)
    
    f.name:ClearAllPoints()
    f.name:SetPoint("LEFT", f.bar, "LEFT", 4, 0)
    
    f.time:ClearAllPoints()
    f.time:SetPoint("RIGHT", f.bar, "RIGHT", -4, 0)
    
    -- Colors: Background (Bar BG)
    local bgr, bgg, bgb, bga = 0, 0, 0, 0.5
    if s.useClassColorBackdrop and class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        bgr, bgg, bgb, bga = c.r, c.g, c.b, 0.5
    elseif s.useThemeBackdropColor and ns.GetThemeBgColor then
         bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    elseif s.backdropColor then
         local c = s.backdropColor
         bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4]
    end
    f.bg:SetVertexColor(bgr, bgg, bgb, bga)
    
    -- Colors: Bar
    local r, g, b, a = 1, 1, 1, 1
    if s.useClassColor and class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        r, g, b, a = c.r, c.g, c.b, 1
    elseif s.useThemeBarColor and ns.GetAccentColor then
        r, g, b, a = ns.GetAccentColor()
    else
        local c = s.barColor
        if c then r, g, b, a = c[1], c[2], c[3], c[4] end
    end
    f.bar:SetStatusBarColor(r, g, b, a)
    
    -- Colors: Text (Name)
    local tr, tg, tb, ta = 1, 1, 1, 1
    if s.useClassColorText and class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        tr, tg, tb, ta = c.r, c.g, c.b, 1
    elseif s.useThemeFontColor and ns.GetAccentColor then
        tr, tg, tb, ta = ns.GetAccentColor()
    else
        local c = s.textColor
        if c then tr, tg, tb, ta = c[1], c[2], c[3], c[4] end
    end
    f.name:SetTextColor(tr, tg, tb, ta)
    
    -- Colors: Text (Time/Ready)
    local cr, cg, cb, ca = tr, tg, tb, ta
    if s.useSpecificCooldownColor then
        local c = s.cooldownTextColor or {1, 1, 1, 1}
        cr, cg, cb, ca = c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
    end
    f.time:SetTextColor(cr, cg, cb, ca)

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
end

local function GetBar()
    -- Try recycle
    for _, f in ipairs(framePool) do
        if not f:IsShown() then
            -- Note: We re-style in StartCooldown now to ensure correct class color
            return f
        end
    end
    -- Create new
    local f = CreateBarFrame()
    -- StyleBar called later with class
    table.insert(framePool, f)
    return f
end

local function UpdateLayout()
    if not container then return end
    local s = GetSettings()
    if not s then return end
    
    -- Removed Red Box
    container:SetBackdropColor(0, 0, 0, 0)
    container:SetBackdropBorderColor(0, 0, 0, 0)
    
    local yOffset = 0
    local spacing = s.spacing or 2
    local height = s.height or 20
    
    -- PERF: Reuse module-scope table instead of allocating a new one each call.
    wipe(sortedBars)
    for _, info in pairs(activeBars) do
        sortedBars[#sortedBars + 1] = info
    end
    
    table.sort(sortedBars, function(a, b)
        local aExp = a.expiration or 0
        local bExp = b.expiration or 0
        
        -- Always put Ready (0) at the top
        if aExp == 0 and bExp ~= 0 then return true end
        if bExp == 0 and aExp ~= 0 then return false end
        
        -- If both are on cooldown, sort by which one finishes first
        if aExp ~= bExp then
             return aExp < bExp
        end
        
        -- Tie-breaker: sort alphabetically by name
        return a.name < b.name
    end)
    
    for i, info in ipairs(sortedBars) do
        local f = info.frame
        f:ClearAllPoints()
        if s.growDirection == "UP" then
            f:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, yOffset)
        else
            f:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -yOffset)
        end
        f:Show()
        yOffset = yOffset + height + spacing
    end
end


local UPDATE_THROTTLE = 0.05
local timeSinceLastUpdate = 0

local DEFAULT_COLOR = {1, 1, 1, 1}

-- PERF: Cached settings for the OnUpdate hot-path.
-- Avoids calling GetSettings() (a multi-level table lookup) 20x per second.
-- Invalidated by calling InvalidateOnUpdateCache() whenever settings change.
local _cachedShowReadyText = true
local _cachedUseSpecificColor = false
local _cachedCooldownColor = DEFAULT_COLOR
local _settingsCacheValid = false

local function InvalidateOnUpdateCache()
    _settingsCacheValid = false
end

local function RefreshOnUpdateCache()
    local s = GetSettings()
    if s then
        _cachedShowReadyText      = s.showReadyText ~= false
        _cachedUseSpecificColor   = s.useSpecificCooldownColor == true
        _cachedCooldownColor      = (s.useSpecificCooldownColor and s.cooldownTextColor) or DEFAULT_COLOR
    end
    _settingsCacheValid = true
end

local function OnUpdate(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate < UPDATE_THROTTLE then return end
    timeSinceLastUpdate = 0

    if not next(activeBars) then
        self:Hide()
        return
    end

    -- PERF: Refresh cache only when invalidated, not every tick.
    if not _settingsCacheValid then RefreshOnUpdateCache() end

    local now = GetTime()
    local dirty = false
    local readyText = _cachedShowReadyText and "Ready" or ""
    local cr = _cachedCooldownColor[1] or 1
    local cg = _cachedCooldownColor[2] or 1
    local cb = _cachedCooldownColor[3] or 1
    local ca = _cachedCooldownColor[4] or 1
    
    -- Check expiration
    for key, info in pairs(activeBars) do
        if info.duration > 0 then
            -- Active Cooldown
            if now >= info.expiration then
                -- Expired -> Ready
                info.duration = 0
                info.expiration = 0
                info.frame.bar:SetValue(1) -- Set bar to full
                
                if info.frame.time:GetText() ~= readyText then
                    info.frame.time:SetText(readyText)
                end
                
                -- Reset Color to Ready Color
                info.frame.time:SetTextColor(cr, cg, cb, ca)
                
                dirty = true
            else
                -- Update Timer Text
                local remaining = info.expiration - now
                local pct = remaining / info.duration
                info.frame.bar:SetValue(pct) -- Update bar value
                
                -- Optimization: Only format and set text if the decisecond value changed
                local rem10 = math.ceil(remaining * 10)
                if info.lastRem10 ~= rem10 then
                    info.lastRem10 = rem10
                    info.frame.time:SetText(string.format("%.1f", math.max(0, remaining)))
                end
            end
        else
            -- Already Ready
            if info.frame.time:GetText() ~= readyText then
                info.frame.time:SetText(readyText)
            end
        end
    end
    
    if dirty then UpdateLayout() end
end

local updateFrame = CreateFrame("Frame", "GravityUI_InterruptTrackerUpdate", UIParent)
updateFrame:Hide()
updateFrame:SetScript("OnUpdate", OnUpdate)

-- ============================================================================
-- LOGIC
-- ============================================================================

local function StartCooldown(guid, name, class, spellId, isReady)
    local s = GetSettings()
    if not s or not s.enabled then return end
    if not IsTrackerAllowed() then return end
    
    local baseCD = INTERRUPTS[spellId]
    if not baseCD then return end
    
    -- Apply Spec-Specific Cooldown Override
    if activeSpecs[guid] and SPEC_COOLDOWN_OVERRIDES[spellId] and SPEC_COOLDOWN_OVERRIDES[spellId][activeSpecs[guid]] then
        baseCD = SPEC_COOLDOWN_OVERRIDES[spellId][activeSpecs[guid]]
    end
    
    -- print("GravityUI Debug: StartCooldown", name, spellId, isReady)

    -- Check duplicates (Key-based mapping for O(1) and guaranteed uniqueness)
    local key = guid .. spellId
    local info = activeBars[key]
    
    if info then
        -- Refresh existing bar
        if not isReady then
            -- Dynamic CD Logic
            local duration = baseCD
            if activeReductions[guid] then
                if activeReductions[guid][spellId] then
                    duration = duration - activeReductions[guid][spellId]
                end
                if activeReductions[guid]["PCT_" .. spellId] then
                    duration = duration * (1 - activeReductions[guid]["PCT_" .. spellId])
                end
            end
            
            info.expiration = GetTime() + duration
            info.duration = duration
            
            -- Update Text
            info.frame.time:SetText(string.format("%.1f", duration))
             -- Reset Color to CD Color
            local r, g, b, a = 1, 1, 1, 1
            if s.useSpecificCooldownColor and s.cooldownTextColor then
                local c = s.cooldownTextColor
                r, g, b, a = c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
            end
            info.frame.time:SetTextColor(r, g, b, a)
        else
            -- If it's a "ready" bar and we find an existing one, ensure it's in ready state
            info.expiration = 0
            info.duration = 0
            if s.showReadyText then
                info.frame.time:SetText("Ready")
            else
                info.frame.time:SetText("")
            end
            -- Reset Color to Ready Color (if different)
            local cr, cg, cb, ca = 1, 1, 1, 1
            if s.useSpecificCooldownColor then
                local c = s.cooldownTextColor or DEFAULT_COLOR
                cr, cg, cb, ca = c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
            end
            info.frame.time:SetTextColor(cr, cg, cb, ca)
        end
        -- Re-apply styling
        StyleBar(info.frame, class)
        UpdateLayout()
        return
    end
    
    -- Create new
    local f = GetBar()
    
    local spellName, _, spellIcon = C_Spell.GetSpellName(spellId), nil, C_Spell.GetSpellTexture(spellId)
    
    -- Apply styling with class info
    StyleBar(f, class)
    
    f.icon:SetTexture(spellIcon)
    f.name:SetText(name) 
    
    local duration = 0
    local expiration = 0
    
    if not isReady then
        duration = baseCD
        -- Dynamic CD Logic
        if activeReductions[guid] then
            if activeReductions[guid][spellId] then
                duration = duration - activeReductions[guid][spellId]
            end
            if activeReductions[guid]["PCT_" .. spellId] then
                duration = duration * (1 - activeReductions[guid]["PCT_" .. spellId])
            end
        end
        expiration = GetTime() + duration
        f.time:SetText(string.format("%.1f", duration))
    else
        if s.showReadyText then
             f.time:SetText("Ready")
        else
             f.time:SetText("")
        end
        f.bar:SetValue(1)
    end
    
    local info = {
        guid = guid,
        name = name,
        class = class,
        spellId = spellId,
        baseDuration = duration,
        expiration = expiration,
        duration = duration,
        frame = f
    }
    activeBars[key] = info
    
    updateFrame:Show() -- Ensure OnUpdate is running
    UpdateLayout()
    
    -- (Say Kick Logic Removed)
end



-- ============================================================================
-- HANDLE PARTY CAST (triggered by correlation or mob-attribution)
-- ============================================================================
local function HandlePartyCast(memberName, spellID)
    if not IsTrackerAllowed() then return end
    local entry = partyRegistry[memberName]
    if not entry then return end
    local cd = INTERRUPTS[spellID] or entry.baseCd or 15
    local now = GetTime()
    entry.cdEnd = now + cd
    if entry.guid then
        StartCooldown(entry.guid, memberName, entry.class, spellID)
    end
end

-- ============================================================================
-- AUTO-REGISTER PARTY MEMBERS BY CLASS
-- ============================================================================
-- Classes that CAN have healer specs and must wait for spec confirmation before being registered.
-- Registering them immediately (when spec is unknown) risks showing bars for Holy Paladins, Resto Druids, etc.
local HEALER_CAPABLE_CLASS = {
    PALADIN = true,  -- Holy / Prot / Ret
    PRIEST  = true,  -- Discipline / Holy / Shadow
    MONK    = true,  -- Mistweaver / Brewmaster / Windwalker
    DRUID   = true,  -- Restoration / Balance / Feral / Guardian
    -- NOTE: SHAMAN excluded intentionally — Resto Shaman keeps Wind Shear (HEALER_KEEPS_KICK)
}

local function AutoRegisterPartyByClass()
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) and UnitIsPlayer(u) then
            local name = UnitName(u)
            local _, cls = UnitClass(u)
            -- Skip if already known to have no kick
            if name and cls and CLASS_INTERRUPTS[cls] and not partyRegistry[name] and not noKickPlayers[name] then
                local role = UnitGroupRolesAssigned(u)
                if role ~= "HEALER" or HEALER_KEEPS_KICK[cls] then
                    local guid   = UnitGUID(u)
                    local sid    = CLASS_INTERRUPTS[cls]
                    local specID = GetInspectSpecialization(u)
                    local noKick = false
                    if specID and specID > 0 then
                        if SPEC_NO_INTERRUPT[specID] then
                            noKickPlayers[name] = true
                            noKick = true
                        elseif SPEC_INTERRUPTS[specID] then
                            sid = SPEC_INTERRUPTS[specID]
                        end
                    else
                        -- Spec not yet available.
                        -- For classes that CAN be healers (Paladin, Priest, Monk, Druid),
                        -- defer registration to the retry loop to avoid false-positive healer bars.
                        if HEALER_CAPABLE_CLASS[cls] then
                            noKick = true  -- skip now; retry loop will register if they turn out to be DPS/Tank
                        end
                    end
                    if not noKick then
                        partyRegistry[name] = {
                            class   = cls,
                            spellID = sid,
                            baseCd  = INTERRUPTS[sid] or 15,
                            cdEnd   = 0,
                            guid    = guid,
                            unit    = u,
                        }
                    end
                end
            end
        end
    end
    -- BliZzi parity: extended retry schedule for slow inspect data (dungeons/M+)
    for _, delay in ipairs({ 1, 2, 4, 8, 15, 25 }) do
        C_Timer.After(delay, function()
            for i = 1, 4 do
                local u = "party" .. i
                if UnitExists(u) then
                    local name = UnitName(u)
                    local _, cls = UnitClass(u)
                    if not name or not cls then break end
                    local role = UnitGroupRolesAssigned(u)
                    local entry = partyRegistry[name]
                    local specID = GetInspectSpecialization(u)
                    if specID and specID > 0 then
                        if entry then
                            -- Already registered: upgrade/demote as needed
                            if SPEC_NO_INTERRUPT[specID] then
                                -- Confirmed healer spec → remove bar + registry entry
                                local guid = entry.guid
                                if guid then
                                    for key, info in pairs(activeBars) do
                                        if info.guid == guid then
                                            info.frame:Hide()
                                            activeBars[key] = nil
                                        end
                                    end
                                    UpdateLayout()
                                end
                                partyRegistry[name] = nil
                                noKickPlayers[name] = true
                            else
                                local ov = SPEC_INTERRUPTS[specID]
                                if ov and ov ~= entry.spellID then
                                    entry.spellID = ov
                                    entry.baseCd  = INTERRUPTS[ov] or 15
                                end
                            end
                        elseif not noKickPlayers[name] and CLASS_INTERRUPTS[cls] then
                            -- Not yet registered (was deferred because HEALER_CAPABLE_CLASS + spec unknown).
                            -- Now we have spec data — register if appropriate.
                            if SPEC_NO_INTERRUPT[specID] then
                                noKickPlayers[name] = true
                            elseif role ~= "HEALER" or HEALER_KEEPS_KICK[cls] then
                                local guid = UnitGUID(u)
                                local sid  = SPEC_INTERRUPTS[specID] or CLASS_INTERRUPTS[cls]
                                partyRegistry[name] = {
                                    class   = cls,
                                    spellID = sid,
                                    baseCd  = INTERRUPTS[sid] or 15,
                                    cdEnd   = 0,
                                    guid    = guid,
                                    unit    = u,
                                }
                            end
                        end
                    end
                end
            end
        end)
    end
end

-- ============================================================================
-- SIGNAL CORRELATION
-- ============================================================================
local function CorrelateSignals()
    local now = GetTime()
    if not needsCorrelation then return end
    if now - lastCorrelateAt < CORRELATE_INTERVAL then return end
    lastCorrelateAt = now
    PruneSignalTape(now)

    local casts, interrupts, auras = {}, {}, {}
    for i = 1, #signalTape do
        local s = signalTape[i]
        if s and not s.consumed then
            if     s.kind == "cast"      then casts[#casts+1]           = s
            elseif s.kind == "interrupt" then interrupts[#interrupts+1] = s
            elseif s.kind == "aura"      then auras[#auras+1]           = s
            end
        end
    end

    if #interrupts == 0 or #casts == 0 then needsCorrelation = false; return end

    table.sort(interrupts, function(a, b) return a.at < b.at end)
    local fresh = interrupts[#interrupts]

    -- Aura suppress: buff change on same mob within 28ms → not a real interrupt
    for i = 1, #auras do
        if auras[i].unit == fresh.unit and math.abs(fresh.at - auras[i].at) <= AURA_SUPPRESS then
            fresh.consumed = true; needsCorrelation = false; return
        end
    end

    -- Cluster suppress: multiple interrupts at once → AoE stun, not a kick
    local cluster = 0
    for i = 1, #interrupts do
        if math.abs(interrupts[i].at - fresh.at) <= 0.018 then cluster = cluster + 1 end
    end
    if cluster > 1 then
        for i = 1, #interrupts do interrupts[i].consumed = true end
        needsCorrelation = false; return
    end

    fresh.consumed = true
    local best, bestDiff = nil, math.huge
    for i = 1, #casts do
        local diff = math.abs(fresh.at - casts[i].at)
        if diff <= MATCH_WINDOW and diff < bestDiff then bestDiff = diff; best = casts[i] end
    end

    if best then
        best.consumed = true
        if best.unit ~= "player" then
            local memberName = UnitName(best.unit)
            if memberName then
                local rc = recentCasts[memberName]
                if rc and rc.spellID then HandlePartyCast(memberName, rc.spellID) end
            end
        end
    end
    needsCorrelation = false
end

-- ============================================================================
-- OWN PLAYER KICK (player spellID is always untainted)
-- ============================================================================
local _addonMsgBlocked = false
InterruptTracker._pendingOwnKickAt = nil

local function OwnKick(spellID)
    if not IsTrackerAllowed() then return end
    spellID = SPELL_ALIASES[spellID] or spellID
    if not INTERRUPTS[spellID] then return end
    local guid = UnitGUID("player")
    local name = UnitName("player")
    local _, class = UnitClass("player")
    InterruptTracker._pendingOwnKickAt = GetTime()
    StartCooldown(guid, name, class, spellID)
    -- Broadcast to other GravityUI users (secondary confirmation channel)
    if not _addonMsgBlocked then
        local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
        local ok, ret = pcall(C_ChatInfo.SendAddonMessage, "GRV_INT", tostring(spellID), channel)
        if ok and ret == 11 then _addonMsgBlocked = true end
    end
end

local _playerFrame = CreateFrame("Frame")
_playerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")
_playerFrame:SetScript("OnEvent", function(_, _, unit, _, spellID)
    if unit == "pet" then
        -- Pet spellID is tainted in 12.0 – launder via slider
        onSliderChangedResult = nil
        launderSlider:SetValue(0)
        pcall(launderSlider.SetValue, launderSlider, spellID)
        local clean = onSliderChangedResult
        if clean then OwnKick(clean) end
        return
    end
    -- Player: untainted – fast path
    OwnKick(spellID)
    PushSignal("cast", "player")
end)

-- ============================================================================
-- UNIFIED EVENT FRAME (12.0.5 Signal-Tape)
-- Handles party casts, mob interrupts, nameplate auras on ONE frame.
-- NOTE: UNIT_SPELLCAST_SUCCEEDED for party no longer fires in 12.0.5.
--       Party attribution uses UNIT_SPELLCAST_INTERRUPTED + mob heuristic.
-- ============================================================================
local _interruptFrame = CreateFrame("Frame")
_interruptFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
_interruptFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
_interruptFrame:RegisterEvent("UNIT_AURA")
_interruptFrame:SetScript("OnEvent", function(_, event, unit, ...)
    local s = GetSettings()
    if not s or not s.enabled or not IsTrackerAllowed() then return end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not unit or unit == "player" or unit == "pet" then return end
        if not unit:find("^party") then return end

        -- Resolve partypet → owner party unit (partypet4 → party4)
        local resolveUnit = unit
        if unit:find("^partypet") then
            local idx = unit:match("partypet(%d)")
            if not idx then return end
            resolveUnit = "party" .. idx
        end

        -- UnitName may return a tainted string in 12.0.5.
        -- Probe it by trying to use it as a table key inside pcall.
        local memberName
        do
            local ok, n = pcall(UnitName, resolveUnit)
            if not ok or not n then return end
            local keyOk = pcall(function() local _ = partyRegistry[n] end)
            if not keyOk then return end  -- tainted name, skip entirely
            memberName = n
        end

        local _, spellID = ...
        -- Use centralized resolver (BliZzi parity: name-path → GetBaseSpell → ID → alias → slider)
        local cleanID = ResolveInterruptSpell(spellID)

        if cleanID then
            recentCasts[memberName] = { t = GetTime(), spellID = cleanID }
            PushSignal("cast", resolveUnit)
        elseif not (pcall(C_Spell.GetSpellName, spellID) and not issecretvalue(select(2, pcall(C_Spell.GetSpellName, spellID)))) then
            -- Name lookup failed entirely (tainted spellID AND GetSpellName failed).
            -- Fall back to the registered interrupt for this player — ONLY if NOT on CD.
            -- (BliZzi parity: prevents resetting CD when e.g. Tail Swipe fires while kick is recharging)
            local ok, entry = pcall(function() return partyRegistry[memberName] end)
            if ok and entry and entry.spellID and entry.spellID > 0 then
                local isOnCD = entry.cdEnd and entry.cdEnd > GetTime()
                if not isOnCD then
                    recentCasts[memberName] = { t = GetTime(), spellID = entry.spellID }
                    PushSignal("cast", resolveUnit)
                end
            end
        end


    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        if not unit or not unit:find("^nameplate") then return end
        PushSignal("interrupt", unit)
        -- 12.0.5 Mob-Attribution: since UNIT_SPELLCAST_SUCCEEDED is gone for party,
        -- we attribute inline when we see the mob interrupted.
        local now = GetTime()

        -- If the local player just kicked within 0.5s, this mob interrupt belongs
        -- to us — OwnKick() already called StartCooldown(). Skip party attribution
        -- entirely to prevent falsely triggering another player's bar.
        -- NOTE: we intentionally do NOT check UnitIsUnit("playertarget", unit) here
        -- because macros / tab-target can leave the target frame on a different unit
        -- than the nameplate that received the kick event.
        if InterruptTracker._pendingOwnKickAt and (now - InterruptTracker._pendingOwnKickAt) < 0.5 then
            InterruptTracker._pendingOwnKickAt = nil  -- consume so rapid-fire doesn't suppress next party kick
            return
        end

        local mobX, mobY, _, mobMap = UnitPosition(unit)
        local MAX_RANGE = 35
        local function dist(pu)
            if not mobX or not mobMap then return nil end
            local px, py, _, pm = UnitPosition(pu)
            if not px or pm ~= mobMap then return nil end
            return math.sqrt((mobX - px)^2 + (mobY - py)^2)
        end
        local targeting, inRange, all = {}, {}, {}
        for i = 1, 4 do
            local pu = "party" .. i
            if UnitExists(pu) then
                -- UnitName may return tainted string in 12.0.5 – probe before indexing
                local nm
                do
                    local ok, n = pcall(UnitName, pu)
                    if ok and n then
                        local keyOk = pcall(function() local _ = partyRegistry[n] end)
                        if keyOk then nm = n end
                    end
                end
                local entry = nm and partyRegistry[nm]
                if entry and entry.spellID and (not entry.cdEnd or entry.cdEnd < now) then
                    local d = dist(pu)
                    local c = { name = nm, unit = pu, spellID = entry.spellID, dist = d }
                    all[#all + 1] = c
                    if UnitIsUnit(pu .. "target", unit) then targeting[#targeting + 1] = c end
                    if not d or d <= MAX_RANGE       then inRange[#inRange + 1]   = c end
                end
            end
        end
        local function closest(set)
            if #set == 0 then return nil end
            local best, bd, fb = nil, math.huge, nil
            for _, c in ipairs(set) do
                if c.dist then
                    if c.dist < bd then best, bd = c, c.dist end
                elseif not fb then fb = c end
            end
            return best or fb
        end
        local winner
        if     #targeting == 1 then winner = targeting[1]
        elseif #targeting  > 1 then winner = closest(targeting)
        elseif #inRange   == 1 then winner = inRange[1]
        elseif #inRange    > 1 then winner = closest(inRange)
        elseif #all       == 1 then winner = all[1]
        end
        if winner then
            recentCasts[winner.name] = { t = now, spellID = winner.spellID }
            HandlePartyCast(winner.name, winner.spellID)
        end

    elseif event == "UNIT_AURA" then
        -- PERF: sub(1,9) avoids pattern-engine overhead for every UNIT_AURA dispatch.
        -- In a 40-man raid this fires 40+ times/sec for players, pets, npcs etc.
        if unit and unit:sub(1, 9) == "nameplate" then PushSignal("aura", unit) end
    end
end)

_interruptFrame:SetScript("OnUpdate", function()
    if needsCorrelation then
        local s = GetSettings()
        if s and s.enabled and IsTrackerAllowed() then
            CorrelateSignals()
        else
            needsCorrelation = false
            wipe(signalTape)
        end
    end
end)

-- ============================================================================
-- GRV_INT ADDON MESSAGE HANDLER (secondary confirmation from other GravityUI users)
-- ============================================================================
function InterruptTracker:CHAT_MSG_ADDON(event, prefix, text, channel, sender)
    if prefix ~= "GRV_INT" then return end
    if not IsTrackerAllowed() then return end
    local name = Ambiguate(sender, "none")
    if UnitIsUnit(name, "player") then return end
    local spellId = tonumber(text)
    if not spellId or not INTERRUPTS[spellId] then return end
    local guid = UnitGUID(name)
    if not guid then return end
    local _, class = UnitClass(name)
    StartCooldown(guid, name, class, spellId)
end

-- No-op: old UNIT_SPELLCAST_SUCCEEDED method (now handled by _playerFrame/_interruptFrame)
function InterruptTracker:UNIT_SPELLCAST_SUCCEEDED() end







function InterruptTracker.TestMode()
    if testModeActive then
        for _, f in ipairs(framePool) do f:Hide() end
        activeBars = {}
        testModeActive = false
    else
        testModeActive = true
        StartCooldown(UnitGUID("player"), "Test Player", "WARRIOR", 6552) -- Pummel
        StartCooldown(UnitGUID("player"), "Test Mage", "MAGE", 2139) -- Counterspell
        StartCooldown(UnitGUID("player"), "Test Shaman", "SHAMAN", 57994) -- Wind Shear
    end
end

-- ============================================================================
-- TEST COMMANDS
-- ============================================================================
-- 1. Test Mode (Dummy Bars)
if ns.Addon then
    ns.Addon:RegisterChatCommand("gravitytest", function() 
        InterruptTracker.TestMode() 
        print("GravityUI: Test Mode Toggled")
    end)
    
    -- 2. Simulate Incoming Generic Interrupt (for Macro Testing)
    ns.Addon:RegisterChatCommand("gravitysim", function(msg)
        local spellId = tonumber(msg) or 47528 -- Default to Mind Freeze
        local s = GetSettings()
        if not s.enabled then 
            print("GravityUI: Simulation FAILED - Interrupt Tracker is DISABLED in settings.")
            return 
        end
        print("GravityUI: Simulating Interrupt from 'TestPlayer': " .. spellId)
        -- Simulate direct call to StartCooldown (bypassing GUID lookup failure)
        StartCooldown("FakeGUID-123456", "TestPlayer", "DEATHKNIGHT", spellId)
    end)
end

-- ============================================================================
-- DYNAMIC COOLDOWNS (INSPECT)
-- ============================================================================

local function ProcessInspect(guid)
    if not guid then return end
    
    -- Clear previous reductions for this GUID
    activeReductions[guid] = {}
    
    -- C_Traits scanning
    local configID = -1 -- Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID
    local ok, configInfo = pcall(C_Traits.GetConfigInfo, configID)
    if not ok or not configInfo or not configInfo.treeIDs or #configInfo.treeIDs == 0 then return end

    local treeID = configInfo.treeIDs[1]
    local ok2, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
    if not ok2 or not nodeIDs then return end

    for _, nodeID in ipairs(nodeIDs) do
        local ok3, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID)
        if ok3 and nodeInfo and nodeInfo.activeEntry and nodeInfo.activeRank and nodeInfo.activeRank > 0 then
            local entryID = nodeInfo.activeEntry.entryID
            if entryID then
                local ok4, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
                if ok4 and entryInfo and entryInfo.definitionID then
                    local ok5, defInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
                    if ok5 and defInfo and defInfo.spellID then
                        local talent = CD_REDUCTION_TALENTS[defInfo.spellID]
                        if talent and talent.affects then
                            if talent.reduction then
                                activeReductions[guid][talent.affects] = (activeReductions[guid][talent.affects] or 0) + talent.reduction
                            elseif talent.pctReduction then
                                activeReductions[guid]["PCT_" .. talent.affects] = (activeReductions[guid]["PCT_" .. talent.affects] or 0) + talent.pctReduction
                            end
                        end
                        
                        local onKick = CD_ON_KICK_TALENTS[defInfo.spellID]
                        if onKick then
                            activeReductions[guid].onKick = (activeReductions[guid].onKick or 0) + onKick.reduction
                        end

                        local extraKick = EXTRA_KICK_TALENTS[defInfo.spellID]
                        if extraKick then
                            if not activeReductions[guid].extraKicks then
                                activeReductions[guid].extraKicks = {}
                            end
                            table.insert(activeReductions[guid].extraKicks, extraKick)
                        end
                    end
                end
            end
        end
    end
end

local function OnInspectReady(guid)
    ProcessInspect(guid)
    
    -- Check Spec Interrupt
    local unit = nil
    
    -- Safe Comparison Helper
    local function SafeEq(a, b)
        local ok, res = pcall(function() return a == b end)
        return ok and res
    end

    if SafeEq(UnitGUID("player"), guid) then unit = "player"
    elseif SafeEq(UnitGUID("target"), guid) then unit = "target"
    elseif SafeEq(UnitGUID("focus"), guid) then unit = "focus"
    else
        if IsInGroup() then
             local prefix = IsInRaid() and "raid" or "party"
             for i=1, GetNumGroupMembers() do
                 local u = prefix..i
                 if SafeEq(UnitGUID(u), guid) then unit = u break end
             end
        end
    end
    
    if unit then
        local specID = GetInspectSpecialization(unit)
        if specID and specID > 0 then
            activeSpecs[guid] = specID
            
            -- If this is a confirmed healer spec with no interrupt, remove any existing bar immediately
            if SPEC_NO_INTERRUPT[specID] then
                local _, cls = UnitClass(unit)
                local name = UnitName(unit)
                if name then noKickPlayers[name] = true end
                if partyRegistry and name then partyRegistry[name] = nil end
                for key, info in pairs(activeBars) do
                    if info.guid == guid then
                        info.frame:Hide()
                        activeBars[key] = nil
                    end
                end
                UpdateLayout()
                return  -- No further processing needed for this unit
            end
            
            local specInterrupt = SPEC_INTERRUPTS[specID]
            if specInterrupt then
                -- Find existing bar for this GUID that uses the wrong (default class) spellId
                for key, info in pairs(activeBars) do
                    if info.guid == guid and info.spellId ~= specInterrupt then
                        -- Re-key the bar so future UNIT_SPELLCAST_SUCCEEDED events find it correctly
                        activeBars[key] = nil
                        local newKey = guid .. specInterrupt
                        -- If a bar already exists for the spec interrupt, hide the old frame
                        if activeBars[newKey] then
                            info.frame:Hide()
                        else
                            info.spellId = specInterrupt
                            -- Update Icon
                            local icon = C_Spell.GetSpellTexture(specInterrupt)
                            if icon and info.frame then
                                info.frame.icon:SetTexture(icon)
                            end

                            -- Reset to Ready (Switching specs resets CDs usually)
                            info.duration = 0
                            info.expiration = 0

                            local s = GetSettings()
                            if s and s.showReadyText then
                                info.frame.time:SetText("Ready")
                            else
                                info.frame.time:SetText("")
                            end

                            info.frame.bar:SetValue(1)
                            local cr, cg, cb, ca = 1, 1, 1, 1
                            if s and s.useSpecificCooldownColor then
                               local c = s.cooldownTextColor or {1, 1, 1, 1}
                               cr, cg, cb, ca = c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
                            end
                            info.frame.time:SetTextColor(cr, cg, cb, ca)
                            activeBars[newKey] = info
                        end
                        break -- Only one default bar per GUID to replace
                    end
                end
            end
            
            -- Handle Spec extra kicks (e.g Warlock Axe Toss)
            if SPEC_EXTRA_KICKS[specID] then
                if not activeReductions[guid] then activeReductions[guid] = {} end
                if not activeReductions[guid].extraKicks then activeReductions[guid].extraKicks = {} end
                
                for _, extraKick in ipairs(SPEC_EXTRA_KICKS[specID]) do
                    local alreadyExists = false
                    for _, ek in ipairs(activeReductions[guid].extraKicks) do
                        if ek.id == extraKick.id then alreadyExists = true break end
                    end
                    if not alreadyExists then
                        table.insert(activeReductions[guid].extraKicks, extraKick)
                    end
                end
            end
            
            -- If we have extra kicks, start tracking them 
            if activeReductions[guid] and activeReductions[guid].extraKicks then
                local _, class = UnitClass(unit)
                local name = UnitName(unit)
                for _, extra in ipairs(activeReductions[guid].extraKicks) do
                    local extraSpellID = extra.id
                    local extraCD = extra.cd
                    if not INTERRUPTS[extraSpellID] then
                        INTERRUPTS[extraSpellID] = extraCD -- Add to master table if missing
                    end
                    
                    if not activeBars[guid .. extraSpellID] then
                        -- Initialize it as ready
                        StartCooldown(guid, name, class, extraSpellID)
                        local info = activeBars[guid .. extraSpellID]
                        if info then
                            info.expiration = 0 -- Ready immediately
                            if not testModeActive then updateFrame:Show() end
                        end
                    end
                end
            end
        end
    end
end

local lastInspectTime = 0
local inspectQueue = {}

local function TryInspect()
    if InCombatLockdown() then return end
    if #inspectQueue == 0 then return end
    
    -- Safety: Do not hijack the global inspect buffer if the user is manually inspecting someone
    if InspectFrame and InspectFrame:IsShown() then
        C_Timer.After(2, TryInspect)
        return
    end
    
    local now = GetTime()
    if now - lastInspectTime < 2 then return end -- Throttle 2s
    
    local unit = table.remove(inspectQueue, 1)
    if UnitExists(unit) then
        -- NotifyInspect triggers INSPECT_READY
        -- We need to check if we can inspect
        if CanInspect(unit) then
             NotifyInspect(unit)
             lastInspectTime = now
        end
    end
    
    if #inspectQueue > 0 then
        C_Timer.After(2, TryInspect)
    end
end

local function QueueInspect(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    table.insert(inspectQueue, unit)
    C_Timer.After(0.5, TryInspect)
end

local function OnGroupRosterUpdate()
    inspectQueue = {} -- Reset queue
    
    local inGroup = IsInGroup()
    local _, instanceType = IsInInstance()
    
    -- VISIBILITY RULES:
    -- 1. Raid: Hide (Too much clutter)
    -- 2. Solo: Hide (User request)
    -- Exception: Test Mode
    if (not inGroup or instanceType == "raid" or IsInRaid()) and not testModeActive then
         for _, info in pairs(activeBars) do info.frame:Hide() end
         activeBars = {}
         UpdateLayout() -- Ensure it clears
         return
    end
    
    -- Register Watchers for Party Members
    RegisterPartyWatchers()

    -- Build partyRegistry for new members
    AutoRegisterPartyByClass()

    local members = {}
    
    local function HandleMember(unit)
        if not UnitExists(unit) then return end
        
        local ok, guid = pcall(UnitGUID, unit)
        if not ok or not guid then return end
        
        members[guid] = true
        
        -- Queue Inspect (Dynamic CD)
        if not UnitIsUnit(unit, "player") then
            QueueInspect(unit)
        end
        
        -- Create/Update Bar (Persistent)
        local _, class = UnitClass(unit)
        local role = UnitGroupRolesAssigned(unit)
        
        -- Skip healers that aren't shamans (they usually don't have interrupts by default)
        -- Filter 1: Explicit LFG healer role
        if role == "HEALER" and not HEALER_KEEPS_KICK[class] then return end
        
        -- Filter 2: Spec-based check (catches healers with role "NONE", e.g. manually formed groups)
        local specID = activeSpecs[guid] or (GetInspectSpecialization and UnitExists(unit) and GetInspectSpecialization(unit))
        if specID and specID > 0 then
            if SPEC_NO_INTERRUPT[specID] then return end
        else
            -- Spec not yet known: if class CAN be a healer, skip until spec is confirmed
            if HEALER_CAPABLE_CLASS[class] then return end
        end
        
        -- Priority: Spec-specific interrupt > Class interrupt
        local interruptID = CLASS_INTERRUPTS[class]
        if activeSpecs[guid] and SPEC_INTERRUPTS[activeSpecs[guid]] then
            interruptID = SPEC_INTERRUPTS[activeSpecs[guid]]
        end
        
        if interruptID then
            -- Check if bar exists
            local found = false
            for key, info in pairs(activeBars) do
                if info.guid == guid and info.spellId == interruptID then
                    found = true
                    break
                end
            end
            
            if not found then
                 local name = UnitName(unit)
                 StartCooldown(guid, name, class, interruptID, true) -- Force Ready State
            end
        end
    end

    if IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        local max = GetNumGroupMembers()
        for i = 1, max do
             HandleMember(prefix .. i)
        end
    end
    HandleMember("player")
    
    -- Clean up removed members (activeBars + partyRegistry)
    for key, info in pairs(activeBars) do
        if not members[info.guid] and not testModeActive then
             info.frame:Hide()
             activeBars[key] = nil
        end
    end
    for name in pairs(partyRegistry) do
        local found = false
        for i = 1, 4 do
            if UnitExists("party"..i) and UnitName("party"..i) == name then found = true; break end
        end
        if not found then partyRegistry[name] = nil end
    end
    
    UpdateLayout()

    -- BliZzi parity: staggered retries so inspect data and UnitExists stabilise
    C_Timer.After(1, function()
        if not testModeActive then
            RegisterPartyWatchers()
            AutoRegisterPartyByClass()
        end
    end)
    C_Timer.After(3, function()
        if not testModeActive then
            RegisterPartyWatchers()
            AutoRegisterPartyByClass()
        end
    end)
end

-- ============================================================================
-- SPEC / ROLE CHANGE HANDLERS (BliZzi parity)
-- ============================================================================
local function OnSpecializationChanged(unit)
    if not unit or unit == "player" then return end
    local ok, name = pcall(UnitName, unit)
    if not ok or not name then return end
    local specID = GetInspectSpecialization(unit)
    if not (specID and specID > 0) then
        C_Timer.After(1, function() OnSpecializationChanged(unit) end)
        return
    end
    if SPEC_NO_INTERRUPT[specID] then
        partyRegistry[name] = nil
        noKickPlayers[name] = true
        return
    end
    noKickPlayers[name] = nil
    local _, cls = UnitClass(unit)
    local entry = partyRegistry[name]
    if not entry then
        entry = { class = cls, cdEnd = 0, guid = UnitGUID(unit), unit = unit }
        partyRegistry[name] = entry
    end
    local ov = SPEC_INTERRUPTS[specID]
    if ov then
        entry.spellID = ov
        entry.baseCd  = INTERRUPTS[ov] or 15
        entry.cdEnd   = 0
    end
end

-- ============================================================================
-- INITIALIZATION & MOVER

-- ============================================================================

local moverDummiesActive = false

function InterruptTracker.ToggleMover(force)
    if not container then return end
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    local show = false
    if force ~= nil then
        show = force
    else
        show = not container.mover:IsShown()
    end
    
    if show then
        container.mover:Show()
        
        -- Style based on mode
        local r, g, b, a, br, bg, bb, ba
        if force then
            -- Edit Mode: Blue Overlay
            r, g, b, a = 0, 0.6, 1, 0.5
            br, bg, bb, ba = 0, 0.8, 1, 1
        else
            -- Manual Toggle: Green Highlight
            r, g, b, a = 0, 1, 0, 0.3
            br, bg, bb, ba = 0, 1, 0, 1
        end

        container.mover:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        container.mover:SetBackdropColor(r, g, b, a)
        container.mover:SetBackdropBorderColor(br, bg, bb, ba)
        
        -- Add dummy bars for visual if empty
        if not next(activeBars) then
             StartCooldown(UnitGUID("player"), "Test Player", "WARRIOR", 6552) -- Pummel
             StartCooldown(UnitGUID("player"), "Test Mage", "MAGE", 2139) -- Counterspell
             moverDummiesActive = true
        end
    else
        container.mover:Hide()
        container.mover:SetBackdrop(nil)
        
        -- Clear dummies ONLY if we created them
        if moverDummiesActive then
            activeBars = {}
            for _, f in ipairs(framePool) do f:Hide() end
            moverDummiesActive = false
            -- Trigger immediate roster update to restore real bars if any (though unlikely if we were empty)
            OnGroupRosterUpdate()
        end
    end
end

function InterruptTracker.Initialize()
    if container then return end
    -- Create Container
    container = CreateFrame("Frame", "GravityUI_InterruptTracker", UIParent, "BackdropTemplate")
    local s = GetSettings()
    if not s then return end
    -- PERF: Populate the OnUpdate cache with the initial settings on first load.
    InvalidateOnUpdateCache()
    
    container:SetSize(220, 100) -- dynamic height usually
    container:SetPoint("CENTER", UIParent, "CENTER", s.x or 0, s.y or 0)
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    
    -- Init Backdrop
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    
    -- Apply Background Color (Container is transparent)
    container:SetBackdropColor(0, 0, 0, 0)
    container:SetBackdropBorderColor(0, 0, 0, 0)
    
    -- Mover Overlay
    local mover = CreateFrame("Frame", nil, container, "BackdropTemplate")
    mover:SetAllPoints()
    mover:SetFrameStrata("DIALOG") -- Ensure above bars
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:Hide()
    
    -- Visuals for Mover
    local txt = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("CENTER")
    txt:SetText("Interrupt Tracker")
    
    mover:SetScript("OnDragStart", function() container:StartMoving() end)
    mover:SetScript("OnDragStop", function() 
        container:StopMovingOrSizing()
        -- Save Pos
        local x, y = container:GetCenter()
        local ux, uy = UIParent:GetCenter()
        s.x = x - ux
        s.y = y - uy
    end)
    container.mover = mover
    
    -- Init Events via AceEvent
    if s.enabled then
        InterruptTracker:RegisterEvent("INSPECT_READY", function(_, guid) OnInspectReady(guid) end)
        InterruptTracker:RegisterEvent("GROUP_ROSTER_UPDATE", OnGroupRosterUpdate)
        InterruptTracker:RegisterEvent("PLAYER_ENTERING_WORLD", OnGroupRosterUpdate)
        InterruptTracker:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(_, unit) OnSpecializationChanged(unit) end)
        InterruptTracker:RegisterEvent("ROLE_CHANGED_INFORM", function()
            for i = 1, 4 do
                local u = "party" .. i
                if UnitExists(u) then
                    local name   = UnitName(u)
                    local _, cls = UnitClass(u)
                    local role   = UnitGroupRolesAssigned(u)
                    if name and role == "HEALER" and not HEALER_KEEPS_KICK[cls] then
                        partyRegistry[name] = nil
                        noKickPlayers[name] = true
                    end
                end
            end
        end)
        C_ChatInfo.RegisterAddonMessagePrefix("GRV_INT")
        InterruptTracker:RegisterEvent("CHAT_MSG_ADDON")
        container:Show()
        OnGroupRosterUpdate()
        updateFrame:Show()
    else
        InterruptTracker:UnregisterAllEvents()
        updateFrame:Hide()
        container:Hide()
    end
    
    -- Initial Pos
    container:ClearAllPoints()
    container:SetPoint("CENTER", UIParent, "CENTER", s.x or 0, s.y or 0)
    
    -- Register Mover
     if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("InterruptTracker", container, function(frame, enabled, force) 
            InterruptTracker.ToggleMover(force) 
        end, "Interrupt Tracker")
    end
end

function InterruptTracker.ApplySettings() 
     local s = GetSettings()
     if not container or not s then return end
     
    if s.enabled then
        InterruptTracker:RegisterEvent("INSPECT_READY", function(_, guid) OnInspectReady(guid) end)
        InterruptTracker:RegisterEvent("GROUP_ROSTER_UPDATE", OnGroupRosterUpdate)
        InterruptTracker:RegisterEvent("PLAYER_ENTERING_WORLD", OnGroupRosterUpdate)
        InterruptTracker:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(_, unit) OnSpecializationChanged(unit) end)
        InterruptTracker:RegisterEvent("ROLE_CHANGED_INFORM", function()
            for i = 1, 4 do
                local u = "party" .. i
                if UnitExists(u) then
                    local name   = UnitName(u)
                    local _, cls = UnitClass(u)
                    local role   = UnitGroupRolesAssigned(u)
                    if name and role == "HEALER" and not HEALER_KEEPS_KICK[cls] then
                        partyRegistry[name] = nil
                        noKickPlayers[name] = true
                    end
                end
            end
        end)
        C_ChatInfo.RegisterAddonMessagePrefix("GRV_INT")
        InterruptTracker:RegisterEvent("CHAT_MSG_ADDON")
        OnGroupRosterUpdate()
        updateFrame:Show()
        container:Show()
    else
        InterruptTracker:UnregisterAllEvents()
        updateFrame:Hide()
        container:Hide()
    end
     
     container:ClearAllPoints()
     container:SetPoint("CENTER", UIParent, "CENTER", s.x or 0, s.y or 0)
     
     -- Apply Background Color (Container is transparent)
    container:SetBackdropColor(0, 0, 0, 0)
     
     -- Refresh styles of active
     for key, info in pairs(activeBars) do
          StyleBar(info.frame, info.class)
     end
     
     -- PERF: Settings changed – force the OnUpdate cache to re-read on next tick.
     InvalidateOnUpdateCache()
     
     UpdateLayout()
end

-- ============================================================================
-- DEBUG COMMAND
-- ============================================================================
SLASH_GRAVITYDEBUGINTERRUPTS1 = "/gravitydebuginterrupts"
SlashCmdList["GRAVITYDEBUGINTERRUPTS"] = function()
    print("GravityUI Debug: Interrupt Tracker State")
    if not container then print("- Container: nil") return end
    print("- Container Shown:", container:IsShown())
    local count = 0
    for _ in pairs(activeBars) do count = count + 1 end
    print("- Active Bars:", count)
    for key, info in pairs(activeBars) do
        print("-", info.name, info.spellId, info.expiration, info.frame:IsShown())
    end
    print("- Mover Shown:", container.mover and container.mover:IsShown())
    local s = GetSettings()
    print("- Enabled:", s and s.enabled)
    print("- Group:", IsInGroup(), "Raid:", IsInRaid())
end
