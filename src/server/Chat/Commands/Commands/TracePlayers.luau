--The /trace command used for tracking players
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local TracePlayer = ReplicatedCommunication.TracePlayer

local command = {
    PrimaryAlias = "/trace";
    
    PermissionLevel = 1;
    ArgSequence = {
        "Characters"
    };
    Execute = function(Player: Player, Targets: table)
        local successes = 0
        for i, Target in ipairs(Targets) do
            local TargetNametag = Target:FindFirstChild("Head")
                and Target.Head:FindFirstChild("Nametag")
            if not TargetNametag then
                warn(
                    `{script}.Execute: No target nametag found for {Target}!`
                )
                continue
            end

            TracePlayer:FireClient(Player, TargetNametag)
            successes += 1
        end

        if successes > 0 then
            return `Successfully traced {successes} \z
                player{(successes == 1 and "") or "s"}!`
        else
            return `Unable to trace {#Targets} \z
                player{(#Targets == 1 and "") or "s"}.`
        end
    end
}

return command