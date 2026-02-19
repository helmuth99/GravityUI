-- GravityUI - Installer Module
local ADDON_NAME, ns = ...

local Addon = ns.Addon
local GUI = ns.GUI
GUI.Installer = {}
local Installer = GUI.Installer

-- Helper to Set Profile directly in Global DB
local function SetAceProfileInGlobal(globalName, profileName)
    local db = _G[globalName]
    if db then
        if not db.profileKeys then db.profileKeys = {} end
        local key = UnitName("player") .. " - " .. GetRealmName()
        db.profileKeys[key] = profileName
        return true
    end
    return false
end

-- Registry of supported addons and their profile management logic
local function GetAceProfileFromGlobal(globalName)
    local db = _G[globalName]
    if db and db.profileKeys then
        local key = UnitName("player") .. " - " .. GetRealmName()
        return db.profileKeys[key]
    end
    return nil
end

Installer.registry = {
    {
        name = "GravityUI",
        label = "GravityUI",
        isCore = true,
        Check = function() return _G.GravityUI_DB end,
        GetProfile = function() return GetAceProfileFromGlobal("GravityUI_DB") end,
        SetProfile = function(self, profileName)
             if ns.db then ns.db:SetProfile(profileName) return true end
        end,
        Import = function(self, data, profileName)
            if ns.ImportProfile then ns:ImportProfile(data, profileName) end
        end,
         HasProfile = function(self, profileName)
             if ns.db then 
                 for _, v in ipairs(ns.db:GetProfiles()) do if v == profileName then return true end end
             end
             return false
        end
    },


    {
        name = "Details",
        label = "Details!",
        Check = function() return _G.Details and _G.Details.ApplyProfile end,
        GetProfile = function() 
            -- Details usually stores profile in _G.Details.profile (string) or _G.Details.db:GetCurrentProfile()
            if _G.Details then
                if _G.Details.GetProfileName then return _G.Details:GetProfileName() end
                if _G.Details.GetCurrentProfileName then return _G.Details:GetCurrentProfileName() end
                
                -- Fallback to standard AceDB if structured that way
                if _G.Details.db and _G.Details.db.GetCurrentProfile then return _G.Details.db:GetCurrentProfile() end
                
                if type(_G.Details.profile) == "string" then return _G.Details.profile end
            end
            return nil
        end, -- Details often stores current profile in root or db
        SetProfile = function(self, profileName)
             if _G.Details then 
                 -- Try ApplyProfile
                 local res = _G.Details:ApplyProfile(profileName) 
                 
                 -- If it failed (returned false), it likely means profile doesn't exist
                 if not res then
                     -- Use ImportProfile with set_as_current=true to force creation
                     -- We use an empty table as data, hoping it creates a default profile
                     local created = _G.Details:ImportProfile({}, profileName, true, false, true)
                     return created
                 end
                 return res
             end
        end,
        Import = function(self, data, profileName)
            if _G.Details then 
                local res = _G.Details:ImportProfile(data, profileName, true, false, true) 
            end
        end,
        HasProfile = function(self, profileName)
             if _G.Details and _G.Details.GetProfileList then
                 for _, v in ipairs(_G.Details:GetProfileList()) do
                     if v == profileName then return true end
                 end
             end
             return false
        end
    },
    {
        name = "Plater",
        label = "Plater",
        Check = function() return _G.Plater and _G.Plater.db end,
        GetProfile = function() return _G.Plater.db:GetCurrentProfile() end,
        SetProfile = function(self, profileName)
             if _G.Plater then _G.Plater.db:SetProfile(profileName) return true end
        end,
        Import = function(self, data, profileName)
             if _G.Plater then 
                -- ImportAndSwitchProfile(profileName, dataString, showConfirmation, isFnc, isNewProfile, force)
                _G.Plater.ImportAndSwitchProfile(profileName, data, false, true, true, true)
             end
        end,
        HasProfile = function(self, profileName)
            if _G.Plater and _G.Plater.db and _G.Plater.db.GetProfiles then 
                 for _, v in ipairs(_G.Plater.db:GetProfiles()) do
                     if v == profileName then return true end
                 end
            end
            return false
        end
    },
    {
        name = "BigWigs",
        label = "BigWigs",
        Check = function() return (_G.BigWigs3DB ~= nil) or C_AddOns.IsAddOnLoaded("BigWigs") end,
        GetProfile = function() 
            local db = _G.BigWigs3DB
            if not db then return nil end
            local hasProfile = db["profileKeys"] and db["profileKeys"][UnitName("PLAYER") .. " - " .. GetRealmName()]
            return hasProfile
        end,
        SetProfile = function(self, profileName)
             if _G.BigWigs3DB then 
                local key = UnitName("PLAYER") .. " - " .. GetRealmName()
                _G.BigWigs3DB["profileKeys"][key] = profileName 
                return true
             end
        end,
        Import = function(self, data, profileName)
             if _G.BigWigsAPI then 
                _G.BigWigsAPI.RegisterProfile(profileName, data, profileName, function() end)
             end
        end,
        HasProfile = function(self, profileName)
            if _G.BigWigs3DB and _G.BigWigs3DB.profiles then
                 return _G.BigWigs3DB.profiles[profileName] ~= nil
            end
            return false
        end
    },
    {
        name = "DandersFrames",
        label = "Dander's Frames",
        Check = function() return _G.DandersFrames_IsReady and _G.DandersFrames_IsReady() end,
        GetProfile = function() return _G.DandersFramesDB_v2 and _G.DandersFramesDB_v2.currentProfile end,
        SetProfile = function(self, profileName)

             if _G.DandersFramesDB_v2 then 
                 -- Ensure profile exists in storage (if it uses a profiles table)
                 -- Assuming DandersFramesDB_v2 might have a 'profiles' key?
                 -- Without source code, we assume 'currentProfile' switch is enough OR we need to init the table.
                 -- Safer: If DandersFramesDB_v2.profiles exists, use it.
                 if _G.DandersFramesDB_v2.profiles and type(_G.DandersFramesDB_v2.profiles) == "table" then
                      if not _G.DandersFramesDB_v2.profiles[profileName] then
                          -- Create copy of current or default?
                          _G.DandersFramesDB_v2.profiles[profileName] = {} 
                      end
                 end
                 
                 _G.DandersFramesDB_v2.currentProfile = profileName 
                 
                 -- FORCE UPDATE? Danders might need an update call
                 if _G.DandersFrames_Update then _G.DandersFrames_Update() end
                 
                 return true 
             end
        end,
        Import = function(self, data, profileName)
            local success = false
            
            -- Helper: Decode data if it's a string
            local decodedData = nil
            if type(data) == "string" and string.find(data, "^!DFP1!") then
                local LibDeflate = LibStub:GetLibrary("LibDeflate", true)
                local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
                
                if LibDeflate then
                    local compressed = LibDeflate:DecodeForPrint(string.sub(data, 7)) -- Remove !DFP1! prefix
                    if compressed then
                        local serialized = LibDeflate:DecompressDeflate(compressed)
                        -- Try Zlib if Deflate fails
                        if not serialized then serialized = LibDeflate:DecompressZlib(compressed) end
                        
                        if serialized then
                            -- Try AceSerializer
                             if LibAceSerializer then 
                                local ok, res = LibAceSerializer:Deserialize(serialized)
                                if ok then decodedData = res end
                            end

                            if not decodedData then
                                local LibSerialize = LibStub:GetLibrary("LibSerialize", true)
                                if LibSerialize then
                                    local ok, res = LibSerialize:Deserialize(serialized)
                                    if ok then decodedData = res end
                                end
                            end
                              -- DECODE STRATEGY 3: Json (Internal?)
                             -- Sometimes simple tables.
                        else
                             ns.Print("[GUI Debug] Danders: Decompress failed.")
                        end
                    else
                         ns.Print("[GUI Debug] Danders: DecodeForPrint failed.")
                    end
                else
                    ns.Print("[GUI Debug] Danders: LibDeflate missing.")
                end
            elseif type(data) == "table" then
                ns.Print("[GUI Debug] Danders: Data is already a table.")
                decodedData = data
            end
            
            -- Use decodedData if available, otherwise fallback to raw string (maybe Apply handles string??)
            local finalData = decodedData or data 

            -- TRY 1: Internal Method (ApplyImportedProfile)
            if _G.DandersFrames and _G.DandersFrames.ApplyImportedProfile then
                local options = nil
                -- Try to DETECT categories first
                if _G.DandersFrames.DetectImportedCategories then
                     local ok, res = pcall(_G.DandersFrames.DetectImportedCategories, _G.DandersFrames, finalData)
                     if ok then 
                         if type(res) == "table" then
                             -- Check if table is empty
                             local hasKeys = false
                             for k,v in pairs(res) do hasKeys = true break end
                             
                             if hasKeys then
                                 options = res
                             else
                                 options = nil -- Trigger fallback
                             end
                         end
                     end
                end
                
                -- Fallback Options if Detection Failed OR Returned Empty
                if not options then
                     options = {
                        -- Standard Case
                        ["Position"] = true, ["Frame Layout"] = true, ["Bars"] = true,
                        ["Auras"] = true, ["Text"] = true, ["Icons"] = true,
                        ["Other"] = true, ["Party"] = true, ["Raid"] = true,
                        ["Create New Profile"] = false, ["Name"] = profileName,
                        
                        -- Lowercase (Just in case)
                        ["position"] = true, ["frame layout"] = true, ["bars"] = true,
                        ["auras"] = true, ["text"] = true, ["icons"] = true,
                        ["other"] = true, ["party"] = true, ["raid"] = true,
                        ["create new profile"] = false, ["name"] = profileName,
                        
                        -- Variable Case (Common variations)
                        ["Positions"] = true, ["Layout"] = true, ["Bar"] = true,
                        ["Aura"] = true, ["Icon"] = true,
                        
                        -- Keys found in Actual Data (The "Golden" Keys)
                        ["frameTypes"] = true, ["profileName"] = true, 
                        ["exportedBy"] = true, ["version"] = true
                    }
                end
                
                -- Call Apply with Options
                local ok, err = pcall(_G.DandersFrames.ApplyImportedProfile, _G.DandersFrames, finalData, options)
                if ok then 
                    success = true
                else
                    ns.Print("[GUI Debug] Danders Apply failed: " .. tostring(err))
                end
            end
            
            -- STRATEGY 2: DIRECT DB INJECTION (The "Nuclear Option")
            -- If Apply failed OR if we want to be sure, we write directly to the DB.
            if decodedData and _G.DandersFramesDB_v2 and _G.DandersFramesDB_v2.profiles then
                 -- 1. Ensure profile table exists
                 if not _G.DandersFramesDB_v2.profiles[profileName] then
                      _G.DandersFramesDB_v2.profiles[profileName] = {}
                 end
                 
                 -- 2. Merge/Overwrite Data
                 local target = _G.DandersFramesDB_v2.profiles[profileName]
                 for k, v in pairs(decodedData) do
                     if k ~= "profileName" and k ~= "exportedBy" and k ~= "exportTime" then
                        target[k] = v
                     end
                 end
                 
                 -- 3. Force Update
                 if _G.DandersFrames_IsReady then _G.DandersFramesDB_v2.currentProfile = profileName end
                 
                 -- Bruteforce Refresh methods
                 if _G.DandersFrames.FullProfileRefresh then pcall(_G.DandersFrames.FullProfileRefresh, _G.DandersFrames) end
                 if _G.DandersFrames_Update then pcall(_G.DandersFrames_Update) end
                 if _G.DandersFrames.Update then pcall(_G.DandersFrames.Update, _G.DandersFrames) end
                 
                 success = true
            end

            -- TRY 2: Legacy Global (DandersFrames_Import)
            if not success and _G.DandersFrames_Import then 
                local ok, err = pcall(_G.DandersFrames_Import, data, profileName)
                if ok then success = true end
                
                -- Fallback: Just Data
                if not ok then
                    pcall(_G.DandersFrames_Import, data)
                end
            end
        end
    },
    {
        name = "BCDM",
        label = "Better Cooldown Manager",
        Check = function() return (_G.BCDM ~= nil) or C_AddOns.IsAddOnLoaded("BetterCooldownManager") end,
        GetProfile = function() 
             -- 1. Try Direct DB Global (Raw Data)
             local p1 = GetAceProfileFromGlobal("BCDMDB")
             if p1 then return p1 end
             local p2 = GetAceProfileFromGlobal("BetterCooldownManagerDB")
             if p2 then return p2 end

             -- 2. Try AceAddon Object (Method)
             local LibStub = _G.LibStub
             if LibStub then 
                  local AceAddon = LibStub("AceAddon-3.0", true)
                  if AceAddon then
                       local addon = AceAddon:GetAddon("BetterCooldownManager", true) or AceAddon:GetAddon("BCDM", true)
                       if addon and addon.db then return addon.db:GetCurrentProfile() end
                  end
             end
             return nil 
        end,
        SetProfile = function(self, profileName)
             -- Primary Method: Global Object
             if _G.BCDM and _G.BCDM.db then 
                _G.BCDM.db:SetProfile(profileName) 
                if _G.BCDM.UpdateBCDM then _G.BCDM:UpdateBCDM() end
                return true 
            end
            
            -- Fallback: AceAddon Registry
             local LibStub = _G.LibStub
             if LibStub then 
                  local AceAddon = LibStub("AceAddon-3.0", true)
                  if AceAddon then
                       local addon = AceAddon:GetAddon("BetterCooldownManager", true) or AceAddon:GetAddon("BCDM", true)
                       if addon and addon.db then 
                           addon.db:SetProfile(profileName)
                           if addon.UpdateBCDM then addon:UpdateBCDM() end
                           return true 
                       end
                  end
             end
             
             -- Ultimate Fallback: Direct DB Write
             if SetAceProfileInGlobal("BCDMDB", profileName) then return true end
             if SetAceProfileInGlobal("BetterCooldownManagerDB", profileName) then return true end
        end,
        Import = function(self, data, profileName)
            if _G.BCDMG and _G.BCDMG.ImportBCDM then _G.BCDMG:ImportBCDM(data, profileName) end
        end,
        HasProfile = function(self, profileName)
             if _G.BCDM and _G.BCDM.db then
                  for _, v in ipairs(_G.BCDM.db:GetProfiles()) do if v == profileName then return true end end
             end
             -- Add fallback check for HasProfile too ??
             return true -- Assume true to not block validation if global missing
        end
    },
    {
        name = "UUF",
        label = "UnhaltedUnitFrames",
        Check = function() return (_G.UUF ~= nil) or C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") end,
        GetProfile = function()
             -- 1. Try Direct DB Global (Raw Data)
             local p1 = GetAceProfileFromGlobal("UUFDB")
             if p1 then return p1 end
             local p2 = GetAceProfileFromGlobal("UnhaltedUnitFramesDB")
             if p2 then return p2 end
             
             -- 2. Try AceAddon Object (Method)
             local LibStub = _G.LibStub
             if LibStub then 
                  local AceAddon = LibStub("AceAddon-3.0", true)
                  if AceAddon then
                       local addon = AceAddon:GetAddon("UnhaltedUnitFrames", true)
                       if addon and addon.db then return addon.db:GetCurrentProfile() end
                  end
             end
             return nil
        end,
         SetProfile = function(self, profileName)
             if _G.UUF and _G.UUF.db then 
                  _G.UUF.db:SetProfile(profileName) 
                  return true 
             end
             -- Fallback set
             local LibStub = _G.LibStub
             if LibStub then 
                  local AceAddon = LibStub("AceAddon-3.0", true)
                  if AceAddon then
                       local addon = AceAddon:GetAddon("UnhaltedUnitFrames", true)
                       if addon and addon.db then addon.db:SetProfile(profileName) return true end
                  end
             end
             
             -- Ultimate Fallback: Direct DB Write
             if SetAceProfileInGlobal("UUFDB", profileName) then return true end
             if SetAceProfileInGlobal("UnhaltedUnitFramesDB", profileName) then return true end
        end,
        Import = function(self, data, profileName)
             ns.Print("[GUI Debug] UUF Import specific profile: " .. tostring(profileName))
             
             -- Ensure profile is set before import (just in case)
             if _G.UUF and _G.UUF.db then 
                 _G.UUF.db:SetProfile(profileName)
             elseif _G.UUF and _G.UUF.SetProfile then
                 _G.UUF:SetProfile(profileName)
             end

             -- TRY Global UUF object
             if _G.UUF and _G.UUF.ImportProfile then
                  ns.Print("[GUI Debug] UUF calling ImportProfile...")
                  local ok, err = pcall(_G.UUF.ImportProfile, _G.UUF, data)
                  if ok then
                      ns.Print("[GUI Debug] UUF Import Success. Calling Update...")
                      if _G.UUF.ThrottledUpdateAll then pcall(_G.UUF.ThrottledUpdateAll, _G.UUF) end
                      if _G.UUF.UpdateLayout then pcall(_G.UUF.UpdateLayout, _G.UUF) end
                  else
                      ns.Print("[GUI Debug] UUF Import Error: " .. tostring(err))
                  end
                  return
             end
             
             -- Fallback to UUFG global
             if _G.UUFG and _G.UUFG.ImportUUF then 
                 -- Attempt 1: (data, profileName) using DOT syntax
                 local ok, err = pcall(_G.UUFG.ImportUUF, data, profileName)
                 if ok then 
                     if _G.UUF and _G.UUF.ThrottledUpdateAll then pcall(_G.UUF.ThrottledUpdateAll, _G.UUF) end
                     return 
                 end
                 
                 -- Attempt 2: Swapped (profileName, data)
                 local ok2, err2 = pcall(_G.UUFG.ImportUUF, profileName, data)
                 if ok2 then return end

                 -- Attempt 3: Just Data
                 pcall(_G.UUFG.ImportUUF, data)
                 if _G.UUF and _G.UUF.ThrottledUpdateAll then pcall(_G.UUF.ThrottledUpdateAll, _G.UUF) end
             end
             
             -- STRATEGY: Direct DB Injection (Nuclear Option for UUF)
             -- Step 1: Decode if string
             if type(data) == "string" then
                 local LibDeflate = LibStub("LibDeflate", true)
                 if LibDeflate then
                      -- Fix Prefix: !UUF_
                      local clean = data
                      if string.find(data, "^!UUF_") then
                          clean = string.sub(data, 6) -- Strip !UUF_ (5 chars)
                      elseif string.find(data, "^!UUF!") then
                          clean = string.sub(data, 6) -- Strip !UUF! (5 chars)
                      end
                      
                      local decoded = LibDeflate:DecodeForPrint(clean)
                      if decoded then
                          local decompressed = LibDeflate:DecompressDeflate(decoded)
                          if decompressed then
                              local AceSerializer = LibStub("AceSerializer-3.0", true)
                              if AceSerializer then
                                   local ok, res = AceSerializer:Deserialize(decompressed)
                                   if ok then 
                                       
                                       data = res -- Promoted to table!
                                   end
                              end
                              
                              if type(data) == "string" then -- deserialization failed or not tried
                                  local LibSerialize = LibStub("LibSerialize", true)
                                  if LibSerialize then
                                      local ok, res = LibSerialize:Deserialize(decompressed)
                                      if ok then 
                                          data = res 
                                      end
                                  end
                               end
                           end
                       end
                  end
             end

             -- Step 2: Inject if table
             if data and type(data) == "table" then
                  -- Unwrap if coming from export that includes container
                  if data.profile then 
                      data = data.profile 
                  end
                  
                  if _G.UUFDB and _G.UUFDB.profiles then
                       if not _G.UUFDB.profiles[profileName] then _G.UUFDB.profiles[profileName] = {} end
                       local target = _G.UUFDB.profiles[profileName]
                       -- Merge
                       for k,v in pairs(data) do target[k] = v end

                       
                       -- Force Update
                       if _G.UUF then 
                           if _G.UUF.db then _G.UUF.db:SetProfile(profileName) end
                           if _G.UUF.UpdateLayout then pcall(_G.UUF.UpdateLayout, _G.UUF) end
                           if _G.UUF.ThrottledUpdateAll then pcall(_G.UUF.ThrottledUpdateAll, _G.UUF) end
                       end
                  end
             end
             

        end,
        HasProfile = function(self, profileName)
             if _G.UUF and _G.UUF.db then -- Global check
                  for _, v in ipairs(_G.UUF.db:GetProfiles()) do if v == profileName then return true end end
             else
                 -- Fallback check
                 local LibStub = _G.LibStub
                 if LibStub then
                      local AceAddon = LibStub("AceAddon-3.0", true)
                      if AceAddon then
                           local addon = AceAddon:GetAddon("UnhaltedUnitFrames", true)
                           if addon and addon.db then 
                               for _, v in ipairs(addon.db:GetProfiles()) do if v == profileName then return true end end
                           end
                      end
                 end
             end
             return false -- Only return false if we checked and didn't find it. 
             -- But if we couldn't check (addons not found), we should probably return false too? 
             -- Actually, installer IsConfigured logic: if HasProfile missing, assume true. if returns false, fail.
             -- If we can't find addon, we return false.
        end
    },
    {
        name = "EditMode",
        label = "Edit Mode",
        isCore = true,
        Check = function() return C_EditMode and C_EditMode.GetLayouts end,
        GetProfile = function()
            local layoutInfo = C_EditMode.GetLayouts()
            if layoutInfo and layoutInfo.activeLayout then
                for _, layout in ipairs(layoutInfo.layouts) do
                    local id = layout.layoutIdentifier or layout.layoutID or layout.id
                    if id and id == layoutInfo.activeLayout then
                        return layout.layoutName
                    end
                end
                local assumedIndex = layoutInfo.activeLayout - 2
                if assumedIndex > 0 and layoutInfo.layouts[assumedIndex] then
                    return layoutInfo.layouts[assumedIndex].layoutName
                end
                return "Unknown ID: " .. tostring(layoutInfo.activeLayout)
            end
            return nil
        end,
        SetProfile = function(self, profileName)
            local layoutInfo = C_EditMode.GetLayouts()
            
            for i, layout in ipairs(layoutInfo.layouts) do
                if layout.layoutName == profileName then
                    -- EditModeManagerFrame:Show() -- REMOVED to prevent Taint
                    
                    if layout.layoutIdentifier then
                         C_EditMode.SetActiveLayout(layout.layoutIdentifier)
                    else 
                         -- Fallback to heuristic
                        C_EditMode.SetActiveLayout(i + 2)
                    end
                    
                    -- EditModeManagerFrame:Hide() -- REMOVED to prevent Taint
                    return true
                end
            end
            return false
        end,
        Import = function(self, data, profileName)
            if InCombatLockdown() then return end
            -- Attempt Safe Import
             local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(data)
             -- EditModeManagerFrame:Show() -- REMOVED
             pcall(function() EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Account, profileName) end)
        end,
        HasProfile = function(self, profileName)
            local layoutInfo = C_EditMode.GetLayouts()
            if layoutInfo and layoutInfo.layouts then
                for _, layout in ipairs(layoutInfo.layouts) do
                    if layout.layoutName == profileName then return true end
                end
            end
            return false
        end
    },
    {
        name = "Baganator",
        label = "Baganator",
        category = "Optional",
        Check = function() return C_AddOns.IsAddOnLoaded("Baganator") end,
        GetProfile = function() 
             if _G.BAGANATOR_CONFIG and _G.BAGANATOR_CONFIG.Profiles and _G.BAGANATOR_CURRENT_PROFILE then
                 return _G.BAGANATOR_CURRENT_PROFILE
             end
             return nil
        end,
        SetProfile = function(self, profileName)
             -- Custom Injection: Baganator doesn't use AceDB
             if _G.BAGANATOR_CONFIG and _G.BAGANATOR_CONFIG.Profiles then
                  -- 1. Create if missing (copy current or empty?)
                  if not _G.BAGANATOR_CONFIG.Profiles[profileName] then
                      _G.BAGANATOR_CONFIG.Profiles[profileName] = {} -- Empty init, data import usually fills it
                      -- Or should we copy Default?
                      if _G.BAGANATOR_CONFIG.Profiles["Default"] then
                          -- Shallow copy
                          for k,v in pairs(_G.BAGANATOR_CONFIG.Profiles["Default"]) do
                              _G.BAGANATOR_CONFIG.Profiles[profileName][k] = v
                          end
                      end
                  end
                  
                  -- 2. Switch
                  _G.BAGANATOR_CURRENT_PROFILE = profileName
                  
                  -- 3. Force UI Refresh
                  if Baganator and Baganator.API and Baganator.API.FireProfileChanged then 
                      pcall(Baganator.API.FireProfileChanged) 
                  end
                  return true
             end
        end,
        Import = function(self, data, profileName)
             -- Baganator Data is usually a table of settings
             if _G.BAGANATOR_CONFIG and _G.BAGANATOR_CONFIG.Profiles then
                  if not _G.BAGANATOR_CONFIG.Profiles[profileName] then _G.BAGANATOR_CONFIG.Profiles[profileName] = {} end
                  local target = _G.BAGANATOR_CONFIG.Profiles[profileName]
                  
                  -- Merge Data
                  if type(data) == "table" then
                      for k,v in pairs(data) do target[k] = v end
                  end
                  
                  -- Switch to it?
                  _G.BAGANATOR_CURRENT_PROFILE = profileName
             end
        end,
        HasProfile = function(self, profileName)
             if _G.BAGANATOR_CONFIG and _G.BAGANATOR_CONFIG.Profiles then
                 return _G.BAGANATOR_CONFIG.Profiles[profileName] ~= nil
             end
             return false
        end
    },
    {
        name = "HidingBar",
        label = "HidingBar",
        category = "Optional",
        Check = function() return C_AddOns.IsAddOnLoaded("HidingBar") end,
        GetProfile = function()
             if _G.HidingBarDBChar and _G.HidingBarDBChar.currentProfileName then
                 return _G.HidingBarDBChar.currentProfileName
             end
             -- Fallback: Check global profiles keys
             if _G.HidingBarDB and _G.HidingBarDB.profiles then
                 -- If only one profile exists, assume it's current? No, risky.
                 -- Return "Default" if nothing found?
                 return "Unknown" 
             end
             return nil
        end,
        SetProfile = function(self, profileName)
             if _G.HidingBarDB and _G.HidingBarDB.profiles then
                 -- Setup DB if missing profile
                 if not _G.HidingBarDB.profiles[profileName] then
                      _G.HidingBarDB.profiles[profileName] = {}
                      -- Copy defaults?
                 end
                 
                 -- Set Char DB pointer
                 if _G.HidingBarDBChar then
                      _G.HidingBarDBChar.currentProfileName = profileName
                 end
                 
                 -- Update
                 if _G.HidingBar and _G.HidingBar.UpdateConfig then pcall(_G.HidingBar.UpdateConfig) end
                 return true
             end
        end,
        Import = function(self, data, profileName)
             if _G.HidingBarDB and _G.HidingBarDB.profiles then
                  if not _G.HidingBarDB.profiles[profileName] then _G.HidingBarDB.profiles[profileName] = {} end
                  local target = _G.HidingBarDB.profiles[profileName]
                  if type(data) == "table" then
                      for k,v in pairs(data) do target[k] = v end
                  end
                  
                  if _G.HidingBarDBChar then _G.HidingBarDBChar.currentProfileName = profileName end
             end
        end,
        HasProfile = function(self, profileName)
             if _G.HidingBarDB and _G.HidingBarDB.profiles then
                 return _G.HidingBarDB.profiles[profileName] ~= nil
             end
             return false
        end
    },
    {
        name = "NorthernSkyRaidTools",
        label = "NSRT", -- Shortened label to fit UI
        category = "Optional",
        Check = function() return C_AddOns.IsAddOnLoaded("NorthernSkyRaidTools") end,
        GetProfile = function()
             -- Check for our injected marker
             if _G.NSRT and _G.NSRT.GravityUIProfile == "GravityUI" then
                 return "GravityUI"
             end
             return "Manual"
        end,
        SetProfile = function(self, profileName)
             -- Inject marker
             if _G.NSRT then _G.NSRT.GravityUIProfile = profileName end
             return true
        end,
        Import = function(self, data, profileName)
             if _G.NSRT and type(data) == "table" then
                  for k,v in pairs(data) do
                      _G.NSRT[k] = v
                  end
                  _G.NSRT.GravityUIProfile = profileName
                  
                  if _G.ReloadUI then 
                       -- Should we reload? Installer usually asks at end.
                  end
             end
        end,
        HasProfile = function(self, profileName)
             return true 
        end
    },
    {
        name = "WarpDeplete",
        label = "WarpDeplete",
        category = "Optional",
        Check = function() return C_AddOns.IsAddOnLoaded("WarpDeplete") end,
        GetProfile = function()
             local db = _G.WarpDepleteDB
             if db and db.profileKeys then
                  return db.profileKeys[UnitName("player").." - "..GetRealmName()]
             end
             return nil
        end,
        SetProfile = function(self, profileName)
             -- WarpDeplete uses standard AceDB usually: WarpDepleteDB
             return SetAceProfileInGlobal("WarpDepleteDB", profileName)
             -- Need to tell WarpDeplete to refresh?
             -- It probably listens to OnProfileChanged if using AceDB
        end,
        Import = function(self, data, profileName)
             -- Direct DB Injection
             if _G.WarpDepleteDB then
                 if not _G.WarpDepleteDB.profiles then _G.WarpDepleteDB.profiles = {} end
                 
                 _G.WarpDepleteDB.profiles[profileName] = data
                 
                 -- Set Active
                 SetAceProfileInGlobal("WarpDepleteDB", profileName)
             end
        end,
        HasProfile = function(self, profileName)
             if _G.WarpDepleteDB and _G.WarpDepleteDB.profiles then
                  return _G.WarpDepleteDB.profiles[profileName] ~= nil
             end
             return false
        end
    },
}

-- Returns the system status
-- @param targetProfile (string) The profile name to check against (default: ADDON_NAME)
-- @return status (boolean) true if all loaded addons match the target profile
-- @return report (table) list of {name, status, error}
-- Returns the system status
-- @param targetProfile (string) The profile name to check against (default: ADDON_NAME)
-- @return status (boolean) true if all loaded addons match the target profile
-- @return report (table) list of {name, status, error}
-- Returns the system status
-- @param targetProfile (string) The profile name to check against (default: ADDON_NAME)
-- @return status (boolean) true if all loaded addons match the target profile
-- @return report (table) list of {name, status, error}
function Installer:GetSystemStatus(targetProfile)
    -- targetProfile = "testUI" -- TEST MODE FORCE
    targetProfile = targetProfile or ADDON_NAME
    local allGood = true
    local report = {}

    for _, addon in ipairs(self.registry) do
        local isLoaded = addon.Check and addon.Check()
        
        if isLoaded then
            -- Safe check profile
            local ok, current = pcall(addon.GetProfile, addon)
            if not ok then current = "Error" end
            

            
            local match = (current == targetProfile)
            
            -- Only Important addons determine the global system status
            if not match and addon.category ~= "Optional" then 
                allGood = false 
            end
            
            table.insert(report, {
                label = addon.label,
                name = addon.name,
                category = addon.category,
                current = current,
                match = match,
                loaded = true
            })
        else
            -- Addon Not Loaded
            table.insert(report, {
                label = addon.label,
                name = addon.name,
                category = addon.category,
                current = "Not Loaded",
                match = false,
                loaded = false
            })
            -- Unloaded addons don't fail the check for "System Configured" 
            -- (because if you didn't install the addon, it's fine)
        end
    end
    
    return allGood, report
end

-- Helper to get available source profiles string data
-- These are profiles we can IMPORT FROM (defined in strings/ folder)
function Installer:GetSourceProfiles()
    local sources = {}
    if _G.GravityUI and _G.GravityUI.profiles then
        for name, _ in pairs(_G.GravityUI.profiles) do
            table.insert(sources, name)
        end
    end
    table.sort(sources)
    return sources
end

-- Get all available profile names from the first addon that supports listing them (usually Plater or Details)
-- This allows us to populate the "Sync" dropdown
function Installer:GetAvailableProfiles()
    local profiles = {}
    local seen = {}
    
    -- Helper to collect
    local function collect(list)
        if not list then return end
        for _, v in ipairs(list) do
            if not seen[v] then
                table.insert(profiles, v)
                seen[v] = true
            end
        end
    end
    
    -- Try Plater
    if Plater and Plater.db and Plater.db.GetProfiles then 
        collect(Plater.db:GetProfiles()) 
    end
    
    -- Try Details
    if Details and Details.GetProfileList then
        collect(Details:GetProfileList())
    end
    
    -- Ensure Default exists
    if not seen["Default"] then table.insert(profiles, "Default") end
    
    table.sort(profiles)
    return profiles
end

-- Checks if all supported addons have the target profile available to switch to
function Installer:IsConfigured(targetProfile)
    -- targetProfile = "testUI" -- TEST MODE FORCE
    targetProfile = targetProfile or ADDON_NAME
    local allHave = true
    
    for _, addon in ipairs(self.registry) do
        if addon.Check() then
            local hasIt = false
            if addon.HasProfile then
                hasIt = addon:HasProfile(targetProfile)
            else
                -- If no HasProfile check, assume true to not block? 
                -- Or assume false? User wants "fully configured". 
                -- Let's assume true for now for addons we haven't implemented HasProfile for (Danders)
                hasIt = true 
            end
            
            if not hasIt then allHave = false end
        end
    end
    return allHave
end


-- Sync all addons to the target profile
function Installer:Synchronize(targetProfile, allowList)
    if not targetProfile then return end
    
    local db = ns.GetDB()
    if db then db.installer = db.installer or {} end

    for _, addon in ipairs(self.registry) do
        -- Check if allowed (if allowList is nil, everything is allowed)
        local isAllowed = (not allowList) or (allowList[addon.name])
        
        if isAllowed and addon.Check() then
            pcall(addon.SetProfile, addon, targetProfile)
            -- Mark as installed/synced in DB
            if db then db.installer[string.lower(addon.name)] = true end
        end
    end
    
    -- Save Metadata Globally for Account-Wide Tracking
    -- Save Metadata Globally for Account-Wide Tracking
    -- REMOVED per user request: Sync should not update timestamp, only Fresh Install does.
    -- local globalDB = ns.GetAceDB() and ns.GetAceDB().global hiding this logic
    
    -- Edit Mode Logic for Sync (Special handling if EditMode is allowed)
    -- (This logic is already in SetProfile for EditMode above, so loop handles it)

    -- Finish
    GUI:ShowConfirmation({
        title = "Sync Complete",
        message = "Profiles set to '"..targetProfile.."'.\nReload UI now?",
        acceptText = "Reload UI",
        onAccept = function() ReloadUI() end
    })
end

-- Full Install (Import + Sync)
function Installer:Install(targetProfile, sourceProfileName, allowList)
    -- targetProfile = "testUI" -- TEST MODE FORCE
    -- ns.Print("[TEST MODE] Installing to profile: " .. targetProfile)
    targetProfile = targetProfile or ADDON_NAME
    -- Determine Import Source
    local imports
    if sourceProfileName and _G.GravityUI and _G.GravityUI.profiles and _G.GravityUI.profiles[sourceProfileName] then
        imports = _G.GravityUI.profiles[sourceProfileName].imports
    else
        -- Fallback to legacy root imports
        imports = _G.GravityUI and _G.GravityUI.imports
    end
    
    if not imports then 
        ns.Print("No import data found" .. (sourceProfileName and (" for profile " .. sourceProfileName) or "") .. "!")
        return 
    end

    local db = ns.GetDB()
    if db then db.installer = db.installer or {} end

    for _, addon in ipairs(self.registry) do
        -- Check if allowed
        local isAllowed = (not allowList) or (allowList[addon.name])
        
        if isAllowed and addon.Check() then
            -- 1. Set Profile (Create/Switch FIRST)
            pcall(addon.SetProfile, addon, targetProfile)
            
            -- 2. Import Data (if available and addon loaded)
            local key = addon.name 
            
            if imports[key] then
                 local ok, err = pcall(addon.Import, addon, imports[key].data, targetProfile)
                 if not ok then
                     print("|cffff0000GravityUI:|r Error importing " .. key .. ": " .. tostring(err))
                 end
            end
            
            if db then db.installer[string.lower(addon.name)] = true end
        end
    end
    
    -- Save Metadata
    -- Save Metadata Globally for Account-Wide Tracking
    local globalDB = ns.GetAceDB() and ns.GetAceDB().global
    if globalDB then
        if not globalDB.installer then globalDB.installer = {} end
        globalDB.installer.setupBy = UnitName("player") .. " - " .. GetRealmName()
        globalDB.installer.setupDate = date("%d.%m.%Y %H:%M")
    end
    
    -- Finish
    GUI:ShowConfirmation({
        title = "Installation Complete",
        message = "All profiles imported and set to '"..targetProfile.."'.\nReload UI now?",
        acceptText = "Reload UI",
        onAccept = function() ReloadUI() end
    })
end
