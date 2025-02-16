--The /evict command for evicting a player from their residence
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local HomeHandler = require(ServerScripts.Homes)

local command = {
    PrimaryAlias = "/evict";

    PermissionLevel = 4;
    ArgSequence = {
        "CharacterID"
    };
    Execute = function(Player: Player, toEvict: number)
        return HomeHandler.Evict(toEvict, Player)
            and `The character with ID {toEvict} has been evicted.`
            or `Failed to evict character with ID {toEvict}.`
    end
}

return command