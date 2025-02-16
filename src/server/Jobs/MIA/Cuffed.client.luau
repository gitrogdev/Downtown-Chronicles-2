--Handle being handcuffed on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character
local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Animator = require(ReplicatedScripts.Animator)

local CuffedTrack: AnimationTrack
local CuffedAnimation: Animation = Animator.new("Cuffed")

CuffedTrack = Animator.Play(Humanoid, CuffedAnimation)
Humanoid:SetAttribute("LockArms", (Humanoid:GetAttribute("LockArms") or 0) + 1)
Humanoid:SetAttribute("PreventDraw",
    (Humanoid:GetAttribute("PreventDraw") or 0) + 1
)

Character:GetAttributeChangedSignal("Cuffed"):Once(function()
    CuffedTrack:Stop()
    Humanoid:SetAttribute("LockArms",
        (Humanoid:GetAttribute("LockArms") or 1) - 1
    )
    Humanoid:SetAttribute("PreventDraw",
        (Humanoid:GetAttribute("PreventDraw") or 1) - 1
    )
end)