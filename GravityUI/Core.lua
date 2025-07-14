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


function GravityUI:ShowFrame()
    if not private.g.mainFrame then
        local frame = GravityUI:CreateFrame()
        private.pages:Home(frame)
        frame:SetTitle("GravityUI Installer")
        private.g.mainFrame = frame
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


    if GravityUI.db.global.reload then --this was set by a reload we still need to fix this
		GravityUI.db.global.reload = false
        print("fix this")
		
	end



    
    --register chat commands
    self:RegisterChatCommand("gui", "HandleSlash")
    self:RegisterChatCommand("GUI", "HandleSlash")
end

function GravityUI:HandleSlash()
    GravityUI:ShowFrame()
end
