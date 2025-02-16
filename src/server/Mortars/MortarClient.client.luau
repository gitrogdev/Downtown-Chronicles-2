--Handles mortar usage on the client
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local MortarSeat = Humanoid.SeatPart
local Mortar = MortarSeat.Parent
local AdjustMortar = Mortar:WaitForChild("AdjustMortar")
local FireMortar = Mortar:WaitForChild("FireMortar")

local adjusting = {}
UserInputService.InputBegan:Connect(function(
    Input: InputObject, gameProcessed: boolean
)
	if gameProcessed then
		return
	end
	
	if
        Input.KeyCode == Enum.KeyCode.W
        or Input.KeyCode == Enum.KeyCode.S
        or Input.KeyCode == Enum.KeyCode.Q
        or Input.KeyCode == Enum.KeyCode.E
    then
		AdjustMortar:FireServer(tostring(Input.KeyCode), true)
		adjusting[Input.KeyCode] = true
	elseif Input.KeyCode == Enum.KeyCode.F then
		FireMortar:FireServer()
	end
end)

UserInputService.InputEnded:Connect(function(Input: InputObject)
	if adjusting[Input.KeyCode] then
		AdjustMortar:FireServer(tostring(Input.KeyCode), false)
		adjusting[Input.KeyCode] = false
	end
end)