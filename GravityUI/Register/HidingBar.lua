local addon, private = ...


-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
importTwink = Twinkinstallation Process
}
]]
local addonName = "HidingBar"
local importText = "Import \n!!GLOBAL OVERWRITE!!"
local data = {
    ["tstmp"] = 1754879805,
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
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_KeystoneGroupList"] = {
                        true,
                        ["tstmp"] = 1754852213,
                    },
                    ["LibDBIcon10_VocalRaidAssistant"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_MythicDungeonTools"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_BugSack"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_Socialite"] = {
                        ["tstmp"] = 1748255535,
                    },
                    ["LibDBIcon10_Details"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_Latency"] = {
                        ["tstmp"] = 1748479760,
                    },
                    ["LibDBIcon10_MethodRaidTools"] = {
                        true,
                        ["tstmp"] = 1754879805,
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
                        ["tstmp"] = 1754879805,
                    },
                    ["AddonCompartmentFrame"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_AlterEgo"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["_G.ExpansionLandingPageMinimapButton"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_Plater"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_Durability"] = {
                        ["tstmp"] = 1748479772,
                    },
                    ["LibDBIcon10_FPS"] = {
                        ["tstmp"] = 1748479749,
                    },
                    ["LibDBIcon10_Leatrix_Plus"] = {
                        false,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_Masque"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_ClassSpecs"] = {
                        ["tstmp"] = 1748480849,
                    },
                    ["LibDBIcon10_System"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_SylingTracker"] = {
                        ["tstmp"] = 1747421324,
                    },
                    ["LibDBIcon10_BigWigs"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_AutoQueueWA"] = {
                        true,
                        ["tstmp"] = 1752443888,
                    },
                    ["LibDBIcon10_NSRT"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_Volume"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_Dominos"] = {
                        ["tstmp"] = 1754879805,
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
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_Gold"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["LibDBIcon10_WeakAuras"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["LibDBIcon10_GPS"] = {
                        ["tstmp"] = 1748258624,
                    },
                    ["MinimapButton_D4Lib_LibDBIcon_MoveAny"] = {
                        ["tstmp"] = 1748940699,
                    },
                    ["LibDBIcon10_TipTac"] = {
                        true,
                        ["tstmp"] = 1747441096,
                    },
                },
                ["btnSettings"] = {
                    ["HidingBar"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["AlterEgo"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["Prat"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["WeakAuras"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["MRT"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["NSRT"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["Raven"] = {
                        ["tstmp"] = 1749060648,
                    },
                    ["BigWigs"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["BtWQuests"] = {
                        true,
                        ["tstmp"] = 1754879805,
                    },
                    ["Bartender4"] = {
                        ["tstmp"] = 1750200829,
                    },
                    ["Krowi_ExtendedVendorUILDB"] = {
                        ["tstmp"] = 1747930734,
                    },
                    ["Dominos"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["Masque"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["RaiderIO"] = {
                        ["tstmp"] = 1754879805,
                    },
                    ["TipTac"] = {
                        ["tstmp"] = 1747441096,
                    },
                    ["SylingTracker"] = {
                        ["tstmp"] = 1747421324,
                    },
                    ["VocalRaidAssistant"] = {
                        ["tstmp"] = 1754879805,
                    },
                },
                ["grabMinimap"] = true,
                ["grabMinimapAfterN"] = 1,
                ["customGrabList"] = {
                    "AddonCompartmentFrame",
                    "_G.ExpansionLandingPageMinimapButton",
                },
                ["ombGrabQueue"] = {
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
                        ["lineWidth"] = 5,
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
                            0,
                            0,
                            0,
                            1,
                        },
                        ["anchor"] = "right",
                        ["lineTexture"] = "Cronix",
                        ["barTypePosition"] = 0,
                        ["size"] = 15,
                        ["interceptTooltipPosition"] = 0,
                        ["petBattleHide"] = true,
                        ["lineColor"] = {
                            0.1647058823529412,
                            0.7333333333333333,
                            1,
                        },
                        ["position"] = 604.2999367833108,
                        ["mbtnPosition"] = 2,
                        ["lineBorderEdge"] = false,
                        ["lineBorderOffset"] = 0,
                        ["showHandler"] = 2,
                        ["expand"] = 2,
                        ["borderEdge"] = false,
                        ["bgColor"] = {
                            0.1,
                            0.1,
                            0.1,
                            0.7,
                        },
                        ["borderSize"] = 1,
                        ["gapSize"] = 1,
                        ["interceptTooltip"] = true,
                        ["buttonDirection"] = {
                            ["V"] = 0,
                            ["H"] = 0,
                        },
                        ["borderOffset"] = 0,
                        ["omb"] = {
                            ["distanceToBar"] = 0,
                            ["hide"] = true,
                            ["fadeOpacity"] = 1,
                            ["anchor"] = "right",
                            ["barDisplacement"] = 0,
                            ["canGrabbed"] = false,
                            ["size"] = 31,
                        },
                        ["buttonSize"] = 36,
                        ["frameStrata"] = 2,
                        ["lineBorderSize"] = 2,
                        ["fadeOpacity"] = 0.2,
                        ["orientation"] = 0,
                        ["barOffset"] = 2,
                        ["hideDelay"] = 0.75,
                        ["rangeBetweenBtns"] = 4,
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
    importText = importText,
    importTwink = function() return end
})
