local addon, _ = ...
local  CUI = select(2, ...):unpack()
local Version = GetAddOnMetadata(addon, "Version")


CUI.InstallerData  = {
    Title = "hello",
    Name = CUI.PluginName,
    --tutorialImage = "todo", --todo,
    Pages = {
        [1] = function()
            print("bulding frame")
            if CronixUI_DB.global and CronixUI_DB.global.installed then
                PluginInstallFrame.SubTitle:SetText("Welcome to the Installation for " .. CUI.PluginName)
                PluginInstallFrame.Desc1:SetText("Thank you for chossing " .. CUI.PluginName .. " again. You have installed " .. Name .. " befor." )
                PluginInstallFrame.Desc2:SetText("If you would like to go through the installation again you can click the continue button. |cffff0000!!WARNING:!!|r Doing so will reset all of your profiles again. You can also click 'Skip Process' if you don't want the Naowh profiles on this character.")
                PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", CUI.LoadNUIProfiles) --todo
				PluginInstallFrame.Option1:SetText("Load Profiles")
				PluginInstallFrame.Option2:Show()
				PluginInstallFrame.Option2:SetScript("OnClick", CUI.InstallComplete)
				PluginInstallFrame.Option2:SetText("Skip Process")
            else
                CUI:Notice("Warning, some changes only apply after a reload, the installer will automatically reload at the end of the installation.")
                PluginInstallFrame.SubTitle:SetText("Welcome to the installation for " .. CUI.PluginName .. ".")
				PluginInstallFrame.Desc1:SetText("This installation process will guide you through steps to add Cronix profiles for various addons.\n|cffff0000!!WARNING:!!|r Running the installer will cause ALL settings for the addons in it to be wiped. If you'd like to keep any of your settings back up your WTF file NOW!")
				PluginInstallFrame.Desc2:SetText("Please press the continue button if you wish to go through the installation process, otherwise click the 'Skip Process' button.")
				PluginInstallFrame.Option1:Show()
				PluginInstallFrame.Option1:SetScript("OnClick", CUI.InstallComplete)
				PluginInstallFrame.Option1:SetText("Skip Process")
            end
        end,
        [2] = function()
            PluginInstallFrame.SubTitle:SetText("ElvUI")
            PluginInstallFrame.Desc1:SetFormattedText("Press the confirm button to install the ElvUI part")
            PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function() CUI:ElvUIImport() end)
			PluginInstallFrame.Option1:SetText("confirm")
        end,
        [3] = function ()
            PluginInstallFrame.SubTitle:SetFormattedText("Plater")
			PluginInstallFrame.Desc1:SetText("Import Cronix Plater profile.")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", CUI:PlaterImport())
			PluginInstallFrame.Option1:SetText("Setup Plater")
            -- body
        end,
        [4] = function()
            PluginInstallFrame.SubTitle:SetText("Installation Complete")
			PluginInstallFrame.Desc1:SetText("You have completed the installation process.")
			PluginInstallFrame.Desc2:SetText("Please click the button below in order to finalize the process and automatically reload your UI.")
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", CUI.InstallComplete)
			PluginInstallFrame.Option1:SetText("Finished")

        end,
    },
    StepTitles = {
		[1] = "Welcome",
		[2] = "ElvUI",
		[3] = "Plater",
		[4] = "Installation Complete",
	},
    StepTitlesColor = {1, 1, 1},
	StepTitlesColorSelected = {0, 179/255, 1},
	StepTitleWidth = 200,
	StepTitleButtonWidth = 180,
	StepTitleTextJustification = "RIGHT",
}