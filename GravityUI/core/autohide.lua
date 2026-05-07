-- GravityUI - Autohide Module
local ADDON_NAME, ns = ...
local ApplyHideSettings -- Forward declaration
local lastHideForMinigame = nil -- specific state tracker for minigame logic

local function GetSettings()
    local db = ns.GetDB()
    if not db then return nil end
    if not db.uiimprovements then db.uiimprovements = {} end
    return db.uiimprovements
end

local function InitDefaults()
    local s = GetSettings()
    if not s then return end
    
    -- Ensure sub-tables exist
    if not s.hideObjectiveTrackerInstanceTypes then
        s.hideObjectiveTrackerInstanceTypes = {
            mythicPlus = false,
            mythicDungeon = false,
            normalDungeon = false,
            heroicDungeon = false,
            followerDungeon = false,
            raid = false,
            pvp = false,
            arena = false,
        }
    end
    if s.hideOnWorldQuestMinigame == nil then s.hideOnWorldQuestMinigame = false end
end

-- Helper: Check if player is in a Mythic+ dungeon (difficulty 8)
local function IsInMythicPlus()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "party" and difficulty == 8
end

-- Helper: Check if player is in a Normal dungeon (difficulty 1)
local function IsInNormalDungeon()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "party" and difficulty == 1
end

-- Helper: Check if player is in a Heroic dungeon (difficulty 2)
local function IsInHeroicDungeon()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "party" and difficulty == 2
end

-- Helper: Check if player is in a Mythic dungeon (difficulty 23, not M+)
local function IsInMythicDungeon()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "party" and difficulty == 23
end

-- Helper: Check if player is in a Follower dungeon (difficulty 205)
local function IsInFollowerDungeon()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "party" then
        return false
    end
    local _, _, difficulty = GetInstanceInfo()
    return difficulty == 205
end

-- Helper: Check if should hide objective tracker based on current instance
local function ShouldHideInCurrentInstance(instanceTypes)
    if not instanceTypes then return false end

    local inInstance, instanceType = IsInInstance()
    if not inInstance or not instanceType then return false end

    -- Special handling for "party" type: check specific dungeon difficulties
    if instanceType == "party" then
        if IsInFollowerDungeon() and instanceTypes.followerDungeon then
            return true
        elseif IsInMythicPlus() and instanceTypes.mythicPlus then
            return true
        elseif IsInMythicDungeon() and instanceTypes.mythicDungeon then
            return true
        elseif IsInNormalDungeon() and instanceTypes.normalDungeon then
            return true
        elseif IsInHeroicDungeon() and instanceTypes.heroicDungeon then
            return true
        end
    -- For other instance types, use the checkbox setting directly
    elseif instanceTypes[instanceType] then
        return true
    end

    return false
end

-- Apply hide/show commands based on saved settings
local function ApplyHideSettings()
    local settings = GetSettings()
    if not settings then return end
    
    InitDefaults() -- Ensure structure
    
    -- Objective Tracker (Quest Tracker)
    if ObjectiveTrackerFrame then
        local shouldHide = false

        -- Check if should hide always
        if settings.hideObjectiveTrackerAlways then
            shouldHide = true
        -- Check if should hide in specific instance types
        elseif ShouldHideInCurrentInstance(settings.hideObjectiveTrackerInstanceTypes) then
            shouldHide = true
        end

        if shouldHide then
            ObjectiveTrackerFrame:Hide()
            if ObjectiveTrackerFrame.SetCollapsed then
                 -- Force collapse if hiding is tricky, but usually Hide() works
                 -- ObjectiveTrackerFrame:SetCollapsed(true)
            end
            -- ObjectiveTrackerFrame:EnableMouse(false)  -- Prevent hidden frame from blocking clicks? Usually standard hide does this.
            
            -- Hook Show() to prevent Blizzard from showing it again (quest updates, boss fights, etc.)
            if not ObjectiveTrackerFrame._gui_ShowHooked then
                ObjectiveTrackerFrame._gui_ShowHooked = true
                hooksecurefunc(ObjectiveTrackerFrame, "Show", function(self)
                    local s = GetSettings()
                    if s then
                        local shouldHideNow = false
                        if s.hideObjectiveTrackerAlways then
                            shouldHideNow = true
                        elseif ShouldHideInCurrentInstance(s.hideObjectiveTrackerInstanceTypes) then
                            shouldHideNow = true
                        end

                        if shouldHideNow then
                            self:Hide()
                        end
                    end
                end)
            end
        else
            ObjectiveTrackerFrame:Show()
            -- ObjectiveTrackerFrame:EnableMouse(true)
        end
    end
    
    -- Compact Raid Frame Manager
    if CompactRaidFrameManager then
        if settings.hideRaidFrameManager then
             CompactRaidFrameManager:SetAlpha(0)
             if not InCombatLockdown() then
                 CompactRaidFrameManager:EnableMouse(false)
                 CompactRaidFrameManager:UnregisterAllEvents()
                 CompactRaidFrameManager:Hide()
             else
                 -- Queue for OOC
                 ns.QueueOOCAction(function()
                     CompactRaidFrameManager:EnableMouse(false)
                     CompactRaidFrameManager:UnregisterAllEvents()
                     CompactRaidFrameManager:Hide()
                 end)
             end
             
             -- Also hook Show and SetAlpha just in case external addons or Blizzard try to show it
             if not CompactRaidFrameManager._gui_ShowHooked then
                 CompactRaidFrameManager._gui_ShowHooked = true
                 hooksecurefunc(CompactRaidFrameManager, "Show", function(self)
                     local s = GetSettings()
                     if s and s.hideRaidFrameManager then
                         self:SetAlpha(0)
                         if not InCombatLockdown() then self:Hide() end
                     end
                 end)
                 hooksecurefunc(CompactRaidFrameManager, "SetAlpha", function(self, alpha)
                     local s = GetSettings()
                     if s and s.hideRaidFrameManager and alpha > 0 then
                         self:SetAlpha(0)
                     end
                 end)
             end
        else
            -- Restore visibility
            CompactRaidFrameManager:SetAlpha(1)
            if not InCombatLockdown() then
                 CompactRaidFrameManager:EnableMouse(true)
                 CompactRaidFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")
                 CompactRaidFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
                 CompactRaidFrameManager:Show()
            else
                 ns.QueueOOCAction(function()
                     CompactRaidFrameManager:EnableMouse(true)
                     CompactRaidFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")
                     CompactRaidFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
                     CompactRaidFrameManager:Show()
                 end)
            end
        end
    end
    
    -- Buff Frame Collapse Button
    if BuffFrame and BuffFrame.CollapseAndExpandButton then
        local btn = BuffFrame.CollapseAndExpandButton
        if settings.hideBuffCollapseButton then
            if btn.NormalTexture then btn.NormalTexture:SetAlpha(0) end
            if btn.PushedTexture then btn.PushedTexture:SetAlpha(0) end
            if btn.HighlightTexture then btn.HighlightTexture:SetAlpha(0) end
            btn:EnableMouse(false)

            if not btn._gui_AlphaHooked then
                btn._gui_AlphaHooked = true
                local function BlockAlpha(texture, alpha)
                    local s = GetSettings()
                    if s and s.hideBuffCollapseButton and alpha > 0 then
                        texture:SetAlpha(0)
                    end
                end
                if btn.NormalTexture then hooksecurefunc(btn.NormalTexture, "SetAlpha", BlockAlpha) end
                if btn.PushedTexture then hooksecurefunc(btn.PushedTexture, "SetAlpha", BlockAlpha) end
                if btn.HighlightTexture then hooksecurefunc(btn.HighlightTexture, "SetAlpha", BlockAlpha) end
            end
        else
            if btn.NormalTexture then btn.NormalTexture:SetAlpha(1) end
            if btn.PushedTexture then btn.PushedTexture:SetAlpha(1) end
            if btn.HighlightTexture then btn.HighlightTexture:SetAlpha(1) end
            btn:EnableMouse(true)
        end
    end

    -- Friendly Player Nameplates
    if settings.hideFriendlyPlayerNameplates then
        SetCVar("nameplateShowFriendlyPlayers", "0")
    end 
    -- We do NOT force it to 1 if unchecked, to respect user preference if they manually toggled it? 
    -- Logic in original was: if settings.hide then 0 else 1. I'll stick to that.
    if settings.hideFriendlyPlayerNameplates == false then -- Explicit false check
        -- Only restore if key exists? Original code did force "1".
        SetCVar("nameplateShowFriendlyPlayers", "1")
    end

    -- Friendly NPC Nameplates
    if settings.hideFriendlyNPCNameplates then
        SetCVar("nameplateShowFriendlyNPCs", "0")
    elseif settings.hideFriendlyNPCNameplates == false then
        SetCVar("nameplateShowFriendlyNPCs", "1")
    end

    -- Talking Head Frame
    if TalkingHeadFrame then
        local function DisableTalkingHeadMouse()
            TalkingHeadFrame:EnableMouse(false)
            local childrenToDisable = { "MainFrame", "PortraitFrame", "BackgroundFrame", "TextFrame", "NameFrame" }
            for _, childName in ipairs(childrenToDisable) do
                local child = TalkingHeadFrame[childName]
                if child and child.EnableMouse then child:EnableMouse(false) end
            end
        end
        local function EnableTalkingHeadMouse()
            TalkingHeadFrame:EnableMouse(true)
            local childrenToEnable = { "MainFrame", "PortraitFrame", "BackgroundFrame", "TextFrame", "NameFrame" }
            for _, childName in ipairs(childrenToEnable) do
                local child = TalkingHeadFrame[childName]
                if child and child.EnableMouse then child:EnableMouse(true) end
            end
        end

        if settings.hideTalkingHead then
            TalkingHeadFrame:Hide()
            DisableTalkingHeadMouse()
            if not TalkingHeadFrame._gui_ShowHooked then
                TalkingHeadFrame._gui_ShowHooked = true
                hooksecurefunc(TalkingHeadFrame, "Show", function(self)
                    local s = GetSettings()
                    if s and s.hideTalkingHead then
                        self:Hide()
                        DisableTalkingHeadMouse()
                    end
                end)
            end
        else
            if not TalkingHeadFrame._gui_MouseManaged then
                TalkingHeadFrame._gui_MouseManaged = true
                DisableTalkingHeadMouse()
                hooksecurefunc(TalkingHeadFrame, "PlayCurrent", EnableTalkingHeadMouse)
                TalkingHeadFrame:HookScript("OnHide", DisableTalkingHeadMouse)
            end
        end

        -- Mute Talking Head
        if not TalkingHeadFrame._gui_MuteHooked then
            TalkingHeadFrame._gui_MuteHooked = true
            hooksecurefunc(TalkingHeadFrame, "PlayCurrent", function()
                local s = GetSettings()
                if s and s.muteTalkingHead and TalkingHeadFrame.voHandle then
                    StopSound(TalkingHeadFrame.voHandle, 0)
                    TalkingHeadFrame.voHandle = nil
                end
            end)
        end
    end

    if WorldMapFrame and WorldMapFrame.BlackoutFrame then
        if settings.hideWorldMapBlackout then
            WorldMapFrame.BlackoutFrame:SetAlpha(0)
            WorldMapFrame.BlackoutFrame:EnableMouse(false)
            if not WorldMapFrame.BlackoutFrame._gui_BlackoutHooked then
                WorldMapFrame.BlackoutFrame._gui_BlackoutHooked = true
                hooksecurefunc(WorldMapFrame.BlackoutFrame, "Show", function(self)
                    local s = GetSettings()
                    if s and s.hideWorldMapBlackout then
                        self:SetAlpha(0)
                        self:EnableMouse(false)
                    end
                end)
                hooksecurefunc(WorldMapFrame.BlackoutFrame, "SetAlpha", function(self, alpha)
                    local s = GetSettings()
                    if s and s.hideWorldMapBlackout and alpha > 0 then
                        self:SetAlpha(0)
                        self:EnableMouse(false)
                    end
                end)
            end
        else
            WorldMapFrame.BlackoutFrame:SetAlpha(1)
            WorldMapFrame.BlackoutFrame:EnableMouse(true)
        end
    end

    -- Status Bars (XP & Reputation)
    if StatusTrackingBarManager then
        -- This is a bit tricky as StatusTrackingBarManager manages multiple bars.
        -- We can try to hide the specific bars if accessible or the whole manager if both are hidden.
        -- For now, let's try to set the alpha or hide specific bars if we can identify them.
        -- Standard UI usually has MainStatusTrackingBarContainer.

        local function UpdateStatusBarVisibility()
            if not StatusTrackingBarManager then return end
            
            -- If user wants to hide everything, we might hide the container
            if settings.hideXPBar and settings.hideReputationBar then
                StatusTrackingBarManager:Hide()
            else
                StatusTrackingBarManager:Show()
                -- If we want granular control, we need to target specific bars inside the manager which is complex in default UI.
                -- However, usually hiding the manager is what people want when they check these.
                -- If one is checked but not the other? 
                -- Let's stick to simple "Hide" on manager if ANY is checked? No that's bad.
                -- Let's try to hook specifically.
                
                -- Actually, usually MainStatusTrackingBarContainer is what holds them.
                -- Let's try to just hide the manager if EITHER is checked for now as a fallback, 
                -- OR if specific needs arise we can iterate. 
                -- Original GravityUI likely hid the whole StatusTrackingBarManager or MainMenuBar.
                
                -- Refined approach:
                -- If hideXPBar is true, we want to hide XP.
                -- If hideReputationBar is true, we want to hide Rep.
                -- The StatusTrackingBarManager serves both. 
                
                if settings.hideXPBar and settings.hideReputationBar then
                    StatusTrackingBarManager:Hide()
                elseif settings.hideXPBar then
                    -- If only XP is hidden, we can't easily decouple without more complex code. 
                    -- For now, let's assume if XP is hidden, we hide the manager (most common use case at max level).
                    -- If Rep is watched, it usually replaces XP or sits beside it.
                    -- Simple solution: Hide Manager if hideXPBar is set. 
                    -- But wait, Rep bar?
                    
                    -- Let's just check if both are requested or if just one.
                    -- As a safeguard for this iteration: Hide StatusTrackingBarManager if EITHER is true.
                    -- This might be "good enough" for the user request "Hide XP Bar".
                    -- If they want to see Rep but hide XP, this might be broken.
                    -- But often "Hide XP" implies "I'm max level, get this bar off my screen".
                    
                    -- Actually, let's look at the options. 
                    if settings.hideXPBar then
                        StatusTrackingBarManager:Hide()
                    end
                     if settings.hideReputationBar then
                        StatusTrackingBarManager:Hide()
                    end
                    -- If both false, show.
                    if not settings.hideXPBar and not settings.hideReputationBar then
                        StatusTrackingBarManager:Show()
                    end
                end
            end
        end
        UpdateStatusBarVisibility()
    end

    -- Error Messages (Red Text)
    if UIErrorsFrame then
        if settings.hideErrorMessages then
            UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
        else
            UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
        end
    end


    -- World Quest Minigames (Vehicle / Override Bar) -> Hide Interface
    -- World Quest Minigames (Vehicle / Override Bar) -> Hide Interface
    local inVehicle = HasOverrideActionBar() or (C_Vehicle and C_Vehicle.IsVehicleUIShowing())
    local inPetBattle = C_PetBattles and C_PetBattles.IsInBattle()
    
    -- EXCLUDE Group Content (Dungeons/Raids) from this logic to prevent taint issues with protected frames
    local inInstance, instanceType = IsInInstance()
    local isGroupContent = (instanceType == "party" or instanceType == "raid")

    local hideForMinigame = settings.hideOnWorldQuestMinigame and (inVehicle or inPetBattle) and not isGroupContent

    -- 1. Objective Tracker (Extension)
    -- We already handled ObjectiveTrackerFrame above based on instance types.
    -- Now enforce it if minigame mode is active.
    if hideForMinigame and ObjectiveTrackerFrame then
        ObjectiveTrackerFrame:Hide()
    end

    -- Optimization: If we are validly NOT in a minigame, and we weren't before, skip the heavy unitframe processing.
    -- This prevents flickering caused by redundant 'Show()' calls on events like mounting.
    if hideForMinigame == false and lastHideForMinigame == false then
        return
    end
    lastHideForMinigame = hideForMinigame

    -- UnitFrames (Player, Target, Focus)
    -- Also try to handle UnhaltedUnitFrames if present (they usually recycle these names or hook them)
    local framesToHide = {
        -- Blizzard
        PlayerFrame, TargetFrame, FocusFrame,
        CompactRaidFrameManager, 
        
        -- UnhaltedUnitFrames (UUF)
        _G["UUF_Player"], _G["UUF_Target"], _G["UUF_Focus"], 
        _G["UUF_TargetTarget"], _G["UUF_Pet"],
    }
    
    
    for _, frame in pairs(framesToHide) do
        if frame then
            -- optimization: if setting is disabled, only process if we previously hooked this frame (need to restore/cleanup)
            -- otherwise, leave it alone so we don't interfere with other addons.
            if settings.hideOnWorldQuestMinigame or frame._gui_AutohideHooked then
            
                if hideForMinigame then
                -- Method 1: Standard Hide (Combat Safe)
                if not InCombatLockdown() then
                    frame:Hide()
                end
                
                -- Method 2: Alpha (Visual Hide)
                frame:SetAlpha(0)
                
                -- Guard EnableMouse on protected frames (UnitFrames etc.)
                if not InCombatLockdown() then
                    frame:EnableMouse(false)
                else
                    ns.QueueOOCAction(function()
                        frame:EnableMouse(false)
                    end)
                end

                -- Method 3: State Driver Override (Combat Sensitive)
                if not InCombatLockdown() and frame.RegisterStateDriver then
                    -- If it's controlled by a driver, Hide() is ignored. We must unregister it.
                    UnregisterStateDriver(frame, "visibility")
                    frame:Hide() -- Try hide again after unregister
                end

                -- Method 4: Aggressive Hooking (Prevent re-show/re-alpha)
                if not frame._gui_AutohideHooked then
                    frame._gui_AutohideHooked = true
                    hooksecurefunc(frame, "Show", function(self)
                         local s = GetSettings()
                         local v = HasOverrideActionBar() or (C_Vehicle and C_Vehicle.IsVehicleUIShowing())
                         local pb = C_PetBattles and C_PetBattles.IsInBattle()
                         if s and s.hideOnWorldQuestMinigame and (v or pb) then
                             -- Alpha-only suppression: never call Hide() here.
                             -- This hook may fire from Blizzard's SecureStateDriver which runs
                             -- in a protected context — calling HideBase() on PlayerFrame etc.
                             -- causes ADDON_ACTION_BLOCKED. SetAlpha(0) is always safe.
                             self:SetAlpha(0)
                         end
                    end)
                    hooksecurefunc(frame, "SetAlpha", function(self, alpha)
                         local s = GetSettings()
                         local v = HasOverrideActionBar() or (C_Vehicle and C_Vehicle.IsVehicleUIShowing())
                         local pb = C_PetBattles and C_PetBattles.IsInBattle()
                         if s and s.hideOnWorldQuestMinigame and (v or pb) and alpha > 0 then
                             self:SetAlpha(0)
                         end
                    end)
                end
            else
                -- Restore visibility
                frame:SetAlpha(1)
                
                if not InCombatLockdown() then
                    frame:EnableMouse(true)
                else
                    ns.QueueOOCAction(function()
                        frame:EnableMouse(true)
                    end)
                end
                
                -- Debug Restore
                -- local n = frame.GetName and frame:GetName() or "Unknown"
                -- if n:find("BCDM") then print("Restoring BCDM Frame: "..n) end

                if frame == PlayerFrame then
                    -- PlayerFrame is protected: Show() is blocked in combat
                    if not InCombatLockdown() then
                        frame:Show()
                        RegisterStateDriver(frame, "visibility", "[@player,exists] show; hide")
                    else
                        ns.QueueOOCAction(function()
                            if frame and frame.Show then frame:Show() end
                            RegisterStateDriver(frame, "visibility", "[@player,exists] show; hide")
                        end)
                    end
                elseif frame == TargetFrame then
                    if not InCombatLockdown() then
                        if UnitExists("target") then frame:Show() end
                        RegisterStateDriver(frame, "visibility", "[@target,exists] show; hide")
                    else
                        ns.QueueOOCAction(function()
                            if frame and frame.Show and UnitExists("target") then frame:Show() end
                            RegisterStateDriver(frame, "visibility", "[@target,exists] show; hide")
                        end)
                    end
                elseif frame == FocusFrame then
                    if not InCombatLockdown() then
                        if UnitExists("focus") then frame:Show() end
                        RegisterStateDriver(frame, "visibility", "[@focus,exists] show; hide")
                    else
                        ns.QueueOOCAction(function()
                            if frame and frame.Show and UnitExists("focus") then frame:Show() end
                            RegisterStateDriver(frame, "visibility", "[@focus,exists] show; hide")
                        end)
                    end

                -- UUF Frames
                elseif frame.GetName and frame:GetName():find("UUF_") then
                    if not InCombatLockdown() then
                        frame:Show()
                        if frame.Update then frame:Update() end
                        if frame.RegisterStateDriver and frame == _G["UUF_Player"] then
                            RegisterStateDriver(frame, "visibility", "[@player,exists] show; hide")
                        end
                    else
                        ns.QueueOOCAction(function()
                            if frame and frame.Show then frame:Show() end
                            if frame and frame.Update then frame:Update() end
                        end)
                    end

                end
            end
            end
        end
    end
end

-- Export Refresh Function
function ns.ApplyAutohideSettings()
    ApplyHideSettings()
end


-- Event Handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("CHALLENGE_MODE_RESET")
eventFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
eventFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
eventFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
eventFrame:RegisterEvent("PET_BATTLE_CLOSE")

eventFrame:SetScript("OnEvent", function(self, event, addon)
    local settings = GetSettings()
    
    if event == "ADDON_LOADED" and addon == "Blizzard_TalkingHeadUI" then
        ApplyHideSettings()
        return
    end

    -- Minigame Detection Checks
    -- Triggers: Vehicle Enter/Exit, Override Bar Updates, Pet Battles
    if event == "UNIT_ENTERING_VEHICLE" or event == "UNIT_EXITING_VEHICLE" or 
       event == "UPDATE_OVERRIDE_ACTIONBAR" or event == "UPDATE_BONUS_ACTIONBAR" or
       event == "PET_BATTLE_OPENING_START" or event == "PET_BATTLE_CLOSE" then
        if unit and unit ~= "player" then return end -- Filter units if strictly necessary, update events don't have unit argument usually
        
        -- Delay to allow other addons to settle
        C_Timer.After(0.5, function()
             ApplyHideSettings()
        end)
        return
    end

    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
        -- Throttle roster updates
         if self.rosterUpdatePending then return end
         self.rosterUpdatePending = true
         C_Timer.After(0.5, function()
             self.rosterUpdatePending = false
             if InCombatLockdown() then return end
             ApplyHideSettings()
         end)
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        if self.zoneUpdatePending then return end
        self.zoneUpdatePending = true
        C_Timer.After(1, function()
            self.zoneUpdatePending = false
            if InCombatLockdown() then return end
            ApplyHideSettings()
        end)
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
             if not InCombatLockdown() then ApplyHideSettings() end
        end)
    else
        if not InCombatLockdown() then
             ApplyHideSettings()
        end
    end
end)

-- DEBUG COMMAND
SLASH_GRAVITYUIAUTOHIDEDEBUG1 = "/guidebug"
SlashCmdList["GRAVITYUIAUTOHIDEDEBUG"] = function()
    local inVehicle = UnitInVehicle("player")
    local hasUI = UnitHasVehicleUI("player")
    local hasBar = HasVehicleActionBar()
    local hasOverride = HasOverrideActionBar()
    local cVehicleUI = (C_Vehicle and C_Vehicle.IsVehicleUIShowing())
    
    ns.Print("Autohide Debug:")
    ns.Print("  UnitInVehicle: " .. tostring(inVehicle))
    ns.Print("  HasOverrideActionBar: " .. tostring(hasOverride))
    ns.Print("  IsVehicleUIShowing: " .. tostring(cVehicleUI))
    ns.Print("  UnitHasVehicleUI: " .. tostring(hasUI))
    
    local settings = ns.GetDB().uiimprovements
    ns.Print("  Setting Enabled: " .. tostring(settings and settings.hideOnWorldQuestMinigame))

end
