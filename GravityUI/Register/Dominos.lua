local addon, private = ...
-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
importTwink = Twinkinstallation Process 
}
]]

local addonName = "Dominos"
local importText = "Import"
local data = {
    ["frames"] = {
        {
            ["point"] = "BOTTOM",
            ["scale"] = 0.8,
            ["unit"] = "none",
            ["padW"] = 2,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
            ["fadeOutDelay"] = false,
            ["x"] = 0.0003356933592613132,
            ["y"] = 84.44455718994139,
            ["fadeInDuration"] = 0.1000000014901161,
            ["padH"] = 2,
            ["fadeInDelay"] = false,
            ["pages"] = {
                ["WARRIOR"] = {
                    ["page2"] = 1,
                    ["page5"] = 4,
                    ["page4"] = 3,
                    ["dragonriding"] = 10,
                    ["page3"] = 2,
                    ["page6"] = 5,
                },
            },
            ["rowSpacing"] = 0,
        },
        {
            ["point"] = "BOTTOM",
            ["scale"] = 0.8,
            ["y"] = 69,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = -0.0002746582032386868,
            ["anchor"] = {
                ["relFrame"] = 1,
                ["point"] = "BOTTOMLEFT",
                ["relPoint"] = "TOPLEFT",
            },
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "BOTTOM",
            ["scale"] = 0.8,
            ["y"] = 200.0001220703125,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = 0.000762939453125,
            ["padH"] = 2,
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = 2,
                ["point"] = "BOTTOMRIGHT",
                ["relPoint"] = "TOPRIGHT",
            },
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "BOTTOM",
            ["scale"] = 0.8,
            ["y"] = 249.0001068115234,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = 0.000762939453125,
            ["padH"] = 2,
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = 3,
                ["point"] = "BOTTOMRIGHT",
                ["relPoint"] = "TOPRIGHT",
            },
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["columns"] = 6,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["scale"] = 0.7,
            ["x"] = -39.42821393694203,
            ["point"] = "BOTTOMRIGHT",
            ["unit"] = "none",
            ["padW"] = 2,
            ["relPoint"] = "BOTTOM",
            ["fadeAlpha"] = 0,
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["columns"] = 6,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["scale"] = 0.7,
            ["x"] = 39.42926897321416,
            ["point"] = "BOTTOMLEFT",
            ["unit"] = "none",
            ["padW"] = 2,
            ["relPoint"] = "BOTTOM",
            ["fadeAlpha"] = 0,
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "BOTTOMLEFT",
            ["scale"] = 0.75,
            ["unit"] = "none",
            ["padW"] = 2,
            ["fadeAlpha"] = 0,
            ["spacing"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 4,
            ["displayLayer"] = "LOW",
            ["y"] = 300.4444885253906,
            ["x"] = 626.9635620117188,
            ["displayLevel"] = 1,
            ["padH"] = 2,
            ["rowOffset"] = -1,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["rowSpacing"] = 0,
        },
        {
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["point"] = "BOTTOMLEFT",
            ["columns"] = 2,
            ["scale"] = 0.75,
            ["fadeAlpha"] = 0,
            ["rowOffset"] = 0,
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = 625.7781982421875,
            ["y"] = 10.51838111877441,
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPRIGHT",
            ["scale"] = 0.75,
            ["unit"] = "none",
            ["padW"] = 2,
            ["showstates"] = "",
            ["spacing"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
            ["columns"] = 2,
            ["y"] = -248.742177327474,
            ["relPoint"] = "RIGHT",
            ["fadeAlpha"] = 0,
            ["rowOffset"] = 0,
            ["padH"] = 2,
            ["isBottomToTop"] = true,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["x"] = -343.7040176391602,
        },
        {
            ["point"] = "BOTTOMRIGHT",
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["scale"] = 0.75,
            ["y"] = 10.51858806610107,
            ["columns"] = 2,
            ["unit"] = "none",
            ["padW"] = 2,
            ["fadeAlpha"] = 0,
            ["x"] = -343.7037734985352,
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPLEFT",
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["y"] = -155.0000228881836,
            ["hidden"] = true,
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = 1.999937057495117,
            ["padH"] = 2,
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = "talk",
                ["point"] = "TOP",
                ["relPoint"] = "BOTTOM",
            },
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPLEFT",
            ["y"] = -155.0000724792481,
            ["hidden"] = true,
            ["unit"] = "none",
            ["padW"] = 2,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["anchor"] = {
                ["relFrame"] = "talk",
                ["point"] = "TOPLEFT",
                ["relPoint"] = "BOTTOMLEFT",
            },
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPLEFT",
            ["y"] = -155.0000228881836,
            ["hidden"] = true,
            ["unit"] = "none",
            ["padW"] = 2,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["anchor"] = {
                ["relFrame"] = "talk",
                ["point"] = "TOPLEFT",
                ["relPoint"] = "BOTTOMLEFT",
            },
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPLEFT",
            ["y"] = -155.0000228881836,
            ["hidden"] = true,
            ["unit"] = "none",
            ["padW"] = 2,
            ["pages"] = {
                ["WARRIOR"] = {
                },
            },
            ["padH"] = 2,
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = "talk",
                ["point"] = "TOPLEFT",
                ["relPoint"] = "BOTTOMLEFT",
            },
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
        },
        ["alerts"] = {
            ["point"] = "TOPRIGHT",
            ["scale"] = 0.8,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 2,
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "MEDIUM",
            ["showInPetBattleUI"] = true,
            ["columns"] = 1,
            ["showInOverrideUI"] = true,
            ["y"] = -55.99986267089847,
            ["relPoint"] = "CENTER",
            ["fadeInDelay"] = false,
            ["x"] = -232.9999694824218,
            ["fadeOutDelay"] = false,
        },
        ["talk"] = {
            ["showInPetBattleUI"] = true,
            ["point"] = "TOPLEFT",
            ["scale"] = 1,
            ["showInOverrideUI"] = true,
            ["fadeOutDelay"] = false,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["y"] = 3.0517578125e-05,
            ["fadeInDelay"] = false,
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "LOW",
        },
        ["exp"] = {
            ["point"] = "TOPRIGHT",
            ["scale"] = 1,
            ["lockMode"] = true,
            ["padW"] = 2,
            ["showstates"] = "",
            ["hideAtMaxLevel"] = true,
            ["spacing"] = 1,
            ["alwaysShowText"] = true,
            ["displayLayer"] = "BACKGROUND",
            ["columns"] = 20,
            ["font"] = "Cronix",
            ["width"] = 240,
            ["y"] = -292.0000820159912,
            ["x"] = -8.888916015625,
            ["displayLevel"] = 1,
            ["numButtons"] = 20,
            ["display"] = {
                ["label"] = true,
                ["max"] = true,
                ["value"] = true,
                ["percent"] = true,
                ["bonus"] = true,
            },
            ["padH"] = 2,
            ["height"] = 12,
            ["texture"] = "Cronix",
        },
        ["possess"] = {
            ["point"] = "BOTTOMLEFT",
            ["scale"] = 1,
            ["padW"] = 2,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 4,
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "MEDIUM",
            ["fadeOutDelay"] = false,
            ["x"] = 258.2225341796875,
            ["relPoint"] = "BOTTOM",
            ["rowOffset"] = 0,
            ["padH"] = 2,
            ["fadeInDelay"] = false,
            ["y"] = 86.00003814697266,
            ["rowSpacing"] = 0,
        },
        ["bags"] = {
            ["point"] = "BOTTOMRIGHT",
            ["scale"] = 1,
            ["keyRing"] = false,
            ["rowOffset"] = 0,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 2,
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "LOW",
            ["oneBag"] = true,
            ["hidden"] = true,
            ["fadeOutDelay"] = false,
            ["x"] = -0.0001983642578125,
            ["fadeInDelay"] = false,
            ["rowSpacing"] = 0,
        },
        ["pet"] = {
            ["point"] = "BOTTOMRIGHT",
            ["scale"] = 0.9,
            ["rowOffset"] = 0,
            ["fadeAlpha"] = 0,
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 6,
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "MEDIUM",
            ["columns"] = 6,
            ["y"] = 300.3333435058593,
            ["x"] = -246.6050771077474,
            ["relPoint"] = "BOTTOM",
            ["showstates"] = "",
            ["fadeInDelay"] = false,
            ["fadeOutDelay"] = false,
            ["rowSpacing"] = 0,
        },
        ["queue"] = {
            ["y"] = -219.9999771118164,
            ["x"] = -197.7776870727539,
            ["point"] = "TOPRIGHT",
            ["displayLayer"] = "MEDIUM",
        },
        ["cast"] = {
            ["point"] = "TOP",
            ["scale"] = 1,
            ["padW"] = 1,
            ["fadeAlpha"] = 0,
            ["fadeOutDuration"] = 0.1000000014901161,
            ["h"] = 32,
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "HIGH",
            ["showInPetBattleUI"] = true,
            ["latencyPadding"] = 80,
            ["useSpellReactionColors"] = true,
            ["padH"] = 1,
            ["w"] = 240,
            ["showInOverrideUI"] = true,
            ["alpha"] = 0,
            ["fadeOutDelay"] = false,
            ["y"] = -239.9999923706055,
            ["x"] = 6.103515625e-05,
            ["relPoint"] = "CENTER",
            ["font"] = "Friz Quadrata TT",
            ["display"] = {
                ["time"] = true,
                ["spark"] = true,
                ["icon"] = false,
                ["border"] = true,
                ["latency"] = true,
            },
            ["fadeInDelay"] = false,
            ["texture"] = "blizzard",
            ["showstates"] = "",
        },
        ["mirrorTimer2"] = {
            ["point"] = "TOP",
            ["w"] = 206,
            ["texture"] = "Blizzard",
            ["y"] = -122,
            ["x"] = 0,
            ["h"] = 26,
            ["font"] = "Friz Quadrata TT",
            ["display"] = {
                ["border"] = true,
                ["time"] = false,
                ["spark"] = false,
                ["label"] = true,
            },
            ["padH"] = 1,
            ["padW"] = 1,
            ["displayLayer"] = "HIGH",
        },
        ["menu"] = {
            ["x"] = 328.89013671875,
            ["point"] = "BOTTOMLEFT",
            ["relPoint"] = "BOTTOM",
            ["scale"] = 1,
            ["displayLayer"] = "LOW",
            ["fadeInDuration"] = 0.1000000014901161,
            ["fadeAlpha"] = 0,
            ["fadeOutDelay"] = false,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 0,
            ["rowOffset"] = 0,
            ["fadeInDelay"] = false,
            ["displayLevel"] = 1,
            ["rowSpacing"] = 0,
        },
        ["mirrorTimer3"] = {
            ["point"] = "TOP",
            ["w"] = 206,
            ["texture"] = "Blizzard",
            ["y"] = -148,
            ["x"] = 0,
            ["h"] = 26,
            ["font"] = "Friz Quadrata TT",
            ["display"] = {
                ["border"] = true,
                ["time"] = false,
                ["spark"] = false,
                ["label"] = true,
            },
            ["padH"] = 1,
            ["padW"] = 1,
            ["displayLayer"] = "HIGH",
        },
        ["mirrorTimer1"] = {
            ["point"] = "TOP",
            ["w"] = 206,
            ["texture"] = "Blizzard",
            ["y"] = -96,
            ["x"] = 0,
            ["h"] = 26,
            ["font"] = "Friz Quadrata TT",
            ["display"] = {
                ["border"] = true,
                ["time"] = false,
                ["spark"] = false,
                ["label"] = true,
            },
            ["padH"] = 1,
            ["padW"] = 1,
            ["displayLayer"] = "HIGH",
        },
        ["roll"] = {
            ["showInPetBattleUI"] = true,
            ["showstates"] = "",
            ["point"] = "BOTTOMRIGHT",
            ["x"] = -322.2222595214845,
            ["scale"] = 0.8,
            ["showInOverrideUI"] = true,
            ["fadeInDuration"] = 0.1000000014901161,
            ["fadeOutDelay"] = false,
            ["relPoint"] = "RIGHT",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 2,
            ["columns"] = 1,
            ["fadeInDelay"] = false,
            ["displayLevel"] = 1,
            ["displayLayer"] = "MEDIUM",
        },
        ["extra"] = {
            ["showInPetBattleUI"] = true,
            ["fadeOutDelay"] = false,
            ["point"] = "BOTTOMLEFT",
            ["hideBlizzardTeture"] = true,
            ["scale"] = 0.8,
            ["showInOverrideUI"] = true,
            ["x"] = 322.7778320312501,
            ["y"] = 158.8888702392578,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["fadeInDuration"] = 0.1000000014901161,
            ["relPoint"] = "BOTTOM",
            ["fadeInDelay"] = false,
            ["displayLevel"] = 1,
            ["displayLayer"] = "HIGH",
        },
        ["encounter"] = {
            ["showInPetBattleUI"] = true,
            ["point"] = "BOTTOM",
            ["y"] = 224.3556976318359,
            ["scale"] = 1,
            ["showInOverrideUI"] = true,
            ["x"] = 0.000152587890625,
            ["fadeOutDelay"] = false,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["fadeInDelay"] = false,
            ["anchor"] = {
                ["relPoint"] = "TOP",
                ["point"] = "BOTTOM",
                ["relFrame"] = 4,
            },
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "HIGH",
        },
    },
    ["showEmptyButtons"] = true,
    ["alignmentGrid"] = {
        ["size"] = 30,
    },
}

local function install()
    if DominosDB then
        DominosDB["char"] = {
            [private.g.cName .. " - " .. private.g.cRealm] = {
                ["bindingsVersion"] = 3,
            }
        }
       
        DominosDB["namespaces"]["ProgressBars"] = {
            ["char"] = {
                [private.g.cName .. " - " .. private.g.cRealm] =
                {
                    ["bars"] = {
                        ["exp"] = {
                            ["mode"] = "xp",
                        },
                    },
                }
            }
        }

        DominosDB["profiles"][private.g.name] = data
        DominosDB["profileKeys"][private.g.cName .. " - " .. private.g.cRealm] = private.g.name
    end
end


local function importTwink()
    if DominosDB then
        DominosDB["char"] = {
            [private.g.cName .. " - " .. private.g.cRealm] = {
                ["bindingsVersion"] = 3,
            }
        }
       
        DominosDB["namespaces"]["ProgressBars"] = {
            ["char"] = {
                [private.g.cName .. " - " .. private.g.cRealm] =
                {
                    ["bars"] = {
                        ["exp"] = {
                            ["mode"] = "xp",
                        },
                    },
                }
            }
        }
        DominosDB["profileKeys"][private.g.cName .. " - " .. private.g.cRealm] = private.g.name
    end
end
table.insert(private.Addons, {
    name = addonName,
    import = install,
    importText = importText,
    importTwink = importTwink
})
