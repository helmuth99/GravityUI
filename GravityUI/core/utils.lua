-- GravityUI Utility Functions
local ADDON_NAME, ns = ...

-- Pixel perfect scaling helper
function ns.Scale(value)
    local scale = UIParent:GetEffectiveScale()
    return value / scale
end

-- Round number to specified decimal places
function ns.Round(number, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(number * mult + 0.5) / mult
end

-- Format large numbers with K/M suffixes
function ns.FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Format gold amount
function ns.FormatGold(copper)
    if not copper or copper == 0 then return "0|cFFFFD700g|r" end
    
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local bronze = copper % 100
    
    local str = ""
    if gold > 0 then
        str = str .. gold .. "|cFFFFD700g|r "
    end
    if silver > 0 then
        str = str .. silver .. "|cFFC7C7CFs|r "
    end
    if bronze > 0 or str == "" then
        str = str .. bronze .. "|cFFCD7F32c|r"
    end
    
    return str:trim()
end

-- Get player coordinates
function ns.GetPlayerCoords()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return 0, 0 end
    
    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then return 0, 0 end
    
    local x, y = position:GetXY()
    return ns.Round(x * 100, 1), ns.Round(y * 100, 1)
end

-- Get current zone name
function ns.GetZoneName()
    return GetZoneText() or GetRealZoneText() or "Unknown"
end

-- Get current subzone name
function ns.GetSubZoneName()
    return GetSubZoneText() or ""
end

-- Get player spec name
function ns.GetSpecName()
    local specIndex = GetSpecialization()
    if not specIndex then return "No Spec" end
    
    local _, name = GetSpecializationInfo(specIndex)
    return name or "Unknown"
end

-- Get FPS (frames per second)
function ns.GetFPS()
    return ns.Round(GetFramerate(), 0)
end

-- Get latency (home and world)
function ns.GetLatency()
    local _, _, home, world = GetNetStats()
    return home or 0, world or 0
end

-- Get total durability percentage
function ns.GetDurability()
    local total, current = 0, 0
    
    for i = 1, 18 do
        local durCur, durMax = GetInventoryItemDurability(i)
        if durCur and durMax then
            total = total + durMax
            current = current + durCur
        end
    end
    
    if total == 0 then return 100 end
    return ns.Round((current / total) * 100, 0)
end

-- Color text by value (red to green gradient)
function ns.ColorByValue(value, max, text)
    local percent = value / max
    local r, g
    
    if percent > 0.5 then
        r = (1 - percent) * 2
        g = 1
    else
        r = 1
        g = percent * 2
    end
    
    return string.format("|cFF%02x%02x%02x%s|r", r * 255, g * 255, 0, text)
end

-- Deep copy table
function ns.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[ns.DeepCopy(orig_key)] = ns.DeepCopy(orig_value)
        end
        setmetatable(copy, ns.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Merge tables (overwrites target with source values)
function ns.MergeTables(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            ns.MergeTables(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end
-- Count elements in a table
function ns.TableCount(tbl)
    if not tbl then return 0 end
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end
