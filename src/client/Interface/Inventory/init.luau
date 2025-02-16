--This script handles the inventory on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ScriptConfig = require(script.Config)

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local EquipTool = ReplicatedCommunication.EquipTool
local UnequipTool = ReplicatedCommunication.UnequipTool

local Util = require(ReplicatedScripts.Util)

local InventoryConfig = require(ReplicatedConfig.Inventory)

local Placeholders = {}
for i = 1, 9 do
    table.insert(Placeholders, Util.CreateInstance("Tool", {
        CanBeDropped = false
    }))
end

local module = {}

---Binds keybinds to equip items from the inventory
---@param Inventory ScreenGui The inventory to get items from
---@param Hotbar Frame The hotbar to display items in
module.Setup = function(Inventory: ScreenGui, Hotbar: Frame)
    local SlotTemplate = Hotbar:WaitForChild("SlotTemplate")
    local function loadHotbar(Item: Tool)
        for i, slot in ipairs(InventoryConfig.Slots) do
            if Inventory:GetAttribute(slot) == Item.Name then
                local HotbarSlot = SlotTemplate:Clone()
                HotbarSlot.Name = `Slot{i == 10 and "9a" or i}`

                HotbarSlot:WaitForChild("Keybind").Text = i == 10 and 0 or i
                HotbarSlot:WaitForChild("NameDisplay").Text =
                    Item:GetAttribute("DisplayName")
                    or Item:GetAttribute("FileName")
                    or Item.Name

                HotbarSlot.Visible = true
                HotbarSlot.Parent = Hotbar

                Item.AncestryChanged:Once(function()
                    HotbarSlot:Destroy()
                end)
                break
            end
        end
    end

    for i, Child in ipairs(Inventory:GetChildren()) do
        loadHotbar(Child)
    end
    Inventory.ChildAdded:Connect(loadHotbar)

    UserInputService.InputBegan:Connect(function(
        Input: InputObject,
        gameProcessed: boolean
    )
        if gameProcessed then
            return
        end
    
        local slotNum = ScriptConfig.SlotKeys[Input.KeyCode]
        if not slotNum then
            return
        end

        local Humanoid: Humanoid = Player.Character
            and Player.Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return
        end

        if (Humanoid:GetAttribute("PreventDraw") or 0) > 0 then
            return
        end

        local slot = InventoryConfig.Slots[slotNum]
        local guid = Inventory:GetAttribute(slot)
        local Equipped = (
                Player.Character or Player.CharacterAdded:Wait()
            ):FindFirstChildWhichIsA("Tool")

        if guid then
            slotNum -= 1
            if Equipped then
                slotNum -= 1
            end

            for i = 1, slotNum do
                Placeholders[i].Parent = Player.Backpack
            end

            EquipTool:InvokeServer(slot)

            for i, Placeholder in ipairs(Placeholders) do
                Placeholder.Parent = nil
            end
        elseif Equipped and (Equipped:GetAttribute("WasIn") == slot
            or not (Equipped:GetAttribute("WasIn") or guid))
        then
            UnequipTool:FireServer()
        end
    end)
end

return module