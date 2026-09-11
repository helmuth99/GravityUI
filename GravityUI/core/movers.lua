local ADDON_NAME, ns = ...
ns.Movers = {}
local Movers = ns.Movers

-- Constants
local CHECKBOX_LABEL = "Show GravityUI Elements"
local SNAP_THRESHOLD = 8 -- pixels for magnetic element-to-element snapping

-- State
Movers.registry = {} -- [name] = { frame = frame, toggleFunc = func, label = "Label", customGet = func, customSet = func }
Movers.isEditMode = false
Movers.showGravityElements = false
Movers.selectedMover = nil

-- ============================================================================
-- MODULE ENABLED RESOLUTION & TOGGLE MAP
-- ============================================================================
local MODULE_CONFIG_MAP = {
    ["DeathAnnouncer"] = {
        get = function(db) return db.deathAnnouncer and db.deathAnnouncer.enabled ~= false end,
        set = function(db, val)
            if db.deathAnnouncer then db.deathAnnouncer.enabled = val end
            if ns.DeathAnnouncer and ns.DeathAnnouncer.ApplySettings then ns.DeathAnnouncer.ApplySettings() end
        end,
    },
    ["Minimap"] = {
        get = function(db) return db.minimap and db.minimap.enabled ~= false end,
        set = function(db, val)
            if db.minimap then db.minimap.enabled = val end
            if ns.Minimap and ns.Minimap.Refresh then ns.Minimap:Refresh() end
        end,
    },
    ["CombatTimer"] = {
        get = function(db) return db.uiimprovements and db.uiimprovements.combatTimer and db.uiimprovements.combatTimer.enabled ~= false end,
        set = function(db, val)
            if db.uiimprovements and db.uiimprovements.combatTimer then db.uiimprovements.combatTimer.enabled = val end
            if ns.CombatTimer and ns.CombatTimer.Refresh then ns.CombatTimer.Refresh() end
        end,
    },
    ["CombatStatus"] = {
        get = function(db) return db.screenindicators and db.screenindicators.combatStatus and db.screenindicators.combatStatus.enabled ~= false end,
        set = function(db, val)
            if db.screenindicators and db.screenindicators.combatStatus then db.screenindicators.combatStatus.enabled = val end
            if ns.ScreenIndicators and ns.ScreenIndicators.UpdateCombatStatus then ns.ScreenIndicators.UpdateCombatStatus() end
        end,
    },
    ["PetWarnings"] = {
        get = function(db) return db.screenindicators and db.screenindicators.petWarnings and db.screenindicators.petWarnings.enabled ~= false end,
        set = function(db, val)
            if db.screenindicators and db.screenindicators.petWarnings then db.screenindicators.petWarnings.enabled = val end
            if ns.ScreenIndicators and ns.ScreenIndicators.UpdatePetWarnings then ns.ScreenIndicators.UpdatePetWarnings() end
        end,
    },
    ["GravityUI_Difficulty"] = {
        get = function(db) return db.screenindicators and db.screenindicators.difficulty and db.screenindicators.difficulty.enabled ~= false end,
        set = function(db, val)
            if db.screenindicators and db.screenindicators.difficulty then db.screenindicators.difficulty.enabled = val end
            if ns.ScreenIndicators and ns.ScreenIndicators.UpdateDifficultyPosition then ns.ScreenIndicators.UpdateDifficultyPosition() end
        end,
    },
    ["RaidWarnings"] = {
        get = function(db) return db.raidWarnings and db.raidWarnings.enabled ~= false end,
        set = function(db, val)
            if db.raidWarnings then db.raidWarnings.enabled = val end
            if ns.RaidWarnings and ns.RaidWarnings.ApplySettings then ns.RaidWarnings.ApplySettings() end
        end,
    },
    ["InterruptTracker"] = {
        get = function(db) return db.screenindicators and db.screenindicators.interruptTracker and db.screenindicators.interruptTracker.enabled ~= false end,
        set = function(db, val)
            if db.screenindicators and db.screenindicators.interruptTracker then db.screenindicators.interruptTracker.enabled = val end
            if ns.InterruptTracker and ns.InterruptTracker.ApplySettings then ns.InterruptTracker.ApplySettings() end
        end,
    },
    ["HealerMana"] = {
        get = function(db) return db.screenindicators and db.screenindicators.healerMana and db.screenindicators.healerMana.enabled == true end,
        set = function(db, val)
            if db.screenindicators and db.screenindicators.healerMana then db.screenindicators.healerMana.enabled = val end
            if ns.HealerMana and ns.HealerMana.Refresh then ns.HealerMana.Refresh() end
        end,
    },
    ["StanceText"] = {
        get = function(db) return db.screenindicators and db.screenindicators.stanceText and db.screenindicators.stanceText.enabled == true end,
        set = function(db, val)
            if db.screenindicators and db.screenindicators.stanceText then db.screenindicators.stanceText.enabled = val end
            if ns.StanceText and ns.StanceText.Refresh then ns.StanceText:Refresh() end
        end,
    },
    ["ReadyCheck"] = {
        get = function(db) return db.styling and (db.styling.skinReadyCheck ~= false or (db.styling.readyCheck and db.styling.readyCheck.enable ~= false)) end,
        set = function(db, val)
            if db.styling then 
                db.styling.skinReadyCheck = val 
                if db.styling.readyCheck then db.styling.readyCheck.enable = val end
            end
            if ns.Styling and ns.Styling.RefreshReadyCheck then ns.Styling:RefreshReadyCheck() end
        end,
    },
    ["PowerBarAlt"] = {
        get = function(db) return db.styling and db.styling.powerBar and db.styling.powerBar.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.powerBar then db.styling.powerBar.enabled = val end
            if ns.Styling and ns.Styling.RefreshPowerBar then ns.Styling:RefreshPowerBar() end
        end,
    },
    ["WidgetPowerBar"] = {
        get = function(db) return db.styling and db.styling.widgetPowerBar and db.styling.widgetPowerBar.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.widgetPowerBar then db.styling.widgetPowerBar.enabled = val end
        end,
    },
    ["WidgetBelowMinimap"] = {
        get = function(db) return db.styling and db.styling.widgetBelowMinimap and db.styling.widgetBelowMinimap.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.widgetBelowMinimap then db.styling.widgetBelowMinimap.enabled = val end
        end,
    },
    ["WidgetTopCenter"] = {
        get = function(db) return db.styling and db.styling.widgetTopCenter and db.styling.widgetTopCenter.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.widgetTopCenter then db.styling.widgetTopCenter.enabled = val end
        end,
    },
    ["Alerts"] = {
        get = function(db) return db.styling and db.styling.alerts and db.styling.alerts.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.alerts then db.styling.alerts.enabled = val end
        end,
    },
    ["Toasts"] = {
        get = function(db) return db.styling and db.styling.alerts and db.styling.alerts.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.alerts then db.styling.alerts.enabled = val end
        end,
    },
    ["BonusRoll"] = {
        get = function(db) return db.styling and db.styling.lootRoll and db.styling.lootRoll.skinBonusRoll ~= false end,
        set = function(db, val)
            if db.styling and db.styling.lootRoll then db.styling.lootRoll.skinBonusRoll = val end
        end,
    },
    ["XPRep"] = {
        get = function(db) return db.styling and db.styling.xpRep and db.styling.xpRep.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.xpRep then db.styling.xpRep.enabled = val end
            if ns.XPRep and ns.XPRep.Update then ns.XPRep:Update() end
            if ns.XPRep and ns.XPRep.Refresh then ns.XPRep:Refresh() end
        end,
    },
    ["WorldMarks"] = {
        get = function(db) return db.uiimprovements and db.uiimprovements.marks and db.uiimprovements.marks.enabled ~= false end,
        set = function(db, val)
            if db.uiimprovements and db.uiimprovements.marks then db.uiimprovements.marks.enabled = val end
            if ns.WorldMarks and ns.WorldMarks.Refresh then ns.WorldMarks:Refresh() end
        end,
    },
    ["LootWindow"] = {
        get = function(db) return db.styling and db.styling.loot and db.styling.loot.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.loot then db.styling.loot.enabled = val end
        end,
    },
    ["LootRolls"] = {
        get = function(db) return db.styling and db.styling.lootRoll and db.styling.lootRoll.enabled ~= false end,
        set = function(db, val)
            if db.styling and db.styling.lootRoll then db.styling.lootRoll.enabled = val end
        end,
    },
    ["CooldownText"] = {
        get = function(db) return db.cooldownText and db.cooldownText.enabled == true end,
        set = function(db, val)
            if db.cooldownText then db.cooldownText.enabled = val end
            if ns.CooldownText and ns.CooldownText.Initialize then ns.CooldownText:Initialize() end
            if ns.CooldownText and ns.CooldownText.Refresh then ns.CooldownText:Refresh() end
        end,
    },
    ["BattleResTracker"] = {
        get = function(db) return db.screenindicators and db.screenindicators.battleRes and db.screenindicators.battleRes.enabled ~= false end,
        set = function(db, val)
            if db.screenindicators and db.screenindicators.battleRes then db.screenindicators.battleRes.enabled = val end
            if ns.BattleResTracker and ns.BattleResTracker.Update then ns.BattleResTracker.Update() end
        end,
    },
    ["BloodlustTracker"] = {
        get = function(db) return db.screenindicators and db.screenindicators.bloodlust and db.screenindicators.bloodlust.enabled ~= false end,
        set = function(db, val)
            if db.screenindicators and db.screenindicators.bloodlust then db.screenindicators.bloodlust.enabled = val end
            if ns.BloodlustTracker and ns.BloodlustTracker.Update then ns.BloodlustTracker.Update() end
        end,
    },
}

function Movers:GetEditModeSettings()
    local db = ns.GetDB and ns.GetDB()
    if db and db.editMode then
        return db.editMode
    end
    return {
        showGrid = true,
        gridSize = 32,
        snapToGrid = true,
        snapToElements = true,
        showDisabled = false,
    }
end

function Movers:IsElementEnabled(name)
    local db = ns.GetDB and ns.GetDB()
    local data = self.registry[name]
    if data and data.customGet then
        return (data.customGet(db) == true)
    end
    local map = MODULE_CONFIG_MAP[name]
    if map and map.get then
        if db then return (map.get(db) == true) end
    end
    return true
end

function Movers:ToggleElementEnabled(name)
    local db = ns.GetDB and ns.GetDB()
    local data = self.registry[name]
    local current = self:IsElementEnabled(name)
    local newVal = not current

    if data and data.customSet then
        data.customSet(newVal, db)
    else
        local map = MODULE_CONFIG_MAP[name]
        if map and map.set then
            if db then map.set(db, newVal) end
        end
    end

    -- Update overlay styling immediately
    self:UpdateOverlayForElement(name)
    self:UpdateDisplay()
    self:UpdateHUD()
    if ns.RefreshAccentColors then ns.RefreshAccentColors() end
end

-- ============================================================================
-- REGISTRY
-- ============================================================================

function Movers:Register(name, frame, toggleFunc, label, customGet, customSet)
    if self.registry[name] then
        local entry = self.registry[name]
        if frame then entry.frame = frame end
        if toggleFunc then entry.toggleFunc = toggleFunc end
        if label then entry.label = label end
        if customGet then entry.customGet = customGet end
        if customSet then entry.customSet = customSet end
        return
    end

    self.registry[name] = {
        frame       = frame,
        toggleFunc  = toggleFunc,
        label       = label or name,
        customGet   = customGet,
        customSet   = customSet,
    }

    if frame then
        self:HookMoverFrame(name, frame)
    end
end

function Movers:Toggle(name)
    local data = self.registry[name]
    if not data then return end

    local hasOverlay = data.frame and data.frame.ag_backdrop and data.frame.ag_backdrop:IsShown()
    local shouldShow = not hasOverlay

    if data.toggleFunc then
        pcall(data.toggleFunc, data.frame, shouldShow, shouldShow)
    elseif data.frame then
        if shouldShow then
            data.frame:Show()
        else
            data.frame:Hide()
        end
    end

    if data.frame then
        self:ApplyEditModeStyle(data.frame, shouldShow, name)
    end
end

-- ============================================================================
-- VISIBILITY LOGIC
-- ============================================================================

function Movers:SetEditMode(enabled)
    self.isEditMode = enabled
    if enabled then
        self.showGravityElements = true
        -- Auto-hide GravityUI settings window while in Edit Mode
        if ns.GUI and ns.GUI.MainFrame and ns.GUI.MainFrame:IsShown() then
            self.wasGUIShown = true
            ns.GUI:Hide()
        end
        self:ShowGrid()
        self:ShowHUD()
        self:EnableKeyHandler(true)
    else
        self.showGravityElements = false
        self:HideGrid()
        self:HideHUD()
        self:EnableKeyHandler(false)
        self.selectedMover = nil
        if ns.HealerMana and ns.HealerMana.HidePreview then
            pcall(function() ns.HealerMana:HidePreview() end)
        end
        -- Restore GravityUI settings window when exiting Edit Mode
        if self.wasGUIShown then
            self.wasGUIShown = false
            if ns.GUI and ns.GUI.Show then
                ns.GUI:Show()
            end
        end
    end
    self:UpdateDisplay()
end

function Movers:SetShowGravityElements(enabled)
    self.showGravityElements = enabled
    self:UpdateDisplay()
end

function Movers:UpdateDisplay()
    local inEdit = self.isEditMode and self.showGravityElements
    local cfg = self:GetEditModeSettings()
    local showDisabled = cfg.showDisabled or false

    for name, data in pairs(self.registry) do
        local isEnabled = self:IsElementEnabled(name)
        local shouldShow = inEdit and (isEnabled or showDisabled)

        if data.toggleFunc then
            pcall(data.toggleFunc, data.frame, shouldShow, shouldShow)
        elseif data.frame then
            if shouldShow then
                data.frame:Show()
            else
                data.frame:Hide()
            end
        end

        if data.frame then
            self:ApplyEditModeStyle(data.frame, shouldShow, name)
        end
    end

    self:UpdateHUD()
end

-- ============================================================================
-- UNIFIED OVERLAY STYLING (Blue = Active, Red = Disabled, Gold = Selected)
-- ============================================================================

function Movers:ApplyOverlayVisuals(ov, targetFrame, name)
    if not ov then return end
    targetFrame = targetFrame or ov:GetParent()
    if not targetFrame then return end

    -- Resolve name if missing
    if not name or name == "" then
        name = ov.moverName or targetFrame.moverName
        if not name then
            for regName, regData in pairs(self.registry) do
                if regData.frame == targetFrame or (targetFrame.GetParent and regData.frame == targetFrame:GetParent()) then
                    name = regName
                    break
                end
            end
        end
        if not name and targetFrame.GetName and targetFrame:GetName() then
            local fn = targetFrame:GetName()
            for regName in pairs(self.registry) do
                if fn:find(regName) then
                    name = regName
                    break
                end
            end
        end
    end

    ov.moverName = name
    targetFrame.moverName = name

    local data = name and self.registry[name]
    local label = (data and data.label) or name or (targetFrame.GetName and targetFrame:GetName()) or "Movable Element"
    local isEnabled = name and self:IsElementEnabled(name)
    if isEnabled == nil then isEnabled = true end
    local isSelected = (name and self.selectedMover == name)

    local w, h = targetFrame:GetSize()
    w = math.max(math.floor((w or 0) + 0.5), 10)
    h = math.max(math.floor((h or 0) + 0.5), 10)

    if isSelected then
        -- Selected Glow / Golden Border
        if isEnabled then
            ov:SetBackdropColor(0.05, 0.55, 1.00, 0.65)
        else
            ov:SetBackdropColor(0.95, 0.15, 0.15, 0.65)
        end
        ov:SetBackdropBorderColor(1.00, 0.84, 0.00, 1.00) -- Vibrant Gold
        if ov.title then ov.title:SetText(string.format("|cffffd700%s%s|r", label, isEnabled and "" or " (Disabled)")) end
        if ov.dim then ov.dim:SetText(string.format("|cffffffff[%d × %d]|r", w, h)) end
    elseif isEnabled then
        -- Enabled Blue Overlay
        ov:SetBackdropColor(0.00, 0.48, 0.95, 0.45)
        ov:SetBackdropBorderColor(0.20, 0.80, 1.00, 0.95)
        if ov.title then ov.title:SetText(string.format("|cff30d1ff%s|r", label)) end
        if ov.dim then ov.dim:SetText(string.format("|cffb0e0e6[%d × %d]|r", w, h)) end
    else
        -- Disabled Red Overlay
        ov:SetBackdropColor(0.85, 0.12, 0.12, 0.45)
        ov:SetBackdropBorderColor(1.00, 0.35, 0.35, 0.95)
        if ov.title then ov.title:SetText(string.format("|cffff4444%s (Disabled)|r", label)) end
        if ov.dim then ov.dim:SetText(string.format("|cffff9999[%d × %d]|r", w, h)) end
    end

    -- Hide overlay labels on modules that render their own rich internal visuals
    if name == "HealerMana" or name == "InterruptTracker" or name == "XPRep" or name == "WorldMarks" or name == "ReadyCheck" or name == "StanceText" then
        if ov.title then ov.title:Hide() end
        if ov.dim then ov.dim:Hide() end
    end
end

function Movers:ApplyEditModeStyle(frame, enabled, name)
    if not frame then return end

    if enabled then
        if not frame.ag_backdrop then
            local ov = CreateFrame("Button", nil, frame, "BackdropTemplate")
            ov:SetAllPoints(frame)
            ov:SetFrameStrata("DIALOG")
            ov:SetFrameLevel(frame:GetFrameLevel() + 10)
            ov:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets   = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            ov:EnableMouse(true)
            ov:RegisterForDrag("LeftButton")
            ov:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            -- Title label
            local title = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("CENTER", ov, "CENTER", 0, 4)
            title:SetJustifyH("CENTER")
            ov.title = title

            -- Sub/Dimensions label
            local dim = ov:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            dim:SetPoint("TOP", title, "BOTTOM", 0, -2)
            dim:SetJustifyH("CENTER")
            ov.dim = dim

            -- Scripts
            ov:SetScript("OnMouseDown", function(self, btn)
                local mName = self.moverName
                if btn == "LeftButton" then
                    if mName then Movers:SelectMover(mName) end
                    local pFrame = self:GetParent()
                    if pFrame and pFrame:IsMovable() and not InCombatLockdown() then
                        pFrame:StartMoving()
                        self._isDragging = true
                    end
                elseif btn == "RightButton" then
                    if mName then Movers:ToggleElementEnabled(mName) end
                end
            end)

            ov:SetScript("OnMouseUp", function(self, btn)
                if btn == "LeftButton" and self._isDragging then
                    self._isDragging = false
                    local pFrame = self:GetParent()
                    if pFrame and not InCombatLockdown() then
                        pFrame:StopMovingOrSizing()
                        Movers:HandleSnapAndSave(self.moverName, pFrame)
                    end
                end
            end)

            ov:SetScript("OnEnter", function(self)
                if Movers.selectedMover ~= self.moverName then
                    self:SetBackdropBorderColor(1, 1, 1, 1)
                end
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(self.title and self.title:GetText() or "Movable Element", 1, 1, 1)
                GameTooltip:AddLine("|cff00FF80Left-Click & Drag:|r Move frame", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("|cff00FF80Left-Click:|r Select for Arrow Key nudging (1px / Shift: 10px)", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("|cffFF9900Right-Click:|r Toggle Enable / Disable module", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)

            ov:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                Movers:ApplyOverlayVisuals(self, self:GetParent(), self.moverName)
            end)

            frame.ag_backdrop = ov
        end

        frame.ag_backdrop.moverName = name
        self:ApplyOverlayVisuals(frame.ag_backdrop, frame, name)
        frame.ag_backdrop:Show()
    else
        if frame.ag_backdrop then
            frame.ag_backdrop:Hide()
        end
    end
end

function Movers:UpdateOverlayForElement(name)
    local data = self.registry[name]
    if data and data.frame and data.frame.ag_backdrop then
        self:ApplyOverlayVisuals(data.frame.ag_backdrop, data.frame, name)
    end
end

function Movers:HookMoverFrame(name, frame)
    if not frame then return end
    if frame._agHooked then return end
    frame._agHooked = true

    frame:SetMovable(true)

    if not frame._origStopMovingOrSizing then
        frame._origStopMovingOrSizing = frame.StopMovingOrSizing
        frame.StopMovingOrSizing = function(f, ...)
            frame._origStopMovingOrSizing(f, ...)
            Movers:HandleSnapAndSave(name, f)
        end
    end
end

-- ============================================================================
-- SELECTION & PIXEL-PERFECT KEYBOARD NUDGING
-- ============================================================================

function Movers:SelectMover(name)
    local prev = self.selectedMover
    self.selectedMover = name

    if prev and prev ~= name then
        self:UpdateOverlayForElement(prev)
    end
    if name then
        self:UpdateOverlayForElement(name)
    end

    self:UpdateHUD()
end

function Movers:NudgeSelectedMover(deltaX, deltaY)
    local name = self.selectedMover
    if not name then return end

    local data = self.registry[name]
    if not data or not data.frame then return end
    local frame = data.frame
    if InCombatLockdown() then return end

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    if not point then
        point, relativeTo, relativePoint, xOfs, yOfs = "CENTER", UIParent, "CENTER", 0, 0
    end

    local newX = math.floor((xOfs or 0) + deltaX + 0.5)
    local newY = math.floor((yOfs or 0) + deltaY + 0.5)

    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo or UIParent, relativePoint or point, newX, newY)

    self:SaveFramePosition(name, frame, point, relativePoint, newX, newY)
    self:UpdateOverlayForElement(name)
    self:UpdateHUD()
end

function Movers:SetSelectedMoverPosition(targetX, targetY)
    local name = self.selectedMover
    if not name then return end

    local data = self.registry[name]
    if not data or not data.frame then return end
    local frame = data.frame
    if InCombatLockdown() then return end

    targetX = math.floor((tonumber(targetX) or 0) + 0.5)
    targetY = math.floor((tonumber(targetY) or 0) + 0.5)

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", targetX, targetY)

    self:SaveFramePosition(name, frame, "CENTER", "CENTER", targetX, targetY)
    self:UpdateOverlayForElement(name)
    self:UpdateHUD()
end

function Movers:SaveFramePosition(name, frame, point, relPoint, x, y)
    -- Re-entrancy guard: OnDragStop → StopMovingOrSizing hook → HandleSnapAndSave
    -- → SaveFramePosition → OnDragStop ... would recurse infinitely without this.
    if frame._isSaving then return end
    frame._isSaving = true

    if frame:GetScript("OnDragStop") then
        pcall(frame:GetScript("OnDragStop"), frame)
    end

    local db = ns.GetDB and ns.GetDB()
    if not db then frame._isSaving = false; return end

    local p, _, rp, px, py = frame:GetPoint()
    local finalX = math.floor((px or x or 0) + 0.5)
    local finalY = math.floor((py or y or 0) + 0.5)
    local finalPoint = p or point or "CENTER"
    local finalRelPoint = rp or relPoint or "CENTER"

    if name == "DeathAnnouncer" and db.deathAnnouncer then
        local cx, cy = frame:GetCenter()
        local scx, scy = UIParent:GetCenter()
        if cx and scx then
            db.deathAnnouncer.x = math.floor(cx - scx + 0.5)
            db.deathAnnouncer.y = math.floor(cy - scy + 0.5)
        end
    elseif name == "XPRep" and db.styling and db.styling.xpRep then
        local cx, cy = frame:GetCenter()
        local ucy = (UIParent:GetHeight() or 1080) / 2
        local scx = UIParent:GetCenter() or 0
        local x = math.floor((cx - scx) + 0.5)
        
        if cy and cy < ucy then
            -- Lower half: Anchor to BOTTOM
            local bottom = math.floor((frame:GetBottom() or 0) + 0.5)
            db.styling.xpRep.position = { point = "BOTTOM", relativePoint = "BOTTOM", x = x, y = bottom }
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOM", UIParent, "BOTTOM", x, bottom)
        else
            -- Upper half: Anchor to TOP
            local top = frame:GetTop() or 0
            local uTop = UIParent:GetTop() or UIParent:GetHeight() or 1080
            local y = math.floor((top - uTop) + 0.5)
            db.styling.xpRep.position = { point = "TOP", relativePoint = "TOP", x = x, y = y }
            frame:ClearAllPoints()
            frame:SetPoint("TOP", UIParent, "TOP", x, y)
        end
        if ns.XPRep and ns.XPRep.Update then ns.XPRep:Update() end
    elseif name == "WorldMarks" and db.uiimprovements and db.uiimprovements.marks then
        local cx, cy = frame:GetCenter()
        local scx, scy = UIParent:GetCenter()
        if cx and scx then
            db.uiimprovements.marks.offsetX = math.floor(cx - scx + 0.5)
            db.uiimprovements.marks.offsetY = math.floor(cy - scy + 0.5)
        end
    elseif name == "CombatTimer" and db.uiimprovements and db.uiimprovements.combatTimer then
        local cx, cy = frame:GetCenter()
        local scx, scy = UIParent:GetCenter()
        if cx and scx then
            db.uiimprovements.combatTimer.xOffset = math.floor(cx - scx + 0.5)
            db.uiimprovements.combatTimer.yOffset = math.floor(cy - scy + 0.5)
        end
    elseif name == "PowerBarAlt" and db.styling and db.styling.powerBar then
        local p, _, rp, px, py = frame:GetPoint()
        local pt = p or point or "CENTER"
        local rpt = rp or relPoint or pt
        local fx = math.floor((px or x or 0) + 0.5)
        local fy = math.floor((py or y or 0) + 0.5)
        db.styling.powerBar.position = { point = pt, relPoint = rpt, relativePoint = rpt, x = fx, y = fy }
    elseif name == "WidgetPowerBar" and db.styling and db.styling.widgetPowerBar then
        db.styling.widgetPowerBar.position = { point = finalPoint, relPoint = finalRelPoint, x = finalX, y = finalY }
        local c = _G.UIWidgetPowerBarContainerFrame
        if c then c:ClearAllPoints(); c:SetPoint(finalPoint, UIParent, finalRelPoint, finalX, finalY) end
    elseif name == "WidgetBelowMinimap" and db.styling and db.styling.widgetBelowMinimap then
        db.styling.widgetBelowMinimap.position = { point = finalPoint, relPoint = finalRelPoint, x = finalX, y = finalY }
        local c = _G.UIWidgetBelowMinimapContainerFrame
        if c then c:ClearAllPoints(); c:SetPoint(finalPoint, UIParent, finalRelPoint, finalX, finalY) end
    elseif name == "WidgetTopCenter" and db.styling and db.styling.widgetTopCenter then
        db.styling.widgetTopCenter.position = { point = finalPoint, relPoint = finalRelPoint, x = finalX, y = finalY }
        local c = _G.UIWidgetTopCenterContainerFrame
        if c then c:ClearAllPoints(); c:SetPoint(finalPoint, UIParent, finalRelPoint, finalX, finalY) end
    elseif name == "Alerts" and db.styling and db.styling.alerts then
        db.styling.alerts.alertPosition = { point = finalPoint, relPoint = finalRelPoint, x = finalX, y = finalY }
    elseif name == "Toasts" and db.styling and db.styling.alerts then
        db.styling.alerts.toastPosition = { point = finalPoint, relPoint = finalRelPoint, x = finalX, y = finalY }
    elseif name == "InterruptTracker" and db.screenindicators and db.screenindicators.interruptTracker then
        local cx, cy = frame:GetCenter()
        local scx, scy = UIParent:GetCenter()
        if cx and scx then
            db.screenindicators.interruptTracker.x = math.floor(cx - scx + 0.5)
            db.screenindicators.interruptTracker.y = math.floor(cy - scy + 0.5)
        end
    elseif name == "RaidWarnings" and db.raidWarnings then
        db.raidWarnings.x = finalX
        db.raidWarnings.y = finalY
    elseif name == "LootWindow" and db.styling and db.styling.loot then
        db.styling.loot.position = { point = finalPoint, relPoint = finalRelPoint, x = finalX, y = finalY }
    elseif name == "LootRolls" and db.styling and db.styling.lootRoll then
        db.styling.lootRoll.position = { point = finalPoint, relPoint = finalRelPoint, x = finalX, y = finalY }
    elseif name == "CooldownText" and db.cooldownText then
        db.cooldownText.x = finalX
        db.cooldownText.y = finalY
    elseif name == "BattleResTracker" and db.screenindicators and db.screenindicators.battleRes then
        db.screenindicators.battleRes.position = { point = finalPoint, relativePoint = finalRelPoint, x = finalX, y = finalY }
    elseif name == "BloodlustTracker" and db.screenindicators and db.screenindicators.bloodlust then
        db.screenindicators.bloodlust.position = { point = finalPoint, relativePoint = finalRelPoint, x = finalX, y = finalY }
    else
        -- Generic handler for action bars (ActionBar_MainBar, ActionBar_Bar2, etc.)
        local abKey = name:match("^ActionBar_(.+)$")
        if abKey and db.actionbars and db.actionbars.bars then
            if not db.actionbars.bars[abKey] then db.actionbars.bars[abKey] = {} end
            db.actionbars.bars[abKey].position = { point = finalPoint, relativePoint = finalRelPoint, x = finalX, y = finalY }

            -- For ExtraAbilities proxy: sync the real Blizzard container position
            if abKey == "ExtraAbilities" then
                local container = _G.ExtraAbilityContainer
                if container and not InCombatLockdown() then
                    container:ClearAllPoints()
                    container:SetPoint(finalPoint, UIParent, finalRelPoint, finalX, finalY)
                end
            end
        end
    end

    frame._isSaving = false
end

local keyHandlerFrame
function Movers:EnableKeyHandler(enable)
    if not keyHandlerFrame then
        keyHandlerFrame = CreateFrame("Frame", "GravityUI_EditMode_KeyHandler", UIParent)
        keyHandlerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        keyHandlerFrame:EnableKeyboard(true)
        keyHandlerFrame:SetPropagateKeyboardInput(true)

        keyHandlerFrame:SetScript("OnKeyDown", function(self, key)
            if not Movers.isEditMode then return end

            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false)
                Movers:SetEditMode(false)
                return
            end

            if not Movers.selectedMover then
                self:SetPropagateKeyboardInput(true)
                return
            end

            local step = IsShiftKeyDown() and 10 or (IsAltKeyDown() and 5 or 1)

            if key == "UP" then
                Movers:NudgeSelectedMover(0, step)
                self:SetPropagateKeyboardInput(false)
            elseif key == "DOWN" then
                Movers:NudgeSelectedMover(0, -step)
                self:SetPropagateKeyboardInput(false)
            elseif key == "LEFT" then
                Movers:NudgeSelectedMover(-step, 0)
                self:SetPropagateKeyboardInput(false)
            elseif key == "RIGHT" then
                Movers:NudgeSelectedMover(step, 0)
                self:SetPropagateKeyboardInput(false)
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)
    end

    if enable then
        keyHandlerFrame:Show()
    else
        keyHandlerFrame:Hide()
    end
end

-- ============================================================================
-- SNAPPING ENGINE (Grid + Magnetic Element-to-Element)
-- ============================================================================

function Movers:HandleSnapAndSave(name, frame)
    if not frame or InCombatLockdown() then return end

    local cfg = self:GetEditModeSettings()
    local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not left then return end

    local fWidth = (right - left)
    local fHeight = (top - bottom)
    local centerX = (left + right) / 2
    local centerY = (top + bottom) / 2

    local screenW, screenH = UIParent:GetSize()
    local screenCenterX = screenW / 2
    local screenCenterY = screenH / 2

    local targetX = centerX - screenCenterX
    local targetY = centerY - screenCenterY

    -- 1. Magnetic Element-to-Element Snapping
    if cfg.snapToElements then
        for otherName, otherData in pairs(self.registry) do
            if otherName ~= name and otherData.frame and otherData.frame:IsShown() and otherData.frame:GetLeft() then
                local oL, oR, oT, oB = otherData.frame:GetLeft(), otherData.frame:GetRight(), otherData.frame:GetTop(), otherData.frame:GetBottom()
                local oCX = (oL + oR) / 2
                local oCY = (oT + oB) / 2

                -- Snap Centers
                if math.abs(centerX - oCX) <= SNAP_THRESHOLD then
                    targetX = oCX - screenCenterX
                end
                if math.abs(centerY - oCY) <= SNAP_THRESHOLD then
                    targetY = oCY - screenCenterY
                end

                -- Snap Left to Left
                if math.abs(left - oL) <= SNAP_THRESHOLD then
                    targetX = (oL + fWidth / 2) - screenCenterX
                end
                -- Snap Right to Right
                if math.abs(right - oR) <= SNAP_THRESHOLD then
                    targetX = (oR - fWidth / 2) - screenCenterX
                end
                -- Snap Top to Top
                if math.abs(top - oT) <= SNAP_THRESHOLD then
                    targetY = (oT - fHeight / 2) - screenCenterY
                end
                -- Snap Bottom to Bottom
                if math.abs(bottom - oB) <= SNAP_THRESHOLD then
                    targetY = (oB + fHeight / 2) - screenCenterY
                end

                -- Snap Right to Left
                if math.abs(right - oL) <= SNAP_THRESHOLD then
                    targetX = (oL - fWidth / 2) - screenCenterX
                end
                -- Snap Left to Right
                if math.abs(left - oR) <= SNAP_THRESHOLD then
                    targetX = (oR + fWidth / 2) - screenCenterX
                end
                -- Snap Top to Bottom
                if math.abs(top - oB) <= SNAP_THRESHOLD then
                    targetY = (oB + fHeight / 2) - screenCenterY
                end
                -- Snap Bottom to Top
                if math.abs(bottom - oT) <= SNAP_THRESHOLD then
                    targetY = (oT - fHeight / 2) - screenCenterY
                end
            end
        end
    end

    -- 2. Grid Snapping
    if cfg.snapToGrid then
        local gSize = cfg.gridSize or 32
        targetX = math.floor((targetX / gSize) + 0.5) * gSize
        targetY = math.floor((targetY / gSize) + 0.5) * gSize
    end

    targetX = math.floor(targetX + 0.5)
    targetY = math.floor(targetY + 0.5)

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", targetX, targetY)

    self:SaveFramePosition(name, frame, "CENTER", "CENTER", targetX, targetY)
    self:UpdateOverlayForElement(name)
    self:UpdateHUD()
end

-- ============================================================================
-- SCREEN GRID SYSTEM
-- ============================================================================

local gridFrame
local gridLines = {}

function Movers:CreateGridFrame()
    if gridFrame then return end

    gridFrame = CreateFrame("Frame", "GravityUI_EditMode_Grid", UIParent)
    gridFrame:SetAllPoints(UIParent)
    gridFrame:SetFrameStrata("BACKGROUND")
    gridFrame:SetFrameLevel(0)
    gridFrame:Hide()

    -- Center crosshairs
    local vCenter = gridFrame:CreateTexture(nil, "OVERLAY")
    vCenter:SetColorTexture(0.00, 0.80, 1.00, 0.45) -- Cyan Center
    vCenter:SetWidth(2)
    vCenter:SetPoint("TOP", gridFrame, "TOP", 0, 0)
    vCenter:SetPoint("BOTTOM", gridFrame, "BOTTOM", 0, 0)
    gridFrame.vCenter = vCenter

    local hCenter = gridFrame:CreateTexture(nil, "OVERLAY")
    hCenter:SetColorTexture(0.00, 0.80, 1.00, 0.45) -- Cyan Center
    hCenter:SetHeight(2)
    hCenter:SetPoint("LEFT", gridFrame, "LEFT", 0, 0)
    hCenter:SetPoint("RIGHT", gridFrame, "RIGHT", 0, 0)
    gridFrame.hCenter = hCenter
end

function Movers:UpdateGrid()
    if not gridFrame then self:CreateGridFrame() end
    local cfg = self:GetEditModeSettings()
    if not self.isEditMode or not cfg.showGrid then
        gridFrame:Hide()
        return
    end

    local gSize = cfg.gridSize or 32
    local w, h = UIParent:GetSize()
    local midX, midY = w / 2, h / 2

    for _, line in ipairs(gridLines) do line:Hide() end

    local lineIdx = 1
    local function GetLine()
        local l = gridLines[lineIdx]
        if not l then
            l = gridFrame:CreateTexture(nil, "BACKGROUND")
            l:SetColorTexture(1, 1, 1, 0.10)
            gridLines[lineIdx] = l
        end
        lineIdx = lineIdx + 1
        l:Show()
        return l
    end

    local x = midX + gSize
    while x < w do
        local l = GetLine()
        l:SetWidth(1)
        l:ClearAllPoints()
        l:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", x, 0)
        l:SetPoint("BOTTOMLEFT", gridFrame, "BOTTOMLEFT", x, 0)
        x = x + gSize
    end
    x = midX - gSize
    while x > 0 do
        local l = GetLine()
        l:SetWidth(1)
        l:ClearAllPoints()
        l:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", x, 0)
        l:SetPoint("BOTTOMLEFT", gridFrame, "BOTTOMLEFT", x, 0)
        x = x - gSize
    end

    local y = midY + gSize
    while y < h do
        local l = GetLine()
        l:SetHeight(1)
        l:ClearAllPoints()
        l:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", 0, -y)
        l:SetPoint("TOPRIGHT", gridFrame, "TOPRIGHT", 0, -y)
        y = y + gSize
    end
    y = midY - gSize
    while y > 0 do
        local l = GetLine()
        l:SetHeight(1)
        l:ClearAllPoints()
        l:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", 0, -y)
        l:SetPoint("TOPRIGHT", gridFrame, "TOPRIGHT", 0, -y)
        y = y - gSize
    end

    gridFrame:Show()
end

function Movers:ShowGrid()
    if self.isEditMode then
        self:UpdateGrid()
    else
        self:HideGrid()
    end
end

function Movers:HideGrid()
    if gridFrame then gridFrame:Hide() end
end

-- ============================================================================
-- FLOATING TOP CONTROL HUD (Spacious Layout, No Overlaps)
-- ============================================================================

local hudFrame

function Movers:CreateHUD()
    if hudFrame then return end

    hudFrame = CreateFrame("Frame", "GravityUI_EditMode_HUD", UIParent, "BackdropTemplate")
    hudFrame:SetSize(860, 68)
    hudFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    hudFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    hudFrame:SetFrameLevel(200)
    hudFrame:SetMovable(true)
    hudFrame:EnableMouse(true)
    hudFrame:RegisterForDrag("LeftButton")
    hudFrame:SetScript("OnDragStart", hudFrame.StartMoving)
    hudFrame:SetScript("OnDragStop", hudFrame.StopMovingOrSizing)
    hudFrame:SetClampedToScreen(true)

    -- Backdrop
    hudFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    hudFrame:SetBackdropColor(0.08, 0.09, 0.13, 0.96)
    hudFrame:SetBackdropBorderColor(0.00, 0.75, 1.00, 1.00)

    -- ── COLUMN 1: Title & Selected Element (Left: 12px to 240px) ──────────
    local title = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    title:SetPoint("TOPLEFT", 12, -8)
    title:SetText("|cFF30D1FFGravityUI|r Edit Mode")
    hudFrame.title = title

    local selectedText = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedText:SetPoint("TOPLEFT", 12, -26)
    selectedText:SetWidth(225)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetWordWrap(false)
    selectedText:SetText("|cffaaaaaaNo element selected|r")
    hudFrame.selectedText = selectedText

    local toggleModuleBtn = CreateFrame("Button", nil, hudFrame, "BackdropTemplate")
    toggleModuleBtn:SetSize(110, 18)
    toggleModuleBtn:SetPoint("BOTTOMLEFT", 12, 6)
    toggleModuleBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    toggleModuleBtn:SetBackdropColor(0.12, 0.14, 0.20, 0.9)
    toggleModuleBtn:SetBackdropBorderColor(0.00, 0.75, 1.00, 1)
    local toggleModuleText = toggleModuleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toggleModuleText:SetPoint("CENTER", 0, 0)
    toggleModuleText:SetText("Toggle Module")
    toggleModuleBtn.text = toggleModuleText
    toggleModuleBtn:SetScript("OnClick", function()
        if Movers.selectedMover then
            Movers:ToggleElementEnabled(Movers.selectedMover)
        end
    end)
    hudFrame.toggleModuleBtn = toggleModuleBtn

    -- ── COLUMN 2: Manual X/Y Inputs & D-Pad Cluster (Left: 245px to 395px) ──
    local function CreateCoordBox(axis, xPos, yPos)
        local lbl = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", hudFrame, "TOPLEFT", xPos, yPos - 2)
        lbl:SetText("|cff30d1ff" .. axis .. ":|r")

        local eb = CreateFrame("EditBox", nil, hudFrame, "BackdropTemplate")
        eb:SetSize(46, 18)
        eb:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        eb:SetAutoFocus(false)
        eb:SetFontObject("GameFontHighlightSmall")
        eb:SetJustifyH("CENTER")
        eb:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        eb:SetBackdropColor(0.05, 0.07, 0.10, 0.95)
        eb:SetBackdropBorderColor(0.2, 0.4, 0.6, 1)

        eb:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            local val = tonumber(self:GetText())
            if val and Movers.selectedMover then
                local data = Movers.registry[Movers.selectedMover]
                local frame = data and data.frame
                if frame then
                    local cx, cy = frame:GetCenter()
                    local scx, scy = UIParent:GetCenter()
                    local curX = cx and math.floor(cx - scx + 0.5) or 0
                    local curY = cy and math.floor(cy - scy + 0.5) or 0
                    if axis == "X" then
                        Movers:SetSelectedMoverPosition(val, curY)
                    else
                        Movers:SetSelectedMoverPosition(curX, val)
                    end
                end
            end
        end)
        eb:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            Movers:UpdateHUD()
        end)
        eb:SetScript("OnEditFocusGained", function(self)
            self:HighlightText()
            self:SetBackdropBorderColor(0, 0.9, 1, 1)
        end)
        eb:SetScript("OnEditFocusLost", function(self)
            self:HighlightText(0, 0)
            self:SetBackdropBorderColor(0.2, 0.4, 0.6, 1)
        end)
        return eb
    end

    hudFrame.xInput = CreateCoordBox("X", 245, -12)
    hudFrame.yInput = CreateCoordBox("Y", 245, -35)

    -- D-Pad Nudge Buttons
    local function CreateNudgeBtn(parent, text, dx, dy, point, relTo, relPoint, x, y)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(20, 18)
        btn:SetPoint(point, relTo, relPoint, x, y)
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.15, 0.15, 0.22, 0.9)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.45, 1)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("CENTER", 0, 0)
        fs:SetText(text)

        btn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0, 0.8, 1, 1) end)
        btn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.3, 0.3, 0.45, 1) end)
        btn:SetScript("OnClick", function()
            Movers:NudgeSelectedMover(dx, dy)
        end)
        return btn
    end

    local upBtn    = CreateNudgeBtn(hudFrame, "▲", 0, 1,   "TOPLEFT", hudFrame, "TOPLEFT", 350, -12)
    local downBtn  = CreateNudgeBtn(hudFrame, "▼", 0, -1,  "TOPLEFT", hudFrame, "TOPLEFT", 350, -35)
    local leftBtn  = CreateNudgeBtn(hudFrame, "<", -1, 0,  "RIGHT", upBtn, "LEFT", -2, -11)
    local rightBtn = CreateNudgeBtn(hudFrame, ">", 1, 0,   "LEFT", upBtn, "RIGHT", 2, -11)

    -- ── COLUMN 3: Checkboxes & Grid Controls (Left: 405px to 740px) ───────
    local function CreateHUDCheck(name, label, getVal, setVal, point, relTo, relPoint, x, y)
        local cb = CreateFrame("CheckButton", nil, hudFrame, "InterfaceOptionsCheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint(point, relTo, relPoint, x, y)
        local t = cb.Text or cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetText(label)
        t:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cb.Text = t
        cb:SetChecked(getVal())
        cb:SetScript("OnClick", function(self)
            setVal(self:GetChecked())
        end)
        return cb
    end

    -- Top Checkbox Row
    local gridCheck = CreateHUDCheck("Grid", "Grid", 
        function() return Movers:GetEditModeSettings().showGrid end,
        function(v) 
            local cfg = Movers:GetEditModeSettings()
            cfg.showGrid = v
            Movers:UpdateGrid()
        end,
        "TOPLEFT", hudFrame, "TOPLEFT", 405, -10
    )

    local snapGridCheck = CreateHUDCheck("SnapGrid", "Snap Grid",
        function() return Movers:GetEditModeSettings().snapToGrid end,
        function(v) Movers:GetEditModeSettings().snapToGrid = v end,
        "TOPLEFT", hudFrame, "TOPLEFT", 475, -10
    )

    local snapElemCheck = CreateHUDCheck("SnapElem", "Snap Elements",
        function() return Movers:GetEditModeSettings().snapToElements end,
        function(v) Movers:GetEditModeSettings().snapToElements = v end,
        "TOPLEFT", hudFrame, "TOPLEFT", 570, -10
    )

    -- Bottom Row: Grid Size Buttons & Show Disabled Checkbox
    local function CreateSizeBtn(size, x)
        local btn = CreateFrame("Button", nil, hudFrame, "BackdropTemplate")
        btn:SetSize(22, 18)
        btn:SetPoint("TOPLEFT", hudFrame, "TOPLEFT", 405 + x, -36)
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.15, 0.15, 0.20, 0.9)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.4, 1)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("CENTER", 0, 0)
        fs:SetText(tostring(size))
        btn:SetScript("OnClick", function()
            local cfg = Movers:GetEditModeSettings()
            cfg.gridSize = size
            Movers:UpdateGrid()
        end)
        return btn
    end

    CreateSizeBtn(16, 0)
    CreateSizeBtn(32, 24)
    CreateSizeBtn(64, 48)

    local showDisabledCheck = CreateHUDCheck("ShowDisabled", "Show Disabled",
        function() return Movers:GetEditModeSettings().showDisabled or false end,
        function(v)
            local cfg = Movers:GetEditModeSettings()
            cfg.showDisabled = v
            Movers:UpdateDisplay()
        end,
        "TOPLEFT", hudFrame, "TOPLEFT", 495, -36
    )
    hudFrame.showDisabledCheck = showDisabledCheck

    local showSettingsCheck = CreateHUDCheck("ShowSettings", "Show Settings",
        function() return Movers:GetEditModeSettings().showSettings or false end,
        function(v)
            local cfg = Movers:GetEditModeSettings()
            cfg.showSettings = v
            -- Toggle the settings panel collapse state
            if not settingsPanel then Movers:CreateSettingsPanel() end
            _spCollapsed = not v
            if settingsPanel.collapseText then
                settingsPanel.collapseText:SetText(_spCollapsed and "|cff30d1ff▶|r" or "|cff30d1ff▼|r")
            end
            if _spCollapsed then
                settingsPanel.content:Hide()
                settingsPanel.tabBar:Hide()
                settingsPanel:SetHeight(24)
            else
                settingsPanel.content:Show()
                settingsPanel.tabBar:Show()
                -- Re-show the current mover's settings panel
                if _spCurrentProvider and Movers.selectedMover then
                    Movers:ShowSettingsPanel(Movers.selectedMover)
                else
                    Movers:RefreshSettingsPanel()
                end
            end
        end,
        "TOPLEFT", hudFrame, "TOPLEFT", 620, -36
    )
    hudFrame.showSettingsCheck = showSettingsCheck

    -- ── COLUMN 4: Done / Exit Button (Far Right) ──────────────────────────
    local exitBtn = CreateFrame("Button", nil, hudFrame, "BackdropTemplate")
    exitBtn:SetSize(90, 48)
    exitBtn:SetPoint("RIGHT", hudFrame, "RIGHT", -10, 0)
    exitBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    exitBtn:SetBackdropColor(0.00, 0.60, 0.30, 0.9)
    exitBtn:SetBackdropBorderColor(0.00, 1.00, 0.50, 1)

    local exitText = exitBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    exitText:SetPoint("CENTER", 0, 0)
    exitText:SetText("|cffffffffDone|r\n|cff00FF80Exit Mode|r")
    exitText:SetJustifyH("CENTER")

    exitBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.00, 0.75, 0.40, 1) end)
    exitBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.00, 0.60, 0.30, 0.9) end)
    exitBtn:SetScript("OnClick", function()
        Movers:SetEditMode(false)
    end)

    table.insert(UISpecialFrames, "GravityUI_EditMode_HUD")
    hudFrame:SetScript("OnHide", function(self)
        if Movers.isEditMode then
            Movers:SetEditMode(false)
        end
    end)

    hudFrame:Hide()
end

function Movers:ShowHUD()
    if not hudFrame then self:CreateHUD() end
    self:UpdateHUD()
    hudFrame:Show()
end

function Movers:HideHUD()
    if hudFrame then hudFrame:Hide() end
    self:HideSettingsPanel()
end

-- ============================================================================
-- GENERIC SETTINGS PANEL (Provider Registry + Tabs + Collapsible)
-- ============================================================================

Movers.settingsProviders = {}   -- [pattern] = { label, tabs = { {label, build}, ... } }
local settingsPanel             -- the floating settings frame
local _spCollapsed = true       -- session-only collapse state (default collapsed)
local _spCurrentProvider = nil  -- currently active provider key
local _spCurrentTab = 1         -- currently active tab index
local _spRows = {}              -- active settings rows

-- ── Provider Registration API ─────────────────────────────────────────────
function Movers:RegisterSettingsProvider(pattern, config)
    if config.build and not config.tabs then
        config.tabs = { { label = config.label or "Settings", build = config.build } }
    end
    self.settingsProviders[pattern] = config
end

local function FindProvider(moverName)
    if not moverName then return nil, nil end
    local providers = Movers.settingsProviders
    if providers[moverName] then return moverName, providers[moverName] end
    for pattern, config in pairs(providers) do
        if pattern:find("*", 1, true) then
            local prefix = pattern:gsub("%*", "")
            if moverName:sub(1, #prefix) == prefix then
                return pattern, config
            end
        end
    end
    return nil, nil
end

-- ── Slider Widget ─────────────────────────────────────────────────────────
local function CreateSPSlider(parent, label, min, max, step, getValue, setValue, yPos)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth() - 24, 22)
    row:SetPoint("TOPLEFT", 12, yPos)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 0, 0)
    lbl:SetWidth(110)
    lbl:SetJustifyH("LEFT")
    lbl:SetText("|cffdddddd" .. label .. ":|r")

    local slider = CreateFrame("Slider", nil, row, "BackdropTemplate")
    slider:SetSize(140, 12)
    slider:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    slider:SetBackdropColor(0.08, 0.10, 0.14, 0.95)
    slider:SetBackdropBorderColor(0.20, 0.40, 0.60, 0.8)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(10, 16)
    thumb:SetColorTexture(0.00, 0.75, 1.00, 1.00)
    slider:SetThumbTexture(thumb)

    local valText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
    valText:SetText(tostring(getValue()))

    slider:SetValue(getValue())
    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        valText:SetText(tostring(val))
        setValue(val)
    end)
    slider:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.00, 0.90, 1.00, 1.00) end)
    slider:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.20, 0.40, 0.60, 0.8) end)

    row.slider = slider
    row.valText = valText
    row.Refresh = function()
        slider:SetValue(getValue())
        valText:SetText(tostring(getValue()))
    end
    return row
end

-- ── Dropdown Widget ───────────────────────────────────────────────────────
local function CreateSPDropdown(parent, label, options, getValue, setValue, yPos)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth() - 24, 22)
    row:SetPoint("TOPLEFT", 12, yPos)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 0, 0)
    lbl:SetWidth(110)
    lbl:SetJustifyH("LEFT")
    lbl:SetText("|cffdddddd" .. label .. ":|r")

    local btnFrame = CreateFrame("Button", nil, row, "BackdropTemplate")
    btnFrame:SetSize(120, 18)
    btnFrame:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    btnFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btnFrame:SetBackdropColor(0.1, 0.12, 0.18, 0.95)
    btnFrame:SetBackdropBorderColor(0.3, 0.5, 0.7, 1)

    local valText = btnFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valText:SetPoint("CENTER", 0, 0)

    local function UpdateText()
        local cur = getValue()
        for _, opt in ipairs(options) do
            if opt.value == cur then valText:SetText(opt.text); return end
        end
        valText:SetText(cur or "")
    end
    UpdateText()

    btnFrame:SetScript("OnClick", function()
        local cur = getValue()
        local idx = 1
        for i, opt in ipairs(options) do
            if opt.value == cur then idx = i; break end
        end
        idx = idx % #options + 1
        setValue(options[idx].value)
        UpdateText()
    end)

    row.Refresh = function() UpdateText() end
    return row
end

-- ── Checkbox Widget ───────────────────────────────────────────────────────
local function CreateSPCheckbox(parent, label, getValue, setValue, yPos)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth() - 24, 22)
    row:SetPoint("TOPLEFT", 12, yPos)

    local cb = CreateFrame("CheckButton", nil, row, "InterfaceOptionsCheckButtonTemplate")
    cb:SetSize(18, 18)
    cb:SetPoint("LEFT", 0, 0)
    cb:SetChecked(getValue())
    cb:SetScript("OnClick", function(self) setValue(self:GetChecked()) end)

    local t = cb.Text or cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetText("|cffdddddd" .. label .. "|r")
    t:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.Text = t

    row.Refresh = function() cb:SetChecked(getValue()) end
    return row
end

-- Expose widget creators for providers
ns.SPSlider = CreateSPSlider
ns.SPDropdown = CreateSPDropdown
ns.SPCheckbox = CreateSPCheckbox

-- ── Settings Panel Frame ──────────────────────────────────────────────────
local function ClearPanelContent()
    for _, row in ipairs(_spRows) do
        row:Hide()
        row:SetParent(nil)
    end
    wipe(_spRows)
end

local function BuildTabContent(moverName)
    if not settingsPanel or not _spCurrentProvider then return end

    ClearPanelContent()

    local provider = Movers.settingsProviders[_spCurrentProvider]
    if not provider or not provider.tabs then return end

    local tab = provider.tabs[_spCurrentTab]
    if not tab or not tab.build then return end

    local contentTop = -6
    if #provider.tabs > 1 then contentTop = -6 end  -- tab bar handled by offset

    local rows, finalY = tab.build(settingsPanel.content, moverName, contentTop, -26)
    if rows then
        for _, row in ipairs(rows) do
            _spRows[#_spRows + 1] = row
        end
    end

    local totalH = math.abs(finalY or contentTop) + 12
    settingsPanel.content:SetHeight(totalH)

    local tabBarH = (#provider.tabs > 1) and 26 or 0
    settingsPanel:SetHeight(24 + tabBarH + totalH + 4)
end

function Movers:CreateSettingsPanel()
    if settingsPanel then return end
    if not hudFrame then self:CreateHUD() end

    settingsPanel = CreateFrame("Frame", "GravityUI_EditMode_Settings", hudFrame, "BackdropTemplate")
    settingsPanel:SetWidth(hudFrame:GetWidth())
    settingsPanel:SetHeight(200)
    settingsPanel:SetPoint("TOPLEFT", hudFrame, "BOTTOMLEFT", 0, -2)
    settingsPanel:SetFrameStrata("FULLSCREEN_DIALOG")
    settingsPanel:SetFrameLevel(198)

    settingsPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    settingsPanel:SetBackdropColor(0.06, 0.07, 0.10, 0.97)
    settingsPanel:SetBackdropBorderColor(0.00, 0.60, 0.85, 0.9)

    -- ── Title Bar ──
    local titleBar = CreateFrame("Frame", nil, settingsPanel)
    titleBar:SetHeight(22)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)

    local titleFS = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleFS:SetPoint("LEFT", 8, 0)
    titleFS:SetText("|cff30d1ffSettings|r")
    settingsPanel.titleFS = titleFS

    -- Collapse toggle button
    local collapseBtn = CreateFrame("Button", nil, titleBar)
    collapseBtn:SetSize(18, 18)
    collapseBtn:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)
    local collapseText = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    collapseText:SetPoint("CENTER", 0, 0)
    collapseText:SetText("|cff30d1ff▶|r")  -- starts collapsed
    collapseBtn:SetScript("OnClick", function()
        _spCollapsed = not _spCollapsed
        collapseText:SetText(_spCollapsed and "|cff30d1ff▶|r" or "|cff30d1ff▼|r")
        if _spCollapsed then
            settingsPanel.content:Hide()
            settingsPanel.tabBar:Hide()
            settingsPanel:SetHeight(24)
        else
            settingsPanel.content:Show()
            settingsPanel.tabBar:Show()
            Movers:RefreshSettingsPanel()
        end
    end)
    settingsPanel.collapseText = collapseText

    -- ── Tab Bar ──
    local tabBar = CreateFrame("Frame", nil, settingsPanel)
    tabBar:SetHeight(24)
    tabBar:SetPoint("TOPLEFT", 0, -22)
    tabBar:SetPoint("TOPRIGHT", 0, -22)
    settingsPanel.tabBar = tabBar
    settingsPanel.tabButtons = {}

    -- ── Content Area ──
    local content = CreateFrame("Frame", nil, settingsPanel)
    content:SetPoint("TOPLEFT", settingsPanel.tabBar, "BOTTOMLEFT", 0, 0)
    content:SetPoint("RIGHT", settingsPanel, "RIGHT", 0, 0)
    content:SetHeight(200)
    settingsPanel.content = content

    settingsPanel:Hide()
end

local function UpdateTabBar(provider, moverName)
    if not settingsPanel or not provider then return end

    for _, btn in ipairs(settingsPanel.tabButtons) do btn:Hide() end
    wipe(settingsPanel.tabButtons)

    local tabs = provider.tabs
    if not tabs or #tabs <= 1 then
        settingsPanel.tabBar:SetHeight(0.001)
        return
    end

    settingsPanel.tabBar:SetHeight(24)
    local xOff = 8
    for i, tabDef in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, settingsPanel.tabBar, "BackdropTemplate")
        btn:SetHeight(20)
        btn:SetPoint("LEFT", settingsPanel.tabBar, "LEFT", xOff, 0)
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("CENTER", 0, 0)
        fs:SetText(tabDef.label or ("Tab " .. i))
        btn:SetWidth(fs:GetStringWidth() + 20)

        local isActive = (i == _spCurrentTab)
        if isActive then
            btn:SetBackdropColor(0.00, 0.45, 0.65, 0.95)
            btn:SetBackdropBorderColor(0.00, 0.75, 1.00, 1)
            fs:SetTextColor(1, 1, 1, 1)
        else
            btn:SetBackdropColor(0.10, 0.12, 0.16, 0.9)
            btn:SetBackdropBorderColor(0.25, 0.35, 0.50, 0.8)
            fs:SetTextColor(0.6, 0.6, 0.6, 1)
        end

        btn:SetScript("OnClick", function()
            _spCurrentTab = i
            Movers:RefreshSettingsPanel()
        end)
        btn:SetScript("OnEnter", function(self)
            if i ~= _spCurrentTab then self:SetBackdropBorderColor(0.00, 0.75, 1.00, 0.8) end
        end)
        btn:SetScript("OnLeave", function(self)
            if i ~= _spCurrentTab then self:SetBackdropBorderColor(0.25, 0.35, 0.50, 0.8) end
        end)

        xOff = xOff + btn:GetWidth() + 4
        settingsPanel.tabButtons[#settingsPanel.tabButtons + 1] = btn
    end
end

function Movers:ShowSettingsPanel(moverName)
    if not settingsPanel then self:CreateSettingsPanel() end

    local patternKey, provider = FindProvider(moverName)
    if not provider then
        self:HideSettingsPanel()
        return
    end

    -- Reset tab if provider changed
    if _spCurrentProvider ~= patternKey then
        _spCurrentTab = 1
        -- Respect "Show Settings" checkbox: expand if checked, collapse if not
        local showSettings = Movers:GetEditModeSettings().showSettings
        _spCollapsed = not showSettings
    end
    _spCurrentProvider = patternKey

    if #provider.tabs < _spCurrentTab then _spCurrentTab = 1 end

    local titleLabel = provider.label or "Settings"
    settingsPanel.titleFS:SetText("|cff30d1ff" .. titleLabel .. "|r")
    settingsPanel.collapseText:SetText(_spCollapsed and "|cff30d1ff▶|r" or "|cff30d1ff▼|r")

    if _spCollapsed then
        settingsPanel.content:Hide()
        settingsPanel.tabBar:Hide()
        settingsPanel:SetHeight(24)
    else
        settingsPanel.content:Show()
        settingsPanel.tabBar:Show()
        UpdateTabBar(provider, moverName)
        BuildTabContent(moverName)
    end

    settingsPanel:Show()
end

function Movers:HideSettingsPanel()
    if settingsPanel then
        ClearPanelContent()
        settingsPanel:Hide()
    end
    _spCurrentProvider = nil
end

function Movers:RefreshSettingsPanel()
    if not settingsPanel or not settingsPanel:IsShown() or not _spCurrentProvider then return end
    local name = self.selectedMover
    if not name then self:HideSettingsPanel(); return end

    local _, provider = FindProvider(name)
    if not provider then self:HideSettingsPanel(); return end

    UpdateTabBar(provider, name)
    BuildTabContent(name)
end

-- Legacy compat
function Movers:ShowActionBarHUD(barKey) self:ShowSettingsPanel("ActionBar_" .. barKey) end
function Movers:HideActionBarHUD() self:HideSettingsPanel() end

-- ── UpdateHUD ─────────────────────────────────────────────────────────────
function Movers:UpdateHUD()
    if not hudFrame or not hudFrame:IsShown() then return end

    local name = self.selectedMover
    if name and self.registry[name] then
        local data = self.registry[name]
        local isEnabled = self:IsElementEnabled(name)
        local frame = data.frame
        local label = data.label or name

        local x, y = 0, 0
        local w, h = 0, 0
        if frame then
            local cx, cy = frame:GetCenter()
            local scx, scy = UIParent:GetCenter()
            if cx and scx then
                x = math.floor(cx - scx + 0.5)
                y = math.floor(cy - scy + 0.5)
            end
            local fw, fh = frame:GetSize()
            w = math.floor(fw + 0.5)
            h = math.floor(fh + 0.5)
        end

        local statusTag = isEnabled and "|cff00FF80Active|r" or "|cffff4444Disabled|r"
        hudFrame.selectedText:SetText(string.format("|cffffd700%s|r [%s] (%d × %d)", label, statusTag, w, h))

        if hudFrame.xInput and not hudFrame.xInput:HasFocus() then
            hudFrame.xInput:SetText(tostring(x))
            hudFrame.xInput:Enable()
            hudFrame.xInput:SetAlpha(1)
        end
        if hudFrame.yInput and not hudFrame.yInput:HasFocus() then
            hudFrame.yInput:SetText(tostring(y))
            hudFrame.yInput:Enable()
            hudFrame.yInput:SetAlpha(1)
        end

        hudFrame.toggleModuleBtn:Show()
        if isEnabled then
            hudFrame.toggleModuleBtn.text:SetText("|cffff4444Disable Module|r")
        else
            hudFrame.toggleModuleBtn.text:SetText("|cff00FF80Enable Module|r")
        end

        -- Show settings panel if a provider exists for the selected element
        local _, provider = FindProvider(name)
        if provider then
            self:ShowSettingsPanel(name)
        else
            self:HideSettingsPanel()
        end
    else
        hudFrame.selectedText:SetText("|cff888888No element selected|r")
        if hudFrame.xInput and not hudFrame.xInput:HasFocus() then
            hudFrame.xInput:SetText("")
            hudFrame.xInput:Disable()
            hudFrame.xInput:SetAlpha(0.3)
        end
        if hudFrame.yInput and not hudFrame.yInput:HasFocus() then
            hudFrame.yInput:SetText("")
            hudFrame.yInput:Disable()
            hudFrame.yInput:SetAlpha(0.3)
        end
        hudFrame.toggleModuleBtn:Hide()
        self:HideSettingsPanel()
    end
end

-- ============================================================================
-- EDIT MODE HOOKS (Blizzard Edit Mode Integration)
-- ============================================================================

local function HookEditMode()
    if Movers.hooked then return end

    local function InitHook()
        if Movers.hooked then return end
        if not EditModeManagerFrame then return end

        if EventRegistry then
            EventRegistry:RegisterCallback("EditMode.Enter", function()
                -- Blizzard Edit Mode opened: Ensure GravityUI Edit Mode does NOT automatically open
                if Movers.isEditMode then
                    Movers:SetEditMode(false)
                end
                if Movers.editModeBtn then
                    Movers.editModeBtn:Show()
                end
                if ObjectiveTrackerFrame and not ObjectiveTrackerFrame:IsShown() then
                    ObjectiveTrackerFrame:Show()
                end
            end)

            EventRegistry:RegisterCallback("EditMode.Exit", function()
                if Movers.editModeBtn then
                    Movers.editModeBtn:Hide()
                end
                if ns.Objectives and ns.Objectives.CheckAutoHide then
                    ns.Objectives:CheckAutoHide()
                end
            end)
        end

        -- Create sleek "Open GravityUI Edit Mode" button inside Blizzard Edit Mode dialog
        local btn = CreateFrame("Button", "GravityUI_OpenEditModeButton", EditModeManagerFrame, "BackdropTemplate")
        btn:SetSize(180, 24)
        btn:SetFrameStrata("FULLSCREEN_DIALOG")
        btn:SetFrameLevel(EditModeManagerFrame:GetFrameLevel() + 10)

        if EditModeManagerFrame.LayoutDropdown then
            btn:SetPoint("LEFT", EditModeManagerFrame.LayoutDropdown, "RIGHT", 14, 0)
        else
            btn:SetPoint("TOPRIGHT", EditModeManagerFrame, "TOPRIGHT", -20, -35)
        end

        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets   = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0.08, 0.12, 0.18, 0.95)
        btn:SetBackdropBorderColor(0.00, 0.75, 1.00, 1.0)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnText:SetPoint("CENTER", 0, 0)
        btnText:SetText("|cFF30D1FFOpen GravityUI Edit Mode|r")
        btn.text = btnText

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.00, 0.50, 0.85, 1.0)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("GravityUI Edit Mode", 1, 1, 1)
            GameTooltip:AddLine("Switch from Blizzard Edit Mode to GravityUI's custom element mover.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.08, 0.12, 0.18, 0.95)
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function()
            -- Close Blizzard Edit Mode
            if HideUIPanel then
                HideUIPanel(EditModeManagerFrame)
            else
                EditModeManagerFrame:Hide()
            end
            -- Open GravityUI Edit Mode
            Movers:SetEditMode(true)
        end)

        btn:Hide()
        Movers.editModeBtn = btn
        Movers.hooked = true
    end

    if C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        InitHook()
    else
        local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(self, event, addon)
            if addon == "Blizzard_EditMode" then
                InitHook()
                self:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
end

-- ============================================================================
-- INIT & SLASH COMMANDS
-- ============================================================================

function Movers:Initialize()
    HookEditMode()
    self:CreateGridFrame()
    self:CreateHUD()
end

SLASH_GRAVITYMOVERS1 = "/gravitymovers"
SLASH_GRAVITYMOVERS2 = "/guiedit"
SlashCmdList["GRAVITYMOVERS"] = function()
    Movers:SetEditMode(not Movers.isEditMode)
end

-- Auto-initialize on login
local _initFrame = CreateFrame("Frame")
_initFrame:RegisterEvent("PLAYER_LOGIN")
_initFrame:SetScript("OnEvent", function(self)
    Movers:Initialize()
    self:UnregisterAllEvents()

    -- Register settings providers for all modules (deferred so DB is ready)
    C_Timer.After(0.1, function()
        local db = ns.GetDB and ns.GetDB()
        if not db then return end
        local si = db.screenindicators  -- shorthand

        -- ── Minimap ──
        Movers:RegisterSettingsProvider("Minimap", {
            label = "Minimap Settings",
            build = function(parent, moverName, yPos, rowStep)
                local mdb = db.minimap
                if not mdb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Scale", 0.5, 2.0, 0.05,
                    function() return mdb.scale or 1 end,
                    function(v) mdb.scale = v; if Minimap then Minimap:SetScale(v) end end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                local shapeOpts = {
                    { value = "square", text = "Square" },
                    { value = "round",  text = "Round" },
                }
                r = ns.SPDropdown(parent, "Shape", shapeOpts,
                    function() return mdb.shape or "square" end,
                    function(v) mdb.shape = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Show Clock",
                    function() return mdb.showClock ~= false end,
                    function(v) mdb.showClock = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Show Coordinates",
                    function() return mdb.showCoords == true end,
                    function(v) mdb.showCoords = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Difficulty Indicator ── (db.minimap.difficultyConfig)
        Movers:RegisterSettingsProvider("GravityUI_Difficulty", {
            label = "Difficulty Indicator",
            build = function(parent, moverName, yPos, rowStep)
                local ddb = db.minimap and db.minimap.difficultyConfig
                if not ddb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Scale", 0.5, 2.0, 0.1,
                    function() return ddb.scale or 1 end,
                    function(v) ddb.scale = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── XP/Rep Bar ── (db.styling.xpRep)
        Movers:RegisterSettingsProvider("XPRep", {
            label = "XP/Rep Bar Settings",
            build = function(parent, moverName, yPos, rowStep)
                local xdb = db.styling and db.styling.xpRep
                if not xdb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Width", 100, 1200, 10,
                    function() return xdb.width or 500 end,
                    function(v) xdb.width = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Height", 4, 30, 1,
                    function() return xdb.height or 14 end,
                    function(v) xdb.height = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Font Size", 6, 20, 1,
                    function() return xdb.fontSize or 10 end,
                    function(v) xdb.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Always Show Text",
                    function() return xdb.alwaysShowText == true end,
                    function(v) xdb.alwaysShowText = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Mouseover Only",
                    function() return xdb.mouseover == true end,
                    function(v) xdb.mouseover = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Pet Warnings ── (db.screenindicators.petWarnings)
        Movers:RegisterSettingsProvider("PetWarnings", {
            label = "Pet Warnings",
            build = function(parent, moverName, yPos, rowStep)
                local pw = si and si.petWarnings
                if not pw then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Enabled",
                    function() return pw.enabled ~= false end,
                    function(v) pw.enabled = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Font Size", 12, 48, 1,
                    function() return pw.fontSize or 28 end,
                    function(v) pw.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Pet Dead Warning",
                    function() return pw.petDeadWarning ~= false end,
                    function(v) pw.petDeadWarning = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Pet Attack Warning",
                    function() return pw.petAttackWarning ~= false end,
                    function(v) pw.petAttackWarning = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Combat Status ── (db.screenindicators.combatStatus)
        Movers:RegisterSettingsProvider("CombatStatus", {
            label = "Combat Status",
            build = function(parent, moverName, yPos, rowStep)
                local cs = si and si.combatStatus
                if not cs then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Enabled",
                    function() return cs.enabled ~= false end,
                    function(v) cs.enabled = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Font Size", 8, 32, 1,
                    function() return cs.fontSize or 14 end,
                    function(v) cs.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Display Time", 0.3, 5, 0.1,
                    function() return cs.displayTime or 0.8 end,
                    function(v) cs.displayTime = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Fade Time", 0.1, 3, 0.1,
                    function() return cs.fadeTime or 0.3 end,
                    function(v) cs.fadeTime = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Healer Mana ── (db.screenindicators.healerMana)
        Movers:RegisterSettingsProvider("HealerMana", {
            label = "Healer Mana Tracker",
            build = function(parent, moverName, yPos, rowStep)
                local hm = si and si.healerMana
                if not hm then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Enabled",
                    function() return hm.enabled == true end,
                    function(v) hm.enabled = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Icon Size", 16, 48, 1,
                    function() return hm.iconSize or 24 end,
                    function(v) hm.iconSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Font Size", 8, 24, 1,
                    function() return hm.fontSize or 12 end,
                    function(v) hm.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Frame Width", 80, 300, 5,
                    function() return hm.frameWidth or 160 end,
                    function(v) hm.frameWidth = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Max Healers", 1, 5, 1,
                    function() return hm.maxHealers or 3 end,
                    function(v) hm.maxHealers = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Grow Down",
                    function() return hm.growDown ~= false end,
                    function(v) hm.growDown = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Battle Res Tracker ── (db.screenindicators.battleRes)
        Movers:RegisterSettingsProvider("BattleResTracker", {
            label = "Battle Res Tracker",
            build = function(parent, moverName, yPos, rowStep)
                local br = si and si.battleRes
                if not br then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Enabled",
                    function() return br.enabled == true end,
                    function(v) br.enabled = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Icon Size", 20, 64, 1,
                    function() return br.iconSize or 36 end,
                    function(v) br.iconSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Font Size", 8, 24, 1,
                    function() return br.fontSize or 12 end,
                    function(v) br.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Bloodlust Tracker ── (db.screenindicators.bloodlust)
        Movers:RegisterSettingsProvider("BloodlustTracker", {
            label = "Bloodlust Tracker",
            build = function(parent, moverName, yPos, rowStep)
                local bl = si and si.bloodlust
                if not bl then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Enabled",
                    function() return bl.enabled == true end,
                    function(v) bl.enabled = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Icon Size", 20, 64, 1,
                    function() return bl.iconSize or 36 end,
                    function(v) bl.iconSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Font Size", 8, 24, 1,
                    function() return bl.fontSize or 12 end,
                    function(v) bl.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Combat Timer ──
        Movers:RegisterSettingsProvider("CombatTimer", {
            label = "Combat Timer Settings",
            build = function(parent, moverName, yPos, rowStep)
                local ctdb = db.uiimprovements and db.uiimprovements.combatTimer
                if not ctdb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Font Size", 8, 32, 1,
                    function() return ctdb.fontSize or 14 end,
                    function(v) ctdb.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Raid Warnings ──
        Movers:RegisterSettingsProvider("RaidWarnings", {
            label = "Raid Warnings Settings",
            build = function(parent, moverName, yPos, rowStep)
                local rwdb = db.raidWarnings
                if not rwdb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Font Size", 12, 48, 1,
                    function() return rwdb.fontSize or 24 end,
                    function(v) rwdb.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Duration", 1, 15, 0.5,
                    function() return rwdb.duration or 5 end,
                    function(v) rwdb.duration = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── World Marks ──
        Movers:RegisterSettingsProvider("WorldMarks", {
            label = "World Marks Settings",
            build = function(parent, moverName, yPos, rowStep)
                local wmdb = db.uiimprovements and db.uiimprovements.marks
                if not wmdb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Button Size", 16, 48, 1,
                    function() return wmdb.buttonSize or 24 end,
                    function(v) wmdb.buttonSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Cooldown Tracker ──
        Movers:RegisterSettingsProvider("CooldownText", {
            label = "Cooldown Tracker Settings",
            build = function(parent, moverName, yPos, rowStep)
                local cddb = db.cooldownText
                if not cddb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Icon Size", 20, 64, 1,
                    function() return cddb.iconSize or 36 end,
                    function(v) cddb.iconSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Max Icons", 1, 12, 1,
                    function() return cddb.maxIcons or 6 end,
                    function(v) cddb.maxIcons = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Spacing", 0, 20, 1,
                    function() return cddb.spacing or 4 end,
                    function(v) cddb.spacing = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Loot Window ──
        Movers:RegisterSettingsProvider("LootWindow", {
            label = "Loot Window Settings",
            build = function(parent, moverName, yPos, rowStep)
                local ldb = db.styling and db.styling.loot
                if not ldb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Loot Under Mouse",
                    function() return ldb.lootUnderMouse == true end,
                    function(v) ldb.lootUnderMouse = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Interrupt Tracker ──
        Movers:RegisterSettingsProvider("InterruptTracker", {
            label = "Interrupt Tracker Settings",
            build = function(parent, moverName, yPos, rowStep)
                local itdb = si and si.interruptTracker
                if not itdb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Icon Size", 20, 64, 1,
                    function() return itdb.iconSize or 32 end,
                    function(v) itdb.iconSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Stance Text ──
        Movers:RegisterSettingsProvider("StanceText", {
            label = "Stance Text",
            build = function(parent, moverName, yPos, rowStep)
                local stdb = db.uiimprovements and db.uiimprovements.stanceText
                if not stdb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Font Size", 8, 24, 1,
                    function() return stdb.fontSize or 12 end,
                    function(v) stdb.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Alerts Anchor ──
        Movers:RegisterSettingsProvider("Alerts", {
            label = "Alerts Anchor",
            build = function(parent, moverName, yPos, rowStep)
                local rows = {}
                -- Position-only element, no additional settings
                return rows, yPos
            end,
        })

        -- ── Toasts Anchor ──
        Movers:RegisterSettingsProvider("Toasts", {
            label = "Toasts Anchor",
            build = function(parent, moverName, yPos, rowStep)
                local rows = {}
                return rows, yPos
            end,
        })

        -- ── Icon Catcher ──
        Movers:RegisterSettingsProvider("IconCatcher", {
            label = "Icon Catcher",
            build = function(parent, moverName, yPos, rowStep)
                local icdb = db.uiimprovements and db.uiimprovements.iconCatcher
                if not icdb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPSlider(parent, "Icon Size", 20, 64, 1,
                    function() return icdb.iconSize or 36 end,
                    function(v) icdb.iconSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Death Announcer ── (top-level: db.deathAnnouncer)
        Movers:RegisterSettingsProvider("DeathAnnouncer", {
            label = "Death Announcer",
            build = function(parent, moverName, yPos, rowStep)
                local dadb = db.deathAnnouncer
                if not dadb then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Enabled",
                    function() return dadb.enabled == true end,
                    function(v) dadb.enabled = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Font Size", 12, 48, 1,
                    function() return dadb.fontSize or 24 end,
                    function(v) dadb.fontSize = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Duration", 1, 10, 0.5,
                    function() return dadb.duration or 3 end,
                    function(v) dadb.duration = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Use Class Color",
                    function() return dadb.useClassColor ~= false end,
                    function(v) dadb.useClassColor = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Crosshair ── (db.screenindicators.crosshair)
        Movers:RegisterSettingsProvider("Crosshair", {
            label = "Crosshair Settings",
            build = function(parent, moverName, yPos, rowStep)
                local ch = si and si.crosshair
                if not ch then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Enabled",
                    function() return ch.enabled == true end,
                    function(v) ch.enabled = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Size", 3, 30, 1,
                    function() return ch.size or 9 end,
                    function(v) ch.size = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Thickness", 1, 6, 1,
                    function() return ch.thickness or 2 end,
                    function(v) ch.thickness = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Color on Range",
                    function() return ch.changeColorOnRange ~= false end,
                    function(v) ch.changeColorOnRange = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPCheckbox(parent, "Only In Combat",
                    function() return ch.onlyInCombat == true end,
                    function(v) ch.onlyInCombat = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Ready Check ── (db.styling.readyCheck)
        Movers:RegisterSettingsProvider("ReadyCheck", {
            label = "Ready Check",
            build = function(parent, moverName, yPos, rowStep)
                local rc = db.styling and db.styling.readyCheck
                if not rc then return {}, yPos end
                local rows, r = {}, nil

                r = ns.SPCheckbox(parent, "Use Default Position",
                    function() return rc.useDefaultPosition ~= false end,
                    function(v) rc.useDefaultPosition = v end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })

        -- ── Position-only movers (no custom settings, just label) ──
        local positionOnlyMovers = {
            { name = "BonusRoll",          label = "Bonus Roll" },
            { name = "LootRolls",          label = "Loot Rolls" },
            { name = "PowerBarAlt",        label = "Power Bar (Alt)" },
            { name = "WidgetBelowMinimap", label = "Widget Below Minimap" },
            { name = "WidgetPowerBar",     label = "Widget Power Bar" },
            { name = "WidgetTopCenter",    label = "Widget Top Center" },
        }

        for _, info in ipairs(positionOnlyMovers) do
            Movers:RegisterSettingsProvider(info.name, {
                label = info.label,
                build = function(parent, moverName, yPos, rowStep)
                    return {}, yPos
                end,
            })
        end

        -- ── Data Panels (dynamic: DataPanel_*) ──
        Movers:RegisterSettingsProvider("DataPanel_*", {
            label = "Data Panel Settings",
            build = function(parent, moverName, yPos, rowStep)
                local panelId = moverName:match("^DataPanel_(.+)$")
                if not panelId then return {}, yPos end
                local dpdb = db.datapanels and db.datapanels.custom and db.datapanels.custom[panelId]
                if not dpdb then return {}, yPos end
                local rows, r = {}, nil
                local refreshDP = function()
                    if ns.DP and ns.DP.RefreshAll then ns.DP:RefreshAll() end
                end

                r = ns.SPSlider(parent, "Num Slots", 0, 5, 1,
                    function() return dpdb.numSlots or 3 end,
                    function(v) dpdb.numSlots = v; refreshDP() end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Width", 80, 600, 10,
                    function() return dpdb.width or 200 end,
                    function(v) dpdb.width = v; refreshDP() end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                r = ns.SPSlider(parent, "Height", 14, 50, 1,
                    function() return dpdb.height or 22 end,
                    function(v) dpdb.height = v; refreshDP() end, yPos)
                rows[#rows + 1] = r; yPos = yPos + rowStep

                return rows, yPos
            end,
        })
    end)
end)
