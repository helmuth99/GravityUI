---------------------------------------------------------------------------
-- GravityUI Chat Module
-- Adapts GravityUI chat customization for modern WoW
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local C = ns.Colors

ns.Chat = {}
local historyFrame = nil
local skinnedFrames = {}
local urlPopup = nil
local chatCopyFrame = nil
local copyButtons = {}
local hookedChatFrames = {}

local tinsert = table.insert
local tconcat = table.concat

-- Textures to strip from ChatFrame
local CHAT_FRAME_TEXTURES = {
    "Background",
    "TopLeftTexture", "TopRightTexture",
    "BottomLeftTexture", "BottomRightTexture",
    "TopTexture", "BottomTexture",
    "LeftTexture", "RightTexture",
}

-- URL Patterns
local URL_PATTERNS = {
    "%f[%S](%a[%w+.-]+://%S+)",             -- protocol://path
    "%f[%S](www%.[-%w_%%]+%.%a%a+/%S+)",    -- www.domain.tld/path
    "%f[%S](www%.[-%w_%%]+%.%a%a+)",        -- www.domain.tld
}

-- EditBox textures to strip
local EDITBOX_TEXTURES = {
    "FocusLeft", "FocusMid", "FocusRight",
    "Header", "HeaderSuffix", "LanguageHeader",
    "Prompt", "NewcomerHint",
}

local function GetSettings()
    local db = ns.GetDB()
    -- Fallback for weird edge cases (e.g. AceConfig open)
    if not db and ns.Addon and ns.Addon.db then
        db = ns.Addon.db.profile
    end
    
    if db and db.uiimprovements and db.uiimprovements.chat then
        return db.uiimprovements.chat
    end
    return nil
end

-- Global hider for stubborn elements
local Hider = CreateFrame("Frame", "GravityUI_ChatHider", UIParent)
Hider:Hide()
Hider:EnableMouse(false)

local function Kill(frame, force)
    if not frame then return end
    if type(frame) == "string" then frame = _G[frame] end
    if not frame then return end
    
    local settings = GetSettings()
    local shouldKill = force or (settings and settings.hideButtons)
    
    -- Store original state for potential restoration
    if not frame.__guiOriginalParent then
        frame.__guiOriginalParent = frame:GetParent()
    end

    if shouldKill then
        frame.__guiKilled = true -- Mark as killed to prevent fighting
        frame:Hide()
        -- frame:SetParent(Hider) -- DON'T re-parent, it breaks Edit Mode handles
        frame:SetAlpha(0)
    else
        -- Resurrection: Only if it was killed by US and is not a "force" kill
        if not force then
            frame:SetAlpha(1)
            frame:Show()
        end
    end
    
    if not frame.__guiHooked then
        frame.__guiHooked = true
        -- Store original OnShow if it had one (some Blizzard buttons do)
        frame.__guiOriginalOnShow = frame:GetScript("OnShow")

        -- Performance Fix (Bug 4): Cache the kill-state as upvalue booleans.
        -- GetSettings() (= DB lookup) was previously being called on EVERY Show/SetAlpha
        -- call, which fires multiple times per chat tab switch. These hooks are extremely
        -- hot paths that must have zero overhead.
        -- The cached value is updated by calling Kill() again when settings change.
        local shouldSuppress = shouldKill
        frame.__guiUpdateSuppressState = function(newState)
            shouldSuppress = newState
        end

        hooksecurefunc(frame, "Show", function(self)
            if shouldSuppress then
                self:Hide()
            end
        end)
        hooksecurefunc(frame, "SetAlpha", function(self, alpha)
            if alpha > 0 and shouldSuppress then
                self:SetAlpha(0)
            end
        end)
    else
        -- If already hooked, update the cached state for subsequent calls
        if frame.__guiUpdateSuppressState then
            frame.__guiUpdateSuppressState(shouldKill)
        end
    end
end

-- Suppress only the visual appearance of a frame but DO NOT block Show().
-- This is critical for ScrollBar / ScrollToBottomButton: Blizzard calls Show()
-- on these internally to trigger the auto-scroll-to-bottom mechanic.
-- Blocking Show() via Kill() would permanently break chat auto-scrolling.
local function HideVisually(frame)
    if not frame then return end
    if type(frame) == "string" then frame = _G[frame] end
    if not frame then return end

    frame:SetAlpha(0)
    -- Hook SetAlpha only to keep it invisible, but never block Show()
    if not frame.__guiScrollHidden then
        frame.__guiScrollHidden = true
        hooksecurefunc(frame, "SetAlpha", function(self, alpha)
            if alpha > 0 then self:SetAlpha(0) end
        end)
    end
end

---------------------------------------------------------------------------
-- Visual Styling (Glass, Fonts)
---------------------------------------------------------------------------

local function StripDefaultTextures(chatFrame)
    local frameName = chatFrame:GetName()
    if not frameName then return end

    for _, textureName in ipairs(CHAT_FRAME_TEXTURES) do
        local texture = _G[frameName .. textureName]
        if texture and texture.SetTexture then
            texture:SetTexture(0)
            texture:SetAlpha(0)
        end
    end
end

local function CreateGlassBackdrop(chatFrame)
    local settings = GetSettings()
    if not settings or not settings.glass or not settings.glass.enabled then return end

    -- Create or update backdrop
    if not chatFrame.__guiChatBackdrop then
        local backdrop = CreateFrame("Frame", nil, chatFrame, "BackdropTemplate")
        backdrop:SetFrameLevel(math.max(1, chatFrame:GetFrameLevel() - 1))
        backdrop:SetFrameStrata("BACKGROUND")
        backdrop:EnableMouse(false) -- VERY IMPORTANT: Don't block parent clicks
        backdrop:SetPoint("TOPLEFT", -8, 2)
        backdrop:SetPoint("BOTTOMRIGHT", 8, -8)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        chatFrame.__guiChatBackdrop = backdrop
    end

    -- Apply color and transparency
    local alpha = settings.glass.bgAlpha or 0.25
    local bgColor = settings.glass.bgColor or {0, 0, 0, 1}
    chatFrame.__guiChatBackdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], alpha)
    chatFrame.__guiChatBackdrop:SetBackdropBorderColor(bgColor[1], bgColor[2], bgColor[3], alpha)
    
    if settings.glass.enabled then
         chatFrame.__guiChatBackdrop:Show()
    else
         chatFrame.__guiChatBackdrop:Hide()
    end
end

local function RemoveGlassBackdrop(chatFrame)
    if chatFrame.__guiChatBackdrop then
        chatFrame.__guiChatBackdrop:Hide()
    end
end

local function StyleFontStrings(chatFrame)
    -- Style the main font string container to force outline
    -- Use Main Font if available
    local fontPath, fontOutline = ns.GetFont()
    local _, fontSize, _ = chatFrame:GetFont()
    
    if fontPath and fontSize then
        chatFrame:SetFont(fontPath, fontSize, fontOutline or "OUTLINE")
        chatFrame:SetShadowOffset(0, 0)
    end
end

---------------------------------------------------------------------------
-- Tab Styling
---------------------------------------------------------------------------

local function UpdateTabColors(tab)
    if not tab or not tab.__guiBackdrop then return end
    
    local chatFrame = _G["ChatFrame" .. tab:GetID()]
    local isSelected = (chatFrame == SELECTED_CHAT_FRAME)
    local isHovered = tab.__guiHovered -- Use explicit flag!
    -- local isHovered = MouseIsOver(tab) -- Disabled: unreliable?
    local settings = GetSettings()
    
    -- Configurable Fading
    local activeAlpha = settings and settings.tabs and settings.tabs.activeTab and settings.tabs.activeTab.alpha or 1.0
    local inactiveAlpha = settings and settings.tabs and settings.tabs.inactiveTab and settings.tabs.inactiveTab.alpha or 0.5
    
    -- Debugging Alpha Issues
    -- print("UpdateTabColors: ID="..tab:GetID().." settings="..(settings and "OK" or "NIL").." active="..activeAlpha.." inactive="..inactiveAlpha)
    
    -- Determine colors
    local bgAlpha = 0
    local borderR, borderG, borderB, borderA = 0, 0, 0, 0
    local textR, textG, textB = 1, 1, 1 -- Default White Text
    
    -- Theme Color Helper
    local function GetActiveColor()
        if settings and settings.tabs and settings.tabs.activeTab then
             if settings.tabs.activeTab.useThemeColor then
                 return ns.GetAccentColor()
             elseif settings.tabs.activeTab.customColor then
                 return unpack(settings.tabs.activeTab.customColor)
             end
        end
        return 1, 0.8, 0 -- Fallback Gold
    end

    local activeDisableBg = settings.tabs and settings.tabs.activeTab and settings.tabs.activeTab.disableBackground

    if isSelected then
        -- Selected: High Visibility, Theme/Custom Text
        tab.__guiIgnoreAlpha = true
        tab:SetAlpha(activeAlpha)
        tab.__guiIgnoreAlpha = false
        
        local activeDisableBox = settings.tabs and settings.tabs.activeTab and settings.tabs.activeTab.disableBox
        
        if activeDisableBg then
            bgAlpha = 0 -- Entirely invisible background
            borderA = 0 -- No border
            borderR, borderG, borderB = 0, 0, 0
        elseif activeDisableBox then
            bgAlpha = 0.3 -- Same as inactive
            borderA = 0   -- No border
            borderR, borderG, borderB = 0, 0, 0
        else
            bgAlpha = 0.8 -- Stronger background for "Button" feel
            borderA = 1
        end
        
        local ar, ag, ab = GetActiveColor()
        if not activeDisableBox and not activeDisableBg then
            borderR, borderG, borderB = ar, ag, ab
        end
        textR, textG, textB = ar, ag, ab -- Text matches active color
        
    elseif isHovered then
        -- Hover: Visible BG + Grey Border
        tab.__guiIgnoreAlpha = true
        tab:SetAlpha(inactiveAlpha + 0.2) -- Slight boost on hover
        tab.__guiIgnoreAlpha = false
        
        if activeDisableBg then
            bgAlpha = 0
            borderA = 0
            borderR, borderG, borderB = 0, 0, 0
        else
            bgAlpha = 0.5
            borderR, borderG, borderB = 0.5, 0.5, 0.5
            borderA = 1
        end
        textR, textG, textB = 1, 1, 1 -- White on hover
        
    else
        -- Inactive: Dim, White Text
        tab.__guiIgnoreAlpha = true
        tab:SetAlpha(inactiveAlpha)
        tab.__guiIgnoreAlpha = false
        
        if activeDisableBg then
            bgAlpha = 0
        else
            bgAlpha = 0.3 -- Subtle background always visible for "Button" look
        end
        borderR, borderG, borderB = 0, 0, 0
        borderA = 0 -- No Border for inactive tabs (Cleaner Look)
        textR, textG, textB = 1, 1, 1 -- White inactive
    end
    
    -- Apply Backdrop
    tab.__guiBackdrop:SetBackdropColor(0.1, 0.1, 0.1, bgAlpha) -- Dark Grey Button Base
    tab.__guiBackdrop:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
    
    -- Apply Text Color
    -- Apply Text Color
    if tab.__guiMyText then
        tab.__guiMyText:SetTextColor(textR, textG, textB, 1)
    end
end

local function StyleChatTab(tab)
    if not tab then return end
    
    -- 1. Strip Textures (Iterative Method - SAFER)
    -- We want to hide ALL standard Blizzard textures (Left, Right, Middle, Active, Highlight, etc.)
    -- BUT NOT the text (FontString) or our custom backdrop (Frame)
    
    local regions = {tab:GetRegions()}
    for _, region in ipairs(regions) do
        if region:IsObjectType("Texture") then
            -- local texture = region:GetTexture()
            -- Don't SetTexture(nil) as it breaks Blizzard's UpdateColors
            region:SetAlpha(0)
            region:Hide()
        end
    end
    
    -- Extra Safety: Explicitly hide known Blizzard textures
    local textureNames = {"Left", "Right", "Middle", "ActiveLeft", "ActiveMiddle", "ActiveRight", "HighlightLeft", "HighlightMiddle", "HighlightRight", "Glow", "SelectedLeft", "SelectedMiddle", "SelectedRight"} 
    for _, name in ipairs(textureNames) do
        local tex = tab[name]
        if tex then tex:SetAlpha(0) tex:Hide() end
    end
    
    -- Find and anchor Tab Text
    -- Find Tab Text (Dynamic Search)
    local text = _G[tab:GetName() .. "Text"]
    
    -- Fallback: Search regions if global name fails (likely in Modern WoW)
    if not text then
        for _, region in ipairs({tab:GetRegions()}) do
            if region:IsObjectType("FontString") then
                text = region
                break
            end
        end
    end
    
    if text then
        text:SetParent(tab)
        text:SetDrawLayer("OVERLAY", 7)
        text:ClearAllPoints()
        text:SetPoint("CENTER", tab, "CENTER", 0, -5)
        text:SetJustifyV("MIDDLE")
        text:SetJustifyH("CENTER")
        
        -- DIAGNOSTIC VOID STRATEGY
        -- 1. Create a void frame if needed
        if not ns.Chat.voidFrame then
            ns.Chat.voidFrame = CreateFrame("Frame")
            ns.Chat.voidFrame:Hide()
        end

        if not text.__guiReplaced then
            text.__guiReplaced = true
            
            -- Styling Logic

            -- 1. Create our custom text (Using GameFontWhite)
            local myText = tab:CreateFontString(nil, "OVERLAY", "GameFontWhite")
            myText:SetPoint("CENTER", tab, "CENTER", 0, -5)
            myText:SetJustifyV("MIDDLE")
            myText:SetJustifyH("CENTER")
            
            -- Font Logic
            local fontPath, fontOutline = ns.GetFont()
            myText:SetFont(fontPath, 12, fontOutline or "OUTLINE")
            myText:SetShadowOffset(0, 0)
            -- myText:SetTextColor(1, 1, 1, 1) -- Handled by UpdateTabColors now
            
            tab.__guiMyText = myText
            
            -- 2. Hide Original (Alpha Only - Safer)
            text:SetAlpha(0)
            
            -- 3. Sync Logic
            local function SyncText(self)
                local content = self:GetText() or ""
                -- Strip colors
                if string.find(content, "|c") then
                     content = string.gsub(content, "|c%x%x%x%x%x%x%x%x", "")
                     content = string.gsub(content, "|r", "")
                end
                
                -- Update our text
                if tab.__guiMyText then
                    tab.__guiMyText:SetText(content)
                    -- Re-apply colors based on state (Active vs Inactive)
                    UpdateTabColors(tab)
                end
            end
            
            hooksecurefunc(text, "SetText", function(self) SyncText(self) end)
            hooksecurefunc(text, "SetFormattedText", function(self) SyncText(self) end)
            
            -- Initial Sync
            SyncText(text)
        end
        
        -- Prevent color changes on the original (just in case it finds its way back)
        text.__guiIgnoreColorHook = true 
        text:SetTextColor(1, 1, 1) 
        text.__guiIgnoreColorHook = false
    end
    
    -- 2. Create Backdrop (Wider & Centered)
    if not tab.__guiBackdrop then
        local bd = CreateFrame("Frame", nil, tab, "BackdropTemplate")
        bd:SetFrameLevel(tab:GetFrameLevel() - 1)
        
        -- Widen the box relative to the tab frame
        -- Tab frame is usually wider than text, so 0 padding might be huge
        -- But user wants WIDER boxes.
        bd:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, -4) 
        bd:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
        
        bd:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        
        tab.__guiBackdrop = bd
        
        -- Hook scripts for dynamic updates
        if not tab.__guiHookedScripts then
            tab.__guiHookedScripts = true
            tab:HookScript("OnEnter", function() 
                tab.__guiHovered = true 
                UpdateTabColors(tab) 
            end)
            tab:HookScript("OnLeave", function() 
                tab.__guiHovered = false
                UpdateTabColors(tab) 
            end)
            tab:HookScript("OnShow", function() UpdateTabColors(tab) end)
        end
        
        -- Hook SetAlpha to prevent Blizzard from overriding our alpha
        -- (e.g. during fade animations or tab switching)
        if not tab.__guiHookedAlpha then
            tab.__guiHookedAlpha = true
            hooksecurefunc(tab, "SetAlpha", function(self, newAlpha)
                if self.__guiIgnoreAlpha then return end
                -- Re-apply our colors/alpha if something else changes it
                UpdateTabColors(self)
            end)
        end
    end
    
    -- 3. Initial Color Update
    UpdateTabColors(tab)
    
    -- 4. Font Style (White)
    local fontPath, fontOutline = ns.GetFont()
    if text then
        text:SetFont(fontPath, 12, fontOutline or "OUTLINE")
        text:SetShadowOffset(0, 0)
        text:SetTextColor(1, 1, 1) -- Force White
    end
end

-- Global hook to handle selection changes
if not ns.Chat.SelectionHooked then
    ns.Chat.SelectionHooked = true
    hooksecurefunc("FCF_SelectDockFrame", function()
        for i = 1, 10 do
            local tab = _G["ChatFrame" .. i .. "Tab"]
            if tab and tab.__guiBackdrop then
                UpdateTabColors(tab)
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Timestamps & URLs
---------------------------------------------------------------------------

-- Timestamp positioning via Blizzard's showTimestamps CVar.
-- We do NOT inject timestamps into the message text ourselves — that would
-- put them AFTER the "[Raid] [Name]:" prefix which Blizzard appends later.
-- The CVar places the stamp at the very beginning of the line, which is
-- what the user expects. We simply sync it to GravityUI's setting.
local function ApplyTimestampCVar()
    local settings = GetSettings()
    if not settings or not settings.timestamps then
        SetCVar("showTimestamps", "none")
        return
    end
    if settings.timestamps.enabled then
        local c = settings.timestamps.color
        local hex = c and string.format("%02x%02x%02x", (c[1] or 0.76)*255, (c[2] or 0.77)*255, (c[3] or 0.73)*255) or "c2c5bc"
        local timeFmt = (settings.timestamps.format == "12h") and "%I:%M %p" or "%H:%M"
        -- Append " |" as a literal separator between the timestamp and channel/sender.
        local fmt = "|cff"..hex..timeFmt.."|r | "
        SetCVar("showTimestamps", fmt)
    else
        SetCVar("showTimestamps", "none")
    end
end

local function MakeURLsClickable(text)
    local settings = GetSettings()
    if not settings or not settings.urls or not settings.urls.enabled then
        return text
    end

    local success, result = pcall(function()
        local r, g, b = 0.078, 0.608, 0.992  -- Default blue
        if settings.urls.color then
            r, g, b = settings.urls.color[1] or r, settings.urls.color[2] or g, settings.urls.color[3] or b
        end
        local colorHex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
        local linkFormat = "|cff" .. colorHex .. "|Haddon:GravityUIChat:%1|h[%1]|h|r"

        local processed = text
        for _, pattern in ipairs(URL_PATTERNS) do
            processed = processed:gsub(pattern, linkFormat)
        end
        return processed
    end)

    if success then return result else return text end
end

-- TAINT-SAFE MESSAGE PROCESSING
-- ChatFrame_AddMessageEventFilter is Blizzard's purpose-built API for addon
-- message pre-processing. Filters are called inside Blizzard's secure event
-- dispatch chain, BEFORE AddMessage runs. They can modify the 'text' argument
-- directly and return the new value — no addon code ever sits on the call
-- stack when SetLastTellTarget(sender) fires. This eliminates the WHISPER
-- "attempt to perform string conversion on a secret string value" taint crash.
local guiMessageFilterRegistered = false
local function RegisterMessageFilter()
    if guiMessageFilterRegistered then return end
    guiMessageFilterRegistered = true

    -- This filter runs for every chat event on every registered chat frame.
    -- Return false (or nil) to pass through; return true to suppress the message.
    -- The signature is: function(chatFrame, event, text, ...) return suppress, newText, ...
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER",         function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM",  function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY",             function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL",            function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY",           function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER",    function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID",            function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER",     function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD",           function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER",         function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT",   function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL",         function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE",           function(_, event, text, ...) return false, HookTransformText(text), ... end)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE",      function(_, event, text, ...) return false, HookTransformText(text), ... end)
end

-- URL transform only — timestamps are handled by the showTimestamps CVar.
function HookTransformText(text)
    if not text or type(text) ~= "string" then return text end
    local success, result = pcall(MakeURLsClickable, text)
    return success and result or text
end

-- Per-frame hook: now just ensures we've registered filters once.
-- The actual work is done by RegisterMessageFilter / HookTransformText above.
local function HookChatMessages(chatFrame)
    if chatFrame.__guiChatMessageHooked then return end
    chatFrame.__guiChatMessageHooked = true
    RegisterMessageFilter()
end

---------------------------------------------------------------------------
-- Copy Popup (URL)
---------------------------------------------------------------------------

local function CreateCopyPopup()
    if urlPopup then return urlPopup end

    urlPopup = CreateFrame("Frame", "GravityUI_ChatCopyPopup", UIParent, "BackdropTemplate")
    urlPopup:SetSize(420, 90)
    urlPopup:SetPoint("CENTER")
    urlPopup:SetFrameStrata("DIALOG")
    
    -- Styling matches GravityUI (Dark BG, Cyan Border). logic replicated from ns.GUI
    urlPopup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    
    local bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    urlPopup:SetBackdropColor(bgr, bgg, bgb, bga)
    urlPopup:SetBackdropBorderColor(ns.GetAccentColor())
    
    urlPopup:EnableMouse(true)
    urlPopup:SetMovable(true)
    urlPopup:RegisterForDrag("LeftButton")
    urlPopup:SetScript("OnDragStart", urlPopup.StartMoving)
    urlPopup:SetScript("OnDragStop", urlPopup.StopMovingOrSizing)
    urlPopup:Hide()

    -- Title
    local title = urlPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Press Ctrl+C to copy")
    
    -- Styling Text (Use Main Font)
    local fontPath, fontOutline = ns.GetFont()
    title:SetFont(fontPath, 14, fontOutline)
    local sr, sg, sb, sa = ns.GetAccentColor()
    title:SetTextColor(sr, sg, sb, sa)

    local editBox = CreateFrame("EditBox", nil, urlPopup, "InputBoxTemplate")
    editBox:SetSize(380, 24)
    editBox:SetPoint("CENTER", 0, -8)
    editBox:SetAutoFocus(true)
    editBox:SetScript("OnEscapePressed", function() urlPopup:Hide() end)
    editBox:SetScript("OnEnterPressed", function() urlPopup:Hide() end)
    
    -- Style EditBox
    local regions = {editBox:GetRegions()}
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
    end
    
    local ebBackdrop = CreateFrame("Frame", nil, editBox, "BackdropTemplate")
    ebBackdrop:SetPoint("TOPLEFT", -4, 2)
    ebBackdrop:SetPoint("BOTTOMRIGHT", 4, -2)
    ebBackdrop:SetFrameLevel(editBox:GetFrameLevel() - 1)
    ebBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    ebBackdrop:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
    ebBackdrop:SetBackdropBorderColor(unpack(C.border or {0.2, 0.2, 0.2, 1}))
    
    urlPopup.editBox = editBox
    
    -- Font for Input
    editBox:SetFont(fontPath, 12, "")

    local closeBtn = CreateFrame("Button", nil, urlPopup, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)

    if not tContains(UISpecialFrames, "GravityUI_ChatCopyPopup") then
        tinsert(UISpecialFrames, "GravityUI_ChatCopyPopup")
    end

    return urlPopup
end

local function ShowCopyPopup(url)
    local popup = CreateCopyPopup()
    popup.editBox:SetText(url)
    popup.editBox:HighlightText()
    popup:Show()
    popup.editBox:SetFocus()
end

local function SetupURLClickHandler()
    -- Register for hyperlink clicks
    EventRegistry:RegisterCallback("SetItemRef", function(_, link, text, button)
        if not link then return end
        local url = link:match("^addon:GravityUIChat:(.*)")
        if url then
            ShowCopyPopup(url)
            return true
        end
    end)
end

---------------------------------------------------------------------------
-- Chat Copy (History)
---------------------------------------------------------------------------

local function CleanMessage(message)
    if not message or type(message) ~= "string" then return "" end
    
    local success, result = pcall(function()
        local cleaned = message
        cleaned = cleaned:gsub("|T[^|]*|t", "")
        cleaned = cleaned:gsub("|A[^|]*|a", "")
        cleaned = cleaned:gsub("|TInterface\\TargetingFrame\\UI%-RaidTargetingIcon_(%d):[^|]*|t", "{rt%1}")
        cleaned = cleaned:gsub("|H[^|]*|h%[?([^%]|]*)%]?|h", "%1")
        cleaned = cleaned:gsub("|c%x%x%x%x%x%x%x%x", "")
        cleaned = cleaned:gsub("|r", "")
        return cleaned
    end)
    
    if success then return result else return "" end
end

local function GetChatLines(chatFrame)
    local lines = {}
    local num = chatFrame:GetNumMessages()
    for i = 1, num do
        local msg = chatFrame:GetMessageInfo(i)
        if msg then
            local clean = CleanMessage(msg)
            if clean and clean ~= "" then
                tinsert(lines, clean)
            end
        end
    end
    return lines
end

local function CreateChatCopyFrame()
    if chatCopyFrame then return chatCopyFrame end

    chatCopyFrame = CreateFrame("Frame", "GravityUI_ChatCopyFrame", UIParent, "BackdropTemplate")
    chatCopyFrame:SetSize(600, 500) -- Slightly larger
    chatCopyFrame:SetPoint("CENTER")
    chatCopyFrame:SetFrameStrata("DIALOG")
    
    -- Gravity Styling
    chatCopyFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    local bgr, bgg, bgb, bga = ns.GetThemeBgColor()
    chatCopyFrame:SetBackdropColor(bgr, bgg, bgb, bga)
    chatCopyFrame:SetBackdropBorderColor(ns.GetAccentColor())
    
    chatCopyFrame:EnableMouse(true)
    chatCopyFrame:SetMovable(true)
    chatCopyFrame:SetResizable(true)
    chatCopyFrame:RegisterForDrag("LeftButton")
    chatCopyFrame:SetScript("OnDragStart", chatCopyFrame.StartMoving)
    chatCopyFrame:SetScript("OnDragStop", chatCopyFrame.StopMovingOrSizing)
    chatCopyFrame:Hide()

    local title = chatCopyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Chat History - Select and Ctrl+C to copy")
    
    -- Use Main Font
    local fontPath, fontOutline = ns.GetFont()
    title:SetFont(fontPath, 14, fontOutline)
    local sr, sg, sb, sa = ns.GetAccentColor()
    title:SetTextColor(sr, sg, sb, sa)

    local scrollFrame = CreateFrame("ScrollFrame", nil, chatCopyFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

    -- Style Scrollbar
    local sb = scrollFrame.ScrollBar
    if sb then
       sb:SetWidth(8)
       local thumb = sb:GetThumbTexture()
       if thumb then
           local sr, sg, sb_color, sa = ns.GetAccentColor()
           thumb:SetColorTexture(sr, sg, sb_color, 0.5)
           thumb:SetWidth(8)
       end
    end

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(550)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function() chatCopyFrame:Hide() end)
    scrollFrame:SetScrollChild(editBox)
    chatCopyFrame.editBox = editBox
    
    -- Update font to match addon font
    editBox:SetFont(fontPath, 12, "")
    
    local closeBtn = CreateFrame("Button", nil, chatCopyFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)

    -- SELECT ALL BUTTON
    local selectAllBtn = CreateFrame("Button", nil, chatCopyFrame, "BackdropTemplate")
    selectAllBtn:SetSize(120, 24)
    selectAllBtn:SetPoint("BOTTOMLEFT", 12, 8)
    
    selectAllBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    selectAllBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    selectAllBtn:SetBackdropBorderColor(unpack(C.border or {0.2,0.2,0.2,1}))
    
    local btnText = selectAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetText("Select All")
    btnText:SetPoint("CENTER")
    
    btnText:SetFont(fontPath, 12, "", {1, 0.82, 0, 1}) -- Gold/Yellow text
    
    selectAllBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(ns.GetAccentColor())
    end)
    selectAllBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end)
    selectAllBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    
    chatCopyFrame.selectAllBtn = selectAllBtn

    if not tContains(UISpecialFrames, "GravityUI_ChatCopyFrame") then
        tinsert(UISpecialFrames, "GravityUI_ChatCopyFrame")
    end

    local resizeBtn = CreateFrame("Button", nil, chatCopyFrame)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetScript("OnMouseDown", function() chatCopyFrame:StartSizing("BOTTOMRIGHT") end)
    resizeBtn:SetScript("OnMouseUp", function() chatCopyFrame:StopMovingOrSizing() end)

    return chatCopyFrame
end

---------------------------------------------------------------------------
-- Chat History (Persistence)
---------------------------------------------------------------------------

local HISTORY_EVENTS = {
    ["CHAT_MSG_SAY"] = true, ["CHAT_MSG_YELL"] = true,
    ["CHAT_MSG_WHISPER"] = true, ["CHAT_MSG_WHISPER_INFORM"] = true,
    ["CHAT_MSG_PARTY"] = true, ["CHAT_MSG_PARTY_LEADER"] = true,
    ["CHAT_MSG_RAID"] = true, ["CHAT_MSG_RAID_LEADER"] = true,
    ["CHAT_MSG_GUILD"] = true, ["CHAT_MSG_OFFICER"] = true,
    ["CHAT_MSG_INSTANCE_CHAT"] = true, ["CHAT_MSG_INSTANCE_CHAT_LEADER"] = true,
    ["CHAT_MSG_EMOTE"] = true,
}

local function SaveChatMessage(event, ...)
    -- History saving completely disabled as per user request
    return
end

local function RestoreChatHistory()
    -- Completely delete chat history from the DB as per user request
    if ns.db and ns.db.char and ns.db.char.chatHistory then
        ns.db.char.chatHistory = nil
    end
    return
end

local function SetupChatHistory()
    if historyFrame then return end
    
    historyFrame = CreateFrame("Frame")
    historyFrame:SetScript("OnEvent", function(self, event, ...)
        SaveChatMessage(event, ...)
    end)
    
    for event in pairs(HISTORY_EVENTS) do
        historyFrame:RegisterEvent(event)
    end
end

local function ShowChatCopyFrame(chatFrame)
    local frame = CreateChatCopyFrame()
    local lines = GetChatLines(chatFrame)
    local text = #lines == 0 and "(No copyable messages)" or tconcat(lines, "\n")
    
    frame.editBox:SetText(text)
    frame.editBox:SetWidth(frame:GetWidth()-50)
    frame:Show()
    frame.editBox:SetFocus()
    frame.editBox:HighlightText()
end

---------------------------------------------------------------------------
-- Copy Button on Chat Frame
---------------------------------------------------------------------------

local function GetOrCreateCopyButton(chatFrame)
    local frameName = chatFrame:GetName()
    if not frameName then return nil end

    if copyButtons[chatFrame] then return copyButtons[chatFrame] end

    local button = CreateFrame("Button", frameName .. "GravityCopyButton", chatFrame)
    button:SetSize(20, 22)
    button:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", 4, -2)
    button:SetFrameLevel(chatFrame:GetFrameLevel() + 5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    button.icon = icon
    button:SetAlpha(0.35)

    button:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Copy Chat")
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        local settings = GetSettings()
        local mode = settings and settings.copyButtonMode or "always"
        if mode == "hover" then
             if not chatFrame:IsMouseOver() then self:SetAlpha(0) end
        else
             self:SetAlpha(0.35)
        end
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function() ShowChatCopyFrame(chatFrame) end)

    copyButtons[chatFrame] = button
    return button
end

local function ApplyCopyButtonMode(chatFrame)
    local settings = GetSettings()
    local mode = (settings and settings.copyButtonMode) or "always"
    
    local button = GetOrCreateCopyButton(chatFrame)
    if not button then return end

    if mode == "disabled" then
        button:Hide()
        return
    end

    if mode == "always" then
        button:SetAlpha(0.35)
        button:Show()
    elseif mode == "hover" then
        button:SetAlpha(0)
        button:Show()
        -- Hook hover logic
        if not chatFrame.GravityCopyButtonHooked then
            chatFrame.GravityCopyButtonHooked = true
            chatFrame:HookScript("OnEnter", function() 
                local s = GetSettings()
                if s and s.copyButtonMode == "hover" then
                    button:SetAlpha(0.35) 
                    button:Show() 
                end
            end)
            chatFrame:HookScript("OnLeave", function() 
               local s = GetSettings()
               if s and s.copyButtonMode == "hover" and not button:IsMouseOver() then 
                   button:SetAlpha(0) 
               end
            end)
        end
    end
end

---------------------------------------------------------------------------
-- Global Button Hiding
---------------------------------------------------------------------------

local function preventShow(self) self:Hide() end

local function EnsureScrollButton(chatFrame)
    if chatFrame.__guiScrollBtn then return chatFrame.__guiScrollBtn end

    local btn = CreateFrame("Button", nil, chatFrame, "BackdropTemplate")
    btn:SetSize(22, 22)
    btn:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 4, -2)
    btn:SetFrameLevel(chatFrame:GetFrameLevel() + 10)
    btn:SetAlpha(0)
    btn:Hide()
    
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, -1)
    icon:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollEnd-Up")
    
    btn:SetScript("OnEnter", function(self)
        self.isHovering = true
        local r, g, b = ns.GetAccentColor()
        self:SetBackdropBorderColor(r, g, b, 1)
        UIFrameFadeIn(self, 0.1, self:GetAlpha(), 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self.isHovering = false
        self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        if not chatFrame:IsMouseOver() then
            UIFrameFadeOut(self, 0.4, self:GetAlpha(), 0)
        end
    end)
    
    btn:SetScript("OnClick", function()
        chatFrame:ScrollToBottom()
    end)
    
    chatFrame.__guiScrollBtn = btn
    
    local function UpdateVis()
        -- Only show if scrolled up
        if chatFrame:GetNumMessages() == 0 then return end
        
        local isScrolledUp = chatFrame:GetScrollOffset() > 0
        if isScrolledUp then
            if chatFrame:IsMouseOver() or btn.isHovering then
                btn:Show()
                UIFrameFadeIn(btn, 0.2, btn:GetAlpha(), 1)
            else
                UIFrameFadeOut(btn, 0.4, btn:GetAlpha(), 0)
            end
        else
            btn:SetAlpha(0)
            btn:Hide()
        end
    end
    
    chatFrame:HookScript("OnEnter", UpdateVis)
    chatFrame:HookScript("OnLeave", function()
        C_Timer.After(0.1, UpdateVis)
    end)
    
    -- Hook scrolling actions
    hooksecurefunc(chatFrame, "ScrollUp", UpdateVis)
    hooksecurefunc(chatFrame, "ScrollDown", UpdateVis)
    hooksecurefunc(chatFrame, "ScrollToTop", UpdateVis)
    hooksecurefunc(chatFrame, "ScrollToBottom", UpdateVis)
    hooksecurefunc(chatFrame, "PageUp", UpdateVis)
    hooksecurefunc(chatFrame, "PageDown", UpdateVis)
    
    return btn
end

local function UpdateChatButtons(chatFrame)
    -- This handles per-frame buttons (Social, Scroll)
    Kill(chatFrame.buttonFrame)

    -- ScrollBar and ScrollToBottomButton: use HideVisually instead of Kill.
    -- Kill() hooks Show() which breaks Blizzard's auto-scroll-to-bottom mechanic.
    -- HideVisually keeps Alpha=0 at all times while still allowing Show() calls,
    -- so new messages cause the chat to scroll down automatically as expected.
    HideVisually(chatFrame.ScrollBar)
    HideVisually(chatFrame.ScrollToBottomButton)

    -- Auto-scroll fix: whenever a new message is added and the frame was already
    -- at the bottom (or the user hasn't manually scrolled up), scroll to bottom.
    if not chatFrame.__guiAutoScrollHooked then
        chatFrame.__guiAutoScrollHooked = true
        hooksecurefunc(chatFrame, "AddMessage", function(self)
            -- Only auto-scroll if the user hasn't intentionally scrolled up
            if self.ScrollBar then
                local atBottom = not self.ScrollBar:IsShown() or
                                 (self.ScrollBar.GetValue and
                                  self.ScrollBar:GetValue() >= (self.ScrollBar:GetMinMaxValues()))
                if atBottom then
                    self:ScrollToBottom()
                end
            else
                self:ScrollToBottom()
            end
        end)
    end

    -- Gravity Scroll to Bottom Button
    EnsureScrollButton(chatFrame)

    local frameName = chatFrame:GetName()
    if frameName then
        Kill(frameName.."ButtonFrame")
        HideVisually(frameName.."ScrollBar")
        HideVisually(frameName.."ScrollToBottomButton")
        -- These are permanently hidden (force=true)
        Kill(frameName.."ChannelButton", true)
        Kill(frameName.."VoiceChatButton", true)
        Kill(chatFrame.ChannelButton, true)
        Kill(chatFrame.VoiceChatButton, true)
    end
end

local function GlobalCleanup()
    -- 1. PERMANENT KILLS (Voice bullshit that nobody ever wants)
    Kill(ChatFrameChannelButton, true)
    Kill(VoiceChatPromptPanel, true)
    Kill(VoiceChatTranscriptButton, true)
    Kill(VoiceChatChannelExplorer, true)
    Kill(VoiceChatTranscribeButton, true)
    Kill(VoiceChatControlPanel, true)
    
    -- 2. DOCK MANAGER CLEANUP
    if GeneralDockManager then
        Kill(GeneralDockManager.ChannelButton, true)
    end

    -- 3. TOGGLEABLE KILLS (Respects settings.hideButtons)
    Kill(ChatFrameMenuButton)
    Kill(QuickJoinToastButton)
    Kill(GeneralDockManagerOverflowButton)
    if ChatMenu then Kill(ChatMenu) end
    
    -- Specifically kill rogue tabs and buttons (Voice/Default name tabs)
    for i = 1, 10 do
        local tab = _G["ChatFrame"..i.."Tab"]
        local cf = _G["ChatFrame"..i]
        if tab then
            -- Find Text safely
            local textObj = _G["ChatFrame"..i.."TabText"]
            if not textObj then
                 for _, region in ipairs({tab:GetRegions()}) do
                    if region:IsObjectType("FontString") then textObj = region break end
                 end
            end
            
            local text = textObj and textObj:GetText() or ""

            -- Kill Voice tabs and "Chat X" tabs permanently (Retail defaults)
            if text:find("Voice") or text:find("Chat %d") then
                Kill(tab, true)
            end
            -- Per-frame voice/channel buttons are killed permanently
            Kill("ChatFrame"..i.."ChannelButton", true)
            Kill("ChatFrame"..i.."VoiceChatButton", true)
            if cf then
                Kill(cf.ChannelButton, true)
                Kill(cf.VoiceChatButton, true)
            end
        end
    end
end

-- Removed ShowChatButtons as Kill handles restoration logic now

---------------------------------------------------------------------------
-- Edit Box Styling
---------------------------------------------------------------------------

local function StyleEditBox(chatFrame)
    local settings = GetSettings()
    if not settings or not settings.editBox then return end
    
    local frameName = chatFrame:GetName()
    if not frameName then return end

    local editBox = chatFrame.editBox or _G[frameName .. "EditBox"]
    if not editBox then return end

    -- Strip textures if enabled
    if settings.editBox.enabled then
        if not editBox.__guiChatStyled then
            editBox.__guiChatStyled = true
            local regions = {editBox:GetRegions()}
            for _, region in ipairs(regions) do
                if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
            end
        end
    end
    
    -- Force Arrow Keys to work without Alt
    editBox:SetAltArrowKeyMode(false)
    
    -- Backdrop (only create once)
    local isNewBackdrop = false
    if not chatFrame.__guiEditBoxBackdrop then
        isNewBackdrop = true
        local backdrop = CreateFrame("Frame", nil, chatFrame, "BackdropTemplate")
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        chatFrame.__guiEditBoxBackdrop = backdrop
    end

    local backdrop = chatFrame.__guiEditBoxBackdrop
    local posTop = settings.editBox.positionTop
    local bgAlpha = settings.editBox.bgAlpha or 0.4
    local bgColor = settings.editBox.bgColor or {0, 0, 0, 1}
    
    -- Dimensions
    local height = settings.editBox.height or 24
    local width = settings.editBox.width or 0
    local offX = settings.editBox.offsetX or 0
    local offY = settings.editBox.offsetY or 0
    
    backdrop:ClearAllPoints()
    editBox:ClearAllPoints()

    -- Set color
    backdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgAlpha)
    backdrop:SetBackdropBorderColor(bgColor[1], bgColor[2], bgColor[3], bgAlpha)
    
    -- Font
    local fontPath, fontOutline = ns.GetFont()
    local _, fontSize, _ = editBox:GetFont()
    fontSize = fontSize or 12
    editBox:SetFont(fontPath, fontSize, fontOutline or "")

    if posTop then
        -- Top Position logic
        if width > 0 then
            backdrop:SetWidth(width)
            backdrop:SetPoint("BOTTOM", chatFrame, "TOP", offX, offY)
        else
            backdrop:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", -8 + offX, offY)
            backdrop:SetPoint("BOTTOMRIGHT", chatFrame, "TOPRIGHT", 8 + offX, offY)
        end
        
        backdrop:SetHeight(height)
        
        -- Anchor EditBox to CENTER of the backdrop for perfect vertical alignment
        editBox:SetPoint("LEFT", backdrop, "LEFT", -4, 0)
        editBox:SetPoint("RIGHT", backdrop, "RIGHT", -4, 0)
        editBox:SetPoint("CENTER", backdrop, "CENTER", 0, 0)
        
        -- Set EditBox height to match font size (plus buffer) for vertical centering within the frame
        editBox:SetHeight(fontSize + 2)
        
        -- Horizontal insets only
        editBox:SetTextInsets(0, 0, 0, 0)
        
        -- Only hide backdrop on first creation (not on every Refresh).
        -- Calling backdrop:Hide() on a re-Refresh would close the editbox mid-type
        -- when PLAYER_ENTERING_WORLD fires on dungeon/raid entry.
        if isNewBackdrop then
            backdrop:Hide()
        end
        
        if not editBox.__guiTopModeHooked then
            editBox.__guiTopModeHooked = true
            editBox:HookScript("OnEditFocusGained", function() 
                local s = GetSettings()
                if s and s.editBox and s.editBox.enabled then backdrop:Show() end
            end)
            editBox:HookScript("OnEditFocusLost", function() backdrop:Hide() end)
        end
    else
        -- Bottom / Default position
        backdrop:SetHeight(height)
        
        if width > 0 then
            backdrop:SetWidth(width)
            backdrop:SetPoint("TOP", chatFrame, "BOTTOM", offX, -2 + offY)
        else
            backdrop:SetPoint("TOPLEFT", chatFrame, "BOTTOMLEFT", -5 + offX, -2 + offY)
            backdrop:SetPoint("TOPRIGHT", chatFrame, "BOTTOMRIGHT", 5 + offX, -2 + offY)
        end
        
        editBox:SetPoint("CENTER", backdrop, "CENTER", 0, 0)
        editBox:SetPoint("LEFT", backdrop, "LEFT", -4, 0)
        editBox:SetPoint("RIGHT", backdrop, "RIGHT", -4, 0)
        
        editBox:SetHeight(fontSize + 2)
        editBox:SetTextInsets(0, 0, 0, 0)
        
        -- Only hide backdrop on first creation (not on every Refresh).
        -- Calling backdrop:Hide() on a re-Refresh would close the editbox mid-type
        -- when PLAYER_ENTERING_WORLD fires on dungeon/raid entry.
        if isNewBackdrop then
            backdrop:Hide()
        end
        
        if not editBox.__guiFocusModeHooked then
            editBox.__guiFocusModeHooked = true
            editBox:HookScript("OnEditFocusGained", function() 
                local s = GetSettings()
                if s and s.editBox and s.editBox.enabled then backdrop:Show() end
            end)
            editBox:HookScript("OnEditFocusLost", function() backdrop:Hide() end)
        end
    end
end

---------------------------------------------------------------------------
-- Message Fade System
---------------------------------------------------------------------------
local function SetupMessageFade(chatFrame)
    local settings = GetSettings()
    if not settings or not settings.fade then return end

    if settings.fade.enabled then
        chatFrame:SetFading(true)
        chatFrame:SetTimeVisible(settings.fade.delay or 15)
        chatFrame:SetFadeDuration(3)
    else
        chatFrame:SetFading(false)
    end
end

---------------------------------------------------------------------------
-- Tab Autohide logic
---------------------------------------------------------------------------

-- Helper: Check if mouse is over ANY part of the chat (Dock, Frame, or Tab)
local function IsMouseOverChat()
    if GeneralDockManager and MouseIsOver(GeneralDockManager) then return true end
    
    -- Also check the ChatFrame1 specifically if it's the primary dock
    if ChatFrame1 and MouseIsOver(ChatFrame1) then return true end

    for i = 1, 10 do
        local cf = _G["ChatFrame"..i]
        local tab = _G["ChatFrame"..i.."Tab"]
        if cf and cf:IsShown() and MouseIsOver(cf) then return true end
        if tab and tab:IsShown() and MouseIsOver(tab) then return true end
    end
    return false
end

local lastHoverState = false
local function UpdateAllTabsVisibility(forceState)
    local settings = GetSettings()
    if not settings or not settings.hideTabs then return end

    local isOverAny = (forceState ~= nil) and forceState or IsMouseOverChat()
    
    -- Only trigger fade if state actually changed
    if isOverAny == lastHoverState and forceState == nil then return end
    lastHoverState = isOverAny

    -- Apply visibility to all valid tabs
    for i = 1, 10 do
        local cf = _G["ChatFrame"..i]
        local tab = _G["ChatFrame"..i.."Tab"]
        if tab and cf and cf.isInitialized and not tab.__guiKilled then
            if isOverAny then
                UIFrameFadeIn(tab, 0.2, tab:GetAlpha(), 1)
            else
                UIFrameFadeOut(tab, 0.4, tab:GetAlpha(), 0)
            end
        end
    end
end

local function ApplyTabAutohide(chatFrame)
    local settings = GetSettings()
    if not settings then return end
    
    local tab = _G[chatFrame:GetName() .. "Tab"]
    if not tab then return end

    if settings.hideTabs then
        -- Initialize Ticker once (centralized)
        if not ns.Chat.AutohideTicker then
            ns.Chat.AutohideTicker = C_Timer.NewTicker(0.2, function()
                UpdateAllTabsVisibility()
            end)
        end

        -- Initialize Alpha and Hooks
        if not tab.__guiTabHooked then
            tab.__guiTabHooked = true
            
            -- Securely prevent alpha changes by Blizzard (e.g. on click or flash)
            hooksecurefunc(tab, "SetAlpha", function(self, alpha)
                if self.__guiKilled or not self.__guiTabHooked then return end
                if self.__guiIgnoreAlphaHook then return end

                local s = GetSettings()
                if s and s.hideTabs then
                    self.__guiIgnoreAlphaHook = true
                    local target = IsMouseOverChat() and 1 or 0
                    if alpha ~= target then
                        self:SetAlpha(target)
                    end
                    self.__guiIgnoreAlphaHook = false
                end
            end)
            
            -- Also hook the Blizzard internal update function
            if not _G.__guiFCFHooked then
                _G.__guiFCFHooked = true
                hooksecurefunc("FCFTab_UpdateAlpha", function(cf)
                    local s = GetSettings()
                    if s and s.hideTabs then
                        local t = _G[cf:GetName().."Tab"]
                        if t and not t.__guiKilled then
                            t:SetAlpha(IsMouseOverChat() and 1 or 0)
                        end
                    end
                end)
            end
        end
        
        -- Set initial state
        tab:SetAlpha(IsMouseOverChat() and 1 or 0)
    else
        -- Disabled: Restore alpha and stop ticker
        if ns.Chat.AutohideTicker then
            ns.Chat.AutohideTicker:Cancel()
            ns.Chat.AutohideTicker = nil
        end
        tab:SetAlpha(1)
    end
end

local function ApplyClamping(chatFrame)
    local settings = GetSettings()
    if not settings then return end

    chatFrame:SetClampedToScreen(not settings.unclamp)
end

---------------------------------------------------------------------------
-- Main Refresh Logic
---------------------------------------------------------------------------

function ns.Chat.Refresh()
    local settings = GetSettings()
    -- Validation
    
    if not settings or settings.enabled == false then return end

    -- Run global cleanup first (Protected Call to avoid crash)
    local status, err = pcall(GlobalCleanup)
    if not status then
        -- print("GRAVITY DEBUG: GlobalCleanup CRASHED: " .. tostring(err))
    end

    -- Iterate all chat frames (standard and potential extra)
    for i = 1, 10 do
        local frameName = "ChatFrame" .. i
        local chatFrame = _G[frameName]
        if chatFrame then
            -- 1. Style
            StripDefaultTextures(chatFrame)
            CreateGlassBackdrop(chatFrame)
            StyleFontStrings(chatFrame)

            -- 2. Buttons
            ApplyCopyButtonMode(chatFrame)
            UpdateChatButtons(chatFrame)
            
            -- 3. Edit Box
            StyleEditBox(chatFrame)
            
            -- 4. Fade
            SetupMessageFade(chatFrame)

            -- 5. Tabs
            ApplyTabAutohide(chatFrame)
            
            local tab = _G[frameName .. "Tab"]
            if tab then
                StyleChatTab(tab)
            end

            -- 6. Clamping
            ApplyClamping(chatFrame)

            -- 7. Hooks (only once)
            HookChatMessages(chatFrame)
        end
    end
    
    -- 8. Alignment (Updated: Feb 13)
    if not ns.Chat.hookedAlignment then
        ns.Chat.hookedAlignment = true
        
        -- TAINT FIX: RepositionTabs manipulates tab anchor points (ClearAllPoints/SetPoint).
        -- When called synchronously inside FCF_DockUpdate, this code runs inside Blizzard's
        -- secure execution stack (FCFDock_UpdateTabs → PanelTemplates_TabResize), where
        -- 'textWidth' is a secret number value. Any addon interaction with tab geometry
        -- at that point causes the 231x taint crash. C_Timer.After(0) defers execution
        -- to the next frame, safely outside the protected stack.
        local function SafeAlign()
            C_Timer.After(0, function()
                if ns.Chat and ns.Chat.RepositionTabs then ns.Chat.RepositionTabs() end
            end)
        end
        hooksecurefunc("FCF_DockUpdate", SafeAlign)
        hooksecurefunc("FCF_OpenNewWindow", SafeAlign)
        hooksecurefunc("FCF_DockFrame", SafeAlign)
        hooksecurefunc("FCF_UnDockFrame", SafeAlign)
    end
    
    -- Always run alignment logic during Refresh
    -- (This fixes reliability issues where alignment might be skipped if Refresh ran too early)
    if ns.Chat.RepositionTabs then
        ns.Chat.RepositionTabs()
    end
end
 
-- Module Function: Reposition Chat Tabs
function ns.Chat.RepositionTabs()
    local DOCK = GENERAL_CHAT_DOCK
    if not DOCK then return end
    
    local anchor = _G["ChatFrame1"] -- Anchor to main chat
    if not anchor then return end
    
    -- We want the first tab to be flush left with ChatFrame1
    -- And others to follow with 1px spacing
    
    local lastTab = nil
    
     if not DOCK.DOCKED_CHAT_FRAMES then return end
     
     for i, chatFrame in ipairs(DOCK.DOCKED_CHAT_FRAMES) do
         local tab = _G[chatFrame:GetName() .. "Tab"]
         if tab and tab:IsShown() then
             tab:ClearAllPoints()
             
             if lastTab then
                 -- Subsequent tabs: Anchor to previous tab's RIGHT with 2px spacing (Increased)
                 tab:SetPoint("BOTTOMLEFT", lastTab, "BOTTOMRIGHT", 2, 0)
             else
                 -- First tab: Anchor to ChatFrame1's TOPLEFT
                 -- Offset updated to -7 to match text alignment better
                 tab:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", -7, 2)
             end
             
             lastTab = tab
         end
     end
end

function ns.Chat.Init()
    local settings = GetSettings()
    if settings and settings.enabled == false then return end

    -- Sync Blizzard's showTimestamps CVar to GravityUI's timestamp setting.
    -- This puts the stamp at the very start of each line (before sender prefix).
    ApplyTimestampCVar()

    SetupURLClickHandler()
    SetupChatHistory()
    
    -- Restore history after a small delay to ensure frames are ready
    if settings and settings.history and settings.history.enabled then
        C_Timer.After(1.5, RestoreChatHistory)
    end
    
    -- TAINT FIX: These hooks previously called Refresh() synchronously inside Blizzard's
    -- protected FCF_* execution stack. That stack includes FCFDock_UpdateTabs →
    -- PanelTemplates_TabResize, where 'textWidth' is a secret/tainted number.
    -- Calling addon code (StyleChatTab, RepositionTabs, etc.) at that point caused the
    -- 231x "attempt to perform arithmetic on local 'textWidth' (a secret number value
    -- tainted by 'AccWideUILayoutSelection')" error.
    -- C_Timer.After(0) defers all work to the next frame, safely outside the stack.
    local function DeferredRefresh()
        C_Timer.After(0, function() if ns.Chat and ns.Chat.Refresh then ns.Chat.Refresh() end end)
    end
    hooksecurefunc("FCF_OpenNewWindow",      DeferredRefresh)
    hooksecurefunc("FCF_OpenTemporaryWindow", DeferredRefresh)
    hooksecurefunc("FCF_DockFrame",           DeferredRefresh)
    hooksecurefunc("FCF_UnDockFrame",         DeferredRefresh)

    -- Prevents Blizzard from resetting alpha/colors on tab selection/deselection.
    -- This fixes the "Active Tab Alpha 1.0" issue.
    -- TAINT FIX: FCFTab_UpdateColors also runs in a secure context. Defer via timer.
    hooksecurefunc("FCFTab_UpdateColors", function(tab, selected)
        C_Timer.After(0, function()
            if ns.Chat and tab and tab.__guiBackdrop then UpdateTabColors(tab) end
        end)
    end)

    -- Initial Refresh after a short delay to let SVs load
    C_Timer.After(1, function() ns.Chat.Refresh() end)
end

-- Hook into addon loading if needed, or just run Init
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    ns.Chat.Init()
end)
