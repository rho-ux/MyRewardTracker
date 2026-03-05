-- =========================================
-- MyRewardTracker - Filter Engine
-- Phase 3
-- Bewertet gespeicherte Missionsdaten
-- =========================================

local addonName, MRT = ...
local FilterEngine = {}

local FilterConfig = MRT.FilterConfig

-- ---------------------------------
-- Mission bewerten
-- ---------------------------------
function FilterEngine:CheckMission(missionID, mission)

    if not mission or not mission.rewards then
        return false
    end

    local config = FilterConfig:GetActive()

    for _, reward in ipairs(mission.rewards) do

        -- ---------------------------------
        -- Item Whitelist
        -- ---------------------------------
        if reward.itemID and config.ItemWhitelist[reward.itemID] then
            return true
        end

        -- ---------------------------------
        -- Currency Minimum
        -- ---------------------------------
        if reward.currencyID then

             local min = config.CurrencyMinimum[reward.currencyID]

             if min and reward.quantity and reward.quantity >= min then
                 return true
             end

        end

        -- ---------------------------------
        -- Gold Minimum
        -- ---------------------------------
        if reward.currencyID == 0 then
            local minGold = config.GoldMinimum

            if minGold and minGold > 0 and reward.quantity and reward.quantity >= minGold then
                return true
            end
        end

    end

    -- ---------------------------------
    -- MissionID Whitelist
    -- ---------------------------------
    if config.MissionWhitelist[missionID] then
        return true
    end

    return false
end


-- ---------------------------------
-- Alle Missionen eines Char prüfen
-- ---------------------------------
function FilterEngine:ScanCharacter(charKey)
    local charData = MyRewardTrackerCharDB
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
