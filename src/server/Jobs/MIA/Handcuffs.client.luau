--Handle handcuffs on the client
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool: Tool = script.Parent

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication

local HandcuffPlayer = ReplicatedCommunication.HandcuffPlayer

local Util = require(ReplicatedScripts.Util)

local Prompts = {}

Tool.Equipped:Connect(function()
    for i, Player: Player in ipairs(Players:GetPlayers()) do
        if Player == Players.LocalPlayer then
            continue
        end

        local Character: Model = Player.Character
        if not Character then
            continue
        end

        local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            continue
        end

        if Humanoid.Health <= 0 then
            continue
        end

        local Torso: Part = Character:FindFirstChild("Torso")
        if not Torso then
            continue
        end

        local BackAttachment: Attachment = Torso:FindFirstChild(
            "BodyBackAttachment"
        )
        if not BackAttachment then
            continue
        end

        if Character:GetAttribute("Cuffed") then
            continue
        end

        local CuffPrompt: ProximityPrompt = Util.CreateInstance(
            "ProximityPrompt",
            {
                ActionText = "Handcuff";
                ClickablePrompt = true;
                HoldDuration = 0.5;
                KeyboardKeyCode = Enum.KeyCode.E;
                MaxActivationDistance = 4;
                Parent = BackAttachment;
                RequiresLineOfSight = true;
            }
        )
        CollectionService:AddTag(CuffPrompt, "ApplyHandcuffs")

        CuffPrompt.Triggered:Connect(function(Triggerer: Player)
            if Triggerer ~= Players.LocalPlayer then
                return warn(
                    `{script}.{Player}.CuffPrompt.Triggered: Local prompt was \z
                    triggered by a Player other than the LocalPlayer! (\z
                    Triggered by {Triggerer}, LocalPlayer: {Player})`
                )
            end

            HandcuffPlayer:FireServer(Player)
        end)

        table.insert(Prompts, CuffPrompt)
    end
end)

Tool.Unequipped:Connect(function()

end)