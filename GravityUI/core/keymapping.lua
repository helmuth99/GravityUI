local ADDON_NAME, ns = ...

-- ═══════════════════════════════════════════════════════════════
-- GUICDM KEYBINDS MODULE
-- ═══════════════════════════════════════════════════════════════
ns.GUICDM_Keybinds = {}
local Module = ns.GUICDM_Keybinds

-- Cache
local spellKeybinds = {} -- [spellID/Name] = "KeybindText"
Module.knownFrames = {} -- [frame] = true
local lastScan = 0
local SCAN_THROTTLE = 2.0 -- Don't scan action bars too often
local HOOK_SET = false

local barToSettingsKey = {
    ["EssentialCooldownViewer"] = "essential",
    ["UtilityCooldownViewer"] = "utility",
    ["BCDM_CustomCooldownViewer"] = "custom",
    ["BCDM_AdditionalCustomCooldownViewer"] = "additionalCustom",
    ["BCDM_TrinketBar"] = "trinket",
    ["BCDM_CustomItemBar"] = "item",
    ["BCDM_CustomItemSpellBar"] = "itemSpell",
}

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════

local function GetSettings()
    return ns.db.profile.actionbars.guicdm
end

local function GetFontPath()
    if ns.Styling and ns.Styling.GetFontPath then
        return ns.Styling:GetFontPath()
    end
    -- Fallback
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local fontName = ns.db.profile.general.font or "Gravity"
    return LSM and LSM:Fetch("font", fontName) or STANDARD_TEXT_FONT
end

local function GetKeysForSlot(slot, prefix, index)
    -- 1. Try Standard Binding
    local k1, k2 = GetBindingKey(prefix .. index)
    if k1 then return k1, k2 end

    -- 2. Try Bartender4
    if _G.Bartender4 then
        k1, k2 = GetBindingKey("CLICK BT4Button" .. slot .. ":LeftButton")
        if k1 then return k1, k2 end
    end

    -- 3. Try Dominos Specific
    if _G.Dominos then
        k1, k2 = GetBindingKey("CLICK DominosActionButton" .. slot .. ":HOTKEY")
        if not k1 then k1, k2 = GetBindingKey("CLICK DominosActionButton" .. slot .. ":LeftButton") end
        if k1 then return k1, k2 end
    end
    
    return nil
end

-- Robust Action Bar Scan for Retail
local function ScanActionBars(force)
    local now = GetTime()
    if not force and (now - lastScan) < SCAN_THROTTLE then return end
    lastScan = now
    
    wipe(spellKeybinds)

    local barConfigs = {
        { start = 1,  ending = 12, prefix = "ACTIONBUTTON" },        -- Bar 1
        { start = 13, ending = 24, prefix = "ACTIONBAR2BUTTON" }, -- Bar 2
        { start = 25, ending = 36, prefix = "MULTIACTIONBAR3BUTTON" }, -- Bar 3 (Side Right)
        { start = 37, ending = 48, prefix = "MULTIACTIONBAR4BUTTON" }, -- Bar 4 (Side Right 2)
        { start = 49, ending = 60, prefix = "MULTIACTIONBAR2BUTTON" }, -- Bar 5 (Bottom Right)
        { start = 61, ending = 72, prefix = "MULTIACTIONBAR1BUTTON" }, -- Bar 6 (Bottom Left)
        -- Dragonflight Bars (5-8)
        { start = 73, ending = 84,  prefix = "MULTIACTIONBAR5BUTTON" },
        { start = 85, ending = 96,  prefix = "MULTIACTIONBAR6BUTTON" },
        { start = 97, ending = 108, prefix = "MULTIACTIONBAR7BUTTON" },
        { start = 109,ending = 120, prefix = "MULTIACTIONBAR8BUTTON" }, 
        -- Paging / Dominos extras
        { start = 121,ending = 132, prefix = "MULTIACTIONBAR9BUTTON" }, 
        { start = 133,ending = 144, prefix = "MULTIACTIONBAR10BUTTON" },
        { start = 145,ending = 156, prefix = "MULTIACTIONBAR5BUTTON" },
        { start = 157,ending = 168, prefix = "MULTIACTIONBAR6BUTTON" },
        { start = 169,ending = 180, prefix = "MULTIACTIONBAR7BUTTON" },
    }

    for _, config in ipairs(barConfigs) do
        for i = 0, (config.ending - config.start) do
            local slot = config.start + i
            local actionType, id = GetActionInfo(slot)
            
            local name, bindId
            local buttonIndex = i + 1
            local key, _ = GetKeysForSlot(slot, config.prefix, buttonIndex)
            
            if key then
                key = key:gsub("SHIFT", "S"):gsub("CTRL", "C"):gsub("ALT", "A")
                key = key:gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD")
                key = key:gsub("BUTTON3", "M3"):gsub("BUTTON4", "M4"):gsub("BUTTON5", "M5")
                key = key:gsub("SPACE", "Spc"):gsub("%-", "")
            end

            if actionType == "spell" and id then
                 bindId = id
                 local info = C_Spell.GetSpellInfo(id)
                 if info then name = info.name end
            elseif actionType == "macro" and id then
                 local mname, _, body = GetMacroInfo(id)
                 if mname and key then spellKeybinds[mname:lower()] = key end
                 
                 local mid = GetMacroSpell(id)
                 local mitem, mlink = GetMacroItem(id)
                 
                 if mid then
                     bindId = mid
                     local info = C_Spell.GetSpellInfo(mid)
                     if info then name = info.name end
                 elseif mlink then
                     local itemId = mlink:match("item:(%d+)")
                     if itemId then
                        bindId = tonumber(itemId)
                        local itemName = GetItemInfo(itemId)
                        if itemName then 
                            name = itemName 
                            if key then spellKeybinds[name:lower()] = key end
                        end
                        local itemSpell = GetItemSpell(itemId)
                        if itemSpell and key then spellKeybinds[itemSpell:lower()] = key end
                     end
                 elseif body then
                      -- Fallback: Parse macro text
                      local tooltips = body:match("#showtooltip%s+([^\n]+)")
                      if not tooltips then
                           for line in body:gmatch("[^\r\n]+") do
                               local cleanLine = line:match("^%s*(.+)")
                               if cleanLine then
                                   local l = cleanLine:lower()
                                   if l:find("^/cast") or l:find("^/use") or l:find("^/castsequence") or l:find("^/wirken") or l:find("^/benutzen") then
                                      local payload = cleanLine:match("^/%w+%s+(.+)")
                                      if payload then 
                                          tooltips = payload
                                          local itemIdMatch = payload:match("item:(%d+)")
                                          if itemIdMatch then bindId = tonumber(itemIdMatch) end
                                          break 
                                      end
                                   end
                                   if line:lower():find("^/use%s+13") then tooltips = "13"; break
                                   elseif line:lower():find("^/use%s+14") then tooltips = "14"; break end
                               end
                           end
                      end
                      
                      if tooltips then
                           local cleanName = tooltips:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
                           cleanName = cleanName:match("([^;]+)")
                           if cleanName then
                               cleanName = cleanName:gsub("^!", ""):match("^%s*(.-)%s*$")
                               local slotId = tonumber(cleanName)
                               if slotId then
                                   if slotId == 13 or slotId == 14 then
                                       local itemId = GetInventoryItemID("player", slotId)
                                       if itemId then
                                           bindId = itemId
                                           local itemName = GetItemInfo(itemId)
                                           if itemName then
                                               name = itemName
                                               if key then spellKeybinds[name:lower()] = key end
                                           end
                                           local itemSpell = GetItemSpell(itemId)
                                           if itemSpell and key then
                                               spellKeybinds[itemSpell:lower()] = key 
                                               if not name then name = itemSpell end
                                           end
                                       end
                                   else
                                       bindId = slotId
                                       local sInfo = C_Spell.GetSpellInfo(slotId)
                                       if sInfo then 
                                           name = sInfo.name 
                                           if key then spellKeybinds[name:lower()] = key end
                                       end
                                   end
                               else
                                   name = cleanName
                                   bindId = "macro_"..name 
                                   if key then spellKeybinds[name:lower()] = key end
                               end
                           end
                      end
                 else
                      local fallbackInfo = C_Spell.GetSpellInfo(id)
                      if fallbackInfo then
                          bindId = id
                          name = fallbackInfo.name
                      end
                 end
            elseif actionType == "item" and id then
                 bindId = id
                 local itemName = GetItemInfo(id)
                 name = itemName
            end

            if bindId and key then
                spellKeybinds[bindId] = key
                if name then
                    spellKeybinds[name:lower()] = key
                end
                
                if type(bindId) == "number" then
                     spellKeybinds[bindId] = key
                end

                if actionType == "item" or (type(bindId) == "number" and not name) then
                    local checkId = (type(bindId) == "number") and bindId or id
                    if checkId then
                        local itemSpell = GetItemSpell(checkId)
                        if itemSpell then
                            spellKeybinds[itemSpell:lower()] = key
                        end
                        local itemName = GetItemInfo(checkId)
                        if itemName then
                            spellKeybinds[itemName:lower()] = key
                        end
                    end
                end
            end
        end
    end
end

-- Single Frame Update (Fast)
function Module:UpdateFrame(frame)
    if not frame then return end
    local settings = GetSettings()
    if not settings then return end
    if not settings.enabled then 
        if frame.gravityKeybind then frame.gravityKeybind:Hide() end
        return 
    end

    local parent = frame:GetParent()
    local pName = parent and parent:GetName()
    
    local barKey = pName and barToSettingsKey[pName]
    if not barKey or not (settings.bars and settings.bars[barKey]) then
        if frame.gravityKeybind then frame.gravityKeybind:Hide() end
        return
    end

    local name = frame:GetName()
    local spellId = frame.spellID or frame.spellId
    if not spellId and frame.GetSpellID then
        local success, id = pcall(frame.GetSpellID, frame)
        if success then spellId = id end
    end
    
    if not spellId and frame.icon then
        spellId = frame.icon.spellID or frame.icon.spellId
    end
    if not spellId and name then
        local idStr = name:match("BCDM_Custom_(%d+)")
        if idStr then spellId = tonumber(idStr) end
    end

    local bind = nil
    if spellId then
        -- Safe indexing with pcall to avoid "table index is secret"
        local success, b = pcall(function() return spellKeybinds[spellId] end)
        if success then bind = b end
        
        if not bind and type(spellId) == "number" then
            local successInfo, spellInfo = pcall(C_Spell.GetSpellInfo, spellId)
            if successInfo and spellInfo then 
                -- Wrap name access, it can be secret
                local successName, spellName = pcall(function() return spellInfo.name end)
                if successName and spellName then
                    local successLower, nameLower = pcall(function() return spellName:lower() end)
                    if successLower and nameLower then
                        local successBind, b2 = pcall(function() return spellKeybinds[nameLower] end)
                        if successBind then bind = b2 end
                    end
                end
            end
        end

        if not bind and type(spellId) == "number" then
            local successItem, itemName = pcall(GetItemInfo, spellId)
            if successItem and itemName then
                local successLower, nameLower = pcall(function() return itemName:lower() end)
                local usedName = false
                if successLower and nameLower then
                     local successBind, b3 = pcall(function() return spellKeybinds[nameLower] end)
                     if successBind then 
                         bind = b3 
                         usedName = true
                     end
                end
                
                if not usedName then
                    local successItemSpell, itemSpell = pcall(GetItemSpell, spellId)
                    if successItemSpell and itemSpell then
                        local successLower2, itemSpellLower = pcall(function() return itemSpell:lower() end)
                        if successLower2 and itemSpellLower then
                             local successBind4, b4 = pcall(function() return spellKeybinds[itemSpellLower] end)
                             if successBind4 then bind = b4 end
                        end
                    end
                end
            end
        end
    end

    local parentObj = frame
    if frame.icon and type(frame.icon) == "table" and frame.icon.IsObjectType and frame.icon:IsObjectType("Frame") then
        parentObj = frame.icon
    end

    if not frame.gravityKeybind then
        frame.gravityKeybind = parentObj:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
    else
        if frame.gravityKeybind:GetParent() ~= parentObj then
           frame.gravityKeybind:SetParent(parentObj)
        end
    end

    frame.gravityKeybind:SetDrawLayer("OVERLAY", 7)
    if bind then
       local barStyle = settings.barStyles and settings.barStyles[barKey]
       local fontSize = barStyle and barStyle.fontSize or settings.fontSize
       local color = barStyle and barStyle.color or settings.color

       frame.gravityKeybind:SetText(bind)
       frame.gravityKeybind:SetFont(GetFontPath(), fontSize, "OUTLINE")
       frame.gravityKeybind:ClearAllPoints()
       frame.gravityKeybind:SetPoint(settings.anchor, settings.offsetX, settings.offsetY)
       frame.gravityKeybind:SetTextColor(unpack(color))
       frame.gravityKeybind:Show()
    else
       frame.gravityKeybind:Hide()
    end
end

-- Find New Frames (Slow)
function Module:DiscoverFrames()
    for containerName, barKey in pairs(barToSettingsKey) do
        local container = _G[containerName]
        if container then
            for _, child in ipairs({container:GetChildren()}) do
                if child and not Module.knownFrames[child] then
                    Module.knownFrames[child] = true
                    self:UpdateFrame(child)
                end
            end
        end
    end
end

-- Update Cached Frames (Fast)
function Module:ApplyKeybinds()
    if not Module.knownFrames then Module.knownFrames = {} end
    for frame in pairs(Module.knownFrames) do
        if frame and frame.IsVisible and frame:IsVisible() then
            self:UpdateFrame(frame)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CDM CENTERING LOGIC
-- ═══════════════════════════════════════════════════════════════
local centeringGuard = false

function Module:UpdateFrameLayout(frameName, shouldCenter)
    local frame = _G[frameName]
    if not frame then return end
    
    -- Collect and group children by row (Y-coordinate)
    local children = { frame:GetChildren() }
    local rows = {}
    local tolerance = 5 -- Y-pixel tolerance to be in same row
    
    for _, child in ipairs(children) do
        if child:IsShown() and child:GetWidth() > 0 then
            local _, _, _, _, y = child:GetPoint()
            -- Try to find existing row
            local inserted = false
            if y then -- verify y is valid
                for _, row in ipairs(rows) do
                    if math.abs(row.y - y) <= tolerance then
                        table.insert(row.buttons, child)
                        -- Update average Y
                        row.y = (row.y + y) / 2
                        inserted = true
                        break
                    end
                end
                if not inserted then
                    table.insert(rows, { y = y, buttons = {child} })
                end
            end
        end
    end
    
    -- Need at least 2 rows to have something to align relative to the first
    if #rows < 2 then return end
    
    -- Sort rows by valid Y
    table.sort(rows, function(a, b) return a.y > b.y end) -- Top first
    
    -- Helper to get bounds
    local function GetRowBounds(row)
        local minL, maxR
        for _, btn in ipairs(row.buttons) do
            local l = btn:GetLeft()
            local r = btn:GetRight()
            if l and r then
                if not minL or l < minL then minL = l end
                if not maxR or r > maxR then maxR = r end
            end
        end
        return minL, maxR
    end
    
    local r1Min, r1Max = GetRowBounds(rows[1])
    if not r1Min or not r1Max then return end
    
    local r1Center = (r1Min + r1Max) / 2
    local r1Left = r1Min
    
    -- Align Row 2+ relative to Row 1
    for i = 2, #rows do
        local row = rows[i]
        local rMin, rMax = GetRowBounds(row)
        if rMin and rMax then
            local diff = 0
            
            if shouldCenter then
                -- Center Alignment
                local currentCenter = (rMin + rMax) / 2
                diff = r1Center - currentCenter
            else
                -- Left Alignment (Reset)
                -- We align the row's Left edge to Row 1's Left edge
                -- This assumes BCDM default is left-aligned grid
                diff = r1Left - rMin 
            end
            
            -- Apply if significant
            if math.abs(diff) > 0.5 then
                for _, btn in ipairs(row.buttons) do
                    local p, rel, rp, x, y = btn:GetPoint()
                    if p then
                         btn:SetPoint(p, rel, rp, x + diff, y)
                    end
                end
            end
        end
    end
end

function Module:UpdateCentering()
    if centeringGuard then return end
    centeringGuard = true
    
    local cdm = ns.db.profile.actionbars.cdmCentering
    if not cdm then 
        centeringGuard = false
        return 
    end
    
    -- Master Switch
    local masterEnabled = cdm.enabled
    
    -- Safe pcall to avoid breaking if logic fails
    pcall(function()
        -- Update both frames
        -- If master is OFF, we pass false to force Reset/LeftAlign
        -- If master is ON, we look at specific bar setting
        self:UpdateFrameLayout("EssentialCooldownViewer", masterEnabled and cdm.essential)
        self:UpdateFrameLayout("UtilityCooldownViewer", masterEnabled and cdm.utility)
    end)
    
    centeringGuard = false
end

local hookedFrames = {}
local function HookFrameForCentering(frameName)
    if hookedFrames[frameName] then return end
    local frame = _G[frameName]
    if frame then
        -- Hook layout updates
        -- Using OnSizeChanged is usually reliable for auto-growing container
        frame:HookScript("OnSizeChanged", function() 
             if ns.db and ns.db.profile.actionbars.cdmCentering.enabled then
                 -- Defer slightly to ensure layout is done
                 C_Timer.After(0.05, function() Module:UpdateCentering() end)
             end
        end)
        hookedFrames[frameName] = true
    end
end


function Module:Refresh()
    ScanActionBars()
    self:DiscoverFrames()
    self:ApplyKeybinds()
    self:UpdateCentering() -- Add centering update to refresh
end

function Module:Init()
    local db = GetSettings()
    
    -- Register Options
    if ns.RegisterModuleOptions then
        ns.RegisterModuleOptions("GUICDM_Keybinds", {
            type = "group",
            name = "CDM Keybinds",
            args = {
                 -- (Options are handled by custom GUI page now)
            }
        })
    end

    -- Hook frames for centering
    C_Timer.After(1, function() -- Wait for BCDM to load
        HookFrameForCentering("EssentialCooldownViewer")
        HookFrameForCentering("UtilityCooldownViewer")
        Module:UpdateCentering() -- Initial pass
    end)

    -- Hook ActionBars (Existing logic)
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    f:RegisterEvent("UPDATE_BINDINGS")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            lastScan = 0
            ScanActionBars()
            Module:DiscoverFrames()
        elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" then
            ScanActionBars()
            Module:ApplyKeybinds()
        elseif event == "PLAYER_REGEN_ENABLED" then
            Module:ApplyKeybinds()
        end
    end)
    
    C_Timer.NewTicker(5.0, function()
        if not InCombatLockdown() then
             Module:DiscoverFrames()
        end
    end)
    
    HOOK_SET = true
    Module:Refresh()
end

-- Debug Command
SLASH_GRAVITYUIGUICDMDEBUG1 = "/gravityuiguicdmdebug"
SlashCmdList["GRAVITYUIGUICDMDEBUG"] = function()
    ns.db.profile.debugGUICDM = not ns.db.profile.debugGUICDM
    local state = ns.db.profile.debugGUICDM and "ENABLED" or "DISABLED"
    print("|cFF30D1FFGravityUI GUICDM Debug:|r " .. state)
    
    if ns.db.profile.debugGUICDM then
        local count = 0
        local ids = {}
        for k, v in pairs(spellKeybinds) do 
            count = count + 1 
            if type(k) == "number" then table.insert(ids, k) end
        end
        print("|cFF30D1FFGravityUI GUICDM:|r " .. count .. " keybinds cached. (" .. #ids .. " by ID)")
        
        print("Checking Containers:")
        for containerName, settingKey in pairs(barToSettingsKey) do
            local container = _G[containerName]
            if container then
                local children = {container:GetChildren()}
                print("  - " .. containerName .. ": FOUND (" .. #children .. " children)")
                for i, child in ipairs(children) do
                    if i <= 3 then
                        local cName = child:GetName() or "Unnamed"
                        local sid = child.spellID or child.spellId or (child.GetSpellID and child:GetSpellID())
                        if not sid and child.icon then sid = child.icon.spellID or child.icon.spellId end
                        local cid = child.cooldownID
                        print("    [Child " .. i .. "] Name: " .. cName .. " | SID: " .. (sid or "nil") .. " | CID: " .. (cid or "nil"))
                    end
                end
            else
                print("  - " .. containerName .. ": |cFFFF0000NOT FOUND|r")
            end
        end

        print("Dump of all ID matches:")
        table.sort(ids)
        for _, id in ipairs(ids) do
            print("  - ID |cFF00FF00" .. id .. "|r: " .. spellKeybinds[id])
        end
        ScanActionBars(true)
    else
        print("Scans will now occur silently.")
    end
end

-- Export
ns.RefreshGUICDMKeybinds = function() Module:Refresh() end
