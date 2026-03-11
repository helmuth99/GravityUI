-- GravityUI - Quality of Life Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- SHARED HELPERS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local ROW_HEIGHT = 30
local LABEL_WIDTH = 220
local WIDGET_WIDTH = 250

local function CreatePropertyRow(parent, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
    
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if ns.GUI.SetFont then
        ns.GUI:SetFont(label, 12, "")
    else
        label:SetFont(STANDARD_TEXT_FONT, 12, "")
    end
    label:SetJustifyH("LEFT")
    label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
    label:SetPoint("LEFT", 0, 0)
    label:SetText(labelText)
    label:SetTextColor(unpack(GUI.Colors.text))
    
    local widget
    if widgetType == "checkbox" then
        widget = GUI:CreateCheckbox(row, "", arg1, arg2, arg3)
        widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
    elseif widgetType == "slider" then
        widget = GUI:CreateSlider(row, "", arg1, arg2, arg3, arg4, arg5, arg6)
        widget:SetHeight(ROW_HEIGHT)
        widget:SetWidth(220) 
        widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
        widget.editBox:ClearAllPoints()
        widget.editBox:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
        widget.slider:ClearAllPoints()
        widget.slider:SetPoint("LEFT", widget, "LEFT", 0, 0)
        widget.slider:SetPoint("RIGHT", widget.editBox, "LEFT", -10, 0)
    elseif widgetType == "dropdown" then
        widget = GUI:CreateDropdown(row, "", arg1, arg2, arg3, arg4)
        widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
        widget:SetWidth(WIDGET_WIDTH)
        widget.dropdown:ClearAllPoints()
        widget.dropdown:SetPoint("LEFT", widget, "LEFT", 0, 0)
        widget.dropdown:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
    elseif widgetType == "color" then
         widget = GUI:CreateColorPicker(row, "", arg1, arg2, arg3)
         widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
    elseif widgetType == "input" then
         widget = GUI:CreateInput(row, "", arg1, arg2, arg3)
         widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
         widget:SetWidth(WIDGET_WIDTH)
         if widget.editBox then
             widget.editBox:ClearAllPoints()
             widget.editBox:SetPoint("LEFT", widget, "LEFT", 0, 0)
             widget.editBox:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
         end
    end
    
    if ns.GUI and ns.GUI.RegisterInSearchIndex then
        ns.GUI:RegisterInSearchIndex(labelText, row)
    end
    
    return row
end

local function AddRow(container, label, type, ...)
    local row = CreatePropertyRow(container, label, type, ...)
    local count = container.rowCount or 0
    row:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
    container.rowCount = count + 1
    return row
end

local function CreateSubHeader(parent, text)
     local row = parent.rowCount or 0
     local y = -10 - (row * (ROW_HEIGHT+5))
     
     local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
     label:SetPoint("TOPLEFT", 10, y)
     label:SetText(text)
     label:SetTextColor(unpack(C.accent))
     
     parent.rowCount = row + 1.0
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- BUILDERS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 1. Automation
local function BuildAutomation(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Automation")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    AddRow(content, "Auto Insert M+ Keys", "checkbox", "autoInsertKey", dbUI, nil)
    AddRow(content, "Auto Combat Log in M+", "checkbox", "autoCombatLog", dbUI, nil)
    AddRow(content, "Auto Log Raid (Normal)", "checkbox", "autoCombatLogRaidNormal", dbUI, nil)
    AddRow(content, "Auto Log Raid (Heroic)", "checkbox", "autoCombatLogRaidHeroic", dbUI, nil)
    AddRow(content, "Auto Log Raid (Mythic)", "checkbox", "autoCombatLogRaidMythic", dbUI, nil)
    AddRow(content, "Sell Gray Items", "checkbox", "sellJunk", dbUI, nil)
    
    local repairOptions = {{value="off", text="Off"}, {value="personal", text="Personal Gold"}, {value="guild", text="Guild Bank First"}}
    AddRow(content, "Auto Repair", "dropdown", repairOptions, "autoRepair", dbUI, nil)
    
    AddRow(content, "Auto Accept Role Check (Group)", "checkbox", "autoRoleAccept", dbUI, nil)
    AddRow(content, "LFG Queue on double click", "checkbox", "lfgQuickJoin", dbUI, nil)
    
    local inviteOptions = {{value="off", text="Off"}, {value="all", text="All Invites"}, {value="friends", text="Friends Only"}, {value="guild", text="Guild Only"}, {value="both", text="Friends & Guild"}}
    AddRow(content, "Auto Accept Invites", "dropdown", inviteOptions, "autoAcceptInvites", dbUI, nil)
    
    content.rowCount = content.rowCount + 0.2
    AddRow(content, "Invite on Whisper", "checkbox", "inviteOnWhisper", dbUI, nil)
    AddRow(content, "   - Invite All", "checkbox", "inviteOnWhisperAll", dbUI, nil)
    AddRow(content, "   - Only Friends / BNet", "checkbox", "inviteOnWhisperFriends", dbUI, nil)
    AddRow(content, "   - Only Guild Members", "checkbox", "inviteOnWhisperGuild", dbUI, nil)
    AddRow(content, "   - Keywords (comma separated)", "input", "inviteOnWhisperKeywords", dbUI, nil)
    
    content.rowCount = content.rowCount + 0.2
    local whisperInfo = GUI:CreateInfoBox(content, "Auto invite players who whisper a keyword. Filter Priority: Invite All > Friends/Guild.")
    whisperInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (whisperInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Auto Accept Quests", "checkbox", "autoAcceptQuest", dbUI, nil)
    AddRow(content, "Auto Turn-In Quests", "checkbox", "autoTurnInQuest", dbUI, nil)
    AddRow(content, "Shift Pauses Accept & Turn-In", "checkbox", "questHoldShift", dbUI, nil)
    
    content.rowCount = content.rowCount + 0.5
    local usefulHeader = GUI:CreateSectionHeader(content, "Useful Stuff")
    usefulHeader:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    usefulHeader:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = content.rowCount + 1.0
    
    AddRow(content, "Faster Auto Loot", "checkbox", "fastAutoLoot", dbUI, function(enabled) if enabled then SetCVar("autoLootDefault", "1") end end)
    content.rowCount = content.rowCount + 0.2
    local lootInfo = GUI:CreateInfoBox(content, "Faster Auto Loot instantly loots all items and enables WoW's Auto Loot setting.")
    lootInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (lootInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Delete Fix", "checkbox", "deleteFix", dbUI, function(enabled) if ns.ToggleDeleteFix then ns.ToggleDeleteFix(enabled) end end)
    content.rowCount = content.rowCount + 0.2
    local delInfo = GUI:CreateInfoBox(content, "Allows destroying Good/Superior items without typing DELETE.")
    delInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (delInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Death Release Protection", "checkbox", "deathReleaseProtection", dbUI, nil)
    content.rowCount = content.rowCount + 0.2
    local deathInfo = GUI:CreateInfoBox(content, "Forces you to hold ALT for 1 second before 'Release Spirit' can be clicked.")
    deathInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (deathInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Faster Movie Skip", "checkbox", "fasterMovieSkip", dbUI, nil)
    content.rowCount = content.rowCount + 0.2
    local movieInfo = GUI:CreateInfoBox(content, "Use ESC, SPACE, or ENTER to skip cancel Cinematic/Movie dialogs instantly.")
    movieInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (movieInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Auto-Select Single Gossip Option", "checkbox", "autoSelectGossip", dbUI, nil)
    AddRow(content, "Auto Check EditMode on Spec Switch", "checkbox", "checkEditmodeOnSpecSwitch", dbUI, nil)
    AddRow(content, "AH: Filter Current Expansion", "checkbox", "ahCurrentExpansionFilter", dbUI, nil)
    content.rowCount = content.rowCount + 0.2
    local ahInfo = GUI:CreateInfoBox(content, "Automatically sets the filter to the current expansion when opening the auction house.")
    ahInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (ahInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Show Widget Power Value (Prey)", "checkbox", "showWidgetPowerValue", dbUI, function(enabled) if ns.UpdateWidgetPowerValueVisibility then ns.UpdateWidgetPowerValueVisibility(enabled) end end)

    
    -- Quick Salvage moved here? Original logic was inside Automation section. Yes.
    content.rowCount = content.rowCount + 0.5
    AddRow(content, "Enable Quick Salvage", "checkbox", "enabled", dbUI.quickSalvage, nil)
    local modOptions = {{value="ALT", text="Alt"}, {value="ALTSHIFT", text="Alt + Shift"}, {value="ALTCTRL", text="Alt + Ctrl"}}
    AddRow(content, "Quick Salvage Modifier", "dropdown", modOptions, "modifier", dbUI.quickSalvage, nil)
    content.rowCount = content.rowCount + 0.2
    local qsInfo = GUI:CreateInfoBox(content, "Hold the modifier and hover over items in your bags to Mill, Prospect, or Disenchant instantly.")
    qsInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (qsInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 2. Autohide
local function BuildAutohide(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0
    
    local function RefreshAutohide() if ns.ApplyAutohideSettings then ns.ApplyAutohideSettings() end end
    
    local header = GUI:CreateSectionHeader(content, "Autohide")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    -- Ensure subtable
    if not dbUI.hideObjectiveTrackerInstanceTypes then
        dbUI.hideObjectiveTrackerInstanceTypes = {mythicPlus=false, mythicDungeon=false, normalDungeon=false, heroicDungeon=false, followerDungeon=false, raid=false, pvp=false, arena=false}
    end

    CreateSubHeader(content, "Objective Tracker")
    AddRow(content, "Hide Always", "checkbox", "hideObjectiveTrackerAlways", dbUI, RefreshAutohide)

    local instanceTypes = {
        {key="mythicPlus", label="Hide in Mythic+"}, {key="mythicDungeon", label="Hide in Mythic Dungeons"},
        {key="heroicDungeon", label="Hide in Heroic Dungeons"}, {key="normalDungeon", label="Hide in Normal Dungeons"},
        {key="followerDungeon", label="Hide in Follower Dungeons"}, {key="raid", label="Hide in Raids"},
        {key="pvp", label="Hide in Battlegrounds"}, {key="arena", label="Hide in Arenas"},
    }
    for _, it in ipairs(instanceTypes) do
        AddRow(content, "   - " .. it.label, "checkbox", it.key, dbUI.hideObjectiveTrackerInstanceTypes, RefreshAutohide)
    end
    content.rowCount = content.rowCount + 0.5 

    CreateSubHeader(content, "Frames & Buttons")
    AddRow(content, "Hide Compact Raid Frame Manager", "checkbox", "hideRaidFrameManager", dbUI, RefreshAutohide)
    AddRow(content, "Hide Buff Frame Collapse Button", "checkbox", "hideBuffCollapseButton", dbUI, RefreshAutohide)
    AddRow(content, "Hide Talking Head Frame", "checkbox", "hideTalkingHead", dbUI, RefreshAutohide)
    AddRow(content, "Mute Talking Head Voice", "checkbox", "muteTalkingHead", dbUI, RefreshAutohide)
    AddRow(content, "Hide World Map Blackout", "checkbox", "hideWorldMapBlackout", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Nameplates")
    AddRow(content, "Hide Friendly Player Nameplates", "checkbox", "hideFriendlyPlayerNameplates", dbUI, RefreshAutohide)
    AddRow(content, "Hide Friendly NPC Nameplates", "checkbox", "hideFriendlyNPCNameplates", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5



    CreateSubHeader(content, "Combat & Messages")
    AddRow(content, "Hide Error Messages (Red Text)", "checkbox", "hideErrorMessages", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "World Quest Minigames/Petbattles")
    AddRow(content, "Hide Interface on Minigame/Petbattle", "checkbox", "hideOnWorldQuestMinigame", dbUI, RefreshAutohide)
    content.rowCount = content.rowCount + 0.5

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 3. Combat
local function BuildCombat(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Combat")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    AddRow(content, "Show Damage Numbers", "checkbox", "showDamageNumbers", dbUI, function(enabled) SetCVar("floatingCombatTextCombatDamage", enabled and "1" or "0") end)
    AddRow(content, "Show Healing Numbers", "checkbox", "showHealingNumbers", dbUI, function(enabled) SetCVar("floatingCombatTextCombatHealing", enabled and "1" or "0") end)
    
    if dbUI.spellQueueWindow == nil then dbUI.spellQueueWindow = tonumber(GetCVar("SpellQueueWindow")) or 400 end
    AddRow(content, "Spell Queue Window (ms)", "slider", 0, 400, "spellQueueWindow", dbUI, function(val) SetCVar("SpellQueueWindow", tostring(val)) end, 10)
    
    -- Combat Text Font Removed
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 4. Buffs & Debuffs
local function BuildBuffs(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "World of Warcraft Buffs & Debuffs Settings")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    local buffInfo = GUI:CreateInfoBox(content, "Modifies borders and font size of Blizzard default Buff and Debuff frames.")
    buffInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (buffInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2

    if not dbUI.buffBorders then dbUI.buffBorders = {} end
    local dbBuffs = dbUI.buffBorders
    local function RefreshBuffs() if ns.BuffBorders and ns.BuffBorders.Refresh then ns.BuffBorders.Refresh() end end

    -- BORDERS
    AddRow(content, "Enable Buff Borders", "checkbox", "enableBuffs", dbBuffs, RefreshBuffs)
    AddRow(content, "Enable Debuff Borders", "checkbox", "enableDebuffs", dbBuffs, RefreshBuffs)
    AddRow(content, "Border Size", "slider", 0, 5, "borderSize", dbBuffs, RefreshBuffs, 0.5)
    
    content.rowCount = content.rowCount + 0.5
    AddRow(content, "Enable Styling", "checkbox", "enableStyling", dbBuffs, RefreshBuffs)
    
    content.rowCount = content.rowCount + 0.5
    CreateSubHeader(content, "Effects")
    AddRow(content, "Disable Blinking", "checkbox", "noBlink", dbBuffs, RefreshBuffs)
    
    content.rowCount = content.rowCount + 0.5
    CreateSubHeader(content, "Font Settings")
    
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local fontOptions = {}
    if LSM then
        local fontList = LSM:List("font")
        if fontList then
            for _, name in ipairs(fontList) do
                table.insert(fontOptions, { text = name, value = name })
            end
        end
    end
    -- Fallback/Default font
    if #fontOptions == 0 then
        table.insert(fontOptions, { text = "System", value = "Fonts\\FRIZQT__.TTF" })
        table.insert(fontOptions, { text = "Gravity", value = "Gravity" })
    end
    
    local outlineOptions = {
        { text = "None", value = "NONE" },
        { text = "Outline", value = "OUTLINE" },
        { text = "Thick Outline", value = "THICKOUTLINE" },
        { text = "Monochrome", value = "MONOCHROME" },
    }
    
    AddRow(content, "Font", "dropdown", fontOptions, "font", dbBuffs, RefreshBuffs)
    AddRow(content, "Duration Font Size", "slider", 8, 24, "fontSize", dbBuffs, RefreshBuffs, 1)
    AddRow(content, "Count Font Size", "slider", 8, 24, "countFontSize", dbBuffs, RefreshBuffs, 1)
    AddRow(content, "Font Outline", "dropdown", outlineOptions, "fontOutline", dbBuffs, RefreshBuffs)
    AddRow(content, "Duration Color", "color", "fontColor", dbBuffs, RefreshBuffs)
    AddRow(content, "Count Color", "color", "countColor", dbBuffs, RefreshBuffs)
    
    content.rowCount = content.rowCount + 0.5
    CreateSubHeader(content, "Blizzard Frames")
    AddRow(content, "Hide Blizzard Buff Frame", "checkbox", "hideBuffFrame", dbBuffs, RefreshBuffs)
    AddRow(content, "Hide Blizzard Debuff Frame", "checkbox", "hideDebuffFrame", dbBuffs, RefreshBuffs)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end


-- 8. Dragonriding (Skyriding)
local function BuildDragonriding(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    
    local function RefreshSkyriding() if ns.RefreshSkyriding then ns.RefreshSkyriding() end end
    
    local dbSky = db.skyriding
    if not dbSky then dbSky = {}; db.skyriding = dbSky end
    -- Initializer defaults (simplified for brevity, main logic in skyriding.lua)
    if dbSky.enabled == nil then dbSky.enabled = true end

    local header = GUI:CreateSectionHeader(content, "Dragonriding")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    CreateSubHeader(content, "Enable")
    local infoBox = GUI:CreateInfoBox(content, "Displays vigor charges, recharge progress, and speed while skyriding.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Vigor Bar", "checkbox", "enabled", dbSky, RefreshSkyriding)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Visibility")
    local visOptions = {{value="ALWAYS", text="Always Visible"}, {value="FLYING_ONLY", text="Only When Flying"}, {value="AUTO", text="Auto (fade)"}}
    AddRow(content, "Visibility Mode", "dropdown", visOptions, "visibility", dbSky, RefreshSkyriding)
    AddRow(content, "Fade Delay (sec)", "slider", 0, 10, "fadeDelay", dbSky, RefreshSkyriding, 0.5)
    AddRow(content, "Fade Speed (sec)", "slider", 0.1, 1.0, "fadeDuration", dbSky, RefreshSkyriding, 0.1)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Bar Size")
    AddRow(content, "Width", "slider", 100, 500, "width", dbSky, RefreshSkyriding, 1)
    AddRow(content, "Vigor Height", "slider", 4, 30, "vigorHeight", dbSky, RefreshSkyriding, 1)
    AddRow(content, "Second Wind Height", "slider", 2, 20, "secondWindHeight", dbSky, RefreshSkyriding, 1)
    
    local textureOptions = {{value="Solid", text="Solid"}, {value="Interface/AddOns/GravityUI/assets/textures/Flat.tga", text="Flat"}}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then 
        textureOptions = {}
        for name, _ in pairs(LSM:HashTable("statusbar")) do table.insert(textureOptions, {value=name, text=name}) end
        table.sort(textureOptions, function(a,b) return a.text < b.text end)
    end
    AddRow(content, "Bar Texture", "dropdown", textureOptions, "barTexture", dbSky, RefreshSkyriding)
    
    local swModeOptions = {{value="PIPS", text="Pips"}, {value="MINIBAR", text="Minibar"}, {value="TEXT", text="Text"}, {value="HIDDEN", text="Disabled"}}
    AddRow(content, "Second Wind Mode", "dropdown", swModeOptions, "secondWindMode", dbSky, RefreshSkyriding)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Position")
    AddRow(content, "Lock Position", "checkbox", "locked", dbSky, RefreshSkyriding)
    AddRow(content, "X Offset", "slider", -1000, 1000, "offsetX", dbSky, RefreshSkyriding, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "offsetY", dbSky, RefreshSkyriding, 1)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Colors & Style")
    AddRow(content, "Use Theme Color for Vigor", "checkbox", "useThemeColorVigor", dbSky, RefreshSkyriding)
    AddRow(content, "Vigor Fill Color", "color", "barColor", dbSky, RefreshSkyriding)
    AddRow(content, "Use Theme Color for Second Wind", "checkbox", "useThemeColorSecondWind", dbSky, RefreshSkyriding)
    AddRow(content, "Second Wind Color", "color", "secondWindColor", dbSky, RefreshSkyriding)
    AddRow(content, "Background Color", "color", "backgroundColor", dbSky, RefreshSkyriding)
    content.rowCount = content.rowCount + 0.5

    CreateSubHeader(content, "Text Display")
    AddRow(content, "Show Vigor Count", "checkbox", "showVigorText", dbSky, RefreshSkyriding)
    local vigorFormatOptions = {{value="FRACTION", text="Fraction (4/6)"}, {value="CURRENT", text="Current (4)"}}
    AddRow(content, "Vigor Format", "dropdown", vigorFormatOptions, "vigorTextFormat", dbSky, RefreshSkyriding)
    AddRow(content, "Show Speed", "checkbox", "showSpeed", dbSky, RefreshSkyriding)
    local speedFormatOptions = {{value="PERCENT", text="Percentage"}, {value="RAW", text="Raw Speed"}}
    AddRow(content, "Speed Format", "dropdown", speedFormatOptions, "speedFormat", dbSky, RefreshSkyriding)
    AddRow(content, "Show Whirling Surge Icon", "checkbox", "showAbilityIcon", dbSky, RefreshSkyriding)
    AddRow(content, "Text Font Size", "slider", 8, 24, "vigorFontSize", dbSky, RefreshSkyriding, 1)

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 9. Combat Timer
local function BuildCombatTimer(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Combat Timer")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local function RefreshCT() if _G.GravityUI_RefreshCombatTimer then _G.GravityUI_RefreshCombatTimer() end end
    local dbCT = dbUI.combatTimer
    
    AddRow(content, "Enable Combat Timer", "checkbox", "enabled", dbCT, RefreshCT)
    AddRow(content, "Only show in Boss Encounters", "checkbox", "onlyEncounter", dbCT, RefreshCT)
    AddRow(content, "Width", "slider", 40, 300, "width", dbCT, RefreshCT, 1)
    AddRow(content, "Height", "slider", 10, 100, "height", dbCT, RefreshCT, 1)
    AddRow(content, "X Offset", "slider", -500, 500, "xOffset", dbCT, RefreshCT, 1)
    AddRow(content, "Y Offset", "slider", -500, 500, "yOffset", dbCT, RefreshCT, 1)
    
    local strataOptions = {{value="BACKGROUND", text="Background"}, {value="LOW", text="Low"}, {value="MEDIUM", text="Medium"}, {value="HIGH", text="High"}, {value="DIALOG", text="Dialog"}, {value="FULLSCREEN", text="Fullscreen"}, {value="TOOLTIP", text="Tooltip"}}
    AddRow(content, "Frame Strata", "dropdown", strataOptions, "strata", dbCT, RefreshCT)
    
    AddRow(content, "Font Size", "slider", 8, 48, "fontSize", dbCT, RefreshCT, 1)
    local alignOptions = {{value="LEFT", text="Left"}, {value="CENTER", text="Center"}, {value="RIGHT", text="Right"}}
    AddRow(content, "Text Alignment", "dropdown", alignOptions, "textAlign", dbCT, RefreshCT)
    AddRow(content, "Use Theme Color for Text", "checkbox", "useThemeColorText", dbCT, RefreshCT)
    AddRow(content, "Text Color", "color", "textColor", dbCT, RefreshCT)
    AddRow(content, "Show Backdrop", "checkbox", "showBackdrop", dbCT, RefreshCT)
    AddRow(content, "Backdrop Color", "color", "backdropColor", dbCT, RefreshCT)
    AddRow(content, "Hide Border", "checkbox", "hideBorder", dbCT, RefreshCT)
    AddRow(content, "Border Size", "slider", 0, 10, "borderSize", dbCT, RefreshCT, 1)
    AddRow(content, "Use Theme Color for Border", "checkbox", "useThemeColorBorder", dbCT, RefreshCT)
    AddRow(content, "Border Color", "color", "borderColor", dbCT, RefreshCT)

    local previewBtn = GUI:CreateButton(content, "Toggle Mover", 120, 26, function()
        if _G.GravityUI_ToggleCombatTimerPreview then
            local isPreview = _G.GravityUI_IsCombatTimerPreviewMode and _G.GravityUI_IsCombatTimerPreviewMode()
            _G.GravityUI_ToggleCombatTimerPreview(not isPreview)
        end
    end)
    previewBtn:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    content.rowCount = content.rowCount + 1.2

    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 10. M+ Teleport
local function BuildTeleport(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "M+ Teleport")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3

    local tpInfo = GUI:CreateInfoBox(content, "|cffFFCC00Note:|r Allows you to click dungeon icons in the Mythic+ Challenges frame to cast teleport spells.")
    tpInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (tpInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable M+ Teleports Overlay", "checkbox", "mplusTeleportEnabled", dbUI, function() if ns.MPlusTeleport and ns.MPlusTeleport.ApplySettings then ns.MPlusTeleport:ApplySettings() end end)
    
    local function RefreshTP() if ns.MPlusTeleport and ns.MPlusTeleport.ApplySettings then ns.MPlusTeleport:ApplySettings() end end

    content.rowCount = content.rowCount + 0.5
    CreateSubHeader(content, "Group Key List")
    AddRow(content, "Show Group Key List", "checkbox", "groupKeyListEnabled", dbUI, RefreshTP)
    AddRow(content, "Hide Background", "checkbox", "groupkeysHideBackground", dbUI, function()
        if ns.MPlusTeleport and ns.MPlusTeleport.ApplyGroupKeyAppearance then
            ns.MPlusTeleport:ApplyGroupKeyAppearance()
        end
    end)
    AddRow(content, "Hide Label Bar", "checkbox", "groupkeysHideTitleBar", dbUI, function()
        if ns.MPlusTeleport and ns.MPlusTeleport.ApplyGroupKeyAppearance then
            ns.MPlusTeleport:ApplyGroupKeyAppearance()
        end
    end)
    
    local btnGroupPreview = GUI:CreateButton(content, "Toggle Mover & Preview", 180, 26, function()
        if ns.MPlusTeleport and ns.MPlusTeleport.ToggleGroupKeyListPreview then
            ns.MPlusTeleport.groupKeyPreview = not ns.MPlusTeleport.groupKeyPreview
            ns.MPlusTeleport:ToggleGroupKeyListPreview(ns.MPlusTeleport.groupKeyPreview)
        end
    end)
    btnGroupPreview:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    content.rowCount = content.rowCount + 1.2

    content.rowCount = content.rowCount + 0.5
    CreateSubHeader(content, "Dungeon Library")
    AddRow(content, "Show Dungeon Library", "checkbox", "dungeonLibraryEnabled", dbUI, RefreshTP)
    
    if not dbUI.dungeonLibraryExpansions then dbUI.dungeonLibraryExpansions = {} end
    for _, exp in ipairs(ns.TeleportData.Expansions) do
        AddRow(content, "   - " .. exp.name, "checkbox", exp.name, dbUI.dungeonLibraryExpansions, function()
             if ns.MPlusTeleport and ns.MPlusTeleport.RefreshLibrary then ns.MPlusTeleport:RefreshLibrary("Dungeon") end
        end)
    end

    content.rowCount = content.rowCount + 0.5
    CreateSubHeader(content, "Raid Library")
    AddRow(content, "Show Raid Library", "checkbox", "raidLibraryEnabled", dbUI, RefreshTP)
    
    if not dbUI.raidLibraryExpansions then dbUI.raidLibraryExpansions = {} end
    local raidExp = { "The War Within", "Dragonflight", "Shadowlands" }
    for _, expName in ipairs(raidExp) do
        AddRow(content, "   - " .. expName, "checkbox", expName, dbUI.raidLibraryExpansions, function()
             if ns.MPlusTeleport and ns.MPlusTeleport.RefreshLibrary then ns.MPlusTeleport:RefreshLibrary("Raid") end
        end)
    end
    
    AddRow(content, "Library Window Scale", "slider", 0.5, 2.0, "libraryScale", dbUI, RefreshTP, 0.05)

    content.rowCount = content.rowCount + 1.2
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 11. World Marks
local function BuildWorldMarks(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "World Marks")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    local function RefreshMarks() if _G.GravityUI_RefreshWorldMarks then _G.GravityUI_RefreshWorldMarks() end end
    local dbMarks = dbUI.marks
    
    local infoBox = GUI:CreateInfoBox(content, "|cffFFCC00Note:|r Left-Click to set Raid Target. Shift-Click to set World Marker.\nPulltimer can be changed on the bar with Right-Click.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Marks Bar", "checkbox", "enabled", dbMarks, RefreshMarks)
    AddRow(content, "Enable Ready Check & Pull Bar", "checkbox", "showTimerBar", dbMarks, RefreshMarks)
    AddRow(content, "Show on Mouseover Only", "checkbox", "mouseover", dbMarks, RefreshMarks)
    AddRow(content, "Button Size", "slider", 10, 60, "size", dbMarks, RefreshMarks, 1)
    AddRow(content, "Spacing", "slider", 0, 20, "spacing", dbMarks, RefreshMarks, 1)
    AddRow(content, "X Offset", "slider", -1000, 1000, "offsetX", dbMarks, RefreshMarks, 1)
    AddRow(content, "Y Offset", "slider", -1000, 1000, "offsetY", dbMarks, RefreshMarks, 1)
    AddRow(content, "Hide Border", "checkbox", "hideBorder", dbMarks, RefreshMarks)
    AddRow(content, "Use Theme Color for Border", "checkbox", "useThemeColorBorder", dbMarks, RefreshMarks)
    AddRow(content, "Border Color", "color", "borderColor", dbMarks, RefreshMarks)
    
    local btnMover = GUI:CreateButton(content, "Toggle Mover", 120, 26, function()
        if ns.WorldMarks and ns.WorldMarks.ToggleMover then
            ns.WorldMarks:ToggleMover()
        end
    end)
    btnMover:SetPoint("TOPLEFT", 10, -10 - (content.rowCount * (ROW_HEIGHT+5)))
    content.rowCount = content.rowCount + 1.2
    

    content.rowCount = content.rowCount + 1.2
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- 12. Mail
local function BuildMailExtras(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    content.rowCount = 0

    local header = GUI:CreateSectionHeader(content, "Mail")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetPoint("RIGHT", content, "RIGHT", -10, 0)
    content.rowCount = 1.3
    
    local function RefreshMail() if ns.Mail and ns.Mail.ApplySettings then ns.Mail.ApplySettings() end end
    local dbMail = dbUI.mail
    if not dbMail then dbMail = {}; dbUI.mail = dbMail end
    
    local infoBox = GUI:CreateInfoBox(content, "Improves the Mailbox with an Open All button, Address Book with Alts/Friends/Guild/Contacts, and gold tracking.")
    infoBox:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (infoBox:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    AddRow(content, "Enable Mail Module", "checkbox", "enabled", dbMail, RefreshMail)
    AddRow(content, "Enable Open All Button", "checkbox", "openAll", dbMail, RefreshMail)
    AddRow(content, "Enable Address Book (Send Mail)", "checkbox", "addressBook", dbMail, RefreshMail)
    AddRow(content, "Track Gold in Chat", "checkbox", "trackGold", dbMail, RefreshMail)
    content.rowCount = content.rowCount + 0.5
    
    CreateSubHeader(content, "Contacts")
    
    -- We can add a simple button to print instructions
    local contactInfo = GUI:CreateInfoBox(content, "To manage contacts, open the Mailbox Send Mail tab, type a name in the 'To' field, click the Address Book dropdown and select 'Add Contact' or 'Remove Contact'.")
    contactInfo:SetPoint("TOPLEFT", 10, -content.rowCount * (ROW_HEIGHT+5))
    content.rowCount = content.rowCount + (contactInfo:GetHeight() / (ROW_HEIGHT+5)) + 0.2
    
    content:SetHeight(50 + (content.rowCount * (ROW_HEIGHT + 5)))
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- MAIN PAGE
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
ns.GUI:RegisterPage("uiimprovements", {
    title = "UI Improvements",
    subTabs = {
        { name = "Automation / Stuff", builder = BuildAutomation },
        { name = "Autohide", builder = BuildAutohide },
        { name = "Combat", builder = BuildCombat },
        { name = "Buffs & Debuffs", builder = BuildBuffs },
        { name = "Dragonriding", builder = BuildDragonriding },
        { name = "Combat Timer", builder = BuildCombatTimer },
        { name = "M+ Teleport", builder = BuildTeleport },
        { name = "World Marks", builder = BuildWorldMarks },
        { name = "Mail", builder = BuildMailExtras },
    },
    OnBuild = function(content)
        -- Hide default scrollframe parent
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        local opts = GUI.pages["uiimprovements"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["uiimprovements"]
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

