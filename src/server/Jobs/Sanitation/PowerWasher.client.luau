--Handles use of the power washer on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool: Tool = script.Parent

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local InitializeWasher = ReplicatedCommunication.InitializeWasher
local ToggleWasher = ReplicatedCommunication.ToggleWasher

InitializeWasher:FireServer(Tool)

Tool.Activated:Connect(function()
    ToggleWasher:FireServer(true)
end)

Tool.Deactivated:Connect(function()
    ToggleWasher:FireServer(false)
end)

Tool:GetAttributeChangedSignal("Spraying"):Connect(function()
    local spraying = Tool:GetAttribute("Spraying")
    if spraying then
        while Tool:GetAttribute("Spraying") do
            task.wait(0.1)
        end
    end
end)