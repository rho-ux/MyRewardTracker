-- =========================================
-- MyRewardTracker - Trigger System
-- =========================================

local addonName, MRT = ...

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GARRISON_MISSION_LIST_UPDATE")
frame:RegisterEvent("GARRISON_MISSION_STARTED")

frame:SetScript("OnEvent", function(self, event)

    if not MRT.Scanner then
        return
    end

    MRT.Scanner:StartScan()

end)