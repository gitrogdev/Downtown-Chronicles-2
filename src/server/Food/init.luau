---Handles all food on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local FoodClient = script.Food

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local ConsumeFood = ReplicatedCommunication.ConsumeFood

local FoodConfig = require(ReplicatedConfig.Food)
local ItemConfig
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local PartStorage = ServerStorage.Parts
local ToolStorage = PartStorage.Tools

---Consume a food item
---@param Player Player The Player consuming the food
---@param Food Tool The food to be consumed
---@return boolean
ConsumeFood.OnServerInvoke = function(Player: Player, Food: Tool)
    local Tool = Player.Character
        and Player.Character:FindFirstChildOfClass("Tool")
    if not (Tool and Tool == Food) then
        return warn(
            `{script}.ConsumeFood.OnServerInvoke: {Player} tried to consume \z
            {Food}, but has {Tool} equipped!`
        )
    end

    local config = FoodConfig[Tool:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.ConsumeFood.OnServerInvoke: {Player} tried to consume \z
            an unknown food ({Food})!`
        )
    end

    local uses = Food:GetAttribute("Uses") or 0
    if uses < 1 then
        return warn(
            `{script}.ConsumeFood.OnServerInvoke: {Player} tried to consume \z
            {Food}, but it was already completely consumed!`
        )
    end

    if Player:GetAttribute("Consuming") then
        return warn(
            `{script}.ConsumeFood.OnServerInvoke: {Player} is already \z
            consuming another food item!`
        )
    end

    Food:SetAttribute("Uses", uses - 1)
    Player:SetAttribute("Consuming", true)
    
    local Handle = Food:FindFirstChild("Handle")
        if Handle then
        local ConsumeSound = Util.CreateInstance("Sound", {
            Parent = Handle;
            RollOffMaxDistance = 30;
            SoundId = Sounds[config.Sound];
            Volume = 0.5;
        })

        ConsumeSound.Ended:Once(function()
            if uses == 1 then
                if config.OnEmpty.Delete then
                    return Tool:Destroy()
                end

                if config.OnEmpty.DestroyParts then
                    for i, Child in ipairs(config.OnEmpty.DestroyParts) do
                        if Tool:FindFirstChild(Child) then
                            Tool[Child]:Destroy()
                        end
                    end
                end

                if config.OnEmpty.ReplaceWith then
                    Tool:SetAttribute("FileName", config.OnEmpty.ReplaceWith)
                    Tool:SetAttribute(
                        "DisplayName",
                        ItemConfig[config.OnEmpty.ReplaceWith].DisplayName
                    )
                end
            end
            ConsumeSound:Destroy()
        end)

        ConsumeSound:Play()
    end

    task.wait(config.Time)
    Player:SetAttribute("Consuming", false)
    return true
end

local module = {}

---Create a local reference to ItemConfig
---@param config table The ItemConfig module
module.ICPass = function(config: table)
    ItemConfig = config
end

---Create a new food item
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.new = function(attributes: table, itemData: table)
    local config = FoodConfig[itemData.Name]
    if not config then
        return warn(`{script}.new: Unknown food item {itemData.Name}!`)
    end
    attributes = attributes or {
        Uses = config.Uses;
    }

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    FoodClient:Clone().Parent = Tool
    return Tool
end

return module