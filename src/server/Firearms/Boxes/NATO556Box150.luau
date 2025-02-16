---All configuration for the 5.56 x 45mm 150-round Box
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.NATO556)
config.Capacity = 150

config.Type = "Box"

return config