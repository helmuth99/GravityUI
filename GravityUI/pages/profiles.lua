-- GravityUI - Profiles Page
local ADDON_NAME, ns = ...

local Addon = ns.Addon
local GUI = ns.GUI
local C = GUI.Colors

---------------------------------------------------------------------------
-- TAB: AceDB Profiles (Original Content)
---------------------------------------------------------------------------
local function BuildAceDBProfilesTab(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints() -- CRITICAL FIX: Anchor the scrollframe to the parent
    
    local y = -15
    local PAD = 10
    local FORM_ROW = 32

    local db = ns.GetAceDB()

    local info = GUI:CreateLabel(content, "Manage profiles and auto-switch based on specialization.", 11, C.textMuted)
    info:SetPoint("TOPLEFT", PAD, y)
    info:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    info:SetJustifyH("LEFT")
    y = y - 28
    
    -- =====================================================
    -- CURRENT PROFILE SECTION
    -- =====================================================
    local currentHeader = GUI:CreateSectionHeader(content, "Current Profile")
    currentHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - currentHeader.gap

    -- Forward declare profileDropdown so refresh function can reference it
    local profileDropdown

    -- Current profile display (form style row)
    local activeContainer = CreateFrame("Frame", nil, content)
    activeContainer:SetHeight(FORM_ROW)
    activeContainer:SetPoint("TOPLEFT", PAD, y)
    activeContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

    local currentProfileLabel = activeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentProfileLabel:SetPoint("LEFT", 0, 0)
    currentProfileLabel:SetText("Active Profile")
    GUI:SetFont(currentProfileLabel, 12)
    currentProfileLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    
    local currentProfileName = activeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentProfileName:SetPoint("LEFT", activeContainer, "LEFT", 200, 0)
    currentProfileName:SetText("Loading...")
    GUI:SetFont(currentProfileName, 12)
    currentProfileName:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    y = y - FORM_ROW
    
    -- Pre-calculate list for better performance (and shared reference)
    local cachedProfileList = {}

    local function UpdateProfileList()
        -- Clear existing
        for k in pairs(cachedProfileList) do cachedProfileList[k] = nil end
        
        if db then
            local profiles = db:GetProfiles()
            for i = 1, #profiles do
                local name = profiles[i]
                if name then
                    cachedProfileList[#cachedProfileList + 1] = {value = name, text = name}
                end
            end
        end
        -- Fallback if empty
        if #cachedProfileList == 0 then
            cachedProfileList[1] = {value = "Default", text = "Default"}
        end
    end

    -- Initial build
    UpdateProfileList()

    local function RefreshProfileDisplay()
        if db then
            local currentName = db:GetCurrentProfile()
            currentProfileName:SetText(currentName or "Unknown")
            if profileDropdown and profileDropdown.RefreshText then
                profileDropdown:RefreshText(currentName or "Default")
            end
            
            -- Rebuild the list in-place so all dropdowns receive the update
            UpdateProfileList()
        end
    end
    
    content:SetScript("OnShow", RefreshProfileDisplay)
    scroll:SetScript("OnShow", RefreshProfileDisplay)
    C_Timer.After(0.1, RefreshProfileDisplay)

    -- =====================================================
    -- RESET BUTTON
    -- =====================================================
    local resetContainer = CreateFrame("Frame", nil, content)
    resetContainer:SetHeight(FORM_ROW)
    resetContainer:SetPoint("TOPLEFT", PAD, y)
    resetContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

    local resetLabel = resetContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetLabel:SetPoint("LEFT", 0, 0)
    resetLabel:SetText("Reset Profile")
    GUI:SetFont(resetLabel, 12)
    resetLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local resetBtn = GUI:CreateButton(resetContainer, "Reset to Defaults", 150, 24, function()
        if db then
            GUI:ShowConfirmation({
                title = "Reset Profile?",
                message = "Reset current profile to defaults?",
                warningText = "This cannot be undone.",
                acceptText = "Reset",
                isDestructive = true,
                onAccept = function()
                    db:ResetProfile()
                    RefreshProfileDisplay()
                end,
            })
        end
    end)
    resetBtn:SetPoint("LEFT", resetContainer, "LEFT", 200, 0)
    
    y = y - FORM_ROW - 10

    -- =====================================================
    -- PROFILE SELECTION SECTION
    -- =====================================================
    local selectHeader = GUI:CreateSectionHeader(content, "Switch Profile")
    selectHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - selectHeader.gap
    
    local profileDropdownContainer = CreateFrame("Frame", nil, content)
    profileDropdownContainer:SetHeight(FORM_ROW)
    profileDropdownContainer:SetPoint("TOPLEFT", PAD, y)
    profileDropdownContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

    local profileDropdownLabel = profileDropdownContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileDropdownLabel:SetPoint("LEFT", 0, 0)
    profileDropdownLabel:SetText("Select Profile")
    GUI:SetFont(profileDropdownLabel, 12)
    profileDropdownLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local CHEVRON_ZONE_WIDTH = 28
    local CHEVRON_BG_ALPHA = 0.15

    profileDropdown = CreateFrame("Button", nil, profileDropdownContainer, "BackdropTemplate")
    profileDropdown:SetHeight(24)
    profileDropdown:SetPoint("LEFT", profileDropdownContainer, "LEFT", 200, 0)
    profileDropdown:SetPoint("RIGHT", profileDropdownContainer, "RIGHT", 0, 0)
    GUI:CreateBackdrop(profileDropdown, {0.08, 0.08, 0.08, 1}, {0.35, 0.35, 0.35, 1})

    local chevronZone = CreateFrame("Frame", nil, profileDropdown, "BackdropTemplate")
    chevronZone:SetWidth(CHEVRON_ZONE_WIDTH)
    chevronZone:SetPoint("TOPRIGHT", profileDropdown, "TOPRIGHT", -1, -1)
    chevronZone:SetPoint("BOTTOMRIGHT", profileDropdown, "BOTTOMRIGHT", -1, 1)
    chevronZone:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)

    local profileDropdownText = profileDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    GUI:SetFont(profileDropdownText, 11)
    profileDropdownText:SetPoint("LEFT", 8, 0)
    profileDropdownText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    profileDropdownText:SetText(db and db:GetCurrentProfile() or "Default")

    function profileDropdown:RefreshText(val)
        profileDropdownText:SetText(val)
    end

    local profileMenu = CreateFrame("Frame", nil, profileDropdown, "BackdropTemplate")
    profileMenu:SetPoint("TOPLEFT", profileDropdown, "BOTTOMLEFT", 0, -2)
    profileMenu:SetPoint("TOPRIGHT", profileDropdown, "BOTTOMRIGHT", 0, -2)
    GUI:CreateBackdrop(profileMenu, {0.1, 0.1, 0.1, 0.98}, {0.3, 0.3, 0.3, 1})
    profileMenu:SetFrameStrata("TOOLTIP")
    profileMenu:Hide()
    
    local function BuildProfileMenu()
        for _, child in ipairs({profileMenu:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        if not db then return end
        
        -- Use cached list for menu building
        local itemHeight = 22
        profileMenu:SetHeight(#cachedProfileList * itemHeight + 4)
        
        for i, itemData in ipairs(cachedProfileList) do
            local profileName = itemData.value
            local item = CreateFrame("Button", nil, profileMenu, "BackdropTemplate")
            item:SetHeight(itemHeight)
            item:SetPoint("TOPLEFT", 2, -2 - (i-1) * itemHeight)
            item:SetPoint("TOPRIGHT", -2, -2 - (i-1) * itemHeight)
            item:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
            item:SetBackdropColor(0,0,0,0)
            local itemText = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            GUI:SetFont(itemText, 11)
            itemText:SetPoint("LEFT", 6, 0)
            itemText:SetText(profileName)
            
            if profileName == db:GetCurrentProfile() then
                itemText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
            else
                itemText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
            end
            
            item:SetScript("OnEnter", function(self) self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.3) end)
            item:SetScript("OnLeave", function(self) self:SetBackdropColor(0,0,0,0) end)
            item:SetScript("OnClick", function()
                db:SetProfile(profileName)
                RefreshProfileDisplay()
                profileMenu:Hide()
            end)
        end
    end

    profileDropdown:SetScript("OnClick", function()
        if profileMenu:IsShown() then profileMenu:Hide() else BuildProfileMenu(); profileMenu:Show() end
    end)

    y = y - FORM_ROW - 10

    -- =====================================================
    -- CREATE NEW PROFILE SECTION
    -- =====================================================
    local newHeader = GUI:CreateSectionHeader(content, "Create New Profile")
    newHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - newHeader.gap

    local newProfileContainer = CreateFrame("Frame", nil, content)
    newProfileContainer:SetHeight(FORM_ROW)
    newProfileContainer:SetPoint("TOPLEFT", PAD, y)
    newProfileContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

    local newProfileLabel = newProfileContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    newProfileLabel:SetPoint("LEFT", 0, 0)
    newProfileLabel:SetText("Profile Name")
    GUI:SetFont(newProfileLabel, 12)
    newProfileLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local newProfileBoxBg = CreateFrame("Frame", nil, newProfileContainer, "BackdropTemplate")
    newProfileBoxBg:SetPoint("LEFT", newProfileContainer, "LEFT", 200, 0)
    newProfileBoxBg:SetSize(200, 24)
    GUI:CreateBackdrop(newProfileBoxBg, {0.08, 0.08, 0.08, 1}, {0.35, 0.35, 0.35, 1})

    local newProfileBox = CreateFrame("EditBox", nil, newProfileBoxBg)
    newProfileBox:SetPoint("LEFT", 8, 0)
    newProfileBox:SetPoint("RIGHT", -8, 0)
    newProfileBox:SetHeight(22)
    newProfileBox:SetAutoFocus(false)
    GUI:SetFont(newProfileBox, 11)
    newProfileBox:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    newProfileBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    newProfileBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local createBtn = GUI:CreateButton(newProfileContainer, "Create", 80, 24, function()
        local newName = newProfileBox:GetText()
        if newName and newName ~= "" and db then
            db:SetProfile(newName)
            newProfileBox:SetText("")
            RefreshProfileDisplay()
            -- Force rebuild of menu next time it opens
            for _, child in ipairs({profileMenu:GetChildren()}) do child:Hide(); child:SetParent(nil) end
        end
    end)
    createBtn:SetPoint("LEFT", newProfileBoxBg, "RIGHT", 10, 0)
    
    y = y - FORM_ROW - 10

    -- =====================================================
    -- UTILITY ACTIONS (COPY/DELETE)
    -- =====================================================
    local utilHeader = GUI:CreateSectionHeader(content, "Copy & Delete")
    utilHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - utilHeader.gap

    local copyWrapper = {selected = ""}
    local copyDropdown
    copyDropdown = GUI:CreateDropdown(content, "Copy From", cachedProfileList, "selected", copyWrapper, function(val)
        if val and val ~= "" then
            db:CopyProfile(val)
            RefreshProfileDisplay()
            copyWrapper.selected = ""
            if copyDropdown then copyDropdown:SetValue("") end
        end
    end)
    copyDropdown:SetPoint("TOPLEFT", PAD, y)
    copyDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    copyDropdown.label:ClearAllPoints()
    copyDropdown.label:SetPoint("LEFT", 0, 0)
    copyDropdown.label:SetSize(200, FORM_ROW)
    copyDropdown.dropdown:ClearAllPoints()
    copyDropdown.dropdown:SetPoint("LEFT", 200, 0)
    copyDropdown.dropdown:SetPoint("RIGHT", 0, 0)
    y = y - FORM_ROW - 10

    local deleteWrapper = {selected = ""}
    local deleteDropdown
    deleteDropdown = GUI:CreateDropdown(content, "Delete Profile", cachedProfileList, "selected", deleteWrapper, function(val)
        if val and val ~= "" then
            if val == db:GetCurrentProfile() then
                print("|cffff0000GravityUI:|r Cannot delete active profile.")
                deleteDropdown:SetValue("")
                return
            end
            GUI:ShowConfirmation({
                title = "Delete Profile?",
                message = "Delete profile '" .. val .. "'?",
                acceptText = "Delete",
                isDestructive = true,
                onAccept = function()
                    db:DeleteProfile(val)
                    RefreshProfileDisplay()
                    deleteWrapper.selected = ""
                    if deleteDropdown then deleteDropdown:SetValue("") end
                end,
                onCancel = function()
                    deleteWrapper.selected = ""
                    if deleteDropdown then deleteDropdown:SetValue("") end
                end
            })
        end
    end)
    deleteDropdown:SetPoint("TOPLEFT", PAD, y)
    deleteDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    deleteDropdown.label:ClearAllPoints()
    deleteDropdown.label:SetPoint("LEFT", 0, 0)
    deleteDropdown.label:SetSize(200, FORM_ROW)
    deleteDropdown.dropdown:ClearAllPoints()
    deleteDropdown.dropdown:SetPoint("LEFT", 200, 0)
    deleteDropdown.dropdown:SetPoint("RIGHT", 0, 0)
    y = y - FORM_ROW - 10
    
    -- =====================================================
    -- AUTO-SWITCH SECTION
    -- =====================================================
    if db and db.IsDualSpecEnabled then
        local specHeader = GUI:CreateSectionHeader(content, "Spec Auto-Switch")
        specHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - specHeader.gap

        local enableSwitch = GUI:CreateCheckbox(content, "Enable Spec Profiles", "enabled", {enabled = db:IsDualSpecEnabled()}, function(val)
            db:SetDualSpecEnabled(val)
        end)
        enableSwitch:SetPoint("TOPLEFT", PAD, y)
        y = y - FORM_ROW - 10

        local numSpecs = GetNumSpecializations()
        for i = 1, numSpecs do
            local _, specName = GetSpecializationInfo(i)
            if specName then
                local currentSpec = GetSpecialization()
                local displayName = (i == currentSpec) and (specName .. " (Active)") or specName
                
                local specWrapper = {selected = db:GetDualSpecProfile(i) or ""}
                local specDropdown = GUI:CreateDropdown(content, displayName, cachedProfileList, "selected", specWrapper, function(val)
                    db:SetDualSpecProfile(val, i)
                end)
                specDropdown:SetPoint("TOPLEFT", PAD, y)
                specDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
                
                specDropdown.label:ClearAllPoints()
                specDropdown.label:SetPoint("LEFT", 0, 0)
                specDropdown.label:SetSize(200, FORM_ROW)
                specDropdown.dropdown:ClearAllPoints()
                specDropdown.dropdown:SetPoint("LEFT", 200, 0)
                specDropdown.dropdown:SetPoint("RIGHT", 0, 0)
                
                y = y - FORM_ROW
            end
        end
    end

    content:SetHeight(math.abs(y) + 50)
end





---------------------------------------------------------------------------
-- TAB: Import/Export
---------------------------------------------------------------------------
local function BuildImportExportTab(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local y = -10
    local PAD = 10
    
    GUI:CreateLabel(content, "Export or import your complete GUI profile.", 11, C.textMuted):SetPoint("TOPLEFT", PAD, y)
    y = y - 25
    
    local exportHeader = GUI:CreateSectionHeader(content, "Export Current Profile")
    exportHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - exportHeader.gap
    
    local exportBox = GUI:CreateScrollableTextBox(content, 120, Addon:ExportProfileToString(), true)
    exportBox:SetPoint("TOPLEFT", PAD, y)
    exportBox:SetPoint("RIGHT", -PAD - 20, 0)
    y = y - 130
    
    local selectBtn = GUI:CreateButton(content, "Select All", 100, 24, function()
        exportBox.editBox:SetFocus()
        exportBox.editBox:HighlightText()
    end)
    selectBtn:SetPoint("TOPLEFT", PAD, y)
    GUI:CreateLabel(content, "then press Ctrl+C to copy", 10, C.textMuted):SetPoint("LEFT", selectBtn, "RIGHT", 10, 0)
    y = y - 50
    
    local importHeader = GUI:CreateSectionHeader(content, "Import Profile String")
    importHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - importHeader.gap
    
    local importBox = GUI:CreateScrollableTextBox(content, 120, "")
    importBox:SetPoint("TOPLEFT", PAD, y)
    importBox:SetPoint("RIGHT", -PAD - 20, 0)
    y = y - 130
    
    local importBtn = GUI:CreateButton(content, "IMPORT AND RELOAD", 180, 26, function()
        local str = importBox.editBox:GetText()
        if str and str ~= "" then
            GUI:ShowConfirmation({
                title = "Import Profile?",
                message = "Are you sure you want to import this profile string?",
                warningText = "This will overwrite your current settings and reload the UI.",
                acceptText = "Import",
                isDestructive = true,
                onAccept = function()
                    local ok, err = Addon:ImportProfileFromString(str)
                    if ok then
                        print("|cFF30D1FFGravityUI:|r Profile imported! Reloading...")
                        Addon:SafeReload()
                    else
                        print("|cFFFF0000GravityUI: Import failed:|r " .. (err or "Unknown error"))
                    end
                end,
            })
        end
    end)
    importBtn:SetPoint("TOPLEFT", PAD, y)
    
    content:SetHeight(math.abs(y) + 50)
end


---------------------------------------------------------------------------
-- TAB: Gravity Strings
---------------------------------------------------------------------------
local function BuildGravityStringsTab(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local PAD = 10
    
    local topLabel = GUI:CreateLabel(content, "Pre-configured strings for supported addons.", 11, C.textMuted)
    topLabel:SetPoint("TOPLEFT", PAD, -10)
    
    local imports = _G.GravityUI and _G.GravityUI.imports
    if not imports then
        GUI:CreateLabel(content, "No import strings found.", 12, {1,0,0,1}):SetPoint("TOPLEFT", PAD, -40)
        return
    end
    
    -- List of major addons/features
    local keys = {
        "EditMode", 
        "Details", 
        "Plater", 
        "BigWigs", 
        "DandersFrames", 
        "Platynator",
        "BCDM",       -- New
        "UUF",        -- New
        "GUIPROFILE"  -- Renamed/New
    }
    
    local headers = {}
    
    local function RefreshLayout()
        local totalH = 40
        for i, h in ipairs(headers) do
            totalH = totalH + h:GetHeight() + 10
        end
        content:SetHeight(totalH + 40)
    end

    local lastHeader = topLabel
    for _, key in ipairs(keys) do
        local data = imports[key]
        if data then
            local header = GUI:CreateCollapsibleHeader(content, data.name or key, false)
            header:SetPoint("TOPLEFT", lastHeader, "BOTTOMLEFT", (lastHeader == topLabel) and 0 or 0, (lastHeader == topLabel) and -20 or -10)
            header:SetPoint("RIGHT", content, "RIGHT", -PAD-20, 0)
            
            header.OnToggle = function(expanded)
                -- Lazy Load: Create content only when expanded for the first time
                if expanded and not header.hasLoadedData then
                    local box = GUI:CreateScrollableTextBox(header.content, 100, data.data, true)
                    box:SetPoint("TOPLEFT", 5, -5)
                    box:SetPoint("RIGHT", -25, 0)
                    
                    local copy = GUI:CreateButton(header.content, "Select String", 120, 20, function()
                        box.editBox:SetFocus()
                        box.editBox:HighlightText()
                    end)
                    copy:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -5)
                    
                    -- Set content height correctly
                    header.content:SetHeight(135)
                    header.hasLoadedData = true
                    
                    -- Update header height manually since framework calc happened before content existed
                    header:SetHeight(30 + 135)
                end
                
                RefreshLayout()
            end
            
            table.insert(headers, header)
            lastHeader = header
        end
    end
    
    RefreshLayout()
end

---------------------------------------------------------------------------
-- TAB: Installer
---------------------------------------------------------------------------
local function BuildInstallerTab(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local y = -10
    local PAD = 10
    
    GUI:CreateLabel(content, "Quickly setup supported addons with Gravity configurations.", 11, C.textMuted):SetPoint("TOPLEFT", PAD, y)
    y = y - 40
    
    local expressHeader = GUI:CreateSectionHeader(content, "New Setup: Express Installer")
    expressHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - expressHeader.gap
    
    GUI:CreateLabel(content, "Overwrites current configurations with Gravity's defaults.", 11):SetPoint("TOPLEFT", PAD, y)
    y = y - 20
    
    local expressBtn = GUI:CreateButton(content, "Run Express Installer", 200, 30, function()
        GUI:InstallAddonsProfiles()
    end)
    expressBtn:SetPoint("TOPLEFT", PAD, y)
    y = y - 60
    
    local twinkHeader = GUI:CreateSectionHeader(content, "Twink Setup: Sync Profiles")
    twinkHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - twinkHeader.gap
    
    GUI:CreateLabel(content, "Switches existing addon profiles to 'GravityUI' without overwriting data.", 11):SetPoint("TOPLEFT", PAD, y)
    y = y - 20
    
    local twinkBtn = GUI:CreateButton(content, "Run Twink Installer", 200, 30, function()
        GUI:TwinkInstaller()
    end)
    twinkBtn:SetPoint("TOPLEFT", PAD, y)
    
    content:SetHeight(math.abs(y) + 50)
end


---------------------------------------------------------------------------
-- MAIN REGISTRATION
---------------------------------------------------------------------------
ns.GUI:RegisterPage("profiles", {
    title = "Profiles",
    OnBuild = function(content)
        -- We don't want the default scrollframe to interfere with our sub-tabs
        -- So we hide the parent's scrollchild and use our own structure
        local scrollFrame = content:GetParent()
        content:Hide()
        
        -- Hide the outer scrollbar if it exists
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            -- Also hook OnShow to ensure it stays hidden
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        local subTabs = GUI:CreateSubTabs(scrollFrame, {
            { name = "Manage Profiles", builder = BuildAceDBProfilesTab },
            { name = "Import/Export", builder = BuildImportExportTab },
            { name = "Gravity Strings", builder = BuildGravityStringsTab },
            { name = "Installers", builder = BuildInstallerTab },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
        
        -- Expose for external control (Installers button)
        GUI.pages["profiles"].subTabs = subTabs
    end,
})
