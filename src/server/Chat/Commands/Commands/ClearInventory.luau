--The /clearinventory command used for clearing a player's inventnory
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local InventoryConfig = require(ReplicatedConfig.Inventory)

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local WebhookHandler = require(ServerScripts.Webhooks)

local STARTER_PACK = {}
for i, StarterItem: string in ipairs(InventoryConfig.StarterPack) do
    STARTER_PACK[StarterItem] = true
end

local command = {
    PrimaryAlias = "/clearinventory";
    SecondaryAlias = "/clearinv";
    
    PermissionLevel = 3;
    ArgSequence = {
        "CharacterID"
    };
    Execute = function(Player: Player, toClear: number)
        local ClearPlayer: Player
        for i, CheckPlayer: Player in ipairs(Players:GetPlayers()) do
            if CheckPlayer:GetAttribute("ID") == toClear then
                ClearPlayer = CheckPlayer
                break
            end
        end

        local function log(name: string)
            WebhookHandler.Post(
                `{Player} has cleared the inventory of {name} ({toClear}).`,
                "ModLog"
            )
        end

        if ClearPlayer then
            local Equipped: Tool = ClearPlayer.Character
                and ClearPlayer.Character:FindFirstChildOfClass("Tool")
            if Equipped then
                Equipped:Destroy()
            end

            local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
            if Inventory then
                for slot, guid in pairs(Inventory:GetAttributes()) do
                    local Item: Tool = Inventory:FindFirstChild(guid)
                    if Item then
                        if STARTER_PACK[Item:GetAttribute("FileName")] then
                            continue
                        end

                        Inventory:SetAttribute(slot, nil)
                        Item:Destroy()
                    end
                end

                log(ClearPlayer:GetAttribute("FullName"))
                return `Inventory cleared for \z
                    {ClearPlayer:GetAttribute("FullName")} ({toClear}).`
            end
        else
            local fullName: string
            DataHandler.Update("Characters", tostring(toClear),
            function(charData: table)
                charData.Equipped = nil
                charData.Inventory = nil

                fullName = `{charData.FirstName} {charData.LastName}`

                return charData
            end)

            log(fullName)
            return `Inventory cleared for {fullName} ({toClear}).`
        end
    end
}

return command