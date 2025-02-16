--All special behavior used in NPC interactions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Util = require(ReplicatedScripts.Util)

local module = {}

---Clamp the amount that the local player is withdrawing from the bank
---@param amount number The amount of money being withdrawn from the bank
---@return number
module.ClampWithdraw = function(amount: number)
    if not RunService:IsClient() then
        warn(
            `{script}.ClampWithdraw: This function is intended for \z
            client-side usage.`
        )
        return amount
    end
    local Player = Players.LocalPlayer

    local balance = Player:GetAttribute("BankBalance") or 0
    if amount > balance then
        amount = balance
    end

    local bills = Util.BillsRequired(amount)
    local slotsRequired = math.ceil(#bills / 50)
    if slotsRequired > Util.FreeSlots(Player, {Pocket = true}) then
        StarterGui:SetCore("SendNotification", {
            Title = "Amount warning!";
            Text = "The amount you are trying to withdraw requires more space \z
                than is available in your inventory.";
            Duration = 10;
        })
    end
    return amount
end

return module