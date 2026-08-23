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
        db.soundAlerts = { enabled = false, channel = "Master" }
    end
    
    local saDB = db.soundAlerts
    if not saDB.channel then saDB.channel = "Master" end
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
    
    -- Direct lookup first
    local meta = settings.payloadMeta[payload]
    if meta then return meta end
    
    -- SavedVariables can store negative numeric keys as strings; try string key
    meta = settings.payloadMeta[tostring(payload)]
    if meta then
        -- Migrate to numeric key for future lookups
        settings.payloadMeta[payload] = meta
        settings.payloadMeta[tostring(payload)] = nil
        return meta
    end
    
    return nil
end

-- ============================================================================
-- LIBSHAREDMEDIA HELPERS
-- ============================================================================
local function GetLSM()
    if LibStub then
        return LibStub("LibSharedMedia-3.0", true)
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

local function SetupSampleUtilityButton(button, clickHandler)
    local playSampleButton = MenuTemplates.AttachUtilityButton(button)
    playSampleButton.Texture:Hide()
    CooldownViewerAlert_SetupTypeButton(playSampleButton, Enum.CooldownViewerAlertType.Sound)
    MenuTemplates.SetUtilityButtonTooltipText(playSampleButton, COOLDOWN_VIEWER_SETTINGS_ALERT_MENU_PLAY_SAMPLE)
    MenuTemplates.SetUtilityButtonAnchor(playSampleButton, MenuVariants.GearButtonAnchor, button)
    MenuTemplates.SetUtilityButtonClickHandler(playSampleButton, clickHandler)
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

    -- Inject a label override that shows our custom sound name.
    -- Must be re-applied each time DisplayForAlert fires because Blizzard
    -- resets the selection text to its own resolver on every call.
    editAlertFrame.PayloadDropdown:SetSelectionText(function(_selections)
        return GetCustomSoundLabel(editAlertFrame.workingCopyOfAlert)
            or CooldownViewerAlert_GetPayloadText(editAlertFrame.workingCopyOfAlert)
    end)

    -- Force an immediate text update so the label shows our custom name
    -- instead of being blank when editing an alert that uses a GravityUI sound.
    if editAlertFrame.PayloadDropdown.Update then
        editAlertFrame.PayloadDropdown:Update()
    elseif editAlertFrame.PayloadDropdown.GenerateMenu then
        -- Some versions use GenerateMenu to refresh text display
    end
end

-- ============================================================================
-- MENU MODIFIER: Appends GravityUI section to Blizzard's Sound Alert dropdown.
-- Uses Menu.ModifyMenu which fires whenever a tagged menu opens, so we never
-- replace Blizzard's generator — we only append our entries at the end.
-- ============================================================================
local menuModifierInstalled = false

local function InstallMenuModifier()
    if menuModifierInstalled then return end
    if not Menu or not Menu.ModifyMenu then return end
    menuModifierInstalled = true

    Menu.ModifyMenu("COOLDOWN_VIEWER_ALERT_PAYLOAD", function(owner, rootDescription, contextData)
        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        -- Find the editAlertFrame from the dropdown owner
        local editAlertFrame = owner and owner:GetParent()
        if not editAlertFrame or not editAlertFrame.workingCopyOfAlert then
            local frame = owner
            for i = 1, 5 do
                if not frame then break end
                if frame.workingCopyOfAlert then
                    editAlertFrame = frame
                    break
                end
                frame = frame:GetParent()
            end
        end

        -- GravityUI submenu with LibSharedMedia sounds
        local names = GetSharedMediaNames()
        local gravityRoot = rootDescription:CreateButton(GRAVITY_MENU_LABEL, NoOp, -1)
        gravityRoot:SetScrollMode(250)

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
            local settings = GetSettings()
            local channel = (settings and settings.channel) or "Master"
            PlaySoundFile(soundPath, channel)
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
    InstallMenuModifier()
    
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
