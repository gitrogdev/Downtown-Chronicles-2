--The /unmute command used for unmuting a player's voice chat
local command = {
    PrimaryAlias = "/unmute";
    
    PermissionLevel = 3;
    ArgSequence = {
        "Player"
    };
    Execute = function(Player: Player, Mute: Player)
        local AudioInput: AudioDeviceInput = Mute:FindFirstChildOfClass(
            "AudioDeviceInput"
        )
        if AudioInput then
            Mute:SetAttribute("Muted", false)
            local Humanoid: Humanoid = Mute.Character
                and Mute.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                AudioInput.Muted = false
            end
            return `Successfully unmuted {Mute}.`
        else
            return `{Mute} does not have voice chat, and can not be unmuted.`
        end
    end
}

return command