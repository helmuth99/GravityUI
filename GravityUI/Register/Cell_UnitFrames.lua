local addon, private = ...


-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
importTwink = Twinkinstallation Process 
}
]]
local addonName = "Cell_UnitFrames"
local importText = "Import"

local data = {["colors"] = {
    ["runes"] = {
        ["frostRune"] = {
            0.24,
            1,
            1,
            1,
        },
        ["bloodRune"] = {
            1,
            0.24,
            0.24,
            1,
        },
        ["unholyRune"] = {
            0.24,
            1,
            0.24,
            1,
        },
    },
    ["shieldBar"] = {
        ["overlayTexture"] = "Interface\\RaidFrame\\Shield-Fill",
        ["shieldTexture"] = "Interface\\AddOns\\Cell\\Media\\shield",
        ["overshieldReverseOffset"] = 0,
        ["overshieldColor"] = {
            0.09019607843137255,
            0.6705882352941176,
            1,
            1,
        },
        ["overshieldSize"] = 4,
        ["shieldColor"] = {
            0.4167821053913174,
            0.7903543679408997,
            1,
            1,
        },
        ["overshieldTexture"] = "Interface\\AddOns\\Cell\\Media\\overshield",
        ["overlayColor"] = {
            0.4156862745098039,
            0.788235294117647,
            1,
            1,
        },
        ["overshieldOffset"] = 4,
        ["useOverlay"] = false,
    },
    ["highlight"] = {
        ["target"] = {
            1,
            0.3,
            0.3,
            1,
        },
        ["hover"] = {
            1,
            1,
            1,
            1,
        },
    },
    ["essence"] = {
        ["1"] = {
            0.2,
            0.57,
            0.5,
            1,
        },
        ["3"] = {
            0.2,
            0.57,
            0.5,
            1,
        },
        ["2"] = {
            0.2,
            0.57,
            0.5,
            1,
        },
        ["5"] = {
            0.2,
            0.57,
            0.5,
            1,
        },
        ["4"] = {
            0.2,
            0.57,
            0.5,
            1,
        },
        ["6"] = {
            0.2,
            0.57,
            0.5,
            1,
        },
    },
    ["healPrediction"] = {
        ["color"] = {
            0,
            1,
            0.5,
            0.25,
        },
        ["overHeal"] = {
            1,
            1,
            1,
            1,
        },
        ["texture"] = "Interface\\Buttons\\WHITE8X8",
    },
    ["chi"] = {
        ["1"] = {
            0.72,
            0.77,
            0.31,
            1,
        },
        ["3"] = {
            0.49,
            0.72,
            0.38,
            1,
        },
        ["2"] = {
            0.58,
            0.74,
            0.36,
            1,
        },
        ["5"] = {
            0.26,
            0.67,
            0.46,
            1,
        },
        ["4"] = {
            0.38,
            0.7,
            0.42,
            1,
        },
        ["6"] = {
            0.13,
            0.64,
            0.5,
            1,
        },
    },
    ["castBar"] = {
        ["stageFour"] = {
            0.65,
            0.2,
            0.3,
            1,
        },
        ["nonInterruptible"] = {
            0.43,
            0.43,
            0.43,
            1,
        },
        ["stageThree"] = {
            0.54,
            0.3,
            0.3,
            1,
        },
        ["interruptible"] = {
            0.2,
            0.57,
            0.5,
            1,
        },
        ["stageTwo"] = {
            0.4,
            0.4,
            0.4,
            1,
        },
        ["stageOne"] = {
            0.3,
            0.47,
            0.45,
            1,
        },
        ["fullyCharged"] = {
            0.77,
            0.1,
            0.2,
            1,
        },
        ["background"] = {
            0,
            0,
            0,
            0.8,
        },
        ["stageZero"] = {
            0.2,
            0.57,
            0.5,
            1,
        },
        ["texture"] = "Interface\\Buttons\\WHITE8X8",
    },
    ["reaction"] = {
        ["hostile"] = {
            0.78,
            0.25,
            0.25,
            1,
        },
        ["useClassColorForPet"] = false,
        ["neutral"] = {
            0.85,
            0.77,
            0.36,
            1,
        },
        ["swapHostileHealthAndLossColors"] = false,
        ["friendly"] = {
            0.29,
            0.69,
            0.3,
            1,
        },
        ["pet"] = {
            0.29,
            0.69,
            0.3,
            1,
        },
    },
    ["classBar"] = {
        ["texture"] = "Interface\\Buttons\\WHITE8X8",
    },
    ["unitFrames"] = {
        ["backgroundAlpha"] = 1,
        ["useDeathColor"] = false,
        ["lossColor"] = {
            0.52,
            0.21,
            0.19,
            1,
        },
        ["barColor"] = {
            0.06,
            0.07,
            0.07,
            1,
        },
        ["powerBarAlpha"] = 1,
        ["lossAlpha"] = 1,
        ["deathColor"] = {
            0.47,
            0.47,
            0.47,
            1,
        },
        ["fullColor"] = {
            0.2,
            0.2,
            1,
            1,
        },
        ["useFullColor"] = false,
        ["barAlpha"] = 1,
        ["powerLossAlpha"] = 1,
    },
    ["healAbsorb"] = {
        ["absorbColor"] = {
            1,
            0.2215466216553444,
            0.2215466216553444,
            1,
        },
        ["invertColor"] = false,
        ["overabsorbTexture"] = "Interface\\AddOns\\Cell\\Media\\overabsorb",
        ["absorbTexture"] = "Interface\\AddOns\\Cell\\Media\\shield",
        ["overabsorbColor"] = {
            1,
            1,
            1,
            1,
        },
    },
    ["comboPoints"] = {
        ["1"] = {
            0.76,
            0.3,
            0.3,
            1,
        },
        ["charged"] = {
            0.15,
            0.64,
            1,
            1,
        },
        ["3"] = {
            0.82,
            0.82,
            0.3,
            1,
        },
        ["2"] = {
            0.79,
            0.56,
            0.3,
            1,
        },
        ["5"] = {
            0.43,
            0.77,
            0.3,
            1,
        },
        ["4"] = {
            0.56,
            0.79,
            0.3,
            1,
        },
        ["7"] = {
            0.36,
            0.82,
            0.54,
            1,
        },
        ["6"] = {
            0.3,
            0.76,
            0.3,
            1,
        },
    },
    ["classResources"] = {
        ["holyPower"] = {
            0.9,
            0.89,
            0.04,
            1,
        },
        ["soulShards"] = {
            0.58,
            0.51,
            0.8,
            1,
        },
        ["arcaneCharges"] = {
            0,
            0.62,
            1,
            1,
        },
    },
},
["useScaling"] = false,
["version"] = 24,
["dummyAnchors"] = {
    ["CUF_Target"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Target",
    },
    ["CUF_Boss8"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss8",
    },
    ["CUF_Boss5"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss5",
    },
    ["CUF_Boss3"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss3",
    },
    ["CUF_Boss4"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss4",
    },
    ["CUF_TargetTarget"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_TargetTarget",
    },
    ["CUF_Boss9"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss9",
    },
    ["CUF_Pet"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Pet",
    },
    ["CUF_Boss1"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss1",
    },
    ["CUF_Boss10"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss10",
    },
    ["CUF_Boss6"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss6",
    },
    ["CUF_Boss2"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss2",
    },
    ["CUF_Boss7"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Boss7",
    },
    ["CUF_Player"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Player",
    },
    ["CUF_Focus"] = {
        ["enabled"] = true,
        ["dummyName"] = "ElvUF_Focus",
    },
},
["blizzardFrames"] = {
    ["playerCastBar"] = true,
    ["pet"] = true,
    ["boss"] = true,
    ["debuffFrame"] = false,
    ["focus"] = true,
    ["target"] = true,
    ["targettarget"] = true,
    ["player"] = true,
    ["buffFrame"] = false,
},
["helpTips"] = {
    ["editModeToggle"] = true,
    ["tagHintButton_Builder"] = true,
    ["bossFramePreview"] = true,
    ["editModeOverlay"] = true,
    ["blizzardFramesToggle"] = true,
},
["masterLayout"] = "default",}

local function import()
    if CUF_DB then
        data["backups"] = CUF_DB["backups"]
        CUF_DB = data
    end
end

local function  importTwink()
    return
end

table.insert(private.Addons, {
    name = addonName,
    import = import,
    importText = importText,
    importTwink = nil
})
