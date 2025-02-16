--Handles the creation of all explosions
local module = {}

local Types = {}
for i, Handler in ipairs(script:GetChildren()) do
    Types[Handler.Name] = require(Handler)
end

---Creates an explosion
---@param explosionType string The type of explosion to create
---@param position Vector3 The position of the explosion in the world
---@param properties table Any properties to apply to the explosion
---@return any
module.new = function(
    explosionType: string,
    position: Vector3,
    properties: table
)
    local TypeHandler = Types[explosionType]
    if not TypeHandler then
        return warn(
            `{script}.new: Explosion type {explosionType} not recognized!`
        )
    end

    if not position then
        return warn(`{script}.new: Position must be specified!`)
    end

    properties = properties or {}
    for key, value in pairs(TypeHandler.Default) do
        if typeof(value) == "table" then
            properties[key] = properties[key] or {}
            for subkey, subvalue in pairs(value) do
                properties[key][subkey] = properties[key][subkey] or subvalue
            end
        else
            properties[key] = properties[key] or value
        end
    end

    return TypeHandler.new(position, properties)
end

return module