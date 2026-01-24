-- cooldownswipe.lua
-- Granulare Cooldown-Swipe-Kontrolle: Buff-Dauer / GCD / Cooldown-Swipes

local _, gui = ...

-- Hole Einstellungen aus AceDB
local function GetSettings()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if not guiCore or not guiCore.db or not guiCore.db.profile then
        return {
            showBuffSwipe = true,
			showBuffIconSwipe = false,						  
            showGCDSwipe = true,
            showCooldownSwipe = true,
        }
    end
    local cs = guiCore.db.profile.cooldownSwipe
    if not cs then
        cs = {
            showBuffSwipe = true,
			showBuffIconSwipe = false,						  
            showGCDSwipe = true,
            showCooldownSwipe = true,
        }
        guiCore.db.profile.cooldownSwipe = cs
    end
    return cs
end

-- Einziger einheitlicher Hook für SetCooldown, der ALLE Swipe-Typen verwaltet
-- Läuft bei JEDEM Cooldown-Update, um sicherzustellen dass Einstellungen immer angewendet werden
local function HookSetCooldown(icon)
    if not icon or not icon.Cooldown then return end
    if icon._gui_SetCooldownHooked then return end
    icon._gui_SetCooldownHooked = true

    -- Speichere Parent-Referenz auf Cooldown-Frame für Hook-Zugriff
    icon.Cooldown._guiParentIcon = icon

    hooksecurefunc(icon.Cooldown, "SetCooldown", function(self)
        local parentIcon = self._guiParentIcon
        if not parentIcon then return end

        -- Überspringe falls wir SetCooldown selbst aufrufen (Rekursionsschutz)
        if parentIcon._gui_BypassCDHook then return end

        local settings = GetSettings()
        local showSwipe
        local auraActive = parentIcon.auraInstanceID and parentIcon.auraInstanceID > 0

        -- Swipe-Logik
        -- Priorität 1: Buff-Dauer (auraInstanceID > 0)
        if auraActive then																				
		-- Prüfe ob dieses Icon in BuffIconCooldownViewer ist (separater Toggle)
            local parent = parentIcon:GetParent()
            if parent == _G.BuffIconCooldownViewer then
                showSwipe = settings.showBuffIconSwipe
            else										 
            showSwipe = settings.showBuffSwipe
		end	   
        -- Priorität 2: GCD vs Cooldown (verwende CooldownFlash-Sichtbarkeit)
        elseif parentIcon.CooldownFlash then
            if parentIcon.CooldownFlash:IsShown() then
                showSwipe = settings.showCooldownSwipe
            else
                showSwipe = settings.showGCDSwipe
            end
        -- Fallback: behandle als Cooldown
        else
            showSwipe = settings.showCooldownSwipe
        end

        self:SetDrawSwipe(showSwipe)

        -- Edge-Logik: Buff-Icons verwenden ihre Swipe-Einstellung, Cooldowns verwenden showRechargeEdge
        local showEdge
        if auraActive then
            showEdge = showSwipe  -- Buff-Icons: Edge folgt Swipe-Toggle
        else
            showEdge = settings.showRechargeEdge  -- Cooldowns: separate Einstellung
        end
        self:SetDrawEdge(showEdge)							  
    end)
end

-- Verarbeite alle Icons in einem Viewer
local function ProcessViewer(viewer)
    if not viewer then return end

    local children = {viewer:GetChildren()}

    for _, icon in ipairs(children) do
        if icon.Cooldown then
            HookSetCooldown(icon)
        end
    end
end

-- Wende Einstellungen auf alle CDM-Viewer an
local function ApplyAllSettings()
    local viewers = {
        _G.EssentialCooldownViewer,
        _G.UtilityCooldownViewer,
        _G.BuffIconCooldownViewer,
    }

    for _, viewer in ipairs(viewers) do
        ProcessViewer(viewer)

        -- Hook Layout um neue Icons zu erfassen
        if viewer and viewer.Layout and not viewer._gui_LayoutHooked then
            viewer._gui_LayoutHooked = true
            hooksecurefunc(viewer, "Layout", function()
                C_Timer.After(0.15, function()  -- 150ms Debounce für CPU-Effizienz
                    ProcessViewer(viewer)
                end)
            end)
        end
    end
end

-- Initialisierung beim Addon-Laden
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == "Blizzard_CooldownManager" then
        C_Timer.After(0.5, ApplyAllSettings)
        C_Timer.After(1.5, ApplyAllSettings)  -- Wende erneut an um späte Icons zu erfassen
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, ApplyAllSettings)
        C_Timer.After(1.5, ApplyAllSettings)  -- Wende erneut an um späte Icons zu erfassen
    end
end)

-- Exportiere zu gui-Namespace
gui.CooldownSwipe = {
    Apply = ApplyAllSettings,
    GetSettings = GetSettings,
}

-- Globale Funktion für Config-Panel-Aufruf
_G.GravityUI_RefreshCooldownSwipe = function()
    ApplyAllSettings()
end
