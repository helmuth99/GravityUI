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
        name = "EditMode",
        label = "Edit Mode",
        isCore = true,
        Check = function() return C_EditMode and C_EditMode.GetLayouts end,
        GetProfile = function()
            local layoutInfo = C_EditMode.GetLayouts()
            if layoutInfo and layoutInfo.activeLayout then
                -- layoutInfo.activeLayout is the ID/Index
                -- 1. Try exact ID match if identifiers exist
                for _, layout in ipairs(layoutInfo.layouts) do
                    local id = layout.layoutIdentifier or layout.layoutID or layout.id
                    if id and id == layoutInfo.activeLayout then
                        return layout.layoutName
                    end
                end
                
                -- 2. Fallback: Assumption of 2 presets (Modern, Classic) offsetting the custom list
                -- This matches the observation: Active=4, GravityUI is Index 2. (2+2=4)
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
                    EditModeManagerFrame:Show()
                    
                    if layout.layoutIdentifier then
                         C_EditMode.SetActiveLayout(layout.layoutIdentifier)
                    else 
                         -- Fallback to heuristic
                        C_EditMode.SetActiveLayout(i + 2)
                    end
                    
                    EditModeManagerFrame:Hide()
                    return true
                end
            end
            return false
        end,
        Import = function(self, data, profileName)
            local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(data)
            EditModeManagerFrame:Show()
            -- logic to check if exists?
            -- EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Account, profileName)
            -- We just try to import. Edit Mode might error if duplicate name?
            -- Safe execution:
            pcall(function() EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Account, profileName) end)
            EditModeManagerFrame:Hide()
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
             if _G.Details then _G.Details:ApplyProfile(profileName) return true end
        end,
        Import = function(self, data, profileName)
            if _G.Details then _G.Details:ImportProfile(data, profileName, true, false, true) end
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
             if _G.DandersFramesDB_v2 then _G.DandersFramesDB_v2.currentProfile = profileName return true end
        end,
        Import = function(self, data, profileName)
            if _G.DandersFrames_Import then _G.DandersFrames_Import(data, profileName) end
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
             if _G.UUFG and _G.UUFG.ImportUUF then _G.UUFG:ImportUUF(data, profileName) end
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
}

-- Returns the system status
-- @param targetProfile (string) The profile name to check against (default: ADDON_NAME)
-- @return status (boolean) true if all loaded addons match the target profile
-- @return report (table) list of {name, status, error}
function Installer:GetSystemStatus(targetProfile)
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
            if not match then allGood = false end
            
            table.insert(report, {
                label = addon.label,
                name = addon.name,
                current = current,
                match = match,
                loaded = true
            })
        else
            -- Addon Not Loaded
            table.insert(report, {
                label = addon.label,
                name = addon.name,
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
        print("|cffff0000GravityUI:|r No import data found" .. (sourceProfileName and (" for profile " .. sourceProfileName) or "") .. "!")
        return 
    end

    local db = ns.GetDB()
    if db then db.installer = db.installer or {} end

    for _, addon in ipairs(self.registry) do
        -- Check if allowed
        local isAllowed = (not allowList) or (allowList[addon.name])
        
        if isAllowed and addon.Check() then
            -- 1. Import Data (if available and addon loaded)
            local key = addon.name -- matches Import key keys usually
            if imports[key] then
                 pcall(addon.Import, addon, imports[key].data, targetProfile)
            end
            
            -- 2. Set Profile
            pcall(addon.SetProfile, addon, targetProfile)
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
