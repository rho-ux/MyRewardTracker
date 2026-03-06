local addonName, MRT = ...

MRT.NotifierSummary = MRT.NotifierSummary or {}
local NotifierSummary = MRT.NotifierSummary

local function CollectSummaryCounts()
    local availableCount = 0
    local readyCount = 0
    local runningCount = 0
    local wqCount = 0
    local filteredTotal = 0
    local charData = MyRewardTrackerCharDB
    local FilterEngine = MRT.FilterEngine

    if not charData or not charData.missionTable or not FilterEngine then
        return 0, 0, 0, 0, 0
    end

    for missionID, mission in pairs(charData.missionTable) do
        local state = "available"
        if MRT.Config and MRT.Config.GetMissionState then
            state = MRT.Config:GetMissionState(mission)
        end
        local filtered = FilterEngine:CheckMission(missionID, mission)

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

    wqCount = 0
    return availableCount, readyCount, wqCount, runningCount, filteredTotal
end

function NotifierSummary.GetCounts()
    local availableCount, readyCount, wqCount, runningCount, filteredTotal = CollectSummaryCounts()
    return {
        available = availableCount or 0,
        ready = readyCount or 0,
        wq = wqCount or 0,
        running = runningCount or 0,
        filteredTotal = filteredTotal or 0
    }
end

function NotifierSummary.GetPopupCounts()
    local availableCount, readyCount, wqCount = CollectSummaryCounts()
    return availableCount, readyCount, wqCount
end
