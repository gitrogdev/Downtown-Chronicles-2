--Handles the distribution of free drinks from the Laki Club
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local InventoryHandler = require(ServerScripts.Inventory)

local module = {}

---Checks if a player can claim the reward
---@param Player Player The Player to check
---@return boolean
module.CanClaim = function(Player: Player)
    return Player:GetAttribute("LakiDrink") == true
end

---Awards the player a free drink
---@param Player Player The Player to award the drink to
module.Claim = function(Player: Player)
    Player:SetAttribute("LakiDrink", false)
    InventoryHandler.Add(Player, InventoryHandler.Items.new(
        "ColaBottle",
        "Free drink from Laki Club"
    ), nil, true)
end

return module