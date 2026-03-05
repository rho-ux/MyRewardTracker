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

local function EnsureAccountTracked()
    MyRewardTrackerDB = MyRewardTrackerDB or {}
    MyRewardTrackerDB.account = MyRewardTrackerDB.account or {}
    MyRewardTrackerDB.account.tracked = MyRewardTrackerDB.account.tracked or {}
    return MyRewardTrackerDB.account.tracked
end

local function CopyMissionRewards(mission)
    local rewardsCopy = {}
    if not mission or type(mission.rewards) ~= "table" then
        return rewardsCopy
    end

    for _, reward in ipairs(mission.rewards) do
        rewardsCopy[#rewardsCopy + 1] = {
            itemID = reward.itemID,
            currencyID = reward.currencyID,
            quantity = reward.quantity,
            title = reward.title,
            icon = reward.icon,
        }
    end

    return rewardsCopy
end

local function GetMissionStateSafe(mission)
    if MRT.Config and MRT.Config.GetMissionState then
        return MRT.Config:GetMissionState(mission)
    end

    if mission and mission.completed then
        return "ready"
    end
    if mission and mission.inProgress then
        return "running"
    end
    return "available"
end

local function GetExpansionKeySafe(mission)
    if MRT.Config and MRT.Config.GetExpansionKeyByFollowerType then
        return MRT.Config:GetExpansionKeyByFollowerType(mission and mission.followerTypeID)
    end
    return "unknown"
end

local function GetRewardKeySafe(mission)
    if MRT.Config and MRT.Config.GetMissionRewardKey then
        return MRT.Config:GetMissionRewardKey(mission)
    end
    return "other"
end

local function BuildTrackedForCharacter(charKey)
    if not MyRewardTrackerDB or not MyRewardTrackerDB.characters then
        return
    end

    local charData = MyRewardTrackerDB.characters[charKey]
    if not charData or type(charData.missionTable) ~= "table" then
        return
    end

    local trackedRoot = EnsureAccountTracked()
    local tracked = {
        charKey = charKey,
        lastScan = time(),
        summary = {
            filteredTotal = 0,
            available = 0,
            running = 0,
            ready = 0,
            wq = 0,
        },
        missions = {},
    }

    for missionID, mission in pairs(charData.missionTable) do
        local isFiltered = MRT.FilterEngine and MRT.FilterEngine.CheckMission and MRT.FilterEngine:CheckMission(missionID, mission)
        if isFiltered then
            local state = GetMissionStateSafe(mission)
            tracked.summary.filteredTotal = tracked.summary.filteredTotal + 1
            tracked.summary[state] = (tracked.summary[state] or 0) + 1

            tracked.missions[missionID] = {
                missionID = missionID,
                name = mission.name,
                state = state,
                expansionKey = GetExpansionKeySafe(mission),
                rewardKey = GetRewardKeySafe(mission),
                startTime = mission.startTime,
                endTime = mission.endTime,
                durationSeconds = mission.durationSeconds,
                timeLeftSeconds = mission.timeLeftSeconds,
                inProgress = mission.inProgress and true or false,
                completed = mission.completed and true or false,
                followerTypeID = mission.followerTypeID,
                rewards = CopyMissionRewards(mission),
            }
        end
    end

    trackedRoot[charKey] = tracked
end

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
    BuildTrackedForCharacter(charKey)

    local count = 0
    for _ in pairs(MyRewardTrackerDB.characters[charKey].missionTable) do
        count = count + 1
    end
    MRT.Notifier:CheckMissions()
    
end

MRT.Scanner = Scanner
