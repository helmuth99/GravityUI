---------------------------------------------------------------------------
-- GravityUI Blizzard Options Integration
-- Registers GravityUI in Settings > AddOns panel
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local gui = GravityUI

local ADDON_DISPLAY_NAME = "Gravity UI"

local function OpenGravityUI()
    if gui.GUI then
        gui.GUI:Toggle()
        return true
    end
    print("|cFF56D1FFGravityUI:|r GUI not loaded yet. Try /gui instead.")
    return false
end

local function CreateSettingsPanel()
    -- Prüfe API-Verfügbarkeit (TWW/Midnight)
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end

    local panel = CreateFrame("Frame", "GravityUI_BlizzardSettingsPanel")
    panel.name = ADDON_DISPLAY_NAME

    -- Titel
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ADDON_DISPLAY_NAME)

    -- Beschreibung
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(520)
    desc:SetJustifyH("LEFT")
    desc:SetText("Open the Gravity UI configuration window.")

    -- Button (verwendet Blizzard-Template für Konsistenz in Blizzard UI)
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(180, 32)
    btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    btn:SetText("Open Gravity UI")
    btn:SetScript("OnClick", OpenGravityUI)

    -- Registriere bei Blizzard Settings
    local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_DISPLAY_NAME)
    Settings.RegisterAddOnCategory(category)
end

-- Erstelle Panel nach kurzer Verzögerung, um sicherzustellen, dass alle Systeme bereit sind
C_Timer.After(0.1, CreateSettingsPanel)
