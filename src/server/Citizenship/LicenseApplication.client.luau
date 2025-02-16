--Handles a firearms license application on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplictedCommunication = ReplicatedScripts.Communication
local SubmitApplication = ReplictedCommunication.SubmitApplication

local MainGui = script.Parent
local Background = MainGui:WaitForChild("Frame")
local InputBox = Background:WaitForChild("Input")
local SubmitButton = Background:WaitForChild("Submit")

local debounce

InputBox:GetPropertyChangedSignal("Text"):Connect(function()
    if #InputBox.Text >= 1024 then
        InputBox.Text = InputBox.Text:sub(1, 1023)
    end
end)

SubmitButton.MouseButton1Click:Connect(function()
    if debounce then
        return
    end

    if #InputBox.Text < 1 then
        return warn(`{script}.SubmitButton.MouseButton1Click: No content!`)
    end

    debounce = true
    SubmitApplication:FireServer(MainGui:GetAttribute("Type"), InputBox.Text)
end)