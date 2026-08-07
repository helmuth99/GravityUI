-- GravityUI - Information Page
local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = GUI.Colors

-- ============================================================
-- FEATURE ROW WIDGET
-- Clickable card that shows the feature name, description,
-- and an optional ON/OFF toggle. Clicking navigates to the
-- correct settings page and sub-tab.
-- ============================================================
local function CreateFeatureRow(container, name, desc, stateTable, stateKey, yOffset, pageId, tabIndex)
    local PAD = 10
    local row = CreateFrame("Button", nil, container, "BackdropTemplate")
    row:SetSize(GUI.CONTENT_WIDTH - 45, 55)
    row:SetPoint("TOPLEFT", PAD, yOffset)

    -- Backdrop
    GUI:CreateBackdrop(row, {0.12, 0.12, 0.14, 0.45}, C.border)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.12)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.14, 0.45)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    end)

    -- Left accent bar
    local accentBar = row:CreateTexture(nil, "BACKGROUND")
    accentBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    accentBar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
    accentBar:SetSize(2, 55)
    accentBar:SetPoint("LEFT", row, "LEFT", 0, 0)

    if pageId then
        row:SetScript("OnClick", function()
            GUI:ShowPage(pageId, tabIndex)
        end)
    end

    -- Feature title
    local title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(title, 13, "", C.accent)
    title:SetPoint("TOPLEFT", 14, -7)
    title:SetText(name)

    -- Status button (right side)
    local statusBtn = CreateFrame("Button", nil, row)
    statusBtn:SetSize(52, 55)
    statusBtn:SetPoint("RIGHT", row, "RIGHT", -12, 0)

    local status = statusBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(status, 12, "")
    status:SetPoint("RIGHT", statusBtn, "RIGHT", 0, 0)

    local isEnabled = stateTable and stateTable[stateKey]

    local function UpdateStatus()
        isEnabled = stateTable and stateTable[stateKey]
        if isEnabled == true then
            status:SetText("|cFF4DFF8FON|r")
            statusBtn:Show()
        elseif isEnabled == false then
            status:SetText("|cFFFF5555OFF|r")
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
            print("|cff00BFFFGravityUI:|r '" .. name .. "' changed. Please |cff00FF00/reload|r to apply.")
        end
    end)
    statusBtn:SetScript("OnEnter", function(self)
        if stateTable and stateKey then
            status:SetText(isEnabled and "|cFF33FF77ON|r" or "|cFFDD3333OFF|r")
            row:GetScript("OnEnter")(row)
        end
    end)
    statusBtn:SetScript("OnLeave", function(self)
        UpdateStatus()
        row:GetScript("OnLeave")(row)
    end)

    -- Description
    local descLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(descLabel, 11, "")
    descLabel:SetPoint("BOTTOMLEFT", 14, 7)
    descLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    descLabel:SetPoint("RIGHT", statusBtn, "LEFT", -8, 0)
    descLabel:SetJustifyH("LEFT")
    descLabel:SetJustifyV("TOP")
    descLabel:SetSpacing(2)
    descLabel:SetTextColor(unpack(C.textMuted))
    descLabel:SetText(desc)

    return row
end

-- ============================================================
-- CHANGELOG CARD WIDGET
-- A modern glassmorphic card for one version entry.
-- ============================================================
local function CreateChangelogCard(container, log, yOffset)
    local PAD = 10
    local BULLET_FONT_SIZE = 11
    local BULLET_PAD = 4
    local BULLET_INDENT = 12
    local CARD_INNER_PAD_TOP = 10
    local CARD_INNER_PAD_BOTTOM = 10
    local CARD_INNER_PAD_SIDES = 14
    local cardWidth = GUI.CONTENT_WIDTH - 45

    -- Pre-calculate total card height by measuring bullet wrap
    local availWidth = cardWidth - (CARD_INNER_PAD_SIDES * 2) - BULLET_INDENT - 20

    local totalHeight = CARD_INNER_PAD_TOP
    totalHeight = totalHeight + 18   -- version header line
    totalHeight = totalHeight + 6    -- gap after header

    local measureFS = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(measureFS, BULLET_FONT_SIZE, "")
    measureFS:SetWidth(availWidth)
    measureFS:SetJustifyH("LEFT")
    measureFS:SetSpacing(2)

    local bulletHeights = {}
    for _, change in ipairs(log.changes) do
        measureFS:SetText("- " .. change)
        local h = measureFS:GetStringHeight()
        bulletHeights[#bulletHeights + 1] = (h > 0 and h or 16)
        totalHeight = totalHeight + bulletHeights[#bulletHeights] + BULLET_PAD
    end
    measureFS:Hide()

    totalHeight = totalHeight + CARD_INNER_PAD_BOTTOM

    -- Card Frame
    local card = CreateFrame("Frame", nil, container, "BackdropTemplate")
    card:SetSize(cardWidth, totalHeight)
    card:SetPoint("TOPLEFT", PAD, yOffset)

    GUI:CreateBackdrop(card, {0.11, 0.11, 0.13, 0.5}, {C.border[1], C.border[2], C.border[3], 0.6})

    -- Left accent stripe
    local stripe = card:CreateTexture(nil, "BACKGROUND")
    stripe:SetTexture("Interface\\Buttons\\WHITE8x8")
    stripe:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.9)
    stripe:SetSize(2, totalHeight)
    stripe:SetPoint("LEFT", card, "LEFT", 0, 0)

    -- Version header
    local versionText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(versionText, 13, "", C.accent)
    versionText:SetPoint("TOPLEFT", CARD_INNER_PAD_SIDES, -CARD_INNER_PAD_TOP)
    versionText:SetJustifyH("LEFT")
    versionText:SetText("|cFF30D1FFv" .. log.version .. "|r")

    local dateText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(dateText, 11, "")
    dateText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_INNER_PAD_SIDES, -CARD_INNER_PAD_TOP)
    dateText:SetJustifyH("RIGHT")
    dateText:SetTextColor(unpack(C.textMuted))
    dateText:SetText(log.date)

    -- Bullet points
    local lastAnchor = versionText
    local lastAnchorPad = -6

    for i, change in ipairs(log.changes) do
        local bullet = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        GUI:SetFont(bullet, BULLET_FONT_SIZE, "")
        bullet:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", (i == 1 and 0 or 0), lastAnchorPad)
        bullet:SetWidth(availWidth)
        bullet:SetJustifyH("LEFT")
        bullet:SetJustifyV("TOP")
        bullet:SetSpacing(2)
        bullet:SetTextColor(0.82, 0.82, 0.82, 1)
        bullet:SetText("- " .. change)

        lastAnchor = bullet
        lastAnchorPad = -BULLET_PAD
    end

    return card, totalHeight
end

-- ============================================================
-- SUB-HEADER helper (line-less, category marker)
-- ============================================================
local function CreateSubHeader(parent, text, yOffset)
    local PAD = 10
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(fs, 12, "", C.accent)
    fs:SetPoint("TOPLEFT", PAD, yOffset)
    fs:SetText(text)
    return fs
end

-- ============================================================
-- MAIN TAB BUILDER
-- ============================================================
local function BuildInformationTab(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local y = -10
    local PAD = 10
    local db = ns.GetDB()
    if not db then return end

    -- ==========================================================
    -- SECTION 1: RECENT CHANGELOGS
    -- ==========================================================
    local changelogHeader = GUI:CreateSectionHeader(content, "Recent Changelogs")
    changelogHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - changelogHeader.gap
    y = y - 10

    local clInfoBox = GUI:CreateInfoBox(content,
        "|cffaaaaaaInfo:|r Recent GravityUI version history. Click any card in the Feature Hub below to jump directly to that module's settings page.")
    clInfoBox:SetPoint("TOPLEFT", PAD, y)
    y = y - clInfoBox:GetHeight() - 10

    -- Changelog data (newest first)
    local changeLogs = {
        {
            version = "4.00.27",
            date = "08/07/2026",
            changes = {
                "Fixed Consumables Raid Frame Durability: local player now queries GetInventoryItemDurability directly instead of relying on LibOpenRaid (fixes Demon Hunters and intermittent blank Durability for all classes on frame open)",
            },
        },
        {
            version = "4.00.26",
            date = "08/07/2026",
            changes = {
                "API 12.1 migration: replaced deprecated GetSpellCooldown, GetItemInfo, IsSpellKnown, GetSpellInfo with C_Spell / C_Item namespaces across core modules",
                "Added Cinematic Auto-Skip -- automatically dismisses in-game cinematics (QoL > Automation, toggle in UI)",
                "Added Weapon Enchant reminder (Oil/Whetstone) to Missing Buffs > Self Buffs > Consumables -- shows NO OIL for melee classes",
                "Fixed Weapon Oil Expiration Warning: customCheck now returns remaining time (ms) for correct Pixel Glow triggering",
                "Fixed Consumables Raid Frame: scanMemberAuras now uses tonumber(aura.spellId) to avoid secret-number taint drops",
                "Fixed Demon Hunter showing 0% Durability: LibOpenRaid default value 0 now shown as dash (data not yet received)",
                "Added Pull Timer Auto-Hide: Raid Frame closes 5s before pull when BigWigs or DBM fires a pull countdown",
            },
        },
        {
            version = "4.00.01",
            date = "07/19/2026",
            changes = {
                "Migrated Unitframes, Party and Raid frames to EllesmereUI (UUF / Ayije no longer updated)",
                "Completely removed UnhaltedUnitFrames (UUF) and AyijeCDM",
                "Removed Castbar Ticks module (TOC, menu entries, defaults)",
                "Added EllesmereUI to Installer registry for profile management",
                "Added EllesmereUI minimap button to IconCatcher",
                "Added EllesmereUI to bottom bar buttons (Unitframes, CDM, Nameplates, Party/Raid)",
                "Updated FPS settings: Shadow=Fair, Liquid=Low, Particle=Ultra, Spell=Low, ViewDist=Level2",
                "TOC: introduced v4.00.25 packager token",
            },
        },
        {
            version = "3.94.68",
            date = "04/13/2026",
            changes = {
                "Integrated Midnight expansion consumables (Food, Flasks, Augment Runes) into RaidBuffs module",
                "Implemented smart talent filtering for class-specific reminders (Shaman Shields, Paladin Rites, Druid Symbiosis)",
                "Fixed UI overlap bug in Missing Buffs settings during custom buff manipulation",
                "Added /glog and /gravitylog commands with toggle support for manual combat log control",
                "Enhanced Combat Log automation with clearer chat feedback for M+ and Raid transitions",
                "Optimized Elemental Orbit shield logic to prevent false-positives for multi-shield classes",
            },
        },
    }

    for i = 1, math.min(#changeLogs, 3) do
        local log = changeLogs[i]
        local card, cardHeight = CreateChangelogCard(content, log, y)
        y = y - cardHeight - 8
    end

    y = y - 20

    -- ==========================================================
    -- SECTION 2: FEATURE HUB
    -- ==========================================================
    local hubHeader = GUI:CreateSectionHeader(content, "Feature Hub -- Status & Navigation")
    hubHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - hubHeader.gap
    y = y - 10

    local hubInfoBox = GUI:CreateInfoBox(content,
        "|cffaaaaaaInfo:|r Click any card to navigate directly to that settings page. The ON/OFF button on the right toggles the module instantly -- a |cff00FF00/reload|r is required afterwards to apply.")
    hubInfoBox:SetPoint("TOPLEFT", PAD, y)
    y = y - hubInfoBox:GetHeight() - 12

    -- Helper to render a category block
    local function RenderCategory(label, featureList)
        local sub = CreateSubHeader(content, label, y)
        y = y - 22

        for _, f in ipairs(featureList) do
            CreateFeatureRow(content, f.name, f.desc, f.stateTable, f.stateKey, y, f.pageId, f.tabIndex)
            y = y - 62
        end
        y = y - 10
    end

    -- Core & Theme
    RenderCategory(">> Core & Theme", {
        { name = "Theme Color",           desc = "Base accent color used across all GravityUI styling modules.",                                                     pageId = "main",       tabIndex = 2 },
        { name = "Global UI Scale",       desc = "Centralized interface scaling with quick one-click presets.",                                                      pageId = "main",       tabIndex = 3 },
        { name = "Global Fonts",          desc = "Global font style settings applied across all UI elements.",                                                       pageId = "main",       tabIndex = 4 },
        { name = "FPS Optimization",      desc = "Apply Gravity's curated graphics settings for competitive play.",                                                  pageId = "main",       tabIndex = 5 },
        { name = "Edit Mode (GravityUI)", desc = "Enable GravityUI's custom frame movers. Freely reposition all registered frames independently.",                  pageId = "main",       tabIndex = 6 },
    })

    -- Minimap
    RenderCategory(">> Minimap", {
        { name = "Minimap Overhaul",  desc = "Transforms the default minimap into a clean square or round frame with smart anchoring and dynamic zoom.",             stateTable = db.minimap,                        stateKey = "enabled", pageId = "minimap", tabIndex = 1 },
        { name = "Minimap Elements",  desc = "Configure zone text, coordinates, clock, and tracking icons around the minimap edge.",                                 pageId = "minimap", tabIndex = 2 },
        { name = "Icon Catcher",      desc = "Collect messy addon minimap icons into a dropdown or drawer. Supports automatic and manual catching.",                 stateTable = db.minimap and db.minimap.catcher, stateKey = "enabled", pageId = "minimap", tabIndex = 3 },
    })

    -- Action Bars
    RenderCategory(">> Action Bars", {
        { name = "Action Bars",          desc = "Custom skinned, dynamically fading action bars. Adjust scaling, padding, backdrop and hotkey fonts.",              stateTable = db.actionbars,                        stateKey = "enabled", pageId = "actionbars", tabIndex = 1 },
        { name = "Mouseover Settings",   desc = "Configure fade rules based on mouse interactions, global fade duration, delays and out-of-combat hiding.",         stateTable = db.actionbars and db.actionbars.fade, stateKey = "enabled", pageId = "actionbars", tabIndex = 2 },
        { name = "Extra Action Buttons", desc = "Scale and reposition the Extra Action Button, Zone Ability, and Encounter bars.",                                  pageId = "actionbars", tabIndex = 3 },
    })

    -- Datapanels
    RenderCategory(">> Datapanels", {
        { name = "Minimap Datapanel", desc = "Information bar anchored below the minimap displaying durability, gold, latency, or time.",                           stateTable = db.minimap and db.minimap.datatext, stateKey = "enabled", pageId = "datapanels", tabIndex = 1 },
        { name = "Custom Panels",     desc = "Create highly customizable floating data text strings for any tracked metric, anywhere on screen.",                   pageId = "datapanels", tabIndex = 2 },
    })

    -- Quality of Life
    RenderCategory(">> Quality of Life", {
        { name = "Automation / Stuff", desc = "Auto-repair, fast loot, junk selling, quest accept, movie skips, cinematic auto-skip, and dialogue routing -- all automated.", pageId = "qol", tabIndex = 1 },
        { name = "Autohide Setup",     desc = "Contextual UI hiding based on game events (e.g. minigames) to preserve full immersion.",                                         pageId = "qol", tabIndex = 2 },
    })

    -- Features
    RenderCategory(">> Features", {
        { name = "Skyriding Tracking",  desc = "Smooth animated Vigor tracking HUD replacing the fragmented default UI with a unified centered layout.",             stateTable = db.skyriding,                                  stateKey = "enabled",              pageId = "features", tabIndex = 1 },
        { name = "M+ Teleport Icons",   desc = "Clickable dungeon portals embedded in the Mythic+ LFG UI. Port to dungeons without searching your spellbook.",      stateTable = db.uiimprovements,                             stateKey = "mplusTeleportEnabled", pageId = "features", tabIndex = 2 },
        { name = "World Marks",         desc = "Streamlined interface for dropping world markers and flares with quick access to ready checks and pull timers.",     stateTable = db.uiimprovements and db.uiimprovements.marks, stateKey = "enabled",              pageId = "features", tabIndex = 3 },
        { name = "Mail Extras",         desc = "Adds an Open All button, an address book for alts and friends, and gold loot messages to the mailbox.",             stateTable = db.uiimprovements and db.uiimprovements.mail,  stateKey = "enabled",              pageId = "features", tabIndex = 4 },
        { name = "Group & Guild Tools", desc = "Guild invite tool and automatic role promotion for assistants in groups and raids.",                                  pageId = "features", tabIndex = 5 },
        { name = "Interrupt Tracker",   desc = "Tracks interrupt cooldowns of party members in M+ dungeons. Uses Say/Party chat as a broadcast fallback.",           stateTable = db.screenindicators and db.screenindicators.interruptTracker, stateKey = "enabled", pageId = "features", tabIndex = 6 },
    })

    -- Screen Indicators
    RenderCategory(">> Screen Indicators", {
        { name = "Cursor Utilities",    desc = "Attach GCD rings, cursor castbars, and highlights directly to your mouse cursor.",                                   stateTable = db.screenindicators and db.screenindicators.cursor,       stateKey = "enabled", pageId = "indicators", tabIndex = 1 },
        { name = "Crosshair",           desc = "Dynamic class-specific targeting crosshairs with real-time range color coding.",                                    stateTable = db.screenindicators and db.screenindicators.crosshair,    stateKey = "enabled", pageId = "indicators", tabIndex = 2 },
        { name = "Pet Info",            desc = "Pet management tools and large status warnings (Pet Dead) for Hunters and Warlocks.",                               stateTable = db.screenindicators and db.screenindicators.petWarnings,  stateKey = "enabled", pageId = "indicators", tabIndex = 3 },
        { name = "Combat Timer",        desc = "Visual stopwatch tracking time spent in combat or encounters. Great for raid bosses and M+ pack analysis.",         stateTable = db.uiimprovements and db.uiimprovements.combatTimer,      stateKey = "enabled", pageId = "indicators", tabIndex = 4 },
        { name = "Cooldown Text",       desc = "On-screen text alerts when tracked party spells go on cooldown. Configurable per class with custom spell IDs.",     stateTable = db.cooldownText,                                         stateKey = "enabled", pageId = "indicators", tabIndex = 5 },
        { name = "Missing Buffs (Raid)", desc = "Dynamically tracks missing raid buffs based on group class composition. Includes Consumables (Oil/Whetstone), Shaman Imbues, and Paladin Rites. Shows exactly what is missing pre-pull.", stateTable = db.raidBuffs, stateKey = "enabled", pageId = "indicators", tabIndex = 6 },
        { name = "Raid Warnings",       desc = "Displays large centralized text alerts for Soulwells, Feasts, Mage Tables, and Rituals.",                           stateTable = db.raidWarnings,                                         stateKey = "enabled", pageId = "indicators", tabIndex = 7 },
        { name = "Consumables Tracker", desc = "Shows missing consumables (food, flasks) for yourself and group members during a Ready Check.",                     stateTable = db.screenindicators and db.screenindicators.consumables,  stateKey = "enabled", pageId = "indicators", tabIndex = 8 },
        { name = "Difficulty Indicator", desc = "Status bar showing the current instance difficulty with a dropdown to change it quickly while out of world.",     stateTable = db.screenindicators and db.screenindicators.difficulty,   stateKey = "enabled", pageId = "indicators", tabIndex = 9 },
        { name = "AFK Screen",          desc = "Immersive cinematic character orbit when AFK. Displays real time, guild, character rank, and a moving camera.",     stateTable = db.screenindicators and db.screenindicators.afkScreen,   stateKey = "enabled", pageId = "indicators", tabIndex = 10 },
    })

    -- Utilities
    RenderCategory(">> Utilities", {
        { name = "Sound Alerts",  desc = "Integrate custom SharedMedia sounds directly into Blizzard's CooldownViewer seamlessly.",                                   stateTable = db.soundAlerts, stateKey = "enabled", pageId = "utilities", tabIndex = 1 },
        { name = "Debuffs",       desc = "Track specific debuffs on nameplates or unit frames with custom duration timers and alert colors.",                          pageId = "utilities", tabIndex = 2 },
        { name = "Tracked Bars",  desc = "Configurable progress bars tracking specific spells, items or timers with custom thresholds and warnings.",                  pageId = "utilities", tabIndex = 3 },
    })

    -- UI Styling
    RenderCategory(">> UI Styling", {
        { name = "Character Panel Enhancements", desc = "Embeds item level, durability, enchants, and gems directly onto character slot icons.",                    stateTable = db.uiimprovements and db.uiimprovements.character,   stateKey = "enabled",              pageId = "Styling", tabIndex = 1 },
        { name = "Chat Styling",        desc = "Glassmorphic chat windows with short channel names, clickable URLs, and dynamic inactivity fading.",                stateTable = db.uiimprovements and db.uiimprovements.chat,        stateKey = "enabled",              pageId = "Styling", tabIndex = 2 },
        { name = "Tooltip Styling",     desc = "Modern dark-themed tooltips with health bars and advanced info like Item IDs, Spell IDs, and NPC IDs.",             stateTable = db.uiimprovements and db.uiimprovements.tooltip,     stateKey = "enabled",              pageId = "Styling", tabIndex = 3 },
        { name = "Objective Tracker",   desc = "Blizzard objective tracker with progressive color text and clean styling profiles.",                                 stateTable = db.styling and db.styling.objectives,                stateKey = "objectiveTrackerSkinning", pageId = "Styling", tabIndex = 4 },
        { name = "Loot Enhancement",    desc = "Modernized loot frames supporting loot-under-mouse positioning with aesthetic boss kill styling.",                   stateTable = db.styling and db.styling.loot,                      stateKey = "enabled",              pageId = "Styling", tabIndex = 5 },
        { name = "Game Menu",           desc = "Fully customized Escape key menu with dark mode and unified structural gradients.",                                  stateTable = db.styling and db.styling.gamemenu,                  stateKey = "enabled",              pageId = "Styling", tabIndex = 6 },
        { name = "Ready Check",         desc = "Replaces the Blizzard Ready Check popup with a dark-themed custom frame.",                                          stateTable = db.styling,                                          stateKey = "skinReadyCheck",       pageId = "Styling", tabIndex = 7 },
        { name = "Keystone",            desc = "Overrides the Mythic+ Keystone pedestal frame with clean lines and legible text.",                                  stateTable = db.styling and db.styling.keystone,                  stateKey = "enabled",              pageId = "Styling", tabIndex = 8 },
        { name = "Power Bar",           desc = "Skins the Player Alternative Power bar (sanity, corruption, etc.) as a clean scalable flat bar.",                   stateTable = db.styling and db.styling.powerBar,                  stateKey = "enabled",              pageId = "Styling", tabIndex = 9 },
        { name = "Alert Frames",        desc = "Skins Blizzard alert toasts (Achievements, Loot Rolls, Mounts) with the GravityUI theme.",                         stateTable = db.styling and db.styling.alerts,                    stateKey = "enabled",              pageId = "Styling", tabIndex = 10 },
        { name = "Chat Bubbles",        desc = "Styles 3D in-world chat bubbles with custom fonts and flat dark backgrounds.",                                      stateTable = db.styling and db.styling.chatBubbles,               stateKey = "enabled",              pageId = "Styling", tabIndex = 11 },
        { name = "Instance Frames",     desc = "Skins the Dungeon Finder, LFG, and Premade Groups panel with standard GravityUI colors.",                           stateTable = db.styling and db.styling.instanceFrames,            stateKey = "enabled",              pageId = "Styling", tabIndex = 12 },
        { name = "Experience & Rep",    desc = "Moveable tracking bars for XP and faction reputation. Automatically morphs at max level.",                          stateTable = db.styling and db.styling.xpRep,                     stateKey = "enabled",              pageId = "Styling", tabIndex = 13 },
        { name = "Static Popups",       desc = "Skins Blizzard dialog popups (Group Invite, Duel, Resurrect) with dark backgrounds and accent borders.",            stateTable = db.styling and db.styling.staticPopups,              stateKey = "enabled",              pageId = "Styling", tabIndex = 14 },
    })

    -- Profiles
    RenderCategory(">> Profiles", {
        { name = "Manage Profiles",      desc = "Create, delete, and copy persistent addon profiles. Manage different character configurations centrally.",          pageId = "profiles", tabIndex = 1 },
        { name = "Import / Export",      desc = "Share and backup profiles via export hash strings. Send a complete UI setup directly to friends.",                  pageId = "profiles", tabIndex = 2 },
        { name = "Gravity Strings (WA)", desc = "Import integrated WeakAuras (Class UI, M+ Automarks, Utilities). Syncs with the GravityUI WeakAura packages.",     pageId = "profiles", tabIndex = 3 },
        { name = "Installers",           desc = "Relaunch the first-time setup and addon dependency installers. Re-sync Details and Plater profiles instantly.",     pageId = "profiles", tabIndex = 4 },
    })

    content:SetHeight(math.abs(y) + 60)
end

-- ============================================================
-- PAGE REGISTRATION
-- ============================================================
ns.GUI:RegisterPage("information", {
    title = "Information",
    subTabs = {
        { name = "Information", builder = BuildInformationTab },
    },
    OnBuild = function(content)
        local scrollFrame = content:GetParent()
        content:Hide()

        if scrollFrame and scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
            scrollFrame:EnableMouseWheel(false)
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
    end,
})
