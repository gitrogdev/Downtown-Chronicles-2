--The /notify command used for sending a notification to players
local Chat = game:GetService("Chat")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local SendNotification = ReplicatedCommunication.SendNotification

local command = {
    PrimaryAlias = "/notify";
    SecondaryAlias = "/n";
    
    PermissionLevel = 1;
    ArgSequence = {
        "Players",
        "string"
    };
    Execute = function(Player: Player, Targets: table, message: string)
        local successes = 0
        for i, Target in ipairs(Targets) do
            local filtered = Chat:FilterStringAsync(message, Player, Target);
            if filtered == message then
                SendNotification:FireClient(Target, {
                    Title = Player.Name;
                    Text = filtered;
                    Icon = Players:GetUserThumbnailAsync(
                        Player.UserId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size420x420
                    );
                    Duration = 20;
                })
                successes += 1
            else warn(
                `{script}.Execute: Filtered notification {message} from \z
                {Player} to {filtered}!`
            )
            end
        end

        if successes > 0 then
            return `Successfully sent a notification to {successes} \z
                player{(successes == 1 and "") or "s"}!`
        else
            return `Unable to send a notification to {#Targets} \z
                player{(#Targets == 1 and "") or "s"}.`
        end
    end
}

return command