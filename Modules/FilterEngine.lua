-- =========================================
-- MyRewardTracker - Filter Engine
-- Phase 3
-- Bewertet gespeicherte Missionsdaten
-- =========================================

local addonName, MRT = ...
local FilterEngine = {}

-- zentrale FilterConfig laden
local Config = MRT.FilterConfig

-- ---------------------------------
-- Mission bewerten
-- ---------------------------------
function FilterEngine:CheckMission(missionID, mission)

    if not mission or not mission.rewards then
        return false
    end

    for _, reward in ipairs(mission.rewards) do

        -- ---------------------------------
        -- Item Whitelist
        -- ---------------------------------
        if reward.itemID and Config.ItemWhitelist[reward.itemID] then
            return true
        end

        -- ---------------------------------
        -- Currency Minimum
        -- ---------------------------------
        if reward.currencyID then

             local min = Config.CurrencyMinimum[reward.currencyID]

             if min and reward.quantity and reward.quantity >= min then
                 return true
             end

        end

        -- ---------------------------------
        -- Gold Minimum
        -- ---------------------------------
        if reward.currencyID == 0 then
            if reward.quantity and reward.quantity >= Config.GoldMinimum then
                return true
            end
        end

    end

    -- ---------------------------------
    -- MissionID Whitelist
    -- ---------------------------------
    if Config.MissionWhitelist[missionID] then
        return true
    end

    return false
end


-- ---------------------------------
-- Alle Missionen eines Char prüfen
-- ---------------------------------
function FilterEngine:ScanCharacter(charKey)

    if not MyRewardTrackerDB then return end
    if not MyRewardTrackerDB.characters then return end

    local charData = MyRewardTrackerDB.characters[charKey]
    if not charData then return end
    if not charData.missionTable then return end

    for missionID, mission in pairs(charData.missionTable) do

        local result = self:CheckMission(missionID, mission)

        if result then
            -- später für Dashboard / Notifier
        end

    end
end


-- Modul registrieren
MRT.FilterEngine = FilterEngine