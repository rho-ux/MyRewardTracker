-- =========================================
-- MyRewardTracker - Debug UI
-- Phase 2 Development Tool
-- =========================================

local addonName, MRT = ...
local DebugUI = {}

local frame
local scrollFrame
local content
local text

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

local function BuildText()

    if not MyRewardTrackerDB then
        return "DB nicht vorhanden."
    end

    local charKey = GetCharacterKey()
    local charData = MyRewardTrackerDB.characters and MyRewardTrackerDB.characters[charKey]

    if not charData then
        return "Keine Daten für Charakter."
    end

    local output = ""
    local count = 0

    output = output .. "Character: " .. charKey .. "\n\n"

    if MRT.Notifier and MRT.Notifier.GetSummaryCounts then
        local summary = MRT.Notifier:GetSummaryCounts()
        output = output .. "Notifier Summary:\n"
        output = output .. "  available: " .. (summary.available or 0) .. "\n"
        output = output .. "  ready: " .. (summary.ready or 0) .. "\n"
        output = output .. "  running: " .. (summary.running or 0) .. "\n"
        output = output .. "  wq: " .. (summary.wq or 0) .. "\n"
        output = output .. "  filteredTotal: " .. (summary.filteredTotal or 0) .. "\n\n"
    end

    local tracked = MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked and MyRewardTrackerDB.account.tracked[charKey]
    if tracked and tracked.summary then
        output = output .. "Tracked Summary (account.tracked):\n"
        output = output .. "  filteredTotal: " .. (tracked.summary.filteredTotal or 0) .. "\n"
        output = output .. "  available: " .. (tracked.summary.available or 0) .. "\n"
        output = output .. "  running: " .. (tracked.summary.running or 0) .. "\n"
        output = output .. "  ready: " .. (tracked.summary.ready or 0) .. "\n"
        output = output .. "  wq: " .. (tracked.summary.wq or 0) .. "\n"
        output = output .. "\n"
    else
        output = output .. "Tracked Summary (account.tracked): nicht vorhanden\n\n"
    end

    local trackedAll = MyRewardTrackerDB.account and MyRewardTrackerDB.account.tracked
    output = output .. "Tracked Characters (account.tracked):\n"
    if trackedAll then
        local keys = {}
        for key in pairs(trackedAll) do
            keys[#keys + 1] = key
        end
        table.sort(keys)

        if #keys == 0 then
            output = output .. "  - keine\n\n"
        else
            for _, key in ipairs(keys) do
                local entry = trackedAll[key]
                local s = entry and entry.summary or {}
                output = output .. string.format(
                    "  - %s | total:%d avail:%d run:%d ready:%d\n",
                    key,
                    s.filteredTotal or 0,
                    s.available or 0,
                    s.running or 0,
                    s.ready or 0
                )
            end
            output = output .. "\n"
        end
    else
        output = output .. "  - nicht vorhanden\n\n"
    end

    for missionID, mission in pairs(charData.missionTable) do
        local filtered = MRT.FilterEngine:CheckMission(missionID, mission)
        count = count + 1

        output = output .. "[" .. missionID .. "] "
        output = output .. (mission.name or "Unknown")

        if filtered then
             output = output .. " | FILTER"
        else
             output = output .. " | ignore"
        end

        if mission.inProgress then
            output = output .. " | running"
        elseif mission.completed then
            output = output .. " | ready"
        else
            output = output .. " | available"
        end

        output = output .. "\n"

        if mission.rewards then
            for _, reward in ipairs(mission.rewards) do

                if reward.itemID then
                    output = output .. "   Item: " .. reward.itemID .. " x" .. (reward.quantity or 1) .. "\n"
                elseif reward.currencyID then
                    output = output .. "   Currency: " .. reward.currencyID .. " x" .. (reward.quantity or 0) .. "\n"
                end

            end
        end

        output = output .. "\n"
    end

    output = "Mission Count: " .. count .. "\n\n" .. output

    return output
end

local function CreateUI()

    frame = CreateFrame("Frame", "MRT_DebugFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background"
    })
    frame:SetBackdropColor(0,0,0,0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(460, 380)

    scrollFrame:SetScrollChild(content)

    text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT")
    text:SetJustifyH("LEFT")
    text:SetWidth(440)
end

function DebugUI:Toggle()

    if not frame then
        CreateUI()
    end

    if frame:IsShown() then
        frame:Hide()
    else
        text:SetText(BuildText())
        frame:Show()
    end
end

SLASH_MRTDEBUG1 = "/mrtdebug"
SlashCmdList["MRTDEBUG"] = function()
    DebugUI:Toggle()
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtdebug", "oeffnet/schliesst Debug-UI")
end


MRT.DebugUI = DebugUI

