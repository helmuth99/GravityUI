-- GravityUI - Premade Group Helper
-- Integrates GroupKeys (by Kubi) Premade Group dropdown into GravityUI.
-- Key Broadcasting is handled separately by mplusteleport.lua.
local ADDON_NAME, ns = ...

local PremadeGroup = {}
ns.PremadeGroup = PremadeGroup

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
    [1] = "Learning",
    [2] = "Relaxed",
    [3] = "Competitive",
    [4] = "Carry Offered",
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

---------------------------------------------------------------------------
-- DYNAMIC ACTIVITY LOOKUP  (KeyLister pattern)
-- Builds a map of localized dungeon name → {categoryID, groupID, activityID}
-- by walking the 3-tier LFG hierarchy.  Works across seasons automatically.
---------------------------------------------------------------------------
local dungeonActivityMap = {}  -- [localizedDungeonName] = {categoryID, groupID, activityID}

local function RebuildDungeonActivityMap()
    wipe(dungeonActivityMap)
    local categories = C_LFGList.GetAvailableCategories()
    if not categories then return end
    for _, catID in ipairs(categories) do
        local groups = C_LFGList.GetAvailableActivityGroups(catID)
        if groups then
            for _, grpID in ipairs(groups) do
                local activities = C_LFGList.GetAvailableActivities(catID, grpID)
                if activities then
                    for _, actID in ipairs(activities) do
                        local info = C_LFGList.GetActivityInfoTable(actID)
                        if info and info.isMythicPlusActivity then
                            local groupName = C_LFGList.GetActivityGroupInfo(grpID)
                            if groupName then
                                dungeonActivityMap[groupName] = {
                                    categoryID = catID,
                                    groupID    = grpID,
                                    activityID = actID,
                                }
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

--- Look up the LFG entry (category/group/activity) for a challenge map ID.
local function FindActivityForMapID(challengeMapID)
    if not next(dungeonActivityMap) then RebuildDungeonActivityMap() end

    local mapName = C_ChallengeMode.GetMapUIInfo(challengeMapID)
    if not mapName then return nil end

    -- Direct match
    if dungeonActivityMap[mapName] then return dungeonActivityMap[mapName] end

    -- Fallback: strip common prefixes and try again
    local cleanName = mapName:gsub("Operation: ", ""):gsub("Tazavesh: ", "")
    if dungeonActivityMap[cleanName] then return dungeonActivityMap[cleanName] end

    return nil
end

---------------------------------------------------------------------------
-- KEYSTONE DATA  (reads from mplusteleport.lua's shared groupKeys table)
---------------------------------------------------------------------------
--- Build a map of player names → class token for players currently in the group.
--- Stores both short ("Name") and full ("Name-Realm") forms so we match
--- regardless of how groupKeys was keyed (Ambiguate "none" vs "short" vs UnitName).
local function GetCurrentGroupMembers()
    local members = {}

    local function AddUnit(unit)
        local name, realm = UnitName(unit)
        if not name or name == "" or name == UNKNOWNOBJECT then return end
        local _, class = UnitClass(unit)
        local token = class or true
        members[name] = token                              -- short form
        if realm and realm ~= "" then
            members[name .. "-" .. realm] = token          -- full "Name-Realm"
        end
        -- Also store Ambiguated forms for consistency
        local fullName = GetUnitName(unit, true)            -- "Name-Realm" (always)
        if fullName then
            local ok, amb = pcall(Ambiguate, fullName, "none")
            if ok and amb then members[amb] = token end
            ok, amb = pcall(Ambiguate, fullName, "short")
            if ok and amb then members[amb] = token end
        end
    end

    AddUnit("player")
    if IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, GetNumGroupMembers() do
            AddUnit(prefix .. i)
        end
    end
    return members
end

local function ClassColoredName(name, classToken)
    if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
        local c = RAID_CLASS_COLORS[classToken]
        return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name)
    end
    return name
end

local function GetAllGroupKeystones()
    local results = {}
    local seen = {} -- deduplicate: same player may be stored under multiple key formats

    local MPT = ns.MPlusTeleport
    if MPT and MPT.GetGroupKeys then
        local shared = MPT:GetGroupKeys()
        if shared then
            -- Only show keys from players currently in the group
            local members = GetCurrentGroupMembers()
            for playerName, kd in pairs(shared) do
                local classToken = members[playerName]
                if classToken and kd and kd.mapID and kd.level then
                    -- Normalize to short name for dedup & display
                    local ok, shortName = pcall(Ambiguate, playerName, "short")
                    local displayName = (ok and shortName and shortName ~= "") and shortName or playerName
                    if not seen[displayName] then
                        seen[displayName] = true
                        local dungeonName = C_ChallengeMode.GetMapUIInfo(kd.mapID) or "Unknown"
                        -- Strip prefixes for cleaner display
                        dungeonName = dungeonName:gsub("Operation: ", ""):gsub("Tazavesh: ", "")
                        local coloredName = ClassColoredName(displayName, classToken)
                        local text = dungeonName .. " +" .. kd.level .. "  " .. coloredName
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

local groupKeysDropdown  = nil
local copyPopup          = nil
local inFormDropdown     = nil  -- in-form key selector button (right panel)
local inFormButtonText   = nil  -- label FontString of the in-form button

-- Forward declarations (defined later, referenced by closures created earlier)
local GetOrCreateDropdownMenu
local InitializeDropdownMenu

local function UpdateButtonText(text)
    if inFormButtonText then inFormButtonText:SetText(text) end
end


---------------------------------------------------------------------------
-- LFG ENTRY CREATION HOOK
---------------------------------------------------------------------------

--- Resolve a keystone entry into a title and LFG entry data.
--- Uses dynamic activity lookup — no hardcoded season tables needed.
local function GetPendingTitleFromKeystone(keystone)
    if not keystone or not keystone.mapID then return nil end

    local entry = FindActivityForMapID(keystone.mapID)
    if not entry then return nil end

    local level = keystone.level
    local title = level and ("+" .. level) or nil
    return title, entry
end

--- Apply the selected keystone's dungeon + level to the Entry Creation form.
local function ApplyActivityToFrame(creationFrame, entry, level)
    -- Set the activity (Blizzard uses this to determine which dungeon is selected)
    creationFrame.selectedActivity = entry.activityID

    C_Timer.After(0, function()
        -- Update the dungeon dropdown text
        local dungeonName = C_LFGList.GetActivityGroupInfo(entry.groupID)
        if dungeonName and creationFrame.GroupDropdown then
            pcall(function() creationFrame.GroupDropdown:OverrideText(dungeonName) end)
        end

        -- NOTE: We cannot SetText() on the title field (creationFrame.Name)
        -- because Blizzard protects it with security taint.
        -- The CopyPopup is shown instead so the user can paste the title.

        -- Set the playstyle
        local playstyleValue = GetPlaystyle()
        if playstyleValue > 0 then
            local psDropdown = LFGListEntryCreationPlayStyleDropdown
                            or creationFrame.PlayStyleDropdown
            if psDropdown then
                creationFrame.generalPlaystyle = playstyleValue
                pcall(function() UIDropDownMenu_SetSelectedValue(psDropdown, playstyleValue) end)
                pcall(function() psDropdown:OverrideText(PLAYSTYLE_LABELS[playstyleValue] or "Relaxed") end)
            end
        end
    end)
end

local function CreateCopyPopup(entryCreationFrame)
    if copyPopup then return copyPopup end

    local popup = CreateFrame("Frame", "GravityUI_PremadeGroupCopyPopup", UIParent, "BackdropTemplate")
    popup:SetSize(320, 90)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(500)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    -- Background (dark glassmorphic)
    local bgR, bgG, bgB = 0.08, 0.09, 0.10
    if ns.GetThemeBgColor then bgR, bgG, bgB = ns.GetThemeBgColor() end
    popup:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    popup:SetBackdropColor(bgR, bgG, bgB, 0.96)
    popup:SetBackdropBorderColor(0.25, 0.25, 0.28, 0.8)
    popup:Hide()

    -- Accent bar (top edge, theme colored)
    local accentR, accentG, accentB = 0, 0.72, 1
    if ns.GetThemeColor then accentR, accentG, accentB = ns.GetThemeColor() end
    local accent = popup:CreateTexture(nil, "OVERLAY")
    accent:SetHeight(2)
    accent:SetPoint("TOPLEFT", popup, "TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -1, -1)
    accent:SetColorTexture(accentR, accentG, accentB, 0.9)

    -- Header label
    local header = popup:CreateFontString(nil, "OVERLAY")
    header:SetFont(GetFont(), 12, "OUTLINE")
    header:SetPoint("TOP", popup, "TOP", 0, -14)
    header:SetText("|cffFFCC00Paste Title|r")

    -- Instruction text
    local hint = popup:CreateFontString(nil, "OVERLAY")
    hint:SetFont(GetFont(), 10, "")
    hint:SetPoint("TOP", header, "BOTTOM", 0, -4)
    hint:SetTextColor(0.65, 0.65, 0.65, 1)
    hint:SetText("Ctrl+C to copy  ·  Ctrl+V in the title field")

    -- EditBox (styled, no default Blizzard look)
    local editBox = CreateFrame("EditBox", nil, popup)
    editBox:SetSize(280, 26)
    editBox:SetPoint("BOTTOM", popup, "BOTTOM", 0, 14)
    editBox:SetAutoFocus(false)
    editBox:SetPropagateKeyboardInput(false)
    editBox:SetFont(GetFont(), 14, "OUTLINE")
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetJustifyH("CENTER")

    -- EditBox background
    local ebBg = editBox:CreateTexture(nil, "BACKGROUND")
    ebBg:SetAllPoints()
    ebBg:SetColorTexture(0.12, 0.13, 0.15, 0.8)

    -- EditBox border (subtle)
    local ebBorder = CreateFrame("Frame", nil, editBox, "BackdropTemplate")
    ebBorder:SetPoint("TOPLEFT", -1, 1)
    ebBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    ebBorder:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 1,
    })
    ebBorder:SetBackdropBorderColor(accentR, accentG, accentB, 0.4)

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

    -- Close button (minimal X)
    local closeBtn = CreateFrame("Button", nil, popup)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -4, -4)
    closeBtn:SetNormalFontObject("GameFontNormalSmall")
    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTxt:SetFont(GetFont(), 12, "OUTLINE")
    closeTxt:SetPoint("CENTER")
    closeTxt:SetText("|cff888888×|r")
    closeBtn:SetScript("OnClick", function() popup:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeTxt:SetText("|cffFFFFFF×|r") end)
    closeBtn:SetScript("OnLeave", function() closeTxt:SetText("|cff888888×|r") end)

    popup.editBox = editBox
    popup:SetScript("OnShow", function(p)
        p.editBox:SetText(state.pendingTitle or "")
        -- Fade in
        p:SetAlpha(0)
        local elapsed = 0
        p:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local alpha = math.min(elapsed / 0.15, 1)
            self:SetAlpha(alpha)
            if alpha >= 1 then self:SetScript("OnUpdate", nil) end
        end)
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

    -- Dynamically anchor relative to the Blizzard activity dropdown
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

        -- Sync the in-form text with whatever is currently selected
        if state.selectedGroupKey and state.selectedGroupKey > 0 then
            local selectedKeystone = state.groupKeys[state.selectedGroupKey]
            if selectedKeystone then
                UpdateButtonText(selectedKeystone.text)
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

        local title, entry = GetPendingTitleFromKeystone(selectedKeystone)
        if not title then return end
        state.pendingTitle = title

        ApplyActivityToFrame(self, entry, selectedKeystone.level)

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
        if copyPopup then copyPopup:Hide() end
        -- Reset selection so the popup doesn't reappear on next open
        state.selectedGroupKey = 0
        state.pendingTitle = nil
        if inFormButtonText then inFormButtonText:SetText("Select Group Key…") end
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
            UpdateButtonText(keyData.text)
            CloseDropDownMenus()
            -- If the creation form is already open, apply immediately
            if LFGListFrame and LFGListFrame.EntryCreation
                    and LFGListFrame.EntryCreation:IsShown() then
                local ecFrame = LFGListFrame.EntryCreation
                local selectedKeystone = state.groupKeys[i]
                if selectedKeystone then
                    local title, entry = GetPendingTitleFromKeystone(selectedKeystone)
                    if title then
                        state.pendingTitle = title
                        ApplyActivityToFrame(ecFrame, entry, selectedKeystone.level)

                        -- Show CopyPopup so user can paste the title
                        local popup = CreateCopyPopup(ecFrame)
                        popup:ClearAllPoints()
                        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
                        popup:Show()
                    end
                end
            end
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Shared dropdown frame (used by the in-form button)
GetOrCreateDropdownMenu = function()
    if groupKeysDropdown then return groupKeysDropdown end
    groupKeysDropdown = CreateFrame("Frame", "GravityUI_PremadeGroupDropdownMenu", UIParent, "UIDropDownMenuTemplate")
    groupKeysDropdown:SetFrameLevel(UIParent:GetFrameLevel() + 200)
    UIDropDownMenu_Initialize(groupKeysDropdown, InitializeDropdownMenu, "MENU")
    UIDropDownMenu_SetWidth(groupKeysDropdown, 220)
    return groupKeysDropdown
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function PremadeGroup:ApplySettings()
    -- No-op if disabled; in-form dropdown visibility is handled by the OnShow hook
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == ADDON_NAME then
        PremadeGroup:ApplySettings()
        HookEntryCreationShow()
    end
end)
