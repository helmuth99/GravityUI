-- GravityUI Constants
local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
ns.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "1.0.0"

-- Expose namespace globally
_G.GravityUI = ns

-- Media paths
ns.MEDIA_PATH = "Interface/AddOns/" .. ADDON_NAME .. "/assets/"
ns.ICON_PATH = ns.MEDIA_PATH .. "GRAVITY_UI_Icon.png"
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
