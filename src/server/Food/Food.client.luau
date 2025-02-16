--Handles the consumption of a food item on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Tool = script.Parent

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Animator = require(ReplicatedScripts.Animator)
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local ConsumeFood = ReplicatedCommunication.ConsumeFood

local FoodConfig = require(ReplicatedConfig.Food)

local config = FoodConfig[Tool:GetAttribute("FileName")]
if not config then
    error(
        `{script}: No config found for food item \z
        {Tool:GetAttribute("FileName")}!`
    )
end

local ConsumeAnimation = Animator.new(config.Animation)
local debounce

Tool.Activated:Connect(function()
    if debounce then
        return
    end

    if Player:GetAttribute("Consuming") then
        return warn(`{script}.Activated: Already consuming a food item!`)
    end

    local uses = Tool:GetAttribute("Uses") or 0
    if uses < 1 then
        StarterGui:SetCore("SendNotification", {
            Title = "Unable to consume!";
            Text = config.OnEmpty.Warning;
            Duration = 10;
        })
        return warn(`{script}.Activated: Food item has already been consumed!`)
    end

    Animator.Play(Humanoid, ConsumeAnimation)

    debounce = true
    ConsumeFood:InvokeServer(Tool)
    debounce = false
end)