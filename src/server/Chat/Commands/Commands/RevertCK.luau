--The /revertck command used for reverting a character kill
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local WebhookHandler = require(ServerScripts.Webhooks)

local command = {
    PrimaryAlias = "/revertck";
    SecondaryAlias = "/unck";
    
    PermissionLevel = 4;
    ArgSequence = {
        "CharacterID"
    };
    Execute = function(Player: Player, charId: number)
        local charName, success
        DataHandler.Update("Characters", tostring(charId),
            function(oldData: table)
                oldData = oldData or {}

                charName = `{oldData.FirstName} {oldData.LastName}`
                success = oldData.Dead and true or false

                oldData.Dead = false

                return oldData
            end
        )

        if not success then
            return (
                success == false and
                `Character with ID {charId} had not been character-killed.`
            )
                or `Unable to revert the character-kill character with ID \z
                {charId}.`
        end

        WebhookHandler.Post(
            `{Player} has reverted the character-kill of {charName} \z
            ({charId})`,
            "ModLog"
        )
        return `Reverted the character-kill of {charName} ({charId}).`
    end
}

return command