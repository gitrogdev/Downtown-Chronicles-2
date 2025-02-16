--The /declareemergency command for declaring states of emergency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local AlertHandler = require(ServerScripts.Alerts)

local command = {
    PrimaryAlias = "/declareemergency";
    SecondaryAlias = "/emergency";
    
    PermissionLevel = 4;
    ArgSequence = {};
    Execute = function(Player: Player)
        if ReplicatedStorage:GetAttribute("Emergency") then
            return "State of emergency already declared!"
        end

        AlertHandler.Emergency()
        return "State of emergency declared!"
    end
}

return command