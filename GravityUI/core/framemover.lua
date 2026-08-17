-- GravityUI - Frame Mover Module (BlizzMove / Shifter functionality)
local ADDON_NAME, ns = ...

ns.FrameMover = ns.FrameMover or {}
local FM = ns.FrameMover

local hookedFrames = {}

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
    
    local pos = db.positions and db.positions[frameName]
    if pos and pos.point then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.xOfs or 0, pos.yOfs or 0)
    end
end

local function MakeMovable(frameName)
    if hookedFrames[frameName] then return end
    local frame = _G[frameName]
    if not frame or not frame.SetMovable then return end

    hookedFrames[frameName] = frame

    -- Determine target frame or header for dragging
    local headerName = DRAG_HEADERS[frameName]
    local handle = headerName and _G[headerName] or (frame.TitleContainer or frame)

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    handle:EnableMouse(true)

    handle:HookScript("OnMouseDown", function(self, button)
        local db = GetDB()
        if not (db and db.enabled) then return end
        if InCombatLockdown() and frame:IsProtected() then return end

        if button == "LeftButton" then
            frame:StartMoving()
            frame._isMoving = true
        elseif button == "RightButton" and IsControlKeyDown() then
            -- Ctrl + RightClick resets frame position
            local db = GetDB()
            if db and db.positions then
                db.positions[frameName] = nil
            end
            if frame.ClearAllPoints then
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
        end
    end)

    handle:HookScript("OnMouseUp", function(self, button)
        if frame._isMoving then
            frame:StopMovingOrSizing()
            frame._isMoving = false
            SavePosition(frame, frameName)
        end
    end)

    frame:HookScript("OnShow", function(self)
        C_Timer.After(0, function()
            if self:IsShown() then
                RestorePosition(self, frameName)
            end
        end)
    end)

    -- Initial position restore if currently shown
    if frame:IsShown() then
        RestorePosition(frame, frameName)
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
    if f and f.ClearAllPoints then
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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
        end
    end
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        FM.Refresh()
    elseif event == "ADDON_LOADED" then
        local frames = ADDON_FRAMES[arg1]
        if frames then
            local db = GetDB()
            if db and db.enabled then
                for _, name in ipairs(frames) do
                    MakeMovable(name)
                end
            end
        end
    end
end)
