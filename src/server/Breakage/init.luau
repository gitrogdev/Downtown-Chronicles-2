--Handles all breakable parts
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local SoundIds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local breakable = {}

local module = {}

---Deal damage to a breakable part
---@param Part BasePart The part to damage or break
---@param damage number The amount of damage to deal
module.Damage = function(Part: BasePart, damage: number, Breaker: Player)
    local partData = breakable[Part]
    if not partData then
        return warn(`{script}.Damage: {Part:GetFullName()} is not breakable!`)
    end

    if partData.Integrity <= 0 then
        return warn(`{script}.Damage: {Part:GetFullName()} is already broken!`)
    end

    partData.Integrity -= damage
    if partData.Integrity <= 0 then
        if partData.Type == "Glass" then
            Part.CanCollide = false
            Part.CanQuery = false
            local originalTransparency = Part.Transparency
            Part.Transparency = 1

            local Tool = Part.Parent
            if Tool:IsA("Tool") then
                Part.Parent = workspace
                Tool:Destroy()
            end

            for i, Child in pairs(Part:GetChildren()) do
                if Child:GetAttribute("OnSurface") then
                    Child:Destroy()
                end
            end

            local BreakSound = Util.CreateInstance("Sound", {
                Parent = Part;
                RollOffMaxDistance = damage * 10;
                SoundId = SoundIds.GlassShatter;
                Volume = 1;
            })

            BreakSound.Ended:Once(function()
                BreakSound:Destroy()
            end)

            BreakSound:Play()

            if Breaker and Part:GetAttribute("Holy") then
                Breaker.Character:SetAttribute("Deicide", true)
            end

            task.spawn(function()
                task.wait(1000)
                Part.CanCollide = true
                partData.Integrity = Part.Size.Magnitude
                    * Part.CurrentPhysicalProperties.Density
                Part.Transparency = originalTransparency
            end)
        end
    end
end

---Finds and sets up all breakable materials in the workspace
module.Setup = function()
    for i, Child in ipairs(workspace.Map:GetDescendants()) do
        if
            Child:IsA("BasePart")
            and Child.Material == Enum.Material.Glass
            and Child.Transparency > 0
        then
            breakable[Child] = {
                Integrity = Child.Size.Magnitude
                    * Child.CurrentPhysicalProperties.Density;
                Part = Child;
                Type = "Glass";
            }
            Child:SetAttribute("Breakable", true)
        end
    end
end

return module