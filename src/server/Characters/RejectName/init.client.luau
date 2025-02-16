--This script handles name input on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainGui = script.Parent
local NameBackground = MainGui:WaitForChild("NameBackground")
local FirstInput = NameBackground:WaitForChild("FirstName")
local LastInput = NameBackground:WaitForChild("LastName")
local ReasonDisplay = NameBackground:WaitForChild("Reason")
local SubmitButton = NameBackground:WaitForChild("SubmitButton")

local Player = Players.LocalPlayer

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Communication = ScriptStorage.Communication
local ReplaceName = Communication.ReplaceName

SubmitButton.MouseButton1Click:Connect(function()
    ReplaceName:InvokeServer(FirstInput.Text, LastInput.Text)
end)

ReasonDisplay.Text = `Your name was rejected by the staff team.\n\z
    Reason: \z
    {(Player:GetAttribute("Rejected") or Player:GetAttribute("Edited"))}\n\z
    Choose a new name for your character. \z
    Remember, you are creating a fictional character, \z
    do not enter your real world information.\n\z
    Please, do not enter offensive names, the names of celebrities, \z
    fictional characters, in-game NPCs, or other player characters, \z
    and please enter a proper name. \z
    Further abuse of the system may result in administrative action.`
NameBackground.Visible = true