--This script handles all aspects of the client's interaction with thunder
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Util = require(ReplicatedScripts.Util)

local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local module = {}

---Starts monitoring for lightning to determine when to play thunder sounds
---@param Player Player The Player to calculate the distance from
---@param Character Model The character to wait for the death of
module.Listen = function(Player: Player, Character: Model)
    local Humanoid = Character:WaitForChild("Humanoid")

    local ListenTo
    ListenTo = workspace.ChildAdded:Connect(function(Child: Instance)
        if Child:GetAttribute("Lightning") then
            local origin = Child:GetAttribute("Origin")
            local distance = Player:DistanceFromCharacter(
                Child:GetAttribute("Target")
            )
            local soundDelay = distance / 1128

            if distance == 0 then
                return ListenTo:Disconnect()
            end

            local ThunderPart = Util.CreateInstance("Part", {
                Anchored = true;
                CanCollide = false;
                CanQuery = false;
                Massless = true;
                Position = origin;
                Parent = workspace;
                Size = Vector3.new(0.1, 0.1, 0.1);
                Transparency = 1;
            })

            local ThunderSound = Util.CreateInstance("Sound", {
                Parent = ThunderPart;
                PlaybackSpeed = math.random(80, 120) / 100;
                RollOffMinDistance = origin.Y / 2;
                SoundId = (soundDelay < 1 and Sounds.ThunderClose)
                    or Sounds.ThunderDistant;
                Volume = 5;
            })
            ThunderSound.Ended:Connect(function()
                ThunderPart:Destroy()
            end)

            print(
                `{script}.Listen: Thunder originating at {origin} \z
                (Distance from character: {Util.Round(distance, 2)} studs)! \z
                {Util.Round(soundDelay, 1)} second delay until sound!`
            )
            task.wait(soundDelay)
            ThunderSound:Play()
        end
    end)

    Humanoid.Died:Once(function()
        ListenTo:Disconnect()
    end)
end

return module