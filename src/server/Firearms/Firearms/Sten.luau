--All configuration for the UZI
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local FeedConfigs = FirearmsHandler.Feeds

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "StenAim";
    Chamber = "SMGChamber";
    Hold = "RifleHold";
    Load = "StenMagIn";
    Prone = "ProneRifle";
    Unload = "StenMagOut";
}

config.BarrelLength = 0.196 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    StenMag32 = require(FeedConfigs.StenMag32);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Auto";
    "Semi";
}
config.FireRate = 500 --rounds per minute
config.MuzzleVelocity = 365 --meters per second

config.Sound = {
    SoundId = Sounds.Handgun9;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config