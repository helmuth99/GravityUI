---------------------------------------------------------------------------
-- GravityUI Tooltip Module
-- Custom tooltip enhancements for GravityUI
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...

ns.Tooltip = {}

local GameTooltip = GameTooltip
local InCombatLockdown = InCombatLockdown
local strmatch = string.match
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS
local C_MountJournal = C_MountJournal
local C_UnitAuras = C_UnitAuras

-- Context Detection Constants
local UNIT_FRAME_PATTERNS = {
    "UnitFrame", "PlayerFrame", "TargetFrame", "FocusFrame",
    "PartyMemberFrame", "CompactRaidFrame", "CompactPartyFrame",
    "NamePlate", "Gravity.*Frame"
}
local CDM_PATTERNS = {
    "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer"
}
local ACTION_BUTTON_PATTERNS = {
    "ActionButton", "MultiBar", "PetActionButton", "StanceButton",
    "OverrideActionBar", "ExtraActionButton", "BT4Button",
    "DominosActionButton", "ElvUI_Bar"
}
local BAG_PATTERNS = {
    "ContainerFrame", "BagSlot", "BankFrame", "ReagentBank",
    "BagItem", "Baganator"
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.tooltip then
        return db.uiimprovements.tooltip
    end
end

local function IsSecretValue(value)
    if not value then return false end
    if type(issecretvalue) == "function" then return issecretvalue(value) end
    return false
end

local function IsModifierActive(modKey)
    if modKey == "SHIFT" then return IsShiftKeyDown() end
    if modKey == "CTRL"  then return IsControlKeyDown() end
    if modKey == "ALT"   then return IsAltKeyDown() end
    return false
end

local function SanitizeColor(c, dr, dg, db, da)
    if not c or type(c) ~= "table" then return dr or 0, dg or 0, db or 0, da or 1 end
    return tonumber(c[1]) or dr or 0, tonumber(c[2]) or dg or 0,
           tonumber(c[3]) or db or 0, tonumber(c[4]) or da or 1
end

local function GetColorFromSettings(useTheme, custom)
    if useTheme then return ns.GetAccentColor() end
    return SanitizeColor(custom, 0.2, 0.2, 0.2, 1)
end

local function CHex(r, g, b)
    return string.format("|cff%02x%02x%02x", (r or 0)*255, (g or 0)*255, (b or 0)*255)
end

---------------------------------------------------------------------------
-- Context Detection / Visibility
---------------------------------------------------------------------------

local function GetTooltipContext(owner)
    if not owner then return "npcs" end
    if type(owner) ~= "table" or (owner.IsForbidden and owner:IsForbidden()) then return "npcs" end
    local ok, name = pcall(function() return owner:GetName() or "" end)
    if not ok then name = "" end
    local parentName = ""
    local parent; pcall(function() parent = owner:GetParent() end)
    if parent and not (parent.IsForbidden and parent:IsForbidden()) then
        local pok, pn = pcall(function() return parent:GetName() or "" end)
        if pok then parentName = pn end
    end
    for _, p in ipairs(CDM_PATTERNS)           do if strmatch(name, p) or strmatch(parentName, p) then return "cdm"       end end
    for _, p in ipairs(ACTION_BUTTON_PATTERNS) do if strmatch(name, p) then return "abilities" end end
    for _, p in ipairs(BAG_PATTERNS)           do if strmatch(name, p) then return "items"     end end
    for _, p in ipairs(UNIT_FRAME_PATTERNS)    do if strmatch(name, p) then return "frames"    end end
    return "npcs"
end

local function ShouldShowTooltip(context)
    local settings = GetSettings()
    if not settings or not settings.enabled then return true end
    if settings.hideInCombat and InCombatLockdown() then
        if settings.combatKey and settings.combatKey ~= "NONE" then
            if IsModifierActive(settings.combatKey) then return true end
        end
        return false
    end
    local v = settings.visibility and settings.visibility[context]
    if not v or v == "SHOW" then return true
    elseif v == "HIDE"      then return false
    else return IsModifierActive(v)
    end
end

---------------------------------------------------------------------------
-- Backdrop Styling
---------------------------------------------------------------------------

local TOOLTIP_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 }
}

local function ApplyStyle(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end
    if InCombatLockdown() then return end
    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.customStyle then return end

    if tooltip.NineSlice then tooltip.NineSlice:Hide(); tooltip.NineSlice:SetAlpha(0) end
    if not tooltip.SetBackdrop then Mixin(tooltip, BackdropTemplateMixin) end

    local bgR, bgG, bgB = SanitizeColor(settings.bgColor, 0, 0, 0, 1)
    local alpha = tonumber(settings.bgAlpha) or 0.8
    local br, bg_, bb, ba = GetColorFromSettings(settings.useThemeColor, settings.borderColor)

    local ok = pcall(function() tooltip:SetBackdrop(TOOLTIP_BACKDROP) end)
    if ok then
        pcall(function()
            tooltip:SetBackdropColor(bgR, bgG, bgB, alpha)
            tooltip:SetBackdropBorderColor(br, bg_, bb, ba)
        end)
    end

    if settings.fontSize then
        for i = 1, 15 do
            local left  = _G[tooltip:GetName().."TextLeft"..i]
            local right = _G[tooltip:GetName().."TextRight"..i]
            if not left then break end
            pcall(function()
                -- Line 1 (name / title) is slightly larger for visual hierarchy
                local size = (i == 1) and (settings.fontSize + 1) or settings.fontSize
                local fp, _, ff = left:GetFont()
                if fp then left:SetFont(fp, size, ff) end
                if right then
                    local rp, _, rf = right:GetFont()
                    if rp then right:SetFont(rp, size, rf) end
                end
            end)
        end
    end
end

---------------------------------------------------------------------------
-- Health Bar
-- Hook GameTooltip "SetUnit" for initial color,
-- hook StatusBar "OnValueChanged" for updates.
-- Both in-combat-locked and use pcall for secret-value safety.
---------------------------------------------------------------------------

local healthBarSetup = false

local C_ClassColor_GetClassColor = C_ClassColor and C_ClassColor.GetClassColor

local function GetClassColor(unit)
    -- Only apply class colour to actual players; NPCs can have a class token
    -- (e.g. training dummies classified as Warrior/Paladin) which would give
    -- them a misleading class colour.
    if UnitIsPlayer(unit) then
        local _, classToken = UnitClass(unit)
        if classToken then
            -- Prefer CUSTOM_CLASS_COLORS / RAID_CLASS_COLORS.
            -- Fall back to C_ClassColor.GetClassColor for robustness
            -- (works even when the unit token is tainted after M+/Raid).
            local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classToken]
            if c then return c.r, c.g, c.b end
            if C_ClassColor_GetClassColor then
                local cc = C_ClassColor_GetClassColor(classToken)
                if cc then return cc.r, cc.g, cc.b end
            end
        end
    end
    if UnitIsFriend("player", unit) then return 0.0, 0.8, 0.0 end
    if UnitIsEnemy("player", unit)  then return 0.9, 0.2, 0.2 end
    return 1.0, 0.8, 0.0
end


local function ApplyBarForUnit(bar, unit)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    -- Visibility
    if settings.hideHealthBar then
        bar:SetAlpha(0)
        return
    end
    bar:SetAlpha(1)

    -- Re-anchor bar flush with tooltip border, height 4px (one-time per session)
    -- PERF: guard flag prevents allocating a closure on every OnValueChanged HP-tick
    if not bar.gravityAnchored then
        pcall(function()
            bar:SetHeight(4)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT",  GameTooltip, "BOTTOMLEFT",  0, 0)
            bar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", 0, 0)
        end)
        bar.gravityAnchored = true
    end

    -- Texture
    if settings.healthBarTexture then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then
            local tex = LSM:Fetch("statusbar", settings.healthBarTexture)
            if tex then pcall(bar.SetStatusBarTexture, bar, tex) end
        end
    end

    -- Class Color
    if settings.useClassColorHealth then
        local cr, cg, cb = GetClassColor(unit)
        pcall(bar.SetStatusBarColor, bar, cr, cg, cb)
    end
end

local function SetupHealthBar()
    if healthBarSetup then return end
    healthBarSetup = true

    -- Primary hook: fires when tooltip acquires a new unit
    hooksecurefunc(GameTooltip, "SetUnit", function(self, unit)
        if InCombatLockdown() then return end
        if not unit then return end
        local bar = self.StatusBar or GameTooltipStatusBar
        if not bar then return end
        pcall(ApplyBarForUnit, bar, unit)
    end)

    -- Secondary hook: fires on every health value tick
    GameTooltipStatusBar:HookScript("OnValueChanged", function(self)
        if InCombatLockdown() then return end
        local unit
        pcall(function() unit = select(2, GameTooltip:GetUnit()) end)
        if not unit or type(unit) ~= "string" then return end
        pcall(ApplyBarForUnit, self, unit)
    end)
end

---------------------------------------------------------------------------
-- Mount Detection (scan HELPFUL auras for active mount)
---------------------------------------------------------------------------

local function GetMountName(unit)
    if InCombatLockdown() then return end  -- aura scanning can throw in combat
    if not unit or not UnitExists(unit) then return end
    if not C_UnitAuras or not C_MountJournal then return end

    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not aura then break end

        local spellId = aura.spellId
        if spellId then
            local mountID
            if C_MountJournal.GetMountInfoBySpellID then
                mountID = select(12, C_MountJournal.GetMountInfoBySpellID(spellId))
            elseif C_MountJournal.GetMountFromSpell then
                mountID = C_MountJournal.GetMountFromSpell(spellId)
            end

            if mountID then
                local mName
                if C_MountJournal.GetMountInfoByID then
                    mName = C_MountJournal.GetMountInfoByID(mountID)
                end
                mName = mName or aura.name or (GetSpellInfo and GetSpellInfo(spellId))
                return mName
            end
        end
    end
end

---------------------------------------------------------------------------
-- ID Display
---------------------------------------------------------------------------

local function AddIDLines(tooltip, data, dataType)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    if not data then return end

    local r, g, b = GetColorFromSettings(settings.useThemeColorID, settings.idColor)
    local lc = CHex(r, g, b)
    local vc = "|cffffffff"
    local lines = {}

    local spellId = data.spellId or data.id

    if settings.showSpellID and spellId and not IsSecretValue(spellId)
       and (dataType == "spell" or dataType == "ability") then
        table.insert(lines, { label = "Spell ID", value = tostring(spellId) })
    end

    if settings.showAuraID and spellId and not IsSecretValue(spellId)
       and dataType == "aura" then
        table.insert(lines, { label = "Aura ID", value = tostring(spellId) })
    end

    if settings.showIconID and spellId and not IsSecretValue(spellId)
       and (dataType == "spell" or dataType == "ability" or dataType == "aura") then
        pcall(function()
            -- Modern API first (Dragonflight+), then legacy fallback
            local icon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellId))
                      or (GetSpellTexture and GetSpellTexture(spellId))
            if icon then
                local iconId
                if type(icon) == "number" then
                    iconId = tostring(icon)
                elseif type(icon) == "string" then
                    -- path like "Interface\Icons\Spell_Fire_Fireball2" → numeric suffix if present
                    iconId = icon:match("(%d+)$")
                    if not iconId then
                        -- also try full path as-is (some addons show it)
                        iconId = icon
                    end
                end
                if iconId then table.insert(lines, { label = "Icon ID", value = iconId }) end
            end
        end)
    end

    -- Icon ID for Items
    if settings.showIconID and dataType == "item" and (data.itemId or data.id) then
        pcall(function()
            local itemId = data.itemId or data.id
            local icon = GetItemIconByID and GetItemIconByID(itemId)
            if icon then
                local iconId = (type(icon) == "number") and tostring(icon) or icon:match("(%d+)$")
                if iconId then table.insert(lines, { label = "Icon ID", value = iconId }) end
            end
        end)
    end


    if settings.showNPCID and dataType == "unit" and data.guid and not IsSecretValue(data.guid) then
        local npcId = data.guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)")
                   or data.guid:match("^Pet%-%d+%-%d+%-%d+%-%d+%-(%d+)")
                   or data.guid:match("^Vehicle%-%d+%-%d+%-%d+%-%d+%-(%d+)")
        if tonumber(npcId) then
            table.insert(lines, { label = "NPC ID", value = npcId })
        end
    end

    if settings.showIDs and dataType == "item" then
        local itemId = data.itemId or data.id
        if itemId and not IsSecretValue(itemId) then
            table.insert(lines, { label = "Item ID", value = tostring(itemId) })
        end
    end

    if settings.showTextureID and data.textureId and not IsSecretValue(data.textureId) then
        table.insert(lines, { label = "Texture ID", value = tostring(data.textureId) })
    end

    if #lines > 0 then
        tooltip:AddLine(" ")
        for _, e in ipairs(lines) do
            tooltip:AddDoubleLine(lc .. e.label .. ":|r", vc .. e.value .. "|r")
        end
    end
end

---------------------------------------------------------------------------
-- Unit Text Enhancements (RoamyTooltip-style)
-- Primary gate: tooltip:GetUnit() → UnitIsPlayer → UnitClass
-- Combat fallback: GetPlayerInfoByGUID (player GUIDs only, never tainted)
-- NPC fallback: UnitReaction for name color
---------------------------------------------------------------------------

local function InjectUnitInfo(tooltip, data)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    pcall(function()
        -- ── Resolve unit token ─────────────────────────────────────────────
        local unit
        pcall(function() unit = select(2, tooltip:GetUnit()) end)
        if unit and type(unit) ~= "string" then unit = nil end

        -- ── Class / player detection ────────────────────────────────────────
        local isPlayer = false
        local localClass, classToken, classColor
        local unitTainted = false  -- true if APIs threw on the resolved unit token

        if unit then
            local ok = pcall(function()
                isPlayer = UnitIsPlayer(unit) == true
                local lc, ct = UnitClass(unit)
                if type(lc) == "string" then localClass = lc end
                if type(ct) == "string" then classToken  = ct end
            end)
            if not ok then
                unitTainted = true  -- unit token is tainted (M+/Raid)
            end
            if classToken then
                classColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classToken]
                if not classColor and C_ClassColor_GetClassColor then
                    classColor = C_ClassColor_GetClassColor(classToken)
                end
            end
        end

        -- GetPlayerInfoByGUID fallback: runs when:
        --   (a) unit is nil (couldn't be resolved), OR
        --   (b) unit was tainted (APIs threw – M+/Raid scenario)
        -- Safe for NPCs: GetPlayerInfoByGUID returns nil for non-player GUIDs.
        -- NOT run if unit resolved fine as a non-player (pet/NPC guard) to avoid
        -- applying the owner's class color to pets (DK ghoul etc.).
        if not classToken and (not unit or unitTainted) then
            pcall(function()
                if not (data and data.guid) then return end
                local lc, ct = GetPlayerInfoByGUID(data.guid)
                if type(lc) ~= "string" or type(ct) ~= "string" then return end
                localClass, classToken, isPlayer = lc, ct, true
                classColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classToken]
                if not classColor and C_ClassColor_GetClassColor then
                    classColor = C_ClassColor_GetClassColor(classToken)
                end
            end)
        end

        -- ── Name color ──────────────────────────────────────────────────────
        local nameR, nameG, nameB = 1, 1, 1
        if isPlayer and classColor then
            -- Class color only for actual player characters
            nameR, nameG, nameB = classColor.r, classColor.g, classColor.b
        elseif unit and not isPlayer then
            -- Reaction color for NPCs (friendly=green, neutral=yellow, hostile=red)
            pcall(function()
                local reaction = UnitReaction("player", unit)
                if reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction] then
                    local c = FACTION_BAR_COLORS[reaction]
                    nameR, nameG, nameB = c.r, c.g, c.b
                end
            end)
        end

        -- ── GetRegions() scan (RoamyTooltip approach) ──────────────────────
        local regions
        pcall(function() regions = {tooltip:GetRegions()} end)
        if not regions then return end

        -- First FontString = name line
        local nameLine
        for _, r in ipairs(regions) do
            if r:GetObjectType() == "FontString" then
                nameLine = r; break
            end
        end

        -- Apply name with embedded color (baked into text, survives vertex resets)
        if nameLine and settings.classColorName then
            local name
            pcall(function()
                if unit then
                    -- PvP title if enabled – guard against empty string returns in instance context
                    local pvpName = UnitPVPName(unit)
                    if pvpName and type(pvpName) == "string" and pvpName ~= "" then name = pvpName end
                    -- UnitName returns (name, realm) – capture only name explicitly
                    if not name or name == "" then
                        local n = UnitName(unit)
                        if n and n ~= "" then name = n end
                    end
                end
                -- Fallback: strip color codes from existing tooltip text
                if not name or name == "" then
                    local t = nameLine:GetText()
                    if t then
                        local stripped = t:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
                        if stripped ~= "" then name = stripped end
                    end
                end
            end)
            if name and name ~= "" then
                local status = ""
                pcall(function()
                    if unit then
                        if UnitIsAFK(unit) then status = " |cffffff00<AFK>|r"
                        elseif UnitIsDND(unit) then status = " |cffff8800<DND>|r" end
                    end
                end)
                nameLine:SetText(CHex(nameR, nameG, nameB) .. name .. "|r" .. status)
                nameLine:SetTextColor(1, 1, 1)
            end
        end

        -- ── Spec (out-of-combat only) ───────────────────────────────────────
        local specName
        if unit and not InCombatLockdown() then
            pcall(function()
                if UnitIsUnit(unit, "player") and GetSpecialization then
                    local idx = GetSpecialization()
                    if idx then specName = select(2, GetSpecializationInfo(idx)) end
                elseif GetInspectSpecialization then
                    local specID = GetInspectSpecialization(unit)
                    if specID and specID > 0 then
                        specName = select(2, GetSpecializationInfoByID(specID))
                    end
                end
            end)
        end

        -- ── Guild info ──────────────────────────────────────────────────────
        local guildName, guildRank
        if unit then
            pcall(function()
                local gn, gr = GetGuildInfo(unit)
                if type(gn) == "string" then guildName = gn end
                if type(gr) == "string" then guildRank = gr end
            end)
        end

        -- ── Iterate remaining FontStrings ────────────────────────────────────
        -- Also tracks whether Blizzard rendered the guild line so we can
        -- fall back to AddLine only when it's missing (e.g. raid/instance).
        local skipFirst = true
        local guildFoundInTooltip = false
        for _, fs in ipairs(regions) do
            if fs:GetObjectType() == "FontString" then
                if skipFirst then
                    skipFirst = false  -- skip name line already handled above
                else
                    local text = fs:GetText()
                    if text and text ~= "" then

                        -- Guild line: recolor Blizzard's own rendered line
                        if isPlayer and guildName and settings.showGuildInfo
                        and text:find(guildName, 1, true) then
                            guildFoundInTooltip = true
                            local gc = settings.guildColor or {0.2, 0.9, 0.2, 1}
                            local gText = CHex(tonumber(gc[1]) or 0.2, tonumber(gc[2]) or 0.9, tonumber(gc[3]) or 0.2)
                                       .. "<" .. guildName .. ">|r"
                            if guildRank and guildRank ~= "" then
                                gText = gText .. " |cffb0b0b0[" .. guildRank .. "]|r"
                            end
                            fs:SetText(gText)
                            fs:SetTextColor(1, 1, 1)

                        -- Level line
                        elseif settings.showColoredLevel and text:lower():find("level") then
                            local level = text:match("(%d+)")
                            if level then
                                local diff = tonumber(level) - (UnitLevel("player") or 1)
                                local lr, lg_, lb
                                if     diff >= 5  then lr,lg_,lb = 1.0, 0.1, 0.1
                                elseif diff >= 3  then lr,lg_,lb = 1.0, 0.5, 0.0
                                elseif diff >= -2 then lr,lg_,lb = 1.0, 1.0, 0.0
                                elseif diff >= -4 then lr,lg_,lb = 0.1, 1.0, 0.1
                                else                   lr,lg_,lb = 0.6, 0.6, 0.6
                                end
                                fs:SetText(text:gsub(tostring(level), CHex(lr,lg_,lb)..level.."|r", 1))
                                fs:SetTextColor(1, 1, 1)
                            end

                        -- Faction
                        elseif settings.showFaction and text:find("Alliance", 1, true) then
                            fs:SetTextColor(0.4, 0.6, 1.0)

                        elseif settings.showFaction and text:find("Horde", 1, true) then
                            fs:SetTextColor(1.0, 0.3, 0.3)

                        -- Spec / Class line
                        elseif settings.showSpecAndClass and isPlayer and classColor
                        and localClass and text:find(localClass, 1, true) then
                            if specName and specName ~= "" then
                                fs:SetText(CHex(classColor.r, classColor.g, classColor.b)
                                    .. specName .. " " .. localClass .. "|r")
                                fs:SetTextColor(1, 1, 1)
                            else
                                fs:SetTextColor(classColor.r, classColor.g, classColor.b)
                            end
                        end
                    end
                end
            end
        end

        -- ── Guild fallback (only if Blizzard didn't render the line) ─────────
        -- In instances/raids Blizzard omits the guild line entirely; inject it.
        if unit and isPlayer and guildName and settings.showGuildInfo
        and not guildFoundInTooltip and not tooltip.__guiGuildAdded then
            pcall(function()
                local gc = settings.guildColor or {0.2, 0.9, 0.2, 1}
                local gText = CHex(tonumber(gc[1]) or 0.2, tonumber(gc[2]) or 0.9, tonumber(gc[3]) or 0.2)
                           .. "<" .. guildName .. ">|r"
                if guildRank and guildRank ~= "" then
                    gText = gText .. " |cffb0b0b0[" .. guildRank .. "]|r"
                end
                tooltip:AddLine(gText)
                tooltip.__guiGuildAdded = true
            end)
        end

        -- ── Server / Realm (only for cross-realm players) ────────────────
        if unit and settings.showServer and not tooltip.__guiServerAdded then
            pcall(function()
                if not UnitIsPlayer(unit) then return end
                -- UnitName returns a non-nil realm only for cross-realm players.
                -- Same-realm players always return nil here, so no line is added.
                local _, unitRealm = UnitName(unit)
                if unitRealm and unitRealm ~= "" then
                    tooltip:AddLine("|cffaaaaaa" .. "Server:|r |cffffffff" .. unitRealm .. "|r")
                    tooltip.__guiServerAdded = true
                end
            end)
        end

        -- ── Mount ───────────────────────────────────────────────────────────
        if unit and settings.showMount and not tooltip.__guiMountAdded then
            local mName = GetMountName(unit)
            if mName then
                tooltip:AddLine("|cffaaaaaa" .. "Mount:|r |cffffffff" .. mName .. "|r")
                tooltip.__guiMountAdded = true
            end
        end
    end) -- pcall
end

---------------------------------------------------------------------------
-- Tooltip Hooks
---------------------------------------------------------------------------

local function InitHooks()
    SetupHealthBar()

    -- Reset per-tooltip injection flags on clear/hide
    GameTooltip:HookScript("OnTooltipCleared", function(self) self.__guiMountAdded = nil; self.__guiServerAdded = nil; self.__guiGuildAdded = nil end)
    GameTooltip:HookScript("OnHide", function(self) self.__guiMountAdded = nil; self.__guiServerAdded = nil; self.__guiGuildAdded = nil end)

    -- When leaving combat, refresh the tooltip if it's still visible.
    -- Guild, rank, mount and spec are skipped in combat; this picks them up again.
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:SetScript("OnEvent", function()
        if GameTooltip:IsShown() and not GameTooltip:IsForbidden() then
            pcall(function()
                local _, unit = GameTooltip:GetUnit()
                if unit and type(unit) == "string" then
                    GameTooltip.__guiMountAdded = nil  -- allow mount re-add
                    GameTooltip:SetUnit(unit)
                end
            end)
        end
    end)

    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        tooltip.__guiLastID = nil
        local settings = GetSettings()
        if not settings or not settings.enabled then return end
        local context = GetTooltipContext(parent)
        if not ShouldShowTooltip(context) then
            tooltip:Hide()
            return
        end
        if settings.anchorToCursor then
            tooltip:SetOwner(parent, "ANCHOR_CURSOR")
        end
    end)

    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            if not tooltip or tooltip:IsForbidden() then return end
            local settings = GetSettings()
            if not settings or not settings.enabled then return end
            pcall(function()
                ApplyStyle(tooltip)
                InjectUnitInfo(tooltip, data)
                AddIDLines(tooltip, data, "unit")
            end)
        end)

        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
            if not tooltip or tooltip:IsForbidden() then return end
            local settings = GetSettings()
            if not settings or not settings.enabled then return end
            pcall(function() ApplyStyle(tooltip); AddIDLines(tooltip, data, "spell") end)
        end)

        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if not tooltip or tooltip:IsForbidden() then return end
            local settings = GetSettings()
            if not settings or not settings.enabled then return end
            pcall(function() ApplyStyle(tooltip); AddIDLines(tooltip, data, "item") end)
        end)

        if Enum.TooltipDataType.UnitAura then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, function(tooltip, data)
                if not tooltip or tooltip:IsForbidden() then return end
                local settings = GetSettings()
                if not settings or not settings.enabled then return end
                pcall(function() ApplyStyle(tooltip); AddIDLines(tooltip, data, "aura") end)
            end)
        end

        if Enum.TooltipDataType.Ability then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Ability, function(tooltip, data)
                if not tooltip or tooltip:IsForbidden() then return end
                local settings = GetSettings()
                if not settings or not settings.enabled then return end
                pcall(function() ApplyStyle(tooltip); AddIDLines(tooltip, data, "ability") end)
            end)
        end
    end

    ---------------------------------------------------------------------------
    -- Macro button SpellID fix
    -- Macros surface as their own tooltip type (Enum.TooltipDataType.Macro),
    -- so the Spell/Ability hooks above never fire for them. GetSpell() also
    -- returns nil on a macro tooltip. The spell #showtooltip resolved to
    -- (honoring conditionals) is exposed as the FIRST tooltip line's tooltipID,
    -- which we read from tooltip:GetTooltipData(). Approach mirrors EllesmereUI.
    ---------------------------------------------------------------------------
    if Enum.TooltipDataType.Macro then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Macro, function(tooltip, _data)
            if not tooltip or tooltip:IsForbidden() then return end
            local settings = GetSettings()
            if not settings or not settings.enabled then return end
            if not (settings.showSpellID or settings.showIconID) then return end

            pcall(function()
                if not tooltip.GetTooltipData then return end
                local ok, info = pcall(tooltip.GetTooltipData, tooltip)
                if not ok or type(info) ~= "table" or not info.lines then return end
                local line = info.lines[1]
                local spellId = line and line.tooltipID
                if not spellId then return end  -- item-only macro / nothing castable
                AddIDLines(tooltip, { spellId = spellId }, "spell")
            end)
        end)
    end
end

---------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------

function ns.Tooltip.Refresh()
    if GameTooltip and GameTooltip:IsShown() and not GameTooltip:IsForbidden() then
        pcall(ApplyStyle, GameTooltip)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    InitHooks()
end)
