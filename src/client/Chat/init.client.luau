--This script handles the game's custom chat on the client
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Communication = ReplicatedScripts.Communication
local SendMessage = Communication.SendMessage
local SendNotification = Communication.SendNotification

local UIStorage = ReplicatedStorage.UserInterface
local ChatGui = UIStorage.ChatGui:Clone()
local ChatDisplay = ChatGui:WaitForChild("ChatDisplay")
local MessageTemplate = ChatDisplay:WaitForChild("MessageTemplate")

local TextChatCommands = TextChatService:WaitForChild("TextChatCommands")

ChatGui.Parent = Player.PlayerGui

local cache = {}

local function applyAssociated(input: string, name: string): string
    return input:gsub(`$\x7BAssociated\x7D`, name)
end

Player.CharacterAdded:Connect(function(Character: Model)
    local Humanoid = Character:WaitForChild("Humanoid")
    Humanoid.Died:Once(function()
        for i, Message in ipairs(cache) do
            Message:Destroy()
        end
        ChatDisplay.CanvasSize = UDim2.new()
        cache = {}
    end)
end)

Player:GetAttributeChangedSignal("PermissionLevel"):Connect(function()
    local permissionLevel = Player:GetAttribute("PermissionLevel")
    for i, ChatCommand in ipairs(TextChatCommands:GetChildren()) do
        local commandLevel = ChatCommand:GetAttribute("PermissionLevel")
        if ChatCommand:IsA("TextChatCommand") and commandLevel then
            ChatCommand.AutocompleteVisible = permissionLevel >= commandLevel
            ChatCommand.Enabled = ChatCommand.AutocompleteVisible
        end
    end
end)

---Receive a chat message from the server and display it on the client
---@param message string The message being sent
---@param format table The format to follow
---@param Sender Player The Player sending the message
SendMessage.OnClientEvent:Connect(function(
    message: string, format: table, Sender: Player
)
    if Sender then
        local associated: table = HttpService:JSONDecode(Player:GetAttribute(
            "NameAssociations"
        ))
        local associatedName: string = (Sender == Player and "Your character")
            or (
                (not Sender:GetAttribute("Masked"))
                and associated[tostring(Sender:GetAttribute("ID"))]
            ) or `Stranger ({Sender.UserId}-{Sender:GetAttribute("ID")})`

        format.Prefix = applyAssociated(format.Prefix or "", associatedName)
        format.Suffix = applyAssociated(format.Suffix or "", associatedName)
    end

    message = `{format.Prefix or ""}{message}{format.Suffix or ""}`
    
    local MessageDisplay = MessageTemplate:Clone()

    local messageSize = TextService:GetTextSize(
        message .. "123.",
        MessageDisplay.TextSize,
        Enum.Font.SourceSans,
        ChatDisplay.AbsoluteSize
    )

    local ySize = messageSize.Y + 4
    local maxSize = MessageTemplate.TextSize * 3 + 4
    ySize = (ySize > maxSize and maxSize) or ySize

    MessageDisplay.Size = UDim2.new(
        MessageDisplay.Size.X,
        UDim.new(0, ySize)
    )

    MessageDisplay.Text = message
    MessageDisplay.TextColor3 = format.TextColor3
    MessageDisplay.Visible = true
    MessageDisplay.Parent = ChatDisplay

    table.insert(cache, MessageDisplay)
    ChatDisplay.CanvasSize += UDim2.fromOffset(0, ySize)
    ChatDisplay.CanvasPosition += Vector2.new(0, ySize)
end)

SendNotification.OnClientEvent:Connect(function(arguments: table)
    StarterGui:SetCore("SendNotification", arguments)
end)