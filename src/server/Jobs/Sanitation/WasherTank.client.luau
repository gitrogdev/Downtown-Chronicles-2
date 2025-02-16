--Handles use of the power washer tank on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool: Tool = script.Parent

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local InitializeTank = ReplicatedCommunication.InitializeTank

InitializeTank:FireServer(Tool)