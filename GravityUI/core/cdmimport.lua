local ADDON_NAME, ns = ...

---------------------------------------------------------------------------
-- GravityUI CDM Import (/guicdm)
--
-- Opens a frame listing all class/spec combinations with an [Import] button
-- each. Clicking Import loads the Blizzard CooldownViewer layout for that
-- spec using the taint-safe CreateLayoutsFromSerializedData path (identical
-- to atrocityUI v1.5.4 / Wago's own flow).
--
-- TAINT DOCTRINE (per atrocityUI BugSack analysis):
--   Imported layout tables are TAINTED until a /reload launders them via the
--   C storage read on next login. All mutations are wrapped in
--   LockNotifications/UnlockNotifications so no listener fires inside our
--   tainted execution. A [Reload] button is offered after every import.
---------------------------------------------------------------------------

local CDM = {}
ns.CDM = CDM

local frame -- main window, created on first /guicdm

---------------------------------------------------------------------------
-- ADDON LOADER
---------------------------------------------------------------------------
local function EnsureCooldownViewerLoaded()
    if CooldownViewerSettings and CooldownViewerUtil then return true end
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
    end
    return (CooldownViewerSettings and CooldownViewerUtil) and true or false
end

local function GetLayoutManager()
    if not EnsureCooldownViewerLoaded() then return nil end
    if not CooldownViewerSettings or not CooldownViewerSettings.GetLayoutManager then return nil end
    return CooldownViewerSettings:GetLayoutManager()
end

local function GetCurrentSpecTag()
    if not CooldownViewerUtil or not CooldownViewerUtil.GetCurrentClassAndSpecTag then return nil end
    return tonumber(CooldownViewerUtil.GetCurrentClassAndSpecTag())
end

---------------------------------------------------------------------------
-- TAINT-SAFE MUTATION WRAPPER
-- Mirrors Blizzard's DeserializeLayouts pattern exactly.
---------------------------------------------------------------------------
local function WithNotificationsSuppressed(fn)
    local lm = GetLayoutManager()
    if not lm or not lm.LockNotifications or not lm.UnlockNotifications then
        fn()
        return
    end
    lm:LockNotifications()
    local ok, err = pcall(fn)
    lm.needsNotificationAfterUnlock = false
    lm:UnlockNotifications()
    if not ok then geterrorhandler()(err) end
end

---------------------------------------------------------------------------
-- LAYOUT HELPERS
---------------------------------------------------------------------------
local function GetLayoutIDByName(layoutName, specTag)
    local lm = GetLayoutManager()
    if not lm then return nil end
    local _, layouts = lm:EnumerateLayouts()
    for layoutID, layout in pairs(layouts) do
        if layout and layout.layoutName == layoutName
            and (not specTag or tostring(layout.classAndSpecTag) == tostring(specTag)) then
            return layoutID
        end
    end
end

local function RemoveLayoutByName(layoutName, specTag)
    local lm = GetLayoutManager()
    if not lm then return end
    local id = GetLayoutIDByName(layoutName, specTag)
    if id then lm:RemoveLayout(id) end
end

local function DismissBlockedActionPopup()
    local btnText = _G.StaticPopup1Button2Text
    if btnText and btnText.GetText and btnText:GetText() == (_G.IGNORE or "Ignore") then
        local btn = _G.StaticPopup1Button2
        if btn and btn.Click then btn:Click() end
    end
end

---------------------------------------------------------------------------
-- IMPORT CORE
-- Returns: true on success, nil on failure, "maxed" if layout cap reached.
---------------------------------------------------------------------------
local function ImportSpec(tag)
    local data = ns.CDMData and ns.CDMData[tag]
    if not data or not data.str or data.str == "" then
        return nil, "nodata"
    end

    local profileKey = "GravityUI - " .. data.name
    local profileStr = data.str
    local currentTag = GetCurrentSpecTag()
    local importTag  = tonumber(tag)
    local result, failReason

    WithNotificationsSuppressed(function()
        local lm = GetLayoutManager()
        if not lm then failReason = "nolm"; return end

        -- Remove any existing layout with our target name (update scenario)
        -- Must search by BOTH "GravityUI - X" AND "atrocityUI - X" since a
        -- previous import may have been named either way.
        local function PurgeByName(name)
            local _, layouts = lm:EnumerateLayouts()
            local toRemove = {}
            for layoutID, layout in pairs(layouts or {}) do
                local lName = layout and (layout.layoutName or layout.name)
                if lName and (lName == name or lName:find(name, 1, true)) then
                    table.insert(toRemove, layoutID)
                end
            end
            for _, id in ipairs(toRemove) do lm:RemoveLayout(id) end
        end
        PurgeByName(profileKey)
        PurgeByName("atrocityUI - " .. data.name)
        PurgeByName("Naowh - Demon Hunter " .. data.name)
        PurgeByName("Naowh - " .. data.name)

        -- Handle layout cap
        if lm.AreLayoutsFullyMaxed and lm:AreLayoutsFullyMaxed() then
            local freedID
            local _, layouts = lm:EnumerateLayouts()
            for layoutID, layout in pairs(layouts or {}) do
                if layout and layout.layoutName == profileKey then
                    freedID = layoutID; break
                end
            end
            if not freedID and lm.GetActiveLayoutID then
                freedID = lm:GetActiveLayoutID()
            end
            if freedID then lm:RemoveLayout(freedID) end
        end

        local layoutIDs = lm:CreateLayoutsFromSerializedData(profileStr)
        if not layoutIDs or not layoutIDs[1] then
            failReason = lm.AreLayoutsFullyMaxed and lm:AreLayoutsFullyMaxed() and "maxed" or "failed"
            return
        end

        local importedID = layoutIDs[1]

        -- Rename: ensure layout is strictly named "GravityUI - <Spec>"
        local _, layouts = lm:EnumerateLayouts()
        local importedLayout = layouts and layouts[importedID]
        if importedLayout then
            importedLayout.layoutName = profileKey
            importedLayout.name = profileKey
            if importedLayout.coloredName then
                importedLayout.coloredName = (data.color or "|cffffffff") .. profileKey .. "|r"
            end
        end

        local isCurrentSpec = importTag and currentTag and importTag == currentTag

        if isCurrentSpec then
            lm:SetActiveLayoutByID(importedID)
            DismissBlockedActionPopup()
        elseif lm.SetPreviouslyActiveLayoutByName then
            lm:SetPreviouslyActiveLayoutByName(profileKey, importTag)
        end

        lm:SaveLayouts()
        result = true
    end)

    return result, failReason
end

---------------------------------------------------------------------------
-- UI CONSTANTS
---------------------------------------------------------------------------
local FRAME_W   = 380
local ROW_H     = 26
local PAD       = 10
local HDR_H     = 22
local BTN_W     = 80
local BTN_H     = 20
local FONT      = "Fonts\\FRIZQT__.TTF"

---------------------------------------------------------------------------
-- UI BUILDER
---------------------------------------------------------------------------
local function BuildFrame()
    if frame then return end

    -- Main window
    frame = CreateFrame("Frame", "GravityUI_CDMFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_W, 100) -- height set later
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:Hide()

    -- Backdrop
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.06, 0.06, 0.09, 0.96)
    frame:SetBackdropBorderColor(0.25, 0.25, 0.35, 1)

    -- Titlebar
    local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titleBar:SetHeight(28)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    titleBar:SetBackdropColor(0.12, 0.12, 0.20, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 11, "OUTLINE")
    title:SetText("|cff7ec8e3GravityUI|r  —  Cooldown Manager Import")
    title:SetPoint("LEFT", titleBar, "LEFT", PAD, 0)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -2)
    closeBtn:SetText("×")
    closeBtn:GetFontString():SetFont(FONT, 16, "OUTLINE")
    closeBtn:GetFontString():SetTextColor(0.7, 0.7, 0.8)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Hint label
    local hint = frame:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 9, "OUTLINE")
    hint:SetTextColor(1, 0.85, 0.3)
    hint:SetText("|cffffcc00! After import a /reload is recommended for the layout to apply cleanly.|r")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -36)
    hint:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    hint:SetJustifyH("LEFT")

    -- Reload button (initially hidden)
    frame.reloadBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    frame.reloadBtn:SetSize(90, 20)
    frame.reloadBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -30)
    frame.reloadBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame.reloadBtn:SetBackdropColor(0.2, 0.5, 0.2, 0.9)
    frame.reloadBtn:SetBackdropBorderColor(0.3, 0.7, 0.3, 1)
    local reloadText = frame.reloadBtn:CreateFontString(nil, "OVERLAY")
    reloadText:SetFont(FONT, 10, "OUTLINE")
    reloadText:SetText("Reload Now")
    reloadText:SetPoint("CENTER")
    frame.reloadBtn:SetScript("OnClick", function() ReloadUI() end)
    frame.reloadBtn:Hide()

    -- Scroll child to hold all rows
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD,    -60)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD-18, PAD)
    frame.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(FRAME_W - PAD*2 - 20)
    scroll:SetScrollChild(content)
    frame.content = content

    -- Build rows
    local yOff = 0
    local currentSpecTag = GetCurrentSpecTag()

    for _, classInfo in ipairs(ns.CDMClassOrder) do
        -- Class header
        local hdr = content:CreateFontString(nil, "OVERLAY")
        hdr:SetFont(FONT, 10, "OUTLINE")
        hdr:SetText(classInfo.color .. classInfo.label .. "|r")
        hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOff)
        hdr:SetJustifyH("LEFT")
        yOff = yOff + HDR_H

        for _, tag in ipairs(classInfo.tags) do
            local specData = ns.CDMData[tag]
            if specData then
                local isCurrentSpec = (currentSpecTag == tag)
                local rowY = -yOff

                -- Spec icon
                local icon = content:CreateTexture(nil, "ARTWORK")
                icon:SetSize(ROW_H - 4, ROW_H - 4)
                icon:SetTexture(specData.icon)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                icon:SetPoint("TOPLEFT", content, "TOPLEFT", 4, rowY - 2)

                -- Spec name label
                local label = content:CreateFontString(nil, "OVERLAY")
                label:SetFont(FONT, 10, isCurrentSpec and "OUTLINE" or "")
                if isCurrentSpec then
                    label:SetText("|cffffd700>> " .. specData.name .. " (current)|r")
                else
                    label:SetText("|cffcccccc" .. specData.name .. "|r")
                end
                label:SetPoint("TOPLEFT", content, "TOPLEFT", ROW_H + 8, rowY)
                label:SetJustifyH("LEFT")

                -- Import button
                local btn = CreateFrame("Button", nil, content, "BackdropTemplate")
                btn:SetSize(BTN_W, BTN_H)
                btn:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, rowY - 3)
                btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
                btn:SetBackdropColor(0.10, 0.18, 0.30, 0.9)
                btn:SetBackdropBorderColor(0.25, 0.45, 0.70, 1)

                local btnLabel = btn:CreateFontString(nil, "OVERLAY")
                btnLabel:SetFont(FONT, 9, "OUTLINE")
                btnLabel:SetText("Import")
                btnLabel:SetPoint("CENTER")

                btn:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.15, 0.25, 0.45, 1)
                end)
                btn:SetScript("OnLeave", function(self)
                    if not self.imported then
                        self:SetBackdropColor(0.10, 0.18, 0.30, 0.9)
                    end
                end)

                local capturedTag   = tag
                local capturedSpec  = specData
                local capturedLabel = btnLabel
                local capturedBtn   = btn

                btn:SetScript("OnClick", function(self)
                    local ok, fail = ImportSpec(capturedTag)
                    if ok then
                        self.imported = true
                        self:SetBackdropColor(0.05, 0.35, 0.10, 1)
                        self:SetBackdropBorderColor(0.1, 0.6, 0.1, 1)
                        capturedLabel:SetText("Done")
                        frame.reloadBtn:Show()
                        ns.Print("Imported: GravityUI - " .. capturedSpec.name ..
                            (GetCurrentSpecTag() == capturedTag and " (active)" or " (applies on spec switch)"))
                    elseif fail == "maxed" then
                        ns.Print("|cffff4040CDM layout limit reached. Delete a layout in CDM settings first.|r")
                    elseif fail == "nolm" or fail == "failed" then
                        ns.Print("|cffff4040Failed to import GravityUI - " .. capturedSpec.name .. ". Is Blizzard_CooldownViewer loaded?|r")
                    else
                        ns.Print("|cffff4040No CDM data found for " .. capturedSpec.name .. ".|r")
                    end
                end)

                yOff = yOff + ROW_H
            end
        end

        yOff = yOff + 4 -- spacing between classes
    end

    content:SetHeight(yOff + PAD)

    -- Resize frame to fit (capped at 80% screen height)
    local maxH = math.floor(GetScreenHeight() * 0.80)
    local targetH = math.min(yOff + 60 + PAD, maxH)
    frame:SetHeight(targetH)
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
function CDM.Toggle()
    if not ns.CDMData then
        ns.Print("|cffff4040CDM data not loaded.|r")
        return
    end
    if not frame then BuildFrame() end

    if frame:IsShown() then
        frame:Hide()
    else
        -- Refresh current-spec highlight on every open
        frame:Hide()
        frame = nil
        BuildFrame()
        frame:Show()
    end
end

---------------------------------------------------------------------------
-- SLASH COMMAND
---------------------------------------------------------------------------
SLASH_GUICDM1 = "/guicdm"
SlashCmdList["GUICDM"] = function()
    CDM.Toggle()
end

---------------------------------------------------------------------------
-- HOOK: Inject "GUI Profiles" button into Blizzard CooldownViewerSettings
--
-- Scans CooldownViewerSettings children for the Revert button (identified
-- by its text containing "Revert"), then anchors our button to its left.
-- Fires on ADDON_LOADED for Blizzard_CooldownViewer, and also immediately
-- if the frame is already present (loaded before GravityUI).
---------------------------------------------------------------------------
local cdvButtonInjected = false

local function FindRevertButton(parent)
    if not parent then return nil end
    for _, child in ipairs({ parent:GetChildren() }) do
        -- Check this child
        if child.GetText then
            local t = child:GetText()
            if t and t:find("Revert", 1, true) then
                return child
            end
        end
        -- Check FontStrings inside (Button text region)
        if child.GetFontString then
            local fs = child:GetFontString()
            if fs then
                local t = fs:GetText()
                if t and t:find("Revert", 1, true) then
                    return child
                end
            end
        end
    end
    return nil
end

local function InjectCDVButton()
    if cdvButtonInjected then return end
    local parent = CooldownViewerSettings
    if not parent then return end

    -- Find Revert button by text
    local revertBtn = FindRevertButton(parent)

    -- Build our button
    local btn = CreateFrame("Button", "GravityUI_CDMProfilesBtn", parent, "BackdropTemplate")
    btn:SetSize(90, 22)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.07, 0.14, 0.25, 0.95)
    btn:SetBackdropBorderColor(0.25, 0.50, 0.80, 1)

    local btnLabel = btn:CreateFontString(nil, "OVERLAY")
    btnLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    btnLabel:SetText("|cff7ec8e3GUI|r Profiles")
    btnLabel:SetPoint("CENTER")

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.22, 0.40, 1)
        self:SetBackdropBorderColor(0.40, 0.70, 1.0, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.07, 0.14, 0.25, 0.95)
        self:SetBackdropBorderColor(0.25, 0.50, 0.80, 1)
    end)
    btn:SetScript("OnClick", function()
        CDM.Toggle()
    end)

    -- Anchor: left of Revert button if found, else bottom-right of frame
    if revertBtn then
        btn:SetPoint("RIGHT", revertBtn, "LEFT", -6, 0)
    else
        -- Fallback: anchor to bottom-right area of the settings frame
        btn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -80, 8)
    end

    cdvButtonInjected = true
end

-- Immediate attempt (if frame already exists)
if CooldownViewerSettings then
    InjectCDVButton()
end

-- ADDON_LOADED listener for when Blizzard_CooldownViewer loads after us
local cdvHookFrame = CreateFrame("Frame")
cdvHookFrame:RegisterEvent("ADDON_LOADED")
cdvHookFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Blizzard_CooldownViewer" then
        -- One frame delay so all children are created before we scan
        C_Timer.After(0, InjectCDVButton)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
