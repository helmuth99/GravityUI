-- GravityUI Constants
local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
-- NOTE: C_AddOns.GetAddOnMetadata returns a 'secret' value in TWW+ that
-- cannot be concatenated, tostring'd, or examined.  Embed the packager
-- token directly instead — CurseForge replaces it at release time.
ns.VERSION = "@project-version@"

-- Expose namespace globally
_G.GravityUI = ns

-- Media paths
ns.MEDIA_PATH = "Interface/AddOns/" .. ADDON_NAME .. "/assets/"
ns.ICON_PATH = ns.MEDIA_PATH .. "GRAVITY_UI_Icon.blp"
ns.DISCORD_ICON = ns.MEDIA_PATH .. "discord.tga"
ns.FONT_PATH = ns.MEDIA_PATH .. "Gravity.ttf"

-- Default accent color (Deep Sky Blue)
ns.DEFAULT_ACCENT = {0, 0.749, 1, 1}

-- Color palette
ns.Colors = {
    -- Backgrounds
    bg = {0.117, 0.121, 0.133, 1},         -- Deep Cool Grey
    bgLight = {0.122, 0.161, 0.216, 1},    -- Lighter Sidebar/Headers
    bgDark = {0.04, 0.05, 0.08, 1},        -- Darker for inputs
    bgContent = {0, 0, 0, 0},              -- Transparent
    
    -- Accent colors
    accent = {0, 0.749, 1, 1},             -- Deep Sky Blue
    accentLight = {0.529, 0.808, 0.980, 1},-- Light Sky Blue
    accentDark = {0, 0.4, 0.6, 1},         -- Darker blue
    accentHover = {0.2, 0.8, 1, 1},        -- Hover state
    
    -- Text colors
    text = {0.9, 0.92, 0.95, 1},           -- Light Grey
    textBright = {1, 1, 1, 1},             -- White
    textMuted = {0.6, 0.65, 0.7, 1},       -- Muted Grey
    
    -- Borders
    border = {0.2, 0.23, 0.28, 1},         -- Subtle dark border
    borderLight = {0.3, 0.35, 0.4, 1},     -- Slightly lighter
    borderAccent = {0, 0.749, 1, 1},       -- Deep Sky Blue border
    
    -- Section headers
    sectionHeader = {0.529, 0.808, 0.980, 1}, -- Light Sky Blue
    
    -- Warning/secondary
    warning = {0.961, 0.620, 0.043, 1},    -- Amber
    
    -- Widget-specific colors
    toggleOff = {0.15, 0.15, 0.15, 1},     -- Toggle switch off state
    toggleThumb = {0.9, 0.9, 0.9, 1},      -- Toggle switch thumb
    sliderTrack = {0.15, 0.15, 0.15, 1},   -- Slider track background
    sliderThumb = {0, 0.749, 1, 1},        -- Slider thumb (accent)
    
    -- Tab colors
    tabHover = {0.2, 0.25, 0.3, 0.5},      -- Tab hover state
    tabSelected = {0, 0.749, 1, 0.2},      -- Tab selected background
    tabSelectedText = {0.529, 0.808, 0.980, 1}, -- Tab selected text
    
    -- Stat colors
    health = { 0.937, 0.267, 0.267, 1 },       -- Soft Red
    mana = { 0.231, 0.510, 0.965, 1 },         -- Soft Blue
    crit = { 0.976, 0.451, 0.086, 1 },         -- Orange
    haste = { 0.918, 0.702, 0.031, 1 },        -- Yellow
    mastery = { 0.545, 0.361, 0.965, 1 },      -- Purple
    versatility = { 0.024, 0.714, 0.831, 1 },  -- Cyan
}

-- WoW: Forever detection (Interface 16xxx = Forever client)
local _buildInterface = select(4, GetBuildInfo()) or 0
ns.IS_FOREVER = _buildInterface >= 16000 and _buildInterface < 17000
ns.IS_RETAIL  = not ns.IS_FOREVER

-- Forever: LibOpenRaid's expansion data files all have version guards that
-- exclude Forever's interface range (16xxx). The globals they normally
-- initialize stay nil, causing "attempt to index nil" errors.
-- We set empty fallback tables so the library degrades gracefully.
if ns.IS_FOREVER then
    LIB_OPEN_RAID_PLAYERCOOLDOWNS      = LIB_OPEN_RAID_PLAYERCOOLDOWNS      or {}
    LIB_OPEN_RAID_COOLDOWNS_INFO       = LIB_OPEN_RAID_COOLDOWNS_INFO       or {}
    LIB_OPEN_RAID_COOLDOWNS_BY_SPEC    = LIB_OPEN_RAID_COOLDOWNS_BY_SPEC    or {}
    LIB_OPEN_RAID_COOLDOWNS_SHARED_ID  = LIB_OPEN_RAID_COOLDOWNS_SHARED_ID  or {}
    LIB_OPEN_RAID_MELEE_SPECS          = LIB_OPEN_RAID_MELEE_SPECS          or {}
    LIB_OPEN_RAID_RANGED_SPECS         = LIB_OPEN_RAID_RANGED_SPECS         or {}
    LIB_OPEN_RAID_HEALER_SPECS         = LIB_OPEN_RAID_HEALER_SPECS         or {}
    LIB_OPEN_RAID_TANK_SPECS           = LIB_OPEN_RAID_TANK_SPECS           or {}
    LIB_OPEN_RAID_ALL_POTIONS          = LIB_OPEN_RAID_ALL_POTIONS          or {}
    LIB_OPEN_RAID_ALL_FLASKS           = LIB_OPEN_RAID_ALL_FLASKS           or {}
    LIB_OPEN_RAID_FOOD_BUFF            = LIB_OPEN_RAID_FOOD_BUFF            or {}
    LIB_OPEN_RAID_AUGMENT_BUFF         = LIB_OPEN_RAID_AUGMENT_BUFF         or {}
    LIB_OPEN_RAID_WEAPON_ENCHANT_IDS   = LIB_OPEN_RAID_WEAPON_ENCHANT_IDS   or {}
end

-- Specialization API wrappers (safe on every client).
-- Retail/Midnight: functions live in C_SpecializationInfo (or legacy globals).
-- Forever: the spec system does not exist -> wrappers return nil instead of
-- erroring with "attempt to call a nil value".
-- Defined here (constants.lua loads before character.lua / init.lua).
do
    local CSI = C_SpecializationInfo
    local _getSpec     = (CSI and CSI.GetSpecialization) or GetSpecialization
    local _getSpecInfo = (CSI and CSI.GetSpecializationInfo) or GetSpecializationInfo
    local _getSpecRole = (CSI and CSI.GetSpecializationRole) or GetSpecializationRole
    local _getMastery  = CSI and CSI.GetSpecializationMasterySpells

    ns.GetSpecialization = function(...)
        if _getSpec then return _getSpec(...) end
        return nil
    end
    ns.GetSpecializationInfo = function(specIndex, ...)
        if _getSpecInfo and specIndex then return _getSpecInfo(specIndex, ...) end
        return nil
    end
    ns.GetSpecializationRole = function(specIndex, ...)
        if _getSpecRole and specIndex then return _getSpecRole(specIndex, ...) end
        return nil
    end
    ns.GetSpecializationMasterySpells = function(specIndex, ...)
        if _getMastery and specIndex then return _getMastery(specIndex, ...) end
        return nil
    end

    -- Forever only: there is no spec role, so use the group role the player
    -- picked (LFG / role check). Returns "TANK"/"HEALER"/"DAMAGER" or nil.
    ns.GetForeverPlayerRole = function()
        local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
        if not role or (issecretvalue and issecretvalue(role)) or role == "NONE" then return nil end
        return role
    end
end

-- Forever: dual spec (talent group) switch guard.
-- During the switch the client rebuilds all action slots, spells, forms and
-- cooldowns at once. Querying action/spell cooldowns (duration objects), stance
-- data or reparenting stance buttons in that window crashed the client
-- (ACCESS_VIOLATION) with GravityUI loaded. Modules check ns.IsTalentSwapping()
-- and skip their work; once the switch has settled, registered callbacks run a
-- single full refresh instead.
do
    local swapping = false
    local token = 0
    local doneCallbacks = {}

    ns.IsTalentSwapping = function() return swapping end
    ns.RegisterTalentSwapDone = function(fn)
        if type(fn) == "function" then doneCallbacks[#doneCallbacks + 1] = fn end
    end

    if ns.IS_FOREVER then
        local function Finish(myToken)
            if myToken ~= token then return end  -- a newer switch extended the window
            swapping = false
            for _, fn in ipairs(doneCallbacks) do pcall(fn) end
        end
        -- (Re)start the guard window; it ends `settle` seconds after the last trigger.
        local function Begin(settle)
            swapping = true
            token = token + 1
            local myToken = token
            C_Timer.After(settle, function() Finish(myToken) end)
        end
        ns._BeginTalentSwap = Begin

        -- Activate Primary/Secondary Spec (cast) spell IDs
        local DUAL_SPEC_SPELLS = { [63644] = true, [63645] = true }

        -- Hook the API calls the talent UI uses to switch groups (whichever exist).
        local function HookSwitchFn(tbl, name)
            if tbl and type(tbl[name]) == "function" then
                pcall(hooksecurefunc, tbl, name, function() Begin(10) end)
            end
        end
        HookSwitchFn(_G, "SetActiveTalentGroup")
        HookSwitchFn(_G, "SetActiveSpecGroup")
        HookSwitchFn(C_SpecializationInfo, "SetActiveSpecGroup")
        HookSwitchFn(C_SpecializationInfo, "SetActiveTalentGroup")
        HookSwitchFn(C_Talent, "SetActiveTalentGroup")

        local f = CreateFrame("Frame")
        pcall(f.RegisterEvent, f, "ACTIVE_TALENT_GROUP_CHANGED")
        pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_START", "player")
        pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_STOP", "player")
        pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_FAILED", "player")
        pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_INTERRUPTED", "player")
        f:SetScript("OnEvent", function(_, event, _, _, spellID)
            if event == "ACTIVE_TALENT_GROUP_CHANGED" then
                Begin(1.5)  -- switch done; let the slot/spell flood settle
            elseif spellID and not (issecretvalue and issecretvalue(spellID)) and DUAL_SPEC_SPELLS[spellID] then
                if event == "UNIT_SPELLCAST_START" then
                    Begin(15)   -- covers the cast; ACTIVE_TALENT_GROUP_CHANGED shortens it
                elseif swapping then
                    Begin(2)    -- cast stopped/failed: short settle (success re-arms via the event)
                end
            end
        end)
    end
end
