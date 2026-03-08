-- =========================================
-- MyRewardTracker - Notifier
-- Phase 4
-- Meldet gefilterte fertige Missionen
-- =========================================

local addonName, MRT = ...
local Notifier = CreateFrame("Frame")
MRT.Notifier = Notifier

local loginHintShown = false

function MRT.Notifier:GetSummaryCounts()
    if MRT.NotifierSummary and MRT.NotifierSummary.GetCounts then
        return MRT.NotifierSummary.GetCounts()
    end
    return { available = 0, ready = 0, wq = 0, running = 0, filteredTotal = 0 }
end

function MRT.Notifier:CheckMissions(showPopup)
    local availableCount = 0
    local readyCount = 0
    local wqCount = 0

    if MRT.NotifierSummary and MRT.NotifierSummary.GetPopupCounts then
        availableCount, readyCount, wqCount = MRT.NotifierSummary.GetPopupCounts()
    end

    if showPopup and MRT.NotifierPopup and MRT.NotifierPopup.ShowSummaryPopup then
        MRT.NotifierPopup.ShowSummaryPopup(availableCount or 0, readyCount or 0, wqCount or 0)
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
    local cfg = MRT.NotifierConfig and MRT.NotifierConfig.Get and MRT.NotifierConfig.Get()
    if not cfg then
        return
    end

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
    local cfg = MRT.NotifierConfig and MRT.NotifierConfig.Get and MRT.NotifierConfig.Get()
    if not cfg then
        return
    end

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
    local cfg = MRT.NotifierConfig and MRT.NotifierConfig.Get and MRT.NotifierConfig.Get()
    if not cfg then
        return
    end

    local seconds = tonumber((msg or ""):match("^%s*(.-)%s*$"))
    if not seconds or seconds < 0 then
        print("|cffff0000[MRT]|r Nutzung: /mrtnotifyautohide <Sekunden>=0+")
        return
    end

    cfg.autoHideSeconds = seconds
    print("|cff00ff00[MRT]|r Notify AutoHide: " .. seconds .. "s")
end

SLASH_MRTNOTIFYHIGHLIGHTS1 = "/mrtnotifyhighlights"
SlashCmdList["MRTNOTIFYHIGHLIGHTS"] = function(msg)
    local cfg = MRT.NotifierConfig and MRT.NotifierConfig.Get and MRT.NotifierConfig.Get()
    if not cfg then
        return
    end

    local arg = string.lower((msg or ""):match("^%s*(.-)%s*$"))
    if arg == "on" then
        cfg.highlightsOnly = true
    elseif arg == "off" then
        cfg.highlightsOnly = false
    else
        cfg.highlightsOnly = not cfg.highlightsOnly
    end
    print("|cff00ff00[MRT]|r Notify nur Highlights: " .. (cfg.highlightsOnly and "AN" or "AUS"))
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtnotify", "zeigt Notifier-Popup sofort")
    MRT.RegisterHelpCommand("/mrtnotifypopup on|off|toggle", "Popup ein/aus")
    MRT.RegisterHelpCommand("/mrtnotifysound none|kit <ID>|file <Pfad>", "Sound-Modus setzen")
    MRT.RegisterHelpCommand("/mrtnotifyautohide <Sekunden>", "AutoHide-Dauer setzen")
    MRT.RegisterHelpCommand("/mrtnotifyhighlights on|off|toggle", "Notifier nur bei Highlight-Treffern")
end
