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
local rowsPool = {}
local buttonsPool = {}

-- PERF: Reuse tables for centering logic to avoid GC pressure
local function GetPoolTable(pool)
    return table.remove(pool) or {}
end

local function ReleaseToPool(t, pool)
    wipe(t)
    table.insert(pool, t)
end

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
    
end

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

-- Robust Action Bar Scan for Retail
local function ScanActionBars(force)
    local now = GetTime()
    if not force and (now - lastScan) < SCAN_THROTTLE then return end
    lastScan = now
    
    wipe(spellKeybinds)

    wipe(spellKeybinds)

    local keybindPriorities = {}

    -- Helper for safe table assignment
    local function SafeSet(key, value, priority)
        if not key or not value then return end
        priority = priority or 2 -- Macro or fallback default to lowest priority
        -- Logic: If we have multiple ways to find a bind, we want the most "direct" one (priority 1)
        -- over generic macro parse (priority 2).
        local currentPriority = keybindPriorities[key] or 99
        if priority <= currentPriority then
            spellKeybinds[key] = value
            keybindPriorities[key] = priority
        end
    end

    -- Helper for safe name lowercasing
    local function SafeLower(str)
        if not str then return nil end
        local success, res = pcall(string.lower, str)
        return success and res or nil
    end

    for _, config in ipairs(barConfigs) do
        for i = 0, (config.ending - config.start) do
            local slot = config.start + i
            local querySlot = slot
            
            -- Handle paging for Bar 1 (ACTIONBUTTON) via Button Attributes (Source of Truth)
            -- Handle paging for Bar 1 (ACTIONBUTTON)
            if _G.Dominos then
                -- Dominos: Trust the button's action attribute (Source of Truth) for ALL bars
                -- Dominos buttons are sequentially numbered 1 to 60 (or more) regardless of the underlying bar
                -- We try to map the slot to the corresponding Dominos button based on standard layout (Bar 1 = 1-12, Bar 2 = 13-24)
                local btnIdx = slot
                local button = _G["DominosActionButton" .. btnIdx]
                if button and button.GetAttribute then
                    local actionID = button:GetAttribute("action")
                    if actionID and type(actionID) == "number" and actionID > 0 then
                        querySlot = actionID
                    end
                end
            else
                -- Default UI: Calculate based on Page/Stance (API)
                -- ActionButton1:GetAttribute("action") is not reliable for paging in Default UI
                if config.prefix == "ACTIONBUTTON" then
                    local page = GetActionBarPage()
                    local offset = GetBonusBarOffset()
                    
                    if offset > 0 then
                        page = 6 + offset -- Classic/Retail Stance Paging Standard (e.g. Cat=Page 7)
                    end
                    
                    if page and page > 1 then
                        querySlot = slot + ((page - 1) * 12)
                    end
                end
            end

            local actionType, id = GetActionInfo(querySlot)
            
            local name, bindId
            local buttonIndex = i + 1
            local key, _ = GetKeysForSlot(slot, config.prefix, buttonIndex)
            
            if key then
                key = key:gsub("SHIFT", "S"):gsub("CTRL", "C"):gsub("ALT", "A")
                key = key:gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD")
                key = key:gsub("BUTTON3", "M3"):gsub("BUTTON4", "M4"):gsub("BUTTON5", "M5")
                key = key:gsub("SPACE", "Spc"):gsub("%-", "")
                key = key:gsub("NUMPADPLUS", "N+"):gsub("NUMPADMINUS", "N-"):gsub("NUMPADMULTIPLY", "N*"):gsub("NUMPADDIVIDE", "N/"):gsub("NUMPADDECIMAL", "N.")
                key = key:gsub("NUMPAD", "N")
            end

            if actionType == "spell" and id then
                 bindId = id
                 local success, info = pcall(C_Spell.GetSpellInfo, id)
                 if success and info then 
                     local nVal = info.name
                     if nVal then name = nVal end
                 end
            elseif actionType == "macro" and id then
                 local success, mname, _, body = pcall(GetMacroInfo, id)
                 local lookupId = id
                 
                 -- FALLBACK: If API macro index is corrupted, lookup by name
                 if not body or body == "" then
                     local mText = GetActionText(querySlot)
                     if mText then
                         local s2, n2, _, b2 = pcall(GetMacroInfo, mText)
                         if b2 and b2 ~= "" then
                             success, mname, body = true, n2, b2
                             lookupId = mname
                         end
                     end
                 end
                 
                 if success and mname and key then 
                    SafeSet(SafeLower(mname), key, 2)
                 end
                 
                 local mid = pcall(GetMacroSpell, lookupId) and GetMacroSpell(lookupId) or nil
                 local mitem, mlink
                 local successItem = pcall(function() mitem, mlink = GetMacroItem(lookupId) end)
                 if not successItem then mitem, mlink = nil, nil end
                 
                 -- Parse macro text even if GetMacroSpell/Item failed
                 if body and key then
                      -- 1. Parse Trinket Slots / Equipment
                      local found13, found14 = false, false
                      for line in body:gmatch("[^\r\n]+") do
                          local l = line:lower():match("^%s*(.+)")
                          if l then
                              if not found13 and (l:find("^/use%s+13") or l:find("^/benutzen%s+13")) then
                                  found13 = true
                                  SafeSet(13, key, 2)
                                  local tId = GetInventoryItemID("player", 13)
                                  if tId then SafeSet(tId, key, 2) end
                              end
                              if not found14 and (l:find("^/use%s+14") or l:find("^/benutzen%s+14")) then
                                  found14 = true
                                  SafeSet(14, key, 2)
                                  local tId = GetInventoryItemID("player", 14)
                                  if tId then SafeSet(tId, key, 2) end
                              end
                          end
                      end

                      -- 2. Parse #showtooltip or /cast for ACTUAL spell
                      local showtooltip = body:match("#showtooltip[ \t]+([^\r\n]+)")
                      if showtooltip then
                          local cName = showtooltip:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
                          cName = cName and cName:match("([^;]+)")
                          if cName then
                              cName = cName:gsub("^!", ""):match("^%s*(.-)%s*$")
                              if cName ~= "" and not tonumber(cName) then
                                  SafeSet(SafeLower(cName), key, 2)
                                  local sOk, sInfo = pcall(C_Spell.GetSpellInfo, cName)
                                  if sOk and sInfo and sInfo.spellID then SafeSet(sInfo.spellID, key, 2) end
                              end
                          end
                      end

                      for line in body:gmatch("[^\r\n]+") do
                          local l = line:lower():match("^%s*(.+)")
                          if l and (l:find("^/cast") or l:find("^/wirken") or l:find("^/use") or l:find("^/benutzen")) then
                              local spell = line:match("^/%w+%s+(.+)")
                              if spell then
                                  local cSpell = spell:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
                                  cSpell = cSpell and cSpell:match("([^;]+)")
                                  if cSpell then
                                      cSpell = cSpell:gsub("^!", ""):match("^%s*(.-)%s*$")
                                      if cSpell ~= "" and not tonumber(cSpell) then
                                          SafeSet(SafeLower(cSpell), key, 2)
                                          local sOk, sInfo = pcall(C_Spell.GetSpellInfo, cSpell)
                                          if sOk and sInfo and sInfo.spellID then SafeSet(sInfo.spellID, key, 2) end
                                      end
                                  end
                              end
                          end
                      end
                 end
                 
                 if mid then
                     bindId = mid
                     local sOk, info = pcall(C_Spell.GetSpellInfo, mid)
                     if sOk and info and info.name then name = info.name end
                 end
                 
                 -- Extra: also parse #showtooltip / /cast from body as additional lookup keys.
                 -- Runs even when mid is valid to cover cases where BCDM uses a different
                 -- spell ID variant than what GetMacroSpell returns.
                 if body and key then
                     local ttip = body:match("#showtooltip[ \t]+([^\r\n]+)")
                     if not ttip then
                         for line in body:gmatch("[^\r\n]+") do
                             local l = line:lower():match("^%s*(.+)")
                             if l and (l:find("^/cast") or l:find("^/wirken") or l:find("^/castsequence")) then
                                 ttip = line:match("^/%w+%s+(.+)")
                                 if ttip then break end
                             end
                         end
                     end
                     if ttip then
                         local cName = ttip:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
                         cName = cName and cName:match("([^;]+)")
                         if cName then
                             cName = cName:gsub("^!", ""):match("^%s*(.-)%s*$")
                             if cName ~= "" and not tonumber(cName) then
                                 SafeSet(SafeLower(cName), key, 2)
                                 local sOk2, sInfo2 = pcall(C_Spell.GetSpellInfo, cName)
                                 if sOk2 and sInfo2 then
                                     local idOk, spId = pcall(function() return sInfo2.spellID end)
                                     if idOk and spId and spId > 0 then SafeSet(spId, key, 2) end
                                     local lnOk, lName = pcall(function() return sInfo2.name end)
                                     if lnOk and lName then SafeSet(SafeLower(lName), key, 2) end
                                 end
                             end
                         end
                     end
                 end

                 if not mid then
                     if mlink then
                         local itemId = mlink:match("item:(%d+)")
                         if itemId then
                            bindId = tonumber(itemId)
                            local iOk, itemName = pcall(GetItemInfo, itemId)
                            if iOk and itemName then 
                                name = itemName 
                                if key then SafeSet(SafeLower(name), key) end
                            end
                            local sOk, itemSpell = pcall(GetItemSpell, itemId)
                            if sOk and itemSpell and key then SafeSet(SafeLower(itemSpell), key) end
                         end
                     elseif body then
                          -- Fallback: Parse macro text (mostly safe as it's string parsing, but careful with results)
                          local tooltips = body:match("#showtooltip[ \t]+([^\r\n]+)")
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
                                               local iOk, itemName = pcall(GetItemInfo, itemId)
                                               if iOk and itemName then
                                                   name = itemName
                                                   if key then 
                                                       SafeSet(SafeLower(name), key)
                                                       SafeSet(slotId, key)
                                                   end
                                               end
                                               local sOk, itemSpell = pcall(GetItemSpell, itemId)
                                               if sOk and itemSpell and key then
                                                   SafeSet(SafeLower(itemSpell), key)
                                                   if not name then name = itemSpell end
                                                   SafeSet(slotId, key)
                                               end
                                           else
                                                bindId = slotId
                                                if key then SafeSet(slotId, key) end
                                           end
                                       else
                                           bindId = slotId
                                           local sOk, sInfo = pcall(C_Spell.GetSpellInfo, slotId)
                                           if sOk and sInfo then 
                                               local nOk, nVal = pcall(function() return sInfo.name end)
                                               if nOk then 
                                                   name = nVal 
                                                   if key then SafeSet(SafeLower(name), key) end
                                               end
                                           end
                                       end
                                   else
                                       name = cleanName
                                       bindId = "macro_"..name 
                                       if key then SafeSet(SafeLower(name), key) end
                                   end
                               end
                          end
                     else
                          -- Try generic spell lookup for macro ID? Usually not needed if mid/mlink failed
                          local sOk, fallbackInfo = pcall(C_Spell.GetSpellInfo, id)
                          if sOk and fallbackInfo then
                              bindId = id
                              local nOk, nVal = pcall(function() return fallbackInfo.name end)
                              if nOk then name = nVal end
                          end
                     end
                 end
            end

            if bindId and key then
                local prio = (actionType == "macro") and 2 or 1
                SafeSet(bindId, key, prio)
                if name then
                    SafeSet(SafeLower(name), key, prio)
                end
                
                if type(bindId) == "number" then
                     SafeSet(bindId, key, prio)
                end

                if actionType == "item" or (type(bindId) == "number" and not name) then
                    local checkId = (type(bindId) == "number") and bindId or id
                    if checkId then
                        if checkId == GetInventoryItemID("player", 13) then
                            SafeSet(13, key, prio)
                        end
                        if checkId == GetInventoryItemID("player", 14) then
                            SafeSet(14, key, prio)
                        end
                        
                        local sOk, itemSpell = pcall(GetItemSpell, checkId)
                        if sOk and itemSpell then
                            SafeSet(SafeLower(itemSpell), key, prio)
                        end
                        local iOk, itemName = pcall(GetItemInfo, checkId)
                        if iOk and itemName then
                             SafeSet(SafeLower(itemName), key, prio)
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
    
    -- Main toggle must be ON for scanning/data to work
    if not settings.enabled then 
        if frame.gravityKeybind then frame.gravityKeybind:Hide() end
        frame.gravityKeybindData = nil
        return 
    end

    local parent = frame:GetParent()
    local pName = parent and parent:GetName()
    
    local barKey = pName and barToSettingsKey[pName]
    if not barKey or not (settings.bars and settings.bars[barKey]) then
        if frame.gravityKeybind then frame.gravityKeybind:Hide() end
        frame.gravityKeybindData = nil
        return
    end

    local name = frame:GetName()
    local spellId = frame.spellID or frame.spellId
    if not spellId and frame.GetSpellID then
        local success, id = pcall(frame.GetSpellID, frame)
        if success then spellId = id end
    end
    
    local itemId = frame.itemID or (frame.icon and frame.icon.itemID) or frame.cooldownID
    
    if not spellId and not itemId and frame.icon then
        spellId = frame.icon.spellID or frame.icon.spellId
    end
    if not spellId and not itemId and name then
        local idStr = name:match("BCDM_Custom_(%d+)")
        if idStr then spellId = tonumber(idStr) end
        
        -- Trinket slots are saved by their Equipment Slot ID (13/14)
        local trinketSlot = name:match("BCDM_Custom_Trinket_(%d+)")
        if trinketSlot then 
            local tSlotNum = tonumber(trinketSlot)
            if tSlotNum then
                spellId = tSlotNum -- Match the slot explicitly as fallback
                local tItemId = GetInventoryItemID("player", tSlotNum)
                if tItemId then
                    itemId = tItemId
                end
            end
        end
    end

    local bind = nil
    if spellId then
        -- PERF: Direct indexing is safe as spellId is number/string here.
        -- If it were a restricted table, pcall would be needed but BCDM IDs are sanitized.
        bind = spellKeybinds[spellId]
        
        if not bind and type(spellId) == "number" then
            local successInfo, spellInfo = pcall(C_Spell.GetSpellInfo, spellId)
            if successInfo and spellInfo then 
                local spellName = spellInfo.name
                if spellName then
                    local nameLower = spellName:lower()
                    bind = spellKeybinds[nameLower]
                end
            end
        end

        if not bind and type(spellId) == "number" then
            local successItem, itemName = pcall(GetItemInfo, spellId)
            if successItem and itemName then
                local nameLower = itemName:lower()
                bind = spellKeybinds[nameLower]
                
                if not bind then
                    local successItemSpell, itemSpell = pcall(GetItemSpell, spellId)
                    if successItemSpell and itemSpell then
                        local itemSpellLower = itemSpell:lower()
                        bind = spellKeybinds[itemSpellLower]
                    end
                end
            end
        end
    end
    
    if not bind and itemId then
        bind = spellKeybinds[itemId]
        
        if not bind then
            local successItem, itemName = pcall(GetItemInfo, itemId)
            if successItem and itemName then
                local nameLower = itemName:lower()
                bind = spellKeybinds[nameLower]
                
                if not bind then
                    local successItemSpell, itemSpell = pcall(GetItemSpell, itemId)
                    if successItemSpell and itemSpell then
                        local itemSpellLower = itemSpell:lower()
                        bind = spellKeybinds[itemSpellLower]
                    end
                end
            end
        end
    end

    -- Store data regardless of visibility setting
    frame.gravityKeybindData = bind

    local parentObj = frame
    if frame.icon and type(frame.icon) == "table" and frame.icon.IsObjectType and frame.icon:IsObjectType("Frame") then
        parentObj = frame.icon
    end

    if not frame.gravityKeybind then
        frame.gravityKeybind = parentObj:CreateFontString(nil, "OVERLAY")
    else
        if frame.gravityKeybind:GetParent() ~= parentObj then
           frame.gravityKeybind:SetParent(parentObj)
        end
    end

    frame.gravityKeybind:SetDrawLayer("OVERLAY", 7)
    
    local utils = settings.utils
    local hideText = utils and utils.hideKeybindText

    if bind and not hideText then
       local barStyle = settings.barStyles and settings.barStyles[barKey]
       local fontSize = barStyle and barStyle.fontSize or settings.fontSize
       local color = barStyle and barStyle.color or settings.color

        frame.gravityKeybind:SetFont(GetFontPath(), fontSize or 12, "OUTLINE")
        frame.gravityKeybind:SetText(bind)
        frame.gravityKeybind:ClearAllPoints()
        frame.gravityKeybind:SetPoint(settings.anchor or "TOPRIGHT", settings.offsetX or 0, settings.offsetY or 0)
        
        if color and type(color) == "table" and #color >= 3 then
            frame.gravityKeybind:SetTextColor(unpack(color))
        else
            frame.gravityKeybind:SetTextColor(1, 1, 1, 1)
        end
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
            for i = 1, select("#", container:GetChildren()) do
                local child = select(i, container:GetChildren())
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
    local rows = GetPoolTable(rowsPool)
    local tolerance = 5 -- Y-pixel tolerance to be in same row
    
    for i = 1, select("#", frame:GetChildren()) do
        local child = select(i, frame:GetChildren())
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
                    local newRow = GetPoolTable(rowsPool)
                    newRow.y = y
                    newRow.buttons = GetPoolTable(buttonsPool)
                    table.insert(newRow.buttons, child)
                    table.insert(rows, newRow)
                end
            end
        end
    end
    
    -- Need at least 2 rows to have something to align relative to the first
    if #rows < 2 then 
        -- PERF: Cleanup pooled tables
        for _, row in ipairs(rows) do
            ReleaseToPool(row.buttons, buttonsPool)
            row.buttons = nil
            ReleaseToPool(row, rowsPool)
        end
        ReleaseToPool(rows, rowsPool)
        return 
    end
    
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

    -- PERF: Cleanup pooled tables
    for _, row in ipairs(rows) do
        ReleaseToPool(row.buttons, buttonsPool)
        row.buttons = nil
        ReleaseToPool(row, rowsPool)
    end
    ReleaseToPool(rows, rowsPool)
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
    if self.UpdateUtils then self:UpdateUtils() end
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
    f:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    f:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    f:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
    f:RegisterEvent("UPDATE_MACROS")
    
    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1.5, function()
                lastScan = 0
                ScanActionBars(true)
                Module:DiscoverFrames()
                Module:ApplyKeybinds()
            end)
        elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_VEHICLE_ACTIONBAR" or event == "UPDATE_MACROS" then
            -- Fix: Delay scan to allow action bar addons to update buttons first 
            C_Timer.After(0.5, function()
                ScanActionBars(true)
                Module:ApplyKeybinds()
            end)
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Delay update to avoid combat-end frame spike
            C_Timer.After(0.5, function()
                Module:ApplyKeybinds()
            end)
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
                local numChildren = select("#", container:GetChildren())
                print("  - " .. containerName .. ": FOUND (" .. numChildren .. " children)")
                for i = 1, numChildren do
                    local child = select(i, container:GetChildren())
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
        
        print("--- Macro Bar Scan (1-180 Slots) ---")
        for slot = 1, 180 do
            local actionType, id = GetActionInfo(slot)
            if actionType == "macro" then
                local sOk, mname, _, body = pcall(GetMacroInfo, id)
                if sOk and body then
                    print("Slot " .. slot .. " | Macro: " .. (mname or "Unknown"))
                end
            end
        end
        
        if _G.Dominos then
            print("--- Dominos Button Dump (1-60) ---")
            for i = 1, 60 do
                local btn = _G["DominosActionButton" .. i]
                if btn then
                    local action = btn:GetAttribute("action")
                    local key, _ = GetKeysForSlot(i, "DOMINOS", i)
                    local isMacro = action and GetActionInfo(action) == "macro"
                    if isMacro or key then
                        local hasKey = key and "|cFF00FF00YES|r ("..key..")" or "|cFFFF0000NO|r"
                        print("Dominos Button " .. i .. " | ActionID: " .. (action or "nil") .. " | Key: " .. hasKey)
                    end
                end
            end
        end
        print("--- End Dump ---")
        
        ScanActionBars(true)
    else
        print("Scans will now occur silently.")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- UTILS: BUTTON GLOW
-- ═══════════════════════════════════════════════════════════════





local Listener = CreateFrame("Frame", "GravityUI_CDM_Input", UIParent)
Listener:Hide()
Listener:SetFrameStrata("TOOLTIP") -- Listen above most other frames
Module.glowingFrames = {} -- Active glows

function Module:ToggleGlow(frame, show, rawKey, reqMods)
    if not frame then return end
    
    -- Lazy Create
    if not frame.gravityGlow then
        frame.gravityGlow = frame:CreateTexture(nil, "OVERLAY")
        frame.gravityGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        frame.gravityGlow:SetBlendMode("ADD")
        frame.gravityGlow:SetAllPoints(frame)
    end
    
    if show then
        local db = ns.GetDB().actionbars.guicdm.utils
        if db and db.buttonGlowColor then
            frame.gravityGlow:SetVertexColor(unpack(db.buttonGlowColor))
        else
            frame.gravityGlow:SetVertexColor(1, 1, 0, 1)
        end
        frame.gravityGlow:Show()
        frame.glowRawKey = rawKey
        frame.glowReqMods = reqMods
        Module.glowingFrames[frame] = true
        Listener:SetScript("OnUpdate", OnUpdate) -- Start checking
    else
        frame.gravityGlow:Hide()
        frame.glowRawKey = nil
        frame.glowReqMods = nil
        Module.glowingFrames[frame] = nil
        
        if not next(Module.glowingFrames) then
            Listener:SetScript("OnUpdate", nil) -- Stop checking
        end
    end
end

function Module:ProcessPress(dispKey, rawKey)
    if not Module.knownFrames then return end

    local s = IsShiftKeyDown()
    local c = IsControlKeyDown()
    local a = IsAltKeyDown()
    
    local prefix = ""
    if s then prefix = prefix .. "S" end
    if c then prefix = prefix .. "C" end
    if a then prefix = prefix .. "A" end
    
    local fullKey = prefix .. dispKey

    for frame in pairs(Module.knownFrames) do
        if frame and frame:IsVisible() then
            -- Check stored data instead of visible fontstring
            local text = frame.gravityKeybindData
            if text then
                text = text:gsub("^%s+", ""):gsub("%s+$", "")
                if text == fullKey then
                    self:ToggleGlow(frame, true, rawKey, {s=s, c=c, a=a})
                end
            end
        end
    end
end

local throttle = 0
local function OnUpdate(self, elapsed)
    throttle = throttle + elapsed
    if throttle < 0.1 then return end
    throttle = 0
    
    if not next(Module.glowingFrames) then return end
    
    local s = IsShiftKeyDown()
    local c = IsControlKeyDown()
    local a = IsAltKeyDown()
    
    for frame in pairs(Module.glowingFrames) do
        local valid = true
        
        -- Check Key State via Game API (using RAW key)
        if not IsKeyDown(frame.glowRawKey) then
            valid = false
        else
            -- Check Mods
            local r = frame.glowReqMods
            if r and (s ~= r.s or c ~= r.c or a ~= r.a) then
                valid = false
            end
        end
        
        if not valid then
            Module:ToggleGlow(frame, false)
        end
    end
end


local function OnInput(key, down)
    local db = ns.GetDB().actionbars.guicdm.utils
    if not db or not db.buttonGlow then return end
    if not down then return end 
    
    -- originalKey for IsKeyDown check
    local originalKey = key:upper()
    
    -- dispKey for Text Match
    local dispKey = originalKey
    dispKey = dispKey:gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD")
    dispKey = dispKey:gsub("BUTTON3", "M3"):gsub("BUTTON4", "M4"):gsub("BUTTON5", "M5")
    dispKey = dispKey:gsub("SPACE", "Spc")
    
    local isMod = (originalKey == "LSHIFT" or originalKey == "RSHIFT" or originalKey == "LCTRL" or originalKey == "RCTRL" or originalKey == "LALT" or originalKey == "RALT")
    
    if not isMod then
        Module:ProcessPress(dispKey, originalKey)
    end
end

Listener:SetPropagateKeyboardInput(true)
Listener:SetScript("OnKeyDown", function(self, key) OnInput(key, true) end)
-- OnUpdate is dynamically toggled in ToggleGlow

function Module:UpdateUtils()
    local db = ns.GetDB().actionbars.guicdm.utils
    
    -- 1. Refresh frames to apply "Hide Keybind Text" setting immediately
    self:ApplyKeybinds()
    
    -- 2. Toggle Input Listener
    if db and db.buttonGlow then
        Listener:Show()
    else
        Listener:Hide()
        wipe(Module.glowingFrames)
        -- Cleanup glows
         for frame in pairs(Module.knownFrames) do
            Module:ToggleGlow(frame, false)
        end
    end
end

-- Export
ns.RefreshGUICDMKeybinds = function() 
    Module:Refresh() 
    Module:UpdateUtils()
end

