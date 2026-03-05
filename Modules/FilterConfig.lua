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
    GoldMinimum = 0,
    AnimaBypassFilter = false,
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
    if type(cfg.AnimaBypassFilter) ~= "boolean" then
        cfg.AnimaBypassFilter = DefaultFilterConfig.AnimaBypassFilter
    end

    return cfg
end

function MRT.FilterConfig:GetActive()
    return EnsureAccountFilterConfig()
end

MRT.FilterConfig.Defaults = DefaultFilterConfig

SLASH_MRTFILTERANIMA1 = "/mrtfilteranima"
SlashCmdList["MRTFILTERANIMA"] = function(msg)
    local cfg = EnsureAccountFilterConfig()
    local arg = string.lower((msg or ""):match("^%s*(.-)%s*$"))

    if arg == "on" then
        cfg.AnimaBypassFilter = true
    elseif arg == "off" then
        cfg.AnimaBypassFilter = false
    else
        cfg.AnimaBypassFilter = not cfg.AnimaBypassFilter
    end

    print("|cff00ff00[MRT]|r Anima Filter-Bypass: " .. (cfg.AnimaBypassFilter and "AN" or "AUS"))

    if MRT.Scanner and MRT.Scanner.SyncTrackedFromCharacter then
        MRT.Scanner:SyncTrackedFromCharacter()
    end
    if MRT.Dashboard and MRT.Dashboard.Refresh then
        MRT.Dashboard:Refresh()
    end
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtfilteranima on|off|toggle", "Anima kann optional normalen Filter uebersteuern")
end
