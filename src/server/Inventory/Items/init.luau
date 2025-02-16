--This script handles the management of tools on the server
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemData = require(script.Items)

local ServerScripts = ServerScriptService.ServerScripts
local WebhookHandler = require(ServerScripts.Webhooks)

local cache = {}
local module = {}

module.Items = ItemData

---Creates a new item
---@param filename string The file name of the item
---@param source string The source which is creating the item (for logging)
---@param attributes table The attributes to create the item with
---@param guid string The GUID assigned to the item (assigns if empty)
---@return Tool
module.new = function(
    filename: string,
    source: string,
    attributes: table,
    guid: string
)
    local itemData = ItemData[filename]

    if not filename then
        return warn(
            `{script}.new: \z
            No item data found for item with file name {filename}`
        )
    end

    local Item = itemData.Setup(attributes, itemData)
    Item.CanBeDropped = false
    Item.Name = guid or HttpService:GenerateGUID(false)

    if not guid then
        WebhookHandler.Post(
            `Initialized item {filename} ({Item:GetAttribute("DisplayName")}) \z
            with GUID {Item.Name}. Source: {source or "Unknown"}`,
            "GuidLog"
        )
    end

    Item:SetAttribute("DontDrop", itemData.DontDrop)
    Item:SetAttribute("DontSave", itemData.DontSave)
    Item:SetAttribute("FileName", filename)
    if not Item:GetAttribute("Weight") then
        Item:SetAttribute("Weight", itemData.Weight or 1)
    end
    module.Cache(Item)

    return Item
end

---Adds an item to the cache and listens for attribute changes
---@param Item Tool The item to add to the cache
module.Cache = function(Item: Tool)
    cache[Item.Name] = table.clone(Item:GetAttributes())

    Item.AttributeChanged:Connect(function(attribute: string)
        cache[Item.Name][attribute] = Item:GetAttribute(attribute)
    end)
end

---Get an item's cached attributes
---@param guid string The GUID of the item to get the attributes of
---@return table
module.GetCache = function(guid: string)
    return cache[guid]
end

return module