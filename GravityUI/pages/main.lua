-- GravityUI - Main Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

---------------------------------------------------------------------------
-- Gravity RECOMMENDED FPS SETTINGS (1:1 identical to EllesmereUI)
---------------------------------------------------------------------------
local Gravity_FPS_CVARS = {
    -- Graphics Quality
    ["graphicsShadowQuality"] = "1",             -- Fair
    ["graphicsLiquidDetail"] = "0",              -- Low
    ["graphicsParticleDensity"] = "5",           -- Ultra
    ["graphicsSSAO"] = "0",                      -- Off
    ["graphicsDepthEffects"] = "0",              -- Off
    ["graphicsComputeEffects"] = "0",            -- Off
    ["graphicsOutlineMode"] = "0",               -- Off
    ["graphicsTextureResolution"] = "2",         -- High
    ["graphicsSpellDensity"] = "0",              -- Essential
    ["graphicsProjectedTextures"] = "1",         -- On
    ["graphicsViewDistance"] = "0",              -- Level 1
    ["graphicsEnvironmentDetail"] = "0",         -- Level 1
    ["graphicsGroundClutter"] = "0",             -- Level 1
    ["RAIDsettingsEnabled"] = "0",               -- Same settings everywhere
    ["ResampleAlwaysSharpen"] = "1",
    -- Audio
    ["Sound_EnableReverb"] = "0",                -- Reduce DSP overhead
}

---------------------------------------------------------------------------
-- FPS DISPLAY METADATA
---------------------------------------------------------------------------
local function _b(v)   local n = tonumber(v); return (n == 1 or v == "true") and "Enabled" or "Disabled" end
local function _ib(v)  local n = tonumber(v); return (n == 0) and "Disabled" or "Enabled" end
local function _lvl(v) return "Level " .. ((tonumber(v) or 0) + 1) end

local Gravity_FPS_DISPLAY = {
    graphics = {
        { cvar = "graphicsShadowQuality",    name = "Shadow Quality",     display = function(v)
            return ({["0"]="Low",["1"]="Fair",["2"]="Good",["3"]="High",["4"]="Ultra",["5"]="Ultra High"})[v] or v end },
        { cvar = "graphicsSSAO",             name = "SSAO",               display = function(v)
            return ({["0"]="Disabled",["1"]="Low",["2"]="Good",["3"]="High",["4"]="Ultra"})[v] or v end },
        { cvar = "graphicsDepthEffects",     name = "Depth Effects",      display = function(v)
            return ({["0"]="Disabled",["1"]="Low",["2"]="Good",["3"]="High"})[v] or v end },
        { cvar = "graphicsComputeEffects",   name = "Compute Effects",    display = function(v)
            return ({["0"]="Disabled",["1"]="Low",["2"]="Good",["3"]="High"})[v] or v end },
        { cvar = "graphicsLiquidDetail",     name = "Liquid Detail",      display = function(v)
            return ({["0"]="Low",["1"]="Fair",["2"]="Good",["3"]="High"})[v] or v end },
        { cvar = "graphicsParticleDensity",  name = "Particle Density",   display = function(v)
            return ({["0"]="None",["1"]="Low",["2"]="Fair",["3"]="Good",["4"]="High",["5"]="Ultra"})[v] or v end },
        { cvar = "graphicsSpellDensity",     name = "Spell Density",      display = function(v)
            return ({["0"]="Essential",["1"]="Low",["2"]="Fair",["3"]="Good",["4"]="High",["5"]="Ultra"})[v] or v end },
        { cvar = "graphicsOutlineMode",      name = "Outline Mode",       display = function(v)
            return ({["0"]="Disabled",["1"]="Low",["2"]="High",["3"]="Ultra High"})[v] or v end },
        { cvar = "graphicsTextureResolution",name = "Texture Resolution", display = function(v)
            return ({["1"]="Low",["2"]="High",["3"]="Ultra"})[v] or v end },
        { cvar = "graphicsProjectedTextures",name = "Projected Textures", display = _b },
    },
    detail = {
        { cvar = "graphicsViewDistance",     name = "View Distance",      display = _lvl },
        { cvar = "graphicsEnvironmentDetail",name = "Environment Detail", display = _lvl },
        { cvar = "graphicsGroundClutter",    name = "Ground Clutter",     display = _lvl },
    },
    advanced = {
        { cvar = "RAIDsettingsEnabled",     name = "Raid Settings",      display = function(v)
            return tonumber(v) == 1 and "Separate" or "Same Everywhere" end },
        { cvar = "ResampleAlwaysSharpen",   name = "Always Sharpen",     display = _b },
        { cvar = "Sound_EnableReverb",      name = "Sound Reverb",       display = _b },
    },
}

---------------------------------------------------------------------------
-- HELPER: FPS Settings Functions
---------------------------------------------------------------------------
local function BackupCurrentFPSSettings()
    local db = ns.GetDB()
    if not db then return false end

    -- One-time store: only snapshot if no backup exists yet
    if db.fpsBackup then
        -- Backfill CVars added to the list after the user's original snapshot,
        -- so Restore covers them too (mirrors EllesmerUI backfill logic).
        local backup = db.fpsBackup
        for cvar, _ in pairs(Gravity_FPS_CVARS) do
            if backup[cvar] == nil then
                local success, current = pcall(C_CVar.GetCVar, cvar)
                if success and current then
                    backup[cvar] = current
                end
            end
        end
        if backup["Contrast"] == nil then
            backup["Contrast"] = C_CVar.GetCVar("Contrast")
        end
        return true
    end

    local backup = {}
    for cvar, _ in pairs(Gravity_FPS_CVARS) do
        local success, current = pcall(C_CVar.GetCVar, cvar)
        if success and current then
            backup[cvar] = current
        end
    end
    -- Store Contrast separately (applied dynamically, not in the table)
    backup["Contrast"] = C_CVar.GetCVar("Contrast")
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
    local backup = db.fpsBackup
    for cvar, value in pairs(Gravity_FPS_CVARS) do
        local saved = backup[cvar]
        if saved then
            local ok = pcall(C_CVar.SetCVar, cvar, tostring(saved))
            if ok then successCount = successCount + 1 else failCount = failCount + 1 end
        end
    end
    -- Restore Contrast separately
    if backup["Contrast"] then
        pcall(C_CVar.SetCVar, "Contrast", tostring(backup["Contrast"]))
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

    -- Contrast boost: if current contrast <= 55, add 10 (mirrors EllesmerUI logic)
    local curContrast = tonumber(C_CVar.GetCVar("Contrast")) or 50
    if curContrast <= 55 then
        pcall(C_CVar.SetCVar, "Contrast", tostring(curContrast + 10))
    end

    ns.Print("Applied " .. successCount .. " FPS settings. Backup saved.")
end

local function CvarsEqual(current, target)
    -- Exact string match first
    if tostring(current) == tostring(target) then return true end
    -- Numeric comparison for float CVARs (WoW may return "75.000000" for "75")
    local nCur = tonumber(current)
    local nTgt = tonumber(target)
    if nCur and nTgt then
        return math.abs(nCur - nTgt) < 0.001
    end
    return false
end

local function CheckCVarsMatch()
    local matchCount, totalCount = 0, 0
    -- Only check CVars that are actually visible in the UI table categories
    for catKey, items in pairs(Gravity_FPS_DISPLAY) do
        for _, item in ipairs(items) do
            local cvar = item.cvar
            local expectedVal = Gravity_FPS_CVARS[cvar]
            if expectedVal then
                totalCount = totalCount + 1
                local currentVal = C_CVar.GetCVar(cvar)
                if CvarsEqual(currentVal, expectedVal) then
                    matchCount = matchCount + 1
                end
            end
        end
    end
    return matchCount == totalCount, matchCount, totalCount
end

---------------------------------------------------------------------------
-- MAIN PAGE BUILD
---------------------------------------------------------------------------
local PADDING = 10

-- Information tab builder is injected from information.lua
local function BuildInformationPlaceholder(parent)
    local scroll, content = ns.GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    local label = ns.GUI:CreateLabel(content, "Loading...", 12, C.text)
    label:SetPoint("TOPLEFT", PADDING, -20)
    content:SetHeight(60)
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
        -- Sync EllesmereUI first (it handles UIParent:SetScale internally)
        if C_AddOns.IsAddOnLoaded("EllesmereUI") then
            local E = _G.EllesmereUI
            if E and E.PP and E.PP.SetUIScale then
                E.PP.SetUIScale(val)
            else
                pcall(function() UIParent:SetScale(val) end)
            end
            if _G.EllesmereUIDB then
                _G.EllesmereUIDB.ppUIScale = val
                _G.EllesmereUIDB.ppUIScaleAuto = false
            end
        else
            pcall(function() UIParent:SetScale(val) end)
        end
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
        -- Sync EllesmereUI when loaded (same logic as ApplyPreset)
        if C_AddOns.IsAddOnLoaded("EllesmereUI") then
            local E = _G.EllesmereUI
            if E and E.PP and E.PP.SetUIScale then
                E.PP.SetUIScale(val)
            else
                pcall(function() UIParent:SetScale(val) end)
            end
            if _G.EllesmereUIDB then
                _G.EllesmereUIDB.ppUIScale = val
                _G.EllesmereUIDB.ppUIScaleAuto = false
            end
        else
            pcall(function() UIParent:SetScale(val) end)
        end
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
    local PAD     = PADDING
    local ROW_H   = 26

    -- Header
    local fpsHeader = ns.GUI:CreateSectionHeader(content, "Gravity Recommended FPS Settings")
    fpsHeader:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - fpsHeader.gap - 10

    -- Description
    local fpsDesc = ns.GUI:CreateInfoBox(content,
        "|cff00BFFFGravity's|r optimized settings for competitive play. " ..
        "|cff00FF80Green|r = already optimal.  |cffFF8800Orange|r = differs from target. " ..
        "Your current settings are backed up when you first click Apply.")
    fpsDesc:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - fpsDesc:GetHeight() - 20



    -- Forward-declare so row closures can reference it
    local UpdateAllRows
    local allRowUpdaters = {}
    local restoreFpsBtn

    -- Buttons
    local applyFpsBtn = ns.GUI:CreateButton(content, "Apply All Settings", 185, 28, function()
        ApplyGravityFPSSettings()
        if restoreFpsBtn then restoreFpsBtn:SetAlpha(1); restoreFpsBtn:Enable() end
        -- Delay refresh so WoW has time to process all SetCVar calls
        C_Timer.After(0.3, function() if UpdateAllRows then UpdateAllRows() end end)
    end)
    applyFpsBtn:SetPoint("TOPLEFT", PAD, yOffset)

    restoreFpsBtn = ns.GUI:CreateButton(content, "Restore Previous Settings", 200, 28, function()
        if RestorePreviousFPSSettings() then
            restoreFpsBtn:SetAlpha(0.5)
            restoreFpsBtn:Disable()
        end
        if UpdateAllRows then UpdateAllRows() end
    end)
    restoreFpsBtn:SetPoint("LEFT", applyFpsBtn, "RIGHT", 10, 0)
    if not db.fpsBackup then restoreFpsBtn:SetAlpha(0.5); restoreFpsBtn:Disable() end

    yOffset = yOffset - 38

    -- Status line
    local statusText = ns.GUI:CreateLabel(content, "", 11, C.textMuted)
    ns.GUI:SetFont(statusText, 11, "")
    statusText:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - 26

    -- Row builder helper
    local function CreateCVarRow(cvar, name, displayFn)
        local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
        row:SetSize(570, ROW_H)
        row:SetPoint("TOPLEFT", PAD, yOffset)
        ns.GUI:CreateBackdrop(row, {0.09, 0.09, 0.09, 0.32}, C.border)

        local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ns.GUI:SetFont(nameLabel, 11, "")
        nameLabel:SetPoint("LEFT", 8, 0)
        nameLabel:SetWidth(190)
        nameLabel:SetJustifyH("LEFT")
        nameLabel:SetText(name)
        nameLabel:SetTextColor(C.text[1], C.text[2], C.text[3])

        local curLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ns.GUI:SetFont(curLabel, 11, "")
        curLabel:SetPoint("LEFT", nameLabel, "RIGHT", 4, 0)
        curLabel:SetWidth(140)
        curLabel:SetJustifyH("LEFT")

        local sep = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ns.GUI:SetFont(sep, 11, "")
        sep:SetPoint("LEFT", curLabel, "RIGHT", 2, 0)
        sep:SetText("|cff444444" .. (string.char(226, 134, 146)) .. "|r")  -- unicode arrow →

        local optLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ns.GUI:SetFont(optLabel, 11, "")
        optLabel:SetPoint("LEFT", sep, "RIGHT", 4, 0)
        optLabel:SetWidth(140)
        optLabel:SetJustifyH("LEFT")

        local function Refresh()
            local rawCur = C_CVar.GetCVar(cvar)
            local rawOpt = Gravity_FPS_CVARS[cvar]
            local dispCur = displayFn and displayFn(rawCur) or (rawCur or "?")
            local dispOpt = displayFn and displayFn(rawOpt) or (rawOpt or "?")
            local isOptimal = CvarsEqual(rawCur, rawOpt)
            curLabel:SetText(isOptimal
                and "|cff00CC66" .. dispCur .. "|r"
                or  "|cffFF8800" .. dispCur .. "|r")
            optLabel:SetText("|cff666666" .. dispOpt .. "|r")
        end
        Refresh()
        table.insert(allRowUpdaters, Refresh)

        yOffset = yOffset - (ROW_H + 3)
    end

    -- Category definitions
    local catDefs = {
        { key = "graphics", label = "Graphics Quality" },
        { key = "detail",   label = "View Distance & Detail" },
        { key = "advanced", label = "Advanced" },
    }

    for _, cat in ipairs(catDefs) do
        local items = Gravity_FPS_DISPLAY[cat.key]
        if items and #items > 0 then
            local catHead = ns.GUI:CreateSectionHeader(content, cat.label)
            catHead:SetPoint("TOPLEFT", PAD, yOffset)
            yOffset = yOffset - catHead.gap - 4
            for _, item in ipairs(items) do
                CreateCVarRow(item.cvar, item.name, item.display)
            end
            yOffset = yOffset - 8
        end
    end

    -- Build UpdateAllRows now that allRowUpdaters is fully populated
    UpdateAllRows = function()
        local _, matched, total = CheckCVarsMatch()
        local needed = total - matched
        if needed == 0 then
            statusText:SetText("|cff00CC66All " .. total .. " settings are optimal|r")
        elseif needed <= 5 then
            statusText:SetText(string.format("|cffFFCC00%d/%d settings still differ - a /reload may be needed for GPU CVars|r", needed, total))
        else
            statusText:SetText(string.format("|cffFF8800%d/%d settings need updating|r", needed, total))
        end
        for _, fn in ipairs(allRowUpdaters) do fn() end
    end
    UpdateAllRows()

    content:SetHeight(math.abs(yOffset) + 40)
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
    
    local cb0 = ns.GUI:CreateCheckbox(content, "Scrolling Combat Text (Self)", "scrollingCombatText", dbUI, function(enabled) SetCVar("enableFloatingCombatText", enabled and "1" or "0") end)
    cb0:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 30

    local cb1 = ns.GUI:CreateCheckbox(content, "Show Damage Numbers", "showDamageNumbers", dbUI, function(enabled) SetCVar("floatingCombatTextCombatDamage_v2", enabled and "1" or "0") end)
    cb1:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 30

    local cb2 = ns.GUI:CreateCheckbox(content, "Show Healing Numbers", "showHealingNumbers", dbUI, function(enabled) SetCVar("floatingCombatTextCombatHealing_v2", enabled and "1" or "0") end)
    cb2:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - 40
    
    if dbUI.spellQueueWindow == nil then dbUI.spellQueueWindow = tonumber(GetCVar("SpellQueueWindow")) or 400 end
    local slider = ns.GUI:CreateSlider(content, "Spell Queue Window (ms)", 0, 400, "spellQueueWindow", dbUI, function(val) SetCVar("SpellQueueWindow", tostring(val)) end, 10)
    slider:SetPoint("TOPLEFT", PADDING, yOffset)
    slider:SetWidth(400)
    yOffset = yOffset - 55

    -- Info box
    local sqInfo = ns.GUI:CreateInfoBox(content,
        "Adjust your Spell Queue Window (0–400ms) to roughly 100ms above your average latency (ping) for optimal performance. " ..
        "Example: 40ms ping → set to ~140ms. Too low = missed inputs. Too high = delayed response.")
    sqInfo:SetPoint("TOPLEFT", PADDING, yOffset)
    yOffset = yOffset - sqInfo:GetHeight() - 10

    -- Ping label + optimal button on the same row
    local pingLabel = ns.GUI:CreateLabel(content, "", 11, C.textMuted)
    ns.GUI:SetFont(pingLabel, 11, "")
    pingLabel:SetPoint("TOPLEFT", PADDING, yOffset)
    pingLabel:SetWidth(240)

    local function GetCurrentPing()
        local _, _, homeMs = GetNetStats()
        return tonumber(homeMs) or 0
    end

    local function UpdatePingLabel()
        local ms = GetCurrentPing()
        pingLabel:SetText(string.format("|cffaaaaaa Current Ping:|r |cff%s%d ms|r",
            ms > 150 and "ff6644" or ms > 80 and "ffcc44" or "44ff88", ms))
    end
    UpdatePingLabel()

    local optBtn = ns.GUI:CreateButton(content, "Set Optimal  (Ping + 100ms)", 200, 26, function()
        local ms = GetCurrentPing()
        local optimal = math.min(400, math.max(0, ms + 100))
        -- Round to nearest 10 to match slider step
        optimal = math.floor(optimal / 10 + 0.5) * 10
        dbUI.spellQueueWindow = optimal
        SetCVar("SpellQueueWindow", tostring(optimal))
        -- container.SetValue has no self-wrapper → must use dot syntax, not colon
        -- Also directly update the raw slider thumb (x100 multiplier) + editbox text
        if slider then
            if slider.SetValue then slider.SetValue(optimal, true) end
            if slider.slider then slider.slider:SetValue(optimal * 100) end  -- thumb position
            if slider.editBox then slider.editBox:SetText(string.format("%.2f", optimal)) end
        end
        UpdatePingLabel()
        ns.Print(string.format("Spell Queue set to |cff00ccff%dms|r (ping %dms + 100ms)", optimal, ms))
    end)
    optBtn:SetPoint("LEFT", pingLabel, "RIGHT", 12, 0)

    -- Refresh ping label when panel is shown (live value each visit)
    content:HookScript("OnShow", UpdatePingLabel)

    yOffset = yOffset - 36

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
    local cfg = ns.Movers:GetEditModeSettings()

    -- Header
    local header = ns.GUI:CreateSectionHeader(content, "GravityUI Edit Mode")
    header:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - header.gap - 10

    local infoBox = ns.GUI:CreateInfoBox(content,
        "|cff30D1FFGravityUI Edit Mode Suite:|r\n" ..
        "• |cff30d1ffBlue Overlays|r: Enabled modules | |cffff4444Red Overlays|r: Disabled modules.\n" ..
        "• |cff00FF80Left-Click & Drag|r to move frames (with Grid & Magnetic Element snapping).\n" ..
        "• |cff00FF80Left-Click|r an element to select it and nudge with |cffffd700Arrow Keys|r (|cffffffff1px|r / |cffffffffShift: 10px|r).\n" ..
        "• |cffFF9900Right-Click|r an element overlay to toggle the module on/off directly.")
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
        end
    end)
    enableBtn:SetPoint("LEFT", btnContainer, "LEFT", 0, 0)

    local disableBtn = ns.GUI:CreateButton(btnContainer, "Disable GravityUI Edit Mode", 210, 32, function()
        if Movers then
            Movers:SetEditMode(false)
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
            statusLabel:SetText("|cff00FF80● Edit Mode ACTIVE — Use Mouse or Arrow Keys to position elements|r")
        else
            statusLabel:SetText("")
        end
    end
    RefreshStatus()

    hooksecurefunc(enableBtn, "Click", RefreshStatus)
    hooksecurefunc(disableBtn, "Click", RefreshStatus)

    -- ── Grid & Snapping Settings ──────────────────────────────────────────
    yOffset = yOffset - 6
    local settingsHeader = ns.GUI:CreateSectionHeader(content, "Grid & Snapping Options")
    settingsHeader:SetPoint("TOPLEFT", PAD, yOffset)
    yOffset = yOffset - settingsHeader.gap - 8

    -- Row 1: Show Screen Grid & Snap to Grid
    local optRow1 = CreateFrame("Frame", nil, content)
    optRow1:SetPoint("TOPLEFT", PAD, yOffset)
    optRow1:SetSize(520, 26)

    local cbShowGrid = ns.GUI:CreateCheckbox(optRow1, "Show Screen Grid", "showGrid", cfg, function(v)
        Movers:UpdateGrid()
    end)
    cbShowGrid:SetPoint("LEFT", optRow1, "LEFT", 0, 0)

    local cbSnapGrid = ns.GUI:CreateCheckbox(optRow1, "Snap to Grid", "snapToGrid", cfg, function(v) end)
    cbSnapGrid:SetPoint("LEFT", optRow1, "LEFT", 240, 0)

    yOffset = yOffset - 32

    -- Row 2: Show Disabled Modules & Snap to Elements
    local optRow2 = CreateFrame("Frame", nil, content)
    optRow2:SetPoint("TOPLEFT", PAD, yOffset)
    optRow2:SetSize(520, 26)

    local cbShowDisabled = ns.GUI:CreateCheckbox(optRow2, "Show Disabled Modules", "showDisabled", cfg, function(v)
        Movers:UpdateDisplay()
    end)
    cbShowDisabled:SetPoint("LEFT", optRow2, "LEFT", 0, 0)

    local cbSnapElem = ns.GUI:CreateCheckbox(optRow2, "Snap to Elements", "snapToElements", cfg, function(v) end)
    cbSnapElem:SetPoint("LEFT", optRow2, "LEFT", 240, 0)

    yOffset = yOffset - 34

    -- Row 3: Grid Size Dropdown
    local optRow3 = CreateFrame("Frame", nil, content)
    optRow3:SetPoint("TOPLEFT", PAD, yOffset)
    optRow3:SetSize(520, 32)

    local gridSizes = {
        { value = 8, text = "8 px" },
        { value = 16, text = "16 px" },
        { value = 32, text = "32 px (Standard)" },
        { value = 64, text = "64 px" },
    }
    local ddGrid = ns.GUI:CreateDropdown(optRow3, "Grid Size", gridSizes, "gridSize", cfg, function(v)
        Movers:UpdateGrid()
    end)
    ddGrid:SetPoint("LEFT", optRow3, "LEFT", 0, 0)

    yOffset = yOffset - 46

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
            local isEnabled = Movers:IsElementEnabled(name)

            -- Row
            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetSize(520, 28)
            row:SetPoint("TOPLEFT", PAD, yOffset)
            ns.GUI:CreateBackdrop(row, {0.12, 0.12, 0.12, 0.35}, C.border)

            -- Status Indicator Pill
            local statusDot = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            statusDot:SetPoint("LEFT", 8, 0)
            statusDot:SetText(isEnabled and "|cff00FF80●|r" or "|cffff4444●|r")

            -- Label
            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            ns.GUI:SetFont(lbl, 12, "")
            lbl:SetPoint("LEFT", statusDot, "RIGHT", 6, 0)
            lbl:SetText(displayLabel .. (isEnabled and "" or " |cffff4444(Disabled)|r"))
            lbl:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

            -- Enable / Disable Toggle Button
            local toggleModuleBtn = ns.GUI:CreateButton(row, isEnabled and "Disable" or "Enable", 64, 20, function() end)
            toggleModuleBtn:SetPoint("RIGHT", row, "RIGHT", -68, 0)
            toggleModuleBtn:SetScript("OnClick", function()
                Movers:ToggleElementEnabled(name)
                local updated = Movers:IsElementEnabled(name)
                statusDot:SetText(updated and "|cff00FF80●|r" or "|cffff4444●|r")
                lbl:SetText(displayLabel .. (updated and "" or " |cffff4444(Disabled)|r"))
                if toggleModuleBtn.text then
                    toggleModuleBtn.text:SetText(updated and "Disable" or "Enable")
                end
            end)

            -- Move single frame button
            local toggleBtn = ns.GUI:CreateButton(row, "Move", 56, 20, function() end)
            toggleBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)

            local moverActive = false
            toggleBtn:SetScript("OnClick", function()
                moverActive = not moverActive
                if Movers and data.toggleFunc then
                    pcall(data.toggleFunc, data.frame, moverActive, moverActive)
                end
                if data.frame then
                    Movers:ApplyEditModeStyle(data.frame, moverActive, name)
                end
                if toggleBtn.text then
                    toggleBtn.text:SetText(moverActive and "Done" or "Move")
                    toggleBtn.text:SetTextColor(moverActive and C.accent[1] or C.text[1], moverActive and C.accent[2] or C.text[2], moverActive and C.accent[3] or C.text[3], 1)
                end
            end)

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
        { name = "Information",   builder = BuildInformationPlaceholder },
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
