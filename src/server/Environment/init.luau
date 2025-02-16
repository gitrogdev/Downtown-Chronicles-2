--All aspects of the game's "environment" such as the background, time, etc.
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local TimeHandler = require(script.Time)
local TrafficHandler = require(script.Traffic)
local WeatherHandler = require(script.Weather)

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local ChurchBell =  workspace.Map:FindFirstChild("Church")
    and workspace.Map.Church:FindFirstChild("ChurchBell")

local module = {}

---Loads a street light
---@param Light Instance The street light to load
module.NewStreetLight = function(Light: Instance)
    local SpotLight = Light:FindFirstChildOfClass("SpotLight")
        or Util.CreateInstance("SpotLight", {
            Color = Light.Color;
            Face = Enum.NormalId.Bottom;
            Parent = Light;
            Range = 25;
        })

    local updateLight = function(currentTime: table)
        if currentTime.hour < 7 or currentTime.hour > 17 then
            Light.Material = Enum.Material.Neon
            SpotLight.Enabled = true
        else
            Light.Material = Enum.Material.Glass
            SpotLight.Enabled = false
        end
    end

    table.insert(TimeHandler.TimeFunctions, {
        Frequency = 60,
        Function = updateLight
    })
    updateLight(TimeHandler.GetTime())
    print(`{script}.Setup: Loaded street light {Light:GetFullName()}.`)
end

---Sets up all environmental effects
module.Setup = function()
    TimeHandler.Count()
    WeatherHandler.Setup()

    if ChurchBell then
        table.insert(TimeHandler.TimeFunctions, {
            Frequency = 60,
            Function = function(currentTime: table)
                local BellMount = ChurchBell:WaitForChild("Mount")
                local Clapper = ChurchBell:WaitForChild("Clapper")

                local BellServo = BellMount:WaitForChild("BellServo")
                local BellSound = BellMount:WaitForChild("BellSound")

                BellMount.CanCollide = false
                Clapper.CanCollide = false

                local oclock = currentTime.hour
                if oclock > 12 then
                    oclock -= 12
                elseif oclock == 0 then
                    oclock += 12
                end

                for i =1 , oclock do
                    BellServo.TargetAngle = 18 * ((i % 2 == 1 and -1) or 1)
                    while
                        math.abs(
                            BellServo.TargetAngle - BellServo.CurrentAngle
                        ) > 1
                    do
                        task.wait()
                    end
                    BellSound:Play()
                end
                BellServo.TargetAngle = 0

                while
                    math.abs(BellServo.TargetAngle - BellServo.CurrentAngle) > 1
                do
                    task.wait()
                end
                
                BellMount.CanCollide = true
                Clapper.CanCollide = true
            end
        })
    end

    task.spawn(TrafficHandler.Cycle)

    for i, Light in ipairs(CollectionService:GetTagged("StreetLight")) do
        module.NewStreetLight(Light)
    end
    CollectionService:GetInstanceAddedSignal("StreetLight"):Connect(
        module.NewStreetLight
    )

    for i, Light in ipairs(CollectionService:GetTagged("TrafficLight")) do
        TrafficHandler.new(Light)
    end
    CollectionService:GetInstanceAddedSignal("TrafficLight"):Connect(
        TrafficHandler.new
    )
end

return module