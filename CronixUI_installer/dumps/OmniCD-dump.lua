local Addon, private = ...

local CronixUI = {
    ["Party"] = {
        ["party"] = {
            ["extraBars"] = {
                ["raidBar2"] = {
                    ["locked"] = true,
                    ["enabled"] = true,
                    ["layout"] = "horizontal",
                    ["columns"] = 6,
                    ["scale"] = 0.96,
                    ["manualPos"] = {
                        ["raidBar2"] = {
                            ["y"] = 317.6334720942759,
                            ["x"] = 269.5669296569395,
                        },
                    },
                },
                ["raidBar1"] = {
                    ["statusBarWidth"] = 230,
                    ["showRaidTargetMark"] = true,
                    ["growUpward"] = true,
                    ["locked"] = true,
                    ["manualPos"] = {
                        ["raidBar1"] = {
                            ["y"] = 437.0999807476983,
                            ["x"] = 270.1008469144836,
                        },
                    },
                    ["scale"] = 0.75,
                },
            },
            ["general"] = {
                ["showPlayer"] = true,
            },
            ["spells"] = {
                ["363916"] = false,
                ["216331"] = false,
                ["118038"] = false,
                ["198589"] = false,
                ["1022"] = false,
                ["8122"] = false,
                ["235219"] = false,
                ["5246"] = false,
                ["221562"] = true,
                ["115203"] = false,
                ["209258"] = false,
                ["108968"] = false,
                ["404381"] = false,
                ["122783"] = false,
                ["231895"] = false,
                ["122278"] = false,
                ["363534"] = false,
                ["61336"] = false,
                ["23920"] = false,
                ["45438"] = false,
                ["31230"] = false,
                ["328530"] = true,
                ["31935"] = false,
                ["186265"] = false,
                ["48792"] = false,
                ["203720"] = true,
                ["122470"] = false,
                ["48707"] = false,
                ["265202"] = false,
                ["64843"] = false,
                ["196718"] = false,
                ["31224"] = false,
                ["108280"] = false,
                ["342245"] = false,
                ["740"] = false,
                ["374251"] = true,
                ["360194"] = false,
                ["193530"] = true,
                ["871"] = false,
                ["47536"] = false,
                ["114556"] = false,
                ["200806"] = true,
                ["86949"] = false,
                ["19574"] = true,
                ["5277"] = false,
                ["322118"] = true,
                ["196555"] = false,
                ["47585"] = false,
                ["642"] = false,
            },
            ["icons"] = {
                ["scale"] = 1.12,
                ["desaturateActive"] = true,
                ["markEnhanced"] = false,
                ["showTooltip"] = true,
            },
            ["position"] = {
                ["offsetX"] = 1,
                ["anchor"] = "TOPRIGHT",
                ["paddingY"] = 1,
                ["columns"] = 4,
                ["paddingX"] = 1,
                ["attach"] = "TOPLEFT",
                ["maxNumIcons"] = 4,
                ["preset"] = "TOPLEFT",
            },
            ["spellFrame"] = {
                [196718] = 0,
            },
            ["highlight"] = {
                ["glowBuffTypes"] = {
                    ["offensive"] = true,
                },
                ["glow"] = false,
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
            ["manualPos"] = {
                ["raidCDBar2"] = {
                    ["y"] = 275.5551344944179,
                    ["x"] = 45.86719465872011,
                },
            },
            ["spells"] = {
                ["374227"] = false,
                ["6940"] = true,
                ["740"] = false,
                ["204018"] = true,
                ["31821"] = false,
                ["196718"] = false,
                ["62618"] = false,
                ["108280"] = false,
                ["186265"] = false,
                ["196555"] = false,
                ["51052"] = false,
                ["64843"] = false,
                ["10060"] = true,
                ["45438"] = false,
                ["642"] = false,
                ["98008"] = false,
                ["97462"] = false,
                ["388007"] = true,
                ["265202"] = false,
                ["115310"] = false,
                ["363534"] = false,
            },
            ["icons"] = {
                ["counterScale"] = 0.7000000000000001,
                ["showForbearanceCounter"] = false,
                ["scale"] = 0.96,
                ["desaturateActive"] = true,
                ["markEnhanced"] = false,
                ["chargeScale"] = 0.9,
            },
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
            ["position"] = {
                ["offsetX"] = 2,
            },
            ["priority"] = {
                ["offensive"] = 9,
                ["immunity"] = 12,
            },
            ["general"] = {
                ["showPlayerEx"] = false,
                ["showPlayer"] = true,
                ["zoneSelected"] = "party",
                ["showRange"] = true,
            },
            ["highlight"] = {
                ["glowBuffs"] = false,
            },
        },
        ["visibility"] = {
            ["arena"] = false,
            ["size"] = 40,
        },
    },
    ["General"] = {
        ["fonts"] = {
            ["statusBar"] = {
                ["font"] = "Cronix",
                ["flag"] = "OUTLINE",
                ["size"] = 18,
            },
            ["icon"] = {
                ["font"] = "Cronix",
                ["ofsX"] = 1,
            },
            ["anchor"] = {
                ["font"] = "Cronix",
                ["flag"] = "OUTLINE",
            },
        },
        ["textures"] = {
            ["statusBar"] = {
                ["BG"] = "Cronix",
                ["bar"] = "Cronix",
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