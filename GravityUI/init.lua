-- Keybinding display name (must be global before Bindings.xml loads)
BINDING_NAME_GravityUI_TOGGLE_OPTIONS = "Open GravityUI Options"

---@type table|AceAddon
GravityUI = LibStub("AceAddon-3.0"):NewAddon("GravityUI", "AceConsole-3.0", "AceEvent-3.0")
---@type table<string, string>
GravityUI.L = LibStub("AceLocale-3.0"):GetLocale("GravityUI")

local L = GravityUI.L

---@type table
GravityUI.DF = _G["DetailsFramework"]
GravityUI.DEBUG_MODE = false

-- Version info
GravityUI.versionString = C_AddOns.GetAddOnMetadata("GravityUI", "Version") or "1.42"

---@type table
GravityUI.defaults = {
    global = {},
    char = {
        ---@type table
        debug = {
            ---@type boolean
            reload = false
        }
    }
}

function GravityUI:OnInitialize()
    ---@type AceDBObject-3.0
    self.db = LibStub("AceDB-3.0"):New("GravityUI_DB", self.defaults, "Default")

    self:RegisterChatCommand("gui", "SlashCommandOpen")
    self:RegisterChatCommand("Gravityui", "SlashCommandOpen")
    self:RegisterChatCommand("rl", "SlashCommandReload")
    
    -- Register our media files with LibSharedMedia
    self:CheckMediaRegistration()
end

-- Quick Keybind Mode shortcut (/kb)
SLASH_GUIKB1 = "/kb"
SlashCmdList["GUIKB"] = function()
    local LibKeyBound = LibStub("LibKeyBound-1.0", true)
    if LibKeyBound then
        LibKeyBound:Toggle()
    elseif QuickKeybindFrame then
        -- Fallback to Blizzard's Quick Keybind Mode (no mousewheel support)
        ShowUIPanel(QuickKeybindFrame)
    else
        print("|cff34D399GravityUI:|r Quick Keybind Mode not available.")
    end
end

-- Cooldown Settings shortcut (/cdm)
SLASH_GravityUI_CDM1 = "/cdm"
SlashCmdList["GravityUI_CDM"] = function()
    if CooldownViewerSettings then
        CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
    else
        print("|cff34D399GravityUI:|r Cooldown Settings not available. Enable CDM first.")
    end
end

function GravityUI:SlashCommandOpen(input)
    if input and input == "debug" then
        self.db.char.debug.reload = true
        GravityUI:SafeReload()
    elseif input and input == "editmode" then
        -- Toggle Unit Frames Edit Mode
        if _G.GravityUI_ToggleUnitFrameEditMode then
            _G.GravityUI_ToggleUnitFrameEditMode()
        else
            print("|cFF56D1FFGravityUI:|r Unit Frames module not loaded.")
        end
        return
    end
    
    -- Default: Open custom GUI
    if self.GUI then
        self.GUI:Toggle()
    else
        print("|cFF56D1FFGravityUI:|r GUI not loaded yet. Try again in a moment.")
    end
end

function GravityUI:SlashCommandReload()
    GravityUI:SafeReload()
end

function GravityUI:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Initialize guiCore (AceDB-based integration)
    if self.guiCore then
        print("|cFF30D1FFGravity UI|r loaded. |cFFFFFF00/gui|r")
    end
end

function GravityUI:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
    GravityUI:BackwardsCompat()

    -- Ensure debug table exists
    if not self.db.char.debug then
        self.db.char.debug = { reload = false }
    end

    if not self.DEBUG_MODE then
        if self.db.char.debug.reload then
            self.DEBUG_MODE = true
            self.db.char.debug.reload = false
            self:DebugPrint("Debug Mode Enabled")
        end
    else
        self:DebugPrint("Debug Mode Enabled")
    end
end

function GravityUI:DebugPrint(...)
    if self.DEBUG_MODE then
        self:Print(...)
    end
end

-- ADDON COMPARTMENT FUNCTIONS --
function GravityUI_CompartmentClick()
    -- Open the new GUI
    if GravityUI.GUI then
        GravityUI.GUI:Toggle()
    end
end

local GameTooltip = GameTooltip
function GravityUI_CompartmentOnEnter(self, button)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(type(self) ~= "string" and self or button, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["AddonName"] .. " v" .. GravityUI.versionString)
    GameTooltip:AddLine(L["LeftClickOpen"])
    GameTooltip:Show()
end

function GravityUI_CompartmentOnLeave()
    GameTooltip:Hide()
end
