--All configuration for the PTRD-41
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirearmsHandler = script.Parent.Parent
local BoxConfigs = FirearmsHandler.Boxes

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Animations = {
    Aim = "RifleAim";
    Chamber = "RifleChargingHandle";
    Hold = "RifleHold";
    Load = "ShotgunShellIn";
    Prone = "ProneRifle";
    Unload = "PistolMagOut";
}

config.BarrelLength = 2.02 --meters

config.ChamberOnLoad = true
config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.EmptyChamber = true

config.FeedParts = {
    AP145Box10 = require(BoxConfigs.AP145Box10);
}
config.MaxCapacity = 1 --Only used when feeding rounds from ammo boxes
config.OpenActionOnEmpty = false
config.OpenActionOnReload = true

config.Firemodes = {
    "Manual";
    "Safe";
}
config.FireRate = 120 --rounds per minute
config.MuzzleVelocity = 1012 --meters per second

config.Sound = {
    SoundId = Sounds.Rifle145;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config