-- GravityUI - Main Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

---------------------------------------------------------------------------
-- Gravity RECOMMENDED FPS SETTINGS (58 CVars)
---------------------------------------------------------------------------
local Gravity_FPS_CVARS = {
    -- Graphics Tab
    ["vsync"] = "0",
    ["LowLatencyMode"] = "3",
    ["MSAAQuality"] = "0",
    ["ffxAntiAliasingMode"] = "0",
    ["alphaTestMSAA"] = "1",
    ["cameraFov"] = "90",
    ["RenderScale"] = "0.83",

    -- Graphics Quality (Base)
    ["graphicsQuality"] = "9",
    ["graphicsShadowQuality"] = "0",
    ["graphicsLiquidDetail"] = "1",
    ["graphicsParticleDensity"] = "3",           -- Good statt High (war 5)
    ["graphicsSSAO"] = "0",
    ["graphicsDepthEffects"] = "0",
    ["graphicsComputeEffects"] = "0",
    ["graphicsOutlineMode"] = "1",
    ["OutlineEngineMode"] = "1",
    ["graphicsTextureResolution"] = "2",
    ["graphicsSpellDensity"] = "0",
    ["spellClutter"] = "1",
    ["spellVisualDensityFilterSetting"] = "1",
    ["graphicsProjectedTextures"] = "1",        
    ["projectedTextures"] = "1",                
    ["graphicsViewDistance"] = "2",
    ["graphicsEnvironmentDetail"] = "0",
    ["graphicsGroundClutter"] = "0",

    -- Advanced Tab
    ["gxTripleBuffer"] = "0",
    ["textureFilteringMode"] = "2",             -- FIX: 4x Anisotropic (war 5 = 16x – unnötig)
    ["graphicsRayTracedShadows"] = "0",
    ["rtShadowQuality"] = "0",
    ["ResampleQuality"] = "4",
    ["ffxSuperResolution"] = "1",
    ["VRSMode"] = "0",
    ["GxApi"] = "D3D12",
    ["physicsLevel"] = "0",
    ["maxFPS"] = "144",
    ["maxFPSBk"] = "30",
    ["targetFPS"] = "61",
    ["useTargetFPS"] = "0",
    ["ResampleSharpness"] = "0.2",
    ["Contrast"] = "75",
    ["Brightness"] = "50",
    ["Gamma"] = "1.1",

    -- Additional Optimizations
    ["particulatesEnabled"] = "0",
    ["clusteredShading"] = "0",
    ["volumeFogLevel"] = "0",
    ["reflectionMode"] = "0",
    ["ffxGlow"] = "0",
    ["ffxSpecular"] = "0",                      -- NEU: Spekulare Glanzeffekte aus
    ["ffxDeathrattle"] = "0",                   -- NEU: Death-Effekte vereinfacht
    ["farclip"] = "5000",
    ["horizonStart"] = "1000",
    ["horizonClip"] = "5000",
    ["lodObjectCullSize"] = "35",
    ["lodObjectFadeScale"] = "50",
    ["lodObjectMinSize"] = "0",
    ["doodadLodScale"] = "50",
    ["entityLodDist"] = "7",
    ["terrainLodDist"] = "350",
    ["TerrainLodDiv"] = "512",
    ["waterDetail"] = "1",
    ["rippleDetail"] = "0",
    ["weatherDensity"] = "0",                   -- FIX: war 3 – minimal Weather Partikel
    ["entityShadowFadeScale"] = "15",
    ["groundEffectDist"] = "40",
    ["ResampleAlwaysSharpen"] = "1",
    ["shadowmode"] = "1",                       -- NEU: Einfache Schatten-Methode
    ["shadowtexturesize"] = "512",              -- NEU: Shadowmap-Größe optimiert
    ["nameplateMotion"] = "0",                  -- NEU: Nameplate-Animation aus (kein float)

    -- Special Hacks
    ["cameraDistanceMaxZoomFactor"] = "2.6",
    ["CameraReduceUnexpectedMovement"] = "1",
}


---------------------------------------------------------------------------
-- HELPER: FPS Settings Functions
---------------------------------------------------------------------------
local function BackupCurrentFPSSettings()
    local db = ns.GetDB()
    if not db then return false end
    
    local backup = {}
    for cvar, _ in pairs(Gravity_FPS_CVARS) do
        local success, current = pcall(C_CVar.GetCVar, cvar)
        if success and current then
            backup[cvar] = current
        end
    end
    db.fpsBackup = backup
    return true
end

local function RestorePreviousFPSSettings()
    local db = ns.GetDB()
    if not db or not db.fpsBackup then
        ns.Print("No backup found. Apply FPS settings first to create a backup.")
        return false
    end

    local successCount = 0
    local failCount = 0
    for cvar, value in pairs(db.fpsBackup) do
        local ok = pcall(C_CVar.SetCVar, cvar, tostring(value))
        if ok then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end
    end

    -- Clear backup after successful restore
    db.fpsBackup = nil

    ns.Print("Restored " .. successCount .. " previous settings.")
    if failCount > 0 then
        ns.Print(failCount .. " settings could not be restored.")
    end
    return true
end

local function ApplyGravityFPSSettings()
    -- Backup current settings first
    BackupCurrentFPSSettings()

    local successCount = 0
    local failCount = 0

    for cvar, value in pairs(Gravity_FPS_CVARS) do
        local success = pcall(function()
            C_CVar.SetCVar(cvar, value)
        end)

        if success then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end
    end

    ns.Print("Your previous settings have been backed up.")
    ns.Print("Applied " .. successCount .. " FPS settings. Use 'Restore Previous Settings' to undo.")
    if failCount > 0 then
        ns.Print(failCount .. " settings could not be applied (may require restart).")
    end
end

local function CheckCVarsMatch()
    local matchCount, totalCount = 0, 0
    for cvar, expectedVal in pairs(Gravity_FPS_CVARS) do
        totalCount = totalCount + 1
        local currentVal = C_CVar.GetCVar(cvar)
        -- Loose string comparison
        if tostring(currentVal) == tostring(expectedVal) then
            matchCount = matchCount + 1
        end
    end
    return matchCount == totalCount, matchCount, totalCount
end

---------------------------------------------------------------------------
-- MAIN PAGE BUILD
---------------------------------------------------------------------------
local PADDING = 10

local function BuildWelcome(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB()
    if not db then return end
    
    local yOffset = -10
    
    local welcomeHeader = ns.GUI:CreateSectionHeader(content, "Welcome to GravityUI")
    welcomeHeader:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - welcomeHeader.gap - 10
    
    local welcomeText = ns.GUI:CreateLabel(content, 
        "A modern, feature-rich UI configuration addon for World of Warcraft.\n" ..
        "Use the menu on the left to navigate through different settings.",
        12, C.text)
    ns.GUI:SetFont(welcomeText, 12, "")
    welcomeText:SetPoint("TOPLEFT", PADDING, yOffset)
    welcomeText:SetWidth(640)
    welcomeText:SetJustifyH("LEFT")
    yOffset = yOffset - 20
    
    -- GravityUI Logo
    local logoWidth = 640
    local logoHeight = 360 -- Maintain 16:9, but scale to width
    local logo = content:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\GravityUI\\assets\\Gravity_UI_Logo.jpg")
    logo:SetSize(logoWidth, logoHeight)
    logo:SetAlpha(0.12) -- Make it somewhat transparent to blend with background
    -- Center it relative to the 640 width of the welcome text block
    logo:SetPoint("TOPLEFT", PADDING + (640 - logoWidth) / 2, yOffset)
    yOffset = yOffset - logoHeight - 20

    content:SetHeight(math.abs(yOffset) + 20)
end

local function BuildThemeColor(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB()
    if not db then return end
    
    local yOffset = -10
    
    local themeHeader = ns.GUI:CreateSectionHeader(content, "Theme Color")
    themeHeader:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - themeHeader.gap - 10
    
    local themeInfo = ns.GUI:CreateInfoBox(content, "Theme Color is used for styling modules in GravityUI.")
    themeInfo:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - themeInfo:GetHeight() - 10
    
    if ns.GUI.CreateColorPicker then
        local colorPicker = ns.GUI:CreateColorPicker(content, "Primary Theme Color", "themeColor", db.general, function()
            if ns.RefreshAccentColors then ns.RefreshAccentColors() end
        end)
        colorPicker:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - 30

        local bgColorPicker = ns.GUI:CreateColorPicker(content, "Theme Background Color", "themeBgColor", db.general, function()
            if ns.RefreshAccentColors then ns.RefreshAccentColors() end
        end)
        bgColorPicker:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - 30
    end
    
    local classThemeCheck = ns.GUI:CreateCheckbox(content, "Use Class Color for Theme", "useClassColorTheme", db.general, function()
        if ns.RefreshAccentColors then ns.RefreshAccentColors() end
    end)
    classThemeCheck:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 40
    
    content:SetHeight(math.abs(yOffset) + 20)
end

local function BuildUIScale(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB()
    if not db then return end
    
    local yOffset = -10
    
    local uiScaleHeader = ns.GUI:CreateSectionHeader(content, "UI Scale")
    uiScaleHeader:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - uiScaleHeader.gap - 10
    
    local presetInfo = ns.GUI:CreateInfoBox(content, "Hover over any preset for details. Gravity's 1440p is Gravity's personal setting.")
    presetInfo:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - presetInfo:GetHeight() - 10
    
    local presetLabel = ns.GUI:CreateLabel(content, "Quick UI Scale Presets:", 12, C.text)
    presetLabel:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 25
    
    if db.general.uiScale == nil then db.general.uiScale = 0.64 end
    
    local scaleSlider
    
    local function ApplyPreset(val, name)
        db.general.uiScale = val
        pcall(function() UIParent:SetScale(val) end)
        if scaleSlider and scaleSlider.SetValue then scaleSlider.SetValue(val) end
        local msg = "UI scale set to " .. string.format("%.4f", val)
        if name then msg = msg .. " (" .. name .. ")" end
        ns.Print(msg)
    end
    
    local function AutoScale()
        local _, height = GetPhysicalScreenSize()
        local scale = 768 / height
        scale = math.max(0.3, math.min(2.0, scale))
        ApplyPreset(scale, "Auto")
    end
    
    local buttonContainer = CreateFrame("Frame", nil, content)
    buttonContainer:SetPoint("TOPLEFT", PADDING, yOffset)
    buttonContainer:SetHeight(26)
    buttonContainer:SetWidth(500)
    
    local BUTTON_GAP = 6
    local buttons = {}
    
    buttons[1] = ns.GUI:CreateButton(buttonContainer, "1080p", 50, 26, function() ApplyPreset(0.7111, "1080p") end)
    buttons[2] = ns.GUI:CreateButton(buttonContainer, "1440p", 50, 26, function() ApplyPreset(0.5333, "1440p") end)
    buttons[3] = ns.GUI:CreateButton(buttonContainer, "4K", 50, 26, function() ApplyPreset(0.3555, "4K") end)
    buttons[4] = ns.GUI:CreateButton(buttonContainer, "Gravity's 1440p", 50, 26, function() ApplyPreset(0.64, "Gravity's 1440p") end)
    buttons[5] = ns.GUI:CreateButton(buttonContainer, "Auto", 50, 26, AutoScale)
    
    for i, btn in ipairs(buttons) do
        if i == 4 then
            btn:SetWidth(120)
        else
            btn:SetWidth(80) 
        end
        btn:ClearAllPoints()
        if i == 1 then
            btn:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", buttons[i-1], "RIGHT", BUTTON_GAP, 0)
        end
    end
    
    local tooltipData = {
        { title = "1080p", desc = "Scale: 0.7111\nPixel-perfect for 1920×1080" },
        { title = "1440p", desc = "Scale: 0.5333\nPixel-perfect for 2560×1440" },
        { title = "4K", desc = "Scale: 0.3555\nPixel-perfect for 3840×2160" },
        { title = "Gravity's 1440p", desc = "Scale: 0.64\nGravity's personal setting — larger and more readable.\nRequires manual adjustment for pixel perfection." },
        { title = "Auto", desc = "Computes pixel-perfect scale based on your resolution.\nFormula: 768 ÷ screen height" },
    }
    
    for i, btn in ipairs(buttons) do
        local data = tooltipData[i]
        btn:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(data.title, 1, 1, 1)
            GameTooltip:AddLine(data.desc, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        btn:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    yOffset = yOffset - 32 - 10
    
    scaleSlider = ns.GUI:CreateSlider(content, "Global UI Scale", 0.3, 2.0, "uiScale", db.general, function(val)
        pcall(function() UIParent:SetScale(val) end)
    end, 0.01)
    scaleSlider:SetPoint("TOPLEFT", PADDING, yOffset)
    scaleSlider:SetWidth(400)
    yOffset = yOffset - 50
    
    content:SetHeight(math.abs(yOffset) + 20)
end

local function BuildFontSettings(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB()
    if not db then return end
    
    local yOffset = -10
    
    local fontHeader = ns.GUI:CreateSectionHeader(content, "Default Font Settings")
    fontHeader:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - fontHeader.gap - 10
    
    local fontInfo = ns.GUI:CreateInfoBox(content, 
        "|cff00BFFFInfo:|r These settings apply throughout the UI, including the Minimap and all Datapanels.\n" ..
        "|cffFFCC00Note:|r A /reload is required for some elements to take full effect.")
    fontInfo:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - fontInfo:GetHeight() - 20 
    
    local fontList = {}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for name in pairs(LSM:HashTable("font")) do
            table.insert(fontList, {value = name, text = name})
        end
        table.sort(fontList, function(a, b) return a.text < b.text end)
    else
        fontList = {{value = "Friz Quadrata TT", text = "Friz Quadrata TT"}}
    end
    
    local fontDropdown = ns.GUI:CreateDropdown(content, "Default Font", fontList, "font", db.general, function()
        if ns.GUI.RefreshAll then ns.GUI:RefreshAll() end
    end)
    fontDropdown:SetPoint("TOPLEFT", PADDING, yOffset)
    fontDropdown:SetWidth(400)
    yOffset = yOffset - 50
    
    local outlineOptions = {
        {value = "", text = "None"},
        {value = "OUTLINE", text = "Outline"},
        {value = "THICKOUTLINE", text = "Thick Outline"},
    }
    local outlineDropdown = ns.GUI:CreateDropdown(content, "Font Outline", outlineOptions, "fontOutline", db.general, function()
        if ns.GUI.RefreshAll then ns.GUI:RefreshAll() end
    end)
    outlineDropdown:SetPoint("TOPLEFT", PADDING, yOffset)
    outlineDropdown:SetWidth(400)
    yOffset = yOffset - 50
    
    content:SetHeight(math.abs(yOffset) + 20)
end

local function BuildFPSSettings(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB()
    if not db then return end
    
    local yOffset = -10
    
    local fpsHeader = ns.GUI:CreateSectionHeader(content, "Gravity Recommended FPS Settings")
    fpsHeader:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - fpsHeader.gap - 10
    
    local fpsDesc = ns.GUI:CreateInfoBox(content,
        "Apply Gravity's optimized graphics settings for competitive play. " ..
        "Your current settings are automatically saved when you click Apply - use 'Restore Previous Settings' to revert anytime. " ..
        "Caution: Clicking Apply again will overwrite your backup with these settings.")
    fpsDesc:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - fpsDesc:GetHeight() - 10
    
    local restoreFpsBtn
    local fpsStatusText

    local function UpdateFPSStatus()
        local allMatch, matched, total = CheckCVarsMatch()
        if matched >= 50 then
            fpsStatusText:SetText("Settings: All applied")
            fpsStatusText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
        else
            fpsStatusText:SetText(string.format("Settings: %d/%d match", matched, total))
            fpsStatusText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
        end
    end

    local applyFpsBtn = ns.GUI:CreateButton(content, "Apply FPS Settings", 200, 28, function()
        ApplyGravityFPSSettings()
        if restoreFpsBtn then
            restoreFpsBtn:SetAlpha(1)
            restoreFpsBtn:Enable()
        end
        UpdateFPSStatus()
    end)
    applyFpsBtn:SetPoint("TOPLEFT", PADDING, yOffset)

    restoreFpsBtn = ns.GUI:CreateButton(content, "Restore Previous Settings", 200, 28, function()
        if RestorePreviousFPSSettings() then
            restoreFpsBtn:SetAlpha(0.5)
            restoreFpsBtn:Disable()
        end
        UpdateFPSStatus()
    end)
    restoreFpsBtn:SetPoint("LEFT", applyFpsBtn, "RIGHT", 10, 0)
    
    if not db.fpsBackup then
        restoreFpsBtn:SetAlpha(0.5)
        restoreFpsBtn:Disable()
    end
    
    yOffset = yOffset - 38

    fpsStatusText = ns.GUI:CreateLabel(content, "", 11, C.accent)
    ns.GUI:SetFont(fpsStatusText, 11, "")
    fpsStatusText:SetPoint("TOPLEFT", PADDING, yOffset)
    
    UpdateFPSStatus()
    
    yOffset = yOffset - 22
    
    content:SetHeight(math.abs(yOffset) + 20)
end

---------------------------------------------------------------------------
-- COMBAT
---------------------------------------------------------------------------
local function BuildCombat(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    
    local yOffset = -10
    local header = ns.GUI:CreateSectionHeader(content, "Combat Settings")
    header:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - header.gap - 10
    
    local cb1 = ns.GUI:CreateCheckbox(content, "Show Damage Numbers", "showDamageNumbers", dbUI, function(enabled) SetCVar("floatingCombatTextCombatDamage", enabled and "1" or "0") end)
    cb1:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 30

    local cb2 = ns.GUI:CreateCheckbox(content, "Show Healing Numbers", "showHealingNumbers", dbUI, function(enabled) SetCVar("floatingCombatTextCombatHealing", enabled and "1" or "0") end)
    cb2:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 40
    
    if dbUI.spellQueueWindow == nil then dbUI.spellQueueWindow = tonumber(GetCVar("SpellQueueWindow")) or 400 end
    local slider = ns.GUI:CreateSlider(content, "Spell Queue Window (ms)", 0, 400, "spellQueueWindow", dbUI, function(val) SetCVar("SpellQueueWindow", tostring(val)) end, 10)
    slider:SetPoint("TOPLEFT", PADDING, yOffset)
    slider:SetWidth(400)
    yOffset = yOffset - 60
    
    content:SetHeight(math.abs(yOffset) + 20)
end

---------------------------------------------------------------------------
-- BUFFS & DEBUFFS (Icons)
---------------------------------------------------------------------------
local function BuildBuffs(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB(); if not db then return end
    local dbUI = db.uiimprovements
    
    local yOffset = -10
    local header = ns.GUI:CreateSectionHeader(content, "Standard Buff & Debuff Styling")
    header:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - header.gap - 10
    
    local info = ns.GUI:CreateInfoBox(content, "Modifies borders and font size of Blizzard default Buff and Debuff frames.")
    info:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - info:GetHeight() - 15

    if not dbUI.buffBorders then dbUI.buffBorders = {} end
    local dbBuffs = dbUI.buffBorders
    local function RefreshBuffs() if ns.BuffBorders and ns.BuffBorders.Refresh then ns.BuffBorders.Refresh() end end

    local cb_b = ns.GUI:CreateCheckbox(content, "Enable Buff Borders", "enableBuffs", dbBuffs, RefreshBuffs)
    cb_b:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 30

    local cb_d = ns.GUI:CreateCheckbox(content, "Enable Debuff Borders", "enableDebuffs", dbBuffs, RefreshBuffs)
    cb_d:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 40

    local sizeSlider = ns.GUI:CreateSlider(content, "Border Size", 0, 5, "borderSize", dbBuffs, RefreshBuffs, 0.5)
    sizeSlider:SetPoint("TOPLEFT", PADDING, yOffset)
    sizeSlider:SetWidth(400)
    yOffset = yOffset - 50
    
    local cb_s = ns.GUI:CreateCheckbox(content, "Enable Styling (Fonts/Effects)", "enableStyling", dbBuffs, RefreshBuffs)
    cb_s:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 40
    
    local cb_n = ns.GUI:CreateCheckbox(content, "Disable Blinking", "noBlink", dbBuffs, RefreshBuffs)
    cb_n:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 40
    
    local subHeader = ns.GUI:CreateLabel(content, "Font Settings", 14, C.accent)
    subHeader:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 25

    local fontList = {}
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for name in pairs(LSM:HashTable("font")) do
            table.insert(fontList, {value = name, text = name})
        end
        table.sort(fontList, function(a, b) return a.text < b.text end)
    else
        fontList = {{value = "Friz Quadrata TT", text = "Friz Quadrata TT"}}
    end

    local fontDropdown = ns.GUI:CreateDropdown(content, "Duration Font", fontList, "font", dbBuffs, RefreshBuffs) 
    fontDropdown:SetPoint("TOPLEFT", PADDING, yOffset)
    fontDropdown:SetWidth(400)
    yOffset = yOffset - 50

    local sizeSlider2 = ns.GUI:CreateSlider(content, "Duration Font Size", 8, 24, "fontSize", dbBuffs, RefreshBuffs, 1)
    sizeSlider2:SetPoint("TOPLEFT", PADDING, yOffset)
    sizeSlider2:SetWidth(400)
    yOffset = yOffset - 50

    content:SetHeight(math.abs(yOffset) + 20)
end


local function BuildEditMode(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local db = ns.GetDB()
    if not db then return end

    local yOffset = -10
    local PAD = PADDING

    -- Header
    local header = ns.GUI:CreateSectionHeader(content, "GravityUI Edit Mode")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap - 10

    local infoBox = ns.GUI:CreateInfoBox(content,
        "Enable GravityUI Edit Mode to drag and reposition all GravityUI elements.\n" ..
        "Changes are saved automatically when you drag a frame.")
    infoBox:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - infoBox:GetHeight() - 14

    -- ── Enable / Disable Buttons ──────────────────────────────────────────
    local Movers = ns.Movers

    local btnContainer = CreateFrame("Frame", nil, content)
    btnContainer:SetPoint("TOPLEFT", PAD, yOffset)
    btnContainer:SetSize(440, 32)

    local enableBtn = ns.GUI:CreateButton(btnContainer, "Enable GravityUI Edit Mode", 210, 32, function()
        if Movers then
            Movers:SetEditMode(true)
            Movers:SetShowGravityElements(true)
        end
    end)
    enableBtn:SetPoint("LEFT", btnContainer, "LEFT", 0, 0)

    local disableBtn = ns.GUI:CreateButton(btnContainer, "Disable GravityUI Edit Mode", 210, 32, function()
        if Movers then
            Movers:SetEditMode(false)
            Movers:SetShowGravityElements(false)
        end
    end)
    disableBtn:SetPoint("LEFT", enableBtn, "RIGHT", 10, 0)

    yOffset = yOffset - 42

    -- ── Status Label ─────────────────────────────────────────────────────
    local statusLabel = ns.GUI:CreateLabel(content, "", 11, C.textMuted)
    ns.GUI:SetFont(statusLabel, 11, "")
    statusLabel:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 22

    -- Live update status when this tab is shown
    local function RefreshStatus()
        if Movers and Movers.isEditMode and Movers.showGravityElements then
            statusLabel:SetText("|cff00FF80● Edit Mode ACTIVE — Drag elements to reposition them|r")
        else
            statusLabel:SetText("")
        end
    end
    RefreshStatus()

    -- Refresh status on each button click
    hooksecurefunc(enableBtn, "Click", RefreshStatus)
    hooksecurefunc(disableBtn, "Click", RefreshStatus)

    -- ── Registered Elements List ──────────────────────────────────────────
    yOffset = yOffset - 8
    local elemHeader = ns.GUI:CreateSectionHeader(content, "Registered Movable Elements")
    elemHeader:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - elemHeader.gap - 4

    if Movers and next(Movers.registry) ~= nil then
        -- Sort alphabetically by label
        local sortedNames = {}
        for name in pairs(Movers.registry) do
            table.insert(sortedNames, name)
        end
        table.sort(sortedNames, function(a, b)
            local la = (Movers.registry[a].label or a):lower()
            local lb = (Movers.registry[b].label or b):lower()
            return la < lb
        end)

        for _, name in ipairs(sortedNames) do
            local data = Movers.registry[name]
            if name ~= "ZoneAbility" then
            local displayLabel = data.label or name

            -- Row
            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetSize(480, 28)
            row:SetPoint("TOPLEFT", PAD, yOffset)
            ns.GUI:CreateBackdrop(row, {0.12, 0.12, 0.12, 0.35}, C.border)

            -- Label
            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            ns.GUI:SetFont(lbl, 12, "")
            lbl:SetPoint("LEFT", 10, 0)
            lbl:SetText(displayLabel)
            lbl:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

            -- Toggle button: first click = show mover, second click = hide + save
            local frameAvailable = name ~= "ZoneAbility" or (data.frame and data.frame.IsShown ~= nil)
            local moverActive = false

            local toggleBtn = ns.GUI:CreateButton(row, "Move", 56, 20, function() end)
            toggleBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)

            local function SetMoverActive(active)
                moverActive = active
                if active then
                    -- Show the mover
                    if Movers and data.toggleFunc then
                        pcall(data.toggleFunc, data.frame, true, true)
                    end
                    -- Update button appearance to "Done"
                    if toggleBtn.text then
                        toggleBtn.text:SetText("Done")
                        toggleBtn.text:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    end
                else
                    -- Hide the mover (position auto-saved on drag via OnDragStop)
                    if Movers and data.toggleFunc then
                        pcall(data.toggleFunc, data.frame, false, false)
                    end
                    -- Revert button to "Move"
                    if toggleBtn.text then
                        toggleBtn.text:SetText("Move")
                        toggleBtn.text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
                    end
                end
            end

            toggleBtn:SetScript("OnClick", function()
                if not frameAvailable then return end
                SetMoverActive(not moverActive)
            end)

            if not frameAvailable then
                toggleBtn:SetAlpha(0.4)
                toggleBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                    GameTooltip:AddLine("Not available", 1, 0.5, 0, true)
                    GameTooltip:AddLine("Zone Ability only appears during\nspecific zone events or encounters.", 0.7, 0.7, 0.7, true)
                    GameTooltip:Show()
                end)
                toggleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end

            yOffset = yOffset - 32
            end -- if name ~= ZoneAbility
        end
    else
        local emptyLabel = ns.GUI:CreateLabel(content, "No movable elements registered yet.", 12, C.textMuted)
        emptyLabel:SetPoint("TOPLEFT", PAD + 5, yOffset)
        yOffset = yOffset - 24
    end

    content:SetHeight(math.abs(yOffset) + 20)
end


ns.GUI:RegisterPage("main", {
    title = "Main",
    subTabs = {
        { name = "Welcome",       builder = BuildWelcome },
        { name = "Theme Color",   builder = BuildThemeColor },
        { name = "UI Scale",      builder = BuildUIScale },
        { name = "Font Settings",  builder = BuildFontSettings },
        { name = "FPS Settings",  builder = BuildFPSSettings },
        { name = "Combat",        builder = BuildCombat },
        { name = "Buffs & Debuffs", builder = BuildBuffs },
        { name = "Edit Mode",     builder = BuildEditMode },
    },
    OnBuild = function(content)
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        local opts = GUI.pages["main"]
        opts.subTabsContainer = ns.GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["main"]
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
