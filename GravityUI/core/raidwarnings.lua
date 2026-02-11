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
    
    alertFrame = CreateFrame("Frame", "GravityUI_RaidAlertFrame", UIParent)
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
-- EVENT HANDLE (UNIT_SPELLCAST_SUCCEEDED)
-- ============================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

-- Throttle State
local lastCastGUID = nil
local lastCastTime = 0

eventFrame:SetScript("OnEvent", function(self, event, unitTarget, castGUID, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not castGUID or not spellID or type(spellID) ~= "number" then return end
        local now = GetTime()
        if castGUID and castGUID == lastCastGUID and (now - lastCastTime) < 1.0 then
            return
        end

        local db = ns.GetDB()
        if not db or not db.raidWarnings or not db.raidWarnings.enabled then return end
        local csv = db.raidWarnings
        
        -- Check Logic: 1. Hardcoded List, 2. Custom List
        local key = TRACKED_SPELLS[spellID]
        if not key and csv.customSpells then
            key = csv.customSpells[spellID]
        end
        
        if not key then return end
        
        if not csv.events or not csv.events[key] then return end
        
        local inRaid = IsInRaid()
        local inGroup = IsInGroup()
        
        -- Logic:
        -- If in Raid -> Check showInRaid
        -- If in Group (but not raid) -> Check showInGroup
        -- If Solo -> Do NOT show (Strict Mode)
        
        if inRaid then
             if not csv.showInRaid then return end
        elseif inGroup then
             if not csv.showInGroup then return end
        else
             -- SOLO: STRICTLY RETURN
             return 
        end
        
        -- Update Throttle only if we are actually proceeding
        lastCastGUID = castGUID
        lastCastTime = now
        
        local spellName = C_Spell.GetSpellName(spellID) or "Unknown Spell"
        local sourceName = UnitName(unitTarget) or "Unknown"
        
        RaidWarnings.ShowAlert(spellName, sourceName, key)
    end
end)

-- Auto-Initialize on Load (Pre-Create Frame)
RaidWarnings.Initialize()


