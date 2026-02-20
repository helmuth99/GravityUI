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
            button._guiNormal = button:CreateTexture(nil, "OVERLAY", nil, 1)
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
            button._guiGloss = button:CreateTexture(nil, "OVERLAY", nil, 2)
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
local function IsMouseOverBar(barKey)
    local frame = _G[BAR_FRAMES[barKey]]
    if frame and frame:IsMouseOver() then return true end
    
    local buttons = GetBarButtons(barKey)
    if not buttons or #buttons == 0 then return false end

    -- Check individual buttons
    for _, btn in ipairs(buttons) do
        if btn:IsMouseOver() then return true end
    end
    
    return false
end

local fadeFrame = CreateFrame("Frame")
local barStates = {}

local function UpdateFade(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.05 then return end
    -- Pass the accumulated elapsed time to the Logic
    local tick = self.elapsed
    self.elapsed = 0
    
    local db = GetDB()
    if not db or not db.fade or not db.fade.enabled then 
        self:SetScript("OnUpdate", nil)
        return 
    end

    local currentTime = GetTime()
    local inCombat = InCombatLockdown()
    
    -- OPTIMIZATION: Short-Circuit checks during combat if "Always Show in Combat" is enabled
    -- No need to check individual mouseovers if everything must be visible anyway.
    if inCombat and db.fade.alwaysShowInCombat then
        for barKey, frameName in pairs(BAR_FRAMES) do
            local frame = _G[frameName]
            local buttons = GetBarButtons(barKey)
            
            -- Just enforce target alpha 1
            local barState = barStates[barKey]
            if not barState then 
                barStates[barKey] = { currentAlpha = 1, lastHoverTime = 0 }
                barState = barStates[barKey]
            end
            
            -- Smooth fade in if needed, or snap if close
            local targetAlpha = 1
            if math.abs(barState.currentAlpha - targetAlpha) > 0.01 then
                local duration = db.fade.fadeInDuration or 0.2
                local step = tick / duration
                barState.currentAlpha = math.min(targetAlpha, barState.currentAlpha + step)
                
                if frame then frame:SetAlpha(barState.currentAlpha) end
                for _, btn in ipairs(buttons) do
                    if not btn._guiHiddenEmpty then
                        btn:SetAlpha(barState.currentAlpha)
                    end
                end
            elseif barState.currentAlpha ~= targetAlpha then
                barState.currentAlpha = targetAlpha
                if frame then frame:SetAlpha(targetAlpha) end
                for _, btn in ipairs(buttons) do
                    if not btn._guiHiddenEmpty then
                        btn:SetAlpha(targetAlpha)
                    end
                end
            end
        end
        return -- SKIP ALL MOUSEOVER CHECKS
    end

    local isMouseOverAny = false
    
    -- Check if mouse is over any linked bar
    if db.fade.linkBars1to8 then
        for i = 1, 8 do
            if IsMouseOverBar("bar" .. i) then
                isMouseOverAny = true
                break
            end
        end
    end

    for barKey, frameName in pairs(BAR_FRAMES) do
        local frame = _G[frameName]
        local buttons = GetBarButtons(barKey)
        
        -- Proceed if either the frame exists OR we have buttons (fallback for missing MainMenuBar)
        if frame or (buttons and #buttons > 0) then
            local barDB = db.bars[barKey]
            
            -- OPTIMIZATION: If this specific bar is set to Always Show, skip mouseover checks for it
            local forceShow = (barDB and barDB.alwaysShow)
            
            -- Initialize state
            if not barStates[barKey] then 
                local current = 1
                if frame then
                    current = frame:GetAlpha()
                elseif buttons and buttons[1] then
                    current = buttons[1]:GetAlpha()
                end
                barStates[barKey] = { lastHoverTime = 0, currentAlpha = current } 
            end
            local state = barStates[barKey]

            local isHovered = false
            if not forceShow then
                 isHovered = IsMouseOverBar(barKey) or (db.fade.linkBars1to8 and isMouseOverAny and barKey:match("bar%d"))
            end
            
            if isHovered then
                state.lastHoverTime = currentTime
            end
            
            -- Determine visibility respecting delay
            local isVisible = isHovered
            if not isVisible and (currentTime - state.lastHoverTime < (db.fade.fadeOutDelay or 0)) then
                isVisible = true
            end

            local shouldShow = isVisible or forceShow
            
            local targetAlpha = shouldShow and 1 or (db.fade.fadeOutAlpha or 0)
            
            local dirty = false
            if math.abs(state.currentAlpha - targetAlpha) > 0.01 then
                local duration = shouldShow and (db.fade.fadeInDuration or 0.2) or (db.fade.fadeOutDuration or 0.4)
                -- Use tick (accumulated time) for smooth interpolation
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
                if frame then frame:SetAlpha(state.currentAlpha) end
                for _, btn in ipairs(buttons) do
                    if not btn._guiHiddenEmpty then
                        btn:SetAlpha(state.currentAlpha)
                    end
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
            if settings.usabilityDesaturate then
                icon:SetDesaturated(true)
                icon:SetVertexColor(0.6, 0.6, 0.6, 1) -- Slightly brighter when desaturated
            else
                icon:SetDesaturated(false)
                icon:SetVertexColor(0.4, 0.4, 0.4, 1)
            end
            button._guiTinted = "unusable"
            return
        end
    end

    -- Normal
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

local function UpdateAllUsability()
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
    
    mover.bg = mover:CreateTexture(nil, "BACKGROUND")
    mover.bg:SetAllPoints()
    mover.bg:SetColorTexture(0, 0.5, 1, 0.5)
    
    mover.text = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mover.text:SetPoint("CENTER")
    mover.text:SetText(labelText)
    
    mover:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    mover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveMoverPosition(self)
        -- Update the actual frame position
        parentFrame:ClearAllPoints()
        parentFrame:SetPoint("CENTER", self, "CENTER")
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
        
        -- Position
        if settings.position then
            frame:ClearAllPoints()
            frame:SetPoint(settings.position.point, UIParent, settings.position.relativePoint, settings.position.x, settings.position.y)
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
        
        -- Create/Update Mover
        local mover = CreateMover("extraActionButton", frame, "Extra Action Button")
        mover:SetSize(160 * (settings.scale or 1), 80 * (settings.scale or 1))
        mover:ClearAllPoints()
        mover:SetPoint("CENTER", frame, "CENTER")
    end
    
    -- Zone Ability (ZoneAbilityFrame)
    local zoneFrame = _G.ZoneAbilityFrame
    if zoneFrame then
        local settings = db.bars.zoneAbility
        
        -- Scale
        if settings.scale then 
            pcall(function() zoneFrame:SetScale(settings.scale) end)
        end
        
        -- Position
        if settings.position then
            zoneFrame:ClearAllPoints()
            zoneFrame:SetPoint(settings.position.point, UIParent, settings.position.relativePoint, settings.position.x, settings.position.y)
        end
        
        -- Artwork (ZoneAbilityFrame.SpellButton.Style)
        if zoneFrame.SpellButton and zoneFrame.SpellButton.Style then
            if settings.hideArtwork then
                zoneFrame.SpellButton.Style:Hide()
                zoneFrame.SpellButton.Style:SetAlpha(0)
            else
                zoneFrame.SpellButton.Style:Show()
                zoneFrame.SpellButton.Style:SetAlpha(1)
            end
        end
        
        -- Create/Update Mover
        local mover = CreateMover("zoneAbility", zoneFrame, "Zone Ability")
        mover:SetSize(160 * (settings.scale or 1), 80 * (settings.scale or 1))
        mover:ClearAllPoints()
        mover:SetPoint("CENTER", zoneFrame, "CENTER")
    end
end

function ActionBars.ToggleExtraButtonMovers()
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

---------------------------------------------------------------------------
-- REFRESH / PUBLIC API
---------------------------------------------------------------------------
function ns.RefreshActionBars()
    local db = GetDB()
    if not db then return end

    -- Flush Cache
    buttonCache = {}

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
    if g.hideEmptySlots ~= nil then
        SetCVar("alwaysShowActionBars", g.hideEmptySlots and "0" or "1")
    end

    for barKey, _ in pairs(BAR_BUTTONS) do
        local buttons = GetBarButtons(barKey)
        for _, btn in ipairs(buttons) do
            SkinButton(btn, g)
            UpdateButtonText(btn, g)
            UpdateEmptySlotVisibility(btn, g)
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
    
    -- Usability Initial Run
    UpdateAllUsability()
    
    -- Initialize Extra Buttons
    if InitializeExtraButtons then InitializeExtraButtons() end
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
-- Polling functionality removed in favor of event-driven updates to save CPU.
-- Events: ACTIONBAR_UPDATE_USABLE, SPELL_UPDATE_USABLE, UNIT_POWER_UPDATE handle this efficiently.


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
initFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
initFrame:RegisterEvent("SPELL_UPDATE_USABLE")
initFrame:RegisterEvent("UNIT_POWER_UPDATE")
initFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
initFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
initFrame:RegisterEvent("UPDATE_BINDINGS")
initFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
initFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
initFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")

initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        ns.RefreshActionBars()
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_VEHICLE_ACTIONBAR" then
        ns.RefreshActionBars()
    else
        UpdateAllUsability()
    end
end)
