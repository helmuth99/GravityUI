local ADDON_NAME, ns = ...

-- ============================================================================
-- GravityUI: Custom Sounds in Blizzard CooldownViewer
-- Injects LibSharedMedia sounds into the Blizzard Alert dropdown
-- ============================================================================

local SoundAlerts = {}
ns.SoundAlerts = SoundAlerts

local CUSTOM_PAYLOAD_START = -200000  -- Use far negative range to avoid conflicts with Blizzard enums
local GRAVITY_MENU_LABEL   = "GravityUI"

local hooksInstalled = false
local refreshRequired = false

-- ============================================================================
-- SETTINGS
-- ============================================================================
local function GetSettings()
    local db = ns.GetDB()
    if not db then return nil end
    if not db.soundAlerts then
        db.soundAlerts = { enabled = false }
    end
    
    local saDB = db.soundAlerts
    if type(saDB.payloadMeta) ~= "table" then saDB.payloadMeta = {} end
    if type(saDB.sharedMediaNameToPayload) ~= "table" then saDB.sharedMediaNameToPayload = {} end
    if type(saDB.nextCustomPayload) ~= "number" then saDB.nextCustomPayload = CUSTOM_PAYLOAD_START end
    
    return saDB
end

-- ============================================================================
-- PAYLOAD MANAGEMENT
-- ============================================================================
local function AllocatePayload()
    local settings = GetSettings()
    if not settings then return nil end

    local payload = settings.nextCustomPayload
    while settings.payloadMeta[payload] ~= nil or payload >= 0 do
        payload = payload - 1
    end
    settings.nextCustomPayload = payload - 1
    return payload
end

local function GetOrCreatePayloadForSharedMediaName(mediaName)
    if type(mediaName) ~= "string" or mediaName == "" then return nil end

    local settings = GetSettings()
    if not settings then return nil end

    local existing = settings.sharedMediaNameToPayload[mediaName]
    if type(existing) == "number" and existing < 0 then
        settings.payloadMeta[existing] = { type = "sharedmedia", key = mediaName }
        return existing
    end

    local payload = AllocatePayload()
    if not payload then return nil end
    
    settings.sharedMediaNameToPayload[mediaName] = payload
    settings.payloadMeta[payload] = { type = "sharedmedia", key = mediaName }
    return payload
end

local function GetPayloadMeta(payload)
    if type(payload) ~= "number" or payload >= 0 then return nil end
    
    local settings = GetSettings()
    if not settings then return nil end
    
    return settings.payloadMeta[payload]
end

-- ============================================================================
-- LIBSHAREDMEDIA HELPERS
-- ============================================================================
local function GetLSM()
    if LibStub then
        local ok, lib = pcall(LibStub.GetLibrary, LibStub, "LibSharedMedia-3.0", true)
        if ok and lib then return lib end
    end
    return nil
end

local function GetSharedMediaNames()
    local lsm = GetLSM()
    if not lsm or type(lsm.List) ~= "function" then return nil end
    local names = lsm:List("sound")
    if not names or #names == 0 then return nil end
    local copy = {}
    for i, v in ipairs(names) do copy[i] = v end
    table.sort(copy)
    return copy
end

local function FetchSharedMediaPath(mediaName)
    local lsm = GetLSM()
    if not lsm or type(lsm.Fetch) ~= "function" then return nil end
    return lsm:Fetch("sound", mediaName, true)
end

-- ============================================================================
-- DROPDOWN LABEL
-- ============================================================================
local function GetCustomSoundLabel(alert)
    if type(alert) ~= "table" then return nil end
    if not CooldownViewerAlert_GetType or CooldownViewerAlert_GetType(alert) ~= Enum.CooldownViewerAlertType.Sound then return nil end

    local payload = CooldownViewerAlert_GetPayload(alert)
    local meta = GetPayloadMeta(payload)
    if not meta or meta.type ~= "sharedmedia" then return nil end

    local mediaName = meta.key
    if FetchSharedMediaPath(mediaName) then
        return "GravityUI: " .. mediaName
    end
    return "GravityUI (missing): " .. mediaName
end

-- ============================================================================
-- DROPDOWN INJECTION
-- ============================================================================
local function NoOp() end

local soundCategoryKeyToText = {
    Animals = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_ANIMALS,
    Devices = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_DEVICES,
    Impacts = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_IMPACTS,
    Instruments = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_INSTRUMENTS,
    War2 = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR2,
    War3 = COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR3,
}

local function SetupSampleUtilityButton(button, clickHandler)
    local playSampleButton = MenuTemplates.AttachUtilityButton(button)
    playSampleButton.Texture:Hide()
    CooldownViewerAlert_SetupTypeButton(playSampleButton, Enum.CooldownViewerAlertType.Sound)
    MenuTemplates.SetUtilityButtonTooltipText(playSampleButton, COOLDOWN_VIEWER_SETTINGS_ALERT_MENU_PLAY_SAMPLE)
    MenuTemplates.SetUtilityButtonAnchor(playSampleButton, MenuVariants.GearButtonAnchor, button)
    MenuTemplates.SetUtilityButtonClickHandler(playSampleButton, clickHandler)
end

local function AddBuiltinSoundAlertButton(ownerFrame, description, buttonText, alertPayload)
    local btn = description:CreateButton(buttonText, function(elementData)
        CooldownViewerAlert_SetPayload(ownerFrame.workingCopyOfAlert, elementData)
    end, alertPayload)

    btn:AddInitializer(function(button)
        SetupSampleUtilityButton(button, function()
            local alert = CooldownViewerAlert_Create(Enum.CooldownViewerAlertType.Sound, Enum.CooldownViewerAlertEventType.Available, alertPayload)
            CooldownViewerAlert_PlayAlert(ownerFrame, ownerFrame:GetCooldownName(), alert)
        end)
    end)
end

local function AddSharedMediaButton(ownerFrame, description, mediaName)
    local btn = description:CreateButton(mediaName, function(elementData)
        local payload = GetOrCreatePayloadForSharedMediaName(elementData)
        if payload then
            CooldownViewerAlert_SetPayload(ownerFrame.workingCopyOfAlert, payload)
        end
    end, mediaName)

    btn:AddInitializer(function(button)
        SetupSampleUtilityButton(button, function()
            local payload = GetOrCreatePayloadForSharedMediaName(mediaName)
            if payload then
                local alert = CooldownViewerAlert_Create(Enum.CooldownViewerAlertType.Sound, Enum.CooldownViewerAlertEventType.Available, payload)
                CooldownViewerAlert_PlayAlert(ownerFrame, ownerFrame:GetCooldownName(), alert)
            end
        end)
    end)
end

local function SetupPayloadDropdown(editAlertFrame)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Inject a label override that shows our custom sound name
    editAlertFrame.PayloadDropdown:SetSelectionText(function(_selections)
        return GetCustomSoundLabel(editAlertFrame.workingCopyOfAlert)
            or CooldownViewerAlert_GetPayloadText(editAlertFrame.workingCopyOfAlert)
    end)

    editAlertFrame.PayloadDropdown:SetupMenu(function(_dropdown, rootDescription)
        rootDescription:SetTag("COOLDOWN_VIEWER_ALERT_PAYLOAD")

        -- Blizzard built-in sounds first
        if CooldownViewerSoundData then
            local function BuildBuiltin(desc, tbl)
                for key, value in pairs(tbl) do
                    if value.soundEnum and value.text then
                        AddBuiltinSoundAlertButton(editAlertFrame, desc, value.text, value.soundEnum)
                    elseif type(value) == "table" then
                        local catName = soundCategoryKeyToText[key] or tostring(key)
                        local sub = desc:CreateButton(catName, NoOp, -1)
                        BuildBuiltin(sub, value)
                    end
                end
            end
            BuildBuiltin(rootDescription, CooldownViewerSoundData)
        end
        if CooldownViewerSound and CooldownViewerSound.TextToSpeech then
            AddBuiltinSoundAlertButton(
                editAlertFrame,
                rootDescription,
                COOLDOWN_VIEWER_SETTINGS_ALERT_LABEL_SOUND_TYPE_TEXT_TO_SPEECH,
                CooldownViewerSound.TextToSpeech
            )
        end

        -- GravityUI section (LibSharedMedia)
        local names = GetSharedMediaNames()
        local gravityRoot = rootDescription:CreateButton(GRAVITY_MENU_LABEL, NoOp, -1)
        gravityRoot:SetScrollMode(250) -- Makes the submenu scrollable if it exceeds 250px height
        
        if names then
            for _, mediaName in ipairs(names) do
                AddSharedMediaButton(editAlertFrame, gravityRoot, mediaName)
            end
        end
    end)
end

-- ============================================================================
-- PLAYBACK HOOK
-- ============================================================================
local function InstallPlaybackHook()
    hooksecurefunc("CooldownViewerAlert_PlayAlert", function(_cooldownItem, _spellName, alert)
        if type(alert) ~= "table" then return end
        if not CooldownViewerAlert_GetType or CooldownViewerAlert_GetType(alert) ~= Enum.CooldownViewerAlertType.Sound then return end

        local payload = CooldownViewerAlert_GetPayload(alert)
        local meta = GetPayloadMeta(payload)
        if not meta or meta.type ~= "sharedmedia" then return end

        local soundPath = FetchSharedMediaPath(meta.key)
        if soundPath then
            local didPlay = PlaySoundFile(soundPath, "SFX")
            if didPlay == false then
                PlaySoundFile(soundPath, "Master")
            end
        end
    end)
end

-- ============================================================================
-- HOOKS INSTALL
-- ============================================================================
local function InstallHooks()
    if hooksInstalled then return end

    -- Wait for Blizzard_CooldownViewerSettings to be loaded
    if not CooldownViewerSettingsEditAlert then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    hooksecurefunc(CooldownViewerSettingsEditAlert, "DisplayForAlert", SetupPayloadDropdown)
    
    -- Taint workaround: Force a reload when saving alerts that use custom sounds
    -- This prevents the "attempt to perform boolean test on local 'hasTotem' (a secret boolean value tainted by 'GravityUI')" error
    local owner = CooldownViewerSettingsEditAlert.owner:GetLayoutManager()
    if owner then
        hooksecurefunc(owner, "AddAlert", function() refreshRequired = true end)
        hooksecurefunc(owner, "UpdateAlert", function() refreshRequired = true end)
        hooksecurefunc(owner, "SaveLayouts", function()
            if refreshRequired then
                C_UI.Reload()
            end
        end)
    end

    InstallPlaybackHook()
    hooksInstalled = true
end

-- Called from the UI checkbox when toggling on/off
function SoundAlerts.ApplySettings()
    if hooksInstalled then return end  -- already active, can't un-hook; requires /reload
    InstallHooks()
end

-- ============================================================================
-- INITIALIZER
-- ============================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        InstallHooks()
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_CooldownViewerSettings" then
        InstallHooks()
    end
end)
