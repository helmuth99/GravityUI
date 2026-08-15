---------------------------------------------------------------------------
-- GravityUI – Healer Mana Tracker
--
-- Displays Spec-Icon + Name + Mana% for every healer in the current
-- party or raid. Only visible while grouped; ticker starts only when
-- healers are detected (zero overhead when solo).
--
-- Mover-Integration: registers with ns.Movers so the container frame
-- can be repositioned via Main → Edit Mode.
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...

ns.HealerMana = ns.HealerMana or {}
local HM = ns.HealerMana

-- ============================================================================
-- UPVALUES
-- ============================================================================
local UnitExists             = UnitExists
local UnitIsConnected        = UnitIsConnected
local UnitClass              = UnitClass
local UnitName               = UnitName
local UnitPowerPercent       = UnitPowerPercent
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGUID               = UnitGUID
local IsInRaid               = IsInRaid
local IsInGroup              = IsInGroup
local GetNumGroupMembers     = GetNumGroupMembers
local NotifyInspect          = NotifyInspect
local select = select
local pairs  = pairs
local ipairs = ipairs
local issecretvalue = issecretvalue
local wipe   = wipe
local format = string.format

-- 12.1 Namespaced API fallbacks
local GetSpecialization = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
local GetSpecializationInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
local GetSpecializationInfoByID = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoByID) or GetSpecializationInfoByID
local GetInspectSpecialization = (C_SpecializationInfo and C_SpecializationInfo.GetInspectSpecialization) or GetInspectSpecialization

local DEFAULT_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local FALLBACK_ICON = 135915  -- question mark
local INSPECT_DELAY = 0.05
local MANA_TICK     = 0.5     -- seconds between mana updates

-- Preview specs: Resto Druid, Holy Paladin, Resto Shaman
local PREVIEW_SPECS = { 105, 65, 264 }
local PREVIEW_NAMES = { "Healer", "Support", "Backup" }

-- ============================================================================
-- STATE
-- ============================================================================
HM.healerFrames   = {}
HM.currentHealers = {}
HM.inspectQueue   = {}
HM.specCache      = {}
HM.ticker         = nil
HM.isPreview      = false
HM.containerFrame = nil

-- ============================================================================
-- HELPERS
-- ============================================================================
local function GetDB()
    local db = ns.GetDB and ns.GetDB()
    return db and db.screenindicators and db.screenindicators.healerMana
end

local function GetClassColor(classToken)
    if not classToken then return 1, 1, 1 end
    if C_ClassColor and C_ClassColor.GetClassColor then
        local c = C_ClassColor.GetClassColor(classToken)
        if c then return c.r, c.g, c.b end
    end
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function GetUnitManaPercent(unit)
    if UnitPowerPercent then
        local ok, pct = pcall(UnitPowerPercent, unit, Enum.PowerType.Mana, true,
            CurveConstants and CurveConstants.ScaleTo100 or nil)
        if ok and pct ~= nil then return pct end
    end
    if UnitPowerMax and UnitPower then
        local maxMana = UnitPowerMax(unit, Enum.PowerType.Mana)
        if maxMana and maxMana > 0 then
            return (UnitPower(unit, Enum.PowerType.Mana) / maxMana) * 100
        end
    end
    return 0
end

local function IsSecret(val)
    return issecretvalue and issecretvalue(val)
end

local function IsUnitDrinking(unit)
    if not UnitExists(unit) then return false end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return false end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
        if not ok or not aura or IsSecret(aura) then break end

        local spellId = aura.spellId
        if spellId and not IsSecret(spellId) then
            if spellId == 29166 or spellId == 64901 or spellId == 16191 then
                return true
            end
        end

        local name = aura.name
        if name and not IsSecret(name) and type(name) == "string" then
            local lower = string.lower(name)
            if string.find(lower, "drink") or string.find(lower, "trink") or string.find(lower, "boisson") or string.find(lower, "boire") or string.find(lower, "beber") or string.find(lower, "refreshment") then
                return true
            end
        end

        local icon = aura.icon
        if icon and not IsSecret(icon) then
            if icon == 132794 or icon == 132800 or icon == 132805 or icon == 134071 or icon == 134062 or icon == 134073 or icon == 4638734 or icon == 4638735 then
                return true
            end
        end
    end
    return false
end

-- ============================================================================
-- MANA DISPLAY
-- ============================================================================
function HM:UpdateManaDisplay(frame, unit, connected, isRegen)
    local db = GetDB()
    if not db then return end
    if connected then
        local pct = GetUnitManaPercent(unit)
        frame.icon:SetVertexColor(1, 1, 1)
        if isRegen then
            -- Actively regenerating (drinking, Innervate, mana pot etc.) → green + Drinking status
            frame.mana:SetTextColor(0.3, 1, 0.4)
            frame.mana:SetText(format("%.0f%%  |cff55ff77Drinking|r", pct or 0))
        else
            local col = db.highManaColor or { 0.4, 0.8, 1 }
            frame.mana:SetTextColor(col[1], col[2], col[3])
            frame.mana:SetText(format("%.0f%%", pct or 0))
        end
    else
        frame.mana:SetTextColor(0.5, 0.5, 0.5)
        frame.mana:SetText("OFFLINE")
        frame.icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================
function HM:CreateHealerFrame(index)
    local db       = GetDB()
    local iconSize = (db and db.iconSize)   or 24
    local frameW   = (db and db.frameWidth) or 160
    local fontSize = (db and db.fontSize)   or 12

    local frame = CreateFrame("Frame", "GravityUI_HealerMana_" .. index, self.containerFrame, "BackdropTemplate")
    frame:SetSize(frameW, iconSize)

    -- Icon background
    frame.iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.iconFrame:SetSize(iconSize, iconSize)
    frame.iconFrame:SetPoint("LEFT", 0, 0)
    frame.iconFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.iconFrame:SetBackdropColor(0, 0, 0, 1)
    frame.iconFrame:SetBackdropBorderColor(0, 0, 0, 1)

    -- Spec icon
    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 1, -1)
    frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Name
    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetPoint("BOTTOMLEFT", frame.iconFrame, "RIGHT", 4, 1)
    frame.name:SetJustifyH("LEFT")
    frame.name:SetFont(DEFAULT_FONT, math.max(fontSize - 1, 8), "OUTLINE")

    -- Mana %
    frame.mana = frame:CreateFontString(nil, "OVERLAY")
    frame.mana:SetPoint("TOPLEFT", frame.iconFrame, "RIGHT", 4, -1)
    frame.mana:SetJustifyH("LEFT")
    frame.mana:SetFont(DEFAULT_FONT, fontSize, "OUTLINE")

    frame:Hide()
    return frame
end

function HM:GetHealerFrame(index)
    if not self.healerFrames[index] then
        self.healerFrames[index] = self:CreateHealerFrame(index)
    end
    return self.healerFrames[index]
end

-- ============================================================================
-- CONTAINER
-- ============================================================================
function HM:CreateContainer()
    if self.containerFrame then return self.containerFrame end
    local db      = GetDB()
    local iconSize = (db and db.iconSize)   or 24
    local frameW   = (db and db.frameWidth) or 160

    local f = CreateFrame("Frame", "GravityUI_HealerMana_Container", UIParent)
    f:SetSize(frameW, iconSize)
    f:SetClampedToScreen(true)

    -- Restore saved position
    local pos = db and db.position
    if pos and pos.point then
        f:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end

    -- Drag support (mouse only enabled during mover/preview mode)
    f:SetMovable(true)
    f:EnableMouse(false)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        local dbb = GetDB()
        if dbb then
            dbb.position = { point = p, relativePoint = rp, x = x, y = y }
        end
    end)

    self.containerFrame = f

    -- Register with Mover system
    if ns.Movers then
        ns.Movers:Register("HealerMana", f, function(frame, show)
            if show then
                HM:ShowPreview()
            else
                HM:HidePreview()
            end
        end, "Healer Mana")
    end

    return f
end

-- ============================================================================
-- LAYOUT
-- ============================================================================
function HM:UpdateContainerSize()
    if not self.containerFrame then return end
    local db      = GetDB()
    local iconSize = (db and db.iconSize)    or 24
    local spacing  = (db and db.frameSpacing) or 4
    local frameW   = (db and db.frameWidth)  or 160
    local count    = #self.currentHealers
    if count == 0 then
        self.containerFrame:SetSize(frameW, iconSize)
        return
    end
    local total = (iconSize * count) + (spacing * math.max(count - 1, 0))
    self.containerFrame:SetSize(frameW, total)
end

function HM:PositionFrames()
    local db      = GetDB()
    local growDown = (db == nil or db.growDown ~= false)
    local iconSize = (db and db.iconSize)    or 24
    local spacing  = (db and db.frameSpacing) or 4

    for i, healer in ipairs(self.currentHealers) do
        local frame = self.healerFrames[healer.frameIndex]
        if frame then
            frame:ClearAllPoints()
            local offset = (i - 1) * (iconSize + spacing)
            if growDown then
                frame:SetPoint("TOPLEFT", self.containerFrame, "TOPLEFT", 0, -offset)
            else
                frame:SetPoint("BOTTOMLEFT", self.containerFrame, "BOTTOMLEFT", 0, offset)
            end
        end
    end
end

-- ============================================================================
-- HEALER DATA
-- ============================================================================
function HM:AddHealer(unit, frameIndex)
    local name = UnitName(unit)
    if IsSecret(name) then name = "Healer" else name = name or "Healer" end
    local _, classToken = UnitClass(unit)
    local guid = UnitGUID(unit)
    self.currentHealers[#self.currentHealers + 1] = {
        unit       = unit,
        guid       = guid,
        name       = name,
        class      = classToken,
        connected  = UnitIsConnected(unit),
        frameIndex = frameIndex,
        specID     = self.specCache[guid],
        lastMana   = nil,
        isRegen    = false,
    }
end

function HM:UpdateHealerFrame(healer)
    if not healer then return end
    local frame = self:GetHealerFrame(healer.frameIndex)
    local icon
    if healer.specID then
        icon = select(4, GetSpecializationInfoByID(healer.specID))
    else
        self:QueueInspect(healer)
    end
    frame.icon:SetTexture(icon or FALLBACK_ICON)
    local r, g, b = GetClassColor(healer.class)
    frame.name:SetText(healer.name)
    frame.name:SetTextColor(r, g, b)
    self:UpdateManaDisplay(frame, healer.unit, healer.connected, healer.isRegen)
    frame:Show()
end

function HM:GetHealerByGUID(guid)
    for _, h in ipairs(self.currentHealers) do
        if h.guid == guid then return h end
    end
end

-- ============================================================================
-- INSPECT QUEUE
-- ============================================================================
function HM:ClearInspectQueue()
    wipe(self.inspectQueue)
    self.currentInspect = nil
end

function HM:QueueInspect(healer)
    if not healer or not healer.guid then return end
    for _, q in ipairs(self.inspectQueue) do if q.guid == healer.guid then return end end
    self.inspectQueue[#self.inspectQueue + 1] = healer
    self:ProcessInspectQueue()
end

function HM:ProcessInspectQueue()
    if self.currentInspect then return end
    if #self.inspectQueue == 0 then return end
    local healer = self.inspectQueue[1]
    if not healer or not UnitExists(healer.unit) or not CanInspect(healer.unit) then
        table.remove(self.inspectQueue, 1)
        C_Timer.After(0.1, function() HM:ProcessInspectQueue() end)
        return
    end
    self.currentInspect = healer.guid
    NotifyInspect(healer.unit)
    C_Timer.After(2, function()
        if HM.currentInspect == healer.guid then
            HM.currentInspect = nil
            HM:ProcessInspectQueue()
        end
    end)
end

function HM:OnInspectReady(guid)
    if self.currentInspect ~= guid then return end
    self.currentInspect = nil
    for i, q in ipairs(self.inspectQueue) do
        if q.guid == guid then table.remove(self.inspectQueue, i); break end
    end
    local healer = self:GetHealerByGUID(guid)
    if not healer or not UnitExists(healer.unit) then
        C_Timer.After(INSPECT_DELAY, function() HM:ProcessInspectQueue() end)
        return
    end
    local specID = GetInspectSpecialization and GetInspectSpecialization(healer.unit)
    if specID and specID > 0 then
        if guid and not IsSecret(guid) then
            self.specCache[guid] = specID
        end
        healer.specID = specID
        self:UpdateHealerFrame(healer)
    end
    C_Timer.After(INSPECT_DELAY, function() HM:ProcessInspectQueue() end)
end

-- ============================================================================
-- FIND HEALERS & UPDATE
-- ============================================================================
function HM:HideAllFrames()
    wipe(self.currentHealers)
    self:ClearInspectQueue()
    for _, f in pairs(self.healerFrames) do f:Hide() end
    if self.containerFrame then self.containerFrame:Hide() end
    self:StopTicker()
end

function HM:FindHealers()
    if self.isPreview then return end
    local db = GetDB()
    if not db or not db.enabled then self:HideAllFrames(); return end

    local inRaid  = IsInRaid()
    local inGroup = IsInGroup()
    if not inGroup then self:HideAllFrames(); return end

    -- Only-if-healer gate (12.1 safe role detection)
    if db.onlyIfHealer then
        local spec = ns.GetSpecialization and ns.GetSpecialization() or (GetSpecialization and GetSpecialization())
        local role
        if spec and GetSpecializationInfo then
            role = select(5, GetSpecializationInfo(spec))
        elseif spec and GetSpecializationRole then
            role = GetSpecializationRole(spec)
        end
        if role ~= "HEALER" then self:HideAllFrames(); return end
    end

    if inRaid and not db.enableInRaid then self:HideAllFrames(); return end
    if not inRaid then
        local _, instanceType = IsInInstance()
        if instanceType == "party" and not db.enableInDungeon then
            self:HideAllFrames(); return
        end
    end

    local prev  = #self.currentHealers
    wipe(self.currentHealers)
    local maxH  = inRaid and (db.maxHealers or 3) or 1
    local count = 0

    if inRaid then
        for i = 1, GetNumGroupMembers() do
            if count >= maxH then break end
            local unit = "raid" .. i
            if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "HEALER" then
                count = count + 1
                self:AddHealer(unit, count)
            end
        end
    else
        for i = 1, 4 do
            if count >= maxH then break end
            local unit = "party" .. i
            if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "HEALER" then
                count = count + 1
                self:AddHealer(unit, count)
            end
        end
    end

    if count == 0 then self:HideAllFrames(); return end

    for i = count + 1, prev do
        if self.healerFrames[i] then self.healerFrames[i]:Hide() end
    end

    self:EnsureContainer()
    self:UpdateContainerSize()
    self:PositionFrames()
    for _, h in ipairs(self.currentHealers) do self:UpdateHealerFrame(h) end
    self.containerFrame:Show()
    self:StartTicker()
end

function HM:UpdateMana()
    if self.isPreview then return end
    for _, h in ipairs(self.currentHealers) do
        local frame = self.healerFrames[h.frameIndex]
        if frame and frame:IsShown() then
            h.connected = UnitIsConnected(h.unit)
            local curMana = UnitPowerPercent(h.unit, Enum.PowerType.Mana, true,
                CurveConstants and CurveConstants.ScaleTo100 or nil)

            local isRegen = false
            local isDrinking = IsUnitDrinking(h.unit)
            if isDrinking then
                isRegen = true
            elseif curMana and not IsSecret(curMana) and h.lastMana and not IsSecret(h.lastMana) and type(curMana) == "number" and type(h.lastMana) == "number" then
                isRegen = h.connected and (curMana > h.lastMana) and (curMana < 100)
            end

            h.isRegen = isRegen
            h.lastMana = curMana
            self:UpdateManaDisplay(frame, h.unit, h.connected, h.isRegen)
        end
    end
end

-- ============================================================================
-- TICKER
-- ============================================================================
function HM:StartTicker()
    if self.ticker then return end
    self.ticker = C_Timer.NewTicker(MANA_TICK, function() HM:UpdateMana() end)
end

function HM:StopTicker()
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
end

-- ============================================================================
-- PREVIEW (Edit Mode)
-- ============================================================================
function HM:ShowPreview()
    self.isPreview = true
    self:EnsureContainer()
    self:UpdateStyles()
    local db   = GetDB()
    local maxH = math.min((db and db.maxHealers) or 3, #PREVIEW_SPECS)

    -- Hide all existing frames first so unused ones disappear
    for _, f in pairs(self.healerFrames) do f:Hide() end

    wipe(self.currentHealers)
    for i = 1, maxH do
        self.currentHealers[i] = {
            unit       = "player",
            guid       = "preview_" .. i,
            name       = PREVIEW_NAMES[i] or ("Healer " .. i),
            class      = "PRIEST",
            connected  = true,
            frameIndex = i,
            specID     = PREVIEW_SPECS[i],
        }
    end

    self:UpdateContainerSize()
    self:PositionFrames()

    for i, h in ipairs(self.currentHealers) do
        local frame = self:GetHealerFrame(h.frameIndex)
        local icon  = select(4, GetSpecializationInfoByID(h.specID))
        frame.icon:SetTexture(icon or FALLBACK_ICON)
        frame.icon:SetVertexColor(1, 1, 1)
        frame.name:SetText(h.name)
        frame.name:SetTextColor(GetClassColor(h.class))
        if i == 1 then
            frame.mana:SetText("52%  |cff55ff77Drinking|r")
            frame.mana:SetTextColor(0.3, 1, 0.4)
        else
            frame.mana:SetText("88%")
            frame.mana:SetTextColor(0.4, 0.8, 1)
        end
        frame:Show()
    end

    self.containerFrame:Show()
    if ns.Movers then ns.Movers:ApplyEditModeStyle(self.containerFrame, true) end
    self.containerFrame:EnableMouse(true)
end

function HM:HidePreview()
    self.isPreview = false
    self.containerFrame:EnableMouse(false)
    if ns.Movers then ns.Movers:ApplyEditModeStyle(self.containerFrame, false) end
    self:HideAllFrames()
    self:FindHealers()
end

function HM:EnsureContainer()
    if not self.containerFrame then self:CreateContainer() end
end

-- ============================================================================
-- EVENTS
-- ============================================================================
local eventFrame = CreateFrame("Frame")

local HEALER_EVENTS = {
    "GROUP_ROSTER_UPDATE",
    "PARTY_MEMBER_ENABLE",
    "PARTY_MEMBER_DISABLE",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_SPECIALIZATION_CHANGED",
    "INSPECT_READY",
}

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "INSPECT_READY" then
        HM:OnInspectReady(...)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit == "player" then
            HM:FindHealers()
        else
            local guid = unit and UnitGUID(unit)
            if guid then HM.specCache[guid] = nil end
            local h = guid and HM:GetHealerByGUID(guid)
            if h then h.specID = nil; HM:QueueInspect(h) end
        end
    else
        HM:FindHealers()
    end
end)

-- ============================================================================
-- ENABLE / DISABLE / APPLY / STYLES
-- ============================================================================
function HM:UpdateStyles()
    local db = GetDB()
    if not db then return end

    local iconSize = db.iconSize or 24
    local frameW   = db.frameWidth or 160
    local fontSize = db.fontSize or 12

    for _, frame in pairs(self.healerFrames) do
        if frame then
            frame:SetSize(frameW, iconSize)
            if frame.iconFrame then
                frame.iconFrame:SetSize(iconSize, iconSize)
            end
            if frame.name then
                frame.name:SetFont(DEFAULT_FONT, math.max(fontSize - 1, 8), "OUTLINE")
            end
            if frame.mana then
                frame.mana:SetFont(DEFAULT_FONT, fontSize, "OUTLINE")
            end
        end
    end

    if self.containerFrame then
        self:UpdateContainerSize()
        self:PositionFrames()
    end
end

function HM:Enable()
    for _, ev in ipairs(HEALER_EVENTS) do eventFrame:RegisterEvent(ev) end
    self:EnsureContainer()
    self:UpdateStyles()
    if self.isPreview then
        self:ShowPreview()
    else
        self:FindHealers()
    end
end

function HM:Disable()
    for _, ev in ipairs(HEALER_EVENTS) do eventFrame:UnregisterEvent(ev) end
    self:HideAllFrames()
end

function HM:ApplySettings()
    local db = GetDB()
    if db and db.enabled then
        self:Enable()
    else
        self:Disable()
    end
end

ns.RefreshHealerMana = function()
    HM:ApplySettings()
end

-- Toggle Mover (called from settings page button)
function HM:ToggleMover()
    self:EnsureContainer()
    if self.isPreview then
        self:HidePreview()
    else
        self:ShowPreview()
    end
end

-- ============================================================================
-- BOOTSTRAP
-- ============================================================================
local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("PLAYER_LOGIN")
bootstrap:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    HM:ApplySettings()
end)
