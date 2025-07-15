local addon, private = ...


-- the following convention is applied
--[[ save private.Addons[addonName] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
}
]]
local addonName = "Prat-3.0"
local importText = "Import"
local data =  {
    ["Prat_Fading"] = {
        ["profiles"] = {
            ["Default"] = {
                ["duration"] = 60,
            },
            ["Cronix UI"] = {
                ["duration"] = 60,
            },
        },
    },
    ["Prat_Timestamps"] = {
        ["profiles"] = {
            ["Cronix UI"] = {
                ["timestampcolor"] = {
                    ["b"] = 0.6784313917160034,
                    ["g"] = 0.6784313917160034,
                    ["r"] = 0.6784313917160034,
                },
                ["formatcode"] = "%H:%M",
            },
        },
    },
    ["Prat_ServerNames"] = {
        ["profiles"] = {
            ["Cronix UI"] = {
                ["hide"] = true,
            },
        },
    },
    ["Prat_ChatTabs"] = {
        ["profiles"] = {
            ["Default"] = {
                ["on"] = true,
                ["showtabtextures"] = false,
            },
            ["Cronix UI"] = {
                ["on"] = true,
                ["showtabtextures"] = false,
            },
        },
    },
    ["Prat_PlayerNames"] = {
        ["profiles"] = {
            ["Default"] = {
                ["level"] = false,
            },
            ["Cronix UI"] = {
                ["level"] = false,
                ["subgroup"] = false,
                ["brackets"] = "None",
            },
        },
    },
    ["Prat_Editbox"] = {
        ["profiles"] = {
            ["Default"] = {
                ["edgeSize"] = 14,
                ["backgroundColor"] = {
                    ["a"] = 0.4000000059604645,
                },
                ["attach"] = "TOP",
                ["background"] = "Solid",
                ["border"] = "None",
                ["font"] = "Cronix",
            },
            ["Cronix UI"] = {
                ["edgeSize"] = 18,
                ["attach"] = "TOP",
                ["border"] = "None",
                ["font"] = "Cronix",
                ["tileSize"] = 20,
                ["borderColor"] = {
                    ["a"] = 0,
                    ["b"] = 0.5,
                    ["g"] = 0.5,
                    ["r"] = 0.5,
                },
                ["background"] = "Solid",
                ["backgroundColor"] = {
                    ["a"] = 0.6076390743255615,
                },
                ["inset"] = 1,
            },
        },
    },
    ["Prat_Frames"] = {
        ["profiles"] = {
            ["Default"] = {
                ["minchatwidthdefault"] = 250.0000152587891,
                ["maxchatheightdefault"] = 800,
                ["initialized"] = true,
            },
            ["Cronix UI"] = {
                ["minchatwidthdefault"] = 250.0000152587891,
                ["maxchatheightdefault"] = 800,
                ["initialized"] = true,
            },
        },
    },
    ["Prat_Font"] = {
        ["profiles"] = {
            ["Default"] = {
                ["rememberfont"] = true,
                ["size"] = {
                    ["ChatFrame5"] = 15,
                    ["ChatFrame4"] = 15,
                    ["ChatFrame2"] = 14,
                    ["PetBattleTab"] = 14,
                    ["WhisperTabs"] = 16,
                    ["ChatFrame1"] = 16,
                },
                ["fontface"] = "Cronix",
            },
            ["Cronix UI"] = {
                ["fontface"] = "Cronix",
                ["rememberfont"] = true,
                ["size"] = {
                    ["ChatFrame5"] = 14,
                    ["ChatFrame4"] = 14,
                    ["ChatFrame2"] = 14,
                    ["WhisperTabs"] = 16,
                    ["PetBattleTab"] = 14,
                    ["ChatFrame1"] = 15,
                },
            },
        },
    },
    ["Prat_Bubbles"] = {
        ["profiles"] = {
            ["Default"] = {
                ["fontsize"] = 8,
            },
            ["Cronix UI"] = {
                ["fontsize"] = 8,
                ["color"] = false,
                ["on"] = false,
            },
        },
    },
    ["Prat_Buttons"] = {
        ["profiles"] = {
            ["Default"] = {
                ["showBnet"] = false,
                ["showvoice"] = false,
                ["showminimize"] = false,
                ["showButtons"] = false,
            },
            ["Cronix UI"] = {
                ["showvoice"] = false,
                ["showBnet"] = false,
                ["showButtons"] = false,
                ["showminimize"] = false,
            },
        },
    },
}

local function install()
    if Prat3DB then
        for k, v in pairs(data) do
            if Prat3DB["namespaces"][k] then
                Prat3DB["namespaces"][k]["profiles"][private.g.name] =  v["profiles"]["Cronix UI"] 
            else
                Prat3DB["namespaces"][k] =  v
            end
           
        end
        Prat3DB["profileKeys"][private.g.cName .. " - " .. private.g.cRealm] = private.g.name
        Prat3DB["profiles"][private.g.name]= {
            ["modules"] = {
                {
                    ["ChatLog"] = 2,
                    ["Mentions"] = 2,
                    ["ChatTabs"] = 3,
                    ["PopupMessage"] = 2,
                    ["AltNames"] = 2,
                    ["Sounds"] = 2,
                    ["Paragraph"] = 2,
                    ["KeyBindings"] = 2,
                    ["LinkInfoIcons"] = 2,
                    ["Bubbles"] = 2,
                    ["DebugModules"] = 2,
                    ["OriginalButtons"] = 2,
                    ["Alias"] = 2,
                },
            }
        }
    end

end

table.insert(private.Addons, {
    name = addonName,
    import = install,
    importText = importText
})
