--Handles all interactions with trash on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local TrashConfig = require(script.Config)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local SendNotification = ReplicatedCommunication.SendNotification

local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local InventoryHandler = require(ServerScripts.Inventory)
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local UIStorage = ServerStorage.UserInterface
local RVMGui = UIStorage.RVMGui

local module = {}

---Sets up a new trash can
---@param Model Instance The model for the trash can to set up
---@return table
module.NewCan = function(Model: Instance)
    local Can = {}

    Can.Body = Model:FindFirstChild("Can")
    if not Can.Body then
        return warn(`{script}.NewCan: No Can found for {Model:GetFullName()}!`)
    end

    local TrashPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Throw away";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 8;
        Parent = Can.Body;
        RequiresLineOfSight = false;
    })

    TrashPrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.NewCan.TrashPrompt.Triggered: No Character found \z
                for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.NewCan.TrashPrompt.Triggered: No Humanoid found for \z
                {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.NewCan.TrashPrompt.Triggered: {Player} is dead!`
            )
        end

        local Item = Character:FindFirstChildOfClass("Tool")
        if not Item then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "You must be holding an item in your hand to use this!";
                Duration = 10;
            })

            return warn(
                `{script}.NewCan.TrashPrompt.Triggered: {Player} is not \z
                holding a tool!`
            )
        end

        local filename = Item:GetAttribute("FileName")
        local itemName = Item:GetAttribute("DisplayName")
            or filename
            or Item.Name
        local itemConfig = InventoryHandler.Items.Items[filename]
        if not itemConfig then
            return warn(
                `{script}.NewCan.TrashPrompt.Triggered: No item config found \z
                for item with file name {filename}!`
            )
        end
        
        if itemConfig.DontDrop then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = `{itemName} can not be dropped or thrown away!`;
                Duration = 10;
            })

            return warn(
                `{script}.NewCan.TrashPrompt.Triggered: The item with file \z
                name {filename} can not be dropped or thrown away!`
            )
        end

        Item:Destroy()
        Util.RoleplayAction(
            Character.Head,
            `*$\{Associated} throws away their {itemName}.`
        )
    end)

    return Can
end

---Sets up a new reverse vending machine (bottle collector)
---@param Model Instance The model for the RVM to set up
---@return table
module.NewRVM = function(Model: Instance)
    local Machine = {}

    Machine.Hole = Model:FindFirstChild("Hole")
    if not Machine.Hole then
        return warn(
            `{script}.NewRVM: No bottle hole found for {Model:GetFullName()}!`
        )
    end

    Machine.Reader = Model:FindFirstChild("CardReader")
    if not Machine.Reader then
        return warn(
            `{script}.NewRVM: No card reader found for {Model:GetFullName()}!`
        )
    end

    Machine.Screen = Model:FindFirstChild("Screen")
    if not Machine.Screen then
        return warn(
            `{script}.NewRVM: No screen found for {Model:GetFullName()}!`
        )
    end

    local CardPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Tap card";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 8;
        Parent = Machine.Reader;
        RequiresLineOfSight = false;
    }, {
        UsesCard = true;
    })

    local InsertPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Insert bottle";
        ClickablePrompt = true;
        Enabled = false;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 8;
        Parent = Machine.Hole;
        RequiresLineOfSight = false;
    })

    Machine.Gui = RVMGui:Clone()
    Machine.Gui.Parent = Machine.Screen
    local Background = Machine.Gui:WaitForChild("Background")
    local TextDisplay = Background:WaitForChild("Display")

    local DepositSound = Util.CreateInstance("Sound", {
        Parent = Machine.Hole;
        RollOffMaxDistance = 50;
        SoundId = Sounds.RecycleBottle;
        Volume = 0.5;
    })

    ---Ends the current session
    Machine.Conclude = function()
        if Machine.PaidOut > 0 then
            local bottles = Machine.PaidOut / TrashConfig.BottlePayout
            WebhookHandler.Post(
                `{Machine.User:GetAttribute("FullName")} ({Machine.User}) has \z
                claimed ₲{Util.ThousandsSeparate(Machine.PaidOut)} from an \z
                RVM after depositing {bottles} bottle\z
                {bottles == 1 and "" or "s"}. Current balance in bank: ₲\z
                {Util.ThousandsSeparate(
                    Machine.User:GetAttribute("BankBalance")
                )}`,
                "BankLog"
            )
        end

        Machine.LastActivity = 0
        Machine.PaidOut = 0
        Machine.User:SetAttribute("UsingCard", false)
        Machine.User = nil
        CardPrompt.Enabled = true
        InsertPrompt.Enabled = false

        TextDisplay.Text = TrashConfig.TimeoutText
        task.wait(10)
        if TextDisplay.Text == TrashConfig.TimeoutText then
            TextDisplay.Text = TrashConfig.RVMDefaultText
        end
    end

    CardPrompt.Triggered:Connect(function(Player: Player)
        if Machine.User then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "RVM already in use.";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.CardPrompt.Triggered: Active \z
                user {Machine.User} already found!`
            )
        end

        if Player:GetAttribute("UsingCard") then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "Currently using bank card in another machine.";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.CardPrompt.Triggered: \z
                {Player} is currently using their card in another machine.`
            )
        end

        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{Model:GetFullName()}.CardPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Model:GetFullName()}.CardPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Model:GetFullName()}.CardPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        if not Player:GetAttribute("PBNBAccount") then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text =
                    "You must have a bank card in order to use this machine.";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.CardPrompt.Triggered: \z
                {Player} does not have a bank card!`
            )
        end

        Machine.PaidOut = 0
        Machine.User = Player
        Player:SetAttribute("UsingCard", true)
        CardPrompt.Enabled = false
        InsertPrompt.Enabled = true
        TextDisplay.Text = TrashConfig.RVMInteractText

        Machine.LastActivity = os.time()
        while os.time() < Machine.LastActivity + 30 do
            task.wait(1)
        end

        Machine.Conclude()
    end)

    InsertPrompt.Triggered:Connect(function(Player: Player)
        if not Machine.User then
            return warn(
                `{script}.{Model:GetFullName()}.InsertPrompt.Triggered: The \z
                machine is not currently active!`
            )
        end

        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{Model:GetFullName()}.InsertPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Model:GetFullName()}.InsertPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Model:GetFullName()}.InsertPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        local Item = Character:FindFirstChildOfClass("Tool")
        if not Item then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "You must be holding an item in your hand to use this!";
                Duration = 10;
            })

            return warn(
                `{script}.{Model:GetFullName()}.InsertPrompt.Triggered: \z
                {Player} is not holding a tool!`
            )
        end

        local filename = Item:GetAttribute("FileName")
        local itemName = Item:GetAttribute("DisplayName")
            or filename
            or Item.Name
        local itemConfig = InventoryHandler.Items.Items[filename]
        if not itemConfig then
            return warn(
                `{script}.{Model:GetFullName()}.InsertPrompt.Triggered: No \z
                item config found for item with file name {filename}!`
            )
        end
        
        if itemConfig.DontDrop then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = `{itemName} can not be dropped or thrown away!`;
                Duration = 10;
            })

            return warn(
                `{script}.{Model:GetFullName()}.InsertPrompt.Triggered: The \z
                item with file name {filename} can not be dropped or thrown \z
                away!`
            )
        end

        Machine.LastActivity = os.time()
        if not TrashConfig.Recyclable[filename] then
            TextDisplay.Text = TrashConfig.UnknownText
            return warn(
                `{script}.{Model:GetFullName()}.InsertPrompt.Triggered: The \z
                item with file name {filename} is not recyclable!`
            )
        end

        Item:Destroy()
        Util.RoleplayAction(
            Character.Head,
            `*$\{Associated} recycles their {itemName}.`
        )
        Machine.User:SetAttribute(
            "BankBalance",
            Machine.User:GetAttribute("BankBalance") + TrashConfig.BottlePayout
        )
        Machine.PaidOut += TrashConfig.BottlePayout
        TextDisplay.Text = `Paid out a total of ₲{Machine.PaidOut} to \z
            {Machine.User:GetAttribute("FullName")}`

        DepositSound:Play()
    end)

    return Machine
end

return module