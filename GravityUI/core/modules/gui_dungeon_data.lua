local addonName, ns = ...

---------------------------------------------------------------------------
-- GETEILTE DUNGEON-DATEN
-- Zentrale Quelle der Wahrheit für Dungeon-Kurznamen und Teleport-Spells
-- Genutzt von: gui_datatexts.lua, gui_dungeon_teleport.lua, gui_mplus_timer.lua
--
-- ARCHITEKTUR:
-- - NAME_TO_SHORT: Dungeon-Name -> Abkürzung (erweiterungs-agnostisch)
-- - MAPID_TO_SPELL: mapID -> Teleport-SpellID (erweiterungs-spezifisch)
-- - GetShortName nutzt C_ChallengeMode.GetMapUIInfo(mapID) um den Dungeon-
--   Namen zu holen, schaut dann die Abkürzung nach. Das behandelt Blizzards
--   Neuabbildung von mapIDs zwischen Erweiterungen automatisch.
---------------------------------------------------------------------------

-- Fraktions-spezifische Spells
local factionGroup = UnitFactionGroup("player")
local SIEGE_SPELL = factionGroup == "Horde" and 464256 or 445418
local MOTHERLODE_SPELL = factionGroup == "Horde" and 467555 or 467553

---------------------------------------------------------------------------
-- NAME ZU KURZ-ABKÜRZUNG
-- Bereitgestellt nach Dungeon-Name (von C_ChallengeMode.GetMapUIInfo)
-- Diese Tabelle ist erweiterungs-agnostisch - Namen ändern sich nicht mit mapID-Neuabbildungen
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
    ["Kings' Rest"] = "KR",
    ["Temple of Sethraliss"] = "SETH",
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
    ["Ruby Life Pools"] = "RLP",
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

    -- Midnight (12.x)
    ["Windrunner Spire"] = "WIND",
    ["Magisters' Terrace"] = "MAGI",
    ["Nexus-Point Xenas"] = "XENAS",
    ["Maisara Caverns"] = "CAVNS",
    ["Murder Row"] = "MURDR",
    ["The Blinding Vale"] = "BLIND",
    ["Den of Nalorakk"] = "NALO",
    ["The Foraging"] = "FORAG",
    ["Voidscar Arena"] = "VSCAR",
    ["The Heart of Rage"] = "RAGE",
    ["Voidstorm"] = "VSTORM",
}

---------------------------------------------------------------------------
-- MAPID ZU TELEPORT-SPELL
-- Teleport-Spells sind an spezifische mapIDs gebunden
-- Diese Tabelle muss aktualisiert werden wenn Blizzard neue Dungeons hinzufügt oder IDs ändert
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

    -- WoD (mapID -> spellID Zuordnungen entsprechen Retail)
    [161] = 159895,   -- Bloodmaul Slag Mines
    [163] = 159897,   -- Auchindoun
    [164] = 159898,   -- Skyreach
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
    [239] = 1254551,  -- Seat of the Triumvirate

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

    -- Midnight
    [557] = 1254840,  -- Windrunner Spire
    [558] = 1254572,  -- Magisters' Terrace
    [559] = 1254563,  -- Nexus-Point Xenas
    [560] = 1255247,  -- Maisara Caverns
    -- Legacy-Datamined mapIDs (Kompatibilität)
    [15808] = 1254840,
    [15829] = 1254572,
    [16573] = 1254563,
    [16395] = 1255247,
}

---------------------------------------------------------------------------
-- ACCESSOR FUNCTIONS
---------------------------------------------------------------------------

-- Hole Kurznamen für eine Dungeon-mapID
local function GetShortName(mapID)
    -- Hole Dungeon-Name von WoW-API (behandelt erweiterungs-spezifische mapID-Neuabbildungen)
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    if name then
        -- Schlage Kurznamen nach Dungeon-Name nach
        local short = NAME_TO_SHORT[name]
        if short then
            return short
        end
        -- Fallback: Auto-Abkürzung vom Namen
        local firstWord = name:match("^(%S+)")
        if firstWord and #firstWord <= 6 then
            return firstWord:upper()
        end
        return name:sub(1, 4):upper()
    end
    return "???"
end

-- Hole Teleport-Spell-ID für eine Dungeon-mapID
local function GetTeleportSpellID(mapID)
    return MAPID_TO_SPELL[mapID]
end

-- Hole vollständige Dungeon-Daten für eine mapID (Legacy-Kompatibilität)
local function GetDungeonData(mapID)
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    if name then
        return {
            short = NAME_TO_SHORT[name] or name:sub(1, 4):upper(),
            spellID = MAPID_TO_SPELL[mapID]
        }
    end
    return nil
end

-- Prüfe ob ein Dungeon einen Teleport-Spell hat
local function HasTeleport(mapID)
    return MAPID_TO_SPELL[mapID] ~= nil
end

-- Hole Key-Level-Farbe (geteiltes Utility)
local function GetKeyColor(level)
    if not level or level == 0 then return 0.7, 0.7, 0.7 end
    if level >= 12 then return 1, 0.5, 0 end      -- Orange für 12+
    if level >= 10 then return 0.64, 0.21, 0.93 end -- Lila für 10-11
    if level >= 7 then return 0, 0.44, 0.87 end   -- Blau für 7-9
    if level >= 5 then  return 0.12, 0.75, 0.26 end -- Grün für 5-6
    return 1, 1, 1                                 -- Weiß für 2-4
end

---------------------------------------------------------------------------
-- EXPORT TO NAMESPACE
---------------------------------------------------------------------------

ns.DungeonData = {
    nameToShort = NAME_TO_SHORT,
    mapIdToSpell = MAPID_TO_SPELL,
    GetShortName = GetShortName,
    GetTeleportSpellID = GetTeleportSpellID,
    GetDungeonData = GetDungeonData,
    HasTeleport = HasTeleport,
    GetKeyColor = GetKeyColor,
}

-- Auch global exponieren für dateiübergreifenden Zugriff
_G.gui_DungeonData = ns.DungeonData
