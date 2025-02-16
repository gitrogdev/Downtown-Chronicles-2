--All configuration for the M1928A1 Thompson
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
    Load = "ARMagIn";
    Prone = "ProneRifle";
    Unload = "ARMagOut";
}

config.BarrelLength = 0.3 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    ThompsonMag30 = require(FeedConfigs.ThompsonMag30);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Auto";
    "Semi";
    "Safe";
}
config.FireRate = 400 --rounds per minute
config.MuzzleVelocity = 662 --meters per second

config.Sound = {
    SoundId = Sounds.Handgun45;
    Volume = 1;
}

config.Tracers = 1 --will use tracers every x rounds, 0 to disable

return config