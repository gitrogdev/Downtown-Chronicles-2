---All configuration for the 9 x 19mm 50-round Box
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Parabellum9)
config.Capacity = 50

config.Type = "Box"

return config