local ADDON_NAME, ns = ...
local LSM = LibStub("LibSharedMedia-3.0", true)

local MPlusTeleport = {}
ns.MPlusTeleport = MPlusTeleport

local libraryFrames = {}
local groupKeys = {} -- [playerName] = {mapID, level, isLeader}
local ICON_SIZE = 32
local SPACING = 4
local COLS = 10

---------------------------------------------------------------------------
-- UTILS
---------------------------------------------------------------------------
local function Print(...)
    local args = {...}
    for i=1, #args do args[i] = tostring(args[i]) end
    print("|cFF30D1FFGravityUI:|r " .. table.concat(args, " "))
end

local function GetOwnedKeystone()
    -- Bag Scan (Most reliable)
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and itemLink:find("keystone:") then
                local mid, lvl = itemLink:match("keystone:%d+:(%d+):(%d+)")
                if mid then return tonumber(mid), tonumber(lvl) end
            end
        end
    end
    -- API Fallback
    local mid = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local lvl = C_MythicPlus.GetOwnedKeystoneLevel()
    if mid and mid > 0 then return mid, lvl end
    return nil, nil
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
    if not dungeonIcon or not dungeonIcon.mapID or InCombatLockdown() or dungeonIcon.guiTeleportOverlay then return end

    local spellID = ns.DungeonData and ns.DungeonData.GetTeleportSpellID(dungeonIcon.mapID)
    if not spellID then return end

    local overlay = CreateFrame("Button", nil, dungeonIcon, "SecureActionButtonTemplate")
    overlay:SetAllPoints(dungeonIcon)
    overlay:SetFrameLevel(dungeonIcon:GetFrameLevel() + 10)
    overlay:SetAttribute("type", "spell")
    overlay:SetAttribute("spell", spellID)
    overlay:RegisterForClicks("AnyUp", "AnyDown")

    local highlight = overlay:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints()
    highlight:Hide()
    overlay.highlight = highlight

    overlay:SetScript("OnEnter", function(self)
        if IsSpellKnown(spellID) then
            local start, duration = 0, 0
            if C_Spell and C_Spell.GetSpellCooldown then
                local info = C_Spell.GetSpellCooldown(spellID)
                if info then start, duration = info.startTime, info.duration end
            else
                start, duration = GetSpellCooldown(spellID)
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
            else
                start, duration = GetSpellCooldown(spellID)
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
                btn.icon:SetAlpha(IsSpellKnown(spellID) and 1 or 0.4)
            end
        end
    end
end

local function UpdateLibraryVisibility()
    if InCombatLockdown() then return end
    local settings = GetSettings()
    local challengesOpen = ChallengesFrame and ChallengesFrame:IsVisible()
    local inValidGroup = IsInGroup() and not IsInRaid() and not IsInInstance() and not (C_Scenario and C_Scenario.IsInScenario())

    if libraryFrames.Dungeon then
        local show = IsEnabled() and challengesOpen and settings.dungeonLibraryEnabled
        libraryFrames.Dungeon:SetShown(show)
        if show then UpdateButtonCooldowns(libraryFrames.Dungeon) end
    end
    if libraryFrames.Raid then
        local show = IsEnabled() and challengesOpen and settings.raidLibraryEnabled
        libraryFrames.Raid:SetShown(show)
        if show then UpdateButtonCooldowns(libraryFrames.Raid) end
    end
    
    local gKeys = libraryFrames.GroupKeys
    if gKeys then
        if IsEnabled() and (gKeys.isPreview or (settings.groupKeyListEnabled and inValidGroup)) then
            gKeys:Show()
            MPlusTeleport:UpdateGroupKeys()
        else
            gKeys:Hide()
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

local lastMapID, lastLevel = nil, nil
local function BroadcastKey(force)
    if not IsInGroup() then return end
    local mapID, level = GetOwnedKeystone()
    
    if force ~= true then
        if mapID == lastMapID and level == lastLevel then return end
    end
    lastMapID, lastLevel = mapID, level

    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or (IsInRaid() and "RAID" or "PARTY")
    
    -- Request keys from others (AstralKeys/LibKeystone support)
    C_ChatInfo.SendAddonMessage("AstralKeys", "request", channel)
    C_ChatInfo.SendAddonMessage("LibKS", "R", channel)
    
    if mapID then
        C_ChatInfo.SendAddonMessage("GravityUI", string.format("KEY:%d:%d", mapID, level), channel)
    end
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
        local inValidGroup = IsInGroup() and not IsInRaid() and not IsInInstance() and not (C_Scenario and C_Scenario.IsInScenario())
        if not (frame.isPreview or (settings.groupKeyListEnabled and inValidGroup)) then
            frame:Hide()
            return
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
                        local name = Ambiguate(UnitName(unit) or "", "none")
                        if name ~= "" and groupKeys[name] then
                            local _, class = UnitClass(unit)
                            table.insert(data, { name = name, mapID = groupKeys[name].mapID, level = groupKeys[name].level, isLeader = UnitIsGroupLeader(unit), class = class })
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
    
            local dungeonName, _, CMIconID = C_ChallengeMode.GetMapUIInfo(info.mapID)
            local spellID = ns.DungeonData and ns.DungeonData.GetTeleportSpellID(info.mapID)
            
            -- Store link for tooltip
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

            local finalIcon = 136235
            if CMIconID then finalIcon = CMIconID end
            if spellID then
                local tex = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)) or (GetSpellTexture and GetSpellTexture(spellID))
                if tex then finalIcon = tex end
            end
    
            row.icon:SetTexture(finalIcon)
            row.lvlText:SetText("+" .. (info.level or "?"))
            row.leaderIcon:SetShown(info.isLeader)
            row.dungeonName:SetText((dungeonName or info.fallback or "Unknown"):gsub("Operation: ", ""):gsub("Tazavesh: ", ""))
            local c = (info.class and RAID_CLASS_COLORS[info.class]) or NORMAL_FONT_COLOR
            row.playerName:SetText(info.name); row.playerName:SetTextColor(c.r, c.g, c.b)
    
            if spellID then
                row.iconBtn:SetAttribute("type", "spell"); row.iconBtn:SetAttribute("spell", spellID)
                local known = IsSpellKnown(spellID)
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

---------------------------------------------------------------------------
-- LIBRARY GENERATION
---------------------------------------------------------------------------
function MPlusTeleport:RefreshLibrary(libType)
    local frame = libraryFrames[libType]
    if not frame or libType == "GroupKeys" or InCombatLockdown() then return end

    local data = (libType == "Dungeon") and ns.TeleportData.Dungeons or ns.TeleportData.Raids
    local settings = GetSettings()
    local expansions = (libType == "Dungeon") and settings.dungeonLibraryExpansions or settings.raidLibraryExpansions

    if frame.icons then for _, i in ipairs(frame.icons) do i:Hide() end end
    if frame.headers then for _, h in ipairs(frame.headers) do h:Hide() end end
    frame.icons, frame.headers = frame.icons or {}, frame.headers or {}

    local iconIdx, headIdx, yOffset, absoluteMaxWidth = 1, 1, -40, 0
    for _, expData in ipairs(ns.TeleportData.Expansions) do
        local expName = expData.name
        if (expansions[expName] ~= false) and data[expName] then
            local header = frame.headers[headIdx] or frame:CreateFontString(nil, "OVERLAY")
            header:SetFont(GetFont(), 11, "OUTLINE"); header:SetTextColor(0, 0.8, 1); header:SetText(expName); header:SetPoint("TOPLEFT", 15, yOffset); header:Show()
            frame.headers[headIdx], headIdx, yOffset = header, headIdx + 1, yOffset - 20

            local col, rowH = 0, ICON_SIZE + 25
            for _, spellGroup in ipairs(data[expName]) do
                local btn = frame.icons[iconIdx] or CreateFrame("Button", "GravityUI_"..libType.."Icon"..iconIdx, frame, "SecureActionButtonTemplate")
                btn:SetSize(ICON_SIZE, ICON_SIZE); btn:SetAttribute("type", "spell"); btn:SetAttribute("spell", spellGroup.spellID); btn:RegisterForClicks("AnyUp", "AnyDown")
                btn:EnableMouse(true)
                if not btn.icon then 
                    btn.icon = btn:CreateTexture(nil, "ARTWORK"); btn.icon:SetAllPoints(); btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate"); btn.cd:SetAllPoints(); btn.cd:SetDrawEdge(false)
                    btn.text = btn:CreateFontString(nil, "OVERLAY"); btn.text:SetPoint("BOTTOM", 0, -12); btn.text:SetFont(GetFont(), 10, "OUTLINE")
                    if ns.GUI and ns.GUI.SkinIcon then ns.GUI:SkinIcon(btn) end
                    btn:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:SetSpellByID(spellGroup.spellID); GameTooltip:Show() end)
                    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
                btn:SetPoint("TOPLEFT", 15 + (col * (ICON_SIZE + SPACING + 5)), yOffset); btn:Show()
                btn.text:SetText(spellGroup.name or "?")
                
                local icon = 136235
                if C_Spell and C_Spell.GetSpellTexture then
                    icon = C_Spell.GetSpellTexture(spellGroup.spellID) or icon
                elseif GetSpellTexture then
                    icon = GetSpellTexture(spellGroup.spellID) or icon
                end
                btn.icon:SetTexture(icon)

                local known = IsSpellKnown(spellGroup.spellID)
                btn.icon:SetVertexColor(known and 1 or 0.25, known and 1 or 0.25, known and 1 or 0.25, known and 1 or 0.8)
                frame.icons[iconIdx], iconIdx, col = btn, iconIdx + 1, col + 1
                if col >= COLS then col, yOffset = 0, yOffset - rowH end
            end
            if col > 0 then yOffset = yOffset - rowH end
            local expW = 30 + (math.min(iconIdx-1, COLS) * (ICON_SIZE + SPACING + 5))
            if expW > absoluteMaxWidth then absoluteMaxWidth = expW end
            yOffset = yOffset - 15
        end
    end
    frame:SetScale(settings.libraryScale or 1.0); frame:SetSize(math.max(absoluteMaxWidth, 200), math.abs(yOffset) + 10)
    UpdateLibraryVisibility()
end

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
        local def = { Dungeon = {"CENTER", -150, 0}, Raid = {"CENTER", 150, 0}, GroupKeys = {"TOPLEFT", 100, -200} }
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
    if libType ~= "GroupKeys" then self:RefreshLibrary(libType) end
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
        if s.dungeonLibraryEnabled then self:CreateLibraryFrame("Dungeon") end
        if s.raidLibraryEnabled then self:CreateLibraryFrame("Raid") end
        if s.groupKeyListEnabled then self:CreateLibraryFrame("GroupKeys") end
    end
    self:ApplyGroupKeyAppearance()
    UpdateLibraryVisibility()
end

function MPlusTeleport:ToggleGroupKeyListPreview(show)
    local f = self:CreateLibraryFrame("GroupKeys"); f.isPreview = show; UpdateLibraryVisibility()
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
eventFrame:RegisterEvent("ADDON_LOADED"); eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN"); eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE"); eventFrame:RegisterEvent("CHAT_MSG_ADDON"); eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD"); eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED"); eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED"); eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then MPlusTeleport:ApplySettings()
        elseif name == "Blizzard_ChallengesUI" then
            ChallengesFrame:HookScript("OnShow", UpdateLibraryVisibility); ChallengesFrame:HookScript("OnHide", UpdateLibraryVisibility)
            hooksecurefunc(ChallengesFrame, "Update", HookDungeonIcons); HookDungeonIcons(); UpdateLibraryVisibility()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        -- Performance: Debounce - SPELL_UPDATE_COOLDOWN fires for every spell/item CD in game
        if not spellCDUpdatePending then
            spellCDUpdatePending = true
            C_Timer.After(0.5, ProcessCooldownUpdate)
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        for _, f in pairs(libraryFrames) do f:Hide() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateLibraryVisibility()
        if MPlusTeleport.pendingGroupUpdate and libraryFrames.GroupKeys then
            MPlusTeleport:UpdateGroupKeys()
        end
        if ChallengesFrame and ChallengesFrame.DungeonIcons then
            for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
                if icon.mapID and not icon.guiTeleportOverlay then CreateSecureOverlay(icon) end
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        BroadcastKey(true); UpdateLibraryVisibility()
    elseif event == "BAG_UPDATE_DELAYED" or event == "CHALLENGE_MODE_COMPLETED" then
        BroadcastKey(false); UpdateLibraryVisibility()
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, _, sender = ...
        if prefix == "GravityUI" or prefix == "AstralKeys" or prefix == "LibKeystone" or prefix == "LibKS" then
            local mid, lvl
            
            -- LibKeystone/BigWigs format: "level,mapID,rating"
            if prefix == "LibKS" and text ~= "R" then
                local kLevel, kMapID = text:match("^(%d+),(%d+),")
                if kLevel and kMapID then
                    mid, lvl = kMapID, kLevel
                end
            else
                mid, lvl = text:match("keystone:%d+:(%d+):(%d+)") -- Sniff for links
                if not mid then mid, lvl = text:match("KEY:(%d+):(%d+)") end -- Sniff for our format
            end
            
            if mid and tonumber(mid) > 0 then
                groupKeys[Ambiguate(sender, "none")] = { mapID = tonumber(mid), level = tonumber(lvl) }; MPlusTeleport:UpdateGroupKeys()
            end
        end
    end
end)

SLASH_GRAVITYTELEPORT1 = "/gtp"
SlashCmdList["GRAVITYTELEPORT"] = function(msg)
    if msg == "dungeon" or msg == "raid" then
        local f = MPlusTeleport:CreateLibraryFrame(msg == "dungeon" and "Dungeon" or "Raid")
        f:SetShown(not f:IsShown())
    elseif msg == "debug" then
        Print("--- Keystone Debug ---")
        
        local apiMapID, apiLevel
        pcall(function() apiMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID() end)
        pcall(function() apiLevel = C_MythicPlus.GetOwnedKeystoneLevel() end)
        
        Print("API MapID:", apiMapID)
        Print("API Level:", apiLevel)
        
        Print("Scanning Bags...")
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
                        -- Reconstruct simple text name (since we removed GetKeystoneLink)
                        local dungeonName = C_ChallengeMode.GetMapUIInfo(tonumber(mid))
                        Print("Reconstructed Name:", dungeonName, "(" .. lvl .. ")")
                    end
                end
            end
        end
        if not found then Print("Result: No Keystone found in bags 0-4.") end
        Print("--- End Debug ---")
    else Print("Usage: /gtp dungeon | raid | debug") end
end
