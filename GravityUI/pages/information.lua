-- GravityUI - Information Page
local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = GUI.Colors

-- ============================================================
-- COMPACT MODULE ROW  (26 px)
-- ============================================================
local function CreateModuleRow(parent, f, hy, rowWidth)
    local ROW_H = 26
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(rowWidth, ROW_H)
    row:SetPoint("TOPLEFT", 0, hy)
    GUI:CreateBackdrop(row, {0.10, 0.10, 0.12, 0.35}, {C.border[1], C.border[2], C.border[3], 0.6})
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.08)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.10, 0.10, 0.12, 0.35)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.6)
    end)
    if f.pageId then
        row:SetScript("OnClick", function() GUI:ShowPage(f.pageId, f.tabIndex) end)
    end
    local dot = row:CreateTexture(nil, "OVERLAY")
    dot:SetTexture("Interface\\Buttons\\WHITE8x8")
    dot:SetSize(3, ROW_H - 8)
    dot:SetPoint("LEFT", 6, 0)
    dot:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(nameFS, 11, "", C.accent)
    nameFS:SetPoint("LEFT", 16, 0)
    nameFS:SetWidth(130)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetText(f.name)
    local toggleBtn = CreateFrame("Button", nil, row)
    toggleBtn:SetSize(36, ROW_H)
    toggleBtn:SetPoint("RIGHT", -6, 0)
    local toggleFS = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(toggleFS, 10, "")
    toggleFS:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)
    local function RefreshToggle()
        local val = f.stateTable and f.stateTable[f.stateKey]
        if val == true then
            toggleFS:SetText("|cFF4DFF8FON|r"); toggleBtn:Show()
        elseif val == false then
            toggleFS:SetText("|cFFFF5555OFF|r"); toggleBtn:Show()
        else
            toggleFS:SetText(""); toggleBtn:Hide()
        end
    end
    RefreshToggle()
    toggleBtn:SetScript("OnClick", function()
        if f.stateTable and f.stateKey then
            f.stateTable[f.stateKey] = not f.stateTable[f.stateKey]
            RefreshToggle()
            print("|cff00BFFFGravityUI:|r '" .. f.name .. "' changed. Please |cff00FF00/reload|r to apply.")
        end
    end)
    local descFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(descFS, 10, "")
    descFS:SetPoint("LEFT", nameFS, "RIGHT", 8, 0)
    descFS:SetPoint("RIGHT", toggleBtn, "LEFT", -6, 0)
    descFS:SetJustifyH("LEFT")
    descFS:SetJustifyV("MIDDLE")
    descFS:SetTextColor(unpack(C.textMuted))
    descFS:SetText(f.desc)
    return ROW_H
end

-- ============================================================
-- GROUP HEADER BAR (mirrors sidebar menu style)
-- ============================================================
local function CreateGroupHeader(parent, label, hy, rowWidth)
    local HDR_H = 22
    local hdr = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    hdr:SetSize(rowWidth, HDR_H)
    hdr:SetPoint("TOPLEFT", 0, hy)
    GUI:CreateBackdrop(hdr,
        {C.accent[1]*0.15, C.accent[2]*0.15, C.accent[3]*0.15, 0.7},
        {C.accent[1]*0.6,  C.accent[2]*0.6,  C.accent[3]*0.6,  0.5})
    local bar = hdr:CreateTexture(nil, "OVERLAY")
    bar:SetTexture("Interface\\Buttons\\WHITE8x8")
    bar:SetSize(3, HDR_H)
    bar:SetPoint("LEFT", 0, 0)
    bar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    local fs = hdr:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(fs, 11, "", C.accent)
    fs:SetPoint("LEFT", 12, 0)
    fs:SetText(label)
    return HDR_H
end

-- ============================================================
-- CHANGELOG CARD WIDGET
-- ============================================================
local function CreateChangelogCard(container, log, yOffset)
    local PAD = 10
    local BULLET_FONT_SIZE = 11
    local BULLET_PAD = 4
    local CARD_INNER_PAD_TOP = 10
    local CARD_INNER_PAD_BOTTOM = 10
    local CARD_INNER_PAD_SIDES = 14
    local cardWidth = GUI.CONTENT_WIDTH - 45
    local availWidth = cardWidth - (CARD_INNER_PAD_SIDES * 2) - 12 - 20
    local totalHeight = CARD_INNER_PAD_TOP + 18 + 6
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
    local card = CreateFrame("Frame", nil, container, "BackdropTemplate")
    card:SetSize(cardWidth, totalHeight)
    card:SetPoint("TOPLEFT", PAD, yOffset)
    GUI:CreateBackdrop(card, {0.11, 0.11, 0.13, 0.5}, {C.border[1], C.border[2], C.border[3], 0.6})
    local stripe = card:CreateTexture(nil, "BACKGROUND")
    stripe:SetTexture("Interface\\Buttons\\WHITE8x8")
    stripe:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.9)
    stripe:SetSize(2, totalHeight)
    stripe:SetPoint("LEFT", card, "LEFT", 0, 0)
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
    local lastAnchor = versionText
    local lastAnchorPad = -6
    for i, change in ipairs(log.changes) do
        local bullet = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        GUI:SetFont(bullet, BULLET_FONT_SIZE, "")
        bullet:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, lastAnchorPad)
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
-- MAIN TAB BUILDER
-- ============================================================
local function BuildInformationTab(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local y = -10
    local PAD = 10
    local db = ns.GetDB()
    if not db then return end

    -- SECTION 1: LATEST CHANGELOG (newest entry only) ----------
    local changelogHeader = GUI:CreateSectionHeader(content, "Latest Changelog")
    changelogHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - changelogHeader.gap - 10

    local changeLogs = {
        {
            version = "4.00.31",
            date = "08/10/2026",
            changes = {
                "ExBoss string added to Gravity Strings tab (Profiles > Gravity Strings)",
                "WarpDeplete and Dander's Frames removed from Installer -- strings remain in Gravity Strings",
            },
        },
        {
            version = "4.00.32",
            date = "08/10/2026",
            changes = {
                "Fixed Consumables Raid Frame Durability not showing for Demon Hunters (and for yourself in a Raid group) -- previous fix used unit == 'player' which is never true in a Raid, now uses UnitIsUnit()",
            },
        },
        {
            version = "4.00.33",
            date = "08/11/2026",
            changes = {
                "Minimap Datapanel: Guild name is now truncated to 12 characters with '...' to prevent overflow in the panel slot",
            },
        },
        {
            version = "4.00.34",
            date = "08/11/2026",
            changes = {
                "Performance: loot.lua GroupLootFrame OnUpdate optimized -- GetDB() now cached on OnShow instead of every 0.2s tick, UpdateRollPositions() only called when width actually changes (State-Gatekeeping)",
            },
        },
        {
            version = "4.00.35",
            date = "08/11/2026",
            changes = {
                "12.1 Pre-Launch Performance Audit: 9x GetChildren() double-call GC churn fixed across buffborders.lua, objectives.lua, trackedbuffbar.lua, automation.lua",
                "buffborders.lua: borderColor {0,0,0,1} table removed from AddBorderToButton hot-path -- direct RGBA values passed (Zero-Allocation standard)",
                "automation.lua: anonymous closure in SafeRelease:Trigger() and LFG-listener loop cleaned up",
            },
        },
        {
            version = "4.00.36",
            date = "08/11/2026",
            changes = {
                "M+ Teleport: !key / !keys now posts the real clickable Keystone item link (|Hkeystone:) from bag scan instead of plain text -- same mechanism as MythicKeyAnnouncer",
                "M+ Teleport: GetOwnedKeystone() now returns the raw item link as 3rd value; bag scan detection updated to use |Hkeystone: literal match (more robust)",
            },
        },
        {
            version = "4.00.37",
            date = "08/11/2026",
            changes = {
                "Objective Tracker: Auto-Hide when empty -- tracker is hidden when no quests/scenarios/achievements are tracked (controllable via Features > Styling > Objective Tracker > Auto-Hide When Empty)",
            },
        },

        {
            version = "4.00.27",
            date = "08/07/2026",
            changes = {
                "Fixed Consumables Raid Frame Durability (fixes Demon Hunters and intermittent blank Durability)",
            },
        },
        {
            version = "4.00.26",
            date = "08/07/2026",
            changes = {
                "API 12.1 migration: C_Spell / C_Item namespaces across core modules",
                "Added Cinematic Auto-Skip (QoL > Automation)",
                "Added Weapon Enchant reminder to Missing Buffs",
                "Added Pull Timer Auto-Hide (closes 5s before BigWigs/DBM pull)",
            },
        },
    }

    local card, cardHeight = CreateChangelogCard(content, changeLogs[1], y)
    y = y - cardHeight - 24

    -- SECTION 2: COMPACT FEATURE HUB ---------------------------
    local hubHeader = GUI:CreateSectionHeader(content, "Feature Hub - Status & Navigation")
    hubHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - hubHeader.gap - 6

    local hubInfoBox = GUI:CreateInfoBox(content,
        "|cffaaaaaaInfo:|r Click any row to navigate to that settings page. The ON/OFF button toggles the module -- a |cff00FF00/reload|r is required to apply.")
    hubInfoBox:SetPoint("TOPLEFT", PAD, y)
    y = y - hubInfoBox:GetHeight() - 10

    local hubW = GUI.CONTENT_WIDTH - 45 - PAD * 2
    local hubFrame = CreateFrame("Frame", nil, content)
    hubFrame:SetPoint("TOPLEFT", PAD, y)
    hubFrame:SetWidth(hubW)

    local hy = 0
    local function H(label) CreateGroupHeader(hubFrame, label, hy, hubW); hy = hy - 28 end
    local function R(f)    CreateModuleRow(hubFrame, f, hy, hubW);       hy = hy - 28 end
    local function G()     hy = hy - 6 end

    H("  Main")
    R({ name="Theme Color",     desc="Base accent color used across all GravityUI styling modules.",                     pageId="main", tabIndex=2 })
    R({ name="Global UI Scale", desc="Centralized interface scaling with quick one-click presets.",                        pageId="main", tabIndex=3 })
    R({ name="Global Fonts",    desc="Global font style settings applied across all UI elements.",                         pageId="main", tabIndex=4 })
    R({ name="FPS Settings",    desc="Apply Gravity's curated graphics settings for competitive play.",                    pageId="main", tabIndex=5 })
    R({ name="Edit Mode",       desc="Enable custom frame movers to freely reposition all registered frames.",             pageId="main", tabIndex=6 })
    G()
    H("  Minimap")
    R({ name="Minimap Overhaul", desc="Square or round minimap with smart anchoring and dynamic zoom.",                   stateTable=db.minimap, stateKey="enabled", pageId="minimap", tabIndex=1 })
    R({ name="Minimap Elements", desc="Configure zone text, coordinates, clock, and tracking icons.",                     pageId="minimap", tabIndex=2 })
    R({ name="Icon Catcher",     desc="Collect addon minimap icons into a dropdown or drawer.",                            stateTable=db.minimap and db.minimap.catcher, stateKey="enabled", pageId="minimap", tabIndex=3 })
    G()
    H("  Action Bars")
    R({ name="Action Bars",          desc="Custom skinned, dynamically fading action bars with backdrop and hotkey fonts.",  stateTable=db.actionbars, stateKey="enabled", pageId="actionbars", tabIndex=1 })
    R({ name="Mouseover Settings",   desc="Configure fade rules based on mouse interaction, duration and combat state.",   stateTable=db.actionbars and db.actionbars.fade, stateKey="enabled", pageId="actionbars", tabIndex=2 })
    R({ name="Extra Action Buttons", desc="Scale and reposition the Extra Action Button, Zone Ability, and Encounter bars.", pageId="actionbars", tabIndex=3 })
    G()
    H("  Datapanels")
    R({ name="Minimap Datapanel", desc="Info bar below the minimap: durability, gold, latency, or time.",            stateTable=db.minimap and db.minimap.datatext, stateKey="enabled", pageId="datapanels", tabIndex=1 })
    R({ name="Custom Panels",     desc="Create floating data text strings for any tracked metric, anywhere on screen.",  pageId="datapanels", tabIndex=2 })
    G()
    H("  Quality of Life")
    R({ name="Automation",     desc="Auto-repair, fast loot, junk selling, quest accept, movie skips -- all automated.", pageId="qol", tabIndex=1 })
    R({ name="Autohide Setup", desc="Contextual UI hiding based on game events (e.g. minigames) for full immersion.",   pageId="qol", tabIndex=2 })
    G()
    H("  Features")
    R({ name="Skyriding HUD",     desc="Smooth animated Vigor tracking HUD with unified centered layout.",             stateTable=db.skyriding, stateKey="enabled", pageId="features", tabIndex=1 })
    R({ name="M+ Teleports",      desc="Clickable dungeon portals embedded in the Mythic+ LFG UI.",                   stateTable=db.uiimprovements, stateKey="mplusTeleportEnabled", pageId="features", tabIndex=2 })
    R({ name="World Marks",       desc="World markers, flares, quick access to ready checks and pull timers.",          stateTable=db.uiimprovements and db.uiimprovements.marks, stateKey="enabled", pageId="features", tabIndex=3 })
    R({ name="Mail Extras",       desc="Open All button, address book for alts, and gold loot messages.",               stateTable=db.uiimprovements and db.uiimprovements.mail, stateKey="enabled", pageId="features", tabIndex=4 })
    R({ name="Group & Guild",     desc="Guild invite tool and automatic role promotion for assistants.",                 pageId="features", tabIndex=5 })
    R({ name="Interrupt Tracker", desc="Tracks interrupt cooldowns of party members in M+ dungeons.",                   stateTable=db.screenindicators and db.screenindicators.interruptTracker, stateKey="enabled", pageId="features", tabIndex=6 })
    G()
    H("  Indicators")
    R({ name="Cursor Utilities",   desc="Attach GCD rings, cursor castbars and highlights to your mouse cursor.",       stateTable=db.screenindicators and db.screenindicators.cursor, stateKey="enabled", pageId="indicators", tabIndex=1 })
    R({ name="Crosshair",          desc="Dynamic class-specific targeting crosshair with real-time range color coding.",  stateTable=db.screenindicators and db.screenindicators.crosshair, stateKey="enabled", pageId="indicators", tabIndex=2 })
    R({ name="Pet Info",           desc="Pet management tools and large status warnings for Hunters and Warlocks.",       stateTable=db.screenindicators and db.screenindicators.petWarnings, stateKey="enabled", pageId="indicators", tabIndex=3 })
    R({ name="Combat Timer",       desc="Visual stopwatch tracking time spent in combat. Great for M+ and raid analysis.", stateTable=db.uiimprovements and db.uiimprovements.combatTimer, stateKey="enabled", pageId="indicators", tabIndex=4 })
    R({ name="Cooldown Text",      desc="On-screen text alerts when tracked party spells go on cooldown.",                stateTable=db.cooldownText, stateKey="enabled", pageId="indicators", tabIndex=5 })
    R({ name="Missing Buffs",      desc="Dynamically tracks missing raid buffs based on group class composition.",         stateTable=db.raidBuffs, stateKey="enabled", pageId="indicators", tabIndex=6 })
    R({ name="Raid Warnings",      desc="Large centralized alerts for Soulwells, Feasts, Mage Tables, and Rituals.",      stateTable=db.raidWarnings, stateKey="enabled", pageId="indicators", tabIndex=7 })
    R({ name="Consumables",        desc="Shows missing consumables for group members during a Ready Check.",               stateTable=db.screenindicators and db.screenindicators.consumables, stateKey="enabled", pageId="indicators", tabIndex=8 })
    R({ name="Difficulty",         desc="Status bar showing current instance difficulty with a quick-change dropdown.",    stateTable=db.screenindicators and db.screenindicators.difficulty, stateKey="enabled", pageId="indicators", tabIndex=9 })
    R({ name="AFK Screen",         desc="Immersive character orbit when AFK. Displays real time, guild, and rank.",        stateTable=db.screenindicators and db.screenindicators.afkScreen, stateKey="enabled", pageId="indicators", tabIndex=10 })
    G()
    H("  Utilities")
    R({ name="Sound Alerts", desc="Integrate custom SharedMedia sounds into Blizzard's CooldownViewer.",           stateTable=db.soundAlerts, stateKey="enabled", pageId="utilities", tabIndex=1 })
    R({ name="Debuffs",      desc="Track specific debuffs on nameplates or unit frames with custom timers.",             stateTable=db.debuffMirror, stateKey="enabled", pageId="utilities", tabIndex=2 })
    R({ name="Tracked Bars", desc="Configurable progress bars tracking spells, items or timers with custom thresholds.",  stateTable=db.actionbars and db.actionbars.cdmBuffbar, stateKey="enabled", pageId="utilities", tabIndex=3 })
    R({ name="Color Picker", desc="Full HSV color picker with saved slots, class colors, hex input, and live preview.",   stateTable=db.colorPicker, stateKey="enabled", pageId="utilities", tabIndex=4 })
    G()
    H("  UI Styling")
    R({ name="Character Panel",    desc="Embeds item level, durability, enchants and gems on character slot icons.",        stateTable=db.uiimprovements and db.uiimprovements.character, stateKey="enabled", pageId="Styling", tabIndex=1 })
    R({ name="Chat Styling",       desc="Glassmorphic chat windows with short channel names and clickable URLs.",          stateTable=db.uiimprovements and db.uiimprovements.chat, stateKey="enabled", pageId="Styling", tabIndex=2 })
    R({ name="Tooltip Styling",    desc="Modern dark tooltips with health bars, Item IDs, Spell IDs, and NPC IDs.",        stateTable=db.uiimprovements and db.uiimprovements.tooltip, stateKey="enabled", pageId="Styling", tabIndex=3 })
    R({ name="Objective Tracker",  desc="Blizzard objective tracker with progressive color text and clean styling.",        stateTable=db.styling and db.styling.objectives, stateKey="objectiveTrackerSkinning", pageId="Styling", tabIndex=4 })
    R({ name="Loot Enhancement",   desc="Modernized loot frames with loot-under-mouse positioning.",                       stateTable=db.styling and db.styling.loot, stateKey="enabled", pageId="Styling", tabIndex=5 })
    R({ name="Game Menu",          desc="Fully customized Escape menu with dark mode and structural gradients.",            stateTable=db.styling and db.styling.gamemenu, stateKey="enabled", pageId="Styling", tabIndex=6 })
    R({ name="Ready Check",        desc="Replaces the Blizzard Ready Check popup with a dark-themed custom frame.",        stateTable=db.styling, stateKey="skinReadyCheck", pageId="Styling", tabIndex=7 })
    R({ name="Keystone",           desc="Overrides the M+ Keystone pedestal frame with clean lines and legible text.",     stateTable=db.styling and db.styling.keystone, stateKey="enabled", pageId="Styling", tabIndex=8 })
    R({ name="Power Bar",          desc="Skins the Player Alternative Power bar (sanity, corruption) as a flat bar.",      stateTable=db.styling and db.styling.powerBar, stateKey="enabled", pageId="Styling", tabIndex=9 })
    R({ name="Alert Frames",       desc="Skins Blizzard alert toasts (Achievements, Loot Rolls) with GravityUI theme.",   stateTable=db.styling and db.styling.alerts, stateKey="enabled", pageId="Styling", tabIndex=10 })
    R({ name="Chat Bubbles",       desc="Styles 3D in-world chat bubbles with custom fonts and flat dark backgrounds.",    stateTable=db.styling and db.styling.chatBubbles, stateKey="enabled", pageId="Styling", tabIndex=11 })
    R({ name="Instance Frames",    desc="Skins the Dungeon Finder, LFG, and Premade Groups panel.",                        stateTable=db.styling and db.styling.instanceFrames, stateKey="enabled", pageId="Styling", tabIndex=12 })
    R({ name="XP & Reputation",    desc="Moveable tracking bars for XP and reputation. Morphs automatically at max level.", stateTable=db.styling and db.styling.xpRep, stateKey="enabled", pageId="Styling", tabIndex=13 })
    R({ name="Static Popups",      desc="Skins Blizzard dialog popups (Group Invite, Duel, Resurrect) with dark theme.",   stateTable=db.styling and db.styling.staticPopups, stateKey="enabled", pageId="Styling", tabIndex=14 })
    G()
    H("  Profiles")
    R({ name="Manage Profiles", desc="Create, delete, and copy persistent addon profiles centrally.",                  pageId="profiles", tabIndex=1 })
    R({ name="Import / Export", desc="Share and backup profiles via export hash strings.",                             pageId="profiles", tabIndex=2 })
    R({ name="Gravity Strings", desc="Import pre-configured WeakAuras and addon profile strings.",                    pageId="profiles", tabIndex=3 })
    R({ name="Installer",       desc="Relaunch the first-time setup and addon dependency installers.",                 pageId="profiles", tabIndex=4 })
    G()

    hubFrame:SetHeight(math.abs(hy) + 4)
    y = y + hy - 20
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
        for _, cf in pairs(opts.subTabsContainer.tabContents) do cf:Hide() end
        if opts.subTabsContainer.tabContents[subIndex] then
            opts.subTabsContainer.tabContents[subIndex]:Show()
        end
    end,
})