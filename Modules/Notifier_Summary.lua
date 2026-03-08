local addonName, MRT = ...

MRT.NotifierSummary = MRT.NotifierSummary or {}
local NotifierSummary = MRT.NotifierSummary

local function GetWQCfg()
    if MRT.Config and MRT.Config.GetWorldQuestConfig then
        return MRT.Config:GetWorldQuestConfig()
    end
    return { enabled = false, showOnCharacterDashboard = false, trackAnima = true, goldMinimum = 0 }
end

local function GetNotifierCfg()
    if MRT.NotifierConfig and MRT.NotifierConfig.Get then
        return MRT.NotifierConfig:Get()
    end
    return { highlightsOnly = false }
end

local function MergeBoolMap(dst, src)
    if type(src) ~= "table" then
        return
    end
    for k, v in pairs(src) do
        local id = tonumber(k)
        if id and id > 0 and v ~= false then
            dst[id] = true
        end
    end
end

local function BuildHighlightMaps()
    local item = {}
    local currency = {}
    local mission = {}

    local dcfg = MRT.Config and MRT.Config.GetDashboardConfig and MRT.Config:GetDashboardConfig() or {}
    local mcfg = MRT.Config and MRT.Config.GetMultiDashboardConfig and MRT.Config:GetMultiDashboardConfig() or {}

    MergeBoolMap(item, mcfg.highlightItemIDs)
    MergeBoolMap(currency, mcfg.highlightCurrencyIDs)
    MergeBoolMap(item, dcfg.highlightItemIDs)
    MergeBoolMap(currency, dcfg.highlightCurrencyIDs)
    MergeBoolMap(mission, dcfg.highlightMissionIDs)
    return item, currency, mission
end

local function MissionMatchesHighlights(missionID, mission, itemMap, currencyMap, missionMap)
    if missionMap[tonumber(missionID) or 0] then
        return true
    end
    if not mission or type(mission.rewards) ~= "table" then
        return false
    end
    for _, reward in ipairs(mission.rewards) do
        if reward.itemID and itemMap[tonumber(reward.itemID) or 0] then
            return true
        end
        if reward.currencyID and reward.currencyID ~= 0 and currencyMap[tonumber(reward.currencyID) or 0] then
            return true
        end
    end
    return false
end

local function CollectSummaryCounts()
    local availableCount = 0
    local readyCount = 0
    local runningCount = 0
    local wqCount = 0
    local filteredTotal = 0
    local charData = MyRewardTrackerCharDB
    local FilterEngine = MRT.FilterEngine
    local notifierCfg = GetNotifierCfg()
    local highlightsOnly = notifierCfg.highlightsOnly and true or false
    local highlightItemIDs, highlightCurrencyIDs, highlightMissionIDs = BuildHighlightMaps()

    if not charData or not charData.missionTable or not FilterEngine then
        return 0, 0, 0, 0, 0
    end

    for missionID, mission in pairs(charData.missionTable) do
        local state = "available"
        if MRT.Config and MRT.Config.GetMissionState then
            state = MRT.Config:GetMissionState(mission)
        end
        local filtered = FilterEngine:CheckMission(missionID, mission)
        if filtered and highlightsOnly then
            filtered = MissionMatchesHighlights(missionID, mission, highlightItemIDs, highlightCurrencyIDs, highlightMissionIDs)
        end

        if filtered then
            filteredTotal = filteredTotal + 1
            if state == "ready" then
                readyCount = readyCount + 1
            elseif state == "available" then
                availableCount = availableCount + 1
            elseif state == "running" then
                runningCount = runningCount + 1
            end
        end
    end

    local wqCfg = GetWQCfg()
    if wqCfg.enabled then
        wqCount = 0 -- WQ scanner folgt spaeter
    else
        wqCount = 0
    end
    return availableCount, readyCount, wqCount, runningCount, filteredTotal
end

function NotifierSummary.GetCounts()
    local availableCount, readyCount, wqCount, runningCount, filteredTotal = CollectSummaryCounts()
    local wqCfg = GetWQCfg()
    local notifierCfg = GetNotifierCfg()
    return {
        available = availableCount or 0,
        ready = readyCount or 0,
        wq = wqCount or 0,
        running = runningCount or 0,
        filteredTotal = filteredTotal or 0,
        wqEnabled = wqCfg.enabled and true or false,
        wqTrackAnima = (wqCfg.trackAnima ~= false),
        wqGoldMinimum = tonumber(wqCfg.goldMinimum) or 0,
        notifierHighlightsOnly = notifierCfg.highlightsOnly and true or false,
    }
end

function NotifierSummary.GetPopupCounts()
    local availableCount, readyCount, wqCount = CollectSummaryCounts()
    return availableCount, readyCount, wqCount
end
