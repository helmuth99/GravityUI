local ADDON_NAME, ns = ...
local CooldownText = {}
ns.CooldownText = CooldownText

local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local IsInInstance = IsInInstance
local strformat = string.format
local GetSpecialization = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
local GetSpecializationInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo

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
    { class = "DEATHKNIGHT", ids = {48265} },          -- Death's Advance
    { class = "DEATHKNIGHT", ids = {212552} },         -- Wraith Walk
    { class = "DEATHKNIGHT", ids = {444347, 444010} }, -- Death Charge
    { class = "DEMONHUNTER", ids = {195072} },         -- Fel Rush
    { class = "DEMONHUNTER", ids = {189110} },         -- Infernal Strike
    { class = "DEMONHUNTER", ids = {1234796} },        -- Hero spec move
    { class = "DRUID",       ids = {102401} },         -- Wild Charge
    { class = "DRUID",       ids = {1850} },           -- Dash
    { class = "DRUID",       ids = {252216} },         -- Tiger Dash
    { class = "DRUID",       ids = {106898} },         -- Stampeding Roar
    { class = "EVOKER",      ids = {358267} },         -- Hover
    { class = "HUNTER",      ids = {186257} },         -- Aspect of the Cheetah
    { class = "HUNTER",      ids = {781} },            -- Disengage
    { class = "MAGE",        ids = {212653, 1953} },   -- Shimmer / Blink
    { class = "MONK",        ids = {109132, 115008} }, -- Roll / Chi Torpedo
    { class = "MONK",        ids = {119085} },         -- Tiger's Lust
    { class = "MONK",        ids = {361138, 101545} }, -- Flying Serpent Kick
    { class = "PALADIN",     ids = {190784} },         -- Divine Steed
    { class = "PRIEST",      ids = {121536} },         -- Angelic Feather
    { class = "PRIEST",      ids = {73325} },          -- Leap of Faith
    { class = "ROGUE",       ids = {36554} },          -- Shadowstep
    { class = "ROGUE",       ids = {195457} },         -- Grappling Hook
    { class = "ROGUE",       ids = {2983} },           -- Sprint
    { class = "SHAMAN",      ids = {79206} },          -- Spiritwalker's Grace
    { class = "SHAMAN",      ids = {192063} },         -- Gust of Wind
    { class = "SHAMAN",      ids = {58875} },          -- Spirit Walk
    { class = "WARLOCK",     ids = {48020} },          -- Demonic Circle: Teleport
    { class = "WARLOCK",     ids = {111400} },         -- Burning Rush
    { class = "WARRIOR",     ids = {6544} },           -- Heroic Leap
}

-- All preset IDs for identifying custom spells
local PRESET_IDS = {}
for _, entry in ipairs(MOVEMENT_PRESETS) do
    for _, id in ipairs(entry.ids) do PRESET_IDS[id] = true end
end

-- Check if a preset spell is enabled (respects DB overrides + defaults)
local function SpellIsEnabled(spellID)
    if DB and DB.spellOverrides then
        local primaryID = spellID
        -- Find the primary ID for this spell (first in its preset group)
        for _, preset in ipairs(MOVEMENT_PRESETS) do
            for _, id in ipairs(preset.ids) do
                if id == spellID then primaryID = preset.ids[1]; break end
            end
        end
        if DB.spellOverrides[primaryID] ~= nil then
            return DB.spellOverrides[primaryID]
        end
    end
    return not MOVEMENT_DEFAULT_OFF[spellID]
end

local DB -- File scoped database variable
local trackedList = {}
local ticker
local mainContainer

-- Cache for instance type check (updated on zone change)
local cachedIsInDungeonOrRaid = false

local function GetSettings()
    if DB then return DB end

    -- Active GravityUI Database integration
    local mainDB = ns.GetDB and ns.GetDB()
    if mainDB then
        -- Guarantee our isolated cooldown data sub-table exists within the SavedVariables
        if type(mainDB.cooldownText) ~= "table" then
            mainDB.cooldownText = {
                enabled = true,
                x = 0,
                y = 18,
                fontSize = 20,
                spacing = 4,
                tickInterval = 0.2,
                growDirection = "DOWN",
                onlyRaidDungeon = false,
                spellsToTrack = {}
            }
        end
        
        -- Fallback check for missing spell tracking specifically (e.g. older versions)
        if not mainDB.cooldownText.spellsToTrack then
            mainDB.cooldownText.spellsToTrack = {}
        end
        
        DB = mainDB.cooldownText
        return DB
    end
    
    -- Absolute Fallback only if the UI Engine fails to find any DB entirely
    if not ns.cooldownTextFallback then
        ns.cooldownTextFallback = {
            enabled = true,
            x = 0,
            y = 18,
            fontSize = 20,
            spacing = 4,
            tickInterval = 0.2,
            growDirection = "DOWN",
            onlyRaidDungeon = false,
            spellsToTrack = {}
        }
    end
    DB = ns.cooldownTextFallback
    return DB
end

local function GetFontPath()
    if ns.Styling and type(ns.Styling.GetFontPath) == "function" then
        return ns.Styling:GetFontPath()
    end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    -- Check DB properly
    local db = ns.GetDB and ns.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    if LSM then return LSM:Fetch("font", fontName) end
    return "Fonts\\FRIZQT__.TTF"
end

local function UpdateInstanceCache()
    local _, instanceType = IsInInstance()
    cachedIsInDungeonOrRaid = instanceType == "party" or instanceType == "raid"
end

local function GetSpellNameFallback(spellID)
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    return spellInfo and spellInfo.name or "Unknown Spell"
end

function CooldownText:Initialize()
    local _, playerClass = UnitClass("player")
    DB = GetSettings()
    UpdateInstanceCache()
    
    -- Ensure Base Frames exist (only once)
    if not mainContainer then
        self:CreateBaseFrames()
    end

    if not DB.enabled then
        mainContainer:Hide()
        if ticker then 
            ticker:Cancel()
            ticker = nil
        end
        return
    end

    mainContainer:Show()

    -- Clean up any active text fields before re-evaluating
    self.fsPool = self.fsPool or {}
    for _, fs in ipairs(self.fsPool) do
        fs:SetText("")
    end

    -- Ensure spellOverrides table exists
    if not DB.spellOverrides then DB.spellOverrides = {} end

    -- 1. Preset movement abilities for current class/spec
    trackedList = {}
    local specIndex = GetSpecialization and GetSpecialization()
    local specID = specIndex and select(1, GetSpecializationInfo(specIndex)) or 0
    local classData = MOVEMENT_ABILITIES[playerClass]
    if classData then
        local specSpells = classData[specID]
        if specSpells then
            local seen = {}
            for _, spellID in ipairs(specSpells) do
                if SpellIsEnabled(spellID) and not seen[spellID] then
                    if C_Spell.GetSpellInfo(spellID) then
                        seen[spellID] = true
                        local spellName = GetSpellNameFallback(spellID)
                        table.insert(trackedList, {
                            spellID = spellID,
                            class = playerClass,
                            runtimeName = "No " .. spellName,
                            isPreset = true,
                        })
                    end
                end
            end
        end
    end

    -- 2. Legacy custom spells (backward compat, skip preset IDs)
    if DB.spellsToTrack then
        for _, spellObj in ipairs(DB.spellsToTrack) do
            if spellObj.class == playerClass and not PRESET_IDS[spellObj.spellID] then
                if C_Spell.GetSpellInfo(spellObj.spellID) then
                    spellObj.runtimeName = (spellObj.text and spellObj.text ~= "") and spellObj.text or GetSpellNameFallback(spellObj.spellID)
                    table.insert(trackedList, spellObj)
                end
            end
        end
    end

    if #trackedList == 0 and ticker then 
        ticker:Cancel() 
        ticker = nil 
    end

    self:Refresh()
    if #trackedList > 0 then
        self:StartTicker()
    end
    self:UpdateCooldowns()
end

function CooldownText:CreateBaseFrames()
    if not DB then DB = GetSettings() end
    mainContainer = CreateFrame("Frame", "GravityUI_CooldownTextContainer", UIParent)
    mainContainer:SetSize(400, 50)
    mainContainer:SetPoint("CENTER", UIParent, "CENTER", (DB and DB.x) or 0, (DB and DB.y) or 18)
    mainContainer:SetFrameStrata("HIGH")
    mainContainer:EnableMouse(false)
    mainContainer:SetMovable(true)
    mainContainer:SetClampedToScreen(true)
    -- Visibility is handled by Initialize/Refresh

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("CooldownText", mainContainer, function(frame, enabled, force) CooldownText:ToggleMover(force) end, "Cooldown Tracker")
    end

    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self.frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self.frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    -- Zone change: update instance cache cheaply
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    -- NOTE: SPELL_UPDATE_COOLDOWN is intentionally NOT registered here.
    -- The ticker handles updates at a controlled rate (default 0.2s) to avoid
    -- the event-storm caused by rapid GCD/cooldown fires during combat.
    self.frame:SetScript("OnEvent", function(selfFrame, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            UpdateInstanceCache()
            C_Timer.After(0.5, function() self:Initialize() end)
        else
            -- Talent / spec change
            C_Timer.After(0.5, function() self:Initialize() end)
        end
    end)
end

function CooldownText:Refresh()
    if not mainContainer or not DB then return end

    mainContainer:ClearAllPoints()
    mainContainer:SetPoint("CENTER", UIParent, "CENTER", DB.x or 0, DB.y or 18)

    local fontPath = GetFontPath()
    self.fsPool = self.fsPool or {}
    
    local growDir = DB.growDirection or "DOWN"
    local anchorPoint = (growDir == "DOWN") and "TOP" or "BOTTOM"
    local modifier = (growDir == "DOWN") and -1 or 1

    local r, g, b, a = 1, 1, 1, 1
    if DB.useClassColor ~= false then
        local _, playerClass = UnitClass("player")
        local color = playerClass and ((CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[playerClass])
        if color then
            r, g, b = color.r, color.g, color.b
        end
    elseif DB.textColor then
        r = DB.textColor[1] or 1
        g = DB.textColor[2] or 1
        b = DB.textColor[3] or 1
        a = DB.textColor[4] or 1
    end

    -- Ensure we have a pool of FontStrings matching our required count
    for i = 1, #trackedList do
        local fs = self.fsPool[i]
        if not fs then
            fs = mainContainer:CreateFontString(nil, "OVERLAY")
            self.fsPool[i] = fs
        end
        fs:SetFont(fontPath, DB.fontSize, "OUTLINE")
        fs:SetJustifyH("CENTER")
        fs:SetTextColor(r, g, b, a)
        
        -- Lock their anchors forever based on index. Moving frames inside combat causes taint.
        fs:ClearAllPoints()
        local yOffset = (i - 1) * (DB.fontSize + DB.spacing)
        fs:SetPoint(anchorPoint, mainContainer, anchorPoint, 0, yOffset * modifier)
        fs:SetText("")
    end

    -- Hide any extra FontStrings
    for i = #trackedList + 1, #self.fsPool do
        self.fsPool[i]:SetText("")
    end

    if not DB.enabled and not isMoverShown then
        mainContainer:Hide()
        return
    end
    mainContainer:Show()

    -- Restart ticker to apply a potentially new tickInterval
    self:StartTicker()
end

function CooldownText:UpdateCooldowns()
    if not mainContainer or not DB then return end
    if not DB.enabled then return end
    
    local shouldHideAll = DB.onlyRaidDungeon and not cachedIsInDungeonOrRaid

    for i, spellObj in ipairs(trackedList) do
        local fs = self.fsPool[i]
        if fs then
            local durationObject = GetSpellCooldownDuration(spellObj.spellID)
            local actualCooldown = durationObject and durationObject:GetRemainingDuration(1) or 0
            
            if shouldHideAll then
                fs:SetAlpha(0)
            else
                -- Build formatted string only when visible
                fs:SetText(strformat("%s: %.1f", spellObj.runtimeName, actualCooldown))
                -- Route through secure C variables without branching on the Tainted Table
                local cdInfo = C_Spell.GetSpellCooldown(spellObj.spellID)
                local state = cdInfo and cdInfo.isOnGCD ~= false
                fs:SetAlphaFromBoolean(state, 0, 1)
            end
        end
    end
end

function CooldownText:StartTicker()
    if not DB then return end
    if ticker then
        ticker:Cancel()
    end
    local interval = DB.tickInterval or 0.2
    ticker = C_Timer.NewTicker(interval, function() self:UpdateCooldowns() end)
end

-- Hook into GravityUI's loading process natively
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function(self, event)
    ns.CooldownText:Initialize()
end)

local isMoverShown = false
local moverFrame

function CooldownText:ToggleMover(forceState)
    if not mainContainer then self:CreateBaseFrames() end
    if not DB then DB = GetSettings() end
    if not mainContainer or not DB then return end
    
    local shouldShow = false
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
        
        moverFrame:SetScript("OnDragStart", function()
            mainContainer:StartMoving()
        end)
        moverFrame:SetScript("OnDragStop", function()
            mainContainer:StopMovingOrSizing()
            local point, relativeTo, relativePoint, xOfs, yOfs = mainContainer:GetPoint()
            DB.x = math.floor((xOfs or 0) + 0.5)
            DB.y = math.floor((yOfs or 0) + 0.5)
        end)
        
        mainContainer:SetMovable(true)
    end
    
    if shouldShow then
        mainContainer:ClearAllPoints()
        mainContainer:SetPoint("CENTER", UIParent, "CENTER", DB.x or 0, DB.y or 18)
        mainContainer:Show()
        moverFrame:Show()
        moverFrame:EnableMouse(true)

        self.fsPool = self.fsPool or {}
        if not self.fsPool[1] then
            local fs = mainContainer:CreateFontString(nil, "OVERLAY")
            local fontPath = GetFontPath()
            fs:SetFont(fontPath, (DB and DB.fontSize) or 20, "OUTLINE")
            fs:SetJustifyH("CENTER")
            fs:SetPoint("CENTER", mainContainer, "CENTER", 0, 0)
            self.fsPool[1] = fs
        end
        
        if not DB.enabled or #trackedList == 0 then
            local r, g, b, a = 1, 1, 1, 1
            if DB.useClassColor ~= false then
                local _, playerClass = UnitClass("player")
                local color = playerClass and ((CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[playerClass])
                if color then r, g, b = color.r, color.g, color.b end
            elseif DB.textColor then
                r = DB.textColor[1] or 1
                g = DB.textColor[2] or 1
                b = DB.textColor[3] or 1
                a = DB.textColor[4] or 1
            end
            self.fsPool[1]:SetTextColor(r, g, b, a)
            self.fsPool[1]:SetText("Cooldown Text Preview: 3.5")
            self.fsPool[1]:SetAlpha(1)
            self.fsPool[1]:Show()
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
            if self.fsPool then
                for _, fs in ipairs(self.fsPool) do
                    fs:SetText("")
                end
            end
            mainContainer:Hide()
        end
    end
end

function CooldownText.AddOptions(parent)
    local GUI = ns.GUI
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    if not GUI then return end
    
    DB = GetSettings()
    local function RefreshSettings() ns.CooldownText:Refresh() end
    local function FullRefresh() ns.CooldownText:Initialize() end
    
    local yOffset = -10
    
    local header = GUI:CreateSectionHeader(content, "Personal Cooldown Tracker")
    header:SetPoint("TOPLEFT", 10, yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 40

    local masterBtn = GUI:CreateCheckbox(content, "Enable Cooldown Tracker", "enabled", DB, FullRefresh)
    masterBtn:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 35
    
    local raidChk = GUI:CreateCheckbox(content, "Only show in Raid/Dungeon", "onlyRaidDungeon", DB, RefreshSettings)
    raidChk:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30

    -- Color Settings
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
    
    -- Font Size Slider
    local fontLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontLabel:SetText("Font Size:")
    fontLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local fontSlider = GUI:CreateSlider(content, "", 8, 36, "fontSize", DB, RefreshSettings, 1)
    fontSlider:SetPoint("LEFT", fontLabel, "RIGHT", 15, 0)
    if fontSlider.slider then fontSlider.slider:SetWidth(150) end
    yOffset = yOffset - 40
    
    -- Spacing Slider
    local spcLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    spcLabel:SetText("Spacing:   ")
    spcLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local spcSlider = GUI:CreateSlider(content, "", 0, 30, "spacing", DB, RefreshSettings, 1)
    spcSlider:SetPoint("LEFT", spcLabel, "RIGHT", 15, 0)
    if spcSlider.slider then spcSlider.slider:SetWidth(150) end
    yOffset = yOffset - 40

    -- Tick Interval Slider
    local tickLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tickLabel:SetText("Refresh Rate (s):")
    tickLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    -- Options from 0.1 to 1.0 seconds
    local tickSlider = GUI:CreateSlider(content, "", 0.1, 1.0, "tickInterval", DB, RefreshSettings, 0.05)
    tickSlider:SetPoint("LEFT", tickLabel, "RIGHT", 15, 0)
    if tickSlider.slider then tickSlider.slider:SetWidth(150) end
    yOffset = yOffset - 40

    -- Grow Direction Dropdown
    local growOptions = {
        { value="DOWN", text="Stack Downwards" },
        { value="UP", text="Stack Upwards" }
    }
    local growLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    growLabel:SetText("Grow Direction:")
    growLabel:SetPoint("TOPLEFT", 15, yOffset - 5)
    local ddGrow = GUI:CreateDropdown(content, "", growOptions, "growDirection", DB, RefreshSettings)
    ddGrow:SetPoint("LEFT", growLabel, "RIGHT", 17, 0)
    if ddGrow.dropdown then ddGrow.dropdown:SetWidth(150) end
    yOffset = yOffset - 40
    
    local btnMover = GUI:CreateButton(content, "Toggle Anchor", 150, 26, function()
        ns.CooldownText:ToggleMover()
    end)
    btnMover:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 50

    -----------------------------------------------------
    -- PRESET MOVEMENT ABILITIES
    -----------------------------------------------------
    local presetHeader = GUI:CreateSectionHeader(content, "Movement Abilities")
    presetHeader:SetPoint("TOPLEFT", 10, yOffset)
    presetHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 35

    local presetInfo = GUI:CreateInfoBox(content, "Toggle which movement abilities to track for your current class. Text automatically shows 'No SpellName' with a cooldown timer.")
    presetInfo:SetPoint("TOPLEFT", 10, yOffset)
    presetInfo:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - (presetInfo:GetHeight() + 10)

    if not DB.spellOverrides then DB.spellOverrides = {} end
    local _, playerClass = UnitClass("player")

    for _, preset in ipairs(MOVEMENT_PRESETS) do
        if preset.class == playerClass then
            local primaryID = preset.ids[1]
            local spellName = GetSpellNameFallback(primaryID)

            -- Seed default if not yet set
            if DB.spellOverrides[primaryID] == nil then
                DB.spellOverrides[primaryID] = not MOVEMENT_DEFAULT_OFF[primaryID]
            end

            local chk = GUI:CreateCheckbox(content, spellName .. "  |cffAAAAAA(" .. primaryID .. ")|r", primaryID, DB.spellOverrides, FullRefresh)
            chk:SetPoint("TOPLEFT", 15, yOffset)
            yOffset = yOffset - 25
        end
    end
    yOffset = yOffset - 15

    -----------------------------------------------------
    -- ADD NEW SPELL (custom)
    -----------------------------------------------------
    local headerSpells = GUI:CreateSectionHeader(content, "Custom Spells")
    headerSpells:SetPoint("TOPLEFT", 10, yOffset)
    headerSpells:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 40

    content.newSpellData = content.newSpellData or { spellID = "", class = "MAGE", text = "" }
    
    local classOptions = {
        { value="DEATHKNIGHT", text="Death Knight" },
        { value="DEMONHUNTER", text="Demon Hunter" },
        { value="DRUID", text="Druid" },
        { value="EVOKER", text="Evoker" },
        { value="HUNTER", text="Hunter" },
        { value="MAGE", text="Mage" },
        { value="MONK", text="Monk" },
        { value="PALADIN", text="Paladin" },
        { value="PRIEST", text="Priest" },
        { value="ROGUE", text="Rogue" },
        { value="SHAMAN", text="Shaman" },
        { value="WARLOCK", text="Warlock" },
        { value="WARRIOR", text="Warrior" },
    }

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
    yOffset = yOffset - 30

    local lblClass = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblClass:SetText("Player Class:")
    lblClass:SetPoint("TOPLEFT", 15, yOffset - 5)
    local ddClass = GUI:CreateDropdown(content, "", classOptions, "class", content.newSpellData, nil)
    ddClass:SetPoint("LEFT", lblClass, "RIGHT", 17, 0)
    if ddClass.dropdown then ddClass.dropdown:SetWidth(120) end
    yOffset = yOffset - 40

    local btnAdd = GUI:CreateButton(content, "Add Tracking", 120, 26, function()
        local sID = tonumber(content.newSpellData.spellID)
        local sClass = content.newSpellData.class
        local sName = content.newSpellData.text
        if sID and sClass then
            table.insert(DB.spellsToTrack, { spellID = sID, class = sClass, text = (sName ~= "" and sName) or nil })
            
            content.newSpellData.spellID = ""
            content.newSpellData.text = ""
            if inputID.editBox then inputID.editBox:SetText("") else inputID:SetText("") end
            if inputName.editBox then inputName.editBox:SetText("") else inputName:SetText("") end
            
            FullRefresh()
            if content.RenderTrackedList then content.RenderTrackedList() end
        end
    end)
    btnAdd:SetPoint("TOPLEFT", 15, yOffset)
    yOffset = yOffset - 50

    -----------------------------------------------------
    -- LIST CURRENT SPELLS
    -----------------------------------------------------
    local headerList = GUI:CreateSectionHeader(content, "Currently Tracked Spells")
    headerList:SetPoint("TOPLEFT", 10, yOffset)
    headerList:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    yOffset = yOffset - 30

    content.spellRows = content.spellRows or {}
    
    content.RenderTrackedList = function()
        for _, row in ipairs(content.spellRows) do
            row:Hide()
        end
        
        local listY = yOffset
        for index, spellItem in ipairs(DB.spellsToTrack) do
            local row = content.spellRows[index]
            if not row then
                row = CreateFrame("Frame", nil, content)
                row:SetSize(400, 24)
                
                local txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                txt:SetPoint("LEFT", 0, 0)
                row.text = txt
                
                local btnDel = GUI:CreateButton(row, "Remove", 70, 20, nil)
                btnDel:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                row.btnDel = btnDel
                
                table.insert(content.spellRows, row)
            end
            
            local displayName = spellItem.text or "Auto-Name"
            row.text:SetText(strformat("[%s]  %s  (|cffAAAAAAID: %d|r)", spellItem.class, displayName, spellItem.spellID))
            
            row.btnDel:SetScript("OnClick", function()
                table.remove(DB.spellsToTrack, index)
                FullRefresh()
                content.RenderTrackedList()
            end)
            
            row:SetPoint("TOPLEFT", 20, listY)
            row:Show()
            listY = listY - 26
        end
        
        local totalHeight = math.abs(listY) + 50
        content:SetHeight(totalHeight)
    end
    
    content.RenderTrackedList()
end