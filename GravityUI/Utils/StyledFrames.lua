local addon, private = ...
local Version = C_AddOns.GetAddOnMetadata(addon, "Version")
local GravityUI = private.GravityUI
local AceGUI = private.AceGUI



function GravityUI:CreateFrame()
    local frame = AceGUI:Create("GravityFrame")
    frame:SetLayout("List")
    return frame
end

function GravityUI:CreateDropdown()
    
end

function GravityUI:CreateButton()
    
end

function GravityUI:CreateLable()
    
end

function GravityUI:CreateScrollFrame()
    
end

function GravityUI:CreateInlineGroup()
    local frame = AceGUI:Create("GravityInlineGroup")
    return frame
end

function GravityUI:CreateInlineGroupTitel(tText, dText)
   --[[  local frame = GravityUI:CreateInlineGroup()
    frame:SetFullWidth(true)
    frame:SetLayout("List") ]]

    --[[frame.title = AceGUI:Create("Label")
    frame.title:SetFullWidth(true)
    frame.title:SetHeight(50)
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
    frame.title:SetJustifyH("CENTER")
    frame.title:SetJustifyH("CENTER")
    frame.title:SetText(tText)
    frame:AddChild(frame.title)]]--
--[[ 
    frame.description = AceGUI:Create("Label")
    frame.description:SetFullWidth(true)
    frame.description:SetJustifyH("LEFT")
    frame.description:SetFontObject("GameFontHighlight")
    frame.description:SetText(dText)
    frame:AddChild(frame.description) ]]

    return 
end