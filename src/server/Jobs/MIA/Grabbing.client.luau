--Handles grabbing a handcuffed player on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character
local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
local RootPart: Part = Humanoid.RootPart

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Util = require(ReplicatedScripts.Util)

local grabbingId = Character:GetAttribute("Grabbing")
local Grabbing: Player = Players:GetPlayerByUserId(grabbingId)
local GrabbingChar: Model = Grabbing.Character
local GrabHumanoid: Humanoid = GrabbingChar:FindFirstChildOfClass("Humanoid")
local ReleaseGrab: RemoteEvent = GrabbingChar:WaitForChild("ReleaseGrab")
local RightArm: Part = GrabbingChar:WaitForChild("Right Arm")
local CuffAttachment: Attachment = RightArm:WaitForChild("HandcuffAttachment")

local GrabPart: Part = GrabHumanoid.RootPart

local Stepper: RBXScriptConnection

local ReleasePrompt: ProximityPrompt = Util.CreateInstance("ProximityPrompt", {
    ActionText = "Release";
    ClickablePrompt = true;
    HoldDuration = 0.5;
    KeyboardKeyCode = Enum.KeyCode.E;
    MaxActivationDistance = 4;
    Parent = CuffAttachment;
    RequiresLineOfSight = true;
})

ReleasePrompt.Triggered:Connect(function(Triggerer: Player)
    if Triggerer ~= Player then
        return warn(
            `{script}.{Grabbing}.ReleasePrompt.Triggered: Local prompt was \z
            triggered by a Player other than the LocalPlayer! (\z
            Triggered by {Triggerer}, LocalPlayer: {Player})`
        )
    end

    ReleasePrompt:Destroy()
    Stepper:Disconnect()
    ReleaseGrab:FireServer()
end)

Stepper = RunService.Stepped:Connect(function()
    GrabHumanoid.Sit = false
    if GrabHumanoid.SeatPart then
        GrabHumanoid:GetPropertyChangedSignal("SeatPart"):Wait()
    end
    GrabPart.CFrame = RootPart.CFrame:ToWorldSpace(CFrame.new(0, 0, -2))
end)

Humanoid.Died:Once(function()
    ReleasePrompt:Destroy()
    Stepper:Disconnect()
end)

Character:GetAttributeChangedSignal("Grabbing"):Once(function()
    ReleasePrompt:Destroy()
    Stepper:Disconnect()
end)