-- GravityUI Minimap Module
-- Combines Minimap backend logic and Minimap Button
local ADDON_NAME, ns = ...

-- Libraries
local LSM = LibStub("LibSharedMedia-3.0")
local LibDBIcon = LibStub("LibDBIcon-1.0", true)

-- Local references
local Minimap = Minimap
local MinimapCluster = MinimapCluster
local UIParent = UIParent

-- Module state
local minimapButton = nil
local backdropFrame, backdrop, mask
local clockFrame, clockText
local coordsFrame, coordsText
local zoneTextFrame, zoneTextFont
local datatextFrame

-- Patch Minimap Layout if missing (Blizzard code calls this when we reparent elements)
if not Minimap.Layout then
    Minimap.Layout = function() end
end

-- Tickers
local clockTicker = nil
local coordsTicker = nil
local dtTicker = nil

-- ═══════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function GetSettings()
    local db = ns.GetDB()
    if not db then return nil end
    return db.minimap
end

local function GetClampedPosition(frame, point, offsetX, offsetY)
    if not frame then return offsetX, offsetY end
    
    local mWidth, mHeight = Minimap:GetWidth(), Minimap:GetHeight()
    
    -- Calculate Bounds relative to Minimap Center
    -- (We use raw Width/Height because SetPoint logic allows us to work in local parent coords)
    
    -- Half dimensions
    -- Note: We generally assume scale is handled by the Parent/Child relationship in SetPoint
    -- If frame has a different scale, we might need adjustments, but usually matching scale is best.
    -- For safety, we use simple dimensions here.
    
    local halfMW = mWidth / 2
    local halfMH = mHeight / 2
    local halfFW = frame:GetWidth() / 2
    local halfFH = frame:GetHeight() / 2
    
    -- Max allowed distance from Center (Relaxed to allow edge positioning)
    -- Allow the frame to go slightly outside (halfFW + 10 padding)
    local maxDistX = halfMW + 10
    local maxDistY = halfMH + 10
    
    -- Determine Anchor's position relative to Center
    -- e.g. TOPRIGHT anchor is at (+halfMW, +halfMH)
    local anchorX, anchorY = 0, 0
    
    if point:find("LEFT") then anchorX = -halfMW
    elseif point:find("RIGHT") then anchorX = halfMW end
    
    if point:find("TOP") then anchorY = halfMH
    elseif point:find("BOTTOM") then anchorY = -halfMH end
    
    -- Target Position relative to Center = AnchorPos + Offset
    local targetX = anchorX + offsetX
    local targetY = anchorY + offsetY
    
    -- Clamp Target Position
    if targetX > maxDistX then targetX = maxDistX
    elseif targetX < -maxDistX then targetX = -maxDistX end
    
    if targetY > maxDistY then targetY = maxDistY
    elseif targetY < -maxDistY then targetY = -maxDistY end
    
    -- Convert back to Offset: NewOffset = ClampedTarget - AnchorPos
    return (targetX - anchorX), (targetY - anchorY)
end

local function UpdateElement(frame, config, shouldShow, isPreview, noForceShow)
    if not frame then return end
    
    local show = shouldShow or isPreview
    if show then
        if frame:IsShown() or shouldShow then
             if frame:GetParent() ~= Minimap then frame:SetParent(Minimap) end
             
             if frame == GameTimeFrame and shouldShow then 
                frame:Show() 
                frame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
             end
        end
        
        if config then
            frame:ClearAllPoints()
            if frame:GetParent() ~= Minimap then frame:SetParent(Minimap) end
            
            local pt = config.point or "TOPRIGHT"
            local ox = config.offsetX or 0
            local oy = config.offsetY or 0
            
            -- Apply Clamping
            ox, oy = GetClampedPosition(frame, pt, ox, oy)
            
            frame:SetPoint(pt, Minimap, pt, ox, oy)
            frame:SetScale(config.scale or 1.0)
        end
        
        -- If hidden, we don't need to force show it here because Blizzard might not have created it yet (e.g. AddonCompartment)
        if show and not frame:IsShown() then 
            if not noForceShow or isPreview then
                frame:Show() 
            end
        end
    else
        frame:Hide()
    end
    
    -- Robust Hiding for Blizzard Frames
    if not show and (frame == AddonCompartmentFrame or frame == TimeManagerClockButton) then
        if not frame.gravityVisibilityHook then
            hooksecurefunc(frame, "Show", function(self)
                local s_live = GetSettings()
                if not s_live then return end
                local still_should_hide = false
                if self == AddonCompartmentFrame then
                    still_should_hide = not s_live.showAddonCompartment and not s_live.settingsPreview
                elseif self == TimeManagerClockButton then
                    still_should_hide = s_live.hideBlizzardBorder
                end
                if still_should_hide then self:Hide() end
            end)
            frame.gravityVisibilityHook = true
        end
    end
end

local function HideBlizzardBorders()
    local s = GetSettings()
    if s and s.hideBlizzardBorder then
        if MinimapBorder then MinimapBorder:Hide() end
        if MinimapBorderTop then MinimapBorderTop:Hide() end
        if MinimapCluster.BorderTop then MinimapCluster.BorderTop:Hide() end
        if MinimapNorthTag then MinimapNorthTag:Hide() end
        if MinimapCompassTexture then MinimapCompassTexture:Hide() end
        
        -- Use robust hiding for the clock
        if TimeManagerClockButton then
            UpdateElement(TimeManagerClockButton, nil, false, false)
        end
    else
        if MinimapBorder then MinimapBorder:Show() end
        if MinimapBorderTop then MinimapBorderTop:Show() end
        if MinimapCluster.BorderTop then MinimapCluster.BorderTop:Show() end
        if MinimapNorthTag then MinimapNorthTag:Show() end
        if MinimapCompassTexture then MinimapCompassTexture:Show() end
        if TimeManagerClockButton then TimeManagerClockButton:Show() end
    end
end

local function GetButtonDB()
    local s = GetSettings()
    return s and s.button or { hide = true, minimapPos = 220 }
end

local function GetClassColor()
    local _, class = UnitClass("player")
    return C_ClassColor.GetClassColor(class)
end

-- ═══════════════════════════════════════════════════════════════
-- MINIMAP SHAPE & BACKDROP
-- ═══════════════════════════════════════════════════════════════

local function SetMinimapShape(shape)
    if shape == "SQUARE" then
        Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
        if mask then mask:SetTexture("Interface\\BUTTONS\\WHITE8X8") end
        _G.GetMinimapShape = function() return "SQUARE" end
    else
        -- Use a cleaner circle mask (TempPortraitAlphaMask is standard for round portraits)
        local roundMask = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
        Minimap:SetMaskTexture(roundMask)
        if mask then mask:SetTexture(roundMask) end
        _G.GetMinimapShape = function() return "ROUND" end
    end
    
    if LibDBIcon then
        for _, button in ipairs(LibDBIcon:GetButtonList()) do
            LibDBIcon:Refresh(button)
        end
    end
end

local function CreateBackdrop()
    if backdropFrame then return end
    
    backdropFrame = CreateFrame("Frame", "Gravity_MinimapBackdrop", Minimap)
    backdropFrame:SetFrameStrata("BACKGROUND")
    backdropFrame:SetFrameLevel(1)
    backdropFrame:SetFixedFrameStrata(true)
    backdropFrame:SetFixedFrameLevel(true)
    backdropFrame:Show()
    
    backdrop = backdropFrame:CreateTexture(nil, "BACKGROUND")
    backdrop:SetPoint("CENTER", Minimap, "CENTER")
    
    mask = backdropFrame:CreateMaskTexture()
    mask:SetAllPoints(backdrop)
    mask:SetParent(backdropFrame)
    backdrop:AddMaskTexture(mask)
end

local function UpdateBackdrop()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    if not backdrop then CreateBackdrop() end
    
    local fullSize = settings.size + (settings.borderSize * 2)
    backdrop:SetSize(fullSize, fullSize)
    
    local r, g, b, a = unpack(settings.borderColor)
    if settings.useThemeColorBorder then
        if ns.GetAccentColor then
             r, g, b = ns.GetAccentColor()
        end
    end
    backdrop:SetColorTexture(r, g, b, a)
    
    if settings.shape == "SQUARE" then
        mask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    else
        mask:SetTexture("Interface\\MINIMAP\\UI-Minimap-Background")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- MINIMAP SIZE & POSITION
-- ═══════════════════════════════════════════════════════════════

local function UpdateMinimapSize()
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    Minimap:SetSize(s.size, s.size)
    Minimap:SetScale(s.scale or 1.0)
    
    -- Force update (Silent)
    if Minimap.ZoomIn and Minimap.ZoomOut then
        -- Avoid using :Click() as it plays sounds. Just invoke update listeners if needed or do nothing.
        -- Often SetSize is sufficient.
    end
end

local function SetupMinimapDragging()
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    Minimap:SetParent(UIParent)
    Minimap:SetFrameStrata("LOW")
    Minimap:SetFrameLevel(2)
    Minimap:EnableMouse(true)
    Minimap:SetMovable(not s.lock)
    Minimap:SetClampedToScreen(true)
    Minimap:RegisterForDrag("LeftButton")
    
    Minimap:SetScript("OnDragStart", function(self)
        if self:IsMovable() then self:StartMoving() end
    end)
    
    Minimap:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        s.position = {point, relPoint, x, y}
    end)
    
    -- Restore position
    local pos = s.position
    if pos then
        Minimap:ClearAllPoints()
        Minimap:SetPoint(pos[1] or "TOPLEFT", UIParent, pos[2] or "BOTTOMLEFT", pos[3] or 790, pos[4] or 285)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO ZOOM
-- ═══════════════════════════════════════════════════════════════

local zoomTimer = nil
local function SetupAutoZoom()
    local s = GetSettings()
    if not s then return end

    -- Hook zoom events only once
    if not Minimap.gravityZoomHooked then
        local function RestartTimer()
            if zoomTimer then zoomTimer:Cancel() end
            
            local s_live = GetSettings()
            if s_live and s_live.enabled and s_live.autoZoom then
                zoomTimer = C_Timer.NewTimer(10, function()
                    Minimap:SetZoom(0)
                    Minimap.ZoomIn:Enable()
                    Minimap.ZoomOut:Disable() -- Visual update for buttons
                    zoomTimer = nil
                end)
            end
        end

        Minimap:HookScript("OnMouseWheel", RestartTimer)
        if Minimap.ZoomIn then Minimap.ZoomIn:HookScript("OnClick", RestartTimer) end
        if Minimap.ZoomOut then Minimap.ZoomOut:HookScript("OnClick", RestartTimer) end
        
        Minimap.gravityZoomHooked = true
    end
    
    -- If disabled, cancel existing timer
    if not s.autoZoom and zoomTimer then
        zoomTimer:Cancel()
        zoomTimer = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CLOCK
-- ═══════════════════════════════════════════════════════════════

local function CreateClock()
    if clockFrame then return end
    clockFrame = CreateFrame("Button", nil, Minimap)
    clockText = clockFrame:CreateFontString(nil, "OVERLAY")
    clockText:SetAllPoints(clockFrame)
    
    clockFrame:EnableMouse(true)
    clockFrame:RegisterForClicks("AnyUp")
    clockFrame:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then ToggleCalendar() else TimeManagerFrame:SetShown(not TimeManagerFrame:IsShown()) end
    end)
end

local function UpdateClock()
    local s = GetSettings()
    if not s or not s.enabled then return end
    if not clockFrame then CreateClock() end
    
    if not s.showClock then clockFrame:Hide(); return end
    
    local cfg = s.clockConfig
    clockFrame:Show()
    clockFrame:ClearAllPoints()
    clockFrame:SetPoint(cfg.point or "TOPRIGHT", Minimap, cfg.point or "TOPRIGHT", cfg.offsetX or 0, cfg.offsetY or 0)
    clockFrame:SetScale(cfg.scale or 1.0)
    clockFrame:SetHeight(cfg.fontSize + 2)
    
    local font, outline = ns.GetFont()
    clockText:SetFont(font, cfg.fontSize, outline)
    clockText:SetJustifyH(cfg.align)
    clockText:SetTextColor(unpack(cfg.color))
end

local function UpdateClockTime()
    if not clockText or not clockFrame:IsShown() then return end
    local s = GetSettings()
    local cfg = s.clockConfig
    
    local h, m
    if cfg.timeFormat == "local" then
        h, m = tonumber(date("%H")), tonumber(date("%M"))
    else
        h, m = GetGameTime()
    end
    
    if GetCVarBool("timeMgrUseMilitaryTime") then
        clockText:SetFormattedText("%02d:%02d", h, m)
    else
        if h == 0 then h = 12 elseif h > 12 then h = h - 12 end
        clockText:SetFormattedText("%d:%02d", h, m)
    end
    clockFrame:SetWidth(clockText:GetStringWidth() + 5)
end

-- ═══════════════════════════════════════════════════════════════
-- COORDINATES
-- ═══════════════════════════════════════════════════════════════

local function CreateCoords()
    if coordsFrame then return end
    coordsFrame = CreateFrame("Frame", nil, Minimap)
    coordsText = coordsFrame:CreateFontString(nil, "OVERLAY")
    coordsText:SetAllPoints(coordsFrame)
end

local function UpdateCoords()
    local s = GetSettings()
    if not s or not s.enabled then return end
    if not coordsFrame then CreateCoords() end
    
    if not s.showCoords then coordsFrame:Hide(); return end
    
    local cfg = s.coordsConfig
    coordsFrame:Show()
    coordsFrame:ClearAllPoints()
    coordsFrame:SetPoint(cfg.point or "TOPRIGHT", Minimap, cfg.point or "TOPRIGHT", cfg.offsetX or 0, cfg.offsetY or 0)
    coordsFrame:SetScale(cfg.scale or 1.0)
    coordsFrame:SetHeight(cfg.fontSize + 2)
    
    local font, outline = ns.GetFont()
    coordsText:SetFont(font, cfg.fontSize, outline)
    coordsText:SetTextColor(unpack(cfg.color))
end

local function UpdateCoordsPosition()
    if not coordsText or not coordsFrame:IsShown() then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            coordsText:SetFormattedText("%.1f, %.1f", pos.x * 100, pos.y * 100)
            coordsFrame:SetWidth(coordsText:GetStringWidth() + 5)
            return
        end
    end
    coordsText:SetText("---")
end

-- ═══════════════════════════════════════════════════════════════
-- ZONE TEXT
-- ═══════════════════════════════════════════════════════════════

local function CreateZoneText()
    if zoneTextFrame then return end
    zoneTextFrame = CreateFrame("Frame", nil, Minimap)
    zoneTextFont = zoneTextFrame:CreateFontString(nil, "OVERLAY")
    zoneTextFont:SetAllPoints(zoneTextFrame)
    
    -- Hide Blizzard zone text
    if MinimapCluster.ZoneTextButton then
        MinimapCluster.ZoneTextButton:Hide()
        MinimapCluster.ZoneTextButton:UnregisterAllEvents()
        hooksecurefunc(MinimapCluster.ZoneTextButton, "Show", function(self) self:Hide() end)
    end
    
    zoneTextFrame:RegisterEvent("ZONE_CHANGED")
    zoneTextFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    zoneTextFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    zoneTextFrame:SetScript("OnEvent", function() ns.RefreshMinimap() end)
end

local function UpdateZoneText()
    local s = GetSettings()
    if not s or not s.enabled then return end
    if not zoneTextFrame then CreateZoneText() end
    
    if not s.showZoneText then zoneTextFrame:Hide(); return end
    
    local cfg = s.zoneTextConfig
    zoneTextFrame:Show()
    zoneTextFrame:ClearAllPoints()
    zoneTextFrame:SetPoint("TOP", Minimap, "TOP", cfg.offsetX, cfg.offsetY)
    zoneTextFrame:SetWidth(s.size)
    zoneTextFrame:SetHeight(cfg.fontSize + 2)
    
    local font, outline = ns.GetFont()
    zoneTextFont:SetFont(font, cfg.fontSize, outline)
    
    local text = GetMinimapZoneText()
    if cfg.allCaps then text = string.upper(text) end
    zoneTextFont:SetText(text)
    
    -- Color logic
    local r, g, b = 1, 1, 1
    
    if cfg.useThemeColor then
        if ns.GetAccentColor then
             r, g, b = ns.GetAccentColor()
        end
    elseif cfg.useBlizzardZoneColors then
        -- Blizzard PvP Colors
        local pvpType = C_PvP.GetZonePVPInfo()
        if pvpType == "sanctuary" then r,g,b = unpack(cfg.colorSanctuary)
        elseif pvpType == "arena" then r,g,b = unpack(cfg.colorArena)
        elseif pvpType == "friendly" then r,g,b = unpack(cfg.colorFriendly)
        elseif pvpType == "hostile" then r,g,b = unpack(cfg.colorHostile)
        elseif pvpType == "contested" then r,g,b = unpack(cfg.colorContested)
        else r,g,b = unpack(cfg.colorNormal) end
    else
        -- User wants custom Mono-Color for all zones
        r, g, b = unpack(cfg.colorNormal)
    end
    
    zoneTextFont:SetTextColor(r, g, b)
end



-- ═══════════════════════════════════════════════════════════════
-- VISIBILITY & PREVIEW HELPERS
-- ═══════════════════════════════════════════════════════════════

local previewFrames = {}

local function CreatePreviewFrame(key, icon, color)
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(24, 24)
    f:SetFrameStrata("TOOLTIP") -- Always on top
    f:EnableMouse(true)
    
    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture(icon or [[Interface\Icons\INV_Misc_QuestionMark]])
    if color then tex:SetVertexColor(unpack(color)) end
    f.icon = tex
    
    -- Border/Highlight to indicate it's a preview
    local border = f:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0, 1, 0, 0.5) -- Semi-transparent green background
    f.bg = border
    
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", f, "TOP", 0, 2)
    f.label = label
    
    previewFrames[key] = f
    return f
end

local function SavePreviewPosition(key, frame)
    if not frame then return end
    
    local settings = GetSettings()
    if not settings then return end
    
    local config = settings[key]
    if not config then
        config = { point = "TOPRIGHT", offsetX = 0, offsetY = 0, scale = 1.0 }
        settings[key] = config
    end
    
    -- Robust Anchor Calculation (Smart Anchoring)
    -- Find the closest anchor point on the Minimap to the Frame's center
    
    local mEffScale = Minimap:GetEffectiveScale()
    local fEffScale = frame:GetEffectiveScale()
    
    local fx, fy = frame:GetCenter()
    local mx, my = Minimap:GetCenter()
    local mWidth, mHeight = Minimap:GetWidth(), Minimap:GetHeight()
    
    if not fx or not mx then return end
    
    -- Calculate positions of all 9 anchor points on the Minimap (in screen pixels)
    -- We assume Minimap's Center is (mx, my) * mEffScale
    
    local anchors = {
        {point="CENTER",      x=0,      y=0},
        {point="TOP",         x=0,      y=mHeight/2},
        {point="BOTTOM",      x=0,      y=-mHeight/2},
        {point="LEFT",        x=-mWidth/2, y=0},
        {point="RIGHT",       x=mWidth/2,  y=0},
        {point="TOPLEFT",     x=-mWidth/2, y=mHeight/2},
        {point="TOPRIGHT",    x=mWidth/2,  y=mHeight/2},
        {point="BOTTOMLEFT",  x=-mWidth/2, y=-mHeight/2},
        {point="BOTTOMRIGHT", x=mWidth/2,  y=-mHeight/2},
    }
    
    -- Current Frame Center in screen/absolute pixels rel to Minimap Center
    -- diffX_screen = (fx * fScale) - (mx * mScale)
    -- Actually straightforward: Frame Center Screen - Minimap Center Screen
    local screen_fx = fx * fEffScale
    local screen_fy = fy * fEffScale
    local screen_mx = mx * mEffScale
    local screen_my = my * mEffScale
    
    local relX_screen = screen_fx - screen_mx
    local relY_screen = screen_fy - screen_my
    
    -- Constraint / Clamping Logic
    -- Determine bounds in screen pixels (Minimap Half Width - Frame Half Width)
    -- This ensures the Frame is fully kept inside the Minimap
    local halfMW_screen = (mWidth * mEffScale) / 2
    local halfMH_screen = (mHeight * mEffScale) / 2
    local halfFW_screen = (frame:GetWidth() * fEffScale) / 2
    local halfFH_screen = (frame:GetHeight() * fEffScale) / 2
    
    -- Calculate bounds (Relaxed)
    local maxDiffX = halfMW_screen + 10
    local maxDiffY = halfMH_screen + 10
    
    -- Clamp relative position
    if relX_screen > maxDiffX then relX_screen = maxDiffX
    elseif relX_screen < -maxDiffX then relX_screen = -maxDiffX end
    
    if relY_screen > maxDiffY then relY_screen = maxDiffY
    elseif relY_screen < -maxDiffY then relY_screen = -maxDiffY end
    
    -- Find best anchor
    local bestAnchor = "CENTER"
    local bestDistSq = 9999999999
    local bestOffsetX, bestOffsetY = 0, 0
    
    for _, anchor in ipairs(anchors) do
        -- Anchor position in screen pixels relatives to Minimap Center
        local anchorX_screen = anchor.x * mEffScale
        local anchorY_screen = anchor.y * mEffScale
        
        -- Distance from frame center to this anchor
        local dx = relX_screen - anchorX_screen
        local dy = relY_screen - anchorY_screen
        local distSq = (dx*dx) + (dy*dy)
        
        if distSq < bestDistSq then
            bestDistSq = distSq
            bestAnchor = anchor.point
            -- Convert screen delta back to Minimap local scale for storage
            -- The SetPoint will be: SetPoint(point, Minimap, point, offX, offY)
            -- So offX should be in Minimap's scale logic (since parent is Minimap)
            bestOffsetX = dx / mEffScale
            bestOffsetY = dy / mEffScale
        end
    end
    
    -- Round to nearest 0.5
    local offX = math.floor(bestOffsetX * 2 + 0.5) / 2
    local offY = math.floor(bestOffsetY * 2 + 0.5) / 2
    
    config.offsetX = offX
    config.offsetY = offY
    config.point = bestAnchor
    
    -- Force immediate update
    C_Timer.After(0.05, function() ns.RefreshMinimap() end)
end

local function UpdatePreviewPlaceholders(show)
    local s = GetSettings()
    if not s then show = false end
    
    local definitions = {
        { key = "mailConfig", label = "Mail", icon = [[Interface\Icons\INV_Letter_15]], visKey = "showMail" },
        { key = "trackingConfig", label = "Track", icon = [[Interface\Icons\INV_Misc_Spyglass_02]], visKey = "showTracking" },
        { key = "craftingConfig", label = "Craft", icon = [[Interface\Icons\Trade_Engineering]], visKey = "showCraftingOrder" },
        { key = "missionsConfig", label = "Missn", icon = [[Interface\Icons\INV_Misc_Map02]], visKey = "showMissions" },
        { key = "difficultyConfig", label = "Diff", icon = [[Interface\Icons\INV_Misc_Bone_Skull_02]], visKey = "showDifficulty" },
        { key = "addonCompartmentConfig", label = "Addon", icon = [[Interface\Icons\INV_Crate_03]], visKey = "showAddonCompartment" },
        { key = "zoomConfig", label = "Zoom", icon = [[Interface\Icons\INV_Misc_Monocle_01]], visKey = "showZoomButtons" },
        { key = "calendarConfig", label = "Cal", icon = [[Interface\Icons\INV_Misc_PocketWatch_01]], visKey = "showCalendar" },
        { key = "clockConfig", label = "Clock", icon = [[Interface\Icons\INV_Misc_PocketWatch_02]], visKey = "showClock" },
        { key = "coordsConfig", label = "Coords", icon = [[Interface\Icons\INV_Map_01]], visKey = "showCoords" },
    }
    
    for _, def in ipairs(definitions) do
        local f = previewFrames[def.key]
        -- Show only if Preview Mode is ON AND the specific feature is ENABLED
        if show and s[def.visKey] then
            if not f then 
                f = CreatePreviewFrame(def.key, def.icon)
            end

            -- Ensure Drag handlers are active (apply every time to prevent "stuck" frames)
            f:SetMovable(true)
            f:EnableMouse(true)
            f:RegisterForDrag("LeftButton")
            f:SetScript("OnDragStart", function(self)
                self:StartMoving()
            end)
            f:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                SavePreviewPosition(def.key, self)
            end)
            
            f:Show()
            f.label:SetText(def.label)
            
            -- Ensure high z-index to prevent blocking by other minimap children
            f:SetParent(UIParent)
            f:SetFrameStrata("DIALOG")
            f:SetFrameLevel(9999)
            
            local config = s[def.key] or { point = "TOPRIGHT", offsetX = 0, offsetY = 0, scale = 1.0 }
            
            f:ClearAllPoints()
            
            -- Important: When NOT dragging, we must snap to config
            f:SetPoint(config.point or "TOPRIGHT", Minimap, config.point or "TOPRIGHT", config.offsetX or 0, config.offsetY or 0)
            f:SetScale(config.scale or 1.0)
        else
            if f then f:Hide() end
        end
    end
end


local function UpdateButtonVisibility()
    local s = GetSettings()
    if not s or not s.enabled then return end
    
    local preview = s.settingsPreview
    UpdatePreviewPlaceholders(preview)
    
    -- Zoom Buttons (Explicit Handling)
    if Minimap.ZoomIn and Minimap.ZoomOut then
        local cfg = s.zoomConfig
        if s.showZoomButtons or preview then
            Minimap.ZoomIn:Show()
            Minimap.ZoomOut:Show()
            Minimap.ZoomIn:SetFrameLevel(Minimap:GetFrameLevel() + 10)
            Minimap.ZoomOut:SetFrameLevel(Minimap:GetFrameLevel() + 10)
            
            if cfg then
                -- Safety Clamp: Reset if coordinates are insane (e.g. from previous bug)
                if math.abs(cfg.offsetX) > 3000 or math.abs(cfg.offsetY) > 3000 then
                    cfg.offsetX = 0
                    cfg.offsetY = 0
                    print("|cFF30D1FFGravityUI:|r Reset Zoom Buttons position (was out of bounds).")
                end
                
                Minimap.ZoomIn:ClearAllPoints()
                Minimap.ZoomIn:SetParent(Minimap)
                Minimap.ZoomIn:SetPoint(cfg.point or "TOPRIGHT", Minimap, cfg.point or "TOPRIGHT", cfg.offsetX or 0, cfg.offsetY or 0)
                Minimap.ZoomIn:SetScale(cfg.scale or 1.0)
                
                Minimap.ZoomOut:ClearAllPoints()
                Minimap.ZoomOut:SetParent(Minimap)
                Minimap.ZoomOut:SetPoint("LEFT", Minimap.ZoomIn, "RIGHT", 2, 0)
                Minimap.ZoomOut:SetScale(cfg.scale or 1.0)
            end
        else
            Minimap.ZoomIn:Hide(); Minimap.ZoomOut:Hide()
        end
    end
    
    -- Calendar
    if GameTimeFrame then
         UpdateElement(GameTimeFrame, s.calendarConfig, s.showCalendar, preview)
    end
    
    -- Mail (IndicatorFrame)
    if MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame then
         -- Pass noForceShow=true so we don't show empty mail icon
         UpdateElement(MinimapCluster.IndicatorFrame.MailFrame, s.mailConfig, s.showMail, preview, true)
    end
    
    -- Crafting
    -- Try to find the crafting frame safely (it might move in Blizzard updates)
    local craftingFrame = MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.CraftingOrderFrame
    if not craftingFrame and MinimapCluster.CraftingOrderFrame then craftingFrame = MinimapCluster.CraftingOrderFrame end
    
    if craftingFrame then
         -- Pass noForceShow=true so we don't show empty crafting icon
        UpdateElement(craftingFrame, s.craftingConfig, s.showCraftingOrder, preview, true)
    end
    
    -- Hook Minimap OnEnter to prevent Blizzard from showing Zoom buttons if we want them hidden
    if not Minimap.gravityHoverHooked then
         Minimap:HookScript("OnEnter", function()
             local s_live = GetSettings()
             if s_live and not s_live.showZoomButtons and not s_live.settingsPreview then
                 if Minimap.ZoomIn then Minimap.ZoomIn:Hide() end
                 if Minimap.ZoomOut then Minimap.ZoomOut:Hide() end
             end
         end)
         Minimap.gravityHoverHooked = true
    end
    
    -- Difficulty
    if MinimapCluster.InstanceDifficulty then
         UpdateElement(MinimapCluster.InstanceDifficulty, s.difficultyConfig, s.showDifficulty, preview)
    end
    
    -- Tracking
    if MinimapCluster.Tracking then
         UpdateElement(MinimapCluster.Tracking, s.trackingConfig, s.showTracking, preview)
    end
    
    -- Missions (Expansion Landing Page)
    if ExpansionLandingPageMinimapButton then
        -- Fix for SetText crash (missing title)
        if not ExpansionLandingPageMinimapButton.gravityCrashFix then
             local old = ExpansionLandingPageMinimapButton.SetTooltip
             ExpansionLandingPageMinimapButton.SetTooltip = function(self)
                 if not self.title then self.title = self.systemNameString or "Expansion Button" end
                 if old then pcall(old, self) end
             end
             ExpansionLandingPageMinimapButton.gravityCrashFix = true
        end
        UpdateElement(ExpansionLandingPageMinimapButton, s.missionsConfig, s.showMissions, preview)
    end
    
    -- Addon Compartment
    if AddonCompartmentFrame then
        UpdateElement(AddonCompartmentFrame, s.addonCompartmentConfig, s.showAddonCompartment, preview)
    end
    
    HideBlizzardBorders()
end

-- ═══════════════════════════════════════════════════════════════
-- DATATEXT PANEL
-- ═══════════════════════════════════════════════════════════════

local function GetDatatextSettings()
    local s = GetSettings()
    return s and s.datatext
end

local function CreateDatatextPanel()
    if datatextFrame then return end

    -- Container frame for 3 datatext slots
    datatextFrame = CreateFrame("Frame", "Gravity_MinimapDatatext", UIParent)
    datatextFrame:SetFrameStrata("LOW")
    datatextFrame:SetFrameLevel(5) -- Above minimap

    -- Create 4 border edge textures
    datatextFrame.borderLeft = datatextFrame:CreateTexture(nil, "BACKGROUND")
    datatextFrame.borderRight = datatextFrame:CreateTexture(nil, "BACKGROUND")
    datatextFrame.borderTop = datatextFrame:CreateTexture(nil, "BACKGROUND")
    datatextFrame.borderBottom = datatextFrame:CreateTexture(nil, "BACKGROUND")

    -- Background texture
    datatextFrame.bg = datatextFrame:CreateTexture(nil, "BACKGROUND")
    datatextFrame.bg:SetAllPoints()

    -- Create 3 slot frames for individual datatexts
    datatextFrame.slots = {}
    for i = 1, 3 do
        local slot = CreateFrame("Button", nil, datatextFrame)
        slot:EnableMouse(true)
        slot:RegisterForClicks("AnyUp")

        -- Create text for datatext use
        slot.text = slot:CreateFontString(nil, "OVERLAY")
        -- Anchor to both edges to constrain width and enable auto-truncation
        slot.text:SetPoint("LEFT", slot, "LEFT", 1, 0)
        slot.text:SetPoint("RIGHT", slot, "RIGHT", -1, 0)
        slot.text:SetJustifyH("CENTER")
        slot.text:SetWordWrap(false)
        slot.index = i
        
        -- Event Handlers
        slot:SetScript("OnEnter", function(self)
            if ns.Datatexts and ns.Datatexts.HandleOnEnter then
                ns.Datatexts:HandleOnEnter(self, self.config)
            end
        end)
        slot:SetScript("OnLeave", function(self)
            if GameTooltip:IsShown() then GameTooltip:Hide() end
        end)
        slot:SetScript("OnClick", function(self, button)
            if ns.Datatexts and ns.Datatexts.HandleOnClick then
                ns.Datatexts:HandleOnClick(self, button, self.config)
            end
        end)

        datatextFrame.slots[i] = slot
    end

    -- Register for modifier key changes to update tooltips dynamically (e.g. Shift for notes)
    datatextFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    datatextFrame:SetScript("OnEvent", function(self, event, key)
        if event == "MODIFIER_STATE_CHANGED" and (key == "LSHIFT" or key == "RSHIFT") then
            if GameTooltip:IsShown() then
                local owner = GameTooltip:GetOwner()
                for _, slot in ipairs(self.slots) do
                    if owner == slot then
                        if ns.Datatexts and ns.Datatexts.HandleOnEnter then
                            ns.Datatexts:HandleOnEnter(slot, slot.config)
                        end
                        break
                    end
                end
            end
        end
    end)
end

local function UpdateSlotContent(slot, config)
    -- Store config for event handlers
    slot.config = config
    
    if not config or not config.content or config.content == "" or config.content == "none" then
        slot.text:SetText("")
        return
    end
    
    if ns.Datatexts and ns.Datatexts.GetContentText then
        local text = ns.Datatexts:GetContentText(slot, config)
        slot.text:SetText(text)
    else
        slot.text:SetText(config.content)
    end
end

local function UpdateDatatextPanel()
    local minimapSettings = GetSettings()
    local dtSettings = GetDatatextSettings()

    if not minimapSettings or not minimapSettings.enabled then return end
    if not dtSettings or not dtSettings.enabled then
        if datatextFrame then datatextFrame:Hide() end
        return
    end

    if not datatextFrame then CreateDatatextPanel() end

    local minimapSize = minimapSettings.size or 160
    local minimapScale = minimapSettings.scale or 1.0
    local minimapBorderSize = minimapSettings.borderSize or 3
    local dtBorderSize = dtSettings.borderSize or 2
    local dtBorderColor = dtSettings.borderColor or {0, 0, 0, 1}
    
    -- Border Theme Color Override
    if dtSettings.useThemeColorBorder ~= false then -- Default true
        local db = ns.GetDB()
        local general = db and (db.general or (db.profile and db.profile.general))
        
        local activeColor
        -- 1. Check Global Class Color Setting
        if general and general.useClassColorTheme then
             local _, class = UnitClass("player")
             local c = RAID_CLASS_COLORS[class]
             if c then activeColor = {c.r, c.g, c.b, 1} end
        end
        
        -- 2. Fallback to Global Theme Color
        if not activeColor and general and general.themeColor then
             activeColor = {general.themeColor[1], general.themeColor[2], general.themeColor[3], 1}
        end
        
        -- 3. Fallback to default blue
        if not activeColor then activeColor = {0, 0.749, 1, 1} end
        
        dtBorderColor = activeColor
    end
    
    local dtHeight = dtSettings.height or 22
    local bgAlpha = (dtSettings.bgOpacity or 60) / 100
    
    -- Offsets
    local panelOffsetX = dtSettings.offsetX or 0
    local panelOffsetY = dtSettings.offsetY or 0

    -- Content frame size = minimap size
    datatextFrame:SetSize(minimapSize, dtHeight)
    datatextFrame:SetScale(minimapScale)

    -- Position below minimap (content touches minimap border bottom)
    datatextFrame:ClearAllPoints()
    datatextFrame:SetPoint("TOP", Minimap, "BOTTOM", panelOffsetX, -minimapBorderSize + panelOffsetY)

    -- Borders Update
    local showBorder = dtBorderSize > 0
    if showBorder then
        datatextFrame.borderLeft:SetPoint("TOPRIGHT", datatextFrame, "TOPLEFT", 0, dtBorderSize)
        datatextFrame.borderLeft:SetPoint("BOTTOMRIGHT", datatextFrame, "BOTTOMLEFT", 0, -dtBorderSize)
        datatextFrame.borderLeft:SetWidth(dtBorderSize)
        datatextFrame.borderLeft:SetColorTexture(unpack(dtBorderColor))
        
        datatextFrame.borderRight:SetPoint("TOPLEFT", datatextFrame, "TOPRIGHT", 0, dtBorderSize)
        datatextFrame.borderRight:SetPoint("BOTTOMLEFT", datatextFrame, "BOTTOMRIGHT", 0, -dtBorderSize)
        datatextFrame.borderRight:SetWidth(dtBorderSize)
        datatextFrame.borderRight:SetColorTexture(unpack(dtBorderColor))
        
        datatextFrame.borderTop:SetPoint("BOTTOMLEFT", datatextFrame, "TOPLEFT", 0, 0)
        datatextFrame.borderTop:SetPoint("BOTTOMRIGHT", datatextFrame, "TOPRIGHT", 0, 0)
        datatextFrame.borderTop:SetHeight(dtBorderSize)
        datatextFrame.borderTop:SetColorTexture(unpack(dtBorderColor))
        
        datatextFrame.borderBottom:SetPoint("TOPLEFT", datatextFrame, "BOTTOMLEFT", 0, 0)
        datatextFrame.borderBottom:SetPoint("TOPRIGHT", datatextFrame, "BOTTOMRIGHT", 0, 0)
        datatextFrame.borderBottom:SetHeight(dtBorderSize)
        datatextFrame.borderBottom:SetColorTexture(unpack(dtBorderColor))
    end
    
    datatextFrame.borderLeft:SetShown(showBorder)
    datatextFrame.borderRight:SetShown(showBorder)
    datatextFrame.borderTop:SetShown(showBorder)
    datatextFrame.borderBottom:SetShown(showBorder)

    -- Background (content area with opacity)
    datatextFrame.bg:SetColorTexture(0, 0, 0, bgAlpha)
    datatextFrame:Show()
    
    -- Active Slots Logic
    local activeSlots = {}
    if dtSettings.slot1 and dtSettings.slot1.content and dtSettings.slot1.content ~= "" and dtSettings.slot1.content ~= "none" then
        table.insert(activeSlots, { config = dtSettings.slot1, id = 1 })
    end
    if dtSettings.slot2 and dtSettings.slot2.content and dtSettings.slot2.content ~= "" and dtSettings.slot2.content ~= "none" then
        table.insert(activeSlots, { config = dtSettings.slot2, id = 2 })
    end
    if dtSettings.slot3 and dtSettings.slot3.content and dtSettings.slot3.content ~= "" and dtSettings.slot3.content ~= "none" then
        table.insert(activeSlots, { config = dtSettings.slot3, id = 3 })
    end
    
    local numActive = #activeSlots
    local slotWidth = (numActive > 0) and (minimapSize / numActive) or minimapSize
    
    -- Reset all slots
    for i, slot in ipairs(datatextFrame.slots) do
        slot:Hide()
    end
    
    -- Show active slots
    for i, data in ipairs(activeSlots) do
        local slot = datatextFrame.slots[i] -- Reuse slot 1, 2, 3 as needed
        if slot then
            slot:Show()
            slot:SetSize(slotWidth, dtHeight)
            slot:ClearAllPoints()
            
            -- Dynamic Positioning: Slot 1 is left, Slot 2 is next to it, etc.
            -- This means Slot 1 always takes the LEFTMOST position if enabled.
            slot:SetPoint("LEFT", datatextFrame, "LEFT", (i-1)*slotWidth, 0)
            
            -- Apply Font
            local font, outline = ns.GetFont()
            slot.text:SetFont(font, dtSettings.fontSize or 12, outline)
            
            -- Apply Offsets
            -- Since we anchored LEFT, we can assume the text is centered in the slot.
            -- We apply the offset to the TEXT, not the slot frame (to keep the grid logical).
            slot.text:ClearAllPoints()
            slot.text:SetPoint("CENTER", slot, "CENTER", data.config.offsetX or 0, data.config.offsetY or 0)
            
            -- Update Content
            UpdateSlotContent(slot, data.config)
        end
    end
end

local function UpdateDatatexts()
    if not datatextFrame or not datatextFrame:IsShown() then return end
    for i, slot in ipairs(datatextFrame.slots) do
        if slot:IsShown() and slot.config then
            UpdateSlotContent(slot, slot.config)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- DUNGEON EYE
-- ═══════════════════════════════════════════════════════════════

local isUpdatingEye = false
local queueStatusHooked = false

local function EnforceDungeonEyePosition()
    if isUpdatingEye then return end
    local s = GetSettings()
    if not s or not s.enabled or not s.dungeonEye or not s.dungeonEye.enabled then return end
    
    local eye = s.dungeonEye
    if QueueStatusButton then
         isUpdatingEye = true
         QueueStatusButton:ClearAllPoints()
         local anchor = eye.corner or "BOTTOMLEFT"
         QueueStatusButton:SetPoint(anchor, Minimap, anchor, eye.offsetX or 0, eye.offsetY or 0)
         
         -- Ensure parent is managed (stick to Minimap)
         if QueueStatusButton:GetParent() ~= Minimap then
             QueueStatusButton:SetParent(Minimap)
         end
         
         QueueStatusButton:SetFrameStrata("MEDIUM")
         QueueStatusButton:SetFrameLevel(Minimap:GetFrameLevel() + 10)
         QueueStatusButton:SetScale(eye.scale or 1.0)
         isUpdatingEye = false
    end
end

local function UpdateDungeonEye()
    local s = GetSettings()
    if not s or not s.enabled then return end
    local eye = s.dungeonEye
    
    if QueueStatusButton then
        if eye.enabled then
             -- Hook once to prevent external moves
             if not queueStatusHooked then
                 hooksecurefunc(QueueStatusButton, "SetPoint", EnforceDungeonEyePosition)
                 hooksecurefunc(QueueStatusButton, "SetParent", function() 
                    if not isUpdatingEye then EnforceDungeonEyePosition() end
                 end)
                 hooksecurefunc(QueueStatusButton, "Show", EnforceDungeonEyePosition)
                 queueStatusHooked = true
             end

             -- Apply Position Immediately
             EnforceDungeonEyePosition()
             
             if eye.preview then
                 QueueStatusButton:Show()
                 QueueStatusButton:SetAlpha(1)
                 if not QueueStatusButton.previewTex then
                     QueueStatusButton.previewTex = QueueStatusButton:CreateTexture(nil, "OVERLAY")
                     QueueStatusButton.previewTex:SetAllPoints()
                     QueueStatusButton.previewTex:SetTexture([[Interface\LFGFrame\LFG-Eye]])
                 end
                 QueueStatusButton.previewTex:Show()
             else
                 -- Preview is OFF.
                 if QueueStatusButton.previewTex then QueueStatusButton.previewTex:Hide() end
                 
                 -- We hide it to clear the forced preview, then let QueueStatusFrame.Update decides if it should be shown
                 if QueueStatusButton:IsShown() and not C_LFGList.HasActiveEntryInfo() and not IsInGroup() and not QueueStatusFrame:IsShown() then
                      -- Crude check, better to just rely on system update
                      QueueStatusButton:Hide()
                 end

                 -- Trigger natural update
                 if QueueStatusFrame and QueueStatusFrame.Update then
                     pcall(QueueStatusFrame.Update, QueueStatusFrame)
                 end
             end
        else
             QueueStatusButton:Hide()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- TICKERS (Optimization)
-- ═══════════════════════════════════════════════════════════════

local function MasterUpdate()
    UpdateClockTime()
    UpdateCoordsPosition()
    UpdateDatatexts()
end

local function StartTickers()
    if masterTicker then masterTicker:Cancel() end
    masterTicker = C_Timer.NewTicker(1, MasterUpdate)
end

-- ═══════════════════════════════════════════════════════════════
-- MINIMAP BUTTON (Existing Logic)
-- ═══════════════════════════════════════════════════════════════

local function UpdateButtonPosition()
    if not minimapButton then return end
    local db = GetButtonDB()
    local angle = math.rad(db.minimapPos or 220)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    if minimapButton then return end
    
    local button = CreateFrame("Button", "GravityUIMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(50) -- Above everything
    button:EnableMouse(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    
    -- Background (Dark Shadow)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(25, 25)
    bg:SetPoint("CENTER", 0, 0)
    bg:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask") -- Use mask as a solid dark circle
    bg:SetVertexColor(0, 0, 0, 0.8)
    
    -- Icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture(ns.ICON_PATH)
    
    -- Mask (Make it round)
    local mask = button:CreateMaskTexture()
    mask:SetSize(22, 22)
    mask:SetPoint("CENTER", 0, 0)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)
    
    -- Border (The gold ring) - Removed as requested
    -- local border = button:CreateTexture(nil, "OVERLAY")
    -- border:SetSize(54, 54)
    -- border:SetPoint("CENTER", 0, 1)
    -- border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(28, 28)
    highlight:SetPoint("CENTER", 0, 0)
    highlight:SetTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])
    highlight:SetBlendMode("ADD")
    
    button:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" and ns.GUI then ns.GUI:Toggle() end
    end)
    
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFF30D1FFGravityUI|r")
        GameTooltip:AddLine("Left-click to open settings", 0.5, 0.8, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local angle = math.deg(math.atan2(py - my, px - mx))
            if angle < 0 then angle = angle + 360 end
            local db = GetButtonDB()
            db.minimapPos = angle
            UpdateButtonPosition()
        end)
    end)
    
    button:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)
    
    minimapButton = button
    UpdateButtonPosition()
end

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════

local function StopTickers()
    if masterTicker then masterTicker:Cancel(); masterTicker = nil end
end

local function HideCustomElements()
    if backdropFrame then backdropFrame:Hide() end
    if clockFrame then clockFrame:Hide() end
    if coordsFrame then coordsFrame:Hide() end
    if zoneTextFrame then zoneTextFrame:Hide() end
    if datatextFrame then datatextFrame:Hide() end
    
    -- Restore Blizzard elements
    if MinimapCluster.ZoneTextButton then MinimapCluster.ZoneTextButton:Show() end
    if TimeManagerClockButton then TimeManagerClockButton:Show() end
    
    -- Restore Minimap parent/state
    if Minimap:SetParent(MinimapCluster) then end
    Minimap:SetMovable(false)
    Minimap:SetScale(1.0)
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function ns.SetMinimapButtonVisible(visible)
    if not minimapButton then return end
    if visible then minimapButton:Show() else minimapButton:Hide() end
end

function ns.RefreshMinimap()
    local s = GetSettings()
    if not s then return end

    if not s.enabled then
        StopTickers()
        HideCustomElements()
        return
    end
    
    -- Minimap Elements
    SetMinimapShape(s.shape)
    UpdateBackdrop()
    UpdateMinimapSize()
    SetupMinimapDragging()
    SetupAutoZoom() -- Apply Auto Zoom settings

    if s.rotate then
        SetCVar("rotateMinimap", "1")
        if Minimap.SetRotates then Minimap:SetRotates(true) end
    else
        SetCVar("rotateMinimap", "0")
        if Minimap.SetRotates then Minimap.SetRotates(false) end
    end
    
    -- Quest Blobs
    if s.hideQuestBlobs then
        SetCVar("minimapShowQuestBlobs", "0")
        
        -- Advanced Hiding: Try to set Scalars or hide specific Frames
        if Minimap.SetQuestBlobRingScalar then Minimap:SetQuestBlobRingScalar(0) end
        if Minimap.SetArchBlobRingScalar then Minimap:SetArchBlobRingScalar(0) end
        
        -- Hide the Blob Frame itself if accessible (Retail)
        if MinimapCluster and MinimapCluster.QuestBlobFrame then
            MinimapCluster.QuestBlobFrame:Hide()
            MinimapCluster.QuestBlobFrame:SetAlpha(0)
        end
        if _G.MinimapQuestBlobFrame then
            _G.MinimapQuestBlobFrame:Hide()
            _G.MinimapQuestBlobFrame:SetAlpha(0)
        end
        
        -- Also hide the compass texture (yellow arrow ring) if part of it
        -- But be careful not to hide tracking blips.
    else
        SetCVar("minimapShowQuestBlobs", "1")
        if Minimap.SetQuestBlobRingScalar then Minimap:SetQuestBlobRingScalar(1) end
        if Minimap.SetArchBlobRingScalar then Minimap:SetArchBlobRingScalar(1) end
        
        if MinimapCluster and MinimapCluster.QuestBlobFrame then
            MinimapCluster.QuestBlobFrame:Show()
            MinimapCluster.QuestBlobFrame:SetAlpha(1)
        end
    end
    
    -- Force Alway Show Elements (Disable Fade)
    if MinimapCluster then
        MinimapCluster:SetAlpha(1)
        MinimapCluster:SetScript("OnLeave", nil) -- Stop fading out
    end
    
    -- Extra Elements
    UpdateClock()
    UpdateCoords()
    UpdateZoneText()
    UpdateDatatextPanel()
    UpdateButtonVisibility()
    UpdateDungeonEye()
    
    -- Button
    if not minimapButton then CreateMinimapButton() end
    local dbBtn = GetButtonDB()
    ns.SetMinimapButtonVisible(not dbBtn.hide)
    
    -- Tickers
    StartTickers()
end

function ns.InitializeMinimapButton()
    local s = GetSettings()
    if s then s.settingsPreview = false end -- Reset preview mode on load
    
    CreateMinimapButton()
    ns.RefreshMinimap()
    
    if ns.Movers and ns.Movers.Register then
         ns.Movers:Register("Minimap", Minimap, function(frame, enabled, force)
              -- Apply Edit Mode Style
              if ns.Movers.ApplyEditModeStyle then
                  ns.Movers:ApplyEditModeStyle(frame, enabled)
              end
         end, "Minimap")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INITIALIZATION & EVENT HANDLING
-- ═══════════════════════════════════════════════════════════════

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1, arg2, arg3, arg4, arg5 = ...
    
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_TimeManager" or arg1 == "Blizzard_AddonCompartment" then
            ns.RefreshMinimap()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Final check once the world is loaded and most things are ready
        C_Timer.After(1, function() ns.RefreshMinimap() end)
    end
end)
