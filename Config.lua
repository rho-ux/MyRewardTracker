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

MRT.Config.ExpansionMapping = MRT.Config.ExpansionMapping or {
    FollowerTypeToExpansion = {
        [1] = "wod",
        [4] = "legion",
        [22] = "bfa",
        [123] = "sl",
    }
}

MRT.Config.UI = MRT.Config.UI or {
    DashboardShowSortDebug = true,
}

MRT.Config.Labels = MRT.Config.Labels or {}
MRT.Config.Labels.Expansion = MRT.Config.Labels.Expansion or {
    wod = "WOD",
    legion = "LEGION",
    bfa = "BFA",
    sl = "SCHATTENLANDE",
    df = "DRAGONFLIGHT",
    tww = "THE WAR WITHIN",
    unknown = "UNBEKANNT",
}

MRT.Config.Labels.Reward = MRT.Config.Labels.Reward or {
    item = "GEGENSTAENDE",
    currency = "WAEHRUNG",
    gold = "GOLD",
    other = "SONSTIGES",
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

function MRT.Config:GetExpansionKeyByFollowerType(followerTypeID)
    if not followerTypeID then
        return "unknown"
    end

    local map = self.ExpansionMapping and self.ExpansionMapping.FollowerTypeToExpansion
    if not map then
        return "unknown"
    end

    return map[followerTypeID] or "unknown"
end

function MRT.Config:GetMissionRewardKey(mission)
    if not mission or not mission.rewards then
        return "other"
    end

    local hasItem = false
    local hasCurrency = false
    local hasGold = false

    for _, reward in ipairs(mission.rewards) do
        if reward.itemID then
            hasItem = true
        elseif reward.currencyID == 0 then
            hasGold = true
        elseif reward.currencyID then
            hasCurrency = true
        end
    end

    if hasItem then
        return "item"
    end
    if hasCurrency then
        return "currency"
    end
    if hasGold then
        return "gold"
    end

    return "other"
end

function MRT.Config:GetMissionState(mission)
    if not mission then
        return "available"
    end

    if mission.completed then
        return "ready"
    end

    if mission.inProgress then
        if mission.timeLeftSeconds and mission.timeLeftSeconds == 0 then
            return "ready"
        end
        return "running"
    end

    return "available"
end

function MRT.Config:GetDashboardConfig()
    local fallback = true
    if self.UI and type(self.UI.DashboardShowSortDebug) == "boolean" then
        fallback = self.UI.DashboardShowSortDebug
    end

    MyRewardTrackerDB = MyRewardTrackerDB or {}
    MyRewardTrackerDB.account = MyRewardTrackerDB.account or {}
    MyRewardTrackerDB.account.dashboardConfig = MyRewardTrackerDB.account.dashboardConfig or {}

    local cfg = MyRewardTrackerDB.account.dashboardConfig
    if type(cfg.showSortDebug) ~= "boolean" then
        cfg.showSortDebug = fallback
    end
    if type(cfg.showExpansionHeaders) ~= "boolean" then
        cfg.showExpansionHeaders = true
    end
    if type(cfg.showRewardHeaders) ~= "boolean" then
        cfg.showRewardHeaders = true
    end
    if type(cfg.showStatusColors) ~= "boolean" then
        cfg.showStatusColors = true
    end
    if type(cfg.showRewardDetails) ~= "boolean" then
        cfg.showRewardDetails = true
    end
    if type(cfg.compactList) ~= "boolean" then
        cfg.compactList = false
    end
    if type(cfg.fontSize) ~= "number" then
        cfg.fontSize = 13
    end
    if cfg.fontSize < 10 then
        cfg.fontSize = 10
    end
    if cfg.fontSize > 20 then
        cfg.fontSize = 20
    end

    return cfg
end

function MRT.Config:IsDashboardSortDebugEnabled()
    local cfg = self:GetDashboardConfig()
    return cfg.showSortDebug
end
