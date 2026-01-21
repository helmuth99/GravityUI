---------------------------------------------------------------------------
-- GravityUI DeleteFix Module
---------------------------------------------------------------------------
local _, gui = ...

-- Die Logik für das automatische Ausfüllen
local function OnDeleteEvent(self, event)
    -- Zugriff auf deine AceDB-Einstellungen über den guiCore
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    local db = guiCore and guiCore.db.profile
    
    -- Nur ausführen, wenn der Regler in den Optionen AN ist (Standard: true)
    if not db or not db.DeleteFix or db.DeleteFix.enableDeleteFix == false then return end

    if StaticPopupDialogs["DELETE_ITEM"] then
        StaticPopup1EditBox:SetText(DELETE_ITEM_CONFIRM_STRING)
        StaticPopup1EditBox:HighlightText()
        StaticPopup1Button1:Enable()
    end
end

-- Event-Frame registrieren
local f = CreateFrame("Frame")
f:RegisterEvent("DELETE_ITEM_CONFIRM")
f:SetScript("OnEvent", OnDeleteEvent)