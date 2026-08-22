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

    -- BANNER -------------------------------------------------------
    local BANNER_H = 90
    local bannerW = GUI.CONTENT_WIDTH - 45
    local banner = CreateFrame("Frame", nil, content, "BackdropTemplate")
    banner:SetSize(bannerW, BANNER_H)
    banner:SetPoint("TOPLEFT", PAD, y)
    GUI:CreateBackdrop(banner, {0.06, 0.06, 0.08, 1}, {C.accent[1]*0.4, C.accent[2]*0.4, C.accent[3]*0.4, 0.6})

    -- Logo image (right-aligned, cropped to banner height)
    local logo = banner:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\GravityUI\\assets\\Gravity_UI_Logo.jpg")
    logo:SetSize(BANNER_H, BANNER_H)
    logo:SetPoint("RIGHT", banner, "RIGHT", -8, 0)
    logo:SetAlpha(0.35)

    -- Dark gradient overlay left-to-right over the logo area
    local grad = banner:CreateTexture(nil, "ARTWORK", nil, 1)
    grad:SetTexture("Interface\\Buttons\\WHITE8x8")
    grad:SetSize(BANNER_H + 40, BANNER_H)
    grad:SetPoint("LEFT", logo, "LEFT", -40, 0)
    grad:SetGradient("HORIZONTAL", CreateColor(0.06, 0.06, 0.08, 1), CreateColor(0.06, 0.06, 0.08, 0))

    -- Accent bar left edge
    local accentBar = banner:CreateTexture(nil, "OVERLAY")
    accentBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    accentBar:SetSize(3, BANNER_H)
    accentBar:SetPoint("LEFT", 0, 0)
    accentBar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)

    -- Title (uses dynamic theme accent)
    local accentHex = string.format("%02X%02X%02X", C.accent[1]*255, C.accent[2]*255, C.accent[3]*255)
    local titleFS = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    GUI:SetFont(titleFS, 22, "")
    titleFS:SetPoint("TOPLEFT", 16, -14)
    titleFS:SetText("|cFF" .. accentHex .. "Gravity|r|cFFFFFFFFUI|r")

    -- Version
    local versionTag = ns.VERSION
    local versionFS = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI:SetFont(versionFS, 11, "")
    versionFS:SetPoint("LEFT", titleFS, "RIGHT", 8, -2)
    versionFS:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 0.9)
    versionFS:SetText(versionTag)

    -- Subtitle
    local subFS = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(subFS, 11, "")
    subFS:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 0, -4)
    subFS:SetTextColor(0.7, 0.7, 0.7, 1)
    subFS:SetText("A complete UI overhaul for World of Warcraft")




    y = y - BANNER_H - 16

    -- SECTION 1: LATEST CHANGELOG (newest entry only) ----------
    local changelogHeader = GUI:CreateSectionHeader(content, "Latest Changelog")
    changelogHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - changelogHeader.gap - 10

    local changeLogs = {
        {
            version = "4.00.99",
            date = "08/22/2026",
            changes = {
                "Actionbars taint error fix on mythic plus start, Objective Tracker optimization on hide",
                "Settings Panel Restructure: Dissolved Utilities page — Sound Alerts, Color Picker, and Premade Group moved to Features; Tracked Bars moved to Indicators",
                "Death Announcer relocated from Features to Indicators for logical grouping with on-screen alert modules",
                "Information page merged into Main as first tab — sidebar entry removed for cleaner navigation",
                "Button Bar Overhaul: Added GUI Edit Mode quick-launch button, EllesmereUI config opener with logo; removed Boss Mods, Nameplates, CDM, Unitframes, and Party/Raid buttons",
                "Ready Check: Added 'Use Blizzard Default Position' toggle — when enabled, hides mover from Edit Mode and uses default centered position",
                "Cooldown Text Expansion: 3 display modes (Text, Icon, Bar), sound alerts, Time Spiral flash for proc resets, per-class mobility spell presets for 13 classes",
                "Feature Hub: Complete audit of all tab indices and page references after restructure — fixed duplicate entries, corrected Difficulty/AFK Screen indices",
                "Performance Audit: Verified zero combat impact across Action Bars (20Hz fade with dirty-checks), Minimap (1Hz master ticker), Icon Catcher (self-disarming startup scan), and all Utility modules",
            },
        },
        {
            version = "4.01.00",
            date = "08/17/2026",
            changes = {
                "Quality of Life Overhaul: Added new QoL suite (Auto Open Containers with Warband exclusions, Hide Item Transforms, Auto Unwrap Collections, Train All Button, and Announce Instance Reset)",
                "Trackers: Added new Battle Res and Bloodlust Lockout HUD trackers with custom timers, font colors, and Edit Mode integration",
                "Frame Mover: Built-in BlizzMove / Shifter module to freely drag, reposition, and persist all standard Blizzard panels",
                "Privacy: Added clickable Guild Chat Privacy Cover in Communities window for streamers",
                "EllesmereUI Compatibility: Full decoupling, standalone Minimap icon capture, and secret Shift+Click module activation bypass",
            },
        },
        {
            version = "4.00.56",
            date = "08/17/2026",
            changes = {
                "Edit Mode Overhaul: Full visual previews for Interrupt Tracker, Healer Mana, Ready Check, Alerts, Toasts, and XP/Reputation bars",
                "Edit Mode HUD: Added manual X and Y coordinate input boxes for real-time pixel-perfect positioning and direct value entry",
                "Edit Mode Decoupling: GravityUI Edit Mode now independent from Blizzard Edit Mode, accessible via dedicated button or /guiedit",
                "Blizzard Edit Mode: Objective Tracker frame auto-shows and remains selectable without conflict",
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
    R({ name="Combat Elements", desc="Hide Blizzard Talking Head, Boss Banners, and Alert popups during combat.",          pageId="main", tabIndex=6 })
    R({ name="Buffs & Debuffs", desc="Configure default Blizzard buff and debuff frame visibility and styles.",            pageId="main", tabIndex=7 })
    R({ name="Edit Mode",       desc="Enable custom frame movers to freely reposition all registered frames.",             pageId="main", tabIndex=8 })
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
    R({ name="QoL Suite",        desc="Auto Open Containers, Hide Transforms, Auto Unwrap Collections, Train All, Instance Reset.", pageId="qol", tabIndex=1 })
    R({ name="Automation",       desc="Auto-repair, fast loot, junk selling, quest accept/turn-in, and cinematic skips.",          pageId="qol", tabIndex=2 })
    R({ name="Autohide Setup",   desc="Contextual UI hiding for Objective Tracker, Frames, Nameplates, and Guild Chat Privacy.",   pageId="qol", tabIndex=3 })
    G()
    H("  Features")
    R({ name="Skyriding HUD",     desc="Smooth animated Vigor tracking HUD with unified centered layout.",             stateTable=db.skyriding, stateKey="enabled", pageId="features", tabIndex=1 })
    R({ name="M+ Teleports",      desc="Clickable dungeon portals embedded in the Mythic+ LFG UI.",                   stateTable=db.uiimprovements, stateKey="mplusTeleportEnabled", pageId="features", tabIndex=2 })
    R({ name="World Marks",       desc="World markers, flares, quick access to ready checks and pull timers.",          stateTable=db.uiimprovements and db.uiimprovements.marks, stateKey="enabled", pageId="features", tabIndex=3 })
    R({ name="Mail Extras",       desc="Open All button, address book for alts, and gold loot messages.",               stateTable=db.uiimprovements and db.uiimprovements.mail, stateKey="enabled", pageId="features", tabIndex=4 })
    R({ name="Group & Guild",     desc="Guild invite tool and automatic role promotion for assistants.",                 pageId="features", tabIndex=5 })
    R({ name="Interrupt Tracker", desc="Tracks interrupt cooldowns of party members in M+ dungeons.",                   stateTable=db.screenindicators and db.screenindicators.interruptTracker, stateKey="enabled", pageId="features", tabIndex=6 })
    R({ name="Alt Manager",       desc="Account-wide matrix for Mythic+ Keystones, Great Vault status, and Currencies.", stateTable=db.altManager, stateKey="enabled", pageId="features", tabIndex=7 })
    R({ name="Frame Mover",       desc="Freely drag and reposition all standard Blizzard frames (Character, Bank, Merchant, etc.).", stateTable=db.frameMover, stateKey="enabled", pageId="features", tabIndex=8 })
    R({ name="Sound Alerts",      desc="Integrate custom SharedMedia sounds into Blizzard's CooldownViewer.",           stateTable=db.soundAlerts, stateKey="enabled", pageId="features", tabIndex=9 })
    R({ name="Color Picker",      desc="Full HSV color picker with saved slots, class colors, hex input, and live preview.", stateTable=db.colorPicker, stateKey="enabled", pageId="features", tabIndex=10 })
    R({ name="Premade Group",     desc="Group Finder and GroupFinderIO enhancements with role filters and auto-accept.",     stateTable=db.premadeGroup, stateKey="enabled", pageId="features", tabIndex=11 })
    G()
    H("  Indicators")
    R({ name="Cursor Utilities",   desc="Attach GCD rings, cursor castbars and highlights to your mouse cursor.",       stateTable=db.screenindicators and db.screenindicators.cursor, stateKey="enabled", pageId="indicators", tabIndex=1 })
    R({ name="Crosshair",          desc="Dynamic class-specific targeting crosshair with real-time range color coding.",  stateTable=db.screenindicators and db.screenindicators.crosshair, stateKey="enabled", pageId="indicators", tabIndex=2 })
    R({ name="Stance Text",        desc="On-screen text indicator for Druid forms, Warrior stances, Paladin auras, etc.", stateTable=db.screenindicators and db.screenindicators.stanceText, stateKey="enabled", pageId="indicators", tabIndex=3 })
    R({ name="Healer Mana",        desc="Shows spec icon, name and mana% of all healers in your party or raid.",          stateTable=db.screenindicators and db.screenindicators.healerMana, stateKey="enabled", pageId="indicators", tabIndex=4 })
    R({ name="Battle Res Tracker", desc="Tracks party and raid battle resurrection pool charges and countdown timer.",    stateTable=db.screenindicators and db.screenindicators.battleRes, stateKey="enabled", pageId="indicators", tabIndex=4 })
    R({ name="Bloodlust Tracker",  desc="Displays remaining Sated / Exhaustion debuff lockout duration on screen.",      stateTable=db.screenindicators and db.screenindicators.bloodlust, stateKey="enabled", pageId="indicators", tabIndex=4 })
    R({ name="Pet Info",           desc="Pet management tools and large status warnings for Hunters and Warlocks.",       stateTable=db.screenindicators and db.screenindicators.petWarnings, stateKey="enabled", pageId="indicators", tabIndex=5 })
    R({ name="Combat Status",      desc="On-screen text notification (+Combat / -Combat) when entering and leaving combat.", stateTable=db.screenindicators and db.screenindicators.combatStatus, stateKey="enabled", pageId="indicators", tabIndex=6 })
    R({ name="Combat Timer",       desc="Visual stopwatch tracking time spent in combat. Great for M+ and raid analysis.", stateTable=db.uiimprovements and db.uiimprovements.combatTimer, stateKey="enabled", pageId="indicators", tabIndex=7 })
    R({ name="Cooldown Text",      desc="Movement cooldown tracker with preset spell lists, sound alerts, and display modes.", stateTable=db.cooldownText, stateKey="enabled", pageId="indicators", tabIndex=8 })
    R({ name="Raid Warnings",      desc="Large centralized alerts for Soulwells, Feasts, Mage Tables, and Rituals.",      stateTable=db.raidWarnings, stateKey="enabled", pageId="indicators", tabIndex=9 })
    R({ name="Consumables",        desc="Shows missing consumables for group members during a Ready Check.",               stateTable=db.screenindicators and db.screenindicators.consumables, stateKey="enabled", pageId="indicators", tabIndex=10 })
    R({ name="Difficulty",         desc="Status bar showing current instance difficulty with a quick-change dropdown.",    stateTable=db.screenindicators and db.screenindicators.difficulty, stateKey="enabled", pageId="indicators", tabIndex=11 })
    R({ name="AFK Screen",         desc="Immersive character orbit when AFK. Displays real time, guild, and rank.",        stateTable=db.screenindicators and db.screenindicators.afkScreen, stateKey="enabled", pageId="indicators", tabIndex=12 })
    R({ name="Death Announcer",    desc="Broadcasts party and raid player deaths to chat and on-screen alerts.",          stateTable=db.deathAnnouncer, stateKey="enabled", pageId="indicators", tabIndex=13 })
    R({ name="Tracked Bars",       desc="Configurable progress bars tracking spells, items or timers with custom thresholds.",  stateTable=db.actionbars and db.actionbars.cdmBuffbar, stateKey="enabled", pageId="indicators", tabIndex=14 })
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

    -- Collect all toggleable module references for bulk operations
    local toggleableModules = {}
    local function CollectToggleable(f)
        if f.stateTable and f.stateKey then
            table.insert(toggleableModules, f)
        end
    end

    -- Re-collect (we already created the rows, so just rebuild the list from the same data)
    -- Minimap
    CollectToggleable({ stateTable=db.minimap, stateKey="enabled" })
    CollectToggleable({ stateTable=db.minimap and db.minimap.catcher, stateKey="enabled" })
    -- Action Bars
    CollectToggleable({ stateTable=db.actionbars, stateKey="enabled" })
    CollectToggleable({ stateTable=db.actionbars and db.actionbars.fade, stateKey="enabled" })
    -- Datapanels
    CollectToggleable({ stateTable=db.minimap and db.minimap.datatext, stateKey="enabled" })
    -- Features
    CollectToggleable({ stateTable=db.skyriding, stateKey="enabled" })
    CollectToggleable({ stateTable=db.uiimprovements, stateKey="mplusTeleportEnabled" })
    CollectToggleable({ stateTable=db.uiimprovements and db.uiimprovements.marks, stateKey="enabled" })
    CollectToggleable({ stateTable=db.uiimprovements and db.uiimprovements.mail, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.interruptTracker, stateKey="enabled" })
    CollectToggleable({ stateTable=db.altManager, stateKey="enabled" })
    CollectToggleable({ stateTable=db.frameMover, stateKey="enabled" })
    CollectToggleable({ stateTable=db.soundAlerts, stateKey="enabled" })
    CollectToggleable({ stateTable=db.colorPicker, stateKey="enabled" })
    CollectToggleable({ stateTable=db.premadeGroup, stateKey="enabled" })
    -- Indicators
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.cursor, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.crosshair, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.stanceText, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.healerMana, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.battleRes, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.bloodlust, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.petWarnings, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.combatStatus, stateKey="enabled" })
    CollectToggleable({ stateTable=db.uiimprovements and db.uiimprovements.combatTimer, stateKey="enabled" })
    CollectToggleable({ stateTable=db.cooldownText, stateKey="enabled" })
    CollectToggleable({ stateTable=db.raidWarnings, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.consumables, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.difficulty, stateKey="enabled" })
    CollectToggleable({ stateTable=db.screenindicators and db.screenindicators.afkScreen, stateKey="enabled" })
    CollectToggleable({ stateTable=db.deathAnnouncer, stateKey="enabled" })
    CollectToggleable({ stateTable=db.actionbars and db.actionbars.cdmBuffbar, stateKey="enabled" })
    -- Styling
    CollectToggleable({ stateTable=db.uiimprovements and db.uiimprovements.character, stateKey="enabled" })
    CollectToggleable({ stateTable=db.uiimprovements and db.uiimprovements.chat, stateKey="enabled" })
    CollectToggleable({ stateTable=db.uiimprovements and db.uiimprovements.tooltip, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling and db.styling.objectives, stateKey="objectiveTrackerSkinning" })
    CollectToggleable({ stateTable=db.styling and db.styling.loot, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling and db.styling.gamemenu, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling, stateKey="skinReadyCheck" })
    CollectToggleable({ stateTable=db.styling and db.styling.keystone, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling and db.styling.powerBar, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling and db.styling.alerts, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling and db.styling.chatBubbles, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling and db.styling.instanceFrames, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling and db.styling.xpRep, stateKey="enabled" })
    CollectToggleable({ stateTable=db.styling and db.styling.staticPopups, stateKey="enabled" })

    -- Enable All / Disable All Buttons
    hy = hy - 6
    local btnEnableAll = GUI:CreateButton(hubFrame, "Enable All", 120, 26, function()
        for _, m in ipairs(toggleableModules) do
            if m.stateTable then m.stateTable[m.stateKey] = true end
        end
        print("|cff00BFFFGravityUI:|r All modules |cff00FF00enabled|r. Please |cff00FF00/reload|r to apply.")
        BuildInformationTab(parent)
    end)
    btnEnableAll:SetPoint("TOPLEFT", 0, hy)

    local btnDisableAll = GUI:CreateButton(hubFrame, "Disable All", 120, 26, function()
        for _, m in ipairs(toggleableModules) do
            if m.stateTable then m.stateTable[m.stateKey] = false end
        end
        print("|cff00BFFFGravityUI:|r All modules |cffFF5555disabled|r. Please |cff00FF00/reload|r to apply.")
        BuildInformationTab(parent)
    end)
    btnDisableAll:SetPoint("LEFT", btnEnableAll, "RIGHT", 10, 0)

    hy = hy - 32

    hubFrame:SetHeight(math.abs(hy) + 4)
    y = y + hy - 20
    content:SetHeight(math.abs(y) + 60)
end

-- ============================================================
-- INJECT INTO MAIN PAGE (replaces Welcome tab)
-- ============================================================
local mainPage = GUI.pages and GUI.pages["main"]
if mainPage and mainPage.subTabs and mainPage.subTabs[1] then
    mainPage.subTabs[1].builder = BuildInformationTab
end