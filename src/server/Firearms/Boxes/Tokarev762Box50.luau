---All configuration for the 7.62 x 25mm Tokarev 50-round Box
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Tokarev762)
config.Capacity = 50

config.Type = "Box"

return config