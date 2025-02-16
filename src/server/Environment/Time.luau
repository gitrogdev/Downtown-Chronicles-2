--This script handles the passage of time
local Lighting = game:GetService("Lighting")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local module = {}

module.TimeFunctions = {}

---Updates the ClockTime and lighting based on the current time
module.Count = function()
    if Lighting:GetAttribute("NoTime") then
        return
    end

    task.spawn(function()
        module.Counting = true
        while module.Counting do
            local currentTime = module.GetTime()

            Lighting.TimeOfDay =
                `{currentTime.hour}:{currentTime.min}:{currentTime.sec}`

            if not Lighting:GetAttribute("Flashing") then
                local brightness = (12 - math.abs(12 - Lighting.ClockTime)) * 20
                Lighting.OutdoorAmbient = Color3.fromRGB(
                    brightness,
                    brightness,
                    brightness
                )
                Lighting.Brightness = 1 -
                    (math.abs(12 - Lighting.ClockTime) * 0.1)
            end

            if currentTime.sec == 0 then
                for i, funcData in ipairs(module.TimeFunctions) do
                    if currentTime.min % funcData.Frequency == 0 then
                        task.spawn(function()
                            funcData.Function(currentTime)
                        end)
                    end
                end
            end

            task.wait(1)
        end
    end)
end

---Get the current time in the GMT-9 timezone (Bloxell's geographic location)
---@return table
module.GetTime = function()
    local currentTime = os.date("!*t")
    currentTime.hour = Util.EnforceRange(currentTime.hour - 9, 0, 23)

    return currentTime
end

return module