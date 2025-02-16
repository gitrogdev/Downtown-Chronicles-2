--This script handles the client-side portion of object interactions
local Players = game:GetService("Players")

local NPCHandler = require(script.NPCs)
local SeatHandler = require(script.Seats)

local Player = Players.LocalPlayer

local usesCard = {}
local processed = {}
local function process(Object: Instance)
    --Prevents duplicate setup of the same object
    if processed[Object] then
        return
    end

    if Object:IsA("ProximityPrompt") then
        Object:SetAttribute("Original", Object.MaxActivationDistance)

        if Object:GetAttribute("UsesCard") then
            table.insert(usesCard, Object)
        end

        local Seat = Object:FindFirstAncestorWhichIsA("Seat")
        if Object.Name == "SeatPrompt" and Seat then
            SeatHandler.Setup(Seat, Object)
        elseif Object.Name == "NPCPrompt" then
            NPCHandler.Setup(Object)
        end
    end
    
    processed[Object] = true
end

for i, Child in ipairs(workspace:GetDescendants()) do
    process(Child)
end

Player:GetAttributeChangedSignal("UsingCard"):Connect(function()
    local usingCard = Player:GetAttribute("UsingCard")
    for i, Prompt in ipairs(usesCard) do
        Prompt:SetAttribute("Deactivated", not not usingCard)
        Prompt.MaxActivationDistance = usingCard and 0
            or Prompt:GetAttribute("Original")
    end
end)
workspace.DescendantAdded:Connect(process)