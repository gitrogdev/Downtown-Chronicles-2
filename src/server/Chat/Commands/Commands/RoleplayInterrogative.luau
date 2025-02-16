--The /me command used for roleplay actions
local Chat = game:GetService("Chat")
local ServerScriptService = game:GetService("ServerScriptService")

local ScriptStorage = ServerScriptService.ServerScripts
local Util = require(ScriptStorage.Util)

local command = {
    PrimaryAlias = "/do";
    SecondaryAlias = "/dolow";
    
    PermissionLevel = 0;
    ArgSequence = {
        "string"
    };
    RequireAlive = true;
    Execute = function(Player: Player, action: string)
        local Head = Player.Character:FindFirstChild("Head")
        if not Head then
            return "Character does not have a head!"
        end

        action = Chat:FilterStringForBroadcast(action, Player)

        Util.RoleplayAction(
            Head,
            `* {action} (( $\{Associated} ))`
        )
    end
}

return command