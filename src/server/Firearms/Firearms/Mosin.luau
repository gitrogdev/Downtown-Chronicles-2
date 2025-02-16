--All configuration for the Mosin-Nagant
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local FeedConfigs = FirearmsHandler.Feeds

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "RifleAim";
    Chamber = "AKChamber";
    Hold = "RifleHold";
    Load = "RifleClipIn";
    Prone = "ProneRifle";
    Unload = "RifleClipOut";
}

config.BarrelLength = 0.730 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    MosinClip5 = require(FeedConfigs.MosinClip5);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = true

config.Firemodes = {
    "Manual";
    "Safe";
}
config.FireRate = 120 --rounds per minute
config.MuzzleVelocity = 865 --meters per second

config.Sound = {
    SoundId = Sounds.Rifle762Russian;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config