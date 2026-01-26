-- GravityUI - World Marks Module
-- Quick bar for raid markers and world markers
local ADDON_NAME, ns = ...

local WorldMarks = {}
ns.WorldMarks = WorldMarks

local function GetSettings()
    local db = ns.GetDB()
    if db and db.uiimprovements and db.uiimprovements.marks then
        return db.uiimprovements.marks
    end
    return nil
end

---------------------------------------------------------------------------
-- REFRESH LOGIC
---------------------------------------------------------------------------
function WorldMarks.Refresh()
    local frame = WorldMarks.frame
    if not frame then return end
    
    if InCombatLockdown() then return end
    
    local settings = GetSettings()
    if not settings then return end
    
    local width = (settings.size * 9) + (settings.spacing * 10)
    local height = settings.size + (settings.spacing * 2)
    frame:SetSize(width, height)
    
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", settings.offsetX or 0, settings.offsetY or 100)
    
    if settings.enabled then 
        frame:Show() 
    else 
        frame:Hide() 
    end
    
    if settings.mouseover then 
        frame:SetAlpha(0) 
    else 
        frame:SetAlpha(1) 
    end

    -- Update Buttons
    for i = 1, 9 do
        local btn = frame.buttons[i]
        if btn then
            btn:SetSize(settings.size, settings.size)
            local xOffset = settings.spacing + ((i-1) * (settings.size + settings.spacing))
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", frame, "LEFT", xOffset, 0)
        end
    end
    
    -- Update Border
    if settings.hideBorder then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = nil,
            edgeSize = 0,
        })
    else
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        
        local r, g, b, a
        if settings.useThemeColorBorder then
            r, g, b, a = ns.GetAccentColor()
        else
            r, g, b, a = unpack(settings.borderColor or {0, 0, 0, 1})
        end
        frame:SetBackdropBorderColor(r, g, b, a or 1)
    end
    
    frame:SetBackdropColor(0, 0, 0, 0.6)
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local function CreateMarksBar()
    if WorldMarks.frame then return end
    
    local settings = GetSettings()
    if not settings then return end

    local frame = CreateFrame("Frame", "GravityUI_MarksBar", UIParent, "BackdropTemplate")
    frame.buttons = {}
    
    frame:EnableMouse(true)
    frame:SetFrameStrata("MEDIUM")
    
    -- Initial backdrop will be set by Refresh()
    
    local function UpdateAlpha(alpha)
        local s = GetSettings()
        if s and s.mouseover then 
            frame:SetAlpha(alpha) 
        else 
            frame:SetAlpha(1) 
        end
    end

    frame:SetScript("OnEnter", function() UpdateAlpha(1) end)
    frame:SetScript("OnLeave", function() if not frame:IsMouseOver() then UpdateAlpha(0) end end)

    -- Button Creation
    for i = 1, 9 do
        local btn = CreateFrame("Button", "GravityUIMarkerBtn"..i, frame, "SecureActionButtonTemplate")
        btn:RegisterForClicks("AnyUp", "AnyDown") 
        btn:SetAttribute("type", "macro") 

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 2, -2)
        tex:SetPoint("BOTTOMRIGHT", -2, 2)
        
        if i < 9 then
            tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
            SetRaidTargetIconTexture(tex, i)
            
            -- Worldmarker mapping (Legacy mapping)
            local wmMap = { [1]=5, [2]=6, [3]=3, [4]=2, [5]=7, [6]=1, [7]=4, [8]=8 }
            local wmID = wmMap[i] or i
            
            -- [nomod:shift] = Target Mark, [mod:shift] = World Mark
            btn:SetAttribute("macrotext", "/tm [nomod:shift] " .. i .. "\n/wm [mod:shift] " .. wmID)
        else
            -- Clear Button
            tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            btn:SetAttribute("macrotext", "/tm [target=player,nomod:shift] 0\n/tm [nomod:shift] 0\n/clearraidmarkers [nomod:shift]\n/cwm [mod:shift] all")
        end
        
        btn:HookScript("OnEnter", function() UpdateAlpha(1) end)
        btn:HookScript("OnLeave", function() if not frame:IsMouseOver() then UpdateAlpha(0) end end)
        
        frame.buttons[i] = btn
    end

    WorldMarks.frame = frame
    WorldMarks.Refresh()
    
    -- Hide if initially needed (Refesh handles it but let's be sure)
    UpdateAlpha(0)
end

-- Export to ns for init
ns.RefreshWorldMarks = WorldMarks.Refresh

-- Auto-Init
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    CreateMarksBar()
end)

-- Hook into global color refresh
local originalRefreshColors = ns.RefreshAccentColors
ns.RefreshAccentColors = function()
    if originalRefreshColors then originalRefreshColors() end
    if WorldMarks.Refresh then WorldMarks.Refresh() end
end

-- Export for GUI
_G.GravityUI_RefreshWorldMarks = WorldMarks.Refresh
