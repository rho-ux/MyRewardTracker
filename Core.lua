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

-- =========================================================
-- DB Initialization
-- =========================================================
local function InitializeDB()

    -- Haupt-DB erstellen
    if not MyRewardTrackerDB then
        MyRewardTrackerDB = {}
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

    -- Per-Character DB (neuer Hauptspeicher fuer Char-Scans)
    if not MyRewardTrackerCharDB then
        MyRewardTrackerCharDB = {}
    end

    if not MyRewardTrackerCharDB.lastScan then
        MyRewardTrackerCharDB.lastScan = 0
    end
    if type(MyRewardTrackerCharDB.missionTable) ~= "table" then
        MyRewardTrackerCharDB.missionTable = {}
    end
    if type(MyRewardTrackerCharDB.worldQuests) ~= "table" then
        MyRewardTrackerCharDB.worldQuests = {}
    end
    if type(MyRewardTrackerCharDB.meta) ~= "table" then
        MyRewardTrackerCharDB.meta = {}
    end
    MyRewardTrackerCharDB.meta.charKey = charKey

    -- Einmalige Migration: alter accountweiter Char-Pfad -> char-spezifische DB
    local legacyChars = MyRewardTrackerDB.characters
    if (not MyRewardTrackerCharDB.meta.migratedFromAccountChars) and type(legacyChars) == "table" and legacyChars[charKey] then
        local legacy = legacyChars[charKey]
        if legacy and type(legacy) == "table" then
            if type(legacy.missionTable) == "table" and next(MyRewardTrackerCharDB.missionTable) == nil then
                MyRewardTrackerCharDB.missionTable = legacy.missionTable
            end
            if type(legacy.worldQuests) == "table" and next(MyRewardTrackerCharDB.worldQuests) == nil then
                MyRewardTrackerCharDB.worldQuests = legacy.worldQuests
            end
            if type(legacy.lastScan) == "number" and (MyRewardTrackerCharDB.lastScan or 0) == 0 then
                MyRewardTrackerCharDB.lastScan = legacy.lastScan
            end
        end
        MyRewardTrackerCharDB.meta.migratedFromAccountChars = true
    end

    -- Legacy-Cleanup (pro Charakter, sicher):
    -- Sobald die Migration fuer diesen Char abgeschlossen ist, wird der alte
    -- accountweite Char-Eintrag entfernt. Andere Chars bleiben unberuehrt,
    -- bis sie selbst eingeloggt/migriert wurden.
    if MyRewardTrackerCharDB.meta.migratedFromAccountChars and type(legacyChars) == "table" and legacyChars[charKey] then
        legacyChars[charKey] = nil
        if next(legacyChars) == nil then
            MyRewardTrackerDB.characters = nil
        end
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
