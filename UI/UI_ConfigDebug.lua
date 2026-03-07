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

local function Trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ClearTable(t)
    if type(t) ~= "table" then
        return
    end
    for k in pairs(t) do
        t[k] = nil
    end
end

local function ParseIDList(text)
    local ids = {}
    local src = tostring(text or "")
    for token in string.gmatch(src, "[^,; %t\n\r]+") do
        local id = tonumber(token)
        if id and id > 0 then
            ids[#ids + 1] = math.floor(id)
        end
    end
    return ids
end

local function ParseCurrencyMinList(text)
    local pairsOut = {}
    local src = tostring(text or "")
    for token in string.gmatch(src, "[^,;]+") do
        local idText, minText = token:match("%s*(%d+)%s*:%s*(%d+)%s*")
        local id = tonumber(idText)
        local minv = tonumber(minText)
        if id and id > 0 and minv and minv >= 0 then
            pairsOut[#pairsOut + 1] = { id = math.floor(id), minv = math.floor(minv) }
        end
    end
    return pairsOut
end

local function BoolMapToText(t)
    if type(t) ~= "table" then
        return ""
    end
    local keys = {}
    for k, v in pairs(t) do
        if v then
            local id = tonumber(k)
            if id and id > 0 then
                keys[#keys + 1] = id
            end
        end
    end
    table.sort(keys)
    local parts = {}
    for _, id in ipairs(keys) do
        parts[#parts + 1] = tostring(id)
    end
    return table.concat(parts, ",")
end

local function CurrencyMinMapToText(t)
    if type(t) ~= "table" then
        return ""
    end
    local keys = {}
    for k in pairs(t) do
        local id = tonumber(k)
        if id and id > 0 then
            keys[#keys + 1] = id
        end
    end
    table.sort(keys)
    local parts = {}
    for _, id in ipairs(keys) do
        local minv = tonumber(t[id]) or 0
        parts[#parts + 1] = tostring(id) .. ":" .. tostring(math.floor(minv))
    end
    return table.concat(parts, ",")
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
    row:SetWidth(1100)
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

local function BuildLines()
    local d = GetDashboardCfg()
    local m = GetMultiCfg()
    local f = GetFilterCfg()
    local n = GetNotifierCfg()
    local lines = {}

    lines[#lines + 1] = "|cffffcc00Config Debug (gross, komplett)|r"
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Char Dashboard|r"
    lines[#lines + 1] = "  fontSize/lineHeight/splitRatio: " .. tostring(d.fontSize) .. "/" .. tostring(d.lineHeight) .. "/" .. tostring(d.splitRatio)
    lines[#lines + 1] = "  headerStyle/showStatusColors: " .. tostring(d.headerStyle) .. "/" .. tostring(d.showStatusColors)
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Multi Dashboard|r"
    lines[#lines + 1] = "  fontSize/lineHeight/topSplitRatio: " .. tostring(m.fontSize) .. "/" .. tostring(m.lineHeight) .. "/" .. tostring(m.topSplitRatio)
    lines[#lines + 1] = "  showExpansionHeaders/showRewardHeaders/showStatusColors: " .. tostring(m.showExpansionHeaders) .. "/" .. tostring(m.showRewardHeaders) .. "/" .. tostring(m.showStatusColors)
    lines[#lines + 1] = "  Highlight IDs item/currency: " .. tostring(CountTableKeys(m.highlightItemIDs)) .. "/" .. tostring(CountTableKeys(m.highlightCurrencyIDs))
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Filter Engine|r"
    lines[#lines + 1] = "  GoldMinimum/AnimaBypass: " .. tostring(f.GoldMinimum) .. "/" .. tostring(f.AnimaBypassFilter)
    lines[#lines + 1] = "  ItemWhitelist IDs: " .. tostring(CountTableKeys(f.ItemWhitelist))
    lines[#lines + 1] = "  CurrencyMinimum IDs: " .. tostring(CountTableKeys(f.CurrencyMinimum))
    lines[#lines + 1] = "  MissionWhitelist IDs: " .. tostring(CountTableKeys(f.MissionWhitelist))
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffffcc00Notifier|r"
    lines[#lines + 1] = "  popupEnabled/soundMode/autoHide: " .. tostring(n.popupEnabled) .. "/" .. tostring(n.soundMode) .. "/" .. tostring(n.autoHideSeconds)
    lines[#lines + 1] = "  soundKitID/soundFilePath: " .. tostring(n.soundKitID) .. "/" .. tostring(n.soundFilePath)
    lines[#lines + 1] = ""

    lines[#lines + 1] = "|cffff8800TODO (gemerkt): MissionBlacklist + WorldQuestBlacklist als extra Filter|r"

    return lines
end

local function CreateSectionLabel(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("BOTTOMLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function CreateHint(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("BOTTOMLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function CreateToggle(parent, x, y, label, helpText, getter, setter)
    local btn = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    btn:SetPoint("BOTTOMLEFT", x, y)
    btn:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        RefreshTargets()
        ConfigDebug.Refresh()
    end)
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("LEFT", btn, "RIGHT", 2, 1)
    txt:SetText(label .. " (" .. helpText .. ")")
    controls[#controls + 1] = { kind = "toggle", btn = btn, getter = getter }
    return btn
end

local function CreateStepButton(parent, x, y, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(44, 22)
    btn:SetPoint("BOTTOMLEFT", x, y)
    btn:SetText(text)
    btn:SetScript("OnClick", function()
        onClick()
        RefreshTargets()
        ConfigDebug.Refresh()
    end)
    return btn
end

local function CreateInputApply(parent, x, y, width, labelText, placeholder, onApply)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("BOTTOMLEFT", x, y + 24)
    label:SetText(labelText)

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetSize(width, 22)
    box:SetPoint("BOTTOMLEFT", x, y)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self)
        onApply(self:GetText() or "")
        self:ClearFocus()
    end)

    if placeholder and placeholder ~= "" then
        box:SetText(placeholder)
        box:HighlightText(0, 0)
    end

    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(64, 22)
    btn:SetPoint("LEFT", box, "RIGHT", 8, 0)
    btn:SetText("Apply")
    btn:SetScript("OnClick", function()
        onApply(box:GetText() or "")
    end)

    return box, btn, label
end

local function BuildControls()
    local d = GetDashboardCfg()
    local m = GetMultiCfg()
    local f = GetFilterCfg()
    local n = GetNotifierCfg()

    local leftX = 14
    local rightX = 760
    local col = 210

    CreateSectionLabel(frame, leftX, 356, "Char Layout")
    CreateToggle(frame, leftX + (col * 0), 334, "SortDebug", "sort text", function() return d.showSortDebug end, function(v) d.showSortDebug = v end)
    CreateToggle(frame, leftX + (col * 1), 334, "StatusColors", "status color", function() return d.showStatusColors end, function(v) d.showStatusColors = v end)
    CreateToggle(frame, leftX + (col * 2), 334, "MissionHL", "highlight block", function() return d.showMissionHighlight end, function(v) d.showMissionHighlight = v end)
    CreateToggle(frame, leftX + (col * 0), 312, "RewardDetails", "details", function() return d.showRewardDetails end, function(v) d.showRewardDetails = v end)
    CreateToggle(frame, leftX + (col * 1), 312, "CompactList", "compact", function() return d.compactList end, function(v) d.compactList = v end)
    CreateToggle(frame, leftX + (col * 2), 312, "ExpHeaders", "exp headers", function() return d.showExpansionHeaders end, function(v) d.showExpansionHeaders = v end)
    CreateToggle(frame, leftX + (col * 0), 290, "RewHeaders", "reward headers", function() return d.showRewardHeaders end, function(v) d.showRewardHeaders = v end)
    CreateToggle(frame, leftX + (col * 1), 290, "CharGold", "group", function() return d.showGroupGold end, function(v) d.showGroupGold = v end)
    CreateToggle(frame, leftX + (col * 2), 290, "CharCurr", "group", function() return d.showGroupCurrency end, function(v) d.showGroupCurrency = v end)
    CreateToggle(frame, leftX + (col * 0), 268, "CharItems", "group", function() return d.showGroupItems end, function(v) d.showGroupItems = v end)
    CreateToggle(frame, leftX + (col * 1), 268, "CharAnima", "group", function() return d.showGroupAnima end, function(v) d.showGroupAnima = v end)

    CreateStepButton(frame, leftX, 242, "F-", function() d.fontSize = math.max(10, (tonumber(d.fontSize) or 13) - 1) end)
    CreateStepButton(frame, leftX + 48, 242, "F+", function() d.fontSize = math.min(20, (tonumber(d.fontSize) or 13) + 1) end)
    CreateHint(frame, leftX + 96, 246, "font")
    CreateStepButton(frame, leftX + 156, 242, "LH-", function() d.lineHeight = math.max(16, (tonumber(d.lineHeight) or 18) - 1) end)
    CreateStepButton(frame, leftX + 204, 242, "LH+", function() d.lineHeight = math.min(28, (tonumber(d.lineHeight) or 18) + 1) end)
    CreateHint(frame, leftX + 252, 246, "line")
    CreateStepButton(frame, leftX + 312, 242, "SP-", function() d.splitRatio = math.max(35, (tonumber(d.splitRatio) or 50) - 1) end)
    CreateStepButton(frame, leftX + 360, 242, "SP+", function() d.splitRatio = math.min(65, (tonumber(d.splitRatio) or 50) + 1) end)
    CreateHint(frame, leftX + 408, 246, "split")

    CreateSectionLabel(frame, rightX, 356, "Multi Layout")
    CreateToggle(frame, rightX + (col * 0), 334, "M-ExpHdr", "exp headers", function() return m.showExpansionHeaders end, function(v) m.showExpansionHeaders = v end)
    CreateToggle(frame, rightX + (col * 1), 334, "M-RewHdr", "reward headers", function() return m.showRewardHeaders end, function(v) m.showRewardHeaders = v end)
    CreateToggle(frame, rightX + (col * 2), 334, "M-Status", "status colors", function() return m.showStatusColors end, function(v) m.showStatusColors = v end)
    CreateToggle(frame, rightX + (col * 0), 312, "M-Highlight", "show block", function() return m.showMissionHighlight end, function(v) m.showMissionHighlight = v end)
    CreateToggle(frame, rightX + (col * 1), 312, "M-Gold", "group", function() return m.multiShowGold end, function(v) m.multiShowGold = v end)
    CreateToggle(frame, rightX + (col * 2), 312, "M-Curr", "group", function() return m.multiShowCurrency end, function(v) m.multiShowCurrency = v end)
    CreateToggle(frame, rightX + (col * 0), 290, "M-Items", "group", function() return m.multiShowItems end, function(v) m.multiShowItems = v end)
    CreateToggle(frame, rightX + (col * 1), 290, "M-Anima", "group", function() return m.multiShowAnima end, function(v) m.multiShowAnima = v end)

    CreateStepButton(frame, rightX, 242, "MF-", function() m.fontSize = math.max(10, (tonumber(m.fontSize) or 13) - 1) end)
    CreateStepButton(frame, rightX + 48, 242, "MF+", function() m.fontSize = math.min(20, (tonumber(m.fontSize) or 13) + 1) end)
    CreateHint(frame, rightX + 96, 246, "font")
    CreateStepButton(frame, rightX + 156, 242, "MLH-", function() m.lineHeight = math.max(16, (tonumber(m.lineHeight) or 18) - 1) end)
    CreateStepButton(frame, rightX + 204, 242, "MLH+", function() m.lineHeight = math.min(28, (tonumber(m.lineHeight) or 18) + 1) end)
    CreateHint(frame, rightX + 252, 246, "line")
    CreateStepButton(frame, rightX + 312, 242, "MSP-", function() m.topSplitRatio = math.max(40, (tonumber(m.topSplitRatio) or 56) - 1) end)
    CreateStepButton(frame, rightX + 360, 242, "MSP+", function() m.topSplitRatio = math.min(75, (tonumber(m.topSplitRatio) or 56) + 1) end)
    CreateHint(frame, rightX + 408, 246, "split")

    CreateSectionLabel(frame, leftX, 236, "Filter + Notifier")
    CreateToggle(frame, leftX, 214, "AnimaBypass", "ignore normal filter", function() return f.AnimaBypassFilter end, function(v) f.AnimaBypassFilter = v end)
    CreateToggle(frame, leftX + 230, 214, "Popup", "show notifier popup", function() return n.popupEnabled end, function(v) n.popupEnabled = v end)

    CreateStepButton(frame, leftX, 190, "G-", function() f.GoldMinimum = math.max(0, (tonumber(f.GoldMinimum) or 0) - 1) end)
    CreateStepButton(frame, leftX + 48, 190, "G+", function() f.GoldMinimum = (tonumber(f.GoldMinimum) or 0) + 1 end)
    CreateHint(frame, leftX + 96, 194, "GoldMinimum")

    CreateStepButton(frame, leftX + 220, 190, "A-", function() n.autoHideSeconds = math.max(0, (tonumber(n.autoHideSeconds) or 0) - 1) end)
    CreateStepButton(frame, leftX + 268, 190, "A+", function() n.autoHideSeconds = (tonumber(n.autoHideSeconds) or 0) + 1 end)
    CreateHint(frame, leftX + 316, 194, "autoHide")

    CreateStepButton(frame, leftX + 430, 190, "SM", function()
        local mode = tostring(n.soundMode or "none")
        if mode == "none" then
            n.soundMode = "kit"
        elseif mode == "kit" then
            n.soundMode = "file"
        else
            n.soundMode = "none"
        end
    end)
    CreateHint(frame, leftX + 478, 194, "soundMode")

    CreateInputApply(frame, leftX + 620, 188, 160,
        "soundKitID direkt setzen",
        tostring(tonumber(n.soundKitID) or 0),
        function(text)
            local v = tonumber(Trim(text)) or 0
            if v < 0 then v = 0 end
            n.soundKitID = math.floor(v)
            RefreshTargets()
            ConfigDebug.Refresh()
        end)

    local function ApplyBoolMapFromInput(target, text)
        ClearTable(target)
        local ids = ParseIDList(text)
        for _, id in ipairs(ids) do
            target[id] = true
        end
        RefreshTargets()
        ConfigDebug.Refresh()
    end

    local function ApplyCurrencyMapFromInput(target, text)
        ClearTable(target)
        local pairsOut = ParseCurrencyMinList(text)
        for _, p in ipairs(pairsOut) do
            target[p.id] = p.minv
        end
        RefreshTargets()
        ConfigDebug.Refresh()
    end

    CreateSectionLabel(frame, 14, 162, "ID Editoren (CSV) - accountweit")

    local row1Y = 118
    local row2Y = 66
    local col1X = 14
    local col2X = 470
    local col3X = 926

    CreateInputApply(frame, col1X, row1Y, 320,
        "Filter ItemWhitelist IDs",
        BoolMapToText(f.ItemWhitelist),
        function(text)
            ApplyBoolMapFromInput(f.ItemWhitelist or {}, text)
        end)

    CreateInputApply(frame, col2X, row1Y, 320,
        "Filter CurrencyMinimum (id:min)",
        CurrencyMinMapToText(f.CurrencyMinimum),
        function(text)
            ApplyCurrencyMapFromInput(f.CurrencyMinimum or {}, text)
        end)

    CreateInputApply(frame, col3X, row1Y, 300,
        "Filter MissionWhitelist IDs",
        BoolMapToText(f.MissionWhitelist),
        function(text)
            ApplyBoolMapFromInput(f.MissionWhitelist or {}, text)
        end)

    CreateInputApply(frame, col1X, row2Y, 320,
        "Multi Highlight ItemIDs",
        BoolMapToText(m.highlightItemIDs),
        function(text)
            ApplyBoolMapFromInput(m.highlightItemIDs or {}, text)
        end)

    CreateInputApply(frame, col2X, row2Y, 320,
        "Multi Highlight CurrencyIDs",
        BoolMapToText(m.highlightCurrencyIDs),
        function(text)
            ApplyBoolMapFromInput(m.highlightCurrencyIDs or {}, text)
        end)

    CreateInputApply(frame, col3X, row2Y, 160,
        "GoldMinimum direkt setzen",
        tostring(tonumber(f.GoldMinimum) or 0),
        function(text)
            local v = tonumber(Trim(text)) or 0
            if v < 0 then v = 0 end
            f.GoldMinimum = math.floor(v)
            RefreshTargets()
            ConfigDebug.Refresh()
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
    frame:SetSize(1420, 920)
    frame:SetPoint("CENTER", 0, 40)
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
    title:SetText("MRT Config Debug (gross)")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -40)
    scroll:SetPoint("BOTTOMRIGHT", -34, 380)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1320, 500)
    scroll:SetScrollChild(content)

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(110, 24)
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
