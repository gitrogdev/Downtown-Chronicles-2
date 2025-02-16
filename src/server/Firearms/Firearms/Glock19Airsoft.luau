--All configuration for the Glock 19
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

config.BarrelLength = 0.102 --meters

config.ChamberSound = {
    SoundId = Sounds.PistolChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    Glock19AirsoftMag30 = require(FeedConfigs.Glock19AirsoftMag30);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Semi";
}
config.FireRate = 300 --rounds per minute
config.MuzzleVelocity = 94 --meters per second

config.NoFlash = true

config.Sound = {
    SoundId = Sounds.Airsoft;
    Volume = 0.5;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config