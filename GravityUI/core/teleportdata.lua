-- GravityUI - Teleport Data
-- Expansion-grouped teleport spells for Dungeons and Raids
local ADDON_NAME, ns = ...

local TeleportData = {}
ns.TeleportData = TeleportData

TeleportData.Expansions = {
    { id = 12, name = "Midnight" },
    { id = 11, name = "The War Within" },
    { id = 10, name = "Dragonflight" },
    { id = 9,  name = "Shadowlands" },
    { id = 8,  name = "Battle for Azeroth" },
    { id = 7,  name = "Legion" },
    { id = 6,  name = "Warlords of Draenor" },
    { id = 5,  name = "Mists of Pandaria" },
    { id = 4,  name = "Cataclysm" },
    { id = 3,  name = "Wrath of the Lich King" },
}

-- Faction-specific Spells
local factionGroup = UnitFactionGroup("player")
local SIEGE_SPELL = factionGroup == "Horde" and 464256 or 445418
local MOTHERLODE_SPELL = factionGroup == "Horde" and 467555 or 467553

TeleportData.Dungeons = {
    ["Midnight"] = {
        { name = "DON", spellID = 1255255 }, -- Den of Nalorakk
        { name = "MT",  spellID = 1254572 }, -- Magisters' Terrace
        { name = "MC",  spellID = 1255247 }, -- Maisara Caverns
        { name = "MR",  spellID = 1255250 }, -- Murder Row
        { name = "NPX", spellID = 1254563 }, -- Nexus-Point Xenas
        { name = "BV",  spellID = 1255254 }, -- The Blinding Vale
        { name = "VA",  spellID = 1255257 }, -- Voidscar Arena
        { name = "WS",  spellID = 1254840 }, -- Windrunner Spire
    },
    ["The War Within"] = {
        { name = "ARAK",  spellID = 445417 },  -- Ara-Kara
        { name = "BREW",  spellID = 445440 },  -- Cinderbrew Meadery
        { name = "COT",   spellID = 445416 },  -- City of Threads
        { name = "DFC",   spellID = 445441 },  -- Darkflame Cleft
        { name = "DAWN",  spellID = 445414 },  -- The Dawnbreaker
        { name = "EDA",   spellID = 1237215 }, -- Eco-Dome Al'dani
        { name = "FLOOD", spellID = 1216786 }, -- Operation: Floodgate
        { name = "PSF",   spellID = 445444 },  -- Priory of the Sacred Flame
        { name = "ROOK",  spellID = 445443 },  -- The Rookery
        { name = "SV",    spellID = 445269 },  -- The Stonevault
    },
    ["Dragonflight"] = {
        { name = "AA",    spellID = 393273 }, -- Algeth'ar Academy
        { name = "AV",    spellID = 393279 }, -- The Azure Vault
        { name = "BH",    spellID = 393267 }, -- Brackenhide Hollow
        { name = "DOTI",  spellID = 424197 }, -- Dawn of the Infinite
        { name = "HOI",   spellID = 393283 }, -- Halls of Infusion
        { name = "NELTH", spellID = 393276 }, -- Neltharus
        { name = "NO",    spellID = 393262 }, -- The Nokhud Offensive
        { name = "RLP",   spellID = 393256 }, -- Ruby Life Pools
        { name = "ULD",   spellID = 393222 }, -- Uldaman
    },
    ["Shadowlands"] = {
        { name = "DOS",   spellID = 354468 }, -- De Other Side
        { name = "HOA",   spellID = 354465 }, -- Halls of Atonement
        { name = "MISTS", spellID = 354464 }, -- Mists of Tirna Scithe
        { name = "NW",    spellID = 354462 }, -- The Necrotic Wake
        { name = "PF",    spellID = 354463 }, -- Plaguefall
        { name = "SD",    spellID = 354469 }, -- Sanguine Depths
        { name = "SOA",   spellID = 354466 }, -- Spires of Ascension
        { name = "TAZ",   spellID = 367416 }, -- Tazavesh
        { name = "TOP",   spellID = 354467 }, -- Theater of Pain
    },
    ["Battle for Azeroth"] = {
        { name = "AD",    spellID = 424187 }, -- Atal'Dazar
        { name = "FH",    spellID = 410071 }, -- Freehold
        { name = "MECHA", spellID = 373274 }, -- Operation: Mechagon
        { name = "ML",    spellID = MOTHERLODE_SPELL },
        { name = "SIEGE", spellID = SIEGE_SPELL },
        { name = "UNDR",  spellID = 410074 }, -- The Underrot
        { name = "WM",    spellID = 424167 }, -- Waycrest Manor
    },
    ["Legion"] = {
        { name = "BRH",  spellID = 424153 }, -- Black Rook Hold
        { name = "COS",  spellID = 393766 }, -- Court of Stars
        { name = "DT",   spellID = 424163 }, -- Darkheart Thicket
        { name = "HOV",  spellID = 393764 }, -- Halls of Valor
        { name = "KARA", spellID = 373262 }, -- Return to Karazhan
        { name = "NL",   spellID = 410078 }, -- Neltharion's Lair
        { name = "SOTT", spellID = 1254551 }, -- Seat of the Triumvirate
    },
    ["Warlords of Draenor"] = {
        { name = "AUCH", spellID = 159897 }, -- Auchindoun
        { name = "BSM",  spellID = 159895 }, -- Bloodmaul Slag Mines
        { name = "EB",   spellID = 159901 }, -- The Everbloom
        { name = "GD",   spellID = 159900 }, -- Grimrail Depot
        { name = "ID",   spellID = 159896 }, -- Iron Docks
        { name = "SBG",  spellID = 159899 }, -- Shadowmoon Burial Grounds
        { name = "SR",   spellID = 159898 }, -- Skyreach (SR is Skyreach)
        { name = "UBRS", spellID = 159902 }, -- Upper Blackrock Spire
    },
    ["Mists of Pandaria"] = {
        { name = "GOTSS", spellID = 131225 }, -- Gate of the Setting Sun
        { name = "MSP",   spellID = 131222 }, -- Mogu'shan Palace
        { name = "SCHOLO", spellID = 131232 }, -- Scholomance
        { name = "SH",    spellID = 131231 }, -- Scarlet Halls
        { name = "SM",    spellID = 131229 }, -- Scarlet Monastery
        { name = "SNT",   spellID = 131228 }, -- Siege of Niuzao Temple
        { name = "SPM",   spellID = 131206 }, -- Shado-Pan Monastery
        { name = "SSB",   spellID = 131205 }, -- Stormstout Brewery
        { name = "TJS",   spellID = 131204 }, -- Temple of the Jade Serpent
    },
    ["Cataclysm"] = {
        { name = "GB",   spellID = 445424 }, -- Grim Batol
        { name = "TOTT", spellID = 424142 }, -- Throne of the Tides
        { name = "VP",   spellID = 410080 }, -- Vortex Pinnacle
    },
    ["Wrath of the Lich King"] = {
        { name = "POS", spellID = 1254551 }, -- Pit of Saron (Placeholder ID from legacy)
    },
}

TeleportData.Raids = {
    ["The War Within"] = {
        { name = "LOU", spellID = 1226482 }, -- Liberation of Undermine
        { name = "MFO", spellID = 1239155 }, -- Manaforge Omega
    },
    ["Dragonflight"] = {
        { name = "VOTI", spellID = 432254 }, -- Vault of the Incarnates
        { name = "ATSC", spellID = 432257 }, -- Aberrus
        { name = "ATDH", spellID = 432258 }, -- Amirdrassil
    },
    ["Shadowlands"] = {
        { name = "CN",   spellID = 373190 }, -- Castle Nathria
        { name = "SOD",  spellID = 373191 }, -- Sanctum of Domination
        { name = "STFO", spellID = 373192 }, -- Sepulcher of the First Ones
    },
}
