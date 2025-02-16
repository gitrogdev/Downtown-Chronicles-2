--Handle radio communication on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool: Tool = script.Parent

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local InitializeRadio = ReplicatedCommunication.InitializeRadio
local ToggleRadio = ReplicatedCommunication.ToggleRadio

InitializeRadio:FireServer(Tool)

Tool.Activated:Connect(function()
    ToggleRadio:FireServer(Tool)
end)