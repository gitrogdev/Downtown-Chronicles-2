--The /ban command used for temporarily banning players from the game
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local SecurityHandler = require(ServerScripts.Security)
local Util = require(ServerScripts.Util)

local command = {
    PrimaryAlias = "/ban";
    
    PermissionLevel = 3;
    ArgSequence = {
        "User",
        "string"
    };
    Execute = function(Player: Player, ban: number, reason: string)
        local response = SecurityHandler.Ban(ban, reason:upper(), Player)
        if not response then
            return `Failed to ban {Players:GetNameFromUserIdAsync(ban)} for \z
                {reason}.`
        else
            return `Successfully banned {Players:GetNameFromUserIdAsync(ban)} \z
                for {Util.ReadableTime(response)}.`
        end
    end
}

return command