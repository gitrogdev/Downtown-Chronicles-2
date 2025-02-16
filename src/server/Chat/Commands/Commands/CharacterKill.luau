--The /killcharacter command used for permanently killing a character
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local WebhookHandler = require(ServerScripts.Webhooks)

local command = {
    PrimaryAlias = "/killcharacter";
    SecondaryAlias = "/ck";
    
    PermissionLevel = 4;
    ArgSequence = {
        "CharacterID"
    };
    Execute = function(Player: Player, charId: number)
        local charBday, charName, success
        DataHandler.Update("Characters", tostring(charId),
            function(oldData: table)
                oldData = oldData or {}

                charBday = oldData.Birthday
                charName = `{oldData.FirstName} {oldData.LastName}`
                success = (not oldData.Dead)

                oldData.Dead = true

                return oldData
            end
        )

        if not success then
            return (
                success == false and
                `Character with ID {charId} has already been character-killed.`
            )
                or `Unable to character-kill character with ID {charId}.`
        end

        for i, KickPlayer in ipairs(Players:GetPlayers()) do
            if KickPlayer:GetAttribute("ID") == charId then
                KickPlayer:Kick("Your character has been character killed!")
                break
            end
        end

        WebhookHandler.Post(
            `{Player} has performed a character-kill of {charName} ({charId}) \z
            (Birthday: {charBday.Day}.{charBday.Month}.{charBday.Year}.)`,
            "ModLog"
        )
        return `Performed a character-kill of {charName} ({charId}).`
    end
}

return command