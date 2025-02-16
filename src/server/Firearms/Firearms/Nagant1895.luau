--All configuration for the Nagant M1895
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local BoxConfigs = FirearmsHandler.Boxes

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "PistolAim";
    Chamber = "SMGChamber";
    Hold = "HoldSide";
    Load = "RevolverLoad";
    Prone = "ProneHandgun";
    Unload = "RevolverUnload";
}

config.BarrelLength = 0.11 --meters

config.ChamberOnLoad = true
config.Chambers = 7
config.ChamberSound = {
    SoundId = Sounds.RevolverHammer;
    Volume = 0.5;
}
config.ChamberTime = 0.5
config.EmptyChamber = false

config.FeedParts = {
    Nagant762Box50 = require(BoxConfigs.Nagant762Box50);
}
config.MaxCapacity = 7 --Only used when feeding rounds from ammo boxes
config.OpenActionOnEmpty = false
config.OpenActionOnReload = true

config.Firemodes = {
    "Double";
}
config.FireRate = 63 --rounds per minute
config.MuzzleVelocity = 335 --meters per second

config.Sound = {
    SoundId = Sounds.Handgun762R;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config