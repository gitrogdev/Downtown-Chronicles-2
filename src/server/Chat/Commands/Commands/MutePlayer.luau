--The /mute command used for muting a player's voice chat
local command = {
    PrimaryAlias = "/mute";
    
    PermissionLevel = 3;
    ArgSequence = {
        "Player"
    };
    Execute = function(Player: Player, Mute: Player)
        local AudioInput: AudioDeviceInput = Mute:FindFirstChildOfClass(
            "AudioDeviceInput"
        )
        if AudioInput then
            AudioInput.Muted = true
            Mute:SetAttribute("Muted", true)
            return `Successfully muted {Mute}.`
        else
            return `{Mute} does not have voice chat, and can not be muted.`
        end
    end
}

return command