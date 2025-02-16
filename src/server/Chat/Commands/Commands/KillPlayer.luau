--The /kill used for killing characters
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local DeathHandler = require(ServerScripts.Deaths)

local command = {
    PrimaryAlias = "/kill";
    SecondaryAlias = "/slay";
    
    PermissionLevel = 2;
    ArgSequence = {
        "Characters"
    };
    Execute = function(Player: Player, Targets: table)
        local successes = 0
        for i, Target in ipairs(Targets) do
            local Humanoid = Target:FindFirstChildWhichIsA("Humanoid")
            if not Humanoid then
                warn(`{script}.Execute: No target Humanoid found for {Target}!`)
                continue
            end

            DeathHandler.TakeDamage(
                Humanoid,
                math.huge,
                `Command killed by {Player}`,
                Player.UserId
            )
        end

        if successes > 0 then
            return `Successfully killed {successes} \z
                character{(successes == 1 and "") or "s"}!`
        else
            return `Unable to kill {#Targets} \z
                character{(#Targets == 1 and "") or "s"}.`
        end
    end
}

return command