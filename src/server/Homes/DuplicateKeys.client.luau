--Prompts the client on who to give a duplicated key
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MainGui: ScreenGui = script.Parent
local Background: Frame = MainGui:WaitForChild("Frame")
local CancelButton: TextButton = Background:WaitForChild("Cancel")
local RecipientHolder: ScrollingFrame = Background:WaitForChild("Recipients")

local NoPlayers: TextLabel = RecipientHolder:WaitForChild("NoPlayers")
local UserTemplate: Frame = RecipientHolder:WaitForChild("UserTemplate")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local GiveKey = ReplicatedCommunication.GiveKey

local Player = Players.LocalPlayer
local Character = Player.Character
local RootPart: Part = Character:WaitForChild("HumanoidRootPart")

CancelButton.MouseButton1Click:Once(function()
    GiveKey:FireServer()
end)

local associated: table = HttpService:JSONDecode(Player:GetAttribute(
    "NameAssociations"
))

local OfferDisplays = {}
for i, CheckPlayer in ipairs(Players:GetPlayers()) do
    if CheckPlayer == Player then
        continue
    end

    if not CheckPlayer:GetAttribute("ID") then
        continue
    end

    local displayName: string = (
        (not CheckPlayer:GetAttribute("Masked"))
        and associated[tostring(CheckPlayer:GetAttribute("ID"))]
    ) or `Stranger ({CheckPlayer.UserId}-{CheckPlayer:GetAttribute("ID")})`
    if displayName then
        local OfferDisplay = UserTemplate:Clone()
        local GiveButton: TextButton =  OfferDisplay:WaitForChild("Give")
        local NameDisplay: TextLabel = OfferDisplay:WaitForChild("NameDisplay")

        GiveButton.MouseButton1Click:Connect(function()
            GiveKey:FireServer(CheckPlayer, MainGui:GetAttribute("Type"))
        end)
        NameDisplay.Text = displayName

        table.insert(OfferDisplays, {
            GUI = OfferDisplay;
            Player = CheckPlayer;
        })
        OfferDisplay.Parent = RecipientHolder
    end
end

RunService.RenderStepped:Connect(function()
    local visible = 0
    for i, offer in ipairs(OfferDisplays) do
        local distance = offer.Player:DistanceFromCharacter(RootPart.Position)
        offer.GUI.Visible = distance > 0 and distance < 12
        if offer.GUI.Visible then
            visible += 1
        end
    end
    NoPlayers.Visible = visible == 0
end)