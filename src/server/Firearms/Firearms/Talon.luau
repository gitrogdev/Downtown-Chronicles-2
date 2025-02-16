--All configuration for the TF Talon
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local FeedConfigs = FirearmsHandler.Feeds

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "PistolAim";
    Chamber = "SMGChamber";
    Hold = "HoldSide";
    Load = "PistolMagIn";
    Prone = "ProneHandgun";
    Unload = "PistolMagOut";
}

config.BarrelLength = 0.13 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    TalonMag30 = require(FeedConfigs.TalonMag30);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Auto";
    "Semi";
    "Safe";
}
config.FireRate = 900 --rounds per minute
config.MuzzleVelocity = 400 --meters per second

config.Sound = {
    SoundId = Sounds.Handgun9;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config