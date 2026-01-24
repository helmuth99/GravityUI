local addonName, ns = ...

-- Fallback für NUM_BAG_FRAMES falls nicht definiert
local NUM_BAG_FRAMES = NUM_BAG_FRAMES or 4

---------------------------------------------------------------------------
-- AUTO-INSERT KEYSTONE
---------------------------------------------------------------------------

-- Hole Einstellungen aus Datenbank
local function GetSettings()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.general then
        return guiCore.db.profile.general
    end
    return nil
end

-- Finde Keystone in Spielertaschen
local function FindKeystoneInBags()
    for bag = 0, NUM_BAG_FRAMES do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                local itemClass, itemSubClass = select(12, C_Item.GetItemInfo(itemID))
                if itemClass == Enum.ItemClass.Reagent and itemSubClass == Enum.ItemReagentSubclass.Keystone then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

-- Füge Keystone in M+-UI ein
local function InsertKeystone()
    local settings = GetSettings()
    if not settings or not settings.autoInsertKey then return end

    local bag, slot = FindKeystoneInBags()
    if not bag then return end

    C_Container.PickupContainerItem(bag, slot)
    if C_Cursor.GetCursorItem() then
        C_ChallengeMode.SlotKeystone()
    end
end

-- Hooke wenn Blizzards M+-UI lädt
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_ChallengesUI" then
        if ChallengesKeystoneFrame then
            ChallengesKeystoneFrame:HookScript("OnShow", InsertKeystone)
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
