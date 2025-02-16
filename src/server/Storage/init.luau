--Handles all item storage units on the server
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(script.Config)
local StorageClient = script.StorageClient

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local SendNotification = ReplicatedCommunication.SendNotification

local ServerScripts = ServerScriptService.ServerScripts
local InventoryHandler = require(ServerScripts.Inventory)
local Util = require(ServerScripts.Util)

local ItemHandler = InventoryHandler.Items

local UIStorage = ServerStorage.UserInterface
local StorageGui = UIStorage.StorageGui

local module = {}

---Set up a new storage unit
---@param storageType string The key for the type of the storage being used
---@param key string The unique identifier of the storage unit (or a GUID)
---@param Attachment Attachment The Attachment for the opening ProximityPrompt
---@param stored table Any items stored in the storage unit (optional)
---@param lock function The function used for determining who can open the unit
---@return table
module.new = function(
    storageType: string,
    key: string,
    Attachment: Attachment,
    stored: table,
    lock: (Player) -> boolean
): table
    local storageConfig = Config.StorageTypes[storageType]
    if not storageConfig then
        return warn(`{script}.new: Unknown storage type "{storageType}"!`)
    end

    key = key or HttpService:GenerateGUID(false)

    if storageConfig.Locked and not lock then
        warn(
            `{script}.new: Storage unit {key} is marked as locked, but \z
            no lock function was provided! Until a lock function is provided \z
            with Storage.SetLock(), it will not be able to be opened!`
        )
    end

    stored = stored or {}

    local StorageFolder = Util.CreateInstance("Folder", {
        Name = key;
        Parent = ServerStorage:FindFirstChild("StoredItems") or
            Util.CreateInstance("Folder", {
                Name = "StoredItems";
                Parent = ServerStorage;
            })
    })

    for i, itemData in ipairs(stored) do
        ItemHandler.new(
            itemData.FileName,
            `Loaded contents of storage unit {key}`,
            itemData.Attributes,
            itemData.GUID
        ).Parent = StorageFolder
    end

    local Storage = {}

    ---Export the contents of the storage unit as a table for saving
    ---@return table
    Storage.Export = function(): table
        return Util.ExportInventory(StorageFolder, function(attributes: table)
            local itemData = ItemHandler.Items[attributes.FileName]
            if not itemData then
                warn(
                    `{script}.Export: Attempted to export unknown item with \z
                    the file name {attributes.FileName}`
                )
                return false
            end
            return true
        end)
    end

    ---Change the locking function for the storage unit
    ---@param newLock function The function to determine if it can be opened
    Storage.SetLock = function(newLock: (Player) -> boolean)
        lock = newLock
    end

    ---Calculate the amount of weight currently being used by the storage
    ---@return number
    Storage.GetWeight = function(): number
        local weight = 0
        for i, Item in ipairs(StorageFolder:GetChildren()) do
            weight += Item:GetAttribute("Weight") or 0
        end
        return weight
    end

    local StoragePrompt: ProximityPrompt = Util.CreateInstance(
        "ProximityPrompt",
        {
            ActionText = "Open storage";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 4;
            Parent = Attachment;
            RequiresLineOfSight = true;
        }
    )

    StoragePrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{key}.StoragePrompt.Triggered: No Character found \z
                for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{key}.StoragePrompt.Triggered: No Humanoid found \z
                for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{key}.StoragePrompt.Triggered: {Player} is dead!`
            )
        end

        if not storageConfig.Locked or (lock and lock(Player)) then
            --Open the storage unit
            StoragePrompt.Enabled = false

            local Interface = StorageGui:Clone()
            Interface:SetAttribute("Capacity", storageConfig.Capacity)
            Interface:SetAttribute("DisplayName", storageConfig.DisplayName)

            local UpdateContents: RemoteEvent = Interface:WaitForChild(
                "UpdateContents"
            )
            StorageClient:Clone().Parent = Interface

            local function updateContents()
                UpdateContents:FireClient(Player, Storage.Export())
            end

            ---Put an item in or take an item out of the storage
            ---@param User Player The User attempting to use the storage
            ---@param from string Where the item is being taken from
            ---@param guid string The GUID of the item
            UpdateContents.OnServerEvent:Connect(function(
                User: Player, from: string, guid: string
            )
                if User ~= Player then
                    return warn(
                        `{script}.{key}.UpdateContents.OnServerEvent: {User} \z
                        is not the current active user of the storage! Active \z
                        user: {Player})`
                    )
                end

                if not (from == "Inventory" or from == "Storage") then
                    return warn(
                        `{script}.{key}.UpdateContents.OnServerEvent: {User} \z
                        tried to pull from an unknown storage type! ({from})`
                    )
                end

                local Inventory = User.PlayerGui:FindFirstChild("Inventory")
                if not Inventory then
                    return warn(
                        `{script}.{key}.UpdateContents.OnServerEvent: No \z
                        inventory found for {User}!`
                    )
                end

                local From = from == "Inventory" and Inventory or StorageFolder
                local To = from == "Inventory" and StorageFolder or Inventory

                local Item
                for i, Child in ipairs(From:GetChildren()) do
                    if Child.Name == guid then
                        Item = Child
                        break
                    end
                end

                if not Item then
                    return warn(
                        `{script}.{key}.UpdateContents.OnServerEvent: No item \z
                        with GUID {guid} found in {
                            (from == "Inventory" and `{User}'s Inventory`)
                            or `the storage unit {key}`
                        }!`
                    )
                end

                if from == "Inventory" then
                    local weight = Item:GetAttribute("Weight") or 0
                    if
                        Storage.GetWeight() + weight > storageConfig.Capacity
                    then
                        SendNotification:FireClient(User, {
                            Title = "No space";
                            Text = `The weight of the \z
                                {Item:GetAttribute("FileName")} you tried to \z
                                put into storage exceeds the storage's weight \z
                                capacity!`;
                            Duration = 10;
                        })
                        return warn(
                            `{script}.{key}.UpdateContents.OnServerEvent: Not \z
                            enough weight capacity in {key} to store {User}'s \z
                            {Item:GetAttribute("FileName")} ({guid})! \z
                            (Currently in use: \z
                            {Util.Round(Storage.GetWeight(), 2)} kg, \z
                            Capacity: {storageConfig.Capacity} kg, \z
                            Item weight: {Util.Round(weight, 2)} kg)`
                        )
                    end

                    local length = Item:GetAttribute("Length") or 0
                    if length > storageConfig.Length then
                        SendNotification:FireClient(User, {
                            Title = "Item too large";
                            Text = `The {Item:GetAttribute("FileName")} you \z
                                tried to is too large to fit in the storage!`;
                            Duration = 10;
                        })
                        return warn(
                            `{script}.{key}.UpdateContents.OnServerEvent: \z
                            {User}'s {Item:GetAttribute("FileName")} ({guid}) \z
                            is too large to fit in {key}! (Storage size: \z
                            {storageConfig.Length}m, item size: {length}m)`
                        )
                    end

                    for slot, checkGuid in pairs(Inventory:GetAttributes()) do
                        if checkGuid == guid then
                            Inventory:SetAttribute(slot, nil)
                            break
                        end
                    end
                    Item.Parent = To
                else
                    InventoryHandler.Add(User, Item, nil, true)
                end
            end)

            local added = StorageFolder.DescendantAdded:Connect(updateContents)
            local removed = StorageFolder.DescendantRemoving:Connect(
                updateContents
            )

            local active
            local function exitStorage()
                if active then
                    return
                end

                active = true
                added:Disconnect()
                removed:Disconnect()
                Interface:Destroy()
                StoragePrompt.Enabled = true
            end

            Humanoid.Died:Once(exitStorage)
            Player.AncestryChanged:Once(exitStorage)
            
            Interface.Parent = Player.PlayerGui
            updateContents()

            while
                Player:DistanceFromCharacter(Attachment.WorldCFrame.Position)
                < StoragePrompt.MaxActivationDistance * 2
            do
                task.wait(0.25)
            end
            exitStorage()
        end
    end)

    return Storage
end

return module