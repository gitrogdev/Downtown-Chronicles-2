---All configuration for the 12 gauge 00 Buck 25-round Box
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Gauge12Buck00)
config.Capacity = 25

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