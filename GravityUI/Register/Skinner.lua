local addon, private = ...


-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
}
]]
local addonName = "Skinner"
local importText = "import"
local data = {
    ["MirrorTimers"] = {
        ["glaze"] = false,
    },
    ["CastingBar"] = {
        ["glaze"] = false,
    },
    ["Backdrop"] = {
        ["a"] = 0.6562499403953552,
    },
    ["DisabledSkins"] = {
        ["RCLootCouncil"] = true,
        ["Prat-3.0"] = true,
        ["Bartender4"] = true,
        ["Details"] = true,
        ["Baganator"] = true,
        ["DetailsFramework-1.0 (Lib)"] = true,
        ["Dominos_Config (LoD)"] = true,
    },
    ["Gradient"] = {
        ["enable"] = false,
        ["npc"] = false,
        ["char"] = false,
        ["ui"] = false,
        ["addon"] = false,
        ["skinner"] = false,
    },
    ["DisabledText"] = {
        ["b"] = 1,
        ["g"] = 1,
        ["r"] = 1,
    },
    ["ContainerFrames"] = {
        ["skin"] = true,
    },
    ["CharacterFrames"] = false,
    ["ChatBubbles"] = {
        ["skin"] = false,
    },
    ["TexturedDD"] = true,
    ["StatusBar"] = {
        ["a"] = 0.3059892356395721,
        ["b"] = 0.2156862914562225,
        ["r"] = 0.1960784494876862,
        ["g"] = 0.2039215862751007,
        ["texture"] = "Cronix",
    },
    ["MinimapIcon"] = {
        ["hide"] = true,
    },
    ["TabDDTexture"] = "Details Ground",
    ["BodyText"] = {
        ["b"] = 1,
        ["g"] = 1,
        ["r"] = 1,
    },
    ["BackdropBorder"] = {
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["TooltipBorder"] = {
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["DisableAllAS"] = true,
    ["Warnings"] = false,
    ["Nameplates"] = false,
    ["HeadText"] = {
        ["b"] = 1,
        ["g"] = 1,
        ["r"] = 1,
    },
    ["IgnoredText"] = {
        ["b"] = 1,
        ["g"] = 1,
        ["r"] = 1,
    },
    ["GradientMax"] = {
        ["a"] = 0,
        ["b"] = 0.250980406999588,
        ["g"] = 0.250980406999588,
        ["r"] = 0.250980406999588,
    },
    ["MainMenuBar"] = {
        ["glazesb"] = false,
    },
    ["BdInset"] = 0,
    ["Errors"] = false,
    ["SliderBorder"] = {
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["BdBorderTexture"] = "1 Pixel",
    ["BdTexture"] = "Solid",
    ["TabDDTextures"] = {
        ["texturedtab"] = true,
        ["tabddtex"] = "Details Ground",
        ["textureddd"] = true,
    },
    ["BdDefault"] = false,
    ["Tooltips"] = {
        ["glazesb"] = false,
        ["style"] = 3,
    },
    ["BdEdgeSize"] = 2,
    ["GradientMin"] = {
        ["b"] = 0.1019607931375504,
        ["g"] = 0.1019607931375504,
        ["r"] = 0.1019607931375504,
    },
    ["TexturedTab"] = true,
}

local function install()
    if SkinnerDB and private.g.cName and private.g.cRealm then
        SkinnerDB["profiles"][private.g.name] = data
        SkinnerDB["profileKeys"][private.g.cName.. " - "..private.g.cRealm] = private.g.name
    end
end

private.Addons[addonName] = {
    name = addonName,
    import = install,
    importText = importText
}