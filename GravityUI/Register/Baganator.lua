local addon, private = ...


-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
}
]]
local addonName = "Baganator"
local importText = "Import"
local data = {
    ["guild_view_width"] = 16,
    ["empty_slot_background"] = true,
    ["junk_plugin"] = "poor_quality",
    ["reduce_spacing"] = true,
    ["bag_view_type"] = "category",
    ["automatic_categories_added"] = {
        ["default_miscellaneous"] = true,
        ["default_armor"] = true,
        ["default_junk"] = true,
        ["default_toy"] = true,
        ["default_hearthstone"] = true,
        ["default_other"] = true,
        ["default_battlepet"] = true,
        ["default_food"] = true,
        ["default_key"] = true,
        ["default_weapon"] = true,
        ["default_questitem"] = true,
        ["default_consumable"] = true,
        ["default_tradegoods"] = true,
        ["default_gem"] = true,
        ["default_potion"] = true,
        ["default_profession"] = true,
        ["default_auto_equipment_sets"] = true,
        ["default_container"] = true,
        ["default_reagent"] = true,
        ["default_recipe"] = true,
        ["default_itemenhancement"] = true,
    },
    ["show_search_box"] = true,
    ["debug_categories_search"] = false,
    ["bank_view_show_bag_slots"] = false,
    ["bank_view_width"] = 26,
    ["sort_method"] = "item-level",
    ["reverse_groups_sort_order"] = false,
    ["auto_open"] = {
        ["auction_house"] = true,
        ["item_upgrade"] = true,
        ["void_storage"] = false,
        ["guild_bank"] = true,
        ["forge_of_bonds"] = false,
        ["merchant"] = true,
        ["tradeskill"] = false,
        ["character_panel"] = false,
        ["scrapping_machine"] = true,
        ["item_interaction"] = true,
        ["mail"] = true,
        ["sockets"] = true,
        ["trade_partner"] = true,
        ["bank"] = true,
    },
    ["icon_corners_auto_insert_applied"] = {
        ["battle_pet_level"] = true,
        ["bag_type"] = true,
        ["keystone_level"] = true,
    },
    ["show_recents_tabs_main_view"] = false,
    ["migrated_sort_method"] = true,
    ["category_hidden"] = {
        ["1"] = false,
        ["26"] = false,
        ["20"] = false,
        ["18"] = false,
        ["11"] = false,
    },
    ["junk_plugin_ignored"] = {
    },
    ["icon_flash_similar_alt"] = false,
    ["category_edit_search_mode"] = "visual",
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
        "6",
        "15",
        "__end",
        "_3",
        "12",
        "20",
        "22",
        "3",
        "__end",
        "_4",
        "17",
        "4",
        "18",
        "16",
        "9",
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
    ["current_skin"] = "blizzard",
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
        27.33331298828125,
        169.22216796875,
    },
    ["sort_start_at_bottom"] = false,
    ["guild_view_position_2"] = {
        "TOPLEFT",
        49.99991226196289,
        -112.9259626600494,
    },
    ["custom_categories"] = {
        ["23"] = {
            ["name"] = "Weapons",
            ["search"] = "#weapon",
        },
        ["22"] = {
            ["name"] = "Prof",
            ["search"] = "#profession",
        },
        ["21"] = {
            ["name"] = "Trade",
            ["search"] = "tradable loot || tradeable loot",
        },
        ["13"] = {
            ["name"] = "Food",
            ["search"] = "#food",
        },
        ["26"] = {
            ["name"] = "Ring",
            ["search"] = "#finger",
        },
        ["15"] = {
            ["name"] = "Gems",
            ["search"] = "#gem",
        },
        ["24"] = {
            ["name"] = "BoA",
            ["search"] = "boa",
        },
        ["9"] = {
            ["name"] = "Quest",
            ["search"] = "#quest",
        },
        ["14"] = {
            ["name"] = "Junk",
            ["search"] = "#junk",
        },
        ["19"] = {
            ["name"] = "Pots",
            ["search"] = "#potion",
        },
        ["1"] = {
            ["name"] = "TWW",
            ["search"] = "#tww",
        },
        ["18"] = {
            ["name"] = "Pets",
            ["search"] = "#battle pet || pet",
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
        ["4"] = {
            ["name"] = "Boxes",
            ["search"] = "open",
        },
        ["7"] = {
            ["name"] = "Gear",
            ["search"] = "#armor",
        },
        ["6"] = {
            ["name"] = "Enchants",
            ["search"] = "#item enhancement",
        },
        ["25"] = {
            ["name"] = "BoE",
            ["search"] = "boe",
        },
        ["8"] = {
            ["name"] = "Trinkets",
            ["search"] = "#trinket",
        },
        ["16"] = {
            ["name"] = "Toys",
            ["search"] = "#toy",
        },
        ["17"] = {
            ["name"] = "Keys",
            ["search"] = "#key",
        },
        ["20"] = {
            ["name"] = "Sparks",
            ["search"] = "spark",
        },
        ["12"] = {
            ["name"] = "Mats",
            ["search"] = "#tradeskill || #reagent",
        },
        ["11"] = {
            ["name"] = "Legacy",
            ["search"] = "#gear&!tww",
        },
        ["10"] = {
            ["name"] = "Utility",
            ["search"] = "",
        },
    },
    ["debug_timers"] = false,
    ["seen_welcome"] = 1,
    ["hide_special_container"] = {
    },
    ["icon_mark_unusable"] = false,
    ["character_select_position"] = {
        "RIGHT",
        "Baganator_CategoryViewBackpackViewFrameblizzard",
        "LEFT",
        0,
        0,
    },
    ["guild_current_tab"] = 6,
    ["category_horizontal_spacing_2"] = 0.3,
    ["lock_frames"] = false,
    ["category_default_import"] = 2,
    ["bag_view_position"] = {
        "BOTTOMRIGHT",
        -7.4453125,
        5.000270843505859,
    },
    ["recent_timeout"] = 15,
    ["bag_icon_size"] = 36,
    ["currencies_tracked_imported"] = {
    },
    ["debug_categories"] = false,
    ["category_horizontal_spacing"] = 0.15,
    ["category_modifications"] = {
        ["default_miscellaneous"] = {
            ["addedItems"] = {
                ["i:244465"] = true,
                ["i:233186"] = true,
            },
        },
        ["10"] = {
            ["priority"] = 3,
            ["addedItems"] = {
                ["i:132516"] = true,
                ["i:112384"] = true,
                ["i:188152"] = true,
                ["i:65360"] = true,
                ["i:168222"] = true,
                ["i:109076"] = true,
                ["i:64402"] = true,
                ["i:65274"] = true,
                ["i:109253"] = true,
                ["i:64400"] = true,
                ["i:221903"] = true,
                ["i:111820"] = true,
                ["i:221949"] = true,
                ["i:49040"] = true,
                ["i:203722"] = true,
                ["i:64401"] = true,
            },
        },
        ["11"] = {
            ["showGroupPrefix"] = true,
            ["priority"] = 3,
        },
        ["12"] = {
            ["addedItems"] = {
                ["i:222738"] = true,
            },
            ["priority"] = -1,
        },
        ["13"] = {
            ["addedItems"] = {
                ["i:222778"] = true,
                ["i:222781"] = true,
            },
            ["priority"] = -1,
        },
        ["26"] = {
            ["showGroupPrefix"] = true,
            ["priority"] = 0,
            ["addedItems"] = {
                ["i:133287"] = true,
                ["i:178736"] = true,
            },
        },
        ["default_hearthstone"] = {
            ["addedItems"] = {
                ["i:110560"] = true,
                ["i:6948"] = true,
            },
        },
        ["default_other"] = {
            ["addedItems"] = {
                ["i:232049"] = true,
                ["i:220756"] = true,
            },
        },
        ["8"] = {
            ["priority"] = 0,
        },
        ["15"] = {
            ["priority"] = -1,
        },
        ["9"] = {
            ["priority"] = -1,
        },
        ["25"] = {
            ["priority"] = 0,
        },
        ["5"] = {
            ["addedItems"] = {
                ["i:132514"] = true,
            },
            ["priority"] = -1,
        },
        ["1"] = {
            ["addedItems"] = {
                ["i:225557"] = true,
                ["i:225767"] = true,
                ["i:235897"] = true,
            },
            ["priority"] = -1,
        },
        ["4"] = {
            ["priority"] = 3,
        },
        ["3"] = {
            ["priority"] = -1,
        },
        ["2"] = {
            ["priority"] = 3,
        },
        ["19"] = {
            ["priority"] = -1,
        },
        ["18"] = {
            ["addedItems"] = {
                ["i:86143"] = true,
                ["i:98114"] = true,
                ["i:127755"] = true,
                ["i:116418"] = true,
                ["i:116374"] = true,
                ["i:92683"] = true,
                ["i:116424"] = true,
                ["i:98715"] = true,
                ["i:116421"] = true,
                ["i:116420"] = true,
                ["i:89906"] = true,
                ["i:122457"] = true,
                ["i:116429"] = true,
                ["i:71153"] = true,
                ["i:163036"] = true,
                ["i:92682"] = true,
            },
            ["priority"] = -1,
        },
        ["7"] = {
            ["priority"] = -1,
            ["addedItems"] = {
                ["i:159972"] = true,
                ["i:133299"] = true,
                ["i:133298"] = true,
                ["i:133306"] = true,
                ["i:133286"] = true,
                ["i:133363"] = true,
                ["i:159427"] = true,
                ["i:178701"] = true,
                ["i:159429"] = true,
            },
        },
        ["6"] = {
            ["addedItems"] = {
                ["i:226505"] = true,
                ["i:213777"] = true,
            },
            ["priority"] = -1,
        },
        ["14"] = {
            ["priority"] = 3,
        },
        ["24"] = {
            ["priority"] = 3,
        },
        ["16"] = {
            ["addedItems"] = {
                ["i:163604"] = true,
                ["i:45047"] = true,
            },
            ["priority"] = -1,
        },
        ["17"] = {
            ["priority"] = -1,
            ["addedItems"] = {
                ["i:180653"] = true,
            },
        },
        ["20"] = {
            ["showGroupPrefix"] = true,
            ["priority"] = 0,
            ["addedItems"] = {
                ["i:211297"] = true,
                ["i:211296"] = true,
            },
        },
        ["21"] = {
            ["priority"] = 3,
        },
        ["22"] = {
            ["addedItems"] = {
                ["i:222551"] = true,
                ["i:222548"] = true,
            },
            ["priority"] = -1,
        },
        ["23"] = {
            ["addedItems"] = {
                ["i:133301"] = true,
                ["i:178780"] = true,
            },
            ["priority"] = -1,
        },
    },
    ["saved_searches"] = {
    },
    ["guild_view_position"] = {
        "LEFT",
        583.5559692382812,
        150.0554809570313,
    },
    ["guild_bank_sort_method"] = "unset",
    ["warband_bank_view_width"] = 16,
    ["category_section_toggled"] = {
        ["1"] = false,
        ["Main"] = false,
        ["Crafting"] = false,
        ["Equipment"] = false,
        ["General"] = false,
    },
    ["add_to_category_buttons_2"] = "drag+alt",
    ["view_type"] = "unset",
    ["bank_current_tab"] = 2,
    ["icon_text_quality_colors"] = true,
    ["bag_empty_space_at_top"] = false,
    ["icon_text_font_size"] = 14,
    ["upgrade_plugin"] = "none",
    ["sort_ignore_slots_count_2"] = {
        ["Cronîx-Blackhand"] = 0,
    },
    ["view_alpha"] = 1,
    ["bag_view_width"] = 16,
    ["setting_anchors"] = false,
    ["skins"] = {
        ["blizzard"] = {
            ["view_transparency"] = 0,
            ["no_frame_borders"] = false,
            ["empty_slot_background"] = false,
        },
        ["elvui"] = {
            ["use_bag_font"] = false,
        },
        ["dark"] = {
            ["view_transparency"] = 0.3,
            ["square_icons"] = false,
            ["no_frame_borders"] = false,
            ["empty_slot_background"] = false,
        },
    },
    ["recent_characters_main_view"] = {
        "Cronîx-Blackhand",
        "Cronìx-Blackhand",
        "Crônix-Blackhand",
        "Evonix-Blackhand",
        "Givemeloot-Eredar",
        "Givemeloot-Blackhand",
        "Bláckstar-Kel'Thuzad",
        "Cròníx-Onyxia",
        "Cròníx-Blackhand",
        "Cronolie-Blackhand",
    },
    ["debug_keywords"] = false,
    ["sort_ignore_bank_slots_count"] = {
        ["Cronîx-Blackhand"] = 0,
    },
    ["auto_sort_on_open"] = false,
    ["category_group_empty_slots"] = true,
    ["show_buttons_on_alt"] = false,
    ["disabled_skins"] = {
    },
    ["sort_ignore_slots_at_end"] = false,
    ["guild_view_dialog_position"] = {
        "TOP",
        "UIParent",
        "TOP",
        -206.8886413574219,
        -154.9445037841797,
    },
    ["currencies_tracked"] = {
        ["Cronìx-Blackhand"] = {
        },
        ["Givemeloot-Blackhand"] = {
        },
        ["Givemeloot-Eredar"] = {
        },
        ["Cròníx-Onyxia"] = {
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
    ["bank_only_view_position"] = {
        "LEFT",
        549.7777099609375,
        20.44439697265625,
    },
    ["category_migration"] = 5,
    ["show_sort_button_2"] = true,
    ["bag_view_show_bag_slots"] = false,
    ["upgrade_plugin_ignored"] = {
    },
    ["currency_panel_position"] = {
        "RIGHT",
        "Baganator_CategoryViewBackpackViewFrameblizzard",
        "LEFT",
        0,
        0,
    },
    ["icon_equipment_set_border"] = true,
    ["icon_context_fading"] = true,
    ["category_sort_method"] = "item-level",
    ["currency_headers_collapsed"] = {
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
}

local function install() 

    local name = UnitName("PLAYER")
    local realm = GetRealmName()
    if BAGANATOR_CURRENT_PROFILE and BAGANATOR_CONFIG then
        BAGANATOR_CONFIG["sort_ignore_bank_slots_count"][name .. "-" .. realm] = 0
        BAGANATOR_CONFIG["sort_ignore_slots_count_2"][name .. "-" .. realm] = 0
        BAGANATOR_CONFIG["Profiles"][private.g.name]  = data
        --Needs to be set 
        BAGANATOR_CURRENT_PROFILE = private.g.name
    end
   
end



table.insert(private.Addons, {
    name = addonName,
    import = install,
    importText = importText
})