--The /kick command used for kicking a player out of the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration

local Rules = require(ReplicatedConfig.Rules)

local command = {
    PrimaryAlias = "/kick";
    
    PermissionLevel = 2;
    ArgSequence = {
        "Player",
        "string"
    };
    Execute = function(Player: Player, Kick: Player, reason: string)
        local ruleData = Rules.RomanDictionary[reason:upper()]
        if not ruleData then
            return `Unknown rule {reason}!`
        end

        Kick:Kick(ruleData.Name)
        return `Kicked {Kick} for {ruleData.Name:lower()}!`
    end
}

return command