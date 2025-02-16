--All configuration for the M3
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local FeedConfigs = FirearmsHandler.Feeds

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "RifleAim";
    Chamber = "SMGChamber";
    Hold = "HoldSide";
    Load = "PistolMagIn";
    Prone = "ProneHandgun";
    Unload = "PistolMagOut";
}

config.BarrelLength = 0.203 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberOnLoad = true
config.ChamberTime = 0.5

config.FeedParts = {
    M3Mag32 = require(FeedConfigs.M3Mag32);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Auto";
}
config.FireRate = 450 --rounds per minute
config.MuzzleVelocity = 274 --meters per second

config.Sound = {
    SoundId = Sounds.Handgun45;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config