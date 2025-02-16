--The /erase command used for carrying out a right-of-erasure request
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local WebhookHandler = require(ServerScripts.Webhooks)

local command = {
    PrimaryAlias = "/erase";
    SecondaryAlias = "/forget";
    
    PermissionLevel = 6;
    ArgSequence = {
        "User",
        "string"
    };
    Execute = function(Player: Player, erase: number)
        local userData = DataHandler.Get("UserData", tostring(erase))
        if not userData then
            return `No data found for user with ID {erase}`
        end

        for i, characterId in ipairs(userData.Characters or {}) do
            DataHandler.Remove("Characters", tostring(characterId))
        end

        for i, characterId in ipairs(userData.Deleted or {}) do
            DataHandler.Remove("Characters", tostring(characterId))
        end
        DataHandler.Remove("UserData", tostring(erase))

        WebhookHandler.Post(
            `{Player} just fulfilled a right-of-erasure request for the user \z
            with ID {erase}.\n\z
            All data for that user has been permanently erased.`,
            "ModLog"
        )

        return `Successfully erased all data for user with ID {erase} \z
            This cannot be undone.`
    end
}

return command