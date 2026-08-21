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
-- Reset Window Command
_G.SlashCmdList["GRAVITYUI_RESETWINDOW"] = function()
    local db = ns.GetDB()
    if db and db.general then
        db.general.windowSize = { width = 980, height = 680 }
        if GUI.MainFrame then
            GUI.MainFrame:SetSize(980, 680)
            GUI.MainFrame:SetPoint("CENTER")
        end
        print("|cFF30D1FFGravityUI:|r Window size has been reset to default (980x680).")
    end
end
_G.SLASH_GRAVITYUI_RESETWINDOW1 = "/gravityreset"

-- Forward Declarations
local CreateTopBar, CreateButtonBar, CreateSidebar, CreateContentArea, UpdateButtonSelection
local function CreateMainWindow()
    if GUI.MainFrame then return end

    local db = ns.GetDB()
    local width = db and db.general and db.general.windowSize and db.general.windowSize.width or 980
    local height = db and db.general and db.general.windowSize and db.general.windowSize.height or 680
    
    -- Safety Clamping: Ensure it fits the screen on load
    local screenW, screenH = UIParent:GetSize()
    width = math.min(width, screenW * 0.9)
    height = math.min(height, screenH * 0.9)
    -- Also ensure it respects our defined bounds (80% of screen size)
    local maxW = screenW * 0.8
    local maxH = screenH * 0.8
    width = math.max(920, math.min(maxW, width))
    height = math.max(600, math.min(maxH, height))
    
    local frame = CreateFrame("Frame", "GravityUIFrame", UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(920, 600, maxW, maxH)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Glassmorphic Backdrop
    GUI:CreateBackdrop(frame, C.bgGlass)
    
    -- Draggable Script
    -- Guard: do not move the window while a scrollbar thumb is being dragged
    frame:SetScript("OnDragStart", function(self)
        if not GUI._scrollThumbDragging then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing()
        -- Save size if it was a resize operation
        if db and db.general then
            local w, h = self:GetSize()
            db.general.windowSize = { width = w, height = h }
        end
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
    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    resizeGrip:SetScript("OnMouseDown", function(self)
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function(self)
        frame:StopMovingOrSizing()
        if db and db.general then
            local w, h = frame:GetSize()
            db.general.windowSize = { width = w, height = h }
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
    
    -- Dark Grey Header (Matching Bottom Bar)
    topBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    topBar:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.8)
    
    -- Separator Line
    local separator = topBar:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(1)
    separator:SetPoint("BOTTOMLEFT", 0, 0)
    separator:SetPoint("BOTTOMRIGHT", 0, 0)
    separator:SetColorTexture(1, 1, 1, 0.05) -- Even more subtle divider

    
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
-- CUSTOM SCROLLBAR SKINNING (Unified Design)
---------------------------------------------------------------------------
function GUI:SkinScrollFrame(scroll, parent)
    parent = parent or scroll:GetParent()
    local C = GUI.Colors
    
    -- 1. Suppress native Blizzard scrollbar (both by name and by reference)
    local function SuppressNativeSB(nativeSB)
        if not nativeSB then return end
        nativeSB:Hide()
        nativeSB:SetAlpha(0)
        nativeSB:EnableMouse(false)
        nativeSB:HookScript("OnShow", function(self) self:Hide() end)
    end
    local sbByRef = scroll.ScrollBar
    local sbByName = scroll:GetName() and _G[scroll:GetName().."ScrollBar"]
    SuppressNativeSB(sbByRef)
    -- Only suppress by name if it's a different object (avoid double-hooking)
    if sbByName and sbByName ~= sbByRef then
        SuppressNativeSB(sbByName)
    end
    
    -- 2. Scroll Indicators (Arrow Bars) 
    -- Top Indicator (Parented to scroll but anchored to edge)
    local indicatorUpContainer = CreateFrame("Frame", nil, scroll)
    indicatorUpContainer:SetSize(parent:GetWidth(), 16)
    indicatorUpContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    
    local upBg = indicatorUpContainer:CreateTexture(nil, "BACKGROUND")
    upBg:SetAllPoints()
    upBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    local indicatorUp = indicatorUpContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(indicatorUp, 12, "")
    indicatorUp:SetPoint("CENTER", 0, 1)
    indicatorUp:SetText("▲")
    indicatorUp:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    indicatorUpContainer:SetAlpha(0)
    indicatorUpContainer:EnableMouse(false)
    
    -- Bottom Indicator (Parented to scroll but anchored to edge)
    local indicatorDownContainer = CreateFrame("Frame", nil, scroll)
    indicatorDownContainer:SetSize(parent:GetWidth(), 16)
    indicatorDownContainer:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    
    local downBg = indicatorDownContainer:CreateTexture(nil, "BACKGROUND")
    downBg:SetAllPoints()
    downBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    local indicatorDown = indicatorDownContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(indicatorDown, 12, "")
    indicatorDown:SetPoint("CENTER", 0, -1)
    indicatorDown:SetText("▼")
    indicatorDown:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    indicatorDownContainer:SetAlpha(0)
    indicatorDownContainer:EnableMouse(false)
    
    local function UpdateScrollIndicators()
        local current = scroll:GetVerticalScroll()
        local maxRange = scroll:GetVerticalScrollRange()
        indicatorUpContainer:SetAlpha(current > 1 and 1 or 0)
        indicatorDownContainer:SetAlpha((maxRange > 0 and current < (maxRange - 1)) and 1 or 0)
    end
    
    -- 3. Custom "Magnetic" Scrollbar
    -- Parent to GUI.MainFrame at a very high frame level (500) to guarantee mouse
    -- events are received regardless of any other frame in the hierarchy.
    -- Anchored to `parent` (contentArea) for correct positioning.
    local sb = CreateFrame("Frame", nil, GUI.MainFrame)
    sb:SetWidth(32)
    sb:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -22)
    sb:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 22)
    sb:SetFrameLevel(500)
    sb:EnableMouse(false) -- Track area: no mouse capture needed; thumb handles it
    sb:Hide()
    
    local thumb = CreateFrame("Frame", nil, sb)
    thumb:SetSize(32, 28)
    thumb:SetPoint("RIGHT", 0, 0)
    thumb:SetFrameLevel(501)
    thumb:EnableMouse(true)
    
    -- Accent bright = slightly lighter version of accent for hover/drag state
    local aR = math.min(1, C.accent[1] + 0.25)
    local aG = math.min(1, C.accent[2] + 0.15)
    local aB = math.min(1, C.accent[3] + 0.05)
    
    local thumbBar = thumb:CreateTexture(nil, "OVERLAY")
    thumbBar:SetSize(10, 24)
    thumbBar:SetPoint("RIGHT", -2, 0)
    thumbBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumbBar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
    
    local function UpdateThumb()
        local maxRange = scroll:GetVerticalScrollRange()
        if maxRange <= 0 then thumb:Hide(); return end
        thumb:Show()
        local current = scroll:GetVerticalScroll()
        local trackHeight = sb:GetHeight() - thumb:GetHeight()
        if trackHeight > 0 then
            thumb:SetPoint("TOPRIGHT", 0, -((current / maxRange) * trackHeight))
        end
    end
    
    -- Hover feedback
    thumb:SetScript("OnEnter", function()
        thumbBar:SetVertexColor(aR, aG, aB, 1)
        thumbBar:SetSize(12, 24)
    end)
    thumb:SetScript("OnLeave", function()
        if not thumb.isDragging then
            thumbBar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
            thumbBar:SetSize(10, 24)
        end
    end)
    
    -- Drag: OnMouseDown/OnMouseUp + GUI._scrollThumbDragging flag to prevent
    -- the main window from starting a move during scrollbar drag
    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        self.isDragging = true
        GUI._scrollThumbDragging = true
        if GUI.MainFrame then GUI.MainFrame:StopMovingOrSizing() end
        local _, y = GetCursorPosition()
        self.lastY = y / self:GetEffectiveScale()
        thumbBar:SetVertexColor(aR, aG, aB, 1)
        thumbBar:SetSize(12, 24)
    end)
    thumb:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then return end
        self.isDragging = false
        GUI._scrollThumbDragging = false
        thumbBar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
        thumbBar:SetSize(10, 24)
    end)
    
    -- OnUpdate on sb: drives drag movement + safety-net for missed OnMouseUp
    -- sb is always shown while its associated scroll page is active (see below)
    sb:SetScript("OnUpdate", function()
        if not thumb.isDragging then return end
        -- Safety: release if button no longer held (e.g. released outside frame)
        if not IsMouseButtonDown("LeftButton") then
            thumb.isDragging = false
            GUI._scrollThumbDragging = false
            thumbBar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
            thumbBar:SetSize(10, 24)
            return
        end
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
    end)
    
    scroll:HookScript("OnVerticalScroll", function() UpdateScrollIndicators(); UpdateThumb() end)
    scroll:HookScript("OnScrollRangeChanged", function() UpdateScrollIndicators(); UpdateThumb() end)
    
    -- Visibility sync: sb mirrors the scroll frame's shown/hidden state
    scroll:HookScript("OnShow", function()
        sb:Show()
        UpdateScrollIndicators()
        UpdateThumb()
    end)
    scroll:HookScript("OnHide", function()
        -- Clean up any active drag state to prevent GUI._scrollThumbDragging
        -- from getting permanently stuck if the page changes mid-drag
        if thumb.isDragging then
            thumb.isDragging = false
            GUI._scrollThumbDragging = false
        end
        sb:Hide()
    end)
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
    sidebarContainer:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.8)
    
    -- Create the actual scroll frame
    local scroll = CreateFrame("ScrollFrame", "GravityUISidebarScroll", sidebarContainer, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -16)
    scroll:SetPoint("BOTTOMRIGHT", 0, 16)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(180, 1) -- Height gets updated dynamically
    scroll:SetScrollChild(content)
    
    -- Apply the Unified Custom Scrollbar Skin
    GUI:SkinScrollFrame(scroll, sidebarContainer)
    
    parent.sidebarContainer = sidebarContainer
    parent.sidebar = content -- Buttons attach here
    parent.sidebarButtons = {}
end

---------------------------------------------------------------------------
-- CONTENT AREA
---------------------------------------------------------------------------
CreateContentArea = function(parent)
    local content = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    content:SetPoint("TOPLEFT", 180, -60)
    content:SetPoint("BOTTOMRIGHT", 0, 50) -- Attach to bottom button bar
    
    -- Dark Grey Backdrop for readability (Matching Sidebar/BottomBar)
    content:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    content:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.8)
    
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
            GUI:ShowPage(idx, 4) 
        end
    end)
    instBtn:SetPoint("LEFT", 15, 0)
    instBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
    instBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    instBtn.RefreshColors = function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end

    -- GUI Edit Mode Button
    local editBtn = GUI:CreateButton(buttonBar, "GUI Edit Mode", 120, 32, function()
        if ns.Movers then
            ns.Movers:SetEditMode(true)
        end
    end)
    editBtn:SetPoint("LEFT", instBtn, "RIGHT", 20, 0)
    editBtn:SetBackdropColor(0.1, 0.7, 0.3, 0.6)
    editBtn:SetBackdropBorderColor(0.1, 0.8, 0.3, 1)
    editBtn.RefreshColors = function(self)
        self:SetBackdropColor(0.1, 0.7, 0.3, 0.6)
        self:SetBackdropBorderColor(0.1, 0.8, 0.3, 1)
    end

    -- Cooldown Settings Button
    local cdmBtn = GUI:CreateButton(buttonBar, "CDM Settings", 130, 32, function()
        if CooldownViewerSettings then
            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
        else
            print("|cFF30D1FFGravityUI:|r Cooldown Settings not available.")
        end
    end)
    cdmBtn:SetPoint("LEFT", editBtn, "RIGHT", 8, 0)
    
    -- EllesmereUI Button (with logo)
    local euiBtn = CreateFrame("Button", nil, buttonBar, "BackdropTemplate")
    euiBtn:SetSize(130, 32)
    euiBtn:SetPoint("LEFT", cdmBtn, "RIGHT", 20, 0)
    euiBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    euiBtn:SetBackdropColor(0.15, 0.12, 0.25, 0.7)
    euiBtn:SetBackdropBorderColor(0.5, 0.3, 0.8, 1)

    -- EUI Logo icon
    local euiIcon = euiBtn:CreateTexture(nil, "ARTWORK")
    euiIcon:SetSize(22, 22)
    euiIcon:SetPoint("LEFT", 6, 0)
    euiIcon:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\eg-logo")
    euiIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Text label
    local euiLabel = euiBtn:CreateFontString(nil, "OVERLAY")
    if GUI.SetFont then
        GUI:SetFont(euiLabel, 11, "", {1, 1, 1, 1})
    else
        euiLabel:SetFontObject(GameFontNormal)
    end
    euiLabel:SetText("EllesmereUI")
    euiLabel:SetPoint("LEFT", euiIcon, "RIGHT", 4, 0)

    euiBtn:SetScript("OnClick", function()
        if SlashCmdList["ELLESMEREUI"] then
            SlashCmdList["ELLESMEREUI"]("")
        elseif SlashCmdList["EUI"] then
            SlashCmdList["EUI"]("")
        elseif C_AddOns.IsAddOnLoaded("EllesmereUI") then
            -- Brute force scan
            for k, v in pairs(_G) do
                if type(k) == "string" and k:match("^SLASH_") and type(v) == "string" then
                    if v:lower() == "/eui" or v:lower() == "/ellesmereui" then
                        local key = k:match("^SLASH_(.+)%d+$")
                        if key and SlashCmdList[key] then
                            SlashCmdList[key]("")
                            return
                        end
                    end
                end
            end
            print("|cFF30D1FFGravityUI:|r EllesmereUI loaded but could not open config.")
        else
            print("|cFF30D1FFGravityUI:|r EllesmereUI is not loaded.")
        end
    end)

    euiBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.2, 0.4, 0.9)
        self:SetBackdropBorderColor(0.7, 0.4, 1, 1)
    end)
    euiBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.12, 0.25, 0.7)
        self:SetBackdropBorderColor(0.5, 0.3, 0.8, 1)
    end)

    euiBtn.RefreshColors = function(self)
        self:SetBackdropColor(0.15, 0.12, 0.25, 0.7)
        self:SetBackdropBorderColor(0.5, 0.3, 0.8, 1)
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

function GUI:UpdateSidebarLayout()
    local frame = self.MainFrame
    if not frame then return end

    local yOffset = 15
    local PADDING_LEFT = 12

    for _, item in ipairs(frame.sidebarItems) do
        item:SetPoint("TOPLEFT", PADDING_LEFT, -yOffset)
        yOffset = yOffset + 38
    end

    frame.sidebar:SetHeight(math.max(yOffset + 20, 1))
end

CreateSidebarButtons = function()
    local frame = GUI.MainFrame
    if not frame then return end

    frame.sidebarItems = {}
    frame.sidebarButtons = {}

    -- Icon mapping per page ID (custom white icons)
    local ICON_DIR = "Interface\\AddOns\\GravityUI\\assets\\sidebar\\"
    local SIDEBAR_ICONS = {
        main       = ICON_DIR .. "icon_main",
        minimap    = ICON_DIR .. "icon_minimap",
        actionbars = ICON_DIR .. "icon_actionbars",
        datapanels = ICON_DIR .. "icon_datapanels",
        qol        = ICON_DIR .. "icon_qol",
        features   = ICON_DIR .. "icon_features",
        indicators = ICON_DIR .. "icon_indicators",
        Styling    = ICON_DIR .. "icon_styling",
        profiles   = ICON_DIR .. "icon_profiles",
    }

    local buttonIndex = 0

    for i, pageId in ipairs(GUI.pageOrder) do
        local opts = GUI.pages[pageId]
        if not opts.hideFromSidebar and (not opts.showIf or opts.showIf()) then
            buttonIndex = buttonIndex + 1

            local btn = CreateFrame("Button", nil, frame.sidebar, "BackdropTemplate")
            btn:SetSize(175, 34)
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            btn:SetBackdropColor(0, 0, 0, 0)

            -- Left accent indicator stripe
            local indicator = btn:CreateTexture(nil, "OVERLAY")
            indicator:SetWidth(3)
            indicator:SetPoint("TOPLEFT", 0, 0)
            indicator:SetPoint("BOTTOMLEFT", 0, 0)
            indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
            indicator:Hide()
            btn.indicator = indicator

            -- Sidebar Icon
            local iconPath = SIDEBAR_ICONS[pageId]
            local iconTex
            if iconPath then
                iconTex = btn:CreateTexture(nil, "ARTWORK")
                iconTex:SetSize(16, 16)
                iconTex:SetPoint("LEFT", 12, 0)
                iconTex:SetTexture(iconPath)
                iconTex:SetVertexColor(0.7, 0.7, 0.7, 0.8)
            end
            btn.icon = iconTex

            local textOffset = iconTex and 34 or 15
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            GUI:SetFont(btnText, 13, "")
            btnText:SetText(opts.title or pageId)
            btnText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
            btnText:SetPoint("LEFT", textOffset, 0)

            btn.text       = btnText
            btn.pageIndex  = i
            btn.pageId     = pageId
            btn.subTabIndex = 1
            btn.type       = "page"
            btn._textOffset = textOffset

            btn:SetScript("OnClick", function()
                GUI:ShowPage(i, 1)
            end)

            btn:SetScript("OnEnter", function(self)
                if GUI.currentPageIndex ~= self.pageIndex then
                    self:SetBackdropColor(1, 1, 1, 0.05)
                    self.text:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
                    self.text:SetPoint("LEFT", self._textOffset + 4, 0)
                    if self.icon then self.icon:SetVertexColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1) end
                end
            end)

            btn:SetScript("OnLeave", function(self)
                if GUI.currentPageIndex ~= self.pageIndex then
                    self:SetBackdropColor(0, 0, 0, 0)
                    self.text:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
                    self.text:SetPoint("LEFT", self._textOffset, 0)
                    if self.icon then self.icon:SetVertexColor(0.7, 0.7, 0.7, 0.8) end
                end
            end)

            frame.sidebarButtons[buttonIndex] = btn
            table.insert(frame.sidebarItems, btn)
        end
    end

    GUI:UpdateSidebarLayout()
end

---------------------------------------------------------------------------
-- REFRESH SIDEBAR STYLE
---------------------------------------------------------------------------
function GUI:RefreshSidebarStyle()
    local frame = GUI.MainFrame
    if not frame or not frame.sidebarItems then return end

    local C = GUI.Colors
    local curPage = GUI.currentPageIndex

    for _, item in ipairs(frame.sidebarItems) do
        if not item.indicator or not item.text then break end
        -- Refresh accent color on the stripe
        item.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        local offset = item._textOffset or 15

        if item.pageIndex == curPage then
            item.indicator:Show()
            item:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.08)
            item.text:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
            item.text:SetPoint("LEFT", offset, 0)
            if item.icon then item.icon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1) end
        else
            item.indicator:Hide()
            item:SetBackdropColor(0, 0, 0, 0)
            item.text:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
            item.text:SetPoint("LEFT", offset, 0)
            if item.icon then item.icon:SetVertexColor(0.7, 0.7, 0.7, 0.8) end
        end
    end
end


---------------------------------------------------------------------------
-- UPDATE BUTTON SELECTION
---------------------------------------------------------------------------
UpdateButtonSelection = function()
    local frame = GUI.MainFrame
    if not frame then return end

    local curPage = GUI.currentPageIndex

    for _, btn in ipairs(frame.sidebarButtons) do
        local isSelected = (btn.pageIndex == curPage)
        local offset = btn._textOffset or 15

        if isSelected then
            btn.indicator:Show()
            btn.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
            btn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.08)
            btn.text:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
            btn.text:SetPoint("LEFT", offset, 0)
            if btn.icon then btn.icon:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1) end
        else
            btn.indicator:Hide()
            btn:SetBackdropColor(0, 0, 0, 0)
            btn.text:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
            btn.text:SetPoint("LEFT", offset, 0)
            if btn.icon then btn.icon:SetVertexColor(0.7, 0.7, 0.7, 0.8) end
        end
    end
end


---------------------------------------------------------------------------
-- BUILD PAGE FRAME
---------------------------------------------------------------------------
local function BuildPageFrame(opts)
    -- Use a counter for unique names (#GUI.pages is a hash table → always 0)
    GUI._pageScrollCount = (GUI._pageScrollCount or 0) + 1
    local frame = CreateFrame("ScrollFrame", "GravityUIContentScroll"..GUI._pageScrollCount, GUI.MainFrame.contentArea, "UIPanelScrollFrameTemplate")
    frame:SetPoint("TOPLEFT", 10, -10)
    frame:SetPoint("BOTTOMRIGHT", -30, 10) -- 30px right margin to accommodate the custom scrollbar (32px wide)
    
    local content = CreateFrame("Frame", nil, frame)
    content:SetSize(frame:GetWidth(), 1) -- Set initial width
    frame:SetScrollChild(content)
    
    -- Apply Unified Custom Scrollbar Skin
    GUI:SkinScrollFrame(frame, GUI.MainFrame.contentArea)
    
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

    -- Visibility Check for Subtabs (Fallback to first visible if target is hidden)
    local opts = self.pages[pageId]
    if opts and opts.subTabs and subIndex then
        local tabInfo = opts.subTabs[subIndex]
        local isVisible = not tabInfo or (not tabInfo.bcdmOnly and (not tabInfo.showIf or tabInfo.showIf()))
        
        if not isVisible then
            for i, tab in ipairs(opts.subTabs) do
                if not tab.bcdmOnly and (not tab.showIf or tab.showIf()) then
                    subIndex = i
                    break
                end
            end
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

    -- (Option C: no expand/collapse state needed)
    
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
        self:RefreshColors()
        
        CreateMainWindow()
        CreateSidebarButtons()
        self:BuildSearchIndex()
        self:ShowPage(1)
    end
    
    -- Sync Colors ON SHOW to ensure freshness
    self:RefreshColors()
    
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
        if self.CloseSearchResults then
            self:CloseSearchResults()
        end
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


