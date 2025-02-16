--The /permban command used for permanently banning players from the game
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local SecurityHandler = require(ServerScripts.Security)

local command = {
    PrimaryAlias = "/permban";
    SecondaryAlias = "/pban";
    
    PermissionLevel = 4;
    ArgSequence = {
        "User",
        "string"
    };
    Execute = function(Player: Player, ban: number, reason: string)
        local response = SecurityHandler.Ban(ban, reason, Player, true)
        if not response then
            return `Failed to perm-ban {Players:GetNameFromUserIdAsync(ban)} \z
                for {reason}.`
        else
            return `Successfully perm-banned \z
                {Players:GetNameFromUserIdAsync(ban)}.`
        end
    end
}

return command