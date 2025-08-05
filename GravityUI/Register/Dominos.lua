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
    ["showEmptyButtons"] = true,
    ["alignmentGrid"] = {
        ["size"] = 30,
    },
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
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                    ["page2"] = 1,
                    ["page5"] = 4,
                    ["dragonriding"] = 10,
                    ["page4"] = 3,
                    ["page3"] = 2,
                    ["page6"] = 5,
                },
                ["SHAMAN"] = {
                    ["page2"] = 1,
                    ["page5"] = 4,
                    ["dragonriding"] = 10,
                    ["page4"] = 3,
                    ["page3"] = 2,
                    ["page6"] = 5,
                },
                ["EVOKER"] = {
                    ["page2"] = 1,
                    ["dragonriding"] = 10,
                    ["page5"] = 4,
                    ["page4"] = 3,
                    ["soar"] = 7,
                    ["page3"] = 2,
                    ["page6"] = 5,
                },
                ["DEMONHUNTER"] = {
                    ["page2"] = 1,
                    ["page5"] = 4,
                    ["dragonriding"] = 10,
                    ["page4"] = 3,
                    ["page3"] = 2,
                    ["page6"] = 5,
                },
            },
            ["displayLayer"] = "LOW",
            ["numButtons"] = 12,
            ["rowOffset"] = 0,
            ["fadeOutDelay"] = false,
            ["x"] = 0.0002441406249431566,
            ["y"] = 84.44456481933594,
            ["fadeInDuration"] = 0.1000000014901161,
            ["padH"] = 2,
            ["fadeInDelay"] = false,
            ["displayLevel"] = 1,
            ["rowSpacing"] = 0,
        },
        {
            ["point"] = "BOTTOM",
            ["scale"] = 0.8,
            ["y"] = 69,
            ["numButtons"] = 12,
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = -0.0002746582032386868,
            ["padH"] = 2,
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = 1,
                ["point"] = "BOTTOMLEFT",
                ["relPoint"] = "TOPLEFT",
            },
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "BOTTOM",
            ["scale"] = 0.8,
            ["y"] = 200.0001220703125,
            ["numButtons"] = 12,
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = 0.000762939453125,
            ["anchor"] = {
                ["relFrame"] = 2,
                ["point"] = "BOTTOMRIGHT",
                ["relPoint"] = "TOPRIGHT",
            },
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "BOTTOM",
            ["scale"] = 0.8,
            ["y"] = 249.0001068115234,
            ["numButtons"] = 12,
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = 0.000762939453125,
            ["anchor"] = {
                ["relFrame"] = 3,
                ["point"] = "BOTTOMRIGHT",
                ["relPoint"] = "TOPRIGHT",
            },
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "BOTTOMRIGHT",
            ["scale"] = 0.7,
            ["unit"] = "none",
            ["padW"] = 2,
            ["fadeAlpha"] = 0,
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = 1,
                ["point"] = "TOPLEFT",
                ["relPoint"] = "BOTTOMLEFT",
            },
            ["rightClickUnit"] = "player",
            ["numButtons"] = 12,
            ["displayLayer"] = "LOW",
            ["columns"] = 6,
            ["fadeInDuration"] = 0.1000000014901161,
            ["showstates"] = "",
            ["rowOffset"] = 0,
            ["fadeOutDelay"] = false,
            ["y"] = 0.508061170578003,
            ["x"] = -26.8569248744419,
            ["relPoint"] = "BOTTOM",
            ["displayLevel"] = 1,
            ["padH"] = 2,
            ["fadeInDelay"] = false,
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["rowSpacing"] = 0,
        },
        {
            ["relPoint"] = "BOTTOM",
            ["numButtons"] = 12,
            ["point"] = "BOTTOMLEFT",
            ["padW"] = 2,
            ["scale"] = 0.7,
            ["anchor"] = {
                ["relFrame"] = 1,
                ["point"] = "TOPRIGHT",
                ["relPoint"] = "BOTTOMRIGHT",
            },
            ["fadeAlpha"] = 0,
            ["unit"] = "none",
            ["y"] = 0.508061170578003,
            ["x"] = 26.85785784040166,
            ["columns"] = 6,
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        {
            ["displayLayer"] = "LOW",
            ["displayLevel"] = 1,
            ["point"] = "BOTTOMLEFT",
            ["numButtons"] = 4,
            ["scale"] = 0.75,
            ["y"] = 300.4444885253906,
            ["rowOffset"] = -1,
            ["unit"] = "none",
            ["padW"] = 2,
            ["fadeAlpha"] = 0,
            ["x"] = 626.9635620117188,
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["rowSpacing"] = 0,
        },
        {
            ["columns"] = 2,
            ["point"] = "BOTTOMLEFT",
            ["numButtons"] = 12,
            ["scale"] = 0.75,
            ["padW"] = 2,
            ["x"] = 625.7781982421875,
            ["unit"] = "none",
            ["rowOffset"] = 0,
            ["fadeAlpha"] = 0,
            ["y"] = 10.51838111877441,
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
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
            ["x"] = -343.7040176391602,
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["padH"] = 2,
            ["isBottomToTop"] = true,
            ["rowOffset"] = 0,
            ["fadeAlpha"] = 0,
        },
        {
            ["columns"] = 2,
            ["point"] = "BOTTOMRIGHT",
            ["scale"] = 0.75,
            ["numButtons"] = 12,
            ["y"] = 10.51858806610107,
            ["unit"] = "none",
            ["padW"] = 2,
            ["fadeAlpha"] = 0,
            ["x"] = -343.7037734985352,
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPLEFT",
            ["y"] = -155.0000228881836,
            ["numButtons"] = 12,
            ["hidden"] = true,
            ["unit"] = "none",
            ["padW"] = 2,
            ["x"] = 1.999937057495117,
            ["anchor"] = {
                ["relFrame"] = "talk",
                ["point"] = "TOP",
                ["relPoint"] = "BOTTOM",
            },
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPLEFT",
            ["y"] = -155.0000724792481,
            ["hidden"] = true,
            ["unit"] = "none",
            ["padW"] = 2,
            ["numButtons"] = 12,
            ["padH"] = 2,
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = "talk",
                ["point"] = "TOPLEFT",
                ["relPoint"] = "BOTTOMLEFT",
            },
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPLEFT",
            ["y"] = -155.0000228881836,
            ["hidden"] = true,
            ["unit"] = "none",
            ["padW"] = 2,
            ["numButtons"] = 12,
            ["padH"] = 2,
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = "talk",
                ["point"] = "TOPLEFT",
                ["relPoint"] = "BOTTOMLEFT",
            },
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        {
            ["point"] = "TOPLEFT",
            ["y"] = -155.0000228881836,
            ["hidden"] = true,
            ["unit"] = "none",
            ["padW"] = 2,
            ["numButtons"] = 12,
            ["anchor"] = {
                ["relFrame"] = "talk",
                ["point"] = "TOPLEFT",
                ["relPoint"] = "BOTTOMLEFT",
            },
            ["spacing"] = 2,
            ["padH"] = 2,
            ["rightClickUnit"] = "player",
            ["pages"] = {
                ["DEATHKNIGHT"] = {
                },
                ["SHAMAN"] = {
                },
                ["EVOKER"] = {
                },
                ["DEMONHUNTER"] = {
                },
            },
            ["displayLayer"] = "LOW",
        },
        ["extra"] = {
            ["showInPetBattleUI"] = true,
            ["point"] = "BOTTOMLEFT",
            ["hideBlizzardTeture"] = true,
            ["scale"] = 0.8,
            ["showInOverrideUI"] = true,
            ["y"] = 158.8888702392578,
            ["showstates"] = "",
            ["fadeOutDelay"] = false,
            ["x"] = 322.7778320312501,
            ["fadeOutDuration"] = 0.1000000014901161,
            ["fadeInDelay"] = false,
            ["relPoint"] = "BOTTOM",
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "HIGH",
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
            ["y"] = 86.00003814697266,
            ["x"] = 258.2225341796875,
            ["relPoint"] = "BOTTOM",
            ["fadeOutDelay"] = false,
            ["padH"] = 2,
            ["fadeInDelay"] = false,
            ["rowOffset"] = 0,
            ["rowSpacing"] = 0,
        },
        ["class"] = {
            ["y"] = 224.3556976318359,
            ["relPoint"] = "BOTTOM",
            ["point"] = "BOTTOMRIGHT",
            ["spacing"] = 2,
            ["anchor"] = {
                ["relFrame"] = 4,
                ["point"] = "BOTTOMLEFT",
                ["relPoint"] = "TOPLEFT",
            },
            ["x"] = -164.3997802734375,
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
            ["texture"] = "Cronix",
            ["width"] = 240,
            ["y"] = -292.0000820159912,
            ["x"] = -8.888916015625,
            ["padH"] = 2,
            ["display"] = {
                ["label"] = true,
                ["value"] = true,
                ["max"] = true,
                ["percent"] = true,
                ["bonus"] = true,
            },
            ["height"] = 12,
            ["numButtons"] = 20,
            ["displayLevel"] = 1,
            ["font"] = "Cronix",
        },
        ["encounter"] = {
            ["showInPetBattleUI"] = true,
            ["point"] = "BOTTOM",
            ["scale"] = 1,
            ["showInOverrideUI"] = true,
            ["y"] = 224.3556976318359,
            ["x"] = 0.000152587890625,
            ["fadeOutDelay"] = false,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["fadeInDuration"] = 0.1000000014901161,
            ["anchor"] = {
                ["relPoint"] = "TOP",
                ["point"] = "BOTTOM",
                ["relFrame"] = 4,
            },
            ["fadeInDelay"] = false,
            ["displayLevel"] = 1,
            ["displayLayer"] = "HIGH",
        },
        ["bags"] = {
            ["displayLayer"] = "LOW",
            ["keyRing"] = false,
            ["point"] = "BOTTOMRIGHT",
            ["fadeInDuration"] = 0.1000000014901161,
            ["scale"] = 1,
            ["oneBag"] = true,
            ["hidden"] = true,
            ["fadeOutDelay"] = false,
            ["rowOffset"] = 0,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 2,
            ["x"] = -0.0001983642578125,
            ["fadeInDelay"] = false,
            ["displayLevel"] = 1,
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
            ["fadeOutDelay"] = false,
            ["fadeInDelay"] = false,
            ["showstates"] = "",
            ["rowSpacing"] = 0,
        },
        ["queue"] = {
            ["y"] = -219.9999771118164,
            ["x"] = -197.7776870727539,
            ["point"] = "TOPRIGHT",
            ["displayLayer"] = "MEDIUM",
        },
        ["talk"] = {
            ["showInPetBattleUI"] = true,
            ["point"] = "TOPLEFT",
            ["scale"] = 1,
            ["showInOverrideUI"] = true,
            ["y"] = 3.0517578125e-05,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["fadeOutDelay"] = false,
            ["fadeInDuration"] = 0.1000000014901161,
            ["fadeInDelay"] = false,
            ["displayLevel"] = 1,
            ["displayLayer"] = "LOW",
        },
        ["menu"] = {
            ["rowSpacing"] = 0,
            ["point"] = "BOTTOMLEFT",
            ["fadeAlpha"] = 0,
            ["scale"] = 1,
            ["fadeInDelay"] = false,
            ["rowOffset"] = 0,
            ["showstates"] = "",
            ["fadeOutDelay"] = false,
            ["relPoint"] = "BOTTOM",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 0,
            ["x"] = 328.89013671875,
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "LOW",
        },
        ["roll"] = {
            ["showInPetBattleUI"] = true,
            ["point"] = "BOTTOMRIGHT",
            ["relPoint"] = "RIGHT",
            ["scale"] = 0.8,
            ["showInOverrideUI"] = true,
            ["showstates"] = "",
            ["fadeInDelay"] = false,
            ["fadeOutDelay"] = false,
            ["x"] = -322.2222595214845,
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 2,
            ["columns"] = 1,
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "MEDIUM",
        },
        ["mirrorTimer3"] = {
            ["point"] = "TOP",
            ["w"] = 206,
            ["displayLayer"] = "HIGH",
            ["padW"] = 1,
            ["x"] = 0,
            ["y"] = -148,
            ["display"] = {
                ["border"] = true,
                ["spark"] = false,
                ["time"] = false,
                ["label"] = true,
            },
            ["padH"] = 1,
            ["font"] = "Friz Quadrata TT",
            ["h"] = 26,
            ["texture"] = "Blizzard",
        },
        ["mirrorTimer1"] = {
            ["point"] = "TOP",
            ["w"] = 206,
            ["displayLayer"] = "HIGH",
            ["padW"] = 1,
            ["x"] = 0,
            ["y"] = -96,
            ["display"] = {
                ["border"] = true,
                ["spark"] = false,
                ["time"] = false,
                ["label"] = true,
            },
            ["padH"] = 1,
            ["font"] = "Friz Quadrata TT",
            ["h"] = 26,
            ["texture"] = "Blizzard",
        },
        ["alerts"] = {
            ["showInPetBattleUI"] = true,
            ["point"] = "TOPRIGHT",
            ["columns"] = 1,
            ["fadeOutDelay"] = false,
            ["scale"] = 0.8,
            ["showInOverrideUI"] = true,
            ["fadeInDuration"] = 0.1000000014901161,
            ["x"] = -232.9999694824218,
            ["y"] = -55.99986267089847,
            ["relPoint"] = "CENTER",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["spacing"] = 2,
            ["showstates"] = "",
            ["fadeInDelay"] = false,
            ["displayLevel"] = 1,
            ["displayLayer"] = "MEDIUM",
        },
        ["mirrorTimer2"] = {
            ["point"] = "TOP",
            ["w"] = 206,
            ["displayLayer"] = "HIGH",
            ["padW"] = 1,
            ["x"] = 0,
            ["y"] = -122,
            ["display"] = {
                ["border"] = true,
                ["spark"] = false,
                ["time"] = false,
                ["label"] = true,
            },
            ["padH"] = 1,
            ["font"] = "Friz Quadrata TT",
            ["h"] = 26,
            ["texture"] = "Blizzard",
        },
        ["cast"] = {
            ["useSpellReactionColors"] = true,
            ["scale"] = 1,
            ["padW"] = 1,
            ["showstates"] = "",
            ["fadeOutDuration"] = 0.1000000014901161,
            ["texture"] = "blizzard",
            ["fadeInDuration"] = 0.1000000014901161,
            ["displayLevel"] = 1,
            ["displayLayer"] = "HIGH",
            ["showInPetBattleUI"] = true,
            ["point"] = "TOP",
            ["fadeAlpha"] = 0,
            ["display"] = {
                ["time"] = true,
                ["spark"] = true,
                ["border"] = true,
                ["icon"] = false,
                ["latency"] = true,
            },
            ["relPoint"] = "CENTER",
            ["showInOverrideUI"] = true,
            ["alpha"] = 0,
            ["x"] = 6.103515625e-05,
            ["y"] = -239.9999923706055,
            ["font"] = "Friz Quadrata TT",
            ["fadeOutDelay"] = false,
            ["w"] = 240,
            ["padH"] = 1,
            ["fadeInDelay"] = false,
            ["latencyPadding"] = 80,
            ["h"] = 32,
        },
    },
    ["useOverrideUI"] = false,
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
