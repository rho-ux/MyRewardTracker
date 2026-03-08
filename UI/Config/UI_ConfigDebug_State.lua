local addonName, MRT = ...

MRT.ConfigDebug = MRT.ConfigDebug or {}
MRT.ConfigDebugState = MRT.ConfigDebugState or {}

local ConfigDebug = MRT.ConfigDebug
local S = MRT.ConfigDebugState

S.rows = S.rows or {}
S.controls = S.controls or {}

function S.GetDashboardCfg()
    if MRT.Config and MRT.Config.GetDashboardConfig then
        return MRT.Config:GetDashboardConfig()
    end
    return {}
end

function S.GetMultiCfg()
    if MRT.Config and MRT.Config.GetMultiDashboardConfig then
        return MRT.Config:GetMultiDashboardConfig()
    end
    return {}
end

function S.GetFilterCfg()
    if MRT.FilterConfig and MRT.FilterConfig.GetActive then
        return MRT.FilterConfig:GetActive()
    end
    return {}
end

function S.GetNotifierCfg()
    if MRT.NotifierConfig and MRT.NotifierConfig.Get then
        return MRT.NotifierConfig:Get()
    end
    return {}
end

function S.GetWQCfg()
    if MRT.Config and MRT.Config.GetWorldQuestConfig then
        return MRT.Config:GetWorldQuestConfig()
    end
    return {}
end

function S.CountTableKeys(t)
    if type(t) ~= "table" then return 0 end
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

function S.Trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function S.ClearTable(t)
    if type(t) ~= "table" then return end
    for k in pairs(t) do t[k] = nil end
end

function S.ParseIDList(text)
    local ids = {}
    local src = tostring(text or "")
    for token in string.gmatch(src, "[^,; %t\n\r]+") do
        local id = tonumber(token)
        if id and id > 0 then ids[#ids + 1] = math.floor(id) end
    end
    return ids
end

function S.ParseCurrencyMinList(text)
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

function S.BoolMapToText(t)
    if type(t) ~= "table" then return "" end
    local keys = {}
    for k, v in pairs(t) do
        if v then
            local id = tonumber(k)
            if id and id > 0 then keys[#keys + 1] = id end
        end
    end
    table.sort(keys)
    local parts = {}
    for _, id in ipairs(keys) do parts[#parts + 1] = tostring(id) end
    return table.concat(parts, ",")
end

function S.CurrencyMinMapToText(t)
    if type(t) ~= "table" then return "" end
    local keys = {}
    for k in pairs(t) do
        local id = tonumber(k)
        if id and id > 0 then keys[#keys + 1] = id end
    end
    table.sort(keys)
    local parts = {}
    for _, id in ipairs(keys) do
        local minv = tonumber(t[id]) or 0
        parts[#parts + 1] = tostring(id) .. ":" .. tostring(math.floor(minv))
    end
    return table.concat(parts, ",")
end

function S.RefreshTargets()
    if MRT.Scanner and MRT.Scanner.SyncTrackedFromCharacter then MRT.Scanner:SyncTrackedFromCharacter() end
    if MRT.Dashboard and MRT.Dashboard.Refresh then MRT.Dashboard:Refresh() end
    if MRT.MultiDebug and MRT.MultiDebug.Refresh then MRT.MultiDebug:Refresh() end
    if MRT.Notifier and MRT.Notifier.CheckMissions then MRT.Notifier:CheckMissions(false) end
end

function S.CreateSectionLabel(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("BOTTOMLEFT", x, y)
    fs:SetTextColor(1.0, 0.82, 0.0)
    fs:SetText(text)
    return fs
end

function S.CreateHint(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("BOTTOMLEFT", x, y)
    fs:SetText(text)
    return fs
end

function S.CreateSeparator(parent, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.12)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 14, y)
    line:SetPoint("BOTTOMRIGHT", -14, y)
    return line
end

function S.CreateToggle(parent, x, y, label, helpText, getter, setter)
    local btn = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    btn:SetPoint("BOTTOMLEFT", x, y)
    btn:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", btn, "RIGHT", 2, 1)
    txt:SetText(label .. " (" .. helpText .. ")")
    S.controls[#S.controls + 1] = { kind = "toggle", btn = btn, getter = getter }
    return btn
end

function S.CreateStepButton(parent, x, y, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(44, 22)
    btn:SetPoint("BOTTOMLEFT", x, y)
    btn:SetText(text)
    btn:SetScript("OnClick", function()
        onClick()
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)
    return btn
end

function S.CreateInputApply(parent, x, y, width, labelText, placeholder, onApply)
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
