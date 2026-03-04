local addonName, MRT = ...

MRT.Config = MRT.Config or {}

-- Placeholder für spätere Filterwerte
MRT.Config.MinGold = 0
MRT.Config.ItemIDs = {}
MRT.Config.CurrencyFilters = {}

MRT.Config.Sorting = MRT.Config.Sorting or {
    ExpansionOrder = { "wod", "legion", "bfa", "sl", "df", "tww", "unknown" },
    RewardOrder = { "item", "currency", "gold", "other" },
}

MRT.Config.UI = MRT.Config.UI or {
    DashboardShowSortDebug = true,
}

local function BuildOrderIndex(orderList)
    local index = {}
    if type(orderList) ~= "table" then
        return index
    end

    for i, key in ipairs(orderList) do
        index[key] = i
    end

    return index
end

MRT.Config.Sorting.ExpansionIndex = BuildOrderIndex(MRT.Config.Sorting.ExpansionOrder)
MRT.Config.Sorting.RewardIndex = BuildOrderIndex(MRT.Config.Sorting.RewardOrder)

function MRT.Config:GetExpansionSortIndex(expansionKey)
    local idx = self.Sorting.ExpansionIndex[expansionKey]
    if idx then
        return idx
    end
    return self.Sorting.ExpansionIndex.unknown or 9999
end

function MRT.Config:GetRewardSortIndex(rewardKey)
    local idx = self.Sorting.RewardIndex[rewardKey]
    if idx then
        return idx
    end
    return self.Sorting.RewardIndex.other or 9999
end
