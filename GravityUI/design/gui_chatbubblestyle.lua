local ADDON_NAME, ns = ...
local guiCore = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0") -- Benötigt für die Schriftarten-Suche

---------------------------------------------------------------------------
-- Lokale Hilfsfunktion (Kopie aus guicore_main, um die Datei unabhängig zu machen)
---------------------------------------------------------------------------
local function GetFontPathDirectly()
    local db = guiCore.db.profile.general
    if not db then return nil end
    
    -- Holt den Pfad der gewählten Schriftart aus SharedMedia
    local fontPath = LSM:Fetch("font", db.font or "Gravity")
    return fontPath
end

---------------------------------------------------------------------------
-- Chat Bubble Logic
---------------------------------------------------------------------------
local function UpdateChatBubbleFont()
    local db = guiCore.db.profile.general
    if not db or not db.applyGlobalFontToBlizzard then return end

    -- Wir rufen jetzt unsere lokale Funktion oben auf
    local fontPath = GetFontPathDirectly()
    if not fontPath then return end

    -- Deine neuen Einstellungen aus der gui_options.lua
    local fontSize = db.chatBubbleFontSize or 8
    local fontOutline = db.chatBubbleFontOutline or "OUTLINE"

    -- Anwendung auf das Blizzard-Objekt
    if ChatBubbleFont and ChatBubbleFont.SetFont then
        ChatBubbleFont:SetFont(fontPath, fontSize, fontOutline)
    end
end

-- Hook: Wenn das Addon die globalen Fonts aktualisiert, ziehen wir mit
hooksecurefunc(guiCore, "ApplyGlobalFont", UpdateChatBubbleFont)

-- Event: Beim Laden der Welt einmalig ausführen
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
    UpdateChatBubbleFont()
end)

-- Globaler Refresh-Zugriff für deine gui_options.lua (RefreshCB)
_G.GravityUI_RefreshChatBubbles = UpdateChatBubbleFont