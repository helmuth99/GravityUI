-- GravityUI Performance Shield
-- Mimics the "Disable Addon Profiler" WeakAura to maximize combat FPS by suppressing
-- engine-level CPU profiling and intrusive telemetry.
-- NOTE: Respects db.uiimprovements.profilingBypass (set by /guiprofile) to allow intentional profiling.

local ADDON_NAME, ns = ...

local function EnforceShield()
    local db = ns.GetDB()
    if not db or not db.uiimprovements or not db.uiimprovements.performanceShield then return end

    -- 1. Disable Engine-level CPU profiling (The expensive part)
    -- Skip if the user has intentionally enabled profiling via /guiprofile
    -- The bypass flag is persisted in SavedVariables so it survives restarts
    if db.uiimprovements.profilingBypass then return end

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
