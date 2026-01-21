local ADDON_NAME, ns = ...
local guiCore = _G.GravityUI and _G.GravityUI.guiCore
local gui = _G.GravityUI

---------------------------------------------------------------------------
-- Farbsystem aus GravityUI Skin laden
---------------------------------------------------------------------------
local function GetSkinColorHex()
    local r, g, b = 0.2, 1.0, 0.6 -- Standard (Mint)
    if gui and gui.GetSkinColor then
        r, g, b = gui:GetSkinColor()
    end
    return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

---------------------------------------------------------------------------
-- Hilfsfunktion für Settings
---------------------------------------------------------------------------
local function GetSettings()
    if guiCore and guiCore.db and guiCore.db.profile then
        return guiCore.db.profile.tooltips
    end
    return nil
end

---------------------------------------------------------------------------
-- NEU: Namen nach Klassenfarbe einfärben
---------------------------------------------------------------------------
local function ColorHeader(tooltip, data)
    if not tooltip or tooltip:IsForbidden() or not data or not data.guid then return end
    
    local settings = GetSettings()
    if not settings or not settings.classColorHeader then return end

    local guid = data.guid
    local isPlayer = false
    
    -- Kompletten Block absichern
    pcall(function()
        -- Prüfung auf Secret Value falls vorhanden
        if IsSecretValue and IsSecretValue(guid) then return end
        
        if type(guid) == "string" and guid:find("Player") then
            local _, class = GetPlayerInfoByGUID(guid)
            local color = class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
            
            if color then
                local text = _G[tooltip:GetName().."TextLeft1"]
                if text then
                    text:SetTextColor(color.r, color.g, color.b)
                end
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Tooltip Style (Viereckig & Clean)
---------------------------------------------------------------------------
local function ApplyStyle(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end
    local settings = GetSettings()
    if not settings or not settings.customStyle then return end

    if tooltip.NineSlice then
        tooltip.NineSlice:Hide()
        tooltip.NineSlice:SetAlpha(0)
    end

    if not tooltip.SetBackdrop then
        Mixin(tooltip, BackdropTemplateMixin)
    end

    tooltip:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

	-- Ersetze den Schriftgrößen-Teil in ApplyStyle mit diesem sichereren Block:
	if settings.fontSize then
		for i = 1, 15 do -- Begrenzung statt endlos-while
			local left = _G[tooltip:GetName().."TextLeft"..i]
			local right = _G[tooltip:GetName().."TextRight"..i]
			if not left then break end

			-- Nutze pcall, um den Zugriff auf Font-Daten zu schützen
			pcall(function()
				local fontFile, _, fontFlags = left:GetFont()
				if fontFile then
					left:SetFont(fontFile, settings.fontSize, fontFlags)
				end
				if right then
					local rFontFile, _, rFontFlags = right:GetFont()
					if rFontFile then
						right:SetFont(rFontFile, settings.fontSize, rFontFlags)
					end
				end
			end)
		end
	end

    local bg = settings.bgColor or {0, 0, 0, 0.8}
    local border = settings.borderColor or {0.3, 0.3, 0.3, 1}
    tooltip:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    tooltip:SetBackdropBorderColor(border[1], border[2], border[3], border[4])

    -- Healthbar ausblenden
    if tooltip.HealthBar then
        tooltip.HealthBar:SetAlpha(0)
    end
	GameTooltipStatusBarTexture:SetTexture(nil)
end

---------------------------------------------------------------------------
-- Extra Infos (IDs für Spells/Items)
---------------------------------------------------------------------------
local function AddExtraInfo(tooltip, data)
    if not tooltip or tooltip:IsForbidden() then return end
    local settings = GetSettings()
    if not settings or not settings.showIDs then return end

    local id = data and (data.id or data.spellId or data.itemId)
    if not id then return end

    -- WICHTIG: Vor String-Verknüpfung prüfen!
    if IsSecretValue and IsSecretValue(id) then return end

    pcall(function()
        local color = GetSkinColorHex()
        tooltip:AddLine(" ") 
        tooltip:AddDoubleLine(color .. "ID:|r", "|cffffffff" .. tostring(id) .. "|r")
    end)
end

---------------------------------------------------------------------------
-- Initialisierung der Hooks
---------------------------------------------------------------------------
	-- Definiere die Funktion AUßERHALB oder VOR dem Hook-Aufruf
local function OnTooltipShow(self)
    -- 1. Sicherheitscheck: Im Kampf oder wenn Tooltip verboten, sofort abbrechen
    if InCombatLockdown() or not self or self:IsForbidden() then return end
    
    -- 2. Sicherer Datenabruf
    local data
    pcall(function() data = self:GetTooltipData() end)
    
    -- 3. Prüfen ob es eine Aura ist (Buff/Debuff)
    if data and data.type == Enum.TooltipDataType.UnitAura then
        -- Styling in pcall kapseln gegen "Secret Value"-Zugriffe
        pcall(function()
            ApplyStyle(self)
        end)
    end
end

-- 1. Die OnTooltipShow Funktion (muss VOR InitStyle stehen)
local function OnTooltipShow(self)
    -- WICHTIG: Wenn wir im Kampf sind, brechen wir SOFORT ab.
    -- Das verhindert den "string conversion" Fehler bei Blizzard-Modulen.
    if InCombatLockdown() or not self or self:IsForbidden() then return end
    
    -- Sicherer Datenabruf
    local data
    pcall(function() data = self:GetTooltipData() end)
    
    -- Wir prüfen, ob es eine Aura ist (Buff/Debuff)
    if data and data.type == Enum.TooltipDataType.UnitAura then
        -- Styling in pcall kapseln
        pcall(function()
            ApplyStyle(self)
        end)
    end
end

-- 2. Die InitStyle Funktion
local function InitStyle()
    if not TooltipDataProcessor then return end

    -- 1. Units (Spieler/NPCs)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        -- Im Kampf Styling überspringen für maximale Sicherheit
        if InCombatLockdown() or not tooltip or tooltip:IsForbidden() then return end
        pcall(function()
            ApplyStyle(tooltip)
            ColorHeader(tooltip, data)
            AddExtraInfo(tooltip, data)
        end)
    end)
    
    -- 2. Items
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if InCombatLockdown() or not tooltip or tooltip:IsForbidden() then return end
        pcall(function()
            ApplyStyle(tooltip)
            AddExtraInfo(tooltip, data)
        end)
    end)
    
-- 3. Zauber (Spells) - Jetzt mit Timeline-Schutz
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
        -- 1. Grundcheck
        if not tooltip or tooltip:IsForbidden() then return end
        
        -- 2. WICHTIG: Timeline & Kampf-Schutz
        -- Wenn wir im Kampf sind ODER der Tooltip von der Timeline kommt, 
        -- lassen wir das Styling komplett weg, um den Crash zu vermeiden.
        if InCombatLockdown() then return end
        
        -- 3. Sicherer Check der ID
        local spellID = data and data.id
        if not spellID or (IsSecretValue and IsSecretValue(spellID)) then
            return
        end

        -- 4. Styling nur ausführen, wenn alles sicher ist
        pcall(function()
            ApplyStyle(tooltip)
            AddExtraInfo(tooltip, data)
        end)
    end)

    -- 4. BUFFS / DEBUFFS (Sicherer Umweg über HookScript)
    if not GameTooltip.GravityHookSet then
        GameTooltip:HookScript("OnShow", OnTooltipShow)
        GameTooltip.GravityHookSet = true
    end
end

---------------------------------------------------------------------------
-- Globaler Refresh & Laden
---------------------------------------------------------------------------
_G.GravityUI_RefreshTooltips = function()
    local tt = GameTooltip
    if tt and tt:IsShown() and not tt:IsForbidden() then 
        ApplyStyle(tt)
        ColorHeader(tt)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    InitStyle()
end)


