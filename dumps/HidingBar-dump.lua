Addon, private = ...


local HidingBarDump = {
	["tstmp"] = 1699222317,
	["profiles"] = {
		{
			["isDefault"] = true,
			["config"] = {
				["addFromDataBroker"] = true,
				["mbtnSettings"] = {
					["LibDBIcon10_Details"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["BtWQuestsMinimapButton"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["LibDBIcon10_MethodRaidTools"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["LibDBIcon10_VocalRaidAssistant"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["LibDBIcon10_MythicDungeonTools"] = {
						["tstmp"] = 1699222317,
					},
					["LibDBIcon10_SimulationCraft"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["LibDBIcon10_DetailsStreamer"] = {
						["tstmp"] = 1691598083,
					},
					["LibDBIcon10_WeakAuras"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["LibDBIcon10_Plater"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["AddonCompartmentFrame"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["LibDBIcon10_BigWigs"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
				},
				["btnSettings"] = {
					["HidingBar"] = {
						true, -- [1]
						["tstmp"] = 1699222317,
					},
					["BigWigs"] = {
						["tstmp"] = 1699222317,
					},
					["VocalRaidAssistant"] = {
						["tstmp"] = 1699222317,
					},
					["BtWQuests"] = {
						["tstmp"] = 1699222317,
					},
					["WeakAuras"] = {
						["tstmp"] = 1699222317,
					},
					["MRT"] = {
						["tstmp"] = 1699222317,
					},
				},
				["grabMinimap"] = true,
				["grabMinimapAfterN"] = 1,
				["ombGrabQueue"] = {
				},
				["customGrabList"] = {
					"AddonCompartmentFrame", -- [1]
				},
				["ignoreMBtn"] = {
					"GatherMatePin", -- [1]
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
							1, -- [1]
							1, -- [2]
							1, -- [3]
							1, -- [4]
						},
						["showDelay"] = 0,
						["bgTexture"] = "Solid",
						["borderColor"] = {
							1, -- [1]
							1, -- [2]
							1, -- [3]
							1, -- [4]
						},
						["anchor"] = "right",
						["lineTexture"] = "Solid",
						["barTypePosition"] = 0,
						["size"] = 10,
						["interceptTooltipPosition"] = 0,
						["lineColor"] = {
							0.1647058823529412, -- [1]
							0.7333333333333333, -- [2]
							1, -- [3]
						},
						["position"] = 630.0446433032048,
						["mbtnPosition"] = 2,
						["lineBorderEdge"] = false,
						["lineBorderOffset"] = 1,
						["showHandler"] = 2,
						["expand"] = 2,
						["borderEdge"] = false,
						["bgColor"] = {
							0.1, -- [1]
							0.1, -- [2]
							0.1, -- [3]
							0.7, -- [4]
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
							["distanceToBar"] = 0,
							["anchor"] = "right",
							["barDisplacement"] = 0,
							["canGrabbed"] = false,
							["hide"] = true,
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
				}, -- [1]
			},
		}, -- [1]
	},
}

function private:HidingbarInstall()
    
    HidingBarDB = HidingBarDump

    PluginInstallStepComplete.message = "HidingBar Imported"
    PluginInstallStepComplete:Show()

end
