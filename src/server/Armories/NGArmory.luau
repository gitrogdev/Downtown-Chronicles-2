--Contains all configuration for the national guard armory
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = {}

module.Name = "National Guard Armory"

module.Loadouts = {
    {
        Weapons = {
            "MPiKM";
        };
        Feeds = {
            {
                Name = "AKMMag30";
                Count = 2;
            }
        };
    };
    {
        Weapons = {
            "MPiKMS";
        };
        Feeds = {
            {
                Name = "AKMMag30";
                Count = 2;
            }
        };
    };
    {
        Weapons = {
            "MPiKMK";
        };
        Feeds = {
            {
                Name = "AKMMag30";
                Count = 2;
            }
        };
    };
}

---Checks if a player can check out the weapons
---@param Player Player The Player to check
---@return boolean
module.Restrict = function(Player: Player)
    return ReplicatedStorage:GetAttribute("Emergency")
        and Player:GetAttribute("Occupation") == "Guardsman"
        and Player:GetAttribute("Working")
end

return module