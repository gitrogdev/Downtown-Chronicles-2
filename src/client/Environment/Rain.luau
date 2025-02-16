--This script handles all aspects of the client's display of rain
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local RainHandler = require(ReplicatedScripts.Rain)
local Util = require(ReplicatedScripts.Util)

local UIStorage = ReplicatedStorage.UserInterface
local RainParticles = UIStorage.RainParticles:Clone()

local Camera = workspace.CurrentCamera
local Terrain = workspace.Terrain
local Clouds = Terrain:WaitForChild("Clouds")

local listening, raining, loaded

local module = {}

---Starts monitoring the level of cloud cover to determine when to generate rain
module.Listen = function()
    if listening then
        return
    end
    listening = true

    Clouds:GetPropertyChangedSignal("Cover"):Connect(function()
        if Clouds.Cover >= 0.9 and Clouds.Density >= 0.1 then
            if not raining then
                print(`{script}.Listen: Starting rain.`)
                raining = true
                if not loaded then
                    RainHandler:Enable()
                else
                    RainHandler:Enable(TweenInfo.new(math.random(10,30)))
                end
            end
        
            RainHandler:SetIntensityRatio(Clouds.Density + (Clouds.Cover - 0.9))
        elseif raining then
            print(`{script}.Listen: Stopping rain.`)
            raining = false
            RainHandler:Disable(TweenInfo.new(math.random(10,30)))
        end
        loaded = true
    end)
end

return module