--All configuration for the Ministry of Internal Affairs plainclothes locker
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local SendNotification = ReplicatedCommunication.SendNotification

local ServerScripts = ServerScriptService.ServerScripts
local JobHandler = require(ServerScripts.Jobs)
local MIAHandler = require(ServerScripts.Jobs.MIA)

local config = {}

---Clock a player in for the MIA job
---@param Player Player The Player clocking in
config.In = function(Player: Player)
    Player:SetAttribute("Working", true)
    MIAHandler.Start(Player)
    SendNotification:FireClient(Player, {
        Title = "Plainclothes Patrol";
        Text = "You are now on plainclothes duty.";
        Duration = 10;
    })
end

---Clock a player out for the Guardsman job
---@param Player Player The Player clocking out
config.Out = function(Player: Player)
    Player:SetAttribute("Working", false)
    JobHandler.Paycheck(Player, "MIA")
    SendNotification:FireClient(Player, {
        Title = "Plainclothes Patrol";
        Text = "You have ended your plainclothes duty.";
        Duration = 10;
    })
end

config.PromptText = "Plainclothes Patrol"

---Checks if a player can open the locker
---@param Player Player The Player attempting to open the locker
---@return boolean
config.Restriction = function(Player: Player)
    return Player:GetAttribute("Occupation") == "MIA" and (
        Player:GetAttribute("PoliceDivision") == "Investigative"
        or Player:GetAttribute("PoliceDivision") == "Tax"
        or Player:GetAttribute("PoliceRank") > 5
    )
end

return config