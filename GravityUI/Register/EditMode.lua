local addon, private = ...

-- the following convention is applied
--[[ save private.Addons[addonname] = {
name = addonName
import = importLink this needs to be a function
importText = importText Text that will be on the button
}
]]

local addonName = "Blizzard UI Edit Mode"
local importText = "Import"
local overwrite = true
local str = "1 43 0 0 1 7 7 UIParent 0.0 45.0 -1 ##$$%/&('%)#+#,$ 0 1 1 6 0 MainMenuBar 0.0 5.0 -1 ##$$%/&('%(#,$ 0 2 1 6 0 MultiBarBottomLeft 0.0 5.0 -1 ##$$%/&('%(#,$ 0 3 1 5 5 UIParent -5.0 -77.0 -1 #$$$%/&('%(#,$ 0 4 1 2 0 MultiBarRight -5.0 0.0 -1 #$$$%/&('%(#,$ 0 5 1 1 4 UIParent 0.0 0.0 -1 ##$$%/&('%(#,$ 0 6 0 0 0 UIParent 401.7 -861.0 -1 ##$$%/&('%(#,$ 0 7 0 0 0 UIParent 401.7 -1155.0 -1 ##$$%/&('%(#,$ 0 10 1 6 0 MainMenuBar 0.0 5.0 -1 ##$$&('% 0 11 0 7 7 UIParent -250.9 300.8 -1 ##$$&('%,# 0 12 1 6 0 MainMenuBar 0.0 5.0 -1 ##$$&('% 1 -1 1 4 4 UIParent 0.0 0.0 -1 ##$#%# 2 -1 0 2 2 UIParent -3.5 0.0 -1 ##$#%( 3 0 1 8 7 UIParent -300.0 250.0 -1 $#3# 3 1 1 6 7 UIParent 300.0 250.0 -1 %#3# 3 2 1 3 5 TargetFrame -10.0 0.0 -1 %#&#3# 3 3 1 0 2 CompactRaidFrameManager 0.0 -7.0 -1 '#(#)#-#.#/#1$3# 3 4 0 0 0 UIParent 2.0 -712.7 -1 ,#-;.//#0&1$2( 3 5 1 5 5 UIParent 0.0 0.0 -1 &#$3# 3 6 1 5 5 UIParent 0.0 0.0 -1 -#.#/#4& 3 7 1 4 4 UIParent 0.0 0.0 -1 3# 4 -1 0 7 7 UIParent 0.0 258.3 -1 # 5 -1 0 7 7 UIParent 352.0 94.8 -1 # 6 0 0 2 2 UIParent -251.7 -28.0 -1 ##$#%#&.())( 6 1 0 2 2 UIParent -268.9 -232.2 -1 ##$#%#',(+)) 7 -1 0 0 0 UIParent -0.0 0.0 -1 # 8 -1 0 6 6 UIParent 11.4 14.2 -1 #'$K%%&O 9 -1 1 6 0 MainMenuBar 0.0 5.0 -1 # 10 -1 0 4 4 UIParent 306.6 46.4 -1 # 11 -1 0 8 8 UIParent -260.9 8.0 -1 # 12 -1 0 5 5 UIParent -2.6 111.5 -1 #'$#%# 13 -1 1 8 8 MicroButtonAndBagsBar 0.0 0.0 -1 ##$#%)&- 14 -1 1 2 2 MicroButtonAndBagsBar 0.0 0.0 -1 ##$#%( 15 0 0 5 5 UIParent -939.8 -413.0 -1 # 15 1 0 7 7 UIParent 0.9 238.2 -1 # 16 -1 0 5 5 UIParent -324.9 293.3 -1 #( 17 -1 1 1 1 UIParent 0.0 -100.0 -1 ## 18 -1 0 8 8 UIParent -430.9 81.9 -1 #- 19 -1 1 7 7 UIParent 0.0 0.0 -1 ## 20 0 1 7 7 UIParent 0.0 310.0 -1 ##$/%$&('%(-($)#+$,$-$ 20 1 1 7 7 UIParent 0.0 240.0 -1 ##$%$&('%(-($)#+$,$-$ 20 2 1 7 7 UIParent 0.0 370.0 -1 ##$$%$&('((-($)#+$,$-$ 20 3 1 7 7 UIParent 420.0 430.0 -1 #$$$%#&('((-($)#*#+$,$-$"

local function import()
    local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(str)
    EditModeManagerFrame:Show()
    EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Character, private.g.name)
    EditModeManagerFrame:Hide()
end

table.insert(private.Addons, {
    name = addonName,
    import = import,
    importText = importText,
    overwrite = overwrite
})