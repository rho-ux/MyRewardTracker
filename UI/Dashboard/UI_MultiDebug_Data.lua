local addonName, MRT = ...

MRT.MultiDebugData = MRT.MultiDebugData or {}
local Data = MRT.MultiDebugData
local Utils = MRT.MultiDebugUtils or {}

local function FormatDuration(seconds)
    local value = tonumber(seconds) or 0
    if value < 0 then value = 0 end
    local days = math.floor(value / 86400)
    local hours = math.floor((value % 86400) / 3600)
    local minutes = math.floor((value % 3600) / 60)
    if days > 0 then
        return string.format("%dt %dh %dm", days, hours, minutes)
    end
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    end
    return string.format("%dm", minutes)
end

local function BuildStatusText(state, mission, useColors)
    local normalized = (state == "completed") and "ready" or state
    local text = "verfuegbar"
    if normalized == "ready" then
        text = "fertig"
    elseif normalized == "running" then
        local seconds = tonumber(mission and mission.timeLeftSeconds)
        if seconds and seconds > 0 then
            text = "Rest: " .. FormatDuration(seconds)
        else
            text = "Rest: ?"
        end
    end
    if not useColors then
        return text
    end
    if normalized == "ready" then
        return "|cff00ff00" .. text .. "|r"
    end
    if normalized == "running" then
        return "|cff33aaff" .. text .. "|r"
    end
    return "|cffffff00" .. text .. "|r"
end

local function GetStateColorCodes(state, useColors)
    if not useColors then
        return "", ""
    end
    local normalized = (state == "completed") and "ready" or state
    if normalized == "ready" then
        return "|cff00ff00", "|r"
    end
    if normalized == "running" then
        return "|cff33aaff", "|r"
    end
    return "|cffffff00", "|r"
end

local function IsStateIncludedForMulti(state)
    return state == "running" or state == "ready" or state == "completed"
end

function Data.BuildLayoutRows(cfg, uiFilters)
    uiFilters = uiFilters or {}
    local selectedExpansion = tostring(uiFilters.expansionKey or "all")
    local selectedReward = tostring(uiFilters.rewardKey or "all")
    local highlightsOnly = uiFilters.highlightsOnly and true or false
    local searchText = string.lower(tostring(uiFilters.searchText or ""))

    local summaryRows = {}
    local highlightRows = {}
    local listRows = {}
    local trackedRoot = MyRewardTrackerDB and MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked
    if type(trackedRoot) ~= "table" then
        summaryRows[#summaryRows + 1] = { text = "Keine account.tracked Daten vorhanden." }
        listRows[#listRows + 1] = { text = "Keine account.tracked Daten vorhanden." }
        return summaryRows, listRows, highlightRows
    end

    local keys = Utils.GetSortedTrackedKeys(trackedRoot)
    if #keys == 0 then
        summaryRows[#summaryRows + 1] = { text = "Keine Characters in account.tracked." }
        listRows[#listRows + 1] = { text = "Keine Characters in account.tracked." }
        return summaryRows, listRows, highlightRows
    end

    local highlightItemIDs = {}
    local highlightCurrencyIDs = {}
    if type(cfg.highlightItemIDs) == "table" then
        for key, val in pairs(cfg.highlightItemIDs) do
            local id = tonumber(key)
            if id and id > 0 and val ~= false then
                highlightItemIDs[id] = true
            end
        end
    end
    if type(cfg.highlightCurrencyIDs) == "table" then
        for key, val in pairs(cfg.highlightCurrencyIDs) do
            local id = tonumber(key)
            if id and id > 0 and val ~= false then
                highlightCurrencyIDs[id] = true
            end
        end
    end

    local function IsHighlightMission(groupInfo)
        for _, it in ipairs(groupInfo.items or {}) do
            if highlightItemIDs[it.itemID] then
                return true, "item", it.itemID
            end
        end
        for _, it in ipairs(groupInfo.animaItems or {}) do
            if highlightItemIDs[it.itemID] then
                return true, "item", it.itemID
            end
        end
        for _, c in ipairs(groupInfo.currencies or {}) do
            if highlightCurrencyIDs[c.currencyID] then
                return true, "currency", c.currencyID
            end
        end
        return false, nil, nil
    end

    local global = {
        gold = 0,
        anima = 0,
        currencies = {},
        missionsTotal = 0,
        chars = #keys,
    }
    local entries = {}
    local highlightAgg = {}

    for _, charKey in ipairs(keys) do
        local tracked = trackedRoot[charKey]
        local missions = tracked and tracked.missions or {}
        for missionID, mission in pairs(missions) do
            local state = mission.state or "available"
            if IsStateIncludedForMulti(state) then
                global.missionsTotal = global.missionsTotal + 1

                local groupInfo = Utils.BuildGroupData(mission)
                local primaryGroup = Utils.GetPrimaryGroupKey(groupInfo)
                if primaryGroup then
                    local includeByGroup = true
                    if primaryGroup == "gold" and not cfg.multiShowGold then includeByGroup = false end
                    if primaryGroup == "currency" and not cfg.multiShowCurrency then includeByGroup = false end
                    if primaryGroup == "items" and not cfg.multiShowItems then includeByGroup = false end
                    if primaryGroup == "anima" and not cfg.multiShowAnima then includeByGroup = false end

                    if includeByGroup then
                        local rewardText = Utils.BuildGroupText(primaryGroup, groupInfo)
                        local rewardSearchText = Utils.BuildGroupSearchText(primaryGroup, groupInfo)
                        local expansionKey = mission.expansionKey or "unknown"
                        local expansionLabel = Utils.GetExpansionLabel(expansionKey)
                        local expansionSort = MRT.Config and MRT.Config.GetExpansionSortIndex and MRT.Config:GetExpansionSortIndex(expansionKey) or 9999
                        local normalizedState = (state == "completed") and "ready" or state
                        local stateSort = Utils.GetStateSort(normalizedState)
                        local normalizedRewardKey = (primaryGroup == "items") and "item" or primaryGroup
                        local rewardSort = MRT.Config and MRT.Config.GetRewardSortIndex and MRT.Config:GetRewardSortIndex(normalizedRewardKey) or 9999
                        local isHighlight, highlightKind, highlightID = IsHighlightMission(groupInfo)

                        if isHighlight then
                            local highlightRewardKey = (highlightKind == "currency") and "currency" or "item"
                            local aggKey = charKey .. "::" .. highlightRewardKey
                            local row = highlightAgg[aggKey] or {
                                charKey = charKey,
                                rewardKey = highlightRewardKey,
                                missions = 0,
                                sampleItemID = nil,
                                sampleCurrencyID = nil,
                            }
                            row.missions = row.missions + 1
                            if highlightRewardKey == "item" and highlightID and not row.sampleItemID then
                                row.sampleItemID = highlightID
                            end
                            if highlightRewardKey == "currency" and highlightID and not row.sampleCurrencyID then
                                row.sampleCurrencyID = highlightID
                            end
                            highlightAgg[aggKey] = row
                        end

                        if primaryGroup == "gold" then
                            global.gold = global.gold + (groupInfo.gold or 0)
                        elseif primaryGroup == "anima" then
                            local a = 0
                            for _, it in ipairs(groupInfo.animaItems or {}) do
                                local v = MRT.Config and MRT.Config.GetAnimaValue and MRT.Config:GetAnimaValue(it.itemID) or 0
                                a = a + ((tonumber(v) or 0) * (tonumber(it.quantity) or 0))
                            end
                            global.anima = global.anima + a
                        elseif primaryGroup == "currency" then
                            for _, c in ipairs(groupInfo.currencies or {}) do
                                local key = tonumber(c.currencyID) or 0
                                local row = global.currencies[key] or {
                                    currencyID = key,
                                    label = (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(key) and C_CurrencyInfo.GetCurrencyInfo(key).name) or ("Currency:" .. tostring(key)),
                                    total = 0,
                                }
                                row.total = row.total + (tonumber(c.quantity) or 0)
                                global.currencies[key] = row
                            end
                        end

                        local pass = true
                        if selectedExpansion ~= "all" and expansionKey ~= selectedExpansion then
                            pass = false
                        end
                        if selectedReward ~= "all" and normalizedRewardKey ~= selectedReward then
                            pass = false
                        end
                        if highlightsOnly and not isHighlight then
                            pass = false
                        end
                        if pass and searchText ~= "" then
                            local haystack = string.lower(
                                tostring(charKey) .. " " ..
                                tostring(expansionLabel) .. " " ..
                                tostring(mission.name or "unknown") .. " " ..
                                tostring(rewardSearchText or "")
                            )
                            if not string.find(haystack, searchText, 1, true) then
                                pass = false
                            end
                        end

                        if pass then
                            entries[#entries + 1] = {
                                charKey = charKey,
                                charSort = MRT.Config and MRT.Config.GetCharacterSortIndex and MRT.Config:GetCharacterSortIndex(charKey) or 9999,
                                missionID = missionID,
                                missionName = mission.name or "Unknown",
                                expansionKey = expansionKey,
                                expansionLabel = expansionLabel,
                                expansionSort = expansionSort,
                                rewardKey = normalizedRewardKey,
                                rewardSort = rewardSort,
                                state = normalizedState,
                                timeLeftSeconds = mission.timeLeftSeconds,
                                stateSort = stateSort,
                                rewardText = rewardText,
                                tooltip = Utils.BuildGroupTooltip(normalizedRewardKey, groupInfo),
                            }
                        end
                    end
                end
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.charSort ~= b.charSort then return a.charSort < b.charSort end
        if a.charKey ~= b.charKey then return a.charKey < b.charKey end
        if a.expansionSort ~= b.expansionSort then return a.expansionSort < b.expansionSort end
        if a.rewardSort ~= b.rewardSort then return a.rewardSort < b.rewardSort end
        if a.stateSort ~= b.stateSort then return a.stateSort < b.stateSort end
        if a.missionName ~= b.missionName then return a.missionName < b.missionName end
        return a.missionID < b.missionID
    end)

    summaryRows[#summaryRows + 1] = { text = "Gefilterte Missionseintraege (Liste): " .. tostring(#entries) .. " | aktiv gesamt: " .. tostring(global.missionsTotal) }
    summaryRows[#summaryRows + 1] = { text = "" }
    if cfg.multiShowGold then
        summaryRows[#summaryRows + 1] = { text = "|cffffcc00Gesamt Gold Missionen:|r " .. Utils.FormatMoney(global.gold) }
        summaryRows[#summaryRows + 1] = { text = "" }
    end
    if cfg.multiShowAnima then
        summaryRows[#summaryRows + 1] = { text = "|cffffcc00Gesamt Anima Missionen:|r " .. tostring(global.anima) }
        summaryRows[#summaryRows + 1] = { text = "" }
    end
    if cfg.multiShowCurrency then
        summaryRows[#summaryRows + 1] = { text = "|cffffcc00Waehrung gesamt:|r" }
        local curr = {}
        for _, c in pairs(global.currencies) do curr[#curr + 1] = c end
        table.sort(curr, function(a, b)
            if a.total ~= b.total then return a.total > b.total end
            return a.label < b.label
        end)
        if #curr == 0 then
            summaryRows[#summaryRows + 1] = { text = "  - keine" }
        else
            for _, c in ipairs(curr) do
                local iconText = ""
                if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
                    local ci = C_CurrencyInfo.GetCurrencyInfo(c.currencyID)
                    if ci and ci.iconFileID then
                        iconText = "|T" .. tostring(ci.iconFileID) .. ":14:14:0:0|t "
                    end
                end
                summaryRows[#summaryRows + 1] = {
                    text = "  - " .. iconText .. c.label .. ": " .. tostring(c.total),
                    tooltip = {
                        currencyID = c.currencyID,
                        quantity = c.total,
                        lines = {
                            c.label .. ": " .. tostring(c.total),
                        }
                    }
                }
            end
        end
    end

    if cfg.showMissionHighlight then
        local highlightList = {}
        for _, row in pairs(highlightAgg) do
            row.charSort = MRT.Config and MRT.Config.GetCharacterSortIndex and MRT.Config:GetCharacterSortIndex(row.charKey) or 9999
            row.rewardSort = MRT.Config and MRT.Config.GetRewardSortIndex and MRT.Config:GetRewardSortIndex(row.rewardKey) or 9999
            highlightList[#highlightList + 1] = row
        end
        table.sort(highlightList, function(a, b)
            if a.charSort ~= b.charSort then return a.charSort < b.charSort end
            if a.charKey ~= b.charKey then return a.charKey < b.charKey end
            if a.rewardSort ~= b.rewardSort then return a.rewardSort < b.rewardSort end
            return a.rewardKey < b.rewardKey
        end)

        highlightRows[#highlightRows + 1] = { text = "|cff00ccffHighlight Bereich|r" }
        if #highlightList == 0 then
            highlightRows[#highlightRows + 1] = { text = "  - keine Highlight-Treffer" }
            highlightRows[#highlightRows + 1] = { text = "  - Hinweis: highlightItemIDs/highlightCurrencyIDs in multiDashboardConfig setzen" }
        else
            for i, h in ipairs(highlightList) do
                if i > 12 then break end
                local rewardLabel = "ITEMS"
                local iconText = ""
                local tooltipPayload = {
                    lines = {
                        h.charKey .. " - " .. rewardLabel,
                        "Missionen: " .. tostring(h.missions),
                    }
                }
                if h.rewardKey == "currency" then
                    rewardLabel = "WAEHRUNG"
                    if h.sampleCurrencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
                        local ci = C_CurrencyInfo.GetCurrencyInfo(h.sampleCurrencyID)
                        if ci and ci.iconFileID then
                            iconText = "|T" .. tostring(ci.iconFileID) .. ":14:14:0:0|t "
                        end
                    end
                    tooltipPayload.currencyID = h.sampleCurrencyID
                    tooltipPayload.quantity = 1
                    tooltipPayload.lines = {
                        h.charKey .. " - " .. rewardLabel,
                        "Missionen: " .. tostring(h.missions),
                    }
                elseif h.sampleItemID then
                    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(h.sampleItemID)
                    if not tex and C_Item and C_Item.GetItemInfoInstant then
                        local _, _, _, _, _, _, _, _, _, instantTex = C_Item.GetItemInfoInstant(h.sampleItemID)
                        tex = instantTex
                    end
                    if tex then
                        iconText = "|T" .. tostring(tex) .. ":14:14:0:0|t "
                    end
                    tooltipPayload.itemID = h.sampleItemID
                end
                highlightRows[#highlightRows + 1] = {
                    text = "  - " .. h.charKey .. " - " .. iconText,
                    tooltip = tooltipPayload
                }
            end
        end
    else
        highlightRows[#highlightRows + 1] = { text = "|cff808080Highlight aus (Config)|r" }
    end

    local showStatusColors = cfg.showStatusColors
    for _, e in ipairs(entries) do
        local statusText = BuildStatusText(e.state, { timeLeftSeconds = e.timeLeftSeconds }, showStatusColors)
        local colorOpen, colorClose = GetStateColorCodes(e.state, showStatusColors)
        local missionNameText = colorOpen .. e.missionName .. colorClose
        listRows[#listRows + 1] = {
            text = string.format("%s - %s - %s - %s - %s", e.charKey, e.expansionLabel, missionNameText, statusText, e.rewardText),
            tooltip = e.tooltip,
        }
    end
    if #entries == 0 then
        listRows[#listRows + 1] = { text = "Keine Treffer fuer aktive Filter/Suche." }
    end

    return summaryRows, listRows, highlightRows
end

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
