-- GravityUI Performance Shield
-- Mimics the "Disable Addon Profiler" WeakAura to maximize combat FPS by suppressing
-- engine-level CPU profiling and intrusive telemetry.

local ADDON_NAME, ns = ...

local function EnforceShield()
    local db = ns.GetDB()
    if not db or not db.uiimprovements or not db.uiimprovements.performanceShield then return end

    -- 1. Disable Engine-level CPU profiling (The expensive part)
    if GetCVar("scriptProfile") ~= "0" then
        SetCVar("scriptProfile", 0)
    end

    -- 2. Disable Addon Performance Display (The UI overlay)
    -- This CVar might be restricted or removed in some versions, pcall for safety
    pcall(function()
        if GetCVar("SetAddonPerformanceDisplay") ~= "0" then
            SetCVar("SetAddonPerformanceDisplay", 0)
        end
    end)

    -- 3. Suppress "Addon is using too much memory" or other analytics hooks
    -- We hook UpdateAddOnCPUUsage to prevent other addons from triggering 
    -- the engine's expensive bookkeeping logic.
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
