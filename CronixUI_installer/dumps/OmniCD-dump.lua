Addon, private = ...

local CronixUI = {
    ["General"] = {
        ["textures"] = {
            ["statusBar"] = {
                ["BG"] = "Cronix",
                ["bar"] = "Cronix",
            },
        },
        ["fonts"] = {
            ["statusBar"] = {
                ["flag"] = "OUTLINE",
                ["font"] = "Cronix",
                ["size"] = 18,
            },
            ["icon"] = {
                ["font"] = "Cronix",
                ["ofsX"] = 1,
                ["size"] = 9,
            },
            ["anchor"] = {
                ["flag"] = "OUTLINE",
                ["font"] = "Cronix",
            },
        },
    },
    ["Party"] = {
        ["visibility"] = {
            ["size"] = 40,
            ["arena"] = false,
        },
        ["party"] = {
            ["extraBars"] = {
                ["raidBar2"] = {
                    ["enabled"] = true,
                    ["manualPos"] = {
                        ["raidBar2"] = {
                            ["y"] = 313.3668581552047,
                            ["x"] = 299.9668698297683,
                        },
                    },
                    ["locked"] = true,
                    ["layout"] = "horizontal",
                    ["columns"] = 5,
                    ["scale"] = 0.9199999999999999,
                },
                ["raidBar1"] = {
                    ["showRaidTargetMark"] = true,
                    ["growUpward"] = true,
                    ["locked"] = true,
                    ["manualPos"] = {
                        ["raidBar1"] = {
                            ["y"] = 417.3666669752856,
                            ["x"] = 299.9674374567439,
                        },
                    },
                    ["statusBarWidth"] = 231,
                },
            },
            ["highlight"] = {
                ["glow"] = false,
                ["glowBuffTypes"] = {
                    ["offensive"] = true,
                },
            },
            ["position"] = {
                ["attach"] = "TOPLEFT",
                ["maxNumIcons"] = 4,
                ["offsetX"] = 1,
                ["paddingX"] = 1,
                ["anchor"] = "TOPRIGHT",
                ["preset"] = "TOPLEFT",
                ["columns"] = 4,
                ["paddingY"] = 1,
            },
            ["general"] = {
                ["showPlayer"] = true,
            },
            ["spells"] = {
                ["328530"] = true,
                ["363916"] = false,
                ["216331"] = false,
                ["209258"] = false,
                ["118038"] = false,
                ["198589"] = false,
                ["1022"] = false,
                ["193530"] = true,
                ["404381"] = false,
                ["48792"] = false,
                ["322118"] = true,
                ["122783"] = false,
                ["86949"] = false,
                ["203720"] = true,
                ["122470"] = false,
                ["48707"] = false,
                ["23920"] = false,
                ["31224"] = false,
                ["231895"] = false,
                ["196555"] = false,
                ["360194"] = false,
                ["8122"] = false,
                ["235219"] = false,
                ["47536"] = false,
                ["363534"] = false,
                ["19574"] = true,
                ["64843"] = false,
                ["5277"] = false,
                ["61336"] = false,
                ["200806"] = true,
                ["871"] = false,
                ["122278"] = false,
                ["740"] = false,
                ["5246"] = false,
                ["342245"] = false,
                ["265202"] = false,
                ["108280"] = false,
                ["47585"] = false,
                ["114556"] = false,
                ["221562"] = true,
                ["45438"] = false,
                ["642"] = false,
                ["186265"] = false,
                ["115203"] = false,
                ["31935"] = false,
                ["31230"] = false,
                ["374251"] = true,
                ["108968"] = false,
            },
            ["icons"] = {
                ["scale"] = 0.98,
                ["desaturateActive"] = true,
                ["markEnhanced"] = false,
                ["showTooltip"] = true,
            },
            ["manualPos"] = {
                {
                    ["y"] = 384.3550042531351,
                    ["x"] = 682.3116694426026,
                },
                [5] = {
                    ["y"] = 384.3550042531351,
                    ["x"] = 682.3116694426026,
                },
            },
        },
        ["noneZoneSetting"] = "party",
        ["raid"] = {
            ["raidCDS"] = {
                ["199452"] = true,
                ["47788"] = true,
                ["357170"] = true,
                ["10060"] = true,
                ["6940"] = true,
                ["33206"] = true,
                ["102342"] = true,
                ["388007"] = true,
                ["1022"] = true,
                ["204018"] = true,
                ["116849"] = true,
            },
            ["highlight"] = {
                ["glowBuffs"] = false,
            },
            ["manualPos"] = {
                ["raidCDBar2"] = {
                    ["y"] = 275.5551344944179,
                    ["x"] = 45.86719465872011,
                },
            },
            ["position"] = {
                ["offsetX"] = 2,
            },
            ["general"] = {
                ["zoneSelected"] = "party",
                ["showPlayer"] = true,
                ["showPlayerEx"] = false,
                ["showRange"] = true,
            },
            ["spells"] = {
                ["374227"] = false,
                ["6940"] = true,
                ["740"] = false,
                ["204018"] = true,
                ["196718"] = false,
                ["62618"] = false,
                ["186265"] = false,
                ["363534"] = false,
                ["196555"] = false,
                ["51052"] = false,
                ["64843"] = false,
                ["10060"] = true,
                ["115310"] = false,
                ["45438"] = false,
                ["642"] = false,
                ["98008"] = false,
                ["265202"] = false,
                ["388007"] = true,
                ["97462"] = false,
                ["108280"] = false,
                ["31821"] = false,
            },
            ["icons"] = {
                ["counterScale"] = 0.7000000000000001,
                ["chargeScale"] = 0.9,
                ["scale"] = 0.96,
                ["showForbearanceCounter"] = false,
                ["markEnhanced"] = false,
                ["desaturateActive"] = true,
            },
            ["priority"] = {
                ["offensive"] = 9,
                ["immunity"] = 12,
            },
        },
    },
}

function private:OmniCDInstallTwink()
    local name = UnitName("PLAYER")
    local realm = GetRealmName()
    OmniCDDB["profileKeys"][name .. " - " .. realm] = private.Profilename
end
function private:OmniCDInstall()

    local resolution = private:GetResolution()

    if resolution == 1080 then
        OmniCDDB["profiles"][private.Profilename] = CronixUI
    else
        OmniCDDB["profiles"][private.Profilename] = CronixUI
    end

    local name = UnitName("PLAYER")
    local realm = GetRealmName()

    OmniCDDB["profileKeys"][name .. " - " .. realm] = private.Profilename

    PluginInstallStepComplete.message = "OmniCD Profile Imported"
    PluginInstallStepComplete:Show()

end