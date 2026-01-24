-- buffborders.lua
-- Fügt konfigurierbare schwarze Ränder um Buff/Debuff-Icons oben rechts hinzu

local _, gui = ...

-- Hole Einstellungen aus AceDB
local function GetSettings()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if not guiCore or not guiCore.db or not guiCore.db.profile then
        return nil
    end
    -- Stelle sicher dass buffBorders-Tabelle existiert
    if not guiCore.db.profile.buffBorders then
        guiCore.db.profile.buffBorders = {
            enableBuffs = true,
            enableDebuffs = true,
            hideBuffFrame = false,
            hideDebuffFrame = false,
            borderSize = 2,
            fontSize = 12,
            fontOutline = true,
        }
    end
    return guiCore.db.profile.buffBorders
end

-- Rand-Farben
local BORDER_COLOR_BUFF = {0, 0, 0, 1}        -- Schwarz für Buffs
local BORDER_COLOR_DEBUFF = {0.5, 0, 0, 1}    -- Dunkelrot für Debuffs

-- Verfolge welche Buttons wir bereits umrandet haben
local borderedButtons = {}

-- Füge Rand zu einem einzelnen Buff/Debuff-Button hinzu
local function AddBorderToButton(button, isBuff)
    if not button or borderedButtons[button] then
        return
    end
    
    -- Prüfe ob Ränder für diesen Typ aktiviert sind
    local settings = GetSettings()
    if not settings then return end
    if isBuff and not settings.enableBuffs then
        return
    end
    if not isBuff and not settings.enableDebuffs then
        return
    end
    
    -- Finde die Icon-Textur (das eigentliche quadratische Icon, nicht der volle Button-Frame)
    local icon = button.Icon or button.icon
    if not icon then
        return
    end

    -- Validiere dass Button ein korrekter Frame ist der CreateTexture unterstützt
    -- (Boss-Fight-Frames können Icon haben, aber keine gültigen Frame-Objekte sein)
    if not button.CreateTexture or type(button.CreateTexture) ~= "function" then
        return
    end
    
    local borderSize = settings.borderSize or 2
    
    -- Wähle Rand-Farbe basierend auf Buff/Debuff
    local borderColor = isBuff and BORDER_COLOR_BUFF or BORDER_COLOR_DEBUFF
    
    -- Erstelle 4 separate Kanten-Texturen für saubere Ränder nur um das ICON
    if not button.GravityBorderTop then
        -- Oberer Rand
        button.GravityBorderTop = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.GravityBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        
        -- Unterer Rand
        button.GravityBorderBottom = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        button.GravityBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        
        -- Linker Rand
        button.GravityBorderLeft = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.GravityBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        
        -- Rechter Rand
        button.GravityBorderRight = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.GravityBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        button.GravityBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    end
    
    -- Aktualisiere Rand-Farbe basierend auf Typ
    button.GravityBorderTop:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.GravityBorderBottom:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.GravityBorderLeft:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.GravityBorderRight:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    
    -- Aktualisiere Rand-Größe
    button.GravityBorderTop:SetHeight(borderSize)
    button.GravityBorderBottom:SetHeight(borderSize)
    button.GravityBorderLeft:SetWidth(borderSize)
    button.GravityBorderRight:SetWidth(borderSize)
    
    button.GravityBorderTop:Show()
    button.GravityBorderBottom:Show()
    button.GravityBorderLeft:Show()
    button.GravityBorderRight:Show()
    
    borderedButtons[button] = true
end

-- Verstecke Ränder auf einem Button
local function HideBorderOnButton(button)
    if button.GravityBorderTop then button.GravityBorderTop:Hide() end
    if button.GravityBorderBottom then button.GravityBorderBottom:Hide() end
    if button.GravityBorderLeft then button.GravityBorderLeft:Hide() end
    if button.GravityBorderRight then button.GravityBorderRight:Hide() end
end

-- Wende Schrift-Einstellungen auf Dauer-Text an
local function ApplyFontSettings(button)
    if not button then return end

    local settings = GetSettings()
    if not settings then return end

    -- Hole Schriftart und Outline aus generellen Einstellungen
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local generalFont = "Fonts\\FRIZQT__.TTF"
    local generalOutline = "OUTLINE"

    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.general then
        local general = guiCore.db.profile.general
        if general.font and LSM then
            generalFont = LSM:Fetch("font", general.font) or generalFont
        end
        generalOutline = general.fontOutline or "OUTLINE"
    end

    -- Dauer-Text (Timer zeigt verbleibende Zeit)
    local duration = button.Duration or button.duration
    if duration and duration.SetFont then
        local fontSize = settings.fontSize or 12
        duration:SetFont(generalFont, fontSize, generalOutline)
    end
end

-- Verarbeite alle Aura-Buttons in einem Container
local function ProcessAuraContainer(container, isBuff)
    if not container then return end
    
    -- Hole alle Child-Frames
    local frames = {container:GetChildren()}
    for _, frame in ipairs(frames) do
        -- Prüfe ob dies wie ein Aura-Button aussieht
        if frame.Icon or frame.icon then
            AddBorderToButton(frame, isBuff)
            ApplyFontSettings(frame)
        end
    end
end

-- Verstecke/zeige gesamten BuffFrame oder DebuffFrame basierend auf Einstellungen
local function ApplyFrameHiding()
    local settings = GetSettings()
    if not settings then return end

    -- BuffFrame-Verstecken (einfaches Hide + Show Hook, kein EnableMouse)
    if BuffFrame then
        if settings.hideBuffFrame then
            BuffFrame:Hide()
        else
            BuffFrame:Show()
        end
        -- Hook Show() einmalig um zu verhindern dass Blizzard erneut zeigt
        if not BuffFrame._gui_ShowHooked then
            BuffFrame._gui_ShowHooked = true
            hooksecurefunc(BuffFrame, "Show", function(self)
                local s = GetSettings()
                if s and s.hideBuffFrame then
                    self:Hide()
                end
            end)
        end
    end

    -- DebuffFrame-Verstecken (einfaches Hide + Show Hook, kein EnableMouse)
    if DebuffFrame then
        if settings.hideDebuffFrame then
            DebuffFrame:Hide()
        else
            DebuffFrame:Show()
        end
        -- Hook Show() einmalig um zu verhindern dass Blizzard erneut zeigt
        if not DebuffFrame._gui_ShowHooked then
            DebuffFrame._gui_ShowHooked = true
            hooksecurefunc(DebuffFrame, "Show", function(self)
                local s = GetSettings()
                if s and s.hideDebuffFrame then
                    self:Hide()
                end
            end)
        end
    end
end

-- Hauptfunktion zum Verarbeiten aller Buff/Debuff-Frames
local function ApplyBuffBorders()
    -- Wende Frame-Verstecken zuerst an
    ApplyFrameHiding()
    -- Verarbeite BuffFrame-Container (Buffs oben rechts)
    if BuffFrame and BuffFrame.AuraContainer then
        ProcessAuraContainer(BuffFrame.AuraContainer, true) -- true = buff
    end
    
    -- Verarbeite DebuffFrame falls es separat existiert
    if DebuffFrame and DebuffFrame.AuraContainer then
        ProcessAuraContainer(DebuffFrame.AuraContainer, false) -- false = debuff
    end
    
    -- Verarbeite Temporary-Enchant-Frames (behandle als Buffs)
    if TemporaryEnchantFrame then
        local frames = {TemporaryEnchantFrame:GetChildren()}
        for _, frame in ipairs(frames) do
            AddBorderToButton(frame, true) -- true = buff
            ApplyFontSettings(frame)
        end
    end
end

-- Debounce-Status für Buff-Border-Updates (gemeinsam über alle Hooks)
local buffBorderPending = false

-- Plane ein gedrosseltes Buff-Border-Update
-- Nur ein Timer läuft gleichzeitig, egal wie viele Hooks feuern
local function ScheduleBuffBorders()
    if buffBorderPending then return end
    buffBorderPending = true
    C_Timer.After(0.15, function()  -- 150ms Debounce für CPU-Effizienz
        buffBorderPending = false
        ApplyBuffBorders()
    end)
end

-- Hook in Aura-Update-Funktionen
local function HookAuraUpdates()
    -- Hook BuffFrame-Updates
    if BuffFrame and BuffFrame.Update then
        hooksecurefunc(BuffFrame, "Update", ScheduleBuffBorders)
    end

    -- Hook AuraContainer-Updates falls es existiert (Buffs)
    if BuffFrame and BuffFrame.AuraContainer and BuffFrame.AuraContainer.Update then
        hooksecurefunc(BuffFrame.AuraContainer, "Update", ScheduleBuffBorders)
    end

    -- Hook DebuffFrame-Updates
    if DebuffFrame and DebuffFrame.Update then
        hooksecurefunc(DebuffFrame, "Update", ScheduleBuffBorders)
    end

    -- Hook DebuffFrame.AuraContainer-Updates falls es existiert
    if DebuffFrame and DebuffFrame.AuraContainer and DebuffFrame.AuraContainer.Update then
        hooksecurefunc(DebuffFrame.AuraContainer, "Update", ScheduleBuffBorders)
    end

    -- Hook die globale Aura-Update-Funktion falls verfügbar
    if type(AuraButton_Update) == "function" then
        hooksecurefunc("AuraButton_Update", ScheduleBuffBorders)
    end
end

-- Performance: Redundante 1-Sekunden-Polling-Schleife entfernt
-- UNIT_AURA-Event und AuraButton_Update-Hook verwalten bereits alle Buff-Border-Updates

-- Initialisierung (UNIT_AURA verwaltet dynamische Updates)
-- Hinweis: Erstanwendung wird nun von guicore_main.lua OnEnable() aufgerufen um sicherzustellen dass AceDB bereit ist
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")

eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "UNIT_AURA" and arg == "player" then
        ScheduleBuffBorders()  -- Verwende gemeinsame Drosselung
    end
end)

-- Hook Aura-Updates beim ersten Laden
C_Timer.After(2, HookAuraUpdates)

-- Exportiere zu gui-Namespace
gui.BuffBorders = {
    Apply = ApplyBuffBorders,
    AddBorder = AddBorderToButton,
}

-- Globale Funktion für Config-Panel-Aufruf
_G.GravityUI_RefreshBuffBorders = function()
    borderedButtons = {}  -- Leere Cache um Neu-Umrandung zu erzwingen
    ApplyBuffBorders()
end

