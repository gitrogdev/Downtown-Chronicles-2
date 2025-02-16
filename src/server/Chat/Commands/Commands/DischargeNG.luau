--The /dischargeguardsman used for discharging national guardsmen
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local CitizenshipHandler = require(ServerScripts.Citizenship)
local TeamHandler = require(ServerScripts.Teams)

local command = {
    PrimaryAlias = "/dischargeguardsman";
    SecondaryAlias = "/ngdischarge";
    
    PermissionLevel = 4;
    ArgSequence = {
        "Player"
    };
    Execute = function(Player: Player, Discharge: Player)
        if Discharge:GetAttribute("Occupation") ~= "Guardsman" then
            return `{Discharge:GetAttribute("FullName")} is not a guardsman!`
        end

        Discharge:SetAttribute("NGDischarged", true)
        Discharge:SetAttribute("Occupation", "Unemployed")
        
        if Discharge:GetAttribute("Working") then
            Discharge:SetAttribute("Working", false)
            Discharge:SetAttribute("ClothesStored", false)

            for i, clothingType in ipairs({"Shirt", "Pants"}) do
                Discharge:SetAttribute(
                    clothingType, Discharge:GetAttribute(`Saved{clothingType}`)
                )
                Discharge:SetAttribute(`Saved{clothingType}`, nil)
            end

            TeamHandler.Join(Discharge, CitizenshipHandler.ToTeam(
                Discharge:GetAttribute("Citizenship")
            ))
        end

        return `{Discharge:GetAttribute("FullName")} has been discharged from \z
            the National Guard!`
    end
}

return command