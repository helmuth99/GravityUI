---------------------------------------------------------------------------
-- GravityUI - Screen Indicators Module
-- Kombinierte Logik für Cursor (GCD Ring) und Crosshair (Fadenkreuz)
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...

-- Libraries
local LSM = LibStub("LibSharedMedia-3.0", true)

-- Module Namespace
ns.ScreenIndicators = ns.ScreenIndicators or {}
local Screen = ns.ScreenIndicators

-- Constants
local GCD_SPELL_ID = 61304
local UPDATE_THROTTLE = 0.01
local RANGE_CHECK_INTERVAL = 0.2
local DOT_TEXTURE = "Interface/AddOns/GravityUI/assets/textures/dot.tga"

-- Texture paths for Ring
local RING_TEXTURES = {
    thin     = "Interface/AddOns/GravityUI/assets/cursor/gui_ring_thin.png",
    standard = "Interface/AddOns/GravityUI/assets/cursor/gui_ring_standard.png",
    thick    = "Interface/AddOns/GravityUI/assets/cursor/gui_ring_thick.png",
    solid    = "Interface/AddOns/GravityUI/assets/cursor/gui_ring_solid.png",
}

-- Optimized Defaults (Prevent GC Churn)
local DEFAULT_CURSOR_COLOR = {0, 0.75, 1, 1}
local DEFAULT_CROSSHAIR_COLOR = {1, 0.95, 0, 1}
local DEFAULT_CROSSHAIR_RANGE_COLOR = {1, 0.2, 0.2, 1}
local DEFAULT_CROSSHAIR_BORDER_COLOR = {0, 0, 0, 1}
local DEFAULT_COMBAT_TEXT_COLOR = {1, 1, 1, 1}

-- Reticle options
local RETICLE_OPTIONS = {
    dot     = { path = "Interface/AddOns/GravityUI/assets/cursor/gui_reticle_dot.tga", isAtlas = false },
    cross   = { path = "uitools-icon-plus", isAtlas = true },
    chevron = { path = "uitools-icon-chevron-down", isAtlas = true },
    diamond = { path = "UF-SoulShard-FX-FrameGlow", isAtlas = true },
}

-- Melee Range check spells for various classes
-- Melee Range check spells for various classes (Hash Set for O(1) lookup)
local MELEE_RANGE_ABILITIES = {
    -- Paladin
    [35395] = true,  -- Crusader Strike
    [406647] = true, -- Templar Strike
    [96231] = true,  -- Rebuke
    
    -- Warrior
    [12294] = true,  -- Mortal Strike
    [23881] = true,  -- Bloodthirst
    [23922] = true,  -- Shield Slam
    [20243] = true,  -- Devastate
    [1464] = true,   -- Slam
    [6552] = true,   -- Pummel
    
    -- Rogue
    [193315] = true, -- Sinister Strike
    [1329] = true,   -- Mutilate
    [53] = true,     -- Backstab
    [8676] = true,   -- Ambush
    [1766] = true,   -- Kick
    
    -- Monk
    [100780] = true, -- Tiger Palm
    [107428] = true, -- Rising Sun Kick
    [205523] = true, -- Blackout Kick
    [116705] = true, -- Spear Hand Strike
    
    -- Demon Hunter
    [183752] = true, -- Disrupt
    [162794] = true, -- Chaos Strike
    [201427] = true, -- Annihilation
    [228478] = true, -- Soul Cleave
    [263642] = true, -- Fracture
    
    -- Death Knight
    -- Note: Mind Freeze is 15y, avoided for melee check
    [49020] = true,  -- Obliterate
    [206930] = true, -- Heart Strike
    [85948] = true,  -- Festering Strike
    -- [55090] = true,  -- Scourge Strike (Removed: Can become 30y with Clawing Shadows)
    [49143] = true,  -- Frost Strike
    [49998] = true,  -- Death Strike
    
    -- Druid
    [5221] = true,   -- Shred
    [33917] = true,  -- Mangle
    [6807] = true,   -- Maul
    [106839] = true, -- Skull Bash
    
    -- Shaman
    [17364] = true,  -- Stormstrike
    [60103] = true,  -- Lava Lash
    [7389] = true,   -- Primal Strike
    
    -- Hunter
    [186270] = true, -- Raptor Strike
    [259387] = true, -- Mongoose Bite (Retail)
    [2953] = true,   -- Wing Clip
}

-- Ranged Range check spells (Standard 40y Casts)
local RANGED_RANGE_ABILITIES = {
    -- Mage
    [116] = true,    -- Frostbolt
    [133] = true,    -- Fireball
    [30451] = true,  -- Arcane Blast
    [44425] = true,  -- Arcane Barrage
    
    -- Warlock
    [686] = true,    -- Shadow Bolt
    [29722] = true,  -- Incinerate
    [198590] = true, -- Drain Soul
    [30108] = true,  -- Unstable Affliction
    
    -- Priest
    [585] = true,    -- Smite
    [589] = true,    -- Shadow Word: Pain
    [8092] = true,   -- Mind Blast
    
    -- Hunter
    [193455] = true, -- Cobra Shot
    [56641] = true,  -- Steady Shot
    [185358] = true, -- Arcane Shot
    [217200] = true, -- Barbed Shot
    
    -- Shaman
    [188196] = true, -- Lightning Bolt
    [188389] = true, -- Flame Shock
    [51505] = true,  -- Lava Burst

    -- Druid
    [194153] = true, -- Starfire
    [5176] = true,   -- Wrath
    [8921] = true,   -- Moonfire
    
    -- Evoker
    [361469] = true, -- Living Flame
    [356995] = true, -- Disintegrate
    [362969] = true, -- Azure Strike
}

local cachedRangeSlot = nil -- Optimization: Cache the slot ID of the ability

-- References
local cursorFrame, ringTexture, reticleTexture, gcdCooldown
local crosshairFrame, horizLine, vertLine, horizBorder, vertBorder
local rangeCheckFrame

-- Cached settings
local cachedCursorSettings, cachedCrosshairSettings
local cursorOffsetX, cursorOffsetY = 0, 0 -- Optimization: Upvalues for OnUpdate
local cursorHideOnRightClick = false -- Optimization: Upvalue for Input Hook
local isRightClickHidden = false -- Optimization: Use Alpha instead of Show/Hide to prevent Cooldown recalculation stutter
local lastOutOfRange = nil -- Optimization: State tracker for Crosshair
local function GetCursorSettings()
    if not cachedCursorSettings then
        local db = ns.GetDB()
        cachedCursorSettings = db and db.screenindicators and db.screenindicators.cursor
    end
    return cachedCursorSettings
end

local function GetCrosshairSettings()
    if not cachedCrosshairSettings then
        local db = ns.GetDB()
        cachedCrosshairSettings = db and db.screenindicators and db.screenindicators.crosshair
    end
    return cachedCrosshairSettings
end

---------------------------------------------------------------------------
-- HELPER FUNCTIONS
---------------------------------------------------------------------------

local function GetAccentColor()
    if ns.GetAccentColor then
        return ns.GetAccentColor()
    end
    return 0, 0.75, 1, 1
end

local function ReadSpellCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local t = C_Spell.GetSpellCooldown(spellID)
        if t then
            return t.startTime, t.duration, t.modRate
        end
    end
    return nil, nil, nil
end

---------------------------------------------------------------------------
-- CURSOR (RETICLE) LOGIC - GCD Ring und Cursor-Indikator
---------------------------------------------------------------------------

local function UpdateCursorStatic()
    if not cursorFrame then return end
    local s = GetCursorSettings()
    if not s or not s.enabled then return end

    -- 1. Static Color & Texture (Only on Refresh)
    local r, g, b, a = 1, 1, 1, 1
    if s.useThemeColor then
        r, g, b, a = GetAccentColor()
    else
        local c = s.customColor or DEFAULT_CURSOR_COLOR
        r, g, b, a = unpack(c)
    end

    local style = s.ringStyle or "standard"
    local size = s.ringSize or 40
    local texturePath = RING_TEXTURES[style] or RING_TEXTURES.standard
    
    ringTexture:SetTexture(texturePath)
    ringTexture:SetVertexColor(r, g, b, 1)
    cursorFrame:SetSize(size, size)

    -- Reticle
    local rStyle = s.reticleStyle or "dot"
    local rSize = s.reticleSize or 10
    local rInfo = RETICLE_OPTIONS[rStyle] or RETICLE_OPTIONS.dot
    
    if rInfo.isAtlas then
        reticleTexture:SetAtlas(rInfo.path)
    else
        reticleTexture:SetTexture(rInfo.path)
    end
    reticleTexture:SetSize(rSize, rSize)
    reticleTexture:SetVertexColor(r, g, b, a)

    -- GCD Static Props
    if gcdCooldown then
        gcdCooldown:SetSwipeTexture(texturePath)
        gcdCooldown:SetSwipeColor(r, g, b, InCombatLockdown() and s.inCombatAlpha or s.outCombatAlpha or 0.3) -- Initial alpha
        gcdCooldown:SetReverse(s.gcdReverse or false)
    end
end

local function UpdateCursorDynamic()
    if not cursorFrame then return end
    
    -- Priority: Right Click Hiding (Instant, Alpha-based)
    if isRightClickHidden then
        cursorFrame:SetAlpha(0)
        return
    end

    -- Restore Alpha (Fix for Right-Click logic)
    cursorFrame:SetAlpha(1)
    
    -- Ensure visibility if we are restoring alpha (Fix for 'Hide out of Combat' not showing on combat start)
    if not isRightClickHidden and not cursorFrame:IsShown() then
        -- Only show if logic permits (e.g. InCombat or !HideOutOfCombat)
        local settings = GetCursorSettings()
        if settings and (not settings.hideOutOfCombat or InCombatLockdown()) then
             cursorFrame:Show()
        end
    end

    local s = GetCursorSettings()
    if not s or not s.enabled then return end

    -- 2. Dynamic Alpha (On GCD/Combat State)
    local baseAlpha = InCombatLockdown() and s.inCombatAlpha or s.outCombatAlpha or 0.3
    
    -- Update GCD Swipe Alpha if needed
    if gcdCooldown then
        -- Note: We assume color is constant, only alpha changes, but SetSwipeColor requires RGB too.
        -- We re-fetch RGB to be safe, or cache it? Fetching is cheap.
        local r, g, b
        if s.useThemeColor then
            r, g, b = GetAccentColor()
        else
            local c = s.customColor or DEFAULT_CURSOR_COLOR
            r, g, b = unpack(c)
        end
        gcdCooldown:SetSwipeColor(r, g, b, baseAlpha)
    end

    local ringAlpha = baseAlpha
    if gcdCooldown and gcdCooldown:IsShown() and s.gcdEnabled then
        ringAlpha = baseAlpha * (1 - (s.gcdFadeRing or 0.35))
    end
    ringTexture:SetAlpha(ringAlpha)
end

local function UpdateCursorVisibility()
    if not cursorFrame then return end
    local s = GetCursorSettings()
    
    if not s or not s.enabled then
        cursorFrame:Hide()
        return
    end

    if s.hideOutOfCombat and not InCombatLockdown() then
        cursorFrame:Hide()
    else
        cursorFrame:Show()
    end
end

local function UpdateCursorGCD()
    if not gcdCooldown then return end
    local s = GetCursorSettings()
    if not s or not s.enabled or not s.gcdEnabled then
        gcdCooldown:Hide()
        UpdateCursorDynamic()
        return
    end

    local start, duration, modRate = ReadSpellCooldown(GCD_SPELL_ID)
    if start and duration and duration > 0 then
        gcdCooldown:Show()
        if modRate then
            gcdCooldown:SetCooldown(start, duration, modRate)
        else
            gcdCooldown:SetCooldown(start, duration)
        end
    else
        gcdCooldown:Hide()
    end
    UpdateCursorDynamic()
end

local function CreateCursorFrame()
    if cursorFrame then return end
    
    cursorFrame = CreateFrame("Frame", "GravityUI_CursorIndicator", UIParent)
    cursorFrame:SetFrameStrata("TOOLTIP")
    cursorFrame:EnableMouse(false)
    cursorFrame:SetSize(40, 40)

    ringTexture = cursorFrame:CreateTexture(nil, "BACKGROUND")
    ringTexture:SetAllPoints()

    gcdCooldown = CreateFrame("Cooldown", nil, cursorFrame, "CooldownFrameTemplate")
    gcdCooldown:SetAllPoints()
    gcdCooldown:EnableMouse(false)
    gcdCooldown:SetDrawSwipe(true)
    gcdCooldown:SetDrawEdge(false)
    gcdCooldown:SetHideCountdownNumbers(true)

    reticleTexture = cursorFrame:CreateTexture(nil, "OVERLAY")
    reticleTexture:SetPoint("CENTER")

    -- Optimization: Use upvalues to avoid table lookups in high-frequency OnUpdate
    cursorFrame:SetScript("OnUpdate", function(self)
        local x, y = GetScaledCursorPosition()
        -- Direct upvalue access is faster than table lookup
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x + cursorOffsetX, y + cursorOffsetY)
    end)

    -- Right-click hide functionality
    -- Optimization: Use local boolean to avoid table lookup during input event
    -- Optimization 2: Use SetAlpha(0) via UpdateCursorDynamic instead of Hide() to prevent layout thrashing
    WorldFrame:HookScript("OnMouseDown", function(_, button)
        if button == "RightButton" and cursorHideOnRightClick then
             isRightClickHidden = true
             UpdateCursorDynamic()
        end
    end)

    WorldFrame:HookScript("OnMouseUp", function(_, button)
        if button == "RightButton" and cursorHideOnRightClick then
            isRightClickHidden = false
            -- We call UpdateCursorDynamic to restore alpha. 
            -- UpdateCursorVisibility is for Combat State (Show/Hide) and usually doesn't need to run here unless state desynced.
            UpdateCursorDynamic()
        end
    end)
end

---------------------------------------------------------------------------
-- CROSSHAIR LOGIC - Bildschirm-Fadenkreuz mit Reichweiten-Check
---------------------------------------------------------------------------

local macroCache = {}
local function GetSpellIDFromSlot(slot)
    local actionType, id = GetActionInfo(slot)
    if not id then return nil end
    
    if actionType == "spell" then
        return id
    elseif actionType == "macro" then
        -- Optimization: Check Cache
        if macroCache[id] then
            return macroCache[id] ~= -1 and macroCache[id] or nil
        end

        -- 1. Try Direct API
        local mid = GetMacroSpell(id)
        if mid then 
            macroCache[id] = mid
            return mid 
        end

        -- 2. Fallback: Parse Macro Body
        local _, _, body = GetMacroInfo(id)
        if body then
            -- A. Check #showtooltip
            local tooltips = body:match("#showtooltip%s+([^\n]+)")
            
            -- B. Check /cast or /use if no tooltip
            if not tooltips then
               for line in body:gmatch("[^\r\n]+") do
                   local cleanLine = line:match("^%s*(.+)")
                   if cleanLine then
                       local l = cleanLine:lower()
                       if l:find("^/cast") or l:find("^/use") or l:find("^/castsequence") or l:find("^/wirken") or l:find("^/benutzen") then
                          local payload = cleanLine:match("^/%w+%s+(.+)")
                          if payload then 
                              tooltips = payload
                              break 
                          end
                       end
                   end
               end
            end
            
            -- C. Resolve Name to ID
            if tooltips then
                local cleanName = tooltips:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
                cleanName = cleanName:match("([^;]+)") -- Handle /cast [cond] Spell; OtherSpell
                if cleanName then
                    cleanName = cleanName:gsub("^!", ""):match("^%s*(.-)%s*$")
                    
                    -- Try as Spell Name
                    local info = C_Spell.GetSpellInfo(cleanName)
                    if info and info.spellID then 
                        macroCache[id] = info.spellID
                        return info.spellID 
                    end
                end
            end
        end
        
        -- Cache failure as -1 to avoid re-parsing
        macroCache[id] = -1
    end
    return nil
end

local cachedRangeSlot = nil -- Optimization: Cache the slot ID of the ability
local cachedRangeSpellID = nil -- Optimization: Fallback Spell ID

local function UpdateRangeSlotCache()
    cachedRangeSlot = nil
    cachedRangeSpellID = nil
    
    -- Determine Priority based on Class/Spec
    -- We want to avoid Ranged spells (Arcane Shot) hijacking the crosshair for Melee specs (Survival)
    local _, class = UnitClass("player")
    local spec = GetSpecialization()
    local preferMelee = false -- Default to Neutral/Ranged
    
    if class == "HUNTER" and spec == 3 then preferMelee = true end -- Survival
    if class == "DRUID" and (spec == 2 or spec == 3) then preferMelee = true end -- Feral/Guardian
    if class == "SHAMAN" and spec == 2 then preferMelee = true end -- Enhancement
    if class == "WARRIOR" or class == "ROGUE" or class == "DEATHKNIGHT" or class == "DEMONHUNTER" then preferMelee = true end
    if class == "PALADIN" and spec ~= 1 then preferMelee = true end -- Prot/Ret (Holy is caster-ish but stands in melee, let's say Ret/Prot strong preference)
    if class == "MONK" and spec ~= 2 then preferMelee = true end -- Brew/WW (MW maybe ranged?)

    local bestSlot = nil
    local bestID = nil
    
    -- Scan Action Bars
    for slot = 1, 180 do
        local id = GetSpellIDFromSlot(slot)
        if id then
            local isMelee = MELEE_RANGE_ABILITIES[id]
            local isRanged = RANGED_RANGE_ABILITIES[id]
            
            if isMelee then
                if preferMelee then
                    cachedRangeSlot = slot
                    cachedRangeSpellID = id
                    return -- Found our preferred type!
                elseif not bestSlot then
                    bestSlot = slot -- Found something, save it
                    bestID = id
                end
            elseif isRanged then
                if not preferMelee then
                    cachedRangeSlot = slot
                    cachedRangeSpellID = id
                    return -- Found our preferred type!
                elseif not bestSlot then
                    bestSlot = slot -- Found something, save it
                    bestID = id
                end
            end
        end
    end
    
    cachedRangeSlot = bestSlot
    cachedRangeSpellID = bestID
end

local function IsOutOfRange()
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
        return false
    end

    if IsActionInRange and cachedRangeSlot then
        local inRange = IsActionInRange(cachedRangeSlot)
        if inRange == true then return false
        elseif inRange == false then return true end
    end
    
    -- Fallback: Check Spell Range directly (Fix for Macros where slot check fails)
    if cachedRangeSpellID then
        local inRange = C_Spell.IsSpellInRange(cachedRangeSpellID, "target")
        if inRange == true then return false
        elseif inRange == false then return true end
    end
    
    -- Fallback: InteractDistance(3) is roughly melee (10y)
    -- If we don't have a cached slot, we default to melee check.
    -- For ranged classes without a cached spell, this might be misleading, 
    -- but usually they WILL have a primary spell on bars.
    return not CheckInteractDistance("target", 3)
end

local function UpdateCrosshairAppearance(outOfRange)
    if not crosshairFrame then return end
    local s = GetCrosshairSettings()
    if not s or not s.enabled then return end

    local r, g, b, a
    if outOfRange and s.changeColorOnRange then
        r, g, b, a = unpack(s.outOfRangeColor or DEFAULT_CROSSHAIR_RANGE_COLOR)
    elseif s.useThemeColor then
        r, g, b, a = GetAccentColor()
    else
        local c = s.customColor or DEFAULT_CROSSHAIR_COLOR
        r, g, b, a = unpack(c)
    end

    horizLine:SetColorTexture(r, g, b, a)
    vertLine:SetColorTexture(r, g, b, a)

    local size = s.size or 12
    local thick = s.thickness or 3
    horizLine:SetSize(size * 2, thick)
    vertLine:SetSize(thick, size * 2)

    local bSize = s.borderSize or 2
    horizBorder:SetSize((size * 2) + bSize * 2, thick + bSize * 2)
    vertBorder:SetSize(thick + bSize * 2, (size * 2) + bSize * 2)
    horizBorder:SetColorTexture(s.borderR or 0, s.borderG or 0, s.borderB or 0, s.borderA or 1)
    vertBorder:SetColorTexture(s.borderR or 0, s.borderG or 0, s.borderB or 0, s.borderA or 1)

    crosshairFrame:SetFrameStrata(s.strata or "HIGH")
    crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", s.offsetX or 0, s.offsetY or 0)
    
    local show = true
    if s.onlyInCombat and not InCombatLockdown() then show = false end
    if s.hideUntilOutOfRange and not outOfRange then show = false end
    
    if show then crosshairFrame:Show() else crosshairFrame:Hide() end
end

local function CreateCrosshairFrame()
    if crosshairFrame then return end
    
    crosshairFrame = CreateFrame("Frame", "GravityUI_Crosshair", UIParent)
    crosshairFrame:SetSize(1, 1)

    horizBorder = crosshairFrame:CreateTexture(nil, "BACKGROUND")
    horizBorder:SetPoint("CENTER")
    vertBorder = crosshairFrame:CreateTexture(nil, "BACKGROUND")
    vertBorder:SetPoint("CENTER")

    horizLine = crosshairFrame:CreateTexture(nil, "ARTWORK")
    horizLine:SetPoint("CENTER")
    vertLine = crosshairFrame:CreateTexture(nil, "ARTWORK")
    vertLine:SetPoint("CENTER")

    rangeCheckFrame = CreateFrame("Frame")
    local elapsed = 0
    
    local function CrosshairOnUpdate(self, delta)
        elapsed = elapsed + delta
        if elapsed < RANGE_CHECK_INTERVAL then return end
        elapsed = 0
        
        local s = GetCrosshairSettings()
        if not s or not s.enabled then return end

        if s.changeColorOnRange then
            local isOut = IsOutOfRange()
            if isOut ~= lastOutOfRange then
                UpdateCrosshairAppearance(isOut)
                lastOutOfRange = isOut
            end
        end
    end

    local function UpdateRangeCheckState()
        local s = GetCrosshairSettings()
        if not s or not s.enabled then
             rangeCheckFrame:SetScript("OnUpdate", nil)
             if crosshairFrame then crosshairFrame:Hide() end
             return
        end

        -- Combat Check
        if s.onlyInCombat and not InCombatLockdown() then
             rangeCheckFrame:SetScript("OnUpdate", nil)
             -- Force update to ensure Hide() logic runs if needed
             if lastOutOfRange ~= nil then lastOutOfRange = nil end
             UpdateCrosshairAppearance(false)
             return
        end

        -- Target Check: Only run range check if we have a target
        if UnitExists("target") then
             if rangeCheckFrame:GetScript("OnUpdate") ~= CrosshairOnUpdate then
                 rangeCheckFrame:SetScript("OnUpdate", CrosshairOnUpdate)
                 -- Instant update to catch range immediately
                 local isOut = IsOutOfRange()
                 lastOutOfRange = isOut
                 UpdateCrosshairAppearance(isOut)
             end
        else
             rangeCheckFrame:SetScript("OnUpdate", nil)
             -- Reset to default (In Range) state
             if lastOutOfRange ~= nil then lastOutOfRange = nil end
             UpdateCrosshairAppearance(false)
        end
    end

    rangeCheckFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    rangeCheckFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    rangeCheckFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    rangeCheckFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    rangeCheckFrame:SetScript("OnEvent", UpdateRangeCheckState)
    
    -- Initial State
    UpdateRangeCheckState()
end

---------------------------------------------------------------------------
-- COMBAT STATUS LOGIC - +Combat / -Combat Text Anzeige
---------------------------------------------------------------------------

local CombatTextState = {
    fadeStart = 0,
    fadeStartAlpha = 1,
    fadeTargetAlpha = 0,
    fadeFrame = nil,
    textFrame = nil,
    displayTimer = nil,
}

local function GetCombatStatusSettings()
    local db = ns.GetDB()
    return db and db.screenindicators and db.screenindicators.combatStatus
end

local function OnFadeUpdate(self, elapsed)
    local s = GetCombatStatusSettings()
    local duration = (s and s.fadeTime) or 0.3

    local now = GetTime()
    local progress = math.min((now - CombatTextState.fadeStart) / duration, 1)

    local alpha = CombatTextState.fadeStartAlpha + (CombatTextState.fadeTargetAlpha - CombatTextState.fadeStartAlpha) * progress

    if CombatTextState.textFrame then
        CombatTextState.textFrame:SetAlpha(alpha)
    end

    if progress >= 1 then
        if CombatTextState.textFrame then CombatTextState.textFrame:Hide() end
        self:SetScript("OnUpdate", nil)
    end
end

local function StartFade()
    if not CombatTextState.textFrame then return end
    CombatTextState.fadeStart = GetTime()
    CombatTextState.fadeStartAlpha = CombatTextState.textFrame:GetAlpha()
    CombatTextState.fadeTargetAlpha = 0
    if not CombatTextState.fadeFrame then CombatTextState.fadeFrame = CreateFrame("Frame") end
    CombatTextState.fadeFrame:SetScript("OnUpdate", OnFadeUpdate)
end

local function CreateCombatTextFrame()
    if CombatTextState.textFrame then return end
    local frame = CreateFrame("Frame", "GravityUI_CombatStatus", UIParent)
    frame:SetSize(300, 50)
    frame:SetFrameStrata("TOOLTIP")
    
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    frame.text = text
    frame:Hide()
    CombatTextState.textFrame = frame
end

function Screen.ShowCombatStatus(message, ignoreEnabled)
    local s = GetCombatStatusSettings()
    if not s or (not s.enabled and not ignoreEnabled) then return end

    CreateCombatTextFrame()
    local f = CombatTextState.textFrame
    if not f then return end

    if CombatTextState.displayTimer then CombatTextState.displayTimer:Cancel(); CombatTextState.displayTimer = nil end
    if CombatTextState.fadeFrame then CombatTextState.fadeFrame:SetScript("OnUpdate", nil) end

    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", s.xOffset or 0, s.yOffset or 100)
    
    local font = LSM:Fetch("font", ns.GetDB().general.font or "Gravity")
    f.text:SetFont(font, s.fontSize or 24, "OUTLINE")

    local col = (message == "+Combat") and s.enterCombatColor or s.leaveCombatColor
    f.text:SetTextColor(unpack(col or DEFAULT_COMBAT_TEXT_COLOR))
    f.text:SetText(message)
    
    f:SetAlpha(1)
    f:Show()

    CombatTextState.displayTimer = C_Timer.NewTimer(s.displayTime or 0.8, function()
        StartFade()
        CombatTextState.displayTimer = nil
    end)
end

---------------------------------------------------------------------------
-- PET WARNINGS LOGIC - Dead/Missing oder nicht angreifendes Pet
---------------------------------------------------------------------------

local PetWarningsState = {
    frame = nil,
    ticker = nil,
    preview = false,
}

local function GetPetWarningsSettings()
    local db = ns.GetDB()
    return db and db.screenindicators and db.screenindicators.petWarnings
end

local function HasPetSpec()
    local _, class = UnitClass("player")
    local petClasses = { HUNTER = true, WARLOCK = true, DEATHKNIGHT = true, MAGE = true }
    if not petClasses[class] then return false end
    
    local spec = GetSpecialization()
    if not spec then return true end
    local specID = GetSpecializationInfo(spec)
    
    -- Jäger: Einsamer Wolf (Marksmanship SpecID 254) hat kein Pet
    if class == "HUNTER" and specID == 254 then return false end
    -- DK: Nur Unheilig (SpecID 252) hat ein permanentes Pet
    if class == "DEATHKNIGHT" and specID ~= 252 then return false end
    
    -- Mage: Nur Frost (SpecID 64) hat ein Pet
    if class == "MAGE" then
        if specID ~= 64 then return false end
        -- Check for Lonely Winter (Talent ID 205024)
        if IsPlayerSpell(205024) then return false end
    end
    
    return true
end

local function CreatePetWarningFrame()
    if PetWarningsState.frame then return end
    local frame = CreateFrame("Frame", "GravityUI_PetWarning", UIParent)
    frame:SetSize(400, 50)
    frame:SetFrameStrata("TOOLTIP")
    
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    frame.text = text
    frame:Hide()
    PetWarningsState.frame = frame
end

local function PetAttacking()
    return UnitExists("pettarget")
end

local function CheckPetWarnings()
    if PetWarningsState.preview then return end
    
    local s = GetPetWarningsSettings()
    if not s or not s.enabled or not HasPetSpec() then
        if PetWarningsState.frame then PetWarningsState.frame:Hide() end
        return
    end

    -- Keine Warnung wenn tot oder auf Reittier
    if UnitIsDeadOrGhost("player") or IsMounted() then
        if PetWarningsState.frame then PetWarningsState.frame:Hide() end
        return
    end

    CreatePetWarningFrame()
    local f = PetWarningsState.frame
    local msg = nil

    -- 1. Tot oder fehlt?
    if s.petDeadWarning and (not UnitExists("pet") or UnitIsDead("pet")) then
        msg = s.petDeadText or (UnitIsDead("pet") and "*** PET TOT ***" or "*** BESCHWÖRE PET ***")
    -- 2. Steht nur rum im Kampf?
    elseif s.petAttackWarning and UnitAffectingCombat("player") and UnitExists("pet") and not UnitIsDead("pet") and not PetAttacking() then
        msg = s.petAttackText or "*** PET GREIFT NICHT AN ***"
    end

    if msg then
        local font = LSM:Fetch("font", ns.GetDB().general.font or "Gravity")
        f.text:SetFont(font, s.fontSize or 28, "OUTLINE")
        
        local r, g, b, a = 1, 1, 1, 1
        if s.useThemeColor then
            r, g, b, a = ns.GetAccentColor()
        elseif s.warningColor then
            r, g, b, a = unpack(s.warningColor)
        end
        f.text:SetTextColor(r, g, b, a)
        
        f.text:SetText(msg)
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", s.xOffset or 0, s.yOffset or 150)
        f:Show()
    else
        f:Hide()
    end
end

function Screen.UpdatePetTicker()
    local s = GetPetWarningsSettings()
    local shouldRun = s and s.enabled and HasPetSpec()
    
    if shouldRun and not PetWarningsState.ticker then
        PetWarningsState.ticker = C_Timer.NewTicker(0.5, CheckPetWarnings)
    elseif not shouldRun and PetWarningsState.ticker then
        PetWarningsState.ticker:Cancel()
        PetWarningsState.ticker = nil
        if PetWarningsState.frame then PetWarningsState.frame:Hide() end
    end
end

---------------------------------------------------------------------------
-- PUBLIC API & GLOBAL REFRESH - Schnittstellen für das System
---------------------------------------------------------------------------

function Screen.Refresh()
    -- Invalidate caches
    cachedCursorSettings = nil
    cachedCrosshairSettings = nil
    
    -- FORCE RANGE SLOT UPDATE (Fix for startup race condition)
    UpdateRangeSlotCache()

    local cS = GetCursorSettings()

    if cS and cS.enabled then
        cursorOffsetX = cS.offsetX or 0
        cursorOffsetY = cS.offsetY or 0
        cursorHideOnRightClick = cS.hideOnRightClick or false
        CreateCursorFrame()
        UpdateCursorVisibility()
        UpdateCursorStatic()
        UpdateCursorDynamic()
        UpdateCursorGCD()
    elseif cursorFrame then
        cursorFrame:Hide()
    end

    local chS = GetCrosshairSettings()
    if chS and chS.enabled then
        CreateCrosshairFrame()
        UpdateCrosshairAppearance(IsOutOfRange())
    elseif chS then
        if crosshairFrame then crosshairFrame:Hide() end
    end

    Screen.UpdatePetTicker()
end

function Screen.PreviewPetWarning(warnType)
    local s = GetPetWarningsSettings()
    if not s then return end

    PetWarningsState.preview = true
    CreatePetWarningFrame()
    local f = PetWarningsState.frame
    
    local msg = (warnType == "petDead") and (s.petDeadText or "*** PET TOT ***") or (s.petAttackText or "*** PET GREIFT NICHT AN ***")
    local font = LSM:Fetch("font", ns.GetDB().general.font or "Gravity")
    f.text:SetFont(font, s.fontSize or 28, "OUTLINE")
    
    local r, g, b, a = 1, 1, 1, 1
    if s.useThemeColor then
        r, g, b, a = ns.GetAccentColor()
    elseif s.warningColor then
        r, g, b, a = unpack(s.warningColor)
    end
    f.text:SetTextColor(r, g, b, a)

    f.text:SetText(msg)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", s.xOffset or 0, s.yOffset or 150)
    f:Show()

    if PetWarningsState.previewTimer then PetWarningsState.previewTimer:Cancel() end
    PetWarningsState.previewTimer = C_Timer.NewTimer(3, function()
        f:Hide()
        PetWarningsState.preview = false
    end)
end

function Screen.PreviewCombatStatus(message)
    -- Preview uses ShowCombatStatus but can be called manually
    -- and bypasses the 'enabled' check
    Screen.ShowCombatStatus(message, true)
end

-- Hook for global theme changes
ns.RefreshScreenIndicators = Screen.Refresh

---------------------------------------------------------------------------
-- INITIALIZATION - Event-Registrierung
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("PET_BAR_UPDATE")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:RegisterEvent("UPDATE_MACROS")

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, Screen.Refresh)
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        UpdateCursorVisibility()
        Screen.Refresh()
        Screen.ShowCombatStatus(event == "PLAYER_REGEN_DISABLED" and "+Combat" or "-Combat")
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        UpdateCursorGCD()
    elseif event == "PLAYER_TARGET_CHANGED" then
        if crosshairFrame and crosshairFrame:IsShown() then
            UpdateCrosshairAppearance(IsOutOfRange())
        end
    elseif event == "UNIT_PET" or event == "PET_BAR_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        Screen.UpdatePetTicker()
        if event == "PLAYER_SPECIALIZATION_CHANGED" then UpdateRangeSlotCache() end
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" then
        UpdateRangeSlotCache()
    elseif event == "UPDATE_MACROS" then
        macroCache = {} -- Invalidate Cache
        UpdateRangeSlotCache()
    end
end)

-- Debug Command
SLASH_GRAVITYDEBUGRANGE1 = "/gravitydebugrange"
SlashCmdList["GRAVITYDEBUGRANGE"] = function()
    print("|cFF30D1FFGravityUI Range Debug:|r")
    if cachedRangeSlot then
        local actionType, id = GetActionInfo(cachedRangeSlot)
        local spellID = GetSpellIDFromSlot(cachedRangeSlot)
        local name = spellID and C_Spell.GetSpellInfo(spellID) and C_Spell.GetSpellInfo(spellID).name or "Unknown"
        print("  Current Range Slot: " .. cachedRangeSlot .. " (" .. (actionType or "nil") .. " | ID: " .. (id or "nil") .. " | SpellID: " .. (spellID or "nil") .. " | Name: " .. name .. ")")
        
        local isMelee = spellID and MELEE_RANGE_ABILITIES[spellID]
        local isRanged = spellID and RANGED_RANGE_ABILITIES[spellID]
        print("  Can Crosshair Use? MELEE: " .. (isMelee and "|cFF00FF00YES|r" or "|cFFFF0000NO|r") .. " | RANGED: " .. (isRanged and "|cFF00FF00YES|r" or "|cFFFF0000NO|r"))
    else
        print("  Current Range Slot: |cFFFF0000NONE|r (Using Fallback InteractDistance 3)")
    end

    print("  Scanning Bar 1 (Slots 1-12):")
    for i = 1, 12 do
        local at, aid = GetActionInfo(i)
        if at then
            local sid = GetSpellIDFromSlot(i)
            local sname = sid and C_Spell.GetSpellInfo(sid) and C_Spell.GetSpellInfo(sid).name or "Unknown"
            local isM = sid and MELEE_RANGE_ABILITIES[sid]
            local isR = sid and RANGED_RANGE_ABILITIES[sid]
            local status = ""
            if isM then status = " [MELEE]" elseif isR then status = " [RANGED]" end
            print("    Slot " .. i .. ": " .. at .. " " .. aid .. " -> SpellID: " .. (sid or "nil") .. " (" .. sname .. ")" .. status)
        end
    end
end
