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

-- Hider frame for absolute hiding
-- Aggressive hooks to keep bars at full opacity initially
C_Timer.After(1, function()
    for i = 1, 8 do
        local barKey = "bar" .. i
        local f = _G[BAR_FRAMES[barKey]]
        if f then
            f:SetAlpha(1)
            -- f:SetScale(1) -- REMOVED: Causes ADDON_ACTION_BLOCKED and overrides EditMode
        end
    end
end)

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

-- Debounced Update Helpers
local pendingUsabilityUpdate = false
local function RequestUsabilityUpdate()
    if pendingUsabilityUpdate then return end
    pendingUsabilityUpdate = true
    C_Timer.After(0.1, function()
        if ns.ActionBars and ns.ActionBars.UpdateAllUsability then
            ns.ActionBars.UpdateAllUsability()
        end
        pendingUsabilityUpdate = false
    end)
end

local pendingRefresh = false
local function RequestRefresh()
    if pendingRefresh then return end
    pendingRefresh = true
    C_Timer.After(0.2, function()
        if ns.RefreshActionBars then
            ns.RefreshActionBars()
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
        if nt then nt:SetAlpha(0) end
        
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
        button._guiBackdrop:SetAlpha(settings.backdropAlpha or 0.8)
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
local function UpdateButtonText(button, settings)
    if not button or not settings then return end

    -- Keybind Text
    local hotkey = button.HotKey
    if hotkey then
        if settings.showKeybinds then
            local text = hotkey:GetText()
            
            -- Filter out Blizzard's RANGE_INDICATOR (dot) as we handle range via icon color
            if text == _G.RANGE_INDICATOR then
                text = ""
            end

            if text then
                text = text:gsub("(s%-)", "S")
                text = text:gsub("(a%-)", "A")
                text = text:gsub("(c%-)", "C")
                text = text:gsub("(st%-)", "C") -- German Strg
                text = text:gsub("(KEY_)", "")
                text = text:gsub("MOUSEWHEELUP", "WU")
                text = text:gsub("MOUSEWHEELDOWN", "WD")
                text = text:gsub("BUTTON3", "M3")
                text = text:gsub("BUTTON4", "M4")
                text = text:gsub("BUTTON5", "M5")
                text = text:gsub("NUMPAD", "N")
                text = text:gsub("PAGEUP", "PU")
                text = text:gsub("PAGEDOWN", "PD")
                text = text:gsub("SPACE", "Spc")
                text = text:gsub("INSERT", "Ins")
                text = text:gsub("HOME", "Hm")
                text = text:gsub("DELETE", "Del")
                hotkey:SetText(text)
            end
            
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
end

local function OnElementLeave(self)
    local barKey = self._guiBarKey
    if barKey then
        hoveredElements[barKey] = math.max(0, (hoveredElements[barKey] or 0) - 1)
    end
end

local function HookBarElement(frame, barKey)
    if not frame or frame._guiHoverHooked then return end
    frame._guiBarKey = barKey
    frame:HookScript("OnEnter", OnElementEnter)
    frame:HookScript("OnLeave", OnElementLeave)
    frame._guiHoverHooked = true
end

local function IsMouseOverBar(barKey)
    -- O(1) Event-driven check
    if hoveredElements[barKey] and hoveredElements[barKey] > 0 then return true end
    
    -- Safety Fallback: Just check the parent frame once (O(1)) instead of looping all buttons
    local frame = _G[BAR_FRAMES[barKey]]
    if frame and frame:IsMouseOver() then return true end
    
    return false
end

local fadeFrame = CreateFrame("Frame")
local barStates = {}
local barMetadata = {}

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
    if self.elapsed < 0.05 then return end
    
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

    -- Link Bars Check
    local isMouseOverAnyLink = false
    if linkBars then
        for i = 1, 8 do
            if IsMouseOverBar("bar" .. i) then
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
        local buttons = meta.buttons
        
        -- Initialize state
        local state = barStates[barKey]
        if not state then 
            local current = 1
            if frame then
                current = frame:GetAlpha()
            elseif buttons and buttons[1] then
                current = buttons[1]:GetAlpha()
            end
            barStates[barKey] = { lastHoverTime = 0, currentAlpha = current } 
            state = barStates[barKey]
        end

        local barDB = db.bars[barKey]
        local forceShow = (barDB and barDB.alwaysShow) or (inCombat and alwaysShowCombat)
        
        local isHovered = false
        if not forceShow then
             isHovered = IsMouseOverBar(barKey) or (linkBars and isMouseOverAnyLink and barKey:match("bar%d"))
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
            local step = tick / duration
            
            if state.currentAlpha < targetAlpha then
                state.currentAlpha = math.min(targetAlpha, state.currentAlpha + step)
            else
                state.currentAlpha = math.max(targetAlpha, state.currentAlpha - step)
            end
            dirty = true
        elseif state.currentAlpha ~= targetAlpha then
            state.currentAlpha = targetAlpha
            dirty = true
        end

        if dirty then
            isAnyBarDirty = true
            if frame then frame:SetAlpha(state.currentAlpha) end
            for j = 1, #buttons do
                local btn = buttons[j]
                if not btn._guiHiddenEmpty then
                    btn:SetAlpha(state.currentAlpha)
                end
            end
        end
    end
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

local function UpdateEmptySlotVisibility(button, settings)
    if not settings or not settings.hideEmptySlots then
        if button._guiHiddenEmpty then
            button:SetAlpha(1)
            button._guiHiddenEmpty = nil
        end
        return
    end

    -- Skip if it's not a standard action button (e.g. bags, microbar)
    local action = button.action or (button.GetAction and button:GetAction())
    if action then
        local hasAction = HasAction(action)
        if hasAction then
            button:SetAlpha(1)
            button._guiHiddenEmpty = nil
        else
            button:SetAlpha(0)
            button._guiHiddenEmpty = true
        end
    elseif button._guiHiddenEmpty then
        button:SetAlpha(1)
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
            UpdateEmptySlotVisibility(btn, g)
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
-- EXTRA BUTTONS (Movers)
---------------------------------------------------------------------------
local movers = {}
local moversLocked = true

-- Guard flag: prevents our own SetPoint calls from retriggering the reassert hook.
local gravityIsPositioning = false

-- Installs hooksecurefunc on each extra button frame's SetPoint so GravityUI
-- reasserts its saved position immediately after any external system moves the frame.
-- Per-frame flags allow retry: ZoneAbilityFrame may not exist at PLAYER_LOGIN
-- but will exist by PLAYER_ENTERING_WORLD. Each call to this function will
-- install hooks for any frames that are now available.
local extraHookInstalled_EAB  = false  -- ExtraAbilityContainer
local extraHookInstalled_Zone = false  -- ZoneAbilityFrame
local function MakeReassert(frameGetter, dbKey)
    return function()
        if gravityIsPositioning then return end
        if InCombatLockdown() then return end
        local db = GetDB()
        if not db or not db.enabled then return end
        local pos = db.bars and db.bars[dbKey] and db.bars[dbKey].position
        if not pos then return end
        C_Timer.After(0, function()
            local f = frameGetter()
            if not f or gravityIsPositioning then return end
            if InCombatLockdown() then return end
            local db2 = GetDB()
            local pos2 = db2 and db2.bars and db2.bars[dbKey] and db2.bars[dbKey].position
            if not pos2 then return end
            gravityIsPositioning = true
            f:ClearAllPoints()
            f:SetPoint(pos2.point, UIParent, pos2.relativePoint, pos2.x, pos2.y)
            gravityIsPositioning = false
        end)
    end
end
local function InstallExtraButtonPositionHooks()
    if not extraHookInstalled_EAB and ExtraAbilityContainer then
        extraHookInstalled_EAB = true
        hooksecurefunc(ExtraAbilityContainer, "SetPoint",
            MakeReassert(function() return ExtraAbilityContainer end, "extraActionButton"))
    end
    if not extraHookInstalled_Zone and _G.ZoneAbilityFrame then
        extraHookInstalled_Zone = true
        hooksecurefunc(_G.ZoneAbilityFrame, "SetPoint",
            MakeReassert(function() return _G.ZoneAbilityFrame end, "zoneAbility"))
    end
end

local function SaveMoverPosition(mover)
    local point, _, relativePoint, x, y = mover:GetPoint()
    local db = GetDB()
    if db and db.bars and db.bars[mover.key] then
        db.bars[mover.key].position = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y
        }
    end
end

local function CreateMover(key, parentFrame, labelText)
    if movers[key] then return movers[key] end
    
    local mover = CreateFrame("Frame", nil, UIParent)
    mover:SetSize(parentFrame:GetWidth(), parentFrame:GetHeight())
    mover:SetFrameStrata("DIALOG")
    mover:EnableMouse(true)
    mover:SetMovable(true)
    mover:SetClampedToScreen(true)
    mover:RegisterForDrag("LeftButton")
    
    mover.text = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mover.text:SetPoint("CENTER")
    mover.text:SetText(labelText)
    
    if ns.Movers and ns.Movers.ApplyEditModeStyle then
        ns.Movers:ApplyEditModeStyle(mover, true) -- Default to true when shown explicitly
    else
        mover.bg = mover:CreateTexture(nil, "BACKGROUND")
        mover.bg:SetAllPoints()
        mover.bg:SetColorTexture(0, 0.5, 1, 0.5)
    end
    
    mover:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    mover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        -- Apply frame position (guard prevents our own SetPoint from triggering the hook)
        gravityIsPositioning = true
        parentFrame:ClearAllPoints()
        parentFrame:SetPoint("CENTER", self, "CENTER")
        gravityIsPositioning = false

        -- Save the mover's raw GetPoint() result — reliable, no coordinate math.
        -- After StopMovingOrSizing() the mover is re-anchored to UIParent TOPLEFT.
        -- Storing this TOPLEFT offset directly and applying it to the game frame
        -- on restore gives a consistent, drift-free position every session.
        local db = GetDB()
        if db and db.bars and db.bars[key] then
            local point, _, relativePoint, x, y = self:GetPoint()
            db.bars[key].position = {
                point         = point         or "TOPLEFT",
                relativePoint = relativePoint or "TOPLEFT",
                x = x or 0,
                y = y or 0,
            }
        end
    end)
    
    mover:Hide()
    mover.key = key
    mover.parentFrame = parentFrame
    movers[key] = mover
    
    return mover
end

-- Initialize Extra Buttons (Art, Scale, Position)
-- Made global for scoping (or move definition up) - Moving up is cleaner, but for now declaring local above Refresh
InitializeExtraButtons = function()
    -- Safety: Cannot modify protected frames (ExtraAbilityContainer) in combat
    if InCombatLockdown() then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        f:SetScript("OnEvent", function(self)
            InitializeExtraButtons()
            self:UnregisterAllEvents()
        end)
        return
    end

    local db = GetDB()
    if not db or not db.enabled then return end
    
    -- Extra Action Button (ExtraAbilityContainer contains the button)
    if ExtraAbilityContainer then
        local settings = db.bars.extraActionButton
        local frame = ExtraAbilityContainer
        
        -- Scale
        if settings.scale then 
            pcall(function() frame:SetScale(settings.scale) end)
        end
        
        -- Position (GravityUI is authoritative — guard flag prevents hook re-entry)
        if settings.position then
            gravityIsPositioning = true
            frame:ClearAllPoints()
            frame:SetPoint(settings.position.point, UIParent, settings.position.relativePoint, settings.position.x, settings.position.y)
            gravityIsPositioning = false
        end
        
        -- Artwork (The texture is usually on ExtraActionButton1.style)
        if ExtraActionButton1 and ExtraActionButton1.style then
            if settings.hideArtwork then
                ExtraActionButton1.style:Hide()
                ExtraActionButton1.style:SetAlpha(0)
            else
                ExtraActionButton1.style:Show()
                ExtraActionButton1.style:SetAlpha(1)
            end
        end

        -- Apply same skinning as regular action buttons (border, backdrop, icon zoom)
        if ExtraActionButton1 then
            SkinButton(ExtraActionButton1, { showBorders = true, showBackdrop = true })
        end

        if not movers["extraActionButton"] then
        local mover = CreateMover("extraActionButton", frame, "Extra Action Button")
        if ns.Movers and ns.Movers.Register then
            ns.Movers:Register("ExtraActionButton", mover, function(f, enabled, force)
                -- Reassert frame positions before showing movers so they appear
                -- in the correct place even if an external system repositioned the frame.
                if enabled or force then
                    InitializeExtraButtons()
                end
                if enabled then
                    mover:Show()
                else
                    mover:Hide()
                end
            end, "Extra Action Button")
        end
    end
    
        local moverEAB = movers["extraActionButton"]
        if moverEAB then
            moverEAB:SetSize(160 * (settings.scale or 1), 80 * (settings.scale or 1))
            moverEAB:ClearAllPoints()
            -- Position the mover at the saved location so it matches the restored frame.
            -- Fall back to centering on the frame only when no saved position exists yet.
            if settings.position then
                moverEAB:SetPoint(settings.position.point, UIParent, settings.position.relativePoint, settings.position.x, settings.position.y)
            else
                moverEAB:SetPoint("CENTER", frame, "CENTER")
            end
        end
    end
    
    -- Zone Ability (ZoneAbilityFrame)
    local zoneFrame = _G.ZoneAbilityFrame
    if zoneFrame then
        local zSettings = db.bars.zoneAbility
        
        -- Scale
        if zSettings.scale then 
            pcall(function() zoneFrame:SetScale(zSettings.scale) end)
        end
        
        -- Position (GravityUI is authoritative — guard flag prevents hook re-entry)
        if zSettings.position then
            gravityIsPositioning = true
            zoneFrame:ClearAllPoints()
            zoneFrame:SetPoint(zSettings.position.point, UIParent, zSettings.position.relativePoint, zSettings.position.x, zSettings.position.y)
            gravityIsPositioning = false
        end
        
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

        if not movers["zoneAbility"] then
            local mover = CreateMover("zoneAbility", zoneFrame, "Zone Ability")
            if ns.Movers and ns.Movers.Register then
                ns.Movers:Register("ZoneAbility", mover, function(f, enabled, force)
                    -- Reassert frame positions before showing movers so they appear
                    -- in the correct place even if an external system repositioned the frame.
                    if enabled or force then
                        InitializeExtraButtons()
                    end
                    if enabled then
                        mover:Show()
                    else
                        mover:Hide()
                    end
                end, "Zone Ability")
            end
        end
        
        local moverZone = movers["zoneAbility"]
        if moverZone then
            moverZone:SetSize(160 * (zSettings.scale or 1), 80 * (zSettings.scale or 1))
            moverZone:ClearAllPoints()
            -- Position the mover at the saved location so it matches the restored frame.
            -- Fall back to centering on the frame only when no saved position exists yet.
            if zSettings.position then
                moverZone:SetPoint(zSettings.position.point, UIParent, zSettings.position.relativePoint, zSettings.position.x, zSettings.position.y)
            else
                moverZone:SetPoint("CENTER", zoneFrame, "CENTER")
            end
        end
    end

    -- Install SetPoint hooks once, so GravityUI reasserts against any future
    -- external repositioning (Edit Mode, Dominos, other addons).
    InstallExtraButtonPositionHooks()
end

function ActionBars.ToggleExtraButtonMovers()
    -- Kept for legacy compatibility / manual slash commands if any, but Edit Mode will handle visibility via ns.Movers
    if InCombatLockdown() then return end
    moversLocked = not moversLocked
    
    if not moversLocked then
        InitializeExtraButtons() -- Ensure movers are created/updated
        local count = 0
        for _, mover in pairs(movers) do
            mover:Show()
            count = count + 1
        end
        print("|cFF30D1FFGravityUI:|r Movers Unlocked (" .. count .. " active).")
    else
        for _, mover in pairs(movers) do
            mover:Hide()
        end
        print("|cFF30D1FFGravityUI:|r Movers Locked.")
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
                btn:SetAlpha(1)
                btn._guiHiddenEmpty = nil
            end
        end

        -- Reset Hide Empty Slots CVar (optional cleanup)
        SetCVar("alwaysShowActionBars", "1")

        -- Disable Fade logic
        fadeFrame:SetScript("OnUpdate", nil)
        for barKey, frameName in pairs(BAR_FRAMES) do
            local f = _G[frameName]
            if f then f:SetAlpha(1) end
            
            -- Also ensure buttons are visible (needed if frame is missing)
            local buttons = GetBarButtons(barKey)
            if buttons then
                for _, btn in ipairs(buttons) do
                    -- Only reset alpha, don't show if hidden by other settings
                    if not btn._guiHiddenEmpty then
                        btn:SetAlpha(1)
                    end
                end
            end
        end
        return
    end

    -- Apply Global Skinning
    local g = db.global

    -- Hide Empty Slots (Grid Management)
    -- Performance: Only call SetCVar if value actually changed (prevents ActionButton_Update cascade on all buttons)
    if g.hideEmptySlots ~= nil then
        local targetVal = g.hideEmptySlots and "0" or "1"
        if GetCVar("alwaysShowActionBars") ~= targetVal then
            SetCVar("alwaysShowActionBars", targetVal)
        end
    end

    for barKey, _ in pairs(BAR_BUTTONS) do
        local frame = _G[BAR_FRAMES[barKey]]
        if frame then HookBarElement(frame, barKey) end
        
        local buttons = GetBarButtons(barKey)
        for _, btn in ipairs(buttons) do
            SkinButton(btn, g)
            UpdateButtonText(btn, g)
            UpdateEmptySlotVisibility(btn, g)
            HookBarElement(btn, barKey)
        end
    end

    -- Toggle Fade logic
    if db.fade.enabled then
        barStates = {} -- Reset states so they re-init with current alpha
        fadeFrame:SetScript("OnUpdate", UpdateFade)
    else
        fadeFrame:SetScript("OnUpdate", nil)
        for barKey, frameName in pairs(BAR_FRAMES) do
            local f = _G[frameName]
            if f then f:SetAlpha(1) end
            
            -- Also ensure buttons are visible (needed if frame is missing)
            local buttons = GetBarButtons(barKey)
            if buttons then
                for _, btn in ipairs(buttons) do
                    if not btn._guiHiddenEmpty then
                        btn:SetAlpha(1)
                    end
                end
            end
        end
    end
    
    -- Usability is managed event-driven via ACTIONBAR_UPDATE_USABLE / SPELL_UPDATE_USABLE
    -- Do NOT call UpdateAllUsability() here - it causes SPELL_ACTIVATION_OVERLAY_HIDE
    -- flood on ALL registered buttons at once during initialization
    
    -- Initialize Extra Buttons
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
-- INITIALIZATION
---------------------------------------------------------------------------
-- Polling functionality removed in favor of event-driven updates to save CPU.
-- Events: ACTIONBAR_UPDATE_USABLE, SPELL_UPDATE_USABLE, UNIT_POWER_UPDATE handle this efficiently.


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Reassert after Edit Mode applies its login-time layout
initFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
-- Note: ACTIONBAR_UPDATE_COOLDOWN removed - fires too frequently (every CD tick)
-- Cooldown display is handled by Blizzard natively; we only need usability state
initFrame:RegisterEvent("SPELL_UPDATE_USABLE")
initFrame:RegisterEvent("UNIT_POWER_UPDATE")
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
        -- WoW's Edit Mode applies its stored layout around PLAYER_ENTERING_WORLD.
        -- 0.1s: reassert after Blizzard's initial layout pass.
        -- 1.5s: safety net after Dominos (1.0s) and any other late-init addons settle.
        C_Timer.After(0.1, function()
            if InitializeExtraButtons then InitializeExtraButtons() end
        end)
        C_Timer.After(1.5, function()
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
-- Also reasserts ExtraButton/ZoneAbility positions since Dominos may move them.
local dominosHookFrame = CreateFrame("Frame")
dominosHookFrame:RegisterEvent("ADDON_LOADED")
dominosHookFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Dominos" then
        -- Wait for PLAYER_LOGIN to ensure DB is ready, then re-run the full refresh
        local waitFrame = CreateFrame("Frame")
        waitFrame:RegisterEvent("PLAYER_LOGIN")
        waitFrame:SetScript("OnEvent", function(wf)
            -- 0.5s: skin refresh; 1.0s: position reassert after Dominos settles
            C_Timer.After(0.5, function()
                local db = GetDB()
                if db and db.skinDominos then
                    ns.RefreshActionBars()
                end
            end)
            C_Timer.After(1.0, function()
                -- Reassert GravityUI positions over whatever Dominos placed
                InitializeExtraButtons()
            end)
            wf:UnregisterEvent("PLAYER_LOGIN")
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Reassert ExtraButton/ZoneAbility positions after WoW Edit Mode saves.
-- EDIT_MODE_LAYOUTS_UPDATED fires whenever the user confirms changes in the
-- Edit Mode UI — at that point Blizzard re-applies the Edit Mode layout and
-- moves our frames. We reassert on the next frame to win.
local editModeReassertFrame = CreateFrame("Frame")
editModeReassertFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
editModeReassertFrame:SetScript("OnEvent", function()
    C_Timer.After(0, function()
        InitializeExtraButtons()
    end)
end)

