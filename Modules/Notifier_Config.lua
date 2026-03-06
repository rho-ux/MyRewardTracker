local addonName, MRT = ...

MRT.NotifierConfig = MRT.NotifierConfig or {}
local NotifierConfig = MRT.NotifierConfig

function NotifierConfig.Ensure()
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

function NotifierConfig.Get()
    return NotifierConfig.Ensure()
end

function NotifierConfig.TryPlaySound(cfg)
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

function NotifierConfig.OpenDashboard()
    if MRT.Dashboard and MRT.Dashboard.Toggle then
        MRT.Dashboard:Toggle()
        return
    end

    if MRT.DebugUI and MRT.DebugUI.Toggle then
        MRT.DebugUI:Toggle()
    end
end
