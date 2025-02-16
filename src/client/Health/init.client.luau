--This script manages the player's health on the client
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NLRHandler = require(script.NLR)
local StaminaHandler = require(script.Stamina)

local Player = Players.LocalPlayer

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Util = require(ScriptStorage.Util)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local UIStorage = ReplicatedStorage.UserInterface

local ReplicatedConfig = ReplicatedScripts.Configuration
local SoundIds = require(ReplicatedConfig.Sounds)

local DeathScreen = UIStorage.DeathScreen:Clone()

local HealthEffect = Util.CreateInstance("ColorCorrectionEffect", {
    Name = "HealthEffect";
    Parent = Lighting;
})

local prompts, newPrompt

Player.CharacterAdded:Connect(function(Character: Model)
    HealthEffect.Brightness = 0
    HealthEffect.Saturation = 0

    if prompts then
        for i, Prompt in ipairs(prompts) do
            Prompt.MaxActivationDistance = (Prompt:GetAttribute("Deactivated")
                and 0) or Prompt:GetAttribute("Original")
        end
        prompts = nil
    end

    if newPrompt then
        newPrompt:Disconnect()
    end

    local Humanoid = Character:WaitForChild("Humanoid")
    NLRHandler.Load(Humanoid)
    local updateHealth

    Humanoid.Died:Once(function()
        local DeathUI = DeathScreen:Clone()
        local Background = DeathUI:WaitForChild("Background")
        local WaitTime = Background:WaitForChild("WaitTime")

        DeathUI.Parent = Player.PlayerGui
        HealthEffect.Brightness = -1

        StaminaHandler.Kill()
        updateHealth:Disconnect()

        prompts = {}
        for i, Child in ipairs(workspace:GetDescendants()) do
            if Child:IsA("ProximityPrompt") then
                table.insert(prompts, Child)
                Child.MaxActivationDistance = 0
            end
        end

        newPrompt = workspace.DescendantAdded:Connect(function(Child: Instance)
            if Child:IsA("ProximityPrompt") then
                table.insert(prompts, Child)
                while not Child:GetAttribute("Original") do
                    task.wait()
                end
                Child.MaxActivationDistance = 0
            end
        end)

        local countdown
        countdown = Player:GetAttributeChangedSignal("ToRespawn"):Connect(
            function()
                local toRespawn = Player:GetAttribute("ToRespawn")
                if not toRespawn then
                    if Character:GetAttribute("Deicide") then
                        WaitTime.Font = Enum.Font.AmaticSC
                        WaitTime.TextTransparency = 1
                        WaitTime.TextStrokeTransparency = 1
                        WaitTime.Text = "Ли тами и пепехка Акуа, пе'меве \z
                            тум'ме меве мафме хулме и?"
                        WaitTime.TextColor3 = Color3.fromRGB(98, 0, 0)

                        Util.CreateInstance("Sound", {
                            Looped = true;
                            PlaybackSpeed = 0.1;
                            Parent = Player.PlayerGui;
                            SoundId = SoundIds.WindChimes;
                            Volume = 1;
                        }):Play()

                        TweenService:Create(WaitTime, TweenInfo.new(30), {
                            TextTransparency = 0;
                            TextStrokeTransparency = 0;
                        }):Play()
                        return
                    else
                        WaitTime.Text = "You will respawn shortly."
                        return countdown:Disconnect()
                    end
                end

                WaitTime.Text = `You will respawn in {toRespawn} second\z
                    {((toRespawn == 1 and "") or "s")}.`
            end
        )
    end)

    Character:GetAttributeChangedSignal("Deicide"):Once(function()
        local DeicideSound = Util.CreateInstance("Sound", {
            PlaybackSpeed = 0.1;
            Parent = Player.PlayerGui;
            SoundId = SoundIds.GlassShatter;
            Volume = 2;
        })

        DeicideSound.Ended:Once(function()
            DeicideSound:Destroy()
        end)

        DeicideSound:Play()
        HealthEffect.Brightness = -0.5
        HealthEffect.Saturation = -1
    end)

    updateHealth = Humanoid.HealthChanged:Connect(function(health: number)
        if Character:GetAttribute("Deicide") then
            return
        end

        if health < Humanoid.MaxHealth / 2 then
            HealthEffect.Saturation = -1 + health / (Humanoid.MaxHealth / 2)
        else
            HealthEffect.Saturation = 0
        end
    end)

    StaminaHandler.Apply(Humanoid)
end)