--This script handles all processing of names on the server-side during character customization
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local module = {}

---Validates a given birthday
---@param day number The day of birth
---@param month number The month of birth
---@param year number The year of birth
---@return boolean
module.Validate = function(day: number, month: number, year: number)
    if not (
        typeof(day) == "number" and day == math.floor(day) and day > 0
        and typeof(month) == "number" and month == math.floor(month) and month > 0
        and typeof(year) == "number" and year == math.floor(year) and year > 0
    ) then
        return warn(`{script}.Validate: Dates must contain positive integers!`)
    end

    if not (month < 13) then
        return warn(`{script}.Validate: Month out of range! \z
            Expected integer 1-12, got {month}!`
        )
    end

    if not (day <= Util.DaysPerMonth[month]) then
        return warn(`{script}.Validate: Day out of range! \z
            Expected integer 1-{Util.DaysPerMonth[month]}, got {day}!`
        )
    end

    local currentTime = os.date("!*t")
    if not
        (year <= currentTime.year - 13
        and year >= currentTime.year - 100)
    then
        return warn(`{script}.Validate: Year out of range! \z
        Expected integer {currentTime.year - 100}-{currentTime.year - 13}, \z
        got {year}`
    )
    end

    return true
end

return module