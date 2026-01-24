local ADDON_NAME, ns = ...
local gui = GravityUI
local GUI = gui.GUI
local guiCore = ns.Addon

local function GetDB()
    if guiCore and guiCore.db and guiCore.db.profile then
        return guiCore.db.profile
    end
    return nil
end

local function ImportEditModeLayout(str)
    local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(str)
    if DevTool then 
       DevTool:AddData(EditModeManagerFrame, "editmodeframe")
    end
    
    -- Zeige Edit-Mode (erforderlich damit Import funktioniert)
    EditModeManagerFrame:Show()
    
    -- Importiere das Layout
    EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Character, ADDON_NAME)
    
    -- WICHTIG: Wir können Edit-Mode nicht programmatisch schließen ohne Taint zu verursachen
    -- Das Taint propagiert zu Party-Frames und verursacht Fehler mit "secret values"
    -- Der Benutzer muss es manuell schließen durch Drücken von ESC oder Klicken auf das X
end

function GUI:InstallAddonsProfiles()
    local options = {
        title = "Install Addons Profiles",
        message = "Install addons profiles?",
        warningText = "This cannot be undone. \nIt will reload the UI after installation.",
        acceptText = "Install",
        cancelText = "Cancel",
        onAccept = function() 
            local db = GetDB()
            db.installer = db.installer or {}
            ImportEditModeLayout(GravityUI.imports.EditMode.data)
            db.installer.editmode = true

            -- Zeige Anweisungen für den Benutzer
            GravityUI:Print("|cff00BFFFEdit Mode layout imported!|r")
            GravityUI:Print("|cffFFFF00Please press ESC or click the X button to close Edit Mode.|r")
            GravityUI:Print("|cff888888(Closing automatically would cause UI errors)|r")
            
            --Details
            if Details and Details.ImportProfile then
                Details:ImportProfile(GravityUI.imports.Details.data, ADDON_NAME, true, false, true)
                db.installer.details = true
            end

            --Plater
            if Plater and Plater.ImportAndSwitchProfile then
                Plater.ImportAndSwitchProfile(ADDON_NAME, GravityUI.imports.Plater.data, true, true, true, true)
                db.installer.plater = true
            end
            GravityUI:SafeReload()
        end,
        onCancel = function() end,
        isDestructive = true,
    }


    GUI:ShowConfirmation(options)
    --Editmode
  
end
    

function GUI:TwinkInstaller()
    local options = {
        title = "Install Addons Profiles Twinks",
        message = "Install addons profiles for twinks??",
        warningText = "This cannot be undone. \nIt will reload the UI after installation.",
        acceptText = "Install",
        cancelText = "Cancel",
        onAccept = function() 
                    --Editmode
            local db = GetDB()
            local layoutInfo = C_EditMode.GetLayouts()
            local index
            for i, layout in ipairs(layoutInfo.layouts) do
                
                if layout.layoutName == ADDON_NAME then
                    index =  layout.systems["systemIndex"]
                    break
                end
            end

            if db.installer.editmode then
                C_EditMode.SetActiveLayout(index)
            end
            --Details
             if Details and Details.ApplyProfile and db.installer.details then
                Details:ApplyProfile(ADDON_NAME, false, false)
             end
            --Plater
            if Plater and Plater.db.SetProfile and db.installer.plater then
                Plater.db:SetProfile(ADDON_NAME)
            end
            GravityUI:SafeReload()
        end,
        onCancel = function() end,
        isDestructive = true,
    }

    GUI:ShowConfirmation(options)

end
