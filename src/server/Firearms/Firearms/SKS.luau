--All configuration for the Zastava M59/66
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
    Load = "RifleClipIn";
    Prone = "ProneRifle";
    Unload = "RifleClipOut";
}

config.BarrelLength = 0.559 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    SKSClip10 = require(FeedConfigs.SKSClip10);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = true

config.Firemodes = {
    "Semi";
    "Safe";
}
config.FireRate = 300 --rounds per minute
config.MuzzleVelocity = 735 --meters per second

config.Sound = {
    SoundId = Sounds.Rifle762Soviet;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config