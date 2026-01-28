---------------------------------------------------------------------------
-- GravityUI Tooltip Module
-- Modern tooltip customization with combat safety and cursor anchoring
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...

ns.Tooltip = {}

-- Local references for performance
local GameTooltip = GameTooltip
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local strmatch = string.match
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS

-- Context Detection Constants
local UNIT_FRAME_PATTERNS = {
    "UnitFrame", "PlayerFrame", "TargetFrame", "FocusFrame",
    "PartyMemberFrame", "CompactRaidFrame", "CompactPartyFrame",
    "NamePlate", "Gravity.*Frame"
}

local ACTION_BUTTON_PATTERNS = {
    "ActionButton", "MultiBar", "PetActionButton", "StanceButton",
    "OverrideActionBar", "ExtraActionButton", "BT4Button", -- Bartender4
    "DominosActionButton", "ElvUI_Bar" -- Dominos / ElvUI
}

local BAG_PATTERNS = {
    "ContainerFrame", "BagSlot", "BankFrame", "ReagentBank",
    "BagItem", "Baganator" -- Baganator
}

---------------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------------

local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.tooltip then
        return db.uiimprovements.tooltip
    end
    return nil
end

local function IsSecretValue(value)
    if not value then return false end
    if type(issecretvalue) == "function" then
        return issecretvalue(value)
    end
    return false
end

local function IsModifierActive(modKey)
    if modKey == "SHIFT" then return IsShiftKeyDown() end
    if modKey == "CTRL" then return IsControlKeyDown() end
    if modKey == "ALT" then return IsAltKeyDown() end
    return false
end

-- Get color based on user rules: Theme/Class vs Custom
local function GetColorFromSettings(useThemeSetting, customColorSetting)
    if useThemeSetting then
        return ns.GetAccentColor()
    else
        -- customColorSetting is expected to be a table {r, g, b, a}
        if type(customColorSetting) == "table" and customColorSetting[1] then
            return customColorSetting[1], customColorSetting[2], customColorSetting[3], customColorSetting[4] or 1
        end
        return 1, 1, 1, 1 -- Fallback to white
    end
end

local function AddIDLine(tooltip, data)
    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.showIDs or not data then return end
    
    local id = data.id or data.spellId or data.itemId
    if not id or IsSecretValue(id) then return end
    
    -- Thorough duplication check: Scan existing tooltip lines for "ID:"
    -- Retail Safety: Use pcall and type checks for line text
    local tooltipName = tooltip:GetName()
    for i = 1, tooltip:NumLines() do
        local line = _G[tooltipName .. "TextLeft" .. i]
        if line then
            local ok, text = pcall(line.GetText, line)
            if ok and type(text) == "string" and text:find("ID:") then
                return -- ID line already exists, skip
            end
        end
    end
    
    -- Get Color
    local r, g, b = GetColorFromSettings(settings.useThemeColorID, settings.idColor)
    local colorHex = string.format("ff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
    
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("|c" .. colorHex .. "ID:|r", "|cffffffff" .. id .. "|r")
end

local function GetTooltipContext(owner)
    if not owner then return "npcs" end
    
    local name = owner:GetName() or ""
    
    -- Action Buttons / Abilities
    for _, pattern in ipairs(ACTION_BUTTON_PATTERNS) do
        if strmatch(name, pattern) then
            return "abilities"
        end
    end
    
    -- Bags / Items
    for _, pattern in ipairs(BAG_PATTERNS) do
        if strmatch(name, pattern) then
            return "items"
        end
    end
    
    -- Unit Frames
    for _, pattern in ipairs(UNIT_FRAME_PATTERNS) do
        if strmatch(name, pattern) or (owner.unit and strmatch(name, "UnitFrame")) then
            return "frames"
        end
    end
    
    -- Default to NPCs/World
    return "npcs"
end

local function ShouldShowTooltip(context)
    local settings = GetSettings()
    if not settings or not settings.enabled then return true end

    -- Combat Hide logic
    if settings.hideInCombat and InCombatLockdown() then
        if settings.combatKey and settings.combatKey ~= "NONE" then
            if IsModifierActive(settings.combatKey) then
                return true
            end
        end
        return false
    end

    -- Context visibility
    local visibility = settings.visibility and settings.visibility[context]
    if not visibility or visibility == "SHOW" then
        return true
    elseif visibility == "HIDE" then
        return false
    else
        return IsModifierActive(visibility)
    end
end

---------------------------------------------------------------------------
-- Styling Logic
---------------------------------------------------------------------------

local function ApplyStyle(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end
    
    -- Retail Safety: Skip complex styling (backdrops/dimensions) in combat
    -- This is the #1 cause of "Secret Value" errors when Blizzard code runs after us.
    if InCombatLockdown() then return end

    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.customStyle then return end

    -- Hide Blizzard NineSlice
    if tooltip.NineSlice then
        tooltip.NineSlice:Hide()
        tooltip.NineSlice:SetAlpha(0)
    end

    -- Apply Backdrop
    if not tooltip.SetBackdrop then
        Mixin(tooltip, BackdropTemplateMixin)
    end

    local bg = settings.bgColor or {0, 0, 0, 1}
    local r, g, b, a = GetColorFromSettings(settings.useThemeColor, settings.borderColor)
    local alpha = settings.bgAlpha or 0.8

    -- Wrap in pcall for 12.0 secret value dimension errors
    pcall(function()
        tooltip:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        tooltip:SetBackdropColor(bg[1], bg[2], bg[3], alpha)
        tooltip:SetBackdropBorderColor(r, g, b, a)
    end)

    -- Healthbar
    if tooltip.HealthBar then
        tooltip.HealthBar:SetAlpha(settings.hideHealthBar and 0 or 1)
    end
    if GameTooltipStatusBar and settings.hideHealthBar then
        GameTooltipStatusBar:SetAlpha(0)
    end

    -- Font Size
    if settings.fontSize then
        for i = 1, 15 do
            local left = _G[tooltip:GetName().."TextLeft"..i]
            local right = _G[tooltip:GetName().."TextRight"..i]
            if not left then break end
            
            pcall(function()
                local fontPath, _, fontFlags = left:GetFont()
                if fontPath then
                    left:SetFont(fontPath, settings.fontSize, fontFlags)
                end
                if right then
                    local rFontPath, _, rFontFlags = right:GetFont()
                    if rFontPath then
                        right:SetFont(rFontPath, settings.fontSize, rFontFlags)
                    end
                end
            end)
        end
    end
end

---------------------------------------------------------------------------
-- Tooltip Hooks
---------------------------------------------------------------------------

local function InitHooks()
    -- Primary Anchor Hook
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        -- Reset ID guard
        tooltip.__guiLastID = nil

        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        local context = GetTooltipContext(parent)
        if not ShouldShowTooltip(context) then
            tooltip:Hide()
            return
        end

        if settings.anchorToCursor then
            tooltip:SetOwner(parent, "ANCHOR_CURSOR")
        end
    end)

    -- Data Processor Hooks (Modern way)
    if TooltipDataProcessor then
        -- Units
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            if not tooltip or tooltip:IsForbidden() then return end
            
            local settings = GetSettings()
            if not settings or not settings.enabled then return end

            pcall(function()
                ApplyStyle(tooltip) -- Returns immediately in combat for safety
                
                -- Class Color Names (Combat safe logic)
                if settings and settings.classColorName and data and data.guid then
                    if not IsSecretValue(data.guid) then
                        local _, class = GetPlayerInfoByGUID(data.guid)
                        local color = class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
                        if color then
                            local text = _G[tooltip:GetName().."TextLeft1"]
                            if text then text:SetTextColor(color.r, color.g, color.b) end
                        end
                    end
                end

                -- IDs (Combat safe logic)
                AddIDLine(tooltip, data)
            end)
        end)

        -- Items & Spells
        local function GeneralPostCall(tooltip, data)
            if not tooltip or tooltip:IsForbidden() then return end
            
            local settings = GetSettings()
            if not settings or not settings.enabled then return end

            pcall(function()
                ApplyStyle(tooltip) -- Returns immediately in combat for safety
                AddIDLine(tooltip, data)
            end)
        end

        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, GeneralPostCall)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, GeneralPostCall)
    end

    -- Safety wrappers removed to prevent Ping System Taint.
    -- Overwriting globals like MoneyFrame_Update causes insecure execution paths.
end

---------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------

function ns.Tooltip.Refresh()
    if GameTooltip and GameTooltip:IsShown() and not GameTooltip:IsForbidden() then
        pcall(ApplyStyle, GameTooltip)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    InitHooks()
end)
