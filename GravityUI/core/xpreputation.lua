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
    self:CreateMover()
    self:RegisterMover()
    
    self:RegisterEvents()
    
    self.initialized = true
    self:Refresh()
    
    -- Force a second update after a slight delay to ensure DB is fully loaded and UI settled
    C_Timer.After(1, function() 
        -- print("GravityUI: Delayed XPRep Update")
        self:Update() 
    end)
end

function XPRep:CreateContainer()
    self.frame = CreateFrame("Frame", "GravityUI_XPRep_Frame", UIParent)
    self.frame:SetSize(self.db.width, self.db.height)
    self.frame:SetPoint(self.db.position.point, UIParent, self.db.position.relativePoint, self.db.position.x, self.db.position.y)
    self.frame:SetFrameStrata("LOW")
    self.frame:SetMovable(true)
    self.frame:SetClampedToScreen(true)
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

            -- Major Faction (Renown) Support
            local isMajorFaction = C_Reputation.IsMajorFaction(factionID)
            local isRenown = false
            
            if isMajorFaction and C_MajorFactions then
                local majorData = C_MajorFactions.GetMajorFactionData(factionID)
                
                if majorData then
                    isRenown = true
                    name = majorData.name -- Use major faction name
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

            if not isRenown then
                self.repBar:Show()
                local standing = val - min
                local total = max - min
                
                -- FIX FOR SOME REPUTATIONS (Renown/Paragon edge cases)
                if total == 0 then total = 1 end -- Prevent div/0
                
                self.repBar:SetMinMaxValues(0, total)
                self.repBar:SetValue(standing)
                
                local color = self.db.repColor
                
                -- PARAGON LOGIC
                -- Only show Paragon if we are actually Exalted (Reaction 8) AND the game says it's Paragon.
                -- This fixes issues with Warband factions showing 0/10000 Paragon bars while still leveling (e.g. 5650/6000).
                local isParagon = C_Reputation.IsFactionParagon(factionID)
                local isExalted = reaction and reaction >= 8
                
                if not self.preview and factionID and isParagon and isExalted then
                    local currentValue, threshold, _, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID)
                    
                    local isActuallyParagon = not tooLowLevelForParagon and currentValue
                    
                    if isActuallyParagon then
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
    
    self.frame:SetSize(width, height * 2 + 5) -- Expand container if needed
    
    if self.xpBar:IsShown() and self.repBar:IsShown() then
        self.xpBar:ClearAllPoints()
        self.xpBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
        self.xpBar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
        self.xpBar:SetHeight(height)
        
        self.repBar:ClearAllPoints()
        self.repBar:SetPoint("TOPLEFT", self.xpBar, "BOTTOMLEFT", 0, -2) -- 2px Spacing
        self.repBar:SetPoint("TOPRIGHT", self.xpBar, "BOTTOMRIGHT", 0, -2)
        self.repBar:SetHeight(height)
    elseif self.xpBar:IsShown() then
        self.xpBar:ClearAllPoints()
        self.xpBar:SetAllPoints(self.frame)
        self.xpBar:SetHeight(height)
        self.frame:SetHeight(height)
    elseif self.repBar:IsShown() then
        self.repBar:ClearAllPoints()
        self.repBar:SetAllPoints(self.frame)
        self.repBar:SetHeight(height)
        self.frame:SetHeight(height)
    else
        self.frame:Hide()
    end
    
    -- Apply Mouseover State & Text Visibility
    if self.db.mouseover and not self.preview and not (self.mover and self.mover:IsShown()) then
        self.frame:SetAlpha(0)
        
        -- Keep text ready
        self.xpBar.text:SetAlpha(1)
        self.repBar.text:SetAlpha(1)
    else
        self.frame:SetAlpha(1)
        
        -- Text Visibility Logic
        local showText = self.db.alwaysShowText or self.frame:IsMouseOver() or (self.mover and self.mover:IsShown())
        local textAlpha = showText and 1 or 0
        
        self.xpBar.text:SetAlpha(textAlpha)
        self.repBar.text:SetAlpha(textAlpha)
    end

    
    if self.mover and self.mover:IsShown() then
        self.frame:SetAlpha(1)
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
    self.frame:ClearAllPoints()
    self.frame:SetPoint(self.db.position.point, UIParent, self.db.position.relativePoint, self.db.position.x, self.db.position.y)
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
    if not self.mover then self:CreateMover() end
    
    local shouldShow = false
    if forceState ~= nil then
        shouldShow = forceState
    else
        shouldShow = not self.mover:IsShown()
    end

    if shouldShow then
        self.mover:Show()
        -- Color Logic
        if forceState == true then
             -- Global Edit Mode: Blue
             self.mover:SetBackdropColor(0, 0.6, 1, 0.5)
             self.mover:SetBackdropBorderColor(0, 0.8, 1, 1)
        else
             -- Manual: Green
             self.mover:SetBackdropColor(0, 1, 0, 0.5)
             self.mover:SetBackdropBorderColor(0, 1, 0, 1)
        end
    else
        self.mover:Hide()
    end
end

function XPRep:RegisterMover()
    if ns.Movers and ns.Movers.Register then
        ns.Movers:Register("XPRep", self.frame, function(frame, enabled) self:ToggleMover(enabled) end, "XP/Rep Bar")
    end
end


function XPRep:CreateMover()
    if self.mover then return end
    
    self.mover = CreateFrame("Frame", "GravityUI_XPRep_Mover", UIParent, "BackdropTemplate")
    self.mover:SetAllPoints(self.frame)
    self.mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    self.mover:SetBackdropColor(0, 1, 0, 0.5)
    self.mover:SetBackdropBorderColor(0, 1, 0, 1)
    
    self.mover:EnableMouse(true)
    self.mover:SetMovable(true)
    self.mover:RegisterForDrag("LeftButton")
    self.mover:SetFrameStrata("DIALOG")
    self.mover:Hide()
    
    local text = self.mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText("XP/Rep Mover")
    
    self.mover:SetScript("OnDragStart", function()
        self.frame:StartMoving()
        self.mover:SetAllPoints(self.frame) -- Keep synced? iterating
    end)
    
    self.mover:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = self.frame:GetPoint()
        self.db.position.point = point
        self.db.position.relativePoint = relPoint
        self.db.position.x = x
        self.db.position.y = y
        self.mover:ClearAllPoints()
        self.mover:SetAllPoints(self.frame)
    end)
    
    -- Sync mover size/pos updates
    hooksecurefunc(self.frame, "SetSize", function() 
        if self.mover then self.mover:SetSize(self.frame:GetSize()) end
    end)
    hooksecurefunc(self.frame, "SetPoint", function() 
         if self.mover and not self.frame:IsDragging() then 
            self.mover:ClearAllPoints()
            self.mover:SetAllPoints(self.frame) 
         end
    end)
end
