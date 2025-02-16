---All configuration for the .45 ACP 50-round Box
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.ACP45)
config.Capacity = 50

config.MagIn = {
    Sound = {
        SoundId = Sounds.LiberatorLoad;
    };
    Time = 2;
}

config.MagOut = {
    Sound = {
        SoundId = Sounds.LiberatorUnload;
    };
    Time = 1.5;
}

config.Type = "Box"

return config