local addonName, MRT = ...

local MultiDebug = {}
MRT.MultiDebug = MultiDebug

local frame
local content
local rows = {}
local optionGold
local optionCurrency
local optionItems
local optionAnima
local optionDetail

local Data = MRT.MultiDebugData or {}

local function GetCfg()
    if MRT.Config and MRT.Config.GetDashboardConfig then
        return MRT.Config:GetDashboardConfig()
    end
    return {
        multiShowGold = true,
        multiShowCurrency = true,
        multiShowItems = true,
        multiShowAnima = true,
        multiDetailLong = true,
    }
end

local function BuildLines()
    if Data.BuildLines then
        return Data.BuildLines(GetCfg())
    end
    return {
        "|cffff0000MultiDebugData nicht geladen.|r",
    }
end

local function PrintTrackedDump()
    if Data.PrintTrackedDump then
        Data.PrintTrackedDump()
        return
    end
    print("|cffff0000[MRT]|r MultiDebugData nicht geladen.")
end

local function EnsureRow(index)
    local row = rows[index]
    if row then
        return row
    end

    row = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 18))
    row:SetWidth(700)
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

local function Refresh()
    if not frame then
        return
    end
    local cfg = GetCfg()
    if optionGold then optionGold:SetChecked(cfg.multiShowGold and true or false) end
    if optionCurrency then optionCurrency:SetChecked(cfg.multiShowCurrency and true or false) end
    if optionItems then optionItems:SetChecked(cfg.multiShowItems and true or false) end
    if optionAnima then optionAnima:SetChecked(cfg.multiShowAnima and true or false) end
    if optionDetail then optionDetail:SetChecked(cfg.multiDetailLong and true or false) end
    RenderLines(BuildLines())
end

local function CreateOptionToggle(parent, x, y, labelText, initialValue, onChanged)
    local btn = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    btn:SetPoint("BOTTOMLEFT", x, y)
    btn:SetChecked(initialValue and true or false)
    btn:SetScript("OnClick", function(self)
        onChanged(self:GetChecked() and true or false)
    end)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", btn, "RIGHT", 2, 1)
    label:SetText(labelText)

    return btn
end

local function CreateUI()
    frame = CreateFrame("Frame", "MRT_MultiDebugFrame", UIParent, "BackdropTemplate")
    frame:SetSize(780, 520)
    frame:SetPoint("CENTER", 120, 40)
    frame:SetFrameStrata("DIALOG")
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

    table.insert(UISpecialFrames, "MRT_MultiDebugFrame")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("MRT Multi-Char Debug")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -40)
    scroll:SetPoint("BOTTOMRIGHT", -34, 44)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(700, 420)
    scroll:SetScrollChild(content)

    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 24)
    refreshButton:SetPoint("BOTTOMLEFT", 14, 14)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        Refresh()
    end)

    local cfg = GetCfg()
    optionGold = CreateOptionToggle(frame, 130, 16, "Gold", cfg.multiShowGold, function(checked)
        cfg.multiShowGold = checked
        Refresh()
    end)
    optionCurrency = CreateOptionToggle(frame, 240, 16, "Waehrung", cfg.multiShowCurrency, function(checked)
        cfg.multiShowCurrency = checked
        Refresh()
    end)
    optionItems = CreateOptionToggle(frame, 380, 16, "Items", cfg.multiShowItems, function(checked)
        cfg.multiShowItems = checked
        Refresh()
    end)
    optionAnima = CreateOptionToggle(frame, 490, 16, "Anima", cfg.multiShowAnima, function(checked)
        cfg.multiShowAnima = checked
        Refresh()
    end)
    optionDetail = CreateOptionToggle(frame, 600, 16, "Lang-Detail", cfg.multiDetailLong, function(checked)
        cfg.multiDetailLong = checked
        Refresh()
    end)
end

function MultiDebug:Toggle()
    if not frame then
        CreateUI()
    end

    if frame:IsShown() then
        frame:Hide()
        return
    end

    Refresh()
    frame:Show()
end

function MultiDebug:Refresh()
    if frame and frame:IsShown() then
        Refresh()
    end
end

SLASH_MRTMULTIDEBUG1 = "/mrtmultidebug"
SlashCmdList["MRTMULTIDEBUG"] = function()
    MultiDebug:Toggle()
end

SLASH_MRTMULTIDUMP1 = "/mrtmultidump"
SlashCmdList["MRTMULTIDUMP"] = function()
    PrintTrackedDump()
end

if MRT.RegisterHelpCommand then
    MRT.RegisterHelpCommand("/mrtmultidebug", "oeffnet/schliesst Multi-Char-Debug-UI")
    MRT.RegisterHelpCommand("/mrtmultidump", "druckt Multi-Char Summen+Gruppen in den Chat")
end
