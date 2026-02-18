local ADDON_NAME, ns = ...
local InterruptTracker = {}
ns.InterruptTracker = InterruptTracker
LibStub("AceEvent-3.0"):Embed(InterruptTracker)

-- ============================================================================
-- CONSTANTS & DATA
-- ============================================================================
local LSM = LibStub("LibSharedMedia-3.0", true)

-- Main Interrupt Spells (ID -> Cooldown)
local INTERRUPTS = {
    -- DEATH KNIGHT
    [47528] = 15,   -- Mind Freeze
    -- DEMON HUNTER
    [183752] = 15,  -- Disrupt
    -- DRUID
    [106839] = 15,  -- Skull Bash
    [78675] = 60,   -- Solar Beam
    -- EVOKER
    [351338] = 40,  -- Quell
    -- HUNTER
    [147362] = 24,  -- Counter Shot
    [187707] = 15,  -- Muzzle
    -- MAGE
    [2139] = 24,    -- Counterspell
    -- MONK
    [116705] = 15,  -- Spear Hand Strike
    -- PALADIN
    [96231] = 15,   -- Rebuke
    [420090] = 15, -- NPC Rebuke (Follower Dungeon)
    -- PRIEST
    [15487] = 45,   -- Silence
    -- ROGUE
    [1766] = 15,    -- Kick
    -- SHAMAN
    [57994] = 12,   -- Wind Shear
    -- WARLOCK
    [19647] = 24,   -- Spell Lock (Felhunter)
    [132409] = 24,  -- Spell Lock (Command Demon)
    [119914] = 30,  -- Axe Toss (Felguard)
    -- WARRIOR
    [6552] = 15,    -- Pummel
}

local CLASS_INTERRUPTS = {
    ["WARRIOR"] = 6552,
    ["PALADIN"] = 96231,
    ["HUNTER"] = 147362,
    ["ROGUE"] = 1766,
    ["PRIEST"] = 15487,
    ["DEATHKNIGHT"] = 47528,
    ["SHAMAN"] = 57994,
    ["MAGE"] = 2139,
    ["WARLOCK"] = 19647, -- Spell Lock (Standard)
    ["MONK"] = 116705,
    ["DRUID"] = 106839,
    ["DEMONHUNTER"] = 183752,
    ["EVOKER"] = 351338,
}

local SPEC_INTERRUPTS = {
    -- DRUID
    [102] = 78675,  -- Balance (Solar Beam)
    
    -- HUNTER
    [255] = 187707, -- Survival (Muzzle)
    
    -- PRIEST
    [258] = 15487,  -- Shadow (Silence)
    
    -- WARLOCK (Optional handling for Demo/Destro if needed, currently sticking to Spell Lock default)
    -- [266] = 119914, -- Demonology (Axe Toss) - Optional
}

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
-- ============================================================================
-- DYNAMIC COOLDOWN DATA
-- ============================================================================

-- Talents that reduce interrupt cooldowns (scanned via inspect)
local CD_REDUCTION_TALENTS = {
    -- Hunter: Lone Survivor - "Counter Shot and Muzzle CD reduced by 2 sec"
    [388039] = { affects = 147362, reduction = 2 }, -- Counter Shot
    -- Evoker: Interwoven Threads - "All spell CDs reduced by 10%"
    [412713] = { affects = 351338, pctReduction = 0.1 }, -- Quell
    
    -- "On Successful Kick" talents (We track successful kicks, so these apply)
    -- DK: Coldthirst - "Mind Freeze CD reduced by 3 sec on successful interrupt"
    [378848] = { affects = 47528, reduction = 3 }, -- Mind Freeze (47528)
}

local activeReductions = {}
local container = nil
local testModeActive = false

-- ============================================================================
-- SPELL ID LAUNDERING (Fix for Tainted Party Events in 12.0.1)
-- ============================================================================
-- These MUST be created here, NOT inside event handlers
local launderBar = CreateFrame("StatusBar")
launderBar:SetMinMaxValues(0, 9999999)

-- Slider for OnValueChanged laundering
local launderSlider = CreateFrame("Slider", nil, UIParent)
launderSlider:SetMinMaxValues(0, 9999999)
launderSlider:SetSize(1, 1)
launderSlider:Hide()

-- OnValueChanged result storage (written by callback, read by handler)
local onValueChangedResult = nil
local onSliderChangedResult = nil

-- The key insight: when a widget fires OnValueChanged, the C++ engine
-- re-reads the value from internal storage and passes it as a callback arg.
-- This MIGHT strip taint since it's a new value from C++ land.
launderBar:SetScript("OnValueChanged", function(self, value)
    onValueChangedResult = value
end)

launderSlider:SetScript("OnValueChanged", function(self, value)
    onSliderChangedResult = value
end)

-- Watcher Frames for explicit unit registration
local partyFrames = {}
for i = 1, 4 do
    partyFrames[i] = CreateFrame("Frame")
end

-- Player Watcher (To avoid AceEvent/Global Taint issues)
local playerWatcher = CreateFrame("Frame")

-- Helper to register events
local function RegisterPartyWatchers()
    -- Party Members (Laundered)
    for i = 1, 4 do
        local unit = "party" .. i
        partyFrames[i]:UnregisterAllEvents()
        if UnitExists(unit) then
            partyFrames[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
            partyFrames[i]:SetScript("OnEvent", function(_, _, unit, castGUID, spellId)
                -- Launder spellID
                onValueChangedResult = nil
                launderBar:SetValue(0) -- reset
                pcall(launderBar.SetValue, launderBar, spellId)
                local barResult = onValueChangedResult

                -- Try OnValueChanged laundering (Slider)
                onSliderChangedResult = nil
                launderSlider:SetValue(0) -- reset
                pcall(launderSlider.SetValue, launderSlider, spellId)
                local sliderResult = onSliderChangedResult

                local cleanID = barResult or sliderResult

                -- print("GravityUI Debug: Raw ID:", spellId, "Clean ID:", cleanID)

                if cleanID then
                    InterruptTracker:UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", unit, castGUID, cleanID)
                end
            end)
            -- print("GravityUI Debug: Registered watcher for", unit)
        end
    end
    
    -- Player Watcher (Direct, Player Unit is usually safe but we use RegisterUnitEvent to be sure)
    playerWatcher:UnregisterAllEvents()
    playerWatcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    playerWatcher:SetScript("OnEvent", function(_, _, unit, castGUID, spellId)
         InterruptTracker:UNIT_SPELLCAST_SUCCEEDED("UNIT_SPELLCAST_SUCCEEDED", unit, castGUID, spellId)
    end)
end



-- ============================================================================
-- FRAME MANAGEMENT
-- ============================================================================

local function GetSettings()
    local db = ns.GetDB()
    if db and db.screenindicators then
        if not db.screenindicators.interruptTracker then
            db.screenindicators.interruptTracker = {
                enabled = true,
                x = 0, y = 0,
                width = 220, height = 20,
                barHeight = 20,
                iconSize = 20,
                fontSize = 12,
                font = "Gravity",
                texture = "Solid",
                growUpwards = true,
                useClassColors = true,
                showBorder = true,
                showIcon = true,
                showTime = true,
                showReadyText = true,
                testMode = false,
                useSpecificCooldownColor = false,
                cooldownTextColor = {1, 1, 1, 1},
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
    if LSM then
        texture = LSM:Fetch("statusbar", s.texture or "Gravity")
    end
    f.bar:SetStatusBarTexture(texture)
    f.bg:SetTexture(texture)
    
    -- Font
    local font = "Fonts\\FRIZQT__.TTF"
    if LSM then
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
    
    -- Sort active bars by expiration time
    table.sort(activeBars, function(a, b)
        -- Stable sort for Ready (0) vs Ready (0)
        -- And separate Ready (0) from Active (>GetTime())
        if a.expiration ~= b.expiration then
             return a.expiration < b.expiration
        end
        return a.name < b.name
    end)
    
    for i, info in ipairs(activeBars) do
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

-- ============================================================================
-- LOGIC
-- ============================================================================

local function StartCooldown(guid, name, class, spellId, isReady)
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    local baseCD = INTERRUPTS[spellId]
    if not baseCD then return end
    
    -- print("GravityUI Debug: StartCooldown", name, spellId, isReady)

    -- Check duplicates
    for i, info in ipairs(activeBars) do
        if info.guid == guid and info.spellId == spellId then
            -- Refresh
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
                    r,g,b,a = c[1],c[2],c[3],c[4]
                end
                info.frame.time:SetTextColor(r,g,b,a)
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
                    local c = s.cooldownTextColor or {1, 1, 1, 1}
                    cr, cg, cb, ca = c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
                end
                info.frame.time:SetTextColor(cr, cg, cb, ca)
            end
            -- Re-apply styling
            StyleBar(info.frame, class)
            UpdateLayout()
            return
        end
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
        expiration = expiration,
        duration = duration,
        frame = f
    }
    table.insert(activeBars, info)
    
    UpdateLayout()
    
    -- Say Kick (Self Only)
    local isEditMode = container and container.mover and container.mover:IsShown()
    if not isReady and UnitGUID("player") == guid and not testModeActive and not isEditMode then
         if s and s.sayKick and s.sayKickText then
             local msg = s.sayKickText
             
             -- %t = Target
             local targetName = UnitName("target") or "Target"
             msg = msg:gsub("%%t", targetName)
             
             -- %f = Focus
             local focusName = UnitName("focus") or "Focus"
             msg = msg:gsub("%%f", focusName)
             
             -- %s legacy support
             msg = msg:gsub("%%s", "Spell") 

             SendChatMessage(msg, "SAY")
         end
     end
end

local function OnUpdate(self, elapsed)
    local now = GetTime()
    local dirty = false
    local s = GetSettings()
    
    -- Check expiration
    for i, info in ipairs(activeBars) do
        if info.duration > 0 then
            -- Active Cooldown
            if now >= info.expiration then
                -- Expired -> Ready
                info.duration = 0
                info.expiration = 0
                info.frame.bar:SetValue(1) -- Set bar to full
                
                if s and s.showReadyText then
                     info.frame.time:SetText("Ready")
                else
                     info.frame.time:SetText("")
                end
                
                -- Reset Color to Ready Color
                local cr, cg, cb, ca = 1, 1, 1, 1
                if s and s.useSpecificCooldownColor then
                    local c = s.cooldownTextColor or {1, 1, 1, 1}
                     cr, cg, cb, ca = c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
                end
                info.frame.time:SetTextColor(cr, cg, cb, ca)
                
                dirty = true
            else
                -- Update Timer Text
                local remaining = info.expiration - now
                local pct = remaining / info.duration
                info.frame.bar:SetValue(pct) -- Update bar value
                info.frame.time:SetText(string.format("%.1f", remaining)) -- Use string.format for consistency with StartCooldown
            end
        else
            -- Already Ready
            local targetText = (s and s.showReadyText) and "Ready" or ""
            if info.frame.time:GetText() ~= targetText then
                 info.frame.time:SetText(targetText)
            end
        end
    end
    
    if dirty then UpdateLayout() end
end

-- ============================================================================
-- EVENT HANDLERS (AceEvent)
-- ============================================================================
local updateFrame = CreateFrame("Frame", "GravityUI_InterruptTrackerUpdate", UIParent)
updateFrame:Hide()
updateFrame:SetScript("OnUpdate", OnUpdate)

function InterruptTracker:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellId)
    -- Restriction: Only in Party (Dungeons/M+), Disable in Raid/Solo
    if not IsInGroup() then return end -- Must be in a group
    if IsInRaid() then return end      -- Must be in a Party (not Raid Group)
    
    local _, instanceType = IsInInstance()
    if instanceType == "raid" then return end -- Must not be in Raid Instance

    -- Check if it is an interrupt spell
    -- Safe Check: Avoid "table index is secret"
    if not spellId or type(spellId) ~= "number" then return end
    
    -- Debug Print
    -- print("GravityUI Debug: Event", event, "Unit", unit, "Spell", spellId)

    -- Safe Check: Wrap lookup in pcall
    local success, val = pcall(function() return INTERRUPTS[spellId] end)
    if success and val then 
         local guid = UnitGUID(unit)
         local name = UnitName(unit)
         local _, class = UnitClass(unit)
         
         -- print("GravityUI Debug: Interrupt Event Detected", unit, name, spellId)
         
         -- Robust Filter: Check if this GUID is in our activeBars tracking list
         local tracked = false
         if UnitIsUnit(unit, "player") then 
             tracked = true 
         else
             for _, info in ipairs(activeBars) do
                 if info.guid == guid then
                     tracked = true
                     break
                 end
             end
         end
         
         if tracked then
             -- print("GravityUI Debug: Updating Cooldown for", name, spellId)
             StartCooldown(guid, name, class, spellId)
         else
             -- print("GravityUI Debug: Ignored Untracked Unit", unit, name)
         end
    end
end





function InterruptTracker.TestMode()
    if testModeActive then
        activeBars = {}
        for _, f in ipairs(framePool) do f:Hide() end
        testModeActive = false
    else
        testModeActive = true
        StartCooldown(UnitGUID("player"), "Test Player", "WARRIOR", 6552) -- Pummel
        StartCooldown(UnitGUID("player"), "Test Mage", "MAGE", 2139) -- Counterspell
        StartCooldown(UnitGUID("player"), "Test Shaman", "SHAMAN", 57994) -- Wind Shear
    end
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
            local specInterrupt = SPEC_INTERRUPTS[specID]
            if specInterrupt then
                -- Find existing bar for this GUID
                for _, info in ipairs(activeBars) do
                    if info.guid == guid then
                        -- Check if we need to update spellID
                        if info.spellId ~= specInterrupt then
                             info.spellId = specInterrupt
                             
                             -- Update Icon
                             local spellIcon = C_Spell.GetSpellTexture(specInterrupt)
                             info.frame.icon:SetTexture(spellIcon)
                             
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
                        end
                        break 
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
         for _, info in ipairs(activeBars) do info.frame:Hide() end
         activeBars = {}
         -- Unregister watchers
         for i=1,4 do partyFrames[i]:UnregisterAllEvents() end
         return
    end
    
    -- Register Watchers for Party Members
    RegisterPartyWatchers()
    
    local members = {}
    
    local function HandleMember(unit)
        if not UnitExists(unit) then return end
        
        local guid = UnitGUID(unit)
        if not guid then return end
        
        members[guid] = true
        
        -- Queue Inspect (Dynamic CD)
        if not UnitIsUnit(unit, "player") then
            QueueInspect(unit)
        end
        
        -- Create/Update Bar (Persistent)
        local _, class = UnitClass(unit)
        local interruptID = CLASS_INTERRUPTS[class]
        
        if interruptID then
            -- Check if bar exists
            local found = false
            for _, info in ipairs(activeBars) do
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
    for i = #activeBars, 1, -1 do
        local info = activeBars[i]
        -- Logic: If guid is not in current members AND bar is not testMode, hide it.
        if not members[info.guid] and not testModeActive then
             info.frame:Hide()
             table.remove(activeBars, i)
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
        if #activeBars == 0 then
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
        -- InterruptTracker:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") -- REMOVED: Managed by playerWatcher
        InterruptTracker:RegisterEvent("INSPECT_READY", function(_, guid) OnInspectReady(guid) end)
        InterruptTracker:RegisterEvent("GROUP_ROSTER_UPDATE", OnGroupRosterUpdate)
        InterruptTracker:RegisterEvent("PLAYER_ENTERING_WORLD", OnGroupRosterUpdate)
        
        container:Show()
        OnGroupRosterUpdate() -- Initial scan
        RegisterPartyWatchers() -- Initial watchers (Includes Player)
        
        updateFrame:Show() -- Starts OnUpdate
    else
        InterruptTracker:UnregisterAllEvents()
        for i=1,4 do partyFrames[i]:UnregisterAllEvents() end
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
        -- InterruptTracker:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") -- REMOVED
        InterruptTracker:RegisterEvent("INSPECT_READY", function(_, guid) OnInspectReady(guid) end)
        InterruptTracker:RegisterEvent("GROUP_ROSTER_UPDATE", OnGroupRosterUpdate)
        InterruptTracker:RegisterEvent("PLAYER_ENTERING_WORLD", OnGroupRosterUpdate)
        
        OnGroupRosterUpdate() -- Initial scan
        RegisterPartyWatchers() -- Initial watchers
        
        updateFrame:Show()
        container:Show()
    else
        InterruptTracker:UnregisterAllEvents()
        for i=1,4 do partyFrames[i]:UnregisterAllEvents() end
        playerWatcher:UnregisterAllEvents()
        updateFrame:Hide()
        container:Hide()
    end
     
     container:ClearAllPoints()
     container:SetPoint("CENTER", UIParent, "CENTER", s.x or 0, s.y or 0)
     
     -- Apply Background Color (Container is transparent)
    container:SetBackdropColor(0, 0, 0, 0)
     
     -- Refresh styles of active
     for _, info in ipairs(activeBars) do
          StyleBar(info.frame, info.class)
     end
     
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
    print("- Active Bars:", #activeBars)
    for i, info in ipairs(activeBars) do
        print(i, info.name, info.spellId, info.expiration, info.frame:IsShown())
    end
    print("- Mover Shown:", container.mover and container.mover:IsShown())
    local s = GetSettings()
    print("- Enabled:", s and s.enabled)
    print("- Group:", IsInGroup(), "Raid:", IsInRaid())
end
