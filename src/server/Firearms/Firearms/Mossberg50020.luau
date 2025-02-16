--All configuration for the Mossberg 500 20 gauge
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local BoxConfigs = FirearmsHandler.Boxes

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "RifleAim";
    Chamber = "ShotgunPump";
    Hold = "RifleHold";
    Load = "ShotgunShellIn";
    Prone = "ProneRifle";
    Unload = "PistolMagOut";
}

config.BarrelLength = 0.51 --meters

config.ChamberSound = {
    SoundId = Sounds.ShotgunPump;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.FeedParts = {
    Bird20Box25 = require(BoxConfigs.Bird20Box25);
    Buck120Box25 = require(BoxConfigs.Buck120Box25);
    Slug20Box25 = require(BoxConfigs.Slug20Box25);
}
config.MaxCapacity = 6 --Only used when feeding rounds from ammo boxes
config.OpenActionOnEmpty = false
config.OpenActionOnReload = true

config.Firemodes = {
    "Manual";
    "Safe";
}
config.FireRate = 120 --rounds per minute
config.MuzzleVelocity = 410 --meters per second

config.Sound = {
    SoundId = Sounds.Shotgun20;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config