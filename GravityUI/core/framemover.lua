-- GravityUI - Frame Mover Module (BlizzMove / Shifter functionality)
local ADDON_NAME, ns = ...

ns.FrameMover = ns.FrameMover or {}
local FM = ns.FrameMover

local hookedFrames = {}

-- Frames that loaded during combat and need SetMovable/SetClampedToScreen deferred
local deferredMovable = {}

-- Track which ADDON_FRAMES entries are still pending (for ADDON_LOADED cleanup)
local pendingAddons = {}

-- Re-assert guard: prevents infinite recursion on our own SetPoint writes
local ignoreSetPoint = {}

-- Forward-declare; created in the event-driven initialization section below
local eventFrame

local function GetDB()
    local db = ns.GetDB()
    if db then
        if not db.frameMover then
            db.frameMover = { enabled = true, rememberPositions = true, positions = {} }
        end
        return db.frameMover
    end
    return nil
end

---------------------------------------------------------------------------
-- FRAME REGISTRY
---------------------------------------------------------------------------
local PRELOADED_FRAMES = {
    "CharacterFrame",
    "FriendsFrame",
    "PVEFrame",
    "DressUpFrame",
    "BankFrame",
    "MailFrame",
    "GossipFrame",
    "QuestFrame",
    "MerchantFrame",
    "AddonList",
    "ChatConfigFrame",
    "ItemTextFrame",
    "LFGDungeonReadyDialog",
    "GuildInviteFrame",
    "TabardFrame",
    "GuildRegistrarFrame",
    "ReadyCheckFrame",
}

local ADDON_FRAMES = {
    ["Blizzard_AchievementUI"]                     = { "AchievementFrame" },
    ["Blizzard_AlliedRacesUI"]                     = { "AlliedRacesFrame" },
    ["Blizzard_ArchaeologyUI"]                     = { "ArchaeologyFrame" },
    ["Blizzard_ArtifactUI"]                        = { "ArtifactFrame" },
    ["Blizzard_AuctionHouseUI"]                    = { "AuctionHouseFrame" },
    ["Blizzard_BlackMarketUI"]                     = { "BlackMarketFrame" },
    ["Blizzard_Calendar"]                          = { "CalendarFrame", "CalendarViewEventFrame" },
    ["Blizzard_ChallengesUI"]                      = { "ChallengesKeystoneFrame" },
    ["Blizzard_ChromieTimeUI"]                     = { "ChromieTimeFrame" },
    ["Blizzard_ClassTalentUI"]                     = { "ClassTalentFrame" },
    ["Blizzard_Collections"]                       = { "CollectionsJournal", "WardrobeFrame" },
    ["Blizzard_Communities"]                       = { "CommunitiesFrame" },
    ["Blizzard_CooldownViewer"]                    = { "CooldownViewerSettings" },
    ["Blizzard_EncounterJournal"]                  = { "EncounterJournal" },
    ["Blizzard_ExpansionLandingPage"]              = { "ExpansionLandingPage" },
    ["Blizzard_FlightMap"]                         = { "FlightMapFrame" },
    ["Blizzard_GenericTraitUI"]                    = { "GenericTraitFrame" },
    ["Blizzard_GuildBankUI"]                       = { "GuildBankFrame" },
    ["Blizzard_GuildControlUI"]                    = { "GuildControlUI" },
    ["Blizzard_InspectUI"]                         = { "InspectFrame" },
    ["Blizzard_ItemInteractionUI"]                 = { "ItemInteractionFrame" },
    ["Blizzard_ItemSocketingUI"]                   = { "ItemSocketingFrame" },
    ["Blizzard_ItemUpgradeUI"]                     = { "ItemUpgradeFrame" },
    ["Blizzard_MacroUI"]                           = { "MacroFrame" },
    ["Blizzard_MajorFactions"]                     = { "MajorFactionRenownFrame" },
    ["Blizzard_PlayerSpells"]                      = { "PlayerSpellsFrame" },
    ["Blizzard_Professions"]                       = { "ProfessionsFrame" },
    ["Blizzard_ProfessionsBook"]                   = { "ProfessionsBookFrame" },
    ["Blizzard_ProfessionsCustomerOrders"]         = { "ProfessionsCustomerOrdersFrame" },
    ["Blizzard_ScrappingMachineUI"]                = { "ScrappingMachineFrame" },
    ["Blizzard_StableUI"]                          = { "StableFrame" },
    ["Blizzard_TokenUI"]                           = { "CurrencyTransferMenu" },
    ["Blizzard_TrainerUI"]                         = { "ClassTrainerFrame" },
    ["Blizzard_TradeSkillUI"]                      = { "TradeSkillFrame" },
    ["Blizzard_Transmog"]                          = { "TransmogFrame" },
    ["Blizzard_WeeklyRewards"]                     = { "WeeklyRewardsFrame" },
    ["Blizzard_WorldMap"]                          = { "WorldMapFrame" },
    ["Blizzard_DelvesCompanionConfigurationFrame"] = { "DelvesCompanionConfigurationFrame", "DelvesCompanionAbilityListFrame" },
    ["Blizzard_DelvesDifficultyPicker"]            = { "DelvesDifficultyPickerFrame" },
    -- Midnight Housing
    ["Blizzard_HousingDashboard"]                  = { "HousingDashboardFrame" },
    ["Blizzard_HousingCornerstone"]                = { "HousingCornerstonePurchaseFrame" },
    ["Blizzard_HousingHouseFinder"]                = { "HouseFinderFrame" },
    ["Blizzard_HousingHouseSettings"]              = { "HousingHouseSettingsFrame" },
    ["Blizzard_HousingBulletinBoard"]              = { "HousingBulletinBoardFrame" },
    ["Blizzard_HousingModelPreview"]               = { "HousingModelPreviewFrame" },
}

local DRAG_HEADERS = {
    ["WorldMapFrame"] = "WorldMapTitleButton",
}

---------------------------------------------------------------------------
-- SECURE POSITIONING (for PROTECTED frames)
--
-- A plain frame:SetPoint() / StartMoving() / SetMovable() called from
-- insecure addon code TAINTS the frame. Protected frames (PVEFrame, etc.)
-- are NEVER touched with those calls; we run ClearAllPoints/SetPoint inside
-- a SecureHandler restricted-environment snippet instead, which executes
-- securely and never taints the frame.
-- Parented to UIParent so self:GetParent() inside the snippet IS UIParent.
---------------------------------------------------------------------------
local securePositioner = CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")

local function SecureSetPoint(frame, point, relPoint, x, y)
    if InCombatLockdown() then return false end
    securePositioner:SetFrameRef("f", frame)
    securePositioner:SetAttribute("p", point)
    securePositioner:SetAttribute("rp", relPoint)
    securePositioner:SetAttribute("x", x)
    securePositioner:SetAttribute("y", y)
    securePositioner:Execute([[
        local f = self:GetFrameRef("f")
        if not f then return end
        f:ClearAllPoints()
        f:SetPoint(self:GetAttribute("p"), self:GetParent(), self:GetAttribute("rp"), self:GetAttribute("x"), self:GetAttribute("y"))
    ]])
    return true
end

---------------------------------------------------------------------------
-- HOOKING & MOVEMENT LOGIC
---------------------------------------------------------------------------
local function SavePosition(frame, frameName)
    local db = GetDB()
    if not (db and db.rememberPositions) then return end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    if point then
        db.positions[frameName] = {
            point = point,
            relativePoint = relativePoint,
            xOfs = math.floor(xOfs + 0.5),
            yOfs = math.floor(yOfs + 0.5),
        }
    end
end

local function RestorePosition(frame, frameName)
    local db = GetDB()
    if not (db and db.enabled and db.rememberPositions) then return end
    if InCombatLockdown() and frame:IsProtected() then return end
    
    local pos = db.positions and db.positions[frameName]
    if pos and pos.point then
        ignoreSetPoint[frame] = true
        if frame:IsProtected() then
            SecureSetPoint(frame, pos.point, pos.relativePoint or pos.point, pos.xOfs or 0, pos.yOfs or 0)
        else
            frame:ClearAllPoints()
            frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.xOfs or 0, pos.yOfs or 0)
        end
        ignoreSetPoint[frame] = false
    end
end

---------------------------------------------------------------------------
-- CURSOR-DELTA DRAG (for PROTECTED frames)
--
-- We can't StartMoving a protected frame without tainting it, so for those
-- we track the cursor ourselves and reposition the frame live via
-- SecureSetPoint each update. Only one protected frame can be dragged at a
-- time.
---------------------------------------------------------------------------
local secureDrag = {}  -- { frame, name, cursorX, cursorY, startX, startY, curX, curY }
local secureDragUpdater = CreateFrame("Frame")
secureDragUpdater:Hide()

local function StopSecureDrag()
    secureDragUpdater:Hide()
    local frame = secureDrag.frame
    if not frame then return end
    if secureDrag.curX then
        local db = GetDB()
        if db and db.rememberPositions then
            db.positions = db.positions or {}
            db.positions[secureDrag.name] = {
                point = "CENTER",
                relativePoint = "CENTER",
                xOfs = math.floor(secureDrag.curX + 0.5),
                yOfs = math.floor(secureDrag.curY + 0.5),
            }
        end
    end
    secureDrag.frame = nil
end

secureDragUpdater:SetScript("OnUpdate", function()
    local frame = secureDrag.frame
    if not frame then secureDragUpdater:Hide(); return end
    if InCombatLockdown() then StopSecureDrag(); return end
    local cx, cy = GetCursorPosition()
    local es = frame:GetEffectiveScale()
    local ues = UIParent:GetEffectiveScale()
    local ucx, ucy = UIParent:GetCenter()
    local newScreenX = secureDrag.startX + (cx - secureDrag.cursorX)
    local newScreenY = secureDrag.startY + (cy - secureDrag.cursorY)
    -- Keep the frame's center on screen
    local sw, sh = GetScreenWidth() * ues, GetScreenHeight() * ues
    if newScreenX < 0 then newScreenX = 0 elseif newScreenX > sw then newScreenX = sw end
    if newScreenY < 0 then newScreenY = 0 elseif newScreenY > sh then newScreenY = sh end
    local x = (newScreenX - ucx * ues) / es
    local y = (newScreenY - ucy * ues) / es
    secureDrag.curX, secureDrag.curY = x, y
    ignoreSetPoint[frame] = true
    SecureSetPoint(frame, "CENTER", "CENTER", x, y)
    ignoreSetPoint[frame] = false
end)

local function StartSecureDrag(frame, name)
    local fcx, fcy = frame:GetCenter()
    if not fcx then return end
    local es = frame:GetEffectiveScale()
    secureDrag.frame = frame
    secureDrag.name = name
    secureDrag.cursorX, secureDrag.cursorY = GetCursorPosition()
    secureDrag.startX, secureDrag.startY = fcx * es, fcy * es
    secureDrag.curX, secureDrag.curY = nil, nil
    secureDragUpdater:Show()
end

---------------------------------------------------------------------------
-- FRAME HOOKING
---------------------------------------------------------------------------
local function MakeMovable(frameName)
    if hookedFrames[frameName] then return end
    local frame = _G[frameName]
    if not frame then return end

    hookedFrames[frameName] = frame

    -- Determine target frame or header for dragging
    local headerName = DRAG_HEADERS[frameName]
    local handle = headerName and _G[headerName] or (frame.TitleContainer or frame)

    local isProtected = frame:IsProtected()

    -- P0: NEVER call SetMovable/SetClampedToScreen on protected frames.
    -- It taints the entire frame tree and causes secret-value crashes in
    -- Blizzard code (e.g. PVEFrame's LFG applicant viewer). Protected
    -- frames use cursor-delta drag via SecureHandler instead.
    if not isProtected then
        if InCombatLockdown() then
            -- P3: Combat-deferred SetMovable – queue and process on
            -- PLAYER_REGEN_ENABLED
            deferredMovable[#deferredMovable + 1] = frame
            if eventFrame then
                eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            end
        else
            frame:SetMovable(true)
            frame:SetClampedToScreen(true)
        end
    end

    if handle and handle.EnableMouse and not isProtected then
        if not InCombatLockdown() then
            handle:EnableMouse(true)
        end
    end

    if handle and handle.HookScript then
        handle:HookScript("OnMouseDown", function(self, button)
            local db = GetDB()
            if not (db and db.enabled) then return end
            if InCombatLockdown() and isProtected then return end

            if button == "LeftButton" then
                if isProtected then
                    -- P0: Use cursor-delta drag for protected frames
                    StartSecureDrag(frame, frameName)
                else
                    if InCombatLockdown() then return end
                    frame:StartMoving()
                    frame._isMoving = true
                end
            elseif button == "RightButton" and IsControlKeyDown() then
                -- Ctrl + RightClick resets frame position
                local db = GetDB()
                if db and db.positions then
                    db.positions[frameName] = nil
                end
                ignoreSetPoint[frame] = true
                if isProtected then
                    SecureSetPoint(frame, "CENTER", "CENTER", 0, 0)
                elseif frame.ClearAllPoints then
                    frame:ClearAllPoints()
                    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                end
                ignoreSetPoint[frame] = false
            end
        end)

        handle:HookScript("OnMouseUp", function(self, button)
            if isProtected then
                -- Protected frames: stop cursor-delta drag
                if secureDrag.frame == frame then StopSecureDrag() end
                return
            end
            if frame._isMoving then
                frame:StopMovingOrSizing()
                -- P1: Prevent WoW from remembering this as a user-placed frame.
                -- Without this, Blizzard's FramePositionDelegate ignores its own
                -- positioning logic and /reload can produce wrong positions.
                frame:SetUserPlaced(false)
                frame._isMoving = false
                SavePosition(frame, frameName)
            end
        end)
    end

    if frame.HookScript then
        frame:HookScript("OnShow", function(self)
            C_Timer.After(0, function()
                if self:IsShown() then
                    RestorePosition(self, frameName)
                end
            end)
        end)
    end

    -- P2: SetPoint re-assert hook – when Blizzard repositions the frame
    -- (e.g. tab switch in CollectionsJournal, docking), re-apply the saved
    -- position so the user's placement sticks.
    hooksecurefunc(frame, "SetPoint", function()
        if ignoreSetPoint[frame] then return end
        local db = GetDB()
        if not (db and db.enabled) then return end
        if InCombatLockdown() and isProtected then return end
        if frame._isMoving then return end
        if secureDrag.frame == frame then return end
        if db.positions and db.positions[frameName] then
            C_Timer.After(0, function()
                if frame:IsShown() and not frame._isMoving and secureDrag.frame ~= frame then
                    RestorePosition(frame, frameName)
                end
            end)
        end
    end)

    -- Initial position restore if currently shown
    if frame:IsShown() then
        C_Timer.After(0, function()
            if frame:IsShown() then
                RestorePosition(frame, frameName)
            end
        end)
    end
end

---------------------------------------------------------------------------
-- RESET & PUBLIC API
---------------------------------------------------------------------------
function FM.ResetAllPositions()
    local db = GetDB()
    if db then
        db.positions = {}
    end
    print("|cFF30D1FFGravityUI:|r All moved frame positions have been reset.")
end

function FM.ResetFrame(frameName)
    local db = GetDB()
    if db and db.positions then
        db.positions[frameName] = nil
    end
    local f = _G[frameName]
    if f then
        ignoreSetPoint[f] = true
        if f:IsProtected() then
            SecureSetPoint(f, "CENTER", "CENTER", 0, 0)
        elseif f.ClearAllPoints then
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        ignoreSetPoint[f] = false
    end
end

function FM.Refresh()
    local db = GetDB()
    if not (db and db.enabled) then return end

    for _, name in ipairs(PRELOADED_FRAMES) do
        MakeMovable(name)
    end

    for addon, frames in pairs(ADDON_FRAMES) do
        if C_AddOns.IsAddOnLoaded(addon) then
            for _, name in ipairs(frames) do
                MakeMovable(name)
            end
        else
            -- P4: Track pending addons for ADDON_LOADED cleanup
            pendingAddons[addon] = frames
        end
    end
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------
eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        C_Timer.After(0.1, FM.Refresh)
    elseif event == "ADDON_LOADED" then
        -- P4: Only process pending addons, unregister when all loaded
        local frames = pendingAddons[arg1]
        if frames then
            pendingAddons[arg1] = nil
            C_Timer.After(0, function()
                local db = GetDB()
                if db and db.enabled then
                    for _, name in ipairs(frames) do
                        MakeMovable(name)
                    end
                end
            end)
            if not next(pendingAddons) then
                self:UnregisterEvent("ADDON_LOADED")
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- P3: Deferred SetMovable for frames that loaded during combat
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        for i = 1, #deferredMovable do
            local f = deferredMovable[i]
            if f and not f:IsProtected() then
                f:SetMovable(true)
                f:SetClampedToScreen(true)
            end
        end
        wipe(deferredMovable)
    end
end)
