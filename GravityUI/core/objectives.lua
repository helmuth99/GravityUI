local ADDON_NAME, ns = ...
local Objectives = ns.Addon:NewModule("Objectives", "AceEvent-3.0")
ns.Objectives = Objectives

-- Helper to skin the Minimize/Collapse Button
-- Helper to skin the Minimize/Collapse Button
local function SkinMinimizeButton(button)
    if not button then return end
    
    -- If already skinned, just update state and exit
    if button.isSkinned then 
        if button.UpdateState then button:UpdateState() end
        return 
    end
    
    -- STATE CAPTURE FUNCS
    local function SetCollapsedVisual(val)
        button.isCollapsedVisual = val
        if button.Txt then 
            button.Txt:SetText(val and "+" or "-") 
            local r, g, b = ns.GetAccentColor()
            button.Txt:SetTextColor(r, g, b)
        end
    end
    
    local function CheckState(identifier)
         if type(identifier) == "string" then
    local function CheckState(identifier)
         if type(identifier) == "string" then
             -- Logic Interpretation: Action based
             -- Bucket + (Show Plus): We want to Expand (currently Closed)
             if string.find(identifier, "Plus") or string.find(identifier, "Expand") or string.find(identifier, "Closed") or string.find(identifier, "Maximize") then
                 SetCollapsedVisual(true)
                 return true
             -- Bucket - (Show Minus): We want to Collapse (currently Open)
             elseif string.find(identifier, "Minus") or string.find(identifier, "Collapse") or string.find(identifier, "Open") or string.find(identifier, "Minimize") then
                 SetCollapsedVisual(false)
                 return true
             end
         elseif type(identifier) == "number" then
             -- Plus
             if identifier == 130838 or identifier == 130835 or identifier == 130836 or identifier == 130837 then 
                 SetCollapsedVisual(true)
                 return true
             -- Minus
             elseif identifier == 130821 or identifier == 130822 or identifier == 130823 or identifier == 130824 then 
                 SetCollapsedVisual(false)
                 return true
             end
         end
         return false
    end
         elseif type(identifier) == "number" then
             -- Plus
             if identifier == 130838 or identifier == 130835 or identifier == 130836 or identifier == 130837 then 
                 SetCollapsedVisual(true)
                 return true
             -- Minus
             elseif identifier == 130821 or identifier == 130822 or identifier == 130823 or identifier == 130824 then 
                 SetCollapsedVisual(false)
                 return true
             end
         end
         return false
    end

    -- 1. Hook the Texture Object directly
    local normal = button:GetNormalTexture()
    
    -- Initial State Check
    if normal then
        local atlas = normal:GetAtlas()
        local tex = normal:GetTexture()
        if atlas then CheckState(atlas) end
        if tex then CheckState(tex) end
        
        -- Hooks
        hooksecurefunc(normal, "SetTexture", function(self, texture)
             if texture then
                 CheckState(texture)
                 self:SetAlpha(0)
             end
        end)
        
        hooksecurefunc(normal, "SetAtlas", function(self, atlas)
             if atlas then
                 CheckState(atlas)
                 self:SetAlpha(0)
             end
        end)
    end

    -- Clear other textures
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetAlpha(0) pushed:Hide() end
    local highlight = button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) highlight:Hide() end
    local disabled = button:GetDisabledTexture()
    if disabled then disabled:SetAlpha(0) disabled:Hide() end
    if button.SetPushedAtlas then hooksecurefunc(button, "SetPushedAtlas", function(self) self:SetPushedTexture(nil) end) end
    if button.SetHighlightAtlas then hooksecurefunc(button, "SetHighlightAtlas", function(self) self:SetHighlightTexture(nil) end) end

    for _, region in ipairs({button:GetRegions()}) do
        if region:IsObjectType("Texture") and region ~= normal then
            region:SetAlpha(0) 
            region:Hide()
        end
    end
    
    -- 2. Add Custom Text (+ / -)
    if not button.Txt then
        button.Txt = button:CreateFontString(nil, "OVERLAY")
        local guiFont = ns.GetFont()
        button.Txt:SetFont(guiFont, 18, "OUTLINE")
        button.Txt:SetPoint("CENTER", 0, 1)
    end
    
    -- 3. Update State
    local function UpdateState()
        -- Ensure Textures are dead
        if normal then normal:SetAlpha(0) end
        
        -- Priority 1: Trusted Visual State from Hooks
        if button.isCollapsedVisual ~= nil then
             -- Force text update in case it was missed
             button.Txt:SetText(button.isCollapsedVisual and "+" or "-")
             local r, g, b = ns.GetAccentColor()
             button.Txt:SetTextColor(r, g, b)
             return
        end
        
        -- Priority 2: Data State (Fallback)
        local isCollapsed = false
        
        -- A. Global Collapse
        if ObjectiveTrackerFrame.isCollapsed then
            isCollapsed = true
        end
        
        -- B. Module/Parent Collapse
        local parent = button:GetParent()
        if parent then
            -- 1. Direct bool on parent (common in some modules)
            if parent.isCollapsed then 
                isCollapsed = true 
            end
            
            -- 2. Module Instance check (Standard Blizzard)
            if parent.module then
                 if parent.module.collapsed then 
                     isCollapsed = true 
                 end
            end
            
            -- 3. Grandparent (Scenario/Delve Content Frames often nested)
            local gp = parent:GetParent()
            if gp then
                if gp.isCollapsed then isCollapsed = true end
                if gp.module and gp.module.collapsed then isCollapsed = true end
            end
        end
        
        button.Txt:SetText(isCollapsed and "+" or "-")
        local r, g, b = ns.GetAccentColor()
        button.Txt:SetTextColor(r, g, b)
    end
    
    -- Export for global hooks
    button.UpdateState = UpdateState
    UpdateState()
    
    if not button.hookedClick then
        button:HookScript("OnClick", function()
             C_Timer.After(0.1, UpdateState)
        end)
        button.hookedClick = true
    end
    
    button.isSkinned = true
end

-- Robust Helper to Skin a Header Frame
local function SkinHeaderFrame(header, isMain)
    if not header then return end
    
    local guiFont = ns.GetFont()
    local r, g, b = ns.GetAccentColor()
    local tr, tg, tb, ta = ns.GetThemeBgColor()
    
    -- (Legacy isSkinned check removed to allow Refresh/Updates)
    
    -- 1. Identify the Text Region
    local textRegion = header.Text or header.Title
    if not textRegion then
        for _, region in ipairs({header:GetRegions()}) do
            if region:IsObjectType("FontString") then
                textRegion = region
                break
            end
        end
    end
    
    -- 2. Hide Native Art (Textures) - SAFETY CHECK: Don't hide textures if they look like Icons or Widgets
    local regions = {header:GetRegions()}
    for _, region in ipairs(regions) do
        if region:IsObjectType("Texture") then
            -- Safe list
            local isSafe = false
            if header.GuiBg and region == header.GuiBg then isSafe = true end
            if header.AccentBar and region == header.AccentBar then isSafe = true end
            
            -- PROTECT: If texture has a specific name or is part of a widget, don't nuke it
            local name = region:GetName() or ""
            if name:find("Icon") or name:find("Widget") or name:find("Timer") then
                isSafe = true
            end

            if not isSafe then
                region:SetAlpha(0)
                -- region:SetTexture(nil) -- Too aggressive, might break things that are shown later
                region:Hide()
            end
        end
    end
    
    -- Explicit Nuke (Only known Blizzard header art)
    if header.Background then header.Background:Hide(); header.Background:SetAlpha(0) end
    if header.Line then header.Line:Hide(); header.Line:SetAlpha(0) end
    -- if header.Bar then header.Bar:Hide(); header.Bar:SetAlpha(0) end -- Some widgets use .Bar!
    
    -- 3. Style Text
    if textRegion then
        textRegion:SetFont(guiFont, isMain and 16 or 14, "OUTLINE")
        textRegion:SetTextColor(isMain and r or 1, isMain and g or 1, isMain and b or 1)
        if not isMain then
            textRegion:ClearAllPoints()
            textRegion:SetPoint("LEFT", header, "LEFT", 10, 0)
        end
    end
    
    -- 4. Create/Update Custom Backdrop
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
    
    -- Update Sizing (Width)
    local db = ns.db.profile.styling.objectives
    local width = db.width or 235
    
    -- Position Logic
    header.GuiBg:ClearAllPoints()
    if isMain then
         -- Main header logic
         header.GuiBg:SetPoint("TOPLEFT", 0, -5)
         header.GuiBg:SetPoint("BOTTOMLEFT", 0, 5)
         header.GuiBg:SetWidth(width + 20) -- Slightly wider for main container visual
    else
         -- Module header logic
         header.GuiBg:SetPoint("TOPLEFT", 0, 0)
         header.GuiBg:SetPoint("BOTTOMLEFT", 0, 0)
         header.GuiBg:SetWidth(width)
    end
    
    -- Apply Colors
    local bgR, bgG, bgB, bgA = tr, tg, tb, ta
    if db.disableThemeColorForBackground then
        if db.customBackgroundColor then
            bgR, bgG, bgB, bgA = unpack(db.customBackgroundColor)
        end
    end
    
    if db.backgroundOpacity then
        bgA = db.backgroundOpacity
    end
    
    header.GuiBg:SetBackdropColor(bgR, bgG, bgB, bgA)
    
    -- Cosmetic Bar Color
    local barR, barG, barB, barA = ns.GetAccentColor()
    if db.cosmeticBar and db.cosmeticBar.disableThemeColor then
        if db.cosmeticBar.color then
            barR, barG, barB, barA = unpack(db.cosmeticBar.color)
        end
    end
    header.AccentBar:SetColorTexture(barR, barG, barB, barA)
    
    -- Apply Font Color
    local fontR, fontG, fontB = ns.GetAccentColor()
    local fontA = 1
    
    if db.disableThemeColorForHeaderFont then
        if db.customHeaderFontColor then
            fontR, fontG, fontB, fontA = unpack(db.customHeaderFontColor)
        end
    end
    
    if textRegion then
        textRegion:SetTextColor(fontR, fontG, fontB, fontA)
    end
    
    header.isSkinned = true
    
    -- Minimize Button handling (Re-run to ensure it stays on top/correct)
    local btn = header.MinimizeButton
    if not btn then
        -- PERF: Cache GetChildren() once to avoid double vararg allocation per iteration.
        local headerChildren = {header:GetChildren()}
        for i = 1, #headerChildren do
            local child = headerChildren[i]
            if child:IsObjectType("Button") then
                local w = child:GetWidth()
                if w and w > 10 and w < 40 then btn = child break end
            end
        end
        header.MinimizeButton = btn 
    end
    if btn then SkinMinimizeButton(btn) end
end

-- Recursive Hunter to find Header Frames
local function FindHeadersRecursive(frame, depth)
    if not frame or depth > 6 then return end 
    
    -- PERF: Cache GetChildren() once to avoid double vararg allocation per iteration.
    local frameChildren = {frame:GetChildren()}
    for i = 1, #frameChildren do
        local child = frameChildren[i]
        local isHeader = false
        local isMain = false
        
        -- EXCLUSION: Skip frames that are known to be part of the content (Widgets, Timers, etc.)
        local name = child:GetName() or ""
        local isContent = name:find("Timer") or name:find("Widget") or name:find("Block")
        
        if not isContent then
            -- Method A: Structure Check (Most Reliable)
            -- Headers typically have a MinimizeButton and a Background (even if we hide it)
            if child.MinimizeButton and child.Background then
                isHeader = true
            end
            
            -- Method B: Keywords (Fallback)
            if not isHeader then
                for j = 1, select("#", child:GetRegions()) do
                    local r = select(j, child:GetRegions())
                    if r:IsObjectType("FontString") then
                        local t = r:GetText()
                        if t then
                            if t == "All Objectives" or t == "Alle Ziele" then
                                isHeader = true
                                isMain = true
                            end
                        end
                    end
                end
            end
        end
        
        if isHeader then
            -- Double check if it's the main header
            if child == ObjectiveTrackerFrame.HeaderMenu then isMain = true end
            SkinHeaderFrame(child, isMain)
        else
            -- If it's a content frame, specifically look into it for widgets but don't skin as header
            FindHeadersRecursive(child, depth + 1)
        end
    end
end

local function SkinWidgetsRecursive(frame)
    if not frame then return end
    -- PERF: Cache GetChildren() once to avoid double vararg allocation per iteration.
    local widgetChildren = {frame:GetChildren()}
    for i = 1, #widgetChildren do
        local child = widgetChildren[i]
        -- Check for Bar with Spark
        if child.Bar and child.Bar.Spark then
            child.Bar.Spark:SetAlpha(0)
            child.Bar.Spark:Hide()
        end
        -- Recurse
        SkinWidgetsRecursive(child)
    end
end

function Objectives:OnInitialize()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "SkinTracker")
    -- Auto-hide: react to quest watch changes
    self:RegisterEvent("QUEST_WATCH_UPDATE", "CheckAutoHide")
    self:RegisterEvent("QUEST_LOG_UPDATE", "CheckAutoHide")
    self:RegisterEvent("QUEST_ACCEPTED", "CheckAutoHide")
    self:RegisterEvent("QUEST_REMOVED", "CheckAutoHide")
    self:RegisterEvent("SCENARIO_UPDATE", "CheckAutoHide")
    self:RegisterEvent("CRITERIA_UPDATE", "CheckAutoHide")
    
    C_Timer.After(1, function() self:SkinTracker() end)
    C_Timer.After(3, function() self:SkinTracker() end)
    C_Timer.After(6, function() self:SkinTracker() end)
    
    -- Global Hooks for Collapse/Expand to force button updates
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
    

    
    if ObjectiveTrackerFrame and ObjectiveTrackerFrame.Update then
        hooksecurefunc(ObjectiveTrackerFrame, "Update", function() 
             if not self.updatePending then
                 self.updatePending = true
                 C_Timer.After(0.2, function() 
                     self.updatePending = false
                     self:SkinTracker() 
                 end)
             end
        end)
    end
end

-- Refresh for config changes
function Objectives:Refresh()
    self:SkinTracker()
end

function Objectives:SkinTracker()
    local db = ns.db.profile.styling.objectives
    if not db.objectiveTrackerSkinning then return end
    
    if not ObjectiveTrackerFrame then return end
    
    -- 1. Main Header (Proven Method)
    local mainHeader = ObjectiveTrackerFrame.HeaderMenu
    if mainHeader then
        SkinHeaderFrame(mainHeader, true)
    end
    
    -- 2. Recursive Scan
    FindHeadersRecursive(ObjectiveTrackerFrame, 1)
    
    -- 3. Specific Scenario Widget Skinning (Remove Sparks)
    if ScenarioObjectiveTracker and ScenarioObjectiveTracker.ContentsFrame then
         SkinWidgetsRecursive(ScenarioObjectiveTracker.ContentsFrame)
    end
    
    -- 4. Auto-hide check after skinning
    self:CheckAutoHide()
end

-- -------------------------------------------------------------------------
-- AUTO-HIDE: Hide the tracker when there is nothing to show.
-- GUARD: Never auto-hide inside any instance (dungeon, M+, raid, scenario)
--        because the tracker always shows relevant content there (M+ timer,
--        dungeon objectives, boss progress, scenario steps).
-- Only hides when the player has no quests tracked AND is in open world.
-- -------------------------------------------------------------------------
function Objectives:CheckAutoHide()
    local db = ns.db.profile.styling.objectives
    if not db.objectiveTrackerSkinning then return end
    if not db.autoHideWhenEmpty then return end
    if not ObjectiveTrackerFrame then return end

    -- GUARD: Never suppress the tracker inside any instance.
    -- IsInInstance() returns true for: dungeons, raids, M+ keys, scenarios.
    local inInstance = IsInInstance and IsInInstance()
    if inInstance then
        if not ObjectiveTrackerFrame:IsShown() then
            ObjectiveTrackerFrame:Show()
        end
        return
    end

    -- Also stay visible during active scenarios in the open world (e.g. Delves entrance)
    if C_Scenario and C_Scenario.IsInScenario and C_Scenario.IsInScenario() then
        if not ObjectiveTrackerFrame:IsShown() then
            ObjectiveTrackerFrame:Show()
        end
        return
    end

    local hasContent = false

    -- Method A: Iterate Blizzard modules (quests, scenarios, achievements, M+)
    if ObjectiveTrackerFrame.MODULES then
        for _, module in pairs(ObjectiveTrackerFrame.MODULES) do
            if module and module.HasContents and module:HasContents() then
                hasContent = true
                break
            end
            -- Fallback: check usedBlocks table (some modules don't implement HasContents)
            if not hasContent and module and module.usedBlocks then
                for _ in pairs(module.usedBlocks) do
                    hasContent = true
                    break
                end
            end
        end
    end

    -- Method B: Direct quest watch count (safety fallback if MODULES is unavailable)
    if not hasContent then
        local watchCount = C_QuestLog and C_QuestLog.GetNumQuestWatches and C_QuestLog.GetNumQuestWatches()
        if watchCount and watchCount > 0 then
            hasContent = true
        end
    end

    if hasContent then
        if not ObjectiveTrackerFrame:IsShown() then
            ObjectiveTrackerFrame:Show()
        end
    else
        if ObjectiveTrackerFrame:IsShown() then
            ObjectiveTrackerFrame:Hide()
        end
    end
end

function Objectives:Initialize()
    self:OnInitialize()
end
