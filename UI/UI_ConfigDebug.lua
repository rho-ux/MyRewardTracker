local addonName, MRT = ...

MRT.ConfigDebug = MRT.ConfigDebug or {}
MRT.ConfigDebugState = MRT.ConfigDebugState or {}

local ConfigDebug = MRT.ConfigDebug
local S = MRT.ConfigDebugState

function ConfigDebug.Refresh()
    if not S.frame then
        return
    end

    for _, c in ipairs(S.controls or {}) do
        if c.kind == "toggle" and c.btn and c.getter then
            c.btn:SetChecked(c.getter() and true or false)
        end
    end

    if S.infoFrame and S.infoFrame:IsShown() and S.RenderLines and S.BuildLines then
        S.RenderLines(S.BuildLines())
    end
end

function ConfigDebug.Toggle()
    if not S.frame then
        if S.CreateMainUI then
            S.CreateMainUI()
        else
            return
        end
    end

    if S.frame:IsShown() then
        S.frame:Hide()
        return
    end

    S.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    S.frame:SetFrameLevel(200)
    S.frame:Raise()
    ConfigDebug.Refresh()
    S.frame:Show()
end

SLASH_MRTCONFIGDEBUG1 = "/mrtconfigdebug"
SlashCmdList["MRTCONFIGDEBUG"] = function()
    ConfigDebug.Toggle()
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtconfigdebug", "oeffnet/schliesst Config-Debug-UI")
end

