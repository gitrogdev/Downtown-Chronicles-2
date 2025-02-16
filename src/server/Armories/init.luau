--Handles armories and the checkout and return of weapons on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ArmoryConfigs = {}
for i, ArmoryConfig in ipairs(script:GetChildren()) do
    ArmoryConfigs[ArmoryConfig.Name] = require(ArmoryConfig)
end

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local CheckoutWeapons = ReplicatedCommunication.CheckoutWeapons
local ReturnWeapons = ReplicatedCommunication.ReturnWeapons

local ServerScripts = ServerScriptService.ServerScripts
local InventoryHandler
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

---Give a Player weapons from an armory
---@param Player Player The Player checking out weapons
---@param armory string The armory to check out the weapons from
---@return any
CheckoutWeapons.OnServerInvoke = function(Player: Player, armory: string)
    local ArmoryConfig = ArmoryConfigs[armory]
    if not ArmoryConfig then
        return warn(
            `{script}.CheckoutWeapons.OnServerInvoke: {Player} requested \z
            weapons from an unknown armory "{armory}"!`
        )
    end

    if not (
        Player.Character
        and (Player.Character:GetAttribute("WeaponsCheckedOut") or 0) == 0
    ) then
        return warn(
            `{script}.CheckoutWeapons.OnServerInvoke: {Player} is currently \z
            unable to check out a weapon!`
        )
    end

    if not ArmoryConfig.Restrict(Player) then
        return warn(
            `{script}.CheckoutWeapons.OnServerInvoke: {Player} is not \z
            authorized to take weapons from the armory {armory}!`
        )
    end

    local Loadout: table
    if ArmoryConfig.ConditionalLoadouts then
        for i, Check: table in ipairs(ArmoryConfig.ConditionalLoadouts) do
            if Check.Condition(Player) then
                Loadout = Util.RandomFrom(Check.Loadouts)
                break
            end
        end
    end

    if not Loadout then
        Loadout = Util.RandomFrom(ArmoryConfig.Loadouts)
    end

    local checkedOut = 0

    for i, feedInfo in ipairs(Loadout.Feeds or {}) do
        for j = 1, feedInfo.Count do
            local FeedPart = InventoryHandler.Items.new(
                feedInfo.Name,
                `{Player:GetAttribute("FullName")} ({Player}) from \z
                {ArmoryConfig.Name}`
            )

            FeedPart:SetAttribute(
                "Capacity", FeedPart:GetAttribute("MaxCapacity")
            )
            FeedPart:SetAttribute("FromArmory", armory)

            InventoryHandler.Add(Player, FeedPart, nil, true)
            checkedOut += 1
            WebhookHandler.Post(
                `{Player:GetAttribute("FullName")} ({Player}) checked out the \z
                {FeedPart:GetAttribute("DisplayName")} with ID {FeedPart} \z
                from the {ArmoryConfig.Name}`,
                "WeaponCheckout"
            )
        end
    end

    for i, filename in ipairs(Loadout.Weapons or {}) do
        local Weapon = InventoryHandler.Items.new(
            filename,
            `{Player:GetAttribute("FullName")} ({Player}) from \z
            {ArmoryConfig.Name}`,
            {
                FeedArmory = armory;
                Loaded = true;
            }
        )

        Weapon:SetAttribute("FromArmory", armory)

        InventoryHandler.Add(Player, Weapon, nil, true)
        checkedOut += 1
        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player}) checked out the \z
            {Weapon:GetAttribute("DisplayName")} with the serial number \z
            {string.format("%012d", Weapon:GetAttribute("SerialNo"))} and ID \z
            {Weapon} from the {ArmoryConfig.Name}`,
            "WeaponCheckout"
        )
    end

    for i, filename in ipairs(Loadout.Equipment or {}) do
        local Weapon = InventoryHandler.Items.new(
            filename,
            `{Player:GetAttribute("FullName")} ({Player}) from \z
            {ArmoryConfig.Name}`
        )

        Weapon:SetAttribute("FromArmory", armory)

        InventoryHandler.Add(Player, Weapon, nil, true)
        checkedOut += 1
        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player}) checked out the \z
            {Weapon:GetAttribute("DisplayName")} with\z
            {Weapon:GetAttribute("SerialNo") and ` the serial number \z
            {string.format("%012d", Weapon:GetAttribute("SerialNo"))} and` or
            ""} ID {Weapon} from the {ArmoryConfig.Name}`,
            "WeaponCheckout"
        )
    end

    Player.Character:SetAttribute("WeaponsCheckedOut", checkedOut)

    return true
end

---Return weapons to an armory
---@param Player Player The Player returning the weapons
---@param armory string The armory to return the weapons to
---@return any
ReturnWeapons.OnServerInvoke = function(Player: Player, armory: string)
    local ArmoryConfig = ArmoryConfigs[armory]
    if not ArmoryConfig then
        return warn(
            `{script}.ReturnWeapons.OnServerInvoke: {Player} attempted to \z
            return weapons to an unknown armory "{armory}"!`
        )
    end

    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.ReturnWeapons.OnServerInvoke: No inventory found for \z
            {Player}!`
        )
    end

    local returned = 0
    local function returnWeapon(Item: Tool)
        if Item:GetAttribute("FromArmory") == armory then
            WebhookHandler.Post(
                `{Player:GetAttribute("FullName")} ({Player}) returned the \z
                {Item:GetAttribute("DisplayName")} with ID {Item} to the \z
                {ArmoryConfig.Name}`,
                "WeaponCheckout"
            )

            if Item:GetAttribute("FeedPartFromArmory") then
                WebhookHandler.Post(
                    `{Player:GetAttribute("FullName")} ({Player}) returned \z
                    the {Item:GetAttribute("FeedPart")} with ID \z
                    {Item:GetAttribute("FeedGUID")} to the {ArmoryConfig.Name}`,
                    "WeaponCheckout"
                )
                returned += 1
            end

            returned += 1

            for attribute, guid in pairs(Inventory:GetAttributes()) do
                if guid == Item.Name then
                    Inventory:SetAttribute(attribute, nil)
                    break
                end
            end
            Item:Destroy()
        end
    end

    for i, Item in ipairs(Inventory:GetChildren()) do
        returnWeapon(Item)
    end
    
    local Equipped = Player.Character
        and Player.Character:FindFirstChildOfClass("Tool")
    if Equipped then
        returnWeapon(Equipped)
    end

    local checkedOut = Player.Character:GetAttribute("WeaponsCheckedOut") or 0
    if checkedOut < returned then
        checkedOut = returned
    end
    Player.Character:SetAttribute("WeaponsCheckedOut", checkedOut - returned)

    return returned > 0 or "NoWeapons"
end

local module = {}

---Creates a local reference to the InventoryHandler module
---@param Handler table The JobHandler module
module.IHPass = function(Handler: table)
    InventoryHandler = Handler
end

---Checks if a player is using weapons from a given armory
---@param Player Player The Player to check
---@param armory string The armory to check
---@return boolean
module.UsingArmory = function(Player: Player, armory: string): boolean
    local ArmoryConfig = ArmoryConfigs[armory]
    if not ArmoryConfig then
        return warn(
            `{script}.UsingArmory: The armory {armory} is not a recognized \z
            armory! (Checking for {Player})`
        )
    end

    return ArmoryConfig.Restrict(Player)
end

return module