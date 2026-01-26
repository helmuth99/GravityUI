-- GravityUI - Installer Module
local ADDON_NAME, ns = ...

local Addon = ns.Addon
local GUI = ns.GUI

local function LayoutInstalled()
    local layoutInfo = C_EditMode.GetLayouts()
    local layoutIndex
    for i, layout in ipairs(layoutInfo.layouts) do
        if layout.layoutName == ADDON_NAME then
            return true
        end
    end
    return false
end


local function ImportEditModeLayout(str, twink)
    local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(str)
    
    -- Show Edit Mode (required for import to work)
    EditModeManagerFrame:Show()
    
    -- Import the layout as account-wide (global) so it works on all characters
    if not LayoutInstalled() or twink then
        EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Character, ADDON_NAME)
    end
    
    -- Note: We can't close edit mode automatically without causing taints
end

function GUI:InstallAddonsProfiles()
    local options = {
        title = "Install Addons Profiles",
        message = "Install addons profiles?",
        warningText = "This cannot be undone.\nIt will reload the UI after installation.",
        acceptText = "Install",
        cancelText = "Cancel",
        onAccept = function() 
            local db = ns.GetDB()
            if not db then return end
            
            db.installer = db.installer or {}
            
            if _G.GravityUI and _G.GravityUI.imports and _G.GravityUI.imports.EditMode then
                ImportEditModeLayout(_G.GravityUI.imports.EditMode.data, false)
                db.installer.editmode = true
            end

            print("|cFF30D1FFGravityUI:|r Edit Mode layout imported!")
            print("|cFFFFFF00Please press ESC or click the X button to close Edit Mode.|r")
            
            --UUF
            if UUFG and UUFG.ImportUUF and _G.GravityUI.imports.UUF then
                UUFG:ImportUUF(_G.GravityUI.imports.UUF.data, ADDON_NAME)
                db.installer.uuf = true
            end

            -- Details
            if Details and Details.ImportProfile and _G.GravityUI.imports.Details then
                Details:ImportProfile(_G.GravityUI.imports.Details.data, ADDON_NAME, true, false, true)
                db.installer.details = true
            end

             -- Plater
            if Plater and Plater.ImportAndSwitchProfile and _G.GravityUI.imports.Plater then
                Plater.ImportAndSwitchProfile(ADDON_NAME, _G.GravityUI.imports.Plater.data, true, true, true, true)
                db.installer.plater = true
            end

            --Platynator todo

            

            --dander Frames
            if DandersFrames_IsReady and DandersFrames_IsReady() and DandersFrames_Import and _G.GravityUI.imports.DandersFrames then
                -- Import frame settings
                local success, profileName = DandersFrames_Import(_G.GravityUI.imports.DandersFrames.data, ADDON_NAME)
                if success then
                    -- Set as active profile
                    if DandersFramesDB_v2 then
                        DandersFramesDB_v2.currentProfile = ADDON_NAME
                    end
                    db.installer.dandersframes = true
                end
            end

            --BCDM
            if BCDMG and BCDMG.ImportBCDM and _G.GravityUI.imports.BCDM then
                BCDMG:ImportBCDM(_G.GravityUI.imports.BCDM.data, ADDON_NAME)
                db.installer.bcdm = true
            end


            --bigwigs

            --temp solution todo
            if BigWigsAPI and BigWigsAPI.RegisterProfile and _G.GravityUI.imports.BigWigs  then
                BigWigsAPI.RegisterProfile(ADDON_NAME, _G.GravityUI.imports.BigWigs.data, ADDON_NAME, function() Addon:SafeReload() end )
                db.installer.bigwigs = true
            else
                Addon:SafeReload()
            end
        end,
        onCancel = function() end,
        isDestructive = true,
    }

    GUI:ShowConfirmation(options)
end

function GUI:TwinkInstaller()
    local options = {
        title = "Install Addons Profiles Twinks",
        message = "Install addons profiles for twinks?",
        warningText = "This cannot be undone.\nIt will reload the UI after installation.",
        acceptText = "Install",
        cancelText = "Cancel",
        onAccept = function() 
            local db = ns.GetDB()
            if not db then return end
            
            -- Find and activate the previously imported Edit Mode layout
            if _G.GravityUI and _G.GravityUI.imports and _G.GravityUI.imports.EditMode then
                ImportEditModeLayout(_G.GravityUI.imports.EditMode.data, true)
            end

            --UUF
            if UUF and UUF.db and db.installer and db.installer.uuf then
                UUF.db:SetProfile(ADDON_NAME)
            end

            -- Details
            if Details and Details.ApplyProfile and db.installer and db.installer.details then
                Details:ApplyProfile(ADDON_NAME, false, false)
            end

            -- Plater
            if Plater and Plater.db and Plater.db.SetProfile and db.installer and db.installer.plater then
                Plater.db:SetProfile(ADDON_NAME)
            end
            
            --BigWigs
            if BigWigs3DB and db.installer and db.installer.bigwigs then
                local name = UnitName("PLAYER")
                local realm = GetRealmName()
                BigWigs3DB["profileKeys"][name .. " - " .. realm] = ADDON_NAME
            end
            
            --dander Frames
            if DandersFrames_IsReady and DandersFrames_IsReady() and db.installer and db.installer.dandersframes then
                if DandersFramesDB_v2 then
                    DandersFramesDB_v2.currentProfile = ADDON_NAME
                end
            end

            --BCDM

            if BCDM and BCDM.db and db.installer and db.installer.bcdm then
                BCDM.db:SetProfile(ADDON_NAME)
                BCDM:UpdateBCDM()  -- Update the UI
            end


            Addon:SafeReload()
        end,
        onCancel = function() end,
        isDestructive = true,
    }

    GUI:ShowConfirmation(options)
end
