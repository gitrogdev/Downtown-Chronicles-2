--The /liftemergency command for lifting states of emergency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local AlertHandler = require(ServerScripts.Alerts)

local command = {
    PrimaryAlias = "/liftemergency";
    SecondaryAlias = "/endemergency";
    
    PermissionLevel = 4;
    ArgSequence = {};
    Execute = function(Player: Player)
        if not ReplicatedStorage:GetAttribute("Emergency") then
            return "A state of emergency has not been declared!"
        end

        AlertHandler.EmergencyLift()
        return "State of emergency lifted!"
    end
}

return command