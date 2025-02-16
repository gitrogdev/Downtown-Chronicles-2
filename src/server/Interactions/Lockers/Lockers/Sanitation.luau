--All configuration for the sanitation services locker
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local JobHandler = require(ServerScripts.Jobs)

local config = {}

config.Clothing = {
    Shirt = "SanitationTop";
    Pants = "SanitationBottom";
}

---Clock a player in for the Guardsman job
---@param Player Player The Player clocking in
config.In = function(Player: Player)
    Player:SetAttribute("Working", true)
end

---Clock a player out for the Guardsman job
---@param Player Player The Player clocking out
config.Out = function(Player: Player)
    Player:SetAttribute("Working", false)
    JobHandler.Paycheck(Player, "Sanitation")
end

---Checks if a player can open the locker
---@param Player Player The Player attempting to open the locker
---@return boolean
config.Restriction = function(Player: Player)
    return Player:GetAttribute("Occupation") == "Sanitation"
end

return config