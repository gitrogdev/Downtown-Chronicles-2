--Handles interaction with a feed part on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local InitializeFeed = ReplicatedCommunication.InitializeFeed

local Tool = script.Parent

InitializeFeed:FireServer(Tool)

Tool.Activated:Connect(function()
    local capacity = Tool:GetAttribute("Capacity")
    local maxCapacity = Tool:GetAttribute("MaxCapacity")
    local name = Tool:GetAttribute("DisplayName")

    StarterGui:SetCore("SendNotification", {
        Title = (capacity == maxCapacity and `{name} full!`)
            or (capacity == 0 and `{name} empty!`)
            or `{name} partially full!`;
        Text = `There are {capacity} round{capacity == 1 and "" or "s"} \z
            remaining in the {name}.`;
        Duration = 10;
    })
end)