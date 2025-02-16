--All configuration for the Ministry of Internal Affairs locker
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local PoliceConfig = require(ReplicatedConfig.Police)

local ServerScripts = ServerScriptService.ServerScripts
local JobHandler = require(ServerScripts.Jobs)
local MIAHandler = require(ServerScripts.Jobs.MIA)
local TeamHandler = require(ServerScripts.Teams)

local config = {}

config.Clothing = {
    Shirt = function(Player: Player): string
        return PoliceConfig.Uniforms[Player:GetAttribute("PoliceRank")].Shirt;
    end;
    Pants = function(Player: Player): string
        return PoliceConfig.Uniforms[Player:GetAttribute("PoliceRank")].Pants;
    end;
    Accessories = function(Player: Player): table
        return PoliceConfig.Uniforms[
            Player:GetAttribute("PoliceRank")
        ].Accessories or {};
    end;
}

---Clock a player in for the Guardsman job
---@param Player Player The Player clocking in
config.In = function(Player: Player)
    Player:SetAttribute("Working", true)
    MIAHandler.Start(Player)
    TeamHandler.Join(Player, "Ministry of Internal Affairs")
end

---Clock a player out for the Guardsman job
---@param Player Player The Player clocking out
config.Out = function(Player: Player)
    Player:SetAttribute("Working", false)
    JobHandler.Paycheck(Player, "MIA")
    TeamHandler.Join(Player, "Northern Citizen")
end

---Checks if a player can open the locker
---@param Player Player The Player attempting to open the locker
---@return boolean
config.Restriction = function(Player: Player)
    return Player:GetAttribute("Occupation") == "MIA"
end

return config