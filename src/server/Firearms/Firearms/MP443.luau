--All configuration for the MP-443 Grach
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

config.BarrelLength = 0.113 --meters

config.ChamberSound = {
    SoundId = Sounds.PistolChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    MP443Mag18 = require(FeedConfigs.MP443Mag18);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Semi";
}
config.FireRate = 300 --rounds per minute
config.MuzzleVelocity = 450 --meters per second

config.Sound = {
    SoundId = Sounds.Handgun9;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config