-- GravityUI - Datapanels Page
local ADDON_NAME, ns = ...

local GUI = ns.GUI
local C = GUI.Colors

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: MINIMAP PANEL (Tab 1)
-- ═══════════════════════════════════════════════════════════════
local function BuildMinimapPanel(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()
    
    local db = ns.GetDB()
    if not db then return end
    
    -- Sub-table inits for safety (though usually handled by defaults)
    if not db.minimap then db.minimap = {} end
    if not db.minimap.datatext then db.minimap.datatext = {} end
    local mDT = db.minimap.datatext
    
    local refreshMinimap = ns.RefreshMinimap or function() end
    
    local ROW_HEIGHT = 30
    local LABEL_WIDTH = 220
    local WIDGET_WIDTH = 250
    
    -- Helper: Property Row
    local function CreatePropertyRow(container, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
        local row = CreateFrame("Frame", nil, container)
        row:SetSize(GUI.CONTENT_WIDTH - 20, ROW_HEIGHT)
        
        -- Label (Always White)
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetFont(ns.FONT_PATH or "Interface/AddOns/GravityUI/assets/Gravity.ttf", 12, "")
        label:SetJustifyH("LEFT")
        label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
        label:SetPoint("LEFT", 0, 0)
        label:SetText(labelText)
        label:SetTextColor(1, 1, 1, 1) -- Force White
        
        -- Widget
        local widget
        if widgetType == "checkbox" then
            widget = GUI:CreateCheckbox(row, "", arg1, arg2, arg3)
            widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
            
        elseif widgetType == "slider" then
            widget = GUI:CreateSlider(row, "", arg1, arg2, arg3, arg4, arg5, arg6)
            widget:SetHeight(ROW_HEIGHT)
            widget:SetWidth(220)
            widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
            
            widget.editBox:ClearAllPoints()
            widget.editBox:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
            widget.slider:ClearAllPoints()
            widget.slider:SetPoint("LEFT", widget, "LEFT", 0, 0)
            widget.slider:SetPoint("RIGHT", widget.editBox, "LEFT", -10, 0)
            
        elseif widgetType == "dropdown" then
            widget = GUI:CreateDropdown(row, "", arg1, arg2, arg3, arg4)
            widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
            widget:SetWidth(WIDGET_WIDTH)
            widget.dropdown:ClearAllPoints()
            widget.dropdown:SetPoint("LEFT", widget, "LEFT", 0, 0)
            widget.dropdown:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
            
        elseif widgetType == "color" then
             widget = GUI:CreateColorPicker(row, "", arg1, arg2, arg3)
             widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
             
        elseif widgetType == "input" then
            widget = GUI:CreateInput(row, "", arg1, arg2, arg3)
            widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
            widget:SetWidth(WIDGET_WIDTH)
            widget.editBox:SetWidth(WIDGET_WIDTH)
        end
        
        if ns.GUI and ns.GUI.RegisterInSearchIndex then
            ns.GUI:RegisterInSearchIndex(labelText, row)
        end
        
        return row
    end
    
    local function AddRow(container, label, type, ...)
        local row = CreatePropertyRow(container, label, type, ...)
        local count = container.rowCount or 0
        row:SetPoint("TOPLEFT", 10, -10 - (count * (ROW_HEIGHT + 5)))
        container.rowCount = count + 1
        return row
    end
    
    local y = -10
    local PAD = 10
    
    -- Section Header
    local mmHeader = GUI:CreateSectionHeader(content, "Minimap Datapanel Settings")
    mmHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - mmHeader.gap
    
    local mmContainer = CreateFrame("Frame", nil, content)
    mmContainer:SetPoint("TOPLEFT", PAD, y)
    mmContainer:SetWidth(GUI.CONTENT_WIDTH - 20)
    mmContainer.rowCount = 0
    
    AddRow(mmContainer, "Enable Panel", "checkbox", "enabled", mDT, refreshMinimap)
    AddRow(mmContainer, "Panel Height", "slider", 10, 60, "height", mDT, refreshMinimap, 1)
    AddRow(mmContainer, "Font Size", "slider", 8, 24, "fontSize", mDT, refreshMinimap, 1)
    
    AddRow(mmContainer, "Font Use Theme Color", "checkbox", "useThemeColor", mDT, refreshMinimap)
    if GUI.CreateColorPicker then
         AddRow(mmContainer, "Font Color", "color", "fontColor", mDT, refreshMinimap)
    end
    AddRow(mmContainer, "Background Opacity (%)", "slider", 0, 100, "bgOpacity", mDT, refreshMinimap, 5)
    
    AddRow(mmContainer, "Border Size", "slider", 0, 5, "borderSize", mDT, refreshMinimap, 1)
    AddRow(mmContainer, "Border Use Theme Color", "checkbox", "useThemeColorBorder", mDT, refreshMinimap)
    if GUI.CreateColorPicker then
        AddRow(mmContainer, "Border Color", "color", "borderColor", mDT, refreshMinimap)
    end
    
    -- Slots Options
    local dataOptions = {
        {value = "", text = "None"},
        {value = "time", text = "Time"},
        {value = "guild", text = "Guild"},
        {value = "friends", text = "Friends"},
        {value = "fps", text = "FPS"},
        {value = "ms", text = "MS"},
        {value = "gold", text = "Gold"},
        {value = "durability", text = "Durability"},
        {value = "bags", text = "Bags"},
        {value = "coords", text = "Coordinates"},
        {value = "spec", text = "Spec / Loot"},
    }

    if ns.Datatexts and ns.Datatexts.LDB_Objects then
        local ldbList = {}
        for name, _ in pairs(ns.Datatexts.LDB_Objects) do
            table.insert(ldbList, {value = "LDB:" .. name, text = "LDB: " .. name})
        end
        table.sort(ldbList, function(a, b) return a.text < b.text end)
        for _, item in ipairs(ldbList) do table.insert(dataOptions, item) end
    end
    
    mmContainer.rowCount = mmContainer.rowCount + 0.5 -- Spacer
    
    for i = 1, 3 do
        local key = "slot" .. i
        local cfg = mDT[key]
        if not cfg then mDT[key] = {content=""} cfg = mDT[key] end
        AddRow(mmContainer, "Slot " .. i, "dropdown", dataOptions, "content", cfg, refreshMinimap)
    end
    
    mmContainer:SetHeight(10 + (mmContainer.rowCount * (ROW_HEIGHT + 5)))
    y = y - mmContainer:GetHeight() - 10
    
    content:SetHeight(math.abs(y) + 50)
end

-- ═══════════════════════════════════════════════════════════════
-- BUILDER: CUSTOM PANELS (Tab 2)
-- ═══════════════════════════════════════════════════════════════
local function BuildCustomPanels(parent)
    local scroll, content = GUI:CreateScrollableContent(parent)
    scroll:SetAllPoints()

    local db = ns.GetDB()
    if not db then return end
    
    if not db.datapanels then db.datapanels = {} end
    if not db.datapanels.custom then db.datapanels.custom = {} end
    
    local refresh = ns.RefreshDatapanels or function() end
    
    local ROW_HEIGHT = 30
    local LABEL_WIDTH = 220
    local WIDGET_WIDTH = 250
    
    -- Duplicated Helpers for closure scope (simplest approach)
    local function CreatePropertyRow(container, labelText, widgetType, arg1, arg2, arg3, arg4, arg5, arg6)
        local row = CreateFrame("Frame", nil, container)
        row:SetSize(GUI.CONTENT_WIDTH - 70, ROW_HEIGHT)
        
        -- Label
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetFont(ns.FONT_PATH or "Interface/AddOns/GravityUI/assets/Gravity.ttf", 12, "")
        label:SetJustifyH("LEFT")
        label:SetSize(LABEL_WIDTH, ROW_HEIGHT)
        label:SetPoint("LEFT", 0, 0)
        label:SetText(labelText)
        label:SetTextColor(1, 1, 1, 1) -- Force White
        
        -- Widget
        local widget
        if widgetType == "checkbox" then
            widget = GUI:CreateCheckbox(row, "", arg1, arg2, arg3)
            widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
        elseif widgetType == "slider" then
            widget = GUI:CreateSlider(row, "", arg1, arg2, arg3, arg4, arg5, arg6)
            widget:SetHeight(ROW_HEIGHT)
            widget:SetWidth(220)
            widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
            
            widget.editBox:ClearAllPoints()
            widget.editBox:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
            widget.slider:ClearAllPoints()
            widget.slider:SetPoint("LEFT", widget, "LEFT", 0, 0)
            widget.slider:SetPoint("RIGHT", widget.editBox, "LEFT", -10, 0)
        elseif widgetType == "dropdown" then
            widget = GUI:CreateDropdown(row, "", arg1, arg2, arg3, arg4)
            widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
            widget:SetWidth(WIDGET_WIDTH)
            widget.dropdown:ClearAllPoints()
            widget.dropdown:SetPoint("LEFT", widget, "LEFT", 0, 0)
            widget.dropdown:SetPoint("RIGHT", widget, "RIGHT", 0, 0)
        elseif widgetType == "color" then
             widget = GUI:CreateColorPicker(row, "", arg1, arg2, arg3)
             widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
        elseif widgetType == "input" then
            widget = GUI:CreateInput(row, "", arg1, arg2, arg3)
            widget:SetPoint("LEFT", label, "RIGHT", 10, 0)
            widget:SetWidth(WIDGET_WIDTH)
            widget.editBox:SetWidth(WIDGET_WIDTH)
        end
        
        if ns.GUI and ns.GUI.RegisterInSearchIndex then
            ns.GUI:RegisterInSearchIndex(labelText, row)
        end
        
        return row
    end
    
    local y = -10
    local PAD = 10
    content._hasContent = false
    
    -- Logic for Custom List
    local editingID = nil
    
    -- Need to rebuild slots options locally as well
    local dataOptions = {
        {value = "", text = "None"},
        {value = "time", text = "Time"},
        {value = "guild", text = "Guild"},
        {value = "friends", text = "Friends"},
        {value = "fps", text = "FPS"},
        {value = "ms", text = "MS"},
        {value = "gold", text = "Gold"},
        {value = "durability", text = "Durability"},
        {value = "bags", text = "Bags"},
        {value = "coords", text = "Coordinates"},
        {value = "spec", text = "Spec / Loot"},
    }
    if ns.Datatexts and ns.Datatexts.LDB_Objects then
        local ldbList = {}
        for name, _ in pairs(ns.Datatexts.LDB_Objects) do
            table.insert(ldbList, {value = "LDB:" .. name, text = "LDB: " .. name})
        end
        table.sort(ldbList, function(a, b) return a.text < b.text end)
        for _, item in ipairs(ldbList) do table.insert(dataOptions, item) end
    end

    local function BuildCustomList()
        -- clear content
        local children = { content:GetChildren() }
        for _, child in ipairs(children) do 
            if child ~= scroll then child:Hide(); child:SetParent(nil) end 
        end
        content.rowCount = 0
        
        -- Header & Info
        local customHeader = GUI:CreateSectionHeader(content, "Custom Movable Panels")
        customHeader:SetPoint("TOPLEFT", PAD, -10)
        content.rowCount = 1.2
        
        local infoBox = GUI:CreateInfoBox(content, 
            "|cff00BFFFInfo:|r Create additional datatext panels that can be freely positioned anywhere on screen.\n" ..
            "|cffFFCC00Note:|r Panels only appear if at least one slot has a datatext assigned.")
        infoBox:SetPoint("TOPLEFT", PAD, -10 - (content.rowCount * 35))
        content.rowCount = content.rowCount + 2.5
        
        -- List
        local sortedKeys = {}
        for k in pairs(db.datapanels.custom or {}) do table.insert(sortedKeys, k) end
        table.sort(sortedKeys)

        for _, id in ipairs(sortedKeys) do
            local cfg = db.datapanels.custom[id]
            local isEditing = (editingID == id)
            
            local editorHeight = 70
            if isEditing then
                editorHeight = 70 + 35 + (6 * 32) + 30 + 32 + 32 + 32 
                + (not cfg.useThemeColor and 32 or 0) + 32 + 32 
                + (not cfg.useThemeColorBorder and 32 or 0) + 32 + 32 + 30 
                + ((cfg.numSlots or 3) * 32) + 20
            end

            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetSize(GUI.CONTENT_WIDTH - 50, editorHeight)
            row:SetPoint("TOPLEFT", PAD, -10 - (content.rowCount * 35))
            ns.GUI:CreateBackdrop(row, {0.1, 0.1, 0.1, 0.5}, isEditing and {0, 0.75, 1, 1} or {0.3, 0.3, 0.3, 1})
            
            -- Title
            local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            name:SetFont(ns.FONT_PATH or "Interface/AddOns/GravityUI/assets/Gravity.ttf", 16, "")
            name:SetText(cfg.name or id)
            name:SetPoint("TOPLEFT", 15, -12)
            name:SetTextColor(unpack(GUI.Colors.accent))

            local slotsText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            slotsText:SetFont(ns.FONT_PATH or "Interface/AddOns/GravityUI/assets/Gravity.ttf", 11, "")
            slotsText:SetText((cfg.numSlots or 3) .. " slots assigned")
            slotsText:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)

            -- Buttons
            local delete = GUI:CreateButton(row, "Delete", 80, 24, function()
                db.datapanels.custom[id] = nil
                refresh()
                BuildCustomList()
            end)
            delete:SetPoint("TOPRIGHT", -10, -10)

            local edit = GUI:CreateButton(row, isEditing and "Close" or "Edit", 80, 24, function()
                if isEditing then editingID = nil else editingID = id end
                BuildCustomList()
            end)
            edit:SetPoint("RIGHT", delete, "LEFT", -5, 0)

            local enabled = GUI:CreateCheckbox(row, "Enabled", "enabled", cfg, refresh)
            enabled:SetPoint("RIGHT", edit, "LEFT", -20, 0)
            
            if isEditing then
                local editor = CreateFrame("Frame", nil, row)
                editor:SetPoint("TOPLEFT", 0, -65)
                editor:SetPoint("BOTTOMRIGHT", 0, 0)
                editor.rowCount = 0
                
                local function AddEditorRow(label, type, ...)
                    local r = CreatePropertyRow(editor, label, type, ...)
                    r:SetPoint("TOPLEFT", 15, -10 - (editor.rowCount * 32))
                    editor.rowCount = editor.rowCount + 1
                end
                
                local function AddHeader(text)
                    local h = editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    h:SetText(text)
                    h:SetTextColor(0, 0.75, 1)
                    h:SetPoint("TOPLEFT", 15, -12 - (editor.rowCount * 32))
                    editor.rowCount = editor.rowCount + 0.95
                end
                
                local wrapRefresh = function() refresh(); BuildCustomList() end
                
                AddHeader("Panel Positioning & Size")
                AddEditorRow("Panel Name", "input", "name", cfg, wrapRefresh)
                AddEditorRow("Locked / Draggable", "checkbox", "locked", cfg, refresh)
                AddEditorRow("Height", "slider", 10, 100, "height", cfg, refresh, 1)
                AddEditorRow("Width", "slider", 50, 1000, "width", cfg, refresh, 5)
                AddEditorRow("X Position", "slider", -1000, 1000, "x", cfg, refresh, 1)
                AddEditorRow("Y Position", "slider", -1000, 1000, "y", cfg, refresh, 1)
                
                AddHeader("Styling & Colors")
                AddEditorRow("Hide Labels", "checkbox", "hideLabel", cfg, refresh)
                AddEditorRow("Font Size", "slider", 8, 32, "fontSize", cfg, refresh, 1)
                AddEditorRow("Font Use Theme (Class) Color", "checkbox", "useThemeColor", cfg, wrapRefresh)
                if not cfg.useThemeColor then
                    AddEditorRow("Font Color", "color", "fontColor", cfg, refresh)
                end
                
                AddEditorRow("Border Size", "slider", 0, 10, "borderSize", cfg, refresh, 1)
                AddEditorRow("Border Use Theme (Class) Color", "checkbox", "useThemeColorBorder", cfg, wrapRefresh)
                if not cfg.useThemeColorBorder then
                    AddEditorRow("Border Color", "color", "borderColor", cfg, refresh)
                end
                AddEditorRow("Background Opacity (%)", "slider", 0, 100, "bgOpacity", cfg, refresh, 1)
                
                AddHeader("Content (Slots)")
                AddEditorRow("Amount of Slots", "slider", 1, 5, "numSlots", cfg, wrapRefresh, 1)
                for i = 1, (cfg.numSlots or 3) do
                    if not cfg.slots[i] then cfg.slots[i] = {content=""} end
                    AddEditorRow("Slot " .. i, "dropdown", dataOptions, "content", cfg.slots[i], refresh)
                end
                
                content.rowCount = content.rowCount + (editorHeight / 35)
            else
                content.rowCount = content.rowCount + 2.2
            end
        end
        
        -- Add Button
        local add = GUI:CreateButton(content, "Add Panel", 120, 30, function()
            local newId = "Panel " .. (ns.TableCount(db.datapanels.custom) + 1)
            db.datapanels.custom[newId] = {
                enabled = true, name = newId, width = 200, height = 24, bgOpacity = 60,
                locked = true, fontSize = 12, borderSize = 1,
                point = "CENTER", relativePoint = "CENTER", x = 0, y = 0,
                numSlots = 3,
                slots = { [1] = {content=""}, [2] = {content=""}, [3] = {content=""} }
            }
            refresh()
            BuildCustomList()
        end)
        add:SetPoint("TOPLEFT", PAD, -10 - (content.rowCount * 35))
        content.rowCount = content.rowCount + 2.0
        
        -- Final Height
        content:SetHeight(math.max(800, 50 + (content.rowCount * 35)))
    end
    
    BuildCustomList()
end


ns.GUI:RegisterPage("datapanels", {
    title = "Datapanels",
    OnBuild = function(content)
        -- Hide default scrollframe parent
        local scrollFrame = content:GetParent()
        content:Hide()
        
        if scrollFrame.ScrollBar then
            scrollFrame.ScrollBar:Hide()
            scrollFrame.ScrollBar:HookScript("OnShow", function(self) self:Hide() end)
        end
        
        -- Create SubTabs
        local subTabs = GUI:CreateSubTabs(scrollFrame, {
            { name = "Minimap Datapanel Settings", builder = BuildMinimapPanel },
            { name = "Custom Panels", builder = BuildCustomPanels },
        })
        subTabs:SetPoint("TOPLEFT", 10, -10)
        subTabs:SetPoint("TOPRIGHT", -10, 0)
    end,
})
