--This script contains all configuration related to character customization
local config = {}

for i, Child in ipairs(script:GetChildren()) do
    config[Child.Name] = require(Child)
end

return config