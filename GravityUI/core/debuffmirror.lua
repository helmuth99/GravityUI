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

-- Cache für expirationTime/duration: wird direkt aus dem UNIT_AURA-Payload befüllt
-- bevor der 0.15s-Timer abläuft, damit M+/Raid-Debuffs ihre Duration behalten.
-- key = auraInstanceID (Zahl), value = {expirationTime, duration}
local auraTimeCache = {}

-- ============================================================================
-- POSITION HELPERS  (declared early so all later functions can call them)
-- ============================================================================

local function SavePosition()
    local db = GetDB()
    if not db or not mirrorFrame then return end
    local x = mirrorFrame:GetLeft()
    local y = mirrorFrame:GetTop()
    if x and y then
        db.position = { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = x, y = y }
    else
        local point, _, relPoint, ox, oy = mirrorFrame:GetPoint()
        db.position = { point = point or "TOPLEFT", relPoint = relPoint or "BOTTOMLEFT", x = ox or 100, y = oy or 500 }
    end
end

local function RestorePosition()
    local db = GetDB()
    if not db or not mirrorFrame then return end
    local pos = db.position or {}
    mirrorFrame:ClearAllPoints()
    mirrorFrame:SetPoint(
        pos.point    or "CENTER",
        UIParent,
        pos.relPoint or "CENTER",
        pos.x or 0,
        pos.y or -200
    )
end


-- ============================================================================
-- ICON FACTORY
-- ============================================================================

local function CreateMirrorIcon(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(32, 32)

    -- Icon fills the whole frame
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints(f)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- 4 separate 1px border textures (same technique as buffborders.lua)
    -- These sit OVER the icon on OVERLAY, so the icon stays fully visible.
    f.borderTop = f:CreateTexture(nil, "OVERLAY", nil, 6)
    f.borderTop:SetPoint("TOPLEFT",  f, "TOPLEFT",  0,  0)
    f.borderTop:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0,  0)
    f.borderTop:SetHeight(1)
    f.borderTop:SetColorTexture(0, 0, 0, 1)

    f.borderBottom = f:CreateTexture(nil, "OVERLAY", nil, 6)
    f.borderBottom:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, 0)
    f.borderBottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.borderBottom:SetHeight(1)
    f.borderBottom:SetColorTexture(0, 0, 0, 1)

    f.borderLeft = f:CreateTexture(nil, "OVERLAY", nil, 6)
    f.borderLeft:SetPoint("TOPLEFT",    f, "TOPLEFT",    0,  0)
    f.borderLeft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0,  0)
    f.borderLeft:SetWidth(1)
    f.borderLeft:SetColorTexture(0, 0, 0, 1)

    f.borderRight = f:CreateTexture(nil, "OVERLAY", nil, 6)
    f.borderRight:SetPoint("TOPRIGHT",    f, "TOPRIGHT",    0, 0)
    f.borderRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.borderRight:SetWidth(1)
    f.borderRight:SetColorTexture(0, 0, 0, 1)

    -- Dispel-type colour: thin coloured line on top of the black border
    -- (reuses the top edge as a coloured indicator)
    f.dispelColor = f:CreateTexture(nil, "OVERLAY", nil, 7)
    f.dispelColor:SetPoint("TOPLEFT",  f, "TOPLEFT",  0,  0)
    f.dispelColor:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0,  0)
    f.dispelColor:SetHeight(2)
    f.dispelColor:SetColorTexture(0, 0, 0, 0)

    -- Default fallback font (overridden by LayoutIcons on every display)
    local defaultFont = ns.FONT_PATH or "Fonts\\FRIZQT__.TTF"

    -- Count (bottom-right)
    f.count = f:CreateFontString(nil, "OVERLAY")
    f.count:SetFont(defaultFont, 11, "OUTLINE")
    f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, 1)
    f.count:SetTextColor(1, 1, 1, 1)
    f.count:SetShadowColor(0, 0, 0, 1)
    f.count:SetShadowOffset(1, -1)

    -- Duration (top-center)
    f.duration = f:CreateFontString(nil, "OVERLAY")
    f.duration:SetFont(defaultFont, 10, "OUTLINE")
    f.duration:SetPoint("TOP", f, "TOP", 0, -1)
    f.duration:SetTextColor(1, 1, 1, 1)
    f.duration:SetShadowColor(0, 0, 0, 1)
    f.duration:SetShadowOffset(1, -1)
    f.duration:Hide() -- superseded by the Cooldown frame below

    -- Cooldown frame: engine-driven swipe + countdown text.
    -- SetCooldown() is a C function that accepts secret numbers directly,
    -- avoiding any Lua arithmetic on Blizzard's protected aura values.
    f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cooldown:SetAllPoints(f)
    f.cooldown:SetDrawSwipe(true)
    f.cooldown:SetDrawBling(false)
    f.cooldown:SetDrawEdge(false)
    f.cooldown:SetHideCountdownNumbers(false) -- let OmniCC / native countdown show
    f.cooldown:SetReverse(false)
    f.cooldown:SetFrameLevel(f:GetFrameLevel() + 1)

    f:Hide()

    -- SetPassThroughButtons is protected: cannot be called during combat.
    -- We guard here and flag any frame created during lockdown so it can
    -- be fixed up by the PLAYER_REGEN_ENABLED handler below.
    if not InCombatLockdown() then
        f:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton")
    else
        f._needsPassThrough = true
    end

    -- Tooltip: OnEnter/OnLeave are always registered but gated on db.showTooltip
    f:SetScript("OnEnter", function(self)
        local db = GetDB()
        if not db or not db.showTooltip then return end
        if not self.auraInstanceID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnitAuraByAuraInstanceID("player", self.auraInstanceID)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function(self)
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)

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
    f:EnableMouse(false)
    f.icon:SetTexture(nil)
    f.count:SetText("")
    f.duration:SetText("")
    f.dispelColor:SetColorTexture(0, 0, 0, 0)
    f.dispelColor:Hide()
    f.cooldown:Clear()
    f.auraInstanceID = nil
    iconPool[#iconPool + 1] = f
end

-- ============================================================================
-- DURATION HELPERS
-- ============================================================================

local function FormatDuration(secs)
    if not secs or secs <= 0 then return "" end
    -- Use math.ceil to match Blizzard's timer display:
    -- 395s → ceil(395/60)=7 → "7m", not floor=6 → "6m"
    if secs >= 3600 then return string.format("%dh", math.ceil(secs / 3600))
    elseif secs >= 60 then return string.format("%dm", math.ceil(secs / 60))
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

    local iconSize   = db.iconSize      or 32
    local spacing    = db.spacing       or 4
    local perRow     = db.iconsPerRow   or 8
    local growDir    = db.growDirection or "RIGHT"
    local step       = iconSize + spacing

    -- Use the module-local GetFont() which safely wraps ns.GetFont
    local fontPath   = GetFont()
    local durFontSize = db.textFontSize  or math.max(8, math.floor(iconSize * 0.33))
    local cntFontSize = db.countFontSize or math.max(9, math.floor(iconSize * 0.40))
    local outline    = db.textOutline   or "OUTLINE"
    local showCount  = db.showCount  ~= false
    local showDur    = db.showDuration ~= false
    local showTooltip = db.showTooltip == true
    local cAnchor     = db.countAnchor    or "BOTTOMRIGHT"
    local dAnchor    = db.durationAnchor or "TOP"

    for idx, ic in ipairs(activeIcons) do
        ic:SetSize(iconSize, iconSize)

        local col = (idx - 1) % perRow
        local row = math.floor((idx - 1) / perRow)
        local x, y

        if growDir == "RIGHT" then
            x =  col * step ; y = -row * step
        elseif growDir == "LEFT" then
            x = -col * step ; y = -row * step
        elseif growDir == "UP" then
            x =  col * step ; y =  row * step
        else -- DOWN or default
            x =  col * step ; y = -row * step
        end

        ic:ClearAllPoints()
        ic:SetPoint("TOPLEFT", mirrorFrame, "TOPLEFT", x, y)
        -- SetPassThroughButtons is called once at icon-creation time (safe, out-of-combat).
        -- Only toggle EnableMouse here; calling SetPassThroughButtons here would
        -- trigger ADDON_ACTION_BLOCKED when LayoutIcons runs during combat.
        ic:EnableMouse(showTooltip)

        -- Count
        ic.count:SetFont(fontPath, cntFontSize, outline)
        ic.count:ClearAllPoints()
        ic.count:SetPoint(cAnchor, ic, cAnchor, 1, 1)
        if showCount then ic.count:Show() else ic.count:Hide() end

        -- Duration
        ic.duration:SetFont(fontPath, math.max(7, durFontSize), outline)
        ic.duration:ClearAllPoints()
        -- Map anchor string to position + offset
        local dAnchorMap = {
            TOP    = {"TOP",    0, -1},
            BOTTOM = {"BOTTOM", 0,  2},
            CENTER = {"CENTER", 0,  0},
        }
        local dm = dAnchorMap[dAnchor] or {"TOP", 0, -1}
        ic.duration:SetPoint(dm[1], ic, dm[1], dm[2], dm[3])
        if showDur then ic.duration:Show() else ic.duration:Hide() end
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

    local maxDebuffs  = db.maxDebuffs    or 16
    local showCount   = db.showCount    ~= false
    local showDur     = db.showDuration ~= false  -- opt-out (konsistent mit LayoutIcons)
    local blacklist   = db.blacklist    or {}
    local count = 0
    local index = 1

    while count < maxDebuffs do
        local aura = C_UnitAuras.GetDebuffDataByIndex("player", index)
        if not aura or not aura.auraInstanceID then break end

        if aura.icon then
            -- Skip blacklisted debuffs (check by name and by spellId string).
            -- aura.name and aura.spellId may be secret values (Blizzard API protection),
            -- which cannot be used as table keys. pcall guards against that crash.
            local isBlacklisted = false
            local ok, val
            ok, val = pcall(function() return blacklist[aura.name] end)
            if ok and val then isBlacklisted = true end
            if not isBlacklisted and aura.spellId then
                ok, val = pcall(function() return blacklist[tostring(aura.spellId)] end)
                if ok and val then isBlacklisted = true end
            end
            if not isBlacklisted then
                count = count + 1
                local ic = AcquireIcon(mirrorFrame)
                ic.icon:SetTexture(aura.icon)
                ic.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                -- Stack count.
                -- applications is a secret number; SetText() is a C function
                -- that accepts secret values directly — no Lua comparison needed.
                if showCount then
                    pcall(function()
                        if aura.applications and aura.applications > 1 then
                            ic.count:SetText(aura.applications)
                            ic.count:Show()
                        else
                            ic.count:SetText("") ; ic.count:Hide()
                        end
                    end)
                else
                    ic.count:SetText("") ; ic.count:Hide()
                end

                -- Duration: zuerst Cache prüfen (direkt aus UNIT_AURA-Payload befüllt),
                -- dann Fallback auf aura-Felder. C-Level SetCooldown akzeptiert secret values.
                if showDur then
                    pcall(function()
                        local expT, dur
                        -- Cache hat Vorrang (zuverlässiger in M+/Raid)
                        local cached = aura.auraInstanceID and auraTimeCache[aura.auraInstanceID]
                        if cached then
                            expT = cached[1]
                            dur  = cached[2]
                        else
                            expT = aura.expirationTime
                            dur  = aura.duration
                        end
                        if expT and expT > 0 and dur and dur > 0 then
                            ic.cooldown:SetCooldown(expT - dur, dur)
                        else
                            ic.cooldown:Clear()
                        end
                    end)
                else
                    ic.cooldown:Clear()
                end

                -- aura.dispelName is a secret string; indexing DISPEL_COLORS
                -- with it causes "cannot be indexed with secret keys". pcall guards.
                local dc
                if aura.dispelName then
                    pcall(function() dc = DISPEL_COLORS[aura.dispelName] end)
                end
                if dc then
                    ic.dispelColor:SetColorTexture(dc[1], dc[2], dc[3], dc[4])
                    ic.dispelColor:Show()
                else
                    ic.dispelColor:SetColorTexture(0, 0, 0, 0)
                    ic.dispelColor:Hide()
                end

                -- Store for tooltip lookup on hover
                ic.auraInstanceID = aura.auraInstanceID

                activeIcons[#activeIcons + 1] = ic
            end -- if not isBlacklisted
        end -- if aura.icon

        index = index + 1
        if index > 64 then break end
    end

    LayoutIcons()

    -- Resize container to fit current icons
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
    -- Note: NO RestorePosition here. TOPLEFT anchor means the frame grows
    -- right/down from its fixed top-left corner. That is the correct behaviour.
end

local function ScheduleUpdate(immediate)
    if immediate then
        -- Sofort-Update (z.B. bei isFullUpdate in M+/Raid-Encounter-Start)
        updatePending = false
        UpdateMirror()
        return
    end
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.05, function()  -- 0.05s statt 0.15s: schneller, aber noch im selben Frame-Batch
        updatePending = false
        UpdateMirror()
    end)
end

-- Duration display is handled entirely by each icon's Cooldown frame
-- (engine-driven; no ticker needed). Stub kept for call-site compatibility.
local function StartDurationTicker() end

-- ============================================================================
-- ORIGINAL FRAME VISIBILITY
-- ============================================================================

local function ApplyOriginalVisibility()
    local db = GetDB()
    if not DebuffFrame or not db then return end

    local shouldHide = db.enabled and db.hideOriginal

    -- Guard: DebuffFrame:SetShown can interact with protected frames in combat.
    -- Defer visibility change to out-of-combat if necessary.
    if InCombatLockdown() then
        -- Register a one-shot PLAYER_REGEN_ENABLED to apply after combat
        if not DebuffFrame._gMirrorCombatPending then
            DebuffFrame._gMirrorCombatPending = true
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            f:SetScript("OnEvent", function(self)
                self:UnregisterAllEvents()
                DebuffFrame._gMirrorCombatPending = nil
                ApplyOriginalVisibility()
            end)
        end
        return
    end

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

    -- Mover registration: toggleFunc is called with (frame, enabled, force)
    -- by both the Blizzard Edit-Mode checkbox AND the GravityUI Edit Mode panel.
    if ns.Movers then
        ns.Movers:Register("DebuffMirror", mirrorFrame, function(frame, show)
            DebuffMirror:ShowMoverPreview(show)
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

-- ShowMoverPreview: shared helper used by toggleFunc AND ToggleMover()
-- show=true  → display placeholder icons, make frame draggable
-- show=false → hide placeholders, restore real debuffs
function DebuffMirror:ShowMoverPreview(show)
    CreateMirrorFrame()
    if not mirrorFrame then return end

    if show then
        mirrorFrame:Show()
        mirrorFrame:EnableMouse(true)

        -- Swap to placeholder icons
        for _, ic in ipairs(activeIcons) do ReleaseIcon(ic) end
        wipe(activeIcons)

        local db = GetDB()
        local iconSize = (db and db.iconSize)    or 32
        local spacing  = (db and db.spacing)     or 4
        local perRow   = (db and db.iconsPerRow) or 8
        local count    = math.min((db and db.maxDebuffs) or 16, perRow * 2)

        for i = 1, count do
            local ic = AcquireIcon(mirrorFrame)
            ic.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            ic.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            ic.count:SetText("")    ; ic.count:Hide()
            ic.duration:SetText("") ; ic.duration:Hide()
            ic.dispelColor:SetColorTexture(0, 0, 0, 0)
            activeIcons[#activeIcons + 1] = ic
        end

        LayoutIcons()

        local cols = math.min(count, perRow)
        local rows = math.ceil(count / perRow)
        mirrorFrame:SetSize(
            cols * (iconSize + spacing) - spacing,
            rows * (iconSize + spacing) - spacing
        )

        -- Drag label
        if not mirrorFrame.dragLabel then
            mirrorFrame.dragLabel = mirrorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            mirrorFrame.dragLabel:SetPoint("BOTTOM", mirrorFrame, "TOP", 0, 4)
            mirrorFrame.dragLabel:SetText("|cff00c8ffDebuff Mirror|r  — Drag me!")
            mirrorFrame.dragLabel:SetShadowColor(0, 0, 0, 1)
            mirrorFrame.dragLabel:SetShadowOffset(1, -1)
        end
        mirrorFrame.dragLabel:Show()
    else
        mirrorFrame:EnableMouse(false)
        if mirrorFrame.dragLabel then mirrorFrame.dragLabel:Hide() end
        self:Refresh()
    end
end

-- Mover state
local moverActive = false

function DebuffMirror:ToggleMover()
    if InCombatLockdown() then
        print("|cff00c8ffGravityUI|r Debuff Mirror: |cffFF4444Cannot move frames in combat.|r")
        return
    end
    moverActive = not moverActive
    self:ShowMoverPreview(moverActive)
    if moverActive then
        print("|cff00c8ffGravityUI|r Debuff Mirror: |cffFFCC00Mover active|r — drag the frame, then click Toggle Mover again.")
    else
        print("|cff00c8ffGravityUI|r Debuff Mirror: |cff00ff00Position saved.|r")
    end
end

function DebuffMirror:ResetPosition()
    CreateMirrorFrame()
    if not mirrorFrame then return end
    mirrorFrame:ClearAllPoints()
    mirrorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    SavePosition()
    print("|cff00c8ffGravityUI|r Debuff Mirror: |cff00ff00Position reset.|r")
end

-- ============================================================================
-- EVENTS
-- ============================================================================

local evtFrame = CreateFrame("Frame")
evtFrame:RegisterUnitEvent("UNIT_AURA", "player")
evtFrame:RegisterEvent("PLAYER_LOGIN")
evtFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
evtFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- fix up any icons created during combat
evtFrame:SetScript("OnEvent", function(self, event, unit, updateInfo)
    if event == "PLAYER_LOGIN" then
        -- Create the frame at login so the GravityUI Edit Mode panel
        -- can find it in Movers.registry when it builds its list.
        CreateMirrorFrame()
        -- Pre-warm the icon pool so CreateMirrorIcon is never called during
        -- combat (which would trigger ADDON_ACTION_BLOCKED on SetPassThroughButtons).
        local db = GetDB()
        local warmCount = (db and db.maxDebuffs) or 16
        for i = 1, warmCount do
            local ic = CreateMirrorIcon(UIParent)
            ic:Hide()
            iconPool[#iconPool + 1] = ic
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(auraTimeCache)
        C_Timer.After(1.0, function() DebuffMirror:Refresh() end)
    elseif event == "UNIT_AURA" then
        local db = GetDB()
        if not db or not db.enabled then return end

        -- UNIT_AURA-Payload direkt auswerten:
        -- expirationTime/duration sofort cachen, BEVOR der Timer abläuft.
        -- In M+/Raid liefert der Server diese Werte nur im Event-Moment zuverlässig.
        if updateInfo then
            if updateInfo.isFullUpdate then
                -- Vollständiges Rescan nötig (z.B. Encounter-Start, Instanz-Betreten).
                -- Cache leeren und sofort updaten.
                wipe(auraTimeCache)
                ScheduleUpdate(true)
                return
            end
            -- Neue Auras: expirationTime/duration sofort cachen
            if updateInfo.addedAuras then
                for _, auraData in ipairs(updateInfo.addedAuras) do
                    if auraData.isHelpful == false or not auraData.isHelpful then
                        -- Debuff (nicht Buff)
                        pcall(function()
                            if auraData.auraInstanceID and auraData.expirationTime
                               and auraData.duration and auraData.expirationTime > 0
                               and auraData.duration > 0 then
                                auraTimeCache[auraData.auraInstanceID] = {
                                    auraData.expirationTime,
                                    auraData.duration
                                }
                            end
                        end)
                    end
                end
            end
            -- Entfernte Auras aus Cache löschen
            if updateInfo.removedAuraInstanceIDs then
                for _, id in ipairs(updateInfo.removedAuraInstanceIDs) do
                    auraTimeCache[id] = nil
                end
            end
        end

        ScheduleUpdate()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Apply SetPassThroughButtons to any icons that were created during combat.
        for _, ic in ipairs(activeIcons) do
            if ic._needsPassThrough then
                ic:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton")
                ic._needsPassThrough = nil
            end
        end
        for _, ic in ipairs(iconPool) do
            if ic._needsPassThrough then
                ic:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton")
                ic._needsPassThrough = nil
            end
        end
    end
end)
