-- GravityUI - Death Announcer Module
-- Displays custom on-screen alerts and optional audio/chat notifications when party/raid members die.
-- Fully compliant with WoW 12.0+ (Uses unit state events, zero CombatLog dependency, 100% combat safe).
local ADDON_NAME, ns = ...

local DeathAnnouncer = {}
ns.DeathAnnouncer = DeathAnnouncer

-- ============================================================================
-- CONSTANTS & HELPERS
-- ============================================================================
local LSM = LibStub("LibSharedMedia-3.0", true)

local function GetLSM()
    return ns.LSM or LibStub("LibSharedMedia-3.0", true)
end

local function GetSettings()
    local db = ns.GetDB()
    if not db then return nil end
    if not db.deathAnnouncer then
        db.deathAnnouncer = {
            enabled = true,
            inDungeon = true,
            inRaid = true,
            inGroup = true,
            useClassColor = true,
            messageFormat = "%s died!",
            fontSize = 24,
            font = "Gravity",
            fontOutline = "OUTLINE",
            textColor = { 1, 1, 1, 1 },
            duration = 3.0,
            x = 0,
            y = 140,
            soundEnabled = false,
            soundFile = "Warning",
            soundChannel = "Master",
            chatAnnouncement = "DISABLED",
        }
    end
    return db.deathAnnouncer
end

local function FormatClassColoredName(name, classFilename)
    if not name or name == "" then return "Unknown" end
    if not classFilename then return name end

    local color = (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classFilename)) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename])
    if not color then return name end

    local hex = color.colorStr
    if not hex and color.GenerateHexColor then
        hex = color:GenerateHexColor()
    end
    if not hex then
        local r = math.floor((color.r or 1) * 255 + 0.5)
        local g = math.floor((color.g or 1) * 255 + 0.5)
        local b = math.floor((color.b or 1) * 255 + 0.5)
        hex = string.format("ff%02x%02x%02x", r, g, b)
    end

    return string.format("|c%s%s|r", hex, name)
end

-- ============================================================================
-- FRAME & ANIMATION POOL
-- ============================================================================
local container
local mover
local lines = {}
local MAX_LINES = 5
local LINE_HEIGHT = 32
local isDeadState = {}   -- [guid] = boolean (true = dead, false = alive)
local recentDeaths = {}  -- [guid] = timestamp debounce

local function CreateAlertFrames()
    if container then return end

    local s = GetSettings()
    local x = (s and s.x) or 0
    local y = (s and s.y) or 140

    -- 1. Main Container
    container = CreateFrame("Frame", "GravityUI_DeathAnnouncerContainer", UIParent)
    container:SetSize(450, (LINE_HEIGHT + 4) * MAX_LINES)
    container:SetPoint("TOP", UIParent, "CENTER", x, y + (LINE_HEIGHT / 2))
    container:SetFrameStrata("HIGH")
    container:SetFrameLevel(60)
    container:Hide()

    -- 2. Mover Frame
    mover = CreateFrame("Frame", "GravityUI_DeathAnnouncerMover", UIParent, "BackdropTemplate")
    mover:SetSize(320, LINE_HEIGHT)
    mover:SetPoint("TOP", container, "TOP", 0, 0)
    mover:SetFrameStrata("DIALOG")
    mover:SetFrameLevel(100)
    mover:SetMovable(true)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:Hide()

    mover:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    mover:SetBackdropColor(0, 0, 0, 0.75)
    mover:SetBackdropBorderColor(0, 0.75, 1, 1)

    local moverTitle = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moverTitle:SetPoint("CENTER", 0, 0)
    moverTitle:SetText("|cFF30D1FFGravityUI|r Death Announcer")
    if ns.GUI and ns.GUI.SetFont then
        ns.GUI:SetFont(moverTitle, 12, "OUTLINE")
    end

    mover:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)

    mover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local centerX, centerY = self:GetCenter()
        local screenCenterX, screenCenterY = UIParent:GetCenter()
        if centerX and screenCenterX then
            local newX = math.floor(centerX - screenCenterX + 0.5)
            local newY = math.floor(centerY - screenCenterY + 0.5)
            local settings = GetSettings()
            if settings then
                settings.x = newX
                settings.y = newY
            end
            container:ClearAllPoints()
            container:SetPoint("TOP", UIParent, "CENTER", newX, newY + (LINE_HEIGHT / 2))
            mover:ClearAllPoints()
            mover:SetPoint("TOP", container, "TOP", 0, 0)
        end
    end)

    -- Register with Movers system if present
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("DeathAnnouncer", mover, function(frame, show)
            DeathAnnouncer.ToggleMover(show)
        end, "Death Announcer")
    end

    -- 3. Pre-allocated Line Pool
    for i = 1, MAX_LINES do
        local line = CreateFrame("Frame", nil, container)
        line:SetSize(450, LINE_HEIGHT)
        line:SetPoint("TOP", container, "TOP", 0, -((i - 1) * (LINE_HEIGHT + 4)))
        line:Hide()

        local fs = line:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        fs:SetPoint("CENTER", line, "CENTER", 0, 0)
        fs:SetJustifyH("CENTER")
        line.text = fs

        -- Animation Group: Fade In -> Hold -> Fade Out
        local ag = line:CreateAnimationGroup()
        line.ag = ag

        local fadeIn = ag:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.15)
        fadeIn:SetOrder(1)

        local hold = ag:CreateAnimation("Alpha")
        hold:SetFromAlpha(1)
        hold:SetToAlpha(1)
        hold:SetDuration(3.0)
        hold:SetOrder(2)
        line.holdAnim = hold

        local fadeOut = ag:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.4)
        fadeOut:SetOrder(3)

        ag:SetScript("OnFinished", function()
            line:Hide()
            line.isActive = false
            -- Hide container if no lines remain active
            local anyActive = false
            for _, l in ipairs(lines) do
                if l.isActive then anyActive = true; break end
            end
            if not anyActive and not (mover and mover:IsShown()) then
                container:Hide()
            end
        end)

        lines[i] = line
    end

    DeathAnnouncer.container = container
    DeathAnnouncer.mover = mover
end

-- ============================================================================
-- APPEARANCE & SETTINGS
-- ============================================================================
function DeathAnnouncer.ApplySettings()
    if not container then CreateAlertFrames() end
    local s = GetSettings()
    if not s then return end

    -- Position
    container:ClearAllPoints()
    container:SetPoint("TOP", UIParent, "CENTER", s.x or 0, (s.y or 140) + (LINE_HEIGHT / 2))
    if mover then
        mover:ClearAllPoints()
        mover:SetPoint("TOP", container, "TOP", 0, 0)
    end

    -- Font
    local defaultFont = "Gravity"
    if ns.GetDB and ns.GetDB() and ns.GetDB().general and ns.GetDB().general.font then
        defaultFont = ns.GetDB().general.font
    end

    local fontPath = "Fonts/FRIZQT__.TTF"
    local lsm = GetLSM()
    if lsm then
        local fetched = lsm:Fetch("font", s.font or defaultFont)
        if fetched then fontPath = fetched end
    end

    local fontSize = s.fontSize or 24
    local fontOutline = s.fontOutline or "OUTLINE"
    local r, g, b, a = 1, 1, 1, 1
    if s.textColor then
        r, g, b, a = s.textColor[1] or 1, s.textColor[2] or 1, s.textColor[3] or 1, s.textColor[4] or 1
    end

    for _, line in ipairs(lines) do
        if line.text then
            line.text:SetFont(fontPath, fontSize, fontOutline)
            line.text:SetTextColor(r, g, b, a)
        end
        if line.holdAnim then
            line.holdAnim:SetDuration(s.duration or 3.0)
        end
    end
end

-- ============================================================================
-- AUDIO & CHAT HELPERS
-- ============================================================================
local function PlayDeathSound(s)
    if not s or not s.soundEnabled then return end
    local soundFile = s.soundFile
    if not soundFile or soundFile == "None" or soundFile == "" then return end

    local lsm = GetLSM()
    local soundPath = lsm and lsm:Fetch("sound", soundFile)
    local channel = s.soundChannel or "Master"

    if soundPath then
        PlaySoundFile(soundPath, channel)
    else
        PlaySound(SOUNDKIT.RAID_WARNING or 8959, channel)
    end
end

local function SafeSendChat(msg, channel)
    pcall(function()
        if C_ChatInfo and C_ChatInfo.SendChatMessage then
            C_ChatInfo.SendChatMessage(msg, channel)
        elseif SendChatMessage then
            SendChatMessage(msg, channel)
        end
    end)
end

local function SendDeathChatMessage(s, formattedText, plainName)
    if not s or not s.chatAnnouncement or s.chatAnnouncement == "DISABLED" then return end

    local channel = s.chatAnnouncement
    local msg = (plainName or "A group member") .. " died!"

    if channel == "SELF" then
        ns.Print(formattedText)
    elseif channel == "PARTY" then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE or 2) then
            SafeSendChat(msg, "INSTANCE_CHAT")
        elseif IsInRaid() then
            SafeSendChat(msg, "RAID")
        elseif IsInGroup() then
            SafeSendChat(msg, "PARTY")
        else
            ns.Print(formattedText)
        end
    elseif channel == "RAID" then
        if IsInRaid() then
            SafeSendChat(msg, "RAID")
        elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE or 2) then
            SafeSendChat(msg, "INSTANCE_CHAT")
        elseif IsInGroup() then
            SafeSendChat(msg, "PARTY")
        else
            ns.Print(formattedText)
        end
    elseif channel == "AUTO" then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE or 2) then
            SafeSendChat(msg, "INSTANCE_CHAT")
        elseif IsInRaid() then
            SafeSendChat(msg, "RAID")
        elseif IsInGroup() then
            SafeSendChat(msg, "PARTY")
        else
            ns.Print(formattedText)
        end
    end
end

-- ============================================================================
-- DISPLAY ALERT
-- ============================================================================
function DeathAnnouncer.ShowAlert(formattedText)
    if not container then CreateAlertFrames() end
    DeathAnnouncer.ApplySettings()

    -- Shift existing lines down
    for i = MAX_LINES, 2, -1 do
        local prev = lines[i - 1]
        local curr = lines[i]
        if prev.isActive then
            curr.text:SetText(prev.text:GetText())
            curr.isActive = true
            curr:Show()
            curr.ag:Stop()
            curr.ag:Play()
        else
            curr:Hide()
            curr.isActive = false
        end
    end

    -- Assign line 1 to the new death
    local line1 = lines[1]
    line1.text:SetText(formattedText)
    line1.isActive = true
    line1:Show()
    line1.ag:Stop()
    line1.ag:Play()

    container:Show()
end

-- ============================================================================
-- INSTANCE & GROUP CONTEXT CHECK
-- ============================================================================
local function IsContextAllowed(s)
    if not s or not s.enabled then return false end

    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "party" then
            return s.inDungeon ~= false
        elseif instanceType == "raid" then
            return s.inRaid ~= false
        elseif instanceType == "arena" or instanceType == "pvp" or instanceType == "scenario" then
            return s.inGroup ~= false
        end
    end

    -- Open world / Delves
    if IsInGroup() or IsInRaid() then
        return s.inGroup ~= false
    end

    return false
end

-- ============================================================================
-- DEATH EVENT LOGIC (WoW 12.0+ Compliant Unit State Tracking)
-- ============================================================================
local function OnUnitDied(unit, guid)
    local s = GetSettings()
    if not s or not s.enabled then return end
    if not IsContextAllowed(s) then return end

    -- Debounce duplicate triggers within 2.0s per GUID
    local now = GetTime()
    if recentDeaths[guid] and (now - recentDeaths[guid] < 2.0) then
        return
    end
    recentDeaths[guid] = now

    -- Cleanup old debounce entries
    for g, t in pairs(recentDeaths) do
        if now - t > 10 then recentDeaths[g] = nil end
    end

    -- Resolve unit name and class
    local plainName = UnitName(unit)
    local _, classFilename = UnitClass(unit)

    if (not plainName or plainName == "") and guid then
        local _, engClass, _, _, _, n = GetPlayerInfoByGUID(guid)
        if n and n ~= "" then plainName = n end
        if engClass then classFilename = engClass end
    end

    plainName = plainName or "Unknown"
    plainName = plainName:match("^([^-]+)") or plainName

    local displayName = plainName
    if s.useClassColor ~= false and classFilename then
        displayName = FormatClassColoredName(plainName, classFilename)
    end

    local formatStr = s.messageFormat
    if not formatStr or formatStr == "" or not formatStr:find("%%s") then
        formatStr = "%s died!"
    end

    local alertText = string.format(formatStr, displayName)

    -- Trigger Visual, Audio & Chat outputs
    DeathAnnouncer.ShowAlert(alertText)
    PlayDeathSound(s)
    SendDeathChatMessage(s, alertText, plainName)
end

local function ProcessUnit(unit)
    if not unit or not UnitExists(unit) then return end
    local guid = UnitGUID(unit)
    if not guid then return end

    -- Check if dead/ghost, exclude Feign Death, check connected (NPC followers in follower dungeons don't count as disconnected)
    local isConnected = not UnitIsPlayer(unit) or UnitIsConnected(unit)
    local isDead = (UnitIsDead(unit) or UnitIsGhost(unit)) and not UnitIsFeignDeath(unit) and isConnected
    local wasDead = isDeadState[guid]

    if isDead and wasDead == false then
        isDeadState[guid] = true
        OnUnitDied(unit, guid)
    elseif not isDead then
        isDeadState[guid] = false
    end
end

local function ScanRoster(initialScan)
    local currentGroupGUIDs = {}

    local function CheckUnit(unit)
        if not UnitExists(unit) then return end
        local guid = UnitGUID(unit)
        if not guid then return end
        currentGroupGUIDs[guid] = true

        local isConnected = not UnitIsPlayer(unit) or UnitIsConnected(unit)
        local isDead = (UnitIsDead(unit) or UnitIsGhost(unit)) and not UnitIsFeignDeath(unit) and isConnected

        if initialScan or isDeadState[guid] == nil then
            isDeadState[guid] = isDead
        else
            local wasDead = isDeadState[guid]
            if isDead and wasDead == false then
                isDeadState[guid] = true
                OnUnitDied(unit, guid)
            elseif not isDead then
                isDeadState[guid] = false
            end
        end
    end

    CheckUnit("player")
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            CheckUnit("raid" .. i)
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            CheckUnit("party" .. i)
        end
    end

    -- Clean up GUIDs no longer in group
    for guid in pairs(isDeadState) do
        if not currentGroupGUIDs[guid] then
            isDeadState[guid] = nil
        end
    end
end

-- ============================================================================
-- EVENT LISTENER (Standard public events only)
-- ============================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_FLAGS")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("PLAYER_UNGHOST")

eventFrame:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        if not container then CreateAlertFrames() end
        DeathAnnouncer.ApplySettings()
        ScanRoster(true)
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        ScanRoster(false)
        return
    end

    if event == "PLAYER_DEAD" then
        ProcessUnit("player")
        return
    end

    if event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        local guid = UnitGUID("player")
        if guid then isDeadState[guid] = false end
        return
    end

    if event == "UNIT_FLAGS" or event == "UNIT_HEALTH" then
        if unit then
            if unit == "player" or unit:find("^party%d+$") or unit:find("^raid%d+$") then
                ProcessUnit(unit)
            end
        end
        return
    end
end)

-- ============================================================================
-- TEST MODE & MOVER
-- ============================================================================
local testIndex = 0
local TEST_PLAYERS = {
    { name = "Shadowpriest", class = "PRIEST" },
    { name = "Protwarrior",  class = "WARRIOR" },
    { name = "Frostmage",    class = "MAGE" },
    { name = "Restodruid",   class = "DRUID" },
    { name = "Havocdh",      class = "DEMONHUNTER" },
    { name = "Blooddk",      class = "DEATHKNIGHT" },
    { name = "Retpaladin",   class = "PALADIN" },
    { name = "Mistweaver",   class = "MONK" },
    { name = "EleShaman",    class = "SHAMAN" },
    { name = "DestroLock",   class = "WARLOCK" },
    { name = "PresEvoker",   class = "EVOKER" },
    { name = "Beastmaster",  class = "HUNTER" },
    { name = "OutlawRogue",  class = "ROGUE" },
}

function DeathAnnouncer.TestMode(force)
    if not container then CreateAlertFrames() end
    local s = GetSettings()

    if force == false then
        for _, line in ipairs(lines) do
            line.ag:Stop()
            line:Hide()
            line.isActive = false
        end
        container:Hide()
        return
    end

    testIndex = (testIndex % #TEST_PLAYERS) + 1
    local testData = TEST_PLAYERS[testIndex]

    local displayName = testData.name
    if not s or s.useClassColor ~= false then
        displayName = FormatClassColoredName(testData.name, testData.class)
    end

    local formatStr = (s and s.messageFormat) or "%s died!"
    if not formatStr:find("%%s") then formatStr = "%s died!" end
    local alertText = string.format(formatStr, displayName)

    DeathAnnouncer.ShowAlert(alertText)
    PlayDeathSound(s)
    SendDeathChatMessage(s, alertText, testData.name)
end

function DeathAnnouncer.ToggleMover(force)
    if not mover then CreateAlertFrames() end
    local show = (force ~= nil) and force or (not mover:IsShown())
    if force == false then show = false end

    if show then
        mover:Show()
        container:Show()
        if not lines[1].isActive then
            DeathAnnouncer.TestMode(true)
        end
    else
        mover:Hide()
        local anyActive = false
        for _, l in ipairs(lines) do
            if l.isActive then anyActive = true; break end
        end
        if not anyActive then container:Hide() end
    end
end

function DeathAnnouncer.Initialize()
    CreateAlertFrames()
    DeathAnnouncer.ApplySettings()
    ScanRoster(true)
end
