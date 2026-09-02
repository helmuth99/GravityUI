-- GravityUI - Player Marks
-- Automatic raid target icon assignment via SecureActionButton
-- Uses /tm macro triggered by physical click to bypass SetRaidTarget protection
local ADDON_NAME, ns = ...

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local MARK_NAMES = {
    [0] = "None",
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross",
    [8] = "Skull",
}

local MARK_ICONS = {
    [1] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t",
    [2] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t",
    [3] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t",
    [4] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t",
    [5] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t",
    [6] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t",
    [7] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
    [8] = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t",
}

-- Export for settings UI
ns.PlayerMarks = {
    MARK_NAMES = MARK_NAMES,
    MARK_ICONS = MARK_ICONS,
}

-- ============================================================================
-- DATABASE ACCESS
-- ============================================================================
local function GetDB()
    local db = ns.GetDB()
    if not db then return nil end
    if not db.playermarks then
        db.playermarks = {
            enabled = true,
            dungeon = {
                TANK = 0,
                HEALER = 0,
            },
            raid = {
                players = {},
                customTargets = {},
            },
        }
    end
    return db.playermarks
end

-- ============================================================================
-- PERMISSION CHECK
-- ============================================================================
local function CanSetMarks()
    if not IsInGroup() and GetNumGroupMembers() <= 1 then return false end
    if IsInRaid() then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end
    -- In 5-man party (including follower dungeons), anyone can set marks
    return true
end

-- ============================================================================
-- MACRO BUILDER
-- ============================================================================
local function BuildMacro()
    local pdb = GetDB()
    if not pdb then return "", {} end

    local macro = ""
    local assignments = {} -- { { name = "X", mark = 6 }, ... }

    if IsInRaid() then
        -- Raid: Player-specific marks (only for active raid members, only set when mark > 0)
        local currentRaidNames = {}
        local numRaid = GetNumGroupMembers()
        for i = 1, numRaid do
            local u = "raid" .. i
            if UnitExists(u) then
                local n = UnitName(u)
                if n then currentRaidNames[n] = true end
            end
        end

        -- Clean up players who are no longer in the raid
        for savedName in pairs(pdb.raid.players) do
            if not currentRaidNames[savedName] then
                pdb.raid.players[savedName] = nil
            end
        end

        for playerName, markIndex in pairs(pdb.raid.players) do
            if markIndex and markIndex > 0 and currentRaidNames[playerName] then
                macro = macro .. "/target " .. playerName .. "\n/tm " .. markIndex .. "\n"
                assignments[#assignments + 1] = { name = playerName, mark = markIndex }
            end
        end
        -- Custom Targets (bosses/NPCs) — only if mark > 0
        for _, entry in ipairs(pdb.raid.customTargets) do
            if entry.name and entry.name ~= "" and entry.mark and entry.mark > 0 then
                macro = macro .. "/target " .. entry.name .. "\n/tm " .. entry.mark .. "\n"
                assignments[#assignments + 1] = { name = entry.name, mark = entry.mark }
            end
        end
    else
        -- M+ / Follower Dungeon: Role-based (include player and all party members)
        -- Only assign when mark > 0 (None / 0 does nothing and does NOT clear existing marks)
        local units = { "player" }
        local numSub = GetNumSubgroupMembers()
        for i = 1, numSub do
            units[#units + 1] = "party" .. i
        end

        for _, unit in ipairs(units) do
            if UnitExists(unit) then
                local role = UnitGroupRolesAssigned(unit)
                local name = UnitName(unit)
                local mark = pdb.dungeon[role]
                if mark and mark > 0 and name then
                    if UnitIsUnit(unit, "player") then
                        macro = macro .. "/target player\n/tm " .. mark .. "\n"
                    else
                        macro = macro .. "/target " .. name .. "\n/tm " .. mark .. "\n"
                    end
                    assignments[#assignments + 1] = { name = name, mark = mark }
                end
            end
        end
    end

    -- Restore original target
    if macro ~= "" then
        macro = macro .. "/targetlasttarget"
    end

    return macro, assignments
end

-- ============================================================================
-- SECURE BUTTON CREATION
-- ============================================================================
local markButton
local pendingAssignments = {} -- stored for PostClick chat output

local function CreateMarkButton()
    if markButton then return markButton end

    markButton = CreateFrame("Button", "GravityUI_SetMarksButton", UIParent, "SecureActionButtonTemplate")
    markButton:SetSize(140, 28)
    markButton:RegisterForClicks("AnyUp", "AnyDown")
    markButton:SetAttribute("type", "macro")
    markButton:SetAttribute("macrotext", "")
    markButton:SetFrameStrata("DIALOG")
    markButton:SetFrameLevel(100)
    markButton:Hide()

    -- Visual styling
    local bg = markButton:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8)
    markButton._bg = bg

    local border = markButton:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    markButton._border = border

    -- Inner background (over border)
    local inner = markButton:CreateTexture(nil, "ARTWORK")
    inner:SetAllPoints()
    inner:SetColorTexture(0.12, 0.12, 0.15, 0.95)
    markButton._inner = inner

    local text = markButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", 0, 0)
    text:SetText("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:14|t Set Marks")
    if ns.GUI and ns.GUI.SetFont then
        ns.GUI:SetFont(text, 11, "OUTLINE")
    end
    markButton._text = text

    -- Hover effect
    markButton:SetScript("OnEnter", function(self)
        self._inner:SetColorTexture(0.2, 0.2, 0.25, 0.95)
    end)
    markButton:SetScript("OnLeave", function(self)
        self._inner:SetColorTexture(0.12, 0.12, 0.15, 0.95)
    end)

    -- Verify marks after click
    local function VerifyMarks(btn)
        -- Permission warning
        if IsInRaid() and not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player") then
            print("|cFF30D1FF[GravityUI]|r |cFFFF4444Marks failed:|r You need Raid Leader or Assistant to set marks in raid.")
            HideMarkButton()
            return
        end

        -- Verify after short delay to let the macro finish
        C_Timer.After(0.5, function()
            for _, a in ipairs(pendingAssignments) do
                local icon = MARK_ICONS[a.mark] or ""
                local markName = MARK_NAMES[a.mark] or "?"

                -- Try to find the unit and check its mark
                local unitID = nil
                if IsInRaid() then
                    for i = 1, GetNumGroupMembers() do
                        local u = "raid" .. i
                        if UnitExists(u) and UnitName(u) == a.name then
                            unitID = u; break
                        end
                    end
                else
                    if UnitName("player") == a.name then
                        unitID = "player"
                    else
                        for i = 1, GetNumSubgroupMembers() do
                            local u = "party" .. i
                            if UnitExists(u) and UnitName(u) == a.name then
                                unitID = u; break
                            end
                        end
                    end
                end

                if not unitID then
                    -- Custom target (boss/NPC) — can't verify
                    if a.mark > 0 then
                        print("|cFF30D1FF[GravityUI]|r " .. icon .. " " .. markName .. " on |cFFFFFFFF" .. a.name .. "|r — |cFFFFCC00attempted (boss/NPC)|r")
                    end
                else
                    if a.mark == 0 then
                        -- Clearing mark
                        print("|cFF30D1FF[GravityUI]|r clears mark on |cFFFFFFFF" .. a.name .. "|r — |cFF44FF44OK|r")
                    else
                        -- pcall: GetRaidTargetIndex may return secret values in follower dungeons
                        local ok, verified = pcall(function()
                            local m = GetRaidTargetIndex(unitID)
                            return m == a.mark
                        end)
                        if ok and verified then
                            print("|cFF30D1FF[GravityUI]|r " .. icon .. " " .. markName .. " on |cFFFFFFFF" .. a.name .. "|r — |cFF44FF44OK|r")
                        elseif not ok then
                            -- Secret value — assume it worked
                            print("|cFF30D1FF[GravityUI]|r " .. icon .. " " .. markName .. " on |cFFFFFFFF" .. a.name .. "|r — |cFF44FF44OK|r")
                        else
                            print("|cFF30D1FF[GravityUI]|r " .. icon .. " " .. markName .. " on |cFFFFFFFF" .. a.name .. "|r — |cFFFF4444FAILED|r")
                        end
                    end
                end
            end
            HideMarkButton()
        end)
    end

    -- Use OnMouseUp for reliable click detection (PostClick can be unreliable on secure buttons)
    markButton:SetScript("OnMouseUp", function(self)
        VerifyMarks(self)
    end)

    return markButton
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================
local eventFrame = CreateFrame("Frame")

local function ShowMarkButton()
    local pdb = GetDB()
    if not pdb or not pdb.enabled then return end
    if not CanSetMarks() then return end
    if InCombatLockdown() then return end

    -- Build macro
    local macro, assignments = BuildMacro()
    if macro == "" then return end

    local btn = CreateMarkButton()

    -- Can only set attributes and show out of combat
    if InCombatLockdown() then return end

    btn:SetAttribute("macrotext", macro)
    pendingAssignments = assignments

    -- Position: try to anchor near ReadyCheckFrame, otherwise center-bottom
    if ReadyCheckFrame and ReadyCheckFrame:IsShown() then
        btn:ClearAllPoints()
        btn:SetPoint("TOP", ReadyCheckFrame, "BOTTOM", 0, -5)
    else
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    end

    btn:SetAlpha(1)
    btn:Show()
end

HideMarkButton = function()
    if not markButton then return end
    if InCombatLockdown() then
        -- TAINT FIX: Cannot call Hide() on a protected SecureActionButton during combat lockdown.
        -- Visually hide immediately via SetAlpha(0) (safe C-API) and queue actual Hide() for OOC.
        markButton:SetAlpha(0)
        if ns.QueueOOCAction then
            ns.QueueOOCAction(function()
                if markButton then
                    markButton:Hide()
                    markButton:SetAlpha(1)
                end
            end)
        end
        return
    end
    markButton:SetAlpha(1)
    markButton:Hide()
end

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "READY_CHECK" then
        ShowMarkButton()
    elseif event == "READY_CHECK_FINISHED" then
        -- Small delay to allow clicking
        C_Timer.After(2, function()
            HideMarkButton()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat: immediately suppress mark button
        HideMarkButton()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Re-check if button should be hidden after combat
        if markButton and markButton:IsShown() then
            HideMarkButton()
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        local pdb = GetDB()
        if pdb and pdb.raid and pdb.raid.players then
            if not IsInRaid() then
                -- Leaving a raid resets temporary player marks
                wipe(pdb.raid.players)
            else
                -- In raid: clean up players who left
                local currentNames = {}
                for i = 1, GetNumGroupMembers() do
                    local u = "raid" .. i
                    if UnitExists(u) then
                        local n = UnitName(u)
                        if n then currentNames[n] = true end
                    end
                end
                for savedName in pairs(pdb.raid.players) do
                    if not currentNames[savedName] then
                        pdb.raid.players[savedName] = nil
                    end
                end
            end
        end
    end
end)

eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("READY_CHECK_FINISHED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

-- ============================================================================
-- MANUAL TRIGGER (slash command or button in settings)
-- ============================================================================
ns.PlayerMarks.ShowMarkButton = ShowMarkButton
ns.PlayerMarks.HideMarkButton = HideMarkButton
ns.PlayerMarks.BuildMacro = BuildMacro
ns.PlayerMarks.CanSetMarks = CanSetMarks
ns.PlayerMarks.GetDB = GetDB
ns.PlayerMarks._createButton = CreateMarkButton

-- Slash command for manual testing
SLASH_GRAVITYMARKS1 = "/gravitymarks"
SlashCmdList["GRAVITYMARKS"] = function()
    local pdb = GetDB()
    if not pdb then
        print("|cFF30D1FF[GravityUI]|r Player Marks: No database available.")
        return
    end
    if not IsInGroup() then
        print("|cFF30D1FF[GravityUI]|r Player Marks: You are not in a group.")
        return
    end
    if not CanSetMarks() then
        print("|cFF30D1FF[GravityUI]|r Player Marks: You need to be Raid Leader or Assistant.")
        return
    end
    local macro = BuildMacro()
    if macro == "" then
        print("|cFF30D1FF[GravityUI]|r Player Marks: No marks configured.")
        return
    end
    ShowMarkButton()
    print("|cFF30D1FF[GravityUI]|r Player Marks: Click the 'Set Marks' button to apply.")
end
