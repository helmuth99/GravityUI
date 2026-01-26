-- GravityUI - M+ Teleport Module
-- One-click teleporting from the Challenges (M+) Frame
local ADDON_NAME, ns = ...

local MPlusTeleport = {}
ns.MPlusTeleport = MPlusTeleport

local function IsEnabled()
    local db = ns.GetDB()
    if db and db.uiimprovements then
        return db.uiimprovements.mplusTeleportEnabled ~= false
    end
    return true
end

---------------------------------------------------------------------------
-- SECURE OVERLAY LOGIC
---------------------------------------------------------------------------
local function CreateSecureOverlay(dungeonIcon)
    if not dungeonIcon or not dungeonIcon.mapID then return end
    if InCombatLockdown() then return end

    -- Check if we have a teleport spell for this dungeon
    local dungeonData = ns.DungeonData
    local spellID = dungeonData and dungeonData.GetTeleportSpellID(dungeonIcon.mapID)
    
    if not spellID then return end

    -- Avoid duplicate overlays
    if dungeonIcon.guiTeleportOverlay then return end

    -- Create Secure Action Button Overlay
    local overlay = CreateFrame("Button", nil, dungeonIcon, "SecureActionButtonTemplate")
    overlay:SetAllPoints(dungeonIcon)
    overlay:SetFrameLevel(dungeonIcon:GetFrameLevel() + 10)

    overlay:SetAttribute("type", "spell")
    overlay:SetAttribute("spell", spellID)
    overlay:RegisterForClicks("AnyUp", "AnyDown")

    -- Highlight Texture
    local highlight = overlay:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.3, 1, 0.5, 0.3) -- Green highlight
    highlight:Hide()
    overlay.highlight = highlight

    -- Mouse Scripts
    overlay:SetScript("OnEnter", function(self)
        if IsSpellKnown(spellID) then
            local start, duration = 0, 0
            if C_Spell and C_Spell.GetSpellCooldown then
                local info = C_Spell.GetSpellCooldown(spellID)
                if info then
                    start = info.startTime
                    duration = info.duration
                end
            elseif GetSpellCooldown then
                start, duration = GetSpellCooldown(spellID)
            end

            if start and duration and duration > 1.5 then -- > 1.5s (GCD) means real CD
                highlight:SetColorTexture(1, 0.8, 0, 0.3) -- Yellow (Cooldown)
            else
                highlight:SetColorTexture(0.3, 1, 0.5, 0.3) -- Green (Ready)
            end
            highlight:Show()
        else
            highlight:SetColorTexture(1, 0.2, 0.2, 0.3) -- Red (Not Known)
            highlight:Show()
        end
        
        if dungeonIcon.OnEnter then
            dungeonIcon:OnEnter()
        end
    end)

    overlay:SetScript("OnLeave", function(self)
        highlight:Hide()
        if dungeonIcon.OnLeave then
            dungeonIcon:OnLeave()
        end
    end)

    dungeonIcon.guiTeleportOverlay = overlay
    return overlay
end

local function HookDungeonIcons()
    if not ChallengesFrame or not ChallengesFrame.DungeonIcons then return end

    for _, dungeonIcon in ipairs(ChallengesFrame.DungeonIcons) do
        if dungeonIcon.mapID then
            CreateSecureOverlay(dungeonIcon)
        end
    end
end

local function OnChallengesFrameUpdate()
    if not IsEnabled() then return end
    -- Retail Safety: Use pcall and type checks for line texticons have their mapIDs populated
    C_Timer.After(0.1, HookDungeonIcons)
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local hooked = false

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_ChallengesUI" then
        if not hooked and ChallengesFrame then
            hooksecurefunc(ChallengesFrame, "Update", OnChallengesFrameUpdate)
            hooked = true
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- If already loaded
if C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
    if not hooked and ChallengesFrame then
        hooksecurefunc(ChallengesFrame, "Update", OnChallengesFrameUpdate)
        hooked = true
    end
end
