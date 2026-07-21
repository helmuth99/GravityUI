-- GravityUI - Debuff Mirror Module
-- Creates a movable 1:1 copy of Blizzard player debuffs
-- with configurable icon size, spacing, icons-per-row, grow direction.
local ADDON_NAME, ns = ...

-- ============================================================================
-- HELPERS
-- ============================================================================

local function GetDB()
    local db = ns.GetDB and ns.GetDB()
    if not db then return nil end
    return db.debuffMirror
end

local function GetFont()
    if ns.GetFont then
        local path, size, outline = ns.GetFont()
        return path, size, outline
    end
    return "Fonts\\FRIZQT__.TTF", 11, "OUTLINE"
end

-- ============================================================================
-- MODULE
-- ============================================================================

local DebuffMirror = {}
ns.DebuffMirror = DebuffMirror

local mirrorFrame
local iconPool = {}
local activeIcons = {}
local updatePending = false

-- ============================================================================
-- ICON FACTORY
-- ============================================================================

local function CreateMirrorIcon(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(32, 32)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints(f)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- 1px border using a solid overlay texture + inner clip
    f.border = f:CreateTexture(nil, "OVERLAY", nil, 5)
    f.border:SetAllPoints(f)
    f.border:SetColorTexture(0, 0, 0, 1)

    f.innerCover = f:CreateTexture(nil, "OVERLAY", nil, 6)
    f.innerCover:SetPoint("TOPLEFT",     f, "TOPLEFT",      1, -1)
    f.innerCover:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1,  1)
    f.innerCover:SetColorTexture(0, 0, 0, 0)

    -- Coloured dispel-type line (1px inset, drawn on top of the black border)
    f.dispelColor = f:CreateTexture(nil, "OVERLAY", nil, 7)
    f.dispelColor:SetAllPoints(f)
    f.dispelColor:SetColorTexture(0, 0, 0, 0)

    -- Count
    f.count = f:CreateFontString(nil, "OVERLAY")
    f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, 1)
    f.count:SetTextColor(1, 1, 1, 1)
    f.count:SetShadowColor(0, 0, 0, 1)
    f.count:SetShadowOffset(1, -1)

    -- Duration
    f.duration = f:CreateFontString(nil, "OVERLAY")
    f.duration:SetPoint("TOP", f, "TOP", 0, -1)
    f.duration:SetTextColor(1, 1, 1, 1)
    f.duration:SetShadowColor(0, 0, 0, 1)
    f.duration:SetShadowOffset(1, -1)

    f:Hide()
    return f
end

local function AcquireIcon(parent)
    local f = table.remove(iconPool)
    if not f then f = CreateMirrorIcon(parent) else f:SetParent(parent) end
    f:Show()
    return f
end

local function ReleaseIcon(f)
    f:Hide()
    f:ClearAllPoints()
    f.icon:SetTexture(nil)
    f.count:SetText("")
    f.duration:SetText("")
    f.dispelColor:SetColorTexture(0, 0, 0, 0)
    iconPool[#iconPool + 1] = f
end

-- ============================================================================
-- DURATION HELPERS
-- ============================================================================

local function FormatDuration(secs)
    if not secs or secs <= 0 then return "" end
    if secs >= 3600 then return string.format("%dh", math.floor(secs / 3600))
    elseif secs >= 60 then return string.format("%dm", math.floor(secs / 60))
    elseif secs >= 10 then return string.format("%d",  math.floor(secs))
    else                    return string.format("%.1f", secs)
    end
end

local DISPEL_COLORS = {
    Magic   = {0.20, 0.60, 1.00, 1},
    Poison  = {0.00, 0.65, 0.00, 1},
    Disease = {0.60, 0.40, 0.00, 1},
    Curse   = {0.60, 0.00, 1.00, 1},
}

-- ============================================================================
-- LAYOUT
-- ============================================================================

local function LayoutIcons()
    local db = GetDB()
    if not db then return end

    local iconSize = db.iconSize    or 32
    local spacing  = db.spacing     or 4
    local perRow   = db.iconsPerRow or 8
    local growDir  = db.growDirection or "RIGHT"
    local step     = iconSize + spacing
    local fontPath, _, fontOutline = GetFont()

    for idx, ic in ipairs(activeIcons) do
        ic:SetSize(iconSize, iconSize)

        local col = (idx - 1) % perRow
        local row = math.floor((idx - 1) / perRow)
        local x, y

        if growDir == "RIGHT" then
            x =  col * step ; y = -row * step
        elseif growDir == "LEFT" then
            x = -col * step ; y = -row * step
        elseif growDir == "DOWN" then
            x =  col * step ; y = -row * step
        elseif growDir == "UP" then
            x =  col * step ; y =  row * step
        else
            x =  col * step ; y = -row * step
        end

        ic:ClearAllPoints()
        ic:SetPoint("TOPLEFT", mirrorFrame, "TOPLEFT", x, y)

        local fs = math.max(8, math.floor(iconSize * 0.33))
        ic.count:SetFont(fontPath, fs, fontOutline)
        ic.duration:SetFont(fontPath, math.max(7, math.floor(iconSize * 0.28)), fontOutline)
    end
end

-- ============================================================================
-- UPDATE
-- ============================================================================

local function UpdateMirror()
    local db = GetDB()
    if not db or not db.enabled then
        if mirrorFrame then mirrorFrame:Hide() end
        return
    end
    if not mirrorFrame then return end
    mirrorFrame:Show()

    for _, ic in ipairs(activeIcons) do ReleaseIcon(ic) end
    wipe(activeIcons)

    local maxDebuffs = db.maxDebuffs or 16
    local count = 0
    local index = 1

    while count < maxDebuffs do
        local aura = C_UnitAuras.GetDebuffDataByIndex("player", index)
        if not aura or not aura.auraInstanceID then break end

        if aura.icon then
            count = count + 1
            local ic = AcquireIcon(mirrorFrame)
            ic.icon:SetTexture(aura.icon)
            ic.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            if aura.applications and aura.applications > 1 then
                ic.count:SetText(aura.applications) ; ic.count:Show()
            else
                ic.count:SetText("") ; ic.count:Hide()
            end

            if aura.expirationTime and aura.expirationTime > 0 then
                local rem = aura.expirationTime - GetTime()
                ic.duration:SetText(FormatDuration(rem)) ; ic.duration:Show()
            else
                ic.duration:SetText("") ; ic.duration:Hide()
            end

            local dc = aura.dispelName and DISPEL_COLORS[aura.dispelName]
            if dc then
                ic.dispelColor:SetColorTexture(dc[1], dc[2], dc[3], dc[4])
            else
                ic.dispelColor:SetColorTexture(0, 0, 0, 0)
            end

            activeIcons[#activeIcons + 1] = ic
        end

        index = index + 1
        if index > 64 then break end
    end

    LayoutIcons()

    -- Resize container
    local iconSize = db.iconSize    or 32
    local spacing  = db.spacing     or 4
    local perRow   = db.iconsPerRow or 8
    local n = #activeIcons
    if n == 0 then mirrorFrame:SetSize(1, 1) ; return end
    local cols = math.min(n, perRow)
    local rows = math.ceil(n / perRow)
    mirrorFrame:SetSize(
        cols * (iconSize + spacing) - spacing,
        rows * (iconSize + spacing) - spacing
    )
end

local function ScheduleUpdate()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.15, function()
        updatePending = false
        UpdateMirror()
    end)
end

-- ============================================================================
-- DURATION TICKER
-- ============================================================================

local durationTicker
local function StartDurationTicker()
    if durationTicker then return end
    durationTicker = C_Timer.NewTicker(0.2, function()
        local db = GetDB()
        if not db or not db.enabled or #activeIcons == 0 then return end
        local now = GetTime()
        local index = 1
        for _, ic in ipairs(activeIcons) do
            local aura = C_UnitAuras.GetDebuffDataByIndex("player", index)
            if aura and aura.expirationTime and aura.expirationTime > 0 then
                local rem = aura.expirationTime - now
                if rem > 0 then
                    ic.duration:SetText(FormatDuration(rem)) ; ic.duration:Show()
                else
                    ic.duration:SetText("") ; ic.duration:Hide()
                end
            end
            index = index + 1
            if index > 64 then break end
        end
    end)
end

-- ============================================================================
-- ORIGINAL FRAME VISIBILITY
-- ============================================================================

local function ApplyOriginalVisibility()
    local db = GetDB()
    if not DebuffFrame or not db then return end

    local shouldHide = db.enabled and db.hideOriginal
    DebuffFrame:SetShown(not shouldHide)

    if not DebuffFrame._gMirrorHooked then
        DebuffFrame._gMirrorHooked = true
        hooksecurefunc(DebuffFrame, "Show", function(self)
            local d = GetDB()
            if d and d.enabled and d.hideOriginal then self:Hide() end
        end)
    end
end

-- ============================================================================
-- MIRROR FRAME (DRAGGABLE CONTAINER)
-- ============================================================================

local function SavePosition()
    local db = GetDB()
    if not db or not mirrorFrame then return end
    local point, _, relPoint, x, y = mirrorFrame:GetPoint()
    db.position = { point = point or "CENTER", relPoint = relPoint or "CENTER", x = x or 0, y = y or -200 }
end

local function RestorePosition()
    local db = GetDB()
    if not db or not mirrorFrame then return end
    local pos = db.position or {}
    mirrorFrame:ClearAllPoints()
    mirrorFrame:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or -200)
end

local function CreateMirrorFrame()
    if mirrorFrame then return end

    mirrorFrame = CreateFrame("Frame", "GravityUI_DebuffMirror", UIParent)
    mirrorFrame:SetFrameStrata("MEDIUM")
    mirrorFrame:SetSize(200, 40)
    mirrorFrame:SetClampedToScreen(true)
    mirrorFrame:SetMovable(true)
    mirrorFrame:EnableMouse(false)
    mirrorFrame:RegisterForDrag("LeftButton")
    mirrorFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mirrorFrame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() ; SavePosition() end)

    RestorePosition()

    -- Mover registration
    if ns.Movers then
        ns.Movers:Register("DebuffMirror", mirrorFrame, function(frame, show)
            frame:EnableMouse(show and true or false)
            if show then
                if not frame.dragLabel then
                    local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                    bg:SetAllPoints(frame)
                    bg:SetFrameLevel(frame:GetFrameLevel() - 1)
                    frame.dragLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    frame.dragLabel:SetPoint("BOTTOM", frame, "TOP", 0, 3)
                    frame.dragLabel:SetText("|cff00c8ffDebuff Mirror|r (Drag)")
                    frame.dragLabel:SetShadowColor(0, 0, 0, 1)
                    frame.dragLabel:SetShadowOffset(1, -1)
                    frame.dragLabelBg = bg
                end
                frame.dragLabel:Show()
            else
                if frame.dragLabel then frame.dragLabel:Hide() end
            end
        end, "Debuff Mirror")
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function DebuffMirror:Refresh()
    CreateMirrorFrame()
    local db = GetDB()
    if not db then return end
    ApplyOriginalVisibility()
    if db.enabled then
        UpdateMirror()
        StartDurationTicker()
    else
        if mirrorFrame then mirrorFrame:Hide() end
    end
end

function DebuffMirror:ApplySettings()
    self:Refresh()
end

-- Mover state
local moverActive = false

function DebuffMirror:ToggleMover()
    CreateMirrorFrame()
    if not mirrorFrame then return end

    moverActive = not moverActive

    if moverActive then
        -- Show the frame with placeholder icons so it's draggable
        mirrorFrame:Show()
        mirrorFrame:EnableMouse(true)

        -- Release real icons and show placeholders
        for _, ic in ipairs(activeIcons) do ReleaseIcon(ic) end
        wipe(activeIcons)

        local db = GetDB()
        local iconSize  = (db and db.iconSize)    or 32
        local spacing   = (db and db.spacing)     or 4
        local perRow    = (db and db.iconsPerRow) or 8
        local count     = math.min((db and db.maxDebuffs) or 16, perRow * 2) -- 2 rows of placeholders

        for i = 1, count do
            local ic = AcquireIcon(mirrorFrame)
            ic.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            ic.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            ic.count:SetText("") ; ic.count:Hide()
            ic.duration:SetText("") ; ic.duration:Hide()
            ic.dispelColor:SetColorTexture(0, 0, 0, 0)
            activeIcons[#activeIcons + 1] = ic
        end

        LayoutIcons()

        -- Resize to show all placeholders
        local cols = math.min(count, perRow)
        local rows = math.ceil(count / perRow)
        mirrorFrame:SetSize(
            cols * (iconSize + spacing) - spacing,
            rows * (iconSize + spacing) - spacing
        )

        -- Label
        if not mirrorFrame.dragLabel then
            mirrorFrame.dragLabel = mirrorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            mirrorFrame.dragLabel:SetPoint("BOTTOM", mirrorFrame, "TOP", 0, 4)
            mirrorFrame.dragLabel:SetText("|cff00c8ffDebuff Mirror|r  — Drag me!")
            mirrorFrame.dragLabel:SetShadowColor(0, 0, 0, 1)
            mirrorFrame.dragLabel:SetShadowOffset(1, -1)
        end
        mirrorFrame.dragLabel:Show()

        print("|cff00c8ffGravityUI|r Debuff Mirror: |cffFFCC00Mover aktiv|r — verschiebe den Frame, dann klick nochmal auf Toggle Mover.")
    else
        -- Done moving: restore real debuffs
        mirrorFrame:EnableMouse(false)
        if mirrorFrame.dragLabel then mirrorFrame.dragLabel:Hide() end
        self:Refresh()
        print("|cff00c8ffGravityUI|r Debuff Mirror: |cff00ff00Position gespeichert.|r")
    end
end

function DebuffMirror:ResetPosition()
    CreateMirrorFrame()
    if not mirrorFrame then return end
    mirrorFrame:ClearAllPoints()
    mirrorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    SavePosition()
    print("|cff00c8ffGravityUI|r Debuff Mirror: Position zurückgesetzt.")
end

-- ============================================================================
-- EVENTS
-- ============================================================================

local evtFrame = CreateFrame("Frame")
evtFrame:RegisterUnitEvent("UNIT_AURA", "player")
evtFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
evtFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        CreateMirrorFrame()
        C_Timer.After(1.0, function() DebuffMirror:Refresh() end)
    elseif event == "UNIT_AURA" then
        local db = GetDB()
        if db and db.enabled then ScheduleUpdate() end
    end
end)
