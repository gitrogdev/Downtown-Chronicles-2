--The server-side portion of NPC interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CharacterHandlers = {}
for i, CharacterHandler in ipairs(script.Characters:GetChildren()) do
    CharacterHandlers[CharacterHandler.Name] = require(CharacterHandler)
end

local RewardHandlers = {}
for i, RewardHandler in ipairs(script.Rewards:GetChildren()) do
    RewardHandlers[RewardHandler.Name] = require(RewardHandler)
end

local ShopHandlers = {}
for i, ShopHandler in ipairs(script.Shops:GetChildren()) do
    ShopHandlers[ShopHandler.Name] = require(ShopHandler)
end

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ConditionHandler = require(ReplicatedScripts.NPCConditions)
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local ClaimReward = ReplicatedCommunication.ClaimReward
local ShopData = ReplicatedCommunication.ShopData
local ShopPurchase = ReplicatedCommunication.ShopPurchase
local StartInteraction = ReplicatedCommunication.StartInteraction
local StopInteraction = ReplicatedCommunication.StopInteraction

local ClothingConfig = require(ReplicatedConfig.Clothing)

local ServerScripts = ServerScriptService.ServerScripts
local InventoryHandler = require(ServerScripts.Inventory)
local MoneyHandler = require(ServerScripts.Money)
local Util = require(ServerScripts.Util)

local ItemHandler = InventoryHandler.Items
local ItemData = ItemHandler.Items

local PartStorage = ServerStorage.Parts
local UIStorage = ServerStorage.UserInterface

local FashionDisplay = PartStorage.FashionDisplay
local ToolStorage = PartStorage.Tools

local Nametag = UIStorage.Nametag

local interacting = {}
local shopping = {}

---Claim a free reward
---@param Player Player The player claiming a reward
---@param reward string The reward to be claimed
---@return any
ClaimReward.OnServerInvoke = function(Player: Player, reward: string)
    local RewardHandler = RewardHandlers[reward]
    if not RewardHandler then
        return warn(
            `{script}.ClaimReward.OnServerInvoke: {Player} attempted to claim \z
            an unknown reward: {reward}!`
        )
    end

    if not RewardHandler.CanClaim(Player) then
        return warn(
            `{script}.ClaimReward.OnServerInvoke: {Player} does not meet the \z
            criteria to claim the {reward} reward!`
        )
    end

    RewardHandler.Claim(Player)
    return true
end

---Package and send the data for a given shop to the client
---@param Player Player The Player requesting the data
---@param name string The name of the shop
---@return table
ShopData.OnServerInvoke = function(Player: Player, name: string)
    local shopData = ShopHandlers[name]
    if not shopData then
        return warn(
            `{script}.ShopData.OnServerInvoke: {Player} requested data for an \z
            unknown shop! ({name})`
        )
    end

    local PreviewModels = Player.PlayerGui:FindFirstChild(`{name}PreviewModels`)
        or Util.CreateInstance("Folder", {
            Name = `{name}PreviewModels`;
            Parent = Player.PlayerGui;
        })
    for i, Child in ipairs(PreviewModels:GetChildren()) do
        Child:Destroy()
    end

    shopData = table.clone(shopData)
    for i, item in ipairs(shopData.Items) do
        if item.Type == "Item" then
            local itemData = ItemData[item.Name]
            if itemData then
                item.DisplayName = itemData.DisplayName
                item.Slots = itemData.Slots

                local PreviewModel = ToolStorage:FindFirstChild(item.Name)
                if PreviewModel then
                    PreviewModel = PreviewModel:Clone()
                    PreviewModel.Name = `Preview{i}`
                    PreviewModel.Parent = PreviewModels
                end
            end
        elseif item.Type == "Clothing" then
            local articleData = ClothingConfig[item.Name]
            if articleData then
                item.DisplayName = articleData.DisplayName

                local PreviewModel = FashionDisplay:Clone()
                Util.CreateInstance(articleData.Type, {
                    [`{articleData.Type}Template`] = articleData.Template;
                    Parent = PreviewModel;
                })
                PreviewModel.Name = `Preview{i}`
                PreviewModel.Parent = PreviewModels
            end
        elseif item.Type == "Suit" then
            local types = {"Shirt", "Pants"}
            local PreviewModel = FashionDisplay:Clone()
            item.DisplayName = item.Name
            for j, clothingType: string in ipairs(types) do
                local articleData = ClothingConfig[item[clothingType]]
                if articleData then

                    Util.CreateInstance(articleData.Type, {
                        [`{articleData.Type}Template`] = articleData.Template;
                        Parent = PreviewModel;
                    })
                end
            end

            PreviewModel.Name = `Preview{i}`
            PreviewModel.Parent = PreviewModels
        end
    end

    shopping[Player] = name
    return shopData
end

---Make a purchase from a shop
---@param Player Player The Player making the purchase
---@param shop string The shop being purchased from
---@param purchase table The items being purchased from the shop (IDs in shop)
---@param payment string The payment method (Cash or Card)
---@return boolean
ShopPurchase.OnServerInvoke = function(
    Player: Player,
    shop: string,
    purchase: table,
    payment: string
)
    local shopData = ShopHandlers[shop]
    if not shopData then
        return warn(
            `{script}.ShopPurchase.OnServerInvoke: {Player} attempted to make \z
            a purchase from an unknown shop! ({shop})`
        )
    end

    if shopping[Player] ~= shop then
        return warn(
            `{script}.ShopPurchase.OnServerInvoke: {Player} is not currently \z
            shopping at {shop}!`
        )
    end
    shopping[Player] = false

    if not (
        (payment == "Card" and shopData.TakesCard)
        or (payment == "Cash" and shopData.TakesCash)
    ) then
        return warn(
            `{script}.ShopPurchase.OnServerInvoke: {Player} attempted to use \z
            an invalid payment method for the shop {shop}! (Got: {payment}. \z
            Takes card: {not not shopData.TakesCard} \z
            Takes cash: {not not shopData.TakesCash})`
        )
    end

    if #purchase == 0 then
        return warn(
            `{script}.ShopPurchase.OnServerInvoke: {Player} attempted to make \z
            a purchase from {shop} with an empty cart!`
        )
    end

    local total = 0
    for i, item in ipairs(purchase) do
        local productData = shopData.Items[item]
        if not productData then
            return warn(
                `{script}.ShopPurchase.OnServerInvoke: {Player} attempted to \z
                buy an unknown item from {shop}: {item}`
            )
        end

        if
            productData.SellIf
            and not ConditionHandler[productData.SellIf](Player)
        then
            return warn(
                `{script}.ShopPurchase.OnServerInvoke: {Player} does not meet \z
                the required condition {productData.SellIf} for {shop}: {item}`
            )
        end

        purchase[i] = productData
        total += productData.Price
    end

    local chargeResponse = MoneyHandler.Charge(Player, total, payment)
    if chargeResponse == false then
        return "Insufficient", warn(
            `{script}.ShopPurchase.OnServerInvoke: {Player} does not have \z
            enough money to make a purchase of ₲{Util.ThousandsSeparate(total)}`
        )
    elseif not chargeResponse then
        return
    end

    for i, item in ipairs(purchase) do
        if item.Type == "Clothing" then
            local article = ClothingConfig[item.Name]
            if not article then
                warn(
                    `{script}.ShopPurchase.OnServerInvoke: {Player} has \z
                    bought an unknown article of clothing from {shop} \z
                    ({item.Name})`
                )
                continue
            end

            Player:SetAttribute(
                Player:GetAttribute(`Saved{article.Type}`)
                and `Saved{article.Type}` or article.Type,
                item.Name
            )
        elseif item.Type == "Suit" then
            local types = {"Shirt", "Pants"}
            for j, clothingType: string in ipairs(types) do
                local article = ClothingConfig[item[clothingType]]
                if not article then
                    warn(
                        `{script}.ShopPurchase.OnServerInvoke: {Player} has \z
                        bought an unknown article of clothing from {shop} \z
                        ({item.Name})`
                    )
                    continue
                end

                Player:SetAttribute(
                    Player:GetAttribute(`Saved{article.Type}`)
                    and `Saved{article.Type}` or article.Type,
                    item[clothingType]
                )
            end
        elseif item.Type == "Item" then
            InventoryHandler.Add(
                Player,
                ItemHandler.new(
                    item.Name,
                    `{Player:GetAttribute("FullName")}'s purchase from {shop}`
                ),
                nil,
                true
            )
        end
    end

    local PreviewModels = Player.PlayerGui:FindFirstChild(`{shop}PreviewModels`)
    if PreviewModels then
        PreviewModels:Destroy()
    end

    print(
        `{script}.ShopPurchase.OnServerInvoke: {Player} bought {#purchase} \z
        item{#purchase == 1 and "" or "s"} from {shop} using {payment}`
    )
    return true
end

---Stops NPC interaction for a player and allows interaction with other NPCs
---@param Player Player The Player stopping the interaction
StopInteraction.OnServerEvent:Connect(function(Player: Player)
    if interacting[Player] then
        interacting[Player] = false
    end
end)

local module = {}

---Sets up an NPC and the prompt to interact with it
---@param Model Instance
---@return table
module.Setup = function(Model: Instance)
    local NPC = {}

    NPC.Config = CharacterHandlers[Model.Name]
    if not NPC.Config then
        return warn(`{script}.Setup: No NPC found with name {Model}!`)
    end

    local Head = Model:FindFirstChild("Head")
    if not Head then
        return warn(`{script}.Setup: No head found for NPC {Model}!`)
    end

    local NPCHumanoid = Model:FindFirstChildOfClass("Humanoid")
    if NPCHumanoid then
        NPCHumanoid:SetAttribute("NoDamage", true)
    end

    NPC.InteractionPart = Model:FindFirstChild("InteractionPart") or
        Model:FindFirstChild("HumanoidRootPart")
    if not NPC.InteractionPart then
        return warn(
            `{script}.Setup: No interaction part found for NPC {Model}!`
        )
    end

    local NameDisplay = Nametag:Clone()
    NameDisplay:WaitForChild("Display").Text = NPC.Config.Name
    NameDisplay.Parent = Head

    local InteractPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Interact";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 8;
        Name = "NPCPrompt";
        Parent = NPC.InteractionPart;
        RequiresLineOfSight = false;
    })

    InteractPrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.Setup.InteractPrompt.Triggered: \z
                No Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.Setup.InteractPrompt.Triggered: \z
                No Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.Setup.InteractPrompt.Triggered: {Player} is dead!`
            )
        end

        if interacting[Player] then
            return warn(
                `{script}.Setup.InteractPrompt.Triggered: \z
                {Player} is alerady interacting with another NPC!`
            )
        end

        interacting[Player] = true
        StartInteraction:FireClient(
            Player,
            NPC.Config,
            NPC.InteractionPart.Position
        )
    end)

    return NPC
end

return module