--The /spawn command for giving an item to the executor
local ServerScriptService = game:GetService("ServerScriptService")

local ScriptStorage = ServerScriptService.ServerScripts
local InventoryHandler = require(ScriptStorage.Inventory)
local ServerConfig = ScriptStorage.Configuration

local PlaceIds = require(ServerConfig.Places)

local command = {
    PrimaryAlias = "/spawn";
    SecondaryAlias = "/sp";
    
    PermissionLevel = 5;
    ArgSequence = {
        "string"
    };
    RequireAlive = true;
    Execute = function(Player: Player, filename: string)
        local itemData = InventoryHandler.Items.Items[filename]
        if not itemData then
            return `No item found with file name {filename}`
        end

        if itemData.DontSpawn then
            return `The item with file name {filename} can not be spawned!`
        end

        InventoryHandler.Add(Player, InventoryHandler.Items.new(
            filename,
            `{Player} (/spawn){game.PlaceId == PlaceIds.DevPlace and
            " in the development place" or ""}`
        ))
        return `Spawned item with file name {filename} for {Player}!`
    end
}

return command