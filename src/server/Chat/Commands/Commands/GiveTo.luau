--The /giveto command for giving an item to other Players
local ServerScriptService = game:GetService("ServerScriptService")

local ScriptStorage = ServerScriptService.ServerScripts
local InventoryHandler = require(ScriptStorage.Inventory)
local ServerConfig = ScriptStorage.Configuration

local PlaceIds = require(ServerConfig.Places)

local command = {
    PrimaryAlias = "/giveto";
    SecondaryAlias = "/give";
    
    PermissionLevel = 5;
    ArgSequence = {
        "string";
        "Players";
    };

    Execute = function(Player: Player, filename: string, recipients: table)
        local itemData = InventoryHandler.Items.Items[filename]
        if not itemData then
            return `No item found with file name {filename}`
        end

        if itemData.DontSpawn then
            return `The item with file name {filename} can not be spawned!`
        end

        for i, Recipient in ipairs(recipients) do
            InventoryHandler.Add(
                Recipient,
                InventoryHandler.Items.new(
                    filename,
                    `{Player} (/giveto){game.PlaceId == PlaceIds.DevPlace and
                    " in the development place" or ""}`
                )
            )
        end
        return `Spawned item with file name {filename} for {#recipients} \z
            player{#recipients == 1 and "" or "s"}!`
    end
}

return command