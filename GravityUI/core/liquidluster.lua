-- GravityUI - Liquid Luster Bar
-- Shows a progress bar when the player uses the Liquid Luster potion.
-- Uses cast detection (UNIT_SPELLCAST_SUCCEEDED) + local timer approach,
-- because the Lustrous Gleam aura is unreliable via the Aura API in combat.
-- Displays: current Versa value | tick count (X/5) | time remaining.
-- Tick markers every 6 seconds on the bar for visual pacing.
local ADDON_NAME, ns = ...

ns.LiquidLuster = {}
local LL = ns.LiquidLuster

-------------------------------------------------------------------------------
--  Constants
-------------------------------------------------------------------------------
local CAST_SPELL_ID     = 1295132 -- Liquid Luster potion cast spell ID
local MAX_STACKS        = 5
local TICK_INTERVAL     = 6       -- seconds per stack
local TOTAL_DURATION    = 30      -- total buff duration
local VERSA_PER_STACK   = 420     -- Versatility per stack

local BAR_WIDTH         = 260
local BAR_HEIGHT        = 20
local TICK_WIDTH        = 2

local LSM = LibStub("LibSharedMedia-3.0", true)

-------------------------------------------------------------------------------
--  Settings
-------------------------------------------------------------------------------
local function GetSettings()
    local db = ns.GetDB()
    return db and db.uiimprovements and db.uiimprovements.liquidLuster
end

local function IsEnabled()
    local s = GetSettings()
    return s and s.enabled
end

local function GetFont()
    local s = GetSettings()
    -- Per-bar font override
    if s and s.font and s.font ~= "" and LSM then
        local fontPath = LSM:Fetch("font", s.font)
        if fontPath then return fontPath end
    end
    -- Fallback to global font
    local db = ns.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    local fontPath = LSM and LSM:Fetch("font", fontName)
    return fontPath or [[Interface\AddOns\GravityUI\media\font\Gravity.ttf]]
end

local function GetBarTexture()
    local s = GetSettings()
    if s and s.texture and s.texture ~= "" and LSM then
        local tex = LSM:Fetch("statusbar", s.texture)
        if tex then return tex end
    end
    local db = ns.GetDB()
    local texName = (db and db.general and db.general.statusBarTexture) or "Gravity"
    local tex = LSM and LSM:Fetch("statusbar", texName)
    return tex or "Interface\\TargetingFrame\\UI-StatusBar"
end

local function GetBarColor()
    local s = GetSettings()
    if s and not s.useThemeColor and s.barColor then
        local c = s.barColor
        return c[1] or 0, c[2] or 0.75, c[3] or 1, c[4] or 1
    end
    if ns.GetAccentColor then return ns.GetAccentColor() end
    return 0, 0.75, 1
end

local function GetBgColor()
    local s = GetSettings()
    if s and not s.useThemeColor and s.bgColor then
        local c = s.bgColor
        return c[1] or 0.08, c[2] or 0.08, c[3] or 0.10, c[4] or 0.85
    end
    if ns.GetThemeBgColor then
        local r, g, b = ns.GetThemeBgColor()
        return r, g, b, 0.85
    end
    return 0.08, 0.08, 0.10, 0.85
end

local function GetLastStackColor()
    local s = GetSettings()
    if s and s.lastStackColor then
        local c = s.lastStackColor
        return c[1] or 0.95, c[2] or 0.55, c[3] or 0.1, c[4] or 1
    end
    return 0.95, 0.55, 0.1, 1
end

-------------------------------------------------------------------------------
--  State
-------------------------------------------------------------------------------
local bar, barBG, barFill, barSpark
local versaText, tickText, timerText
local tickMarkers = {}
local eventFrame
local isActive = false
local isTestMode = false

-- Timer-based tracking state
local potStartTime = 0  -- GetTime() when the pot was used
local potEndTime   = 0  -- potStartTime + TOTAL_DURATION

-------------------------------------------------------------------------------
--  Position Persistence
-------------------------------------------------------------------------------
local function SavePosition()
    if not bar then return end
    local s = GetSettings()
    if not s then return end
    local p, _, rp, x, y = bar:GetPoint()
    if p then s.position = { p = p, rp = rp, x = x, y = y } end
end

local function ApplyPosition()
    if not bar then return end
    bar:ClearAllPoints()
    local s = GetSettings()
    local pos = s and s.position
    if pos and pos.p then
        bar:SetPoint(pos.p, UIParent, pos.rp or pos.p, pos.x or 0, pos.y or 0)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end
end

-------------------------------------------------------------------------------
--  Build the bar UI
-------------------------------------------------------------------------------
local function BuildBar()
    if bar then return end

    local s = GetSettings()
    local w = (s and s.width) or BAR_WIDTH
    local h = (s and s.height) or BAR_HEIGHT

    -- Main frame (movable)
    bar = CreateFrame("Frame", "GravityUI_LiquidLusterBar", UIParent)
    bar:SetSize(w, h)
    bar:SetFrameStrata("MEDIUM")
    bar:SetFrameLevel(10)
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self) self:StartMoving() end)
    bar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)
    bar:SetClampedToScreen(true)

    -- Background
    local bgR, bgG, bgB, bgA = GetBgColor()

    barBG = bar:CreateTexture(nil, "BACKGROUND")
    barBG:SetAllPoints()
    barBG:SetColorTexture(bgR, bgG, bgB, bgA)

    -- Border
    local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 0.8)

    -- Status bar fill
    barFill = CreateFrame("StatusBar", nil, bar)
    barFill:SetAllPoints()
    barFill:SetMinMaxValues(0, TOTAL_DURATION)
    barFill:SetValue(0)
    barFill:SetStatusBarTexture(GetBarTexture())

    -- Bar color
    local aR, aG, aB = GetBarColor()
    barFill:SetStatusBarColor(aR, aG, aB, 1)

    -- Spark (moving bright line at fill edge)
    barSpark = barFill:CreateTexture(nil, "OVERLAY")
    barSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    barSpark:SetBlendMode("ADD")
    barSpark:SetSize(12, h * 2.5)
    barSpark:SetAlpha(0.8)

    -- Tick markers (at 6, 12, 18, 24 seconds)
    for i = 1, MAX_STACKS - 1 do
        local tick = bar:CreateTexture(nil, "OVERLAY", nil, 2)
        tick:SetColorTexture(1, 1, 1, 0.35)
        tick:SetSize(TICK_WIDTH, h)
        local xPos = (i * TICK_INTERVAL / TOTAL_DURATION) * w
        tick:SetPoint("LEFT", bar, "LEFT", xPos - (TICK_WIDTH / 2), 0)
        tickMarkers[i] = tick
    end

    -- Font size scales with bar height
    local fontSize = math.max(9, math.floor(h * 0.55))

    -- Versa text (left)
    versaText = barFill:CreateFontString(nil, "OVERLAY")
    versaText:SetFont(GetFont(), fontSize, "OUTLINE")
    versaText:SetPoint("LEFT", bar, "LEFT", 4, 0)
    versaText:SetJustifyH("LEFT")
    versaText:SetTextColor(1, 1, 1, 1)

    -- Tick count text (center)
    tickText = barFill:CreateFontString(nil, "OVERLAY")
    tickText:SetFont(GetFont(), fontSize, "OUTLINE")
    tickText:SetPoint("CENTER", bar, "CENTER", 0, 0)
    tickText:SetJustifyH("CENTER")
    tickText:SetTextColor(1, 1, 1, 1)

    -- Timer text (right)
    timerText = barFill:CreateFontString(nil, "OVERLAY")
    timerText:SetFont(GetFont(), fontSize, "OUTLINE")
    timerText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    timerText:SetJustifyH("RIGHT")
    timerText:SetTextColor(1, 1, 1, 1)

    ApplyPosition()

    -- Register with mover system
    if ns.RegisterMover then
        ns.RegisterMover(bar, "Liquid Luster Bar")
    end

    bar:Hide()
end

-------------------------------------------------------------------------------
--  Refresh colors/size (called when theme changes or settings update)
-------------------------------------------------------------------------------
function LL.RefreshBar()
    if not bar then return end
    local s = GetSettings()
    local w = (s and s.width) or BAR_WIDTH
    local h = (s and s.height) or BAR_HEIGHT

    bar:SetSize(w, h)

    -- Re-position tick markers for new width
    for i = 1, MAX_STACKS - 1 do
        local tick = tickMarkers[i]
        if tick then
            tick:ClearAllPoints()
            tick:SetSize(TICK_WIDTH, h)
            local xPos = (i * TICK_INTERVAL / TOTAL_DURATION) * w
            tick:SetPoint("LEFT", bar, "LEFT", xPos - (TICK_WIDTH / 2), 0)
        end
    end

    -- Bar color (only if not in max-stack mode)
    if not bar._maxStackColor then
        local aR, aG, aB = GetBarColor()
        barFill:SetStatusBarColor(aR, aG, aB, 1)
    end

    -- Background
    local bgR, bgG, bgB, bgA = GetBgColor()
    barBG:SetColorTexture(bgR, bgG, bgB, bgA)

    -- Texture
    barFill:SetStatusBarTexture(GetBarTexture())

    -- Spark height
    if barSpark then barSpark:SetSize(12, h * 2.5) end

    -- Font
    local font = GetFont()
    local fontSize = math.max(9, math.floor(h * 0.55))
    versaText:SetFont(font, fontSize, "OUTLINE")
    tickText:SetFont(font, fontSize, "OUTLINE")
    timerText:SetFont(font, fontSize, "OUTLINE")
end

-------------------------------------------------------------------------------
--  Update loop (OnUpdate while active) — uses local timer, not aura API
-------------------------------------------------------------------------------
local function OnUpdate()
    if not isActive or not bar:IsShown() then return end
    if isTestMode then return end

    local now = GetTime()
    local elapsed = now - potStartTime
    local remaining = potEndTime - now

    -- Buff expired
    if remaining <= 0 then
        isActive = false
        bar:Hide()
        bar._maxStackColor = nil
        return
    end

    -- Calculate current stack: first stack at 0s, new stack every 6s
    -- Stack 1 at 0s, stack 2 at 6s, stack 3 at 12s, stack 4 at 18s, stack 5 at 24s
    local stacks = math.min(MAX_STACKS, math.floor(elapsed / TICK_INTERVAL) + 1)

    -- Update bar fill
    barFill:SetValue(elapsed)

    -- Color transition: orange glow at max stacks (burst window)
    if stacks >= MAX_STACKS then
        if not bar._maxStackColor then
            local lR, lG, lB, lA = GetLastStackColor()
            barFill:SetStatusBarColor(lR, lG, lB, lA)
            bar._maxStackColor = true
        end
    elseif bar._maxStackColor then
        local aR, aG, aB = GetBarColor()
        barFill:SetStatusBarColor(aR, aG, aB, 1)
        bar._maxStackColor = nil
    end

    -- Position spark at fill edge
    local s = GetSettings()
    local w = (s and s.width) or BAR_WIDTH
    local fillFrac = elapsed / TOTAL_DURATION
    local sparkX = fillFrac * w
    barSpark:ClearAllPoints()
    barSpark:SetPoint("CENTER", barFill, "LEFT", sparkX, 0)

    -- Versa text
    local currentVersa = stacks * VERSA_PER_STACK
    versaText:SetText(string.format("%d Versa", currentVersa))

    -- Tick count
    tickText:SetText(string.format("%d / %d", stacks, MAX_STACKS))

    -- Time remaining
    timerText:SetText(string.format("%.1fs", remaining))
end

-------------------------------------------------------------------------------
--  Events — detect potion cast via UNIT_SPELLCAST_SUCCEEDED
-------------------------------------------------------------------------------
local function OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if IsEnabled() then
            BuildBar()
        end

    elseif event == "PLAYER_DEAD" then
        if isActive then
            isActive = false
            isTestMode = false
            if bar then
                bar:Hide()
                bar._maxStackColor = nil
            end
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and spellID == CAST_SPELL_ID then
            if not IsEnabled() then return end
            BuildBar()
            potStartTime = GetTime()
            potEndTime = potStartTime + TOTAL_DURATION
            isActive = true
            isTestMode = false
            bar._maxStackColor = nil
            -- Reset bar color
            local aR, aG, aB = GetBarColor()
            barFill:SetStatusBarColor(aR, aG, aB, 1)
            bar:Show()
        end
    end
end

eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:SetScript("OnEvent", OnEvent)

-- OnUpdate ticker (throttled to ~20 FPS for performance)
local updateElapsed = 0
eventFrame:SetScript("OnUpdate", function(self, elapsed)
    updateElapsed = updateElapsed + elapsed
    if updateElapsed < 0.05 then return end
    updateElapsed = 0
    if isActive then OnUpdate() end
end)

-------------------------------------------------------------------------------
--  Public API
-------------------------------------------------------------------------------
function LL.ApplySettings()
    if IsEnabled() then
        BuildBar()
        LL.RefreshBar()
    else
        if bar then bar:Hide() end
        isActive = false
    end
end

function LL.TestBar()
    if not IsEnabled() then
        print("|cFF30D1FFGravityUI:|r Liquid Luster Bar is disabled. Enable it in Settings > Features > Stuff.")
        return
    end
    BuildBar()
    if bar:IsShown() then
        bar:Hide()
        isActive = false
        isTestMode = false
        bar._maxStackColor = nil
        print("|cFF30D1FFGravityUI:|r Liquid Luster test bar hidden.")
        return
    end
    -- Simulate a buff for testing (3/5 stacks, 12s elapsed, 18s remaining)
    isActive = true
    isTestMode = true
    barFill:SetValue(12)
    versaText:SetText("1260 Versa")
    tickText:SetText("3 / 5")
    timerText:SetText("18.0s")

    -- Position spark
    local s = GetSettings()
    local w = (s and s.width) or BAR_WIDTH
    barSpark:ClearAllPoints()
    barSpark:SetPoint("CENTER", barFill, "LEFT", (12 / 30) * w, 0)

    -- Reset color
    local aR, aG, aB = GetBarColor()
    barFill:SetStatusBarColor(aR, aG, aB, 1)
    bar._maxStackColor = nil

    bar:Show()
    print("|cFF30D1FFGravityUI:|r Liquid Luster test bar shown. Type /lltest again to hide.")
end

-- Hook into theme refresh
local origRefresh = ns.RefreshAccentColors
ns.RefreshAccentColors = function()
    if origRefresh then origRefresh() end
    if bar then LL.RefreshBar() end
end

-- Slash command for testing
SLASH_GRAVITYLLTEST1 = "/lltest"
SlashCmdList["GRAVITYLLTEST"] = function()
    if LL.TestBar then LL.TestBar() end
end
