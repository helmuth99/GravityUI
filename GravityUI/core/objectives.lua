local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = ns.Colors

-- Module
ns.Objectives = {}
local Objectives = ns.Objectives

-- LibSharedMedia
local LSM = LibStub("LibSharedMedia-3.0", true)
local LCG = LibStub("LibCustomGlow-1.0", true)

-- Constants
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

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

local function GetSettings()
    if ns.db and ns.db.profile and ns.db.profile.styling and ns.db.profile.styling.objectives then
        return ns.db.profile.styling.objectives
    end
    return nil
end

local function GetFontPath()
    local path = ns.GetFont()
    return path or STANDARD_TEXT_FONT
end

-- COLOR LOGIC:
-- 1. Global Use Class Color -> Class Color
-- 2. Else -> Primary Theme Color
-- 3. SPECIFIC OVERRIDE: If "Use Theme Color" in Objectives is OFF, use Custom Color.
local function GetObjectiveThemeColor()
    local settings = GetSettings()
    
    -- If "Use Theme Color" is enabled in Objectives settings, we follow global rules
    if settings.cosmeticBar.useThemeColor then
        -- Returns (r, g, b, a) based on Global Class Color or Global Theme Color
        return ns.GetAccentColor()
    else
        -- User wants specific custom color for objectives
        local c = settings.cosmeticBar.color
        return c[1], c[2], c[3], c[4] or 1
    end
end

local function GetBackdropColor()
    local c = ns.db.profile.general.themeBgColor
    local settings = GetSettings()
    local alpha = (settings and settings.backgroundOpacity) or 0.8
    return c[1], c[2], c[3], alpha
end

local function SafeSetTextColor(fontString, colorTable)
    if not fontString or not colorTable then return end
    fontString:SetTextColor(colorTable[1] or 1, colorTable[2] or 1, colorTable[3] or 1, colorTable[4] or 1)
end

-------------------------------------------------------------------------------
-- CORE STYLING
-------------------------------------------------------------------------------

local function KillNineSlice(nineSlice)
    if not nineSlice then return end
    nineSlice:Hide()
    nineSlice:SetAlpha(0)
    for _, region in ipairs({nineSlice:GetRegions()}) do
        if region:IsObjectType("Texture") then
            region:SetTexture(nil); region:SetAtlas(nil); region:Hide()
        end
    end
end

local function StyleQuestPOIIcon(button)
    if not button then return end
    
    -- Hide Backgrounds/Borders
    if button.NormalTexture then button.NormalTexture:SetAlpha(0) end
    if button.PushedTexture then button.PushedTexture:SetAlpha(0) end
    if button.HighlightTexture then button.HighlightTexture:SetAlpha(0) end 
    if button.Border then button.Border:SetAlpha(0) end
    if button.IconBorder then button.IconBorder:SetAlpha(0) end
    
    -- Helper to apply style safely
    local function ApplyStyle()
        -- Scale
        if button:GetScale() ~= 0.65 then
            button:SetScale(0.65)
        end
        
        -- Position
        -- Target X: -10px (Flush left)
        -- We try to set it relative to Parent TOPLEFT to force flush left
        local parent = button:GetParent()
        if parent then
            -- Check if we are already there to avoid spamming SetPoint
            local p, r, rp, x, y = button:GetPoint(1)
            if x ~= -10 then
                 button:ClearAllPoints()
                 button:SetPoint("TOPLEFT", parent, "TOPLEFT", -10, 0)
            end
        end
    end
    
    -- Apply immediately
    ApplyStyle()
    
    -- Re-apply one frame later to override Blizzard layout
    C_Timer.After(0.01, ApplyStyle)
    
    -- Hook OnShow (safely, no recursive hooksecurefunc on SetPoint)
    if not button.guiHookedShow then
        button:HookScript("OnShow", function()
             C_Timer.After(0.01, ApplyStyle)
        end)
        button.guiHookedShow = true
    end
end

local function HandleQuestBlockIcons(tracker, block)
    if not block then return end
    if block.ItemButton then StyleQuestPOIIcon(block.ItemButton) end
    if block.itemButton then StyleQuestPOIIcon(block.itemButton) end
end

local function SkinProgressBar(tracker, key)
     local progressBar = tracker.usedProgressBars[key]
     if not progressBar or not progressBar.Bar or progressBar.guiStyled then return end
     
     local bar = progressBar.Bar
     bar:SetStatusBarTexture(LSM:Fetch("statusbar", "Gravity"))
     
     if bar.Icon then
          -- Icon skinning logic could go here
          bar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
     end
     
     -- Use Theme Color for Progress
     local r, g, b = GetObjectiveThemeColor()
     bar:SetStatusBarColor(r, g, b)
     
     if bar.Label then
         bar.Label:SetFont(GetFontPath(), 12, "OUTLINE")
         bar.Label:ClearAllPoints()
         bar.Label:SetPoint("CENTER", bar, 0, 1)
     end
     
    progressBar.guiStyled = true
end

local function HandleBlockHeader(block)
    if not block or not block.HeaderText then return end
    
    local settings = GetSettings()
    if not settings then return end
    
    local text = block.HeaderText
    text:SetFont(GetFontPath(), settings.titleFontSize or 13, FONT_FLAGS)
    
    -- Color
    local r, g, b, a = 1, 1, 1, 1
    -- Logic: User requested to REMOVE "Use Theme Color" for Titles. Always use custom color.
    local c = settings.titleColor
    if c then r, g, b, a = c[1], c[2], c[3], c[4] or 1 end
    
    text:SetTextColor(r, g, b, a)
    
    -- Width / Wrapping
    -- Explicitly set width to force wrapping inside the container
    if settings.width then
        -- 20px left, 10px right padding = 30px
        text:SetWidth(settings.width - 30)
        text:SetWordWrap(true)
    end
    
    -- Force height to fit font changes if needed
    text:SetHeight(text:GetStringHeight() + 2)
    
    -- Lock Color to prevent hover changes (Yellow highlight)
    if not text.guiHookedColor then
        block.guiTargetColor = {r, g, b, a}
        hooksecurefunc(text, "SetTextColor", function(self, newR, newG, newB)
             if self.guiLocked then return end
             
             -- Compare with target
             local t = block.guiTargetColor
             -- Simple check: if not roughly equal, reset
             if not (math.abs(newR - t[1]) < 0.01 and math.abs(newG - t[2]) < 0.01) then
                 self.guiLocked = true
                 self:SetTextColor(t[1], t[2], t[3], t[4])
                 self.guiLocked = false
             end
        end)
        text.guiHookedColor = true
    else
        -- Update target color if settings changed
        block.guiTargetColor = {r, g, b, a}
        -- Re-apply immediately
        text.guiLocked = true
        text:SetTextColor(r, g, b, a)
        text.guiLocked = false
    end
end

-- Hook existing block handling
local function HandleBlockAdd(tracker, block)
    if not block then return end
    
    -- Gravity Cache: Store block for dynamic resizing
    if not tracker.gravityCache then tracker.gravityCache = {} end
    tracker.gravityCache[block] = true
    
    HandleQuestBlockIcons(tracker, block)
    HandleBlockHeader(block)
end

-------------------------------------------------------------------------------
-- COSMETIC BAR
-------------------------------------------------------------------------------
local function CreateCosmeticBar(header)
    if not header or not header.Text then return end
    local settings = GetSettings()
    if not settings.cosmeticBar.enable then 
        if header.guiCosmeticBar then header.guiCosmeticBar:Hide() end
        return 
    end

    if not header.guiCosmeticBar then
        local bar = header:CreateTexture(nil, "ARTWORK")
        header.guiCosmeticBar = bar
    end
    
    local bar = header.guiCosmeticBar
    local cfg = settings.cosmeticBar
    
    -- Texture
    local tex = LSM:Fetch("statusbar", cfg.texture) or "Interface\\Buttons\\WHITE8x8"
    bar:SetTexture(tex)
    
    -- Color
    local r, g, b = GetObjectiveThemeColor()
    bar:SetVertexColor(r, g, b)
    
    -- Size
    local width, height = cfg.width, cfg.height
    if cfg.widthMode == "DYNAMIC" then
        width = width + header.Text:GetStringWidth()
    end
    if cfg.heightMode == "DYNAMIC" then
        height = height + header.Text:GetStringHeight()
    end
    
    bar:SetSize(math.max(width, 1), math.max(height, 1))
    
    -- Position
    bar:ClearAllPoints()
    bar:SetPoint("RIGHT", header.Text, "LEFT", cfg.offsetX, cfg.offsetY)
    
    bar:Show()
end

-------------------------------------------------------------------------------
-- COLORFUL PROGRESSION
-------------------------------------------------------------------------------
local function GetProgressColor(progress)
    if progress >= 1 then
        return 0, 1, 0 -- Green
    elseif progress >= 0.5 then
        return 1, 1, 0 -- Yellow
    else
        return 1, 0, 0 -- Red
    end
end

local function ColorizeProgressText(text)
    local settings = GetSettings()
    if not settings.colorfulProgress and not settings.percentage then return end
    
    local raw = text:GetText()
    if not raw then return end
    
    -- Strip existing percentage if present (prevent duplication)
    raw = raw:gsub(" %[%d+%%%]$", "")
    -- Strip existing color codes if present (prevent nesting)
    raw = raw:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    
    local current, required, details = raw:match("^(%d+)/(%d+) (.+)")
    if not current then
        details, current, required = raw:match("(.+): (%d+)/(%d+)$")
    end
    
    if not (current and required and details) then return end
    
    local curNum, reqNum = tonumber(current), tonumber(required)
    if not curNum or not reqNum or reqNum == 0 then return end
    
    local progress = curNum / reqNum
    
    -- Color the numbers
    local progressText = current .. "/" .. required
    if settings.colorfulProgress then
        local r, g, b = GetProgressColor(progress)
        progressText = string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, progressText)
    end
    
    local result = progressText .. " " .. details
    
    if settings.percentage then
         local percent = math.floor(progress * 100)
         local percentStr = string.format(" [%d%%]", percent)
         if settings.colorfulProgress then
             local r, g, b = GetProgressColor(progress)
             percentStr = string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, percentStr)
         end
         result = result .. percentStr
    end
    
    text:SetText(result)
end

-------------------------------------------------------------------------------
-- MODULE HOOKS
-------------------------------------------------------------------------------
local function ApplyLineStyle(line)
    if not line or not line.Text then return end
    
    -- Apply Font
    local settings = GetSettings()
    if not settings then return end
    
    line.Text:SetFont(GetFontPath(), settings.textFontSize or 12, FONT_FLAGS)
    -- Color Logic
    local r, g, b, a = 0.75, 0.75, 0.75, 1
    if not settings.disableThemeColorForObjectives then
        r, g, b, a = GetObjectiveThemeColor()
    else
        local col = settings.textColor
        if col then r, g, b, a = col[1], col[2], col[3], col[4] end
    end
    line.Text:SetTextColor(r, g, b, a)
    
    -- Width / Wrapping for Objectives
    -- Explicitly set width
    if settings.width then
        -- 20px padding (standardized)
        line.Text:SetWidth(settings.width - 20)
        line.Text:SetWordWrap(true)
    end
    
    -- Colorful Progression
    ColorizeProgressText(line.Text)
    
    -- Handle Dash & Text Cleaning
    if settings.removeDashes then
        if line.Dash then
            line.Dash:Hide()
            line.Dash:SetText("")
        end
        if line.Icon then line.Icon:Hide() end -- Some trackers use Icon instead of Dash
        
        if text and text:find("^%- ") then
             line.Text:SetText(text:gsub("^%- ", ""))
        end
    end
    
    -- Fix Height Overlap: Ensure the Line Frame expands to fit the wrapped Text
    local textHeight = line.Text:GetStringHeight()
    if textHeight > 10 then -- Sanity check
        line:SetHeight(textHeight + 4) -- +4 padding
    end
end

local function UpdateMinimizeButton(header, collapsed)
    local button = header.MinimizeButton
    if not button then return end
    
    button:ClearAllPoints()
    button:SetPoint("RIGHT", header, "RIGHT", -5, 0)
    button:SetSize(16, 16)
    button:SetAlpha(1)
    button:Show()
    button:SetFrameLevel(header:GetFrameLevel() + 20)
    
    -- Create textures if not present
    if not button.guiTex then
        button:SetNormalTexture(0)
        button:SetPushedTexture(0)
        button:SetHighlightTexture(0)
        
        local tex = button:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        button.guiTex = tex
    end
    
    local tex = button.guiTex
    tex:Show()
    tex:ClearAllPoints()
    tex:SetAllPoints()
    tex:SetTexture(nil) -- Reset
    
    if collapsed then
        -- Collapsed -> Show Plus to Expand
        tex:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
    else
        -- Expanded -> Show Minus to Collapse
        tex:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
    end
    
    -- Reset Vertex Color (Textures have their own color)
    tex:SetVertexColor(1, 1, 1, 1)
end

local function SkinTrackerHeader(header, stateSource)
    if not header then return end
    
    -- Minimize Button
    if header.MinimizeButton then
        -- Default source if not provided
        local source = stateSource or header
        
        -- Helper to check state safely
        local function GetCollapsedState()
            if source.IsCollapsed then return source:IsCollapsed() end
            if source.isCollapsed ~= nil then return source.isCollapsed end
            return false
        end
        
        UpdateMinimizeButton(header, GetCollapsedState())
        
        if not header.MinimizeButton.guiHooked then
            -- Hook parent/header SetCollapsed if available (this might be on header or source)
            if source.SetCollapsed then
                hooksecurefunc(source, "SetCollapsed", function(self, collapsed)
                     -- Double check state just in case 'collapsed' arg isn't reliable
                    UpdateMinimizeButton(header, collapsed)
                end)
            end
            
            -- Also hook OnClick to catch manual toggles
            header.MinimizeButton:HookScript("OnClick", function(self)
                -- Defer slightly to let state update
                C_Timer.After(0.05, function() 
                    UpdateMinimizeButton(header, GetCollapsedState())
                end)
            end)
            
            -- Hook OnShow
            header.MinimizeButton:HookScript("OnShow", function(self)
                UpdateMinimizeButton(header, GetCollapsedState())
            end)
            
            header.MinimizeButton.guiHooked = true
            
            -- Force an initial update slightly after load
            C_Timer.After(0.5, function() 
                 UpdateMinimizeButton(header, GetCollapsedState())
            end)
        end
    end
    
    -- Hide Blizzard Backgrounds
    if header.Background then header.Background:Hide(); header.Background:SetAlpha(0) end
    if header.Line then header.Line:Hide(); header.Line:SetAlpha(0) end -- Some headers have a line
    
    -- Adjust Text Position if needed
    if header.Text then
        header.Text:ClearAllPoints()
        header.Text:SetPoint("LEFT", header, "LEFT", 20, 0) -- Adjusted to 20 for standard alignment
    end
end

local function HookModuleUpdate(tracker)
    if not tracker.Header then return end
    
    -- Pass 'tracker' as the source for IsCollapsed state
    SkinTrackerHeader(tracker.Header, tracker)
    
    -- Style Header Text
    local settings = GetSettings()
    if settings then
        local hText = tracker.Header.Text
        if hText then
            hText:SetFont(GetFontPath(), settings.moduleFontSize or 14, FONT_FLAGS)
            
            -- Color Logic: Same as ForceUpdateContent
            local r, g, b = 1, 0.82, 0
            if not settings.disableThemeColorForHeaders then
                r, g, b = GetObjectiveThemeColor()
            elseif settings.moduleColor then
                local col = settings.moduleColor
                r, g, b = col[1], col[2], col[3]
            end
            hText:SetTextColor(r, g, b, 1)
        end
    end

    -- Cosmetic Bar
    CreateCosmeticBar(tracker.Header)
    
    -- Iterate Blocks/Lines and Re-Apply Styles (Fixes "Revert to Standard" on update)
    if tracker.gravityCache then
         local currentWidth = 245 -- Fallback
         if _G.ObjectiveTrackerFrame then currentWidth = _G.ObjectiveTrackerFrame:GetWidth() end
         
         for block in pairs(tracker.gravityCache) do
              if block and block.IsShown and block:IsShown() then
                   -- Apply Header Style
                   HandleBlockHeader(block)
                   
                   -- Apply Line Style
                   local linePool = block.lines
                   if linePool then
                        if linePool.EnumerateActive then
                             for line in linePool:EnumerateActive() do ApplyLineStyle(line) end
                        else
                             for _, line in pairs(linePool) do ApplyLineStyle(line) end
                        end
                   end
                   if block.usedLines then
                        for _, line in pairs(block.usedLines) do ApplyLineStyle(line) end
                   end
              end
         end
    end
end

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------
function Objectives:Initialize()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end
    
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end
    
    -- Initial Update
    if TrackerFrame.Header then
        SkinTrackerHeader(TrackerFrame.Header, TrackerFrame)
    end
    
    -- Force Tracker Width
    if settings.width then
        TrackerFrame:SetWidth(settings.width)
    end
    
    -- START: Dynamic Update Logic
    local function ForceUpdateContent()
         local settings = GetSettings()
         local currentWidth = TrackerFrame:GetWidth() 
         
         -- Use settings width if available and valid
         if settings.width and type(settings.width) == "number" then 
             currentWidth = settings.width 
         end
         
         -- Debug: Print width
         -- print("GravityUI Debug: Resize Width =", currentWidth)
         
         -- Update FRAME HEIGHT
         if settings.height then
             TrackerFrame:SetHeight(settings.height)
         end
         
         -- Iterate Modules (via Frame, safer)
         local modules = TrackerFrame.modules
         if modules then
             for i, tracker in ipairs(modules) do
                 if tracker then
                      
                      -- Header Text Styling
                      if tracker.Header and tracker.Header.Text then
                           tracker.Header.Text:SetWidth(currentWidth - 30)
                           -- Font
                           if settings.moduleFontSize then
                               tracker.Header.Text:SetFont(GetFontPath(), settings.moduleFontSize, FONT_FLAGS)
                           end
                           -- Color
                           local r, g, b = 1, 0.82, 0
                           if not settings.disableThemeColorForHeaders then
                               r, g, b = GetObjectiveThemeColor()
                           elseif settings.moduleColor then
                               local c = settings.moduleColor
                               r, g, b = c[1], c[2], c[3]
                           end
                           tracker.Header.Text:SetTextColor(r, g, b, 1)
                      end
                      
                      -- Blocks from Gravity Cache
                      if tracker.gravityCache then
                           for block in pairs(tracker.gravityCache) do
                                if block and block.IsShown and block:IsShown() then
                                    -- Block Header (Quest Title)
                                    if block.HeaderText then
                                         block.HeaderText:SetWidth(currentWidth - 30)
                                         -- Update Style (Font/Color)
                                         HandleBlockHeader(block) 
                                    end
                                    
                                    -- Lines
                                    -- Lines
                                    local function StyleLine(line)
                                          ApplyLineStyle(line)
                                    end
                                    
                                    -- Check both possible locations
                                    local linePool = block.lines
                                    if linePool then
                                         if linePool.EnumerateActive then
                                              for line in linePool:EnumerateActive() do StyleLine(line) end
                                         else
                                              for _, line in pairs(linePool) do StyleLine(line) end
                                         end
                                    end
                                    
                                    if block.usedLines then
                                         for _, line in pairs(block.usedLines) do StyleLine(line) end
                                    end
                                end
                           end
                      end
                      
                      -- Update Cosmetic Bar
                      CreateCosmeticBar(tracker.Header)
                 end
             end
         end
    end
    
    -- Hook OnSizeChanged to handle dynamic resizing
    TrackerFrame:SetScript("OnSizeChanged", function(self)
         -- Remove silent pcall to see errors, or print them
         local status, err = pcall(ForceUpdateContent)
         if not status then 
             print("GravityUI Error in OnSizeChanged:", err)
         end
    end)
    
    -- Apply Initial Height
    if settings.height then
        TrackerFrame:SetHeight(settings.height)
    end
    -- END: Dynamic Update Logic
    
    -- Initialize Styling for All Trackers
    for _, name in ipairs(trackerModules) do
        local tracker = _G[name]
        if tracker then
            -- Initial Update
            HookModuleUpdate(tracker)
            
            -- Hook Updates
            hooksecurefunc(tracker, "Update", function() HookModuleUpdate(tracker) end)
            
            -- Hook Bar Skinning
            if tracker.GetProgressBar then
                hooksecurefunc(tracker, "GetProgressBar", SkinProgressBar)
            end
            
            -- Hook Block Adds
            if tracker.AddBlock and not tracker.guiHookedAddBlock then
                hooksecurefunc(tracker, "AddBlock", HandleBlockAdd)
                tracker.guiHookedAddBlock = true
            end
            
            -- Proactive Cache Population: Catch blocks that already exist
            if not tracker.gravityCache then tracker.gravityCache = {} end
            if tracker.usedBlocks then
                for _, block in pairs(tracker.usedBlocks) do
                    tracker.gravityCache[block] = true
                    -- Apply styling immediately to be safe
                    HandleBlockAdd(tracker, block)
                end
            end
        end
    end
    
    -- Hook Line Creation for Text Styling
    if ObjectiveTrackerBlockMixin and ObjectiveTrackerBlockMixin.AddObjective and not ObjectiveTrackerBlockMixin.guiHookedLines then
        hooksecurefunc(ObjectiveTrackerBlockMixin, "AddObjective", function(self, objectiveKey)
            local line = self.usedLines and self.usedLines[objectiveKey]
            if line then
                ApplyLineStyle(line)
            end
        end)
        ObjectiveTrackerBlockMixin.guiHookedLines = true
    end
    
    -- Backdrop Logic (Simplified from previous)
    if not TrackerFrame.guiBackdrop and settings.backdrop and settings.backdrop.enable then
        local bg = CreateFrame("Frame", nil, TrackerFrame, "BackdropTemplate")
        bg:SetFrameLevel(0)
        bg:SetPoint("TOPLEFT", -20, 10)
        bg:SetPoint("BOTTOMRIGHT", 20, -10)
        
        bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        
        local r, g, b, a = GetBackdropColor()
        bg:SetBackdropColor(r, g, b, a)
        
        -- Border Color (Theme)
        local br, bg_b, bb = GetObjectiveThemeColor()
        if settings.hideBorder then
            bg:SetBackdropBorderColor(0,0,0,0)
        else
            bg:SetBackdropBorderColor(br, bg_b, bb, 1)
        end
        
        TrackerFrame.guiBackdrop = bg
    end
    
    -- Force Initial Update to apply Fonts/Colors immediately
    ForceUpdateContent()
end

function Objectives:Refresh()
    self:Initialize()
end

_G.GravityUI_RefreshObjectiveTracker = function() Objectives:Refresh() end
