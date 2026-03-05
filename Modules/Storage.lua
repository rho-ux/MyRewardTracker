local addonName, MRT = ...

MRT.Storage = {}

-- =========================================================
-- Utility
-- =========================================================

local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName()
    if not realm or realm == "" then
        local _, fullRealm = UnitFullName("player")
        realm = fullRealm
    end
    if not name or name == "" then
        name = "UnknownPlayer"
    end
    if not realm or realm == "" then
        realm = "UnknownRealm"
    end
    return name .. "-" .. realm
end

-- =========================================================
-- Character Access
-- =========================================================

function MRT.Storage:GetCharacterKey()
    return GetCharacterKey()
end

function MRT.Storage:GetCharacterData()
    if MyRewardTrackerCharDB then
        return MyRewardTrackerCharDB
    end
    return nil
end

-- =========================================================
-- Scan Timestamp
-- =========================================================

function MRT.Storage:SetLastScan(timestamp)
    local charData = self:GetCharacterData()
    if charData then
        charData.lastScan = timestamp
    end
end

function MRT.Storage:GetLastScan()
    local charData = self:GetCharacterData()
    if charData then
        return charData.lastScan
    end
    return 0
end

-- =========================================================
-- Mission Table Handling
-- =========================================================

function MRT.Storage:ResetMissionTable()
    local charData = self:GetCharacterData()
    if charData then
        charData.missionTable = {}
    end
end

function MRT.Storage:GetMissionTable()
    local charData = self:GetCharacterData()
    if charData then
        return charData.missionTable
    end
    return {}
end

-- =========================================================
-- Mission Cleanup
-- =========================================================

function MRT.Storage:CleanupMissions(charKey, currentMissionIDs)
    local charData = self:GetCharacterData()
    if not charData then return end
    if not charData.missionTable then return end

    for missionID, mission in pairs(charData.missionTable) do

        local stillExists = currentMissionIDs[missionID]

        if not stillExists and mission.completed then
            charData.missionTable[missionID] = nil
        end

    end

end
