-- cooldownmanager.lua
-- Saubere Cooldown-Manager-Funktionalität integriert in GravityUI
-- Entfernt Padding von Cooldown-Icons und verwaltet Icon-Layout
-- Hinweis: Swipe-Sichtbarkeit wird von cooldownswipe.lua verwaltet

local _, gui = ...

-- Lokale Variablen
local viewerPending = {}
local updateBucket = {}

-- Kernfunktion zum Entfernen von Padding und Anwenden von Modifikationen
local function RemovePadding(viewer)
    -- Wende keine Modifikationen im Edit-Modus an
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end
    
    -- Greife nicht ein falls Layout gerade angewendet wird
    if viewer._layoutApplying then
        return
    end
    
    local children = {viewer:GetChildren()}
    
    -- Hole die sichtbaren Icons (weil sie vollständig dynamisch sind)
    local visibleChildren = {}
    for _, child in ipairs(children) do
        if child:IsShown() then
            -- Speichere ursprüngliche Position zum Sortieren
            local point, relativeTo, relativePoint, x, y = child:GetPoint(1)
            child.originalX = x or 0
            child.originalY = y or 0
            table.insert(visibleChildren, child)
        end
    end
    
    if #visibleChildren == 0 then return end
    
    -- Sortiere nach ursprünglicher Position um Blizzard-Reihenfolge beizubehalten
    local isHorizontal = viewer.isHorizontal
    if isHorizontal then
        -- Sortiere links nach rechts, dann oben nach unten
        table.sort(visibleChildren, function(a, b)
            if math.abs(a.originalY - b.originalY) < 1 then
                return a.originalX < b.originalX
            end
            return a.originalY > b.originalY
        end)
    else
        -- Sortiere oben nach unten, dann links nach rechts
        table.sort(visibleChildren, function(a, b)
            if math.abs(a.originalX - b.originalX) < 1 then
                return a.originalY > b.originalY
            end
            return a.originalX < b.originalX
        end)
    end
    
    -- Hole Layout-Einstellungen vom Viewer
    local stride = viewer.stride or #visibleChildren

    -- KONFIGURATIONSOPTIONEN:
    local overlap = -3 -- Icons überlappen leicht, um transparente Ränder zu verstecken
    local iconScale = 1.15 -- Skalierung für Icons
    
    -- Skaliere die Icons zum Überlappen und Verstecken der transparenten Ränder in den Texturen
    for _, child in ipairs(visibleChildren) do
        if child.Icon then
            child.Icon:ClearAllPoints()
            child.Icon:SetPoint("CENTER", child, "CENTER", 0, 0)
            child.Icon:SetSize(child:GetWidth() * iconScale, child:GetHeight() * iconScale)
        end
        
        -- Swipe-Sichtbarkeit wird nun von cooldownswipe.lua verwaltet
    end
    
    -- Positioniere Buttons neu unter Beachtung von Orientierung und Stride
    local buttonWidth = visibleChildren[1]:GetWidth()
    local buttonHeight = visibleChildren[1]:GetHeight()
    
    -- Berechne Grid-Dimensionen
    local numIcons = #visibleChildren
    local totalWidth, totalHeight
    
    if isHorizontal then
        local cols = math.min(stride, numIcons)
        local rows = math.ceil(numIcons / stride)
        totalWidth = cols * buttonWidth + (cols - 1) * overlap
        totalHeight = rows * buttonHeight + (rows - 1) * overlap
    else
        local rows = math.min(stride, numIcons)
        local cols = math.ceil(numIcons / stride)
        totalWidth = cols * buttonWidth + (cols - 1) * overlap
        totalHeight = rows * buttonHeight + (rows - 1) * overlap
    end
    
    -- Berechne Offsets um Grid zu zentrieren
    local startX = -totalWidth / 2
    local startY = totalHeight / 2
    
    if isHorizontal then
        -- Horizontales Layout mit Wrapping
        for i, child in ipairs(visibleChildren) do
            local index = i - 1
			local row = math.floor(index / stride)
			local col = index % stride

			-- Bestimme Anzahl der Icons in dieser Reihe
			local rowStart = row * stride + 1
			local rowEnd = math.min(rowStart + stride - 1, numIcons)
			local iconsInRow = rowEnd - rowStart + 1

			-- Berechne die tatsächliche Breite dieser Reihe
			local rowWidth = iconsInRow * buttonWidth + (iconsInRow - 1) * overlap

			-- Zentriere diese Reihe
			local rowStartX = -rowWidth / 2

			-- Spalten-Offset innerhalb zentrierter Reihe
			local xOffset = rowStartX + col * (buttonWidth + overlap)
			local yOffset = startY - row * (buttonHeight + overlap)

			child:ClearAllPoints()
			child:SetPoint("CENTER", viewer, "CENTER", xOffset + buttonWidth/2, yOffset - buttonHeight/2)
        end
    else
        -- Vertikales Layout mit Wrapping
        for i, child in ipairs(visibleChildren) do
            local row = (i - 1) % stride
            local col = math.floor((i - 1) / stride)
            
            local xOffset = startX + col * (buttonWidth + overlap)
            local yOffset = startY - row * (buttonHeight + overlap)
            
            child:ClearAllPoints()
            child:SetPoint("CENTER", viewer, "CENTER", xOffset + buttonWidth/2, yOffset - buttonHeight/2)
        end
    end
end

-- Pending-Flag um mehrere Schedule-Aufrufe zu einem Timer zu konsolidieren
local updatePending = false

-- Plane ein Update um Modifikationen nach Blizzard anzuwenden
local function ScheduleUpdate(viewer)
    updateBucket[viewer] = true
    if updatePending then return end
    updatePending = true
    C_Timer.After(0, function()
        updatePending = false
        for v in pairs(updateBucket) do
            updateBucket[v] = nil
            RemovePadding(v)
        end
    end)
end

-- Swipe-Sichtbarkeit wird nun zentral von cooldownswipe.lua verwaltet
-- Diese Datei verwaltet nur Icon-Layout (Padding-Entfernung, Skalierung, Positionierung)

-- Exportiere Funktion zu gui-Namespace
gui.CooldownManager = {
    RemovePadding = RemovePadding,
    ScheduleUpdate = ScheduleUpdate,
}

