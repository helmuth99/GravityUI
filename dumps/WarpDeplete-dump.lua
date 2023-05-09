Addon, private = ...

local CronixUI = {
    ["keyFontSize"] = 19,
    ["timerSuccessColor"] = "ff00ff28",
    ["bar2FontSize"] = 17,
    ["frameX"] = 9.999900817871094,
    ["keyDetailsFontSize"] = 17,
    ["keyColor"] = "ffe6e6e6",
    ["bar3FontSize"] = 17,
    ["keyDetailsColor"] = "ffe6e6e6",
    ["showPrideGlow"] = false,
    ["bar3TextureColor"] = "ffe6e6e6",
    ["bar2Texture"] = "Meli",
    ["frameY"] = 105.9999694824219,
    ["bar1Texture"] = "Meli",
    ["bar1TextureColor"] = "ffe6e6e6",
    ["forcesOverlayTexture"] = "Meli",
    ["bar1FontSize"] = 17,
    ["bar3Texture"] = "Meli",
    ["forcesOverlayTextureColor"] = "ff00ff28",
    ["forcesTextureColor"] = "ff0094ff",
    ["timerFontSize"] = 30,
    ["forcesTexture"] = "Meli",
    ["forcesFontSize"] = 17,
    ["bar2TextureColor"] = "ffe6e6e6",
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