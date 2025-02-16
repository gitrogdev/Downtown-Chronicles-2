---All configuration for the 5.45 x 39mm 30-round Box
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Soviet545)
config.Capacity = 30

config.Type = "Box"

return config