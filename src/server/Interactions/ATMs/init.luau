--This script handles the server-side portion of ATM interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Pages = require(script.Pages)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local InventoryHandler = require(ServerScripts.Inventory)
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local UIStorage = ServerStorage.UserInterface
local ATMGui = UIStorage.ATMGui

local ButtonBeep = Util.CreateInstance("Sound", {
    Name = "ButtonBeep";
    RollOffMaxDistance = 10;
    SoundId = Sounds.ATMBeep;
    Volume = 0.25;
})

local Displays = {}
for i, Locale in ipairs(script.Displays:GetChildren()) do
    Displays[Locale.Name] = require(Locale)
end
Pages.Displays = Displays

local module = {}

---Sets up an ATM and all interaction with it
---@param Model Instance The ATM to set up
---@return table
module.Setup = function(Model: Instance)
    local ATM = {}
    ATM.Model = Model

    ATM.CashOutput = Model:FindFirstChild("CashOutput")
    if not ATM.CashOutput then
        return warn(
            `{script}.Setup: \z
            No cash slot found for ATM {Model:GetFullName()}`
        )
    end

    ATM.Screen = Model:FindFirstChild("Screen")
    if not ATM.Screen then
        return warn(
            `{script}.Setup: \z
            No screen found for ATM {Model:GetFullName()}`
        )
    end

    ATM.DispenseSound = Util.CreateInstance("Sound", {
        Name = "DispenseCash";
        Parent = ATM.Screen;
        RollOffMaxDistance = 30;
        SoundId = Sounds.ATMDispense;
        Volume = 0.25;
    })

    ATM.Language = "en"
    ATM.Gui = ATMGui:Clone()
    ATM.Gui.Parent = ATM.Screen

    ATM.Background = ATM.Gui:WaitForChild("Background")
    ATM.Header = ATM.Background:WaitForChild("Header")
    ATM.Header = ATM.Header:WaitForChild("HeadDisplay")

    ATM.CancelButton = Model:FindFirstChild("CancelButton")
    if not ATM.CancelButton then
        return warn(
            `{script}.Setup: \z
            No cancel button found for ATM {Model:GetFullName()}`
        )
    end

    local CancelBeep = ButtonBeep:Clone()
    CancelBeep.Parent = ATM.Screen

    Util.CreateInstance("ClickDetector", {
        MaxActivationDistance = 0;
        Parent = ATM.CancelButton;
    }).MouseClick:Connect(function(Player: Player)
        if Player ~= ATM.User then
            return warn(
                `{script}.{Model:GetFullName()}.CancelButton.MouseClick: \z
                Player {Player} is not the active user of the ATM! ({ATM.User})`
            )
        end

        CancelBeep:Play()
        ATM.LastActivity = os.time()
        if not ATM.CurrentPage.Cancel then
            ATM.Conclude("SuccessfulWithdraw")
        else
            ATM.CurrentPage.Cancel(ATM)
        end
    end)

    ATM.EnterButton = Model:FindFirstChild("EnterButton")
    if not ATM.EnterButton then
        return warn(
            `{script}.Setup: \z
            No enter button found for ATM {Model:GetFullName()}`
        )
    end

    local EnterBeep = ButtonBeep:Clone()
    EnterBeep.Parent = ATM.Screen

    Util.CreateInstance("ClickDetector", {
        MaxActivationDistance = 0;
        Parent = ATM.EnterButton;
    }).MouseClick:Connect(function(Player: Player)
        if Player ~= ATM.User then
            return warn(
                `{script}.{Model:GetFullName()}.EnterButton.MouseClick: \z
                Player {Player} is not the active user of the ATM! ({ATM.User})`
            )
        end

        if not ATM.CurrentPage.Enter then
            return warn(
                `{script}.{Model:GetFullName()}.EnterButton.MouseClick: \z
                The enter button is not active on page {ATM.CurrentPage.Page}!`
            )
        end

        EnterBeep:Play()
        ATM.LastActivity = os.time()
        ATM.CurrentPage.Enter(ATM)
    end)

    ATM.MFDButtons = {}
    for i = 1, 6 do
        local Button = Model:FindFirstChild(`MFDButton{i}`)
        if not Button then
            return warn(
                `{script}.Setup: \z
                Unable to find MFDButton{i} for ATM {Model:GetFullName()}`
            )
        end

        local MFDBeep = ButtonBeep:Clone()
        MFDBeep.Parent = ATM.Screen

        Util.CreateInstance("ClickDetector", {
            MaxActivationDistance = 0;
            Parent = Button;
        }).MouseClick:Connect(function(Player: Player)
            if Player ~= ATM.User then
                return warn(
                    `{script}.{Model:GetFullName()}.{Button}.MouseClick: \z
                    {Player} is not the active user of the ATM! ({ATM.User})`
                )
            end

            if not ATM.CurrentPage.MFDs then
                return warn(
                    `{script}.{Model:GetFullName()}.{Button}.MouseClick: \z
                    No MFD buttons active on page {ATM.CurrentPage.Page}.`
                )
            end

            local onPress = ATM.CurrentPage.MFDs[i]
            if onPress then
                MFDBeep:Play()
                ATM.LastActivity = os.time()
                onPress(ATM)
            end
        end)

        table.insert(ATM.MFDButtons, Button)
    end

    ATM.NumberButtons = {}
    for i = 0, 9 do
        local Button = Model:FindFirstChild(`NumButton{i}`)
        if not Button then
            return warn(
                `{script}.Setup: \z
                Unable to find NumButton{i} for ATM {Model:GetFullName()}`
            )
        end

        local NumberBeep = ButtonBeep:Clone()
        NumberBeep.Parent = ATM.Screen

        Util.CreateInstance("ClickDetector", {
            MaxActivationDistance = 0;
            Parent = Button;
        }).MouseClick:Connect(function(Player: Player)
            if Player ~= ATM.User then
                return warn(
                    `{script}.{Model:GetFullName()}.{Button}.MouseClick: \z
                    Player {Player} is not the active user of the ATM! \z
                    ({ATM.User})`
                )
            end
    
            if not ATM.CurrentPage.NumberInput then
                return warn(
                    `{script}.{Model:GetFullName()}.{Button}.MouseClick: \z
                    The number buttons are not active on page \z
                    {ATM.CurrentPage.Page}!`
                )
            end

            NumberBeep:Play()
            ATM.LastActivity = os.time()
            ATM.CurrentPage.NumberInput(ATM, i)
        end)

        table.insert(ATM.NumberButtons, Button)
    end

    ---Concludes the ATM session and display the final message
    ---@param message string The message to display
    ATM.Conclude = function(message: string)
        ATM.SetScreen("EndPage")
        ATM.CurrentPage.Page.MessageDisplay.Text =
            Displays[ATM.Language][message]

        ATM.CancelButton.ClickDetector.MaxActivationDistance = 0
        ATM.EnterButton.ClickDetector.MaxActivationDistance = 0

        for i, Child in ipairs(ATM.MFDButtons) do
            local Detector = Child:FindFirstChildWhichIsA("ClickDetector")
            Detector.MaxActivationDistance = 0
        end

        for i, Child in ipairs(ATM.NumberButtons) do
            local Detector = Child:FindFirstChildWhichIsA("ClickDetector")
            Detector.MaxActivationDistance = 0
        end

        ATM.Language = "en"
        if typeof(ATM.User) == "Instance" then
            ATM.User:SetAttribute("UsingCard", false)
        end
        ATM.User = nil

        task.wait(10)

        ATM.Prompt.Enabled = true
        ATM.SetScreen("HomePage")
    end

    ---Changes the screen of the ATM
    ---@param screen string The screen to change to
    ATM.SetScreen = function(screen: string)
        local Page = ATM.Background:FindFirstChild(screen)
        if not Page then
            return warn(
                `{script}.{Model:GetFullName()}.SetScreen: \z
                Unable to find ATM screen {screen}`
            )
        end

        local pageInfo = Pages[screen]
        if not pageInfo then
            return warn(
                `{script}.{Model:GetFullName()}.SetScreen: \z
                Unable to find ATM page info for {screen}`
            )
        end

        for HidePage, info in Pages do
            if ATM.Background:FindFirstChild(HidePage) then
                ATM.Background[HidePage].Visible = false
            end
        end
        ATM.CurrentPage = pageInfo
        ATM.CurrentPage.Page = Page

        if pageInfo.Setup then
            pageInfo.Setup(ATM)
        end

        Page.Visible = true

        ATM.Header.Text = Displays[ATM.Language or "en"][pageInfo.Header]
    end

    ---Withdraws a stack of cash from the ATM
    ---@param amount number The amount to withdraw
    ATM.Withdraw = function(amount: number)
        if amount <= 0 or math.floor(amount) ~= amount then
            warn(
                `{script}.{Model:GetFullName()}.Withdraw: \z
                Amount must be a positive integer. \z
                (Got {amount} from {ATM.User})`
            )
            return ATM.Conclude("InvalidInput")
        end

        if amount % 500 > 0 then
            warn(
                `{script}.{Model:GetFullName()}.Withdraw: \z
                Expected a multiple of 500, got {amount} from {ATM.User}`
            )
            return ATM.Conclude("InvalidInput")
        end

        local bills = Util.BillsRequired(amount)
        if #bills > 30 then
            warn(
                `{script}.{Model:GetFullName()}.Withdraw: \z
                Stack size too large, got {amount} (stack size: {#bills}) \z
                from {ATM.User}`
            )
            return ATM.Conclude("InvalidInput")
        end

        local balance = ATM.User:GetAttribute("BankBalance") or 0
        if amount > balance then
            warn(
                `{script}.{Model:GetFullName()}.Withdraw: \z
                {ATM.User} attempted to overdraw! \z
                (Balance: {balance}, Requested: {amount})`
            )
            return ATM.Conclude("Overdraw")
        end

        ATM.User:SetAttribute("BankBalance", balance - amount)

        ATM.DispenseSound:Play()        
        
        local Stack = InventoryHandler.Items.new(
            "Cash",
            `ATM (account of {ATM.User:GetAttribute("FullName")})`,
            {
                Value = amount;
            }
        )
        InventoryHandler.Drop(Stack, ATM.CashOutput.CFrame, true)

        WebhookHandler.Post(
            `{ATM.User:GetAttribute("FullName")} ({ATM.User}) has withdrawn \z
            ₲{Util.ThousandsSeparate(amount)} from an ATM. Current balance in \z
            bank: ₲{Util.ThousandsSeparate(balance - amount)}`,
            "BankLog"
        )

        ATM.Conclude("SuccessfulWithdraw")
    end

    ATM.Prompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Tap card";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 4.5;
        Name = "ATMPrompt";
        Parent = ATM.Screen;
        RequiresLineOfSight = false;
    }, {
        UsesCard = true;
    })

    ATM.Prompt.Triggered:Connect(function(Player: Player)
        if ATM.User then
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                ATM already in use by {ATM.User}.`
            )
        end

        if Player:GetAttribute("UsingCard") then
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                {Player} is currently using their card in another machine.`
            )
        end

        if not Player:GetAttribute("PBNBAccount") then
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                {Player} does not have a bank card!`
            )
        end

        local Humanoid = Player.Character
            and Player.Character:FindFirstChildWhichIsA("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                {Player}'s Character is not alive!`
            )
        end

        ATM.Prompt.Enabled = false

        ATM.CancelButton.ClickDetector.MaxActivationDistance = 8
        ATM.EnterButton.ClickDetector.MaxActivationDistance = 8

        for i, Child in ipairs(ATM.MFDButtons) do
            local Detector = Child:FindFirstChildWhichIsA("ClickDetector")
            Detector.MaxActivationDistance = 8
        end

        for i, Child in ipairs(ATM.NumberButtons) do
            local Detector = Child:FindFirstChildWhichIsA("ClickDetector")
            Detector.MaxActivationDistance = 8
        end

        ATM.User = Player
        ATM.User:SetAttribute("UsingCard", true)

        ATM.SetScreen(
            Player:GetAttribute("BankFrozen") and "FrozenPage" or "LanguagePage"
        )

        ATM.LastActivity = os.time()
        while os.time() < ATM.LastActivity + 10 do
            task.wait(1)
        end
        
        if ATM.User then
            ATM.Conclude("Timeout")
        end
    end)

    return ATM
end

return module