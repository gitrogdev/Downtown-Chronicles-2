--Configuration for all spawn locations
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local GetSpawns = ReplicatedCommunication.GetSpawns

local spawnApts
if RunService:IsClient() then
    local Player = Players.LocalPlayer
    Player.CharacterAdded:Connect(function(Character: Model)
        Character:WaitForChild("Humanoid").Died:Once(function()
            spawnApts = GetSpawns:InvokeServer()
        end)
    end)
end

local config = {}

config.Apartment = {
    ---Determine if a Player can spawn at an apartment building
    ---@param Player Player
    ---@param Spawn SpawnLocation
    ---@return boolean
    Check = function(Player: Player, Spawn: SpawnLocation)
        local Apartment = Spawn.Parent
        local building = Apartment:GetAttribute("Building")
        local unit = Apartment:GetAttribute("Apartment")
        if not (building and unit) then
            return warn(
                `{script}.Apartment.Check: {Spawn:GetFullName()} is not in a \z
                valid apartment!`
            )
        end

        if RunService:IsClient() then
            spawnApts = spawnApts or GetSpawns:InvokeServer()
            for i, accessTo in ipairs(spawnApts) do
                if accessTo.Building == building and accessTo.Unit == unit then
                    return true
                end
            end
            return false
        else
            return require(
                game:GetService("ServerScriptService").ServerScripts.Homes
            ).HasAccess(Player:GetAttribute("ID"), building, unit)
        end

        local citizenship = Player:GetAttribute("Citizenship")
        return citizenship == "North" or citizenship == "Tourist"
    end;
    Display = "Apartment";
}

config.MIA = {
    ---Determine if a Player can spawn at spawn location for the MIA
    ---@param Player Player
    ---@param Spawn SpawnLocation
    ---@return boolean
    Check = function(Player: Player, Spawn: SpawnLocation)
        return Player:GetAttribute("Occupation") == "MIA" and ((
            Spawn:GetAttribute("Division") and (
                Player:GetAttribute("PoliceDivision")
                == Spawn:GetAttribute("Division")
                or Player:GetAttribute("PoliceRank") > 5
        )) or not Spawn:GetAttribute("Division"))
    end;
    Display = "Ministry of Internal Affairs";
}

config.NationalGuard = {
    ---Determine if a Player can spawn at spawn location for the National Guard
    ---@param Player Player
    ---@param Spawn SpawnLocation
    ---@return boolean
    Check = function(Player: Player, Spawn: SpawnLocation)
        return Player:GetAttribute("Occupation") == "Guardsman"
    end;
    Display = "National Guard of North Bloxell";
}

config.North = {
    ---Determine if a Player can spawn at a public spawn location in North Bloxell
    ---@param Player Player
    ---@param Spawn SpawnLocation
    ---@return boolean
    Check = function(Player: Player, Spawn: SpawnLocation)
        local citizenship = Player:GetAttribute("Citizenship")
        return citizenship == "North" or citizenship == "Tourist"
    end;
    Display = "North Bloxell";
}

return config