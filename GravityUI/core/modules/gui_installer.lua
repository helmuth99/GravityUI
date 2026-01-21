local ADDON_NAME, ns = ...
local gui = GravityUI
local GUI = gui.GUI

local function ImportEditModeLayout(str)
    local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(str)
    if DevTool then 
       DevTool:AddData(EditModeManagerFrame, "editmodeframe")
    end
    
    -- Show Edit Mode (required for import to work)
    EditModeManagerFrame:Show()
    
    -- Import the layout
    EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Character, ADDON_NAME)
    
    -- IMPORTANT: We cannot close Edit Mode programmatically without causing taint
    -- The taint propagates to party frames and causes errors with "secret values"
    -- The user must close it manually by pressing ESC or clicking the X button
end

function GUI:InstallAddonsProfiles()

    --Editmode
    ImportEditModeLayout(GravityUI.imports.EditMode.data)

    -- Show instructions to the user
    GravityUI:Print("|cff00BFFFEdit Mode layout imported!|r")
    GravityUI:Print("|cffFFFF00Please press ESC or click the X button to close Edit Mode.|r")
    GravityUI:Print("|cff888888(Closing automatically would cause UI errors)|r")
    
    --Details
    Details:ImportProfile(GravityUI.imports.Details.data, ADDON_NAME, true, false, true)

    --Plater
    Plater.ImportAndSwitchProfile(ADDON_NAME, GravityUI.imports.Plater.data, true, true, true, true)
end

function GUI:TwinkInstaller()

    --Editmode
    local layoutInfo = C_EditMode.GetLayouts()
    local index
    for i, layout in ipairs(layoutInfo.layouts) do
        
        if layout.layoutName == ADDON_NAME then
            index =  layout.systems["systemIndex"]
            break
        end
    end

    C_EditMode.SetActiveLayout(index)

    --Details
    Details:ApplyProfile(ADDON_NAME, false, false)

     --Plater
    Plater.db:SetProfile(ADDON_NAME)
end
