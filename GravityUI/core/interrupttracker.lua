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
    { class = "DRUID", spellID = 78675, cd = 45, specID = 102 },            -- Solar Beam (Balance) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ 45s not 60s
    -- EVOKER
    { class = "EVOKER", spellID = 351338, cd = 18, isDefault = true, talents = { [412713] = { pctReduction = 0.1 } } }, -- Quell ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ 18s not 40s
    -- HUNTER
    { class = "HUNTER", spellID = 147362, cd = 24, isDefault = true, talents = { [388039] = { reduction = 2 } } }, -- Counter Shot
    { class = "HUNTER", spellID = 187707, cd = 15, specID = 255, talents = { [388039] = { reduction = 2 } } },     -- Muzzle (Survival)
    -- MAGE
    { class = "MAGE", spellID = 2139, cd = 20, isDefault = true },          -- Counterspell ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ 20s not 24s
    -- MONK
    { class = "MONK", spellID = 116705, cd = 15, isDefault = true },        -- Spear Hand Strike
    -- PALADIN
    { class = "PALADIN", spellID = 96231, cd = 15, isDefault = true },      -- Rebuke
    { class = "PALADIN", spellID = 420090, cd = 15 },                       -- NPC Rebuke (Follower Dungeon)
    -- PRIEST
    { class = "PRIEST", spellID = 15487, cd = 30, specID = 258, isDefault = true }, -- Silence (Shadow) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ 30s not 45s
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

local SPELL_ALIASES = {
    [1276467] = 132409, -- Fel Ravager summon -> Spell Lock extra bar
    [89766]   = 119914, -- Felguard Axe Toss (pet) -> Axe Toss (player)
    [119898]  = 19647,  -- Command Demon (Spell Lock) -> Spell Lock
    [171138]  = 19647,  -- Grimoire Felhunter (Spell Lock) -> Spell Lock
    [420090]  = 96231,  -- NPC Rebuke -> Rebuke
}
-- Specs that have NO interrupt at all (healer specs that can't kick)
local SPEC_NO_INTERRUPT = {
    [65]  = true,  -- Paladin: Holy
    [256] = true,  -- Priest: Discipline
    [257] = true,  -- Priest: Holy
    [270] = true,  -- Monk: Mistweaver
    [105] = true,  -- Druid: Restoration
    -- NOTE: Shaman Restoration (264) intentionally excluded Ã¢â‚¬â€ Resto Shaman keeps Wind Shear
}

-- Classes that keep their interrupt even as healer spec
local HEALER_KEEPS_KICK = {
    SHAMAN = true,  -- Restoration Shaman keeps Wind Shear
}

-- Classes that CAN have healer specs and must wait for spec confirmation before being registered.
local HEALER_CAPABLE_CLASS = {
    PALADIN = true,
    PRIEST = true,
    DRUID = true,
    MONK = true,
    SHAMAN = true,
    EVOKER = true,
}

local function BuildInterruptTables()
    for _, data in ipairs(INTERRUPT_CONFIG) do
        INTERRUPTS[data.spellID] = data.cd
        if data.isDefault then
            CLASS_INTERRUPTS[data.class] = data.spellID
        end
        if data.specID then
            SPEC_INTERRUPTS[data.specID] = data.spellID
        end
        if data.overrides then
            SPEC_COOLDOWN_OVERRIDES[data.spellID] = data.overrides
        end
    end

    for aliasID, targetID in pairs(SPELL_ALIASES) do
        if INTERRUPTS[targetID] then
            INTERRUPTS[aliasID] = INTERRUPTS[targetID]
        end
    end
end
BuildInterruptTables()

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
local sortedBars = {}

-- Object Pool (Zero-Allocation Architecture) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â only infoPool kept for bar recycling
local infoPool = {}

local function AcquireInfo(guid, name, class, spellId, duration, expiration, f)
    local info = table.remove(infoPool)
    if not info then info = {} end
    info.guid = guid
    info.name = name
    info.class = class
    info.spellId = spellId
    info.baseDuration = duration
    info.expiration = expiration
    info.duration = duration
    info.frame = f
    info.lastRem10 = nil
    return info
end

local function ReleaseInfo(info)
    if info then
        wipe(info)
        infoPool[#infoPool + 1] = info
    end
end

local function ClearActiveBar(key)
    local info = activeBars[key]
    if info then
        if info.frame then info.frame:Hide() end
        ReleaseInfo(info)
        activeBars[key] = nil
    end
end

local function ClearAllActiveBars()
    for key, info in pairs(activeBars) do
        if info.frame then info.frame:Hide() end
        ReleaseInfo(info)
        activeBars[key] = nil
    end
end

-- ============================================================================
-- DYNAMIC COOLDOWN DATA
-- ============================================================================

local activeSpecs = {}
local container = nil
local testModeActive = false

-- Party Registry: tracks known interrupt spell per party member
local partyRegistry = {}  -- [name] = { class, spellID, baseCd, cdEnd, guid, unit }

-- ============================================================================
-- NAMEPLATE INTERRUPT DETECTION (MiniAura-proven pattern, 12.x compatible)
-- ============================================================================
-- Instead of trying to read tainted party spellIDs from UNIT_SPELLCAST_SUCCEEDED,
-- we detect interrupts via UNIT_SPELLCAST_INTERRUPTED on nameplate units and
-- identify the kicker via UnitNameFromGUID(interruptedBy).

local NAMEPLATE_PREFIX = "^nameplate"
local REPEAT_WINDOW = 0.5   -- Dedup: same mob within 0.5s (engine fires per-token)
local OWN_CAST_WINDOW = 0.5 -- Match own kick to mob interrupt within 0.5s
local lastRecordedAt = {}    -- [unitToken] = timestamp

-- Decodes the interrupter from stop-event payloads (MiniAura KickEvents pattern).
-- Returns: interruptedBy (GUID, may be secret), interruptedSpellId (may be secret)
-- Returns nil, nil if the cast merely ended (not interrupted).
local function GetInterrupter(event, ...)
    if event == "UNIT_SPELLCAST_INTERRUPTED" then
        -- Args after unit: castGUID, spellID, interruptedBy
        local _, spellId, interruptedBy = ...
        return interruptedBy, spellId
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        -- Args after unit: castGUID, spellID, interruptedBy
        local _, spellId, interruptedBy = ...
        return interruptedBy, spellId
    elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        -- Args after unit: castGUID, spellID, closedByInterrupt, interruptedBy
        local _, spellId, _, interruptedBy = ...
        return interruptedBy, spellId
    end
    return nil, nil
end

-- Infer which ally kicked when the name is secret.
-- If only 1 party member has an interrupt off-CD, it must be them.
local allyKickBuiltAt = -math.huge
local ALLY_KICK_TTL = 30
local cachedAllyName, cachedAllySpellID

local function InferAllyKick()
    local now = GetTime()
    if now - allyKickBuiltAt < ALLY_KICK_TTL then
        return cachedAllyName, cachedAllySpellID
    end
    allyKickBuiltAt = now
    cachedAllyName, cachedAllySpellID = nil, nil

    local onlyName, onlySpellID, candidateCount = nil, nil, 0
    for name, entry in pairs(partyRegistry) do
        if not entry.cdEnd or entry.cdEnd < now then  -- off CD
            candidateCount = candidateCount + 1
            onlyName, onlySpellID = name, entry.spellID
        end
    end

    if candidateCount == 1 then
        cachedAllyName, cachedAllySpellID = onlyName, onlySpellID
    end
    return cachedAllyName, cachedAllySpellID
end

-- Invalidate the inference cache (called on roster/spec changes)
local function InvalidateAllyKickCache()
    allyKickBuiltAt = -math.huge
end

-- Real cooldown from the game engine (accounts for talents, Haste, resets)
local MIN_REPORTED_COOLDOWN = 2  -- anything shorter is GCD
local function PlayerSpellCooldown(spellId)
    local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellId)
    if not info or not info.duration then return nil, nil end
    if issecretvalue and (issecretvalue(info.duration) or issecretvalue(info.startTime)) then
        return nil, nil
    end
    if info.duration < MIN_REPORTED_COOLDOWN then return nil, nil end
    return info.startTime, info.duration
end

-- Back-compat stub (called from OnGroupRosterUpdate / Initialize)
local function RegisterPartyWatchers() end


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

local function GetSafeClassColor(class)
    if not class then return nil end
    if C_ClassColor and C_ClassColor.GetClassColor then
        local ok, col = pcall(C_ClassColor.GetClassColor, class)
        if ok and col and col.r then return col end
    end
    if issecretvalue and issecretvalue(class) then return nil end
    if type(class) == "string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        return RAID_CLASS_COLORS[class]
    end
    return nil
end

local function StyleBar(f, class)
    local s = GetSettings()
    if not s then return end
    
    local width = s.width or 200
    local height = s.height or 20
    
    f:SetSize(width, height)
    f.bar:SetSize(width, height)
    
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
    
    -- Layout: Icon & Text Anchors
    f.icon:ClearAllPoints()
    f.icon:SetSize(height, height)
    f.icon:SetPoint("RIGHT", f.bar, "LEFT", 0, 0)
    if s.showIcon ~= false then
        f.icon:Show()
    else
        f.icon:Hide()
    end
    
    f.name:ClearAllPoints()
    f.name:SetPoint("LEFT", f.bar, "LEFT", 4, 0)
    f.name:SetPoint("RIGHT", f.time, "LEFT", -4, 0)
    f.name:Show()
    
    f.time:ClearAllPoints()
    f.time:SetPoint("RIGHT", f.bar, "RIGHT", -4, 0)
    f.time:Show()
    
    local classCol = GetSafeClassColor(class)

    -- Colors: Background (Bar BG)
    local bgr, bgg, bgb, bga = 0, 0, 0, 0.5
    if s.useClassColorBackdrop and classCol then
        bgr, bgg, bgb, bga = classCol.r, classCol.g, classCol.b, 0.5
    elseif s.useThemeBackdropColor and ns.GetThemeBgColor then
         bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    elseif s.backdropColor then
         local c = s.backdropColor
         bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4]
    end
    f.bg:SetVertexColor(bgr, bgg, bgb, bga)
    
    -- Colors: Bar
    local r, g, b, a = 1, 1, 1, 1
    if s.useClassColor and classCol then
        r, g, b, a = classCol.r, classCol.g, classCol.b, 1
    elseif s.useThemeBarColor and ns.GetAccentColor then
        r, g, b, a = ns.GetAccentColor()
    else
        local c = s.barColor
        if c then r, g, b, a = c[1], c[2], c[3], c[4] end
    end
    f.bar:SetStatusBarColor(r, g, b, a)
    
    -- Colors: Text (Name)
    local tr, tg, tb, ta = 1, 1, 1, 1
    if s.useClassColorText and classCol then
        tr, tg, tb, ta = classCol.r, classCol.g, classCol.b, 1
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

local function ClearActiveBar(key)
    local info = activeBars[key]
    if info then
        if info.frame then
            info.frame:Hide()
        end
        ReleaseInfo(info)
        activeBars[key] = nil
    end
end

local function ClearAllActiveBars()
    for key in pairs(activeBars) do
        ClearActiveBar(key)
    end
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
        
        -- Tie-breaker: safe name/pointer comparison
        local aNameOk, aName = pcall(tostring, a.name)
        local bNameOk, bName = pcall(tostring, b.name)
        if aNameOk and bNameOk and not (issecretvalue and (issecretvalue(aName) or issecretvalue(bName))) then
            local cmpOk, res = pcall(function() return aName < bName end)
            if cmpOk then return res end
        end
        return tostring(a) < tostring(b)
    end)
    
    local barCount = #sortedBars
    local totalW = (s.width or 200) + height
    for i, info in ipairs(sortedBars) do
        local f = info.frame
        f:ClearAllPoints()
        if s.growDirection == "UP" then
            f:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", height, yOffset)
        else
            f:SetPoint("TOPLEFT", container, "TOPLEFT", height, -yOffset)
        end
        f:Show()
        yOffset = yOffset + height + spacing
    end

    local totalH = barCount > 0 and (yOffset - spacing) or height
    container:SetSize(totalW, totalH)
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

-- ===============================================================
local function StartCooldown(guid, name, class, spellId, isReady, isTest)
    local s = GetSettings()
    if not s or not s.enabled then return end
    if not isTest and not IsTrackerAllowed() then return end
    
    local baseCD = (spellId and INTERRUPTS[spellId]) or 15
    
    -- Apply Spec-Specific Cooldown Override (guarded against secret GUID)
    local spec = nil
    if guid and not (issecretvalue and issecretvalue(guid)) then
        spec = activeSpecs[guid]
    end
    if spec and spellId and SPEC_COOLDOWN_OVERRIDES[spellId] and SPEC_COOLDOWN_OVERRIDES[spellId][spec] then
        baseCD = SPEC_COOLDOWN_OVERRIDES[spellId][spec]
    end

    -- Clean name for persistent keying
    local cleanName = nil
    if name and not (issecretvalue and issecretvalue(name)) then
        cleanName = Ambiguate(name, "none")
    end

    -- Check duplicates: by character name (guarantees strictly 1 bar per player)
    local info = cleanName and activeBars[cleanName]
    
    if info then
        -- Refresh existing bar
        if not isReady then
            local now = GetTime()
            -- Dedup: ignore duplicate kick events within 0.5s of cooldown start
            if info.duration > 0 and (info.expiration - now) > (baseCD - 0.5) then
                return
            end
            local duration = baseCD
            info.expiration = now + duration
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
    
    -- If no cleanName could be resolved, do not create unkeyed orphan bars
    if not cleanName then return end

    -- Create new
    local f = GetBar()
    
    local spellIcon = nil
    if spellId and not (issecretvalue and issecretvalue(spellId)) then
        local siOk, icon = pcall(C_Spell.GetSpellTexture, spellId)
        if siOk and icon then spellIcon = icon end
    end
    if not spellIcon then
        spellIcon = C_Spell.GetSpellTexture(1766)
    end
    
    -- Apply styling with class info
    StyleBar(f, class)
    
    f.icon:SetTexture(spellIcon)
    pcall(f.name.SetText, f.name, cleanName)
    
    local duration = 0
    local expiration = 0
    
    if not isReady then
        duration = baseCD
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
    
    local newInfo = AcquireInfo(guid, cleanName, class, spellId or 1766, duration, expiration, f)
    activeBars[cleanName] = newInfo
    
    updateFrame:Show() -- Ensure OnUpdate is running
    UpdateLayout()
end



-- ============================================================================
-- HANDLE PARTY CAST (triggered by correlation or mob-attribution)
-- ============================================================================
local function HandlePartyCast(memberName, spellID)
    if not IsTrackerAllowed() then return end
    local entry = partyRegistry[memberName]
    if not entry then return end
    local cd = INTERRUPTS[spellID] or entry.baseCd or 15
    local guid = entry.guid

    local now = GetTime()
    entry.cdEnd = now + cd
    if guid then
        StartCooldown(guid, memberName, entry.class, spellID)
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
    -- NOTE: SHAMAN excluded intentionally ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Resto Shaman keeps Wind Shear (HEALER_KEEPS_KICK)
}

local function AutoRegisterPartyByClass()
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) then
            local name = UnitName(u)
            local _, cls = UnitClass(u)
            -- TAINT FIX: UnitName/UnitClass can return secrets; skip if tainted
            if issecretvalue and (issecretvalue(name) or issecretvalue(cls)) then
                -- skip this unit; retry loop will catch it later
            elseif name and cls and CLASS_INTERRUPTS[cls] and not partyRegistry[name] and not noKickPlayers[name] then
                local role = UnitGroupRolesAssigned(u)
                if role ~= "HEALER" or HEALER_KEEPS_KICK[cls] then
                    local guid   = UnitGUID(u)
                    -- TAINT FIX: UnitGUID can return a secret
                    if issecretvalue and issecretvalue(guid) then guid = nil end
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
                        -- For players that CAN be healers with unknown/NONE role, defer registration.
                        -- NPCs/Followers with explicit TANK/DAMAGER roles are registered immediately.
                        if UnitIsPlayer(u) and (not role or role == "NONE") and HEALER_CAPABLE_CLASS[cls] then
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
                                -- Confirmed healer spec ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ remove bar + registry entry
                                local guid = entry.guid
                                if guid then
                                    for key, info in pairs(activeBars) do
                                        if info.guid == guid then
                                            ClearActiveBar(key)
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
                            -- Now we have spec data ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â register if appropriate.
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
-- OWN PLAYER KICK (player spellID is always untainted)
-- ============================================================================
local _addonMsgBlocked = false
InterruptTracker._pendingOwnKickAt = nil

local function OwnKick(spellID)
    if not IsTrackerAllowed() then return end
    spellID = SPELL_ALIASES[spellID] or spellID
    if not INTERRUPTS[spellID] then return end
    -- TAINT FIX: UnitGUID/UnitName/UnitClass can return secrets
    local guid = UnitGUID("player")
    if issecretvalue and issecretvalue(guid) then return end
    local name = UnitName("player")
    if issecretvalue and issecretvalue(name) then name = "Player" end
    local _, class = UnitClass("player")
    if issecretvalue and issecretvalue(class) then class = "WARRIOR" end
    InterruptTracker._pendingOwnKickAt = GetTime()

    -- Use real CD from the game engine (accounts for talents, Haste, resets)
    local startTime, realDuration = PlayerSpellCooldown(spellID)
    if realDuration then
        StartCooldown(guid, name, class, spellID)
        -- Patch the bar's duration/expiration to match the real cooldown
        local keyOk, key = pcall(function() return guid .. spellID end)
        if keyOk and activeBars[key] then
            activeBars[key].duration = realDuration
            activeBars[key].expiration = startTime + realDuration
        end
    else
        StartCooldown(guid, name, class, spellID)
    end

    -- Broadcast to other GravityUI users (secondary confirmation channel)
    if not _addonMsgBlocked then
        local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
        local ok, ret = pcall(function() return C_ChatInfo.SendAddonMessage("GRV_INT", tostring(spellID), channel) end)
        if ok and ret == 11 then _addonMsgBlocked = true end
    end
end

-- ============================================================================
-- NAMEPLATE INTERRUPT EVENT HANDLER (MiniAura-proven pattern, 12.x / Midnight compatible)
-- ============================================================================
-- Decodes the interrupter from stop-event payloads (MiniAura pattern).
-- Returns: interruptedBy (GUID), interruptedSpellId
local function GetInterrupter(event, ...)
    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local _, _, spellId, interruptedBy = ...
        return interruptedBy, spellId
    elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        local _, _, spellId, _, interruptedBy = ...
        return interruptedBy, spellId
    end
    return nil, nil
end

local NAMEPLATE_PREFIX = "^nameplate"
local REPEAT_WINDOW = 0.5   -- Dedup: same mob within 0.5s (engine fires per-token)
local OWN_CAST_WINDOW = 0.5 -- Match own kick to mob interrupt within 0.5s
local lastRecordedAt = {}    -- [unitToken] = timestamp
local lastPartyCastTime = {} -- [unitToken] = timestamp

local _playerFrame = CreateFrame("Frame")
local _interruptFrame = CreateFrame("Frame")
local _framesEnabled = false

local function PlayerFrame_OnEvent(_, _, unit, _, spellID)
    if not spellID or not IsTrackerAllowed() then return end
    if unit == "player" or unit == "pet" then
        if issecretvalue and issecretvalue(spellID) then return end
        local normalizedID = SPELL_ALIASES[spellID] or spellID
        if not INTERRUPTS[normalizedID] then return end
        OwnKick(normalizedID)
    end
end

local function InterruptFrame_OnEvent(self, event, unit, arg2, arg3, arg4, arg5)
    local s = GetSettings()
    if not s or not s.enabled or not IsTrackerAllowed() then return end

    local interruptedBy
    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        interruptedBy = arg4
    elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        interruptedBy = arg5
    end

    if interruptedBy == nil then return end
    if not unit or unit:sub(1, 9) ~= "nameplate" then return end
    if not UnitCanAttack("player", unit) then return end

    local now = GetTime()
    local last = lastRecordedAt[unit]
    if last and (now - last) <= REPEAT_WINDOW then return end
    lastRecordedAt[unit] = now

    -- Check if player kicked (handled by OwnKick via PlayerFrame)
    if InterruptTracker._pendingOwnKickAt and (now - InterruptTracker._pendingOwnKickAt) <= OWN_CAST_WINDOW then
        InterruptTracker._pendingOwnKickAt = nil
        return
    end

    -- Ally kick: Find candidate from party members who currently have their kick Ready
    local readyCandidate, readyEntry = nil, nil
    for memberName, entry in pairs(partyRegistry) do
        local barInfo = activeBars[memberName]
        if barInfo and (barInfo.duration == 0 or now >= barInfo.expiration) then
            readyCandidate = memberName
            readyEntry = entry
            break
        end
    end

    if readyCandidate and readyEntry then
        StartCooldown(readyEntry.guid, readyCandidate, readyEntry.class, readyEntry.spellID)
        return
    end

    -- Fallback: If all were on cooldown, refresh the first party member's cooldown
    for memberName, entry in pairs(partyRegistry) do
        StartCooldown(entry.guid, memberName, entry.class, entry.spellID)
        break
    end
end

local function EnableTrackerFrames()
    if _framesEnabled then return end
    _playerFrame:SetScript("OnEvent", PlayerFrame_OnEvent)
    _playerFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")

    _interruptFrame:SetScript("OnEvent", InterruptFrame_OnEvent)
    _interruptFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    _interruptFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    _interruptFrame:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
    _framesEnabled = true
end

local function DisableTrackerFrames()
    if not _framesEnabled then return end
    _playerFrame:UnregisterAllEvents()
    _playerFrame:SetScript("OnEvent", nil)

    _interruptFrame:UnregisterAllEvents()
    _interruptFrame:SetScript("OnEvent", nil)

    wipe(lastRecordedAt)
    _framesEnabled = false
end


-- GRV_INT ADDON MESSAGE HANDLER (secondary confirmation from other GravityUI users)
-- ============================================================================
function InterruptTracker:CHAT_MSG_ADDON(event, prefix, text, channel, sender)
    if prefix ~= "GRV_INT" then return end
    if not IsTrackerAllowed() then return end
    -- TAINT FIX: sender and all derived values can be secret strings
    if issecretvalue and issecretvalue(sender) then return end
    local ambOk, name = pcall(Ambiguate, sender, "none")
    if not ambOk or not name or (issecretvalue and issecretvalue(name)) then return end
    if UnitIsUnit(name, "player") then return end
    local spellId = tonumber(text)
    if not spellId or not INTERRUPTS[spellId] then return end
    local guid = UnitGUID(name)
    if not guid or (issecretvalue and issecretvalue(guid)) then return end
    local _, class = UnitClass(name)
    if issecretvalue and issecretvalue(class) then class = "WARRIOR" end
    StartCooldown(guid, name, class, spellId)
end

-- No-op: old UNIT_SPELLCAST_SUCCEEDED method (now handled by _playerFrame/_interruptFrame)
function InterruptTracker:UNIT_SPELLCAST_SUCCEEDED() end







function InterruptTracker.TestMode()
    if testModeActive then
        ClearAllActiveBars()
        testModeActive = false
    else
        testModeActive = true
        StartCooldown("test_warrior", "Warrior", "WARRIOR", 6552, nil, true) -- Pummel
        StartCooldown("test_mage", "Mage", "MAGE", 2139, nil, true) -- Counterspell
        StartCooldown("test_shaman", "Shaman", "SHAMAN", 57994, true, true) -- Wind Shear
        updateFrame:Show()
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

local function OnInspectReady(guid)
    if not guid then return end

    -- Resolve unit from GUID
    local unit = nil
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

    if not unit then return end

    local specID = GetInspectSpecialization(unit)
    if not specID or specID <= 0 then return end

    activeSpecs[guid] = specID
    InvalidateAllyKickCache()  -- Spec changed, re-infer next time

    -- If this is a confirmed healer spec with no interrupt, remove any existing bar immediately
    local name = UnitName(unit)
    local cleanName = name and Ambiguate(name, "none")
    if SPEC_NO_INTERRUPT[specID] then
        if cleanName then
            noKickPlayers[cleanName] = true
            partyRegistry[cleanName] = nil
            ClearActiveBar(cleanName)
            UpdateLayout()
        end
        return
    end

    -- Update active bar and partyRegistry with spec interrupt / cooldown
    if cleanName and activeBars[cleanName] then
        local info = activeBars[cleanName]
        local specInterrupt = SPEC_INTERRUPTS[specID]
        if specInterrupt then
            info.spellId = specInterrupt
            local icon = C_Spell.GetSpellTexture(specInterrupt)
            if icon and info.frame then
                info.frame.icon:SetTexture(icon)
            end
        end
        if partyRegistry[cleanName] then
            partyRegistry[cleanName].spellID = info.spellId
            local baseCd = INTERRUPTS[info.spellId] or 15
            if SPEC_COOLDOWN_OVERRIDES[info.spellId] and SPEC_COOLDOWN_OVERRIDES[info.spellId][specID] then
                baseCd = SPEC_COOLDOWN_OVERRIDES[info.spellId][specID]
            end
            partyRegistry[cleanName].baseCd = baseCd
        end
        StyleBar(info.frame, info.class)
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
         ClearAllActiveBars()
         UpdateLayout() -- Ensure it clears
         return
    end
    
    -- Register Watchers for Party Members
    RegisterPartyWatchers()

    -- Build partyRegistry for new members
    AutoRegisterPartyByClass()

    local currentPartyNames = {}
    
    local function HandleMember(unit)
        if not UnitExists(unit) then return end
        
        local name = UnitName(unit)
        if not name then return end
        local cleanName = Ambiguate(name, "none")
        currentPartyNames[cleanName] = true
        
        local ok, guid = pcall(UnitGUID, unit)
        if not ok or not guid then guid = cleanName end
        
        -- Queue Inspect (Dynamic CD)
        if not UnitIsUnit(unit, "player") then
            QueueInspect(unit)
        end
        
        -- Create/Update Bar (Persistent)
        local _, class = UnitClass(unit)
        local role = UnitGroupRolesAssigned(unit)
        
        -- Skip healers that aren't shamans (they usually don't have interrupts by default)
        if role == "HEALER" and not HEALER_KEEPS_KICK[class] then
            if activeBars[cleanName] then ClearActiveBar(cleanName) end
            return
        end
        
        -- Spec-based check
        local specID = (guid and not (issecretvalue and issecretvalue(guid)) and activeSpecs[guid]) or (GetInspectSpecialization and UnitExists(unit) and GetInspectSpecialization(unit))
        if specID and specID > 0 then
            if SPEC_NO_INTERRUPT[specID] then
                if activeBars[cleanName] then ClearActiveBar(cleanName) end
                return
            end
        else
            if UnitIsPlayer(unit) and (not role or role == "NONE") and HEALER_CAPABLE_CLASS[class] then return end
        end
        
        -- Priority: Spec-specific interrupt > Class interrupt
        local interruptID = CLASS_INTERRUPTS[class]
        if specID and SPEC_INTERRUPTS[specID] then
            interruptID = SPEC_INTERRUPTS[specID]
        end
        
        if interruptID then
            if activeBars[cleanName] then
                -- Already exists: update class & spellId and re-style
                local info = activeBars[cleanName]
                info.class = class
                info.spellId = interruptID
                info.guid = guid
                StyleBar(info.frame, class)
            else
                StartCooldown(guid, cleanName, class, interruptID, true) -- Force Ready State
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
    for key in pairs(activeBars) do
        if not currentPartyNames[key] and not testModeActive then
             ClearActiveBar(key)
        end
    end
    for name in pairs(partyRegistry) do
        if not currentPartyNames[name] then
            partyRegistry[name] = nil
        end
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
    if not IsTrackerAllowed() then return end
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

function InterruptTracker.ToggleMover(forceState)
    if not container then return end
    local s = GetSettings()
    
    local shouldShow = false
    if forceState ~= nil then
        shouldShow = forceState
    else
        shouldShow = not (container.mover and container.mover:IsShown())
    end
    
    if shouldShow then
        container:Show()
        if container.mover then container.mover:Show() end
        
        -- Add dummy bars for visual preview if empty
        if not next(activeBars) then
            StartCooldown("test_warrior", "Warrior", "WARRIOR", 6552, nil, true) -- Pummel
            StartCooldown("test_mage", "Mage", "MAGE", 2139, nil, true) -- Counterspell
            StartCooldown("test_shaman", "Shaman", "SHAMAN", 57994, true, true) -- Wind Shear
            moverDummiesActive = true
            updateFrame:Show()
        end
    else
        if container.mover then container.mover:Hide() end
        
        -- Clear dummies ONLY if we created them
        if moverDummiesActive then
            ClearAllActiveBars()
            moverDummiesActive = false
            -- Trigger immediate roster update to restore real bars if any
            OnGroupRosterUpdate()
        end
        
        if s and not s.enabled then
            container:Hide()
        end
    end

    if ns.Movers and ns.Movers.ApplyEditModeStyle and container then
        ns.Movers:ApplyEditModeStyle(container, shouldShow, "InterruptTracker")
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
    container:EnableMouse(false)

    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local ux, uy = UIParent:GetCenter()
        if x and ux then
            s.x = math.floor(x - ux + 0.5)
            s.y = math.floor(y - uy + 0.5)
        end
    end)
    
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
        if container:GetScript("OnDragStop") then
            container:GetScript("OnDragStop")(container)
        end
    end)
    container.mover = mover
    
    -- Init Events via AceEvent
    if s.enabled then
        EnableTrackerFrames()
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
        DisableTrackerFrames()
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
        EnableTrackerFrames()
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
        DisableTrackerFrames()
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
     
     -- PERF: Settings changed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ force the OnUpdate cache to re-read on next tick.
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
