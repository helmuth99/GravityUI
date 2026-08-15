-- GravityUI Consumables Module
local ADDON_NAME, ns = ...

local openRaidLib = LibStub("LibOpenRaid-1.0", true)

local Module = { db = {}, F = {} }
ns.Consumables = Module

function Module.GetSetting(key)
    local db = ns.GetDB()
    if not db or not db.screenindicators or not db.screenindicators.consumables then return true end
    if key == 'consumables_enabled' then return db.screenindicators.consumables.enabled end
    if key == 'raid_frame_enabled' or key == 'raidFrame_enabled' then return db.screenindicators.consumables.showRaidFrame end
    return true
end

Module.F.shortName = function(name)
    if not name then return '' end
    local s = strsplit('-', name)
    return string.sub(s, 1, 12)
end

Module.F.GetRaidDiffMaxGroup = function()
    local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
    if instanceType == 'party' then return 1 end
    if instanceType == 'raid' then return math.ceil((maxPlayers or 20) / 5) end
    return 8
end

Module.F.hasClassInRoster = function(className)
    for j = 1, 40 do
        local name, _, _, class = Module.F.GetRosterInfo(j)
        if not name then
            if not IsInRaid() then return false end
        elseif class == className then
            return true
        end
    end
    return false
end

Module.F.GetRosterInfo = function(index)
    local name, _, subgroup, _, _, class, _, online, isDead = GetRaidRosterInfo(index)
    
    if not name and IsInGroup() and not IsInRaid() then
        if index == 1 then
            name = UnitName('player')
            subgroup = 1
            class = select(2, UnitClass('player'))
            online = true
            isDead = UnitIsDeadOrGhost('player')
        elseif index <= 5 then
            local unit = 'party' .. (index - 1)
            name = UnitName(unit)
            subgroup = 1
            class = select(2, UnitClass(unit))
            online = UnitIsConnected(unit)
            isDead = UnitIsDeadOrGhost(unit)
        end
    end
    
    local unit = 'raid' .. index
    if not IsInRaid() then
        unit = index == 1 and 'player' or 'party' .. (index - 1)
    end
    
    return name, unit, subgroup, class, online, isDead
end

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Expansion Constants
-------------------------------------------------------------------------------

local SHADOWLANDS    = 9
local DRAGONFLIGHT   = 10
local THE_WAR_WITHIN = 11
local MIDNIGHT       = 12

-------------------------------------------------------------------------------
--- Per-Expansion Settings
--- Icon and item overrides per expansion. The resolution loop below
--- iterates oldest-to-newest so the most recent expansion wins.
-------------------------------------------------------------------------------

Module.settings = {
    [SHADOWLANDS] = {
        rune           = { item_id = 181468, icon_id = 134078 },
        unlimited_rune = { item_id = 190384, icon_id = 4224736 },
        armor_kit      = { item_id = 3528447 },
    },
    [DRAGONFLIGHT] = {},
    [THE_WAR_WITHIN] = {
        rune           = { item_id = 224572, icon_id = 4549102 },
        flask          = { icon_id = 3566840 },
        vantus_rune    = { icon_id = 4638737 },
    },
    [MIDNIGHT] = {
        rune           = { item_id = 259085, icon_id = 4549099 },
        flask          = { icon_id = 7548902 },
        vantus_rune    = { icon_id = 5976918 },
        potion         = { icon_id = 7548911 },
        healing_potion = { icon_id = 7548909 },
        weapon_enchant = { icon_id = 7548985 },
    },
}

-- Sorted expansion IDs for deterministic oldest-to-newest iteration
Module.ordered_xpac_ids = {}
for xpac_id in pairs(Module.settings) do
    table.insert(Module.ordered_xpac_ids, xpac_id)
end
table.sort(Module.ordered_xpac_ids)

-------------------------------------------------------------------------------
--- Resolve icon and item IDs from settings
--- Loops oldest -> newest so the latest expansion overrides earlier ones.
-------------------------------------------------------------------------------

-- Defaults
Module.db.weapon_enchant_icon_id  = 463543
Module.db.food_icon_id            = 136000
Module.db.flask_icon_id           = 3528447
Module.db.armor_kit_icon_id       = 3566840
Module.db.healthstone_item_id     = 5512
Module.db.healthstone_icon_id     = 538745
Module.db.potion_icon_id          = 650640   -- trade_alchemy_potiona4
Module.db.healing_potion_icon_id  = 5931169  -- inv_flask_red
Module.db.vantus_icon_id          = 4638737  -- inv_10_inscription_glyphs_color5

local icon_keys = {
    { setting = "food",           db_key = "food_icon_id" },
    { setting = "flask",          db_key = "flask_icon_id" },
    { setting = "potion",         db_key = "potion_icon_id" },
    { setting = "healing_potion", db_key = "healing_potion_icon_id" },
    { setting = "weapon_enchant", db_key = "weapon_enchant_icon_id" },
    { setting = "armor_kit",      db_key = "armor_kit_icon_id" },
    { setting = "healthstone",    db_key = "healthstone_icon_id" },
    { setting = "vantus_rune",    db_key = "vantus_icon_id" },
}

for _, xpac_id in ipairs(Module.ordered_xpac_ids) do
    local xpac = Module.settings[xpac_id]

    if xpac then
        if xpac.rune then
            Module.db.rune_item_id = xpac.rune.item_id
            Module.db.rune_icon_id = xpac.rune.icon_id
        end

        if xpac.unlimited_rune then
            Module.db.unlimited_rune_item_id = xpac.unlimited_rune.item_id
            Module.db.unlimited_rune_icon_id = xpac.unlimited_rune.icon_id
        end

        for _, key in ipairs(icon_keys) do
            local entry = xpac[key.setting]

            if entry and entry.icon_id then
                Module.db[key.db_key] = entry.icon_id
            end
        end
    end
end

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Food Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently used by the addon.
--- "Hearty" variants are the same food but persist through death.
-------------------------------------------------------------------------------

Module.db.foodItemIDs = {
    -- Alcohol
    262880, -- Vintage Purple Stuff

    ----------------------------------------------------------------------------
    --- Feasts

    242745, -- [Epic] Hearty Blooming Feast       | 98 Stam, 65 Primary Stat
    266996, -- [Epic] Hearty Harandar Celebration | 98 Stam, 65 Primary Stat
    242744, -- [Epic] Hearty Quel'dorei Medley    | 98 Stam, 65 Primary Stat
    266985, -- [Epic] Hearty Silvermoon Parade    | 98 Stam, 65 Primary Stat
    266986, -- [Rare] Hearty Quel'dorei Medley    | 98 Stam, 65 Primary Stat

    242273, -- [Rare] Blooming Feast    | 98 Stam, 65 Highest Secondary Stat
    242272, -- [Rare] Quel'dorei Medley | 98 Stam, 65 Highest Secondary Stat

    255846, -- [Rare] Harandar Celebration   | 98 Stam, 50 Primary Stat
    255845, -- [Rare] Silvermoon Parade      | 98 Stam, 50 Primary Stat
    255847, -- [Rare] Impossibly Royal Roast | 98 Stam, 50 Primary Stat


    ----------------------------------------------------------------------------
    --- Personal Food

    242275, -- [Rare] Royal Roast                   | 50 Primary Stat
    242279, -- [Rare] Baked Lucky Loa               | 46 Primary Stat

    242274, -- [Rare] Champion's Bento              | 65 Highest Secondary Stat
    255848, -- [Rare] Flora Frenzy                  | 65 Highest Secondary Stat

    242287, -- [Rare] Arcano Cutlets                | 59 Critical Strike
    242278, -- [Rare] Tasty Smoked Tetra            | 59 Critical Strike
    242283, -- [Rare] Sun-Seared Lumifin            | 59 Critical Strike
    242277, -- [Rare] Crimson Calamari              | 59 Haste
    242286, -- [Rare] Fel-Kissed Filet              | 59 Haste
    242282, -- [Rare] Null and Void Plate           | 59 Haste
    242285, -- [Rare] Warped Wise Wings             | 59 Mastery
    242281, -- [Rare] Glitter Skewers               | 59 Mastery
    242276, -- [Rare] Braised Blood Hunter          | 59 Versatility
    242280, -- [Rare] Buttered Root Crab            | 59 Versatility
    242284, -- [Rare] Void-Kissed Fish Rolls        | 59 Versatility

    242747, -- [Rare] Hearty Royal Roast            | 50 Primary Stat
    268679, -- [Rare] Hearty Impossibly Royal Roast | 50 Primary Stat
    242751, -- [Rare] Hearty Rootland Surprise      | 46 Primary Stat
    242760, -- [Rare] Hearty Twilight Angler's Medl | 35 Primary Stat
    242761, -- [Rare] Hearty Spellfire Filet        | 35 Primary Stat
    242769, -- [Rare] Hearty Bloom Skewers          | 25 Primary Stat
    242770, -- [Rare] Hearty Mana-Infused Stew      | 25 Primary Stat

    242746, -- [Rare] Hearty Champion's Bento       | 65 Highest Secondary Stat
    268680, -- [Rare] Hearty Flora Frenzy           | 65 Highest Secondary Stat

    242750, -- [Rare] Hearty Tasty Smoked Tetra     | 59 Critical Strike
    242759, -- [Rare] Hearty Arcano Cutlets         | 59 Critical Strike
    242755, -- [Rare] Hearty Sun-Seared Lumifin     | 59 Critical Strike

    242749, -- [Rare] Hearty Crimson Calamari       | 59 Haste
    242758, -- [Rare] Hearty Fel-Kissed Filet       | 59 Haste
    242754, -- [Rare] Hearty Null and Void Plate    | 59 Haste

    242753, -- [Rare] Hearty Glitter Skewers        | 59 Mastery
    242757, -- [Rare] Hearty Warped Wise Wings      | 59 Mastery

    242752, -- [Rare] Hearty Buttered Root Crab     | 59 Versatility
    242756, -- [Rare] Hearty Void-Kissed Fish Rolls | 59 Versatility
    242748, -- [Rare] Hearty Braised Blood Hunter   | 59 Versatility
    242766, -- [Rare] Hearty Felberry Figs          | 46 Versatility

    242767, -- [Rare] Hearty Hearthflame Supper     | 22 Critical Strike, 22 Haste
    242775, -- [Rare] Hearty Portable Snack         | 16 Critical Strike, 16 Haste

    242762, -- [Rare] Hearty Wise Tails             | 22 Critical Strike, 22 Versatility
    242771, -- [Rare] Hearty Spiced Biscuits        | 16 Critical Strike, 16 Versatility

    242764, -- [Rare] Hearty Eversong Pudding       | 22 Mastery, 22 Critical Strike
    242773, -- [Rare] Hearty Forager's Medley       | 16 Mastery, 16 Critical Strike

    242768, -- [Rare] Hearty Bloodthistle-Wrapped C | 22 Mastery, 22 Haste
    242776, -- [Rare] Hearty Farstrider Rations     | 16 Mastery, 16 Haste

    242763, -- [Rare] Hearty Fried Bloomtail        | 22 Mastery, 22 Versatility
    242772, -- [Rare] Hearty Silvermoon Standard    | 16 Mastery, 16 Versatility

    242765, -- [Rare] Hearty Sunwell Delight        | 22 Versatility, 22 Haste
    242774, -- [Rare] Hearty Quick Sandwich         | 16 Versatility, 16 Haste


    242288, -- [Uncm] Twilight Angler's Medley      | 35 Primary Stat
    242289, -- [Uncm] Spellfire Filet               | 35 Primary Stat

    242295, -- [Uncm] Hearthflame Supper            | 22 Critical Strike, 22 Haste
    242290, -- [Uncm] Wise Tails                    | 22 Critical Strike, 22 Versatility
    242292, -- [Uncm] Eversong Pudding              | 22 Mastery, 22 Critical Strike
    242296, -- [Uncm] Bloodthistle-Wrapped Cutlets  | 22 Mastery, 22 Haste
    242291, -- [Uncm] Fried Bloomtail               | 22 Mastery, 22 Versatility
    242293, -- [Uncm] Sunwell Delight               | 22 Versatility, 22 Haste

    242294, -- [Uncm] Felberry Figs                 | 46 Versatility

    242297, -- [Uncm] Mana Lily Tea                 | Mana
    242298, -- [Uncm] Argentleaf Tea                | Mana
    242299, -- [Uncm] Sanguithorn Tea               | Mana
    242300, -- [Uncm] Tranquility Bloom Tea         | Mana
    242301, -- [Uncm] Azeroot Tea                   | Mana
    249689, -- [Uncm] Ghostflower Tea with Sunfruit | Mana

    ----------------------------------------------------------------------------
    --- Boon

    -- Epic Boon's
    267240, -- Boon of Fortitude
    267235, -- Boon of Vitality
    267236, -- Boon of Speed
    267238, -- Boon of Potency
    267239, -- Boon of Possibilities
    267648, -- Boon of Vigor
    267241, -- Boon of Abstinence
    267237, -- Boon of Power

    -- Rare Boon's
    260878, -- Boon of Possibilities
    260879, -- Boon of Power
    260882, -- Boon of Potency
    260884, -- Boon of Abstinence
    260910, -- Boon of Vitality
    260911, -- Boon of Fortitude
    264668, -- Boon of Speed
    267649, -- Boon of Vigor

    -- Uncommon Boon's
    267647, -- Boon of Vigor
    267243, -- Boon of Vitality
    267242, -- Boon of Speed
}

-------------------------------------------------------------------------------
--- Food Detection Icon IDs
--- Icon IDs used as a fallback to detect food/drink auras when the spell ID
--- is not in foodBuffIDs. 136000 is the canonical Well Fed icon and is
--- prioritized over others when multiple food auras are present.
-------------------------------------------------------------------------------

Module.db.foodIconIDs = {
    [136000] = true, -- Spell_misc_food,  Well Fed / Food Buff
    [132805] = true, -- Inv_drink_18,     Drinking
    [133950] = true, -- Inv_misc_food_08, Eating
}

Module.db.foodWellFedIconID = 136000

-------------------------------------------------------------------------------
--- Food Buff Spell IDs
--- Maps spell ID -> true for detecting Well Fed auras on players.
--- Also detected by icon ID (foodIconIDs) as a fallback.
-------------------------------------------------------------------------------

Module.db.foodBuffIDs = {
    -- 8.0.1 - Battle for Azeroth
    [257413] = true, -- Haste 5
    [257415] = true, -- Haste 7
    [297034] = true, -- Haste 9
    [257418] = true, -- Mastery 5
    [257420] = true, -- Mastery 7
    [297035] = true, -- Mastery 9
    [257408] = true, -- Crit 5
    [257410] = true, -- Crit 7
    [297039] = true, -- Crit 9
    [185736] = true, -- Versatility 3
    [257422] = true, -- Versatility 5
    [257424] = true, -- Versatility 7
    [297037] = true, -- Versatility 9
    [259449] = true, -- Intellect 7
    [259455] = true, -- Intellect 10
    [290468] = true, -- Intellect 8
    [297117] = true, -- Intellect 10
    [259452] = true, -- Strength 7
    [259456] = true, -- Strength 10
    [290469] = true, -- Strength 8
    [297118] = true, -- Strength 10
    [259448] = true, -- Agility 7
    [259454] = true, -- Agility 10
    [290467] = true, -- Agility 8
    [297116] = true, -- Agility 10
    [259453] = true, -- Stamina 11
    [259457] = true, -- Stamina 15
    [288074] = true, -- Stamina 11
    [288075] = true, -- Stamina 15
    [297119] = true, -- Stamina 16
    [297040] = true, -- Stamina 19
    [285719] = true, -- Rebirth Well Fed 5
    [285720] = true, -- Rebirth Well Fed 8
    [285721] = true, -- Rebirth Well Fed 8
    [286171] = true, -- Melee atk speed reduction 10

    -- 10.0.0 - Dragonflight
    [308488] = true, -- Haste 30
    [308506] = true, -- Mastery 30
    [308434] = true, -- Crit 30
    [308514] = true, -- Versatility 30
    [327708] = true, -- Intellect 20
    [327706] = true, -- Strength 20
    [327709] = true, -- Agility 20
    [308525] = true, -- Stamina 30
    [327707] = true, -- Stamina 30
    [308637] = true, -- Special 30
    [308474] = true, -- Haste 18
    [308504] = true, -- Mastery 18
    [308430] = true, -- Crit 18
    [308509] = true, -- Versatility 18
    [327704] = true, -- Intellect 18
    [327701] = true, -- Strength 18
    [327705] = true, -- Agility 18
    [327702] = true, -- Stamina 18
    [382145] = true, -- Haste 70
    [382150] = true, -- Mastery 70
    [382146] = true, -- Crit 70
    [382149] = true, -- Versatility 70
    [396092] = true, -- Intellect 90
    [382246] = true, -- Stamina 70
    [382247] = true, -- Stamina 90
    [382152] = true, -- Haste/Crit 90
    [382153] = true, -- Haste/Versatility 90
    [382157] = true, -- Versatility/Mastery 90
    [382230] = true, -- Stamina/Strength 70
    [382231] = true, -- Stamina/Agility 70
    [382232] = true, -- Stamina/Intellect 70
    [382154] = true, -- Haste/Mastery 90
    [382155] = true, -- Crit/Versatility 90
    [382156] = true, -- Crit/Mastery 90
    [382234] = true, -- Stamina/Strength 90
    [382235] = true, -- Stamina/Agility 90
    [382236] = true, -- Stamina/Intellect 90
}

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Flask Buff Spell IDs
--- Maps spell ID -> true for detecting flask auras on players.
-------------------------------------------------------------------------------

Module.db.flaskBuffIDs = {
    -- 12.0.0 - Midnight (Season 1 + Season 2 variants)
    [1235057] = true, -- Flask of Thalassian Resistance (Vers)
    [1235108] = true, -- Flask of the Magisters (Mastery)
    [1235110] = true, -- Flask of the Blood Knights (Haste)
    [1235111] = true, -- Flask of the Shattered Sun (Crit)
    [1236763] = true, -- Flask variant (Midnight S2)
    [1239355] = true, -- Flask variant (Midnight S2)
    [1239755] = true, -- Flask variant (Midnight S2)
    [1236767] = true, -- Flask variant (Midnight S2)

    -- 11.0.0 - The War Within
    [432021] = true, -- Flask of Alchemical Chaos
    [432473] = true, -- Flask of Saving Graces
    [431971] = true, -- Flask of Tempered Aggression
    [431972] = true, -- Flask of Tempered Swiftness
    [431974] = true, -- Flask of Tempered Mastery
    [431973] = true, -- Flask of Tempered Versatility

    -- 10.0.0 - Dragonflight
    [371339] = true, -- Phial of Elemental Chaos
    [374000] = true, -- Iced Phial of Corrupting Rage
    [371354] = true, -- Phial of the Eye in the Storm
    [371204] = true, -- Phial of Still Air
    [370662] = true, -- Phial of Icy Preservation
    [373257] = true, -- Phial of Glacial Fury
    [371386] = true, -- Phial of Charged Isolation
    [370652] = true, -- Phial of Static Empowerment
    [371172] = true, -- Phial of Tepid Versatility
    [371186] = true, -- Charged Phial of Alacrity

    -- 9.0.1 - Shadowlands
    [307187] = true, -- Spectral Stamina Flask
    [307185] = true, -- Spectral Flask of Power
    [307166] = true, -- Eternal Flask

    -- 8.0.1 - Battle for Azeroth
    [251838] = true, -- Flask of the Vast Horizon (Stamina)
    [251837] = true, -- Flask of Endless Fathoms (Intellect)
    [251836] = true, -- Flask of the Currents (Agility)
    [251839] = true, -- Flask of the Undertow (Strength)
    [298839] = true, -- Greater Flask of the Vast Horizon (Stamina)
    [298837] = true, -- Greater Flask of Endless Fathoms (Intellect)
    [298836] = true, -- Greater Flask of the Currents (Agility)
    [298841] = true, -- Greater Flask of the Undertow (Strength)
}

-------------------------------------------------------------------------------
--- Flask Item IDs
--- Used to check player inventory for flask items to offer the
--- click-to-use button. Order matters: first match wins.
-------------------------------------------------------------------------------

Module.db.flaskItemIDs = {
    -- 12.0.0 - Fleeting
    245927, 245926, -- Fleeting Flask of Thalassian Resistance
    245932, 245933, -- Fleeting Flask of the Magisters
    245930, 245931, -- Fleeting Flask of the Blood Knights
    245928, 245929, -- Fleeting Flask of the Shattered Sun

    -- 12.0.0 - Full duration
    241320, 241321, -- Flask of Thalassian Resistance
    241322, 241323, -- Flask of the Magisters
    241324, 241325, -- Flask of the Blood Knights
    241326, 241327, -- Flask of the Shattered Sun

    -- 11.0.0 - Fleeting
    212741, 212740, 212739, -- Fleeting Flask of Alchemical Chaos
    212747, 212746, 212745, -- Fleeting Flask of Saving Graces
    212728, 212727, 212725, -- Fleeting Flask of Tempered Aggression
    212731, 212730, 212729, -- Fleeting Flask of Tempered Swiftness
    212738, 212736, 212735, -- Fleeting Flask of Tempered Mastery
    212734, 212733, 212732, -- Fleeting Flask of Tempered Versatility

    -- 11.0.0 - Full duration
    212283, 212282, 212281, -- Flask of Alchemical Chaos
    212301, 212300, 212299, -- Flask of Saving Graces
    212271, 212270, 212269, -- Flask of Tempered Aggression
    212274, 212273, 212272, -- Flask of Tempered Swiftness
    212280, 212279, 212278, -- Flask of Tempered Mastery
    212277, 212276, 212275, -- Flask of Tempered Versatility
}

-------------------------------------------------------------------------------
--- Cauldron Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently tracked by the addon.
-------------------------------------------------------------------------------

Module.db.cauldronItemIDs = {
    241284, 241285, -- Voidlight Potion Cauldron
    241318, 241319, -- Cauldron of Sin'dorei Flasks
}

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Augment Rune Spell IDs
--- Maps spell ID -> tier for detecting augment rune auras.
--- Higher tier = more current expansion.
-------------------------------------------------------------------------------

Module.db.runeBuffIDs = {
    [1264426] = 7, -- 12.0.0: Void-Touched Augment Rune
    [1242347] = 6, -- 11.2.0: Soulgorged Augmentation
    [1234969] = 6, -- 11.2.0: Ethereal Augmentation
    [453250]  = 6, -- 11.0.0: Crystallization
    [393438]  = 6, -- 10.0.0: Draconic Augmentation
    [367405]  = 5, -- 9.2.0:  Eternal Augmentation
    [347901]  = 5, -- 9.0.2:  Veiled Augmentation
    [317065]  = 4, -- 8.3.0:  Battle-Scarred Augmentation
    [270058]  = 4, -- 8.1.0:  Battle-Scarred Augmentation
    [224001]  = 3, -- 7.0.3:  Defiled Augmentation
}

-- Rune Item Ids? 259085 12.0.0: Void-Touched Augment Rune

-------------------------------------------------------------------------------
--- Vantus Rune Buff Spell IDs (TWW + Midnight)
--- Set-style lookup for detecting active vantus rune auras.
--- The buff name contains "Vantus Rune: <Boss Name>".
-------------------------------------------------------------------------------

Module.db.vantusBuffIDs = {
    ----------------------------------------------------------------------------
    --- Midnight

    -- 12.1.0 - The Venomous Abyss (Season 2)
    -- Vantus Rune applies raid-wide. One SpellID covers all bosses.
    [1303164] = true, -- Vantus Rune: Tides (The Venomous Abyss, EncounterID 3492)

    -- 12.0.0 - Voidspire
    [1276687] = true, [1276688] = true, -- Imperator Averzian
    [1276691] = true, [1276698] = true, -- Vorasius
    [1276704] = true, [1276705] = true, -- Fallen-King Salhadaar
    [1276708] = true, [1276709] = true, -- Vaelgor & Ezzorak
    [1276711] = true, [1276712] = true, -- Lightblinded Vanguard
    [1276714] = true, [1276715] = true, -- Crown of the Cosmos

    -- 12.0.0 - Dreamrift
    [1276685] = true, [1276686] = true, -- Chimaerus the Undreamt God

    -- 12.0.0 - March on Quel'Danas
    [1276666] = true, [1276669] = true, -- Belo'ren, Child of Al'ar
    [1276682] = true, [1276683] = true, -- L'ura

    ----------------------------------------------------------------------------
    --- The War Within

    -- 11.2.0 - Manaforge Omega
    [1236892] = true, [1236900] = true, -- Plexus Sentinel
    [1236893] = true, [1236901] = true, -- Loom'ithar
    [1236894] = true, [1236902] = true, -- Soulbinder Naazindhri
    [1236895] = true, [1236903] = true, -- Forgeweaver Araz
    [1236896] = true, [1236904] = true, -- The Soul Hunters
    [1236897] = true, [1236905] = true, -- Fractillus
    [1236898] = true, [1236906] = true, -- Nexus-King Salhadaar
    [1236899] = true, [1236907] = true, -- Dimensius

    -- 11.1.0 - Liberation of Undermine
    [472541] = true, [472604] = true, -- Vexie and the Geargrinders
    [472596] = true, [472602] = true, -- Rik Reverb
    [472595] = true, [472601] = true, -- Stix Bunkjunker
    [472597] = true, [472603] = true, -- Cauldron of Carnage
    [472592] = true, [472598] = true, -- Mug'Zee, Heads of Security
    [472594] = true, [472600] = true, -- Sprocketmonger Lockenstock
    [472593] = true, [472599] = true, -- One-Armed Bandit
    [472521] = true, [472591] = true, -- Chrome King Gallywix

    -- 11.0.0 - Nerub-ar Palace
    [457610] = true, -- Ulgrax the Devourer
    [458701] = true, -- The Bloodbound Horror
    [458702] = true, -- Sikran
    [458703] = true, -- Rasha'nan
    [458704] = true, -- Broodtwister Ovi'nax
    [458705] = true, -- Nexus-Princess Ky'veza
    [458706] = true, -- The Silken Court
    [458707] = true, -- Queen Ansurek

    ----------------------------------------------------------------------------
    --- Dragonflight

    -- 10.2.0 - Amirdrassil, the Dream's Hope
    [425905] = 1, [425934] = 2, [425943] = 3, -- Gnarlroot
    [425906] = 1, [425935] = 2, [425944] = 3, -- Igira the Cruel
    [425907] = 1, [425936] = 2, [425945] = 3, -- Volcoross
    [425908] = 1, [425937] = 2, [425946] = 3, -- Council of Dreams
    [425909] = 1, [425938] = 2, [425947] = 3, -- Larodar, Keeper of the Flame
    [425910] = 1, [425939] = 2,               -- Nymue, Weaver of the Cycle
    [425911] = 1, [425940] = 2, [425951] = 3, -- Smolderon
    [425912] = 1, [425941] = 2, [425948] = 3, -- Tindral Sageswift
    [425913] = 1, [425942] = 2, [425949] = 3, -- Fyrakk the Blazing
    [425914] = 1, [425915] = 2, [425916] = 3, -- Amirdrassil, the Dream's Hope

    -- 10.1.0 - Aberrus, the Shadowed Crucible
    [411469] = 1,                             -- Kazzara, the Hellforged
    [409619] = 1, [411507] = 2, [411513] = 3, -- Kazzara, the Hellforged
    [409622] = 1, [411514] = 2, [411515] = 3, -- Shadowflame Elemental
    [409624] = 1, [411516] = 2, [411517] = 3, -- The Forgotten Experiments
    [409626] = 1, [411523] = 2, [411526] = 3, -- Zaqali Invasion
    [409627] = 1, [411527] = 2, [411528] = 3, -- Rashok
    [409638] = 1, [411530] = 2, [411532] = 3, -- The Vigilant Steward, Zskarn
    [409640] = 1, [411534] = 2, [411535] = 3, -- Magmorax
    [409618] = 1, [411536] = 2, [411537] = 3, -- Echo of Neltharion
    [409644] = 1, [411538] = 2, [411539] = 3, -- Scalecommander Sarkareth
    [409611] = 1, [410290] = 2, [410291] = 3, -- Aberrus, the Shadowed Crucible

    -- 10.0.0 - Vault of the Incarnates
    [384192] = 1, [384203] = 2, [384201] = 3, -- Eranog
    [384214] = 1, [384215] = 2, [384216] = 3, -- The Primal Council
    [384210] = 1, [384209] = 2, [384208] = 3, -- Terros
    [384229] = 1, [384228] = 2, [384227] = 3, -- Dathea, Ascended
    [384239] = 1, [384240] = 2, [384241] = 3, -- Kurog Grimtotem
    [384220] = 1, [384221] = 2, [384222] = 3, -- Sennarth
    [384233] = 1, [384234] = 2, [384235] = 3, -- Broodkeeper Diurna
    [384245] = 1, [384246] = 2, [384247] = 3, -- Raszageth
    [384154] = 1, [384248] = 2, [384306] = 3, -- Vault of the Incarnates

    ----------------------------------------------------------------------------
    --- Shadowlands

    -- 9.2.0 - Sepulcher of the First Ones

    -- 9.1.0 - Sanctum of Domination
    [354384] = 1,
    [354385] = 2,
    [354386] = 3,
    [354387] = 4,
    [354388] = 5,
    [354389] = 6,
    [354390] = 7,
    [354391] = 8,
    [354392] = 9,
    [354393] = 10,

    -- 9.0.0 - Castle Nathria
    [311445] = 1,
    [334132] = 2,
    [311448] = 3,
    [311446] = 4,
    [311447] = 5,
    [311449] = 6,
    [311450] = 7,
    [311451] = 8,
    [311452] = 9,
    [334131] = 10,

    ----------------------------------------------------------------------------
    --- Battle for Azeroth

    -- 8.3.0 - Ny'alotha, the Waking City
    [306475] = 1,
    [306480] = 2,
    [306476] = 3,
    [306477] = 4,
    [306478] = 5,
    [306484] = 6,
    [306485] = 7,
    [306479] = 8,
    [313550] = 9,
    [313551] = 10,
    [313554] = 11,
    [313556] = 12,

    -- 8.2.0 - The Eternal Palace
    [298622] = 1,
    [298640] = 2,
    [298642] = 3,
    [298643] = 4,
    [298644] = 5,
    [298645] = 6,
    [298646] = 7,
    [302914] = 8,

    -- 8.1.0 - Crucible of Storms
    -- 8.1.0 - Battle of Dazar'alor

    -- 8.0.0 - Uldir
    [269276] = 1,
    [269405] = 2,
    [269408] = 3,
    [269407] = 4,
    [269409] = 5,
    [269411] = 6,
    [269412] = 7,
    [269413] = 8,
}

-------------------------------------------------------------------------------
--- Vantus Rune Item IDs by Raid Instance
--- Keyed by WoW instance ID (GetInstanceInfo 8th return).
--- Each array is ordered highest quality first so the update
--- function can stop at the first item found in bags.
-------------------------------------------------------------------------------

Module.db.vantusItemsByRaid = {
    -- The War Within
    [1273] = { 226036, 226035, 226034 }, -- Nerub-ar Palace
    [1296] = { 232937, 232936, 232935 }, -- Liberation of Undermine
    [1301] = { 244149, 244148, 244147 }, -- Manaforge Omega
    [2810] = { 244149, 244148, 244147 }, -- Manaforge Omega Story mode

    -- Midnight
    [2912] = { 245880, 245879 }, -- The Voidspire
    [2913] = { 245880, 245879 }, -- March on Quel'Danas
    [2939] = { 245880, 245879 }, -- The Dreamrift
}

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Weapon Enchant / Oil Lookup
--- Maps enchant ID -> { item, icon, [q], [iconoh] }
--- Used by the consumable frame to detect and display weapon buffs.
--- Detected via GetWeaponEnchantInfo() Ã¢â‚¬â€ only weapon-slot enchants belong here.
-------------------------------------------------------------------------------

Module.db.weaponEnchants = {
    -- Shaman Enchants (negative item = spell-based, not item-based)
    [5401] = { item = -33757, icon = 462329, iconoh = 135814 }, -- Windfury Weapon
    [5400] = { item = -318038, icon = 135814 },                 -- Flametongue Weapon

    ----------------------------------------------------------------------------
    -- 12.0.0 - Midnight: Oils
    [8056] = { item = 243738, icon = 7548986, q = 2 }, -- Smuggler's Enchanted Edge
    [8055] = { item = 243737, icon = 7548986, q = 1 }, -- Smuggler's Enchanted Edge
    [8054] = { item = 243736, icon = 7548985, q = 2 }, -- Oil of Dawn
    [8053] = { item = 243735, icon = 7548985, q = 1 }, -- Oil of Dawn
    [8052] = { item = 243734, icon = 7548987, q = 2 }, -- Thalassian Phoenix Oil
    [8051] = { item = 243733, icon = 7548987, q = 1 }, -- Thalassian Phoenix Oil

    -- 12.0.0 - Midnight: Weightstone
    [7908] = { item = 237369, icon = 7548939, q = 2 }, -- Refulgent Weightstone
    [7907] = { item = 237367, icon = 7548938, q = 1 }, -- Refulgent Weightstone

    -- 12.0.0 - Midnight: Whetstone
    [7905] = { item = 237371, icon = 7548942, q = 2 }, -- Refulgent Whetstone
    [7904] = { item = 237370, icon = 7548941, q = 1 }, -- Refulgent Whetstone

    ----------------------------------------------------------------------------
    -- 11.0.0 - The War Within: Whetstones & Weightstones
    [7545] = { item = 222504, icon = 3622195, q = 3 }, -- Ironclaw Whetstone
    [7544] = { item = 222503, icon = 3622195, q = 2 }, -- Ironclaw Whetstone
    [7543] = { item = 222502, icon = 3622195, q = 1 }, -- Ironclaw Whetstone
    [7551] = { item = 222510, icon = 3622199, q = 3 }, -- Ironclaw Weightstone
    [7550] = { item = 222509, icon = 3622199, q = 2 }, -- Ironclaw Weightstone
    [7549] = { item = 222508, icon = 3622199, q = 1 }, -- Ironclaw Weightstone

    -- 11.0.0 - The War Within: Oils
    [7498] = { item = 224113, icon = 609897, q = 3 }, -- Oil of Deep Toxins
    [7497] = { item = 224112, icon = 609897, q = 2 }, -- Oil of Deep Toxins
    [7496] = { item = 224111, icon = 609897, q = 1 }, -- Oil of Deep Toxins
    [7495] = { item = 224107, icon = 609892, q = 3 }, -- Algari Mana Oil
    [7494] = { item = 224106, icon = 609892, q = 2 }, -- Algari Mana Oil
    [7493] = { item = 224105, icon = 609892, q = 1 }, -- Algari Mana Oil
    [7502] = { item = 224110, icon = 609896, q = 3 }, -- Oil of Beledar's Grace
    [7501] = { item = 224109, icon = 609896, q = 2 }, -- Oil of Beledar's Grace
    [7500] = { item = 224108, icon = 609896, q = 1 }, -- Oil of Beledar's Grace

    ----------------------------------------------------------------------------
    -- 10.0.0 - Dragonflight: Whetstones & Weightstones
    [6381] = { item = 191940, icon = 4622275, q = 3 }, -- Primal Whetstone
    [6380] = { item = 191939, icon = 4622275, q = 2 }, -- Primal Whetstone
    [6379] = { item = 191933, icon = 4622275, q = 1 }, -- Primal Whetstone
    [6698] = { item = 191945, icon = 4622279, q = 3 }, -- Primal Weightstone
    [6697] = { item = 191944, icon = 4622279, q = 2 }, -- Primal Weightstone
    [6696] = { item = 191943, icon = 4622279, q = 1 }, -- Primal Weightstone
    [6384] = { item = 191950, icon = 4622274, q = 3 }, -- Primal Razorstone
    [6383] = { item = 191949, icon = 4622274, q = 2 }, -- Primal Razorstone
    [6382] = { item = 191948, icon = 4622274, q = 1 }, -- Primal Razorstone

    -- 10.0.0 - Dragonflight: Runes
    [6514] = { item = 194823, icon = 134421, q = 3 }, -- Buzzing Rune
    [6513] = { item = 194822, icon = 134421, q = 2 }, -- Buzzing Rune
    [6512] = { item = 194821, icon = 134421, q = 1 }, -- Buzzing Rune
    [6695] = { item = 194826, icon = 134422, q = 3 }, -- Chirping Rune
    [6694] = { item = 194825, icon = 134422, q = 2 }, -- Chirping Rune
    [6515] = { item = 194824, icon = 134422, q = 1 }, -- Chirping Rune
    [6518] = { item = 194820, icon = 134418, q = 3 }, -- Howling Rune
    [6517] = { item = 194819, icon = 134418, q = 2 }, -- Howling Rune
    [6516] = { item = 194817, icon = 134418, q = 1 }, -- Howling Rune

    -- 10.0.0 - Dragonflight: Engineering
    [6534] = { item = 198165, icon = 135644, q = 3 },  -- Endless Stack of Needles
    [6533] = { item = 198164, icon = 135644, q = 2 },  -- Endless Stack of Needles
    [6532] = { item = 198163, icon = 135644, q = 1 },  -- Endless Stack of Needles
    [6531] = { item = 198162, icon = 249174, q = 3 },  -- Completely Safe Rockets
    [6530] = { item = 198161, icon = 249174, q = 2 },  -- Completely Safe Rockets
    [6529] = { item = 198160, icon = 249174, q = 1 },  -- Completely Safe Rockets
    [6522] = { item = 198312, icon = 4548897, q = 3 }, -- Gyroscopic Kaleidoscope
    [6521] = { item = 198311, icon = 4548897, q = 2 }, -- Gyroscopic Kaleidoscope
    [6520] = { item = 198310, icon = 4548897, q = 1 }, -- Gyroscopic Kaleidoscope
    [6528] = { item = 198318, icon = 4548899, q = 3 }, -- High Intensity Thermal Scanner
    [6527] = { item = 198317, icon = 4548899, q = 2 }, -- High Intensity Thermal Scanner
    [6526] = { item = 198316, icon = 4548899, q = 1 }, -- High Intensity Thermal Scanner
    [6525] = { item = 198315, icon = 4548898, q = 3 }, -- Projectile Propulsion Pinion
    [6524] = { item = 198314, icon = 4548898, q = 2 }, -- Projectile Propulsion Pinion
    [6523] = { item = 198313, icon = 4548898, q = 1 }, -- Projectile Propulsion Pinion

    -- 10.1.0 - Dragonflight: Hissing Rune
    [6839] = { item = 204973, icon = 134422, q = 3 }, -- Hissing Rune
    [6837] = { item = 204972, icon = 134422, q = 2 }, -- Hissing Rune
    [6838] = { item = 204971, icon = 134422, q = 1 }, -- Hissing Rune

    -- 10.2.0 - Dragonflight
    [7052] = { item = 210494, icon = 1045108 }, -- Incandescent Essence

    ----------------------------------------------------------------------------
    -- 9.0.1 - Shadowlands
    [6190] = { item = 171286, icon = 463544 },  -- Embalmer's Oil
    [6188] = { item = 171285, icon = 463543 },  -- Shadowcore Oil
    [6200] = { item = 171437, icon = 3528422 }, -- Shaded Sharpening Stone
    [6198] = { item = 171436, icon = 3528424 }, -- Porous Sharpening Stone
    [6201] = { item = 171439, icon = 3528423 }, -- Shaded Weightstone
    [6199] = { item = 171438, icon = 3528425 }, -- Porous Weightstone
}

-------------------------------------------------------------------------------
--- Reverse Lookup: item ID -> enchant data
--- Built at load time from Module.db.weaponEnchants.
-------------------------------------------------------------------------------

Module.db.weaponEnchantItems = {}
for _, v in pairs(Module.db.weaponEnchants) do
    Module.db.weaponEnchantItems[v.item] = v
end

-------------------------------------------------------------------------------
--- Non-Weapon Enchants
--- These use the enchant system but are applied to non-weapon slots.
--- Cannot be detected via GetWeaponEnchantInfo().
--- Stored for future use. Not currently used by the addon.
-------------------------------------------------------------------------------

Module.db.spellthreadEnchantIDs = {
    -- 11.0.0 - The War Within
    [7537] = { item = 222890, icon = 4549251, q = 3 }, -- Weavercloth Spellthread
    [7536] = { item = 222889, icon = 4549251, q = 2 }, -- Weavercloth Spellthread
    [7535] = { item = 222888, icon = 4549251, q = 1 }, -- Weavercloth Spellthread
    [7534] = { item = 222893, icon = 4549251, q = 3 }, -- Sunset Spellthread
    [7533] = { item = 222892, icon = 4549251, q = 2 }, -- Sunset Spellthread
    [7532] = { item = 222891, icon = 4549251, q = 1 }, -- Sunset Spellthread
    [7531] = { item = 222896, icon = 4549251, q = 3 }, -- Daybreak Spellthread
    [7530] = { item = 222895, icon = 4549251, q = 2 }, -- Daybreak Spellthread
    [7529] = { item = 222894, icon = 4549251, q = 1 }, -- Daybreak Spellthread

    -- 10.0.0 - Dragonflight
    [6538] = { item = 194010, icon = 4549251, q = 3 }, -- Vibrant Spellthread
    [6537] = { item = 194009, icon = 4549251, q = 2 }, -- Vibrant Spellthread
    [6536] = { item = 194008, icon = 4549251, q = 1 }, -- Vibrant Spellthread
    [6541] = { item = 194013, icon = 4549250, q = 3 }, -- Frozen Spellthread
    [6540] = { item = 194012, icon = 4549250, q = 2 }, -- Frozen Spellthread
    [6539] = { item = 194011, icon = 4549250, q = 1 }, -- Frozen Spellthread
    [6544] = { item = 194016, icon = 4549249, q = 3 }, -- Temporal Spellthread
    [6543] = { item = 194015, icon = 4549249, q = 2 }, -- Temporal Spellthread
    [6542] = { item = 194014, icon = 4549249, q = 1 }, -- Temporal Spellthread
}

Module.db.armorKitEnchantIDs = {
    -- 11.0.0 - The War Within
    [7601] = { item = 219911, icon = 5975854, q = 3 }, -- Stormbound Armor Kit
    [7600] = { item = 219910, icon = 5975854, q = 2 }, -- Stormbound Armor Kit
    [7599] = { item = 219909, icon = 5975854, q = 1 }, -- Stormbound Armor Kit
    [7598] = { item = 219914, icon = 5975933, q = 3 }, -- Dual Layered Armor Kit
    [7597] = { item = 219913, icon = 5975933, q = 2 }, -- Dual Layered Armor Kit
    [7596] = { item = 219912, icon = 5975933, q = 1 }, -- Dual Layered Armor Kit
    [7595] = { item = 219908, icon = 5975753, q = 3 }, -- Defender's Armor Kit
    [7594] = { item = 219907, icon = 5975753, q = 2 }, -- Defender's Armor Kit
    [7593] = { item = 219906, icon = 5975753, q = 1 }, -- Defender's Armor Kit
    [6830] = { item = 204702, icon = 5088845, q = 3 }, -- Lambent Armor Kit
    [6829] = { item = 204701, icon = 5088845, q = 2 }, -- Lambent Armor Kit
    [6828] = { item = 204700, icon = 5088845, q = 1 }, -- Lambent Armor Kit

    -- 10.0.0 - Dragonflight
    [6493] = { item = 193567, icon = 4559209, q = 3 }, -- Reinforced Armor Kit
    [6492] = { item = 193563, icon = 4559209, q = 2 }, -- Reinforced Armor Kit
    [6491] = { item = 193559, icon = 4559209, q = 1 }, -- Reinforced Armor Kit
    [6490] = { item = 193565, icon = 4559217, q = 3 }, -- Fierce Armor Kit
    [6489] = { item = 193561, icon = 4559217, q = 2 }, -- Fierce Armor Kit
    [6488] = { item = 193557, icon = 4559217, q = 1 }, -- Fierce Armor Kit
    [6496] = { item = 193564, icon = 4559216, q = 3 }, -- Frosted Armor Kit
    [6495] = { item = 193560, icon = 4559216, q = 2 }, -- Frosted Armor Kit
    [6494] = { item = 193556, icon = 4559216, q = 1 }, -- Frosted Armor Kit
}

Module.db.beltClaspEnchantIDs = {
    -- 10.1.0 - Dragonflight
    [6904] = { item = 205039, icon = 4559225, q = 3 }, -- Shadowed Belt Clasp
    [6905] = { item = 205044, icon = 4559225, q = 2 }, -- Shadowed Belt Clasp
    [6906] = { item = 205043, icon = 4559225, q = 1 }, -- Shadowed Belt Clasp
}

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Potion Spell IDs
--- Maps spell ID -> true for detecting potion usage via aura scanning.
--- Stored for future use. Not currently used by the addon.
-------------------------------------------------------------------------------

Module.db.potionBuffIDs = {
    -- 12.0.0 - Midnight
    [1236616] = true, -- Light's Potential
    [1236998] = true, -- Draught of Rampant Abandon
    [1236994] = true, -- Potion of Recklessness
    [1238443] = true, -- Potion of Zealotry
    [1235568] = true, -- Light's Preservation
    [1236648] = true, -- Lightfused Mana Potion
    [1239479] = true, -- Potion of Devoured Dreams

    -- 11.2.0
    [1247091] = true, -- Shrouded in Shadows

    -- 11.0.0 - The War Within
    [431932] = true, -- Tempered Potion
    [431419] = true, -- Cavedweller's Delight
    [431416] = true, -- Algari Healing Potion
    [431424] = true, -- Treading Lightly
    [431418] = true, -- Algari Mana Potion
    [460074] = true, -- Grotesque Vial
    [431914] = true, -- Potion of Unwavering Focus
    [431422] = true, -- Slumbering Soul Serum
    [431941] = true, -- Potion of the Reborn Cheetah
    [431432] = true, -- Draught of Shocking Revelations
    [431925] = true, -- Frontline Potion
    [453040] = true, -- Potion Bomb of Speed
    [453162] = true, -- Potion Bomb of Recovery
    [453205] = true, -- Potion Bomb of Power

    -- 10.0.0 - Dragonflight
    [370607] = true,
    [371028] = true,
    [371024] = true,
    [371033] = true,
    [371134] = true,
    [371152] = true,
    [371039] = true,
    [371167] = true,

    -- 9.0.1 - Shadowlands
    [307159] = true, -- Agility
    [307162] = true, -- Intellect
    [307163] = true, -- Stamina
    [307164] = true, -- Strength
    [307160] = true, -- Armor
    [307161] = true, -- Mana sleep
    [307194] = true, -- Mana+hp
    [307193] = true, -- Mana
    [307497] = true, -- Potion of Deathly Fixation
    [307494] = true, -- Potion of Empowered Exorcisms
    [307496] = true, -- Potion of Divine Awakening
    [307495] = true, -- Potion of Phantom Fire
    [322302] = true, -- Potion of Sacrificial Anima
    [344314] = true, -- Run
    [307199] = true, -- Potion of Soul Purity
    [342890] = true, -- Potion of Unhindered Passing
    [307196] = true, -- Potion of Shadow Sight
    [307195] = true, -- Invisibility

    -- 8.2.0 - Battle for Azeroth
    [298152] = true, -- Intellect
    [298146] = true, -- Agility
    [298153] = true, -- Stamina
    [298154] = true, -- Strength
    [298155] = true, -- Armor
    [298225] = true, -- Potion of Empowered Proximity
    [298317] = true, -- Potion of Focused Resolve
    [300714] = true, -- Potion of Unbridled Fury
    [300741] = true, -- Potion of Wild Mending
    [251316] = true, -- Potion of Bursting Blood
    [269853] = true, -- Potion of Rising Death
    [250873] = true, -- Invisibility
    [250878] = true, -- Run haste
    [251143] = true, -- Fall

    -- 8.0.1 - Battle for Azeroth
    [279152] = true, -- Agility
    [279151] = true, -- Intellect
    [279154] = true, -- Stamina
    [279153] = true, -- Strength
    [251231] = true, -- Armor

    -- Legacy
    [188024] = true, -- Run haste
    [250871] = true, -- Mana
    [252753] = true, -- Mana channel
    [250872] = true, -- Mana+hp
}

-------------------------------------------------------------------------------
--- Damage Potion Item IDs
--- Used to check player inventory for combat potions. Order matters:
--- first match wins for icon display, all are summed for count.
-------------------------------------------------------------------------------

Module.db.potionItemIDs = {
    -- 12.0.0 - Fleeting
    245916, 245917, -- Fleeting Lightfused Mana Potion
    245897, 245898, -- Fleeting Light's Potential
    245910, 245911, -- Fleeting Draught of Rampant Abandon
    245902, 245903, -- Fleeting Potion of Recklessness
    245900, 245901, -- Fleeting Potion of Zealotry
    245904, 245905, -- Fleeting Potion of Devoured Dreams

    -- 12.0.0 - Full duration
    241300, 241301, -- Lightfused Mana Potion
    241308, 241309, -- Light's Potential
    241292, 241293, -- Draught of Rampant Abandon
    241288, 241289, -- Potion of Recklessness
    241296, 241297, -- Potion of Zealotry
    241286, 241287, -- Light's Preservation
    241294, 241295, -- Potion of Devoured Dreams

    -- 11.0.0 - Fleeting
    212969, 212970, 212971, -- Fleeting Tempered Potion
    212963, 212964, 212965, -- Fleeting Potion of Unwavering Focus
    212966, 212967, 212968, -- Fleeting Frontline Potion

    -- 11.0.0 - Full duration
    212263, 212264, 212265, -- Tempered Potion
    212257, 212258, 212259, -- Potion of Unwavering Focus
    212260, 212261, 212262, -- Frontline Potion
}

-------------------------------------------------------------------------------
--- Utility Potions (12.0.0 - Midnight)
--- Stored for future use. Not currently tracked by the addon.
-------------------------------------------------------------------------------

Module.db.utilityPotionItemIDs = {
    241302, 241303, -- Void-Shrouded Tincture (invisibility)
    241338, 241339, -- Enlightenment Tonic (slow fall)
}

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Healthstone
-------------------------------------------------------------------------------

Module.db.healthstoneItemIDs = {
    [5512]   = true, -- Healthstone
    [224464] = true, -- Demonic Healthstone
}

Module.db.healthstoneSpellIDs = {
    [6262] = true, -- Create Healthstone
}

-------------------------------------------------------------------------------
--- Healing Potion Spell IDs
--- Maps spell ID -> true for detecting healing potion aura buffs.
--- Stored for future use. Not currently used by the addon.
-------------------------------------------------------------------------------

Module.db.healingPotionSpellIDs = {
    [1234768] = true, -- 12.0.0: Silvermoon Health Potion
    [1263074] = true, -- 12.0.0: Amani Extract
    [1236590] = true, -- 12.0.0: Refreshing Serum

    [1238009] = true, -- 11.2.0: Invigorating Healing Potion
    [431416]  = true, -- 11.0.0: Algari Healing Potion
    [431419]  = true, -- 11.0.0: Cavedweller's Delight

    [370511]  = true, -- 10.0.0: Refreshing Healing Potion

    [307192]  = true, -- 9.0.1: Spiritual Healing Potion

    [301308]  = true, -- 8.0.1: Abyssal Healing Potion
    [250870]  = true, -- 8.0.1: Coastal Healing Potion

    [188016]  = true, -- 7.0.1: Ancient Healing Potion

    [156438]  = true, -- 6.0.1: Healing Tonic

    [105708]  = true, -- 5.0.4: Healing Potion
}

-------------------------------------------------------------------------------
--- Healing Potion Item IDs
--- Used to check player inventory for healing potions.
--- All items are summed for total count.
-------------------------------------------------------------------------------

Module.db.healingPotionItemIDs = {
    -- 12.0.0 - Full duration
    241304, 241305, -- Silvermoon Health Potion
    241298, 241299, -- Amani Extract
    241306, 241307, -- Refreshing Serum

    -- 11.2.0 - Fleeting
    244849,                 -- Fleeting Invigorating Healing Potion

    -- 11.2.0 - Full duration
    244835, 244838, 244839, -- Invigorating Healing Potion

    -- 11.0.0 - Fleeting
    212948, 212949, 212950, -- Fleeting Cavedweller's Delight
    212942, 212943, 212944, -- Fleeting Algari Healing Potion

    -- 11.0.0 - Full duration
    212242, 212243, 212244, -- Cavedweller's Delight
    211878, 211879, 211880, -- Algari Healing Potion
}

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Gem Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently used by the addon.
--- Organized by gem color, then stat prefix.
--- Base gems are uncommon, Flawless gems are rare.
-------------------------------------------------------------------------------

Module.db.gemItemIDs = {
    -- 12.0.0 - Midnight
    amethyst = {
        deadly    = { 240866, 240855 },
        masterful = { 240863 },
        quick     = { 240867, 240868 },
        versatile = { 240869, 240870 },
    },
    flawless_amethyst = {
        deadly    = { 240891, 240858 },
        masterful = { 240895, 240896 },
        quick     = { 240899, 240900 },
        versatile = { 240901, 240902 },
    },
    garnet = {
        deadly    = { 240871 },
        masterful = { 240876, 240875 },
        quick     = { 240873 },
        versatile = { 240877, 240879 },
    },
    flawless_garnet = {
        deadly    = { 240903, 240904 },
        masterful = { 240907, 240908 },
        quick     = { 240905, 240906 },
        versatile = { 240909, 240910 },
    },
    lapis = {
        deadly    = { 240881, 240882 },
        masterful = { 240885, 240886 },
        quick     = { 240883 },
        versatile = { 240880 },
    },
    flawless_lapis = {
        deadly    = { 240914, 240913 },
        masterful = { 240917, 240918 },
        quick     = { 240915, 240916 },
        versatile = { 240911, 240912 },
    },
    peridot = {
        deadly    = { 240857, 240862 },
        masterful = { 240859, 240860 },
        quick     = { 240856, 240865 },
        versatile = { 240861, 240864 },
    },
    flawless_peridot = {
        deadly    = { 240888, 240889 },
        masterful = { 240892, 240890 },
        quick     = { 240887, 240898 },
        versatile = { 240893, 240894 },
    },
    eversong_diamond = {
        indecipherable = { 240983, 240982 },
        powerful       = { 240966, 240967 },
        stoic          = { 240970, 240971 },
        telluric       = { 240968, 240969 },
    },
    heliotrope = {
        cognitive  = { 241143 },
        determined = { 241142 },
        enduring   = { 241144 },
    },
}

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Permanent Enchantments (12.0.0 - Midnight)
--- Stored for future use. Not currently used by the addon.
--- Item IDs only Ã¢â‚¬â€ enchant IDs not yet collected.
-------------------------------------------------------------------------------

Module.db.enchantIDs = {
    -- 12.0.0 - Midnight
    boots = {
        244009, -- Farstrider's Hunt
        243953, -- Lynx's Dexterity
        243983, -- Shaladrassil's Roots
    },
    chest = {
        243947, -- Mark of Nalorakk
        244003, -- Mark of the Magister
        243975, -- Mark of the Rootwarden
        243977, -- Mark of the Worldsoul
    },
    helm = {
        243979, -- Blessing of Speed
        243981, -- Empowered Blessing of Speed
        244007, -- Empowered Rune of Avoidance
        243949, -- Hex of Leeching
        244005, -- Rune of Avoidance
    },
    ring = {
        243955, -- Amani Mastery
        243957, -- Eyes of the Eagle
        243987, -- Nature's Fury
        243985, -- Nature's Wrath
        244015, -- Silvermoon's Alacrity
        244017, -- Silvermoon's Tenacity
        244011, -- Thalassian Haste
        244013, -- Thalassian Versatility
        243959, -- Zul'jins Mastery
    },
    shoulder = {
        243963, -- Akil'zon's Celerity
        243991, -- Amirdrassil's Grace
        243961, -- Flight of the Eagle
        243989, -- Nature's Grace
        244021, -- Silvermoon's Mending
        244019, -- Thalassian Recovery
    },
    weapon = {
        244029, -- Acuity of the Ren'dorei
        244031, -- Arcane Mastery
        243973, -- Berserker's Rage
        244027, -- Flames of the Sin'dorei
        243971, -- Jan'alai's Precision
        243969, -- Strength of Halazzi
        243999, -- Worldsoul Aegis
        243997, -- Worldsoul Cradle
        244001, -- Worldsoul Tenacity
    },
    tool = {
        243965, -- Amani Perception
        243967, -- Amani Resourcefulness
        243993, -- Haranir Finesse
        243995, -- Haranir Multicrafting
        244025, -- Ren'dorei Ingenuity
        244023, -- Sin'dorei Deftness
    },
    spellthread = {
        240155, -- Arcanoweave Spellthread
        240133, -- Sunfire Silk Spellthread
        240157, -- Bright Linen Spellthread
    },
    armorkit = {
        244643, -- Blood Knight's Armor Kit
        244641, -- Forest Hunter's Armor Kit
        244645, -- Thalassian Scout Armor Kit
    },
}

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Raid Buff Spell IDs
-------------------------------------------------------------------------------

local battle_shout                = 6673
local battle_shout_scroll         = 264761
local power_word_fortitude        = 21562
local power_word_fortitude_scroll = 264764
local arcane_intellect            = 1459
local arcane_intellect_scroll     = 264760
local mark_of_the_wild            = 1126
local skyfury                     = 462854
local blessing_of_the_bronze      = 381748

-------------------------------------------------------------------------------
--- Raid Buff Definitions
--- Each entry: { label, provider_class, primary_spell, scroll_spell,
---               [optional alternate_spells table] }
-------------------------------------------------------------------------------

Module.db.raidBuffDefs = {
    {
        ATTACK_POWER_TOOLTIP or "AP", "WARRIOR",
        battle_shout, battle_shout_scroll,
    },
    {
        SPELL_STAT3_NAME or "Stamina", "PRIEST",
        power_word_fortitude, power_word_fortitude_scroll,
    },
    {
        SPELL_STAT4_NAME or "Int", "MAGE",
        arcane_intellect, arcane_intellect_scroll,
    },
    {
        STAT_VERSATILITY or "Vers", "DRUID",
        mark_of_the_wild,
    },
    {
        STAT_MASTERY or "Mastery", "SHAMAN",
        skyfury,
    },
    {
        TUTORIAL_TITLE2 or "Movement", "EVOKER",
        blessing_of_the_bronze, nil,
        {
            [381758] = true, -- Heroic Leap
            [381732] = true, -- Death's Advance
            [381741] = true, -- Fel Rush
            [381746] = true, -- Tiger Dash / Dash
            [381748] = true, -- Hover
            [381750] = true, -- Shimmer / Blink
            [381749] = true, -- Aspect of the Cheetah
            [381751] = true, -- Chi Torpedo / Roll
            [381752] = true, -- Divine Steed
            [381753] = true, -- Leap of Faith
            [381754] = true, -- Sprint
            [381756] = true, -- Spiritwalker's Grace / Spirit Walk / Gust of Wind
            [381757] = true, -- Demonic Circle: Teleport
        },
    },
}


local F = Module.F

local GetTime = GetTime

local      IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local       GetSpellInfo = C_Spell.GetSpellInfo
local        GetItemInfo = C_Item.GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local       GetItemCount = C_Item.GetItemCount
local        GetItemIcon = C_Item.GetItemIconByID

-------------------------------------------------------------------------------
--- Constants
-------------------------------------------------------------------------------

local consumables_size = 48
local FONT = ns.GetFont()

-------------------------------------------------------------------------------
--- Construct the button frame
-------------------------------------------------------------------------------

Module.consumables = CreateFrame("Frame", "GravityUIConsumables", ReadyCheckListenerFrame, "BackdropTemplate")
Module.consumables:SetPoint("BOTTOM", ReadyCheckListenerFrame, "TOP", 0, 5)
Module.consumables:SetSize(consumables_size * 5, consumables_size)
Module.consumables:SetFrameStrata("DIALOG")
Module.consumables:SetFrameLevel(100)
Module.consumables:SetMovable(true)
Module.consumables:EnableMouse(true)
Module.consumables:RegisterForDrag("LeftButton")
Module.consumables:Hide()
Module.consumables.buttons = {}

Module.consumables.rlpointer = CreateFrame("Frame", nil, UIParent)
Module.consumables.rlpointer:SetSize(1, 1)
Module.consumables.rlpointer:SetPoint("CENTER")
Module.consumables.rlpointer:Hide()

local function savePersonalPosition(self)
    self:StopMovingOrSizing()
    self.isMoving = false

    local db = ns.GetDB()
    if not db or not db.screenindicators or not db.screenindicators.consumables then return end

    local point, _, relPoint, x, y = self:GetPoint(1)
    db.screenindicators.consumables.personalPos = {
        point    = point,
        relPoint = relPoint,
        x        = x,
        y        = y,
    }
end

Module.consumables:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then
        self:StartMoving()
        self.isMoving = true
    end
end)

Module.consumables:SetScript("OnDragStop", savePersonalPosition)

Module.consumables:HookScript("OnHide", function(self)
    if self.isMoving then
        savePersonalPosition(self)
    end
end)

--- Drag handle (previously the close bar)
Module.consumables.dragHandle = CreateFrame("Frame", nil, Module.consumables, "BackdropTemplate")
Module.consumables.dragHandle:SetSize(0, 20)
Module.consumables.dragHandle:SetPoint("TOPLEFT", Module.consumables, "BOTTOMLEFT", 1, -3)
Module.consumables.dragHandle:SetPoint("TOPRIGHT", Module.consumables, "BOTTOMRIGHT", -1, -3)
Module.consumables.dragHandle:Hide()

Module.consumables.dragHandle.bg = Module.consumables.dragHandle:CreateTexture(nil, "BACKGROUND")
Module.consumables.dragHandle.bg:SetAllPoints()
Module.consumables.dragHandle.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

Module.consumables.dragHandle.border = Module.consumables.dragHandle:CreateTexture(nil, "BORDER")
Module.consumables.dragHandle.border:SetPoint("TOPLEFT", -1, 1)
Module.consumables.dragHandle.border:SetPoint("BOTTOMRIGHT", 1, -1)
Module.consumables.dragHandle.border:SetColorTexture(0, 0, 0, 1)

Module.consumables.dragHandle.text = Module.consumables.dragHandle:CreateFontString(nil, "OVERLAY")
Module.consumables.dragHandle.text:SetPoint("LEFT", 5, 0)
Module.consumables.dragHandle.text:SetFont(FONT, 10, "OUTLINE")
Module.consumables.dragHandle.text:SetText("DRAG")
Module.consumables.dragHandle.text:SetTextColor(0.5, 0.5, 0.5)

Module.consumables.dragHandle:EnableMouse(true)
Module.consumables.dragHandle:RegisterForDrag("LeftButton")
Module.consumables.dragHandle:SetScript("OnMouseDown", function(self, button)
    local p = self:GetParent()
    if button == "LeftButton" and not InCombatLockdown() then
        p:StartMoving()
        p.isMoving = true
    end
end)
Module.consumables.dragHandle:SetScript("OnMouseUp", function(self, button)
    local p = self:GetParent()
    if button == "LeftButton" and p.isMoving then
        savePersonalPosition(p)
    end
end)

--- Close button (small X on the right)
Module.consumables.closeBtn = CreateFrame("Button", nil, Module.consumables.dragHandle, "SecureHandlerClickTemplate")
Module.consumables.closeBtn:SetSize(20, 20)
Module.consumables.closeBtn:SetPoint("RIGHT")

Module.consumables.closeBtn.text = Module.consumables.closeBtn:CreateFontString(nil, "OVERLAY")
Module.consumables.closeBtn.text:SetPoint("CENTER")
Module.consumables.closeBtn.text:SetFont(FONT, 12, "OUTLINE")
Module.consumables.closeBtn.text:SetText("X")
Module.consumables.closeBtn.text:SetTextColor(1, 0.2, 0.2)

Module.consumables.closeBtn:SetFrameRef("consumables", Module.consumables)
Module.consumables.closeBtn:SetAttribute("_onclick", [[
    self:GetFrameRef("consumables"):Hide()
]])

local function savePersonalPosition(self)
    self:StopMovingOrSizing()

    local db = ns.GetDB()
    if not db or not db.screenindicators or not db.screenindicators.consumables then return end

    local point, _, relPoint, x, y = self:GetPoint(1)
    db.screenindicators.consumables.personalPos = {
        point    = point,
        relPoint = relPoint,
        x        = x,
        y        = y,
    }
end

Module.consumables:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

Module.consumables:SetScript("OnDragStop", savePersonalPosition)

-------------------------------------------------------------------------------
--- Combat state driver
-------------------------------------------------------------------------------

local function ClickButtonOnEnter(self)
    local button = self:GetParent()
    button:SetAlpha(0.7)

    if button.tooltipItemID then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(button.tooltipItemID)
        GameTooltip:Show()
    end
end

local function ClickButtonOnLeave(self)
    self:GetParent():SetAlpha(1)
    GameTooltip:Hide()
end

local function InfoButtonOnEnter(self)
    if self.tooltipAuraID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnitBuffByAuraInstanceID("player", self.tooltipAuraID)
        GameTooltip:Show()

        return
    end

    if self.tooltipItemID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.tooltipItemID)
        GameTooltip:Show()
    end
end

local function InfoButtonOnLeave()
    GameTooltip:Hide()
end

Module.consumables.state = CreateFrame("Frame", nil, nil,
                                    "SecureHandlerStateTemplate")

Module.consumables.state:SetAttribute("_onstate-combat", [=[
    for i = 2, 6 do
        if self:GetFrameRef("Button"..i) then
            if newstate == "hide" then
                self:GetFrameRef("Button"..i):Hide()
            elseif newstate == "show" then
                if self:GetFrameRef("Button"..i).IsON then
                    self:GetFrameRef("Button"..i):Show()
                end
            end
        end
    end
]=])

RegisterStateDriver(Module.consumables.state, "combat",
                    "[combat] hide; [nocombat] show")

-------------------------------------------------------------------------------
--- Button creation (9 buttons)
--- 1=food  2=flask  3=mh_oil  4=rune  5=hs  6=oh_oil
--- 7=dmg_pot  8=heal_pot  9=vantus
-------------------------------------------------------------------------------

local     i_food = 1
local    i_flask = 2
local   i_mh_oil = 3
local     i_rune = 4
local       i_hs = 5
local   i_oh_oil = 6
local  i_dmg_pot = 7
local i_heal_pot = 8
local   i_vantus = 9

local CLICKABLE_BUTTONS = {
    [i_flask]    = true,
    [i_mh_oil]   = true,
    [i_rune]     = true,
    [i_oh_oil]   = true,
    [i_vantus]   = false,
    [i_hs]       = false,
    [i_dmg_pot]  = false,
    [i_heal_pot] = false,
}

for i = 1, 9 do
    local button = CreateFrame("Frame", nil, Module.consumables)
    Module.consumables.buttons[i] = button
    button:SetSize(consumables_size, consumables_size)

    if i == 1 then
        button:SetPoint("LEFT", 0, 0)
    else
        button:SetPoint("LEFT", Module.consumables.buttons[i - 1], "RIGHT", 0, 0)
    end

    button.texture = button:CreateTexture()
    button.texture:SetAllPoints()

    button.statustexture = button:CreateTexture(nil, "OVERLAY")
    button.statustexture:SetPoint("CENTER")
    button.statustexture:SetSize(consumables_size / 2, consumables_size / 2)

    button.timeleft = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.timeleft:SetPoint("BOTTOM", button, "TOP", 0, 1)
    button.timeleft:SetFont(FONT, 12, "OUTLINE")

    button.count = button:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    button.count:SetFont(ns.GetFont(), 14, "OUTLINE")

    -- Always enable mouse on the parent button so tooltips work even when click is hidden
    button:EnableMouse(true)
    button:SetScript("OnEnter", InfoButtonOnEnter)
    button:SetScript("OnLeave", InfoButtonOnLeave)

    if CLICKABLE_BUTTONS[i] then
        button.click = CreateFrame("Button", nil, button,
                                   "SecureActionButtonTemplate")
        button.click:SetAllPoints()
        button.click:SetFrameLevel(button:GetFrameLevel() + 2)
        button.click:Hide()
        button.click:RegisterForClicks("AnyUp", "AnyDown")

        if i == i_mh_oil or i == i_oh_oil then
            button.click:SetAttribute("type", "item")
            button.click:SetAttribute("target-slot",
                                      i == i_mh_oil and "16" or "17")
        else
            button.click:SetAttribute("type", "macro")
        end

        button.click:SetScript("OnEnter", ClickButtonOnEnter)
        button.click:SetScript("OnLeave", ClickButtonOnLeave)

        Module.consumables.state:SetFrameRef("Button" .. i, button.click)
    end

    if i == i_food then
        button.texture:SetTexture(Module.db.food_icon_id)
        Module.consumables.buttons.food = button

    elseif i == i_flask then
        button.texture:SetTexture(Module.db.flask_icon_id)
        Module.consumables.buttons.flask = button

    elseif i == i_mh_oil then
        button.texture:SetTexture(Module.db.weapon_enchant_icon_id)
        Module.consumables.buttons.oil = button

    elseif i == i_rune then
        button.texture:SetTexture(Module.db.rune_icon_id)
        Module.consumables.buttons.rune = button

    elseif i == i_hs then
        button.texture:SetTexture(Module.db.healthstone_icon_id)
        Module.consumables.buttons.hs = button

    elseif i == i_oh_oil then
        button.texture:SetTexture(Module.db.weapon_enchant_icon_id)
        Module.consumables.buttons.oiloh = button
        button:Hide()

    elseif i == i_dmg_pot then
        button.texture:SetTexture(Module.db.potion_icon_id)
        Module.consumables.buttons.dmgpot = button

    elseif i == i_heal_pot then
        button.texture:SetTexture(Module.db.healing_potion_icon_id)
        Module.consumables.buttons.healpot = button

    elseif i == i_vantus then
        button.texture:SetTexture(Module.db.vantus_icon_id)
        Module.consumables.buttons.vantus = button
        button:Hide()
    end
end

-------------------------------------------------------------------------------
--- Update helper functions
-------------------------------------------------------------------------------

local isElvUIFix

local function updateElvUIParent(self) end

local function scanPlayerAuras(buttons, now)
    local isFlask, isRune, isVantus

    for i = 1, 60 do
        local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not auraData then break end

        -- TAINT FIX: auraData.spellId and auraData.icon can be 'secret number values'
        -- when the aura originates from a Blizzard-protected source. Using a secret
        -- value as a table index crashes with "table index is secret". tonumber()
        -- strips the secret flag and returns a plain Lua number safe for table indexing.
        local sid    = tonumber(auraData.spellId)
        local icon   = tonumber(auraData.icon)
        local expiry = auraData.expirationTime
        local READY  = "Interface\\RaidFrame\\ReadyCheck-Ready"

        if not sid then -- skip entirely if spellId is unreadable
        elseif Module.db.foodBuffIDs[sid] or Module.db.foodIconIDs[icon] then
            buttons.food.statustexture:SetTexture(READY)
            buttons.food.texture:SetDesaturated(false)
            buttons.food.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
                                                   ceil((expiry - now) / 60))
            buttons.food.tooltipAuraID = auraData.auraInstanceID

        elseif Module.db.flaskBuffIDs[sid] then
            buttons.flask.statustexture:SetTexture(READY)
            buttons.flask.texture:SetDesaturated(false)
            buttons.flask.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
                                                    ceil((expiry - now) / 60))
            if icon then buttons.flask.texture:SetTexture(icon) end
            isFlask = true

            if expiry - now <= 600 then
                isFlask = false
            end

        elseif Module.db.runeBuffIDs[sid] then
            buttons.rune.statustexture:SetTexture(READY)
            buttons.rune.texture:SetDesaturated(false)
            if icon then buttons.rune.texture:SetTexture(icon) end
            buttons.rune.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
                                                   ceil((expiry - now) / 60))
            isRune = true

        elseif Module.db.vantusBuffIDs[sid] then
            local name = auraData.name or ""
            isVantus = name:gsub("^Vantus Rune: ", "")
        end
    end

    return isFlask, isRune, isVantus
end

local function updateHealthstones(buttons)
    local totalCount = 0

    for itemID in pairs(Module.db.healthstoneItemIDs) do
        local count = GetItemCount(itemID, false, true)

        if count and count > 0 then
            totalCount = totalCount + count
        end
    end

    if totalCount > 0 then
        local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
        buttons.hs.count:SetFormattedText("%d", totalCount)
        buttons.hs.statustexture:SetTexture(READY)
        buttons.hs.texture:SetDesaturated(false)
        buttons.hs.tooltipItemID = Module.db.healthstone_item_id
    else
        buttons.hs.count:SetText("0")
    end
end

local function updateFlasks(buttons, isFlask, LCG)
    local flask_count = 0
    local flask_item_id

    for flask_index = 1, #Module.db.flaskItemIDs do
        local fid = Module.db.flaskItemIDs[flask_index]
        local count = GetItemCount(fid, false, false)

        if count and count > 0 then
            flask_item_id = fid
            flask_count = count

            break
        end
    end

    if flask_count > 0 then
        buttons.flask.tooltipItemID = flask_item_id

        if not isFlask then
            local texture = select(5, GetItemInfoInstant(flask_item_id))

            if texture then
                buttons.flask.texture:SetTexture(texture)
            end
        end

        if not InCombatLockdown() then
            if flask_item_id then
                buttons.flask.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use item:%d", flask_item_id))

                buttons.flask.click:Show()
                buttons.flask.click.IsON = true
            else
                buttons.flask.click:Hide()
                buttons.flask.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            buttons.flask.click:Hide()
            buttons.flask.click.IsON = false
        end
    end

    buttons.flask.count:SetFormattedText(
        "%s", flask_count > 0 and flask_count or "")

    if not LCG then return end

    if not isFlask and flask_count > 0 then
        LCG.PixelGlow_Start(buttons.flask)
    else
        LCG.PixelGlow_Stop(buttons.flask)
    end
end

local lastWeaponEnchantItem

local function updateWeaponEnchants(buttons, LCG)
    local offhandCanBeEnchanted
    local offhandItemID = GetInventoryItemID("player", 17)

    if offhandItemID then
        local itemClassID = select(6, GetItemInfoInstant(offhandItemID))

        if itemClassID == 2 then
            offhandCanBeEnchanted = true
        end
    end

    if not InCombatLockdown() then
        if offhandCanBeEnchanted then
            buttons.oiloh:Show()
            buttons.oiloh:ClearAllPoints()
            buttons.oiloh:SetPoint("LEFT", buttons.oil, "RIGHT", 0, 0)
            buttons.rune:ClearAllPoints()
            buttons.rune:SetPoint("LEFT", buttons.oiloh, "RIGHT", 0, 0)

        else
            buttons.oiloh:Hide()
            buttons.rune:ClearAllPoints()
            buttons.rune:SetPoint("LEFT", buttons.oil, "RIGHT", 0, 0)
        end
    end

    local hasMainHandEnchant, mainHandExpiration,
          mainHandCharges, mainHandEnchantID,
          hasOffHandEnchant, offHandExpiration,
          offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    if hasMainHandEnchant then
        buttons.oil.statustexture:SetTexture(READY)
        buttons.oil.texture:SetDesaturated(false)
        buttons.oil.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
            ceil((mainHandExpiration or 0) / 1000 / 60))

        if Module.db.weaponEnchants[mainHandEnchantID or 0] then
            lastWeaponEnchantItem = Module.db.weaponEnchants[mainHandEnchantID].item
        end
    end

    if offhandCanBeEnchanted and hasOffHandEnchant then
        buttons.oiloh.statustexture:SetTexture(READY)
        buttons.oiloh.texture:SetDesaturated(false)
        buttons.oiloh.timeleft:SetFormattedText(GARRISON_DURATION_MINUTES,
            ceil((offHandExpiration or 0) / 1000 / 60))
    end

    if lastWeaponEnchantItem
        and Module.db.weaponEnchantItems[lastWeaponEnchantItem]
    then
        local wenchData = Module.db.weaponEnchantItems[lastWeaponEnchantItem]
        buttons.oil.texture:SetTexture(wenchData.icon)
        buttons.oiloh.texture:SetTexture(wenchData.iconoh or wenchData.icon)
    end

    local oilItemID = lastWeaponEnchantItem

    if not oilItemID then
        local foundItem

        for itemID, data in pairs(Module.db.weaponEnchantItems) do
            -- Negative itemIDs are spells, not items
            if itemID > 0 and GetItemCount(itemID, false, true) > 0 then
                -- If we find 1 item, we want to store it. If we find a 2nd item
                --
                if foundItem then
                    foundItem = nil

                    break
                end

                foundItem = itemID
            end
        end

        if foundItem then
            oilItemID = foundItem
            local wenchData = Module.db.weaponEnchantItems[foundItem]

            buttons.oil.texture:SetTexture(wenchData.icon)
            buttons.oiloh.texture:SetTexture(wenchData.iconoh or wenchData.icon)
        end
    end

    if not oilItemID then
        if LCG then
            LCG.PixelGlow_Stop(buttons.oil)
            LCG.PixelGlow_Stop(buttons.oiloh)
        end

        return
    end

    local oilCount = GetItemCount(oilItemID, false, true)
    buttons.oil.count:SetText(oilCount)
    buttons.oiloh.count:SetText(oilCount)

    if type(oilItemID) == "number" and oilItemID > 0 then
        buttons.oil.tooltipItemID = oilItemID
        buttons.oiloh.tooltipItemID = oilItemID
    end

    if type(oilItemID) == "number" and oilItemID < 0 then
        if not InCombatLockdown() then
            local spellInfo = C_Spell.GetSpellInfo(-oilItemID)
            local spellName = spellInfo and spellInfo.name
            buttons.oil.click:SetAttribute("spell", spellName)
            buttons.oil.click:Show()
            buttons.oil.click.IsON = true
            buttons.oil.click:SetAttribute("type", "spell")

            local ohSpellInfo = C_Spell.GetSpellInfo(-oilItemID)
            local ohSpellName = ohSpellInfo and ohSpellInfo.name
            buttons.oiloh.click:SetAttribute("spell", ohSpellName)
            buttons.oiloh.click:Show()
            buttons.oiloh.click.IsON = true
            buttons.oiloh.click:SetAttribute("type", "spell")
        end

        buttons.oil.count:SetText("")
        buttons.oiloh.count:SetText("")
    elseif oilCount and oilCount > 0 then
        if not InCombatLockdown() then
            if oilItemID then
                buttons.oil.click:SetAttribute("item", "item:" .. oilItemID)
                buttons.oil.click:Show()
                buttons.oil.click.IsON = true

                if mainHandExpiration
                    and (oilItemID == 171285 or oilItemID == 171286)
                    and offhandItemID
                    and not offhandCanBeEnchanted then

                    buttons.oil.click:SetAttribute("type", "cancelaura")
                else
                    buttons.oil.click:SetAttribute("type", "item")
                end

                buttons.oiloh.click:SetAttribute("item", "item:" .. oilItemID)
                buttons.oiloh.click:Show()
                buttons.oiloh.click.IsON = true
            else
                buttons.oil.click:Hide()
                buttons.oil.click.IsON = false
                buttons.oiloh.click:Hide()
                buttons.oiloh.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            buttons.oil.click:Hide()
            buttons.oil.click.IsON = false
            buttons.oiloh.click:Hide()
            buttons.oiloh.click.IsON = false
        end
    end

    if not LCG then return end

    local needsMH = oilCount and oilCount > 0 and (not hasMainHandEnchant or
                    (mainHandExpiration and mainHandExpiration <= 300000))

    if needsMH then
        LCG.PixelGlow_Start(buttons.oil)
    else
        LCG.PixelGlow_Stop(buttons.oil)
    end

    local needsOH = oilCount and oilCount > 0 and (not hasOffHandEnchant
                    or (offHandExpiration and offHandExpiration <= 300000))

    if needsOH then
        LCG.PixelGlow_Start(buttons.oiloh)
    else
        LCG.PixelGlow_Stop(buttons.oiloh)
    end
end

local function updateRunes(buttons, isRune, LCG)
    local rune_item_count =
        GetItemCount(Module.db.rune_item_id, false, true)
    local unlimited_rune_item_count =
        GetItemCount(Module.db.unlimited_rune_item_id, false, true)

    if unlimited_rune_item_count
        and unlimited_rune_item_count > 0
    then
        buttons.rune.count:SetText("")
        buttons.rune.tooltipItemID = Module.db.unlimited_rune_item_id

        if not isRune then
            buttons.rune.texture:SetTexture(Module.db.unlimited_rune_icon_id)
        end

        if not InCombatLockdown() then
            if Module.db.unlimited_rune_item_id then
                buttons.rune.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use item:%d", Module.db.unlimited_rune_item_id))
                buttons.rune.click:Show()
                buttons.rune.click.IsON = true
            else
                buttons.rune.click:Hide()
                buttons.rune.click.IsON = false
            end
        end
    elseif rune_item_count and rune_item_count > 0 then
        buttons.rune.count:SetFormattedText("%d", rune_item_count)
        buttons.rune.tooltipItemID = Module.db.rune_item_id

        if not isRune then
            buttons.rune.texture:SetTexture(Module.db.rune_icon_id)
        end

        if not InCombatLockdown() then
            if Module.db.rune_item_id then
                buttons.rune.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n/use item:%d", Module.db.rune_item_id))
                buttons.rune.click:Show()
                buttons.rune.click.IsON = true
            else
                buttons.rune.click:Hide()
                buttons.rune.click.IsON = false
            end
        end
    else
        buttons.rune.count:SetText("0")

        if not InCombatLockdown() then
            buttons.rune.click:Hide()
            buttons.rune.click.IsON = false
        end
    end

    if not LCG then
        return
    end

    local hasRunes = (rune_item_count and rune_item_count > 0) or
        (unlimited_rune_item_count and unlimited_rune_item_count > 0)

    if hasRunes and not isRune then
        LCG.PixelGlow_Start(buttons.rune)
    else
        LCG.PixelGlow_Stop(buttons.rune)
    end
end

-- TODO: Update logic to only show most powerful found pot?
-- This will get weird if a healer has dmg pots and mana pots
local function updateDamagePotions(buttons)
    local inventoryItem,
          inventoryItemCount

    for i = 1, #Module.db.potionItemIDs do
        local item  = Module.db.potionItemIDs[i]
        local count = GetItemCount(item, false, true)

        if count and count > 0 then
            inventoryItem      = item
            inventoryItemCount = count

            break
        end
    end

    if inventoryItem and inventoryItemCount > 0 then
        buttons.dmgpot.count:SetFormattedText("%d", inventoryItemCount)
        buttons.dmgpot.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        buttons.dmgpot.texture:SetTexture(GetItemIcon(inventoryItem))
        buttons.dmgpot.texture:SetDesaturated(false)
        buttons.dmgpot.tooltipItemID = inventoryItem
    else
        buttons.dmgpot.count:SetText("0")
    end
end

local function updateHealingPotions(buttons)
    local inventoryItem,
          inventoryItemCount

    for i = 1, #Module.db.healingPotionItemIDs do
        local item  = Module.db.healingPotionItemIDs[i]
        local count = GetItemCount(item, false, true)

        if count and count > 0 then
            inventoryItem      = item
            inventoryItemCount = count

            break
        end
    end

    if inventoryItem and inventoryItemCount > 0 then
        buttons.healpot.count:SetFormattedText("%d", inventoryItemCount)
        buttons.healpot.statustexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        buttons.healpot.texture:SetTexture(GetItemIcon(inventoryItem))
        buttons.healpot.texture:SetDesaturated(false)
        buttons.healpot.tooltipItemID = inventoryItem
    else
        buttons.healpot.count:SetText("0")
    end
end

local function getVantusForCurrentRaid()
    local instanceID = select(8, GetInstanceInfo())
    local vantusRuneIDs = Module.db.vantusItemsByRaid[instanceID]

    -- db.vantusItemsByRaid does not have instance ID, return nils
    if not vantusRuneIDs then
        return nil, nil, 0
    end

    -- Return the first rune we have in our inventory and the count
    for i = 1, #vantusRuneIDs do
        local count = GetItemCount(vantusRuneIDs[i], false, true)

        if count and count > 0 then
            return vantusRuneIDs, vantusRuneIDs[i], count
        end
    end

    -- Return the first rune in the list so we can use the icon
    return vantusRuneIDs, vantusRuneIDs[1], 0
end

local function updateVantusRune(buttons, isVantus)
    local vantusRuneIDs, itemID, count = getVantusForCurrentRaid()
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    -- db.vantusItemsByRaid does not have a entry for instance ID, hide
    if not vantusRuneIDs then
        if not InCombatLockdown() then
            buttons.vantus:Hide()
        end

        return
    end

    if itemID then
        local icon_texture_id = select(10, C_Item.GetItemInfo(itemID))
        buttons.vantus.texture:SetTexture(icon_texture_id)
    end

    if not InCombatLockdown() then
        buttons.vantus:Show()
    end

    if isVantus then
        buttons.vantus.timeleft:SetText(isVantus)
        buttons.vantus.statustexture:SetTexture(READY)
        buttons.vantus.texture:SetDesaturated(false)

        if count > 0 then
            buttons.vantus.count:SetFormattedText("%d", count)
        end

        return
    end

    if itemID and count > 0 then
        buttons.vantus.count:SetFormattedText("%d", count)
        buttons.vantus.tooltipItemID = itemID

        return
    end

    buttons.vantus.count:SetText("0")
end

local function countVisibleButtons(buttons)
    local count = 0

    for i = 1, #buttons do
        if buttons[i]:IsShown() then
            count = count + 1
        end
    end

    return count
end

-------------------------------------------------------------------------------
--- Dormant: Armor Kit handling
--- Not currently called. Preserved for future re-use.
--- To re-enable: create a kit button, add to layout, call from
--- Update().
-------------------------------------------------------------------------------

local function updateArmorKits(buttons, LCG)
    local kitCount = GetItemCount(172347, false, true)
    local kitNow, kitMax, kitTimeLeft = Module:KitCheck()
    local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"

    if kitNow > 0 then
        buttons.kit.statustexture:SetTexture(READY)
        buttons.kit.texture:SetDesaturated(false)

        if kitTimeLeft then
            buttons.kit.timeleft:SetText(kitTimeLeft)
        end
    end

    if kitCount and kitCount > 0 then
        if not InCombatLockdown() then
            local itemName = C_Item.GetItemInfo(172347)

            if itemName then
                buttons.kit.click:SetAttribute("macrotext1",
                    format("/stopmacro [combat]\n" .. "/use %s\n/use 5", itemName))
                buttons.kit.click:Show()
                buttons.kit.click.IsON = true
            else
                buttons.kit.click:Hide()
                buttons.kit.click.IsON = false
            end
        end
    else
        if not InCombatLockdown() then
            buttons.kit.click:Hide()
            buttons.kit.click.IsON = false
        end
    end

    buttons.kit.count:SetFormattedText("%d", kitCount)

    if not LCG then return end

    if kitCount and kitCount > 0 and kitNow == 0 then
        LCG.PixelGlow_Start(buttons.kit)
    else
        LCG.PixelGlow_Stop(buttons.kit)
    end
end

-------------------------------------------------------------------------------
--- Update() coordinator
-------------------------------------------------------------------------------

local ICON_SETTINGS = {
    [i_food]     = "icon_food",
    [i_flask]    = "icon_flask",
    [i_mh_oil]   = "icon_mhOil",
    [i_oh_oil]   = "icon_ohOil",
    [i_hs]       = "icon_healthstone",
    [i_dmg_pot]  = "icon_dmgPotion",
    [i_heal_pot] = "icon_healPotion",
    [i_rune]     = "icon_rune",
    [i_vantus]   = "icon_vantus",
}

function Module.consumables:Update()
    updateElvUIParent(self)
    local buttons = self.buttons

    local isWarlockInRaid = F.hasClassInRoster("WARLOCK")

    if not InCombatLockdown() then
        if isWarlockInRaid then
            buttons.hs:Show()
        else
            buttons.hs:Hide()
        end

        buttons.oil:ClearAllPoints()
        buttons.oil:SetPoint("LEFT", buttons.flask, "RIGHT", 0, 0)
    end

    local NOT_READY = "Interface\\RaidFrame\\ReadyCheck-NotReady"

    for i = 1, #buttons do
        buttons[i].statustexture:SetTexture(NOT_READY)
        buttons[i].timeleft:SetText("")
        buttons[i].count:SetText("")
        buttons[i].texture:SetDesaturated(true)
        buttons[i].tooltipAuraID = nil
        buttons[i].tooltipItemID = nil
    end

    local LCG = LibStub("LibCustomGlow-1.0", true)
    local now = GetTime()

    local isFlask, isRune, isVantus = scanPlayerAuras(buttons, now)

    updateHealthstones(buttons)
    updateFlasks(buttons, isFlask, LCG)
    updateWeaponEnchants(buttons, LCG)
    updateRunes(buttons, isRune, LCG)
    updateDamagePotions(buttons)
    updateHealingPotions(buttons)
    updateVantusRune(buttons, isVantus)

    if not InCombatLockdown() then
        -- Chain potion buttons after the last dynamic button.
        -- Rune is always the last in the oil/oiloh/rune chain.
        local anchor = buttons.rune

        if isWarlockInRaid then
            buttons.hs:ClearAllPoints()
            buttons.hs:SetPoint("LEFT", anchor, "RIGHT", 0, 0)
            anchor = buttons.hs
        end

        buttons.dmgpot:ClearAllPoints()
        buttons.dmgpot:SetPoint("LEFT", anchor, "RIGHT", 0, 0)

        buttons.healpot:ClearAllPoints()
        buttons.healpot:SetPoint("LEFT", buttons.dmgpot, "RIGHT", 0, 0)

        if buttons.vantus:IsShown() then
            buttons.vantus:ClearAllPoints()
            buttons.vantus:SetPoint("LEFT", buttons.healpot, "RIGHT", 0, 0)
        end

        for idx, key in pairs(ICON_SETTINGS) do
            if not Module.GetSetting(key) then
                buttons[idx]:Hide()
            end
        end

        self:SetWidth(consumables_size * countVisibleButtons(buttons))
    end
end

-------------------------------------------------------------------------------
--- Repos / OnHide
-------------------------------------------------------------------------------

function Module.consumables:Repos(isRL)
    if InCombatLockdown() then
        return
    end

    if isRL then
        self:SetParent(UIParent)
        self:ClearAllPoints()

        local db = ns.GetDB()
        local pos = db and db.screenindicators and db.screenindicators.consumables and db.screenindicators.consumables.personalPos
        if pos then
            self:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
        else
            self:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        end

        self.dragHandle:Show()

        self.isRLpos = true
    elseif self.isRLpos then
        local parent

        if isElvUIFix then
            parent = ReadyCheckFrame
        else
            parent = ReadyCheckListenerFrame
        end

        self:SetParent(parent)
        self:ClearAllPoints()
        self:SetPoint("BOTTOM", parent, "TOP", 0, 5)

        self.isRLpos = false
    end
end

function Module.consumables:OnHide()
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("UNIT_INVENTORY_CHANGED")

    if self.cancelDelay then
        self.cancelDelay:Cancel()
        self.cancelDelay = nil
    end
end


local F  = Module.F
local db = Module.db

local GetTime = GetTime
local ceil    = ceil
local format  = format

-------------------------------------------------------------------------------
--- Constants
-------------------------------------------------------------------------------

local ROW_HEIGHT           = 30
local TITLE_HEIGHT         = 28
local ICON_SIZE            = 26
local NAME_WIDTH           = 150
local RC_ICON_WIDTH        = 24
local TIME_WIDTH           = 45
local DURABILITY_WIDTH     = 45
local H_PAD                = 3
local V_PAD                = 0
local FRAME_PAD            = 3
local MAX_ROWS             = 40
local MISSING_ALPHA        = 0.3
local EXPIRE_WARN_SECONDS  = 600  -- 10 minutes
local MISSING_BG           = { r = 0,   g = 0,   b = 0   }
local COLOR_TIME_NORMAL    = { r = 1,   g = 1,   b = 1   }
local COLOR_TIME_WARN      = { r = 1,   g = 0.2, b = 0.2 }
local COLOR_NAME_NORMAL    = { r = 1,   g = 1,   b = 1   }
local COLOR_NAME_OFFLINE   = { r = 0.5, g = 0.5, b = 0.5 }
local COLOR_NAME_DEAD      = { r = 0.8, g = 0.2, b = 0.2 }
local FONT_SIZE_NAME       = 16
local FONT_SIZE_TIME       = 14
local COLOR_TITLE_BG = { r = 0, g = 0, b = 0, a = 0.5 }
local COLOR_PROGRESS_BAR   = { r = 0, g = 209/255, b = 255/255, a = 0.6 }

local FONT = ns.GetFont()

local RC_PENDING = 0
local RC_READY   = 1
local RC_NOT     = 2

local RC_TEXTURES = {
    [RC_PENDING] = "Interface\\RaidFrame\\ReadyCheck-Waiting",
    [RC_READY]   = "Interface\\RaidFrame\\ReadyCheck-Ready",
    [RC_NOT]     = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

local RC_TEXTURE_OFFLINE = "Interface\\CharacterFrame\\Disconnect-Icon"
local RC_ATLAS_DEAD      = "Navigation-Tombstone-Icon"

local COLOR_SUMMARY_NOT_READY = { r = 1,   g = 0.2, b = 0.2 }
local COLOR_SUMMARY_AFK       = { r = 1,   g = 0.82, b = 0  }
local COLOR_SUMMARY_READY     = { r = 0.2, g = 1,   b = 0.2 }

local FRAME_WIDTH = FRAME_PAD
    + RC_ICON_WIDTH + H_PAD
    + NAME_WIDTH + H_PAD
    + DURABILITY_WIDTH + H_PAD
    + TIME_WIDTH + ICON_SIZE + H_PAD  -- food
    + TIME_WIDTH + ICON_SIZE + H_PAD  -- flask
    + (ICON_SIZE + H_PAD) * 8         -- rune + vantus + 6 raid buffs
    + FRAME_PAD

-- X offsets of each icon column within a row (and title bar), relative to row left edge.
-- These mirror the layout computed in createRow so title icons align with data icons.
local COL_X_FOOD  = RC_ICON_WIDTH + H_PAD + NAME_WIDTH + H_PAD + DURABILITY_WIDTH + H_PAD + TIME_WIDTH
local COL_X_FLASK = COL_X_FOOD  + ICON_SIZE + H_PAD + TIME_WIDTH
local COL_X_RUNE  = COL_X_FLASK + ICON_SIZE + H_PAD
local COL_X_VANTUS = COL_X_RUNE + ICON_SIZE + H_PAD
local COL_X_RAIDBUFF = {}  -- [1..N]
for k = 1, 8 do
    COL_X_RAIDBUFF[k] = COL_X_VANTUS + k * (ICON_SIZE + H_PAD)
end

-------------------------------------------------------------------------------
--- Raid buff default icons (spell texture IDs)
--- Looked up via C_Spell.GetSpellInfo at load time
-------------------------------------------------------------------------------

local RAID_BUFF_ICONS = {}
local FALLBACK_SPELL_ICON = 134400  -- INV_Misc_QuestionMark

local function resolveRaidBuffIcons()
    for k = 1, #db.raidBuffDefs do
        local spellID = db.raidBuffDefs[k][3]
        local info = C_Spell.GetSpellInfo(spellID)

        RAID_BUFF_ICONS[k] = info and info.iconID or FALLBACK_SPELL_ICON
    end
end

resolveRaidBuffIcons()

-------------------------------------------------------------------------------
--- Frame creation
-------------------------------------------------------------------------------
---

local frame = CreateFrame("Frame", "GravityUIRaidFrame", UIParent, "BackdropTemplate")
Module.raidFrame = frame

frame:SetSize(FRAME_WIDTH, ROW_HEIGHT * 5 + FRAME_PAD * 2)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetFrameLevel(100)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()

frame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
frame:SetBackdropBorderColor(0, 0, 0, 1)

frame:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    self:StartMoving()
end)

--- Close button
-- TODO: Extract into function and reduce duplication with the ConsumablesFrame.lua:37
frame.close = CreateFrame("Button", nil, frame,
                                    "SecureHandlerClickTemplate")
frame.close:SetSize(0, 20)
frame.close:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 1, -3)
frame.close:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3)

frame.close.bg = frame.close:CreateTexture(nil, "BACKGROUND")
frame.close.bg:SetAllPoints()
frame.close.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

frame.close.border = frame.close:CreateTexture(nil, "BORDER")
frame.close.border:SetPoint("TOPLEFT", -1, 1)
frame.close.border:SetPoint("BOTTOMRIGHT", 1, -1)
frame.close.border:SetColorTexture(0, 0, 0, 1)

frame.close.highlight = frame.close:CreateTexture(nil, "ARTWORK")
frame.close.highlight:SetAllPoints(frame.close.bg)
frame.close.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
frame.close.highlight:SetBlendMode("ADD")
frame.close.highlight:Hide()

frame.close.text = frame.close:CreateFontString(nil, "OVERLAY")
frame.close.text:SetPoint("CENTER")
frame.close.text:SetFont(FONT, 12, "OUTLINE")
frame.close.text:SetText(CLOSE or "x")
frame.close.text:SetTextColor(1, 1, 1)

frame.close:SetScript("OnEnter", function(self)
    self.highlight:Show()
end)

frame.close:SetScript("OnLeave", function(self)
    self.highlight:Hide()
end)

frame.close:SetFrameRef("CLLRaidFrame", frame)
frame.close:SetAttribute("_onclick", [[
    self:GetFrameRef("CLLRaidFrame"):Hide()
]])


local function savePosition(self)
    self:StopMovingOrSizing()

    local db = ns.GetDB()
    if not db or not db.screenindicators or not db.screenindicators.consumables then return end

    local point, _, relPoint, x, y = self:GetPoint(1)
    db.screenindicators.consumables.raidFramePos = {
        point    = point,
        relPoint = relPoint,
        x        = x,
        y        = y,
    }
end

frame:SetScript("OnDragStop", savePosition)

local resizer = CreateFrame("Button", nil, frame)
resizer:SetSize(16, 16)
resizer:SetPoint("BOTTOMRIGHT", -2, 2)
resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizer:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self.isScaling = true
        local _, y = GetCursorPosition()
        self.startY = y
        self.startScale = frame:GetScale()
    end
end)
resizer:SetScript("OnMouseUp", function(self, button)
    self.isScaling = false
    local db = ns.GetDB()
    if db and db.screenindicators and db.screenindicators.consumables then
        db.screenindicators.consumables.raidFrameScale = frame:GetScale()
    end
end)
resizer:SetScript("OnUpdate", function(self)
    if self.isScaling then
        local _, y = GetCursorPosition()
        local diff = y - self.startY
        local newScale = self.startScale - (diff / 200)
        newScale = math.max(0.5, math.min(2.5, newScale))
        frame:SetScale(newScale)
    end
end)
frame.resizer = resizer

local positionRestored = false

local function restorePosition()
    local db = ns.GetDB()
    if not db or not db.screenindicators or not db.screenindicators.consumables then return end
    
    local pos = db.screenindicators.consumables.raidFramePos

    if not pos then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

-------------------------------------------------------------------------------
--- Title bar
--- Progress bar bg that drains left-to-right over the RC duration.
--- Left side: "X/N" ready count + "Xs" countdown.
--- Right side: per-column CHECK/X summary icons aligned with data rows.
-------------------------------------------------------------------------------

local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  FRAME_PAD, -FRAME_PAD)
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PAD, -FRAME_PAD)
titleBar:SetHeight(TITLE_HEIGHT)

-- Plain black background
titleBar.bg = titleBar:CreateTexture(nil, "BACKGROUND")
titleBar.bg:SetAllPoints(titleBar)
titleBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
titleBar.bg:SetVertexColor(COLOR_TITLE_BG.r, COLOR_TITLE_BG.g, COLOR_TITLE_BG.b, COLOR_TITLE_BG.a)

-- Progress bar (fills left-to-right, drawn over the bg)
titleBar.progress = titleBar:CreateTexture(nil, "BORDER")
titleBar.progress:SetPoint("TOPLEFT",  titleBar, "TOPLEFT")
titleBar.progress:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT")
titleBar.progress:SetTexture("Interface\\Buttons\\WHITE8x8")
titleBar.progress:SetVertexColor(COLOR_PROGRESS_BAR.r, COLOR_PROGRESS_BAR.g, COLOR_PROGRESS_BAR.b, COLOR_PROGRESS_BAR.a)
titleBar.progress:SetWidth(1)
titleBar.progress:Hide()

-- "X/N" ready count label
titleBar.countText = titleBar:CreateFontString(nil, "ARTWORK")
titleBar.countText:SetPoint("LEFT", titleBar, "LEFT", 2, 0)
titleBar.countText:SetFont(FONT, FONT_SIZE_NAME, "OUTLINE")
titleBar.countText:SetTextColor(1, 1, 1)
titleBar.countText:SetText("")

-- Countdown timer label (e.g. "15s")
titleBar.timerText = titleBar:CreateFontString(nil, "ARTWORK")
titleBar.timerText:SetPoint("LEFT", titleBar.countText, "RIGHT", 6, 0)
titleBar.timerText:SetFont(FONT, FONT_SIZE_NAME, "OUTLINE")
titleBar.timerText:SetTextColor(1, 1, 1)
titleBar.timerText:SetText("")

-- Durability Header
titleBar.durabilityText = titleBar:CreateFontString(nil, "ARTWORK")
titleBar.durabilityText:SetPoint("LEFT", titleBar, "LEFT", FRAME_PAD + RC_ICON_WIDTH + H_PAD + NAME_WIDTH + H_PAD, 0)
titleBar.durabilityText:SetFont(FONT, 10, "OUTLINE")
titleBar.durabilityText:SetTextColor(1, 1, 1, 0.5)
titleBar.durabilityText:SetWidth(DURABILITY_WIDTH)
titleBar.durabilityText:SetJustifyH("RIGHT")
titleBar.durabilityText:SetText("Dur%")

-- Per-column summary icons (CHECK or X), one per buff column
-- Indices: 1=food, 2=flask, 3=rune, 4=vantus, 5..10=raid buffs 1-6
local TITLE_COL_X = {
    COL_X_FOOD,
    COL_X_FLASK,
    COL_X_RUNE,
    COL_X_VANTUS,
}
for k = 1, 6 do
    TITLE_COL_X[4 + k] = COL_X_RAIDBUFF[k]
end

titleBar.colIcons = {}
for i = 1, #TITLE_COL_X do
    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", titleBar, "LEFT", TITLE_COL_X[i], 0)
    icon:SetTexture(RC_TEXTURES[RC_PENDING])
    titleBar.colIcons[i] = icon
end

-------------------------------------------------------------------------------
--- Tooltip overlay helper
-------------------------------------------------------------------------------

local function onOverlayEnter(self)
    local unit    = self.unit
    local auraID  = self.auraID
    local spellID = self.spellID
    local label   = self.label

    if auraID and unit then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetUnitBuffByAuraInstanceID(unit, auraID)
        GameTooltip:Show()

        return
    end

    if spellID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(spellID)
        GameTooltip:Show()

        return
    end

    if label then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label)
        GameTooltip:Show()

        return
    end
end

local function onOverlayLeave()
    GameTooltip:Hide()
end

local function createOverlay(row, icon)
    local overlay = CreateFrame("Frame", nil, row)
    overlay:SetPoint("TOPLEFT", icon, "TOPLEFT")
    overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    overlay:EnableMouse(true)
    overlay:SetScript("OnEnter", onOverlayEnter)
    overlay:SetScript("OnLeave", onOverlayLeave)
    overlay.unit    = nil
    overlay.auraID  = nil
    overlay.spellID = nil
    overlay.label   = nil

    return overlay
end

-------------------------------------------------------------------------------
--- Icon background helper
--- Places a dark red BACKGROUND texture behind an icon texture.
--- Call after the icon texture is positioned so the bg matches its location.
-------------------------------------------------------------------------------

local function createIconBg(row, icon)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT",     icon, "TOPLEFT")
    bg:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(MISSING_BG.r, MISSING_BG.g, MISSING_BG.b, 1)
end

-------------------------------------------------------------------------------
--- Row creation (pre-allocate 40 rows)
-------------------------------------------------------------------------------

frame.rows = {}

local function createRow(index)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(FRAME_WIDTH - FRAME_PAD * 2, ROW_HEIGHT)
    row:Hide()

    local x = 0

    -- Ready check icon
    row.rcIcon = row:CreateTexture(nil, "ARTWORK")
    row.rcIcon:SetPoint("CENTER", row, "LEFT", x + RC_ICON_WIDTH / 2, 0)
    row.rcIcon:SetSize(RC_ICON_WIDTH, RC_ICON_WIDTH)
    row.rcIcon:SetTexture(RC_TEXTURES[RC_PENDING])
    x = x + RC_ICON_WIDTH + H_PAD

    -- Row background (class color)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)
    row.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.bg:SetVertexColor(1, 1, 1, 0.25)

    -- Player name
    row.nameText = row:CreateFontString(nil, "ARTWORK")
    row.nameText:SetPoint("LEFT", row, "LEFT", x, 0)
    row.nameText:SetFont(FONT, FONT_SIZE_NAME, "OUTLINE")
    row.nameText:SetWidth(NAME_WIDTH)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)
    x = x + NAME_WIDTH + H_PAD

    -- Durability %
    row.durabilityText = row:CreateFontString(nil, "ARTWORK")
    row.durabilityText:SetPoint("LEFT", row, "LEFT", x, 0)
    row.durabilityText:SetFont(FONT, FONT_SIZE_TIME, "OUTLINE")
    row.durabilityText:SetWidth(DURABILITY_WIDTH)
    row.durabilityText:SetJustifyH("RIGHT")
    x = x + DURABILITY_WIDTH + H_PAD

    -- Food time + icon
    row.foodTime = row:CreateFontString(nil, "ARTWORK")
    row.foodTime:SetPoint("LEFT", row, "LEFT", x, 0)
    row.foodTime:SetFont(FONT, FONT_SIZE_TIME, "OUTLINE")
    row.foodTime:SetWidth(TIME_WIDTH)
    row.foodTime:SetJustifyH("RIGHT")
    x = x + TIME_WIDTH

    row.foodIcon = row:CreateTexture(nil, "ARTWORK")
    row.foodIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.foodIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.foodIcon:SetTexture(db.food_icon_id)
    createIconBg(row, row.foodIcon)
    row.foodOverlay = createOverlay(row, row.foodIcon)
    row.foodOverlay.label = "Food: Missing"
    x = x + ICON_SIZE + H_PAD

    -- Flask time + icon
    row.flaskTime = row:CreateFontString(nil, "ARTWORK")
    row.flaskTime:SetPoint("LEFT", row, "LEFT", x, 0)
    row.flaskTime:SetFont(FONT, FONT_SIZE_TIME, "OUTLINE")
    row.flaskTime:SetWidth(TIME_WIDTH)
    row.flaskTime:SetJustifyH("RIGHT")
    x = x + TIME_WIDTH

    row.flaskIcon = row:CreateTexture(nil, "ARTWORK")
    row.flaskIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.flaskIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.flaskIcon:SetTexture(db.flask_icon_id)
    createIconBg(row, row.flaskIcon)
    row.flaskOverlay = createOverlay(row, row.flaskIcon)
    row.flaskOverlay.label = "Flask: Missing"
    x = x + ICON_SIZE + H_PAD

    -- Augment Rune icon
    row.runeIcon = row:CreateTexture(nil, "ARTWORK")
    row.runeIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.runeIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.runeIcon:SetTexture(db.rune_icon_id)
    createIconBg(row, row.runeIcon)
    row.runeOverlay = createOverlay(row, row.runeIcon)
    row.runeOverlay.label = "Augment Rune: Missing"
    x = x + ICON_SIZE + H_PAD

    -- Vantus Rune icon
    row.vantusIcon = row:CreateTexture(nil, "ARTWORK")
    row.vantusIcon:SetPoint("LEFT", row, "LEFT", x, 0)
    row.vantusIcon:SetSize(ICON_SIZE, ICON_SIZE)
    row.vantusIcon:SetTexture(db.vantus_icon_id)
    createIconBg(row, row.vantusIcon)
    row.vantusOverlay = createOverlay(row, row.vantusIcon)
    row.vantusOverlay.label = "Vantus Rune: Missing"
    x = x + ICON_SIZE + H_PAD

    -- 6 Raid buff icons
    row.raidBuffIcons    = {}
    row.raidBuffOverlays = {}

    for k = 1, #db.raidBuffDefs do
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", row, "LEFT", x, 0)
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetTexture(RAID_BUFF_ICONS[k])
        createIconBg(row, icon)
        row.raidBuffIcons[k] = icon

        local overlay = createOverlay(row, icon)
        overlay.spellID = db.raidBuffDefs[k][3]
        row.raidBuffOverlays[k] = overlay
        x = x + ICON_SIZE + H_PAD
    end

    -- Anchor row in frame (row 1 sits below the title bar)
    if index == 1 then
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PAD, -(FRAME_PAD + TITLE_HEIGHT + FRAME_PAD + V_PAD))
    else
        row:SetPoint("TOPLEFT", frame.rows[index - 1], "BOTTOMLEFT", 0, -V_PAD)
    end

    return row
end

for i = 1, MAX_ROWS do
    frame.rows[i] = createRow(i)
end

-------------------------------------------------------------------------------
--- Member data storage
-------------------------------------------------------------------------------

local memberData  = {}  -- [i] = { name, unit, class, online, isDead, auras }
local unitToIndex = {}  -- [unit] = i
local rcStatus    = {}  -- [unit] = RC_PENDING | RC_READY | RC_NOT
local activeCount = 0

-------------------------------------------------------------------------------
--- Aura scanning
-------------------------------------------------------------------------------

local function scanMemberAuras(unit, now)
    local result = {
        hasFood  = false, foodTime  = 0, foodAuraID  = nil, foodIconID  = nil,
        hasFlask = false, flaskTime = 0, flaskAuraID = nil, flaskIconID = nil,
        hasRune  = false, runeAuraID  = nil, runeIconID  = nil,
        hasVantus = false, vantusAuraID = nil, vantusIconID = nil,
        raidBuff = {},
    }

    local buffsList = db.raidBuffDefs

    for k = 1, #buffsList do
        result.raidBuff[k] = false
    end

    local i = 1
    while i <= 60 do
        -- GetAuraDataByIndex() itself can raise "Auras cannot be accessed when secret"
        -- when called in a tainted context (e.g. UNIT_AURA triggered by a raid-frame click).
        -- If ok==false the aura is tainted: skip this index and continue.
        -- If ok==true and aura==nil: real end of aura list, stop scanning.
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
        if not ok then
            i = i + 1
        elseif not aura then
            break
        else
            -- tonumber() strips Blizzard's 'secret number' flag from protected aura spellIds.
            -- Without this, table lookups like db.foodBuffIDs[sid] raise 'table index is secret'
            -- even inside pcall on some aura sources (e.g. phased or restricted instances).
            local sid = tonumber(aura.spellId)

            -- Blizzard marks some internal auras as "secret": type() still reports
            -- "number" but using them as a table key raises "table index is secret".
            -- Wrap the entire per-aura block in pcall so those auras are silently skipped.
            if sid and type(sid) == "number" then
                pcall(function()
                    if db.foodBuffIDs[sid] or db.foodIconIDs[aura.icon] then
                        if not result.hasFood or aura.icon == db.foodWellFedIconID then
                            result.hasFood    = true
                            result.foodTime   = (aura.expirationTime or 0) - now
                            result.foodAuraID = aura.auraInstanceID
                            result.foodIconID = aura.icon
                        end
                    end

                    if not result.hasFlask and db.flaskBuffIDs[sid] then
                        result.hasFlask    = true
                        result.flaskTime   = (aura.expirationTime or 0) - now
                        result.flaskAuraID = aura.auraInstanceID
                        result.flaskIconID = aura.icon
                    end

                    if not result.hasRune and db.runeBuffIDs[sid] then
                        result.hasRune    = true
                        result.runeAuraID = aura.auraInstanceID
                        result.runeIconID = aura.icon
                    end

                    if not result.hasVantus and db.vantusBuffIDs[sid] then
                        result.hasVantus    = true
                        result.vantusAuraID = aura.auraInstanceID
                        result.vantusIconID = aura.icon
                    end

                    for k = 1, #buffsList do
                        if not result.raidBuff[k] then
                            local b = buffsList[k]

                            if sid == b[3]
                                or (b[4] and sid == b[4])
                                or (b[5] and b[5][sid])
                            then
                                result.raidBuff[k] = aura.auraInstanceID or true
                            end
                        end
                    end
                end)
            end

            i = i + 1
        end -- else (aura valid)
    end

    return result
end

-------------------------------------------------------------------------------
--- Roster scanning
-------------------------------------------------------------------------------

local function scanAllMembers()
    local maxGroup = F.GetRaidDiffMaxGroup()
    local now = GetTime()
    local count = 0

    wipe(memberData)
    wipe(unitToIndex)

    for j = 1, 40 do
        local name, unit, subgroup, class = F.GetRosterInfo(j)

        if not name then
            if not IsInRaid() then
                break
            end
        elseif subgroup <= maxGroup then
            count = count + 1
            local online = UnitIsConnected(unit)
            local isDead = UnitIsDeadOrGhost(unit)
            memberData[count] = {
                name   = name,
                unit   = unit,
                class  = class,
                online = online,
                isDead = isDead,
                auras  = scanMemberAuras(unit, now),
            }

            unitToIndex[unit] = count

            if not rcStatus[unit] then
                rcStatus[unit] = RC_PENDING
            end
        end
    end

    activeCount = count
end

-------------------------------------------------------------------------------
--- Formatting helpers
-------------------------------------------------------------------------------

local function formatDuration(seconds)
    local mins = ceil(seconds / 60)

    if mins >= 60 then
        return format("%dh", ceil(seconds / 3600))
    end

    return format("%dm", mins > 0 and mins or 0)
end

-------------------------------------------------------------------------------
--- Row rendering
-------------------------------------------------------------------------------

local function applyRowData(row, member)
    if not member then
        row:Hide()

        return
    end

    local unit  = member.unit
    local auras = member.auras

    -- Ready check icon
    local status = rcStatus[unit] or RC_PENDING

    if status == RC_NOT and not member.online then
        row.rcIcon:SetSize(RC_ICON_WIDTH, RC_ICON_WIDTH)
        row.rcIcon:SetTexture(RC_TEXTURE_OFFLINE)
    elseif status == RC_PENDING and member.isDead then
        row.rcIcon:SetSize(RC_ICON_WIDTH * 26 / 33, RC_ICON_WIDTH)
        row.rcIcon:SetAtlas(RC_ATLAS_DEAD)
    else
        row.rcIcon:SetSize(RC_ICON_WIDTH, RC_ICON_WIDTH)
        row.rcIcon:SetTexture(RC_TEXTURES[status])
    end

    -- Row background (class color)
    local color = RAID_CLASS_COLORS[member.class]

    if color then
        row.bg:SetVertexColor(color.r, color.g, color.b, 0.25)
    else
        row.bg:SetVertexColor(0.5, 0.5, 0.5, 0.25)
    end

    -- Player name (white)
    local shortName = F.shortName(member.name)

    if not member.online then
        row.nameText:SetTextColor(COLOR_NAME_OFFLINE.r, COLOR_NAME_OFFLINE.g, COLOR_NAME_OFFLINE.b)
    elseif member.isDead then
        row.nameText:SetTextColor(COLOR_NAME_DEAD.r, COLOR_NAME_DEAD.g, COLOR_NAME_DEAD.b)
    else
        row.nameText:SetTextColor(COLOR_NAME_NORMAL.r, COLOR_NAME_NORMAL.g, COLOR_NAME_NORMAL.b)
    end

    row.nameText:SetText(shortName)

    -- Player Durability
    -- For the local player we query the API directly so the value is always
    -- available immediately (LibOpenRaid data may not have arrived yet, which
    -- caused DHs and other classes to show '-' or nothing on frame open).
    -- IMPORTANT: Use UnitIsUnit(unit, "player") not unit == "player" because
    -- in a raid group our own unit ID is "raidN", never the literal "player".
    -- For remote players we fall back to LibOpenRaid as before.
    do
        local durPct = nil

        if UnitIsUnit(member.unit, "player") then
            local total, count = 0, 0
            for i = 1, 18 do
                local cur, maxD = GetInventoryItemDurability(i)
                if cur and maxD and maxD > 0 then
                    total = total + (cur / maxD * 100)
                    count = count + 1
                end
            end
            if count > 0 then
                durPct = floor(total / count)
            end
        elseif openRaidLib and openRaidLib.GetUnitGear then
            local unitGear = openRaidLib.GetUnitGear(member.unit)
            if unitGear and unitGear.durability and unitGear.durability > 0 then
                durPct = unitGear.durability
            end
        end

        if durPct then
            row.durabilityText:SetFormattedText("%d%%", durPct)
            if durPct < 20 then
                row.durabilityText:SetTextColor(1, 0.2, 0.2)
            elseif durPct < 50 then
                row.durabilityText:SetTextColor(1, 0.8, 0)
            else
                row.durabilityText:SetTextColor(0.8, 0.8, 0.8)
            end
        else
            -- LibOpenRaid hasn't received data yet for this remote player.
            -- Show '-' to distinguish from genuinely broken gear (~1-5%).
            row.durabilityText:SetText("-")
            row.durabilityText:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    -- Food
    if auras.hasFood then
        row.foodIcon:SetDesaturated(false)
        row.foodIcon:SetVertexColor(1, 1, 1, 1)
        row.foodIcon:SetTexture(auras.foodIconID or db.food_icon_id)
        row.foodTime:SetText(formatDuration(auras.foodTime))

        if auras.foodTime < EXPIRE_WARN_SECONDS then
            row.foodTime:SetTextColor(COLOR_TIME_WARN.r, COLOR_TIME_WARN.g, COLOR_TIME_WARN.b)
        else
            row.foodTime:SetTextColor(COLOR_TIME_NORMAL.r, COLOR_TIME_NORMAL.g, COLOR_TIME_NORMAL.b)
        end
    else
        row.foodIcon:SetTexture(db.food_icon_id)
        row.foodIcon:SetDesaturated(true)
        row.foodIcon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        row.foodTime:SetText("")
    end

    row.foodOverlay.unit   = unit
    row.foodOverlay.auraID = auras.foodAuraID

    -- Flask
    if auras.hasFlask then
        row.flaskIcon:SetDesaturated(false)
        row.flaskIcon:SetVertexColor(1, 1, 1, 1)
        row.flaskIcon:SetTexture(auras.flaskIconID or db.flask_icon_id)
        row.flaskTime:SetText(formatDuration(auras.flaskTime))

        if auras.flaskTime < EXPIRE_WARN_SECONDS then
            row.flaskTime:SetTextColor(COLOR_TIME_WARN.r, COLOR_TIME_WARN.g, COLOR_TIME_WARN.b)
        else
            row.flaskTime:SetTextColor(COLOR_TIME_NORMAL.r, COLOR_TIME_NORMAL.g, COLOR_TIME_NORMAL.b)
        end
    else
        row.flaskIcon:SetTexture(db.flask_icon_id)
        row.flaskIcon:SetDesaturated(true)
        row.flaskIcon:SetVertexColor(1, 1, 1, MISSING_ALPHA)
        row.flaskTime:SetText("")
    end

    row.flaskOverlay.unit   = unit
    row.flaskOverlay.auraID = auras.flaskAuraID

    -- Augment Rune
    row.runeIcon:SetTexture(auras.runeIconID or db.rune_icon_id)
    row.runeIcon:SetDesaturated(not auras.hasRune)
    row.runeIcon:SetVertexColor(1, 1, 1, auras.hasRune and 1 or MISSING_ALPHA)
    row.runeOverlay.unit   = unit
    row.runeOverlay.auraID = auras.runeAuraID

    -- Vantus Rune
    row.vantusIcon:SetTexture(auras.vantusIconID or db.vantus_icon_id)
    row.vantusIcon:SetDesaturated(not auras.hasVantus)
    row.vantusIcon:SetVertexColor(1, 1, 1, auras.hasVantus and 1 or MISSING_ALPHA)
    row.vantusOverlay.unit   = unit
    row.vantusOverlay.auraID = auras.vantusAuraID

    -- Raid buffs
    for k = 1, #db.raidBuffDefs do
        local auraID = auras.raidBuff[k]
        local has = auraID and auraID ~= false

        row.raidBuffIcons[k]:SetDesaturated(not has)
        row.raidBuffIcons[k]:SetVertexColor(1, 1, 1, has and 1 or MISSING_ALPHA)
        row.raidBuffOverlays[k].unit = unit

        if has and type(auraID) == "number" then
            row.raidBuffOverlays[k].auraID = auraID
        else
            row.raidBuffOverlays[k].auraID = nil
        end
    end

    row:Show()
end

-------------------------------------------------------------------------------
--- Title bar helpers
-------------------------------------------------------------------------------

-- Returns true if the column buff is considered "bad" for a member.
-- bad = missing, or (food/flask) present but expiring soon.
local function isBad(member, colIndex)
    local a = member.auras

    if colIndex == 1 then
        return not a.hasFood or a.foodTime < EXPIRE_WARN_SECONDS
    end

    if colIndex == 2 then
        return not a.hasFlask or a.flaskTime < EXPIRE_WARN_SECONDS
    end

    if colIndex == 3 then
        return not a.hasRune
    end

    if colIndex == 4 then
        return not a.hasVantus
    end

    local raidIdx = colIndex - 4
    return not a.raidBuff[raidIdx] or a.raidBuff[raidIdx] == false
end

local function refreshTitleBar()
    local numCols = #titleBar.colIcons

    for i = 1, numCols do
        local anyBad = false

        for j = 1, activeCount do
            local member = memberData[j]

            if member and member.online and isBad(member, i) then
                anyBad = true
                break
            end
        end

        titleBar.colIcons[i]:SetTexture(anyBad and RC_TEXTURES[RC_NOT] or RC_TEXTURES[RC_READY])
    end
end

local function updateTitleCount()
    local readyCount = 0

    for unit, status in pairs(rcStatus) do
        if status == RC_READY or status == RC_NOT then
            readyCount = readyCount + 1
        end
    end

    titleBar.countText:SetTextColor(1, 1, 1)
    titleBar.countText:SetText(readyCount .. "/" .. activeCount)
end

local function showFinishedSummary()
    local notReadyCount = 0
    local afkCount      = 0

    for i = 1, activeCount do
        local member = memberData[i]
        local status = rcStatus[member.unit]

        if status == RC_PENDING then
            afkCount = afkCount + 1
        elseif status == RC_NOT then
            notReadyCount = notReadyCount + 1
        end
    end

    if notReadyCount > 0 then
        local c = COLOR_SUMMARY_NOT_READY
        titleBar.countText:SetTextColor(c.r, c.g, c.b)
        local s = notReadyCount == 1 and "Player" or "Players"
        titleBar.countText:SetText(notReadyCount .. " " .. s .. " not Ready")
    elseif afkCount > 0 then
        local c = COLOR_SUMMARY_AFK
        titleBar.countText:SetTextColor(c.r, c.g, c.b)
        local verb = afkCount == 1 and "Player is" or "Players are"
        titleBar.countText:SetText(afkCount .. " " .. verb .. " AFK")
    else
        local c = COLOR_SUMMARY_READY
        titleBar.countText:SetTextColor(c.r, c.g, c.b)
        titleBar.countText:SetText("Everyone is Ready!")
    end
end

local function refreshRow(index)
    local row = frame.rows[index]

    if not row then
        return
    end

    applyRowData(row, memberData[index])
    refreshTitleBar()
end

local function refreshAllRows()
    for i = 1, activeCount do
        applyRowData(frame.rows[i], memberData[i])
    end

    for i = activeCount + 1, MAX_ROWS do
        frame.rows[i]:Hide()
    end

    -- SetHeight is protected during combat lockdown (ADDON_ACTION_BLOCKED).
    -- The frame is already alpha-suppressed in OnCombat(), so skip the resize.
    if not InCombatLockdown() then
        local height = FRAME_PAD * 2
            + TITLE_HEIGHT + FRAME_PAD
            + activeCount * ROW_HEIGHT
            + (activeCount > 1 and (activeCount - 1) * V_PAD or 0)

        frame:SetHeight(height)
    end

    refreshTitleBar()
end

function Module.OnLibOpenRaidUpdate()
    if frame:IsShown() then
        refreshAllRows()
    end
end

if openRaidLib then
    openRaidLib.RegisterCallback(Module, "GearUpdate", "OnLibOpenRaidUpdate")
    openRaidLib.RegisterCallback(Module, "GearDurabilityUpdate", "OnLibOpenRaidUpdate")
end

-------------------------------------------------------------------------------
--- Ready check lifecycle
-------------------------------------------------------------------------------

local hideTimer
local rcTickTimer
local rcEndTime   = 0
local rcDuration  = 0

local function cancelHideTimer()
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
end

local function cancelRcTick()
    if rcTickTimer then
        rcTickTimer:Cancel()
        rcTickTimer = nil
    end
end

local function stopProgressBar()
    cancelRcTick()
    titleBar.progress:Hide()
    titleBar.timerText:SetText("")
end

local function tickProgressBar()
    local now       = GetTime()
    local remaining = rcEndTime - now

    if remaining <= 0 then
        stopProgressBar()

        return
    end

    local frac = remaining / rcDuration
    titleBar.progress:SetWidth(math.max(1, (FRAME_WIDTH - FRAME_PAD * 2) * frac))

    local secs = ceil(remaining)
    titleBar.timerText:SetText(secs .. "s")
end

local function startProgressBar(duration)
    rcDuration = duration
    rcEndTime  = GetTime() + duration

    titleBar.progress:SetWidth(FRAME_WIDTH - FRAME_PAD * 2)
    titleBar.progress:Show()

    cancelRcTick()
    -- PERF: 0.2s (5Hz) is visually identical to 0.1s for a countdown bar; halves SetWidth calls.
    rcTickTimer = C_Timer.NewTicker(0.2, tickProgressBar)
end

function frame:OnReadyCheck(initiatorUnit, timeToHide)
    if not Module.GetSetting("raidFrame_enabled") then
        return
    end

    cancelHideTimer()
    wipe(rcStatus)

    self.manualShow = (timeToHide == 0)

    if openRaidLib then
        if openRaidLib.GearManager and openRaidLib.GearManager.GetPlayerFullGearInfo then
            local pGear = openRaidLib.GearManager.GetPlayerFullGearInfo()
            if pGear then
                openRaidLib.GearManager.AddUnitGearList(UnitName("player"), unpack(pGear))
            end
        end
        openRaidLib.RequestAllData()
    end

    scanAllMembers()

    -- The initiator never receives READY_CHECK_CONFIRM for themselves;
    -- auto-mark them as ready so their row shows a check immediately.
    if initiatorUnit then
        for unit in pairs(unitToIndex) do
            if UnitIsUnit(unit, initiatorUnit) then
                rcStatus[unit] = RC_READY
                break
            end
        end
    end

    refreshAllRows()
    updateTitleCount()

    if not self.manualShow then
        startProgressBar(timeToHide or 30)
    else
        stopProgressBar()
        titleBar.timerText:SetText("")
    end

    restorePosition()
    self:Show()
end

function frame:OnReadyCheckConfirm(unit, ready)
    local index = unitToIndex[unit]

    if not index then
        return
    end

    rcStatus[unit] = ready and RC_READY or RC_NOT

    local row = self.rows[index]

    if row then
        local member = memberData[index]
        local newStatus = rcStatus[unit]

        row.rcIcon:SetSize(RC_ICON_WIDTH, RC_ICON_WIDTH)

        if newStatus == RC_NOT and member and not member.online then
            row.rcIcon:SetTexture(RC_TEXTURE_OFFLINE)
        else
            row.rcIcon:SetTexture(RC_TEXTURES[newStatus])
        end
    end

    updateTitleCount()
end

function frame:OnReadyCheckFinished()
    stopProgressBar()
    showFinishedSummary()

    if self.manualShow then
        return
    end

    cancelHideTimer()

    hideTimer = C_Timer.NewTimer(15, function()
        if InCombatLockdown() then
            frame:SetAlpha(0)
            frame.pendingHide = true
        else
            frame:Hide()
        end
    end)
end

function frame:OnCombat()
    cancelHideTimer()
    -- Cannot call :Hide() during combat lockdown (ADDON_ACTION_BLOCKED).
    -- Suppress visually and defer the actual Hide() to PLAYER_REGEN_ENABLED.
    self:SetAlpha(0)
    self.pendingHide = true
end

function frame:OnUnitAura(unit)
    local index = unitToIndex[unit]

    if not index then
        return
    end

    local member = memberData[index]

    if not member then
        return
    end

    -- Outer pcall: catches any residual taint that escapes the inner per-aura pcall
    -- (e.g. if the entire UNIT_AURA call-stack is tainted in a raid context).
    local ok, result = pcall(scanMemberAuras, unit, GetTime())
    if ok and result then member.auras = result end
    refreshRow(index)
end

function frame:OnHide()
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("READY_CHECK_CONFIRM")
    cancelHideTimer()
    cancelRcTick()
    stopProgressBar()
    self.manualShow = false
end

-------------------------------------------------------------------------------
--- Event wiring
-------------------------------------------------------------------------------

frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "READY_CHECK" then
        local initiatorUnit, duration = arg1, arg2
        self:OnReadyCheck(initiatorUnit, duration)
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("READY_CHECK_CONFIRM")

        return
    end

    if event == "READY_CHECK_CONFIRM" then
        local unit, isReady = arg1, arg2
        self:OnReadyCheckConfirm(unit, isReady)

        return
    end

    if event == "READY_CHECK_FINISHED" then
        self:OnReadyCheckFinished()

        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        self:OnCombat()

        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if self.pendingHide then
            self.pendingHide = nil
            self:SetAlpha(1)
            self:Hide()
        end

        return
    end

    if event == "UNIT_AURA" then
        local unit = arg1
        self:OnUnitAura(unit)

        return
    end

    if event == "ADDON_LOADED" then
        local addonName = arg1

        if addonName == ADDON_NAME then
            self:UnregisterEvent("ADDON_LOADED")
        end

        return
    end
end)

frame:SetScript("OnHide", function(self)
    self:OnHide()
end)

frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("READY_CHECK_FINISHED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("ADDON_LOADED")

-------------------------------------------------------------------------------
--- Pull Timer Auto-Hide
--- Hides the Consumables Raid Frame when a pull timer reaches 5 seconds.
--- Supports: BigWigs (BigWigs_StartPull / BigWigs_StopPull)
---           DBM     (DBM_TimerStart with type "pull")
--- Only triggers when the frame is shown (after a Ready Check).
--- Cancelled automatically if the pull is aborted.
-------------------------------------------------------------------------------

local pullHideTimer

local function cancelPullHideTimer()
    if pullHideTimer then
        pullHideTimer:Cancel()
        pullHideTimer = nil
    end
end

local PULL_CLOSE_BEFORE_SECONDS = 5  -- hide frame N seconds before pull

local function OnPullTimerStart(seconds)
    if not frame:IsShown() then return end
    cancelPullHideTimer()

    -- Schedule hide so that the frame disappears PULL_CLOSE_BEFORE_SECONDS before pull
    local delay = (seconds or 0) - PULL_CLOSE_BEFORE_SECONDS
    if delay <= 0 then
        -- Pull is already within 5s or shorter than 5s: hide immediately
        cancelHideTimer()
        frame:Hide()
        return
    end

    pullHideTimer = C_Timer.NewTimer(delay, function()
        pullHideTimer = nil
        if frame:IsShown() then
            cancelHideTimer()
            frame:Hide()
        end
    end)
end

local function OnPullTimerStop()
    cancelPullHideTimer()
end

-- BigWigs: uses BigWigsLoader message bus (available even when BigWigs core not loaded)
local function HookBigWigsPullTimer()
    local BWLoader = BigWigsLoader
    if not BWLoader then return end
    BWLoader.RegisterMessage(Module, "BigWigs_StartPull", function(_, _, seconds)
        OnPullTimerStart(seconds)
    end)
    BWLoader.RegisterMessage(Module, "BigWigs_StopPull", function()
        OnPullTimerStop()
    end)
end

-- DBM: fires DBM_TimerStart with type containing "pull" for pull countdowns
local function HookDBMPullTimer()
    if not DBM then return end
    -- DBM uses callback events registered via DBM:RegisterCallback
    -- Alternatively, hook via a frame listening to the DBM event frame messages.
    -- DBM fires DBM_TimerStart(id, msg, timerDuration, type, ...) where type == "pull"
    local dbmFrame = CreateFrame("Frame")
    dbmFrame:RegisterEvent("DBM_TIMER_START")  -- fired by DBM as virtual event
    dbmFrame:SetScript("OnEvent", function(_, event, ...)
        -- DBM doesn't use Blizzard events; this is a no-op fallback.
        -- Real DBM hook is via DBM.RegisterCallback below.
    end)

    -- DBM 9.x callback API
    if DBM.RegisterCallback then
        DBM:RegisterCallback("DBM_TimerStart", function(_, timer)
            if timer and timer.type and timer.type:find("pull") then
                OnPullTimerStart(timer.totalTime)
            end
        end)
        DBM:RegisterCallback("DBM_TimerStop", function(_, timer)
            if timer and timer.type and timer.type:find("pull") then
                OnPullTimerStop()
            end
        end)
    end
end

-- C_Timer.After(0) defers until the next frame tick, after all addons have loaded.
-- BigWigs and DBM are guaranteed to be available at that point.
C_Timer.After(0, function()
    HookBigWigsPullTimer()
    HookDBMPullTimer()
end)


Module.color = "cff00cc"

Module.db = Module.db or {}

-------------------------------------------------------------------------------
--- Event handler
-------------------------------------------------------------------------------

Module.consumables:SetScript("OnEvent", function(self, event, unit, time_to_hide)
    if event == "READY_CHECK" then
        if not Module.GetSetting("consumables_enabled") then
            self:Hide()

            return
        end

        self:Show()
        self:Update()
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("UNIT_INVENTORY_CHANGED")

        if self.cancelDelay then
            self.cancelDelay:Cancel()
            self.cancelDelay = nil
        end

        if time_to_hide ~= 0 then
            self.cancelDelay = C_Timer.NewTimer(time_to_hide or 12, function()
                self:UnregisterEvent("UNIT_AURA")
                self:UnregisterEvent("UNIT_INVENTORY_CHANGED")

                if self.isRLpos then
                    self:Hide()
                end
            end)
        end

        if unit and UnitIsUnit(unit, "player") then
            self:Repos(true)
        else
            self:Repos()
        end

    elseif event == "READY_CHECK_FINISHED"
        or event == "PLAYER_REGEN_DISABLED" then

        Module.consumables:OnHide()

        if event == "PLAYER_REGEN_DISABLED" then
            self:Hide()
            -- raidFrame:Hide() is guarded in frame:OnCombat() via alpha suppression
        end

        if self.isRLpos
            and not InCombatLockdown()
        then
            self:Hide()
        end

    elseif event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
        if unit == "player" then
            if self.updateTimer then
                self.updateTimer:Cancel()
            end
            self.updateTimer = C_Timer.NewTimer(0.2, function()
                self:Update()
                self.updateTimer = nil
            end)
        end
    end
end)

Module.consumables:SetScript("OnHide", function(self)
    Module.consumables:OnHide()

    if not InCombatLockdown()
        and self.dragHandle:IsShown()
    then
        self.dragHandle:Hide()
    end
end)

Module.consumables:RegisterEvent("READY_CHECK")
Module.consumables:RegisterEvent("READY_CHECK_FINISHED")
Module.consumables:RegisterEvent("PLAYER_REGEN_DISABLED")
-- Initialization handled via Module.Initialize -> ApplySettings
-- Module.consumables:Show()

-------------------------------------------------------------------------------
--- Slash Commands
-------------------------------------------------------------------------------

SLASH_GUIC1 = "/guic"
SlashCmdList["GUIC"] = function(msg)
    msg = strlower(strtrim(msg))

    if msg == "test" or msg == "t" then
        local name = UnitName("player")
        Module.consumables:GetScript("OnEvent")(Module.consumables,
                                             "READY_CHECK",
                                             name, 0)
        Module.raidFrame:GetScript("OnEvent")(Module.raidFrame,
                                           "READY_CHECK",
                                           name, 0)

    elseif msg == "hide" or msg == "h" then
        Module.consumables:GetScript("OnEvent")(Module.consumables,
                                             "READY_CHECK_FINISHED",
                                             "")
        Module.raidFrame:Hide()

    elseif msg == "report" or msg == "r" then
        Module.chatReport.Test(false)

    elseif msg == "reportchat" or msg == "rc" then
        Module.chatReport.Test(true)

    elseif msg == "settings" or msg == "s" then
        if Module.settingsCategory then
            Settings.OpenToCategory(Module.settingsCategory:GetID())
        end

    else
        print("|" .. Module.color .. "ff" .. "GravityUI Consumables|r commands:")
        print("  /guic test, t - Show a test consumable icon frame")
        print("  /guic hide, h - Immediately hide the consumable icon frame")
        print("  /guic report, r - Print consumable report locally")
        print("  /guic reportchat, rc - Send consumable report to chat")
        print("  /guic settings, s - Open settings panel")
    end
end

function Module.ApplySettings()
    local db = ns.GetDB()
    local c = db and db.screenindicators and db.screenindicators.consumables
    if not c then return end

    -- Raid Frame Scale
    if c.raidFrameScale and Module.raidFrame then
        Module.raidFrame:SetScale(c.raidFrameScale)
    end

    -- Personal Frame Toggles
    if Module.GetSetting('consumables_enabled') then
        Module.consumables:RegisterEvent("READY_CHECK")
        Module.consumables:RegisterEvent("READY_CHECK_FINISHED")
        Module.consumables:RegisterEvent("PLAYER_REGEN_DISABLED")
    else
        Module.consumables:UnregisterEvent("READY_CHECK")
        Module.consumables:UnregisterEvent("READY_CHECK_FINISHED")
        Module.consumables:UnregisterEvent("PLAYER_REGEN_DISABLED")
        Module.consumables:Hide()
    end

    -- Raid Frame Toggles
    if Module.GetSetting('raidFrame_enabled') then
        if Module.raidFrame then
            Module.raidFrame:RegisterEvent("READY_CHECK")
            Module.raidFrame:RegisterEvent("READY_CHECK_FINISHED")
            Module.raidFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        end
    else
        if Module.raidFrame then
            Module.raidFrame:UnregisterEvent("READY_CHECK")
            Module.raidFrame:UnregisterEvent("READY_CHECK_FINISHED")
            Module.raidFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")
            if not InCombatLockdown() then
                Module.raidFrame:Hide()
            else
                Module.raidFrame:SetAlpha(0)
                Module.raidFrame.pendingHide = true
            end
        end
    end
end

function Module.Initialize()
    local sr, sg, sb, sa = 0, 0.749, 1, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
    if ns.GetAccentColor then sr, sg, sb, sa = ns.GetAccentColor() end
    if ns.GetThemeBgColor then bgr, bgg, bgb, bga = ns.GetThemeBgColor() end

    if Module.raidFrame then
        Module.raidFrame:SetBackdropBorderColor(sr, sg, sb, sa)
        Module.raidFrame:SetBackdropColor(bgr, bgg, bgb, bga)
    end
    
    if Module.consumables then
        Module.consumables:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        Module.consumables:SetBackdropBorderColor(sr, sg, sb, sa)
        Module.consumables:SetBackdropColor(bgr, bgg, bgb, bga)
    end

    if Module.consumables and Module.consumables.dragHandle then
        Module.consumables.dragHandle.bg:SetColorTexture(bgr, bgg, bgb, 0.9)
        Module.consumables.dragHandle.border:SetColorTexture(sr, sg, sb, 1)
        Module.consumables.dragHandle.text:SetFont(ns.GetFont(), 12, "OUTLINE")
    end

    if Module.consumables and Module.consumables.buttons then
        for _, btn in pairs(Module.consumables.buttons) do
            if btn.timeleft then btn.timeleft:SetFont(ns.GetFont(), 12, "OUTLINE") end
            if btn.count then btn.count:SetFont(ns.GetFont(), 14, "OUTLINE") end
        end
    end

    if Module.raidFrame then
        if Module.raidFrame.title then
            if Module.raidFrame.title.text then Module.raidFrame.title.text:SetFont(ns.GetFont(), 12, "OUTLINE") end
        end
        if Module.raidFrame.rows then
            for _, row in pairs(Module.raidFrame.rows) do
                if row.name then row.name:SetFont(ns.GetFont(), 12, "OUTLINE") end
                if row.timeleft then row.timeleft:SetFont(ns.GetFont(), 12, "OUTLINE") end
            end
        end
    end

    Module.ApplySettings()
end

