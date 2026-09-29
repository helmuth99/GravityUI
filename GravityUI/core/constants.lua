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
