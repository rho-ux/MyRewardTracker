-- =========================================
-- MyRewardTracker - Notifier
-- Phase 4
-- Meldet gefilterte fertige Missionen
-- =========================================

local addonName, MRT = ...
local Notifier = CreateFrame("Frame")
MRT.Notifier = Notifier
local FilterEngine = MRT.FilterEngine

local popup
local lineAvailable
local lineReady
local lineWQ
local lastSummary
local popupToken = 0
local loginHintShown = false

local function EnsureNotifierConfig()
    MyRewardTrackerDB = MyRewardTrackerDB or {}
    MyRewardTrackerDB.account = MyRewardTrackerDB.account or {}
    MyRewardTrackerDB.account.notifierConfig = MyRewardTrackerDB.account.notifierConfig or {}

    local cfg = MyRewardTrackerDB.account.notifierConfig

    if type(cfg.popupEnabled) ~= "boolean" then
        cfg.popupEnabled = true
    end

    if type(cfg.soundMode) ~= "string" then
        cfg.soundMode = "none"
    end

    if type(cfg.autoHideSeconds) ~= "number" or cfg.autoHideSeconds < 0 then
        cfg.autoHideSeconds = 8
    end

    if cfg.soundKitID ~= nil and type(cfg.soundKitID) ~= "number" then
        cfg.soundKitID = nil
    end

    if cfg.soundFilePath ~= nil and type(cfg.soundFilePath) ~= "string" then
        cfg.soundFilePath = nil
    end

    -- Migration alter Konfiguration
    if type(cfg.soundEnabled) == "boolean" then
        if cfg.soundEnabled and cfg.soundKitID then
            cfg.soundMode = "kit"
        elseif cfg.soundEnabled and cfg.soundFilePath then
            cfg.soundMode = "file"
        else
            cfg.soundMode = "none"
        end
        cfg.soundEnabled = nil
    end

    return cfg
end

local function GetNotifierConfig()
    return EnsureNotifierConfig()
end

local function TryPlayNotificationSound(cfg)
    if not cfg or cfg.soundMode == "none" then
        return
    end

    if cfg.soundMode == "kit" and cfg.soundKitID then
        PlaySound(cfg.soundKitID, "Master")
        return
    end

    if cfg.soundMode == "file" and cfg.soundFilePath and cfg.soundFilePath ~= "" then
        PlaySoundFile(cfg.soundFilePath, "Master")
    end
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

local function OpenDashboard()
    if MRT.Dashboard and MRT.Dashboard.Toggle then
        MRT.Dashboard:Toggle()
        return
    end

    if MRT.DebugUI and MRT.DebugUI.Toggle then
        MRT.DebugUI:Toggle()
    end
end

local function EnsurePopup()
    if popup then
        return
    end

    popup = CreateFrame("Frame", "MRT_NotifyPopup", UIParent, "BackdropTemplate")
    popup:SetSize(320, 170)
    popup:SetPoint("CENTER", 0, 220)
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    popup:SetBackdropColor(0, 0, 0, 0.9)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup:Hide()

    table.insert(UISpecialFrames, "MRT_NotifyPopup")

    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("MyRewardTracker")

    lineAvailable = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineAvailable:SetPoint("TOPLEFT", 16, -42)
    lineAvailable:SetJustifyH("LEFT")

    lineReady = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineReady:SetPoint("TOPLEFT", 16, -64)
    lineReady:SetJustifyH("LEFT")

    lineWQ = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineWQ:SetPoint("TOPLEFT", 16, -86)
    lineWQ:SetJustifyH("LEFT")

    local openButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    openButton:SetSize(180, 24)
    openButton:SetPoint("BOTTOM", 0, 14)
    openButton:SetText("Dashboard oeffnen")
    openButton:SetScript("OnClick", function()
        OpenDashboard()
        popup:Hide()
    end)

    local closeButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)
end

local function ShowSummaryPopup(availableCount, readyCount, wqCount)
    local cfg = EnsureNotifierConfig()
    if not cfg.popupEnabled then
        return
    end

    EnsurePopup()

    local total = availableCount + readyCount + wqCount
    if total == 0 then
        if popup:IsShown() then
            popup:Hide()
        end
        lastSummary = nil
        return
    end

    local summary = availableCount .. "|" .. readyCount .. "|" .. wqCount
    if summary == lastSummary and popup:IsShown() then
        return
    end

    lineAvailable:SetText(availableCount .. " Mission verfuegbar")
    lineReady:SetText(readyCount .. " Mission fertig")
    lineWQ:SetText(wqCount .. " WQ verfuegbar")

    popup:Show()
    lastSummary = summary

    TryPlayNotificationSound(cfg)

    popupToken = popupToken + 1
    local currentToken = popupToken
    if cfg.autoHideSeconds > 0 then
        C_Timer.After(cfg.autoHideSeconds, function()
            if popup and popup:IsShown() and currentToken == popupToken then
                popup:Hide()
            end
        end)
    end
end

local function CollectSummaryCounts()
    if not MyRewardTrackerDB then return end
    if not MyRewardTrackerDB.characters then return end

    local availableCount = 0
    local readyCount = 0
    local runningCount = 0
    local wqCount = 0
    local filteredTotal = 0
    local charKey = GetCharacterKey()
    local charData = MyRewardTrackerDB.characters[charKey]

    if not charData or not charData.missionTable then
        return 0, 0, 0, 0, 0
    end

    for missionID, mission in pairs(charData.missionTable) do
        local state = "available"
        if MRT.Config and MRT.Config.GetMissionState then
            state = MRT.Config:GetMissionState(mission)
        end
        local filtered = FilterEngine:CheckMission(missionID, mission)

        if filtered then
            filteredTotal = filteredTotal + 1
            if state == "ready" then
                readyCount = readyCount + 1
            elseif state == "available" then
                availableCount = availableCount + 1
            elseif state == "running" then
                runningCount = runningCount + 1
            end
        end
    end

    -- Placeholder bis World-Quest-Modul integriert ist.
    wqCount = 0

    return availableCount, readyCount, wqCount, runningCount, filteredTotal
end

function MRT.Notifier:GetSummaryCounts()
    local availableCount, readyCount, wqCount, runningCount, filteredTotal = CollectSummaryCounts()
    return {
        available = availableCount or 0,
        ready = readyCount or 0,
        wq = wqCount or 0,
        running = runningCount or 0,
        filteredTotal = filteredTotal or 0
    }
end

function MRT.Notifier:CheckMissions(showPopup)
    local availableCount, readyCount, wqCount = CollectSummaryCounts()
    if not availableCount then
        if showPopup then
            ShowSummaryPopup(0, 0, 0)
        end
        return
    end

    if showPopup then
        ShowSummaryPopup(availableCount, readyCount, wqCount)
    end
end

Notifier:RegisterEvent("PLAYER_LOGIN")
Notifier:RegisterEvent("GARRISON_MISSION_LIST_UPDATE")
Notifier:RegisterEvent("GARRISON_MISSION_FINISHED")

Notifier:SetScript("OnEvent", function(self, event)

    if event == "PLAYER_LOGIN" then

        C_Timer.After(5, function()
            if not loginHintShown then
                loginHintShown = true
                MRT.Notifier:CheckMissions(true)
            end
        end)

    else

        MRT.Notifier:CheckMissions(false)

    end

end)

SLASH_MRTNOTIFY1 = "/mrtnotify"
SlashCmdList["MRTNOTIFY"] = function()
    if MRT.Notifier and MRT.Notifier.CheckMissions then
        MRT.Notifier:CheckMissions(true)
    end
end

SLASH_MRTNOTIFYPOPUP1 = "/mrtnotifypopup"
SlashCmdList["MRTNOTIFYPOPUP"] = function(msg)
    local cfg = GetNotifierConfig()
    local arg = string.lower((msg or ""):match("^%s*(.-)%s*$"))

    if arg == "on" then
        cfg.popupEnabled = true
    elseif arg == "off" then
        cfg.popupEnabled = false
    else
        cfg.popupEnabled = not cfg.popupEnabled
    end

    print("|cff00ff00[MRT]|r Notify-Popup: " .. (cfg.popupEnabled and "AN" or "AUS"))
end

SLASH_MRTNOTIFYSOUND1 = "/mrtnotifysound"
SlashCmdList["MRTNOTIFYSOUND"] = function(msg)
    local cfg = GetNotifierConfig()
    local command = (msg or ""):match("^%s*(.-)%s*$")
    local mode, value = command:match("^(%S+)%s*(.-)$")
    mode = string.lower(mode or "")

    if mode == "none" then
        cfg.soundMode = "none"
        print("|cff00ff00[MRT]|r Notify-Sound: AUS")
        return
    end

    if mode == "kit" then
        local id = tonumber(value)
        if not id then
            print("|cffff0000[MRT]|r Nutzung: /mrtnotifysound kit <SoundKitID>")
            return
        end
        cfg.soundMode = "kit"
        cfg.soundKitID = id
        print("|cff00ff00[MRT]|r Notify-Sound: KIT " .. id)
        return
    end

    if mode == "file" then
        if not value or value == "" then
            print("|cffff0000[MRT]|r Nutzung: /mrtnotifysound file <Dateipfad>")
            return
        end
        cfg.soundMode = "file"
        cfg.soundFilePath = value
        print("|cff00ff00[MRT]|r Notify-Sound: FILE gesetzt")
        return
    end

    print("|cffff0000[MRT]|r Nutzung: /mrtnotifysound none | kit <ID> | file <Pfad>")
end

SLASH_MRTNOTIFYAUTOHIDE1 = "/mrtnotifyautohide"
SlashCmdList["MRTNOTIFYAUTOHIDE"] = function(msg)
    local cfg = GetNotifierConfig()
    local seconds = tonumber((msg or ""):match("^%s*(.-)%s*$"))
    if not seconds or seconds < 0 then
        print("|cffff0000[MRT]|r Nutzung: /mrtnotifyautohide <Sekunden>=0+")
        return
    end

    cfg.autoHideSeconds = seconds
    print("|cff00ff00[MRT]|r Notify AutoHide: " .. seconds .. "s")
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtnotify", "zeigt Notifier-Popup sofort")
    MRT.RegisterHelpCommand("/mrtnotifypopup on|off|toggle", "Popup ein/aus")
    MRT.RegisterHelpCommand("/mrtnotifysound none|kit <ID>|file <Pfad>", "Sound-Modus setzen")
    MRT.RegisterHelpCommand("/mrtnotifyautohide <Sekunden>", "AutoHide-Dauer setzen")
end
