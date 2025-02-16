--The /killcharacter command used for permanently killing a character
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local BookingHandler = require(ServerScripts.Interactions.Booking)
local DataHandler = require(ServerScripts.Data)
local Util = require(ServerScripts.Util)

local command = {
    PrimaryAlias = "/chargeplayer";
    SecondaryAlias = "/charge";
    
    PermissionLevel = 3;
    ArgSequence = {
        "CharacterID"
    };
    Execute = function(Player: Player, charId: number)
        local success, fullName, incarceratedTo, userId, bday, bmonth, byear
        DataHandler.Update("Characters", tostring(charId),
            function(charData: table)
                charData = charData or {}

                success = not (charData.Dead or charData.Occupation == "MIA")
                if success then
                    incarceratedTo = charData.IncarceratedTo
                    fullName = `{charData.FirstName} {charData.LastName}`
                    userId = charData.Created and charData.Created.By or "?"
                    bday = charData.Birthday.Day
                    bmonth = charData.Birthday.Month
                    byear = charData.Birthday.Year
                end

                return charData
            end
        )

        if not success then
            return `Unable to charge character with character ID {charId}!`
        end

        BookingHandler.Initiate(Player, {
            Util.CreateInstance("Model", {
                Name = `{fullName}`;
                Parent = ReplicatedStorage;
            }, {
                BirthDay = bday;
                BirthMonth = bmonth;
                BirthYear = byear;
                ID = charId;
                IncarceratedTo = incarceratedTo;
                FullName = fullName;
                UserId = userId;
            })
        })
    end
}

return command