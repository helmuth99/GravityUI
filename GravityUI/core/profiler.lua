-------------------------------------------------------------------------------
--- GravityUI Module Profiler (v2 — Aug 2026 Rewrite)
---
--- Lightweight per-module CPU profiling using debugprofilestop().
--- Does NOT require scriptProfile CVar, causes NO taint.
---
--- Usage:
---     /guiprofile modules     - Start module profiling
---     /guiprofile stop        - Stop module profiling
---     /guiprofile             - Show results (auto-detects mode)
---
--- Architecture (v2):
---   1. TICK SUBSCRIBERS: Uses ns.Tick.SetProfiler(hook) to intercept the
---      shared ticker's dispatch loop. This captures ALL subscribers — both
---      existing and newly registered — without re-registration.
---   2. STANDALONE OnUpdate: Wraps known high-frequency OnUpdate frames.
---   3. OnEvent HANDLERS: Wraps OnEvent scripts on discovered GravityUI
---      frames to count event dispatch frequency and CPU cost.
---   4. UIParent SCAN: Scans all UIParent children for GravityUI-named
---      frames and hooks both OnUpdate and OnEvent.
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local Profiler = {}
ns.Profiler = Profiler

-- State
local isActive = false
local moduleTimings = {}     -- key -> { calls = N, totalMs = N }
local eventCounts   = {}     -- key -> { [eventName] = count }
local profilingStartTime = 0 -- GetTime() when profiling started
local hookedFrameCount = 0   -- count of hooked frames for report

-- Saved references for unhooking
local hookedOnUpdates = {}   -- frame -> originalScript
local hookedOnEvents  = {}   -- frame -> originalScript

-------------------------------------------------------------------------------
-- Timing helpers (upvalue-cached for hot path)
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
-- Hook: Tick Profiler (v2 — uses SetProfiler API)
-- Installed directly into the shared ticker's dispatch loop.
-- Captures ALL subscribers instantly.
-------------------------------------------------------------------------------
local function InstallTickerHook()
    if not ns.Tick or not ns.Tick.SetProfiler then
        print("|cffff4444[GravityUI Profiler]|r Tick.SetProfiler not available — ticker.lua too old?")
        return
    end

    ns.Tick.SetProfiler(function(key, fn, elapsed)
        local entry = EnsureEntry("tick:" .. key)
        debugprofilestart()
        fn(elapsed)
        local ms = debugprofilestop()
        entry.calls = entry.calls + 1
        entry.totalMs = entry.totalMs + ms
    end)
end

local function RemoveTickerHook()
    if ns.Tick and ns.Tick.SetProfiler then
        ns.Tick.SetProfiler(nil)
    end
end

-------------------------------------------------------------------------------
-- Hook: Wrap standalone OnUpdate frames
-------------------------------------------------------------------------------
local function WrapOnUpdate(frame, moduleName)
    if not frame or hookedOnUpdates[frame] then return end
    local ok, origScript = pcall(frame.GetScript, frame, "OnUpdate")
    if not ok or not origScript then return end

    hookedOnUpdates[frame] = origScript
    hookedFrameCount = hookedFrameCount + 1
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
-- Hook: Wrap OnEvent handlers with CPU timing + event counting
-------------------------------------------------------------------------------
local function WrapOnEvent(frame, moduleName)
    if not frame or hookedOnEvents[frame] then return end
    local ok, origScript = pcall(frame.GetScript, frame, "OnEvent")
    if not ok or not origScript then return end

    hookedOnEvents[frame] = origScript
    hookedFrameCount = hookedFrameCount + 1
    frame:SetScript("OnEvent", function(self, event, ...)
        -- CPU timing
        local entry = EnsureEntry("event:" .. moduleName)
        debugprofilestart()
        origScript(self, event, ...)
        local ms = debugprofilestop()
        entry.calls = entry.calls + 1
        entry.totalMs = entry.totalMs + ms

        -- Event frequency counter
        if not eventCounts[moduleName] then eventCounts[moduleName] = {} end
        local ec = eventCounts[moduleName]
        ec[event] = (ec[event] or 0) + 1
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
-- Discovery: Find GravityUI frames to hook (v2 — much more aggressive)
-------------------------------------------------------------------------------
local function DiscoverAndHookFrames()
    hookedFrameCount = 0

    -- 1. Hook known global frame names (OnUpdate targets)
    local targets = {
        { globalName = "GravityUIActionBarFader",       module = "ActionBars (Fader)" },
        { globalName = "GravityUISkyridingFrame",       module = "Skyriding HUD" },
        { globalName = "GravityUI_SkyridingFrame",      module = "Skyriding HUD" },
        { globalName = "GravityUI_CombatTimer",         module = "CombatTimer" },
        { globalName = "GravityUI_CursorIndicator",     module = "Cursor Indicator" },
        { globalName = "GravityUI_CrosshairFrame",      module = "Crosshair" },
        { globalName = "GravityUI_ChatHider",           module = "Chat Hider" },
    }

    for _, t in ipairs(targets) do
        local frame = _G[t.globalName]
        if frame then
            WrapOnUpdate(frame, t.module)
            WrapOnEvent(frame, t.module)
        end
    end

    -- 2. Hook ns module tables (check .frame, .updateFrame, .eventFrame patterns)
    local moduleFrames = {
        { ref = ns.ScreenIndicators,    name = "ScreenIndicators" },
        { ref = ns.ActionBars,          name = "ActionBars" },
        { ref = ns.Objectives,          name = "Objectives" },
        { ref = ns.Styling,             name = "Styling" },        { ref = ns.Loot,                name = "Loot" },
        { ref = ns.InterruptTracker,    name = "InterruptTracker" },        { ref = ns.Chat,                name = "Chat" },
        { ref = ns.Tooltip,             name = "Tooltip" },
        { ref = ns.Character,           name = "Character" },
        { ref = ns.Inspect,             name = "Inspect" },
        { ref = ns.Consumables,         name = "Consumables" },
        { ref = ns.HealerMana,          name = "HealerMana" },
        { ref = ns.Automation,          name = "Automation" },
        { ref = ns.DeathAnnouncer,      name = "DeathAnnouncer" },
        { ref = ns.Mail,                name = "Mail" },
        { ref = ns.BuffBorders,         name = "BuffBorders" },
        { ref = ns.StanceText,          name = "StanceText" },
        { ref = ns.BattleRes,           name = "BattleRes/Bloodlust" },
        { ref = ns.CooldownText,        name = "CooldownText" },
        { ref = ns.DataTexts,           name = "DataTexts" },
    }

    -- Sub-frame key patterns to check on each module table
    local subKeys = { "frame", "updateFrame", "eventFrame", "_frame", "mainFrame" }

    for _, m in ipairs(moduleFrames) do
        if m.ref and type(m.ref) == "table" then
            -- Check if the module itself is a frame
            local isFrame = pcall(function() return m.ref.GetScript end) and m.ref.GetScript
            if isFrame then
                WrapOnUpdate(m.ref, m.name)
                WrapOnEvent(m.ref, m.name)
            end
            -- Check common sub-frame patterns
            for _, subKey in ipairs(subKeys) do
                local sub = m.ref[subKey]
                if sub and type(sub) == "table" then
                    local subIsFrame = pcall(function() return sub.GetScript end) and sub.GetScript
                    if subIsFrame then
                        WrapOnUpdate(sub, m.name .. " (" .. subKey .. ")")
                        WrapOnEvent(sub, m.name .. " (" .. subKey .. ")")
                    end
                end
            end
        end
    end

    -- 3. Aggressive UIParent child scan: hook ALL GravityUI-named frames
    -- pcall required: some Blizzard frames are forbidden/secure
    local numChildren = UIParent and UIParent.GetNumChildren and UIParent:GetNumChildren() or 0
    if numChildren > 0 then
        local ok, children = pcall(function() return { UIParent:GetChildren() } end)
        if ok and children then
            for _, child in ipairs(children) do
                local nameOk, name = pcall(child.GetName, child)
                if nameOk and name and (name:find("GravityUI") or name:find("Gravity_")) then
                    -- Try OnUpdate
                    local scriptOk, script = pcall(child.GetScript, child, "OnUpdate")
                    if scriptOk and script then
                        WrapOnUpdate(child, "frame:" .. name)
                    end
                    -- Try OnEvent
                    local eventOk, eventScript = pcall(child.GetScript, child, "OnEvent")
                    if eventOk and eventScript then
                        WrapOnEvent(child, "frame:" .. name)
                    end
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
    wipe(eventCounts)
    profilingStartTime = GetTime()

    -- Install hooks
    InstallTickerHook()
    DiscoverAndHookFrames()

    -- Report what we found
    local tickCount = ns.Tick and ns.Tick.Count and ns.Tick.Count() or 0
    local tickKeys = ns.Tick and ns.Tick.ListKeys and ns.Tick.ListKeys() or {}

    print("|cff00ccff[GravityUI Profiler]|r Module profiling started! (v2)")
    print(format("  |cff888888Tick subscribers: %d  |  Hooked frames: %d|r", tickCount, hookedFrameCount))
    if tickCount > 0 then
        local keyStr = table.concat(tickKeys, ", ")
        print(format("  |cff888888Tick keys: %s|r", keyStr))
    end
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
    RemoveTickerHook()
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

    -- --- Header ---
    print("|cff00ccff[GravityUI Profiler]|r Module CPU Report (" .. format("%.0fs elapsed", elapsed) .. "):")
    print("|cff888888" .. string.rep("-", 60) .. "|r")

    local totalMs = 0
    for _, entry in ipairs(sorted) do
        totalMs = totalMs + entry.totalMs
    end

    -- --- Module Entries ---
    local count = math.min(#sorted, 25)
    for i = 1, count do
        local d = sorted[i]
        local pct = totalMs > 0 and (d.totalMs / totalMs * 100) or 0
        local color = pct > 25 and "|cffff4444" or pct > 10 and "|cffffaa00" or "|cff44ff44"
        print(format("  %s%-30s|r %7.1fms  %6.2fms/s  %5.1f%%  (%dk calls)",
            color, d.name, d.totalMs, d.msPerSec, pct, d.calls / 1000))
    end

    if #sorted > count then
        print(format("  |cff888888... and %d more|r", #sorted - count))
    end

    -- --- Summary ---
    print("|cff888888" .. string.rep("-", 60) .. "|r")
    print(format("  |cffffffffTotal: %.1fms (%.2fms/s) across %d tracked modules|r",
        totalMs, totalMs / elapsed, #sorted))

    -- --- Event Frequency ---
    local hasEvents = false
    for _ in pairs(eventCounts) do hasEvents = true; break end
    if hasEvents then
        print("")
        print("|cff00ccff[GravityUI Profiler]|r Event Dispatch Frequency:")
        print("|cff888888" .. string.rep("-", 60) .. "|r")
        for modName, events in pairs(eventCounts) do
            -- Sort events by count
            local evSorted = {}
            local evTotal = 0
            for evName, evCount in pairs(events) do
                evSorted[#evSorted + 1] = { name = evName, count = evCount }
                evTotal = evTotal + evCount
            end
            table.sort(evSorted, function(a, b) return a.count > b.count end)

            local evPerSec = evTotal / elapsed
            local evColor = evPerSec > 50 and "|cffff4444" or evPerSec > 10 and "|cffffaa00" or "|cff44ff44"
            print(format("  %s%-25s|r %5d events (%.1f/s)", evColor, modName, evTotal, evPerSec))

            -- Top 3 events
            local topCount = math.min(#evSorted, 3)
            for j = 1, topCount do
                local e = evSorted[j]
                print(format("    |cff888888%-30s %5d (%.1f/s)|r", e.name, e.count, e.count / elapsed))
            end
        end
    end

    print("|cff888888  /guiprofile stop to finish|r")
end
