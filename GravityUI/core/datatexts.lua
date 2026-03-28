local ADDON_NAME, ns = ...
ns.Datatexts = {}
local DT = ns.Datatexts
local C = ns.Colors

-- Constants
local DAY_SECONDS = 86400
local HOUR_SECONDS = 3600
local MINUTE_SECONDS = 60

-- Helpers
local function GetValueColor()
    -- Use the optimized global accent color
    local r, g, b = ns.GetAccentColor()
    return r, g, b
end

local function GetLabel(fullLabel, shortLabel, useShortLabel, useNoLabel)
    if useNoLabel then return "" end
    if useShortLabel then return shortLabel end
    return fullLabel
end

local function FormatTimeRemaining(seconds)
    if not seconds or seconds <= 0 then return "0m" end
    local days = math.floor(seconds / DAY_SECONDS)
    local hours = math.floor((seconds % DAY_SECONDS) / HOUR_SECONDS)
    local minutes = math.floor((seconds % HOUR_SECONDS) / MINUTE_SECONDS)
    
    if days > 0 then return string.format("%dd %dh", days, hours)
    elseif hours > 0 then return string.format("%dh %dm", hours, minutes)
    else return string.format("%dm", minutes) end
end

-- Lockout cache for throttling RequestRaidInfo
local lockoutCache = {
    lastUpdate = 0,
    instances = {},
    worldBosses = {},
}

local function RefreshLockoutCache()
    local now = GetTime()
    if now - lockoutCache.lastUpdate < 300 then -- 5 minute cache
        return
    end

    RequestRaidInfo()
    lockoutCache.lastUpdate = now

    -- Cache saved instances
    wipe(lockoutCache.instances)
    local numSaved = GetNumSavedInstances() or 0
    for i = 1, numSaved do
        local name, _, reset, _, locked, _, _, _, maxPlayers, difficultyName = GetSavedInstanceInfo(i)
        if locked and reset > 0 then
            table.insert(lockoutCache.instances, {
                name = name,
                reset = reset,
                maxPlayers = maxPlayers,
                difficultyName = difficultyName,
            })
        end
    end

    -- Cache world bosses
    wipe(lockoutCache.worldBosses)
    if GetNumSavedWorldBosses then
        local numWorldBosses = GetNumSavedWorldBosses() or 0
        for i = 1, numWorldBosses do
            local name, _, reset = GetSavedWorldBossInfo(i)
            if name and reset > 0 then
                table.insert(lockoutCache.worldBosses, {
                    name = name,
                    reset = reset,
                })
            end
        end
    end
end

-- ============================================================================
-- SOCIAL HELPERS & CACHING
-- ============================================================================
local TIMERUNNING_ICON = "|A:timerunning-glues-icon-small:12:10:0:0|a"
local MOBILE_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat:14:14:0:0:16:16:0:16:0:16:73:177:73|t"

local function GetLevelColor(level)
    level = level or 1
    local color = GetQuestDifficultyColor(level)
    return color -- Return the color table
end

local LocalizedToEnglishMap = {}
if FillLocalizedClassList then
    FillLocalizedClassList(LocalizedToEnglishMap)
end

-- Fallback for clients where FillLocalizedClassList might technically exist but return nothing, or not exist
if not next(LocalizedToEnglishMap) then
    if LOCALIZED_CLASS_NAMES_MALE then
        for token, localizedName in pairs(LOCALIZED_CLASS_NAMES_MALE) do
            LocalizedToEnglishMap[localizedName] = token
        end
    end
    if LOCALIZED_CLASS_NAMES_FEMALE then
        for token, localizedName in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
            LocalizedToEnglishMap[localizedName] = token
        end
    end
end

local function GetClassColor(className)
    if not className then return {r=1, g=1, b=1} end
    -- Try direct lookup (English Token)
    local c = RAID_CLASS_COLORS[className]
    if c then return c end
    -- Try localized lookup (e.g. "Krieger" -> "WARRIOR")
    if LocalizedToEnglishMap[className] then
        c = RAID_CLASS_COLORS[LocalizedToEnglishMap[className]]
        if c then return c end
    end
    -- Fallback: check upper case just in case
    if LocalizedToEnglishMap[className:upper()] then
         c = RAID_CLASS_COLORS[LocalizedToEnglishMap[className:upper()]]
         if c then return c end
    end
    
    return {r=1, g=1, b=1}
end

local function IsPlayerInGroup(name)
    if not name then return false end
    return UnitInParty(name) or UnitInRaid(name)
end

local function SendWhisperTo(name, isBNet)
    if not name then return end
    if isBNet then
        ChatFrameUtil.SendBNetTell(name)
    else
        SetItemRef("player:" .. name, string.format("|Hplayer:%1$s|h[%1$s]|h", name), "LeftButton")
    end
end

local function InvitePlayerToGroup(name, guid, isBNet)
    if not name then return end
    if isBNet then
        BNInviteFriend(name)
    else
        C_PartyInfo.InviteUnit(name)
    end
end

local myRealmPattern
local function StripMyRealm(name)
    if not myRealmPattern then
        local realm = GetNormalizedRealmName()
        if realm then myRealmPattern = "%-" .. realm else return name end
    end
    return (string.gsub(name, myRealmPattern, ""))
end

-- Guild Cache
local guildCache = { members = {}, lastUpdate = 0 }

local function GetPopupMaxRows()
    local db = ns.GetDB()
    if db and db.minimap and db.minimap.datatext then
        local v = tonumber(db.minimap.datatext.popupMaxRows)
        if v == nil then return 25 end        -- default
        if v == 0  then return math.huge end  -- unlimited
        return v
    end
    return 25
end

local function BuildGuildCache()
    if not IsInGuild() then return end
    C_GuildInfo.GuildRoster() -- Request refresh
    wipe(guildCache.members)
    local total, online = GetNumGuildMembers()
    for i = 1, total do
        local name, rank, rankIndex, level, class, zone, note, offNote, connected, status, engClass, _, _, isMobile, _, _, guid = GetGuildRosterInfo(i)
        if name and (connected or isMobile) then
            table.insert(guildCache.members, {
                name = name, rank = rank, level = level, class = engClass, zone = zone,
                note = note, offNote = offNote, online = connected, status = status,
                isMobile = isMobile, guid = guid
            })
        end
    end
    guildCache.lastUpdate = GetTime()
end

-- ============================================================================
-- DATATEXT TYPES INITIALIZATION
-- ============================================================================
DT.Types = {}

-- 1. TIME
DT.Types.time = {
    Update = function(slot, config)
        local db = ns.GetDB()
        local useLocal = not db or not db.minimap or not db.minimap.clockConfig or db.minimap.clockConfig.timeFormat == "local"
        
        local h, m
        if useLocal then
            h, m = tonumber(date("%H")), tonumber(date("%M"))
        else
            h, m = GetGameTime()
        end
        
        local r, g, b = GetValueColor()
        local label = GetLabel("Time: ", "T: ", config.shortLabel, config.noLabel)
        
        local text = string.format("%s|cff%02x%02x%02x%02d:%02d|r", label, r*255, g*255, b*255, h, m)
        return text
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Time", 1, 1, 1)
        GameTooltip:AddLine(" ")
        
        local ar, ag, ab = GetValueColor()
        
        -- Lockouts
        RefreshLockoutCache()
        if #lockoutCache.instances > 0 then
            GameTooltip:AddLine("Saved Raid(s)", 1, 0.82, 0)
            for _, instance in ipairs(lockoutCache.instances) do
                local name = instance.difficultyName and string.format("%s (%s)", instance.name, instance.difficultyName) or instance.name
                GameTooltip:AddDoubleLine(name, FormatTimeRemaining(instance.reset), 0.8, 0.8, 0.8, ar, ag, ab)
            end
            GameTooltip:AddLine(" ")
        end

        if #lockoutCache.worldBosses > 0 then
            GameTooltip:AddLine("World Bosses", 1, 0.82, 0)
            for _, boss in ipairs(lockoutCache.worldBosses) do
                GameTooltip:AddDoubleLine(boss.name, FormatTimeRemaining(boss.reset), 0.8, 0.8, 0.8, ar, ag, ab)
            end
            GameTooltip:AddLine(" ")
        end

        -- Resets
        local dailyReset = C_DateAndTime.GetSecondsUntilDailyReset()
        if dailyReset and dailyReset > 0 then
            GameTooltip:AddDoubleLine("Daily Reset:", FormatTimeRemaining(dailyReset), 0.8, 0.8, 0.8, ar, ag, ab)
        end
        local weeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
        if weeklyReset and weeklyReset > 0 then
            GameTooltip:AddDoubleLine("Weekly Reset:", FormatTimeRemaining(weeklyReset), 0.8, 0.8, 0.8, ar, ag, ab)
        end

        -- Realm Time
        GameTooltip:AddDoubleLine("Realm time:", GameTime_GetGameTime(true), 0.8, 0.8, 0.8, 1, 1, 1)
        
         GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Calendar", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Toggle Clock", ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then ToggleCalendar()
        elseif button == "RightButton" then if TimeManagerFrame then TimeManagerFrame:SetShown(not TimeManagerFrame:IsShown()) end end
    end
}

-- 2. FPS / SYSTEM
DT.Types.fps = {
    Update = function(slot, config)
        local fps = math.floor(GetFramerate() + 0.5)
        local r, g, b = GetValueColor()
        if fps < 30 then r, g, b = 1, 0.2, 0.2 end
        local label = GetLabel("FPS: ", "F: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d|r", label, r*255, g*255, b*255, fps)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("System", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local _, _, home, world = GetNetStats()
        local ar, ag, ab = GetValueColor()
        GameTooltip:AddDoubleLine("Framerate:", math.floor(GetFramerate() + 0.5) .. " fps", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:AddDoubleLine("Home Latency:", (home or 0) .. " ms", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:AddDoubleLine("World Latency:", (world or 0) .. " ms", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function() end
}

-- 3. MS (Latency)
DT.Types.ms = {
    Update = function(slot, config)
        local _, _, home, world = GetNetStats()
        local ms = world or home or 0
        local r, g, b = GetValueColor()
        
        -- Color logic for MS
        local mr, mg, mb = r, g, b
        if ms > 150 then mr, mg, mb = 1, 0.4, 0.4 
        elseif ms > 100 then mr, mg, mb = 1, 1, 0.2 end
        
        local label = GetLabel("MS: ", "L: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d|r", label, mr*255, mg*255, mb*255, ms)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("System", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local _, _, home, world = GetNetStats()
        local ar, ag, ab = GetValueColor()
        GameTooltip:AddDoubleLine("Home Latency:", (home or 0) .. " ms", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:AddDoubleLine("World Latency:", (world or 0) .. " ms", 0.8, 0.8, 0.8, ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function() end
}

-- 4. GOLD
local function FormatGold(copper)
    local gold = math.floor(copper / 10000)
    local goldStr = tostring(gold)
    if gold >= 1000 then 
        goldStr = string.format("%d,%03d", math.floor(gold / 1000), gold % 1000) 
    end
    if gold >= 1000000 then 
        local millions = math.floor(gold / 1000000)
        local thousands = math.floor((gold % 1000000) / 1000)
        goldStr = string.format("%d,%03d,%03d", millions, thousands, gold % 1000)
    end
    return goldStr .. "g"
end

local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if not name or not realm then return nil end
    return string.format("%s-%s", realm, name)
end

-- (Removed redundant local function GetClassColor)

local function SaveGold()
    local key = GetCharacterKey()
    if not key then return end
    local db = ns.GetAceDB()
    if db then
        if not db.global then db.global = {} end
        if not db.global.goldData then db.global.goldData = {} end
        local _, class = UnitClass("player")
        db.global.goldData[key] = {
            money = GetMoney() or 0,
            class = class
        }
    end
end

DT.Types.gold = {
    Update = function(slot, config)
        local money = GetMoney() or 0
        local r, g, b = GetValueColor()
        local label = GetLabel("Gold: ", "G: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%s|r", label, r*255, g*255, b*255, FormatGold(money))
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Gold", 1, 1, 1)
        GameTooltip:AddLine(" ")

        local money = GetMoney() or 0
        local gold = math.floor(money / 10000)
        local silver = math.floor((money % 10000) / 100)
        local copper = money % 100
        GameTooltip:AddDoubleLine("Current:", string.format("%dg %ds %dc", gold, silver, copper), 0.8, 0.8, 0.8, 1, 1, 1)

        -- Global Characters
        local db = ns.GetAceDB()
        if db and db.global and db.global.goldData then
            local total = 0
            local list = {}
            for k, v in pairs(db.global.goldData) do
                local m = type(v) == "table" and v.money or v
                local c = type(v) == "table" and v.class or nil
                total = total + m
                table.insert(list, {key = k, money = m, class = c})
            end
            
            if #list > 1 then
                table.sort(list, function(a, b) return a.money > b.money end)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("All Characters", 1, 1, 1)
                local currentKey = GetCharacterKey()
                for _, char in ipairs(list) do
                    local cr, cg, cb = GetClassColor(char.class)
                    local name = (char.key == currentKey) and ("• " .. char.key) or char.key
                    GameTooltip:AddDoubleLine(name, FormatGold(char.money), cr, cg, cb, 1, 1, 1)
                end
                local vr, vg, vb = GetValueColor()
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Total:", FormatGold(total), vr, vg, vb, 1, 0.82, 0)
            end
        end

        -- Warbound Bank
        if C_Bank and C_Bank.FetchDepositedMoney then
            local wbMoney = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
            if wbMoney and wbMoney > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Warbound Bank", 1, 1, 1)
                GameTooltip:AddDoubleLine("Account Gold:", FormatGold(wbMoney), 0.8, 0.8, 0.8, 1, 0.82, 0)
            end
        end

        -- WoW Token
        if C_WowTokenPublic and C_WowTokenPublic.GetCurrentMarketPrice then
            local price = C_WowTokenPublic.GetCurrentMarketPrice()
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("WoW Token", 1, 1, 1)
            if price and price > 0 then
                GameTooltip:AddDoubleLine("Market Price:", FormatGold(price), 0.8, 0.8, 0.8, 1, 0.82, 0)
            else
                GameTooltip:AddDoubleLine("Market Price:", "Updating...", 0.8, 0.8, 0.8, 0.5, 0.5, 0.5)
                C_WowTokenPublic.UpdateMarketPrice()
            end
        end

        local ar, ag, ab = GetValueColor()
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Currency", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Toggle Bags", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFMiddle Click:|r Manage Characters", ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then ToggleCharacter("TokenFrame")
        elseif button == "RightButton" then ToggleAllBags()
        elseif button == "MiddleButton" then
            local db = ns.GetAceDB()
            if not db or not db.global or not db.global.goldData then return end
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle("Manage Characters")
                local currentKey = GetCharacterKey()
                for key, data in pairs(db.global.goldData) do
                    local money = type(data) == "table" and data.money or data
                    local class = type(data) == "table" and data.class or nil
                    local c = GetClassColor(class)
                    local colorCode = string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
                    local btn = root:CreateButton(colorCode .. key .. "|r - " .. FormatGold(money), function()
                        db.global.goldData[key] = nil
                        print("|cff30D1FFGravityUI:|r Removed gold data for " .. key)
                    end)
                    if key == currentKey then btn:SetEnabled(false) end
                end
                root:CreateDivider()
                root:CreateButton("|cffFF6666Reset All (Keep Current)|r", function()
                    local currentData = db.global.goldData[currentKey]
                    db.global.goldData = { [currentKey] = currentData }
                    print("|cff30D1FFGravityUI:|r Reset all gold data.")
                end)
            end)
        end
    end
}

-- ============================================================================
-- GUILD POPUP PANEL
-- ============================================================================
local guildPopup = nil

local GUILD_POPUP_WIDTH      = 460
local GUILD_POPUP_ROW_HEIGHT = 18
local GUILD_POPUP_MAX_H      = 600
local GUILD_POPUP_PAD        = 6
local GUILD_POPUP_HDR_H      = 18

-- Column x-offsets (left-to-right inside the content frame)
local GCOL_LEVEL  = 0
local GCOL_NAME   = 34
local GCOL_RANK   = 180
local GCOL_ZONE   = 260
local GCOL_NOTE   = 360

local function GetGuildFontPath()
    if ns.GetFont then
        local path, _ = ns.GetFont()
        return path
    end
    if ns.Styling and ns.Styling.GetFontPath then return ns.Styling:GetFontPath() end
    return "Fonts\\FRIZQT__.TTF"
end

local function GuildPopupHide()
    if guildPopup then guildPopup:Hide() end
end

local function GuildPopup_IsMouseOver()
    if not guildPopup or not guildPopup:IsShown() then return false end
    return guildPopup:IsMouseOver()
end

-- Creates a FontString label on a given parent
local function MakeLabel(parent, fontSize, anchor, x, y, width, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(GetGuildFontPath(), fontSize or 11, "OUTLINE")
    if anchor then fs:SetPoint("TOPLEFT", parent, anchor, x or 0, y or 0) end
    if width then fs:SetWidth(width) end
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)  -- prevent multi-line overflow
    return fs
end

-- Truncate plain text to fit a FontString's width, appending "..."
local function TruncateText(fs, text)
    if not text or text == "" then fs:SetText("") return end
    fs:SetText(text)
    if fs:GetStringWidth() <= fs:GetWidth() then return end
    -- Strip trailing chars until it fits
    local t = text
    repeat
        t = t:sub(1, -2)
        fs:SetText(t .. "...")
    until #t == 0 or fs:GetStringWidth() <= fs:GetWidth()
end

local function BuildGuildPopupFrame()
    if guildPopup then return guildPopup end

    local f = CreateFrame("Frame", "GravityUIGuildPopup", UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(200)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.72)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f:Hide()

    -- Close when mouse leaves the popup frame
    f:SetScript("OnLeave", function(self)
        C_Timer.After(0.05, function()
            if guildPopup and not guildPopup:IsMouseOver() then
                guildPopup:Hide()
            end
        end)
    end)

    -- Safety auto-close: if mouse isn't over the frame or anchor, hide after ~0.25s tick
    f:SetScript("OnShow", function(self)
        if self._ticker then self._ticker:Cancel() end
        self._ticker = C_Timer.NewTicker(0.25, function()
            local overPopup  = self:IsShown() and self:IsMouseOver()
            local overAnchor = self._anchor and self._anchor:IsMouseOver()
            if self:IsShown() and not overPopup and not overAnchor then
                self:Hide()
            end
        end)
    end)
    f:SetScript("OnHide", function(self)
        if self._ticker then
            self._ticker:Cancel()
            self._ticker = nil
        end
    end)

    -- Title bar
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(GetGuildFontPath(), 11, "OUTLINE")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", GUILD_POPUP_PAD, -GUILD_POPUP_PAD + 1)
    title:SetTextColor(1, 1, 1, 1)
    f.title = title

    -- Hint line (bottom) – refreshed each PopulateGuildPopup call so accent color stays live
    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(GetGuildFontPath(), 10, "OUTLINE")
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", GUILD_POPUP_PAD, GUILD_POPUP_PAD - 1)
    hint:SetTextColor(0.65, 0.65, 0.65, 1)
    f.hint = hint

    -- Separator line below title
    local sep = f:CreateTexture(nil, "OVERLAY")
    sep:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep:SetVertexColor(0.15, 0.15, 0.15, 1)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -(GUILD_POPUP_PAD + GUILD_POPUP_HDR_H))
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(GUILD_POPUP_PAD + GUILD_POPUP_HDR_H))
    f.sep = sep

    -- Column headers
    local hdrY = -(GUILD_POPUP_PAD + GUILD_POPUP_HDR_H + 3)
    local function MakeHdr(txt, x, w)
        local h = f:CreateFontString(nil, "OVERLAY")
        h:SetFont(GetGuildFontPath(), 9, "OUTLINE")
        h:SetPoint("TOPLEFT", f, "TOPLEFT", GUILD_POPUP_PAD + x, hdrY)
        h:SetWidth(w)
        h:SetJustifyH("LEFT")
        h:SetText(txt)
        h:SetTextColor(0.70, 0.70, 0.70, 1)
    end
    MakeHdr("Lvl",  GCOL_LEVEL, 30)
    MakeHdr("Name", GCOL_NAME,  120)
    MakeHdr("Rang", GCOL_RANK,  75)
    MakeHdr("Zone", GCOL_ZONE,  90)
    MakeHdr("Note", GCOL_NOTE,  90)

    -- Separator below headers
    local sep2 = f:CreateTexture(nil, "OVERLAY")
    sep2:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep2:SetVertexColor(0.12, 0.12, 0.12, 1)
    sep2:SetHeight(1)
    local hdrSepY = hdrY - 12
    sep2:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, hdrSepY)
    sep2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, hdrSepY)
    f.sep2 = sep2

    -- Inner content area (for rows)
    local innerTop  = -(GUILD_POPUP_PAD + GUILD_POPUP_HDR_H + 2 + 12 + 4) -- below 2nd sep
    local innerBot  = GUILD_POPUP_PAD + 14 -- above hint

    -- ScrollFrame
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     f, "TOPLEFT",     1, innerTop)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, innerBot)
    if scroll.ScrollBar then scroll.ScrollBar:Hide() end -- use scrollbar only when needed
    f.scroll = scroll

    -- Content frame (child of scroll)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(GUILD_POPUP_WIDTH - 22)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    f.content = content

    f.rows = {}

    guildPopup = f
    return f
end

local function PopulateGuildPopup(anchor)
    if not IsInGuild() then return end
    if GetTime() - guildCache.lastUpdate > 1 then BuildGuildCache() end

    local f = BuildGuildPopupFrame()
    local content = f.content
    -- Remember the rankIndex is **stored inside guildCache** via BuildGuildCache.
    -- GetGuildRosterInfo returns: name, rank, rankIndex, level, class, zone…
    -- We stored rankIndex as info.rankIndex but BuildGuildCache uses rank=rank, not rankIndex.
    -- We need to re-query rankIndex. We do that below from a re-sort pass on the existing cache.
    -- Actually BuildGuildCache stores info.rank (string) but NOT rankIndex. We'll sort by doing a
    -- fresh lightweight pass using GetGuildRosterInfo to get rankIndex per name for sorting.

    -- Build sorted list: since we don't store rankIndex separately, rebuild it here quickly.
    local sorted = {}
    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, rank, rankIndex, level, class, zone, note, _, connected, status, engClass, _, _, isMobile, _, _, guid = GetGuildRosterInfo(i)
        if name and (connected or isMobile) then
            table.insert(sorted, {
                name      = name,
                rank      = rank,
                rankIndex = rankIndex,
                level     = level,
                class     = engClass,
                zone      = zone,
                note      = note,
                online    = connected,
                status    = status,
                isMobile  = isMobile,
                guid      = guid,
            })
        end
    end
    table.sort(sorted, function(a, b)
        if a.rankIndex ~= b.rankIndex then return a.rankIndex < b.rankIndex end
        return StripMyRealm(a.name) < StripMyRealm(b.name)
    end)

    -- Set title with accent-colored online count
    local guildName = GetGuildInfo("player") or "Guild"
    local ar, ag, ab = ns.GetAccentColor()
    local accentHex = string.format("|cff%02x%02x%02x", ar*255, ag*255, ab*255)
    f.title:SetText(string.format("%s  %s(%d online)|r", guildName, accentHex, #sorted))

    -- Refresh hint text with live accent color
    f.hint:SetText(string.format(
        "|cffFFFFFFLeft-Click:|r %sWhisper|r    |cffFFFFFFRight-Click:|r %sInvite|r",
        accentHex, accentHex))

    -- Row pool: hide all, then reuse or create
    for _, row in ipairs(f.rows) do row:Hide() end

    local playerName  = UnitName("player")
    local playerRealm = GetNormalizedRealmName()
    local yOff = 0
    local innerW = content:GetWidth()

    local MAX_ROWS = GetPopupMaxRows()
    local dynamicGuildMaxH = (MAX_ROWS == math.huge)
        and GUILD_POPUP_MAX_H
        or  (GUILD_POPUP_PAD + GUILD_POPUP_HDR_H + 2 + 12 + 4 + MAX_ROWS * GUILD_POPUP_ROW_HEIGHT + GUILD_POPUP_PAD + 14 + 4)
    for i, info in ipairs(sorted) do
        local row = f.rows[i]
        if not row then
            row = CreateFrame("Button", nil, content)
            row:SetHeight(GUILD_POPUP_ROW_HEIGHT)
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            -- Hover highlight texture
            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetTexture("Interface\\Buttons\\WHITE8x8")
            hl:SetVertexColor(1, 1, 1, 0.07)
            hl:SetAllPoints()

            -- Column FontStrings per row
            row.fsLevel = MakeLabel(row, 11, "TOPLEFT", GUILD_POPUP_PAD + GCOL_LEVEL,  -2, 28)
            row.fsName  = MakeLabel(row, 12, "TOPLEFT", GUILD_POPUP_PAD + GCOL_NAME,   -2, 140)
            row.fsRank  = MakeLabel(row, 11, "TOPLEFT", GUILD_POPUP_PAD + GCOL_RANK,   -2, 74)
            row.fsZone  = MakeLabel(row, 11, "TOPLEFT", GUILD_POPUP_PAD + GCOL_ZONE,   -2, 94)
            row.fsNote  = MakeLabel(row, 11, "TOPLEFT", GUILD_POPUP_PAD + GCOL_NOTE,   -2, 94)

            row.fsRank:SetTextColor(1.0, 1.0, 1.0, 1)
            row.fsZone:SetTextColor(0.72, 0.72, 0.72, 1)
            row.fsNote:SetTextColor(0.85, 0.85, 0.55, 1)

            -- OnLeave propagation so the popup closes when leaving a row
            row:SetScript("OnLeave", function()
                C_Timer.After(0.05, function()
                    if guildPopup and not guildPopup:IsMouseOver() then
                        guildPopup:Hide()
                    end
                end)
            end)

            f.rows[i] = row
        end

        -- Fill data
        local classColor = GetClassColor(info.class)
        local levelColor = GetLevelColor(info.level)

        local lvlR = levelColor.r or 1
        local lvlG = levelColor.g or 1
        local lvlB = levelColor.b or 1

        row.fsLevel:SetText(string.format("|cff%02x%02x%02x%d|r", lvlR*255, lvlG*255, lvlB*255, info.level or 0))

        local status = info.status == 1 and " |cffFFFF00[AFK]|r" or info.status == 2 and " |cffFF4444[DND]|r" or ""
        local mobile = (info.isMobile and not info.online) and (" " .. MOBILE_ICON) or ""
        -- Show only the bare character name (no realm suffix) for cleaner display
        local displayName = StripMyRealm(info.name)
        row.fsName:SetText(string.format("|cff%02x%02x%02x%s|r%s%s",
            classColor.r*255, classColor.g*255, classColor.b*255,
            displayName, status, mobile))

        row.fsRank:SetText(info.rank or "")
        TruncateText(row.fsZone, info.zone or "")
        TruncateText(row.fsNote, (info.note and info.note ~= "") and info.note or "")

        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOff)
        row:SetWidth(innerW)
        row:Show()

        -- Click handlers (capture locals)
        local whisperName = info.name
        local inviteGuid  = info.guid
        -- Same-realm members have no "-Realm" suffix in info.name, so compare by bare name
        local isMe = StripMyRealm(info.name) == playerName
        row:SetScript("OnClick", function(self, btn)
            if isMe then return end
            if btn == "LeftButton" then
                GuildPopupHide()
                SendWhisperTo(whisperName, false)
            elseif btn == "RightButton" then
                GuildPopupHide()
                InvitePlayerToGroup(whisperName, inviteGuid, false)
            end
        end)

        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", function()
            C_Timer.After(0.05, function()
                if guildPopup and not guildPopup:IsMouseOver() then
                    guildPopup:Hide()
                end
            end)
        end)

        yOff = yOff + GUILD_POPUP_ROW_HEIGHT
    end

    content:SetHeight(math.max(1, yOff))

    -- Calculate popup height
    local hdrRegion   = GUILD_POPUP_PAD + GUILD_POPUP_HDR_H + 2 + 12 + 4  -- title + sep + col-headers + sep
    local footerH     = GUILD_POPUP_PAD + 14
    local rowAreaH    = math.min(yOff, dynamicGuildMaxH - hdrRegion - footerH)
    local totalH      = hdrRegion + rowAreaH + footerH + 4

    f:SetSize(GUILD_POPUP_WIDTH, totalH)

    -- Show/hide native scrollbar based on if content overflows
    if f.scroll.ScrollBar then
        f.scroll.ScrollBar:SetShown(yOff > rowAreaH)
    end

    -- Smart anchor: open upward if datatext is in the bottom half of the screen
    local screenH = GetScreenHeight()
    local _, anchorY = anchor:GetCenter()
    f:ClearAllPoints()
    if anchorY and (anchorY / screenH) < 0.5 then
        f:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
    else
        f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    end

    f._anchor = anchor
    f:Show()
    f:Raise()
end

-- 4. GUILD
DT.Types.guild = {
    Update = function(slot, config)
        if not IsInGuild() then return "No Guild" end
        local total, online = GetNumGuildMembers()
        local r, g, b = GetValueColor()
        local guildName = GetGuildInfo("player") or "Guild"
        local label = GetLabel(guildName .. ": ", "G: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d|r", label, r*255, g*255, b*255, online or 0)
    end,
    OnEnter = function(self)
        if not IsInGuild() then return end
        PopulateGuildPopup(self)
    end,
    OnLeave = function(self)
        -- Give a brief moment so the mouse can move into the popup without it closing
        C_Timer.After(0.1, function()
            if guildPopup and not guildPopup:IsMouseOver() then
                guildPopup:Hide()
            end
        end)
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            GuildPopupHide()
            ToggleGuildFrame()
        elseif button == "RightButton" then
            GuildPopupHide()
        end
    end,
}



-- Friends Cache
local friendsCache = {
    wowFriends = {}, bnetRetail = {}, bnetClassic = {}, bnetOther = {},
    lastUpdate = 0
}

local CLIENT_PRIORITY = { App = 1, BSAp = 1 }
local function GetClientPriority(client, wowProjectID)
    if client == BNET_CLIENT_WOW then
        return (wowProjectID == (WOW_PROJECT_ID or 1)) and 100 or 50
    end
    return CLIENT_PRIORITY[client] or 10
end

local function BuildFriendsCache()
    wipe(friendsCache.wowFriends)
    wipe(friendsCache.bnetRetail)
    wipe(friendsCache.bnetClassic)
    wipe(friendsCache.bnetOther)

    for i = 1, C_FriendList.GetNumFriends() do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.connected then
            table.insert(friendsCache.wowFriends, info)
        end
    end

    if BNConnected() then
        local seenAccounts = {}
        for i = 1, BNGetNumFriends() do
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
            if accountInfo then
                local bnetID = accountInfo.bnetAccountID
                local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i) or 0
                local foundGameAccount = false

                for y = 1, numGameAccounts do
                    local gameInfo = C_BattleNet.GetFriendGameAccountInfo(i, y)
                    if gameInfo and gameInfo.isOnline then
                        foundGameAccount = true
                        local priority = GetClientPriority(gameInfo.clientProgram, gameInfo.wowProjectID)
                        local existing = seenAccounts[bnetID]
                        if not existing or priority > existing.priority then
                            seenAccounts[bnetID] = { priority = priority, entry = gameInfo, accountName = accountInfo.accountName, note = accountInfo.note, isAFK = accountInfo.isAFK, isDND = accountInfo.isDND }
                        end
                    end
                end

                if not foundGameAccount and not seenAccounts[bnetID] then
                    local gameAccountInfo = accountInfo.gameAccountInfo
                    if gameAccountInfo and gameAccountInfo.isOnline then
                        seenAccounts[bnetID] = { priority = 1, entry = gameAccountInfo, accountName = accountInfo.accountName, note = accountInfo.note, isAFK = accountInfo.isAFK, isDND = accountInfo.isDND }
                    end
                end
            end
        end

        for _, data in pairs(seenAccounts) do
            local entry = data.entry
            entry.accountName = data.accountName
            entry.note = data.note
            entry.isAFK = data.isAFK
            entry.isDND = data.isDND
            if entry.clientProgram == BNET_CLIENT_WOW then
                if entry.wowProjectID == (WOW_PROJECT_ID or 1) then table.insert(friendsCache.bnetRetail, entry)
                else table.insert(friendsCache.bnetClassic, entry) end
            else table.insert(friendsCache.bnetOther, entry) end
        end
    end
    friendsCache.lastUpdate = GetTime()
end

-- 1. TIME (already implemented above)
-- 2. FPS / SYSTEM (already implemented above)
-- 3. GOLD (already implemented above)

-- 4. DURABILITY
DT.Types.durability = {
    Update = function(slot, config)
        local minVal = 100
        for i = 1, 18 do
            local cur, maxVal = GetInventoryItemDurability(i)
            if cur and maxVal and maxVal > 0 then
                local pct = (cur / maxVal) * 100
                if pct < minVal then minVal = pct end
            end
        end
        local r, g, b = GetValueColor()
        if minVal <= 25 then r, g, b = 1, 0.2, 0.2 elseif minVal <= 50 then r, g, b = 1, 1, 0 end
        local label = GetLabel("Durability: ", "Durability: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d%%|r", label, r*255, g*255, b*255, math.floor(minVal + 0.5))
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Durability", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local SLOT_NAMES = { [1]="Head", [3]="Shoulder", [5]="Chest", [6]="Waist", [7]="Legs", [8]="Feet", [9]="Wrist", [10]="Hands", [15]="Back", [16]="Main Hand", [17]="Off Hand" }
        for id, name in pairs(SLOT_NAMES) do
            local cur, maxVal = GetInventoryItemDurability(id)
            if cur and maxVal and maxVal > 0 then
                local pct = (cur / maxVal) * 100
                local r, g, b = 0.1, 1, 0.1
                if pct <= 25 then r, g, b = 1, 0.2, 0.2 elseif pct <= 50 then r, g, b = 1, 1, 0 end
                GameTooltip:AddDoubleLine(name, string.format("%d%%", pct), 0.8, 0.8, 0.8, r, g, b)
            end
        end
        GameTooltip:Show()
    end,
    OnClick = function() ToggleCharacter("PaperDollFrame") end
}

-- 5. GUILD (already implemented above)

-- ============================================================================
-- FRIENDS POPUP PANEL
-- ============================================================================
local friendsPopup = nil

local FPOP_WIDTH      = 480
local FPOP_ROW_HEIGHT = 18
local FPOP_MAX_H      = 600
local FPOP_PAD        = 6
local FPOP_HDR_H      = 18

-- Column x-offsets
local FCOL_LEVEL  = 0
local FCOL_NAME   = 34   -- Charname (classcolored) + (BNetName)
local FCOL_ZONE   = 270
local FCOL_NOTE   = 370

local function FriendsPopupHide()
    if friendsPopup then friendsPopup:Hide() end
end

local function BuildFriendsPopupFrame()
    if friendsPopup then return friendsPopup end

    local f = CreateFrame("Frame", "GravityUIFriendsPopup", UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(200)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.72)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f:Hide()

    f:SetScript("OnLeave", function()
        C_Timer.After(0.05, function()
            if friendsPopup and not friendsPopup:IsMouseOver() then
                friendsPopup:Hide()
            end
        end)
    end)

    -- Safety auto-close ticker: hides popup if mouse leaves without triggering OnLeave
    f:SetScript("OnShow", function(self)
        if self._ticker then self._ticker:Cancel() end
        self._ticker = C_Timer.NewTicker(0.25, function()
            local overPopup  = self:IsShown() and self:IsMouseOver()
            local overAnchor = self._anchor and self._anchor:IsMouseOver()
            if self:IsShown() and not overPopup and not overAnchor then
                self:Hide()
            end
        end)
    end)
    f:SetScript("OnHide", function(self)
        if self._ticker then
            self._ticker:Cancel()
            self._ticker = nil
        end
    end)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(GetGuildFontPath(), 11, "OUTLINE")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", FPOP_PAD, -FPOP_PAD + 1)
    title:SetTextColor(1, 1, 1, 1)
    f.title = title

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(GetGuildFontPath(), 10, "OUTLINE")
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", FPOP_PAD, FPOP_PAD - 1)
    hint:SetTextColor(0.65, 0.65, 0.65, 1)
    f.hint = hint

    local sep = f:CreateTexture(nil, "OVERLAY")
    sep:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep:SetVertexColor(0.15, 0.15, 0.15, 1)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -(FPOP_PAD + FPOP_HDR_H))
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -(FPOP_PAD + FPOP_HDR_H))

    local hdrY = -(FPOP_PAD + FPOP_HDR_H + 3)
    local function MakeHdr(txt, x, w)
        local h = f:CreateFontString(nil, "OVERLAY")
        h:SetFont(GetGuildFontPath(), 9, "OUTLINE")
        h:SetPoint("TOPLEFT", f, "TOPLEFT", FPOP_PAD + x, hdrY)
        h:SetWidth(w)
        h:SetJustifyH("LEFT")
        h:SetText(txt)
        h:SetTextColor(0.70, 0.70, 0.70, 1)
    end
    MakeHdr("Lvl",  FCOL_LEVEL, 30)
    MakeHdr("Name", FCOL_NAME,  230)
    MakeHdr("Zone", FCOL_ZONE,  94)
    MakeHdr("Note", FCOL_NOTE,  94)

    local sep2 = f:CreateTexture(nil, "OVERLAY")
    sep2:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep2:SetVertexColor(0.12, 0.12, 0.12, 1)
    sep2:SetHeight(1)
    local hdrSepY = hdrY - 12
    sep2:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, hdrSepY)
    sep2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, hdrSepY)

    local innerTop = -(FPOP_PAD + FPOP_HDR_H + 2 + 12 + 4)
    local innerBot = FPOP_PAD + 14

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     f, "TOPLEFT",     1, innerTop)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, innerBot)
    if scroll.ScrollBar then scroll.ScrollBar:Hide() end
    f.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(FPOP_WIDTH - 22)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    f.content = content

    f.rows    = {}
    f.sepTex  = {} -- section separator textures

    friendsPopup = f
    return f
end

-- Creates or reuses a row button in the friends popup
local function GetFriendRow(f, i)
    local row = f.rows[i]
    if not row then
        row = CreateFrame("Button", nil, f.content)
        row:SetHeight(FPOP_ROW_HEIGHT)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Buttons\\WHITE8x8")
        hl:SetVertexColor(1, 1, 1, 0.07)
        hl:SetAllPoints()

        row.fsLevel = MakeLabel(row, 11, "TOPLEFT", FPOP_PAD + FCOL_LEVEL, -2, 28)
        row.fsName  = MakeLabel(row, 12, "TOPLEFT", FPOP_PAD + FCOL_NAME,  -2, 230)
        row.fsZone  = MakeLabel(row, 11, "TOPLEFT", FPOP_PAD + FCOL_ZONE,  -2, 94)
        row.fsNote  = MakeLabel(row, 11, "TOPLEFT", FPOP_PAD + FCOL_NOTE,  -2, 94)

        row.fsZone:SetTextColor(0.72, 0.72, 0.72, 1)
        row.fsNote:SetTextColor(0.85, 0.85, 0.55, 1)

        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", function()
            C_Timer.After(0.05, function()
                if friendsPopup and not friendsPopup:IsMouseOver() then
                    friendsPopup:Hide()
                end
            end)
        end)

        f.rows[i] = row
    end
    return row
end

-- Section label (e.g. "WoW Friends", "Battle.net (Retail)")
local function GetSectionLabel(f, idx)
    if not f.sectionLabels then f.sectionLabels = {} end
    local lbl = f.sectionLabels[idx]
    if not lbl then
        lbl = f.content:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(GetGuildFontPath(), 10, "OUTLINE")
        lbl:SetJustifyH("LEFT")
        f.sectionLabels[idx] = lbl
    end
    return lbl
end

local function PopulateFriendsPopup(anchor)
    if GetTime() - friendsCache.lastUpdate > 1 then BuildFriendsCache() end

    local f = BuildFriendsPopupFrame()
    local content = f.content

    -- Hide all rows and section labels
    for _, row in ipairs(f.rows) do row:Hide() end
    if f.sectionLabels then
        for _, lbl in ipairs(f.sectionLabels) do lbl:Hide() end
    end

    local ar, ag, ab = ns.GetAccentColor()
    local accentHex = string.format("|cff%02x%02x%02x", ar*255, ag*255, ab*255)

    local totalCount = #friendsCache.wowFriends + #friendsCache.bnetRetail
    f.title:SetText(string.format("Friends  %s(%d online)|r", accentHex, totalCount))
    f.hint:SetText(string.format(
        "|cffFFFFFFLeft-Click:|r %sWhisper|r    |cffFFFFFFRight-Click:|r %sInvite|r",
        accentHex, accentHex))

    local innerW = content:GetWidth()
    local yOff   = 0
    local rowIdx = 0

    local SECTION_H = 14  -- height of section label row

    local MAX_ROWS = GetPopupMaxRows()
    local dynamicFriendsMaxH = (MAX_ROWS == math.huge)
        and FPOP_MAX_H
        or  (FPOP_PAD + FPOP_HDR_H + 2 + 12 + 4 + MAX_ROWS * FPOP_ROW_HEIGHT + FPOP_PAD + 14 + 4)
    local function AddRow(level, levelColor, nameText, zoneText, noteText, whisperFn, inviteFn)
        rowIdx = rowIdx + 1
        local row = GetFriendRow(f, rowIdx)

        if level and levelColor then
            row.fsLevel:SetText(string.format("|cff%02x%02x%02x%d|r",
                levelColor.r*255, levelColor.g*255, levelColor.b*255, level))
        else
            row.fsLevel:SetText("")
        end
        row.fsName:SetText(nameText or "")
        TruncateText(row.fsZone, zoneText or "")
        TruncateText(row.fsNote, noteText or "")

        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOff)
        row:SetWidth(innerW)
        row:Show()

        row:SetScript("OnClick", function(_, btn)
            if btn == "LeftButton" and whisperFn then
                FriendsPopupHide()
                whisperFn()
            elseif btn == "RightButton" and inviteFn then
                FriendsPopupHide()
                inviteFn()
            end
        end)

        yOff = yOff + FPOP_ROW_HEIGHT
    end

    local function AddSection(txt, r, g, b)
        local lbl = GetSectionLabel(f, (f._secIdx or 0) + 1)
        f._secIdx = (f._secIdx or 0) + 1
        lbl:SetPoint("TOPLEFT", content, "TOPLEFT", FPOP_PAD, -yOff)
        lbl:SetWidth(innerW)
        lbl:SetText(txt)
        lbl:SetTextColor(r or ar, g or ag, b or ab)
        lbl:Show()
        yOff = yOff + SECTION_H
    end

    f._secIdx = 0

    -- WoW Friends section
    if #friendsCache.wowFriends > 0 then
        AddSection("WoW Friends")
        for _, info in ipairs(friendsCache.wowFriends) do
            local cc = GetClassColor(info.className)
            local lc = GetLevelColor(info.level)
            local status = info.isAFK and " |cffFFFF00[AFK]|r" or info.isDND and " |cffFF4444[DND]|r" or ""
            local nameStr = string.format("|cff%02x%02x%02x%s|r%s",
                cc.r*255, cc.g*255, cc.b*255, info.name or "", status)
            local wn = info.name
            AddRow(
                info.level, lc,
                nameStr, info.area, info.notes ~= "" and info.notes or "",
                function() SendWhisperTo(wn, false) end,
                (not IsPlayerInGroup(info.name)) and
                    function() InvitePlayerToGroup(wn, nil, false) end or nil
            )
        end
    end

    -- BNet Retail section
    if #friendsCache.bnetRetail > 0 then
        if #friendsCache.wowFriends > 0 then yOff = yOff + 4 end  -- small gap
        AddSection("Battle.net (Retail)", 0.31, 0.69, 0.9)
        for _, info in ipairs(friendsCache.bnetRetail) do
            local cc = GetClassColor(info.className)
            local lc = GetLevelColor(info.characterLevel)
            local status = info.isAFK and " |cffFFFF00[AFK]|r" or info.isDND and " |cffFF4444[DND]|r" or ""
            local charPart = (info.characterName and info.characterName ~= "")
                and string.format("|cff%02x%02x%02x%s|r", cc.r*255, cc.g*255, cc.b*255, info.characterName)
                or ""
            local bnetPart = string.format("|cffffffff(%s)|r", info.accountName or "")
            local nameStr = charPart .. " " .. bnetPart .. status
            local acctName = info.accountName
            local charName = info.characterName
            local gameID   = info.gameAccountID
            AddRow(
                (info.characterLevel and info.characterLevel > 0) and info.characterLevel or nil,
                lc,
                nameStr,
                info.areaName,
                info.note ~= "" and info.note or "",
                function() SendWhisperTo(acctName, true) end,
                (charName and charName ~= "" and not IsPlayerInGroup(charName)) and
                    function() InvitePlayerToGroup(gameID, nil, true) end or nil
            )
        end
    end

    content:SetHeight(math.max(1, yOff))

    local hdrRegion = FPOP_PAD + FPOP_HDR_H + 2 + 12 + 4
    local footerH   = FPOP_PAD + 14
    local rowAreaH  = math.min(yOff, dynamicFriendsMaxH - hdrRegion - footerH)
    local totalH    = hdrRegion + rowAreaH + footerH + 4

    f:SetSize(FPOP_WIDTH, totalH)

    if f.scroll.ScrollBar then
        f.scroll.ScrollBar:SetShown(yOff > rowAreaH)
    end

    local screenH = GetScreenHeight()
    local _, anchorY = anchor:GetCenter()
    f:ClearAllPoints()
    if anchorY and (anchorY / screenH) < 0.5 then
        f:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
    else
        f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    end

    f._anchor = anchor
    f:Show()
    f:Raise()
end

-- 6. FRIENDS
DT.Types.friends = {
    Update = function(slot, config)
        if GetTime() - friendsCache.lastUpdate > 5 then BuildFriendsCache() end
        local total = #friendsCache.wowFriends + #friendsCache.bnetRetail
        local r, g, b = GetValueColor()
        local label = GetLabel("Friends: ", "Fr: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d|r", label, r*255, g*255, b*255, total)
    end,
    OnEnter = function(self)
        PopulateFriendsPopup(self)
    end,
    OnLeave = function(self)
        C_Timer.After(0.1, function()
            if friendsPopup and not friendsPopup:IsMouseOver() then
                friendsPopup:Hide()
            end
        end)
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            FriendsPopupHide()
            ToggleFriendsFrame(1)
        elseif button == "RightButton" then
            FriendsPopupHide()
        end
    end,
}


-- 7. BAGS
DT.Types.bags = {
    Update = function(slot, config)
        local free, total = 0, 0
        for i = 0, NUM_BAG_SLOTS + 1 do
            local f, t = C_Container.GetContainerNumFreeSlots(i), C_Container.GetContainerNumSlots(i)
            if t and t > 0 then free, total = free + f, total + t end
        end
        local r, g, b = GetValueColor()
        local label = GetLabel("Bags: ", "B: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%d/%d|r", label, r*255, g*255, b*255, total - free, total)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Bags", 1, 1, 1)
        GameTooltip:AddLine(" ")
        for i = 0, NUM_BAG_SLOTS + 1 do
            local t = C_Container.GetContainerNumSlots(i)
            if t and t > 0 then
                local f = C_Container.GetContainerNumFreeSlots(i)
                local name = C_Container.GetBagName(i) or (i == 0 and "Backpack" or "Bag "..i)
                local pct = (t-f)/t
                local r, g, b = 0.1, 1, 0.1
                if pct > 0.9 then r, g, b = 1, 0.1, 0.1 elseif pct > 0.75 then r, g, b = 1, 1, 0.1 end
                GameTooltip:AddDoubleLine(name, string.format("%d / %d", t-f, t), 1,1,1, r, g, b)
            end
        end
        GameTooltip:Show()
    end,
    OnClick = function() ToggleAllBags() end
}

-- 8. COORDS
DT.Types.coords = {
    Update = function(slot, config)
        local mapID = C_Map.GetBestMapForUnit("player")
        local x, y = 0, 0
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then x, y = pos:GetXY() end
        end
        local r, g, b = GetValueColor()
        local label = GetLabel("Coords: ", "C: ", config.shortLabel, config.noLabel)
        return string.format("%s|cff%02x%02x%02x%.1f, %.1f|r", label, r*255, g*255, b*255, x*100, y*100)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Coordinates", 1, 1, 1)
        GameTooltip:AddLine(GetZoneText(), 1, 1, 1)
        local sub = GetSubZoneText()
        if sub and sub ~= "" then GameTooltip:AddLine(sub, 0.7, 0.7, 0.7) end
        GameTooltip:Show()
    end,
    OnClick = function() ToggleWorldMap() end
}

-- 9. SPEC / PLAYERSPEC
DT.Types.spec = {
    Update = function(slot, config)
        local spec = GetSpecialization()
        local _, _, _, specIcon = GetSpecializationInfo(spec or 1)
        
        local lootSpec = GetLootSpecialization()
        local lootIcon
        if lootSpec == 0 then
            local _, _, _, autoIcon = GetSpecializationInfo(spec or 1)
            lootIcon = autoIcon
        else
            local _, _, _, specificIcon = GetSpecializationInfoByID(lootSpec)
            lootIcon = specificIcon
        end

        local r, g, b = GetValueColor()
        local specLabel = GetLabel("Spec: ", "S: ", config.shortLabel, config.noLabel)
        local lootLabel = GetLabel("Loot: ", "L: ", config.shortLabel, config.noLabel)
        
        local specIconText = string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t", specIcon or "")
        local lootIconText = string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t", lootIcon or "")
        
        return string.format("%s%s %s%s", specLabel, specIconText, lootLabel, lootIconText)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Specialization", 1, 1, 1)
        GameTooltip:AddLine(" ")
        local cur = GetSpecialization()
        for i = 1, GetNumSpecializations() do
            local _, name, _, icon = GetSpecializationInfo(i)
            local status = (i == cur) and " |cff00FF00(Active)|r" or ""
            GameTooltip:AddLine(string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s%s", icon, name, status), 1, 1, 1)
        end
        GameTooltip:AddLine(" ")
        local ar, ag, ab = GetValueColor()
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Switch Spec Menu", ar, ag, ab)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Change Loot Spec", ar, ag, ab)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle("Switch Specialization")
                for i = 1, GetNumSpecializations() do
                    local _, name, _, icon = GetSpecializationInfo(i)
                    root:CreateButton(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s", icon, name), function() C_SpecializationInfo.SetSpecialization(i) end)
                end
            end)
        elseif button == "RightButton" then
            MenuUtil.CreateContextMenu(self, function(_, root)
                root:CreateTitle("Loot Specialization")
                local curLoot = GetLootSpecialization()
                local _, curName = GetSpecializationInfo(GetSpecialization() or 1)
                root:CreateButton(curName .. " (Auto)" .. (curLoot == 0 and " |cff00FF00*|r" or ""), function() SetLootSpecialization(0) end)
                root:CreateDivider()
                for i = 1, GetNumSpecializations() do
                    local id, name, _, icon = GetSpecializationInfo(i)
                    root:CreateButton(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s", icon, name) .. (id == curLoot and " |cff00FF00*|r" or ""), function() SetLootSpecialization(id) end)
                end
            end)
        end
    end
}


-- ============================================================================
-- MAIN INTERFACE
-- ============================================================================

-- ============================================================================
-- LIBDATABROKER (LDB) SUPPORT
-- ============================================================================
DT.LDB_Objects = {}

local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
if LDB then
    local function RegisterLDB(name, obj)
        DT.LDB_Objects[name] = obj
        -- Signal UI to refresh if needed (e.g. if options are open)
        if ns.GUI and ns.GUI.RefreshPage then ns.GUI:RefreshPage("datapanels") end
    end

    -- Initial scan
    for name, obj in LDB:DataObjectIterator() do
        RegisterLDB(name, obj)
    end

    -- Callback for new objects
    LDB.RegisterCallback(ADDON_NAME, "LibDataBroker_DataObjectCreated", function(_, name, obj)
        RegisterLDB(name, obj)
    end)

    -- Callback for attribute changes (refresh UI when text/label changes)
    LDB.RegisterCallback(ADDON_NAME, "LibDataBroker_AttributeChanged", function(_, name, attr, value, obj)
        if attr == "text" or attr == "value" or attr == "label" then
            if ns.RefreshMinimap then ns.RefreshMinimap() end
        end
    end)
end

-- Generic LDB Wrapper
local function UpdateLDB(slot, config, hideLabelOverride)
    local name = config.content:sub(5) -- Strip "LDB:"
    local obj = DT.LDB_Objects[name]
    if not obj then return "Err: " .. name end

    local r, g, b = GetValueColor()
    local colorStr = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    
    local text = obj.text or obj.label or name
    local hide = (hideLabelOverride == true) or config.noLabel
    local label = GetLabel((obj.label or name) .. ": ", (obj.label or name):sub(1,2) .. ": ", config.shortLabel, hide)
    
    return string.format("%s%s%s|r", label, colorStr, text)
end

local function OnEnterLDB(self, config)
    local name = config.content:sub(5)
    local obj = DT.LDB_Objects[name]
    if not obj or not obj.OnEnter then return end
    obj.OnEnter(self)
end

local function OnClickLDB(self, button, config)
    local name = config.content:sub(5)
    local obj = DT.LDB_Objects[name]
    if not obj or not obj.OnClick then return end
    obj.OnClick(self, button)
end

-- ============================================================================
-- MAIN INTERFACE
-- ============================================================================

function DT:GetContentText(slot, config, hideLabelOverride)
    if not config or not config.content then return "" end
    local type = config.content
    
    -- Merge hideLabelOverride into a temporary config for individual updates
    local tempConfig = config
    if hideLabelOverride then
        tempConfig = {}
        for k, v in pairs(config) do tempConfig[k] = v end
        tempConfig.noLabel = true
    end

    -- Handle LDB
    if type:find("^LDB:") then
        return UpdateLDB(slot, tempConfig, hideLabelOverride)
    end
    
    -- Handle Internal
    if DT.Types[type] and DT.Types[type].Update then
        return DT.Types[type].Update(slot, tempConfig)
    end
    return type -- Fallback
end

function DT:HandleOnEnter(slotFrame, config)
    if not config or not config.content then return end
    local type = config.content
    
    if type:find("^LDB:") then
        OnEnterLDB(slotFrame, config)
        return
    end

    if DT.Types[type] and DT.Types[type].OnEnter then
        DT.Types[type].OnEnter(slotFrame)
    end
end

function DT:HandleOnLeave(slotFrame, config)
    GameTooltip:Hide()
    if not config or not config.content then return end
    local type = config.content
    if DT.Types[type] and DT.Types[type].OnLeave then
        DT.Types[type].OnLeave(slotFrame)
    end
end

function DT:HandleOnClick(slotFrame, button, config)
    if not config or not config.content then return end
    local type = config.content
    
    if type:find("^LDB:") then
        OnClickLDB(slotFrame, button, config)
        return
    end

    if DT.Types[type] and DT.Types[type].OnClick then
        DT.Types[type].OnClick(slotFrame, button)
    end
end

-- ============================================================================
-- INITIALIZATION & EVENT HANDLING
-- ============================================================================
local dtEvents = CreateFrame("Frame")
dtEvents:RegisterEvent("PLAYER_MONEY")
dtEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
dtEvents:RegisterEvent("PLAYER_TRADE_MONEY")
dtEvents:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
dtEvents:RegisterEvent("SEND_MAIL_COD_CHANGED")

dtEvents:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_MONEY" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TRADE_MONEY" then
        SaveGold()
    end
end)
