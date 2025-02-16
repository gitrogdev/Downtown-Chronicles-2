--Handles mortar placement on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool = script.Parent

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local PlaceMortar = ReplicatedCommunication.PlaceMortar

Tool.Activated:Connect(function()
	PlaceMortar:FireServer()
end)