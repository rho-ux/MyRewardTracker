-- =========================================
-- MyRewardTracker - Debug UI
-- Phase 2 Development Tool
-- =========================================

local addonName, MRT = ...
local DebugUI = {}

local frame
local scrollFrame
local content
local text

local function BuildText()
    if MRT.DebugText and MRT.DebugText.BuildText then
        return MRT.DebugText.BuildText()
    end
    return "DebugText-Modul nicht geladen."
end

local function CreateUI()
    frame = CreateFrame("Frame", "MRT_DebugFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background"
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(460, 380)
    scrollFrame:SetScrollChild(content)

    text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT")
    text:SetJustifyH("LEFT")
    text:SetWidth(440)
end

function DebugUI:Toggle()
    if not frame then
        CreateUI()
    end

    if frame:IsShown() then
        frame:Hide()
    else
        text:SetText(BuildText())
        frame:Show()
    end
end

SLASH_MRTDEBUG1 = "/mrtdebug"
SlashCmdList["MRTDEBUG"] = function()
    DebugUI:Toggle()
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtdebug", "oeffnet/schliesst Debug-UI")
end

MRT.DebugUI = DebugUI
