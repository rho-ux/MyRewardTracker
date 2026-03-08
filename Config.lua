local addonName, MRT = ...

MRT.Config = MRT.Config or {}

-- Placeholder für spätere Filterwerte
MRT.Config.MinGold = 0
MRT.Config.ItemIDs = {}
MRT.Config.CurrencyFilters = {}

MRT.Config.Sorting = MRT.Config.Sorting or {
    ExpansionOrder = { "wod", "legion", "bfa", "sl", "df", "tww", "unknown" },
    RewardOrder = { "anima", "item", "currency", "gold", "other" },
    CharacterOrder = {
        "Gehkel-Khaz'goroth",
        "Tildal-Blackhand",
        "Nathi-Khaz'goroth",
        "Toma-Khaz'goroth",
    },
    UnknownCharsAtBottom = true,
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
    sl = "SL",
    df = "DF",
    tww = "TWW",
    unknown = "UNBEKANNT",
}

MRT.Config.Labels.Reward = MRT.Config.Labels.Reward or {
    anima = "ANIMA",
    item = "ITEM",
    currency = "WÄHRUNG",
    gold = "GOLD",
    other = "SONSTIGES",
}

MRT.Config.Anima = MRT.Config.Anima or {
    -- Anima-Itemwerte (itemID -> anima pro Stueck)
    ItemValues = {
        [181548] = 35,
        [184775] = 35,
    },
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
MRT.Config.Sorting.CharacterIndex = BuildOrderIndex(MRT.Config.Sorting.CharacterOrder)

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

function MRT.Config:GetCharacterSortIndex(charKey)
    local idx = self.Sorting.CharacterIndex[charKey]
    if idx then
        return idx
    end
    local unknownAtBottom = true
    if self.Sorting and type(self.Sorting.UnknownCharsAtBottom) == "boolean" then
        unknownAtBottom = self.Sorting.UnknownCharsAtBottom
    end
    if unknownAtBottom then
        return 9999
    end
    return -1
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

    local hasAnima = false
    local hasItem = false
    local hasCurrency = false
    local hasGold = false

    for _, reward in ipairs(mission.rewards) do
        if reward.itemID then
            if self.IsAnimaItem and self:IsAnimaItem(reward.itemID) then
                hasAnima = true
            else
                hasItem = true
            end
        elseif reward.currencyID == 0 then
            hasGold = true
        elseif reward.currencyID then
            hasCurrency = true
        end
    end

    if hasAnima then
        return "anima"
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

function MRT.Config:IsAnimaItem(itemID)
    if not itemID then
        return false
    end
    local values = self.Anima and self.Anima.ItemValues
    if type(values) ~= "table" then
        return false
    end
    return values[itemID] ~= nil
end

function MRT.Config:GetAnimaValue(itemID)
    if not itemID then
        return 0
    end
    local values = self.Anima and self.Anima.ItemValues
    if type(values) ~= "table" then
        return 0
    end
    local value = tonumber(values[itemID])
    if not value or value < 0 then
        return 0
    end
    return value
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
    if type(cfg.debugForceRemaining) ~= "boolean" then
        cfg.debugForceRemaining = false
    end
    if type(cfg.showGroupGold) ~= "boolean" then
        cfg.showGroupGold = true
    end
    if type(cfg.showGroupCurrency) ~= "boolean" then
        cfg.showGroupCurrency = true
    end
    if type(cfg.showGroupItems) ~= "boolean" then
        cfg.showGroupItems = true
    end
    if type(cfg.showGroupAnima) ~= "boolean" then
        cfg.showGroupAnima = true
    end
    if type(cfg.multiShowGold) ~= "boolean" then
        cfg.multiShowGold = true
    end
    if type(cfg.multiShowCurrency) ~= "boolean" then
        cfg.multiShowCurrency = true
    end
    if type(cfg.multiShowItems) ~= "boolean" then
        cfg.multiShowItems = true
    end
    if type(cfg.multiShowAnima) ~= "boolean" then
        cfg.multiShowAnima = true
    end
    if type(cfg.multiDetailLong) ~= "boolean" then
        cfg.multiDetailLong = true
    end
    if type(cfg.lineHeight) ~= "number" then
        cfg.lineHeight = 18
    end
    if cfg.lineHeight < 16 then
        cfg.lineHeight = 16
    end
    if cfg.lineHeight > 28 then
        cfg.lineHeight = 28
    end
    if type(cfg.headerStyle) ~= "string" then
        cfg.headerStyle = "normal"
    end
    if cfg.headerStyle ~= "normal" and cfg.headerStyle ~= "emphasis" then
        cfg.headerStyle = "normal"
    end
    if type(cfg.splitRatio) ~= "number" then
        cfg.splitRatio = 50
    end
    if cfg.splitRatio < 35 then
        cfg.splitRatio = 35
    end
    if cfg.splitRatio > 65 then
        cfg.splitRatio = 65
    end
    if type(cfg.showMissionHighlight) ~= "boolean" then
        cfg.showMissionHighlight = true
    end
    if type(cfg.highlightItemIDs) ~= "table" then
        cfg.highlightItemIDs = {}
    end
    if type(cfg.highlightCurrencyIDs) ~= "table" then
        cfg.highlightCurrencyIDs = {}
    end
    if type(cfg.highlightMissionIDs) ~= "table" then
        cfg.highlightMissionIDs = {}
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

function MRT.Config:GetMultiDashboardConfig()
    MyRewardTrackerDB = MyRewardTrackerDB or {}
    MyRewardTrackerDB.account = MyRewardTrackerDB.account or {}
    MyRewardTrackerDB.account.multiDashboardConfig = MyRewardTrackerDB.account.multiDashboardConfig or {}

    local cfg = MyRewardTrackerDB.account.multiDashboardConfig
    local old = MyRewardTrackerDB.account.dashboardConfig or {}

    if type(cfg.multiShowGold) ~= "boolean" then
        if type(old.multiShowGold) == "boolean" then
            cfg.multiShowGold = old.multiShowGold
        else
            cfg.multiShowGold = true
        end
    end
    if type(cfg.multiShowCurrency) ~= "boolean" then
        if type(old.multiShowCurrency) == "boolean" then
            cfg.multiShowCurrency = old.multiShowCurrency
        else
            cfg.multiShowCurrency = true
        end
    end
    if type(cfg.multiShowItems) ~= "boolean" then
        if type(old.multiShowItems) == "boolean" then
            cfg.multiShowItems = old.multiShowItems
        else
            cfg.multiShowItems = true
        end
    end
    if type(cfg.multiShowAnima) ~= "boolean" then
        if type(old.multiShowAnima) == "boolean" then
            cfg.multiShowAnima = old.multiShowAnima
        else
            cfg.multiShowAnima = true
        end
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
    if type(cfg.showMissionHighlight) ~= "boolean" then
        if type(old.showMissionHighlight) == "boolean" then
            cfg.showMissionHighlight = old.showMissionHighlight
        else
            cfg.showMissionHighlight = true
        end
    end
    if type(cfg.fontSize) ~= "number" then
        cfg.fontSize = tonumber(old.fontSize) or 13
    end
    if cfg.fontSize < 10 then cfg.fontSize = 10 end
    if cfg.fontSize > 20 then cfg.fontSize = 20 end

    if type(cfg.lineHeight) ~= "number" then
        cfg.lineHeight = tonumber(old.lineHeight) or 18
    end
    if cfg.lineHeight < 16 then cfg.lineHeight = 16 end
    if cfg.lineHeight > 28 then cfg.lineHeight = 28 end

    if type(cfg.headerStyle) ~= "string" then
        cfg.headerStyle = old.headerStyle or "normal"
    end
    if cfg.headerStyle ~= "normal" and cfg.headerStyle ~= "emphasis" then
        cfg.headerStyle = "normal"
    end

    if type(cfg.topSplitRatio) ~= "number" then
        cfg.topSplitRatio = 56
    end
    if cfg.topSplitRatio < 40 then cfg.topSplitRatio = 40 end
    if cfg.topSplitRatio > 75 then cfg.topSplitRatio = 75 end

    if type(cfg.highlightItemIDs) ~= "table" then
        cfg.highlightItemIDs = { [163036] = true }
    elseif next(cfg.highlightItemIDs) == nil then
        cfg.highlightItemIDs[163036] = true
    end
    if type(cfg.highlightCurrencyIDs) ~= "table" then
        cfg.highlightCurrencyIDs = {}
    end

    return cfg
end

function MRT.Config:GetWorldQuestConfig()
    MyRewardTrackerDB = MyRewardTrackerDB or {}
    MyRewardTrackerDB.account = MyRewardTrackerDB.account or {}
    MyRewardTrackerDB.account.worldQuestConfig = MyRewardTrackerDB.account.worldQuestConfig or {}

    local cfg = MyRewardTrackerDB.account.worldQuestConfig
    if type(cfg.enabled) ~= "boolean" then
        cfg.enabled = false
    end
    if type(cfg.showOnCharacterDashboard) ~= "boolean" then
        cfg.showOnCharacterDashboard = false
    end
    if type(cfg.trackAnima) ~= "boolean" then
        cfg.trackAnima = true
    end
    if type(cfg.goldMinimum) ~= "number" or cfg.goldMinimum < 0 then
        cfg.goldMinimum = 0
    end
    if type(cfg.zoneWhitelist) ~= "table" then
        cfg.zoneWhitelist = {}
    end
    if type(cfg.questBlacklist) ~= "table" then
        cfg.questBlacklist = {}
    end
    return cfg
end

function MRT.Config:IsDashboardSortDebugEnabled()
    local cfg = self:GetDashboardConfig()
    return cfg.showSortDebug
end
