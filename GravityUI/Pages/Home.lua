local addon, private = ...
local Version = C_AddOns.GetAddOnMetadata(addon, "Version")
local GravityUI = private.GravityUI
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

--settings

local titleText = "GravityUI"
local descriptionText =
"\nSupported Addon Profiles in Gravity UI \n \nBelow are the addon profiles supported by Gravity UI. Once you've installed the corresponding addon, you can proceed to import its profile."
local itemHeight = 40

function private.pages:Home(frame)
    if private.pages.home then
        frame:AddChild(private.pages.home)
        frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        return
    end
    local page = AceGUI:Create("SimpleGroup")
    page:SetFullWidth(true)
    page:SetHeight(20)
    page:SetLayout("List")

    local topWrapper = AceGUI:Create("SimpleGroup")
    topWrapper:SetFullWidth(true)
    topWrapper:SetLayout("Table")
    topWrapper:SetUserData("table", {
        columns = { 0.30, 0.70 }, -- 70% and 30% width columns
        space = 0               -- No spacing between columns
    })
    page:AddChild(topWrapper)

    local logo = AceGUI:Create("Label")
    logo:SetImage("Interface\\AddOns\\GravityUI\\Media\\GRAVITY_UI.tga")
    logo:SetImageSize(125, 125)
    logo:SetFullWidth(true)
    topWrapper:AddChild(logo)


    local textWrapper = AceGUI:Create("SimpleGroup")
    textWrapper:SetFullHeight(true)
    textWrapper:SetFullWidth(true)
    textWrapper:SetLayout("List")
    topWrapper:AddChild(textWrapper)

    local text1 = AceGUI:Create("Label")
    text1:SetText(descriptionText)
    text1:SetFont(private.g.font, 14, "OUTLINE")
    text1:SetFullWidth(true)
    textWrapper:AddChild(text1)
    text1:SetJustifyV("MIDDLE")

    frame.page = page
    frame:AddChild(page)

    local group = AceGUI:Create("SimpleGroup")
    frame:AddChild(group)
    group:SetFullWidth(true)
    group:SetHeight(itemHeight)
    group:SetAutoAdjustHeight(false)
    group:SetLayout("Table")
    group:SetUserData("table", {
        columns = { 0.7, 0.3 },     -- 70% and 30% width columns
        space = 0                   -- No spacing between columns
    })


    -- Left (stretch)
    local leftLabel = AceGUI:Create("GravityLabel")
    leftLabel:SetText("Addon")
    leftLabel:SetRelativeWidth(0.68) -- 70% of line
    leftLabel:SetFont(private.g.font, 18, "OUTLINE")
    leftLabel:SetHeight(itemHeight)

    useDevTool(leftLabel, "leftLabel")


    group:AddChild(leftLabel)

    -- Right (fixed)
    local rightLabel = AceGUI:Create("GravityLabel")
    rightLabel:SetText("Import")
    rightLabel:SetRelativeWidth(0.32) -- 30% of line
    rightLabel:SetFont(private.g.font, 18, "OUTLINE")
    rightLabel:SetHeight(itemHeight)
    useDevTool(rightLabel, "rightLabel")
    group:AddChild(rightLabel)


    local scrollFrameContainer = GravityUI:CreateInlineGroup()
    scrollFrameContainer:SetFullWidth(true)
    scrollFrameContainer:SetHeight(300)
    scrollFrameContainer:SetLayout("Fill")
    frame:AddChild(scrollFrameContainer)

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")

    scrollFrameContainer:AddChild(scrollFrame)

    --put it into  a scrollframe
    for i, v in pairs(private.Addons) do
        local igroup = AceGUI:Create("SimpleGroup")
        igroup:SetHeight(itemHeight)
        igroup:SetFullWidth(true)
        igroup:SetLayout("Table")
        igroup:SetUserData("table", {
            columns = { 0.7, 0.3 }, -- 70% and 30% width columns
            space = 0               -- No spacing between columns
        })
        -- Your label (left side)
        local ilabel = AceGUI:Create("Label")
        ilabel:SetText(v.name)
        ilabel:SetRelativeWidth(0.7)
        ilabel:SetHeight(itemHeight)
        ilabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        ilabel:SetUserData("cell", { colspan = 1 })
        igroup:AddChild(ilabel)

        -- Your button (right side)
        local button = AceGUI:Create("Button")
        button:SetRelativeWidth(0.3)
        button:SetHeight(itemHeight)
        button:SetText("Import")

        button:SetUserData("cell", { colspan = 1 })

        -- Simple button styling
        local buttonFrame = button.frame
        if buttonFrame.Left then buttonFrame.Left:Hide() end
        if buttonFrame.Middle then buttonFrame.Middle:Hide() end
        if buttonFrame.Right then buttonFrame.Right:Hide() end
        button.text:SetTextColor(1, 1, 1) -- White text
        local bg = buttonFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.5, 0.1, 0.8) -- solid dark gray

        if C_AddOns.IsAddOnLoaded(v.name) then
            button:SetText(v.importText)
            bg:SetColorTexture(0.1, 0.5, 0.1, 0.8)
            button:SetCallback("OnClick", function(widget, event)
                v:import()
                button:SetText("imported")
                GravityUI.db.global.InstalledAddons[v.name] = true
            end)
        else
            button:SetText("|cffff0000Addon not loaded|r")
            bg:SetColorTexture(0.5, 0.1, 0.1, 0.8)
            button:SetDisabled(true)
        end

        igroup:AddChild(button)
        scrollFrame:AddChild(igroup)
    end
end
