--Handles being grabbed while handcuffed on the client
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character
local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
local RootPart: Part = Humanoid.RootPart

local Grabber: Player
for i, Check: Player in ipairs(Players:GetPlayers()) do
    if Check == Player then
        continue
    end

    if not Check.Character then
        continue
    end

    if Check.Character:GetAttribute("Grabbing") == Player.UserId then
        Grabber = Check
        break
    end
end
if not Grabber then
    error(`{script}: No grabber found!`)
end

local GrabberChar: Model = Grabber.Character
local GrabberHumanoid: Humanoid = GrabberChar:FindFirstChildOfClass("Humanoid")
local GrabberPart: Part = GrabberHumanoid.RootPart

local Stepper: RBXScriptConnection

Stepper = RunService.Stepped:Connect(function()
    Humanoid.Sit = false
    if Humanoid.SeatPart then
        Humanoid:GetPropertyChangedSignal("SeatPart"):Wait()
    end
    RootPart.CFrame = GrabberPart.CFrame:ToWorldSpace(CFrame.new(0, 0, -2))
end)

GrabberHumanoid.Died:Once(function()
    Stepper:Disconnect()
end)

GrabberChar:GetAttributeChangedSignal("Grabbing"):Once(function()
    Stepper:Disconnect()
end)