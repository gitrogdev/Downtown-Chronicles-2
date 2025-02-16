--All configuration for the FN FS2000
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

config.BarrelLength = 0.4 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChargingHandle;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    M16Mag20 = require(FeedConfigs.M16Mag20);
    STANAG30 = require(FeedConfigs.STANAG30);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Semi";
    "Safe";
}
config.FireRate = 300 --rounds per minute
config.MuzzleVelocity = 900 --meters per second

config.Sound = {
    SoundId = Sounds.Rifle556NATO;
    Volume = 1;
}

config.StoreShells = 5
config.Tracers = 3 --will use tracers every x rounds, 0 to disable

return config