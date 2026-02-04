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
    
    local frame = CreateFrame("Frame", "GravityUIFrame", UIParent, "BackdropTemplate")
    frame:SetSize(900, 650)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH") -- Changed from DIALOG to HIGH to play nicer with other windows
    frame:SetFrameLevel(100)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Glassmorphic Backdrop
    GUI:CreateBackdrop(frame, C.bgGlass)
    
    -- Make draggable
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
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
                    local children = {f:GetChildren()}
                    for _, child in ipairs(children) do
                        Recurse(child)
                    end
                end
                Recurse(child)
            end
        end
        
        -- 4. Refresh Resize Grip

    end
    
    -- ESC to close
    -- Removed from UISpecialFrames to prevent conflicts with other addons triggering global close events
    -- table.insert(UISpecialFrames, "GravityUIFrame")
    
    frame:SetPropagateKeyboardInput(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    
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
    logo:SetSize(22, 22)
    logo:SetPoint("LEFT", 15, 0)
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
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetWidth(180)
    sidebar:SetPoint("TOPLEFT", 0, -60)
    sidebar:SetPoint("BOTTOMLEFT", 0, 50) -- Attach to bottom button bar
    
    sidebar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    sidebar:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.5)
    
    parent.sidebar = sidebar
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
    local instBtn = GUI:CreateButton(buttonBar, "GravityUI Installer", 155, 32, function()
        -- Find profiles page index
        local idx
        for i, id in ipairs(GUI.pageOrder) do 
            if id == "profiles" then idx = i; break end 
        end
        if idx then
            GUI:ShowPage(idx)
            -- Click the 4th tab (Installers)
            local p = GUI.pages["profiles"]
            if p and p.subTabs and p.subTabs.tabButtons and p.subTabs.tabButtons[4] then
                p.subTabs.tabButtons[4]:Click()
            end
        end
    end)
    instBtn:SetPoint("LEFT", 20, 0)
    instBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    instBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list
    instBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    
    -- Cooldown Settings Button
    local cdmBtn = GUI:CreateButton(buttonBar, "Cooldown Settings", 155, 32, function()
        if CooldownViewerSettings then
            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
        else
            print("|cFF30D1FFGravityUI:|r Cooldown Settings not available.")
        end
    end)
    cdmBtn:SetPoint("LEFT", instBtn, "RIGHT", 10, 0)
    
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
    local bossBtn = GUI:CreateButton(buttonBar, "Boss Mods", 95, 32, function()
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
    bossBtn:SetPoint("LEFT", cdmBtn, "RIGHT", 10, 0)
    -- Matching User Image styling
    bossBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    bossBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list
    bossBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end

    -- Nameplates Button
    local npBtn = GUI:CreateButton(buttonBar, "Nameplates", 95, 32, function()
        local opened = false
        
        -- Plater
        if not opened and OpenAddonConfig("Plater", "PLATER") then opened = true end
        
        -- Platynator
        if not opened and OpenAddonConfig("Platynator", "PLATYNATOR") then opened = true end
         
        if not opened then
             print("|cFF30D1FFGravityUI:|r No supported Nameplates addon loaded (Plater, Platynator).")
        end
    end)
    npBtn:SetPoint("LEFT", bossBtn, "RIGHT", 10, 0)
    -- Matching User Image styling
    npBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    npBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list
    npBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    
    -- CDM Button (Better Cooldown Manager, Centered Cooldown Manager, Arc UI)
    local cdmAddonBtn = GUI:CreateButton(buttonBar, "CDM", 70, 32, function()
        local opened = false
        
        -- Better Cooldown Manager (BCDM)
        if not opened and OpenAddonConfig("BetterCooldownManager", "BCDM") then opened = true end
        
        -- Centered Cooldown Manager
        if not opened and OpenAddonConfig("CenteredCooldownManager", "CCM") then opened = true end
        
        -- Arc UI
        if not opened and OpenAddonConfig("ArcUI", "ARCUI") then opened = true end
         
        if not opened then
             print("|cFF30D1FFGravityUI:|r No supported CDM addon loaded (BetterCooldownManager, CenteredCooldownManager, ArcUI).")
        end
    end)
    cdmAddonBtn:SetPoint("LEFT", npBtn, "RIGHT", 10, 0)
    -- Matching User Image styling
    cdmAddonBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    cdmAddonBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list (Standard Button)
    cdmAddonBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    
    -- Unitframes Button
    local ufBtn = GUI:CreateButton(buttonBar, "Unitframes", 95, 32, function()
        local opened = false
        
        -- Unhalted UnitFrames
        if not opened and OpenAddonConfig("UnhaltedUnitFrames", "UUF") then opened = true end
        
        -- MidnightSimpleUnitframes
        if not opened and OpenAddonConfig("MidnightSimpleUnitframes", "MSUF") then opened = true end
         
        if not opened then
             print("|cFF30D1FFGravityUI:|r No supported Unitframes addon loaded (Unhalted, Midnight).")
        end
    end)
    ufBtn:SetPoint("LEFT", cdmAddonBtn, "RIGHT", 10, 0)
    -- Matching User Image: Standardize to Theme Blue
    ufBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5) -- Semi-transparent Theme Blue
    ufBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) -- Theme Blue
    
    -- Add to refresh list
    ufBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end

    -- Party / Raid Button
    local prBtn = GUI:CreateButton(buttonBar, "Party / Raid", 95, 32, function()
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
    prBtn:SetPoint("LEFT", ufBtn, "RIGHT", 10, 0)
    -- Matching User Image: Standardize to Theme Blue
    prBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    prBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Add to refresh list
    prBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    
    parent.buttonBar = buttonBar
end

---------------------------------------------------------------------------
-- CREATE SIDEBAR BUTTONS
---------------------------------------------------------------------------
CreateSidebarButtons = function()
    local frame = GUI.MainFrame
    if not frame then return end
    
    local yOffset = 10
    local buttonIndex = 0
    
    for i, pageId in ipairs(GUI.pageOrder) do
        local opts = GUI.pages[pageId]
        if not opts.hideFromSidebar and (not opts.showIf or opts.showIf()) then
            buttonIndex = buttonIndex + 1
            
            local btn = CreateFrame("Button", nil, frame.sidebar, "BackdropTemplate")
            btn:SetSize(160, 36)
            btn:SetPoint("TOPLEFT", 10, -yOffset)
            
            -- Tech Nav Styling (Transparent default)
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            btn:SetBackdropColor(0, 0, 0, 0)
            
            -- Vertical Indicator (Hidden by default)
            local indicator = btn:CreateTexture(nil, "OVERLAY")
            indicator:SetWidth(3)
            indicator:SetPoint("TOPLEFT", 0, 0)
            indicator:SetPoint("BOTTOMLEFT", 0, 0)
            indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
            indicator:Hide()
            btn.indicator = indicator
            
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            GUI:SetFont(btnText, 13, "") -- Removed Outline
            btnText:SetTextColor(1, 1, 1, 1) -- White text as requested
            btnText:SetText(opts.title or pageId)
            btnText:SetPoint("LEFT", 15, 0)
            
            btn.text = btnText
            btn.pageIndex = i
            
            -- Refresh Method
            btn.RefreshColors = function(self)
                local isSelected = (GUI.currentPageIndex == self.pageIndex)
                if isSelected then
                    self.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                    -- Re-apply selection state gradient if we had one (simplified here)
                end
            end
            
            -- Click handler
            btn:SetScript("OnClick", function()
                GUI:ShowPage(i)
            end)
            
            -- Hover effect
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
            
            frame.sidebarButtons[buttonIndex] = btn
            yOffset = yOffset + 42
        end
    end
end

---------------------------------------------------------------------------
-- UPDATE BUTTON SELECTION
---------------------------------------------------------------------------
UpdateButtonSelection = function()
    local frame = GUI.MainFrame
    if not frame then return end
    
    for _, btn in ipairs(frame.sidebarButtons) do
        if btn.pageIndex == GUI.currentPageIndex then
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

function GUI:ShowPage(index)
    if not self.MainFrame then return end
    
    -- Handle string ID or Index
    local pageId = type(index) == "string" and index or self.pageOrder[index]
    if not pageId then return end
    
    -- Correct numeric index if string ID was used
    if type(index) == "string" then
        for i, id in ipairs(self.pageOrder) do
            if id == index then index = i; break end
        end
    end
    
    -- Don't switch if already on it
    if self.currentPageId == pageId then return end
    
    -- Handle Search state return
    if pageId == "search" then
        if self.currentPageId ~= "search" then
            self.preSearchPageId = self.currentPageId
            self.preSearchPageIndex = self.currentPageIndex
        end
    end
    
    -- Hide ALL pages to prevent overlap
    HideAllPages()
    
    -- Show new page
    local opts = self.pages[pageId]
    if not opts then return end
    
    if not opts.frame then
        opts.frame = BuildPageFrame(opts)
    end
    
    opts.frame:Show()
    self.currentPageIndex = index
    self.currentPageId = pageId
    
    if opts.OnShow then
        opts.OnShow(opts.frame:GetScrollChild())
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
    
    -- 1. Switch Page
    self:ShowPage(item.pageId)
    
    -- 2. Switch Tab (if applicable)
    local page = self.pages[item.pageId]
    if page and item.tabIndex and item.tabIndex > 0 and page.subTabs then
        if page.subTabs.tabButtons and page.subTabs.tabButtons[item.tabIndex] then
            page.subTabs.tabButtons[item.tabIndex]:Click()
        end
    end
    
    -- 3. Scroll to widget (delayed to allow build/layout)
    C_Timer.After(0.1, function()
        if item.widget and item.widget:IsVisible() then
            local scrollFrame = page.frame
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
