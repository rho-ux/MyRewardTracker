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

local function TryScan(force)

    if not MRT.Scanner then
        return
    end

    local now = time()

    if not force and now - lastScan < SCAN_COOLDOWN then
        return
    end

    lastScan = now

    MRT.Scanner:StartScan()

end

Controller:RegisterEvent("PLAYER_LOGIN")
Controller:RegisterEvent("GARRISON_MISSION_LIST_UPDATE")
Controller:RegisterEvent("GARRISON_MISSION_FINISHED")

Controller:SetScript("OnEvent", function(self, event)

    if event == "PLAYER_LOGIN" then

        if loginScanDone then
            return
        end

        loginScanDone = true

        C_Timer.After(3, function()
            TryScan()
        end)

        -- Sicherheits-Scan nach Login, falls API-Daten erst spaeter vollstaendig sind.
        C_Timer.After(8, function()
            TryScan(true)
        end)

    elseif event == "GARRISON_MISSION_LIST_UPDATE" then

        TryScan()

        -- Sicherheits-Scan fuer spaet nachgeladene Missionsdaten.
        C_Timer.After(2, function()
            TryScan(true)
        end)

    elseif event == "GARRISON_MISSION_FINISHED" then

        C_Timer.After(1, function()
            TryScan()
        end)

    end

end)

MRT.ScannerController = Controller
