--Handles all sanitation related tasks on the server
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local TankClient = script.WasherTank
local WasherClient = script.PowerWasher

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local InitializeTank = ReplicatedCommunication.InitializeTank
local InitializeWasher = ReplicatedCommunication.InitializeWasher
local SendNotification = ReplicatedCommunication.SendNotification
local ToggleWasher = ReplicatedCommunication.ToggleWasher

local JobConfig = require(ReplicatedConfig.Jobs.Sanitation)
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local DeathHandler = require(ServerScripts.Deaths)
local InventoryHandler
local JobHandler
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local PartStorage = ServerStorage.Parts
local PrivateStorage = ServerStorage.PrivateStorage

local MistEffect: ParticleEmitter = PartStorage.Mist
local ToolStorage = PartStorage.Tools

local initialized = {}
local GPM = 2.5

---Initialize a new power washer
---@param Player Player The Player initializing a power washer
---@param Washer Tool The power washer to initialize
InitializeWasher.OnServerEvent:Connect(function(Player: Player, Washer: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.InitializeWasher.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Washer:IsA("Tool") and (
        Washer.Parent == Inventory
        or (Player.Character and Washer.Parent == Player.Character))
    ) then
        return warn(
            `{script}.InitializeWasher.OnServerEvent: The item {Washer} is \z
            not in {Player}'s inventory!`
        )
    end

    if initialized[Washer] then
        return warn(
            `{script}.InitializeWasher.OnServerEvent: The item {Washer} has \z
            already been initialized!`
        )
    end

    if Washer:GetAttribute("FileName") ~= "PowerWasher" then
        return warn(
            `{script}.InitializeWasher.OnServerEvent: The item {Washer} is \z
            not a power washer!`
        )
    end

    initialized[Washer] = true

    local connectTank, findTank, TankSearch
    local Tube: RopeConstraint = Washer.Handle:WaitForChild("Tube")

    ---Connect a tank to the washer with a tube
    ---@param Tank Model The tank to connect to the washer
    connectTank = function(Tank: Model)
        Tube.Attachment1 = Tank.Handle.TankTubeAttachment
        Tube.Enabled = true

        Tank.AncestryChanged:Once(function()
            Tube.Attachment1 = nil
            findTank()
        end)
    end

    ---Find a tank to connect the washer to
    findTank = function()
        local User = Players:GetPlayerFromCharacter(Washer.Parent)
        if not User then
            return warn(
                `{script}.InitializeWasher.OnServerEvent: Washer {Washer} not \z
                equipped by a player!`
            )
        end

        local Tank
        for i, Child in ipairs(User.Character:GetChildren()) do
            if Util.StartsWith(Child.Name, "WasherTankDisplay") then
                Tank = Child
                break
            end
        end

        if not Tank then
            TankSearch = User.Character.ChildAdded:Connect(function(
                Child: Instance
            )
                if Util.StartsWith(Child.Name, "WasherTankDisplay") then
                    connectTank(Child)
                    TankSearch:Disconnect()
                end
            end)
        else connectTank(Tank)
        end
    end

    findTank()
    Washer.AncestryChanged:Connect(function()
        if TankSearch then
            TankSearch:Disconnect()
        end

        Tube.Attachment1 = nil
        findTank()
    end)

    local spraying
    Washer:GetAttributeChangedSignal("Spraying"):Connect(function()
        if Washer:GetAttribute("Spraying") and not spraying then
            local Barrel: MeshPart = Washer:FindFirstChild("Barrel")
            if not Barrel then
                return warn(
                    `{script}.Washer.GetAttributeChangedSignal("Spraying"): \z
                    No barrel found for {Player}'s power washer {Washer}!`
                )
            end

            local Nozzle: Attachment = Barrel:FindFirstChild("Nozzle")
            if not Nozzle then
                return warn(
                    `{script}.Washer.GetAttributeChangedSignal("Spraying"): \z
                    No nozzle found for {Player}'s power washer {Washer}!`
                )
            end

            local Spray: Beam = Barrel:FindFirstChild("Spray")
            if not Spray then
                return warn(
                    `{script}.Washer.GetAttributeChangedSignal("Spraying"): \z
                    No spray found for {Player}'s power washer {Washer}!`
                )
            end

            local Tank
            for i, Child in ipairs(Inventory:GetChildren()) do
                if Child:GetAttribute("FileName") == "WasherTank" then
                    Tank = Child
                end
            end

            if not Tank then
                return warn(
                    `{script}.Washer.GetAttributeChangedSignal("Spraying"): \z
                    No power washer tank found for {Player}!`
                )
            end

            local capacity = Tank:GetAttribute("Capacity") or 0
            if capacity <= 0 then
                return warn(
                    `{script}.Washer.GetAttributeChangedSignal("Spraying"): \z
                    Tank {Tank} is empty for {Player}'s power washer!`
                )
            end

            spraying = true

            local SprayParams = RaycastParams.new()
            SprayParams.FilterType = Enum.RaycastFilterType.Exclude
            SprayParams.FilterDescendantsInstances = {Player.Character}

            local EndPoint: Attachment = Util.CreateInstance("Attachment", {
                Name = "JetEnd";
                Parent = Nozzle.Parent;
            })

            local Mist: ParticleEmitter = MistEffect:Clone()
            Mist.Parent = EndPoint

            Spray.Attachment0 = Nozzle
            Spray.Attachment1 = EndPoint
            Spray.Enabled = true

            local SpraySound: Sound = Util.CreateInstance("Sound", {
                Looped = true;
                Parent = EndPoint;
                RollOffMaxDistance = 150;
                SoundId = Sounds.PowerWash;
            })
            SpraySound:Play()

            while Washer:GetAttribute("Spraying") do
                capacity = (Tank:GetAttribute("Capacity") or 0) - (GPM / 600)
                Tank:SetAttribute("Capacity", capacity)
                if capacity < 0 then
                    Tank:SetAttribute("Capacity", 0)
                end
                if capacity <= 0 then
                    Washer:SetAttribute("Spraying", false)
                    break
                end

                local SprayResults = workspace:Raycast(
                    Nozzle.WorldCFrame.Position,
                    Nozzle.WorldCFrame.LookVector.Unit * 5,
                    SprayParams
                )

                local endPos = SprayResults and SprayResults.Position
                    or Nozzle.WorldCFrame.Position
                    + Nozzle.WorldCFrame.LookVector.Unit * 5

                EndPoint.WorldCFrame = CFrame.new(endPos)

                if
                    SprayResults
                    and SprayResults.Instance
                    and SprayResults.Instance.Parent:FindFirstChildOfClass(
                        "Humanoid"
                    )
                then
                    local Humanoid =
                        SprayResults.Instance.Parent:FindFirstChildOfClass(
                            "Humanoid"
                        )

                    DeathHandler.TakeDamage(
                        Humanoid,
                        3,
                        `{Player:GetAttribute("FullName")}'s ({Player}'s) \z
                        {Washer:GetAttribute("DisplayName")
                        or Washer:GetAttribute("FileName")} \z
                        ({Washer})`,
                        Player.UserId
                    )
                end

                if
                    SprayResults
                    and SprayResults.Instance and
                    SprayResults.Instance:FindFirstChildOfClass("SurfaceGui")
                then
                    local surface: Enum.NormalId = Util.GetNormalId(
                        SprayResults.Instance, SprayResults.Normal
                    )
                    if not surface then
                        task.wait(0.1)
                        continue
                    end

                    local BloodSurface = SprayResults.Instance:FindFirstChild(
                        `BloodSplatter{surface}`
                    )
                    if not BloodSurface then
                        task.wait(0.1)
                        continue
                    end

                    local guiPos: UDim2 = Util.GuiPos(
                        SprayResults.Instance, SprayResults.Position, surface
                    )
                    if not guiPos then
                        task.wait(0.1)
                        continue
                    end

                    local BloodHit = {}
                    for i, Child in ipairs(BloodSurface:GetChildren()) do
                        local absoluteX = BloodSurface.AbsoluteSize.X
                            * guiPos.X.Scale
                        local absoluteY = BloodSurface.AbsoluteSize.Y
                            * guiPos.Y.Scale
                        if
                            (absoluteX >= Child.AbsolutePosition.X
                            and absoluteX <= Child.AbsolutePosition.X
                            + Child.AbsoluteSize.X)
                            and
                            (absoluteY >= Child.AbsolutePosition.Y
                            and absoluteY <= Child.AbsolutePosition.Y
                            + Child.AbsoluteSize.Y)
                        then
                            table.insert(BloodHit, Child)
                        end
                    end
                    
                    if #BloodHit == 0 then
                        task.wait(0.1)
                        continue
                    end

                    Mist:SetAttribute("Fading", false)
                    for i, BloodSplatter in ipairs(BloodHit) do
                        BloodSplatter.ImageTransparency += 0.1 / #BloodHit
                        if BloodSplatter.ImageTransparency >= 1 then
                            if
                                BloodSplatter:IsDescendantOf(workspace.Map)
                                and Player:GetAttribute("Occupation")
                                    == "Sanitation"
                                and Player:GetAttribute("Working")
                            then
                                local experience = 0
                                local PrivatePlayer =
                                    PrivateStorage:FindFirstChild(`Character{
                                        Player:GetAttribute("ID")
                                    }`)
                                if PrivatePlayer then
                                    experience = PrivatePlayer:GetAttribute(
                                        "BartenderExperience"
                                    ) or 0
                                end

                                print(
                                    `{script}.InitializeWasher.OnServerEvent: \z
                                    {Player} has cleaned up a splatter.`
                                )
                                local paid = JobHandler.Pay(Player,
                                    JobConfig.BasePay + (experience * 0.01))
                                SendNotification:FireClient(Player, {
                                    Title = "Pollution cleaned";
                                    Text = `₲{paid} have been added to your \z
                                        next paycheck.`;
                                    Duration = 10;
                                })
                            end
                            BloodSplatter:Destroy()
                        end
                    end
                end

                task.wait(0.1)
            end

            --To prevent a sudden cut off
            Mist.Enabled = false
            Spray.Enabled = false
            SpraySound:Stop()

            task.wait(Mist.Lifetime.Max)

            EndPoint:Destroy()
        elseif not Washer:GetAttribute("Spraying") then
            spraying = false
        end
    end)
end)

---Initialize a new power washer tank
---@param Player Player The Player initializing a power washer tank
---@param Tank Tool The power washer tank to initialize
InitializeTank.OnServerEvent:Connect(function(Player: Player, Tank: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.InitializeTank.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Tank:IsA("Tool") and (
        Tank.Parent == Inventory
        or (Player.Character and Tank.Parent == Player.Character))
    ) then
        return warn(
            `{script}.InitializeTank.OnServerEvent: The item {Tank} is \z
            not in {Player}'s inventory!`
        )
    end

    if initialized[Tank] then
        return warn(
            `{script}.InitializeTank.OnServerEvent: The item {Tank} has \z
            already been initialized!`
        )
    end

    if Tank:GetAttribute("FileName") ~= "WasherTank" then
        return warn(
            `{script}.InitializeTank.OnServerEvent: The item {Tank} is \z
            not a power washer tank!`
        )
    end

    local itemData = InventoryHandler.Items.Items[
        Tank:GetAttribute("FileName")
    ]
    if not itemData then
        return warn(
            `{script}.InitializeTank.OnServerEvent: Unknown tool \z
            {Tank:GetAttribute("FileName")}!`
        )
    end

    initialized[Tank] = true

    local function updateWeight()
        local capacity = Tank:GetAttribute("Capacity") or 0
        Tank:SetAttribute(
            "Weight", itemData.Weight + (capacity * 3.78)
        )
    end
    updateWeight()

    Tank:GetAttributeChangedSignal("Capacity"):Connect(updateWeight)
end)

---Toggle the status of a power washer
---@param Player Player The Player toggling the power washer
---@param status boolean The status of the power washer
ToggleWasher.OnServerEvent:Connect(function(Player: Player, status: boolean)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.ToggleWasher.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    local Washer = Player.Character
        and Player.Character:FindFirstChildOfClass("Tool")
    if not (Washer and Washer:GetAttribute("FileName") == "PowerWasher") then
        return warn(
            `{script}.ToggleWasher.OnServerEvent: No power washer found for \z
            player {Player}!`
        )
    end

    local Tank
    for i, Child in ipairs(Inventory:GetChildren()) do
        if Child:GetAttribute("FileName") == "WasherTank" then
            Tank = Child
        end
    end

    if not Tank then
        Washer:SetAttribute("Spraying", false)
        return warn(
            `{script}.ToggleWasher.OnServerEvent: No washer tank found for \z
            player {Player}!`
        )
    end

    if status then
        Washer:SetAttribute("Spraying", true)
        Washer.AncestryChanged:Once(function()
            Washer:SetAttribute("Spraying", false)
        end)
        Tank.AncestryChanged:Once(function()
            Washer:SetAttribute("Spraying", false)
        end)
    else Washer:SetAttribute("Spraying", false)
    end
end)

local module = {}

---Set up a locker for the sanitation equipment
---@param Handle Part The handle of the locker
---@return RBXScriptConnection
module.EquipmentLocker = function(Handle: BasePart)
    local LockerPrompt: ProximityPrompt = Util.CreateInstance(
        "ProximityPrompt",
        {
            ActionText = "Take equipment";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Parent = Handle:FindFirstChildWhichIsA("Attachment")
                or Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(0.5, 0, 0);
                    Name = "PromptAttachment";
                    Parent = Handle;
                });
            RequiresLineOfSight = true;
        }
    )

    return LockerPrompt.Triggered:Connect(function(Player: Player)
        local Character: Model = Player.Character
        if not Character then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        if not (
            Player:GetAttribute("Occupation") == "Sanitation"
            and Player:GetAttribute("Working")
        ) then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is not an on duty sanitation worker!`
            )
        end

        local checkedOut = Character:GetAttribute("SanitationCheckedOut") or 0
        if checkedOut > 0 then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} has not returned their sanitation equipment!`
            )
        end

        local Washer: Tool = InventoryHandler.Items.new(
            "PowerWasher",
            `{Player:GetAttribute("FullName")} ({Player}) from the sanitation \z
            services' equipment locker`
        )
        Washer:SetAttribute("SanitationEquipment", true)
        InventoryHandler.Add(Player, Washer, nil, true)
        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player}) checked out the \z
            {Washer:GetAttribute("DisplayName")} with the serial number \z
            {string.format("%012d", Washer:GetAttribute("SerialNo"))} and ID \z
            {Washer} from the sanitation services.`,
            "WeaponCheckout"
        )

        local Tank: Tool = InventoryHandler.Items.new(
            "WasherTank",
            `{Player:GetAttribute("FullName")} ({Player}) from the sanitation \z
            services' equipment locker`
        )
        Tank:SetAttribute("SanitationEquipment", true)
        InventoryHandler.Add(Player, Tank, nil, true)
        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player}) checked out the \z
            {Tank:GetAttribute("DisplayName")} with the serial number \z
            {string.format("%012d", Tank:GetAttribute("SerialNo"))} and ID \z
            {Tank} from the sanitation services.`,
            "WeaponCheckout"
        )

        Character:SetAttribute("SanitationCheckedOut", 2)
    end)
end

---Creates a local reference to the InventoryHandler module
---@param Handler table The InventoryHandler module
module.IHPass = function(Handler: table)
    InventoryHandler = Handler
end

---Creates a local reference to the JobHandler module
---@param Handler table The JobHandler module
module.JHPass = function(Handler: table)
    JobHandler = Handler
end

---Create a new power washer
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.NewWasher = function(attributes: table, itemData: table)
    attributes = attributes or {
        SerialNo = Util.Serialize("Washer");
    }

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    WasherClient:Clone().Parent = Tool

    return Tool
end

---Create a new power washer tank
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.NewTank = function(attributes: table, itemData: table)
    attributes = attributes or {
        SerialNo = Util.Serialize("WasherTank");
    }

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    TankClient:Clone().Parent = Tool

    return Tool
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

    if Player:GetAttribute("Citizenship") ~= "North" then
        return false, "NotCitizen", warn(
            `{script}.Requirements: {Player} is not a citizen of North Bloxell!`
        )
    end

    if Player:GetAttribute("Felon") then
        return false, "Felon", warn(
            `{script}.Requirements: {Player} is a felon!`
        )
    end

    return true
end

---Set up a locker for the return of sanitation equipment
---@param Handle Part The handle of the locker
---@return RBXScriptConnection
module.ReturnLocker = function(Handle: BasePart)
    local LockerPrompt: ProximityPrompt = Util.CreateInstance(
        "ProximityPrompt",
        {
            ActionText = "Return equipment";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Parent = Handle:FindFirstChildWhichIsA("Attachment")
                or Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(0.5, 0, 0);
                    Name = "PromptAttachment";
                    Parent = Handle;
                });
            RequiresLineOfSight = true;
        }
    )

    return LockerPrompt.Triggered:Connect(function(Player: Player)
        local Character: Model = Player.Character
        if not Character then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
        if not Inventory then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: No \z
                inventory found for {Player}!`
            )
        end

        local returned = 0
        local function returnEquipment(Item: Tool)
            if Item:GetAttribute("SanitationEquipment") then
                WebhookHandler.Post(
                    `{Player:GetAttribute("FullName")} ({Player}) returned \z
                    the {Item:GetAttribute("DisplayName")} with the serial \z
                    number \z
                    {string.format("%012d", Item:GetAttribute("SerialNo"))} \z
                    and ID {Item} to the sanitation services.`,
                    "WeaponCheckout"
                )

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

        for i, Item: Tool in ipairs(Inventory:GetChildren()) do
            returnEquipment(Item)
        end
        
        local Equipped: Tool = Character:FindFirstChildOfClass("Tool")
        if Equipped then
            returnEquipment(Equipped)
        end

        local checkedOut = Character:GetAttribute("SanitationCheckedOut") or 0
        if checkedOut < returned then
            checkedOut = returned
        end
        Character:SetAttribute("SanitationCheckedOut", checkedOut - returned)
    end)
end

---Set up a nozzle for the refill of washer tanks
---@param Lever BasePart The lever for the nozzle
---@return RBXScriptConnection
module.TankRefill = function(Lever: BasePart)
    local LeverPrompt: ProximityPrompt = Util.CreateInstance(
        "ProximityPrompt",
        {
            ActionText = "Refill tank";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Parent = Lever:FindFirstChildWhichIsA("Attachment")
                or Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(-0.25, 0, 0);
                    Name = "PromptAttachment";
                    Parent = Lever;
                });
            RequiresLineOfSight = true;
        }
    )

    return LeverPrompt.Triggered:Connect(function(Player: Player)
        local Character: Model = Player.Character
        if not Character then
            return warn(
                `{script}.{Lever:GetFullName()}.LeverPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Lever:GetFullName()}.LeverPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Lever:GetFullName()}.LeverPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        local Tank: Tool = Character:FindFirstChildOfClass("Tool")
        if not Tank then
            SendNotification:FireClient(Player, {
                Title = "Unable to fill tank";
                Text = "To use the refill station, you must have a power \z
                washer tank in hand.";
                Duration = 10;
            })
            return warn(
                `{script}.{Lever:GetFullName()}.LeverPrompt.Triggered: \z
                {Player} does not have a tool equipped!`
            )
        end

        if Tank:GetAttribute("FileName") ~= "WasherTank" then
            SendNotification:FireClient(Player, {
                Title = "Unable to fill tank";
                Text = "To use the refill station, you must have a power \z
                washer tank in hand.";
                Duration = 10;
            })
            return warn(
                `{script}.{Lever:GetFullName()}.LeverPrompt.Triggered: \z
                {Player} does not have a washer tank equipped!`
            )
        end

        Tank:SetAttribute("Capacity", 5)
        SendNotification:FireClient(Player, {
            Title = "Tank refilled";
            Text = "Your power washer tank has been successfully refilled.";
            Duration = 10;
        })
    end)
end

return module