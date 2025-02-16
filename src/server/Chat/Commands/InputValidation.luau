--Handles validation and parsing of all input types
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local Util = require(ServerScripts.Util)

local module = {}

---Converts the given argument into a single character Model
---@param argument string The argument containing the character name
---@param Executor Player The Player executing the command
---@return Model
---@return boolean
module.Character = function(argument: string, Executor: Player)
    argument = argument:lower()
    if argument == "me" then
        return Executor.Character, true
    end

    local firstMatch
    for i, Player in ipairs(Players:GetPlayers()) do
        if not Player.Character then
            continue
        end

        --If exact name entered, break instantly
        if Player.Name:lower() == argument then
            return Player.Character, true
        end

        if not firstMatch
            and Player.Name:lower():sub(1, #argument) == argument
        then
            firstMatch = Player.Character
        end
    end

    if firstMatch then
        return firstMatch, true
    end
end

---Converts the given argument into an array of character models
---@param argument string The argument containing the character names
---@param Executor Player The Player executing the command
---@return table
---@return boolean
module.Characters = function(argument: string, Executor: Player)
    argument = argument:lower()
    local matches = {}

    if argument == "me" then
        if Executor.Character then
            return {Executor.Character}, true
        else
            return
        end
    elseif argument == "all" then
        for i, Player in ipairs(Players:GetPlayers()) do
            if Player.Character then
                table.insert(matches, Player.Character)
            end
        end
        return matches, true
    elseif argument == "others" then
        for i, Player in ipairs(Players:GetPlayers()) do
            if Player ~= Executor and Player.Character then
                table.insert(matches, Player.Character)
            end
        end
        return matches, true
    end

    local arguments = Util.SplitString(argument, "%P+")
    for i, target in ipairs(arguments) do
        local firstMatch

        for j, Player in ipairs(Players:GetPlayers()) do
            if not Player.Character then
                continue
            end

            --If exact name entered, break instantly
            if Player.Name:lower() == target then
                table.insert(matches, Player.Character)
                break
            end

            if not firstMatch
                and Player.Name:lower():sub(1, #target) == target
            then
                firstMatch = Player.Character
            end
        end

        if firstMatch then
            table.insert(matches, firstMatch)
        end
    end
    return matches, true
end

---Converts the given argument into saved character data
---@param argument string The argument containing the character ID
---@return number
---@return boolean
module.CharacterID = function(argument: string)
    argument = tonumber(argument)
    if not argument then
        return
    end

    if not argument == math.floor(math.abs(argument)) then
        return
    end

    if not DataHandler.Get("Characters", tostring(argument)) then
        return
    end
    return argument, true
end

---Converts the given argument into a single Player
---@param argument string The argument containing the Player name
---@param Executor Player The Player executing the command
---@return Player
---@return boolean
module.Player = function(argument: string, Executor: Player)
    argument = argument:lower()
    if argument == "me" then
        return Executor, true
    end

    local firstMatch
    for i, Player in ipairs(Players:GetPlayers()) do
        --If exact name entered, break instantly
        if Player.Name:lower() == argument then
            return Player, true
        end

        if not firstMatch and Player.Name:lower():sub(1, #argument) == argument then
            firstMatch = Player
        end
    end

    if firstMatch then
        return firstMatch, true
    end
end

---Converts the given argument into an array of Players
---@param argument string The argument containing the Player names
---@param Executor Player The Player executing the command
---@return table
---@return boolean
module.Players = function(argument: string, Executor: Player)
    argument = argument:lower()
    local matches = {}

    if argument == "me" then
        return {Executor}, true
    elseif argument == "all" then
        return Players:GetPlayers(), true
    elseif argument == "others" then
        for i, Player in ipairs(Players:GetPlayers()) do
            if Player ~= Executor then
                table.insert(matches, Player)
            end
        end
        return matches, true
    end

    local arguments = Util.SplitString(argument, "%P+")
    for i, target in ipairs(arguments) do
        local firstMatch

        for j, Player in ipairs(Players:GetPlayers()) do
            --If exact name entered, break instantly
            if Player.Name:lower() == target then
                table.insert(matches, Player)
                break
            end

            if not firstMatch
                and Player.Name:lower():sub(1, #target) == target
            then
                firstMatch = Player
            end
        end

        if firstMatch then
            table.insert(matches, firstMatch)
        end
    end
    return matches, true
end

---Confirms that a non-empty string argument is present
---@param argument string The provided string argument
---@return string
---@return boolean
module.string = function(argument: string)
    return argument, typeof(argument) == "string" and #argument > 0
end

---Converts the given argument into a UserId
---@param argument string The argument containing the Player name or UserId
---@param Executor Player The Player executing the command
---@return number
---@return boolean
module.User = function(argument: string, Executor: Player)
    argument = argument:lower()
    if argument == "me" then
        return Executor.UserId, true
    end

    local firstMatch
    for i, Player in ipairs(Players:GetPlayers()) do
        --If exact name entered, break instantly
        if Player.Name:lower() == argument then
            return Player.UserId, true
        end

        if not firstMatch
            and Player.Name:lower():sub(1, #argument) == argument
        then
            firstMatch = Player
        end
    end

    if firstMatch then
        return firstMatch.UserId, true
    end

    --Checks user ID
    if tostring(tonumber(argument)) == argument then
        local success = pcall(
            Players.GetNameFromUserIdAsync,
            Players,
            tonumber(argument)
        )
        if success then
            return tonumber(argument), true
        end
    end

    local success, response = pcall(
        Players.GetUserIdFromNameAsync,
        Players,
        argument
    )
    return response, success
end

return module