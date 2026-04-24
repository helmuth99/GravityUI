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
    { class = "DEMONHUNTER", spellID = 183752, cd = 15, isDefault = true },
    -- DRUID
    { class = "DRUID", spellID = 106839, cd = 15, isDefault = true },
    { class = "DRUID", spellID = 78675, cd = 60, specID = 102 }, -- Balance (Solar Beam)
    -- EVOKER
    { class = "EVOKER", spellID = 351338, cd = 40, isDefault = true, talents = { [412713] = { pctReduction = 0.1 } } }, -- Interwoven Threads
    -- HUNTER
    { class = "HUNTER", spellID = 147362, cd = 24, isDefault = true, talents = { [388039] = { reduction = 2 } } }, -- Lone Survivor (Counter Shot)
    { class = "HUNTER", spellID = 187707, cd = 15, specID = 255, talents = { [388039] = { reduction = 2 } } }, -- Lone Survivor (Muzzle)
    -- MAGE
    { class = "MAGE", spellID = 2139, cd = 24, isDefault = true },
    -- MONK
    { class = "MONK", spellID = 116705, cd = 15, isDefault = true },
    -- PALADIN
    { class = "PALADIN", spellID = 96231, cd = 15, isDefault = true },
    { class = "PALADIN", spellID = 420090, cd = 15 }, -- NPC Rebuke (Follower Dungeon)
    -- PRIEST
    { class = "PRIEST", spellID = 15487, cd = 45, specID = 258, isDefault = true }, -- Shadow (Silence)
    -- ROGUE
    { class = "ROGUE", spellID = 1766, cd = 15, isDefault = true },
    -- SHAMAN
    { class = "SHAMAN", spellID = 57994, cd = 12, isDefault = true, overrides = { [264] = 30 } }, -- Resto 30s
    -- WARLOCK
    { class = "WARLOCK", spellID = 19647, cd = 24, isDefault = true }, -- Spell Lock
    { class = "WARLOCK", spellID = 132409, cd = 24 }, -- Spell Lock / Fel Ravager
    { class = "WARLOCK", spellID = 119914, cd = 30, specID = 266 }, -- Axe Toss (Demonology Primary)
    -- WARRIOR
    { class = "WARRIOR", spellID = 6552, cd = 15, isDefault = true },
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
local SPEC_EXTRA_KICKS = {
    [266] = { -- Warlock Demonology
        { id = 132409, cd = 24, name = "Spell Lock" }
    }
}
local SPELL_ALIASES = {
    [1276467] = 132409, -- Fel Ravager summon -> Spell Lock extra bar
    [89766] = 119914,   -- Felguard Axe Toss (pet) -> Axe Toss (player)
}
-- Automatically register talents that grant an extra kick
local EXTRA_KICK_TALENTS = {
    [385110] = { id = 1276467, cd = 25, name = "Fel Ravager" }, -- Warlock Grimoire of Sacrifice
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
    end
end
BuildInterruptTables()

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
-- SPELL ID LAUNDERING & PARTY WATCHERS
-- ============================================================================
local recentPartyCasts = {}

-- These MUST be created here, NOT inside event handlers
local launderBar = CreateFrame("StatusBar")
launderBar:SetMinMaxValues(0, 9999999)

-- Slider for OnValueChanged laundering
local launderSlider = CreateFrame("Slider", nil, UIParent)
launderSlider:SetMinMaxValues(0, 9999999)
launderSlider:SetSize(1, 1)
launderSlider:Hide()

local onSliderChangedResult = nil
local onValueChangedResult = nil  -- war versehentlich global, jetzt local
launderSlider:SetScript("OnValueChanged", function(self, value)
    onSliderChangedResult = value
end)

local playerWatcher = CreateFrame("Frame")
local partyFrames = {}
local partyPetFrames = {}
for i = 1, 4 do
    partyFrames[i] = CreateFrame("Frame")
    partyPetFrames[i] = CreateFrame("Frame")
end

-- Helper to register events
local function RegisterPartyWatchers()
    -- Player Watcher
    playerWatcher:UnregisterAllEvents()
    playerWatcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    playerWatcher:SetScript("OnEvent", function(_, _, unit, castGUID, spellId)
         InterruptTracker:UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", unit, castGUID, spellId)
    end)

    -- Party Watchers
    for i = 1, 4 do
        local unit = "party" .. i
        partyFrames[i]:UnregisterAllEvents()
        if UnitExists(unit) then
            partyFrames[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
            partyFrames[i]:SetScript("OnEvent", function(self, event, eUnit, eCastGUID, eSpellID, eCastBarID)
                local cleanUnit = "party" .. i
                local cleanName = UnitName(cleanUnit)

                -- PERF: Replaced pcall-closure with a direct nil-guard.
                -- Anonymous closures allocate GC objects on every spellcast event.
                if cleanName then
                    recentPartyCasts[cleanName] = GetTime()
                end

                -- Try OnValueChanged laundering (StatusBar)
                onValueChangedResult = nil
                launderBar:SetValue(0)
                pcall(launderBar.SetValue, launderBar, eSpellID)
                local barResult = onValueChangedResult

                -- Try OnValueChanged laundering (Slider)
                onSliderChangedResult = nil
                launderSlider:SetValue(0)
                pcall(launderSlider.SetValue, launderSlider, eSpellID)
                local sliderResult = onSliderChangedResult

                -- PERF: Replaced pcall-closures with direct table lookups.
                -- INTERRUPTS is a plain Lua table; indexing it never raises an error.
                local cleanID = nil
                if barResult and INTERRUPTS[barResult] then
                    cleanID = barResult
                end
                if not cleanID and sliderResult and INTERRUPTS[sliderResult] then
                    cleanID = sliderResult
                end

                if cleanID and cleanName then
                    InterruptTracker:UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", cleanUnit, eCastGUID, cleanID)
                elseif cleanName then
                    -- Fallback: spellID was tainted (Midnight 12.x) but we know this unit cast something.
                    -- If their registered interrupt is NOT on cooldown, start it now — this covers
                    -- "kick without an interrupted cast" where UNIT_SPELLCAST_INTERRUPTED never fires.
                    local guid = UnitGUID(cleanUnit)
                    if guid then
                        local _, cls = UnitClass(cleanUnit)
                        local interruptID = CLASS_INTERRUPTS[cls]
                        if activeSpecs[guid] and SPEC_INTERRUPTS[activeSpecs[guid]] then
                            interruptID = SPEC_INTERRUPTS[activeSpecs[guid]]
                        end
                        if interruptID then
                            local key = guid .. interruptID
                            local existing = activeBars[key]
                            local isOnCD = existing and existing.expiration and existing.expiration > GetTime()
                            if not isOnCD then
                                -- Kick detected via tainted spellID fallback
                                InterruptTracker:UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", cleanUnit, eCastGUID, interruptID)
                            end
                        end
                    end
                end
            end)
        end
    end

    -- Party Pet Watchers
    for i = 1, 4 do
        local petUnit = "partypet" .. i
        local ownerUnit = "party" .. i
        partyPetFrames[i]:UnregisterAllEvents()
        if UnitExists(petUnit) then
            partyPetFrames[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", petUnit)
            partyPetFrames[i]:SetScript("OnEvent", function(self, event, eUnit, eCastGUID, eSpellID, eCastBarID)
                local cleanOwner = "party" .. i
                local cleanName = UnitName(cleanOwner)

                -- PERF: Replaced pcall-closure with a direct nil-guard.
                if cleanName then
                    recentPartyCasts[cleanName] = GetTime()
                end

                onValueChangedResult = nil
                launderBar:SetValue(0)
                pcall(launderBar.SetValue, launderBar, eSpellID)
                local barResult = onValueChangedResult

                -- PERF: Replaced pcall-closure with direct table lookup.
                local cleanID = nil
                if barResult and INTERRUPTS[barResult] then
                    cleanID = barResult
                end

                if cleanID and cleanName then
                    InterruptTracker:UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", cleanOwner, eCastGUID, cleanID)
                end
            end)
        end
    end
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



function InterruptTracker:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellId)
    -- Restriction: Only in Party (Dungeons/M+), Disable in Raid/Solo
    if not IsInGroup() then return end
    if IsInRaid() then return end
    
    local _, instanceType = IsInInstance()
    if instanceType == "raid" then return end

    if not spellId or type(spellId) ~= "number" then return end
    
    if SPELL_ALIASES and SPELL_ALIASES[spellId] then
        spellId = SPELL_ALIASES[spellId]
    end

    local success, val = pcall(function() return INTERRUPTS[spellId] end)
    if success and val then 
         local guid = UnitGUID(unit)
         if not guid then return end
         local name = UnitName(unit)
         local _, class = UnitClass(unit)
         
         -- Start Local Cooldown
         StartCooldown(guid, name, class, spellId)
         
         -- Record for correlation fallback
         pcall(function() recentPartyCasts[name] = GetTime() end)
         
         -- Try Addon Message (may not work in M+ in Midnight, but keep as fallback)
         -- Only send if we are the one who cast it
         if UnitIsUnit(unit, "player") then
             local payload = tostring(spellId)
             local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
             local ok, ret = pcall(C_ChatInfo.SendAddonMessage, "GRV_INT", payload, channel)
             
             -- Fallback: If channel send failed or is blocked, whisper each real player in the party.
             -- We explicitly check UnitIsPlayer to avoid errors in Follower Dungeons (NPCs).
             if not ok or ret == 0 then
                 for i = 1, 4 do
                     local pUnit = "party" .. i
                     if UnitExists(pUnit) and UnitIsPlayer(pUnit) then
                         local okName, pName, pRealm = pcall(UnitFullName, pUnit)
                         if okName and pName then
                             local target = (pRealm and pRealm ~= "") and (pName .. "-" .. pRealm) or pName
                             pcall(C_ChatInfo.SendAddonMessage, "GRV_INT", payload, "WHISPER", target)
                         end
                     end
                 end
             end
         end
    end
end
    
function InterruptTracker:CHAT_MSG_ADDON(event, prefix, text, channel, sender)
    if prefix ~= "GRV_INT" then return end
    if not IsTrackerAllowed() then return end
    
    -- Ignore Self (handled locally in UNIT_SPELLCAST_SUCCEEDED)
    local name = Ambiguate(sender, "none")
    if UnitIsUnit(name, "player") then return end
    
    local spellId = tonumber(text)
    if not spellId then return end
    
    local guid = UnitGUID(name)
    if not guid then return end
    
    local _, class = UnitClass(name)
    StartCooldown(guid, name, class, spellId)
end

-- Shared handler for Say/Party kick messages (M+ fallback when addon comms are blocked)
local function OnChatKickReceived(senderName, text)
    if not IsTrackerAllowed() then return end
    -- Match any number in parentheses: e.g. "Interrupted (47528)" or "Kicked! (47528)"
    local ok, spellId = pcall(function()
        if not text or type(text) ~= "string" then return nil end
        return text:match("%((%d+)%)")
    end)
    
    if not ok or not spellId then return end
    spellId = tonumber(spellId)
    if not spellId then return end
    
    if SPELL_ALIASES and SPELL_ALIASES[spellId] then
        spellId = SPELL_ALIASES[spellId]
    end

    -- Only process known interrupt spells (prevents false positives from random chat)
    local ok2, val = pcall(function() return INTERRUPTS[spellId] end)
    if not ok2 or not val then return end
    
    -- Ignore own messages (already handled locally)
    local name = Ambiguate(senderName, "none")
    if UnitIsUnit(name, "player") then return end
    
    local guid = UnitGUID(name)
    if not guid then return end
    local _, class = UnitClass(name)
    StartCooldown(guid, name, class, spellId)
end

function InterruptTracker:CHAT_MSG_SAY(event, text, senderName)
    OnChatKickReceived(senderName, text)
end

function InterruptTracker:CHAT_MSG_PARTY(event, text, senderName)
    OnChatKickReceived(senderName, text)
end

-- ============================================================================
-- TIME-CORRELATION FALLBACK (MOB INTERRUPTED)
-- ============================================================================
local function OnMobInterrupted(unit)
    if not IsTrackerAllowed() then return end
    local now = GetTime()
    local bestName = nil
    local bestDelta = 999

    for name, ts in pairs(recentPartyCasts) do
        local delta = now - ts
        if delta > 1.0 then
            recentPartyCasts[name] = nil
        elseif delta < bestDelta then
            bestDelta = delta
            bestName = name
        end
    end

    if bestName and bestDelta < 0.5 then
        -- We found the likely kicker
        -- Fallback to default class interrupt
        for idx = 1, 4 do
            local u = "party" .. idx
            if UnitExists(u) and UnitName(u) == bestName then
                local guid = UnitGUID(u)
                local _, class = UnitClass(u)
                local role = UnitGroupRolesAssigned(u)
                
                -- Skip healers that aren't shamans
                if not (role == "HEALER" and class ~= "SHAMAN") then
                    -- Priority: Spec-specific interrupt > Class interrupt
                    local interruptID = CLASS_INTERRUPTS[class]
                    if activeSpecs[guid] and SPEC_INTERRUPTS[activeSpecs[guid]] then
                        interruptID = SPEC_INTERRUPTS[activeSpecs[guid]]
                    end
                    
                    if interruptID and guid then
                        StartCooldown(guid, bestName, class, interruptID)
                    end
                    
                    -- Handle on-kick conditional CD reductions (e.g. DK Coldthirst)
                    local key = guid .. (interruptID or CLASS_INTERRUPTS[class])
                    local info = activeBars[key]
                    if info and activeReductions[guid] and activeReductions[guid].onKick then
                        local newExpiration = info.expiration - activeReductions[guid].onKick
                        if newExpiration < now then newExpiration = now end
                        info.expiration = newExpiration
                        -- Avoid updating the text here, OnUpdate will smoothly catch it
                        if not testModeActive then updateFrame:Show() end
                    end
                end
                break
            end
        end
    end
end

local mobInterruptFrame = CreateFrame("Frame")
mobInterruptFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target", "focus")
mobInterruptFrame:SetScript("OnEvent", function(self, event, unit)
    OnMobInterrupted(unit)
end)

local nameplateCastFrames = {}
local nameplateFrame = CreateFrame("Frame")
nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
nameplateFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        if not nameplateCastFrames[unit] then
            nameplateCastFrames[unit] = CreateFrame("Frame")
        end
        local f = nameplateCastFrames[unit]
        f:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
        f:SetScript("OnEvent", function(_, _, eUnit)
            OnMobInterrupted(eUnit)
        end)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if nameplateCastFrames[unit] then
            nameplateCastFrames[unit]:UnregisterAllEvents()
            nameplateCastFrames[unit]:SetScript("OnEvent", nil)
            nameplateCastFrames[unit] = nil  -- Frame-Leak-Fix: Referenz freigeben
        end
    end
end)





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
        -- Holy Paladins specifically are reported as having an incorrect interrupt bar
        if role == "HEALER" and class ~= "SHAMAN" then return end
        
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
    
    -- Clean up removed members
    for key, info in pairs(activeBars) do
        -- Logic: If guid is not in current members AND bar is not testMode, hide it.
        if not members[info.guid] and not testModeActive then
             info.frame:Hide()
             activeBars[key] = nil
        end
    end
    
    UpdateLayout()
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
        
        -- Addon Communication (may not work in M+ in Midnight)
        C_ChatInfo.RegisterAddonMessagePrefix("GRV_INT")
        InterruptTracker:RegisterEvent("CHAT_MSG_ADDON")
        
        -- Chat listener: picks up GRV_INT:SPELLID from kick macros in say/party
        InterruptTracker:RegisterEvent("CHAT_MSG_SAY")
        InterruptTracker:RegisterEvent("CHAT_MSG_PARTY")
        
        container:Show()
        OnGroupRosterUpdate()
        RegisterPartyWatchers()
        
        updateFrame:Show()
    else
        InterruptTracker:UnregisterAllEvents()
        playerWatcher:UnregisterAllEvents()
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
        
        -- Addon Communication (may not work in M+ in Midnight)
        C_ChatInfo.RegisterAddonMessagePrefix("GRV_INT")
        InterruptTracker:RegisterEvent("CHAT_MSG_ADDON")
        
        -- Chat listener: always on when tracker is enabled
        InterruptTracker:RegisterEvent("CHAT_MSG_SAY")
        InterruptTracker:RegisterEvent("CHAT_MSG_PARTY")
        
        OnGroupRosterUpdate()
        RegisterPartyWatchers()
        
        updateFrame:Show()
        container:Show()
    else
        InterruptTracker:UnregisterAllEvents()
        playerWatcher:UnregisterAllEvents()
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
