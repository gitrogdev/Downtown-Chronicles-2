--This script handles interactions with money on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CashClient = script.Cash
local WalletHandler = require(script.Wallet)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local BankDeposit = ReplicatedCommunication.BankDeposit
local BankWithdraw = ReplicatedCommunication.BankWithdraw
local MakeAccount = ReplicatedCommunication.MakeAccount
local StackWallet = ReplicatedCommunication.StackWallet

local InventoryConfig = require(ReplicatedConfig.Inventory)
local MoneyConfig = require(ReplicatedConfig.Money)

local ServerScripts = ServerScriptService.ServerScripts
local InventoryHandler
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

---Withdraws money from the bank and gives it to a Player
---@param Player Player The Player withdrawing the money
---@param amount string The amount of money requested
---@return any
BankWithdraw.OnServerInvoke = function(Player: Player, amount: string)
    if Player:GetAttribute("BankFrozen") then
        return "Frozen", warn(
            `{script}.BankWithdraw.OnServerInvoke: {Player}'s bank account is \z
            frozen!`
        )
    end

    if not tonumber(amount) then
        return "Amount", warn(
            `{script}.BankWithdraw.OnServerInvoke: \z
            Amount must be a positive integer! (Got {amount} from {Player})`
        )
    end
    amount = tonumber(amount)

    if math.floor(math.abs(amount)) ~= amount then
        return "Amount", warn(
            `{script}.BankWithdraw.OnServerInvoke: \z
            Amount must be a positive integer! (Got {amount} from {Player})`
        )
    end

    if amount == 0 then
        return "Amount", warn(
            `{script}.BankWithdraw.OnServerInvoke: \z
            Amount must be a positive integer! (Got {amount} from {Player})`
        )
    end

    if amount > (Player:GetAttribute("BankBalance") or 0) then
        return "Insufficent", warn(
            `{script}.BankWithdraw.OnServerInvoke: \z
            {Player} has insufficent funds to withdraw {amount} \z
            ({Player:GetAttribute("BankBalance") or 0})!`
        )
    end

    Player:SetAttribute(
        "BankBalance",
        Player:GetAttribute("BankBalance") - amount
    )

    local optimal = Util.BillsRequired(amount)
    repeat
        local stack = {unpack(optimal, 1, 100)}
        optimal = {unpack(optimal, 101)}

        local sum = 0
        for i, bill in ipairs(stack) do
            sum += bill
        end

        if sum > 0 then
            InventoryHandler.Add(Player, InventoryHandler.Items.new(
                "Cash",
                `Bankteller (account of {Player:GetAttribute("FullName")})`,
                {
                    Value = sum;
                }
            ), nil, true)
        end
    until #optimal == 0

    WebhookHandler.Post(
        `{Player:GetAttribute("FullName")} ({Player}) has withdrawn \z
        ₲{Util.ThousandsSeparate(amount)} from their bank account. \z
        Current balance in bank: \z
        ₲{Util.ThousandsSeparate(Player:GetAttribute("BankBalance"))}`,
        "BankLog"
    )

    return true
end

---Creates a bank new bank account for a Player
---@param Player Player The Player creating the bank account
---@param bank string The bank to create the account with
---@return boolean
MakeAccount.OnServerInvoke = function(Player: Player, bank: string)
    if bank ~= "PBNB" then
        return warn(
            `{script}.MakeAccount.OnServerInvoke: \z
            {Player} attempted to create an account with the unknown bank \z
            {bank}!`
        )
    end

    if Player:GetAttribute(bank .. "Account") then
        return warn(
            `{script}.MakeAccount.OnServerInvoke: \z
            {Player} already has an account with {bank}`
        )
    end

    Player:SetAttribute(bank .. "Account", true)
    return true
end

---Puts an equipped stack of cash into the Player's wallet
---@param Player Player The Player holding the stack of cash
---@param Stack Tool The stack of cash to put away
---@return boolean
StackWallet.OnServerInvoke = function(Player: Player, Stack: Tool)
    local Head = Player.Character:FindFirstChild("Head")
    if not Head then
        return warn(
            `{script}.StackWallet.OnServerInvoke: \z
            No head found for player {Player}!`
        )
    end

    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.StackWallet.OnServerInvoke: \z
            No inventory found for Player {Player}!`
        )
    end

    local Wallet
    for i, Child in ipairs(Inventory:GetChildren()) do
        if Child:GetAttribute("FileName") == "Wallet" then
            Wallet = Child
            break
        end
    end
    if not Wallet then
        return warn(
            `{script}.StackWallet.OnServerInvoke: \z
            No wallet found for {Player}!`
        )
    end

    if not Stack:IsA("Tool")
        or Stack.Parent ~= Player.Character
        or Stack:GetAttribute("FileName") ~= "Cash"
    then
        return warn(
            `{script}.StackWallet.OnServerInvoke: \z
            {Stack} is not a valid stack of cash! ({
                (not Stack:IsA("Tool") and "Not a Tool")
                or (Stack.Parent ~= Player.Character and "Not equipped")
                or (Stack:GetAttribute("FileName") ~= "Cash" and "Not cash")
            })`
        )
    end

    local amount = Stack:GetAttribute("Value")
    local currentBalance = Wallet:GetAttribute("Balance") or 0
    local maxCapacity = Wallet:GetAttribute("Capacity") * 10000
    local bills = Util.BillsRequired(currentBalance + amount)
    if #bills > Wallet:GetAttribute("Capacity") then
        local useAmount = amount
        while currentBalance + useAmount > maxCapacity + 10000 do
            useAmount -= 10000
        end

        for i = useAmount - 1, 1, -1 do
            bills = Util.BillsRequired(currentBalance + i)
            if #bills <= Wallet:GetAttribute("Capacity") then
                amount = i
                break
            end
        end

        if amount == Stack:GetAttribute("Value") then
            return warn(
                `{script}.StackWallet.OnServerInvoke: \z
                {Player}'s wallet is currently full!`
            )
        end
    end

    Util.RoleplayAction(Head,
        `*$\{Associated} has put ₲{Util.ThousandsSeparate(amount)} into their \z
        wallet.`
    )

    Wallet:SetAttribute("Balance", currentBalance + amount)
    if Stack:GetAttribute("Value") <= amount then
        for attribute, value in pairs(Inventory:GetAttributes()) do
            if value == Stack.Name then
                Inventory:SetAttribute(attribute, nil)
                break
            end
        end
        Stack:Destroy()
    else
        for attribute, value in pairs(Inventory:GetAttributes()) do
            if value == Stack.Name then
                Inventory:SetAttribute(attribute, nil)

                InventoryHandler.Add(Player,
                InventoryHandler.Items.new(
                    "Cash",
                    `Change from stacking into \z
                    {Player:GetAttribute("FullName")}'s wallet`,
                    {
                        Value = Stack:GetAttribute("Value") - amount;
                    }
                ), InventoryConfig.SlotNumbers[attribute])
                
                Stack:Destroy()
                break
            end
        end
    end
    
    return true
end

local module = {}

---Deposits money from a Player's inventory into the bank
---@param Player Player The Player depositing the money
---@param amount string The amount of money requested
---@return any
BankDeposit.OnServerInvoke = function(Player: Player, amount: string)
    if Player:GetAttribute("BankFrozen") then
        return "Frozen", warn(
            `{script}.BankDeposit.OnServerInvoke: {Player}'s bank account is \z
            frozen!`
        )
    end

    if not tonumber(amount) then
        return "Amount", warn(
            `{script}.BankDeposit.OnServerInvoke: \z
            Amount must be a positive integer! (Got {amount} from {Player})`
        )
    end
    amount = tonumber(amount)

    if math.floor(math.abs(amount)) ~= amount then
        return "Amount", warn(
            `{script}.BankDeposit.OnServerInvoke: \z
            Amount must be a positive integer! (Got {amount} from {Player})`
        )
    end

    if amount == 0 then
        return "Amount", warn(
            `{script}.BankDeposit.OnServerInvoke: \z
            Amount must be a positive integer! (Got {amount} from {Player})`
        )
    end

    local result = module.Charge(Player, amount, "Cash")
    if result then
        Player:SetAttribute(
            "BankBalance",
            (Player:GetAttribute("BankBalance") or 0) + amount
        )
        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player}) has deposited \z
            ₲{Util.ThousandsSeparate(amount)} into their bank account. \z
            Current balance in bank: \z
            ₲{Util.ThousandsSeparate(Player:GetAttribute("BankBalance"))}`,
            "BankLog"
        )

        return true
    elseif result == false then
        return "Insufficient", warn(
            `{script}.BankDeposit.OnServerInvoke: \z
            {Player} has insufficent funds to deposit {amount}!`
        )
    else return
    end
end

---Charge a player a given amount
---@param Player Player The Player to charge
---@param amount number The amount to charge the player
---@param method string The method by which to charge the player (Cash or Card)
---@return boolean
module.Charge = function(Player: Player, amount: number, method: string)
    if not (method == "Cash" or method == "Card") then
        return warn(`{script}.Charge: Invalid payment method {method}!`)
    end

    if method == "Cash" then
        local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
        if not Inventory then
            return warn(
                `{script}.Charge: No inventory found for Player {Player}!`
            )
        end

        local balance, stacks = Util.InventoryBalance(Player, true, true)

        if amount > balance then
            return false
        end

        for i, Stack in ipairs(stacks) do
            if Stack:GetAttribute("FileName") == "Cash" then
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
                                    `Change from cash payment for \z
                                    {Player:GetAttribute("FullName")}`,
                                    {
                                        Value =
                                            Stack:GetAttribute("Value") - amount
                                    }
                                ),
                                InventoryConfig.SlotNumbers[attribute]
                            )
    
                            Stack:Destroy()
                            break
                        end
                    end
    
                    break
                end
            elseif Stack:GetAttribute("FileName") == "Wallet" then
                local walletBalance = Stack:GetAttribute("Balance") or 0
                if walletBalance < amount then
                    amount -= walletBalance
                    Stack:SetAttribute("Balance", 0)
                else
                    Stack:SetAttribute(
                        "Balance",
                        walletBalance - amount
                    )
                    break
                end
            end
        end
        return true
    elseif method == "Card" then
        if Player:GetAttribute("BankFrozen") then
            return warn(`{script}.Charge: {Player}'s bank account is frozen!`)
        end

        local balance = Player:GetAttribute("BankBalance") or 0
        if balance >= amount then
            Player:SetAttribute("BankBalance", balance - amount)
            return true
        else
            return false
        end
    end
end

---Creates the physical object for a stack of cash
---@param value number The value of the stack of cache
---@return Tool
module.NewStack = function(value: number)
    local bills = Util.BillsRequired(value)

    if #bills > 100 or #bills < 1 then
        warn(
            `{script}.NewStack: Size out of range! \z
            (Expected 1-100, got {#bills})`
        )
        if #bills < 1 then
            return
        end
    end

    local Tool = Util.CreateInstance("Tool", {}, {
        DisplayName = `₲{Util.ThousandsSeparate(value)}`;
        Value = value;
        Weight = 0.001 * #bills;
    })

    local Handle = Util.CreateInstance("Part", {
        Color = Color3.fromRGB(196, 205, 255);
        Material = Enum.Material.SmoothPlastic;
        Name = "Handle";
        Parent = Tool;
        Size = Vector3.new(1, #bills * 0.005, 0.488);
    })

    Util.CreateInstance("Decal", {
        Face = Enum.NormalId.Top;
        Name = "FrontBill";
        Parent = Handle;
        Texture = `rbxassetid://{MoneyConfig.Bills[bills[1]].Front}`;
    })

    Util.CreateInstance("Decal", {
        Face = Enum.NormalId.Bottom;
        Name = "BackBill";
        Parent = Handle;
        Texture = `rbxassetid://{MoneyConfig.Bills[bills[#bills]].Back}`;
    })

    for side, texture in pairs(MoneyConfig.BillSides) do
        Util.CreateInstance("Decal", {
            Face = Enum.NormalId[side];
            Name = `{side}Side`;
            Parent = Handle;
            Texture = `rbxassetid://{texture}`;
        })
    end

    CashClient:Clone().Parent = Tool

    return Tool
end

---Creates a local reference to the InventoryHandler module
---@param InvHandler table The InventoryHandler module
module.IHPass = function(InvHandler: table)
    InventoryHandler = InvHandler
end

module.WalletHandler = WalletHandler

return module