--This script handles the inventory on the server
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemHandler = require(script.Items)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local EquipTool = ReplicatedCommunication.EquipTool
local PlayAnimation = ReplicatedCommunication.PlayAnimation
local SendNotification = ReplicatedCommunication.SendNotification
local UnequipTool = ReplicatedCommunication.UnequipTool

local InventoryConfig = require(ReplicatedConfig.Inventory)

local ServerScripts = ServerScriptService.ServerScripts
local ArmoryHandler = require(ServerScripts.Armories)
local FireamsHandler = require(ServerScripts.Firearms)
local DeathHandler = require(ServerScripts.Deaths)
local EvidenceHandler = require(ServerScripts.Interactions.Evidence)
local MIAHandler = require(ServerScripts.Jobs.MIA)
local MoneyHandler = require(ServerScripts.Money)
local MortarHandler = require(ServerScripts.Mortars)
local PrisonHandler = require(ServerScripts.Prison)
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local SanitationHandler = require(ServerScripts.Jobs.Sanitation)

local HANDLE_PROPERTIES = PhysicalProperties.new(
    Util.MaterialDensities["Enum.Material.Metal"],
    1,
    0
)

local module = {}

module.Items = ItemHandler

EquipTool.OnServerInvoke = function(Player: Player, slot: string)
    if InventoryConfig.InvalidSlots[slot] then
        return warn(
            `{script}.EquipTool.OnServerInvoke: \z
            Unable to equip item to forbidden slot {slot} for {Player}!`
        )
    end

    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.EquipTool.OnServerInvoke: \z
            No inventory found for player {Player}!`
        )
    end

    local guid = Inventory:GetAttribute(slot)
    if not guid then
        return warn(
            `{script}.EquipTool.OnServerInvoke: \z
            No item found in slot {slot} for Player {Player}!`
        )
    end

    local Item = Inventory:FindFirstChild(guid)
    if not Item then
        return warn(
            `{script}.EquipTool.OnServerInvoke: \z
            Item with GUID {guid} not found in inventory of {Player}!`
        )
    end

    if Player.Character:GetAttribute("Drawing") then
        return warn(
            `{script}.EquipTool.OnServerInvoke: Player {Player} is currently \z
            drawing a tool!`
        )
    end

    module.Equip(Player, Item, slot)
end

UnequipTool.OnServerEvent:Connect(function(Player: Player)
    local Item = Player.Character:FindFirstChildWhichIsA("Tool")
    if not Item then
        return warn(
            `{script}.UnequipTool.OnServerEvent: Player {Player} does not \z
            currently have an item equipped!`
        )
    end

    if Player.Character:GetAttribute("Drawing") then
        return warn(
            `{script}.UnequipTool.OnServerEvent: Player {Player} is currently \z
            drawing a tool!`
        )
    end

    if not module.Unequip(Player, Item) then
        return warn(
            `{script}.UnequipTool.OnServerEvent: Unable to unequip currently \z
            equipped item {Item} for Player {Player}!`
        )
    end
end)

---Adds an item to the inventory of a player
---@param Player Player The Player to give the item to
---@param Item Tool The item to be given
---@param useSlot number The slot in the inventory to be used (allots if empty)
---@param dropOnFull boolean Whether to drop the item if the inventory is full
---@param dontEquip boolean Whether to ignore equipped as a potential slot
---@return boolean
module.Add = function(
    Player: Player,
    Item: Tool,
    useSlot: number,
    dropOnFull: boolean,
    dontEquip: boolean
)
    local fileName = Item and Item:GetAttribute("FileName")
    if not fileName then
        return warn(`{script}.Add: No file name found for item {Item}`)
    end

    local itemData = ItemHandler.Items[fileName]
    if not itemData then
        return warn(
            `{script}.Add: \z
            No item found with name {Item:GetAttribute(fileName)}`
        )
    end

    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(`{script}.Add: No inventory found for player {Player}!`)
    end

    local slotName = useSlot and InventoryConfig.Slots[useSlot]
    if slotName and not Inventory:GetAttribute(slotName) then
        Inventory:SetAttribute(slotName, Item.Name)

        if Item.ClassName == "Model" then
            Item = Util.ConvertTo(Item, "Tool")
            Item.CanBeDropped = false
            ItemHandler.Cache(Item)
        end

        Item.Parent = Inventory
        
        module.Show(Player, Item)
        return true
    else
        for i, slot in ipairs(InventoryConfig.Slots) do
            if itemData.Slots[InventoryConfig.SlotInfo[slot].Type]
                and not Inventory:GetAttribute(slot)
            then
                Inventory:SetAttribute(slot, Item.Name)

                if Item.ClassName == "Model" then
                    Item = Util.ConvertTo(Item, "Tool")
                    Item.CanBeDropped = false
                    ItemHandler.Cache(Item)
                end

                Item.Parent = Inventory
                
                module.Show(Player, Item)
                return true
            end
        end
    end

    if not dontEquip and module.Equip(Player, Item) then
        return true
    end

    warn(
        `{script}.Add: No slot found for item {Item} in inventory of {Player}!`
    )
    local RootPart = Player.Character
        and Player.Character:FindFirstChild("HumanoidRootPart")
    if dropOnFull and RootPart then
        module.Drop(Item, RootPart.CFrame + Vector3.new(
            math.random(-30, 30),
            math.random(0, 10),
            math.random(-30, 30)
        ) / 10)
    end
    return false
end

---Drops an item onto the ground
---@param Item Tool The item to drop
---@param DropAt CFrame The CFrame to drop the item at
---@param anchorDropped boolean Whether to immediately anchor the dropped item
---@return boolean
module.Drop = function(Item: Tool, DropAt: CFrame, anchorDropped: boolean)
    local itemData = ItemHandler.Items[Item:GetAttribute("FileName")]
    if not itemData then
        return warn(
            `{script}.Drop: \z
            No item data found for item with file name \z
            {Item:GetAttribute("FileName")}!`
        )
    end

    if itemData.DontDrop then
        return warn(
            `{script}.Drop: Item with file name \z
            {Item:GetAttribute("FileName")} can not be dropped!`
        )
    end

    if itemData.DestroyOnDrop then
        Item:Destroy()
        return true
    end

    Item = Util.ConvertTo(Item, "Model")
    ItemHandler.Cache(Item)

    for i, Child: Instance in ipairs(Item:GetChildren()) do
        if not Child:IsA("BasePart") then
            continue
        end

        if Child:GetAttribute("CouldCollide") then
            Child.CanCollide = true
            Child:SetAttribute("CouldCollide", nil)
        end
    end

    local PickupPrompts = {}
    for i = 1, 2 do
        local PickupPrompt = Util.CreateInstance("ProximityPrompt", {
            ActionText = "Pick up";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.P;
            MaxActivationDistance = 6;
            Name = "PickupPrompt";
            Parent = Item.Handle:FindFirstChild(`PromptAttachment{i}`)
                or Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(0.2 * (i == 1 and 1 or -1), 0, 0);
                    Name = `PromptAttachment{i}`;
                    Parent = Item.Handle;
                });
            RequiresLineOfSight = true;
        })
        
        PickupPrompt.Triggered:Connect(function(Player: Player)
            local enforceNLR = Item:GetAttribute("EnforceNLR")
            if enforceNLR then
                if
                    Player.UserId == enforceNLR
                    and not (InventoryConfig.IgnoreNLR[Player.Team.Name])
                then
                    Player:Kick(
                        "Violation of the New Life Rule! You are not \z
                        permitted to pick up items dropped by yourself on \z
                        death!"
                    )
                    return WebhookHandler.Post(
                        `{Player} has been kicked from the game for \z
                        attempting to pick up a \z
                        {Item:GetAttribute("DisplayName")} dropped by their \z
                        own corpse.`,
                        "ModLog"
                    )
                else Item:SetAttribute("EnforceNLR", nil)
                end
            end

            local Character: Model = Player.Character
            if not (Character and Character:FindFirstChild("Right Arm")) then
                SendNotification:FireClient(Player, {
                    Title = "Unable to pick up";
                    Text = "You can not pick up items, because your character \z
                        is missing their right arm!";
                    Duration = 10;
                })
                return warn(
                    `{script}.{Item}.PickupPrompt.Triggered: Missing right \z
                    arm for {Player}!`
                )
            end

            if module.Equip(Player, Item) then
                for j, Prompt in ipairs(PickupPrompts) do
                    Prompt:Destroy()
                end
            end
        end)

        table.insert(PickupPrompts, PickupPrompt)
    end

    if not anchorDropped then
        task.spawn(function()
            local GravForce = Util.CreateInstance("VectorForce", {
                ApplyAtCenterOfMass = true;
                Force = Vector3.new(0, -32.17, 0);
                Parent = Item.Handle;
                --32.17 is imperial gravitational acceleration (9.81 in metric)
            })
            Item.Handle.Velocity = GravForce.Force
            repeat
                task.wait()
            until Item.Handle.Velocity.Magnitude > 0
            repeat
                task.wait()
            until not Item:FindFirstChild("Handle")
                or Item.Handle.Velocity.Magnitude == 0
            GravForce:Destroy()
            if Item:FindFirstChild("Handle") then
                Item.Handle.Anchored = true
            end
        end)
    else
        Item.Handle.Anchored = true
    end

    Item:SetAttribute("InAction", nil)
    Item.Handle.CanCollide = true
    Item.Handle.CustomPhysicalProperties = HANDLE_PROPERTIES
    Item.Parent = workspace
    Item.Handle.CFrame = DropAt
    return true
end

---Drops all items from the inventory of a Player
---@param Player Player The Player whose items to drop
---@param reset boolean Whether to fully reset the inventory
---@param enforceNLR boolean Whether to prevent pickup from the dropped player
module.DropAll = function(Player: Player, reset: boolean, enforceNLR: boolean)
    local RootPart = Player.Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then
        warn(
            `{script}.DropAll: No root part found for player {tostring(Player)}`
        )
    end

    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.DropAll: No inventory found for player {tostring(Player)}`
        )
    end

    for attribute, value in pairs(Inventory:GetAttributes()) do
        local Item = Inventory:FindFirstChild(value) or (Player.Character
            and Player.Character:FindFirstChild(value))
        if Item then
            local itemData = ItemHandler.Items[Item:GetAttribute("FileName")]
            if not itemData then
                warn(
                    `{script}.DropAll: \z
                    No item data found for item with file name \z
                    {Item:GetAttribute("FileName")}`
                )
                continue
            end

            if
                itemData.DontDrop
                or (
                    Item:GetAttribute("FromArmory")
                    and ArmoryHandler.UsingArmory(
                        Player, Item:GetAttribute("FromArmory")
                    )
                )
            then
                if Item:GetAttribute("FileName") == "Wallet" then
                    local balance = Item:GetAttribute("Balance")
                    if balance and balance > 0 then
                        Item:SetAttribute("Balance", 0)

                        if reset then
                            Inventory:SetAttribute(attribute, nil)
                            Item:Destroy()
                        end

                        Item = ItemHandler.new(
                            "Cash",
                            `{Player:GetAttribute("FullName")}'s wallet`,
                            {
                                Value = balance
                            }
                        )
                    else
                        if reset then
                            Inventory:SetAttribute(attribute, nil)
                            Item:Destroy()
                        end
                        continue
                    end
                else
                    warn(
                        `{script}.DropAll: Unable to drop item with file name \z
                        {Item:GetAttribute("FileName")}!`
                    )

                    if reset then
                        Inventory:SetAttribute(attribute, nil)
                        Item:Destroy()
                    end
                    continue
                end
            else
                Inventory:SetAttribute(attribute, nil)
            end

            if RootPart then
                if enforceNLR then
                    Item:SetAttribute("EnforceNLR", Player.UserId)
                end

                module.Drop(Item, RootPart.CFrame + Vector3.new(
                    math.random(-30, 30),
                    math.random(0, 10),
                    math.random(-30, 30)
                ) / 10)
            else
                Item:Destroy()
            end
        end
    end
end

---Equips a tool to a character
---@param Player Player The Player equipping the item
---@param Item Tool The item to be equipped
---@param fromSlot string The name of the slot the item is being equipped from
---@return boolean
module.Equip = function(Player: Player, Item: Tool, fromSlot: string)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(`{script}.Equip: No inventory found for player {Player}!`)
    end

    local Equipped = Player.Character:FindFirstChildWhichIsA("Tool")
    if Equipped then
        if not module.Unequip(Player, Equipped) then
            return warn(
                `{script}.Equip.OnServerInvoke: \z
                Unable to unequip currently equipped item {Equipped} for \z
                Player {Player}!`
            )
        end
    end

    if Item.ClassName == "Model" then
        Item = Util.ConvertTo(Item, "Tool")
        ItemHandler.Cache(Item)
        Item.CanBeDropped = false
    end

    if fromSlot then
        Inventory:SetAttribute(fromSlot, nil)
        Item:SetAttribute("WasIn", fromSlot)

        PlayAnimation:FireClient(Player, `Draw{fromSlot}`)
        Player.Character:SetAttribute("Drawing", true)

        task.wait(InventoryConfig.DrawTime[fromSlot] / 2)
        task.spawn(function()
            task.wait(InventoryConfig.DrawTime[fromSlot] / 2)
            Player.Character:SetAttribute("Drawing", nil)
        end)
    end

    Inventory:SetAttribute("Equipped", Item.Name)
    
    Item.Handle.Anchored = false
    Item.Parent = Player.Character
    Item.AncestryChanged:Once(function()
        if
            Player.Parent == Players
            and Inventory:GetAttribute("Equipped") == Item.Name
        then
            Inventory:SetAttribute("Equipped", nil)
        end
    end)

    for i, Child: Instance in pairs(Item:GetChildren()) do
        if not Child:IsA("BasePart") then
            continue
        end

        local showOnEquipped = Child:GetAttribute("ShowOnEquipped")
        if showOnEquipped ~= nil then
            Child.Transparency = showOnEquipped and 0 or 1
        end

        if Child.Name ~= "Handle" and Child.CanCollide then
            Child:SetAttribute("CouldCollide", true)
            Child.CanCollide = false
        end
    end

    return true
end

---Creates the inventory for a Player, and loads the saved inventory
---@param Player Player The Player whose inventory to load
---@param inventory table The saved inventory
---@param equipped table The saved equipped item
module.Load = function(Player: Player, inventory: table, equipped: table)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
        or Util.CreateInstance("ScreenGui", {
            Name = "Inventory";
            Parent = Player.PlayerGui;
            ResetOnSpawn = false;
        }, {
            New = true;
        })

    if not Inventory:GetAttribute("New") then
        for attribute, value in pairs(Inventory:GetAttributes()) do
            print(
                `{script}.Load: Removing {value} from the inventory of \z
                {Player} (Slot: {attribute})`
            )
            local Tool = Inventory:FindFirstChild(value)
            if Tool then
                Tool:Destroy()
            end
            Inventory:SetAttribute(attribute, nil)
        end
    end
    Inventory:SetAttribute("New", nil)

    if Player.Team.Name ~= "Incarcerated" then
        if inventory then
            for i, itemData in pairs(inventory) do
                if not itemData.FileName then
                    continue
                end

                if not ItemHandler.Items[itemData.FileName] then
                    warn(
                        `{script}.Load: Unable to load unknown item \z
                        {itemData.FileName} for {Player}!`
                    )
                    continue
                end

                module.Add(
                    Player,
                    ItemHandler.new(
                        itemData.FileName,
                        `Saved data for {Player:GetAttribute("FullName")}`,
                        itemData.Attributes,
                        itemData.GUID
                    ),
                    i
                )
            end
        else
            for i, filename in ipairs(InventoryConfig.StarterPack) do
                module.Add(
                    Player,
                    ItemHandler.new(
                        filename,
                        `{Player:GetAttribute("FullName")}'s StarterPack`
                    )
                )
            end
        end

        if equipped and equipped.FileName then
            task.spawn(function()
                Player.CharacterAdded:Wait()
                module.Equip(Player, ItemHandler.new(
                    equipped.FileName,
                    `Saved data for {Player:GetAttribute("FullName")}`,
                    equipped.Attributes,
                    equipped.GUID
                ))
            end)
        end
    end

    local function toBackpack(Item: Tool)
        module.Unequip(Player, Item)
    end

    local updateBackpack = Player.Backpack.ChildAdded:Connect(toBackpack)
    Player.ChildAdded:Connect(function(Child: Instance)
        if Child:IsA("Backpack") then
            updateBackpack:Disconnect()
            updateBackpack = Child.ChildAdded:Connect(toBackpack)
        end
    end)

    Player.AncestryChanged:Connect(function()
        Inventory:Clone().Parent = Player
    end)
end

---Writes the contents of a Player's inventory to a DataStore-compatible array
---@param Player Player The Player whose inventory to save
---@return table
module.Save = function(Player: Player)
    local Inventory = Player:WaitForChild("Inventory")
    if not Inventory then
        return warn(`{script}.Save: No inventory found for player {Player}!`)
    end

    if Player:GetAttribute("Dead") then
        return warn(`{script}.Save: {Player} is dead!`)
    end

    if Player:GetAttribute("Booked") then
        print(
            `{script}.Save: {Player} has been arrested, confiscating all \z
            items...`
        )
        PrisonHandler.ConfiscateInventory(Player)
    end

    local function toTable(guid: string)
        if not guid then
            return {}
        end

        local attributes = ItemHandler.GetCache(guid)
        if not attributes then
            return warn(
                `{script}.Save: Attributes for item with GUID {guid} not \z
                found in the cache!`
            )
        end
        
        for i, dontSave in ipairs(InventoryConfig.DontSave) do
            attributes[dontSave] = nil
        end

        local itemData = ItemHandler.Items[attributes.FileName]
        if not itemData then
            return warn(
                `{script}.Save: Attempted to save unknown item with the \z
                file name {attributes.FileName}`
            )
        end

        if itemData.DontSave then
            return warn(
                `{script}.Save: The item with file name {attributes.FileName} \z
                is unable to be saved to file!`
            )
        end

        return {
            GUID = guid;
            FileName = attributes.FileName;
            Attributes = attributes;
        }
    end

    local saved = {}
    for i, slot in ipairs(InventoryConfig.Slots) do
        saved[i] = toTable(Inventory:GetAttribute(slot))
    end

    return saved, toTable(Inventory:GetAttribute("Equipped"))
end

---Display an item on a Player's character
---@param Player Player The Player to display the item on
---@param Item Tool The item to display
module.Show = function(Player: Player, Item: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(`{script}.Show: No inventory found for player {Player}!`)
    end

    local itemData = ItemHandler.Items[Item:GetAttribute("FileName")]
    if not itemData then
        return warn(
            `{script}.Show: \z
            No item data found for item with file name \z
            {Item:GetAttribute("FileName")}!`
        )
    end

    local inSlot
    for i, slot in ipairs(InventoryConfig.Slots) do
        if Inventory:GetAttribute(slot) == Item.Name then
            inSlot = slot
            break
        end
    end

    if not inSlot then
        return warn(
            `{script}.Show: Unable to find inventory slot of {Player}'s \z
            {Item:GetAttribute("FileName")} {Item}!`
        )
    end

    local slotInfo = InventoryConfig.SlotInfo[inSlot]
    if not slotInfo.AttachesTo then
        return print(
            `{script}.Show: Not showing {Player}'s \z
            {Item:GetAttribute("FileName")}, because the slot {inSlot} does \z
            not appear on the character!`
        )
    end

    local AttachModel = Util.CreateInstance("Model", {
        Name = `{Item:GetAttribute("FileName")}Display{Item}`;
    })
    for i, Child in ipairs(Item:GetDescendants()) do
        if Child:IsA("BasePart") then
            local ClonedPart = Child:Clone()
            ClonedPart.CanCollide = false
            ClonedPart.CanQuery = false
            ClonedPart.Parent = AttachModel

            local showOnEquipped = Child:GetAttribute("ShowOnEquipped")
            if showOnEquipped ~= nil then
                ClonedPart.Transparency = showOnEquipped and 1 or 0
            end
        end
    end

    for i, Child in ipairs(AttachModel:GetDescendants()) do
        if Child:IsA("Sound") then
            Child:Stop()
        elseif Child:IsA("ParticleEmitter") or Child:IsA("Beam") then
            Child.Enabled = false
        end
    end
    
    local Handle = AttachModel:FindFirstChild("Handle")
    if not Handle then
        return warn(
            `{script}.Show: No handle found for \z
            {Item:GetAttribute("FileName")} {Item}!`
        )
    end

    local UseAttachment = Handle:FindFirstChild(`{inSlot}Attachment`)
    if not UseAttachment then
        return warn(
            `{script}.Show: No {inSlot}Attachment found for \z
            {Item:GetAttribute("FileName")} {Item}!`
        )
    end

    local ConnectAttachment = Player.Character
        and Player.Character:FindFirstChild("Torso")
        and Player.Character.Torso:FindFirstChild(slotInfo.AttachesTo)
    if not ConnectAttachment then
        return warn(
            `{script}.Show: No {slotInfo.AttachesTo} found for {Player}!`
        )
    end

    local OldModel = Player.Character:FindFirstChild(AttachModel.Name)
    if OldModel then
        OldModel:Destroy()
    end

    local AttachmentPart = Util.CreateInstance("Part", {
        CFrame = UseAttachment.WorldCFrame;
        CanCollide = false;
        CanQuery = false;
        Massless = true;
        Parent = AttachModel;
        Size = Vector3.new(0.1, 0.1, 0.1);
        Transparency = 1;
    })
    AttachModel.PrimaryPart = AttachmentPart
    Util.WeldChildren(AttachModel, Handle)
    AttachModel:SetPrimaryPartCFrame(ConnectAttachment.WorldCFrame)
    Util.WeldTo(AttachmentPart, Player.Character.Torso)
    AttachModel.Parent = Player.Character;

    Item.AncestryChanged:Once(function()
        AttachModel:Destroy()
    end)
end

---Unequips an item from a Player's character and returns it to the inventory
---@param Player Player The Player unequipping the item
---@param Item Tool The item to be unequipped
---@return boolean
module.Unequip = function(Player: Player, Item: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(`{script}.Unequip: No inventory found for player {Player}!`)
    end

    local itemData = ItemHandler.Items[Item:GetAttribute("FileName")]
    if not itemData then
        return warn(
            `{script}.Unequip: No item data found for item with file name \z
            {Item:GetAttribute("FileName")}!`
        )
    end

    if Item:GetAttribute("InAction") then
        return warn(
            `{script}.Unequip: Can not unequip {Player}'s \z
            {Item:GetAttribute("FileName")} ({Item}) while in action!`
        )
    end

    if itemData.DestroyOnUnequip then
        Inventory:SetAttribute("Equipped", nil)
        Item:Destroy()
        return true
    end

    local lastSlot = Item:GetAttribute("WasIn")
    if module.Add(Player, Item, lastSlot, false, true) then
        Inventory:SetAttribute("Equipped", nil)
        Item:SetAttribute("WasIn", nil)
        return true
    else
        Item.Parent = Player.Character
        return false
    end
end

--Prevents recursive module requiring
ArmoryHandler.IHPass(module)
DeathHandler.IHPass(module)
FireamsHandler.IHPass(module)
EvidenceHandler.IHPass(module)
SanitationHandler.IHPass(module)
MIAHandler.IHPass(module)
MoneyHandler.IHPass(module)
MoneyHandler.WalletHandler.IHPass(module)
MortarHandler.IHPass(module)
PrisonHandler.IHPass(module)
return module