local ADDON_NAME, ns = ...
local CooldownText = {}
ns.CooldownText = CooldownText

local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local IsInInstance = IsInInstance
local strformat = string.format
local mathfloor = math.floor

local DB
local trackedList = {}
local ticker
local mainContainer
local isMoverShown = false
local moverFrame
local cachedIsInDungeonOrRaid = false

-------------------------------------------------------------------------------
--  MOVEMENT ABILITIES (class -> specID -> {spellIDs})
-------------------------------------------------------------------------------
local MOVEMENT_ABILITIES = {
    DEATHKNIGHT = {[250] = {48265, 212552}, [251] = {48265, 212552}, [252] = {48265, 444010, 444347, 212552}},
    DEMONHUNTER = {[577] = {195072}, [581] = {189110}, [1480] = {1234796}},
    DRUID       = {[102] = {102401, 252216, 1850}, [103] = {102401, 252216, 1850}, [104] = {102401, 252216, 106898, 1850}, [105] = {102401, 252216, 1850}},
    EVOKER      = {[1467] = {358267}, [1468] = {358267}, [1473] = {358267}},
    HUNTER      = {[253] = {186257, 781}, [254] = {186257, 781}, [255] = {186257, 781}},
    MAGE        = {[62] = {212653, 1953}, [63] = {212653, 1953}, [64] = {212653, 1953}},
    MONK        = {[268] = {115008, 109132, 119085, 361138}, [269] = {109132, 119085, 361138, 101545}, [270] = {109132, 119085, 361138}},
    PALADIN     = {[65] = {190784}, [66] = {190784}, [70] = {190784}},
    PRIEST      = {[256] = {121536, 73325}, [257] = {121536, 73325}, [258] = {121536, 73325}},
    ROGUE       = {[259] = {36554, 2983}, [260] = {195457, 2983}, [261] = {36554, 2983}},
    SHAMAN      = {[262] = {79206, 192063, 58875}, [263] = {192063, 58875}, [264] = {79206, 192063, 58875}},
    WARLOCK     = {[265] = {48020, 111400}, [266] = {48020, 111400}, [267] = {48020, 111400}},
    WARRIOR     = {[71] = {6544}, [72] = {6544}, [73] = {6544}},
}

-- Spells that default to DISABLED (user must opt-in)
local MOVEMENT_DEFAULT_OFF = {
    [2983]   = true,  -- Sprint
    [73325]  = true,  -- Leap of Faith
    [106898] = true,  -- Stampeding Roar
    [1850]   = true,  -- Dash
    [252216] = true,  -- Tiger Dash
    [212552] = true,  -- Wraith Walk
    [79206]  = true,  -- Spiritwalker's Grace
    [58875]  = true,  -- Spirit Walk
    [111400] = true,  -- Burning Rush
}

-- Flat preset list for the options checkbox grid
local MOVEMENT_PRESETS = {
    { class = "DEATHKNIGHT", ids = {48265} },      -- Death's Advance
    { class = "DEATHKNIGHT", ids = {212552} },     -- Wraith Walk
    { class = "DEATHKNIGHT", ids = {444347, 444010} }, -- Death Charge
    { class = "DEMONHUNTER", ids = {195072} },     -- Fel Rush
    { class = "DEMONHUNTER", ids = {189110} },     -- Infernal Strike
    { class = "DEMONHUNTER", ids = {1234796} },    -- Hero spec move
    { class = "DRUID",       ids = {102401} },     -- Wild Charge
    { class = "DRUID",       ids = {1850} },       -- Dash
    { class = "DRUID",       ids = {252216} },     -- Tiger Dash
    { class = "DRUID",       ids = {106898} },     -- Stampeding Roar
    { class = "EVOKER",      ids = {358267} },     -- Hover
    { class = "HUNTER",      ids = {186257} },     -- Aspect of the Cheetah
    { class = "HUNTER",      ids = {781} },        -- Disengage
    { class = "MAGE",        ids = {212653, 1953} }, -- Shimmer / Blink
    { class = "MONK",        ids = {109132, 115008} }, -- Roll / Chi Torpedo
    { class = "MONK",        ids = {119085} },     -- Chi Burst / Tiger's Lust
    { class = "MONK",        ids = {361138} },     -- Flying Serpent Kick (talent)
    { class = "MONK",        ids = {101545} },     -- Flying Serpent Kick
    { class = "PALADIN",     ids = {190784} },     -- Divine Steed
    { class = "PRIEST",      ids = {121536} },     -- Angelic Feather
    { class = "PRIEST",      ids = {73325} },      -- Leap of Faith
    { class = "ROGUE",       ids = {36554} },      -- Shadowstep
    { class = "ROGUE",       ids = {195457} },     -- Grappling Hook
    { class = "ROGUE",       ids = {2983} },       -- Sprint
    { class = "SHAMAN",      ids = {79206} },      -- Spiritwalker's Grace
    { class = "SHAMAN",      ids = {192063} },     -- Gust of Wind
    { class = "SHAMAN",      ids = {58875} },      -- Spirit Walk
    { class = "WARLOCK",     ids = {48020} },      -- Demonic Circle: Teleport
    { class = "WARLOCK",     ids = {111400} },     -- Burning Rush
    { class = "WARRIOR",     ids = {6544} },       -- Heroic Leap
}

-- All preset IDs for identifying custom spells
local PRESET_IDS = {}
for _, entry in ipairs(MOVEMENT_PRESETS) do
    for _, id in ipairs(entry.ids) do PRESET_IDS[id] = true end
end

-------------------------------------------------------------------------------
--  DB / SETTINGS
-------------------------------------------------------------------------------
local DEFAULT_SETTINGS = {
    enabled = true,
    x = 0, y = 18,
    fontSize = 20,
    spacing = 4,
    tickInterval = 0.2,
    growDirection = "DOWN",
    onlyRaidDungeon = false,
    useClassColor = true,
    textColor = {1, 1, 1, 1},
    -- Display mode: "text", "icon", "bar"
    displayMode = "text",
    iconSize = 40,
    barWidth = 200,
    barHeight = 20,
    -- Sound alert
    soundEnabled = false,
    soundKey = "none",
    -- Time Spiral
    timeSpiralEnabled = false,
    timeSpiralText = "FREE MOVEMENT",
    timeSpiralDuration = 3,
    timeSpiralColorR = 0.2, timeSpiralColorG = 1.0, timeSpiralColorB = 0.0,
    timeSpiralSoundEnabled = false,
    timeSpiralSoundKey = "none",
    -- Spell overrides (preset enable/disable)
    spellOverrides = {},
    -- Legacy custom spells (backward compat)
    spellsToTrack = {},
}

local function GetSettings()
    if DB then return DB end
    local mainDB = ns.GetDB and ns.GetDB()
    if mainDB then
        if type(mainDB.cooldownText) ~= "table" then
            mainDB.cooldownText = {}
        end
        -- Apply defaults for missing keys
        for k, v in pairs(DEFAULT_SETTINGS) do
            if mainDB.cooldownText[k] == nil then
                if type(v) == "table" then
                    mainDB.cooldownText[k] = {}
                    for kk, vv in pairs(v) do mainDB.cooldownText[k][kk] = vv end
                else
                    mainDB.cooldownText[k] = v
                end
            end
        end
        DB = mainDB.cooldownText
        return DB
    end
    if not ns.cooldownTextFallback then
        ns.cooldownTextFallback = {}
        for k, v in pairs(DEFAULT_SETTINGS) do
            if type(v) == "table" then
                ns.cooldownTextFallback[k] = {}
                for kk, vv in pairs(v) do ns.cooldownTextFallback[k][kk] = vv end
            else
                ns.cooldownTextFallback[k] = v
            end
        end
    end
    DB = ns.cooldownTextFallback
    return DB
end

-------------------------------------------------------------------------------
--  UTILITIES
-------------------------------------------------------------------------------
local function GetFontPath()
    if ns.Styling and type(ns.Styling.GetFontPath) == "function" then
        return ns.Styling:GetFontPath()
    end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local db = ns.GetDB and ns.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    if LSM then return LSM:Fetch("font", fontName) end
    return "Fonts\\FRIZQT__.TTF"
end

local function GetBarTexturePath()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then return LSM:Fetch("statusbar", "Gravity v3") end
    return "Interface\\TargetingFrame\\UI-StatusBar"
end

local function UpdateInstanceCache()
    local _, instanceType = IsInInstance()
    cachedIsInDungeonOrRaid = instanceType == "party" or instanceType == "raid"
end

local function GetSpellNameSafe(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    return info and info.name or ("Spell#" .. spellID)
end

local function GetSpellIcon(spellID)
    return C_Spell.GetSpellTexture(spellID) or 134400 -- question mark icon
end

local function SpellIsEnabled(spellID)
    if not DB then return false end
    local ov = DB.spellOverrides and DB.spellOverrides[spellID]
    if ov ~= nil then
        if type(ov) == "table" then return ov.enabled ~= false end
        return ov ~= false
    end
    -- No override: enabled unless in DEFAULT_OFF
    return not MOVEMENT_DEFAULT_OFF[spellID]
end

local function GetTextColor()
    if not DB then return 1, 1, 1, 1 end
    if DB.useClassColor ~= false then
        local _, playerClass = UnitClass("player")
        local color = playerClass and ((CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[playerClass])
        if color then return color.r, color.g, color.b, 1 end
    elseif DB.textColor then
        return DB.textColor[1] or 1, DB.textColor[2] or 1, DB.textColor[3] or 1, DB.textColor[4] or 1
    end
    return 1, 1, 1, 1
end

local function PlayAlertSound()
    if not DB or not DB.soundEnabled or DB.soundKey == "none" then return end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local path = LSM:Fetch("sound", DB.soundKey)
        if path then PlaySoundFile(path, "Master") end
    end
end

-------------------------------------------------------------------------------
--  BUILD TRACKED LIST
-------------------------------------------------------------------------------
local function BuildTrackedList()
    trackedList = {}
    if not DB then return end

    local _, playerClass = UnitClass("player")
    local specIndex = GetSpecialization and GetSpecialization()
    local specID = specIndex and select(1, GetSpecializationInfo(specIndex)) or 0

    -- 1. Preset movement abilities for current class/spec
    local classData = MOVEMENT_ABILITIES[playerClass]
    if classData then
        local specSpells = classData[specID]
        if specSpells then
            local seen = {}
            for _, spellID in ipairs(specSpells) do
                if SpellIsEnabled(spellID) and not seen[spellID] then
                    if C_Spell.GetSpellInfo(spellID) then
                        seen[spellID] = true
                        table.insert(trackedList, {
                            spellID = spellID,
                            class = playerClass,
                            name = GetSpellNameSafe(spellID),
                            icon = GetSpellIcon(spellID),
                            isPreset = true,
                            wasOnCooldown = false,
                            prevRemaining = 0,
                        })
                    end
                end
            end
        end
    end

    -- 2. Legacy custom spells (backward compat)
    if DB.spellsToTrack then
        for _, spellObj in ipairs(DB.spellsToTrack) do
            if spellObj.class == playerClass and not PRESET_IDS[spellObj.spellID] then
                if C_Spell.GetSpellInfo(spellObj.spellID) then
                    table.insert(trackedList, {
                        spellID = spellObj.spellID,
                        class = playerClass,
                        name = (spellObj.text and spellObj.text ~= "") and spellObj.text or GetSpellNameSafe(spellObj.spellID),
                        icon = GetSpellIcon(spellObj.spellID),
                        isPreset = false,
                        wasOnCooldown = false,
                        prevRemaining = 0,
                    })
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
--  FRAME POOLS
-------------------------------------------------------------------------------
-- Text mode: FontString pool (existing pattern)
-- Icon mode: Frame pool with icon texture + cooldown swipe + text
-- Bar mode: Frame pool with StatusBar + icon + text

local textPool = {}
local iconPool = {}
local barPool = {}

local function EnsureTextEntry(index)
    if textPool[index] then return textPool[index] end
    local fs = mainContainer:CreateFontString(nil, "OVERLAY")
    fs:SetJustifyH("CENTER")
    textPool[index] = fs
    return fs
end

local function EnsureIconEntry(index)
    if iconPool[index] then return iconPool[index] end

    local f = CreateFrame("Frame", nil, mainContainer)
    f:SetSize(40, 40)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon

    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(false)
    cd:SetHideCountdownNumbers(true)
    if cd.SetDrawBling then cd:SetDrawBling(false) end
    f.cd = cd

    local text = f:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    f.text = text

    local border = f:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 0.8)
    border:SetDrawLayer("OVERLAY", -1)
    f.border = border

    iconPool[index] = f
    return f
end

local function EnsureBarEntry(index)
    if barPool[index] then return barPool[index] end

    local f = CreateFrame("Frame", nil, mainContainer, "BackdropTemplate")
    f:SetSize(200, 20)
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetStatusBarTexture(GetBarTexturePath())
    f.bar = bar

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(f:GetHeight(), f:GetHeight())
    icon:SetPoint("RIGHT", f, "LEFT", -2, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon

    local iconBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    iconBorder:SetBackdropBorderColor(0, 0, 0, 1)
    f.iconBorder = iconBorder

    local name = bar:CreateFontString(nil, "OVERLAY")
    name:SetPoint("LEFT", bar, "LEFT", 4, 0)
    name:SetJustifyH("LEFT")
    f.name = name

    local time = bar:CreateFontString(nil, "OVERLAY")
    time:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    time:SetJustifyH("RIGHT")
    f.time = time

    barPool[index] = f
    return f
end

local function HideAllPools()
    for _, fs in ipairs(textPool) do fs:SetText(""); fs:SetAlpha(0) end
    for _, f in ipairs(iconPool) do f:Hide() end
    for _, f in ipairs(barPool) do f:Hide() end
end

-------------------------------------------------------------------------------
--  REFRESH LAYOUT
-------------------------------------------------------------------------------
function CooldownText:Refresh()
    if not mainContainer or not DB then return end

    mainContainer:ClearAllPoints()
    mainContainer:SetPoint("CENTER", UIParent, "CENTER", DB.x or 0, DB.y or 18)

    local fontPath = GetFontPath()
    local r, g, b, a = GetTextColor()
    local mode = DB.displayMode or "text"
    local growDir = DB.growDirection or "DOWN"
    local anchorPoint = (growDir == "DOWN") and "TOP" or "BOTTOM"
    local modifier = (growDir == "DOWN") and -1 or 1

    HideAllPools()

    for i, entry in ipairs(trackedList) do
        if mode == "text" then
            local fs = EnsureTextEntry(i)
            fs:SetFont(fontPath, DB.fontSize or 20, "OUTLINE")
            fs:SetTextColor(r, g, b, a)
            fs:ClearAllPoints()
            local yOff = (i - 1) * ((DB.fontSize or 20) + (DB.spacing or 4))
            fs:SetPoint(anchorPoint, mainContainer, anchorPoint, 0, yOff * modifier)
            fs:SetText("")
            fs:SetAlpha(1)

        elseif mode == "icon" then
            local f = EnsureIconEntry(i)
            local sz = DB.iconSize or 40
            f:SetSize(sz, sz)
            f.icon:SetTexture(entry.icon)
            f.text:SetFont(fontPath, math.max(10, sz * 0.35), "OUTLINE")
            f.text:SetTextColor(1, 1, 1, 1)
            f:ClearAllPoints()
            local yOff = (i - 1) * (sz + (DB.spacing or 4))
            f:SetPoint(anchorPoint, mainContainer, anchorPoint, 0, yOff * modifier)
            f:Show()

        elseif mode == "bar" then
            local f = EnsureBarEntry(i)
            local bw = DB.barWidth or 200
            local bh = DB.barHeight or 20
            f:SetSize(bw, bh)
            f.icon:SetSize(bh, bh)
            f.icon:SetTexture(entry.icon)
            f.bar:SetStatusBarTexture(GetBarTexturePath())
            f.bar:SetStatusBarColor(r, g, b, 1)
            f.name:SetFont(fontPath, math.max(9, bh * 0.6), "OUTLINE")
            f.name:SetText(entry.name)
            f.name:SetTextColor(1, 1, 1, 1)
            f.time:SetFont(fontPath, math.max(9, bh * 0.6), "OUTLINE")
            f.time:SetTextColor(1, 1, 1, 1)
            f:ClearAllPoints()
            local yOff = (i - 1) * (bh + (DB.spacing or 4))
            f:SetPoint(anchorPoint .. "LEFT", mainContainer, anchorPoint .. "LEFT", 0, yOff * modifier)
            f:Show()
        end
    end

    if not DB.enabled and not isMoverShown then
        mainContainer:Hide()
        return
    end
    mainContainer:Show()
    self:StartTicker()
end

-------------------------------------------------------------------------------
--  UPDATE COOLDOWNS
-------------------------------------------------------------------------------
function CooldownText:UpdateCooldowns()
    if not mainContainer or not DB or not DB.enabled then return end

    local shouldHideAll = DB.onlyRaidDungeon and not cachedIsInDungeonOrRaid
    local mode = DB.displayMode or "text"

    for i, entry in ipairs(trackedList) do
        local durationObject = GetSpellCooldownDuration(entry.spellID)
        local remaining = durationObject and durationObject:GetRemainingDuration(1) or 0
        local cdInfo = C_Spell.GetSpellCooldown(entry.spellID)
        local isOnGCD = cdInfo and cdInfo.isOnGCD ~= false

        -- Sound alert: detect cooldown → ready transition
        local isOnCD = (remaining > 0.5) and not isOnGCD
        if entry.wasOnCooldown and not isOnCD and DB.soundEnabled then
            PlayAlertSound()
        end
        entry.wasOnCooldown = isOnCD

        if shouldHideAll then
            if mode == "text" then
                local fs = textPool[i]
                if fs then fs:SetAlpha(0) end
            elseif mode == "icon" then
                local f = iconPool[i]
                if f then f:SetAlpha(0) end
            elseif mode == "bar" then
                local f = barPool[i]
                if f then f:SetAlpha(0) end
            end
        else
            if mode == "text" then
                local fs = textPool[i]
                if fs then
                    fs:SetText(strformat("%s: %.1f", entry.name, remaining))
                    -- Use SetAlphaFromBoolean for Midnight-safe secret value handling
                    local state = cdInfo and cdInfo.isOnGCD ~= false
                    if fs.SetAlphaFromBoolean then
                        fs:SetAlphaFromBoolean(state, 0, 1)
                    else
                        fs:SetAlpha(isOnGCD and 0 or 1)
                    end
                end

            elseif mode == "icon" then
                local f = iconPool[i]
                if f then
                    if isOnCD then
                        if durationObject and f.cd.SetCooldownFromDurationObject then
                            f.cd:SetCooldownFromDurationObject(durationObject, false)
                        end
                        f.text:SetText(remaining >= 10 and mathfloor(remaining) or strformat("%.1f", remaining))
                        f:SetAlpha(1)
                    else
                        f.cd:Clear()
                        f.text:SetText("")
                        -- Hide when ready (no cooldown to show)
                        if isOnGCD then f:SetAlpha(0) else f:SetAlpha(0.3) end
                    end
                end

            elseif mode == "bar" then
                local f = barPool[i]
                if f then
                    if isOnCD then
                        local baseCDms = GetSpellBaseCooldown and GetSpellBaseCooldown(entry.spellID) or 0
                        local baseCD = baseCDms / 1000
                        if baseCD > 0 then
                            f.bar:SetValue(1 - (remaining / baseCD))
                        else
                            f.bar:SetValue(0)
                        end
                        f.time:SetText(remaining >= 10 and mathfloor(remaining) or strformat("%.1f", remaining))
                        f:SetAlpha(1)
                    else
                        f.bar:SetValue(1)
                        f.time:SetText("Ready")
                        if isOnGCD then f:SetAlpha(0) else f:SetAlpha(0.4) end
                    end
                end
            end
        end
    end
end

function CooldownText:StartTicker()
    if not DB then return end
    if ticker then ticker:Cancel() end
    local interval = DB.tickInterval or 0.2
    ticker = C_Timer.NewTicker(interval, function() self:UpdateCooldowns() end)
end

-------------------------------------------------------------------------------
--  TIME SPIRAL (Flash alert on proc-reset)
-------------------------------------------------------------------------------
local timeSpiralFrame, timeSpiralText, timeSpiralFadeAnim

local function CreateTimeSpiralFrame()
    if timeSpiralFrame then return end

    timeSpiralFrame = CreateFrame("Frame", "GravityUI_TimeSpiralFrame", UIParent)
    timeSpiralFrame:SetSize(400, 60)
    timeSpiralFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    timeSpiralFrame:SetFrameStrata("HIGH")
    timeSpiralFrame:EnableMouse(false)
    timeSpiralFrame:Hide()

    timeSpiralText = timeSpiralFrame:CreateFontString(nil, "OVERLAY")
    timeSpiralText:SetPoint("CENTER")
    timeSpiralText:SetJustifyH("CENTER")

    -- Fade-out animation
    local ag = timeSpiralFrame:CreateAnimationGroup()
    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.3)
    fadeIn:SetOrder(1)

    local hold = ag:CreateAnimation("Alpha")
    hold:SetFromAlpha(1)
    hold:SetToAlpha(1)
    hold:SetDuration(2)
    hold:SetOrder(2)

    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.7)
    fadeOut:SetOrder(3)

    ag:SetScript("OnFinished", function() timeSpiralFrame:Hide() end)
    timeSpiralFrame.anim = ag
end

local function ShowTimeSpiralFlash()
    if not DB or not DB.timeSpiralEnabled then return end
    CreateTimeSpiralFrame()

    local fontPath = GetFontPath()
    timeSpiralText:SetFont(fontPath, 32, "OUTLINE")
    timeSpiralText:SetText(DB.timeSpiralText or "FREE MOVEMENT")
    timeSpiralText:SetTextColor(
        DB.timeSpiralColorR or 0.2,
        DB.timeSpiralColorG or 1.0,
        DB.timeSpiralColorB or 0.0,
        1
    )

    timeSpiralFrame:Show()
    timeSpiralFrame:SetAlpha(1)
    if timeSpiralFrame.anim:IsPlaying() then timeSpiralFrame.anim:Stop() end
    timeSpiralFrame.anim:Play()

    -- Sound
    if DB.timeSpiralSoundEnabled and DB.timeSpiralSoundKey ~= "none" then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then
            local path = LSM:Fetch("sound", DB.timeSpiralSoundKey)
            if path then PlaySoundFile(path, "Master") end
        end
    end
end

-- Detect proc-resets via overlay glow events
local timeSpiralEventFrame
local function SetupTimeSpiralEvents()
    if timeSpiralEventFrame then return end
    timeSpiralEventFrame = CreateFrame("Frame")
    timeSpiralEventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    timeSpiralEventFrame:SetScript("OnEvent", function(_, event, spellID)
        if not DB or not DB.timeSpiralEnabled then return end
        -- Check if the glowing spell is one of our tracked movement spells
        for _, entry in ipairs(trackedList) do
            if entry.spellID == spellID and entry.wasOnCooldown then
                ShowTimeSpiralFlash()
                return
            end
        end
    end)
end

-------------------------------------------------------------------------------
--  MOVER
-------------------------------------------------------------------------------
function CooldownText:CreateBaseFrames()
    if not DB then DB = GetSettings() end
    mainContainer = CreateFrame("Frame", "GravityUI_CooldownTextContainer", UIParent)
    mainContainer:SetSize(400, 50)
    mainContainer:SetPoint("CENTER", UIParent, "CENTER", (DB and DB.x) or 0, (DB and DB.y) or 18)
    mainContainer:SetFrameStrata("HIGH")
    mainContainer:EnableMouse(false)
    mainContainer:SetMovable(true)
    mainContainer:SetClampedToScreen(true)

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("CooldownText", mainContainer, function(frame, enabled, force) CooldownText:ToggleMover(force) end, "Cooldown Tracker")
    end

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self.eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self.eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            UpdateInstanceCache()
            C_Timer.After(0.5, function() self:Initialize() end)
        else
            C_Timer.After(0.5, function() self:Initialize() end)
        end
    end)
end

function CooldownText:ToggleMover(forceState)
    if not mainContainer then self:CreateBaseFrames() end
    if not DB then DB = GetSettings() end
    if not mainContainer or not DB then return end

    local shouldShow
    if forceState ~= nil then
        shouldShow = (forceState == true)
    else
        shouldShow = not (moverFrame and moverFrame:IsShown())
    end
    isMoverShown = shouldShow

    if not moverFrame then
        moverFrame = CreateFrame("Frame", nil, mainContainer, "BackdropTemplate")
        moverFrame:SetAllPoints(mainContainer)
        moverFrame:EnableMouse(true)
        moverFrame:RegisterForDrag("LeftButton")
        moverFrame:SetMovable(true)

        moverFrame:SetScript("OnDragStart", function() mainContainer:StartMoving() end)
        moverFrame:SetScript("OnDragStop", function()
            mainContainer:StopMovingOrSizing()
            local _, _, _, xOfs, yOfs = mainContainer:GetPoint()
            DB.x = mathfloor((xOfs or 0) + 0.5)
            DB.y = mathfloor((yOfs or 0) + 0.5)
        end)
        mainContainer:SetMovable(true)
    end

    if shouldShow then
        mainContainer:ClearAllPoints()
        mainContainer:SetPoint("CENTER", UIParent, "CENTER", DB.x or 0, DB.y or 18)
        mainContainer:Show()
        moverFrame:Show()
        moverFrame:EnableMouse(true)

        -- Show preview
        local mode = DB.displayMode or "text"
        HideAllPools()
        local r, g, b = GetTextColor()
        local fontPath = GetFontPath()

        if mode == "text" then
            local fs = EnsureTextEntry(1)
            fs:SetFont(fontPath, DB.fontSize or 20, "OUTLINE")
            fs:SetTextColor(r, g, b, 1)
            fs:ClearAllPoints()
            fs:SetPoint("TOP", mainContainer, "TOP", 0, 0)
            fs:SetText("Cooldown Preview: 3.5")
            fs:SetAlpha(1)
        elseif mode == "icon" then
            local f = EnsureIconEntry(1)
            local sz = DB.iconSize or 40
            f:SetSize(sz, sz)
            f.icon:SetTexture(134400) -- question mark
            f.text:SetFont(fontPath, math.max(10, sz * 0.35), "OUTLINE")
            f.text:SetText("3.5")
            f:ClearAllPoints()
            f:SetPoint("TOP", mainContainer, "TOP", 0, 0)
            f:Show()
        elseif mode == "bar" then
            local f = EnsureBarEntry(1)
            local bw = DB.barWidth or 200
            local bh = DB.barHeight or 20
            f:SetSize(bw, bh)
            f.icon:SetSize(bh, bh)
            f.icon:SetTexture(134400)
            f.bar:SetStatusBarTexture(GetBarTexturePath())
            f.bar:SetStatusBarColor(r, g, b, 1)
            f.bar:SetValue(0.65)
            f.name:SetFont(fontPath, math.max(9, bh * 0.6), "OUTLINE")
            f.name:SetText("Spell Preview")
            f.time:SetFont(fontPath, math.max(9, bh * 0.6), "OUTLINE")
            f.time:SetText("3.5")
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", mainContainer, "TOPLEFT", 0, 0)
            f:Show()
        end

        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(mainContainer, true, "CooldownText")
        end
    else
        isMoverShown = false
        moverFrame:Hide()
        moverFrame:EnableMouse(false)
        mainContainer:EnableMouse(false)
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(mainContainer, false, "CooldownText")
        end
        if not DB.enabled then
            HideAllPools()
            mainContainer:Hide()
        end
    end
end

-------------------------------------------------------------------------------
--  INITIALIZE
-------------------------------------------------------------------------------
function CooldownText:Initialize()
    DB = GetSettings()
    UpdateInstanceCache()

    if not mainContainer then self:CreateBaseFrames() end

    if not DB.enabled then
        mainContainer:Hide()
        if ticker then ticker:Cancel(); ticker = nil end
        return
    end

    mainContainer:Show()
    BuildTrackedList()

    if #trackedList == 0 and ticker then
        ticker:Cancel(); ticker = nil
    end

    self:Refresh()
    SetupTimeSpiralEvents()

    if #trackedList > 0 then
        self:StartTicker()
    end
    self:UpdateCooldowns()
end

-- Boot
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function() ns.CooldownText:Initialize() end)

-------------------------------------------------------------------------------
--  OPTIONS UI
-------------------------------------------------------------------------------
function CooldownText.AddOptions(parent)
    local GUI = ns.GUI
    if not GUI then return end
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    DB = GetSettings()
    local function RefreshSettings() ns.CooldownText:Refresh() end
    local function FullRefresh() ns.CooldownText:Initialize() end

    local yOffset = -10

    -- ── HEADER ──────────────────────────────────────────────────────────────
    local header = GUI:CreateSectionHeader(content, "Movement Cooldown Tracker")
    header:SetPoint("TOPLEFT", 10, yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 40

    local masterBtn = GUI:CreateCheckbox(content, "Enable Cooldown Tracker", "enabled", DB, FullRefresh)
    masterBtn:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local raidChk = GUI:CreateCheckbox(content, "Only show in Raid/Dungeon", "onlyRaidDungeon", DB, RefreshSettings)
    raidChk:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 35

    -- ── DISPLAY MODE ────────────────────────────────────────────────────────
    local modeHeader = GUI:CreateSectionHeader(content, "Display Mode")
    modeHeader:SetPoint("TOPLEFT", 10, yOffset)
    modeHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    local modeOptions = {
        { value = "text", text = "Text (Name: 3.5)" },
        { value = "icon", text = "Icon (Cooldown Swipe)" },
        { value = "bar",  text = "Bar (StatusBar)" },
    }
    local modeLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    modeLabel:SetText("Display Mode:")
    modeLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local ddMode = GUI:CreateDropdown(content, "", modeOptions, "displayMode", DB, function()
        FullRefresh()
        -- Refresh the options page too if we have a rebuild callback
    end)
    ddMode:SetPoint("LEFT", modeLabel, "RIGHT", 17, 0)
    if ddMode.dropdown then ddMode.dropdown:SetWidth(180) end
    yOffset = yOffset - 35

    -- ── APPEARANCE ──────────────────────────────────────────────────────────
    local colorPicker
    local classColorChk = GUI:CreateCheckbox(content, "Use Class Color", "useClassColor", DB, function(val)
        if colorPicker then
            if val then colorPicker:Hide() else colorPicker:Show() end
        end
        RefreshSettings()
    end)
    classColorChk:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    colorPicker = GUI:CreateColorPicker(content, "Custom Text Color", "textColor", DB, RefreshSettings)
    colorPicker:SetPoint("TOPLEFT", 15, yOffset)
    if DB.useClassColor ~= false then colorPicker:Hide() end
    yOffset = yOffset - 35

    -- Text mode settings
    local fontLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontLabel:SetText("Font Size:")
    fontLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local fontSlider = GUI:CreateSlider(content, "", 8, 36, "fontSize", DB, RefreshSettings, 1)
    fontSlider:SetPoint("LEFT", fontLabel, "RIGHT", 15, 0)
    if fontSlider.slider then fontSlider.slider:SetWidth(150) end
    yOffset = yOffset - 35

    -- Icon mode settings
    local iconLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    iconLabel:SetText("Icon Size:")
    iconLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local iconSlider = GUI:CreateSlider(content, "", 20, 80, "iconSize", DB, RefreshSettings, 1)
    iconSlider:SetPoint("LEFT", iconLabel, "RIGHT", 15, 0)
    if iconSlider.slider then iconSlider.slider:SetWidth(150) end
    yOffset = yOffset - 35

    -- Bar mode settings
    local bwLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bwLabel:SetText("Bar Width:")
    bwLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local bwSlider = GUI:CreateSlider(content, "", 100, 400, "barWidth", DB, RefreshSettings, 1)
    bwSlider:SetPoint("LEFT", bwLabel, "RIGHT", 15, 0)
    if bwSlider.slider then bwSlider.slider:SetWidth(150) end
    yOffset = yOffset - 35

    local bhLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bhLabel:SetText("Bar Height:")
    bhLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local bhSlider = GUI:CreateSlider(content, "", 12, 40, "barHeight", DB, RefreshSettings, 1)
    bhSlider:SetPoint("LEFT", bhLabel, "RIGHT", 15, 0)
    if bhSlider.slider then bhSlider.slider:SetWidth(150) end
    yOffset = yOffset - 35

    -- Shared settings
    local spcLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    spcLabel:SetText("Spacing:")
    spcLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local spcSlider = GUI:CreateSlider(content, "", 0, 30, "spacing", DB, RefreshSettings, 1)
    spcSlider:SetPoint("LEFT", spcLabel, "RIGHT", 15, 0)
    if spcSlider.slider then spcSlider.slider:SetWidth(150) end
    yOffset = yOffset - 35

    local tickLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tickLabel:SetText("Refresh Rate (s):")
    tickLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local tickSlider = GUI:CreateSlider(content, "", 0.1, 1.0, "tickInterval", DB, RefreshSettings, 0.05)
    tickSlider:SetPoint("LEFT", tickLabel, "RIGHT", 15, 0)
    if tickSlider.slider then tickSlider.slider:SetWidth(150) end
    yOffset = yOffset - 35

    local growOptions = {
        { value = "DOWN", text = "Stack Downwards" },
        { value = "UP", text = "Stack Upwards" },
    }
    local growLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    growLabel:SetText("Grow Direction:")
    growLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local ddGrow = GUI:CreateDropdown(content, "", growOptions, "growDirection", DB, RefreshSettings)
    ddGrow:SetPoint("LEFT", growLabel, "RIGHT", 17, 0)
    if ddGrow.dropdown then ddGrow.dropdown:SetWidth(150) end
    yOffset = yOffset - 35

    local btnMover = GUI:CreateButton(content, "Toggle Anchor", 150, 26, function()
        ns.CooldownText:ToggleMover()
    end)
    btnMover:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- ── SOUND ALERT ─────────────────────────────────────────────────────────
    local soundHeader = GUI:CreateSectionHeader(content, "Sound Alert")
    soundHeader:SetPoint("TOPLEFT", 10, yOffset)
    soundHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    local infoSound = GUI:CreateInfoBox(content, "Play a sound when a tracked movement spell comes off cooldown.")
    infoSound:SetPoint("TOPLEFT", 10, yOffset)
    infoSound:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - (infoSound:GetHeight() + 10)

    local soundChk = GUI:CreateCheckbox(content, "Enable Sound Alert", "soundEnabled", DB, nil)
    soundChk:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local soundOptions = {{ value = "none", text = "None" }}
        for name in pairs(LSM:HashTable("sound")) do
            table.insert(soundOptions, { value = name, text = name })
        end
        table.sort(soundOptions, function(a, b)
            if a.value == "none" then return true end
            if b.value == "none" then return false end
            return a.text < b.text
        end)
        local sndLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        sndLabel:SetText("Alert Sound:")
        sndLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
        local ddSound = GUI:CreateDropdown(content, "", soundOptions, "soundKey", DB, function()
            -- Preview
            PlayAlertSound()
        end)
        ddSound:SetPoint("LEFT", sndLabel, "RIGHT", 17, 0)
        if ddSound.dropdown then ddSound.dropdown:SetWidth(180) end
        yOffset = yOffset - 40
    end

    -- ── TIME SPIRAL ─────────────────────────────────────────────────────────
    local tsHeader = GUI:CreateSectionHeader(content, "Time Spiral (Proc-Reset Flash)")
    tsHeader:SetPoint("TOPLEFT", 10, yOffset)
    tsHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    local infoTS = GUI:CreateInfoBox(content, "Flashes a big text alert when a tracked movement spell is proc-reset (e.g. a charge restored by a talent proc). Detects via Blizzard's Spell Activation Overlay glow system.")
    infoTS:SetPoint("TOPLEFT", 10, yOffset)
    infoTS:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - (infoTS:GetHeight() + 10)

    local tsChk = GUI:CreateCheckbox(content, "Enable Time Spiral Flash", "timeSpiralEnabled", DB, nil)
    tsChk:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    local tsColor = GUI:CreateColorPicker(content, "Flash Color", {DB.timeSpiralColorR or 0.2, DB.timeSpiralColorG or 1, DB.timeSpiralColorB or 0}, DB, function()
        -- Store as separate R/G/B keys
    end)
    tsColor:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 35

    if LSM then
        local tsSoundOptions = {{ value = "none", text = "None" }}
        for name in pairs(LSM:HashTable("sound")) do
            table.insert(tsSoundOptions, { value = name, text = name })
        end
        table.sort(tsSoundOptions, function(a, b)
            if a.value == "none" then return true end
            if b.value == "none" then return false end
            return a.text < b.text
        end)
        local tsSndChk = GUI:CreateCheckbox(content, "Enable Flash Sound", "timeSpiralSoundEnabled", DB, nil)
        tsSndChk:SetPoint("TOPLEFT", 10, yOffset)
        yOffset = yOffset - 30

        local tsSndLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tsSndLabel:SetText("Flash Sound:")
        tsSndLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
        local ddTSSound = GUI:CreateDropdown(content, "", tsSoundOptions, "timeSpiralSoundKey", DB, nil)
        ddTSSound:SetPoint("LEFT", tsSndLabel, "RIGHT", 17, 0)
        if ddTSSound.dropdown then ddTSSound.dropdown:SetWidth(180) end
        yOffset = yOffset - 40
    end

    local btnTestTS = GUI:CreateButton(content, "Test Flash", 120, 26, function()
        ShowTimeSpiralFlash()
    end)
    btnTestTS:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -- ── TRACKED SPELLS (Checkbox Grid) ──────────────────────────────────────
    local spellHeader = GUI:CreateSectionHeader(content, "Movement Spells")
    spellHeader:SetPoint("TOPLEFT", 10, yOffset)
    spellHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    local infoSpells = GUI:CreateInfoBox(content, "Enable or disable preset movement spells for your class. Spells are detected automatically per spec. You can also add custom spells below.")
    infoSpells:SetPoint("TOPLEFT", 10, yOffset)
    infoSpells:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - (infoSpells:GetHeight() + 10)

    local _, playerClass = UnitClass("player")
    local spellCheckboxes = {}

    for _, preset in ipairs(MOVEMENT_PRESETS) do
        if preset.class == playerClass then
            local primaryID = preset.ids[1]
            local spellName = GetSpellNameSafe(primaryID)
            local spellIcon = GetSpellIcon(primaryID)

            -- Icon
            local iconTex = content:CreateTexture(nil, "ARTWORK")
            iconTex:SetSize(20, 20)
            iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            iconTex:SetTexture(spellIcon)
            iconTex:SetPoint("TOPLEFT", 15, yOffset - 4)

            -- Initialize override if needed
            if DB.spellOverrides[primaryID] == nil then
                DB.spellOverrides[primaryID] = not MOVEMENT_DEFAULT_OFF[primaryID]
            end

            -- Checkbox
            local chk = GUI:CreateCheckbox(content, spellName .. " (" .. primaryID .. ")", primaryID, DB.spellOverrides, function(val)
                DB.spellOverrides[primaryID] = val
                -- Apply to all variant IDs in this preset
                for idx = 2, #preset.ids do
                    DB.spellOverrides[preset.ids[idx]] = val
                end
                FullRefresh()
            end)
            chk:SetPoint("TOPLEFT", 40, yOffset)
            table.insert(spellCheckboxes, chk)

            yOffset = yOffset - 26
        end
    end

    yOffset = yOffset - 15

    -- ── ADD CUSTOM SPELL ────────────────────────────────────────────────────
    local customHeader = GUI:CreateSectionHeader(content, "Add Custom Spell")
    customHeader:SetPoint("TOPLEFT", 10, yOffset)
    customHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    content.newSpellData = content.newSpellData or { spellID = "", text = "" }

    local lblName = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblName:SetText("Display Name:")
    lblName:SetPoint("TOPLEFT", 15, yOffset - 5)
    local inputName = GUI:CreateInput(content, "", "text", content.newSpellData, nil)
    inputName:SetPoint("LEFT", lblName, "RIGHT", 10, 0)
    if inputName.editBox then inputName.editBox:SetWidth(150) else inputName:SetWidth(150) end
    yOffset = yOffset - 30

    local lblID = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblID:SetText("Spell ID:")
    lblID:SetPoint("TOPLEFT", 15, yOffset - 5)
    local inputID = GUI:CreateInput(content, "", "spellID", content.newSpellData, nil)
    inputID:SetPoint("LEFT", lblID, "RIGHT", 40, 0)
    if inputID.editBox then inputID.editBox:SetWidth(100) else inputID:SetWidth(100) end
    yOffset = yOffset - 35

    local btnAdd = GUI:CreateButton(content, "Add Tracking", 120, 26, function()
        local sID = tonumber(content.newSpellData.spellID)
        local sName = content.newSpellData.text
        if sID then
            table.insert(DB.spellsToTrack, { spellID = sID, class = playerClass, text = (sName ~= "" and sName) or nil })
            content.newSpellData.spellID = ""
            content.newSpellData.text = ""
            if inputID.editBox then inputID.editBox:SetText("") else inputID:SetText("") end
            if inputName.editBox then inputName.editBox:SetText("") else inputName:SetText("") end
            FullRefresh()
            if content.RenderCustomList then content.RenderCustomList() end
        end
    end)
    btnAdd:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 45

    -- ── CUSTOM SPELL LIST ───────────────────────────────────────────────────
    local customListHeader = GUI:CreateSectionHeader(content, "Custom Tracked Spells")
    customListHeader:SetPoint("TOPLEFT", 10, yOffset)
    customListHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 30

    content.customRows = content.customRows or {}
    local listAnchorY = yOffset

    content.RenderCustomList = function()
        for _, row in ipairs(content.customRows) do row:Hide() end
        local ly = listAnchorY
        local customCount = 0
        for index, spellItem in ipairs(DB.spellsToTrack) do
            if spellItem.class == playerClass then
                customCount = customCount + 1
                local row = content.customRows[customCount]
                if not row then
                    row = CreateFrame("Frame", nil, content)
                    row:SetSize(400, 24)
                    local txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    txt:SetPoint("LEFT", 0, 0)
                    row.text = txt
                    local btnDel = GUI:CreateButton(row, "Remove", 70, 20, nil)
                    btnDel:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                    row.btnDel = btnDel
                    table.insert(content.customRows, row)
                end
                local displayName = spellItem.text or GetSpellNameSafe(spellItem.spellID)
                row.text:SetText(strformat("%s  (|cffAAAAAAID: %d|r)", displayName, spellItem.spellID))
                row.btnDel:SetScript("OnClick", function()
                    table.remove(DB.spellsToTrack, index)
                    FullRefresh()
                    content.RenderCustomList()
                end)
                row:SetPoint("TOPLEFT", 20, ly)
                row:Show()
                ly = ly - 26
            end
        end
        content:SetHeight(math.abs(ly) + 50)
    end

    content.RenderCustomList()
end