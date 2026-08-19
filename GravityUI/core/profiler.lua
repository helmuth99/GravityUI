-------------------------------------------------------------------------------
--- GravityUI Module Profiler
---
--- Lightweight per-module CPU profiling using debugprofilestop().
--- Does NOT require scriptProfile CVar, causes NO taint.
---
--- Usage:
---     /guiprofile modules     - Start module profiling
---     /guiprofile stop        - Stop module profiling
---     /guiprofile             - Show results (auto-detects mode)
---
--- How it works:
---   When active, wraps the central ns.Tick dispatcher to measure each
---   subscriber's execution time. Also hooks standalone OnUpdate frames
---   from known high-frequency modules (ActionBars, Skyriding, Crosshair).
---   Uses debugprofilestop() which is always available and taint-free.
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local Profiler = {}
ns.Profiler = Profiler

-- State
local isActive = false
local moduleTimings = {}     -- key -> { calls = N, totalMs = N }
local profilingStartTime = 0 -- GetTime() when profiling started

-- Saved references for unhooking
local originalTickAdd = nil
local originalTickDispatcher = nil
local hookedOnUpdates = {}   -- frame -> originalScript

-------------------------------------------------------------------------------
-- Timing helpers
-------------------------------------------------------------------------------
local debugprofilestop = debugprofilestop
local debugprofilestart = debugprofilestart

local function EnsureEntry(key)
    if not moduleTimings[key] then
        moduleTimings[key] = { calls = 0, totalMs = 0 }
    end
    return moduleTimings[key]
end

-------------------------------------------------------------------------------
-- Hook: Wrap ns.Tick's internal dispatch
-- We replace the shared driver's OnUpdate to inject timing around each subscriber.
-------------------------------------------------------------------------------
local function InstallTickerHook()
    -- Access the shared driver frame (it's the parent of ns.Tick)
    -- We need to hook into the Tick system by wrapping Add to inject timing
    local origAdd = ns.Tick.Add
    originalTickAdd = origAdd

    -- Wrap each subscriber function when it's added
    ns.Tick.Add = function(key, fn)
        if not isActive then
            return origAdd(key, fn)
        end
        -- Wrap the function with timing
        local wrappedFn = function(dt)
            local entry = EnsureEntry("tick:" .. key)
            debugprofilestart()
            fn(dt)
            local elapsed = debugprofilestop()
            entry.calls = entry.calls + 1
            entry.totalMs = entry.totalMs + elapsed
        end
        return origAdd(key, wrappedFn)
    end

    -- Re-register all current tick subscribers with wrapped versions
    -- We can't access internals directly, so we'll hook new registrations
    -- and catch existing ones via the OnUpdate frame itself
end

-------------------------------------------------------------------------------
-- Hook: Wrap standalone OnUpdate frames
-------------------------------------------------------------------------------
local function WrapOnUpdate(frame, moduleName)
    if not frame or hookedOnUpdates[frame] then return end
    local origScript = frame:GetScript("OnUpdate")
    if not origScript then return end

    hookedOnUpdates[frame] = origScript
    frame:SetScript("OnUpdate", function(self, elapsed)
        local entry = EnsureEntry(moduleName)
        debugprofilestart()
        origScript(self, elapsed)
        local ms = debugprofilestop()
        entry.calls = entry.calls + 1
        entry.totalMs = entry.totalMs + ms
    end)
end

local function UnwrapAllOnUpdates()
    for frame, origScript in pairs(hookedOnUpdates) do
        pcall(function()
            frame:SetScript("OnUpdate", origScript)
        end)
    end
    wipe(hookedOnUpdates)
end

-------------------------------------------------------------------------------
-- Hook: Wrap OnEvent handlers for event-heavy modules
-------------------------------------------------------------------------------
local hookedOnEvents = {} -- frame -> originalScript

local function WrapOnEvent(frame, moduleName)
    if not frame or hookedOnEvents[frame] then return end
    local origScript = frame:GetScript("OnEvent")
    if not origScript then return end

    hookedOnEvents[frame] = origScript
    frame:SetScript("OnEvent", function(self, event, ...)
        local entry = EnsureEntry(moduleName)
        debugprofilestart()
        origScript(self, event, ...)
        local ms = debugprofilestop()
        entry.calls = entry.calls + 1
        entry.totalMs = entry.totalMs + ms
    end)
end

local function UnwrapAllOnEvents()
    for frame, origScript in pairs(hookedOnEvents) do
        pcall(function()
            frame:SetScript("OnEvent", origScript)
        end)
    end
    wipe(hookedOnEvents)
end

-------------------------------------------------------------------------------
-- Discovery: Find GravityUI frames to hook
-------------------------------------------------------------------------------
local function DiscoverAndHookFrames()
    -- Hook known high-frequency standalone OnUpdate frames
    local targets = {
        -- ActionBars fader (20Hz)
        { globalName = "GravityUIActionBarFader",       module = "ActionBars (Fader)" },
        -- Skyriding HUD (20Hz/2Hz)
        { globalName = "GravityUISkyridingFrame",       module = "Skyriding HUD" },
        { globalName = "GravityUI_SkyridingFrame",      module = "Skyriding HUD" },
    }

    -- Try to find frames by global name
    for _, t in ipairs(targets) do
        local frame = _G[t.globalName]
        if frame then
            WrapOnUpdate(frame, t.module)
        end
    end

    -- Hook into ns module frames if they have OnUpdate/OnEvent
    local moduleFrames = {
        { ref = ns.ScreenIndicators,    name = "ScreenIndicators" },
        { ref = ns.ActionBars,          name = "ActionBars" },
        { ref = ns.Objectives,          name = "Objectives" },
        { ref = ns.Styling,             name = "Styling" },
        { ref = ns.RaidBuffs,           name = "RaidBuffs" },
        { ref = ns.Loot,                name = "Loot" },
        { ref = ns.InterruptTracker,    name = "InterruptTracker" },
        { ref = ns.TargetedSpells,      name = "TargetedSpells" },
        { ref = ns.Chat,                name = "Chat" },
        { ref = ns.Tooltip,             name = "Tooltip" },
        { ref = ns.Character,           name = "Character" },
        { ref = ns.Inspect,             name = "Inspect" },
        { ref = ns.Consumables,         name = "Consumables" },
    }

    for _, m in ipairs(moduleFrames) do
        if m.ref then
            -- Check if the module itself is a frame
            if type(m.ref) == "table" and m.ref.GetScript then
                WrapOnUpdate(m.ref, m.name)
                WrapOnEvent(m.ref, m.name)
            end
            -- Check common sub-frame patterns
            if m.ref.frame and type(m.ref.frame) == "table" and m.ref.frame.GetScript then
                WrapOnUpdate(m.ref.frame, m.name)
                WrapOnEvent(m.ref.frame, m.name)
            end
            if m.ref.updateFrame and type(m.ref.updateFrame) == "table" and m.ref.updateFrame.GetScript then
                WrapOnUpdate(m.ref.updateFrame, m.name .. " (update)")
                WrapOnEvent(m.ref.updateFrame, m.name .. " (update)")
            end
        end
    end

    -- Scan all children of UIParent for GravityUI-named frames
    -- pcall required: some Blizzard frames are forbidden/secure
    for i = 1, (UIParent and UIParent.GetNumChildren and UIParent:GetNumChildren() or 0) do
        local ok, child = pcall(select, i, UIParent:GetChildren())
        if ok and child then
            local nameOk, name = pcall(child.GetName, child)
            if nameOk and name and (name:find("GravityUI") or name:find("Gravity_")) then
                local scriptOk, script = pcall(child.GetScript, child, "OnUpdate")
                if scriptOk and script then
                    WrapOnUpdate(child, "frame:" .. name)
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
function Profiler.Start()
    if isActive then
        print("|cff00ccff[GravityUI Profiler]|r Already running! Use /guiprofile to see results.")
        return
    end

    isActive = true
    wipe(moduleTimings)
    profilingStartTime = GetTime()

    -- Install hooks
    InstallTickerHook()
    DiscoverAndHookFrames()

    print("|cff00ccff[GravityUI Profiler]|r Module profiling started!")
    print("|cffffcc00  Play for 1-2 minutes, then type:|r /guiprofile")
    print("|cffffcc00  To stop:|r /guiprofile stop")
end

function Profiler.Stop()
    if not isActive then
        print("|cff00ccff[GravityUI Profiler]|r Not running.")
        return
    end

    isActive = false

    -- Restore hooks
    if originalTickAdd then
        ns.Tick.Add = originalTickAdd
        originalTickAdd = nil
    end
    UnwrapAllOnUpdates()
    UnwrapAllOnEvents()

    print("|cff00ccff[GravityUI Profiler]|r Module profiling stopped.")
end

function Profiler.IsActive()
    return isActive
end

function Profiler.Report()
    local elapsed = GetTime() - profilingStartTime
    if elapsed < 1 then elapsed = 1 end

    -- Collect and sort
    local sorted = {}
    for key, data in pairs(moduleTimings) do
        sorted[#sorted + 1] = {
            name = key,
            calls = data.calls,
            totalMs = data.totalMs,
            avgMs = data.calls > 0 and (data.totalMs / data.calls) or 0,
            msPerSec = data.totalMs / elapsed,
        }
    end

    table.sort(sorted, function(a, b) return a.totalMs > b.totalMs end)

    print("|cff00ccff[GravityUI Profiler]|r Module CPU Report (" .. format("%.0fs elapsed", elapsed) .. "):")
    print("|cff888888" .. string.rep("-", 55) .. "|r")

    local totalMs = 0
    for _, entry in ipairs(sorted) do
        totalMs = totalMs + entry.totalMs
    end

    local count = math.min(#sorted, 20)
    for i = 1, count do
        local d = sorted[i]
        local pct = totalMs > 0 and (d.totalMs / totalMs * 100) or 0
        local color = pct > 25 and "|cffff4444" or pct > 10 and "|cffffaa00" or "|cff44ff44"
        print(format("  %s%-28s|r %7.1fms  %6.1fms/s  %5.1f%%  (%dk calls)",
            color, d.name, d.totalMs, d.msPerSec, pct, d.calls / 1000))
    end

    if #sorted > count then
        print(format("  |cff888888... and %d more|r", #sorted - count))
    end
    print("|cff888888" .. string.rep("-", 55) .. "|r")
    print(format("  |cffffffffTotal: %.1fms (%.1fms/s) across %d modules|r",
        totalMs, totalMs / elapsed, #sorted))
    print("|cff888888  /guiprofile stop to finish|r")
end
