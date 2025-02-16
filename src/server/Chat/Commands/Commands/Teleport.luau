--The /teleport command used for teleporting players to a player
local command = {
    PrimaryAlias = "/teleport";
    SecondaryAlias = "/tp";
    
    PermissionLevel = 1;
    ArgSequence = {
        "Characters",
        "Character"
    };
    Execute = function(Player: Player, Targets: table, Destination: Model)
        local DestinationPart = Destination:FindFirstChild("HumanoidRootPart")
        if not DestinationPart then
            return `No root part found for destination character {Destination}!`
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
            TargetPart.CFrame = DestinationPart.CFrame:ToWorldSpace(
                CFrame.new(0, 0, -3)
            )
            successes += 1
        end

        if successes > 0 then
            return `Successfully teleported {successes} \z
                character{(successes == 1 and "") or "s"} to {Destination}!`
        else
            return `Unable to teleport {#Targets} \z
                character{(#Targets == 1 and "") or "s"} to {Destination}`
        end
    end
}

return command