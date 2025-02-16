--All configuration for the Zastava M84
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
    Load = "LMGBoxIn";
    Prone = "ProneRifle";
    Unload = "LMGBoxOut";
}

config.BarrelLength = 0.658 --meters

config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    PKMBox100 = require(FeedConfigs.PKMBox100);
}
config.OpenActionOnEmpty = true
config.OpenActionOnReload = false

config.Firemodes = {
    "Auto";
    "Safe";
}
config.FireRate = 750 --rounds per minute
config.MuzzleVelocity = 825 --meters per second

config.Sound = {
    SoundId = Sounds.Rifle762Russian;
    Volume = 1;
}

config.Tracers = 3 --will use tracers every x rounds, 0 to disable

return config