--This script handles all chat commands on the server side
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Communication = ReplicatedScripts.Communication
local SendMessage = Communication.SendMessage

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local TextChatCommands = TextChatService:WaitForChild("TextChatCommands")

local ChatCommands = require(script.Chat)
local InputValidation = require(script.InputValidation)
local PermissionLevels = require(script.PermissionLevels)
local RemoveCommands = require(script.RemoveCommands)

local commands = {}

---Writes a command syntax
---@param command string The command to write the syntax for
---@param sequence table The argument sequence to specify in the syntax
---@return string
local function writeSyntax(command: string, sequence: table)
    if #sequence == 0 then
        return command
    end

    local output = command
    for i, argument in ipairs(sequence) do
        output ..= ` <{argument}>`
    end
    return output
end

local module = {}

---Calculates and applies the permission level granted to a Player
---@param Player Player The Player to check the permission level of
module.CalculatePermissions = function(Player: Player)
    local success, response = pcall(
        Player.GetRankInGroup,
        Player,
        PermissionLevels.GroupId
    )

    if not success then
        warn(
            `{script}.CalculatePermissions: Unable to get {Player}'s rank in \z
            the Bigman Studios group. Reason: {response}`
        )
    end
    
    Player:SetAttribute("PermissionLevel",
        PermissionLevels.Roles[response]
        or 0
    )
end

---Checks if a string is a command
---@param command string The string to check
---@return boolean
module.IsCommand = function(command: string)
    return commands[tostring(command):lower()] and true or false
end

---Parses the command arguments into their proper types
---@param arguments table The command arguments provided
---@param sequence table The argument syntax outlined by the command
---@param Executor Player The Player executing the command
---@return table
module.ProcessArguments = function(
    arguments: table,
    sequence: table,
    Executor: Player
)
    if (not sequence) or #sequence == 0 then
        return {}
    end

    if not (arguments and #arguments > 1) then
        module.Respond(
            Executor,
            `Invalid syntax. Expected {writeSyntax(arguments[1], sequence)}`
        )
        return warn(`{script}.ProcessArguments: \z
        No arguments provided. Expected {#sequence}`)
    end

    --Gets rid of the command name
    local command = table.remove(arguments, 1)

    --Allows multi-word strings for the last argument
    if sequence[#sequence] == "string" and #arguments > #sequence then
        for i = #sequence + 1, #arguments do
            arguments[#sequence] =
                `{arguments[#sequence]} {table.remove(arguments, #sequence + 1)}`
        end
    end

    for i, argument in ipairs(arguments) do
        local argType = sequence[i]
        local validate, valid = InputValidation[argType]
        if not validate then
            module.Respond(
                Executor,
                `Unknown argument <{argType}> requested. \z
                Please report this to a developer.`
            )
            return error(`{script}.ProcessArguments: \z
                Unknown argument type found in sequence at {i}: {argType}`)
        end

        arguments[i], valid = validate(argument, Executor)
        if not valid then
            module.Respond(
                Executor,
                `Invalid argument type provided for <{argType}>.`
            )
            return warn(`{script}.ProcessArguments: \z
                Invalid argument found for type {argType} at {i}!`)
        end
    end

    return arguments
end

---Sends command output as a chat message
---@param Executor Player The Player executing the command
---@param message string The message to respond with
module.Respond = function(Executor: Player, message: string)
    SendMessage:FireClient(Executor, message, {
        Prefix = "[Server]: ";
        TextColor3 = Color3.new(0.75, 0.75, 0.75);
    })
end

---Sets up commands to be executed
module.Setup = function()
    if module.Commands then
        return warn(`{script}.Setup: Setup already complete!`)
    end

    for i, command in ipairs(RemoveCommands) do
        local Command = TextChatCommands:FindFirstChild(command)
        if Command then
            Command:Destroy()
        end
    end

    module.Commands = {}
    for i, Command in ipairs(script.Commands:GetChildren()) do
        if Command:IsA("ModuleScript") then
            local commandData = require(Command)
            
            Util.CreateInstance("TextChatCommand", {
                Name = Command.Name;
                Parent = TextChatCommands;
                PrimaryAlias = commandData.PrimaryAlias;
                SecondaryAlias = commandData.SecondaryAlias;
            }, {
                PermissionLevel = commandData.PermissionLevel;
            }).Triggered:Connect(function(Origin: TextSource, input: string)
                local Executor = Players:GetPlayerByUserId(Origin.UserId)
                if not Executor then
                    return warn(`{script}.Setup.{Command}.Triggered: \z
                        No executor found from {Origin}!`)
                end

                local permissionLevel = Executor:GetAttribute("PermissionLevel")
                    or 0
                local reqLevel = commandData.PermissionLevel
                if permissionLevel < reqLevel then
                    module.Respond(
                        Executor,
                        "You do not have permission to use this command."
                    )
                    return warn(`{script}.Setup.{Command}.Triggered: \z
                        {Executor.Name} does not have permission \z
                        to use this command! \z
                        (Required: {reqLevel}, got: {permissionLevel})`
                    )
                end

                if commandData.RequireAlive then
                    local Character = Executor.Character
                    if not Character then
                        module.Respond(
                            Executor,
                            "Your character must be loaded to use this command."
                        )
                        return warn(`{script}.Setup.{Command}.Triggered: \z
                            Player {Executor} does not have a character loaded!`
                        )
                    end

                    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                    if not (Humanoid and Humanoid.Health > 0) then
                        module.Respond(
                            Executor,
                            "Your character must be alive to use this command."
                        )
                        return warn(`{script}.Setup.{Command}.Triggered: \z
                            Player {Executor} is currently dead!`
                        )
                    end
                end

                local arguments = Util.SplitString(input)
                arguments = module.ProcessArguments(
                    arguments,
                    commandData.ArgSequence,
                    Executor
                )

                if not arguments then
                    return warn(`{script}.Setup.{Command}.Triggered: \z
                        {Executor} provided bad arguments for the command!`
                    )
                end

                local response = commandData.Execute(
                    Executor,
                    unpack(arguments)
                )
                if response then
                    module.Respond(Executor, response)
                end
            end)
            
            table.insert(module.Commands, commandData)
        end
    end

    for command, alias in pairs(ChatCommands) do
        Util.CreateInstance("TextChatCommand", {
            Name = command;
            Parent = TextChatCommands;
            PrimaryAlias = alias;
        })
    end

    for i, Child in ipairs(TextChatCommands:GetChildren()) do
        commands[Child.PrimaryAlias] = true
        if Child.SecondaryAlias and #Child.SecondaryAlias > 0 then
            commands[Child.SecondaryAlias] = true
        end
    end
end

return module