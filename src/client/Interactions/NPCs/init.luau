--The client-side portion of NPC interactions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local ShopHandler = require(script.Shops)

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local BehaviorHandler = require(ReplicatedScripts.NPCBehavior)
local ConditionHandler = require(ReplicatedScripts.NPCConditions)
local ResponseHandler = require(ReplicatedScripts.NPCResponses)
local Util = require(ReplicatedScripts.Util)

local PassBack = ReplicatedCommunication.PassBack
local StartInteraction = ReplicatedCommunication.StartInteraction
local StopInteraction = ReplicatedCommunication.StopInteraction

local UIStorage = ReplicatedStorage.UserInterface
local DialogueUI = UIStorage.Dialogue

local npcs = {}

---Starts an NPC interaction
---@param config table The NPC configuration sent from the server
---@param at Vector3 The position the NPC is located at
StartInteraction.OnClientEvent:Connect(function(config: table, at: Vector3)
    --To stop other NPC prompts from appearing
    for i, Prompt in ipairs(npcs) do
        Prompt.MaxActivationDistance = 0
        Prompt:SetAttribute("Deactivated", true)
    end

    local Dialogue: ScreenGui = DialogueUI:Clone()
    local Background: Frame = Dialogue:WaitForChild("Background")
    local ActionHolder: Frame = Background:WaitForChild("ActionHolder")
    local DialogueDisplay: TextLabel = Background:WaitForChild("Dialogue")
    local NameDisplay: TextLabel = Background:WaitForChild("NPCName")
    local OptionHolder: ScrollingFrame = Background:WaitForChild("OptionHolder")

    local InvokeInput: TextBox = ActionHolder:WaitForChild("InvokeInput")
    local InvokeSend: TextButton = ActionHolder:WaitForChild("InvokeSend")

    local OptionTemplate: TextButton = OptionHolder:WaitForChild(
        "OptionTemplate"
    )

    local OptionButtons = {}
    local PassedOff

    NameDisplay.Text = config.Name
    Dialogue.Parent = Player.PlayerGui

    local function terminate()
        Dialogue:Destroy()
        if PassedOff then
            PassedOff:Destroy()
        end

        StopInteraction:FireServer()
        for i, Prompt in ipairs(npcs) do
            Prompt.MaxActivationDistance = Prompt:GetAttribute("Original")
            Prompt:SetAttribute("Deactivated", false)
        end
    end
    Player.Character:FindFirstChildOfClass("Humanoid").Died:Once(terminate)

    local ending
    local function handleOption(option: table)
        --To clear old options
        for i, Child in ipairs(OptionButtons) do
            Child:Destroy()
        end
        OptionButtons = {}

        if option.Then.Type == "End" then
            ending = true
        end

        if option.Text then
            ActionHolder.Visible = false
            DialogueDisplay.Visible = true

            for i, text in ipairs(option.Text) do
                Util.Typewriter(
                    text,
                    DialogueDisplay,
                    "Text",
                    0.02,
                    false,
                    false,
                    option.Delay
                )
            end
        end

        if option.Then.Type == "Options" or option.Then.Type == "Respond" then
            if option.Then.Type == "Respond" then
                Util.Typewriter(
                    ResponseHandler[option.Then.Response](Player),
                    DialogueDisplay
                )
            end

            local debounce
            for i, optionInfo in ipairs(option.Then.Options) do
                if
                    not optionInfo.ShowIf
                    or (
                        not ConditionHandler[optionInfo.ShowIf]
                        and warn(
                            `{script}.Dialogue.HandleOption: \z
                            No condition found with key {optionInfo.ShowIf}`
                        )
                        and true
                    )
                    or ConditionHandler[optionInfo.ShowIf](Player)
                then
                    local OptionButton = OptionTemplate:Clone()
                    OptionButton.Name = "OptionButton"
                    OptionButton.Text = optionInfo.Text
                    OptionButton.Parent = OptionHolder

                    local function updateSize()
                        local MessageSize: Vector2 = TextService:GetTextSize(
                            optionInfo.Text,
                            OptionButton.TextSize,
                            Enum.Font.SourceSans,
                            OptionHolder.AbsoluteSize - Vector2.new(0, 12)
                        )
                        OptionButton.Size = UDim2.new(1, -12, 0, MessageSize.Y)
                    end
                    updateSize()
                    local SizeChanged: RBXScriptConnection =
                        OptionHolder:GetPropertyChangedSignal(
                            "AbsoluteSize"
                        ):Connect(updateSize)

                    OptionButton.Visible = true

                    OptionButton.AncestryChanged:Once(function()
                        SizeChanged:Disconnect()
                    end)

                    OptionButton.MouseButton1Click:Connect(function()
                        if debounce then
                            return
                        end
                        debounce = true

                        handleOption(config[optionInfo.Then])
                    end)

                    OptionButton.MouseEnter:Connect(function()
                        TweenService:Create(
                            OptionButton,
                            TweenInfo.new(0.2),
                            {
                                TextColor3 = Color3.new(0.6, 0.6, 0.6)
                            }
                        ):Play()
                    end)

                    OptionButton.MouseLeave:Connect(function()
                        TweenService:Create(
                            OptionButton,
                            TweenInfo.new(0.2),
                            {
                                TextColor3 = Color3.new(1, 1, 1)
                            }
                        ):Play()
                    end)

                    table.insert(OptionButtons, OptionButton)
                end

                ActionHolder.Visible = true
                DialogueDisplay.Visible = false
            end
        elseif option.Then.Type == "Invoke" then
            if not (
                ReplicatedCommunication:FindFirstChild(option.Then.Function)
                and ReplicatedCommunication[option.Then.Function]:IsA(
                    "RemoteFunction"
                )
            ) then
                warn(
                    `{script}.Dialogue.HandleOption: \z
                    RemoteFunction {option.Then.Function} not found!`
                )
                return handleOption(config[option.Then.Then["nil"]])
            end

            local success, response = pcall(tostring,
                ReplicatedCommunication[option.Then.Function]:InvokeServer(
                    option.Then.Arguments and unpack(option.Then.Arguments)
                )
            )
            if not success then
                response = "nil"
            end

            local nextInteraction = option.Then.Then[response]
            print(
                `{script}.Dialogue.HandleOption: Handling the response \z
                {response} (leads to {nextInteraction}) from invoking \z
                {option.Then.Function}`
            )
            handleOption(config[nextInteraction])
        elseif option.Then.Type == "InvokeInput" then
            ActionHolder.Visible = true
            InvokeInput.Visible = true
            InvokeSend.Visible = true

            local debounce, sendClick, restrictText
            sendClick = InvokeSend.MouseButton1Click:Connect(function()
                if debounce then
                    return
                end
                debounce = true

                ActionHolder.Visible = false
                InvokeInput.Visible = false
                InvokeSend.Visible = false
                sendClick:Disconnect()
                if restrictText then
                    restrictText:Disconnect()
                end

                local invokeWith = (
                    option.Then.RestrictText == "InputPosInt"
                    and InvokeInput.Text:gsub(",", "")
                ) or InvokeInput.Text

                local success, response = pcall(tostring,
                    ReplicatedCommunication[option.Then.Function]:InvokeServer(
                        invokeWith
                    )
                )
                if not success then
                    response = "nil"
                end

                InvokeInput.Text = ""

                local nextInteraction = option.Then.Then[response]
                print(
                    `{script}.Dialogue.HandleOption: Handling the response \z
                    {response} (leads to {nextInteraction}) from invoking \z
                    {option.Then.Function}`
                )
                handleOption(config[nextInteraction])
            end)

            if option.Then.RestrictText then
                restrictText = Util[option.Then.RestrictText](
                    InvokeInput,
                    "Text",
                    true,
                    option.Then.AdditionalRestrictions
                        and BehaviorHandler[option.Then.AdditionalRestrictions]
                )
            end
        elseif option.Then.Type == "PassOff" then
            local gui = ReplicatedCommunication[
                option.Then.Function
            ]:InvokeServer(
                option.Then.Arguments and unpack(option.Then.Arguments)
            )

            PassedOff = Player.PlayerGui:FindFirstChild(gui)
            if PassedOff then
                print(`{script}.Dialogue.HandleOption: Passing off to {gui}.`)
                Background.Visible = false

                PassBack.OnClientEvent:Once(function(response: any)
                    if not response then
                        response = "nil"
                    else
                        response = tostring(response)
                    end

                    Background.Visible = true
                    local nextInteraction = option.Then.Then[response]
                    print(
                        `{script}.PassBack.OnClientEvent: Handling the \z
                        response {response} (leads to {nextInteraction}) from \z
                        invoking {option.Then.Function}`
                    )
                    handleOption(config[nextInteraction])
                end)
            else
                if not gui then
                    gui = "nil"
                else
                    gui = tostring(gui)
                end

                Background.Visible = true
                local nextInteraction = option.Then.Then[gui]
                print(
                    `{script}.Dialogue.HandleOption: Handling the \z
                    response {gui} (leads to {nextInteraction}) from \z
                    invoking {option.Then.Function}`
                )
                handleOption(config[nextInteraction])

                warn(
                    `{script}.Dialogue.HandleOption: No GUI found with name \z
                    {gui}!`
                )
            end
        elseif option.Then.Type == "Shop" then
            ShopHandler.new(
                option.Then.Name,
                Dialogue,
                config,
                option.Then.Then,
                handleOption
            )
        elseif option.Then.Type == "End" then
            terminate()
        end
    end

    local checkDistance
    checkDistance = RunService.Heartbeat:Connect(function()
        if ending then
            return checkDistance:Disconnect()
        end

        local distance = Player:DistanceFromCharacter(at)
        if distance > (config.Range or 10) or distance == 0 then
            checkDistance:Disconnect()
            OptionHolder.Visible = false
            
            if Background.Visible then
                handleOption(config.Goodbye)
            else
                terminate()
            end
        end
    end)

    handleOption(config.Initial)
end)

local module = {}

---Sets up display behavior for an NPC ProximityPrompt
module.Setup = function(Prompt: ProximityPrompt)
    table.insert(npcs, Prompt)
end

return module