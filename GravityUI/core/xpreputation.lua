local ADDON_NAME, ns = ...
local LCG = LibStub("LibCustomGlow-1.0", true)
local LSM = LibStub("LibSharedMedia-3.0", true)

ns.XPRep = {}
local XPRep = ns.XPRep

-- Upvalues
local UnitXP, UnitXPMax = UnitXP, UnitXPMax
-- local GetWatchedFactionInfo = GetWatchedFactionInfo -- Deprecated
local C_Reputation = C_Reputation
local C_MajorFactions = C_MajorFactions
local GetXPExhaustion = GetXPExhaustion

-- Constants
local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
}

function XPRep:Initialize()
    if self.initialized then return end
    
    self.db = ns.db.profile.styling.xpRep
    if not self.db.enabled then return end

    self:CreateContainer()
    self:CreateBars()
    self:RegisterMover()
    
    self:RegisterEvents()
    
    self.initialized = true
    self:Refresh()
    
    -- Force a second update after a slight delay to ensure DB is fully loaded and UI settled
    C_Timer.After(1, function() 
        self:Update() 
    end)
end

function XPRep:CreateContainer()
    self.frame = CreateFrame("Frame", "GravityUI_XPRep_Frame", UIParent)
    self.frame:SetSize(self.db.width, self.db.height)
    local pos = self.db.position or { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 0 }
    self.frame:SetPoint(pos.point or "BOTTOM", UIParent, pos.relativePoint or pos.point or "BOTTOM", pos.x or 0, pos.y or 0)
    self.frame:SetFrameStrata("LOW")
    self.frame:SetMovable(true)
    self.frame:SetClampedToScreen(true)

    self.frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local cx, cy = f:GetCenter()
        local ucy = (UIParent:GetHeight() or 1080) / 2
        local scx = UIParent:GetCenter() or 0
        local x = math.floor((cx - scx) + 0.5)
        
        if cy and cy < ucy then
            -- Lower half of screen: Anchor to BOTTOM
            local bottom = math.floor((f:GetBottom() or 0) + 0.5)
            self.db.position = { point = "BOTTOM", relativePoint = "BOTTOM", x = x, y = bottom }
            f:ClearAllPoints()
            f:SetPoint("BOTTOM", UIParent, "BOTTOM", x, bottom)
        else
            -- Upper half of screen: Anchor to TOP
            local top = f:GetTop() or 0
            local uTop = UIParent:GetTop() or UIParent:GetHeight() or 1080
            local y = math.floor((top - uTop) + 0.5)
            self.db.position = { point = "TOP", relativePoint = "TOP", x = x, y = y }
            f:ClearAllPoints()
            f:SetPoint("TOP", UIParent, "TOP", x, y)
        end
        XPRep:Update()
    end)
end

function XPRep:CreateBars()
    -- XP Bar
    self.xpBar = CreateFrame("StatusBar", nil, self.frame, "BackdropTemplate")
    self.xpBar:SetAllPoints() -- Will adjust based on visibility
    self.xpBar:SetBackdrop(BACKDROP)
    self.xpBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    self.xpBar:SetBackdropBorderColor(0, 0, 0, 1)
    
    self.xpBar.text = self.xpBar:CreateFontString(nil, "OVERLAY")
    self.xpBar.text:SetPoint("CENTER")
    
    -- Rep Bar
    self.repBar = CreateFrame("StatusBar", nil, self.frame, "BackdropTemplate")
    self.repBar:SetAllPoints() -- Will adjust
    self.repBar:SetBackdrop(BACKDROP)
    self.repBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    self.repBar:SetBackdropBorderColor(0, 0, 0, 1)
    
    self.repBar.text = self.repBar:CreateFontString(nil, "OVERLAY")
    self.repBar.text:SetPoint("CENTER")
end

function XPRep:Update()
    if not self.db then return end
    
    if not self.db.enabled then 
        if self.frame then self.frame:Hide() end
        return 
    end
    
    if self.db.alwaysHide and not self.preview then
        if self.frame then self.frame:Hide() end
        return
    end

    self.frame:Show()

    local showXP = (self.db.showXP and UnitLevel("player") < GetMaxLevelForPlayerExpansion()) or self.preview
    local showRep = self.db.showRep or self.preview
    
    -- XP Update
    if showXP then
        self.xpBar:Show()
        local cur, max = UnitXP("player"), UnitXPMax("player")
        local rested = GetXPExhaustion()
        
        if self.preview then
            cur, max = 4500, 10000
            rested = 2500
        end
        
        self.xpBar:SetMinMaxValues(0, max)
        self.xpBar:SetValue(cur)
        
        local pct = math.floor((cur / max) * 100)
        local text = string.format("XP: %s / %s (%d%%)", AbbreviateLargeNumbers(cur), AbbreviateLargeNumbers(max), pct)
        if rested and rested > 0 then
            text = text .. string.format(" R: %d%%", math.floor(rested / max * 100))
            self.xpBar:SetStatusBarColor(unpack(self.db.restedColor))
        else
            self.xpBar:SetStatusBarColor(unpack(self.db.xpColor))
        end
        
        self.xpBar.text:SetText(text)
    else
        self.xpBar:Hide()
    end
    
    -- Rep Update
    if showRep then
        local data = C_Reputation.GetWatchedFactionData()
        
        if self.preview then
            data = {
                name = "Preview Faction",
                reaction = 5,
                currentReactionThreshold = 0,
                nextReactionThreshold = 21000,
                currentStanding = 10500,
                factionID = 0
            }
        end
        
        if data then
            local name = data.name
            local reaction = data.reaction
            local min = data.currentReactionThreshold
            local max = data.nextReactionThreshold
            local val = data.currentStanding
            local factionID = data.factionID
        
            -- DEBUG
            -- print("GravityUI Rep Debug:", name, "Min:", min, "Max:", max, "Val:", val, "ID:", factionID)

            -- 1. Major Faction (Renown) Support
            local isMajorFaction = C_Reputation.IsMajorFaction(factionID)
            local isHandled = false
            
            if isMajorFaction and C_MajorFactions then
                local majorData = C_MajorFactions.GetMajorFactionData(factionID)
                
                if majorData then
                    isHandled = true
                    name = majorData.name or name
                    local renownVal = majorData.renownReputationEarned or 0
                    local renownMax = majorData.renownLevelThreshold or 1
                    local renownLevel = majorData.renownLevel or 0
                    
                    self.repBar:Show()
                    self.repBar:SetMinMaxValues(0, renownMax)
                    self.repBar:SetValue(renownVal)
                    self.repBar:SetStatusBarColor(unpack(self.db.repColor))
                    
                    local pct = math.floor((renownVal / renownMax) * 100)
                    self.repBar.text:SetText(string.format("%s (Renown %d): %s / %s (%d%%)", name, renownLevel, AbbreviateLargeNumbers(renownVal), AbbreviateLargeNumbers(renownMax), pct))
                end
            end

            -- 2. Friendship Factions / Delve Companions Support (e.g. Valeera, Brann)
            if not isHandled and factionID and factionID > 0 then
                local friendshipData = (C_GossipInfo and C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(factionID))
                    or (C_Reputation and C_Reputation.GetFriendshipReputation and C_Reputation.GetFriendshipReputation(factionID))
                    or (GetFriendshipReputation and GetFriendshipReputation(factionID))
                
                if friendshipData and friendshipData.friendshipFactionID and friendshipData.friendshipFactionID > 0 then
                    isHandled = true
                    name = friendshipData.name or name
                    local rankName = friendshipData.reaction or ""
                    local cur = friendshipData.standing or 0
                    local minThresh = friendshipData.reactionThreshold or 0
                    local nextThresh = friendshipData.nextThreshold
                    local maxRep = friendshipData.maxRep or 0
                    
                    local standing = 0
                    local total = 1
                    
                    if nextThresh and nextThresh > minThresh then
                        standing = cur - minThresh
                        total = nextThresh - minThresh
                    else
                        -- Capped / Maximum level reached
                        local cap = (maxRep > minThresh and (maxRep - minThresh)) or (cur > minThresh and (cur - minThresh)) or 1
                        standing = cap
                        total = cap
                    end
                    
                    if total <= 0 then total = 1 end
                    standing = math.max(0, math.min(standing, total))
                    
                    self.repBar:Show()
                    self.repBar:SetMinMaxValues(0, total)
                    self.repBar:SetValue(standing)
                    self.repBar:SetStatusBarColor(unpack(self.db.repColor))
                    
                    local pct = math.floor((standing / total) * 100)
                    if rankName and rankName ~= "" then
                        self.repBar.text:SetText(string.format("%s (%s): %s / %s (%d%%)", name, rankName, AbbreviateLargeNumbers(standing), AbbreviateLargeNumbers(total), pct))
                    else
                        self.repBar.text:SetText(string.format("%s: %s / %s (%d%%)", name, AbbreviateLargeNumbers(standing), AbbreviateLargeNumbers(total), pct))
                    end
                end
            end

            -- 3. Standard & Paragon Reputation
            if not isHandled then
                self.repBar:Show()
                local standing = val - min
                local total = max - min
                
                -- FIX FOR SOME REPUTATIONS (Renown/Paragon edge cases)
                if total <= 0 then total = 1 end -- Prevent div/0
                if standing < 0 then standing = 0 end
                if standing > total then standing = total end
                
                self.repBar:SetMinMaxValues(0, total)
                self.repBar:SetValue(standing)
                
                local color = self.db.repColor
                
                -- PARAGON LOGIC
                -- Only show Paragon if we are actually Exalted (Reaction 8) AND the game says it's Paragon.
                local isParagon = C_Reputation.IsFactionParagon(factionID)
                local isExalted = reaction and reaction >= 8
                
                if not self.preview and factionID and isParagon and isExalted then
                    local currentValue, threshold, _, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID)
                    
                    local isActuallyParagon = not tooLowLevelForParagon and currentValue
                    
                    if isActuallyParagon and threshold and threshold > 0 then
                        standing = currentValue % threshold
                        total = threshold
                        self.repBar:SetMinMaxValues(0, total)
                        self.repBar:SetValue(standing)
                        name = name .. " (Paragon)"
                    end
                end

                self.repBar:SetStatusBarColor(unpack(color))
                
                local pct = 0
                if total > 0 then
                    pct = math.floor((standing / total) * 100)
                end
                self.repBar.text:SetText(string.format("%s: %s / %s (%d%%)", name, AbbreviateLargeNumbers(standing), AbbreviateLargeNumbers(total), pct))
            end
        else
            self.repBar:Hide() 
        end
    else
        self.repBar:Hide()
    end
    
    -- Layout
    local width = self.db.width
    local height = self.db.height
    
    local isBottomAnchored = true
    if self.db.position and self.db.position.point and self.db.position.point:find("TOP") then
        isBottomAnchored = false
    end

    if self.xpBar:IsShown() and self.repBar:IsShown() then
        self.frame:SetSize(width, height * 2 + 2)
        self.xpBar:ClearAllPoints()
        self.repBar:ClearAllPoints()
        
        if isBottomAnchored then
            self.repBar:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
            self.repBar:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
            self.repBar:SetHeight(height)
            
            self.xpBar:SetPoint("BOTTOMLEFT", self.repBar, "TOPLEFT", 0, 2)
            self.xpBar:SetPoint("BOTTOMRIGHT", self.repBar, "TOPRIGHT", 0, 2)
            self.xpBar:SetHeight(height)
        else
            self.xpBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
            self.xpBar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
            self.xpBar:SetHeight(height)
            
            self.repBar:SetPoint("TOPLEFT", self.xpBar, "BOTTOMLEFT", 0, -2)
            self.repBar:SetPoint("TOPRIGHT", self.xpBar, "BOTTOMRIGHT", 0, -2)
            self.repBar:SetHeight(height)
        end
    elseif self.xpBar:IsShown() then
        self.xpBar:ClearAllPoints()
        self.xpBar:SetAllPoints(self.frame)
        self.xpBar:SetHeight(height)
        self.frame:SetSize(width, height)
    elseif self.repBar:IsShown() then
        self.repBar:ClearAllPoints()
        self.repBar:SetAllPoints(self.frame)
        self.repBar:SetHeight(height)
        self.frame:SetSize(width, height)
    else
        self.frame:Hide()
    end
    
    -- Apply Mouseover State & Text Visibility
    if self.db.mouseover and not self.preview then
        self.frame:SetAlpha(0)
        
        -- Keep text ready
        self.xpBar.text:SetAlpha(1)
        self.repBar.text:SetAlpha(1)
    else
        self.frame:SetAlpha(1)
        
        -- Text Visibility Logic
        local showText = self.db.alwaysShowText or self.frame:IsMouseOver() or self.preview
        local textAlpha = showText and 1 or 0
        
        self.xpBar.text:SetAlpha(textAlpha)
        self.repBar.text:SetAlpha(textAlpha)
    end
end

SLASH_GRAVITYREPDEBUG1 = "/gravitydebugrep"
SlashCmdList["GRAVITYREPDEBUG"] = function()
    local data = C_Reputation.GetWatchedFactionData()
    if data then
        print("GravityUI Rep Debug:")
        print("Name:", data.name)
        print("ID:", data.factionID)
        print("Reaction:", data.reaction)
        print("Min (Current Threshold):", data.currentReactionThreshold)
        print("Max (Next Threshold):", data.nextReactionThreshold)
        print("Val (Current Standing):", data.currentStanding)

        local isMajor = C_Reputation.IsMajorFaction(data.factionID)
        print("Is Major Faction (Renown):", isMajor)
        if isMajor and C_MajorFactions then
            local majorData = C_MajorFactions.GetMajorFactionData(data.factionID)
            if majorData then
                print("Major Faction Data:", majorData.name, "Renown:", majorData.renownLevel, "Earned:", majorData.renownReputationEarned, "Threshold:", majorData.renownLevelThreshold)
            end
        end

        local friendshipData = (C_GossipInfo and C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(data.factionID))
            or (C_Reputation and C_Reputation.GetFriendshipReputation and C_Reputation.GetFriendshipReputation(data.factionID))
            or (GetFriendshipReputation and GetFriendshipReputation(data.factionID))
        if friendshipData and friendshipData.friendshipFactionID and friendshipData.friendshipFactionID > 0 then
            print("Friendship Data:", friendshipData.name, "Rank:", friendshipData.reaction, "Standing:", friendshipData.standing, "Threshold:", friendshipData.reactionThreshold, "Next:", friendshipData.nextThreshold, "Max:", friendshipData.maxRep)
        end
        
        local standing = data.currentStanding - data.currentReactionThreshold
        local total = data.nextReactionThreshold - data.currentReactionThreshold
        print("Calculated Standing:", standing)
        print("Calculated Total:", total)
        
        local isParagon = C_Reputation.IsFactionParagon(data.factionID)
        print("Is Paragon:", isParagon)
        if isParagon then
            local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(data.factionID)
            print("Paragon Info:", currentValue, threshold, hasRewardPending)
        end
    else
        print("GravityUI: No watched faction found.")
    end
end

function XPRep:Refresh()
    if not self.initialized then return end
    
    self.db = ns.db.profile.styling.xpRep
    
    if not self.db.enabled then
        self.frame:Hide()
        return
    end
    
    self.frame:SetSize(self.db.width, self.db.height) -- Initial sizing
    local pos = self.db.position or { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 0 }
    self.frame:ClearAllPoints()
    self.frame:SetPoint(pos.point or "BOTTOM", UIParent, pos.relativePoint or pos.point or "BOTTOM", pos.x or 0, pos.y or 0)
    self.frame:SetFrameStrata(self.db.strata or "MEDIUM")
    
    local texture = LSM:Fetch("statusbar", self.db.texture)
    local font = LSM:Fetch("font", ns.db.profile.general.font)
    
    self.xpBar:SetStatusBarTexture(texture)
    self.repBar:SetStatusBarTexture(texture)
    
    self.xpBar.text:SetFont(font, self.db.fontSize, self.db.fontOutline)
    self.repBar.text:SetFont(font, self.db.fontSize, self.db.fontOutline)
    
    -- Mouseover Scripts
    self.frame:SetScript("OnEnter", function()
        if self.db.mouseover and not self.db.alwaysHide then
            self.frame:SetAlpha(1)
        elseif not self.db.mouseover then
            -- Bar is always visible, show text on hover
            self.xpBar.text:SetAlpha(1)
            self.repBar.text:SetAlpha(1)
        end
    end)
    
    self.frame:SetScript("OnLeave", function()
        if self.db.mouseover and not self.preview and not (self.mover and self.mover:IsShown()) then
            self.frame:SetAlpha(0)
        elseif not self.db.mouseover and not self.db.alwaysShowText then
            -- Bar is visible, hide text on leave if not always shown
            self.xpBar.text:SetAlpha(0)
            self.repBar.text:SetAlpha(0)
        end
    end)
    
    self:Update()
end

function XPRep:RegisterEvents()
    self.frame:RegisterEvent("PLAYER_XP_UPDATE")
    self.frame:RegisterEvent("UPDATE_EXHAUSTION")
    self.frame:RegisterEvent("UPDATE_FACTION")
    self.frame:RegisterEvent("PLAYER_LEVEL_UP")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    self.frame:SetScript("OnEvent", function(_, event)
        -- Optimization: Throttle events (especially UPDATE_FACTION) to prevent spam
        if self.pendingUpdate then return end
        self.pendingUpdate = true
        
        C_Timer.After(0.1, function()
            self.pendingUpdate = false
            self:Update()
        end)
    end)
end

function XPRep:TogglePreview()
    self.preview = not self.preview
    self:Update()
end

function XPRep:ToggleMover(forceState)
    local shouldShow = false
    if forceState ~= nil then
        shouldShow = forceState
    else
        shouldShow = not self.preview
    end

    if shouldShow then
        self.preview = true
        self:Update()
        self.frame:Show()
        self.frame:SetAlpha(1)
    else
        self.preview = false
        self:Update()
    end

    if ns.Movers and ns.Movers.ApplyEditModeStyle and self.frame then
        ns.Movers:ApplyEditModeStyle(self.frame, shouldShow, "XPRep")
    end
end

function XPRep:RegisterMover()
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("XPRep", self.frame, function(frame, enabled) self:ToggleMover(enabled) end, "XP/Rep Bar")
    end
end
