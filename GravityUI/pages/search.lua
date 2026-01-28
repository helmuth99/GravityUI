local ADDON_NAME, ns = ...
local GUI = ns.GUI
local C = GUI.Colors

local searchResults = {}

local function RefreshSearchResults(content)
    -- Robust clearing of old results
    GUI:ClearPageContent(content)
    
    local yOffset = -40 -- Start below the header
    local PAD = 15
    local width = content:GetWidth() - 30
    
    if #searchResults == 0 then
        -- This label will NOT have isStepHeader because we fixed framework.lua logic
        local empty = GUI:CreateLabel(content, "No results found. Try a different search term.", 13, C.textMuted)
        empty:SetPoint("TOPLEFT", PAD, yOffset)
        content:SetHeight(100)
        return
    end
    
    for i, item in ipairs(searchResults) do
        local result = CreateFrame("Button", nil, content, "BackdropTemplate")
        result:SetSize(width, 40)
        result:SetPoint("TOPLEFT", PAD, yOffset)
        
        GUI:CreateBackdrop(result, {0.15, 0.15, 0.15, 0.3}, C.border)
        
        -- Path (Breadcrumbs)
        local path = result:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        GUI:SetFont(path, 10, "", C.accent)
        local pathText = item.pageTitle or "General"
        if item.tabName then
            pathText = pathText .. " > " .. item.tabName
        end
        path:SetText(pathText)
        path:SetPoint("TOPLEFT", 10, -5)
        
        -- Setting Name
        local name = result:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        GUI:SetFont(name, 12, "OUTLINE", C.text)
        name:SetText(item.displayText)
        name:SetPoint("BOTTOMLEFT", 10, 5)
        
        result:SetScript("OnEnter", function(self)
            self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.1)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        
        result:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.3)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)
        
        result:SetScript("OnClick", function()
            GUI:NavigateToItem(item)
        end)
        
        yOffset = yOffset - 45
    end
    
    content:SetHeight(math.abs(yOffset) + 20)
end

local function BuildSearchResultsPage(parent)
    parent.isStepHeader = true
    
    -- Static Header - we manually set isStepHeader here to ensure it stays
    local header = GUI:CreateSectionHeader(parent, "Search Results")
    header:SetPoint("TOPLEFT", 15, -10)
    header.isStepHeader = true
    if header.text then header.text.isStepHeader = true end
end

function GUI:UpdateSearchResultsPage(query)
    query = query:lower():trim()
    
    -- Filter
    searchResults = {}
    if query ~= "" and #query >= 2 then
        table.wipe(searchResults)
        for _, item in ipairs(self.searchIndex) do
            if item.text:find(query, 1, true) then
                table.insert(searchResults, item)
                if #searchResults >= 50 then break end
            end
        end
    end
    
    -- Switch to search page or refresh it if already there
    if self.currentPageId == "search" then
        if self.pages.search.OnShow and self.pages.search.frame then
            self.pages.search.OnShow(self.pages.search.frame:GetScrollChild())
        end
    else
        self:ShowPage("search")
    end
end

GUI:RegisterPage("search", {
    title = "Search",
    OnBuild = BuildSearchResultsPage,
    OnShow = RefreshSearchResults,
    hideFromSidebar = true,
    hideFromSearch = true,
})
