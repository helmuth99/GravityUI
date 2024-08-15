--Don't worry about this
local addon, private = ...
local Version = C_AddOns.GetAddOnMetadata(addon, "Version")

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
	local horizontal, vertical = GetPhysicalScreenSize()
	if vertical <= 1200 then
		return 1080
	else
		return 1440
	end
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

local AddonList = { "ElvUI", "Plater", "WeakAuras", "MRT", "WarpDeplete", "Details", "HidingBar", "OmniCD", "BigWigs",
	"Cell", "BetterBags" }

local CronixEverythingLoaded = true

local function CronixIsAddOnLoaded(AddonName)
	if C_AddOns.IsAddOnLoaded(AddonName) == true then
		return ("|cff00ff00loaded|r")
	else
		CronixEverythingLoaded = false
		return ("|cffff0000Not loaded|r")
	end
end
local function CronixCellCheck(AddonName)
	if AddonName == "Cell" then
		return " (only for HealUI needed) "
	else
		return ""
	end
end
local function Listaddon()
	local str = ""
	for i, v in ipairs(AddonList) do
		str = str .. v ..CronixCellCheck(v).." : " .. CronixIsAddOnLoaded(v) .. "\n"
	end
	return str
end

function private:CronixUIWarning(string, importFunction, ...)
	local args = {...}
	StaticPopupDialogs["ProfileOverrideConfirm"] = {
		text = string,
		button1 = "Accept",
		button2 = "Decline",
		OnAccept = function()
			importFunction(unpack(args))
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	-- tell our dialog box to show
	StaticPopup_Show("ProfileOverrideConfirm")
end

--This is the data we pass on to the ElvUI Plugin Installer.
--The Plugin Installer is reponsible for displaying the install guide for this layout.
local InstallParams = 0

local InstallerData = {
	Title = format("|cff0097fa%s %s|r", private.Profilename, "Installation"),
	Name = MyPluginName,
	tutorialImage = "Interface/Addons/CronixUI_installer/CRONIX_UI_LOGO.tga", --If you have a logo you want to use, otherwise it uses the one from ElvUI
	tutorialImagePoint = {0, 35},
	Pages = {
		[1] = function()
			if (CronixUIDB["Version"] == Version) then
				PluginInstallFrame.SubTitle:SetFormattedText("Welcome to the installation for the %s.", MyPluginName)
				PluginInstallFrame.Desc1:SetText("You have already installed the latest version of " ..
					MyPluginName .. " you can go throught the installer again or skip the process")
				PluginInstallFrame.Desc2:SetText("Your Version: " ..
					CronixUIDB["Version"] .. "    ---     " .. MyPluginName .. " Version: " .. Version)
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() InstallComplete() end)
				PluginInstallFrame.Option1:SetText("Skip Process")
			else
				PluginInstallFrame.SubTitle:SetFormattedText("Welcome to the installation for %s.", MyPluginName)
				PluginInstallFrame.Desc1:SetText(
					"This installation process will guide you through a few steps and create a new ElvUI profile. If you want to be able to go back to your original settings then create a new profile before going through this installation process.")
				PluginInstallFrame.Desc2:SetText(
					"Please press the continue button if you wish to go through the installation process, otherwise click the 'Skip Process' button.")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() InstallComplete() end)
				PluginInstallFrame.Option1:SetText("Skip Process")
			end
		end,
		[2] = function()
			PluginInstallFrame.SubTitle:SetText("ElvUI")
			PluginInstallFrame.Desc1:SetText("Please select the roles you want to install the " ..
				private.Profilename ..
				" for.\n Because of technical reasons the changes will only be visible after a reload.")
			PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function()
				InstallParams = 0
				private:Elvinstall(InstallParams)
			end)
			PluginInstallFrame.Option1:SetText("DPS")
			PluginInstallFrame.Option2:Show()
			PluginInstallFrame.Option2:SetScript("OnClick", function()
				InstallParams = 1
				private:Elvinstall(InstallParams)
			end)
			PluginInstallFrame.Option2:SetText("HEAL")
			PluginInstallFrame.Option3:Show()
			PluginInstallFrame.Option3:SetScript("OnClick", function()
				InstallParams = 2
				private:Elvinstall(InstallParams)
			end)
			PluginInstallFrame.Option3:SetText("DPS + HEAL")
		end,
		[3] = function()
			if C_AddOns.IsAddOnLoaded("Plater") then
				PluginInstallFrame.SubTitle:SetText("Plater")
				PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Plater part.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() private:PlaterImport() end)
				PluginInstallFrame.Option1:SetText("CronixUI Plater")
			else
				PluginInstallFrame.SubTitle:SetText("Plater")
				PluginInstallFrame.Desc1:SetText(
				"The addon Plater |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename .. " Plater part, please install/enable Plater and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[4] = function()
			if C_AddOns.IsAddOnLoaded("WeakAuras") then
				PluginInstallFrame.SubTitle:SetText("Weakaura")
				PluginInstallFrame.Desc1:SetText(
					"Please click the button below to install the CronixUI Weakauras. \n|cffff0000Important:|r All of your installed Weakauras will be removed and overwritten!")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() private:CronixUIWarning("|cffff0000Accepting this will overwrite all Weakauras on every characters! There will be no way to restore the lost data!|r", private.WeakauraInstall) end)
				PluginInstallFrame.Option1:SetText("CronixUI Weakaura")
			else
				PluginInstallFrame.SubTitle:SetText("Weakaura")
				PluginInstallFrame.Desc1:SetText(
				"The addon Weakaura |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename .. " Weakaura part, please install/enable Weakaura and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[5] = function()
			if C_AddOns.IsAddOnLoaded("BigWigs") then
				PluginInstallFrame.SubTitle:SetText("BigWigs")
				PluginInstallFrame.Desc1:SetText(
					"Please click the button below to install the CronixUI BigWigs part. \n|cffff0000Important:|r All of your current settings will be wiped, for all characters")
				PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() private:CronixUIWarning("|cffff0000Accepting this will overwrite Bigwigs for every character!|r", private.BWInstall) end)
				PluginInstallFrame.Option1:SetText("CronixUI Bigwigs")
			else
				PluginInstallFrame.SubTitle:SetText("BigWigs")
				PluginInstallFrame.Desc1:SetText(
				"The addon BigWigs |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename .. " BigWigs part, please install/enable BigWigs and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[6] = function()
			if C_AddOns.IsAddOnLoaded("MRT") then
				PluginInstallFrame.SubTitle:SetText("Method Raid Tools")
				PluginInstallFrame.Desc1:SetText(
					"Please click the button below to install the CronixUI Method Raid Tools part. \n|cffff0000Important:|r All of your current settings will be wiped, for all characters")
				PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() private:CronixUIWarning("|cffff0000Accepting this will overwrite MRT for every character!|r", private.MRTInstall) end)
				PluginInstallFrame.Option1:SetText("CronixUI MRT")
			else
				PluginInstallFrame.SubTitle:SetText("Method Raid Tools")
				PluginInstallFrame.Desc1:SetText(
				"The addon Method Raid Tools |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename ..
				" Method Raid Tools part, please install/enable Method Raid Tools and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[7] = function()
			if C_AddOns.IsAddOnLoaded("WarpDeplete") then
				PluginInstallFrame.SubTitle:SetText("WarpDeplete")
				PluginInstallFrame.Desc1:SetText(
				"Please click the button below to install the CronixUI WarpDeplete part.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() private:WarpDepleteInstall() end)
				PluginInstallFrame.Option1:SetText("CronixUI WarpDeplete")
			else
				PluginInstallFrame.SubTitle:SetText("WarpDeplete")
				PluginInstallFrame.Desc1:SetText(
				"The addon WarpDeplete |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename .. " WarpDeplete part, please install/enable WarpDeplete and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[8] = function()
			if C_AddOns.IsAddOnLoaded("OmniCD") then
				PluginInstallFrame.SubTitle:SetText("OmniCD")
				PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI OmniCD part.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() private:OmniCDInstall() end)
				PluginInstallFrame.Option1:SetText("CronixUI OmniCD")
			else
				PluginInstallFrame.SubTitle:SetText("OmniCD")
				PluginInstallFrame.Desc1:SetText(
				"The addon OmniCD |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename .. " OmniCD part, please install/enable OmniCD and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[9] = function()
			if C_AddOns.IsAddOnLoaded("HidingBar") then
				PluginInstallFrame.SubTitle:SetText("HidingBar")
				PluginInstallFrame.Desc1:SetText(
					"Please click the button below to install the CronixUI HidingBar part. \n|cffff0000Important:|r All of your current settings will be wiped, for all characters")
				PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() private:CronixUIWarning("|cffff0000Accepting this will overwrite HidingBar for every character!|r", private.HidingbarInstall) end)
				PluginInstallFrame.Option1:SetText("CronixUI HidingBar")
			else
				PluginInstallFrame.SubTitle:SetText("HidingBar")
				PluginInstallFrame.Desc1:SetText(
				"The addon HidingBar |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename .. " HidingBar part, please install/enable HidingBar and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[10] = function()
			if C_AddOns.IsAddOnLoaded("Details") then
				PluginInstallFrame.SubTitle:SetText("Details")
				PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Details part.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", function() private:DetailsInstall() end)
				PluginInstallFrame.Option1:SetText("CronixUI Details")
			else
				PluginInstallFrame.SubTitle:SetText("Details")
				PluginInstallFrame.Desc1:SetText(
				"The addon Details |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename .. " Details part, please install/enable Details and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[11] = function()
			if C_AddOns.IsAddOnLoaded("Cell") then
				if InstallParams == 0 then
					PluginInstallFrame.SubTitle:SetText("Cell")
					PluginInstallFrame.Desc1:SetText(
					"Please skip to the next page, since Cell is not needed for the DPS only profile.")
					PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffirrelevant|r")
				else
					PluginInstallFrame.SubTitle:SetText("Cell")
					PluginInstallFrame.Desc1:SetText("Please click the button below to install the CronixUI Cell Part.")
					PluginInstallFrame.Desc2:SetText("Importance: |cff00ffffLow|r")
					PluginInstallFrame.Option1:Show()
					PluginInstallFrame.Option1:SetScript("OnClick", function() private:CronixUIWarning("|cffff0000Accepting this will overwrite Cell for every character!|r", private.CellInstall) end)
					PluginInstallFrame.Option1:SetText("CronixUI Cell")
				end
			else
				PluginInstallFrame.SubTitle:SetText("Cell")
				PluginInstallFrame.Desc1:SetText("The addon Cell |cffff0000is not loaded|r. If you want to install the " ..
				private.Profilename .. " Cell part, please install/enable Cell and restart the installer.")
				PluginInstallFrame.Desc2:SetText("Importance: |cff07D400High|r")
			end
		end,
		[12] = function()
			PluginInstallFrame.SubTitle:SetText("Installation Complete")
			PluginInstallFrame.Desc1:SetText("You have completed the installation process.")
			PluginInstallFrame.Desc2:SetText(
				"Please click the button below in order to finalize the process and automatically reload your UI.")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() InstallComplete() end)
			PluginInstallFrame.Option1:SetText("Finish")
		end

	},
	StepTitles = {
		[1] = "Welcome",
		[2] = "ElvUI Installation",
		[3] = "Plater Installation",
		[4] = "WeakAuras Installation",
		[5] = "BigWigs Installation",
		[6] = "MRT Installation",
		[7] = "WarpDeplete Installation",
		[8] = "OmniCD Installation",
		[9] = "HidingBar Installation",
		[10] = "Details Installation",
		[11] = "Cell Installation",
		[12] = "Installation Complete",
	},
	StepTitlesColor = { 1, 1, 1 },
	StepTitlesColorSelected = { 0, 179 / 255, 1 },
	StepTitleWidth = 200,
	StepTitleButtonWidth = 180,
	StepTitleTextJustification = "RIGHT",
}

--This function holds the options table which will be inserted into the ElvUI config
local function InsertOptions()
	E.Options.args.CronixUI = {
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
				name = "",
				image = function() return "Interface/Addons/CronixUI_installer/CRONIX_UI_LOGO.tga", 400, 200 end,
				imageWidth = 64,
				imageHeight = 32,
			},
			spacer1 = {
				order = 3,
				type = "description",
				name = "\n\n\n",
			},
			header5 = {
				order = 4,
				type = "header",
				name = "options",
			},
			option1 = {
				order = 5,
				type = "toggle",
				name = "Cell helper",
				desc = "This will enable/disable the Cell helper. The Cell helper will promt you to disable/enable Cell for the intended use in the CronixUI.",
				set = function (info,val)
					if val then
						CronixUIDB.CellHelper = true
						mod:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
						mod:CellHelperDo()
					else
						print("unregistered event")
						CronixUIDB.CellHelper = false
						mod:UnregisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
					end
				end,
				get = function ()
					return CronixUIDB.CellHelper
				end
			},
			spacer2 = {
				order = 6,
				type = "description",
				name = "\n",
			},
			header3 = {
				order = 7,
				type = "header",
				name = "Addons",
			},
			description3 = {
				order = 8,
				type = "description",
				name =
				"Check the list below if every addon is loaded, that is going to be used during the installtion. \n\n" ..
				Listaddon(),
			},
			spacer3 = {
				order = 9,
				type = "description",
				name = "\n\n",
			},
			header4 = {
				order = 10,
				type = "header",
				name = "Shoutout",
			},
			description4 = {
				order = 11,
				type = "description",
				name =
				"Special shoutout to |cff0097faHijack|r for letting us use his class weakauras. Check him out on |Hurl:https://www.wago.io|hWago|h here: |cff71d5ffhttps://wago.io/p/iamhijack|r \n\n",
			},
			spacer4 = {
				order = 12,
				type = "description",
				name = "\n\n",
			},
			header2 = {
				order = 13,
				type = "header",
				name = "Installation",
			},
			description2 = {
				order = 14,
				type = "description",
				name =
				"The installation guide should pop up automatically after you have completed the ElvUI installation. If you wish to re-run the installation process for this layout then please click the button below.",
			},
			install = {
				order = 15,
				type = "execute",
				name = "Install " .. MyPluginName,
				desc = "Run the installation process for CronixUI.",
				width = "half",
				func = function()
					E:GetModule("PluginInstaller"):Queue(InstallerData); E:ToggleOptions();
				end,
			},
			install2 = {
				order = 15,
				type = "execute",
				name = "Install " .. MyPluginName .. "Twinks (WIP)",
				desc = "Run the installation process CronixUI for twinks.",
				width = "half",
				func = function()
					E:GetModule("PluginInstaller"):Queue(InstallerData); E:ToggleOptions();
				end,
			},
		},
	}
	if CronixEverythingLoaded == false then
		print("Not every addon is loaded")
		E.Options.args.CronixUI.args.install2 = {
			order = 10,
			type = "execute",
			name = "(optional) load addons",
			desc = "Press to enable all addons and start installation",
			width = "full",
			func = function()
				for _, value in ipairs(AddonList) do
					if C_AddOns.IsAddOnLoaded(value) == false then
						C_AddOns.EnableAddOn(value)
					end
				end
				CronixUIDB.reload = true
				ReloadUI()
			end,
			
		}
	end
end

--Create a unique table for our plugin
P[MyPluginName] = {}


--CronixUI Cell helper
local function CronixEnableCell(active)
	if active then
		C_AddOns.EnableAddOn("Cell")
	else
		C_AddOns.DisableAddOn("Cell")
	end
	ReloadUI()
end

function mod:CellHelperDo()
	local id, name, desc, icon, role, primary = GetSpecializationInfo(GetSpecialization())
	if role == "HEALER" and not C_AddOns.IsAddOnLoaded("Cell") then
		private:CronixUIWarning("CronixUI: Cell should be actived as a heal. Should we fix this?\n This will reload your UI! ", CronixEnableCell, true)
		return
	end
	if role ~= "Healer" and C_AddOns.IsAddOnLoaded("Cell") then
		private:CronixUIWarning("CronixUI: Cell should not be actived as a "..role..". Should we fix this?\n This will reload your UI! ", CronixEnableCell, false)
		return
	end
end

function mod:ACTIVE_PLAYER_SPECIALIZATION_CHANGED()
	mod:CellHelperDo()
end

--This function will handle initialization of the addon
function mod:Initialize()
	--Initiate installation process if ElvUI install is complete and our plugin install has not yet been run
	if CronixUIDB == nil then
		CronixUIDB = {
			["Version"] = 0
		}
	end

	if CronixUIDB.CellHelper == nil then
		CronixUIDB.CellHelper = true
	end

	if E.private.install_complete and E.db[MyPluginName].install_version == nil and CronixUIDB["Version"] ~= Version then
		E:GetModule("PluginInstaller"):Queue(InstallerData)
	end
	if CronixUIDB.reload then
		CronixUIDB.reload = false
		E:GetModule("PluginInstaller"):Queue(InstallerData)
	end

	--Insert our options table when ElvUI config is loaded
	EP:RegisterPlugin(addon, InsertOptions)

	if CronixUIDB.CellHelper then
		self:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
		mod:CellHelperDo()
	end
	
	
end

--Register module with callback so it gets initialized when ready
E:RegisterModule(mod:GetName())
