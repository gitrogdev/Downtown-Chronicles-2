--This script handles the playback of all animations
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = require(script.Animations)

local Player = Players.LocalPlayer

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Util = require(ScriptStorage.Util)

local bindings = {}

local characterAdded = function(Character: Model)
    local childAdded = function(Child: Instance)
        if Child:IsA("Tool") then
            Child.AncestryChanged:Once(function()
                if bindings[Child] then
                    for i, AnimTrack in ipairs(bindings[Child]) do
                        AnimTrack:Stop()
                    end
                end
            end)
        end
    end
    local Tool = Character:FindFirstChildOfClass("Tool")
    if Tool then
        childAdded(Tool)
    end
    Character.ChildAdded:Connect(childAdded)
end
if Player.Character then
    characterAdded(Player.Character)
end
Player.CharacterAdded:Connect(characterAdded)

local module = {}

---Creates a new animation
---@param animName string The file name of the Animation to create
---@return Animation
module.new = function(animName: string)
    local animData = Animations[animName]
    if not animData then
        return warn(`{script}.new: No animation found with key {animName}!`)
    end

    local Animation = Util.CreateInstance("Animation", {
        AnimationId = animData.Id;
    })
    return Animation
end

---Plays an Animation on a Humanoid
---@param Humanoid Humanoid The Humanoid to play the Animation on
---@param Animation Animation The Animation to play
---@param BoundTo Tool The Tool to bind the animation to
---@return AnimationTrack
module.Play = function(
    Humanoid: Humanoid, Animation: Animation, BoundTo: Tool
)
    local Animator = Humanoid:FindFirstChildWhichIsA("Animator")
    if not Animator then
        return warn(`{script}.Play: No animator found!`)
    end

    local AnimTrack = Animator:LoadAnimation(Animation)
    AnimTrack:Play()

    if BoundTo then
        bindings[BoundTo] = bindings[BoundTo] or {}
        table.insert(bindings[BoundTo], AnimTrack)
    end
    
    return AnimTrack
end

return module