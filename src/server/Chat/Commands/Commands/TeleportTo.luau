--The /tpto (/to) command used for teleporting to a player
local command = {
    PrimaryAlias = "/tpto";
    SecondaryAlias = "/to";
    
    PermissionLevel = 1;
    ArgSequence = {
        "Character"
    };
    RequireAlive = true;
    Execute = function(Player: Player, Target: Model)
        local Humanoid: Humanoid = Player.Character:FindFirstChildOfClass(
            "Humanoid"
        )
        local RootPart: Part = Humanoid and Humanoid.RootPart
        if not RootPart then
            return `No root part found in character!`
        end

        local TargetPart = Target:FindFirstChild("HumanoidRootPart")
        if not TargetPart then
           return `No root part found for target character {Target}!`
        end

        Humanoid.Sit = false
        if Humanoid.SeatPart then
            Humanoid:GetPropertyChangedSignal("SeatPart"):Wait()
        end
        RootPart.CFrame = TargetPart.CFrame:ToWorldSpace(CFrame.new(0, 0, -3))
        return `Successfully teleported to {Target}.`
    end
}

return command