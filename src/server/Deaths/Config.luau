--Contains all config related to death and ragdolling
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = {}

config.BloodDecals = {
    "rbxassetid://195871208";
    "rbxassetid://6533576835";
    "rbxassetid://508050980";
    "rbxassetid://508050982";
    "rbxassetid://6533577611";
    "rbxassetid://195871375";
    "rbxassetid://6533576652";
    "rbxassetid://508050994";
    "rbxassetid://508050906";
    "rbxassetid://6533576407";
    "rbxassetid://6533522408";
}

config.DutyJobs = {
    Guardsman = true;
    MIA = true;
}

config.RemoveClasses = {
    Motor6D = true;
    Script = true;
    Weld = true;
}

config.NLRTime = 15 --minutes
config.RespawnTime = ReplicatedStorage:GetAttribute("RespawnTime") or 60 --s

config.RotTime = 1000 --seconds

return config