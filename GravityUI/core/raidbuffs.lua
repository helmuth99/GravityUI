
local ADDON_NAME, ns = ...

---------------------------------------------------------------------------
-- RAID BUFFS DISPLAY
-- Custom port for modern retail WoW
---------------------------------------------------------------------------

local RaidBuffs = {}
ns.RaidBuffs = RaidBuffs

-- Constants
local ICON_SIZE = 32
local ICON_SPACING = 4
local UPDATE_THROTTLE = 0.5
local MAX_AURA_INDEX = 40

-- Buff definitions
local RAID_BUFFS = {
    {
        spellId = 21562,
        name = "Power Word: Fortitude",
        stat = "Stamina",
        providerClass = "PRIEST",
        range = 40,
    },
    {
        spellId = 6673,
        name = "Battle Shout",
        stat = "Attack Power",
        providerClass = "WARRIOR",
        range = 100,
    },
    {
        spellId = 1459,
        name = "Arcane Intellect",
        stat = "Intellect",
        providerClass = "MAGE",
        range = 40,
    },
    {
        spellId = 1126,
        name = "Mark of the Wild",
        stat = "Versatility",
        providerClass = "DRUID",
        range = 40,
    },
    {
        -- Evoker Bronze
        spellId = 381748,
        name = "Blessing of the Bronze",
        stat = "Movement Speed",
        providerClass = "EVOKER",
        range = 40,
    },
    {
        -- Shaman Skyfury
        spellId = 462854,
        name = "Skyfury",
        stat = "Mastery",
        providerClass = "SHAMAN",
        range = 100,
    },
}

-- Helpers
local function GetBuffIcon(spellId)
    local texture = C_Spell.GetSpellTexture(spellId)
    return texture or 134400
end

local function GetSettings()
    if ns.db and ns.db.profile and ns.db.profile.raidBuffs then
        return ns.db.profile.raidBuffs
    end
    -- Fallback
    return { enabled = false } 
end

-- State
local mainFrame
local buffIcons = {}
local lastUpdate = 0
local groupClasses = {}
local previewMode = false

-- Utility to get accent color
local function GetAccentColor()
    if ns.GetAccentColor then return ns.GetAccentColor() end
    return 0, 0.6, 1, 1 -- Fallback blue
end

local function GetFontPath()
    if ns.Styling and ns.Styling.GetFontPath then
        return ns.Styling:GetFontPath() -- Need to ensure Styling helper is accessible or redefine here
    end
    -- Redefine simple version if needed or access global
    local general = ns.db.profile.general
    local fontName = (general and general.font) or "Gravity"
    return LibStub("LibSharedMedia-3.0"):Fetch("font", fontName)
end

-- Logic
local function ScanGroupClasses()
    wipe(groupClasses)
    local _, playerClass = UnitClass("player")
    if playerClass then groupClasses[playerClass] = true end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
             local _, class = UnitClass("raid"..i)
             if class then groupClasses[class] = true end
        end
    elseif IsInGroup() then
         for i = 1, GetNumGroupMembers() - 1 do
             local _, class = UnitClass("party"..i)
             if class then groupClasses[class] = true end
        end
    end
end

-- Localized Name Cache
local localizedNames = {}

-- Initialize Cache
local function InitCache()
    for _, buff in ipairs(RAID_BUFFS) do
        local info = C_Spell.GetSpellInfo(buff.spellId)
        if info and info.name then
            localizedNames[buff.spellId] = info.name
        else
            localizedNames[buff.spellId] = buff.name -- Fallback
        end
    end
end

local function UnitHasBuff(unit, spellId, fallbackName)
    if not unit then return false end
    
    -- Ensure cache is populated
    if not localizedNames[spellId] then
        local info = C_Spell.GetSpellInfo(spellId)
        if info and info.name then
            localizedNames[spellId] = info.name
        else
            localizedNames[spellId] = fallbackName
        end
    end
    
    local name = localizedNames[spellId]
    if not name then return false end

    -- Fast Lookup by Name (O(1) in C)
    local aura = C_UnitAuras.GetAuraDataBySpellName(unit, name, "HELPFUL")
    if aura then
        -- Optional: Verify SpellID to be 100% sure (handling shared names)
        if aura.spellId == spellId then
            return true
        end
        -- If name matches but ID differs, it might be a variant (e.g. diff rank). 
        -- Usually name match is sufficient for raid buffs.
        return true
    end
    
    return false
end

local function GetMissingBuffs()
    local missing = {}
    local settings = GetSettings()

    if previewMode then
        -- Return fake missing buffs for preview
        return {
            RAID_BUFFS[1], -- Fortitude
            RAID_BUFFS[2], -- Battle Shout
            RAID_BUFFS[3]  -- Intellect
        }
    end

    -- Conditions
    if settings.showOnlyInGroup and not IsInGroup() then return missing end
    if settings.showOnlyInInstance and not IsInInstance() then return missing end -- Needs IsInInstance check refinement for "instance only" vs "instanced content"
    if InCombatLockdown() then return missing end

    ScanGroupClasses()
    local _, playerClass = UnitClass("player")

    for _, buff in ipairs(RAID_BUFFS) do
        -- Logic: If provider is in group, and I don't have it
        if groupClasses[buff.providerClass] then
            if not UnitHasBuff("player", buff.spellId, buff.name) then
                table.insert(missing, buff)
            end
        end
        
        -- "Also Show Buffs You Can Provide"
        if settings.providerMode then
            if buff.providerClass == playerClass then
                 -- Check group members if they are missing it. 
                 -- Optimization: Just check if *anyone* is missing it for now to show the icon?
                 -- The original code checks each member.
                 -- Simplified for brevity: If I am the provider, and I see someone missing it within range?
                 -- Implementing simplified check:
                 local function AnyoneMissing(spellId, name)
                     if IsInRaid() then
                        for i=1, GetNumGroupMembers() do
                            if not UnitHasBuff("raid"..i, spellId, name) and not UnitIsDeadOrGhost("raid"..i) and UnitIsConnected("raid"..i) then return true end
                        end
                     elseif IsInGroup() then
                        for i=1, GetNumGroupMembers() - 1 do
                            if not UnitHasBuff("party"..i, spellId, name) and not UnitIsDeadOrGhost("party"..i) and UnitIsConnected("party"..i) then return true end
                        end
                     end
                     return false
                 end
                 
                 -- Avoid duplicates if already added
                 local already = false
                 for _, m in ipairs(missing) do if m.spellId == buff.spellId then already = true break end end
                 
                 if not already and AnyoneMissing(buff.spellId, buff.name) then
                     table.insert(missing, buff)
                 end
            end
        end
    end
    
    return missing
end

-- UI
local function CreateBuffIcon(parent, index)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(ICON_SIZE, ICON_SIZE)
    
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    return button
end

local function UpdateSkin()
    if not mainFrame then return end
    local settings = GetSettings()
    
    local sr, sg, sb, sa = GetAccentColor()
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
    
    -- Label Bar
    mainFrame.labelBar:SetBackdropColor(bgr, bgg, bgb, bga)
    mainFrame.labelBar:SetBackdropBorderColor(sr, sg, sb, sa)
    
    -- Icons
    for _, icon in pairs(buffIcons) do
        icon:SetBackdropBorderColor(sr, sg, sb, sa)
        icon:SetBackdropColor(0, 0, 0, 0.8)
    end
    
    -- Text Color
    if settings.labelTextColor then
        mainFrame.labelBar.text:SetTextColor(unpack(settings.labelTextColor))
    else
        mainFrame.labelBar.text:SetTextColor(1, 1, 1, 1)
    end
    
    -- Font Size
    local fontSize = settings.labelFontSize or 12
    mainFrame.labelBar.text:SetFont(GetFontPath(), fontSize, "OUTLINE")
end

local function CreateMainFrame()
    if mainFrame then return mainFrame end
    
    mainFrame = CreateFrame("Frame", "GravityUI_RaidBuffs", UIParent)
    mainFrame:SetSize(200, 70)
    mainFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:RegisterForDrag("LeftButton")
    
    mainFrame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local settings = GetSettings()
        if settings then
            local point, _, relPoint, x, y = self:GetPoint()
            settings.position = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)
    
    -- Icon Container
    mainFrame.iconContainer = CreateFrame("Frame", nil, mainFrame)
    mainFrame.iconContainer:SetPoint("TOP", mainFrame, "TOP", 0, 0)
    mainFrame.iconContainer:SetSize(200, ICON_SIZE)
    
    -- Label Bar
    mainFrame.labelBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    mainFrame.labelBar:SetPoint("TOP", mainFrame.iconContainer, "BOTTOM", 0, -2)
    mainFrame.labelBar:SetSize(100, 18)
    mainFrame.labelBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    
    mainFrame.labelBar.text = mainFrame.labelBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainFrame.labelBar.text:SetPoint("CENTER", 0, 0)
    mainFrame.labelBar.text:SetText("Missing Buffs")
    
    mainFrame:Hide()
    return mainFrame
end

local function UpdateDisplay()
    local settings = GetSettings()
    if not settings or not settings.enabled then
        if mainFrame then mainFrame:Hide() end
        return
    end
    
    if not mainFrame then CreateMainFrame() end
    UpdateSkin() -- Ensure colors are fresh
    
    -- Reposition if saved
    if settings.position then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(settings.position.point, UIParent, settings.position.relPoint, settings.position.x, settings.position.y)
    end
    
    local missing = GetMissingBuffs()
    
    if #missing == 0 then
        mainFrame:Hide()
        return
    end
    
    local iconSize = settings.iconSize or 32
    local fontSize = settings.labelFontSize or 12
    
    -- Layout Icons
    local numMissing = #missing
    local totalWidth = (numMissing * iconSize) + ((numMissing - 1) * ICON_SPACING)
    local startX = -totalWidth / 2 + iconSize / 2
    
    for i = 1, #RAID_BUFFS do
        if not buffIcons[i] then
            buffIcons[i] = CreateBuffIcon(mainFrame.iconContainer, i)
        end
        local icon = buffIcons[i]
        
        if i <= numMissing then
            local buff = missing[i]
            icon:SetSize(iconSize, iconSize)
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", mainFrame.iconContainer, "CENTER", startX + (i - 1) * (iconSize + ICON_SPACING), 0)
            icon.icon:SetTexture(GetBuffIcon(buff.spellId))
            icon:Show()
            
            -- Simple Tooltip
            icon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(buff.name)
                GameTooltip:AddLine(buff.stat, 1, 1, 1)
                GameTooltip:Show()
            end)
            icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
        else
            icon:Hide()
        end
    end
        -- Frame Sizing
    local bgHeight = fontSize + 8
    
    mainFrame.labelBar.text:SetFont(GetFontPath(), fontSize, "OUTLINE")
    local textWidth = mainFrame.labelBar.text:GetStringWidth() + 16 -- padding
    local contentWidth = totalWidth
    
    -- Width is max of icons or text, ensuring minimum for single icon isn't too small for text
    local frameWidth = math.max(contentWidth, textWidth)
    
    -- Update icon container to match new width so icons stay centered
    mainFrame.iconContainer:SetSize(frameWidth, iconSize)
    
    if settings.hideLabelBar then
        mainFrame.labelBar:Hide()
        mainFrame:SetSize(math.max(totalWidth, 20), iconSize)
    else
        mainFrame.labelBar:Show()
        mainFrame.labelBar:SetSize(frameWidth, bgHeight)
        mainFrame:SetSize(frameWidth, iconSize + bgHeight)
    end
    
    mainFrame:Show()
end

-- Refresh / Toggle
function RaidBuffs:Refresh()
    UpdateDisplay()
end

function RaidBuffs:TogglePreview()
    previewMode = not previewMode
    if previewMode and not mainFrame then CreateMainFrame() end
    UpdateDisplay()
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitCache()
        C_Timer.After(2, UpdateDisplay)
    else
        -- Throttle updates
        if self.updatePending then return end
        self.updatePending = true
        C_Timer.After(0.5, function()
             self.updatePending = false
             UpdateDisplay()
        end)
    end
end)
