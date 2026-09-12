-- GravityUI - Action Bar Core Logic (Rewrite 2026-09)
-- Own secure action bar frames AND buttons (GravityUIButton/ActionBarButtonTemplate),
-- eliminating the taint surface from reusing Blizzard's protected buttons.
-- Stance/Pet bars reuse Blizzard buttons (own secure handling).
-- Keybinds: SetOverrideBindingClick for custom bars, native commands for standard bars.
-- Paging: RegisterStateDriver + _childupdate-gui-page with explicit action attrs.
-- Cooldowns: Own central dispatcher using SetCooldownFromDurationObject (secret-safe).
local ADDON_NAME, ns = ...

ns.ActionBars = ns.ActionBars or {}
local ActionBars = ns.ActionBars

-------------------------------------------------------------------------------
--  Upvalues
-------------------------------------------------------------------------------
local _G = _G
local ipairs, pairs, type, pcall, tostring, tonumber = ipairs, pairs, type, pcall, tostring, tonumber
local abs, ceil, floor, min, max = math.abs, math.ceil, math.floor, math.min, math.max
local wipe, tinsert = wipe, table.insert
local InCombatLockdown = InCombatLockdown
local hooksecurefunc = hooksecurefunc
local HasAction = HasAction
local GetActionTexture = GetActionTexture
local GetBindingKey = GetBindingKey
local RegisterStateDriver = RegisterStateDriver
local RegisterAttributeDriver = RegisterAttributeDriver
local NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12
local NUM_AB_PAGES = NUM_ACTIONBAR_PAGES or 6
local C_Timer_After = C_Timer.After

-------------------------------------------------------------------------------
--  Constants
-------------------------------------------------------------------------------
local TEXTURE_PATH = "Interface/AddOns/GravityUI/assets/iconskin/"
local TEXTURES = {
    normal    = TEXTURE_PATH .. "Normal",
    gloss     = TEXTURE_PATH .. "Gloss",
    highlight = TEXTURE_PATH .. "Highlight",
    pushed    = TEXTURE_PATH .. "Pushed",
    checked   = TEXTURE_PATH .. "Checked",
    flash     = TEXTURE_PATH .. "Flash",
}

-------------------------------------------------------------------------------
--  External weak-keyed per-frame state table
--  Avoids writing custom properties onto Blizzard-owned frame tables (taint).
-------------------------------------------------------------------------------
ns._guiFD = setmetatable({}, { __mode = "k" })
local function GFD(frame)
    local d = ns._guiFD[frame]
    if not d then d = {}; ns._guiFD[frame] = d end
    return d
end

-------------------------------------------------------------------------------
--  Bar Configuration
-------------------------------------------------------------------------------
local BAR_CONFIG = {
    { key = "MainBar",   label = "Action Bar 1 (Main)", barID = 1,  count = 12, blizzBtnPrefix = "ActionButton",              blizzFrame = "MainMenuBar", nativeMainBar = true },
    { key = "Bar2",      label = "Action Bar 2",        barID = 2,  count = 12, blizzBtnPrefix = "MultiBarBottomLeftButton",   blizzFrame = "MultiBarBottomLeft",  nativeActionPage = 6 },
    { key = "Bar3",      label = "Action Bar 3",        barID = 3,  count = 12, blizzBtnPrefix = "MultiBarBottomRightButton",  blizzFrame = "MultiBarBottomRight", nativeActionPage = 5 },
    { key = "Bar4",      label = "Action Bar 4",        barID = 4,  count = 12, blizzBtnPrefix = "MultiBarRightButton",        blizzFrame = "MultiBarRight",       nativeActionPage = 3 },
    { key = "Bar5",      label = "Action Bar 5",        barID = 5,  count = 12, blizzBtnPrefix = "MultiBarLeftButton",         blizzFrame = "MultiBarLeft",        nativeActionPage = 4 },
    { key = "Bar6",      label = "Action Bar 6",        barID = 6,  count = 12, blizzBtnPrefix = "MultiBar5Button",            blizzFrame = "MultiBar5",           nativeActionPage = 13 },
    { key = "Bar7",      label = "Action Bar 7",        barID = 7,  count = 12, blizzBtnPrefix = "MultiBar6Button",            blizzFrame = "MultiBar6",           nativeActionPage = 14 },
    { key = "Bar8",      label = "Action Bar 8",        barID = 8,  count = 12, blizzBtnPrefix = "MultiBar7Button",            blizzFrame = "MultiBar7",           nativeActionPage = 15 },
    -- Bar9/Bar10: extra bars with NO native Blizzard frame
    { key = "Bar9",      label = "Action Bar 9",        barID = 0,  count = 12, customPage = 2 },
    { key = "Bar10",     label = "Action Bar 10",       barID = 0,  count = 12, customPage = 10 },
    { key = "StanceBar", label = "Stance Bar",          barID = 0,  count = 10, blizzBtnPrefix = "StanceButton",               blizzFrame = "StanceBar", isStance = true },
    { key = "PetBar",    label = "Pet Bar",             barID = 0,  count = 10, blizzBtnPrefix = "PetActionButton",            blizzFrame = "PetActionBar", isPetBar = true },
}

local EXTRA_BARS = {
    { key = "MicroBar",        label = "Micro Menu Bar",    frameName = "MicroMenuContainer",  visibilityOnly = true },
    { key = "BagBar",          label = "Bag Bar",           frameName = "BagsBar",             visibilityOnly = true },
}

local BAR_LOOKUP = {}
for _, info in ipairs(BAR_CONFIG) do BAR_LOOKUP[info.key] = info end
for _, info in ipairs(EXTRA_BARS) do BAR_LOOKUP[info.key] = info end

-- Stock bar frames to hide
local STOCK_BAR_DISPOSAL = {
    { name = "MainActionBar",       retainEvents = true },
    { name = "MainMenuBar" },
    { name = "MultiBarBottomLeft" },
    { name = "MultiBarBottomRight" },
    { name = "MultiBarRight" },
    { name = "MultiBarLeft" },
    { name = "MultiBar5" },
    { name = "MultiBar6" },
    { name = "MultiBar7" },
    { name = "StanceBar" },
    { name = "PetActionBar",       retainEvents = true },
}

-- Native binding command map (Bar key → command prefix for SetOverrideBindingClick)
local BINDING_MAP = {
    MainBar = "ACTIONBUTTON",
    Bar2    = "MULTIACTIONBAR1BUTTON",
    Bar3    = "MULTIACTIONBAR2BUTTON",
    Bar4    = "MULTIACTIONBAR3BUTTON",
    Bar5    = "MULTIACTIONBAR4BUTTON",
    Bar6    = "MULTIACTIONBAR5BUTTON",
    Bar7    = "MULTIACTIONBAR6BUTTON",
    Bar8    = "MULTIACTIONBAR7BUTTON",
    Bar9    = "GRAVITYUI_BAR9_BUTTON",
    Bar10   = "GRAVITYUI_BAR10_BUTTON",
}

-- Page map for action slot calculation
local BAR_KEY_TO_PAGE = {
    MainBar = 1,  Bar2 = 6,  Bar3 = 5,  Bar4 = 3,
    Bar5 = 4,     Bar6 = 13, Bar7 = 14, Bar8 = 15,
    Bar9 = 2,     Bar10 = 10,
}

-- Event lists for per-button registration
local BUTTON_EVENT_LISTS = {
    action = {
        "ACTIONBAR_UPDATE_STATE",
        "ACTIONBAR_UPDATE_USABLE",
        "SPELL_UPDATE_CHARGES",
        "SPELL_UPDATE_ICON",
        "UPDATE_SHAPESHIFT_FORM",
        "PLAYER_ENTERING_WORLD",
    },
    stance = {
        "ACTIONBAR_UPDATE_STATE",
        "UPDATE_SHAPESHIFT_FORMS",
        "UPDATE_SHAPESHIFT_FORM",
        "PLAYER_ENTERING_WORLD",
    },
    pet = {
        "PET_BAR_UPDATE",
        "PET_BAR_UPDATE_COOLDOWN",
        "PET_BAR_UPDATE_USABLE",
        "PLAYER_CONTROL_LOST",
        "PLAYER_CONTROL_GAINED",
        "PLAYER_FARSIGHT_FOCUS_CHANGED",
        "PLAYER_ENTERING_WORLD",
        "PET_BAR_SHOWGRID",
        "PET_BAR_HIDEGRID",
    },
}

-------------------------------------------------------------------------------
--  Helpers
-------------------------------------------------------------------------------
local function GetDB()
    local db = ns.GetDB()
    return db and db.actionbars
end

-- Safe API wrappers
local GetOverrideBarIndex = GetOverrideBarIndex or (C_ActionBar and C_ActionBar.GetOverrideBarIndex) or function() return 14 end
local GetVehicleBarIndex = GetVehicleBarIndex or (C_ActionBar and C_ActionBar.GetVehicleBarIndex) or function() return 12 end
local GetActionBarPage = GetActionBarPage or (C_ActionBar and C_ActionBar.GetActionBarPage) or function() return 1 end

local function SafeIsActionInRange(action)
    local ok, result = pcall(IsActionInRange, action)
    if not ok then return nil end
    if result == false then return false end
    if result == true then return true end
    return nil
end

local function SafeIsUsableAction(action)
    local ok, usable = pcall(IsUsableAction, action)
    if not ok then return true end
    return usable and true or false
end

-------------------------------------------------------------------------------
--  Hidden Dump Frame — reparenting stock frames here is safer than :Hide(),
--  which can trigger taint chains in protected code paths.
-------------------------------------------------------------------------------
local hiddenParent = CreateFrame("Frame", "GravityUIHiddenParent", UIParent)
hiddenParent:SetAllPoints(UIParent)
hiddenParent:Hide()

local function QuietlyHideBlizzButton(btn)
    btn:UnregisterAllEvents()
    btn:SetAttributeNoHandler("statehidden", true)
end

-------------------------------------------------------------------------------
--  Kill Blizzard's event broadcasters at file load
--  Both dispatch to ALL registered buttons, causing mass redraws.
--  Our central dispatcher handles the needed events.
-------------------------------------------------------------------------------
if ActionBarButtonEventsFrame then ActionBarButtonEventsFrame:UnregisterAllEvents() end
if ActionBarActionEventsFrame then ActionBarActionEventsFrame:UnregisterAllEvents() end

-------------------------------------------------------------------------------
--  Broadcaster Precision Kill & Controlled Revive
--  Vehicle/override buttons (OverrideActionBarButton1-6) and ExtraActionButton1
--  still need Blizzard's broadcaster for their cooldown/state updates.
--  Press-and-hold (Evoker empowered spells) needs ACTIONBAR_SLOT_CHANGED.
-------------------------------------------------------------------------------
do
    local _abefEvents = {
        -- Note: ACTIONBAR_UPDATE_COOLDOWN intentionally excluded.
        -- Our central dispatcher handles cooldowns via SetCooldownFromDurationObject.
        -- Blizzard's broadcaster would dispatch SetCooldown with secret values in tainted context.
        "ACTIONBAR_UPDATE_STATE",
        "ACTIONBAR_UPDATE_USABLE", "ACTIONBAR_SLOT_CHANGED",
        "PLAYER_ENTERING_WORLD",
    }
    local _aaefEvents = {
        "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
    }

    local _vehNeed, _extraNeed, _phNeed = false, false, false
    local _broadcasterMode = "off"
    local _broadcasterSlot = true
    local _classPH

    local function ClassMayPressHold()
        if _classPH == nil then
            local _, class = UnitClass("player")
            if not class then return false end
            _classPH = (class == "EVOKER")
        end
        return _classPH
    end

    local function CooldownsSecret()
        if not (C_Secrets and C_Secrets.ShouldCooldownsBeSecret) then return false end
        local ok, secret = pcall(C_Secrets.ShouldCooldownsBeSecret)
        return (ok and secret) and true or false
    end

    local function ApplyBroadcaster()
        local want = (_vehNeed or _extraNeed) and "full"
            or ((_phNeed or ClassMayPressHold()) and "ph" or "off")
        if want == "full" and CooldownsSecret() then
            want = (_phNeed or ClassMayPressHold()) and "ph" or "off"
        end
        local slotOK = not InCombatLockdown()
        if want == _broadcasterMode and slotOK == _broadcasterSlot then return end
        _broadcasterMode, _broadcasterSlot = want, slotOK

        if ActionBarButtonEventsFrame then ActionBarButtonEventsFrame:UnregisterAllEvents() end
        if ActionBarActionEventsFrame then ActionBarActionEventsFrame:UnregisterAllEvents() end

        if want == "full" then
            if ActionBarButtonEventsFrame then
                for _, ev in ipairs(_abefEvents) do
                    if slotOK or ev ~= "ACTIONBAR_SLOT_CHANGED" then
                        ActionBarButtonEventsFrame:RegisterEvent(ev)
                    end
                end
            end
            if ActionBarActionEventsFrame then
                for _, ev in ipairs(_aaefEvents) do
                    ActionBarActionEventsFrame:RegisterUnitEvent(ev, "player")
                end
            end
        elseif want == "ph" then
            if ActionBarButtonEventsFrame then
                if slotOK then
                    ActionBarButtonEventsFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
                end
                ActionBarButtonEventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
            end
        end
    end

    ns.SetBroadcasterPressHoldNeed = function(v)
        _phNeed = v and true or false
        ApplyBroadcaster()
    end

    ns.SetBroadcasterVehicleNeed = function(v)
        _vehNeed = v and true or false
        ApplyBroadcaster()
    end

    ns.SetBroadcasterExtraNeed = function(v)
        _extraNeed = v and true or false
        ApplyBroadcaster()
    end

    ns.InvalidateBroadcasterState = function()
        _broadcasterMode = ""
        ApplyBroadcaster()
    end
end

-------------------------------------------------------------------------------
--  Bar Frame Storage
-------------------------------------------------------------------------------
local barFrames = {}   -- [barKey] = secure frame
local barButtons = {}  -- [barKey] = { btn1, btn2, ... }
local allButtons = {}  -- [actionSlot] = btn
ns.barButtons = barButtons

-------------------------------------------------------------------------------
--  Secure Bar Frame Creation
-------------------------------------------------------------------------------
local function CreateBarFrame(info)
    local key = info.key
    local frame = CreateFrame("Frame", "GravityUIBar_" .. key, UIParent, "SecureHandlerStateTemplate")
    frame:SetSize(1, 1)
    frame:SetPoint("CENTER")
    frame:SetFrameLevel(max(frame:GetFrameLevel(), 10))
    if frame.SetMouseClickEnabled then
        frame:SetMouseClickEnabled(false)
    end
    frame._barKey = key
    frame._barInfo = info

    barFrames[key] = frame
    return frame
end

-------------------------------------------------------------------------------
--  Class-specific Paging Conditions (MainBar)
-------------------------------------------------------------------------------
local PAGING_STATES = {
    modifier = {
        { id = "alt",   macro = "[mod:alt]",   label = "Alt" },
        { id = "shift", macro = "[mod:shift]", label = "Shift" },
        { id = "ctrl",  macro = "[mod:ctrl]",  label = "Ctrl" },
    },
    target = {
        { id = "help",  macro = "[help]",      label = "Friendly Target" },
        { id = "harm",  macro = "[harm]",      label = "Hostile Target" },
    },
    class = {
        DRUID = {
            { id = "prowl",   macro = "[bonusbar:1,stealth]", label = "Prowl" },
            { id = "cat",     macro = "[bonusbar:1]",         label = "Cat Form" },
            { id = "tree",    macro = "[bonusbar:2]",         label = "Tree of Life" },
            { id = "bear",    macro = "[bonusbar:3]",         label = "Bear Form" },
            { id = "moonkin", macro = "[bonusbar:4]",         label = "Moonkin Form" },
        },
        ROGUE = {
            { id = "stealth", macro = "[bonusbar:1]", label = "Stealth" },
        },
        WARRIOR = {
            { id = "battle",    macro = "[bonusbar:1]", label = "Battle Stance" },
            { id = "defensive", macro = "[bonusbar:2]", label = "Defensive Stance" },
        },
        EVOKER = {
            { id = "soar", macro = "[bonusbar:1]", label = "Soar" },
        },
    },
}
ns.PAGING_STATES = PAGING_STATES

local CLASS_PAGING_DEFAULTS = {
    DRUID  = { prowl = 7, cat = 7, tree = 8, bear = 9, moonkin = 10 },
    ROGUE  = { stealth = 7 },
}

local function BuildPagingConditions(barKey, pagingConfig, defaultPage)
    local _, class = UnitClass("player")
    local parts = {}

    if barKey == "MainBar" then
        parts[#parts + 1] = "[overridebar] " .. GetOverrideBarIndex()
        parts[#parts + 1] = "[vehicleui][possessbar] " .. GetVehicleBarIndex()
    end

    -- Custom modifier pages
    if pagingConfig then
        for _, state in ipairs(PAGING_STATES.modifier) do
            local page = pagingConfig[state.id]
            if page then
                parts[#parts + 1] = state.macro .. " " .. page
            end
        end
    end

    -- Manual page switching (pages 2-6)
    if barKey == "MainBar" then
        for i = 2, NUM_AB_PAGES do
            parts[#parts + 1] = "[bar:" .. i .. "] " .. i
        end
    end

    -- Class-specific form paging
    local classStates = PAGING_STATES.class[class]
    if classStates then
        local defs = (barKey == "MainBar") and CLASS_PAGING_DEFAULTS[class]
        for _, state in ipairs(classStates) do
            local page = pagingConfig and pagingConfig[state.id]
            if page then
                parts[#parts + 1] = state.macro .. " " .. page
            elseif defs and defs[state.id] then
                parts[#parts + 1] = state.macro .. " " .. defs[state.id]
            end
        end
    end

    -- Dragonriding
    if barKey == "MainBar" then
        parts[#parts + 1] = "[bonusbar:5] 11"
    end

    -- Target conditions
    if pagingConfig and PAGING_STATES.target then
        for _, state in ipairs(PAGING_STATES.target) do
            local page = pagingConfig[state.id]
            if page then
                parts[#parts + 1] = state.macro .. " " .. page
            end
        end
    end

    parts[#parts + 1] = tostring(defaultPage or 1)
    return table.concat(parts, "; ")
end
ns.BuildPagingConditions = BuildPagingConditions

local function GetClassPagingConditions()
    local _, class = UnitClass("player")
    local conditions = ""
    conditions = conditions .. "[overridebar] " .. GetOverrideBarIndex() .. "; "
    conditions = conditions .. "[vehicleui][possessbar] " .. GetVehicleBarIndex() .. "; "

    for i = 2, NUM_AB_PAGES do
        conditions = conditions .. "[bar:" .. i .. "] " .. i .. "; "
    end

    if class == "DRUID" then
        conditions = conditions .. "[bonusbar:1,stealth] 7; [bonusbar:1] 7; [bonusbar:3] 9; [bonusbar:4] 10; "
    elseif class == "ROGUE" then
        conditions = conditions .. "[bonusbar:1] 7; "
    end

    conditions = conditions .. "[bonusbar:5] 11; "
    conditions = conditions .. "1"
    return conditions
end

-------------------------------------------------------------------------------
--  Empower Snippet (pressAndHoldAction)
-------------------------------------------------------------------------------
local empowerSnippet = [[
    local slot = self:GetAttribute('action')
    if slot and IsPressHoldReleaseSpell then
        local actionType, id, subType = GetActionInfo(slot)
        local spellID = nil
        if actionType == 'spell' then
            spellID = id
        elseif actionType == 'macro' and subType == 'spell' then
            spellID = id
        end
        if spellID then
            if IsPressHoldReleaseSpell(spellID) then
                self:SetAttribute('pressAndHoldAction', true)
            else
                self:SetAttribute('pressAndHoldAction', false)
            end
        elseif actionType and actionType ~= 'spell' and actionType ~= 'macro' then
            self:SetAttribute('pressAndHoldAction', false)
        end
    end
]]

-- Page visibility snippet
local pageVisSnippet = [[
    local showEmpty = self:GetAttribute('gui-showempty')
    if showEmpty then
        local visible = true
        if showEmpty == 0 then
            visible = HasAction(slot)
        end
        if visible then
            if self:GetAttribute('statehidden') then
                self:SetAttribute('statehidden', nil)
            end
            if not self:IsShown() then
                self:SetAlpha(1)
                self:EnableMouse(true)
            end
            self:Show(true)
        else
            if not self:GetAttribute('statehidden') then
                self:SetAttribute('statehidden', true)
            end
            self:Hide(true)
        end
    end
]]

local function BuildPageChildSnippet(baseIndex)
    return ("local page = tonumber(message) or 1; local slot = %d + (page - 1) * 12; self:SetAttribute('action', slot)\n"):format(baseIndex)
        .. pageVisSnippet .. empowerSnippet
end

-------------------------------------------------------------------------------
--  Button Creation
-------------------------------------------------------------------------------
local function ReRegisterButtonEvents(btn, listKey)
    for _, event in ipairs(BUTTON_EVENT_LISTS[listKey]) do
        btn:RegisterEvent(event)
    end
    if listKey == "pet" then
        btn:RegisterUnitEvent("UNIT_PET", "player")
        btn:RegisterUnitEvent("UNIT_FLAGS", "pet")
    end
end

local function GetOrCreateButton(slot, parent, info, index)
    if allButtons[slot] and not info.isStance and not info.isPetBar then
        allButtons[slot]:SetParent(parent)
        return allButtons[slot]
    end

    local btn

    if info.isStance then
        btn = _G["StanceButton" .. index]
        if btn then
            btn:SetAttributeNoHandler("statehidden", nil)
            ReRegisterButtonEvents(btn, "stance")
            btn:SetParent(parent)
            btn:Show()
        end
    elseif info.isPetBar then
        btn = _G["PetActionButton" .. index]
        if btn then
            btn:SetAttributeNoHandler("statehidden", nil)
            ReRegisterButtonEvents(btn, "pet")
            btn:SetParent(parent)
            btn:Show()
        end
    else
        -- Action bars: create our own button
        local name = "GravityUIButton" .. slot
        btn = _G[name]
        if not btn then
            btn = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate, SecureActionButtonTemplate")
            -- Neuter Blizzard mixin methods that cause taint or GPU thrashing.
            -- Our own dispatchers handle all of these:
            --   UpdateButtonArt  → resets textures, GPU spam
            --   UpdatePressAndHoldAction → SetAttribute() in combat (taint)
            --   Update → calls ActionButton_UpdateCooldown with secret values (taint)
            --           and various other methods we handle ourselves
            btn.UpdateButtonArt = function() end
            btn.UpdatePressAndHoldAction = function() end
            btn.UpdateAction = function() end  -- calls UpdatePingAttributes → ClearAttribute (taint)
            btn.UpdateUsable = function() end  -- assertion spam on custom buttons
            btn.Update = function() end
        end

        -- Template OnLoad self-registers events; the central dispatcher owns them
        btn:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
        btn:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

        -- Remove from Blizzard's broadcaster frames list (nil, not tremove!)
        if ActionBarButtonEventsFrame and type(ActionBarButtonEventsFrame.frames) == "table" then
            local fr = ActionBarButtonEventsFrame.frames
            local tail = #fr
            if fr[tail] == btn then
                fr[tail] = nil
            else
                for k, f in pairs(fr) do
                    if f == btn then fr[k] = nil end
                end
            end
        end

        -- Re-evaluate cooldown visuals when main cooldown completes
        if btn.cooldown and not GFD(btn).cdDoneHooked then
            GFD(btn).cdDoneHooked = true
            btn.cooldown:HookScript("OnCooldownDone", function(cd)
                local b = cd:GetParent()
                if b and ns._RefreshCooldownVisuals then
                    ns._RefreshCooldownVisuals(b)
                end
            end)
        end

        btn:SetParent(parent)
        btn:SetID(0)
        btn:SetAttribute("action", slot)
        btn.action = slot  -- Blizzard's overlay glow reads this property

        -- Keep btn.action synced when SecureStateDriver changes the attribute
        if not GFD(btn).actionSyncHooked then
            GFD(btn).actionSyncHooked = true
            btn:HookScript("OnAttributeChanged", function(self, name, value)
                if name == "action" then
                    self.action = value
                end
            end)
        end

        -- Register our per-button events
        ReRegisterButtonEvents(btn, "action")
    end

    if btn then
        -- Don't store pet/stance in allButtons — they collide with MainBar slots 1-12
        if not info.isPetBar and not info.isStance then
            allButtons[slot] = btn
        end
    end
    return btn
end

-------------------------------------------------------------------------------
--  Force-paint cooldown swipe (secret-safe, for vehicle/override/extra buttons)
-------------------------------------------------------------------------------
local function ForceCooldownPaint(btn)
    if not btn then return end
    local cd = btn.cooldown
    local action = btn:GetAttribute("action")
    if cd and action and HasAction(action) and C_ActionBar and C_ActionBar.GetActionCooldown then
        local cdInfo = C_ActionBar.GetActionCooldown(action)
        local durObj = cdInfo and cdInfo.isActive and C_ActionBar.GetActionCooldownDuration
            and C_ActionBar.GetActionCooldownDuration(action)
        if durObj then
            cd:SetCooldownFromDurationObject(durObj)
        else
            pcall(cd.Clear, cd)  -- 12.1.5: Clear() restricted on protected frames
        end
    end
end
ns.ForceCooldownPaint = ForceCooldownPaint

-------------------------------------------------------------------------------
--  Central Overlay Glow Dispatcher
--  Handles proc glow (SpellActivationAlert) for our custom buttons since
--  they've been removed from ActionBarButtonEventsFrame.
--  Resolves macros to their underlying spellID for accurate glow matching.
-------------------------------------------------------------------------------
do

    -- Resolve button → spellID (handles spells AND macros)
    local function GetButtonSpellID(btn)
        local action = btn.action or btn:GetAttribute("action")
        if not action or not HasAction(action) then return nil end
        local actionType, id, subType = GetActionInfo(action)
        if actionType == "spell" then
            return id
        elseif actionType == "macro" then
            if subType == "spell" then return id end
            local macroName = GetActionText(action)
            local macroIndex = macroName and GetMacroIndexByName(macroName)
            if macroIndex and macroIndex > 0 then
                if GetMacroItem and GetMacroItem(macroIndex) then return nil end
                return GetMacroSpell and GetMacroSpell(macroIndex)
            end
        end
        return nil
    end

    local activeGlows = {}  -- btn → true

    ---------------------------------------------------------------------------
    -- Glow Style mapping
    -- Our settings key → EllesmereUI.Glows style index (1-based)
    ---------------------------------------------------------------------------
    local GLOW_STYLE_MAP = {
        pixel    = 1,  -- Pixel Glow (procedural ants)
        abg      = 2,  -- Action Button Glow
        shine    = 3,  -- Auto-Cast Shine
        gcd      = 5,  -- GCD FlipBook
        modern   = 6,  -- Modern WoW Glow
        classic  = 7,  -- Classic WoW Glow
        border   = 0,  -- Our built-in pulsing border (no EUI equivalent)
    }

    ---------------------------------------------------------------------------
    --  Built-in Fallback: Pulsing Border Glow (no dependency)
    ---------------------------------------------------------------------------
    local function CreateBorderGlow(btn, color, width)
        local glow = CreateFrame("Frame", nil, btn)
        glow:SetAllPoints(btn)
        glow:SetFrameLevel(btn:GetFrameLevel() + 5)
        local r, g, b, a = color[1] or 1, color[2] or 0.8, color[3] or 0, color[4] or 1
        local w = width or 2
        local t = glow:CreateTexture(nil, "OVERLAY"); t:SetColorTexture(r, g, b, a)
        t:SetPoint("TOPLEFT"); t:SetPoint("TOPRIGHT"); t:SetHeight(w); glow._top = t
        local bo = glow:CreateTexture(nil, "OVERLAY"); bo:SetColorTexture(r, g, b, a)
        bo:SetPoint("BOTTOMLEFT"); bo:SetPoint("BOTTOMRIGHT"); bo:SetHeight(w); glow._bottom = bo
        local l = glow:CreateTexture(nil, "OVERLAY"); l:SetColorTexture(r, g, b, a)
        l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT"); l:SetWidth(w); glow._left = l
        local ri = glow:CreateTexture(nil, "OVERLAY"); ri:SetColorTexture(r, g, b, a)
        ri:SetPoint("TOPRIGHT"); ri:SetPoint("BOTTOMRIGHT"); ri:SetWidth(w); glow._right = ri
        local ag = glow:CreateAnimationGroup(); ag:SetLooping("REPEAT")
        local a1 = ag:CreateAnimation("Alpha")
        a1:SetFromAlpha(1); a1:SetToAlpha(0.3); a1:SetDuration(0.4); a1:SetOrder(1)
        local a2 = ag:CreateAnimation("Alpha")
        a2:SetFromAlpha(0.3); a2:SetToAlpha(1); a2:SetDuration(0.4); a2:SetOrder(2)
        glow._pulse = ag; glow:Hide()
        return glow
    end

    local function UpdateBorderGlowStyle(glow, color, width)
        if not glow then return end
        local r, g, b, a = color[1] or 1, color[2] or 0.8, color[3] or 0, color[4] or 1
        local w = width or 2
        if glow._top then glow._top:SetColorTexture(r, g, b, a); glow._top:SetHeight(w) end
        if glow._bottom then glow._bottom:SetColorTexture(r, g, b, a); glow._bottom:SetHeight(w) end
        if glow._left then glow._left:SetColorTexture(r, g, b, a); glow._left:SetWidth(w) end
        if glow._right then glow._right:SetColorTexture(r, g, b, a); glow._right:SetWidth(w) end
    end

    ---------------------------------------------------------------------------
    --  Built-in Fallback: Pixel Glow (orbiting squares)
    ---------------------------------------------------------------------------
    local PIXEL_COUNT = 8
    local PIXEL_SIZE = 3
    local PIXEL_SPEED = 1.8
    local function CreatePixelGlow(btn, color)
        local glow = CreateFrame("Frame", nil, btn)
        glow:SetAllPoints(btn); glow:SetFrameLevel(btn:GetFrameLevel() + 5)
        local r, g, b, a = color[1] or 1, color[2] or 0.8, color[3] or 0, color[4] or 1
        local pixels = {}
        for i = 1, PIXEL_COUNT do
            local px = glow:CreateTexture(nil, "OVERLAY")
            px:SetColorTexture(r, g, b, a); px:SetSize(PIXEL_SIZE, PIXEL_SIZE)
            pixels[i] = px
        end
        glow._pixels = pixels; glow._phase = 0
        glow:SetScript("OnUpdate", function(self, elapsed)
            self._phase = (self._phase + elapsed * PIXEL_SPEED) % 1
            local fw, fh = self:GetWidth(), self:GetHeight()
            if fw < 1 or fh < 1 then return end
            local perimeter = 2 * (fw + fh)
            for i, px in ipairs(self._pixels) do
                local t = (self._phase + (i - 1) / PIXEL_COUNT) % 1
                local d = t * perimeter
                local x, y
                if d < fw then x, y = d, 0
                elseif d < fw + fh then x, y = fw, -(d - fw)
                elseif d < 2 * fw + fh then x, y = fw - (d - fw - fh), -fh
                else x, y = 0, -(fh - (d - 2 * fw - fh)) end
                px:ClearAllPoints()
                px:SetPoint("TOPLEFT", self, "TOPLEFT", x - PIXEL_SIZE/2, y + PIXEL_SIZE/2)
            end
        end)
        glow:Hide(); return glow
    end

    ---------------------------------------------------------------------------
    --  Built-in FlipBook Glow (Modern WoW, Classic WoW, Action Button Glow)
    --  Uses Blizzard's own textures + WoW's native FlipBook animation API
    ---------------------------------------------------------------------------
    local FLIPBOOK_STYLES = {
        modern  = { atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook", rows = 6, columns = 5, frames = 30, duration = 1.0, padding = 1.4 },
        classic = { texture = [[Interface\SpellActivationOverlay\IconAlertAnts]], rows = 5, columns = 5, frames = 22, duration = 0.3, padding = 1.25, frameW = 48, frameH = 48 },
        abg     = { atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook", rows = 6, columns = 5, frames = 30, duration = 1.0, padding = 1.4 },
        gcd     = { atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook", rows = 6, columns = 5, frames = 30, duration = 0.6, padding = 1.4 },
    }

    local function CreateFlipBookGlow(btn, styleDef, color)
        local wrapper = CreateFrame("Frame", nil, btn)
        wrapper:SetAllPoints(btn)
        wrapper:SetFrameLevel(btn:GetFrameLevel() + 5)

        local sz = btn:GetWidth() or 36
        local texSz = sz * (styleDef.padding or 1)

        local tex = wrapper:CreateTexture(nil, "OVERLAY", nil, 7)
        tex:SetPoint("CENTER")
        tex:SetSize(texSz, texSz)
        tex:SetBlendMode("ADD")
        if styleDef.atlas then
            tex:SetAtlas(styleDef.atlas)
        elseif styleDef.texture then
            tex:SetTexture(styleDef.texture)
        end
        if color then
            tex:SetDesaturated(true)
            tex:SetVertexColor(color[1] or 1, color[2] or 0.8, color[3] or 0)
        end

        local ag = tex:CreateAnimationGroup()
        ag:SetLooping("REPEAT")
        local anim = ag:CreateAnimation("FlipBook")
        anim:SetFlipBookRows(styleDef.rows or 6)
        anim:SetFlipBookColumns(styleDef.columns or 5)
        anim:SetFlipBookFrames(styleDef.frames or 30)
        anim:SetDuration(styleDef.duration or 1.0)
        if styleDef.frameW then anim:SetFlipBookFrameWidth(styleDef.frameW) end
        if styleDef.frameH then anim:SetFlipBookFrameHeight(styleDef.frameH) end

        wrapper._flipTex = tex
        wrapper._flipAG = ag
        wrapper:Hide()
        return wrapper
    end

    ---------------------------------------------------------------------------
    --  Built-in Auto-Cast Shine (orbiting sparkle dots)
    ---------------------------------------------------------------------------
    local SHINE_TEX    = [[Interface\Artifacts\Artifacts]]
    local SHINE_L, SHINE_R = 0.8115234375, 0.9169921875
    local SHINE_T, SHINE_B = 0.8798828125, 0.9853515625

    local function CreateShineGlow(btn, color)
        local wrapper = CreateFrame("Frame", nil, btn)
        wrapper:SetAllPoints(btn)
        wrapper:SetFrameLevel(btn:GetFrameLevel() + 5)
        local dots = {}
        local sizes = { 7, 6, 5, 4 }
        for layer = 1, 4 do
            for i = 1, 4 do
                local dot = wrapper:CreateTexture(nil, "OVERLAY", nil, 7)
                dot:SetTexture(SHINE_TEX)
                dot:SetTexCoord(SHINE_L, SHINE_R, SHINE_T, SHINE_B)
                dot:SetDesaturated(true)
                dot:SetBlendMode("ADD")
                dot:SetSize(sizes[layer], sizes[layer])
                dot:SetVertexColor(color[1] or 1, color[2] or 0.8, color[3] or 0, 1)
                dots[#dots + 1] = { tex = dot, layer = layer, idx = i }
            end
        end
        wrapper._shineDots = dots
        wrapper._shinePhase = { 0, 0.25, 0.5, 0.75 }
        wrapper:SetScript("OnUpdate", function(self, elapsed)
            local w, h = self:GetWidth(), self:GetHeight()
            if w < 1 or h < 1 then return end
            local hw, hh = w * 0.5, h * 0.5
            for _, d in ipairs(self._shineDots) do
                local phase = self._shinePhase[d.layer]
                local t = (phase + (d.idx - 1) * 0.25) % 1
                local angle = t * 6.2832
                local radius = math.min(hw, hh) * 0.9
                d.tex:ClearAllPoints()
                d.tex:SetPoint("CENTER", self, "CENTER",
                    math.cos(angle) * radius, math.sin(angle) * radius)
            end
            for i = 1, 4 do
                self._shinePhase[i] = (self._shinePhase[i] + elapsed * 0.5) % 1
            end
        end)
        wrapper:Hide()
        return wrapper
    end

    ---------------------------------------------------------------------------
    --  EllesmereUI.Glows wrapper frame per button
    ---------------------------------------------------------------------------
    local function GetGlowWrapper(btn)
        if btn._gravGlowWrapper then return btn._gravGlowWrapper end
        local wrapper = CreateFrame("Frame", nil, btn)
        wrapper:SetAllPoints(btn)
        wrapper:SetFrameLevel(btn:GetFrameLevel() + 5)
        btn._gravGlowWrapper = wrapper
        wrapper:Show()
        return wrapper
    end

    ---------------------------------------------------------------------------
    --  Helper: Hide all glow frames on a button
    ---------------------------------------------------------------------------
    local function HideAllGlowFrames(btn)
        if btn._gravGlow then
            if btn._gravGlow._pulse then btn._gravGlow._pulse:Stop() end
            btn._gravGlow:Hide()
        end
        if btn._gravPixel then btn._gravPixel:Hide() end
        if btn._gravFlipBook then
            if btn._gravFlipBook._flipAG then btn._gravFlipBook._flipAG:Stop() end
            btn._gravFlipBook:Hide()
        end
        if btn._gravShine then btn._gravShine:Hide() end
        local EG = EllesmereUI and EllesmereUI.Glows
        if btn._gravGlowWrapper and EG then
            EG.StopGlow(btn._gravGlowWrapper)
        end
    end

    ---------------------------------------------------------------------------
    --  ShowGlow / HideGlow
    ---------------------------------------------------------------------------
    local function ShowGlow(btn)
        if activeGlows[btn] then return end
        activeGlows[btn] = true

        local db = GetDB()
        local g = db and db.global
        local style = g and g.procGlowStyle or "border"
        if style == "none" then return end  -- user disabled proc glow
        local color = g and g.procGlowColor or { 1, 0.8, 0, 1 }
        local cr, cg, cb = color[1] or 1, color[2] or 0.8, color[3] or 0

        -- Hide all first
        HideAllGlowFrames(btn)

        -- 1) Try EllesmereUI.Glows API (best quality, if loaded)
        local euiIdx = GLOW_STYLE_MAP[style]
        local EG = EllesmereUI and EllesmereUI.Glows
        if EG and euiIdx and euiIdx > 0 then
            local wrapper = GetGlowWrapper(btn)
            local sz = btn:GetWidth() or 36
            EG.StartGlow(wrapper, euiIdx, sz, cr, cg, cb)
            return
        end

        -- 2) Built-in FlipBook (modern, classic, abg, gcd)
        local fbDef = FLIPBOOK_STYLES[style]
        if fbDef then
            if not btn._gravFlipBook then
                btn._gravFlipBook = CreateFlipBookGlow(btn, fbDef, color)
            end
            btn._gravFlipBook:Show()
            if btn._gravFlipBook._flipAG then
                btn._gravFlipBook._flipAG:Stop()
                btn._gravFlipBook._flipAG:Play()
            end
            return
        end

        -- 3) Built-in Auto-Cast Shine
        if style == "shine" then
            if not btn._gravShine then
                btn._gravShine = CreateShineGlow(btn, color)
            end
            btn._gravShine:Show()
            return
        end

        -- 4) Built-in Pixel Glow
        if style == "pixel" then
            if not btn._gravPixel then
                btn._gravPixel = CreatePixelGlow(btn, color)
            end
            btn._gravPixel._phase = 0; btn._gravPixel:Show()
            return
        end

        -- 5) Border glow (default, always available)
        local width = g and g.procGlowBorderWidth or 2
        if not btn._gravGlow then
            btn._gravGlow = CreateBorderGlow(btn, color, width)
        else
            UpdateBorderGlowStyle(btn._gravGlow, color, width)
        end
        btn._gravGlow:Show()
        if btn._gravGlow._pulse then btn._gravGlow._pulse:Play() end
    end

    local function HideGlow(btn)
        if not activeGlows[btn] then return end
        activeGlows[btn] = nil
        HideAllGlowFrames(btn)
    end

    -- Full rescan: check all buttons against IsSpellOverlayed
    local rescanPending = false
    local lastScan = 0
    local function GlowRescan()
        rescanPending = false
        lastScan = GetTime()
        local ISO = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed
        if not ISO then return end
        -- Remove stale glows
        for btn in pairs(activeGlows) do
            local id = GetButtonSpellID(btn)
            if not id or not ISO(id) then
                HideGlow(btn)
            end
        end
        -- Add new glows
        for _, info in ipairs(BAR_CONFIG) do
            local btns = barButtons[info.key]
            if btns then
                for _, btn in ipairs(btns) do
                    if btn and not activeGlows[btn] then
                        local id = GetButtonSpellID(btn)
                        if id and ISO(id) then
                            ShowGlow(btn)
                        end
                    end
                end
            end
        end
    end

    local function QueueRescan()
        if rescanPending then return end
        rescanPending = true
        local elapsed = GetTime() - lastScan
        C_Timer_After(elapsed >= 0.25 and 0 or (0.25 - elapsed), GlowRescan)
    end

    local glowDispatcher = CreateFrame("Frame")
    glowDispatcher:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    glowDispatcher:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    glowDispatcher:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    glowDispatcher:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    glowDispatcher:RegisterEvent("UPDATE_BONUS_ACTIONBAR")

    glowDispatcher:SetScript("OnEvent", function(_, event, arg1)
        if event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED"
            or event == "UPDATE_BONUS_ACTIONBAR" then
            QueueRescan()
            return
        end

        local isShow = (event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")

        if isShow then
            -- SHOW: scan all buttons for matching spellID
            for _, info in ipairs(BAR_CONFIG) do
                local btns = barButtons[info.key]
                if btns then
                    for _, btn in ipairs(btns) do
                        if btn then
                            local id = GetButtonSpellID(btn)
                            if id and id == arg1 then
                                ShowGlow(btn)
                            end
                        end
                    end
                end
            end
        else
            -- HIDE: only check buttons with active glows
            local toHide
            for btn in pairs(activeGlows) do
                local id = GetButtonSpellID(btn)
                local ISO = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed
                if (id and id == arg1) or not id or (ISO and not ISO(id)) then
                    if not toHide then toHide = {} end
                    toHide[#toHide + 1] = btn
                end
            end
            if toHide then
                for i = 1, #toHide do HideGlow(toHide[i]) end
            end
        end
    end)
end

-------------------------------------------------------------------------------
--  Out-of-Range Icon Coloring (event-based)
--  Uses C_ActionBar.EnableActionRangeCheck + ACTION_RANGE_CHECK_UPDATE.
--  Only tints spells that have a range requirement (checksRange flag).
--  Self-buffs (AMS, IBF, etc.) are correctly excluded.
-------------------------------------------------------------------------------
do
    local _rangeSlots = {}       -- [actionSlot] = true (tracked slots)
    local _rangeOutOf = {}       -- [actionSlot] = true (currently out of range)
    local _rangeEventFrame

    -- Apply or remove the range tint on a button's icon
    local function ApplyRangeTint(btn, isOut)
        local ico = btn.icon or btn.Icon
        if not ico then return end
        local fd = GFD(btn)
        local db = GetDB()
        local g = db and db.global
        if isOut and g and g.outOfRangeColoring then
            local c = g.outOfRangeColor or { 0.8, 0.1, 0.1 }
            ico:SetVertexColor(c[1] or 0.8, c[2] or 0.1, c[3] or 0.1)
            fd.rangeTinted = true
        elseif fd.rangeTinted then
            fd.rangeTinted = nil
            ico:SetVertexColor(1, 1, 1, 1)
        end
    end

    -- Enable range checking for all active button slots
    local function EnableRangeChecking()
        local db = GetDB()
        local g = db and db.global
        if not g or not g.outOfRangeColoring then return end
        if not C_ActionBar or not C_ActionBar.EnableActionRangeCheck then return end

        for _, info in ipairs(BAR_CONFIG) do
            local btns = barButtons[info.key]
            if btns then
                for _, btn in ipairs(btns) do
                    if btn then
                        local action = btn.action or btn:GetAttribute("action")
                        if action and HasAction(action) and not _rangeSlots[action] then
                            _rangeSlots[action] = true
                            pcall(C_ActionBar.EnableActionRangeCheck, action, true)
                        end
                    end
                end
            end
        end
    end

    -- Disable all range checking and clear tints
    local function DisableRangeChecking()
        if C_ActionBar and C_ActionBar.EnableActionRangeCheck then
            for slot in pairs(_rangeSlots) do
                pcall(C_ActionBar.EnableActionRangeCheck, slot, false)
            end
        end
        wipe(_rangeSlots)
        wipe(_rangeOutOf)
        -- Clear tints on all buttons
        for _, info in ipairs(BAR_CONFIG) do
            local btns = barButtons[info.key]
            if btns then
                for _, btn in ipairs(btns) do
                    if btn then ApplyRangeTint(btn, false) end
                end
            end
        end
    end

    -- Sweep all buttons: poll live range state and repaint
    local function RangeSweep()
        local db = GetDB()
        local g = db and db.global
        if not g or not g.outOfRangeColoring then return end
        for _, info in ipairs(BAR_CONFIG) do
            local btns = barButtons[info.key]
            if btns then
                for _, btn in ipairs(btns) do
                    if btn then
                        local action = btn.action or btn:GetAttribute("action")
                        if action and HasAction(action) then
                            local isOut = (SafeIsActionInRange(action) == false)
                            _rangeOutOf[action] = isOut or nil
                            ApplyRangeTint(btn, isOut)
                        else
                            ApplyRangeTint(btn, false)
                        end
                    end
                end
            end
        end
    end

    -- Override Blizzard's keybind range coloring
    -- Hook HotKey:SetVertexColor directly so Blizzard can never make it red
    local function HookHotKeyColor(btn)
        local hk = btn.HotKey
        if not hk or hk._gravColorHooked then return end
        hk._gravColorHooked = true

        local origSetVertexColor = hk.SetVertexColor
        hk.SetVertexColor = function(self, r, g, b, a)
            -- Detect Blizzard's red range coloring (r > 0.7, g < 0.3)
            -- and suppress it, keeping our configured color
            if r and g and r > 0.7 and g < 0.3 then
                local db = GetDB()
                local gs = db and db.global
                if gs then
                    local c = gs.keybindColor
                    if c then
                        return origSetVertexColor(self, c[1], c[2], c[3], c[4] or 1)
                    else
                        return origSetVertexColor(self, 0.75, 0.75, 0.75, 1)
                    end
                end
            end
            return origSetVertexColor(self, r, g, b, a)
        end
    end

    -- Apply hooks to all buttons
    local _keybindOverrideStarted = false
    function ActionBars.StartKeybindRangeOverride()
        if _keybindOverrideStarted then return end
        _keybindOverrideStarted = true
        for _, info in ipairs(BAR_CONFIG) do
            local btns = barButtons[info.key]
            if btns then
                for _, btn in ipairs(btns) do
                    if btn then HookHotKeyColor(btn) end
                end
            end
        end
    end

    -- Set up the range event listener
    local function SetupRangeEvents()
        if _rangeEventFrame then return end
        _rangeEventFrame = CreateFrame("Frame")
        _rangeEventFrame:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
        _rangeEventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        _rangeEventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
        _rangeEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

        _rangeEventFrame:SetScript("OnEvent", function(_, event, slot, inRange, checksRange)
            if event == "ACTION_RANGE_CHECK_UPDATE" then
                if not _rangeSlots[slot] then return end
                local isOut = checksRange and not inRange
                local wasOut = _rangeOutOf[slot]
                if isOut == (wasOut or false) then return end
                _rangeOutOf[slot] = isOut or nil

                for _, info in ipairs(BAR_CONFIG) do
                    local btns = barButtons[info.key]
                    if btns then
                        for _, btn in ipairs(btns) do
                            if btn then
                                local a = btn.action or btn:GetAttribute("action")
                                if a == slot then
                                    ApplyRangeTint(btn, isOut)
                                end
                            end
                        end
                    end
                end
            elseif event == "ACTIONBAR_SLOT_CHANGED" then
                if slot and slot > 0 then
                    _rangeOutOf[slot] = nil
                    if C_ActionBar and C_ActionBar.EnableActionRangeCheck then
                        if HasAction(slot) then
                            _rangeSlots[slot] = true
                            pcall(C_ActionBar.EnableActionRangeCheck, slot, true)
                        else
                            _rangeSlots[slot] = nil
                            pcall(C_ActionBar.EnableActionRangeCheck, slot, false)
                        end
                    end
                    local btn = allButtons[slot]
                    if btn then ApplyRangeTint(btn, false) end
                else
                    EnableRangeChecking()
                    RangeSweep()
                end
            elseif event == "ACTIONBAR_PAGE_CHANGED"
                or event == "UPDATE_SHAPESHIFT_FORM" then
                C_Timer_After(0.1, function()
                    EnableRangeChecking()
                    RangeSweep()
                end)
            end
        end)
    end

    -- Public API for settings toggle
    function ActionBars.EnableRangeColoring()
        SetupRangeEvents()
        EnableRangeChecking()
        C_Timer_After(0.1, RangeSweep)
    end

    function ActionBars.DisableRangeColoring()
        DisableRangeChecking()
    end

    -- Expose for refresh calls
    ns._RangeSweep = RangeSweep
    ns._EnableRangeChecking = EnableRangeChecking
end

-------------------------------------------------------------------------------
--  Central Cooldown Dispatcher (Secret-Safe)
--  Uses SetCooldownFromDurationObject instead of numeric SetCooldown.
--  Duration objects pass through secret-value restrictions (AllowedWhenTainted).
-------------------------------------------------------------------------------
do
    local dispatcher = CreateFrame("Frame")

    -- Cooldown visuals: desaturate, alpha dim on CD
    local function RefreshCooldownVisuals(btn)
        local db = GetDB()
        if not db then return end
        local g = db.global
        if not g or not g.usabilityIndicator then return end
        local action = btn:GetAttribute("action")
        if not action or not HasAction(action) then return end
        local icon = btn.icon or btn.Icon
        if not icon then return end

        local cdInfo = C_ActionBar.GetActionCooldown(action)
        local isOnCD = cdInfo and cdInfo.isActive and not cdInfo.isOnGCD

        if isOnCD then
            if g.usabilityDesaturate then
                icon:SetDesaturated(true)
            end
        else
            icon:SetDesaturated(false)
        end
    end
    ns._RefreshCooldownVisuals = RefreshCooldownVisuals

    -- Per-button cooldown push
    local function PushButtonCooldown(btn)
        local action = btn:GetAttribute("action")
        if not action or not HasAction(action) then return end
        local fd = GFD(btn)
        local cd = btn.cooldown

        local cdInfo = C_ActionBar.GetActionCooldown(action)
        local active = (cdInfo and cdInfo.isActive) and true or false

        if cd then
            if active then
                local durObj = C_ActionBar.GetActionCooldownDuration(action)
                if durObj then cd:SetCooldownFromDurationObject(durObj) end
            elseif fd.cdWasActive then
                pcall(cd.Clear, cd)  -- 12.1.5: Clear() restricted on protected frames
            end
        end

        -- Charge cooldown
        if btn.chargeCooldown then
            local chargeInfo = C_ActionBar.GetActionCharges(action)
            if chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1 then
                if chargeInfo.isActive then
                    local chargeDur = C_ActionBar.GetActionChargeDuration(action)
                    if chargeDur then btn.chargeCooldown:SetCooldownFromDurationObject(chargeDur) end
                else
                    pcall(btn.chargeCooldown.Clear, btn.chargeCooldown)  -- 12.1.5 safe
                end
            end
        end

        -- Visuals
        if active or fd.cdWasActive then
            RefreshCooldownVisuals(btn)
        end

        fd.cdWasActive = active
    end

    -- Per-button content refresh for slot change
    local function RefreshButtonContent(btn, action)
        if not btn or not action then return end
        local hasAct = HasAction(action)
        -- Icon
        local icon = btn.icon or btn.Icon
        if icon then
            local tex = hasAct and GetActionTexture(action)
            if tex then
                icon:SetTexture(tex)
                icon:Show()
                -- Immediately apply usability dimming
                local db = GetDB()
                local gs = db and db.global
                local fd = GFD(btn)
                local isUsable = SafeIsUsableAction(action)
                if gs and gs.usabilityIndicator and not isUsable then
                    if gs.usabilityDesaturate then
                        icon:SetDesaturated(true)
                        icon:SetVertexColor(0.6, 0.6, 0.6, 1)
                    else
                        icon:SetDesaturated(false)
                        icon:SetVertexColor(0.65, 0.65, 0.65, 1)
                    end
                    fd.usableState = "unusable"
                else
                    icon:SetVertexColor(1, 1, 1, 1)
                    icon:SetDesaturated(false)
                    fd.usableState = nil
                end
            else
                icon:Hide()
                icon:SetDesaturated(false)
                icon:SetVertexColor(1, 1, 1, 1)
                local fd = GFD(btn)
                fd.usableState = nil
                fd.rangeTinted = nil
            end
        end
        -- Cooldown: clear if slot is empty
        if hasAct then
            PushButtonCooldown(btn)
        else
            local cd = btn.cooldown
            if cd then pcall(cd.Clear, cd) end
            if btn.chargeCooldown then pcall(btn.chargeCooldown.Clear, btn.chargeCooldown) end
        end
        -- Count: clear if slot is empty
        if btn.Count then
            if hasAct and C_ActionBar.GetActionDisplayCount then
                local display = C_ActionBar.GetActionDisplayCount(action)
                if issecretvalue and issecretvalue(display) then
                    btn.Count:SetText(display)
                else
                    btn.Count:SetText(display or "")
                end
            else
                btn.Count:SetText("")
            end
        end
        -- Macro name
        if btn.Name then
            local db = GetDB()
            local g = db and db.global
            if g and g.showMacroNames then
                local macroText = hasAct and GetActionText(action) or ""
                btn.Name:SetText(macroText)
            else
                btn.Name:SetText("")
            end
        end
    end

    -- Walk all buttons
    local function DispatchCooldownUpdate()
        for _, info in ipairs(BAR_CONFIG) do
            local btns = barButtons[info.key]
            if btns then
                for _, btn in ipairs(btns) do
                    if btn and btn:IsVisible() then
                        PushButtonCooldown(btn)
                    end
                end
            end
        end
    end

    local function DispatchSlotChanged(changedSlot)
        if changedSlot == 0 then
            -- Full refresh (all slots)
            for _, info in ipairs(BAR_CONFIG) do
                local btns = barButtons[info.key]
                if btns then
                    for _, btn in ipairs(btns) do
                        if btn then
                            local action = btn.action or btn:GetAttribute("action")
                            if action then RefreshButtonContent(btn, action) end
                        end
                    end
                end
            end
        else
            -- Single slot
            local btn = allButtons[changedSlot]
            if btn then RefreshButtonContent(btn, changedSlot) end
        end
    end

    local function DispatchUsableUpdate()
        local db = GetDB()
        if not db then return end
        local g = db.global
        if not g or not g.usabilityIndicator then return end

        for _, info in ipairs(BAR_CONFIG) do
            local btns = barButtons[info.key]
            if btns then
                for _, btn in ipairs(btns) do
                    if btn and btn:IsVisible() then
                        local action = btn:GetAttribute("action")
                        if action and HasAction(action) then
                            local icon = btn.icon or btn.Icon
                            if icon then
                                local isUsable = SafeIsUsableAction(action)
                                local fd = GFD(btn)
                                if not isUsable then
                                    if fd.usableState ~= "unusable" then
                                        if g.usabilityDesaturate then
                                            icon:SetDesaturated(true)
                                            icon:SetVertexColor(0.6, 0.6, 0.6, 1)
                                        else
                                            icon:SetDesaturated(false)
                                            icon:SetVertexColor(0.65, 0.65, 0.65, 1)
                                        end
                                        fd.usableState = "unusable"
                                    end
                                else
                                    if fd.usableState then
                                        icon:SetVertexColor(1, 1, 1, 1)
                                        icon:SetDesaturated(false)
                                        fd.usableState = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    dispatcher:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    dispatcher:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    dispatcher:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    dispatcher:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    dispatcher:RegisterEvent("SPELL_UPDATE_CHARGES")
    dispatcher:RegisterEvent("SPELL_UPDATE_ICON")
    dispatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    dispatcher:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    dispatcher:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    dispatcher:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    dispatcher:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
    dispatcher:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
    dispatcher:RegisterEvent("PLAYER_TALENT_UPDATE")
    if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("TRAIT_CONFIG_UPDATED") then
        dispatcher:RegisterEvent("TRAIT_CONFIG_UPDATED")
    end
    dispatcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

    dispatcher:SetScript("OnEvent", function(self, event, arg1)
        if event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then
            DispatchCooldownUpdate()
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            DispatchSlotChanged(arg1 or 0)
        elseif event == "ACTIONBAR_UPDATE_USABLE" then
            DispatchUsableUpdate()
        elseif event == "SPELL_UPDATE_CHARGES" then
            DispatchCooldownUpdate()
        elseif event == "SPELL_UPDATE_ICON" then
            DispatchSlotChanged(0)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Longer delay: SecureStateDriver needs time to evaluate
            -- bonusbar/vehicle conditions after login/reload
            C_Timer_After(0.5, function()
                DispatchSlotChanged(0)
                DispatchCooldownUpdate()
            end)
            -- Second pass: some mount states resolve very late
            C_Timer_After(1.5, function()
                DispatchSlotChanged(0)
                DispatchCooldownUpdate()
            end)
        elseif event == "UPDATE_SHAPESHIFT_FORM"
            or event == "ACTIONBAR_PAGE_CHANGED"
            or event == "UPDATE_BONUS_ACTIONBAR"
            or event == "UPDATE_VEHICLE_ACTIONBAR"
            or event == "UPDATE_OVERRIDE_ACTIONBAR" then
            -- Delay slightly to let SecureStateDriver _childupdate finish
            -- updating button action attributes before we read them
            C_Timer_After(0.1, function()
                DispatchSlotChanged(0)
                DispatchCooldownUpdate()
            end)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            DispatchCooldownUpdate()
        elseif event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" then
            -- Talent change: full refresh with delay to let slots settle
            C_Timer_After(0.3, function()
                DispatchSlotChanged(0)
                DispatchUsableUpdate()
                DispatchCooldownUpdate()
            end)
        end
    end)
end

-------------------------------------------------------------------------------
--  Button Skinning
-------------------------------------------------------------------------------
-- Force a Blizzard overlay texture to fill its parent button exactly.
-- Blizzard's stock textures use fixed pixel anchors (e.g. 64x64) that don't
-- scale when we resize buttons.  SetAllPoints pins them to the button bounds.
local function FitTextureToButton(tex)
    if not tex then return end
    tex:ClearAllPoints()
    tex:SetAllPoints(tex:GetParent())
    tex:SetTexCoord(0, 1, 0, 1)
end

local function SkinButton(button, settings)
    if not button or not settings then return end
    local bData = GFD(button)

    if not bData.stripped then
        local nt = button:GetNormalTexture()
        if nt then nt:SetAlpha(0) end

        local icon = button.icon or button.Icon
        if icon then
            local zoom = settings.iconZoom or 0.07
            icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
            icon:SetAllPoints(button)
        end

        -- Neutralize the round icon mask (Blizzard applies round mask via UpdateButtonArt)
        if button.IconMask then
            if button.icon then button.icon:RemoveMaskTexture(button.IconMask) end
            button.IconMask:Hide()
            button.IconMask:ClearAllPoints()
            button.IconMask:SetSize(0.001, 0.001)
        end

        -- Hook NormalTexture so it stays hidden when Blizzard re-shows it
        if nt and not bData.ntHooked then
            nt:HookScript("OnShow", function(self)
                self:SetAlpha(0)
            end)
            bData.ntHooked = true
        end

        bData.stripped = true
    end

    -- ── Fit all Blizzard overlay textures to button bounds ────────────
    -- These are hardcoded to 64x64 (or atlas-based) and must be pinned
    -- to the button so they scale with custom button sizes.

    -- Ensure PushedTexture uses our custom texture (UpdateButtonArt is neutered)
    local pt = button:GetPushedTexture()
    if pt then
        pt:SetTexture(TEXTURES.pushed)
        pt:SetBlendMode("ADD")
        pt:SetVertexColor(0.97, 0.84, 0.60, 0.5)  -- warm gold, subtle
        FitTextureToButton(pt)
    end

    -- Highlight on mouseover
    local ht = button:GetHighlightTexture()
    if ht then
        ht:SetTexture(TEXTURES.highlight)
        ht:SetBlendMode("ADD")
        ht:SetVertexColor(1, 1, 1, 0.35)  -- soft white glow
        FitTextureToButton(ht)
    end

    -- Checked state (auto-attack, toggle abilities)
    local ct = button:GetCheckedTexture()
    if ct then
        ct:SetTexture(TEXTURES.checked)
        ct:SetBlendMode("ADD")
        ct:SetVertexColor(0.97, 0.84, 0.60, 0.6)  -- warm gold
        FitTextureToButton(ct)
    end

    FitTextureToButton(button.Border)
    FitTextureToButton(button.NewActionTexture)
    FitTextureToButton(button.Flash)
    if button.FlyoutBorderShadow then
        button.FlyoutBorderShadow:Hide()
    end
    if button.BorderShadow then
        button.BorderShadow:Hide()
    end

    if settings.showBackdrop then
        if not bData.backdrop then
            bData.backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -8)
            bData.backdrop:SetColorTexture(0, 0, 0, 1)
            bData.backdrop:SetAllPoints(button)
        end
        bData.backdrop:SetAlpha(settings.backdropAlpha or 0.8)
        bData.backdrop:Show()
    elseif bData.backdrop then
        bData.backdrop:Hide()
    end

    if settings.showBorders then
        if not bData.borderNormal then
            bData.borderNormal = button:CreateTexture(nil, "BORDER", nil, 7)
            bData.borderNormal:SetTexture(TEXTURES.normal)
            bData.borderNormal:SetVertexColor(0, 0, 0, 1)
            bData.borderNormal:SetAllPoints(button)
        end
        bData.borderNormal:Show()
    elseif bData.borderNormal then
        bData.borderNormal:Hide()
    end

    if settings.showGloss then
        if not bData.gloss then
            bData.gloss = button:CreateTexture(nil, "OVERLAY", nil, -1)
            bData.gloss:SetTexture(TEXTURES.gloss)
            bData.gloss:SetBlendMode("ADD")
            bData.gloss:SetAllPoints(button)
        end
        bData.gloss:SetVertexColor(1, 1, 1, settings.glossAlpha or 0.6)
        bData.gloss:Show()
    elseif bData.gloss then
        bData.gloss:Hide()
    end
end

local function UnskinButton(button)
    if not button then return end
    local bData = ns._guiFD[button]
    if not bData then return end
    if bData.stripped then
        local icon = button.icon or button.Icon
        if icon then icon:SetTexCoord(0, 1, 0, 1); icon:SetAllPoints(button) end
        local nt = button:GetNormalTexture()
        if nt then nt:SetAlpha(1) end
        bData.stripped = nil
    end
    if bData.backdrop then bData.backdrop:Hide() end
    if bData.borderNormal then bData.borderNormal:Hide() end
    if bData.gloss then bData.gloss:Hide() end
end
ns.UnskinButton = UnskinButton

-------------------------------------------------------------------------------
--  Cooldown Countdown Font Styling
-------------------------------------------------------------------------------
local FONT_PATH = "Fonts\\FRIZQT__.TTF"  -- fallback; matches Blizzard default

local function EffectiveCooldownSize(cdFrame, cdSize, fitToButton)
    if not fitToButton then return cdSize end
    local host = cdFrame and (cdFrame:GetParent() or cdFrame)
    if not (host and host.GetWidth and host.GetHeight) then return cdSize end
    local w, h = host:GetWidth(), host:GetHeight()
    if not w or not h or w <= 0 or h <= 0 then return cdSize end
    local dim = (w < h) and w or h
    local cap = math.floor(dim * 0.40)
    if cap < 5 then cap = 5 end
    return (cdSize > cap) and cap or cdSize
end

local function ApplyCooldownFontToFrame(cdFrame, fontSize, xOff, yOff, color, fitToButton)
    if not cdFrame then return false end

    local eff = EffectiveCooldownSize(cdFrame, fontSize, fitToButton)
    local bData = GFD(cdFrame)
    local cr, cg, cb = color[1] or 1, color[2] or 0.82, color[3] or 0

    -- Skip if already applied with same settings
    local stamp = bData.cdFontStamp
    if stamp and stamp[1] == eff and stamp[2] == xOff and stamp[3] == yOff
       and stamp[4] == cr and stamp[5] == cg and stamp[6] == cb then
        return true
    end

    for ri = 1, cdFrame:GetNumRegions() do
        local region = select(ri, cdFrame:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local existingFont = region:GetFont()
            local fontPath = existingFont or FONT_PATH
            region:SetFont(fontPath, eff, "OUTLINE")
            region:SetTextColor(cr, cg, cb)
            region:ClearAllPoints()
            region:SetPoint("CENTER", cdFrame, "CENTER", xOff, yOff)
            bData.cdFontStamp = { eff, xOff, yOff, cr, cg, cb }
            return true
        end
    end
    return false
end

local function ApplyCooldownFont(btn, settings)
    if not btn or not settings then return end

    local fontSize = settings.cooldownFontSize or 14
    local xOff = settings.cooldownTextXOffset or 0
    local yOff = settings.cooldownTextYOffset or 0
    local color = settings.cooldownTextColor or { 1, 0.82, 0 }
    local fitToButton = settings.cooldownFitToButton ~= false

    local applied = ApplyCooldownFontToFrame(btn.cooldown, fontSize, xOff, yOff, color, fitToButton)
    local appliedCharge = (not btn.chargeCooldown)
        or ApplyCooldownFontToFrame(btn.chargeCooldown, fontSize, xOff, yOff, color, fitToButton)

    -- Retry once if FontString was not yet created (lazy initialization)
    if not applied or not appliedCharge then
        C_Timer.After(0.1, function()
            ApplyCooldownFontToFrame(btn.cooldown, fontSize, xOff, yOff, color, fitToButton)
            if btn.chargeCooldown then
                ApplyCooldownFontToFrame(btn.chargeCooldown, fontSize, xOff, yOff, color, fitToButton)
            end
        end)
    end
end
-------------------------------------------------------------------------------
--  Text Styling (Keybind/MacroName/Count)
-------------------------------------------------------------------------------
local function FormatKeyText(key)
    if not key or key == "" then return "" end
    key = key:gsub("CTRL%-", "C")
    key = key:gsub("ALT%-", "A")
    key = key:gsub("SHIFT%-", "S")
    key = key:gsub("META%-", "M")
    key = key:gsub("MOUSEWHEELUP", "WU")
    key = key:gsub("MOUSEWHEELDOWN", "WD")
    key = key:gsub("NUMPADDECIMAL", "N.")
    key = key:gsub("NUMPADPLUS", "N+")
    key = key:gsub("NUMPADMINUS", "N-")
    key = key:gsub("NUMPADMULTIPLY", "N*")
    key = key:gsub("NUMPADDIVIDE", "N/")
    key = key:gsub("NUMPAD", "N")
    key = key:gsub("BUTTON", "M")
    key = key:gsub("PAGEUP", "PU")
    key = key:gsub("PAGEDOWN", "PD")
    key = key:gsub("SPACE", "Spc")
    key = key:gsub("INSERT", "Ins")
    key = key:gsub("HOME", "Hm")
    key = key:gsub("DELETE", "Del")
    key = key:gsub("CAPSLOCK", "Caps")
    return key
end

local function UpdateButtonText(button, settings)
    if not button or not settings then return end

    local hotkey = button.HotKey
    if hotkey then
        if settings.showKeybinds then
            -- Actively query the keybind via GetBindingKey (Blizzard's native
            -- UpdateHotkeys never runs for our custom buttons)
            local bData = GFD(button)
            local barKey = bData.barKey
            local btnIdx = bData.btnIndex
            local text = ""

            if barKey and btnIdx then
                local bindCmd
                local info = BAR_LOOKUP[barKey]
                if info and not info.isStance and not info.isPetBar then
                    local prefix = BINDING_MAP[barKey]
                    if prefix then
                        bindCmd = prefix .. btnIdx
                    end
                elseif info and info.isStance then
                    bindCmd = "SHAPESHIFTBUTTON" .. btnIdx
                elseif info and info.isPetBar then
                    bindCmd = "BONUSACTIONBUTTON" .. btnIdx
                end

                if bindCmd then
                    local key1 = GetBindingKey(bindCmd)
                    if key1 then
                        text = FormatKeyText(key1)
                    end
                end
            end

            -- Fallback: read existing text (for Blizzard-skinned buttons)
            if text == "" then
                local existing = hotkey:GetText()
                if type(existing) == "string" and existing ~= "" then
                    if existing == _G.RANGE_INDICATOR then existing = "" end
                    text = FormatKeyText(existing)
                end
            end

            hotkey:SetText(text)
            hotkey:Show()
            hotkey:SetFont(hotkey:GetFont(), settings.keybindFontSize or 12, "OUTLINE")
            hotkey:ClearAllPoints()
            hotkey:SetPoint(settings.keybindAnchor or "TOPRIGHT", settings.keybindOffsetX or 0, settings.keybindOffsetY or -2)

            if settings.keybindColor then
                local c = settings.keybindColor
                hotkey:SetVertexColor(c[1], c[2], c[3], c[4])
            end

            local shouldHide = false
            if not text or text == "" then
                shouldHide = true
            elseif settings.hideEmptyKeybinds then
                local action = button:GetAttribute("action")
                if action and not HasAction(action) then
                    shouldHide = true
                end
            end

            if shouldHide then hotkey:Hide() end
        else
            hotkey:Hide()
        end
    end

    local name = button.Name
    if name then
        if settings.showMacroNames then
            -- Populate text (Blizzard's Update() is neutered)
            local action = button.action or button:GetAttribute("action")
            local macroText = ""
            if action and HasAction(action) then
                macroText = GetActionText(action) or ""
            end
            name:SetText(macroText)
            name:Show()
            name:SetFont(name:GetFont(), settings.macroNameFontSize or 10, "OUTLINE")
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

    local count = button.Count
    if count then
        if settings.showCounts then
            count:Show()
            count:SetFont(count:GetFont(), settings.countFontSize or 14, "OUTLINE")
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

-------------------------------------------------------------------------------
--  Empty Slot Visibility (via statehidden attribute, combat-safe)
-------------------------------------------------------------------------------
local function UpdateEmptySlotVisibility(btn, settings)
    if not btn or not settings then return end
    local fd = GFD(btn)
    local action = btn:GetAttribute("action")
    if not action then return end

    if not settings.hideEmptySlots then
        if fd.hiddenEmpty then
            btn:SetAlpha(1)
            fd.hiddenEmpty = nil
        end
        return
    end

    if HasAction(action) then
        if fd.hiddenEmpty then
            btn:SetAlpha(1)
            fd.hiddenEmpty = nil
        end
    else
        btn:SetAlpha(0)
        fd.hiddenEmpty = true
    end
end

-------------------------------------------------------------------------------
--  Fading System
-------------------------------------------------------------------------------
local fadeFrame = CreateFrame("Frame")
local barStates = {}
local barMetadata = {}

local fadeCombatWaker = CreateFrame("Frame")
fadeCombatWaker:RegisterEvent("PLAYER_REGEN_DISABLED")
fadeCombatWaker:RegisterEvent("PLAYER_REGEN_ENABLED")
fadeCombatWaker:SetScript("OnEvent", function()
    if fadeFrame then fadeFrame._settled = false end
end)

local function RefreshBarMetadata()
    wipe(barMetadata)
    for _, info in ipairs(BAR_CONFIG) do
        local frame = barFrames[info.key]
        if frame then
            table.insert(barMetadata, {
                key = info.key,
                frame = frame,
                buttons = barButtons[info.key] or {},
            })
        end
    end
    -- Add extra bars (MicroBar, BagBar)
    for _, info in ipairs(EXTRA_BARS) do
        local frame = info.frameName and _G[info.frameName]
        if frame then
            table.insert(barMetadata, {
                key = info.key,
                frame = frame,
            })
        end
    end
end

local function SetBarFrameAlpha(barKey, alpha)
    local frame = barFrames[barKey]
    if frame then
        frame:SetAlpha(alpha)
        return
    end
    -- Extra bars (MicroBar, BagBar) use Blizzard frames
    local info = BAR_LOOKUP[barKey]
    if info and info.frameName then
        local f = _G[info.frameName]
        if f then f:SetAlpha(alpha) end
    end
end

local function IsMouseOverBar(barKey)
    local frame = barFrames[barKey]
    if frame and frame:IsVisible() and frame:IsMouseOver() then
        return true
    end
    local info = BAR_LOOKUP[barKey]
    if info and info.frameName then
        local f = _G[info.frameName]
        if f and f:IsVisible() and f:IsMouseOver() then return true end
    end
    return false
end

local function UpdateFade(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
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

    local isMouseOverAnyLink = false
    if linkBars then
        for i = 1, #barMetadata do
            local bk = barMetadata[i].key
            local bdb = db.bars and db.bars[bk]
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

        local state = barStates[barKey]
        if not state then
            local current = frame and frame:GetAlpha() or 1
            barStates[barKey] = { lastHoverTime = 0, currentAlpha = current }
            state = barStates[barKey]
        end

        local barDB = db.bars and db.bars[barKey]
        local editMode = ns.Movers and ns.Movers.isEditMode
        local forceShow = editMode or (barDB and barDB.alwaysShow) or (inCombat and alwaysShowCombat)

        local isHovered = false
        if not forceShow then
            isHovered = IsMouseOverBar(barKey) or (linkBars and isMouseOverAnyLink)
        end

        if isHovered then state.lastHoverTime = currentTime end

        local isVisible = isHovered
        if not isVisible and (currentTime - state.lastHoverTime < fadeOutDelay) then
            isVisible = true
        end

        local shouldShow = isVisible or forceShow
        local targetAlpha = shouldShow and 1 or fadeOutAlpha

        local dirty = false
        if abs(state.currentAlpha - targetAlpha) > 0.01 then
            local duration = shouldShow and fadeInDur or fadeOutDur
            if duration < 0.01 then
                state.currentAlpha = targetAlpha
            else
                local step = tick / duration
                if state.currentAlpha < targetAlpha then
                    state.currentAlpha = min(targetAlpha, state.currentAlpha + step)
                else
                    state.currentAlpha = max(targetAlpha, state.currentAlpha - step)
                end
            end
            dirty = true
        elseif state.currentAlpha ~= targetAlpha then
            state.currentAlpha = targetAlpha
            dirty = true
        end

        if dirty then
            isAnyBarDirty = true
            SetBarFrameAlpha(barKey, state.currentAlpha)
        end
    end

    self._settled = not isAnyBarDirty
end

-------------------------------------------------------------------------------
--  Setup Bar: Creates bar frame, buttons, paging, layout
-------------------------------------------------------------------------------
local function SetupBar(info)
    if InCombatLockdown() then return end

    local db = GetDB()
    if not db or not db.enabled then return end

    local barDB = db.bars and db.bars[info.key]
    if barDB and barDB.enabled == false then
        -- Still create the frame so it can be registered with the mover system
        -- and re-enabled via the edit mode overlay
        if not barFrames[info.key] then
            CreateBarFrame(info)
        end
        if barFrames[info.key] then barFrames[info.key]:Hide() end
        return
    end

    -- Auto-hide stance bar for classes with no stances (DK, Mage, etc.)
    if info.isStance then
        local numForms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
        if numForms == 0 then return end
    end

    -- Auto-hide pet bar when no pet is active
    if info.isPetBar then
        local hasPet = UnitExists("pet")
        if not hasPet then
            -- Still create the frame but keep it hidden
            local frame = barFrames[info.key] or CreateBarFrame(info)
            frame:Hide()
            return
        end
    end

    -- Create bar frame
    local frame = barFrames[info.key] or CreateBarFrame(info)

    -- Paging (MainBar only)
    if info.nativeMainBar then
        local pagingConfig = barDB and barDB.paging
        local conditions
        if pagingConfig and next(pagingConfig) then
            conditions = BuildPagingConditions("MainBar", pagingConfig, 1)
        else
            conditions = GetClassPagingConditions()
        end

        frame:SetFrameRef("blizzmainbar", MainActionBar)
        frame:SetAttributeNoHandler("_onstate-page", [[
            local page = tonumber(newstate) or 1
            self:SetAttribute("actionpage", page)
            local blizzBar = self:GetFrameRef("blizzmainbar")
            if blizzBar then blizzBar:SetAttribute("actionpage", page) end
            self:ChildUpdate("gui-page", page)
        ]])
        -- RegisterStateDriver is deferred until AFTER buttons are created
        -- so that the initial ChildUpdate hits all child buttons.
        frame._pagingConditions = conditions
    end

    -- Create buttons
    local btns = {}
    barButtons[info.key] = btns
    local page = info.nativeActionPage or info.customPage or BAR_KEY_TO_PAGE[info.key] or 1
    local cols = (barDB and barDB.columns) or info.count
    local rows = (barDB and barDB.rows) or 1
    local btnW = (barDB and barDB.buttonWidth) or 45
    local btnH = (barDB and barDB.buttonHeight) or 45
    local spacing = (barDB and barDB.spacing) or 4
    local isVertical = (barDB and barDB.orientation == "vertical")
    local growDir = (barDB and barDB.growDirection) or "TOPLEFT"
    local visibleButtons = (barDB and barDB.visibleButtons) or info.count
    if visibleButtons > info.count then visibleButtons = info.count end

    for i = 1, info.count do
        local slot
        if info.isPetBar then
            slot = i  -- Pet buttons use SetID
        elseif info.isStance then
            slot = i  -- Stance buttons use native IDs
        elseif info.nativeMainBar then
            slot = i  -- MainBar slots 1-12, paged via ChildUpdate
        else
            slot = (page - 1) * 12 + i
        end

        local btn = GetOrCreateButton(slot, frame, info, i)
        if btn then
            btns[i] = btn

            -- Store bar identity for keybind text lookup
            local bData = GFD(btn)
            bData.barKey = info.key
            bData.btnIndex = i

            -- Set commandName for Blizzard Quick Keybind support
            local bindPrefix = BINDING_MAP[info.key]
            if bindPrefix then
                btn.commandName = bindPrefix .. i
            end

            -- Layout
            local col, row
            if isVertical then
                col = floor((i - 1) / rows)
                row = (i - 1) % rows
            else
                col = (i - 1) % cols
                row = floor((i - 1) / cols)
            end

            btn:ClearAllPoints()
            -- Growth direction: flip col/row offsets based on anchor
            local xMul = (growDir == "TOPRIGHT" or growDir == "BOTTOMRIGHT") and -1 or 1
            local yMul = (growDir == "BOTTOMLEFT" or growDir == "BOTTOMRIGHT") and 1 or -1
            local anchor = growDir
            btn:SetPoint(anchor, frame, anchor, xMul * col * (btnW + spacing), yMul * row * (btnH + spacing))
            btn:SetSize(btnW, btnH)

            -- ── Scale all overlay effects to button size ──────────────
            -- Cooldown swirl: must fill the button exactly
            if btn.cooldown then
                btn.cooldown:ClearAllPoints()
                btn.cooldown:SetAllPoints(btn)
            end

            -- Proc glow (SpellActivationAlert): pin to button bounds
            -- Native size is 128x128 for a 45x45 button → SetAllPoints rescales
            if btn.SpellActivationAlert then
                btn.SpellActivationAlert:ClearAllPoints()
                btn.SpellActivationAlert:SetAllPoints(btn)
                btn.SpellActivationAlert:SetScale(1)
            end

            -- AutoCast overlay (pet abilities)
            if btn.AutoCastOverlay then
                btn.AutoCastOverlay:ClearAllPoints()
                btn.AutoCastOverlay:SetAllPoints(btn)
            end

            -- Target reticle animation: authored 128x128 for 45x45 → scale ratio
            local sizeScale = btnW / 45
            if btn.TargetReticleAnimFrame then
                btn.TargetReticleAnimFrame:SetScale(sizeScale)
            end

            -- Assisted combat highlights: same 45x45 base
            if btn.AssistedCombatHighlightFrame then
                btn.AssistedCombatHighlightFrame:SetScale(sizeScale)
            end
            if btn.AssistedCombatRotationFrame then
                btn.AssistedCombatRotationFrame:SetScale(sizeScale)
            end

            -- Charge cooldown (recharge overlay)
            if btn.chargeCooldown then
                btn.chargeCooldown:ClearAllPoints()
                btn.chargeCooldown:SetAllPoints(btn)
            end

            -- Icon: ensure it fills the button after resize
            local icon = btn.icon or btn.Icon
            if icon then
                icon:ClearAllPoints()
                icon:SetAllPoints(btn)
            end

            -- MainBar paging childupdate
            if info.nativeMainBar and not info.isStance and not info.isPetBar then
                btn:SetAttributeNoHandler("_childupdate-gui-page", BuildPageChildSnippet(i))
            end

            if i <= visibleButtons then
                btn:Show()
            else
                btn:Hide()
            end
        end
    end

    -- Set bar frame size
    local totalCols = isVertical and ceil(visibleButtons / rows) or math.min(cols, visibleButtons)
    local totalRows = isVertical and rows or ceil(visibleButtons / cols)
    frame:SetSize(totalCols * (btnW + spacing) - spacing, totalRows * (btnH + spacing) - spacing)

    -- Restore saved position
    if barDB and barDB.position then
        local pos = barDB.position
        frame:ClearAllPoints()
        frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
    end

    -- Make movable for edit mode
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    -- Register the StateDriver NOW, after all buttons have been created
    -- and their _childupdate-gui-page snippets assigned
    if info.nativeMainBar and frame._pagingConditions then
        RegisterStateDriver(frame, "page", frame._pagingConditions)
        frame._pagingConditions = nil
    end

    -- Show (pet bar only if pet is active)
    if info.isPetBar then
        if UnitExists("pet") then frame:Show() else frame:Hide() end
    else
        frame:Show()
    end
end

-------------------------------------------------------------------------------
--  Hide Blizzard Stock Bars
-------------------------------------------------------------------------------
local function HideStockBars()
    if InCombatLockdown() then return end

    for _, entry in ipairs(STOCK_BAR_DISPOSAL) do
        local bar = _G[entry.name]
        if bar then
            if not entry.retainEvents then
                bar:UnregisterAllEvents()
            end
            bar:SetParent(hiddenParent)
        end
    end

    -- Quietly hide all Blizzard action buttons
    for _, info in ipairs(BAR_CONFIG) do
        if info.blizzBtnPrefix and not info.isStance and not info.isPetBar then
            for i = 1, info.count do
                local btn = _G[info.blizzBtnPrefix .. i]
                if btn then
                    QuietlyHideBlizzButton(btn)
                end
            end
        end
    end

    -- Hide StatusTrackingBarManager if we manage data bars
    local db = GetDB()
    if StatusTrackingBarManager and db and not db.useBlizzardDataBars then
        StatusTrackingBarManager:SetParent(hiddenParent)
    end
end

-------------------------------------------------------------------------------
--  Keybind System
-------------------------------------------------------------------------------
local keybindOwner = CreateFrame("Frame", "GravityUIKeybindOwner", UIParent)

local function UpdateKeybinds()
    if InCombatLockdown() then return end
    ClearOverrideBindings(keybindOwner)

    local db = GetDB()
    if not db or not db.enabled then return end

    local hasPH = false
    for _, info in ipairs(BAR_CONFIG) do
        if info.isStance or info.isPetBar then
            -- Stance/Pet keep Blizzard's native binding routing
        else
            local btns = barButtons[info.key]
            if btns then
                local cmdPrefix = BINDING_MAP[info.key]
                if not cmdPrefix then -- skip bars without commands

                else
                    -- Determine if this bar needs click-routing:
                    -- 1. Custom bars (Bar9/10) have no native binding command → must click-route
                    -- 2. Bars with user custom paging (modifier pages) → must click-route
                    --    (native commands resolve against Blizzard's page, not ours)
                    -- 3. Standard bars with default/class paging → native command routing
                    --    (engine pairs press+release for empower hold-and-release)
                    local isCustomBar = (info.key == "Bar9" or info.key == "Bar10")
                    local barDB = db.bars and db.bars[info.key]
                    local barHasCustomPaging = (barDB and barDB.paging and next(barDB.paging) ~= nil)

                    for i, btn in ipairs(btns) do
                        if btn then
                            local cmd = cmdPrefix .. i
                            local key1, key2 = GetBindingKey(cmd)
                            local btnName = btn:GetName()

                            -- Check if this specific slot is a flyout (needs click-route
                            -- so SpellFlyout:Toggle anchors to our visible button)
                            local action = btn:GetAttribute("action")
                            local isFlyout = false
                            if action and HasAction(action) then
                                local actionType = GetActionInfo(action)
                                isFlyout = (actionType == "flyout")
                            end

                            -- Always use click-route: key → synthetic click on our button
                            -- This ensures PushedTexture shows on keyboard input.
                            -- pressAndHoldAction attribute handles empower spells.
                            if key1 and btnName then
                                SetOverrideBindingClick(keybindOwner, false, key1, btnName, "LeftButton")
                            end
                            if key2 and btnName then
                                SetOverrideBindingClick(keybindOwner, false, key2, btnName, "LeftButton")
                            end

                            -- Empower detection (pressAndHoldAction attr for mouse clicks)
                            if action and HasAction(action) then
                                local actionType, id, subType = GetActionInfo(action)
                                local spellID = nil
                                if actionType == "spell" then
                                    spellID = id
                                elseif actionType == "macro" and subType == "spell" then
                                    spellID = id
                                end
                                if spellID and IsPressHoldReleaseSpell and IsPressHoldReleaseSpell(spellID) then
                                    btn:SetAttribute("pressAndHoldAction", true)
                                    hasPH = true
                                else
                                    btn:SetAttribute("pressAndHoldAction", false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    ns.SetBroadcasterPressHoldNeed(hasPH)
end

-------------------------------------------------------------------------------
--  Refresh / Public API
-------------------------------------------------------------------------------
function ns.RefreshActionBars()
    local db = GetDB()
    if not db then return end

    if InCombatLockdown() then
        ns.QueueOOCAction(function()
            if ns.RefreshActionBars then
                ns.RefreshActionBars()
            end
        end)
        return
    end

    RefreshBarMetadata()

    if not db.enabled then
        -- Cleanup: reset all bars
        fadeFrame:SetScript("OnUpdate", nil)
        for barKey, frame in pairs(barFrames) do
            frame:Hide()
        end
        return
    end

    -- Hide Blizzard bars
    HideStockBars()

    -- Setup all bars
    for _, info in ipairs(BAR_CONFIG) do
        SetupBar(info)
    end

    -- Apply skinning, text, and cooldown fonts
    local g = db.global
    for _, info in ipairs(BAR_CONFIG) do
        local btns = barButtons[info.key]
        if btns then
            for _, btn in ipairs(btns) do
                if btn then
                    SkinButton(btn, g)
                    UpdateButtonText(btn, g)
                    UpdateEmptySlotVisibility(btn, g)
                    ApplyCooldownFont(btn, g)
                end
            end
        end
    end

    -- Keybinds
    UpdateKeybinds()

    -- Fading
    RefreshBarMetadata()
    if db.fade and db.fade.enabled then
        fadeFrame._settled = false
        fadeFrame:SetScript("OnUpdate", UpdateFade)
        -- Pin always-show bars
        for barKey, _ in pairs(barFrames) do
            local barDB = db.bars and db.bars[barKey]
            if barDB and barDB.alwaysShow then
                SetBarFrameAlpha(barKey, 1)
                barStates[barKey] = { lastHoverTime = 0, currentAlpha = 1 }
            end
        end
    else
        fadeFrame:SetScript("OnUpdate", nil)
        for barKey, _ in pairs(barFrames) do
            SetBarFrameAlpha(barKey, 1)
        end
    end

    -- Extra Buttons
    if ns.InitializeExtraButtons then ns.InitializeExtraButtons() end

    -- Dominos Skinning (legacy)
    if C_AddOns.IsAddOnLoaded("Dominos") and db.skinDominos then
        local dominosPatterns = {
            { prefix = "DominosActionButton",             from = 1,  to = 24  },
            { prefix = "MultiBarRightActionButton",       from = 1,  to = 12  },
            { prefix = "MultiBarLeftActionButton",        from = 1,  to = 12  },
            { prefix = "MultiBarBottomRightActionButton", from = 1,  to = 12  },
            { prefix = "MultiBarBottomLeftActionButton",  from = 1,  to = 12  },
            { prefix = "DominosActionButton",             from = 73, to = 132 },
            { prefix = "MultiBar5ActionButton",           from = 1,  to = 12  },
            { prefix = "MultiBar6ActionButton",           from = 1,  to = 12  },
            { prefix = "MultiBar7ActionButton",           from = 1,  to = 12  },
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

    -- Bartender4 Skinning (legacy)
    if C_AddOns.IsAddOnLoaded("Bartender4") and db.skinBartender4 then
        for i = 1, 120 do
            local btn = _G["BT4Button" .. i]
            if btn then
                SkinButton(btn, g)
                UpdateButtonText(btn, g)
            end
        end
    end

    -- Register with GravityUI mover system
    -- IMPORTANT: toggleFunc must be a no-op for action bars!
    -- The fading system manages bar visibility exclusively.
    -- Without a toggleFunc, Movers:UpdateDisplay() would call frame:Hide()
    -- when exiting edit mode, causing ALL action bars to vanish.
    if ns.Movers and ns.Movers.Register then
        local abToggle = function(frame, show, editActive)
            -- In edit mode: show the frame so the overlay (child) is visible.
            -- Disabled bars need to be visible for the red overlay to render.
            -- On exit: leave frames visible; RefreshActionBars (called on exit) handles hiding.
            if show and frame and not InCombatLockdown() then
                frame:Show()
            end
        end
        for _, info in ipairs(BAR_CONFIG) do
            local frame = barFrames[info.key]
            if frame then
                local barKey = info.key  -- capture for closures
                ns.Movers:Register(
                    "ActionBar_" .. barKey,
                    frame,
                    abToggle,
                    info.label,
                    function(dbRoot)
                        if not dbRoot or not dbRoot.actionbars then return true end
                        local bars = dbRoot.actionbars.bars
                        if bars and bars[barKey] then
                            return bars[barKey].enabled ~= false
                        end
                        return true
                    end,
                    function(val, dbRoot)
                        if dbRoot and dbRoot.actionbars then
                            if not dbRoot.actionbars.bars then dbRoot.actionbars.bars = {} end
                            if not dbRoot.actionbars.bars[barKey] then dbRoot.actionbars.bars[barKey] = {} end
                            dbRoot.actionbars.bars[barKey].enabled = val
                        end
                        -- Don't refresh bars while in edit mode — it would hide the
                        -- bar frame (and its overlay child) for disabled bars.
                        -- The actual visibility update happens when exiting edit mode.
                        if not (ns.Movers and ns.Movers.isEditMode) then
                            if ns.RefreshActionBars then ns.RefreshActionBars() end
                        end
                    end
                )
            end
        end

        -- Register extra bars (BagBar, MicroBar) for mover system.
        -- These are protected Blizzard frames that reject StartMoving().
        -- Solution: wrap them in our own movable frame.
        for _, info in ipairs(EXTRA_BARS) do
            local frame = info.frameName and _G[info.frameName]
            if frame then
                local wrapperName = "GravityUI_" .. info.key .. "_Wrapper"
                local wrapper = _G[wrapperName]
                if not wrapper then
                    wrapper = CreateFrame("Frame", wrapperName, UIParent)
                    wrapper:SetMovable(true)
                    wrapper:SetClampedToScreen(true)
                    wrapper:SetUserPlaced(true)

                    -- Reparent Blizzard frame into our wrapper (pcall for safety)
                    pcall(function()
                        frame:SetParent(wrapper)
                        frame:ClearAllPoints()
                        frame:SetPoint("CENTER", wrapper, "CENTER", 0, 0)
                    end)

                    -- Prevent Blizzard's FramePositionManager from resetting position
                    frame.ignoreFramePositionManager = true
                    if frame.layoutParent then
                        frame.layoutParent = nil
                    end

                    -- Hook ClearAllPoints to re-anchor to wrapper (use hooksecurefunc for safety)
                    hooksecurefunc(frame, "ClearAllPoints", function(f)
                        if wrapper and wrapper:IsShown() then
                            pcall(f.SetPoint, f, "CENTER", wrapper, "CENTER", 0, 0)
                        end
                    end)
                end

                -- Size wrapper to match the Blizzard frame
                local w, h = frame:GetSize()
                if w and h and w > 0 and h > 0 then
                    wrapper:SetSize(w, h)
                else
                    wrapper:SetSize(200, 40)  -- fallback
                end

                -- Periodic size sync — Blizzard frames may resize after initial load
                if not wrapper._sizeHooked then
                    wrapper._sizeHooked = true
                    hooksecurefunc(frame, "SetSize", function(f, fw, fh)
                        if wrapper and fw and fh and fw > 0 and fh > 0 then
                            wrapper:SetSize(fw, fh)
                        end
                    end)
                end

                -- Restore saved position
                local barDB = db.bars and db.bars[info.key]
                if barDB and barDB.position then
                    local pos = barDB.position
                    wrapper:ClearAllPoints()
                    wrapper:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
                end

                wrapper:Show()
                frame:Show()

                -- Toggle function: ensure wrapper + child are always visible
                local extraToggle = function(wrapFrame, show, editActive)
                    if not wrapFrame then return end
                    if not InCombatLockdown() then
                        wrapFrame:Show()
                        pcall(frame.Show, frame)
                        pcall(frame.SetPoint, frame, "CENTER", wrapFrame, "CENTER", 0, 0)
                    end
                end

                ns.Movers:Register(
                    "ActionBar_" .. info.key,
                    wrapper,
                    extraToggle,
                    info.label,
                    function() return true end,
                    nil
                )
            end
        end

        -- Register ExtraAbilityContainer for our mover system.
        -- IMPORTANT: We do NOT reparent this frame (unlike BagBar/MicroBar).
        -- Reparenting ExtraAbilityContainer breaks Blizzard's edit mode system.
        -- Instead, we create a proxy mover that repositions the container via SetPoint.
        C_Timer.After(0.5, function()
            if InCombatLockdown() then return end
            if _G["GravityUI_ExtraAbilities_Proxy"] then return end

            -- Force-load the Blizzard addon that creates ExtraAbilityContainer
            if C_AddOns and C_AddOns.LoadAddOn then
                pcall(C_AddOns.LoadAddOn, "Blizzard_ExtraActionButton")
            elseif LoadAddOn then
                pcall(LoadAddOn, "Blizzard_ExtraActionButton")
            end

            local container = _G.ExtraAbilityContainer
            if not container then return end

            -- Restore saved position on the real container
            local barDB = db.bars and db.bars.ExtraAbilities
            if barDB and barDB.position then
                local pos = barDB.position
                container:ClearAllPoints()
                container:SetPoint(pos.point or "BOTTOM", UIParent, pos.relativePoint or "BOTTOM", pos.x or 0, pos.y or 100)
            end

            -- Create a proxy mover frame — same size, positioned at the container.
            local proxy = CreateFrame("Frame", "GravityUI_ExtraAbilities_Proxy", UIParent)
            proxy:SetSize(256, 120)
            proxy:SetMovable(true)
            proxy:SetClampedToScreen(true)
            proxy:SetFrameStrata("MEDIUM")

            -- Copy position from container (no SetAllPoints to avoid circular dependency)
            local p, _, rp, px, py = container:GetPoint()
            if p then
                proxy:SetPoint(p, UIParent, rp, px, py)
            else
                proxy:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
            end

            -- Override the mover's save logic to write position to both proxy and container
            local function SyncContainerToProxy()
                if InCombatLockdown() then return end
                local point, _, relPoint, x, y = proxy:GetPoint()
                if point then
                    container:ClearAllPoints()
                    container:SetPoint(point, UIParent, relPoint, x, y)
                    -- Save to DB
                    if not db.bars then db.bars = {} end
                    if not db.bars.ExtraAbilities then db.bars.ExtraAbilities = {} end
                    db.bars.ExtraAbilities.position = {
                        point = point,
                        relativePoint = relPoint,
                        x = math.floor(x + 0.5),
                        y = math.floor(y + 0.5),
                    }
                end
            end

            proxy._gravityOnMoveStop = SyncContainerToProxy

            ns.Movers:Register(
                "ActionBar_ExtraAbilities",
                proxy,
                abToggle,
                "Extra Abilities",
                function() return true end,
                nil
            )
        end)
    end
end

-------------------------------------------------------------------------------
--  Keyboard Pushed-State Flash
--  SetOverrideBinding routes keybinds to native engine commands, so buttons
--  never enter PUSHED state from keyboard input.  Fix: hook ActionButtonDown
--  for the main bar, and MultiActionButtonDown for multi-bars.  Additionally
--  hook ActionButtonUp to hide the texture on key release.
-------------------------------------------------------------------------------
do
    local _pushedHooked = false

    local function PushDown(btn)
        if not btn then return end
        -- Use native button state instead of timer-based Show/Hide
        pcall(btn.SetButtonState, btn, "PUSHED", true)
    end

    local function PushUp(btn)
        if not btn then return end
        pcall(btn.SetButtonState, btn, "NORMAL")
    end

    function ActionBars.HookKeyboardPush()
        if _pushedHooked then return end
        _pushedHooked = true

        -- Hook ActionButtonDown/Up (main bar key presses)
        if ActionButtonDown then
            hooksecurefunc("ActionButtonDown", function(id)
                PushDown(allButtons[tonumber(id)])
            end)
        end
        if ActionButtonUp then
            hooksecurefunc("ActionButtonUp", function(id)
                PushUp(allButtons[tonumber(id)])
            end)
        end

        -- Hook MultiActionButtonDown/Up (secondary bars)
        local multiBarPage = {
            MultiBarBottomLeft  = 6,
            MultiBarBottomRight = 5,
            MultiBarRight       = 3,
            MultiBarLeft        = 4,
            MultiBar5           = 13,
            MultiBar6           = 14,
            MultiBar7           = 15,
        }
        if MultiActionButtonDown then
            hooksecurefunc("MultiActionButtonDown", function(barName, id)
                local page = multiBarPage[barName]
                if page then PushDown(allButtons[(page - 1) * 12 + id]) end
            end)
        end
        if MultiActionButtonUp then
            hooksecurefunc("MultiActionButtonUp", function(barName, id)
                local page = multiBarPage[barName]
                if page then PushUp(allButtons[(page - 1) * 12 + id]) end
            end)
        end
    end
end

-- Usability update (external callers)
function ActionBars.UpdateAllUsability()
    local db = GetDB()
    if not db or not db.enabled then return end
    local g = db.global
    if not g or not g.usabilityIndicator then return end

    for _, info in ipairs(BAR_CONFIG) do
        local btns = barButtons[info.key]
        if btns then
            for _, btn in ipairs(btns) do
                if btn and btn:IsVisible() then
                    local action = btn:GetAttribute("action")
                    if action and HasAction(action) then
                        local icon = btn.icon or btn.Icon
                        if icon then
                            local isUsable = SafeIsUsableAction(action)
                            local fd = GFD(btn)
                            if not isUsable then
                                if fd.usableState ~= "unusable" then
                                    if g.usabilityDesaturate then
                                        icon:SetDesaturated(true)
                                        icon:SetVertexColor(0.6, 0.6, 0.6, 1)
                                    else
                                        icon:SetDesaturated(false)
                                        icon:SetVertexColor(0.65, 0.65, 0.65, 1)
                                    end
                                    fd.usableState = "unusable"
                                end
                            elseif fd.usableState then
                                icon:SetVertexColor(1, 1, 1, 1)
                                icon:SetDesaturated(false)
                                fd.usableState = nil
                            end
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
--  Extra Action Button / Zone Ability (Skinning only)
-------------------------------------------------------------------------------
function ns.InitializeExtraButtons()
    local db = GetDB()
    if not db or not db.enabled then return end

    if ExtraActionButton1 then
        local eb = db.bars and db.bars.extraActionButton
        if ExtraActionButton1.style then
            if eb and eb.hideArtwork then
                ExtraActionButton1.style:Hide()
                ExtraActionButton1.style:SetAlpha(0)
            else
                ExtraActionButton1.style:Show()
                ExtraActionButton1.style:SetAlpha(1)
            end
        end
        SkinButton(ExtraActionButton1, { showBorders = true, showBackdrop = true })
    end

    local zoneFrame = _G.ZoneAbilityFrame
    if zoneFrame then
        local zb = db.bars and db.bars.zoneAbility
        if zoneFrame.SpellButton and zoneFrame.SpellButton.Style then
            if zb and zb.hideArtwork then
                zoneFrame.SpellButton.Style:Hide()
                zoneFrame.SpellButton.Style:SetAlpha(0)
            else
                zoneFrame.SpellButton.Style:Show()
                zoneFrame.SpellButton.Style:SetAlpha(1)
            end
        end
        local function SkinZoneBtn(btn)
            if btn then SkinButton(btn, { showBorders = true, showBackdrop = true }) end
        end
        if zoneFrame.SpellButton then
            SkinZoneBtn(zoneFrame.SpellButton)
        elseif zoneFrame.SpellButtonContainer and zoneFrame.SpellButtonContainer.EnumerateActive then
            for btn in zoneFrame.SpellButtonContainer:EnumerateActive() do
                SkinZoneBtn(btn)
            end
        end
    end
end

-------------------------------------------------------------------------------
--  Zone Ability Keybind Mirror
-------------------------------------------------------------------------------
local zoneKeybindOwner = CreateFrame("Frame")
local zoneAbilityProxy = CreateFrame("Button", "GravityUI_ZoneAbilityProxy", UIParent, "SecureActionButtonTemplate")
local zoneKeybindPending = false
zoneAbilityProxy:SetSize(1, 1)
zoneAbilityProxy:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, 0)
zoneAbilityProxy:SetAlpha(0)
zoneAbilityProxy:RegisterForClicks("AnyDown", "AnyUp")
zoneAbilityProxy:SetAttribute("type", "macro")

local function GetZoneAbilityButton()
    if not ZoneAbilityFrame then return nil end
    if ZoneAbilityFrame.SpellButton then return ZoneAbilityFrame.SpellButton end
    local container = ZoneAbilityFrame.SpellButtonContainer
    if container then
        if container.EnumerateActive then
            for btn in container:EnumerateActive() do return btn end
        elseif container.GetChildren then
            return select(1, container:GetChildren())
        end
    end
    return nil
end

local function UpdateZoneAbilityKeybindText(spellBtn, keyText)
    if not spellBtn then return end
    local bData = GFD(spellBtn)
    if not bData.hotkey then
        bData.hotkey = spellBtn:CreateFontString(nil, "OVERLAY")
        bData.hotkey:SetFont("Fonts/FRIZQT__.TTF", 12, "OUTLINE")
        bData.hotkey:SetTextColor(1, 1, 1, 1)
        bData.hotkey:SetPoint("TOPRIGHT", spellBtn, "TOPRIGHT", 0, -2)
    end
    if keyText and keyText ~= "" then
        bData.hotkey:SetText(keyText)
        bData.hotkey:Show()
    else
        bData.hotkey:SetText("")
        bData.hotkey:Hide()
    end
end

local function ApplyZoneAbilityKeybind()
    if InCombatLockdown() then
        zoneKeybindPending = true
        return
    end
    zoneKeybindPending = false
    ClearOverrideBindings(zoneKeybindOwner)

    local db = GetDB()
    if not db or not db.bars or not db.bars.zoneAbility then return end
    if not db.bars.zoneAbility.mirrorExtraKeybind then
        UpdateZoneAbilityKeybindText(GetZoneAbilityButton(), nil)
        return
    end

    local key1 = GetBindingKey("EXTRAACTIONBUTTON1")
    local key2 = select(2, GetBindingKey("EXTRAACTIONBUTTON1"))
    if not key1 then return end

    local spellBtn = GetZoneAbilityButton()
    if not spellBtn then return end

    local btnName = spellBtn:GetName()
    if btnName then
        SetOverrideBindingClick(zoneKeybindOwner, false, key1, btnName, "LeftButton")
        if key2 then SetOverrideBindingClick(zoneKeybindOwner, false, key2, btnName, "LeftButton") end
        UpdateZoneAbilityKeybindText(spellBtn, FormatKeyText(key1))
        return
    end

    local spellID = spellBtn.spellID
    local spellName
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        spellName = info and info.name
    end

    if spellName then
        zoneAbilityProxy:SetAttribute("type", "macro")
        zoneAbilityProxy:SetAttribute("macrotext", "/cast " .. spellName)
        SetOverrideBindingClick(zoneKeybindOwner, false, key1, "GravityUI_ZoneAbilityProxy", "LeftButton")
        if key2 then SetOverrideBindingClick(zoneKeybindOwner, false, key2, "GravityUI_ZoneAbilityProxy", "LeftButton") end
        UpdateZoneAbilityKeybindText(spellBtn, FormatKeyText(key1))
        return
    end

    zoneAbilityProxy:SetAttribute("type", "click")
    zoneAbilityProxy:SetAttribute("clickbutton", spellBtn)
    SetOverrideBindingClick(zoneKeybindOwner, false, key1, "GravityUI_ZoneAbilityProxy", "LeftButton")
    if key2 then SetOverrideBindingClick(zoneKeybindOwner, false, key2, "GravityUI_ZoneAbilityProxy", "LeftButton") end
    UpdateZoneAbilityKeybindText(spellBtn, FormatKeyText(key1))
end

function ActionBars.RefreshZoneAbilityKeybind()
    ApplyZoneAbilityKeybind()
end

if ZoneAbilityFrame then
    ZoneAbilityFrame:HookScript("OnShow", function()
        C_Timer_After(0.2, ApplyZoneAbilityKeybind)
    end)
end

local zoneAbilityHookFrame = CreateFrame("Frame")
zoneAbilityHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneAbilityHookFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneAbilityHookFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
zoneAbilityHookFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if zoneKeybindPending then
            C_Timer_After(0.1, ApplyZoneAbilityKeybind)
        end
    else
        C_Timer_After(1.0, ApplyZoneAbilityKeybind)
    end
end)

-------------------------------------------------------------------------------
--  Import Blizzard Bar Positions (called from settings page button)
-------------------------------------------------------------------------------
local BLIZZ_BAR_MAP = {
    { key = "MainBar",   frame = "MainMenuBar",         btn = "ActionButton" },
    { key = "Bar2",      frame = "MultiBarBottomLeft",   btn = "MultiBarBottomLeftButton" },
    { key = "Bar3",      frame = "MultiBarBottomRight",  btn = "MultiBarBottomRightButton" },
    { key = "Bar4",      frame = "MultiBarRight",        btn = "MultiBarRightButton" },
    { key = "Bar5",      frame = "MultiBarLeft",         btn = "MultiBarLeftButton" },
    { key = "Bar6",      frame = "MultiBar5",            btn = "MultiBar5Button" },
    { key = "Bar7",      frame = "MultiBar6",            btn = "MultiBar6Button" },
    { key = "Bar8",      frame = "MultiBar7",            btn = "MultiBar7Button" },
    { key = "StanceBar", frame = "StanceBar",            btn = "StanceButton" },
    { key = "PetBar",    frame = "PetActionBar",         btn = "PetActionButton" },
}

-- Popup dialogs for import flow
StaticPopupDialogs["GRAVITYUI_IMPORT_STEP1"] = {
    text = "|cff30d1ffGravityUI|r\n\nA UI reload is required to capture your current Blizzard bar positions, sizes, and layout.\n\nGravityUI Action Bars will be temporarily disabled.",
    button1 = "Reload UI",
    button2 = "Cancel",
    OnAccept = function()
        local db = ns.GetDB and ns.GetDB()
        if not db then return end
        db.importPending = true
        if db.actionbars then db.actionbars.enabled = false end
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["GRAVITYUI_IMPORT_STEP2"] = {
    text = "|cff30d1ffGravityUI|r\n\n|cff00ff00%d|r bar positions captured successfully!\n\nClick below to enable GravityUI Action Bars with your Blizzard positions.",
    button1 = "Apply & Reload",
    button2 = "Cancel",
    OnAccept = function()
        local db = ns.GetDB and ns.GetDB()
        if not db then return end
        if db.actionbars then db.actionbars.enabled = true end
        db.importPending = nil
        ReloadUI()
    end,
    OnCancel = function()
        local db = ns.GetDB and ns.GetDB()
        if not db then return end
        db.importPending = nil
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

-- Step 1: User clicks Import → show confirmation popup
function ns.ImportBlizzardPositions()
    if InCombatLockdown() then
        print("|cff30d1ffGravityUI:|r Cannot import during combat.")
        return
    end
    StaticPopup_Show("GRAVITYUI_IMPORT_STEP1")
end

-- Step 2: Called on PLAYER_LOGIN when importPending is set
-- Blizzard bars are visible (our bars disabled), read everything
local function CompleteBlizzardImport()
    local rootDB = ns.GetDB()
    if not rootDB then return end
    local db = rootDB.actionbars
    if not db then return end
    if not db.bars then db.bars = {} end

    local imported = 0
    -- UIParent screen rect for coordinate conversion
    local uiLeft, uiBottom, uiWidth, uiHeight = UIParent:GetRect()
    local uiScale = UIParent:GetEffectiveScale()

    for _, map in ipairs(BLIZZ_BAR_MAP) do
        local blizzFrame = _G[map.frame]
        if blizzFrame then
            if not db.bars[map.key] then db.bars[map.key] = {} end
            local barDB = db.bars[map.key]

            -- ── Position ──
            -- Use FIRST BUTTON position, not bar frame.
            -- MainMenuBar is a large container (includes micro menu, bags)
            -- so its center doesn't match the action button area.
            local posRef = _G[map.btn .. "1"] or blizzFrame
            local refLeft, refTop
            if posRef.GetLeft and posRef.GetTop then
                refLeft = posRef:GetLeft()
                refTop = posRef:GetTop()
            end
            local refScale = posRef:GetEffectiveScale()
            if refLeft and refTop and uiScale > 0 then
                -- Convert to UIParent coordinate space (TOPLEFT anchor)
                local relX = refLeft * refScale / uiScale
                local relY = refTop * refScale / uiScale - uiHeight

                barDB.position = {
                    point = "TOPLEFT",
                    relativePoint = "TOPLEFT",
                    x = math.floor(relX + 0.5),
                    y = math.floor(relY + 0.5),
                }
                imported = imported + 1
            end

            -- ── Button size ──
            -- Use GetWidth/GetHeight (local coords, already scaled correctly)
            local btn1 = _G[map.btn .. "1"]
            if btn1 then
                local w, h = btn1:GetWidth(), btn1:GetHeight()
                -- If button has a different scale than UIParent, adjust
                local btnScale = btn1:GetEffectiveScale()
                if w and h and w > 5 and h > 5 then
                    local adjustedW = w * btnScale / uiScale
                    local adjustedH = h * btnScale / uiScale
                    barDB.buttonWidth = math.floor(adjustedW + 0.5)
                    barDB.buttonHeight = math.floor(adjustedH + 0.5)
                end

                -- ── Columns/Rows detection ──
                local numButtons = 12
                if map.key == "StanceBar" or map.key == "PetBar" then numButtons = 10 end

                local _, b1Y = btn1:GetCenter()
                local sameRow = 1
                local visibleCount = btn1:IsShown() and 1 or 0
                for i = 2, numButtons do
                    local btn = _G[map.btn .. i]
                    if btn and btn:IsShown() then
                        visibleCount = visibleCount + 1
                        local _, bY = btn:GetCenter()
                        if bY and b1Y and math.abs(bY - b1Y) < 10 then
                            sameRow = sameRow + 1
                        else
                            break
                        end
                    else
                        break
                    end
                end

                if sameRow > 0 then
                    barDB.columns = sameRow
                    barDB.rows = math.ceil(numButtons / sameRow)
                end
                -- Always show all buttons — Blizzard may hide empty slots
                barDB.visibleButtons = numButtons

                -- ── Spacing ──
                local btn2 = _G[map.btn .. "2"]
                if btn2 and btn2:IsShown() then
                    local r1 = btn1:GetRight()
                    local l2 = btn2:GetLeft()
                    if r1 and l2 then
                        local gap = (l2 - r1) * (btn1:GetEffectiveScale() / uiScale)
                        gap = math.floor(gap + 0.5)
                        if gap >= 0 and gap <= 20 then
                            barDB.spacing = gap
                        end
                    end
                end
            end

            barDB.enabled = true
            print("|cff30d1ffImport|r " .. map.key .. ": pos=" .. (barDB.position and (barDB.position.x .. "," .. barDB.position.y) or "nil")
                .. " size=" .. (barDB.buttonWidth or "?") .. "x" .. (barDB.buttonHeight or "?")
                .. " cols=" .. (barDB.columns or "?") .. " rows=" .. (barDB.rows or "?")
                .. " vis=" .. (barDB.visibleButtons or "?") .. " spc=" .. (barDB.spacing or "?"))
        end
    end

    -- Show popup with capture count
    StaticPopup_Show("GRAVITYUI_IMPORT_STEP2", imported)
end

-------------------------------------------------------------------------------
--  Initialization
-------------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("UPDATE_BINDINGS")
initFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
-- Vehicle/override events for broadcaster management
initFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
initFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
initFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
initFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
initFrame:RegisterUnitEvent("UNIT_PET", "player")
initFrame:RegisterEvent("PET_BAR_UPDATE")

initFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Check if we need to complete a Blizzard import (Step 2)
        -- Note: importPending is on the ROOT db (ns.GetDB()), not the actionbars sub-DB
        local rootDB = ns.GetDB()
        if rootDB and rootDB.importPending then
            -- Delay to ensure all Blizzard bars are fully positioned
            C_Timer_After(1.0, CompleteBlizzardImport)
            return  -- Don't init our bars yet
        end
        ns.RefreshActionBars()
        ActionBars.HookKeyboardPush()
        -- Always suppress Blizzard's red keybind text
        ActionBars.StartKeybindRangeOverride()
        -- Init range coloring if enabled
        local db = GetDB()
        local g = db and db.global
        if g and g.outOfRangeColoring then
            C_Timer_After(0.5, function() ActionBars.EnableRangeColoring() end)
        end
        C_Timer_After(0.5, ApplyZoneAbilityKeybind)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        if isLogin or isReload then
            C_Timer_After(0.5, function()
                if ns.InitializeExtraButtons then ns.InitializeExtraButtons() end
            end)
        end
        -- Refresh broadcaster state on zone transitions
        ns.InvalidateBroadcasterState()
    elseif event == "UPDATE_BINDINGS" then
        if not InCombatLockdown() then
            UpdateKeybinds()
            ApplyZoneAbilityKeybind()
        end
    elseif event == "UNIT_PET" or event == "PET_BAR_UPDATE" then
        -- Pet summoned/dismissed/updated: toggle pet bar + refresh icons
        local petFrame = barFrames["PetBar"]
        if UnitExists("pet") then
            -- If pet bar was never fully set up (e.g. login on mount),
            -- run full SetupBar now to create buttons
            if not petFrame or not barButtons["PetBar"] or #barButtons["PetBar"] == 0 then
                if not InCombatLockdown() then
                    for _, info in ipairs(BAR_CONFIG) do
                        if info.isPetBar then
                            SetupBar(info)
                            -- Apply skinning to newly created pet buttons
                            local db = GetDB()
                            if db then
                                local g = db.global
                                local petBtns = barButtons["PetBar"]
                                if petBtns and g then
                                    for _, btn in ipairs(petBtns) do
                                        if btn then
                                            SkinButton(btn, g)
                                            UpdateButtonText(btn, g)
                                            ApplyCooldownFont(btn, g)
                                        end
                                    end
                                end
                            end
                            UpdateKeybinds()
                            break
                        end
                    end
                end
            else
                if not InCombatLockdown() then petFrame:Show() end
                -- Refresh pet button icons (delayed to let game register abilities)
                local function RefreshPetIcons()
                    local petBtns = barButtons["PetBar"]
                    if not petBtns then return end
                    for i, btn in ipairs(petBtns) do
                        if btn then
                            local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(i)
                            local icon = btn.icon or btn.Icon
                            if icon then
                                if texture then
                                    if isToken then
                                        icon:SetTexture(_G[texture])
                                    else
                                        icon:SetTexture(texture)
                                    end
                                    icon:Show()
                                else
                                    icon:Hide()
                                end
                            end
                        end
                    end
                end
                RefreshPetIcons()
                -- Second pass after abilities fully load
                C_Timer_After(0.5, RefreshPetIcons)
            end
        else
            if petFrame then
                if not InCombatLockdown() then
                    petFrame:Hide()
                else
                    -- Defer hide until combat ends
                    petFrame._hidePending = true
                end
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended: refresh deferred operations
        ns.InvalidateBroadcasterState()
        -- Deferred pet bar hide
        local petFrame = barFrames["PetBar"]
        if petFrame and petFrame._hidePending then
            petFrame._hidePending = nil
            if not UnitExists("pet") then
                petFrame:Hide()
            end
        end
        C_Timer_After(0.1, function()
            if not InCombatLockdown() then
                UpdateKeybinds()
            end
        end)
    elseif event == "UPDATE_OVERRIDE_ACTIONBAR" or event == "UPDATE_VEHICLE_ACTIONBAR"
        or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
        -- Vehicle/override state change
        local isVehicle = (event == "UNIT_ENTERED_VEHICLE" or event == "UPDATE_VEHICLE_ACTIONBAR")
        ns.SetBroadcasterVehicleNeed(isVehicle or HasVehicleActionBar and HasVehicleActionBar())

        -- Force-paint cooldowns and keybinds on Blizzard's OverrideActionBar buttons.
        -- The broadcaster only catches the NEXT cooldown change; already-running
        -- cooldowns need an explicit initial paint.
        if event == "UNIT_ENTERED_VEHICLE" or event == "UPDATE_VEHICLE_ACTIONBAR"
            or event == "UPDATE_OVERRIDE_ACTIONBAR" then
            C_Timer_After(0, function()
                for i = 1, 6 do
                    local btn = _G["OverrideActionBarButton" .. i]
                    if btn then
                        ForceCooldownPaint(btn)
                        -- Paint keybind text on the override button
                        local hk = btn.HotKey
                        if hk then
                            local key1 = GetBindingKey("ACTIONBUTTON" .. i)
                            if key1 then
                                hk:SetText(FormatKeyText(key1))
                                hk:Show()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Dominos loading hook
local dominosHookFrame = CreateFrame("Frame")
dominosHookFrame:RegisterEvent("ADDON_LOADED")
dominosHookFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Dominos" then
        local waitFrame = CreateFrame("Frame")
        waitFrame:RegisterEvent("PLAYER_LOGIN")
        waitFrame:SetScript("OnEvent", function(wf)
            C_Timer_After(0.5, function()
                local db = GetDB()
                if db and db.skinDominos then
                    ns.RefreshActionBars()
                end
            end)
            wf:UnregisterEvent("PLAYER_LOGIN")
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-------------------------------------------------------------------------------
--  Register Edit Mode Settings Provider for Action Bars
-------------------------------------------------------------------------------
C_Timer_After(0, function()
    if not ns.Movers or not ns.Movers.RegisterSettingsProvider then return end

    local function GetBarDB(moverName)
        local barKey = moverName:match("^ActionBar_(.+)$")
        if not barKey then return nil, nil end
        local db = GetDB()
        if not db or not db.bars then return nil, nil end
        if not db.bars[barKey] then db.bars[barKey] = {} end
        return db.bars[barKey], barKey
    end

    local function abRefresh()
        if ns.RefreshActionBars then
            C_Timer.After(0.05, function()
                if not InCombatLockdown() then ns.RefreshActionBars() end
            end)
        end
    end

    local orientOpts = {
        { value = "horizontal", text = "Horizontal" },
        { value = "vertical",   text = "Vertical" },
    }

    local growOpts = {
        { value = "TOPLEFT",     text = "Top Left (→↓)" },
        { value = "BOTTOMLEFT",  text = "Bottom Left (→↑)" },
        { value = "TOPRIGHT",    text = "Top Right (←↓)" },
        { value = "BOTTOMRIGHT", text = "Bottom Right (←↑)" },
    }

    ns.Movers:RegisterSettingsProvider("ActionBar_*", {
        label = "Action Bar Settings",
        tabs = {
            -- ── Tab 1: Layout ──
            {
                label = "Layout",
                build = function(parent, moverName, yPos, rowStep)
                    local barDB, barKey = GetBarDB(moverName)
                    if not barDB then return {}, yPos end

                    local rows = {}
                    local r
                    local maxBtns = (barKey == "StanceBar" or barKey == "PetBar") and 10 or 12

                    r = ns.SPCheckbox(parent, "Enabled",
                        function() return barDB.enabled ~= false end,
                        function(v) barDB.enabled = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPCheckbox(parent, "Always Show",
                        function() return barDB.alwaysShow ~= false end,
                        function(v) barDB.alwaysShow = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPSlider(parent, "Visible Buttons", 1, maxBtns, 1,
                        function() return barDB.visibleButtons or maxBtns end,
                        function(v) barDB.visibleButtons = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPSlider(parent, "Columns", 1, 12, 1,
                        function() return barDB.columns or 12 end,
                        function(v) barDB.columns = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPSlider(parent, "Rows", 1, 12, 1,
                        function() return barDB.rows or 1 end,
                        function(v) barDB.rows = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPSlider(parent, "Button Width", 20, 80, 1,
                        function() return barDB.buttonWidth or 45 end,
                        function(v) barDB.buttonWidth = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPSlider(parent, "Button Height", 20, 80, 1,
                        function() return barDB.buttonHeight or 45 end,
                        function(v) barDB.buttonHeight = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPSlider(parent, "Spacing", 0, 20, 1,
                        function() return barDB.spacing or 4 end,
                        function(v) barDB.spacing = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPDropdown(parent, "Orientation", orientOpts,
                        function() return barDB.orientation or "horizontal" end,
                        function(v) barDB.orientation = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPDropdown(parent, "Growth Direction", growOpts,
                        function() return barDB.growDirection or "TOPLEFT" end,
                        function(v) barDB.growDirection = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    return rows, yPos
                end,
            },
            -- ── Tab 2: Appearance ──
            {
                label = "Appearance",
                build = function(parent, moverName, yPos, rowStep)
                    local db = GetDB()
                    if not db then return {}, yPos end
                    local g = db.global
                    if not g then db.global = {}; g = db.global end

                    local rows = {}
                    local r

                    r = ns.SPCheckbox(parent, "Show Backdrop",
                        function() return g.showBackdrop ~= false end,
                        function(v) g.showBackdrop = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPSlider(parent, "Backdrop Opacity", 0, 1, 0.05,
                        function() return g.backdropAlpha or 0.5 end,
                        function(v) g.backdropAlpha = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPCheckbox(parent, "Show Gloss Effect",
                        function() return g.showGloss ~= false end,
                        function(v) g.showGloss = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPCheckbox(parent, "Show Macro Text",
                        function() return g.showMacroText ~= false end,
                        function(v) g.showMacroText = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPCheckbox(parent, "Show Keybind Text",
                        function() return g.showKeybindText ~= false end,
                        function(v) g.showKeybindText = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    r = ns.SPCheckbox(parent, "Desaturate Unusable",
                        function() return g.usabilityDesaturate == true end,
                        function(v) g.usabilityDesaturate = v; abRefresh() end, yPos)
                    rows[#rows + 1] = r; yPos = yPos + rowStep

                    return rows, yPos
                end,
            },
        },
    })
end)

-------------------------------------------------------------------------------
--  Diagnostic: /gravitydebugcd
-------------------------------------------------------------------------------
SLASH_GRAVITYDEBUGCD1 = "/gravitydebugcd"
SlashCmdList["GRAVITYDEBUGCD"] = function()
    print("|cFF30D1FFGravityUI CD Debug (Own Buttons):|r")
    print("  InCombatLockdown:", tostring(InCombatLockdown()))
    print("  Own buttons created:", tostring(not not barButtons.MainBar))
    local btns = barButtons.MainBar
    if btns then
        print("  MainBar button count:", #btns)
        for i, b in ipairs(btns) do
            if b then
                local action = b:GetAttribute("action")
                if action and HasAction(action) then
                    local cd = b.cooldown
                    if cd then
                        local ok, s, d = pcall(cd.GetCooldownTimes, cd)
                        local shown = cd:IsShown()
                        local alpha = cd:GetAlpha()
                        if ok and (s and s > 0) then
                            print(string.format("    [%d] action=%d cdTimes=%d/%d shown=%s alpha=%.2f",
                                i, action, s or 0, d or 0, tostring(shown), alpha or 0))
                        end
                    end
                end
            end
        end
    end
    local ok, secure = pcall(issecurevariable, _G["GravityUIButton1"] or CreateFrame("Frame"), "cooldown")
    if ok then print("  GravityUIButton1.cooldown secure:", tostring(secure)) end
    if C_Secrets and C_Secrets.ShouldCooldownsBeSecret then
        local sok, secret = pcall(C_Secrets.ShouldCooldownsBeSecret)
        print("  CooldownsSecret:", sok and tostring(secret) or "error")
    end
end
