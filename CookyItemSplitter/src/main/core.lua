local CIS = CreateFrame("Frame")
lockedSlots = nil
local baseContainer
local maxContainer
local containerType

local MaxBuffer = 5

-----------------
-- Util Functions
-----------------
local function SetSlotLocked(bag, slot)
    if not lockedSlots then
        lockedSlots = {}
    end

    if not lockedSlots[bag] then
        lockedSlots[bag] = {}
    end

    lockedSlots[bag][slot] = true
end

local function IsSlotLocked(bag, slot)
    if lockedSlots and lockedSlots[bag] and lockedSlots[bag][slot] then
        return true
    end

    return false
end

local function IsSlotFree(bag, slot)
    return not GetContainerItemLink(bag, slot)
end

local function ClearAllLockedSlots()
    lockedSlots = nil
end

local function IsBag(bag)
    local inventoryID = ContainerIDToInventoryID(bag)
    local bagLink = GetInventoryItemLink("player", inventoryID)

    if bagLink then
        return bagLink
    else
        return false
    end
end

local function GetNumFreeBagSlots(self)
    local freeSlots = 0

    if self.container == BANK_CONTAINER or (self.container >= NUM_BAG_SLOTS + 1 and self.container <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then -- Bank
        freeSlots = GetContainerNumFreeSlots(BANK_CONTAINER)

        for bag = BANK_CONTAINER, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
            if bag == BANK_CONTAINER + 1 then
                bag = NUM_BAG_SLOTS + 1
            end

            freeSlots = freeSlots + GetContainerNumFreeSlots(bag)
        end
    elseif self.container == REAGENTBANK_CONTAINER then -- Reagent Bank
        freeSlots = GetContainerNumFreeSlots(REAGENTBANK_CONTAINER)
    elseif self.container >= BACKPACK_CONTAINER and self.container <= NUM_BAG_SLOTS then -- Bags
        freeSlots = GetContainerNumFreeSlots(BACKPACK_CONTAINER)
        local containerBagType = BACKPACK_CONTAINER
        local itemFamily = GetItemFamily(self.link)

        for bag = 1, NUM_BAG_SLOTS do
            local bagLink = IsBag(bag)

            if bagLink then
                containerBagType = GetItemFamily(bagLink)

                if containerBagType == BACKPACK_CONTAINER or containerBagType == itemFamily then
                    freeSlots = freeSlots + GetContainerNumFreeSlots(bag)
                end
            end
        end
    end

    return freeSlots
end

local function GetNextFreeSlot(self)
    if self.guildSplit then
        for slot = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
            if not IsSlotLocked(GetCurrentGuildBankTab(), slot) and not GetGuildBankItemInfo(GetCurrentGuildBankTab(), slot) then
                return slot
            end
        end
    else
        local containerBagType
        local itemFamily = GetItemFamily(self.link)
        local goodBag = true

        for bag = baseContainer, maxContainer do
            if baseContainer == BANK_CONTAINER and containerType == BANK_CONTAINER + 1 then
                bag = NUM_BAG_SLOTS + 1
            end

            if bag > baseContainer then
                local bagLink = IsBag(bag)

                if bagLink then
                    containerBagType = GetItemFamily(bagLink)

                    if containerBagType == baseContainer or containerBagType == itemFamily then
                        goodBag = true
                    else
                        goodBag = false
                    end
                end
            end

            if goodBag then
                for slot = 1, GetContainerNumSlots(bag) do
                    if not IsSlotLocked(bag, slot) and IsSlotFree(bag, slot) then
                        return bag, slot
                    end
                end
            end
        end

        return nil
    end
end

local function CalculateSplit(self)
    local freeSlots = 0

    if self.guildSplit then
        for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
            if not GetGuildBankItemInfo(GetCurrentGuildBankTab(), i) then
                freeSlots = freeSlots + 1
            end
        end
    else
        freeSlots = GetNumFreeBagSlots(self)
    end

    local numStacks = floor(self.maxStack / self.split)

    if numStacks > freeSlots then
        numStacks = freeSlots
    end

    -- print(freeSlots.." : "..self.maxStack.."_"..numStacks.."_"..self.split)
    local leftover = self.maxStack - (numStacks * self.split)

    self.freeSlots = freeSlots or 0
    self.numStacks = numStacks or 0
    self.leftover = leftover or 0
end

local function VendorWindow()
    CIS_ParentFrame.buyOnce:Show()
    CIS_ParentFrame.buyStacks:Show()

    CIS_ParentFrame.splitOnce:Hide()
    CIS_ParentFrame.splitAll:Hide()
end

local function NonVendorWindow()
    CIS_ParentFrame.splitOnce:Show()
    CIS_ParentFrame.splitAll:Show()

    CIS_ParentFrame.buyOnce:Hide()
    CIS_ParentFrame.buyStacks:Hide()
end

local function UpdateBuyStacksText(self, amount)
    if self.price then
        local freeSlots = GetNumFreeBagSlots(self)

        if amount > freeSlots then
            amount = freeSlots
        end
    end

    if amount == 1 then
        self.buyStacks.text:SetText("Buy " .. amount .. " Stack")
    else
        self.buyStacks.text:SetText("Buy " .. amount .. " Stacks")
    end
end

local function UpdateText(self, amount)
    self.text:SetText(amount)
    UpdateBuyStacksText(self, amount)
end

--------------------------
local function OpenFrame(self, maxStack, parent, anchor, anchorTo, stackCount)
    if CIS_ParentFrame.parent then
        CIS_ParentFrame.parent.hasStackSplit = 0
    end

    if not maxStack or maxStack < 1 then
        CIS_ParentFrame:Hide()
        return
    end

    CIS_ParentFrame.maxStack = maxStack
    CIS_ParentFrame.parent = parent
    CIS_ParentFrame.container = parent:GetParent():GetID()
    CIS_ParentFrame.slot = parent:GetID()
    parent.hasStackSplit = 1
    CIS_ParentFrame.minSplit = 1
    CIS_ParentFrame.split = CIS_ParentFrame.minSplit
    CIS_ParentFrame.totalSplit = CIS_ParentFrame.split
    -- If there's a price, we're in a vendor window, handle vendor behavior. If there's no price, we're not in a vendor window
    CIS_ParentFrame.price = parent.price
    UpdateText(CIS_ParentFrame, CIS_ParentFrame.minSplit)
    CIS_ParentFrame.typing = 0
    CIS_ParentFrame.guildSplit = false
    CIS_ParentFrame.fromBags = false

    CIS_ParentFrame:ClearAllPoints()
    CIS_ParentFrame:SetPoint(anchor, parent, anchorTo, 0, 0)
    CIS_ParentFrame:Show()

    if CIS_ParentFrame.price then
        VendorWindow()
    else
        NonVendorWindow()
    end
end

local function OnHide(self)
    for key in next, (self.down or {}) do
        self.down[key] = nil
    end

    if self.parent then
        self.parent.hasStackSplit = 0
    end
end

local function OnChar(self, text)
    if text < "0" or text > "9" then
        return
    end

    if (self.typing == 0) then
        self.typing = self.minSplit
        self.split = 0
    end

    local split = (self.split * 10) + (text * self.minSplit)
    if split == self.split then
        if self.split == 0 then
            self.split = self.minSplit
        end

        return
    end

    if split <= self.maxStack then
        self.split = split
        UpdateText(self, split)
    elseif split == 0 then
        self.split = 1
    end
end

local function SplitOnce(self)
    self:Hide()

    if self.parent then
        self.parent.SplitStack(self.parent, self.split)
    end
end

local function AutoSplit(self)
    if (self.leftover == 0 and self.splitStacks == self.numStacks - 1) or self.splitStacks == self.numStacks then
        -- print(self.leftover.." _ "..self.numStacks)
        CIS:UnregisterEvent("ITEM_LOCK_CHANGED")
        return
    end

    SplitContainerItem(self.container, self.slot, self.split)

    local bag, slot = GetNextFreeSlot(self)

    if bag then
        SetSlotLocked(bag, slot)
        PickupContainerItem(bag, slot)
    end

    self.splitStacks = self.splitStacks + 1
end

local function SplitAll(self)
    self:Hide()

    if self.parent then
        CIS:RegisterEvent("ITEM_LOCK_CHANGED")

        if self.container == BANK_CONTAINER or (self.container >= NUM_BAG_SLOTS + 1 and self.container <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS) then -- Bank
            baseContainer = BANK_CONTAINER
            maxContainer = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
            containerType = BANK_CONTAINER
        elseif self.container == REAGENTBANK_CONTAINER then -- Reagent Bank
            baseContainer = REAGENTBANK_CONTAINER
            maxContainer = REAGENTBANK_CONTAINER
            containerType = REAGENTBANK_CONTAINER
        elseif self.container >= BACKPACK_CONTAINER and self.container <= NUM_BAG_SLOTS then -- Bags
            baseContainer = BACKPACK_CONTAINER
            maxContainer = NUM_BAG_SLOTS
            containerType = BACKPACK_CONTAINER
        end

        CalculateSplit(self)
        self.splitStacks = 0
        ClearAllLockedSlots()
        AutoSplit(self)
    end
end

local function GuildBankAutoSplit(self)
    if self.fromBags then
        if self.splitStacks == self.numStacks then
            -- print("exit 1")
            CIS:UnregisterEvent("GUILDBANK_ITEM_LOCK_CHANGED")
            CIS:UnregisterEvent("ITEM_LOCK_CHANGED")
            return
        end
    else
        if (self.leftover == 0 and self.splitStacks == self.numStacks - 1) or self.splitStacks == self.numStacks then
            CIS:UnregisterEvent("GUILDBANK_ITEM_LOCK_CHANGED")
            return
        end
    end

    local tab = GetCurrentGuildBankTab()

    if self.fromBags then
        SplitContainerItem(self.container, self.slot, self.split)
    else
        SplitGuildBankItem(tab, self.slot, self.split)
    end

    local slot = GetNextFreeSlot(self)
    SetSlotLocked(tab, slot)
    PickupGuildBankItem(tab, slot)

    -- print(self.splitStacks)

    self.splitStacks = self.splitStacks + 1
end

local function GuildBankSplit(self)
    if self.container ~= BACKPACK_CONTAINER then
        self.fromBags = true
    elseif self.slot <= GetContainerNumSlots(BACKPACK_CONTAINER) then
        -- Since Blizzard made the GBank inventory id the same as the backpack for some reason, we gotta figure out which we're in........
        local bankTexture, bankAmount = GetGuildBankItemInfo(GetCurrentGuildBankTab(), self.slot)
        local texture = self.parent.icon:GetTexture()
        local amount = self.maxStack

        if bankTexture ~= texture and bankAmount ~= amount then
            -- Not always true, but very likely, which is good enough for us
            self.fromBags = true
        end
    end

    self:Hide()

    if self.parent then
        if self.fromBags then
            CIS:RegisterEvent("ITEM_LOCK_CHANGED")
        end

        CIS:RegisterEvent("GUILDBANK_ITEM_LOCK_CHANGED")

        self.guildSplit = true
        CalculateSplit(self)
        self.splitStacks = 0
        ClearAllLockedSlots()
        GuildBankAutoSplit(self)
    end
end

local function BuyOnce(self)
    self:Hide()

    if self.parent then
        BuyMerchantItem(self.slot, self.split)
    end
end

local function AutoBuyStacks(self, numRuns, remainder)
    self:Hide()
    local limit = MaxBuffer

    if self.parent then
        local count = 0
        CalculateSplit(self)

        -- To prevent "Internal Item Errors"
        -- Only buy "limit" stacks at a time
        if numRuns == 0 then
            if remainder < MaxBuffer then
                limit = remainder
            end
        end

        for i = 1, limit do
            BuyMerchantItem(self.slot, self.maxStack)
        end

        -- Continuation of preventing Internal Item errors:
        -- after buying "limit" stacks, wait 1 second then attempt to buy "limit" more
        if numRuns > 0 then
            C_Timer.After(1, function() AutoBuyStacks(self, numRuns - 1, remainder) end)
        end
    end
end

local function CheckItemLock(self)
    local locked
    if self.guildSplit then
        if self.fromBags then
            locked = select(3, GetContainerItemInfo(self.container, self.slot))
        else
            locked = select(3, GetGuildBankItemInfo(GetCurrentGuildBankTab(), self.slot))
        end

        if not locked then
            C_Timer.After(1, function() GuildBankAutoSplit(self) end) -- Needs timer or else causes C Stack overflow of blizzard trying to set color of locked items if ran too fast
        end
    else
        locked = select(3, GetContainerItemInfo(self.container, self.slot))

        if not locked then
            AutoSplit(self)
        end
    end
end

local function LeftClick(self)
    if self.split <= self.minSplit then
        return
    end

    self.split = IsShiftKeyDown() and self.minSplit or self.split - self.minSplit

    if self.split <= self.maxStack then
        UpdateText(self, self.split)
    else
        UpdateBuyStacksText(self, self.split)
    end
end

local function RightClick(self)
    if self.price then
        local freeSlots = GetNumFreeBagSlots(self)

        if self.split < self.maxStack then
            self.split = IsShiftKeyDown() and self.maxStack or self.split + self.minSplit
            UpdateText(self, self.split)
        else
            local freeSlots = GetNumFreeBagSlots(self)

            if self.split < freeSlots then
                self.split = self.split + self.minSplit
                UpdateBuyStacksText(self, self.split)
            end
        end
    else
        if self.split == self.maxStack then
            return
        end

        self.split = IsShiftKeyDown() and self.maxStack or self.split + self.minSplit

        UpdateText(self, self.split)
    end
end

local function OnKeyDown(self, key)
    local numKey = gsub(key, "NUMPAD", "")

    if key == "BACKSPACE" or key == "DELETE" then
        if (self.typing == 0 or self.split == self.minSplit) then
            return
        end

        self.split = floor(self.split / 10)
        if self.split <= self.minSplit then
            self.split = self.minSplit
            self.typing = 0
        end

        UpdateText(self, self.split)
    elseif key == "ENTER" then
        SplitOnce(self)
    elseif GetBindingFromClick(key) == "TOGGLEGAMEMENU" then
        self:Hide()
    elseif key == "LEFT" or key == "DOWN" then
        LeftClick(self)
    elseif key == "RIGHT" or key == "UP" then
        RightClick(self)
    end

    self.down = self.down or {}
    self.down[key] = true
end

local function OnMouseWheel(self, delta)
    if delta < 0 then
        LeftClick(self)
    else
        RightClick(self)
    end
end

local function OnKeyUp(self, key)
    if self.down then
        self.down[key] = nil
    end
end

local function OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        StackSplitFrame.OpenStackSplitFrame = OpenFrame
        -- print(OpenStackSplitFrame)

        CIS_ParentFrame:SetScript("OnHide", OnHide)
        CIS_ParentFrame:SetScript("OnChar", OnChar)
        CIS_ParentFrame:SetScript("OnKeyDown", OnKeyDown)
        CIS_ParentFrame:SetScript("OnKeyUp", OnKeyUp)
        CIS_ParentFrame:SetScript("OnMouseWheel", OnMouseWheel)

        CIS_ParentFrame.leftButton:HookScript("OnClick", function() LeftClick(CIS_ParentFrame) end)
        CIS_ParentFrame.rightButton:HookScript("OnClick", function() RightClick(CIS_ParentFrame) end)

        CIS_ParentFrame.splitOnce:HookScript("OnClick", function() SplitOnce(CIS_ParentFrame) end)
        CIS_ParentFrame.splitAll:HookScript("OnClick", function() SplitAll(CIS_ParentFrame) end)
        CIS_ParentFrame.guildBankSplit:HookScript("OnClick", function() GuildBankSplit(CIS_ParentFrame) end)
        CIS_ParentFrame.buyOnce:HookScript("OnClick", function() BuyOnce(CIS_ParentFrame) end)
        CIS_ParentFrame.buyStacks:HookScript("OnClick", function() AutoBuyStacks(CIS_ParentFrame, floor(CIS_ParentFrame.split / MaxBuffer), CIS_ParentFrame.split % MaxBuffer) end)
    elseif event == "ITEM_LOCK_CHANGED" then
        CheckItemLock(CIS_ParentFrame)
    elseif event == "GUILDBANK_ITEM_LOCK_CHANGED" then
        CheckItemLock(CIS_ParentFrame)
    elseif event == "GUILDBANKFRAME_OPENED" then
        CIS_ParentFrame.guildBankSplit:Show()
    elseif event == "GUILDBANKFRAME_CLOSED" then
        CIS_ParentFrame.guildBankSplit:Hide()
        CIS_ParentFrame:Hide()
    end
end

CIS:RegisterEvent("PLAYER_LOGIN")
CIS:RegisterEvent("GUILDBANKFRAME_OPENED")
CIS:RegisterEvent("GUILDBANKFRAME_CLOSED")
CIS:HookScript("OnEvent", OnEvent)
print(util.test())
