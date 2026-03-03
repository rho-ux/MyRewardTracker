-- =========================================
-- MyRewardTracker - Notifier
-- Phase 4
-- Meldet gefilterte fertige Missionen
-- =========================================

local addonName, MRT = ...
local Notifier = CreateFrame("Frame")
MRT.Notifier = Notifier
local FilterEngine = MRT.FilterEngine

local notified = {}

function MRT.Notifier:CheckMissions()

    if not MyRewardTrackerDB then return end
    if not MyRewardTrackerDB.characters then return end

    for charKey, charData in pairs(MyRewardTrackerDB.characters) do

        if charData.missionTable then

            for missionID, mission in pairs(charData.missionTable) do

    local filtered = FilterEngine:CheckMission(missionID, mission)

    if filtered then

        if mission.inProgress and mission.timeLeftSeconds == 0 then

            if not notified[charKey .. missionID] then

                print("|cff00ff00[MRT]|r Mission fertig: " .. (mission.name or missionID))

                notified[charKey .. missionID] = true

            end

        end

    end

end

        end

    end

end

Notifier:RegisterEvent("PLAYER_LOGIN")
Notifier:RegisterEvent("GARRISON_MISSION_LIST_UPDATE")

Notifier:SetScript("OnEvent", function(self, event)

    if event == "PLAYER_LOGIN" then

        C_Timer.After(5, function()
            MRT.Notifier:CheckMissions()
        end)

    else

        MRT.Notifier:CheckMissions()

    end

end)
