---All configuration for the .357 Magnum 50-round Box
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Magnum357)
config.Capacity = 50

config.MagIn = {
    Sound = {
        SoundId = Sounds.RevolverLoad;
    };
    Time = 0.5;
}

config.MagOut = {
    Sound = {
        SoundId = Sounds.RevolverEmpty;
    };
    Time = 0.5;
}

config.Type = "Box"

return config