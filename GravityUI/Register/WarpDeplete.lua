local addon, private = ...

-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
importTwink = Twinkinstallation Process 
}
]]
local a
local addonName = "WarpDeplete"
local importText = "Import"
local data = {
    ["keyFontSize"] = 16,
    ["bar2Font"] = "Cronix",
    ["timerSuccessColor"] = "ff00ff28",
    ["barPadding"] = 4,
    ["verticalOffset"] = 4,
    ["frameX"] = 14.61116218566895,
    ["completedObjectivesColor"] = "ff00ff25",
    ["keyColor"] = "ff0095ff",
    ["bar3Font"] = "Cronix",
    ["keyDetailsColor"] = "ffe6e6e6",
    ["bar3TextureColor"] = "ffe6e6e6",
    ["objectivesFont"] = "Cronix",
    ["completedForcesColor"] = "ff00ff25",
    ["timerFont"] = "Cronix",
    ["bar2Texture"] = "Cronix",
    ["keyDetailsFont"] = "Cronix",
    ["bar1Texture"] = "Cronix",
    ["frameY"] = 170.6667327880859,
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

local function install() 
    if WarpDepleteDB then
        local name = private.g.cName
        local realm = private.g.cRealm
        WarpDepleteDB["profileKeys"][name .. " - " .. realm] = private.g.name
        WarpDepleteDB["profiles"][private.g.name] = data
    end
end

local function importTwink()
    if WarpDepleteDB then
        local name = private.g.cName
        local realm = private.g.cRealm
        WarpDepleteDB["profileKeys"][name .. " - " .. realm] = private.g.name
    end
end

table.insert(private.Addons, {
    name = addonName,
    import = install,
    importText = importText,
    importTwink = importTwink
})
