--Handles all bartender related tasks on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local JobClient = script.Job

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration
local Util = require(ReplicatedScripts.Util)

local DrinkOrder = ReplicatedCommunication.DrinkOrder
local ListenOrders = ReplicatedCommunication.ListenOrders
local SendNotification = ReplicatedCommunication.SendNotification

local JobConfig = require(ReplicatedConfig.Jobs.Bartender)
local JobHandler

local PrivateStorage = ServerStorage.PrivateStorage

local activeOrders = {}

local module = {}

---Process a completed drink order
---@param Player Player The Player performing the job
---@param served table The drinks served
DrinkOrder.OnServerEvent:Connect(function(Player: Player, served: table)
    if
        not Player:GetAttribute("Occupation") == "Bartender"
        and Player:GetAttribute("Working")
    then
        return warn(
            `{script}.DrinkOrder.OnServerEvent: {Player} is not an on-duty \z
            bartender!`
        )
    end

    local order = activeOrders[Player]
    if not order then
        return warn(
            `{script}.DrinkOrder.OnServerEvent: {Player} does not currently \z
            have a pending drink order!`
        )
    end

    if #served ~= #order then
        return warn(
            `{script}.DrinkOrder.OnServerEvent: {Player} made the wrong \z
            number of drinks!`
        )
    end

    local orderSpeed = #order * 1.5
    local repeats = {}
    for i, drink in ipairs(order) do
        repeats[drink.Drink] = (repeats[drink.Drink] or 0) + 1
    end
    local maxRepeats = 0
    for drink, repeating in pairs(repeats) do
        maxRepeats = math.max(maxRepeats, repeating)
    end
    orderSpeed += maxRepeats * JobConfig.FillTime
    
    print(
        `{script}.DrinkOrder.OnServerEvent: Minimum drink speed for order of \z
        {#order} drinks for {Player} determined as \z
        {Util.ReadableTime(orderSpeed)}.`
    )

    if os.time() < order.At + orderSpeed then
        return warn(
            `{script}.DrinkOrder.OnServerEvent: {Player} made their order too \z
            fast! (Length: {#order}, completed in {os.time() - order.At}s})`
        )
    end

    for i, drink in ipairs(order) do
        local found
        for j, made in ipairs(served) do
            if made.Drink == drink.Drink and made.Size == drink.Size then
                found = j
                break
            end
        end
        if not found then
            module.NewOrder(Player)
            SendNotification:FireClient(Player, {
                Title = "Incorrect order!";
                Text = "You will not be paid for this order.";
                Duration = 10;
            })
            return warn(
                `{script}.DrinkOrder.OnServerEvent: {Player} made a drink \z
                order incorrectly!`
            )
        else
            table.remove(served, found)
        end
    end

    local experience = 0
    local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
        Player:GetAttribute("ID")
    }`)
    if PrivatePlayer then
        experience = PrivatePlayer:GetAttribute("BartenderExperience") or 0
    end

    print(
        `{script}.DrinkOrder.OnServerEvent: {Player} has completed a drink \z
        order of {#order} drink{#order == 1 and "" or "s"} in \z
        {Util.ReadableTime(os.time() - order.At)}.`
    )
    local paid = JobHandler.Pay(Player, ((JobConfig.BasePay * #order) +
        (experience * 0.01)) * (Player:GetAttribute("Citizenship") == "North"
        and 1.5 or 1))
    SendNotification:FireClient(Player, {
        Title = "Order complete!";
        Text = `₲{paid} have been added to your next paycheck.`;
        Duration = 10;
    })
    module.NewOrder(Player)
end)

---Informs the server that the client is ready to receive drink orders
---@param Player Player The Player serving drinks
ListenOrders.OnServerEvent:Connect(function(Player: Player)
    if
        not Player:GetAttribute("Occupation") == "Bartender"
        and Player:GetAttribute("Working")
    then
        return warn(
            `{script}.ListenOrders.OnServerEvent: {Player} is not an on-duty \z
            bartender!`
        )
    end

    Player:SetAttribute("BartenderListening", true)
end)

---End the shift of a given Player
---@param Player Player The Player clocking out
module.End = function(Player: Player)
    activeOrders[Player] = nil
    Player:SetAttribute("BartenderListening", nil)
end

---Creates a local reference to the JobHandler module
---@param Handler table The JobHandler module
module.JHPass = function(Handler: table)
    JobHandler = Handler
end

---Generate a drink order and send it to a Player
---@param Player Player The Player to send the order to
module.NewOrder = function(Player: Player)
    local order = {}
    for i = 1, math.random(1, JobConfig.MaxOrder) do
        table.insert(order, {
            Drink = Util.RandomFrom(JobConfig.TapList);
            Size = Util.RandomFrom(JobConfig.SizeList);
        })
    end

    print(`{script}.NewOrder: Sending order of {#order} drinks to {Player}`)
    if not Player:GetAttribute("BartenderListening") then
        Player:GetAttributeChangedSignal("BartenderListening"):Wait()
    end
    DrinkOrder:FireClient(Player, order)
    order.At = os.time()
    activeOrders[Player] = order
end

---Check if a Player meets the requirements for the job
---@param Player Player The Player applying for the job
---@return boolean
---@return string
module.Requirements = function(Player: Player)
    if not Player:GetAttribute("PBNBAccount") then
        return false, "NoBank", warn(
            `{script}.Requirements: {Player} does not have a bank account!`
        )
    end

    return true
end

---Start the bartender job for a given Player
---@param Player Player The Player to start the job for
module.Start = function(Player: Player)
    task.spawn(function()
        task.wait(JobConfig.StartDelay)
        JobClient:Clone().Parent = Player.PlayerGui
        module.NewOrder(Player)
    end)
end

return module