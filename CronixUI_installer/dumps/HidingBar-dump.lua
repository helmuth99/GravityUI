local Addon, private = ...


local HidingBarDump = {
    ["tstmp"] = 1740606357,
    ["profiles"] = {
        {
            ["isDefault"] = true,
            ["config"] = {
                ["addFromDataBroker"] = true,
                ["mbtnSettings"] = {
                    ["LibDBIcon10_Details"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_VocalRaidAssistant"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_SimulationCraft"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["BtWQuestsMinimapButton"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_KeystoneGroupList"] = {
                        true,
                        ["tstmp"] = 1740605089,
                    },
                    ["LibDBIcon10_RaiderIO"] = {
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_MethodRaidTools"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["AddonCompartmentFrame"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_MythicDungeonTools"] = {
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_Plater"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_vGambler"] = {
                        ["tstmp"] = 1740604341,
                    },
                    ["LibDBIcon10_MinimapIcon"] = {
                        ["tstmp"] = 1740603676,
                    },
                    ["LibDBIcon10_WeakAuras"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_BugSack"] = {
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_BigWigs"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["LibDBIcon10_CrossGamblingIcon"] = {
                        ["tstmp"] = 1740606357,
                    },
                },
                ["btnSettings"] = {
                    ["RaiderIO"] = {
                        ["tstmp"] = 1740606357,
                    },
                    ["HidingBar"] = {
                        true,
                        ["tstmp"] = 1740606357,
                    },
                    ["BigWigs"] = {
                        ["tstmp"] = 1740606357,
                    },
                    ["MRT"] = {
                        ["tstmp"] = 1740606357,
                    },
                    ["BtWQuests"] = {
                        ["tstmp"] = 1740606357,
                    },
                    ["WeakAuras"] = {
                        ["tstmp"] = 1740606357,
                    },
                    ["VocalRaidAssistant"] = {
                        ["tstmp"] = 1740606357,
                    },
                },
                ["grabMinimap"] = true,
                ["grabMinimapAfterN"] = 1,
                ["customGrabList"] = {
                    "AddonCompartmentFrame",
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
                        ["size"] = 10,
                        ["interceptTooltipPosition"] = 0,
                        ["petBattleHide"] = true,
                        ["lineColor"] = {
                            0.1647058823529412,
                            0.7333333333333333,
                            1,
                        },
                        ["position"] = 630.0446910293102,
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
                            ["V"] = 0,
                            ["H"] = 0,
                        },
                        ["borderOffset"] = 4,
                        ["omb"] = {
                            ["distanceToBar"] = 0,
                            ["hide"] = true,
                            ["fadeOpacity"] = 1,
                            ["anchor"] = "right",
                            ["barDisplacement"] = 0,
                            ["canGrabbed"] = false,
                            ["size"] = 31,
                        },
                        ["buttonSize"] = 31,
                        ["frameStrata"] = 2,
                        ["lineBorderSize"] = 2,
                        ["fadeOpacity"] = 0.2,
                        ["orientation"] = 0,
                        ["barOffset"] = 2,
                        ["hideDelay"] = 0.75,
                        ["rangeBetweenBtns"] = 0,
                    },
                    ["name"] = "Bar 1",
                },
            },
        },
    },
}


function private:HidingbarInstall()
    HidingBarDB = HidingBarDump

    PluginInstallStepComplete.message = "HidingBar Imported"
    PluginInstallStepComplete:Show()
end
