-- GravityUI Core Initialization
local ADDON_NAME, ns = ...

-- Keybinding display name (must be global before Bindings.xml loads)
BINDING_NAME_GravityUI_TOGGLE_OPTIONS = "Open GravityUI Options"

-- Create main addon object
local Addon = LibStub("AceAddon-3.0"):NewAddon("GravityUI", "AceConsole-3.0", "AceEvent-3.0")
ns.Addon = Addon

-- Database reference
ns.db = nil
ns.trackedFonts = {}

-- Database caching
local dbCache = nil
function ns.GetDB()
    if not dbCache and ns.db then
        dbCache = ns.db.profile
    end
    return dbCache
end

-- Helper to clear caches
function ns.InvalidateCaches()
    dbCache = nil
    ns.accentCache = nil
end

-- Standard Print Helper
function ns.Print(msg)
    print("|cFF30D1FFGravityUI|r " .. tostring(msg))
end

-- Get AceDB object for profile management
function ns.GetAceDB()
    return ns.db
end

-- Reset all settings to defaults
function ns.ResetDB()
    if ns.db then
        ns.db:ResetProfile()
    end
end

-- Get accent color (with class color option and caching)
ns.accentCache = nil
function ns.GetAccentColor()
    if ns.accentCache then
        return unpack(ns.accentCache)
    end

    local db = ns.GetDB()
    local r, g, b, a = 0, 0.749, 1, 1 -- Default fallback

    if db and db.general and db.general.useClassColorTheme then
        local _, class = UnitClass("player")
        local color = class and C_ClassColor.GetClassColor(class)
        if color then
            r, g, b, a = color.r, color.g, color.b, 1
        end
    elseif db and db.general and db.general.themeColor then
        local tc = db.general.themeColor
        if tc[1] then
            r, g, b, a = tc[1], tc[2], tc[3], tc[4] or 1
        end
    else
        r, g, b, a = unpack(ns.DEFAULT_ACCENT or {0, 0.749, 1, 1})
    end

    ns.accentCache = {r, g, b, a}
    return r, g, b, a
end

-- Get theme background color
function ns.GetThemeBgColor()
    local db = ns.GetDB()
    local tbc = db and db.general and db.general.themeBgColor
    if tbc and tbc[1] then
        return tbc[1], tbc[2], tbc[3], tbc[4] or 1
    end
    -- Fallback to default bg color from constants (re-unpacked)
    return 0.117, 0.121, 0.133, 1
end

-- Refresh accent colors throughout UI
function ns.RefreshAccentColors()
    ns.InvalidateCaches()
    
    if ns.GUI and ns.GUI.RefreshColors then
        ns.GUI:RefreshColors()
    end
    -- explicitly refresh modules that rely on accent color
    if ns.RefreshMinimap then ns.RefreshMinimap() end
    if ns.RefreshDatapanels then ns.RefreshDatapanels() end
    if ns.RefreshSkyriding then ns.RefreshSkyriding() end
    if ns.RefreshScreenIndicators then ns.RefreshScreenIndicators() end
    if ns.RefreshCombatTimer then ns.RefreshCombatTimer() end
    if ns.Character and ns.Character.RefreshBackground then ns.Character.RefreshBackground() end
    
    -- New refresh calls for UI Styling
    if ns.Styling and ns.Styling.Refresh then ns.Styling:Refresh() end
    if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end -- Alerts re-init resets colors
    if ns.Loot and ns.Loot.RefreshStyling then ns.Loot:RefreshStyling() end
    if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot:RefreshHistoryStyling() end
    if ns.Loot and ns.Loot.RefreshHistoryStyling then ns.Loot:RefreshHistoryStyling() end
    if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    if ns.Objectives and ns.Objectives.Initialize then ns.Objectives:Initialize() end
    if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
    if ns.TrackedBuffBar and ns.TrackedBuffBar.Refresh then ns.TrackedBuffBar:Refresh() end
end

-- Get global font settings
function ns.GetFont()
    local db = ns.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    local outline = (db and db.general and db.general.fontOutline) or "OUTLINE"
    
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local fontPath = LSM and LSM:Fetch("font", fontName) or ns.FONT_PATH
    
    return fontPath, outline
end

-- AceAddon callback - initializes database
function Addon:OnInitialize()
    -- Initialize database with defaults
    ns.db = LibStub("AceDB-3.0"):New("GravityUI_DB", ns.Defaults, true)
    
    -- Enhance with LibDualSpec for spec-based profiles
    local LibDualSpec = LibStub("LibDualSpec-1.0", true)
    if LibDualSpec then
        LibDualSpec:EnhanceDatabase(ns.db, "GravityUI")
    end
    -- Force reset if minimap is missing (migration helper)
    -- (Removed reset logic to prevent settings loss)
    -- if not ns.db.profile.minimap or not ns.db.profile.minimap.datatext then
    --     print("|cFF30D1FFGravityUI:|r Detecting missing Minimap settings... Resetting profile to apply defaults.")
    --     ns.db:ResetProfile()
    -- end

    -- Reset temporary states
    if ns.db.profile.minimap and ns.db.profile.minimap.dungeonEye then
        ns.db.profile.minimap.dungeonEye.preview = false
    end
    
    -- Register for profile change events
    for _, event in ipairs({"OnProfileChanged", "OnProfileCopied", "OnProfileReset"}) do
        ns.db.RegisterCallback(ns, event, function()
            -- Refresh in-game UI elements (Minimap, Datapanels, Colors, local changes)
            ns.RefreshAccentColors()
            
            -- Refresh GUI if open
            if ns.GUI and ns.GUI.RefreshAll then
                ns.GUI:RefreshAll()
            end
        end)
    end
    
    -- Register slash commands
    self:RegisterChatCommand("gui", "SlashCommandOpen")
    self:RegisterChatCommand("gravityui", "SlashCommandOpen")
    self:RegisterChatCommand("rl", "SlashCommandReload")
    self:RegisterChatCommand("kb", "SlashCommandKeybind")
    
    ns.Print("loaded. Type |cFFFFFF00/gui|r to open settings.")
    ns.Print("using profile: |cFF00BFFF" .. ns.db:GetCurrentProfile() .. "|r")
    
    -- Character panel module auto-initializes via event registration
end

-- Apply UI Scale from DB
function ns.ApplyUIScale()
    local db = ns.GetDB()
    if db and db.general and db.general.uiScale then
        pcall(function()
            if math.abs(UIParent:GetScale() - db.general.uiScale) > 0.001 then
                UIParent:SetScale(db.general.uiScale)
            end
        end)
    end
end

-- Refresh functions
ns.RefreshEverything = function()
    ns.ApplyUIScale()
    if ns.Styling then ns.Styling:Refresh() end
    if ns.Media then ns.Media:Update() end
    
    -- Modules
    if ns.Modules then
        for _, module in pairs(ns.Modules) do
            if module.Refresh then
                module:Refresh()
            end
        end
    end
end

-- AceAddon callback - runs after OnInitialize
function Addon:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Initialize Modules
    if ns.InterruptTracker and ns.InterruptTracker.Initialize then 
        ns.InterruptTracker.Initialize() 
        if ns.InterruptTracker.ApplySettings then ns.InterruptTracker.ApplySettings() end
    end
    
    if ns.Mail and ns.Mail.Initialize then
        ns.Mail.Initialize()
        if ns.Mail.ApplySettings then ns.Mail.ApplySettings() end
    end
    
    -- Initial Updates
    ns.RefreshEverything()
    
    -- Initialize Movers
    if ns.Movers and ns.Movers.Initialize then ns.Movers:Initialize() end

    -- Debug Command for Quick Keybind
    _G["SLASH_GUIKB1"] = "/guikb"
    SlashCmdList["GUIKB"] = function()
        ns.Addon:SlashCommandKeybind()
    end
end

-- Slash command handler
function Addon:SlashCommandOpen(input)
    input = input and input:lower():trim() or ""
    
    if input == "editmode" then
        if SlashCmdList["EDITMODE"] then
            SlashCmdList["EDITMODE"]("")
        elseif EditModeManagerFrame then
            ShowUIPanel(EditModeManagerFrame)
        end
        return
    end
    
    if input == "cdm" then
        -- Toggle Cooldown Settings
        if CooldownViewerSettings then
            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
        else
            ns.Print("Cooldown Settings not available.")
        end
        -- Print welcome message
        ns.Print("Version " .. (C_AddOns.GetAddOnMetadata("GravityUI", "Version") or "Dev") .. " Loaded.")
        return
    end
    
    -- Default: Open GUI
    if ns.GUI then
        ns.GUI:Toggle()
    else
        ns.Print("GUI not loaded yet. Try again in a moment.")
    end
end

-- Reload UI command
function Addon:SlashCommandReload()
    ReloadUI()
end

-- Toggle Quick Keybind Mode
function Addon:SlashCommandKeybind()
    if not C_AddOns.IsAddOnLoaded("Blizzard_QuickKeybind") then
        C_AddOns.LoadAddOn("Blizzard_QuickKeybind")
    end
    
    if QuickKeybindFrame then
        if QuickKeybindFrame:IsShown() then
            HideUIPanel(QuickKeybindFrame)
        else
            ShowUIPanel(QuickKeybindFrame)
            
            -- Inject Custom Save & Exit Button
            if not QuickKeybindFrame.GravityUISaveExit then
                local btn = CreateFrame("Button", "GravityUI_QuickKeybind_SaveExit", QuickKeybindFrame, "UIPanelButtonTemplate")
                QuickKeybindFrame.GravityUISaveExit = btn
                btn:SetText("Save & Exit")
                btn:SetSize(140, 30)
                -- Position it below the frame to avoid overlapping the checkbox
                btn:SetPoint("TOP", QuickKeybindFrame, "BOTTOM", 0, -10) 
                
                btn:SetScript("OnClick", function()
                     -- 1. Trigger the standard "Okay" (Save) logic
                     if QuickKeybindFrame.okayButton then
                         QuickKeybindFrame.okayButton:Click()
                     elseif QuickKeybindFrame.OkayButton then
                         QuickKeybindFrame.OkayButton:Click()
                     end
                     
                     -- 2. Force Close the QuickKeybindFrame itself (in case click didn't)
                     HideUIPanel(QuickKeybindFrame)
                     
                     -- 3. Close Parent Menus (Settings / Game Menu) to return to game
                     if SettingsPanel and SettingsPanel:IsShown() then 
                        HideUIPanel(SettingsPanel) 
                     end
                     if GameMenuFrame and GameMenuFrame:IsShown() then 
                        HideUIPanel(GameMenuFrame) 
                     end
                end)
            end
        end
    end
end

-- Event handler

-- Event handler
function Addon:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
    -- Initialize custom datapanels
    if ns.Datapanels and ns.Datapanels.Init then ns.Datapanels:Init() end
    if ns.Styling and ns.Styling.Initialize then ns.Styling:Initialize() end
    
    -- CHUNK 1: +0.5 Seconds (ActionBars, PlayerFrames, etc.)
    C_Timer.After(0.5, function()
        if ns.Alerts and ns.Alerts.Initialize then ns.Alerts:Initialize() end
        if ns.InstanceFrames and ns.InstanceFrames.Initialize then ns.InstanceFrames:Initialize() end
    end)
    
    -- CHUNK 2: +1.0 Seconds (Loot, Combat Helpers, Raid Warnings)
    C_Timer.After(1.0, function()
        if ns.Loot and ns.Loot.Initialize then ns.Loot:Initialize() end
        if ns.RaidWarnings and ns.RaidWarnings.Initialize then ns.RaidWarnings:Initialize() end
        if ns.TrackedBuffBar and ns.TrackedBuffBar.Init then ns.TrackedBuffBar:Init() end
        if ns.InterruptTracker and ns.InterruptTracker.Initialize then ns.InterruptTracker:Initialize() end
    end)
    
    -- CHUNK 3: +1.5 Seconds (Secondary Systems, Objectives, XP)
    C_Timer.After(1.5, function()
        if ns.Objectives and ns.Objectives.Initialize then ns.Objectives:Initialize() end
        if ns.XPRep and ns.XPRep.Initialize then ns.XPRep:Initialize() end
        if ns.GUICDM_Keybinds and ns.GUICDM_Keybinds.Init then ns.GUICDM_Keybinds:Init() end
        if ns.Mail and ns.Mail.Initialize then ns.Mail.Initialize() end
    end)


    

    

end

-- Out of Combat Queue System
ns.OOCQueue = {}

function ns.QueueOOCAction(func)
    if not InCombatLockdown() then
        func()
    else
        table.insert(ns.OOCQueue, func)
    end
end

-- Process OOC Queue
local function ProcessOOCQueue()
    if InCombatLockdown() then return end
    
    for i = #ns.OOCQueue, 1, -1 do
        local func = table.remove(ns.OOCQueue, i)
        if func then
            pcall(func)
        end
    end
end

local oocFrame = CreateFrame("Frame")
oocFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
oocFrame:SetScript("OnEvent", ProcessOOCQueue)

-- Addon Compartment Functions (for addon button in minimap area)
function GravityUI_CompartmentClick()
    if ns.GUI then
        ns.GUI:Toggle()
    end
end

local GameTooltip = GameTooltip
function GravityUI_CompartmentOnEnter(self, button)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(type(self) ~= "string" and self or button, "ANCHOR_LEFT")
    GameTooltip:AddLine("GravityUI" .. ns.VERSION)
    GameTooltip:AddLine("Left-click to open settings")
    GameTooltip:Show()
end

function GravityUI_CompartmentOnLeave()
    GameTooltip:Hide()
end

-- Additional slash commands for convenience
SLASH_GUICDM1 = "/cdm"
SLASH_GUICDM2 = "/wa"
SlashCmdList["GUICDM"] = function()
    if CooldownViewerSettings then
        CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
    else
        ns.Print("Cooldown Settings not available.")
    end
end

SLASH_GUIEDIT1 = "/edit"
SlashCmdList["GUIEDIT"] = function(msg)
    if SlashCmdList["EDITMODE"] then
        SlashCmdList["EDITMODE"](msg)
    elseif EditModeManagerFrame then
        ShowUIPanel(EditModeManagerFrame)
    end
end

-- Debug command to export current settings for defaults.lua
SLASH_GUIEXPORT1 = "/gui"
SlashCmdList["GUIEXPORT"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    
    if cmd == "exportdefaults" then
        if not ViragDevTool_AddData then
            -- Fallback serialization
             local LibSerialize = LibStub("LibSerialize", true) -- Optional if available
             -- Basic print for now
             ns.Print("Exporting defaults...")
             
             -- Create a frame to hold the text
             local f = CreateFrame("Frame", "GUIExportFrame", UIParent)
             f:SetSize(600, 500)
             f:SetPoint("CENTER")
             f:SetFrameStrata("DIALOG")
             
             local t = f:CreateTexture(nil, "BACKGROUND")
             t:SetAllPoints()
             t:SetColorTexture(0, 0, 0, 0.9)
             
             local s = CreateFrame("ScrollFrame", "GUIExportScroll", f, "UIPanelScrollFrameTemplate")
             s:SetPoint("TOPLEFT", 10, -10)
             s:SetPoint("BOTTOMRIGHT", -30, 40)
             
             local eb = CreateFrame("EditBox", nil, s)
             eb:SetMultiLine(true)
             eb:SetFontObject(ChatFontNormal)
             eb:SetWidth(560)
             eb:SetScript("OnEscapePressed", function() f:Hide() end)
             
             s:SetScrollChild(eb)
             
             local function DumpTable(tbl, indent)
                 if not indent then indent = 0 end
                 local toprint = string.rep(" ", indent) .. "{\n"
                 indent = indent + 4 
                 for k, v in pairs(tbl) do
                     toprint = toprint .. string.rep(" ", indent)
                     if (type(k) == "number") then
                         toprint = toprint .. "[" .. k .. "] = "
                     elseif (type(k) == "string") then
                         toprint = toprint .. k .. " = " 
                     end
                     
                     if (type(v) == "number") then
                         toprint = toprint .. v .. ",\n"
                     elseif (type(v) == "string") then
                         toprint = toprint .. "\"" .. v .. "\",\n"
                     elseif (type(v) == "table") then
                         toprint = toprint .. DumpTable(v, indent) .. ",\n"
                     elseif (type(v) == "boolean") then
                         toprint = toprint .. (v and "true" or "false") .. ",\n"
                     else
                         toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
                     end
                 end
                 toprint = toprint .. string.rep(" ", indent-4) .. "}"
                 return toprint
             end
             
             local serialized = DumpTable(ns.db.profile)
             
             eb:SetText(serialized)
             eb:HighlightText()
             
             local close = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
             close:SetPoint("BOTTOM", 0, 10)
             close:SetSize(100, 25)
             close:SetText("Close")
             close:SetScript("OnClick", function() f:Hide() end)
             
             f:Show()
             ns.Print("Profile serialized. Please copy the text.")
             return
        end
    end

    -- Forward to standard handler
    Addon:SlashCommandOpen(msg)
end

SLASH_GUITESTCLEANUP1 = "/guitestcleanup"
SlashCmdList["GUITESTCLEANUP"] = function()
    local profile = "testUI"
    ns.Print("Cleaning up '" .. profile .. "' profiles...")
    
    local db = ns.GetDB()
    if db then db.installer = db.installer or {} end
    
    -- Iterate registry from Installer (requires access, assumed global ns.GUI.Installer)
    if ns.GUI and ns.GUI.Installer and ns.GUI.Installer.registry then
        for _, addon in ipairs(ns.GUI.Installer.registry) do
            if addon.Check() then
                -- Try to delete profile
                -- Note: Most addons don't have a standardized DeleteProfile in the registry, 
                -- so we might need to rely on the underlying DB object if available.
                local deleted = false
                
                -- Attempt to find the DB object
                local dbObj = nil
                if addon.name == "GravityUI" then dbObj = ns.db 
                elseif addon.name == "Details" and _G.Details then dbObj = _G.Details.db -- Details handles profiles differently though
                elseif addon.name == "Plater" and _G.Plater then dbObj = _G.Plater.db
                elseif addon.name == "BigWigs" and _G.BigWigs3DB then -- BigWigs manual key deletion
                     if _G.BigWigs3DB.profiles then _G.BigWigs3DB.profiles[profile] = nil deleted = true end
                elseif addon.name == "BCDM" and _G.BCDM then dbObj = _G.BCDM.db
                elseif addon.name == "UUF" and _G.UUF then dbObj = _G.UUF.db
                end
                
                if dbObj and dbObj.DeleteProfile then
                    dbObj:DeleteProfile(profile)
                    deleted = true
                end
                
                if deleted then
                    print(" - Deleted from " .. addon.label)
                else
                    print(" - Could not delete from " .. addon.label .. " (Manual deletion required)")
                end
            end
        end
    end
    print("Cleanup complete. Reloading UI...")
    C_Timer.After(2, ReloadUI)
end

SLASH_GUISCAN1 = "/guiscan"
SlashCmdList["GUISCAN"] = function()
    -- Global Scan
    print("=== GravityUI Global Scan ===")
    local found = 0
    for k, v in pairs(_G) do
        if type(k) == "string" then
            local lower = string.lower(k)
            if string.find(lower, "danders") or string.find(lower, "uuf") or string.find(lower, "unhalted") then
                print("Key: " .. k .. " (" .. type(v) .. ")")
                found = found + 1
            end
        end
    end
    print("Scan complete. Found " .. found .. " keys.")
end

SLASH_GUIDEEP1 = "/guideep"
SlashCmdList["GUIDEEP"] = function()
    print("=== Deep Scan: DandersFrames & UUFG ===")
    
    local function ScanTable(name, tbl)
        if not tbl or type(tbl) ~= "table" then
            print(name .. " is not a table or not found.")
            return
        end
        print("Scanning " .. name .. ":")
        local count = 0
        for k, v in pairs(tbl) do
            if type(v) == "function" or (type(k)=="string" and (string.find(string.lower(k), "import") or string.find(string.lower(k), "profile"))) then
                print("  ." .. tostring(k) .. " (" .. type(v) .. ")")
                count = count + 1
            end
        end
        print("  Found " .. count .. " relevant keys.")
    end

    ScanTable("DandersFrames", _G.DandersFrames)
    ScanTable("UUFG", _G.UUFG)
    ScanTable("UUF", _G.UUF)
end
