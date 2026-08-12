local ADDON_NAME, ns = ...
local LSM = LibStub("LibSharedMedia-3.0", true)

local MPlusTeleport = {}
ns.MPlusTeleport = MPlusTeleport

local libraryFrames = {}
local groupKeys = {} -- [playerName] = {mapID, level, isLeader}
local ICON_SIZE = 32
local SPACING = 4
local COLS = 10
local postRunActive = false  -- true after CHALLENGE_MODE_COMPLETED until player leaves the instance
local postRunTimer = nil     -- kept for cancellation safety only

---------------------------------------------------------------------------
-- UTILS
---------------------------------------------------------------------------
local function Print(...)
    local args = {...}
    for i=1, #args do args[i] = tostring(args[i]) end
    print("|cFF30D1FFGravityUI:|r " .. table.concat(args, " "))
end

-- Scans bags for a real |Hkeystone: item link.
-- Returns the raw API link (the ONLY format accepted by SendChatMessage in Midnight 12.0.1).
-- Uses the global string.find (not :find) matching MythicKeyAnnouncer exactly.
local function FindKeystoneItemLink()
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link and string.find(link, "|Hkeystone:", 1, true) then
                return link
            end
        end
    end
    return nil
end

local function GetOwnedKeystone()
    -- Bag Scan (Most reliable)
    -- Also returns the raw item link so !key/!keys can post a clickable |Hkeystone: link.
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and string.find(itemLink, "|Hkeystone:", 1, true) then
                local mid, lvl = itemLink:match("keystone:%d+:(%d+):(%d+)")
                if mid then return tonumber(mid), tonumber(lvl), itemLink end
            end
        end
    end
    -- API Fallback (no item link available here)
    local mid = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local lvl = C_MythicPlus.GetOwnedKeystoneLevel()
    if mid and mid > 0 then return mid, lvl, nil end
    return nil, nil, nil
end

-- Announce our own keystone to the given channel.
-- CRITICAL: WoW internally validates the "authenticity" of |Hkeystone: hyperlinks.
-- Any modification of the raw string from GetContainerItemLink (gsub, format, concat)
-- breaks this provenance check and causes SendChatMessage to strip the link to plain text.
-- The raw link MUST be sent completely unmodified via C_ChatInfo.SendChatMessage.
-- This matches KeystoneLoot's exact working implementation:
--   local link = GetContainerItemLink(bag, slot)
--   C_ChatInfo.SendChatMessage(link, channel)
local function AnnounceOwnKey(replyChannel, whisperTarget)
    local rawLink = FindKeystoneItemLink()

    if rawLink then
        -- KeystoneLoot's exact pattern: prefix text + raw link.
        -- WoW requires non-hyperlink text to precede the |Hkeystone: link
        -- in order for SendChatMessage to accept it as a clickable hyperlink.
        local msg = rawLink  -- start with just the link
        if replyChannel == "WHISPER" then
            C_ChatInfo.SendChatMessage(msg, "WHISPER", nil, whisperTarget)
        else
            C_ChatInfo.SendChatMessage(msg, replyChannel)
        end
        return true
    end

    -- No bag link — text fallback from API data only
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    if mapID and mapID > 0 and level and level > 0 then
        local dn = C_ChallengeMode.GetMapUIInfo(mapID) or "Unknown Dungeon"
        local text = string.format("Keystone: %s (%d)", dn, level)
        if replyChannel == "WHISPER" then
            C_ChatInfo.SendChatMessage(text, "WHISPER", nil, whisperTarget)
        else
            C_ChatInfo.SendChatMessage(text, replyChannel)
        end
        return true
    end

    return false
end

-- IsSpellKnown() does not reliably detect newer Midnight teleport spells (IDs 1254xxx+).
-- These are registered as player spells via a different mechanism.
local function IsTeleportKnown(spellID)
    if not spellID then return false end
    -- Primary: IsPlayerSpell covers spells granted by achievements/completions
    local ok1, r1 = pcall(IsPlayerSpell, spellID)
    if ok1 and r1 then return true end
    -- Fallback: classic spellbook check
    local ok2, r2 = pcall(IsSpellKnown, spellID)
    if ok2 and r2 then return true end
    -- Fallback: C_SpellBook usability (covers some edge cases)
    if C_SpellBook and C_SpellBook.IsSpellUsable then
        local ok3, r3 = pcall(C_SpellBook.IsSpellUsable, spellID)
        if ok3 and r3 then return true end
    end
    return false
end

local function IsEnabled()
    local db = ns.GetDB()
    return db and db.uiimprovements and db.uiimprovements.mplusTeleportEnabled ~= false
end

local function GetSettings()
    local db = ns.GetDB()
    return (db and db.uiimprovements) or {}
end

local function GetFont()
    local db = ns.GetDB()
    local fontName = (db and db.general and db.general.font) or "Gravity"
    local fontPath = LSM and LSM:Fetch("font", fontName)
    return fontPath or [[Interface\AddOns\GravityUI\media\font\Gravity.ttf]]
end

---------------------------------------------------------------------------
-- SECURE OVERLAY LOGIC (ChallengesFrame Integration)
---------------------------------------------------------------------------
local function CreateSecureOverlay(dungeonIcon)
    if not dungeonIcon or not dungeonIcon.mapID or InCombatLockdown() then return end

    local spellID = ns.DungeonData and ns.DungeonData.GetTeleportSpellID(dungeonIcon.mapID)
    if not spellID then return end

    local overlay = dungeonIcon.guiTeleportOverlay
    if not overlay then
        overlay = CreateFrame("Button", nil, dungeonIcon, "SecureActionButtonTemplate")
        overlay:SetAllPoints(dungeonIcon)
        overlay:SetFrameLevel(dungeonIcon:GetFrameLevel() + 10)
        overlay:RegisterForClicks("AnyUp", "AnyDown")

        local highlight = overlay:CreateTexture(nil, "OVERLAY")
        highlight:SetAllPoints()
        highlight:Hide()
        overlay.highlight = highlight

        -- Short-name label centered on the icon (created once on the icon, not overlay)
        if not dungeonIcon.guiShortLabel then
            local lbl = dungeonIcon:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(GetFont(), 12, "OUTLINE")
            lbl:SetPoint("CENTER", 0, 0)
            lbl:SetJustifyH("CENTER")
            lbl:SetTextColor(1, 1, 1, 1)
            dungeonIcon.guiShortLabel = lbl
        end

        overlay:SetScript("OnEnter", function(self)
            local currentSpellID = self:GetAttribute("spell")
            if not currentSpellID then return end

            if IsTeleportKnown(currentSpellID) then
                local start, duration = 0, 0
                if C_Spell and C_Spell.GetSpellCooldown then
                    local info = C_Spell.GetSpellCooldown(currentSpellID)
                    if info then start, duration = info.startTime, info.duration end
                end
                local isCooldown = false
                if start and duration then
                    local success, res = pcall(function() return duration > 1.5 end)
                    if success then isCooldown = res end
                end
                highlight:SetColorTexture(unpack(isCooldown and {1, 0.8, 0, 0.3} or {0.3, 1, 0.5, 0.3}))
            else
                highlight:SetColorTexture(1, 0.2, 0.2, 0.3)
            end
            highlight:Show()
            if dungeonIcon.OnEnter then dungeonIcon:OnEnter() end
        end)

        overlay:SetScript("OnLeave", function(self)
            highlight:Hide()
            if dungeonIcon.OnLeave then dungeonIcon:OnLeave() end
        end)

        dungeonIcon.guiTeleportOverlay = overlay
    end

    overlay:SetAttribute("type", "spell")
    overlay:SetAttribute("spell", spellID)

    -- Update label for current mapID
    local lbl = dungeonIcon.guiShortLabel
    if lbl and ns.DungeonData then
        local short = ns.DungeonData.GetShortName(dungeonIcon.mapID)
        if short then
            lbl:SetFont(GetFont(), #short > 4 and 10 or 12, "OUTLINE")
            lbl:SetText(short)
        end
    end
end


local function HookDungeonIcons()
    if not ChallengesFrame or not ChallengesFrame.DungeonIcons then return end
    for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
        if icon.mapID then CreateSecureOverlay(icon) end
    end
end

---------------------------------------------------------------------------
-- VISIBILITY & UPDATE LOGIC
---------------------------------------------------------------------------
local function UpdateButtonCooldowns(frame)
    if not frame or not frame.icons then return end
    for _, btn in ipairs(frame.icons) do
        if btn.cd and btn:GetAttribute("spell") then
            local spellID = btn:GetAttribute("spell")
            local start, duration = 0, 0
            if C_Spell and C_Spell.GetSpellCooldown then
                local info = C_Spell.GetSpellCooldown(spellID)
                if info then start, duration = info.startTime, info.duration end
            end

            local isCooldown = false
            if start and duration then
                local success, res = pcall(function() return duration > 1.5 end)
                if success then isCooldown = res end
            end

            if isCooldown then
                btn.cd:SetCooldown(start, duration)
                btn.cd:SetHideCountdownNumbers(false)
                btn.icon:SetDesaturated(true)
                btn.icon:SetAlpha(0.6)
            else
                btn.cd:Clear()
                btn.icon:SetDesaturated(false)
                btn.icon:SetAlpha((C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) or IsSpellKnown(spellID)) and 1 or 0.4)
            end
        end
    end
end

---------------------------------------------------------------------------
-- GROUP KEY LIST CONTENT
---------------------------------------------------------------------------
C_ChatInfo.RegisterAddonMessagePrefix("GravityUI")
C_ChatInfo.RegisterAddonMessagePrefix("AstralKeys")
C_ChatInfo.RegisterAddonMessagePrefix("LibKeystone")
C_ChatInfo.RegisterAddonMessagePrefix("LibKS")

-- LibKeystone integration: register a callback to receive keys from ALL players
-- using BigWigs/LittleWigs/any LibKeystone-compatible addon.
-- This fires for every group member who has any LibKeystone addon installed.
local libKeystoneRegistered = false
local function TryRegisterLibKeystone()
    if libKeystoneRegistered then return end
    local LKS = LibStub and LibStub("LibKeystone", true)
    if not LKS then return end
    LKS.Register(MPlusTeleport, function(keyLevel, keyChallengeMapID, playerRating, playerName, channel)
        if keyChallengeMapID and keyChallengeMapID > 0 and keyLevel and keyLevel > 0 then
            -- playerName from LibKeystone may include realm ("Name-Realm").
            -- Normalize to short name so groupKeys keys are consistent with
            -- what UpdateGroupKeys looks up via Ambiguate(UnitName(), "short").
            local ok, shortName = pcall(Ambiguate, playerName, "short")
            if ok and shortName and shortName ~= "" then
                groupKeys[shortName] = { mapID = keyChallengeMapID, level = keyLevel }
                MPlusTeleport:UpdateGroupKeys()
            end
        end
    end)
    libKeystoneRegistered = true
end

local lastMapID, lastLevel = nil, nil
local function BroadcastKey(force)
    if not IsInGroup() then return end
    local mapID, level = GetOwnedKeystone()
    
    if force ~= true then
        if mapID == lastMapID and level == lastLevel then return end
    end
    lastMapID, lastLevel = mapID, level

    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or (IsInRaid() and "RAID" or "PARTY")
    
    -- Request keys from others:
    -- LibKeystone handles LibKS internally after TryRegisterLibKeystone() is called.
    -- We still send LibKS "R" as a fallback for players who have LibKeystone but we registered late.
    C_ChatInfo.SendAddonMessage("AstralKeys", "request", channel)
    C_ChatInfo.SendAddonMessage("LibKS", "R", channel)
    
    -- Also use LibKeystone.Request() if available — this triggers callbacks for everyone in group
    local LKS = LibStub and LibStub("LibKeystone", true)
    if LKS and LKS.Request then
        pcall(LKS.Request, "PARTY")
    end
    
    if mapID then
        C_ChatInfo.SendAddonMessage("GravityUI", string.format("KEY:%d:%d", mapID, level), channel)
    end
end

local CHAT_CMD_EVENTS = {
    CHAT_MSG_PARTY = true, CHAT_MSG_PARTY_LEADER = true,
    CHAT_MSG_RAID = true, CHAT_MSG_RAID_LEADER = true,
    CHAT_MSG_INSTANCE_CHAT = true, CHAT_MSG_INSTANCE_CHAT_LEADER = true,
    CHAT_MSG_WHISPER = true,
}
local CHAT_CMD_REPLY = {
    CHAT_MSG_PARTY = "PARTY", CHAT_MSG_PARTY_LEADER = "PARTY",
    CHAT_MSG_RAID = "RAID", CHAT_MSG_RAID_LEADER = "RAID",
    CHAT_MSG_INSTANCE_CHAT = "INSTANCE_CHAT", CHAT_MSG_INSTANCE_CHAT_LEADER = "INSTANCE_CHAT",
    CHAT_MSG_WHISPER = "WHISPER",
}

local function HandleChatCommand(event, msg, sender)
    local s = GetSettings()
    if not s or not s.groupChatCommands then return end

    -- msg is a "secret string" (tainted by WoW engine) in chat events.
    -- Indexing a tainted string crashes (attempt to index a secret value).
    -- Use pcall to safely extract the command prefix.
    local cmd
    local ok, result = pcall(function()
        return msg and string.lower(msg):match("^(!%w+)")
    end)
    if ok then cmd = result end
    if not cmd then return end

    local replyChannel = CHAT_CMD_REPLY[event]
    if not replyChannel then return end
    local target = (replyChannel == "WHISPER") and Ambiguate(sender, "none") or nil

    local function Reply(text)
        if replyChannel == "WHISPER" then
            pcall(SendChatMessage, text, "WHISPER", nil, target)
        else
            pcall(SendChatMessage, text, replyChannel)
        end
    end

    if cmd == "!key" or cmd == "!keys" then
        -- Delegate entirely to AnnounceOwnKey which calls SendChatMessage directly.
        -- This matches the MythicKeyAnnouncer pattern: the chat event handler only
        -- extracts the command safely, the actual announce happens in a clean function
        -- scope where the item link security context is fully preserved.
        local announced = AnnounceOwnKey(replyChannel, target)
        if not announced then
            -- Only tell the player they have no key if THEY typed the command
            local isSelf = false
            pcall(function()
                local playerName = UnitName("player") or ""
                local senderShort = Ambiguate(sender, "short")
                isSelf = (senderShort == playerName or senderShort == Ambiguate(playerName, "short"))
            end)
            if isSelf then
                pcall(SendChatMessage, "[GravityUI] You have no keystone.", replyChannel == "WHISPER" and "WHISPER" or replyChannel, nil, target)
            end
        end

    elseif cmd == "!score" then
        local summary = C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary
            and C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        local rating = (summary and summary.currentSeasonScore) or 0
        Reply(string.format("[GravityUI] %s M+ Score: %d", UnitName("player"), math.floor(rating)))
    end
end

-- Returns the shared groupKeys table: [playerName] = {mapID, level}
-- Used by premadegroup.lua to populate the Premade Group dropdown.
function MPlusTeleport:GetGroupKeys()
    -- Include own keystone if available
    local myMapID, myLevel = GetOwnedKeystone()
    if myMapID then
        local myName = UnitName("player")
        if myName then
            groupKeys[myName] = { mapID = myMapID, level = myLevel }
        end
    end
    return groupKeys
end

function MPlusTeleport:UpdateGroupKeys()
    if InCombatLockdown() then
        MPlusTeleport.pendingGroupUpdate = true
        return
    end
    MPlusTeleport.pendingGroupUpdate = false
    local success, err = pcall(function()
        local frame = libraryFrames.GroupKeys
        if not frame then return end
    
        local settings = GetSettings()
        local inValidGroup
        if postRunActive then
            -- Post-run: skip instance/scenario checks — player is still inside the dungeon
            inValidGroup = IsInGroup() and not IsInRaid()
        else
            inValidGroup = IsInGroup() and not IsInRaid() and not IsInInstance() and not (C_Scenario and C_Scenario.IsInScenario())
        end
        if not (frame.isPreview or (settings.groupKeyListEnabled and inValidGroup)) then
            frame:Hide()
            return
        else
            frame:Show()
        end

        if frame.rows then for _, row in ipairs(frame.rows) do row:Hide() end end
        frame.rows = frame.rows or {}
    
        local data = {}
        if frame.isPreview then
            data = {
                { name = "Edolie", mapID = 502, level = 14, class = "PRIEST", fallback = "City of Threads" },
                { name = "Dpxhunt", mapID = 501, level = 13, class = "HUNTER", fallback = "The Stonevault" },
                { name = "Cronîx", mapID = 505, level = 12, class = "DEATHKNIGHT", isLeader = true, fallback = "The Dawnbreaker" },
                { name = "Axtn", mapID = 507, level = 13, class = "SHAMAN", fallback = "Grim Batol" },
                { name = "Antagon", mapID = 503, level = 13, class = "MONK", fallback = "Ara-Kara" },
            }
        else
            -- 1. Get Player Data
            local myMapID, myLevel = GetOwnedKeystone()
            if myMapID then
                local _, class = UnitClass("player")
                table.insert(data, { name = UnitName("player"), mapID = myMapID, level = myLevel, isLeader = UnitIsGroupLeader("player"), class = class })
            end
            -- 2. Get Group Data
            if IsInGroup() then
                local num = GetNumGroupMembers()
                for i = 1, 40 do -- Scan enough slots
                    local unit = (IsInRaid() and "raid"..i) or "party"..i
                    if i > num then break end
                    if not UnitIsUnit(unit, "player") then
                        local name = Ambiguate(UnitName(unit) or "", "short")
                        if name ~= "" then
                            local _, class = UnitClass(unit)
                            local kd = groupKeys[name]
                            -- Show all group members; kd may be nil for players without a compatible addon
                            table.insert(data, {
                                name     = name,
                                mapID    = kd and kd.mapID or nil,
                                level    = kd and kd.level or nil,
                                isLeader = UnitIsGroupLeader(unit),
                                class    = class,
                                noKey    = (kd == nil), -- true = no addon response yet
                            })
                        end
                    end
                end
            end
        end
    
        if #data == 0 then frame:Hide(); return end
    
        local yOffset = -35
        for i, info in ipairs(data) do
            local row = frame.rows[i]
            if not row then
                row = CreateFrame("Frame", nil, frame)
                row:SetSize(frame:GetWidth() - 20, 42)
                row.iconBtn = CreateFrame("Button", "GravityUI_GroupKeyIcon"..i, row, "SecureActionButtonTemplate")
                row.iconBtn:SetSize(36, 36); row.iconBtn:SetPoint("LEFT", 5, 0)
                row.iconBtn:EnableMouse(true)
                if ns.GUI and ns.GUI.CreateBackdrop then ns.GUI:CreateBackdrop(row.iconBtn, {0,0,0,0}, {1, 1, 1, 0.4}) end
                
                row.icon = row.iconBtn:CreateTexture(nil, "ARTWORK"); row.icon:SetAllPoints(); row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                row.lvlText = row.iconBtn:CreateFontString(nil, "OVERLAY"); row.lvlText:SetPoint("CENTER", 0, -1); row.lvlText:SetFont(GetFont(), 16, "OUTLINE")
                row.leaderIcon = row.iconBtn:CreateTexture(nil, "OVERLAY"); row.leaderIcon:SetSize(14, 14); row.leaderIcon:SetPoint("TOPLEFT", -2, 2); row.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
                row.dungeonName = row:CreateFontString(nil, "OVERLAY"); row.dungeonName:SetPoint("TOPLEFT", row.iconBtn, "TOPRIGHT", 10, -2); row.dungeonName:SetFont(GetFont(), 14, "OUTLINE"); row.dungeonName:SetTextColor(1, 1, 1)
                row.playerName = row:CreateFontString(nil, "OVERLAY"); row.playerName:SetPoint("TOPLEFT", row.dungeonName, "BOTTOMLEFT", 0, -1); row.playerName:SetFont(GetFont(), 12, "OUTLINE")
                
                row.iconBtn:RegisterForClicks("AnyUp", "AnyDown")
                row.iconBtn:SetScript("OnEnter", function(self)
                    if self.link then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetHyperlink(self.link)
                        GameTooltip:Show()
                    end
                end)
                row.iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                frame.rows[i] = row
            end
    
            local dungeonName, _, CMIconID = info.mapID and C_ChallengeMode.GetMapUIInfo(info.mapID) or nil
            local spellID = info.mapID and ns.DungeonData and ns.DungeonData.GetTeleportSpellID(info.mapID)
            
            -- Store link for tooltip (only if we have real keystone data)
            if info.mapID and info.level then
                row.iconBtn.link = string.format("item:180653:::::::::::::keystone:%d:%d:0:0:0:0", info.mapID, info.level)
                -- If it's the player, try to get the real bag link for better accuracy (affixes)
                if info.name == UnitName("player") then
                    for bag = 0, 4 do
                        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
                        for slot = 1, numSlots do
                            local itemLink = C_Container.GetContainerItemLink(bag, slot)
                            if itemLink and itemLink:find("keystone:") then
                                row.iconBtn.link = itemLink
                                break
                            end
                        end
                    end
                end
            else
                row.iconBtn.link = nil -- No key data available
            end

            local finalIcon = 136235 -- default: question mark / missing texture fallback
            if info.noKey then
                finalIcon = 134400 -- Interface/Icons/INV_Misc_QuestionMark — no addon
            elseif CMIconID then
                finalIcon = CMIconID
            end
            if spellID then
                local tex = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)) or (GetSpellTexture and GetSpellTexture(spellID))
                if tex then finalIcon = tex end
            end
    
            row.icon:SetTexture(finalIcon)
            row.lvlText:SetText(info.level and ("+" .. info.level) or (info.noKey and "?" or "?"))
            row.leaderIcon:SetShown(info.isLeader)
            row.dungeonName:SetText((dungeonName or info.fallback or (info.noKey and "No Addon" or "Unknown")):gsub("Operation: ", ""):gsub("Tazavesh: ", ""))
            local c = (info.class and RAID_CLASS_COLORS[info.class]) or NORMAL_FONT_COLOR
            row.playerName:SetText(info.name); row.playerName:SetTextColor(c.r, c.g, c.b)
    
            if spellID then
                row.iconBtn:SetAttribute("type", "spell"); row.iconBtn:SetAttribute("spell", spellID)
                local known = IsTeleportKnown(spellID)
                row.icon:SetDesaturated(not known); 
                row.icon:SetVertexColor(known and 1 or 0.4, known and 1 or 0.4, known and 1 or 0.4, known and 1 or 0.8)
            else
                row.iconBtn:SetAttribute("type", nil); row.icon:SetDesaturated(false); row.icon:SetVertexColor(1, 1, 1, 1)
            end
            row:SetPoint("TOPLEFT", 10, yOffset); row:Show(); yOffset = yOffset - 46
        end
        frame:SetHeight(math.abs(yOffset) + 15)
    end)
    if not success then Print("Error in UpdateGroupKeys:", err) end
end

-- Library Generation Logic Removed

function MPlusTeleport:CreateLibraryFrame(libType)
    if libraryFrames[libType] then return libraryFrames[libType] end
    local frame = CreateFrame("Frame", "GravityUI_" .. libType .. "Library", UIParent)
    frame:SetSize(300, 400)
    frame:SetFrameStrata(libType == "GroupKeys" and "BACKGROUND" or "HIGH")
    frame:SetFrameLevel(10)
    
    local r, g, b = 0.11, 0.12, 0.13
    if ns.GetThemeBgColor then r, g, b = ns.GetThemeBgColor() end
    if ns.GUI and ns.GUI.CreateBackdrop then ns.GUI:CreateBackdrop(frame, {r, g, b, 0.8}) else
        frame.bg = frame:CreateTexture(nil, "BACKGROUND"); frame.bg:SetAllPoints(); frame.bg:SetColorTexture(r, g, b, 0.8)
    end

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -8); frame.title:SetFont(GetFont(), 14, "OUTLINE"); frame.title:SetTextColor(1, 1, 1)
    frame.title:SetText(libType == "GroupKeys" and "Group Key List" or (libType .. " Library"))
    
    local settings = GetSettings()
    local posKey = libType:lower() .. "LibraryPos"
    local scaleKey = libType:lower() .. "LibraryScale"
    local lockKey = libType:lower() .. "LibraryLocked"
    local pos = settings[posKey]
    local scale = settings[scaleKey] or settings.libraryScale or 1.0
    local isLocked = settings[lockKey]

    frame:SetScale(scale)
    if pos then frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        local def = { GroupKeys = {"TOPLEFT", 100, -200} }
        frame:SetPoint(unpack(def[libType] or {"CENTER", 0, 0}))
    end

    frame:SetMovable(not isLocked); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(s) if not settings[lockKey] then s:StartMoving() end end)
    frame:SetScript("OnDragStop", function(s) 
        s:StopMovingOrSizing()
        local p, _, rp, x, y = s:GetPoint()
        settings[posKey] = {point=p, relativePoint=rp, x=x, y=y}
    end)

    -- Resizing / Scaling Logic
    local rb = CreateFrame("Button", nil, frame)
    rb:SetSize(16, 16); rb:SetPoint("BOTTOMRIGHT"); rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    rb:SetShown(libType == "GroupKeys" and not isLocked)
    
    rb:SetScript("OnMouseDown", function() 
        frame.isResizing = true 
        frame.startMouseX, frame.startMouseY = GetCursorPosition()
        frame.startScale = frame:GetScale()
    end)
    rb:SetScript("OnMouseUp", function() 
        frame.isResizing = false 
        settings[scaleKey] = frame:GetScale()
    end)
    rb:SetScript("OnUpdate", function()
        if frame.isResizing then
            local cx, cy = GetCursorPosition()
            local dx = (cx - frame.startMouseX) / frame:GetEffectiveScale()
            local newScale = frame.startScale + (dx / 200) -- Sensitivity
            newScale = math.max(0.6, math.min(1.5, newScale))
            frame:SetScale(newScale)
        end
    end)

    -- Lock & Reset Buttons (GroupKeys only)
    if libType == "GroupKeys" then
        -- Lock Button
        local lock = CreateFrame("Button", nil, frame)
        frame.lockBtn = lock
        lock:SetSize(26, 26); lock:SetPoint("TOPRIGHT", -10, -4)
        local function UpdateLockTexture()
            local locked = settings[lockKey]
            lock:SetNormalTexture(locked and "Interface\\Buttons\\LockButton-Locked-Up" or "Interface\\Buttons\\LockButton-Unlocked-Up")
            local tex = lock:GetNormalTexture()
            if tex then tex:SetDesaturated(true); tex:SetVertexColor(1, 1, 1) end
        end
        UpdateLockTexture()
        lock:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        lock:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_TOP"); GameTooltip:SetText(settings[lockKey] and "Unlock Frame" or "Lock Frame"); GameTooltip:Show() end)
        lock:SetScript("OnLeave", function() GameTooltip:Hide() end)
        lock:SetScript("OnClick", function() 
            settings[lockKey] = not settings[lockKey]
            local locked = settings[lockKey]
            frame:SetMovable(not locked)
            rb:SetShown(not locked)
            UpdateLockTexture()
            GameTooltip:SetText(locked and "Unlock Frame" or "Lock Frame")
        end)

        -- Reset Button
        local reset = CreateFrame("Button", nil, frame)
        frame.resetBtn = reset
        reset:SetSize(18, 18); reset:SetPoint("RIGHT", lock, "LEFT", -8, 0)
        reset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
        local resetTex = reset:GetNormalTexture()
        if resetTex then resetTex:SetDesaturated(true); resetTex:SetVertexColor(1, 1, 1) end
        reset:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        reset:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_TOP"); GameTooltip:SetText("Scale Reset (1.0)"); GameTooltip:Show() end)
        reset:SetScript("OnLeave", function() GameTooltip:Hide() end)
        reset:SetScript("OnClick", function() 
            frame:SetScale(1.0)
            settings[scaleKey] = 1.0
        end)
    end

    libraryFrames[libType] = frame
    if libType == "GroupKeys" then self:ApplyGroupKeyAppearance(frame) end
    return frame
end

function MPlusTeleport:ApplyGroupKeyAppearance(frame)
    frame = frame or libraryFrames.GroupKeys
    if not frame then return end
    local s = GetSettings()
    -- Background: CreateBackdrop uses SetBackdropColor directly on frame
    if frame.SetBackdropColor then
        if s.groupkeysHideBackground then
            frame:SetBackdropColor(0, 0, 0, 0)
            if frame.border then frame.border:SetAlpha(0) end
        else
            local r, g, b = 0.11, 0.12, 0.13
            if ns.GetThemeBgColor then r, g, b = ns.GetThemeBgColor() end
            frame:SetBackdropColor(r, g, b, 0.8)
            if frame.border then frame.border:SetAlpha(1) end
        end
    end
    -- Title bar (fonstring at the top) + header buttons
    local showBar = not s.groupkeysHideTitleBar
    if frame.title then frame.title:SetShown(showBar) end
    if frame.lockBtn then frame.lockBtn:SetShown(showBar) end
    if frame.resetBtn then frame.resetBtn:SetShown(showBar) end
end

---------------------------------------------------------------------------
-- PUBLIC API & EVENTS
---------------------------------------------------------------------------
function MPlusTeleport:ApplySettings()
    local s = GetSettings()
    if IsEnabled() then
        if s.groupKeyListEnabled then self:CreateLibraryFrame("GroupKeys") end
    end
    self:ApplyGroupKeyAppearance()
    -- Ensure visibility is updated based on current state after settings apply
    local gKeys = libraryFrames.GroupKeys
    if gKeys then
        local inValidGroup = postRunActive and (IsInGroup() and not IsInRaid())
            or (IsInGroup() and not IsInRaid() and not IsInInstance() and not (C_Scenario and C_Scenario.IsInScenario()))
        if IsEnabled() and (gKeys.isPreview or (s.groupKeyListEnabled and inValidGroup)) then
            gKeys:Show()
            MPlusTeleport:UpdateGroupKeys()
        else
            gKeys:Hide()
        end
    end
end

function MPlusTeleport:ToggleGroupKeyListPreview(show)
    local f = self:CreateLibraryFrame("GroupKeys"); f.isPreview = show; MPlusTeleport:UpdateGroupKeys()
end

-- Performance: Debounce SPELL_UPDATE_COOLDOWN (fires extremely frequently in instances)
local spellCDUpdatePending = false
local function ProcessCooldownUpdate()
    spellCDUpdatePending = false
    if InCombatLockdown() then return end
    for _, f in pairs(libraryFrames) do
        if f:IsShown() then UpdateButtonCooldowns(f) end
    end
    if libraryFrames.GroupKeys and libraryFrames.GroupKeys:IsShown() then MPlusTeleport:UpdateGroupKeys() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
-- Chat command events
for evt in pairs(CHAT_CMD_EVENTS) do
    eventFrame:RegisterEvent(evt)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    -- Chat command routing (highest priority, early return)
    if CHAT_CMD_EVENTS[event] then
        local msg, sender = ...
        HandleChatCommand(event, msg, sender)
        return
    end
    if event == "ADDON_LOADED" then
        local name = ...
        -- Always try to register LibKeystone when any addon loads — BigWigs may load later than GravityUI
        TryRegisterLibKeystone()
        if name == ADDON_NAME then MPlusTeleport:ApplySettings()
        elseif name == "Blizzard_ChallengesUI" then
            if ChallengesFrame then
                ChallengesFrame:HookScript("OnShow", MPlusTeleport.UpdateGroupKeys) -- Or whatever visibility logic remains
                ChallengesFrame:HookScript("OnHide", MPlusTeleport.UpdateGroupKeys)
                hooksecurefunc(ChallengesFrame, "Update", HookDungeonIcons)
                HookDungeonIcons()

                -- Great Vault Button — anchored top-right of the Mythic+ Dungeons panel
                if not ChallengesFrame._guiVaultBtn then
                    local vb = CreateFrame("Button", "GravityUI_ChallengesVaultBtn", ChallengesFrame)
                    -- Top-left corner of the frame title bar
                    vb:SetSize(120, 20)
                    vb:SetPoint("TOPLEFT", ChallengesFrame, "TOPLEFT", 8, -8)
                    vb:SetFrameLevel(ChallengesFrame:GetFrameLevel() + 20)

                    -- Backdrop (GravityUI style)
                    local bgR, bgG, bgB = 0.08, 0.09, 0.10
                    if ns.GetThemeBgColor then bgR, bgG, bgB = ns.GetThemeBgColor() end
                    if ns.GUI and ns.GUI.CreateBackdrop then
                        ns.GUI:CreateBackdrop(vb, {bgR, bgG, bgB, 0.88})
                    else
                        local vbBg = vb:CreateTexture(nil, "BACKGROUND")
                        vbBg:SetAllPoints()
                        vbBg:SetColorTexture(bgR, bgG, bgB, 0.88)
                    end

                    -- Gold left-accent bar (matches GravityUI section headers)
                    local accentR, accentG, accentB = 1, 0.82, 0
                    if ns.GetThemeColor then accentR, accentG, accentB = ns.GetThemeColor() end
                    local accent = vb:CreateTexture(nil, "BORDER", nil, 3)
                    accent:SetWidth(2)
                    accent:SetPoint("TOPLEFT",    vb, "TOPLEFT",  0, 0)
                    accent:SetPoint("BOTTOMLEFT", vb, "BOTTOMLEFT", 0, 0)
                    accent:SetColorTexture(accentR, accentG, accentB, 1)

                    -- Hover highlight overlay
                    local vbHL = vb:CreateTexture(nil, "HIGHLIGHT")
                    vbHL:SetAllPoints()
                    vbHL:SetColorTexture(1, 1, 1, 0.06)

                    -- Chest / vault icon
                    local vbIcon = vb:CreateTexture(nil, "ARTWORK")
                    vbIcon:SetSize(14, 14)
                    vbIcon:SetPoint("LEFT", vb, "LEFT", 8, 0)
                    vbIcon:SetTexture("Interface\\Icons\\inv_chest_blue")
                    vbIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                    -- Label
                    local vbText = vb:CreateFontString(nil, "OVERLAY")
                    vbText:SetFont(GetFont(), 11, "OUTLINE")
                    vbText:SetPoint("LEFT",  vbIcon, "RIGHT", 5, 0)
                    vbText:SetPoint("RIGHT", vb,     "RIGHT", -8, 0)
                    vbText:SetText("Great Vault")
                    vbText:SetTextColor(accentR, accentG, accentB, 1)

                    -- Tooltip
                    vb:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
                        GameTooltip:SetText("Great Vault", accentR, accentG, accentB)
                        GameTooltip:AddLine("Open your Weekly Vault to see\nand claim M+ rewards.", 0.8, 0.8, 0.8, true)
                        local ok, hasRewards = pcall(function()
                            return C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards
                                and C_WeeklyRewards.HasAvailableRewards()
                        end)
                        if ok and hasRewards then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine("|cff00FF00Rewards available this week!|r", 1, 1, 1)
                        end
                        GameTooltip:Show()
                    end)
                    vb:SetScript("OnLeave", function() GameTooltip:Hide() end)

                    -- Click: load addon on demand then toggle
                    vb:SetScript("OnClick", function()
                        C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
                        if WeeklyRewardsFrame then
                            if WeeklyRewardsFrame:IsShown() then
                                WeeklyRewardsFrame:Hide()
                            else
                                WeeklyRewardsFrame:Show()
                            end
                        end
                    end)

                    ChallengesFrame._guiVaultBtn = vb
                end
            end
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if not spellCDUpdatePending then
            spellCDUpdatePending = true
            C_Timer.After(0.5, ProcessCooldownUpdate)
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if libraryFrames.GroupKeys then libraryFrames.GroupKeys:Hide() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- If we have a pending post-run open (combat ended after CHALLENGE_MODE_COMPLETED), show now
        if MPlusTeleport.pendingPostRunOpen then
            MPlusTeleport.pendingPostRunOpen = false
            BroadcastKey(true)
            MPlusTeleport:UpdateGroupKeys()
        elseif not postRunActive then
            -- Normal out-of-combat restore (not a post-run transition)
            MPlusTeleport:UpdateGroupKeys()
        end
        if ChallengesFrame and ChallengesFrame.DungeonIcons then
            for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
                if icon.mapID and not icon.guiTeleportOverlay then CreateSecureOverlay(icon) end
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        BroadcastKey(true)
        MPlusTeleport:UpdateGroupKeys() -- immediate refresh with what we already know
        -- Replies from group members arrive asynchronously via CHAT_MSG_ADDON.
        -- Do a second refresh after a short delay so late replies are included.
        C_Timer.After(2, function() MPlusTeleport:UpdateGroupKeys() end)
        C_Timer.After(5, function() MPlusTeleport:UpdateGroupKeys() end)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        -- If the post-run list was showing while inside the dungeon, hide it now that the player has left.
        if postRunActive and not IsInInstance() then
            postRunActive = false
            if postRunTimer then postRunTimer:Cancel(); postRunTimer = nil end
        end
        BroadcastKey(true)
        MPlusTeleport:UpdateGroupKeys()
        C_Timer.After(2, function() MPlusTeleport:UpdateGroupKeys() end)
        C_Timer.After(5, function() MPlusTeleport:UpdateGroupKeys() end)
    elseif event == "BAG_UPDATE_DELAYED" then
        BroadcastKey(false)
        MPlusTeleport:UpdateGroupKeys()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        -- Set postRunActive immediately so the Group Key List remains visible while inside the dungeon.
        -- CRITICAL: PLAYER_REGEN_ENABLED fires BEFORE this event, so postRunActive must be
        -- set here (not on PLAYER_REGEN_ENABLED) to avoid the race condition.
        -- postRunActive is cleared in PLAYER_ENTERING_WORLD / ZONE_CHANGED_NEW_AREA once the
        -- player actually leaves the instance — no fixed timer needed anymore.
        postRunActive = true
        MPlusTeleport.pendingPostRunOpen = false -- cancel any stale pending flag
        if postRunTimer then postRunTimer:Cancel(); postRunTimer = nil end
        -- Ensure frame exists (may not have been created if player logged in while inside the instance)
        local s = GetSettings()
        if IsEnabled() and s.groupKeyListEnabled then
            MPlusTeleport:CreateLibraryFrame("GroupKeys")
        end
        -- Wait 5s (BigWigs pattern) for loot screen + keystone update, then show.
        -- If player is still in combat (rare), defer to PLAYER_REGEN_ENABLED.
        C_Timer.After(5, function()
            if InCombatLockdown() then
                MPlusTeleport.pendingPostRunOpen = true
            else
                BroadcastKey(true)
                MPlusTeleport:UpdateGroupKeys()
            end
        end)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender = ...
        if prefix == "GravityUI" or prefix == "AstralKeys" or prefix == "LibKeystone" or prefix == "LibKS" then
            local mid, lvl
            if prefix == "LibKS" then
                -- LibKS format: "keyLevel,keyChallengeMapID,playerRating"
                -- "R" = request broadcast — ignore it, we already sent "R" in BroadcastKey()
                if text == "R" then return end
                -- Parse: first number = level, second = mapID, third = rating (ignored)
                local kLevel, kMapID = text:match("^(%d+),(%d+),?%d*$")
                if kLevel and kMapID then
                    mid  = tonumber(kMapID)
                    lvl  = tonumber(kLevel)
                end
            elseif prefix == "AstralKeys" or prefix == "LibKeystone" then
                -- AstralKeys/LibKeystone embed link format: keystone:itemID:mapID:level
                mid, lvl = text:match("keystone:%d+:(%d+):(%d+)")
            else
                -- GravityUI own format: "KEY:mapID:level"
                mid, lvl = text:match("KEY:(%d+):(%d+)")
                -- Fallback: link format in case someone forwards link text
                if not mid then mid, lvl = text:match("keystone:%d+:(%d+):(%d+)") end
            end
            if mid and tonumber(mid) > 0 then
                groupKeys[Ambiguate(sender, "none")] = { mapID = tonumber(mid), level = tonumber(lvl) }
                MPlusTeleport:UpdateGroupKeys()
            end
        end
    end
end)

SLASH_GRAVITYTELEPORT1 = "/gtp"
SlashCmdList["GRAVITYTELEPORT"] = function(msg)
    if msg == "debug" then
        Print("--- Keystone Debug ---")
        
        local apiMapID, apiLevel
        pcall(function() apiMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID() end)
        pcall(function() apiLevel = C_MythicPlus.GetOwnedKeystoneLevel() end)
        
        Print("API MapID:", apiMapID)
        Print("API Level:", apiLevel)
        
        Print("Scanning Bags (legacy find)...")
        local found = false
        for bag = 0, 4 do
            local numSlots = C_Container.GetContainerNumSlots(bag) or 0
            for slot = 1, numSlots do
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                if itemLink and itemLink:find("keystone:") then
                    found = true
                    Print(string.format("Found in Bag %d, Slot %d", bag, slot))
                    local mid, lvl = itemLink:match("keystone:%d+:(%d+):(%d+)")
                    Print("Link (raw):", itemLink:gsub("|", "||"))
                    Print("Parsed:", "MapID="..tostring(mid), "Level="..tostring(lvl))
                    if mid then
                        local dungeonName = C_ChallengeMode.GetMapUIInfo(tonumber(mid))
                        Print("Reconstructed Name:", dungeonName, "(" .. lvl .. ")")
                    end
                end
            end
        end
        if not found then Print("Result: No Keystone found in bags 0-4.") end

        -- Test new FindKeystoneItemLink function
        local newLink = FindKeystoneItemLink()
        if newLink then
            Print("FindKeystoneItemLink: FOUND", newLink:gsub("|", "||"))
        else
            Print("FindKeystoneItemLink: NIL (not found with |Hkeystone: check)")
        end

        Print("--- End Debug ---")
    elseif msg == "testkey" then
        Print("Testing key announce (RAW link, KeystoneLoot-style)...")
        local rawLink = FindKeystoneItemLink()
        if rawLink then
            Print("Raw link found:", rawLink:gsub("|", "||"))
            local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT"
                or (IsInRaid() and "RAID")
                or (IsInGroup() and "PARTY")
                or nil
            if channel then
                C_ChatInfo.SendChatMessage(rawLink, channel)
                Print("Sent RAW via C_ChatInfo to", channel)
            else
                C_ChatInfo.SendChatMessage(rawLink, "SAY")
                Print("Not in group - sent RAW to SAY")
            end
        else
            Print("No keystone found in bags.")
        end
    elseif msg:match("^spell%s+(%d+)") then
        -- /gtp spell <spellID> - test all known APIs for spell detection
        local id = tonumber(msg:match("^spell%s+(%d+)"))
        Print("--- Spell API Test for ID:", id, "---")
        local ok, r
        ok, r = pcall(IsPlayerSpell, id);       Print("IsPlayerSpell:        ", tostring(r), ok and "" or "(err)")
        ok, r = pcall(IsSpellKnown, id);        Print("IsSpellKnown:         ", tostring(r), ok and "" or "(err)")
        ok, r = pcall(IsSpellKnown, id, true);  Print("IsSpellKnown(pet):    ", tostring(r), ok and "" or "(err)")
        if C_Spell then
            ok, r = pcall(C_Spell.IsSpellUsable, id); Print("C_Spell.IsSpellUsable:", tostring(r), ok and "" or "(err)")
            local info; ok, info = pcall(C_Spell.GetSpellInfo, id)
            Print("C_Spell.GetSpellInfo: ", ok and (info and info.name or "nil") or "(err)")
        end
        if C_SpellBook and C_SpellBook.IsSpellUsable then
            ok, r = pcall(C_SpellBook.IsSpellUsable, id); Print("C_SpellBook.IsSpellUsable:", tostring(r), ok and "" or "(err)")
        end
        -- Check if it appears in GetSpellCooldown (exists but might be on CD)
        ok, r = pcall(GetSpellCooldown, id)
        Print("GetSpellCooldown: ", ok and tostring(r) or "(err)")
        Print("--- End ---")
    else
        Print("Usage: /gtp debug  |  /gtp spell <spellID>")
    end
end

