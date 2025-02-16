--This script handles all aspects of the game's "environment" such as weather on the client
local Players = game:GetService("Players")

local RainHandler = require(script.Rain)
local ThunderHandler = require(script.Thunder)

local Player = Players.LocalPlayer

local function characterAdded(Character: Model)
    RainHandler.Listen()
    ThunderHandler.Listen(Player, Character)
end

Player.CharacterAdded:Connect(characterAdded)
if Player.Character then
    characterAdded(Player.Character)
end