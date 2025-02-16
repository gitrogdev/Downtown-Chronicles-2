--Handles mortars on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local MortarClient = script.MortarClient
local ToolClient = script.ToolClient

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local PlaceMortar = ReplicatedCommunication.PlaceMortar

local SoundIds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local ExplosionHandler = require(ServerScripts.Explosions)
local InventoryHandler
local Util = require(ServerScripts.Util)

local PartStorage = ServerStorage.Parts
local ToolStorage = PartStorage.Tools

local MortarConfigs = {}
for i, MortarConfig in ipairs(script.Mortars:GetChildren()) do
    MortarConfigs[MortarConfig.Name] = require(MortarConfig)
end

local module = {}

---Place a Player's mortar tool on the ground
---@param Player Player
PlaceMortar.OnServerEvent:Connect(function(Player: Player)
	local Character = Player.Character
	if not Character then
		return warn(
            `{script}.PlaceMortar.OnServerEvent: {Player}'s character is not \z
            loaded!`
        )
	end

	local Tool = Character:FindFirstChildOfClass("Tool")
	if not Tool then
		return warn(
            `{script}.PlaceMortar.OnServerEvent: {Player} does not have a \z
            tool equipped!`
        )
	end

    local config = MortarConfigs[Tool:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.PlaceMortar.OnServerEvent: {Player} does not have a \z
            mortar equipped! ({Tool:GetAttribute("FileName")})`
        )
    end

	local filterDescendants = {workspace.Map}

	local DropParams = RaycastParams.new()
	DropParams.FilterDescendantsInstances = filterDescendants
	DropParams.FilterType = Enum.RaycastFilterType.Include
	DropParams.RespectCanCollide = true
	DropParams.IgnoreWater = true

	local result = workspace:Raycast(
        Tool.Handle.Position, Vector3.new(0, -4, 0), DropParams
    )
	if not result then
		return warn(
            `{script}.PlaceMortar.OnServerEvent: No space found for \z
            {Player}'s mortar!`
        )
	end

	local LaunchMortar = config.PlaceModel:Clone()

    for attribute, value in pairs(Tool:GetAttributes()) do
        LaunchMortar:SetAttribute(attribute, value)
    end
    LaunchMortar.Name = Tool.Name

	LaunchMortar:SetPrimaryPartCFrame(CFrame.new(result.Position))
	LaunchMortar.Parent = workspace

    module.Setup(LaunchMortar, config)

	Tool:Destroy()
end)

---Creates a local reference to the InventoryHandler module
---@param InvHandler table The InventoryHandler module
module.IHPass = function(InvHandler: table)
    InventoryHandler = InvHandler
end

---Fires a mortar
---@param origin CFrame The origin point of the mortar round
---@param Mortar Model The mortar being fired
---@param Player Player The Player firing the mortal
---@param config table The configuration file for the mortar
module.Fire = function(
    origin: CFrame, Mortar: Model, Player: Player, config: table
)
    local Projectile = PartStorage:WaitForChild(config.Caliber.Name):Clone()
	Projectile.Position = origin.Position
	Projectile.Parent = workspace

	local CastingParams = RaycastParams.new()
	CastingParams.FilterDescendantsInstances = {
        Mortar, Player.Character, Projectile
    }
	CastingParams.FilterType = Enum.RaycastFilterType.Exclude
	CastingParams.IgnoreWater = true
	CastingParams.RespectCanCollide = true

	for i, Child in ipairs(Mortar.FirePart:GetChildren()) do
		if Child:IsA("PointLight") or Child:IsA("ParticleEmitter") then
			Child.Enabled = true
			task.spawn(function()
				task.wait(0.1)
				Child.Enabled = false
			end)
		end
	end

	local FireSound = Util.CreateInstance("Sound", {
        Parent = Mortar.FirePart;
        RollOffMaxDistance = 750;
        RollOffMinDistance = 20;
        SoundId = SoundIds.MortarFire;
        Volume = 1;
    })

    FireSound.Ended:Connect(function()
		FireSound:Destroy()
	end)

	FireSound:Play()

	local velocity = origin.LookVector * config.MuzzleVelocity
        + Vector3.new(
            math.random(-1000,1000) / 100,
            math.random(-1000,1000) / 100,
            math.random(-1000,1000) / 100
        )
	local gravity = 0
	while Projectile.Position.Y > workspace.FallenPartsDestroyHeight do
		local NextPosition = Vector3.new(
			Projectile.Position.X + velocity.X / 10,
			Projectile.Position.Y + velocity.Y / 10,
			Projectile.Position.Z + velocity.Z / 10
		)

		--Plays the whistling sound as the shell is on approach
		if NextPosition.Y + velocity.Y < 300 then
			local ApproachSound = Util.CreateInstance("Sound", {
                Parent = Projectile;
                RollOffMaxDistance = 500;
                RollOffMinDistance = 20;
                SoundId = SoundIds.MortarIncoming;
                Volume = 1;
            })

			ApproachSound:Play()
		end

		local Hit = workspace:Raycast(
            Projectile.Position, NextPosition - Projectile.Position,
            CastingParams
        )
		if Hit then
            local ApproachTween = TweenService:Create(
                Projectile,
                TweenInfo.new(
                    (Hit.Position - Projectile.Position).Magnitude
                    / (NextPosition - Projectile.Position).Magnitude
                ),
                {Position = Hit.Position}
            )

            ApproachTween.Completed:Connect(function()
                ExplosionHandler.new("Default", Hit.Position, {
                    ExplosionProperties = {
                        BlastRadius = 85;
                    };
                    MaxDamage = 20;
                    Source = `{Player:GetAttribute("FullName")}'s \z
                        ({Player}'s) mortar`;
                })

                Projectile:Destroy()
            end)

            ApproachTween:Play()

			break
		else
			gravity += 0.98
			velocity -= Vector3.new(0, gravity, 0)
			TweenService:Create(
                Projectile, TweenInfo.new(0.1), {Position = NextPosition}
            ):Play()
		end
		task.wait(0.1)
	end

	if Projectile then
		Projectile:Destroy()
	end
end

---Create a new firearm
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.new = function(attributes: table, itemData: table)
    local config = MortarConfigs[itemData.Name]
    if not config then
        return warn(`{script}.new: Unknown ammo box {itemData.Name}!`)
    end

    attributes = attributes or {
        Caliber = config.Caliber.Name;
    }
    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    ToolClient:Clone().Parent = Tool

    return Tool
end

---Create a new mortar round
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.NewRound = function(attributes: table, itemData: table)
    attributes = attributes or {}
    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    return Tool
end

---Set up a new placed mortar
---@param Mortar Model The model of the mortar
---@param config table The configuration file for the mortar
module.Setup = function(Mortar: Model, config: table)
    local Base = Mortar:FindFirstChild("Base")
    if not Base then
        return warn(`{script}.Setup: No base found for mortar {Mortar}!`)
    end

    local AngleMotor = Base:FindFirstChild("AngleMotor")
    if not AngleMotor then
        return warn(`{script}.Setup: No angle motor found for mortar {Mortar}!`)
    end

    local BasePivot = Mortar:FindFirstChild("BasePivot")
    if not BasePivot then
        return warn(`{script}.Setup: No base pivot found for mortar {Mortar}!`)
    end

    local BaseMotor = BasePivot:FindFirstChild("BaseMotor")
    if not BaseMotor then
        return warn(`{script}.Setup: No base motor found for mortar {Mortar}!`)
    end

    local FirePart = Mortar:FindFirstChild("FirePart")
    if not FirePart then
        return warn(`{script}.Setup: No fire part found for mortar {Mortar}!`)
    end

    local LegAttach = Mortar:FindFirstChild("LegAttach")
    if not LegAttach then
        return warn(
            `{script}.Setup: No leg attachment found for mortar {Mortar}!`
        )
    end

    local LegServo = LegAttach:FindFirstChild("LegServo")
    if not LegServo then
        return warn(`{script}.Setup: No leg servo found for mortar {Mortar}!`)
    end

    local Seat = Mortar:FindFirstChildOfClass("Seat")
    if not Seat then
        return warn(`{script}.Setup: No seat found for mortar {Mortar}!`)
    end

    local Tube = Mortar:FindFirstChild("Tube")
    if not Tube then
        return warn(`{script}.Setup: No tube found for mortar {Mortar}!`)
    end

    local AdjustMortar = Util.CreateInstance("RemoteEvent", {
        Name = "AdjustMortar";
        Parent = Mortar;
    })

    local FireMortar = Util.CreateInstance("RemoteEvent", {
        Name = "FireMortar";
        Parent = Mortar;
    })

    local LoadSound = Util.CreateInstance("Sound", {
        Name = "LoadSound";
        Parent = Tube;
        RollOffMaxDistance = 100;
        SoundId = SoundIds.LoadMortar;
    })

    local PickupPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Pick up";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.P;
        MaxActivationDistance = 8;
        Parent = Tube:FindFirstChild("PickupAttachment")
            or Util.CreateInstance("Attachment", {
                Name = "PickupAttachment";
                Parent = Tube;
                Position = Vector3.new(0, 0.3, 0);
            });
        RequiresLineOfSight = true;
    })

    local cooldown = os.time() + 1.2
    local User

    ---Adjust the mortar's angle
    ---@param Player Player The Player adjusting the angle
    ---@param Input InputObject The key being pressed
    ---@param active boolean Whether the key is being pressed
    AdjustMortar.OnServerEvent:Connect(function(
        Player: Player, Input: InputObject, active: boolean
    )
        if not User then
            return warn(
                `{script}.{Mortar}.AdjustMortar.OnServerEvent: Mortar is not \z
                in use!`
            )
        end
        
        if User.Parent ~= Player.Character then
            return warn(
                `{script}.{Mortar}.AdjustMortar.OnServerEvent: {Player} tried \z
                to use {User.Parent}'s mortar!`
            )
        end
        
        if active then
            if Input == "Enum.KeyCode.W" or Input == "Enum.KeyCode.S" then
                AngleMotor.AngularVelocity = 0.5
                    * ((Input == "Enum.KeyCode.W" and 1) or -1)
            end
            
            if Input == "Enum.KeyCode.Q" or Input == "Enum.KeyCode.E" then
                BaseMotor.AngularVelocity = 0.5
                    * ((Input == "Enum.KeyCode.E" and 1) or -1)
            end
        else
            if Input == "Enum.KeyCode.W" or Input == "Enum.KeyCode.S" then
                AngleMotor.AngularVelocity = 0
            end
            
            if Input == "Enum.KeyCode.Q" or Input == "Enum.KeyCode.E" then
                BaseMotor.AngularVelocity = 0
            end
        end
    end)

    AngleMotor:GetPropertyChangedSignal("AngularVelocity"):Connect(function()
        LegServo.TargetAngle = AngleMotor.CurrentAngle * -4
    end)

    ---Fire the mortar
    ---@param Player Player The Player firing the mortar
    FireMortar.OnServerEvent:Connect(function(Player: Player)
        if not User then
            return warn(
                `{script}.{Mortar}.FireMortar.OnServerEvent: Mortar is not in \z
                use!`
            )
        end
    
        if User.Parent ~= Player.Character then
            return warn(
                `{script}.{Mortar}.FireMortar.OnServerEvent: {Player} tried \z
                to use {User.Parent}'s mortar!`
            )
        end
        
        if os.time() < cooldown then
            return warn(
                `{script}.{Mortar}.FireMortar.OnServerEvent: Mortar is on \z
                cooldown!`
            )
        end

        local Round = Player.Character:FindFirstChildOfClass("Tool")
        if not (
                Round and Round:GetAttribute("FileName") == config.Caliber.Name
        ) then
            return warn(
                `{script}.{Mortar}.FireMortar.OnServerEvent: {Player} does \z
                not have a mortar round!`
            )
        end
        
        cooldown = os.time() + 2.4
        
        Round:Destroy()
        PickupPrompt.MaxActivationDistance = 0
        LoadSound:Play()
        task.wait(1.2)
        module.Fire(
            FirePart.CFrame, Mortar, Player, config
        )
        PickupPrompt.MaxActivationDistance = 8
    end)

    PickupPrompt.Triggered:Connect(function(Player: Player)
        if Seat.Occupant then
            return warn(
                `{script}.{Mortar}.PickupPrompt.Triggered: Mortar {Mortar} is \z
                currently in use and can not be picked up by {Player}!`
            )
        end

        if
            InventoryHandler.Equip(Player, InventoryHandler.Items.new(
                Mortar:GetAttribute("FileName"),
                `{Player} picking up mortar`,
                Mortar:GetAttributes(),
                Mortar.Name
            ))
        then
            Mortar:Destroy()
        end
    end)

    Seat:GetPropertyChangedSignal("Occupant"):Connect(function()        
        local Occupant = Seat.Occupant
        if Occupant then
            MortarClient:Clone().Parent = Occupant.Parent
        else
            if User.Parent:FindFirstChild("MortarClient") then
                User.Parent.MortarClient:Destroy()
            end
        end
        User = Occupant

        PickupPrompt.Enabled = not Occupant
    end)
end

return module