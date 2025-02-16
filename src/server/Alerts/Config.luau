--Configuration relating to alerts on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local config = {}

config.Alerts = {
    Rocket = {
        Sounds.AlertRocketENG;
        Sounds.AlertRocketVLK;
    };
}

config.AllClear = {
    Sounds.AllClearENG;
    Sounds.AllClearVLK;
}

config.Emergency = {
    Sounds.EmergencyENG;
    Sounds.EmergencyVLK;
}

config.EmergencyLift = {
    Sounds.EmergencyLiftedENG;
    Sounds.EmergencyLiftedVLK;
}

config.Repeats = 4

config.Siren = Sounds.Alert

return config