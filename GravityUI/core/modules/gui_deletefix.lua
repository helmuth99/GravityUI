---------------------------------------------------------------------------
-- GravityUI DeleteFix Module
---------------------------------------------------------------------------
local _, gui = ...

-- Logik für das automatische Ausfüllen des DELETE_ITEM_CONFIRM_STRING
local function OnDeleteEvent(self, event)
    -- Zugriff auf AceDB-Einstellungen über guiCore
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    local db = guiCore and guiCore.db.profile
    
    -- Nur ausführen, wenn DeleteFix in den Optionen aktiviert ist (Standard: true)
    if not db or not db.DeleteFix or db.DeleteFix.enableDeleteFix == false then return end

    if StaticPopupDialogs["DELETE_ITEM"] then
        StaticPopup1EditBox:SetText(DELETE_ITEM_CONFIRM_STRING)
        StaticPopup1EditBox:HighlightText()
        StaticPopup1Button1:Enable()
    end
end

-- Event-Frame für DELETE_ITEM_CONFIRM registrieren
local f = CreateFrame("Frame")
f:RegisterEvent("DELETE_ITEM_CONFIRM")
f:SetScript("OnEvent", OnDeleteEvent)