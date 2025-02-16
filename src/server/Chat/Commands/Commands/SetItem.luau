--The /set command used for dropping items without adjusting the CFrame
local ServerScriptService = game:GetService("ServerScriptService")

local ScriptStorage = ServerScriptService.ServerScripts
local InventoryHandler = require(ScriptStorage.Inventory)
local Util = require(ScriptStorage.Util)

local command = {
    PrimaryAlias = "/set";
    
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
        if InventoryHandler.Drop(Item, Item.Handle.CFrame) then
            if filename == "Corpse" then
                return "Successfully dropped corpse."
            end

            Util.RoleplayAction(
                Head,
                `*$\{Associated} has set {Util.AOrAn(itemName)} {itemName} \z
                onto the ground.`
            )
            return `Set {itemName} onto the ground.`
        else
            return `Unable to set down item {itemName}.`
        end
    end
}

return command