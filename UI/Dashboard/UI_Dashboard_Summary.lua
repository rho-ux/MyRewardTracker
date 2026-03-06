local addonName, MRT = ...

MRT.DashboardSummary = MRT.DashboardSummary or {}
local Summary = MRT.DashboardSummary
local Utils = MRT.DashboardUtils or {}

function Summary.BuildAggregateRows(goldActive, goldTotal, animaActive, animaTotal, currencyTotals, cfg)
    local rows = {}
    local function add(text, tooltip)
        rows[#rows + 1] = { text = text, tooltip = tooltip }
    end

    if cfg.showGroupGold then
        add("|cffffcc00Gesamt Gold Mission:|r " .. Utils.FormatMoney(goldActive or 0) .. " / " .. Utils.FormatMoney(goldTotal or 0))
        add("")
    end

    if cfg.showGroupAnima then
        add("|cffffcc00Gesamt Anima Mission:|r " .. tostring(animaActive or 0) .. " / " .. tostring(animaTotal or 0))
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
        add("|cff00ccffHighlight Bereich (reserviert)|r")
        add("  - Highlight Eintrag 1")
        add("  - Highlight Eintrag 2")
        add("  - Highlight Eintrag 3")
    end

    return rows
end
