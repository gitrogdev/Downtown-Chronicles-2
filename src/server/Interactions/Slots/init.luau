--The server-side portion of slot machine interactions
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Coordinator = require(script.Coordinator)
local Config = require(script.Config)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local SendNotification = ReplicatedCommunication.SendNotification

local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local Badges = require(ServerConfig.Badges)

local PrivateStorage = ServerStorage.PrivateStorage
local UIStorage = ServerStorage.UserInterface

local MainGui = UIStorage.SlotMainGui
local TopGui = UIStorage.SlotTopGui

local module = {}

module.JackpotLights = {}

---Adds a new light to flash when the jackpot is won
---@param JackpotLight Instance The light to add
---@return Instance
module.AddLight = function(JackpotLight: Instance)
    table.insert(module.JackpotLights, JackpotLight)
    return JackpotLight
end

---Sets up a slot machine and all interaction with it
---@param Model Instance The slot machine to set up
---@return table
module.Setup = function(Model: Instance)
    local Machine = {}
    Machine.Config = table.clone(Config)
    Machine.Model = Model

    Machine.MainScreen = Model:FindFirstChild("MainScreen")
    if not Machine.MainScreen then
        return warn(
            `{script}.Setup: \z
            No main screen found for slot machine {Model:GetFullName()}`
        )
    end

    Machine.TopScreen = Model:FindFirstChild("TopScreen")
    if not Machine.TopScreen then
        return warn(
            `{script}.Setup: \z
            No top screen found for slot machine {Model:GetFullName()}`
        )
    end

    Machine.MainGui = MainGui:Clone()
    Machine.TopGui = TopGui:Clone()

    Machine.CardReader = Model:FindFirstChild("CardReader")
    if not Machine.CardReader then
        return warn(
            `{script}.Setup: \z
            No card reader found for slot machine {Model:GetFullName()}`
        )
    end

    Machine.ResetButton = Model:FindFirstChild("ResetButton")
    if not Machine.ResetButton then
        return warn(
            `{script}.Setup: \z
            No reset button found for slot machine {Model:GetFullName()}`
        )
    end

    Util.CreateInstance("ClickDetector", {
        MaxActivationDistance = 0;
        Parent = Machine.ResetButton;
    }).MouseClick:Connect(function(Player: Player)
        if Player ~= Machine.User then
            return warn(
                `{script}.{Model:GetFullName()}.ResetButton.MouseClick: \z
                Player {Player} is not the active user of the slot machine! \z
                ({Machine.User})`
            )
        end

        if Machine.Spinning then
            return warn(
                `{script}.{Model:GetFullName()}.ResetButton.MouseClick: \z
                Slot machine currently spinning!`
            )
        end

        Machine.Reset()
    end)

    Machine.SpinButton = Model:FindFirstChild("SpinButton")
    if not Machine.SpinButton then
        return warn(
            `{script}.Setup: \z
            No spin button found for slot machine {Model:GetFullName()}`
        )
    end

    Util.CreateInstance("ClickDetector", {
        MaxActivationDistance = 0;
        Parent = Machine.SpinButton;
    }).MouseClick:Connect(function(Player: Player)
        if Player ~= Machine.User then
            return warn(
                `{script}.{Model:GetFullName()}.SpinButton.MouseClick: \z
                Player {Player} is not the active user of the slot machine! \z
                ({Machine.User})`
            )
        end

        if Machine.Spinning then
            return warn(
                `{script}.{Model:GetFullName()}.SpinButton.MouseClick: \z
                Slot machine already spinning!`
            )
        end

        local balance = Player:GetAttribute("BankBalance") or 0
        local spins = Player:GetAttribute("FreeSpins") or 0
        if balance < Machine.Config.MinBet * Machine.Bet and spins < 1 then
            return warn(
                `{script}.{Model:GetFullName()}.SpinButton.MouseClick: \z
                Player {Player} has insufficient funds to spin the machine! \z
                (Minimum: ₲{Machine.Config.MinBet}, Bet: x{Machine.Bet}, \z
                Balance: ₲{balance})`
            )
        end

        if spins < 1 then
            Player:SetAttribute(
                "BankBalance",
                balance - (Machine.Config.MinBet * Machine.Bet)
            )
            Machine.Spent += Machine.Config.MinBet * Machine.Bet
        else
            if Machine.Bet > spins then
                Machine.SetBet(spins)
            end

            Player:SetAttribute("FreeSpins", spins - Machine.Bet)
        end

        local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
            Player:GetAttribute("ID")
        }`)
        if PrivatePlayer then
            PrivatePlayer:SetAttribute(
                "CasinoLosses",
                (PrivatePlayer:GetAttribute("CasinoLosses") or 0)
                    + (Machine.Config.MinBet * Machine.Bet)
            )
        end

        Machine.LastActivity = os.time()
        Machine.Spin()
    end)

    Machine.BetButtons = {}
    for i = 1, 5 do
        local Button = Model:FindFirstChild(`Bet{i}Button`)
        if not Button then
            return warn(
                `{script}.Setup: Unable to find Bet{i}Button for slot machine \z
                {Model:GetFullName()}`
            )
        end

        Util.CreateInstance("ClickDetector", {
            MaxActivationDistance = 0;
            Parent = Button;
        }).MouseClick:Connect(function(Player: Player)
            if Player ~= Machine.User then
                return warn(
                    `{script}.{Model:GetFullName()}.{Button}.MouseClick: \z
                    {Player} is not the active user of the slot machine! \z
                    ({Machine.User})`
                )
            end

            if Machine.Spinning then
                return warn(
                    `{script}.{Model:GetFullName()}.{Button}.MouseClick: \z
                    Slot machine already spinning!`
                )
            end

            Machine.LastActivity = os.time()
            Machine.SetBet(i)
        end)

        table.insert(Machine.BetButtons, Button)
    end

    Machine.ScreenClick = Util.CreateInstance("ClickDetector", {
        MaxActivationDistance = 0;
        Parent = Machine.MainScreen;
    })
    Machine.ScreenClick.MouseClick:Connect(function(Player: Player)
        if Player ~= Machine.User then
            return warn(
                `{script}.{Model:GetFullName()}.ScreenClick.MouseClick: \z
                Player {Player} is not the active user of the slot machine! \z
                ({Machine.User})`
            )
        end

        if (Machine.CanClick or 0) <= tick() then
            Machine.CanClick = tick() + Config.ClickCooldown
            Machine.ClickSound:Play()
        end
    end)

    local MainBackground = Machine.MainGui.Background
    local BalanceDisplay = MainBackground.BalanceDisplay
    local BetDisplay = MainBackground.BetDisplay
    local ColumnHolder = MainBackground.ColumnHolder
    local FreeDrink = MainBackground.FreeDrink
    local MessageDisplay = MainBackground.MessageDisplay
    local SpinDisplay = MainBackground.SpinDisplay
    local WelcomeBonus = MainBackground.WelcomeBonus
    local WinDisplay = MainBackground.WinDisplay

    local ColumnTemplate = ColumnHolder.ColumnTemplate
    Machine.Columns = {}
    for i = 1, Machine.Config.Columns do
        local Column = ColumnTemplate:Clone()
        Column.Name = `Column{i}`
        Column.Visible = true
        Column.Parent = ColumnHolder

        local SlotTemplate = Column:WaitForChild("SlotTemplate")

        Machine.Columns[i] = {
            Column = Column;

            ---Spin an individual column of the slot machine
            ---@param cycle number The number of reels to generate
            ---@param instant boolean Whether to run the algorithm only
            Spin = function(cycle: number, instant: boolean)
                Machine.Columns[i].Sequence = {}
                Machine.Columns[i].Spinning = true

                if instant then
                    cycle = Machine.Config.Rows
                end

                local speed = 1 / cycle / Machine.Config.Rows
                if not instant then
                    for j, Slot in ipairs(Column:GetChildren()) do
                        if Slot.Name:find("ActiveSlot") then
                            task.spawn(function()
                                for k = Slot.Position.Y.Scale / 0.25,
                                    Machine.Config.Rows
                                do
                                    local Tween = TweenService:Create(
                                        Slot,
                                        TweenInfo.new(
                                            speed,
                                            Enum.EasingStyle.Linear
                                        ), {
                                            Position = UDim2.fromScale(
                                                0,
                                                0.25 * k
                                            )
                                        }
                                    )
                                    Tween:Play()
                                    Tween.Completed:Wait()
                                end
                                Slot:Destroy()
                            end)
                        end
                    end
                end

                for j = 1, cycle do
                    speed = j / cycle / Machine.Config.Rows / 3

                    local useIcon, key
                    if math.random(1, math.floor(
                            Coordinator.JackpotOdds() * (
                                (not instant and Machine.User.MembershipType
                                == Enum.MembershipType.Premium) and 0.8
                                or 1
                            )
                        )) == 1
                    then
                        useIcon, key = Machine.Config.Jackpot, "Jackpot"
                    else
                        useIcon, key = Util.RandomFrom(Machine.Config.Reels)
                    end

                    if instant then
                        table.insert(Machine.Columns[i].Sequence, key)
                        continue
                    end

                    local Slot = SlotTemplate:Clone()
                    Slot.Image = `rbxassetid://{useIcon.Image}`
                    Slot.ImageColor3 = useIcon.ImageColor
                        or Color3.new(1, 1, 1)
                    
                    if key == "Jackpot" then
                        Slot.BackgroundTransparency = 0
                        Slot.BorderSizePixel = 5
                    end

                    Slot.Visible = true
                    Slot.Parent = Column

                    task.spawn(function()
                        local goTo = cycle - j
                        if goTo > Machine.Config.Rows then
                            goTo = Machine.Config.Rows
                        end
                        for k = 0, goTo do
                            local Tween = TweenService:Create(
                                Slot,
                                TweenInfo.new(speed, Enum.EasingStyle.Linear),
                                {
                                    Position = UDim2.fromScale(0, 0.25 * k)
                                }
                            )
                            Tween:Play()
                            Tween.Completed:Wait()
                        end

                        if goTo == Machine.Config.Rows then
                            Slot:Destroy()
                        else
                            table.insert(Machine.Columns[i].Sequence, key)
                            Slot.Name = `ActiveSlot{key}`
                        end
                    end)

                    task.wait(speed)
                end
                Machine.Columns[i].Spinning = false
            end;
        }
    end

    Machine.MainGui.Parent = Machine.MainScreen
    Machine.TopGui.Parent = Machine.TopScreen
    local updateDisplay = Coordinator.AddDisplay(Machine, Machine.TopGui)

    Machine.ClickSound = Util.CreateInstance("Sound", {
        Name = "ClickSound";
        Parent = Machine.MainScreen;
        RollOffMaxDistance = 15;
        SoundId = Sounds.SlotClick;
        Volume = 0.25;
    })

    Machine.JackpotSound = Util.CreateInstance("Sound", {
        Name = "JackpotSound";
        Parent = Machine.MainScreen;
        RollOffMaxDistance = 30;
        SoundId = Sounds.SlotJackpot;
        Volume = 0.5;
    })

    Machine.MultiplierSound = Util.CreateInstance("Sound", {
        Name = "MultiplierSound";
        Parent = Machine.MainScreen;
        RollOffMaxDistance = 15;
        SoundId = Sounds.SlotMultiplier;
        Volume = 0.25;
    })

    Machine.SpinSound = Util.CreateInstance("Sound", {
        Name = "SpinSound";
        Parent = Machine.MainScreen;
        RollOffMaxDistance = 30;
        SoundId = Sounds.SlotSpin;
        Volume = 0.5;
    })

    Machine.WinSound = Util.CreateInstance("Sound", {
        Name = "WinSound";
        Parent = Machine.MainScreen;
        RollOffMaxDistance = 30;
        SoundId = Sounds.SlotWin;
        Volume = 0.5;
    })

    Machine.LoseSound = Util.CreateInstance("Sound", {
        Name = "LoseSound";
        Parent = Machine.MainScreen;
        RollOffMaxDistance = 30;
        SoundId = Sounds.SlotLose;
        Volume = 0.5;
    })

    ---Set the bet and illuminate the appropriate button
    ---@param bet number The bet to set the machine to
    Machine.SetBet = function(bet: number)
        FreeDrink.Visible = false
        WelcomeBonus.Visible = false
        Machine.Bet = bet
        updateDisplay()
        for i, Button in ipairs(Machine.BetButtons) do
            Button.Material = Enum.Material[(i == bet and "Neon") or "Glass"]
        end
        BetDisplay.Text = bet * Machine.Config.MinBet
        Machine.UpdateLine(`Bet Multiplier {bet}`, 1)
    end

    ---Conclude the interaction with the machine
    Machine.Reset = function()
        if typeof(Machine.User) == "Instance" then
            FreeDrink.Visible = false
            WelcomeBonus.Visible = false
            local playtime = os.time() - Machine.FirstActivity

            Machine.User:SetAttribute("UsingCard", false)

            local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
                Machine.User:GetAttribute("ID")
            }`)
            if PrivatePlayer then
                PrivatePlayer:SetAttribute("CasinoTime",
                    PrivatePlayer:GetAttribute("CasinoTime") + playtime
                )
            end

            if Machine.Won > Machine.Spent then
                WebhookHandler.Post(
                    `{Machine.User:GetAttribute("FullName")} \z
                    ({Machine.User}) has won ₲{Util.ThousandsSeparate(
                        Machine.Won - Machine.Spent
                    )} from a slot machine after \z
                    {Util.ReadableTime(playtime)} of gaming. Current balance \z
                    in bank: ₲{Util.ThousandsSeparate(
                        Machine.User:GetAttribute("BankBalance")
                    )}`,
                    "BankLog"
                )
            end
        end
        Machine.User = nil

        Machine.Message = {"","",""}
        Machine.SetBet(1)
        Machine.Spent = 0
        Machine.Won = 0
        updateDisplay()

        BalanceDisplay.Text = "0"
        SpinDisplay.Text = "0"
        WinDisplay.Text = "0"

        Machine.Prompt.Enabled = true

        Machine.ResetButton.ClickDetector.MaxActivationDistance = 0
        Machine.SpinButton.ClickDetector.MaxActivationDistance = 0

        for i, Child in ipairs(Machine.BetButtons) do
            Child.Material = Enum.Material.Glass
            local Detector = Child:FindFirstChildWhichIsA("ClickDetector")
            Detector.MaxActivationDistance = 0
        end

        if Machine.UpdateBalance then
            Machine.UpdateBalance:Disconnect()
        end

        if Machine.UpdateSpins then
            Machine.UpdateSpins:Disconnect()
        end
    end

    ---Spin the slot machine one time
    ---@param instant boolean Whether to run the algorithm without displaying
    Machine.Spin = function(instant: boolean)
        FreeDrink.Visible = false
        WelcomeBonus.Visible = false
        Machine.Spinning = true
        if not instant then
            for i, Column in ipairs(Machine.Columns) do
                task.spawn(Column.Spin, 10 + (i * 10))
            end

            Machine.UpdateLine("GOOD LUCK", 2)
            Machine.UpdateLine("", 3)
            Machine.ScreenClick.MaxActivationDistance = 8
            Machine.ResetButton.ClickDetector.MaxActivationDistance = 0
            Machine.SpinButton.ClickDetector.MaxActivationDistance = 0
            for i, Child in ipairs(Machine.BetButtons) do
                local Detector = Child:FindFirstChildWhichIsA("ClickDetector")
                Detector.MaxActivationDistance = 0
            end
            Machine.SpinSound:Play()

            local spinning
            repeat
                task.wait(1)
                spinning = false
                for i, Column in ipairs(Machine.Columns) do
                    if Column.Spinning then
                        spinning = true
                        break
                    end
                end
            until not spinning
            Machine.ScreenClick.MaxActivationDistance = 0
            Machine.SpinSound:Stop()
        else
            for i, Column in ipairs(Machine.Columns) do
                Column.Spin(Machine.Config.Rows, instant)
            end
        end

        local sequence = {}
        for i, Column in ipairs(Machine.Columns) do
            table.insert(sequence, Column.Sequence)
        end
        
        local total = 0
        local winDrink
        local winJackpot
        local jackpots = {}
        local wins = {}
        for i, results in ipairs(sequence) do
            for j, reel in ipairs(results) do
                if reel == 0 then
                    continue
                end

                local length = 0
                for k = i, #sequence do
                    local checkResults = sequence[k]
                    local continues
                    for l, checkReel in ipairs(checkResults) do
                        if checkReel == reel then
                            if instant and reel == "Jackpot" then
                                table.insert(jackpots, checkReel)
                            end
                            checkResults[l] = 0
                            continues = true
                        end
                    end

                    if not continues then
                        break
                    end
                    length += 1
                end

                if instant and reel == "Jackpot" then
                    table.insert(jackpots, reel)
                end

                local reelConfig = reel == "Jackpot" and Machine.Config.Jackpot
                    or Machine.Config.Reels[reel]
                local result = reelConfig.Rules[length]
                if result then
                    if not instant then
                        local toBlink = {}
                        for k = i, i + length - 1 do
                            local Column = Machine.Columns[k].Column
                            for l, Reel in ipairs(Column:GetChildren()) do
                                if Reel.Name == `ActiveSlot{reel}` then
                                    table.insert(toBlink, Reel)
                                end
                            end
                        end

                        if #toBlink > 0 then
                            table.insert(wins, {
                                Count = length;
                                Name = reelConfig.Name;
                                Reels = toBlink;
                                Result = result;
                            })
                            if reelConfig.Name == "VALAK"
                                and not Model:GetAttribute("External")
                            then
                                winDrink = true
                            end
                        end
                    end

                    if reel == "Jackpot" then
                        winJackpot = true
                    end
                    total += result
                end
            end
        end

        if not instant then
            for i, Column in ipairs(Machine.Columns) do
                for j, Reel in ipairs(Column.Column:GetChildren()) do
                    if Reel.Name == "ActiveSlotJackpot" then
                        table.insert(jackpots, Reel)
                    end
                end
            end
        end

        if total > 0 then
            local winnings = math.floor(
                (total + ((winJackpot and Coordinator.WinJackpot()) or 0))
                * Machine.Bet
                * (2 ^ #jackpots)
            )
            
            if not instant then
                print(
                    `{script}.{Model:GetFullName()}.Spin: \z
                    {Machine.User} won a total of ₲{winnings} from the slot \z
                    machine! (Won ₲{total}, Bet x{Machine.Bet}\z
                    {#jackpots > 0 and `, Multiplier {2 ^ #jackpots}x` or ""})`
                )
                Machine.User:SetAttribute(
                    "BankBalance",
                    (Machine.User:GetAttribute("BankBalance") or 0) + winnings
                )

                local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
                    Machine.User:GetAttribute("ID")
                }`)
                if PrivatePlayer then
                    PrivatePlayer:SetAttribute(
                        "CasinoWinnings",
                        (PrivatePlayer:GetAttribute("CasinoWinnings") or 0)
                            + winnings
                    )
                end

                local ValueHolder = Util.CreateInstance("NumberValue", {
                    Value = Machine.Won
                })
                ValueHolder:GetPropertyChangedSignal("Value"):Connect(function()
                    Machine.Won = math.floor(ValueHolder.Value)
                    WinDisplay.Text = Util.ThousandsSeparate(Machine.Won)
                end)
                
                local countTime = ((#wins > 0 and 2 * #wins) or 0 ) +
                    ((#jackpots > 0 and 2 * #jackpots) or 0)
                local CountTween = TweenService:Create(ValueHolder,
                    TweenInfo.new(
                        countTime,
                        Enum.EasingStyle.Linear
                    ), {
                        Value = Machine.Won + winnings;
                    }
                )
                task.spawn(function()
                    task.wait(countTime)
                    Machine.Spinning = false
                end)
                CountTween:Play()
                
                if #wins > 0 then
                    local wonJackpot
                    for i, win in ipairs(wins) do
                        Machine.UpdateLine("Great Success!!", 2)
                        Machine.UpdateLine(
                            `{Util.EnglishNumber(win.Count)} {win.Name} wins \z
                            {win.Result}{
                                Machine.Bet > 1 and ` (x{Machine.Bet})` or ""
                            }`,
                            3
                        )

                        if win.Name == Machine.Config.Jackpot.Name then
                            if
                                not PrivatePlayer:GetAttribute("BadgeJackpot")
                            then
                                BadgeService:AwardBadge(
                                    Machine.User.UserId,
                                    Badges.Jackpot
                                )
                            end

                            wonJackpot = true
                            Machine.JackpotSound:Play()
                            task.spawn(function()
                                local setTo = Config.LightColors.Base
                                repeat
                                    setTo = setTo ==
                                        Config.LightColors.Base and
                                        Config.LightColors.Jackpot or
                                        Config.LightColors.Base
                                    for j, JackpotLight in
                                        ipairs(module.JackpotLights)
                                    do
                                        JackpotLight.Color = setTo
                                        if JackpotLight:FindFirstChild(
                                            "PointLight"
                                        ) then
                                            JackpotLight.PointLight.Color =
                                                setTo
                                        end
                                        if JackpotLight:FindFirstChild(
                                            "SpotLight"
                                        ) then
                                            JackpotLight.SpotLight.Color = setTo
                                        end
                                    end

                                    for j, Child in
                                        ipairs(Model:GetChildren())
                                    do
                                        if
                                            Child.Material == Enum.Material.Neon
                                            and not Child.Name:find("Button")
                                        then
                                            Child.Color = setTo
                                            if Child:IsA("UnionOperation") then
                                                Child.UsePartColor = true
                                            end
                                        end
                                    end
                                    task.wait(0.5)
                                until not Machine.Spinning

                                setTo = Config.LightColors.Base
                                for j, JackpotLight in
                                        ipairs(module.JackpotLights)
                                    do
                                    JackpotLight.Color = setTo
                                    if JackpotLight:FindFirstChild(
                                        "PointLight"
                                    ) then
                                        JackpotLight.PointLight.Color = setTo
                                    end
                                    if JackpotLight:FindFirstChild(
                                        "SpotLight"
                                    ) then
                                        JackpotLight.SpotLight.Color = setTo
                                    end
                                end

                                for j, Child in ipairs(Model:GetChildren()) do
                                    if Child.Material == Enum.Material.Neon then
                                        Child.Color = setTo
                                    end
                                end
                            end)
                        elseif not wonJackpot then
                            Machine.WinSound:Play()
                        end
                        
                        for j = 1, 4 do
                            for k, Reel in ipairs(win.Reels) do
                                Reel.Visible = not Reel.Visible
                            end
                            task.wait(0.5)
                        end
                    end
                end

                if #jackpots > 0 then
                    for i, Jackpot in ipairs(jackpots) do
                        Machine.UpdateLine(
                            `{Util.EnglishNumber(i)} \z
                            {Machine.Config.Jackpot.Name} win\z
                            {i == 1 and "" or "s"} ({2 ^ i}x multiplier)`,
                            3
                        )
                        Machine.MultiplierSound:Play()
                        for j = 1, 4 do
                            Jackpot.Visible = not Jackpot.Visible
                            task.wait(0.5)
                        end
                    end
                end
            else
                Machine.Won += winnings
            end
            Coordinator.Game(winnings, Machine.Bet * Machine.Config.MinBet)
        else
            Coordinator.Game(0, Machine.Bet * Machine.Config.MinBet)
            Machine.Spinning = false
        end

        Machine.ResetButton.ClickDetector.MaxActivationDistance = 8
        Machine.SpinButton.ClickDetector.MaxActivationDistance = 8
        for i, Child in ipairs(Machine.BetButtons) do
            local Detector = Child:FindFirstChildWhichIsA("ClickDetector")
            Detector.MaxActivationDistance = 8
        end

        if typeof(Machine.User) == "Instance" then
            local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
                Machine.User:GetAttribute("ID")
            }`)
            local spent = PrivatePlayer:GetAttribute("CasinoLosses")
            if
                Machine.User:GetAttribute("Citizenship") == "North"
                and PrivatePlayer
                and not PrivatePlayer:GetAttribute("CasinoWelcomed")
                and spent >= Config.WelcomeCost
            then
                WelcomeBonus.Visible = true
                Machine.User:SetAttribute("FreeSpins", Config.WelcomeBonus)
                PrivatePlayer:SetAttribute("CasinoWelcomed", true)
            elseif winDrink then
                FreeDrink.Visible = true
                Machine.User:SetAttribute("LakiDrink", true)
            end
        end

        if not instant then
            Machine.UpdateLine("Game Over - Play Now", 1)
            if Machine.Message[2] == "GOOD LUCK" then
                Machine.UpdateLine("", 2)
            end
        end
    end

    Machine.Message = {}

    ---Update a given line of the display message
    ---@param message string The message to write
    ---@param line number The line to write to (1-3)
    Machine.UpdateLine = function(message: string, line: number)
        Machine.Message[line] = message
        MessageDisplay.Text = ""
        for i, writeLine in ipairs(Machine.Message) do
            MessageDisplay.Text ..= writeLine
                .. (i < #Machine.Message and "\n" or "")
        end
    end

    Machine.Prompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Tap card";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 4.5;
        Name = "SlotPrompt";
        Parent = Machine.CardReader;
        RequiresLineOfSight = false;
    }, {
        UsesCard = true;
    })

    Machine.Prompt.Triggered:Connect(function(Player: Player)
        if Machine.User then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "Slot machine already in use.";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                Slot machine already in use by {Machine.User}.`
            )
        end

        if Player:GetAttribute("UsingCard") then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "Currently using bank card in another machine.";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                {Player} is currently using their card in another machine.`
            )
        end

        if Player:GetAttribute("BankFrozen") then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "Your bank account is currently frozen by the MIA.";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                {Player} has a frozen bank account.`
            )
        end

        local balance = Player:GetAttribute("BankBalance") or 0
        local spins = Player:GetAttribute("FreeSpins") or 0
        if balance < Machine.Config.MinBet and spins < 1 then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "Insufficient funds.";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                {Player} does not have any money available!`
            )
        end

        local Humanoid = Player.Character
            and Player.Character:FindFirstChildWhichIsA("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "Character not alive.";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.Prompt.Triggered: \z
                {Player}'s Character is not alive!`
            )
        end

        Machine.Prompt.Enabled = false

        Machine.ResetButton.ClickDetector.MaxActivationDistance = 8
        Machine.SpinButton.ClickDetector.MaxActivationDistance = 8

        for i, Child in ipairs(Machine.BetButtons) do
            local Detector = Child:FindFirstChildWhichIsA("ClickDetector")
            Detector.MaxActivationDistance = 8
        end

        Machine.User = Player
        Machine.User:SetAttribute("UsingCard", true)

        Machine.Message = {"","",""}
        Machine.SetBet(1)
        Machine.Spent = 0
        Machine.Won = 0
        updateDisplay()

        Machine.UpdateBalance = Player:GetAttributeChangedSignal(
            "BankBalance"
        ):Connect(function()
            BalanceDisplay.Text = Util.ThousandsSeparate(
                Player:GetAttribute("BankBalance")
            )
        end)
        BalanceDisplay.Text = Util.ThousandsSeparate(
            Player:GetAttribute("BankBalance")
        )

        Machine.UpdateSpins = Player:GetAttributeChangedSignal(
            "FreeSpins"
        ):Connect(function()
            SpinDisplay.Text = Util.ThousandsSeparate(
                Player:GetAttribute("FreeSpins")
            )
        end)
        SpinDisplay.Text = Util.ThousandsSeparate(
            Player:GetAttribute("FreeSpins")
        )

        Machine.FirstActivity = os.time()
        Machine.LastActivity = os.time()
        while os.time() < Machine.LastActivity + 30 do
            task.wait(1)
        end
        
        if Machine.User then
            Machine.Reset()
        end
    end)

    return Machine
end

return module