-- GravityUI - Action Bar Core Logic
-- Ported and adapted from legacy GravityUI
local ADDON_NAME, ns = ...

-- Namespace shortcuts
ns.ActionBars = ns.ActionBars or {}
local ActionBars = ns.ActionBars
local C = ns.Colors

---------------------------------------------------------------------------
-- CONSTANTS & TEXTURES
---------------------------------------------------------------------------
local TEXTURE_PATH = "Interface/AddOns/GravityUI/assets/iconskin/"
local TEXTURES = {
    normal = TEXTURE_PATH .. "Normal",
    gloss = TEXTURE_PATH .. "Gloss",
    highlight = TEXTURE_PATH .. "Highlight",
    pushed = TEXTURE_PATH .. "Pushed",
    checked = TEXTURE_PATH .. "Checked",
    flash = TEXTURE_PATH .. "Flash",
}

local BAR_BUTTONS = {
    bar1 = "ActionButton",
    bar2 = "MultiBarBottomLeftButton",
    bar3 = "MultiBarBottomRightButton",
    bar4 = "MultiBarRightButton",
    bar5 = "MultiBarLeftButton",
    bar6 = "MultiBar5Button",
    bar7 = "MultiBar6Button",
    bar8 = "MultiBar7Button",
    pet = "PetActionButton",
    stance = "StanceButton",
}

local BAR_FRAMES = {
    bar1 = "MainMenuBar",
    bar2 = "MultiBarBottomLeft",
    bar3 = "MultiBarBottomRight",
    bar4 = "MultiBarRight",
    bar5 = "MultiBarLeft",
    bar6 = "MultiBar5",
    bar7 = "MultiBar6",
    bar8 = "MultiBar7",
    pet = "PetActionBar",
    stance = "StanceBar",
    microbar = "MicroMenuContainer",
    bags = "BagsBar",
}

-- Blizzard ActionBar frames whose internal state must NOT be touched by addons.
-- Setting alpha on these taints their protected SetFrameStrata/ShowBase chain.
-- Non-protected frames (microbar, bags) can safely use frame-level alpha.
local PROTECTED_BAR_FRAMES = {
    bar1 = true, bar2 = true, bar3 = true, bar4 = true,
    bar5 = true, bar6 = true, bar7 = true, bar8 = true,
}

-- -- REMOVED: SetAlpha(1) on Blizzard bar frames caused taint propagation.
-- Blizzard's UpdateFrameStrata / SetShowGrid chain later triggers
-- ADDON_ACTION_BLOCKED for MultiBarBottomLeft:SetFrameStrata().
-- Alpha is managed by GravityUI's own fading system (UpdateBarFading).

-- Moved to top

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------
local function GetDB()
    local db = ns.GetDB()
    return db and db.actionbars
end

local buttonCache = {}

local function GetBarButtons(barKey)
    if buttonCache[barKey] then return buttonCache[barKey] end

    local buttons = {}
    local prefix = BAR_BUTTONS[barKey]
    if not prefix then 
        buttonCache[barKey] = buttons
        return buttons 
    end
    
    local count = (barKey == "pet" or barKey == "stance") and 10 or 12
    for i = 1, count do
        local btn = _G[prefix .. i]
        if btn then table.insert(buttons, btn) end
    end
    
    buttonCache[barKey] = buttons
    return buttons
end

---------------------------------------------------------------------------
-- BAR-LEVEL ALPHA (SAB-proven pattern)
---------------------------------------------------------------------------
-- Fading is done at the BAR FRAME level, not per-button.
-- SetAlpha() is a C API call that does NOT propagate Lua taint — it is safe
-- to call on protected bar frames at any time, including during combat.
-- Per-button SetAlpha is only used for empty-slot hiding (cosmetic).
-- This approach is 12× fewer API calls per bar per tick and matches the
-- pattern used by SimpleActionBars which has zero taint issues.

local function SetBarFrameAlpha(barKey, alpha)
    -- SPECIAL CASE: bar1 maps to "MainMenuBar" which is the master container
    -- for ALL action bars in WoW 12.x. Setting its alpha would hide everything
    -- and Blizzard's ActionBarController continuously resets it anyway.
    -- For bar1, fade individual buttons instead (same as SAB's "MainActionBar"
    -- approach, but using per-button since we reference the wrong container).
    if barKey == "bar1" then
        local buttons = GetBarButtons(barKey)
        for i = 1, #buttons do
            local btn = buttons[i]
            if not btn._guiHiddenEmpty then
                btn:SetAlpha(alpha)
            end
        end
        return
    end
    local frame = _G[BAR_FRAMES[barKey]]
    if frame then
        frame:SetAlpha(alpha)
    end
end

local function SetSafeButtonAlpha(btn, barKey, alpha)
    -- Used only for per-button visibility (empty slot hiding).
    btn:SetAlpha(alpha)
end

-- Forward declarations
local UpdateButtonText, UpdateEmptySlotVisibility
-- Debounced Update Helpers
-- PERF: Pre-allocated callbacks avoid closure allocation on every event dispatch.
local pendingUsabilityUpdate = false
local function FlushUsabilityUpdate()
    if ns.ActionBars and ns.ActionBars.UpdateAllUsability then
        ns.ActionBars.UpdateAllUsability()
    end
    pendingUsabilityUpdate = false
end
local function RequestUsabilityUpdate()
    if pendingUsabilityUpdate then return end
    pendingUsabilityUpdate = true
    C_Timer.After(0.1, FlushUsabilityUpdate)
end

local pendingRefresh = false
local combatDeferredRefresh = false
local function RequestRefresh()
    if pendingRefresh then return end
    pendingRefresh = true
    C_Timer.After(0.2, function()
        if InCombatLockdown() then
            -- Lightweight in-combat refresh: only update non-protected bars.
            -- TAINT FIX: Protected bars (bar1-8) must NOT be touched from
            -- addon code during combat. Their text/visibility state is managed
            -- by Blizzard's own Update cycle; our hooksecurefunc on the Mixin
            -- methods handles re-styling after each Blizzard update.
            local db = GetDB()
            if db and db.enabled and db.global then
                local g = db.global
                for barKey, _ in pairs(BAR_BUTTONS) do
                    if not PROTECTED_BAR_FRAMES[barKey] then
                        local buttons = GetBarButtons(barKey)
                        for _, btn in ipairs(buttons) do
                            UpdateButtonText(btn, g)
                            UpdateEmptySlotVisibility(btn, g, barKey)
                        end
                    end
                end
            end
            -- Queue a full refresh for when combat ends (e.g. vehicle/override bar exit)
            if not combatDeferredRefresh then
                combatDeferredRefresh = true
                ns.QueueOOCAction(function()
                    combatDeferredRefresh = false
                    if ns.RefreshActionBars then
                        ns.RefreshActionBars()
                    end
                end)
            end
        else
            if ns.RefreshActionBars then
                ns.RefreshActionBars()
            end
        end
        pendingRefresh = false
    end)
end

---------------------------------------------------------------------------
-- BUTTON SKINNING
---------------------------------------------------------------------------
local function SkinButton(button, settings)
    if not button or not settings then return end
    
    -- Strip Blizzard Artwork
    if not button._guiStripped then
        local nt = button:GetNormalTexture()
        if nt then
            nt:SetAlpha(0)
            -- TAINT FIX: Blizzard's UpdateButtonArt() re-shows the NormalTexture
            -- on every bar art refresh. Hook OnShow to keep it hidden permanently.
            if not nt._guiHideHooked then
                nt:HookScript("OnShow", function(self) self:SetAlpha(0) end)
                nt._guiHideHooked = true
            end
        end
        
        local icon = button.icon or button.Icon
        if icon then
            local zoom = 0.07
            icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
            icon:SetAllPoints(button)
        end
        button._guiStripped = true
    end

    -- Backdrop
    if settings.showBackdrop then
        if not button._guiBackdrop then
            button._guiBackdrop = button:CreateTexture(nil, "BACKGROUND", nil, -8)
            button._guiBackdrop:SetColorTexture(0, 0, 0, 1)
            button._guiBackdrop:SetAllPoints(button)
        end
        button._guiBackdropBaseAlpha = settings.backdropAlpha or 0.8
        button._guiBackdrop:SetAlpha(button._guiBackdropBaseAlpha)
        button._guiBackdrop:Show()
    elseif button._guiBackdrop then
        button._guiBackdrop:Hide()
    end

    -- Borders
    if settings.showBorders then
        if not button._guiNormal then
            -- Use BORDER layer (always below OVERLAY where HotKey/Count FontStrings live).
            -- sublayer 7 keeps it on top of BACKGROUND/backdrop but under all OVERLAY text.
            button._guiNormal = button:CreateTexture(nil, "BORDER", nil, 7)
            button._guiNormal:SetTexture(TEXTURES.normal)
            button._guiNormal:SetVertexColor(0, 0, 0, 1)
            button._guiNormal:SetAllPoints(button)
        end
        button._guiNormal:Show()
    elseif button._guiNormal then
        button._guiNormal:Hide()
    end

    -- Gloss
    if settings.showGloss then
        if not button._guiGloss then
            -- OVERLAY sublayer -1: above icon (ARTWORK) but below HotKey/Count text (OVERLAY 0+)
            button._guiGloss = button:CreateTexture(nil, "OVERLAY", nil, -1)
            button._guiGloss:SetTexture(TEXTURES.gloss)
            button._guiGloss:SetBlendMode("ADD")
            button._guiGloss:SetAllPoints(button)
        end
        button._guiGloss:SetVertexColor(1, 1, 1, settings.glossAlpha or 0.6)
        button._guiGloss:Show()
    elseif button._guiGloss then
        button._guiGloss:Hide()
    end
end

---------------------------------------------------------------------------
-- TEXT STYLING
---------------------------------------------------------------------------
UpdateButtonText = function(button, settings)
    if not button or not settings then return end

    -- Keybind Text
    local hotkey = button.HotKey
    if hotkey then
        if settings.showKeybinds then
            -- SECRET VALUE ISOLATION: hotkey:GetText() can return a "secret string"
            -- when the execution path is tainted (e.g., during protected binding updates).
            -- Any string operation (comparison, gsub, concatenation) on a secret value
            -- crashes with "attempt to perform string conversion on a secret string value".
            -- Wrapping in pcall ensures we gracefully skip text processing in tainted contexts.
            local ok, text = pcall(function()
                local t = hotkey:GetText()
                if type(t) ~= "string" then return nil end
                
                -- Filter out Blizzard's RANGE_INDICATOR (dot) as we handle range via icon color
                if t == _G.RANGE_INDICATOR then
                    t = ""
                end

                if t then
                    t = t:gsub("(s%-)", "S")
                    t = t:gsub("(a%-)", "A")
                    t = t:gsub("(c%-)", "C")
                    t = t:gsub("(st%-)", "C") -- German Strg
                    t = t:gsub("(KEY_)", "")
                    t = t:gsub("MOUSEWHEELUP", "WU")
                    t = t:gsub("MOUSEWHEELDOWN", "WD")
                    t = t:gsub("BUTTON3", "M3")
                    t = t:gsub("BUTTON4", "M4")
                    t = t:gsub("BUTTON5", "M5")
                    t = t:gsub("NUMPAD", "N")
                    t = t:gsub("PAGEUP", "PU")
                    t = t:gsub("PAGEDOWN", "PD")
                    t = t:gsub("SPACE", "Spc")
                    t = t:gsub("INSERT", "Ins")
                    t = t:gsub("HOME", "Hm")
                    t = t:gsub("DELETE", "Del")
                    hotkey:SetText(t)
                end
                return t
            end)
            if not ok then text = nil end
            
            hotkey:Show()
            local font, size, outline = hotkey:GetFont()
            hotkey:SetFont(font, settings.keybindFontSize or 12, "OUTLINE")
            hotkey:ClearAllPoints()
            hotkey:SetPoint(settings.keybindAnchor or "TOPRIGHT", settings.keybindOffsetX or 0, settings.keybindOffsetY or -2)
            
            if settings.keybindColor then
                local c = settings.keybindColor
                hotkey:SetVertexColor(c[1], c[2], c[3], c[4])
            end
            
            -- Logic: If 'Hide Empty Keybinds' is ON, hide text if the *slot* is empty (no spell)
            -- OR if the text itself is empty (no binding).
            local shouldHide = false
            if not text or text == "" then
                shouldHide = true
            elseif settings.hideEmptyKeybinds then
                if button.action and not HasAction(button.action) then
                    shouldHide = true
                end
            end
            
            if shouldHide then
                hotkey:Hide()
            end
        else
            hotkey:Hide()
        end
    end

    -- Macro Name
    local name = button.Name
    if name then
        if settings.showMacroNames then
            name:Show()
            local font, size, outline = name:GetFont()
            name:SetFont(font, settings.macroNameFontSize or 10, "OUTLINE")
            name:ClearAllPoints()
            name:SetPoint(settings.macroNameAnchor or "BOTTOM", settings.macroNameOffsetX or 0, settings.macroNameOffsetY or 2)
             if settings.macroNameColor then
                local c = settings.macroNameColor
                name:SetVertexColor(c[1], c[2], c[3], c[4])
            end
        else
            name:Hide()
        end
    end

    -- Stack Count
    local count = button.Count
    if count then
         if settings.showCounts then
            count:Show()
            local font, size, outline = count:GetFont()
            count:SetFont(font, settings.countFontSize or 14, "OUTLINE")
            count:ClearAllPoints()
            count:SetPoint(settings.countAnchor or "BOTTOMRIGHT", settings.countOffsetX or 0, settings.countOffsetY or 2)
             if settings.countColor then
                local c = settings.countColor
                count:SetVertexColor(c[1], c[2], c[3], c[4])
            end
        else
            count:Hide()
        end
    end
end
local hoveredElements = {}

local function OnElementEnter(self)
    local barKey = self._guiBarKey
    if barKey then
        hoveredElements[barKey] = (hoveredElements[barKey] or 0) + 1
    end
    -- PERF: Force 20Hz on next tick for responsive fade-in
    if fadeFrame then fadeFrame._settled = false end
end

local function OnElementLeave(self)
    local barKey = self._guiBarKey
    if barKey then
        hoveredElements[barKey] = math.max(0, (hoveredElements[barKey] or 0) - 1)
    end
    -- PERF: Force 20Hz on next tick for responsive fade-out
    if fadeFrame then fadeFrame._settled = false end
end

local function HookBarElement(frame, barKey)
    if not frame or frame._guiHoverHooked then return end
    -- HookScript on buttons for OnEnter/OnLeave is safe — the hook callbacks
    -- only increment/decrement a Lua counter. They do NOT modify button state,
    -- so there is no taint propagation. This matches SAB's proven pattern.
    -- (The real taint was from UpdateButtonText during combat, now fixed.)
    frame._guiBarKey = barKey
    frame:HookScript("OnEnter", OnElementEnter)
    frame:HookScript("OnLeave", OnElementLeave)
    frame._guiHoverHooked = true
end

local function IsMouseOverBar(barKey)
    -- O(1) event-driven check — populated by HookScript on ALL bars.
    if hoveredElements[barKey] and hoveredElements[barKey] > 0 then return true end
    -- Fallback: MouseIsOver() for bars without individual button hooks
    -- (microbar, bags) whose container frames don't fire OnEnter.
    if not BAR_BUTTONS[barKey] then
        local frame = _G[BAR_FRAMES[barKey]]
        if frame and frame:IsVisible() and frame:IsMouseOver() then return true end
    end
    return false
end

local fadeFrame = CreateFrame("Frame")
local barStates = {}
local barMetadata = {}

-- PERF: Force 20Hz when combat state changes so "alwaysShowInCombat" responds immediately.
local fadeCombatWaker = CreateFrame("Frame")
fadeCombatWaker:RegisterEvent("PLAYER_REGEN_DISABLED")
fadeCombatWaker:RegisterEvent("PLAYER_REGEN_ENABLED")
fadeCombatWaker:SetScript("OnEvent", function()
    if fadeFrame then fadeFrame._settled = false end
end)

local function RefreshBarMetadata()
    wipe(barMetadata)
    for barKey, frameName in pairs(BAR_FRAMES) do
        table.insert(barMetadata, {
            key = barKey,
            frame = _G[frameName],
            buttons = GetBarButtons(barKey)
        })
    end
end

local function UpdateFade(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    -- PERF: Adaptive rate — 20Hz during animation, 5Hz when settled.
    -- Hover detection is now fully event-driven (HookScript on all bars),
    -- so we only need the ticker for smooth fade interpolation.
    local threshold = self._settled and 0.2 or 0.05
    if self.elapsed < threshold then return end
    
    local tick = self.elapsed
    self.elapsed = 0
    
    local db = GetDB()
    if not db or not db.fade or not db.fade.enabled then 
        self:SetScript("OnUpdate", nil)
        return 
    end

    local currentTime = GetTime()
    local inCombat = InCombatLockdown()
    local linkBars = db.fade.linkBars1to8
    local alwaysShowCombat = db.fade.alwaysShowInCombat
    local fadeOutAlpha = db.fade.fadeOutAlpha or 0
    local fadeOutDelay = db.fade.fadeOutDelay or 0
    local fadeInDur = db.fade.fadeInDuration or 0.2
    local fadeOutDur = db.fade.fadeOutDuration or 0.4

    if #barMetadata == 0 then RefreshBarMetadata() end

    -- Link Bars Check — check ALL bars that participate in mouseover fading
    local isMouseOverAnyLink = false
    if linkBars then
        for i = 1, #barMetadata do
            local bk = barMetadata[i].key
            local bdb = db.bars[bk]
            if not (bdb and bdb.alwaysShow) and IsMouseOverBar(bk) then
                isMouseOverAnyLink = true
                break
            end
        end
    end

    local isAnyBarDirty = false

    for i = 1, #barMetadata do
        local meta = barMetadata[i]
        local barKey = meta.key
        local frame = meta.frame
        
        -- Initialize state
        local state = barStates[barKey]
        if not state then 
            local current = 1
            if frame then
                current = frame:GetAlpha()
            end
            barStates[barKey] = { lastHoverTime = 0, currentAlpha = current } 
            state = barStates[barKey]
        end

        local barDB = db.bars[barKey]
        local forceShow = (barDB and barDB.alwaysShow) or (inCombat and alwaysShowCombat)
        
        local isHovered = false
        if not forceShow then
             isHovered = IsMouseOverBar(barKey) or (linkBars and isMouseOverAnyLink)
        end
        
        if isHovered then
            state.lastHoverTime = currentTime
        end
        
        -- Determine visibility respecting delay
        local isVisible = isHovered
        if not isVisible and (currentTime - state.lastHoverTime < fadeOutDelay) then
            isVisible = true
        end

        local shouldShow = isVisible or forceShow
        local targetAlpha = shouldShow and 1 or fadeOutAlpha
        
        local dirty = false
        if math.abs(state.currentAlpha - targetAlpha) > 0.01 then
            local duration = shouldShow and fadeInDur or fadeOutDur
            -- Duration 0 (or near-zero) = instant snap, no interpolation
            if duration < 0.01 then
                state.currentAlpha = targetAlpha
            else
                local step = tick / duration
                if state.currentAlpha < targetAlpha then
                    state.currentAlpha = math.min(targetAlpha, state.currentAlpha + step)
                else
                    state.currentAlpha = math.max(targetAlpha, state.currentAlpha - step)
                end
            end
            dirty = true
        elseif state.currentAlpha ~= targetAlpha then
            state.currentAlpha = targetAlpha
            dirty = true
        end

        if dirty then
            isAnyBarDirty = true
            -- BAR-LEVEL ALPHA: SetAlpha on the bar frame itself.
            -- This is a C API call — safe on all frames including protected.
            -- Matches SAB's proven pattern. All children (buttons, cooldowns,
            -- overlays) inherit the bar's alpha multiplicatively.
            SetBarFrameAlpha(barKey, state.currentAlpha)
        end
    end

    -- PERF: Adaptive throttle — when all bars are settled at their target alpha,
    -- slow down to 5Hz (0.2s) since hover detection is event-driven.
    self._settled = not isAnyBarDirty
end

---------------------------------------------------------------------------
-- RETAIL SAFETY WRAPPERS
---------------------------------------------------------------------------
local function SafeIsActionInRange(action)
    local ok, result = pcall(IsActionInRange, action)
    if not ok then return nil end
    if result == false then return false end
    if result == true then return true end
    return nil
end

local function SafeIsUsableAction(action)
    local ok, usable, noMana = pcall(IsUsableAction, action)
    if not ok then return true end
    return usable and true or false
end

---------------------------------------------------------------------------
-- USABILITY INDICATORS
---------------------------------------------------------------------------
local function UpdateButtonUsability(button, settings)
    if not button.action then return end
    local icon = button.icon or button.Icon
    if not icon then return end

    if not settings.usabilityIndicator then
        if button._guiTinted then
            icon:SetVertexColor(1, 1, 1, 1)
            icon:SetDesaturated(false)
            button._guiTinted = nil
        end
        return
    end

    -- Usability Check
    if settings.usabilityIndicator then
        local isUsable = SafeIsUsableAction(button.action)

        if not isUsable then
            -- Performance: Only call API if state actually changed (prevents Blizzard overlay cascade)
            if button._guiTinted ~= "unusable" then
                if settings.usabilityDesaturate then
                    icon:SetDesaturated(true)
                    icon:SetVertexColor(0.6, 0.6, 0.6, 1)
                else
                    icon:SetDesaturated(false)
                    icon:SetVertexColor(0.4, 0.4, 0.4, 1)
                end
                button._guiTinted = "unusable"
            end
            return
        end
    end

    -- Normal: Only reset if we were previously tinted
    if button._guiTinted then
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetDesaturated(false)
        button._guiTinted = nil
    end
end

UpdateEmptySlotVisibility = function(button, settings, barKey)
    -- TAINT FIX: Never modify protected action buttons during combat.
    -- Reading button.action and calling HasAction() from addon code in combat
    -- taints the execution context, causing ADDON_ACTION_BLOCKED downstream.
    if PROTECTED_BAR_FRAMES[barKey] and InCombatLockdown() then return end

    if not settings or not settings.hideEmptySlots then
        if button._guiHiddenEmpty then
            SetSafeButtonAlpha(button, barKey, 1)
            button._guiHiddenEmpty = nil
        end
        return
    end

    -- Skip if it's not a standard action button (e.g. bags, microbar)
    local action = button.action or (button.GetAction and button:GetAction())
    if action then
        local hasAction = HasAction(action)
        if hasAction then
            SetSafeButtonAlpha(button, barKey, 1)
            button._guiHiddenEmpty = nil
        else
            SetSafeButtonAlpha(button, barKey, 0)
            button._guiHiddenEmpty = true
        end
    elseif button._guiHiddenEmpty then
        SetSafeButtonAlpha(button, barKey, 1)
        button._guiHiddenEmpty = nil
    end
end

local function UpdateAllEmptySlots()
    local db = GetDB()
    if not db or not db.enabled then return end
    local g = db.global
    
    for barKey, _ in pairs(BAR_BUTTONS) do
        local buttons = GetBarButtons(barKey)
        for _, btn in ipairs(buttons) do
            UpdateEmptySlotVisibility(btn, g, barKey)
        end
    end
end

function ActionBars.UpdateAllUsability()
    local db = GetDB()
    if not db or not db.enabled then return end
    local g = db.global
    
    for barKey, _ in pairs(BAR_BUTTONS) do
        local buttons = GetBarButtons(barKey)
        for _, btn in ipairs(buttons) do
            if btn:IsVisible() then
                UpdateButtonUsability(btn, g)
            end
        end
    end
end

---------------------------------------------------------------------------
-- EXTRA BUTTONS (Skinning & Scale)
-- Positioning is handled by Blizzard's Edit Mode — no custom movers needed.
---------------------------------------------------------------------------

-- Initialize Extra Buttons (Artwork & Skinning only)
-- Positioning and Scale are delegated to Blizzard's Edit Mode.
-- TAINT FIX (2026-08): Removed SetScale/EnableMouse on ExtraAbilityContainer
-- and ZoneAbilityFrame. These protected-frame modifications tainted Blizzard's
-- ActionBarController chain, silently blocking ALL SetCooldown() calls and
-- causing cooldown swipes/text to disappear after M+ key start.
InitializeExtraButtons = function()
    local db = GetDB()
    if not db or not db.enabled then return end
    
    -- Extra Action Button — cosmetic skinning only
    if ExtraActionButton1 then
        local settings = db.bars.extraActionButton
        
        -- Artwork (The texture is usually on ExtraActionButton1.style)
        if ExtraActionButton1.style then
            if settings.hideArtwork then
                ExtraActionButton1.style:Hide()
                ExtraActionButton1.style:SetAlpha(0)
            else
                ExtraActionButton1.style:Show()
                ExtraActionButton1.style:SetAlpha(1)
            end
        end

        -- Apply same skinning as regular action buttons (border, backdrop, icon zoom)
        SkinButton(ExtraActionButton1, { showBorders = true, showBackdrop = true })
    end
    
    -- Zone Ability — cosmetic skinning only
    local zoneFrame = _G.ZoneAbilityFrame
    if zoneFrame then
        local zSettings = db.bars.zoneAbility
        
        -- Artwork (ZoneAbilityFrame.SpellButton.Style)
        if zoneFrame.SpellButton and zoneFrame.SpellButton.Style then
            if zSettings.hideArtwork then
                zoneFrame.SpellButton.Style:Hide()
                zoneFrame.SpellButton.Style:SetAlpha(0)
            else
                zoneFrame.SpellButton.Style:Show()
                zoneFrame.SpellButton.Style:SetAlpha(1)
            end
        end

        -- Apply same skinning as regular action buttons (border, backdrop, icon zoom)
        local function SkinZoneBtn(btn)
            if btn then SkinButton(btn, { showBorders = true, showBackdrop = true }) end
        end
        if zoneFrame.SpellButton then
            SkinZoneBtn(zoneFrame.SpellButton)
        elseif zoneFrame.SpellButtonContainer then
            if zoneFrame.SpellButtonContainer.EnumerateActive then
                for btn in zoneFrame.SpellButtonContainer:EnumerateActive() do
                    SkinZoneBtn(btn)
                end
            end
        end
    end
end


-- ---------------------------------------------------------------------------
-- ZONE ABILITY KEYBIND MIRROR
-- ---------------------------------------------------------------------------
-- In WoW 12.x, ZoneAbilityFrame.SpellButton is nil — the button lives inside
-- ZoneAbilityFrame.SpellButtonContainer (object pool). Use EnumerateActive().
-- IMPORTANT: The proxy must be SHOWN (not hidden) for SetOverrideBindingClick.
local zoneKeybindOwner = CreateFrame("Frame")
local zoneAbilityProxy = CreateFrame("Button", "GravityUI_ZoneAbilityProxy", UIParent, "SecureActionButtonTemplate")
local zoneKeybindPending = false  -- deferred apply requested while in combat
zoneAbilityProxy:SetSize(1, 1)
zoneAbilityProxy:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, 0) -- off-screen
zoneAbilityProxy:SetAlpha(0) -- invisible but shown
zoneAbilityProxy:RegisterForClicks("AnyDown", "AnyUp")
zoneAbilityProxy:SetAttribute("type", "macro")

local function GetZoneAbilityButton()
    if not ZoneAbilityFrame then return nil end
    if ZoneAbilityFrame.SpellButton then
        return ZoneAbilityFrame.SpellButton
    end
    local container = ZoneAbilityFrame.SpellButtonContainer
    if container then
        if container.EnumerateActive then
            for btn in container:EnumerateActive() do
                return btn
            end
        elseif container.GetChildren then
            local btn = select(1, container:GetChildren())
            if btn then return btn end
        end
    end
    return nil
end

-- Formats a raw keybind string the same way GravityUI's UpdateButtonText does
local function FormatKeyText(key)
    if not key then return "" end
    key = key:gsub("(s%-)", "S")
    key = key:gsub("(a%-)", "A")
    key = key:gsub("(c%-)", "C")
    key = key:gsub("(st%-)", "C")
    key = key:gsub("(KEY_)", "")
    key = key:gsub("MOUSEWHEELUP", "WU")
    key = key:gsub("MOUSEWHEELDOWN", "WD")
    key = key:gsub("BUTTON3", "M3")
    key = key:gsub("BUTTON4", "M4")
    key = key:gsub("BUTTON5", "M5")
    key = key:gsub("NUMPAD", "N")
    key = key:gsub("PAGEUP", "PU")
    key = key:gsub("PAGEDOWN", "PD")
    key = key:gsub("SPACE", "Spc")
    key = key:gsub("INSERT", "Ins")
    key = key:gsub("HOME", "Hm")
    key = key:gsub("DELETE", "Del")
    return key
end

-- Adds or updates the keybind label on the zone ability button
local function UpdateZoneAbilityKeybindText(spellBtn, keyText)
    if not spellBtn then return end
    -- Create FontString if it doesn't exist yet
    if not spellBtn._guiHotKey then
        spellBtn._guiHotKey = spellBtn:CreateFontString(nil, "OVERLAY")
        spellBtn._guiHotKey:SetFont("Fonts/FRIZQT__.TTF", 12, "OUTLINE")
        spellBtn._guiHotKey:SetTextColor(1, 1, 1, 1)
        spellBtn._guiHotKey:SetPoint("TOPRIGHT", spellBtn, "TOPRIGHT", 0, -2)
    end
    if keyText and keyText ~= "" then
        spellBtn._guiHotKey:SetText(keyText)
        spellBtn._guiHotKey:Show()
    else
        spellBtn._guiHotKey:SetText("")
        spellBtn._guiHotKey:Hide()
    end
end

local function ApplyZoneAbilityKeybind()
    -- ClearOverrideBindings / SetOverrideBindingClick are protected functions:
    -- calling them during combat lockdown causes ADDON_ACTION_BLOCKED.
    if InCombatLockdown() then
        zoneKeybindPending = true
        return
    end
    zoneKeybindPending = false
    ClearOverrideBindings(zoneKeybindOwner)

    local db = GetDB()
    if not db or not db.bars or not db.bars.zoneAbility then return end

    -- If disabled, clear the keybind label too
    if not db.bars.zoneAbility.mirrorExtraKeybind then
        UpdateZoneAbilityKeybindText(GetZoneAbilityButton(), nil)
        return
    end

    local key1 = GetBindingKey("EXTRAACTIONBUTTON1")
    local key2 = select(2, GetBindingKey("EXTRAACTIONBUTTON1"))
    if not key1 then return end

    local spellBtn = GetZoneAbilityButton()
    if not spellBtn then return end

    -- Strategy 1: button has a global name → bind directly
    local btnName = spellBtn:GetName()
    if btnName then
        SetOverrideBindingClick(zoneKeybindOwner, false, key1, btnName, "LeftButton")
        if key2 then SetOverrideBindingClick(zoneKeybindOwner, false, key2, btnName, "LeftButton") end
        UpdateZoneAbilityKeybindText(spellBtn, FormatKeyText(key1))
        return
    end

    -- Strategy 2: cast by spell name via macro (C_Spell.GetSpellInfo for TWW)
    local spellID = spellBtn.spellID
    local spellName
    if spellID then
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            spellName = info and info.name
        end
    end

    if spellName then
        zoneAbilityProxy:SetAttribute("type", "macro")
        zoneAbilityProxy:SetAttribute("macrotext", "/cast " .. spellName)
        SetOverrideBindingClick(zoneKeybindOwner, false, key1, "GravityUI_ZoneAbilityProxy", "LeftButton")
        if key2 then SetOverrideBindingClick(zoneKeybindOwner, false, key2, "GravityUI_ZoneAbilityProxy", "LeftButton") end
        UpdateZoneAbilityKeybindText(spellBtn, FormatKeyText(key1))
        return
    end

    -- Strategy 3: fallback — forward click to zone ability button
    zoneAbilityProxy:SetAttribute("type", "click")
    zoneAbilityProxy:SetAttribute("clickbutton", spellBtn)
    SetOverrideBindingClick(zoneKeybindOwner, false, key1, "GravityUI_ZoneAbilityProxy", "LeftButton")
    if key2 then SetOverrideBindingClick(zoneKeybindOwner, false, key2, "GravityUI_ZoneAbilityProxy", "LeftButton") end
    UpdateZoneAbilityKeybindText(spellBtn, FormatKeyText(key1))
end

-- Public wrapper exposed to settings page.
-- ApplyZoneAbilityKeybind() now handles the combat guard internally.
function ActionBars.RefreshZoneAbilityKeybind()
    ApplyZoneAbilityKeybind()
end

-- Debug slash command: /gravitydebugzone
SLASH_GRAVITYDEBUGZONE1 = "/gravitydebugzone"
SlashCmdList["GRAVITYDEBUGZONE"] = function()
    print("|cFF30D1FFGravityUI ZoneAbility Debug:|r")
    local spellBtn = GetZoneAbilityButton()
    print("  SpellButton:", spellBtn and "found" or "|cFFFF4444nil|r")
    if spellBtn and spellBtn.spellID then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellBtn.spellID)
        print("  Spell:", tostring(info and info.name), "(ID=" .. tostring(spellBtn.spellID) .. ")")
    end
    local key1 = GetBindingKey("EXTRAACTIONBUTTON1")
    print("  ExtraActionButton1 key:", tostring(key1))
    local db = GetDB()
    print("  mirrorExtraKeybind:", tostring(db and db.bars and db.bars.zoneAbility and db.bars.zoneAbility.mirrorExtraKeybind))
    ApplyZoneAbilityKeybind()
    print("  >> ApplyZoneAbilityKeybind() forced.")
end

-- Hook ZoneAbilityFrame:OnShow to reapply when zone ability becomes active
if ZoneAbilityFrame then
    ZoneAbilityFrame:HookScript("OnShow", function()
        C_Timer.After(0.2, ApplyZoneAbilityKeybind)
    end)
end

-- Zone change events + post-combat flush for deferred applies
local zoneAbilityHookFrame = CreateFrame("Frame")
zoneAbilityHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneAbilityHookFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneAbilityHookFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- flush pending apply after combat
zoneAbilityHookFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if zoneKeybindPending then
            C_Timer.After(0.1, ApplyZoneAbilityKeybind)
        end
    else
        C_Timer.After(1.0, ApplyZoneAbilityKeybind)
    end
end)

---------------------------------------------------------------------------
-- REFRESH / PUBLIC API
---------------------------------------------------------------------------
function ns.RefreshActionBars()
    local db = GetDB()
    if not db then return end

    -- Flush Cache
    buttonCache = {}
    RefreshBarMetadata()

    -- Cleanup if disabled
    if not db.enabled then
        -- Reset Global Skinning
        for barKey, _ in pairs(BAR_BUTTONS) do
            local buttons = GetBarButtons(barKey)
            for _, btn in ipairs(buttons) do
                if btn._guiStripped then
                    local icon = btn.icon or btn.Icon
                    if icon then
                        icon:SetTexCoord(0, 1, 0, 1)
                        icon:SetAllPoints(btn)
                    end
                end
                if btn._guiBackdrop then btn._guiBackdrop:Hide() end
                if btn._guiNormal then btn._guiNormal:Hide() end
                if btn._guiGloss then btn._guiGloss:Hide() end
                
                local icon = btn.icon or btn.Icon
                if icon and btn._guiTinted then
                    icon:SetVertexColor(1, 1, 1, 1)
                    icon:SetDesaturated(false)
                    btn._guiTinted = nil
                end
                SetSafeButtonAlpha(btn, barKey, 1)
                btn._guiFadeAlpha = nil
                btn._guiHiddenEmpty = nil
            end
        end

        -- NOTE: We deliberately do NOT touch SetCVar("alwaysShowActionBars") here.
        -- It synchronously triggers MultiActionBar_Update → ShowBase() which is
        -- protected and would cause ADDON_ACTION_BLOCKED. Empty-slot visibility
        -- is handled by GravityUI's own UpdateEmptySlotVisibility (alpha-based).

        -- Disable Fade logic — reset ALL bar frames to full alpha
        fadeFrame:SetScript("OnUpdate", nil)
        for barKey, _ in pairs(BAR_FRAMES) do
            SetBarFrameAlpha(barKey, 1)
        end
        return
    end

    -- Apply Global Skinning
    local g = db.global

    -- Hide Empty Slots (Grid Management)
    -- NOTE: We deliberately do NOT call SetCVar("alwaysShowActionBars") here.
    -- It synchronously triggers Blizzard's ActionBarController_UpdateAll →
    -- MultiActionBar_Update → bar:SetShown() → ShowBase(), which is a
    -- protected function. ANY call to SetCVar from addon code taints this
    -- chain (even via C_Timer.After or OnUpdate) because the engine still
    -- considers it addon-initiated.
    -- Empty-slot visibility is instead handled entirely by GravityUI's own
    -- UpdateEmptySlotVisibility() which uses SetAlpha(0) on individual buttons.
    -- This is purely cosmetic and does not require CVar manipulation.

    for barKey, _ in pairs(BAR_BUTTONS) do
        local frame = _G[BAR_FRAMES[barKey]]
        if frame then HookBarElement(frame, barKey) end
        
        local buttons = GetBarButtons(barKey)
        for _, btn in ipairs(buttons) do
            SkinButton(btn, g)
            UpdateButtonText(btn, g)
            UpdateEmptySlotVisibility(btn, g, barKey)
            HookBarElement(btn, barKey)
        end
    end

    -- Hook mouseover for bars that have no buttons in BAR_BUTTONS
    -- (microbar, bags) — they still need OnEnter/OnLeave for fade detection.
    for barKey, frameName in pairs(BAR_FRAMES) do
        if not BAR_BUTTONS[barKey] then
            local frame = _G[frameName]
            if frame then
                HookBarElement(frame, barKey)
                -- Also hook ALL direct children (micro buttons, bag slots)
                -- regardless of widget type — some are Frames, not Buttons.
                local children = { frame:GetChildren() }
                for _, child in ipairs(children) do
                    HookBarElement(child, barKey)
                end
            end
        end
    end

    -- Toggle Fade logic
    if db.fade.enabled then
        -- Do NOT wipe barStates here — that would discard in-progress fade
        -- animations and cause bars to "blink" (flash to alpha 1 then re-fade).
        -- Only ensure alwaysShow bars are pinned at alpha 1.
        fadeFrame._settled = false  -- Start at 20Hz for initial settle
        fadeFrame:SetScript("OnUpdate", UpdateFade)

        -- Immediately restore bars that have alwaysShow = true
        for barKey, _ in pairs(BAR_FRAMES) do
            local barDB = db.bars[barKey]
            if barDB and barDB.alwaysShow then
                SetBarFrameAlpha(barKey, 1)
                -- Pre-seed state so ticker doesn't re-fade
                barStates[barKey] = { lastHoverTime = 0, currentAlpha = 1 }
            end
        end
    else
        fadeFrame:SetScript("OnUpdate", nil)
        -- Reset ALL bar frames to full alpha
        for barKey, _ in pairs(BAR_FRAMES) do
            SetBarFrameAlpha(barKey, 1)
        end
    end
    
    -- Usability is managed event-driven via ACTIONBAR_UPDATE_USABLE / SPELL_UPDATE_USABLE
    -- Do NOT call UpdateAllUsability() here - it causes SPELL_ACTIVATION_OVERLAY_HIDE
    -- flood on ALL registered buttons at once during initialization
    
    -- Initialize Extra Buttons (cosmetic only, safe in all states)
    if InitializeExtraButtons then InitializeExtraButtons() end

    -- Dominos Skinning (only if both master toggle and Dominos toggle are enabled)
    if C_AddOns.IsAddOnLoaded("Dominos") and db.skinDominos then
        local g = db.global
        local dominosPatterns = {
            { prefix = "DominosActionButton",             from = 1,  to = 24  }, -- Bars 1-2
            { prefix = "MultiBarRightActionButton",       from = 1,  to = 12  }, -- Bar 3
            { prefix = "MultiBarLeftActionButton",        from = 1,  to = 12  }, -- Bar 4
            { prefix = "MultiBarBottomRightActionButton", from = 1,  to = 12  }, -- Bar 5
            { prefix = "MultiBarBottomLeftActionButton",  from = 1,  to = 12  }, -- Bar 6
            { prefix = "DominosActionButton",             from = 73, to = 132 }, -- Bars 7-11
            { prefix = "MultiBar5ActionButton",           from = 1,  to = 12  }, -- Bar 12
            { prefix = "MultiBar6ActionButton",           from = 1,  to = 12  }, -- Bar 13
            { prefix = "MultiBar7ActionButton",           from = 1,  to = 12  }, -- Bar 14
        }
        for _, p in ipairs(dominosPatterns) do
            for i = p.from, p.to do
                local btn = _G[p.prefix .. i]
                if btn then
                    SkinButton(btn, g)
                    UpdateButtonText(btn, g)
                end
            end
        end
    end

    -- Bartender4 Skinning (only if both master toggle and BT4 toggle are enabled)
    -- BT4 uses simple sequential naming: BT4Button1-120 (10 bars × 12 buttons)
    if C_AddOns.IsAddOnLoaded("Bartender4") and db.skinBartender4 then
        local g = db.global
        for i = 1, 120 do
            local btn = _G["BT4Button" .. i]
            if btn then
                SkinButton(btn, g)
                UpdateButtonText(btn, g)
            end
        end
    end
end


---------------------------------------------------------------------------
-- NOTE: SetCVar("alwaysShowActionBars") intentionally NOT used.
-- Any addon-initiated SetCVar call synchronously triggers Blizzard's
-- ActionBarController_UpdateAll → MultiActionBar_Update → ShowBase()
-- (protected). This causes ADDON_ACTION_BLOCKED regardless of deferral
-- mechanism (C_Timer, OnUpdate, etc.). GravityUI uses its own alpha-based
-- empty-slot hiding via UpdateEmptySlotVisibility() instead.
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
-- Polling functionality removed in favor of event-driven updates to save CPU.
-- Events: ACTIONBAR_UPDATE_USABLE, SPELL_UPDATE_USABLE, UNIT_POWER_UPDATE handle this efficiently.

---------------------------------------------------------------------------
-- TAINT-SAFE MIXIN HOOKS (SAB pattern)
---------------------------------------------------------------------------
-- hooksecurefunc on Mixin methods is taint-safe: the hook runs AFTER
-- Blizzard's own protected call, inheriting Blizzard's secure execution
-- context. This replaces the C_Timer.After-based in-combat refresh that
-- tainted the ActionBarController chain.

local function ReapplyButtonStyle(button)
    if not button or not button._guiStripped then return end
    local db = GetDB()
    if not db or not db.enabled or not db.global then return end
    UpdateButtonText(button, db.global)

    -- Re-hide NormalTexture that Blizzard's UpdateButtonArt may have re-shown
    local nt = button.GetNormalTexture and button:GetNormalTexture()
    if nt then nt:SetAlpha(0) end

    -- Re-apply icon zoom (Blizzard's Update resets TexCoords)
    local icon = button.icon or button.Icon
    if icon then
        local zoom = 0.07
        icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
    end
end

if ActionBarActionButtonMixin then
    if type(ActionBarActionButtonMixin.Update) == "function" then
        hooksecurefunc(ActionBarActionButtonMixin, "Update", ReapplyButtonStyle)
    end
    if type(ActionBarActionButtonMixin.UpdateHotkeys) == "function" then
        hooksecurefunc(ActionBarActionButtonMixin, "UpdateHotkeys", ReapplyButtonStyle)
    end
end
if PetActionButtonMixin and type(PetActionButtonMixin.Update) == "function" then
    hooksecurefunc(PetActionButtonMixin, "Update", ReapplyButtonStyle)
end
if StanceButtonMixin and type(StanceButtonMixin.Update) == "function" then
    hooksecurefunc(StanceButtonMixin, "Update", ReapplyButtonStyle)
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Reassert after Edit Mode applies its login-time layout
initFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
-- Note: ACTIONBAR_UPDATE_COOLDOWN removed - fires too frequently (every CD tick)
-- Cooldown display is handled by Blizzard natively; we only need usability state
initFrame:RegisterEvent("SPELL_UPDATE_USABLE")
-- PERF: RegisterUnitEvent filters at engine level — only fires for "player".
-- Action bar usability only depends on the player's own power (mana/rage/energy).
initFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
-- Note: PLAYER_TARGET_CHANGED removed - does not affect spell usability,
-- only range checks (handled by screenindicators.lua crosshair)
initFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
initFrame:RegisterEvent("UPDATE_BINDINGS")
initFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
initFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
initFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")

initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        ns.RefreshActionBars()
        -- Apply zone keybind mirror after initial bindings are loaded
        C_Timer.After(0.5, function() ApplyZoneAbilityKeybind() end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Cosmetic-only: no protected frame ops, short delay is sufficient
        C_Timer.After(0.5, function()
            if InitializeExtraButtons then InitializeExtraButtons() end
        end)
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_VEHICLE_ACTIONBAR" then
        RequestRefresh()
        -- Re-mirror zone keybind whenever bindings change (e.g. player re-bound ExtraActionButton1)
        if event == "UPDATE_BINDINGS" then
            ApplyZoneAbilityKeybind()
        end
    else
        RequestUsabilityUpdate()
    end
end)

---------------------------------------------------------------------------
-- DOMINOS SKINNING
---------------------------------------------------------------------------
-- Dominos reuses Blizzard MultiBar names for bars 3-6 (already skinned).
-- Only DominosActionButton1-24 (bars 1+2) need custom skinning.
-- Skinning is applied via RefreshActionBars() which is called at PLAYER_LOGIN.

ns.SkinDominosButtons = function()
    ns.RefreshActionBars() -- Delegate to the main refresh which includes Dominos
end

-- Hook: when Dominos finishes loading, trigger a refresh once the DB is ready.
local dominosHookFrame = CreateFrame("Frame")
dominosHookFrame:RegisterEvent("ADDON_LOADED")
dominosHookFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Dominos" then
        -- Wait for PLAYER_LOGIN to ensure DB is ready, then re-run the full refresh
        local waitFrame = CreateFrame("Frame")
        waitFrame:RegisterEvent("PLAYER_LOGIN")
        waitFrame:SetScript("OnEvent", function(wf)
            C_Timer.After(0.5, function()
                local db = GetDB()
                if db and db.skinDominos then
                    ns.RefreshActionBars()
                end
            end)
            -- Re-apply skinning (scale, artwork) to extra buttons after Dominos settles
            C_Timer.After(1.0, function()
                InitializeExtraButtons()
            end)
            wf:UnregisterEvent("PLAYER_LOGIN")
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

---------------------------------------------------------------------------
-- DIAGNOSTIC: /gravitydebugcd
-- Helps diagnose taint-related cooldown failures at affected users.
---------------------------------------------------------------------------
SLASH_GRAVITYDEBUGCD1 = "/gravitydebugcd"
SlashCmdList["GRAVITYDEBUGCD"] = function()
    print("|cFF30D1FFGravityUI CD Debug:|r")
    print("  InCombatLockdown:", tostring(InCombatLockdown()))
    local btn = ActionButton1
    if btn and btn.cooldown then
        local start, dur = btn.cooldown:GetCooldownTimes()
        print("  AB1 CD times:", start, dur)
        print("  AB1 CD shown:", tostring(btn.cooldown:IsShown()))
        print("  AB1 CD alpha:", btn.cooldown:GetAlpha())
    end
    if ExtraAbilityContainer then
        print("  ExtraAbility scale:", ExtraAbilityContainer:GetScale())
        print("  ExtraAbility mouseEnabled:", tostring(ExtraAbilityContainer:IsMouseEnabled()))
    end
    local ok, secure = pcall(issecurevariable, ActionButton1, "cooldown")
    if ok then print("  AB1.cooldown secure:", tostring(secure)) end
end

