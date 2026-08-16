-- ============================================================================
-- GravityUI: Targeted Spells Module
-- Highlights spells and channels targeting the player and party members
-- Built on the robust, secret-safe WoW 12.0 Retail API architecture
-- ============================================================================
local ADDON_NAME, ns = ...

local TargetedSpells = {}
ns.TargetedSpells = TargetedSpells
LibStub("AceEvent-3.0"):Embed(TargetedSpells)

-- ============================================================================
-- UPVALUES & CONSTANTS
-- ============================================================================
local UnitExists             = UnitExists
local UnitName               = UnitName
local UnitClass              = UnitClass
local UnitCanAttack          = UnitCanAttack
local UnitCanAssist          = UnitCanAssist
local UnitAffectingCombat    = UnitAffectingCombat
local UnitCastingInfo        = UnitCastingInfo
local UnitChannelInfo        = UnitChannelInfo
local UnitCastingDuration    = UnitCastingDuration or function() end
local UnitChannelDuration    = UnitChannelDuration or function() end
local UnitSpellTargetName    = UnitSpellTargetName or function() end
local UnitSpellTargetClass   = UnitSpellTargetClass or function() end
local PlayerIsSpellTarget    = PlayerIsSpellTarget or function() end
local GetTime                = GetTime
local PlaySoundFile          = PlaySoundFile
local pairs                  = pairs
local ipairs                 = ipairs
local wipe                   = wipe
local format                 = string.format
local math_max               = math.max
local math_min               = math.min
local math_floor             = math.floor
local table_insert           = table.insert
local table_remove           = table.remove

local LSM = LibStub("LibSharedMedia-3.0", true)

local DEFAULT_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local DEFAULT_FONT    = "Fonts\\FRIZQT__.TTF"

-- ============================================================================
-- OBJECT POOLS & DATA STRUCTURES (ZERO-ALLOCATION)
-- ============================================================================
local castPool = {}
local activeCasts = {}       -- [unitKey] = castData
local activeList = {}        -- array of active castData
local pendingCasts = {}
local barPool = {}
local iconPool = {}
local dynamicShards = {}
local driverFrame = nil

local testModeActive = false
local barMoverActive = false
local iconMoverActive = false
local lastSoundPlayTime = 0

local barContainer = nil
local iconContainer = nil
local updateFrame = nil
local UpdateLayout = nil
local StopCast = nil

local function AcquireCast()
    local c = table_remove(castPool)
    if not c then
        c = {}
    else
        wipe(c)
    end
    return c
end

local function ReleaseCast(c)
    if not c then return end
    wipe(c)
    table_insert(castPool, c)
end

-- ============================================================================
-- SETTINGS HELPER
-- ============================================================================
local function GetSettings()
    local db = ns.GetDB and ns.GetDB()
    if not db then return nil end
    if not db.screenindicators then db.screenindicators = {} end
    if not db.screenindicators.targetedSpells then
        db.screenindicators.targetedSpells = {
            enabled            = false,
            showBars           = true,
            showIcons          = false,
            showSelf           = true,
            showParty          = true,
            onlyKickable       = false,

            -- Bars
            width              = 200,
            height             = 20,
            spacing            = 4,
            maxBars            = 5,
            growDirection      = "UP",
            texture            = "Gravity Normal",
            font               = "Gravity",
            fontSize           = 12,
            fontOutline        = "OUTLINE",

            -- Icons
            iconSize           = 36,
            iconSpacing        = 4,
            iconMax            = 5,
            iconGrowDirection  = "CENTER",
            iconFont           = "Gravity",
            iconFontSize       = 13,
            iconFontOutline    = "OUTLINE",
            iconShowTargetName = true,
            iconShowSweep      = true,
            iconOnlySelf       = true,
            iconGlow           = true,
            iconGlowMatchCast  = true,
            iconGlowColor      = { 1.00, 0.82, 0.00, 0.90 },
            iconGlowSize       = 4,
            iconGlowPulse      = true,

            -- Colors
            castingColor       = { 1.00, 0.82, 0.00, 0.90 },
            channelingColor    = { 0.60, 0.25, 0.95, 0.90 },
            shieldColor        = { 0.50, 0.50, 0.50, 0.90 },
            backdropColor      = { 0.08, 0.08, 0.08, 0.85 },
            textColor          = { 1.00, 1.00, 1.00, 1.00 },
            targetClassColor   = true,

            -- Sound (Deactivated)
            soundEnabled       = false,
            soundFile          = "Targeted",
            soundChannel       = "Master",

            x                  = 0,
            y                  = -140,
            iconX              = 0,
            iconY              = -80,
        }
    end
    return db.screenindicators.targetedSpells
end

local function FetchMedia(mediaType, name, default)
    if LSM and name then
        local fetched = LSM:Fetch(mediaType, name)
        if fetched then return fetched end
    end
    return default
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

-- ============================================================================
-- SOUND ALERT
-- ============================================================================
local function GetSoundPath(soundFile)
    local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
    if lsm and soundFile then
        local p = lsm:Fetch("sound", soundFile, true)
        if p then return p end
    end
    return "Interface\\AddOns\\GravityUI\\assets\\media\\sounds\\" .. (soundFile or "Targeted") .. ".ogg"
end

local function TriggerSoundAlert()
    -- Sound alerts for targeted spells are deactivated in WoW 12.0
    return
end

function TargetedSpells.PlayTestSound()
    local s = GetSettings()
    if not s then return end
    local soundFile = s.soundFile or "Targeted"
    local soundPath = GetSoundPath(soundFile)
    local channel = s.soundChannel or "Master"
    PlaySoundFile(soundPath, channel)
end



-- ============================================================================
-- BAR CREATION & STYLING
-- ============================================================================
local function CreateBarFrame()
    local bar = CreateFrame("Frame", nil, barContainer, "BackdropTemplate")
    bar:SetSize(200, 20)

    -- Backdrop (Pixel-perfect 1px border)
    bar:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    bar:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
    bar:SetBackdropBorderColor(0, 0, 0, 1)

    -- Status Bar
    local sb = CreateFrame("StatusBar", nil, bar)
    sb:SetPoint("TOPLEFT", 1, -1)
    sb:SetPoint("BOTTOMRIGHT", -1, 1)
    sb:SetMinMaxValues(0, 1)
    sb:SetValue(1)
    bar.statusBar = sb

    -- Status Bar Background Texture (Rich dark textured track behind fill)
    local sbBg = sb:CreateTexture(nil, "BACKGROUND")
    sbBg:SetAllPoints()
    sbBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    sbBg:SetVertexColor(0.08, 0.08, 0.08, 0.85)
    bar.sbBg = sbBg

    -- Casting Spark (Smooth Animated Glow at Cast Progress Edge)
    local spark = sb:CreateTexture(nil, "OVERLAY", nil, 6)
    spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
    spark:SetBlendMode("ADD")
    spark:SetWidth(12)
    spark:SetPoint("CENTER", sb:GetStatusBarTexture(), "RIGHT", 0, 0)
    bar.spark = spark

    -- Icon Frame & Texture (Crisp 1px border with zoom crop)
    local iconFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    iconFrame:SetSize(20, 20)
    iconFrame:SetPoint("RIGHT", bar, "LEFT", -2, 0)
    iconFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    iconFrame:SetBackdropColor(0, 0, 0, 1)
    iconFrame:SetBackdropBorderColor(0, 0, 0, 1)
    bar.iconFrame = iconFrame

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    bar.icon = icon

    -- Raid Target Marker Icon (Skull, Star, Cross, etc.)
    local raidIcon = bar:CreateTexture(nil, "OVERLAY", nil, 7)
    raidIcon:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcons")
    raidIcon:SetPoint("RIGHT", iconFrame, "LEFT", -3, 0)
    raidIcon:Hide()
    bar.raidIcon = raidIcon

    -- Shield Icon (Uninterruptible indicator - Top-Left Corner)
    local shield = sb:CreateTexture(nil, "OVERLAY", nil, 7)
    shield:SetSize(11, 11)
    shield:SetPoint("TOPLEFT", bar, "TOPLEFT", 2, -2)
    local ok = pcall(shield.SetAtlas, shield, "ui-castingbar-shield")
    if not ok or not shield:GetTexture() then
        shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Shield")
    end
    shield:SetVertexColor(1, 1, 1, 1)
    shield:Hide()
    bar.shield = shield

    -- Duration Cooldown (Hidden, used strictly for event timing)
    local durCd = CreateFrame("Cooldown", nil, sb, "CooldownFrameTemplate")
    durCd:SetAllPoints()
    durCd:SetHideCountdownNumbers(true)
    durCd:SetDrawEdge(false)
    durCd:SetDrawSwipe(false)
    durCd:SetScript("OnCooldownDone", function(self)
        local parentBar = self:GetParent():GetParent()
        if parentBar and parentBar.unit and StopCast then
            StopCast(parentBar.unit)
        end
    end)
    bar.durationCooldown = durCd

    -- Text: Duration (Far Right, e.g. "2.5s")
    local textDuration = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    textDuration:SetPoint("RIGHT", sb, "RIGHT", -4, 0)
    textDuration:SetJustifyH("RIGHT")
    textDuration:SetWordWrap(false)
    textDuration:SetMaxLines(1)
    bar.textDuration = textDuration

    -- Text: Target Name (e.g. "» YOU" or "» Tank", right-aligned before duration)
    local textTarget = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    textTarget:SetPoint("RIGHT", textDuration, "LEFT", -6, 0)
    textTarget:SetJustifyH("RIGHT")
    textTarget:SetWordWrap(false)
    textTarget:SetMaxLines(1)
    bar.textTarget = textTarget

    -- Text: Left (Spell Name, left-aligned, auto-truncates so target name is always visible)
    local textLeft = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    textLeft:SetPoint("LEFT", sb, "LEFT", 4, 0)
    textLeft:SetPoint("RIGHT", textTarget, "LEFT", -6, 0)
    textLeft:SetJustifyH("LEFT")
    textLeft:SetWordWrap(false)
    textLeft:SetMaxLines(1)
    bar.textLeft = textLeft

    bar:Hide()
    return bar
end

local function GetBarFrame(index)
    if not barPool[index] then
        barPool[index] = CreateBarFrame()
    end
    return barPool[index]
end

local function UpdateBarColors(bar, cast)
    local s = GetSettings()
    if not bar or not s then return end

    local castCol   = s.castingColor or { 1.00, 0.82, 0.00, 0.90 }   -- Yellow (Interruptible Casts)
    local chanCol   = s.channelingColor or { 0.60, 0.25, 0.95, 0.90 } -- Purple (Channeling Casts)
    local shieldCol = s.shieldColor or { 0.50, 0.50, 0.50, 0.90 }     -- Shield Gray (Non-Interruptible Casts)

    local sbTex = bar.statusBar:GetStatusBarTexture()
    if not sbTex then return end

    -- TEST MODE
    if cast.isTest then
        local activeCol
        if cast.notInterruptible then
            activeCol = shieldCol
        elseif cast.isChannel then
            activeCol = chanCol
        else
            activeCol = castCol
        end
        sbTex:SetVertexColor(activeCol[1], activeCol[2], activeCol[3], activeCol[4] or 0.9)
        return
    end

    -- LIVE MODE: Blizzard Native C++ Engine SetVertexColorFromBoolean (Atrocity / TargetedSpells Standard)
    local baseCol = cast.isChannel and chanCol or castCol

    if cast.uninterruptible ~= nil and sbTex.SetVertexColorFromBoolean then
        local shieldObj = CreateColor(shieldCol[1], shieldCol[2], shieldCol[3], shieldCol[4] or 0.9)
        local baseObj   = CreateColor(baseCol[1], baseCol[2], baseCol[3], baseCol[4] or 0.9)
        sbTex:SetVertexColorFromBoolean(cast.uninterruptible, shieldObj, baseObj)
    else
        local isShielded = (cast.uninterruptible == true or cast.notInterruptible == true)
        local col = isShielded and shieldCol or baseCol
        sbTex:SetVertexColor(col[1], col[2], col[3], col[4] or 0.9)
    end
end

local function ApplyBarStyles(bar, cast)
    local s = GetSettings()
    if not s then return end

    local fontPath = FetchMedia("font", s.font, DEFAULT_FONT)
    local fontSize = s.fontSize or 12
    local fontOutline = s.fontOutline or "OUTLINE"
    local texturePath = FetchMedia("statusbar", s.texture, DEFAULT_TEXTURE)

    local height = s.height or 20
    bar:SetSize(s.width or 200, height)
    bar.iconFrame:SetSize(height, height)

    bar.statusBar:SetStatusBarTexture(texturePath)
    if bar.sbBg then
        bar.sbBg:SetTexture(texturePath)
        bar.sbBg:SetVertexColor(0.08, 0.08, 0.08, 0.85)
    end

    if bar.spark then
        bar.spark:SetHeight(height * 1.5)
        bar.spark:SetShown(not cast.isChannel)
    end

    bar.textLeft:SetFont(fontPath, fontSize, fontOutline)
    bar.textTarget:SetFont(fontPath, fontSize, fontOutline)
    bar.textDuration:SetFont(fontPath, fontSize, fontOutline)

    local bdc = s.backdropColor or { 0.08, 0.08, 0.08, 0.85 }
    bar:SetBackdropColor(bdc[1], bdc[2], bdc[3], bdc[4] or 0.85)

    -- Dynamic Interrupt Status Bar Coloring
    UpdateBarColors(bar, cast)

    -- Shield display (Secret Boolean Safe - Top-Left Corner)
    local shieldSize = math_min(12, math_max(10, math_floor(height * 0.55)))
    bar.shield:SetSize(shieldSize, shieldSize)
    bar.shield:ClearAllPoints()
    bar.shield:SetPoint("TOPLEFT", bar, "TOPLEFT", 2, -2)
    if cast.uninterruptible ~= nil and bar.shield.SetAlphaFromBoolean then
        bar.shield:SetAlphaFromBoolean(cast.uninterruptible, 1, 0)
        bar.shield:Show()
    else
        bar.shield:Hide()
    end

    -- Raid Target Marker Icon (Star, Circle, Diamond, Triangle, Moon, Square, Cross, Skull)
    if bar.raidIcon then
        local raidSize = math_max(14, height - 2)
        bar.raidIcon:SetSize(raidSize, raidSize)
        local raidIdx = (cast.isTest and cast.previewRaidIcon) or (cast.unit and GetRaidTargetIndex and GetRaidTargetIndex(cast.unit))
        if raidIdx then
            SetRaidTargetIconTexture(bar.raidIcon, raidIdx)
            bar.raidIcon:Show()
        else
            bar.raidIcon:Hide()
        end
    end

    local tc = s.textColor or { 1, 1, 1, 1 }
    bar.textLeft:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
    bar.textTarget:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
    bar.textDuration:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)

    bar.icon:SetTexture(cast.icon or 136243)
    bar.textLeft:SetText(cast.spellName or cast.casterName or "Cast")

    -- Target Name with Modern Arrow Separator and Class Color (Secret-Safe)
    if cast.targetName then
        local formattedTarget = cast.targetName
        if s.targetClassColor ~= false and cast.targetClass and C_ClassColor and C_ClassColor.GetClassColor then
            local c = C_ClassColor.GetClassColor(cast.targetClass)
            if c and c.WrapTextInColorCode then
                pcall(function() formattedTarget = c:WrapTextInColorCode(cast.targetName) end)
            end
        elseif cast.targetFormatted then
            formattedTarget = cast.targetFormatted
        end
        bar.textTarget:SetFormattedText("» %s", formattedTarget)
        bar.textTarget:Show()
    else
        bar.textTarget:SetText("")
        bar.textTarget:Hide()
    end

    -- Native Timer Duration
    if cast.duration then
        if bar.statusBar.SetTimerDuration then
            local dir = cast.isChannel and (Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.RemainingTime or 1)
                or (Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.ElapsedTime or 0)
            local interp = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or 0
            pcall(bar.statusBar.SetTimerDuration, bar.statusBar, cast.duration, interp, dir)
        end
        if bar.durationCooldown.SetCooldownFromDurationObject then
            pcall(bar.durationCooldown.SetCooldownFromDurationObject, bar.durationCooldown, cast.duration)
        end
    end

    bar.unit = cast.unit

    -- Engine-level secret-safe alpha
    if cast.isTest then
        if s.onlyKickable and cast.notInterruptible then
            bar:SetAlpha(0)
        else
            bar:SetAlpha(1)
        end
    elseif cast.unit and bar.SetAlphaFromBoolean then
        if s.onlyKickable and cast.uninterruptible ~= nil then
            bar:SetAlphaFromBoolean(cast.uninterruptible, 0, 1)
        elseif s.showSelf and not s.showParty then
            bar:SetAlphaFromBoolean(PlayerIsSpellTarget(cast.unit, "player"), 1, 0)
        elseif s.showParty and not s.showSelf then
            bar:SetAlphaFromBoolean(PlayerIsSpellTarget(cast.unit, "player"), 0, 1)
        else
            bar:SetAlpha(1)
        end
    else
        bar:SetAlpha(1)
    end
end

-- ============================================================================
-- ICON CREATION & STYLING
-- ============================================================================
local function CreateIconFrame()
    local iconF = CreateFrame("Frame", nil, iconContainer, "BackdropTemplate")
    iconF:SetSize(36, 36)

    iconF:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    iconF:SetBackdropColor(0, 0, 0, 1)
    iconF:SetBackdropBorderColor(0, 0, 0, 1)

    -- Glow Frame (Outer Glowing Border with Smooth Pulse Animation)
    local glow = CreateFrame("Frame", nil, iconF, "BackdropTemplate")
    glow:SetPoint("TOPLEFT", iconF, "TOPLEFT", -4, 4)
    glow:SetPoint("BOTTOMRIGHT", iconF, "BOTTOMRIGHT", 4, -4)
    glow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 4,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    glow:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.9)

    local ag = glow:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(0.35)
    a:SetToAlpha(1.0)
    a:SetDuration(0.65)
    a:SetSmoothing("IN_OUT")
    glow.animGroup = ag
    iconF.glow = glow

    -- Texture
    local tex = iconF:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 1, -1)
    tex:SetPoint("BOTTOMRIGHT", -1, 1)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    iconF.texture = tex

    -- Cooldown Sweep
    local cd = CreateFrame("Cooldown", nil, iconF, "CooldownFrameTemplate")
    cd:SetPoint("TOPLEFT", 1, -1)
    cd:SetPoint("BOTTOMRIGHT", -1, 1)
    cd:SetDrawEdge(false)
    cd:SetDrawSwipe(true)
    cd:SetReverse(true)
    cd:SetHideCountdownNumbers(true)
    cd.noCooldownCount = true
    cd:SetScript("OnCooldownDone", function(self)
        local parentIcon = self:GetParent()
        if parentIcon and parentIcon.unit and StopCast then
            StopCast(parentIcon.unit)
        end
    end)
    iconF.cooldown = cd

    -- Shield Icon
    local shield = iconF:CreateTexture(nil, "OVERLAY", nil, 7)
    shield:SetSize(14, 14)
    shield:SetPoint("TOPLEFT", iconF, "TOPLEFT", 1, -1)
    local ok = pcall(shield.SetAtlas, shield, "ui-castingbar-shield")
    if not ok or not shield:GetTexture() then
        shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Shield")
    end
    shield:SetVertexColor(1, 1, 1, 1)
    shield:Hide()
    iconF.shield = shield

    -- Text: Target Name (Bottom)
    local textTarget = iconF:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    textTarget:SetPoint("TOP", iconF, "BOTTOM", 0, -2)
    textTarget:SetJustifyH("CENTER")
    textTarget:SetWordWrap(false)
    iconF.textTarget = textTarget

    -- Text: Duration (Center overlay)
    local textDur = iconF:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textDur:SetPoint("CENTER", iconF, "CENTER", 0, 0)
    textDur:SetJustifyH("CENTER")
    iconF.textDuration = textDur

    iconF:Hide()
    return iconF
end

local function GetIconFrame(index)
    if not iconPool[index] then
        iconPool[index] = CreateIconFrame()
    end
    return iconPool[index]
end

local function ApplyIconStyles(iconF, cast)
    local s = GetSettings()
    if not s then return end

    local size = s.iconSize or 36
    iconF:SetSize(size, size)

    local fontPath = FetchMedia("font", s.iconFont, DEFAULT_FONT)
    local fontSize = s.iconFontSize or 13
    local fontOutline = s.iconFontOutline or "OUTLINE"

    iconF.textDuration:SetFont(fontPath, fontSize, fontOutline)
    iconF.textTarget:SetFont(fontPath, math_max(9, fontSize - 2), fontOutline)

    iconF.texture:SetTexture(cast.icon or 136243)

    -- Native Cooldown from Duration Object
    if cast.duration and iconF.cooldown.SetCooldownFromDurationObject then
        pcall(iconF.cooldown.SetCooldownFromDurationObject, iconF.cooldown, cast.duration)
    end

    -- Border Color
    local castCol   = s.castingColor or { 1.00, 0.82, 0.00, 0.90 }
    local chanCol   = s.channelingColor or { 0.60, 0.25, 0.95, 0.90 }
    local shieldCol = s.shieldColor or { 0.50, 0.50, 0.50, 0.90 }

    local activeBorderCol
    if cast.isTest then
        local borderCol
        if cast.notInterruptible then
            borderCol = shieldCol
        elseif cast.isChannel then
            borderCol = chanCol
        else
            borderCol = castCol
        end
        activeBorderCol = borderCol
        iconF:SetBackdropBorderColor(borderCol[1], borderCol[2], borderCol[3], borderCol[4] or 1)
    else
        local baseCol = cast.isChannel and chanCol or castCol
        local ev = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean
        if cast.uninterruptible ~= nil and ev then
            local r = ev(cast.uninterruptible, baseCol[1], shieldCol[1])
            local g = ev(cast.uninterruptible, baseCol[2], shieldCol[2])
            local b = ev(cast.uninterruptible, baseCol[3], shieldCol[3])
            activeBorderCol = { r, g, b, 1 }
            iconF:SetBackdropBorderColor(r, g, b, 1)
        else
            local col = (cast.uninterruptible == true or cast.notInterruptible == true) and shieldCol or baseCol
            activeBorderCol = col
            iconF:SetBackdropBorderColor(col[1], col[2], col[3], 1)
        end
    end

    -- Icon Glow Handling
    if iconF.glow then
        if s.iconGlow ~= false then
            local glowSize = s.iconGlowSize or 4
            iconF.glow:ClearAllPoints()
            iconF.glow:SetPoint("TOPLEFT", iconF, "TOPLEFT", -glowSize, glowSize)
            iconF.glow:SetPoint("BOTTOMRIGHT", iconF, "BOTTOMRIGHT", glowSize, -glowSize)
            iconF.glow:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = glowSize,
                insets   = { left = 0, right = 0, top = 0, bottom = 0 }
            })

            -- Determine Glow Color
            if s.iconGlowMatchCast == false and s.iconGlowColor then
                local gc = s.iconGlowColor
                iconF.glow:SetBackdropBorderColor(gc[1], gc[2], gc[3], gc[4] or 0.9)
            else
                if activeBorderCol then
                    iconF.glow:SetBackdropBorderColor(activeBorderCol[1], activeBorderCol[2], activeBorderCol[3], activeBorderCol[4] or 0.9)
                end
            end

            if s.iconGlowPulse ~= false then
                if not iconF.glow.animGroup:IsPlaying() then
                    iconF.glow.animGroup:Play()
                end
            else
                if iconF.glow.animGroup:IsPlaying() then
                    iconF.glow.animGroup:Stop()
                end
                iconF.glow:SetAlpha(0.9)
            end
            iconF.glow:Show()
        else
            if iconF.glow.animGroup:IsPlaying() then
                iconF.glow.animGroup:Stop()
            end
            iconF.glow:Hide()
        end
    end

    -- Shield Icon
    iconF.shield:SetSize(math_max(12, size * 0.4), math_max(12, size * 0.4))
    if cast.uninterruptible ~= nil and iconF.shield.SetAlphaFromBoolean then
        iconF.shield:SetAlphaFromBoolean(cast.uninterruptible, 1, 0)
        iconF.shield:Show()
    else
        iconF.shield:Hide()
    end

    if s.iconShowTargetName ~= false and cast.targetName then
        local formattedTarget = cast.targetName
        if s.targetClassColor ~= false and cast.targetClass and C_ClassColor and C_ClassColor.GetClassColor then
            local c = C_ClassColor.GetClassColor(cast.targetClass)
            if c and c.WrapTextInColorCode then
                pcall(function() formattedTarget = c:WrapTextInColorCode(cast.targetName) end)
            end
        elseif cast.targetFormatted then
            formattedTarget = cast.targetFormatted
        end
        iconF.textTarget:SetText(formattedTarget)
        iconF.textTarget:Show()
    else
        iconF.textTarget:SetText("")
        iconF.textTarget:Hide()
    end

    iconF.cooldown:SetReverse(not cast.isChannel)
    iconF.cooldown:SetDrawSwipe(s.iconShowSweep ~= false)
    iconF.unit = cast.unit

    -- Engine-level secret-safe alpha
    if cast.isTest then
        if s.onlyKickable and cast.notInterruptible then
            iconF:SetAlpha(0)
        else
            iconF:SetAlpha(1)
        end
    elseif cast.unit and iconF.SetAlphaFromBoolean then
        if s.onlyKickable and cast.uninterruptible ~= nil then
            iconF:SetAlphaFromBoolean(cast.uninterruptible, 0, 1)
        elseif s.iconOnlySelf then
            iconF:SetAlphaFromBoolean(PlayerIsSpellTarget(cast.unit, "player"), 1, 0)
        else
            if s.showSelf and not s.showParty then
                iconF:SetAlphaFromBoolean(PlayerIsSpellTarget(cast.unit, "player"), 1, 0)
            elseif s.showParty and not s.showSelf then
                iconF:SetAlphaFromBoolean(PlayerIsSpellTarget(cast.unit, "player"), 0, 1)
            else
                iconF:SetAlpha(1)
            end
        end
    else
        iconF:SetAlpha(1)
    end
end

-- ============================================================================
-- LAYOUT & DISPLAY
-- ============================================================================
UpdateLayout = function()
    local s = GetSettings()
    if not s then return end

    local activeCount = #activeList

    -- 1. BARS LAYOUT
    if barContainer then
        if s.enabled and s.showBars then
            local width = s.width or 200
            local height = s.height or 20
            local spacing = s.spacing or 4
            local maxBars = s.maxBars or 5
            local growUp = (s.growDirection ~= "DOWN")

            local barCount = 0
            for i, cast in ipairs(activeList) do
                if barCount < maxBars then
                    barCount = barCount + 1
                    local bar = GetBarFrame(barCount)
                    ApplyBarStyles(bar, cast)

                    bar:ClearAllPoints()
                    local yOffset = (barCount - 1) * (height + spacing)
                    if growUp then
                        bar:SetPoint("BOTTOMLEFT", barContainer, "BOTTOMLEFT", 0, yOffset)
                    else
                        bar:SetPoint("TOPLEFT", barContainer, "TOPLEFT", 0, -yOffset)
                    end

                    bar.icon:SetTexture(cast.icon or 136243)
                    bar.textLeft:SetText(cast.spellName or cast.casterName or "Cast")
                    bar:Show()
                end
            end

            for i = barCount + 1, #barPool do
                barPool[i]:Hide()
            end

            local totalHeight = math_max(height, (barCount * height) + (math_max(0, barCount - 1) * spacing))
            barContainer:SetSize(width, totalHeight)
            barContainer:Show()
        else
            for _, bar in ipairs(barPool) do bar:Hide() end
            barContainer:Hide()
        end
    end

    -- 2. ICONS LAYOUT
    if iconContainer then
        if s.enabled and s.showIcons then
            local size = s.iconSize or 36
            local spacing = s.iconSpacing or 4
            local maxIcons = s.iconMax or 5
            local growDir = s.iconGrowDirection or "CENTER"

            local iconCount = 0
            local step = size + spacing

            for i, cast in ipairs(activeList) do
                if iconCount < maxIcons then
                    iconCount = iconCount + 1
                    local iconF = GetIconFrame(iconCount)
                    ApplyIconStyles(iconF, cast)

                    iconF:ClearAllPoints()
                    if growDir == "CENTER" or growDir == "CENTER_HORIZONTAL" then
                        -- Stable Alternating Center: Slot 1 is center (0), Slot 2 is Right (+step), Slot 3 is Left (-step), Slot 4 is Right (+2*step), Slot 5 is Left (-2*step)
                        -- Completely eliminates icon jumping when casts start/stop or change count!
                        local xOffset = 0
                        if iconCount > 1 then
                            local pairIdx = math_floor(iconCount / 2)
                            if (iconCount % 2) == 0 then
                                xOffset = pairIdx * step
                            else
                                xOffset = -pairIdx * step
                            end
                        end
                        iconF:SetPoint("CENTER", iconContainer, "CENTER", xOffset, 0)
                    elseif growDir == "RIGHT" then
                        local xOffset = (iconCount - 1) * step
                        iconF:SetPoint("CENTER", iconContainer, "CENTER", xOffset, 0)
                    elseif growDir == "LEFT" then
                        local xOffset = -(iconCount - 1) * step
                        iconF:SetPoint("CENTER", iconContainer, "CENTER", xOffset, 0)
                    elseif growDir == "DOWN" then
                        local yOffset = -(iconCount - 1) * step
                        iconF:SetPoint("CENTER", iconContainer, "CENTER", 0, yOffset)
                    else -- UP
                        local yOffset = (iconCount - 1) * step
                        iconF:SetPoint("CENTER", iconContainer, "CENTER", 0, yOffset)
                    end

                    iconF.texture:SetTexture(cast.icon or 136243)
                    if cast.duration and iconF.cooldown.SetCooldownFromDurationObject then
                        pcall(iconF.cooldown.SetCooldownFromDurationObject, iconF.cooldown, cast.duration)
                    elseif cast.startTime and type(cast.duration) == "number" then
                        iconF.cooldown:SetCooldown(cast.startTime, cast.duration)
                    end
                    iconF:Show()
                end
            end

            for i = iconCount + 1, #iconPool do
                iconPool[i]:Hide()
            end

            iconContainer:SetSize(size, size)
            iconContainer:Show()
        else
            for _, iconF in ipairs(iconPool) do iconF:Hide() end
            iconContainer:Hide()
        end
    end

    local shouldAnimate = (activeCount > 0 and (s.showBars or s.showIcons)) or testModeActive or barMoverActive or iconMoverActive
    if shouldAnimate and updateFrame then
        updateFrame:Show()
    elseif updateFrame then
        updateFrame:Hide()
    end
end

local function OnUpdateTicker(self, elapsed)
    local now = GetTime()
    local s = GetSettings()
    if not s then return end

    local i = 1
    local dirty = false

    while i <= #activeList do
        local cast = activeList[i]
        if cast.isTest then
            if now > cast.endTime then
                cast.startTime = now
                cast.endTime = now + cast.duration
                if s.showIcons then
                    local iconF = GetIconFrame(i)
                    if iconF and iconF:IsShown() then
                        iconF.cooldown:SetCooldown(cast.startTime, cast.duration)
                    end
                end
            end
            local remaining = math_max(0, cast.endTime - now)
            local progress = 1 - (remaining / cast.duration)

            if s.showBars then
                local bar = GetBarFrame(i)
                if bar and bar:IsShown() then
                    UpdateBarColors(bar, cast)
                    bar.statusBar:SetValue(cast.isChannel and (1 - progress) or progress)
                    bar.textDuration:SetFormattedText("%.1fs", remaining)
                end
            end

            if s.showIcons then
                local iconF = GetIconFrame(i)
                if iconF and iconF:IsShown() then
                    iconF.textDuration:SetFormattedText("%.1f", remaining)
                end
            end

            i = i + 1
        else
            -- LIVE CASTS & CHANNELS (Native Duration Countdown & Dynamic Kick Color)
            if s.showBars then
                local bar = GetBarFrame(i)
                if bar and bar:IsShown() then
                    UpdateBarColors(bar, cast)
                    if bar.textDuration then
                        if cast.duration and cast.duration.GetRemainingDuration then
                            local ok, rem = pcall(cast.duration.GetRemainingDuration, cast.duration)
                            if ok and rem then
                                pcall(bar.textDuration.SetFormattedText, bar.textDuration, "%.1fs", rem)
                            end
                        end
                    end
                end
            end

            if s.showIcons then
                local iconF = GetIconFrame(i)
                if iconF and iconF:IsShown() then
                    if iconF.textDuration then
                        if cast.duration and cast.duration.GetRemainingDuration then
                            local ok, rem = pcall(cast.duration.GetRemainingDuration, cast.duration)
                            if ok and rem then
                                pcall(iconF.textDuration.SetFormattedText, iconF.textDuration, "%.1f", rem)
                            end
                        end
                    end
                end
            end
            i = i + 1
        end
    end

    if dirty then
        UpdateLayout()
    end
end

-- ============================================================================
-- CAST RESOLUTION & EVENT HANDLING
-- ============================================================================
StopCast = function(unit)
    if testModeActive then return end
    local existing = activeCasts[unit]
    if existing then
        activeCasts[unit] = nil
        for idx, c in ipairs(activeList) do
            if c.unit == unit then
                table_remove(activeList, idx)
                ReleaseCast(c)
                break
            end
        end
        UpdateLayout()
    end
end

local function GetCastInformation(unit)
    local _, _, _, _, _, _, _, _, castingSpellId, castingBarId = UnitCastingInfo(unit)
    if castingSpellId ~= nil then
        local duration = UnitCastingDuration and UnitCastingDuration(unit)
        return false, castingSpellId, castingBarId, duration
    end

    local _, _, _, _, _, _, _, channelSpellId, _, _, channelBarId = UnitChannelInfo(unit)
    if channelSpellId ~= nil then
        local duration = UnitChannelDuration and UnitChannelDuration(unit)
        return true, channelSpellId, channelBarId, duration
    end

    return false, nil, nil, nil
end

local function ResolveTarget(unit)
    -- Target Name & Class from Spell Target
    local targetName = UnitSpellTargetName(unit)
    local targetClass = UnitSpellTargetClass(unit)

    return targetName, targetClass
end

local function ShouldBeActive()
    if testModeActive or barMoverActive or iconMoverActive then return true end
    local inInstance, instanceType = IsInInstance()
    -- "party" = 5-man Normal, Heroic, Mythic, and Mythic+ Dungeons (same as Atrocity DungeonCasts)
    return inInstance and (instanceType == "party")
end

local function TryProcessCast(unit, isChannel)
    if testModeActive then return end
    local s = GetSettings()
    if not s or not s.enabled then return end
    if not ShouldBeActive() then return end

    if not unit or unit == "target" or unit == "focus" then return end
    if not UnitExists(unit) then return end
    if not UnitAffectingCombat(unit) or UnitCanAssist("player", unit) then
        return
    end

    local isChan, spellId, castId, duration = GetCastInformation(unit)
    if spellId == nil or duration == nil then
        StopCast(unit)
        return
    end

    local uninterruptible = select(8, UnitCastingInfo(unit))
    if uninterruptible == nil then
        uninterruptible = select(7, UnitChannelInfo(unit))
    end

    local targetName, targetClass = ResolveTarget(unit)

    local now = GetTime()

    local cast = activeCasts[unit]
    local isNew = false
    if not cast then
        cast = AcquireCast()
        activeCasts[unit] = cast
        table_insert(activeList, cast)
        isNew = true
    end

    local spellInfo = C_Spell.GetSpellInfo(spellId)
    local spellName = spellInfo and spellInfo.name or C_Spell.GetSpellName(spellId)
    local spellIcon = spellInfo and spellInfo.iconID or 136243

    cast.unit             = unit
    cast.casterName       = UnitName(unit) or "Enemy"
    cast.spellName        = spellName or "Cast"
    cast.spellID          = spellId
    cast.icon             = spellIcon
    cast.startTime        = now
    cast.duration         = duration
    cast.isChannel        = isChan
    cast.uninterruptible  = uninterruptible
    cast.targetName       = targetName
    cast.targetClass      = targetClass
    cast.isTest           = false

    -- Sound alerts for targeted spells are completely deactivated in WoW 12.0
    -- (secret value restrictions prevent target-specific sound triggers in combat)

    UpdateLayout()
end

local function ProcessCast(unit, isChannel)
    TryProcessCast(unit, isChannel)

    local token = (pendingCasts[unit] or 0) + 1
    pendingCasts[unit] = token
    C_Timer.After(0.15, function()
        if pendingCasts[unit] == token then
            TryProcessCast(unit, isChannel)
        end
    end)
end

-- ============================================================================
-- DYNAMIC SHARD ARCHITECTURE (TARGETEDSPELLS DRIVER ARCHITECTURE)
-- ============================================================================
local SHARD_EVENTS = {
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_EMPOWER_START",
    "UNIT_SPELLCAST_EMPOWER_STOP",
    "UNIT_SPELLCAST_INTERRUPTIBLE",
    "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    "UNIT_TARGET",
}

local function OnShardEvent(self, event, unit, ...)
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
        if unit then ProcessCast(unit, false) end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        if unit then ProcessCast(unit, true) end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        if unit then StopCast(unit) end
    elseif event == "UNIT_TARGET" or event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        if unit then ProcessCast(unit, false) end
    end
end

local function ConfigureShard(shard)
    shard:SetScript("OnEvent", OnShardEvent)
    for _, ev in ipairs(SHARD_EVENTS) do
        shard:RegisterUnitEvent(ev, unpack(shard.units))
    end
end

local function EnsureShardForUnits(...)
    local key = table.concat({...}, "-")
    if dynamicShards[key] then return end

    local shard = CreateFrame("Frame")
    shard.units = {...}
    dynamicShards[key] = shard
    ConfigureShard(shard)
end

local function EnsureShardForUnit(unit)
    if not unit then return end
    if string.sub(unit, 1, 9) == "nameplate" then
        local tokenIndex = tonumber(string.sub(unit, 10))
        if tokenIndex then
            local shardIndex = math_floor((tokenIndex - 1) / 2) + 1
            local firstToken = (shardIndex - 1) * 2 + 1
            EnsureShardForUnits("nameplate" .. firstToken, "nameplate" .. (firstToken + 1))
        end
    end
end

local function OnDriverEvent(self, event, unit, ...)
    if event == "NAME_PLATE_UNIT_ADDED" and unit then
        EnsureShardForUnit(unit)
        ProcessCast(unit, false)
        ProcessCast(unit, true)
    elseif event == "NAME_PLATE_UNIT_REMOVED" and unit then
        StopCast(unit)
    elseif event == "UNIT_TARGET" and unit then
        ProcessCast(unit, false)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not testModeActive then
            for _, c in ipairs(activeList) do ReleaseCast(c) end
            wipe(activeList)
            wipe(activeCasts)
            UpdateLayout()
        end
    end
end

local function RegisterEvents()
    if not driverFrame then
        driverFrame = CreateFrame("Frame")
        driverFrame:SetScript("OnEvent", OnDriverEvent)
    end

    driverFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    driverFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    driverFrame:RegisterEvent("UNIT_TARGET")
    driverFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    for i = 1, 8, 2 do
        EnsureShardForUnits("boss" .. i, "boss" .. (i + 1))
    end
    for i = 1, 5, 2 do
        if i + 1 <= 5 then
            EnsureShardForUnits("arena" .. i, "arena" .. (i + 1))
        else
            EnsureShardForUnits("arena" .. i)
        end
    end

    for i = 1, 40, 2 do
        EnsureShardForUnits("nameplate" .. i, "nameplate" .. (i + 1))
    end

    for _, shard in pairs(dynamicShards) do
        ConfigureShard(shard)
    end
end

local function UnregisterEvents()
    if driverFrame then
        driverFrame:UnregisterAllEvents()
    end
    for _, shard in pairs(dynamicShards) do
        shard:UnregisterAllEvents()
    end
end

-- ============================================================================
-- ZONE STATE / INSTANCE GATEWAY (DUNGEONS & M+ ONLY)
-- ============================================================================
local isEventsRegistered = false
local zoneListener = nil

local function CheckZoneState()
    local s = GetSettings()
    if not s or not s.enabled or not (s.showBars or s.showIcons) then
        if isEventsRegistered then
            UnregisterEvents()
            isEventsRegistered = false
        end
        for _, c in ipairs(activeList) do ReleaseCast(c) end
        wipe(activeList)
        wipe(activeCasts)
        for _, bar in ipairs(barPool) do bar:Hide() end
        for _, iconF in ipairs(iconPool) do iconF:Hide() end
        if barContainer then barContainer:Hide() end
        if iconContainer then iconContainer:Hide() end
        if updateFrame then updateFrame:Hide() end
        return
    end

    if ShouldBeActive() then
        if not isEventsRegistered then
            RegisterEvents()
            isEventsRegistered = true
        end
        UpdateLayout()
    else
        if isEventsRegistered then
            UnregisterEvents()
            isEventsRegistered = false
        end
        for _, c in ipairs(activeList) do ReleaseCast(c) end
        wipe(activeList)
        wipe(activeCasts)
        for _, bar in ipairs(barPool) do bar:Hide() end
        for _, iconF in ipairs(iconPool) do iconF:Hide() end
        if barContainer then barContainer:Hide() end
        if iconContainer then iconContainer:Hide() end
        if updateFrame then updateFrame:Hide() end
    end
end

-- ============================================================================
-- TEST MODE & MOVERS
-- ============================================================================
function TargetedSpells.TestMode(state)
    local enable = (state ~= nil) and state or (not testModeActive)
    if not enable then
        testModeActive = false
        for _, c in ipairs(activeList) do ReleaseCast(c) end
        wipe(activeList)
        wipe(activeCasts)
        CheckZoneState()
        print("|cff00ccffGravityUI|r: Targeted Spells Test Mode |cffff4444Disabled|r")
    else
        testModeActive = true
        for _, c in ipairs(activeList) do ReleaseCast(c) end
        wipe(activeList)
        wipe(activeCasts)

        local now = GetTime()
        local _, pClass = UnitClass("player")

        -- 1. Shadow Bolt: Targeted on YOU (Interruptible -> Gravity Blue)
        local c1 = AcquireCast()
        c1.unit = "test1"
        c1.casterName = "Dark Cultist"
        c1.spellName = "Shadow Bolt"
        c1.icon = 136197
        c1.startTime = now
        c1.endTime = now + 2.5
        c1.duration = 2.5
        c1.isChannel = false
        c1.notInterruptible = false
        c1.previewRaidIcon = 8 -- Skull
        c1.targetType = "SELF"
        c1.targetName = "YOU"
        c1.targetClass = pClass
        c1.targetFormatted = "|cffff4444YOU|r"
        c1.isTest = true
        table_insert(activeList, c1)

        -- 2. Drain Life: Channeling on YOU (Channeling -> Vibrant Orange)
        local c2 = AcquireCast()
        c2.unit = "test2"
        c2.casterName = "Soulbinder"
        c2.spellName = "Drain Life"
        c2.icon = 136169
        c2.startTime = now
        c2.endTime = now + 4.0
        c2.duration = 4.0
        c2.isChannel = true
        c2.notInterruptible = false -- Interruptible Channel -> Orange
        c2.previewRaidIcon = 1 -- Star
        c2.targetType = "SELF"
        c2.targetName = "YOU"
        c2.targetClass = pClass
        c2.targetFormatted = "|cffff4444YOU|r"
        c2.isTest = true
        table_insert(activeList, c2)

        -- 3. Frostbolt: Targeted on Tank (Interruptible -> Gravity Blue)
        local c3 = AcquireCast()
        c3.unit = "test3"
        c3.casterName = "Frost Mage"
        c3.spellName = "Frostbolt"
        c3.icon = 135846
        c3.startTime = now
        c3.endTime = now + 3.2
        c3.duration = 3.2
        c3.isChannel = false
        c3.notInterruptible = false
        c3.previewRaidIcon = 7 -- Cross
        c3.targetType = "PARTY"
        c3.targetName = "Tank"
        c3.targetClass = "WARRIOR"
        c3.targetFormatted = "|cffc79c6eTank|r"
        c3.isTest = true
        table_insert(activeList, c3)

        -- 4. Cataclysmic Slam: Boss Cast (Shielded -> Shield Gray)
        local c4 = AcquireCast()
        c4.unit = "test4"
        c4.casterName = "Colossus"
        c4.spellName = "Cataclysmic Slam"
        c4.icon = 132337
        c4.startTime = now
        c4.endTime = now + 3.8
        c4.duration = 3.8
        c4.isChannel = false
        c4.notInterruptible = true -- Shielded / Non-Interruptible -> Shield Gray
        c4.previewRaidIcon = 5 -- Moon
        c4.targetType = "PARTY"
        c4.targetName = "Healer"
        c4.targetClass = "DRUID"
        c4.targetFormatted = "|cffff7c0aHealer|r"
        c4.isTest = true
        table_insert(activeList, c4)

        UpdateLayout()
        print("|cff00ccffGravityUI|r: Targeted Spells Test Mode |cff55ff55Enabled|r")
    end
end

function TargetedSpells.ToggleBarMover(force)
    if not barContainer then return end
    local s = GetSettings()

    local show = (force ~= nil) and force or (not barContainer.mover:IsShown())
    if force == false then show = false end
    barMoverActive = show

    if show then
        barContainer:Show()
        barContainer.mover:Show()
        barContainer.mover:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets   = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        barContainer.mover:SetBackdropColor(0, 0.6, 1, 0.5)
        barContainer.mover:SetBackdropBorderColor(0, 0.8, 1, 1)

        if #activeList == 0 and not testModeActive then
            TargetedSpells.TestMode(true)
        end
    else
        barContainer.mover:Hide()
        barContainer.mover:SetBackdrop(nil)
        if not iconMoverActive then
            TargetedSpells.TestMode(false)
        end
        if not s or not s.enabled or not s.showBars or #activeList == 0 then
            barContainer:Hide()
        end
        UpdateLayout()
    end
end

function TargetedSpells.ToggleIconMover(force)
    if not iconContainer then return end
    local s = GetSettings()

    local show = (force ~= nil) and force or (not iconContainer.mover:IsShown())
    if force == false then show = false end
    iconMoverActive = show

    if show then
        iconContainer:Show()
        iconContainer.mover:Show()
        iconContainer.mover:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
            insets   = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        iconContainer.mover:SetBackdropColor(0.0, 0.6, 1.0, 0.45)
        iconContainer.mover:SetBackdropBorderColor(0.0, 0.9, 1.0, 1)

        local r, g, b = 0, 0.8, 1
        if ns.GetAccentColor then
            r, g, b = ns.GetAccentColor()
        end
        if iconContainer.mover.titleBadge then
            iconContainer.mover.titleBadge:SetBackdropBorderColor(r, g, b, 0.9)
        end
        if iconContainer.mover.titleText then
            iconContainer.mover.titleText:SetTextColor(r, g, b)
        end

        if #activeList == 0 and not testModeActive then
            TargetedSpells.TestMode(true)
        end
    else
        iconContainer.mover:Hide()
        iconContainer.mover:SetBackdrop(nil)
        if not barMoverActive then
            TargetedSpells.TestMode(false)
        end
        if not s or not s.enabled or not s.showIcons or #activeList == 0 then
            iconContainer:Hide()
        end
        UpdateLayout()
    end
end

function TargetedSpells.ToggleMover(force)
    local s = GetSettings()
    if force == false then
        TargetedSpells.ToggleBarMover(false)
        TargetedSpells.ToggleIconMover(false)
        TargetedSpells.TestMode(false)
        return
    end
    if s and s.showBars then
        TargetedSpells.ToggleBarMover(force)
    end
    if s and s.showIcons then
        TargetedSpells.ToggleIconMover(force)
    end
end

-- ============================================================================
-- INITIALIZE & APPLY SETTINGS
-- ============================================================================
function TargetedSpells.Initialize()
    if barContainer then return end

    local s = GetSettings()
    if not s then return end

    -- 1. Bar Container Frame
    barContainer = CreateFrame("Frame", "GravityUI_TargetedSpells_Bars", UIParent, "BackdropTemplate")
    barContainer:SetSize(s.width or 200, s.height or 20)
    barContainer:SetPoint("CENTER", UIParent, "CENTER", s.x or 0, s.y or -140)
    barContainer:SetMovable(true)
    barContainer:SetClampedToScreen(true)

    local barMover = CreateFrame("Frame", nil, barContainer, "BackdropTemplate")
    barMover:SetAllPoints()
    barMover:SetFrameStrata("DIALOG")
    barMover:EnableMouse(true)
    barMover:RegisterForDrag("LeftButton")
    barMover:Hide()

    local barTxt = barMover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    barTxt:SetPoint("CENTER")
    barTxt:SetText("Targeted Spells (Bars)")

    barMover:SetScript("OnDragStart", function() barContainer:StartMoving() end)
    barMover:SetScript("OnDragStop", function()
        barContainer:StopMovingOrSizing()
        local x, y = barContainer:GetCenter()
        local ux, uy = UIParent:GetCenter()
        s.x = x - ux
        s.y = y - uy
    end)
    barContainer.mover = barMover

    -- 2. Icon Container Frame (represents Slot 1 at Anchor X=0, Y=0)
    iconContainer = CreateFrame("Frame", "GravityUI_TargetedSpells_Icons", UIParent, "BackdropTemplate")
    iconContainer:SetSize(s.iconSize or 36, s.iconSize or 36)
    iconContainer:SetPoint("CENTER", UIParent, "CENTER", s.iconX or 0, s.iconY or -80)
    iconContainer:SetMovable(true)
    iconContainer:SetClampedToScreen(true)

    local iconMover = CreateFrame("Frame", nil, iconContainer, "BackdropTemplate")
    iconMover:SetAllPoints()
    iconMover:SetFrameStrata("DIALOG")
    iconMover:EnableMouse(true)
    iconMover:RegisterForDrag("LeftButton")
    iconMover:Hide()

    -- Title Badge positioned above the anchor icon box so it doesn't obstruct icons
    local titleBadge = CreateFrame("Frame", nil, iconMover, "BackdropTemplate")
    titleBadge:SetPoint("BOTTOM", iconMover, "TOP", 0, 6)
    titleBadge:SetSize(160, 20)
    titleBadge:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    titleBadge:SetBackdropColor(0.06, 0.06, 0.06, 0.90)
    titleBadge:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.9)

    local iconTxt = titleBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    iconTxt:SetPoint("CENTER")
    iconTxt:SetText("Targeted Spells (Icons)")

    -- Center Slot Anchor Marker inside the exact X=0 icon box
    local slotTxt = iconMover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slotTxt:SetPoint("CENTER")
    slotTxt:SetText("Slot 1\n[ X=0 ]")
    slotTxt:SetTextColor(1, 0.82, 0, 1)
    slotTxt:SetShadowOffset(1, -1)
    slotTxt:SetShadowColor(0, 0, 0, 1)

    iconMover.titleBadge = titleBadge
    iconMover.titleText  = iconTxt
    iconMover.slotText   = slotTxt

    iconMover:SetScript("OnDragStart", function() iconContainer:StartMoving() end)
    iconMover:SetScript("OnDragStop", function()
        iconContainer:StopMovingOrSizing()
        local x, y = iconContainer:GetCenter()
        local ux, uy = UIParent:GetCenter()
        s.iconX = x - ux
        s.iconY = y - uy
    end)
    iconContainer.mover = iconMover

    -- Update Frame
    updateFrame = CreateFrame("Frame", "GravityUI_TargetedSpellsUpdate", UIParent)
    updateFrame:SetScript("OnUpdate", OnUpdateTicker)
    updateFrame:Hide()

    -- Register with Mover System
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("TargetedSpellsBars", barContainer, function(frame, enabled, force)
            TargetedSpells.ToggleBarMover(force)
        end, "Targeted Spells (Bars)")

        ns.Movers:Register("TargetedSpellsIcons", iconContainer, function(frame, enabled, force)
            TargetedSpells.ToggleIconMover(force)
        end, "Targeted Spells (Icons)")
    end

    TargetedSpells.ApplySettings()
end

function TargetedSpells.ApplySettings()
    local s = GetSettings()
    if not barContainer or not iconContainer or not s then return end

    if not zoneListener then
        zoneListener = CreateFrame("Frame")
        zoneListener:SetScript("OnEvent", function(self, event)
            CheckZoneState()
        end)
        zoneListener:RegisterEvent("PLAYER_ENTERING_WORLD")
        zoneListener:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    end

    barContainer:ClearAllPoints()
    barContainer:SetSize(s.width or 200, s.height or 20)
    barContainer:SetPoint("CENTER", UIParent, "CENTER", s.x or 0, s.y or -140)

    iconContainer:ClearAllPoints()
    iconContainer:SetSize(s.iconSize or 36, s.iconSize or 36)
    iconContainer:SetPoint("CENTER", UIParent, "CENTER", s.iconX or 0, s.iconY or -80)

    CheckZoneState()
    if ns.SyncEllesmereTargetedSpells then ns.SyncEllesmereTargetedSpells() end
end

-- ============================================================================
-- CHAT COMMANDS
-- ============================================================================
if ns.Addon then
    ns.Addon:RegisterChatCommand("gravitytargeted", function()
        TargetedSpells.TestMode()
    end)
end
