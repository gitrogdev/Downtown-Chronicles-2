--This script handles the start menu and loading screen
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CharacterSelection = require(script.CharacterSelection)
local CreditHandler = require(script.Credits)
local LoadingHandler = require(script.Loading)
local TipConfig = require(script.Tips)
local TitleHandler = require(script.Title)

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Util = require(ReplicatedScripts.Util)

local Sounds = require(ReplicatedConfig.Sounds)

local UIStorage = ReplicatedStorage.UserInterface
local StartMenu = UIStorage.StartMenu:Clone()
local TipDisplay = StartMenu:WaitForChild("GameTip")

local Blackout = Util.CreateInstance("ColorCorrectionEffect", {
    Brightness = -1;
    Name = "Blackout";
    Parent = Lighting;
})

local MenuMusic = Util.CreateInstance("Sound", {
    Looped = true;
    Name = "MenuMusic";
    Parent = StartMenu;
    SoundId = Sounds.MainTheme;
})
MenuMusic:Play()

task.spawn(function()
    CharacterSelection.Setup(StartMenu, Blackout, MenuMusic)
end)

task.spawn(function()
    --Randomizes the cycle of the tips
    local cache = table.clone(TipConfig.Cyclical)
    local cycle = {}
    for i = 1, #TipConfig.Cyclical do
        table.insert(cycle, table.remove(cache, math.random(1, #cache)))
    end

    local i = 1
    while TipDisplay.Text ~= TipConfig.Scroll do
        Util.Typewriter(cycle[i], TipDisplay)
        task.wait(10)
        i += 1
        if i > #cycle then
            i = 1
        end
    end
end)

StartMenu.Parent = Player.PlayerGui

LoadingHandler.Load(StartMenu)
CreditHandler.Display(StartMenu)

TweenService:Create(Blackout, TweenInfo.new(1), {
    Brightness = 0;
}):Play()

TitleHandler.Display(StartMenu, CharacterSelection, Blackout)