local addonName, MRT = ...

MRT.MultiDebugData = MRT.MultiDebugData or {}
local Data = MRT.MultiDebugData
local Utils = MRT.MultiDebugUtils or {}

function Data.BuildLines(cfg)
    local lines = {}
    lines[#lines + 1] = "|cffffcc00Multi-Char Debug (account.tracked)|r"
    lines[#lines + 1] = ""

    local trackedRoot = MyRewardTrackerDB and MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked
    if type(trackedRoot) ~= "table" then
        lines[#lines + 1] = "Keine account.tracked Daten vorhanden."
        return lines
    end

    local keys = Utils.GetSortedTrackedKeys(trackedRoot)
    if #keys == 0 then
        lines[#lines + 1] = "Keine Characters in account.tracked."
        return lines
    end

    local global = {
        filteredTotal = 0,
        available = 0,
        running = 0,
        ready = 0,
        gold = 0,
        anima = 0,
        items = 0,
        waehr = 0,
        missions = 0,
    }

    for _, charKey in ipairs(keys) do
        local tracked = trackedRoot[charKey]
        local s = tracked and tracked.summary or {}
        global.filteredTotal = global.filteredTotal + (s.filteredTotal or 0)
        global.available = global.available + (s.available or 0)
        global.running = global.running + (s.running or 0)
        global.ready = global.ready + (s.ready or 0)
        global.gold = global.gold + (s.totalGoldCopper or 0)
        global.anima = global.anima + (s.totalAnima or 0)
        global.items = global.items + (s.totalItemQuantity or 0)
        global.waehr = global.waehr + (s.totalCurrencyQuantity or 0)
        if tracked and type(tracked.missions) == "table" then
            for _ in pairs(tracked.missions) do
                global.missions = global.missions + 1
            end
        end
    end

    lines[#lines + 1] = "|cffffcc00Global (alle Chars):|r"
    lines[#lines + 1] = string.format(
        "  Missionen total:%d | verfuegbar:%d | laeuft:%d | fertig:%d | Eintraege:%d",
        global.filteredTotal,
        global.available,
        global.running,
        global.ready,
        global.missions
    )
    local globalParts = {}
    if cfg.multiShowGold then
        globalParts[#globalParts + 1] = "gold:" .. Utils.FormatMoney(global.gold)
    end
    if cfg.multiShowAnima then
        globalParts[#globalParts + 1] = "anima:" .. tostring(global.anima)
    end
    if cfg.multiShowItems then
        globalParts[#globalParts + 1] = "items:" .. tostring(global.items)
    end
    if cfg.multiShowCurrency then
        globalParts[#globalParts + 1] = "waehr:" .. tostring(global.waehr)
    end
    if #globalParts > 0 then
        lines[#lines + 1] = "  " .. table.concat(globalParts, " ")
    end
    lines[#lines + 1] = ""

    for _, charKey in ipairs(keys) do
        local tracked = trackedRoot[charKey]
        local s = tracked and tracked.summary or {}
        lines[#lines + 1] = "|cffffcc00" .. charKey .. "|r"
        lines[#lines + 1] = string.format(
            "  Missionen total:%d | verfuegbar:%d | laeuft:%d | fertig:%d",
            s.filteredTotal or 0,
            s.available or 0,
            s.running or 0,
            s.ready or 0
        )
        local parts = {}
        if cfg.multiShowGold then
            parts[#parts + 1] = "gold:" .. Utils.FormatMoney(s.totalGoldCopper or 0)
        end
        if cfg.multiShowAnima then
            parts[#parts + 1] = "anima:" .. tostring(s.totalAnima or 0)
        end
        if cfg.multiShowItems then
            parts[#parts + 1] = "items:" .. tostring(s.totalItemQuantity or 0)
        end
        if cfg.multiShowCurrency then
            parts[#parts + 1] = "waehr:" .. tostring(s.totalCurrencyQuantity or 0)
        end
        if #parts == 0 then
            parts[1] = "(alle Summengruppen aus)"
        end
        lines[#lines + 1] = "  " .. table.concat(parts, " ")
        lines[#lines + 1] = string.format(
            "  Eintraege:%d | lastScan:%s",
            tracked and tracked.missions and (function()
                local c = 0
                for _ in pairs(tracked.missions) do
                    c = c + 1
                end
                return c
            end)() or 0,
            tostring(tracked and tracked.lastScan or 0)
        )
        if cfg.multiDetailLong then
            lines[#lines + 1] = "  Detailliste (Sort: Erweiterung > Status > Name)"

            local groups = {
                gold = {},
                currency = {},
                items = {},
                anima = {},
            }
            local missions = tracked and tracked.missions or {}
            for missionID, mission in pairs(missions or {}) do
                local groupInfo = Utils.BuildGroupData(mission)
                local primaryGroup = Utils.GetPrimaryGroupKey(groupInfo)
                if primaryGroup then
                    local base = {
                        missionID = missionID,
                        name = mission.name or "Unknown",
                        state = mission.state or "available",
                        expansionKey = mission.expansionKey or "unknown",
                        expansionSort = MRT.Config and MRT.Config.GetExpansionSortIndex and MRT.Config:GetExpansionSortIndex(mission.expansionKey or "unknown") or 9999,
                        stateSort = Utils.GetStateSort(mission.state),
                        groupInfo = groupInfo,
                    }
                    groups[primaryGroup][#groups[primaryGroup] + 1] = base
                end
            end

            local function sortEntries(tbl)
                table.sort(tbl, function(a, b)
                    if a.expansionSort ~= b.expansionSort then return a.expansionSort < b.expansionSort end
                    if a.stateSort ~= b.stateSort then return a.stateSort < b.stateSort end
                    if a.name ~= b.name then return a.name < b.name end
                    return a.missionID < b.missionID
                end)
            end
            sortEntries(groups.gold)
            sortEntries(groups.currency)
            sortEntries(groups.items)
            sortEntries(groups.anima)

            local function appendGroup(title, key, enabled)
                if not enabled then
                    return
                end
                lines[#lines + 1] = "  " .. title .. ":"
                local list = groups[key] or {}
                if #list == 0 then
                    lines[#lines + 1] = "    - keine"
                    return
                end
                for _, e in ipairs(list) do
                    lines[#lines + 1] = string.format(
                        "    - [%d] %s | %s | %s | %s",
                        e.missionID,
                        e.name,
                        Utils.BuildGroupText(key, e.groupInfo),
                        Utils.GetStateLabel(e.state),
                        Utils.GetExpansionLabel(e.expansionKey)
                    )
                end
            end

            appendGroup("Gold", "gold", cfg.multiShowGold)
            appendGroup("Waehrung", "currency", cfg.multiShowCurrency)
            appendGroup("Items", "items", cfg.multiShowItems)
            appendGroup("Anima", "anima", cfg.multiShowAnima)
        end
        lines[#lines + 1] = ""
    end

    return lines
end

function Data.PrintTrackedDump()
    local trackedRoot = MyRewardTrackerDB and MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked
    if type(trackedRoot) ~= "table" then
        print("|cffff0000[MRT]|r Kein account.tracked vorhanden.")
        return
    end

    local keys = Utils.GetSortedTrackedKeys(trackedRoot)
    if #keys == 0 then
        print("|cffff0000[MRT]|r account.tracked ist leer.")
        return
    end

    print("|cff00ff00[MRT]|r Multi-Char Dump (account.tracked):")
    for _, charKey in ipairs(keys) do
        local tracked = trackedRoot[charKey]
        local s = tracked and tracked.summary or {}
        local groupCount = { anima = 0, item = 0, currency = 0, gold = 0, other = 0 }
        local missionCount = 0

        if tracked and type(tracked.missions) == "table" then
            for _, mission in pairs(tracked.missions) do
                missionCount = missionCount + 1
                local key = mission and mission.rewardKey or "other"
                if not groupCount[key] then
                    key = "other"
                end
                groupCount[key] = groupCount[key] + 1
            end
        end

        print(string.format(
            "  %s | total:%d avail:%d run:%d ready:%d",
            charKey,
            s.filteredTotal or 0,
            s.available or 0,
            s.running or 0,
            s.ready or 0
        ))
        print(string.format(
            "    gold:%s anima:%d items:%d waehr:%d missions:%d",
            Utils.FormatMoney(s.totalGoldCopper or 0),
            s.totalAnima or 0,
            s.totalItemQuantity or 0,
            s.totalCurrencyQuantity or 0,
            missionCount
        ))
        print(string.format(
            "    groups anima:%d item:%d currency:%d gold:%d other:%d",
            groupCount.anima,
            groupCount.item,
            groupCount.currency,
            groupCount.gold,
            groupCount.other
        ))
    end
end
