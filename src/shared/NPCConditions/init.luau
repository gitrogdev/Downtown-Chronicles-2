--All conditions used in NPC interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local Util = require(ReplicatedScripts.Util)

local HasResidence = ReplicatedCommunication.HasResidence
local RentDue = ReplicatedCommunication.RentDue

local module = {}

---Checks if a Player's bank account is frozen
---@param Player Player The Player to check
---@return boolean
module.AccountFrozen = function(Player: Player)
    return Player:GetAttribute("BankFrozen") == true
end

---Checks if a Player can apply for firearms license in North Bloxell
---@param Player Player The Player to check
---@return boolean
module.CanApplyNorthLicense = function(Player: Player)
    return (module.CanApplyNorthHDP(Player)
        or module.CanApplyNorthLTC(Player)
        or module.CanApplyNorthMGP(Player)
    ) and not module.Felon(Player)
end

---Checks if a Player can apply for a Home Defense Permit in North Bloxell
---@param Player Player The Player to check
---@return boolean
module.CanApplyNorthHDP = function(Player: Player)
    return module.NorthHomeowner(Player)
        and Util.GetAge(Player) >= 18
        and not module.NorthHDP(Player)
        and not module.Felon(Player)
end

---Checks if a Player can apply for a License to Carry in North Bloxell
---@param Player Player The Player to check
---@return boolean
module.CanApplyNorthLTC = function(Player: Player)
    return module.NorthCitizen(Player)
        and Util.GetAge(Player) >= 18
        and not module.NorthLTC(Player)
        and not module.Felon(Player)
end

---Checks if a Player can apply for a License to Carry in North Bloxell
---@param Player Player The Player to check
---@return boolean
module.CanApplyNorthMGP = function(Player: Player)
    return module.NorthCitizen(Player)
        and Util.GetAge(Player) >= 18
        and Util.GetTIB(Player) >= 100
        and not module.NorthMGP(Player)
        and not module.Felon(Player)
end

---Checks if a Player can join the National Guard
---@param Player Player The Player to check
---@return boolean
module.CanJoinNG = function(Player: Player)
    return module.UnemployedNorthern(Player)
        and Util.GetAge(Player) >= 17
        and not Player:GetAttribute("NGDischarged")
        and not module.Felon(Player)
end

---Checks if a Player can join the sanitation services
---@param Player Player The Player to check
---@return boolean
module.CanJoinSanitation = function(Player: Player)
    return module.UnemployedNorthern(Player)
        and not module.Felon(Player)
end

---Checks if a Player can check out a weapon from the police armory
---@param Player Player The Player to check
---@return boolean
module.CheckoutMIAWeapon = function(Player: Player)
    return Player.Character
        and (Player.Character:GetAttribute("WeaponsCheckedOut") or 0) == 0
        and Player:GetAttribute("Occupation") == "MIA"
        and (
            (Player:GetAttribute("PoliceRank") or 0) > 1
            or (
                Player:GetAttribute("PoliceRank") == 1
                and Player:GetAttribute("ArmoryAuthorized")
            )
        )
        and Player:GetAttribute("Working")
end

---Checks if a Player can check out a weapon from the national guard armory
---@param Player Player The Player to check
---@return boolean
module.CheckoutNGWeapon = function(Player: Player)
    return ReplicatedStorage:GetAttribute("Emergency")
        and Player.Character
        and (Player.Character:GetAttribute("WeaponsCheckedOut") or 0) == 0
        and Player:GetAttribute("Occupation") == "Guardsman"
        and Player:GetAttribute("Working")
end

---Checks if a Player has been convicted of a felony
---@param Player Player The Player to check
---@return boolean
module.Felon = function(Player: Player)
    return Player:GetAttribute("Felon") == true
end

---Checks if a Player has a weapon belonging to the police armory
---@param Player Player The Player to check
---@return boolean
module.HasMIAWeapon = function(Player: Player)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(`{script}.HasMIAWeapon: No inventory found for {Player}!`)
    end

    for i, Item: Tool in ipairs(Inventory:GetChildren()) do
        if Item:GetAttribute("FromArmory") == "MIAArmory" then
            return true
        end
    end

    local Equipped: Tool = Player.Character
        and Player.Character:FindFirstChildOfClass("Tool")
    if Equipped then
        return Equipped:GetAttribute("FromArmory") == "MIAArmory"
    end
    return false
end

---Checks if a Player has a weapon belonging to the national guard armory
---@param Player Player The Player to check
---@return boolean
module.HasNGWeapon = function(Player: Player)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(`{script}.HasNGWeapon: No inventory found for {Player}!`)
    end

    for i, Item in ipairs(Inventory:GetChildren()) do
        if Item:GetAttribute("FromArmory") == "NGArmory" then
            return true
        end
    end

    local Equipped = Player.Character
        and Player.Character:FindFirstChildOfClass("Tool")
    if Equipped then
        return Equipped:GetAttribute("FromArmory") == "NGArmory"
    end
    return false
end

---Checks if a Player has a search warrant to provide to the locksmiht
---@param Player Player The Player to check
---@return boolean
module.HasSearchWarrant = function(Player: Player): boolean
    return Player:GetAttribute("SearchWarrants") ~= nil
        and Player:GetAttribute("SearchWarrants") ~= ""
        and Player:GetAttribute("SearchWarrants") ~= "[]"
end

---Checks if a Player is a northern citizen that does not own a home
---@param Player Player The Player to check
---@return boolean
module.HomelessNortherner = function(Player: Player)
    return module.NorthCitizen(Player) and not module.Homeowner(Player)
end

---Checks if a Player has a home
---@param Player Player The Player to check
---@return boolean
module.Homeowner = function(Player: Player)
    return HasResidence:InvokeServer()
end

---Checks if a Player has won a free drink from the Laki Club
---@param Player Player The Player to check
---@return boolean
module.LakiDrink = function(Player: Player)
    return Player:GetAttribute("LakiDrink") == true
end

---Checks if a Player has no account with the People's Bank of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.NoPBNBAccount = function(Player: Player)
    return not module.PBNBAccount(Player) and not module.AccountFrozen(Player)
end

---Checks if a Player is a citizen of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.NorthCitizen = function(Player: Player)
    return Player:GetAttribute("Citizenship") == "North"
end

---Checks if a Player can buy firearms in the State of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.NorthGunBuyer = function(Player: Player)
    return (
        Player:GetAttribute("NorthHDP")
        or Player:GetAttribute("NorthLTC")
        or Player:GetAttribute("NorthMGP")
    ) and Util.GetAge(Player) >= 18
    and not module.Felon(Player)
end

---Checks if a Player has a Home Defense Permit in the State of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.NorthHDP = function(Player: Player)
    return Player:GetAttribute("NorthHDP") == true
end

---Checks if a Player has an HDP or an MGP in the State of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.NorthHDPMGP = function(Player: Player)
    return module.NorthHDP(Player) or module.NorthMGP(Player)
end

---Checks if a Player is a Northern Citizen that owns a home
---@param Player Player The Player to check
---@return boolean
module.NorthHomeowner = function(Player: Player)
    return module.NorthCitizen(Player) and module.Homeowner(Player)
end

---Checks if a Player has a License to Carry in the State of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.NorthLTC = function(Player: Player)
    return Player:GetAttribute("NorthLTC") == true
end

---Checks if a Player has a Machine Gun Permit in the State of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.NorthMGP = function(Player: Player)
    return Player:GetAttribute("NorthMGP") == true
end

---Checks if a Player has received a rejection on their license application
---@param Player Player The Player to check
---@return boolean
module.NorthWeaponsResults = function(Player: Player)
    return not not (
        Player:GetAttribute("ApprovedNorthHDP")
        or Player:GetAttribute("ApprovedNorthLTC")
        or Player:GetAttribute("ApprovedNorthMGP")
        or Player:GetAttribute("RejectedNorthHDP")
        or Player:GetAttribute("RejectedNorthLTC")
        or Player:GetAttribute("RejectedNorthMGP")
    )
end

---Checks if a Player is a not a member of the Ministry of Internal Affairs
---@param Player Player The Player to check
---@return boolean
module.NotMIA = function(Player: Player)
    return not (
        module.PoliceOffer(Player) or Player:GetAttribute("Occupation") == "MIA"
    )
end

---Checks if a Player is a not bartender who is currently working
---@param Player Player The Player to check
---@return boolean
module.NotOndutyBartender = function(Player: Player)
    return not module.OndutyBartender(Player)
end

---Checks if a Player is not a sanitation worker
---@param Player Player The Player to check
---@return boolean
module.NotSanitation = function(Player: Player)
    return Player:GetAttribute("Occupation") ~= "Sanitation"
end

---Checks if a Player is a bartender who is not currently working
---@param Player Player The Player to check
---@return boolean
module.OffdutyBartender = function(Player: Player)
    return Player:GetAttribute("Occupation") == "Bartender"
        and not Player:GetAttribute("Working")
end

---Checks if a Player is a sanitation worker who is not currently working
---@param Player Player The Player to check
---@return boolean
module.OffdutySanitation = function(Player: Player)
    return Player:GetAttribute("Occupation") == "Sanitation"
        and not Player:GetAttribute("Working")
end

---Checks if a Player is a bartender who is currently working
---@param Player Player The Player to check
---@return boolean
module.OndutyBartender = function(Player: Player)
    return Player:GetAttribute("Occupation") == "Bartender"
        and Player:GetAttribute("Working")
end

---Checks if a Player has an account with the People's Bank of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.PBNBAccount = function(Player: Player)
    return Player:GetAttribute("PBNBAccount")
        and not module.AccountFrozen(Player)
end

---Checks if a Player has an offer to join the Ministry of Internal Affairs
---@param Player Player The Player to check
---@return boolean
module.PoliceOffer = function(Player: Player)
    return Player:GetAttribute("PoliceOffer")
        and Player:GetAttribute("PoliceOffer") ~= ""
end

---Checks if a Player's rent is due
---@param Player Player The Player to check
---@return boolean
module.RentDue = function(Player: Player)
    return RentDue:InvokeServer()
end

---Checks if a Player is a northern citizen with due rent
---@param Player Player The Player to check
---@return boolean
module.RentDueNorth = function(Player: Player)
    return module.NorthCitizen(Player) and module.RentDue(Player)
end

---Checks if a Player is unemployed
---@param Player Player The Player to check
---@return boolean
module.Unemployed = function(Player: Player)
    return not Player:GetAttribute("Occupation")
        or Player:GetAttribute("Occupation") == "Unemployed"
end

---Checks if a Player is unemployed citizen of North Bloxell
---@param Player Player The Player to check
---@return boolean
module.UnemployedNorthern = function(Player: Player)
    return module.Unemployed(Player)
        and module.NorthCitizen(Player)
end

---Checks if a Player is a tourist
---@param Player Player The Player to check
---@return boolean
module.Tourist = function(Player: Player)
    return not Player:GetAttribute("Citizenship")
        or Player:GetAttribute("Citizenship") == "Tourist"
end

return module