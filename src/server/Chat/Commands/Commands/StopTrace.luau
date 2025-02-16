--The /untrace command used to stop tracking players
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local UntracePlayer = ReplicatedCommunication.UntracePlayer

local command = {
    PrimaryAlias = "/untrace";
    SecondaryAlias = "/stoptrace";
    
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

            UntracePlayer:FireClient(Player, TargetNametag)
            successes += 1
        end

        if successes > 0 then
            return `Successfully stopped tracing {successes} \z
                player{(successes == 1 and "") or "s"}!`
        else
            return `Unable to stop tracing {#Targets} \z
                player{(#Targets == 1 and "") or "s"}.`
        end
    end
}

return command