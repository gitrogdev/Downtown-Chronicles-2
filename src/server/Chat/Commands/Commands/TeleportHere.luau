--The /tphere (/bring) command used for teleporting a player to the executor
local command = {
    PrimaryAlias = "/tphere";
    SecondaryAlias = "/bring";
    
    PermissionLevel = 1;
    ArgSequence = {
        "Characters"
    };
    RequireAlive = true;
    Execute = function(Player: Player, Targets: table)
        local RootPart = Player.Character:FindFirstChild("HumanoidRootPart")
        if not RootPart then
            return `No root part found in character!`
        end

        local successes = 0
        for i, Target in ipairs(Targets) do
            local Humanoid: Humanoid = Target:FindFirstChildOfClass("Humanoid")
            local TargetPart: Part = Humanoid and Humanoid.RootPart
            if not TargetPart then
                warn(
                    `{script}.Execute: No target HumanoidRootPart found for \z
                    {Target}!`
                )
                continue
            end

            Humanoid.Sit = false
            if Humanoid.SeatPart then
                Humanoid:GetPropertyChangedSignal("SeatPart"):Wait()
            end
            TargetPart.CFrame = RootPart.CFrame:ToWorldSpace(
                CFrame.new(0, 0, -3)
            )
            successes += 1
        end

        if successes > 0 then
            return `Successfully teleported {successes} \z
                character{(successes == 1 and "") or "s"} to your location!`
        else
            return `Unable to teleport {#Targets} \z
                character{(#Targets == 1 and "") or "s"} to your location.`
        end
    end
}

return command