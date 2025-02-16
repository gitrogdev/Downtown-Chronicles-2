---All interaction with shops on the client
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ConditionHandler = require(ReplicatedScripts.NPCConditions)
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration
local Util = require(ReplicatedScripts.Util)

local ShopData = ReplicatedCommunication.ShopData
local ShopPurchase = ReplicatedCommunication.ShopPurchase

local ClothingConfig = require(ReplicatedConfig.Clothing)

local module = {}

---Initialize a new shop
---@param name string The name of the shop
---@param MainGui ScreenGui The GUI being used for the NPC interaction
---@param npcConfig table The config for the NPC being interacted with
---@param next table The arguments for what to do after the shopping completes
---@param handleOption function The function to handle the next NPC option
module.new = function(
    name: string,
    MainGui: ScreenGui,
    npcConfig: table,
    next: table,
    handleOption: (string) -> ()
)
    local AffiliateBackground: Frame = MainGui:WaitForChild("Affiliate")
    local DialogueBackground: Frame = MainGui:WaitForChild("Background")
    local ShopGui: Frame = MainGui:WaitForChild("Shop")

    local AffiliateBody: TextLabel = AffiliateBackground:WaitForChild("Body")
    local AffiliateCancel: TextButton = AffiliateBackground:WaitForChild(
        "CancelButton"
    )
    local AffiliatePurchase: TextButton = AffiliateBackground:WaitForChild(
        "PurchaseButton"
    )

    local CartBackground = ShopGui:WaitForChild("CartBackground")
    local ShopBackground = ShopGui:WaitForChild("ShopBackground")

    local CartHolder = CartBackground:WaitForChild("CartHolder")
    local PaymentHolder = CartBackground:WaitForChild("PaymentHolder")
    local TotalDisplay = CartBackground:WaitForChild("Price")

    local PurchaseTemplate = CartHolder:WaitForChild("PurchaseTemplate")

    local PayCard = PaymentHolder:WaitForChild("CardPayment")
    local PayCash = PaymentHolder:WaitForChild("CashPayment")

    local HeadDisplay = ShopBackground:WaitForChild("Head")
    local ItemHolder = ShopBackground:WaitForChild("ItemHolder")
    local GridLayout = ItemHolder:WaitForChild("UIGridLayout")
    local ItemTemplate = ItemHolder:WaitForChild("ItemTemplate")

    local data = ShopData:InvokeServer(name)
    local PreviewModels = Player.PlayerGui:WaitForChild(`{name}PreviewModels`)

    local debounce
    local cart = {}
    local options = {}

    local function makePurchase(method: string)
        if #cart == 0 then
            return StarterGui:SetCore("SendNotification", {
                Title = "Cart empty";
                Text = "You don't have any items in your cart!";
                Duration = 10;
            })
        end

        if debounce then
            return
        end
        debounce = true

        --Simplifies purchase data for server use
        local purchase = {}
        
        for i, item in ipairs(cart) do
            table.insert(purchase, item.ID)
            item.Display:Destroy()
        end

        local response = ShopPurchase:InvokeServer(name, purchase, method)

        local nextInteraction = next[tostring(response)]
        print(
            `{script}.{name}.MakePurchase}: Handling the response {response} \z
            (leads to {nextInteraction})!`
        )

        ShopGui.Visible = false

        local function affiliatePrompt(clothingConfig: table)
            local productInfo: table =
            MarketplaceService:GetProductInfo(clothingConfig.RobloxId)

            if not productInfo then
                return
            end

            if not productInfo.PriceInRobux then
                return
            end

            AffiliateBackground.Visible = true

            AffiliateBody.Text = `The clothing item "\z
                {clothingConfig.DisplayName}" which you just purchased is \z
                available on the Roblox Catalog as "{productInfo.Name}" \z
                from {productInfo.Creator.Name}.  Would you like to buy it \z
                for your avatar on Roblox?`
            
            local holding = true
            AffiliatePurchase.MouseButton1Click:Once(function()
                MarketplaceService:PromptPurchase(
                    Player, clothingConfig.RobloxId
                )
                holding = false
            end)
            
            AffiliateCancel.MouseButton1Click:Once(function()
                holding = false
            end)

            while holding do
                task.wait()
            end
            AffiliateBackground.Visible = false
        end

        for i, item: table in ipairs(cart) do
            local itemData = data.Items[item.ID]
            if itemData.Type == "Clothing" then
                local clothingConfig = ClothingConfig[itemData.Name]
                if clothingConfig and clothingConfig.RobloxId then
                    affiliatePrompt(clothingConfig)
                end
            elseif itemData.Type == "Suit" then
                local types = {"Shirt", "Pants"}
                for j, clothingType: string in ipairs(types) do
                    local clothingConfig = ClothingConfig[
                        itemData[clothingType]
                    ]
                    if clothingConfig and clothingConfig.RobloxId then
                        affiliatePrompt(clothingConfig)
                    end
                end
            end
         end

        DialogueBackground.Visible = true
        handleOption(npcConfig[nextInteraction])

        for i, Option in ipairs(options) do
            Option:Destroy()
        end
        TotalDisplay.Text = "₲0"
    end

    local function updateTotal()
        local total = 0
        for i, item in ipairs(cart) do
            total += data.Items[item.ID].Price
        end
        TotalDisplay.Text = `₲{Util.ThousandsSeparate(total)}`
    end

    local function usingSlots(slots: string)
        local using = 0
        for i, item in ipairs(cart) do
            local found = true
            for checkSlot, status in pairs(data.Items[item.ID].Slots) do
                if not slots[checkSlot] then
                    found = false
                    break
                end
            end

            if found then
                using += 1
            end
        end
        return using
    end

    for i, item in ipairs(data.Items) do
        if item.SellIf and not ConditionHandler[item.SellIf](Player) then
            print(
                `{script}.new: Skipping item {item.Name} with condition \z
                {item.SellIf} for shop {name}.`
            )
            continue
        end

        local ItemDisplay = ItemTemplate:Clone()
        local BuyButton = ItemDisplay:WaitForChild("BuyButton")
        local NameDisplay = ItemDisplay:WaitForChild("ItemName")
        local PriceDisplay = ItemDisplay:WaitForChild("Price")
        local Viewport = ItemDisplay:WaitForChild("ViewportFrame")

        NameDisplay.Text = item.DisplayName or item.Name
        PriceDisplay.Text = `₲{Util.ThousandsSeparate(item.Price)}`

        local PreviewModel = PreviewModels:FindFirstChild(`Preview{i}`)
        if PreviewModel then
            if not PreviewModel.PrimaryPart then
                PreviewModel.PrimaryPart = PreviewModel.Handle
                warn(`{script}.new: No PrimaryPart found for {PreviewModel}!`)
            end

            local cameraCFrame = CFrame.new(
                PreviewModel.PrimaryPart.CFrame:ToWorldSpace(
                    CFrame.new(0, 0, -3)
                ).Position,
                PreviewModel.PrimaryPart.CFrame.Position
            )
            
            if item.Type == "Clothing" then
                local articleConfig = ClothingConfig[item.Name]
                if articleConfig then
                    if articleConfig.Type == "Pants" then
                        cameraCFrame -= Vector3.new(0, 1.5, 0)
                    end
                end
            end

            PreviewModel.Parent = Viewport
            Viewport.CurrentCamera = Util.CreateInstance("Camera", {
                CFrame = cameraCFrame;
                Parent = Viewport;
            })
        end

        table.insert(options, ItemDisplay)
        ItemDisplay.Name = item.DisplayName or item.Name
        ItemDisplay.Parent = ItemHolder
        ItemDisplay.Visible = true

        BuyButton.MouseButton1Click:Connect(function()
            if debounce then
                return
            end

            --Makes sure the Player has inventory space
            if item.Type == "Clothing" then
                for j, purchase in ipairs(cart) do
                    local productData = data.Items[purchase.ID]
                    if
                        productData.Type == "Clothing"
                        or productData.Type == "Suit"
                    then
                        if
                            ClothingConfig[productData.Name].Type
                            == ClothingConfig[item.Name].Type
                            or productData.Type == "Suit"
                        then
                            return StarterGui:SetCore("SendNotification", {
                                Title = "No space";
                                Text = "You can only buy one clothing item of \z
                                    a given type!";
                                Duration = 10;
                            })
                        end
                    end
                end
            elseif item.Type == "Item" then
                local slots = item.Slots
                if Util.FreeSlots(Player, slots) - usingSlots(slots) < 1 then
                    return StarterGui:SetCore("SendNotification", {
                        Title = "No space";
                        Text = "You don't have enough inventory space to \z
                            purchase this item!";
                        Duration = 10;
                    })
                end
            elseif item.Type == "Suit" then
                for j, purchase in ipairs(cart) do
                    local productData = data.Items[purchase.ID]
                    if productData.Type == "Clothing" then
                        return StarterGui:SetCore("SendNotification", {
                            Title = "No space";
                            Text = "You can only buy one clothing item of a \z
                            given type!";
                            Duration = 10;
                        })
                    end
                end
            end

            local PurchaseDisplay = PurchaseTemplate:Clone()
            local PurchaseName = PurchaseDisplay:WaitForChild("ItemName")
            local PurchasePrice = PurchaseDisplay:WaitForChild("Price")
            local RemoveButton = PurchaseDisplay:WaitForChild("RemoveButton")

            PurchaseName.Text = NameDisplay.Text
            PurchasePrice.Text = PriceDisplay.Text

            local guid = HttpService:GenerateGUID(false)
            table.insert(cart, {
                Display = PurchaseDisplay;
                ID = i;
                GUID = guid;
            })
            CartHolder.CanvasSize = UDim2.fromOffset(
                0,
                PurchaseDisplay.Size.Y.Offset * #cart
            )
            updateTotal()

            PurchaseDisplay.Parent = CartHolder
            PurchaseDisplay.Visible = true

            RemoveButton.MouseButton1Click:Connect(function()
                if debounce then
                    return
                end

                PurchaseDisplay:Destroy()
                for j, check in ipairs(cart) do
                    if check.GUID == guid then
                        table.remove(cart, j)
                        break
                    end
                end

                CartHolder.CanvasSize = UDim2.fromOffset(
                    0,
                    PurchaseDisplay.Size.Y.Offset * #cart
                )
                updateTotal()
            end)
        end)
    end
    GridLayout.CellSize = UDim2.new(0.3, 0, 0, GridLayout.AbsoluteCellSize.X)

    HeadDisplay.Text = data.Name
    PayCard.Visible = data.TakesCard
    PayCash.Visible = data.TakesCash
    if data.TakesCard then
        PayCard.MouseButton1Click:Connect(function()
            makePurchase("Card")
        end)
    end

    if data.TakesCash then
        PayCash.MouseButton1Click:Connect(function()
            makePurchase("Cash")
        end)
    end

    DialogueBackground.Visible = false
    ShopGui.Visible = true
end

return module