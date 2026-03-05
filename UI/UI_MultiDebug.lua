local addonName, MRT = ...

local MultiDebug = {}
MRT.MultiDebug = MultiDebug

local frame
local content
local rows = {}
local optionGold
local optionCurrency
local optionItems
local optionAnima

local function GetCfg()
    if MRT.Config and MRT.Config.GetDashboardConfig then
        return MRT.Config:GetDashboardConfig()
    end
    return {
        multiShowGold = true,
        multiShowCurrency = true,
        multiShowItems = true,
        multiShowAnima = true,
    }
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

local function GetExpansionLabel(expansionKey)
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Expansion then
        local label = MRT.Config.Labels.Expansion[expansionKey]
        if label and label ~= "" then
            return label
        end
    end
    return string.upper(expansionKey or "unknown")
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

local function BuildGroupData(mission)
    local data = {
        gold = 0,
        currencies = {},
        items = {},
        animaItems = {},
    }
    if not mission or type(mission.rewards) ~= "table" then
        return data
    end

    for _, reward in ipairs(mission.rewards) do
        local qty = tonumber(reward.quantity) or 0
        if reward.currencyID == 0 then
            data.gold = data.gold + qty
        elseif reward.currencyID then
            data.currencies[#data.currencies + 1] = {
                currencyID = reward.currencyID,
                quantity = qty,
            }
        elseif reward.itemID then
            local isAnima = MRT.Config and MRT.Config.IsAnimaItem and MRT.Config:IsAnimaItem(reward.itemID)
            local target = isAnima and data.animaItems or data.items
            target[#target + 1] = {
                itemID = reward.itemID,
                quantity = qty,
            }
        end
    end

    return data
end

local function BuildGroupText(groupKey, info)
    if groupKey == "gold" then
        return FormatMoney(info.gold or 0)
    end
    if groupKey == "currency" then
        local parts = {}
        for _, c in ipairs(info.currencies or {}) do
            local name = "Currency:" .. tostring(c.currencyID)
            local cfg = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(c.currencyID)
            if cfg and cfg.name and cfg.name ~= "" then
                name = cfg.name
            end
            parts[#parts + 1] = name .. " x" .. tostring(c.quantity or 0)
        end
        return table.concat(parts, ", ")
    end

    local src = groupKey == "anima" and info.animaItems or info.items
    local parts = {}
    for _, it in ipairs(src or {}) do
        local label = "Item:" .. tostring(it.itemID)
        local link = select(2, GetItemInfo(it.itemID))
        if link and link ~= "" then
            label = link
        end
        parts[#parts + 1] = label .. " x" .. tostring(it.quantity or 0)
    end
    return table.concat(parts, ", ")
end

local function EnsureRow(index)
    local row = rows[index]
    if row then
        return row
    end

    row = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetWidth(700)
    row:SetJustifyH("LEFT")
    row:SetJustifyV("TOP")
    rows[index] = row
    return row
end

local function RenderLines(lines)
    for i, text in ipairs(lines) do
        local row = EnsureRow(i)
        row:SetText(text)
        row:Show()
    end

    for i = #lines + 1, #rows do
        rows[i]:Hide()
    end

    content:SetHeight(math.max(1, (#lines * 18) + 8))
end

local function BuildLines()
    local cfg = GetCfg()
    local lines = {}
    lines[#lines + 1] = "|cffffcc00Multi-Char Debug (account.tracked)|r"
    lines[#lines + 1] = ""

    local trackedRoot = MyRewardTrackerDB and MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked
    if type(trackedRoot) ~= "table" then
        lines[#lines + 1] = "Keine account.tracked Daten vorhanden."
        return lines
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
        lines[#lines + 1] = "Keine Characters in account.tracked."
        return lines
    end

    for _, charKey in ipairs(keys) do
        local tracked = trackedRoot[charKey]
        local s = tracked and tracked.summary or {}
        lines[#lines + 1] = string.format(
            "%s | total:%d avail:%d run:%d ready:%d",
            charKey,
            s.filteredTotal or 0,
            s.available or 0,
            s.running or 0,
            s.ready or 0
        )
        local parts = {}
        if cfg.multiShowGold then
            parts[#parts + 1] = "gold:" .. FormatMoney(s.totalGoldCopper or 0)
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
            "  missions:%d lastScan:%s",
            tracked and tracked.missions and (function()
                local c = 0
                for _ in pairs(tracked.missions) do
                    c = c + 1
                end
                return c
            end)() or 0,
            tostring(tracked and tracked.lastScan or 0)
        )
        lines[#lines + 1] = "  ---------------------------"

        local groups = {
            gold = {},
            currency = {},
            items = {},
            anima = {},
        }
        local missions = tracked and tracked.missions or {}
        for missionID, mission in pairs(missions or {}) do
            local groupInfo = BuildGroupData(mission)
            local base = {
                missionID = missionID,
                name = mission.name or "Unknown",
                state = mission.state or "available",
                expansionKey = mission.expansionKey or "unknown",
                expansionSort = MRT.Config and MRT.Config.GetExpansionSortIndex and MRT.Config:GetExpansionSortIndex(mission.expansionKey or "unknown") or 9999,
                stateSort = GetStateSort(mission.state),
            }

            if (groupInfo.gold or 0) > 0 then
                local e = {}
                for k, v in pairs(base) do e[k] = v end
                e.groupInfo = groupInfo
                groups.gold[#groups.gold + 1] = e
            end
            if #(groupInfo.currencies or {}) > 0 then
                local e = {}
                for k, v in pairs(base) do e[k] = v end
                e.groupInfo = groupInfo
                groups.currency[#groups.currency + 1] = e
            end
            if #(groupInfo.items or {}) > 0 then
                local e = {}
                for k, v in pairs(base) do e[k] = v end
                e.groupInfo = groupInfo
                groups.items[#groups.items + 1] = e
            end
            if #(groupInfo.animaItems or {}) > 0 then
                local e = {}
                for k, v in pairs(base) do e[k] = v end
                e.groupInfo = groupInfo
                groups.anima[#groups.anima + 1] = e
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
                    GetStateLabel(e.state),
                    GetExpansionLabel(e.expansionKey),
                    BuildGroupText(key, e.groupInfo)
                )
            end
        end

        appendGroup("Gold", "gold", cfg.multiShowGold)
        appendGroup("Waehrung", "currency", cfg.multiShowCurrency)
        appendGroup("Items", "items", cfg.multiShowItems)
        appendGroup("Anima", "anima", cfg.multiShowAnima)
        lines[#lines + 1] = ""
    end

    return lines
end

local function Refresh()
    if not frame then
        return
    end
    local cfg = GetCfg()
    if optionGold then optionGold:SetChecked(cfg.multiShowGold and true or false) end
    if optionCurrency then optionCurrency:SetChecked(cfg.multiShowCurrency and true or false) end
    if optionItems then optionItems:SetChecked(cfg.multiShowItems and true or false) end
    if optionAnima then optionAnima:SetChecked(cfg.multiShowAnima and true or false) end
    RenderLines(BuildLines())
end

local function CreateOptionToggle(parent, x, y, labelText, initialValue, onChanged)
    local btn = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    btn:SetPoint("BOTTOMLEFT", x, y)
    btn:SetChecked(initialValue and true or false)
    btn:SetScript("OnClick", function(self)
        onChanged(self:GetChecked() and true or false)
    end)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", btn, "RIGHT", 2, 1)
    label:SetText(labelText)

    return btn
end

local function CreateUI()
    frame = CreateFrame("Frame", "MRT_MultiDebugFrame", UIParent, "BackdropTemplate")
    frame:SetSize(780, 520)
    frame:SetPoint("CENTER", 120, 40)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    table.insert(UISpecialFrames, "MRT_MultiDebugFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("MRT Multi-Char Debug")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -40)
    scroll:SetPoint("BOTTOMRIGHT", -34, 44)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(700, 420)
    scroll:SetScrollChild(content)

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 24)
    refreshButton:SetPoint("BOTTOMLEFT", 14, 14)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        Refresh()
    end)

    local cfg = GetCfg()
    optionGold = CreateOptionToggle(frame, 130, 16, "Gold", cfg.multiShowGold, function(checked)
        cfg.multiShowGold = checked
        Refresh()
    end)
    optionCurrency = CreateOptionToggle(frame, 240, 16, "Waehrung", cfg.multiShowCurrency, function(checked)
        cfg.multiShowCurrency = checked
        Refresh()
    end)
    optionItems = CreateOptionToggle(frame, 380, 16, "Items", cfg.multiShowItems, function(checked)
        cfg.multiShowItems = checked
        Refresh()
    end)
    optionAnima = CreateOptionToggle(frame, 490, 16, "Anima", cfg.multiShowAnima, function(checked)
        cfg.multiShowAnima = checked
        Refresh()
    end)
end

function MultiDebug:Toggle()
    if not frame then
        CreateUI()
    end

    if frame:IsShown() then
        frame:Hide()
        return
    end

    Refresh()
    frame:Show()
end

function MultiDebug:Refresh()
    if frame and frame:IsShown() then
        Refresh()
    end
end

SLASH_MRTMULTIDEBUG1 = "/mrtmultidebug"
SlashCmdList["MRTMULTIDEBUG"] = function()
    MultiDebug:Toggle()
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtmultidebug", "oeffnet/schliesst Multi-Char-Debug-UI")
end
