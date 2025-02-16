--Handles all melee weapons
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ServerScripts = ServerScriptService.ServerScripts

local Util = require(ServerScripts.Util)

local PartStorage: Folder = ServerStorage.Parts
local ToolStorage: Folder = PartStorage.Tools

local MeleeConfig = require(script.Melees)

local module = {}

---Creates a new melee weapon
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.new = function(attributes: table, itemData: table): Tool
    local config: table = MeleeConfig[itemData.Name]
    if not config then
        return warn(`{script}.new: Unknown melee weapon {itemData.Name}!`)
    end
    attributes = attributes or {}

    attributes.DisplayName = itemData.DisplayName
    local Tool: Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child: Instance in ipairs(
        ToolStorage[itemData.Name]:GetChildren()
    ) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    return Tool
end

return module