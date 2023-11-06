Addon, private = ...

local CronixUI = {
			["keyFontSize"] = 19,
			["bar2Font"] = "Cronix",
			["timerSuccessColor"] = "ff00ff28",
			["bar2FontSize"] = 17,
			["frameX"] = 11.77755451202393,
			["keyDetailsFontSize"] = 17,
			["timerFont"] = "Cronix",
			["bar3Font"] = "Cronix",
			["keyDetailsColor"] = "ffe6e6e6",
			["bar3TextureColor"] = "ffe6e6e6",
			["objectivesFont"] = "Cronix",
			["bar2Texture"] = "Melli Dark",
			["keyDetailsFont"] = "Cronix",
			["frameY"] = 177.1111602783203,
			["bar1Texture"] = "Melli Dark",
			["barWidth"] = 330,
			["bar1TextureColor"] = "ffe6e6e6",
			["forcesOverlayTexture"] = "Melli Dark",
			["bar1FontSize"] = 17,
			["bar3Texture"] = "Melli Dark",
			["bar1Font"] = "Cronix",
			["bar2TextureColor"] = "ffe6e6e6",
			["showPrideGlow"] = false,
			["deathsFont"] = "Cronix",
			["keyColor"] = "ffe6e6e6",
			["forcesTextureColor"] = "ff0094ff",
			["timerFontSize"] = 30,
			["forcesTexture"] = "Melli Dark",
			["forcesFontSize"] = 17,
			["forcesFont"] = "Cronix",
			["forcesOverlayTextureColor"] = "ff00ff28",
			["bar3FontSize"] = 17,
			["keyFont"] = "Cronix",
}

function private:WarpDepleteInstall()
    WarpDepleteDB["profiles"]["CronixUI"] = CronixUI

    local name = UnitName("PLAYER")
    local realm = GetRealmName()

    WarpDepleteDB["profileKeys"][name .. " - " .. realm] = "CronixUI"

    PluginInstallStepComplete.message = "WarpDeplete Profile Imported"
    PluginInstallStepComplete:Show()

end