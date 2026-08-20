-------------------------------------------------------------------------------
--- GravityUI Shared Ticker
---
--- Self-disarming OnUpdate driver: the driver frame only runs while at least
--- one subscriber is registered. When the last subscriber unregisters the
--- frame is Hidden and WoW fires no more OnUpdate calls -- zero CPU when idle.
---
--- Usage:
---     ns.Tick.Add("my_key", function(dt) ... end)   -- arm (idempotent)
---     ns.Tick.Remove("my_key")                       -- disarm
---     ns.Tick.Has("my_key")                          -- check
---     ns.Tick.Count()                                -- live subscriber count
---
---     -- Fixed-interval (Animation-based, no Lua between ticks):
---     local t = ns.Tick.NewAnimTicker(function() ... return true end, 1.0)
---     t.Start()   t.Stop()   t.IsPlaying()
---
--- Contract:
---   * Add is idempotent: same key replaces the function, no duplicate entry.
---   * A subscriber SHOULD remove itself once work has settled.
---     Removing from inside your own tick callback is safe.
---   * Remove on an unknown key is a no-op.
---   * dt is real elapsed seconds since the previous dispatch.
---
--- Adapted from EllesmereUI_Ticker.lua (EllesmereUI v8.8.6, 2026).
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local Tick = {}
ns.Tick = Tick

-------------------------------------------------------------------------------
-- Internal driver builder
-------------------------------------------------------------------------------
local function NewDriver(frame)
    if not frame then frame = CreateFrame("Frame") end

    local reg         = {}  -- dense key array
    local regFn       = {}  -- parallel function array
    local regInterval = {}  -- optional per-subscriber interval (nil = every frame)
    local regElapsed  = {}  -- accumulated elapsed per subscriber
    local index       = {}  -- key -> position
    local count       = 0
    local profilerHook = nil  -- function(key, fn, elapsed) or nil

    local drv = {}

    frame:Hide()
    frame:SetScript("OnUpdate", function(self, elapsed)
        local hook = profilerHook  -- upvalue snapshot for this frame
        local i = 1
        while i <= count do
            local key = reg[i]
            local fn  = regFn[i]

            -- Per-subscriber interval gating (added Aug 2026)
            -- When interval is set, accumulate elapsed and skip fn() until
            -- the interval is reached. Zero unnecessary Lua calls.
            local shouldCall = true
            local iv = regInterval[i]
            if iv then
                local acc = regElapsed[i] + elapsed
                if acc < iv then
                    regElapsed[i] = acc
                    shouldCall = false
                else
                    regElapsed[i] = 0
                end
            end

            if fn and shouldCall then
                if hook then
                    hook(key, fn, elapsed)
                else
                    fn(elapsed)
                end
            end
            if reg[i] == key then
                i = i + 1
            end
        end
        if count == 0 then
            self:Hide()
        end
    end)

    --- Register a subscriber. Optional 3rd arg = interval in seconds.
    --- When interval is set, the driver only calls fn() once per interval,
    --- accumulating elapsed time internally. Zero Lua calls between intervals.
    --- Without interval, fn() is called every frame (original behavior).
    function drv.Add(key, fn, interval)
        if not key or type(fn) ~= "function" then return end
        local i = index[key]
        if i then
            regFn[i]       = fn
            regInterval[i] = interval
            regElapsed[i]  = 0
            return
        end
        count              = count + 1
        reg[count]         = key
        regFn[count]       = fn
        regInterval[count] = interval
        regElapsed[count]  = 0
        index[key]         = count
        if count == 1 then frame:Show() end
    end

    function drv.Remove(key)
        local i = index[key]
        if not i then return end
        local lastKey      = reg[count]
        reg[i]             = lastKey
        regFn[i]           = regFn[count]
        regInterval[i]     = regInterval[count]
        regElapsed[i]      = regElapsed[count]
        index[lastKey]     = i
        reg[count]         = nil
        regFn[count]       = nil
        regInterval[count] = nil
        regElapsed[count]  = nil
        index[key]         = nil
        count              = count - 1
        if count == 0 then frame:Hide() end
    end

    function drv.Has(key)
        return index[key] ~= nil
    end

    function drv.Count()
        return count
    end

    --- Set a profiler hook function. When set, the dispatch loop calls
    --- hook(key, fn, elapsed) instead of fn(elapsed) for each subscriber.
    --- Pass nil to remove the hook.
    function drv.SetProfiler(hook)
        profilerHook = hook
    end

    --- Return a list of all currently registered subscriber keys.
    function drv.ListKeys()
        local keys = {}
        for i = 1, count do
            keys[i] = reg[i]
        end
        return keys
    end

    return drv
end

Tick.NewDriver = NewDriver

-------------------------------------------------------------------------------
-- Animation-based fixed-rate ticker
-- Uses WoW Animation engine for the interval. Zero Lua between ticks.
-- fn() returns truthy to keep ticking, falsy to self-stop.
-------------------------------------------------------------------------------
function Tick.NewAnimTicker(fn, interval, frame)
    if not frame then frame = CreateFrame("Frame") end
    local ag   = frame:CreateAnimationGroup()
    local anim = ag:CreateAnimation("Animation")
    ag:SetLooping("REPEAT")
    anim:SetDuration(interval or 1.0)

    ag:SetScript("OnLoop", function()
        if not fn() then ag:Stop() end
    end)

    local t = {}

    function t.Start(newInterval)
        if not ag:IsPlaying() then
            if newInterval then anim:SetDuration(newInterval) end
            ag:Play()
        end
    end

    function t.Stop()
        ag:Stop()
    end

    function t.IsPlaying()
        return ag:IsPlaying()
    end

    return t
end

-------------------------------------------------------------------------------
-- Shared driver: single OnUpdate frame for all GravityUI modules.
-- Frame is file-scope so WoW attributes work to GravityUI in the profiler.
-- When no subscribers are active the frame is hidden -> zero CPU.
-------------------------------------------------------------------------------
local _sharedFrame = CreateFrame("Frame")
local _shared = NewDriver(_sharedFrame)

Tick.Add         = _shared.Add
Tick.Remove      = _shared.Remove
Tick.Has         = _shared.Has
Tick.Count       = _shared.Count
Tick.SetProfiler = _shared.SetProfiler
Tick.ListKeys    = _shared.ListKeys
