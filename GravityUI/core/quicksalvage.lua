-- GravityUI - Quick Salvage Module
-- One-click Milling, Prospecting, Disenchanting
local ADDON_NAME, ns = ...

local QuickSalvage = {}
ns.QuickSalvage = QuickSalvage

-- Spell IDs
local SPELL_DISENCHANT = 13262

-- Colors (using ns.Colors where possible or defining local ones)
local COLORS = {
    disenchant = CreateColor(0.7, 0.3, 0.9),  -- Purple
    milling = CreateColor(0.3, 0.8, 0.3),     -- Green
    prospecting = CreateColor(1.0, 0.6, 0.2), -- Orange
    salvage = CreateColor(0.2, 0.8, 1.0),     -- Cyan (fallback)
}

-- Current modifier setting
local currentModifier = "ALT"

local IsPlayerSpell = C_SpellBook.IsSpellKnown or IsPlayerSpell

---------------------------------------------------------------------------
-- DYNAMIC SALVAGE LOOKUP
---------------------------------------------------------------------------
local SalvageLookup = {} -- [itemID] = { spellID, color, required, action }
local SalvageLookupBuilt = false
local SalvageLookupBuilding = false
local SalvageLookupLastAttempt = 0

local SALVAGE_CACHE_VERSION = 1

local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.quickSalvage then
        return db.uiimprovements.quickSalvage
    end
    return nil
end

local function LoadSalvageLookupFromDB()
    local db = ns.GetDB()
    local cache = db and db.quickSalvageCache
    if not (cache and cache.version == SALVAGE_CACHE_VERSION and type(cache.items) == "table") then
        return false
    end

    table.wipe(SalvageLookup)
    local count = 0
    for itemID, entry in pairs(cache.items) do
        if type(itemID) == "number" and type(entry) == "table" and entry.spellID then
            SalvageLookup[itemID] = {
                spellID = entry.spellID,
                required = entry.required,
                action = entry.action,
            }
            count = count + 1
        end
    end

    SalvageLookupBuilt = count > 0
    return SalvageLookupBuilt
end

local function SaveSalvageLookupToDB()
    local db = ns.GetDB()
    if not db then return end

    local items = {}
    local count = 0
    for itemID, entry in pairs(SalvageLookup) do
        if type(itemID) == "number" and type(entry) == "table" and entry.spellID then
            items[itemID] = {
                spellID = entry.spellID,
                required = entry.required,
                action = entry.action,
            }
            count = count + 1
        end
    end

    db.quickSalvageCache = {
        version = SALVAGE_CACHE_VERSION,
        builtAt = time(),
        count = count,
        items = items,
    }
end

local function EnsureProfessionsUI()
    if not C_AddOns or not C_AddOns.IsAddOnLoaded then return false end
    return C_AddOns.IsAddOnLoaded("Blizzard_Professions") or C_AddOns.IsAddOnLoaded("Blizzard_TradeSkillUI")
end

local function RebuildSalvageLookup()
    if SalvageLookupBuilding or InCombatLockdown() then return end
    if not (C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs) then return end
    if C_TradeSkillUI.IsTradeSkillReady and not C_TradeSkillUI.IsTradeSkillReady() then return end
    if not EnsureProfessionsUI() then return end
    
    local now = GetTime()
    if (now - SalvageLookupLastAttempt) < 10 then return end
    SalvageLookupLastAttempt = now

    SalvageLookupBuilding = true

    local ok = pcall(function()
        table.wipe(SalvageLookup)
        local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs() or {}
        local salvageRecipeType = Enum.TradeskillRecipeType.Salvage
        local itemRecipeType = Enum.TradeskillRecipeType.Item

        for _, recipeID in ipairs(recipeIDs) do
            local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
            if schematic and (schematic.recipeType == salvageRecipeType or schematic.recipeType == itemRecipeType) then
                local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
                local recipeSpellID = recipeInfo and recipeInfo.recipeSpellID
                if recipeSpellID and recipeInfo.learned then
                    local includeRecipe = false
                    local action = "salvage"
                    
                    if schematic.recipeType == salvageRecipeType then
                        includeRecipe = true
                    elseif recipeInfo.alternateVerb then
                        local lowerVerb = string.lower(recipeInfo.alternateVerb)
                        if string.find(lowerVerb, "mill") then
                            includeRecipe = true
                            action = "milling"
                        elseif string.find(lowerVerb, "prospect") then
                            includeRecipe = true
                            action = "prospecting"
                        end
                    end

                    if includeRecipe then
                        local color = COLORS[action] or COLORS.salvage
                        local slots = schematic.reagentSlotSchematics
                        if type(slots) == "table" then
                            for _, slot in ipairs(slots) do
                                local qty = slot.quantityRequired
                                local reagents = slot.reagents
                                if type(reagents) == "table" then
                                    for _, reagent in ipairs(reagents) do
                                        if reagent.itemID then
                                            SalvageLookup[reagent.itemID] = { spellID = recipeSpellID, color = color, required = qty, action = action }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    if ok then
        SalvageLookupBuilt = next(SalvageLookup) ~= nil
        if SalvageLookupBuilt then SaveSalvageLookupToDB() end
    end
    SalvageLookupBuilding = false
end

---------------------------------------------------------------------------
-- SECURE BUTTON
---------------------------------------------------------------------------
local TEMPLATES = "SecureActionButtonTemplate,SecureHandlerAttributeTemplate,SecureHandlerEnterLeaveTemplate"
local SalvageButton = CreateFrame("Button", "GravityUI_QuickSalvageButton", UIParent, TEMPLATES)
SalvageButton:SetFrameStrata("TOOLTIP")
SalvageButton:EnableMouse(true)
SalvageButton:RegisterForClicks("AnyUp", "AnyDown")
SalvageButton:Hide()

-- Glow Effect
local Glow = SalvageButton:CreateTexture(nil, "ARTWORK")
Glow:SetPoint("CENTER")
Glow:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
Glow:SetDesaturated(true)

local Animation = SalvageButton:CreateAnimationGroup()
Animation:SetLooping("REPEAT")
local FlipBook = Animation:CreateAnimation("FlipBook")
FlipBook:SetTarget(Glow)
FlipBook:SetDuration(1)
FlipBook:SetFlipBookColumns(5)
FlipBook:SetFlipBookRows(6)
FlipBook:SetFlipBookFrames(30)

local function SetGlowColor(color)
    if color then Glow:SetVertexColor(color:GetRGB()) end
    local w, h = SalvageButton:GetSize()
    if w and w > 0 then Glow:SetSize(w * 1.4, h * 1.4) end
end

SalvageButton:SetScript("OnShow", function() Animation:Play() end)
SalvageButton:SetScript("OnHide", function() Animation:Stop() end)

---------------------------------------------------------------------------
-- LOGIC
---------------------------------------------------------------------------
local function IsModifierActive()
    local s = GetSettings()
    if not s or not s.enabled then return false end
    
    local mod = s.modifier or "ALT"
    if not IsAltKeyDown() then return false end

    if mod == "ALTCTRL" then return IsControlKeyDown()
    elseif mod == "ALTSHIFT" then return IsShiftKeyDown()
    else return not IsControlKeyDown() and not IsShiftKeyDown() end
end

local function GetSalvageInfo(itemID, stackCount)
    if not itemID then return end
    
    -- Check dynamic lookup
    if not SalvageLookupBuilt and not SalvageLookupBuilding then LoadSalvageLookupFromDB() end
    local salvage = SalvageLookup[itemID]
    if salvage then
        if salvage.required and stackCount < salvage.required then
            return nil, nil, "salvage", salvage.required, true
        end
        return salvage.spellID, (COLORS[salvage.action] or COLORS.salvage), salvage.action, salvage.required
    end

    -- Disenchant Check
    local quality = C_Item.GetItemQualityByID(itemID)
    local _, _, _, equipLoc, _, classID = C_Item.GetItemInfoInstant(itemID)
    if quality and classID and quality >= Enum.ItemQuality.Uncommon and quality <= Enum.ItemQuality.Epic then
        if classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Profession then
            if equipLoc ~= "INVTYPE_BODY" and not (C_Item.IsCosmeticItem and C_Item.IsCosmeticItem(itemID)) then
                if IsPlayerSpell(SPELL_DISENCHANT) then
                    return SPELL_DISENCHANT, COLORS.disenchant, "disenchant"
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- HOOKS & EVENTS
---------------------------------------------------------------------------
local function ApplyOwnerRect(self, owner)
    if not owner or not owner.GetScaledRect then return end
    local left, bottom, width, height = owner:GetScaledRect()
    if not left or width < 5 then return end

    local scale = 1 / UIParent:GetScale()
    self:ClearAllPoints()
    self:SetPoint("BOTTOMLEFT", left * scale, bottom * scale)
    self:SetSize(width * scale, height * scale)
    return true
end

local MACRO_SALVAGE = "/run C_TradeSkillUI.CraftSalvage(%d, 1, ItemLocation:CreateFromBagAndSlot(%d, %d))"

function SalvageButton:ApplySpell(bagID, slotID, itemLink, spellID, color, owner)
    if not ApplyOwnerRect(self, owner) then return end
    
    local settings = GetSettings()
    local mod = settings.modifier or "ALT"
    local typePrefix = (mod == "ALTCTRL" and "alt-ctrl-") or (mod == "ALTSHIFT" and "alt-shift-") or "alt-"

    self:SetAttribute("target-bag", bagID)
    self:SetAttribute("target-slot", slotID)
    self.spellID = spellID
    self.itemLink = itemLink
    self.owner = owner

    -- Determine if it's a legacy spell (Disenchant) or a modern salvage API call
    if spellID == SPELL_DISENCHANT then
        self:SetAttribute(typePrefix .. "type1", "spell")
        self:SetAttribute(typePrefix .. "spell1", spellID)
        self:SetAttribute(typePrefix .. "macrotext1", nil)
    else
        local macro = MACRO_SALVAGE:format(spellID, bagID, slotID)
        self:SetAttribute(typePrefix .. "type1", "macro")
        self:SetAttribute(typePrefix .. "macrotext1", macro)
        self:SetAttribute(typePrefix .. "spell1", nil)
    end
    
    self:SetAttribute("type1", nil) -- Only clickable with modifier
    self:Show()
    SetGlowColor(color)
end

-- Tooltip Sync
SalvageButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.itemLink then GameTooltip:SetHyperlink(self.itemLink) end
    local spellName = C_Spell.GetSpellName(self.spellID)
    if spellName then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|A:NPE_LeftClick:18:18|a |cff0090ff" .. spellName .. "|r", 1, 1, 1)
    end
    GameTooltip:Show()
end)
SalvageButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Secure Deactivation
SalvageButton:SetAttribute("_onleave", "self:ClearAllPoints(); self:Hide()")

local function OnTooltipSetItem(tooltip, data)
    if InCombatLockdown() or not IsModifierActive() then return end
    if tooltip:GetOwner() == SalvageButton then return end

    local itemID = data and data.id
    if not itemID then return end

    local owner = tooltip:GetOwner()
    if not owner or not (owner.GetBagID and owner.GetID) then return end
    
    local bagID, slotID = owner:GetBagID(), owner:GetID()
    if not bagID or not slotID then return end

    local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
    local stackCount = C_Container.GetContainerItemInfo(bagID, slotID).stackCount

    local spellID, color, action, required, needsMore = GetSalvageInfo(itemID, stackCount)
    if spellID and not needsMore then
        if IsPlayerSpell(spellID) then
            SalvageButton:ApplySpell(bagID, slotID, data.hyperlink, spellID, color, owner)
        end
    end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
eventFrame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "BAG_UPDATE_DELAYED" then
        if SalvageButton:IsShown() and not InCombatLockdown() then SalvageButton:Hide() end
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" then
        RebuildSalvageLookup()
    elseif event == "MODIFIER_STATE_CHANGED" then
        if SalvageButton:IsShown() and not IsModifierActive() and not InCombatLockdown() then
            SalvageButton:Hide()
        end
    end
end)
