-- =========================================
-- MyRewardTracker - FilterConfig
-- Zentrale Filterdefinition
-- =========================================

local addonName, MRT = ...

MRT.FilterConfig = MRT.FilterConfig or {}

local DefaultFilterConfig = {
    ItemWhitelist = {},
    CurrencyMinimum = {},
    MissionWhitelist = {},
    GoldMinimum = 0
}

local function EnsureAccountFilterConfig()
    MyRewardTrackerDB = MyRewardTrackerDB or {}
    MyRewardTrackerDB.account = MyRewardTrackerDB.account or {}
    MyRewardTrackerDB.account.filterConfig = MyRewardTrackerDB.account.filterConfig or {}

    local cfg = MyRewardTrackerDB.account.filterConfig

    cfg.ItemWhitelist = cfg.ItemWhitelist or {}
    cfg.CurrencyMinimum = cfg.CurrencyMinimum or {}
    cfg.MissionWhitelist = cfg.MissionWhitelist or {}

    if type(cfg.GoldMinimum) ~= "number" then
        cfg.GoldMinimum = DefaultFilterConfig.GoldMinimum
    end

    return cfg
end

function MRT.FilterConfig:GetActive()
    return EnsureAccountFilterConfig()
end

MRT.FilterConfig.Defaults = DefaultFilterConfig
