local addonName, ns = ...

---------------------------------------------------------------------------
-- M+ DUNGEON TELEPORT MODULE
-- Feature: Klick-zum-Teleportieren bei M+-Tab-Dungeon-Icons
-- Nutzt gemeinsame Dungeon-Daten von gui_dungeon_data.lua
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- SETTINGS ACCESS
---------------------------------------------------------------------------

local function IsEnabled()
    local guiCore = _G.GravityUI and _G.GravityUI.guiCore
    local settings = guiCore and guiCore.db and guiCore.db.profile and guiCore.db.profile.general
    return settings and settings.mplusTeleportEnabled ~= false
end

---------------------------------------------------------------------------
-- CLICK-TO-TELEPORT ON M+ TAB ICONS
---------------------------------------------------------------------------

local function CreateSecureOverlay(dungeonIcon)
    if not dungeonIcon or not dungeonIcon.mapID then return end
    if InCombatLockdown() then return end

    -- Hole Teleport-Spell von gemeinsamen Dungeon-Daten
    local spellID = _G.gui_DungeonData and _G.gui_DungeonData.GetTeleportSpellID(dungeonIcon.mapID)
    if not spellID then return end

    -- Prüfe ob Overlay bereits existiert
    if dungeonIcon.guiTeleportOverlay then return end

    -- Erstelle Secure-Button-Overlay
    local overlay = CreateFrame("Button", nil, dungeonIcon, "SecureActionButtonTemplate")
    overlay:SetAllPoints(dungeonIcon)
    overlay:SetFrameLevel(dungeonIcon:GetFrameLevel() + 10)

    overlay:SetAttribute("type", "spell")
    overlay:SetAttribute("spell", spellID)
    overlay:RegisterForClicks("AnyUp", "AnyDown")

    -- Speichere Referenz
    overlay.spellID = spellID
    overlay.dungeonIcon = dungeonIcon

    -- Erstelle Highlight-Textur für Hover-Effekt
    local highlight = overlay:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.3, 1, 0.5, 0.3)  -- Grüner Farbton wenn Spell bekannt
    highlight:Hide()
    overlay.highlight = highlight

    -- Visueller Indikator bei Hover
    overlay:SetScript("OnEnter", function(self)
        -- Zeige Highlight falls Spell bekannt ist
        if IsSpellKnown(spellID) then
            highlight:Show()
        end
        -- Trigger ursprünglichen Tooltip
        if dungeonIcon.OnEnter then
            dungeonIcon:OnEnter()
        end
    end)

    overlay:SetScript("OnLeave", function(self)
        highlight:Hide()
        if dungeonIcon.OnLeave then
            dungeonIcon:OnLeave()
        end
    end)

    dungeonIcon.guiTeleportOverlay = overlay
    return overlay
end

local function HookDungeonIcons()
    if not ChallengesFrame or not ChallengesFrame.DungeonIcons then return end

    for _, dungeonIcon in ipairs(ChallengesFrame.DungeonIcons) do
        if dungeonIcon.mapID then
            CreateSecureOverlay(dungeonIcon)
        end
    end
end

local function OnChallengesFrameUpdate()
    if not IsEnabled() then return end
    -- Verzögere leicht um sicherzustellen dass Icons ihre mapID haben
    C_Timer.After(0.1, HookDungeonIcons)
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

local hooked = false

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_ChallengesUI" then
        if not hooked and ChallengesFrame then
            hooksecurefunc(ChallengesFrame, "Update", OnChallengesFrameUpdate)
            hooked = true
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Behandle Fall wo Blizzard_ChallengesUI bereits geladen ist
if C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
    if not hooked and ChallengesFrame then
        hooksecurefunc(ChallengesFrame, "Update", OnChallengesFrameUpdate)
        hooked = true
    end
end
