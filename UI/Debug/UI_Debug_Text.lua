local addonName, MRT = ...

MRT.DebugText = MRT.DebugText or {}
local DebugText = MRT.DebugText

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

local function GetMissionState(mission)
    if MRT.Config and MRT.Config.GetMissionState then
        return MRT.Config:GetMissionState(mission)
    end
    if mission and mission.inProgress then
        return "running"
    end
    if mission and mission.completed then
        return "ready"
    end
    return "available"
end

local function GetStateLabel(state)
    if state == "ready" then
        return "fertig"
    end
    if state == "running" then
        return "laeuft"
    end
    return "verfuegbar"
end

local function GetStateSort(state)
    if state == "available" then return 1 end
    if state == "running" then return 2 end
    if state == "ready" then return 3 end
    return 99
end

local function GetExpansionKey(mission)
    if MRT.Config and MRT.Config.GetExpansionKeyByFollowerType then
        return MRT.Config:GetExpansionKeyByFollowerType(mission and mission.followerTypeID)
    end
    return "unknown"
end

local function GetExpansionLabel(expansionKey)
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Expansion then
        local label = MRT.Config.Labels.Expansion[expansionKey]
        if label and label ~= "" then
            return label
        end
    end
    return string.upper(expansionKey or "unknown")
end

local function GetRewardSort(rewardKey)
    if MRT.Config and MRT.Config.GetRewardSortIndex then
        return MRT.Config:GetRewardSortIndex(rewardKey or "other")
    end
    return 9999
end

local function ResolveCurrencyName(currencyID)
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if info and info.name and info.name ~= "" then
        return info.name
    end
    return "Currency:" .. tostring(currencyID)
end

local function ResolveItemName(itemID)
    local name, link = GetItemInfo(itemID)
    if link and link ~= "" then
        return link
    end
    if name and name ~= "" then
        return name
    end
    local instantName = C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(itemID)
    if instantName and instantName ~= "" then
        return instantName
    end
    return "Item:" .. tostring(itemID)
end

local function BuildRewardSummaryAndKey(mission)
    if not mission or type(mission.rewards) ~= "table" then
        return "keine Belohnung", "other"
    end

    local hasGold = false
    local hasCurrency = false
    local hasItem = false
    local hasAnima = false
    local parts = {}

    for _, reward in ipairs(mission.rewards) do
        local qty = tonumber(reward.quantity) or 0
        if reward.currencyID == 0 then
            hasGold = true
            parts[#parts + 1] = "Gold x" .. qty
        elseif reward.currencyID then
            hasCurrency = true
            parts[#parts + 1] = ResolveCurrencyName(reward.currencyID) .. " x" .. qty
        elseif reward.itemID then
            local itemName = ResolveItemName(reward.itemID)
            parts[#parts + 1] = itemName .. " x" .. qty
            if MRT.Config and MRT.Config.IsAnimaItem and MRT.Config:IsAnimaItem(reward.itemID) then
                hasAnima = true
            else
                hasItem = true
            end
        end
    end

    local rewardKey = "other"
    if hasAnima then
        rewardKey = "anima"
    elseif hasItem then
        rewardKey = "item"
    elseif hasCurrency then
        rewardKey = "currency"
    elseif hasGold then
        rewardKey = "gold"
    end

    if #parts == 0 then
        return "keine Belohnung", rewardKey
    end
    return table.concat(parts, ", "), rewardKey
end

local function BuildTrackedCharactersBlock(output, trackedAll)
    output[#output + 1] = "Tracked Characters (account.tracked):"
    if not trackedAll then
        output[#output + 1] = "  - nicht vorhanden"
        output[#output + 1] = ""
        return
    end

    local keys = {}
    for key in pairs(trackedAll) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    if #keys == 0 then
        output[#output + 1] = "  - keine"
        output[#output + 1] = ""
        return
    end

    for _, key in ipairs(keys) do
        local entry = trackedAll[key]
        local s = entry and entry.summary or {}
        output[#output + 1] = string.format(
            "  - %s | total:%d avail:%d run:%d ready:%d",
            key,
            s.filteredTotal or 0,
            s.available or 0,
            s.running or 0,
            s.ready or 0
        )
    end
    output[#output + 1] = ""
end

function DebugText.BuildText()
    if not MyRewardTrackerDB then
        return "DB nicht vorhanden."
    end

    local charKey = GetCharacterKey()
    local charData = MyRewardTrackerCharDB
    if not charData or type(charData.missionTable) ~= "table" then
        return "Keine Missionsdaten fuer Charakter."
    end

    local output = {}
    output[#output + 1] = "Character: " .. charKey
    output[#output + 1] = ""

    if MRT.Notifier and MRT.Notifier.GetSummaryCounts then
        local summary = MRT.Notifier:GetSummaryCounts()
        output[#output + 1] = "Notifier Summary:"
        output[#output + 1] = "  available: " .. (summary.available or 0)
        output[#output + 1] = "  ready: " .. (summary.ready or 0)
        output[#output + 1] = "  running: " .. (summary.running or 0)
        output[#output + 1] = "  wq: " .. (summary.wq or 0)
        output[#output + 1] = "  filteredTotal: " .. (summary.filteredTotal or 0)
        output[#output + 1] = ""
    end

    local tracked = MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked and MyRewardTrackerDB.account.tracked[charKey]
    if tracked and tracked.summary then
        output[#output + 1] = "Tracked Summary (account.tracked, aktueller Char):"
        output[#output + 1] = "  filteredTotal: " .. (tracked.summary.filteredTotal or 0)
        output[#output + 1] = "  available: " .. (tracked.summary.available or 0)
        output[#output + 1] = "  running: " .. (tracked.summary.running or 0)
        output[#output + 1] = "  ready: " .. (tracked.summary.ready or 0)
        output[#output + 1] = "  wq: " .. (tracked.summary.wq or 0)
        output[#output + 1] = ""
    else
        output[#output + 1] = "Tracked Summary (account.tracked, aktueller Char): nicht vorhanden"
        output[#output + 1] = ""
    end

    BuildTrackedCharactersBlock(output, MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked)

    local allCount = 0
    local filteredCount = 0
    local entries = {}
    local ignored = {}

    for missionID, mission in pairs(charData.missionTable) do
        allCount = allCount + 1
        local filtered = MRT.FilterEngine and MRT.FilterEngine.CheckMission and MRT.FilterEngine:CheckMission(missionID, mission) or false
        local state = GetMissionState(mission)
        local expansionKey = GetExpansionKey(mission)
        local expansionSort = MRT.Config and MRT.Config.GetExpansionSortIndex and MRT.Config:GetExpansionSortIndex(expansionKey) or 9999
        local rewardText, rewardKey = BuildRewardSummaryAndKey(mission)
        local rewardSort = GetRewardSort(rewardKey)

        local item = {
            missionID = missionID,
            name = mission.name or "Unknown",
            state = state,
            expansionKey = expansionKey,
            expansionSort = expansionSort,
            rewardKey = rewardKey,
            rewardSort = rewardSort,
            rewardText = rewardText,
            stateSort = GetStateSort(state),
        }

        if filtered then
            filteredCount = filteredCount + 1
            entries[#entries + 1] = item
        else
            ignored[#ignored + 1] = item
        end
    end

    table.sort(entries, function(a, b)
        if a.expansionSort ~= b.expansionSort then return a.expansionSort < b.expansionSort end
        if a.rewardSort ~= b.rewardSort then return a.rewardSort < b.rewardSort end
        if a.stateSort ~= b.stateSort then return a.stateSort < b.stateSort end
        if a.name ~= b.name then return a.name < b.name end
        return a.missionID < b.missionID
    end)

    output[#output + 1] = string.format("Missionen gesamt: %d | gefiltert: %d | ignoriert: %d", allCount, filteredCount, allCount - filteredCount)
    output[#output + 1] = ""
    output[#output + 1] = "Gefilterte Missionen (Sort: Erweiterung > Belohnung > Status > Name):"

    local lastExpansion = nil
    local lastReward = nil
    for _, e in ipairs(entries) do
        if lastExpansion ~= e.expansionKey then
            output[#output + 1] = "  == " .. GetExpansionLabel(e.expansionKey) .. " =="
            lastReward = nil
        end
        if lastReward ~= e.rewardKey then
            output[#output + 1] = "   -- " .. string.upper(e.rewardKey) .. " --"
        end

        output[#output + 1] = string.format(
            "   [%d] %s | %s | %s",
            e.missionID,
            e.name,
            e.rewardText,
            GetStateLabel(e.state)
        )
        lastExpansion = e.expansionKey
        lastReward = e.rewardKey
    end

    if #entries == 0 then
        output[#output + 1] = "  - keine gefilterten Missionen"
    end

    output[#output + 1] = ""
    output[#output + 1] = "Ignorierte Missionen (nur Kurzliste): " .. tostring(#ignored)
    if #ignored > 0 then
        table.sort(ignored, function(a, b)
            if a.name ~= b.name then return a.name < b.name end
            return a.missionID < b.missionID
        end)
        local limit = math.min(#ignored, 10)
        for i = 1, limit do
            local e = ignored[i]
            output[#output + 1] = string.format("  - [%d] %s", e.missionID, e.name)
        end
        if #ignored > limit then
            output[#output + 1] = "  ... +" .. tostring(#ignored - limit) .. " weitere"
        end
    end

    return table.concat(output, "\n")
end
