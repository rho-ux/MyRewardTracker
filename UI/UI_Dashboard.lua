local addonName, MRT = ...

local Dashboard = {}
MRT.Dashboard = Dashboard

local frame
local lineCharacter
local listTitle
local listContent
local listScrollFrame
local listRows = {}
local missionSummaryTitle
local missionSummaryContent
local missionSummaryRows = {}
local missionSummaryScroll
local wqSummaryTitle
local wqSummaryContent
local wqSummaryRows = {}
local wqSummaryScroll
local wqListTitle
local wqListContent
local wqListRows = {}
local wqListScroll
local hLine
local vLine

local Utils = MRT.DashboardUtils or {}
local SummaryBuilder = MRT.DashboardSummary or {}

local GetColoredStateLabel = Utils.GetColoredStateLabel
local FormatMoney = Utils.FormatMoney
local GetMissionRemainingText = Utils.GetMissionRemainingText
local GetDebugRemainingText = Utils.GetDebugRemainingText
local FormatRemainingLabel = Utils.FormatRemainingLabel
local ResolveItemData = Utils.ResolveItemData
local ResolveCurrencyData = Utils.ResolveCurrencyData
local BuildRewardPreview = Utils.BuildRewardPreview
local BuildRewardPriorityNote = Utils.BuildRewardPriorityNote
local BuildRewardTooltipData = Utils.BuildRewardTooltipData
local GetMissionExpansionKey = Utils.GetMissionExpansionKey
local GetCharacterKey = Utils.GetCharacterKey
local GetExpansionLabel = Utils.GetExpansionLabel
local GetRewardLabel = Utils.GetRewardLabel
local GetMissionPrimaryGroupKey = Utils.GetMissionPrimaryGroupKey
local MissionAllowedByGroupToggles = Utils.MissionAllowedByGroupToggles
local ShowRowTooltip = Utils.ShowRowTooltip
local HideRowTooltip = Utils.HideRowTooltip
local BuildAggregateRows = SummaryBuilder.BuildAggregateRows

local function SetupRowText(fs)
    if not fs then return end
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    if fs.SetWordWrap then fs:SetWordWrap(false) end
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
    if fs.SetIndentedWordWrap then fs:SetIndentedWordWrap(false) end
    if fs.SetMaxLines then fs:SetMaxLines(1) end
end

local function SetRowsTextWidth(rows, width)
    local w = math.max(220, tonumber(width) or 220)
    for _, row in ipairs(rows or {}) do
        if row and row.text then
            row.text:SetWidth(w)
        end
    end
end

local function HideScrollBar(scrollFrame)
    if not scrollFrame then return end
    local sb = scrollFrame.ScrollBar
    if sb then
        sb:Hide()
        sb.Show = function() end
    end
end

local function EnableWheelScroll(scrollFrame, step)
    if not scrollFrame then return end
    local delta = step or 24
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, d)
        local current = self:GetVerticalScroll() or 0
        local _, maxV = self:GetVerticalScrollRange()
        local nextV = current - (d * delta)
        if nextV < 0 then nextV = 0 end
        if maxV and nextV > maxV then nextV = maxV end
        self:SetVerticalScroll(nextV)
    end)
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
        lineHeight = 18,
        headerStyle = "normal",
        splitRatio = 50,
        showMissionHighlight = true,
        fontSize = 13,
    }
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
    row.text:SetWidth(960)
    SetupRowText(row.text)

    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", HideRowTooltip)

    listRows[index] = row
    return row
end

local function RenderMissionRows(rows)
    local cfg = GetDashboardConfig()
    local lineHeight = tonumber(cfg.lineHeight) or 18
    if lineHeight < 16 then lineHeight = 16 end
    if lineHeight > 32 then lineHeight = 32 end
    for i, rowData in ipairs(rows) do
        local row = EnsureListRow(i)
        row:SetHeight(lineHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((i - 1) * lineHeight))
        row:SetPoint("TOPRIGHT", 0, -((i - 1) * lineHeight))
        row.data = rowData
        row.text:SetText(rowData.text or "")
        row:Show()
    end

    for i = #rows + 1, #listRows do
        listRows[i].data = nil
        listRows[i]:Hide()
    end

    listContent:SetHeight(math.max(1, (#rows * lineHeight) + 8))
end

local function EnsureMissionSummaryRow(index)
    local row = missionSummaryRows[index]
    if row then
        return row
    end

    row = CreateFrame("Button", nil, missionSummaryContent)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * 18))
    row:RegisterForClicks("AnyUp")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", 0, 0)
    row.text:SetWidth(960)
    SetupRowText(row.text)

    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", HideRowTooltip)

    missionSummaryRows[index] = row
    return row
end

local function RenderMissionSummaryRows(rows)
    local cfg = GetDashboardConfig()
    local lineHeight = tonumber(cfg.lineHeight) or 18
    if lineHeight < 16 then lineHeight = 16 end
    if lineHeight > 32 then lineHeight = 32 end
    for i, rowData in ipairs(rows) do
        local row = EnsureMissionSummaryRow(i)
        row:SetHeight(lineHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((i - 1) * lineHeight))
        row:SetPoint("TOPRIGHT", 0, -((i - 1) * lineHeight))
        row.data = rowData
        row.text:SetText(rowData.text or "")
        row:Show()
    end

    for i = #rows + 1, #missionSummaryRows do
        missionSummaryRows[i].data = nil
        missionSummaryRows[i]:Hide()
    end

    missionSummaryContent:SetHeight(math.max(1, (#rows * lineHeight) + 8))
end

local function EnsureWQSummaryRow(index)
    local row = wqSummaryRows[index]
    if row then
        return row
    end

    row = CreateFrame("Button", nil, wqSummaryContent)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * 18))
    row:RegisterForClicks("AnyUp")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", 0, 0)
    row.text:SetWidth(960)
    SetupRowText(row.text)

    wqSummaryRows[index] = row
    return row
end

local function RenderWQSummaryRows(rows)
    local cfg = GetDashboardConfig()
    local lineHeight = tonumber(cfg.lineHeight) or 18
    if lineHeight < 16 then lineHeight = 16 end
    if lineHeight > 32 then lineHeight = 32 end
    for i, rowData in ipairs(rows) do
        local row = EnsureWQSummaryRow(i)
        row:SetHeight(lineHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((i - 1) * lineHeight))
        row:SetPoint("TOPRIGHT", 0, -((i - 1) * lineHeight))
        row.data = rowData
        row.text:SetText(rowData.text or "")
        row:Show()
    end

    for i = #rows + 1, #wqSummaryRows do
        wqSummaryRows[i].data = nil
        wqSummaryRows[i]:Hide()
    end

    wqSummaryContent:SetHeight(math.max(1, (#rows * lineHeight) + 8))
end

local function EnsureWQListRow(index)
    local row = wqListRows[index]
    if row then
        return row
    end

    row = CreateFrame("Button", nil, wqListContent)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * 18))
    row:RegisterForClicks("AnyUp")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", 0, 0)
    row.text:SetWidth(960)
    SetupRowText(row.text)

    wqListRows[index] = row
    return row
end

local function RenderWQListRows(rows)
    local cfg = GetDashboardConfig()
    local lineHeight = tonumber(cfg.lineHeight) or 18
    if lineHeight < 16 then lineHeight = 16 end
    if lineHeight > 32 then lineHeight = 32 end
    for i, rowData in ipairs(rows) do
        local row = EnsureWQListRow(i)
        row:SetHeight(lineHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((i - 1) * lineHeight))
        row:SetPoint("TOPRIGHT", 0, -((i - 1) * lineHeight))
        row.data = rowData
        row.text:SetText(rowData.text or "")
        row:Show()
    end

    for i = #rows + 1, #wqListRows do
        wqListRows[i].data = nil
        wqListRows[i]:Hide()
    end

    wqListContent:SetHeight(math.max(1, (#rows * lineHeight) + 8))
end

local function ApplyDashboardFontSize(fontSize)
    local size = tonumber(fontSize) or 13
    if size < 10 then size = 10 end
    if size > 20 then size = 20 end
    local cfg = GetDashboardConfig()
    local headerExtra = (cfg.headerStyle == "emphasis") and 3 or 1

    local base = STANDARD_TEXT_FONT
    if lineCharacter then lineCharacter:SetFont(base, size, "") end
    if listTitle then listTitle:SetFont(base, size + headerExtra, "") end
    if missionSummaryTitle then missionSummaryTitle:SetFont(base, size + headerExtra, "") end
    if wqSummaryTitle then wqSummaryTitle:SetFont(base, size + headerExtra, "") end
    if wqListTitle then wqListTitle:SetFont(base, size + headerExtra, "") end

    for _, row in ipairs(listRows) do
        if row and row.text then
            row.text:SetFont(base, math.max(10, size - 1), "")
        end
    end

    for _, row in ipairs(missionSummaryRows) do
        if row and row.text then
            row.text:SetFont(base, math.max(10, size - 1), "")
        end
    end

    for _, row in ipairs(wqSummaryRows) do
        if row and row.text then
            row.text:SetFont(base, math.max(10, size - 1), "")
        end
    end

    for _, row in ipairs(wqListRows) do
        if row and row.text then
            row.text:SetFont(base, math.max(10, size - 1), "")
        end
    end

end

local function ApplyDashboardLayout(cfg)
    if not frame then
        return
    end
    local ratio = tonumber(cfg.splitRatio) or 50
    if ratio < 35 then ratio = 35 end
    if ratio > 65 then ratio = 65 end

    local frameW = 1560
    local leftW = math.floor((frameW - 34) * (ratio / 100))
    local rightW = (frameW - 34) - leftW
    local leftX = 14
    local rightX = 14 + leftW + 22
    local topY = -92
    local topH = 236
    local bottomY = -376
    local bottomH = 460

    if missionSummaryTitle then
        missionSummaryTitle:ClearAllPoints()
        missionSummaryTitle:SetPoint("TOPLEFT", leftX + 2, -70)
    end
    if wqSummaryTitle then
        wqSummaryTitle:ClearAllPoints()
        wqSummaryTitle:SetPoint("TOPLEFT", rightX + 2, -70)
    end
    if listTitle then
        listTitle:ClearAllPoints()
        listTitle:SetPoint("TOPLEFT", leftX + 2, -354)
    end
    if wqListTitle then
        wqListTitle:ClearAllPoints()
        wqListTitle:SetPoint("TOPLEFT", rightX + 2, -354)
    end

    if missionSummaryScroll then
        missionSummaryScroll:ClearAllPoints()
        missionSummaryScroll:SetPoint("TOPLEFT", leftX, topY)
        missionSummaryScroll:SetSize(leftW, topH)
    end
    if wqSummaryScroll then
        wqSummaryScroll:ClearAllPoints()
        wqSummaryScroll:SetPoint("TOPLEFT", rightX, topY)
        wqSummaryScroll:SetSize(rightW, topH)
    end
    if listScrollFrame then
        listScrollFrame:ClearAllPoints()
        listScrollFrame:SetPoint("TOPLEFT", leftX, bottomY)
        listScrollFrame:SetSize(leftW, bottomH)
    end
    if wqListScroll then
        wqListScroll:ClearAllPoints()
        wqListScroll:SetPoint("TOPLEFT", rightX, bottomY)
        wqListScroll:SetSize(rightW, bottomH)
    end

    if missionSummaryContent then missionSummaryContent:SetSize(math.max(520, leftW - 40), topH) end
    if wqSummaryContent then wqSummaryContent:SetSize(math.max(520, rightW - 40), topH) end
    if listContent then listContent:SetSize(math.max(520, leftW - 40), bottomH) end
    if wqListContent then wqListContent:SetSize(math.max(520, rightW - 40), bottomH) end

    local leftTextW = math.max(220, (listContent and listContent:GetWidth() or leftW) - 20)
    local rightTextW = math.max(220, (wqListContent and wqListContent:GetWidth() or rightW) - 20)
    SetRowsTextWidth(listRows, leftTextW)
    SetRowsTextWidth(missionSummaryRows, leftTextW)
    SetRowsTextWidth(wqSummaryRows, rightTextW)
    SetRowsTextWidth(wqListRows, rightTextW)

    if hLine then
        hLine:ClearAllPoints()
        hLine:SetPoint("LEFT", 12, 0)
        hLine:SetPoint("RIGHT", -12, 0)
        hLine:SetPoint("TOP", 0, -344)
    end
    if vLine then
        vLine:ClearAllPoints()
        vLine:SetPoint("TOPLEFT", frame, "TOPLEFT", rightX - 6, -64)
        vLine:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", rightX - 6, 8)
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
    local wqCfg = MRT.Config and MRT.Config.GetWorldQuestConfig and MRT.Config:GetWorldQuestConfig() or {}
    local showSortDebug = dashboardCfg.showSortDebug
    local showExpansionHeaders = dashboardCfg.showExpansionHeaders
    local showRewardHeaders = dashboardCfg.showRewardHeaders
    local showStatusColors = dashboardCfg.showStatusColors
    local showRewardDetails = dashboardCfg.showRewardDetails
    local compactList = dashboardCfg.compactList
    local debugForceRemaining = dashboardCfg.debugForceRemaining
    local showGroupGold = dashboardCfg.showGroupGold
    local showGroupCurrency = dashboardCfg.showGroupCurrency
    local showGroupItems = dashboardCfg.showGroupItems
    local showGroupAnima = dashboardCfg.showGroupAnima
    local fontSize = dashboardCfg.fontSize or 13

    local multiCfg = MRT.Config and MRT.Config.GetMultiDashboardConfig and MRT.Config:GetMultiDashboardConfig() or {}
    local highlightItemIDs = {}
    local highlightCurrencyIDs = {}
    local highlightMissionIDs = {}
    local function mergeBoolMap(dst, src)
        if type(src) ~= "table" then
            return
        end
        for k, v in pairs(src) do
            local id = tonumber(k)
            if id and id > 0 and v ~= false then
                dst[id] = true
            end
        end
    end
    mergeBoolMap(highlightItemIDs, multiCfg.highlightItemIDs)
    mergeBoolMap(highlightCurrencyIDs, multiCfg.highlightCurrencyIDs)
    mergeBoolMap(highlightItemIDs, dashboardCfg.highlightItemIDs)
    mergeBoolMap(highlightCurrencyIDs, dashboardCfg.highlightCurrencyIDs)
    mergeBoolMap(highlightMissionIDs, dashboardCfg.highlightMissionIDs)

    ApplyDashboardLayout(dashboardCfg)
    ApplyDashboardFontSize(fontSize)

    lineCharacter:SetText("Charakter: " .. GetCharacterKey())
    local entries = {}
    local charData = MyRewardTrackerCharDB
    local shown = 0
    local totalGold = 0
    local totalGoldActive = 0
    local totalAnima = 0
    local totalAnimaActive = 0
    local itemTotals = {}
    local currencyTotals = {}

    if charData and charData.missionTable and MRT.FilterEngine then
        for missionID, mission in pairs(charData.missionTable) do
            if MRT.FilterEngine:CheckMission(missionID, mission) then
                local state = MRT.Config and MRT.Config.GetMissionState and MRT.Config:GetMissionState(mission) or "available"
                local expansionKey = GetMissionExpansionKey(mission)
                local rewardKey = GetMissionPrimaryGroupKey(mission)
                local highlightKind = nil
                local highlightID = nil
                if highlightMissionIDs[missionID] then
                    highlightKind = "mission"
                    highlightID = missionID
                end
                local visibleByGroup = MissionAllowedByGroupToggles(rewardKey, dashboardCfg)
                if not visibleByGroup then
                    -- Gruppe ausgeblendet (Gold/Waehrung/Items/Anima).
                else
                    shown = shown + 1
                    local isActiveState = (state == "running" or state == "ready")
                    local expansionSort = MRT.Config and MRT.Config.GetExpansionSortIndex and MRT.Config:GetExpansionSortIndex(expansionKey) or 9999
                    local rewardSort = MRT.Config and MRT.Config.GetRewardSortIndex and MRT.Config:GetRewardSortIndex(rewardKey) or 9999

                    if mission.rewards then
                        for _, reward in ipairs(mission.rewards) do
                            local qty = reward.quantity or 0
                            if reward.currencyID == 0 then
                                totalGold = totalGold + qty
                                if isActiveState then
                                    totalGoldActive = totalGoldActive + qty
                                end
                            elseif reward.itemID then
                                if not highlightKind and highlightItemIDs[reward.itemID] then
                                    highlightKind = "item"
                                    highlightID = reward.itemID
                                end
                                local itemLink, itemName, itemIcon = ResolveItemData(reward)
                                local key = reward.itemID
                                local label = itemLink or itemName or ("Item:" .. reward.itemID)
                                local isAnima = MRT.Config and MRT.Config.IsAnimaItem and MRT.Config:IsAnimaItem(reward.itemID)
                                if not isAnima then
                                    local row = itemTotals[key] or { label = label, quantity = 0, icon = itemIcon, itemID = reward.itemID, itemLink = itemLink }
                                    row.quantity = row.quantity + qty
                                    if not row.icon and itemIcon then row.icon = itemIcon end
                                    if not row.itemLink and itemLink then row.itemLink = itemLink end
                                    itemTotals[key] = row
                                end
                                if MRT.Config and MRT.Config.GetAnimaValue then
                                    local animaValue = MRT.Config:GetAnimaValue(reward.itemID)
                                    if animaValue > 0 then
                                        local gain = (animaValue * qty)
                                        totalAnima = totalAnima + gain
                                        if isActiveState then
                                            totalAnimaActive = totalAnimaActive + gain
                                        end
                                    end
                                end
                            elseif reward.currencyID then
                                if not highlightKind and highlightCurrencyIDs[reward.currencyID] then
                                    highlightKind = "currency"
                                    highlightID = reward.currencyID
                                end
                                local currencyName, currencyIcon = ResolveCurrencyData(reward)
                                local key = reward.currencyID
                                local label = currencyName or ("Currency:" .. reward.currencyID)
                                local row = currencyTotals[key] or { label = label, total = 0, active = 0, icon = currencyIcon, currencyID = reward.currencyID }
                                row.total = row.total + qty
                                if isActiveState then
                                    row.active = row.active + qty
                                end
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
                        rewardPreview = BuildRewardPreview(mission, compactList, missionID),
                        rewardPriorityNote = BuildRewardPriorityNote(mission, rewardKey),
                        tooltip = BuildRewardTooltipData(mission),
                        isHighlight = (highlightKind ~= nil),
                        highlightKind = highlightKind,
                        highlightID = highlightID,
                    }

                    if debugForceRemaining and not entries[#entries].remainingText then
                        entries[#entries].remainingText = GetDebugRemainingText(mission, state)
                    end
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
    local charKey = GetCharacterKey()
    for _, entry in ipairs(entries) do
        local statusColorOpen = ""
        local statusColorClose = ""
        if showStatusColors then
            if entry.state == "ready" then
                statusColorOpen = "|cff00ff00"
            elseif entry.state == "running" then
                statusColorOpen = "|cff33aaff"
            else
                statusColorOpen = "|cffffff00"
            end
            statusColorClose = "|r"
        end

        local statusText = "verfuegbar"
        if entry.state == "ready" then
            statusText = "fertig"
        elseif entry.state == "running" then
            if entry.remainingText and entry.remainingText ~= "" then
                statusText = "Rest: " .. entry.remainingText
            else
                statusText = "Rest: ?"
            end
        end

        local rewardLabel = GetRewardLabel(entry.rewardKey)
        local rewardText = entry.rewardPreview or "keine Belohnung"
        if not showRewardDetails then
            rewardText = rewardLabel
        end
        local missionNameText = statusColorOpen .. entry.missionName .. statusColorClose
        local statusDisplay = statusColorOpen .. statusText .. statusColorClose
        local expansionLabel = GetExpansionLabel(entry.expansionKey)
        local parts = { charKey }
        if showExpansionHeaders then
            parts[#parts + 1] = expansionLabel
        end
        if showRewardHeaders then
            parts[#parts + 1] = rewardLabel
        end
        parts[#parts + 1] = missionNameText
        parts[#parts + 1] = statusDisplay
        parts[#parts + 1] = rewardText
        local line = table.concat(parts, " - ")

        rows[#rows + 1] = {
            text = line,
            tooltip = entry.tooltip
        }
    end

    listTitle:SetText("Missionen")
    RenderMissionRows(rows)
    local summaryRowsData = BuildAggregateRows(totalGoldActive, totalGold, totalAnimaActive, totalAnima, currencyTotals, dashboardCfg, entries)
    RenderMissionSummaryRows(summaryRowsData)

    local wqEnabled = wqCfg.enabled and true or false
    local wqShowOnChar = wqCfg.showOnCharacterDashboard and true or false
    local wqTrackAnima = (wqCfg.trackAnima ~= false)
    local wqGoldMin = tonumber(wqCfg.goldMinimum) or 0
    if wqGoldMin < 0 then wqGoldMin = 0 end
    local wqZoneCount = 0
    if type(wqCfg.zoneWhitelist) == "table" then
        for _ in pairs(wqCfg.zoneWhitelist) do wqZoneCount = wqZoneCount + 1 end
    end
    local wqBlacklistCount = 0
    if type(wqCfg.questBlacklist) == "table" then
        for _ in pairs(wqCfg.questBlacklist) do wqBlacklistCount = wqBlacklistCount + 1 end
    end

    if not wqShowOnChar then
        local wqSummaryRowsData = {
            { text = "|cffffcc00WQ-Zusammenfassung:|r" },
            { text = "  - Anzeige im Char-Dashboard: |cffff5555AUS|r" },
            { text = "  - WQ Modul aktiv: " .. (wqEnabled and "|cff00ff00AN|r" or "|cffff5555AUS|r") },
            { text = "|cffb0b0b0(Option in Config aktivieren: WQ im Char-Dashboard)|r" },
        }
        RenderWQSummaryRows(wqSummaryRowsData)
        RenderWQListRows({
            { text = "|cff808080WQ-Bereich ausgeblendet (Config)|r" },
        })
    else
        local wqSummaryRowsData = {
            { text = "|cffffcc00WQ-Zusammenfassung:|r" },
            { text = "  - verfuegbar: " .. tostring(summary.wq or 0) },
            { text = "  - WQ Modul aktiv: " .. (wqEnabled and "|cff00ff00AN|r" or "|cffff5555AUS|r") },
            { text = "  - Im Char-Dashboard: |cff00ff00AN|r" },
            { text = "  - WQ GoldMinimum: " .. tostring(math.floor(wqGoldMin)) },
            { text = "  - WQ Anima Tracking: " .. (wqTrackAnima and "|cff00ff00AN|r" or "|cffff5555AUS|r") },
            { text = "  - WQ ZoneWhitelist: " .. tostring(wqZoneCount) .. " IDs" },
            { text = "  - WQ QuestBlacklist: " .. tostring(wqBlacklistCount) .. " IDs" },
            { text = "|cffb0b0b0(Datenfluss aus Config aktiv; Scanner folgt spaeter)|r" },
        }
        RenderWQSummaryRows(wqSummaryRowsData)

        local wqListRowsData = {
            { text = "|cffffcc00-- WQ LISTE (platzhalter) --|r" },
            { text = "  - Scanner-Status: " .. (wqEnabled and "vorbereitet (noch kein aktiver Scan)" or "deaktiviert in Config") },
            { text = "  - Char-Dashboard Anzeige: aktiviert" },
            { text = "  - Goldfilter: ab " .. tostring(math.floor(wqGoldMin)) },
            { text = "  - Anima-Tracking: " .. (wqTrackAnima and "AN" or "AUS") },
            { text = "" },
            { text = "|cffffcc00-- WQ ZONEN (Whitelist) --|r" },
        }
        if wqZoneCount == 0 then
            wqListRowsData[#wqListRowsData + 1] = { text = "  - keine IDs gesetzt" }
        else
            local shownZones = 0
            for mapID, enabled in pairs(wqCfg.zoneWhitelist or {}) do
                if enabled and shownZones < 12 then
                    wqListRowsData[#wqListRowsData + 1] = { text = "  - mapID " .. tostring(mapID) }
                    shownZones = shownZones + 1
                end
            end
            if wqZoneCount > shownZones then
                wqListRowsData[#wqListRowsData + 1] = { text = "  - ... +" .. tostring(wqZoneCount - shownZones) .. " weitere" }
            end
        end
        wqListRowsData[#wqListRowsData + 1] = { text = "" }
        wqListRowsData[#wqListRowsData + 1] = { text = "|cffffcc00-- WQ QUEST BLACKLIST --|r" }
        if wqBlacklistCount == 0 then
            wqListRowsData[#wqListRowsData + 1] = { text = "  - keine IDs gesetzt" }
        else
            local shownQ = 0
            for questID, enabled in pairs(wqCfg.questBlacklist or {}) do
                if enabled and shownQ < 12 then
                    wqListRowsData[#wqListRowsData + 1] = { text = "  - questID " .. tostring(questID) }
                    shownQ = shownQ + 1
                end
            end
            if wqBlacklistCount > shownQ then
                wqListRowsData[#wqListRowsData + 1] = { text = "  - ... +" .. tostring(wqBlacklistCount - shownQ) .. " weitere" }
            end
        end
        RenderWQListRows(wqListRowsData)
    end
    ApplyDashboardFontSize(fontSize)
end

local function CreateDashboard()
    frame = CreateFrame("Frame", "MRT_DashboardFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1560, 860)
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

    missionSummaryTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    missionSummaryTitle:SetPoint("TOPLEFT", 16, -70)
    missionSummaryTitle:SetJustifyH("LEFT")
    missionSummaryTitle:SetText("Zusammenfassung Missionen")

    wqSummaryTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wqSummaryTitle:SetPoint("TOPLEFT", 790, -70)
    wqSummaryTitle:SetJustifyH("LEFT")
    wqSummaryTitle:SetText("Zusammenfassung WorldQuest")

    listTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listTitle:SetPoint("TOPLEFT", 16, -354)
    listTitle:SetJustifyH("LEFT")
    listTitle:SetText("Missionen")

    wqListTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wqListTitle:SetPoint("TOPLEFT", 790, -354)
    wqListTitle:SetJustifyH("LEFT")
    wqListTitle:SetText("WorldQuest")

    missionSummaryScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    missionSummaryScroll:SetPoint("TOPLEFT", 14, -92)
    missionSummaryScroll:SetSize(740, 236)

    missionSummaryContent = CreateFrame("Frame", nil, missionSummaryScroll)
    missionSummaryContent:SetSize(700, 236)
    missionSummaryScroll:SetScrollChild(missionSummaryContent)
    HideScrollBar(missionSummaryScroll)
    EnableWheelScroll(missionSummaryScroll, 24)

    wqSummaryScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    wqSummaryScroll:SetPoint("TOPLEFT", 788, -92)
    wqSummaryScroll:SetSize(740, 236)

    wqSummaryContent = CreateFrame("Frame", nil, wqSummaryScroll)
    wqSummaryContent:SetSize(700, 236)
    wqSummaryScroll:SetScrollChild(wqSummaryContent)
    HideScrollBar(wqSummaryScroll)
    EnableWheelScroll(wqSummaryScroll, 24)

    listScrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    listScrollFrame:SetPoint("TOPLEFT", 14, -376)
    listScrollFrame:SetSize(740, 460)

    listContent = CreateFrame("Frame", nil, listScrollFrame)
    listContent:SetSize(700, 460)
    listScrollFrame:SetScrollChild(listContent)
    HideScrollBar(listScrollFrame)
    EnableWheelScroll(listScrollFrame, 28)

    wqListScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    wqListScroll:SetPoint("TOPLEFT", 788, -376)
    wqListScroll:SetSize(740, 460)

    wqListContent = CreateFrame("Frame", nil, wqListScroll)
    wqListContent:SetSize(700, 460)
    wqListScroll:SetScrollChild(wqListContent)
    HideScrollBar(wqListScroll)
    EnableWheelScroll(wqListScroll, 28)

    hLine = frame:CreateTexture(nil, "ARTWORK")
    hLine:SetColorTexture(0, 0, 0, 0)
    hLine:SetHeight(2)
    hLine:SetPoint("LEFT", 12, 0)
    hLine:SetPoint("RIGHT", -12, 0)
    hLine:SetPoint("TOP", 0, -344)

    vLine = frame:CreateTexture(nil, "ARTWORK")
    vLine:SetColorTexture(0, 0, 0, 0)
    vLine:SetWidth(2)
    vLine:SetPoint("TOP", 0, -64)
    vLine:SetPoint("BOTTOM", 0, 8)

    local buttonY = 16
    local buttonGap = 12

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 24)
    refreshButton:SetPoint("BOTTOMLEFT", 16, buttonY)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        RefreshDashboard()
    end)

    local configButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    configButton:SetSize(100, 24)
    configButton:SetPoint("LEFT", refreshButton, "RIGHT", buttonGap, 0)
    configButton:SetText("Config")
    configButton:SetScript("OnClick", function()
        if MRT.ConfigDebug and MRT.ConfigDebug.Toggle then
            MRT.ConfigDebug.Toggle()
        end
    end)

    local switchButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    switchButton:SetSize(100, 24)
    switchButton:SetPoint("LEFT", configButton, "RIGHT", buttonGap, 0)
    switchButton:SetText("Multi-Char")
    switchButton:SetScript("OnClick", function()
        Dashboard:Hide()
        if MRT.MultiDebug and MRT.MultiDebug.Show then
            MRT.MultiDebug:Show()
        elseif MRT.MultiDebug and MRT.MultiDebug.Toggle then
            MRT.MultiDebug:Toggle()
        end
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)
end

function Dashboard:Show()
    if not frame then
        CreateDashboard()
    end
    RefreshDashboard()
    frame:Show()
end

function Dashboard:Hide()
    if frame and frame:IsShown() then
        frame:Hide()
    end
end

function Dashboard:Toggle()
    if frame and frame:IsShown() then
        Dashboard:Hide()
        return
    end

    Dashboard:Show()
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
