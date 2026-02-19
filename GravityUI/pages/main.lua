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

    -- Graphics Quality (Base)
    ["graphicsQuality"] = "9",
    ["graphicsShadowQuality"] = "0",
    ["graphicsLiquidDetail"] = "1",
    ["graphicsParticleDensity"] = "5",
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
    ["graphicsViewDistance"] = "3",
    ["graphicsEnvironmentDetail"] = "0",
    ["graphicsGroundClutter"] = "0",

    -- Advanced Tab
    ["gxTripleBuffer"] = "0",
    ["textureFilteringMode"] = "5",
    ["graphicsRayTracedShadows"] = "0",
    ["rtShadowQuality"] = "0",
    ["ResampleQuality"] = "4",
    ["ffxSuperResolution"] = "1",
    ["VRSMode"] = "0",
    ["GxApi"] = "D3D12",
    ["physicsLevel"] = "0",
    ["maxFPS"] = "144",
    ["maxFPSBk"] = "60",
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
    ["weatherDensity"] = "3",
    ["entityShadowFadeScale"] = "15",
    ["groundEffectDist"] = "40",
    ["ResampleAlwaysSharpen"] = "1",

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
ns.GUI:RegisterPage("main", {
    title = "Main",
    OnBuild = function(content)
        local db = ns.GetDB()
        if not db then return end
        
        -- Use the provided content frame directly (which is already a ScrollChild)
        -- No need to create another ScrollFrame inside it
        
        local yOffset = -10
        local PADDING = 10
        
        -- ═══════════════════════════════════════════════════════════════
        -- WELCOME SECTION
        -- ═══════════════════════════════════════════════════════════════
        local welcomeHeader = GUI:CreateSectionHeader(content, "Welcome to GravityUI")
        welcomeHeader:SetPoint("TOPLEFT", PADDING, yOffset)
        -- Note: SetPoint("RIGHT") is handled automatically by CreateSectionHeader (if overriding)
        -- If not overriding, we should check if we need to set it. 
        -- Assuming user reverted framework.lua, the override IS present.
        -- So we do NOT set RIGHT manually here to avoid conflicts.
        yOffset = yOffset - welcomeHeader.gap
        yOffset = yOffset - 10
        
        local welcomeText = GUI:CreateLabel(content, 
            "A modern, feature-rich UI configuration addon for World of Warcraft.\n" ..
            "Use the menu on the left to navigate through different settings.",
            12, C.text)
        GUI:SetFont(welcomeText, 12, "")
        welcomeText:SetPoint("TOPLEFT", PADDING, yOffset)
        welcomeText:SetWidth(640)
        welcomeText:SetJustifyH("LEFT")
        yOffset = yOffset - 45
        
        -- ═══════════════════════════════════════════════════════════════
        -- THEME COLOR SECTION
        -- ═══════════════════════════════════════════════════════════════
        local themeHeader = GUI:CreateSectionHeader(content, "Theme Color")
        themeHeader:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - themeHeader.gap
        yOffset = yOffset - 10
        
        local themeInfo = GUI:CreateInfoBox(content, "Theme Color is used for styling modules in GravityUI.")
        themeInfo:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - themeInfo:GetHeight() - 10 -- Dynamic Spacing
        
        -- Theme Color Pickers
        if GUI.CreateColorPicker then
            local colorPicker = GUI:CreateColorPicker(content, "Primary Theme Color", "themeColor", db.general, function()
                if ns.RefreshAccentColors then ns.RefreshAccentColors() end
            end)
            colorPicker:SetPoint("TOPLEFT", PADDING, yOffset)
            yOffset = yOffset - 30

            local bgColorPicker = GUI:CreateColorPicker(content, "Theme Background Color", "themeBgColor", db.general, function()
                if ns.RefreshAccentColors then ns.RefreshAccentColors() end
            end)
            bgColorPicker:SetPoint("TOPLEFT", PADDING, yOffset)
            yOffset = yOffset - 30
        end
        
        -- Use Class Color Theme
        local classThemeCheck = GUI:CreateCheckbox(content, "Use Class Color for Theme", "useClassColorTheme", db.general, function()
            if ns.RefreshAccentColors then ns.RefreshAccentColors() end
        end)
        classThemeCheck:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - 40
        yOffset = yOffset - 10 -- Extra spacer
        
        -- ═══════════════════════════════════════════════════════════════
        -- UI SCALE SECTION
        -- ═══════════════════════════════════════════════════════════════
        local uiScaleHeader = GUI:CreateSectionHeader(content, "UI Scale")
        uiScaleHeader:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - uiScaleHeader.gap
        yOffset = yOffset - 10
        
        -- UI Scale Slider
        if db.general.uiScale == nil then db.general.uiScale = 0.64 end
        
        local scaleSlider = GUI:CreateSlider(content, "Global UI Scale", 0.3, 2.0, "uiScale", db.general, function(val)
            pcall(function() UIParent:SetScale(val) end)
        end, 0.01)
        scaleSlider:SetPoint("TOPLEFT", PADDING, yOffset)
        scaleSlider:SetWidth(400)
        yOffset = yOffset - 50
        
        -- Preset Buttons Label
        local presetLabel = GUI:CreateLabel(content, "Quick UI Scale Presets:", 12, C.text)
        presetLabel:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - 25
        
        -- Info text (Moved & Converted to InfoBox)
        local presetInfo = GUI:CreateInfoBox(content, 
            "Hover over any preset for details. 1440p+ is Gravity's personal setting.")
        presetInfo:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - presetInfo:GetHeight() - 10 -- Dynamic Spacing
        
        -- Preset Button Functions
        local function ApplyPreset(val, name)
            db.general.uiScale = val
            pcall(function() UIParent:SetScale(val) end)
            scaleSlider.SetValue(val)
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
        
        -- Button Container
        local buttonContainer = CreateFrame("Frame", nil, content)
        buttonContainer:SetPoint("TOPLEFT", PADDING, yOffset)
        buttonContainer:SetHeight(26)
        buttonContainer:SetWidth(500)
        
        local BUTTON_GAP = 6
        local buttons = {}
        
        -- Create 5 preset buttons
        buttons[1] = GUI:CreateButton(buttonContainer, "1080p", 50, 26, function() ApplyPreset(0.7111, "1080p") end)
        buttons[2] = GUI:CreateButton(buttonContainer, "1440p", 50, 26, function() ApplyPreset(0.5333, "1440p") end)
        buttons[3] = GUI:CreateButton(buttonContainer, "1440p+", 50, 26, function() ApplyPreset(0.64, "1440p+") end)
        buttons[4] = GUI:CreateButton(buttonContainer, "4K", 50, 26, function() ApplyPreset(0.3555, "4K") end)
        buttons[5] = GUI:CreateButton(buttonContainer, "Auto", 50, 26, AutoScale)
        
        for i, btn in ipairs(buttons) do
            btn:SetWidth(80) 
            btn:ClearAllPoints()
            if i == 1 then
                btn:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
            else
                btn:SetPoint("LEFT", buttons[i-1], "RIGHT", BUTTON_GAP, 0)
            end
        end
        
        -- Tooltips for preset buttons
        local tooltipData = {
            { title = "1080p", desc = "Scale: 0.7111\nPixel-perfect for 1920×1080" },
            { title = "1440p", desc = "Scale: 0.5333\nPixel-perfect for 2560×1440" },
            { title = "1440p+", desc = "Scale: 0.64\nGravity's personal setting — larger and more readable.\nRequires manual adjustment for pixel perfection." },
            { title = "4K", desc = "Scale: 0.3555\nPixel-perfect for 3840×2160" },
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
        
        yOffset = yOffset - 32
        

        yOffset = yOffset - 10 -- Extra spacer
        
        -- ═══════════════════════════════════════════════════════════════
        -- DEFAULT FONT SETTINGS
        -- ═══════════════════════════════════════════════════════════════
        local fontHeader = GUI:CreateSectionHeader(content, "Default Font Settings")
        fontHeader:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - fontHeader.gap
        yOffset = yOffset - 10
        
        local fontInfo = GUI:CreateInfoBox(content, 
            "|cff00BFFFInfo:|r These settings apply throughout the UI, including the Minimap and all Datapanels.\n" ..
            "|cffFFCC00Note:|r A /reload is required for some elements to take full effect.")
        fontInfo:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - fontInfo:GetHeight() - 20 
        
        -- Font List (LibSharedMedia)
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
        
        local fontDropdown = GUI:CreateDropdown(content, "Default Font", fontList, "font", db.general, function()
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
        local outlineDropdown = GUI:CreateDropdown(content, "Font Outline", outlineOptions, "fontOutline", db.general, function()
            if ns.GUI.RefreshAll then ns.GUI:RefreshAll() end
        end)
        outlineDropdown:SetPoint("TOPLEFT", PADDING, yOffset)
        outlineDropdown:SetWidth(400)
        yOffset = yOffset - 50
        yOffset = yOffset - 10 -- Extra spacer

        -- ═══════════════════════════════════════════════════════════════
        -- GRAVITY RECOMMENDED FPS SETTINGS
        -- ═══════════════════════════════════════════════════════════════
        local fpsHeader = GUI:CreateSectionHeader(content, "Gravity Recommended FPS Settings")
        fpsHeader:SetPoint("TOPLEFT", PADDING, yOffset)
        yOffset = yOffset - fpsHeader.gap
        yOffset = yOffset - 10

        local fpsDesc = GUI:CreateInfoBox(content,
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

        local applyFpsBtn = GUI:CreateButton(content, "Apply FPS Settings", 200, 28, function()
            ApplyGravityFPSSettings()
            if restoreFpsBtn then
                restoreFpsBtn:SetAlpha(1)
                restoreFpsBtn:Enable()
            end
            UpdateFPSStatus()
        end)
        applyFpsBtn:SetPoint("TOPLEFT", PADDING, yOffset)

        restoreFpsBtn = GUI:CreateButton(content, "Restore Previous Settings", 200, 28, function()
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

        fpsStatusText = GUI:CreateLabel(content, "", 11, C.accent)
        GUI:SetFont(fpsStatusText, 11, "")
        fpsStatusText:SetPoint("TOPLEFT", PADDING, yOffset)
        
        UpdateFPSStatus()
        
        yOffset = yOffset - 22
        
        -- Set Final Height of Content
        content:SetHeight(math.abs(yOffset) + 20)
    end,
})
