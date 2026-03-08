local addonName, MRT = ...

local ConfigDebug = MRT.ConfigDebug or {}
local S = MRT.ConfigDebugState or {}

local function EnsureRow(index)
    local row = S.rows[index]
    if row then return row end
    if not S.content then return nil end
    row = S.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetWidth(1100)
    row:SetJustifyH("LEFT")
    row:SetJustifyV("TOP")
    S.rows[index] = row
    return row
end

function S.RenderLines(lines)
    if not S.content then return end
    for i, text in ipairs(lines) do
        local row = EnsureRow(i)
        if row then
            row:SetText(text)
            row:Show()
        end
    end
    for i = #lines + 1, #S.rows do
        S.rows[i]:Hide()
    end
    S.content:SetHeight(math.max(1, (#lines * 18) + 8))
end

function S.BuildLines()
    local d = S.GetDashboardCfg()
    local m = S.GetMultiCfg()
    local f = S.GetFilterCfg()
    local n = S.GetNotifierCfg()
    local wq = S.GetWQCfg()
    local lines = {}

    lines[#lines + 1] = "|cffffcc00Config Info|r"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "|cffffcc00Char Dashboard|r"
    lines[#lines + 1] = "  fontSize/lineHeight/splitRatio: " .. tostring(d.fontSize) .. "/" .. tostring(d.lineHeight) .. "/" .. tostring(d.splitRatio)
    lines[#lines + 1] = "  headerStyle/showStatusColors: " .. tostring(d.headerStyle) .. "/" .. tostring(d.showStatusColors)
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Multi Dashboard|r"
    lines[#lines + 1] = "  fontSize/lineHeight/topSplitRatio: " .. tostring(m.fontSize) .. "/" .. tostring(m.lineHeight) .. "/" .. tostring(m.topSplitRatio)
    lines[#lines + 1] = "  showExpansionHeaders/showRewardHeaders/showStatusColors: " .. tostring(m.showExpansionHeaders) .. "/" .. tostring(m.showRewardHeaders) .. "/" .. tostring(m.showStatusColors)
    lines[#lines + 1] = "  Highlight IDs item/currency: " .. tostring(S.CountTableKeys(m.highlightItemIDs)) .. "/" .. tostring(S.CountTableKeys(m.highlightCurrencyIDs))
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Filter Engine|r"
    lines[#lines + 1] = "  GoldMinimum/AnimaBypass: " .. tostring(f.GoldMinimum) .. "/" .. tostring(f.AnimaBypassFilter)
    lines[#lines + 1] = "  ItemWhitelist IDs: " .. tostring(S.CountTableKeys(f.ItemWhitelist))
    lines[#lines + 1] = "  CurrencyMinimum IDs: " .. tostring(S.CountTableKeys(f.CurrencyMinimum))
    lines[#lines + 1] = "  MissionWhitelist IDs: " .. tostring(S.CountTableKeys(f.MissionWhitelist))
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Notifier|r"
    lines[#lines + 1] = "  popupEnabled/soundMode/autoHide: " .. tostring(n.popupEnabled) .. "/" .. tostring(n.soundMode) .. "/" .. tostring(n.autoHideSeconds)
    lines[#lines + 1] = "  highlightsOnly: " .. tostring(n.highlightsOnly)
    lines[#lines + 1] = "  soundKitID/soundFilePath: " .. tostring(n.soundKitID) .. "/" .. tostring(n.soundFilePath)
    lines[#lines + 1] = "  Sound test quick guide:"
    lines[#lines + 1] = "   - KIT: soundMode=kit, soundKitID=1428"
    lines[#lines + 1] = "   - FILE (game): soundMode=file, soundFilePath=Sound\\Interface\\RaidWarning.ogg"
    lines[#lines + 1] = "   - FILE (addon): soundMode=file, soundFilePath=Interface\\AddOns\\MyRewardTracker\\Media\\ding.ogg"
    lines[#lines + 1] = "   - Use double backslash in SavedVariables text."
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00WorldQuest (Platzhalter-Config)|r"
    lines[#lines + 1] = "  enabled/showOnCharacterDashboard/trackAnima: " .. tostring(wq.enabled) .. "/" .. tostring(wq.showOnCharacterDashboard) .. "/" .. tostring(wq.trackAnima)
    lines[#lines + 1] = "  goldMinimum/zoneWhitelistCount/questBlacklistCount: " .. tostring(wq.goldMinimum) .. "/" .. tostring(S.CountTableKeys(wq.zoneWhitelist)) .. "/" .. tostring(S.CountTableKeys(wq.questBlacklist))
    lines[#lines + 1] = ""
    lines[#lines + 1] = "|cffff8800TODO (gemerkt): MissionBlacklist + WorldQuestBlacklist als extra Filter|r"
    return lines
end

local function CreateInfoUI()
    S.infoFrame = CreateFrame("Frame", "MRT_ConfigInfoFrame", UIParent, "BackdropTemplate")
    S.infoFrame:SetSize(900, 700)
    S.infoFrame:SetPoint("CENTER", 60, 20)
    S.infoFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    S.infoFrame:SetFrameLevel(210)
    S.infoFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    S.infoFrame:SetBackdropColor(0, 0, 0, 0.9)
    S.infoFrame:SetMovable(true)
    S.infoFrame:EnableMouse(true)
    S.infoFrame:RegisterForDrag("LeftButton")
    S.infoFrame:SetScript("OnDragStart", S.infoFrame.StartMoving)
    S.infoFrame:SetScript("OnDragStop", S.infoFrame.StopMovingOrSizing)
    S.infoFrame:Hide()

    table.insert(UISpecialFrames, "MRT_ConfigInfoFrame")

    local title = S.infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("MRT Config Info")

    local closeButton = CreateFrame("Button", nil, S.infoFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)

    local scroll = CreateFrame("ScrollFrame", nil, S.infoFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -40)
    scroll:SetPoint("BOTTOMRIGHT", -34, 14)

    S.content = CreateFrame("Frame", nil, scroll)
    S.content:SetSize(820, 500)
    scroll:SetScrollChild(S.content)
end

function ConfigDebug.ToggleInfo()
    if not S.infoFrame then
        CreateInfoUI()
    end
    if S.infoFrame:IsShown() then
        S.infoFrame:Hide()
        return
    end
    S.infoFrame:Raise()
    S.RenderLines(S.BuildLines())
    S.infoFrame:Show()
end
