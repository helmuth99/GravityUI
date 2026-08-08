-- GravityUI Custom Color Picker
-- Replaces Blizzard's ColorPickerFrame addon-wide via a secure hook.
-- Exposes ns.ColorPicker:Open() as the public API for internal use.
-- Features: HSV Square, Hue/Alpha Bars, Theme/Class/Recent/Saved Tabs, Hex Copy.
local ADDON_NAME, ns = ...

ns.ColorPicker = ns.ColorPicker or {}
local CP = ns.ColorPicker

-- ============================================================
-- Static Palette (Gravity Blue – Glassmorphic 2026)
-- ============================================================
local C_BG      = {0,    0,    0   }
local C_ELEM    = {0.1,  0.1,  0.1 }
local C_BORDER  = {0.12, 0.12, 0.12}
local C_ACCENT  = {0,    0.6,  1   }
local C_TEXT    = {0.9,  0.92, 0.95}
local C_MUTED   = {0.5,  0.5,  0.55}
local C_WARNING = {0.96, 0.62, 0.04}

local FONT_PATH = "Interface/AddOns/GravityUI/assets/Gravity.ttf"

-- ============================================================
-- Class Colors
-- ============================================================
local CLASS_COLORS = {
    { name = "Warrior",      r = 0.78, g = 0.61, b = 0.43 },
    { name = "Paladin",      r = 0.96, g = 0.55, b = 0.73 },
    { name = "Hunter",       r = 0.67, g = 0.83, b = 0.45 },
    { name = "Rogue",        r = 1.00, g = 0.96, b = 0.41 },
    { name = "Priest",       r = 1.00, g = 1.00, b = 1.00 },
    { name = "Death Knight", r = 0.77, g = 0.12, b = 0.23 },
    { name = "Shaman",       r = 0.00, g = 0.44, b = 0.87 },
    { name = "Mage",         r = 0.41, g = 0.80, b = 0.94 },
    { name = "Warlock",      r = 0.58, g = 0.51, b = 0.79 },
    { name = "Monk",         r = 0.00, g = 1.00, b = 0.59 },
    { name = "Druid",        r = 1.00, g = 0.49, b = 0.04 },
    { name = "Demon Hunter", r = 0.64, g = 0.19, b = 0.79 },
    { name = "Evoker",       r = 0.20, g = 0.58, b = 0.50 },
}

-- ============================================================
-- Persistent State
-- ============================================================
local savedColors   = {}
local recentColors  = {}
local savedPosition = nil

local MAX_RECENT      = 24
local MAX_SAVED       = 24
local SWATCH_SIZE     = 28
local SWATCH_GAP      = 3
local SWATCHES_PER_ROW = 12

local function GetDB()
    local db = ns.GetDB and ns.GetDB()
    return db
end

local function LoadDB()
    local db = GetDB()
    if db and db.colorPicker then
        savedColors  = db.colorPicker.savedColors  or {}
        recentColors = db.colorPicker.recentColors or {}
    end
end

local function SaveDB()
    local db = GetDB()
    if not db then return end
    if not db.colorPicker then db.colorPicker = {} end
    db.colorPicker.savedColors  = savedColors
    db.colorPicker.recentColors = recentColors
end

-- ============================================================
-- Color Math
-- ============================================================
local function HSVtoRGB(h, s, v)
    if s == 0 then return v, v, v end
    h = h / 60
    local i = math.floor(h)
    local f = h - i
    local p = v * (1 - s)
    local q = v * (1 - s * f)
    local t = v * (1 - s * (1 - f))
    i = i % 6
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else               return v, p, q end
end

local function RGBtoHSV(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, v = 0, 0, max
    local d = max - min
    if max ~= 0 then s = d / max end
    if max ~= min then
        if     max == r then h = (g - b) / d; if g < b then h = h + 6 end
        elseif max == g then h = (b - r) / d + 2
        else                 h = (r - g) / d + 4 end
        h = h * 60
    end
    return h, s, v
end

local function RGBtoHex(r, g, b, a)
    local ri = math.floor(r * 255 + 0.5)
    local gi = math.floor(g * 255 + 0.5)
    local bi = math.floor(b * 255 + 0.5)
    if a and a < 0.999 then
        return string.format("#%02X%02X%02X%02X", ri, gi, bi, math.floor(a * 255 + 0.5))
    end
    return string.format("#%02X%02X%02X", ri, gi, bi)
end

local function HexToRGB(hex)
    hex = hex:gsub("#", "")
    if #hex == 8 then
        return (tonumber(hex:sub(1,2), 16) or 255)/255,
               (tonumber(hex:sub(3,4), 16) or 255)/255,
               (tonumber(hex:sub(5,6), 16) or 255)/255,
               (tonumber(hex:sub(7,8), 16) or 255)/255
    elseif #hex == 6 then
        return (tonumber(hex:sub(1,2), 16) or 255)/255,
               (tonumber(hex:sub(3,4), 16) or 255)/255,
               (tonumber(hex:sub(5,6), 16) or 255)/255, nil
    end
    return 1, 1, 1, nil
end

local function ColorKey(r, g, b, a)
    return string.format("%.3f,%.3f,%.3f,%.3f", r, g, b, a or 1)
end

-- ============================================================
-- Helpers
-- ============================================================
local function SetFont(fs, size, flags)
    fs:SetFont(FONT_PATH, size or 12, flags or "")
end

local function Backdrop(bgFile, edgeFile, edgeSize)
    return {
        bgFile   = bgFile   or "Interface\\Buttons\\WHITE8x8",
        edgeFile = edgeFile or "Interface\\Buttons\\WHITE8x8",
        edgeSize = edgeSize or 1,
    }
end

-- ============================================================
-- Picker Frame (Singleton)
-- ============================================================
local pickerFrame = nil

local function CreatePickerFrame()
    if pickerFrame then return end

    local SQ_SIZE  = 160   -- HSV square
    local HUE_W    = 18    -- hue bar width
    local ALPHA_W  = 18    -- alpha bar width

    -- Color state (upvalues shared across all inner functions)
    local curH, curS, curV = 210, 1, 0.6
    local curA = 1
    local isUpdatingInputs = false
    -- Forward-declared so closures in savedPanel/rightPanel reference these correctly
    -- even though they are assigned later in CreatePickerFrame.
    local SelectColor, RefreshSaved

    do
        local db = GetDB()
        if db and db.colorPicker then
            -- Logic simplified to remove circle/square toggle
        end
    end

    -- ──────────────────────────────────────────────────────────
    -- MAIN FRAME
    -- ──────────────────────────────────────────────────────────
    pickerFrame = CreateFrame("Frame", "GravityUIColorPicker", UIParent, "BackdropTemplate")
    pickerFrame:SetSize(420, 500)
    pickerFrame:SetBackdrop(Backdrop())
    pickerFrame:SetBackdropColor(C_BG[1], C_BG[2], C_BG[3], 0.88)
    pickerFrame:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0.45)
    pickerFrame:SetMovable(true)
    pickerFrame:EnableMouse(true)
    pickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    pickerFrame:SetFrameLevel(500)
    pickerFrame:SetToplevel(true)
    pickerFrame:Hide()
    tinsert(UISpecialFrames, "GravityUIColorPicker")

    pickerFrame.appliedColor = false
    pickerFrame:SetScript("OnHide", function(self)
        if not self.appliedColor then
            if self.onCancelCallback then self.onCancelCallback() end
        end
        self.appliedColor = false
        self.skipOnChange = false
        self:ClearCallbacks()
    end)

    local function DoRestorePosition()
        pickerFrame:ClearAllPoints()
        if savedPosition then
            pickerFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", savedPosition.x, savedPosition.y)
        else
            pickerFrame:SetPoint("CENTER")
        end
    end
    local function DoSavePosition()
        local l, b = pickerFrame:GetLeft(), pickerFrame:GetBottom()
        local w, h = pickerFrame:GetWidth(), pickerFrame:GetHeight()
        if l and b and w and h then
            savedPosition = { x = l + w / 2, y = b + h / 2 }
        end
    end

    -- ──────────────────────────────────────────────────────────
    -- HEADER
    -- ──────────────────────────────────────────────────────────
    local header = CreateFrame("Frame", nil, pickerFrame)
    header:SetHeight(30)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() pickerFrame:StartMoving() end)
    header:SetScript("OnDragStop", function() pickerFrame:StopMovingOrSizing(); DoSavePosition() end)

    local headerAccent = pickerFrame:CreateTexture(nil, "ARTWORK")
    headerAccent:SetHeight(1)
    headerAccent:SetPoint("TOPLEFT",  header, "BOTTOMLEFT",  0, 0)
    headerAccent:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerAccent:SetGradient("HORIZONTAL",
        CreateColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0.6),
        CreateColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0))

    local titleFS = header:CreateFontString(nil, "OVERLAY")
    SetFont(titleFS, 12, "")
    titleFS:SetPoint("LEFT", 10, 0)
    titleFS:SetText("|cff00aaff●|r  GravityUI Color Picker")
    titleFS:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -8, 0)
    local closeFS = closeBtn:CreateFontString(nil, "OVERLAY")
    SetFont(closeFS, 16, "")
    closeFS:SetPoint("CENTER", 0, 1)
    closeFS:SetText("×")
    closeFS:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])
    closeBtn:SetScript("OnClick",  function() pickerFrame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeFS:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeFS:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3]) end)

    -- ──────────────────────────────────────────────────────────
    -- CONTENT AREA
    -- ──────────────────────────────────────────────────────────
    local content = CreateFrame("Frame", nil, pickerFrame)
    content:SetPoint("TOPLEFT",  0, -32)
    content:SetPoint("BOTTOMRIGHT", 0, 44)

    -- ──────────────────────────────────────────────────────────
    -- SQUARE PICKER
    -- ──────────────────────────────────────────────────────────
    -- SQUARE PICKER CONTAINER
    -- ──────────────────────────────────────────────────────────
    local sqCont = CreateFrame("Frame", nil, content)
    sqCont:SetSize(SQ_SIZE + HUE_W + ALPHA_W + 20, SQ_SIZE)
    sqCont:SetPoint("TOPLEFT", 10, -10)

    -- SV Square — hueLayer (BACKGROUND) tinted via UpdateHueGradient
    -- blackGrad (ARTWORK) fades bottom to black
    local sqFrame = CreateFrame("Frame", nil, sqCont, "BackdropTemplate")
    sqFrame:SetSize(SQ_SIZE, SQ_SIZE)
    sqFrame:SetPoint("TOPLEFT", 0, 0)
    sqFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    sqFrame:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)

    -- White→Hue horizontal gradient (updated dynamically with hue)
    local hueLayer = sqFrame:CreateTexture(nil, "BACKGROUND")
    hueLayer:SetAllPoints()
    hueLayer:SetColorTexture(1, 1, 1, 1)

    -- Black vertical fade (value axis)
    local blackGrad = sqFrame:CreateTexture(nil, "ARTWORK")
    blackGrad:SetAllPoints()
    blackGrad:SetColorTexture(1, 1, 1, 1)
    blackGrad:SetGradient("VERTICAL", CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 0))

    local sqThumb = sqFrame:CreateTexture(nil, "OVERLAY")
    sqThumb:SetSize(14, 14)
    sqThumb:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
    sqThumb:SetTexCoord(0, 0.15625, 0, 0.625)

    -- ── Hue Bar (BACKGROUND segments — proven pattern like reference addon) ──
    -- Uses edgeFile-only backdrop (no bgFile) so BACKGROUND textures show through
    local hueBar = CreateFrame("Frame", nil, sqCont, "BackdropTemplate")
    hueBar:SetSize(HUE_W, SQ_SIZE)
    hueBar:SetPoint("LEFT", sqFrame, "RIGHT", 6, 0)
    hueBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    hueBar:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)

    local HUE_COLORS = {{1,0,0},{1,1,0},{0,1,0},{0,1,1},{0,0,1},{1,0,1},{1,0,0}}
    local segH = SQ_SIZE / 6
    for i = 1, 6 do
        local seg = hueBar:CreateTexture(nil, "BACKGROUND")
        seg:SetSize(HUE_W, segH)
        seg:SetPoint("TOPLEFT", 0, -((i-1) * segH))
        seg:SetColorTexture(1, 1, 1, 1)
        local c1, c2 = HUE_COLORS[i], HUE_COLORS[i+1]
        seg:SetGradient("VERTICAL", CreateColor(c2[1],c2[2],c2[3],1), CreateColor(c1[1],c1[2],c1[3],1))
    end
    local hueTH  = hueBar:CreateTexture(nil, "OVERLAY", nil, 2)
    hueTH:SetSize(HUE_W+6, 5); hueTH:SetColorTexture(1,1,1,1)
    local hueTHB = hueBar:CreateTexture(nil, "OVERLAY", nil, 1)
    hueTHB:SetSize(HUE_W+8, 7); hueTHB:SetColorTexture(0,0,0,1)

    -- ── Alpha Bar ──
    local alphaBar = CreateFrame("Frame", nil, sqCont, "BackdropTemplate")
    alphaBar:SetSize(ALPHA_W, SQ_SIZE)
    alphaBar:SetPoint("LEFT", hueBar, "RIGHT", 6, 0)
    alphaBar:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    alphaBar:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)

    local ckW, ckH, ckSz = ALPHA_W - 2, SQ_SIZE - 2, 8
    for row = 0, math.ceil(ckH/ckSz)-1 do
        for col = 0, math.ceil(ckW/ckSz)-1 do
            local ck = alphaBar:CreateTexture(nil, "BACKGROUND")
            ck:SetSize(math.min(ckSz, ckW-col*ckSz), math.min(ckSz, ckH-row*ckSz))
            ck:SetPoint("TOPLEFT", 1+col*ckSz, -1-row*ckSz)
            local light = (row+col)%2==0
            ck:SetColorTexture(light and 0.4 or 0.2, light and 0.4 or 0.2, light and 0.4 or 0.2, 1)
        end
    end
    local alphaGrad = alphaBar:CreateTexture(nil, "ARTWORK")
    alphaGrad:SetPoint("TOPLEFT", 1, -1); alphaGrad:SetPoint("BOTTOMRIGHT", -1, 1)
    alphaGrad:SetColorTexture(1,1,1,1)
    local alphaTH  = alphaBar:CreateTexture(nil, "OVERLAY", nil, 2)
    alphaTH:SetSize(ALPHA_W+6, 5); alphaTH:SetColorTexture(1,1,1,1)
    local alphaTHB = alphaBar:CreateTexture(nil, "OVERLAY", nil, 1)
    alphaTHB:SetSize(ALPHA_W+8, 7); alphaTHB:SetColorTexture(0,0,0,1)

    -- ──────────────────────────────────────────────────────────
    -- SAVED PANEL (2-col grid, anchored right of alpha bar)
    -- RIGHT PANEL (New/Prev swatches + Save / Clear buttons, far right)
    -- ──────────────────────────────────────────────────────────
    local RP_W    = 82   -- right panel width (New / Prev / Save / Clear)
    local SP_W    = 90   -- saved panel width
    local SP_SW   = 32   -- saved swatch size
    local SP_GAP  = 4
    local SP_COLS = 2
    local SP_PAD_X = math.floor((SP_W - SP_COLS * SP_SW - (SP_COLS - 1) * SP_GAP) / 2)  -- 11px

    -- ── Saved Panel ──
    local savedPanel = CreateFrame("Frame", nil, content)
    savedPanel:SetSize(SP_W, SQ_SIZE)
    savedPanel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -(10 + RP_W + 4), -10)

    local spLbl = savedPanel:CreateFontString(nil, "OVERLAY")
    SetFont(spLbl, 9, ""); spLbl:SetPoint("TOPLEFT", SP_PAD_X, 0)
    spLbl:SetText("Saved"); spLbl:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])

    local savedSwatches = {}
    local savedEmptyFS  = savedPanel:CreateFontString(nil, "OVERLAY")
    SetFont(savedEmptyFS, 8, ""); savedEmptyFS:SetPoint("CENTER", 0, -20)
    savedEmptyFS:SetText("No saved\ncolors yet")
    savedEmptyFS:SetTextColor(C_MUTED[1]*0.7, C_MUTED[2]*0.7, C_MUTED[3]*0.7)
    savedEmptyFS:SetJustifyH("CENTER")

    -- ── Right Panel ──
    local RP_SW_H = 30  -- swatch height inside right panel

    local rightPanel = CreateFrame("Frame", nil, content)
    rightPanel:SetSize(RP_W, SQ_SIZE)
    rightPanel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -10)

    local function MakeRPSwatch(labelTxt, yTop)
        local lbl = rightPanel:CreateFontString(nil, "OVERLAY")
        SetFont(lbl, 9, ""); lbl:SetPoint("TOPLEFT", 0, -yTop)
        lbl:SetText(labelTxt); lbl:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])

        local box = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
        box:SetSize(RP_W, RP_SW_H)
        box:SetPoint("TOPLEFT", 0, -(yTop + 12))
        box:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        box:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)

        local inW, inH = RP_W - 2, RP_SW_H - 2
        for r = 0, math.ceil(inH / 8) - 1 do
            for c = 0, math.ceil(inW / 8) - 1 do
                local ck = box:CreateTexture(nil, "BACKGROUND")
                ck:SetSize(math.min(8, inW - c*8), math.min(8, inH - r*8))
                ck:SetPoint("TOPLEFT", 1 + c*8, -1 - r*8)
                local lt = (r + c) % 2 == 0
                ck:SetColorTexture(lt and 0.35 or 0.18, lt and 0.35 or 0.18, lt and 0.35 or 0.18, 1)
            end
        end
        local tex = box:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT",     box, "TOPLEFT",     1, -1)
        tex:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1,  1)
        return tex, box
    end

    local RP_NEW_Y  = 0
    local RP_PREV_Y = RP_NEW_Y + 12 + RP_SW_H + 4
    local newTex,  newBox  = MakeRPSwatch("New",  RP_NEW_Y)
    local prevTex, prevBox = MakeRPSwatch("Prev", RP_PREV_Y)

    local RP_SAVE_Y  = RP_PREV_Y + 12 + RP_SW_H + 6
    local RP_CLEAR_Y = RP_SAVE_Y + 24 + 3

    local saveSwatchBtn = CreateFrame("Button", nil, rightPanel, "BackdropTemplate")
    saveSwatchBtn:SetSize(RP_W, 24); saveSwatchBtn:SetPoint("TOPLEFT", 0, -RP_SAVE_Y)
    saveSwatchBtn:SetBackdrop(Backdrop())
    saveSwatchBtn:SetBackdropColor(C_ELEM[1], C_ELEM[2], C_ELEM[3], 1)
    saveSwatchBtn:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0.6)
    local saveSwatchFS = saveSwatchBtn:CreateFontString(nil, "OVERLAY")
    SetFont(saveSwatchFS, 10, ""); saveSwatchFS:SetPoint("CENTER")
    saveSwatchFS:SetText("+ Save"); saveSwatchFS:SetTextColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3])
    saveSwatchBtn:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(C_ACCENT[1],C_ACCENT[2],C_ACCENT[3],1) end)
    saveSwatchBtn:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(C_ACCENT[1],C_ACCENT[2],C_ACCENT[3],0.6) end)
    -- OnClick set later after RefreshSaved is assigned

    local clearSavedBtn = CreateFrame("Button", nil, rightPanel, "BackdropTemplate")
    clearSavedBtn:SetSize(RP_W, 24); clearSavedBtn:SetPoint("TOPLEFT", 0, -RP_CLEAR_Y)
    clearSavedBtn:SetBackdrop(Backdrop())
    clearSavedBtn:SetBackdropColor(C_ELEM[1], C_ELEM[2], C_ELEM[3], 1)
    clearSavedBtn:SetBackdropBorderColor(0.5, 0.18, 0.18, 1)
    local clearSavedFS = clearSavedBtn:CreateFontString(nil, "OVERLAY")
    SetFont(clearSavedFS, 10, ""); clearSavedFS:SetPoint("CENTER")
    clearSavedFS:SetText("Clear Saved"); clearSavedFS:SetTextColor(0.8, 0.35, 0.35)
    clearSavedBtn:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(0.8,0.3,0.3,1) end)
    clearSavedBtn:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(0.5,0.18,0.18,1) end)
    -- OnClick set later after RefreshSaved is assigned


    -- ──────────────────────────────────────────────────────────
    -- RGBA / HEX INPUTS
    -- ──────────────────────────────────────────────────────────
    local INPUT_Y = SQ_SIZE + 10 + 8  -- from content top

    local function CreateNumInput(parent, lbl, lblColor, xLeft, w)
        local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        frame:SetSize(w, 22)
        frame:SetPoint("TOPLEFT", xLeft, -INPUT_Y)
        frame:SetBackdrop(Backdrop())
        frame:SetBackdropColor(C_ELEM[1], C_ELEM[2], C_ELEM[3], 1)
        frame:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)

        local lt = frame:CreateFontString(nil, "OVERLAY")
        SetFont(lt, 10, ""); lt:SetPoint("LEFT", 5, 0)
        lt:SetText(lbl); lt:SetTextColor(lblColor[1], lblColor[2], lblColor[3])

        local eb = CreateFrame("EditBox", nil, frame)
        eb:SetSize(w - 22, 18); eb:SetPoint("LEFT", lt, "RIGHT", 2, 0)
        eb:SetFont(FONT_PATH, 10, "")
        eb:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
        eb:SetAutoFocus(false); eb:SetNumeric(true); eb:SetMaxLetters(3)
        eb:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        eb:SetScript("OnEditFocusGained",  function() frame:SetBackdropBorderColor(C_ACCENT[1],C_ACCENT[2],C_ACCENT[3],0.8) end)
        eb:SetScript("OnEditFocusLost",    function() frame:SetBackdropBorderColor(C_BORDER[1],C_BORDER[2],C_BORDER[3],1) end)
        return eb, frame
    end

    local rInput, _ = CreateNumInput(content, "R", {1, 0.4, 0.4},    10,  58)
    local gInput, _ = CreateNumInput(content, "G", {0.4, 0.9, 0.4},  72,  58)
    local bInput, _ = CreateNumInput(content, "B", {0.4, 0.6, 1  },  134, 58)
    local aInput, aFrame = CreateNumInput(content, "A%",{0.7, 0.7, 0.7}, 196, 60)

    local HEX_Y = INPUT_Y + 26
    local hexFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    hexFrame:SetSize(148, 22)
    hexFrame:SetPoint("TOPLEFT", 10, -HEX_Y)
    hexFrame:SetBackdrop(Backdrop())
    hexFrame:SetBackdropColor(C_ELEM[1], C_ELEM[2], C_ELEM[3], 1)
    hexFrame:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)

    local hexLbl = hexFrame:CreateFontString(nil, "OVERLAY")
    SetFont(hexLbl, 10, ""); hexLbl:SetPoint("LEFT", 6, 0)
    hexLbl:SetText("Hex"); hexLbl:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])

    local hexInput = CreateFrame("EditBox", nil, hexFrame)
    hexInput:SetSize(102, 18); hexInput:SetPoint("LEFT", hexLbl, "RIGHT", 4, 0)
    hexInput:SetFont(FONT_PATH, 10, "")
    hexInput:SetTextColor(C_TEXT[1], C_TEXT[2], C_TEXT[3])
    hexInput:SetAutoFocus(false); hexInput:SetMaxLetters(9)
    hexInput:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    hexInput:SetScript("OnEditFocusGained",  function() hexFrame:SetBackdropBorderColor(C_ACCENT[1],C_ACCENT[2],C_ACCENT[3],0.8) end)
    hexInput:SetScript("OnEditFocusLost",    function() hexFrame:SetBackdropBorderColor(C_BORDER[1],C_BORDER[2],C_BORDER[3],1) end)

    -- Copy button: click to focus + select hex text (Ctrl+C to copy)
    -- Uses a small icon-like label; the ⎘ glyph may not render in all fonts,
    -- so we use an inline Blizzard texture atlas icon instead.
    local copyBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    copyBtn:SetSize(30, 22)
    copyBtn:SetPoint("LEFT", hexFrame, "RIGHT", 5, 0)
    copyBtn:SetBackdrop(Backdrop())
    copyBtn:SetBackdropColor(C_ELEM[1], C_ELEM[2], C_ELEM[3], 1)
    copyBtn:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)
    -- Use a Blizzard UI texture for the copy icon (edit/pencil from common atlas)
    local copyIcon = copyBtn:CreateTexture(nil, "OVERLAY")
    copyIcon:SetSize(16, 16)
    copyIcon:SetPoint("CENTER", 0, 0)
    copyIcon:SetAtlas("chatframe-button-icon-copy")
    if not copyIcon:GetAtlas() then
        -- Fallback: plain text
        copyIcon:Hide()
        local fallbackFS = copyBtn:CreateFontString(nil, "OVERLAY")
        SetFont(fallbackFS, 10, ""); fallbackFS:SetPoint("CENTER", 0, 0)
        fallbackFS:SetText("C"); fallbackFS:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])
    end
    copyBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
        copyIcon:SetVertexColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3])
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Copy hex color", 1, 1, 1)
        GameTooltip:AddLine("Click to select, then |cff00aaff Ctrl+C|r to copy", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    copyBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C_BORDER[1], C_BORDER[2], C_BORDER[3], 1)
        copyIcon:SetVertexColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])
        GameTooltip:Hide()
    end)
    copyBtn:SetScript("OnClick", function()
        hexInput:SetFocus()
        hexInput:HighlightText()
    end)

    -- ──────────────────────────────────────────────────────────
    -- UPDATE FUNCTIONS
    -- ──────────────────────────────────────────────────────────
    local function UpdateHueGradient()
        local r, g, b = HSVtoRGB(curH, 1, 1)
        hueLayer:SetGradient("HORIZONTAL", CreateColor(1,1,1,1), CreateColor(r,g,b,1))
    end

    local function UpdateAlphaGradient()
        local r, g, b = HSVtoRGB(curH, curS, curV)
        alphaGrad:SetGradient("VERTICAL", CreateColor(r,g,b,0), CreateColor(r,g,b,1))
    end

    local function UpdateSqThumb()
        sqThumb:ClearAllPoints()
        sqThumb:SetPoint("CENTER", sqFrame, "BOTTOMLEFT", curS * SQ_SIZE, curV * SQ_SIZE)
    end

    local function UpdateHueThumb()
        local y = (curH / 360) * SQ_SIZE
        hueTH:ClearAllPoints();  hueTH:SetPoint("CENTER",  hueBar, "TOP", 0, -y)
        hueTHB:ClearAllPoints(); hueTHB:SetPoint("CENTER", hueTH)
    end

    local function UpdateAlphaThumb()
        local y = (1 - curA) * SQ_SIZE
        alphaTH:ClearAllPoints();  alphaTH:SetPoint("CENTER",  alphaBar, "TOP", 0, -y)
        alphaTHB:ClearAllPoints(); alphaTHB:SetPoint("CENTER", alphaTH)
    end



    local function UpdateInputs()
        if isUpdatingInputs then return end
        isUpdatingInputs = true
        local r, g, b = HSVtoRGB(curH, curS, curV)
        rInput:SetText(math.floor(r * 255 + 0.5))
        gInput:SetText(math.floor(g * 255 + 0.5))
        bInput:SetText(math.floor(b * 255 + 0.5))
        aInput:SetText(math.floor(curA * 100 + 0.5))
        if pickerFrame.hasAlpha then
            hexInput:SetText(RGBtoHex(r, g, b, curA))
        else
            hexInput:SetText(RGBtoHex(r, g, b))
        end
        isUpdatingInputs = false
    end

    local function GetCurrentRGB()
        return HSVtoRGB(curH, curS, curV)
    end

    local function UpdateAll()
        local r, g, b = GetCurrentRGB()
        newTex:SetColorTexture(r, g, b, curA)  -- "New" swatch tracks live color
        UpdateHueGradient()
        UpdateAlphaGradient()
        UpdateSqThumb()
        UpdateHueThumb()
        UpdateAlphaThumb()
        UpdateInputs()
        if pickerFrame.onChangeCallback and not pickerFrame.skipOnChange then
            pickerFrame.onChangeCallback({
                r = r, g = g, b = b,
                a = pickerFrame.hasAlpha and curA or 1
            })
        end
    end

    -- ──────────────────────────────────────────────────────────
    -- INPUT HANDLERS
    -- ──────────────────────────────────────────────────────────
    local function OnRGBAChanged()
        if isUpdatingInputs then return end
        local r = math.max(0,math.min(1, (tonumber(rInput:GetText()) or 0)/255))
        local g = math.max(0,math.min(1, (tonumber(gInput:GetText()) or 0)/255))
        local b = math.max(0,math.min(1, (tonumber(bInput:GetText()) or 0)/255))
        local a = math.max(0,math.min(1, (tonumber(aInput:GetText()) or 100)/100))
        curH, curS, curV = RGBtoHSV(r, g, b)
        curA = a
        UpdateAll()
    end
    for _, eb in ipairs({rInput, gInput, bInput, aInput}) do
        eb:SetScript("OnEnterPressed", function(s) OnRGBAChanged(); s:ClearFocus() end)
        eb:SetScript("OnTextChanged",  function(s, u) if u then OnRGBAChanged() end end)
    end

    -- Helper: normalise hex to #RRGGBB or #RRGGBBAA
    local function NormalizeHex(txt)
        txt = txt:gsub("^#*", ""):upper()  -- strip leading #
        if #txt == 6 or #txt == 8 then
            return "#" .. txt
        end
        return nil
    end

    hexInput:SetScript("OnEnterPressed", function(self)
        if isUpdatingInputs then return end
        local norm = NormalizeHex(self:GetText())
        if norm then
            local r, g, b, a = HexToRGB(norm)
            curH, curS, curV = RGBtoHSV(r, g, b)
            if a and pickerFrame.hasAlpha then curA = a end
            UpdateAll()
        end
        self:ClearFocus()
    end)
    hexInput:SetScript("OnTextChanged", function(self, u)
        if not u or isUpdatingInputs then return end
        local norm = NormalizeHex(self:GetText())
        if norm then
            local r, g, b, a = HexToRGB(norm)
            if r then
                curH, curS, curV = RGBtoHSV(r, g, b)
                if a and pickerFrame.hasAlpha then curA = a end
                UpdateAll()
            end
        end
    end)
    -- Ctrl+C: select all and allow system copy when focused
    hexInput:SetScript("OnKeyDown", function(self, key)
        if IsControlKeyDown() and key == "C" then
            self:SetFocus()
            self:HighlightText()
        end
    end)

    -- ──────────────────────────────────────────────────────────
    -- MOUSE DRAG HANDLERS
    -- ──────────────────────────────────────────────────────────
    local dragSq, dragHue, dragAlpha = false, false, false

    sqFrame:EnableMouse(true)
    sqFrame:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        dragSq = true
        local sc = self:GetEffectiveScale()
        local cx, cy = GetCursorPosition(); cx, cy = cx/sc, cy/sc
        curS = math.max(0, math.min(1, (cx - self:GetLeft()) / SQ_SIZE))
        curV = math.max(0, math.min(1, (cy - self:GetBottom()) / SQ_SIZE))
        UpdateAll()
    end)
    sqFrame:SetScript("OnMouseUp",   function() dragSq = false end)
    sqFrame:SetScript("OnUpdate",    function(self)
        if not dragSq then return end
        local sc = self:GetEffectiveScale()
        local cx, cy = GetCursorPosition(); cx, cy = cx/sc, cy/sc
        curS = math.max(0, math.min(1, (cx - self:GetLeft()) / SQ_SIZE))
        curV = math.max(0, math.min(1, (cy - self:GetBottom()) / SQ_SIZE))
        UpdateAll()
    end)

    hueBar:EnableMouse(true)
    hueBar:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        dragHue = true
        local sc = self:GetEffectiveScale()
        local _, cy = GetCursorPosition(); cy = cy/sc
        curH = math.max(0, math.min(360, ((self:GetTop() - cy) / SQ_SIZE) * 360))
        UpdateAll()
    end)
    hueBar:SetScript("OnMouseUp",  function() dragHue = false end)
    hueBar:SetScript("OnUpdate",   function(self)
        if not dragHue then return end
        local sc = self:GetEffectiveScale()
        local _, cy = GetCursorPosition(); cy = cy/sc
        curH = math.max(0, math.min(360, ((self:GetTop() - cy) / SQ_SIZE) * 360))
        UpdateAll()
    end)

    local function SetupAlphaDrag(bar, isCircle)
        bar:EnableMouse(true)
        bar:SetScript("OnMouseDown", function(self, btn)
            if btn ~= "LeftButton" then return end
            if isCircle then dragCiAlpha = true else dragAlpha = true end
            local sc = self:GetEffectiveScale()
            local _, cy = GetCursorPosition(); cy = cy/sc
            curA = math.max(0, math.min(1, 1 - ((self:GetTop() - cy) / SQ_SIZE)))
            UpdateAll()
        end)
        bar:SetScript("OnMouseUp",  function() dragAlpha = false; dragCiAlpha = false end)
        bar:SetScript("OnUpdate",   function(self)
            local dragging = isCircle and dragCiAlpha or dragAlpha
            if not dragging then return end
            local sc = self:GetEffectiveScale()
            local _, cy = GetCursorPosition(); cy = cy/sc
            curA = math.max(0, math.min(1, 1 - ((self:GetTop() - cy) / SQ_SIZE)))
            UpdateAll()
        end)
    end
    SetupAlphaDrag(alphaBar,  false)




    function pickerFrame:UpdateAlphaVis()
        local show = self.hasAlpha
        alphaBar:SetShown(show); aFrame:SetShown(show)
    end

    -- ──────────────────────────────────────────────────────────
    -- PALETTE  (Theme + Classes + Recent inline; Saved as toggle)
    -- ──────────────────────────────────────────────────────────
    -- No toggle bar anymore; palette starts right after hex input row
    local PAL_Y = INPUT_Y + 26 + 22 + 8   -- from content top

    -- Swatch helper
    local function MakeSwatch(parent, col, row, r, g, b, a, tip, onLeft, onRight)
        local sw = CreateFrame("Button", nil, parent, "BackdropTemplate")
        sw:SetSize(SWATCH_SIZE, SWATCH_SIZE)
        sw:SetPoint("TOPLEFT", col*(SWATCH_SIZE+SWATCH_GAP), -(row*(SWATCH_SIZE+SWATCH_GAP)))
        sw:SetBackdrop(Backdrop()); sw:SetBackdropColor(r, g, b, a or 1)
        sw:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
        sw:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C_ACCENT[1],C_ACCENT[2],C_ACCENT[3],1)
            if tip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tip, C_TEXT[1], C_TEXT[2], C_TEXT[3])
                GameTooltip:AddLine(RGBtoHex(r, g, b, a), 0.6, 0.6, 0.6)
                if onRight then GameTooltip:AddLine("Right-click: save / delete", 0.5,0.5,0.5) end
                GameTooltip:Show()
            end
        end)
        sw:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.18,0.18,0.18,1); GameTooltip:Hide()
        end)
        if onLeft or onRight then
            sw:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            sw:SetScript("OnClick", function(self, btn)
                if btn == "LeftButton" and onLeft then onLeft()
                elseif btn == "RightButton" and onRight then onRight() end
            end)
        end
        return sw
    end

    SelectColor = function(r, g, b, a)
        curH, curS, curV = RGBtoHSV(r, g, b)
        if a and pickerFrame.hasAlpha then curA = a end
        UpdateAll()
    end

    -- Section label helper
    local function MakeSectionLabel(parent, text, yOffset)
        local lbl = parent:CreateFontString(nil, "OVERLAY")
        SetFont(lbl, 9, "")
        lbl:SetPoint("TOPLEFT", 0, -yOffset)
        lbl:SetText(text)
        lbl:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])
        local line = parent:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        line:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        line:SetPoint("TOPLEFT", lbl, "RIGHT", 4, -1)
        line:SetColorTexture(C_BORDER[1], C_BORDER[2], C_BORDER[3], 0.6)
        return lbl
    end

    -- ──────────────────────────────────────────────────────────
    -- PALETTE  (Theme + Classes + Recent, always visible below inputs)
    -- ──────────────────────────────────────────────────────────
    local palCont = CreateFrame("Frame", nil, content)
    palCont:SetPoint("TOPLEFT", 10, -(PAL_Y))
    palCont:SetPoint("RIGHT",  content, "RIGHT", -10, 0)

    local ROW_H = SWATCH_SIZE + SWATCH_GAP   -- 31
    local LBL_H = 13

    -- ── SECTION 1: Theme ──
    local THEME_Y = 0
    MakeSectionLabel(palCont, "Theme", THEME_Y)
    local themeSwatchFrames = {}
    local function BuildThemeSection()
        for _, sw in ipairs(themeSwatchFrames) do sw:Hide(); sw:SetParent(nil) end
        wipe(themeSwatchFrames)
        local presets = {}
        local db = GetDB()
        if db and db.general then
            local tc2 = db.general.themeColor
            if tc2 then table.insert(presets, { label="Theme Color",     r=tc2[1] or 0, g=tc2[2] or 0.6, b=tc2[3] or 1, a=tc2[4] or 1 }) end
            local bgc = db.general.themeBgColor
            if bgc then table.insert(presets, { label="Theme Background", r=bgc[1] or 0.1, g=bgc[2] or 0.1, b=bgc[3] or 0.1, a=bgc[4] or 1 }) end
        end
        table.insert(presets, { label="Gravity Blue",  r=0,    g=0.6,  b=1,    a=1 })
        table.insert(presets, { label="White",         r=1,    g=1,    b=1,    a=1 })
        table.insert(presets, { label="Black",         r=0,    g=0,    b=0,    a=1 })
        table.insert(presets, { label="Gold",          r=0.96, g=0.62, b=0.04, a=1 })
        table.insert(presets, { label="Red",           r=0.8,  g=0.2,  b=0.2,  a=1 })
        table.insert(presets, { label="Green",         r=0.2,  g=0.8,  b=0.2,  a=1 })
        table.insert(presets, { label="Transparent",   r=1,    g=1,    b=1,    a=0 })
        for i, p in ipairs(presets) do
            local r, g, b, a = p.r, p.g, p.b, p.a
            local col = (i-1) % SWATCHES_PER_ROW
            local row = math.floor((i-1) / SWATCHES_PER_ROW)
            local sw = MakeSwatch(palCont, col, 0, r, g, b, a, p.label,
                function() SelectColor(r, g, b, a) end, nil)
            sw:SetPoint("TOPLEFT", col*(SWATCH_SIZE+SWATCH_GAP), -(THEME_Y + LBL_H + row*ROW_H))
            table.insert(themeSwatchFrames, sw)
        end
    end

    -- ── SECTION 2: Classes ──
    local CLASS_Y = THEME_Y + LBL_H + ROW_H + 6
    MakeSectionLabel(palCont, "Classes", CLASS_Y)
    for i, cls in ipairs(CLASS_COLORS) do
        local r, g, b = cls.r, cls.g, cls.b
        local col = (i-1) % SWATCHES_PER_ROW
        local row = math.floor((i-1) / SWATCHES_PER_ROW)
        local sw = MakeSwatch(palCont, col, 0, r, g, b, 1, cls.name,
            function() SelectColor(r, g, b, 1) end, nil)
        sw:SetPoint("TOPLEFT", col*(SWATCH_SIZE+SWATCH_GAP), -(CLASS_Y + LBL_H + row*ROW_H))
    end
    local CLASS_ROWS = math.ceil(#CLASS_COLORS / SWATCHES_PER_ROW)

    -- ── SECTION 3: Recent ──
    local RECENT_Y = CLASS_Y + LBL_H + CLASS_ROWS * ROW_H + 6
    MakeSectionLabel(palCont, "Recent", RECENT_Y)
    local recentSwatches = {}

    local recentEmptyFS = palCont:CreateFontString(nil, "OVERLAY")
    SetFont(recentEmptyFS, 9, ""); recentEmptyFS:SetPoint("TOPLEFT", 0, -(RECENT_Y + LBL_H))
    recentEmptyFS:SetText("Colors appear here after confirming")
    recentEmptyFS:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])

    local function RefreshRecent()
        for _, sw in ipairs(recentSwatches) do sw:Hide(); sw:SetParent(nil) end
        wipe(recentSwatches)
        recentEmptyFS:SetShown(#recentColors == 0)
        for i, c in ipairs(recentColors) do
            local r, g, b, a = c.r, c.g, c.b, c.a or 1
            local col = (i-1) % SWATCHES_PER_ROW
            local sw = MakeSwatch(palCont, col, 0, r, g, b, a, RGBtoHex(r,g,b,a),
                function() SelectColor(r, g, b, a) end,
                function()
                    local key = ColorKey(r,g,b,a)
                    local exists = false
                    for _, s in ipairs(savedColors) do
                        if ColorKey(s.r,s.g,s.b,s.a or 1) == key then exists=true; break end
                    end
                    if not exists and #savedColors < MAX_SAVED then
                        table.insert(savedColors, 1, {r=r,g=g,b=b,a=a}); SaveDB()
                        RefreshSaved()
                    end
                end)
            sw:SetPoint("TOPLEFT", col*(SWATCH_SIZE+SWATCH_GAP), -(RECENT_Y + LBL_H))
            table.insert(recentSwatches, sw)
        end
    end

    local PAL_TOTAL = RECENT_Y + LBL_H + ROW_H + 4
    palCont:SetHeight(PAL_TOTAL)

    -- ── Assign RefreshSaved (savedPanel + savedSwatches created in the top section) ──
    RefreshSaved = function()
        for _, sw in ipairs(savedSwatches) do sw:Hide(); sw:SetParent(nil) end
        wipe(savedSwatches)
        savedEmptyFS:SetShown(#savedColors == 0)
        local maxVisible = SP_COLS * math.floor((SQ_SIZE - 13) / (SP_SW + SP_GAP))
        for i = 1, math.min(#savedColors, maxVisible) do
            local c = savedColors[i]
            local r, g, b, a = c.r, c.g, c.b, c.a or 1
            local ci = i
            local col = (i-1) % SP_COLS
            local row = math.floor((i-1) / SP_COLS)
            local sw = CreateFrame("Button", nil, savedPanel, "BackdropTemplate")
            sw:SetSize(SP_SW, SP_SW)
            sw:SetPoint("TOPLEFT",
                SP_PAD_X + col * (SP_SW + SP_GAP),
                -(13 + row * (SP_SW + SP_GAP)))
            sw:SetBackdrop(Backdrop()); sw:SetBackdropColor(r, g, b, a)
            sw:SetBackdropBorderColor(0.18, 0.18, 0.18, 1)
            sw:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            sw:SetScript("OnClick", function(self, btn)
                if btn == "LeftButton" then SelectColor(r, g, b, a)
                elseif btn == "RightButton" then
                    table.remove(savedColors, ci); SaveDB(); RefreshSaved()
                end
            end)
            sw:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(C_ACCENT[1],C_ACCENT[2],C_ACCENT[3],1)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(RGBtoHex(r,g,b,a), C_TEXT[1],C_TEXT[2],C_TEXT[3])
                GameTooltip:AddLine("Right-click to remove", 0.5,0.5,0.5)
                GameTooltip:Show()
            end)
            sw:SetScript("OnLeave", function(self)
                self:SetBackdropBorderColor(0.18,0.18,0.18,1); GameTooltip:Hide()
            end)
            table.insert(savedSwatches, sw)
        end
    end

    -- ── Button scripts (now that RefreshSaved is assigned) ──
    saveSwatchBtn:SetScript("OnClick", function()
        if #savedColors >= MAX_SAVED then return end
        local r, g, b = GetCurrentRGB()
        local a = pickerFrame.hasAlpha and curA or 1
        local key = ColorKey(r, g, b, a)
        for _, c in ipairs(savedColors) do
            if ColorKey(c.r, c.g, c.b, c.a or 1) == key then return end
        end
        table.insert(savedColors, 1, {r=r,g=g,b=b,a=a}); SaveDB(); RefreshSaved()
    end)
    clearSavedBtn:SetScript("OnClick", function()
        wipe(savedColors); SaveDB(); RefreshSaved()
    end)

    -- ── Store refs for external use ──
    pickerFrame._refreshTheme  = BuildThemeSection
    pickerFrame._refreshRecent = RefreshRecent
    pickerFrame._refreshSaved  = RefreshSaved


    -- ──────────────────────────────────────────────────────────
    -- FOOTER
    -- ──────────────────────────────────────────────────────────
    -- ──────────────────────────────────────────────────────────
    -- FOOTER (separator + Cancel | Apply | Default)
    -- ──────────────────────────────────────────────────────────
    local footer = CreateFrame("Frame", nil, pickerFrame, "BackdropTemplate")
    footer:SetHeight(52)
    footer:SetPoint("BOTTOMLEFT",  0, 0)
    footer:SetPoint("BOTTOMRIGHT", 0, 0)
    footer:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    footer:SetBackdropColor(C_ELEM[1]*0.7, C_ELEM[2]*0.7, C_ELEM[3]*0.7, 1)

    -- Full-width accent separator line
    local footerLine = footer:CreateTexture(nil, "ARTWORK")
    footerLine:SetHeight(1)
    footerLine:SetPoint("TOPLEFT",  footer, "TOPLEFT",  0, 0)
    footerLine:SetPoint("TOPRIGHT", footer, "TOPRIGHT", 0, 0)
    footerLine:SetColorTexture(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 0.35)

    -- Helper to make a footer button
    local function MakeFooterBtn(lbl, w, accent)
        local btn = CreateFrame("Button", nil, footer, "BackdropTemplate")
        btn:SetSize(w, 30)
        btn:SetBackdrop(Backdrop())
        if accent then
            btn:SetBackdropColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
            btn:SetBackdropBorderColor(C_ACCENT[1], C_ACCENT[2], C_ACCENT[3], 1)
        else
            btn:SetBackdropColor(C_ELEM[1]+0.04, C_ELEM[2]+0.04, C_ELEM[3]+0.04, 1)
            btn:SetBackdropBorderColor(C_BORDER[1]+0.06, C_BORDER[2]+0.06, C_BORDER[3]+0.06, 1)
        end
        local fs = btn:CreateFontString(nil, "OVERLAY")
        SetFont(fs, 11, "")
        fs:SetPoint("CENTER")
        fs:SetText(lbl)
        fs:SetTextColor(accent and 1 or C_TEXT[1], accent and 1 or C_TEXT[2], accent and 1 or C_TEXT[3])
        btn._fs = fs
        return btn
    end

    -- [ Cancel ]   [ Apply ]   [ Default ]
    -- Left: Cancel (ghost/red hover)
    local cancelBtn = MakeFooterBtn("Cancel", 110, false)
    cancelBtn:SetPoint("LEFT", footer, "LEFT", 10, 0)
    cancelBtn._fs:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])
    cancelBtn:SetScript("OnClick",  function() pickerFrame:Hide() end)
    cancelBtn:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(0.85, 0.3, 0.3, 1)
        s._fs:SetTextColor(1, 0.4, 0.4)
    end)
    cancelBtn:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(C_BORDER[1]+0.06, C_BORDER[2]+0.06, C_BORDER[3]+0.06, 1)
        s._fs:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])
    end)

    -- Center: Apply (bright blue fill)
    local applyBtn = MakeFooterBtn("Apply", 140, true)
    applyBtn:SetPoint("CENTER", footer, "CENTER", 0, 0)
    applyBtn:SetScript("OnEnter", function(s) s:SetBackdropColor(0, 0.72, 1, 1) end)
    applyBtn:SetScript("OnLeave", function(s) s:SetBackdropColor(C_ACCENT[1],C_ACCENT[2],C_ACCENT[3],1) end)

    -- Right: Default (ghost, dimmed, only shown when defaultColor set)
    local defaultBtn = MakeFooterBtn("Default", 110, false)
    defaultBtn:SetPoint("RIGHT", footer, "RIGHT", -10, 0)
    defaultBtn._fs:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])
    defaultBtn:SetScript("OnClick",  function()
        local d = pickerFrame.defaultColor
        if d then SelectColor(d.r or 1, d.g or 1, d.b or 1, d.a or 1) end
    end)
    defaultBtn:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(C_WARNING[1], C_WARNING[2], C_WARNING[3], 0.8)
        s._fs:SetTextColor(C_WARNING[1], C_WARNING[2], C_WARNING[3])
    end)
    defaultBtn:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(C_BORDER[1]+0.06, C_BORDER[2]+0.06, C_BORDER[3]+0.06, 1)
        s._fs:SetTextColor(C_MUTED[1], C_MUTED[2], C_MUTED[3])
    end)
    pickerFrame.defaultBtn = defaultBtn

    -- ── Add to Recent ──
    local function AddToRecent(r, g, b, a)
        local key = ColorKey(r, g, b, a or 1)
        for i, c in ipairs(recentColors) do
            if ColorKey(c.r, c.g, c.b, c.a or 1) == key then table.remove(recentColors, i); break end
        end
        table.insert(recentColors, 1, {r=r,g=g,b=b,a=a or 1})
        while #recentColors > MAX_RECENT do table.remove(recentColors) end
        SaveDB(); RefreshRecent()
    end
    pickerFrame._addToRecent = AddToRecent

    -- ── Apply logic ──
    applyBtn:SetScript("OnClick", function()
        local r, g, b = GetCurrentRGB()
        AddToRecent(r, g, b, pickerFrame.hasAlpha and curA or nil)
        pickerFrame.appliedColor = true
        if pickerFrame.onAcceptCallback then
            pickerFrame.onAcceptCallback({
                r = r, g = g, b = b,
                a = pickerFrame.hasAlpha and curA or 1
            })
        end
        pickerFrame:ClearCallbacks()
        pickerFrame:Hide()
    end)

    -- ──────────────────────────────────────────────────────────
    -- PUBLIC API ON FRAME
    -- ──────────────────────────────────────────────────────────
    function pickerFrame:ClearCallbacks()
        self.onAcceptCallback = nil
        self.onCancelCallback = nil
        self.onChangeCallback = nil
    end

    function pickerFrame:SetColor(r, g, b, a)
        curH, curS, curV = RGBtoHSV(r, g, b)
        curA = a or 1
        UpdateAll()
    end

    -- Store the initial "Prev" color shown in the top-right swatch
    pickerFrame._setPrevColor = function(r, g, b, a)
        prevTex:SetColorTexture(r, g, b, a or 1)
    end

    -- ──────────────────────────────────────────────────────────
    -- INIT
    -- ──────────────────────────────────────────────────────────
    BuildThemeSection()
    RefreshRecent()
    RefreshSaved()
    UpdateHueGradient()
    UpdateAll()
    -- Initialize Prev swatch with same default color as New
    local ir, ig, ib = HSVtoRGB(curH, curS, curV)
    prevTex:SetColorTexture(ir, ig, ib, curA)
    DoRestorePosition()
end  -- CreatePickerFrame()

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Opens the GravityUI Color Picker.
-- @param initialColor  table {r,g,b,a} in 0-1 range
-- @param hasAlpha      boolean – show alpha slider
-- @param onAccept      function(newColor) – called on Übernehmen
-- @param onCancel      function()         – called on Abbrechen / Escape
-- @param onChange      function(newColor) – live preview (optional)
-- @param defaultColor  table {r,g,b,a}   – enables 'Standard' button
function CP:Open(initialColor, hasAlpha, onAccept, onCancel, onChange, defaultColor)
    LoadDB()
    if not pickerFrame then CreatePickerFrame() end

    -- Suppress stale cancel when re-opening
    if pickerFrame:IsShown() then
        pickerFrame.appliedColor = true
        pickerFrame:Hide()
    end

    pickerFrame:ClearCallbacks()
    pickerFrame.appliedColor     = false
    pickerFrame.skipOnChange     = false
    pickerFrame.hasAlpha         = hasAlpha
    pickerFrame.defaultColor     = defaultColor
    pickerFrame.onAcceptCallback = onAccept
    pickerFrame.onCancelCallback = onCancel
    pickerFrame.onChangeCallback = onChange

    pickerFrame.defaultBtn:SetShown(defaultColor ~= nil)

    if initialColor then
        -- Set "Prev" swatch to the original color (before any changes)
        local ir = initialColor.r or 1
        local ig = initialColor.g or 1
        local ib = initialColor.b or 1
        local ia = hasAlpha and (initialColor.a or 1) or 1
        if pickerFrame._setPrevColor then pickerFrame._setPrevColor(ir, ig, ib, ia) end

        pickerFrame.skipOnChange = true
        pickerFrame:SetColor(ir, ig, ib, ia)
        pickerFrame.skipOnChange = false
        if pickerFrame._addToRecent then
            pickerFrame._addToRecent(ir, ig, ib, hasAlpha and ia or nil)
        end
    end

    pickerFrame:UpdateAlphaVis()

    -- Refresh palette sections (user might have changed theme since last open)
    if pickerFrame._refreshTheme  then pickerFrame._refreshTheme()  end
    if pickerFrame._refreshRecent then pickerFrame._refreshRecent() end

    -- Restore saved position
    pickerFrame:ClearAllPoints()
    if savedPosition then
        pickerFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", savedPosition.x, savedPosition.y)
    else
        pickerFrame:SetPoint("CENTER")
    end

    pickerFrame:Show()
end

-- ============================================================
-- BLIZZARD HOOK SYSTEM
-- Replaces Blizzard ColorPickerFrame addon-wide.
-- The Blizzard picker runs hidden – color is synced back to it
-- so that all third-party addon callbacks work automatically.
-- ============================================================
-- Installs the global Blizzard hook when hookAllAddons = true.
-- enabled = picker works in GravityUI; hookAllAddons = picker replaces Blizzard picker everywhere.
local blizzHookInstalled = false

local function HideBlizzard()
    if not ColorPickerFrame then return end
    ColorPickerFrame:UnregisterEvent("GLOBAL_MOUSE_DOWN")
    ColorPickerFrame:SetScale(0.001)
    ColorPickerFrame:SetAlpha(0)
    ColorPickerFrame:EnableMouse(false)
    ColorPickerFrame:ClearAllPoints()
    ColorPickerFrame:SetPoint("CENTER", UIParent, "CENTER", 10000, 10000)
end

local function RestoreBlizzard()
    if not ColorPickerFrame then return end
    ColorPickerFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
    ColorPickerFrame:SetScale(1)
    ColorPickerFrame:SetAlpha(1)
    ColorPickerFrame:EnableMouse(true)
    ColorPickerFrame:ClearAllPoints()
    ColorPickerFrame:SetPoint("CENTER")
end

local function SyncToBlizzard(r, g, b, a)
    if not ColorPickerFrame or not ColorPickerFrame:IsShown() then return end
    if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
        ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
        if ColorPickerFrame.hasOpacity and a and ColorPickerFrame.Content.ColorPicker.SetColorAlpha then
            ColorPickerFrame.Content.ColorPicker:SetColorAlpha(a)
        end
    end
    if ColorPickerFrame.SetColorRGB then ColorPickerFrame:SetColorRGB(r, g, b) end
end

local function ClickBlizzardOKWithColor(r, g, b, a)
    if not (ColorPickerFrame and ColorPickerFrame.Footer and ColorPickerFrame.Footer.OkayButton) then
        return
    end
    if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
        ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
        if ColorPickerFrame.hasOpacity and a and ColorPickerFrame.Content.ColorPicker.SetColorAlpha then
            ColorPickerFrame.Content.ColorPicker:SetColorAlpha(a)
        end
    end
    if ColorPickerFrame.SetColorRGB    then ColorPickerFrame:SetColorRGB(r, g, b) end
    if ColorPickerFrame.hasOpacity and a and ColorPickerFrame.SetColorAlpha then
        ColorPickerFrame:SetColorAlpha(a)
    end
    -- Restore just enough to make the click functional
    ColorPickerFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
    ColorPickerFrame:SetAlpha(1)
    ColorPickerFrame:EnableMouse(true)
    ColorPickerFrame.Footer.OkayButton:Click()
    ColorPickerFrame:SetScale(1)
    ColorPickerFrame:ClearAllPoints()
    ColorPickerFrame:SetPoint("CENTER")
end

local function ClickBlizzardCancel()
    if not (ColorPickerFrame and ColorPickerFrame.Footer and ColorPickerFrame.Footer.CancelButton) then
        return
    end
    ColorPickerFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
    ColorPickerFrame:SetAlpha(1)
    ColorPickerFrame:EnableMouse(true)
    ColorPickerFrame.Footer.CancelButton:Click()
    ColorPickerFrame:SetScale(1)
    ColorPickerFrame:ClearAllPoints()
    ColorPickerFrame:SetPoint("CENTER")
end

local function InstallBlizzardHook()
    if blizzHookInstalled or not ColorPickerFrame then return end

    hooksecurefunc(ColorPickerFrame, "SetupColorPickerAndShow", function(self, info)
        local db = GetDB()
        -- Only intercept when global hook is active
        if not (db and db.colorPicker and db.colorPicker.hookAllAddons) then return end

        local r, g, b = info.r or 1, info.g or 1, info.b or 1
        local a       = info.opacity or info.a or 1
        local hasA    = info.hasOpacity

        -- Hide Blizzard's frame (tiny delay so its callbacks get registered first)
        C_Timer.After(0.01, HideBlizzard)

        local defaultColor = info.dfDefaultColor
            or (info.previousValues and {
                r = info.previousValues.r or r,
                g = info.previousValues.g or g,
                b = info.previousValues.b or b,
                a = info.previousValues.a or a,
            })

        CP:Open(
            { r=r, g=g, b=b, a=a },
            hasA,
            function(c) ClickBlizzardOKWithColor(c.r, c.g, c.b, c.a) end,
            ClickBlizzardCancel,
            function(c) SyncToBlizzard(c.r, c.g, c.b, c.a) end,
            defaultColor
        )
    end)

    blizzHookInstalled = true
end

--- Enables or disables the global Blizzard hook (replaces picker for all addons).
--- Note: hooksecurefunc cannot be uninstalled; suppression is handled via DB flag.
function CP:SetGlobalHookEnabled(enabled)
    local db = GetDB()
    if db and db.colorPicker then db.colorPicker.hookAllAddons = enabled end
    if enabled and not blizzHookInstalled then
        InstallBlizzardHook()
    end
    InstallEllesmereHook()
end

-- ============================================================
-- ELLESMEREUI HOOK SYSTEM
-- Replaces EllesmereUI.ShowColorPicker with GravityUI's picker.
-- EUI's own swatch callbacks read the live color via
--   popup:GetColorRGB() / popup:GetColorAlpha()
-- so we install a lightweight proxy on EllesmereUI._colorPickerPopup
-- that returns the current GravityUI picker color.
-- ============================================================
local euiHookInstalled = false

-- Proxy object: mimics the fields EUI reads from its popup.
local euiProxy = {
    _r = 1, _g = 1, _b = 1, _a = 1,
    _shown = false,
}
function euiProxy:GetColorRGB()   return self._r, self._g, self._b end
function euiProxy:GetColorAlpha() return self._a end
function euiProxy:IsShown()       return self._shown end
function euiProxy:Hide()          self._shown = false end

local function InstallEllesmereHook()
    if euiHookInstalled then return end
    -- EllesmereUI may not be loaded yet; this is called again on ADDON_LOADED.
    if not (EllesmereUI and EllesmereUI.ShowColorPicker) then return end

    local db = GetDB()
    if not (db and db.colorPicker and db.colorPicker.hookAllAddons) then return end

    -- Store EUI's original function so we can call it when our hook is disabled.
    local _origShowColorPicker = EllesmereUI.ShowColorPicker

    EllesmereUI.ShowColorPicker = function(self, info, anchorFrame)
        -- Re-check the flag at call time so toggling in settings takes effect
        -- without needing a reload.
        local db2 = GetDB()
        if not (db2 and db2.colorPicker and db2.colorPicker.hookAllAddons) then
            _origShowColorPicker(self, info, anchorFrame)
            return
        end

        local r, g, b = info.r or 1, info.g or 1, info.b or 1
        local a       = info.opacity or 1
        local hasA    = info.hasOpacity or false

        -- Install proxy so EUI swatch callbacks that call popup:GetColorRGB()
        -- see our live color immediately.
        euiProxy._r, euiProxy._g, euiProxy._b, euiProxy._a = r, g, b, a
        euiProxy._shown = true
        EllesmereUI._colorPickerPopup = euiProxy

        CP:Open(
            { r=r, g=g, b=b, a=a },
            hasA,
            -- Apply callback (OK button)
            function(c)
                euiProxy._r, euiProxy._g, euiProxy._b, euiProxy._a = c.r, c.g, c.b, c.a
                if info.swatchFunc   then info.swatchFunc()   end
                if hasA and info.opacityFunc then info.opacityFunc() end
                euiProxy._shown = false
            end,
            -- Cancel callback
            function()
                if info.cancelFunc then info.cancelFunc() end
                euiProxy._shown = false
            end,
            -- onChange live-preview callback
            function(c)
                euiProxy._r, euiProxy._g, euiProxy._b, euiProxy._a = c.r, c.g, c.b, c.a
                if info.swatchFunc   then info.swatchFunc()   end
                if hasA and info.opacityFunc then info.opacityFunc() end
            end,
            -- Default color (none provided by EUI; use start color)
            { r=r, g=g, b=b, a=a }
        )
    end

    euiHookInstalled = true
end

-- ============================================================
-- INITIALISATION
-- ============================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        LoadDB()
    elseif event == "ADDON_LOADED" and arg1 == "EllesmereUI" then
        -- EllesmereUI just finished loading; install our hook if active.
        local db = GetDB()
        if db and db.colorPicker and db.colorPicker.hookAllAddons then
            InstallEllesmereHook()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local db = GetDB()
        if db and db.colorPicker and db.colorPicker.hookAllAddons then
            InstallBlizzardHook()
            InstallEllesmereHook()
        end
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

