---This script contains general utility functions for server-side scripts
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local ReplicatedUtil = require(ReplicatedScripts.Util)

local ClothingConfig = require(ReplicatedConfig.Clothing)

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)

local PartStorage = ServerStorage.Parts
local UIStorage = ServerStorage.UserInterface

local AccessoryStorage: Folder = PartStorage.Accessories

local RoleplayText: BillboardGui = UIStorage.RPText

local module = table.clone(ReplicatedUtil)

---Equip an accessory from config for a character
---@param Character Model The character to equip the accessory for
---@param key string The key of the accessory
---@return PVInstance
module.EquipAccessory = function(Character: Model, key: string): PVInstance
    local accessoryConfig: table = ClothingConfig[key]
    if not accessoryConfig then
        return warn(
            `{script}.EquipAccessory: No config found with key "{key}"!`
        )
    end

    local Accessory: Instance = AccessoryStorage:FindFirstChild(key)
    if not Accessory then
        return warn(
            `{script}.EquipAccessory: No accessory found with key "{key}"!`
        )
    end

    local Attach: PVInstance = Accessory:Clone()
    if Attach:IsA("Model") then
        local AttachTo: Part = Character:FindFirstChild(
            accessoryConfig.AttachesTo
        )
        module.WeldChildren(Attach, Attach.PrimaryPart, true, true)
        Attach:PivotTo(AttachTo.CFrame)
        module.WeldTo(Attach.PrimaryPart, AttachTo)
    end
    Attach.Parent = Character
    
    local hid = {}
    while accessoryConfig.HidesHair and (
        module.FindFirstChildWithAttributes(Character, {Hair = true})
        or module.FindFirstChildWithAttributes(Character, {FacialHair = true})
    ) do
        local Target: Accessory = (
            module.FindFirstChildWithAttributes(Character, {Hair = true}) or
            module.FindFirstChildWithAttributes(Character, {FacialHair = true})
        )
        table.insert(hid, Target)
        Target.Parent = nil
    end

    if accessoryConfig.HidesHair and #hid > 0 then
        Attach.AncestryChanged:Connect(function()
            if not Attach.Parent then
                for i, Reapply: Accessory in ipairs(hid) do
                    Reapply.Parent = Character
                end
            end
        end)
    end

    if accessoryConfig.Mask then
        local Player: Player = Players:GetPlayerFromCharacter(Character)
        if Player then
            Player:SetAttribute("Masked", true)
            Attach.AncestryChanged:Connect(function()
                if not Attach.Parent then
                    Player:SetAttribute("Masked", nil)
                end
            end)
        end
    end
    
    return Attach
end

---Displays a roleplay action
---@param Source Part The part to display the roleplay action over
---@param text string The text to display in the roleplay action
module.RoleplayAction = function(Source: Part, text: string)
    local ActionDisplay = Source:FindFirstChild(RoleplayText.Name)
        or RoleplayText:Clone()
    ActionDisplay:WaitForChild("Display").Text = text
    ActionDisplay.Parent = Source
    CollectionService:AddTag(ActionDisplay, "RoleplayText")

    --Prevents stacking of multiple actions
    task.spawn(function()
        if ActionDisplay:GetAttribute("Decay") then
            ActionDisplay:SetAttribute("Decay", os.time() + 8)
        else
            ActionDisplay:SetAttribute("Decay", os.time() + 8)
            while ActionDisplay:GetAttribute("Decay") > os.time() do
                task.wait(1)
            end
            ActionDisplay:Destroy()
        end
    end)
end

---Assign a serial number to an item
---@param itemType string The item type to assign the serial number of
---@return number
module.Serialize = function(itemType: string)
    local serial

    DataHandler.Update("SerialNumbers", itemType, function(lastSerial: number)
        lastSerial = lastSerial or 0
        serial = lastSerial + 1
        lastSerial = serial
        return lastSerial
    end)

    return serial
end

return module