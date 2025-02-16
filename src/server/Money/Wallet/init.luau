--This script handles wallets on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local WalletClient = script.Wallet

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local SmartStack = ReplicatedCommunication.SmartStack
local WalletDeposit = ReplicatedCommunication.WalletDeposit
local WalletWithdraw = ReplicatedCommunication.WalletWithdraw

local InventoryConfig = require(ReplicatedConfig.Inventory)

local ServerScripts = ServerScriptService.ServerScripts
local InventoryHandler
local Util = require(ServerScripts.Util)

local ServerParts = ServerStorage.Parts
local ToolStorage = ServerParts.Tools
local WalletTemplate = ToolStorage.Wallet

SmartStack.OnServerInvoke = function(Player: Player)
    local Head = Player.Character:FindFirstChild("Head")
    if not Head then
        return warn(
            `{script}.SmartStack.OnServerInvoke: \z
            No head found for player {Player}!`
        )
    end

    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.SmartStack.OnServerInvoke: \z
            No inventory found for Player {Player}!`
        )
    end

    local Wallet = Player.Character:FindFirstChildOfClass("Tool")
    if not Wallet or Wallet:GetAttribute("FileName") ~= "Wallet" then
        return warn(
            `{script}.SmartStack.OnServerInvoke: \z
            No wallet found for {Player}!`
        )
    end

    local balance, stacks = Util.InventoryBalance(Player)
    local optimal = Util.BillsRequired(balance)
    
    local destroyed = 0
    for i, Stack in ipairs(stacks) do
        for attribute, value in pairs(Inventory:GetAttributes()) do
            if value == Stack.Name then
                Inventory:SetAttribute(attribute, nil)
                destroyed += 1
                Stack:Destroy()
                break
            end
        end
    end

    local operations = 0
    repeat
        local stack = {unpack(optimal, 1, 100)}
        optimal = {unpack(optimal, 101)}

        local sum = 0
        for i, bill in ipairs(stack) do
            sum += bill
        end

        if sum > 0 then
            operations += 1
            InventoryHandler.Add(Player, InventoryHandler.Items.new(
                "Cash",
                `Change from {Player:GetAttribute("FullName")} smart-stacking.`,
                {
                    Value = sum;
                }
            ), nil, true)
        end
    until #optimal == 0

    if operations > 0 and destroyed > 1 then
        Util.RoleplayAction(Head,
            `*$\{Associated} carefully rearranges their cash.`
        )
    end

    return true
end

WalletDeposit.OnServerInvoke = function(Player: Player, amount: number)
    local Head = Player.Character:FindFirstChild("Head")
    if not Head then
        return warn(
            `{script}.WalletDeposit.OnServerInvoke: \z
            No head found for player {Player}!`
        )
    end

    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.WalletDeposit.OnServerInvoke: \z
            No inventory found for Player {Player}!`
        )
    end

    local Wallet = Player.Character:FindFirstChildOfClass("Tool")
    if not Wallet or Wallet:GetAttribute("FileName") ~= "Wallet" then
        return warn(
            `{script}.WalletDeposit.OnServerInvoke: \z
            No wallet found for {Player}!`
        )
    end

    if amount < 1 or amount ~= math.floor(amount) then
        return warn(
            `{script}.WalletDeposit.OnServerInvoke: \z
            Amount must be a positive integer! (Got {amount} from {Player})`
        )
    end

    local balance, stacks = Util.InventoryBalance(Player)
    if amount > balance then
        return warn(
            `{script}.WalletDeposit.OnServerInvoke: \z
            {Player} does not have enough money in their inventory to deposit \z
            ₲{amount}! (Balance: ₲{balance})`
        )
    end

    local currentBalance = Wallet:GetAttribute("Balance") or 0
    local bills = Util.BillsRequired(currentBalance + amount)
    if #bills > Wallet:GetAttribute("Capacity") then
        return warn(
            `{script}.WalletDeposit.OnServerInvoke: Amount ₲{amount} \z
            exceeds maximum wallet capacity! (Required: {#bills})`
        )
    end

    Util.RoleplayAction(Head,
        `*$\{Associated} has put ₲{Util.ThousandsSeparate(amount)} into their \z
        wallet.`
    )

    Wallet:SetAttribute("Balance", currentBalance + amount)
    for i, Stack in ipairs(stacks) do
        if Stack:GetAttribute("Value") <= amount then
            amount -= Stack:GetAttribute("Value")
            for attribute, value in pairs(Inventory:GetAttributes()) do
                if value == Stack.Name then
                    Inventory:SetAttribute(attribute, nil)
                    break
                end
            end
            Stack:Destroy()

            if amount == 0 then
                break
            end
        else
            for attribute, value in pairs(Inventory:GetAttributes()) do
                if value == Stack.Name then
                    Inventory:SetAttribute(attribute, nil)

                    InventoryHandler.Add(Player,
                    InventoryHandler.Items.new(
                        "Cash",
                        `Change from wallet deposit for \z
                        {Player:GetAttribute("FullName")}`,
                        {
                            Value = Stack:GetAttribute("Value") - amount;
                        }
                    ), InventoryConfig.SlotNumbers[attribute])
                        
                    Stack:Destroy()
                    break
                end
            end
            
            break
        end
    end
    
    return true
end

WalletWithdraw.OnServerInvoke = function(Player: Player, amount: number)
    local Head = Player.Character:FindFirstChild("Head")
    if not Head then
        return warn(
            `{script}.WalletWithdraw.OnServerInvoke: \z
            No head found for player {Player}!`
        )
    end

    local Wallet = Player.Character:FindFirstChildOfClass("Tool")
    if not Wallet or Wallet:GetAttribute("FileName") ~= "Wallet" then
        return warn(
            `{script}.WalletWithdraw.OnServerInvoke: \z
            No wallet found for {Player}!`
        )
    end

    if amount < 1 or amount ~= math.floor(amount) then
        return warn(
            `{script}.WalletWithdraw.OnServerInvoke: \z
            Amount must be a positive integer! (Got {amount} from {Player})`
        )
    end

    local bills = Util.BillsRequired(amount)
    if #bills > 100 then
        return warn(
            `{script}.WalletWithdraw.OnServerInvoke: \z
            Amount ₲{amount} exceeds maximum stack size! (Required: {#bills})`
        )
    end

    local balance = Wallet:GetAttribute("Balance") or 0
    if amount > balance then
        return warn(
            `{script}.WalletWithdraw.OnServerInvoke: \z
            {Player} does not have enough money in their wallet to withdraw \z
            ₲{amount}! (Balance: ₲{balance})`
        )
    end

    Wallet:SetAttribute("Balance", balance - amount)
    InventoryHandler.Add(Player, InventoryHandler.Items.new(
        "Cash",
        `{Player:GetAttribute("FullName")}'s wallet`,
        {
            Value = amount;
        }
    ), nil, true)

    Util.RoleplayAction(Head,
        `*$\{Associated} has taken ₲{Util.ThousandsSeparate(amount)} out of \z
        their wallet.`
    )
    
    return true
end

local module = {}

---Creates a local reference to the InventoryHandler module
---@param InvHandler table The InventoryHandler module
module.IHPass = function(InvHandler: table)
    InventoryHandler = InvHandler
end

---Creates a new wallet
---@param attributes table The attributes to create the wallet with
---@return Tool
module.new = function(attributes: table)
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)
    Tool:SetAttribute("AssociatedGui", "WalletGui")
    Tool:SetAttribute("Capacity", 50)

    for i, Child in ipairs(WalletTemplate:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    WalletClient:Clone().Parent = Tool

    local function updateWeight()
        local bills = Util.BillsRequired(Tool:GetAttribute("Balance") or 0)
        Tool:SetAttribute("Weight", 0.06 + (0.001 * #bills));
    end
    Tool:GetAttributeChangedSignal("Balance"):Connect(updateWeight)
    updateWeight()

    return Tool
end

return module