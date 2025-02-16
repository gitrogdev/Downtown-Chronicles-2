--All configuration for the MPi-K74K
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

config.BarrelLength = 0.415 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    AK74Mag30 = require(FeedConfigs.AK74Mag30);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Auto";
    "Semi";
    "Safe";
}
config.FireRate = 650 --rounds per minute
config.MuzzleVelocity = 890 --meters per second

config.Sound = {
    SoundId = Sounds.Rifle545Soviet;
    Volume = 1;
}

config.Tracers = 3 --will use tracers every x rounds, 0 to disable

return config