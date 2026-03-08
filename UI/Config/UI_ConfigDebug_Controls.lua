local addonName, MRT = ...

local ConfigDebug = MRT.ConfigDebug or {}
local S = MRT.ConfigDebugState or {}

local function BuildControls()
    local d = S.GetDashboardCfg()
    local m = S.GetMultiCfg()
    local f = S.GetFilterCfg()
    local n = S.GetNotifierCfg()
    local wq = S.GetWQCfg()

    local leftX = 14
    local rightX = 680
    local col = 210

    S.CreateSectionLabel(S.frame, leftX, 620, "Char Layout")
    S.CreateToggle(S.frame, leftX + (col * 0), 596, "SortDebug", "sort text", function() return d.showSortDebug end, function(v) d.showSortDebug = v end)
    S.CreateToggle(S.frame, leftX + (col * 1), 596, "StatusColors", "status color", function() return d.showStatusColors end, function(v) d.showStatusColors = v end)
    S.CreateToggle(S.frame, leftX + (col * 2), 596, "MissionHL", "highlight block", function() return d.showMissionHighlight end, function(v) d.showMissionHighlight = v end)
    S.CreateToggle(S.frame, leftX + (col * 0), 574, "RewardDetails", "details", function() return d.showRewardDetails end, function(v) d.showRewardDetails = v end)
    S.CreateToggle(S.frame, leftX + (col * 1), 574, "CompactList", "compact", function() return d.compactList end, function(v) d.compactList = v end)
    S.CreateToggle(S.frame, leftX + (col * 2), 574, "ExpHeaders", "exp headers", function() return d.showExpansionHeaders end, function(v) d.showExpansionHeaders = v end)
    S.CreateToggle(S.frame, leftX + (col * 0), 552, "RewHeaders", "reward headers", function() return d.showRewardHeaders end, function(v) d.showRewardHeaders = v end)
    S.CreateToggle(S.frame, leftX + (col * 1), 552, "CharGold", "group", function() return d.showGroupGold end, function(v) d.showGroupGold = v end)
    S.CreateToggle(S.frame, leftX + (col * 2), 552, "CharCurr", "group", function() return d.showGroupCurrency end, function(v) d.showGroupCurrency = v end)
    S.CreateToggle(S.frame, leftX + (col * 0), 530, "CharItems", "group", function() return d.showGroupItems end, function(v) d.showGroupItems = v end)
    S.CreateToggle(S.frame, leftX + (col * 1), 530, "CharAnima", "group", function() return d.showGroupAnima end, function(v) d.showGroupAnima = v end)

    S.CreateStepButton(S.frame, leftX, 504, "F-", function() d.fontSize = math.max(10, (tonumber(d.fontSize) or 13) - 1) end)
    S.CreateStepButton(S.frame, leftX + 48, 504, "F+", function() d.fontSize = math.min(20, (tonumber(d.fontSize) or 13) + 1) end)
    S.CreateHint(S.frame, leftX + 96, 508, "font")
    S.CreateStepButton(S.frame, leftX + 156, 504, "LH-", function() d.lineHeight = math.max(16, (tonumber(d.lineHeight) or 18) - 1) end)
    S.CreateStepButton(S.frame, leftX + 204, 504, "LH+", function() d.lineHeight = math.min(28, (tonumber(d.lineHeight) or 18) + 1) end)
    S.CreateHint(S.frame, leftX + 252, 508, "line")
    S.CreateStepButton(S.frame, leftX + 312, 504, "SP-", function() d.splitRatio = math.max(35, (tonumber(d.splitRatio) or 50) - 1) end)
    S.CreateStepButton(S.frame, leftX + 360, 504, "SP+", function() d.splitRatio = math.min(65, (tonumber(d.splitRatio) or 50) + 1) end)
    S.CreateHint(S.frame, leftX + 408, 508, "split")

    S.CreateSectionLabel(S.frame, rightX, 620, "Multi Layout")
    S.CreateToggle(S.frame, rightX + (col * 0), 596, "M-ExpHdr", "exp headers", function() return m.showExpansionHeaders end, function(v) m.showExpansionHeaders = v end)
    S.CreateToggle(S.frame, rightX + (col * 1), 596, "M-RewHdr", "reward headers", function() return m.showRewardHeaders end, function(v) m.showRewardHeaders = v end)
    S.CreateToggle(S.frame, rightX + (col * 2), 596, "M-Status", "status colors", function() return m.showStatusColors end, function(v) m.showStatusColors = v end)
    S.CreateToggle(S.frame, rightX + (col * 0), 574, "M-Highlight", "show block", function() return m.showMissionHighlight end, function(v) m.showMissionHighlight = v end)
    S.CreateToggle(S.frame, rightX + (col * 1), 574, "M-Gold", "group", function() return m.multiShowGold end, function(v) m.multiShowGold = v end)
    S.CreateToggle(S.frame, rightX + (col * 2), 574, "M-Curr", "group", function() return m.multiShowCurrency end, function(v) m.multiShowCurrency = v end)
    S.CreateToggle(S.frame, rightX + (col * 0), 552, "M-Items", "group", function() return m.multiShowItems end, function(v) m.multiShowItems = v end)
    S.CreateToggle(S.frame, rightX + (col * 1), 552, "M-Anima", "group", function() return m.multiShowAnima end, function(v) m.multiShowAnima = v end)

    S.CreateStepButton(S.frame, rightX, 504, "MF-", function() m.fontSize = math.max(10, (tonumber(m.fontSize) or 13) - 1) end)
    S.CreateStepButton(S.frame, rightX + 48, 504, "MF+", function() m.fontSize = math.min(20, (tonumber(m.fontSize) or 13) + 1) end)
    S.CreateHint(S.frame, rightX + 96, 508, "font")
    S.CreateStepButton(S.frame, rightX + 156, 504, "MLH-", function() m.lineHeight = math.max(16, (tonumber(m.lineHeight) or 18) - 1) end)
    S.CreateStepButton(S.frame, rightX + 204, 504, "MLH+", function() m.lineHeight = math.min(28, (tonumber(m.lineHeight) or 18) + 1) end)
    S.CreateHint(S.frame, rightX + 252, 508, "line")
    S.CreateStepButton(S.frame, rightX + 312, 504, "MSP-", function() m.topSplitRatio = math.max(40, (tonumber(m.topSplitRatio) or 56) - 1) end)
    S.CreateStepButton(S.frame, rightX + 360, 504, "MSP+", function() m.topSplitRatio = math.min(75, (tonumber(m.topSplitRatio) or 56) + 1) end)
    S.CreateHint(S.frame, rightX + 408, 508, "split")

    S.CreateSectionLabel(S.frame, leftX, 466, "Filter + Notifier")
    S.CreateToggle(S.frame, leftX, 444, "AnimaBypass", "ignore normal filter", function() return f.AnimaBypassFilter end, function(v) f.AnimaBypassFilter = v end)
    S.CreateToggle(S.frame, leftX + 300, 444, "Popup", "show notifier popup", function() return n.popupEnabled end, function(v) n.popupEnabled = v end)
    S.CreateToggle(S.frame, leftX + 520, 444, "AutoHide", "on/off", function() return (tonumber(n.autoHideSeconds) or 0) > 0 end, function(v)
        if v then
            if (tonumber(n.autoHideSeconds) or 0) <= 0 then n.autoHideSeconds = 8 end
        else
            n.autoHideSeconds = 0
        end
    end)
    S.CreateToggle(S.frame, leftX + 760, 444, "Notify Highlights", "only highlight hits", function() return n.highlightsOnly end, function(v)
        n.highlightsOnly = v
        print("|cff00ff00[MRT]|r Notify nur Highlights: " .. (v and "AN" or "AUS"))
    end)

    S.CreateHint(S.frame, leftX, 414, "GoldMinimum im Feld unten")
    S.CreateInputApply(S.frame, leftX + 14, 380, 120, "autoHide Sekunden", tostring(tonumber(n.autoHideSeconds) or 0), function(text)
        local v = tonumber(S.Trim(text)) or 0
        if v < 0 then v = 0 end
        n.autoHideSeconds = math.floor(v)
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)
    S.CreateStepButton(S.frame, leftX + 220, 380, "SM", function()
        local mode = tostring(n.soundMode or "none")
        if mode == "none" then n.soundMode = "kit" elseif mode == "kit" then n.soundMode = "file" else n.soundMode = "none" end
    end)
    S.CreateHint(S.frame, leftX + 268, 384, "soundMode")
    S.CreateInputApply(S.frame, leftX + 320, 380, 140, "soundKitID direkt setzen", tostring(tonumber(n.soundKitID) or 0), function(text)
        local v = tonumber(S.Trim(text)) or 0
        if v < 0 then v = 0 end
        n.soundKitID = math.floor(v)
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)
    S.CreateInputApply(S.frame, leftX + 560, 380, 300, "soundFilePath direkt setzen", tostring(n.soundFilePath or ""), function(text)
        local v = S.Trim(text)
        if v == "" then n.soundFilePath = nil else n.soundFilePath = v end
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)

    S.CreateSeparator(S.frame, 360)

    local function ApplyBoolMapFromInput(target, text)
        if type(target) ~= "table" then return end
        S.ClearTable(target)
        local ids = S.ParseIDList(text)
        for _, id in ipairs(ids) do target[id] = true end
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end

    local function ApplyCurrencyMapFromInput(target, text)
        if type(target) ~= "table" then return end
        S.ClearTable(target)
        local pairsOut = S.ParseCurrencyMinList(text)
        for _, p in ipairs(pairsOut) do target[p.id] = p.minv end
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end

    S.CreateSectionLabel(S.frame, 14, 348, "Mission-Modul (CSV IDs) - accountweit")
    local row1Y, row2Y = 302, 254
    local col1X, col2X, col3X = 14, 470, 926

    S.CreateInputApply(S.frame, col1X, row1Y, 320, "Filter ItemWhitelist IDs", S.BoolMapToText(f.ItemWhitelist), function(text)
        f.ItemWhitelist = f.ItemWhitelist or {}
        ApplyBoolMapFromInput(f.ItemWhitelist, text)
    end)
    S.CreateInputApply(S.frame, col2X, row1Y, 320, "Filter CurrencyMinimum (id:min)", S.CurrencyMinMapToText(f.CurrencyMinimum), function(text)
        f.CurrencyMinimum = f.CurrencyMinimum or {}
        ApplyCurrencyMapFromInput(f.CurrencyMinimum, text)
    end)
    S.CreateInputApply(S.frame, col3X, row1Y, 300, "Filter MissionWhitelist IDs", S.BoolMapToText(f.MissionWhitelist), function(text)
        f.MissionWhitelist = f.MissionWhitelist or {}
        ApplyBoolMapFromInput(f.MissionWhitelist, text)
    end)
    S.CreateInputApply(S.frame, col1X, row2Y, 320, "Multi Highlight ItemIDs", S.BoolMapToText(m.highlightItemIDs), function(text)
        m.highlightItemIDs = m.highlightItemIDs or {}
        ApplyBoolMapFromInput(m.highlightItemIDs, text)
    end)
    S.CreateInputApply(S.frame, col2X, row2Y, 320, "Multi Highlight CurrencyIDs", S.BoolMapToText(m.highlightCurrencyIDs), function(text)
        m.highlightCurrencyIDs = m.highlightCurrencyIDs or {}
        ApplyBoolMapFromInput(m.highlightCurrencyIDs, text)
    end)
    S.CreateInputApply(S.frame, col3X, row2Y, 160, "GoldMinimum direkt setzen", tostring(tonumber(f.GoldMinimum) or 0), function(text)
        local v = tonumber(S.Trim(text)) or 0
        if v < 0 then v = 0 end
        f.GoldMinimum = math.floor(v)
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)

    S.CreateSeparator(S.frame, 236)

    S.CreateSectionLabel(S.frame, 14, 218, "WorldQuest-Modul (Platzhalter)")
    S.CreateHint(S.frame, 14, 202, "passive Felder fuer spaetere WQ-Umsetzung")
    S.CreateToggle(S.frame, col1X, 178, "WQ Enabled", "scanner placeholder", function() return wq.enabled end, function(v) wq.enabled = v end)
    S.CreateToggle(S.frame, col2X, 178, "WQ im Char-Dashboard", "placeholder", function() return wq.showOnCharacterDashboard end, function(v) wq.showOnCharacterDashboard = v end)
    S.CreateToggle(S.frame, col3X, 178, "WQ Anima Tracking", "placeholder", function() return wq.trackAnima end, function(v) wq.trackAnima = v end)
    S.CreateInputApply(S.frame, col1X, 136, 320, "WQ GoldMinimum", tostring(tonumber(wq.goldMinimum) or 0), function(text)
        local v = tonumber(S.Trim(text)) or 0
        if v < 0 then v = 0 end
        wq.goldMinimum = math.floor(v)
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)
    S.CreateInputApply(S.frame, col2X, 136, 320, "WQ ZoneWhitelist (mapIDs CSV)", S.BoolMapToText(wq.zoneWhitelist), function(text)
        wq.zoneWhitelist = wq.zoneWhitelist or {}
        S.ClearTable(wq.zoneWhitelist)
        local ids = S.ParseIDList(text)
        for _, id in ipairs(ids) do wq.zoneWhitelist[id] = true end
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)
    S.CreateInputApply(S.frame, col3X, 136, 300, "WQ QuestBlacklist IDs", S.BoolMapToText(wq.questBlacklist), function(text)
        wq.questBlacklist = wq.questBlacklist or {}
        S.ClearTable(wq.questBlacklist)
        local ids = S.ParseIDList(text)
        for _, id in ipairs(ids) do wq.questBlacklist[id] = true end
        S.RefreshTargets()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)
    S.CreateSeparator(S.frame, 88)
end

function S.CreateMainUI()
    S.frame = CreateFrame("Frame", "MRT_ConfigDebugFrame", UIParent, "BackdropTemplate")
    S.frame:SetSize(1320, 700)
    S.frame:SetPoint("CENTER", 0, 20)
    S.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    S.frame:SetFrameLevel(200)
    S.frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    S.frame:SetBackdropColor(0, 0, 0, 0.9)
    S.frame:SetMovable(true)
    S.frame:EnableMouse(true)
    S.frame:RegisterForDrag("LeftButton")
    S.frame:SetScript("OnDragStart", S.frame.StartMoving)
    S.frame:SetScript("OnDragStop", S.frame.StopMovingOrSizing)
    S.frame:Hide()

    table.insert(UISpecialFrames, "MRT_ConfigDebugFrame")

    local title = S.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("MRT Config Debug (gross)")

    local closeButton = CreateFrame("Button", nil, S.frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)

    local infoButton = CreateFrame("Button", nil, S.frame, "UIPanelButtonTemplate")
    infoButton:SetSize(150, 24)
    infoButton:SetPoint("BOTTOMLEFT", 14, 14)
    infoButton:SetText("Config Info")
    infoButton:SetScript("OnClick", function()
        if ConfigDebug.ToggleInfo then ConfigDebug.ToggleInfo() end
    end)

    local refreshButton = CreateFrame("Button", nil, S.frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(110, 24)
    refreshButton:SetPoint("BOTTOMRIGHT", -14, 14)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        if ConfigDebug.Refresh then ConfigDebug.Refresh() end
    end)

    BuildControls()
end
