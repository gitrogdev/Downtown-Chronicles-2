--Contains all configuration related to game security measures
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local config  = {}

config.AFKTime = 30 --minutes

config.Honeypots = {
    "BanPlayer";
    "CollectPaycheck";
    "CompleteJob";
    "GetCitizenship";
    "GetLicense";
    "GiveTool";
    "OverrideHDP";
    "OverrideLTC";
    "OverrideMGP";
    "TakeDamage";
    "UpdateBalance";
}

config.Packages = {
    ReplicatedStorage.Parts,
    ReplicatedStorage.ReplicatedScripts,
    ReplicatedStorage.UserInterface,
    ServerScriptService.ServerScripts,
    ServerStorage.Parts,
    ServerStorage.UserInterface,
    StarterPlayer.StarterPlayerScripts.ClientScripts
}

config.ResetPay = {
    Guardsman = true;
    MIA = true;
}

return config