local addonName, MRT = ...

MRT.NotifierPopup = MRT.NotifierPopup or {}
local NotifierPopup = MRT.NotifierPopup

local popup
local lineAvailable
local lineReady
local lineWQ
local lastSummary
local popupToken = 0

local function EnsurePopup()
    if popup then
        return
    end

    popup = CreateFrame("Frame", "MRT_NotifyPopup", UIParent, "BackdropTemplate")
    popup:SetSize(320, 170)
    popup:SetPoint("CENTER", 0, 220)
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    popup:SetBackdropColor(0, 0, 0, 0.9)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup:Hide()

    table.insert(UISpecialFrames, "MRT_NotifyPopup")

    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("MyRewardTracker")

    lineAvailable = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineAvailable:SetPoint("TOPLEFT", 16, -42)
    lineAvailable:SetJustifyH("LEFT")

    lineReady = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineReady:SetPoint("TOPLEFT", 16, -64)
    lineReady:SetJustifyH("LEFT")

    lineWQ = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineWQ:SetPoint("TOPLEFT", 16, -86)
    lineWQ:SetJustifyH("LEFT")

    local openButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    openButton:SetSize(180, 24)
    openButton:SetPoint("BOTTOM", 0, 14)
    openButton:SetText("Dashboard oeffnen")
    openButton:SetScript("OnClick", function()
        if MRT.NotifierConfig and MRT.NotifierConfig.OpenDashboard then
            MRT.NotifierConfig.OpenDashboard()
        end
        popup:Hide()
    end)

    local closeButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)
end

function NotifierPopup.ShowSummaryPopup(availableCount, readyCount, wqCount)
    local cfg = MRT.NotifierConfig and MRT.NotifierConfig.Ensure and MRT.NotifierConfig.Ensure()
    if not cfg or not cfg.popupEnabled then
        return
    end

    EnsurePopup()

    local total = availableCount + readyCount + wqCount
    if total == 0 then
        if popup:IsShown() then
            popup:Hide()
        end
        lastSummary = nil
        return
    end

    local summary = availableCount .. "|" .. readyCount .. "|" .. wqCount
    if summary == lastSummary and popup:IsShown() then
        return
    end

    lineAvailable:SetText(availableCount .. " Mission verfuegbar")
    lineReady:SetText(readyCount .. " Mission fertig")
    lineWQ:SetText(wqCount .. " WQ verfuegbar")

    popup:Show()
    lastSummary = summary

    if MRT.NotifierConfig and MRT.NotifierConfig.TryPlaySound then
        MRT.NotifierConfig.TryPlaySound(cfg)
    end

    popupToken = popupToken + 1
    local currentToken = popupToken
    if cfg.autoHideSeconds > 0 then
        C_Timer.After(cfg.autoHideSeconds, function()
            if popup and popup:IsShown() and currentToken == popupToken then
                popup:Hide()
            end
        end)
    end
end
