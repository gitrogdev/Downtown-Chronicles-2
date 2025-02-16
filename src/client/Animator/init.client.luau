--Handles animations on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Animator = require(ReplicatedScripts.Animator)
local ReplicatedCommunication = ReplicatedScripts.Communication

local Animations = require(ReplicatedScripts.Animator.Animations)

local LimitSpeed = ReplicatedCommunication.LimitSpeed
local PlayAnimation = ReplicatedCommunication.PlayAnimation

local TextChatCommands: Folder = TextChatService:WaitForChild(
    "TextChatCommands"
)
local RBXEmoteCommand: TextChatCommand = TextChatCommands:WaitForChild(
    "RBXEmoteCommand"
)

local AnimationCache = {}
local CommandAnimations = {}
local KeyboundAnimations = {}
local PlayingCommandAnimations = {}
local STACK_EFFECTS = {
    "Crouch";
    "LockArms";
    "OverrideLower";
    "PreventDraw";
    "Prone";
}
local STOP_KEYS = {
    sa = true;
    stop = true;
    stopanimation = true;
}

for key, animData in pairs(Animations) do
    AnimationCache[key] = Animator.new(key)

    if animData.Keybind then
        KeyboundAnimations[animData.Keybind] = {
            Animation = AnimationCache[key];
            Data = animData;
            Key = key;
        }
    end

    if animData.CommandKeys then
        for i, commandKey: string in ipairs(animData.CommandKeys) do
            CommandAnimations[commandKey] = {
                Animation = AnimationCache[key];
                Data = animData;
                Key = key;
            }
        end
    end
end

local Chatted, InputBegan, InputEnded, OnPlay, Seated
Player.CharacterAdded:Connect(function(Character: Model)
    local Humanoid = Character:WaitForChild("Humanoid")

    local function stopAnimations(cuffed: boolean)
        for i, PlayingAnim in ipairs(PlayingCommandAnimations) do
            if PlayingAnim and PlayingAnim.AnimTrack then
                if cuffed and PlayingAnim.Data.ContinueOnCuffed then
                    continue
                end

                PlayingAnim.AnimTrack:Stop()
                if PlayingAnim.Data.SpeedMod then
                    LimitSpeed:Fire(PlayingAnim.Key)
                end

                for j, effect: string in ipairs(STACK_EFFECTS) do
                    if PlayingAnim.Data[effect] then
                        Humanoid:SetAttribute(
                            effect, (Humanoid:GetAttribute(effect) or 1) - 1
                        )
                    end
                end
            end
        end
        PlayingCommandAnimations = {}
    end

    Character:GetAttributeChangedSignal("Cuffed"):Connect(function()
        if not Character:GetAttribute("Cuffed") then
            return
        end

        stopAnimations(true)
    end)

    Chatted = RBXEmoteCommand.Triggered:Connect(function(
        Origin: TextSource, message: string
    )
        local Executor: Player = Players:GetPlayerByUserId(Origin.UserId)
        if Executor ~= Player then
            return
        end

        local startPos = message:find(" ")
        if not startPos then
            return
        end
        startPos += 1

        local animKey = message:sub(startPos)
        local Animation: table = CommandAnimations[animKey]
        if Animation then
            if
                Character:GetAttribute("Cuffed")
                and not Animation.ContinueOnCuffed
            then
                return
            end

            --Prevents stacking of animations
            if Animation.AnimTrack then
                Animation.AnimTrack:Stop()
            end
            stopAnimations()

            table.insert(PlayingCommandAnimations, Animation)

            Animation.AnimTrack = Animator.Play(
                Humanoid, Animation.Animation
            )
            if Animation.Data.SpeedMod then
                LimitSpeed:Fire(
                    Animation.Key,
                    Animation.Data.SpeedMod,
                    Animation.Data.CanSprint
                )
            end

            for i, effect: string in ipairs(STACK_EFFECTS) do
                if Animation.Data[effect] then
                    Humanoid:SetAttribute(
                        effect, (Humanoid:GetAttribute(effect) or 0) + 1
                    )
                end
            end
        elseif STOP_KEYS[animKey] then
            stopAnimations()
        end
    end)

    InputBegan = UserInputService.InputBegan:Connect(function(
        Input: InputObject, gameProcessed: boolean
    )
        if gameProcessed then
            return
        end

        if Humanoid.Sit then
            return
        end

        local Animation = KeyboundAnimations[Input.KeyCode]
        local crouch: boolean = (Humanoid:GetAttribute("Crouch") or 0) > 0
        local prone: boolean = (Humanoid:GetAttribute("Prone") or 0) > 0
        if Animation and not (crouch or prone) then
            --Prevents stacking of animations
            if Animation.AnimTrack then
                Animation.AnimTrack:Stop()
            end

            Animation.AnimTrack = Animator.Play(
                Humanoid, Animation.Animation
            )
            if Animation.Data.SpeedMod then
                LimitSpeed:Fire(
                    Animation.Key,
                    Animation.Data.SpeedMod,
                    Animation.Data.CanSprint
                )
            end

            for i, effect: string in ipairs(STACK_EFFECTS) do
                if Animation.Data[effect] then
                    Humanoid:SetAttribute(
                        effect, (Humanoid:GetAttribute(effect) or 0) + 1
                    )
                end
            end
        end
    end)

    InputEnded = UserInputService.InputEnded:Connect(function(
        Input: InputObject, gameProcessed: boolean
    )
        if gameProcessed then
            return
        end

        local Animation = KeyboundAnimations[Input.KeyCode]
        if Animation and Animation.AnimTrack then
            Animation.AnimTrack:Stop()
            Animation.AnimTrack = nil
            if Animation.Data.SpeedMod then
                LimitSpeed:Fire(Animation.Key)
            end

            for i, effect: string in ipairs(STACK_EFFECTS) do
                if Animation.Data[effect] then
                    Humanoid:SetAttribute(
                        effect, (Humanoid:GetAttribute(effect) or 1) - 1
                    )
                end
            end
        end
    end)

    OnPlay = PlayAnimation.OnClientEvent:Connect(function(key: string)
        Animator.Play(
            Humanoid, AnimationCache[key]
        )
    end)

    Seated = Humanoid.Seated:Connect(function(active: boolean)
        if active then
            for keyCode, Animation in pairs(KeyboundAnimations) do
                if Animation.AnimTrack then
                    Animation.AnimTrack:Stop()
                    if Animation.Data.SpeedMod then
                        LimitSpeed:Fire(Animation.Key)
                    end
                end
            end
        end
    end)

    Humanoid.Died:Once(function()
        Chatted:Disconnect()
        InputBegan:Disconnect()
        InputEnded:Disconnect()
        OnPlay:Disconnect()
        Seated:Disconnect()
        stopAnimations()
    end)
end)