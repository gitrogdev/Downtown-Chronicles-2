--All configuration for the Mafia PPSh-41
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
    Hold = "HoldSide";
    Load = "ARMagIn";
    Prone = "ProneHandgun";
    Unload = "ARMagOut";
}

config.BarrelLength = 0.03 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    PPShDrum71 = require(FeedConfigs.PPShDrum71);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Auto";
    "Semi";
}
config.FireRate = 950 --rounds per minute
config.MuzzleVelocity = 488 --meters per second

config.Sound = {
    SoundId = Sounds.Handgun762;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config