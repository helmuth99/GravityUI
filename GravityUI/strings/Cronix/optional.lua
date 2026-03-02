-- Optional Addons Data Export
-- Extracted from User SavedVariables (21.02.2026)

if not GravityUI.profiles["Cronix"] then return end

local imports = GravityUI.profiles["Cronix"].imports

-- 1. BAGANATOR
-- Data from BAGANATOR_CONFIG.Profiles["GravityUI"]
imports["Baganator"] = {
    data = {
["guild_view_width"] = 14,
["empty_slot_background"] = true,
["new_items_flashing"] = true,
["reduce_spacing"] = false,
["bag_view_type"] = "category",
["automatic_categories_added"] = {
["default_miscellaneous"] = true,
["default_armor"] = true,
["default_itemenhancement"] = true,
["default_toy"] = true,
["default_hearthstone"] = true,
["default_other"] = true,
["default_battlepet"] = true,
["default_food"] = true,
["default_recipe"] = true,
["default_junk"] = true,
["default_reagent"] = true,
["default_consumable"] = true,
["default_tradegoods"] = true,
["default_key"] = true,
["default_container"] = true,
["default_auto_equipment_sets"] = true,
["default_profession"] = true,
["default_potion"] = true,
["default_gem"] = true,
["default_questitem"] = true,
["default_weapon"] = true,
},
["show_search_box"] = true,
["debug_categories_search"] = false,
["bank_view_show_bag_slots"] = false,
["bank_view_width"] = 26,
["sort_method"] = "item-level",
["reverse_groups_sort_order"] = false,
["auto_open"] = {
["merchant"] = true,
["void_storage"] = false,
["item_upgrade"] = true,
["guild_bank"] = true,
["trade_partner"] = true,
["tradeskill"] = false,
["auction_house"] = true,
["character_panel"] = false,
["scrapping_machine"] = true,
["item_interaction"] = true,
["mail"] = true,
["sockets"] = true,
["forge_of_bonds"] = false,
["bank"] = true,
},
["icon_corners_auto_insert_applied"] = {
["battle_pet_level"] = true,
["keystone_level"] = true,
["bag_type"] = true,
},
["show_recents_tabs_main_view"] = false,
["upgrade_plugin_ignored"] = {
},
["category_hidden"] = {
["1"] = false,
["18"] = false,
["14"] = false,
["default_hearthstone"] = false,
["27"] = false,
["26"] = false,
["20"] = false,
["11"] = false,
["default_housing"] = false,
},
["junk_plugin_ignored"] = {
},
["icon_flash_similar_alt"] = false,
["character_bank_view_width"] = 14,
["no_frame_borders"] = false,
["warband_current_tab"] = 0,
["category_item_grouping"] = true,
["icon_top_left_corner_array"] = {
"battle_pet_level",
"keystone_level",
"item_level",
},
["main_view_show_bag_slots"] = false,
["category_display_order"] = {
"default_auto_recents",
"_1",
"19",
"13",
"10",
"5",
"__end",
"_2",
"default_auto_equipment_sets",
"7",
"26",
"23",
"8",
"21",
"25",
"24",
"2",
"11",
"12",
"15",
"__end",
"_3",
"20",
"22",
"3",
"__end",
"_4",
"17",
"4",
"18",
"16",
"default_housing",
"9",
"27",
"1",
"14",
"__end",
"_5",
"default_hearthstone",
"default_miscellaneous",
"default_special_empty",
"__end",
"default_other",
},
["current_skin"] = "dark",
["hide_boe_on_common"] = true,
["bank_view_type"] = "category",
["icon_grey_junk"] = true,
["main_view_position"] = {
"BOTTOMRIGHT",
-4.89013671875,
2.66734790802002,
},
["bank_only_view_show_bag_slots"] = false,
["icon_bottom_left_corner_array"] = {
"bag_type",
"equipment_set",
"junk",
},
["icon_top_right_corner_array"] = {
},
["icon_bottom_right_corner_array"] = {
"quantity",
},
["bank_view_position"] = {
"BOTTOMLEFT",
11.11108112335205,
235.0554504394531,
},
["recent_timeout"] = 15,
["currency_headers_collapsed"] = {
},
["recent_include_owned"] = false,
["category_sort_method"] = "item-level",
["icon_context_fading"] = true,
["guild_view_position_2"] = {
"TOPLEFT",
150.4443664550781,
-143.148193359375,
},
["icon_equipment_set_border"] = true,
["debug_timers"] = false,
["seen_welcome"] = 1,
["hide_special_container"] = {
},
["category_sections"] = {
["1"] = {
["name"] = "General",
},
["3"] = {
["name"] = "Crafting",
},
["2"] = {
["name"] = "Equipment",
},
["5"] = {
["name"] = "Misc",
},
["4"] = {
["name"] = "Stuff",
},
},
["character_select_position"] = {
"RIGHT",
"Baganator_CategoryViewBackpackViewFramedark",
"LEFT",
0,
0,
},
["category_edit_search_mode"] = "visual",
["category_horizontal_spacing_2"] = 0.3,
["bag_view_show_bag_slots"] = false,
["category_default_import"] = 3,
["debug_categories"] = false,
["character_bank_current_tab"] = 0,
["category_horizontal_spacing"] = 0.15,
["migrated_sort_method"] = true,
["upgrade_plugin"] = "none",
["junk_plugin"] = "poor_quality",
["category_modifications"] = {
["23"] = {
["priority"] = -1,
["addedItems"] = {
["i:133301"] = true,
["i:178780"] = true,
},
},
["default_miscellaneous"] = {
["addedItems"] = {
["i:244465"] = true,
["i:233186"] = true,
["i:259361"] = true,
["i:253580"] = true,
["i:255826"] = true,
["i:260531"] = true,
},
},
["22"] = {
["priority"] = -1,
["addedItems"] = {
["i:222548"] = true,
["i:222551"] = true,
["i:256645"] = true,
},
},
["21"] = {
["priority"] = 3,
},
["20"] = {
["showGroupPrefix"] = true,
["priority"] = 0,
["addedItems"] = {
["i:231756"] = true,
["i:231757"] = true,
["i:211297"] = true,
["i:211296"] = true,
},
},
["17"] = {
["addedItems"] = {
["i:180653"] = true,
},
["priority"] = -1,
},
["27"] = {
["showGroupPrefix"] = true,
["priority"] = -1,
["addedItems"] = {
["i:264882"] = true,
},
},
["default_housing"] = {
["showGroupPrefix"] = true,
["priority"] = -1,
["addedItems"] = {
["i:246838"] = true,
["i:252041"] = true,
["i:252039"] = true,
},
},
["default_hearthstone"] = {
["showGroupPrefix"] = true,
["priority"] = -1,
["addedItems"] = {
["i:6948"] = true,
["i:110560"] = true,
},
},
["default_other"] = {
["addedItems"] = {
["i:220756"] = true,
["i:232049"] = true,
},
},
["8"] = {
["priority"] = 0,
},
["25"] = {
["priority"] = 0,
},
["15"] = {
["priority"] = -1,
},
["14"] = {
["showGroupPrefix"] = true,
["priority"] = 3,
},
["18"] = {
["priority"] = -1,
["addedItems"] = {
["i:86143"] = true,
["i:163036"] = true,
["i:127755"] = true,
["i:92682"] = true,
["i:116374"] = true,
["i:92683"] = true,
["i:98114"] = true,
["i:98715"] = true,
["i:116421"] = true,
["i:116420"] = true,
["i:89906"] = true,
["i:122457"] = true,
["i:116429"] = true,
["i:71153"] = true,
["i:116424"] = true,
["i:116418"] = true,
},
},
["1"] = {
["showGroupPrefix"] = true,
["priority"] = -1,
["addedItems"] = {
["i:225557"] = true,
["i:225767"] = true,
["i:235897"] = true,
},
},
["19"] = {
["priority"] = -1,
["addedItems"] = {
["i:241304"] = true,
["i:258138"] = true,
},
},
["3"] = {
["priority"] = -1,
},
["2"] = {
["priority"] = 3,
},
["5"] = {
["priority"] = -1,
["addedItems"] = {
["i:132514"] = true,
},
},
["4"] = {
["priority"] = 3,
},
["7"] = {
["addedItems"] = {
["i:159972"] = true,
["i:133299"] = true,
["i:133298"] = true,
["i:178701"] = true,
["i:133286"] = true,
["i:133363"] = true,
["i:159427"] = true,
["i:133306"] = true,
["i:159429"] = true,
},
["priority"] = -1,
},
["6"] = {
["priority"] = -1,
["addedItems"] = {
["i:226505"] = true,
["i:213777"] = true,
},
},
["9"] = {
["priority"] = -1,
},
["24"] = {
["priority"] = 3,
},
["16"] = {
["priority"] = -1,
["addedItems"] = {
["i:163604"] = true,
["i:45047"] = true,
},
},
["26"] = {
["showGroupPrefix"] = true,
["priority"] = 0,
["addedItems"] = {
["i:133287"] = true,
["i:178736"] = true,
},
},
["13"] = {
["priority"] = -1,
["addedItems"] = {
["i:222781"] = true,
["i:222778"] = true,
["i:242764"] = true,
["i:222776"] = true,
["i:266985"] = true,
["i:222768"] = true,
},
},
["12"] = {
["priority"] = -1,
["addedItems"] = {
["i:222738"] = true,
},
},
["11"] = {
["showGroupPrefix"] = true,
["priority"] = 3,
},
["10"] = {
["addedItems"] = {
["i:65274"] = true,
["i:64401"] = true,
["i:188152"] = true,
["i:65360"] = true,
["i:168222"] = true,
["i:109076"] = true,
["i:64402"] = true,
["i:132516"] = true,
["i:64400"] = true,
["i:111820"] = true,
["i:221903"] = true,
["i:109253"] = true,
["i:221949"] = true,
["i:49040"] = true,
["i:203722"] = true,
["i:112384"] = true,
},
["priority"] = 3,
},
},
["category_migration"] = 5,
["currencies_tracked"] = {
["Cronìx-Blackhand"] = {
},
["Givemeloot-Blackhand"] = {
},
["Cròníx-Onyxia"] = {
},
["Givemeloot-Eredar"] = {
},
["Cròníx-Blackhand"] = {
},
["Cronîx-Blackhand"] = {
},
["Evonix-Blackhand"] = {
},
["Bláckstar-Kel'Thuzad"] = {
},
},
["guild_bank_sort_method"] = "unset",
["warband_bank_view_width"] = 16,
["guild_view_position"] = {
"LEFT",
583.5559692382812,
150.0554809570313,
},
["add_to_category_buttons_2"] = "drag+alt",
["view_type"] = "unset",
["bank_current_tab"] = 2,
["icon_text_quality_colors"] = true,
["bag_empty_space_at_top"] = false,
["icon_text_font_size"] = 14,
["sort_ignore_slots_at_end"] = false,
["disabled_skins"] = {
},
["view_alpha"] = 1,
["sort_ignore_slots_count_2"] = {
["Cronîx-Blackhand"] = 0,
},
["sort_ignore_bank_slots_count"] = {
["Cronîx-Blackhand"] = 0,
},
["category_group_empty_slots"] = true,
["debug_keywords"] = false,
["skins"] = {
["elvui"] = {
["use_bag_font"] = false,
},
["blizzard"] = {
["no_frame_borders"] = true,
["view_transparency"] = 0,
["empty_slot_background"] = true,
},
["dark"] = {
["view_transparency"] = 0.2,
["square_icons"] = true,
["no_frame_borders"] = true,
["empty_slot_background"] = false,
},
},
["recent_characters_main_view"] = {
"Cronîx-Blackhand",
"Cronìx-Blackhand",
"Crônix-Blackhand",
"Cròníx-Blackhand",
},
["auto_sort_on_open"] = false,
["bag_view_width"] = 16,
["setting_anchors"] = false,
["show_buttons_on_alt"] = false,
["category_section_toggled"] = {
["1"] = false,
["Main"] = false,
["Crafting"] = false,
["General"] = false,
["Equipment"] = false,
},
["guild_view_dialog_position"] = {
"TOP",
"UIParent",
"TOP",
-5.999967098236084,
-170.9444885253906,
},
["saved_searches"] = {
},
["bank_only_view_position"] = {
"LEFT",
549.7777099609375,
20.44439697265625,
},
["bag_view_position"] = {
"BOTTOMRIGHT",
-8.66845703125,
22.88926315307617,
},
["show_sort_button_2"] = true,
["currencies_tracked_imported"] = {
},
["bag_icon_size"] = 36,
["currency_panel_position"] = {
"RIGHT",
"Baganator_CategoryViewBackpackViewFramedark",
"LEFT",
0,
0,
},
["lock_frames"] = false,
["guild_current_tab"] = 1,
["icon_mark_unusable"] = false,
["custom_categories"] = {
["10"] = {
["name"] = "Utility",
["search"] = "",
},
["11"] = {
["name"] = "Legacy",
["search"] = "#gear&!tww",
},
["12"] = {
["name"] = "Mats",
["search"] = "#tradeskill || #reagent",
},
["20"] = {
["name"] = "Sparks",
["search"] = "spark",
},
["17"] = {
["name"] = "Keys",
["search"] = "#key",
},
["16"] = {
["name"] = "Toys",
["search"] = "#toy",
},
["15"] = {
["name"] = "Gems",
["search"] = "#gem",
},
["25"] = {
["name"] = "BoE",
["search"] = "boe",
},
["8"] = {
["name"] = "Trinkets",
["search"] = "#trinket",
},
["14"] = {
["name"] = "Junk",
["search"] = "#junk",
},
["4"] = {
["name"] = "Boxes",
["search"] = "open",
},
["1"] = {
["name"] = "TWW",
["search"] = "#tww",
},
["19"] = {
["name"] = "Pots",
["search"] = "#potion",
},
["3"] = {
["name"] = "Recipes",
["search"] = "#recipe",
},
["2"] = {
["name"] = "Misc",
["search"] = "#tabard || #shirt",
},
["5"] = {
["name"] = "Consumables",
["search"] = "#consumable",
},
["18"] = {
["name"] = "Pets",
["search"] = "#battle pet || pet",
},
["7"] = {
["name"] = "Gear",
["search"] = "#armor",
},
["6"] = {
["name"] = "Enchants",
["search"] = "#item enhancement",
},
["9"] = {
["name"] = "Quest",
["search"] = "#quest",
},
["24"] = {
["name"] = "BoA",
["search"] = "boa",
},
["27"] = {
["name"] = "Midnight",
["search"] = "#midnight",
},
["26"] = {
["name"] = "Ring",
["search"] = "#finger",
},
["13"] = {
["name"] = "Food",
["search"] = "#food",
},
["21"] = {
["name"] = "Trade",
["search"] = "tradable loot || tradeable loot",
},
["22"] = {
["name"] = "Prof",
["search"] = "#profession",
},
["23"] = {
["name"] = "Weapons",
["search"] = "#weapon",
},
},
["sort_start_at_bottom"] = false,
}

}

-- 3. NORTHERN SKY RAID TOOLS
-- Data from NSRT
imports["NorthernSkyRaidTools"] = {
    data = {
["CooldownList"] = {
[252] = {
["spell"] = {
[42650] = {
["offset"] = 0,
["name"] = "Army of the Dead",
},
},
},
},
["ReadyCheckSettings"] = {
["TierCheck"] = true,
["RepairCheck"] = true,
["SoulstoneCheck"] = true,
["EnchantCheck"] = true,
["RaidBuffCheck"] = true,
["CraftedCheck"] = true,
["GatewayShardCheck"] = true,
["MissingItemCheck"] = true,
["GemCheck"] = true,
["ItemLevelCheck"] = true,
},
["EncounterAlerts"] = {
[3181] = {
["enabled"] = true,
},
[3182] = {
["enabled"] = true,
},
[3183] = {
["enabled"] = true,
},
[3176] = {
["enabled"] = true,
},
[3177] = {
["enabled"] = true,
},
[3178] = {
["enabled"] = true,
},
[3306] = {
["enabled"] = true,
},
[3134] = {
["enabled"] = true,
},
[3180] = {
["enabled"] = true,
},
[3135] = {
["enabled"] = true,
},
[3179] = {
["enabled"] = true,
},
},
["ReminderSettings"] = {
["IconSettings"] = {
["yTimer"] = 0,
["relativeTo"] = "CENTER",
["FontSize"] = 24,
["xTimer"] = 0,
["xOffset"] = 205,
["yOffset"] = 153,
["xTextOffset"] = 0,
["Width"] = 50,
["yTextOffset"] = 0,
["Font"] = "Gravity",
["colors"] = {
1,
1,
1,
1,
},
["GrowDirection"] = "Down",
["Height"] = 50,
["Anchor"] = "CENTER",
["TimerFontSize"] = 30,
["Glow"] = 0,
},
["ShowExtraReminderFrame"] = false,
["SpellTTSTimer"] = 5,
["TextTTS"] = false,
["TextCountdown"] = 0,
["UnitIconSettings"] = {
["Position"] = "CENTER",
["xOffset"] = 0,
["yOffset"] = 0,
["Height"] = 25,
["Width"] = 25,
},
["Sticky"] = 5,
["ExtraReminderFrame"] = {
["enabled"] = false,
["relativeTo"] = "TOPLEFT",
["xOffset"] = 5,
["Moveable"] = false,
["Width"] = 500,
["Font"] = "Gravity",
["BGcolor"] = {
0,
0,
0,
0.3,
},
["Height"] = 600,
["FontSize"] = 14,
["yOffset"] = -54,
["Anchor"] = "TOPLEFT",
},
["ExtraReminderFrameMoveable"] = false,
["OnlySpellReminders"] = true,
["TextSettings"] = {
["FontSize"] = 40,
["xOffset"] = 0,
["yOffset"] = 213,
["Font"] = "Gravity",
["colors"] = {
1,
1,
1,
1,
},
["GrowDirection"] = "Up",
["Anchor"] = "CENTER",
["relativeTo"] = "CENTER",
["Height"] = 40,
["Width"] = 302.933349609375,
},
["BarSettings"] = {
["yTimer"] = 0,
["FontSize"] = 20,
["xTimer"] = -2,
["xOffset"] = -278,
["yOffset"] = 16,
["GrowDirection"] = "Up",
["Anchor"] = "CENTER",
["TimerFontSize"] = 20,
["Texture"] = "Atrocity",
["relativeTo"] = "CENTER",
["yIcon"] = 0,
["Width"] = 220,
["yTextOffset"] = 0,
["xTextOffset"] = 2,
["xIcon"] = 0,
["Height"] = 22,
["colors"] = {
1,
0,
0,
1,
},
["Font"] = "Gravity",
},
["SpellDuration"] = 10,
["TextTTSTimer"] = 5,
["SpellName"] = true,
["enabled"] = true,
["MRTNote"] = false,
["ReminderFrameMoveable"] = false,
["GlowSettings"] = {
["Thickness"] = 4,
["Lines"] = 10,
["colors"] = {
0,
1,
0,
1,
},
["xOffset"] = 0,
["Length"] = 10,
["Frequency"] = 0.2,
["yOffset"] = 0,
},
["ShowReminderFrame"] = true,
["ReminderFrame"] = {
["enabled"] = true,
["relativeTo"] = "TOPLEFT",
["xOffset"] = 0,
["Moveable"] = false,
["Width"] = 410,
["Font"] = "Gravity",
["BGcolor"] = {
0,
0,
0,
0.3,
},
["Height"] = 223,
["Anchor"] = "TOPLEFT",
["yOffset"] = -67,
["FontSize"] = 14,
},
["SpellTTS"] = false,
["TextDuration"] = 10,
["AutoShare"] = true,
["HideTimerText"] = false,
["SpellCountdown"] = 0,
["ShowPersonalReminderFrame"] = false,
["PersNote"] = true,
["Bars"] = false,
["PersonalReminderFrameMoveable"] = false,
["PersonalReminderFrame"] = {
["enabled"] = false,
["relativeTo"] = "LEFT",
["xOffset"] = 0,
["Moveable"] = false,
["Width"] = 410,
["Font"] = "Gravity",
["BGcolor"] = {
0,
0,
0,
0.3,
},
["Height"] = 183,
["Anchor"] = "LEFT",
["yOffset"] = 207,
["FontSize"] = 14,
},
},
["UseDefaultPASounds"] = true,
["NSUI"] = {
["scale"] = 1,
["externals_anchor"] = {
["settings"] = {
["anchorPoint"] = {
"CENTER",
"UIParent",
"CENTER",
0,
150,
},
["height"] = 70,
["width"] = 70,
},
},
["AutoComplete"] = {
["WA"] = {
"Northern Sky",
"Northern Sky Manaforge Omega",
["Optimized"] = {
["n"] = {
"northern sky",
},
},
},
["Addon"] = {
"Nortern Sky",
"Nortern Sky Raid Tools",
"Northern Sky Raid Tools",
"Northern Sky",
["Optimized"] = {
},
},
},
["timeline_window"] = {
["scale"] = 1,
["NSUITimelineWindow"] = {
["scale"] = 1,
},
},
},
["Settings"] = {
["SuF"] = false,
["CooldownThreshold"] = 15,
["Blizzard"] = false,
["Minimap"] = {
["minimapPos"] = 223.4974003637528,
["showInCompartment"] = true,
["hide"] = false,
},
["PASelfPing"] = false,
["TTSVoice"] = 1,
["NickNamesSyncAccept"] = 2,
["UpdateWhitelist"] = {
},
["UnreadyOnCooldown"] = true,
["TTS"] = true,
["Unhalted"] = false,
["GlobalFont"] = "Gravity",
["WA"] = false,
["Translit"] = false,
["GlobalNickNames"] = false,
["VersionCheckRemoveResponse"] = false,
["RebuffCheck"] = false,
["AutoUpdateWA"] = false,
["VersionCheckPresets"] = {
{
"WA: Northern Sky Manaforge Omega",
{
"WA",
"Northern Sky Manaforge Omega",
},
},
},
["ShareNickNames"] = 4,
["OmniCD"] = false,
["WeakAurasImportAccept"] = 1,
["MRT"] = false,
["CheckCooldowns"] = true,
["AcceptNickNames"] = 4,
["Debug"] = false,
["TTSVolume"] = 50,
["MRTNoteComparison"] = false,
["NickNamesSyncSend"] = 3,
["LIQUID_MACRO"] = false,
["Cell"] = false,
["ElvUI"] = false,
["Grid2"] = false,
["ExternalSelfPing"] = false,
["DebugLogs"] = false,
["GenericDisplay"] = {
["Anchor"] = "CENTER",
["relativeTo"] = "CENTER",
["xOffset"] = -200,
["yOffset"] = 400,
},
["PAExtraAction"] = false,
["AutoUpdateRaidWA"] = false,
["MissingRaidBuffs"] = false,
},
["PATextSettings"] = {
["enabled"] = true,
["relativeTo"] = "TOP",
["Scale"] = 1.5,
["Anchor"] = "TOP",
["xOffset"] = 0,
["yOffset"] = -200,
},
["StoredSharedReminder"] = false,
["PASounds"] = {
[1223958] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1215897] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1249478] = {
["sound"] = "|cFF4BAAC8Charge|r",
["edited"] = false,
},
[1262772] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1225792] = {
["sound"] = "|cFF4BAAC8Debuff|r",
["edited"] = false,
},
[1241292] = {
["sound"] = "|cFF4BAAC8Light|r",
["edited"] = false,
},
[1249609] = {
["sound"] = "|cFF4BAAC8Rune|r",
["edited"] = false,
},
[1265426] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1253709] = {
["sound"] = "|cFF4BAAC8Linked|r",
["edited"] = false,
},
[1248985] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1283069] = {
["sound"] = "|cFF4BAAC8Fixate|r",
["edited"] = false,
},
[1260643] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1260203] = {
["sound"] = "|cFF4BAAC8Soak|r",
["edited"] = false,
},
[1253531] = {
["sound"] = "|cFF4BAAC8Beam|r",
["edited"] = false,
},
[1281184] = {
["sound"] = "|cFF4BAAC8Spread|r",
["edited"] = false,
},
[1253024] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1280023] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[474129] = {
["sound"] = "|cFF4BAAC8Spread|r",
["edited"] = false,
},
[1284527] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1248994] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1255612] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1241339] = {
["sound"] = "|cFF4BAAC8Void|r",
["edited"] = false,
},
[1232470] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
["UseDefaultMPlusPASounds"] = true,
[1261286] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1239111] = {
["sound"] = "|cFF4BAAC8Break|r",
["edited"] = false,
},
[1251775] = {
["sound"] = "|cFF4BAAC8Fixate|r",
["edited"] = false,
},
["UseDefaultPASounds"] = true,
[472793] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1264756] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1246487] = {
["sound"] = "|cFF4BAAC8Spread|r",
["edited"] = false,
},
[153954] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1260027] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1254113] = {
["sound"] = "|cFF4BAAC8Fixate|r",
["edited"] = false,
},
[1268992] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1248697] = {
["sound"] = "|cFF4BAAC8Debuff|r",
["edited"] = false,
},
[1249265] = {
["sound"] = "|cFF4BAAC8Soak|r",
["edited"] = false,
},
[1270497] = {
["sound"] = "|cFF4BAAC8Spread|r",
["edited"] = false,
},
[466559] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1252733] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1282911] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1264453] = {
["sound"] = "|cFF4BAAC8Fixate|r",
["edited"] = false,
},
[1241992] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1233887] = {
["sound"] = "|cFF4BAAC8Debuff|r",
["edited"] = false,
},
[1242091] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1251785] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1257087] = {
["sound"] = "|cFF4BAAC8Clear|r",
["edited"] = false,
},
[1253511] = {
["sound"] = "|cFF4BAAC8Fixate|r",
["edited"] = false,
},
[1259861] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1237623] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1283236] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
[1283247] = {
["sound"] = "|cFF4BAAC8Targeted|r",
["edited"] = false,
},
},
["QoL"] = {
["TradeableItems"] = {
["relativeTo"] = "TOP",
["xOffset"] = 0,
["yOffset"] = -400,
["Anchor"] = "TOP",
["Spacing"] = 5,
["Height"] = 30,
["Width"] = 30,
["FontSize"] = 18,
["GrowDirection"] = "DOWN",
},
["IconDisplay"] = {
["Width"] = 40,
["relativeTo"] = "TOP",
["Scpaing"] = 5,
["GrowDirection"] = "DOWN",
["Height"] = 40,
["Anchor"] = "TOP",
["xOffset"] = 0,
["yOffset"] = -350,
},
["AutoInvite"] = true,
["TextDisplay"] = {
["relativeTo"] = "CENTER",
["Anchor"] = "CENTER",
["FontSize"] = 30,
["xOffset"] = 0,
["yOffset"] = 0,
},
},
["PARaidSettings"] = {
["enabled"] = false,
["relativeTo"] = "BOTTOMLEFT",
["xOffset"] = 0,
["GrowDirection"] = "RIGHT",
["RowGrowDirection"] = "UP",
["Width"] = 25,
["DebuffTypeBorder"] = false,
["Height"] = 25,
["Limit"] = 5,
["Spacing"] = -1,
["Anchor"] = "BOTTOMLEFT",
["yOffset"] = 0,
["StackScale"] = 1.100000023841858,
["PerRow"] = 3,
},
["NickNames"] = {
["Lukîî-Blackhand"] = "Luki",
},
["InviteList"] = {
},
["Reminders"] = {
},
["GravityUIProfile"] = "GravityUI",
["PersonalReminders"] = {
},
["HasLoggedIntoMidnight"] = true,
["PASettings"] = {
["enabled"] = true,
["relativeTo"] = "CENTER",
["xOffset"] = -187,
["RowGrowDirection"] = "UP",
["Width"] = 40,
["UpscaleDuration"] = true,
["GrowDirection"] = "LEFT",
["Limit"] = 5,
["Spacing"] = -1,
["Height"] = 40,
["Anchor"] = "CENTER",
["yOffset"] = -50,
["PerRow"] = 10,
},
["PATankSettings"] = {
["enabled"] = false,
["relativeTo"] = "CENTER",
["xOffset"] = -187,
["MultiTankGrowDirection"] = "UP",
["Width"] = 40,
["Limit"] = 5,
["Spacing"] = -1,
["Height"] = 40,
["GrowDirection"] = "LEFT",
["Anchor"] = "CENTER",
["yOffset"] = -101,
},
["AssignmentSettings"] = {
[3178] = {
["Soaks"] = true,
},
["OnPull"] = true,
[3306] = {
["Soaks"] = true,
["SplitSoaks"] = true,
},
[3180] = {
["Soaks"] = true,
},
},
}

}

-- 4. WARPDEPLETE
-- Data from WarpDepleteDB.profiles["GravityUI"]
imports["WarpDeplete"] = {
    data = {
["keyFontSize"] = 16,
["bar2Font"] = "Gravity",
["timerSuccessColor"] = "ff00ff28",
["barPadding"] = 4,
["verticalOffset"] = 4,
["frameX"] = 13.38862800598145,
["completedObjectivesColor"] = "ff00ff25",
["keyDetailsFontSize"] = 12,
["keyColor"] = "ff0095ff",
["bar3Font"] = "Gravity",
["bar1Texture"] = "Gravity Normal",
["bar3TextureColor"] = "ffe6e6e6",
["objectivesFont"] = "Gravity",
["keyDetailsColor"] = "ffe6e6e6",
["keyFont"] = "Gravity",
["bar2Texture"] = "Gravity Normal",
["keyDetailsFont"] = "Gravity",
["forcesFont"] = "Gravity",
["deathsFont"] = "Gravity",
["bar3Texture"] = "Gravity Normal",
["frameScale"] = 0.9,
["forcesOverlayTexture"] = "Gravity Normal",
["timingsImprovedTimeColor"] = "ff00ff25",
["showPrideGlow"] = false,
["completedForcesColor"] = "ff00ff25",
["objectivesFontSize"] = 16,
["bar1Font"] = "Gravity",
["bar2TextureColor"] = "ffe6e6e6",
["timerFontSize"] = 28,
["bar1TextureColor"] = "ffe6e6e6",
["forcesTextureColor"] = "ff0096ff",
["forcesTexture"] = "Gravity Normal",
["frameY"] = 187.8846740722656,
["forcesOverlayTextureColor"] = "ff00ff28",
["timerFont"] = "Gravity",
["keyFont"] = "Gravity",
}

}

