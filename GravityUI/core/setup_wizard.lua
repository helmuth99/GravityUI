-- GravityUI - First-Run Setup Wizard
-- Shows a welcome window on the very first WoW session with GravityUI installed.
-- Subsequent logins (and existing users) are detected and the wizard is never shown.
local ADDON_NAME, ns = ...

local GUI = ns.GUI
GUI.Wizard = {}
local Wizard = GUI.Wizard

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------
local WIZARD_W  = 620
local WIZARD_H  = 560
local PAD       = 20
local LOGO_H    = 88
local ROW_H     = 34
local LIST_TOP  = LOGO_H + 95   -- px from wizard top to scrollFrame top

-- ---------------------------------------------------------------------------
-- DETECTION HELPERS
-- ---------------------------------------------------------------------------

--- Returns true if a GravityUI profile already exists in SavedVariables.
local function HasExistingGravityProfile()
    local db = _G.GravityUI_DB
    if not db then return false end
    if db.profileKeys then
        for _, profileName in pairs(db.profileKeys) do
            if type(profileName) == "string" and profileName:find("Gravity") then
                return true
            end
        end
    end
    if db.profiles then
        for name in pairs(db.profiles) do
            if type(name) == "string" and name:find("Gravity") then
                return true
            end
        end
    end
    return false
end

--- Marks setup as done so the wizard never auto-appears again.
local function MarkSetupDone()
    local aceDB = ns.GetAceDB()
    if aceDB and aceDB.global then
        if not aceDB.global.installer then aceDB.global.installer = {} end
        aceDB.global.installer.setupDone = true
    end
end

--- Returns true if the wizard should appear this session.
local function ShouldShowWizard()
    local aceDB = ns.GetAceDB()
    if not aceDB then return false end
    local g = aceDB.global
    if not g then return false end
    if g.installer and g.installer.setupDone  then return false end
    if g.installer and g.installer.setupDate  then MarkSetupDone(); return false end
    if HasExistingGravityProfile()            then MarkSetupDone(); return false end
    return true
end

-- ---------------------------------------------------------------------------
-- BACKDROP HELPER  (mirrors framework.lua's private CreateBackdrop)
-- ---------------------------------------------------------------------------
local function ApplyBackdrop(frame, bgColor, borderColor)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = nil,
        edgeSize = 0,
    })
    frame:SetBackdropColor(unpack(bgColor or {0, 0, 0, 0.92}))
    if borderColor then
        if not frame._wizBorder then
            frame._wizBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            frame._wizBorder:SetPoint("TOPLEFT",     -1,  1)
            frame._wizBorder:SetPoint("BOTTOMRIGHT",  1, -1)
            frame._wizBorder:SetFrameLevel(frame:GetFrameLevel())
            frame._wizBorder:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
        end
        frame._wizBorder:SetBackdropBorderColor(unpack(borderColor))
    end
end

-- ---------------------------------------------------------------------------
-- WIZARD FRAME – singleton, built once, populated on every Show()
-- ---------------------------------------------------------------------------
local wizardFrame = nil

local function BuildWizard()
    if wizardFrame then return wizardFrame end

    -- ── Main Frame ─────────────────────────────────────────────────────────
    wizardFrame = CreateFrame("Frame", "GravityUI_SetupWizard", UIParent, "BackdropTemplate")
    wizardFrame:SetSize(WIZARD_W, WIZARD_H)
    wizardFrame:SetPoint("CENTER")
    wizardFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    wizardFrame:SetFrameLevel(900)
    wizardFrame:EnableMouse(true)
    wizardFrame:SetMovable(true)
    wizardFrame:RegisterForDrag("LeftButton")
    wizardFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    wizardFrame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    wizardFrame:SetClampedToScreen(true)
    wizardFrame:Hide()

    ApplyBackdrop(wizardFrame, {0.04, 0.04, 0.06, 0.97}, {0, 0.6, 1, 0.8})

    -- Top accent stripe
    local topStrip = wizardFrame:CreateTexture(nil, "BORDER")
    topStrip:SetPoint("TOPLEFT",  wizardFrame, "TOPLEFT",   1, -1)
    topStrip:SetPoint("TOPRIGHT", wizardFrame, "TOPRIGHT", -1, -1)
    topStrip:SetHeight(2)
    topStrip:SetColorTexture(0, 0.6, 1, 1)

    -- ── Header Zone ───────────────────────────────────────────────────────
    local header = CreateFrame("Frame", nil, wizardFrame, "BackdropTemplate")
    header:SetPoint("TOPLEFT",  wizardFrame, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", wizardFrame, "TOPRIGHT", 0, 0)
    header:SetHeight(LOGO_H)
    ApplyBackdrop(header, {0, 0.04, 0.09, 0.9})

    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(56, 56)
    logo:SetPoint("LEFT", header, "LEFT", PAD, 0)
    logo:SetTexture(ns.ICON_PATH)

    local titleFS = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFS:SetFont(ns.FONT_PATH, 22, "OUTLINE")
    titleFS:SetTextColor(0.3, 0.75, 1, 1)
    titleFS:SetText("Welcome to GravityUI")
    titleFS:SetPoint("BOTTOMLEFT", logo, "BOTTOMRIGHT", 12, 18)

    local subFS = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subFS:SetFont(ns.FONT_PATH, 12, "")
    subFS:SetTextColor(0.55, 0.65, 0.75, 1)
    subFS:SetText("Configure your addons and get started in seconds.")
    subFS:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 0, -4)

    -- Separator below header
    local sep = wizardFrame:CreateTexture(nil, "BORDER")
    sep:SetPoint("TOPLEFT",  wizardFrame, "TOPLEFT",  PAD, -(LOGO_H + 1))
    sep:SetPoint("TOPRIGHT", wizardFrame, "TOPRIGHT", -PAD, -(LOGO_H + 1))
    sep:SetHeight(1)
    sep:SetColorTexture(0, 0.6, 1, 0.2)

    -- ── Profile selector: label + dropdown stacked ─────────────────────────
    -- "GravityUI Profile:" label
    local profLabel = wizardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profLabel:SetFont(ns.FONT_PATH, 12, "")
    profLabel:SetTextColor(0.55, 0.65, 0.75, 1)
    profLabel:SetText("GravityUI Profile")
    profLabel:SetPoint("TOPLEFT", wizardFrame, "TOPLEFT", PAD, -(LOGO_H + 14))
    wizardFrame._profLabel = profLabel

    -- Dropdown sits below the label (framework widget: 18px label zone + 24px button)
    -- We park it here; the label zone overlaps the profLabel text, but since we set
    -- an empty label string the top 18px are transparent, so it looks stacked cleanly.
    wizardFrame._profileDropdown = nil  -- created fresh in Show()

    -- "Addon Profiles to Install" section label
    local listHeader = wizardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listHeader:SetFont(ns.FONT_PATH, 11, "")
    listHeader:SetTextColor(0.45, 0.55, 0.65, 1)
    listHeader:SetText("Addon Profiles to Install")
    listHeader:SetPoint("TOPLEFT", wizardFrame, "TOPLEFT", PAD, -(LOGO_H + 72))

    local listRule = wizardFrame:CreateTexture(nil, "BACKGROUND")
    listRule:SetPoint("TOPLEFT",  wizardFrame, "TOPLEFT",  PAD,  -(LOGO_H + 87))
    listRule:SetPoint("TOPRIGHT", wizardFrame, "TOPRIGHT", -PAD, -(LOGO_H + 87))
    listRule:SetHeight(1)
    listRule:SetColorTexture(0.12, 0.14, 0.18, 1)

    -- ── ScrollFrame ────────────────────────────────────────────────────────
    local scrollFrame = CreateFrame("ScrollFrame", nil, wizardFrame)
    scrollFrame:SetPoint("TOPLEFT",     wizardFrame, "TOPLEFT",      PAD,        -LIST_TOP)
    scrollFrame:SetPoint("BOTTOMRIGHT", wizardFrame, "BOTTOMRIGHT", -(PAD + 14),  60)
    scrollFrame:EnableMouseWheel(true)

    local listContainer = CreateFrame("Frame", nil, scrollFrame)
    listContainer:SetWidth(WIZARD_W - PAD * 2 - 14)
    listContainer:SetHeight(1)
    scrollFrame:SetScrollChild(listContainer)

    -- ── Scrollbar track ────────────────────────────────────────────────────
    local sbTrack = CreateFrame("Frame", nil, wizardFrame, "BackdropTemplate")
    sbTrack:SetPoint("TOPRIGHT",    wizardFrame, "TOPRIGHT",    -(PAD - 6), -LIST_TOP)
    sbTrack:SetPoint("BOTTOMRIGHT", wizardFrame, "BOTTOMRIGHT", -(PAD - 6),  60)
    sbTrack:SetWidth(8)
    ApplyBackdrop(sbTrack, {0.06, 0.07, 0.10, 0.9})

    local sbThumb = CreateFrame("Frame", nil, sbTrack, "BackdropTemplate")
    sbThumb:SetWidth(8)
    sbThumb:SetHeight(40)
    sbThumb:SetPoint("TOP", sbTrack, "TOP", 0, 0)
    ApplyBackdrop(sbThumb, {0, 0.55, 1, 0.65}, {0, 0.6, 1, 0.9})
    sbThumb:Hide()

    local function UpdateScrollbar(sf)
        local max = sf:GetVerticalScrollRange()
        if not max or max <= 0 then
            sbThumb:Hide()
            return
        end
        local viewH  = sf:GetHeight()
        local totalH = viewH + max
        local trackH = sbTrack:GetHeight()
        local thumbH = math.max(24, trackH * viewH / totalH)
        local ratio  = sf:GetVerticalScroll() / max
        sbThumb:SetHeight(thumbH)
        sbThumb:ClearAllPoints()
        sbThumb:SetPoint("TOP", sbTrack, "TOP", 0, -ratio * (trackH - thumbH))
        sbThumb:Show()
    end
    wizardFrame._UpdateScrollbar = UpdateScrollbar

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local new = cur - delta * ROW_H * 3
        if new < 0 then new = 0 end
        local max = self:GetVerticalScrollRange()
        if new > max then new = max end
        self:SetVerticalScroll(new)
        UpdateScrollbar(self)
    end)

    scrollFrame:SetScript("OnVerticalScroll", function(self)
        UpdateScrollbar(self)
    end)

    wizardFrame._scrollFrame   = scrollFrame
    wizardFrame._listContainer = listContainer

    -- ── EllesmereUI not-loaded warning ─────────────────────────────────────
    local euiWarn = wizardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    euiWarn:SetFont(ns.FONT_PATH, 11, "")
    euiWarn:SetTextColor(1, 0.4, 0.35, 1)
    euiWarn:SetText("|cFFFF5544[!] EllesmereUI is not installed or loaded. Install it before continuing.|r")
    euiWarn:SetPoint("BOTTOMLEFT", wizardFrame, "BOTTOMLEFT", PAD, 56)
    euiWarn:SetWidth(WIZARD_W - PAD * 2 - 200)
    euiWarn:SetJustifyH("LEFT")
    euiWarn:Hide()
    wizardFrame._euiWarn = euiWarn

    -- ── Footer Buttons ─────────────────────────────────────────────────────
    local skipBtn = GUI:CreateButton(wizardFrame, "Skip Installation", 160, 34)
    skipBtn:SetPoint("BOTTOMLEFT", wizardFrame, "BOTTOMLEFT", PAD, PAD)
    skipBtn.text:SetTextColor(0.5, 0.55, 0.6, 1)
    wizardFrame._skipBtn = skipBtn

    local installBtn = GUI:CreateButton(wizardFrame, "Install GravityUI", 190, 34)
    installBtn:SetPoint("BOTTOMRIGHT", wizardFrame, "BOTTOMRIGHT", -PAD, PAD)
    installBtn:SetBackdropColor(0, 0.3, 0.65, 1)
    installBtn:SetBackdropBorderColor(0, 0.6, 1, 1)
    installBtn.text:SetTextColor(1, 1, 1, 1)
    installBtn.text:SetFont(ns.FONT_PATH, 13, "OUTLINE")
    wizardFrame._installBtn = installBtn

    -- ESC to skip
    wizardFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            MarkSetupDone()
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    return wizardFrame
end

-- ---------------------------------------------------------------------------
-- ROW POOL  (lightweight frame reuse for the addon list)
-- ---------------------------------------------------------------------------
local rowPool = {}

local function ClearRows()
    for _, r in ipairs(rowPool) do r:Hide() end
end

--- Builds the addon-list rows inside listContainer.
--- selectionState is a plain table { addonName = bool } shared with Show().
local function PopulateAddonRows(listContainer, selectionState)
    ClearRows()

    local registry = GUI.Installer and GUI.Installer.registry
    if not registry then return end

    -- Split registry: non-Optional = Core/Required, rest = Optional.
    -- WIZARD_HIDDEN: addons hidden from the wizard (still installable via /gui -> Installer).
    local WIZARD_HIDDEN = {
        ["Dominos"]       = true,
        ["Details"]       = true,
    }

    local important, optional = {}, {}
    for _, addon in ipairs(registry) do
        if WIZARD_HIDDEN[addon.name] then
            -- skip: available under /gui -> Installer
        elseif addon.category == "Optional" then
            table.insert(optional,  addon)
        else
            table.insert(important, addon)
        end
    end

    local listWidth = WIZARD_W - PAD * 2 - 14  -- matches SetWidth() on scroll child
    local yOffset   = 0    -- running pixel distance from listContainer top
    local rowIndex  = 0    -- pool index for frame reuse

    -- Per-group description texts.
    local GROUP_INFO = {
        Core     = "These addons form the core of GravityUI. Their profiles are configured automatically. All settings can be fine-tuned at any time via /gui.",
        Optional = "The following addons are supported by GravityUI and come with a ready-made profile. Each profile can be customised to your liking via /gui.",
    }

    --- Renders one section: header, info text, addon rows.
    local function RenderGroup(groupLabel, groupKey, list)
        if #list == 0 then return end

        -- ── Section header ───────────────────────────────────────────────
        local hdrKey = "hdr_" .. groupKey
        if not listContainer[hdrKey] then
            listContainer[hdrKey] = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            listContainer[hdrKey]:SetFont(ns.FONT_PATH, 10, "OUTLINE")
            listContainer[hdrKey]:SetTextColor(0.45, 0.55, 0.65, 1)
        end
        listContainer[hdrKey]:SetText(groupLabel)
        listContainer[hdrKey]:ClearAllPoints()
        listContainer[hdrKey]:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 6, -yOffset - 2)
        listContainer[hdrKey]:Show()
        yOffset = yOffset + 16

        -- ── Info text ────────────────────────────────────────────────────
        local infoKey = "info_" .. groupKey
        if not listContainer[infoKey] then
            listContainer[infoKey] = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            listContainer[infoKey]:SetFont(ns.FONT_PATH, 10, "")
            listContainer[infoKey]:SetTextColor(0.38, 0.47, 0.56, 1)
            listContainer[infoKey]:SetWidth(listWidth - 12)
            listContainer[infoKey]:SetJustifyH("LEFT")
        end
        listContainer[infoKey]:SetText(GROUP_INFO[groupKey] or "")
        listContainer[infoKey]:ClearAllPoints()
        listContainer[infoKey]:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 6, -yOffset)
        listContainer[infoKey]:Show()
        yOffset = yOffset + 30  -- ~2 lines at 10pt
        yOffset = yOffset + 6   -- gap before rows

        -- ── Addon rows ───────────────────────────────────────────────────
        for _, addon in ipairs(list) do
            rowIndex = rowIndex + 1

            local row = rowPool[rowIndex]
            if not row then
                row = CreateFrame("Frame", nil, listContainer, "BackdropTemplate")
                rowPool[rowIndex] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -yOffset)
            row:SetSize(listWidth, ROW_H - 2)
            ApplyBackdrop(row, (rowIndex % 2 == 0)
                and {0.08, 0.09, 0.12, 0.55}
                or  {0.05, 0.06, 0.08, 0.3})
            row:Show()

            local isRequired = (addon.category ~= "Optional")
            local isLoaded   = addon.Check and addon.Check()

            if selectionState[addon.name] == nil then
                selectionState[addon.name] = (isLoaded == true) and true or false
            end
            if not isLoaded  then selectionState[addon.name] = false end
            if isRequired    then selectionState[addon.name] = true  end

            if not row._cbState then row._cbState = {} end
            row._cbState.checked = selectionState[addon.name]

            local addonNameRef = addon.name

            local function OnChange(val)
                if isRequired then
                    selectionState[addonNameRef] = true
                    row._cb:SetValue(true, true)
                    if row._nameFS then row._nameFS:SetTextColor(1, 1, 1, 1) end
                    return
                end
                selectionState[addonNameRef] = val and true or false
                if row._nameFS then
                    if selectionState[addonNameRef] then
                        row._nameFS:SetTextColor(0.85, 0.9, 0.95, 1)
                    else
                        row._nameFS:SetTextColor(0.4, 0.4, 0.45, 1)
                    end
                end
            end

            if not row._cb then
                row._cb = GUI:CreateCheckbox(row, "", "checked", row._cbState, OnChange)
            else
                row._cbState.checked = selectionState[addon.name]
                row._cb:SetValue(selectionState[addon.name], true)
            end
            row._cb:ClearAllPoints()
            row._cb:SetPoint("LEFT", row, "LEFT", 6, 0)

            if isRequired or not isLoaded then
                row._cb:Disable()
            else
                row._cb:Enable()
            end
            if isRequired then
                row._cb:SetValue(true, true)
            end

            if not row._nameFS then
                row._nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row._nameFS:SetFont(ns.FONT_PATH, 12, "")
                row._nameFS:SetPoint("LEFT", row._cb, "RIGHT", 6, 0)
            end
            row._nameFS:SetText(addon.label or addon.name)

            if not isLoaded then
                row._nameFS:SetTextColor(0.38, 0.38, 0.42, 1)
            elseif selectionState[addon.name] then
                row._nameFS:SetTextColor(0.88, 0.92, 0.96, 1)
            else
                row._nameFS:SetTextColor(0.38, 0.38, 0.42, 1)
            end

            if not row._badgeFS then
                row._badgeFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row._badgeFS:SetFont(ns.FONT_PATH, 10, "")
                row._badgeFS:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            end

            if isRequired then
                row._badgeFS:SetText("|cFFFFCC00Required|r")
            elseif not isLoaded then
                row._badgeFS:SetText("|cFF888888Not Loaded|r")
            elseif addon.category == "Optional" then
                row._badgeFS:SetText("|cFF5577AAOptional|r")
            else
                row._badgeFS:SetText("")
            end

            yOffset = yOffset + ROW_H
        end -- addon loop

        yOffset = yOffset + 10  -- gap between groups
    end -- RenderGroup

    RenderGroup("Core & Required Addons", "Core",     important)
    RenderGroup("Optional Addons",        "Optional", optional)

    -- ── Footer hint ──────────────────────────────────────────────────────
    -- Shown after the Optional section, pointing users to the full installer.
    local footerKey = "footer_hint"
    if not listContainer[footerKey] then
        listContainer[footerKey] = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        listContainer[footerKey]:SetFont(ns.FONT_PATH, 10, "")
        listContainer[footerKey]:SetWidth(listWidth - 12)
        listContainer[footerKey]:SetJustifyH("LEFT")
    end
    listContainer[footerKey]:SetText("|cFF556677Profiles for additional addons can be found and installed under |r|cFF00BFFFAddon Settings -> Installer|r|cFF556677 (/gui).|r")
    listContainer[footerKey]:ClearAllPoints()
    listContainer[footerKey]:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 6, -yOffset)
    listContainer[footerKey]:Show()
    yOffset = yOffset + 24

    -- Resize scroll child to fit all content
    listContainer:SetHeight(yOffset + 4)
end

-- ---------------------------------------------------------------------------
-- PUBLIC: Wizard:Show() / Wizard:Hide()
-- ---------------------------------------------------------------------------
function Wizard:Show()
    local f = BuildWizard()

    -- ── Determine source profile ──────────────────────────────────────────
    local sources = GUI.Installer and GUI.Installer:GetSourceProfiles() or {}
    if #sources == 0 then table.insert(sources, "GravityUI") end

    local selectedSource = sources[1]
    for _, v in ipairs(sources) do
        if v == "Cronix" then selectedSource = v; break end
    end

    local aceDB = ns.GetAceDB()
    if aceDB and aceDB.global and aceDB.global.installer then
        local saved = aceDB.global.installer.sourceProfile
        if saved then
            for _, v in ipairs(sources) do
                if v == saved then selectedSource = v; break end
            end
        end
    end

    -- ── (Re)build the profile dropdown ───────────────────────────────────
    if f._profileDropdown then
        f._profileDropdown:Hide()
        f._profileDropdown = nil
    end

    local srcWrapper = { selected = selectedSource }
    local items = {}
    for _, v in ipairs(sources) do table.insert(items, { text = v, value = v }) end

    local dd = GUI:CreateDropdown(
        f,
        "",         -- empty label; profLabel above acts as our heading
        items,
        "selected",
        srcWrapper,
        function(val) selectedSource = val end
    )
    -- Park the framework container so its empty 18px label zone sits behind profLabel,
    -- making the actual button appear directly below the label text.
    dd:SetPoint("TOPLEFT", f._profLabel, "BOTTOMLEFT", 0, -2)
    dd:SetSize(220, 40)
    if dd.label then dd.label:SetAlpha(0) end
    f._profileDropdown = dd

    -- ── Selection state (per-session) ─────────────────────────────────────
    f._selectionState = f._selectionState or {}
    if GUI.Installer then
        for _, addon in ipairs(GUI.Installer.registry) do
            if not addon.Check() then
                f._selectionState[addon.name] = false
            end
        end
    end

    -- ── Populate addon rows ───────────────────────────────────────────────
    PopulateAddonRows(f._listContainer, f._selectionState)

    -- Update scrollbar after content is laid out (1-frame delay for GetHeight)
    C_Timer.After(0.05, function()
        if f._UpdateScrollbar and f._scrollFrame and f:IsShown() then
            f._UpdateScrollbar(f._scrollFrame)
        end
    end)

    -- ── EllesmereUI readiness check ───────────────────────────────────────
    local euiLoaded = C_AddOns.IsAddOnLoaded("EllesmereUI") and _G.EllesmereUI ~= nil

    if euiLoaded then
        f._euiWarn:Hide()
        f._installBtn:SetAlpha(1)
        f._installBtn:EnableMouse(true)
    else
        f._euiWarn:Show()
        f._installBtn:SetAlpha(0.35)
        f._installBtn:EnableMouse(false)
    end

    -- ── Button scripts ─────────────────────────────────────────────────────
    f._skipBtn:SetScript("OnClick", function()
        MarkSetupDone()
        f:Hide()
    end)

    f._installBtn:SetScript("OnClick", function()
        if not (C_AddOns.IsAddOnLoaded("EllesmereUI") and _G.EllesmereUI) then return end

        -- Build allowList from selectionState.
        -- Required addons are already forced true in selectionState by PopulateAddonRows.
        local allowList = {}
        for addonName, checked in pairs(f._selectionState) do
            if checked then allowList[addonName] = true end
        end

        -- Persist selected source profile
        local aceDB2 = ns.GetAceDB()
        if aceDB2 and aceDB2.global then
            if not aceDB2.global.installer then aceDB2.global.installer = {} end
            aceDB2.global.installer.sourceProfile = selectedSource
        end

        MarkSetupDone()
        f:Hide()

        if GUI.Installer and GUI.Installer.Install then
            GUI.Installer:Install("GravityUI", selectedSource, allowList)
        end
    end)

    f:Show()
    f:EnableKeyboard(true)
end

function Wizard:Hide()
    if wizardFrame then wizardFrame:Hide() end
end

-- ---------------------------------------------------------------------------
-- TRIGGER: fires on PLAYER_LOGIN, once per session
-- ---------------------------------------------------------------------------
do
    local _wizTrigger = CreateFrame("Frame")
    _wizTrigger:RegisterEvent("PLAYER_LOGIN")
    _wizTrigger:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        C_Timer.After(0.6, function()
            if ShouldShowWizard() then
                GUI.Wizard:Show()
            end
        end)
    end)
end
