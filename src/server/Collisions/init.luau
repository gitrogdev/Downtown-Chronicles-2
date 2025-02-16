--This script handles all collision groups in the game
local PhysicsService = game:GetService("PhysicsService")

local GroupSettings = require(script.GroupSettings)

local collisionGroups = {}

local module = {}

---Creates a new collision group, using properties in `script.GroupSettings`
---@param group string The name of the collision group to be created
local function createGroup(group: string)
    PhysicsService:RegisterCollisionGroup(group)
    collisionGroups[group] = true

    if GroupSettings[group] then
        for collideGroup, status in pairs(GroupSettings[group]) do
            if not collisionGroups[collideGroup] then
                createGroup(collideGroup)
            end
            PhysicsService:CollisionGroupSetCollidable(
                group,
                collideGroup,
                status
            )
        end
    else
        warn(`{script}.Group:\z
            Group settings not found for collision group {group}`
        )
    end
end

---Adds a part to a collision group
---@param Part BasePart The part to add to the collision group
---@param group string The collision group to add the part to
module.Group = function(Part: BasePart, group: string)
    if not (collisionGroups[group] or group == "Default") then
        createGroup(group)
    end

    Part.CollisionGroup = group
end

---Adds all BaseParts in the Workspace to the Workspace collision group
module.Setup = function()
    for i, Child in ipairs(workspace:GetDescendants()) do
        if Child:IsA("BasePart") and Child.CanCollide == true then
            module.Group(Child, "Workspace")
        end
    end
end

return module