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
            local Addon = ns.Addon
            if Addon and Addon.ImportProfileFromString then
                local ok, err = pcall(Addon.ImportProfileFromString, Addon, data)
                if not ok then
                    ns.Print("|cffff0000[GravityUI]|r Profile import failed: " .. tostring(err))
                end
            end
        end,
         HasProfile = function(self, profileName)
             if ns.db then 
                 for _, v in ipairs(ns.db:GetProfiles()) do if v == profileName then return true end end
             end
             return false
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
                    if layout.layoutIdentifier then
                         C_EditMode.SetActiveLayout(layout.layoutIdentifier)
                    else 
                        C_EditMode.SetActiveLayout(i + 2)
                    end
                    return true
                end
            end
            return false
        end,
        Import = function(self, data, profileName)
            if InCombatLockdown() then return end
             local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(data)
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
        -- EllesmereUI Ã¢â‚¬â€œ uses its own Lite DB framework (NOT AceDB).
        -- Profile storage: EllesmereUIDB.activeProfile (string, account-wide)
        --                  EllesmereUIDB.profiles[name] (profile table)
        -- API: EllesmereUI.GetActiveProfileName() / SwitchProfile(name) / ImportProfile(str, name)
        name = "EllesmereUI",
        label = "EllesmereUI",
        category = "Important",
        Check = function()
            return C_AddOns.IsAddOnLoaded("EllesmereUI") and _G.EllesmereUI ~= nil
        end,
        GetProfile = function()
            local E = _G.EllesmereUI
            if E and E.GetActiveProfileName then
                return E.GetActiveProfileName()
            end
            return _G.EllesmereUIDB and _G.EllesmereUIDB.activeProfile or nil
        end,
        SetProfile = function(self, profileName)
            local E = _G.EllesmereUI
            if E and E.SwitchProfile then
                pcall(E.SwitchProfile, profileName)
                return true
            end
            if _G.EllesmereUIDB then
                _G.EllesmereUIDB.activeProfile = profileName
                return true
            end
        end,
        Import = function(self, data, profileName)
            if type(data) ~= "string" then return end
            local E = _G.EllesmereUI
            if E and E.ImportProfile then
                local ok, err = pcall(E.ImportProfile, data, profileName)
                if ok then
                    ns.Print("[GUI Debug] EllesmereUI ImportProfile success \226\134\146 '" .. profileName .. "'")
                else
                    ns.Print("[GUI Debug] EllesmereUI ImportProfile failed: " .. tostring(err))
                end
            end
        end,
        HasProfile = function(self, profileName)
            if _G.EllesmereUIDB and _G.EllesmereUIDB.profiles then
                return _G.EllesmereUIDB.profiles[profileName] ~= nil
            end
            local E = _G.EllesmereUI
            if E and E.GetProfileList then
                local _, profiles = E.GetProfileList()
                return profiles and profiles[profileName] ~= nil
            end
            return false
        end,
    },

    {
        name = "Plater",
        label = "Plater",
        category = "Optional",
        Check = function() return _G.Plater and _G.Plater.db end,
        GetProfile = function() return _G.Plater.db:GetCurrentProfile() end,
        SetProfile = function(self, profileName)
             if _G.Plater then _G.Plater.db:SetProfile(profileName) return true end
        end,
        Import = function(self, data, profileName)
             if _G.Plater then 
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
        category = "Optional",
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

    -- -----------------------------------------------------------------------
    -- Optional Addons
    -- -----------------------------------------------------------------------
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
             if _G.BAGANATOR_CONFIG and _G.BAGANATOR_CONFIG.Profiles then
                  if not _G.BAGANATOR_CONFIG.Profiles[profileName] then
                      _G.BAGANATOR_CONFIG.Profiles[profileName] = {}
                      if _G.BAGANATOR_CONFIG.Profiles["Default"] then
                          for k,v in pairs(_G.BAGANATOR_CONFIG.Profiles["Default"]) do
                              _G.BAGANATOR_CONFIG.Profiles[profileName][k] = v
                          end
                      end
                  end
                  _G.BAGANATOR_CURRENT_PROFILE = profileName
                  if Baganator and Baganator.API and Baganator.API.FireProfileChanged then 
                      pcall(Baganator.API.FireProfileChanged) 
                  end
                  return true
             end
        end,
        Import = function(self, data, profileName)
             if _G.BAGANATOR_CONFIG and _G.BAGANATOR_CONFIG.Profiles then
                  if not _G.BAGANATOR_CONFIG.Profiles[profileName] then _G.BAGANATOR_CONFIG.Profiles[profileName] = {} end
                  local target = _G.BAGANATOR_CONFIG.Profiles[profileName]
                  if type(data) == "table" then
                      for k,v in pairs(data) do target[k] = v end
                  end
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
             return SetAceProfileInGlobal("WarpDepleteDB", profileName)
        end,
        Import = function(self, data, profileName)
             if _G.WarpDepleteDB then
                 if not _G.WarpDepleteDB.profiles then _G.WarpDepleteDB.profiles = {} end
                 _G.WarpDepleteDB.profiles[profileName] = data
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

    {
        name = "DandersFrames",
        label = "Dander's Frames",
        category = "Optional",
        Check = function() return _G.DandersFrames_IsReady and _G.DandersFrames_IsReady() end,
        GetProfile = function() return _G.DandersFramesDB_v2 and _G.DandersFramesDB_v2.currentProfile end,
        SetProfile = function(self, profileName)
             if _G.DandersFrames and _G.DandersFrames.SetProfile then
                 local ok = pcall(_G.DandersFrames.SetProfile, _G.DandersFrames, profileName)
                 if _G.DandersFramesCharDB then
                     _G.DandersFramesCharDB.currentProfile = profileName
                 end
                 return ok
             end
             if _G.DandersFramesDB_v2 then
                 _G.DandersFramesDB_v2.currentProfile = profileName
                 if _G.DandersFramesCharDB then
                     _G.DandersFramesCharDB.currentProfile = profileName
                 end
                 return true
             end
        end,
        Import = function(self, data, profileName)
            local success = false
            
            local decodedData = nil
            if type(data) == "string" and string.find(data, "^!DFP1!") then
                local LibDeflate = LibStub:GetLibrary("LibDeflate", true)
                local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
                
                if LibDeflate then
                    local compressed = LibDeflate:DecodeForPrint(string.sub(data, 7))
                    if compressed then
                        local serialized = LibDeflate:DecompressDeflate(compressed)
                        if not serialized then serialized = LibDeflate:DecompressZlib(compressed) end
                        
                        if serialized then
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
                decodedData = data
            end
            
            local finalData = decodedData or data 

            if _G.DandersFrames and _G.DandersFrames.SetProfile then
                local ok, err = pcall(_G.DandersFrames.SetProfile, _G.DandersFrames, profileName)
                if ok and _G.DandersFrames.db and decodedData then
                    if decodedData.party  then _G.DandersFrames.db.party  = decodedData.party  end
                    if decodedData.raid   then _G.DandersFrames.db.raid   = decodedData.raid   end
                    if decodedData.classColors      then _G.DandersFrames.db.classColors      = decodedData.classColors      end
                    if decodedData.powerColors      then _G.DandersFrames.db.powerColors      = decodedData.powerColors      end
                    if decodedData.raidAutoProfiles then _G.DandersFrames.db.raidAutoProfiles = decodedData.raidAutoProfiles end
                    if decodedData.auraBlacklist    then _G.DandersFrames.db.auraBlacklist    = decodedData.auraBlacklist    end
                    if _G.DandersFrames.SaveCurrentProfile then
                        pcall(_G.DandersFrames.SaveCurrentProfile, _G.DandersFrames)
                    end
                    if _G.DandersFramesCharDB then
                        _G.DandersFramesCharDB.currentProfile = profileName
                    end
                    success = true
                    ns.Print("[Danders] SetProfile+inject complete \226\134\146 '" .. profileName .. "'")
                else
                    ns.Print("[GUI Debug] Danders SetProfile failed: " .. tostring(err))
                end
            end
            
            if not success and _G.DandersFrames and _G.DandersFrames.ApplyImportedProfile then
                local okB, errB = pcall(_G.DandersFrames.ApplyImportedProfile, _G.DandersFrames,
                    finalData, nil, nil, profileName, true, true)
                if okB then
                    success = true
                    if _G.DandersFramesDB_v2 then _G.DandersFramesDB_v2.currentProfile = profileName end
                    if _G.DandersFramesCharDB then _G.DandersFramesCharDB.currentProfile = profileName end
                    ns.Print("[Danders] ApplyImportedProfile complete \226\134\146 '" .. profileName .. "'")
                else
                    ns.Print("[GUI Debug] Danders ApplyImportedProfile failed: " .. tostring(errB))
                end
            end
            
            if not success and decodedData and _G.DandersFramesDB_v2 then
                 if not _G.DandersFramesDB_v2.profiles then
                     ns.Print("[GUI Debug] Danders: profiles table missing, creating it.")
                     _G.DandersFramesDB_v2.profiles = {}
                 end
                 if not _G.DandersFramesDB_v2.profiles[profileName] then
                      _G.DandersFramesDB_v2.profiles[profileName] = {}
                 end
                 local target = _G.DandersFramesDB_v2.profiles[profileName]
                 for k, v in pairs(decodedData) do
                     if k ~= "profileName" and k ~= "exportedBy" and k ~= "exportTime" then
                        target[k] = v
                     end
                 end
                 _G.DandersFramesDB_v2.currentProfile = profileName
                 if _G.DandersFrames then
                     if _G.DandersFrames.FullProfileRefresh then pcall(_G.DandersFrames.FullProfileRefresh, _G.DandersFrames) end
                     if _G.DandersFrames.Update then pcall(_G.DandersFrames.Update, _G.DandersFrames) end
                 end
                 if _G.DandersFrames_Update then pcall(_G.DandersFrames_Update) end
                 success = true
                 ns.Print("[GUI Debug] Danders: Nuclear injection complete \226\134\146 '" .. profileName .. "'")
            end

            if not success and _G.DandersFrames_Import then 
                local ok, err = pcall(_G.DandersFrames_Import, data, profileName)
                if ok then success = true end
                if not ok then pcall(_G.DandersFrames_Import, data) end
            end
        end
    },

    {
        name = "Details",
        label = "Details!",
        category = "Optional",
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
                local res = _G.Details:ImportProfile(data, profileName, true, true, true) 
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
    },  -- end Details entry
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
            -- Entries with hideWhenNotLoaded skip the report entirely (not shown in UI when missing)
            if addon.hideWhenNotLoaded then
                -- Do nothing: addon is optional and should not clutter the status display
            else
                table.insert(report, {
                    label = addon.label,
                    name = addon.name,
                    category = addon.category,
                    current = "Not Loaded",
                    match = false,
                    loaded = false
                })
            end
            -- Unloaded addons don't fail the check for "System Configured" 
            -- (because if you didn't install the addon, it's fine)
        end
    end
    
    -- Post-Processing: Mutual Exclusion (e.g. BCDM vs replacement CDM)
    -- If BCDM is not loaded but its replacement IS loaded:
    -- Ã¢â€ â€™ Remove BCDM from the report, promote the replacement to Important
    local replacements = {} -- { replacedName -> replacerIndex }
    for i, item in ipairs(report) do
        local regEntry = nil
        for _, addon in ipairs(self.registry) do
            if addon.name == item.name then regEntry = addon break end
        end
        if regEntry and regEntry.replaces then
            replacements[regEntry.replaces] = i
        end
    end

    if next(replacements) then
        local toRemove = {}
        for i, item in ipairs(report) do
            local replacerIdx = replacements[item.name]
            if replacerIdx then
                if not item.loaded then
                    -- Original not loaded Ã¢â€ â€™ remove it, promote replacement to Important
                    toRemove[i] = true
                    report[replacerIdx].category = nil -- Promote to Important
                    -- Recalculate allGood now that replacement is Important
                    if not report[replacerIdx].match then
                        allGood = false
                    end
                else
                    -- Both loaded Ã¢â€ â€™ keep both (replacement stays Optional)
                end
            end
        end
        -- Remove suppressed entries (iterate backwards to keep indices valid)
        for i = #report, 1, -1 do
            if toRemove[i] then table.remove(report, i) end
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
            -- Safe Check: Only switch if the target profile EXISTS
            local shouldSync = true
            
            if addon.HasProfile then
                 if not addon:HasProfile(targetProfile) then
                     shouldSync = false
                     -- Optional: Log that we skipped it?
                     -- ns.Print("Skipped " .. addon.label .. " (Profile missing)")
                 end
            end
            
            if shouldSync then
                pcall(addon.SetProfile, addon, targetProfile)
                -- Mark as installed/synced in DB
                if db then db.installer[string.lower(addon.name)] = true end
            end
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
            local key = addon.importKey or addon.name
            
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
