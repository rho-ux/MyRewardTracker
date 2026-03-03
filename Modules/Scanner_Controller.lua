-- =========================================
-- MyRewardTracker - Scanner Controller
-- Startet Mission Scans über Events
-- Stabilisiert gegen Event-Spam
-- =========================================

local addonName, MRT = ...
local Controller = CreateFrame("Frame")

local lastScan = 0
local SCAN_COOLDOWN = 5
local loginScanDone = false

local function TryScan()

    if not MRT.Scanner then
        return
    end

    local now = time()

    if now - lastScan < SCAN_COOLDOWN then
        return
    end

    lastScan = now

    MRT.Scanner:StartScan()

end

Controller:RegisterEvent("PLAYER_LOGIN")
Controller:RegisterEvent("GARRISON_MISSION_LIST_UPDATE")

Controller:SetScript("OnEvent", function(self, event)

    if event == "PLAYER_LOGIN" then

        if loginScanDone then
            return
        end

        loginScanDone = true

        C_Timer.After(3, function()
            TryScan()
        end)

    elseif event == "GARRISON_MISSION_LIST_UPDATE" then

        TryScan()

    end

end)

MRT.ScannerController = Controller