--All configuration for the FP-45
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local BoxConfigs = FirearmsHandler.Boxes

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "PistolAim";
    Hold = "HoldSide";
    Load = "FP45Load";
    Prone = "ProneHandgun";
    Unload = "FP45Unload";
}

config.BarrelLength = 0.1 --meters

config.ChamberOnLoad = true
config.DontChamber = true
config.EmptyChamber = true

config.FeedParts = {
    ACP45Box50 = require(BoxConfigs.ACP45Box50);
}
config.MaxCapacity = 1 --Only used when feeding rounds from ammo boxes
config.OpenActionOnEmpty = false
config.OpenActionOnReload = true

config.Firemodes = {
    "Manual";
}
config.FireRate = 120 --rounds per minute
config.MuzzleVelocity = 250 --meters per second

config.Sound = {
    SoundId = Sounds.Handgun45;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config