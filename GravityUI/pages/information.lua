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
            GUI:ShowPage(pageId)
            if tabIndex then
                local page = GUI.pages[pageId]
                if page and page.subTabs and page.subTabs.tabButtons and page.subTabs.tabButtons[tabIndex] then
                    C_Timer.After(0.01, function() page.subTabs.tabButtons[tabIndex]:Click() end)
                end
            end
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

local function BuildInformationTab(content)
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
        { version = "3.88", date = "04.03.2026", changes = {
            "Added GravityUI skinning for Dominos action bars (Bars 1-14, all button types)",
            "Added GravityUI skinning for Bartender4 action bars (BT4Button1-120)",
            "Added 'Enable GravityUI Skinning' to Icon Catcher: removes gold ring, applies square backdrop + border",
            "Icon Catcher GravityUI skinning is zero-cost after load (no OnUpdate, no event overhead)",
            "Added missing defaults for skinDominos, skinBartender4, guiSkinning, groupkeysHideBackground, groupkeysHideTitleBar",
        } },
        { version = "3.87", date = "04.03.2026", changes = {
            "Added 'Hide Background' and 'Hide Label Bar' options to M+ Teleport Group Key List",
            "Lock/Unlock and Reset Scale icons are now also hidden when Hide Label Bar is active",
        } },
        { version = "3.86", date = "02.03.2026", changes = {
            "Overhauled 'Group Key List' visibility - now strictly restricted to 5-man parties outside of instances",
            "Added 'Lock/Unlock' frame functionality to the Group Key List to prevent accidental movement and resizing",
            "Added a 'Scale Reset' button to the Group Key List header to quickly restore the 1.0 scale factor",
            "Implemented hover tooltips for all keystones in the Group Key List for rapid affix and level inspection",
            "Cleaned up legacy chat commands: Removed !key and !keys to reduce internal and shared chat noise"
        } },
        { version = "3.85", date = "01.03.2026", changes = {
            "Added Sound Alerts module to 'UI Utilities' for replacing game sounds with custom SharedMedia files",
            "Added manual 'Play' buttons for instant sound previews in the Sound Alerts menu",
            "Resolved 'ADDON_ACTION_BLOCKED' taint in the main window by utilizing UISpecialFrames for Escape handling",
            "Harden 'Messages' subsystem against Retail 12.0 secret spellID crashes using iteration-based pcall guards"
        } },
        { version = "3.84", date = "01.03.2026", changes = {"Fixed a UI layout anchoring bug preventing Options from drawing correctly", "Fixed a nil value crash in the Messages subsystem when iterating buff slots"} },
        { version = "3.83", date = "01.03.2026", changes = {"Overhauled Misdirection and Tricks of the Trade tracking logic to circumvent hidden API limitations", "Expanded Ranged Crosshair checks to cover all class rotations (e.g. Aimed Shot, Chaos Bolt)", "Fixed a bug where existing UI profiles failed to load Stealth settings in the Messages module", "Synced Midnight enchantable slots (Head/Shoulder) to the Inspect Panel"} },
        { version = "3.82", date = "28.02.2026", changes = {"Added UIWidgetPowerBarContainerFrame (Widget Power Bar) to EditMode Custom Movers", "Fixed false positive 'No Enchant' displayed on Held-in-off-hand items and shields in Character Panel"} },
        { version = "3.81", date = "27.02.2026", changes = {"Added 'Messages' subtab to UI Indicators with Trackers for Misdirection, Tricks of the Trade, Durability, Stealth, and Shroud", "Fixed 'Details' Profile Installation not applying custom strings correctly", "Updated Character Panel enchant logic for the Midnight expansion (Head/Shoulder)"} },
        { version = "3.80", date = "27.02.2026", changes = {"Integrated Extra Action Button and Zone Ability into the custom Edit Mode movers", "Fixed an issue where Blizzard's Minimap overlay blocked clicks in Edit Mode"} },
        { version = "3.79", date = "26.02.2026", changes = {"Updated Gravity Font with kyrillic support"} },
        { version = "3.78", date = "26.02.2026", changes = {"Added an option to automatically prompt and restore GravityUI Edit Mode Layout upon specialization switch", "Added a quick 'Disable Check' option into the Edit Mode popup"} },
        { version = "3.77", date = "26.02.2026", changes = {"Fixed missing or incorrect sound file assets paths across the UI"} },
        { version = "3.76", date = "26.02.2026", changes = {"Fixed an issue where the GravityUI Installer failed to sync UnhaltedUnitFrames", "Fixed 'Death Release Protection' blocking clicks on recycled 'Accept Resurrection' popups", "Added a 'Clear Alts List' button to the Mail Module Address Book"} },
    }

    for i = 1, math.min(#changeLogs, 3) do
        local log = changeLogs[i]
        local vLabel = GUI:CreateLabel(content, "|cFF30D1FFv" .. log.version .. "|r - " .. log.date, 13, C.accent)
        vLabel:SetPoint("TOPLEFT", PAD, y)
        y = y - 20
        
        for _, change in ipairs(log.changes) do
            local bullet = GUI:CreateLabel(content, " • " .. change, 11, C.text)
            bullet:SetPoint("TOPLEFT", PAD + 10, y)
            y = y - 16
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
        { name = "Special Buttons", desc = "Control the Extra Action Button, Zone Ability, and Encounter bars.\nEasily scale and reposition these critical scenario-specific buttons.", pageId = "actionbars", tabIndex = 3 },
        
        -- Datapanels (datapanels.lua)
        { name = "Minimap Datapanel", desc = "Information bar anchored below the minimap showing tracked metrics.\nDisplays dynamically updating durability, gold, latency, or time.", stateTable = db.minimap and db.minimap.datatext, stateKey = "enabled", pageId = "datapanels", tabIndex = 1 },
        { name = "Custom Panels", desc = "Create highly customizable, floating text strings for any tracked data.\nBuild personalized dashboards anywhere on your screen.", pageId = "datapanels", tabIndex = 2 },
        
        -- UI Improvements (uiimprovements.lua)
        { name = "Automation", desc = "Automates tedious tasks out of sight: auto-repair, fast loot, and sell junk.\nIncludes auto-accepting quests, skips for movies, and dialogue routing.", pageId = "uiimprovements", tabIndex = 1 },
        { name = "Autohide Setup", desc = "Configure contextual hiding rules based on game events (e.g. Minigames).\nAutomatically hides specific UI frames to preserve immersion.", pageId = "uiimprovements", tabIndex = 2 },
        { name = "Combat Settings", desc = "Visual combat lockouts, screen flashes on aggro, and threat coloring.\nReplaces aggressive default red flashes with customized indicators.", pageId = "uiimprovements", tabIndex = 3 },
        { name = "Blizzard Buffs & Debuffs", desc = "Enhances the default player buff/debuff frames with modern borders.\nRemoves the rigid Blizzard texture wrapping.", stateTable = db.uiimprovements and db.uiimprovements.buffBorders, stateKey = "enableBuffs", pageId = "uiimprovements", tabIndex = 4 },
        { name = "Chat Styling", desc = "Glassmorphic chat windows with short channel names and clickable URLs.\nOptimizes chat layout and supports dynamic fading for inactivity.", stateTable = db.uiimprovements and db.uiimprovements.chat, stateKey = "enabled", pageId = "uiimprovements", tabIndex = 5 },
        { name = "Tooltip Styling", desc = "Modernized, dark-themed tooltips with clean health bars.\nDisplays advanced information like Item IDs, Spell IDs, and NPC IDs.", stateTable = db.uiimprovements and db.uiimprovements.tooltip, stateKey = "enabled", pageId = "uiimprovements", tabIndex = 6 },
        { name = "Character Panel Enhancements", desc = "Directly embeds item level, durability, enchants, and gems onto slots.\nSignificantly enhances the player and inspect character paper dolls.", stateTable = db.uiimprovements and db.uiimprovements.character, stateKey = "enabled", pageId = "uiimprovements", tabIndex = 7 },
        { name = "Skyriding Tracking", desc = "A smooth, customizable Vigor trackingHUD with visual animations.\nReplaces the disjointed default UI with a unified, centered layout.", stateTable = db.skyriding, stateKey = "enabled", pageId = "uiimprovements", tabIndex = 8 },
        { name = "Combat Timer", desc = "A visual stopwatch tracking the duration spent in combat or encounters.\nExcellent for visualizing long raid bosses or Mythic+ pack length.", stateTable = db.uiimprovements and db.uiimprovements.combatTimer, stateKey = "enabled", pageId = "uiimprovements", tabIndex = 9 },
        { name = "M+ Teleport Icons", desc = "Clickable dungeon portals embedded directly into the Mythic+ LFG UI.\nRapidly port to dungeons without searching through your spellbook.", stateTable = db.uiimprovements, stateKey = "mplusTeleportEnabled", pageId = "uiimprovements", tabIndex = 10 },
        { name = "World Marks", desc = "A streamlined interface for dropping world markers and flare tools.\nProvides quick access to ready-checks and countdown pull timers.", stateTable = db.uiimprovements and db.uiimprovements.marks, stateKey = "enabled", pageId = "uiimprovements", tabIndex = 11 },
        { name = "Mail Extras", desc = "Adds an 'Open All' button, an Address Book for alts and friends, and gold loot messages.\nImproves mailbox efficiency natively without extra addons.", stateTable = db.uiimprovements and db.uiimprovements.mail, stateKey = "enabled", pageId = "uiimprovements", tabIndex = 12 },
        
        -- Screen Indicators (screenindicators.lua)
        { name = "Cursor Utilities", desc = "Attach GCD Rings, Cursor Castbars, and highlights to your mouse.\nSuperb for tracking mechanics instantly without looking away from the action.", stateTable = db.screenindicators and db.screenindicators.cursor, stateKey = "enabled", pageId = "screenindicators", tabIndex = 1 },
        { name = "Crosshair", desc = "Provides dynamic class-specific targeting crosshairs emphasizing range.\nColor translates combat and spell-range availability in real-time.", stateTable = db.screenindicators and db.screenindicators.crosshair, stateKey = "enabled", pageId = "screenindicators", tabIndex = 2 },
        { name = "Combat Indicator", desc = "Displays a visual screen pulse indicating combat enter/exit status.\nHighly useful confirmation for aggressive aggro state changes.", stateTable = db.screenindicators and db.screenindicators.combatStatus, stateKey = "enabled", pageId = "screenindicators", tabIndex = 3 },
        { name = "Pet Info", desc = "Quick pet management tools and large status warnings (Pet Dead).\nCrucial for Hunters and Warlocks who need rapid reminders.", stateTable = db.screenindicators and db.screenindicators.petWarnings, stateKey = "enabled", pageId = "screenindicators", tabIndex = 4 },
        { name = "Missing Buffs (Raid)", desc = "Tracks missing raid buffs dynamically based on group class composition.\nExamines exactly who is present and what buffs are missing pre-pull.", stateTable = db.raidBuffs, stateKey = "enabled", pageId = "screenindicators", tabIndex = 5 },
        { name = "Raid Warnings", desc = "Displays centralized large text alerts for helpful utility spells.\nWarns for newly dropped Soulwells, Feasts, Mage Tables, and Rituals.", stateTable = db.raidWarnings, stateKey = "enabled", pageId = "screenindicators", tabIndex = 6 },
        { name = "Difficulty Indicator", desc = "Visual status bar tracking the currently selected instance difficulty.\nIncludes a dropdown for rapidly changing difficulties out-of-world.", stateTable = db.screenindicators and db.screenindicators.difficulty, stateKey = "enabled", pageId = "screenindicators", tabIndex = 7 },
        { name = "AFK Screen", desc = "An immersive, cinematic character orbit view when Away From Keyboard.\nDisplays real time, guild, character rank, and a moving camera.", stateTable = db.screenindicators and db.screenindicators.afkScreen, stateKey = "enabled", pageId = "screenindicators", tabIndex = 8 },

        
        -- UI Utilities (cdmutils.lua)
        { name = "Keybindings on CDM", desc = "Maps action bar keybind text directly onto the BetterCooldownManager frames.\nAllows custom coloring and hiding of the text on the cooling timeline icons.", stateTable = db.actionbars and db.actionbars.guicdm, stateKey = "enabled", pageId = "cdmutils", tabIndex = 1 },
        { name = "CDM Centering", desc = "Physically aligns BetterCooldownManager's frames symmetrically into the UI.\nGuarantees perfectly pixel-aligned center cooling timelines.", stateTable = db.actionbars and db.actionbars.cdmCentering, stateKey = "enabled", pageId = "cdmutils", tabIndex = 2 },
        { name = "Action Button Glow", desc = "Customizes the Proc, Alert, and Auto-attack glow on all action buttons.\nAllows re-coloring or overriding the highly noisy default animations.", stateTable = db.actionbars and db.actionbars.guicdm and db.actionbars.guicdm.utils, stateKey = "buttonGlow", pageId = "cdmutils", tabIndex = 3 },
        { name = "Castbar Ticks", desc = "Adds channeling tick marks (e.g., Evoker Disintegrate) to Unit Frames.\nTracks intervals mathematically to avoid clipping spells prematurely.", stateTable = db.general and db.general.castbarTicks and db.general.castbarTicks.disintegrate, stateKey = "enableUUF", pageId = "cdmutils", tabIndex = 4 },
        { name = "CDM Buffbar Integration", desc = "Enhances specific buff trackers with GravityUI styling logic.\nForces precise borders, shadows, and coloring onto third-party icons.", stateTable = db.actionbars and db.actionbars.cdmBuffbar, stateKey = "enabled", pageId = "cdmutils", tabIndex = 5 },
        { name = "Sound Alerts", desc = "Integrates custom SharedMedia sounds directly into Blizzard's CooldownViewer.\nSeamlessly replaces specific Blizzard sounds with your own media files.", stateTable = db.soundAlerts, stateKey = "enabled", pageId = "cdmutils", tabIndex = 6 },

        -- Styling Tab (styling.lua)
        { name = "Game Menu", desc = "Generates a fully customized Escape Key menu overriding the Blizzard UI.\nApplies unified structural gradients and dark-mode styling.", stateTable = db.styling and db.styling.gamemenu, stateKey = "enabled", pageId = "Styling", tabIndex = 1 },
        { name = "Chat Bubbles", desc = "Alters the 3D in-world chat bubbles with custom fonts and flat backgrounds.\nHighly readable and integrates with nameplate aesthetics.", stateTable = db.styling and db.styling.chatBubbles, stateKey = "enabled", pageId = "Styling", tabIndex = 2 },
        { name = "Ready Check", desc = "Replaces the Blizzard Ready Check pop-up with a customized dark version.\nSupports unique coloring and thematic structure fonts.", stateTable = db.styling, stateKey = "skinReadyCheck", pageId = "Styling", tabIndex = 3 },
        { name = "Keystone", desc = "Overrides the Mythic+ Keystone insertion pedestal frame.\nReplaces clunky textures with clean lines and legible text.", stateTable = db.styling and db.styling.keystone, stateKey = "enabled", pageId = "Styling", tabIndex = 4 },
        { name = "Power Bar", desc = "Skins the Player's Alternative Power bar (sanity, corruption, etc).\nConverts the bizarre Blizzard artwork into straight, scalable bars.", stateTable = db.styling and db.styling.powerBar, stateKey = "enabled", pageId = "Styling", tabIndex = 5 },
        { name = "Alert Frames", desc = "Skins Blizzard alert toast pop-ups (Achievements, Loot Rolls, Mounts).\nIntercepts specific windows without breaking API compatibility limits.", stateTable = db.styling and db.styling.alerts, stateKey = "enabled", pageId = "Styling", tabIndex = 6 },
        { name = "Loot Enhancement", desc = "Modernized loot frames supporting the 'loot-under-mouse' position metric.\nAesthetically wraps standard loot distributions and boss kills.", stateTable = db.styling and db.styling.loot, stateKey = "enabled", pageId = "Styling", tabIndex = 7 },
        { name = "Objective Tracker", desc = "Overrides Blizzard's quest tracking layout with clean styling profiles.\nUses progressive contextual color text to highlight current progress.", stateTable = db.styling and db.styling.objectives, stateKey = "objectiveTrackerSkinning", pageId = "Styling", tabIndex = 8 },
        { name = "Instance Frames", desc = "Skins the Dungeon Finder, LFG, and Premade Groups menu globally.\nUnifies the complex LFG panel with standard GravityUI colors.", stateTable = db.styling and db.styling.instanceFrames, stateKey = "enabled", pageId = "Styling", tabIndex = 9 },
        { name = "Experience & Rep", desc = "Draws highly customized, moveable tracking bars for XP and faction Rep.\nMorphs based on max level logic immediately.", stateTable = db.styling and db.styling.xpRep, stateKey = "enabled", pageId = "Styling", tabIndex = 10 },
        
        -- Profiles (profiles.lua)
        { name = "Manage Profiles", desc = "Create, delete, and copy persistent addon profile hierarchies entirely.\nManages different character needs from a unified interface.", pageId = "profiles", tabIndex = 1 },
        { name = "Import / Export", desc = "Share and backup profiles via export hash strings securely.\nSeamlessly send an entire UI array directly to friends via web strings.", pageId = "profiles", tabIndex = 2 },
        { name = "Gravity Strings (WA)", desc = "Import critical integrated WeakAuras (Class UI, M+ Automarks, Utilities).\nSyncs directly with the custom GravityUI WeakAura system packages.", pageId = "profiles", tabIndex = 3 },
        { name = "Installers", desc = "Relaunch the First-Time initial setup and addon dependency installers.\nResyncs layout profiles for Detail, Plater, UUF and BCDM instantly.", pageId = "profiles", tabIndex = 4 },
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
    OnBuild = BuildInformationTab,
})
