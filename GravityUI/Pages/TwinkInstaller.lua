local addon, private = ...
local Version = C_AddOns.GetAddOnMetadata(addon, "Version")
local GravityUI = private.GravityUI
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

--settings

local titleText = "GRAVITY UI powered by |cff00ccffCronix UI|r"
local descriptionText =
"\nTwinkinstaller of the Gravity UI \n \nBelow are the addons that are ready to be installed on you Twink."
local itemHeight = 40
local manPage= nil

local function ExpressInstallation()
    for i, v in ipairs(private.Addons) do
        if (C_AddOns.IsAddOnLoaded(v.name) or v.overwrite) and  GravityUI.db.global.InstalledAddons[v.name] then
            if v.importTwink then
                v.importTwink()
            end
            GravityUI.db.char[private.g.cName .. "-" .. private.g.cRealm] = true
            ReloadUI()
        end
    end
end

local function StyleButton(buttonFrame)

    buttonFrame.bg = buttonFrame:CreateTexture(nil, "BACKGROUND")
    buttonFrame.bg:SetAllPoints()
    buttonFrame.bg:SetColorTexture(private.g.blue())

    if buttonFrame.Left then buttonFrame.Left:Hide() end
    if buttonFrame.Middle then buttonFrame.Middle:Hide() end
    if buttonFrame.Right then buttonFrame.Right:Hide() end
    local tex = buttonFrame:GetHighlightTexture()

    if tex then
        tex:Hide()
        tex:SetAlpha(0)
        tex:SetTexture(nil) -- This removes the image but keeps the texture object
    end
    local borderColor = {0,0,0,1} -- blue, fully opaque
    local borderThickness = 1

    -- Top border
    local borderTop = buttonFrame:CreateTexture(nil, "OVERLAY")
    borderTop:SetColorTexture(unpack(borderColor))
    borderTop:SetHeight(borderThickness)
    borderTop:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", buttonFrame, "TOPRIGHT", 0, 0)

    -- Bottom border
    local borderBottom = buttonFrame:CreateTexture(nil, "OVERLAY")
    borderBottom:SetColorTexture(unpack(borderColor))
    borderBottom:SetHeight(borderThickness)
    borderBottom:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", 0, 0)

    -- Left border
    local borderLeft = buttonFrame:CreateTexture(nil, "OVERLAY")
    borderLeft:SetColorTexture(unpack(borderColor))
    borderLeft:SetWidth(borderThickness)
    borderLeft:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOMLEFT", 0, 0)

    -- Right border
    local borderRight = buttonFrame:CreateTexture(nil, "OVERLAY")
    borderRight:SetColorTexture(unpack(borderColor))
    borderRight:SetWidth(borderThickness)
    borderRight:SetPoint("TOPRIGHT", buttonFrame, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOMRIGHT", 0, 0)
end

local function ManuelPage(frame, anchor)
    --Start of table head
    local group = AceGUI:Create("SimpleGroup")
    manPage = group
    frame:AddChild(group)
    group:SetFullWidth(true)
    group:SetHeight(itemHeight)
    group:SetAutoAdjustHeight(false)
    group:SetLayout("Table")
    group:SetUserData("table", {
        columns = { 0.68, 0.32 }, -- 70% and 30% width columns
        space = 0                 -- No spacing between columns
    })
    -- Left (stretch)
    local leftLabel = AceGUI:Create("GravityLabel")
    leftLabel:SetText("Addon")
    leftLabel:SetFont(private.g.font, 20, "OUTLINE")
    leftLabel:SetHeight(itemHeight)
    leftLabel:SetJustifyV("MIDDLE")

    group:AddChild(leftLabel)

    -- Right (fixed)
    local rightLabel = AceGUI:Create("GravityLabel")
    rightLabel:SetText("Import")
    -- 30% of line
    rightLabel:SetFont(private.g.font, 20, "OUTLINE")
    rightLabel:SetHeight(itemHeight)
    rightLabel:SetJustifyV("MIDDLE")
    group:AddChild(rightLabel)


    --start of scrollframe
    local ScrollBackdrop = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Addons\\CronixUIMedia\\Media\\border\\SeerahScalloped.tga]",
        tile = true,
        tileSize = 32,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    }
    local scrollFrameContainer = GravityUI:CreateInlineGroup()
    scrollFrameContainer.titletext:SetHeight(0)
    scrollFrameContainer.frame:SetBackdrop(ScrollBackdrop)
    scrollFrameContainer.frame:SetBackdropColor(0, 0, 0, 0.6)
    scrollFrameContainer.frame:SetBackdropBorderColor(0, 0, 0, 1)
    scrollFrameContainer:SetFullWidth(true)
    scrollFrameContainer:SetHeight(260)
    scrollFrameContainer:SetLayout("Fill")
    scrollFrameContainer.frame:SetPoint("TOPLEFT", group.frame, "BOTTOMLEFT", 0, 0)
    scrollFrameContainer.frame:SetPoint("BOTTOMRIGHT", frame.frame, "BOTTOMRIGHT", 0, 0)

    frame:AddChild(scrollFrameContainer)

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")
    scrollFrame.frame:SetPoint("TOP", scrollFrameContainer.frame, "TOP", 0, 0)
    scrollFrameContainer:AddChild(scrollFrame)

    --put it into  a scrollframe
    for i, v in ipairs(private.Addons) do
        local igroup = AceGUI:Create("GravitySimpleGroup")
        igroup.frame:SetBackdrop(ScrollBackdrop)
        igroup.frame:SetBackdropColor(0, 0, 0, 0)
        igroup.frame:SetBackdropBorderColor(0, 0, 0, 0.6)
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
        button.text:SetFont(private.g.font, 14, "OUTLINE")
        button.text:SetTextColor(1, 1, 1) -- White text

        button:SetUserData("cell", { colspan = 1 })

        -- Simple button styling
        local buttonFrame = button.frame
        StyleButton(buttonFrame)
        local bg = buttonFrame.bg

        if (C_AddOns.IsAddOnLoaded(v.name) or v.overwrite) and  GravityUI.db.global.InstalledAddons[v.name] and v.importTwink then
            button:SetText("Available")
            bg:SetColorTexture(private.g.blue())
            button:SetCallback("OnClick", function(widget, event)
               
                v:importTwink()
              
                button:SetText("Imported")
                bg:SetColorTexture(0.1, 0.5, 0.1, 0.8)
                GravityUI.db.global.reload = true
            end)
        else
            button:SetText("Unavailable")
            bg:SetColorTexture(0.5, 0.1, 0.1, 0.8)
            button:SetDisabled(true)
        end

        igroup:AddChild(button)
        scrollFrame:AddChild(igroup)
    end


    --Styling
    local scrollbar = scrollFrame.scrollbar

    --centering scrollbar
    scrollbar:SetPoint("TOPLEFT", scrollFrame.scrollframe, "TOPRIGHT", 3, -16)
	scrollbar:SetPoint("BOTTOMLEFT", scrollFrame.scrollframe, "BOTTOMRIGHT", 3, 16)

    -- Try to set the track/rail texture
    if not scrollbar.Track then
        local track = scrollbar:CreateTexture(nil, "BACKGROUND")
        track:SetAllPoints()
        track:SetTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\bar.tga")
        scrollbar.Track = track
        scrollbar.Track:SetTexCoord(0, 1, 0, 1) -- or (0.08, 0.92, 0.08, 0.92) if needed
    end
    scrollbar.ThumbTexture:SetTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\button.tga")
    
    if scrollbar.ThumbTexture then
        scrollbar.ThumbTexture:SetTexCoord(0, 1, 0, 1) -- or (0.08, 0.92, 0.08, 0.92) if needed
    end
   

    scrollbar.ScrollDownButton:SetNormalTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\down.tga")
    scrollbar.ScrollDownButton:SetPushedTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\down.tga")
    scrollbar.ScrollDownButton:SetHighlightTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\down.tga")
    scrollbar.ScrollDownButton:SetDisabledTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\down.tga")

    -- For Down Button
    local downNormal = scrollbar.ScrollDownButton:GetNormalTexture()
    if downNormal then downNormal:SetAllPoints(); downNormal:SetTexCoord(0, 1, 0, 1) end

    local downPushed = scrollbar.ScrollDownButton:GetPushedTexture()
    if downPushed then downPushed:SetAllPoints(); downPushed:SetTexCoord(0, 1, 0, 1) end

    local downHighlight = scrollbar.ScrollDownButton:GetHighlightTexture()
    if downHighlight then downHighlight:SetAllPoints(); downHighlight:SetTexCoord(0, 1, 0, 1) end

    local downDisabled = scrollbar.ScrollDownButton:GetDisabledTexture()
    if downDisabled then downDisabled:SetAllPoints(); downDisabled:SetTexCoord(0, 1, 0, 1) end

    scrollbar.ScrollUpButton:SetNormalTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\up.tga")
    scrollbar.ScrollUpButton:SetPushedTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\up.tga")
    scrollbar.ScrollUpButton:SetHighlightTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\up.tga")
    scrollbar.ScrollUpButton:SetDisabledTexture("Interface\\AddOns\\GravityUI\\Media\\Scrollbar\\up.tga")

    -- For Up Button
    local upNormal = scrollbar.ScrollUpButton:GetNormalTexture()
    if upNormal then upNormal:SetAllPoints(); upNormal:SetTexCoord(0, 1, 0, 1) end

    local upPushed = scrollbar.ScrollUpButton:GetPushedTexture()
    if upPushed then upPushed:SetAllPoints(); upPushed:SetTexCoord(0, 1, 0, 1) end

    local upHighlight = scrollbar.ScrollUpButton:GetHighlightTexture()
    if upHighlight then upHighlight:SetAllPoints(); upHighlight:SetTexCoord(0, 1, 0, 1) end

    local upDisabled = scrollbar.ScrollUpButton:GetDisabledTexture()
    if upDisabled then upDisabled:SetAllPoints(); upDisabled:SetTexCoord(0, 1, 0, 1) end
end


function private.pages:TwinkHome(frame)
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
        space = 0                 -- No spacing between columns
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

    --buttons

    local buttonWrapper = AceGUI:Create("SimpleGroup")
    buttonWrapper:SetFullWidth(true)
    buttonWrapper:SetHeight(itemHeight)
    buttonWrapper:SetLayout("Table")
    buttonWrapper:SetUserData("table", {
        columns = {0.5, 0.5}, 
        space = 0                 -- No spacing between columns
    })
    frame:AddChild(buttonWrapper)

    local leftButton = AceGUI:Create("Button")
    leftButton:SetFullWidth(true)
    leftButton:SetHeight(itemHeight)
    leftButton:SetText("Express Installation")
    leftButton.text:SetFont(private.g.font, 14, "OUTLINE")
    leftButton.text:SetTextColor(1, 1, 1) -- White text
    StyleButton(leftButton.frame)
    buttonWrapper:AddChild(leftButton)

    local rightButton = AceGUI:Create("Button")
    rightButton:SetFullWidth(true)
    rightButton:SetHeight(itemHeight)
    rightButton:SetText("Manuel Installation")
    rightButton.text:SetFont(private.g.font, 14, "OUTLINE")
    rightButton.text:SetTextColor(1, 1, 1) -- White text
    StyleButton(rightButton.frame)
    buttonWrapper:AddChild(rightButton)

   
    --setting Button CallBack
    leftButton:SetCallback("OnClick", function(widget, event)
        ExpressInstallation()
    end)

    rightButton:SetCallback("OnClick", function(widget, event)
        if not manPage then
            ManuelPage(frame, textWrapper)
        end
        
    end)






    
    
    
end
