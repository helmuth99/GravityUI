Addon, private = ...

local CronixUI = {
	["keyFontSize"] = 16,
	["bar2Font"] = "Cronix",
	["timerSuccessColor"] = "ff00ff28",
	["barPadding"] = 4,
	["verticalOffset"] = 4,
	["frameX"] = 17.11108207702637,
	["completedObjectivesColor"] = "ff00ff25",
	["keyColor"] = "ff0095ff",
	["bar3Font"] = "Cronix",
	["keyDetailsColor"] = "ffe6e6e6",
	["bar3TextureColor"] = "ffe6e6e6",
	["objectivesFont"] = "Cronix",
	["bar1Texture"] = "Cronix",
	["timerFont"] = "Cronix",
	["keyDetailsFont"] = "Cronix",
	["bar3Texture"] = "Cronix",
	["frameY"] = 220.6667022705078,
	["deathsFont"] = "Cronix",
	["forcesOverlayTexture"] = "Cronix",
	["timingsImprovedTimeColor"] = "ff00ff25",
	["showPrideGlow"] = false,
	["completedForcesColor"] = "ff00ff25",
	["objectivesFontSize"] = 16,
	["bar1Font"] = "Cronix",
	["forcesOverlayTextureColor"] = "ff00ff28",
	["bar2Texture"] = "Cronix",
	["timerFontSize"] = 28,
	["bar1TextureColor"] = "ffe6e6e6",
	["forcesTextureColor"] = "ff0096ff",
	["forcesTexture"] = "Cronix",
	["forcesFont"] = "Cronix",
	["bar2TextureColor"] = "ffe6e6e6",
	["barWidth"] = 300,
	["keyFont"] = "Cronix",
}

function private:WarpDepleteInstallTwink()
	local name = UnitName("PLAYER")
    local realm = GetRealmName()
    WarpDepleteDB["profileKeys"][name .. " - " .. realm] = private.Profilename
end


function private:WarpDepleteInstall()
    WarpDepleteDB["profiles"][private.Profilename] = CronixUI

    local name = UnitName("PLAYER")
    local realm = GetRealmName()

    WarpDepleteDB["profileKeys"][name .. " - " .. realm] = private.Profilename


    PluginInstallStepComplete.message = "WarpDeplete Profile Imported"
    PluginInstallStepComplete:Show()

end