--Don't worry about this
local addon, private = ...
local Version = GetAddOnMetadata(addon, "Version")

--Cache Lua / WoW API
local format = string.format
local GetCVarBool = GetCVarBool
local ReloadUI = ReloadUI
local StopMusic = StopMusic

private.Profilename = "CronixUI"

-- These are things we do not cache
-- GLOBALS: PluginInstallStepComplete, PluginInstallFrame

--Change this line and use a unique name for your plugin.
local MyPluginName = "|cff0097faCroniX UI|r"

--Create references to ElvUI internals
local E, L, V, P, G = unpack(ElvUI)

--Create reference to LibElvUIPlugin
local EP = LibStub("LibElvUIPlugin-1.0")

--Create a new ElvUI module so ElvUI can handle initialization when ready
local mod = E:NewModule(MyPluginName, "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0");


function private:GetResolution()
	horizontal, vertical = GetPhysicalScreenSize()
	if vertical <= 1200 then
		return 1080
	else
		return 1440
	end
end

--This function will hold your layout settings
local function SetupLayout()
	--[[
	--	PUT YOUR EXPORTED PROFILE/SETTINGS BELOW HERE
	--]]	
	private:Elvinstall()
	

	--[[
	--	This section at the bottom is just to update ElvUI and display a message
	--]]
	--Update ElvUI
	--E:UpdateAll(true)
	--Show message about layout being set
	PluginInstallStepComplete.message = "Layout Set"
	PluginInstallStepComplete:Show()
	
end

--This function is executed when you press "Skip Process" or "Finished" in the installer.
local function InstallComplete()
	if GetCVarBool("Sound_EnableMusic") then
		StopMusic()
	end

	--Set a variable tracking the version of the addon when layout was installed
	E.db[MyPluginName].install_version = Version
	
	CronixUIDB["Version"] = Version

	ReloadUI()
end

--This is the data we pass on to the ElvUI Plugin Installer.
--The Plugin Installer is reponsible for displaying the install guide for this layout.
local InstallerData = {
	Title = format("|cff4beb2c%s %s|r", private.Profilename, "Installation"),
	Name = MyPluginName,
	tutorialImage = "Interface/Addons/CronixInstaller/croniX_Logo.tga", --If you have a logo you want to use, otherwise it uses the one from ElvUI
	Pages = {
		[1] = function()
			if (CronixUIDB["Version"] == Version) then
				PluginInstallFrame.SubTitle:SetFormattedText("Welcome to the installation for the %s.", MyPluginName)
				PluginInstallFrame.Desc1:SetText("You have already installed the latest version of " .. MyPluginName .. " you can go throught the installer again or skip the process")
				PluginInstallFrame.Desc2:SetText("Your Version: " .. CronixUIDB["Version"] .. "    ---     " .. MyPluginName .. " Version: " ..Version)
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() InstallComplete() end)
				PluginInstallFrame.Option1:SetText("Skip Process")
			else
			PluginInstallFrame.SubTitle:SetFormattedText("Welcome to the installation for %s.", MyPluginName)
			PluginInstallFrame.Desc1:SetText("This installation process will guide you through a few steps and create a new ElvUI profile. If you want to be able to go back to your original settings then create a new profile before going through this installation process.")
			PluginInstallFrame.Desc2:SetText("Please press the continue button if you wish to go through the installation process, otherwise click the 'Skip Process' button.")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() InstallComplete() end)
			PluginInstallFrame.Option1:SetText("Skip Process")
			end
		end,
		[2] = function()
			PluginInstallFrame.SubTitle:SetText("Layouts")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Elvui part. The addon automatically installs eather the 1080p or 1440p version based on your resolution. \n Because of technical reasons the changes will only be visible after a reload.")
			PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() SetupLayout() end)
			PluginInstallFrame.Option1:SetText("CronixUI ElvUI")
		end,
		[3] = function()
			PluginInstallFrame.SubTitle:SetText("Plater")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Plater part.")
			PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:PlaterImport() end)
			PluginInstallFrame.Option1:SetText("CronixUI Plater")
		end,
		[4] = function()
			PluginInstallFrame.SubTitle:SetText("Weakaura")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Weakauren. \n|cffff0000Important:|r all of your installed Weakauren will be removed!")
			PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:WeakauraInstall() end)
			PluginInstallFrame.Option1:SetText("CronixUI Weakaura")
		end,
		[5] = function() 
			PluginInstallFrame.SubTitle:SetText("BigWigs")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI BigWigs part. \n|cffff0000Important:|r All of your current settings will be wiped, for all characters")
			PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:BWInstall() end)
			PluginInstallFrame.Option1:SetText("CronixUI Bigwigs")
		end,
		[6] = function()
			PluginInstallFrame.SubTitle:SetText("Method Raid Tools")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Method Raid Tools part. \n|cffff0000Important:|r All of your current settings will be wiped, for all characters")
			PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:MRTInstall() end)
			PluginInstallFrame.Option1:SetText("CronixUI MRT")
		end,
		[7] = function()
			PluginInstallFrame.SubTitle:SetText("Method Raid Tools")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Adibag part.")
			PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:AdiBagInstall() end)
			PluginInstallFrame.Option1:SetText("CronixUI Adibag")
		end,
		[8] = function()
			PluginInstallFrame.SubTitle:SetText("WarpDeplete")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI WarpDeplete part.")
			PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:WarpDepleteInstall() end)
			PluginInstallFrame.Option1:SetText("CronixUI WarpDeplete")
		end,
		[9] = function()
			PluginInstallFrame.SubTitle:SetText("OmniCD")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI OmniCD part.")
			PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:OmniCDInstall() end)
			PluginInstallFrame.Option1:SetText("CronixUI OmniCD")
		end,
		[10] = function()
			PluginInstallFrame.SubTitle:SetText("HidingBar")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI HidingBar part. \n|cffff0000Important:|r All of your current settings will be wiped, for all characters")
			PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:HidingbarInstall() end)
			PluginInstallFrame.Option1:SetText("CronixUI HidingBar")
		end,
		[11] = function()
			PluginInstallFrame.SubTitle:SetText("Details")
			PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Details part.")
			PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() private:DetailsInstall() end)
			PluginInstallFrame.Option1:SetText("CronixUI Details")
		end,
		[12] = function()
			PluginInstallFrame.SubTitle:SetText("Installation Complete")
			PluginInstallFrame.Desc1:SetText("You have completed the installation process.")
			PluginInstallFrame.Desc2:SetText("Please click the button below in order to finalize the process and automatically reload your UI.")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() InstallComplete() end)
			PluginInstallFrame.Option1:SetText("Finish")
		end,
	},
	StepTitles = {
		[1] = "Welcome",
		[2] = "ElvUI Installation",
		[3] = "Plater Installation",
		[4] = "WeakAuren Installation",
		[5] = "BigWigs Installation",
		[6] = "MRT Installation",
		[7] = "Adibag Installation",
		[8] = "WarpDeplete Installation",
		[9] = "OmniCD Installation",
		[10] = "HidingBar Installation",
		[11] = "Details Installation",
		[12] = "Installation Complete"
	},
	StepTitlesColor = {1, 1, 1},
	StepTitlesColorSelected = {0, 179/255, 1},
	StepTitleWidth = 200,
	StepTitleButtonWidth = 180,
	StepTitleTextJustification = "RIGHT",
}

--This function holds the options table which will be inserted into the ElvUI config
local function InsertOptions()
	E.Options.args.MyPluginName = {
		order = 100,
		type = "group",
		name = format("|cff4beb2c%s|r", MyPluginName),
		args = {
			header1 = {
				order = 1,
				type = "header",
				name = MyPluginName,
			},
			description1 = {
				order = 2,
				type = "description",
				name = format("%s is a layout for ElvUI.", MyPluginName),
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
				func = function() E:GetModule("PluginInstaller"):Queue(InstallerData); E:ToggleOptions(); end,
			},
		},
	}
end

--Create a unique table for our plugin
P[MyPluginName] = {}

--This function will handle initialization of the addon
function mod:Initialize()
	--Initiate installation process if ElvUI install is complete and our plugin install has not yet been run
	if CronixUIDB == nil then
		CronixUIDB = {
			["Version"] = 0
	}
	end
	
	if E.private.install_complete and E.db[MyPluginName].install_version == nil and CronixUIDB["Version"] ~= Version then
		E:GetModule("PluginInstaller"):Queue(InstallerData)
	end

	--Insert our options table when ElvUI config is loaded
	EP:RegisterPlugin(addon, InsertOptions)
end

--Register module with callback so it gets initialized when ready
E:RegisterModule(mod:GetName())