-- =========================================
-- MyRewardTracker - Mission Scanner (Phase 1: Full Dump)
-- =========================================

local addonName, MRT = ...
local Scanner = {}

local TABLE_TYPES = {
    { garrisonType = 2,   followerType = 1   },
    { garrisonType = 3,   followerType = 4   },
    { garrisonType = 9,   followerType = 22  },
    { garrisonType = 111, followerType = 123 },
}

local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName()
    return name .. "-" .. realm
end

local function EnsureDB()
    MyRewardTrackerDB = MyRewardTrackerDB or {}
    MyRewardTrackerDB.characters = MyRewardTrackerDB.characters or {}

    local charKey = GetCharacterKey()

    MyRewardTrackerDB.characters[charKey] = MyRewardTrackerDB.characters[charKey] or {
        lastScan = 0,
        missionTable = {},
        worldQuests = {}
    }

    return charKey
end

function Scanner:StartScan()

    
    local charKey = EnsureDB()

    -- 🔄 Alte Daten komplett ersetzen
    MyRewardTrackerDB.characters[charKey].missionTable = {}

    local function SaveMission(mission)
    if mission and mission.missionID then

        -- Zeitdaten ergänzen
        if mission.startTime and mission.durationSeconds then
            mission.endTime = mission.startTime + mission.durationSeconds
        end

        -- 🔒 1:1 Rohspeicherung
        MyRewardTrackerDB.characters[charKey].missionTable[mission.missionID] = mission
    end
end

    for _, entry in ipairs(TABLE_TYPES) do

        local followerTypeID = entry.followerType

        local available = C_Garrison.GetAvailableMissions(followerTypeID)
        local inProgress = C_Garrison.GetInProgressMissions(followerTypeID)

        if type(available) == "table" then
            for _, mission in ipairs(available) do
                SaveMission(mission)
            end
        end

        if type(inProgress) == "table" then
            for _, mission in ipairs(inProgress) do
                SaveMission(mission)
            end
        end
    end

    MyRewardTrackerDB.characters[charKey].lastScan = time()

    local count = 0
    for _ in pairs(MyRewardTrackerDB.characters[charKey].missionTable) do
        count = count + 1
    end
    MRT.Notifier:CheckMissions()
    
end

MRT.Scanner = Scanner