local addon, engine = ...
engine[1] = {}
local Version = GetAddOnMetadata(addon, "Version")


function engine:unpack()
	return self[1]
end



local function tprintf(table)
	print("___Start:__");
		for key, value in pairs(table) do
			print('\t', key, value)
		end
	print("___End:__");
end
 --globals
CUI = engine[1];
CronixUIAddon = LibStub("AceAddon-3.0"):NewAddon("CronixUI Installer");
CronixUIAddon.db = LibStub("AceDB-3.0"):New("CronixUI_DB");
CUI.Pluginname = "CronixInstaller"

--Create references to ElvUI internals
local Elv, _, _, P, _ = unpack(ElvUI)

--Create reference to LibElvUIPlugin


--Create a new ElvUI module so ElvUI can handle initialization when ready
local CronixUI = Elv:NewModule(CUI.Pluginname, "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0");
local EP = LibStub("LibElvUIPlugin-1.0")
P[CUI.Pluginname] = {}
--globals end 

	-- string: a string as the message to be shown in the dialog box
function CUI:Notice(string)
	-- we'd like to notify the user about something
	-- make a dialog box that will show a notice

	-- Make the dialog box that will be shown
		StaticPopupDialogs["ProfileOverrideConfirm"] = {
			text = string,
			button1 = "Okay",
			OnAccept = function()
			end,
			StartDelay = function() return 1 end,
			whileDead = true,
			hideOnEscape = true,
		}

		-- tell our dialog box to show
		StaticPopup_Show("ProfileOverrideConfirm", "test")
end

function CUI:LoadCUIProfiles()
	--we are going to assume Installcomplete was called befor
	ElvUI[1].data:SetProfile(CronixUIAddon.db.global["ElvUI profile name"])

	if IsAddOnLoaded ("Plater") then
		CUI:PlaterImport()
	end

	--todo add other addons
	CronixUIAddon.db.profile.install_version = Version
	ReloadUI()
end

--This function is executed when you press "Skip Process" or "Finished" in the installer.
function CUI:InstallComplete()
	if GetCVarBool("Sound_EnableMusic") then
		StopMusic()
	end

	CronixUIAddon.db.global["ElvUI old name"] = ElvUI[1].data:GetCurrentProfile();
	CronixUIAddon.db.global.installed = true;

	CronixUIAddon.db.profile.install_version = Version

	--Plater dose not like it when you change profiles and requies a reload after so do it right before the reload
		Elv.private["nameplates"]["enable"] = false
		if IsAddOnLoaded ("Plater") then
			Plater.db:SetProfile("CronixUI")
		end
	--re-enabled the ElvUI incompatility warning
	--This is redundant if the users does import the ElvUI profile
	--but incase they didn't make sure this is back on.
	Elv.global.ignoreIncompatible = false
	ReloadUI()
end

local function InsertOptions()
	Elv.Options.args[CUI.Cronix_Installer] = {
		order = 100,
		type = "group",
		name = format("|cff4beb2c%s|r", CUI.Cronix_Installer),
		args = {
			header1 = {
				order = 1,
				type = "header",
				name = CUI.Cronix_Installer,
			},
			description1 = {
				order = 2,
				type = "description",
				name = format("%s is a layout for ElvUI.", CUI.Cronix_Installer),
			},
			spacer1 = {
				order = 3,
				type = "description",
				name = "\n\n\n",
			},
			header2 = {
				order = 4,
				type = "header",
				name = "Installation",
			},
			description2 = {
				order = 5,
				type = "description",
				name = "The installation guide should pop up automatically after you have completed the ElvUI installation. If you wish to re-run the installation process for this layout then please click the button below.",
			},
			spacer2 = {
				order = 6,
				type = "description",
				name = "",
			},
			install = {
				order = 7,
				type = "execute",
				name = "Install",
				desc = "Run the installation process.",
				func = function() Elv:GetModule("PluginInstaller"):Queue(CUI.InstallerData); Elv:ToggleOptionsUI(); end,
			},
		},
	}
end

function CronixUI:OnInitialize()
	print("starting addon")
	--disable the details tutorials
	--[[Details:SetTutorialCVar ("STREAMER_PLUGIN_FIRSTRUN", true)
	Details:SetTutorialCVar ("version_announce", 1)
	Details.character_first_run = false
	Details.auto_open_news_window = false
	_detalhes.is_first_run = false
]]--
	--Trick ElvUI into thinking it's installer has been run
	CronixUIAddon.db = LibStub("AceDB-3.0"):New("CronixUI_DB");
	Elv.private.install_complete = Elv.version

	if Elv.private.install_complete and CronixUIAddon.db.profile.install_version == nil then

		Elv.global.ignoreIncompatible = true;
		print("queuing frame")
		Elv:GetModule("PluginInstaller"):Queue(CUI.InstallerData)

	end

	EP:RegisterPlugin(addon, InsertOptions)
end
--Register module with callback so it gets initialized when ready
Elv:RegisterModule(CronixUI:GetName())
