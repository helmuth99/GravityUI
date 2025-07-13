local addon, private = ...

--todo implement private.GetWeakauraString in Weakauradump

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerializer = LibStub("LibSerialize")
local AceGUI = LibStub("AceGUI-3.0")
local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')


---@param importString string
---@return table
function private:decodeWAPacket(importString)
    local _, _, encodeVersion, encoded = importString:find("^(!WA:%d+!)(.+)$")
    if encodeVersion then
        encodeVersion = tonumber(encodeVersion:match("%d+"))
    else
        encoded, encodeVersion = importString:gsub("^%!", "")
    end
    if encoded then
        local decoded = LibDeflate:DecodeForPrint(encoded)
        local decompressed = LibDeflate:DecompressDeflate(decoded or "")
        local deserialized
        if encodeVersion == 2 then
            _, deserialized = LibSerializer:Deserialize(decompressed)
        else
            error("Incompatible WA Import String")
        end
        return deserialized
    end
    return {}
end

---@param WATable table
---@return table
local function CreateEntry(WATable)
    if not WATable.d then
        return {}
    end


    local entry = CreateFrame("Frame")

    -- Name Text
    local nameFrame = CreateFrame("Frame", nil, entry)
    nameFrame:SetSize(185, 20)
    nameFrame:SetPoint("LEFT", entry, "LEFT", 10, 0)

    local name = nameFrame:CreateFontString(nil, "OVERLAY")
    name:SetFontObject("GameFontNormal")
    name:SetPoint("LEFT", nameFrame, "LEFT")
    name:SetText(WATable.d.id or "Unknown")
    name:SetTextColor(255, 255, 255, 1)

    -- Version Text
    local version = entry:CreateFontString(nil, "OVERLAY")
    version:SetFontObject("GameFontNormal")
    version:SetPoint("LEFT", nameFrame, "RIGHT", 25, 0)
    version:SetText(WATable.d.semver or "1.0")
    version:SetTextColor(255, 255, 255, 1)

    -- Import Button
    local importBtn = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
    importBtn:SetSize(100, 20)
    importBtn:SetPoint("RIGHT", entry, "RIGHT", -50, 0)
    importBtn:SetText("Import")
    importBtn:SetNormalFontObject("GameFontHighlight")
    importBtn:SetScript("OnClick", function()
        WeakAuras.Import(WATable, nil, function()
            importBtn:SetText("Imported")
            importBtn:SetBackdropColor(0.216, 0.714, 1, 1)
        end)
    end)
    S:HandleButton(importBtn)

    return entry
end

local FrameBackdrop = {
    bgFile = "Interface\\LevelUp\\LevelUpTex",
    edgeFile = "",
    tile = false,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
}

local function Button_OnClick(frame)
    PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
    frame:GetParent():Hide()
end

function private:CreateWeakauraFrame()
    if _G.CronixUIWeakauraFrame then
        _G.CronixUIWeakauraFrame:Show()
        return
    end
    local frame = CreateFrame("Frame", "CronixUIWeakauraFrame", _G.PluginInstallFrame, "BackdropTemplate")

    --local frame = CreateFrame("Frame", "CronixUIWeakauraFrame", _G.PluginInstallFrame)



    frame:SetPoint("RIGHT", _G.PluginInstallFrame, "LEFT", 0, 0)
    frame:SetHeight(_G.PluginInstallFrame:GetHeight())
    frame:SetWidth(500)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(10)
    frame:SetTemplate('Transparent')

    local titleFrame = CreateFrame("Frame", nil, frame)
    titleFrame:SetPoint("TOP", frame, "TOP", 0, -20)
    titleFrame:SetSize(frame:GetWidth(), 30)

    local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closebutton:SetScript("OnClick", Button_OnClick)
    closebutton:SetPoint("BOTTOMRIGHT", -27, 17)
    closebutton:SetHeight(20)
    closebutton:SetWidth(100)
    closebutton:SetText(CLOSE)
    closebutton:SetNormalFontObject("GameFontHighlight")
    S:HandleButton(closebutton)


    local title = titleFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16)
    title:SetPoint("CENTER", titleFrame, "CENTER")
    title:SetText("Weakauras")


    -- Headers
    local headers = {
        { text = "Name",    width = 200 },
        { text = "Version", width = 60 },
        { text = "Import",  width = 100 }
    }

    local headerFrame = CreateFrame("Frame", nil, frame)
    headerFrame:SetPoint("TOP", title, "BOTTOM", 0, -20)
    headerFrame:SetSize(frame:GetWidth() - 40, 25)

    local xOffset = 10
    for i, header in ipairs(headers) do
        local text = headerFrame:CreateFontString(nil, "OVERLAY")
        text:SetFontObject("GameFontNormal")
        text:SetPoint("LEFT", headerFrame, "LEFT", xOffset, 0)
        text:SetText(header.text)
        text:SetTextColor(255, 255, 255, 1)
        xOffset = xOffset + header.width + 10
    end

    -- Create a scrollframe to contain the entries
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 50)
    scrollFrame:SetHeight(400)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth() - 10, 400) -- Height will adjust based on content

    -- Function to create entries will be called here in the loop below
    local yOffset = 0
    local entryHeight = 30

    -- This will be populated in the loop below
    local entries = {}
    local WAString = private:GetWeakauraString();

    for i, v in ipairs(WAString) do
        local WaTable = private:decodeWAPacket(v)
        local entry = CreateEntry(WaTable)
        entry:SetSize(scrollChild:GetWidth(), entryHeight)
        entry:SetParent(scrollChild)
        entry:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)

        table.insert(entries, entry)
        yOffset = yOffset + entryHeight + 5
    end

    scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))


    return frame
end
