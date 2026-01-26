-- GravityUI - Installer Module
local ADDON_NAME, ns = ...

local Addon = ns.Addon
local GUI = ns.GUI

local function ImportEditModeLayout(str)
    local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(str)
    
    -- Show Edit Mode (required for import to work)
    EditModeManagerFrame:Show()
    
    -- Import the layout
    EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Character, ADDON_NAME)
    
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
                ImportEditModeLayout(_G.GravityUI.imports.EditMode.data)
                db.installer.editmode = true
            end

            print("|cFF30D1FFGravityUI:|r Edit Mode layout imported!")
            print("|cFFFFFF00Please press ESC or click the X button to close Edit Mode.|r")
            
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
            
            Addon:SafeReload()
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
            
            local layoutInfo = C_EditMode.GetLayouts()
            local index
            for i, layout in ipairs(layoutInfo.layouts) do
                if layout.layoutName == ADDON_NAME then
                    index = layout.systems["systemIndex"]
                    break
                end
            end

            if db.installer and db.installer.editmode and index then
                C_EditMode.SetActiveLayout(index)
            end
            
            -- Details
            if Details and Details.ApplyProfile and db.installer and db.installer.details then
                Details:ApplyProfile(ADDON_NAME, false, false)
            end
            
            -- Plater
            if Plater and Plater.db and Plater.db.SetProfile and db.installer and db.installer.plater then
                Plater.db:SetProfile(ADDON_NAME)
            end
            
            Addon:SafeReload()
        end,
        onCancel = function() end,
        isDestructive = true,
    }

    GUI:ShowConfirmation(options)
end
