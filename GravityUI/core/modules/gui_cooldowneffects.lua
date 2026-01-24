-- cooldowneffects.lua
-- Versteckt aufdringliche Blizzard-Cooldown-Effekte und Glows
-- Features:
-- 1. Versteckt Blizzard Rot/Flash-Effekte (Pandemic, ProcStartFlipbook, Finish)
-- 2. Versteckt ALLE Overlay-Glows (goldene Proc-Glows, Spell-Activation-Alerts, etc.)

local _, gui = ...

-- Hole Einstellungen aus AceDB
local function GetSettings()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    if not guiCore or not guiCore.db or not guiCore.db.profile then
        return { hideEssential = true, hideUtility = true }
    end
    if not guiCore.db.profile.cooldownEffects then
        guiCore.db.profile.cooldownEffects = { hideEssential = true, hideUtility = true }
    end
    return guiCore.db.profile.cooldownEffects
end

-- ======================================================
-- Feature 1: Hide Blizzard red/flash cooldown overlays
-- ======================================================
local function HideCooldownEffects(child)
    if not child then return end
    
    local effectFrames = {"PandemicIcon", "ProcStartFlipbook", "Finish"}
    
    for _, frameName in ipairs(effectFrames) do
        local frame = child[frameName]
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
            
            -- Hooke um versteckt zu halten
            if not frame._GravityUI_NoShow then
                frame._GravityUI_NoShow = true
                
                -- Hooke Show um Anzeige zu verhindern
                if frame.Show then
                    hooksecurefunc(frame, "Show", function(self)
                        self:Hide()
                        self:SetAlpha(0)
                    end)
                end
                
                -- Hooke auch Parent OnShow
                if child.HookScript then
                    child:HookScript("OnShow", function(self)
                        local f = self[frameName]
                        if f then
                            f:Hide()
                            f:SetAlpha(0)
                        end
                    end)
                end
            end
        end
    end
end

-- ======================================================
-- Feature 2: Hide Blizzard Overlay Glows on Cooldown Viewers
-- (Always hide Blizzard's glow - our LibCustomGlow is separate)
-- ======================================================
local function HideBlizzardGlows(button)
    if not button then return end
    
    -- Verstecke IMMER Blizzards Glows - unser Custom-Glow nutzt LibCustomGlow welches separat ist
    -- Rufe nicht ActionButton_HideOverlayGlow auf da es mit Proc-Erkennung interferieren könnte
    
    -- Verstecke das SpellActivationAlert-Overlay (der goldene Swirl-Glow-Frame)
    if button.SpellActivationAlert then
        button.SpellActivationAlert:Hide()
        button.SpellActivationAlert:SetAlpha(0)
    end
    
    -- Verstecke OverlayGlow-Frame falls es existiert (Blizzards Standard)
    if button.OverlayGlow then
        button.OverlayGlow:Hide()
        button.OverlayGlow:SetAlpha(0)
    end
    
    -- Verstecke _ButtonGlow (Blizzards Button-Glow-Frame, NICHT unsere LibCustomGlow-Frames)
    if button._ButtonGlow then
        button._ButtonGlow:Hide()
    end
end

-- Alias für Rückwärtskompatibilität
local HideAllGlows = HideBlizzardGlows

-- ======================================================
-- Apply to Cooldown Viewers - ONLY Essential and Utility
-- ======================================================
local viewers = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer"
    -- BuffIconCooldownViewer ist NICHT enthalten - wir wollen Glows/Effekte auf Buff-Icons
}

local function ProcessViewer(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end
    
    -- Prüfe ob wir Effekte für diesen Viewer verstecken sollen
    local settings = GetSettings()
    local shouldHide = false
    if viewerName == "EssentialCooldownViewer" then
        shouldHide = settings.hideEssential
    elseif viewerName == "UtilityCooldownViewer" then
        shouldHide = settings.hideUtility
    end
    
    if not shouldHide then return end -- Verarbeite nicht falls Effekte angezeigt werden sollen
    
    local function ProcessIcons()
        local children = {viewer:GetChildren()}
        for _, child in ipairs(children) do
            if child:IsShown() then
                -- Verstecke Rot/Flash-Effekte
                HideCooldownEffects(child)
                
                -- Verstecke ALLE Glows (nicht nur Epidemic)
                pcall(HideAllGlows, child)
                
                -- Markiere als verarbeitet (kein OnUpdate-Hook nötig - wir verwalten Glows via hooksecurefunc)
                    child._GravityUI_EffectsHidden = true
            end
        end
    end
    
    -- Verarbeite sofort
    ProcessIcons()
    
    -- Hooke Layout um neu zu verarbeiten wenn Viewer aktualisiert
    if viewer.Layout and not viewer._GravityUI_EffectsHooked then
        viewer._GravityUI_EffectsHooked = true
        hooksecurefunc(viewer, "Layout", function()
            C_Timer.After(0.15, ProcessIcons)  -- 150ms Debounce für CPU-Effizienz
        end)
    end
    
    -- Hooke OnShow
    if not viewer._GravityUI_EffectsShowHooked then
        viewer._GravityUI_EffectsShowHooked = true
        viewer:HookScript("OnShow", function()
            C_Timer.After(0.15, ProcessIcons)  -- 150ms Debounce für CPU-Effizienz
        end)
    end
end

local function ApplyToAllViewers()
    for _, viewerName in ipairs(viewers) do
        ProcessViewer(viewerName)
    end
end

-- ======================================================
-- Hook Blizzard Glows globally on Cooldown Viewers - ONLY Essential/Utility
-- (Custom gui glows are handled separately in customglows.lua using LibCustomGlow)
-- ======================================================
-- Hide any existing Blizzard glows on all viewer icons
local function HideExistingBlizzardGlows()
    local viewerNames = {"EssentialCooldownViewer", "UtilityCooldownViewer"}
    for _, viewerName in ipairs(viewerNames) do
        local viewer = _G[viewerName]
        if viewer then
            local children = {viewer:GetChildren()}
            for _, child in ipairs(children) do
                pcall(HideBlizzardGlows, child)
            end
        end
    end
end

local function HookAllGlows()
    -- Hook the standard ActionButton_ShowOverlayGlow
    -- When Blizzard tries to show a glow, we ALWAYS hide Blizzard's glow
    -- Our custom glow (via LibCustomGlow) is completely separate and won't be affected
    if type(ActionButton_ShowOverlayGlow) == "function" then
        hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)
            -- Only hide glows on Essential/Utility cooldown viewers, NOT BuffIcon
            if button and button:GetParent() then
                local parent = button:GetParent()
                local parentName = parent:GetName()
                if parentName and (
                    parentName:find("EssentialCooldown") or 
                    parentName:find("UtilityCooldown")
                    -- BuffIconCooldown is NOT included - we want glows on buff icons
                ) then
                    -- Hide Blizzard's glow immediately
                    -- customglows.lua runs first (load order) and applies LibCustomGlow
                    -- which is NOT affected by HideBlizzardGlows
                    C_Timer.After(0.01, function()
                        if button then
                            pcall(HideBlizzardGlows, button)
                        end
                    end)
                end
            end
        end)
    end
    
    -- Verstecke auch Glows die möglicherweise bereits angezeigt werden
    HideExistingBlizzardGlows()
end

-- ======================================================
-- Monitor removed - we don't process BuffIconCooldownViewer anymore
-- ======================================================
local function StartMonitoring()
    -- No longer needed - BuffIconCooldownViewer is not processed
end

-- ======================================================
-- Initialize
-- ======================================================
local glowHooksSetup = false

local function EnsureGlowHooks()
    if glowHooksSetup then return end
    glowHooksSetup = true
    HookAllGlows()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == "Blizzard_CooldownManager" then
        EnsureGlowHooks()
        -- Konsolidierter Timer: wende Einstellungen an und verstecke Glows zusammen
        C_Timer.After(0.5, function()
            ApplyToAllViewers()
            HideExistingBlizzardGlows()
        end)
        C_Timer.After(1, HideExistingBlizzardGlows) -- Finale Bereinigung für späte Procs
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            ApplyToAllViewers()
            HideExistingBlizzardGlows()
        end)
    elseif event == "PLAYER_LOGIN" then
        EnsureGlowHooks()
        C_Timer.After(0.5, HideExistingBlizzardGlows)
    end
end)

-- ======================================================
-- Export to gui namespace
-- ======================================================
gui.CooldownEffects = {
    HideCooldownEffects = HideCooldownEffects,
    HideAllGlows = HideAllGlows,
    ApplyToAllViewers = ApplyToAllViewers,
}

-- Globale Funktion für Config-Panel-Aufruf
_G.GravityUI_RefreshCooldownEffects = function()
    ApplyToAllViewers()
end

