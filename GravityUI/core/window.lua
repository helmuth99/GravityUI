-- GravityUI Main GUI Window
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local GUI = ns.GUI
local C = GUI.Colors

-- Main frame reference
GUI.MainFrame = nil
GUI.currentPageIndex = 1

---------------------------------------------------------------------------
-- CREATE MAIN WINDOW
---------------------------------------------------------------------------
-- Forward Declarations
local CreateTopBar, CreateButtonBar, CreateSidebar, CreateContentArea, UpdateButtonSelection
local function CreateMainWindow()
    if GUI.MainFrame then return end

    local db = ns.GetDB()
    local frame = CreateFrame("Frame", "GravityUIFrame", UIParent, "BackdropTemplate")
    frame:SetSize(980, 680)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Glassmorphic Backdrop
    GUI:CreateBackdrop(frame, C.bgGlass)
    
    -- Draggable Script
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing()
    end)

    -- REFRESH COLORS METHOD (Recursive)
    function frame:RefreshColors()
        -- 1. Refresh global components
        if self.topBar and self.topBar.RefreshColors then self.topBar:RefreshColors() end
        
        -- 2. Refresh Sidebar Buttons
        if self.sidebarButtons then
            for _, btn in ipairs(self.sidebarButtons) do
                if btn.RefreshColors then btn:RefreshColors() end
            end
            -- Force update selection state to apply new colors
            UpdateButtonSelection() 
        end
        
        -- 3. Refresh Active Content
        local content = self.contentArea
        if content then
            local p = content:GetParent() -- ScrollFrame
            if p and p.GetScrollChild then
                local child = p:GetScrollChild()
                if child and child.RefreshColors then child:RefreshColors() end
                
                -- Traverse standard widgets in content
                local function Recurse(f)
                    if f.RefreshColors then f:RefreshColors() end
                    local function ProcessChildren(...)
                        for i = 1, select("#", ...) do
                            Recurse(select(i, ...))
                        end
                    end
                    ProcessChildren(f:GetChildren())
                end
                Recurse(child)
            end
        end
        
        -- 4. Refresh Resize Grip

    end
    
    -- ESC to close
    -- Using UISpecialFrames to allow closing with Escape without SetPropagateKeyboardInput taint
    tinsert(UISpecialFrames, "GravityUIFrame")
    
    GUI.MainFrame = frame
    
    -- Create components
    CreateTopBar(frame)
    CreateButtonBar(frame) -- Create ButtonBar first for anchoring
    CreateSidebar(frame)
    CreateContentArea(frame)
    
    -- Resize Grip

end

---------------------------------------------------------------------------
-- TOP BAR (Title, Logo, Close Button)
---------------------------------------------------------------------------
function CreateTopBar(parent)
    local topBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    topBar:SetHeight(60)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)
    
    -- Glass Header (Darker)
    topBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    topBar:SetBackdropColor(C.bgGlass[1], C.bgGlass[2], C.bgGlass[3], 0.5)
    
    -- Separator Line
    local separator = topBar:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(1)
    separator:SetPoint("BOTTOMLEFT", 0, 0)
    separator:SetPoint("BOTTOMRIGHT", 0, 0)
    separator:SetColorTexture(1, 1, 1, 0.1) -- Subtle divider

    
    -- Logo
    local logo = topBar:CreateTexture(nil, "OVERLAY")
    logo:SetSize(28, 28)
    logo:SetPoint("LEFT", 10, 0)
    logo:SetTexture(ns.ICON_PATH)
    
    -- Title
    local title = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    GUI:SetFont(title, 16, "OUTLINE", {0, 0.6, 1, 1})
    title:SetText("GravityUI")
    title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    
    -- Version
    local version = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(version, 11, "", C.textMuted)
    version:SetText("" .. ns.VERSION)
    version:SetPoint("LEFT", title, "RIGHT", 8, 0)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, topBar, "BackdropTemplate")
    closeBtn:SetSize(30, 30)
    closeBtn:SetPoint("RIGHT", -15, 0)
    
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    closeBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    closeBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(closeText, 14, "OUTLINE")
    closeText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    closeText:SetText("×")
    closeText:SetPoint("CENTER", 0, 1)
    
    closeBtn:SetScript("OnClick", function()
        parent:Hide()
    end)
    
    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        closeText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    
    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        closeText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    end)
    
    -- Search Bar
    local searchContainer = CreateFrame("Frame", nil, topBar, "BackdropTemplate")
    searchContainer:SetSize(220, 28)
    searchContainer:SetPoint("RIGHT", closeBtn, "LEFT", -15, 0)
    
    searchContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    searchContainer:SetBackdropColor(0.15, 0.15, 0.15, 1) -- Match close button
    searchContainer:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    
    local searchIcon = searchContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(searchIcon, 12, "", C.textMuted) -- Same color as placeholder, no outline
    searchIcon:SetText(">")
    searchIcon:SetPoint("LEFT", 10, 0)
    
    local searchBox = CreateFrame("EditBox", nil, searchContainer)
    searchBox:SetPoint("LEFT", searchIcon, "RIGHT", 5, 0)
    searchBox:SetPoint("RIGHT", -25, 0) -- Leave space for clear btn
    searchBox:SetHeight(20)
    searchBox:SetAutoFocus(false)
    GUI:SetFont(searchBox, 11, "", C.textBright)
    
    local searchPlaceholder = searchContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(searchPlaceholder, 11, "", C.textMuted)
    searchPlaceholder:SetText("Search settings...")
    searchPlaceholder:SetPoint("LEFT", searchBox, "LEFT", 0, 0)
    
    -- Clear button (X)
    local clearBtn = CreateFrame("Button", nil, searchContainer)
    clearBtn:SetSize(20, 20)
    clearBtn:SetPoint("RIGHT", -4, 0)
    clearBtn:Hide()
    
    local clearText = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(clearText, 12, "OUTLINE")
    clearText:SetText("×")
    clearText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
    clearText:SetPoint("CENTER")
    
    clearBtn:SetScript("OnEnter", function() clearText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
    clearBtn:SetScript("OnLeave", function() clearText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1) end)
    clearBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        GUI:UpdateSearchResults("")
    end)
    
    searchBox:SetScript("OnEditFocusGained", function() searchPlaceholder:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function(self) 
        if self:GetText() == "" then searchPlaceholder:Show() end
    end)
    
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text ~= "" then 
            clearBtn:Show()
            searchPlaceholder:Hide()
        else 
            clearBtn:Hide()
            if not self:HasFocus() then searchPlaceholder:Show() end
        end
        GUI:UpdateSearchResults(text)
    end)
    
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    
    topBar.searchBox = searchBox
    parent.topBar = topBar
end

---------------------------------------------------------------------------
-- SIDEBAR (Navigation Tabs)
---------------------------------------------------------------------------
CreateSidebar = function(parent)
    -- Change sidebar to a ScrollFrame container
    local sidebarContainer = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebarContainer:SetWidth(180)
    sidebarContainer:SetPoint("TOPLEFT", 0, -60)
    sidebarContainer:SetPoint("BOTTOMLEFT", 0, 50) -- Attach to bottom button bar
    
    sidebarContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    sidebarContainer:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.5)
    
    -- Create the actual scroll frame
    local scroll = CreateFrame("ScrollFrame", "GravityUISidebarScroll", sidebarContainer, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -16)
    scroll:SetPoint("BOTTOMRIGHT", 0, 16)
    
    -- Hide default scrollbar to keep it clean (or we can style it)
    if _G["GravityUISidebarScrollScrollBar"] then
        _G["GravityUISidebarScrollScrollBar"]:SetAlpha(0)
        -- We still want mousewheel to work, so we don't Hide() it entirely, just make it invisible
    end
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(180, 1) -- Height gets updated dynamically
    scroll:SetScrollChild(content)
    
    -- --- Scroll Indicators (Overlays) ---
    -- Top Indicator Bar
    local indicatorUpContainer = CreateFrame("Frame", nil, sidebarContainer)
    indicatorUpContainer:SetSize(180, 16)
    indicatorUpContainer:SetPoint("TOPLEFT", sidebarContainer, "TOPLEFT", 0, 0)
    local upBg = indicatorUpContainer:CreateTexture(nil, "BACKGROUND")
    upBg:SetAllPoints()
    upBg:SetColorTexture(0, 0, 0, 0.25) -- Dark very transparent
    
    local indicatorUp = indicatorUpContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(indicatorUp, 12, "")
    indicatorUp:SetPoint("CENTER", 0, 1)
    indicatorUp:SetText("▲")
    indicatorUp:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    indicatorUpContainer:SetAlpha(0)
    
    -- Bottom Indicator Bar
    local indicatorDownContainer = CreateFrame("Frame", nil, sidebarContainer)
    indicatorDownContainer:SetSize(180, 16)
    indicatorDownContainer:SetPoint("BOTTOMLEFT", sidebarContainer, "BOTTOMLEFT", 0, 0)
    local downBg = indicatorDownContainer:CreateTexture(nil, "BACKGROUND")
    downBg:SetAllPoints()
    downBg:SetColorTexture(0, 0, 0, 0.25) -- Dark very transparent
    
    local indicatorDown = indicatorDownContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(indicatorDown, 12, "")
    indicatorDown:SetPoint("CENTER", 0, -1)
    indicatorDown:SetText("▼")
    indicatorDown:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    indicatorDownContainer:SetAlpha(0)
    
    local function UpdateScrollIndicators()
        local current = scroll:GetVerticalScroll()
        local maxRange = scroll:GetVerticalScrollRange()
        
        -- Show UP arrow if we are scrolled down at all
        if current > 1 then
            indicatorUpContainer:SetAlpha(1)
        else
            indicatorUpContainer:SetAlpha(0)
        end
        
        -- Show DOWN arrow if we haven't reached the bottom
        if maxRange > 0 and current < (maxRange - 1) then
            indicatorDownContainer:SetAlpha(1)
        else
            indicatorDownContainer:SetAlpha(0)
        end
    end
    
    -- --- Custom Scrollbar ---
    local sb = CreateFrame("Frame", nil, sidebarContainer)
    sb:SetWidth(20) -- Wider hit box
    sb:SetPoint("TOPRIGHT", 0, -22)
    sb:SetPoint("BOTTOMRIGHT", 0, 22)
    
    local thumb = CreateFrame("Button", nil, sb, "BackdropTemplate")
    thumb:SetWidth(7) -- 1px smaller
    thumb:SetPoint("RIGHT", 0, 0) -- Align thumb to the right of the hit box
    thumb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    thumb:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.4) -- More transparent blue
    -- Removed dot texture to make it a clean blue bar
    
    local function UpdateThumb()
        local maxRange = scroll:GetVerticalScrollRange()
        if maxRange <= 0 then
            thumb:Hide()
            return
        end
        thumb:Show()
        
        local thumbHeight = 20
        thumb:SetHeight(thumbHeight)
        
        local current = scroll:GetVerticalScroll()
        local ratio = current / maxRange
        local trackHeight = sb:GetHeight() - thumbHeight
        thumb:SetPoint("TOPRIGHT", 0, -(ratio * trackHeight))
    end
    
    thumb:RegisterForDrag("LeftButton")
    thumb:SetScript("OnDragStart", function(self)
        self.isDragging = true
        local _, y = GetCursorPosition()
        self.lastY = y / self:GetEffectiveScale()
    end)
    thumb:SetScript("OnDragStop", function(self)
        self.isDragging = false
    end)
    
    -- Show scrollbar only when mouse is over sidebar OR scrollbar itself
    sidebarContainer:SetScript("OnUpdate", function(self)
        if self:IsMouseOver() or sb:IsMouseOver() or thumb.isDragging then
            sb:SetAlpha(1)
        else
            sb:SetAlpha(0)
        end
        
        if thumb.isDragging then
            local _, y = GetCursorPosition()
            y = y / thumb:GetEffectiveScale()
            local diff = thumb.lastY - y
            if diff ~= 0 then
                local maxRange = scroll:GetVerticalScrollRange()
                local trackHeight = sb:GetHeight() - thumb:GetHeight()
                if trackHeight > 0 then
                    local scrollDiff = (diff / trackHeight) * maxRange
                    scroll:SetVerticalScroll(math.max(0, math.min(maxRange, scroll:GetVerticalScroll() + scrollDiff)))
                end
                thumb.lastY = y
            end
        end
    end)

    scroll:HookScript("OnVerticalScroll", function()
        UpdateScrollIndicators()
        UpdateThumb()
    end)
    
    scroll:HookScript("OnScrollRangeChanged", function()
        UpdateScrollIndicators()
        UpdateThumb()
    end)
    
    parent.sidebarContainer = sidebarContainer
    parent.sidebar = content -- Buttons attach here
    parent.sidebarButtons = {}
end

---------------------------------------------------------------------------
-- CONTENT AREA
---------------------------------------------------------------------------
CreateContentArea = function(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", 180, -60)
    content:SetPoint("BOTTOMRIGHT", 0, 50) -- Attach to bottom button bar
    
    parent.contentArea = content
end

---------------------------------------------------------------------------
-- BUTTON BAR (Cooldown Settings, Edit Mode)
---------------------------------------------------------------------------
CreateButtonBar = function(parent)
    local buttonBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    buttonBar:SetHeight(50)
    buttonBar:SetPoint("BOTTOMLEFT", 0, 0)
    buttonBar:SetPoint("BOTTOMRIGHT", 0, 0)
    
    buttonBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    buttonBar:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.8)
    
    -- Installers Button
    local instBtn = GUI:CreateButton(buttonBar, "Installer", 130, 32, function()
        -- Find profiles page index
        local idx
        for i, id in ipairs(GUI.pageOrder) do 
            if id == "profiles" then idx = i; break end 
        end
        if idx then
            -- We assume "Installers" is the 4th item in profiles subtabs now
            GUI:ShowPage(idx, 4) 
        end
    end)
    instBtn:SetPoint("LEFT", 15, 0)
    instBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    instBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list
    instBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    
    -- Cooldown Settings Button
    local cdmBtn = GUI:CreateButton(buttonBar, "CDM Settings", 130, 32, function()
        if CooldownViewerSettings then
            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
        else
            print("|cFF30D1FFGravityUI:|r Cooldown Settings not available.")
        end
    end)
    cdmBtn:SetPoint("LEFT", instBtn, "RIGHT", 8, 0)
    
    -- Helper to open addon config
    local function OpenAddonConfig(name, slashCmds)
        if not C_AddOns.IsAddOnLoaded(name) then return false end
        
        -- Helper to execute a slash command if key exists
        local function TryRun(key)
            if SlashCmdList[key] then
                SlashCmdList[key]("")
                return true
            end
            return false
        end

        local cmds = type(slashCmds) == "table" and slashCmds or {slashCmds}
        
        -- 1. Try direct keys (UPPERCASE, TitleCase, lowercase)
        for _, cmd in ipairs(cmds) do
            if TryRun(cmd) then return true end
            if TryRun(cmd:upper()) then return true end
            if TryRun(cmd:lower()) then return true end
        end

        -- 2. Brute force scan for the command string
        -- e.g. look for SLASH_XYZ1 = "/bigwigs" -> run SlashCmdList["XYZ"]
        for k, v in pairs(_G) do
            if type(k) == "string" and k:match("^SLASH_") and type(v) == "string" then
                for _, targetCmd in ipairs(cmds) do
                     -- targetCmd might be "bw" or "bigwigs"
                     -- v might be "/bw" or "/bigwigs"
                     if v:lower() == "/" .. targetCmd:lower() then
                         -- Extract key: SLASH_KEY1 -> KEY
                         local key = k:match("^SLASH_(.+)%d+$")
                         if key and TryRun(key) then 
                             return true 
                         end
                     end
                end
            end
        end

        -- 3. Generic AceConfig fallback
        local LibStub = _G.LibStub
        if LibStub then
            local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
            if AceConfigDialog and AceConfigDialog.Open then
                 if AceConfigDialog:Open(name) then return true end
            end
        end

        print("|cFF30D1FFGravityUI:|r Loaded " .. name .. " but could not open config automatically.")
        return true
    end

    -- Boss Mods Button (BigWigs / DBM)
    -- Boss Mods Button (BigWigs / DBM)
    local bossBtn = GUI:CreateButton(buttonBar, "Boss Mods", 90, 32, function()
        local opened = false

        -- BigWigs (Try Slash Commands)
        if not opened and OpenAddonConfig("BigWigs", {"BIGWIGS", "BW"}) then opened = true end
        
        -- BigWigs (Try Option Frame directly if slash failed, sometimes its lod)
        if not opened and C_AddOns.IsAddOnLoaded("BigWigs") then
             -- Try generic AceConfig load
             local LibStub = _G.LibStub
             if LibStub then
                 local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
                 if AceConfigDialog and AceConfigDialog.Open then
                      if AceConfigDialog:Open("BigWigs") then opened = true end
                 end
             end
             -- Try LoadOnDemand options if needed
             if not opened and not C_AddOns.IsAddOnLoaded("BigWigs_Options") then
                 C_AddOns.LoadAddOn("BigWigs_Options")
                 if LibStub("AceConfigDialog-3.0"):Open("BigWigs") then opened = true end
             end
         end

        -- DBM (Deadly Boss Mods)
        if not opened and OpenAddonConfig("DBM-Core", {"DBM", "DEADLYBOSSMODS"}) then opened = true end

        if not opened then
             print("|cFF30D1FFGravityUI:|r No supported Boss Mod addon loaded (BigWigs, DBM).")
        end
    end)
    bossBtn:SetPoint("LEFT", cdmBtn, "RIGHT", 8, 0)
    -- Matching User Image styling
    bossBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    bossBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list
    bossBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end

    -- Nameplates Button
    local npBtn = GUI:CreateButton(buttonBar, "Nameplates", 90, 32, function()
        local opened = false
        
        -- Plater
        if not opened and OpenAddonConfig("Plater", "PLATER") then opened = true end
        
        -- Platynator
        if not opened and OpenAddonConfig("Platynator", "PLATYNATOR") then opened = true end
         
        if not opened then
             print("|cFF30D1FFGravityUI:|r No supported Nameplates addon loaded (Plater, Platynator).")
        end
    end)
    npBtn:SetPoint("LEFT", bossBtn, "RIGHT", 8, 0)
    -- Matching User Image styling
    npBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    npBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list
    npBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    
    -- CDM Button (Better Cooldown Manager, Centered Cooldown Manager, Arc UI)
    local cdmAddonBtn = GUI:CreateButton(buttonBar, "CDM", 50, 32, function()
        local opened = false
        
        -- Ayije CDM
        if not opened and OpenAddonConfig("Ayije_CDM", "ACDM") then opened = true end
        
        -- Better Cooldown Manager (BCDM)
        if not opened and OpenAddonConfig("BetterCooldownManager", "BCDM") then opened = true end
        
        -- Centered Cooldown Manager
        if not opened and OpenAddonConfig("CenteredCooldownManager", "CCM") then opened = true end
        
        -- Arc UI
        if not opened and OpenAddonConfig("ArcUI", "ARCUI") then opened = true end
         
        if not opened then
             print("|cFF30D1FFGravityUI:|r No supported CDM addon loaded (Ayije, BCDM, CCM, ArcUI).")
        end
    end)
    cdmAddonBtn:SetPoint("LEFT", npBtn, "RIGHT", 8, 0)
    -- Matching User Image styling
    cdmAddonBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    cdmAddonBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list (Standard Button)
    cdmAddonBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    
    -- Unitframes Button
    local ufBtn = GUI:CreateButton(buttonBar, "Unitframes", 90, 32, function()
        local opened = false
        
        -- Unhalted UnitFrames
        if not opened and OpenAddonConfig("UnhaltedUnitFrames", "UUF") then opened = true end
        
        -- MidnightSimpleUnitframes
        if not opened and OpenAddonConfig("MidnightSimpleUnitframes", "MSUF") then opened = true end
         
        if not opened then
             print("|cFF30D1FFGravityUI:|r No supported Unitframes addon loaded (Unhalted, Midnight).")
        end
    end)
    ufBtn:SetPoint("LEFT", cdmAddonBtn, "RIGHT", 8, 0)
    -- Matching User Image: Standardize to Theme Blue
    ufBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5) -- Semi-transparent Theme Blue
    ufBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) -- Theme Blue
    
    -- Add to refresh list
    ufBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
 
    -- Party / Raid Button
    local prBtn = GUI:CreateButton(buttonBar, "Party / Raid", 90, 32, function()
        local opened = false
        
        -- DandersFrames
        if not opened and OpenAddonConfig("DandersFrames", "DANDERSFRAMES") then opened = true end
        
        -- Grid2
        if not opened and OpenAddonConfig("Grid2", "GRID2") then opened = true end
        
        -- Cell
        if not opened and OpenAddonConfig("Cell", "CELL") then opened = true end
 
        if not opened then
            print("|cFF30D1FFGravityUI:|r No supported Party/Raid addon loaded (DandersFrames, Grid2, Cell).")
        end
    end)
    prBtn:SetPoint("LEFT", ufBtn, "RIGHT", 8, 0)
    -- Matching User Image: Standardize to Theme Blue
    prBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    prBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
     
    -- Add to refresh list
    prBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
     
    -- Discord Link & Manual UI Scale Input (Bottom Right)
    local db = ns.GetDB()
    if db then
        -- Discord Button
        local discordBtn = CreateFrame("Button", nil, buttonBar)
        discordBtn:SetSize(32, 32)
        discordBtn:SetPoint("BOTTOMRIGHT", -113, 9)
        
        local discordIcon = discordBtn:CreateTexture(nil, "ARTWORK")
        discordIcon:SetAllPoints()
        discordIcon:SetTexture(ns.DISCORD_ICON)
        discordIcon:SetVertexColor(1, 1, 1, 1)

        discordBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Join our Discord", 0, 0.75, 1)
            GameTooltip:AddLine("Click to copy link: |cff00ffffhttps://discord.gg/nBwzzHc|r", 1, 1, 1)
            GameTooltip:Show()
            discordIcon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)

        discordBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            discordIcon:SetVertexColor(1, 1, 1, 1)
        end)

        discordBtn:SetScript("OnClick", function()
            local edit_box = ChatEdit_ChooseBoxForSend()
            ChatEdit_ActivateChat(edit_box)
            edit_box:SetText("https://discord.gg/nBwzzHc")
            edit_box:HighlightText()
            ns.Print("Discord link pasted to chat! Press Enter to send or Ctrl+C to copy.")
        end)

        -- Scale Container
        local scaleContainer = CreateFrame("Frame", nil, buttonBar)
        scaleContainer:SetSize(45, 24)
        scaleContainer:SetPoint("BOTTOMRIGHT", -10, 13)

        local scaleLabel = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        GUI:SetFont(scaleLabel, 10, "", C.textMuted)
        scaleLabel:SetText("Scale:")
        scaleLabel:SetPoint("RIGHT", scaleContainer, "LEFT", -4, 0)

        local scaleInput = CreateFrame("EditBox", nil, scaleContainer, "BackdropTemplate")
        scaleInput:SetSize(45, 22)
        scaleInput:SetPoint("CENTER")
        scaleInput:SetAutoFocus(false)
        GUI:SetFont(scaleInput, 11, "", C.textBright)
        scaleInput:SetTextInsets(5, 5, 0, 0)
        scaleInput:SetJustifyH("CENTER")

        scaleInput:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        scaleInput:SetBackdropColor(0.15, 0.15, 0.15, 1)
        scaleInput:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local function UpdateScaleValue()
            local current = db.general.configPanelScale or 1
            scaleInput:SetText(string.format("%.2f", current))
        end

        scaleInput:SetScript("OnEnterPressed", function(self)
            local val = tonumber(self:GetText())
            if val and val >= 0.3 and val <= 2.5 then
                db.general.configPanelScale = val
                if GUI.MainFrame then
                    GUI.MainFrame:SetScale(val)
                end
            end
            self:ClearFocus()
            UpdateScaleValue()
        end)

        scaleInput:SetScript("OnEscapePressed", function(self)
            UpdateScaleValue()
            self:ClearFocus()
        end)

        scaleInput:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
        scaleInput:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1) end)

        UpdateScaleValue()
    end
    
    parent.buttonBar = buttonBar
end

---------------------------------------------------------------------------
-- CREATE SIDEBAR BUTTONS
---------------------------------------------------------------------------
GUI.expandedCategories = GUI.expandedCategories or {}

function GUI:UpdateSidebarLayout()
    local frame = self.MainFrame
    if not frame then return end
    
    local yOffset = 10
    
    for _, item in ipairs(frame.sidebarItems) do
        if item.type == "header" then
            item:SetPoint("TOPLEFT", 15, -yOffset)
            local isExpanded = GUI.expandedCategories[item.pageId] ~= false
            item.icon:SetText(isExpanded and "-" or "+")
            yOffset = yOffset + 26
        elseif item.type == "subtab" then
            local isExpanded = GUI.expandedCategories[item.pageId] ~= false
            if isExpanded then
                item:Show()
                item:SetPoint("TOPLEFT", 10, -yOffset)
                yOffset = yOffset + 30
            else
                item:Hide()
            end
        elseif item.type == "spacer" then
            local isExpanded = GUI.expandedCategories[item.pageId] ~= false
            if isExpanded then
                yOffset = yOffset + 10
            end
        elseif item.type == "single" then
            item:SetPoint("TOPLEFT", 10, -yOffset)
            yOffset = yOffset + 42
        end
    end
    
    frame.sidebar:SetHeight(math.max(yOffset + 10, 1))
end

CreateSidebarButtons = function()
    local frame = GUI.MainFrame
    if not frame then return end
    
    GUI.expandedCategories = GUI.expandedCategories or {}
    frame.sidebarItems = {}
    frame.sidebarButtons = {}
    
    local buttonIndex = 0
    
    for i, pageId in ipairs(GUI.pageOrder) do
        local opts = GUI.pages[pageId]
        if not opts.hideFromSidebar and (not opts.showIf or opts.showIf()) then
            
            if opts.subTabs and #opts.subTabs > 0 then
                local db = ns.GetDB()
                local isSideTop = db and db.general.menuStyle == "SIDE_TOP"
                
                local headerBtn = CreateFrame("Button", nil, frame.sidebar, "BackdropTemplate")
                headerBtn:SetSize(160, isSideTop and 36 or 20)
                
                local headerIcon = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                GUI:SetFont(headerIcon, 12, "", C.sectionHeader)
                headerIcon:SetPoint("RIGHT", -5, 0)
                headerIcon:SetText("-")
                headerBtn.icon = headerIcon
                
                local headerText = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                GUI:SetFont(headerText, 13, "", C.sectionHeader)
                headerText:SetPoint("LEFT", isSideTop and 15 or 0, 0)
                headerText:SetText(opts.title or pageId)
                headerBtn.text = headerText
                
                if isSideTop then
                    headerBtn:SetSize(175, 36)
                    
                    local indicator = headerBtn:CreateTexture(nil, "OVERLAY")
                    indicator:SetWidth(3)
                    indicator:SetPoint("TOPLEFT", 0, 0)
                    indicator:SetPoint("BOTTOMLEFT", 0, 0)
                    indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                    indicator:Hide()
                    headerBtn.indicator = indicator
                    
                    headerBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
                    headerBtn:SetBackdropColor(0, 0, 0, 0)
                    
                    headerBtn:SetScript("OnEnter", function(self)
                        if GUI.currentPageIndex ~= self.pageIndex then
                            self:SetBackdropColor(C.tabHover[1], C.tabHover[2], C.tabHover[3], C.tabHover[4])
                            self.text:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3], 1)
                        end
                    end)
                    
                    headerBtn:SetScript("OnLeave", function(self)
                        if GUI.currentPageIndex ~= self.pageIndex then
                            self:SetBackdropColor(0, 0, 0, 0)
                            self.text:SetTextColor(1, 1, 1, 1)
                        end
                    end)
                end
                
                headerBtn:SetScript("OnClick", function()
                    local db = ns.GetDB()
                    if db.general.menuStyle == "SIDE_TOP" then
                        GUI:ShowPage(pageId, 1)
                    else
                        if GUI.expandedCategories[pageId] == false then
                            GUI.expandedCategories[pageId] = true
                        else
                            GUI.expandedCategories[pageId] = false
                        end
                        GUI:UpdateSidebarLayout()
                    end
                end)
                
                headerBtn.type = "header"
                headerBtn.pageId = pageId
                headerBtn.pageIndex = i
                headerBtn.subTabIndex = 1 -- Headers in SIDE_TOP act as first subtab
                table.insert(frame.sidebarItems, headerBtn)
                
                -- Add to buttons list for selection highlighting ONLY in SIDE_TOP
                if isSideTop then
                    buttonIndex = buttonIndex + 1
                    frame.sidebarButtons[buttonIndex] = headerBtn
                    headerIcon:Hide()
                end
                
                -- 2. Create nested subtab buttons (ONLY in SIDE mode)
                local db = ns.GetDB()
                if db.general.menuStyle ~= "SIDE_TOP" then
                    for subIdx, tabInfo in ipairs(opts.subTabs) do
                    buttonIndex = buttonIndex + 1
                    
                    local btn = CreateFrame("Button", nil, frame.sidebar, "BackdropTemplate")
                    btn:SetSize(160, 28)
                    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
                    btn:SetBackdropColor(0, 0, 0, 0)
                    
                    local indicator = btn:CreateTexture(nil, "OVERLAY")
                    indicator:SetWidth(2)
                    indicator:SetPoint("TOPLEFT", 0, 0)
                    indicator:SetPoint("BOTTOMLEFT", 0, 0)
                    indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                    indicator:Hide()
                    btn.indicator = indicator
                    
                    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    GUI:SetFont(btnText, 13, "")
                    btnText:SetTextColor(1, 1, 1, 1)
                    btnText:SetText(tabInfo.name)
                    btnText:SetPoint("LEFT", 15, 0)
                    
                    btn.text = btnText
                    btn.pageIndex = i
                    btn.subTabIndex = subIdx
                    
                    btn.RefreshColors = function(self)
                        local isSelected = (GUI.currentPageIndex == self.pageIndex and GUI.currentSubTabIndex == self.subTabIndex)
                        if isSelected then
                            self.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                        end
                    end
                    
                    btn:SetScript("OnClick", function()
                        GUI:ShowPage(i, subIdx)
                        if tabInfo.fn then
                            tabInfo.fn()
                        end
                    end)
                    
                    btn:SetScript("OnEnter", function(self)
                        if GUI.currentPageIndex ~= self.pageIndex or GUI.currentSubTabIndex ~= self.subTabIndex then
                            self:SetBackdropColor(C.tabHover[1], C.tabHover[2], C.tabHover[3], C.tabHover[4])
                            self.text:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3], 1)
                        end
                    end)
                    
                    btn:SetScript("OnLeave", function(self)
                        if GUI.currentPageIndex ~= self.pageIndex or GUI.currentSubTabIndex ~= self.subTabIndex then
                            self:SetBackdropColor(0, 0, 0, 0)
                            self.text:SetTextColor(1, 1, 1, 1)
                        end
                    end)
                    
                    btn.type = "subtab"
                    btn.pageId = pageId
                    frame.sidebarButtons[buttonIndex] = btn
                    table.insert(frame.sidebarItems, btn)
                end
            end
                
                table.insert(frame.sidebarItems, { type = "spacer", pageId = pageId })
            else
                -- Traditional Single Page Button
                buttonIndex = buttonIndex + 1
                
                local db = ns.GetDB()
                local isSideTop = db and db.general.menuStyle == "SIDE_TOP"
                
                local btn = CreateFrame("Button", nil, frame.sidebar, "BackdropTemplate")
                btn:SetSize(isSideTop and 175 or 160, 36)
                btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
                btn:SetBackdropColor(0, 0, 0, 0)
                
                local indicator = btn:CreateTexture(nil, "OVERLAY")
                indicator:SetWidth(3)
                indicator:SetPoint("TOPLEFT", 0, 0)
                indicator:SetPoint("BOTTOMLEFT", 0, 0)
                indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                indicator:Hide()
                btn.indicator = indicator
                
                local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                GUI:SetFont(btnText, 13, "") 
                btnText:SetTextColor(1, 1, 1, 1)
                btnText:SetText(opts.title or pageId)
                btnText:SetPoint("LEFT", 15, 0)
                
                btn.text = btnText
                btn.pageIndex = i
                btn.subTabIndex = 1
                
                btn.RefreshColors = function(self)
                    local isSelected = (GUI.currentPageIndex == self.pageIndex)
                    if isSelected then
                        self.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                    end
                end
                
                btn:SetScript("OnClick", function()
                    GUI:ShowPage(i, 1)
                end)
                
                btn:SetScript("OnEnter", function(self)
                    if GUI.currentPageIndex ~= self.pageIndex then
                        self:SetBackdropColor(C.tabHover[1], C.tabHover[2], C.tabHover[3], C.tabHover[4])
                        self.text:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3], 1)
                    end
                end)
                
                btn:SetScript("OnLeave", function(self)
                    if GUI.currentPageIndex ~= self.pageIndex then
                        self:SetBackdropColor(0, 0, 0, 0)
                        self.text:SetTextColor(1, 1, 1, 1)
                    end
                end)
                
                btn.type = "single"
                btn.pageId = pageId
                frame.sidebarButtons[buttonIndex] = btn
                table.insert(frame.sidebarItems, btn)
            end
        end
    end
    
    GUI:UpdateSidebarLayout()
end


---------------------------------------------------------------------------
-- UPDATE BUTTON SELECTION
---------------------------------------------------------------------------
UpdateButtonSelection = function()
    local frame = GUI.MainFrame
    if not frame then return end
    
    local db = ns.GetDB()
    local isSideTop = db and db.general.menuStyle == "SIDE_TOP"
    
    for _, btn in ipairs(frame.sidebarButtons) do
        local isSelected
        if isSideTop then
            -- In SIDE_TOP, we only care about the main page index in the sidebar
            isSelected = (btn.pageIndex == GUI.currentPageIndex)
        else
            -- Standard mode: Headers are not in this list, but if they were, they shouldn't match
            if btn.type == "header" then
                isSelected = false
            else
                isSelected = (btn.pageIndex == GUI.currentPageIndex and btn.subTabIndex == GUI.currentSubTabIndex)
            end
        end
        
        if isSelected then
            -- Selected state: Tech Nav
            -- 1. Show Indicator
            btn.indicator:Show()
            btn.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
            
            -- 2. Gradient Background (Simulated with Alpha)
            btn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.1)
            
            -- 3. Text Bright
            btn.text:SetTextColor(1, 1, 1, 1)
        else
            -- Normal state
            btn.indicator:Hide()
            btn:SetBackdropColor(0, 0, 0, 0)
            btn.text:SetTextColor(1, 1, 1, 1) -- White text
        end
    end
end

---------------------------------------------------------------------------
-- BUILD PAGE FRAME
---------------------------------------------------------------------------
local function BuildPageFrame(opts)
    local frame = CreateFrame("ScrollFrame", nil, GUI.MainFrame.contentArea, "UIPanelScrollFrameTemplate")
    frame:SetPoint("TOPLEFT", 10, -10)
    frame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local content = CreateFrame("Frame", nil, frame)
    content:SetSize(frame:GetWidth(), 1) -- Set initial width
    frame:SetScrollChild(content)
    
    -- Auto-resize content width when scrollframe resizes
    frame:SetScript("OnSizeChanged", function(self, width)
        content:SetWidth(width)
    end)
    
    content._hasContent = false
    
    frame:Hide()
    
    if opts.OnBuild then
        -- Set search context if we are building for indexing
        if GUI.currentSearchContext then
            GUI:SetSearchContext(GUI.currentSearchContext.pageId, 0)
        end
        
        opts.OnBuild(content)
        
        if GUI.currentSearchContext then
            GUI:ClearSearchContext()
        end
    end
    
    return frame
end

---------------------------------------------------------------------------
-- SHOW PAGE
---------------------------------------------------------------------------
local function HideAllPages()
    for _, opts in pairs(GUI.pages) do
        if opts.frame then
            opts.frame:Hide()
        end
    end
end

function GUI:ShowPage(index, subIndex)
    if not self.MainFrame then return end
    
    -- Default to subIndex 1 if not provided (for backwards compatibility or simple pages)
    subIndex = subIndex or 1
    
    -- Handle string ID or Index
    local pageId = type(index) == "string" and index or self.pageOrder[index]
    if not pageId then return end
    
    -- Correct numeric index if string ID was used
    if type(index) == "string" then
        for i, id in ipairs(self.pageOrder) do
            if id == index then index = i; break end
        end
    end
    
    -- Don't switch if already on it AND on the same subtab
    if self.currentPageId == pageId and self.currentSubTabIndex == subIndex then return end
    
    -- Handle Search state return
    if pageId == "search" then
        if self.currentPageId ~= "search" then
            self.preSearchPageId = self.currentPageId
            self.preSearchPageIndex = self.currentPageIndex
            self.preSearchSubTabIndex = self.currentSubTabIndex
        end
    end
    
    -- Hide ALL pages to prevent overlap
    HideAllPages()
    
    -- Show new page
    local opts = self.pages[pageId]
    if not opts then return end
    
    if not opts.frame then
        self.buildingPageId = pageId
        -- We pass the subIndex initially in case it needs it for first build
        opts.frame = BuildPageFrame(opts)
        self.buildingPageId = nil
    end
    
    opts.frame:Show()
    self.currentPageIndex = index
    self.currentPageId = pageId
    self.currentSubTabIndex = subIndex
    
    if opts.OnShow then
        -- Pass subIndex so the page knows which internal section to render
        opts.OnShow(opts.frame:GetScrollChild(), subIndex)
        
        -- Update top tabs if they exist
        if opts.subTabsContainer and opts.subTabsContainer.UpdateButtons then
            opts.subTabsContainer:UpdateButtons(subIndex)
        end
    end

    -- Ensure the category is expanded in the sidebar if it was collapsed (ONLY in SIDE mode)
    local db = ns.GetDB()
    if db.general.menuStyle ~= "SIDE_TOP" and self.expandedCategories[pageId] == false then
        self.expandedCategories[pageId] = true
        self:UpdateSidebarLayout()
    end
    
    UpdateButtonSelection()
end

---------------------------------------------------------------------------
-- TOGGLE WINDOW
---------------------------------------------------------------------------
function GUI:Toggle()
    if not self.MainFrame then
        CreateMainWindow()
        CreateSidebarButtons()
        self:BuildSearchIndex()
        self:ShowPage(1)
    end
    
    if self.MainFrame:IsShown() then
        self.MainFrame:Hide()
    else
        self.MainFrame:Show()
    end
end

---------------------------------------------------------------------------
-- SHOW WINDOW
---------------------------------------------------------------------------
function GUI:Show()
    if not self.MainFrame then
        -- Sync Colors BEFORE creating window
        self:UpdateThemeColors()
        
        CreateMainWindow()
        CreateSidebarButtons()
        self:BuildSearchIndex()
        self:ShowPage(1)
    end
    
    -- Sync Colors ON SHOW to ensure freshness
    self:UpdateThemeColors()
    
    local db = ns.GetDB()
    if db and db.general and db.general.configPanelScale then
        self.MainFrame:SetScale(db.general.configPanelScale)
    end
    
    self.MainFrame:Show()
end

---------------------------------------------------------------------------
-- HIDE WINDOW
---------------------------------------------------------------------------
function GUI:Hide()
    if self.MainFrame then
        self.MainFrame:Hide()
        self:CloseSearchResults()
    end
end

---------------------------------------------------------------------------
-- SEARCH FUNCTIONALITY
---------------------------------------------------------------------------
local searchResultsFrame = nil

function GUI:UpdateSearchResults(query)
    query = query:lower():trim()
    
    if query == "" then
        -- Return to previous page if we were on search page
        if self.currentPageId == "search" and self.preSearchPageId then
            self:ShowPage(self.preSearchPageId)
        end
        return
    end
    
    if #query < 2 then return end
    
    if self.UpdateSearchResultsPage then
        self:UpdateSearchResultsPage(query)
    end
end

local function FlashWidget(widget)
    if not widget then return end
    
    if not widget.flashFrame then
        widget.flashFrame = CreateFrame("Frame", nil, widget, "BackdropTemplate")
        widget.flashFrame:SetAllPoints(widget)
        widget.flashFrame:SetFrameLevel(widget:GetFrameLevel() + 10)
        GUI:CreateBackdrop(widget.flashFrame, {1, 1, 1, 0.4}, C.accent)
    end
    
    local flash = widget.flashFrame
    flash:Show()
    flash:SetAlpha(1)
    
    local elapsed = 0
    flash:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        if elapsed > 1 then
            self:Hide()
            self:SetScript("OnUpdate", nil)
        else
            self:SetAlpha(1 - elapsed)
        end
    end)
end

function GUI:NavigateToItem(item)
    if not item then return end
    
    -- 1. Switch Page and Tab
    self:ShowPage(item.pageId, item.tabIndex)
    
    local page = self.pages[item.pageId]
    
    -- 3. Scroll to widget (delayed to allow build/layout)
    C_Timer.After(0.1, function()
        if item.widget and item.widget:IsVisible() then
            local scrollFrame = page.frame
            local parent = item.widget:GetParent()
            while parent do
                if parent.GetVerticalScrollRange and parent.GetScrollChild then
                    scrollFrame = parent
                    break
                end
                parent = parent:GetParent()
            end
            
            if scrollFrame and scrollFrame.GetVerticalScrollRange then
                local content = scrollFrame:GetScrollChild()
                local widgetY = item.widget:GetTop()
                local contentY = content:GetTop()
                
                if widgetY and contentY then
                    local scrollPos = contentY - widgetY - 20
                    scrollFrame:SetVerticalScroll(math.max(0, scrollPos))
                end
            end
            
            FlashWidget(item.widget)
        end
    end)
end

function GUI:SelectFirstSearchResult()
    -- Page-based search handles selection via button clicks
end

function GUI:BuildSearchIndex()
    if #self.searchIndex > 0 then return end
    
    -- Force build all pages to trigger widget registration
    for i, pageId in ipairs(self.pageOrder) do
        local opts = self.pages[pageId]
        if not opts.frame and not opts.hideFromSearch then
            self:SetSearchContext(pageId, 0)
            opts.frame = BuildPageFrame(opts)
            self:ClearSearchContext()
        end
    end
end

