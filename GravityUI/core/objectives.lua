local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = ns.Colors

-- Module
ns.Objectives = {}
local Objectives = ns.Objectives

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------
local FONT_FLAGS = "OUTLINE"

local trackerModules = {
    "ScenarioObjectiveTracker",
    "UIWidgetObjectiveTracker",
    "CampaignQuestObjectiveTracker",
    "QuestObjectiveTracker",
    "AdventureObjectiveTracker",
    "AchievementObjectiveTracker",
    "MonthlyActivitiesObjectiveTracker",
    "ProfessionsRecipeTracker",
    "BonusObjectiveTracker",
    "WorldQuestObjectiveTracker",
}

-- Debounce flag
local pendingBackdropUpdate = false

-- Get LibCustomGlow
local LCG = LibStub("LibCustomGlow-1.0", true)

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

local function GetSettings()
    if ns.db and ns.db.profile and ns.db.profile.styling and ns.db.profile.styling.objectives then
        return ns.db.profile.styling.objectives
    end
    return nil
end

local function GetColors()
    local sr, sg, sb, sa = ns.GetAccentColor()
    local br, bg, bb, ba = ns.GetThemeBgColor()
    -- Ensure alpha defaults if nil
    return sr, sg, sb, sa, br, bg, bb, (ba or 0.95)
end

local function GetFontPath()
    local path = ns.GetFont()
    return path or "Fonts\\FRIZQT__.TTF"
end

local function SafeSetTextColor(fontString, colorTable)
    if not fontString or not colorTable then return end
    if type(colorTable) ~= "table" or #colorTable < 3 then return end
    fontString:SetTextColor(colorTable[1] or 1, colorTable[2] or 1, colorTable[3] or 1, colorTable[4] or 1)
end

-------------------------------------------------------------------------------
-- STYLE FUNCTIONS (Ported from GravityUI_old)
-------------------------------------------------------------------------------

local function KillNineSlice(nineSlice)
    if not nineSlice then return end
    nineSlice:Hide()
    nineSlice:SetAlpha(0)
    for _, region in ipairs({nineSlice:GetRegions()}) do
        if region:IsObjectType("Texture") then
            region:SetTexture(nil)
            region:SetAtlas(nil)
            region:Hide()
        end
    end
    local parts = {"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
                   "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center"}
    for _, part in ipairs(parts) do
        local tex = nineSlice[part]
        if tex then
            tex:SetTexture(nil)
            tex:SetAtlas(nil)
            tex:Hide()
        end
    end
end

local function StyleQuestPOIIcon(button)
    if not button or button.guiStyled then return end
    if button.NormalTexture then button.NormalTexture:SetAlpha(0) end
    if button.PushedTexture then button.PushedTexture:SetAlpha(0) end
    if button.HighlightTexture then button.HighlightTexture:SetAlpha(0.3) end
    
    if LCG and LCG.PixelGlow_Stop then
        LCG.PixelGlow_Stop(button, "_guiQuestGlow")
    end
    button.guiStyled = true
end

local function StyleCompletionCheck(check)
    if not check or check.guiStyled then return end
    local sr, sg, sb = ns.GetAccentColor()
    check:SetAtlas("checkmark-minimal")
    check:SetDesaturated(true)
    check:SetVertexColor(sr, sg, sb)
    check.guiStyled = true
end

local function HandleQuestBlockIcons(tracker, block)
    if not block then return end
    local itemButton = block.ItemButton or block.itemButton
    if itemButton then StyleQuestPOIIcon(itemButton) end
    
    local check = block.currentLine and block.currentLine.Check
    if check then StyleCompletionCheck(check) end
end

local function SkinTrackerHeader(header)
    if not header then return end
    if header.Background then
        header.Background:SetAtlas(nil)
        header.Background:SetAlpha(0)
    end
    if header.Text then
        header.Text:ClearAllPoints()
        header.Text:SetPoint("LEFT", header, "LEFT", -7, 0)
        header.Text:SetJustifyH("LEFT")
    end
end

local function UpdateMinimizeButtonAtlas(btn, collapsed)
    if not btn then return end
    local normalTex = btn:GetNormalTexture()
    local pushedTex = btn:GetPushedTexture()
    if collapsed then
        if normalTex then normalTex:SetAtlas("ui-questtrackerbutton-secondary-expand") end
        if pushedTex then pushedTex:SetAtlas("ui-questtrackerbutton-secondary-expand-pressed") end
    else
        if normalTex then normalTex:SetAtlas("ui-questtrackerbutton-secondary-collapse") end
        if pushedTex then pushedTex:SetAtlas("ui-questtrackerbutton-secondary-collapse-pressed") end
    end
end

local function SyncBlizzardHeight()
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end
    local settings = GetSettings()
    local maxHeight = settings and settings.height or 600
    TrackerFrame.editModeHeight = maxHeight
    if TrackerFrame.UpdateHeight then TrackerFrame:UpdateHeight() end
end

local function HideScenarioStageArtwork()
    local scenario = _G.ScenarioObjectiveTracker
    if not scenario then return end
    local stageBlock = scenario.StageBlock
    if not stageBlock then return end
    
    if stageBlock.NormalBG then stageBlock.NormalBG:Hide(); stageBlock.NormalBG:SetAlpha(0) end
    if stageBlock.FinalBG then stageBlock.FinalBG:Hide(); stageBlock.FinalBG:SetAlpha(0) end
    if stageBlock.GlowTexture then stageBlock.GlowTexture:Hide(); stageBlock.GlowTexture:SetAlpha(0) end
    
    if stageBlock.Stage then
        stageBlock.Stage:ClearAllPoints()
        stageBlock.Stage:SetPoint("TOPLEFT", stageBlock, "TOPLEFT", 0, -5)
        if stageBlock.Name then
            stageBlock.Name:ClearAllPoints()
            stageBlock.Name:SetPoint("TOPLEFT", stageBlock.Stage, "BOTTOMLEFT", 0, -2)
        end
    end
end

local function IsScenarioActive()
    local scenario = _G.ScenarioObjectiveTracker
    if not scenario or not scenario:IsShown() then return false end
    if scenario.GetContentsHeight then
        local height = scenario:GetContentsHeight()
        if height and height > 0 then return true end
    end
    return false
end

local function ApplyMaxWidth(settings)
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end
    
    local maxWidth
    if IsScenarioActive() then
        maxWidth = 260
    else
        maxWidth = settings and settings.width or 260
    end
    TrackerFrame:SetWidth(maxWidth)
    
    if TrackerFrame.Header then
        TrackerFrame.Header:SetWidth(maxWidth)
        local minBtn = TrackerFrame.Header.MinimizeButton
        if minBtn then
            minBtn:ClearAllPoints()
            minBtn:SetPoint("RIGHT", TrackerFrame.Header, "RIGHT", 0, 0)
            minBtn:SetSize(16, 16)
            if not minBtn.guiHighlightSet and minBtn:GetHighlightTexture() then
                minBtn:GetHighlightTexture():SetAtlas("ui-questtrackerbutton-yellow-highlight")
                minBtn.guiHighlightSet = true
            end
        end
        
        if TrackerFrame.Header.SetCollapsed and not TrackerFrame.Header.guiSetCollapsedHooked then
            hooksecurefunc(TrackerFrame.Header, "SetCollapsed", function(self, collapsed)
                UpdateMinimizeButtonAtlas(self.MinimizeButton, collapsed)
            end)
            TrackerFrame.Header.guiSetCollapsedHooked = true
            local isCollapsed = false
            if type(TrackerFrame.IsCollapsed) == "function" then
                isCollapsed = TrackerFrame:IsCollapsed()
            end
            UpdateMinimizeButtonAtlas(minBtn, isCollapsed)
        end
    end
    
    for _, trackerName in ipairs(trackerModules) do
        local tracker = _G[trackerName]
        if tracker then
            tracker:SetWidth(maxWidth)
            if tracker.Header then tracker.Header:SetWidth(maxWidth) end
        end
    end
    
    HideScenarioStageArtwork()
end

local function UpdateBackdropAnchors()
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame or not TrackerFrame.guiBackdrop then return end
    
    local settings = GetSettings()
    local maxHeight = settings and settings.height or 600
    
    local bottomModule = nil
    local lowestBottom = math.huge
    
    for _, trackerName in ipairs(trackerModules) do
        local tracker = _G[trackerName]
        if tracker and tracker:IsShown() then
            local hasContent = false
            if tracker.GetContentsHeight then
                local contentHeight = tracker:GetContentsHeight()
                hasContent = contentHeight and contentHeight > 0
            end
            if not hasContent then
                local frameHeight = tracker:GetHeight()
                hasContent = frameHeight and frameHeight > 1
            end
            
            if hasContent then
                local bottom = tracker:GetBottom()
                if bottom and bottom < lowestBottom then
                    lowestBottom = bottom
                    bottomModule = tracker
                end
            end
        end
    end
    
    TrackerFrame.guiBackdrop:ClearAllPoints()
    TrackerFrame.guiBackdrop:SetPoint("TOPLEFT", TrackerFrame, "TOPLEFT", -15, 0)
    TrackerFrame.guiBackdrop:SetPoint("TOPRIGHT", TrackerFrame, "TOPRIGHT", 10, 0)
    
    if bottomModule then
        local trackerTop = TrackerFrame:GetTop()
        local contentHeight = 0
        if trackerTop and lowestBottom and trackerTop > lowestBottom then
            contentHeight = trackerTop - lowestBottom + 15
        end
        
        if contentHeight > maxHeight then
            TrackerFrame.guiBackdrop:SetHeight(maxHeight)
        else
            TrackerFrame.guiBackdrop:SetPoint("BOTTOM", bottomModule, "BOTTOM", 0, -15)
        end
        TrackerFrame.guiBackdrop:Show()
    else
        TrackerFrame.guiBackdrop:Hide()
    end
end

local function HidePOIButtonGlows()
    for _, trackerName in ipairs(trackerModules) do
        local tracker = _G[trackerName]
        if tracker and tracker.usedBlocks then
            for template, blocks in pairs(tracker.usedBlocks) do
                if type(blocks) == "table" then
                    for id, block in pairs(blocks) do
                        if block.poiButton and block.poiButton.Glow then
                            block.poiButton.Glow:Hide()
                            block.poiButton.Glow:SetAlpha(0)
                            if not block.poiButton.Glow.guiHooked then
                                hooksecurefunc(block.poiButton.Glow, "Show", function(self) self:Hide() end)
                                block.poiButton.Glow.guiHooked = true
                            end
                        end
                        if LCG and LCG.PixelGlow_Stop and block.poiButton then
                            LCG.PixelGlow_Stop(block.poiButton, "_guiQuestGlow")
                        end
                        local itemButton = block.ItemButton or block.itemButton
                        if LCG and LCG.PixelGlow_Stop and itemButton then
                            LCG.PixelGlow_Stop(itemButton, "_guiQuestGlow")
                        end
                    end
                end
            end
        end
    end
end

local function ScheduleBackdropUpdate()
    -- Only debounced update
    if pendingBackdropUpdate then return end
    pendingBackdropUpdate = true
    C_Timer.After(0.15, function()
        pendingBackdropUpdate = false
        UpdateBackdropAnchors()
        HidePOIButtonGlows()
    end)
end

local function ApplyguiBackdrop(trackerFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not trackerFrame then return end
    
    KillNineSlice(trackerFrame.NineSlice)
    
    if trackerFrame.SetBackgroundAlpha and not trackerFrame.guiBackgroundHooked then
        hooksecurefunc(trackerFrame, "SetBackgroundAlpha", function(self, alpha)
            if self.NineSlice then
                self.NineSlice:Hide()
                self.NineSlice:SetAlpha(0)
            end
            if self.guiBackdrop then
                local _, _, _, _, currBgR, currBgG, currBgB = GetColors()
                self.guiBackdrop:SetBackdropColor(currBgR, currBgG, currBgB, alpha)
            end
        end)
        trackerFrame.guiBackgroundHooked = true
    end
    
    local manager = _G.ObjectiveTrackerManager
    local opacity
    if manager and manager.backgroundAlpha ~= nil then
        opacity = manager.backgroundAlpha
    else
        opacity = bga or 0.95
    end
    
    if not trackerFrame.guiBackdrop then
        trackerFrame.guiBackdrop = CreateFrame("Frame", nil, trackerFrame, "BackdropTemplate")
        trackerFrame.guiBackdrop:SetFrameLevel(math.max(trackerFrame:GetFrameLevel() - 1, 0))
        trackerFrame.guiBackdrop:EnableMouse(false)
    end
    
    local settings = GetSettings()
    local hideBorder = settings and settings.hideBorder
    
    trackerFrame.guiBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = hideBorder and 0 or 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    trackerFrame.guiBackdrop:SetBackdropColor(bgr, bgg, bgb, opacity)
    if hideBorder then
        trackerFrame.guiBackdrop:SetBackdropBorderColor(0, 0, 0, 0)
    else
        trackerFrame.guiBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end
    
    UpdateBackdropAnchors()
end

-- Font Styling
local function StyleLine(line, fontPath, textFontSize, textColor)
    if not line then return end
    if line.Text then
        line.Text:SetFont(fontPath, textFontSize, FONT_FLAGS)
        SafeSetTextColor(line.Text, textColor)
    end
    if line.Dash then
        line.Dash:SetFont(fontPath, textFontSize, FONT_FLAGS)
        SafeSetTextColor(line.Dash, textColor)
    end
end

local function StyleBlock(block, fontPath, titleFontSize, textFontSize, titleColor, textColor)
    if not block then return end
    if titleFontSize > 0 and block.HeaderText then
        block.HeaderText:SetFont(fontPath, titleFontSize, FONT_FLAGS)
        SafeSetTextColor(block.HeaderText, titleColor)
    end
    if textFontSize > 0 and block.usedLines then
        for _, line in pairs(block.usedLines) do
            StyleLine(line, fontPath, textFontSize, textColor)
        end
    end
end

local function ApplyFontStyles(moduleFontSize, titleFontSize, textFontSize, moduleColor, titleColor, textColor)
    local fontPath = GetFontPath()
    
    for _, trackerName in ipairs(trackerModules) do
        local tracker = _G[trackerName]
        if tracker then
            if moduleFontSize > 0 and tracker.Header and tracker.Header.Text then
                tracker.Header.Text:SetFont(fontPath, moduleFontSize, FONT_FLAGS)
                SafeSetTextColor(tracker.Header.Text, moduleColor)
            end
            if tracker.usedBlocks then
                for template, blocks in pairs(tracker.usedBlocks) do
                    for blockID, block in pairs(blocks) do
                        StyleBlock(block, fontPath, titleFontSize, textFontSize, titleColor, textColor)
                    end
                end
            end
        end
    end
    
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if TrackerFrame and TrackerFrame.Header and TrackerFrame.Header.Text then
        if moduleFontSize > 0 then
            TrackerFrame.Header.Text:SetFont(fontPath, moduleFontSize, FONT_FLAGS)
            SafeSetTextColor(TrackerFrame.Header.Text, moduleColor)
        end
    end
end

local function HookLineCreation()
    local settings = GetSettings()
    if not settings then return end
    local textFontSize = settings.textFontSize or 0
    
    if ObjectiveTrackerBlockMixin and ObjectiveTrackerBlockMixin.AddObjective and not ObjectiveTrackerBlockMixin.guiAddObjectiveHooked then
        hooksecurefunc(ObjectiveTrackerBlockMixin, "AddObjective", function(self, objectiveKey)
            local line = self.usedLines and self.usedLines[objectiveKey]
            if line then
                local db = GetSettings()
                local size = db and db.textFontSize or 12
                local color = db and db.textColor
                if size > 0 then
                    StyleLine(line, GetFontPath(), size, color)
                end
            end
        end)
        ObjectiveTrackerBlockMixin.guiAddObjectiveHooked = true
    end
    
    if ObjectiveTrackerBlockMixin and ObjectiveTrackerBlockMixin.SetHeader and not ObjectiveTrackerBlockMixin.guiSetHeaderHooked then
        hooksecurefunc(ObjectiveTrackerBlockMixin, "SetHeader", function(self)
            local db = GetSettings()
            local size = db and db.titleFontSize or 13
            local color = db and db.titleColor
            if size > 0 and self.HeaderText then
                self.HeaderText:SetFont(GetFontPath(), size, FONT_FLAGS)
                SafeSetTextColor(self.HeaderText, color)
            end
        end)
        ObjectiveTrackerBlockMixin.guiSetHeaderHooked = true
    end
end

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

function Objectives:Initialize()
    local settings = GetSettings()
    if not settings or not settings.enabled then 
        if ObjectiveTrackerFrame and ObjectiveTrackerFrame.guiBackdrop then
            ObjectiveTrackerFrame.guiBackdrop:Hide()
        end
        return 
    end

    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()

    SyncBlizzardHeight()
    ApplyMaxWidth(settings)
    ApplyguiBackdrop(TrackerFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)

    local moduleFontSize = settings.moduleFontSize or 14
    local titleFontSize = settings.titleFontSize or 13
    local textFontSize = settings.textFontSize or 12
    local moduleColor = settings.moduleColor
    local titleColor = settings.titleColor
    local textColor = settings.textColor
    
    ApplyFontStyles(moduleFontSize, titleFontSize, textFontSize, moduleColor, titleColor, textColor)
    HookLineCreation()

    if TrackerFrame.Header then
        SkinTrackerHeader(TrackerFrame.Header)
    end
    for _, name in ipairs(trackerModules) do
        local tracker = _G[name]
        if tracker then SkinTrackerHeader(tracker.Header) end
    end

    -- Hooks
    if TrackerFrame.Update and not TrackerFrame.guiUpdateHooked then
        hooksecurefunc(TrackerFrame, "Update", ScheduleBackdropUpdate)
        TrackerFrame.guiUpdateHooked = true
    end
    if TrackerFrame.SetCollapsed and not TrackerFrame.guiCollapseHooked then
        hooksecurefunc(TrackerFrame, "SetCollapsed", ScheduleBackdropUpdate)
        TrackerFrame.guiCollapseHooked = true
    end

    for _, trackerName in ipairs(trackerModules) do
        local tracker = _G[trackerName]
        if tracker and not tracker.guiCollapseHooked then
            if tracker.Header and tracker.Header.MinimizeButton then
                tracker.Header.MinimizeButton:HookScript("OnClick", ScheduleBackdropUpdate)
            end
            if tracker.SetCollapsed then
                hooksecurefunc(tracker, "SetCollapsed", ScheduleBackdropUpdate)
            end
            if tracker.LayoutContents then
                hooksecurefunc(tracker, "LayoutContents", ScheduleBackdropUpdate)
            end
            if tracker.AddBlock and not tracker.guiAddBlockHooked then
                hooksecurefunc(tracker, "AddBlock", HandleQuestBlockIcons)
                tracker.guiAddBlockHooked = true
            end
            tracker.guiCollapseHooked = true
        end
    end

    if not TrackerFrame.guiSizeChangedHooked then
        TrackerFrame:HookScript("OnSizeChanged", UpdateBackdropAnchors)
        TrackerFrame.guiSizeChangedHooked = true
    end

    local manager = _G.ObjectiveTrackerManager
    if manager and manager.SetOpacity and not manager.guiOpacityHooked then
        hooksecurefunc(manager, "SetOpacity", function(self, opacityPercent)
            local alpha = (opacityPercent or 0) / 100
            local _, _, _, _, currBgR, currBgG, currBgB = GetColors()
            if TrackerFrame.guiBackdrop then
                TrackerFrame.guiBackdrop:SetBackdropColor(currBgR, currBgG, currBgB, alpha)
            end
        end)
        manager.guiOpacityHooked = true
    end

    C_Timer.After(0.5, HidePOIButtonGlows)
    TrackerFrame.guiSkinned = true
end

function Objectives:Refresh()
    self:Initialize()
end

-- Export for external refresh
_G.GravityUI_RefreshObjectiveTracker = function() Objectives:Refresh() end
