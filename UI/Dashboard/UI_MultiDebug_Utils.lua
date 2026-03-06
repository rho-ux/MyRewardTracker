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
    return string.format("%dg %ds %dc", gold, silver, bronze)
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
            local name = "Currency:" .. tostring(c.currencyID)
            local cfg = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(c.currencyID)
            if cfg and cfg.name and cfg.name ~= "" then
                name = cfg.name
            end
            parts[#parts + 1] = name .. " x" .. tostring(c.quantity or 0)
        end
        return table.concat(parts, ", ")
    end

    local src = groupKey == "anima" and info.animaItems or info.items
    local parts = {}
    for _, it in ipairs(src or {}) do
        local label = "Item:" .. tostring(it.itemID)
        local link = select(2, GetItemInfo(it.itemID))
        if link and link ~= "" then
            label = link
        end
        parts[#parts + 1] = label .. " x" .. tostring(it.quantity or 0)
    end
    return table.concat(parts, ", ")
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
