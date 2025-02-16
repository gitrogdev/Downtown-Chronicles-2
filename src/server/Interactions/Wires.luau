--Handle damage-dealing wires
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local SoundIds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local DeathHandler = require(ServerScripts.Deaths)
local Util = require(ServerScripts.Util)

local module = {}

---Set up a barbed wire part
---@param Barb BasePart The part to do barbed wire damage
---@return RBXScriptSignal
module.BarbedWire = function(Barb: BasePart)
    return Barb.Touched:Connect(function(Part: BasePart)
        local Humanoid = Part.Parent:FindFirstChildOfClass("Humanoid")
        if Humanoid and Humanoid.Health > 0 then
            DeathHandler.Splatter(Humanoid, 10, Barb.Position)
            DeathHandler.TakeDamage(Humanoid, 10, "Barbed wire")
            local WireSound = Util.CreateInstance("Sound", {
                Parent = Barb;
                RollOffMaxDistance = 50;
                SoundId = SoundIds.BarbedWire;
            })

            WireSound.Ended:Once(function()
                WireSound:Destroy()
            end)

            WireSound:Play()
        end
    end)
end

---Set up a razor wire part
---@param Razor BasePart The part to do razor wire damage
---@return RBXScriptSignal
module.RazorWire = function(Razor: BasePart)
    return Razor.Touched:Connect(function(Part: BasePart)
        local Humanoid = Part.Parent:FindFirstChildOfClass("Humanoid")
        if Humanoid and Humanoid.Health > 0 then
            DeathHandler.Splatter(Humanoid, 25, Razor.Position)
            DeathHandler.TakeDamage(Humanoid, 25, "Razor wire")
            local WireSound = Util.CreateInstance("Sound", {
                Parent = Razor;
                RollOffMaxDistance = 50;
                SoundId = SoundIds.BarbedWire;
            })

            WireSound.Ended:Once(function()
                WireSound:Destroy()
            end)

            WireSound:Play()
        end
    end)
end

return module