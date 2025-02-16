--This is the main script which strats the main thread for running the game
local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local ArmoryHandler = require(ServerScripts.Armories)
local BreakageHandler = require(ServerScripts.Breakage)
local CharacterHandler = require(ServerScripts.Characters)
local ChatHandler = require(ServerScripts.Chat)
local CollisionHandler = require(ServerScripts.Collisions)
local EnvironmentHandler = require(ServerScripts.Environment)
local HomeHandler = require(ServerScripts.Homes)
local InteractionHandler = require(ServerScripts.Interactions)
local JobHandler = require(ServerScripts.Jobs)
local MarketplaceHandler = require(ServerScripts.Marketplace)
local SecurityHandler = require(ServerScripts.Security)
local ServiceHandler = require(ServerScripts.Services)
local TeamHandler = require(ServerScripts.Teams)

if SecurityHandler.IntegrityCheck() then
    print(`{script}: Integrity check passed.`)
end

if SecurityHandler.ClothingConflicts() then
    print(`{script}: No clothing conflicts found.`)
end

BreakageHandler.Setup()
ChatHandler.Setup()
CollisionHandler.Setup()
EnvironmentHandler.Setup()
InteractionHandler.Setup()
MarketplaceService.ProcessReceipt = MarketplaceHandler.ProcessReceipt
SecurityHandler.PlantHoneypots()
ServiceHandler.Setup()
TeamHandler.Setup()
HomeHandler.Load("North")