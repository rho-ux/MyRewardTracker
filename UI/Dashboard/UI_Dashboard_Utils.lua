local addonName, MRT = ...

MRT.DashboardUtils = MRT.DashboardUtils or {}
local Utils = MRT.DashboardUtils

function Utils.GetColoredStateLabel(state, useColors)
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

function Utils.FormatMoney(copper)
    local value = tonumber(copper) or 0
    if value < 0 then
        value = 0
    end

    local gold = math.floor(value / 10000)
    local silver = math.floor((value % 10000) / 100)
    local bronze = value % 100

    return string.format(
        "%d|cffffd100g|r %d|cffffffffs|r %d|cffb87333c|r",
        gold,
        silver,
        bronze
    )
end

function Utils.FormatDuration(seconds)
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

function Utils.GetMissionRemainingText(mission, state)
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

    return Utils.FormatDuration(seconds)
end

function Utils.GetDebugRemainingText(mission, state)
    if state ~= "available" then
        return nil
    end

    local seconds = tonumber(mission and mission.durationSeconds)
    if not seconds or seconds <= 0 then
        seconds = 5400
    end

    return Utils.FormatDuration(seconds) .. " (test)"
end

function Utils.FormatRemainingLabel(remainingText)
    if not remainingText or remainingText == "" then
        return nil
    end

    if remainingText == "bereit" then
        return "|cff00ff00Rest: bereit|r"
    end

    return "|cffb0b0b0Rest: " .. remainingText .. "|r"
end

function Utils.ResolveItemData(reward)
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

function Utils.ResolveCurrencyData(reward)
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

local function RewardMatchesActiveFilter(reward, missionID)
    if not reward or not MRT.FilterConfig or not MRT.FilterConfig.GetActive then
        return false
    end

    local cfg = MRT.FilterConfig:GetActive()
    if type(cfg) ~= "table" then
        return false
    end

    local qty = tonumber(reward.quantity) or 0

    if reward.itemID and type(cfg.ItemWhitelist) == "table" and cfg.ItemWhitelist[reward.itemID] then
        return true
    end

    if reward.itemID and cfg.AnimaBypassFilter and MRT.Config and MRT.Config.IsAnimaItem and MRT.Config:IsAnimaItem(reward.itemID) then
        return true
    end

    if reward.currencyID == 0 then
        local minGold = tonumber(cfg.GoldMinimum) or 0
        if minGold > 0 and qty >= minGold then
            return true
        end
    elseif reward.currencyID then
        local minByCurrency = type(cfg.CurrencyMinimum) == "table" and tonumber(cfg.CurrencyMinimum[reward.currencyID]) or nil
        if minByCurrency and qty >= minByCurrency then
            return true
        end
    end

    if missionID and type(cfg.MissionWhitelist) == "table" and cfg.MissionWhitelist[missionID] then
        return true
    end

    return false
end

function Utils.BuildRewardPreview(mission, compactMode, missionID)
    if not mission or not mission.rewards then
        return nil
    end

    local parts = {}
    for idx, reward in ipairs(mission.rewards) do
        local qty = reward.quantity or 0
        local iconText = ""

        if reward.itemID then
            local _, _, itemIcon = Utils.ResolveItemData(reward)
            if itemIcon then
                iconText = "|T" .. tostring(itemIcon) .. ":14:14:0:0|t "
            end
            parts[#parts + 1] = {
                text = iconText .. "x" .. qty,
                isFilterHit = RewardMatchesActiveFilter(reward, missionID),
                index = idx,
            }
        elseif reward.currencyID == 0 then
            parts[#parts + 1] = {
                text = Utils.FormatMoney(qty),
                isFilterHit = RewardMatchesActiveFilter(reward, missionID),
                index = idx,
            }
        elseif reward.currencyID then
            local _, currencyIcon = Utils.ResolveCurrencyData(reward)
            if currencyIcon then
                iconText = "|T" .. tostring(currencyIcon) .. ":14:14:0:0|t "
            end
            parts[#parts + 1] = {
                text = iconText .. "x" .. qty,
                isFilterHit = RewardMatchesActiveFilter(reward, missionID),
                index = idx,
            }
        end
    end

    if #parts == 0 then
        return nil
    end

    table.sort(parts, function(a, b)
        if a.isFilterHit ~= b.isFilterHit then
            return a.isFilterHit and not b.isFilterHit
        end
        return (a.index or 0) < (b.index or 0)
    end)

    if compactMode then
        if #parts > 1 then
            return parts[1].text .. " |cffb0b0b0(+" .. (#parts - 1) .. ")|r"
        end
        return parts[1].text
    end

    local flat = {}
    for i = 1, #parts do
        flat[#flat + 1] = parts[i].text
    end

    return table.concat(flat, ", ")
end

function Utils.BuildRewardPriorityNote(mission, rewardKey)
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

function Utils.BuildRewardTooltipData(mission)
    if not mission or not mission.rewards then
        return nil
    end

    local payload = { lines = {} }
    for _, reward in ipairs(mission.rewards) do
        local qty = reward.quantity or 0
        if reward.itemID then
            local itemLink, itemName = Utils.ResolveItemData(reward)
            if not payload.itemLink and itemLink then
                payload.itemLink = itemLink
            end
            if not payload.itemID then
                payload.itemID = reward.itemID
            end
            payload.lines[#payload.lines + 1] = (itemLink or itemName or ("Item:" .. reward.itemID)) .. " x" .. qty
        elseif reward.currencyID == 0 then
            payload.lines[#payload.lines + 1] = "Gold " .. Utils.FormatMoney(qty)
        elseif reward.currencyID then
            local currencyName = Utils.ResolveCurrencyData(reward)
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

function Utils.GetMissionExpansionKey(mission)
    if not mission then
        return "unknown"
    end

    local followerTypeID = mission.followerTypeID
    if MRT.Config and MRT.Config.GetExpansionKeyByFollowerType then
        return MRT.Config:GetExpansionKeyByFollowerType(followerTypeID)
    end

    return "unknown"
end

function Utils.GetCharacterKey()
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

function Utils.GetExpansionLabel(expansionKey)
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Expansion then
        local label = MRT.Config.Labels.Expansion[expansionKey]
        if label and label ~= "" then
            return label
        end
    end
    return string.upper(expansionKey or "unknown")
end

function Utils.GetRewardLabel(rewardKey)
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Reward then
        local label = MRT.Config.Labels.Reward[rewardKey]
        if label and label ~= "" then
            return label
        end
    end
    return string.upper(rewardKey or "other")
end

function Utils.GetMissionItemGroupFlags(mission)
    local hasAnimaItem = false
    local hasRegularItem = false
    if not mission or type(mission.rewards) ~= "table" then
        return hasAnimaItem, hasRegularItem
    end

    if not MRT.Config or not MRT.Config.IsAnimaItem then
        for _, reward in ipairs(mission.rewards) do
            if reward.itemID then
                hasRegularItem = true
                break
            end
        end
        return hasAnimaItem, hasRegularItem
    end

    for _, reward in ipairs(mission.rewards) do
        if reward.itemID then
            if MRT.Config:IsAnimaItem(reward.itemID) then
                hasAnimaItem = true
            else
                hasRegularItem = true
            end
        end
    end

    return hasAnimaItem, hasRegularItem
end

function Utils.GetMissionPrimaryGroupKey(mission)
    local hasAnimaItem, hasRegularItem = Utils.GetMissionItemGroupFlags(mission)
    local hasCurrency = false
    local hasGold = false

    if mission and type(mission.rewards) == "table" then
        for _, reward in ipairs(mission.rewards) do
            if reward.currencyID == 0 then
                hasGold = true
            elseif reward.currencyID then
                hasCurrency = true
            end
        end
    end

    if hasAnimaItem then
        return "anima"
    end
    if hasRegularItem then
        return "item"
    end
    if hasCurrency then
        return "currency"
    end
    if hasGold then
        return "gold"
    end
    return "other"
end

function Utils.MissionAllowedByGroupToggles(groupKey, cfg)
    if groupKey == "gold" then
        return cfg.showGroupGold
    end
    if groupKey == "currency" then
        return cfg.showGroupCurrency
    end
    if groupKey == "item" then
        return cfg.showGroupItems
    end
    if groupKey == "anima" then
        return cfg.showGroupAnima
    end
    return true
end

function Utils.ShowRowTooltip(row)
    local data = row and row.data
    if not data or not data.tooltip then
        return
    end

    local tooltip = data.tooltip
    GameTooltip:SetOwner(row, "ANCHOR_CURSOR")

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

function Utils.HideRowTooltip()
    GameTooltip:Hide()
end
