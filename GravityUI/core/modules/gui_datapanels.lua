--- GravityUI Datapanels
--- Erstellt und verwaltet verschiebbare Datatext-Panels

local ADDON_NAME, ns = ...
local guiCore = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

-- Modul-Referenz
local Datapanels = {}
guiCore.Datapanels = Datapanels

-- Aktive Panels Speicher
Datapanels.activePanels = {}

---=================================================================================
--- PANEL CREATION
---=================================================================================

--- Erstelle ein verschiebbares Datapanel
-- @param panelID string Eindeutiger Panel-Identifikator
-- @param config table Panel-Konfiguration
-- @return Frame Das erstellte Panel-Frame
function Datapanels:CreatePanel(panelID, config)
    if self.activePanels[panelID] then
        print("|cffff0000GravityUI:|r Panel '" .. panelID .. "' already exists!")
        return self.activePanels[panelID]
    end
    
    -- Erstelle Panel-Frame
    local panel = CreateFrame("Frame", "gui_Datapanel_" .. panelID, UIParent)
    panel:SetFrameStrata("LOW")
    panel:SetFrameLevel(100)
    panel:SetSize(config.width or 300, config.height or 22)
    
    -- Position
    if config.position then
        panel:SetPoint(config.position[1], UIParent, config.position[2], config.position[3], config.position[4])
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
    end
    
    -- Hintergrund
    panel.bg = panel:CreateTexture(nil, "BACKGROUND")
    panel.bg:SetAllPoints()
    panel.bg:SetColorTexture(0, 0, 0, (config.bgOpacity or 50) / 100)
    
    -- Ränder
    local borderSize = config.borderSize or 2
    local borderColor = config.borderColor or {0, 0, 0, 1}														  
    panel.borderLeft = panel:CreateTexture(nil, "BORDER")
    panel.borderRight = panel:CreateTexture(nil, "BORDER")
    panel.borderTop = panel:CreateTexture(nil, "BORDER")
    panel.borderBottom = panel:CreateTexture(nil, "BORDER")
    
    panel.borderLeft:SetColorTexture(unpack(borderColor))
    panel.borderRight:SetColorTexture(unpack(borderColor))
    panel.borderTop:SetColorTexture(unpack(borderColor))
    panel.borderBottom:SetColorTexture(unpack(borderColor))
    
    panel.borderLeft:SetWidth(borderSize)
    panel.borderRight:SetWidth(borderSize)
    panel.borderTop:SetHeight(borderSize)
    panel.borderBottom:SetHeight(borderSize)

    -- Verstecke Ränder wenn borderSize 0 ist (WoW erzwingt 1px Minimum bei Texturen)
    local showBorder = borderSize > 0
    panel.borderLeft:SetShown(showBorder)
    panel.borderRight:SetShown(showBorder)
    panel.borderTop:SetShown(showBorder)
    panel.borderBottom:SetShown(showBorder)

    panel.borderLeft:SetPoint("TOPRIGHT", panel, "TOPLEFT", 0, 0)
    panel.borderLeft:SetPoint("BOTTOMRIGHT", panel, "BOTTOMLEFT", 0, 0)
    
    panel.borderRight:SetPoint("TOPLEFT", panel, "TOPRIGHT", 0, 0)
    panel.borderRight:SetPoint("BOTTOMLEFT", panel, "BOTTOMRIGHT", 0, 0)
    
    panel.borderTop:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 0, 0)
    panel.borderTop:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", 0, 0)
    
    panel.borderBottom:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, 0)
    panel.borderBottom:SetPoint("TOPRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    
    -- Speichere Config
    panel.panelID = panelID
    panel.config = config
    panel.slots = {}
    
    -- Setup Ziehen
    self:SetupDragging(panel)
    
    -- Erstelle Slots
    self:UpdateSlots(panel)
    
    -- Speichere Panel
    self.activePanels[panelID] = panel
    
    -- Zeige/verstecke basierend auf Config UND ob Datatexts zugewiesen sind
    local hasDatatext = false
    if config.slots then
        for i = 1, (config.numSlots or 3) do
            if config.slots[i] and config.slots[i] ~= "" then
                hasDatatext = true
                break
            end
        end
    end
    
    if config.enabled and hasDatatext then
        panel:Show()
    else
        panel:Hide()
    end
    
    return panel
end

---=================================================================================
--- DRAGGING
---=================================================================================

function Datapanels:SetupDragging(panel)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetClampedToScreen(true)
    
    panel:SetScript("OnDragStart", function(self)
        if not self.config.locked then
            self:StartMoving()
        end
    end)
    
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        
        -- Speichere Position
        local point, _, relPoint, x, y = self:GetPoint()
        self.config.position = {point, relPoint, x, y}
        
        -- Aktualisiere gespeicherte Variablen
        local db = guiCore.db.profile.guiDatatexts
        if db and db.panels then
            for i, panelConfig in ipairs(db.panels) do
                if panelConfig.id == self.panelID then
                    db.panels[i].position = self.config.position
                    break
                end
            end
        end
    end)
end

--- Sperre/entsperre Panel-Bewegung
function Datapanels:SetLocked(panelID, locked)
    local panel = self.activePanels[panelID]
    if not panel then return end
    
    panel.config.locked = locked
    panel:SetMovable(not locked)
    
    -- Visuelles Feedback wenn entsperrt
    if locked then
        panel.bg:SetColorTexture(0, 0, 0, (panel.config.bgOpacity or 50) / 100)
    else
        panel.bg:SetColorTexture(0.2, 0.2, 0.5, (panel.config.bgOpacity or 50) / 100)  -- Blauer Tönung
    end
end

---=================================================================================
--- SLOT MANAGEMENT
---=================================================================================

function Datapanels:UpdateSlots(panel)
    -- Lösche existierende Slots
    for _, slot in ipairs(panel.slots) do
        if guiCore.Datatexts then
            guiCore.Datatexts:DetachFromSlot(slot)
        end
        slot:Hide()
        slot:SetParent(nil)
    end
    panel.slots = {}
    
    local numSlots = panel.config.numSlots or 3
    local slotWidth = panel:GetWidth() / numSlots
    local slotHeight = panel:GetHeight()
    
    -- Wende Schrift-Einstellungen an
    local generalFont = "Gravity"
    local generalOutline = "OUTLINE"
    if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.general then
        local general = guiCore.db.profile.general
        generalFont = general.font or "Gravity"
        generalOutline = general.fontOutline or "OUTLINE"
    end
    local fontPath = LSM:Fetch("font", generalFont) or "Fonts\\FRIZQT__.TTF"
    local fontSize = panel.config.fontSize or 12
    
    for i = 1, numSlots do
        local slot = CreateFrame("Button", panel:GetName() .. "_Slot" .. i, panel)
        slot:SetSize(slotWidth, slotHeight)
        slot:SetPoint("LEFT", panel, "LEFT", (i - 1) * slotWidth, 0)
        
        -- Erstelle Text für Datatext-Nutzung
        slot.text = slot:CreateFontString(nil, "OVERLAY")
        guiCore:SafeSetFont(slot.text, fontPath, fontSize, generalOutline)
        -- Verankere an beiden Kanten um Breite zu begrenzen und Auto-Truncation zu ermöglichen
        slot.text:SetPoint("LEFT", slot, "LEFT", 1, 0)
        slot.text:SetPoint("RIGHT", slot, "RIGHT", -1, 0)
        slot.text:SetJustifyH("CENTER")
        slot.text:SetWordWrap(false)
        slot.text:SetTextColor(1, 1, 1, 1)
        
        -- Speichere Slot-Index
        slot.index = i
        
        -- Wende pro-Slot shortLabel/noLabel Einstellungen an (#119)
        local slotSettings = panel.config.slotSettings and panel.config.slotSettings[i]
        slot.shortLabel = slotSettings and slotSettings.shortLabel or false
        slot.noLabel = slotSettings and slotSettings.noLabel or false
        -- Leite Drag-Events an Parent weiter
        slot:EnableMouse(true)
        slot:RegisterForDrag("LeftButton")
        slot:SetScript("OnDragStart", function()
            if not panel.config.locked then
                panel:StartMoving()
            end
        end)
        slot:SetScript("OnDragStop", function()
            panel:StopMovingOrSizing()
            
            -- Speichere Position
            local point, _, relPoint, x, y = panel:GetPoint()
            panel.config.position = {point, relPoint, x, y}
        end)
        
        -- Hänge Datatext an falls konfiguriert
        local datatextID = panel.config.slots and panel.config.slots[i]
        if datatextID and guiCore.Datatexts then
            guiCore.Datatexts:AttachToSlot(slot, datatextID, panel.config)
        else
            -- Zeige Platzhalter für leere Slots
            slot.text:SetText("|cffFFAA00Slot " .. i .. "|r")
            slot.text:Show()
        end
        
        table.insert(panel.slots, slot)
    end
end

---=================================================================================
--- PANEL MANAGEMENT
---=================================================================================

--- Aktualisiere Panel-Erscheinung
function Datapanels:UpdatePanel(panelID)
    local panel = self.activePanels[panelID]
    if not panel then return end
    
    -- Aktualisiere Größe
    panel:SetSize(panel.config.width or 300, panel.config.height or 22)
    
    -- Aktualisiere Hintergrund-Deckkraft
    panel.bg:SetColorTexture(0, 0, 0, (panel.config.bgOpacity or 50) / 100)
    
    -- Aktualisiere Ränder
    local borderSize = panel.config.borderSize or 2
    local borderColor = panel.config.borderColor or {0, 0, 0, 1}
    panel.borderLeft:SetWidth(borderSize)
    panel.borderRight:SetWidth(borderSize)
    panel.borderTop:SetHeight(borderSize)
    panel.borderBottom:SetHeight(borderSize)
    panel.borderLeft:SetColorTexture(unpack(borderColor))
    panel.borderRight:SetColorTexture(unpack(borderColor))
    panel.borderTop:SetColorTexture(unpack(borderColor))
    panel.borderBottom:SetColorTexture(unpack(borderColor))													   

    -- Verstecke Ränder wenn borderSize 0 ist (WoW erzwingt 1px Minimum bei Texturen)
    local showBorder = borderSize > 0
    panel.borderLeft:SetShown(showBorder)
    panel.borderRight:SetShown(showBorder)
    panel.borderTop:SetShown(showBorder)
    panel.borderBottom:SetShown(showBorder)

    -- Aktualisiere Position falls geändert
    if panel.config.position then
        panel:ClearAllPoints()
        panel:SetPoint(panel.config.position[1], UIParent, panel.config.position[2], panel.config.position[3], panel.config.position[4])
    end
    
    -- Aktualisiere Slots
    self:UpdateSlots(panel)
    
    -- Zeige/verstecke
    if panel.config.enabled then
        panel:Show()
    else
        panel:Hide()
    end
end

--- Lösche ein Panel
function Datapanels:DeletePanel(panelID)
    local panel = self.activePanels[panelID]
    if not panel then return end
    
    -- Trenne alle Datatexts ab
    for _, slot in ipairs(panel.slots) do
        if guiCore.Datatexts then
            guiCore.Datatexts:DetachFromSlot(slot)
        end
    end
    
    -- Entferne Frame
    panel:Hide()
    panel:SetParent(nil)
    
    -- Entferne aus Speicher
    self.activePanels[panelID] = nil
end

--- Aktualisiere alle Panels von gespeicherten Variablen
function Datapanels:RefreshAll()
    -- Lösche existierende Panels
    for panelID, panel in pairs(self.activePanels) do
        self:DeletePanel(panelID)
    end
    
    -- Erstelle Panels von gespeicherten Variablen
    local db = guiCore.db.profile.guiDatatexts
    if not db or not db.panels then return end
    
    for _, panelConfig in ipairs(db.panels) do
        if panelConfig.id then
            self:CreatePanel(panelConfig.id, panelConfig)
        end
    end
end

---=================================================================================
--- GLOBAL REFRESH FUNCTION
---=================================================================================

_G.GravityUI_RefreshDatapanels = function()
    if guiCore and guiCore.Datapanels then
        guiCore.Datapanels:RefreshAll()
    end
end

---=================================================================================
--- INITIALIZATION
---=================================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            Datapanels:RefreshAll()
            
            -- Debug: Zeige wie viele Panels erstellt wurden
            local count = 0
            for _ in pairs(Datapanels.activePanels) do
                count = count + 1
            end
            -- Panels erstellt stillschweigend
        end)
        self:UnregisterAllEvents()
    end
end)

-- Debug Slash-Befehl
SLASH_guiDATAPANELS1 = "/guidp"
SlashCmdList["guiDATAPANELS"] = function(msg)
    if msg == "show" then
        local count = 0
        for id, panel in pairs(Datapanels.activePanels) do
            count = count + 1
            print(string.format("|cff00ff00Panel %s:|r %s at %s, %dx%d, %s", 
                id, 
                panel:IsShown() and "VISIBLE" or "HIDDEN",
                tostring(panel.config.position),
                panel:GetWidth(),
                panel:GetHeight(),
                panel.config.enabled and "enabled" or "disabled"
            ))
        end
        print(string.format("|cff00ff00GravityUI:|r Total panels: %d", count))
    elseif msg == "refresh" then
        Datapanels:RefreshAll()
        print("|cff00ff00GravityUI:|r Refreshed all datapanels")
    else
        print("|cff00ff00GravityUI Datapanels Commands:|r")
        print("/guidp show - List all panels and their status")
        print("/guidp refresh - Refresh all panels")
    end
end

