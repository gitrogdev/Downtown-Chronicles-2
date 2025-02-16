---All configuration for the 10.75 x 58mmR 10-round Box
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Russian1075)
config.Capacity = 10

config.MagIn = {
    Sound = {
        SoundId = Sounds.ShotgunLoad;
    };
    Time = 1;
}

config.MagOut = {
    Sound = {
        SoundId = Sounds.ShotgunLoad;
    };
    Time = 1;
}

config.Type = "Box"

return config