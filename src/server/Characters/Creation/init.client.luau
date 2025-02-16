--This script handles character customization on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Util = require(ScriptStorage.Util)

local PartStorage = ReplicatedStorage.Parts
local CustomizationRoom = PartStorage.CustomizationRoom:Clone()
local DisplayCharacter = CustomizationRoom:WaitForChild("Character")

local PageHandlers = {
    Character = require(script.Character);
    Coloring = require(script.Coloring);
    Faces = require(script.Faces);
    Hairs = require(script.Hairs);
    Verify = require(script.Verify);
}
local MainGui = script.Parent
local CharacterRoom = MainGui:WaitForChild("CharacterRoom")
local Pages = MainGui:WaitForChild("CharacterPages")
local PageLayout = Pages:WaitForChild("UIPageLayout")

local RoomModel = CharacterRoom:WaitForChild("WorldModel")

CharacterRoom.CurrentCamera = Util.CreateInstance("Camera", {
    CFrame = CustomizationRoom:WaitForChild("CameraPart").CFrame;
    Parent = CharacterRoom;
})
CustomizationRoom.Parent = RoomModel

for key, PageHandler in pairs(PageHandlers) do
    local LastPage, NextPage = PageHandler.Setup(Pages, DisplayCharacter, PageHandlers)
    if LastPage then
        LastPage.MouseButton1Click:Connect(function()
            PageLayout:Previous()
        end)
    end

    if NextPage then
        NextPage.MouseButton1Click:Connect(function()
            PageLayout:Next()
        end)
    end
end