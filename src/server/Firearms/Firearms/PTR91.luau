--All configuration for the PTR 91
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local FeedConfigs = FirearmsHandler.Feeds

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "RifleAim";
    Chamber = "RifleChargingHandle";
    Hold = "RifleHold";
    Load = "ARMagIn";
    Prone = "ProneRifle";
    Unload = "ARMagOut";
}

config.BarrelLength = 0.45 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChargingHandle;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    G3Mag20 = require(FeedConfigs.G3Mag20);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Semi";
    "Safe";
}
config.FireRate = 300 --rounds per minute
config.MuzzleVelocity = 790 --meters per second

config.Sound = {
    SoundId = Sounds.Rifle762NATO;
    Volume = 1;
}

config.Tracers = 1 --will use tracers every x rounds, 0 to disable

return config