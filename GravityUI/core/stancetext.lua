-- ============================================================================
-- GravityUI - Stance / Shapeshift Text Display
-- Displays configurable text indicator for current Stance, Form, or Aura
-- ============================================================================
local ADDON_NAME, ns = ...

local LSM = LibStub("LibSharedMedia-3.0", true)

ns.StanceText = ns.StanceText or {}
local ST = ns.StanceText

local stanceFrame = nil
local isPreviewActive = false

-- Paladin Aura spell IDs
local PALADIN_AURAS = {
    [465]    = "Devotion",
    [317920] = "Concentration",
    [32223]  = "Crusader",
    [183435] = "Retribution",
}

-- Rogue Stealthed spell IDs
local ROGUE_STEALTH_SPELLS = {
    [1784]   = "Stealth",
    [185313] = "Shadow Dance",
    [185422] = "Shadow Dance",
    [11327]  = "Vanish",
    [115191] = "Stealth",
}

-- Priest Forms
local PRIEST_FORMS = {
    [232698] = "Shadowform",
    [65248]  = "Shadowform",
    [15473]  = "Shadowform",
    [194249] = "Voidform",
}

-- Demon Hunter Metamorphosis
local DH_FORMS = {
    [187827] = "Metamorphosis",
    [162264] = "Metamorphosis",
}

local function GetDB()
    local db = ns.GetDB and ns.GetDB()
    if db and db.screenindicators and db.screenindicators.stanceText then
        return db.screenindicators.stanceText
    end
    return nil
end

local function GetClassColor()
    local _, class = UnitClass("player")
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b, 1
    end
    return 1, 1, 1, 1
end

-- ============================================================================
-- STANCE DETECTION (Event-driven, zero garbage allocation)
-- ============================================================================

local function GetCurrentStanceName()
    local _, class = UnitClass("player")
    local form = GetShapeshiftForm and GetShapeshiftForm()

    -- 1. Standard Shapeshift / Stance API (Druid, Warrior, etc.)
    if form and form > 0 and GetShapeshiftFormInfo then
        local _, _, _, spellID = GetShapeshiftFormInfo(form)
        if spellID then
            local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            local name = spellInfo and spellInfo.name
            if name then
                -- Clean up common redundant suffixes
                name = name:gsub(" Form", ""):gsub(" Gestalt", ""):gsub(" Stance", ""):gsub("haltung", "")
                return name:upper()
            end
        end
    end

    -- 2. Paladin Auras (Check player helpful auras)
    if class == "PALADIN" and AuraUtil and AuraUtil.ForEachAura then
        local foundAura = nil
        AuraUtil.ForEachAura("player", "HELPFUL", nil, function(aura)
            if aura and aura.spellId and PALADIN_AURAS[aura.spellId] then
                foundAura = PALADIN_AURAS[aura.spellId]
                return true
            end
            return false
        end, true)
        if foundAura then return foundAura:upper() end
    end

    -- 3. Rogue Stealth / Shadow Dance
    if class == "ROGUE" and AuraUtil and AuraUtil.ForEachAura then
        local foundStealth = nil
        AuraUtil.ForEachAura("player", "HELPFUL", nil, function(aura)
            if aura and aura.spellId and ROGUE_STEALTH_SPELLS[aura.spellId] then
                foundStealth = ROGUE_STEALTH_SPELLS[aura.spellId]
                return true
            end
            return false
        end, true)
        if foundStealth then return foundStealth:upper() end
    end

    -- 4. Priest Shadowform / Voidform
    if class == "PRIEST" and AuraUtil and AuraUtil.ForEachAura then
        local foundForm = nil
        AuraUtil.ForEachAura("player", "HELPFUL", nil, function(aura)
            if aura and aura.spellId and PRIEST_FORMS[aura.spellId] then
                foundForm = PRIEST_FORMS[aura.spellId]
                return true
            end
            return false
        end, true)
        if foundForm then return foundForm:upper() end
    end

    -- 5. Demon Hunter Metamorphosis
    if class == "DEMONHUNTER" and AuraUtil and AuraUtil.ForEachAura then
        local foundMeta = nil
        AuraUtil.ForEachAura("player", "HELPFUL", nil, function(aura)
            if aura and aura.spellId and DH_FORMS[aura.spellId] then
                foundMeta = DH_FORMS[aura.spellId]
                return true
            end
            return false
        end, true)
        if foundMeta then return foundMeta:upper() end
    end

    return nil
end

local function FormatStanceText(stanceName, bracketStyle)
    if not stanceName or stanceName == "" then return "" end
    bracketStyle = bracketStyle or "brackets"

    if bracketStyle == "brackets" then
        return "[ " .. stanceName .. " ]"
    elseif bracketStyle == "hyphens" then
        return "- " .. stanceName .. " -"
    elseif bracketStyle == "arrows" then
        return ">> " .. stanceName .. " <<"
    elseif bracketStyle == "colon" then
        return ": " .. stanceName .. " :"
    else
        return stanceName
    end
end

-- ============================================================================
-- FRAME & UPDATE LOGIC
-- ============================================================================

local function CreateStanceFrame()
    if stanceFrame then return end

    local f = CreateFrame("Frame", "GravityUI_StanceTextFrame", UIParent)
    local db = GetDB()
    f:SetSize(200, 32)
    f:SetFrameStrata((db and db.strata) or "HIGH")
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    local text = f:CreateFontString(nil, "OVERLAY", nil, 7)
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    f.text = text

    f:EnableMouse(false)
    f:Hide()
    stanceFrame = f

    -- Drag Handlers for Movers
    f:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local pt, _, relPt, x, y = self:GetPoint()
        local db = GetDB()
        if db then
            db.point = pt or "CENTER"
            db.relativePoint = relPt or "CENTER"
            db.x = math.floor((x or 0) + 0.5)
            db.y = math.floor((y or 0) + 0.5)
        end
    end)

    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("StanceText", f, function(frame, enabled)
            ST:ToggleMover(enabled)
        end, "Stance Text")
    end
end

function ST:ApplyPosition()
    if not stanceFrame then return end
    local db = GetDB()
    if not db then return end

    stanceFrame:ClearAllPoints()
    local pt = db.point or "CENTER"
    local relPt = db.relativePoint or "CENTER"
    local x = db.x or 0
    local y = db.y or -180
    stanceFrame:SetPoint(pt, UIParent, relPt, x, y)
end

function ST:UpdateStyles()
    if not stanceFrame or not stanceFrame.text then return end
    local db = GetDB()
    if not db then return end

    local font = (ns.Styling and ns.Styling.GetFontPath and ns.Styling:GetFontPath()) or
                 (LSM and LSM:Fetch("font", ns.GetDB() and ns.GetDB().general and ns.GetDB().general.font or "Gravity")) or
                 "Fonts\\FRIZQT__.TTF"
    local fontSize = db.fontSize or 18
    local outline = db.fontOutline or "OUTLINE"
    stanceFrame.text:SetFont(font, fontSize, outline)
    stanceFrame:SetFrameStrata(db.strata or "HIGH")

    -- Color
    local r, g, b, a
    local colorMode = db.colorMode or "class"
    if colorMode == "theme" then
        if ns.GetAccentColor then
            r, g, b, a = ns.GetAccentColor()
        else
            r, g, b, a = 1, 0.75, 0, 1
        end
    elseif colorMode == "custom" then
        local c = db.customColor or { 1, 1, 1, 1 }
        r, g, b, a = c[1], c[2], c[3], c[4] or 1
    else
        r, g, b, a = GetClassColor()
    end
    stanceFrame.text:SetTextColor(r, g, b, a or 1)
end

function ST:UpdateDisplay()
    if isPreviewActive then return end
    local db = GetDB()
    if not db or not db.enabled then
        if stanceFrame then stanceFrame:Hide() end
        return
    end

    CreateStanceFrame()
    self:ApplyPosition()
    self:UpdateStyles()

    -- Combat Check
    if db.onlyInCombat and not InCombatLockdown() then
        stanceFrame:Hide()
        return
    end

    local stance = GetCurrentStanceName()

    if not stance then
        if db.hideInCasterForm ~= false then
            stanceFrame:Hide()
            return
        else
            stance = "NORMAL"
        end
    end

    local formatted = FormatStanceText(stance, db.bracketStyle)
    stanceFrame.text:SetText(formatted)
    stanceFrame:Show()
end

-- ============================================================================
-- PREVIEW & MOVER (Edit Mode)
-- ============================================================================

function ST:ShowPreview()
    CreateStanceFrame()
    if not stanceFrame then return end

    isPreviewActive = true
    self:ApplyPosition()
    self:UpdateStyles()

    local db = GetDB()
    local sampleText = "CAT FORM"
    local _, class = UnitClass("player")
    if class == "WARRIOR" then
        sampleText = "DEFENSIVE"
    elseif class == "PALADIN" then
        sampleText = "DEVOTION"
    elseif class == "ROGUE" then
        sampleText = "STEALTH"
    elseif class == "PRIEST" then
        sampleText = "SHADOWFORM"
    elseif class == "DEMONHUNTER" then
        sampleText = "METAMORPHOSIS"
    end

    local formatted = FormatStanceText(sampleText, db and db.bracketStyle)
    stanceFrame.text:SetText(formatted)
    stanceFrame:Show()
    stanceFrame:EnableMouse(true)

    if ns.Movers and ns.Movers.ApplyEditModeStyle then
        ns.Movers:ApplyEditModeStyle(stanceFrame, true, "StanceText")
        if stanceFrame.ag_backdrop then
            if stanceFrame.ag_backdrop.title then stanceFrame.ag_backdrop.title:Hide() end
            if stanceFrame.ag_backdrop.dim then stanceFrame.ag_backdrop.dim:Hide() end
        end
    end
end

function ST:HidePreview()
    CreateStanceFrame()
    if not stanceFrame then return end

    isPreviewActive = false
    stanceFrame:EnableMouse(false)
    if ns.Movers and ns.Movers.ApplyEditModeStyle then
        if stanceFrame.ag_backdrop then
            if stanceFrame.ag_backdrop.title then stanceFrame.ag_backdrop.title:Show() end
            if stanceFrame.ag_backdrop.dim then stanceFrame.ag_backdrop.dim:Show() end
        end
        ns.Movers:ApplyEditModeStyle(stanceFrame, false, "StanceText")
    end
    self:UpdateDisplay()
end

function ST:ToggleMover(enabled)
    CreateStanceFrame()
    if not stanceFrame then return end

    if enabled ~= nil then
        if enabled then
            self:ShowPreview()
        else
            self:HidePreview()
        end
    else
        if isPreviewActive then
            self:HidePreview()
        else
            self:ShowPreview()
        end
    end
end

function ST:PreviewTest()
    CreateStanceFrame()
    if not stanceFrame then return end

    if isPreviewActive then
        self:HidePreview()
        return
    end

    self:ShowPreview()
    C_Timer.After(4, function()
        if isPreviewActive and (not ns.Movers or not ns.Movers.isEditMode) then
            ST:HidePreview()
        end
    end)
end

-- ============================================================================
-- INITIALIZATION & EVENTS
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        CreateStanceFrame()
        ST:ApplyPosition()
        ST:UpdateDisplay()
    elseif event == "UNIT_AURA" then
        if unit == "player" then
            ST:UpdateDisplay()
        end
    else
        ST:UpdateDisplay()
    end
end)

function ST:Refresh()
    self:ApplyPosition()
    self:UpdateStyles()
    self:UpdateDisplay()
end

ns.RefreshStanceText = function()
    ST:Refresh()
end
