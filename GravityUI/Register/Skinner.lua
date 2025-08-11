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
    ["BgUseTex"] = true,
    ["MirrorTimers"] = {
        ["glaze"] = false,
    },
    ["PVPMatch"] = false,
    ["AchievementUI"] = {
        ["style"] = 1,
        ["skin"] = false,
    },
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
        ["texture"] = "Blizzard Tooltip",
    },
    ["DisabledText"] = {
        ["b"] = 1,
        ["g"] = 1,
        ["r"] = 1,
    },
    ["ContainerFrames"] = {
        ["itmbtns"] = true,
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
    ["DisabledSkins"] = {
        ["Simulationcraft"] = true,
        ["LibDialog-1.1 (Lib)"] = true,
        ["BugSack"] = true,
        ["WeakAurasOptions (LoD)"] = true,
        ["BetterWardrobe"] = true,
        ["AceGUI-3.0 (Lib)"] = true,
        ["ScrollingTable (Lib)"] = true,
        ["NickTag-1.0 (Lib)"] = true,
        ["Dominos_Config (LoD)"] = true,
        ["Auctionator"] = true,
        ["AdvancedInterfaceOptions"] = true,
        ["Baganator"] = true,
        ["DetailsFramework-1.0 (Lib)"] = true,
        ["WeakAuras"] = true,
        ["RaiderIO"] = true,
        ["RCLootCouncil"] = true,
        ["LibKeyBound-1.0 (Lib)"] = true,
        ["ColorPickerPlus"] = true,
        ["TomTom"] = true,
        ["Details"] = true,
        ["BtWQuests"] = true,
        ["Syndicator"] = true,
        ["WorldQuestTracker"] = true,
        ["BigWigs"] = true,
        ["Postal"] = true,
        ["MSA-DropDownMenu-1.0 (Lib)"] = true,
        ["Bartender4"] = true,
        ["LibDropDown (Lib)"] = true,
        ["LibDBIcon-1.0 (Lib)"] = true,
        ["Leatrix_Plus"] = true,
        ["Prat-3.0"] = true,
    },
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
    ["BdDefault"] = false,
    ["ZoneAbility"] = false,
    ["DisableAllAS"] = true,
    ["PVEFrame"] = false,
    ["CovenantRenown"] = false,
    ["Warnings"] = false,
    ["TabDDTextures"] = {
        ["tabddtex"] = "Details Ground",
    },
    ["Collections"] = false,
    ["Errors"] = false,
    ["HeadText"] = {
        ["b"] = 0.0470588281750679,
        ["g"] = 0.8352941870689392,
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
    ["SliderBorder"] = {
        ["a"] = 0.8085179328918457,
        ["b"] = 0,
        ["g"] = 0,
        ["r"] = 0,
    },
    ["PlayerSpells"] = false,
    ["DelvesUI"] = false,
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
    ["Nameplates"] = false,
    ["Tooltips"] = {
        ["border"] = 2,
        ["style"] = 3,
        ["glazesb"] = false,
    },
    ["CovenantToasts"] = false,
    ["BdEdgeSize"] = 1,
    ["MajorFactions"] = false,
    ["Settings"] = false,
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
