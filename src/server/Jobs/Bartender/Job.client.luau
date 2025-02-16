--Handles the bartender job on the client
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration
local Util = require(ReplicatedScripts.Util)

local DrinkOrder = ReplicatedCommunication.DrinkOrder
local ListenOrders = ReplicatedCommunication.ListenOrders

local JobConfig = require(ReplicatedConfig.Jobs.Bartender)
local Sounds = require(ReplicatedConfig.Sounds)

local PartStorage = ReplicatedStorage.Parts
local UIStorage = ReplicatedStorage.UserInterface
local SlipTemplate = UIStorage.DrinkSlip

local Map = workspace:WaitForChild("Map")
local Bar = Map:WaitForChild("RedStag")
local Glasses = Bar:WaitForChild("Glasses")
local Taps = Bar:WaitForChild("Tap")

local currentOrder
local glassPrompts = {}
local holdingGlass
local inUse = {}
local served
local tapPrompts = {}

local GlassPrompts = Glasses:FindFirstChild("Prompts")
if GlassPrompts then
    --Cleans up prompts from the last job if they were left somehow
    GlassPrompts:Destroy()
end

GlassPrompts = Util.CreateInstance("Folder", {
    Name = "Prompts";
    Parent = Glasses;
})

for i, Child in ipairs(Glasses:GetChildren()) do
    local glassType = Child:GetAttribute("GlassType")
    if glassType then
        local avgPosition = Vector3.new()
        local count = 0
        for j, Glass in ipairs(Child:GetChildren()) do
            if Glass:IsA("BasePart") then
                avgPosition += Glass.Position
                count += 1
            end
        end
        avgPosition /= count

        local GlassPrompt = Util.CreateInstance("ProximityPrompt", {
            ActionText = `{glassType} glass`;
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Name = "GlassPrompt";
            Parent = Util.CreateInstance("Part", {
                Anchored = true;
                CanCollide = false;
                CanQuery = false;
                Massless = true;
                Parent = GlassPrompts;
                Position = avgPosition;
                Size = Vector3.new(1, 1, 1);
                Transparency = 1;
            });
            RequiresLineOfSight = false;
        })

        GlassPrompt.Triggered:Connect(function()
            if GlassPrompt.ActionText == "Put back" then
                GlassPrompt.ActionText = `{glassType} glass`
                holdingGlass = nil
                for promptType, Prompt in pairs(glassPrompts) do
                    Prompt.Enabled = true
                end

                for j, Prompt in ipairs(tapPrompts) do
                    Prompt.Enabled = false
                end
            else
                GlassPrompt.ActionText = "Put back"
                holdingGlass = glassType
                for promptType, Prompt in pairs(glassPrompts) do
                    Prompt.Enabled = promptType == glassType
                end

                for j, Prompt in ipairs(tapPrompts) do
                    if not inUse[Prompt] then
                        Prompt.Enabled = true
                    end
                end
            end
        end)

        glassPrompts[glassType] = GlassPrompt
    end
end

for tapType, config in pairs(JobConfig.Taps) do
    local Tap = Taps:FindFirstChild(`{tapType}Tap`)
    if not Tap then
        warn(`{script.Name}: {tapType}Tap not found!`)
        continue
    end

    local TapPart = Tap.Tap
    if not TapPart then
        warn(`{script.Name}: {Tap}.Tap not found!`)
        continue
    end

    local TapPrompt = Tap:FindFirstChildOfClass("ProximityPrompt")
    if TapPrompt then
        --Cleans up prompts from the last job if they were left somehow
        TapPrompt:Destroy()
    end

    TapPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = `Pour {config.Name}`;
        ClickablePrompt = true;
        Enabled = false;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 8;
        Name = "TapPrompt";
        Parent = TapPart;
        RequiresLineOfSight = false;
    })

    TapPrompt.Triggered:Connect(function()
        for i, Prompt in ipairs(tapPrompts) do
            Prompt.Enabled = false
        end

        for promptType, Prompt in pairs(glassPrompts) do
            Prompt.Enabled = true
        end
        inUse[TapPrompt] = true
        local usingGlass = holdingGlass
        holdingGlass = nil

        glassPrompts[usingGlass].ActionText = `{usingGlass} glass`

        local Glass = PartStorage:FindFirstChild(`{usingGlass}Glass`)
        if not Glass then
            return warn(
                `{script}.{tapType}Tap.TapPrompt.Triggered: \z
                {usingGlass}Glass not found!`
            )
        end
        Glass = Glass:Clone()

        Glass:SetPrimaryPartCFrame(CFrame.new(
            TapPart.Position - Vector3.new(
                0,
                JobConfig.Differences[usingGlass],
                0
            )
        ))
        Glass.Parent = GlassPrompts

        local PourSound = Util.CreateInstance("Sound", {
            Parent = Glass.Glass;
            SoundId = Sounds.PourSound;
            Volume = 0.5;
        })

        PourSound.Ended:Connect(function()
            PourSound:Destroy()
        end)

        PourSound:Play()
        task.wait(JobConfig.FillTime)

        local FillPart = Glass:WaitForChild("Fill")
        FillPart.Color = config.Color
        FillPart.Transparency = 0

        local ServePrompt = Util.CreateInstance("ProximityPrompt", {
            ActionText = "Serve drink";
            ClickablePrompt = true;
            Enabled = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Name = "ServePrompt";
            Parent = FillPart;
            RequiresLineOfSight = false;
        })

        ServePrompt.Triggered:Once(function()
            inUse[TapPrompt] = false
            Glass:Destroy()
            if holdingGlass then
                TapPrompt.Enabled = true
            end

            table.insert(served, {
                Drink = tapType;
                Size = usingGlass;
            })
            if #served >= #currentOrder.Order then
                TweenService:Create(currentOrder.Slip.Background,
                    TweenInfo.new(1),
                    {
                        Position = UDim2.fromScale(
                            1,
                            currentOrder.Slip.Background.Position.Y.Scale
                        )
                    }
                ):Play()
                
                DrinkOrder:FireServer(served)
            end
        end)
    end)
    
    inUse[TapPrompt] = false
    table.insert(tapPrompts, TapPrompt)
end

DrinkOrder.OnClientEvent:Connect(function(order: table)
    print(`{script}.DrinkOrder.OnClientEvent: Got order of {#order} drinks.`)

    local DrinkSlip = SlipTemplate:Clone()
    local SlipBackground = DrinkSlip:WaitForChild("Background")
    local SlipInfo = SlipBackground:WaitForChild("NameDate")
    local SlipOrders = SlipBackground:WaitForChild("Orders")
    local SlipTimestamp = SlipBackground:WaitForChild("Timestamp")

    local timestamp = os.time() - 36000
    SlipTimestamp.Text = Lighting.TimeOfDay
    SlipInfo.Text = `{Player:GetAttribute("FullName"):upper()}\n\z
    {os.date("%A", timestamp):upper()} {os.date("%d", timestamp)} \z
    {os.date("%B", timestamp):upper()} {os.date("%Y", timestamp)}`

    for i, drink in ipairs(order) do
        SlipOrders.Text ..= `{drink.Drink:upper()} {drink.Size:upper()} \z
            {JobConfig.Sizes[drink.Size]}L{i == JobConfig.MaxOrder and ""
            or "\n"}`
    end

    for i = 1, JobConfig.MaxOrder - #order do
        SlipOrders.Text ..= "\n"
    end

    DrinkSlip.Parent = Player.PlayerGui
    TweenService:Create(SlipBackground, TweenInfo.new(3), {
        Position = UDim2.fromScale(
            SlipBackground.Position.X.Scale,
            1 - SlipBackground.Size.Y.Scale
        );
    }):Play()
    currentOrder = {
        Order = order;
        Slip = DrinkSlip;
    }
    served = {}
end)

ListenOrders:FireServer()
print(`{script}: Listening for drink orders.`)

Player:GetAttributeChangedSignal("Working"):Once(function()
    if currentOrder then
        TweenService:Create(currentOrder.Slip.Background, TweenInfo.new(1), {
            Position = UDim2.fromScale(
                1,
                currentOrder.Slip.Background.Position.Y.Scale
            )
        }):Play()
    end

    GlassPrompts:Destroy()
    script:Destroy()
end)