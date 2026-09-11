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
    { name = "PetActionBar" },
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
        "ACTIONBAR_UPDATE_COOLDOWN", "ACTIONBAR_UPDATE_STATE",
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
            -- Neuter UpdateButtonArt: it resets NormalTexture/PushedTexture
            -- atlases on every call, causing mass GPU redraws
            btn.UpdateButtonArt = function() end
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

        -- Register our per-button events
        ReRegisterButtonEvents(btn, "action")
    end

    if btn then
        allButtons[slot] = btn
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
            cd:Clear()
        end
    end
end
ns.ForceCooldownPaint = ForceCooldownPaint

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
                cd:Clear()
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
                    btn.chargeCooldown:Clear()
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
        -- Icon
        local icon = btn.icon or btn.Icon
        if icon then
            local tex = HasAction(action) and GetActionTexture(action)
            if tex then
                icon:SetTexture(tex)
                icon:Show()
            else
                icon:Hide()
            end
        end
        -- Cooldown
        PushButtonCooldown(btn)
        -- Count (secret-safe)
        if btn.Count and C_ActionBar.GetActionDisplayCount then
            local display = C_ActionBar.GetActionDisplayCount(action)
            if issecretvalue and issecretvalue(display) then
                btn.Count:SetText(display)
            else
                if display == nil then display = "" end
                btn.Count:SetText(display)
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
                            local action = btn:GetAttribute("action")
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
                                            icon:SetVertexColor(0.4, 0.4, 0.4, 1)
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
        elseif event == "PLAYER_ENTERING_WORLD"
            or event == "UPDATE_SHAPESHIFT_FORM"
            or event == "ACTIONBAR_PAGE_CHANGED"
            or event == "UPDATE_BONUS_ACTIONBAR"
            or event == "UPDATE_VEHICLE_ACTIONBAR"
            or event == "UPDATE_OVERRIDE_ACTIONBAR" then
            DispatchSlotChanged(0)
            DispatchCooldownUpdate()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            DispatchCooldownUpdate()
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
    FitTextureToButton(button.HighlightTexture)
    FitTextureToButton(button.PushedTexture)
    FitTextureToButton(button.CheckedTexture)
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
    if barDB and barDB.enabled == false then return end

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
        RegisterStateDriver(frame, "page", conditions)
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
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT", col * (btnW + spacing), -row * (btnH + spacing))
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

            btn:Show()
        end
    end

    -- Set bar frame size
    local totalCols = isVertical and ceil(info.count / rows) or cols
    local totalRows = isVertical and rows or ceil(info.count / cols)
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

    -- Show
    frame:Show()
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

                            local useClickRoute = isCustomBar or barHasCustomPaging or isFlyout

                            if useClickRoute then
                                -- Click-route: key → synthetic click on our button
                                -- Reads our paged "action" attribute correctly
                                if key1 and btnName then
                                    SetOverrideBindingClick(keybindOwner, false, key1, btnName, "LeftButton")
                                end
                                if key2 and btnName then
                                    SetOverrideBindingClick(keybindOwner, false, key2, btnName, "LeftButton")
                                end
                            else
                                -- Native command route: key → ACTIONBUTTON1, MULTIACTIONBAR1BUTTON1, etc.
                                -- Engine handles key-state pairing (empower hold-and-release,
                                -- press-and-hold repeat, queued empowers) natively
                                if key1 then
                                    SetOverrideBinding(keybindOwner, false, key1, cmd)
                                end
                                if key2 then
                                    SetOverrideBinding(keybindOwner, false, key2, cmd)
                                end
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
            -- No-op: fading system handles bar visibility.
            -- The mover overlay is handled separately by ApplyEditModeStyle.
        end
        for _, info in ipairs(BAR_CONFIG) do
            local frame = barFrames[info.key]
            if frame then
                ns.Movers:Register(
                    "ActionBar_" .. info.key,
                    frame,
                    abToggle,
                    info.label,
                    function(dbRoot)
                        return dbRoot and dbRoot.actionbars and dbRoot.actionbars.enabled ~= false
                    end,
                    function(val, dbRoot)
                        if dbRoot and dbRoot.actionbars then
                            dbRoot.actionbars.enabled = val
                        end
                        if ns.RefreshActionBars then ns.RefreshActionBars() end
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

                    -- Reparent Blizzard frame into our wrapper
                    frame:SetParent(wrapper)
                    frame:ClearAllPoints()
                    frame:SetPoint("CENTER", wrapper, "CENTER", 0, 0)

                    -- Prevent Blizzard's FramePositionManager from resetting position
                    frame.ignoreFramePositionManager = true
                    if frame.layoutParent then
                        frame.layoutParent = nil
                    end

                    -- Hook ClearAllPoints to immediately re-anchor to wrapper
                    -- Blizzard layout may try to reposition the child frame
                    local origClear = frame.ClearAllPoints
                    frame.ClearAllPoints = function(f, ...)
                        origClear(f, ...)
                        f:SetPoint("CENTER", wrapper, "CENTER", 0, 0)
                    end
                end

                -- Size wrapper to match the Blizzard frame
                local w, h = frame:GetSize()
                if w and h and w > 0 and h > 0 then
                    wrapper:SetSize(w, h)
                else
                    wrapper:SetSize(200, 40)  -- fallback
                end

                -- Restore saved position
                local barDB = db.bars and db.bars[info.key]
                if barDB and barDB.position then
                    local pos = barDB.position
                    wrapper:ClearAllPoints()
                    wrapper:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
                end

                wrapper:Show()

                ns.Movers:Register(
                    "ActionBar_" .. info.key,
                    wrapper,
                    abToggle,  -- no-op
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
                                        icon:SetVertexColor(0.4, 0.4, 0.4, 1)
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

function ns.ImportBlizzardPositions()
    local db = GetDB()
    if not db or not db.bars then return end

    local imported = 0
    for _, map in ipairs(BLIZZ_BAR_MAP) do
        local blizzFrame = _G[map.frame]
        if blizzFrame and blizzFrame.GetPoint and blizzFrame:GetNumPoints() > 0 then
            if not db.bars[map.key] then db.bars[map.key] = {} end
            local barDB = db.bars[map.key]

            -- Position
            local point, relativeTo, relativePoint, x, y = blizzFrame:GetPoint(1)
            if point then
                barDB.position = {
                    point = point,
                    relativePoint = relativePoint or point,
                    x = x or 0,
                    y = y or 0,
                }
                imported = imported + 1
            end

            -- Button size from first button
            local btn1 = _G[map.btn .. "1"]
            if btn1 and btn1.GetWidth then
                local w, h = btn1:GetWidth(), btn1:GetHeight()
                if w and w > 10 and h and h > 10 then
                    barDB.buttonWidth = math.floor(w + 0.5)
                    barDB.buttonHeight = math.floor(h + 0.5)
                end
            end

            -- Spacing from first two buttons
            local btn2 = _G[map.btn .. "2"]
            if btn1 and btn2 and btn1.GetRight and btn2.GetLeft then
                local right = btn1:GetRight()
                local left = btn2:GetLeft()
                if right and left then
                    local gap = math.floor(left - right + 0.5)
                    if gap >= 0 and gap <= 20 then
                        barDB.spacing = gap
                    end
                end
            end
        end
    end

    -- Refresh bars with new positions
    if ns.RefreshActionBars then
        C_Timer.After(0.05, function()
            if not InCombatLockdown() then ns.RefreshActionBars() end
        end)
    end

    print("|cff30d1ffGravityUI:|r " .. imported .. " Action Bar positions imported from Blizzard.")
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

initFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ns.RefreshActionBars()
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
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended: refresh deferred operations
        ns.InvalidateBroadcasterState()
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
