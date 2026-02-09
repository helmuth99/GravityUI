-- GravityUI Special Buttons
-- Cooldown Settings and Edit Mode integration
local ADDON_NAME, ns = ...

---------------------------------------------------------------------------
-- COOLDOWN SETTINGS BUTTON HANDLER
---------------------------------------------------------------------------
function ns.OpenCooldownSettings()
    if CooldownViewerSettings then
        if CooldownViewerSettings:IsShown() then
            CooldownViewerSettings:Hide()
        else
            CooldownViewerSettings:Show()
        end
        return true
    else
        print("|cFF30D1FFGravityUI:|r Cooldown Settings window not found.")
        print("|cFF30D1FFGravityUI:|r Make sure CDM (Cooldown Monitor) is enabled.")
        return false
    end
end



---------------------------------------------------------------------------
-- QUICK KEYBIND MODE (Bonus Feature)
---------------------------------------------------------------------------
function ns.OpenKeybindMode()
    if ns.Addon and ns.Addon.SlashCommandKeybind then
        ns.Addon:SlashCommandKeybind()
        return true
    end
    return false
end
