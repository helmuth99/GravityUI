-- GravityUI Core Initialization
local ADDON_NAME, ns = ...

-- Keybinding display name (must be global before Bindings.xml loads)
BINDING_NAME_GravityUI_TOGGLE_OPTIONS = "Open GravityUI Options"

-- Create main addon object
local Addon = LibStub("AceAddon-3.0"):NewAddon("GravityUI", "AceConsole-3.0", "AceEvent-3.0")
ns.Addon = Addon

-- Database reference
ns.db = nil
ns.trackedFonts = {}

-- v2026-08 (Midnight compat): GetSpecialization / GetSpecializationInfo were moved
-- from globals into C_SpecializationInfo. Any GravityUI code that needs these should
-- call ns.GetSpecialization() / ns.GetSpecializationInfo() so both expansions work.
-- (Libs like LibOpenRaid and LibDualSpec already have their own local wrappers.)
do
    local CSI = C_SpecializationInfo
    ns.GetSpecialization = (CSI and CSI.GetSpecialization) or GetSpecialization
    ns.GetSpecializationInfo = (CSI and CSI.GetSpecializationInfo) or GetSpecializationInfo
end


-- Database caching
local dbCache = nil
function ns.GetDB()
    if not dbCache and ns.db then
        dbCache = ns.db.profile
    end
    return dbCache
end

-- Helper to clear caches
function ns.InvalidateCaches()
    dbCache = nil
    ns.accentCache = nil
end

-- Standard Print Helper
function ns.Print(msg)
    print("|cFF30D1FFGravityUI|r " .. tostring(msg))
end

-- Get AceDB object for profile management
function ns.GetAceDB()
    return ns.db
end

-- Reset all settings to defaults
function ns.ResetDB()
    if ns.db then
        ns.db:ResetProfile()
    end
end

-- (Invalidate defined above, this duplicate removed)

-- Get accent color (with class color option and caching)
ns.accentCache = nil
function ns.GetAccentColor()
    if ns.accentCache then
        return unpack(ns.accentCache)
    end

    local db = ns.GetDB()
    local r, g, b, a = 0, 0.749, 1, 1 -- Default fallback

    if db and db.general and db.general.useClassColorTheme then
        local _, class = UnitClass("player")
        local color = class and C_ClassColor.GetClassColor(class)
        if color then
            r, g, b, a = color.r, color.g, color.b, 1
        end
    elseif db and db.general and db.general.themeColor then
        local tc = db.general.themeColor
        if tc[1] then
            r, g, b, a = tc[1], tc[2], tc[3], tc[4] or 1
        end
    else
        r, g, b, a = unpack(ns.DEFAULT_ACCENT or {0, 0.749, 1, 1})
    end

    ns.accentCache = {r, g, b, a}
    return r, g, b, a
end

-- Get theme background color
function ns.GetThemeBgColor()
    local db = ns.GetDB()
    local tbc = db and db.general and db.general.themeBgColor
    if tbc and tbc[1] then
        return tbc[1], tbc[2], tbc[3], tbc[4] or 1
    end
    -- Fallback to default bg color from constants (re-unpacked)
    return 0.117, 0.121, 0.133, 1
end

-- Refresh accent colors throughout UI
function ns.RefreshAccentColors()
    ns.InvalidateCaches()
    
    if ns.GUI and ns.GUI.RefreshColors then
        ns.GUI:RefreshColors()
    end
    
    -- Refresh Sidebar Style if Open
    if ns.GUI and ns.GUI.RefreshSidebarStyle then
        ns.GUI:RefreshSidebarStyle()
    end
    
    -- explicitly refresh modules that rely on accent color
    if ns.RefreshMinimap then ns.RefreshMinimap() end
    if ns.RefreshDatapanels then ns.RefreshDatapanels() end
    if ns.RefreshSkyriding then ns.RefreshSkyriding() end
    if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end
    if ns.RefreshCombatTimer then ns.RefreshCombatTimer() end
    if ns.Character and ns.Character.RefreshBackground then ns.Character.RefreshBackground() end
    
    -- New refresh calls for UI Styling
    if ns.Styling and ns.Styling.Refresh then ns.Styling:Refresh() end
    if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end -- Alerts re-init resets colors
    if ns.Loot and ns.Loot.RefreshStyling then ns.Loot:RefreshStyling() end
    if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot:RefreshHistoryStyling() end
    if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    if ns.Objectives and ns.Objectives.Initialize then ns.Objectives:Initialize() end
    if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    -- Sync EllesmereUI accent color whenever GravityUI's theme color changes.
    if ns.SyncEllesmereAccentColor then ns.SyncEllesmereAccentColor() end
end

-- Get global font settings
function ns.GetFont()
    local db = ns.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    local outline = (db and db.general and db.general.fontOutline) or "OUTLINE"
    
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local fontPath = LSM and LSM:Fetch("font", fontName) or ns.FONT_PATH
    
    return fontPath, outline
end

-- AceAddon callback - initializes database
function Addon:OnInitialize()
    -- Initialize database with defaults
    ns.db = LibStub("AceDB-3.0"):New("GravityUI_DB", ns.Defaults, true)
    
    -- Enhance with LibDualSpec for spec-based profiles
    local LibDualSpec = LibStub("LibDualSpec-1.0", true)
    if LibDualSpec then
        LibDualSpec:EnhanceDatabase(ns.db, "GravityUI")
    end
    -- Force reset if minimap is missing (migration helper)
    -- (Removed reset logic to prevent settings loss)
    -- if not ns.db.profile.minimap or not ns.db.profile.minimap.datatext then
    --     print("|cFF30D1FFGravityUI:|r Detecting missing Minimap settings... Resetting profile to apply defaults.")
    --     ns.db:ResetProfile()
    -- end

    -- Reset temporary states
    if ns.db.profile.minimap and ns.db.profile.minimap.dungeonEye then
        ns.db.profile.minimap.dungeonEye.preview = false
    end

    -- Disable GravityUI Instance Styling when EllesmereUI is loaded,
    -- because EllesmereUI ships its own instance frame styling and
    -- running both simultaneously causes visual conflicts.
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local idb = ns.db.profile.styling and ns.db.profile.styling.instanceFrames
        if idb and idb.enabled then
            idb.enabled = false
            ns.Print("EllesmereUI detected – |cFFFFFF00Enable Custom Instance Styling|r automatically disabled to avoid conflicts.")
        end
        -- Sync tooltip ownership: if GravityUI's Tooltip Module is on,
        -- immediately disable EllesmereUI's Blizzard Tooltip reskin.
        -- ns.SyncEllesmereTooltip is defined later in this file (in its own
        -- do-block), so we defer one frame to let all do-blocks finish loading.
        C_Timer.After(0, function()
            if ns.SyncEllesmereTooltip     then ns.SyncEllesmereTooltip()     end
            if ns.SyncEllesmereVigorBar    then ns.SyncEllesmereVigorBar()    end
            if ns.SyncEllesmereCharSheet   then ns.SyncEllesmereCharSheet()   end
            if ns.SyncEllesmereAccentColor then ns.SyncEllesmereAccentColor() end
        end)
    end
    
    -- Register for profile change events
    for _, event in ipairs({"OnProfileChanged", "OnProfileCopied", "OnProfileReset"}) do
        ns.db.RegisterCallback(ns, event, function()
            -- Re-apply EllesmereUI compat guard after profile switches too
            if C_AddOns.IsAddOnLoaded("EllesmereUI") then
                local idb = ns.db.profile.styling and ns.db.profile.styling.instanceFrames
                if idb and idb.enabled then
                    idb.enabled = false
                end
                -- Re-sync all EllesmereUI compat states on profile switch
                if ns.SyncEllesmereTooltip     then ns.SyncEllesmereTooltip()     end
                if ns.SyncEllesmereVigorBar    then ns.SyncEllesmereVigorBar()    end
                if ns.SyncEllesmereCharSheet   then ns.SyncEllesmereCharSheet()   end
                if ns.SyncEllesmereAccentColor then ns.SyncEllesmereAccentColor() end
            end

            -- Refresh in-game UI elements (Minimap, Datapanels, Colors, local changes)
            ns.RefreshAccentColors()
            
            -- Refresh GUI if open
            if ns.GUI and ns.GUI.RefreshAll then
                ns.GUI:RefreshAll()
            end
        end)
    end
    
    -- Register slash commands
    self:RegisterChatCommand("gui", "SlashCommandOpen")
    self:RegisterChatCommand("gravityui", "SlashCommandOpen")
    self:RegisterChatCommand("rl", "SlashCommandReload")
    self:RegisterChatCommand("kb", "SlashCommandKeybind")
    self:RegisterChatCommand("guiinstall", "SlashCommandInstall")
    
    ns.Print("loaded. Type |cFFFFFF00/gui|r to open settings.")
    ns.Print("using profile: |cFF00BFFF" .. ns.db:GetCurrentProfile() .. "|r")
    
    -- Character panel module auto-initializes via event registration
end

-- Apply UI Scale from DB
-- If EllesmereUI is loaded we route through PP.SetUIScale() so that
-- EllesmereUIDB.ppUIScale stays in sync and EllesmereUI's pixel-snap
-- callbacks (SnapProfilePositions, ApplyAllWidthHeightMatches, …) fire
-- correctly. Without this EllesmereUI's Startup listener would re-apply
-- its own saved scale on UI_SCALE_CHANGED and overwrite ours.
function ns.ApplyUIScale()
    local db = ns.GetDB()
    if not (db and db.general and db.general.uiScale) then return end
    local targetScale = db.general.uiScale

    -- Route through EllesmereUI when it is available
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local E = _G.EllesmereUI
        if E and E.PP and E.PP.SetUIScale then
            -- PP.SetUIScale handles combat-deferred, UpdateMult,
            -- SnapProfilePositions and ApplyAllWidthHeightMatches internally.
            E.PP.SetUIScale(targetScale)
            -- Also keep EllesmereUIDB aligned so the Startup listener
            -- does not clobber our value after a UI_SCALE_CHANGED event.
            if _G.EllesmereUIDB then
                _G.EllesmereUIDB.ppUIScale = targetScale
                _G.EllesmereUIDB.ppUIScaleAuto = false
            end
            return
        end
        -- EllesmereUI is loaded but PP is not ready yet (very early in boot).
        -- Fall through to direct SetScale and keep EllesmereUIDB in sync.
        if _G.EllesmereUIDB then
            _G.EllesmereUIDB.ppUIScale = targetScale
            _G.EllesmereUIDB.ppUIScaleAuto = false
        end
    end

    -- Vanilla path (EllesmereUI not loaded, or PP not ready yet)
    pcall(function()
        if math.abs(UIParent:GetScale() - targetScale) > 0.001 then
            UIParent:SetScale(targetScale)
        end
    end)
end

-------------------------------------------------------------------------------
-- Combat Text CVar Sync
-- Both GravityUI and EllesmereUI use the same WoW CVars for showing/hiding
-- floating combat damage and healing numbers. By keeping GravityUI's DB aligned
-- with the CVars we get seamless bidirectional sync without touching EllesmereUI.
--
--  GravityUI → WoW/EllesmereUI : ns.ApplyCombatTextSettings() at startup
--  EllesmereUI → GravityUI      : CVAR_UPDATE listener updates the DB
-------------------------------------------------------------------------------

-- Push GravityUI's saved combat-text flags to the WoW CVars.
-- Called at startup so EllesmereUI (and Blizzard) picks up our saved values.
function ns.ApplyCombatTextSettings()
    local db = ns.GetDB()
    if not (db and db.uiimprovements) then return end
    local ui = db.uiimprovements
    if ui.scrollingCombatText ~= nil then
        SetCVar("enableFloatingCombatText",          ui.scrollingCombatText and "1" or "0")
    end
    if ui.showDamageNumbers ~= nil then
        SetCVar("floatingCombatTextCombatDamage_v2",  ui.showDamageNumbers  and "1" or "0")
    end
    if ui.showHealingNumbers ~= nil then
        SetCVar("floatingCombatTextCombatHealing_v2", ui.showHealingNumbers and "1" or "0")
    end
end

-- CVAR_UPDATE: when EllesmereUI (or any source) flips these CVars, mirror the
-- new value back into GravityUI's DB so both sides stay in sync.
do
    local combatCVarFrame = CreateFrame("Frame")
    combatCVarFrame:RegisterEvent("CVAR_UPDATE")
    combatCVarFrame:SetScript("OnEvent", function(_, _, cvarName, value)
        if cvarName ~= "enableFloatingCombatText"
           and cvarName ~= "floatingCombatTextCombatDamage_v2"
           and cvarName ~= "floatingCombatTextCombatHealing_v2" then return end
        local db = ns.GetDB()
        if not (db and db.uiimprovements) then return end
        local enabled = (value == "1")
        if cvarName == "enableFloatingCombatText" then
            db.uiimprovements.scrollingCombatText = enabled
        elseif cvarName == "floatingCombatTextCombatDamage_v2" then
            db.uiimprovements.showDamageNumbers  = enabled
        else
            db.uiimprovements.showHealingNumbers = enabled
        end
    end)
end

ns.RefreshEverything = function()
    ns.ApplyUIScale()
    ns.ApplyCombatTextSettings()
    if ns.Styling then ns.Styling:Refresh() end
    if ns.Media then ns.Media:Update() end
    
    -- Modules
    if ns.Modules then
        for _, module in pairs(ns.Modules) do
            if module.Refresh then
                module:Refresh()
            end
        end
    end
end

-- AceAddon callback - runs after OnInitialize
function Addon:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    if ns.InterruptTracker and ns.InterruptTracker.Initialize then 
        ns.InterruptTracker.Initialize() 
        if ns.InterruptTracker.ApplySettings then ns.InterruptTracker.ApplySettings() end
    end

    if ns.TargetedSpells and ns.TargetedSpells.Initialize then
        ns.TargetedSpells.Initialize()
        if ns.TargetedSpells.ApplySettings then ns.TargetedSpells.ApplySettings() end
    end

    if ns.Consumables and ns.Consumables.Initialize then 
        ns.Consumables.Initialize()
    end
    
    if ns.Mail and ns.Mail.Initialize then
        ns.Mail.Initialize()
        if ns.Mail.ApplySettings then ns.Mail.ApplySettings() end
    end
    
    -- Initial Updates
    ns.RefreshEverything()
    
    -- Initialize Movers
    if ns.Movers and ns.Movers.Initialize then ns.Movers:Initialize() end

    -- Debug Command for Quick Keybind
    _G["SLASH_GUIKB1"] = "/guikb"
    SlashCmdList["GUIKB"] = function()
        ns.Addon:SlashCommandKeybind()
    end
end


-------------------------------------------------------------------------------
-- EllesmereUI – "Managed by GravityUI" label beneath the sidebar logo
--
-- EllesmereUI._sidebar is the sidebar frame (SIDEBAR_W wide, full panel height).
-- The logo area occupies the top ~114 px (NAV_TOP = -114). We place a small
-- FontString centred horizontally, anchored at Y = -95 from the sidebar top,
-- just below the EllesmereUI logo text.
-- The label is created once on the first Show/Toggle and then persists.
-------------------------------------------------------------------------------
do
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local labelCreated = false

        local function PlaceManagedLabel()
            local E = _G.EllesmereUI
            if not (E and E._sidebar) then return end
            if labelCreated then return end
            labelCreated = true

            local sidebar = E._sidebar

            -- Icon texture embedded inline so the whole unit centres as one string
            local GRAV_ICON = "Interface\\AddOns\\GravityUI\\assets\\GRAVITY_UI_Icon.blp"
            local iconTag   = "|T" .. GRAV_ICON .. ":14:14:0:-1|t"

            local lbl = sidebar:CreateFontString(nil, "OVERLAY")
            lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            do local _r,_g,_b = ns.GetAccentColor(); lbl:SetTextColor(_r,_g,_b, 0.90) end
            lbl:SetText("In collaboration with GravityUI  " .. iconTag)
            -- Centre horizontally in the sidebar, just below the EllesmereUI logo
            lbl:SetPoint("TOP", sidebar, "TOP", 0, -95)
            lbl:SetJustifyH("CENTER")
        end

        local E = _G.EllesmereUI
        if E then
            hooksecurefunc(E, "Show",       function() PlaceManagedLabel() end)
            hooksecurefunc(E, "Toggle",     function() PlaceManagedLabel() end)
            hooksecurefunc(E, "ShowModule", function() PlaceManagedLabel() end)

            -- Retry hooking the "Use Blizzard CDM Bars" card each time EUI opens.
            -- The card is built lazily (first visit to Tracking Bars tab), so we
            -- keep retrying until Module:HookBlizzardCard() succeeds.
            local _blizzRetryTicker = nil
            local function TryHookBlizzardCard()
                local mod = ns.TrackedBuffBar
                if not (mod and mod.HookBlizzardCard) then return end
                -- HookBlizzardCard() is safe to call every time – it deduplicates
                -- via the _blizzCardFrame pointer and only re-hooks when EUI has
                -- built a new card frame (e.g. after a page rebuild).
                mod:HookBlizzardCard()
                if mod._blizzCardFrame then
                    -- Card found: stop any pending retry ticker.
                    if _blizzRetryTicker then _blizzRetryTicker:Cancel(); _blizzRetryTicker = nil end
                    return
                end
                -- Card not found yet (Tracking Bars tab not visited) – retry.
                if _blizzRetryTicker then return end  -- already ticking
                local retries = 0
                _blizzRetryTicker = C_Timer.NewTicker(0.5, function()
                    retries = retries + 1
                    mod:HookBlizzardCard()
                    if mod._blizzCardFrame or retries >= 20 then
                        _blizzRetryTicker:Cancel()
                        _blizzRetryTicker = nil
                    end
                end)
            end
            hooksecurefunc(E, "Show",       function() TryHookBlizzardCard() end)
            hooksecurefunc(E, "Toggle",     function() TryHookBlizzardCard() end)
            hooksecurefunc(E, "ShowModule", function() TryHookBlizzardCard() end)
        end
    end
end


-------------------------------------------------------------------------------
-- EllesmereUI – Auto-disable conflicting sub-addons at PLAYER_LOGIN
--
-- When GravityUI manages a feature that EllesmereUI also provides (Chat,
-- Minimap, Action Bars, etc.), the corresponding EllesmereUI sub-addon must be
-- disabled to prevent both systems from running simultaneously and causing
-- conflicts (duplicate frames, double-skinning, event handler clashes).
--
-- C_AddOns.DisableAddOn() writes to WoW's AddOns.txt and takes effect on the
-- NEXT session. If an addon is still loaded in the current session we print a
-- one-time reload prompt.
--
-- Mapping (mirrors the sidebar-hide conditions exactly):
--   Always disabled     : EllesmereUIQoL
--   When GravityUI Chat is enabled      → EllesmereUIChat
--   When GravityUI Minimap is enabled   → EllesmereUIMinimap
--   When GravityUI Tracker styling on   → EllesmereUIQuestTracker
--   When GravityUI Action Bars enabled  → EllesmereUIActionBars
--   When Plater is loaded               → EllesmereUINameplates
--   When Baganator is loaded            → EllesmereUIBags
--   When Details is loaded              → EllesmereUIDamageMeters
--   When WarpDeplete is loaded          → EllesmereUIMythicTimer
-------------------------------------------------------------------------------
do
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local function AutoDisableEllesmereModules()
            local reloadNeeded = false

            -- Disable an EllesmereUI sub-addon if it should not run alongside GravityUI.
            -- Returns true if the addon was still loaded this session (= reload required).
            local function Disable(addonName)
                -- Only act if the addon is actually installed
                local name = C_AddOns.GetAddOnInfo(addonName)
                if not name then return end
                -- Disable for next session
                C_AddOns.DisableAddOn(addonName)
                -- If it's still loaded right now, a reload is needed to fully remove it
                if C_AddOns.IsAddOnLoaded(addonName) then
                    reloadNeeded = true
                end
            end

            -- ---------------------------------------------------------------
            -- Always disabled: GravityUI fully replaces these.
            -- ---------------------------------------------------------------
            Disable("EllesmereUIQoL")

            -- ---------------------------------------------------------------
            -- Conditionally disabled: only when the matching GravityUI
            -- feature is active.
            -- ---------------------------------------------------------------
            local db = ns.GetDB()
            if db then
                -- Chat
                if db.uiimprovements and db.uiimprovements.chat
                   and (db.uiimprovements.chat.enabled ~= false) then
                    Disable("EllesmereUIChat")
                end

                -- Minimap
                if db.minimap and (db.minimap.enabled ~= false) then
                    Disable("EllesmereUIMinimap")
                end

                -- Quest Tracker / Objective Tracker styling
                if db.styling and db.styling.objectives
                   and db.styling.objectives.objectiveTrackerSkinning == true then
                    Disable("EllesmereUIQuestTracker")
                end

                -- Action Bars
                if db.actionbars and (db.actionbars.enabled ~= false) then
                    Disable("EllesmereUIActionBars")
                end

                -- AuraBuff Reminders: disable when GravityUI Missing Buffs is active
                if db.raidBuffs and (db.raidBuffs.enabled ~= false) then
                    Disable("EllesmereUIAuraBuffReminders")
                end
            end

            -- Nameplates: disable EllesmereUINameplates when Plater is loaded,
            -- because Plater fully replaces Blizzard/EllesmereUI nameplates.
            if C_AddOns.IsAddOnLoaded("Plater") then
                Disable("EllesmereUINameplates")
            end

            -- Bags: disable EllesmereUIBags when Baganator is loaded,
            -- because Baganator fully replaces the bag UI.
            if C_AddOns.IsAddOnLoaded("Baganator") then
                Disable("EllesmereUIBags")
            end

            -- Damage Meters: disable EllesmereUIDamageMeters when Details is loaded.
            if C_AddOns.IsAddOnLoaded("Details") then
                Disable("EllesmereUIDamageMeters")
            end

            -- Mythic+ Timer: disable EllesmereUIMythicTimer when WarpDeplete is loaded,
            -- because WarpDeplete fully replaces the Mythic+ timer UI.
            if C_AddOns.IsAddOnLoaded("WarpDeplete") then
                Disable("EllesmereUIMythicTimer")
            end

            -- Notify once if a reload is required to fully remove a module
            if reloadNeeded then
                C_Timer.After(3, function()
                    ns.Print("|cffFFCC00EllesmereUI Integration:|r Conflicting modules have been disabled. Please |cff00CCFF/reload|r to fully apply the changes.")
                end)
            end
        end

        -- Run after all SavedVariables are loaded (PLAYER_LOGIN fires after
        -- all addon OnLoad events and DB initialisation).
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_LOGIN")
        f:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            AutoDisableEllesmereModules()
        end)
    end
end

-------------------------------------------------------------------------------
-- EllesmereUI – Lock "Blizz UI Enhanced" sidebar row when GravityUI is active
--
-- Root problem: EllesmereUI.lua calls CreateMainFrame() lazily on the first
-- EllesmereUI:Show() / :Toggle() / :ShowModule(). Inside CreateMainFrame() the
-- sidebar buttons are built AND EllesmereUI.RefreshSidebarOverrideLocks is
-- (re)defined. A PLAYER_LOGIN hook that patches RefreshSidebarOverrideLocks
-- runs BEFORE CreateMainFrame(), so CreateMainFrame() overwrites our patch on
-- the first panel open.
--
-- Correct strategy:
--  1. Use hooksecurefunc on EllesmereUI.Show / Toggle / ShowModule.
--     hooksecurefunc fires AFTER the original, so by the time our callback
--     runs, CreateMainFrame() has already completed and _sidebarButtons exists.
--  2. In the hook callback, directly manipulate the button's Script handlers
--     and visual properties. We also wrap RefreshSidebarOverrideLocks AT THAT
--     POINT (after it has been created) so future RefreshSidebarStates calls
--     cannot wash out our changes.
--  3. Use a "once" guard so we only patch the scripts once; on subsequent
--     Show/Toggle calls we just call ApplyBlizzSkinLock() to re-assert the
--     visual state (RefreshSidebarStates recolors rows on every panel open).
-------------------------------------------------------------------------------
do
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local LOCK_FOLDER         = "EllesmereUIBlizzardSkin"
        local LOCK_TOOLTIP        = "Managed by GravityUI \226\128\147 Blizz UI styling is handled by GravityUI's Styling module."
        local AURABUFF_FOLDER     = "EllesmereUIAuraBuffReminders"
        local BAGS_FOLDER          = "EllesmereUIBags"
        local CHAT_FOLDER          = "EllesmereUIChat"
        local MINIMAP_FOLDER       = "EllesmereUIMinimap"
        local QUEST_TRACKER_FOLDER = "EllesmereUIQuestTracker"
        local ACTION_BARS_FOLDER   = "EllesmereUIActionBars"
        local NAMEPLATES_FOLDER    = "EllesmereUINameplates"
        local DAMAGE_METERS_FOLDER = "EllesmereUIDamageMeters"
        local MYTHIC_TIMER_FOLDER  = "EllesmereUIMythicTimer"

        -- These buttons are always hidden when EllesmereUI is loaded alongside GravityUI,
        -- because GravityUI fully manages these features.
        local ALWAYS_HIDDEN_FOLDERS = {
            "EllesmereUIQoL",      -- Quality of Life (managed by GravityUI)
        }

        -- NAV colors (mirrored from EllesmereUI.lua file-scope constants)
        local DISABLED_R, DISABLED_G, DISABLED_B, DISABLED_A = 1, 1, 1, 0.11
        local DISABLED_ICON_A = 0.20

        local scriptsPatched = false  -- only replace Script handlers once

        -- Returns true when GravityUI's GUI Chatbox is enabled
        local function IsGravityUIChatEnabled()
            local db = ns.GetDB()
            return db and db.uiimprovements and db.uiimprovements.chat
                       and (db.uiimprovements.chat.enabled ~= false)
        end

        -- Returns true when GravityUI's Minimap is enabled
        local function IsGravityUIMinimapEnabled()
            local db = ns.GetDB()
            return db and db.minimap and (db.minimap.enabled ~= false)
        end

        -- Returns true when GravityUI's Objective Tracker styling is enabled
        -- Full path: ns.db.profile.styling.objectives.objectiveTrackerSkinning
        local function IsGravityUITrackerEnabled()
            local db = ns.GetDB()
            return db and db.styling and db.styling.objectives
                       and (db.styling.objectives.objectiveTrackerSkinning ~= false)
                       and db.styling.objectives.objectiveTrackerSkinning ~= nil
        end

        -- Returns true when GravityUI's Action Bars are enabled
        local function IsGravityUIActionBarsEnabled()
            local db = ns.GetDB()
            return db and db.actionbars and (db.actionbars.enabled ~= false)
        end

        -- Returns true when GravityUI's Missing Buffs (Raid Buff Reminders) is enabled
        local function IsGravityUIAuraBuffEnabled()
            local db = ns.GetDB()
            return db and db.raidBuffs and (db.raidBuffs.enabled ~= false)
        end

        local function ApplyBlizzSkinLock()
            -- Lock removed: Blizz UI Enhanced is accessible for all users.
        end

        -----------------------------------------------------------------------
        -- MakePlaceholder: converts a sidebar button into a "managed by X"
        -- placeholder that is still visible and clickable, but navigates to
        -- the controlling settings panel instead of EllesmereUI's own page.
        --
        -- • btn       – the EllesmereUI sidebar Button frame
        -- • byText    – right-side annotation, e.g. "by GravityUI"
        -- • pageId    – GravityUI page string ID to navigate to (or nil)
        -- • openFn    – optional override callback (used for Plater)
        --
        -- Idempotent: the _isGravityUIPlaceholder flag prevents double-patching
        -- so it is safe to call from the RefreshSidebarOverrideLocks wrapper.
        -----------------------------------------------------------------------
        local function MakePlaceholder(btn, byText, pageId, openFn)
            if not btn or btn._isGravityUIPlaceholder then return end
            btn._isGravityUIPlaceholder = true

            -- Dim the module name to signal "managed externally"
            btn._label:SetTextColor(1, 1, 1, 0.38)

            -- Hide power/sync buttons – irrelevant for managed features
            if btn._pwrBtn  then btn._pwrBtn:Hide()  end
            if btn._syncBtn then btn._syncBtn:Hide() end

            -- Right-aligned "by X" annotation (where the power button was)
            local tag = btn:CreateFontString(nil, "OVERLAY")
            tag:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            if pageId then
                local r, g, b = ns.GetAccentColor()
                tag:SetTextColor(r, g, b, 0.90)
            else
                tag:SetTextColor(0.50, 0.80, 1.00, 0.90)  -- Plater: light blue
            end
            tag:SetText(byText)
            tag:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
            btn._placeholderTag = tag

            -- Click: close EllesmereUI first, then open GravityUI/external addon
            btn:SetScript("OnClick", function()
                -- Close EllesmereUI so GravityUI/Plater/Baganator opens in front
                local E = _G.EllesmereUI
                if E and E.Toggle then
                    pcall(function() E:Toggle() end)
                end

                C_Timer.After(0.05, function()
                    if openFn then
                        openFn()
                    elseif pageId and ns.GUI then
                        ns.GUI:Show()
                        C_Timer.After(0, function() ns.GUI:ShowPage(pageId) end)
                    end
                end)
            end)

            -- Hover: glow + tooltip explaining why it is managed externally
            btn:SetScript("OnEnter", function(self)
                local E = _G.EllesmereUI
                if self._hoverGlow      then self._hoverGlow:Show()      end
                if self._hoverIndicator then self._hoverIndicator:Show() end
                if E and E.ShowWidgetTooltip then
                    local addonLabel = (byText:match("^by (.+)$")) or byText
                    local tip = openFn
                        and ("Managed by " .. addonLabel .. ".\n\nClick to open " .. addonLabel .. " settings.")
                        or  "Managed by GravityUI.\n\nClick to configure in GravityUI."
                    E.ShowWidgetTooltip(self, tip)
                end
            end)

            btn:SetScript("OnLeave", function(self)
                local E = _G.EllesmereUI
                if self._hoverGlow      then self._hoverGlow:Hide()      end
                if self._hoverIndicator then self._hoverIndicator:Hide() end
                if E and E.HideWidgetTooltip then E.HideWidgetTooltip() end
            end)
        end

        -- Chat: managed by GravityUI → navigate to UI Styling (contains Chat tab)
        local function ApplyChatHide()
            if not IsGravityUIChatEnabled() then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[CHAT_FOLDER], "by GravityUI", "Styling")
        end

        -- Minimap: managed by GravityUI → navigate to Minimap page
        local function ApplyMinimapHide()
            if not IsGravityUIMinimapEnabled() then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[MINIMAP_FOLDER], "by GravityUI", "minimap")
        end

        -- Quest Tracker: managed by GravityUI → navigate to UI Styling page
        local function ApplyTrackerHide()
            if not IsGravityUITrackerEnabled() then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[QUEST_TRACKER_FOLDER], "by GravityUI", "Styling")
        end

        -- Action Bars: managed by GravityUI → navigate to Action Bars page
        local function ApplyActionBarsHide()
            if not IsGravityUIActionBarsEnabled() then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[ACTION_BARS_FOLDER], "by GravityUI", "actionbars")
        end

        -- Nameplates: managed by Plater → open Plater directly
        local function ApplyNameplatesHide()
            if not C_AddOns.IsAddOnLoaded("Plater") then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[NAMEPLATES_FOLDER], "by Plater", nil, function()
                if SlashCmdList["PLATER"] then SlashCmdList["PLATER"]("") end
            end)
        end

        -- Bags: managed by Baganator → open Baganator directly
        local function ApplyBagsHide()
            if not C_AddOns.IsAddOnLoaded("Baganator") then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[BAGS_FOLDER], "by Baganator", nil, function()
                if SlashCmdList["Baganator"] then SlashCmdList["Baganator"]("") end
            end)
        end

        -- Mythic+ Timer: managed by WarpDeplete → open WarpDeplete directly
        local function ApplyMythicTimerHide()
            if not C_AddOns.IsAddOnLoaded("WarpDeplete") then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[MYTHIC_TIMER_FOLDER], "by WarpDeplete", nil, function()
                -- Brute-force scan: find any SLASH_*N = "/warp*" and run its handler
                local opened = false
                for k, v in pairs(_G) do
                    if type(k) == "string" and k:match("^SLASH_") and type(v) == "string"
                       and v:lower():match("^/warp") then
                        local key = k:match("^SLASH_(.+)%d+$")
                        if key and SlashCmdList[key] then
                            SlashCmdList[key]("")
                            opened = true
                            break
                        end
                    end
                end
                -- Fallback: call WarpDeplete addon object directly
                if not opened then
                    local WD = _G.WarpDeplete
                    if WD then
                        if WD.ToggleOptions then WD:ToggleOptions()
                        elseif WD.OpenOptions then WD:OpenOptions()
                        elseif WD.Toggle      then WD:Toggle() end
                    end
                end
            end)
        end

        -- Damage Meters: managed by Details → open Details directly
        local function ApplyDamageMetersHide()
            if not C_AddOns.IsAddOnLoaded("Details") then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[DAMAGE_METERS_FOLDER], "by Details", nil, function()
                if SlashCmdList["DETAILS"] then SlashCmdList["DETAILS"]("options")
                elseif _G.Details and _G.Details.Show then _G.Details:Show() end
            end)
        end

        -- AuraBuff Reminders: managed by GravityUI Missing Buffs → navigate to Indicators page
        local function ApplyAuraBuffHide()
            if not IsGravityUIAuraBuffEnabled() then return end
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            MakePlaceholder(E._sidebarButtons[AURABUFF_FOLDER], "by GravityUI", "indicators")
        end

        -- QoL: always managed by GravityUI → show placeholder pointing to GravityUI's QoL page
        local function ApplyAlwaysHidden()
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end
            for _, folder in ipairs(ALWAYS_HIDDEN_FOLDERS) do
                MakePlaceholder(E._sidebarButtons[folder], "deactivated by GravityUI", "qol")
            end
        end

        local function ApplyAllSidebarLocks()
            local E = _G.EllesmereUI
            if not (E and E._sidebarButtons) then return end

            ApplyBlizzSkinLock()
            ApplyAlwaysHidden()
            ApplyChatHide()
            ApplyMinimapHide()
            ApplyTrackerHide()
            ApplyActionBarsHide()
            ApplyNameplatesHide()
            ApplyBagsHide()
            ApplyMythicTimerHide()
            ApplyDamageMetersHide()
            ApplyAuraBuffHide()

            -- Replace Script handlers and wrap RefreshSidebarOverrideLocks only once
            if not scriptsPatched then
                scriptsPatched = true

                -- Wrap RefreshSidebarOverrideLocks so all locks re-assert
                -- after every future RefreshSidebarStates call.
                if E.RefreshSidebarOverrideLocks then
                    local orig = E.RefreshSidebarOverrideLocks
                    E.RefreshSidebarOverrideLocks = function(...)
                        orig(...)
                        ApplyBlizzSkinLock()
                        ApplyAlwaysHidden()
                        ApplyChatHide()
                        ApplyMinimapHide()
                        ApplyTrackerHide()
                        ApplyActionBarsHide()
                        ApplyNameplatesHide()
                        ApplyBagsHide()
                        ApplyMythicTimerHide()
                        ApplyDamageMetersHide()
                        ApplyAuraBuffHide()
                    end
                end
            end
        end


        -- Hook all three entry points that call CreateMainFrame() internally.
        -- hooksecurefunc fires AFTER the original function returns, so
        -- _sidebarButtons is guaranteed to exist by the time we run.
        local E = _G.EllesmereUI
        if E then
            hooksecurefunc(E, "Show",       function() ApplyAllSidebarLocks() end)
            hooksecurefunc(E, "Toggle",     function() ApplyAllSidebarLocks() end)
            hooksecurefunc(E, "ShowModule", function() ApplyAllSidebarLocks() end)
        end
    end
end



-------------------------------------------------------------------------------
-- EllesmereUI – Lock specific Global Settings sliders managed by GravityUI
--
-- GravityUI owns both UI Scale (General → uiScale) and Lag Tolerance
-- (Combat → spellQueueWindow). Allowing users to also change these from
-- EllesmereUI's Global Settings panel creates two-master conflicts.
--
-- Architecture:
--  Layer 1 – Functional wraps (PP.SetUIScale etc.) prevent persistent changes.
--  Layer 2 – Visual overlays cover the relevant half of each DualRow so the
--    controls look disabled and show an explanatory tooltip.
--
-- Frame path (discovered via EllesmereUI source analysis):
--   EllesmereUI._pageCache["_EUIGlobal::General"].wrapper
--     :GetChildren()  →  DualRow frames
--       [i]._leftRegion  or  [i]._rightRegion  →  target half-region
--         ._label:GetText()  ==  locked label text
-------------------------------------------------------------------------------
do
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local GLOBAL_CACHE_KEY = "_EUIGlobal::General"

        -- Each entry: which DualRow half to lock and what tooltip to show.
        -- "side" = "left" | "right"
        local LOCKED_WIDGETS = {
            {
                label   = "UI Scale",
                side    = "left",
                tooltip = "UI Scale is managed by GravityUI \226\128\148 change it under General > UI Scale.",
            },
            {
                label   = "Lag Tolerance",
                side    = "right",
                tooltip = "Lag Tolerance (Spell Queue Window) is managed by GravityUI \226\128\148 change it under Combat > Spell Queue Window.",
            },
        }

        -----------------------------------------------------------------------
        -- Layer 1: Wrap PP.SetUIScale to re-assert GravityUI's value.
        -----------------------------------------------------------------------
        local ppWrapped = false
        local function WrapPPSetUIScale()
            if ppWrapped then return end
            local E = _G.EllesmereUI
            if not (E and E.PP and E.PP.SetUIScale) then return end
            ppWrapped = true
            local origSetUIScale = E.PP.SetUIScale
            E.PP.SetUIScale = function(newScale)
                origSetUIScale(newScale)
                local db = ns.GetDB()
                if db and db.general and db.general.uiScale then
                    local guiScale = db.general.uiScale
                    if math.abs((UIParent:GetScale() or 1) - guiScale) > 0.001 then
                        if _G.EllesmereUIDB then
                            _G.EllesmereUIDB.ppUIScale    = guiScale
                            _G.EllesmereUIDB.ppUIScaleAuto = false
                        end
                        pcall(function() UIParent:SetScale(guiScale) end)
                    end
                end
            end
        end
        do
            local wf = CreateFrame("Frame")
            wf:RegisterEvent("PLAYER_LOGIN")
            wf:SetScript("OnEvent", function(self) self:UnregisterAllEvents(); WrapPPSetUIScale() end)
        end

        -----------------------------------------------------------------------
        -- Layer 2: Visual overlay – mirrors the working Tooltip overlay pattern
        -- exactly (see "Managed by GravityUI overlay for BLIZZARD TOOLTIP" block).
        --
        -- Key insight: SetParent() resets FrameStrata in WoW. The overlay must
        -- re-assert SetFrameStrata + SetFrameLevel on *every* PlaceAllOverlays
        -- call, not just at creation time. That is what makes the Tooltip overlay
        -- work on 2nd+ opens while this one was failing.
        -----------------------------------------------------------------------
        local function GetGeneralWrapper()
            local E = _G.EllesmereUI
            if not (E and E._pageCache) then return nil end
            local entry = E._pageCache[GLOBAL_CACHE_KEY]
            return entry and entry.wrapper or nil
        end

        -- Walk wrapper children and return the region frame (left or right)
        -- whose label text matches, plus the DualRow parent frame.
        local function FindRegion(wrapper, labelText, side)
            if not wrapper then return nil, nil end
            for _, child in next, {wrapper:GetChildren()} do
                local rgn = (side == "right") and child._rightRegion or child._leftRegion
                if rgn and rgn._label then
                    if rgn._label:GetText() == labelText then
                        return rgn, child  -- region, dualrow
                    end
                end
            end
            return nil, nil
        end

        -- One cached overlay per locked widget (keyed by label).
        -- Created once; re-anchored and re-strataed on every open.
        local sliderOverlays = {}
        local sliderHooksInstalled = false

        local function PlaceAllOverlays()
            local wrapper = GetGeneralWrapper()
            if not wrapper then return end

            local E = _G.EllesmereUI

            for _, cfg in ipairs(LOCKED_WIDGETS) do
                local rgn, dualrow = FindRegion(wrapper, cfg.label, cfg.side)
                if rgn and dualrow then

                    -- Create the overlay frame once; reuse it every call.
                    local ov = sliderOverlays[cfg.label]
                    if not ov then
                        ov = CreateFrame("Frame", nil, wrapper)
                        ov:EnableMouse(true)

                        local bg = ov:CreateTexture(nil, "BACKGROUND")
                        bg:SetAllPoints()
                        bg:SetColorTexture(0.02, 0.02, 0.06, 0.82)

                        local lbl = ov:CreateFontString(nil, "OVERLAY")
                        lbl:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                        lbl:SetTextColor(ns.GetAccentColor())
                        lbl:SetText("Managed by GravityUI")
                        lbl:SetPoint("CENTER", ov, "CENTER", 0, 0)

                        local tip = cfg.tooltip
                        ov:SetScript("OnEnter", function(self)
                            if E and E.ShowWidgetTooltip then
                                E.ShowWidgetTooltip(self, tip)
                            end
                        end)
                        ov:SetScript("OnLeave", function()
                            if E and E.HideWidgetTooltip then E.HideWidgetTooltip() end
                        end)

                        sliderOverlays[cfg.label] = ov
                    end

                    -- Re-parent to the current wrapper (may change between opens).
                    -- Then immediately re-assert strata + level:
                    -- SetParent() RESETS FrameStrata in WoW – this was the root
                    -- cause of the "works on 1st open, breaks on 2nd" bug.
                    ov:SetParent(wrapper)
                    ov:SetFrameStrata("DIALOG")
                    ov:SetFrameLevel(200)

                    -- Anchor to cover the full DualRow half (label + slider).
                    ov:ClearAllPoints()
                    if cfg.side == "left" then
                        ov:SetPoint("TOPLEFT",     dualrow, "TOPLEFT",     0, 0)
                        ov:SetPoint("BOTTOMRIGHT", dualrow, "BOTTOM",      0, 0)
                    else
                        ov:SetPoint("TOPLEFT",     dualrow, "TOP",         0, 0)
                        ov:SetPoint("BOTTOMRIGHT", dualrow, "BOTTOMRIGHT", 0, 0)
                    end

                    ov:Show()
                end
            end
        end

        -- Install hooks on PLAYER_LOGIN (mirrors Tooltip overlay pattern).
        local sliderHookFrame = CreateFrame("Frame")
        sliderHookFrame:RegisterEvent("PLAYER_LOGIN")
        sliderHookFrame:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            if sliderHooksInstalled then return end
            local E = _G.EllesmereUI
            if not E then return end
            sliderHooksInstalled = true
            -- C_Timer.After(0) is sufficient – page-cache is populated synchronously
            -- by PP.Point during buildPage; no render pass is needed.
            local function Schedule() C_Timer.After(0, PlaceAllOverlays) end
            hooksecurefunc(E, "Show",         Schedule)
            hooksecurefunc(E, "Toggle",       Schedule)
            hooksecurefunc(E, "ShowModule",   Schedule)
            hooksecurefunc(E, "SelectModule", Schedule)
            -- SelectPage fires when the user clicks a tab inside a module;
            -- it actually builds + caches the page, so it must be hooked too.
            if E.SelectPage then
                hooksecurefunc(E, "SelectPage", Schedule)
            end
        end)

        -- Debug slash: /guisliderdbg
        SLASH_GUISLIDERDBG1 = "/guisliderdbg"
        SlashCmdList["GUISLIDERDBG"] = function()
            local E = _G.EllesmereUI
            if not E then print("EllesmereUI not loaded"); return end
            print("GLOBAL_CACHE_KEY = " .. GLOBAL_CACHE_KEY)
            local cache = E._pageCache
            if not cache then print("_pageCache is nil"); return end
            local found = {}
            for k in pairs(cache) do found[#found+1] = k end
            table.sort(found)
            print("Cache keys (" .. #found .. "):")
            for _, k in ipairs(found) do print("  " .. k) end
            local entry = cache[GLOBAL_CACHE_KEY]
            local wrapper = entry and entry.wrapper
            print("Wrapper: " .. tostring(wrapper))
            if wrapper then
                local children = {wrapper:GetChildren()}
                print("Children: " .. #children)
                for i, ch in ipairs(children) do
                    local lr = ch._leftRegion
                    local rr = ch._rightRegion
                    local lt = (lr and lr._label and lr._label:GetText()) or "?"
                    local rt = (rr and rr._label and rr._label:GetText()) or "?"
                    print(string.format("  [%d] L=%q  R=%q", i, lt, rt))
                end
            end
            print("sliderOverlays:")
            for k, ov in pairs(sliderOverlays) do
                print(string.format("  [%s] strata=%s lvl=%d shown=%s",
                    k, ov:GetFrameStrata(), ov:GetFrameLevel(), tostring(ov:IsShown())))
            end
        end
    end
end


-------------------------------------------------------------------------------
-- ns.SyncEllesmereTooltip – always defined (even without EllesmereUI)
-- so pages/styling.lua can call it unconditionally from RefreshTooltip().
-- When GravityUI's Tooltip Module is on and EllesmereUI is loaded, this
-- writes EllesmereUIDB.customTooltips = false to prevent dual-tooltip conflicts.
-------------------------------------------------------------------------------
do
    local function IsGravityUITooltipEnabled()
        local db = ns.GetDB()
        if not db then return false end
        local tt = db.uiimprovements and db.uiimprovements.tooltip
        return tt and (tt.enabled ~= false)
    end

    ns.SyncEllesmereTooltip = function()
        if not C_AddOns.IsAddOnLoaded("EllesmereUI") then return end
        if not IsGravityUITooltipEnabled() then return end
        if _G.EllesmereUIDB and _G.EllesmereUIDB.customTooltips ~= false then
            _G.EllesmereUIDB.customTooltips = false
            local E = _G.EllesmereUI
            if E and E.SyncAuraTooltipSkin then E.SyncAuraTooltipSkin() end
        end
    end
end

-------------------------------------------------------------------------------
-- ns.SyncEllesmereVigorBar – always defined (even without EllesmereUI).
-- When GravityUI's Vigor Bar is on and EllesmereUI is loaded, this writes
-- EllesmereUIDB.profiles[activeProfile].addons.EllesmereUIDragonRiding.enabled
-- = false to prevent the two skyriding HUDs running simultaneously.
-------------------------------------------------------------------------------
do
    ns.SyncEllesmereVigorBar = function()
        if not C_AddOns.IsAddOnLoaded("EllesmereUI") then return end
        local db = ns.GetDB()
        if not db then return end
        local skyEnabled = db.skyriding and (db.skyriding.enabled ~= false)
        if not skyEnabled then return end
        if not _G.EllesmereUIDB then return end
        local profileName = _G.EllesmereUIDB.activeProfile or "Default"
        local profiles = _G.EllesmereUIDB.profiles
        if not profiles or not profiles[profileName] then return end
        local addons = profiles[profileName].addons
        if not addons then return end
        if not addons["EllesmereUIDragonRiding"] then
            addons["EllesmereUIDragonRiding"] = {}
        end
        if addons["EllesmereUIDragonRiding"].enabled ~= false then
            addons["EllesmereUIDragonRiding"].enabled = false
            -- _EDR_Rebuild is a global exported by EllesmereUIBlizzardSkin_DragonRiding.lua.
            -- It triggers a runtime rebuild so the HUD hides immediately.
            if _G._EDR_Rebuild then _G._EDR_Rebuild() end
        end
    end
end

-------------------------------------------------------------------------------
-- ns.SyncEllesmereCharSheet – always defined (even without EllesmereUI).
-- When GravityUI's Character Panel Styling is on and EllesmereUI is loaded,
-- this writes EllesmereUIDB.themedCharacterSheet = false (and themedInspectSheet)
-- so EllesmereUI's Character Sheet reskin doesn't conflict with GravityUI's.
-------------------------------------------------------------------------------
do
    ns.SyncEllesmereCharSheet = function()
        if not C_AddOns.IsAddOnLoaded("EllesmereUI") then return end
        local db = ns.GetDB()
        if not db then return end
        local charEnabled = db.uiimprovements and db.uiimprovements.character and
                            (db.uiimprovements.character.enabled ~= false)
        if not charEnabled then return end
        if not _G.EllesmereUIDB then return end
        if _G.EllesmereUIDB.themedCharacterSheet ~= false then
            _G.EllesmereUIDB.themedCharacterSheet = false
            _G.EllesmereUIDB.themedInspectSheet   = false
            local E = _G.EllesmereUI
            -- Trigger a widget refresh so the dropdown re-reads the DB value.
            if E and E.RefreshWidgets then E:RefreshWidgets() end
        end
    end
end

-------------------------------------------------------------------------------
-- ns.SyncEllesmereAccentColor – always defined (even without EllesmereUI).
-- Mirrors GravityUI's current resolved accent color (custom or class) into
-- EllesmereUI's per-profile euiAccent so both UIs stay visually consistent.
--
-- Uses EllesmereUI.SetActiveProfileAccent + ApplyAccentColorLive when the
-- Widgets module is loaded (i.e. after the EllesmereUI settings panel has
-- been opened once). Falls back to a direct SavedVariables write + live
-- ELLESMERE_GREEN update otherwise.
-------------------------------------------------------------------------------
do
    ns.SyncEllesmereAccentColor = function()
        if not C_AddOns.IsAddOnLoaded("EllesmereUI") then return end
        local E = _G.EllesmereUI
        if not E then return end

        -- Resolve the current GravityUI accent (handles class-color mode internally).
        local r, g, b = ns.GetAccentColor()
        local db = ns.GetDB()
        local useClass = db and db.general and (db.general.useClassColorTheme == true)

        -- High-level API is available once EllesmereUI_Widgets.lua has been
        -- EnsureLoaded (i.e. the settings panel was opened at least once).
        if E.SetActiveProfileAccent and E.ApplyAccentColorLive then
            E.SetActiveProfileAccent(
                useClass and nil or { r = r, g = g, b = b },
                useClass
            )
            E.ApplyAccentColorLive(r, g, b)
            return
        end

        -- Fallback: write directly into the SavedVariables profile table
        -- and update ELLESMERE_GREEN so the color takes effect live even
        -- without the Widgets module being loaded yet.
        local edb = _G.EllesmereUIDB
        if not edb then return end
        local profileName = edb.activeProfile or "Default"
        edb.profiles = edb.profiles or {}
        local p = edb.profiles[profileName]
        if not p then p = {}; edb.profiles[profileName] = p end
        p.euiAccent = p.euiAccent or {}
        p.euiAccent.useClass = useClass
        if not useClass then
            p.euiAccent.custom = { r = r, g = g, b = b }
        end
        -- Live update: ELLESMERE_GREEN is the shared accent table that all
        -- EllesmereUI modules read from for tinting.
        local EG = E.ELLESMERE_GREEN
        if EG then EG.r, EG.g, EG.b = r, g, b end
    end
end

-------------------------------------------------------------------------------
-- EllesmereUI – "Managed by GravityUI" overlay for the BLIZZARD TOOLTIP
-- section inside Blizz UI Enhanced → Tooltips, Menus & Popups.
--
-- Architecture (same as the Global Settings UI Scale overlay above):
--   • PLAYER_LOGIN: hooksecurefunc EllesmereUI.Show/Toggle/ShowModule/SelectModule
--     (deferred to PLAYER_LOGIN so all EllesmereUI functions are guaranteed
--     to exist; the sidebar-lock block above works the same way at file-load
--     time only because EllesmereUI is loaded before GravityUI in that run).
--   • PlaceTooltipOverlay() fires C_Timer.After(0) deferred so the page
--     cache is populated before we read it.
--   • Header detected via frame._isSectionHeader + frame._sectionName
--     (EllesmereUI_Widgets.lua WidgetFactory:SectionHeader sets both).
--   • Overlay sized from section-header bottom to wrapper bottom.
-------------------------------------------------------------------------------
do
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local TOOLTIP_CACHE_KEY   = "EllesmereUIBlizzardSkin::Tooltips, Menus & Popups"
        local TOOLTIP_SECTION_KEY = "BLIZZARD TOOLTIP"   -- frame._sectionName value
        local tooltipSectionOverlay = nil  -- single frame, reused across page rebuilds
        local hooksInstalled = false

        local function IsGravityUITooltipEnabled()
            local db = ns.GetDB()
            if not db then return false end
            local tt = db.uiimprovements and db.uiimprovements.tooltip
            return tt and (tt.enabled ~= false)
        end

        -- Returns the wrapper frame for the Tooltips page (or nil if not built yet)
        local function GetTooltipsWrapper()
            local E = _G.EllesmereUI
            if not (E and E._pageCache) then return nil end
            local entry = E._pageCache[TOOLTIP_CACHE_KEY]
            return entry and entry.wrapper or nil
        end

        -- Scan wrapper children for the SectionHeader whose _sectionName matches.
        -- EllesmereUI_Widgets.lua WidgetFactory:SectionHeader sets:
        --   frame._isSectionHeader = true
        --   frame._sectionName     = text  (raw English key, before L() translation)
        local function FindTooltipSectionHeader(wrapper)
            if not wrapper then return nil end
            for _, child in next, {wrapper:GetChildren()} do
                if child._isSectionHeader and child._sectionName == TOOLTIP_SECTION_KEY then
                    return child
                end
            end
            return nil
        end

        local function PlaceTooltipOverlay()
            ns.SyncEllesmereTooltip()

            local E = _G.EllesmereUI
            if not E then return end

            if not IsGravityUITooltipEnabled() then
                if tooltipSectionOverlay then tooltipSectionOverlay:Hide() end
                return
            end

            local wrapper = GetTooltipsWrapper()
            if not wrapper then return end

            local header = FindTooltipSectionHeader(wrapper)
            if not header then return end

            if not tooltipSectionOverlay then
                tooltipSectionOverlay = CreateFrame("Frame", nil, wrapper)
                tooltipSectionOverlay:EnableMouse(true)
                tooltipSectionOverlay:SetFrameStrata("DIALOG")
                tooltipSectionOverlay:SetFrameLevel(200)

                local bg = tooltipSectionOverlay:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.02, 0.02, 0.06, 0.82)

                local lbl = tooltipSectionOverlay:CreateFontString(nil, "OVERLAY")
                lbl:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
                lbl:SetTextColor(ns.GetAccentColor())  -- GravityUI accent
                lbl:SetText("Managed by GravityUI")
                lbl:SetPoint("CENTER", tooltipSectionOverlay, "CENTER", 0, 10)

                local sub = tooltipSectionOverlay:CreateFontString(nil, "OVERLAY")
                sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                sub:SetTextColor(0.75, 0.75, 0.75, 1)
                sub:SetText("Change it under UI Styling > Tooltip")
                sub:SetPoint("TOP", lbl, "BOTTOM", 0, -5)

                tooltipSectionOverlay:SetScript("OnEnter", function(self)
                    if E and E.ShowWidgetTooltip then
                        E.ShowWidgetTooltip(self,
                            "This section is managed by GravityUI.\n" ..
                            "To configure tooltips, open GravityUI (|cffFFCC00/gui|r)\n" ..
                            "and go to |cffFFCC00UI Styling > Tooltip|r.")
                    end
                end)
                tooltipSectionOverlay:SetScript("OnLeave", function()
                    if E and E.HideWidgetTooltip then E.HideWidgetTooltip() end
                end)
            end

            -- Two-anchor stretch: no coordinate math needed at all.
            -- TOPLEFT snaps to the section header's bottom-left edge.
            -- BOTTOMRIGHT snaps to the wrapper's bottom-right corner.
            -- Re-assert strata/level every call: SetParent can reset them in WoW,
            -- which caused the overlay to be behind content frames on 2nd+ opens.
            tooltipSectionOverlay:SetParent(wrapper)
            tooltipSectionOverlay:SetFrameStrata("DIALOG")
            tooltipSectionOverlay:SetFrameLevel(200)
            tooltipSectionOverlay:ClearAllPoints()
            tooltipSectionOverlay:SetPoint("TOPLEFT",    header,  "BOTTOMLEFT",  0, 0)
            tooltipSectionOverlay:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)
            tooltipSectionOverlay:Show()
        end




        -- Install hooks on PLAYER_LOGIN to guarantee all EllesmereUI functions exist.
        local hookFrame = CreateFrame("Frame")
        hookFrame:RegisterEvent("PLAYER_LOGIN")
        hookFrame:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            if hooksInstalled then return end
            local E = _G.EllesmereUI
            if not E then return end
            hooksInstalled = true
            -- Single C_Timer.After(0) is sufficient: GetPoint values are set
            -- synchronously by PP.Point during buildPage (no render pass needed).
            local function Schedule() C_Timer.After(0, PlaceTooltipOverlay) end
            hooksecurefunc(E, "Show",         Schedule)
            hooksecurefunc(E, "Toggle",       Schedule)
            hooksecurefunc(E, "ShowModule",   Schedule)
            hooksecurefunc(E, "SelectModule", Schedule)
            -- SelectPage is called when the user clicks a page TAB within a module
            -- (e.g. "Tooltips, Menus & Popups" tab in Blizz UI Enhanced).
            -- This is the function that actually builds + caches the page, so it
            -- MUST be hooked – SelectModule only handles sidebar MODULE clicks.
            if E.SelectPage then
                hooksecurefunc(E, "SelectPage", Schedule)
            end
        end)

        -- Debug slash command: /guitooltipdbg
        -- Prints cache key, wrapper state, and header scan results to chat.
        SLASH_GUITOOLTIPDBG1 = "/guitooltipdbg"
        SlashCmdList["GUITOOLTIPDBG"] = function()
            local E = _G.EllesmereUI
            if not E then print("EllesmereUI not loaded"); return end
            print("GravityUI Tooltip enabled: " .. tostring(IsGravityUITooltipEnabled()))
            local cache = E._pageCache
            if cache then
                local found = {}
                for k in pairs(cache) do found[#found+1] = k end
                table.sort(found)
                print("Cache keys (" .. #found .. "):")
                for _, k in ipairs(found) do print("  " .. k) end
            else
                print("_pageCache is nil")
            end
            local wrapper = GetTooltipsWrapper()
            print("Wrapper: " .. tostring(wrapper))
            if wrapper then
                local children = {wrapper:GetChildren()}
                print("Children: " .. #children)
                for i, ch in ipairs(children) do
                    if ch._isSectionHeader then
                        print("  SectionHeader [" .. i .. "] _sectionName=" .. tostring(ch._sectionName))
                    end
                end
                local hdr = FindTooltipSectionHeader(wrapper)
                print("Header found: " .. tostring(hdr))
            end
        end
    end
end

-------------------------------------------------------------------------------
-- EllesmereUI – "Managed by GravityUI" overlay for the GENERAL section
-- inside Blizz UI Enhanced → Dragon Riding.
--
-- When GravityUI's Vigor Bar (Features > Dragonriding > Enable Vigor Bar) is
-- enabled, EllesmereUI's Dragon Riding bar is disabled via SyncEllesmereVigorBar
-- and this overlay locks the Dragon Riding settings page so the user cannot
-- re-enable it through EllesmereUI.
-------------------------------------------------------------------------------
do
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local DR_CACHE_KEY   = "EllesmereUIBlizzardSkin::Dragon Riding"
        local DR_SECTION_KEY = "GENERAL"   -- frame._sectionName value
        local drSectionOverlay = nil
        local drHooksInstalled = false

        local function IsGravityUIVigorBarEnabled()
            local db = ns.GetDB()
            if not db then return false end
            return db.skyriding and (db.skyriding.enabled ~= false)
        end

        local function GetDragonRidingWrapper()
            local E = _G.EllesmereUI
            if not (E and E._pageCache) then return nil end
            local entry = E._pageCache[DR_CACHE_KEY]
            return entry and entry.wrapper or nil
        end

        local function FindDrGeneralHeader(wrapper)
            if not wrapper then return nil end
            for _, child in next, {wrapper:GetChildren()} do
                if child._isSectionHeader and child._sectionName == DR_SECTION_KEY then
                    return child
                end
            end
            return nil
        end

        local function PlaceDragonRidingOverlay()
            ns.SyncEllesmereVigorBar()

            local E = _G.EllesmereUI
            if not E then return end

            if not IsGravityUIVigorBarEnabled() then
                if drSectionOverlay then drSectionOverlay:Hide() end
                return
            end

            local wrapper = GetDragonRidingWrapper()
            if not wrapper then return end

            local header = FindDrGeneralHeader(wrapper)
            if not header then return end

            if not drSectionOverlay then
                drSectionOverlay = CreateFrame("Frame", nil, wrapper)
                drSectionOverlay:EnableMouse(true)
                drSectionOverlay:SetFrameStrata("DIALOG")
                drSectionOverlay:SetFrameLevel(200)

                local bg = drSectionOverlay:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.02, 0.02, 0.06, 0.82)

                local lbl = drSectionOverlay:CreateFontString(nil, "OVERLAY")
                lbl:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
                lbl:SetTextColor(ns.GetAccentColor())  -- GravityUI accent
                lbl:SetText("Managed by GravityUI")
                lbl:SetPoint("CENTER", drSectionOverlay, "CENTER", 0, 10)

                local sub = drSectionOverlay:CreateFontString(nil, "OVERLAY")
                sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                sub:SetTextColor(0.75, 0.75, 0.75, 1)
                sub:SetText("Change it under Features > Dragonriding")
                sub:SetPoint("TOP", lbl, "BOTTOM", 0, -5)

                drSectionOverlay:SetScript("OnEnter", function(self)
                    if E and E.ShowWidgetTooltip then
                        E.ShowWidgetTooltip(self,
                            "This section is managed by GravityUI.\n" ..
                            "To configure the Dragonriding HUD, open GravityUI (|cffFFCC00/gui|r)\n" ..
                            "and go to |cffFFCC00Features > Dragonriding|r.")
                    end
                end)
                drSectionOverlay:SetScript("OnLeave", function()
                    if E and E.HideWidgetTooltip then E.HideWidgetTooltip() end
                end)
            end

            -- Two-anchor stretch (same pattern as Tooltip overlay):
            -- Re-assert strata/level every call – SetParent can reset them.
            drSectionOverlay:SetParent(wrapper)
            drSectionOverlay:SetFrameStrata("DIALOG")
            drSectionOverlay:SetFrameLevel(200)
            drSectionOverlay:ClearAllPoints()
            drSectionOverlay:SetPoint("TOPLEFT",    header,  "BOTTOMLEFT",  0, 0)
            drSectionOverlay:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 0, 0)
            drSectionOverlay:Show()
        end

        -- Install hooks on PLAYER_LOGIN.
        local drHookFrame = CreateFrame("Frame")
        drHookFrame:RegisterEvent("PLAYER_LOGIN")
        drHookFrame:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            if drHooksInstalled then return end
            local E = _G.EllesmereUI
            if not E then return end
            drHooksInstalled = true
            local function DrSchedule() C_Timer.After(0, PlaceDragonRidingOverlay) end
            hooksecurefunc(E, "Show",         DrSchedule)
            hooksecurefunc(E, "Toggle",       DrSchedule)
            hooksecurefunc(E, "ShowModule",   DrSchedule)
            hooksecurefunc(E, "SelectModule", DrSchedule)
            if E.SelectPage then
                hooksecurefunc(E, "SelectPage", DrSchedule)
            end
        end)
    end
end

-------------------------------------------------------------------------------
-- EllesmereUI – "Managed by GravityUI" overlay for the Character Sheet window
-- card inside Blizz UI Enhanced → Blizzard Window Skins.
--
-- When GravityUI's Character Panel Styling is enabled, EllesmereUI's Character
-- Sheet reskin is disabled via SyncEllesmereCharSheet and this overlay locks
-- the window card row so the user cannot re-enable it through EllesmereUI.
--
-- The window card header has _isSectionHeader = true and
-- _sectionName = "Character Sheet <desc>" (title .. " " .. desc),
-- so we find it with a prefix search and use SetAllPoints to cover exactly
-- the card header row (not the entire page).
-------------------------------------------------------------------------------
do
    if C_AddOns.IsAddOnLoaded("EllesmereUI") then
        local CS_CACHE_KEY = "EllesmereUIBlizzardSkin::Blizzard Window Skins"
        local csOverlay = nil
        local csHooksInstalled = false

        local function IsGravityUICharPanelEnabled()
            local db = ns.GetDB()
            if not db then return false end
            return db.uiimprovements and db.uiimprovements.character and
                   (db.uiimprovements.character.enabled ~= false)
        end

        local function GetWindowSkinsWrapper()
            local E = _G.EllesmereUI
            if not (E and E._pageCache) then return nil end
            local entry = E._pageCache[CS_CACHE_KEY]
            return entry and entry.wrapper or nil
        end

        local function FindCharSheetCard(wrapper)
            if not wrapper then return nil end
            for _, child in next, {wrapper:GetChildren()} do
                -- Window cards set _isSectionHeader = true and _sectionName = title .. " " .. desc
                if child._isSectionHeader and child._sectionName and
                   child._sectionName:find("^Character Sheet") then
                    return child
                end
            end
            return nil
        end

        local function PlaceCharSheetOverlay()
            ns.SyncEllesmereCharSheet()

            local E = _G.EllesmereUI
            if not E then return end

            if not IsGravityUICharPanelEnabled() then
                if csOverlay then csOverlay:Hide() end
                return
            end

            local wrapper = GetWindowSkinsWrapper()
            if not wrapper then return end

            local card = FindCharSheetCard(wrapper)
            if not card then return end

            if not csOverlay then
                csOverlay = CreateFrame("Frame", nil, card)
                csOverlay:EnableMouse(true)
                csOverlay:SetFrameStrata("DIALOG")
                csOverlay:SetFrameLevel(200)

                local bg = csOverlay:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.02, 0.02, 0.06, 0.82)

                local lbl = csOverlay:CreateFontString(nil, "OVERLAY")
                lbl:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
                lbl:SetTextColor(ns.GetAccentColor())  -- GravityUI accent
                lbl:SetText("Managed by GravityUI")
                lbl:SetPoint("CENTER", csOverlay, "CENTER", 0, 8)

                local sub = csOverlay:CreateFontString(nil, "OVERLAY")
                sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                sub:SetTextColor(0.75, 0.75, 0.75, 1)
                sub:SetText("Change it under UI Styling > Character Panel")
                sub:SetPoint("TOP", lbl, "BOTTOM", 0, -4)

                csOverlay:SetScript("OnEnter", function(self)
                    if E and E.ShowWidgetTooltip then
                        E.ShowWidgetTooltip(self,
                            "This section is managed by GravityUI.\n" ..
                            "To configure the Character Panel, open GravityUI (|cffFFCC00/gui|r)\n" ..
                            "and go to |cffFFCC00UI Styling > Character Panel|r.")
                    end
                end)
                csOverlay:SetScript("OnLeave", function()
                    if E and E.HideWidgetTooltip then E.HideWidgetTooltip() end
                end)
            end

            -- Cover the card header row exactly.
            -- Re-assert strata/level every call: SetParent can reset them.
            csOverlay:SetParent(card)
            csOverlay:SetFrameStrata("DIALOG")
            csOverlay:SetFrameLevel(card:GetFrameLevel() + 20)
            csOverlay:ClearAllPoints()
            csOverlay:SetAllPoints(card)
            csOverlay:Show()
        end

        -- Install hooks on PLAYER_LOGIN.
        local csHookFrame = CreateFrame("Frame")
        csHookFrame:RegisterEvent("PLAYER_LOGIN")
        csHookFrame:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            if csHooksInstalled then return end
            local E = _G.EllesmereUI
            if not E then return end
            csHooksInstalled = true
            local function CsSchedule() C_Timer.After(0, PlaceCharSheetOverlay) end
            hooksecurefunc(E, "Show",         CsSchedule)
            hooksecurefunc(E, "Toggle",       CsSchedule)
            hooksecurefunc(E, "ShowModule",   CsSchedule)
            hooksecurefunc(E, "SelectModule", CsSchedule)
            if E.SelectPage then
                hooksecurefunc(E, "SelectPage", CsSchedule)
            end
        end)
    end
end




function Addon:SlashCommandOpen(input)
    input = input and input:lower():trim() or ""
    
    if input == "editmode" then
        if SlashCmdList["EDITMODE"] then
            SlashCmdList["EDITMODE"]("")
        elseif EditModeManagerFrame then
            ShowUIPanel(EditModeManagerFrame)
        end
        return
    end
    
    if input == "cdm" then
        -- Toggle Cooldown Settings
        if CooldownViewerSettings then
            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
        else
            ns.Print("Cooldown Settings not available.")
        end
        return
    end
    
    -- Default: Open GUI
    if ns.GUI then
        ns.GUI:Toggle()
    else
        ns.Print("GUI not loaded yet. Try again in a moment.")
    end
end

-- Reload UI command
function Addon:SlashCommandReload()
    ReloadUI()
end

-- Open the Setup Wizard on demand (/guiinstall)
-- Works even if setupDone is already set – useful for re-running setup.
function Addon:SlashCommandInstall()
    if ns.GUI and ns.GUI.Wizard and ns.GUI.Wizard.Show then
        ns.GUI.Wizard:Show()
    else
        ns.Print("Setup Wizard not available.")
    end
end

-- Toggle Quick Keybind Mode
function Addon:SlashCommandKeybind()
    if not C_AddOns.IsAddOnLoaded("Blizzard_QuickKeybind") then
        C_AddOns.LoadAddOn("Blizzard_QuickKeybind")
    end
    
    if QuickKeybindFrame then
        if QuickKeybindFrame:IsShown() then
            HideUIPanel(QuickKeybindFrame)
        else
            ShowUIPanel(QuickKeybindFrame)
            
            -- Inject Custom Save & Exit Button
            if not QuickKeybindFrame.GravityUISaveExit then
                local btn = CreateFrame("Button", "GravityUI_QuickKeybind_SaveExit", QuickKeybindFrame, "UIPanelButtonTemplate")
                QuickKeybindFrame.GravityUISaveExit = btn
                btn:SetText("Save & Exit")
                btn:SetSize(140, 30)
                -- Position it below the frame to avoid overlapping the checkbox
                btn:SetPoint("TOP", QuickKeybindFrame, "BOTTOM", 0, -10) 
                
                btn:SetScript("OnClick", function()
                     -- 1. Trigger the standard "Okay" (Save) logic
                     if QuickKeybindFrame.okayButton then
                         QuickKeybindFrame.okayButton:Click()
                     elseif QuickKeybindFrame.OkayButton then
                         QuickKeybindFrame.OkayButton:Click()
                     end
                     
                     -- 2. Force Close the QuickKeybindFrame itself (in case click didn't)
                     HideUIPanel(QuickKeybindFrame)
                     
                     -- 3. Close Parent Menus (Settings / Game Menu) to return to game
                     if SettingsPanel and SettingsPanel:IsShown() then 
                        HideUIPanel(SettingsPanel) 
                     end
                     if GameMenuFrame and GameMenuFrame:IsShown() then 
                        HideUIPanel(GameMenuFrame) 
                     end
                end)
            end
        end
    end
end

-- Event handler

-- Event handler
function Addon:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
    -- Initialize custom datapanels
    if ns.Datapanels and ns.Datapanels.Init then ns.Datapanels:Init() end
    if ns.Styling and ns.Styling.Initialize then ns.Styling:Initialize() end
    
    -- CHUNK 1: +0.5 Seconds (ActionBars, PlayerFrames, etc.)
    C_Timer.After(0.5, function()
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    
    -- CHUNK 2: +1.0 Seconds (Loot, Combat Helpers, Raid Warnings)
    C_Timer.After(1.0, function()
        if ns.Loot and ns.Loot.Initialize then ns.Loot:Initialize() end
        if ns.RaidWarnings and ns.RaidWarnings.Initialize then ns.RaidWarnings:Initialize() end
        if ns.InterruptTracker and ns.InterruptTracker.Initialize then ns.InterruptTracker:Initialize() end
        if ns.TargetedSpells and ns.TargetedSpells.Initialize then ns.TargetedSpells:Initialize() end
        if ns.TrackedBuffBar and ns.TrackedBuffBar.Init then ns.TrackedBuffBar:Init() end
    end)
    
    -- CHUNK 3: +1.5 Seconds (Secondary Systems, Objectives, XP)
    C_Timer.After(1.5, function()
        if ns.Objectives and ns.Objectives.Initialize then ns.Objectives:Initialize() end
        if ns.XPRep and ns.XPRep.Initialize then ns.XPRep:Initialize() end
        if ns.Mail and ns.Mail.Initialize then ns.Mail.Initialize() end
    end)


    

    

end

-- Out of Combat Queue System
ns.OOCQueue = {}

function ns.QueueOOCAction(func)
    if not InCombatLockdown() then
        func()
    else
        table.insert(ns.OOCQueue, func)
    end
end

-- Process OOC Queue
local function ProcessOOCQueue()
    if InCombatLockdown() then return end
    
    for i = #ns.OOCQueue, 1, -1 do
        local func = table.remove(ns.OOCQueue, i)
        if func then
            pcall(func)
        end
    end
end

local oocFrame = CreateFrame("Frame")
oocFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
oocFrame:SetScript("OnEvent", ProcessOOCQueue)

-- Addon Compartment Functions (for addon button in minimap area)
function GravityUI_CompartmentClick()
    if ns.GUI then
        ns.GUI:Toggle()
    end
end

local GameTooltip = GameTooltip
function GravityUI_CompartmentOnEnter(self, button)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(type(self) ~= "string" and self or button, "ANCHOR_LEFT")
    GameTooltip:AddLine("GravityUI" .. ns.VERSION)
    GameTooltip:AddLine("Left-click to open settings")
    GameTooltip:Show()
end

function GravityUI_CompartmentOnLeave()
    GameTooltip:Hide()
end

-- Additional slash commands for convenience
SLASH_GUICDM1 = "/cdm"
SlashCmdList["GUICDM"] = function()
    if CooldownViewerSettings then
        CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
    else
        ns.Print("Cooldown Settings not available.")
    end
end

SLASH_GUIEDIT1 = "/edit"
SlashCmdList["GUIEDIT"] = function(msg)
    if SlashCmdList["EDITMODE"] then
        SlashCmdList["EDITMODE"](msg)
    elseif EditModeManagerFrame then
        ShowUIPanel(EditModeManagerFrame)
    end
end

-- Debug command to export current settings for defaults.lua
SLASH_GUIEXPORT1 = "/gui"
SlashCmdList["GUIEXPORT"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    
    if cmd == "exportdefaults" then
        if not ViragDevTool_AddData then
            -- Fallback serialization
             local LibSerialize = LibStub("LibSerialize", true) -- Optional if available
             -- Basic print for now
             ns.Print("Exporting defaults...")
             
             -- Create a frame to hold the text
             local f = CreateFrame("Frame", "GUIExportFrame", UIParent)
             f:SetSize(600, 500)
             f:SetPoint("CENTER")
             f:SetFrameStrata("DIALOG")
             
             local t = f:CreateTexture(nil, "BACKGROUND")
             t:SetAllPoints()
             t:SetColorTexture(0, 0, 0, 0.9)
             
             local s = CreateFrame("ScrollFrame", "GUIExportScroll", f, "UIPanelScrollFrameTemplate")
             s:SetPoint("TOPLEFT", 10, -10)
             s:SetPoint("BOTTOMRIGHT", -30, 40)
             
             local eb = CreateFrame("EditBox", nil, s)
             eb:SetMultiLine(true)
             eb:SetFontObject(ChatFontNormal)
             eb:SetWidth(560)
             eb:SetScript("OnEscapePressed", function() f:Hide() end)
             
             s:SetScrollChild(eb)
             
             local function DumpTable(tbl, indent)
                 if not indent then indent = 0 end
                 local toprint = string.rep(" ", indent) .. "{\n"
                 indent = indent + 4 
                 for k, v in pairs(tbl) do
                     toprint = toprint .. string.rep(" ", indent)
                     if (type(k) == "number") then
                         toprint = toprint .. "[" .. k .. "] = "
                     elseif (type(k) == "string") then
                         toprint = toprint .. k .. " = " 
                     end
                     
                     if (type(v) == "number") then
                         toprint = toprint .. v .. ",\n"
                     elseif (type(v) == "string") then
                         toprint = toprint .. "\"" .. v .. "\",\n"
                     elseif (type(v) == "table") then
                         toprint = toprint .. DumpTable(v, indent) .. ",\n"
                     elseif (type(v) == "boolean") then
                         toprint = toprint .. (v and "true" or "false") .. ",\n"
                     else
                         toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
                     end
                 end
                 toprint = toprint .. string.rep(" ", indent-4) .. "}"
                 return toprint
             end
             
             local serialized = DumpTable(ns.db.profile)
             
             eb:SetText(serialized)
             eb:HighlightText()
             
             local close = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
             close:SetPoint("BOTTOM", 0, 10)
             close:SetSize(100, 25)
             close:SetText("Close")
             close:SetScript("OnClick", function() f:Hide() end)
             
             f:Show()
             ns.Print("Profile serialized. Please copy the text.")
             return
        end
    end

    -- Forward to standard handler
    Addon:SlashCommandOpen(msg)
end

SLASH_GUITESTCLEANUP1 = "/guitestcleanup"
SlashCmdList["GUITESTCLEANUP"] = function()
    local profile = "testUI"
    ns.Print("Cleaning up '" .. profile .. "' profiles...")
    
    local db = ns.GetDB()
    if db then db.installer = db.installer or {} end
    
    -- Iterate registry from Installer (requires access, assumed global ns.GUI.Installer)
    if ns.GUI and ns.GUI.Installer and ns.GUI.Installer.registry then
        for _, addon in ipairs(ns.GUI.Installer.registry) do
            if addon.Check() then
                -- Try to delete profile
                -- Note: Most addons don't have a standardized DeleteProfile in the registry, 
                -- so we might need to rely on the underlying DB object if available.
                local deleted = false
                
                -- Attempt to find the DB object
                local dbObj = nil
                if addon.name == "GravityUI" then dbObj = ns.db 
                elseif addon.name == "Details" and _G.Details then dbObj = _G.Details.db -- Details handles profiles differently though
                elseif addon.name == "Plater" and _G.Plater then dbObj = _G.Plater.db
                elseif addon.name == "BigWigs" and _G.BigWigs3DB then -- BigWigs manual key deletion
                     if _G.BigWigs3DB.profiles then _G.BigWigs3DB.profiles[profile] = nil deleted = true end
                end
                
                if dbObj and dbObj.DeleteProfile then
                    dbObj:DeleteProfile(profile)
                    deleted = true
                end
                
                if deleted then
                    print(" - Deleted from " .. addon.label)
                else
                    print(" - Could not delete from " .. addon.label .. " (Manual deletion required)")
                end
            end
        end
    end
    print("Cleanup complete. Reloading UI...")
    C_Timer.After(2, ReloadUI)
end
