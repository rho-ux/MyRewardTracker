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
local listText
local listContent

local FOLLOWER_EXPANSION_MAP = {
    [1] = "wod",
    [4] = "legion",
    [22] = "bfa",
    [123] = "sl",
}

local function GetMissionState(mission)
    if not mission then
        return "available"
    end

    if mission.completed then
        return "ready"
    end

    if mission.inProgress then
        if mission.timeLeftSeconds and mission.timeLeftSeconds == 0 then
            return "ready"
        end
        return "running"
    end

    return "available"
end

local function GetMissionExpansionKey(mission)
    if not mission then
        return "unknown"
    end

    local followerTypeID = mission.followerTypeID
    if followerTypeID and FOLLOWER_EXPANSION_MAP[followerTypeID] then
        return FOLLOWER_EXPANSION_MAP[followerTypeID]
    end

    return "unknown"
end

local function GetMissionRewardKey(mission)
    if not mission or not mission.rewards then
        return "other"
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

    if hasItem then
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

local function RefreshDashboard()
    if not frame then
        return
    end

    local summary = nil
    if MRT.Notifier and MRT.Notifier.GetSummaryCounts then
        summary = MRT.Notifier:GetSummaryCounts()
    end

    summary = summary or {
        available = 0,
        ready = 0,
        running = 0,
        wq = 0
    }

    lineCharacter:SetText("Character: " .. GetCharacterKey())
    lineAvailable:SetText("Mission verfuegbar: " .. (summary.available or 0))
    lineReady:SetText("Mission fertig: " .. (summary.ready or 0))
    lineRunning:SetText("Mission running: " .. (summary.running or 0))
    lineWQ:SetText("WQ verfuegbar: " .. (summary.wq or 0))

    local entries = {}
    local charData = MyRewardTrackerDB and MyRewardTrackerDB.characters and MyRewardTrackerDB.characters[GetCharacterKey()]
    local shown = 0

    if charData and charData.missionTable and MRT.FilterEngine then
        for missionID, mission in pairs(charData.missionTable) do
            if MRT.FilterEngine:CheckMission(missionID, mission) then
                shown = shown + 1
                local state = GetMissionState(mission)
                local expansionKey = GetMissionExpansionKey(mission)
                local rewardKey = GetMissionRewardKey(mission)
                local expansionSort = 9999
                local rewardSort = 9999

                if MRT.Config and MRT.Config.GetExpansionSortIndex then
                    expansionSort = MRT.Config:GetExpansionSortIndex(expansionKey)
                end
                if MRT.Config and MRT.Config.GetRewardSortIndex then
                    rewardSort = MRT.Config:GetRewardSortIndex(rewardKey)
                end

                entries[#entries + 1] = {
                    missionID = missionID,
                    missionName = mission.name or "Unknown",
                    state = state,
                    expansionKey = expansionKey,
                    rewardKey = rewardKey,
                    expansionSort = expansionSort,
                    rewardSort = rewardSort,
                }
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.expansionSort ~= b.expansionSort then
            return a.expansionSort < b.expansionSort
        end
        if a.rewardSort ~= b.rewardSort then
            return a.rewardSort < b.rewardSort
        end
        if a.missionName ~= b.missionName then
            return a.missionName < b.missionName
        end
        return a.missionID < b.missionID
    end)

    local lines = {}
    for _, entry in ipairs(entries) do
        lines[#lines + 1] =
            "[" .. entry.missionID .. "] "
            .. entry.missionName
            .. " | "
            .. entry.state
            .. " | "
            .. entry.expansionKey
            .. " | "
            .. entry.rewardKey
    end

    listTitle:SetText("Gefilterte Missionen: " .. shown)
    listText:SetText(table.concat(lines, "\n"))
end

local function CreateDashboard()
    frame = CreateFrame("Frame", "MRT_DashboardFrame", UIParent, "BackdropTemplate")
    frame:SetSize(520, 420)
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

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 14, -182)
    scrollFrame:SetPoint("BOTTOMRIGHT", -34, 44)

    listContent = CreateFrame("Frame", nil, scrollFrame)
    listContent:SetSize(450, 180)
    scrollFrame:SetScrollChild(listContent)

    listText = listContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    listText:SetPoint("TOPLEFT")
    listText:SetWidth(450)
    listText:SetJustifyH("LEFT")
    listText:SetJustifyV("TOP")
    listText:SetText("")

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 24)
    refreshButton:SetPoint("BOTTOMLEFT", 14, 14)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        RefreshDashboard()
    end)

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

SLASH_MRTDASHBOARD1 = "/mrtdashboard"
SlashCmdList["MRTDASHBOARD"] = function()
    Dashboard:Toggle()
end
