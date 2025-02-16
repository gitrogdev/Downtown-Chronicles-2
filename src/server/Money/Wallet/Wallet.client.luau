--This script handles wallets on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tool = script.Parent

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration
local Util = require(ReplicatedScripts.Util)

local SmartStack = ReplicatedCommunication.SmartStack
local WalletDeposit = ReplicatedCommunication.WalletDeposit
local WalletWithdraw = ReplicatedCommunication.WalletWithdraw

local MoneyConfig = require(ReplicatedConfig.Money)

local UserInterface = ReplicatedStorage.UserInterface
local WalletGui = UserInterface.WalletGui:Clone()
local Background = WalletGui:WaitForChild("Background")
local BackPouchLeft = Background:WaitForChild("BackPouchLeft")
local Body = Background:WaitForChild("Body")
local CashButton = Background:WaitForChild("CashButton")
local CashHover = Background:WaitForChild("CashHover")
local Pouch1 = Background:WaitForChild("Pouch1")
local Pouch2 = Background:WaitForChild("Pouch2")
local Pouch4 = Background:WaitForChild("Pouch4")
local Pouch5 = Background:WaitForChild("Pouch5")

local AmountBox = CashButton:WaitForChild("AmountBox")
local BalanceDisplay = CashButton:WaitForChild("Balance")
local ConfirmButton = CashButton:WaitForChild("ConfirmButton")
local DepositButton = CashButton:WaitForChild("DepositButton")
local StackButton = CashButton:WaitForChild("StackButton")
local WithdrawButton = CashButton:WaitForChild("WithdrawButton")

local DebitDisplay = Pouch4:WaitForChild("DebitCard")

local NorthHDPDisplay = Pouch1:WaitForChild("NorthHDP")
local NorthLTCDisplay = Pouch2:WaitForChild("NorthLTC")
local NorthMGPDisplay = BackPouchLeft:WaitForChild("NorthMGP")

local NorthIDDisplay = Pouch5:WaitForChild("NorthID")

local mode, open, debounce
local Pouches = {}

local function updateBalance()
    local balance = Tool:GetAttribute("Balance") or 0

    local bills = (balance == 0 and {1}) or Util.BillsRequired(balance)
    CashButton.Image = `rbxassetid://{MoneyConfig.Bills[bills[1]].Front}`

    BalanceDisplay.Text = `₲{Util.ThousandsSeparate(balance)}`
end

Util.InputPosInt(AmountBox, "Text", true, function(number: number)
    --To prevent the player from withdrawing more than available
    local balance = (mode == "W" and (Tool:GetAttribute("Balance") or 0))
        or (mode == "D" and Util.InventoryBalance(Player))
    
    if balance and number > balance then
        number = balance
    end
    return number
end)

CashButton.MouseButton1Click:Connect(function()
    if open then
        return
    end
    open = true

    for i, Child in ipairs(Pouches) do
        TweenService:Create(Child, TweenInfo.new(0.5), {
            Position = Child:GetAttribute("OriginalPosition")
                + UDim2.fromScale(0, 3);
        }):Play()
    end
    TweenService:Create(CashButton, TweenInfo.new(0.5), {
        Position = UDim2.fromScale(0.108, -0.1);
    }):Play()

    task.wait(0.5)

    AmountBox.Visible = false
    ConfirmButton.Visible = false
    BalanceDisplay.Visible = true
    DepositButton.Visible = true
    StackButton.Visible = true
    WithdrawButton.Visible = true
end)

CashHover.MouseEnter:Connect(function()
    if open then
        return
    end

    TweenService:Create(CashButton, TweenInfo.new(0.5), {
        Position = UDim2.fromScale(0.108, -0.2);
    }):Play()
end)

CashHover.MouseLeave:Connect(function()
    if open then
        return
    end

    TweenService:Create(CashButton, TweenInfo.new(0.5), {
        Position = UDim2.fromScale(0.108, -0.1);
    }):Play()
end)

ConfirmButton.MouseButton1Click:Connect(function()
    if debounce then
        return
    end

    if mode == "W" or mode == "D" then
        local invokeWith = AmountBox.Text:gsub(",", "")
        invokeWith = tonumber(invokeWith)

        if not invokeWith then
            AmountBox.Visible = false
            ConfirmButton.Visible = false
            BalanceDisplay.Visible = true
            DepositButton.Visible = true
            StackButton.Visible = true
            WithdrawButton.Visible = true
            return
        end

        debounce = true

        local success = (
                ((mode == "W") and WalletWithdraw)
                or ((mode == "D") and WalletDeposit)
            ):InvokeServer(invokeWith)
        if success then
            AmountBox.Visible = false
            ConfirmButton.Visible = false
            BalanceDisplay.Visible = true
            DepositButton.Visible = true
            StackButton.Visible = true
            WithdrawButton.Visible = true
        end
        debounce = false
    end
end)

DepositButton.MouseButton1Click:Connect(function()
    AmountBox.Visible = true
    ConfirmButton.Visible = true
    DepositButton.Visible = false
    StackButton.Visible = false
    WithdrawButton.Visible = false

    mode = "D"
end)

StackButton.MouseButton1Click:Connect(function()
    if debounce then
        return
    end

    debounce = true
    SmartStack:InvokeServer()
    debounce = false
end)

Tool.Equipped:Connect(function()
    DebitDisplay.Visible = Player:GetAttribute("PBNBAccount")
    if
        not NorthHDPDisplay.Visible and Player:GetAttribute("NorthHDP")
    then
        Util.SetupID(Player, NorthHDPDisplay)
        NorthHDPDisplay.Visible = true
    end

    if
        not NorthLTCDisplay.Visible and Player:GetAttribute("NorthLTC")
    then
        Util.SetupID(Player, NorthLTCDisplay)
        NorthLTCDisplay.Visible = true
    end

    if
        not NorthMGPDisplay.Visible and Player:GetAttribute("NorthMGP")
    then
        Util.SetupID(Player, NorthMGPDisplay)
        NorthMGPDisplay.Visible = true
    end

    if
        not NorthIDDisplay.Visible
        and Player:GetAttribute("Citizenship") == "North"
    then
        Util.SetupID(Player, NorthIDDisplay)
        NorthIDDisplay.Visible = true
    end
    WalletGui.Parent = Player.PlayerGui
end)

Tool.Unequipped:Connect(function()
    WalletGui.Parent = nil

    if open then
        for i, Child in ipairs(Pouches) do
            Child.Position = Child:GetAttribute("OriginalPosition")
        end

        AmountBox.Visible = false
        ConfirmButton.Visible = false
        BalanceDisplay.Visible = false
        DepositButton.Visible = false
        StackButton.Visible = false
        WithdrawButton.Visible = false

        mode = nil
        open = false
    end
end)

Tool:GetAttributeChangedSignal("Balance"):Connect(updateBalance)

WithdrawButton.MouseButton1Click:Connect(function()
    AmountBox.Visible = true
    ConfirmButton.Visible = true
    DepositButton.Visible = false
    StackButton.Visible = false
    WithdrawButton.Visible = false

    mode = "W"
end)

for i, Child in ipairs(Background:GetChildren()) do
    if Child.Name:find("Pouch")  then
        table.insert(Pouches, Child)
        Child:SetAttribute("OriginalPosition", Child.Position)
    end
end
table.insert(Pouches, Body)
Body:SetAttribute("OriginalPosition", Body.Position)
updateBalance()