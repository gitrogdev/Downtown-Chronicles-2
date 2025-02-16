---All configuration for the Hi-Point C-9 8-round magazine
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Parabellum9)
config.Capacity = 8

config.MagIn = {
    Sound = {
        SoundId = Sounds.PistolMagIn;
    };
    Time = 1;
}

config.MagOut = {
    Sound = {
        SoundId = Sounds.PistolMagOut;
    };
    Time = 1;
}

config.Type = "Mag"

return config