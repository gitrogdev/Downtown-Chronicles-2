--This script handles the game's custom chat on the server
local Chat = game:GetService("Chat")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local CommandHandler = require(script.Commands)
local MessageFormats = require(script.MessageFormats)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Communication = ReplicatedScripts.Communication
local SendMessage = Communication.SendMessage

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)


local function applyFormats(input: string, Player: Player)
    for key, apply in pairs(MessageFormats.Formats) do
        input = input:gsub(`$\x7B{key}\x7D`, apply(Player))
    end
    return input
end

local module = {}

module.Commands = CommandHandler

---Starts listening to chat messages from a Player
---@param Player Player The Player to listen to messages from
module.Listen = function(Player: Player)
    Player.Chatted:Connect(function(message: string)
        local Character = Player.Character
        if not Character then
            return
        end

        local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
        if not Inventory then
            return
        end

        --Removes line breaks to prevent "chat clearing"
        message = message:gsub("\n", "")

        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not (Humanoid and RootPart and Humanoid.Health > 0) then
            return
        end

        local format
        for key, formatData in pairs(MessageFormats.Commands) do
            local command = MessageFormats.CommandPrefix .. key
            if message:lower():sub(1, #key + 1) == command then
                format = table.clone(formatData)
                break
            end
        end

        --Avoid showing commands in the chat
        if not format
            and message:sub(1,1) == MessageFormats.CommandPrefix
            and CommandHandler.IsCommand(Util.SplitString(message)[1])
        then
            return
        end

        local UsingRadio: Tool =
            Util.FindFirstChildOfClassWithAttributes(Character, "Tool", {
                Active = true;
                FileName = "ShoulderRadio";
            }) or Util.FindFirstChildOfClassWithAttributes(Inventory, "Tool", {
                Active = true;
                FileName = "ShoulderRadio";
            })
        if UsingRadio and not format then
           format = table.clone(MessageFormats.Radio)
        end

        format = format or table.clone(MessageFormats.Default)

        --Applies all default values
        for key, value in pairs(MessageFormats.Default) do
            format[key] = format[key] or value
        end

        if format.Substring then
            message = message:sub(unpack(format.Substring))
        end

        if format.Prefix then
            format.Prefix = applyFormats(format.Prefix, Player)
        end

        if format.Suffix then
            format.Suffix = applyFormats(format.Suffix, Player)
        end

        ---Roblox replaces certain characters with escape forms. This fixes that
        for i, escapeForm in ipairs(MessageFormats.EscapeForms) do
            message = message:gsub(unpack(escapeForm))
        end

        local rootPos = RootPart.Position
        for i, Recipient: Player in ipairs(Players:GetPlayers()) do
            local CheckChar: Model = Recipient.Character
            if not CheckChar then
                continue
            end

            if UsingRadio then
                local CheckInv = Recipient.PlayerGui:FindFirstChild("Inventory")
                if not CheckInv then
                    continue
                end

                local ReceivingRadio: Tool =
                    Util.FindFirstChildOfClassWithAttributes(CheckChar,
                        "Tool", {
                            FileName = "ShoulderRadio";
                            FromArmory = UsingRadio:GetAttribute("FromArmory");
                        }
                    ) or Util.FindFirstChildOfClassWithAttributes(CheckInv,
                        "Tool", {
                            FileName = "ShoulderRadio";
                            FromArmory = UsingRadio:GetAttribute("FromArmory");
                        }
                    )
                
                if not ReceivingRadio then
                    continue
                end

                local RecipientHumanoid: Humanoid =
                    CheckChar:FindFirstChildOfClass("Humanoid")
                if not (RecipientHumanoid and RecipientHumanoid.Health > 0) then
                    continue
                end

                SendMessage:FireClient(
                    Recipient,
                    Chat:FilterStringAsync(message, Player, Recipient),
                    format,
                    Player
                )
            else
                local distance = Recipient:DistanceFromCharacter(rootPos)
                local RecipientHumanoid: Humanoid =
                    CheckChar:FindFirstChildOfClass("Humanoid")
                if Recipient == Player or (
                    RecipientHumanoid and RecipientHumanoid.Health > 0
                    and (distance > 0 and distance < format.Range))
                then
                    SendMessage:FireClient(
                        Recipient,
                        Chat:FilterStringAsync(message, Player, Recipient),
                        format,
                        Player
                    )
                end
            end
        end
    end)
end

---Hides the default chat window and sets up custom commands
module.Setup = function()
    TextChatService.ChatWindowConfiguration.Enabled = false

    CommandHandler.Setup()
end

return module