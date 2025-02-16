--This script handles weather effects
local Lighting = game:GetService("Lighting")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local ServerScripts = ServerScriptService.ServerScripts
local EvLightning = require(ServerScripts.EvLightning)
local ExplosionHandler = require(ServerScripts.Explosions)
local Util = require(ServerScripts.Util)

local Terrain = workspace.Terrain
local Clouds = Terrain:FindFirstChildOfClass("Clouds")
    or Util.CreateInstance("Clouds", {
        Parent = Terrain;
    })

local storming = false

local module = {}

---Generates a random weather state and begins shifting into it
module.Generate = function()
    local ShiftTween = TweenService:Create(Clouds,
        TweenInfo.new(math.random(900, 7200)),
        {
            Cover = math.random(1, 100) / 100;
            Density = math.random(1, 100) / 100;
        }
    )

    local manualInterface = Clouds:GetAttributeChangedSignal("Manual"):Once(
        function()
            if Clouds:GetAttribute("Manual") then
                ShiftTween:Cancel()

                Clouds:GetAttributeChangedSignal("Manual"):Once(function()
                    if not Clouds:GetAttribute("Manual") then
                        module.Generate()
                    end
                end)
            end
        end
    )

    ShiftTween.Completed:Connect(function()
        task.wait(math.random(60, 1500))
        manualInterface:Disconnect()
        module.Generate()
    end)

    
    ShiftTween:Play()
end

---Calls a lightning strike
---@param origin Vector3 The origin position of the lightning bolt (or random)
---@param position Vector3 The strike position of the lightning bolt (or random)
module.LightningStrike = function(origin: Vector3, position: Vector3)
    origin = origin or Vector3.new(
        math.random(Util.Boundaries.Min.X, Util.Boundaries.Max.X),
        3200,
        math.random(Util.Boundaries.Min.Z, Util.Boundaries.Max.Z)
    )

    if not position then
        local direction = Vector3.new(
            math.random(-500, 500),
            -origin.Y * 2,
            math.random(-500, 500)
        )
        local Hit = workspace:Raycast(origin, direction)

        if Hit and Hit.Position then
            position = Hit.Position
        else
            position = origin + direction
            position = Vector3.new(
                position.X,
                workspace.FallenPartsDestroyHeight,
                position.Z
            )
        end
    end

    if not Lighting:GetAttribute("Flashing") then
        local originalAmbient = Lighting.OutdoorAmbient
        local originalBrightness = Lighting.Brightness
        Lighting:SetAttribute("Flashing", true)

        local FlashTween = TweenService:Create(Lighting, TweenInfo.new(0.1), {
            Brightness = 2;
            OutdoorAmbient = Color3.new(1, 1, 1)
        })
        local RevertTween = TweenService:Create(Lighting, TweenInfo.new(0.1), {
            Brightness = originalBrightness;
            OutdoorAmbient = originalAmbient;
        })
        
        FlashTween.Completed:Connect(function()
            RevertTween:Play()
        end)
        RevertTween.Completed:Connect(function()
            Lighting:SetAttribute("Flashing", false)
        end)

        FlashTween:Play()
    end

    local LightningBolt = EvLightning.new(origin, position, {
        decay = 0.2;
    })

    LightningBolt:Draw()
    LightningBolt.model:SetAttribute("Lightning", true)
    LightningBolt.model:SetAttribute("Origin", origin)
    LightningBolt.model:SetAttribute("Target", position)

    ExplosionHandler.new("Default", position, {
        ExplosionProperties = {
            BlastRadius = 10;
        };
        MaxDamage = 25;
        Source = "Lightning strike";
    })
    print(`{script}.LightningStrike: Striking position {position}`)
end

---Begins updating and running cloud and weather effects
module.Setup = function()
    Clouds = Clouds or Util.CreateInstance("Clouds", {
        Parent = Terrain
    })

    Clouds.Cover = math.random(1, 100)/100
    Clouds.Density = math.random(1, 100)/100

    Clouds:GetPropertyChangedSignal("Cover"):Connect(function()
        if storming then
            return
        end

        if Clouds.Cover >= 0.9 and Clouds.Density >= 0.7 then
            storming = true
            print(`{script}.Setup: Storming!`)

            while Clouds.Cover >= 0.9 and Clouds.Density >= 0.7 do
                local strikeChance = (Clouds.Cover - 0.9) + (Clouds.Density - 0.7)
                local strikeHit = math.random(1, 100) / 100
                if strikeHit <= strikeChance then
                    module.LightningStrike()
                else
                    print(`{script}.Setup: \z
                        {Util.Round(strikeChance * 100, 2)}% chance to strike, \z
                        got {strikeHit}`
                    )
                end

                task.wait(
                    10 - ((Clouds.Cover - 0.9) * 10) -
                    ((Clouds.Density - 0.7) * 10)
                )
            end
            
            storming = false
            print(`{script}.Setup: Stopping storm!`)
        end
    end)

    module.Generate()
end

return module