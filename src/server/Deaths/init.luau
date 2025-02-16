--This script handles all deaths server-side
local BadgeService = game:GetService("BadgeService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local DeathConfig = require(script.Config)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local LastDeath = ReplicatedCommunication.LastDeath

local SoundIds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local CharacterHandler
local CollisionHandler = require(ServerScripts.Collisions)
local InventoryHandler
local ServerConfig = ServerScripts.Configuration
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local BadgeIds = require(ServerConfig.Badges)

local PartStorage = ServerStorage.Parts
local PrivateStorage = ServerStorage:FindFirstChild("PrivateStorage") or
    Util.CreateInstance("Folder", {
        Name = "PrivateStorage";
        Parent = ServerStorage;
    })

local BleedingParticles = PartStorage.Bleeding
local FlyParticles = PartStorage.Flies

local CORPSE_ATTACHMENTS = {
    {"Right Arm", "RightGripAttachment"};
    {"Right Arm", "RightShoulderAttachment"};

    {"Left Arm", "LeftGripAttachment"};
    {"Left Arm", "LeftShoulderAttachment"};

    {"Right Leg", "RightFootAttachment"};

    {"Left Leg", "LeftFootAttachment"};

    {"Torso", "WaistCenterAttachment"};
    {"Torso", "NeckAttachment"};

    {"HumanoidRootPart", "RootJointAttachment"};
    {"HumanoidRootPart", "RootAttachment"};
}

local lastDeaths = {}

---Get the data for a Player's last death
---@param Player Player The Player requesting the death data
---@return any
LastDeath.OnServerInvoke = function(Player: Player)
    local lastDeath = lastDeaths[Player:GetAttribute("ID")]
    if not lastDeath then
        return warn(
            `{script}.LastDeath.OnServerInvoke: No death found for \z
            {Player:GetAttribute("FullName")} ({Player}) (ID: \z
            {Player:GetAttribute("ID")})`
        )
    end

    local endNLR = lastDeath.At + (DeathConfig.NLRTime * 60)
    if endNLR < os.time() then
        return warn(
            `{script}.LastDeath.OnServerInvoke: NLR cooldown of \z
            {DeathConfig.NLRTime} has passed since {Player}'s last death!`
        )
    end

    return {
        Until = endNLR;
        Position = lastDeath.Position;
    }
end

local module = {}

---Start bleeding from a part
---@param Humanoid Humanoid The Humanoid to deal damage to
---@param BleedFrom BasePart The part to make blood particles from
---@param source string The source of the bleeding
---@param rate number The rate for the bleeding to start at
---@param size NumberSequence The size of the blood particles
---@param time number The time for the player to bleed for
---@param Source Player The Player who caused the bleeding
module.Bleed = function(
    Humanoid: Humanoid,
    BleedFrom: BasePart,
    source: string,
    rate: number,
    size: NumberSequence,
    time: number,
    Source: Player
)
    local Blood = BleedingParticles:Clone()
    Blood.Rate = rate
    Blood.Size = size
    Blood.Parent = BleedFrom

    TweenService:Create(Blood, TweenInfo.new(time), {
        Rate = 0;
    }):Play()

    task.spawn(function()
        while Blood.Rate > 0 and BleedFrom.Parent do
            module.Splatter(Humanoid, 1, BleedFrom.Position)
            module.TakeDamage(
                Humanoid, size.Keypoints[1].Value * (Blood.Rate / 2),
                `Bleeding from {source}`, Source and Source.UserId
            )
            task.wait(1)
        end
    end)
end

---Start burning a Humanoid
---@param Humanoid Humanoid The Humanoid to burn
---@param Fire Fire The fire burning the Humanoid
---@param source string The source of the burning
---@param Source Player The Player who caused the burning
module.Burn = function(
    Humanoid: Humanoid, Fire: Fire, source: string, Source: Player
)
    task.spawn(function()
        while Fire.Enabled and Fire:IsDescendantOf(Humanoid.Parent) do
            module.TakeDamage(
                Humanoid,
                Fire.Heat,
                `Burning from {source}`,
                Source and Source.UserId
            )
            task.wait(1)
        end
    end)
end

---Creates a local reference to the CharacterHandler module
---@param CharHandler table The CharacterHandle module
module.CHPass = function(CharHandler: table)
    CharacterHandler = CharHandler
end

---Creates a local reference to the InventoryHandler module
---@param InvHandler table The InventoryHandler module
module.IHPass = function(InvHandler: table)
    InventoryHandler = InvHandler
end

module.CorpseHandle = function(attributes: table)
    local Corpse = workspace:FindFirstChild(attributes.Corpse)
    if not Corpse then
        return warn(
            `{script}.CorpseHandle: Corpse with GUID {attributes.Corpse} not \z
            found in workspace!`
        )
    end

    ---Finds the optimal attachment for the rope to "grab"
    local function findAttachment()
        for i, attachment in ipairs(CORPSE_ATTACHMENTS) do
            local Attachment = Corpse:FindFirstChild(attachment[1])
                and Corpse[attachment[1]]:FindFirstChild(attachment[2])
            if Attachment then
                return Attachment
            end
        end
    end

    local Tool = Util.CreateInstance("Tool", {}, attributes)
    local Handle = Util.CreateInstance("Part", {
        CanCollide = false;
        CanQuery = false;
        Massless = true;
        Name = "Handle";
        Parent = Tool;
        Size = Vector3.new(0.5, 0.5, 0.5);
        Transparency = 1;
    })
    local Attachment = Util.CreateInstance("Attachment", {
        Parent = Handle
    })
    Util.CreateInstance("RopeConstraint", {
        Attachment0 = Attachment;
        Attachment1 = findAttachment();
        Length = 3;
        Parent = Handle;
        Visible = false;
    })

    Tool.AncestryChanged:Connect(function()
        if not Tool.Parent then
            Corpse.Humanoid.RootPart.DragPrompt.Enabled = true

            for i, Child in ipairs(Corpse:GetDescendants()) do
                if Child:IsA("BasePart") then
                    Child.Massless = false
                    Child:SetNetworkOwnershipAuto()
                    CollisionHandler.Group(Child, "Default")
                end
            end
        end
    end)

    return Tool
end

---Handles the death of a Player
---@param Player Player The Player that died
module.Kill = function(Player: Player)
    if not DeathConfig.DutyJobs[Player:GetAttribute("Occupation")] then
        Player:SetAttribute("Working", false)
    end
    Player:SetAttribute("Dead", true)

    InventoryHandler.DropAll(Player, true, true)

    local Humanoid = Player.Character
        and Player.Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        task.spawn(function()
            WebhookHandler.Post(
                `{Player:GetAttribute("FullName")} ({Player}) has died! Cause \z
                of death: {Humanoid:GetAttribute("LastDamage") or "Unknown"}`,
                "DeathLog"
            )
            
            local killer = Humanoid:GetAttribute("LastDamager")
            if (not killer) or killer == Player.UserId then
                return
            end

            local Killer = Players:GetPlayerByUserId(killer)
            if not Killer then
                return
            end

            local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
                Killer:GetAttribute("ID")
            }`)
            if
                PrivatePlayer
                and not PrivatePlayer:GetAttribute("BadgeMurderer")
            then
                print(
                    `{script}.Kill: Awarding the Murderer badge to {Killer} \z
                    for killing {Player}!`
                )
                BadgeService:AwardBadge(killer, BadgeIds.Murderer)
                if not RunService:IsStudio() then
                    PrivatePlayer:SetAttribute("BadgeMurderer", true)
                end
            end
        end)
    end

    local RootPart = Humanoid.RootPart
    if RootPart then
        lastDeaths[Player:GetAttribute("ID")] = {
            At = os.time();
            Position = RootPart.Position;
        }
    else warn(`{script}.Kill: No root part found for {Player}!`)
    end

    local Torso = Player.Character:FindFirstChild("Torso")
    if Torso then
        local LeftShoulder = Torso:FindFirstChild("Left Shoulder")
        local Neck = Torso:FindFirstChild("Neck")
        local RightShoulder = Torso:FindFirstChild("Right Shoulder")

        if LeftShoulder then
            LeftShoulder.C1 = Util.DefaultCFrames.LeftShoulderC1
        end

        if Neck then
            Neck.C0 = Util.DefaultCFrames.NeckC0
        end

        if RightShoulder then
            RightShoulder.C1 = Util.DefaultCFrames.RightShoulderC1
        end
    end

    local Nametag = Player.Character and Player.Character:FindFirstChild("Head")
        and Player.Character.Head:FindFirstChild("Nametag")
    if Nametag then
        Nametag.Display:SetAttribute("Dead", true)
    else
        warn(`{script}.Kill: No nametag found for {Player}`)
    end

    Player:SetAttribute("Masked", nil)
    module.Ragdoll(Player.Character, Player:GetAttribute("FullName"))

    for i = 0, DeathConfig.RespawnTime - 1 do
        if Player.Parent ~= Players then
            return
        end

        Player:SetAttribute("ToRespawn", DeathConfig.RespawnTime - i)
        task.wait(1)
    end
    Player:SetAttribute("ToRespawn", nil)

    if Player.Parent == Players then
        if Player.Character:GetAttribute("Deicide") then
            local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
                Player:GetAttribute("ID")
            }`)
            if not PrivatePlayer:GetAttribute("BadgeDeicide") then
                BadgeService:AwardBadge(Player.UserId, BadgeIds.Deicide)
                if not RunService:IsStudio() then
                    PrivatePlayer:SetAttribute("BadgeDeicide", true)
                end
            end
        else
            InventoryHandler.Load(Player)
            CharacterHandler.SelectSpawn(Player)
            Player:SetAttribute("Dead", false)
        end
    end
end

---Creates a ragdolled corpse of a character
---@param Character Model The character model to ragdoll
---@return Model
module.Ragdoll = function(Character: Model, name: string)
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    if not Humanoid then
        return warn(`{script}.Ragdoll: No Humanoid found for {Character}`)
    end

    local Corpse = Util.CreateInstance("Model", {
        Name = HttpService:GenerateGUID(false);
        Parent = workspace;
    })
	
    Humanoid = Humanoid:Clone()
    Humanoid.RequiresNeck = false
    Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    Humanoid.PlatformStand = true

	for i, Child in ipairs(Character:GetDescendants()) do
		if Child:IsA("Motor6D") then
            local Attachment0 = Util.CreateInstance("Attachment", {
                CFrame = Child.C0;
                Name = `{Child}Attachment`;
                Parent = Child.Part0;
            })
            local Attachment1 = Util.CreateInstance("Attachment", {
                CFrame = Child.C1;
                Name = `{Child}Attachment`;
                Parent = Child.Part1;
            })
            Util.CreateInstance("BallSocketConstraint", {
                Attachment0 = Attachment0;
                Attachment1 = Attachment1;
                LimitsEnabled = true;
                Name = `{Child}Socket`;
                Parent = Child.Parent;
                TwistLimitsEnabled = true;
            })
		elseif Child:IsA("BasePart") then
			Child.Velocity = Vector3.new(0,0,0)
		end

		if DeathConfig.RemoveClasses[Child.ClassName] then
			Child:Destroy()
		end
	end
	
	for i, Child in ipairs(Character:GetChildren()) do
		if Child:IsA("BasePart")
            and (Child.Name:find("Arm") or Child.Name:find("Leg"))
        then
            local Bone = Util.CreateInstance("Part", {
                Massless = true;
                Name = `{Child}Bone`;
                Parent = Child;
                Size = Vector3.new(
                    Child.Size.X / 2,
                    Child.Size.Y,
                    Child.Size.Z / 2
                );
                --The Ball type ensures the legs "crumple"
                Shape = (Child.Name:find("Leg") and Enum.PartType.Ball)
                    or Enum.PartType.Block;
                Transparency = 1;
            })
            Util.CreateInstance("ManualWeld", {
                C0 = Child.CFrame:Inverse() * Child.CFrame;
                Name = `{Child}BoneWeld`;
                Parent = Bone;
                Part0 = Child;
                Part1 = Bone;
            })
		end

        if not Child:IsA("Humanoid") then
            Child.Parent = Corpse
        end
	end
    Humanoid.Parent = Corpse
    
    local DragPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Drag";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.P;
        MaxActivationDistance = 8;
        Name = "DragPrompt";
        Parent = Humanoid.RootPart;
        RequiresLineOfSight = false;
    })

    DragPrompt.Triggered:Connect(function(Player: Player)
        local ClickChar = Player.Character
        if not ClickChar then
            return warn(
                `{script}.Ragdoll.DragPrompt.Triggered: \z
                No Character found for {Player}!`
            )
        end

        local ClickHumanoid = ClickChar:FindFirstChildOfClass("Humanoid")
        if not ClickHumanoid then
            return warn(
                `{script}.Ragdoll.DragPrompt.Triggered: \z
                No Humanoid found for {Player}!`
            )
        end

        if ClickHumanoid.Health <= 0 then
            return warn(
                `{script}.Ragdoll.DragPrompt.Triggered: {Player} is dead!`
            )
        end

        local success = InventoryHandler.Equip(Player,
            InventoryHandler.Items.new("Corpse", `{Corpse.Name}'s DragPrompt`, {
                Corpse = Corpse.Name;
                DisplayName = `{name}'s Corpse`;
            })
        )
        if success then
            DragPrompt.Enabled = false
            for i, Child in ipairs(Corpse:GetDescendants()) do
                if Child:IsA("BasePart") then
                    Child.Massless = true
                    Child:SetNetworkOwner(Player)
                    CollisionHandler.Group(Child, "Dragging")
                end
            end

            for i, Child in ipairs(Player.Character:GetDescendants()) do
                if Child:IsA("BasePart") then
                    CollisionHandler.Group(Child, "Draggers")
                end
            end

            local Tool = Player.Character:FindFirstChildWhichIsA("Tool")
            Tool.AncestryChanged:Connect(function()
                local NewTool = Player.Character:FindFirstChildWhichIsA("Tool")
                if NewTool and NewTool:GetAttribute("FileName") == "Corpse" then
                    return
                end

                for i, Child in ipairs(Player.Character:GetDescendants()) do
                    if Child:IsA("BasePart") then
                        CollisionHandler.Group(Child, "Players")
                    end
                end
            end)
        end
    end)

    for i, Child in ipairs(Corpse:GetDescendants()) do
        if Child:IsA("TouchTransmitter") then
            Child:Destroy()
        end
    end

    return Corpse
end

---Splatter blood on the map
---@param Humanoid Humanoid The Humanoid the blood is coming from
---@param damage number The amount of damage done to the Humanoid
---@param at Vector3 The position the damage was dealt at
module.Splatter = function(Humanoid: Humanoid, damage: number, at: Vector3)
    if Humanoid:GetAttribute("NoDamage") then
        return warn(
            `{script}.Splatter: The Humanoid {Humanoid:GetFullName()} is \z
            marked with the "NoDamage" attribute!`
        )
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {Util.GetBricks()}
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.IgnoreWater = true

    local sprayDistance: number = math.ceil(damage / 4)
    if sprayDistance > 30 then
        sprayDistance = 30
    end

	for i = 1, math.ceil(damage / 10) do
		local direction = Vector3.new(
            math.random(-50,50),
            math.random(-50,50),
            math.random(-50,50)
        ).Unit * sprayDistance
        local result = workspace:Raycast(at, direction, rayParams)
        if not result then
            result = workspace:Raycast(at + direction, Vector3.new(
                0, -math.abs(
                    (at + direction).Y - workspace.FallenPartsDestroyHeight
                ), 0
            ), rayParams)
        end

        if result then
            local normalId = Util.GetNormalId(result.Instance, result.Normal)
            if not normalId then
                continue
            end
            
            local guiPos = Util.GuiPos(
                result.Instance, result.Position, normalId
            )
            if not guiPos then
                continue
            end

            local Surface = result.Instance:FindFirstChild(
                `BloodSplatter{normalId}`
            ) or Util.CreateInstance("SurfaceGui", {
                ClipsDescendants = true;
                Face = normalId;
                Name = `BloodSplatter{normalId}`;
                Parent = result.Instance;
                PixelsPerStud = 100;
                SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud;
            }, {
                OnSurface = true;
            })

            local xSize = math.random(damage * 5, damage * 10)
            if xSize > 750 then
                xSize = math.random(500, 750)
            end
            if xSize < 20 then
                xSize = math.random(20,50)
            end
            local imageSize = UDim2.fromOffset(
                xSize, xSize * math.random(80, 120) / 100
            )

            local SplatterImage = Util.CreateInstance("ImageLabel", {
                BackgroundTransparency = 1;
                Image = Util.RandomFrom(DeathConfig.BloodDecals);
                Parent = Surface;
                Position = guiPos - UDim2.fromOffset(
                    imageSize.X.Offset / 2, imageSize.Y.Offset / 2
                );
                Size = imageSize;
                ZIndex = #Surface:GetChildren();
            }, {
                Washable = true;
            })

            local FlyPart = Util.CreateInstance("Part", {
                Massless = true;
                CanCollide = false;
                CanQuery = false;
                Parent = result.Instance;
                Position = result.Position;
                Size = Vector3.new(1, 1, 1);
                Transparency = 1;
            }, {
                OnSurface = true;
            })

            Util.WeldTo(FlyPart, result.Instance)

            SplatterImage.AncestryChanged:Connect(function()
                if not SplatterImage:IsDescendantOf(workspace) then
                    task.wait(math.random(10, 60))
                    FlyPart:Destroy()
                end
            end)

            task.spawn(function()
                task.wait(math.random(
                    DeathConfig.RotTime * 0.75,
                    DeathConfig.RotTime * 1.25
                ))
                if SplatterImage:IsDescendantOf(workspace) then
                    local Flies = FlyParticles:Clone()
                    Flies.Parent = FlyPart

                    local FlySound = Util.CreateInstance("Sound", {
                        Looped = true;
                        Parent = FlyPart;
                        RollOffMaxDistance = 20;
                        RollOffMinDistance = 1;
                        SoundId = SoundIds.Flies;
                        Volume = 0.1;
                    })

                    FlySound:Play()
                end
            end)
		end
	end
end

---Deal damage to a Humanoid
---@param Humanoid Humanoid The Humanoid to damage
---@param damage number The amount of damage to deal
---@param source string The source to mark (if fatal, put in death logs)
---@param sourcePlayer number The UserId of the Player who did the damage
module.TakeDamage = function(
    Humanoid: Humanoid,
    damage: number,
    source: string,
    sourcePlayer: number
)
    if Humanoid:GetAttribute("NoDamage") then
        return warn(
            `{script}.TakeDamage: The Humanoid {Humanoid:GetFullName()} is \z
            marked with the "NoDamage" attribute!`
        )
    end

    local damageCount = (Humanoid:GetAttribute("DamageCount") or 0) + 1

    Humanoid:SetAttribute("DamageCount", damageCount)
    Humanoid:SetAttribute("LastDamage", source)
    Humanoid:SetAttribute("LastDamager", sourcePlayer)
    Humanoid:TakeDamage(damage)

    task.spawn(function()
        task.wait(5)
        if Humanoid:GetAttribute("DamageCount") == damageCount then
            Humanoid:SetAttribute("LastDamage", nil)
            Humanoid:SetAttribute("LastDamager", nil)
        end
    end)
end

return module