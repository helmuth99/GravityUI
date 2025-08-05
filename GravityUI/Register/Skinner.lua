local addon, private = ...

-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
importTwink = Twinkinstallation Process 
}
]]
local addonName = "Skinner"
local importText = "Import"
local data = {
    ["QuestInfo"] = false,
    ["MirrorTimers"] = {
        ["glaze"] = false,
    },
    ["PVPMatch"] = false,
    ["QuestFrame"] = false,
    ["CastingBar"] = {
        ["skin"] = false,
        ["glaze"] = false,
    },
    ["Backdrop"] = {
        ["a"] = 0.7551859021186829,
    },
    ["DisabledSkins"] = {
        ["Simulationcraft"] = true,
        ["Prat-3.0"] = true,
        ["BugSack"] = true,
        ["Leatrix_Plus"] = true,
        ["LibDBIcon-1.0 (Lib)"] = true,
        ["LibDropDown (Lib)"] = true,
        ["WeakAurasOptions (LoD)"] = true,
        ["AceGUI-3.0 (Lib)"] = true,
        ["Bartender4"] = true,
        ["MSA-DropDownMenu-1.0 (Lib)"] = true,
        ["AdvancedInterfaceOptions"] = true,
        ["Baganator"] = true,
        ["ColorPickerPlus"] = true,
        ["WeakAuras"] = true,
        ["Dominos_Config (LoD)"] = true,
        ["RCLootCouncil"] = true,
        ["BigWigs"] = true,
        ["WorldQuestTracker"] = true,
        ["LibKeyBound-1.0 (Lib)"] = true,
        ["Details"] = true,
        ["BtWQuests"] = true,
        ["DetailsFramework-1.0 (Lib)"] = true,
        ["Syndicator"] = true,
        ["TomTom"] = true,
        ["Postal"] = true,
        ["Auctionator"] = true,
        ["RaiderIO"] = true,
        ["NickTag-1.0 (Lib)"] = true,
        ["LibDialog-1.1 (Lib)"] = true,
        ["ScrollingTable (Lib)"] = true,
        ["BetterWardrobe"] = true,
    },
    ["Gradient"] = {
        ["enable"] = false,
        ["npc"] = false,
        ["char"] = false,
        ["addon"] = false,
        ["ui"] = false,
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
    ["ReadyCheck"] = false,
    ["CharacterFrames"] = false,
    ["ChatBubbles"] = {
        ["skin"] = false,
    },
    ["TexturedDD"] = false,
    ["TexturedTab"] = false,
    ["GradientMin"] = {
        ["b"] = 0.1019607931375504,
        ["g"] = 0.1019607931375504,
        ["r"] = 0.1019607931375504,
    },
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
        ["a"] = 0.8055558800697327,
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["BdDefault"] = false,
    ["DisableAllAS"] = true,
    ["Warnings"] = false,
    ["TabDDTextures"] = {
        ["tabddtex"] = "Details Ground",
    },
    ["QuestMap"] = false,
    ["Collections"] = false,
    ["GossipFrame"] = false,
    ["Errors"] = false,
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
    ["Nameplates"] = false,
    ["GradientMax"] = {
        ["a"] = 0,
        ["b"] = 0.250980406999588,
        ["g"] = 0.250980406999588,
        ["r"] = 0.250980406999588,
    },
    ["PVEFrame"] = false,
    ["PlayerSpells"] = false,
    ["DelvesUI"] = false,
    ["SliderBorder"] = {
        ["a"] = 0.8055558800697327,
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["MainMenuBar"] = {
        ["glazesb"] = false,
    },
    ["BdInset"] = 0,
    ["TooltipBorder"] = {
        ["a"] = 0.8025929927825928,
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["BdBorderTexture"] = "1 Pixel",
    ["BdTexture"] = "Solid",
    ["LFGTexture"] = true,
    ["Tooltips"] = {
        ["style"] = 3,
        ["glazesb"] = false,
        ["border"] = 2,
    },
    ["BdEdgeSize"] = 1,
    ["Settings"] = false,
    ["HelpFrame"] = false,
}

local function install()
    if SkinnerDB and private.g.cName and private.g.cRealm then
        SkinnerDB["profiles"][private.g.name] = data
        SkinnerDB["profileKeys"][private.g.cName.. " - "..private.g.cRealm] = private.g.name
    end
end

local function installTwink()
    if SkinnerDB and private.g.cName and private.g.cRealm then
        SkinnerDB["profileKeys"][private.g.cName.. " - "..private.g.cRealm] = private.g.name
    end
end

table.insert(private.Addons, {
    name = addonName,
    import = install,
    importText = importText,
    importTwink = installTwink
})