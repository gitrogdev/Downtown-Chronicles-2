--The /fillfeed command for filling feed parts for firearms
local command = {
    PrimaryAlias = "/fillfeed";
    SecondaryAlias = "/fillmag";
    
    PermissionLevel = 5;
    ArgSequence = {};
    RequireAlive = true;
    Execute = function(Player: Player)
        local Feed = Player.Character:FindFirstChildOfClass("Tool")
        if not Feed then
            return "Must have a feed part equipped to be filled!"
        end

        if not
            (Feed:GetAttribute("MaxCapacity") and Feed:GetAttribute("Caliber"))
        then
            return `Equipped item {Feed:GetAttribute("FileName")} is not a \z
                valid feed part!`
        end

        local max = Feed:GetAttribute("MaxCapacity")
        local capacity = Feed:GetAttribute("Capacity") or 0
        local loaded = max - capacity
        Feed:SetAttribute("Capacity", max)
        return `Successfully loaded {loaded} round{loaded == 1 and "" or "s"} \z
            into the equipped {Feed:GetAttribute("DisplayName")
            or Feed:GetAttribute("FileName")}.`
    end
}

return command