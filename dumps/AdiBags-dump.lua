Addon, private = ...

local Adiprofile = "croniXUI"

local AdiBagsDump = {
	["namespaces"] = {
		["ItemLevel"] = {
		},
		["FilterOverride"] = {
			["profiles"] = {
				["Default"] = {
					["version"] = 3,
					["overrides"] = {
						[45047] = "Consumable#Explosives and Devices",
						[204001] = "Tradeskill#Gem",
						[168965] = "Trinkets#Trinkets",
						[189841] = "Rings#Rings",
						[194699] = "Equipment#Profession Equipment",
						[204002] = "Tradeskill#Gem",
						[204018] = "Tradeskill#Gem",
						[204193] = "Tradeskill#Other",
						[204019] = "Tradeskill#Gem",
						[191335] = "Consumable#Flask",
						[171285] = "Item Enhancement#Item Enhancement",
						[191002] = "Class Set Tokens#Class Set Tokens",
						[71153] = "Miscellaneous#Miscellaneous",
						[173048] = "New#Raid",
						[204195] = "Tradeskill#Other",
						[191003] = "Class Set Tokens#Class Set Tokens",
						[190384] = "New#Raid",
						[169064] = "Equipment#Armor",
						[116421] = "Miscellaneous#Miscellaneous",
						[180653] = "New#M+ Key",
						[173049] = "New#Raid",
						[173065] = "Miscellaneous#Miscellaneous",
						[194703] = "Equipment#Profession Equipment",
						[201323] = "Miscellaneous#Miscellaneous",
						[204006] = "Tradeskill#Gem",
						[204022] = "Tradeskill#Gem",
						[204007] = "Tradeskill#Gem",
						[201325] = "New#Raid",
						[142159] = "Trinkets#Trinkets",
						[110017] = "Trinkets#Trinkets",
						[191007] = "Class Set Tokens#Class Set Tokens",
						[204010] = "Tradeskill#Gem",
						[187786] = "New#M+ Key",
						[180817] = "Consumable#Other",
						[181468] = "New#Raid",
						[194819] = "Item Enhancement#Item Enhancement",
						[183040] = "Equipment#Jewelry",
						[169769] = "Trinkets#Trinkets",
						[189851] = "Equipment#Weapon",
						[194820] = "Item Enhancement#Item Enhancement",
						[86143] = "Miscellaneous#Miscellaneous",
						[124640] = "Consumable#Potion",
						[171437] = "Item Enhancement#Item Enhancement",
						[204013] = "Tradeskill#Gem",
						[191329] = "Consumable#Flask",
						[187805] = "Consumable#Vantus Runes",
						[204076] = "Tradeskill#Other",
						[204075] = "Tradeskill#Other",
						[189827] = "Equipment#Armor",
						[195489] = "Equipment#Set: Frost",
						[204014] = "Tradeskill#Gem",
						[178818] = "Equipment#Armor",
						[171280] = "New#Raid",
						[186662] = "Consumable#Vantus Runes",
						[171439] = "Item Enhancement#Item Enhancement",
						[194823] = "Item Enhancement#Item Enhancement",
						[191837] = "Miscellaneous#Other",
						[132514] = "New#Raid",
						[204015] = "Tradeskill#Gem",
						[172043] = "New#Raid",
						[109076] = "Consumable#Explosives and Devices",
						[204029] = "Tradeskill#Gem",
						[171276] = "New#Raid",
						[204005] = "Tradeskill#Gem",
						[190487] = "Equipment#Weapon",
						[195505] = "Equipment#Set: Frost",
						[188761] = "Miscellaneous#Miscellaneous",
						[194817] = "Item Enhancement#Item Enhancement",
					},
				},
				["croniXUI"] = {
					["version"] = 3,
					["overrides"] = {
						[45047] = "Consumable#Explosives and Devices",
						[204001] = "Tradeskill#Gem",
						[168965] = "Trinkets#Trinkets",
						[189841] = "Rings#Rings",
						[194699] = "Equipment#Profession Equipment",
						[204002] = "Tradeskill#Gem",
						[204018] = "Tradeskill#Gem",
						[204193] = "Tradeskill#Other",
						[204019] = "Tradeskill#Gem",
						[191335] = "Consumable#Flask",
						[171285] = "Item Enhancement#Item Enhancement",
						[191002] = "Class Set Tokens#Class Set Tokens",
						[71153] = "Miscellaneous#Miscellaneous",
						[173048] = "New#Raid",
						[204195] = "Tradeskill#Other",
						[191003] = "Class Set Tokens#Class Set Tokens",
						[190384] = "New#Raid",
						[169064] = "Equipment#Armor",
						[116421] = "Miscellaneous#Miscellaneous",
						[180653] = "New#M+ Key",
						[173049] = "New#Raid",
						[173065] = "Miscellaneous#Miscellaneous",
						[194703] = "Equipment#Profession Equipment",
						[201323] = "Miscellaneous#Miscellaneous",
						[204006] = "Tradeskill#Gem",
						[204022] = "Tradeskill#Gem",
						[204007] = "Tradeskill#Gem",
						[201325] = "New#Raid",
						[142159] = "Trinkets#Trinkets",
						[110017] = "Trinkets#Trinkets",
						[191007] = "Class Set Tokens#Class Set Tokens",
						[204010] = "Tradeskill#Gem",
						[187786] = "New#M+ Key",
						[180817] = "Consumable#Other",
						[181468] = "New#Raid",
						[194819] = "Item Enhancement#Item Enhancement",
						[183040] = "Equipment#Jewelry",
						[169769] = "Trinkets#Trinkets",
						[189851] = "Equipment#Weapon",
						[194820] = "Item Enhancement#Item Enhancement",
						[86143] = "Miscellaneous#Miscellaneous",
						[124640] = "Consumable#Potion",
						[171437] = "Item Enhancement#Item Enhancement",
						[204013] = "Tradeskill#Gem",
						[191329] = "Consumable#Flask",
						[187805] = "Consumable#Vantus Runes",
						[194817] = "Item Enhancement#Item Enhancement",
						[188761] = "Miscellaneous#Miscellaneous",
						[195505] = "Equipment#Set: Frost",
						[195489] = "Equipment#Set: Frost",
						[204014] = "Tradeskill#Gem",
						[190487] = "Equipment#Weapon",
						[171280] = "New#Raid",
						[178818] = "Equipment#Armor",
						[171439] = "Item Enhancement#Item Enhancement",
						[194823] = "Item Enhancement#Item Enhancement",
						[186662] = "Consumable#Vantus Runes",
						[204029] = "Tradeskill#Gem",
						[204015] = "Tradeskill#Gem",
						[109076] = "Consumable#Explosives and Devices",
						[172043] = "New#Raid",
						[132514] = "New#Raid",
						[204075] = "Tradeskill#Other",
						[191837] = "Miscellaneous#Other",
						[171276] = "New#Raid",
						[204005] = "Tradeskill#Gem",
						[189827] = "Equipment#Armor",
						[204076] = "Tradeskill#Other",
					},
				},
			},
		},
		["ItemCategory"] = {
			["profiles"] = {
				["Default"] = {
					["splitBySubclass"] = {
						["Recipe"] = false,
						["Consumable"] = true,
						["Gem"] = true,
						["Tradeskill"] = true,
						["Glyph"] = true,
						["Miscellaneous"] = true,
					},
				},
				["croniXUI"] = {
					["splitBySubclass"] = {
						["Recipe"] = false,
						["Tradeskill"] = true,
						["Gem"] = true,
						["Consumable"] = true,
						["Glyph"] = true,
						["Miscellaneous"] = true,
					},
				},
			},
		},
		["NewItem"] = {
		},
		["MoneyFrame"] = {
		},
		["AdiBags_TooltipInfo"] = {
		},
		["Equipment"] = {
			["profiles"] = {
				["Default"] = {
					["dispatchRule"] = "slot",
				},
				["croniXUI"] = {
					["dispatchRule"] = "slot",
				},
			},
		},
		["CurrencyFrame"] = {
			["profiles"] = {
				["Default"] = {
					["shown"] = {
						["Mark of the World Tree"] = false,
						["Brawler's Gold"] = false,
						["Cyphers of the First Ones"] = false,
						["Sinstone Fragments"] = false,
						["Nethershard"] = false,
						["Valor"] = false,
						["Illustrious Jewelcrafter's Token"] = false,
						["Garrison Resources"] = false,
						["Order Resources"] = false,
						["Echoes of Battle"] = false,
						["Cataloged Research"] = false,
						["Honorbound Service Medal"] = false,
						["Elemental Overflow"] = true,
						["Mote of Darkness"] = false,
						["Stygian Ember"] = false,
						["Argent Commendation"] = false,
						["War Resources"] = false,
						["Cosmic Flux"] = false,
						["Soul Cinders"] = false,
						["Sightless Eye"] = false,
						["Coalescing Visions"] = false,
						["Essence of Corrupted Deathwing"] = false,
						["Grateful Offering"] = false,
						["Mogu Rune of Fate"] = false,
						["Dragon Isles Supplies"] = true,
						["Reservoir Anima"] = false,
						["Veiled Argunite"] = false,
						["Lingering Soul Fragment"] = false,
						["Tower Knowledge"] = false,
						["Warforged Seal"] = false,
						["Ironpaw Token"] = false,
						["Timeless Coin"] = false,
						["Stygia"] = false,
						["Seafarer's Dubloon"] = false,
						["Seal of Broken Fate"] = false,
						["Timeworn Artifact"] = false,
						["Lesser Charm of Good Fortune"] = false,
						["Infused Ruby"] = false,
						["Seal of Wartorn Fate"] = false,
						["Artifact Fragment"] = false,
						["Curious Coin"] = false,
						["Dalaran Jewelcrafter's Token"] = false,
						["Seal of Tempered Fate"] = false,
						["Soul Ash"] = false,
						["Timewarped Badge"] = false,
						["Ancient Mana"] = false,
						["Seal of Inevitable Fate"] = false,
						["Prismatic Manapearl"] = false,
						["Honor"] = false,
						["Epicurean's Award"] = false,
						["Echoes of Ny'alotha"] = false,
						["Oil"] = false,
						["Wakening Essence"] = false,
						["Corrupted Mementos"] = false,
						["Apexis Crystal"] = false,
						["Darkmoon Prize Ticket"] = false,
						["Titan Residuum"] = false,
						["Tol Barad Commendation"] = false,
						["Elder Charm of Good Fortune"] = false,
						["Champion's Seal"] = false,
						["Legionfall War Supplies"] = false,
					},
					["text"] = {
						["size"] = 14,
					},
					["width"] = 8,
				},
				["croniXUI"] = {
					["shown"] = {
						["Mark of the World Tree"] = false,
						["Mogu Rune of Fate"] = false,
						["Cyphers of the First Ones"] = false,
						["Sinstone Fragments"] = false,
						["Tower Knowledge"] = false,
						["Valor"] = false,
						["Illustrious Jewelcrafter's Token"] = false,
						["Garrison Resources"] = false,
						["Order Resources"] = false,
						["Veiled Argunite"] = false,
						["Warforged Seal"] = false,
						["Cosmic Flux"] = false,
						["Elemental Overflow"] = true,
						["War Resources"] = false,
						["Legionfall War Supplies"] = false,
						["Argent Commendation"] = false,
						["Mote of Darkness"] = false,
						["Elder Charm of Good Fortune"] = false,
						["Soul Cinders"] = false,
						["Sightless Eye"] = false,
						["Coalescing Visions"] = false,
						["Essence of Corrupted Deathwing"] = false,
						["Grateful Offering"] = false,
						["Tol Barad Commendation"] = false,
						["Dragon Isles Supplies"] = true,
						["Reservoir Anima"] = false,
						["Titan Residuum"] = false,
						["Lingering Soul Fragment"] = false,
						["Nethershard"] = false,
						["Brawler's Gold"] = false,
						["Ironpaw Token"] = false,
						["Corrupted Mementos"] = false,
						["Stygia"] = false,
						["Oil"] = false,
						["Seal of Broken Fate"] = false,
						["Echoes of Ny'alotha"] = false,
						["Lesser Charm of Good Fortune"] = false,
						["Infused Ruby"] = false,
						["Seal of Wartorn Fate"] = false,
						["Artifact Fragment"] = false,
						["Curious Coin"] = false,
						["Prismatic Manapearl"] = false,
						["Seal of Inevitable Fate"] = false,
						["Ancient Mana"] = false,
						["Soul Ash"] = false,
						["Timewarped Badge"] = false,
						["Seal of Tempered Fate"] = false,
						["Dalaran Jewelcrafter's Token"] = false,
						["Honor"] = false,
						["Epicurean's Award"] = false,
						["Timeworn Artifact"] = false,
						["Seafarer's Dubloon"] = false,
						["Wakening Essence"] = false,
						["Timeless Coin"] = false,
						["Apexis Crystal"] = false,
						["Darkmoon Prize Ticket"] = false,
						["Echoes of Battle"] = false,
						["Cataloged Research"] = false,
						["Honorbound Service Medal"] = false,
						["Champion's Seal"] = false,
						["Stygian Ember"] = false,
					},
					["text"] = {
						["size"] = 14,
					},
					["width"] = 8,
				},
			},
		},
		["DataSource"] = {
		},
		["Shadowlands"] = {
			["profiles"] = {
				["Default"] = {
					["moveFood"] = true,
					["moveRings"] = true,
					["moveTrinkets"] = true,
					["showcoloredCategories"] = false,
				},
			},
		},
		["ItemSets"] = {
		},
		["Junk"] = {
		},
		["Hearthstones"] = {
		},
	},
	["profileKeys"] = {
		["Cnxmonk - Blackhand"] = "Default",
		["Cronîx - Blackhand"] = "croniXUI",
		["Cronìx - Blackhand"] = "Default",
	},
	["profiles"] = {
		["Blackhand"] = {
		},
		["croniXUI"] = {
			["virtualStacks"] = {
				["incomplete"] = true,
			},
			["maxHeight"] = 0.45,
			["positions"] = {
				["Backpack"] = {
					["xOffset"] = -4,
					["yOffset"] = 0.2217570245265961,
				},
				["Bank"] = {
					["xOffset"] = 78.8890151977539,
					["yOffset"] = -51.77783203125,
				},
			},
			["rightClickConfig"] = false,
			["theme"] = {
				["reagentBank"] = {
					["color"] = {
						nil, -- [1]
						0.501960813999176, -- [2]
						nil, -- [3]
						0.4602124094963074, -- [4]
					},
					["background"] = "Solid",
					["border"] = "None",
				},
				["currentTheme"] = "legacy theme",
				["backpack"] = {
					["color"] = {
						0.04313725605607033, -- [1]
						0.04313725605607033, -- [2]
						0.04313725605607033, -- [3]
						0.9376660250127316, -- [4]
					},
					["background"] = "Solid",
					["border"] = "None",
				},
				["bank"] = {
					["color"] = {
						nil, -- [1]
						0.529411792755127, -- [2]
						1, -- [3]
						0.4124674201011658, -- [4]
					},
					["background"] = "Solid",
					["border"] = "None",
				},
				["themes"] = {
					["legacy theme"] = {
						["reagentBank"] = {
							["sectionFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 0,
								["g"] = 0.8196079134941101,
								["size"] = 12,
							},
							["color"] = {
								[2] = 0.501960813999176,
								[4] = 0.4602124094963074,
							},
							["background"] = "Solid",
							["border"] = "None",
							["bagFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 1,
								["g"] = 1,
								["size"] = 15,
							},
						},
						["bank"] = {
							["sectionFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 0,
								["g"] = 0.8196079134941101,
								["size"] = 12,
							},
							["color"] = {
								nil, -- [1]
								0.529411792755127, -- [2]
								1, -- [3]
								0.4124674201011658, -- [4]
							},
							["background"] = "Solid",
							["border"] = "None",
							["bagFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 1,
								["g"] = 1,
								["size"] = 15,
							},
						},
						["backpack"] = {
							["sectionFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 0,
								["g"] = 0.8196079134941101,
								["size"] = 12,
							},
							["color"] = {
								0.04313725605607033, -- [1]
								0.04313725605607033, -- [2]
								0.04313725605607033, -- [3]
								0.9376660250127316, -- [4]
							},
							["background"] = "Solid",
							["border"] = "None",
							["bagFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 1,
								["g"] = 1,
								["size"] = 15,
							},
						},
					},
				},
			},
		},
		["Default"] = {
			["maxHeight"] = 0.45,
			["virtualStacks"] = {
				["incomplete"] = true,
			},
			["rightClickConfig"] = false,
			["positions"] = {
				["Backpack"] = {
					["xOffset"] = -4,
					["yOffset"] = 0.2217570245265961,
				},
				["Bank"] = {
					["xOffset"] = 78.8890151977539,
					["yOffset"] = -51.77783203125,
				},
			},
			["theme"] = {
				["reagentBank"] = {
					["color"] = {
						nil, -- [1]
						0.501960813999176, -- [2]
						nil, -- [3]
						0.4602124094963074, -- [4]
					},
					["background"] = "Solid",
					["border"] = "None",
				},
				["currentTheme"] = "legacy theme",
				["backpack"] = {
					["color"] = {
						0.04313725605607033, -- [1]
						0.04313725605607033, -- [2]
						0.04313725605607033, -- [3]
						0.9376660250127316, -- [4]
					},
					["background"] = "Solid",
					["border"] = "None",
				},
				["bank"] = {
					["color"] = {
						nil, -- [1]
						0.529411792755127, -- [2]
						1, -- [3]
						0.4124674201011658, -- [4]
					},
					["background"] = "Solid",
					["border"] = "None",
				},
				["themes"] = {
					["legacy theme"] = {
						["reagentBank"] = {
							["sectionFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 0,
								["g"] = 0.8196079134941101,
								["size"] = 12,
							},
							["color"] = {
								[2] = 0.501960813999176,
								[4] = 0.4602124094963074,
							},
							["background"] = "Solid",
							["border"] = "None",
							["bagFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 1,
								["g"] = 1,
								["size"] = 15,
							},
						},
						["backpack"] = {
							["sectionFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 0,
								["g"] = 0.8196079134941101,
								["size"] = 12,
							},
							["color"] = {
								0.04313725605607033, -- [1]
								0.04313725605607033, -- [2]
								0.04313725605607033, -- [3]
								0.9376660250127316, -- [4]
							},
							["background"] = "Solid",
							["border"] = "None",
							["bagFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 1,
								["g"] = 1,
								["size"] = 15,
							},
						},
						["bank"] = {
							["sectionFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 0,
								["g"] = 0.8196079134941101,
								["size"] = 12,
							},
							["color"] = {
								nil, -- [1]
								0.529411792755127, -- [2]
								1, -- [3]
								0.4124674201011658, -- [4]
							},
							["background"] = "Solid",
							["border"] = "None",
							["bagFont"] = {
								["name"] = "Naowh",
								["r"] = 1,
								["b"] = 1,
								["g"] = 1,
								["size"] = 15,
							},
						},
					},
				},
			},
		},
		["Cronìx - Blackhand"] = {
		},
	},
}

function private:AdiBagInstall()
    --change values in namespace
    for key, value in pairs(AdiBagsDump["namespaces"]) do
        if value["profiles"] ~= nil then
            if value["profiles"][Adiprofile] ~= nil then
                if AdiBagsDB["namespaces"][key]["profiles"] == nil then
                    AdiBagsDB["namespaces"][key] = {
                        ["profiles"] = value["profiles"][Adiprofile]
                    }
                else
                    AdiBagsDB["namespaces"][key]["profiles"][Adiprofile] = value["profiles"][Adiprofile]
                end
            end
        end
    end

    --setting profile key
    local name = UnitName("PLAYER")
    local realm = GetRealmName()
    AdiBagsDB["profileKeys"][name.." - "..realm] = Adiprofile

    --import rest of the profile
    AdiBagsDB["profiles"][Adiprofile] = AdiBagsDump["profiles"][Adiprofile]
    
    PluginInstallStepComplete.message = "Adibag Imported"
  	PluginInstallStepComplete:Show()

end