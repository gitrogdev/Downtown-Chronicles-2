---All configuration for the Zastava M57 9-round magazine
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Tokarev762)
config.Capacity = 9

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