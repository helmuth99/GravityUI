function GUI:CreateSubTabs(parent, tabs)
    local container = CreateFrame("Frame", nil, parent)
    -- Initial height, updated by layout
    container:SetHeight(35)
    
    local tabButtons = {}
    local tabContents = {}
    
    -- Store for layout update
    container.tabButtons = tabButtons
    
    local BUTTON_HEIGHT = 28
    local SPACING_X = 5
    local SPACING_Y = 5
    
    for i, tabInfo in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
        btn:SetHeight(BUTTON_HEIGHT)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(text, 12, "OUTLINE", C.text)
        text:SetText(tabInfo.name)
        text:SetPoint("CENTER", 0, 0)
        btn.text = text
        
        local width = text:GetStringWidth() + 30
        btn:SetSize(width, BUTTON_HEIGHT)
        
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        
        local contentFrame = CreateFrame("Frame", nil, parent)
        -- Anchors handled via container resizing mainly, but we anchor content to container bottom
        contentFrame:SetPoint("BOTTOMRIGHT", 0, 0)
        contentFrame:Hide()
        tabContents[i] = contentFrame
        
        if tabInfo.builder then
            tabInfo.builder(contentFrame)
        end
        
        btn:SetScript("OnClick", function()
            for j, otherBtn in ipairs(tabButtons) do
                local isSelected = (i == j)
                if isSelected then
                    otherBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.3)
                    otherBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    tabContents[j]:Show()
                else
                    otherBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
                    otherBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                    tabContents[j]:Hide()
                end
            end
            if tabInfo.fn then
                tabInfo.fn()
            end
        end)
        
        tabButtons[i] = btn
    end
    
    -- Dynamic Layout Update
    local function UpdateLayout()
        local width = container:GetWidth()
        if not width or width < 10 then return end
        
        local x = 0
        local y = 0
        
        for _, btn in ipairs(container.tabButtons) do
            local btnWidth = btn:GetWidth()
            
            -- Wrap?
            if (x + btnWidth) > width and x > 0 then
                x = 0
                y = y - (BUTTON_HEIGHT + SPACING_Y)
            end
            
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", x, y)
            
            x = x + btnWidth + SPACING_X
        end
        
        local totalHeight = math.abs(y) + BUTTON_HEIGHT + 5
        container:SetHeight(totalHeight)
    end
    
    container:SetScript("OnSizeChanged", UpdateLayout)
    
    -- Anchor Contents Dynamic Update
    -- When container height changes, the TOPLEFT of content should update?
    -- Actually since content is anchored to "BOTTOMLEFT" of container, 
    -- and "BOTTOMLEFT" of container moves down as height increases (assuming TOP anchor fixed),
    -- then content moves down. 
    -- Wait. If container is anchored TOPLEFT to parent, increasing Height moves BOTTOM edge down.
    -- Content is anchored TOPLEFT to container BOTTOMLEFT. So content starts below container. Correct.
    
    for _, cf in pairs(tabContents) do
         cf:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -10)
    end
    
    -- Select first tab
    if tabButtons[1] then
        tabButtons[1]:GetScript("OnClick")(tabButtons[1])
    end
    
    -- Initial layout call (might be 0 width if not anchored yet, but OnSizeChanged handles it later)
    UpdateLayout()
    
    return container
end
