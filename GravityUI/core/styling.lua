local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = ns.Colors
local LCG = LibStub("LibCustomGlow-1.0", true)
local LSM = LibStub("LibSharedMedia-3.0", true)

-- Create module
ns.Styling = {}
local Styling = ns.Styling

-- Constants
local BUTTON_SIZE = 40
local BUTTON_SPACING = 0

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

local function GetDB()
    if ns.db and ns.db.profile and ns.db.profile.styling then
        return ns.db.profile.styling
    end
    -- Fallback/Initialize
    if ns.db and ns.db.profile then
        if not ns.db.profile.styling then ns.db.profile.styling = {} end
        return ns.db.profile.styling
    end
    return nil
end

local function GetFontPath()
    local general = ns.db.profile.general
    local fontName = (general and general.font) or "Gravity"
    return LSM:Fetch("font", fontName)
end

-------------------------------------------------------------------------------
-- CHAT BUBBLES
-------------------------------------------------------------------------------
function Styling:SkinChatBubbles()
    local db = GetDB()
    -- Only proceed if Chat Bubbles are enabled (default enabled if nil)
    if db.chatBubbles and db.chatBubbles.enabled == false then return end
    
    local fontPath = GetFontPath()
    if not fontPath then return end

    local fontSize = (db.chatBubbles and db.chatBubbles.fontSize) or 12
    local fontOutline = (db.chatBubbles and db.chatBubbles.fontOutline) or "OUTLINE"

    if ChatBubbleFont and ChatBubbleFont.SetFont then
        ChatBubbleFont:SetFont(fontPath, fontSize, fontOutline)
    end
end

-------------------------------------------------------------------------------
-- GAME MENU
-------------------------------------------------------------------------------
-- Helper: Get Game Menu Colors
local function GetGameMenuColors()
    local db = GetDB()
    if not db or not db.gamemenu then return 0.2, 0.2, 0.2, 1, 0.05, 0.05, 0.05, 0.95 end
    
    local sr, sg, sb, sa = ns.GetAccentColor()
    
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
    
    -- Check Background Override
    if db.gamemenu.disableThemeColorBackground then
        local c = db.gamemenu.customBackgroundColor
        if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
    else
        -- Use Theme Background if enabled in General
        local themeBg = ns.db.profile.general.themeBgColor
        if themeBg then bgr, bgg, bgb, bga = themeBg[1], themeBg[2], themeBg[3], themeBg[4] end
    end
    
    return sr, sg, sb, sa, bgr, bgg, bgb, bga
end

local function GetGameMenuFontColor()
    local db = GetDB()
    if not db or not db.gamemenu then return 0.9, 0.9, 0.9, 1 end
    
    if db.gamemenu.disableThemeColorFont then
        local c = db.gamemenu.customFontColor
        if c then return c[1], c[2], c[3], c[4] end
        -- Use Theme Accent (Primary Color)
        return ns.GetAccentColor()
    end
    return 0.9, 0.9, 0.9, 1
end

-- Helper: Style Button (Updated to allow refreshing)
local function StyleGameMenuButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button then return end

    if not button.guiBackdrop then
        button.guiBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.guiBackdrop:SetAllPoints()
        button.guiBackdrop:SetFrameLevel(button:GetFrameLevel()) -- Behind text
        button.guiBackdrop:EnableMouse(false)
        
        button.guiBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        
        -- Hide default textures once
        if button.Left then button.Left:SetAlpha(0) end
        if button.Right then button.Right:SetAlpha(0) end
        if button.Center then button.Center:SetAlpha(0) end
        if button.Middle then button.Middle:SetAlpha(0) end
        local highlight = button:GetHighlightTexture()
        if highlight then highlight:SetAlpha(0) end
        
        button:HookScript("OnEnter", function(self)
            if self.guiBackdrop and self.guiSkinColor then
                local r, g, b, a = unpack(self.guiSkinColor)
                self.guiBackdrop:SetBackdropBorderColor(math.min(r * 1.3, 1), math.min(g * 1.3, 1), math.min(b * 1.3, 1), a)
            end
        end)
        button:HookScript("OnLeave", function(self)
            if self.guiBackdrop and self.guiSkinColor then
                self.guiBackdrop:SetBackdropBorderColor(unpack(self.guiSkinColor))
            end
        end)
    end

    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.guiBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)

    -- Font Style Update
    local text = button:GetFontString()
    if text then
        local db = GetDB()
        local fontSize = (db and db.gamemenu and db.gamemenu.buttonFontSize) or 14
        local fontPath = GetFontPath()
        text:SetFont(fontPath, fontSize, "OUTLINE")
        
        local fr, fg, fb, fa = GetGameMenuFontColor()
        text:SetTextColor(fr, fg, fb, fa)
    end
    
    button.guiSkinColor = { sr, sg, sb, sa }
    button.guiStyled = true
end

-- Inject Button logic (Idempotent for updates)
local function InjectGravityUIButton(updateVisibilityOnly)
    if InCombatLockdown() then return end
    local db = GetDB()
    local shouldShow = db and db.gamemenu and db.gamemenu.showGravityButton
    
    -- Handle existing button visibility
    local existingBtn = nil
    if GameMenuFrame.buttonPool then
         for button in GameMenuFrame.buttonPool:EnumerateActive() do
            if button:GetText() == ADDON_NAME then
                existingBtn = button
                break
            end
        end
    end
    
    if updateVisibilityOnly then
        if existingBtn then
            if shouldShow then
                existingBtn:Show()
                 -- Force layout update if needed
                 GameMenuFrame:MarkDirty()
            else
                existingBtn:Hide()
                GameMenuFrame:MarkDirty()
            end
        end
        return
    end

    if not shouldShow then return end
    if not GameMenuFrame or not GameMenuFrame.buttonPool then return end

    -- Avoid duplicate injection if already exists
    if existingBtn then return end

    -- Find Macros to insert after
    local macrosIndex = nil
    for button in GameMenuFrame.buttonPool:EnumerateActive() do
        if button:GetText() == MACROS then
            macrosIndex = button.layoutIndex
            break
        end
    end

    if macrosIndex then
        -- Shift
        for button in GameMenuFrame.buttonPool:EnumerateActive() do
            if button.layoutIndex and button.layoutIndex > macrosIndex then
                button.layoutIndex = button.layoutIndex + 1
            end
        end
        
        -- Add Button
        local guiButton = GameMenuFrame:AddButton(ADDON_NAME, function()
            if not InCombatLockdown() then
                HideUIPanel(GameMenuFrame)
                ns.GUI:Show()
            end
        end)
        guiButton.layoutIndex = macrosIndex + 1
        GameMenuFrame:MarkDirty()
    end
end

function Styling:SkinGameMenu()
    if InCombatLockdown() then return end
    local db = GetDB()
    if not db or not db.gamemenu or not db.gamemenu.enabled then return end
    
    if not GameMenuFrame then return end
    
    -- Update Button Visibility
    InjectGravityUIButton(true)
    
    -- Hide Blizz decorations
    if GameMenuFrame.Border then GameMenuFrame.Border:Hide() end
    if GameMenuFrame.Header then GameMenuFrame.Header:Hide() end
    
    -- Backdrop
    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetGameMenuColors()
    
    if not GameMenuFrame.guiBackdrop then
        GameMenuFrame.guiBackdrop = CreateFrame("Frame", nil, GameMenuFrame, "BackdropTemplate")
        GameMenuFrame.guiBackdrop:SetAllPoints()
        GameMenuFrame.guiBackdrop:SetFrameLevel(GameMenuFrame:GetFrameLevel()) -- Behind buttons
        
         GameMenuFrame.guiBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
    end
    
    GameMenuFrame.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    GameMenuFrame.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    
    -- Padding
    GameMenuFrame.topPadding = 15
    GameMenuFrame.bottomPadding = 15
    GameMenuFrame.leftPadding = 15
    GameMenuFrame.rightPadding = 15
    GameMenuFrame.spacing = 4
    
    -- Style Active Buttons (Always update to catch font size changes)
    if GameMenuFrame.buttonPool then
        for button in GameMenuFrame.buttonPool:EnumerateActive() do
            StyleGameMenuButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end



    if GameMenuFrame.MarkDirty then GameMenuFrame:MarkDirty() end
end

function Styling:RefreshGameMenu()
    if GameMenuFrame and GameMenuFrame:IsShown() then
        Styling:SkinGameMenu()
    end
end


-- One-time Hook
local hasHookedGameMenu = false
function Styling:HookGameMenu()
    if hasHookedGameMenu then return end
    if GameMenuFrame and GameMenuFrame.InitButtons then
        hooksecurefunc(GameMenuFrame, "InitButtons", function()
             if InCombatLockdown() then return end
             InjectGravityUIButton()
             C_Timer.After(0, function() Styling:SkinGameMenu() end)
        end)
        hasHookedGameMenu = true
    end
end

-------------------------------------------------------------------------------
-- READY CHECK SKINNING & MOVER
-------------------------------------------------------------------------------

local readyCheckMover = nil

-- Position Helpers
function Styling:SaveReadyCheckPosition(point, relativeTo, relativePoint, x, y)
    local db = GetDB()
    if db then
        db.readyCheckPosition = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y
        }
    end
end

function Styling:GetReadyCheckPosition()
    local db = GetDB()
    return db and db.readyCheckPosition
end

function Styling:ResetReadyCheckPosition()
    local db = GetDB()
    if db then
        db.readyCheckPosition = nil
    end
    -- Reset to default position
    local frame = _G.ReadyCheckFrame
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
    end
    -- Also reset mover overlay if it exists
    if readyCheckMover then
        readyCheckMover:ClearAllPoints()
        readyCheckMover:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
    end
end

-- Mover Logic
local function CreateReadyCheckMover()
    if readyCheckMover then return end

    local frame = _G.ReadyCheckFrame
    if not frame then return end

    local sr, sg, sb, sa = ns.GetAccentColor()

    -- Create mover overlay
    readyCheckMover = CreateFrame("Frame", "GravityUI_ReadyCheckMover", UIParent, "BackdropTemplate")
    readyCheckMover:SetSize(frame:GetWidth() + 4, frame:GetHeight() + 4)
    readyCheckMover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    readyCheckMover:SetBackdropColor(sr, sg, sb, 0.3)
    readyCheckMover:SetBackdropBorderColor(sr, sg, sb, 1)
    readyCheckMover:EnableMouse(true)
    readyCheckMover:SetMovable(true)
    readyCheckMover:RegisterForDrag("LeftButton")
    readyCheckMover:SetFrameStrata("FULLSCREEN_DIALOG")
    readyCheckMover:Hide()

    -- Position mover
    local pos = Styling:GetReadyCheckPosition()
    if pos then
        readyCheckMover:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        readyCheckMover:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
    end

    -- Mover label
    readyCheckMover.text = readyCheckMover:CreateFontString(nil, "OVERLAY")
    readyCheckMover.text:SetPoint("CENTER")
    readyCheckMover.text:SetFont(GetFontPath(), 11, "OUTLINE")
    readyCheckMover.text:SetText("Ready Check")
    readyCheckMover.text:SetTextColor(1, 1, 1)

    -- Drag handlers
    readyCheckMover:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    readyCheckMover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        Styling:SaveReadyCheckPosition(point, nil, relPoint, x, y)
    end)
end

function Styling:ToggleReadyCheckMover(forceState)
    CreateReadyCheckMover()
    
    local shouldShow = false
    if forceState ~= nil then
        shouldShow = forceState
    else
        shouldShow = not (readyCheckMover and readyCheckMover:IsShown())
    end

    if shouldShow then
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(readyCheckMover, forceState == true)
        end
        if readyCheckMover then readyCheckMover:Show() end
    else
        if readyCheckMover then readyCheckMover:Hide() end
    end
end

-- Skinning Logic
local function HideBlizzardReadyCheckDecorations()
    local frame = _G.ReadyCheckFrame
    local listenerFrame = _G.ReadyCheckListenerFrame
    if not frame then return end

    if _G.ReadyCheckPortrait then _G.ReadyCheckPortrait:SetAlpha(0) end

    if listenerFrame then
        if listenerFrame.NineSlice then listenerFrame.NineSlice:SetAlpha(0) end
        if listenerFrame.PortraitContainer then listenerFrame.PortraitContainer:SetAlpha(0) end
        if listenerFrame.TitleContainer then listenerFrame.TitleContainer:SetAlpha(0) end
        if listenerFrame.Bg then listenerFrame.Bg:SetAlpha(0) end
        for _, region in ipairs({listenerFrame:GetRegions()}) do
            if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
        end
    end

    for _, region in ipairs({frame:GetRegions()}) do
        if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
    end
end

local function SkinReadyCheckButton(button, sr, sg, sb, bgr, bgg, bgb, bga)
    if not button then return end
    
    -- Hide default button textures (aggressive)
    if button.Left then button.Left:SetAlpha(0) end
    if button.Right then button.Right:SetAlpha(0) end
    if button.Middle then button.Middle:SetAlpha(0) end
    if button.NineSlice then button.NineSlice:SetAlpha(0) end
    for _, region in ipairs({button:GetRegions()}) do
        if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
             region:SetAlpha(0)
        end
    end

    if not button.guiBackdrop then
        button.guiBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.guiBackdrop:SetAllPoints()
        button.guiBackdrop:SetFrameLevel(button:GetFrameLevel())
        button.guiBackdrop:EnableMouse(false)
        button.guiBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
    end

    local btnBgr = math.min(bgr + 0.07, 1)
    local btnBgg = math.min(bgg + 0.07, 1)
    local btnBgb = math.min(bgb + 0.07, 1)
    
    button.guiBackdrop:SetBackdropColor(btnBgr, btnBgg, btnBgb, bga)
    button.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, 1)

    button:HookScript("OnEnter", function(self)
        self.guiBackdrop:SetBackdropColor(math.min(btnBgr+0.1, 1), math.min(btnBgg+0.1, 1), math.min(btnBgb+0.1, 1), bga)
    end)
    button:HookScript("OnLeave", function(self)
        self.guiBackdrop:SetBackdropColor(btnBgr, btnBgg, btnBgb, bga)
    end)

    local text = button:GetFontString()
    if text then
        text:SetFont(GetFontPath(), 12, "OUTLINE")
        text:SetTextColor(0.9, 0.9, 0.9, 1)
    end
end

function Styling:SkinReadyCheck()
    local db = GetDB()
    if not db or not db.skinReadyCheck then return end

    local frame = _G.ReadyCheckFrame
    local listenerFrame = _G.ReadyCheckListenerFrame
    if not frame or frame.guiSkinned then return end

    local sr, sg, sb, sa = ns.GetAccentColor()
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
    
    -- Custom Background Logic
    if db.readyCheck and db.readyCheck.disableThemeColorBackground then
        local c = db.readyCheck.customBackgroundColor
        if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
    else
        -- Theme Background if enabled generally? Or just dark?
        bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    end
    
    -- Custom Font Logic (Title + Text)
    local titleR, titleG, titleB, titleA = sr, sg, sb, 1
    local textR, textG, textB, textA = 0.9, 0.9, 0.9, 1
    
    if db.readyCheck and db.readyCheck.disableThemeColorFont then
        local c = db.readyCheck.customFontColor
        if c then 
            titleR, titleG, titleB, titleA = c[1], c[2], c[3], c[4] 
            textR, textG, textB, textA = c[1], c[2], c[3], c[4] -- Apply to both?
        end
    end

    HideBlizzardReadyCheckDecorations()

    local targetFrame = listenerFrame or frame
    
    if not frame.guiBackdrop then
        frame.guiBackdrop = CreateFrame("Frame", nil, targetFrame, "BackdropTemplate")
        frame.guiBackdrop:SetAllPoints()
        frame.guiBackdrop:SetFrameLevel(targetFrame:GetFrameLevel())
        frame.guiBackdrop:EnableMouse(false)
        frame.guiBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
    end
    frame.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    frame.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)

    -- Skin buttons
    SkinReadyCheckButton(_G.ReadyCheckFrameYesButton, sr, sg, sb, bgr, bgg, bgb, bga)
    if _G.ReadyCheckFrameYesButton then
        _G.ReadyCheckFrameYesButton:ClearAllPoints()
        _G.ReadyCheckFrameYesButton:SetPoint("BOTTOMRIGHT", targetFrame, "BOTTOM", -5, 12)
    end

    SkinReadyCheckButton(_G.ReadyCheckFrameNoButton, sr, sg, sb, bgr, bgg, bgb, bga)
    if _G.ReadyCheckFrameNoButton then
        _G.ReadyCheckFrameNoButton:ClearAllPoints()
        _G.ReadyCheckFrameNoButton:SetPoint("BOTTOMLEFT", targetFrame, "BOTTOM", 5, 12)
    end

    -- Text
    local text = _G.ReadyCheckFrameText
    if text then
        text:ClearAllPoints()
        text:SetPoint("TOP", targetFrame, "TOP", 0, -30)
        text:SetFont(GetFontPath(), 12, "OUTLINE")
        text:SetTextColor(textR, textG, textB, textA)
    end

    -- Custom Title
    if not frame.guiTitle then
        frame.guiTitle = targetFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.guiTitle:SetPoint("TOP", targetFrame, "TOP", 0, -8)
        frame.guiTitle:SetFont(GetFontPath(), 13, "OUTLINE")
    end
    frame.guiTitle:SetText("Ready Check")
    frame.guiTitle:SetTextColor(titleR, titleG, titleB, titleA)

    -- Re-hide and restore position on show
    frame:HookScript("OnShow", function(self)
        HideBlizzardReadyCheckDecorations()
        local pos = Styling:GetReadyCheckPosition()
        if pos then
            self:ClearAllPoints()
            self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        end
    end)

    -- Move logic
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        -- Only allow moving if our mover is active OR if user initiated drag via mover overlay
        -- Actually, Blizzard frame isn't draggable by default, so we can just let it be movable via our Mover
        -- But `gui_readycheck.lua` had logic to drag the frame itself if unlocked?
        -- Let's stick to the Mover Overlay approach for consistency with user request "Toggle Mover"
    end)
    
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("ReadyCheck", nil, function(frame, enabled, force) Styling:ToggleReadyCheckMover(force) end, "Ready Check")
    end
    
    frame.guiSkinned = true
end

function Styling:RefreshReadyCheck()
    local frame = _G.ReadyCheckFrame
    if not frame or not frame.guiSkinned then return end

    local sr, sg, sb, sa = ns.GetAccentColor()
    local bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    
    local db = GetDB()
    if db and db.readyCheck and db.readyCheck.disableThemeColorBackground then
        local c = db.readyCheck.customBackgroundColor
        if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
    end

    if frame.guiBackdrop then
        frame.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        frame.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end
    
    -- Refresh buttons
    for _, btn in ipairs({_G.ReadyCheckFrameYesButton, _G.ReadyCheckFrameNoButton}) do
        if btn and btn.guiBackdrop then
            local btnBgr = math.min(bgr + 0.07, 1)
            local btnBgg = math.min(bgg + 0.07, 1)
            local btnBgb = math.min(bgb + 0.07, 1)
            btn.guiBackdrop:SetBackdropColor(btnBgr, btnBgg, btnBgb, bga)
            btn.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, 1)
        end
    end
    
    -- Refresh Title
    local titleR, titleG, titleB, titleA = sr, sg, sb, 1
    if db and db.readyCheck and db.readyCheck.disableThemeColorFont then
        local c = db.readyCheck.customFontColor
        if c then titleR, titleG, titleB, titleA = c[1], c[2], c[3], c[4] end
    end
    if frame.guiTitle then frame.guiTitle:SetTextColor(titleR, titleG, titleB, titleA) end

    -- Existing refresh logic

end

-------------------------------------------------------------------------------
-- KEYSTONE SKINNING (Port from GravityUI/design/gui_keystone.lua)
-------------------------------------------------------------------------------

local function SkinKeystone_CreateguiBackdrop(frame, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not frame.guiBackdrop then
        frame.guiBackdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.guiBackdrop:SetAllPoints()
        frame.guiBackdrop:SetFrameLevel(frame:GetFrameLevel())
        frame.guiBackdrop:EnableMouse(false)
        frame.guiBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
    end
    frame.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    frame.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
end

local function SkinKeystone_StyleButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button then return end

    if not button.guiBackdrop then
        button.guiBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.guiBackdrop:SetAllPoints()
        button.guiBackdrop:SetFrameLevel(button:GetFrameLevel())
        button.guiBackdrop:EnableMouse(false)
        button.guiBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
    end

    local btnBgR, btnBgG, btnBgB = math.min(bgr + 0.07, 1), math.min(bgg + 0.07, 1), math.min(bgb + 0.07, 1)
    button.guiBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)

    -- Hide default textures
    if button.Left then button.Left:SetAlpha(0) end
    if button.Right then button.Right:SetAlpha(0) end
    if button.Middle then button.Middle:SetAlpha(0) end
    if button.LeftSeparator then button.LeftSeparator:SetAlpha(0) end
    if button.RightSeparator then button.RightSeparator:SetAlpha(0) end

    -- Hide highlight/pushed
    local highlight = button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) end
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetAlpha(0) end

    -- Style text
    local text = button:GetFontString()
    if text then
        text:SetFont(GetFontPath(), 12, "OUTLINE")
        text:SetTextColor(0.9, 0.9, 0.9, 1)
    end

    button.guiSkinColor = { sr, sg, sb, sa }

    button:HookScript("OnEnter", function(self)
        if self.guiBackdrop and self.guiSkinColor then
            local r, g, b, a = unpack(self.guiSkinColor)
            self.guiBackdrop:SetBackdropBorderColor(math.min(r * 1.3, 1), math.min(g * 1.3, 1), math.min(b * 1.3, 1), a)
        end
    end)
    button:HookScript("OnLeave", function(self)
        if self.guiBackdrop and self.guiSkinColor then
            self.guiBackdrop:SetBackdropBorderColor(unpack(self.guiSkinColor))
        end
    end)
end

local function SkinKeystone_StyleCloseButton(button)
    if not button then return end
    if button.Border then button.Border:SetAlpha(0) end
end

local function SkinKeystone_StyleSlot(slot, sr, sg, sb, sa)
    if not slot then return end
    if not slot.guiBorder then
        slot.guiBorder = CreateFrame("Frame", nil, slot, "BackdropTemplate")
        slot.guiBorder:SetPoint("TOPLEFT", -4, 4)
        slot.guiBorder:SetPoint("BOTTOMRIGHT", 4, -4)
        slot.guiBorder:SetFrameLevel(slot:GetFrameLevel() - 1)
        slot.guiBorder:EnableMouse(false)
        slot.guiBorder:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        slot.guiBorder:SetBackdropColor(0, 0, 0, 0.5)
        slot.guiBorder:SetBackdropBorderColor(sr, sg, sb, sa)
    end
end

local function SkinKeystone_HideDecorations(f)
    local region = f:GetRegions()
    if region then region:SetAlpha(0) end
    if f.InstructionBackground then f.InstructionBackground:SetAlpha(0) end
    if f.KeystoneSlotGlow then f.KeystoneSlotGlow:Hide() end
    if f.SlotBG then f.SlotBG:Hide() end
    if f.KeystoneFrame then f.KeystoneFrame:Hide() end
    if f.Divider then f.Divider:Hide() end
end

function Styling:SkinKeystone()
    local db = GetDB()
    if not db or not db.keystone or not db.keystone.enabled then return end

    local keystoneFrame = _G.ChallengesKeystoneFrame
    if not keystoneFrame or keystoneFrame.guiSkinned then return end

    local sr, sg, sb, sa = ns.GetAccentColor()
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
    
    if db.keystone.disableThemeColorBackground then
        local c = db.keystone.customBackgroundColor
        if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
    else
        bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    end
    
    local titleR, titleG, titleB, titleA = sr, sg, sb, sa
    local textR, textG, textB, textA = 0.9, 0.9, 0.9, 1
    
    if db.keystone.disableThemeColorFont then
        local c = db.keystone.customFontColor
        if c then 
            titleR, titleG, titleB, titleA = c[1], c[2], c[3], c[4]
            textR, textG, textB, textA = c[1], c[2], c[3], c[4]
        end
    end

    SkinKeystone_CreateguiBackdrop(keystoneFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)

    hooksecurefunc(keystoneFrame, "Reset", SkinKeystone_HideDecorations)
    keystoneFrame:HookScript("OnShow", SkinKeystone_HideDecorations)

    local fontPath = GetFontPath()

    if keystoneFrame.DungeonName then
        keystoneFrame.DungeonName:SetFont(fontPath, 22, "OUTLINE")
        keystoneFrame.DungeonName:SetTextColor(titleR, titleG, titleB, titleA)
    end
    if keystoneFrame.TimeLimit then
        keystoneFrame.TimeLimit:SetFont(fontPath, 16, "OUTLINE")
        -- Keep TimeLimit dim unless overridden? 
        -- User asked for Font Color override. Usually implies main text.
        -- Let's apply it if custom. Otherwise default matches standard styling (0.6)
        if db.keystone.disableThemeColorFont then
             keystoneFrame.TimeLimit:SetTextColor(textR, textG, textB, textA)
        else
             keystoneFrame.TimeLimit:SetTextColor(0.6, 0.6, 0.6, 1)
        end
    end
    if keystoneFrame.Instructions then
        keystoneFrame.Instructions:SetFont(fontPath, 11, "OUTLINE")
        keystoneFrame.Instructions:SetTextColor(0.6, 0.6, 0.6, 1)
    end

    SkinKeystone_StyleButton(keystoneFrame.StartButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    SkinKeystone_StyleCloseButton(keystoneFrame.CloseButton)
    SkinKeystone_StyleSlot(keystoneFrame.KeystoneSlot, sr, sg, sb, sa)

    keystoneFrame.guiSkinColor = { sr, sg, sb, sa }

    hooksecurefunc(keystoneFrame, "OnKeystoneSlotted", function(f)
        local r, g, b, a = unpack(f.guiSkinColor or { ns.GetAccentColor() })
        for i = 1, 4 do
            local affix = f["Affix" .. i]
            if affix and affix.Portrait then
                if not affix.guiBorder then
                    affix.guiBorder = affix:CreateTexture(nil, "OVERLAY")
                    affix.guiBorder:SetPoint("TOPLEFT", affix.Portrait, -1, 1)
                    affix.guiBorder:SetPoint("BOTTOMRIGHT", affix.Portrait, 1, -1)
                    affix.guiBorder:SetColorTexture(r, g, b, a)
                    affix.guiBorder:SetDrawLayer("OVERLAY", -1)
                end
            end
        end
    end)

    keystoneFrame.guiSkinned = true
end

-------------------------------------------------------------------------------
-- POWER BAR (Port from GravityUI/design/gui_powerbaralt.lua)
-------------------------------------------------------------------------------

local altPowerBar = nil
local powerBarMover = nil

function Styling:SavePowerBarPosition(point, relPoint, x, y)
    local db = GetDB()
    if db then
        db.powerBar.position = { point = point, relPoint = relPoint, x = x, y = y }
    end
end

function Styling:GetPowerBarPosition()
    local db = GetDB()
    return db and db.powerBar.position
end

function Styling:ResetPowerBarPosition()
    local db = GetDB()
    if db then db.powerBar.position = nil end
    if altPowerBar then
        altPowerBar:ClearAllPoints()
        altPowerBar:SetPoint("TOP", UIParent, "TOP", 0, -100)
    end
    if powerBarMover then
        powerBarMover:ClearAllPoints()
        powerBarMover:SetPoint("CENTER", altPowerBar, "CENTER")
    end
end

local function UpdateAltPowerBar(self)
    -- Simplified version for TWW
    local barInfo = GetUnitPowerBarInfo("player")
    if barInfo then
        -- Enforce Theme Color on every update
        local sr, sg, sb, sa = ns.GetAccentColor()
        self:SetStatusBarColor(sr, sg, sb)
        if self.backdrop then
             self.backdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        end

        local powerName, powerTooltip = GetUnitPowerBarStrings("player")
        local power = UnitPower("player", Enum.PowerType.Alternate or 10)
        local maxPower = UnitPowerMax("player", Enum.PowerType.Alternate or 10)
        
        local perc = 0
        local isSecret = false
        if maxPower and maxPower > 0 then
            -- Use pcall to avoid "arithmetic on a secret value" errors
            -- If this fails, 'power' is a Secret Value (protected)
            local success, result = pcall(function() return math.floor((power or 0) / maxPower * 100) end)
            if success then
                perc = result
            else
                isSecret = true
            end
        end

        self.powerName = powerName
        self.powerTooltip = powerTooltip
        
        -- Safe updates for MinMax/Value
        pcall(function() self:SetMinMaxValues(barInfo.minPower or 0, maxPower or 0) end)
        pcall(function() self:SetValue(power or 0) end)

        if isSecret then
             -- Fallback for Secret Values: Use SetFormattedText to let C handle the secret number display
             -- We cannot calculate percentage in Lua, so we show Absolute Values
             local safe = pcall(function() 
                 self.text:SetFormattedText("%s: %d / %d", powerName or "Power", power or 0, maxPower or 0)
             end)
             if not safe and powerName then
                 self.text:SetText(powerName) 
             end
        else
             if powerName then
                 self.text:SetText(string.format("%s: %d%%", powerName, perc))
             else
                 self.text:SetText(string.format("%d%%", perc))
             end
        end
        self:Show()
    else
        self:Hide()
    end
end

local function CreateAltPowerBarMover()
    if powerBarMover or not altPowerBar then return end
    
    local sr, sg, sb, sa = ns.GetAccentColor()
    
    powerBarMover = CreateFrame("Frame", "GravityUI_AltPowerBarMover", UIParent, "BackdropTemplate")
    powerBarMover:SetSize(altPowerBar:GetWidth() + 4, altPowerBar:GetHeight() + 4)
    powerBarMover:SetPoint("CENTER", altPowerBar, "CENTER")
    powerBarMover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    powerBarMover:SetBackdropColor(sr, sg, sb, 0.3)
    powerBarMover:SetBackdropBorderColor(sr, sg, sb, 1)
    powerBarMover:EnableMouse(true)
    powerBarMover:SetMovable(true)
    powerBarMover:RegisterForDrag("LeftButton")
    powerBarMover:SetFrameStrata("FULLSCREEN_DIALOG")
    powerBarMover:Hide()

    powerBarMover.text = powerBarMover:CreateFontString(nil, "OVERLAY")
    powerBarMover.text:SetPoint("CENTER")
    powerBarMover.text:SetFont(GetFontPath(), 10, "OUTLINE")
    powerBarMover.text:SetText("Encounter Power Bar")
    
    powerBarMover:SetScript("OnDragStart", function() altPowerBar:StartMoving() end)
    powerBarMover:SetScript("OnDragStop", function(self)
        altPowerBar:StopMovingOrSizing()
        local point, _, relPoint, x, y = altPowerBar:GetPoint()
        Styling:SavePowerBarPosition(point, relPoint, x, y)
        self:ClearAllPoints()
        self:SetPoint("CENTER", altPowerBar, "CENTER")
    end)
end

function Styling:TogglePowerBarMover(forceState)
    if not altPowerBar then return end
    CreateAltPowerBarMover()

    local shouldShow = not powerBarMover:IsShown()
    if forceState ~= nil then shouldShow = forceState end

    if shouldShow then
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(powerBarMover, forceState == true)
        end
        powerBarMover:Show()
        altPowerBar:Show()
        if not altPowerBar.powerName then
            altPowerBar.text:SetText("Encounter Power Bar")
            altPowerBar:SetMinMaxValues(0, 100)
            altPowerBar:SetValue(50)
        end
    else
        powerBarMover:Hide()
        UpdateAltPowerBar(altPowerBar)
    end
end

local blizzardBarHooked = false
function Styling:SkinPowerBar()
    local db = GetDB()
    if not db or not db.powerBar or not db.powerBar.enabled then return end
    if altPowerBar then return end

    -- Hide Blizzard
    local bBar = _G.PlayerPowerBarAlt
    if bBar then
        bBar:UnregisterAllEvents()
        bBar:Hide()
        bBar:SetAlpha(0)
    end
    if not blizzardBarHooked and _G.UnitPowerBarAlt_SetUp then
        hooksecurefunc("UnitPowerBarAlt_SetUp", function(self)
            if InCombatLockdown() then return end
            if self == _G.PlayerPowerBarAlt and GetDB().powerBar.enabled then
                self:UnregisterAllEvents()
                self:Hide()
                self:SetAlpha(0)
            end
        end)
        blizzardBarHooked = true
    end

    -- Create bar
    local sr, sg, sb, sa = ns.GetAccentColor()
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    altPowerBar = CreateFrame("StatusBar", "GravityUI_AltPowerBar", UIParent)
    altPowerBar:SetSize(250, 20)
    
    local pos = Styling:GetPowerBarPosition()
    if pos and pos.point then
        altPowerBar:SetPoint(pos.point, UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or 0)
    else
        altPowerBar:SetPoint("TOP", UIParent, "TOP", 0, -100)
    end
    
    altPowerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    altPowerBar:SetStatusBarColor(sr, sg, sb)
    altPowerBar:SetMovable(true)
    altPowerBar:SetClampedToScreen(true)

    altPowerBar.backdrop = CreateFrame("Frame", nil, altPowerBar, "BackdropTemplate")
    altPowerBar.backdrop:SetPoint("TOPLEFT", -2, 2)
    altPowerBar.backdrop:SetPoint("BOTTOMRIGHT", 2, -2)
    altPowerBar.backdrop:SetFrameLevel(altPowerBar:GetFrameLevel() - 1)
    altPowerBar.backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    altPowerBar.backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    altPowerBar.backdrop:SetBackdropBorderColor(sr, sg, sb, sa)

    altPowerBar.text = altPowerBar:CreateFontString(nil, "OVERLAY")
    altPowerBar.text:SetPoint("CENTER")
    altPowerBar.text:SetFont(GetFontPath(), 11, "OUTLINE")

    altPowerBar:EnableMouse(true)
    altPowerBar:SetScript("OnEnter", function(self)
        if self.powerName then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(self.powerName, 1, 1, 1)
            GameTooltip:AddLine(self.powerTooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    altPowerBar:SetScript("OnLeave", function() GameTooltip:Hide() end)

    altPowerBar:RegisterEvent("UNIT_POWER_UPDATE")
    altPowerBar:RegisterEvent("UNIT_POWER_BAR_SHOW")
    altPowerBar:RegisterEvent("UNIT_POWER_BAR_HIDE")
    altPowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
    altPowerBar:SetScript("OnEvent", function(self, event, unit, pType)
        if event == "UNIT_POWER_UPDATE" then
            if unit == "player" and pType == "ALTERNATE" then UpdateAltPowerBar(self) end
        else
            UpdateAltPowerBar(self)
        end
    end)

    UpdateAltPowerBar(altPowerBar)
    
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("PowerBarAlt", nil, function(frame, enabled, force) Styling:TogglePowerBarMover(force) end, "Encounter Power Bar")
    end
end

function Styling:RefreshPowerBar()
    if not altPowerBar then return end
    -- Trigger an update which now enforces color
    UpdateAltPowerBar(altPowerBar)
    
    -- Also update mover text/backdrop if visible
    if powerBarMover then
        local sr, sg, sb, sa = ns.GetAccentColor()
        powerBarMover:SetBackdropColor(sr, sg, sb, 0.3)
        powerBarMover:SetBackdropBorderColor(sr, sg, sb, 1)
    end
end

-------------------------------------------------------------------------------
-- WIDGET POWER BAR CONTAINER (UIWidgetPowerBarContainerFrame)
-------------------------------------------------------------------------------

local widgetPowerBarMover = nil

function Styling:SaveWidgetPowerBarPosition(point, relPoint, x, y)
    local db = GetDB()
    if db then
        db.widgetPowerBar = db.widgetPowerBar or {}
        db.widgetPowerBar.position = { point = point, relPoint = relPoint, x = x, y = y }
    end
end

function Styling:GetWidgetPowerBarPosition()
    local db = GetDB()
    return db and db.widgetPowerBar and db.widgetPowerBar.position
end

function Styling:ResetWidgetPowerBarPosition()
    local db = GetDB()
    if db and db.widgetPowerBar then db.widgetPowerBar.position = nil end
    local container = _G.UIWidgetPowerBarContainerFrame
    if container then
        container:ClearAllPoints()
        container:SetPoint("TOP", UIParent, "TOP", 0, -200)
    end
    if widgetPowerBarMover then
        widgetPowerBarMover:ClearAllPoints()
        widgetPowerBarMover:SetPoint("CENTER", container, "CENTER")
    end
end

local function CreateWidgetPowerBarMover()
    if widgetPowerBarMover then return end
    
    local container = _G.UIWidgetPowerBarContainerFrame
    if not container then return end

    local sr, sg, sb, sa = ns.GetAccentColor()
    
    widgetPowerBarMover = CreateFrame("Frame", "GravityUI_WidgetPowerBarMover", UIParent, "BackdropTemplate")
    widgetPowerBarMover:SetSize(math.max(container:GetWidth() or 200, 200), math.max(container:GetHeight() or 40, 40))
    widgetPowerBarMover:SetPoint("CENTER", container, "CENTER")
    widgetPowerBarMover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    widgetPowerBarMover:SetBackdropColor(sr, sg, sb, 0.3)
    widgetPowerBarMover:SetBackdropBorderColor(sr, sg, sb, 1)
    widgetPowerBarMover:EnableMouse(true)
    widgetPowerBarMover:SetMovable(true)
    widgetPowerBarMover:RegisterForDrag("LeftButton")
    widgetPowerBarMover:SetFrameStrata("FULLSCREEN_DIALOG")
    widgetPowerBarMover:Hide()

    widgetPowerBarMover.text = widgetPowerBarMover:CreateFontString(nil, "OVERLAY")
    widgetPowerBarMover.text:SetPoint("CENTER")
    widgetPowerBarMover.text:SetFont(GetFontPath(), 10, "OUTLINE")
    widgetPowerBarMover.text:SetText("Widget Power Bar")
    
    widgetPowerBarMover:SetScript("OnDragStart", function() container:StartMoving() end)
    widgetPowerBarMover:SetScript("OnDragStop", function(self)
        container:StopMovingOrSizing()
        local point, _, relPoint, x, y = container:GetPoint()
        Styling:SaveWidgetPowerBarPosition(point, relPoint, x, y)
        self:ClearAllPoints()
        self:SetPoint("CENTER", container, "CENTER")
    end)
    
    container:SetMovable(true)
    container:SetClampedToScreen(true)
end

function Styling:ToggleWidgetPowerBarMover(forceState)
    CreateWidgetPowerBarMover()
    if not widgetPowerBarMover then return end

    local container = _G.UIWidgetPowerBarContainerFrame
    local shouldShow = not widgetPowerBarMover:IsShown()
    if forceState ~= nil then shouldShow = forceState end

    if shouldShow then
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(widgetPowerBarMover, forceState == true)
        end
        widgetPowerBarMover:SetSize(math.max(container:GetWidth() or 200, 200), math.max(container:GetHeight() or 40, 40))
        widgetPowerBarMover:Show()
    else
        widgetPowerBarMover:Hide()
    end
end

function Styling:InitWidgetPowerBar()
    local container = _G.UIWidgetPowerBarContainerFrame
    if not container then return end

    local pos = Styling:GetWidgetPowerBarPosition()
    if pos and pos.point then
        container:ClearAllPoints()
        container:SetPoint(pos.point, UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or 0)
    end

    hooksecurefunc(container, "SetPoint", function(self, point, relativeTo)
        if self._isSettingPosition then return end
        
        local currentPos = Styling:GetWidgetPowerBarPosition()
        if currentPos and currentPos.point then
            if point ~= currentPos.point or relativeTo ~= UIParent then
                self._isSettingPosition = true
                self:ClearAllPoints()
                self:SetPoint(currentPos.point, UIParent, currentPos.relPoint or "CENTER", currentPos.x or 0, currentPos.y or 0)
                self._isSettingPosition = false
            end
        end
    end)

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("WidgetPowerBar", nil, function(frame, enabled, force) Styling:ToggleWidgetPowerBarMover(force) end, "Widget Power Bar")
    end

    local function GetActivePreyPercent()
        local questID = C_QuestLog and C_QuestLog.GetActivePreyQuest and C_QuestLog.GetActivePreyQuest()
        if not questID or questID == 0 then return nil, nil, false end
        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questID)
        
        local titleInfo = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
        local questTitle = type(titleInfo) == "table" and titleInfo.title or titleInfo

        local isWidgetShown = false
        
        if isCompleted then return 100, questTitle, true end

        if GetQuestProgressBarPercent then
            local p = GetQuestProgressBarPercent(questID)
            if p and p > 0 then return math.floor(p), questTitle, true end
        end

        -- Try widget
        if C_UIWidgetManager and C_UIWidgetManager.GetAllWidgetsBySetID and C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo then
            local sets = {C_UIWidgetManager.GetTopCenterWidgetSetID(), C_UIWidgetManager.GetObjectiveTrackerWidgetSetID(), C_UIWidgetManager.GetBelowMinimapWidgetSetID(), C_UIWidgetManager.GetPowerBarWidgetSetID()}
            for _, setID in ipairs(sets) do
                if setID then
                    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setID)
                    if widgets then
                        for _, w in ipairs(widgets) do
                            if w.widgetType == 31 then -- PreyHuntProgress
                                local info = C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo(w.widgetID)
                                if info and info.shownState == 1 then
                                    isWidgetShown = true
                                    if info.progressPercentage then return info.progressPercentage, questTitle, true end
                                    if info.progressPercent then return info.progressPercent, questTitle, true end
                                    if info.tooltip then
                                        local pctText = info.tooltip:match("(%d+)%%")
                                        if pctText then return tonumber(pctText), questTitle, true end
                                    end
                                    
                                    -- Fallback based on preydator's progressState mapping
                                    if info.progressState then
                                        if info.progressState == 0 then return 0, questTitle, true end
                                        if info.progressState == 1 then return 33, questTitle, true end
                                        if info.progressState == 2 then return 66, questTitle, true end
                                        if info.progressState == 3 then return 100, questTitle, true end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Try objective percent
        if C_QuestLog.GetQuestObjectives then
            local objectives = C_QuestLog.GetQuestObjectives(questID)
            if objectives and #objectives > 0 then
                local totalF = 0
                local totalR = 0
                local anyNumeric = false
                
                for _, obj in ipairs(objectives) do
                    local f = tonumber(obj.numFulfilled or obj.fulfilled)
                    local r = tonumber(obj.numRequired or obj.required)
                    
                    if f ~= nil and r == nil and obj.finished ~= nil then
                        r = 1
                        f = obj.finished and 1 or math.max(0, f)
                    end
                    
                    if f and r and r > 0 then
                        anyNumeric = true
                        totalF = totalF + math.max(0, f)
                        totalR = totalR + math.max(0, r)
                    else
                        local text = obj.text
                        if type(text) == "string" and text ~= "" then
                            local ct, mt = text:match("(%d+)%s*/%s*(%d+)")
                            if ct and mt and tonumber(mt) > 0 then
                                anyNumeric = true
                                totalF = totalF + math.max(0, tonumber(ct))
                                totalR = totalR + math.max(0, tonumber(mt))
                            else
                                local pctText = text:match("(%d+)%s*%%")
                                if pctText then
                                    local parsedPct = tonumber(pctText)
                                    if parsedPct then return parsedPct, questTitle, isWidgetShown end
                                end
                            end
                        end
                    end
                end
                
                if anyNumeric and totalR > 0 then
                    return math.floor((totalF / totalR) * 100), questTitle, isWidgetShown
                end
            end
        end
        
        return nil, questTitle, isWidgetShown
    end

    local function EnsurePreyTracker()
        if ns.PreyTrackerBar then return end
        
        local bar = CreateFrame("StatusBar", "GravityUIPreyTracker", UIParent)
        bar:SetSize(120, 16)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(0.85, 0.1, 0.1)
        
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.6)
        
        local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        border:SetBackdropBorderColor(0.8, 0.1, 0.1, 0.85)
        
        local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("BOTTOM", bar, "TOP", 0, 2)
        title:SetText("Prey")
        title:SetTextColor(1, 0.82, 0, 1)
        bar.title = title
        
        local valText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valText:SetPoint("CENTER", bar, "CENTER", 0, 0)
        bar.valText = valText
        
        local container = _G.UIWidgetPowerBarContainerFrame
        bar:SetPoint("TOP", container or UIParent, "BOTTOM", 0, -10)
        
        bar:Hide()
        ns.PreyTrackerBar = bar
    end
    
    SLASH_GRAVITYPREYDEBUG1 = "/gravitydebugprey"
    SlashCmdList["GRAVITYPREYDEBUG"] = function()
        local questID = C_QuestLog and C_QuestLog.GetActivePreyQuest and C_QuestLog.GetActivePreyQuest()
        print("--- Gravity Prey Debug ---")
        print("Active Prey QuestID:", questID)
        
        if not questID or questID == 0 then return end
        
        if GetQuestProgressBarPercent then
            print("GetQuestProgressBarPercent:", GetQuestProgressBarPercent(questID))
        end
        
        if C_QuestLog.GetQuestObjectives then
            local obj = C_QuestLog.GetQuestObjectives(questID)
            if obj then
                for i, o in ipairs(obj) do
                    print("Obj["..i.."] type:", o.type, "text:", o.text, "numF:", o.numFulfilled, "numR:", o.numRequired, "fin:", o.finished)
                end
            else
                print("No Quest Objectives Array")
            end
        end
        
        if C_UIWidgetManager and C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo then
            local sets = {C_UIWidgetManager.GetTopCenterWidgetSetID(), C_UIWidgetManager.GetObjectiveTrackerWidgetSetID(), C_UIWidgetManager.GetBelowMinimapWidgetSetID(), C_UIWidgetManager.GetPowerBarWidgetSetID()}
            for _, setID in ipairs(sets) do
                if setID then
                    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setID)
                    if widgets then
                        for _, w in ipairs(widgets) do
                            if w.widgetType == 31 then
                                local info = C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo(w.widgetID)
                                if info then
                                    print("Widget Found ID:", w.widgetID, "shown:", info.shownState)
                                    for k, v in pairs(info) do
                                        print("  ", k, "=", tostring(v))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function UpdatePreyTracker()
        local db = ns.GetDB()
        if not (db and db.uiimprovements and db.uiimprovements.showWidgetPowerValue) then
            if ns.PreyTrackerBar then ns.PreyTrackerBar:Hide() end
            return
        end
        
        EnsurePreyTracker()
        
        local pct, title, isWidgetShown = GetActivePreyPercent()
        
        if pct and isWidgetShown then
            if title then
                local cleanTitle = title:match("^%s*[Pp]rey:%s*(.-)%s*%(") or title:match("^%s*[Pp]rey:%s*(.-)%s*$") or title
                ns.PreyTrackerBar.title:SetText(cleanTitle)
            end
            
            ns.PreyTrackerBar:SetMinMaxValues(0, 100)
            ns.PreyTrackerBar:SetValue(pct)
            ns.PreyTrackerBar.valText:SetText(pct .. "%")
            
            local container = _G.UIWidgetPowerBarContainerFrame
            if container and container:IsShown() then
                ns.PreyTrackerBar:ClearAllPoints()
                ns.PreyTrackerBar:SetPoint("TOP", container, "BOTTOM", 0, -10)
                ns.PreyTrackerBar:Show()
            else
                ns.PreyTrackerBar:Hide()
            end
        else
            ns.PreyTrackerBar:Hide()
        end
    end

    function ns.UpdateWidgetPowerValueVisibility(enabled)
        if enabled then
            if not ns.widgetPowerTicker then
                ns.widgetPowerTicker = C_Timer.NewTicker(0.5, UpdatePreyTracker)
            end
            UpdatePreyTracker()
        else
            if ns.PreyTrackerBar then ns.PreyTrackerBar:Hide() end
            if ns.widgetPowerTicker then
                ns.widgetPowerTicker:Cancel()
                ns.widgetPowerTicker = nil
            end
        end
    end

    local db = ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.showWidgetPowerValue then
        ns.UpdateWidgetPowerValueVisibility(true)
    end
end

-------------------------------------------------------------------------------
-- WIDGET BELOW MINIMAP CONTAINER (UIWidgetBelowMinimapContainerFrame)
-------------------------------------------------------------------------------

local widgetBelowMinimapMover = nil

function Styling:SaveWidgetBelowMinimapPosition(point, relPoint, x, y)
    local db = GetDB()
    if db then
        db.widgetBelowMinimap = db.widgetBelowMinimap or {}
        db.widgetBelowMinimap.position = { point = point, relPoint = relPoint, x = x, y = y }
    end
end

function Styling:GetWidgetBelowMinimapPosition()
    local db = GetDB()
    return db and db.widgetBelowMinimap and db.widgetBelowMinimap.position
end

function Styling:ResetWidgetBelowMinimapPosition()
    local db = GetDB()
    if db and db.widgetBelowMinimap then db.widgetBelowMinimap.position = nil end
    local container = _G.UIWidgetBelowMinimapContainerFrame
    if container then
        container:ClearAllPoints()
        container:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -200, -350)
    end
    if widgetBelowMinimapMover then
        widgetBelowMinimapMover:ClearAllPoints()
        widgetBelowMinimapMover:SetPoint("CENTER", container, "CENTER")
    end
end

local function CreateWidgetBelowMinimapMover()
    if widgetBelowMinimapMover then return end
    
    local container = _G.UIWidgetBelowMinimapContainerFrame
    if not container then return end

    local sr, sg, sb, sa = ns.GetAccentColor()
    
    widgetBelowMinimapMover = CreateFrame("Frame", "GravityUI_WidgetBelowMinimapMover", UIParent, "BackdropTemplate")
    widgetBelowMinimapMover:SetSize(math.max(container:GetWidth() or 200, 200), math.max(container:GetHeight() or 40, 40))
    widgetBelowMinimapMover:SetPoint("CENTER", container, "CENTER")
    widgetBelowMinimapMover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    widgetBelowMinimapMover:SetBackdropColor(sr, sg, sb, 0.3)
    widgetBelowMinimapMover:SetBackdropBorderColor(sr, sg, sb, 1)
    widgetBelowMinimapMover:EnableMouse(true)
    widgetBelowMinimapMover:SetMovable(true)
    widgetBelowMinimapMover:RegisterForDrag("LeftButton")
    widgetBelowMinimapMover:SetFrameStrata("FULLSCREEN_DIALOG")
    widgetBelowMinimapMover:Hide()

    widgetBelowMinimapMover.text = widgetBelowMinimapMover:CreateFontString(nil, "OVERLAY")
    widgetBelowMinimapMover.text:SetPoint("CENTER")
    widgetBelowMinimapMover.text:SetFont(GetFontPath(), 10, "OUTLINE")
    widgetBelowMinimapMover.text:SetText("Widget Below Minimap")
    
    widgetBelowMinimapMover:SetScript("OnDragStart", function() container:StartMoving() end)
    widgetBelowMinimapMover:SetScript("OnDragStop", function(self)
        container:StopMovingOrSizing()
        local point, _, relPoint, x, y = container:GetPoint()
        Styling:SaveWidgetBelowMinimapPosition(point, relPoint, x, y)
        self:ClearAllPoints()
        self:SetPoint("CENTER", container, "CENTER")
    end)
    
    container:SetMovable(true)
    container:SetClampedToScreen(true)
end

function Styling:ToggleWidgetBelowMinimapMover(forceState)
    CreateWidgetBelowMinimapMover()
    if not widgetBelowMinimapMover then return end

    local container = _G.UIWidgetBelowMinimapContainerFrame
    local shouldShow = not widgetBelowMinimapMover:IsShown()
    if forceState ~= nil then shouldShow = forceState end

    if shouldShow then
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(widgetBelowMinimapMover, forceState == true)
        end
        widgetBelowMinimapMover:SetSize(math.max(container:GetWidth() or 200, 200), math.max(container:GetHeight() or 40, 40))
        widgetBelowMinimapMover:Show()
    else
        widgetBelowMinimapMover:Hide()
    end
end

function Styling:InitWidgetBelowMinimap()
    local container = _G.UIWidgetBelowMinimapContainerFrame
    if not container then return end

    local pos = Styling:GetWidgetBelowMinimapPosition()
    if pos and pos.point then
        container:ClearAllPoints()
        container:SetPoint(pos.point, UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or 0)
    end

    hooksecurefunc(container, "SetPoint", function(self, point, relativeTo)
        if self._isSettingPosition then return end
        
        local currentPos = Styling:GetWidgetBelowMinimapPosition()
        if currentPos and currentPos.point then
            if point ~= currentPos.point or relativeTo ~= UIParent then
                self._isSettingPosition = true
                self:ClearAllPoints()
                self:SetPoint(currentPos.point, UIParent, currentPos.relPoint or "CENTER", currentPos.x or 0, currentPos.y or 0)
                self._isSettingPosition = false
            end
        end
    end)

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("WidgetBelowMinimap", nil, function(frame, enabled, force) Styling:ToggleWidgetBelowMinimapMover(force) end, "Widget Below Minimap")
    end
end

-------------------------------------------------------------------------------
-- TOP CENTER CONTAINER (UIWidgetTopCenterContainerFrame)
-------------------------------------------------------------------------------

local widgetTopCenterMover = nil

function Styling:SaveWidgetTopCenterPosition(point, relPoint, x, y)
    local db = GetDB()
    if db then
        db.widgetTopCenter = db.widgetTopCenter or {}
        db.widgetTopCenter.position = { point = point, relPoint = relPoint, x = x, y = y }
    end
end

function Styling:GetWidgetTopCenterPosition()
    local db = GetDB()
    return db and db.widgetTopCenter and db.widgetTopCenter.position
end

function Styling:ResetWidgetTopCenterPosition()
    local db = GetDB()
    if db and db.widgetTopCenter then db.widgetTopCenter.position = nil end
    local container = _G.UIWidgetTopCenterContainerFrame
    if container then
        container:ClearAllPoints()
        container:SetPoint("TOP", UIParent, "TOP", 0, -200)
    end
    if widgetTopCenterMover then
        widgetTopCenterMover:ClearAllPoints()
        widgetTopCenterMover:SetPoint("CENTER", container, "CENTER")
    end
end

local function CreateWidgetTopCenterMover()
    if widgetTopCenterMover then return end
    
    local container = _G.UIWidgetTopCenterContainerFrame
    if not container then return end

    local sr, sg, sb, sa = ns.GetAccentColor()
    
    widgetTopCenterMover = CreateFrame("Frame", "GravityUI_WidgetTopCenterMover", UIParent, "BackdropTemplate")
    widgetTopCenterMover:SetSize(math.max(container:GetWidth() or 200, 200), math.max(container:GetHeight() or 40, 40))
    widgetTopCenterMover:SetPoint("CENTER", container, "CENTER")
    widgetTopCenterMover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    widgetTopCenterMover:SetBackdropColor(sr, sg, sb, 0.3)
    widgetTopCenterMover:SetBackdropBorderColor(sr, sg, sb, 1)
    widgetTopCenterMover:EnableMouse(true)
    widgetTopCenterMover:SetMovable(true)
    widgetTopCenterMover:RegisterForDrag("LeftButton")
    widgetTopCenterMover:SetFrameStrata("FULLSCREEN_DIALOG")
    widgetTopCenterMover:Hide()

    widgetTopCenterMover.text = widgetTopCenterMover:CreateFontString(nil, "OVERLAY")
    widgetTopCenterMover.text:SetPoint("CENTER")
    widgetTopCenterMover.text:SetFont(GetFontPath(), 10, "OUTLINE")
    widgetTopCenterMover.text:SetText("Widget Top Center")
    
    widgetTopCenterMover:SetScript("OnDragStart", function() container:StartMoving() end)
    widgetTopCenterMover:SetScript("OnDragStop", function(self)
        container:StopMovingOrSizing()
        local point, _, relPoint, x, y = container:GetPoint()
        Styling:SaveWidgetTopCenterPosition(point, relPoint, x, y)
        self:ClearAllPoints()
        self:SetPoint("CENTER", container, "CENTER")
    end)
    
    container:SetMovable(true)
    container:SetClampedToScreen(true)
end

function Styling:ToggleWidgetTopCenterMover(forceState)
    CreateWidgetTopCenterMover()
    if not widgetTopCenterMover then return end

    local container = _G.UIWidgetTopCenterContainerFrame
    local shouldShow = not widgetTopCenterMover:IsShown()
    if forceState ~= nil then shouldShow = forceState end

    if shouldShow then
        if ns.Movers and ns.Movers.ApplyEditModeStyle then
            ns.Movers:ApplyEditModeStyle(widgetTopCenterMover, forceState == true)
        end
        widgetTopCenterMover:SetSize(math.max(container:GetWidth() or 200, 200), math.max(container:GetHeight() or 40, 40))
        widgetTopCenterMover:Show()
    else
        widgetTopCenterMover:Hide()
    end
end

function Styling:InitWidgetTopCenter()
    local container = _G.UIWidgetTopCenterContainerFrame
    if not container then return end

    local pos = Styling:GetWidgetTopCenterPosition()
    if pos and pos.point then
        container:ClearAllPoints()
        container:SetPoint(pos.point, UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or 0)
    end

    hooksecurefunc(container, "SetPoint", function(self, point, relativeTo)
        if self._isSettingPosition then return end
        
        local currentPos = Styling:GetWidgetTopCenterPosition()
        if currentPos and currentPos.point then
            if point ~= currentPos.point or relativeTo ~= UIParent then
                self._isSettingPosition = true
                self:ClearAllPoints()
                self:SetPoint(currentPos.point, UIParent, currentPos.relPoint or "CENTER", currentPos.x or 0, currentPos.y or 0)
                self._isSettingPosition = false
            end
        end
    end)

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("WidgetTopCenter", nil, function(frame, enabled, force) Styling:ToggleWidgetTopCenterMover(force) end, "Widget Top Center")
    end
end

-------------------------------------------------------------------------------
-- ALERT FRAMES
-------------------------------------------------------------------------------
function Styling:SkinAlertFrames()
    -- TBD: Port skinAlerts
end

-------------------------------------------------------------------------------
-- LOOT WINDOW
-------------------------------------------------------------------------------
function Styling:SkinLoot()
    -- TBD: Port skinLootWindow / skinLootHistory
end

-------------------------------------------------------------------------------
-- REPUTATION / CURRENCY
-------------------------------------------------------------------------------
function Styling:SkinReputationCurrency()
    -- TBD: Port skinCharacterFrame / Inspect
end

-------------------------------------------------------------------------------
-- OBJECTIVE TRACKER
-------------------------------------------------------------------------------
function Styling:SkinObjectiveTracker()
    -- TBD: Port skinObjectiveTracker
end

-------------------------------------------------------------------------------
-- INSTANCE FRAMES
-------------------------------------------------------------------------------
function Styling:SkinInstanceFrames()
    -- TBD: Port skinInstanceFrames
end

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------
function Styling:Initialize()
    self:SkinChatBubbles()
    self:HookGameMenu()
    self:SkinReadyCheck()
    self:SkinStaticPopups()
    self:SkinKeystone()
    self:SkinPowerBar()
    self:InitWidgetPowerBar()
    self:InitWidgetBelowMinimap()
    self:InitWidgetTopCenter()
    self:SkinAlertFrames()
    self:SkinLoot()
    self:SkinReputationCurrency()
    self:SkinObjectiveTracker()
    self:SkinInstanceFrames()
    
    -- Event registration for LoD addons
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, addon)
        if addon == "Blizzard_ChallengesUI" then
            Styling:SkinKeystone()
        end
    end)
end

-- Hook global font update to refresh chat bubbles
-- hooksecurefunc(ns, "UpdateGlobalFont", function()
--     Styling:SkinChatBubbles()
-- end)

function Styling:RefreshKeystone()
    local frame = _G.ChallengesKeystoneFrame
    if not frame or not frame.guiSkinned then return end

    local sr, sg, sb, sa = ns.GetAccentColor()
    local bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    
    local db = GetDB()
    if db and db.keystone and db.keystone.disableThemeColorBackground then
        local c = db.keystone.customBackgroundColor
        if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
    end

    if frame.guiBackdrop then
        frame.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        frame.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end
    
    -- Refresh Start Button
    if frame.StartButton and frame.StartButton.guiBackdrop then
        local btnBgR, btnBgG, btnBgB = math.min(bgr + 0.07, 1), math.min(bgg + 0.07, 1), math.min(bgb + 0.07, 1)
        frame.StartButton.guiBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
        frame.StartButton.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        frame.StartButton.guiSkinColor = { sr, sg, sb, sa }
    end
    
    -- Refresh Title
    local titleR, titleG, titleB, titleA = sr, sg, sb, sa
    if db and db.keystone and db.keystone.disableThemeColorFont then
        local c = db.keystone.customFontColor
        if c then titleR, titleG, titleB, titleA = c[1], c[2], c[3], c[4] end
    end
    if frame.DungeonName then frame.DungeonName:SetTextColor(titleR, titleG, titleB, titleA) end
end

-------------------------------------------------------------------------------
-- STATIC POPUPS (Group Invite, Duel, Resurrect, Trade, etc.)
-------------------------------------------------------------------------------

local staticPopupHooked = false

local function HideStaticPopupDecorations(popup)
    if popup.NineSlice then popup.NineSlice:SetAlpha(0) end
    if popup.Border then popup.Border:SetAlpha(0) end
    if popup.TopTileStreaks then popup.TopTileStreaks:SetAlpha(0) end
    if popup.portrait then popup.portrait:SetAlpha(0) end
    for _, region in ipairs({ popup:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
        end
    end
end

local function SkinStaticPopupButton(button, sr, sg, sb, bgr, bgg, bgb, bga, fontPath)
    if not button then return end
    if button._guiSkinned then
        -- Refresh colors only on theme change
        if button.guiBackdrop then
            local btnBgr = math.min(bgr + 0.09, 1)
            local btnBgg = math.min(bgg + 0.09, 1)
            local btnBgb = math.min(bgb + 0.09, 1)
            button.guiBackdrop:SetBackdropColor(btnBgr, btnBgg, btnBgb, 1)
            button.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, 1)
            button.guiSkinColor = { sr, sg, sb, 1 }
            button.guiBtnBg = { btnBgr, btnBgg, btnBgb }
        end
        return
    end

    -- Hide native Blizzard button art (Left/Right/Middle slices + NineSlice)
    -- Use hooksecurefunc so Blizzard can't re-show them after OnShow resets
    local function HideRegion(region)
        if not region then return end
        region:SetAlpha(0)
        if not region._guiAlphaHooked then
            region._guiAlphaHooked = true
            hooksecurefunc(region, "SetAlpha", function(self, a)
                if self._guiSupressingAlpha then return end
                if a > 0 then
                    self._guiSupressingAlpha = true
                    self:SetAlpha(0)
                    self._guiSupressingAlpha = nil
                end
            end)
        end
    end
    HideRegion(button.Left)
    HideRegion(button.Right)
    HideRegion(button.Middle)
    HideRegion(button.NineSlice)
    HideRegion(button:GetHighlightTexture())
    HideRegion(button:GetPushedTexture())
    -- Also scan all textures as fallback (covers atlas-based buttons in Midnight)
    for _, region in ipairs({ button:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            HideRegion(region)
        end
    end

    -- Custom backdrop at same FrameLevel as the button.
    -- Child frames at the same level render ABOVE parent BACKGROUND textures,
    -- but the parent's OVERLAY layer (where the FontString lives) renders on top.
    -- Using +2 would cover the text — same level is correct.
    button.guiBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
    button.guiBackdrop:SetAllPoints()
    button.guiBackdrop:SetFrameLevel(button:GetFrameLevel())
    button.guiBackdrop:EnableMouse(false)
    button.guiBackdrop:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    local btnBgr = math.min(bgr + 0.09, 1)
    local btnBgg = math.min(bgg + 0.09, 1)
    local btnBgb = math.min(bgb + 0.09, 1)
    button.guiBackdrop:SetBackdropColor(btnBgr, btnBgg, btnBgb, 1)
    button.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, 1)
    button.guiSkinColor = { sr, sg, sb, 1 }
    button.guiBtnBg = { btnBgr, btnBgg, btnBgb }

    button:HookScript("OnEnter", function(self)
        if self.guiBackdrop and self.guiSkinColor and self.guiBtnBg then
            local r, g, b, a = unpack(self.guiSkinColor)
            local br, bg_, bb = unpack(self.guiBtnBg)
            self.guiBackdrop:SetBackdropColor(math.min(br + 0.10, 1), math.min(bg_ + 0.10, 1), math.min(bb + 0.10, 1), 1)
            self.guiBackdrop:SetBackdropBorderColor(math.min(r * 1.35, 1), math.min(g * 1.35, 1), math.min(b * 1.35, 1), a)
        end
    end)
    button:HookScript("OnLeave", function(self)
        if self.guiBackdrop and self.guiSkinColor and self.guiBtnBg then
            self.guiBackdrop:SetBackdropColor(unpack(self.guiBtnBg))
            self.guiBackdrop:SetBackdropBorderColor(unpack(self.guiSkinColor))
        end
    end)

    local text = button:GetFontString()
    if text and fontPath then
        text:SetFont(fontPath, 12, "OUTLINE")
        text:SetTextColor(0.92, 0.92, 0.92, 1)
        text:SetShadowColor(0, 0, 0, 0.8)
        text:SetShadowOffset(1, -1)
    end

    button._guiSkinned = true
end

local function ApplySkinToStaticPopup(popup, db, fontPath)
    if not popup then return end
    if not popup:IsShown() then return end

    local sr, sg, sb, sa = ns.GetAccentColor()
    local bgr, bgg, bgb, bga = ns.GetThemeBgColor()

    if db.disableThemeColorBackground then
        local c = db.customBackgroundColor
        if c then bgr, bgg, bgb, bga = c[1], c[2], c[3], c[4] end
    end

    local brdr, brdg, brdb, brda = sr, sg, sb, sa
    if db.hideBorder then
        brdr, brdg, brdb, brda = 0, 0, 0, 0
    elseif db.disableThemeColorBorder then
        local c = db.customBorderColor
        if c then brdr, brdg, brdb, brda = c[1], c[2], c[3], c[4] end
    end

    local textR, textG, textB, textA = 0.92, 0.92, 0.92, 1
    if db.disableThemeColorFont then
        local c = db.customFontColor
        if c then textR, textG, textB, textA = c[1], c[2], c[3], c[4] end
    end

    HideStaticPopupDecorations(popup)

    if not popup.guiBackdrop then
        popup.guiBackdrop = CreateFrame("Frame", nil, popup, "BackdropTemplate")
        popup.guiBackdrop:SetPoint("TOPLEFT",     popup, "TOPLEFT",      -1,  1)
        popup.guiBackdrop:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT",   1, -1)
        popup.guiBackdrop:SetFrameLevel(popup:GetFrameLevel())
        popup.guiBackdrop:EnableMouse(false)
        popup.guiBackdrop:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 },
        })
    end
    popup.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    popup.guiBackdrop:SetBackdropBorderColor(brdr, brdg, brdb, brda)

    for i = 1, 4 do
        -- Skin button1..4 AND extraButton
        -- Buttons in StaticPopup frames are accessible via both .button1 (old API)
        -- AND the global name StaticPopup{n}Button{j} (modern/fallback).
        -- We check both to be safe across WoW versions.
        local function getBtn(popup, popupIndex, btnIndex)
            return popup["button" .. btnIndex]
                or _G["StaticPopup" .. popupIndex .. "Button" .. btnIndex]
        end
        -- (popupIndex is loop var i from outer scope — referenced in closure below)
        SkinStaticPopupButton(getBtn(popup, i, 1), sr, sg, sb, bgr, bgg, bgb, bga, fontPath)
        SkinStaticPopupButton(getBtn(popup, i, 2), sr, sg, sb, bgr, bgg, bgb, bga, fontPath)
        SkinStaticPopupButton(getBtn(popup, i, 3), sr, sg, sb, bgr, bgg, bgb, bga, fontPath)
        SkinStaticPopupButton(getBtn(popup, i, 4), sr, sg, sb, bgr, bgg, bgb, bga, fontPath)
        SkinStaticPopupButton(
            popup.extraButton or _G["StaticPopup" .. i .. "ExtraButton"],
            sr, sg, sb, bgr, bgg, bgb, bga, fontPath
        )
    end

    if popup.text then
        popup.text:SetFont(fontPath, 13, "OUTLINE")
        popup.text:SetTextColor(textR, textG, textB, textA)
        popup.text:SetShadowColor(0, 0, 0, 0.8)
        popup.text:SetShadowOffset(1, -1)
    end
    if popup.nameText then
        popup.nameText:SetFont(fontPath, 12, "OUTLINE")
        popup.nameText:SetTextColor(sr, sg, sb, 1)
    end
    if popup.subText then
        popup.subText:SetFont(fontPath, 11, "OUTLINE")
        popup.subText:SetTextColor(textR * 0.75, textG * 0.75, textB * 0.75, 1)
    end
    if popup.timerText then
        popup.timerText:SetFont(fontPath, 11, "OUTLINE")
        popup.timerText:SetTextColor(sr, sg, sb, 1)
    end

    popup._guiPopupSkinned = true
end

function Styling:SkinStaticPopups()
    local db = GetDB()
    if not db then return end

    if not db.staticPopups then
        db.staticPopups = {
            enabled = true,
            disableThemeColorBackground = false,
            customBackgroundColor = { 0.07, 0.07, 0.07, 0.97 },
            disableThemeColorFont = false,
            customFontColor = { 1, 1, 1, 1 },
            hideBorder = false,
            disableThemeColorBorder = false,
            customBorderColor = { 1, 1, 1, 1 },
        }
    else
        if db.staticPopups.hideBorder          == nil then db.staticPopups.hideBorder          = false end
        if db.staticPopups.disableThemeColorBorder == nil then db.staticPopups.disableThemeColorBorder = false end
        if db.staticPopups.customBorderColor   == nil then db.staticPopups.customBorderColor   = { 1, 1, 1, 1 } end
    end

    if not db.staticPopups.enabled then return end
    if staticPopupHooked then return end

    local fontPath = GetFontPath()
    if not fontPath then return end

    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup then
            popup:HookScript("OnShow", function(self)
                local currentDb = GetDB()
                if not currentDb or not currentDb.staticPopups or not currentDb.staticPopups.enabled then return end
                local fp = GetFontPath()
                if fp then ApplySkinToStaticPopup(self, currentDb.staticPopups, fp) end
            end)
            if popup:IsShown() then
                ApplySkinToStaticPopup(popup, db.staticPopups, fontPath)
            end
        end
    end

    staticPopupHooked = true
end

function Styling:RefreshStaticPopups()
    local db = GetDB()
    if not db or not db.staticPopups then return end

    local fontPath = GetFontPath()
    if not fontPath then return end

    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() and popup._guiPopupSkinned then
            for j = 1, 4 do
                local btn = popup["button" .. j]
                if btn then btn._guiSkinned = nil end
            end
            if popup.extraButton then popup.extraButton._guiSkinned = nil end
            ApplySkinToStaticPopup(popup, db.staticPopups, fontPath)
        end
    end
end

function Styling:Refresh()
    Styling:RefreshGameMenu()
    Styling:RefreshReadyCheck()
    Styling:RefreshKeystone()
    Styling:RefreshPowerBar()
    Styling:RefreshStaticPopups()
end

-- Make global for external access
GUI.Styling = Styling
