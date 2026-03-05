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

local function CopyTrackedRewards(mission)
    local rewardsCopy = {}
    if not mission or type(mission.rewards) ~= "table" then
        return rewardsCopy
    end

    for _, reward in ipairs(mission.rewards) do
        rewardsCopy[#rewardsCopy + 1] = {
            itemID = reward.itemID,
            currencyID = reward.currencyID,
            quantity = reward.quantity,
        }
    end

    return rewardsCopy
end

local function FormatMoneySimple(copper)
    local value = tonumber(copper) or 0
    if value < 0 then
        value = 0
    end
    local gold = math.floor(value / 10000)
    local silver = math.floor((value % 10000) / 100)
    local bronze = value % 100
    return string.format("%dg %ds %dc", gold, silver, bronze)
end

local function DeepCopyTable(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for k, v in pairs(value) do
        local copyKey = DeepCopyTable(k, seen)
        copy[copyKey] = DeepCopyTable(v, seen)
    end

    return copy
end

local function BuildCharacterMissionRecord(mission)
    if type(mission) ~= "table" or not mission.missionID then
        return nil
    end

    -- Charakter-Speicher bleibt absichtlich detailreich (Werkbank fuer spaetere Ideen).
    local record = DeepCopyTable(mission)
    if record.startTime and record.durationSeconds and not record.endTime then
        record.endTime = record.startTime + record.durationSeconds
    end

    return record
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
    if not MyRewardTrackerCharDB then
        return nil
    end

    local charData = MyRewardTrackerCharDB
    if not charData or type(charData.missionTable) ~= "table" then
        return nil
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
            totalGoldCopper = 0,
            totalAnima = 0,
            totalItemQuantity = 0,
            totalCurrencyQuantity = 0,
        },
        missions = {},
    }

    for missionID, mission in pairs(charData.missionTable) do
        local isFiltered = MRT.FilterEngine and MRT.FilterEngine.CheckMission and MRT.FilterEngine:CheckMission(missionID, mission)
        if isFiltered then
            local state = GetMissionStateSafe(mission)
            local missionGold = 0
            local missionAnima = 0
            local missionItems = 0
            local missionCurrencies = 0

            tracked.summary.filteredTotal = tracked.summary.filteredTotal + 1
            tracked.summary[state] = (tracked.summary[state] or 0) + 1

            if type(mission.rewards) == "table" then
                for _, reward in ipairs(mission.rewards) do
                    local qty = tonumber(reward.quantity) or 0
                    if reward.currencyID == 0 then
                        missionGold = missionGold + qty
                    elseif reward.currencyID then
                        missionCurrencies = missionCurrencies + qty
                    elseif reward.itemID then
                        missionItems = missionItems + qty
                        if MRT.Config and MRT.Config.GetAnimaValue then
                            local animaValue = MRT.Config:GetAnimaValue(reward.itemID)
                            if animaValue > 0 then
                                missionAnima = missionAnima + (animaValue * qty)
                            end
                        end
                    end
                end
            end

            tracked.summary.totalGoldCopper = (tracked.summary.totalGoldCopper or 0) + missionGold
            tracked.summary.totalAnima = (tracked.summary.totalAnima or 0) + missionAnima
            tracked.summary.totalItemQuantity = (tracked.summary.totalItemQuantity or 0) + missionItems
            tracked.summary.totalCurrencyQuantity = (tracked.summary.totalCurrencyQuantity or 0) + missionCurrencies

            tracked.missions[missionID] = {
                missionID = missionID,
                name = mission.name,
                state = state,
                expansionKey = GetExpansionKeySafe(mission),
                rewardKey = GetRewardKeySafe(mission),
                endTime = mission.endTime,
                timeLeftSeconds = mission.timeLeftSeconds,
                goldCopper = missionGold,
                anima = missionAnima,
                itemQuantity = missionItems,
                currencyQuantity = missionCurrencies,
                rewards = CopyTrackedRewards(mission),
            }
        end
    end

    trackedRoot[charKey] = tracked
    return tracked
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
    MyRewardTrackerDB.account = MyRewardTrackerDB.account or {}
    MyRewardTrackerDB.account.tracked = MyRewardTrackerDB.account.tracked or {}

    MyRewardTrackerCharDB = MyRewardTrackerCharDB or {}
    MyRewardTrackerCharDB.missionTable = MyRewardTrackerCharDB.missionTable or {}
    MyRewardTrackerCharDB.worldQuests = MyRewardTrackerCharDB.worldQuests or {}
    MyRewardTrackerCharDB.meta = MyRewardTrackerCharDB.meta or {}

    local charKey = GetCharacterKey()
    MyRewardTrackerCharDB.meta.charKey = charKey
    if type(MyRewardTrackerCharDB.lastScan) ~= "number" then
        MyRewardTrackerCharDB.lastScan = 0
    end

    return charKey
end

function Scanner:StartScan()

    
    local charKey = EnsureDB()

    -- 🔄 Alte Daten komplett ersetzen
    MyRewardTrackerCharDB.missionTable = {}

    local function SaveMission(mission)
        local record = BuildCharacterMissionRecord(mission)
        if not record then
            return
        end

        MyRewardTrackerCharDB.missionTable[record.missionID] = record
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

    MyRewardTrackerCharDB.lastScan = time()
    self:SyncTrackedFromCharacter(charKey)

    local count = 0
    for _ in pairs(MyRewardTrackerCharDB.missionTable) do
        count = count + 1
    end
    MRT.Notifier:CheckMissions()
    
end

function Scanner:SyncTrackedFromCharacter(charKey)
    local resolvedCharKey = charKey
    if not resolvedCharKey or resolvedCharKey == "" then
        if MyRewardTrackerCharDB and MyRewardTrackerCharDB.meta and MyRewardTrackerCharDB.meta.charKey then
            resolvedCharKey = MyRewardTrackerCharDB.meta.charKey
        else
            resolvedCharKey = GetCharacterKey()
        end
    end

    return BuildTrackedForCharacter(resolvedCharKey)
end

SLASH_MRTSYNCTRACKED1 = "/mrtsynctracked"
SlashCmdList["MRTSYNCTRACKED"] = function()
    if not MRT.Scanner or not MRT.Scanner.SyncTrackedFromCharacter then
        print("|cffff0000[MRT]|r Scanner-Sync nicht verfuegbar.")
        return
    end

    local tracked = MRT.Scanner:SyncTrackedFromCharacter()
    if not tracked or not tracked.summary then
        print("|cffff0000[MRT]|r Kein Tracked-Sync moeglich (keine Char-Daten).")
        return
    end

    print(
        string.format(
            "|cff00ff00[MRT]|r Tracked-Sync OK (%s): total=%d avail=%d run=%d ready=%d",
            tracked.charKey or "unknown",
            tracked.summary.filteredTotal or 0,
            tracked.summary.available or 0,
            tracked.summary.running or 0,
            tracked.summary.ready or 0
        )
    )
    if tracked.summary then
        print(
            string.format(
                "|cff00ff00[MRT]|r Tracked-Summen: gold=%s anima=%d items=%d waehrung=%d",
                FormatMoneySimple(tracked.summary.totalGoldCopper or 0),
                tracked.summary.totalAnima or 0,
                tracked.summary.totalItemQuantity or 0,
                tracked.summary.totalCurrencyQuantity or 0
            )
        )
    end
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtsynctracked", "sync't account.tracked aus aktuellem Charakter-Scan")
end

MRT.Scanner = Scanner
