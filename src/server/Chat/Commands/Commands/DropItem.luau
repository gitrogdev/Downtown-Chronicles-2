--The /drop command used for dropping items
local ServerScriptService = game:GetService("ServerScriptService")

local ScriptStorage = ServerScriptService.ServerScripts
local InventoryHandler = require(ScriptStorage.Inventory)
local Util = require(ScriptStorage.Util)

local command = {
    PrimaryAlias = "/drop";
    
    PermissionLevel = 0;
    RequireAlive = true;
    Execute = function(Player: Player)
        local Head = Player.Character:FindFirstChild("Head")
        if not Head then
            return "Character does not have a head!"
        end

        local Item = Player.Character:FindFirstChildWhichIsA("Tool")
        if not Item then
            return "Not currently holding an item!"
        end

        if Item:GetAttribute("InAction") then
            return "Item is currently in action!"
        end

        local filename = Item:GetAttribute("FileName")
        local itemName = Item:GetAttribute("DisplayName")
            or filename
            or Item.Name
        if InventoryHandler.Drop(
            Item,
            Head.CFrame:ToWorldSpace(CFrame.new(0, 0, -3))
        ) then
            if filename == "Corpse" then
                return "Successfully dropped corpse."
            end

            Util.RoleplayAction(
                Head,
                `*$\{Associated} has dropped {Util.AOrAn(itemName)} \z
                {itemName} onto the ground.`
            )
            return `Dropped {itemName} onto the ground.`
        else
            return `Unable to drop item {itemName}.`
        end
    end
}

return command