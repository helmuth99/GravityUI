local ADDON_NAME, ns = ...
local Objectives = ns.Addon:NewModule("Objectives", "AceEvent-3.0")
ns.Objectives = Objectives

-- ============================================================================
-- WEAK-KEYED CACHES (Anti-Taint Architecture)
-- ============================================================================
local _skinned = setmetatable({}, { __mode = "k" })
local _hookedTrackers = setmetatable({}, { __mode = "k" })
local _hookedBlocks = setmetatable({}, { __mode = "k" })
local _blockIcons = setmetatable({}, { __mode = "k" })
local _hookedPOIs = setmetatable({}, { __mode = "k" })
local _headerClickOverlays = setmetatable({}, { __mode = "k" })
local _blockTitleFSCache = setmetatable({}, { __mode = "k" })
local _eqtFontRegistry = setmetatable({}, { __mode = "k" })
local _masterHeaderCollapseHooked = false
local _masterHeaderShowHooked = false

local SUB_TRACKERS = {
    "ScenarioObjectiveTracker",
    "UIWidgetObjectiveTracker",
    "CampaignQuestObjectiveTracker",
    "QuestObjectiveTracker",
    "AdventureObjectiveTracker",
    "AchievementObjectiveTracker",
    "MonthlyActivitiesObjectiveTracker",
    "ProfessionsRecipeTracker",
    "ProfessionsRecipeObjectiveTracker",
    "ProfessionsCustomerOrdersTracker",
    "ProfessionsCustomerOrdersObjectiveTracker",
    "BonusObjectiveTracker",
    "WorldQuestObjectiveTracker",
    "InitiativeTasksObjectiveTracker",
    "DelvesObjectiveTracker",
}

-- ============================================================================
-- QUEST TYPE ICONS & CLASSIFICATION
-- ============================================================================
local QUEST_ICON_ATLAS = {
    normal    = nil,
    campaign  = "Crosshair_campaignquest_32",
    legendary = "Crosshair_legendaryquest_32",
    important = "Crosshair_important_48",
    recurring = "Crosshair_Recurring_48",
    daily     = "Crosshair_Recurring_48",
    weekly    = "Crosshair_Recurring_48",
    meta      = "Crosshair_Wrapper_48",
}

local QUEST_TURNIN_ATLAS = {
    campaign  = "Crosshair_campaignquestturnin_32",
    legendary = "Crosshair_legendaryquestturnin_32",
    important = "Crosshair_importantturnin_48",
    recurring = "Crosshair_Recurringturnin_48",
    daily     = "Crosshair_Recurringturnin_48",
    weekly    = "Crosshair_Recurringturnin_48",
    meta      = "Crosshair_Wrapperturnin_48",
}

local QUEST_ICON_SIZE_OVERRIDE = {
    recurring = 18,
    daily     = 18,
    weekly    = 18,
    important = 22,
}
local QUEST_ICON_SIZE = 16

local _classifyCache = {}

local function _computeClassification(questID)
    if not questID or not C_QuestLog then return nil end
    local logIdx = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
    local info = logIdx and C_QuestLog.GetInfo and C_QuestLog.GetInfo(logIdx)
    local cls = info and info.questClassification
    local freq = (info and info.frequency) or 0
    local done = C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID) or false

    local key = "normal"
    if C_CampaignInfo and C_CampaignInfo.IsCampaignQuest and C_CampaignInfo.IsCampaignQuest(questID) then
        key = "campaign"
    elseif cls and Enum and Enum.QuestClassification then
        local QC = Enum.QuestClassification
        if cls == QC.Important then
            key = "important"
        elseif cls == QC.Legendary then
            key = "legendary"
        elseif cls == QC.Campaign then
            key = "campaign"
        elseif cls == QC.Recurring then
            key = "recurring"
        end
    end
    if key == "normal" then
        if freq == 1 then
            key = "daily"
        elseif freq == 2 then
            key = "weekly"
        end
    end
    return { key = key, done = done }
end

local function ClassifyQuest(questID)
    if not questID then return nil, false end
    local entry = _classifyCache[questID]
    if not entry then
        entry = _computeClassification(questID)
        _classifyCache[questID] = entry
    end
    if not entry then return nil, false end
    local key = entry.key
    if entry.done and QUEST_TURNIN_ATLAS[key] then
        return QUEST_TURNIN_ATLAS[key], key
    end
    return QUEST_ICON_ATLAS[key], key
end

local function _refreshClassifyCache()
    if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries) then return end
    local seen = {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo and C_QuestLog.GetInfo(i)
        local qID = info and info.questID
        if qID then
            seen[qID] = true
            _classifyCache[qID] = _computeClassification(qID)
        end
    end
    for qID in pairs(_classifyCache) do
        if not seen[qID] then _classifyCache[qID] = nil end
    end
end

-- ============================================================================
-- HELPERS & COLOR RESOLUTION
-- ============================================================================
local function GetSettings()
    local db = ns.db and ns.db.profile and ns.db.profile.styling and ns.db.profile.styling.objectives
    return db or {}
end

local function GetBlockTitleFS(block)
    if not block then return nil end
    if block.HeaderText then return block.HeaderText end
    if block.Title then return block.Title end
    local cached = _blockTitleFSCache[block]
    if cached then return cached end
    if not block.GetRegions then return nil end
    for _, rg in ipairs({ block:GetRegions() }) do
        if rg.GetObjectType and rg:GetObjectType() == "FontString" then
            _blockTitleFSCache[block] = rg
            return rg
        end
    end
    return nil
end

local function GetPhysicalPixelSize(frame)
    local screenHeight = select(2, GetPhysicalScreenSize()) or 768
    local scale = UIParent:GetEffectiveScale()
    local es = (frame and frame.GetEffectiveScale and frame:GetEffectiveScale()) or scale
    if not es or es <= 0 then es = 1 end
    return (768 / screenHeight) / es
end

local function GetPlayerClassColor()
    local class = select(2, UnitClass("player"))
    local c = class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
    if c then return c.r, c.g, c.b end
    return 1.0, 1.0, 1.0
end

local function GetHeaderRGB()
    local s = GetSettings()
    if s.headerColorType == "class" then
        return GetPlayerClassColor()
    elseif s.headerColorType == "custom" and s.customHeaderColor then
        return s.customHeaderColor[1] or 1, s.customHeaderColor[2] or 1, s.customHeaderColor[3] or 1
    else
        local r, g, b = ns.GetAccentColor()
        return r or 0.047, g or 0.824, b or 0.624
    end
end

local function GetLineRGB()
    local s = GetSettings()
    if s.lineColorType == "class" then
        return GetPlayerClassColor()
    elseif s.lineColorType == "custom" and s.customLineColor then
        return s.customLineColor[1] or 1, s.customLineColor[2] or 1, s.customLineColor[3] or 1
    else
        local r, g, b = ns.GetAccentColor()
        return r or 0.047, g or 0.824, b or 0.624
    end
end

local function GetTitleRGB()
    local s = GetSettings()
    if s.customTitleColor then
        return s.customTitleColor[1] or 1.0, s.customTitleColor[2] or 0.910, s.customTitleColor[3] or 0.471
    end
    return 1.0, 0.910, 0.471
end

local function GetFocusRGB()
    local s = GetSettings()
    if s.customFocusColor then
        return s.customFocusColor[1] or 0.871, s.customFocusColor[2] or 0.251, s.customFocusColor[3] or 1.0
    end
    return 0.871, 0.251, 1.0
end

local function GetCompletedRGB()
    local s = GetSettings()
    if s.customCompletedColor then
        return s.customCompletedColor[1] or 0.251, s.customCompletedColor[2] or 1.0, s.customCompletedColor[3] or 0.349
    end
    return 0.251, 1.0, 0.349
end

local function GetObjectiveRGB()
    local s = GetSettings()
    if s.customObjectiveColor then
        return s.customObjectiveColor[1] or 0.720, s.customObjectiveColor[2] or 0.720, s.customObjectiveColor[3] or 0.720
    end
    return 0.720, 0.720, 0.720
end

-- ============================================================================
-- TYPOGRAPHY & FONT HELPERS
-- ============================================================================
local function GetFont()
    return (ns.GetFont and ns.GetFont()) or "Fonts/FRIZQT__.TTF"
end

local function StyleFontString(fs, size)
    if not fs or not fs.SetFont then return end
    local font = GetFont()
    if not size then
        local _, cur = fs:GetFont()
        size = cur or 12
    end
    local ok = pcall(fs.SetFont, fs, font, size, "OUTLINE")
    if not ok then fs:SetFont("Fonts/FRIZQT__.TTF", size, "OUTLINE") end
    _eqtFontRegistry[fs] = size
end

local function StyleHeaderFS(fs)
    local s = GetSettings()
    StyleFontString(fs, s.headerFontSize or 14)
end

local function StyleTitleFS(fs)
    local s = GetSettings()
    StyleFontString(fs, s.titleFontSize or 14)
end

local function StyleObjectiveFS(fs)
    if not fs then return end
    local s = GetSettings()
    StyleFontString(fs, s.objectiveFontSize or 12)
    local r, g, b = GetObjectiveRGB()
    if fs.SetTextColor then
        fs:SetTextColor(r, g, b)
    end
end

-- ============================================================================
-- TEXTURE STRIPPING
-- ============================================================================
local function StripTextures(frame, keep)
    if not frame or not frame.GetRegions then return end
    keep = keep or {}
    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region:GetObjectType() == "Texture" and not keep[region] and region.SetTexture then
            region:SetTexture("")
        end
    end
end

-- ============================================================================
-- PROGRESS BAR & TIMER BAR SKINNING
-- ============================================================================
local function SkinProgressBar(bar)
    if not bar or type(bar) ~= "table" or not bar.IsObjectType then return end
    local s = GetSettings()
    if not s.objectiveTrackerSkinning then return end
    if s.modernSkinning == false then return end

    for _, k in ipairs({
        "Border", "BorderLeft", "BorderRight", "BorderMid",
        "Spark", "Glow", "Sheen",
    }) do
        local r = bar[k]
        if r and type(r) == "table" and r.SetAlpha then r:SetAlpha(0); r:Hide() end
    end

    local statusBar = bar.Bar or (bar:IsObjectType("StatusBar") and bar)
    if statusBar then
        statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        local r, g, b = ns.GetAccentColor()
        statusBar:SetStatusBarColor(r, g, b, 1)
        if statusBar.Spark then statusBar.Spark:SetAlpha(0); statusBar.Spark:Hide() end
        if statusBar.SetStatusBarDesaturated then statusBar:SetStatusBarDesaturated(true) end
    end

    if bar.Icon then
        bar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if not bar.IconBorder then
            local iconBg = CreateFrame("Frame", nil, bar, "BackdropTemplate")
            iconBg:SetAllPoints(bar.Icon)
            iconBg:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            iconBg:SetBackdropBorderColor(0, 0, 0, 1)
            bar.IconBorder = iconBg
        end
    end

    if not bar.GuiBackdrop then
        local bg = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        bg:SetAllPoints(bar)
        bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        bg:SetBackdropColor(0.12, 0.12, 0.12, 0.85)
        bg:SetBackdropBorderColor(0, 0, 0, 1)
        bg:SetFrameLevel(bar:GetFrameLevel() > 0 and bar:GetFrameLevel() - 1 or 0)
        bar.GuiBackdrop = bg
    end

    if bar.Label then
        StyleFontString(bar.Label, 11)
        bar.Label:SetTextColor(1, 1, 1, 1)
    end
    if statusBar and statusBar.Label then
        StyleFontString(statusBar.Label, 11)
        statusBar.Label:SetTextColor(1, 1, 1, 1)
    end
end

local function SkinTimerBar(bar)
    if not bar or type(bar) ~= "table" or not bar.IsObjectType then return end
    local s = GetSettings()
    if not s.objectiveTrackerSkinning then return end
    if s.modernSkinning == false then return end

    for _, k in ipairs({
        "Border", "BorderLeft", "BorderRight", "BorderMid",
        "Spark", "Glow", "Sheen",
    }) do
        local r = bar[k]
        if r and type(r) == "table" and r.SetAlpha then r:SetAlpha(0); r:Hide() end
    end

    local statusBar = bar.Bar or (bar:IsObjectType("StatusBar") and bar)
    if statusBar then
        statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        statusBar:SetStatusBarColor(1.00, 0.82, 0.20, 1)
        if statusBar.Spark then statusBar.Spark:SetAlpha(0); statusBar.Spark:Hide() end
    end

    if not bar.GuiBackdrop then
        local bg = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        bg:SetAllPoints(bar)
        bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        bg:SetBackdropColor(0.12, 0.12, 0.12, 0.85)
        bg:SetBackdropBorderColor(0, 0, 0, 1)
        bg:SetFrameLevel(bar:GetFrameLevel() > 0 and bar:GetFrameLevel() - 1 or 0)
        bar.GuiBackdrop = bg
    end

    if bar.Label then
        StyleFontString(bar.Label, 11)
        bar.Label:SetTextColor(1, 1, 1, 1)
    end
end

-- ============================================================================
-- POI & QUEST TYPE ICON MANAGEMENT
-- ============================================================================
local function SuppressPOI(block)
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    local pb = block and (block.poiButton or block.PoiButton)
    if not pb then return end

    local isModern = (s.modernSkinning ~= false)
    local thickness = isModern and (s.dividerThickness or 1) or 0
    local spacing = isModern and (s.dividerSpacing or 3) or 0
    local poiOffsetY = isModern and -(thickness + spacing) or -2

    local shouldHide = isModern and (not s.showQuestIcons)
    if shouldHide then
        if pb:IsShown() then pb:Hide() end
        pb:EnableMouse(false)
    else
        if not pb:IsShown() then pb:Show() end
        pb:EnableMouse(true)
        local scale = s.poiIconScale or 0.8
        pb:SetScale(scale)

        local parent = block or pb:GetParent()
        if parent and (pb._gui_parent ~= parent) then
            pb._gui_parent = parent
            pb:ClearAllPoints()
            local offsetX = -(math.floor(24 * scale) + 8)
            pb:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, poiOffsetY)
        end
    end

    if not _hookedPOIs[pb] then
        _hookedPOIs[pb] = true
        hooksecurefunc(pb, "Show", function(self)
            local cur = GetSettings()
            if cur.objectiveTrackerSkinning == false then return end
            local curModern = (cur.modernSkinning ~= false)
            local hide = curModern and (not cur.showQuestIcons)
            if hide then
                self:Hide()
            else
                local scale = cur.poiIconScale or 0.8
                self:SetScale(scale)
                local parent = self:GetParent()
                if parent and (self._gui_parent ~= parent) then
                    self._gui_parent = parent
                    self:ClearAllPoints()
                    local curThickness = curModern and (cur.dividerThickness or 1) or 0
                    local curSpacing = curModern and (cur.dividerSpacing or 3) or 0
                    local curOffsetY = curModern and -(curThickness + curSpacing) or -2
                    local offsetX = -(math.floor(24 * scale) + 8)
                    self:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, curOffsetY)
                end
            end
        end)
    end
end

local function ApplyQuestTypeIcon(block)
    if not block then return end
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false or s.modernSkinning == false or s.showQuestIcons then
        if _blockIcons[block] then _blockIcons[block]:Hide() end
        return
    end

    local qID = block.id
    if type(qID) ~= "number" then
        if _blockIcons[block] then _blockIcons[block]:Hide() end
        return
    end

    -- Never overlay or block native ItemButton or GroupFinderButton!
    local hasItem = (block.ItemButton and block.ItemButton.IsShown and block.ItemButton:IsShown())
                 or (block.itemButton and block.itemButton.IsShown and block.itemButton:IsShown())
    local hasLFG  = (block.groupFinderButton and block.groupFinderButton.IsShown and block.groupFinderButton:IsShown())
                 or (block.GroupFinderButton and block.GroupFinderButton.IsShown and block.GroupFinderButton:IsShown())
                 or (block.rightEdgeFrame and block.rightEdgeFrame.IsShown and block.rightEdgeFrame:IsShown())
    if hasItem or hasLFG then
        if _blockIcons[block] then _blockIcons[block]:Hide() end
        return
    end

    local atlas, key = ClassifyQuest(qID)
    if not atlas then
        if _blockIcons[block] then _blockIcons[block]:Hide() end
        return
    end

    local isModern = (s.modernSkinning ~= false)
    local thickness = isModern and (s.dividerThickness or 1) or 0
    local spacing = isModern and (s.dividerSpacing or 3) or 0
    local iconOffsetY = 3 - (thickness + spacing)

    local ico = _blockIcons[block]
    if not ico then
        ico = block:CreateTexture(nil, "OVERLAY")
        ico:SetPoint("TOPRIGHT", block, "TOPRIGHT", -2, iconOffsetY)
        _blockIcons[block] = ico
    else
        ico:ClearAllPoints()
        ico:SetPoint("TOPRIGHT", block, "TOPRIGHT", -2, iconOffsetY)
    end
    if ico._lastAtlas ~= atlas then
        ico._lastAtlas = atlas
        local size = QUEST_ICON_SIZE_OVERRIDE[key] or QUEST_ICON_SIZE
        ico:SetSize(size, size)
        ico:SetAtlas(atlas)
    end
    ico:SetAlpha(1)
    ico:Show()
end

-- ============================================================================
-- HEADER SKINNING & SPACING (MODERN & CLASSIC)
-- ============================================================================
local function UpdateTrackerHeaderSpacing(tracker)
    if not tracker then return end
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    local isModern = (s.modernSkinning ~= false)

    if tracker._gui_origFromHeaderOffsetY == nil then
        tracker._gui_origFromHeaderOffsetY = tracker.fromHeaderOffsetY or 0
    end

    if isModern then
        local thickness = s.dividerThickness or 1
        local spacing = s.dividerSpacing or 3
        tracker.fromHeaderOffsetY = -(thickness + spacing)
    else
        tracker.fromHeaderOffsetY = tracker._gui_origFromHeaderOffsetY
    end
end

local function SkinHeader(header, isMain)
    if not header then return end
    local s = GetSettings()
    if not s.objectiveTrackerSkinning then return end

    local guiFont = GetFont()
    local textRegion = header.Text or header.Title
    if not textRegion then
        for _, region in ipairs({ header:GetRegions() }) do
            if region:IsObjectType("FontString") then
                textRegion = region
                break
            end
        end
    end

    local isModern = (s.modernSkinning ~= false)

    if isModern then
        -- --------------------------------------------------------------------
        -- MODERN SKINNING MODE
        -- --------------------------------------------------------------------
        if header.GuiBg then header.GuiBg:Hide() end
        if header.AccentBar then header.AccentBar:Hide() end

        for _, k in ipairs({
            "Background", "Line", "LineSheen", "LineGlow", "Divider",
            "Sheen", "Glow", "Stripe",
        }) do
            local reg = header[k]
            if reg and reg.SetTexture then reg:SetTexture("") end
        end

        local minBtn = header.MinimizeButton
        local keep = {}
        if minBtn and minBtn.GetRegions then
            for _, region in ipairs({ minBtn:GetRegions() }) do
                keep[region] = true
            end
        end
        StripTextures(header, keep)

        if textRegion then
            local hr, hg, hb = GetHeaderRGB()
            textRegion:SetTextColor(hr, hg, hb, 1)
            StyleHeaderFS(textRegion)
        end

        if minBtn then
            local hr, hg, hb = GetHeaderRGB()
            local function tint(tex)
                if not tex then return end
                if tex.SetDesaturated then tex:SetDesaturated(true) end
                if tex.SetVertexColor then tex:SetVertexColor(hr, hg, hb) end
            end
            tint(minBtn.GetNormalTexture and minBtn:GetNormalTexture())
            tint(minBtn.GetPushedTexture and minBtn:GetPushedTexture())
            tint(minBtn.GetHighlightTexture and minBtn:GetHighlightTexture())
            tint(minBtn.GetDisabledTexture and minBtn:GetDisabledTexture())
            if minBtn.GetRegions then
                for _, rg in ipairs({ minBtn:GetRegions() }) do
                    if rg:GetObjectType() == "Texture" then tint(rg) end
                end
            end
        end

        -- Pixel-perfect accent divider line with configurable thickness
        if not header.DividerLine then
            header.DividerLine = header:CreateTexture(nil, "OVERLAY", nil, 7)
            header.DividerLine:SetTexture("Interface\\Buttons\\WHITE8X8")
            if header.DividerLine.SetSnapToPixelGrid then
                header.DividerLine:SetSnapToPixelGrid(false)
                header.DividerLine:SetTexelSnappingBias(0)
            end
        end
        local thickness = s.dividerThickness or 1
        local px = GetPhysicalPixelSize(header) * thickness
        header.DividerLine:ClearAllPoints()
        header.DividerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
        header.DividerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
        header.DividerLine:SetHeight(px)
        local lr, lg, lb = GetLineRGB()
        header.DividerLine:SetColorTexture(lr, lg, lb, 1)
        header.DividerLine:Show()

        -- Update header spacing on parent tracker
        local tracker = header.parentModule or header.module or (header.GetParent and header:GetParent())
        if tracker and type(tracker) == "table" and tracker.fromHeaderOffsetY ~= nil then
            UpdateTrackerHeaderSpacing(tracker)
        end

        if not _headerClickOverlays[header] and header.MinimizeButton then
            local mb = header.MinimizeButton
            local overlay = CreateFrame("Button", nil, header)
            overlay:SetFrameLevel(header:GetFrameLevel() + 1)
            overlay:RegisterForClicks("LeftButtonUp")
            overlay:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
            overlay:SetPoint("BOTTOMRIGHT", mb, "BOTTOMLEFT", -2, 0)
            overlay:SetScript("OnClick", function()
                if InCombatLockdown() then return end
                if mb and mb:IsShown() and mb.Click then
                    mb:Click()
                end
            end)
            _headerClickOverlays[header] = overlay
        end

    else
        -- --------------------------------------------------------------------
        -- CLASSIC / LEGACY SKINNING MODE
        -- --------------------------------------------------------------------
        if header.DividerLine then header.DividerLine:Hide() end

        local regions = { header:GetRegions() }
        for _, region in ipairs(regions) do
            if region:IsObjectType("Texture") then
                local isSafe = false
                if header.GuiBg and region == header.GuiBg then isSafe = true end
                if header.AccentBar and region == header.AccentBar then isSafe = true end
                local name = region:GetName() or ""
                if name:find("Icon") or name:find("Widget") or name:find("Timer") then
                    isSafe = true
                end
                if not isSafe then
                    region:SetAlpha(0)
                    region:Hide()
                end
            end
        end
        if header.Background then header.Background:Hide(); header.Background:SetAlpha(0) end
        if header.Line then header.Line:Hide(); header.Line:SetAlpha(0) end

        local fontR, fontG, fontB = ns.GetAccentColor()
        local fontA = 1
        if s.disableThemeColorForHeaderFont and s.customHeaderFontColor then
            fontR, fontG, fontB, fontA = unpack(s.customHeaderFontColor)
        end
        if textRegion then
            textRegion:SetFont(guiFont, isMain and 16 or 14, "OUTLINE")
            textRegion:SetTextColor(fontR, fontG, fontB, fontA)
            if not isMain then
                textRegion:ClearAllPoints()
                textRegion:SetPoint("LEFT", header, "LEFT", 10, 0)
            end
        end

        if not header.GuiBg then
            local bg = CreateFrame("Frame", nil, header, "BackdropTemplate")
            bg:SetAllPoints()
            bg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            bg:SetFrameLevel(header:GetFrameLevel() > 0 and header:GetFrameLevel() - 1 or 0)
            header.GuiBg = bg

            local bar = header:CreateTexture(nil, "OVERLAY")
            bar:SetTexture("Interface\\Buttons\\WHITE8X8")
            bar:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
            bar:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
            bar:SetWidth(4)
            header.AccentBar = bar
        end

        local width = s.width or 235
        header.GuiBg:ClearAllPoints()
        if isMain then
            header.GuiBg:SetPoint("TOPLEFT", 0, -5)
            header.GuiBg:SetPoint("BOTTOMLEFT", 0, 5)
            header.GuiBg:SetWidth(width + 20)
        else
            header.GuiBg:SetPoint("TOPLEFT", 0, 0)
            header.GuiBg:SetPoint("BOTTOMLEFT", 0, 0)
            header.GuiBg:SetWidth(width)
        end

        local tr, tg, tb, ta = ns.GetThemeBgColor()
        local bgR, bgG, bgB, bgA = tr, tg, tb, ta
        if s.disableThemeColorForBackground and s.customBackgroundColor then
            bgR, bgG, bgB, bgA = unpack(s.customBackgroundColor)
        end
        if s.backgroundOpacity then bgA = s.backgroundOpacity end
        header.GuiBg:SetBackdropColor(bgR, bgG, bgB, bgA)
        header.GuiBg:Show()

        local barR, barG, barB, barA = ns.GetAccentColor()
        if s.cosmeticBar and s.cosmeticBar.disableThemeColor and s.cosmeticBar.color then
            barR, barG, barB, barA = unpack(s.cosmeticBar.color)
        end
        local barW = (s.cosmeticBar and s.cosmeticBar.width) or 4
        header.AccentBar:SetWidth(barW)
        header.AccentBar:SetColorTexture(barR, barG, barB, barA)
        if s.cosmeticBar and s.cosmeticBar.enable == false then
            header.AccentBar:Hide()
        else
            header.AccentBar:Show()
        end
    end
end

-- ============================================================================
-- SUPER-TRACKING & QUEST BLOCK HIGHLIGHTING
-- ============================================================================
local _superTrackedID = nil
local function GetSuperTrackedIDCached() return _superTrackedID end

local function ApplyFocusHighlight(block)
    if not block then return end
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    if s.modernSkinning == false then return end

    local fs = GetBlockTitleFS(block)
    if not fs then return end
    local qID = (type(block.id) == "number") and block.id or nil
    local isFocus = qID and (qID == GetSuperTrackedIDCached())
    local isDone = qID and C_QuestLog and C_QuestLog.IsComplete and C_QuestLog.IsComplete(qID)
    local r, g, b
    if isFocus then
        r, g, b = GetFocusRGB()
    elseif isDone then
        r, g, b = GetCompletedRGB()
    else
        r, g, b = GetTitleRGB()
    end
    fs:SetTextColor(r, g, b)
end

-- ============================================================================
-- BLOCK & OBJECTIVE LINES SKINNING
-- ============================================================================
local function SharesWidgetPool(tracker)
    return tracker == _G.ScenarioObjectiveTracker
        or tracker == _G.UIWidgetObjectiveTracker
end

local function StyleObjectiveLine(line)
    if not line or not line.Text then return end
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    if s.modernSkinning == false then return end

    StyleObjectiveFS(line.Text)
    local r, g, b = GetObjectiveRGB()
    line.Text:SetTextColor(r, g, b)
    if line.Dash then
        StyleObjectiveFS(line.Dash)
        line.Dash:SetTextColor(r, g, b)
    end
    if line.GetRegions then
        for _, rg in ipairs({ line:GetRegions() }) do
            if rg:IsObjectType("FontString") and rg ~= line.Text and rg ~= line.Dash then
                StyleObjectiveFS(rg)
            end
        end
    end
end

local function SetupTitleLayout(block)
    if not block then return end
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    if s.modernSkinning == false then return end

    local fs = GetBlockTitleFS(block)
    if not fs then return end
    StyleTitleFS(fs)
    if fs.SetWordWrap then fs:SetWordWrap(false) end
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end

    local thickness = s.dividerThickness or 1
    local spacing = s.dividerSpacing or 3
    local titleOffsetY = -(thickness + spacing)

    if fs.GetNumPoints and fs:GetNumPoints() > 0 then
        local point, relTo, relPoint, x, y = fs:GetPoint(1)
        if point then
            fs:ClearAllPoints()
            fs:SetPoint(point, relTo, relPoint, x or 0, titleOffsetY)
        end
    end
    if fs.SetWidth then fs:SetWidth(s.width or 235) end
end

local function ProcessBlockChildren(frame, depth)
    if not frame or depth > 3 or not frame.GetChildren then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        if child.GetObjectType then
            local ok, otype = pcall(child.GetObjectType, child)
            if ok then
                if otype == "StatusBar" or child.Bar or (child.Label and child.Border) then
                    SkinProgressBar(child)
                elseif (otype == "Frame" or otype == "Button") and not child.Tooltip then
                    if child.GetRegions then
                        for _, rg in ipairs({ child:GetRegions() }) do
                            if rg:GetObjectType() == "Texture" then
                                local n = (rg.GetAtlas and rg:GetAtlas()) or ""
                                local l = n:lower()
                                if l:find("evergreen") or l:find("toast") or l:find("filigree") or l:find("shimmer") then
                                    rg:SetTexture("")
                                end
                            elseif rg:GetObjectType() == "FontString" then
                                StyleObjectiveFS(rg)
                            end
                        end
                    end
                    ProcessBlockChildren(child, depth + 1)
                end
            end
        end
    end
end

local function SkinBlock(block)
    if not block then return end
    local s = GetSettings()
    if not s.objectiveTrackerSkinning then return end
    if s.modernSkinning == false then return end

    -- Suppress or scale bulky Blizzard round POI button
    SuppressPOI(block)

    -- Ensure item button and group finder button have high frame levels
    local bl = block.GetFrameLevel and block:GetFrameLevel() or 0
    if block.ItemButton and block.ItemButton.SetFrameLevel then
        block.ItemButton:SetFrameLevel(bl + 5)
    end
    if block.GroupFinderButton and block.GroupFinderButton.SetFrameLevel then
        block.GroupFinderButton:SetFrameLevel(bl + 5)
    end

    if _skinned[block] then
        ApplyQuestTypeIcon(block)
        ApplyFocusHighlight(block)
        return
    end

    -- Setup title typography & layout once per block
    SetupTitleLayout(block)

    -- Reassert title color on hover
    if not _hookedBlocks[block] then
        _hookedBlocks[block] = true
        local function reassertTitle() ApplyFocusHighlight(block) end
        if block.HookScript then
            block:HookScript("OnEnter", reassertTitle)
            block:HookScript("OnLeave", reassertTitle)
        end
        if block.HeaderButton and block.HeaderButton.HookScript then
            block.HeaderButton:HookScript("OnEnter", reassertTitle)
            block.HeaderButton:HookScript("OnLeave", reassertTitle)
        end
    end

    -- Strip named decorative textures
    for _, k in ipairs({
        "Background", "HeaderBackground", "Stripe", "Sheen", "Glow",
        "Highlight", "ShineTop", "ShineBottom",
    }) do
        local r = block[k]
        if r and r.SetTexture then r:SetTexture("") end
    end

    local titleFS = GetBlockTitleFS(block)
    local myIcon = _blockIcons[block]
    if block.GetRegions then
        for _, rg in ipairs({ block:GetRegions() }) do
            local ot = rg.GetObjectType and rg:GetObjectType()
            if ot == "Texture" then
                if rg ~= myIcon and rg.SetTexture then rg:SetTexture("") end
            elseif ot == "FontString" then
                if rg == titleFS then
                    StyleTitleFS(rg)
                else
                    StyleObjectiveFS(rg)
                end
            end
        end
    end
    if titleFS then StyleTitleFS(titleFS) end

    ApplyQuestTypeIcon(block)
    ApplyFocusHighlight(block)

    if block.ProgressBar then SkinProgressBar(block.ProgressBar) end
    if block.progressBar then SkinProgressBar(block.progressBar) end
    if block.TimerBar then SkinTimerBar(block.TimerBar) end
    if block.timerBar then SkinTimerBar(block.timerBar) end
    if block.lines then
        for _, line in pairs(block.lines) do
            StyleObjectiveLine(line)
        end
    end
    ProcessBlockChildren(block, 0)

    _skinned[block] = true
end

-- ============================================================================
-- MASTER "ALL OBJECTIVES" HEADER VISIBILITY
-- ============================================================================
local function ApplyMasterHeaderVisibility()
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    local otf = _G.ObjectiveTrackerFrame
    if not otf then return end
    local header = otf.HeaderMenu or otf.Header
    if not header then return end

    local isModern = (s.modernSkinning ~= false)
    local shouldHide = isModern and (s.hideMasterHeader ~= false)

    if not _masterHeaderShowHooked then
        _masterHeaderShowHooked = true
        header:HookScript("OnShow", function(self)
            local cur = GetSettings()
            if cur.objectiveTrackerSkinning == false then return end
            if (cur.modernSkinning ~= false) and (cur.hideMasterHeader ~= false) then
                self:Hide()
            end
        end)
    end

    if shouldHide then
        header:Hide()
    else
        header:Show()
    end
end

-- ============================================================================
-- TRACKER HOOKING & ITERATION
-- ============================================================================
local function SkinExistingBlocks(tracker)
    if not tracker then return end
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    UpdateTrackerHeaderSpacing(tracker)
    if tracker.Header then SkinHeader(tracker.Header) end
    if SharesWidgetPool(tracker) then return end

    if tracker.progressBarPool and tracker.progressBarPool.EnumerateActive then
        for bar in tracker.progressBarPool:EnumerateActive() do
            SkinProgressBar(bar)
        end
    end
    if tracker.timerBarPool and tracker.timerBarPool.EnumerateActive then
        for bar in tracker.timerBarPool:EnumerateActive() do
            SkinTimerBar(bar)
        end
    end

    if tracker.usedBlocks then
        for _, byTemplate in pairs(tracker.usedBlocks) do
            if type(byTemplate) == "table" then
                if byTemplate.GetNumPoints then
                    SkinBlock(byTemplate)
                else
                    for _, block in pairs(byTemplate) do
                        if type(block) == "table" then
                            SkinBlock(block)
                            if block.lines then
                                for _, line in pairs(block.lines) do
                                    StyleObjectiveLine(line)
                                end
                            end
                            if block.usedProgressBars then
                                for _, bar in pairs(block.usedProgressBars) do
                                    SkinProgressBar(bar)
                                end
                            end
                            if block.usedTimerBars then
                                for _, bar in pairs(block.usedTimerBars) do
                                    SkinTimerBar(bar)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function HookTracker(tracker)
    if not tracker then return end
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    UpdateTrackerHeaderSpacing(tracker)
    if _hookedTrackers[tracker] then return end
    _hookedTrackers[tracker] = true

    if SharesWidgetPool(tracker) then
        if tracker.Header then SkinHeader(tracker.Header) end
        if tracker.Update then
            hooksecurefunc(tracker, "Update", function(self)
                if self.Header then SkinHeader(self.Header) end
            end)
        end
        return
    end

    if tracker.Header then
        SkinHeader(tracker.Header)
        if tracker.Header.SetCollapsed then
            hooksecurefunc(tracker.Header, "SetCollapsed", function(self)
                SkinHeader(self)
            end)
        end
    end

    if tracker.AddBlock then
        hooksecurefunc(tracker, "AddBlock", function(_, block)
            if block then _skinned[block] = nil end
            SkinBlock(block)
        end)
    end

    if tracker.AddObjective then
        hooksecurefunc(tracker, "AddObjective", function(_, _, line)
            if line and type(line) == "table" and line.IsObjectType then StyleObjectiveLine(line) end
        end)
    end

    if tracker.LayoutContents then
        hooksecurefunc(tracker, "LayoutContents", function(self)
            local t = self
            C_Timer.After(0, function()
                if t.progressBarPool and t.progressBarPool.EnumerateActive then
                    for bar in t.progressBarPool:EnumerateActive() do
                        SkinProgressBar(bar)
                    end
                end
                if t.timerBarPool and t.timerBarPool.EnumerateActive then
                    for bar in t.timerBarPool:EnumerateActive() do
                        SkinTimerBar(bar)
                    end
                end
            end)
        end)
    end

    SkinExistingBlocks(tracker)
    C_Timer.After(0.5, function() SkinExistingBlocks(tracker) end)
end

local function EachTracker(fn)
    local seen = {}
    local otf = _G.ObjectiveTrackerFrame
    local modules = otf and (otf.modules or otf.MODULES)
    if modules then
        for _, t in ipairs(modules) do
            if t and not seen[t] then
                seen[t] = true
                fn(t)
            end
        end
    end
    if ObjectiveTrackerManager and ObjectiveTrackerManager.moduleToContainerMap then
        for t in pairs(ObjectiveTrackerManager.moduleToContainerMap) do
            if t and not seen[t] then
                seen[t] = true
                fn(t)
            end
        end
    end
    for _, name in ipairs(SUB_TRACKERS) do
        local t = _G[name]
        if t and not seen[t] then
            seen[t] = true
            fn(t)
        end
    end
end

-- ============================================================================
-- AUTO-HIDE LOGIC
-- ============================================================================
local function TrackerHasRealContent(tracker)
    if not tracker then return false end

    if tracker.HasContents then
        local ok, has = pcall(tracker.HasContents, tracker)
        if ok and has == true then return true end
    end

    if tracker.usedBlocks and type(tracker.usedBlocks) == "table" and next(tracker.usedBlocks) ~= nil then
        return true
    end
    if tracker.currentBlocks and type(tracker.currentBlocks) == "table" and next(tracker.currentBlocks) ~= nil then
        return true
    end
    if tracker.numBlocks and type(tracker.numBlocks) == "number" and tracker.numBlocks > 0 then
        return true
    end
    if tracker.GetNumBlocks then
        local ok, num = pcall(tracker.GetNumBlocks, tracker)
        if ok and type(num) == "number" and num > 0 then return true end
    end

    if tracker.ContentsFrame and tracker.ContentsFrame.GetChildren then
        local children = { tracker.ContentsFrame:GetChildren() }
        for _, c in ipairs(children) do
            if c and c:IsShown() and c.GetHeight and c:GetHeight() > 10 then
                return true
            end
        end
    end

    return false
end

local function HasAnyTrackerContent()
    if not ObjectiveTrackerFrame then return false end

    if ObjectiveTrackerManager then
        if ObjectiveTrackerManager.GetTrackers then
            local ok, list = pcall(ObjectiveTrackerManager.GetTrackers, ObjectiveTrackerManager)
            if ok and type(list) == "table" then
                for _, tracker in ipairs(list) do
                    if tracker ~= ObjectiveTrackerFrame.HeaderMenu and TrackerHasRealContent(tracker) then
                        return true
                    end
                end
            end
        end
        if ObjectiveTrackerManager.trackers and type(ObjectiveTrackerManager.trackers) == "table" then
            for _, tracker in pairs(ObjectiveTrackerManager.trackers) do
                if tracker ~= ObjectiveTrackerFrame.HeaderMenu and TrackerHasRealContent(tracker) then
                    return true
                end
            end
        end
    end

    for _, name in ipairs(SUB_TRACKERS) do
        local tracker = _G[name]
        if tracker and TrackerHasRealContent(tracker) then
            return true
        end
    end

    if ObjectiveTrackerFrame.MODULES then
        for _, module in pairs(ObjectiveTrackerFrame.MODULES) do
            if module ~= ObjectiveTrackerFrame.HeaderMenu and TrackerHasRealContent(module) then
                return true
            end
        end
    end

    if C_QuestLog then
        local ok1, qw = pcall(C_QuestLog.GetNumQuestWatches)
        if ok1 and type(qw) == "number" and qw > 0 then return true end
        local ok2, wqw = pcall(C_QuestLog.GetNumWorldQuestWatches)
        if ok2 and type(wqw) == "number" and wqw > 0 then return true end
    end

    if C_TradeSkillUI then
        if C_TradeSkillUI.GetTrackedRecipeIDs then
            local ok, list = pcall(C_TradeSkillUI.GetTrackedRecipeIDs)
            if ok and type(list) == "table" and #list > 0 then return true end
        end
        if C_TradeSkillUI.GetTrackedRecipes then
            local ok, list = pcall(C_TradeSkillUI.GetTrackedRecipes)
            if ok and type(list) == "table" and #list > 0 then return true end
        end
    end

    if C_ContentTracking and C_ContentTracking.GetTrackedIDs then
        for trackTypeID = 0, 10 do
            local ok, list = pcall(C_ContentTracking.GetTrackedIDs, trackTypeID)
            if ok and type(list) == "table" and #list > 0 then
                return true
            end
        end
    end

    if GetNumTrackedAchievements then
        local ok, count = pcall(GetNumTrackedAchievements)
        if ok and type(count) == "number" and count > 0 then return true end
    end

    if C_PerksProgram and C_PerksProgram.GetTrackedPerksActivities then
        local ok, list = pcall(C_PerksProgram.GetTrackedPerksActivities)
        if ok and type(list) == "table" and #list > 0 then return true end
    end

    return false
end

function Objectives:CheckAutoHide()
    local db = ns.db and ns.db.profile and ns.db.profile.styling and ns.db.profile.styling.objectives
    if not db or not db.objectiveTrackerSkinning then return end
    if not db.autoHideWhenEmpty then return end
    if not ObjectiveTrackerFrame then return end

    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
        if not ObjectiveTrackerFrame:IsShown() then ObjectiveTrackerFrame:Show() end
        return
    end

    local inInstance = IsInInstance and IsInInstance()
    if inInstance then
        if not ObjectiveTrackerFrame:IsShown() then ObjectiveTrackerFrame:Show() end
        return
    end

    if C_Scenario and C_Scenario.IsInScenario and C_Scenario.IsInScenario() then
        if not ObjectiveTrackerFrame:IsShown() then ObjectiveTrackerFrame:Show() end
        return
    end

    local hasContent = HasAnyTrackerContent()
    if hasContent then
        if not ObjectiveTrackerFrame:IsShown() then ObjectiveTrackerFrame:Show() end
    else
        if ObjectiveTrackerFrame:IsShown() then ObjectiveTrackerFrame:Hide() end
    end
end

-- ============================================================================
-- MAIN ENTRY POINTS & INITIALIZATION
-- ============================================================================
function Objectives:SkinTracker()
    local s = GetSettings()
    if not s.objectiveTrackerSkinning then return end
    if not ObjectiveTrackerFrame then return end

    local otf = ObjectiveTrackerFrame
    if otf.NineSlice then otf.NineSlice:Hide() end
    StripTextures(otf)

    local masterHeader = otf.HeaderMenu or otf.Header
    if masterHeader then
        SkinHeader(masterHeader, true)
        if masterHeader.SetCollapsed and not _masterHeaderCollapseHooked then
            _masterHeaderCollapseHooked = true
            hooksecurefunc(masterHeader, "SetCollapsed", function(self)
                SkinHeader(self, true)
            end)
        end
    end
    ApplyMasterHeaderVisibility()

    EachTracker(function(t)
        UpdateTrackerHeaderSpacing(t)
        HookTracker(t)
    end)

    self:CheckAutoHide()
end

function Objectives:Refresh()
    -- Reset skin flags so full restyle runs
    EachTracker(function(t)
        UpdateTrackerHeaderSpacing(t)
        if t.usedBlocks then
            for _, byTemplate in pairs(t.usedBlocks) do
                if type(byTemplate) == "table" then
                    for _, block in pairs(byTemplate) do
                        if type(block) == "table" then _skinned[block] = nil end
                    end
                end
            end
        end
        if t.Header then SkinHeader(t.Header) end
        SkinExistingBlocks(t)
        if t.MarkDirty then
            t:MarkDirty()
        end
    end)
    local otf = _G.ObjectiveTrackerFrame
    local masterHeader = otf and (otf.HeaderMenu or otf.Header)
    if masterHeader then SkinHeader(masterHeader, true) end
    ApplyMasterHeaderVisibility()
    -- FORBIDDEN: Never call ObjectiveTrackerManager:Update() from addon code.
    -- It runs Blizzard's entire quest machinery in our tainted execution context,
    -- and the tables it materializes stay tainted for the rest of the session.
    -- Cosmetic staleness self-heals on the next natural Blizzard relayout.
    self:CheckAutoHide()
end

local function UpdateAllFocusHighlights()
    local s = GetSettings()
    if s.objectiveTrackerSkinning == false then return end
    EachTracker(function(t)
        if SharesWidgetPool(t) then return end
        if t.usedBlocks then
            for _, byTemplate in pairs(t.usedBlocks) do
                if type(byTemplate) == "table" then
                    for _, block in pairs(byTemplate) do
                        if type(block) == "table" then
                            ApplyFocusHighlight(block)
                        end
                    end
                end
            end
        end
    end)
end

function Objectives:OnInitialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        _refreshClassifyCache()
        Objectives:SkinTracker()
    end)
    self:RegisterEvent("QUEST_WATCH_UPDATE", "CheckAutoHide")
    self:RegisterEvent("QUEST_LOG_UPDATE", function()
        _refreshClassifyCache()
        Objectives:CheckAutoHide()
    end)
    self:RegisterEvent("QUEST_ACCEPTED", function()
        _refreshClassifyCache()
        Objectives:CheckAutoHide()
    end)
    self:RegisterEvent("QUEST_REMOVED", function()
        _refreshClassifyCache()
        Objectives:CheckAutoHide()
    end)
    self:RegisterEvent("QUEST_WATCH_LIST_CHANGED", "CheckAutoHide")
    self:RegisterEvent("TRACKED_RECIPE_UPDATE", "CheckAutoHide")
    self:RegisterEvent("CONTENT_TRACKING_UPDATE", "CheckAutoHide")
    self:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE", "CheckAutoHide")
    self:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED", "CheckAutoHide")
    self:RegisterEvent("PERKS_PROGRAM_DATA_REFRESH", "CheckAutoHide")
    self:RegisterEvent("PERKS_ACTIVITY_COMPLETED", "CheckAutoHide")
    self:RegisterEvent("SCENARIO_UPDATE", "CheckAutoHide")
    self:RegisterEvent("CRITERIA_UPDATE", "CheckAutoHide")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckAutoHide")
    self:RegisterEvent("ZONE_CHANGED", "CheckAutoHide")

    -- Super-tracking event to update focus highlight (fast color-only path)
    self:RegisterEvent("SUPER_TRACKING_CHANGED", function()
        local s = GetSettings()
        if s.objectiveTrackerSkinning == false then return end
        if C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID then
            local id = C_SuperTrack.GetSuperTrackedQuestID()
            _superTrackedID = (id and id ~= 0) and id or nil
        end
        UpdateAllFocusHighlights()
    end)

    C_Timer.After(1, function() self:SkinTracker() end)
    C_Timer.After(3, function() self:SkinTracker() end)
    C_Timer.After(6, function() self:SkinTracker() end)

    if ObjectiveTracker_CollapseModule then
        hooksecurefunc("ObjectiveTracker_CollapseModule", function()
            C_Timer.After(0.1, function() self:SkinTracker() end)
        end)
    end
    if ObjectiveTracker_ExpandModule then
        hooksecurefunc("ObjectiveTracker_ExpandModule", function()
            C_Timer.After(0.1, function() self:SkinTracker() end)
        end)
    end

    if ObjectiveTrackerManager and ObjectiveTrackerManager.Update then
        hooksecurefunc(ObjectiveTrackerManager, "Update", function()
            self:CheckAutoHide()
        end)
    end

    if ObjectiveTrackerFrame and not ObjectiveTrackerFrame._gui_AutoHideHooked then
        ObjectiveTrackerFrame._gui_AutoHideHooked = true
        hooksecurefunc(ObjectiveTrackerFrame, "Show", function()
            if Objectives.isApplyingAutoHide then return end
            Objectives.isApplyingAutoHide = true
            Objectives:CheckAutoHide()
            Objectives.isApplyingAutoHide = false
        end)
    end
end

function Objectives:Initialize()
    self:OnInitialize()
end
