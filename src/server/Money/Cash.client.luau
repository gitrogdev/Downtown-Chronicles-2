--Handles a stack of cash on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool = script.Parent

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local StackWallet = ReplicatedCommunication.StackWallet

local debounce

Tool.Activated:Connect(function()
    if debounce then
        return
    end
    debounce = true
    debounce = StackWallet:InvokeServer(Tool)
end)