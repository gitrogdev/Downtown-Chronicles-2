--This script handles the client-side portion of seat interactions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Animator = require(ReplicatedScripts.Animator)

local seats = {}

local SeatAnimTrack

local function characterAdded(Character: Model)
    local Humanoid = Character:WaitForChild("Humanoid")
    Humanoid.Seated:Connect(function(active: boolean)
        if active and Humanoid.SeatPart:GetAttribute("PlayAnimation") then
            SeatAnimTrack = Animator.Play(
                Humanoid, Animator.new(Humanoid.SeatPart:GetAttribute(
                    "PlayAnimation"
                ))
            )
        elseif SeatAnimTrack then
            SeatAnimTrack:Stop()
        end

        for i, SeatPrompt in ipairs(seats) do
            local disableSeat = (
                active
                or (
                    SeatPrompt:FindFirstAncestorWhichIsA("Seat")
                    and SeatPrompt:FindFirstAncestorWhichIsA("Seat").Occupant
                    and true
                )
            )
            SeatPrompt.Enabled = disableSeat and 0
                or SeatPrompt:GetAttribute("Original")
            SeatPrompt:SetAttribute("Deactivated", disableSeat)
        end
    end)
end

Player.CharacterAdded:Connect(characterAdded)
if Player.Character then
    characterAdded(Player.Character)
end

local module = {}

---Sets up display behavior for a Seat
---@param Seat Seat The seat to set up the behavior for
---@param SeatPrompt ProximityPrompt The prompt to set up the behavior for
module.Setup = function(Seat: Seat, SeatPrompt: ProximityPrompt)
    table.insert(seats, SeatPrompt)
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        SeatPrompt.MaxActivationDistance =
            (Player.Character.Humanoid.SeatPart and 0)
            or SeatPrompt:GetAttribute("Original")
        SeatPrompt:SetAttribute("Deactivated",
            not not Player.Character.Humanoid.SeatPart --casting to bool...
        )
    end

    Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        SeatPrompt.MaxActivationDistance =
            (Seat.Occupant and 0)
            or SeatPrompt:GetAttribute("Original")
        SeatPrompt:SetAttribute("Deactivated", not not Seat.Occupant) --bool...
    end)
end

return module