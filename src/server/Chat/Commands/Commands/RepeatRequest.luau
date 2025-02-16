--The /repeatrequest command used for re-sending name requests to the Discord
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local NameHandler = require(ServerScripts.Characters.Names)
local DataHandler = require(ServerScripts.Data)

local command = {
    PrimaryAlias = "/repeatrequest";
    SecondaryAlias = "/resubmitname";
    
    PermissionLevel = 4;
    ArgSequence = {
        "CharacterID"
    };
    Execute = function(Player: Player, charId: number)
        local charData = DataHandler.Get("Characters", tostring(charId))

        if not charData then
            return `No character data found for character with ID {charId}.`
        end

        NameHandler.Submit(
            charData.FirstName,
            charData.LastName,
            charData.Gender,
            charId,
            Player
        )

        return `Re-submitted the name request for {charData.FirstName} \z
        {charData.LastName} ({charId}).`
    end
}

return command