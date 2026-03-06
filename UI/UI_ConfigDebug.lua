local addonName, MRT = ...

local ConfigDebug = {}
MRT.ConfigDebug = ConfigDebug

local frame
local content
local rows = {}
local controls = {}

local function GetDashboardCfg()
    if MRT.Config and MRT.Config.GetDashboardConfig then
        return MRT.Config:GetDashboardConfig()
    end
    return {}
end

local function GetMultiCfg()
    if MRT.Config and MRT.Config.GetMultiDashboardConfig then
        return MRT.Config:GetMultiDashboardConfig()
    end
    return {}
end

local function GetFilterCfg()
    if MRT.FilterConfig and MRT.FilterConfig.GetActive then
        return MRT.FilterConfig:GetActive()
    end
    return {}
end

local function GetNotifierCfg()
    if MRT.NotifierConfig and MRT.NotifierConfig.Get then
        return MRT.NotifierConfig:Get()
    end
    return {}
end

local function RefreshTargets()
    if MRT.Scanner and MRT.Scanner.SyncTrackedFromCharacter then
        MRT.Scanner:SyncTrackedFromCharacter()
    end
    if MRT.Dashboard and MRT.Dashboard.Refresh then
        MRT.Dashboard:Refresh()
    end
    if MRT.MultiDebug and MRT.MultiDebug.Refresh then
        MRT.MultiDebug:Refresh()
    end
    if MRT.Notifier and MRT.Notifier.CheckMissions then
        MRT.Notifier:CheckMissions(false)
    end
end

local function EnsureRow(index)
    local row = rows[index]
    if row then
        return row
    end
    row = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetWidth(560)
    row:SetJustifyH("LEFT")
    row:SetJustifyV("TOP")
    rows[index] = row
    return row
end

local function RenderLines(lines)
    for i, text in ipairs(lines) do
        local row = EnsureRow(i)
        row:SetText(text)
        row:Show()
    end
    for i = #lines + 1, #rows do
        rows[i]:Hide()
    end
    content:SetHeight(math.max(1, (#lines * 18) + 8))
end

local function CountTableKeys(t)
    if type(t) ~= "table" then
        return 0
    end
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end
    return c
end

local function BuildLines()
    local d = GetDashboardCfg()
    local m = GetMultiCfg()
    local f = GetFilterCfg()
    local n = GetNotifierCfg()
    local lines = {}

    lines[#lines + 1] = "|cffffcc00Config Debug (accountweit)|r"
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Dashboard (Charakter)|r"
    lines[#lines + 1] = "  showSortDebug: " .. tostring(d.showSortDebug)
    lines[#lines + 1] = "  showRewardDetails: " .. tostring(d.showRewardDetails)
    lines[#lines + 1] = "  compactList: " .. tostring(d.compactList)
    lines[#lines + 1] = "  showGroupGold/Currency/Items/Anima: " .. tostring(d.showGroupGold) .. "/" .. tostring(d.showGroupCurrency) .. "/" .. tostring(d.showGroupItems) .. "/" .. tostring(d.showGroupAnima)
    lines[#lines + 1] = "  fontSize: " .. tostring(d.fontSize)
    lines[#lines + 1] = "  lineHeight: " .. tostring(d.lineHeight)
    lines[#lines + 1] = "  headerStyle: " .. tostring(d.headerStyle)
    lines[#lines + 1] = "  splitRatio: " .. tostring(d.splitRatio)
    lines[#lines + 1] = "  showMissionHighlight: " .. tostring(d.showMissionHighlight)
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Dashboard (Multi-Char)|r"
    lines[#lines + 1] = "  multiShowGold/Currency/Items/Anima: " .. tostring(m.multiShowGold) .. "/" .. tostring(m.multiShowCurrency) .. "/" .. tostring(m.multiShowItems) .. "/" .. tostring(m.multiShowAnima)
    lines[#lines + 1] = "  showExpansionHeaders/showRewardHeaders/showStatusColors: " .. tostring(m.showExpansionHeaders) .. "/" .. tostring(m.showRewardHeaders) .. "/" .. tostring(m.showStatusColors)
    lines[#lines + 1] = "  fontSize: " .. tostring(m.fontSize)
    lines[#lines + 1] = "  lineHeight: " .. tostring(m.lineHeight)
    lines[#lines + 1] = "  headerStyle: " .. tostring(m.headerStyle)
    lines[#lines + 1] = "  topSplitRatio: " .. tostring(m.topSplitRatio)
    lines[#lines + 1] = "  showMissionHighlight: " .. tostring(m.showMissionHighlight)
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Filter|r"
    lines[#lines + 1] = "  GoldMinimum: " .. tostring(f.GoldMinimum)
    lines[#lines + 1] = "  AnimaBypassFilter: " .. tostring(f.AnimaBypassFilter)
    lines[#lines + 1] = "  ItemWhitelist Eintraege: " .. tostring(CountTableKeys(f.ItemWhitelist))
    lines[#lines + 1] = "  CurrencyMinimum Eintraege: " .. tostring(CountTableKeys(f.CurrencyMinimum))
    lines[#lines + 1] = "  MissionWhitelist Eintraege: " .. tostring(CountTableKeys(f.MissionWhitelist))
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Notifier|r"
    lines[#lines + 1] = "  popupEnabled: " .. tostring(n.popupEnabled)
    lines[#lines + 1] = "  soundMode: " .. tostring(n.soundMode)
    lines[#lines + 1] = "  soundKitID: " .. tostring(n.soundKitID)
    lines[#lines + 1] = "  soundFilePath: " .. tostring(n.soundFilePath)
    lines[#lines + 1] = "  autoHideSeconds: " .. tostring(n.autoHideSeconds)

    return lines
end

local function CreateToggle(parent, x, y, label, getter, setter)
    local btn = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    btn:SetPoint("BOTTOMLEFT", x, y)
    btn:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        RefreshTargets()
        ConfigDebug.Refresh()
    end)
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("LEFT", btn, "RIGHT", 2, 1)
    txt:SetText(label)
    controls[#controls + 1] = { kind = "toggle", btn = btn, getter = getter }
    return btn
end

local function CreateStepButton(parent, x, y, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(42, 22)
    btn:SetPoint("BOTTOMLEFT", x, y)
    btn:SetText(text)
    btn:SetScript("OnClick", function()
        onClick()
        RefreshTargets()
        ConfigDebug.Refresh()
    end)
    return btn
end

local function BuildControls()
    local d = GetDashboardCfg()
    local m = GetMultiCfg()
    local f = GetFilterCfg()
    local n = GetNotifierCfg()

    CreateToggle(frame, 14, 14, "SortDebug", function() return d.showSortDebug end, function(v) d.showSortDebug = v end)
    CreateToggle(frame, 114, 14, "RewardDetails", function() return d.showRewardDetails end, function(v) d.showRewardDetails = v end)
    CreateToggle(frame, 244, 14, "CompactList", function() return d.compactList end, function(v) d.compactList = v end)
    CreateToggle(frame, 354, 14, "M-Highlight", function() return m.showMissionHighlight end, function(v) m.showMissionHighlight = v end)
    CreateToggle(frame, 494, 14, "AnimaBypass", function() return f.AnimaBypassFilter end, function(v) f.AnimaBypassFilter = v end)
    CreateToggle(frame, 14, 66, "MissionHighlight", function() return d.showMissionHighlight end, function(v) d.showMissionHighlight = v end)
    CreateToggle(frame, 174, 66, "M-ExpHdr", function() return m.showExpansionHeaders end, function(v) m.showExpansionHeaders = v end)
    CreateToggle(frame, 294, 66, "M-RewHdr", function() return m.showRewardHeaders end, function(v) m.showRewardHeaders = v end)
    CreateToggle(frame, 414, 66, "M-Status", function() return m.showStatusColors end, function(v) m.showStatusColors = v end)

    CreateStepButton(frame, 14, 40, "G-", function() f.GoldMinimum = math.max(0, (tonumber(f.GoldMinimum) or 0) - 1) end)
    CreateStepButton(frame, 60, 40, "G+", function() f.GoldMinimum = (tonumber(f.GoldMinimum) or 0) + 1 end)
    CreateStepButton(frame, 114, 40, "A-", function() n.autoHideSeconds = math.max(0, (tonumber(n.autoHideSeconds) or 0) - 1) end)
    CreateStepButton(frame, 160, 40, "A+", function() n.autoHideSeconds = (tonumber(n.autoHideSeconds) or 0) + 1 end)
    CreateStepButton(frame, 214, 40, "F-", function() d.fontSize = math.max(10, (tonumber(d.fontSize) or 13) - 1) end)
    CreateStepButton(frame, 260, 40, "F+", function() d.fontSize = math.min(20, (tonumber(d.fontSize) or 13) + 1) end)

    CreateStepButton(frame, 314, 40, "Pop", function() n.popupEnabled = not n.popupEnabled end)
    CreateStepButton(frame, 360, 40, "SM", function()
        local mode = tostring(n.soundMode or "none")
        if mode == "none" then
            n.soundMode = "kit"
        elseif mode == "kit" then
            n.soundMode = "file"
        else
            n.soundMode = "none"
        end
    end)

    CreateStepButton(frame, 114, 66, "LH-", function() d.lineHeight = math.max(16, (tonumber(d.lineHeight) or 18) - 1) end)
    CreateStepButton(frame, 160, 66, "LH+", function() d.lineHeight = math.min(28, (tonumber(d.lineHeight) or 18) + 1) end)
    CreateStepButton(frame, 214, 66, "SP-", function() d.splitRatio = math.max(35, (tonumber(d.splitRatio) or 50) - 1) end)
    CreateStepButton(frame, 260, 66, "SP+", function() d.splitRatio = math.min(65, (tonumber(d.splitRatio) or 50) + 1) end)
    CreateStepButton(frame, 314, 66, "HS", function()
        if tostring(d.headerStyle) == "emphasis" then
            d.headerStyle = "normal"
        else
            d.headerStyle = "emphasis"
        end
    end)

    CreateStepButton(frame, 14, 92, "MF-", function() m.fontSize = math.max(10, (tonumber(m.fontSize) or 13) - 1) end)
    CreateStepButton(frame, 60, 92, "MF+", function() m.fontSize = math.min(20, (tonumber(m.fontSize) or 13) + 1) end)
    CreateStepButton(frame, 114, 92, "MLH-", function() m.lineHeight = math.max(16, (tonumber(m.lineHeight) or 18) - 1) end)
    CreateStepButton(frame, 160, 92, "MLH+", function() m.lineHeight = math.min(28, (tonumber(m.lineHeight) or 18) + 1) end)
    CreateStepButton(frame, 214, 92, "MSP-", function() m.topSplitRatio = math.max(40, (tonumber(m.topSplitRatio) or 60) - 1) end)
    CreateStepButton(frame, 260, 92, "MSP+", function() m.topSplitRatio = math.min(75, (tonumber(m.topSplitRatio) or 60) + 1) end)
    CreateStepButton(frame, 314, 92, "MHS", function()
        if tostring(m.headerStyle) == "emphasis" then
            m.headerStyle = "normal"
        else
            m.headerStyle = "emphasis"
        end
    end)
end

function ConfigDebug.Refresh()
    if not frame then
        return
    end

    for _, c in ipairs(controls) do
        if c.kind == "toggle" and c.btn and c.getter then
            c.btn:SetChecked(c.getter() and true or false)
        end
    end
    RenderLines(BuildLines())
end

local function CreateUI()
    frame = CreateFrame("Frame", "MRT_ConfigDebugFrame", UIParent, "BackdropTemplate")
    frame:SetSize(620, 520)
    frame:SetPoint("CENTER", -120, 40)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(200)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    table.insert(UISpecialFrames, "MRT_ConfigDebugFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("MRT Config Debug")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -40)
    scroll:SetPoint("BOTTOMRIGHT", -34, 72)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(560, 380)
    scroll:SetScrollChild(content)

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 24)
    refreshButton:SetPoint("BOTTOMRIGHT", -14, 14)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        ConfigDebug.Refresh()
    end)

    BuildControls()
end

function ConfigDebug.Toggle()
    if not frame then
        CreateUI()
    end
    if frame:IsShown() then
        frame:Hide()
        return
    end
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(200)
    frame:Raise()
    ConfigDebug.Refresh()
    frame:Show()
end

SLASH_MRTCONFIGDEBUG1 = "/mrtconfigdebug"
SlashCmdList["MRTCONFIGDEBUG"] = function()
    ConfigDebug.Toggle()
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtconfigdebug", "oeffnet/schliesst Config-Debug-UI")
end
