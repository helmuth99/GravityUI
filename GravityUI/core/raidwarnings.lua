local ADDON_NAME, ns = ...
local RaidWarnings = {}
ns.RaidWarnings = RaidWarnings

-- ============================================================================
-- CONSTANTS & CONFIG
-- ============================================================================
local TRACKED_SPELLS = {
    -- SOULWELLS
    [29893] = "soulwell", 
    
    -- RITUALS
    [698] = "ritual", 
    
    -- MAGE TABLES
    [190336] = "magetable", 
    
    -- REPAIR BOTS
    [67826] = "repair", 
    [199109] = "repair", 
    [199115] = "repair", 
    [126459] = "repair", 
    [161414] = "repair", 
    [261602] = "repair", 
    [300203] = "repair", 
    [22700] = "repair", 
    [44389] = "repair", 
    [54710] = "repair", 
    [199109] = "repair", 
    [199115] = "repair", 
    
    -- PORTALS
    [120146] = "portal", 
    [224871] = "portal", 
    [281403] = "portal", 
    [281404] = "portal", 
    [344587] = "portal", 
    [395277] = "portal", 
    [10059] = "portal", 
    [11416] = "portal", 
    [11419] = "portal", 
    [11420] = "portal", 
    [11418] = "portal", 
    [11417] = "portal", 
    [32271] = "portal", 
    [32272] = "portal", 
    [49359] = "portal", 
    [49358] = "portal", 
    [49360] = "portal", 
    [49361] = "portal", 
    [53140] = "portal", 
    [88344] = "portal", 
    [88342] = "portal", 
    [132621] = "portal", 
    [132627] = "portal", 
    [176248] = "portal", 
    [176242] = "portal", 
    
    -- FEASTS
    [201351] = "feast", 
    [201352] = "feast", 
    [259409] = "feast", 
    [259410] = "feast", 
    [297048] = "feast", 
    [308458] = "feast", 
    [308462] = "feast", 
    [327706] = "feast", 
    [327821] = "feast", 
    [383063] = "feast", 
    [382426] = "feast", 
    [396092] = "feast", 
    [433066] = "feast", 
    [462213] = "feast", -- Hearty Feast of the Midnight Masquerade
}

-- ============================================================================
-- HELPER: SAFE LSM ACCESS
-- ============================================================================
local function GetLSM()
    return ns.LSM or LibStub("LibSharedMedia-3.0", true)
end

-- ============================================================================
-- VISUAL FRAME (Lazy Creation)
-- ============================================================================
local alertFrame, alertText
local function CreateAlertFrame()
    if alertFrame then return end
    
    alertFrame = CreateFrame("Frame", "GravityUI_RaidAlertFrame", UIParent, "BackdropTemplate")
    alertFrame:SetSize(400, 50)
    alertFrame:SetPoint("CENTER", 0, 150)
    alertFrame:SetFrameStrata("HIGH")
    alertFrame:SetMovable(true)
    alertFrame:SetUserPlaced(true)
    alertFrame:Hide()
    
    alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    alertText:SetPoint("CENTER")
    alertText:SetJustifyH("CENTER")
    
    local ag = alertFrame:CreateAnimationGroup()
    alertFrame.animGroup = ag
    
    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.2)
    fadeIn:SetOrder(1)
    
    local hold = ag:CreateAnimation("Alpha")
    hold:SetFromAlpha(1)
    hold:SetToAlpha(1)
    hold:SetDuration(3.0)
    hold:SetOrder(2)
    
    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetOrder(3)
    
    ag:SetScript("OnFinished", function()
        alertFrame:Hide()
    end)
    
    ns.RaidAlertFrame = alertFrame
end

function RaidWarnings.ApplySettings()
    if not alertFrame then return end
    -- Force fetch DB to ensure fresh settings
    local db = ns.GetDB()
    if not db or not db.raidWarnings then return end
    local csv = db.raidWarnings
    
    -- Font
    local defaultFont = "Gravity"
    if db.general and db.general.font then defaultFont = db.general.font end

    local fontPath = "Fonts/FRIZQT__.TTF"
    local LSM = GetLSM()
    if LSM then
        local fetched = LSM:Fetch("font", csv.font or defaultFont)
        if fetched then fontPath = fetched end
    end
    alertText:SetFont(fontPath, csv.fontSize or 24, "OUTLINE")
    
    -- Color
    local r, g, b = 1, 1, 0
    if csv.color then r,g,b = unpack(csv.color) end
    alertText:SetTextColor(r, g, b)
    
    -- Position
    alertFrame:ClearAllPoints()
    if csv.x and csv.y then
        alertFrame:SetPoint("CENTER", UIParent, "CENTER", csv.x, csv.y)
    else
        alertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    end
    
    -- Scale/Size
    alertFrame:SetScale(1)
    alertFrame:SetSize(400, (csv.fontSize or 24) + 10)
end

-- ============================================================================
-- ALERTS
-- ============================================================================
function RaidWarnings.ShowAlert(spellName, providerName, key)
    if not alertFrame then CreateAlertFrame() end
    
    RaidWarnings.ApplySettings()
    
    local db = ns.GetDB()
    local csv = db and db.raidWarnings
    
    local text = string.format("%s used by %s", spellName, providerName or "Unknown")
    
    if key == "repair" then text = string.format("%s (Repair) placed by %s", spellName, providerName) end
    if key == "portal" then text = string.format("Portal: %s opened by %s", spellName, providerName) end
    if key == "feast" then text = string.format("%s placed by %s", spellName, providerName) end
    if key == "soulwell" then text = string.format("Soulwell created by %s", providerName) end
    if key == "ritual" then text = string.format("Summoning Ritual started by %s", providerName) end
    if key == "magetable" then text = string.format("Refreshment Table created by %s", providerName) end
    
    alertText:SetText(text)
    
    if csv and csv.soundEnabled and csv.soundFile then
        local soundFile = csv.soundFile
        local LSM = GetLSM()
        
        if LSM then
            local fetchedSound = LSM:Fetch("sound", csv.soundFile)
            if fetchedSound then
                soundFile = fetchedSound
            end
        end
        
        -- Smart Play: Handle Numbers (FileIDs) vs Strings (Paths)
        if type(soundFile) == "number" then
            PlaySound(soundFile, "Master")
        else
            soundFile = tostring(soundFile)
            -- If it's still a "key" that wasn't fetched, default to standard sound
            if not string.find(soundFile, "\\") and not string.find(soundFile, "/") then
                PlaySound(8959, "Master") -- Raid Warning Sound ID Fallback
            else
                PlaySoundFile(soundFile, "Master")
            end
        end
    end
    
    alertFrame:Show()
    alertFrame.animGroup:Stop()
    alertFrame.animGroup:Play()
end

function RaidWarnings.TestAlert()
    ns.GetDB()
    RaidWarnings.ShowAlert("Test Event", UnitName("player"), "feast")
end

-- ============================================================================
-- API FOR CUSTOM SPELLS
-- ============================================================================
function RaidWarnings.AddCustomSpell(id, type)
    if not id or not type then return false, "Invalid ID or Type" end
    id = tonumber(id)
    if not id then return false, "ID must be a number" end
    
    local db = ns.GetDB()
    if not db or not db.raidWarnings then return false, "Database not loaded" end
    
    if not db.raidWarnings.customSpells then db.raidWarnings.customSpells = {} end
    db.raidWarnings.customSpells[id] = type
    return true
end

function RaidWarnings.RemoveCustomSpell(id)
    if not id then return end
    id = tonumber(id)
    local db = ns.GetDB()
    if db and db.raidWarnings and db.raidWarnings.customSpells then
        db.raidWarnings.customSpells[id] = nil
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function RaidWarnings.Initialize()
    CreateAlertFrame()
end

-- ============================================================================
-- ADDON COMMUNICATION
-- ============================================================================
local COMM_PREFIX = "GravityUI"
if C_ChatInfo then C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX) end

-- ============================================================================
-- SPELL ID LAUNDERING (Fix for Tainted Party Events in 12.0.1)
-- ============================================================================
local launderBar = CreateFrame("StatusBar")
launderBar:SetMinMaxValues(0, 9999999)

local launderSlider = CreateFrame("Slider", nil, UIParent)
launderSlider:SetMinMaxValues(0, 9999999)
launderSlider:SetSize(1, 1)
launderSlider:Hide()

local onValueChangedResult = nil
local onSliderChangedResult = nil

launderBar:SetScript("OnValueChanged", function(self, value)
    onValueChangedResult = value
end)

launderSlider:SetScript("OnValueChanged", function(self, value)
    onSliderChangedResult = value
end)

-- ============================================================================
-- WATCHER FRAMES (Reliable Event Detection)
-- ============================================================================
local watcherFrames = {}
-- We need up to 40 frames for Raid
for i = 1, 40 do
    watcherFrames[i] = CreateFrame("Frame")
end

-- Forward declaration
local ProcessSpellCast 

local function UpdateWatchers()
    -- Unregister all first
    for _, f in ipairs(watcherFrames) do f:UnregisterAllEvents() end
    
    local members = GetNumGroupMembers()
    local method = IsInRaid() and "raid" or "party"
    if method == "party" then members = members - 1 end -- 'party' excludes player in count usually involved in other loops, but let's be specific
    -- Actually:
    -- If Raid: raid1..raidN
    -- If Party: party1..party4 (GetNumSubgroupMembers) + player
    
    if IsInRaid() then
        for i = 1, 40 do
             local unit = "raid"..i
             if UnitExists(unit) then
                 watcherFrames[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
                 watcherFrames[i]:SetScript("OnEvent", function(_, _, unit, castGUID, spellId)
                     ProcessSpellCast(unit, castGUID, spellId)
                 end)
             end
        end
    elseif IsInGroup() then
        -- Party Members
        for i = 1, 4 do
             local unit = "party"..i
             if UnitExists(unit) then
                 watcherFrames[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
                 watcherFrames[i]:SetScript("OnEvent", function(_, _, unit, castGUID, spellId)
                     ProcessSpellCast(unit, castGUID, spellId)
                 end)
             end
        end
        -- Player (handled by a separate watcher or just slot 5)
        watcherFrames[5]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        watcherFrames[5]:SetScript("OnEvent", function(_, _, unit, castGUID, spellId)
             ProcessSpellCast(unit, castGUID, spellId)
        end)
    else
        -- Solo (Player only)
        watcherFrames[1]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        watcherFrames[1]:SetScript("OnEvent", function(_, _, unit, castGUID, spellId)
             ProcessSpellCast(unit, castGUID, spellId)
        end)
    end
end

-- ============================================================================
-- EVENT HANDLE (UNIT_SPELLCAST_SUCCEEDED & COMM)
-- ============================================================================
-- ============================================================================
-- SPELL PROCESSING (Laundered)
-- ============================================================================
-- Throttle State (Locally generated events)
local lastCastGUID = nil
local lastCastTime = 0

ProcessSpellCast = function(unitTarget, castGUID, spellID)
    -- 1. LAUNDER SPELL ID
    onValueChangedResult = nil
    launderBar:SetValue(0) 
    pcall(launderBar.SetValue, launderBar, spellID)
    local cleanID = onValueChangedResult

    if not cleanID then
        onSliderChangedResult = nil
        launderSlider:SetValue(0)
        pcall(launderSlider.SetValue, launderSlider, spellID)
        cleanID = onSliderChangedResult
    end
    
    if not cleanID then return end
    spellID = cleanID

    -- 2. LOGIC
    if not castGUID or not spellID or type(spellID) ~= "number" then return end
    
    local now = GetTime()
    
    -- Safe Comparison for Secret GUIDs (pcall protection)
    local isDuplicate = false
    if castGUID and lastCastGUID then
        local success, match = pcall(function() return castGUID == lastCastGUID end)
        if success and match then isDuplicate = true end
    end
    
    -- 1s Throttle for same cast
    if isDuplicate and (now - lastCastTime) < 1.0 then return end

    local db = ns.GetDB()
    if not db or not db.raidWarnings or not db.raidWarnings.enabled then return end
    local csv = db.raidWarnings
    
    -- Check Tracked Spells (using pcall for safety)
    local key = nil
    local success, val = pcall(function() return TRACKED_SPELLS[spellID] end)
    if success then key = val end
    
    -- Check Custom Spells
    if not key and csv.customSpells then
        local success_custom, key_custom = pcall(function() return csv.customSpells[spellID] end)
        if success_custom then key = key_custom end
    end
    
    if not key then return end
    if csv.events and not csv.events[key] then return end
    
    -- Group Check (Redundant if watchers are managed well, but safe)
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()
    
    if inRaid then
         if not csv.showInRaid then return end
    elseif inGroup then
         if not csv.showInGroup then return end
    end
    
    -- Update Throttle
    lastCastGUID = castGUID
    lastCastTime = now
    
    local spellName = C_Spell.GetSpellName(spellID) or "Unknown Spell"
    local providerName = UnitName(unitTarget) or "Unknown"
    
    -- Show Alert (Locally Detected)
    RaidWarnings.ShowAlert(spellName, providerName, key)
end

-- ============================================================================
-- EVENT HANDLE (WATCHER MGMT & COMM)
-- ============================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- Throttle for incoming COMM messages
local commThrottle = {}

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        UpdateWatchers()
        
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        
        if prefix ~= COMM_PREFIX then return end
        
        -- Ignore messages from self (we already showed local alert)
        local myself = UnitName("player")
        if sender == myself or sender == (myself.."-"..GetRealmName()) then return end
        
        -- Parse Message: "RW:SpellID:Key"
        if string.sub(message, 1, 3) == "RW:" then
            local _, spellID, key = strsplit(":", message)
            spellID = tonumber(spellID)
            
            if not spellID or not key then return end
            
            -- Throttle remote messages (same sender + same spell within 1s)
            local now = GetTime()
            local throttleKey = sender .. "_" .. spellID
            if commThrottle[throttleKey] and (now - commThrottle[throttleKey]) < 1.0 then return end
            commThrottle[throttleKey] = now
            
            -- Fetch Spell Name locally to ensure client language match
            local spellName = C_Spell.GetSpellName(spellID) or "Unknown Spell"
            
            -- Show Alert
            -- Remove Realm from sender name for cleaner UI
            if string.find(sender, "-") then
                sender = string.match(sender, "([^-]+)")
            end
            
            RaidWarnings.ShowAlert(spellName, sender, key)
        end
    end
end)

-- ============================================================================
-- MOVER LOGIC
-- ============================================================================
function RaidWarnings.ToggleMover(forceState)
    if not alertFrame then CreateAlertFrame() end
    
    local shouldShow = false
    if forceState ~= nil then
        shouldShow = forceState
    else
        shouldShow = not alertFrame:IsShown()
    end
    
    if shouldShow then
        alertFrame:Show()
        alertText:SetText("Raid Warning Test")
        alertFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        
        -- Default to Green (Manual Toggle)
        local r, g, b, a = 0, 0.5, 0, 0.5
        local br, bg, bb, ba = 0, 1, 0, 1
        
        -- Check Global Edit Mode Override
        if forceState == true and ns.Movers and ns.Movers.ApplyEditModeStyle then
            -- We manually set colors to match ApplyEditModeStyle because we control the backdrop directly here
            -- Blue Overlay
            r, g, b, a = 0, 0.6, 1, 0.5
            br, bg, bb, ba = 0, 0.8, 1, 1
        end

        alertFrame:SetBackdropColor(r, g, b, a)
        alertFrame:SetBackdropBorderColor(br, bg, bb, ba)
        alertFrame:EnableMouse(true)
        alertFrame:RegisterForDrag("LeftButton")
        alertFrame:SetScript("OnDragStart", alertFrame.StartMoving)
        alertFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local _, _, _, x, y = self:GetPoint()
            local db = ns.GetDB()
            if db and db.raidWarnings then
                db.raidWarnings.x = x
                db.raidWarnings.y = y
            end
        end)
    else
        alertFrame:Hide()
        alertFrame:EnableMouse(false)
        alertFrame:RegisterForDrag()
        alertFrame:SetScript("OnDragStart", nil)
        alertFrame:SetScript("OnDragStop", nil)
        alertFrame:SetBackdrop(nil)
    end
end

function RaidWarnings.RegisterMover()
    if ns.Movers and ns.Movers.Register then
        if not alertFrame then CreateAlertFrame() end
        ns.Movers:Register("RaidWarnings", alertFrame, function(frame, enabled, force) RaidWarnings.ToggleMover(force) end, "Raid Warnings")
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function RaidWarnings.Initialize()
    CreateAlertFrame()
    RaidWarnings.RegisterMover()
end

-- ============================================================================
-- ADDON COMMUNICATION
-- ============================================================================
local COMM_PREFIX = "GravityUI"


