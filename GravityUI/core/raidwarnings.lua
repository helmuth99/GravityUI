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
    
    -- WARLOCK
    [111771] = "gateway", 
    
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
    [242745] = "feast", 
    [266985] = "feast", 
    [127892] = "feast", 
    -- Midnight Feasts (12.0)
    [1259657] = "feast", -- Quel'dorei Medley
    [1278915] = "feast", -- Hearty Quel'dorei Medley
    [1259658] = "feast", -- Harandar Celebration
    [1278929] = "feast", -- Hearty Harandar Celebration
    [1237104] = "feast", -- Blooming Feast
    [1278909] = "feast", -- Hearty Blooming Feast
    [1259659] = "feast", -- Silvermoon Parade
    [1278895] = "feast", -- Hearty Silvermoon Parade
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

local textInfoFrame, textInfoText
local function CreateTextInfoFrame()
    if textInfoFrame then return end
    
    textInfoFrame = CreateFrame("Frame", "GravityUI_TextInfoFrame", UIParent)
    textInfoFrame:SetSize(400, 50)
    textInfoFrame:SetPoint("CENTER", 0, 100)
    textInfoFrame:Hide()
    
    textInfoText = textInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    textInfoText:SetPoint("CENTER")
    textInfoText:SetJustifyH("CENTER")
    textInfoFrame.text = textInfoText
    
    ns.TextInfoFrame = textInfoFrame
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

    -- Text Info Settings
    if not textInfoFrame then CreateTextInfoFrame() end
    local ti = csv.textInfos
    if ti then
        local fontPath = "Fonts/FRIZQT__.TTF"
        local LSM = GetLSM()
        if LSM then
            local fetched = LSM:Fetch("font", csv.font or defaultFont)
            if fetched then fontPath = fetched end
        end
        textInfoText:SetFont(fontPath, ti.durabilitySize or 24, "OUTLINE")
        local r, g, b = 1, 0.2, 0.2
        if ti.durabilityColor then r,g,b = unpack(ti.durabilityColor) end
        textInfoText:SetTextColor(r, g, b)
        textInfoFrame:ClearAllPoints()
        textInfoFrame:SetPoint("CENTER", UIParent, "CENTER", ti.durabilityX or 0, ti.durabilityY or 200)
    end

    -- Mark that settings have been freshly applied. settingsDirty will be reset to true
    -- by MarkSettingsDirty() when called from the settings panel, ensuring the next
    -- ShowAlert() call will re-apply if anything changed in between.
    -- (No action needed here since ShowAlert sets settingsDirty = false after calling us)
end

-- ============================================================================
-- ALERTS
-- ============================================================================
-- Performance Fix (Bug 2): settingsDirty flag ensures ApplySettings() is called
-- once on init/refresh, NOT on every single alert invocation.
local settingsDirty = true
function RaidWarnings.MarkSettingsDirty() settingsDirty = true end

function RaidWarnings.ShowAlert(spellName, providerName, key)
    if not alertFrame then CreateAlertFrame() end

    -- Only re-apply settings when something actually changed (e.g. after a Refresh)
    if settingsDirty then
        RaidWarnings.ApplySettings()
        settingsDirty = false
    end

    local db = ns.GetDB()
    local csv = db and db.raidWarnings
    
    local text = string.format("%s used by %s", spellName, providerName or "Unknown")
    
    if key == "repair" then text = string.format("%s (Repair) placed by %s", spellName, providerName) end
    if key == "portal" then text = string.format("Portal: %s opened by %s", spellName, providerName) end
    if key == "feast" then text = string.format("%s placed by %s", spellName, providerName) end
    if key == "soulwell" then text = string.format("Soulwell created by %s", providerName) end
    if key == "ritual" then text = string.format("Summoning Ritual started by %s", providerName) end
    if key == "magetable" then text = string.format("Refreshment Table created by %s", providerName) end
    if key == "gateway" then text = string.format("Demonic Gateway placed by %s", providerName) end
    
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
    CreateTextInfoFrame()
end

function RaidWarnings.CheckDurability()
    local db = ns.GetDB()
    if not db or not db.raidWarnings or not db.raidWarnings.enabled then 
        if textInfoFrame then textInfoFrame:Hide() end
        return 
    end
    
    local csv = db.raidWarnings
    local ti = csv.textInfos
    
    if not ti or not ti.durabilityEnabled then
        if textInfoFrame then textInfoFrame:Hide() end
        return
    end

    -- Visibility Filters
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()
    
    if inRaid then
         if not csv.showInRaid then if textInfoFrame then textInfoFrame:Hide() end return end
    elseif inGroup then
         if not csv.showInGroup then if textInfoFrame then textInfoFrame:Hide() end return end
    end

    -- Calculate Durability
    local minPercent = 100
    local hasDurability = false
    for i = 1, 18 do
        local current, max = GetInventoryItemDurability(i)
        if current and max and max > 0 then
            hasDurability = true
            local pct = (current / max) * 100
            if pct < minPercent then minPercent = pct end
        end
    end

    if hasDurability then
        if minPercent < (ti.durabilityThreshold or 25) then
            if not textInfoFrame then CreateTextInfoFrame() end
            RaidWarnings.ApplySettings()
            textInfoText:SetText("Durability low")
            textInfoFrame:Show()
        else
            if textInfoFrame then textInfoFrame:Hide() end
        end
    else
        if textInfoFrame then textInfoFrame:Hide() end
    end
end

-- ============================================================================
-- ADDON COMMUNICATION
-- ============================================================================
local COMM_PREFIX = "GravityUI"
if C_ChatInfo then C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX) end

-- ============================================================================
-- SPELL ID LAUNDERING (DISABLED - REPLACED BY ADDON COMMS)
-- ============================================================================
--[[
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
]]

-- ============================================================================
-- WATCHER FRAMES (Reliable Event Detection)
-- ============================================================================
-- Performance Fix: We only ever watch the player (1 unit), so 1 frame is sufficient.
-- Previous code created 40 frames unnecessarily.
local watcherFrame = CreateFrame("Frame")

-- Forward declaration
local ProcessSpellCast

-- Bug 3 Fix: Named function instead of anonymous closure to avoid
-- re-allocating a closure object on every GROUP_ROSTER_UPDATE.
local function WatcherOnEvent(_, _, unit, castGUID, spellId)
    ProcessSpellCast(unit, castGUID, spellId)
end

local function UpdateWatchers()
    watcherFrame:UnregisterAllEvents()

    if IsInGroup() then
        watcherFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        watcherFrame:SetScript("OnEvent", WatcherOnEvent)
    end
end

-- ============================================================================
-- SPELL PROCESSING (Laundered)
-- ============================================================================
-- Throttle State (Locally generated events)
local lastCastGUID = nil
local lastCastTime = 0

ProcessSpellCast = function(unitTarget, castGUID, spellID)
    -- ONLY PROCESS PLAYER LOCALLY
    -- Other members are processed via CHAT_MSG_ADDON to avoid taint/hacks
    if not UnitIsUnit(unitTarget, "player") then return end

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
    
    -- Check Tracked Spells
    local key = TRACKED_SPELLS[spellID]
    
    -- Check Custom Spells
    if not key and csv.customSpells then
        key = csv.customSpells[spellID]
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
    
    -- Broadcast to Party/Raid
    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or (IsInRaid() and "RAID" or "PARTY")
    pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, "RW:"..spellID..":"..key, channel)
end

-- ============================================================================
-- EVENT HANDLE (WATCHER MGMT & COMM)
-- ============================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")

-- Throttle for incoming COMM messages
local commThrottle = {}

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_INVENTORY_DURABILITY" then
        UpdateWatchers()
        RaidWarnings.CheckDurability()
        
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        
        if prefix ~= COMM_PREFIX then return end
        
        -- Ignore messages from self (we already showed local alert)
        local myself = UnitName("player")
        if sender == myself or sender == (myself.."-"..GetRealmName()) then return end
        
        -- Parse Message: "RW:SpellID:Key" (Key is optional)
        if string.sub(message, 1, 3) == "RW:" then
            local _, spellID, key = strsplit(":", message)
            spellID = tonumber(spellID)
            
            if not spellID then return end
            
            -- If Key is missing, try to resolve it from TRACKED_SPELLS
            if not key or key == "" then
                if TRACKED_SPELLS[spellID] then
                    key = TRACKED_SPELLS[spellID]
                else
                    key = "alert" -- Generic fallback
                end
            end
            
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

        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(alertFrame, true, "RaidWarnings")
        end
    else
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(alertFrame, false, "RaidWarnings")
        end
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
    CreateTextInfoFrame()
    RaidWarnings.RegisterMover()
    
    -- Initial Check
    C_Timer.After(2, RaidWarnings.CheckDurability)
end

