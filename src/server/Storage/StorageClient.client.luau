--Handles interaction with a storage unit on the server
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainGui: ScreenGui = script.Parent
local Background: Frame = MainGui:WaitForChild("Frame")
local UpdateContents: RemoteEvent = MainGui:WaitForChild("UpdateContents")

local Head: TextLabel = Background:WaitForChild("Head")

local Player = Players.LocalPlayer
local Inventory: Folder = Player.PlayerGui:WaitForChild("Inventory")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Util = require(ReplicatedScripts.Util)

local Contents = {
    Inventory = {};
    Storage = {};
}
local Holders = {
    Inventory = Background:WaitForChild("InventoryHolder");
    Storage = Background:WaitForChild("StorageHolder");
}
local WeightDisplays = {
    Inventory = Background:WaitForChild("InventoryWeight");
    Storage = Background:WaitForChild("StorageWeight");
}

---Update the contents of the inventory or storage
---@param list string The list to update the contents of (Inventory or Storage)
---@param contents table The new contents of the list
local function updateContents(list: string, contents: table)
    local Template: Frame = Holders[list]:WaitForChild("ItemTemplate")

    for i, Child in ipairs(Contents[list]) do
        Child:Destroy()
    end
    Contents[list] = {}

    local totalWeight = 0
    for i, itemData in ipairs(contents) do
        local Slot = Template:Clone()
        local MoveButton: TextButton = Slot:WaitForChild("MoveButton")
        local NameDisplay: TextLabel = Slot:WaitForChild("ItemName")
        local WeightDisplay: TextLabel = Slot:WaitForChild("Weight")

        local weight = itemData.Attributes.Weight or 0
        totalWeight += weight

        NameDisplay.Text = itemData.Attributes.DisplayName or itemData.FileName
        WeightDisplay.Text = `{Util.Round(weight, 2)} kg`

        MoveButton.MouseButton1Click:Connect(function()
            UpdateContents:FireServer(list, itemData.GUID)
        end)

        Slot.Visible = true
        Slot.Parent = Holders[list]
        table.insert(Contents[list], Slot)
    end
    WeightDisplays[list].Text = `{Util.Round(totalWeight, 2)}{
            list == "Storage"
            and `/{Util.Round(MainGui:GetAttribute("Capacity"), 2)}`
            or ""
        } kg`
end

---Update the contents of the inventory list
local function updateInventory()
    updateContents(
        "Inventory",
        Util.ExportInventory(Inventory, function(attributes: table)
            return not (attributes.DontDrop or attributes.DontSave)
        end)
    )
end

---Updates the contents of the storage unit
---@param contents table The contents of the storage unit in export form
UpdateContents.OnClientEvent:Connect(function(contents: table)
    updateContents("Storage", contents)
end)

Inventory.ChildAdded:Connect(updateInventory)
Inventory.ChildRemoved:Connect(updateInventory)
updateInventory()

Head.Text = MainGui:GetAttribute("DisplayName")