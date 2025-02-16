--This script handles the properties of all Roblox services
local ServiceConfig = require(script.Config)

local module = {}

---Sets the properties of all Roblox services to the desired values
module.Setup = function()
    for service, properties in pairs(ServiceConfig) do
        local Service = game:GetService(service)
        for property, value in pairs(properties) do
            Service[property] = value
        end
    end
end

return module