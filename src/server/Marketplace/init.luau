--Handles all interactions with the MarketplaceService on the server
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local ProductIds = require(ReplicatedConfig.Products)

local ProductHandlers = {}
for key, id in pairs(ProductIds) do
    local ProductHandler = script:FindFirstChild(key)
    if not ProductHandler then
        warn(`{script}: Product handler {key} not found!`)
        continue
    end

    ProductHandlers[id] = require(ProductHandler)
end

local module = {}

---Processes the purchase of a developer product
---@param receiptInfo table The receipt info passed from MarketplaceService
---@return Enum.ProductPurchaseDecision
module.ProcessReceipt = function(receiptInfo: table)
    local Player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not Player then
        warn(
            `{script}.ProcessReceipt: Player with ID {receiptInfo.PlayerId} \z
            is not currently in game!`
        )
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local ProductHandler = ProductHandlers[receiptInfo.ProductId]
    if not ProductHandler then
        warn(
            `{script}.ProcessReceipt: Product handler for product with ID \z
            {receiptInfo.ProductId} not found!`
        )
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local success, result = pcall(ProductHandler.Bought, Player, receiptInfo)
    if not success then
        warn(
            `{script}.ProcessReceipt: Failed to process receipt for {Player} \z
            for product {receiptInfo.ProductId}. Error: {result}`
        )
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

return module