local addonName, MRT = ...

local MultiDebug = {}
MRT.MultiDebug = MultiDebug

local frame
local lineTitle
local lineTracked
local summaryTitle
local summaryScroll
local summaryContent
local summaryRows = {}
local highlightTitle
local highlightScroll
local highlightContent
local highlightRows = {}
local listTitle
local filterTitle
local listScroll
local listContent
local listRows = {}
local hLine
local vLineTop
local filterLineTop
local filterLineBottom
local expansionFilterButton
local rewardFilterButton
local highlightOnlyToggle
local searchBox
local clearSearchButton
local filterInfoLine
local resetFilterButton

local Data = MRT.MultiDebugData or {}
local DashboardUtils = MRT.DashboardUtils or {}
local ShowRowTooltip = DashboardUtils.ShowRowTooltip
local HideRowTooltip = DashboardUtils.HideRowTooltip
local uiFilters = {
    expansionKey = "all",
    rewardKey = "all",
    highlightsOnly = false,
    searchText = "",
}

local function GetExpansionFilterOptions()
    local options = { "all" }
    if MRT.Config and MRT.Config.Sorting and type(MRT.Config.Sorting.ExpansionOrder) == "table" then
        for _, key in ipairs(MRT.Config.Sorting.ExpansionOrder) do
            options[#options + 1] = key
        end
    else
        options[#options + 1] = "wod"
        options[#options + 1] = "legion"
        options[#options + 1] = "bfa"
        options[#options + 1] = "sl"
        options[#options + 1] = "df"
        options[#options + 1] = "tww"
        options[#options + 1] = "unknown"
    end
    return options
end

local function GetRewardFilterOptions()
    return { "all", "anima", "item", "currency", "gold" }
end

local function GetExpansionFilterLabel(key)
    if key == "all" then
        return "ALLE"
    end
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Expansion and MRT.Config.Labels.Expansion[key] then
        return MRT.Config.Labels.Expansion[key]
    end
    return string.upper(key or "unknown")
end

local function GetRewardFilterLabel(key)
    if key == "all" then
        return "ALLE"
    end
    if MRT.Config and MRT.Config.Labels and MRT.Config.Labels.Reward and MRT.Config.Labels.Reward[key] then
        return MRT.Config.Labels.Reward[key]
    end
    return string.upper(key or "other")
end

local function CycleFilter(current, options)
    local idx = 1
    for i, key in ipairs(options) do
        if key == current then
            idx = i
            break
        end
    end
    idx = idx + 1
    if idx > #options then
        idx = 1
    end
    return options[idx]
end

local function GetCfg()
    if MRT.Config and MRT.Config.GetMultiDashboardConfig then
        return MRT.Config:GetMultiDashboardConfig()
    end
    if MRT.Config and MRT.Config.GetDashboardConfig then
        return MRT.Config:GetDashboardConfig()
    end
    return {
        multiShowGold = true,
        multiShowCurrency = true,
        multiShowItems = true,
        multiShowAnima = true,
        showExpansionHeaders = true,
        showRewardHeaders = true,
        showStatusColors = true,
        lineHeight = 18,
        headerStyle = "normal",
        fontSize = 13,
        topSplitRatio = 56,
        showMissionHighlight = true,
    }
end

local function ResetUiFilters()
    uiFilters.expansionKey = "all"
    uiFilters.rewardKey = "all"
    uiFilters.highlightsOnly = false
    uiFilters.searchText = ""
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
    local delta = step or 20
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, d)
        local current = self:GetVerticalScroll() or 0
        local minV, maxV = self:GetVerticalScrollRange()
        local nextV = current - (d * delta)
        if nextV < 0 then nextV = 0 end
        if maxV and nextV > maxV then nextV = maxV end
        self:SetVerticalScroll(nextV)
    end)
end

local function EnsureRow(container, store, index)
    local row = store[index]
    if row then return row end

    row = CreateFrame("Button", nil, container)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetPoint("TOPRIGHT", 0, -((index - 1) * 18))
    row:RegisterForClicks("AnyUp")
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("TOPLEFT", 0, 0)
    row.text:SetWidth(1400)
    row.text:SetJustifyH("LEFT")
    row.text:SetJustifyV("TOP")
    if ShowRowTooltip then
        row:SetScript("OnEnter", ShowRowTooltip)
    end
    if HideRowTooltip then
        row:SetScript("OnLeave", HideRowTooltip)
    end
    store[index] = row
    return row
end

local function RenderRows(container, store, rowsData, lineHeight)
    for i, rowData in ipairs(rowsData) do
        local row = EnsureRow(container, store, i)
        row:SetHeight(lineHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((i - 1) * lineHeight))
        row:SetPoint("TOPRIGHT", 0, -((i - 1) * lineHeight))
        row.data = rowData
        row.text:SetText(rowData.text or "")
        row:Show()
    end
    for i = #rowsData + 1, #store do
        store[i].data = nil
        store[i]:Hide()
    end
    container:SetHeight(math.max(1, (#rowsData * lineHeight) + 8))
end

local function ApplyFonts(cfg)
    local size = tonumber(cfg.fontSize) or 13
    if size < 10 then size = 10 end
    if size > 20 then size = 20 end
    local headerExtra = (cfg.headerStyle == "emphasis") and 3 or 1
    local base = STANDARD_TEXT_FONT

    if lineTitle then lineTitle:SetFont(base, size + headerExtra, "") end
    if lineTracked then lineTracked:SetFont(base, size, "") end
    if summaryTitle then summaryTitle:SetFont(base, size + headerExtra, "") end
    if highlightTitle then highlightTitle:SetFont(base, size + headerExtra, "") end
    if filterTitle then filterTitle:SetFont(base, size + headerExtra, "") end
    if listTitle then listTitle:SetFont(base, size + headerExtra, "") end
    if filterInfoLine then filterInfoLine:SetFont(base, math.max(10, size - 2), "") end

    for _, r in ipairs(summaryRows) do
        if r and r.text then r.text:SetFont(base, math.max(10, size - 1), "") end
    end
    for _, r in ipairs(highlightRows) do
        if r and r.text then r.text:SetFont(base, math.max(10, size - 1), "") end
    end
    for _, r in ipairs(listRows) do
        if r and r.text then r.text:SetFont(base, math.max(10, size - 1), "") end
    end
end

local function ApplyLayout(cfg)
    if not frame then
        return
    end

    local ratio = tonumber(cfg.topSplitRatio) or 56
    if ratio < 40 then ratio = 40 end
    if ratio > 75 then ratio = 75 end

    local frameW = 1560
    local leftW = math.floor((frameW - 34) * (ratio / 100))
    local rightW = (frameW - 34) - leftW
    local leftX = 14
    local rightX = 14 + leftW + 12

    local topY = -92
    local topH = 236
    local midTitleY = -372
    local listTitleY = -438
    local listTopY = -462

    if summaryTitle then
        summaryTitle:ClearAllPoints()
        summaryTitle:SetPoint("TOPLEFT", leftX + 2, -66)
    end
    if highlightTitle then
        highlightTitle:ClearAllPoints()
        highlightTitle:SetPoint("TOPLEFT", rightX + 2, -66)
    end
    if summaryScroll then
        summaryScroll:ClearAllPoints()
        summaryScroll:SetPoint("TOPLEFT", leftX, topY)
        summaryScroll:SetSize(leftW, topH)
    end
    if highlightScroll then
        highlightScroll:ClearAllPoints()
        highlightScroll:SetPoint("TOPLEFT", rightX, topY)
        highlightScroll:SetSize(rightW, topH)
    end

    if summaryContent then summaryContent:SetSize(math.max(520, leftW - 40), topH) end
    if highlightContent then highlightContent:SetSize(math.max(320, rightW - 40), topH) end

    if hLine then
        hLine:ClearAllPoints()
        hLine:SetPoint("LEFT", 12, 0)
        hLine:SetPoint("RIGHT", -12, 0)
        hLine:SetPoint("TOP", 0, -344)
    end

    if vLineTop then
        vLineTop:ClearAllPoints()
        vLineTop:SetPoint("TOPLEFT", frame, "TOPLEFT", rightX - 6, -64)
        vLineTop:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", rightX - 6, -344)
    end

    if filterLineTop then
        filterLineTop:ClearAllPoints()
        filterLineTop:SetPoint("LEFT", 12, 0)
        filterLineTop:SetPoint("RIGHT", -12, 0)
        filterLineTop:SetPoint("TOP", 0, -368)
    end
    if filterTitle then
        filterTitle:ClearAllPoints()
        filterTitle:SetPoint("TOP", 0, midTitleY)
    end
    if resetFilterButton then
        resetFilterButton:ClearAllPoints()
        resetFilterButton:SetPoint("TOPLEFT", 14, midTitleY - 2)
    end
    if expansionFilterButton then
        expansionFilterButton:ClearAllPoints()
        expansionFilterButton:SetPoint("LEFT", resetFilterButton, "RIGHT", 8, 0)
    end
    if rewardFilterButton then
        rewardFilterButton:ClearAllPoints()
        rewardFilterButton:SetPoint("LEFT", expansionFilterButton, "RIGHT", 8, 0)
    end
    if highlightOnlyToggle then
        highlightOnlyToggle:ClearAllPoints()
        highlightOnlyToggle:SetPoint("LEFT", rewardFilterButton, "RIGHT", 8, 0)
    end
    if searchBox then
        searchBox:ClearAllPoints()
        searchBox:SetPoint("TOP", 220, midTitleY - 2)
    end
    if clearSearchButton then
        clearSearchButton:ClearAllPoints()
        clearSearchButton:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
    end
    if filterInfoLine then
        filterInfoLine:ClearAllPoints()
        filterInfoLine:SetPoint("TOPLEFT", 14, midTitleY - 34)
    end
    if filterLineBottom then
        filterLineBottom:ClearAllPoints()
        filterLineBottom:SetPoint("LEFT", 12, 0)
        filterLineBottom:SetPoint("RIGHT", -12, 0)
        filterLineBottom:SetPoint("TOP", 0, -412)
    end

    if listTitle then
        listTitle:ClearAllPoints()
        listTitle:SetPoint("TOPLEFT", 16, listTitleY)
    end
    if listScroll then
        listScroll:ClearAllPoints()
        listScroll:SetPoint("TOPLEFT", 14, listTopY)
        listScroll:SetPoint("BOTTOMRIGHT", -34, 84)
    end
    if listContent then listContent:SetSize(1480, 420) end
end

local function Refresh()
    if not frame then return end
    local cfg = GetCfg()
    local lineHeight = tonumber(cfg.lineHeight) or 18
    if lineHeight < 16 then lineHeight = 16 end
    if lineHeight > 28 then lineHeight = 28 end

    local summaryRowsData, listRowsData, highlightRowsData
    if Data.BuildLayoutRows then
        summaryRowsData, listRowsData, highlightRowsData = Data.BuildLayoutRows(cfg, uiFilters)
    else
        summaryRowsData = { { text = "MultiDebugData nicht geladen." } }
        listRowsData = { { text = "MultiDebugData nicht geladen." } }
        highlightRowsData = { { text = "MultiDebugData nicht geladen." } }
    end

    ApplyLayout(cfg)
    RenderRows(summaryContent, summaryRows, summaryRowsData or {}, lineHeight)
    RenderRows(highlightContent, highlightRows, highlightRowsData or {}, lineHeight)
    RenderRows(listContent, listRows, listRowsData or {}, lineHeight)

    local trackedRoot = MyRewardTrackerDB and MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked
    local trackedCount = 0
    if type(trackedRoot) == "table" then
        for _ in pairs(trackedRoot) do
            trackedCount = trackedCount + 1
        end
    end
    if lineTracked then
        lineTracked:SetText("Chars erfasst: " .. tostring(trackedCount))
    end

    if expansionFilterButton then
        expansionFilterButton:SetText("Exp: " .. GetExpansionFilterLabel(uiFilters.expansionKey))
    end
    if rewardFilterButton then
        rewardFilterButton:SetText("Reward: " .. GetRewardFilterLabel(uiFilters.rewardKey))
    end
    if highlightOnlyToggle then
        local stateText = uiFilters.highlightsOnly and "AN" or "AUS"
        highlightOnlyToggle:SetText("Highlights: " .. stateText)
    end
    if searchBox and searchBox:GetText() ~= uiFilters.searchText then
        searchBox:SetText(uiFilters.searchText or "")
    end
    if filterInfoLine then
        local searchPart = (uiFilters.searchText and uiFilters.searchText ~= "") and (" | Suche: " .. uiFilters.searchText) or ""
        local hiPart = uiFilters.highlightsOnly and " | Highlights-only: AN" or ""
        filterInfoLine:SetText("Filter aktiv: " .. GetExpansionFilterLabel(uiFilters.expansionKey) .. " / " .. GetRewardFilterLabel(uiFilters.rewardKey) .. hiPart .. searchPart)
    end

    ApplyFonts(cfg)
end

local function CreateUI()
    frame = CreateFrame("Frame", "MRT_MultiDebugFrame", UIParent, "BackdropTemplate")
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
    table.insert(UISpecialFrames, "MRT_MultiDebugFrame")

    lineTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    lineTitle:SetPoint("TOP", 0, -12)
    lineTitle:SetText("MRT Multi-Char Dashboard")

    lineTracked = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineTracked:SetPoint("TOPLEFT", 16, -42)
    lineTracked:SetJustifyH("LEFT")

    summaryTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryTitle:SetPoint("TOPLEFT", 16, -70)
    summaryTitle:SetJustifyH("LEFT")
    summaryTitle:SetText("Zusammenfassung Multi-Char Missionen")

    highlightTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    highlightTitle:SetPoint("TOPLEFT", 920, -70)
    highlightTitle:SetJustifyH("LEFT")
    highlightTitle:SetText("Highlights")

    summaryScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    summaryScroll:SetPoint("TOPLEFT", 14, -92)
    summaryScroll:SetSize(900, 236)
    summaryContent = CreateFrame("Frame", nil, summaryScroll)
    summaryContent:SetSize(860, 236)
    summaryScroll:SetScrollChild(summaryContent)

    highlightScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    highlightScroll:SetPoint("TOPLEFT", 920, -92)
    highlightScroll:SetSize(606, 236)
    highlightContent = CreateFrame("Frame", nil, highlightScroll)
    highlightContent:SetSize(566, 236)
    highlightScroll:SetScrollChild(highlightContent)

    hLine = frame:CreateTexture(nil, "ARTWORK")
    hLine:SetColorTexture(0, 0, 0, 0)
    hLine:SetHeight(2)
    hLine:SetPoint("LEFT", 12, 0)
    hLine:SetPoint("RIGHT", -12, 0)
    hLine:SetPoint("TOP", 0, -344)

    vLineTop = frame:CreateTexture(nil, "ARTWORK")
    vLineTop:SetColorTexture(0, 0, 0, 0)
    vLineTop:SetWidth(2)
    vLineTop:SetPoint("TOP", 0, -64)
    vLineTop:SetPoint("BOTTOM", 0, -344)

    filterLineTop = frame:CreateTexture(nil, "ARTWORK")
    filterLineTop:SetColorTexture(0, 0, 0, 0)
    filterLineTop:SetHeight(2)
    filterLineTop:SetPoint("LEFT", 12, 0)
    filterLineTop:SetPoint("RIGHT", -12, 0)
    filterLineTop:SetPoint("TOP", 0, -368)

    filterTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterTitle:SetPoint("TOP", 0, -372)
    filterTitle:SetJustifyH("CENTER")
    filterTitle:SetText("")

    resetFilterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetFilterButton:SetSize(80, 29)
    resetFilterButton:SetPoint("TOPLEFT", 14, -374)
    resetFilterButton:SetText("Reset")
    resetFilterButton:SetScript("OnClick", function()
        ResetUiFilters()
        if searchBox then
            searchBox:SetText("")
        end
        Refresh()
    end)

    expansionFilterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    expansionFilterButton:SetSize(160, 29)
    expansionFilterButton:SetPoint("LEFT", resetFilterButton, "RIGHT", 8, 0)
    expansionFilterButton:SetText("Exp: ALLE")
    expansionFilterButton:SetScript("OnClick", function()
        uiFilters.expansionKey = CycleFilter(uiFilters.expansionKey, GetExpansionFilterOptions())
        Refresh()
    end)

    rewardFilterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    rewardFilterButton:SetSize(180, 29)
    rewardFilterButton:SetPoint("LEFT", expansionFilterButton, "RIGHT", 8, 0)
    rewardFilterButton:SetText("Reward: ALLE")
    rewardFilterButton:SetScript("OnClick", function()
        uiFilters.rewardKey = CycleFilter(uiFilters.rewardKey, GetRewardFilterOptions())
        Refresh()
    end)

    highlightOnlyToggle = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    highlightOnlyToggle:SetSize(140, 29)
    highlightOnlyToggle:SetPoint("LEFT", rewardFilterButton, "RIGHT", 8, 0)
    highlightOnlyToggle:SetText("Highlights: AUS")
    highlightOnlyToggle:SetScript("OnClick", function()
        uiFilters.highlightsOnly = not uiFilters.highlightsOnly
        Refresh()
    end)

    searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetAutoFocus(false)
    searchBox:SetSize(320, 29)
    searchBox:SetPoint("TOP", 220, -374)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        uiFilters.searchText = self:GetText() or ""
        Refresh()
    end)

    clearSearchButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearSearchButton:SetSize(70, 29)
    clearSearchButton:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
    clearSearchButton:SetText("Clear")
    clearSearchButton:SetScript("OnClick", function()
        uiFilters.searchText = ""
        if searchBox then
            searchBox:SetText("")
        end
        Refresh()
    end)

    filterInfoLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    filterInfoLine:SetPoint("TOPLEFT", 14, -406)
    filterInfoLine:SetJustifyH("LEFT")
    filterInfoLine:SetText("Filter aktiv: ALLE / ALLE")

    filterLineBottom = frame:CreateTexture(nil, "ARTWORK")
    filterLineBottom:SetColorTexture(0, 0, 0, 0)
    filterLineBottom:SetHeight(2)
    filterLineBottom:SetPoint("LEFT", 12, 0)
    filterLineBottom:SetPoint("RIGHT", -12, 0)
    filterLineBottom:SetPoint("TOP", 0, -412)

    listTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listTitle:SetPoint("TOPLEFT", 16, -438)
    listTitle:SetJustifyH("LEFT")
    listTitle:SetText("Missionen (Multi-Char, nur laufend/fertig)")

    listScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 14, -462)
    listScroll:SetPoint("BOTTOMRIGHT", -34, 84)
    listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetSize(1480, 420)
    listScroll:SetScrollChild(listContent)
    HideScrollBar(summaryScroll)
    HideScrollBar(highlightScroll)
    HideScrollBar(listScroll)
    EnableWheelScroll(summaryScroll, 24)
    EnableWheelScroll(highlightScroll, 24)
    EnableWheelScroll(listScroll, 28)

    local buttonY = 16
    local buttonGap = 12

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 24)
    refreshButton:SetPoint("BOTTOMLEFT", 16, buttonY)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function() Refresh() end)

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
    switchButton:SetText("Charakter")
    switchButton:SetScript("OnClick", function()
        MultiDebug:Hide()
        if MRT.Dashboard and MRT.Dashboard.Show then
            MRT.Dashboard:Show()
        elseif MRT.Dashboard and MRT.Dashboard.Toggle then
            MRT.Dashboard:Toggle()
        end
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)
end

function MultiDebug:Show()
    if not frame then CreateUI() end
    Refresh()
    frame:Show()
end

function MultiDebug:Hide()
    if frame and frame:IsShown() then
        frame:Hide()
    end
end

function MultiDebug:Toggle()
    if not frame then CreateUI() end
    if frame:IsShown() then
        frame:Hide()
        return
    end
    MultiDebug:Show()
end

function MultiDebug:Refresh()
    if frame and frame:IsShown() then Refresh() end
end

local function PrintTrackedDump()
    if Data.PrintTrackedDump then
        Data.PrintTrackedDump()
        return
    end
    print("|cffff0000[MRT]|r MultiDebugData nicht geladen.")
end

SLASH_MRTMULTIDEBUG1 = "/mrtmultidebug"
SlashCmdList["MRTMULTIDEBUG"] = function()
    MultiDebug:Toggle()
end

SLASH_MRTMULTIDUMP1 = "/mrtmultidump"
SlashCmdList["MRTMULTIDUMP"] = function()
    PrintTrackedDump()
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtmultidebug", "oeffnet/schliesst Multi-Char-Dashboard")
    MRT.RegisterHelpCommand("/mrtmultidump", "druckt Multi-Char Summen+Gruppen in den Chat")
end
