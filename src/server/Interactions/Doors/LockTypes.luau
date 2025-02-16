--All lock behaviors for doors
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local HomeHandler = require(ServerScripts.Homes)

local module = {}

---Determines whether a door can be opened based on an apartment's owner
---@param Model Instance The door to be opened
---@param Player Player The Player opening the door
---@return boolean
module.Apartment = function(Model: Instance, Player: Player)
    return HomeHandler.HasAccess(
        Player:GetAttribute("ID"),
        Model.Parent:GetAttribute("Building"),
        Model.Parent:GetAttribute("Apartment")
    )
end

---Determines whether a door can be opened based on residence in a building
---@param Model Instance The door to be opened
---@param Player Player The Player opening the door
---@return boolean
module.ApartmentBuilding = function(Model: Instance, Player: Player)
    return HomeHandler.LivesIn(Player, Model:GetAttribute("Building"))
end

---Determines whether a door can be opened based on the state of emergency
---@param Model Instance The door to be opened
---@param Player Player The Player opening the door
---@return boolean
module.Emergency = function(Model: Instance, Player: Player)
    return ReplicatedStorage:GetAttribute("Emergency") and
        Model:GetAttribute("Occupation") == Player:GetAttribute("Occupation")
end

---Determines whether a door can be opened based on the player's occupation
---@param Model Instance The door to be opened
---@param Player Player The Player opening the door
---@return boolean
module.Occupation = function(Model: Instance, Player: Player)
    return Model:GetAttribute("Occupation") == Player:GetAttribute("Occupation")
end

---Determines whether a door can be opened based on status as a police officer
---@param Model Instance The door to be opened
---@param Player Player The Player opening the door
---@return boolean
module.Police = function(Model: Instance, Player: Player)
    return Player:GetAttribute("Occupation") == "MIA" and ((
            Model:GetAttribute("Division") and (
                Player:GetAttribute("PoliceDivision")
                == Model:GetAttribute("Division")
                or Player:GetAttribute("PoliceRank") > 5
        )) or not Model:GetAttribute("Division"))
end

---Determines whether a door can be opened based on TeamColor
---@param Model Instance The door to be opened
---@param Player Player The Player opening the door
---@return boolean
module.Team = function(Model: Instance, Player: Player)
    return Model:GetAttribute("Team") == Player.TeamColor
end

return module