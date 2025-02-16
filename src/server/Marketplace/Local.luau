--Handles the "Local" pass
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local CitizenshipHandler = require(ServerScripts.Citizenship)
local SaveAttributes = require(ServerScripts.Characters.SaveAttributes)
local TeamHandler = require(ServerScripts.Teams)

local module = {}

---Handles the purchase of a new character slot
---@param Player Player The Player that purchased a character slot
module.Bought = function(Player: Player)
    if Player:GetAttribute("Citizenship") == "Tourist" then
        Player:SetAttribute("Citizenship", "North") --RETURN TO: let them choose

        if Player:GetAttribute("Shirt") == SaveAttributes.Shirt then
            Player:SetAttribute("Shirt", "CITIZEN_DEFAULT_SHIRT")
        end

        if Player:GetAttribute("Pants") == SaveAttributes.Pants then
            Player:SetAttribute("Pants", "CITIZEN_DEFAULT_PANTS")
        end

        TeamHandler.Join(Player, CitizenshipHandler.ToTeam(
            Player:GetAttribute("Citizenship")
        ))
    end
end

return module