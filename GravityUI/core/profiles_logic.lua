-- GravityUI - Profile Logic
local ADDON_NAME, ns = ...

local Addon = ns.Addon
local AceSerializer = LibStub("AceSerializer-3.0", true)
local LibDeflate = LibStub("LibDeflate", true)

-- For compatibility with strings that use GravityUI.imports
_G.GravityUI = _G.GravityUI or {}
_G.GravityUI.imports = _G.GravityUI.imports or {}

-------------------------------------------------------------------------------
-- PROFILE IMPORT/EXPORT
-------------------------------------------------------------------------------

function Addon:ExportProfileToString()
    if not ns.db or not ns.db.profile then
        return "No profile loaded."
    end
    if not AceSerializer or not LibDeflate then
        return "Export requires AceSerializer-3.0 and LibDeflate."
    end

    local serialized = AceSerializer:Serialize(ns.db.profile)
    if not serialized or type(serialized) ~= "string" then
        return "Failed to serialize profile."
    end

    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then
        return "Failed to compress profile."
    end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
        return "Failed to encode profile."
    end

    return "gui1:" .. encoded
end

function Addon:ImportProfileFromString(str)
    if not ns.db or not ns.db.profile then
        return false, "No profile loaded."
    end
    if not AceSerializer or not LibDeflate then
        return false, "Import requires AceSerializer-3.0 and LibDeflate."
    end
    if not str or str == "" then
        return false, "No data provided."
    end

    str = str:gsub("%s+", "")
    str = str:gsub("^gui1:", "")  -- Update prefix
    str = str:gsub("^GUI1:", "")

    local compressed = LibDeflate:DecodeForPrint(str)
    if not compressed then
        return false, "Could not decode string (maybe corrupted)."
    end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return false, "Could not decompress data."
    end

    local ok, t = AceSerializer:Deserialize(serialized)
    if not ok or type(t) ~= "table" then
        return false, "Could not deserialize profile."
    end

    local profile = ns.db.profile
    for k in pairs(profile) do
        profile[k] = nil
    end
    for k, v in pairs(t) do
        profile[k] = v
    end

    if ns.GUI and ns.GUI.RefreshAll then
        ns.GUI:RefreshAll()
    end

    return true
end

-------------------------------------------------------------------------------
-- SAFE RELOAD SYSTEM
-----------------------------------------------
Addon.__pendingReload = false
Addon.__reloadEventFrame = nil

function Addon:SafeReload()
    if InCombatLockdown() then
        if not self.__pendingReload then
            self.__pendingReload = true
            print("|cFF30D1FFGravityUI:|r Reload queued - will execute when combat ends.")

            if not self.__reloadEventFrame then
                self.__reloadEventFrame = CreateFrame("Frame")
                self.__reloadEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                self.__reloadEventFrame:SetScript("OnEvent", function(frame, event)
                    if event == "PLAYER_REGEN_ENABLED" and Addon.__pendingReload then
                        Addon.__pendingReload = false
                        Addon:ShowReloadPopup()
                    end
                end)
            end
        end
    else
        ReloadUI()
    end
end

function Addon:ShowReloadPopup()
    if ns.GUI and ns.GUI.ShowConfirmation then
        ns.GUI:ShowConfirmation({
            title = "Reload Ready",
            message = "Combat ended. Click to reload the UI.",
            acceptText = "Reload Now",
            cancelText = "Later",
            onAccept = function() ReloadUI() end,
        })
    else
        print("|cFF30D1FFGravityUI:|r Combat ended. Type /reload to reload.")
    end
end
