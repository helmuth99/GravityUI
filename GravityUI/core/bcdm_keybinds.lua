local ADDON_NAME, ns = ...

-- ═══════════════════════════════════════════════════════════════
-- BCDM KEYBINDS MODULE
-- ═══════════════════════════════════════════════════════════════
ns.BCDM_Keybinds = {}
local Module = ns.BCDM_Keybinds

-- Cache
local spellKeybinds = {} -- [spellID] = "KeybindText"
Module.knownFrames = {} -- [frame] = true
local lastScan = 0
local SCAN_THROTTLE = 2.0 -- Don't scan action bars too often
local HOOK_SET = false

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════

local function GetSettings()
    return ns.db.profile.actionbars.bcdm
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

    -- 2. Try Dominos Specific (CLICK DominosActionButtonX:HOTKEY)
    if _G.Dominos then
        k1, k2 = GetBindingKey("CLICK DominosActionButton" .. slot .. ":HOTKEY")
        if k1 then return k1, k2 end
        -- Fallback to LeftButton click? (Rarely bound directly but possible)
        k1, k2 = GetBindingKey("CLICK DominosActionButton" .. slot .. ":LeftButton")
        if k1 then return k1, k2 end
    end
    
    return nil
end

-- Robust Action Bar Scan for Retail
local function ScanActionBars()
    local now = GetTime()
    if (now - lastScan) < SCAN_THROTTLE then return end
    lastScan = now
    
    wipe(spellKeybinds)

    local barConfigs = {
        { start = 1,  ending = 12, prefix = "ACTIONBUTTON" },        -- Bar 1
        { start = 13, ending = 24, prefix = "ACTIONBAR2BUTTON" }, -- Bar 2
        { start = 25, ending = 36, prefix = "MULTIACTIONBAR3BUTTON" }, -- Bar 3 (Side Right)
        { start = 37, ending = 48, prefix = "MULTIACTIONBAR4BUTTON" }, -- Bar 4 (Side Right 2)
        { start = 49, ending = 60, prefix = "MULTIACTIONBAR2BUTTON" }, -- Bar 5 (Bottom Right)
        { start = 61, ending = 72, prefix = "MULTIACTIONBAR1BUTTON" }, -- Bar 6 (Bottom Left)
        -- Dragonflight Bars (5, 6, 7, 8)
        { start = 73, ending = 84,  prefix = "MULTIACTIONBAR5BUTTON" },
        { start = 85, ending = 96,  prefix = "MULTIACTIONBAR6BUTTON" },
        { start = 97, ending = 108, prefix = "MULTIACTIONBAR7BUTTON" },
        { start = 109,ending = 120, prefix = "MULTIACTIONBAR8BUTTON" }, 
        -- Extra padding just in case
        { start = 121,ending = 132, prefix = "MULTIACTIONBAR9BUTTON" }, 
        { start = 133,ending = 144, prefix = "MULTIACTIONBAR10BUTTON" },
        { start = 145,ending = 156, prefix = "MULTIACTIONBAR5BUTTON" }, -- Reuse prefixes (Dominos paging behavior)
        { start = 157,ending = 168, prefix = "MULTIACTIONBAR6BUTTON" },
        { start = 169,ending = 180, prefix = "MULTIACTIONBAR7BUTTON" },
    }

    for _, config in ipairs(barConfigs) do
        for i = 0, (config.ending - config.start) do
            local slot = config.start + i
            local actionType, id = GetActionInfo(slot)
            
            if actionType and id and ns.db.profile.debugBCDM then
                 -- Verbose scan log
                 -- print("Slot " .. slot .. ": " .. actionType .. " ID:" .. id)
            end
            
            local name
            local bindId
            
            if actionType == "spell" and id then
                 bindId = id
                 local info = C_Spell.GetSpellInfo(id)
                 if info then name = info.name end
            elseif actionType == "macro" and id then
                 local mid = GetMacroSpell(id)
                 if mid then
                     bindId = mid
                     local info = C_Spell.GetSpellInfo(mid)
                     if info then name = info.name end
                     -- if ns.db.profile.debugBCDM then print("BCDM Macro " .. slot .. " -> GetMacroSpell ID: " .. mid .. " ("..(name or "?")..")") end
                 else
                     -- Fallback: Parse macro text for #showtooltip or /cast
                     local _, _, body = GetMacroInfo(id)
                     if body then
                         -- Case insensitive match for cast/use/castsequence/showtooltip
                         local tooltips = body:match("#showtooltip%s+([^\n]+)")
                         
                         if not tooltips then
                             -- Line-by-line scan for robust matching
                             for line in body:gmatch("[^\r\n]+") do
                                 local cleanLine = line:match("^%s*(.+)")
                                 if cleanLine then
                                     local l = cleanLine:lower()
                                     
                                     -- if ns.db.profile.debugBCDM then print("BCDM Macro " .. slot .. " Line: " .. cleanLine) end
                                     
                                     -- Match basic commands (English and German)
                                     -- /cast, /use, /castsequence, /wirken, /benutzen
                                     if l:find("^/cast") or l:find("^/use") or l:find("^/castsequence") or l:find("^/wirken") or l:find("^/benutzen") then
                                        local payload = cleanLine:match("^/%w+%s+(.+)")
                                        if payload then 
                                            tooltips = payload 
                                            break 
                                        end
                                     end
                                 end
                             end
                         end
                         
                         if tooltips then
                              -- Clean up conditionals [mod] ...
                              local cleanName = tooltips:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
                              -- Remove ; part if multiple
                              cleanName = cleanName:match("([^;]+)")
                              -- Clean up ! prefix
                              if cleanName then
                                  cleanName = cleanName:gsub("^!", ""):match("^%s*(.-)%s*$")
                              end
                              
                              -- if ns.db.profile.debugBCDM then print("BCDM MacroParsed " .. slot .. ": " .. (cleanName or "nil")) end
                              
                              if cleanName then
                                  local slotId = tonumber(cleanName)
                                  if slotId then
                                      if slotId == 13 or slotId == 14 then
                                          local itemId = GetInventoryItemID("player", slotId)
                                          if itemId then
                                              local itemSpell = GetItemSpell(itemId)
                                              if itemSpell then
                                                   spellKeybinds[itemSpell:lower()] = true 
                                                   name = itemSpell
                                                   bindId = "macro_slot_"..slotId
                                              end
                                          end
                                      else
                                          -- Assume SpellID
                                          bindId = slotId
                                          local sInfo = C_Spell.GetSpellInfo(slotId)
                                          if sInfo then name = sInfo.name end
                                      end
                                  else
                                      name = cleanName
                                      bindId = "macro_"..name 
                                  end
                              end
                         else
                         end
                     else
                          -- Fallback: If no body, maybe ID is actually a Spell ID? (Seen in debug: actionType=macro, id=SpellID)
                          local fallbackInfo = C_Spell.GetSpellInfo(id)
                          if fallbackInfo then
                              bindId = id
                              name = fallbackInfo.name
                              -- if ns.db.profile.debugBCDM then print("BCDM Macro Fallback: Treated ID " .. id .. " as Spell: " .. (name or "?")) end
                          end
                     end
                 end
            elseif actionType == "item" and id then
                 bindId = id
                 local itemName = GetItemInfo(id)
                 name = itemName
            end

            if bindId then
                local buttonIndex = i + 1
                -- Adjust for Bar 2 special offset if command shares name (rare but safe)
                -- Actually for standard UI, Bar 2 uses MultiBarBottomLeft? No.
                -- Use MultiBar7? No.
                -- Bar 2 is "ACTIONBUTTON" page 2. Bindings usually "ACTIONBUTTON1..12" depend on page.
                -- BUT if using Dominos, Dominos maps 13-24 to a specific binding header usually.
                -- Let's try standard retail global string for Bar 2: "ACTIONBAR2BUTTON"? No.
                -- In standard UI, Bar 2 is simply page 2 of main bar.
                -- BUT addons like Dominos expose it.
                -- Correct binding command for slots 13-24 is undefined in standard non-paged UI?
                -- Actually, Dominos typically reuses MULTIACTIONBAR ranges or defines overrides.
                -- Let's assume standard "ACTIONBUTTON" is only 1-12.
                
                if not name and actionType == "macro" then
                    -- If macro parsing failed completely but we have a slot, use slot name?
                end
                
                local buttonIndex = i + 1
                local key, key2 = GetKeysForSlot(slot, config.prefix, buttonIndex)
                
                if key then
                     -- Abbreviate
                    key = key:gsub("SHIFT", "S")
                    key = key:gsub("CTRL", "C")
                    key = key:gsub("ALT", "A")
                    key = key:gsub("MOUSEWHEELUP", "MwU")
                    key = key:gsub("MOUSEWHEELDOWN", "MwD")
                    key = key:gsub("BUTTON3", "M3")
                    key = key:gsub("BUTTON4", "M4")
                    key = key:gsub("BUTTON5", "M5")
                    key = key:gsub("SPACE", "Spc")
                    key = key:gsub("%-", "") -- Remove All Hyphens (e.g. S-R -> SR)
                    
                    -- Store by ID
                    spellKeybinds[bindId] = key
                    
                    -- Store by Name
                    if name then
                        spellKeybinds[name:lower()] = key
                    end
                    
                    -- Store by Item Spell Name (for Trinkets causing Spell effects)
                    if actionType == "item" then
                        local itemSpell = GetItemSpell(id)
                        if itemSpell then
                            spellKeybinds[itemSpell:lower()] = key
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
    if not settings.enabled then 
        if frame.gravityKeybind then frame.gravityKeybind:Hide() end
        return 
    end
    local parent = frame:GetParent()
    local pName = parent and parent:GetName()
    if not (pName and (pName == "EssentialCooldownViewer" or pName == "UtilityCooldownViewer")) then
        return
    end
    local name = frame:GetName()
    local spellId = frame.spellID or frame.spellId or (frame.GetSpellID and frame:GetSpellID())
    if not spellId and frame.icon then
        spellId = frame.icon.spellID or frame.icon.spellId
    end
    if not spellId and name then
        local idStr = name:match("BCDM_Custom_(%d+)")
        if idStr then spellId = tonumber(idStr) end
    end
    local bind = nil
    if spellId and type(spellId) == "number" then
        bind = spellKeybinds[spellId]
        if not bind then
            local spellInfo = C_Spell.GetSpellInfo(spellId)
            if spellInfo and spellInfo.name then
                bind = spellKeybinds[spellInfo.name:lower()]
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
       frame.gravityKeybind:SetText(bind)
       frame.gravityKeybind:SetFont(GetFontPath(), settings.fontSize, "OUTLINE")
       frame.gravityKeybind:ClearAllPoints()
       frame.gravityKeybind:SetPoint(settings.anchor, settings.offsetX, settings.offsetY)
       frame.gravityKeybind:SetTextColor(unpack(settings.color))
       frame.gravityKeybind:Show()
    else
       frame.gravityKeybind:Hide()
    end
end

-- Find New Frames (Slow)
function Module:DiscoverFrames()
    local frame = EnumerateFrames()
    while frame do
        if frame.IsVisible and frame:IsVisible() and not Module.knownFrames[frame] then
             local parent = frame:GetParent()
             local pName = parent and parent:GetName()
             if pName and (pName == "EssentialCooldownViewer" or pName == "UtilityCooldownViewer") then
                  Module.knownFrames[frame] = true
                  self:UpdateFrame(frame)
             end
        end
        frame = EnumerateFrames(frame)
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

function Module:Refresh()
    ScanActionBars() -- Force updated data
    self:DiscoverFrames()
    self:ApplyKeybinds()
end

function Module:Init()
    if HOOK_SET then return end
    
    -- Event Frame for reactive updates
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    f:RegisterEvent("UPDATE_BINDINGS")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            lastScan = 0 -- Reset throttle for initial load
            ScanActionBars()
            Module:DiscoverFrames()
        elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" then
            ScanActionBars()
            Module:ApplyKeybinds()
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Catch any missed updates after combat
            Module:ApplyKeybinds()
        end
    end)
    
    -- Slow Ticker (5s) just to catch newly created/shown frames that might have missed events
    C_Timer.NewTicker(5.0, function()
        if not InCombatLockdown() then
             Module:DiscoverFrames()
        end
    end)
    
    HOOK_SET = true
    Module:Refresh()
end

-- Debug Command
SLASH_GRAVITYUIBCDMDEBUG1 = "/gravityuibcdmdebug"
SlashCmdList["GRAVITYUIBCDMDEBUG"] = function()
    -- Toggle debug mode
    ns.db.profile.debugBCDM = not ns.db.profile.debugBCDM
    
    local state = ns.db.profile.debugBCDM and "ENABLED" or "DISABLED"
    print("|cFF30D1FFGravityUI BCDM Debug:|r " .. state)
    
    if ns.db.profile.debugBCDM then
        print("Rescanning Action Bars (Verbose Mode)...")
        ScanActionBars()
    else
        print("Scans will now occur silently.")
    end
    




end

-- Export
ns.RefreshBCDMKeybinds = function() Module:Refresh() end
