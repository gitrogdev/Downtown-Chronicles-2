---All configuration for the .25g Airsoft Pellet 5000-round Bottle
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local config = {}

config.Caliber = require(CaliberConfigs.Airsoft25)
config.Capacity = 5000

config.Type = "Box"

return config