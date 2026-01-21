local _, gui = ...
local guiCore = _G.GravityUI and _G.GravityUI.guiCore

_G.GravityUI_RefreshMarks = function()
    local frame = _G.GravityUI_MarksBar
    if not frame then return end
    
    -- Im Kampf sind Größen- und Positionsänderungen von Secure-Buttons gesperrt
    if InCombatLockdown() then return end
    
    local db = guiCore.db.profile.marks
    
    -- 1. Hauptframe: Größe basierend auf Button-Size UND Spacing neu berechnen
    local width = (db.size * 9) + (db.spacing * 10)
    local height = db.size + (db.spacing * 2)
    frame:SetSize(width, height)
    
    -- Position & Sichtbarkeit
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.offsetX or 0, db.offsetY or 100)
    if db.enabled then frame:Show() else frame:Hide() end
    if db.mouseover then frame:SetAlpha(0) else frame:SetAlpha(1) end

    -- 2. Buttons: Positionen basierend auf dem neuen Spacing neu setzen
    for i = 1, 9 do
        local btn = _G["GravityUIMarkerBtn"..i]
        if btn then
            btn:SetSize(db.size, db.size)
            -- Die X-Position berechnet sich aus: (Anzahl Lücken * Spacing) + (Anzahl Buttons davor * Size)
            local xOffset = db.spacing + ((i-1) * (db.size + db.spacing))
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", frame, "LEFT", xOffset, 0)
        end
    end
end

local function CreateMarksBar()
    if _G.GravityUI_MarksBar then return end
    
    local db = guiCore.db.profile.marks
    if not db or not db.enabled then return end

    -- Hauptframe (Container)
    local frame = CreateFrame("Frame", "GravityUI_MarksBar", UIParent, "BackdropTemplate")
    local width = (db.size * 9) + (db.spacing * 10)
    local height = db.size + (db.spacing * 2)
    
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.offsetX or 0, db.offsetY or 100)
    frame:EnableMouse(true)
    
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0.6)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    -- Mouseover Logik
    local function UpdateAlpha(alpha)
        if db.mouseover then frame:SetAlpha(alpha) else frame:SetAlpha(1) end
    end

    frame:SetScript("OnEnter", function() UpdateAlpha(1) end)
    frame:SetScript("OnLeave", function() if not frame:IsMouseOver() then UpdateAlpha(0) end end)
    UpdateAlpha(0)

    -- Button Erstellung
    for i = 1, 9 do
        -- WICHTIG: "SecureActionButtonTemplate" ist zwingend erforderlich
        local btn = CreateFrame("Button", "GravityUIMarkerBtn"..i, frame, "SecureActionButtonTemplate")
        btn:SetSize(db.size, db.size)
        
        -- Diese Zeilen sind entscheidend für die Klick-Funktion:
        btn:RegisterForClicks("AnyUp", "AnyDown") 
        btn:SetAttribute("type", "macro") 

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        
if i < 9 then
            tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
            SetRaidTargetIconTexture(tex, i)
            
            -- Korrigiertes Mapping für Worldmarker
            local wmMap = { [1]=5, [2]=6, [3]=3, [4]=2, [5]=7, [6]=1, [7]=4, [8]=8 }
            local wmID = wmMap[i] or i
            
			-- Wir nutzen [nomod] für das Ziel-Markieren und [mod:shift] für den Worldmarker
			-- Der Befehl /tm X setzt die Markierung X oder entfernt sie, wenn sie schon da ist.
			btn:SetAttribute("macrotext", "/tm [nomod:shift] " .. i .. "\n/wm [mod:shift] " .. wmID)
        else
            -- Clear Button (X) bleibt wie von dir gewünscht
            tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            btn:SetAttribute("macrotext", "/tm [target=player,nomod:shift] 0\n/tm [nomod:shift] 0\n/clearraidmarkers [nomod:shift]\n/cwm [mod:shift] all")
        end

        btn:SetPoint("LEFT", frame, "LEFT", db.spacing + ((i-1) * (db.size + db.spacing)), 0)
        
        -- Mouseover-Sync für die Buttons
        btn:HookScript("OnEnter", function() UpdateAlpha(1) end)
        btn:HookScript("OnLeave", function() if not frame:IsMouseOver() then UpdateAlpha(0) end end)
    end

    -- Anchoring Support
    if gui.gui_Anchoring then
        gui.gui_Anchoring:RegisterAnchorTarget("Raid Marks", frame, {
            category = "Extras",
            defaultAnchor = "CENTER",
        })
    end
end

-- Start mit kleiner Verzögerung
C_Timer.After(1, function()
    if not _G.GravityUI_MarksBar then CreateMarksBar() end
end)