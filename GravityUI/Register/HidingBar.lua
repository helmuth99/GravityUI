local addon, private = ...


-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
}
]]
local addonName = "HidingBar"
local importText = "Import \n!!GLOBAL OVERWRITE!!"
local data = {
    ["tstmp"] = 1752278464,
    ["profiles"] = {
        {
            ["isDefault"] = true,
            ["config"] = {
                ["addFromDataBroker"] = true,
                ["mbtnSettings"] = {
                    ["LibDBIcon10_Professions"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["BtWQuestsMinimapButton"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_KeystoneGroupList"] = {
                        true,
                        ["tstmp"] = 1752252567,
                    },
                    ["LibDBIcon10_VocalRaidAssistant"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_MythicDungeonTools"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_BugSack"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_Socialite"] = {
                        ["tstmp"] = 1748255535,
                    },
                    ["LibDBIcon10_Details"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_Latency"] = {
                        ["tstmp"] = 1748479760,
                    },
                    ["LibDBIcon10_MethodRaidTools"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_Guild"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_Raven"] = {
                        true,
                        ["tstmp"] = 1749060648,
                    },
                    ["LibDBIcon10_Krowi_ExtendedVendorUILDB"] = {
                        ["tstmp"] = 1747930734,
                    },
                    ["LibDBIcon10_Hekili"] = {
                        ["tstmp"] = 1747607598,
                    },
                    ["LibDBIcon10_Friends"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_RaiderIO"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["AddonCompartmentFrame"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_ClassSpecs"] = {
                        ["tstmp"] = 1748480849,
                    },
                    ["LibDBIcon10_Durability"] = {
                        ["tstmp"] = 1748479772,
                    },
                    ["MinimapButton_D4Lib_LibDBIcon_MoveAny"] = {
                        ["tstmp"] = 1748940699,
                    },
                    ["LibDBIcon10_Leatrix_Plus"] = {
                        false,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_Masque"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_GPS"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_System"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_Gold"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_AutoQueueWA"] = {
                        true,
                        ["tstmp"] = 1750206201,
                    },
                    ["LibDBIcon10_BigWigs"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_NSRT"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_Volume"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_Dominos"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_Equipment"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_Bartender4"] = {
                        true,
                        ["tstmp"] = 1750200829,
                    },
                    ["LibDBIcon10_Bags"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_SimulationCraft"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_SylingTracker"] = {
                        ["tstmp"] = 1747421324,
                    },
                    ["LibDBIcon10_WeakAuras"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_Plater"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["LibDBIcon10_FPS"] = {
                        ["tstmp"] = 1748479749,
                    },
                    ["LibDBIcon10_TipTac"] = {
                        true,
                        ["tstmp"] = 1747441096,
                    },
                },
                ["btnSettings"] = {
                    ["SylingTracker"] = {
                        ["tstmp"] = 1747421324,
                    },
                    ["Raven"] = {
                        ["tstmp"] = 1749060648,
                    },
                    ["HidingBar"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["BigWigs"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["MRT"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["BtWQuests"] = {
                        true,
                        ["tstmp"] = 1752278464,
                    },
                    ["Bartender4"] = {
                        ["tstmp"] = 1750200829,
                    },
                    ["Krowi_ExtendedVendorUILDB"] = {
                        ["tstmp"] = 1747930734,
                    },
                    ["Dominos"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["NSRT"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["Masque"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["Prat"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["VocalRaidAssistant"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["TipTac"] = {
                        ["tstmp"] = 1747441096,
                    },
                    ["WeakAuras"] = {
                        ["tstmp"] = 1752278464,
                    },
                    ["RaiderIO"] = {
                        ["tstmp"] = 1752278464,
                    },
                },
                ["grabMinimap"] = true,
                ["grabMinimapAfterN"] = 1,
                ["ombGrabQueue"] = {
                },
                ["customGrabList"] = {
                    "AddonCompartmentFrame",
                },
                ["ignoreMBtn"] = {
                    "GatherMatePin",
                },
            },
            ["name"] = "Profile 1",
            ["bars"] = {
                {
                    ["isDefault"] = true,
                    ["config"] = {
                        ["lineWidth"] = 4,
                        ["secondPosition"] = 0,
                        ["hideHandler"] = 0,
                        ["lineBorderColor"] = {
                            1,
                            1,
                            1,
                            1,
                        },
                        ["showDelay"] = 0,
                        ["bgTexture"] = "Solid",
                        ["borderColor"] = {
                            1,
                            1,
                            1,
                            1,
                        },
                        ["anchor"] = "right",
                        ["lineTexture"] = "Solid",
                        ["barTypePosition"] = 0,
                        ["size"] = 15,
                        ["interceptTooltipPosition"] = 0,
                        ["petBattleHide"] = true,
                        ["lineColor"] = {
                            0.1647058823529412,
                            0.7333333333333333,
                            1,
                        },
                        ["position"] = 617.7780395790468,
                        ["mbtnPosition"] = 2,
                        ["lineBorderEdge"] = false,
                        ["lineBorderOffset"] = 1,
                        ["showHandler"] = 2,
                        ["expand"] = 2,
                        ["borderEdge"] = false,
                        ["bgColor"] = {
                            0.1,
                            0.1,
                            0.1,
                            0.7,
                        },
                        ["borderSize"] = 16,
                        ["gapSize"] = 0,
                        ["interceptTooltip"] = true,
                        ["buttonDirection"] = {
                            ["H"] = 0,
                            ["V"] = 0,
                        },
                        ["borderOffset"] = 4,
                        ["omb"] = {
                            ["size"] = 31,
                            ["hide"] = true,
                            ["fadeOpacity"] = 1,
                            ["anchor"] = "right",
                            ["barDisplacement"] = 0,
                            ["canGrabbed"] = false,
                            ["distanceToBar"] = 0,
                        },
                        ["buttonSize"] = 31,
                        ["frameStrata"] = 2,
                        ["lineBorderSize"] = 2,
                        ["fadeOpacity"] = 0.2,
                        ["orientation"] = 0,
                        ["rangeBetweenBtns"] = 0,
                        ["hideDelay"] = 0.75,
                        ["barOffset"] = 2,
                    },
                    ["name"] = "Bar 1",
                },
            },
        },
    },
}

local function import()
    if HidingBarDB then
        HidingBarDB = data
    end
end

table.insert(private.Addons, {
    name = addonName,
    import = import,
    importText = importText
})
