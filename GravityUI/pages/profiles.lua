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
                deleteDropdown.SetValue("")
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
                    if deleteDropdown then deleteDropdown.SetValue("") end
                end,
                onCancel = function()
                    deleteWrapper.selected = ""
                    if deleteDropdown then deleteDropdown.SetValue("") end
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
    local y = -10
    
    local topLabel = GUI:CreateLabel(content, "Pre-configured strings for supported addons.", 11, C.textMuted)
    topLabel:SetPoint("TOPLEFT", PAD, y)
    y = y - 30

    -- 1. Source Profile Dropdown
    local availableProfiles = GUI.Installer and GUI.Installer:GetSourceProfiles() or {}
    local defaultSource = "Cronix"
    -- Check if Cronix exists, if not pick first
    local hasDefault = false
    for _, v in ipairs(availableProfiles) do if v == defaultSource then hasDefault = true break end end
    if not hasDefault and #availableProfiles > 0 then defaultSource = availableProfiles[1] end
    
    local selectedSource = defaultSource
    local sourceWrapper = { selected = selectedSource }
    local stringsContainer -- Forward declare

    local sourceDropdown 
    sourceDropdown = GUI:CreateDropdown(content, "GravityUI Profile", 
        (function() 
            local list = {}; 
            for _,v in ipairs(availableProfiles) do table.insert(list, {text=v, value=v}) end; 
            return list 
        end)(), 
        "selected", sourceWrapper, function(val)
            selectedSource = val
            if stringsContainer and stringsContainer.Rebuild then stringsContainer:Rebuild(val) end
        end
    )
    sourceDropdown:SetPoint("TOPLEFT", PAD, y)
    sourceDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    sourceDropdown.label:ClearAllPoints()
    sourceDropdown.label:SetPoint("LEFT", 0, 0)
    sourceDropdown.label:SetSize(100, 30)
    sourceDropdown.dropdown:ClearAllPoints()
    sourceDropdown.dropdown:SetPoint("LEFT", 110, 0)
    sourceDropdown.dropdown:SetPoint("RIGHT", 0, 0)
    
    y = y - 40

    -- 2. Container for Strings
    stringsContainer = CreateFrame("Frame", nil, content)
    stringsContainer:SetPoint("TOPLEFT", PAD, y)
    stringsContainer:SetPoint("RIGHT", -PAD, 0)
    stringsContainer:SetHeight(10) -- Will autosize

    local headers = {}

    function stringsContainer:Rebuild(sourceName)
        -- Clear existing headers
        for _, h in ipairs(headers) do 
            h:Hide() 
            h:SetParent(nil) 
        end
        headers = {}
        
        -- Resolve imports
        local imports
        if sourceName and _G.GravityUI and _G.GravityUI.profiles and _G.GravityUI.profiles[sourceName] then
            imports = _G.GravityUI.profiles[sourceName].imports
        else
            imports = _G.GravityUI and _G.GravityUI.imports
        end
        
        if not imports then
            -- Maybe show a "No Data" label?
            return 
        end

        -- List of keys
        local keys = {
            "EditMode", "Details", "Plater", "BigWigs", "DandersFrames", 
            "Platynator", "BCDM", "UUF", "GravityUI"
        }
        
        local lastHeader = nil
        for _, key in ipairs(keys) do
            local data = imports[key]
            -- Fallback for legacy key GUIPROFILE
            if not data and key == "GravityUI" then data = imports["GUIPROFILE"] end

            if data then
                local header = GUI:CreateCollapsibleHeader(stringsContainer, data.name or key, false)
                if lastHeader then
                    header:SetPoint("TOPLEFT", lastHeader, "BOTTOMLEFT", 0, -10)
                else
                    header:SetPoint("TOPLEFT", 0, 0)
                end
                header:SetPoint("RIGHT", 0, 0)
                
                header.OnToggle = function(expanded)
                    if expanded and not header.hasLoadedData then
                        local box = GUI:CreateScrollableTextBox(header.content, 100, data.data, true)
                        box:SetPoint("TOPLEFT", 5, -5)
                        box:SetPoint("RIGHT", -25, 0)
                        
                        local copy = GUI:CreateButton(header.content, "Select String", 120, 20, function()
                            box.editBox:SetFocus()
                            box.editBox:HighlightText()
                        end)
                        copy:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -5)
                        
                        header.content:SetHeight(135)
                        header.hasLoadedData = true
                        header:SetHeight(30 + 135)
                    end
                    stringsContainer:RefreshLayout()
                end
                
                table.insert(headers, header)
                lastHeader = header
            end
        end
        stringsContainer:RefreshLayout()
    end

    function stringsContainer:RefreshLayout()
        local totalH = 0
        for i, h in ipairs(headers) do
            totalH = totalH + h:GetHeight() + 10
        end
        stringsContainer:SetHeight(totalH)
        content:SetHeight(math.abs(y) + totalH + 50)
    end

    -- Initial Build
    stringsContainer:Rebuild(selectedSource)
end

---------------------------------------------------------------------------
-- TAB: Installer
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- TAB: Installer
---------------------------------------------------------------------------
local function BuildInstallerTab(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local y = -10
    local PAD = 10
    local FORM_ROW = 30
    
    -- Get available source profiles
    local availableProfiles = GUI.Installer:GetSourceProfiles()
    if #availableProfiles == 0 then
        table.insert(availableProfiles, "GravityUI") -- Default fallback
    end
    
    local selectedSource = availableProfiles[1] or "GravityUI"
    -- Prefer "Cronix" if available as default (User Request)
    for _, v in ipairs(availableProfiles) do
        if v == "Cronix" then selectedSource = "Cronix" break end
    end

    -- 1. STATUS SECTION
    local statusHeader = GUI:CreateSectionHeader(content, "System Status")
    statusHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - statusHeader.gap

    local statusFrame = CreateFrame("Frame", nil, content)
    statusFrame:SetSize(1, 1) 
    statusFrame:SetPoint("TOPLEFT", PAD, y)
    statusFrame:SetPoint("RIGHT", -PAD, y)
    
    local statusText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    statusText:SetPoint("TOP", 0, 0)
    statusText:SetText("Checking...")
    
    -- Sub-details container
    local detailsFrame = CreateFrame("Frame", nil, statusFrame)
    detailsFrame:SetPoint("TOPLEFT", 0, -25)
    detailsFrame:SetPoint("RIGHT", 0, 0)
    detailsFrame:SetHeight(10)

    -- Checkbox States
    local selectionState = {} 
    -- Initialize selectionState? We can do it on first status update or just check defaults
    -- Default behavior: Check Everything that is loaded.

    local function UpdateStatus()
        local targetProfile = "GravityUI" 
        local isReady, report = GUI.Installer:GetSystemStatus(targetProfile)
        
        -- Main Header
        if isReady then
            statusText:SetText("|cFF00FF00System Fully Configured|r") 
        else
            statusText:SetText("|cFFFF0000Configuration Mismatch|r")
        end
        
        
        -- Show Global Metadata (Account-Wide) if available
        -- This shows "Who did the last setup", even if current char is mismatched.
        -- Use GetAceDB() because GetDB() returns the profile (no global)
        local rawDB = ns.GetAceDB()
        local globalDB = rawDB and rawDB.global
        local metaDisplayed = false
        
        if globalDB and globalDB.installer and globalDB.installer.setupBy then
            local meta = "|cFF888888Setup by: " .. globalDB.installer.setupBy
            if globalDB.installer.setupDate then meta = meta .. " (" .. globalDB.installer.setupDate .. ")" end
            meta = meta .. "|r"
            
            if not statusFrame.metaText then
                statusFrame.metaText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                statusFrame.metaText:SetPoint("TOP", statusText, "BOTTOM", 0, -5)
            end
            statusFrame.metaText:SetText(meta)
            statusFrame.metaText:Show()
            metaDisplayed = true
        else
            if statusFrame.metaText then statusFrame.metaText:Hide() end
        end
        
        -- Adjust Details Frame position based on metadata visibility
        if metaDisplayed then
             detailsFrame:SetPoint("TOPLEFT", 0, -50)
        else
             detailsFrame:SetPoint("TOPLEFT", 0, -35)
        end
        
        -- Details
        local dy = 0
        for _, child in ipairs({detailsFrame:GetChildren()}) do child:Hide() end
        
        for _, item in ipairs(report) do
            -- Create/Reuse Checkbox Container or Row
            -- We need a Checkbox on Left, Text on Right.
            
            -- Ideally we reuse frames or create new ones properly.
            -- Using a hash-based retrieval for reusing by addon name would be best but simple create works for low item count (~10)
            
            local row = detailsFrame[item.label] 
            if not row then
                row = CreateFrame("Frame", nil, detailsFrame)
                row:SetHeight(18)
                
                -- Create temporary state object for this checkbox to ensure it initializes Checked
                local cbState = { checked = true }
                
                -- FORCE unchecked if not loaded
                if not item.loaded then
                    selectionState[item.label] = false
                    cbState.checked = false
                end
                
                if selectionState[item.label] ~= nil then cbState.checked = selectionState[item.label] end
                
                -- Capture label for closure
                local labelText = item.label
                
                -- GUI:CreateCheckbox(parent, label, key, table, callback)
                row.cb = GUI:CreateCheckbox(row, "", "checked", cbState, function(val) 
                     selectionState[labelText] = val 
                     if row.UpdateColor then row:UpdateColor() end
                end)
                row.cb:SetPoint("LEFT", 0, 0)
                row.cb:SetSize(350, 24) 
                
                -- We use the framework's label
                row.text = row.cb.label 
                
                detailsFrame[item.label] = row
            end
            
            -- Re-Attach Color Update logic to row for reuse (FRESH CLOSURE)
            row.UpdateColor = function(self)
                local isChecked = selectionState[item.label]
                if not self.text then return end
                
                if item.loaded == false then
                     self.text:SetTextColor(0.5, 0.5, 0.5, 1)
                     return
                end
                
                if not isChecked then
                     self.text:SetTextColor(0.5, 0.5, 0.5, 1)
                else
                     if item.match then
                         self.text:SetTextColor(0, 1, 0, 1)
                     else
                         self.text:SetTextColor(1, 0, 0, 1)
                     end
                end
            end
            
            -- Handle Loaded State
            if item.loaded == false then
                 -- Not Loaded: Disable Checkbox and force Unchecked
                 if row.cb.Disable then row.cb:Disable() end
                 -- selectionState already forced false above
                 
                 -- Update Text
                 row.text:SetText(item.label .. ": |cFF888888Not Loaded|r")
                 -- Force gray color (UpdateRowColor handles it)
                 if row.cb.label then row.cb.label:SetTextColor(0.5, 0.5, 0.5, 1) end
            else
                 -- Loaded: Enable
                 if row.cb.Enable then row.cb:Enable() end
                 -- Initialize state if nil
                 if selectionState[item.label] == nil then selectionState[item.label] = true end
                 
                 -- Update Text Content
                 local contentText = item.label .. ": " .. (item.current or "Unknown")
                 if not item.match then contentText = contentText .. " (Expected: " .. targetProfile .. ")" end
                 row.text:SetText(contentText)
                 
                 -- Ensure checkbox visual matches state (might trigger callback)
                 if row.cb.SetValue then row.cb:SetValue(selectionState[item.label], false) end
            end
            
            row:UpdateColor()
            
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 10, dy)
            row:SetPoint("RIGHT", -10, dy)
            row:Show()

            
            -- Initialize state in our master table if missing
            if selectionState[item.label] == nil then selectionState[item.label] = true end
            
            -- Force visual update if needed (though binding above handles it usually)
            -- If the row was reused, we might need to update the checkbox?
            -- Since we don't have a reliable SetChecked on the wrapper usually...
            -- We just rely on the fact that we re-bind it or it's a new frame. 
            -- But we are caching 'row'. So reused rows might have stale state if we don't update 'cbState'.
            -- Actually, we passed 'cbState' during creation. Changing it now won't update the widget if it doesn't watch the table.
            -- Best approach without deep widget knowledge: Re-create structure or recreate widget?
            -- Or just assume the user won't toggle 100 times in a way that breaks reuse order (which is stable: by addon label).
            -- We ARE reusing by label (detailsFrame[item.label]), so the checkbox stays with the addon. 
            -- So the state should persist correctly as long as selectionState is source of truth.
            -- We just need to make sure visuals match selectionState.
            -- GUI Checkboxes usually update from table on Show? Or only on init?
            -- Let's try to set the checked value if the method exists.
            if row.cb.SetChecked then row.cb:SetChecked(selectionState[item.label]) end


            
            dy = dy - 24 -- Increased spacing for larger rows
        end
        detailsFrame:SetHeight(math.abs(dy))
        
        local totalH = 35 + math.abs(dy)
        return totalH 
    end
    
    local statusH = UpdateStatus()
    y = y - statusH - 20
    
    
    -- Helper to build allowList
    local function GetAllowList()
        local list = {}
        -- Iterate the registry to find names matching our labels
        for _, addon in ipairs(GUI.Installer.registry) do
            -- If selectionState[addon.label] is true (or nil->true default)
            local s = selectionState[addon.label]
            if s == nil then s = true end
            
            if s then
                list[addon.name] = true
            end
        end
        return list
    end

    -- 2. SETUP CONTROLS
    local setupHeader = GUI:CreateSectionHeader(content, "Setup & Synchronization")
    setupHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - setupHeader.gap

    -- ACTION 1: FRESH INSTALL
    local freshLabel = GUI:CreateLabel(content, "Fresh Installation (Express Installation)", 12, C.accent)
    freshLabel:SetPoint("TOPLEFT", PAD, y)
    y = y - 20
    
    local freshDesc = GUI:CreateLabel(content, "Import 'GravityUI' selected Gravity Profile settings and overwrite configuration for:", 11, C.textMuted)
    freshDesc:SetPoint("TOPLEFT", PAD, y)
    y = y - 15
    local addonListObj = GUI:CreateLabel(content, "The selected Addons from above (checked / unchecked)", 11, {1,1,1})
    addonListObj:SetPoint("TOPLEFT", PAD, y)
    y = y - 35

    -- Source Selection Dropdown
    local sourceWrapper = { selected = selectedSource }
    local sourceDropdown 
    sourceDropdown = GUI:CreateDropdown(content, "GravityUI Profile Config:", 
        (function() 
            local list = {}; 
            for _,v in ipairs(availableProfiles) do table.insert(list, {text=v, value=v}) end; 
            return list 
        end)(), 
        "selected", sourceWrapper, function(val)
            selectedSource = val
            -- Button Update if needed, though mostly static now
        end
    )
    sourceDropdown:SetPoint("TOPLEFT", PAD, y)
    sourceDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    sourceDropdown.label:ClearAllPoints()
    sourceDropdown.label:SetPoint("LEFT", 0, 0)
    sourceDropdown.label:SetSize(150, 30)
    sourceDropdown.dropdown:ClearAllPoints()
    sourceDropdown.dropdown:SetPoint("LEFT", 160, 0)
    sourceDropdown.dropdown:SetPoint("RIGHT", 0, 0)
    
    y = y - 45

    -- Forward declaration for Sync Button updates
    local syncBtn 
    local function UpdateSyncState()
        if not syncBtn then return end
        
        local rawDB = ns.GetAceDB()
        local globalDB = rawDB and rawDB.global
        local hasSetup = globalDB and globalDB.installer and globalDB.installer.setupDate
        
        if hasSetup then
            syncBtn:SetEnabled(true)
            syncBtn:SetText("Sync to 'GravityUI' (Alt/Twink)")
        else
            syncBtn:SetEnabled(false)
            syncBtn:SetText("Requires Fresh Install First")
        end
    end

    local installBtn -- Forward declare
    installBtn = GUI:CreateButton(content, "Install GravityUI (Fresh Install)", 220, 30, function()
        -- Confirm
        GUI:ShowConfirmation({
            title = "Fresh Install?",
            message = "Import data from '"..selectedSource.."' and |cFFFF0000OVERWRITE|r profile 'GravityUI'?\n\nAny existing configuration in 'GravityUI' will be reset.",
            isDestructive = true,
            acceptText = "INSTALL",
            onAccept = function()
                GUI.Installer:Install("GravityUI", selectedSource, GetAllowList())
                -- Update UI
                UpdateStatus()
                UpdateSyncState()
            end
        })
    end)
    -- Align button with the dropdown input for cleaner look
    installBtn:SetPoint("TOPLEFT", PAD + 160, y) 
    
    y = y - 60

    -- ACTION 2: SYNC (Twink)
    local syncLabel = GUI:CreateLabel(content, "Sync Existing Profile (Alt / Twink Installation)", 12, C.accent)
    syncLabel:SetPoint("TOPLEFT", PAD, y)
    y = y - 20
    
    local syncDesc = GUI:CreateLabel(content, "Switch Addon Profiles to use GravityUI Profiles without overwriting data.", 11, C.textMuted)
    syncDesc:SetPoint("TOPLEFT", PAD, y)
    y = y - 25

    -- Check if system is configured (profiles exist)
    local canSync = GUI.Installer:IsConfigured("GravityUI")
    
    syncBtn = GUI:CreateButton(content, "Sync to 'GravityUI' (Alt/Twink)", 220, 30, function()
        GUI.Installer:Synchronize("GravityUI", GetAllowList())
        -- Update status immediately
        UpdateStatus() 
        UpdateSyncState()
    end)
    -- Align with Install button
    syncBtn:SetPoint("TOPLEFT", PAD + 160, y)
    
    -- Initial State Check
    UpdateSyncState()
    
    -- Logic change: Always enable Sync button, but maybe warn if missing?
    -- User wanted it clickable even if not fully configured, to sync partials.
    -- "Make Sync Button "Clickable" only if Full Config is found" -> This was the OLD task.
    -- New request implies flexibility. 
    -- If I allow selective sync, checking strict global config is counter-intuitive.
    -- So I will ENABLE it always.
    
    -- if not canSync then
    --     syncBtn:SetEnabled(false)
    --     syncBtn:SetText("Profile 'GravityUI' not found")
    --     syncBtn.tooltip = "You must perform a Fresh Install at least once to create the 'GravityUI' profiles data."
    -- end


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
