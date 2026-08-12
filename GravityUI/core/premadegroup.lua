-- GravityUI - Premade Group Helper
-- Integrates GroupKeys (by Kubi) Premade Group dropdown into GravityUI.
-- Key Broadcasting is handled separately by mplusteleport.lua.
local ADDON_NAME, ns = ...

local PremadeGroup = {}
ns.PremadeGroup = PremadeGroup

---------------------------------------------------------------------------
-- SEASON CONFIG  (Midnight Season 1 — update per season)
-- Maps English dungeon name → LFG Activity ID
---------------------------------------------------------------------------
local DUNGEON_TO_ACTIVITY_ID = {
    ["Algeth'ar Academy"]       = 1160,
    ["Magisters' Terrace"]      = 1760,
    ["Maisara Caverns"]         = 1764,
    ["Nexus-Point Xenas"]       = 1768,
    ["Pit of Saron"]            = 1770,
    ["Seat of the Triumvirate"] = 486,
    ["Skyreach"]                = 182,
    ["Windrunner Spire"]        = 1542,
}

---------------------------------------------------------------------------
-- LOCALIZATION  (locale display name → English name)
---------------------------------------------------------------------------
local DUNGEON_NAME_MAP = {}
local DUNGEON_DISPLAY_MAP = {}

local function BuildLocalizationMaps()
    local localeData = {
        ["deDE"] = {
            ["Akademie von Algeth'ar"]   = "Algeth'ar Academy",
            ["Terrasse der Magister"]    = "Magisters' Terrace",
            ["Maisarakavernen"]          = "Maisara Caverns",
            ["Nexuspunkt Xenas"]         = "Nexus-Point Xenas",
            ["Die Grube von Saron"]      = "Pit of Saron",
            ["Der Sitz des Triumvirats"] = "Seat of the Triumvirate",
            ["Die Himmelsnadel"]         = "Skyreach",
            ["Windläuferturm"]           = "Windrunner Spire",
        },
        ["esES"] = {
            ["Academia Algeth'ar"]       = "Algeth'ar Academy",
            ["Bancal del Magister"]      = "Magisters' Terrace",
            ["Cavernas Maisara"]         = "Maisara Caverns",
            ["Punto de Nexo Xenas"]      = "Nexus-Point Xenas",
            ["Foso de Saron"]            = "Pit of Saron",
            ["Sede del Triunvirato"]     = "Seat of the Triumvirate",
            ["Aguja de Skyreach"]        = "Skyreach",
            ["Aguja Brisaveloz"]         = "Windrunner Spire",
        },
        ["frFR"] = {
            ["Académie d'Algeth'ar"]     = "Algeth'ar Academy",
            ["Terrasse des Magistères"]  = "Magisters' Terrace",
            ["Cavernes de Maisara"]      = "Maisara Caverns",
            ["Point-nexus Xenas"]        = "Nexus-Point Xenas",
            ["Fosse de Saron"]           = "Pit of Saron",
            ["Siège du Triumvirat"]      = "Seat of the Triumvirate",
            ["Orée-du-Ciel"]             = "Skyreach",
            ["Flèche de Coursevent"]     = "Windrunner Spire",
        },
    }

    -- Populate flat DUNGEON_NAME_MAP (all locales → english)
    for _, localeMap in pairs(localeData) do
        for localName, englishName in pairs(localeMap) do
            DUNGEON_NAME_MAP[localName] = englishName
        end
    end

    -- Populate DUNGEON_DISPLAY_MAP for the current client locale (english → local)
    local clientLocale = GetLocale()
    if localeData[clientLocale] then
        for localName, englishName in pairs(localeData[clientLocale]) do
            DUNGEON_DISPLAY_MAP[englishName] = localName
        end
    end
end

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------
local function IsEnabled()
    local db = ns.GetDB()
    return db and db.uiimprovements and db.uiimprovements.premadeGroupEnabled ~= false
end

-- Playstyle value → display name mapping (matches Blizzard's LFG values)
local PLAYSTYLE_LABELS = {
    [0] = "Don't set",
    [1] = "Moderate",
    [2] = "Relaxed",
    [3] = "Hardcore",
}

local function GetPlaystyle()
    local db = ns.GetDB()
    local val = db and db.uiimprovements and db.uiimprovements.premadeGroupPlaystyle
    if val == nil then return 2 end -- default: Relaxed
    return val
end

local function GetFont()
    local db = ns.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local fontPath = LSM and LSM:Fetch("font", fontName)
    return fontPath or [[Interface\AddOns\GravityUI\media\font\Gravity.ttf]]
end

local function NormalizeDungeonName(name)
    return DUNGEON_NAME_MAP[name] or name
end

---------------------------------------------------------------------------
-- KEYSTONE DATA  (reads from mplusteleport.lua's shared groupKeys table)
---------------------------------------------------------------------------
local function GetAllGroupKeystones()
    local results = {}

    -- 1. Own keystone from bags
    local MPT = ns.MPlusTeleport
    if MPT and MPT.GetGroupKeys then
        local shared = MPT:GetGroupKeys()
        if shared then
            for playerName, kd in pairs(shared) do
                if kd and kd.mapID and kd.level then
                    local dungeonName = C_ChallengeMode.GetMapUIInfo(kd.mapID) or "Unknown"
                    -- Strip prefixes for cleaner display
                    dungeonName = dungeonName:gsub("Operation: ", ""):gsub("Tazavesh: ", "")
                    local text = dungeonName .. " +" .. kd.level
                    table.insert(results, {
                        text    = text,
                        value   = #results + 1,
                        player  = playerName,
                        mapID   = kd.mapID,
                        level   = kd.level,
                    })
                end
            end
        end
    end

    -- Sort: highest level first
    table.sort(results, function(a, b) return (a.level or 0) > (b.level or 0) end)
    return results
end

---------------------------------------------------------------------------
-- DROPDOWN STATE
---------------------------------------------------------------------------
local state = {
    selectedGroupKey = 0,
    pendingTitle     = nil,
    groupKeys        = {},
}

local dropdownButtonText = nil
local groupKeysDropdown  = nil
local dropdownButton     = nil
local copyPopup          = nil
local inFormDropdown     = nil  -- in-form key selector button (right panel)
local inFormButtonText   = nil  -- label FontString of the in-form button

-- Forward declarations (defined later, referenced by closures created earlier)
local GetOrCreateDropdownMenu
local InitializeDropdownMenu

local function UpdateBothButtonTexts(text)
    if dropdownButtonText then dropdownButtonText:SetText(text) end
    if inFormButtonText   then inFormButtonText:SetText(text)   end
end


---------------------------------------------------------------------------
-- LFG ENTRY CREATION HOOK
---------------------------------------------------------------------------
local function GetPendingTitleFromKeystone(keystone)
    -- keystone.text = "DungeonName +N"
    local dungeonName = keystone.text:match("^(.-)%s*%+")
    if not dungeonName then dungeonName = keystone.text end
    dungeonName = dungeonName:gsub("^%s+", ""):gsub("%s+$", "")
    dungeonName = NormalizeDungeonName(dungeonName)

    local activityID = DUNGEON_TO_ACTIVITY_ID[dungeonName]
    if not activityID then return nil end

    local level = keystone.text:match("%+(%d+)")
    return (level and ("+" .. level)), activityID, dungeonName
end

local function ApplyActivityToFrame(creationFrame, activityID, dungeonName)
    creationFrame.selectedActivity = activityID
    if creationFrame.UpdateActivityDependentViews then
        pcall(function() creationFrame:UpdateActivityDependentViews() end)
    end
    C_Timer.After(0, function()
        -- Apply the playstyle selected in GravityUI settings
        local playstyleValue = GetPlaystyle()
        local playstyleDropdown = LFGListEntryCreationPlayStyleDropdown
        if playstyleDropdown and playstyleValue > 0 then
            creationFrame.generalPlaystyle = playstyleValue
            pcall(function() UIDropDownMenu_SetSelectedValue(playstyleDropdown, playstyleValue) end)
            pcall(function() playstyleDropdown:OverrideText(PLAYSTYLE_LABELS[playstyleValue] or "Relaxed") end)
        end

        -- Set the dungeon dropdown text
        if creationFrame.GroupDropdown then
            local displayName = DUNGEON_DISPLAY_MAP[dungeonName] or dungeonName
            pcall(function() creationFrame.GroupDropdown:OverrideText(displayName) end)
        end
    end)
end

local function CreateCopyPopup(entryCreationFrame)
    if copyPopup then return copyPopup end

    local popup = CreateFrame("Frame", "GravityUI_PremadeGroupCopyPopup", UIParent, "BackdropTemplate")
    popup:SetSize(290, 58)
    popup:SetFrameStrata("DIALOG")

    local r, g, b = 0.11, 0.12, 0.13
    if ns.GetThemeBgColor then r, g, b = ns.GetThemeBgColor() end
    popup:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    popup:SetBackdropColor(r, g, b, 0.95)
    popup:Hide()

    local label = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", popup, "TOP", 0, -9)
    label:SetFont(GetFont(), 11, "OUTLINE")
    label:SetText("|cffFFCC00Ctrl+C|r to copy the new title, then close")
    label:SetTextColor(0.9, 0.9, 0.9, 1)

    local editBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    editBox:SetSize(248, 24)
    editBox:SetPoint("BOTTOM", popup, "BOTTOM", 0, 9)
    editBox:SetAutoFocus(false)
    editBox:SetPropagateKeyboardInput(false)
    editBox:SetScript("OnEscapePressed", function() popup:Hide() end)
    editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    editBox:SetScript("OnKeyDown", function(self, key)
        if key == "C" and IsControlKeyDown() then
            C_Timer.After(0, function()
                popup:Hide()
                if entryCreationFrame and entryCreationFrame.Name then
                    entryCreationFrame.Name:SetFocus()
                    entryCreationFrame.Name:HighlightText()
                end
            end)
        end
    end)

    popup.editBox = editBox
    popup:SetScript("OnShow", function(p)
        p.editBox:SetText(state.pendingTitle or "")
        C_Timer.After(0, function()
            p.editBox:SetFocus()
            p.editBox:HighlightText()
        end)
    end)

    copyPopup = popup
    return popup
end

local function CreateInFormDropdown(entryCreationFrame)
    if inFormDropdown then return inFormDropdown end

    -- Dynamically anchor relative to the Blizzard activity dropdown (The Blinding Vale)
    -- so our button always sits exactly above it, flush left and right.
    local btn = CreateFrame("Button", "GravityUI_PremadeGroupInFormBtn", entryCreationFrame)
    btn:SetHeight(20)

    -- Try to find the Blizzard activity dropdown to anchor against
    local groupDD = entryCreationFrame.GroupDropdown   -- confirmed name from debug
                 or entryCreationFrame.ActivityDropdown
    if groupDD then
        -- Sit 4px above the Blizzard dropdown row, match its left/right edges
        btn:SetPoint("BOTTOMLEFT",  groupDD, "TOPLEFT",  0, 4)
        btn:SetPoint("BOTTOMRIGHT", groupDD, "TOPRIGHT", 0, 4)
    else
        -- Fallback: fixed position below "Dungeons" headline
        btn:SetPoint("TOPLEFT",  entryCreationFrame, "TOPLEFT",  15, -68)
        btn:SetPoint("TOPRIGHT", entryCreationFrame, "TOPRIGHT", -8,  -68)
    end
    btn:SetFrameLevel(entryCreationFrame:GetFrameLevel() + 50)

    local r, g, b = 0.06, 0.07, 0.08
    if ns.GetThemeBgColor then r, g, b = ns.GetThemeBgColor() end

    if ns.GUI and ns.GUI.CreateBackdrop then
        ns.GUI:CreateBackdrop(btn, {r, g, b, 0.9})
    else
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(r, g, b, 0.9)
        btn.bg = bg
    end

    -- Arrow icon
    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")

    -- Label
    inFormButtonText = btn:CreateFontString(nil, "OVERLAY")
    inFormButtonText:SetFont(GetFont(), 12, "OUTLINE")
    inFormButtonText:SetPoint("LEFT", btn, "LEFT", 10, 0)
    inFormButtonText:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
    inFormButtonText:SetText("Select Group Key…")
    local tr, tg, tb = 0, 0.72, 1
    if ns.GetThemeColor then tr, tg, tb = ns.GetThemeColor() end
    inFormButtonText:SetTextColor(tr, tg, tb, 1)

    -- Hover
    local bgTex = btn:CreateTexture(nil, "BORDER")
    bgTex:SetAllPoints()
    bgTex:SetColorTexture(r, g, b, 0)
    btn:SetScript("OnEnter", function()
        bgTex:SetColorTexture(0.12, 0.14, 0.16, 0.6)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Group Key Selector", 1, 1, 1)
        GameTooltip:AddLine("Select a keystone to pre-fill dungeon, title\nand playstyle in this form.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        bgTex:SetColorTexture(r, g, b, 0)
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self)
        ToggleDropDownMenu(1, nil, GetOrCreateDropdownMenu(), self, 0, -4)
    end)

    inFormDropdown = btn
    return btn
end

local function HookEntryCreationShow()
    if not LFGListFrame or not LFGListFrame.EntryCreation then
        C_Timer.After(1, HookEntryCreationShow)
        return
    end

    local entryCreationFrame = LFGListFrame.EntryCreation

    entryCreationFrame:HookScript("OnShow", function(self)
        if not IsEnabled() then
            if inFormDropdown then inFormDropdown:Hide() end
            return
        end

        -- Always show the in-form key selector so user can pick a key from here
        local inForm = CreateInFormDropdown(self)
        inForm:Show()

        -- Sync the in-form text with whatever is currently selected on the left
        if state.selectedGroupKey and state.selectedGroupKey > 0 then
            local selectedKeystone = state.groupKeys[state.selectedGroupKey]
            if selectedKeystone then
                UpdateBothButtonTexts(selectedKeystone.text)
            end
        else
            if inFormButtonText then inFormButtonText:SetText("Select Group Key…") end
        end

        if not state.selectedGroupKey or state.selectedGroupKey == 0 then
            state.pendingTitle = nil
            return
        end

        local selectedKeystone = state.groupKeys[state.selectedGroupKey]
        if not selectedKeystone then return end

        local title, activityID, dungeonName = GetPendingTitleFromKeystone(selectedKeystone)
        if not title then return end
        state.pendingTitle = title

        ApplyActivityToFrame(self, activityID, dungeonName)

        -- Show copy popup for group members' keystones (player can't paste directly)
        if selectedKeystone.player ~= UnitName("player") then
            local popup = CreateCopyPopup(entryCreationFrame)
            popup:ClearAllPoints()
            popup:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
            popup:Show()
        end
    end)

    entryCreationFrame:HookScript("OnHide", function()
        if inFormDropdown then inFormDropdown:Hide() end
    end)
end

---------------------------------------------------------------------------
-- DROPDOWN MENU INITIALIZER
---------------------------------------------------------------------------
InitializeDropdownMenu = function(self, level)
    if level ~= 1 then return end

    state.groupKeys = GetAllGroupKeystones()

    if #state.groupKeys == 0 then
        local info = {}
        info.text     = "|cffAAAAAA(No keys found)|r"
        info.disabled = true
        UIDropDownMenu_AddButton(info, level)
        return
    end

    for i, keyData in ipairs(state.groupKeys) do
        local info = {}
        info.text    = keyData.text
        info.value   = i
        info.checked = (state.selectedGroupKey == i)
        info.func = function()
            state.selectedGroupKey = i
            UpdateBothButtonTexts(keyData.text)
            CloseDropDownMenus()
            -- If the creation form is already open, apply immediately
            if LFGListFrame and LFGListFrame.EntryCreation
                    and LFGListFrame.EntryCreation:IsShown() then
                local selectedKeystone = state.groupKeys[i]
                if selectedKeystone then
                    local title, activityID, dungeonName = GetPendingTitleFromKeystone(selectedKeystone)
                    if title then
                        state.pendingTitle = title
                        ApplyActivityToFrame(LFGListFrame.EntryCreation, activityID, dungeonName)
                    end
                end
            end
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Shared dropdown frame (re-used by both the left-panel button and the in-form button)
GetOrCreateDropdownMenu = function()
    if groupKeysDropdown then return groupKeysDropdown end
    groupKeysDropdown = CreateFrame("Frame", "GravityUI_PremadeGroupDropdownMenu", UIParent, "UIDropDownMenuTemplate")
    groupKeysDropdown:SetFrameLevel(UIParent:GetFrameLevel() + 200)
    UIDropDownMenu_Initialize(groupKeysDropdown, InitializeDropdownMenu, "MENU")
    UIDropDownMenu_SetWidth(groupKeysDropdown, 220)
    return groupKeysDropdown
end

function PremadeGroup:CreateDropdown()
    if dropdownButton then return end  -- already created
    if InCombatLockdown() then return end
    if not GroupFinderFrame or not GroupFinderFrameGroupButton3 then return end

    -- Button that triggers the dropdown (full width of nav button)
    dropdownButton = CreateFrame("Button", "GravityUI_PremadeGroupDropdown", GroupFinderFrame)
    dropdownButton:SetPoint("TOPLEFT", GroupFinderFrameGroupButton3, "BOTTOMLEFT", 0, -5)
    dropdownButton:SetSize(GroupFinderFrameGroupButton3:GetWidth(), 26)
    dropdownButton:SetFrameLevel(UIParent:GetFrameLevel() + 100)

    -- Background
    local bgTex = dropdownButton:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints()
    bgTex:SetColorTexture(0.06, 0.07, 0.08, 0.85)

    -- Border
    if ns.GUI and ns.GUI.CreateBackdrop then
        ns.GUI:CreateBackdrop(dropdownButton, {0.06, 0.07, 0.08, 0.85})
    else
        local border = dropdownButton:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetColorTexture(0.2, 0.2, 0.22, 1)
    end

    -- Arrow icon
    local arrow = dropdownButton:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", dropdownButton, "RIGHT", -8, 0)
    arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")

    -- Label text
    dropdownButtonText = dropdownButton:CreateFontString(nil, "OVERLAY")
    dropdownButtonText:SetFont(GetFont(), 12, "OUTLINE")
    dropdownButtonText:SetPoint("LEFT", dropdownButton, "LEFT", 10, 0)
    dropdownButtonText:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
    dropdownButtonText:SetText("Select Group Key…")

    local r, g, b = 0, 0.72, 1
    if ns.GetThemeColor then r, g, b = ns.GetThemeColor() end
    dropdownButtonText:SetTextColor(r, g, b, 1)

    -- Tooltip + hover
    dropdownButton:SetScript("OnEnter", function(self)
        bgTex:SetColorTexture(0.12, 0.14, 0.16, 0.95)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Group Key Selector", 1, 1, 1)
        GameTooltip:AddLine("Select a group member's keystone\nto pre-fill the Premade Group creation.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    dropdownButton:SetScript("OnLeave", function()
        bgTex:SetColorTexture(0.06, 0.07, 0.08, 0.85)
        GameTooltip:Hide()
    end)

    dropdownButton:SetScript("OnClick", function(self)
        ToggleDropDownMenu(1, nil, GetOrCreateDropdownMenu(), self, 0, -4)
    end)
end

function PremadeGroup:SetEnabled(enabled)
    if dropdownButton then
        dropdownButton:SetShown(enabled)
    end
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function PremadeGroup:ApplySettings()
    local enabled = IsEnabled()
    if enabled then
        self:CreateDropdown()
        self:SetEnabled(true)
    else
        self:SetEnabled(false)
    end
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == ADDON_NAME then
        BuildLocalizationMaps()
        PremadeGroup:ApplySettings()
        HookEntryCreationShow()
    end
end)
