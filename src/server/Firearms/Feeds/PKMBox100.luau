---All configuration for the PKM 100-round box
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Russian762)
config.Capacity = 100

config.MagIn = {
    Sound = {
        SoundId = Sounds.LMGBoxIn;
    };
    Time = 1.6;
}

config.MagOut = {
    Sound = {
        SoundId = Sounds.LMGBoxOut;
    };
    Time = 1.6;
}

config.Type = "Mag"

return config