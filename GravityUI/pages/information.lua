-- GravityUI - Information Page
local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = GUI.Colors

local function CreateFeatureRow(container, name, desc, stateTable, stateKey, yOffset, pageId, tabIndex)
    local PAD = 10
    local row = CreateFrame("Button", nil, container, "BackdropTemplate")
    row:SetSize(GUI.CONTENT_WIDTH - 45, 55)
    row:SetPoint("TOPLEFT", PAD, yOffset)

    -- Clickable styling
    GUI:CreateBackdrop(row, {0.15, 0.15, 0.15, 0.3}, C.border)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.1)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 0.3)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    end)
    
    if pageId then
        row:SetScript("OnClick", function()
            GUI:ShowPage(pageId, tabIndex)
        end)
    end

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(title, 13, "", C.accent)
    title:SetPoint("TOPLEFT", 10, -5)
    title:SetText(name)

    local statusBtn = CreateFrame("Button", nil, row)
    statusBtn:SetSize(50, 55)
    statusBtn:SetPoint("RIGHT", row, "RIGHT", -15, 0)
    
    local status = statusBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(status, 13, "OUTLINE")
    status:SetPoint("RIGHT", statusBtn, "RIGHT", 0, 0) 
    
    local isEnabled = stateTable and stateTable[stateKey]
    
    local function UpdateStatus()
        isEnabled = stateTable and stateTable[stateKey]
        if isEnabled == true then
            status:SetText("|cFF00FF00ON|r")
            statusBtn:Show()
        elseif isEnabled == false then
            status:SetText("|cFFFF0000OFF|r")
            statusBtn:Show()
        else
            status:SetText("")
            statusBtn:Hide()
        end
    end
    UpdateStatus()

    statusBtn:SetScript("OnClick", function()
        if stateTable and stateKey then
            stateTable[stateKey] = not stateTable[stateKey]
            UpdateStatus()
            print("|cff00BFFFGravityUI:|r '" .. name .. "' modified. Please |cff00FF00/reload|r to apply.")
        end
    end)
    
    statusBtn:SetScript("OnEnter", function(self)
        if stateTable and stateKey then
            status:SetText(isEnabled and "|cFF00CC00ON|r" or "|cFFCC0000OFF|r")
            row:GetScript("OnEnter")(row)
        end
    end)
    statusBtn:SetScript("OnLeave", function(self)
        UpdateStatus()
        row:GetScript("OnLeave")(row)
    end)

    local descLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(descLabel, 11, "")
    descLabel:SetPoint("BOTTOMLEFT", 10, 5)
    descLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    descLabel:SetPoint("RIGHT", statusBtn, "LEFT", -10, 0)
    descLabel:SetJustifyH("LEFT")
    descLabel:SetJustifyV("TOP")
    descLabel:SetSpacing(2)
    descLabel:SetTextColor(unpack(C.textMuted))
    descLabel:SetText(desc)

    return row
end

local function BuildInformationTab(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local y = -10
    local PAD = 10
    local db = ns.GetDB()
    if not db then return end

    -- 1. CHANGELOG SECTION
    local changelogHeader = GUI:CreateSectionHeader(content, "Recent Changelogs")
    changelogHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - changelogHeader.gap
    y = y - 10

    local changeLogs = {
        { version = "3.94.68", date = "13.04.2026", changes = {
            "Integrated Midnight expansion consumables (Food, Flasks, Augment Runes) into RaidBuffs module with persistent detection",
            "Implemented smart talent filtering for class-specific reminders (Shaman Shields, Paladin Rites, Druid Symbiotic Relationship)",
            "Fixed UI overlapping bug in 'Missing Buffs' settings page during custom buff manipulation",
            "Added '/glog' and '/gravitylog' commands with 'toggle' support for manual combat log control",
            "Enhanced Combat Log automation with clearer chat feedback for M+ and Raid transitions",
            "Optimized 'Elemental Orbit' shield logic to prevent false-positives for multi-shield classes",
        } },
        { version = "3.94.67", date = "31.03.2026", changes = {
            "Removed M+ CD Tracking module (CDTracker) entirely — WoW Midnight taint system prevents reliable cooldown tracking in instances",
            "Deleted cdtracker.lua, cleaned up GravityUI.toc, defaults.lua, and all CDTracker references in init.lua",
            "Removed M+ CD Tracking subtab from UI Indicators settings page",
            "Removed M+ CD Tracking entry from Information Feature Hub and corrected all subsequent tabIndex references",
        } },
        { version = "3.94.66", date = "31.03.2026", changes = {
            "Fixed critical deployment path bug — all addon files now correctly sync to Interface\\AddOns\\GravityUI\\core\\ (was incorrectly targeting nested GravityUI\\GravityUI\\core\\)",
            "Resolved persistent 'secret string' taint crash in M+ Teleport chat handler (mplusteleport.lua) causing 20+ repeated errors per session in party",
        } },
    }

    -- Calculation for dynamic text width based on content frame
    local textWidth = parent:GetWidth() - (PAD * 3)
    if textWidth < 400 then textWidth = 600 end -- Fallback for initial load
    
    for i = 1, math.min(#changeLogs, 4) do
        local log = changeLogs[i]
        local vLabel = GUI:CreateLabel(content, "|cFF30D1FFv" .. log.version .. "|r - " .. log.date, 13, C.accent)
        vLabel:SetPoint("TOPLEFT", PAD, y)
        vLabel:SetWidth(textWidth)
        vLabel:SetJustifyH("LEFT")
        y = y - 20
        
        for _, change in ipairs(log.changes) do
            local bullet = GUI:CreateLabel(content, " • " .. change, 11, C.text)
            bullet:SetPoint("TOPLEFT", PAD + 10, y)
            bullet:SetWidth(textWidth - 10)
            bullet:SetJustifyH("LEFT")
            bullet:SetSpacing(2)
            
            -- Dynamic height decrement to prevent overlap on wrap
            local h = bullet:GetStringHeight()
            y = y - (h > 0 and h or 16) - 4
        end
        y = y - 10
    end

    y = y - 20

    -- 2. FEATURE HUB
    local hubHeader = GUI:CreateSectionHeader(content, "Feature Hub (Status & Navigation)")
    hubHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - hubHeader.gap
    y = y - 10

    local features = {
        -- Main Category
        { name = "Theme Color", desc = "Base color settings used for styling modules in GravityUI.", pageId = "main", tabIndex = 2 },
        { name = "Global UI Scale", desc = "Centralized settings for interface scaling and quick presets.", pageId = "main", tabIndex = 3 },
        { name = "Global Fonts", desc = "Centralized settings for global font styling.", pageId = "main", tabIndex = 4 },
        { name = "FPS Optimization", desc = "Apply Gravity's optimized graphics settings for competitive play.", pageId = "main", tabIndex = 5 },
        { name = "Edit Mode (GravityUI)", desc = "Enable or disable GravityUI's custom element movers.\nDrag and reposition all registered GravityUI frames independently.", pageId = "main", tabIndex = 6 },

        -- Minimap (minimap.lua)
        { name = "Minimap Overhaul", desc = "Transforms the default minimap into a clean, modern square or round frame.\nFeatures smart anchoring, dynamic zoom, and addon minimization.", stateTable = db.minimap, stateKey = "enabled", pageId = "minimap", tabIndex = 1 },
        { name = "Minimap Elements", desc = "Configures custom zone text, coordinates, clock, and tracking icons.\nEasily position navigational data beautifully around the map edge.", pageId = "minimap", tabIndex = 2 },
        { name = "Icon Catcher", desc = "Collects messy addon minimap icons into a dropdown or a drawer.\nSupports automatic catching and manually added custom frames.", stateTable = db.minimap and db.minimap.catcher, stateKey = "enabled", pageId = "minimap", tabIndex = 3 },
        
        -- Action Bars (actionbars.lua)
        { name = "Action Bars", desc = "Custom skinned, dynamically fading immersive action bars.\nAdjust scaling, padding, backdrop aesthetics, and hotkey fonts.", stateTable = db.actionbars, stateKey = "enabled", pageId = "actionbars", tabIndex = 1 },
        { name = "Mouseover Settings", desc = "Configure specific fade rules based on mouse interactions.\nSet global fade duration, delays, and out-of-combat hiding rules.", stateTable = db.actionbars and db.actionbars.fade, stateKey = "enabled", pageId = "actionbars", tabIndex = 2 },
        { name = "Extra Action Buttons", desc = "Control the Extra Action Button, Zone Ability, and Encounter bars.\nEasily scale and reposition these critical scenario-specific buttons.", pageId = "actionbars", tabIndex = 3 },
        
        -- Datapanels (datapanels.lua)
        { name = "Minimap Datapanel", desc = "Information bar anchored below the minimap showing tracked metrics.\nDisplays dynamically updating durability, gold, latency, or time.", stateTable = db.minimap and db.minimap.datatext, stateKey = "enabled", pageId = "datapanels", tabIndex = 1 },
        { name = "Custom Panels", desc = "Create highly customizable, floating text strings for any tracked data.\nBuild personalized dashboards anywhere on your screen.", pageId = "datapanels", tabIndex = 2 },
        
        -- Quality of Life (qol.lua)
        { name = "Automation / Stuff", desc = "Automates tedious tasks out of sight: auto-repair, fast loot, and sell junk.\nIncludes auto-accepting quests, skips for movies, and dialogue routing.", pageId = "qol", tabIndex = 1 },
        { name = "Autohide Setup", desc = "Configure contextual hiding rules based on game events (e.g. Minigames).\nAutomatically hides specific UI frames to preserve immersion.", pageId = "qol", tabIndex = 2 },

        -- Feature Hub (features.lua)
        { name = "Skyriding Tracking", desc = "A smooth, customizable Vigor trackingHUD with visual animations.\nReplaces the disjointed default UI with a unified, centered layout.", stateTable = db.skyriding, stateKey = "enabled", pageId = "features", tabIndex = 1 },
        { name = "M+ Teleport Icons", desc = "Clickable dungeon portals embedded directly into the Mythic+ LFG UI.\nRapidly port to dungeons without searching through your spellbook.", stateTable = db.uiimprovements, stateKey = "mplusTeleportEnabled", pageId = "features", tabIndex = 2 },
        { name = "World Marks", desc = "A streamlined interface for dropping world markers and flare tools.\nProvides quick access to ready-checks and countdown pull timers.", stateTable = db.uiimprovements and db.uiimprovements.marks, stateKey = "enabled", pageId = "features", tabIndex = 3 },
        { name = "Mail Extras", desc = "Adds an 'Open All' button, an Address Book for alts and friends, and gold loot messages.\nImproves mailbox efficiency natively without extra addons.", stateTable = db.uiimprovements and db.uiimprovements.mail, stateKey = "enabled", pageId = "features", tabIndex = 4 },
        { name = "Group & Guild Tools", desc = "A collection of utility features like the Guild Invite tool and automatic role promotion for assistants.", pageId = "features", tabIndex = 5 },
        { name = "Interrupt Tracker", desc = "Tracks interrupt cooldowns of party members in M+ dungeons.\nUses Say/Party chat as a fallback broadcast when addon comms are unavailable.", stateTable = db.screenindicators and db.screenindicators.interruptTracker, stateKey = "enabled", pageId = "features", tabIndex = 6 },

        -- Screen Indicators (indicators.lua)
        { name = "Cursor Utilities", desc = "Attach GCD Rings, Cursor Castbars, and highlights to your mouse.\nSuperb for tracking mechanics instantly without looking away from the action.", stateTable = db.screenindicators and db.screenindicators.cursor, stateKey = "enabled", pageId = "indicators", tabIndex = 1 },
        { name = "Crosshair", desc = "Provides dynamic class-specific targeting crosshairs emphasizing range.\nColor translates combat and spell-range availability in real-time.", stateTable = db.screenindicators and db.screenindicators.crosshair, stateKey = "enabled", pageId = "indicators", tabIndex = 2 },
        { name = "Pet Info", desc = "Quick pet management tools and large status warnings (Pet Dead).\nCrucial for Hunters and Warlocks who need rapid reminders.", stateTable = db.screenindicators and db.screenindicators.petWarnings, stateKey = "enabled", pageId = "indicators", tabIndex = 3 },
        { name = "Combat Timer", desc = "A visual stopwatch tracking the duration spent in combat or encounters.\nExcellent for visualizing long raid bosses or Mythic+ pack length.", stateTable = db.uiimprovements and db.uiimprovements.combatTimer, stateKey = "enabled", pageId = "indicators", tabIndex = 4 },
        { name = "Cooldown Text", desc = "Displays on-screen text when tracked party spells go on cooldown.\nConfigurable per class with custom_spell IDs, display names, and grow direction.", stateTable = db.cooldownText, stateKey = "enabled", pageId = "indicators", tabIndex = 5 },
        { name = "Missing Buffs (Raid)", desc = "Tracks missing raid buffs dynamically based on group class composition.\nExamines exactly who is present and what buffs are missing pre-pull.", stateTable = db.raidBuffs, stateKey = "enabled", pageId = "indicators", tabIndex = 6 },
        { name = "Raid Warnings", desc = "Displays centralized large text alerts for helpful utility spells.\nWarns for newly dropped Soulwells, Feasts, Mage Tables, and Rituals.", stateTable = db.raidWarnings, stateKey = "enabled", pageId = "indicators", tabIndex = 7 },
        { name = "Consumables Tracker", desc = "Displays missing consumables like food and flasks for yourself and your group members during a Ready Check.", stateTable = db.screenindicators and db.screenindicators.consumables, stateKey = "enabled", pageId = "indicators", tabIndex = 8 },
        { name = "Difficulty Indicator", desc = "Visual status bar tracking the currently selected instance difficulty.\nIncludes a dropdown for rapidly changing difficulties out-of-world.", stateTable = db.screenindicators and db.screenindicators.difficulty, stateKey = "enabled", pageId = "indicators", tabIndex = 9 },
        { name = "AFK Screen", desc = "An immersive, cinematic character orbit view when Away From Keyboard.\nDisplays real time, guild, character rank, and a moving camera.", stateTable = db.screenindicators and db.screenindicators.afkScreen, stateKey = "enabled", pageId = "indicators", tabIndex = 10 },
        
        -- UI Utilities (utilities.lua)
        { name = "Sound Alerts", desc = "Integrates custom SharedMedia sounds directly into Blizzard's CooldownViewer.\nSeamlessly replaces specific Blizzard sounds with your own media files.", stateTable = db.soundAlerts, stateKey = "enabled", pageId = "utilities", tabIndex = 4 },
        { name = "Castbar Ticks", desc = "Adds channeling tick marks (e.g., Evoker Disintegrate) to Unit Frames.\nTracks intervals mathematically to avoid clipping spells prematurely.", stateTable = db.general and db.general.castbarTicks and db.general.castbarTicks.disintegrate, stateKey = "enableUUF", pageId = "utilities", tabIndex = 3 },

        -- Styling Tab (styling.lua)
        { name = "Game Menu", desc = "Generates a fully customized Escape Key menu overriding the Blizzard UI.\nApplies unified structural gradients and dark-mode styling.", stateTable = db.styling and db.styling.gamemenu, stateKey = "enabled", pageId = "Styling", tabIndex = 6 },
        { name = "Chat Bubbles", desc = "Alters the 3D in-world chat bubbles with custom fonts and flat backgrounds.\nHighly readable and integrates with nameplate aesthetics.", stateTable = db.styling and db.styling.chatBubbles, stateKey = "enabled", pageId = "Styling", tabIndex = 11 },
        { name = "Ready Check", desc = "Replaces the Blizzard Ready Check pop-up with a customized dark version.\nSupports unique coloring and thematic structure fonts.", stateTable = db.styling, stateKey = "skinReadyCheck", pageId = "Styling", tabIndex = 7 },
        { name = "Keystone", desc = "Overrides the Mythic+ Keystone insertion pedestal frame.\nReplaces clunky textures with clean lines and legible text.", stateTable = db.styling and db.styling.keystone, stateKey = "enabled", pageId = "Styling", tabIndex = 8 },
        { name = "Power Bar", desc = "Skins the Player's Alternative Power bar (sanity, corruption, etc).\nConverts the bizarre Blizzard artwork into straight, scalable bars.", stateTable = db.styling and db.styling.powerBar, stateKey = "enabled", pageId = "Styling", tabIndex = 9 },
        { name = "Alert Frames", desc = "Skins Blizzard alert toast pop-ups (Achievements, Loot Rolls, Mounts).\nIntercepts specific windows without breaking API compatibility limits.", stateTable = db.styling and db.styling.alerts, stateKey = "enabled", pageId = "Styling", tabIndex = 10 },
        { name = "Loot Enhancement", desc = "Modernized loot frames supporting the 'loot-under-mouse' position metric.\nAesthetically wraps standard loot distributions and boss kills.", stateTable = db.styling and db.styling.loot, stateKey = "enabled", pageId = "Styling", tabIndex = 5 },
        { name = "Objective Tracker", desc = "Overrides Blizzard's quest tracking layout with clean styling profiles.\nUses progressive contextual color text to highlight current progress.", stateTable = db.styling and db.styling.objectives, stateKey = "objectiveTrackerSkinning", pageId = "Styling", tabIndex = 4 },
        { name = "Instance Frames", desc = "Skins the Dungeon Finder, LFG, and Premade Groups menu globally.\nUnifies the complex LFG panel with standard GravityUI colors.", stateTable = db.styling and db.styling.instanceFrames, stateKey = "enabled", pageId = "Styling", tabIndex = 12 },
        { name = "Experience & Rep", desc = "Draws highly customized, moveable tracking bars for XP and faction Rep.\nMorphs based on max level logic immediately.", stateTable = db.styling and db.styling.xpRep, stateKey = "enabled", pageId = "Styling", tabIndex = 13 },
        { name = "Chat Styling", desc = "Glassmorphic chat windows with short channel names and clickable URLs.\nOptimizes chat layout and supports dynamic fading for inactivity.", stateTable = db.uiimprovements and db.uiimprovements.chat, stateKey = "enabled", pageId = "Styling", tabIndex = 2 },
        { name = "Tooltip Styling", desc = "Modernized, dark-themed tooltips with clean health bars.\nDisplays advanced information like Item IDs, Spell IDs, and NPC IDs.", stateTable = db.uiimprovements and db.uiimprovements.tooltip, stateKey = "enabled", pageId = "Styling", tabIndex = 3 },
        { name = "Character Panel Enhancements", desc = "Directly embeds item level, durability, enchants, and gems onto slots.\nSignificantly enhances the player and inspect character paper dolls.", stateTable = db.uiimprovements and db.uiimprovements.character, stateKey = "enabled", pageId = "Styling", tabIndex = 1 },
        { name = "Static Popups", desc = "Skins Blizzard's dialog popups (Group Invite, Duel, Resurrect) with the GravityUI theme.\nApplies dark backgrounds, accent borders, and custom fonts to all popup buttons.", stateTable = db.styling and db.styling.staticPopups, stateKey = "enabled", pageId = "Styling", tabIndex = 14 },
        
        -- Profiles (profiles.lua)
        { name = "Manage Profiles", desc = "Create, delete, and copy persistent addon profile hierarchies entirely.\nManages different character needs from a unified interface.", pageId = "profiles", tabIndex = 1 },
        { name = "Import / Export", desc = "Share and backup profiles via export hash strings securely.\nSeamlessly send an entire UI array directly to friends via web strings.", pageId = "profiles", tabIndex = 2 },
        { name = "Gravity Strings (WA)", desc = "Import critical integrated WeakAuras (Class UI, M+ Automarks, Utilities).\nSyncs directly with the custom GravityUI WeakAura system packages.", pageId = "profiles", tabIndex = 3 },
        { name = "Installers", desc = "Relaunch the First-Time initial setup and addon dependency installers.\nResyncs layout profiles for Details, Plater, and UUF instantly.", pageId = "profiles", tabIndex = 4 },
    }

    table.sort(features, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    for _, f in ipairs(features) do
        CreateFeatureRow(content, f.name, f.desc, f.stateTable, f.stateKey, y, f.pageId, f.tabIndex)
        y = y - 60
    end

    content:SetHeight(math.abs(y) + 50)
end

ns.GUI:RegisterPage("information", {
    title = "Information",
    subTabs = {
        { name = "Information", builder = BuildInformationTab },
    },
    OnBuild = function(content)
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        local opts = GUI.pages["information"]
        opts.subTabsContainer = ns.GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["information"]
        if not opts.subTabsContainer then return end
        
        subIndex = subIndex or 1
        
        for _, cf in pairs(opts.subTabsContainer.tabContents) do
            cf:Hide()
        end
        
        if opts.subTabsContainer.tabContents[subIndex] then
            opts.subTabsContainer.tabContents[subIndex]:Show()
        end
    end
})
