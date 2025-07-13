local Addon, private = ...

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
	["bar2Texture"] = "Cronix",
	["keyDetailsFont"] = "Cronix",
	["completedForcesColor"] = "ff00ff25",
	["frameY"] = 220.6667022705078,
	["deathsFont"] = "Cronix",
	["forcesOverlayTexture"] = "Cronix",
	["timingsImprovedTimeColor"] = "ff00ff25",
	["showPrideGlow"] = false,
	["objectivesFontSize"] = 16,
	["bar3Texture"] = "Cronix",
	["bar1Font"] = "Cronix",
	["forcesOverlayTextureColor"] = "ff00ff28",
	["timerFontSize"] = 28,
	["bar1TextureColor"] = "ffe6e6e6",
	["forcesTexture"] = "Cronix",
	["forcesTextureColor"] = "ff0096ff",
	["forcesFont"] = "Cronix",
	["bar2TextureColor"] = "ffe6e6e6",
	["keyFont"] = "Cronix",
	["barWidth"] = 300,
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