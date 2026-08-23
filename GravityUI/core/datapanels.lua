-- GravityUI - Custom Datatext Panels Manager
local ADDON_NAME, ns = ...
local DT = ns.Datatexts

-- Initialize namespace
ns.Datapanels = {}
local DP = ns.Datapanels

local panels = {} -- Active panel frames

-- =---------------------------------------------------------------------------
-- HELPER: Create Panel Frame
-- =---------------------------------------------------------------------------
local function CreatePanelFrame(id, config)
    local name = "GravityUI_CustomPanel_" .. id
    -- Main Frame (No BackdropTemplate needed for manual textures)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(config.width or 200, config.height or 22)
    frame:SetPoint(config.point or "CENTER", UIParent, config.relativePoint or "CENTER", config.x or 0, config.y or 0)
    
    -- Manual Textures for Styling
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.borderTop = frame:CreateTexture(nil, "BORDER")
    frame.borderBottom = frame:CreateTexture(nil, "BORDER")
    frame.borderLeft = frame:CreateTexture(nil, "BORDER")
    frame.borderRight = frame:CreateTexture(nil, "BORDER")
    
    local function UpdateBorder(self, cfg)
        -- Support both direct call and colon syntax
        if not cfg then cfg = self end
        
        -- Safety: Clear any legacy backdrops from previous versions
        if frame.SetBackdrop then frame:SetBackdrop(nil) end
        
        local borderSize = cfg.borderSize or 1
        local bgOpacity = (cfg.bgOpacity or 60) / 100
        
        -- Apply Background
        frame.bg:ClearAllPoints()
        if bgOpacity > 0 then
            frame.bg:Show()
            frame.bg:SetColorTexture(0, 0, 0, bgOpacity)
            frame.bg:SetPoint("TOPLEFT", borderSize, -borderSize)
            frame.bg:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
        else
            frame.bg:Hide()
        end
        
        -- Apply Border
        local r, g, b = 0, 0.75, 1
        if cfg.useThemeColorBorder then
            r, g, b = ns.GetAccentColor()
        elseif cfg.borderColor then
            r, g, b = cfg.borderColor[1], cfg.borderColor[2], cfg.borderColor[3]
        end
        
        if borderSize > 0 then
            -- Set Colors
            frame.borderTop:SetColorTexture(r, g, b, 1)
            frame.borderBottom:SetColorTexture(r, g, b, 1)
            frame.borderLeft:SetColorTexture(r, g, b, 1)
            frame.borderRight:SetColorTexture(r, g, b, 1)
            
            -- Anchoring
            frame.borderTop:ClearAllPoints()
            frame.borderTop:SetPoint("TOPLEFT", 0, 0)
            frame.borderTop:SetPoint("TOPRIGHT", 0, 0)
            frame.borderTop:SetHeight(borderSize)
            frame.borderTop:Show()
            
            frame.borderBottom:ClearAllPoints()
            frame.borderBottom:SetPoint("BOTTOMLEFT", 0, 0)
            frame.borderBottom:SetPoint("BOTTOMRIGHT", 0, 0)
            frame.borderBottom:SetHeight(borderSize)
            frame.borderBottom:Show()
            
            frame.borderLeft:ClearAllPoints()
            frame.borderLeft:SetPoint("TOPLEFT", 0, 0)
            frame.borderLeft:SetPoint("BOTTOMLEFT", 0, 0)
            frame.borderLeft:SetWidth(borderSize)
            frame.borderLeft:Show()
            
            frame.borderRight:ClearAllPoints()
            frame.borderRight:SetPoint("TOPRIGHT", 0, 0)
            frame.borderRight:SetPoint("BOTTOMRIGHT", 0, 0)
            frame.borderRight:SetWidth(borderSize)
            frame.borderRight:Show()
        else
            frame.borderTop:Hide()
            frame.borderBottom:Hide()
            frame.borderLeft:Hide()
            frame.borderRight:Hide()
        end
    end
    UpdateBorder(config)
    frame.UpdateBorder = UpdateBorder

    -- Movement / Dragging logic
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    -- Mover Overlay (Visible when unlocked)
    local mover = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    mover:SetAllPoints(frame)
    mover:SetFrameLevel(frame:GetFrameLevel() + 20)
    mover:SetBackdrop({bgFile = [[Interface\Buttons\WHITE8x8]]})
    mover:SetBackdropColor(0, 0.75, 1, 0.4)
    mover:Hide()
    
    local moverText = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moverText:SetPoint("CENTER")
    moverText:SetText(config.name or id)
    mover.text = moverText
    
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetScript("OnDragStart", function() frame:StartMoving() end)
    mover:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = frame:GetPoint()
        config.point = point
        config.relativePoint = relPoint
        config.x = math.floor(x + 0.5)
        config.y = math.floor(y + 0.5)
        if ns.GUI and ns.GUI.RefreshPage then ns.GUI:RefreshPage("datapanels") end
    end)

    frame.mover = mover
    frame.slots = {}
    
    return frame
end

-- =---------------------------------------------------------------------------
-- HELPER: Populate Slots
-- =---------------------------------------------------------------------------
local function UpdatePanelSlots(frame, config)
    -- Update Size
    frame:SetSize(config.width or 200, config.height or 22)
    frame:ClearAllPoints()
    frame:SetPoint(config.point or "CENTER", UIParent, config.relativePoint or "CENTER", config.x or 0, config.y or 0)
    
    -- Update Border & Backdrop (Call after size is set)
    if frame.UpdateBorder then frame:UpdateBorder(config) end
    
    -- Insets for slots (respect borderSize)
    local border = config.borderSize or 1
    local panelW = math.max(1, frame:GetWidth() - (border * 2))
    local panelH = math.max(1, frame:GetHeight() - (border * 2))

    -- Mover Visibility & Name update
    if config.locked then
        frame.mover:Hide()
    else
        frame.mover:Show()
        frame.mover:SetAllPoints(frame)
        frame.mover.text:SetText(config.name or "Panel")
    end

    local numVisible = config.numSlots or 3
    if numVisible == 0 then
        if config.locked then frame:Hide() else frame:Show() end
        return
    end
    
    frame:Show()
    
    local slotWidth = panelW / numVisible
    for i = 1, 5 do
        local sCfg = config.slots[i]
        local slot = frame.slots[i]
        
        if i <= numVisible then
            if not slot then
                slot = CreateFrame("Button", nil, frame)
                slot:SetFrameLevel(frame:GetFrameLevel() + 5)
                slot.text = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                slot.text:SetPoint("CENTER", 0, 0)
                frame.slots[i] = slot
                slot:RegisterForClicks("AnyUp")
            end
            
            slot:Show()
            slot:SetSize(slotWidth, panelH)
            slot:SetPoint("LEFT", frame, "LEFT", border + (i-1) * slotWidth, 0)
            
            slot:SetScript("OnEnter", function(self) if sCfg and sCfg.content ~= "" then DT:HandleOnEnter(self, sCfg) end end)
            slot:SetScript("OnLeave", function(self) if sCfg and sCfg.content ~= "" then DT:HandleOnLeave(self, sCfg) else GameTooltip:Hide() end end)
            slot:SetScript("OnClick", function(self, btn) if sCfg and sCfg.content ~= "" then DT:HandleOnClick(self, btn, sCfg) end end)
            
            slot.Update = function()
                local font, outline = ns.GetFont()
                slot.text:SetFont(font, config.fontSize or 12, outline)
                
                -- Labels should ALWAYS be white. Values are colored via internal hex codes.
                slot.text:SetTextColor(1, 1, 1, 1)

                local text = ""
                if sCfg and sCfg.content ~= "" then
                    -- Pass panel-level hideLabel setting to the datatext engine
                    text = DT:GetContentText(i, sCfg, config.hideLabel)
                end
                slot.text:SetText(text)
            end
            slot:Update()
        elseif slot then
            slot:Hide()
        end
    end
    
    frame.UpdateFonts = function()
        for i=1, 5 do
            if frame.slots[i] and frame.slots[i]:IsShown() then 
                frame.slots[i].Update() 
            end
        end
    end
end

-- =---------------------------------------------------------------------------
-- MAIN INTERFACE
-- =---------------------------------------------------------------------------

function DP:RefreshAll()
    local db = ns.GetDB()
    if not db or not db.datapanels or not db.datapanels.custom then return end
    
    for id, config in pairs(db.datapanels.custom) do
        local frame = panels[id]
        if config.enabled then
            if not frame then
                frame = CreatePanelFrame(id, config)
                panels[id] = frame
            end
            UpdatePanelSlots(frame, config)

            -- EDIT MODE INTEGRATION: Register each custom panel with GravityUI's
            -- mover system so it appears in Edit Mode as a draggable overlay.
            if ns.Movers and ns.Movers.Register and not frame._guiMoverRegistered then
                frame._guiMoverRegistered = true
                local moverName = "DataPanel_" .. id
                local panelLabel = "Panel: " .. (config.name or id)
                ns.Movers:Register(moverName, frame, function(f, enabled, force)
                    if enabled or force then
                        -- Show the existing mover overlay in GravityUI Edit Mode
                        if frame.mover then
                            frame.mover:Show()
                            frame.mover.text:SetText(config.name or id)
                        end
                    else
                        -- Hide mover overlay when exiting Edit Mode (unless panel is unlocked)
                        if frame.mover and config.locked then
                            frame.mover:Hide()
                        end
                    end
                end, panelLabel)
            end
        elseif frame then
            frame:Hide()
        end
    end
    
    -- Cleanup deleted panels
    for id, frame in pairs(panels) do
        if not db.datapanels.custom[id] then
            frame:Hide()
            panels[id] = nil
        end
    end
end

local DEFAULT_CUSTOM_PANELS = {
    ["Panel 1"] = {
        name = "Durability", enabled = true, numSlots = 1, width = 250, height = 24,
        point = "BOTTOMRIGHT", relativePoint = "BOTTOMRIGHT", x = -8, y = 71,
        fontSize = 12, bgOpacity = 50, borderSize = 0, locked = true,
        useThemeColor = true, useThemeColorBorder = true,
        slots = { [1] = { content = "durability", shortLabel = true } }
    },
    ["Panel 2"] = {
        name = "Spec/Loot", enabled = true, numSlots = 1, width = 250, height = 24,
        point = "BOTTOMRIGHT", relativePoint = "BOTTOMRIGHT", x = -8, y = 47,
        fontSize = 12, bgOpacity = 50, borderSize = 0, locked = true,
        slots = { [1] = { content = "spec" } }
    },
    ["Panel 3"] = {
        name = "Gold", enabled = true, numSlots = 1, width = 250, height = 24,
        point = "BOTTOMRIGHT", relativePoint = "BOTTOMRIGHT", x = -8, y = 23,
        fontSize = 12, bgOpacity = 50, borderSize = 0, locked = true,
        slots = { [1] = { content = "gold" } }
    },
    ["Panel 4"] = {
        name = "FPS/MS", enabled = true, numSlots = 2, width = 120, height = 24,
        point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -76, y = -244,
        fontSize = 12, bgOpacity = 0, borderSize = 0, locked = true,
        slots = { [1] = { content = "fps" }, [2] = { content = "ms" } }
    },
}

-- Auto-refresh on a timer for text updates
local ticker
function DP:Init()
    local db = ns.GetDB()
    if not db or not db.datapanels then return end
    
    -- One-time initialization of default panels into user profile
    if db.datapanels.initialized == false then
        for id, config in pairs(DEFAULT_CUSTOM_PANELS) do
            if not db.datapanels.custom[id] then
                -- Deep copy logic (manual for this simple structure)
                local newCfg = {}
                for k, v in pairs(config) do
                    if type(v) == "table" then
                        newCfg[k] = {}
                        for k2, v2 in pairs(v) do
                            if type(v2) == "table" then
                                newCfg[k][k2] = {}
                                for k3, v3 in pairs(v2) do newCfg[k][k2][k3] = v3 end
                            else
                                newCfg[k][k2] = v2
                            end
                        end
                    else
                        newCfg[k] = v
                    end
                end
                db.datapanels.custom[id] = newCfg
            end
        end
        db.datapanels.initialized = true
    end

    DP:RefreshAll()
    
    local function IsHighPriority(config)
        if not config or not config.slots then return false end
        for i = 1, 5 do
            local slot = config.slots[i]
            if slot and (slot.content == "fps" or slot.content == "ms") then
                return true
            end
        end
        return false
    end

    if ns.Tick.Has("datapanels_update") then ns.Tick.Remove("datapanels_update") end

    -- PERF: Tick.Add with interval parameter — the driver accumulates elapsed
    -- time internally and only calls the function once per second.
    -- Zero unnecessary Lua calls, safe OnUpdate context (no taint).
    local tickCount = 0
    ns.Tick.Add("datapanels_update", function()
        tickCount = tickCount + 1
        local checkPassive = (tickCount % 5 == 0)
        
        for id, frame in pairs(panels) do
            if frame:IsShown() and frame.UpdateFonts then
                local config = db.datapanels.custom[id]
                if IsHighPriority(config) or checkPassive then
                    frame.UpdateFonts()
                end
            end
        end
        if checkPassive then tickCount = 0 end
    end, 1.0)
end

-- Export to ns for initialization
ns.RefreshDatapanels = function() DP:Init() end
