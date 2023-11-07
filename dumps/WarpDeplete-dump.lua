Addon, private = ...

local CronixUI = {
	["bar2Font"] = "Cronix",
	["timerSuccessColor"] = "ff00ff28",
	["frameX"] = 11.77755451202393,
	["keyDetailsFontSize"] = 17,
	["keyColor"] = "ffe6e6e6",
	["bar3FontSize"] = 17,
	["keyDetailsColor"] = "ffe6e6e6",
	["bar3TextureColor"] = "ffe6e6e6",
	["objectivesFont"] = "Cronix",
	["bar1Texture"] = "Melli Dark",
	["timerFont"] = "Cronix",
	["keyDetailsFont"] = "Cronix",
	["frameY"] = 177.1111602783203,
	["deathsFont"] = "Cronix",
	["forcesOverlayTexture"] = "Melli Dark",
	["bar1FontSize"] = 17,
	["bar2FontSize"] = 17,
	["showPrideGlow"] = false,
	["keyFontSize"] = 19,
	["bar3Texture"] = "Melli Dark",
	["bar1Font"] = "Cronix",
	["bar2TextureColor"] = "ffe6e6e6",
	["bar2Texture"] = "Melli Dark",
	["timerFontSize"] = 30,
	["bar1TextureColor"] = "ffe6e6e6",
	["forcesTextureColor"] = "ff0094ff",
	["forcesTexture"] = "Melli Dark",
	["forcesFont"] = "Cronix",
	["forcesFontSize"] = 17,
	["forcesOverlayTextureColor"] = "ff00ff28",
	["keyFont"] = "Cronix",
	["bar3Font"] = "Cronix",
	["barWidth"] = 330,
}

function private:WarpDepleteInstall()
    WarpDepleteDB["profiles"]["CronixUI"] = CronixUI

    local name = UnitName("PLAYER")
    local realm = GetRealmName()

    WarpDepleteDB["profileKeys"][name .. " - " .. realm] = "CronixUI"

    PluginInstallStepComplete.message = "WarpDeplete Profile Imported"
    PluginInstallStepComplete:Show()

end