local addonName, addon = ...

-- Functions
local CreateFrame, unpack = CreateFrame, unpack

-- WoW variables
local GameTooltip = GameTooltip

-- Constants
local ADDON_PREFIX = addonName .. "_"
local FRAME_BACKDROP = { bgFile = [[Interface\Buttons\WHITE8X8]],
                         edgeFile = [[Interface\Buttons\WHITE8X8]],
                         edgeSize = 1,
                         insets = { left = 1, right = 1, top = 1, bottom = 1 } }
local FRAME_BACKDROP_COLOR = { 0.22, 0.25, 0.28, 1 }
local FRAME_BACKDROP_BORDER_COLOR = { 0.06, 0.08, 0.09, 1 }
local BUTTON_BACKDROP = {
    bgFile = [[Interface\Buttons\WHITE8X8]],
    edgeFile = [[Interface\Buttons\WHITE8X8]],
    edgeSize = 1
}
local BUTTON_BACKDROP_COLOR = { 0, 0.55, 0.85, 0.6 }
local BUTTON_BACKDROP_BORDER_COLOR = FRAME_BACKDROP_BORDER_COLOR

-- Local Variables
local frames = {}

local function createParentFrame()
    local parentFrame = CreateFrame("Frame", ADDON_PREFIX .. "ParentFrame", UIParent, "BackdropTemplate")
    parentFrame:EnableMouse(true)
    parentFrame:SetToplevel(true)
    parentFrame:EnableKeyboard(false)
    parentFrame:SetClampedToScreen(true)
    parentFrame:SetFrameStrata("HIGH")
    parentFrame:SetSize(200, 95)
    parentFrame:SetBackdrop(FRAME_BACKDROP)
    parentFrame:SetBackdropColor(unpack(FRAME_BACKDROP_COLOR))
    parentFrame:SetBackdropBorderColor(unpack(FRAME_BACKDROP_BORDER_COLOR))
    parentFrame:SetPoint("CENTER")
    parentFrame:Hide()

    frames.ParentFrame = parentFrame
end

local function createValueText()
    local parentFrame = frames.ParentFrame

    local valueText = parentFrame:CreateFontString(nil, "ARTWORK", "CIS_TextTemplate")
    valueText:SetJustifyH("CENTER")
    valueText:SetJustifyV("MIDDLE")
    valueText:ClearAllPoints();
    valueText:SetPoint("TOP", parentFrame, "TOP", 0, -35)

    frames.ValueText = valueText
end

local function createTitleBar()
    local parentFrame = frames.ParentFrame

    local titleBar = CreateFrame("Frame", ADDON_PREFIX .. "TitleBar", parentFrame, "BackdropTemplate")
    titleBar:SetHeight(25)
    titleBar:SetBackdrop(FRAME_BACKDROP)
    titleBar:SetBackdropColor(unpack(FRAME_BACKDROP_COLOR))
    titleBar:SetBackdropBorderColor(unpack(FRAME_BACKDROP_BORDER_COLOR))
    titleBar:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0, 0)

    local titleText = titleBar:CreateFontString(nil, "ARTWORK", "CIS_TextTemplate")
    titleText:ClearAllPoints()
    titleText:SetPoint("CENTER")
    titleText:SetJustifyH("CENTER")
    titleText:SetText("|cffBF5FFFCooky|r Item Splitter")

    frames.TitleBar = titleBar
end

local function createCloseButton()
    local titleBar = frames.TitleBar
    local onEnterBackdropColor = { 0.6, 0.1, 0.1, 1 }
    local onLeaveBackdropColor = { 0.6, 0.1, 0.1, 0.6 }

    local closeButton = CreateFrame("Button", titleBar:GetName() .. "CloseButton", titleBar, "BackdropTemplate,CIS_ButtonTemplate")
    closeButton:RegisterForClicks("LeftButtonUp")
    closeButton:SetSize(18, 18)
    closeButton:SetBackdrop(FRAME_BACKDROP)
    closeButton:SetBackdropColor(0.6, 0.1, 0.1, 0.6)
    closeButton:SetBackdropBorderColor(0.6, 0.8, 0.9, 1)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -3, 0)
    closeButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(onEnterBackdropColor))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Close")
        GameTooltip:Show()
    end)
    closeButton:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(onLeaveBackdropColor))
        GameTooltip:Hide()
    end)
    closeButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(onEnterBackdropColor))
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Close")
        GameTooltip:Show()
    end)
    closeButton:SetScript("OnClick", function()
        GameTooltip:Hide()
        frames.ParentFrame:Hide()
    end)

    closeButton.text:ClearAllPoints();
    closeButton.text:SetPoint("CENTER", 0, 0)
    closeButton.text:SetText("X")
end

local function createLeftArrowButton()
    local parentFrame = frames.ParentFrame

    local leftArrowButton = CreateFrame("Button", parentFrame:GetName() .. "LeftArrowButton", parentFrame)
    leftArrowButton:SetSize(20, 20)
    leftArrowButton:SetPoint("LEFT", frames.ValueText, "LEFT", -42.5, 0)
    leftArrowButton:SetNormalTexture(leftArrowButton:CreateTexture(nil, "ARTWORK", "CIS_ArrowLeftTemplate"))
    leftArrowButton:SetHighlightTexture(leftArrowButton:CreateTexture(nil, "HIGHLIGHT", "CIS_ArrowLeftTemplate"))

    frames.LeftArrowButton = leftArrowButton
end

local function createRightArrowButton()
    local parentFrame = frames.ParentFrame

    local rightArrowButton = CreateFrame("Button", parentFrame:GetName() .. "RightArrowButton", parentFrame)
    rightArrowButton:SetSize(20, 20)
    rightArrowButton:SetPoint("RIGHT", frames.ValueText, "RIGHT", 42.5, 0)
    rightArrowButton:SetNormalTexture(rightArrowButton:CreateTexture(nil, "ARTWORK", "CIS_ArrowRightTemplate"))
    rightArrowButton:SetHighlightTexture(rightArrowButton:CreateTexture(nil, "HIGHLIGHT", "CIS_ArrowRightTemplate"))

    frames.RightArrowButton = rightArrowButton
end

local function createSplitOnceButton()
    local parentFrame = frames.ParentFrame

    local splitOnceButton = CreateFrame("Button", parentFrame:GetName() .. "SplitOnceButton", parentFrame, "CIS_ButtonTemplate")
    splitOnceButton:SetBackdrop(BUTTON_BACKDROP)
    splitOnceButton:SetBackdropBorderColor(unpack(BUTTON_BACKDROP_BORDER_COLOR))
    splitOnceButton:SetBackdropColor(unpack(BUTTON_BACKDROP_COLOR))
    splitOnceButton:SetPoint("TOPRIGHT", frames.ValueText, "BOTTOM", -5, -10)

    splitOnceButton.text:SetText("Split")

    frames.SplitOnceButton = splitOnceButton
end

local function createSplitAllButton()
    local parentFrame = frames.ParentFrame

    local splitAllButton = CreateFrame("Button", parentFrame:GetName() .. "SplitAllButton", parentFrame, "CIS_ButtonTemplate")
    splitAllButton:SetBackdrop(BUTTON_BACKDROP)
    splitAllButton:SetBackdropBorderColor(unpack(BUTTON_BACKDROP_BORDER_COLOR))
    splitAllButton:SetBackdropColor(unpack(BUTTON_BACKDROP_COLOR))
    splitAllButton:SetPoint("TOPLEFT", frames.ValueText, "BOTTOM", 5, -10)

    splitAllButton.text:SetText("Auto-Split")

    frames.SplitAllButton = splitAllButton
end

local function createGuildBankSplitButton()
    local parentFrame = frames.ParentFrame

    local guildBankSplitButton = CreateFrame("Button", parentFrame:GetName() .. "GuildBankSplitButton", parentFrame, "CIS_ButtonTemplate")
    guildBankSplitButton:SetBackdrop(BUTTON_BACKDROP)
    guildBankSplitButton:SetBackdropBorderColor(unpack(BUTTON_BACKDROP_BORDER_COLOR))
    guildBankSplitButton:SetBackdropColor(unpack(BUTTON_BACKDROP_COLOR))
    guildBankSplitButton:SetSize(180, 25)
    guildBankSplitButton:SetPoint("BOTTOM", parentFrame, "BOTTOM", 0, 10)
    guildBankSplitButton:SetScript("OnShow", function()
        parentFrame:SetHeight(125)
    end)
    guildBankSplitButton:SetScript("OnHide", function()
        parentFrame:SetHeight(95)
    end)
    guildBankSplitButton:Hide()

    guildBankSplitButton.text:SetText("Auto-Split Into GBank")

    frames.GuildBankSplitButton = guildBankSplitButton
end

local function createBuyOnceButton()
    local parentFrame = frames.ParentFrame

    local buyOnceButton = CreateFrame("Button", parentFrame:GetName() .. "BuyOnceButton", parentFrame, "CIS_ButtonTemplate")
    buyOnceButton:SetBackdrop(BUTTON_BACKDROP)
    buyOnceButton:SetBackdropBorderColor(unpack(BUTTON_BACKDROP_BORDER_COLOR))
    buyOnceButton:SetBackdropColor(unpack(BUTTON_BACKDROP_COLOR))
    buyOnceButton:SetSize(55, 25)
    buyOnceButton:SetPoint("TOPRIGHT", frames.ValueText, "BOTTOM", -35, -10)
    buyOnceButton:Hide()

    buyOnceButton.text:SetText("Buy")

    frames.BuyOnceButton = buyOnceButton
end

local function createBuyStacksButton()
    local parentFrame = frames.ParentFrame

    local buyStacksButton = CreateFrame("Button", parentFrame:GetName() .. "BuyStacksButton", parentFrame, "CIS_ButtonTemplate")
    buyStacksButton:SetBackdrop(BUTTON_BACKDROP)
    buyStacksButton:SetBackdropBorderColor(unpack(BUTTON_BACKDROP_BORDER_COLOR))
    buyStacksButton:SetBackdropColor(unpack(BUTTON_BACKDROP_COLOR))
    buyStacksButton:SetSize(115, 25)
    buyStacksButton:SetPoint("TOPLEFT", frames.ValueText, "BOTTOM", -25, -10)
    buyStacksButton:Hide()

    buyStacksButton.text:SetText("Buy Stacks")

    frames.BuyStacksButton = buyStacksButton
end

createParentFrame()
createValueText()
createTitleBar()
createCloseButton()

createLeftArrowButton()
createRightArrowButton()

createSplitOnceButton()
createSplitAllButton()

createGuildBankSplitButton()

createBuyOnceButton()
createBuyStacksButton()

addon.frames = frames

