--Handles voice chat on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoiceChatService = game:GetService("VoiceChatService")

local Player: Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local Util = require(ReplicatedScripts.Util)

local CanTalk = ReplicatedCommunication.CanTalk

---Check whether the player can use voice chat
---@return boolean
local function canTalk(): boolean
    local success, enabled = pcall(
        VoiceChatService.IsVoiceEnabledForUserIdAsync, VoiceChatService,
        Player.UserId
    )

    return success and enabled
end
CanTalk.OnClientInvoke = canTalk

local module = {}

module.CanTalk = canTalk

---Create the listener for a new character
---@return AudioListener
module.Setup = function(): AudioListener
    local Listener: AudioListener = Util.CreateInstance("AudioListener", {
        Parent = Player.Character:WaitForChild("Head");
    })
    
    local Output: AudioDeviceOutput = Util.CreateInstance("AudioDeviceOutput", {
        Parent = Listener;
    })
    
    Util.CreateInstance("Wire", {
        Parent = Listener;
        SourceInstance = Listener;
        TargetInstance = Output;
    })

    for i, Child in ipairs(Player.Character:GetChildren()) do
        if Child:IsA("AudioEmitter") then
            Child:SetDistanceAttenuation({[0] = 0})
        end
    end

    Player.Character.ChildAdded:Connect(function(Child: Instance)
        if Child:IsA("AudioEmitter") then
            Child:SetDistanceAttenuation({[0] = 0})
        end
    end)

    return Listener
end

return module