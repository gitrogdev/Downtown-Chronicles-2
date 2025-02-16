--The /unban command used for unbanning players from the game
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local SecurityHandler = require(ServerScripts.Security)

local command = {
    PrimaryAlias = "/unban";
    
    PermissionLevel = 3;
    ArgSequence = {
        "User"
    };
    Execute = function(Player: Player, unban: number)
        SecurityHandler.Unban(unban, Player)
        return `Successfully unbanned {Players:GetNameFromUserIdAsync(unban)}.`
    end
}

return command