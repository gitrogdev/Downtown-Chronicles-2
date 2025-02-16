--All configuration related to jobs
local config = {}

for i, Child in ipairs(script:GetChildren()) do
    config[Child.Name] = require(Child)
end

return config