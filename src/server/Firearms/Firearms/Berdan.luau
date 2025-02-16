--All configuration for the Berdan II
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

config.BarrelLength = 0.83 --meters

config.ChamberOnLoad = true
config.ChamberSound = {
    SoundId = Sounds.RifleChamber;
    Volume = 0.5;
}
config.ChamberTime = 0.5

config.EmptyChamber = true

config.FeedParts = {
    Russian1075Box10 = require(BoxConfigs.Russian1075Box10);
}
config.MaxCapacity = 1 --Only used when feeding rounds from ammo boxes
config.OpenActionOnEmpty = false
config.OpenActionOnReload = true

config.Firemodes = {
    "Manual";
}
config.FireRate = 120 --rounds per minute
config.MuzzleVelocity = 437 --meters per second

config.Sound = {
    PlaybackSpeed = 0.5;
    SoundId = Sounds.Rifle1075;
    Volume = 1;
}

config.Tracers = 0 --will use tracers every x rounds, 0 to disable

return config