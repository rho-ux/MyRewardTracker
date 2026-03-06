local addonName, MRT = ...

MRT.MultiDebugUtils = MRT.MultiDebugUtils or {}
local Utils = MRT.MultiDebugUtils

function Utils.FormatMoney(copper)
    local value = tonumber(copper) or 0
    if value < 0 then
        value = 0
    end
    local gold = math.floor(value / 10000)
    local silver = math.floor((value % 10000) / 100)
    local bronze = value % 100
    return string.format(
        "%d|cffffd100g|r %d|cffffffffs|r %d|cffb87333c|r",
        gold,
        silver,
        bronze
    )
end

function Utils.GetExpansionLabel(expansionKey)
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Expansion then
        local label = MRT.Config.Labels.Expansion[expansionKey]
        if label and label ~= "" then
            return label
        end
    end
    return string.upper(expansionKey or "unknown")
end

function Utils.GetStateLabel(state)
    if state == "ready" then
        return "fertig"
    end
    if state == "running" then
        return "laeuft"
    end
    return "verfuegbar"
end

function Utils.GetStateSort(state)
    if state == "available" then return 1 end
    if state == "running" then return 2 end
    if state == "ready" then return 3 end
    return 99
end

function Utils.BuildGroupData(mission)
    local data = {
        gold = 0,
        currencies = {},
        items = {},
        animaItems = {},
    }
    if not mission or type(mission.rewards) ~= "table" then
        return data
    end

    for _, reward in ipairs(mission.rewards) do
        local qty = tonumber(reward.quantity) or 0
        if reward.currencyID == 0 then
            data.gold = data.gold + qty
        elseif reward.currencyID then
            data.currencies[#data.currencies + 1] = {
                currencyID = reward.currencyID,
                quantity = qty,
            }
        elseif reward.itemID then
            local isAnima = MRT.Config and MRT.Config.IsAnimaItem and MRT.Config:IsAnimaItem(reward.itemID)
            local target = isAnima and data.animaItems or data.items
            target[#target + 1] = {
                itemID = reward.itemID,
                quantity = qty,
            }
        end
    end

    return data
end

function Utils.GetPrimaryGroupKey(groupInfo)
    if #groupInfo.animaItems > 0 then
        return "anima"
    end
    if #groupInfo.items > 0 then
        return "items"
    end
    if #groupInfo.currencies > 0 then
        return "currency"
    end
    if (groupInfo.gold or 0) > 0 then
        return "gold"
    end
    return nil
end

function Utils.BuildGroupText(groupKey, info)
    if groupKey == "gold" then
        return Utils.FormatMoney(info.gold or 0)
    end
    if groupKey == "currency" then
        local parts = {}
        for _, c in ipairs(info.currencies or {}) do
            local iconText = ""
            local cfg = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(c.currencyID)
            if cfg and cfg.iconFileID then
                iconText = "|T" .. tostring(cfg.iconFileID) .. ":14:14:0:0|t "
            end
            parts[#parts + 1] = iconText .. "x" .. tostring(c.quantity or 0)
        end
        return table.concat(parts, ", ")
    end

    local src = groupKey == "anima" and info.animaItems or info.items
    local parts = {}
    for _, it in ipairs(src or {}) do
        local icon = nil
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(it.itemID)
        if not texture and C_Item and C_Item.GetItemInfoInstant then
            local _, _, _, _, _, _, _, _, _, instantTexture = C_Item.GetItemInfoInstant(it.itemID)
            texture = instantTexture
        end
        if texture then
            icon = "|T" .. tostring(texture) .. ":14:14:0:0|t "
        else
            icon = ""
        end
        parts[#parts + 1] = icon .. "x" .. tostring(it.quantity or 0)
    end
    return table.concat(parts, ", ")
end

function Utils.BuildGroupTooltip(groupKey, info)
    local payload = { lines = {} }

    if groupKey == "gold" then
        payload.lines[#payload.lines + 1] = "Gold " .. Utils.FormatMoney(info.gold or 0)
        return payload
    end

    if groupKey == "currency" then
        local first = nil
        for _, c in ipairs(info.currencies or {}) do
            local name = "Currency:" .. tostring(c.currencyID)
            local cfg = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(c.currencyID)
            if cfg and cfg.name and cfg.name ~= "" then
                name = cfg.name
            end
            payload.lines[#payload.lines + 1] = name .. " x" .. tostring(c.quantity or 0)
            if not first then
                first = c
            end
        end
        if first then
            payload.currencyID = first.currencyID
            payload.quantity = first.quantity or 0
            return payload
        end
        return nil
    end

    local src = (groupKey == "anima") and (info.animaItems or {}) or (info.items or {})
    local firstItemID = nil
    for _, it in ipairs(src) do
        local itemID = it.itemID
        local label = "Item:" .. tostring(itemID)
        local link = select(2, GetItemInfo(itemID))
        if link and link ~= "" then
            label = link
        end
        payload.lines[#payload.lines + 1] = label .. " x" .. tostring(it.quantity or 0)
        if not firstItemID then
            firstItemID = itemID
            payload.itemID = itemID
            if link and link ~= "" then
                payload.itemLink = link
            end
        end
    end
    if firstItemID then
        return payload
    end

    return nil
end

function Utils.BuildGroupSearchText(groupKey, info)
    if groupKey == "gold" then
        return "gold " .. tostring(info.gold or 0)
    end

    if groupKey == "currency" then
        local parts = {}
        for _, c in ipairs(info.currencies or {}) do
            local name = "currency:" .. tostring(c.currencyID)
            local cfg = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(c.currencyID)
            if cfg and cfg.name and cfg.name ~= "" then
                name = cfg.name
            end
            parts[#parts + 1] = name .. " " .. tostring(c.quantity or 0)
        end
        return table.concat(parts, " ")
    end

    local src = (groupKey == "anima") and (info.animaItems or {}) or (info.items or {})
    local parts = {}
    for _, it in ipairs(src) do
        local itemID = it.itemID
        local name = "item:" .. tostring(itemID)
        local itemName = GetItemInfo(itemID)
        if itemName and itemName ~= "" then
            name = itemName
        end
        parts[#parts + 1] = name .. " " .. tostring(it.quantity or 0)
    end
    return table.concat(parts, " ")
end

function Utils.GetSortedTrackedKeys(trackedRoot)
    local keys = {}
    for charKey in pairs(trackedRoot) do
        keys[#keys + 1] = charKey
    end

    table.sort(keys, function(a, b)
        local aSort = MRT.Config and MRT.Config.GetCharacterSortIndex and MRT.Config:GetCharacterSortIndex(a) or 9999
        local bSort = MRT.Config and MRT.Config.GetCharacterSortIndex and MRT.Config:GetCharacterSortIndex(b) or 9999
        if aSort ~= bSort then
            return aSort < bSort
        end
        return a < b
    end)

    return keys
end
