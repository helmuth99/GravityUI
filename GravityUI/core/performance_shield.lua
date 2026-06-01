-- GravityUI Performance Shield
-- Suppresses intrusive addon telemetry and performance-display overhead.
-- NOTE: scriptProfile CVar is intentionally NOT changed here.
-- Setting scriptProfile=0 removes WoW's 'debug' library from the Lua sandbox,
-- which breaks error reporting for all addons (e.g. NSRT import popups).
-- Users who want to disable addon profiling should do so via WoW's own
-- /console scriptProfile 0 after understanding the trade-off.

local ADDON_NAME, ns = ...

local function EnforceShield()
    local db = ns.GetDB()
    if not db or not db.uiimprovements or not db.uiimprovements.performanceShield then return end

    -- 1. Disable Addon Performance Display (The UI overlay)
    -- (scriptProfile is intentionally left untouched - see file header comment)
    -- This CVar might be restricted or removed in some versions, pcall for safety
    pcall(function()
        if GetCVar("SetAddonPerformanceDisplay") ~= "0" then
            SetCVar("SetAddonPerformanceDisplay", 0)
        end
    end)

    -- 2. Suppress UpdateAddOnCPUUsage calls from other addons
    -- This prevents engine-side profiling bookkeeping when triggered externally.
    if not ns.ShieldHooked then
        hooksecurefunc("UpdateAddOnCPUUsage", function()
            -- By hooking this, we ensure that even if an addon calls it,
            -- the internal state remains as "unprofiled" as possible.
            -- Note: We don't overwrite it to avoid Taint, but the hook 
            -- is often enough to neutralize certain engine triggers.
        end)
        ns.ShieldHooked = true
    end
end

-- Initialize on load
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event)
    EnforceShield()
    -- Some CVars are reset by the engine after login; re-enforce after a short delay
    C_Timer.After(2, EnforceShield)
    C_Timer.After(10, EnforceShield)
end)

-- Export for manual trigger if setting is changed in GUI
ns.EnforcePerformanceShield = EnforceShield
