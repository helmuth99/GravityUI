local ADDON_NAME, ns = ...

-- ============================================================================
-- GravityUI CD Tracker — Defensive & Offensive Cooldowns
-- Tracks party member cooldowns and attaches icon badges to party frames.
-- ============================================================================

local CDTracker = {}
ns.CDTracker = CDTracker

LibStub("AceEvent-3.0"):Embed(CDTracker)

-- ============================================================================
-- SPELL DATABASE
-- ============================================================================
-- cat: "DEFENSIVE" | "OFFENSIVE"
-- specID: 0 = all specs, number = specific specID, table = list of specIDs
-- cd: cooldown in seconds

local CD_CONFIG = {
    -- ══════════════════════════════════════════
    -- DEATH KNIGHT
    -- ══════════════════════════════════════════
    -- Defensive
    { class = "DEATHKNIGHT", cat = "DEFENSIVE", spellID = 48792,  cd = 120,              }, -- Icebound Fortitude
    { class = "DEATHKNIGHT", cat = "DEFENSIVE", spellID = 48707,  cd = 40,               }, -- Anti-Magic Shell
    { class = "DEATHKNIGHT", cat = "DEFENSIVE", spellID = 51052,  cd = 120,              }, -- Anti-Magic Zone
    { class = "DEATHKNIGHT", cat = "DEFENSIVE", spellID = 55233,  cd = 90,  specID = 250 }, -- Vampiric Blood (Blood)
    -- Offensive
    { class = "DEATHKNIGHT", cat = "OFFENSIVE", spellID = 49028,  cd = 45,  specID = 250 }, -- Dancing Rune Weapon (Blood)
    { class = "DEATHKNIGHT", cat = "OFFENSIVE", spellID = 51271,  cd = 60,  specID = 251 }, -- Pillar of Frost (Frost)
    { class = "DEATHKNIGHT", cat = "OFFENSIVE", spellID = 279302, cd = 180, specID = 251 }, -- Frostwyrm's Fury (Frost)
    { class = "DEATHKNIGHT", cat = "OFFENSIVE", spellID = 42650,  cd = 180, specID = 252 }, -- Army of the Dead (Unholy)
    { class = "DEATHKNIGHT", cat = "OFFENSIVE", spellID = 63560,  cd = 45,  specID = 252 }, -- Dark Transformation (Unholy)

    -- ══════════════════════════════════════════
    -- DEMON HUNTER
    -- ══════════════════════════════════════════
    { class = "DEMONHUNTER", cat = "DEFENSIVE", spellID = 198589, cd = 60,  specID = 577 }, -- Blur (Havoc)
    { class = "DEMONHUNTER", cat = "DEFENSIVE", spellID = 196718, cd = 180               }, -- Darkness
    { class = "DEMONHUNTER", cat = "DEFENSIVE", spellID = 212800, cd = 180, specID = 577 }, -- Netherwalk (Havoc)
    { class = "DEMONHUNTER", cat = "DEFENSIVE", spellID = 187827, cd = 120, specID = 581 }, -- Metamorphosis (Vengeance)
    { class = "DEMONHUNTER", cat = "DEFENSIVE", spellID = 204021, cd = 60,  specID = 581 }, -- Fiery Brand (Vengeance)
    { class = "DEMONHUNTER", cat = "OFFENSIVE", spellID = 191427, cd = 120, specID = 577 }, -- Metamorphosis (Havoc)
    { class = "DEMONHUNTER", cat = "OFFENSIVE", spellID = 212084, cd = 60,  specID = 581 }, -- Fel Devastation (Vengeance)

    -- ══════════════════════════════════════════
    -- DRUID
    -- ══════════════════════════════════════════
    { class = "DRUID", cat = "DEFENSIVE", spellID = 22812,  cd = 60               }, -- Barkskin
    { class = "DRUID", cat = "DEFENSIVE", spellID = 61336,  cd = 180, specID = 104 }, -- Survival Instincts (Guardian)
    { class = "DRUID", cat = "DEFENSIVE", spellID = 102342, cd = 90,  specID = 105 }, -- Ironbark (Restoration)
    { class = "DRUID", cat = "OFFENSIVE", spellID = 102558, cd = 180, specID = 104 }, -- Incarnation: Ursoc (Guardian)
    { class = "DRUID", cat = "OFFENSIVE", spellID = 102560, cd = 180, specID = 102 }, -- Incarnation: Chosen of Elune (Balance)
    { class = "DRUID", cat = "OFFENSIVE", spellID = 323764, cd = 60               }, -- Convoke the Spirits

    -- ══════════════════════════════════════════
    -- EVOKER
    -- ══════════════════════════════════════════
    { class = "EVOKER", cat = "DEFENSIVE", spellID = 363916, cd = 90,               }, -- Obsidian Scales
    { class = "EVOKER", cat = "DEFENSIVE", spellID = 374227, cd = 120,              }, -- Renewing Blaze
    { class = "EVOKER", cat = "DEFENSIVE", spellID = 363534, cd = 180, specID = 1468 }, -- Rewind (Preservation)
    { class = "EVOKER", cat = "DEFENSIVE", spellID = 370537, cd = 90,  specID = 1468 }, -- Stasis (Preservation)
    { class = "EVOKER", cat = "DEFENSIVE", spellID = 357170, cd = 60,  specID = 1468 }, -- Emerald Communion (Preservation)
    { class = "EVOKER", cat = "OFFENSIVE", spellID = 375087, cd = 120, specID = 1467 }, -- Dragonrage (Devastation)
    { class = "EVOKER", cat = "OFFENSIVE", spellID = 403631, cd = 120, specID = 1473 }, -- Upheaval (Augmentation)

    -- ══════════════════════════════════════════
    -- HUNTER
    -- ══════════════════════════════════════════
    { class = "HUNTER", cat = "DEFENSIVE", spellID = 186265, cd = 180              }, -- Aspect of the Turtle
    { class = "HUNTER", cat = "DEFENSIVE", spellID = 264735, cd = 180              }, -- Survival of the Fittest
    { class = "HUNTER", cat = "DEFENSIVE", spellID = 109304, cd = 120              }, -- Exhilaration
    { class = "HUNTER", cat = "OFFENSIVE", spellID = 288613, cd = 120, specID = 254 }, -- Trueshot (Marksmanship)

    -- ══════════════════════════════════════════
    -- MAGE
    -- ══════════════════════════════════════════
    { class = "MAGE", cat = "DEFENSIVE", spellID = 414658, cd = 180              }, -- Ice Cold / Ice Block
    { class = "MAGE", cat = "DEFENSIVE", spellID = 45438,  cd = 240              }, -- Ice Block
    { class = "MAGE", cat = "DEFENSIVE", spellID = 342245, cd = 50               }, -- Alter Time
    { class = "MAGE", cat = "DEFENSIVE", spellID = 235450, cd = 24,  specID = 62  }, -- Prismatic Barrier (Arcane)
    { class = "MAGE", cat = "DEFENSIVE", spellID = 235313, cd = 24,  specID = 63  }, -- Blazing Barrier (Fire)
    { class = "MAGE", cat = "DEFENSIVE", spellID = 11426,  cd = 24,  specID = 64  }, -- Ice Barrier (Frost)
    { class = "MAGE", cat = "OFFENSIVE", spellID = 365350, cd = 120, specID = 62  }, -- Arcane Surge (Arcane)
    { class = "MAGE", cat = "OFFENSIVE", spellID = 190319, cd = 60,  specID = 63  }, -- Combustion (Fire)
    { class = "MAGE", cat = "OFFENSIVE", spellID = 205021, cd = 60,  specID = 64  }, -- Icy Veins (Frost)

    -- ══════════════════════════════════════════
    -- MONK
    -- ══════════════════════════════════════════
    { class = "MONK", cat = "DEFENSIVE", spellID = 115203, cd = 240               }, -- Fortifying Brew
    { class = "MONK", cat = "DEFENSIVE", spellID = 122470, cd = 90,  specID = 269  }, -- Touch of Karma (Windwalker)
    { class = "MONK", cat = "DEFENSIVE", spellID = 119582, cd = 15,  specID = 268  }, -- Purifying Brew (Brewmaster)
    { class = "MONK", cat = "DEFENSIVE", spellID = 322507, cd = 45,  specID = 268  }, -- Celestial Brew (Brewmaster)
    { class = "MONK", cat = "OFFENSIVE", spellID = 137639, cd = 90,  specID = 269  }, -- Storm, Earth, and Fire (Windwalker)

    -- ══════════════════════════════════════════
    -- PALADIN
    -- ══════════════════════════════════════════
    { class = "PALADIN", cat = "DEFENSIVE", spellID = 642,   cd = 300              }, -- Divine Shield
    { class = "PALADIN", cat = "DEFENSIVE", spellID = 1022,  cd = 300              }, -- Blessing of Protection
    { class = "PALADIN", cat = "DEFENSIVE", spellID = 6940,  cd = 120              }, -- Blessing of Sacrifice
    { class = "PALADIN", cat = "DEFENSIVE", spellID = 31821, cd = 180, specID = 65  }, -- Aura Mastery (Holy)
    { class = "PALADIN", cat = "OFFENSIVE", spellID = 31884, cd = 120              }, -- Avenging Wrath

    -- ══════════════════════════════════════════
    -- PRIEST
    -- ══════════════════════════════════════════
    { class = "PRIEST", cat = "DEFENSIVE", spellID = 33206, cd = 180, specID = 256 }, -- Pain Suppression (Discipline)
    { class = "PRIEST", cat = "DEFENSIVE", spellID = 62618, cd = 180, specID = 256 }, -- Power Word: Barrier (Discipline)
    { class = "PRIEST", cat = "DEFENSIVE", spellID = 47788, cd = 180, specID = 257 }, -- Guardian Spirit (Holy)
    { class = "PRIEST", cat = "OFFENSIVE", spellID = 10060, cd = 120              }, -- Power Infusion

    -- ══════════════════════════════════════════
    -- ROGUE
    -- ══════════════════════════════════════════
    { class = "ROGUE", cat = "DEFENSIVE", spellID = 31224, cd = 120              }, -- Cloak of Shadows
    { class = "ROGUE", cat = "DEFENSIVE", spellID = 5277,  cd = 120              }, -- Evasion
    { class = "ROGUE", cat = "DEFENSIVE", spellID = 1856,  cd = 120              }, -- Vanish
    { class = "ROGUE", cat = "OFFENSIVE", spellID = 121471, cd = 120, specID = 261 }, -- Shadow Blades (Subtlety)

    -- ══════════════════════════════════════════
    -- SHAMAN
    -- ══════════════════════════════════════════
    { class = "SHAMAN", cat = "DEFENSIVE", spellID = 108271, cd = 90               }, -- Astral Shift
    { class = "SHAMAN", cat = "DEFENSIVE", spellID = 98008,  cd = 180, specID = 264 }, -- Spirit Link Totem (Restoration)
    { class = "SHAMAN", cat = "DEFENSIVE", spellID = 198838, cd = 60,  specID = 264 }, -- Earthen Wall Totem (Restoration)
    { class = "SHAMAN", cat = "OFFENSIVE", spellID = 114050, cd = 120, specID = 262 }, -- Ascendance (Elemental)

    -- ══════════════════════════════════════════
    -- WARLOCK
    -- ══════════════════════════════════════════
    { class = "WARLOCK", cat = "DEFENSIVE", spellID = 108416, cd = 45               }, -- Dark Pact
    { class = "WARLOCK", cat = "DEFENSIVE", spellID = 104773, cd = 180              }, -- Unending Resolve
    { class = "WARLOCK", cat = "OFFENSIVE", spellID = 265187, cd = 60,  specID = 266 }, -- Doom (Demonology) / Doomguard
    { class = "WARLOCK", cat = "OFFENSIVE", spellID = 1122,   cd = 120, specID = 267 }, -- Summon Infernal (Destruction)
    { class = "WARLOCK", cat = "OFFENSIVE", spellID = 18540,  cd = 120             }, -- Summon Doomguard

    -- ══════════════════════════════════════════
    -- WARRIOR
    -- ══════════════════════════════════════════
    { class = "WARRIOR", cat = "DEFENSIVE", spellID = 871,    cd = 180, specID = 73  }, -- Shield Wall (Protection)
    { class = "WARRIOR", cat = "DEFENSIVE", spellID = 118038, cd = 180, specID = 71  }, -- Die by the Sword (Arms)
    { class = "WARRIOR", cat = "DEFENSIVE", spellID = 184364, cd = 120, specID = 72  }, -- Enraged Regeneration (Fury)
    { class = "WARRIOR", cat = "DEFENSIVE", spellID = 23920,  cd = 25               }, -- Spell Reflect
    { class = "WARRIOR", cat = "OFFENSIVE", spellID = 107574, cd = 90               }, -- Avatar
    { class = "WARRIOR", cat = "OFFENSIVE", spellID = 1719,   cd = 90,  specID = 72  }, -- Recklessness (Fury)
}

-- Runtime lookup tables
local DEFENSIVES = {}   -- [spellID] = cd
local OFFENSIVES = {}   -- [spellID] = cd
local SPELL_CLASS = {}  -- [spellID] = class
local SPELL_SPEC  = {}  -- [spellID] = specID or table of specIDs

local function BuildCDTables()
    for _, data in ipairs(CD_CONFIG) do
        if data.cat == "DEFENSIVE" then
            DEFENSIVES[data.spellID] = data.cd
        else
            OFFENSIVES[data.spellID] = data.cd
        end
        SPELL_CLASS[data.spellID] = data.class
        if data.specID then
            SPELL_SPEC[data.spellID] = data.specID
        end
    end
end
BuildCDTables()

-- ============================================================================
-- PARTY FRAME DETECTION (DandersFrames / UUF / ElvUI / Grid2 / Blizzard)
-- ============================================================================
local activeSpecs = {} -- [guid] = specID

local function GetPartyUnitFrame(unit)
    local function IsValid(f) return f and f:IsVisible() end
    local function UnitMatch(f)
        if not f then return false end
        local fu = f.unit or (f.GetAttribute and f:GetAttribute("unit"))
        return fu and UnitIsUnit(fu, unit)
    end

    -- 1. DandersFrames / DUI
    if _G["DandersPartyHeader"] or _G["DUI_PlayerFrame"] or _G["DandersPlayerFrame"] then
        for i = 1, 5 do
            local f = _G["DUI_PartyFrame"..i]
                   or _G["DUI_UnitFrameParty"..i]
                   or _G["DandersPartyHeaderUnitButton"..i]
                   or _G["DUI_PartyGroup1UnitButton"..i]
            if IsValid(f) and UnitMatch(f) then return f end
        end
        if unit == "player" then
            local p = _G["DUI_PlayerFrame"] or _G["DandersPlayerFrame"] or _G["DandersPartyHeaderUnitButton0"]
            if IsValid(p) then return p end
        end
    end

    -- 2. ElvUI
    if _G["ElvUI"] then
        for i = 1, 5 do
            local f = _G["ElvUF_PartyGroup1UnitButton"..i]
            if IsValid(f) and UnitMatch(f) then return f end
        end
        if unit == "player" then
            local p = _G["ElvUF_Player"]
            if IsValid(p) then return p end
        end
    end

    -- 3. Grid2
    if _G["Grid2LayoutFrame"] then
        for i = 1, 5 do
            local f = _G["Grid2LayoutHeader1UnitButton"..i]
            if IsValid(f) and UnitMatch(f) then return f end
        end
    end

    -- 4. Blizzard CompactParty
    for i = 1, 5 do
        local f = _G["CompactPartyFrameMember"..i]
        if IsValid(f) and UnitMatch(f) then return f end
    end
    if unit == "player" then
        local p = _G["PlayerFrame"]
        if IsValid(p) then return p end
    end

    return nil
end

-- ============================================================================
-- SETTINGS
-- ============================================================================
local function GetSettings(trackerType)
    local db = ns.GetDB()
    if not db then return nil end
    if trackerType == "DEFENSIVE" then
        return db.defensiveTracker
    else
        return db.offensiveTracker
    end
end

local function IsSpellEnabled(trackerType, spellID)
    local s = GetSettings(trackerType)
    if not s then return true end
    if s.disabledSpells and s.disabledSpells[spellID] == false then
        return false
    end
    return true
end

-- ============================================================================
-- ICON MANAGEMENT (per-unit, per-spell icon badges on party frames)
-- ============================================================================
-- iconState[unit][spellID] = { frame, expiration, duration, class }
local iconState = {}
local UNITS = { "player", "party1", "party2", "party3", "party4" }

local LSM = LibStub("LibSharedMedia-3.0", true)

local function GetFont(s)
    if not s then return "Fonts\\FRIZQT__.TTF", 10 end
    local fontName = s.font or "Gravity"
    local size = s.fontSize or 10
    local path = "Fonts\\FRIZQT__.TTF"
    if LSM then path = LSM:Fetch("font", fontName) or path end
    return path, size
end

local function CreateIconBadge(parent, spellID, trackerType)
    local s = GetSettings(trackerType)
    local iconSize = (s and s.iconSize) or 28

    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(iconSize, iconSize)

    -- Spell icon
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local tex = C_Spell.GetSpellTexture(spellID)
    f.icon:SetTexture(tex)

    -- Cooldown overlay (desaturated when on CD)
    f.overlay = f:CreateTexture(nil, "OVERLAY")
    f.overlay:SetAllPoints()
    f.overlay:SetColorTexture(0, 0, 0, 0.55)
    f.overlay:Hide()

    -- Timer text
    f.timer = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local font, size = GetFont(s)
    f.timer:SetFont(font, size, "OUTLINE")
    f.timer:SetPoint("CENTER", 0, 0)
    f.timer:SetText("")

    -- Black border
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    f:SetBackdropColor(0, 0, 0, 0)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    f.spellID = spellID
    f.trackerType = trackerType
    f.expiration = 0
    f.duration = 0

    return f
end

-- Lays out the icon badges for a unit next to its party frame.
-- anchorSide  = which side of the frame icons are attached to (LEFT/RIGHT/TOP/BOTTOM)
-- growDirection = which direction subsequent icons extend (LEFT/RIGHT/UP/DOWN)
local function LayoutIconsForUnit(unit, trackerType)
    local s = GetSettings(trackerType)
    if not s or not s.enabled then return end

    local unitIcons = iconState[unit]
    if not unitIcons then return end

    local partyFrame = GetPartyUnitFrame(unit)
    if not partyFrame then
        for _, info in pairs(unitIcons) do
            if info.trackerType == trackerType and info.frame then
                info.frame:Hide()
            end
        end
        return
    end

    local iconSize   = s.iconSize or 28
    local spacing    = s.iconSpacing or 2
    local side       = s.anchorSide or "LEFT"
    local growDir    = s.growDirection or "DOWN"
    local maxIcons   = s.maxIcons or 0       -- 0 = unlimited
    local oX         = s.offsetX or 0
    local oY         = s.offsetY or 0
    local step       = iconSize + spacing

    -- ── Step vector: direction each subsequent icon moves ──
    local stepX, stepY = 0, 0
    if     growDir == "DOWN"  then stepY = -step
    elseif growDir == "UP"    then stepY =  step
    elseif growDir == "LEFT"  then stepX = -step
    elseif growDir == "RIGHT" then stepX =  step
    end

    -- ── Base anchor of the FIRST icon relative to partyFrame ──
    -- point = corner of the ICON, relPoint = corner of the FRAME
    local point, relPoint, baseX, baseY
    if side == "LEFT" then
        point    = "TOPRIGHT"
        relPoint = "TOPLEFT"
        baseX    = oX - 2
        baseY    = oY
    elseif side == "RIGHT" then
        point    = "TOPLEFT"
        relPoint = "TOPRIGHT"
        baseX    = oX + 2
        baseY    = oY
    elseif side == "TOP" then
        point    = "BOTTOMLEFT"
        relPoint = "TOPLEFT"
        baseX    = oX
        baseY    = oY + 2
    elseif side == "BOTTOM" then
        point    = "TOPLEFT"
        relPoint = "BOTTOMLEFT"
        baseX    = oX
        baseY    = oY - 2
    end

    -- ── Collect & sort icons for this trackerType ──
    local ordered = {}
    for _, info in pairs(unitIcons) do
        if info.trackerType == trackerType and info.frame then
            table.insert(ordered, info)
        end
    end
    table.sort(ordered, function(a, b)
        local aExp = a.expiration or 0
        local bExp = b.expiration or 0
        if aExp == 0 and bExp ~= 0 then return false end
        if bExp == 0 and aExp ~= 0 then return true  end
        return aExp < bExp
    end)

    -- ── Position icons ──
    local shown = 0
    local showOnlyOnCD = s.showOnlyOnCooldown

    for idx, info in ipairs(ordered) do
        local f = info.frame
        if not f then break end

        local onCD = (info.expiration or 0) > GetTime()

        if showOnlyOnCD and not onCD then
            f:Hide()
        elseif maxIcons > 0 and shown >= maxIcons then
            f:Hide()  -- over the limit
        else
            f:Show()
            f:SetParent(partyFrame)
            f:SetSize(iconSize, iconSize)
            f:ClearAllPoints()
            f:SetPoint(
                point, partyFrame, relPoint,
                baseX + stepX * shown,
                baseY + stepY * shown
            )
            shown = shown + 1
        end
    end
end

-- ============================================================================
-- COOLDOWN LOGIC
-- ============================================================================

local function EnsureIconForUnit(unit, spellID, class, trackerType)
    if not iconState[unit] then iconState[unit] = {} end
    -- Key includes trackerType prefix so Defensive and Offensive never collide
    local key = trackerType .. ":" .. spellID
    if not iconState[unit][key] then
        local icon = CreateIconBadge(UIParent, spellID, trackerType)
        iconState[unit][key] = {
            frame       = icon,
            expiration  = 0,
            duration    = 0,
            class       = class,
            trackerType = trackerType,
            spellID     = spellID,
        }
    end
    return iconState[unit][key]
end

local function StartCooldown(unit, guid, name, class, spellID, trackerType, isReady)
    local s = GetSettings(trackerType)
    if not s or not s.enabled then return end
    if not IsSpellEnabled(trackerType, spellID) then return end

    local baseCD = (trackerType == "DEFENSIVE") and DEFENSIVES[spellID] or OFFENSIVES[spellID]
    if not baseCD then return end

    local info = EnsureIconForUnit(unit, spellID, class, trackerType)
    local f = info.frame
    if not f then return end

    -- Store trackerType on state entry (for filtering in layout)
    info.trackerType = trackerType

    if isReady then
        info.expiration = 0
        info.duration   = 0
        f.overlay:Hide()
        f.icon:SetDesaturated(false)
        f.timer:SetText("")
    else
        local dur = baseCD
        info.expiration = GetTime() + dur
        info.duration   = dur
        f.overlay:Show()
        f.icon:SetDesaturated(true)
        f.timer:SetText(string.format("%d", dur))
    end

    LayoutIconsForUnit(unit, trackerType)
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================
local UPDATE_THROTTLE = 0.1
local timeSinceUpdate = 0

local updateFrame = CreateFrame("Frame", "GravityUI_CDTrackerUpdate", UIParent)
updateFrame:Hide()
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceUpdate = timeSinceUpdate + elapsed
    if timeSinceUpdate < UPDATE_THROTTLE then return end
    timeSinceUpdate = 0

    local now = GetTime()
    local anyActive = false

    for _, unit in ipairs(UNITS) do
        if iconState[unit] then
            for spellID, info in pairs(iconState[unit]) do
                local f = info.frame
                if f and f:IsShown() then
                    anyActive = true
                    local exp = info.expiration or 0
                    if exp > 0 then
                        if now >= exp then
                            -- Expired → Ready
                            info.expiration = 0
                            info.duration   = 0
                            f.overlay:Hide()
                            f.icon:SetDesaturated(false)
                            f.timer:SetText("")
                            -- Re-layout to potentially hide if showOnlyOnCooldown
                            LayoutIconsForUnit(unit, info.frame.trackerType)
                        else
                            local remaining = exp - now
                            local rem10 = math.ceil(remaining * 10)
                            if info.lastRem ~= rem10 then
                                info.lastRem = rem10
                                if remaining >= 60 then
                                    f.timer:SetText(string.format("%dm", math.floor(remaining / 60)))
                                else
                                    f.timer:SetText(string.format("%d", math.ceil(remaining)))
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not anyActive then
        self:Hide()
    end
end)

-- ============================================================================
-- SPEC DETECTION
-- ============================================================================
local function ShouldShowSpellForUnit(unit, spellID)
    local specFilter = SPELL_SPEC[spellID]
    if not specFilter or specFilter == 0 then return true end

    local guid = UnitGUID(unit)
    local unitSpec = (guid and activeSpecs[guid]) or (unit == "player" and (function()
        local idx = GetSpecialization()
        return idx and GetSpecializationInfo(idx) or 0
    end)()) or 0

    -- If spec is unknown (0), show spec-gated spells only for the player itself
    -- For party members we haven't inspected yet, show all (optimistic default)
    if unitSpec == 0 then
        return unit == "player" and false or true
    end

    if type(specFilter) == "table" then
        for _, sid in ipairs(specFilter) do
            if sid == unitSpec then return true end
        end
        return false
    end

    return unitSpec == specFilter
end

-- ============================================================================
-- UNIT_SPELLCAST_SUCCEEDED
-- ============================================================================
local function OnSpellCast(unit, rawSpellID)
    if not IsInGroup() then return end
    if IsInRaid() then return end
    local _, instanceType = IsInInstance()
    if instanceType == "raid" then return end

    -- Launder the spellID to prevent 'table index is secret' taint
    -- (Vehicle/NPC spell IDs from UNIT_SPELLCAST_SUCCEEDED can be tainted)
    local ok, resolvedID = pcall(tonumber, rawSpellID)
    if not ok or not resolvedID then return end

    local guid = UnitGUID(unit)
    if not guid then return end

    -- Skip vehicle units — their casts are NPC/scenario casts, not player CDs
    local okGuid, guidStr = pcall(tostring, guid)
    if not okGuid or not guidStr then return end
    if guidStr:sub(1, 7) == "Vehicle" then return end

    -- Must be a real player
    if not UnitIsPlayer(unit) then return end

    local name = UnitName(unit)
    local _, class = UnitClass(unit)

    -- Check Defensive
    local defS = GetSettings("DEFENSIVE")
    if defS and defS.enabled then
        local okD, inDef = pcall(function() return DEFENSIVES[resolvedID] end)
        if okD and inDef then
            local classMatch = SPELL_CLASS[resolvedID]
            if classMatch == class and ShouldShowSpellForUnit(unit, resolvedID) then
                StartCooldown(unit, guid, name, class, resolvedID, "DEFENSIVE")
                updateFrame:Show()
            end
        end
    end

    -- Check Offensive
    local offS = GetSettings("OFFENSIVE")
    if offS and offS.enabled then
        local okO, inOff = pcall(function() return OFFENSIVES[resolvedID] end)
        if okO and inOff then
            local classMatch = SPELL_CLASS[resolvedID]
            if classMatch == class and ShouldShowSpellForUnit(unit, resolvedID) then
                StartCooldown(unit, guid, name, class, resolvedID, "OFFENSIVE")
                updateFrame:Show()
            end
        end
    end
end

-- Party watchers (same pattern as interrupt tracker)
local playerWatcherCD = CreateFrame("Frame")
local partyWatchersCD = {}
for i = 1, 4 do partyWatchersCD[i] = CreateFrame("Frame") end

local function RegisterCDWatchers()
    playerWatcherCD:UnregisterAllEvents()
    playerWatcherCD:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    playerWatcherCD:SetScript("OnEvent", function(_, _, unit, _, spellID)
        -- Always pass raw; OnSpellCast handles laundering
        OnSpellCast(unit, spellID)
    end)

    for i = 1, 4 do
        local unit = "party"..i
        partyWatchersCD[i]:UnregisterAllEvents()
        if UnitExists(unit) then
            partyWatchersCD[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
            local capturedIdx = i
            partyWatchersCD[i]:SetScript("OnEvent", function(_, _, eUnit, _, eSpellID)
                OnSpellCast("party"..capturedIdx, eSpellID)
            end)
        end
    end
end

-- ============================================================================
-- GROUP ROSTER UPDATE
-- ============================================================================
local function OnGroupRosterUpdate()
    local inGroup = IsInGroup()
    local _, instanceType = IsInInstance()

    if not inGroup or instanceType == "raid" or IsInRaid() then
        -- Hide all icons
        for _, unit in ipairs(UNITS) do
            if iconState[unit] then
                for _, info in pairs(iconState[unit]) do
                    if info.frame then info.frame:Hide() end
                end
            end
        end
        return
    end

    RegisterCDWatchers()

    -- Ensure icons exist for all current party members
    local function HandleMember(unit)
        if not UnitExists(unit) then return end
        -- Skip NPC units (Follower Dungeons, vehicles, etc.)
        if unit ~= "player" and not UnitIsPlayer(unit) then return end

        local guid = UnitGUID(unit)
        if not guid then return end
        -- Extra safety: skip Vehicle GUIDs
        local okG, guidStr = pcall(tostring, guid)
        if not okG or not guidStr or guidStr:sub(1, 7) == "Vehicle" then return end

        local _, class = UnitClass(unit)
        if not class then return end
        local name = UnitName(unit)

        for _, data in ipairs(CD_CONFIG) do
            if data.class == class then
                -- Defensive
                local defS = GetSettings("DEFENSIVE")
                if defS and defS.enabled and data.cat == "DEFENSIVE" then
                    if IsSpellEnabled("DEFENSIVE", data.spellID) and ShouldShowSpellForUnit(unit, data.spellID) then
                        EnsureIconForUnit(unit, data.spellID, class, "DEFENSIVE")
                        local key = "DEFENSIVE:" .. data.spellID
                        local info = iconState[unit] and iconState[unit][key]
                        if info and (info.expiration or 0) == 0 then
                            StartCooldown(unit, guid, name, class, data.spellID, "DEFENSIVE", true)
                        end
                    end
                end

                -- Offensive
                local offS = GetSettings("OFFENSIVE")
                if offS and offS.enabled and data.cat == "OFFENSIVE" then
                    if IsSpellEnabled("OFFENSIVE", data.spellID) and ShouldShowSpellForUnit(unit, data.spellID) then
                        EnsureIconForUnit(unit, data.spellID, class, "OFFENSIVE")
                        local key = "OFFENSIVE:" .. data.spellID
                        local info = iconState[unit] and iconState[unit][key]
                        if info and (info.expiration or 0) == 0 then
                            StartCooldown(unit, guid, name, class, data.spellID, "OFFENSIVE", true)
                        end
                    end
                end
            end
        end

        LayoutIconsForUnit(unit, "DEFENSIVE")
        LayoutIconsForUnit(unit, "OFFENSIVE")
        updateFrame:Show()
    end

    HandleMember("player")
    for i = 1, 4 do HandleMember("party"..i) end

    -- Hide icons for units no longer in group or no longer players
    for _, unit in ipairs(UNITS) do
        local shouldHide = not UnitExists(unit)
                        or (unit ~= "player" and not UnitIsPlayer(unit))
        if shouldHide and iconState[unit] then
            for _, info in pairs(iconState[unit]) do
                if info.frame then info.frame:Hide() end
            end
        end
    end
end

-- ============================================================================
-- INSPECT for spec-specific CDs
-- ============================================================================
-- NOTE: INSPECT_READY is registered in ApplySettings/Initialize (not here at module
-- load) to avoid duplicates when settings are reapplied.

-- ============================================================================
-- EXPOSE DATA FOR SETTINGS PANEL
-- ============================================================================
CDTracker.CD_CONFIG   = CD_CONFIG
CDTracker.DEFENSIVES  = DEFENSIVES
CDTracker.OFFENSIVES  = OFFENSIVES

-- ============================================================================
-- TEST MODE
-- ============================================================================
local testModeActive = false

local function ToggleTestMode()
    local _, class = UnitClass("player")
    local guid = UnitGUID("player")

    if testModeActive then
        -- Clear all test icons
        if iconState["player"] then
            for _, info in pairs(iconState["player"]) do
                if info.frame then info.frame:Hide() end
            end
            iconState["player"] = {}
        end
        testModeActive = false
        ns.Print("CD Tracker Test Mode: OFF")
        updateFrame:Hide()
        return
    end

    testModeActive = true
    ns.Print("CD Tracker Test Mode: ON — Icons werden am Player Frame angezeigt.")

    -- Find some defensive and offensive spells for testing (use generic ones if class not in DB)
    local testDef = {
        { spellID = 48792, cd = 120, cat = "DEFENSIVE" }, -- Icebound Fortitude (DK — any)
        { spellID = 642,   cd = 300, cat = "DEFENSIVE" }, -- Divine Shield
        { spellID = 22812, cd = 60,  cat = "DEFENSIVE" }, -- Barkskin
    }
    local testOff = {
        { spellID = 107574, cd = 90,  cat = "OFFENSIVE" }, -- Avatar
        { spellID = 31884,  cd = 120, cat = "OFFENSIVE" }, -- Avenging Wrath
    }

    -- Force enable temporarily
    local defS = GetSettings("DEFENSIVE")
    local offS = GetSettings("OFFENSIVE")
    local defWasEnabled = defS and defS.enabled
    local offWasEnabled = offS and offS.enabled
    if defS then defS.enabled = true end
    if offS then offS.enabled = true end

    -- Inject test icons on player using the correct trackerType:spellID key format
    if defS and defS.enabled then
        for i, data in ipairs(testDef) do
            if not iconState["player"] then iconState["player"] = {} end
            local icon = CreateIconBadge(UIParent, data.spellID, "DEFENSIVE")
            local onCD = (i % 2 == 0)
            local key = "DEFENSIVE:" .. data.spellID
            iconState["player"][key] = {
                frame       = icon,
                expiration  = onCD and (GetTime() + data.cd * 0.4) or 0,
                duration    = data.cd,
                class       = class,
                trackerType = "DEFENSIVE",
                spellID     = data.spellID,
            }
            if onCD then
                icon.overlay:Show()
                icon.icon:SetDesaturated(true)
                icon.timer:SetText(string.format("%d", math.floor(data.cd * 0.4)))
            end
        end
    end
    if offS and offS.enabled then
        for i, data in ipairs(testOff) do
            if not iconState["player"] then iconState["player"] = {} end
            local icon = CreateIconBadge(UIParent, data.spellID, "OFFENSIVE")
            local onCD = (i == 1)
            local key = "OFFENSIVE:" .. data.spellID
            iconState["player"][key] = {
                frame       = icon,
                expiration  = onCD and (GetTime() + data.cd * 0.6) or 0,
                duration    = data.cd,
                class       = class,
                trackerType = "OFFENSIVE",
                spellID     = data.spellID,
            }
            if onCD then
                icon.overlay:Show()
                icon.icon:SetDesaturated(true)
                icon.timer:SetText(string.format("%d", math.floor(data.cd * 0.6)))
            end
        end
    end

    LayoutIconsForUnit("player", "DEFENSIVE")
    LayoutIconsForUnit("player", "OFFENSIVE")
    updateFrame:Show()
end

-- ============================================================================
-- DEBUG COMMAND
-- ============================================================================
SLASH_GRAVITYDEBUGCD1 = "/gravitydebugcd"
SlashCmdList["GRAVITYDEBUGCD"] = function()
    print("GravityUI CD Tracker State:")
    local total = 0
    for _, unit in ipairs(UNITS) do
        if iconState[unit] then
            for key, info in pairs(iconState[unit]) do
                total = total + 1
                local exp = info.expiration or 0
                local status = (exp > GetTime()) and string.format("%.1fs", exp - GetTime()) or "READY"
                if info.frame then
                    print(string.format("  [%s] %s  Status=%s  Shown=%s",
                        unit, tostring(key), status, tostring(info.frame:IsShown())))
                end
            end
        end
    end
    print("Total icons tracked:", total)
end

SLASH_GRAVITYTESTCD1 = "/gravitytestcd"
SlashCmdList["GRAVITYTESTCD"] = function()
    ToggleTestMode()
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================
function CDTracker.Initialize()
    local defS = GetSettings("DEFENSIVE")
    local offS = GetSettings("OFFENSIVE")
    if (not defS or not defS.enabled) and (not offS or not offS.enabled) then return end

    CDTracker:RegisterEvent("GROUP_ROSTER_UPDATE", OnGroupRosterUpdate)
    CDTracker:RegisterEvent("PLAYER_ENTERING_WORLD", OnGroupRosterUpdate)
    CDTracker:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", OnGroupRosterUpdate)

    RegisterCDWatchers()
    OnGroupRosterUpdate()
    updateFrame:Show()
end

function CDTracker.ApplySettings()
    CDTracker:UnregisterAllEvents()
    playerWatcherCD:UnregisterAllEvents()
    for i = 1, 4 do partyWatchersCD[i]:UnregisterAllEvents() end

    -- Re-hide all icons, rebuild from scratch
    for _, unit in ipairs(UNITS) do
        if iconState[unit] then
            for _, info in pairs(iconState[unit]) do
                if info.frame then info.frame:Hide() end
            end
            iconState[unit] = {}
        end
    end

    CDTracker:RegisterEvent("INSPECT_READY", function(_, guid)
        -- re-register the same closure
        if not guid then return end
        local unit = nil
        if UnitGUID("player") == guid then unit = "player" end
        if not unit then
            for i = 1, 4 do
                if UnitGUID("party"..i) == guid then unit = "party"..i break end
            end
        end
        if not unit then return end
        local specID = GetInspectSpecialization(unit)
        if specID and specID > 0 then
            activeSpecs[guid] = specID
            OnGroupRosterUpdate()
        end
    end)

    local defS = GetSettings("DEFENSIVE")
    local offS = GetSettings("OFFENSIVE")
    if (defS and defS.enabled) or (offS and offS.enabled) then
        CDTracker:RegisterEvent("GROUP_ROSTER_UPDATE", OnGroupRosterUpdate)
        CDTracker:RegisterEvent("PLAYER_ENTERING_WORLD", OnGroupRosterUpdate)
        CDTracker:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", OnGroupRosterUpdate)
        RegisterCDWatchers()
        OnGroupRosterUpdate()
        updateFrame:Show()
    else
        updateFrame:Hide()
    end
end

