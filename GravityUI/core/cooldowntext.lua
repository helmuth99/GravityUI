local ADDON_NAME, ns = ...

local CooldownText = {}
ns.CooldownText = CooldownText

local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration

local DB -- File scoped database variable
local trackedList = {}
local ticker
local mainContainer

local function GetSettings()
    if DB then return DB end

    -- Active GravityUI Database integration
    local mainDB = ns.GetDB and ns.GetDB()
    if mainDB then
        -- Guarantee our isolated cooldown data sub-table exists within the SavedVariables
        if type(mainDB.cooldownText) ~= "table" then
            mainDB.cooldownText = {
                x = 0,
                y = 18,
                fontSize = 20,
                spacing = 4,
                tickInterval = 0.1,
                growDirection = "DOWN",
                onlyRaidDungeon = false,
                spellsToTrack = {
                    { spellID = 1953,   class = "MAGE", text = "No Blink on cd" },
                    { spellID = 212653, class = "MAGE", text = "No Shimmer" },
                    { spellID = 1234796, class = "DEMONHUNTER", text = "No Shift" },
                }
            }
        end
        
        -- Fallback check for missing spell tracking specifically (e.g. older versions)
        if not mainDB.cooldownText.spellsToTrack then
            mainDB.cooldownText.spellsToTrack = {
                { spellID = 1953,   class = "MAGE", text = "No Blink" },
                { spellID = 212653, class = "MAGE", text = "No Shimmer" },
                { spellID = 1234796, class = "DEMONHUNTER", text = "No Shift" },
            }
        end
        
        DB = mainDB.cooldownText
        return DB
    end
    
    -- Absolute Fallback only if the UI Engine fails to find any DB entirely
    if not ns.cooldownTextFallback then
        ns.cooldownTextFallback = {
            x = 0,
            y = 18,
            fontSize = 20,
            spacing = 4,
            tickInterval = 0.1,
            growDirection = "DOWN",
            onlyRaidDungeon = false,
            spellsToTrack = {
                { spellID = 1953,   class = "MAGE", text = "No Blink" },
                { spellID = 212653, class = "MAGE", text = "No Shimmer" },
                { spellID = 1234796, class = "DEMONHUNTER", text = "No Shift" },
            }
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

local function IsInDungeonOrRaid()
    local _, instanceType = IsInInstance()
    return instanceType == "party" or instanceType == "raid"
end

local function GetSpellNameFallback(spellID)
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    return spellInfo and spellInfo.name or "Unknown Spell"
end

function CooldownText:Initialize()
    local _, playerClass = UnitClass("player")
    DB = GetSettings()

    -- Clean up any active text fields before re-evaluating
    self.fsPool = self.fsPool or {}
    for _, fs in ipairs(self.fsPool) do
        fs:SetText("")
    end

    -- 1. Identify which spells to track based on Class and Learning status
    trackedList = {}
    if DB.spellsToTrack then
        for _, spellObj in ipairs(DB.spellsToTrack) do
            if spellObj.class == playerClass then
                if C_SpellBook.IsSpellKnown(spellObj.spellID) then
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

    -- 2. Create the main Container Frame
    if not mainContainer then
        mainContainer = CreateFrame("Frame", "GravityUI_CooldownTextContainer", UIParent)
        mainContainer:SetSize(400, 50)
        mainContainer:SetFrameStrata("LOW")
        mainContainer:Show()

        self.frame = CreateFrame("Frame")
        self.frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
        self.frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        self.frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        self.frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        self.frame:SetScript("OnEvent", function(selfFrame, event)
            if event == "SPELL_UPDATE_COOLDOWN" then
                self:UpdateCooldowns()
            else
                C_Timer.After(0.5, function() self:Initialize() end)
            end
        end)
    end

    self:Refresh()
    if #trackedList > 0 then
        self:StartTicker()
    end
    self:UpdateCooldowns()
end

function CooldownText:Refresh()
    if not mainContainer or not DB then return end
    
    mainContainer:ClearAllPoints()
    mainContainer:SetPoint("CENTER", UIParent, "CENTER", DB.x, DB.y)

    local fontPath = GetFontPath()
    self.fsPool = self.fsPool or {}
    
    local growDir = DB.growDirection or "DOWN"
    local anchorPoint = (growDir == "DOWN") and "TOP" or "BOTTOM"
    local modifier = (growDir == "DOWN") and -1 or 1

    -- Ensure we have a pool of FontStrings matching our required count
    for i = 1, #trackedList do
        local fs = self.fsPool[i]
        if not fs then
            fs = mainContainer:CreateFontString(nil, "OVERLAY")
            self.fsPool[i] = fs
        end
        fs:SetFont(fontPath, DB.fontSize, "OUTLINE")
        fs:SetJustifyH("CENTER")
        fs:SetTextColor(1, 1, 1, 1)
        
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

    -- Restart ticker to apply a potentially new tickInterval
    self:StartTicker()
end

function CooldownText:UpdateCooldowns()
    if not mainContainer or not DB then return end
    
    local shouldHideAll = DB.onlyRaidDungeon and not IsInDungeonOrRaid()

    for i, spellObj in ipairs(trackedList) do
        local fs = self.fsPool[i]
        if fs then
            local durationObject = GetSpellCooldownDuration(spellObj.spellID)
            local actualCooldown = durationObject and durationObject:GetRemainingDuration(1) or 0
            local cdString = string.format("%.1f", actualCooldown)
            
            -- Assign text unconditionally, acting exactly like test.lua does (bypassing logic taints)
            fs:SetText(string.format("%s: %s", spellObj.runtimeName, cdString))
            
            if shouldHideAll then
                -- Hide entirely when tracking rule fails or spell is strictly off cooldown
                fs:SetAlpha(0)
            else
                -- Route perfectly through secure C variables without branching on the Tainted Table
                local state = GetSpellCooldown(spellObj.spellID).isOnGCD ~= false
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
    local interval = DB.tickInterval or 0.1
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

function CooldownText:ToggleMover()
    if not mainContainer or not DB then return end
    
    if not moverFrame then
        moverFrame = CreateFrame("Frame", nil, mainContainer, "BackdropTemplate")
        moverFrame:SetAllPoints(mainContainer)
        moverFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        moverFrame:SetBackdropColor(0, 1, 0, 0.5)
        moverFrame:SetBackdropBorderColor(0, 1, 0, 1)
        moverFrame:EnableMouse(true)
        moverFrame:RegisterForDrag("LeftButton")
        moverFrame:SetMovable(true)
        
        local text = moverFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Cooldown Tracker\nDrag to Move")
        
        moverFrame:SetScript("OnDragStart", function()
            mainContainer:StartMoving()
        end)
        moverFrame:SetScript("OnDragStop", function()
            mainContainer:StopMovingOrSizing()
            local point, relativeTo, relativePoint, xOfs, yOfs = mainContainer:GetPoint()
            DB.x = xOfs
            DB.y = yOfs
        end)
        
        mainContainer:SetMovable(true)
    end
    
    isMoverShown = not isMoverShown
    
    if isMoverShown then
        moverFrame:Show()
    else
        moverFrame:Hide()
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
    
    local raidChk = GUI:CreateCheckbox(content, "Only show in Raid/Dungeon", "onlyRaidDungeon", DB, RefreshSettings)
    raidChk:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 30
    
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
    -- Options from 0.05 to 1.0 seconds
    local tickSlider = GUI:CreateSlider(content, "", 0.05, 1.0, "tickInterval", DB, RefreshSettings, 0.05)
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
    -- ADD NEW SPELL
    -----------------------------------------------------
    local headerSpells = GUI:CreateSectionHeader(content, "Add a Spell to Track")
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
            row.text:SetText(string.format("[%s]  %s  (|cffAAAAAAID: %d|r)", spellItem.class, displayName, spellItem.spellID))
            
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