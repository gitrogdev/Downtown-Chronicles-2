--All configuration for the Izhevsk PB
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local FeedConfigs = FirearmsHandler.Feeds

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "PistolAim";
    Chamber = "PistolChamber";
    Hold = "HoldSide";
    Load = "PistolMagIn";
    Prone = "ProneHandgun";
    Unload = "PistolMagOut";
}

config.BarrelLength = 0.243 --meters

config.ChamberSound = {
    SoundId = Sounds.PistolChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    MakarovMag8 = require(FeedConfigs.MakarovMag8);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Semi";
}
config.FireRate = 300 --rounds per minute
config.MuzzleVelocity = 290 --meters per second

config.Sound = {
    PlaybackSpeed = 3;
    SoundId = Sounds.Handgun9Makarov;
    Volume = 0.25;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config