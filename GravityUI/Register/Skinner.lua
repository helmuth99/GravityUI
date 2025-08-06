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
    ["MirrorTimers"] = {
        ["glaze"] = false,
    },
    ["PVPMatch"] = false,
    ["CastingBar"] = {
        ["glaze"] = false,
        ["skin"] = false,
    },
    ["Backdrop"] = {
        ["a"] = 0.708888590335846,
    },
    ["GradientMin"] = {
        ["b"] = 0.1019607931375504,
        ["g"] = 0.1019607931375504,
        ["r"] = 0.1019607931375504,
    },
    ["Gradient"] = {
        ["addon"] = false,
        ["npc"] = false,
        ["char"] = false,
        ["enable"] = false,
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
    ["ExpansionLandingPage"] = false,
    ["CharacterFrames"] = false,
    ["ChatBubbles"] = {
        ["skin"] = false,
    },
    ["TexturedDD"] = false,
    ["TexturedTab"] = false,
    ["StatusBar"] = {
        ["a"] = 0.7018523812294006,
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
    ["WeeklyRewards"] = false,
    ["BackdropBorder"] = {
        ["a"] = 0.8055558800697327,
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["ZoneAbility"] = false,
    ["DisableAllAS"] = true,
    ["DisabledSkins"] = {
        ["Simulationcraft"] = true,
        ["LibDialog-1.1 (Lib)"] = true,
        ["BugSack"] = true,
        ["Prat-3.0"] = true,
        ["BetterWardrobe"] = true,
        ["Leatrix_Plus"] = true,
        ["WeakAurasOptions (LoD)"] = true,
        ["AceGUI-3.0 (Lib)"] = true,
        ["Dominos_Config (LoD)"] = true,
        ["Auctionator"] = true,
        ["AdvancedInterfaceOptions"] = true,
        ["Baganator"] = true,
        ["DetailsFramework-1.0 (Lib)"] = true,
        ["WeakAuras"] = true,
        ["RaiderIO"] = true,
        ["RCLootCouncil"] = true,
        ["BigWigs"] = true,
        ["Bartender4"] = true,
        ["LibKeyBound-1.0 (Lib)"] = true,
        ["Details"] = true,
        ["BtWQuests"] = true,
        ["ColorPickerPlus"] = true,
        ["WorldQuestTracker"] = true,
        ["TomTom"] = true,
        ["Postal"] = true,
        ["MSA-DropDownMenu-1.0 (Lib)"] = true,
        ["Syndicator"] = true,
        ["LibDropDown (Lib)"] = true,
        ["LibDBIcon-1.0 (Lib)"] = true,
        ["NickTag-1.0 (Lib)"] = true,
        ["ScrollingTable (Lib)"] = true,
    },
    ["Warnings"] = false,
    ["Nameplates"] = false,
    ["Collections"] = false,
    ["Errors"] = false,
    ["MajorFactions"] = false,
    ["HeadText"] = {
        ["g"] = 0.6117647290229797,
        ["r"] = 0.7490196228027344,
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
    ["PVEFrame"] = false,
    ["PlayerSpells"] = false,
    ["Settings"] = false,
    ["MainMenuBar"] = {
        ["glazesb"] = false,
    },
    ["BdInset"] = 0,
    ["BdDefault"] = false,
    ["BdBorderTexture"] = "1 Pixel",
    ["BdTexture"] = "Solid",
    ["CovenantRenown"] = false,
    ["SliderBorder"] = {
        ["a"] = 0.8055558800697327,
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["LFGTexture"] = true,
    ["TabDDTextures"] = {
        ["tabddtex"] = "Details Ground",
    },
    ["Tooltips"] = {
        ["style"] = 3,
        ["glazesb"] = false,
        ["border"] = 2,
    },
    ["CovenantToasts"] = false,
    ["BdEdgeSize"] = 1,
    ["DelvesUI"] = false,
    ["TooltipBorder"] = {
        ["a"] = 0.8025929927825928,
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["EncounterJournal"] = false,
    ["HelpFrame"] = false,
}

local function install()
    if SkinnerDB and private.g.cName and private.g.cRealm then
        SkinnerDB["profiles"][private.g.name] = data
        SkinnerDB["profileKeys"][private.g.cName .. " - " .. private.g.cRealm] = private.g.name
    end
end

local function installTwink()
    if SkinnerDB and private.g.cName and private.g.cRealm then
        SkinnerDB["profileKeys"][private.g.cName .. " - " .. private.g.cRealm] = private.g.name
    end
end

table.insert(private.Addons, {
    name = addonName,
    import = install,
    importText = importText,
    importTwink = installTwink
})
