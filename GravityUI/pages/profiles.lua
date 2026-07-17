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

    local infoBox = GUI:CreateInfoBox(content, "|cffFFCC00Info:|r Manage profiles and auto-switch based on specialization.")
    infoBox:SetPoint("TOPLEFT", PAD, y)
    y = y - infoBox:GetHeight() - 10
    
    -- =====================================================
    -- CURRENT PROFILE SECTION
    -- =====================================================
    local currentHeader = GUI:CreateSectionHeader(content, "Current Profile")
    currentHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - currentHeader.gap
    y = y - 10

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
    y = y - 10
    
    local profileDropdown
    -- Wrapper to hold current selection status
    local profileWrapper = { selected = db and db:GetCurrentProfile() or "Default" }
    
    profileDropdown = GUI:CreateDropdown(content, "Select Profile", cachedProfileList, "selected", profileWrapper, function(val)
        if val and val ~= db:GetCurrentProfile() then
            db:SetProfile(val)
            RefreshProfileDisplay()
            -- Close menu is handled by dropdown logic
        end
    end)
    profileDropdown:SetPoint("TOPLEFT", PAD, y)
    profileDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    
    -- Layout adjustments for standard dropdown
    profileDropdown.label:ClearAllPoints()
    profileDropdown.label:SetPoint("LEFT", 0, 0)
    profileDropdown.label:SetSize(200, FORM_ROW)
    profileDropdown.dropdown:ClearAllPoints()
    profileDropdown.dropdown:SetPoint("LEFT", 200, 0)
    profileDropdown.dropdown:SetPoint("RIGHT", 0, 0)
    
    -- Hook for RefreshProfileDisplay to update the dropdown text externally
    profileDropdown.RefreshText = function(self, val)
         self:SetValue(val)
    end
    
    y = y - FORM_ROW - 10

    -- =====================================================
    -- CREATE NEW PROFILE SECTION
    -- =====================================================
    local newHeader = GUI:CreateSectionHeader(content, "Create New Profile")
    newHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - newHeader.gap
    y = y - 10

    local newProfileWrapper = { name = "" }
    local newProfileInput = GUI:CreateInput(content, "Profile Name", "name", newProfileWrapper)
    newProfileInput:SetPoint("TOPLEFT", PAD, y)
    -- We need space for the button, so don't stretch fully right immediately or handle button positioning
    newProfileInput:SetWidth(450) -- Adjusted width to fit button
    
    -- Manual layout tweaks for Input to match the style
    newProfileInput.label:ClearAllPoints()
    newProfileInput.label:SetPoint("LEFT", 0, 0)
    newProfileInput.label:SetSize(200, 24)
    newProfileInput.editBox:ClearAllPoints()
    newProfileInput.editBox:SetPoint("LEFT", 200, 0)
    newProfileInput.editBox:SetWidth(200)
    
    -- Button next to input
    local createBtn = GUI:CreateButton(content, "Create", 80, 24, function()
        local newName = newProfileInput.editBox:GetText()
        if newName and newName ~= "" and db then
             db:SetProfile(newName)
             newProfileWrapper.name = "" -- clear
             newProfileInput.editBox:SetText("")
             RefreshProfileDisplay()
        end
    end)
    createBtn:SetPoint("LEFT", newProfileInput.editBox, "RIGHT", 10, 0)
    
    y = y - FORM_ROW - 10

    -- =====================================================
    -- UTILITY ACTIONS (COPY/DELETE)
    -- =====================================================
    local utilHeader = GUI:CreateSectionHeader(content, "Copy & Delete")
    utilHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - utilHeader.gap
    y = y - 10

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
        y = y - 10

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
    
    local infoBox = GUI:CreateInfoBox(content, "|cffFFCC00Info:|r Export or import your complete GUI profile.\n\n|cffFFCC00Note:|r Press CTRL+C to Copy the string.")
    infoBox:SetPoint("TOPLEFT", PAD, y)
    y = y - infoBox:GetHeight() - 10
    
    local exportHeader = GUI:CreateSectionHeader(content, "Export Current Profile")
    exportHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - exportHeader.gap
    y = y - 10
    
    local exportBox = GUI:CreateScrollableTextBox(content, 120, Addon:ExportProfileToString(), true)
    exportBox:SetPoint("TOPLEFT", PAD, y)
    exportBox:SetPoint("RIGHT", -PAD - 20, 0)
    y = y - 130
    
    local selectBtn = GUI:CreateButton(content, "Select All", 100, 24, function()
        exportBox.editBox:SetFocus()
        exportBox.editBox:HighlightText()
    end)
    selectBtn:SetPoint("TOPLEFT", PAD, y)

    y = y - 50
    
    local importHeader = GUI:CreateSectionHeader(content, "Import Profile String")
    importHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - importHeader.gap
    y = y - 10
    
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
    
    local infoBox = GUI:CreateInfoBox(content, "|cffFFCC00Info:|r Pre-configured strings for supported addons.\n\n|cffFFCC00Note:|r Press CTRL+C to Copy the string.")
    infoBox:SetPoint("TOPLEFT", PAD, y)
    y = y - infoBox:GetHeight() - 10

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
            "EllesmereUI", "GravityUI", "MethodRaidTools"
        }

        
        local lastHeader = nil
        local shown = {}

        local function AddStringHeader(key, d)
            if not d or type(d) ~= "table" or type(d.data) ~= "string" then return end
            if shown[key] then return end
            shown[key] = true

            local header = GUI:CreateCollapsibleHeader(stringsContainer, d.name or key, false)
            if lastHeader then
                header:SetPoint("TOPLEFT", lastHeader, "BOTTOMLEFT", 0, -10)
            else
                header:SetPoint("TOPLEFT", 0, 0)
            end
            header:SetPoint("RIGHT", 0, 0)
            
            header.OnToggle = function(expanded)
                if expanded and not header.hasLoadedData then
                    local box = GUI:CreateScrollableTextBox(header.content, 100, d.data, true)
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

        -- 1. Standard keys (ordered)
        for _, key in ipairs(keys) do
            local data = imports[key]
            if not data and key == "GravityUI" then data = imports["GUIPROFILE"] end
            AddStringHeader(key, data)
        end

        -- 2. Dynamic keys (catch-all for any additional entries)
        for key, data in pairs(imports) do
            AddStringHeader(key, data)
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
    y = y - 10

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
    
    -- [PERSISTENCE] Helpers
    local function GetGlobalSelection(addonName)
        local db = ns.GetAceDB()
        local val = nil
        if db and db.global and db.global.installer and db.global.installer.selections then
            val = db.global.installer.selections[addonName]
        end
        
        -- [FIX] Sanitize input: If corrupted with table, treat as nil (fallback to default) AND auto-repair
        if type(val) == "table" then
             -- Auto-repair corruption
             if db and db.global and db.global.installer and db.global.installer.selections then
                 db.global.installer.selections[addonName] = nil
             end
             return nil 
        end
        
        return val
    end

    local function SetGlobalSelection(addonName, value)
        -- [FIX] Sanitize output: Force boolean or nil, never allow table
        if type(value) == "table" then
            value = false
        end
        
        local db = ns.GetAceDB()
        if db and db.global then
            if not db.global.installer then db.global.installer = {} end
            if not db.global.installer.selections then db.global.installer.selections = {} end
            db.global.installer.selections[addonName] = value
        end
    end

    local function UpdateStatus()
        local targetProfile = "GravityUI" 
        local isReady, report = GUI.Installer:GetSystemStatus(targetProfile)
        
        -- Main Header
        if isReady then
            statusText:SetText("|cFF00FF00System Fully Configured|r") 
        else
            statusText:SetText("|cFFFF0000Configuration Mismatch|r")
        end
        
        -- Metadata Logic
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
        local topOffset = metaDisplayed and -50 or -35
        detailsFrame:SetPoint("TOPLEFT", 0, topOffset)

        -- Clear previous children (hide them)
        for _, child in ipairs({detailsFrame:GetChildren()}) do child:Hide() end
        
        -- 1. Split Items Categories & Init State
        local importantItems = {}
        local optionalItems = {}
        
        for _, item in ipairs(report) do
            -- Default Selection State Logic
            if selectionState[item.label] == nil then
                -- [PERSISTENCE] Check Global DB First
                local savedState = GetGlobalSelection(item.name)
                
                if savedState ~= nil then
                    selectionState[item.label] = savedState
                else
                    if item.category == "Optional" then
                        selectionState[item.label] = false
                    else
                        selectionState[item.label] = true
                    end
                end
            end
            
            -- Override if not loaded -> False
            if not item.loaded then
                selectionState[item.label] = false
            end

            if item.category == "Optional" then
                table.insert(optionalItems, item)
            else
                table.insert(importantItems, item)
            end
        end
        
        -- 2. Render Columns helper
        -- We hold references to created fontstrings for titles to hide/reuse safely?
        -- Actually, we can just create them if missing.
        if not detailsFrame.leftTitle then
             detailsFrame.leftTitle = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
             detailsFrame.leftTitle:SetPoint("TOPLEFT", 10, 0)
             detailsFrame.leftTitle:SetText("Important Addon Profiles")
        end
        detailsFrame.leftTitle:Show()
        
        if not detailsFrame.rightTitle then
             detailsFrame.rightTitle = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
             detailsFrame.rightTitle:SetPoint("TOPLEFT", 350, 0)
             detailsFrame.rightTitle:SetText("Optional Addon Profiles")
        end
        detailsFrame.rightTitle:Show()

        local function UpdateHeader(currentReport)
             local allOk = true
             
             for _, item in ipairs(currentReport) do
                 -- If Checked AND Mismatch -> Fail
                 -- (Important addons are Checked by default, so this covers them too if selectionState is correct)
                 -- We must rely on selectionState.
                 
                 local isChecked = selectionState[item.label]
                 -- Fallback for safety if nil (shouldn't happen with init logic below, but just in case)
                 if isChecked == nil then
                     if item.category == "Optional" then isChecked = false else isChecked = true end
                 end
                 
                 if isChecked and (not item.match) then
                     allOk = false
                     break
                 end
             end
             
             if allOk then
                statusText:SetText("|cFF00FF00System Fully Configured|r") 
             else
                statusText:SetText("|cFFFF0000Configuration Mismatch|r")
             end
        end

        local function RenderColumn(items, xOffset)
            local y = -25
            
            for _, item in ipairs(items) do
                 local row = detailsFrame[item.label]
                 if not row then
                    row = CreateFrame("Frame", nil, detailsFrame)
                    row:SetSize(320, 20) -- Explicit Size to ensure visibility
                    
                    local cbState = { checked = selectionState[item.label] }
                    
                    local label = item.label
                    row.cb = GUI:CreateCheckbox(row, "", "checked", cbState, function(val)
                         selectionState[label] = val
                         -- [PERSISTENCE] Save to DB
                         SetGlobalSelection(item.name, val)
                         
                         if row.UpdateColor then row:UpdateColor() end
                         
                         -- Dynamic Header Update
                         UpdateHeader(report)
                    end)
                    row.cb:SetPoint("LEFT", 0, 0)
                    row.cb:SetSize(300, 24) -- Width for checkbox handling
                    
                    row.text = row.cb.label 
                    detailsFrame[item.label] = row
                 end
                 
                 -- Update Color Logic
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
                 
                 -- Refresh Display
                 if item.loaded == false then
                      if row.cb.Disable then row.cb:Disable() end
                      row.text:SetText(item.label .. ": |cFF888888Not Loaded|r")
                 else
                      if row.cb.Enable then row.cb:Enable() end
                      local contentText = item.label .. ": " .. (item.current or "Unknown")
                      if not item.match then contentText = contentText .. " (|cFFFF0000Mismatch|r)" end
                      row.text:SetText(contentText)
                      if row.cb.SetValue then row.cb:SetValue(selectionState[item.label], true) end
                 end
                 
                 row:UpdateColor()
                 row:ClearAllPoints()
                 row:SetPoint("TOPLEFT", xOffset, y)
                 row:Show()
                 
                 y = y - 24
            end
            return math.abs(y)
        end
        
        local h1 = RenderColumn(importantItems, 10)
        local h2 = RenderColumn(optionalItems, 350)
        
        local maxH = math.max(h1, h2)
        detailsFrame:SetHeight(maxH)
        
        -- Initial Header Update
        UpdateHeader(report)
        
        return (math.abs(topOffset) + maxH)
    end
    
    local statusH = UpdateStatus()
    y = y - statusH - 20
    
    
    -- Helper to build allowList
    local function GetAllowList()
        local list = {}
        -- Iterate the registry to find names matching our labels
        for _, addon in ipairs(GUI.Installer.registry) do
            -- If selectionState[addon.label] is true (or nil->true default)
            local function AddStringHeader(key, d)
            if not d or type(d) ~= "table" or type(d.data) ~= "string" then return end
            if shown[key] then return end
            shown[key] = true
            end
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
    y = y - 10

    -- ACTION 1: FRESH INSTALL
    local freshLabel = GUI:CreateLabel(content, "Fresh Installation (Express Installation)", 12, C.accent)
    freshLabel:SetPoint("TOPLEFT", PAD, y)
    y = y - 20
    
    local freshDesc = GUI:CreateLabel(content, "Import 'GravityUI' Profiles for the selected Addons above, with the GravityUI Profile Config.", 11, C.textMuted)
    freshDesc:SetPoint("TOPLEFT", PAD, y)
    y = y - 15

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
    -- Custom Red Theme for Fresh Install
    installBtn:SetBackdropColor(0.4, 0.1, 0.1, 0.8)
    installBtn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    if installBtn.glow then installBtn.glow:SetColorTexture(1, 0.2, 0.2, 0.1) end
    
    installBtn:HookScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.3, 0.3, 1)
    end)
    installBtn:HookScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
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
    -- Custom Blue Theme for Sync (matching GravityUI Accent)
    syncBtn:SetBackdropColor(0, 0.2, 0.3, 0.8)
    syncBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    syncBtn:HookScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accentHover[1], C.accentHover[2], C.accentHover[3], 1)
    end)
    syncBtn:HookScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
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
    subTabs = {
        { name = "Manage Profiles", builder = BuildAceDBProfilesTab },
        { name = "Import / Export", builder = BuildImportExportTab },
        { name = "Gravity Strings", builder = BuildGravityStringsTab },
        { name = "Installers",      builder = BuildInstallerTab },
    },
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
        
        local opts = GUI.pages["profiles"]
        opts.subTabsContainer = GUI:CreateSubTabs(scrollFrame, opts.subTabs)
        opts.subTabsContainer:SetPoint("TOPLEFT", 10, -10)
        opts.subTabsContainer:SetPoint("TOPRIGHT", -10, 0)
    end,
    OnShow = function(content, subIndex)
        local opts = GUI.pages["profiles"]
        if not opts.subTabsContainer then return end
        
        subIndex = subIndex or 1
        
        for _, cf in pairs(opts.subTabsContainer.tabContents) do
            cf:Hide()
        end
        
        if opts.subTabsContainer.tabContents[subIndex] then
            opts.subTabsContainer.tabContents[subIndex]:Show()
        end
    end
})
