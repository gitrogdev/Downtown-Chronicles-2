---All configuration for the AKM 30-round magazine
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Soviet762)
config.Capacity = 30

config.MagIn = {
    Sound = {
        SoundId = Sounds.AKMagIn;
    };
    Time = 1;
}

config.MagOut = {
    Sound = {
        SoundId = Sounds.AKMagOut;
    };
    Time = 1;
}

config.Type = "Mag"

return config