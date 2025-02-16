--The /devplace command used for teleporting players into the development place
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local ServerConfig = ServerScripts.Configuration

local PlaceIds = require(ServerConfig.Places)

local command = {
    PrimaryAlias = "/devplace";
    SecondaryAlias = "/testplace";
    
    PermissionLevel = 6;
    ArgSequence = {
        "Players"
    };
    Execute = function(Player: Player, Targets: table)
        for i, TargetPlayer in ipairs(Targets) do
            DataHandler.Update("UserData", tostring(TargetPlayer.UserId),
                function(data: table)
                    data = data or {}

                    data.DevPlace = true

                    return data
                end
            )
        end
        TeleportService:TeleportPartyAsync(PlaceIds.DevPlace, Targets)
        return `Teleporting {#Targets} player{#Targets == 1 and "" or "s"} to \z
            the development place.`
    end
}

return command