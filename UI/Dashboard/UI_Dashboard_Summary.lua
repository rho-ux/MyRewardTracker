local addonName, MRT = ...

MRT.DashboardSummary = MRT.DashboardSummary or {}
local Summary = MRT.DashboardSummary
local Utils = MRT.DashboardUtils or {}

function Summary.BuildAggregateRows(goldActive, goldTotal, animaActive, animaTotal, currencyTotals, cfg, entries)
    local rows = {}
    local function add(text, tooltip)
        rows[#rows + 1] = { text = text, tooltip = tooltip }
    end

    if cfg.showGroupGold then
        add("|cffffcc00Gesamt Gold Missionen:|r " .. Utils.FormatMoney(goldActive or 0) .. " / " .. Utils.FormatMoney(goldTotal or 0))
        add("")
    end

    if cfg.showGroupAnima then
        add("|cffffcc00Gesamt Anima Missionen:|r " .. tostring(animaActive or 0) .. " / " .. tostring(animaTotal or 0))
        add("")
    end

    if cfg.showGroupCurrency then
        add("|cffffcc00Waehrung gesamt:|r")
    end
    local currencies = {}
    for _, entry in pairs(currencyTotals) do
        currencies[#currencies + 1] = entry
    end
    table.sort(currencies, function(a, b)
        if (a.total or 0) ~= (b.total or 0) then return (a.total or 0) > (b.total or 0) end
        return a.label < b.label
    end)

    if cfg.showGroupCurrency then
        if #currencies == 0 then
            add("  - keine")
        else
            for _, entry in ipairs(currencies) do
                local iconText = entry.icon and ("|T" .. tostring(entry.icon) .. ":14:14:0:0|t ") or ""
                add(
                    "  - " .. iconText .. entry.label .. ": " .. tostring(entry.active or 0) .. " / " .. tostring(entry.total or 0),
                    {
                        currencyID = entry.currencyID,
                        quantity = entry.total,
                        lines = {
                            entry.label .. " aktiv: " .. tostring(entry.active or 0),
                            entry.label .. " gesamt: " .. tostring(entry.total or 0)
                        }
                    }
                )
            end
        end
        add("")
    end

    if cfg.showMissionHighlight then
        add("")
        add("|cff00ccffHighlight Bereich|r")
        local charKey = Utils.GetCharacterKey and Utils.GetCharacterKey() or "Character"
        local agg = {}
        local order = {}

        for _, e in ipairs(entries or {}) do
            if e.isHighlight then
                local kind = tostring(e.highlightKind or "other")
                local id = tonumber(e.highlightID) or 0
                local key = kind .. ":" .. tostring(id)
                local row = agg[key]
                if not row then
                    row = {
                        kind = kind,
                        id = id,
                        missions = 0,
                        lines = {},
                    }
                    agg[key] = row
                    order[#order + 1] = row
                end
                row.missions = row.missions + 1
                row.lines[#row.lines + 1] = (e.missionName or "Unknown") .. " | " .. (e.rewardPreview or "keine Belohnung")
            end
        end

        if #order == 0 then
            add("  - keine Highlight-Treffer")
            add("  - Hinweis: highlightIDs im Config setzen")
        else
            table.sort(order, function(a, b)
                if a.kind ~= b.kind then
                    return a.kind < b.kind
                end
                return a.id < b.id
            end)

            local maxRows = 12
            for i = 1, math.min(#order, maxRows) do
                local h = order[i]
                local iconText = ""
                local tooltipPayload = {
                    lines = {
                        charKey .. " - Highlight",
                        "Treffer: " .. tostring(h.missions),
                    }
                }

                if h.kind == "currency" and h.id > 0 and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
                    local ci = C_CurrencyInfo.GetCurrencyInfo(h.id)
                    if ci and ci.iconFileID then
                        iconText = "|T" .. tostring(ci.iconFileID) .. ":14:14:0:0|t "
                    end
                    tooltipPayload.currencyID = h.id
                    tooltipPayload.quantity = 1
                elseif h.kind == "item" and h.id > 0 then
                    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(h.id)
                    if not tex and C_Item and C_Item.GetItemInfoInstant then
                        local _, _, _, _, _, _, _, _, _, instantTex = C_Item.GetItemInfoInstant(h.id)
                        tex = instantTex
                    end
                    if tex then
                        iconText = "|T" .. tostring(tex) .. ":14:14:0:0|t "
                    end
                    tooltipPayload.itemID = h.id
                end

                local previewMax = 3
                for j = 1, math.min(#h.lines, previewMax) do
                    tooltipPayload.lines[#tooltipPayload.lines + 1] = h.lines[j]
                end
                if #h.lines > previewMax then
                    tooltipPayload.lines[#tooltipPayload.lines + 1] = "... +" .. tostring(#h.lines - previewMax) .. " weitere"
                end

                add("  - " .. charKey .. " - " .. iconText, tooltipPayload)
            end
            if #order > maxRows then
                add("  - ... +" .. tostring(#order - maxRows) .. " weitere")
            end
        end
    end

    return rows
end
