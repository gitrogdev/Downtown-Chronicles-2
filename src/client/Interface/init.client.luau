--Handles the interface UI
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local InventoryHandler = require(script.Inventory)
local NametagHandler = require(script.Nametags)
local TIBHandler = require(script.TIB)
local VoiceHandler = require(script.Voice)

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local UIStorage = ReplicatedStorage.UserInterface

local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration
local Util = require(ReplicatedScripts.Util)

local FadeTeleport = ReplicatedCommunication.FadeTeleport

local Rules = require(ReplicatedConfig.Rules)

local Interface: ScreenGui = UIStorage.Interface:Clone()
local Background: Frame = Interface:WaitForChild("Background")
local DiscordInvite: Frame = Interface:WaitForChild("DiscordInvite")
local GuideDisplay: Frame = Interface:WaitForChild("GuideDisplay")
local GuideHolder: Frame = Interface:WaitForChild("GuideHolder")
local Hotbar: Frame = Interface:WaitForChild("Hotbar")
local RulesDisplay: Frame = Interface:WaitForChild("RulesDisplay")
local RulesHolder: Frame = Interface:WaitForChild("RulesHolder")

local CharacterName: TextLabel = Background:WaitForChild("CharacterName")
local HealthBackground: Frame = Background:WaitForChild("HealthBar")
local StaminaBackground: Frame = Background:WaitForChild("StaminaBar")
local TIBDisplay: TextLabel = Background:WaitForChild("TIBDisplay")

local HealthBar: Frame = HealthBackground:WaitForChild("Bar")
local StaminaBar: Frame = StaminaBackground:WaitForChild("Bar")

local GuideButton: TextButton = GuideHolder:WaitForChild("GuideButton")

local RuleHolder: ScrollingFrame = RulesDisplay:WaitForChild("RuleHolder")

local RuleTemplate: Frame = RuleHolder:WaitForChild("RuleTemplate")

local RulesButton: TextButton = RulesHolder:WaitForChild("RulesButton")

local listening, findInventory

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local policyInfo = PolicyService:GetPolicyInfoForPlayerAsync(Player)
for i, link in ipairs(policyInfo.AllowedExternalLinkReferences) do
    if link == "Discord" then
        DiscordInvite.Visible = true
        break
    end
end

GuideDisplay.Visible = Player:GetAttribute("Playtime") == 0

Player.CharacterAdded:Once(NametagHandler.Setup)
Player.CharacterAdded:Connect(function(Character: Model)
    local Blackout = Lighting:FindFirstChild("Blackout")
    if Blackout then
        Blackout:Destroy()
    end

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)

    if not listening then
        CharacterName.Text = `{Player:GetAttribute("FullName")} \z
            ({Player:GetAttribute("ID")})`
        Player:GetAttributeChangedSignal("FullName"):Connect(function()
            CharacterName.Text = `{Player:GetAttribute("FullName")} \z
                ({Player:GetAttribute("ID")})`
        end)
        TIBHandler.Listen(TIBDisplay)
        listening = true
    end

    local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
    local updateHealth, updateStamina

    local Listener: AudioListener
    if VoiceHandler.CanTalk() then
        Listener = VoiceHandler.Setup()
    end

    ---Fade out the screen, and teleport to a location
    ---@param target CFrame Where to teleport the player to
    local OnTeleport: RBXScriptConnection = FadeTeleport.OnClientEvent:Connect(
        function(target: CFrame)
            local Fade: ColorCorrectionEffect = Util.CreateInstance(
                "ColorCorrectionEffect", {
                    Parent = Lighting;
                }
            )
            local FadeTween = TweenService:Create(Fade, TweenInfo.new(1), {
                Brightness = -1;
            })

            FadeTween.Completed:Once(function()
                Humanoid.Sit = false
                if Humanoid.SeatPart then
                    Humanoid:GetPropertyChangedSignal("SeatPart"):Wait()
                end
                Humanoid.RootPart.CFrame = target
                task.wait(0.5)
                local FadeOutTween = TweenService:Create(Fade, TweenInfo.new(1),
                    {
                        Brightness = 0;
                    }
                )
                
                FadeOutTween.Completed:Once(function()
                    Fade:Destroy()
                end)
                FadeOutTween:Play()
            end)
            FadeTween:Play()
        end
    )

    Humanoid.Died:Once(function()
        if (Player:GetAttribute("PermissionLevel") or 0) == 0 then
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        end
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        if Listener then
            Listener:Destroy()
        end
        OnTeleport:Disconnect()
        updateHealth:Disconnect()
        updateStamina:Disconnect()
        Interface.Parent = nil
    end)

    Character.ChildAdded:Connect(function(Child: Instance)
        local guiName = Child:GetAttribute("AssociatedGui")
        local tagName = Child:GetAttribute("AssociateTag")
        if guiName or tagName then
            Child.AncestryChanged:Once(function()
                if guiName then
                    local AssociatedGui = Player.PlayerGui:FindFirstChild(
                        guiName
                    )
                    if AssociatedGui and not Child:IsDescendantOf(Player) then
                        AssociatedGui.Parent = nil
                    end
                end

                if tagName then
                    for i, Tagged: Instance in ipairs(
                        CollectionService:GetTagged(tagName)
                    ) do
                        Tagged:Destroy()
                    end
                end
            end)
        end

        local hidesIcon = Child:GetAttribute("HidesMouseIcon")
        if hidesIcon then
            Child.AncestryChanged:Once(function()
                if not Child:IsDescendantOf(Player) then
                    UserInputService.MouseIconEnabled = true
                end
            end)
        end
    end)

    updateStamina = Humanoid:GetAttributeChangedSignal("Stamina"):Connect(
        function()
            local maxStamina = Player:GetAttribute("MaxStamina") or 30
            StaminaBar.Size = UDim2.fromScale(
                Humanoid:GetAttribute("Stamina") / maxStamina,
                1
            )
        end
    )
    StaminaBar.Size = UDim2.fromScale(1, 1)

    updateHealth = Humanoid.HealthChanged:Connect(function(health: number)
        if health < 0 then
            health = 0
        end
        HealthBar.Size = UDim2.fromScale(health / Humanoid.MaxHealth, 1)
    end)
    HealthBar.Size = UDim2.fromScale(1, 1)

    Interface.Parent = Player.PlayerGui
end)

findInventory = Player.PlayerGui.ChildAdded:Connect(function(Child: Instance)
    if Child:IsA("ScreenGui") and Child.Name == "Inventory" then
        findInventory:Disconnect()
        InventoryHandler.Setup(Child, Hotbar)
    end
end)

for i, rule in ipairs(Rules.Rules) do
    local RuleDisplay: Frame = RuleTemplate:Clone()
    local Body: TextLabel = RuleDisplay:WaitForChild("Body")
    local DetailToggle: TextButton = RuleDisplay:WaitForChild("DetailToggle")
    local Head: TextLabel = RuleDisplay:WaitForChild("Head")
    local LongBody: TextLabel = RuleDisplay:WaitForChild("LongBody")

    Head.Text = `{rule.Roman}. {rule.Name}`
    Body.Text = rule.Simple
    LongBody.Text = rule.Description

    DetailToggle.MouseButton1Click:Connect(function()
        LongBody.Visible = not LongBody.Visible
        DetailToggle.Text = LongBody.Visible and "Show less" or "Show more"
        RuleDisplay.Size = UDim2.new(1, -12, 0, LongBody.Visible and 180 or 85)
    end)

    RuleDisplay.Visible = true
    RuleDisplay.Parent = RuleHolder
end

GuideButton.MouseButton1Click:Connect(function()
    GuideDisplay.Visible = not GuideDisplay.Visible
    if GuideDisplay.Visible then
        RulesDisplay.Visible = false
    end
end)

RulesButton.MouseButton1Click:Connect(function()
    RulesDisplay.Visible = not RulesDisplay.Visible
    if RulesDisplay.Visible then
        GuideDisplay.Visible = false
    end
end)