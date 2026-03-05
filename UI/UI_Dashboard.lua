local addonName, MRT = ...

local Dashboard = {}
MRT.Dashboard = Dashboard

local frame
local lineCharacter
local lineAvailable
local lineReady
local lineRunning
local lineWQ
local listTitle
local listContent
local listScrollFrame
local listRows = {}
local optionSortDebug
local optionExpansionHeaders
local optionRewardHeaders
local optionStatusColors
local optionRewardDetails
local optionCompactList
local optionDebugForceRemaining
local fontSizeLabel
local summaryTitle
local summaryContent
local summaryRows = {}

local function GetColoredStateLabel(state, useColors)
    if not useColors then
        if state == "ready" then
            return "fertig"
        end
        if state == "running" then
            return "laeuft"
        end
        return "verfuegbar"
    end

    if state == "ready" then
        return "|cff00ff00fertig|r"
    end
    if state == "running" then
        return "|cff33aafflaeuft|r"
    end
    return "|cffffff00verfuegbar|r"
end

local function FormatMoney(copper)
    local value = tonumber(copper) or 0
    if value < 0 then
        value = 0
    end

    local gold = math.floor(value / 10000)
    local silver = math.floor((value % 10000) / 100)
    local bronze = value % 100

    return string.format("%dg %ds %dc", gold, silver, bronze)
end

local function FormatDuration(seconds)
    local value = tonumber(seconds) or 0
    if value < 0 then
        value = 0
    end

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

local function GetMissionRemainingText(mission, state)
    if state ~= "running" or not mission then
        return nil
    end

    local seconds = tonumber(mission.timeLeftSeconds)
    if not seconds and mission.endTime then
        seconds = tonumber(mission.endTime) - time()
    end

    if not seconds then
        return nil
    end

    if seconds <= 0 then
        return "bereit"
    end

    return FormatDuration(seconds)
end

local function GetDebugRemainingText(mission, state)
    if state ~= "available" then
        return nil
    end

    local seconds = tonumber(mission and mission.durationSeconds)
    if not seconds or seconds <= 0 then
        seconds = 5400
    end

    return FormatDuration(seconds) .. " (test)"
end

local function FormatRemainingLabel(remainingText)
    if not remainingText or remainingText == "" then
        return nil
    end

    if remainingText == "bereit" then
        return "|cff00ff00Rest: bereit|r"
    end

    return "|cffb0b0b0Rest: " .. remainingText .. "|r"
end

local function ResolveItemData(reward)
    if not reward then
        return nil, nil, nil
    end

    local itemID = reward.itemID
    local link = reward.itemLink
    local name = reward.name
    local icon = reward.icon

    if itemID then
        local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
        if itemLink and itemLink ~= "" then
            link = itemLink
        end
        if itemName and itemName ~= "" then
            name = itemName
        end
        if itemTexture then
            icon = itemTexture
        end

        if (not name or name == "") or not icon then
            local instantName, _, _, _, _, _, _, _, _, instantIcon = C_Item.GetItemInfoInstant(itemID)
            if instantName and instantName ~= "" and (not name or name == "") then
                name = instantName
            end
            if instantIcon and not icon then
                icon = instantIcon
            end
        end
    end

    if (not name or name == "") and itemID then
        name = "Item:" .. itemID
    end

    return link, name, icon
end

local function ResolveCurrencyData(reward)
    if not reward or not reward.currencyID then
        return nil, nil
    end

    local name = reward.name
    local icon = reward.icon
    local info = C_CurrencyInfo.GetCurrencyInfo(reward.currencyID)
    if info then
        if info.name and info.name ~= "" then
            name = info.name
        end
        if info.iconFileID then
            icon = info.iconFileID
        end
    end

    if not name or name == "" then
        name = "Currency:" .. reward.currencyID
    end

    return name, icon
end

local function BuildRewardPreview(mission, compactMode)
    if not mission or not mission.rewards then
        return nil
    end

    local parts = {}
    for _, reward in ipairs(mission.rewards) do
        local qty = reward.quantity or 0
        local iconText = ""

        if reward.itemID then
            local itemLink, itemName, itemIcon = ResolveItemData(reward)
            if itemIcon then
                iconText = "|T" .. tostring(itemIcon) .. ":14:14:0:0|t "
            end
            if itemLink and itemLink ~= "" then
                parts[#parts + 1] = iconText .. itemLink .. " x" .. qty
            else
                parts[#parts + 1] = iconText .. (itemName or ("Item:" .. reward.itemID)) .. " x" .. qty
            end
        elseif reward.currencyID == 0 then
            if reward.icon then
                iconText = "|T" .. tostring(reward.icon) .. ":14:14:0:0|t "
            end
            parts[#parts + 1] = iconText .. "Gold " .. FormatMoney(qty)
        elseif reward.currencyID then
            local name, currencyIcon = ResolveCurrencyData(reward)
            if currencyIcon then
                iconText = "|T" .. tostring(currencyIcon) .. ":14:14:0:0|t "
            end
            parts[#parts + 1] = iconText .. name .. " x" .. qty
        end
    end

    if #parts == 0 then
        return nil
    end

    if compactMode then
        if #parts > 1 then
            return parts[1] .. " |cffb0b0b0(+" .. (#parts - 1) .. ")|r"
        end
        return parts[1]
    end

    return table.concat(parts, ", ")
end

local function BuildRewardPriorityNote(mission, rewardKey)
    if not mission or not mission.rewards then
        return nil
    end

    local hasItem = false
    local hasCurrency = false
    local hasGold = false

    for _, reward in ipairs(mission.rewards) do
        if reward.itemID then
            hasItem = true
        elseif reward.currencyID == 0 then
            hasGold = true
        elseif reward.currencyID then
            hasCurrency = true
        end
    end

    local parts = {}
    if hasItem then parts[#parts + 1] = "item" end
    if hasCurrency then parts[#parts + 1] = "waehrung" end
    if hasGold then parts[#parts + 1] = "gold" end

    if #parts <= 1 then
        return nil
    end

    local groupLabel = string.upper(rewardKey or "other")
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Reward and MRT.Config.Labels.Reward[rewardKey] then
        groupLabel = MRT.Config.Labels.Reward[rewardKey]
    end

    return "mix(" .. table.concat(parts, "+") .. ") -> " .. groupLabel
end

local function BuildRewardTooltipData(mission)
    if not mission or not mission.rewards then
        return nil
    end

    local payload = { lines = {} }
    for _, reward in ipairs(mission.rewards) do
        local qty = reward.quantity or 0
        if reward.itemID then
            local itemLink, itemName = ResolveItemData(reward)
            if not payload.itemLink and itemLink then
                payload.itemLink = itemLink
            end
            if not payload.itemID then
                payload.itemID = reward.itemID
            end
            payload.lines[#payload.lines + 1] = (itemLink or itemName or ("Item:" .. reward.itemID)) .. " x" .. qty
        elseif reward.currencyID == 0 then
            payload.lines[#payload.lines + 1] = "Gold " .. FormatMoney(qty)
        elseif reward.currencyID then
            local currencyName = ResolveCurrencyData(reward)
            if not payload.itemLink and not payload.itemID and not payload.currencyID then
                payload.currencyID = reward.currencyID
                payload.quantity = qty
            end
            payload.lines[#payload.lines + 1] = (currencyName or ("Currency:" .. reward.currencyID)) .. " x" .. qty
        end
    end

    if #payload.lines == 0 then
        return nil
    end

    return payload
end

local function GetMissionExpansionKey(mission)
    if not mission then
        return "unknown"
    end

    local followerTypeID = mission.followerTypeID
    if MRT.Config and MRT.Config.GetExpansionKeyByFollowerType then
        return MRT.Config:GetExpansionKeyByFollowerType(followerTypeID)
    end

    return "unknown"
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

local function GetDashboardConfig()
    if MRT.Config and MRT.Config.GetDashboardConfig then
        return MRT.Config:GetDashboardConfig()
    end
    return {
        showSortDebug = true,
        showExpansionHeaders = true,
        showRewardHeaders = true,
        showStatusColors = true,
        showRewardDetails = true,
        compactList = false,
        fontSize = 13,
    }
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

local function GetRewardLabel(rewardKey)
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Reward then
        local label = MRT.Config.Labels.Reward[rewardKey]
        if label and label ~= "" then
            return label
        end
    end
    return string.upper(rewardKey or "other")
end

local function BuildAggregateRows(missionTotal, availableCount, runningCount, readyCount, totalGold, itemTotals, currencyTotals)
    local rows = {}
    local function add(text, tooltip)
        rows[#rows + 1] = { text = text, tooltip = tooltip }
    end

    add("|cffffcc00Missions-Uebersicht:|r")
    add("  - gefiltert gesamt: " .. (missionTotal or 0))
    add("  - verfuegbar: " .. (availableCount or 0))
    add("  - laeuft: " .. (runningCount or 0))
    add("  - fertig: " .. (readyCount or 0))
    add("")
    add("|cffffcc00Gesamt Gold Mission&WQ:|r " .. FormatMoney(totalGold))
    add("|cffb0b0b0(WQ aktuell Platzhalter bis WQ-Modul aktiv ist)|r")
    add("")
    add("|cffffcc00Items gesamt:|r")

    local items = {}
    for _, entry in pairs(itemTotals) do
        items[#items + 1] = entry
    end
    table.sort(items, function(a, b)
        if a.quantity ~= b.quantity then return a.quantity > b.quantity end
        return a.label < b.label
    end)

    if #items == 0 then
        add("  - keine")
    else
        for _, entry in ipairs(items) do
            local iconText = entry.icon and ("|T" .. tostring(entry.icon) .. ":14:14:0:0|t ") or ""
            add(
                "  - " .. iconText .. entry.label .. " x" .. entry.quantity,
                {
                    itemID = entry.itemID,
                    itemLink = entry.itemLink,
                    lines = { entry.label .. " x" .. entry.quantity }
                }
            )
        end
    end

    add("")
    add("|cffffcc00Waehrung gesamt:|r")
    local currencies = {}
    for _, entry in pairs(currencyTotals) do
        currencies[#currencies + 1] = entry
    end
    table.sort(currencies, function(a, b)
        if a.quantity ~= b.quantity then return a.quantity > b.quantity end
        return a.label < b.label
    end)

    if #currencies == 0 then
        add("  - keine")
    else
        for _, entry in ipairs(currencies) do
            local iconText = entry.icon and ("|T" .. tostring(entry.icon) .. ":14:14:0:0|t ") or ""
            add(
                "  - " .. iconText .. entry.label .. " x" .. entry.quantity,
                {
                    currencyID = entry.currencyID,
                    quantity = entry.quantity,
                    lines = { entry.label .. " x" .. entry.quantity }
                }
            )
        end
    end

    return rows
end

local function AppendTrackedCharacterRows(rows)
    rows[#rows + 1] = { text = "" }
    rows[#rows + 1] = { text = "|cffffcc00Multi-Char (tracked):|r" }

    local trackedRoot = MyRewardTrackerDB and MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked
    if type(trackedRoot) ~= "table" then
        rows[#rows + 1] = { text = "  - keine Daten" }
        return
    end

    local keys = {}
    for charKey in pairs(trackedRoot) do
        keys[#keys + 1] = charKey
    end

    table.sort(keys, function(a, b)
        local aSort = MRT.Config and MRT.Config.GetCharacterSortIndex and MRT.Config:GetCharacterSortIndex(a) or 9999
        local bSort = MRT.Config and MRT.Config.GetCharacterSortIndex and MRT.Config:GetCharacterSortIndex(b) or 9999
        if aSort ~= bSort then
            return aSort < bSort
        end
        return a < b
    end)

    if #keys == 0 then
        rows[#rows + 1] = { text = "  - keine Daten" }
        return
    end

    for _, charKey in ipairs(keys) do
        local tracked = trackedRoot[charKey]
        local s = tracked and tracked.summary or {}
        rows[#rows + 1] = {
            text = string.format(
                "  - %s | total:%d avail:%d run:%d ready:%d",
                charKey,
                s.filteredTotal or 0,
                s.available or 0,
                s.running or 0,
                s.ready or 0
            )
        }
    end
end

local function ShowRowTooltip(row)
    local data = row and row.data
    if not data or not data.tooltip then
        return
    end

    local tooltip = data.tooltip
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")

    if tooltip.itemLink then
        GameTooltip:SetHyperlink(tooltip.itemLink)
    elseif tooltip.itemID then
        GameTooltip:SetHyperlink("item:" .. tooltip.itemID)
    elseif tooltip.currencyID and GameTooltip.SetCurrencyByID then
        GameTooltip:SetCurrencyByID(tooltip.currencyID, tooltip.quantity or 0)
    else
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Belohnung")
    end

    if tooltip.lines then
        for _, line in ipairs(tooltip.lines) do
            GameTooltip:AddLine(line, 1, 1, 1, true)
        end
    end

    GameTooltip:Show()
end

local function HideRowTooltip()
    GameTooltip:Hide()
end

local function EnsureListRow(index)
    local row = listRows[index]
    if row then
        return row
    end

    row = CreateFrame("Button", nil, listContent)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * 18))
    row:RegisterForClicks("AnyUp")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", 0, 0)
    row.text:SetWidth(700)
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("TOP")

    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", HideRowTooltip)

    listRows[index] = row
    return row
end

local function RenderMissionRows(rows)
    for i, rowData in ipairs(rows) do
        local row = EnsureListRow(i)
        row.data = rowData
        row.text:SetText(rowData.text or "")
        row:Show()
    end

    for i = #rows + 1, #listRows do
        listRows[i].data = nil
        listRows[i]:Hide()
    end

    listContent:SetHeight(math.max(1, (#rows * 18) + 8))
end

local function EnsureSummaryRow(index)
    local row = summaryRows[index]
    if row then
        return row
    end

    row = CreateFrame("Button", nil, summaryContent)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * 18))
    row:RegisterForClicks("AnyUp")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", 0, 0)
    row.text:SetWidth(500)
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("TOP")

    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", HideRowTooltip)

    summaryRows[index] = row
    return row
end

local function RenderSummaryRows(rows)
    for i, rowData in ipairs(rows) do
        local row = EnsureSummaryRow(i)
        row.data = rowData
        row.text:SetText(rowData.text or "")
        row:Show()
    end

    for i = #rows + 1, #summaryRows do
        summaryRows[i].data = nil
        summaryRows[i]:Hide()
    end

    summaryContent:SetHeight(math.max(1, (#rows * 18) + 8))
end

local function ApplyDashboardFontSize(fontSize)
    local size = tonumber(fontSize) or 13
    if size < 10 then size = 10 end
    if size > 20 then size = 20 end

    local base = STANDARD_TEXT_FONT
    if lineCharacter then lineCharacter:SetFont(base, size, "") end
    if lineAvailable then lineAvailable:SetFont(base, size, "") end
    if lineReady then lineReady:SetFont(base, size, "") end
    if lineRunning then lineRunning:SetFont(base, size, "") end
    if lineWQ then lineWQ:SetFont(base, size, "") end
    if listTitle then listTitle:SetFont(base, size + 1, "") end
    if summaryTitle then summaryTitle:SetFont(base, size + 1, "") end

    for _, row in ipairs(listRows) do
        if row and row.text then
            row.text:SetFont(base, math.max(10, size - 1), "")
        end
    end

    for _, row in ipairs(summaryRows) do
        if row and row.text then
            row.text:SetFont(base, math.max(10, size - 1), "")
        end
    end

    if fontSizeLabel then
        fontSizeLabel:SetText("Schrift: " .. size)
    end
end

local function RefreshDashboard()
    if not frame then
        return
    end

    local summary = nil
    if MRT.Notifier and MRT.Notifier.GetSummaryCounts then
        summary = MRT.Notifier:GetSummaryCounts()
    end
    summary = summary or { available = 0, ready = 0, running = 0, wq = 0 }

    local dashboardCfg = GetDashboardConfig()
    local showSortDebug = dashboardCfg.showSortDebug
    local showExpansionHeaders = dashboardCfg.showExpansionHeaders
    local showRewardHeaders = dashboardCfg.showRewardHeaders
    local showStatusColors = dashboardCfg.showStatusColors
    local showRewardDetails = dashboardCfg.showRewardDetails
    local compactList = dashboardCfg.compactList
    local debugForceRemaining = dashboardCfg.debugForceRemaining
    local fontSize = dashboardCfg.fontSize or 13

    if optionSortDebug then optionSortDebug:SetChecked(showSortDebug) end
    if optionExpansionHeaders then optionExpansionHeaders:SetChecked(showExpansionHeaders) end
    if optionRewardHeaders then optionRewardHeaders:SetChecked(showRewardHeaders) end
    if optionStatusColors then optionStatusColors:SetChecked(showStatusColors) end
    if optionRewardDetails then optionRewardDetails:SetChecked(showRewardDetails) end
    if optionCompactList then optionCompactList:SetChecked(compactList) end
    if optionDebugForceRemaining then optionDebugForceRemaining:SetChecked(debugForceRemaining) end
    ApplyDashboardFontSize(fontSize)

    lineCharacter:SetText("Character: " .. GetCharacterKey())
    if showStatusColors then
        lineAvailable:SetText("|cffffff00Mission verfuegbar:|r " .. (summary.available or 0))
        lineReady:SetText("|cff00ff00Mission fertig:|r " .. (summary.ready or 0))
        lineRunning:SetText("|cff33aaffMission laeuft:|r " .. (summary.running or 0))
        lineWQ:SetText("|cffffff00WQ verfuegbar:|r " .. (summary.wq or 0))
    else
        lineAvailable:SetText("Mission verfuegbar: " .. (summary.available or 0))
        lineReady:SetText("Mission fertig: " .. (summary.ready or 0))
        lineRunning:SetText("Mission laeuft: " .. (summary.running or 0))
        lineWQ:SetText("WQ verfuegbar: " .. (summary.wq or 0))
    end

    local entries = {}
    local charData = MyRewardTrackerCharDB
    local shown = 0
    local totalGold = 0
    local itemTotals = {}
    local currencyTotals = {}

    if charData and charData.missionTable and MRT.FilterEngine then
        for missionID, mission in pairs(charData.missionTable) do
            if MRT.FilterEngine:CheckMission(missionID, mission) then
                shown = shown + 1
                local state = MRT.Config and MRT.Config.GetMissionState and MRT.Config:GetMissionState(mission) or "available"
                local expansionKey = GetMissionExpansionKey(mission)
                local rewardKey = MRT.Config and MRT.Config.GetMissionRewardKey and MRT.Config:GetMissionRewardKey(mission) or "other"
                local expansionSort = MRT.Config and MRT.Config.GetExpansionSortIndex and MRT.Config:GetExpansionSortIndex(expansionKey) or 9999
                local rewardSort = MRT.Config and MRT.Config.GetRewardSortIndex and MRT.Config:GetRewardSortIndex(rewardKey) or 9999

                if mission.rewards then
                    for _, reward in ipairs(mission.rewards) do
                        local qty = reward.quantity or 0
                        if reward.currencyID == 0 then
                            totalGold = totalGold + qty
                        elseif reward.itemID then
                            local itemLink, itemName, itemIcon = ResolveItemData(reward)
                            local key = reward.itemID
                            local label = itemLink or itemName or ("Item:" .. reward.itemID)
                            local row = itemTotals[key] or { label = label, quantity = 0, icon = itemIcon, itemID = reward.itemID, itemLink = itemLink }
                            row.quantity = row.quantity + qty
                            if not row.icon and itemIcon then row.icon = itemIcon end
                            if not row.itemLink and itemLink then row.itemLink = itemLink end
                            itemTotals[key] = row
                        elseif reward.currencyID then
                            local currencyName, currencyIcon = ResolveCurrencyData(reward)
                            local key = reward.currencyID
                            local label = currencyName or ("Currency:" .. reward.currencyID)
                            local row = currencyTotals[key] or { label = label, quantity = 0, icon = currencyIcon, currencyID = reward.currencyID }
                            row.quantity = row.quantity + qty
                            if not row.icon and currencyIcon then row.icon = currencyIcon end
                            currencyTotals[key] = row
                        end
                    end
                end

                entries[#entries + 1] = {
                    missionID = missionID,
                    missionName = mission.name or "Unknown",
                    state = state,
                    remainingText = GetMissionRemainingText(mission, state),
                    expansionKey = expansionKey,
                    rewardKey = rewardKey,
                    expansionSort = expansionSort,
                    rewardSort = rewardSort,
                    rewardPreview = BuildRewardPreview(mission, compactList),
                    rewardPriorityNote = BuildRewardPriorityNote(mission, rewardKey),
                    tooltip = BuildRewardTooltipData(mission),
                }

                if debugForceRemaining and not entries[#entries].remainingText then
                    entries[#entries].remainingText = GetDebugRemainingText(mission, state)
                end
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.expansionSort ~= b.expansionSort then return a.expansionSort < b.expansionSort end
        if a.rewardSort ~= b.rewardSort then return a.rewardSort < b.rewardSort end
        if a.missionName ~= b.missionName then return a.missionName < b.missionName end
        return a.missionID < b.missionID
    end)

    local rows = {}
    local lastExpansionKey = nil
    local lastRewardKey = nil
    for _, entry in ipairs(entries) do
        if showExpansionHeaders and lastExpansionKey ~= entry.expansionKey then
            rows[#rows + 1] = { text = "|cffffcc00== " .. GetExpansionLabel(entry.expansionKey) .. " ==|r" }
            lastRewardKey = nil
        elseif lastExpansionKey ~= entry.expansionKey then
            lastRewardKey = nil
        end

        if showRewardHeaders and lastRewardKey ~= entry.rewardKey then
            rows[#rows + 1] = { text = "|cffb0b0b0-- " .. GetRewardLabel(entry.rewardKey) .. " --|r" }
        end

        local line = "[" .. entry.missionID .. "] " .. entry.missionName .. " | " .. GetColoredStateLabel(entry.state, showStatusColors)
        local remainingLabel = FormatRemainingLabel(entry.remainingText)
        if remainingLabel then
            line = line .. " | " .. remainingLabel
        end
        if showRewardDetails and entry.rewardPreview then
            line = line .. " | " .. entry.rewardPreview
        end
        if showRewardDetails and entry.rewardPriorityNote then
            line = line .. " | |cffffcc00" .. entry.rewardPriorityNote .. "|r"
        end
        if showSortDebug then
            line = line .. " | " .. entry.expansionKey .. " | " .. entry.rewardKey
        end

        rows[#rows + 1] = {
            text = line,
            tooltip = entry.tooltip
        }

        lastExpansionKey = entry.expansionKey
        lastRewardKey = entry.rewardKey
    end

    listTitle:SetText("Gefilterte Missionen: " .. shown)
    RenderMissionRows(rows)
    local summaryRowsData = BuildAggregateRows(shown, summary.available or 0, summary.running or 0, summary.ready or 0, totalGold, itemTotals, currencyTotals)
    AppendTrackedCharacterRows(summaryRowsData)
    RenderSummaryRows(summaryRowsData)
    ApplyDashboardFontSize(fontSize)
end

local function CreateOptionToggle(parent, anchorPoint, x, y, labelText, initialValue, onChanged)
    local btn = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    btn:SetPoint(anchorPoint, x, y)
    btn:SetChecked(initialValue and true or false)
    btn:SetScript("OnClick", function(self)
        onChanged(self:GetChecked() and true or false)
    end)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", btn, "RIGHT", 2, 1)
    label:SetText(labelText)

    return btn
end

local function CreateDashboard()
    frame = CreateFrame("Frame", "MRT_DashboardFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1320, 620)
    frame:SetPoint("CENTER", 0, 60)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    table.insert(UISpecialFrames, "MRT_DashboardFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("MRT Character Dashboard")

    lineCharacter = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineCharacter:SetPoint("TOPLEFT", 16, -42)
    lineCharacter:SetJustifyH("LEFT")

    lineAvailable = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineAvailable:SetPoint("TOPLEFT", 16, -66)
    lineAvailable:SetJustifyH("LEFT")

    lineReady = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineReady:SetPoint("TOPLEFT", 16, -88)
    lineReady:SetJustifyH("LEFT")

    lineRunning = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineRunning:SetPoint("TOPLEFT", 16, -110)
    lineRunning:SetJustifyH("LEFT")

    lineWQ = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineWQ:SetPoint("TOPLEFT", 16, -132)
    lineWQ:SetJustifyH("LEFT")

    listTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listTitle:SetPoint("TOPLEFT", 16, -160)
    listTitle:SetJustifyH("LEFT")
    listTitle:SetText("Gefilterte Missionen: 0")

    summaryTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryTitle:SetPoint("TOPLEFT", 760, -42)
    summaryTitle:SetJustifyH("LEFT")
    summaryTitle:SetText("Zusammenfassung")

    local summaryScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    summaryScroll:SetPoint("TOPLEFT", 758, -64)
    summaryScroll:SetPoint("BOTTOMRIGHT", -34, 84)

    summaryContent = CreateFrame("Frame", nil, summaryScroll)
    summaryContent:SetSize(500, 380)
    summaryScroll:SetScrollChild(summaryContent)

    listScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    listScrollFrame:SetPoint("TOPLEFT", 14, -182)
    listScrollFrame:SetPoint("BOTTOMRIGHT", -560, 84)

    listContent = CreateFrame("Frame", nil, listScrollFrame)
    listContent:SetSize(700, 380)
    listScrollFrame:SetScrollChild(listContent)

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 24)
    refreshButton:SetPoint("BOTTOMLEFT", 14, 14)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        RefreshDashboard()
    end)

    local cfg = GetDashboardConfig()

    optionSortDebug = CreateOptionToggle(frame, "BOTTOMLEFT", 130, 16, "Sort-Debug anzeigen", cfg.showSortDebug, function(checked)
        cfg.showSortDebug = checked
        RefreshDashboard()
    end)

    optionExpansionHeaders = CreateOptionToggle(frame, "BOTTOMLEFT", 300, 16, "Erweiterungs-Header", cfg.showExpansionHeaders, function(checked)
        cfg.showExpansionHeaders = checked
        RefreshDashboard()
    end)

    optionRewardHeaders = CreateOptionToggle(frame, "BOTTOMLEFT", 130, 40, "Belohnungs-Header", cfg.showRewardHeaders, function(checked)
        cfg.showRewardHeaders = checked
        RefreshDashboard()
    end)

    optionStatusColors = CreateOptionToggle(frame, "BOTTOMLEFT", 300, 40, "Statusfarben", cfg.showStatusColors, function(checked)
        cfg.showStatusColors = checked
        RefreshDashboard()
    end)

    optionRewardDetails = CreateOptionToggle(frame, "BOTTOMLEFT", 130, 64, "Reward-Details in Liste", cfg.showRewardDetails, function(checked)
        cfg.showRewardDetails = checked
        RefreshDashboard()
    end)

    optionCompactList = CreateOptionToggle(frame, "BOTTOMLEFT", 300, 64, "Kompakte Liste", cfg.compactList, function(checked)
        cfg.compactList = checked
        RefreshDashboard()
    end)

    optionDebugForceRemaining = CreateOptionToggle(frame, "BOTTOMLEFT", 460, 40, "Restzeit-Test", cfg.debugForceRemaining, function(checked)
        cfg.debugForceRemaining = checked
        RefreshDashboard()
    end)

    local fontDown = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    fontDown:SetSize(28, 22)
    fontDown:SetPoint("BOTTOMLEFT", 460, 14)
    fontDown:SetText("A-")
    fontDown:SetScript("OnClick", function()
        if cfg.fontSize > 10 then
            cfg.fontSize = cfg.fontSize - 1
            RefreshDashboard()
        end
    end)

    local fontUp = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    fontUp:SetSize(28, 22)
    fontUp:SetPoint("LEFT", fontDown, "RIGHT", 4, 0)
    fontUp:SetText("A+")
    fontUp:SetScript("OnClick", function()
        if cfg.fontSize < 20 then
            cfg.fontSize = cfg.fontSize + 1
            RefreshDashboard()
        end
    end)

    fontSizeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontSizeLabel:SetPoint("LEFT", fontUp, "RIGHT", 8, 0)
    fontSizeLabel:SetText("Schrift: " .. tostring(cfg.fontSize or 13))

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)
end

function Dashboard:Toggle()
    if not frame then
        CreateDashboard()
    end

    if frame:IsShown() then
        frame:Hide()
        return
    end

    RefreshDashboard()
    frame:Show()
end

function Dashboard:Refresh()
    if frame and frame:IsShown() then
        RefreshDashboard()
    end
end

SLASH_MRTDASHBOARD1 = "/mrtdashboard"
SlashCmdList["MRTDASHBOARD"] = function()
    Dashboard:Toggle()
end

SLASH_MRTSORTDEBUG1 = "/mrtsortdebug"
SlashCmdList["MRTSORTDEBUG"] = function(msg)
    if not MRT.Config or not MRT.Config.GetDashboardConfig then
        print("|cffff0000[MRT]|r Dashboard config nicht verfuegbar.")
        return
    end

    local cfg = MRT.Config:GetDashboardConfig()
    local arg = string.lower((msg or ""):match("^%s*(.-)%s*$"))

    if arg == "on" then
        cfg.showSortDebug = true
    elseif arg == "off" then
        cfg.showSortDebug = false
    else
        cfg.showSortDebug = not cfg.showSortDebug
    end

    local stateText = cfg.showSortDebug and "AN" or "AUS"
    print("|cff00ff00[MRT]|r Sort-Debug: " .. stateText)

    if MRT.Dashboard and MRT.Dashboard.Refresh then
        MRT.Dashboard:Refresh()
    end
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtdashboard", "oeffnet/schliesst Charakter-Dashboard")
    MRT.RegisterHelpCommand("/mrtsortdebug on|off|toggle", "Sort-Debugspalten ein/aus")
end
