--Handles all traffic light patterns on the server
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local BULB_COLORS = {
    Green = Color3.new(0, 1, 0);
    Yellow = Color3.new(1, 1, 0);
    Red = Color3.new(1, 0, 0);
}

local cycle = 0
local status
local TrafficLights = {}

local module = {}

---Sets up a new traffic light
---@param Light Model The traffic light model to set up
---@return table
module.new = function(Light: Model)
    local Bulbs = {
        Green = Light:FindFirstChild("GreenBulb");
        Yellow = Light:FindFirstChild("YellowBulb");
        Red = Light:FindFirstChild("RedBulb");
    }

    if not (Bulbs.Green and Bulbs.Yellow and Bulbs.Red) then
        return warn(
            `{script}.new: {Light:GetFullName()} is not a complete traffic \z
            light! (Green bulb: {Bulbs.Green:GetFullName()}, Yellow bulb: \z
            {Bulbs.Yellow:GetFullName()}, Red bulb: {Bulbs.Red:GetFullName()})`
        )
    end

    local orientation = Light.PrimaryPart and Light.PrimaryPart.Orientation.Y
    if orientation == 0 or orientation == 180 then
        orientation = "NS"
    elseif orientation == -90 or orientation == 90 then
        orientation = "EW"
    else
        return warn(
            `{script}.new: {Light:GetFullName()} has an invalid orientation: \z
            {(not Light.PrimaryPart and "No PrimaryPart found") or orientation}`
        )
    end

    local TrafficLight = {
        Bulbs = Bulbs;
        Lights = {};
        Opposite = orientation == "NS" and "EW" or "NS";
        Orientation = orientation;
    }

    for color, Bulb in pairs(Bulbs) do
        TrafficLight.Lights[color] = Bulb:FindFirstChildOfClass("PointLight")
            or Util.CreateInstance("PointLight", {
                Brightness = 2;
                Color = BULB_COLORS[color];
                Name = `{color}Light`;
                Parent = Bulb;
            })
    end

    module.UpdateLight(TrafficLight)
    table.insert(TrafficLights, TrafficLight)

    print(`{script}.new: Loaded traffic light {Light:GetFullName()}.`)
    return TrafficLight
end

---Begins a traffic light cycle
module.Cycle = function()
    cycle += 1
    local instance = cycle

    local i = 0
    print(`{script}.Cycle: Starting traffic cycle with instance {instance}.`)
    while cycle == instance do
        status = i % 2 == 0 and "NS" or "EW"
        print(
            `{script}.Cycle.{instance}: Allowing \z
            {status == "NS" and "north-south" or "east-west"} traffic.`
        )
        module.UpdateLights()

        task.wait(60)
        
        status = "SWITCH"
        print(`{script}.Cycle.{instance}: Switching traffic direction.`)
        module.UpdateLights()

        task.wait(5)
        i += 1
    end
end

---Update the lighting of an individual traffic light
---@param TrafficLight table The traffic light to update
module.UpdateLight = function(TrafficLight: table)
    TrafficLight.Bulbs.Green.Material =
        status == TrafficLight.Orientation and Enum.Material.Neon
        or Enum.Material.Glass
    TrafficLight.Lights.Green.Enabled = status == TrafficLight.Orientation

    TrafficLight.Bulbs.Yellow.Material =
        status == "SWITCH" and Enum.Material.Neon
        or Enum.Material.Glass
    TrafficLight.Lights.Yellow.Enabled = status == "SWITCH"

    TrafficLight.Bulbs.Red.Material =
        status == TrafficLight.Opposite and Enum.Material.Neon
        or Enum.Material.Glass
    TrafficLight.Lights.Red.Enabled = status == TrafficLight.Opposite
end

---Updates the status of all traffic lights
module.UpdateLights = function()
    for i, TrafficLight in ipairs(TrafficLights) do
        module.UpdateLight(TrafficLight)
    end
end

return module