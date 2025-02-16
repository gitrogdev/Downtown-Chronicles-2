--Handles the New Life Rule on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local UIStorage = ReplicatedStorage.UserInterface

local ReplicatedCommunication = ReplicatedScripts.Communication

local LastDeath = ReplicatedCommunication.LastDeath

local NLRWarning = UIStorage.NLRWarning

local module = {}

module.Load = function(Humanoid: Humanoid)
    local lastDeath = LastDeath:InvokeServer()
    if not lastDeath then
        return print(`{script}.Load: Last death not found!`)
    end

    local WarningGui = NLRWarning:Clone()
    local Background = WarningGui:WaitForChild("Frame")

    Background.Position = UDim2.fromScale(0, 1)

    WarningGui.Parent = Player.PlayerGui

    local checkPosition, inRange
    local function terminate()
        local TweenOut = TweenService:Create(Background, TweenInfo.new(1), {
            Position = UDim2.fromScale(0, 1)
        })

        TweenOut.Completed:Connect(function()
            WarningGui:Destroy()
        end)

        checkPosition:Disconnect()
        TweenOut:Play()
    end

    checkPosition = RunService.RenderStepped:Connect(function()
        if lastDeath.Until < os.time() then
            terminate()
        end

        local distance = (
            Humanoid.RootPart.Position - lastDeath.Position
        ).Magnitude

        local violating = distance < 150
        if violating ~= inRange then
            inRange = violating
            TweenService:Create(Background, TweenInfo.new(1), {
                Position = UDim2.fromScale(0, inRange and 0 or 1)
            }):Play()
        end
    end)

    Humanoid.Died:Once(terminate)
end

return module