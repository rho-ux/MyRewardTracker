local addonName, MRT = ...

MRT = MRT or {}
_G.MRT = MRT

local frame = CreateFrame("Frame")

MRT.HelpCommands = MRT.HelpCommands or {}

function MRT.RegisterHelpCommand(command, description)
    if not command or command == "" then
        return
    end

    local key = string.lower(command)
    MRT.HelpCommands[key] = {
        command = command,
        description = description or ""
    }
end

SLASH_MRTHELP1 = "/mrthelp"
SlashCmdList["MRTHELP"] = function()
    print("|cff00ff00[MRT]|r Befehle:")

    local list = {}
    for _, info in pairs(MRT.HelpCommands) do
        list[#list + 1] = info
    end

    table.sort(list, function(a, b)
        return string.lower(a.command) < string.lower(b.command)
    end)

    for _, info in ipairs(list) do
        if info.description ~= "" then
            print("  " .. info.command .. " - " .. info.description)
        else
            print("  " .. info.command)
        end
    end
end

MRT.RegisterHelpCommand("/mrthelp", "zeigt diese Hilfe")

-- =========================================================
-- Utility: Character Key
-- =========================================================
local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName()
    return name .. "-" .. realm
end

-- =========================================================
-- DB Initialization
-- =========================================================
local function InitializeDB()

    -- Haupt-DB erstellen
    if not MyRewardTrackerDB then
        MyRewardTrackerDB = {}
    end

    -- Characters Tabelle
    if not MyRewardTrackerDB.characters then
        MyRewardTrackerDB.characters = {}
    end

    -- Account Bereich
    if not MyRewardTrackerDB.account then
        MyRewardTrackerDB.account = {}
    end

    if not MyRewardTrackerDB.account.tracked then
        MyRewardTrackerDB.account.tracked = {}
    end

    -- Charakter anlegen
    local charKey = GetCharacterKey()

    if not MyRewardTrackerDB.characters[charKey] then
        MyRewardTrackerDB.characters[charKey] = {
            lastScan = 0,
            missionTable = {},
            worldQuests = {}
        }
    end

    print("|cff00ff00[MRT]|r DB initialized for:", charKey)
end

-- =========================================================
-- Event Handling
-- =========================================================
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event)
if event == "PLAYER_LOGIN" then
    InitializeDB()
end
end)
