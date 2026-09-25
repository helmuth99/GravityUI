-- GravityUI - LFG Teleport Reminder
-- When the player joins a Group Finder (LFGList) group for a dungeon that has
-- a known teleport, show a small popup with the dungeon name and a one-click
-- teleport button. The popup hides when the player enters the dungeon, leaves
-- the group, or enters combat. A close (X) button dismisses it manually.
--
-- Taint / secret-value safety:
--   - The teleport spellID fed to SetAttribute("spell", id) is ALWAYS a static
--     integer resolved from our own DungeonData tables, never an LFG field.
--   - The dungeon is resolved on LFG_LIST_JOINED_GROUP where the search result
--     is readable. All fields guarded with issecretvalue() and pcall.
--   - The secure button is created ONCE at login (out of combat); only the
--     "spell" attribute is rewritten later, and only out of combat.
local ADDON_NAME, ns = ...

local LSM = LibStub("LibSharedMedia-3.0", true)
local issecretvalue = issecretvalue or function() return false end

-------------------------------------------------------------------------------
--  Settings
-------------------------------------------------------------------------------
local function GetSettings()
    local db = ns.GetDB()
    return db and db.uiimprovements
end

local function IsEnabled()
    local s = GetSettings()
    return s and s.lfgTeleportReminder ~= false
end

local function GetFont()
    local db = ns.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    local fontPath = LSM and LSM:Fetch("font", fontName)
    return fontPath or [[Interface\AddOns\GravityUI\media\font\Gravity.ttf]]
end

-- Reuse the IsTeleportKnown from mplusteleport.lua if available, else inline
local function IsTeleportKnown(spellID)
    if not spellID then return false end
    local ok1, r1 = pcall(IsPlayerSpell, spellID)
    if ok1 and r1 then return true end
    local ok2, r2 = pcall(IsSpellKnown, spellID)
    if ok2 and r2 then return true end
    if C_SpellBook and C_SpellBook.IsSpellUsable then
        local ok3, r3 = pcall(C_SpellBook.IsSpellUsable, spellID)
        if ok3 and r3 then return true end
    end
    return false
end

-------------------------------------------------------------------------------
--  Layout constants
-------------------------------------------------------------------------------
local POPUP_W     = 220
local TITLE_H     = 28
local PAD         = 10
local NAME_TOP    = TITLE_H + 8
local NAME_H      = 24
local BTN_TOP     = NAME_TOP + NAME_H
local BTN_H       = 56
local POPUP_H     = BTN_TOP + BTN_H + PAD

-------------------------------------------------------------------------------
--  State (plain upvalues; never keyed by a possibly-secret resultID)
-------------------------------------------------------------------------------
local popup, secureBtn
local popupAccent, popupTitle, popupHdrBg  -- color-dependent refs for RefreshColors
local pendingSpellID        -- resolved teleport spell (static integer) to use
local pendingName           -- dungeon display name for the title
local pendingAttrSpellID    -- spell attr stashed to write when leaving combat
local pendingShow           -- join landed in combat; show on PLAYER_REGEN_ENABLED
local pendingHide           -- hide requested in combat; hide on PLAYER_REGEN_ENABLED

-- Forward declarations
local BuildPopup, ShowPrompt, HidePrompt, ClearPending
local UpdateButtonVisuals, ResolveDungeon, RefreshPopupColors
local SavePosition, ApplySavedPosition

-------------------------------------------------------------------------------
--  Position persistence
-------------------------------------------------------------------------------
SavePosition = function()
    if not popup then return end
    local s = GetSettings()
    if not s then return end
    local p, _, rp, x, yo = popup:GetPoint()
    if p then s.lfgTeleportPos = { p = p, rp = rp, x = x, y = yo } end
end

ApplySavedPosition = function()
    if not popup then return end
    popup:ClearAllPoints()
    local s = GetSettings()
    local pos = s and s.lfgTeleportPos
    if pos and pos.p then
        popup:SetPoint(pos.p, UIParent, pos.rp or pos.p, pos.x or 0, pos.y or 0)
    else
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    end
end

-------------------------------------------------------------------------------
--  Build the popup + secure button (called once at login, out of combat)
-------------------------------------------------------------------------------
BuildPopup = function()
    if popup then return popup end

    popup = CreateFrame("Frame", "GravityUI_LFGTeleportPopup", UIParent)
    popup:SetSize(POPUP_W, POPUP_H)
    popup:SetFrameStrata("DIALOG")
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function(s) s:StartMoving() end)
    popup:SetScript("OnDragStop", function(s) s:StopMovingOrSizing(); SavePosition() end)

    -- Background: GravityUI themed backdrop
    local bgR, bgG, bgB = 0.11, 0.12, 0.13
    if ns.GetThemeBgColor then bgR, bgG, bgB = ns.GetThemeBgColor() end
    if ns.GUI and ns.GUI.CreateBackdrop then
        ns.GUI:CreateBackdrop(popup, {bgR, bgG, bgB, 0.92})
    else
        local bg = popup:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(bgR, bgG, bgB, 0.92)
    end

    -- Header bar
    popupHdrBg = popup:CreateTexture(nil, "BORDER")
    popupHdrBg:SetColorTexture(0, 0, 0, 0.3)
    popupHdrBg:SetPoint("TOPLEFT", 1, -1)
    popupHdrBg:SetPoint("TOPRIGHT", -1, 0)
    popupHdrBg:SetHeight(TITLE_H)

    -- Theme accent stripe (left edge of header)
    local accentR, accentG, accentB = 1, 0.82, 0
    if ns.GetAccentColor then accentR, accentG, accentB = ns.GetAccentColor() end
    popupAccent = popup:CreateTexture(nil, "BORDER", nil, 3)
    popupAccent:SetWidth(2)
    popupAccent:SetPoint("TOPLEFT", popup, "TOPLEFT", 0, 0)
    popupAccent:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 0, 0)
    popupAccent:SetColorTexture(accentR, accentG, accentB, 1)

    -- Title text
    popupTitle = popup:CreateFontString(nil, "OVERLAY")
    popupTitle:SetFont(GetFont(), 11, "OUTLINE")
    popupTitle:SetPoint("TOPLEFT", PAD, -8)
    popupTitle:SetPoint("TOPRIGHT", -(PAD + 16), -8)
    popupTitle:SetJustifyH("LEFT")
    popupTitle:SetWordWrap(false)
    popupTitle:SetText("LFG Reminder")
    popupTitle:SetTextColor(accentR, accentG, accentB, 1)

    -- Dungeon name label
    local nameFS = popup:CreateFontString(nil, "OVERLAY")
    nameFS:SetFont(GetFont(), 13, "OUTLINE")
    nameFS:SetPoint("TOPLEFT", popup, "TOPLEFT", PAD, -NAME_TOP)
    nameFS:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -PAD, -NAME_TOP)
    nameFS:SetJustifyH("CENTER")
    nameFS:SetWordWrap(true)
    nameFS:SetTextColor(1, 1, 1, 1)
    popup._name = nameFS

    -- Close (X) button
    local xBtn = CreateFrame("Button", nil, popup)
    xBtn:SetSize(14, 14)
    xBtn:SetPoint("TOPRIGHT", -6, -7)
    local xTex = xBtn:CreateTexture(nil, "ARTWORK")
    xTex:SetAllPoints()
    xTex:SetTexture("Interface\\AddOns\\GravityUI\\assets\\icons\\close.tga")
    xTex:SetAlpha(0.5)
    -- Fallback if texture doesn't exist: use a simple X label
    xBtn:SetScript("OnShow", function()
        if not xTex:GetTexture() or xTex:GetTexture() == 0 then
            xTex:SetTexture("Interface\\Buttons\\UI-StopButton")
        end
    end)
    xBtn:SetScript("OnEnter", function() xTex:SetAlpha(1) end)
    xBtn:SetScript("OnLeave", function() xTex:SetAlpha(0.5) end)
    xBtn:SetScript("OnClick", function() HidePrompt() end)

    -- Secure teleport button
    secureBtn = CreateFrame("Button", "GravityUI_LFGTeleportButton", popup, "SecureActionButtonTemplate")
    secureBtn:SetSize(POPUP_W - PAD * 2, BTN_H)
    secureBtn:SetPoint("TOP", popup, "TOP", 0, -BTN_TOP)
    secureBtn:RegisterForClicks("AnyUp", "AnyDown")
    secureBtn:SetAttribute("type", "spell")

    -- Button background
    local btnBg = secureBtn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints()
    btnBg:SetColorTexture(0.04, 0.04, 0.06, 0.9)
    if ns.GUI and ns.GUI.CreateBackdrop then
        ns.GUI:CreateBackdrop(secureBtn, {0, 0, 0, 0}, {1, 1, 1, 0.4})
    end

    -- Spell icon
    local icon = secureBtn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    secureBtn._icon = icon

    -- Button label
    local btnLabel = secureBtn:CreateFontString(nil, "OVERLAY")
    btnLabel:SetFont(GetFont(), 12, "OUTLINE")
    btnLabel:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    btnLabel:SetPoint("RIGHT", -6, 0)
    btnLabel:SetJustifyH("LEFT")
    btnLabel:SetWordWrap(false)
    btnLabel:SetText("Teleport")
    btnLabel:SetTextColor(1, 1, 1, 1)
    secureBtn._label = btnLabel

    -- Hover highlight
    local hover = secureBtn:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.08)

    -- Cooldown overlay
    local cd = CreateFrame("Cooldown", nil, secureBtn, "CooldownFrameTemplate")
    cd:SetPoint("LEFT", secureBtn, "LEFT", 8, 0)
    cd:SetSize(40, 40)
    cd:SetHideCountdownNumbers(true)
    cd:SetDrawSwipe(true)
    cd:SetDrawBling(false)
    cd:SetDrawEdge(false)
    secureBtn._cd = cd

    -- Tooltip
    secureBtn:SetScript("OnEnter", function(self)
        local sid = pendingSpellID
        if not sid then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if not IsTeleportKnown(sid) then
            GameTooltip:SetText("Teleport Not Learned", 1, 0.3, 0.3)
            GameTooltip:AddLine("You haven't unlocked this dungeon teleport yet.", 0.8, 0.8, 0.8, true)
        else
            local cdInfo = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(sid)
            if cdInfo and cdInfo.duration and cdInfo.duration > 0 then
                GameTooltip:SetText("Teleport on Cooldown", 1, 0.8, 0)
            else
                GameTooltip:SetText("Teleport to " .. (pendingName or "dungeon"), 0.3, 1, 0.5)
            end
        end
        GameTooltip:Show()
    end)
    secureBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ApplySavedPosition()
    popup:Hide()

    -- Hook into global accent refresh so live theme changes update this popup
    local origRefresh = ns.RefreshAccentColors
    ns.RefreshAccentColors = function()
        if origRefresh then origRefresh() end
        RefreshPopupColors()
    end

    return popup
end

-------------------------------------------------------------------------------
--  Visuals
-------------------------------------------------------------------------------
UpdateButtonVisuals = function()
    if not secureBtn or not pendingSpellID then return end
    local sid = pendingSpellID
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(sid)
    if info and info.iconID then secureBtn._icon:SetTexture(info.iconID) end
    local known = IsTeleportKnown(sid)
    secureBtn._icon:SetDesaturated(not known)
    secureBtn._icon:SetAlpha(known and 1 or 0.4)
    local lc = known and 1 or 0.5
    secureBtn._label:SetTextColor(lc, lc, lc, 1)
    if known then
        local cdInfo = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(sid)
        if cdInfo and cdInfo.startTime and cdInfo.duration and cdInfo.duration > 0 then
            pcall(secureBtn._cd.SetCooldown, secureBtn._cd, cdInfo.startTime, cdInfo.duration)
        else
            secureBtn._cd:Clear()
        end
    else
        secureBtn._cd:Clear()
    end
end

--- Refresh accent / bg colors on the popup when the user changes their theme.
RefreshPopupColors = function()
    if not popup then return end
    local aR, aG, aB = 1, 0.82, 0
    if ns.GetAccentColor then aR, aG, aB = ns.GetAccentColor() end
    if popupAccent then popupAccent:SetColorTexture(aR, aG, aB, 1) end
    if popupTitle  then popupTitle:SetTextColor(aR, aG, aB, 1) end
    -- Background refresh
    if popup.Backdrop then
        local bgR, bgG, bgB = 0.11, 0.12, 0.13
        if ns.GetThemeBgColor then bgR, bgG, bgB = ns.GetThemeBgColor() end
        popup.Backdrop:SetBackdropColor(bgR, bgG, bgB, 0.92)
    end
end

-------------------------------------------------------------------------------
--  Resolve the accepted dungeon -> teleport spell
-------------------------------------------------------------------------------
ResolveDungeon = function(resultID)
    if not (C_LFGList and C_LFGList.GetSearchResultInfo) then return end
    pcall(function()
        local info = C_LFGList.GetSearchResultInfo(resultID)
        if type(info) ~= "table" then return end
        local activityID = info.activityID
        if activityID == nil and info.activityIDs and not issecretvalue(info.activityIDs) then
            activityID = info.activityIDs[1]
        end
        if issecretvalue(activityID) or activityID == nil then return end
        local act = C_LFGList.GetActivityInfoTable(activityID)
        if type(act) ~= "table" then return end
        local fullName = act.fullName
        if type(fullName) ~= "string" or issecretvalue(fullName) then return end
        local spellID = ns.DungeonData and ns.DungeonData.ResolveTeleportByName
            and ns.DungeonData.ResolveTeleportByName(fullName)
        if spellID then
            pendingSpellID = spellID
            -- Strip trailing difficulty suffix: "Skyreach (Mythic Keystone)" -> "Skyreach"
            pendingName = (fullName:gsub("%s*%b()%s*$", ""))
        end
    end)
end

-------------------------------------------------------------------------------
--  Show / Hide / Clear
-------------------------------------------------------------------------------
ShowPrompt = function()
    if not IsEnabled() or not pendingSpellID then return end
    BuildPopup()
    popup._name:SetText(pendingName or "")
    if InCombatLockdown() then
        pendingAttrSpellID = pendingSpellID
        pendingShow = true
        pendingHide = nil
        return
    end
    secureBtn:SetAttribute("spell", pendingSpellID)
    pendingAttrSpellID = nil
    pendingHide = nil
    UpdateButtonVisuals()
    popup:Show()
end

HidePrompt = function()
    pendingShow = nil
    if not (popup and popup:IsShown()) then pendingHide = nil; return end
    if InCombatLockdown() then pendingHide = true; return end
    pendingHide = nil
    popup:Hide()
end

ClearPending = function()
    pendingSpellID = nil
    pendingName = nil
    pendingShow = nil
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
local ev = CreateFrame("Frame")

-- Separate frame for UNIT_SPELLCAST_SUCCEEDED (unit-scoped event)
local castWatcher = CreateFrame("Frame")
castWatcher:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        if pendingSpellID and spellID == pendingSpellID then
            -- Teleport cast finished → close the popup
            ClearPending()
            HidePrompt()
        end
    end
end)

ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "PLAYER_LOGIN" then
        if IsEnabled() then BuildPopup() end
        -- Register feature events
        if IsEnabled() then
            ev:RegisterEvent("LFG_LIST_JOINED_GROUP")
            ev:RegisterEvent("GROUP_ROSTER_UPDATE")
            ev:RegisterEvent("PLAYER_ENTERING_WORLD")
            ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
            ev:RegisterEvent("PLAYER_REGEN_DISABLED")
            ev:RegisterEvent("PLAYER_REGEN_ENABLED")
            castWatcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        end
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Flush secure attribute write that was blocked during combat
        if pendingAttrSpellID and secureBtn then
            secureBtn:SetAttribute("spell", pendingAttrSpellID)
            pendingAttrSpellID = nil
        end
        -- Surface a prompt whose accept landed mid-combat
        if pendingShow and pendingSpellID and IsEnabled() then
            pendingShow = nil
            UpdateButtonVisuals()
            if popup then popup:Show() end
        end
        -- Flush a hide that was blocked during combat
        if pendingHide then
            pendingHide = nil
            if popup and popup:IsShown() then popup:Hide() end
        end
        return
    elseif event == "PLAYER_REGEN_DISABLED" then
        HidePrompt()
        return
    end

    if not IsEnabled() then
        ClearPending(); HidePrompt(); return
    end

    if event == "LFG_LIST_JOINED_GROUP" then
        ClearPending()
        ResolveDungeon(arg1)
        if pendingSpellID then ShowPrompt() end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if not IsInGroup() then
            ClearPending(); HidePrompt()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "party" then
            ClearPending(); HidePrompt()
        end
    end
end)

-------------------------------------------------------------------------------
--  Public API (for settings page)
-------------------------------------------------------------------------------
ns.LFGTeleport = {
    ApplySettings = function()
        if IsEnabled() then
            if not popup and not InCombatLockdown() then BuildPopup() end
            ev:RegisterEvent("LFG_LIST_JOINED_GROUP")
            ev:RegisterEvent("GROUP_ROSTER_UPDATE")
            ev:RegisterEvent("PLAYER_ENTERING_WORLD")
            ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
            ev:RegisterEvent("PLAYER_REGEN_DISABLED")
            ev:RegisterEvent("PLAYER_REGEN_ENABLED")
            castWatcher:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        else
            ClearPending()
            HidePrompt()
            ev:UnregisterEvent("LFG_LIST_JOINED_GROUP")
            ev:UnregisterEvent("GROUP_ROSTER_UPDATE")
            castWatcher:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
            -- Keep PLAYER_REGEN_ENABLED registered if there's a pending flush
            if not (pendingHide or pendingAttrSpellID) then
                ev:UnregisterEvent("PLAYER_REGEN_ENABLED")
            end
        end
    end,

    --- Test the popup with a sample dungeon (no real LFG join needed).
    TestPrompt = function()
        if InCombatLockdown() then
            print("|cFF30D1FFGravityUI:|r Cannot test in combat.")
            return
        end
        -- Toggle: if popup is already shown, hide it
        if popup and popup:IsShown() then
            ClearPending(); HidePrompt()
            print("|cFF30D1FFGravityUI:|r LFG Teleport Reminder hidden.")
            return
        end
        -- Pick a current-season dungeon from DungeonData
        BuildPopup()
        local testMaps = C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable() or {}
        local testSpell, testName
        for _, mapID in ipairs(testMaps) do
            local spell = ns.DungeonData and ns.DungeonData.GetTeleportSpellID(mapID)
            if spell then
                testName = C_ChallengeMode.GetMapUIInfo(mapID)
                testSpell = spell
                break
            end
        end
        if not testSpell then
            -- Hardcoded fallback
            testSpell = 1286801
            testName = "The Blinding Vale"
        end
        pendingSpellID = testSpell
        pendingName = testName
        secureBtn:SetAttribute("spell", testSpell)
        popup._name:SetText(testName)
        UpdateButtonVisuals()
        popup:Show()
        print("|cFF30D1FFGravityUI:|r LFG Teleport Reminder test — showing \"" .. testName .. "\". Type /lfgtest again to hide.")
    end,
}

SLASH_GRAVITYLFGTEST1 = "/lfgtest"
SlashCmdList["GRAVITYLFGTEST"] = function()
    if ns.LFGTeleport and ns.LFGTeleport.TestPrompt then
        ns.LFGTeleport.TestPrompt()
    end
end
