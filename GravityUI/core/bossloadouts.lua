-- GravityUI: Boss Loadouts & NSRT Cooldown Reminders Integration
-- Command: /gravityboss or /guiboss
local ADDON_NAME, G = ...

local BossLoadouts = {}
G.BossLoadouts = BossLoadouts

local LOADOUT_NAME = "GravityUI: Talents"
local NOTE_PREFIX = "[GravityUI] "

local function GetFont()
    local db = G.GetDB and G.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local fontPath = LSM and LSM:Fetch("font", fontName)
    return fontPath or [[Interface\AddOns\GravityUI\media\font\Gravity.ttf]]
end

local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if specIndex and specIndex > 0 then
        local specID, name, _, icon = GetSpecializationInfo(specIndex)
        return specID, name, icon
    end
    return nil, "Unknown", nil
end

local function GetCharKey()
    local name = UnitName("player") or "Player"
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or (GetRealmName() or "Realm")
    return (name .. "-" .. realm):gsub("%s+", "")
end

local function FormatDuration(seconds)
    if not seconds or seconds <= 0 then return "0:00" end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return ("%d:%02d (%ds)"):format(m, s, seconds)
end

---------------------------------------------------------------------------
-- COPY POPUP (TAINT-FREE EDITBOX DIALOG)
---------------------------------------------------------------------------
local copyPopup = nil
local function ShowCopyPopup(text)
    if not copyPopup then
        local p = CreateFrame("Frame", "GravityUI_CopyPopup", UIParent, "BackdropTemplate")
        p:SetSize(460, 120)
        p:SetPoint("CENTER")
        p:SetFrameStrata("DIALOG")
        p:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        })
        p:SetBackdropColor(0.06, 0.08, 0.10, 0.98)
        p:SetBackdropBorderColor(0.19, 0.82, 1.0, 1)

        local lbl = p:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(GetFont(), 12, "OUTLINE")
        lbl:SetPoint("TOPLEFT", 14, -12)
        lbl:SetText("|cFF30D1FFPress Ctrl+C to copy talent string:|r")

        local eb = CreateFrame("EditBox", nil, p, "BackdropTemplate")
        eb:SetPoint("TOPLEFT", 14, -36)
        eb:SetPoint("BOTTOMRIGHT", -14, 38)
        eb:SetFont(GetFont(), 10, "OUTLINE")
        eb:SetAutoFocus(true)
        eb:SetBackdrop({
            bgFile = [[Interface\Buttons\WHITE8x8]],
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = 1,
        })
        eb:SetBackdropColor(0.03, 0.04, 0.05, 1)
        eb:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)
        eb:SetTextInsets(6, 6, 0, 0)
        eb:SetScript("OnEscapePressed", function() p:Hide() end)
        eb:SetScript("OnEnterPressed", function() p:Hide() end)
        p.editBox = eb

        local close = CreateFrame("Button", nil, p, "BackdropTemplate")
        close:SetSize(80, 22)
        close:SetPoint("BOTTOMRIGHT", -14, 10)
        close:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
        close:SetBackdropColor(0.10, 0.13, 0.17, 0.8)
        close:SetBackdropBorderColor(0.25, 0.30, 0.38, 1)
        close.text = close:CreateFontString(nil, "OVERLAY")
        close.text:SetFont(GetFont(), 10, "OUTLINE")
        close.text:SetPoint("CENTER")
        close.text:SetText("Done")
        close:SetScript("OnClick", function() p:Hide() end)

        copyPopup = p
    end

    copyPopup.editBox:SetText(text or "")
    copyPopup.editBox:HighlightText()
    copyPopup:Show()
    copyPopup.editBox:SetFocus()
end

---------------------------------------------------------------------------
-- TALENT UI PREPARATION & ENTRY PARSER
---------------------------------------------------------------------------
local function EnsureTalentUILoaded()
    if not (C_AddOns and C_AddOns.LoadAddOn) then return end
    for _, name in ipairs({ "Blizzard_PlayerSpells", "Blizzard_ClassTalentUI" }) do
        if C_AddOns.IsAddOnLoadable and C_AddOns.IsAddOnLoadable(name) then
            pcall(C_AddOns.LoadAddOn, name)
        end
    end
end

local function GetBlizzardImportEntries(importString, configID)
    if not (ExportUtil and ExportUtil.MakeImportDataStream and C_Traits) then return nil end
    EnsureTalentUILoaded()
    local tab = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if not (tab and tab.ReadLoadoutHeader and tab.ReadLoadoutContent and tab.ConvertToImportLoadoutEntryInfo) then
        return nil
    end

    local specID = GetCurrentSpecID()
    local treeID = specID and C_ClassTalents.GetTraitTreeForSpec and C_ClassTalents.GetTraitTreeForSpec(specID)
    if not treeID then
        local cfg = C_Traits.GetConfigInfo(configID)
        treeID = cfg and cfg.treeIDs and cfg.treeIDs[1]
    end
    if not treeID then return nil end

    local ok, stream = pcall(ExportUtil.MakeImportDataStream, importString)
    if not ok or not stream then return nil end

    pcall(tab.ReadLoadoutHeader, tab, stream)
    local okC, content = pcall(tab.ReadLoadoutContent, tab, stream, treeID)
    if not okC or type(content) ~= "table" then return nil end

    local okE, entries = pcall(tab.ConvertToImportLoadoutEntryInfo, tab, configID, treeID, content)
    if not okE or type(entries) ~= "table" then return nil end

    return entries, treeID
end

local function FindManagedConfigID(specID)
    local configIDs = C_ClassTalents.GetConfigIDsBySpecID and C_ClassTalents.GetConfigIDsBySpecID(specID)
    if configIDs then
        for _, cfgID in ipairs(configIDs) do
            local id = (type(cfgID) == "table" and cfgID.ID) or (type(cfgID) == "number" and cfgID)
            if id then
                local info = C_Traits.GetConfigInfo(id)
                if info and info.name == LOADOUT_NAME then
                    return id
                end
            end
        end
    end
    return nil
end

local function DeleteManagedConfig(specID)
    local cid = FindManagedConfigID(specID)
    local activeId = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    if cid then
        if cid == activeId then
            local configIDs = C_ClassTalents.GetConfigIDsBySpecID and C_ClassTalents.GetConfigIDsBySpecID(specID)
            if configIDs then
                for _, otherID in ipairs(configIDs) do
                    local id = (type(otherID) == "table" and otherID.ID) or (type(otherID) == "number" and otherID)
                    if id and id ~= cid then
                        pcall(C_ClassTalents.LoadConfig, id, false)
                        break
                    end
                end
            end
        end
        pcall(C_ClassTalents.DeleteConfig, cid)
    end
end

---------------------------------------------------------------------------
-- ASYNC TALENT COMMIT & SELECTION WATCHER
---------------------------------------------------------------------------
local applyGen = 0
local pendingCreate = nil
local createWatcher = CreateFrame("Frame")

local errorsMuted = false
local function MuteUIErrors(on)
    if on == errorsMuted or not UIErrorsFrame then return end
    errorsMuted = on
    if on then
        UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    else
        UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
    end
end

local function SelectLoadout(configID, specID)
    if C_ClassTalents and C_ClassTalents.SetUsesSharedActionBars then
        pcall(C_ClassTalents.SetUsesSharedActionBars, configID, true)
    end
    if specID and C_ClassTalents.UpdateLastSelectedSavedConfigID then
        pcall(C_ClassTalents.UpdateLastSelectedSavedConfigID, specID, configID)
    end
    local tf = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if tf then
        if tf.SetSelectedSavedConfigID then
            pcall(tf.SetSelectedSavedConfigID, tf, configID, false, true)
        end
        tf.isConfigReadyToApply = false
        if tf.UpdateConfigButtonsState then pcall(tf.UpdateConfigButtonsState, tf) end
    end
end

local function SyncApplyButton()
    local tf = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if tf then
        tf.isConfigReadyToApply = false
        if tf.UpdateConfigButtonsState then pcall(tf.UpdateConfigButtonsState, tf) end
    end
end

local function EnsureCommitted(configID, specID, gen, autoCommit, committed, tries)
    if gen ~= applyGen then return end

    local tf = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    local pending = tf and tf.HasAnyConfigChanges and tf:HasAnyConfigChanges()
    local committing = tf and tf.IsCommitInProgress and tf:IsCommitInProgress()

    if not pending then
        MuteUIErrors(false)
        if C_ClassTalents and C_ClassTalents.SetUsesSharedActionBars then
            pcall(C_ClassTalents.SetUsesSharedActionBars, configID, true)
        end
        SelectLoadout(configID, specID)
        C_Timer.After(1.0, function() if gen == applyGen then SelectLoadout(configID, specID) end end)
        C_Timer.After(3.0, function() if gen == applyGen then SyncApplyButton() end end)
        print(("|cFF30D1FFGravityUI|r: |cFF00FF88Applied build to '%s' loadout!|r"):format(LOADOUT_NAME))
        return
    end

    if tries >= 18 then
        MuteUIErrors(false)
        SelectLoadout(configID, specID)
        print(("|cFF30D1FFGravityUI|r: |cFFFFD100Saved build to '%s'. Open Talents and click 'Apply Changes'.|r"):format(LOADOUT_NAME))
        return
    end

    if not committed and not committing and C_ClassTalents.CommitConfig and ((not autoCommit) or tries >= 14) then
        pcall(C_ClassTalents.CommitConfig, configID)
        committed = true
    end

    C_Timer.After(0.5, function() EnsureCommitted(configID, specID, gen, autoCommit, committed, tries + 1) end)
end

local function LoadAndApply(configID, specID, gen, attempt)
    attempt = attempt or 1
    if gen ~= applyGen then return end

    if attempt == 1 then
        MuteUIErrors(true)
        C_Timer.After(12, function() MuteUIErrors(false) end)
    end

    local R = (Enum and Enum.LoadConfigResult) or {}
    local lok, result, changeErr = pcall(C_ClassTalents.LoadConfig, configID, true)

    if (not lok) or result == R.Error then
        if attempt < 4 then
            C_Timer.After(0.6, function() LoadAndApply(configID, specID, gen, attempt + 1) end)
        else
            MuteUIErrors(false)
            print(("|cFF30D1FFGravityUI|r: |cFFFFD100Saved build to '%s'. Open Talents and click 'Apply Changes'.|r"):format(LOADOUT_NAME))
        end
        return
    end

    local autoCommit = (result == R.LoadInProgress)
    C_Timer.After(0.8, function() EnsureCommitted(configID, specID, gen, autoCommit, false, 1) end)
end

local function FinishLoadout(configID)
    local p = pendingCreate
    pendingCreate = nil
    createWatcher:UnregisterAllEvents()
    if not p then return end
    LoadAndApply(configID, p.specID, p.gen)
end

createWatcher:SetScript("OnEvent", function(_, event, arg1)
    if not pendingCreate then return end
    if event == "TRAIT_CONFIG_CREATED" then
        local combat = Enum.TraitConfigType and Enum.TraitConfigType.Combat
        if type(arg1) == "table" and (not combat or arg1.type == combat) then
            local configID = arg1.ID
            if C_ClassTalents.IsConfigPopulated and not C_ClassTalents.IsConfigPopulated(configID) then
                pendingCreate.awaitPopulate = configID
            else
                FinishLoadout(configID)
            end
        end
    elseif event == "TRAIT_CONFIG_UPDATED" then
        if pendingCreate and pendingCreate.awaitPopulate and arg1 == pendingCreate.awaitPopulate then
            FinishLoadout(arg1)
        end
    end
end)

---------------------------------------------------------------------------
-- CORE LOGIC: TALENTS IMPORT
---------------------------------------------------------------------------
function BossLoadouts:ApplyTalents(talentString, customName)
    if not talentString or talentString == "" then
        print("|cFF30D1FFGravityUI|r: |cFFFF5555No talent string available for this selection.|r")
        return false
    end

    if InCombatLockdown() then
        print("|cFF30D1FFGravityUI|r: |cFFFF8000Cannot change talents in combat.|r")
        return false
    end

    local specID = GetCurrentSpecID()
    if not specID then
        print("|cFF30D1FFGravityUI|r: |cFFFF5555Could not determine player specialization.|r")
        return false
    end

    local configID = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    if not configID then
        local configIDs = C_ClassTalents.GetConfigIDsBySpecID and C_ClassTalents.GetConfigIDsBySpecID(specID)
        configID = configIDs and configIDs[1]
    end

    if not configID then
        print("|cFF30D1FFGravityUI|r: |cFFFF5555No active talent configuration found.|r")
        return false
    end

    EnsureTalentUILoaded()

    -- Turn off starter build if active
    if C_ClassTalents.GetStarterBuildActive and C_ClassTalents.GetStarterBuildActive() then
        pcall(C_ClassTalents.SetStarterBuildActive, false)
    end

    local entries, treeID = GetBlizzardImportEntries(talentString, configID)
    if not (entries and #entries > 0) then
        ShowCopyPopup(talentString)
        return false
    end

    if not C_ClassTalents.ImportLoadout then
        print("|cFF30D1FFGravityUI|r: |cFFFF5555Game client cannot create talent loadouts.|r")
        return false
    end

    -- Clean old managed loadout
    DeleteManagedConfig(specID)

    applyGen = applyGen + 1
    pendingCreate = { specID = specID, gen = applyGen }
    createWatcher:RegisterEvent("TRAIT_CONFIG_CREATED")
    createWatcher:RegisterEvent("TRAIT_CONFIG_UPDATED")

    local pOK, success, errStr = pcall(C_ClassTalents.ImportLoadout, configID, entries, LOADOUT_NAME, talentString)
    if not pOK or not success then
        pendingCreate = nil
        createWatcher:UnregisterAllEvents()
        ShowCopyPopup(talentString)
        return false
    end

    -- Timeout safety net
    C_Timer.After(6, function()
        if pendingCreate and pendingCreate.specID == specID then
            pendingCreate = nil
            createWatcher:UnregisterAllEvents()
        end
    end)

    return true
end

---------------------------------------------------------------------------
-- CORE LOGIC: NSRT PERSONAL NOTES INJECTION
---------------------------------------------------------------------------
function BossLoadouts:SendToNSRT(encID, difficulty, reminders, bossName)
    local nsrtDB = _G["NSRT"]
    local nsrtAddon = _G["NorthernSkyRaidTools"]
    if not nsrtDB then
        print("|cFF30D1FFGravityUI|r: |cFFFF8000Northern Sky Raid Tools (NSRT) database not found.|r")
        return false
    end

    if not (reminders and #reminders > 0) then
        print("|cFF30D1FFGravityUI|r: |cFFFF5555No cooldown reminders found for this boss.|r")
        return false
    end

    local playerName = UnitName("player") or "Player"
    local cleanBoss = bossName or "Boss"
    local noteKey = NOTE_PREFIX .. cleanBoss

    local lines = {
        ("EncounterID:%d;Difficulty:%s;Name:%s"):format(encID, difficulty, cleanBoss)
    }

    for _, r in ipairs(reminders) do
        local parts = {
            ("time:%d"):format(r.time),
            ("ph:%d"):format(r.ph or 1),
            ("tag:%s"):format(playerName),
            ("spellid:%d"):format(r.spellid),
        }
        lines[#lines + 1] = table.concat(parts, ";") .. ";"
    end

    local noteText = table.concat(lines, "\n") .. "\n"

    -- 1. Write directly to NSRT SavedVariables
    nsrtDB.PersonalReminders = nsrtDB.PersonalReminders or {}
    nsrtDB.PersonalReminders[noteKey] = noteText

    local charKey = (nsrtAddon and nsrtAddon.GetProfileKey and nsrtAddon:GetProfileKey()) or GetCharKey()
    nsrtDB.ActivePersonalReminder = nsrtDB.ActivePersonalReminder or {}
    nsrtDB.ActivePersonalReminder[charKey] = nsrtDB.ActivePersonalReminder[charKey] or {}
    nsrtDB.ActivePersonalReminder[charKey][encID] = noteKey

    nsrtDB.StoredPersonalReminder = nsrtDB.StoredPersonalReminder or {}
    nsrtDB.StoredPersonalReminder[charKey] = noteKey

    nsrtDB.ReminderSettings = nsrtDB.ReminderSettings or {}
    nsrtDB.ReminderSettings.PersNote = true

    -- 2. Call NSRT runtime handler if active
    if nsrtAddon then
        nsrtAddon.PersonalReminder = noteText
        nsrtAddon.LoadedPersonalReminder = noteKey
        if nsrtAddon.SetReminder then
            pcall(nsrtAddon.SetReminder, nsrtAddon, noteKey, true)
        end
        if nsrtAddon.UpdatePersonalNote then
            pcall(nsrtAddon.UpdatePersonalNote, nsrtAddon)
        end
    end

    -- 3. Refresh NSRT UI if open
    if _G.NSUI and _G.NSUI.personal_reminders_frame and _G.NSUI.personal_reminders_frame.scrollbox then
        pcall(_G.NSUI.personal_reminders_frame.scrollbox.MasterRefresh, _G.NSUI.personal_reminders_frame.scrollbox)
    end

    print(("|cFF30D1FFGravityUI|r: |cFF00FF88Sent %d cooldown reminders to NSRT Personal Notes for %s (%s)!|r"):format(#reminders, cleanBoss, difficulty))
    return true
end

---------------------------------------------------------------------------
-- MASTER ONE-CLICK APPLY (TARGETING SELECTED VARIANT)
---------------------------------------------------------------------------
function BossLoadouts:ApplyBossSetup(encID, difficulty, variantIndex)
    local data = G.BossLoadoutsData and G.BossLoadoutsData.Plans and G.BossLoadoutsData.Plans[encID]
    local diffData = data and data[difficulty]
    local specID = GetCurrentSpecID()
    local variants = diffData and specID and diffData[specID]
    local plan = variants and (variants[variantIndex or 1] or variants[1])

    local encInfo = G.BossLoadoutsData and G.BossLoadoutsData.Encounters and G.BossLoadoutsData.Encounters[encID]
    local bossName = (encInfo and encInfo.name) or "Boss"

    if not plan then
        print(("|cFF30D1FFGravityUI|r: |cFFFF5555No data found for %s (%s) on current spec.|r"):format(bossName, difficulty))
        return
    end

    -- 1. Talents
    if plan.talents then
        self:ApplyTalents(plan.talents, LOADOUT_NAME)
    else
        print("|cFF30D1FFGravityUI|r: |cFFFF8000No talent string available in log data.|r")
    end

    -- 2. NSRT Reminders
    if plan.reminders and #plan.reminders > 0 then
        self:SendToNSRT(encID, difficulty, plan.reminders, bossName)
    end
end

---------------------------------------------------------------------------
-- UI FRAME CREATION
---------------------------------------------------------------------------
local UIFrame = nil
local selectedBossID = 3470 -- Default: Nek'zali the Soulcoiler
local selectedDiff = "Mythic"
local selectedVariantIdx = 1

local ENCOUNTER_ORDER = { 3470, 3445, 3497, 3455, 3420, 3421, 3429, 3492, 3379 }

function BossLoadouts:CreateUI()
    if UIFrame then return UIFrame end

    local f = CreateFrame("Frame", "GravityUI_BossLoadoutsFrame", UIParent, "BackdropTemplate")
    f:SetSize(720, 520)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")

    -- Modern Backdrop
    f:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    f:SetBackdropColor(0.06, 0.07, 0.09, 0.96)
    f:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)

    tinsert(UISpecialFrames, f:GetName())

    -- Header Bar
    local header = CreateFrame("Frame", nil, f, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(38)
    header:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    header:SetBackdropColor(0.09, 0.11, 0.14, 1)
    header:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(GetFont(), 14, "OUTLINE")
    title:SetPoint("LEFT", 14, 0)
    title:SetText("|cFF30D1FFGravityUI|r |cFFFFFFFFBoss Loadouts & Reminders|r")

    -- Clean ASCII close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("RIGHT", -6, 0)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(GetFont(), 13, "OUTLINE")
    closeText:SetPoint("CENTER")
    closeText:SetText("|cFF888888X|r")

    closeBtn:SetScript("OnEnter", function() closeText:SetText("|cFFFF5555X|r") end)
    closeBtn:SetScript("OnLeave", function() closeText:SetText("|cFF888888X|r") end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -----------------------------------------------------------------------
    -- LEFT PANEL: BOSS LIST
    -----------------------------------------------------------------------
    local listContainer = CreateFrame("Frame", nil, f, "BackdropTemplate")
    listContainer:SetPoint("TOPLEFT", 12, -50)
    listContainer:SetPoint("BOTTOMLEFT", 12, 14)
    listContainer:SetWidth(190)
    listContainer:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    listContainer:SetBackdropColor(0.04, 0.05, 0.07, 0.85)
    listContainer:SetBackdropBorderColor(0.14, 0.16, 0.20, 1)

    local listLabel = listContainer:CreateFontString(nil, "OVERLAY")
    listLabel:SetFont(GetFont(), 10, "OUTLINE")
    listLabel:SetPoint("TOPLEFT", 8, -8)
    listLabel:SetText("|cFF30D1FFRAID ENCOUNTERS|r")

    local bossButtons = {}

    local function SelectBoss(encID)
        selectedBossID = encID
        selectedVariantIdx = 1
        for id, btn in pairs(bossButtons) do
            if id == encID then
                btn.bg:SetColorTexture(0.19, 0.82, 1.0, 0.25)
                btn.border:SetColorTexture(0.19, 0.82, 1.0, 1)
                btn.text:SetTextColor(0.19, 0.82, 1.0, 1)
            else
                btn.bg:SetColorTexture(0.08, 0.10, 0.13, 0.6)
                btn.border:SetColorTexture(0.14, 0.16, 0.20, 1)
                btn.text:SetTextColor(0.8, 0.8, 0.8, 1)
            end
        end
        f:RefreshDetails()
    end

    local yOff = -26
    for _, encID in ipairs(ENCOUNTER_ORDER) do
        local enc = G.BossLoadoutsData and G.BossLoadoutsData.Encounters and G.BossLoadoutsData.Encounters[encID]
        if enc then
            local btn = CreateFrame("Button", nil, listContainer)
            btn:SetSize(174, 42)
            btn:SetPoint("TOPLEFT", 8, yOff)

            btn.bg = btn:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetAllPoints()
            btn.bg:SetColorTexture(0.08, 0.10, 0.13, 0.6)

            btn.border = btn:CreateTexture(nil, "OVERLAY")
            btn.border:SetPoint("TOPLEFT")
            btn.border:SetPoint("BOTTOMLEFT")
            btn.border:SetWidth(2)
            btn.border:SetColorTexture(0.14, 0.16, 0.20, 1)

            btn.text = btn:CreateFontString(nil, "OVERLAY")
            btn.text:SetFont(GetFont(), 11, "OUTLINE")
            btn.text:SetPoint("LEFT", 8, 5)
            btn.text:SetText(enc.name)
            btn.text:SetJustifyH("LEFT")

            btn.sub = btn:CreateFontString(nil, "OVERLAY")
            btn.sub:SetFont(GetFont(), 9, "OUTLINE")
            btn.sub:SetPoint("LEFT", 8, -10)
            btn.sub:SetText("|cFF888888" .. enc.raid .. "|r")
            btn.sub:SetJustifyH("LEFT")

            btn:SetScript("OnClick", function()
                SelectBoss(encID)
            end)

            bossButtons[encID] = btn
            yOff = yOff - 46
        end
    end

    -----------------------------------------------------------------------
    -- RIGHT PANEL: DETAILS & ACTIONS
    -----------------------------------------------------------------------
    local details = CreateFrame("Frame", nil, f, "BackdropTemplate")
    details:SetPoint("TOPLEFT", listContainer, "TOPRIGHT", 12, 0)
    details:SetPoint("BOTTOMRIGHT", -12, 14)
    details:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    details:SetBackdropColor(0.04, 0.05, 0.07, 0.85)
    details:SetBackdropBorderColor(0.14, 0.16, 0.20, 1)
    f.details = details

    -- Difficulty Selector Buttons
    local mythicBtn = CreateFrame("Button", nil, details, "BackdropTemplate")
    mythicBtn:SetSize(85, 26)
    mythicBtn:SetPoint("TOPRIGHT", -12, -10)
    mythicBtn:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    mythicBtn.text = mythicBtn:CreateFontString(nil, "OVERLAY")
    mythicBtn.text:SetFont(GetFont(), 11, "OUTLINE")
    mythicBtn.text:SetPoint("CENTER")
    mythicBtn.text:SetText("Mythic")

    local heroicBtn = CreateFrame("Button", nil, details, "BackdropTemplate")
    heroicBtn:SetSize(85, 26)
    heroicBtn:SetPoint("RIGHT", mythicBtn, "LEFT", -6, 0)
    heroicBtn:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    heroicBtn.text = heroicBtn:CreateFontString(nil, "OVERLAY")
    heroicBtn.text:SetFont(GetFont(), 11, "OUTLINE")
    heroicBtn.text:SetPoint("CENTER")
    heroicBtn.text:SetText("Heroic")

    local function SetDifficulty(diff)
        selectedDiff = diff
        selectedVariantIdx = 1
        if diff == "Mythic" then
            mythicBtn:SetBackdropColor(0.95, 0.45, 0.15, 0.3)
            mythicBtn:SetBackdropBorderColor(0.95, 0.45, 0.15, 1)
            mythicBtn.text:SetTextColor(0.95, 0.45, 0.15, 1)
            heroicBtn:SetBackdropColor(0.08, 0.10, 0.13, 0.6)
            heroicBtn:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)
            heroicBtn.text:SetTextColor(0.6, 0.6, 0.6, 1)
        else
            heroicBtn:SetBackdropColor(0.30, 0.70, 1.0, 0.3)
            heroicBtn:SetBackdropBorderColor(0.30, 0.70, 1.0, 1)
            heroicBtn.text:SetTextColor(0.30, 0.70, 1.0, 1)
            mythicBtn:SetBackdropColor(0.08, 0.10, 0.13, 0.6)
            mythicBtn:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)
            mythicBtn.text:SetTextColor(0.6, 0.6, 0.6, 1)
        end
        f:RefreshDetails()
    end

    mythicBtn:SetScript("OnClick", function() SetDifficulty("Mythic") end)
    heroicBtn:SetScript("OnClick", function() SetDifficulty("Heroic") end)

    -- Header Info
    details.bossHeader = details:CreateFontString(nil, "OVERLAY")
    details.bossHeader:SetFont(GetFont(), 15, "OUTLINE")
    details.bossHeader:SetPoint("TOPLEFT", 14, -14)
    details.bossHeader:SetText("Nek'zali the Soulcoiler")

    -----------------------------------------------------------------------
    -- TOP LOGS / BUILDS SELECTOR LIST
    -----------------------------------------------------------------------
    local logsHeader = details:CreateFontString(nil, "OVERLAY")
    logsHeader:SetFont(GetFont(), 10, "OUTLINE")
    logsHeader:SetPoint("TOPLEFT", 14, -46)
    logsHeader:SetText("|cFF30D1FFAVAILABLE TOP LOGS & TIMELINES (SELECT ONE):|r")

    local logsContainer = CreateFrame("Frame", nil, details, "BackdropTemplate")
    logsContainer:SetPoint("TOPLEFT", 14, -62)
    logsContainer:SetPoint("TOPRIGHT", -14, -62)
    logsContainer:SetHeight(150)
    logsContainer:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    logsContainer:SetBackdropColor(0.06, 0.08, 0.10, 0.9)
    logsContainer:SetBackdropBorderColor(0.16, 0.20, 0.26, 1)
    f.logsContainer = logsContainer

    local logButtons = {}

    local function CreateLogButton(i)
        local btn = CreateFrame("Button", nil, logsContainer, "BackdropTemplate")
        btn:SetSize(466, 26)
        btn:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
        btn:SetBackdropColor(0.08, 0.10, 0.13, 0.6)
        btn:SetBackdropBorderColor(0.14, 0.16, 0.20, 1)

        btn.rank = btn:CreateFontString(nil, "OVERLAY")
        btn.rank:SetFont(GetFont(), 11, "OUTLINE")
        btn.rank:SetPoint("LEFT", 8, 0)

        btn.duration = btn:CreateFontString(nil, "OVERLAY")
        btn.duration:SetFont(GetFont(), 11, "OUTLINE")
        btn.duration:SetPoint("RIGHT", -8, 0)

        btn:SetScript("OnClick", function()
            selectedVariantIdx = i
            f:RefreshDetails()
        end)

        return btn
    end

    for i = 1, 5 do
        logButtons[i] = CreateLogButton(i)
        logButtons[i]:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 28)
    end
    f.logButtons = logButtons

    -----------------------------------------------------------------------
local function FormatDPS(dps)
    if not dps or dps <= 0 then return "" end
    if dps >= 1000000 then
        return ("%.2fM DPS"):format(dps / 1000000)
    elseif dps >= 1000 then
        return ("%.1fk DPS"):format(dps / 1000)
    else
        return ("%d DPS"):format(dps)
    end
end

---------------------------------------------------------------------------
-- SUMMARY CARD FOR SELECTED VARIANT
---------------------------------------------------------------------------
    local card = CreateFrame("Frame", nil, details, "BackdropTemplate")
    card:SetPoint("TOPLEFT", logsContainer, "BOTTOMLEFT", 0, -10)
    card:SetPoint("TOPRIGHT", logsContainer, "BOTTOMRIGHT", 0, -10)
    card:SetHeight(100)
    card:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    card:SetBackdropColor(0.07, 0.09, 0.12, 0.92)
    card:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)

    card.specIcon = card:CreateTexture(nil, "ARTWORK")
    card.specIcon:SetSize(38, 38)
    card.specIcon:SetPoint("TOPLEFT", 12, -12)
    card.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    card.specName = card:CreateFontString(nil, "OVERLAY")
    card.specName:SetFont(GetFont(), 13, "OUTLINE")
    card.specName:SetPoint("TOPLEFT", card.specIcon, "TOPRIGHT", 10, 2)

    card.heroBadge = card:CreateFontString(nil, "OVERLAY")
    card.heroBadge:SetFont(GetFont(), 11, "OUTLINE")
    card.heroBadge:SetPoint("LEFT", card.specName, "RIGHT", 8, 0)

    card.talentStatus = card:CreateFontString(nil, "OVERLAY")
    card.talentStatus:SetFont(GetFont(), 11, "OUTLINE")
    card.talentStatus:SetPoint("TOPRIGHT", -12, -12)

    -- Left Column Info
    card.selectedLog = card:CreateFontString(nil, "OVERLAY")
    card.selectedLog:SetFont(GetFont(), 11, "OUTLINE")
    card.selectedLog:SetPoint("TOPLEFT", card.specIcon, "BOTTOMLEFT", 0, -8)

    card.heroTree = card:CreateFontString(nil, "OVERLAY")
    card.heroTree:SetFont(GetFont(), 11, "OUTLINE")
    card.heroTree:SetPoint("TOPLEFT", card.selectedLog, "BOTTOMLEFT", 0, -4)

    -- Right Column Info
    card.duration = card:CreateFontString(nil, "OVERLAY")
    card.duration:SetFont(GetFont(), 11, "OUTLINE")
    card.duration:SetPoint("TOPLEFT", card, "CENTER", 20, 4)

    card.dps = card:CreateFontString(nil, "OVERLAY")
    card.dps:SetFont(GetFont(), 11, "OUTLINE")
    card.dps:SetPoint("TOPLEFT", card.duration, "BOTTOMLEFT", 0, -4)

    card.remindersCount = card:CreateFontString(nil, "OVERLAY")
    card.remindersCount:SetFont(GetFont(), 11, "OUTLINE")
    card.remindersCount:SetPoint("TOPLEFT", card.dps, "BOTTOMLEFT", 0, -4)

    f.card = card

    -- Notice Box
    local notice = details:CreateFontString(nil, "OVERLAY")
    notice:SetFont(GetFont(), 9.5, "OUTLINE")
    notice:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -8)
    notice:SetPoint("TOPRIGHT", card, "BOTTOMRIGHT", 0, -8)
    notice:SetJustifyH("LEFT")
    notice:SetText("|cFF30D1FFInfo:|r Reuses the loadout |cFF00FF88GravityUI: Talents|r and updates NSRT Personal Notes for this kill timeline.")
    f.notice = notice

    -----------------------------------------------------------------------
    -- ACTION BUTTONS
    -----------------------------------------------------------------------
    -- 1. Main Action Button
    local applyAllBtn = CreateFrame("Button", nil, details, "BackdropTemplate")
    applyAllBtn:SetSize(456, 36)
    applyAllBtn:SetPoint("BOTTOM", 0, 72)
    applyAllBtn:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    applyAllBtn:SetBackdropColor(0.19, 0.82, 1.0, 0.25)
    applyAllBtn:SetBackdropBorderColor(0.19, 0.82, 1.0, 1)

    applyAllBtn.text = applyAllBtn:CreateFontString(nil, "OVERLAY")
    applyAllBtn.text:SetFont(GetFont(), 13, "OUTLINE")
    applyAllBtn.text:SetPoint("CENTER")
    applyAllBtn.text:SetText("Apply Talents & NSRT Notes")

    applyAllBtn:SetScript("OnClick", function()
        BossLoadouts:ApplyBossSetup(selectedBossID, selectedDiff, selectedVariantIdx)
    end)
    applyAllBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.19, 0.82, 1.0, 0.45)
    end)
    applyAllBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.19, 0.82, 1.0, 0.25)
    end)

    -- 2. Talents Only Button
    local talentsOnlyBtn = CreateFrame("Button", nil, details, "BackdropTemplate")
    talentsOnlyBtn:SetSize(224, 28)
    talentsOnlyBtn:SetPoint("TOPLEFT", applyAllBtn, "BOTTOMLEFT", 0, -6)
    talentsOnlyBtn:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    talentsOnlyBtn:SetBackdropColor(0.10, 0.13, 0.17, 0.8)
    talentsOnlyBtn:SetBackdropBorderColor(0.25, 0.30, 0.38, 1)

    talentsOnlyBtn.text = talentsOnlyBtn:CreateFontString(nil, "OVERLAY")
    talentsOnlyBtn.text:SetFont(GetFont(), 11, "OUTLINE")
    talentsOnlyBtn.text:SetPoint("CENTER")
    talentsOnlyBtn.text:SetText("Apply Talents Only")

    talentsOnlyBtn:SetScript("OnClick", function()
        local data = G.BossLoadoutsData and G.BossLoadoutsData.Plans and G.BossLoadoutsData.Plans[selectedBossID]
        local diffData = data and data[selectedDiff]
        local specID = GetCurrentSpecID()
        local variants = diffData and specID and diffData[specID]
        local plan = variants and (variants[selectedVariantIdx] or variants[1])
        if plan and plan.talents then
            BossLoadouts:ApplyTalents(plan.talents, LOADOUT_NAME)
        else
            print("|cFF30D1FFGravityUI|r: |cFFFF8000No talent string available.|r")
        end
    end)

    -- 3. NSRT Notes Only Button
    local nsrtOnlyBtn = CreateFrame("Button", nil, details, "BackdropTemplate")
    nsrtOnlyBtn:SetSize(224, 28)
    nsrtOnlyBtn:SetPoint("TOPRIGHT", applyAllBtn, "BOTTOMRIGHT", 0, -6)
    nsrtOnlyBtn:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    nsrtOnlyBtn:SetBackdropColor(0.10, 0.13, 0.17, 0.8)
    nsrtOnlyBtn:SetBackdropBorderColor(0.25, 0.30, 0.38, 1)

    nsrtOnlyBtn.text = nsrtOnlyBtn:CreateFontString(nil, "OVERLAY")
    nsrtOnlyBtn.text:SetFont(GetFont(), 11, "OUTLINE")
    nsrtOnlyBtn.text:SetPoint("CENTER")
    nsrtOnlyBtn.text:SetText("Set NSRT Note Only")

    nsrtOnlyBtn:SetScript("OnClick", function()
        local data = G.BossLoadoutsData and G.BossLoadoutsData.Plans and G.BossLoadoutsData.Plans[selectedBossID]
        local diffData = data and data[selectedDiff]
        local specID = GetCurrentSpecID()
        local variants = diffData and specID and diffData[specID]
        local plan = variants and (variants[selectedVariantIdx] or variants[1])
        local encInfo = G.BossLoadoutsData and G.BossLoadoutsData.Encounters and G.BossLoadoutsData.Encounters[selectedBossID]
        local bossName = (encInfo and encInfo.name) or "Boss"

        if plan and plan.reminders then
            BossLoadouts:SendToNSRT(selectedBossID, selectedDiff, plan.reminders, bossName)
        else
            print("|cFF30D1FFGravityUI|r: |cFFFF8000No cooldown reminders available.|r")
        end
    end)

    -- 4. Copy Code Button
    local copyBtn = CreateFrame("Button", nil, details, "BackdropTemplate")
    copyBtn:SetSize(456, 20)
    copyBtn:SetPoint("TOP", talentsOnlyBtn, "BOTTOM", 116, -6)
    copyBtn:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8x8]], edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1 })
    copyBtn:SetBackdropColor(0.06, 0.08, 0.10, 0.5)
    copyBtn:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.8)

    copyBtn.text = copyBtn:CreateFontString(nil, "OVERLAY")
    copyBtn.text:SetFont(GetFont(), 9.5, "OUTLINE")
    copyBtn.text:SetPoint("CENTER")
    copyBtn.text:SetText("|cFF888888Copy Talent Code to Clipboard|r")

    copyBtn:SetScript("OnClick", function()
        local data = G.BossLoadoutsData and G.BossLoadoutsData.Plans and G.BossLoadoutsData.Plans[selectedBossID]
        local diffData = data and data[selectedDiff]
        local specID = GetCurrentSpecID()
        local variants = diffData and specID and diffData[specID]
        local plan = variants and (variants[selectedVariantIdx] or variants[1])
        if plan and plan.talents then
            ShowCopyPopup(plan.talents)
        end
    end)

    -----------------------------------------------------------------------
    -- REFRESH DETAILS
    -----------------------------------------------------------------------
    function f:RefreshDetails()
        local enc = G.BossLoadoutsData and G.BossLoadoutsData.Encounters and G.BossLoadoutsData.Encounters[selectedBossID]
        details.bossHeader:SetText((enc and enc.name) or "Unknown Encounter")

        local specID, specName, specIcon = GetCurrentSpecID()
        if specIcon then
            card.specIcon:SetTexture(specIcon)
        else
            card.specIcon:SetColorTexture(0.2, 0.2, 0.2, 1)
        end
        card.specName:SetText("|cFFFFFFFF" .. (specName or "Current Spec") .. "|r")

        local data = G.BossLoadoutsData and G.BossLoadoutsData.Plans and G.BossLoadoutsData.Plans[selectedBossID]
        local diffData = data and data[selectedDiff]
        local variants = diffData and specID and diffData[specID]

local function CleanPlayerName(name)
    if not name then return "Unknown" end
    return (name:gsub("^Top%s*#%d+%s*:%s*", ""):gsub("^Top%s*#%d+%s*", ""))
end

        -- Populate Log Buttons
        for i = 1, 5 do
            local btn = logButtons[i]
            local v = variants and variants[i]
            if v then
                btn:Show()
                local isSelected = (i == selectedVariantIdx)
                local pName = CleanPlayerName(v.player or v.name or ("Player #" .. i))
                local dpsText = (v.dps and v.dps > 0) and ("   •   " .. FormatDPS(v.dps)) or ""

                if isSelected then
                    btn:SetBackdropColor(0.19, 0.82, 1.0, 0.25)
                    btn:SetBackdropBorderColor(0.19, 0.82, 1.0, 1)
                    btn.rank:SetText(("|cFF30D1FFTop #%d:|r |cFFFFFFFF%s|r"):format(i, pName))
                    btn.duration:SetText(("|cFF30D1FFKill Duration: %s%s|r"):format(FormatDuration(v.duration), dpsText))
                else
                    btn:SetBackdropColor(0.08, 0.10, 0.13, 0.6)
                    btn:SetBackdropBorderColor(0.14, 0.16, 0.20, 1)
                    btn.rank:SetText(("|cFFFFD100Top #%d:|r |cFFCCCCCC%s|r"):format(i, pName))
                    btn.duration:SetText(("|cFF888888Kill Duration: %s%s|r"):format(FormatDuration(v.duration), dpsText))
                end
            else
                btn:Hide()
            end
        end

        local plan = variants and (variants[selectedVariantIdx] or variants[1])

        if plan then
            local pName = CleanPlayerName(plan.player or plan.name or "Top Log")
            card.heroBadge:SetText((plan.hero and plan.hero ~= "") and ("|cFF00FFCC[" .. plan.hero .. "]|r") or "")
            card.selectedLog:SetText(("|cFF888888Selected Log:|r |cFFFFD100Top #%d: %s|r"):format(selectedVariantIdx, pName))
            card.heroTree:SetText(("|cFF888888Hero Tree:|r |cFF00FFCC%s|r"):format(plan.hero or "Default"))

            card.duration:SetText(("|cFF888888Duration:|r |cFFFFFFFF%s|r"):format(FormatDuration(plan.duration)))
            local dpsStr = (plan.dps and plan.dps > 0) and FormatDPS(plan.dps) or "N/A"
            card.dps:SetText(("|cFF888888DPS:|r |cFFFF9933%s|r"):format(dpsStr))

            local remCount = plan.reminders and #plan.reminders or 0
            card.remindersCount:SetText(("|cFF888888Reminders:|r |cFF30D1FF%d Timestamps|r"):format(remCount))

            if plan.talents then
                card.talentStatus:SetText("|cFF00FF88● Talent Build Ready|r")
            else
                card.talentStatus:SetText("|cFFFF8000○ No Talent String|r")
            end
        else
            card.heroBadge:SetText("")
            card.selectedLog:SetText("|cFF888888No data available for this spec/difficulty.|r")
            card.heroTree:SetText("")
            card.duration:SetText("")
            card.dps:SetText("")
            card.remindersCount:SetText("")
            card.talentStatus:SetText("|cFFFF5555● Unavailable|r")
        end
    end

    -- Event listener for automatic spec change updates
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    f:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_SPECIALIZATION_CHANGED" and (not unit or unit == "player") then
            if self:IsShown() then
                self:RefreshDetails()
            end
        end
    end)

    -- Initial state: explicitly hidden
    f:Hide()
    SetDifficulty("Mythic")
    SelectBoss(3470)

    UIFrame = f
    return f
end

function BossLoadouts:ToggleUI()
    local f = self:CreateUI()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        f:RefreshDetails()
    end
end

---------------------------------------------------------------------------
-- SLASH COMMAND REGISTRATION
---------------------------------------------------------------------------
SLASH_GRAVITYBOSS1 = "/gravityboss"
SLASH_GRAVITYBOSS2 = "/guiboss"
SlashCmdList["GRAVITYBOSS"] = function(msg)
    BossLoadouts:ToggleUI()
end
