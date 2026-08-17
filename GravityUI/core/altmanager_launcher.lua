-- ============================================================================
-- GravityUI - Alt Manager Launcher (Icon Catcher & Minimap Integration)
-- ============================================================================
local ADDON_NAME, ns = ...

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)
local LSM = LibStub("LibSharedMedia-3.0", true)

ns.AltManager = ns.AltManager or {}
local AM = ns.AltManager

local minimapButton = nil

local function GetDB()
    local db = ns.GetDB and ns.GetDB()
    if db and db.altManager then return db.altManager end
    return ns.Defaults and ns.Defaults.altManager
end

local function GetFont()
    local font = (ns.Styling and ns.Styling.GetFontPath and ns.Styling:GetFontPath()) or
                 (LSM and LSM:Fetch("font", ns.GetDB() and ns.GetDB().general and ns.GetDB().general.font or "Gravity")) or
                 "Fonts\\FRIZQT__.TTF"
    return font
end

function AM:SetupLauncher()
    if not LDB or not LDBIcon then return end
    if minimapButton then return end

    local db = GetDB()
    if not db then return end

    local broker = LDB:NewDataObject("GravityUI_AltManager", {
        type = "launcher",
        text = "Alt Manager",
        icon = ns.ICON_PATH or "Interface\\AddOns\\GravityUI\\assets\\GRAVITY_UI_Icon.blp",
        OnClick = function(_, btn)
            if btn == "LeftButton" then
                if AM.UI and AM.UI.ToggleWindow then
                    AM.UI:ToggleWindow()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cff00c0ffGravity|r |cffffffffAlt Manager|r")
            tooltip:AddLine("Account-wide Mythic+, Vault & Raid Matrix", 0.7, 0.8, 0.9)
            tooltip:AddLine(" ")

            -- Quick list of current alts & keys
            if AM.Data and AM.Data.GetAllAltsList then
                local alts = AM.Data:GetAllAltsList()
                if #alts > 0 then
                    tooltip:AddLine("|cffffffffAlts & Keystones:|r")
                    for _, alt in ipairs(alts) do
                        local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[alt.class] or { r = 1, g = 1, b = 1 }
                        local cStr = classColor.colorStr or "ffffffff"
                        local keyStr = "|cff666666No Key|r"
                        if alt.keystone and alt.keystone.level and alt.keystone.level > 0 then
                            keyStr = string.format("|c%s+%d %s|r", alt.keystone.color or "ffffffff", alt.keystone.level, alt.keystone.name or "")
                        end
                        tooltip:AddDoubleLine(string.format("|c%s%s|r", cStr, alt.name), keyStr, 1, 1, 1, 1, 1, 1)
                    end
                    tooltip:AddLine(" ")
                end
            end

            tooltip:AddLine("|cff00c0ffLeft-Click:|r Open Alt Matrix Dashboard", 0.5, 0.8, 1)
            tooltip:AddLine("|cff888888Slash Command: /guialt or /galt|r", 0.5, 0.5, 0.5)
        end,
    })

    local dbMinimap = db.minimap or { hide = false, minimapPos = 220 }
    LDBIcon:Register("GravityUI_AltManager", broker, dbMinimap)
    minimapButton = LDBIcon:GetMinimapButton("GravityUI_AltManager")

    -- Add centered "ALT" text overlay onto the button
    if minimapButton then
        if not minimapButton.altBadge then
            local badge = minimapButton:CreateFontString(nil, "OVERLAY")
            badge:SetPoint("CENTER", minimapButton, "CENTER", 0, -1)
            badge:SetFont(GetFont(), 9, "OUTLINE")
            badge:SetText("|cffffffffALT|r")
            badge:SetTextColor(1, 1, 1, 1)
            minimapButton.altBadge = badge
        end

    -- Dim the background texture slightly so "ALT" text pops out crisply
        if minimapButton.icon then
            minimapButton.icon:SetVertexColor(0.7, 0.85, 1, 0.9)
        end
    end
end

function AM:UpdateMinimapIcon()
    local db = GetDB()
    if not db then return end
    local hide = (db.showMinimap == false) or (db.minimap and db.minimap.hide == true)
    
    if LDBIcon then
        if hide then
            LDBIcon:Hide("GravityUI_AltManager")
        else
            LDBIcon:Show("GravityUI_AltManager")
        end
    end

    if minimapButton then
        if hide then
            minimapButton.GravityExt_IsUpdating = true
            minimapButton:Hide()
            minimapButton.GravityExt_IsUpdating = false
        else
            if not ns.IconCatcher or not ns.IconCatcher.isExpanded then
                -- let IconCatcher manage it
            else
                minimapButton:Show()
            end
        end
    end

    if ns.IconCatcher and ns.IconCatcher.LayoutGrid then
        ns.IconCatcher.LayoutGrid()
    end
end

-- Bootstrap launcher after player login
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    C_Timer.After(1.0, function()
        local db = GetDB()
        if db and db.enabled ~= false then
            AM:SetupLauncher()
            AM:UpdateMinimapIcon()
        end
    end)
end)
