--Handles the "Character Slot" developer product
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local CharacterHandler = require(ServerScripts.Characters)
local DataHandler = require(ServerScripts.Data)

local module = {}

---Handles the purchase of a new character slot
---@param Player Player The Player that purchased a character slot
module.Bought = function(Player: Player)
    DataHandler.Update("UserData", tostring(Player.UserId),
        function(data: table)
            data.MaxCharacters = data.MaxCharacters
                or (#data.Characters > 0 and #data.Characters) or 1
            
            data.MaxCharacters += 1

            return data
        end
    )

    CharacterHandler.new(Player)
end

return module