---All configuration for the 82-BM-37 Mortar
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local CaliberConfigs = ServerConfig.Calibers

local PartStorage = ServerStorage.Parts

local config = {}

config.Caliber = require(CaliberConfigs.Mortar82)

config.MuzzleVelocity = 350

config.PlaceModel = PartStorage.PlacedM37

return config