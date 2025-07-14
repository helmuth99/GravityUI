local addon, private = ...
local Version = C_AddOns.GetAddOnMetadata(addon, "Version")
private.g = {}
private.g.name = addon
private.g.mainFrame = nil
private.GravityUI = nil  --will be set after init of LibStub
private.AceGUI = LibStub("AceGUI-3.0")
--private.AddonList = {"Cell", "Dominos", "Prat 3.0", "Details", "Plater", "WeakAuras", "LeatrixPlus", "Bagantor", "WarpDeplete", "BigWigs", "OmniCD", "HidingBar", "Skinner"}
--utility
local format = string.format
local GetCVarBool = GetCVarBool
local ReloadUI = ReloadUI
local StopMusic = StopMusic
local name = UnitName("PLAYER")
local realm = GetRealmName()
local DevTool = DevTool
private.g.cName = name
private.g.cRealm = realm
private.g.font = "Interface\\Addons\\CronixUIMedia\\Media\\font\\Cronix.ttf"
private.g.blue = function() return 0.11764705882353, 0.56470588235294, 1 end


if not private.pages then
    private.pages = {}
end

if not private.Addons then
    private.Addons = {}
end

---@param data any
---@param name string
function useDevTool(data, name)
    if DevTool then
        DevTool:AddData(data, name)
    end
end
-- end utility
local GravityUI = LibStub("AceAddon-3.0"):NewAddon(private.g.name, "AceConsole-3.0")
private.GravityUI = GravityUI

local function ShouldReload()
    if GravityUI.db.global.reload then
        ReloadUI()
    end
end
function GravityUI:ShowFrame()
    if not private.g.mainFrame then
        local frame = GravityUI:CreateFrame()
        private.pages:Home(frame)
        frame:SetTitle("GRAVITY UI powered by |cff00ccffCronix UI|r")
        private.g.mainFrame = frame
        frame:SetCallback("OnClose", function(widget) 
            ShouldReload() 
            end)
        return
    end
    if private.g.mainFrame:IsShown() then
        private.g.mainFrame:Hide()
    else
        private.g.mainFrame:Show()
    end
end


function GravityUI:OnInitialize()
    local defaults = {
        char = {
            ['*'] = false,
        },
        global = {
            reload = false,
            Version = 0,
            InstalledAddons = {},
        }
    }
    
    self.db = LibStub("AceDB-3.0"):New("GravityUIDB", defaults, true)


    if not GravityUI.db.global.Version or GravityUI.db.global.Version == 0 then --this was set by a reload we still need to fix this
		GravityUI:ShowFrame()
        GravityUI.db.global.Version = Version
	end

    if not GravityUI.db.char or not GravityUI.db.char[private.g.cName .. "-" .. private.g.cRealm] then
        GravityUI.db.char[private.g.cName .. "-" .. private.g.cRealm] = true
    end

    if GravityUI.db.global.reload then
        GravityUI.db.global.reload = false
    end
    

    
    --register chat commands
    self:RegisterChatCommand("gui", "HandleSlash")
    self:RegisterChatCommand("GUI", "HandleSlash")
    self:RegisterChatCommand("cui", "HandleSlash")
    self:RegisterChatCommand("CUI", "HandleSlash")
end

function GravityUI:HandleSlash()
    GravityUI:ShowFrame()
end
