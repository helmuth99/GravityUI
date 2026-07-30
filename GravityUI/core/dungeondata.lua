-- GravityUI - Dungeon Data
-- Central source for dungeon short names and teleport spells
local ADDON_NAME, ns = ...

local DungeonData = {}
ns.DungeonData = DungeonData

-- Faction-specific Spells
local factionGroup = UnitFactionGroup("player")
local SIEGE_SPELL = factionGroup == "Horde" and 464256 or 445418
local MOTHERLODE_SPELL = factionGroup == "Horde" and 467555 or 467553

---------------------------------------------------------------------------
-- NAME TO SHORT
---------------------------------------------------------------------------
local NAME_TO_SHORT = {
    -- Wrath of the Lich King
    ["Pit of Saron"] = "PIT",

    -- Mists of Pandaria
    ["Temple of the Jade Serpent"] = "TJS",
    ["Stormstout Brewery"] = "SSB",
    ["Shado-Pan Monastery"] = "SPM",
    ["Siege of Niuzao Temple"] = "SNT",
    ["Gate of the Setting Sun"] = "GOTSS",
    ["Mogu'shan Palace"] = "MSP",
    ["Scholomance"] = "SCHOLO",
    ["Scarlet Halls"] = "SH",
    ["Scarlet Monastery"] = "SM",

    -- Warlords of Draenor
    ["Bloodmaul Slag Mines"] = "BSM",
    ["Auchindoun"] = "AUCH",
    ["Skyreach"] = "SKY",
    ["Shadowmoon Burial Grounds"] = "SBG",
    ["Grimrail Depot"] = "GD",
    ["Upper Blackrock Spire"] = "UBRS",
    ["The Everbloom"] = "EB",
    ["Iron Docks"] = "ID",

    -- Legion
    ["Eye of Azshara"] = "EOA",
    ["Darkheart Thicket"] = "DT",
    ["Black Rook Hold"] = "BRH",
    ["Halls of Valor"] = "HOV",
    ["Neltharion's Lair"] = "NL",
    ["Vault of the Wardens"] = "VAULT",
    ["Maw of Souls"] = "MOS",
    ["The Arcway"] = "ARC",
    ["Court of Stars"] = "COS",
    ["Return to Karazhan: Lower"] = "LKARA",
    ["Return to Karazhan: Upper"] = "UKARA",
    ["Seat of the Triumvirate"] = "SEAT",

    -- Battle for Azeroth
    ["Atal'Dazar"] = "AD",
    ["Freehold"] = "FH",
    ["The MOTHERLODE!!"] = "ML",
    ["Waycrest Manor"] = "WM",
    ["Kings' Rest"] = "REST",
    ["Temple of Sethraliss"] = "TEMPLE",
    ["The Underrot"] = "UNDR",
    ["Shrine of the Storm"] = "SHRINE",
    ["Siege of Boralus"] = "SIEGE",
    ["Operation: Mechagon - Junkyard"] = "YARD",
    ["Operation: Mechagon - Workshop"] = "WORK",

    -- Shadowlands
    ["Mists of Tirna Scithe"] = "MISTS",
    ["The Necrotic Wake"] = "NW",
    ["De Other Side"] = "DOS",
    ["Halls of Atonement"] = "HOA",
    ["Plaguefall"] = "PF",
    ["Sanguine Depths"] = "SD",
    ["Spires of Ascension"] = "SOA",
    ["Theater of Pain"] = "TOP",
    ["Tazavesh: Streets of Wonder"] = "STRT",
    ["Tazavesh: So'leah's Gambit"] = "GMBT",

    -- Dragonflight
    ["Ruby Life Pools"] = "POOLS",
    ["The Nokhud Offensive"] = "NO",
    ["The Azure Vault"] = "AV",
    ["Algeth'ar Academy"] = "AA",
    ["Uldaman: Legacy of Tyr"] = "ULD",
    ["Neltharus"] = "NELTH",
    ["Brackenhide Hollow"] = "BH",
    ["Halls of Infusion"] = "HOI",
    ["Dawn of the Infinite: Galakrond's Fall"] = "DOTI",
    ["Dawn of the Infinite: Murozond's Rise"] = "DOTI",

    -- The War Within
    ["Priory of the Sacred Flame"] = "PSF",
    ["The Rookery"] = "ROOK",
    ["The Stonevault"] = "SV",
    ["City of Threads"] = "COT",
    ["Ara-Kara, City of Echoes"] = "ARAK",
    ["Darkflame Cleft"] = "DFC",
    ["The Dawnbreaker"] = "DAWN",
    ["Cinderbrew Meadery"] = "BREW",
    ["Grim Batol"] = "GB",
    ["Operation: Floodgate"] = "FLOOD",
    ["Eco-Dome Al'dani"] = "EDA",

    -- Cataclysm
    ["Vortex Pinnacle"] = "VP",
    ["Throne of the Tides"] = "TOTT",

    -- Midnight Season 1 (12.0)
    ["Windrunner Spire"] = "SPIRE",
    ["Magisters' Terrace"] = "MT",
    ["Nexus-Point Xenas"] = "XENAS",
    ["Maisara Caverns"] = "CAVERN",

    -- Midnight Season 2 / Sporefall (12.1)
    ["Voidscar Arena"] = "ARENA",
    ["The Blinding Vale"] = "VALE",
    ["Temple of Sethraliss"] = "TEMPLE",
    ["Ruby Life Pools"] = "POOLS",
    ["Murder Row"] = "MURDER",
    ["Kings' Rest"] = "REST",
    ["Den of Nalorakk"] = "DEN",
    ["Altar of Fangs"] = "ALTAR",
}

---------------------------------------------------------------------------
-- MAPID TO SPELL
---------------------------------------------------------------------------
local MAPID_TO_SPELL = {
    -- Wrath
    [556] = 1254555,  -- Pit of Saron

    -- MoP
    [2] = 131204,     -- Temple of the Jade Serpent
    [56] = 131205,    -- Stormstout Brewery
    [57] = 131206,    -- Shado-Pan Monastery
    [58] = 131228,    -- Siege of Niuzao Temple
    [59] = 131225,    -- Gate of the Setting Sun
    [60] = 131222,    -- Mogu'shan Palace
    [76] = 131232,    -- Scholomance
    [77] = 131231,    -- Scarlet Halls
    [78] = 131229,    -- Scarlet Monastery

    -- WoD
    [161] = 159898,   -- Skyreach (WoD spell, backwards-compat — Midnight spell is 1254557 once earned)
    [163] = 159895,   -- Bloodmaul Slag Mines (Remapped for Midnight)
    [164] = 159897,   -- Auchindoun (Remapped for Midnight)
    [165] = 159899,   -- Shadowmoon Burial Grounds
    [166] = 159900,   -- Grimrail Depot
    [167] = 159902,   -- Upper Blackrock Spire
    [168] = 159901,   -- The Everbloom
    [169] = 159896,   -- Iron Docks

    -- Legion
    [198] = 424163,   -- Darkheart Thicket
    [199] = 424153,   -- Black Rook Hold
    [200] = 393764,   -- Halls of Valor
    [206] = 410078,   -- Neltharion's Lair
    [210] = 393766,   -- Court of Stars
    [227] = 373262,   -- Lower Karazhan
    [234] = 373262,   -- Upper Karazhan
    [239] = 1254551,  -- Seat of the Triumvirate (Midnight Season 1)

    -- BfA
    [244] = 424187,   -- Atal'Dazar
    [245] = 410071,   -- Freehold
    [247] = MOTHERLODE_SPELL,
    [248] = 424167,   -- Waycrest Manor
    [251] = 410074,   -- The Underrot
    [353] = SIEGE_SPELL,
    [369] = 373274,   -- Mechagon Junkyard
    [370] = 373274,   -- Mechagon Workshop

    -- Shadowlands
    [375] = 354464,   -- Mists of Tirna Scithe
    [376] = 354462,   -- The Necrotic Wake
    [377] = 354468,   -- De Other Side
    [378] = 354465,   -- Halls of Atonement
    [379] = 354463,   -- Plaguefall
    [380] = 354469,   -- Sanguine Depths
    [381] = 354466,   -- Spires of Ascension
    [382] = 354467,   -- Theater of Pain
    [391] = 367416,   -- Tazavesh: Streets
    [392] = 367416,   -- Tazavesh: Gambit

    -- Dragonflight
    [399] = 393256,   -- Ruby Life Pools
    [400] = 393262,   -- The Nokhud Offensive
    [401] = 393279,   -- The Azure Vault
    [402] = 393273,   -- Algeth'ar Academy
    [403] = 393222,   -- Uldaman
    [404] = 393276,   -- Neltharus
    [405] = 393267,   -- Brackenhide Hollow
    [406] = 393283,   -- Halls of Infusion
    [463] = 424197,   -- DOTI Galakrond
    [464] = 424197,   -- DOTI Murozond

    -- TWW
    [499] = 445444,   -- Priory
    [500] = 445443,   -- Rookery
    [501] = 445269,   -- Stonevault
    [502] = 445416,   -- City of Threads
    [503] = 445417,   -- Ara-Kara
    [504] = 445441,   -- Darkflame Cleft
    [505] = 445414,   -- Dawnbreaker
    [506] = 445440,   -- Cinderbrew
    [507] = 445424,   -- Grim Batol
    [525] = 1216786,  -- Floodgate
    [542] = 1237215,  -- Eco-Dome

    -- Cata
    [438] = 410080,   -- Vortex Pinnacle
    [456] = 424142,   -- Throne of Tides

    -- Midnight Season 1 (12.0)
    [557] = 1254400,  -- Windrunner Spire
    [558] = 1254572,  -- Magisters' Terrace
    [559] = 1254563,  -- Nexus-Point Xenas
    [560] = 1254559,  -- Maisara Caverns

    -- Midnight Season 2 / Sporefall (12.1)
    -- Kings' Rest and Temple of Sethraliss reuse their BfA ChallengeMode MapIDs (249, 250)
    -- but get new Midnight-era teleport spells. Ruby Life Pools (399) keeps its DF spell.
    [249] = 1286831,  -- Kings' Rest
    [250] = 1286828,  -- Temple of Sethraliss
    -- [399] = 393256 already defined above (Ruby Life Pools — DF spell still valid)
    [584] = 1286801,  -- The Blinding Vale
    [585] = 1286804,  -- Voidscar Arena
    [586] = 1286807,  -- Den of Nalorakk
    [587] = 1286809,  -- Murder Row
    [588] = 1286812,  -- Altar of Fangs
}

---------------------------------------------------------------------------
-- ACCESSORS
---------------------------------------------------------------------------
function DungeonData.GetTeleportSpellID(mapID)
    return MAPID_TO_SPELL[mapID]
end

function DungeonData.GetShortName(mapID)
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    if name then
        return NAME_TO_SHORT[name] or name:sub(1, 4):upper()
    end
    return "???"
end
