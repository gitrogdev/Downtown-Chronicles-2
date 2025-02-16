---All configuration for the Mosin-Nagant 5-round clip
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
config.Capacity = 5

config.MagIn = {
    Sound = {
        SoundId = Sounds.RifleClipOut;
    };
    Time = 1.5;
}

config.MagOut = {
    Sound = {
        SoundId = Sounds.RifleClipIn;
    };
    Time = 1.5;
}

config.Type = "Clip"

return config