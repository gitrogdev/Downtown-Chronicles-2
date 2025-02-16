--Handles the operation of a firearm on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Tool = script.Parent
local FiringMechanism = require(script:WaitForChild("Firing"))

local Handle = Tool:WaitForChild("Handle")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Animator = require(ReplicatedScripts.Animator)
local ReplicatedCommunication = ReplicatedScripts.Communication

local ChamberWeapon = ReplicatedCommunication.ChamberWeapon
local FireSelector = ReplicatedCommunication.FireSelector
local InitializeFirearm = ReplicatedCommunication.InitializeFirearm
local GetConfig = ReplicatedCommunication.FirearmConfig
local ReloadWeapon = ReplicatedCommunication.ReloadWeapon

local CONFIG = GetConfig:InvokeServer(Tool)
InitializeFirearm:FireServer(Tool)

local AimAnimation = Animator.new(CONFIG.Animations.Aim)
local ArmsBack = Animator.new("ArmsBack")
local ChamberAnimation = Animator.new(CONFIG.Animations.Chamber)
local HoldAnimation = Animator.new(CONFIG.Animations.Hold)
local LoadAnimation = Animator.new(CONFIG.Animations.Load)
local ProneAnimation = Animator.new(CONFIG.Animations.Prone)
local UnloadAnimation = Animator.new(CONFIG.Animations.Unload)
local ArmsBackTrack, IdleAnimTrack

local firing, lowered
local nextShot = tick()
Humanoid:GetAttributeChangedSignal("Prone"):Connect(function()
    local prone: boolean = (Humanoid:GetAttribute("Prone") or 0) > 0
    lowered = false
    UserInputService.MouseIconEnabled = false

    if prone then
        if IdleAnimTrack then
            IdleAnimTrack:Stop()
        end
        IdleAnimTrack = Animator.Play(Humanoid, ProneAnimation, Tool)
    else
        if ArmsBackTrack then
            ArmsBackTrack:Stop()
        end

        if IdleAnimTrack then
            IdleAnimTrack:Stop()
        end
        IdleAnimTrack = Animator.Play(Humanoid, AimAnimation, Tool)
    end
end)

Tool.Activated:Connect(function()
    if Character:GetAttribute("Drawing") then
        return warn(`{script}.Activated: Firearm still being drawn!`)
    end

    if tick() < nextShot then
        return warn(`{script}.Activated: Exceeds rate of fire limit!`)
    end

    if firing then
        return warn(`{script}.Activated: Already firing!`)
    end

    if lowered and (Humanoid:GetAttribute("OverrideLower") or 0) == 0 then
        return warn(`{script}.Activated: Weapon lowered!`)
    end

    local firemode = Tool:GetAttribute("Conversion")
        or CONFIG.Firemodes[Tool:GetAttribute("Firemode") or 1]
    if firemode == "Safe" then
        return warn(`{script}.Activated: Safety on!`)
    end

    firing = true
    while firing do
        nextShot = tick()
            + (60 / (Tool:GetAttribute("FireRate") or CONFIG.FireRate))
        local result = FiringMechanism.Fire(CONFIG, Tool, Humanoid)
        if not result then
            break
        end

        firemode = Tool:GetAttribute("Conversion")
            or CONFIG.Firemodes[Tool:GetAttribute("Firemode") or 1]
        if firemode == "Auto" then
            task.wait(nextShot - tick())
        else
            break
        end
    end
    firing = false
end)

Tool.Deactivated:Connect(function()
    firing = false
end)

Tool.Equipped:Connect(function()
    if Character:GetAttribute("Drawing") then
        Character:GetAttributeChangedSignal("Drawing"):Wait()
    end

    local prone: boolean = (Humanoid:GetAttribute("Prone") or 0) > 0
    IdleAnimTrack = Animator.Play(
        Humanoid,
        (lowered and HoldAnimation) or (prone and ProneAnimation)
        or AimAnimation,
        Tool
    )
    UserInputService.MouseIconEnabled = lowered
end)

Tool.Unequipped:Connect(function()
    firing = false
    UserInputService.MouseIconEnabled = true
end)

UserInputService.InputBegan:Connect(function(
    Input: InputObject, gameProcessed: boolean
)
    if gameProcessed then
        return
    end

    if Tool.Parent ~= Character then
        return
    end

    if Tool:GetAttribute("InAction") then
        return warn(`{script}.InputBegan: In action!`)
    end

    if Input.KeyCode == Enum.KeyCode.F then
        ChamberWeapon:FireServer(Tool)
    elseif Input.KeyCode == Enum.KeyCode.G then
        if (Humanoid:GetAttribute("Prone") or 0) > 0 then
            return
        end

        lowered = not lowered
        if IdleAnimTrack then
            IdleAnimTrack:Stop()
        end
        IdleAnimTrack = Animator.Play(
            Humanoid, lowered and HoldAnimation or AimAnimation, Tool
        )
        UserInputService.MouseIconEnabled = lowered
    elseif Input.KeyCode == Enum.KeyCode.R then
        ReloadWeapon:FireServer(Tool)
    elseif Input.KeyCode == Enum.KeyCode.V then
        if #CONFIG.Firemodes > 1 and not Tool:GetAttribute("Conversion") then
            FireSelector:FireServer(Tool)
        end
    end
end)

Tool:GetAttributeChangedSignal("Chambering"):Connect(function()
    if Tool.Parent ~= Character then
        return
    end

    local status = Tool:GetAttribute("Chambering")
    if status then
        local prone: boolean = (Humanoid:GetAttribute("Prone") or 0) > 0
        if prone then
            if ArmsBackTrack then
                ArmsBackTrack:Stop()
            end
            ArmsBackTrack = Animator.Play(Humanoid, ArmsBack, Tool)
        end

        Animator.Play(Humanoid, ChamberAnimation, Tool).Ended:Once(function()
            if ArmsBackTrack then
                ArmsBackTrack:Stop()
            end
        end)
    end
end)

Tool:GetAttributeChangedSignal("Reloading"):Connect(function()
    if Tool.Parent ~= Character then
        return
    end

    local prone: boolean = (Humanoid:GetAttribute("Prone") or 0) > 0
    local status = Tool:GetAttribute("Reloading")
    if status == "In" then
        if prone then
            if ArmsBackTrack then
                ArmsBackTrack:Stop()
            end
            ArmsBackTrack = Animator.Play(Humanoid, ArmsBack, Tool)
        end

        Animator.Play(Humanoid, LoadAnimation, Tool).Ended:Once(function()
            if ArmsBackTrack then
                ArmsBackTrack:Stop()
            end
        end)
    elseif status == "Out" then
        if prone then
            if ArmsBackTrack then
                ArmsBackTrack:Stop()
            end
            ArmsBackTrack = Animator.Play(Humanoid, ArmsBack, Tool)
        end

        Animator.Play(Humanoid, UnloadAnimation, Tool).Ended:Once(function()
            if ArmsBackTrack then
                ArmsBackTrack:Stop()
            end
        end)
    end
end)