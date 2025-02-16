--This script handles stamina, jumping, and sprinting on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Animator = require(ScriptStorage.Animator)
local ReplicatedCommunication = ScriptStorage.Communication
local Util = require(ScriptStorage.Util)

local LimitSpeed = ReplicatedCommunication.LimitSpeed

local SprintAnimation = Animator.new("Sprint")
local SprintAnimTrack

local speedMods = {}

local module = {}

local nextJump = 0
local staminaLoss = -1

UserInputService.InputBegan:Connect(function(
    Input: InputObject,
    gameProcessed: boolean
)
    if gameProcessed
        or not module.Humanoid
        or module.Humanoid:GetAttribute("Sprinting")
        or module.Humanoid:GetAttribute("Stamina") < 3
    then
        return
    end

    if
        Input.KeyCode == Enum.KeyCode.LeftShift and Util.GetWeight(Player) < 30
    then
        module.Humanoid:SetAttribute("Sprinting", true)

        if module.CalculateSpeed(module.Humanoid) == 0 then
            return module.Humanoid:SetAttribute("Sprinting", false)
        end

        SprintAnimTrack = Animator.Play(module.Humanoid, SprintAnimation)
    end
end)

UserInputService.InputEnded:Connect(function(
    Input: InputObject,
    gameProcessed: boolean
)
    if gameProcessed or not module.Humanoid then
        return
    end

    if Input.KeyCode == Enum.KeyCode.LeftShift then
        module.Humanoid:SetAttribute("Sprinting", false)

        if SprintAnimTrack then
            SprintAnimTrack:Stop()
            SprintAnimTrack = nil
        end
    end
end)

---Starts applying the speed and stamina modifiers
---@param Humanoid Humanoid The Humanoid to apply the modifiers to
module.Apply = function(Humanoid: Humanoid)
    local JUMP_POWER = Humanoid.JumpPower
    local MAX_STAMINA = Player:GetAttribute("MaxStamina") or 30
    Humanoid:SetAttribute("Stamina", MAX_STAMINA)
    Humanoid.UseJumpPower = true
    module.Humanoid = Humanoid
    
    if module.Heartbeat then
        module.Heartbeat:Disconnect()
    end

    Humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        if not Humanoid.Jump then
            return
        end

        if Humanoid.JumpPower == 0 then
            Humanoid.Jump = false
            return
        end

        local stamina = Humanoid:GetAttribute("Stamina") - 3
        nextJump = os.time() + 3
        if stamina < 0 then
            stamina = 0
        end

        Humanoid:SetAttribute("Stamina", stamina)
    end)

    module.Heartbeat = RunService.Heartbeat:Connect(function(time: number)
        local stamina = Humanoid:GetAttribute("Stamina")
        stamina += time * (
            (
                Humanoid:GetAttribute("Sprinting")
                and Humanoid.RootPart.AssemblyLinearVelocity.Magnitude > 10
                and staminaLoss
            ) or 1
        )

        if stamina < 0 then
            Humanoid:SetAttribute("Sprinting", false)
            Humanoid:SetAttribute("Stamina", 0)

            if SprintAnimTrack then
                SprintAnimTrack:Stop()
                SprintAnimTrack = nil
            end
        elseif stamina > MAX_STAMINA then
            Humanoid:SetAttribute("Stamina", MAX_STAMINA)
        else
            Humanoid:SetAttribute("Stamina", stamina)
        end

        Humanoid.JumpPower = (stamina < 5 and 0) or (nextJump > os.time() and 0)
            or (Humanoid:GetAttribute("DontJump") and 0) or JUMP_POWER
        Humanoid.WalkSpeed = module.CalculateSpeed(Humanoid)
    end)
end

---Calculates the WalkSpeed of a Humanoid
---@param Humanoid Humanoid The Humanoid to calculate the WalkSpeed of
---@return number
module.CalculateSpeed = function(Humanoid: Humanoid)
    local speed = 16
    staminaLoss = -1

    local weight = Util.GetWeight(Player)

    if weight > 5 then
        --Increase the rate at which stamina is lost
        staminaLoss = -weight / 5
        if weight > 10 then
            --Lower the base speed
            speed = (60 - (weight - 10)) / 2.5
            if speed < 0 then
                speed = 0
            elseif speed > 16 then
                speed = 16
            end
        end
    end

    local canSprint = true
    for key, modData in pairs(speedMods) do
        if not (Humanoid:GetAttribute("Sprinting") and modData.CanSprint) then
            speed *= modData.Modifier
        end

        if not modData.CanSprint then
            canSprint = false
        end
    end

    if canSprint and Humanoid:GetAttribute("Sprinting") then
        speed *= 1.5
    end

    --Slows down elderly players
    if Util.GetAge(Player) > 64 then
        speed *= 0.75
        staminaLoss *= 1.25
    end

    return speed
end

---Stops updating WalkSpeed and stamina
module.Kill = function()
    if module.Heartbeat then
        module.Heartbeat:Disconnect()
    end

    module.Humanoid = nil
    speedMods = {}
end

---Limit the speed of the character
---@param key string
---@param mod number
LimitSpeed.Event:Connect(function(key: string, mod: number, canSprint: boolean)
    if mod then
        speedMods[key] = {
            CanSprint = canSprint;
            Modifier = mod;
        }
    else
        speedMods[key] = nil
    end
end)

return module