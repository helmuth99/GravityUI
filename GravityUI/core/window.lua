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
local function CreateMainWindow()
    if GUI.MainFrame then return end
    
    local frame = CreateFrame("Frame", "GravityUIFrame", UIParent, "BackdropTemplate")
    frame:SetSize(900, 650)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true) -- Enable resizing
    frame:SetResizeBounds(900, 600, 1920, 1200) -- Min/Max sizes
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.98)
    frame:SetBackdropBorderColor(C.borderAccent[1], C.borderAccent[2], C.borderAccent[3], 1)
    
    -- Make draggable
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- ESC to close
    table.insert(UISpecialFrames, "GravityUIFrame")
    
    GUI.MainFrame = frame
    
    -- Create components
    CreateTopBar(frame)
    CreateButtonBar(frame) -- Create ButtonBar first for anchoring
    CreateSidebar(frame)
    CreateContentArea(frame)
    
    -- Resize Grip
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(20, 20) -- Slightly larger for better visibility
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    
    -- Use standard WoW resize texture (guaranteed to exist)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    -- Color it to match theme (muted by default, accent on hover)
    local gripTex = grip:GetNormalTexture()
    if gripTex then
        gripTex:SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.7)
    end
    
    grip:SetScript("OnMouseDown", function() 
        frame:StartSizing("BOTTOMRIGHT")
        frame.isResizing = true 
    end)
    
    grip:SetScript("OnMouseUp", function() 
        frame:StopMovingOrSizing()
        frame.isResizing = false
    end)
    
    grip:SetScript("OnEnter", function(self) 
        if self:GetNormalTexture() then
            self:GetNormalTexture():SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end
    end)
    
    grip:SetScript("OnLeave", function(self)
        if self:GetNormalTexture() then
            self:GetNormalTexture():SetVertexColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.7)
        end
    end)
end

---------------------------------------------------------------------------
-- TOP BAR (Title, Logo, Close Button)
---------------------------------------------------------------------------
function CreateTopBar(parent)
    local topBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    topBar:SetHeight(60)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)
    
    topBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    topBar:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 1)
    
    -- Title
    local title = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(title, 18, "OUTLINE")
    title:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
    title:SetText("GravityUI")
    title:SetPoint("LEFT", 20, 0)
    
    -- Version
    local version = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(version, 11, "OUTLINE")
    version:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
    version:SetText("v" .. ns.VERSION)
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
    
    parent.topBar = topBar
end

---------------------------------------------------------------------------
-- SIDEBAR (Navigation Tabs)
---------------------------------------------------------------------------
function CreateSidebar(parent)
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
function CreateContentArea(parent)
    local content = CreateFrame("Frame", nil, parent)
    content:SetPoint("TOPLEFT", 180, -60)
    content:SetPoint("BOTTOMRIGHT", 0, 50) -- Attach to bottom button bar
    
    parent.contentArea = content
end

---------------------------------------------------------------------------
-- BUTTON BAR (Cooldown Settings, Edit Mode)
---------------------------------------------------------------------------
function CreateButtonBar(parent)
    local buttonBar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    buttonBar:SetHeight(50)
    buttonBar:SetPoint("BOTTOMLEFT", 0, 0)
    buttonBar:SetPoint("BOTTOMRIGHT", 0, 0)
    
    buttonBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    buttonBar:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.8)
    
    -- Installers Button
    local instBtn = GUI:CreateButton(buttonBar, "Installers", 120, 32, function()
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
    
    -- Cooldown Settings Button
    local cdmBtn = GUI:CreateButton(buttonBar, "Cooldown Settings", 160, 32, function()
        if CooldownViewerSettings then
            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
        else
            print("|cFF30D1FFGravityUI:|r Cooldown Settings not available.")
        end
    end)
    cdmBtn:SetPoint("LEFT", instBtn, "RIGHT", 10, 0)
    
    -- Edit Mode Button
    local editBtn = GUI:CreateButton(buttonBar, "Edit Mode", 120, 32, function()
        if EditModeManagerFrame then
            if EditModeManagerFrame:IsShown() then
                EditModeManagerFrame:Hide()
            else
                EditModeManagerFrame:Show()
            end
        else
            print("|cFF30D1FFGravityUI:|r Edit Mode not available.")
        end
    end)
    editBtn:SetPoint("LEFT", cdmBtn, "RIGHT", 10, 0)
    
    parent.buttonBar = buttonBar
end

---------------------------------------------------------------------------
-- CREATE SIDEBAR BUTTONS
---------------------------------------------------------------------------
local function CreateSidebarButtons()
    local frame = GUI.MainFrame
    if not frame then return end
    
    local yOffset = 10
    local buttonIndex = 0
    
    for i, pageId in ipairs(GUI.pageOrder) do
        local opts = GUI.pages[pageId]
        if not opts.showIf or opts.showIf() then
            buttonIndex = buttonIndex + 1
            
            local btn = CreateFrame("Button", nil, frame.sidebar, "BackdropTemplate")
            btn:SetSize(160, 36)
            btn:SetPoint("TOPLEFT", 10, -yOffset)
            
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            btn:SetBackdropColor(0, 0, 0, 0)
            btn:SetBackdropBorderColor(0, 0, 0, 0)
            
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            GUI:SetFont(btnText, 13, "OUTLINE")
            btnText:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3], 1)
            btnText:SetText(opts.title or pageId)
            btnText:SetPoint("LEFT", 10, 0)
            
            btn.text = btnText
            btn.pageIndex = i
            
            -- Click handler
            btn:SetScript("OnClick", function()
                GUI:ShowPage(i)
            end)
            
            -- Hover effect
            btn:SetScript("OnEnter", function(self)
                if GUI.currentPageIndex ~= self.pageIndex then
                    self:SetBackdropColor(C.tabHover[1], C.tabHover[2], C.tabHover[3], C.tabHover[4])
                end
            end)
            
            btn:SetScript("OnLeave", function(self)
                if GUI.currentPageIndex ~= self.pageIndex then
                    self:SetBackdropColor(0, 0, 0, 0)
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
local function UpdateButtonSelection()
    local frame = GUI.MainFrame
    if not frame then return end
    
    for _, btn in ipairs(frame.sidebarButtons) do
        if btn.pageIndex == GUI.currentPageIndex then
            -- Selected state
            btn:SetBackdropColor(C.tabSelected[1], C.tabSelected[2], C.tabSelected[3], C.tabSelected[4])
            btn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
            btn.text:SetTextColor(C.tabSelectedText[1], C.tabSelectedText[2], C.tabSelectedText[3], 1)
        else
            -- Normal state
            btn:SetBackdropColor(0, 0, 0, 0)
            btn:SetBackdropBorderColor(0, 0, 0, 0)
            btn.text:SetTextColor(C.textBright[1], C.textBright[2], C.textBright[3], 1)
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
        opts.OnBuild(content)
    end
    
    return frame
end

---------------------------------------------------------------------------
-- SHOW PAGE
---------------------------------------------------------------------------
function GUI:ShowPage(index)
    if not self.MainFrame then return end
    
    -- Hide current page
    local currentPageId = self.pageOrder[self.currentPageIndex]
    if currentPageId then
        local currentOpts = self.pages[currentPageId]
        if currentOpts and currentOpts.frame then
            currentOpts.frame:Hide()
        end
    end
    
    -- Show new page
    local pageId = self.pageOrder[index]
    if not pageId then return end
    
    local opts = self.pages[pageId]
    if not opts.frame then
        opts.frame = BuildPageFrame(opts)
    end
    
    opts.frame:Show()
    self.currentPageIndex = index
    
    UpdateButtonSelection()
end

---------------------------------------------------------------------------
-- TOGGLE WINDOW
---------------------------------------------------------------------------
function GUI:Toggle()
    if not self.MainFrame then
        CreateMainWindow()
        CreateSidebarButtons()
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
        CreateMainWindow()
        CreateSidebarButtons()
        self:ShowPage(1)
    end
    
    self.MainFrame:Show()
end

---------------------------------------------------------------------------
-- HIDE WINDOW
---------------------------------------------------------------------------
function GUI:Hide()
    if self.MainFrame then
        self.MainFrame:Hide()
    end
end
