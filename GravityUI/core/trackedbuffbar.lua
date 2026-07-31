local ADDON_NAME, ns = ...

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
-- TRACKED BUFF BAR (CDM) MODULE
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
-- Handles skinning of the external "Tracked Bars" (Blizzard/CDM)
-- based on GravityUI settings.

ns.TrackedBuffBar = {}
local Module = ns.TrackedBuffBar

-- Cache
Module.knownBars = {} -- [frame] = true
local lastScan = 0
local SCAN_THROTTLE = 5.0

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
-- HELPERS
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ

local function GetSettings()
    return ns.GetDB().actionbars.cdmBuffbar
end

-- Read EllesmereUI CDM's useBlizzardBuffBars flag via Lite addon registry.
-- Returns: true  = EUI is using Blizzard bars (GravityUI can skin them)
--          false = EUI is using its own Tracking Bars (GravityUI should stay off)
--          nil   = EllesmereUICooldownManager not loaded / flag unknown
local function GetEUIUseBlizzardBars()
    if not C_AddOns.IsAddOnLoaded("EllesmereUICooldownManager") then return nil end
    local ok, result = pcall(function()
        local EUI = _G.EllesmereUI
        if not (EUI and EUI.Lite and EUI.Lite.GetAddon) then return nil end
        local ecme = EUI.Lite.GetAddon("EllesmereUICooldownManager", true)
        if not (ecme and ecme.db and ecme.db.profile) then return nil end
        local cdmBars = ecme.db.profile.cdmBars
        if cdmBars == nil then return nil end
        return cdmBars.useBlizzardBuffBars  -- true=Blizzard, false=EUI own bars
    end)
    if ok then return result end
    return nil
end

local function GetLSM()
    return LibStub("LibSharedMedia-3.0", true)
end

local function CheckSparkSize(region, bar)
    local w, h = region:GetSize()
    local barH = bar:GetHeight()
    if w and h and barH and w < 20 and h >= (barH - 5) then
        return true
    end
    return false
end

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
-- SKINNING LOGIC
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
-- SKINNING LOGIC
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ

function Module:ApplyTexture(bar)
    local db = GetSettings()
    if not db or not db.enabled then return end
    
    if bar.SetStatusBarTexture and db.texture then
        local LSM = GetLSM()
        local texture = LSM and LSM:Fetch("statusbar", db.texture) or "Interface\\TargetingFrame\\UI-StatusBar"
        local current = bar:GetStatusBarTexture()
        if not current or current:GetTexture() ~= texture then
            bar:SetStatusBarTexture(texture)
        end
    end
end

function Module:ApplyColor(bar)
    local db = GetSettings()
    if not db or not db.enabled then return end
    
    if bar.SetStatusBarColor then
        local r, g, b, a = 0, 0.57, 0.98, 1
        
        if db.useThemeColor then
             -- User wants Global Theme Color
             if ns.GetAccentColor then 
                 r, g, b, a = ns.GetAccentColor() 
             end
        else
             -- User wants Custom Bar Color
             if db.barColor and next(db.barColor) then
                 r, g, b, a = unpack(db.barColor)
             end
        end
        
        -- Check current to avoid redundant calls (optional)
        bar:SetStatusBarColor(r, g, b, a or 1) 
    end
end

function Module:SkinBar(bar)
    if not bar then return end
    local db = GetSettings()
    if not db or not db.enabled then return end
    
    -- Prevent double skinning/hooking
    if not bar.gravitySkinned then
         -- Hook Color updates to enforce our color
         if bar.SetStatusBarColor then
             hooksecurefunc(bar, "SetStatusBarColor", function()
                 if not Module.ignoreHooks then
                     Module.ignoreHooks = true
                     Module:ApplyColor(bar)
                     Module.ignoreHooks = false
                 end
             end)
         end
         -- Hook Texture updates
         if bar.SetStatusBarTexture then
             hooksecurefunc(bar, "SetStatusBarTexture", function()
                 if not Module.ignoreHooks then
                     Module.ignoreHooks = true
                     Module:ApplyTexture(bar)
                     Module.ignoreHooks = false
                 end
             end)
         end
         
         -- Hook Width updates removed by user request
         bar.gravitySkinned = true
    end

    -- 1. Dimensions
    if not bar:IsProtected() then
        -- Width controlled by Blizzard/External Addon
        if db.height then bar:SetHeight(db.height) end
    end

    -- 2. Initial Application
    Module.ignoreHooks = true
    self:ApplyTexture(bar)
    self:ApplyColor(bar)
    Module.ignoreHooks = false
    
    -- 4. Background
    -- Specific check for .BarBG (from Screenshot)
    local bgColor = {0, 0, 0, 0.5} -- Default fallback
    if db.useThemeBackground then
        -- Use Global Theme Background
        local globalDB = ns.GetDB()
        if globalDB and globalDB.general and globalDB.general.themeBgColor then
             bgColor = globalDB.general.themeBgColor
        end
    elseif db.backgroundColor and next(db.backgroundColor) then
        -- Use Custom Background Color
        bgColor = db.backgroundColor
    end

    if bar.BarBG and bar.BarBG.SetColorTexture then
        bar.BarBG:SetColorTexture(unpack(bgColor))
        bar.BarBG:ClearAllPoints()
        bar.BarBG:SetAllPoints(bar)
    elseif bar.bg or bar.background or bar.Background then
        local bg = bar.bg or bar.background or bar.Background
        if bg.SetColorTexture then
             bg:SetColorTexture(unpack(bgColor))
             bg:ClearAllPoints()
             bg:SetAllPoints(bar)
        end
    end
    
    -- 5. Font handling (Name / Time)
    local LSM = GetLSM()
    local fontPath = LSM and LSM:Fetch("font", db.font) or standardFont
    
    -- Identify Regions
    local nameRegion = bar.Name
    local timeRegion = bar.Time or bar.time or bar.Duration
    
    -- Fallback scan if not found directly
    if not nameRegion or not timeRegion then
        local regions = {bar:GetRegions()}
        for _, region in ipairs(regions) do
            if region:IsObjectType("FontString") then
                local text = region:GetText()
                -- Heuristic: If text is a number, it's time; otherwise name?
                -- Hard to be sure, just apply font to all for consistency
                if not nameRegion then nameRegion = region end
            end
        end
    end

    if nameRegion and nameRegion.SetFont then
         if db.fontSize then
             local _, _, outline = nameRegion:GetFont()
             nameRegion:SetFont(fontPath, db.fontSize, outline or "OUTLINE")
         end
    end
    
    if timeRegion and timeRegion.SetFont then
         if db.fontSize then
             local _, _, outline = timeRegion:GetFont()
             timeRegion:SetFont(fontPath, db.fontSize, outline or "OUTLINE")
         end
    end
    
    -- 6. Icon
    local icon = bar.icon or bar.Icon
    -- Check children for icon if not found
    if not icon and bar.GetChildren then
        for i = 1, select("#", bar:GetChildren()) do
             local child = select(i, bar:GetChildren())
             if child.Texture or (child.IsObjectType and child:IsObjectType("Texture")) then
                 -- This is risky, might catch random textures
             end
        end
    end
    -- Try parent's icon if bar is inside a row
    if not icon and bar:GetParent() and (bar:GetParent().icon or bar:GetParent().Icon) then
        icon = bar:GetParent().icon or bar:GetParent().Icon
    end

    if icon then
        if db.iconSize then
            icon:SetSize(db.iconSize, db.iconSize)
        end
        -- Icon Border
        if db.iconBorderSize and db.iconBorderSize > 0 then
            if not icon.border then
                 -- Create border
                 if icon.CreateTexture then
                     icon.border = icon:CreateTexture(nil, "BACKGROUND")
                 else
                     -- Fallback for frame icon
                     local parent = icon:GetParent() or bar
                     icon.border = parent:CreateTexture(nil, "BACKGROUND")
                 end
            end
            
            if icon.border then
                icon.border:ClearAllPoints()
                icon.border:SetPoint("CENTER", icon, "CENTER", 0, 0)
                local size = (db.iconSize or icon:GetWidth()) + (db.iconBorderSize * 2)
                icon.border:SetSize(size, size)
                
                local r, g, b, a = 0, 0, 0, 1
                if db.iconBorderColor then r, g, b, a = unpack(db.iconBorderColor) end
                icon.border:SetColorTexture(r, g, b, a)
                
                -- Ensure draw layer is correct
                icon.border:SetDrawLayer("BACKGROUND", -1)
            end
        elseif icon.border then
            icon.border:SetColorTexture(0,0,0,0) -- Hide if disabled
        end
    end
    
    -- 7. Spacing (Hook SetPoint)
    -- This is tricky. If we just want to expand the gap, we need to intercept the y-offset.
    if not bar.spacingHooked and db.spacing then
        hooksecurefunc(bar, "SetPoint", function(self, point, relativeTo, relativePoint, x, y)
            if not Module.ignoreHooks and type(y) == "number" and y ~= 0 then
                -- Determine if this is a vertical stacking point
                -- simple heuristic: if y is negative (going down) or positive (going up)
                -- we add the spacing to it.
                -- BUT avoiding infinite recursion or fighting.
                -- Use a separate adjustment? No, SetPoint is hard to override safely with hooksecurefunc without taint or infinite loops if we Call SetPoint again.
                -- Actually we CANNOT change arguments in hooksecurefunc.
                -- We would need to detour it.
            end
        end)
        bar.spacingHooked = true
    end
    -- 8. Spark Handling
    local spark = bar.Spark
    -- Fallback: Scan regions
    if not spark and bar.GetRegions then
        local regions = {bar:GetRegions()}
        for _, region in ipairs(regions) do
            if not region:IsForbidden() and region:IsObjectType("Texture") then
                local tex = region:GetTexture()
                -- 1. Check Path Name or Specific ID (6739577 found in debug)
                if (type(tex) == "string" and (tex:find("Spark") or tex:find("SPARK"))) or (tex == 6739577) then
                    spark = region
                    break
                end
                -- 2. Fallback: OVERLAY + Small Width (If ID changes in future)
                if not spark and region:GetDrawLayer() == "OVERLAY" and (not bar:IsProtected()) then
                     local isSpark = false
                     local ok, result = pcall(CheckSparkSize, region, bar)
                     if ok and result then
                         isSpark = true
                     end
                     if isSpark then
                         spark = region
                     end
                end
            end
        end
    end
    
    if spark then
        spark:ClearAllPoints()
        spark:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
        spark:SetSize(10, (db.height or bar:GetHeight()) * 1.7) -- Force large height (padding)
        
        -- Spark Color to Light Grey (Desaturated to kill yellow tint)
        if spark.SetDesaturated then spark:SetDesaturated(true) end
        if spark.SetVertexColor then
             local r, g, b, a = 0.85, 0.85, 0.85, 1
             if db.sparkColor then r, g, b, a = unpack(db.sparkColor) end
             spark:SetVertexColor(r, g, b, a)
        end

        if not spark.gravityHooked then
             hooksecurefunc(spark, "SetHeight", function(self, h)
                 local target = (db.height or bar:GetHeight()) * 1.7
                 if not Module.ignoreHooks and math.abs(h - target) > 0.1 then
                     Module.ignoreHooks = true
                     self:SetHeight(target)
                     Module.ignoreHooks = false
                 end
             end)
             -- Also hook SetSize
             if spark.SetSize then
                 hooksecurefunc(spark, "SetSize", function(self, w, h)
                     local target = (db.height or bar:GetHeight()) * 1.7
                     if not Module.ignoreHooks and math.abs(h - target) > 0.1 then
                         Module.ignoreHooks = true
                         self:SetHeight(target)
                         Module.ignoreHooks = false
                     end
                 end)
             end
             spark.gravityHooked = true
        end
    end
    
    -- 9. Force Width Constraint Check Removed
end

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
-- DISCOVERY
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ

function Module:ScanForBars()
    -- 1. Check known globals
    local targets = {
        "CooldownViewerFrame", 
        "CDMFrame", 
        "Blizzard_CooldownsBar",
        "BuffBarCooldownViewer", 
    }
    
    for _, name in ipairs(targets) do
        local obj = _G[name]
        
        -- Case A: It's a Frame (Container)
        if obj and type(obj) == "table" and obj.IsObjectType and obj:IsObjectType("Frame") then
             -- Heuristic: Is strict match?
             if not Module.knownBars[obj] and obj.SetStatusBarTexture then
                 Module.knownBars[obj] = true
             end
                 
             -- Scan Children
             for i = 1, select("#", obj:GetChildren()) do
                 local child = select(i, obj:GetChildren())
                 -- Direct Child Bar
                 if child.SetStatusBarTexture then
                     Module.knownBars[child] = true
                 end
                 -- .Bar wrapper (BuffBarCooldownViewer style)
                 if child.Bar and type(child.Bar) == "table" and child.Bar.SetStatusBarTexture then
                      Module.knownBars[child.Bar] = true
                 end
             end
             
        -- Case B: It's a Table of Frames (Registry)
        elseif obj and type(obj) == "table" then
             for k, v in pairs(obj) do
                 -- Check k/v
                 if type(v) == "table" and v.IsObjectType and v:IsObjectType("Frame") then
                      if v.SetStatusBarTexture then
                          Module.knownBars[v] = true
                      elseif v.Bar and v.Bar.SetStatusBarTexture then
                          Module.knownBars[v.Bar] = true
                      end
                 end
             end
        end
    end
    
    -- 2. Heuristic: Scan for the specific object pattern "BuffBarCooldownViewer.X.Bar"
    local root = _G["BuffBarCooldownViewer"]
    if root and root.GetChildren then
        for i = 1, select("#", root:GetChildren()) do
             local child = select(i, root:GetChildren())
             if child.Bar and child.Bar.SetStatusBarTexture then
                 Module.knownBars[child.Bar] = true
             end
             if child.SetStatusBarTexture then
                 Module.knownBars[child] = true
             end
        end
    end

    -- 3. Apply to all known
    for bar in pairs(Module.knownBars) do
        self:SkinBar(bar)
    end
    

end

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
-- DYNAMIC POSITIONING
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ

-- Remove Anchor Creation entirely (Use EditMode Position)

-- Helper: Find the container frame (Row) that holds the bar and icon
function Module:GetMovableFrame(bar)
    local parent = bar:GetParent()
    if parent and parent ~= UIParent then
        -- Heuristic: If parent has a .Bar/.Icon key, it's likely the container
        if parent.Bar == bar or parent.bar == bar then return parent end
        if parent.Icon or parent.icon then return parent end
        
        -- Heuristic: CooldownViewer specific naming?
        local name = parent:GetName()
        if name and (name:find("Row") or name:find("Bar")) then return parent end
    end
    return bar
end

function Module:UpdateLayout()
    local db = GetSettings()
    if not db or not db.enabled or not db.dynamicPositioning then return end
    
    -- 1. Gather Visible Frames (Containers)
    local visibleFrames = {}
    local seen = {}
    
    for bar in pairs(Module.knownBars) do
        local f = self:GetMovableFrame(bar)
        if f and f:IsVisible() and not seen[f] then
            -- Save current width if valid
            if f:GetWidth() > 10 then
                f.savedWidth = f:GetWidth()
            end
            table.insert(visibleFrames, f)
            seen[f] = true
        end
    end
    
    if #visibleFrames == 0 then return end
    
    -- 2. Sort
    table.sort(visibleFrames, function(a,b) 
        return (a:GetName() or tostring(a)) < (b:GetName() or tostring(b)) 
    end)
    
    -- 3. Stack
    local spacing = db.spacing or 5
    local growth = db.growDirection or "DOWN"
    local prev = nil -- First frame is the anchor
    
    Module.ignoreHooks = true -- Prevent recursive fighting
    
    for i, f in ipairs(visibleFrames) do
        -- Restore Width on Container
        if f.savedWidth then
             f:SetWidth(f.savedWidth)
        else
             f:SetWidth(230) -- Fallback default
        end
        
        if i == 1 then
             -- FORCE Anchor to Parent's Edge (EditMode Frame)
             local parent = f:GetParent()
             if parent then
                 f:ClearAllPoints()
                 if growth == "DOWN" then
                     -- Start at Top
                     f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
                 else
                     -- Start at Bottom
                     f:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
                 end
             end
             prev = f
        else
             f:ClearAllPoints()
             if growth == "DOWN" then
                 f:SetPoint("TOP", prev, "BOTTOM", 0, -spacing)
             else
                 f:SetPoint("BOTTOM", prev, "TOP", 0, spacing)
             end
             prev = f
        end
    end
    
    Module.ignoreHooks = false
end



local function DoLayoutUpdate()
    Module.layoutTimer = nil
    Module:UpdateLayout()
end

-- Performance: Debounce layout updates to prevent spamming
function Module:RequestLayout()
    if self.layoutTimer then return end 
    self.layoutTimer = C_Timer.After(0.05, DoLayoutUpdate)
end

-- Hook OnShow/OnHide to trigger layout
function Module:HookBarEvents(bar)
    if bar.gravityLayoutHooked then return end
    
    -- Hook Visibility on the BAR (since that's what we track)
    bar:HookScript("OnShow", function() Module:RequestLayout() end)
    bar:HookScript("OnHide", function() Module:RequestLayout() end)

    -- Hook SetPoint on the MOVABLE FRAME (Container)
    local f = self:GetMovableFrame(bar)
    if not f.gravityPointHooked then
        hooksecurefunc(f, "SetPoint", function(self)
            if Module.ignoreHooks then return end
            local db = GetSettings()
            if db and db.dynamicPositioning and self:IsVisible() then
                 Module:RequestLayout()
            end
        end)
        f.gravityPointHooked = true
    end
    
    bar.gravityLayoutHooked = true
end

-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ
-- LIFECYCLE
-- ÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉ

function Module:Refresh()
    self:ScanForBars()
    for bar in pairs(Module.knownBars) do
        self:SkinBar(bar)
        self:HookBarEvents(bar) -- Dynamic Layout Hook
    end
    
    -- Trigger Layout Update
    if self.anchor or (GetSettings() and GetSettings().dynamicPositioning) then
        self:UpdateLayout()
    end
end

function Module:Init()
    local db = GetSettings()
    if not db then return end

    -- ── EllesmereUI CDM bi-directional sync ──────────────────────────────────
    -- Runs before the db.enabled guard so we can auto-enable/disable based on
    -- what EllesmereUI CDM is currently doing.
    local euiUseBlizz = GetEUIUseBlizzardBars()

    if euiUseBlizz == false then
        -- EllesmereUI is using its own Tracking Bars → GravityUI must stay off
        if db.enabled then
            db.enabled = false
            print("|cff00ccffGravityUI:|r Tracked Bars auto-disabled " ..
                  "(EllesmereUI Tracking Bars are active).")
        end
        return

    elseif euiUseBlizz == true then
        -- EllesmereUI switched to Blizzard CDM Bars → enable GravityUI skinning
        if not db.enabled then
            db.enabled = true
            print("|cff00ccffGravityUI:|r Tracked Bars auto-enabled " ..
                  "(Blizzard CDM Bars are now active).")
        end
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- Normal guard: stop here if user has disabled Tracked Bars manually
    if not db.enabled then return end

    -- Register Event Hooks
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    f:SetScript("OnEvent", function(self, event)
        Module:Refresh()
    end)
    
    local function ApplyClickThrough()
        local obj = _G.BuffBarCooldownViewer
        if obj then
            if obj.SetMouseClickThrough then obj:SetMouseClickThrough(true) end
            if obj.EnableMouse then obj:EnableMouse(false) end
        end
    end

    -- Periodic Scan (to catch dynamically created bars)
    C_Timer.NewTicker(2.0, function()
        ApplyClickThrough()
        local anyVisible = false
        for bar in pairs(Module.knownBars) do
            if bar:IsVisible() then anyVisible = true; break end
        end
        if not anyVisible and next(Module.knownBars) ~= nil then return end
        Module:ScanForBars()
        Module:UpdateLayout()
    end)
    
    ApplyClickThrough()
    Module:Refresh()

    -- Hook the "Use Blizzard CDM Bars" card in EUI to show a GravityUI tooltip
    C_Timer.After(1.0, function() Module:HookBlizzardCard() end)
end

-------------------------------------------------------------------------------
-- EUI CDM CARD TOOLTIP HOOK
-- Finds "Use Blizzard CDM Bars" action card in EUI and adds a GravityUI info
-- tooltip so the user knows CDM Bar skinning will activate on switch.
-------------------------------------------------------------------------------

local function ScanForCardByTitle(frame, title, depth)
    if not frame or depth > 8 then return nil end
    local ok, children = pcall(function() return {frame:GetChildren()} end)
    if not ok then return nil end
    for _, child in ipairs(children) do
        -- Check FontString regions of this frame for matching title
        local ok2, regions = pcall(function() return {child:GetRegions()} end)
        if ok2 then
            for _, region in ipairs(regions) do
                local ok3, text = pcall(function()
                    return region:IsObjectType("FontString") and region:GetText()
                end)
                if ok3 and text == title then
                    return child  -- found the card frame
                end
            end
        end
        -- Recurse into children
        local found = ScanForCardByTitle(child, title, depth + 1)
        if found then return found end
    end
    return nil
end

function Module:HookBlizzardCard()
    local EUI = _G.EllesmereUI
    local root = EUI and EUI._mainFrame
    if not root then return end

    local card = ScanForCardByTitle(root, "Use Blizzard CDM Bars", 0)
    if not card then return end  -- page not built yet; will retry via Toggle hook

    -- EUI rebuilds the card frame on every page visit. Only hook the *new*
    -- frame pointer; skip if we already hooked this exact frame object.
    if self._blizzCardFrame == card then return end
    self._blizzCardFrame = card

    card:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:SetText("Use Blizzard CDM Bars", 1, 1, 1, 1, true)
        GameTooltip:AddLine("Switch back to Blizzard's bars.", 0.65, 0.65, 0.65, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ccffGravityUI:|r CDM Bar skinning will be activated.", 0, 0.8, 1, true)
        GameTooltip:Show()
    end)
    card:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end


-- Debug Command to help user identify the frame
SLASH_GUITRACKED1 = "/guitracked"
SlashCmdList["GUITRACKED"] = function()
    print("|cff00ccffGravityUI Tracked Bars Debug:|r")
    local db = GetSettings()
    print("  enabled:", db and db.enabled)
    print("  _blizzCardFrame:", tostring(Module._blizzCardFrame))

    local EUI = _G.EllesmereUI
    local root = EUI and EUI._mainFrame
    print("  EUI._mainFrame:", root and tostring(root) or "nil")

    if not root then
        print("  [!] EllesmereUI._mainFrame not found")
        return
    end

    -- Print all FontStrings found under EUI mainFrame (depth 8)
    local count = 0
    local function PrintFontStrings(frame, depth)
        if not frame or depth > 8 then return end
        local ok, children = pcall(function() return {frame:GetChildren()} end)
        if not ok then return end
        for _, child in ipairs(children) do
            local ok2, regions = pcall(function() return {child:GetRegions()} end)
            if ok2 then
                for _, region in ipairs(regions) do
                    local ok3, text = pcall(function()
                        return region:IsObjectType("FontString") and region:GetText()
                    end)
                    if ok3 and text and text ~= "" and count < 30 then
                        count = count + 1
                        print(string.format("  [d%d] '%s'", depth, text))
                    end
                end
            end
            PrintFontStrings(child, depth + 1)
        end
    end
    PrintFontStrings(root, 0)
    print("  Total FontStrings found:", count)
end
