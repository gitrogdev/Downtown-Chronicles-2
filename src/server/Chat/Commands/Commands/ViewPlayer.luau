--The /view command used for viewing a player
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ViewPlayer = ReplicatedCommunication.ViewPlayer

local command = {
    PrimaryAlias = "/view";
    SecondaryAlias = "/watch";
    
    PermissionLevel = 1;
    ArgSequence = {
        "Character"
    };
    Execute = function(Player: Player, Target: Model)
        local TargetHumanoid = Target:FindFirstChildOfClass("Humanoid")
        if not TargetHumanoid then
            return `No Humanoid found for target player {Target}!`
        end

        ViewPlayer:FireClient(Player, TargetHumanoid)

        return `Now viewing {Target}.`
    end
}

return command