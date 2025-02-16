--All configuration for the national guard locker
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local JobHandler = require(ServerScripts.Jobs)
local GuardsmanHandler = require(ServerScripts.Jobs.Guardsman)
local TeamHandler = require(ServerScripts.Teams)

local config = {}

config.Clothing = {
    Shirt = "NBAFTop";
    Pants = "NBAFBottom";
}

---Clock a player in for the Guardsman job
---@param Player Player The Player clocking in
config.In = function(Player: Player)
    Player:SetAttribute("Working", true)
    GuardsmanHandler.Start(Player)
    TeamHandler.Join(Player, "National Guard")
end

---Clock a player out for the Guardsman job
---@param Player Player The Player clocking out
config.Out = function(Player: Player)
    Player:SetAttribute("Working", false)
    JobHandler.Paycheck(Player, "Guardsman")
    TeamHandler.Join(Player, "Northern Citizen")
end

---Checks if a player can open the locker
---@param Player Player The Player attempting to open the locker
---@return boolean
config.Restriction = function(Player: Player)
    return Player:GetAttribute("Occupation") == "Guardsman"
end

return config