---All configuration for the 7.62 x 39mm 20-round Box
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Soviet762)
config.Capacity = 20

config.Type = "Box"

return config