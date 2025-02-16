local ReplicatedStorage = game:GetService("ReplicatedStorage")
--Contains all configuration for the national guard armory
local module = {}

module.Name = "Police Armory"

module.Loadouts = {
    {
        Weapons = {
            "MP443";
        };
        Equipment = {
            "HandcuffKey";
            "Handcuffs";
            "ShoulderRadio";
        };
        Feeds = {
            {
                Name = "MP443Mag18";
                Count = 2;
            }
        };
    };
}

module.ConditionalLoadouts = {
    {
        Condition = function(Player: Player): boolean
            return Player:GetAttribute("PoliceRank") == 9
        end;
        Loadouts = {
            {
                Weapons = {
                    "Taurus605";
                };
                Equipment = {
                    "Magnum357Box50";
                };
            };
        }
    };
    {
        Condition = function(Player: Player): boolean
            return ReplicatedStorage:GetAttribute(
                `{Player:GetAttribute("PoliceDivision")}TacticalDeployment`
            ) == true
        end;
        Loadouts = {
            {
                Weapons = {
                    "MPiK74";
                };
                Equipment = {
                    "HandcuffKey";
                    "Handcuffs";
                    "ShoulderRadio";
                };
                Feeds = {
                    {
                        Name = "AK74Mag30";
                        Count = 2;
                    }
                };
            };
            {
                Weapons = {
                    "MPiK74K";
                };
                Equipment = {
                    "HandcuffKey";
                    "Handcuffs";
                    "ShoulderRadio";
                };
                Feeds = {
                    {
                        Name = "AK74Mag30";
                        Count = 2;
                    }
                };
            };
            {
                Weapons = {
                    "MPiK74NK";
                };
                Equipment = {
                    "HandcuffKey";
                    "Handcuffs";
                    "ShoulderRadio";
                };
                Feeds = {
                    {
                        Name = "AK74Mag30";
                        Count = 2;
                    }
                };
            };
        }
    };
    {
        Condition = function(Player: Player): boolean
            return Player:GetAttribute("PoliceRank") == 6
                and Player:GetAttribute("UsingLocker") == "MIAPlainclothes"
        end;
        Loadouts = {
            {
                Weapons = {
                    "AlaskanRedhawk";
                };
                Equipment = {
                    "Magnum44Box50";
                };
            };
        }
    };
    {
        Condition = function(Player: Player): boolean
            return Player:GetAttribute("PoliceDivision") == "Investigative"
                and Player:GetAttribute("UsingLocker") == "MIAPlainclothes"
        end;
        Loadouts = {
            {
                Weapons = {
                    "Taurus605";
                };
                Equipment = {
                    "Magnum357Box50";
                };
            };
        }
    };
    {
        Condition = function(Player: Player): boolean
            return Player:GetAttribute("PoliceDivision") == "Investigative"
        end;
        Loadouts = {
            {
                Weapons = {
                    "PB";
                };
                Equipment = {
                    "HandcuffKey";
                    "Handcuffs";
                    "ShoulderRadio";
                };
                Feeds = {
                    {
                        Name = "MakarovMag8";
                        Count = 2;
                    }
                };
            };
        }
    };
    {
        Condition = function(Player: Player): boolean
            return Player:GetAttribute("PoliceDivision") == "Tax"
        end;
        Loadouts = {
            {
                Weapons = {
                    "M6P9";
                };
                Equipment = {
                    "HandcuffKey";
                    "Handcuffs";
                    "ShoulderRadio";
                };
                Feeds = {
                    {
                        Name = "MakarovMag8";
                        Count = 2;
                    }
                };
            };
        }
    };
}

---Checks if a player can check out the weapons
---@param Player Player The Player to check
---@return boolean
module.Restrict = function(Player: Player)
    return Player:GetAttribute("Occupation") == "MIA"
        and Player:GetAttribute("Working")
        and (
            (Player:GetAttribute("PoliceRank") or 0) > 1
            or (
                Player:GetAttribute("PoliceRank") == 1
                and Player:GetAttribute("ArmoryAuthorized")
            )
        )
end

return module