--This script handles name input on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainGui = script.Parent
local NotifBackground = MainGui:WaitForChild("NotificationBackground")
local ReasonDisplay = NotifBackground:WaitForChild("Reason")
local AcceptButton = NotifBackground:WaitForChild("AcceptButton")
local ReapplyButton = NotifBackground:WaitForChild("ReapplyButton")

local Player = Players.LocalPlayer

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Communication = ScriptStorage.Communication
local RespondEdit = Communication.RespondEdit

AcceptButton.MouseButton1Click:Connect(function()
    RespondEdit:InvokeServer(true)
end)

ReapplyButton.MouseButton1Click:Connect(function()
    RespondEdit:InvokeServer(false)
end)

ReasonDisplay.Text = `Your name was edited by the staff team. \z
    It is now: {Player:GetAttribute("FirstName")} \z
    {Player:GetAttribute("LastName")}\n\z
    Reason: {Player:GetAttribute("Edited")}\n\z
    You can choose to accept the name change, or reapply for a new name.`
NotifBackground.Visible = true