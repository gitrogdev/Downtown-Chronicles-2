--The /associate command used for associating names with characters
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local CustomizationConfig = require(ReplicatedConfig.Customization)
local NameConfig = CustomizationConfig.Names

local ScriptStorage = ServerScriptService.ServerScripts
local Util = require(ScriptStorage.Util)

local MAX_LENGTH = NameConfig.MaxLength * 2 + 1

local command = {
    PrimaryAlias = "/associate";
    SecondaryAlias = "/recognize";
    
    PermissionLevel = 0;
    ArgSequence = {
        "CharacterID",
        "string"
    };
    RequireAlive = true;
    Execute = function(Player: Player, id: number, name: string)
        if #name > MAX_LENGTH then
            return `The name "{name}" is too long! (Max length: {MAX_LENGTH}, \z
                got {#name})`
        end

        local Target: Player = Util.FindFirstChildOfClassWithAttributes(
            Players, "Player", {ID = id}
        )
        if not Target then
            return `No character with ID {id} is currently in game.`
        end

        if Target:GetAttribute("Masked") then
            return `You can not associate a name with a masked character!`
        end

        Util.AssociateName(Player, id, name)
        return `Associated the name "{name}" with character {Target.UserId}-{id}`
    end
}

return command