--The /smite used for killing characters with lightning
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local WeatherHandler = require(ServerScripts.Environment.Weather)

local command = {
    PrimaryAlias = "/smite";
    SecondaryAlias = "/lightning";
    
    PermissionLevel = 4;
    ArgSequence = {
        "Characters"
    };
    Execute = function(Player: Player, Targets: table)
        local successes = 0
        for i, Target in ipairs(Targets) do
            local RootPart = Target:FindFirstChild("HumanoidRootPart")
            if not RootPart then
                warn(
                    `{script}.Execute: No target root part found for {Target}!`
                )
                continue
            end

            WeatherHandler.LightningStrike(
                RootPart.Position + Vector3.new(0, 500, 0),
                RootPart.Position
            )
            successes += 1
        end

        if successes > 0 then
            return `Successfully smote {successes} \z
                character{(successes == 1 and "") or "s"}!`
        else
            return `Unable to smite {#Targets} \z
                character{(#Targets == 1 and "") or "s"}.`
        end
    end
}

return command