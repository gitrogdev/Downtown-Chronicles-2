---Handles all use of firearms on the server
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local BoxScript = script.BoxScript
local ClientScript = script.FirearmClient
local FeedScript = script.FeedScript

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local ChamberWeapon = ReplicatedCommunication.ChamberWeapon
local FireBullet = ReplicatedCommunication.FireBullet
local FireSelector = ReplicatedCommunication.FireSelector
local GetConfig = ReplicatedCommunication.FirearmConfig
local InitializeBox = ReplicatedCommunication.InitializeBox
local InitializeFeed = ReplicatedCommunication.InitializeFeed
local InitializeFirearm = ReplicatedCommunication.InitializeFirearm
local LoadFeed = ReplicatedCommunication.LoadFeed
local Recoil = ReplicatedCommunication.Recoil
local ReloadWeapon = ReplicatedCommunication.ReloadWeapon
local TriggerPull = ReplicatedCommunication.TriggerPull

local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local BreakageHandler = require(ServerScripts.Breakage)
local CollisionHandler = require(ServerScripts.Collisions)
local DeathHandler = require(ServerScripts.Deaths)
local InventoryHandler
local ServerConfig = ServerScripts.Configuration
local Util = require(ServerScripts.Util)

local WeaponConfig = require(ServerConfig.Weapons)

local PartStorage = ServerStorage.Parts
local CartridgeStorage = PartStorage.Cartridges
local ImpactDebris = PartStorage.ImpactDebris
local MuzzleEffects = PartStorage.MuzzleEffects
local TracerTemplate = PartStorage.Tracer
local ToolStorage = PartStorage.Tools

local BoxConfigs = {}
for i, BoxConfig in ipairs(script.Boxes:GetChildren()) do
    BoxConfigs[BoxConfig.Name] = require(BoxConfig)
end

local FeedConfigs = {}
for i, FeedConfig in ipairs(script.Feeds:GetChildren()) do
    FeedConfigs[FeedConfig.Name] = require(FeedConfig)
end

local FirearmsConfigs = {}
for i, FirearmConfig in ipairs(script.Firearms:GetChildren()) do
    FirearmsConfigs[FirearmConfig.Name] = require(FirearmConfig)
end

for i, Child in ipairs(CartridgeStorage:GetDescendants()) do
    if Child:IsA("BasePart") then
        Child.CanQuery = false
    end
end

local initialized = {}

---Eject one or more shells from a weapon
---@param Weapon Tool The weapon to eject the shell from
---@param Cartridge Model The cartridge to eject
---@param spent boolean Whether the cartridge was spent
---@param count number The number of cartridges to eject (defaults to 1)
---@param velocity number The muzzle velocity of the firearm
---@param caliberConfig table The configuration file for the cartridge
---@param Player Player The Player to apply recoil to
local function ejectShell(
    Weapon: Tool,
    Cartridge: Model,
    spent: boolean,
    count: number,
    velocity: number,
    caliberConfig: table,
    Player: Player
)
    local Ejector = Weapon:FindFirstChild("Ejector")
    if Ejector then
        task.spawn(function()
            for i = 1, (count or 1) do
                local Shell = (
                    spent and Cartridge:FindFirstChild("SpentShell")
                    or Cartridge.Shell
                ):Clone()

                local EjectCartridge = Util.CreateInstance("Model", {
                    Name = "EjectedShell";
                })

                Shell.Parent = EjectCartridge
                EjectCartridge.PrimaryPart = Shell

                if spent and Cartridge:FindFirstChild("SpentBase") then
                    local SpentBase = Cartridge.SpentBase:Clone()
                    SpentBase.Parent = EjectCartridge
                    Util.WeldTo(SpentBase, Shell)
                    CollisionHandler.Group(SpentBase, "Shells")
                elseif not spent then
                    local Bullet = Cartridge.Bullet:Clone()
                    Bullet.Parent = EjectCartridge
                    Util.WeldTo(Bullet, Shell)
                    CollisionHandler.Group(Bullet, "Shells")

                    if Cartridge:FindFirstChild("Base") then
                        local Base = Cartridge.Base:Clone()
                        Base.Parent = EjectCartridge
                        Util.WeldTo(Base, Shell)
                        CollisionHandler.Group(Base, "Shells")
                    end
                end

                CollisionHandler.Group(Shell, "Shells")

                Shell.Anchored = false
               
                local orientation = Ejector.Orientation + Vector3.new(
                    math.random(-1000, 1000) / 100,
                    math.random(-1000, 1000) / 100,
                    math.random(-1000, 1000) / 100
                )

                EjectCartridge:SetPrimaryPartCFrame(
                    CFrame.new(Ejector.Position)
                    * CFrame.Angles(
                        orientation.X,
                        orientation.Y,
                        orientation.Z
                    )
                )

                local force = Util.MuzzleForce(
                    caliberConfig.Mass, velocity, 1
                )

                local shellVelocity = force / (caliberConfig.Weight * 1000 - (
                    spent and (caliberConfig.Mass) or 0
                ))

                Shell.Velocity = Ejector.CFrame.LookVector * shellVelocity
                    + Vector3.new(
                        math.random(-1000, 1000) / 100,
                        math.random(0, 3000) / 100,
                        math.random(-1000, 1000) / 100
                    )

                if Player then
                    Recoil:FireClient(Player, force)
                end

                Util.Debris(EjectCartridge, 1000)
                task.spawn(function()
                    task.wait(5)
                    while Shell.Velocity.Magnitude > 0.1 do
                        task.wait()
                    end
                    Shell.Anchored = true
                    Shell.CanCollide = false
                    if EjectCartridge:FindFirstChild("Bullet") then
                        EjectCartridge.Bullet.Anchored = true
                        EjectCartridge.Bullet.CanCollide = false
                    end
                end)

                EjectCartridge.Parent = workspace

                local ShellSound = Util.CreateInstance("Sound", {
                    Parent = Shell;
                    RollOffMaxDistance = 20;
                    RollOffMinDistance = 10;
                    SoundId = Sounds.ShellEject;
                    Volume = 0.5;
                })
                ShellSound.Ended:Once(function()
                    ShellSound:Destroy()
                end)
                ShellSound:Play()
                task.wait(0.1)
            end
        end)
    end
end

---Rotate the chambers of a revolver
---@param Weapon Tool The weapon to rotate the chambers of
---@param config table The configuration for the weapon
local function rotateChambers(Weapon: Tool, config: table)
    local newChambers = {}
    for i = 1, config.Chambers do
        newChambers[Util.EnforceRange(i + 1, 1, config.Chambers)] =
            Weapon:GetAttribute(`Chambered{i == 1 and "" or i}`)
        Weapon:SetAttribute(`Chambered{i == 1 and "" or i}`, nil)
    end

    for i, value in pairs(newChambers) do
        Weapon:SetAttribute(`Chambered{i == 1 and "" or i}`, value)
    end
end

---Validates the path of a bullet
---@param config table The configuration fire for the firearm used
---@param origin table The origin of the bullet (direction, spread and origin)
---@param path table The path the bullet is taking
---@return boolean
local function validatePath(config: table, origin: table, path: table)
    local originalSlope = (origin.Origin.X - path[1].Position.X)
        / (origin.Origin.Z - path[1].Position.Z)
    local velocity = config.MuzzleVelocity
    for i, step in ipairs(path) do
        if step.Velocity > velocity then
            return warn(
                `{script}.validatePath: Velocity increase detected at step \z
                {i}! (Initial velocity: {config.MuzzleVelocity} mps, velocity \z
                at step {i - 1}: {velocity} mps, velocity at step {i}: \z
                {step.Velocity} mps)`
            )
        end
        velocity = step.Velocity

        local slope =  (origin.Origin.X - step.Position.X)
            / (origin.Origin.Z - step.Position.Z)
        local diff = math.abs(originalSlope-slope)
        if diff > 0.2 then
            warn(
                `{script}.validatePath: Step {i} in the path has a \z
                difference of {Util.Round(diff, 2)} from the calculated \z
                slope! (Calculated: {Util.Round(originalSlope, 2)}, Got: \z
                {Util.Round(slope, 2)}, Origin point: {origin.Origin}, \z
                Hit point: {step.Position})`
            )
        end
    end

    return true
end

---Manually chamber a round
---@param Player Player The Player chambering the weapon
---@param Weapon Tool The weapon being chambered
ChamberWeapon.OnServerEvent:Connect(function(
    Player: Player, Weapon: Tool
)
    if not (Weapon:IsA("Tool") and
        (Player.Character and Weapon.Parent == Player.Character)
    ) then
        return warn(
            `{script}.ChamberWeapon.OnServerEvent: The item {Weapon} is not \z
            currently equipped by {Player}!`
        )
    end

    if Weapon:GetAttribute("InAction") then
        return warn(
            `{script}.ChamberWeapon.OnServerEvent: The item {Weapon} is \z
            currently in action!`
        )
    end

    local config = FirearmsConfigs[Weapon:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.ChamberWeapon.OnServerEvent: Unknown firearm \z
            {Weapon:GetAttribute("FileName")}!`
        )
    end

    if config.DontChamber then
        return warn(
            `{script}.ChamberWeapon.OnServerEvent: Firearm with file name \z
            {Weapon:GetAttribute("FileName")} can not be chambered!`
        )
    end

    local feed = Weapon:GetAttribute("FeedPart")
    local feedConfig = config.FeedParts[feed]
    if not feedConfig then
        return warn(
            `{script}.ChamberWeapon.OnServerEvent: No loaded FeedPart found \z
            for {Player}'s {Weapon:GetAttribute("FileName")} {Weapon}!`
        )
    end

    local capacity = Weapon:GetAttribute("Capacity") or 0
    local chambered = Weapon:GetAttribute("Chambered")
    if capacity < 1 and not chambered then
        if not config.Chambers or not feed then
            return warn(
                `{script}.ChamberWeapon.OnServerEvent: The item {Weapon} is \z
                currently empty!`
            )
        end
    end

    local Cartridge = CartridgeStorage:FindFirstChild(feedConfig.Caliber.Name)
    if not Cartridge then
        return warn(
            `{script}.ChamberWeapon.OnServerEvent: Unable to find cartridge \z
            for caliber {feedConfig.Caliber.Name}!`
        )
    end
    Cartridge = Cartridge:Clone()

    Weapon:SetAttribute("Chambering", true)
    Weapon:SetAttribute("InAction", true)

    local addLive = false
    if not config.Chambers then
        if chambered then
            ejectShell(
                Weapon,
                Cartridge,
                chambered == "Spent",
                1,
                50,
                feedConfig.Caliber
            )
            Weapon:SetAttribute("Chambered", nil)
        end

        if capacity > 0 then
            Weapon:SetAttribute("Capacity", capacity - 1)
            addLive = true
        elseif feedConfig.Type == "Box" then
            Weapon:SetAttribute("FeedPart", nil)
        end
    end

    local soundProperties = {
        RollOffMaxDistance = 50;
        Parent = Weapon.Handle;
        Volume = 0.5;
    }
    
    for property, value in pairs(config.ChamberSound) do
        soundProperties[property] = value
    end
    local ChamberSound = Util.CreateInstance("Sound", soundProperties)
    ChamberSound.Ended:Once(function()
        ChamberSound:Destroy()
    end)
    ChamberSound:Play()

    for i, Child in pairs(Weapon:GetChildren()) do
        if Child.Name == "ActionClosed" then
            Child.Transparency = 1
        elseif Child.Name == "ActionOpen" then
            Child.Transparency = 0
        end
    end

    task.wait(config.ChamberTime)

    if config.Chambers then
        rotateChambers(Weapon, config)
    elseif addLive then
        Weapon:SetAttribute("Chambered", "Live")
    end

    if Weapon:GetAttribute("Chambered") then
        for i, Child in pairs(Weapon:GetChildren()) do
            if Child.Name == "ActionClosed" then
                Child.Transparency = 0
            elseif Child.Name == "ActionOpen" then
                Child.Transparency = 1
            end
        end
    end

    Weapon:SetAttribute("Chambering", nil)
    Weapon:SetAttribute("InAction", nil)
end)

---Fires a bullet from a Player's firearm
---@param Player Player The Player firing the weapon
---@param Weapon Tool The weapon being fired
---@param paths table The calculated paths of the bullets
---@param origins table A table containing the direction and origin point
FireBullet.OnServerEvent:Connect(function(
    Player: Player, Weapon: Tool, paths: table, origins: table
)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.FireBullet.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Weapon:IsA("Tool") and
        (Player.Character and Weapon.Parent == Player.Character)
    ) then
        return warn(
            `{script}.FireBullet.OnServerEvent: The item {Weapon} is not \z
            currently equipped by {Player}!`
        )
    end

    local config = FirearmsConfigs[Weapon:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.FireBullet.OnServerEvent: Unknown firearm \z
            {Weapon:GetAttribute("FileName")}!`
        )
    end

    local feedConfig = config.FeedParts[Weapon:GetAttribute("FeedPart")]
    if not feedConfig then
        return warn(
            `{script}.FireBullet.OnServerEvent: No loaded FeedPart found for \z
            {Player}'s {Weapon:GetAttribute("FileName")} {Weapon}!`
        )
    end

    local capacity = Weapon:GetAttribute("Capacity") or 0
    local chambered = Weapon:GetAttribute("Chambered")
    if chambered ~= "Live" then
        return warn(
            `{script}.FireBullet.OnServerEvent: {Player}'s \z
            {Weapon:GetAttribute("FileName")} {Weapon} is empty ({chambered} \z
            round in chamber!)`
        )
    end

    local FirePart = Weapon:FindFirstChild("FirePart")
    if not FirePart then
        return warn(
            `{script}.FireBullet.OnServerEvent: No FirePart found for \z
            {Player}'s {Weapon:GetAttribute("FileName")} {Weapon}!`
        )
    end

    local count = feedConfig.Caliber.Count or 1
    if #paths ~= count or #origins ~= count then
        return warn(
            `{script}.FireBullet.OnServerEvent: Improper number of paths and \z
            origins sent! (Expected: {count}, Paths received: {#paths}, \z
            Origins received: {#origins})`
        )
    end

    local baseOrigin = origins[1]
    for i, origin in ipairs(origins) do
        if origin.Direction ~= baseOrigin.Direction then
            return warn(
                `{script}.FireBullet.OnServerEvent: Direction mismatch found \z
                at origin {i} for {Player}!`
            )
        end

        if origin.Origin ~= baseOrigin.Origin then
            print(origin.Origin, baseOrigin.Origin)
            return warn(
                `{script}.FireBullet.OnServerEvent: Origin mismatch found \z
                at origin {i} for {Player}!`
            )
        end
    end

    local originDistance = (baseOrigin.Origin - FirePart.Position).Magnitude
    if originDistance > 5 then
        return warn(
            `{script}.FireBullet.OnServerEvent: The origin point \z
            {baseOrigin.Origin} is too far ({Util.Round(originDistance, 2)} \z
            from the FirePart's current position ({FirePart.Position}) \z
            for {Player}'s {Weapon:GetAttribute("FileName")} {Weapon}!`
        )
    end

    for i = 1, count do
        if not validatePath(config, origins[i], paths[i]) then
            return warn(
                `{script}.FireBullet.OnServerEvent: {Player} provided an \z
                invalid bullet path for their \z
                {Weapon:GetAttribute("FileName")} {Weapon}!`
            )
        end
    end

    local Cartridge = CartridgeStorage:FindFirstChild(feedConfig.Caliber.Name)
    if not Cartridge then
        return warn(
            `{script}.FireBullet.OnServerEvent: Unable to find cartridge \z
            for caliber {feedConfig.Caliber.Name}!`
        )
    end
    Cartridge = Cartridge:Clone()

    local firemode = Weapon:GetAttribute("Conversion")
        or config.Firemodes[Weapon:GetAttribute("Firemode") or 1]
    if firemode == "Manual" or firemode == "Single" or firemode == "Double" then
        Weapon:SetAttribute("Chambered", "Spent")
    else
        if capacity > 0 then
            Weapon:SetAttribute("Capacity", capacity - 1)
        else
            Weapon:SetAttribute("Chambered", nil)
        end

        if feedConfig.Type == "Box" and capacity - 1 < 1 then
            Weapon:SetAttribute("FeedPart", nil)
        end
    end

    local source = `{Player:GetAttribute("FullName")}'s ({Player}'s) \z
        {Weapon:GetAttribute("DisplayName")
        or Weapon:GetAttribute("FileName")} \z
        ({Weapon})`

    if
        capacity < 1
        and Weapon:GetAttribute("Chambered") == "Spent"
        and config.OpenActionOnEmpty
    then
        for i, Child in pairs(Weapon:GetChildren()) do
            if Child.Name == "ActionClosed" then
                Child.Transparency = 1
            elseif Child.Name == "ActionOpen" then
                Child.Transparency = 0
            end
        end
    end

    for i, Child in ipairs(FirePart:GetChildren()) do
        if Child:GetAttribute("MuzzleEffect") then
            Child.Enabled = true
        end
    end

    task.spawn(function()
        task.wait(0.2)
        for i, Child in ipairs(FirePart:GetChildren()) do
            if Child:GetAttribute("MuzzleEffect") then
                Child.Enabled = false
            end
        end
    end)

    local soundProperties = {
        Parent = FirePart;
        PlaybackSpeed = 1;
        RollOffMaxDistance = config.MuzzleVelocity / 2;
        RollOffMode = Enum.RollOffMode.InverseTapered;
        Volume = 1;
    }
    for property, value in pairs(config.Sound) do
        soundProperties[property] = value
    end

    local CloseSound = Util.CreateInstance("Sound", soundProperties)

    local force = Util.MuzzleForce(
        feedConfig.Caliber.Mass, config.MuzzleVelocity, feedConfig.Caliber.Count
    )
    local emitter = force / (config.BarrelLength * 1000)

    soundProperties.RollOffMinDistance = emitter
    soundProperties.RollOffMaxDistance = config.MuzzleVelocity * 10
    soundProperties.RollOffMode = Enum.RollOffMode.InverseTapered
    local FarSound = Util.CreateInstance("Sound", soundProperties)
    Util.CreateInstance("EqualizerSoundEffect", {
        HighGain = -80;
        LowGain = -80;
        Parent = FarSound;
    })

    CloseSound.Ended:Once(function()
        CloseSound:Destroy()
    end)
    CloseSound:Play()

    FarSound.Ended:Once(function()
        FarSound:Destroy()
    end)
    FarSound:Play()

    local eject = 1
    if config.StoreShells then
        local storedShells = Weapon:GetAttribute("StoredShells") or 0
        if storedShells >= config.StoreShells then
            eject = config.StoreShells
            Weapon:SetAttribute("StoredShells", 0)
        else
            eject = 0
            Weapon:SetAttribute("StoredShells", storedShells + 1)
        end
    end

    if firemode == "Double" then
        rotateChambers(Weapon, config)
    elseif firemode ~= "Manual" and firemode ~= "Single" then
        ejectShell(
            Weapon,
            Cartridge,
            true,
            eject,
            config.MuzzleVelocity / 4,
            feedConfig.Caliber,
            Player
        )
    end

    for i = 1, count do
        local path = paths[i]
        local origin = origins[i]

        local Projectile = Cartridge.Bullet:Clone()
        Projectile.Anchored = true
        Projectile.CanCollide = false
        Projectile.Position = baseOrigin.Origin
        Projectile.Parent = workspace

        if feedConfig.Caliber.Effects then
            local Effects = PartStorage:FindFirstChild(
                feedConfig.Caliber.Effects
            )
            if Effects then
                for j, Effect in ipairs(Effects:GetChildren()) do
                    Effect:Clone().Parent = Projectile
                end
            end
        end

        Debris:AddItem(Projectile, 10)

        if config.Tracers > 0 and capacity % config.Tracers == 0 then
            local Tracer = TracerTemplate:Clone()
            for i = 0, 1 do
                Tracer[`Attachment{i}`] = Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(
                        0, 0,
                        Util.MetersToStuds(feedConfig.Caliber.Diameter / 1000) *
                        (i == 0 and -3 or 3)
                    );
                    Parent = Projectile;
                })
            end
            Tracer.Parent = Projectile
        end

        Util.CreateInstance("Sound", {
            Looped = true;
            Name = "WhizSound";
            Parent = Projectile;
            RollOffMaxDistance = 10;
            SoundId = Sounds.BulletWhiz;
            Volume = 5;
        }):Play()

        local function projectileStep(pos: number)
            local step = path[pos]

            local destination = step.Position
            local ProjectileTween = TweenService:Create(
                Projectile, TweenInfo.new(
                    (origin.Origin - destination).Magnitude
                    / config.MuzzleVelocity
                ), {
                    Position = destination
                }
            )

            ProjectileTween.Completed:Connect(function()
                if step.Instance then
                    local Humanoid = step.Instance.Parent
                        and step.Instance.Parent:FindFirstChildOfClass(
                            "Humanoid"
                        )

                    if not (
                        step.Instance:IsA("MeshPart")
                        or step.Instance:FindFirstChildOfClass("SpecialMesh")
                    ) then
                        local bulletSize = Util.MetersToStuds(
                            feedConfig.Caliber.Diameter / 1000
                        ) * 5
                        local relativeData = step.Instance.CFrame:ToWorldSpace(
                            step.Instance.CFrame:ToObjectSpace(
                                CFrame.new(step.Position))
                                + (
                                    step.Instance.CFrame.Position
                                    - step.Instance.CFrame.Position
                                ));

                        local HolePart = Util.CreateInstance("Part", {
                            CanCollide = false;
                            CanQuery = false;
                            CFrame = CFrame.new(
                                relativeData.Position,
                                relativeData.Position + step.Surface
                            );
                            Massless = true;
                            Name = "BulletHole";
                            Parent = step.Instance;
                            Size = Vector3.new(bulletSize, bulletSize, 0.05);
                            Transparency = 1;
                        }, {
                            OnSurface = true;
                        })

                        Util.WeldTo(HolePart, step.Instance, step.WasAt)
                        
                        local HoleDecal = Util.CreateInstance("ImageLabel", {
                            BackgroundTransparency = 1;
                            Image = "rbxassetid://2859765692";
                            ImageTransparency = 1 -
                                (step.Velocity / config.MuzzleVelocity);
                            Parent = Util.CreateInstance("SurfaceGui", {
                                AlwaysOnTop = false;
                                Enabled = true;
                                LightInfluence = 1;
                                Parent = HolePart;
                            });
                            Size = UDim2.fromScale(1, 1);
                        })

                        if feedConfig.Caliber.Incendiary then
                            HoleDecal.ImageColor3 = Color3.fromRGB(35, 35, 35)

                            local IncendiaryFire = Util.CreateInstance("Fire", {
                                Parent = HolePart;
                                Size = feedConfig.Caliber.Diameter;
                            })

                            local BurnTween = TweenService:Create(
                                IncendiaryFire,
                                TweenInfo.new(
                                    feedConfig.Caliber.Diameter * 3
                                    + math.random(0, 20)
                                ),
                                {
                                    Heat = 0;
                                    Size = 0;
                                }
                            )
                            BurnTween.Completed:Connect(function()
                                IncendiaryFire.Enabled = false
                                task.wait(5)
                                IncendiaryFire:Destroy()
                            end)
                            BurnTween:Play()

                            if Humanoid then
                                DeathHandler.Burn(
                                    Humanoid, IncendiaryFire, source, Player
                                )
                            end
                        elseif Humanoid then
                            HoleDecal.ImageColor3 = Color3.fromRGB(170, 0, 0)
                            if
                                Humanoid.Health > 0 and step.Velocity > 100
                                and not Humanoid:GetAttribute("NoDamage")
                            then
                                DeathHandler.Bleed(
                                    Humanoid,
                                    HolePart,
                                    source,
                                    50 *(step.Velocity / config.MuzzleVelocity),
                                    NumberSequence.new(
                                        Util.MetersToStuds(
                                            feedConfig.Caliber.Diameter / 1000
                                        )
                                    ),
                                    (1000 * Util.MetersToStuds(
                                        feedConfig.Caliber.Diameter / 1000
                                    )) * (step.Velocity / 20),
                                    Player
                                )
                            end
                        end

                        if step.Instance.Name == "HeadUnion" then
                            step.Instance = step.Instance.Parent:FindFirstChild(
                                    "Head"
                                ) or step.Instance
                        end
                    end
                    
                    local EntryDebris = ImpactDebris:Clone()
                    local last = (pos == 1 and origin.Origin)
                        or path[pos - 1].Position
                    local Emitter: ParticleEmitter =
                        EntryDebris:FindFirstChildOfClass("ParticleEmitter")
                    Emitter.Size = NumberSequence.new(
                        step.Velocity / 800, step.Velocity / 200
                    )
                    Emitter.Speed = NumberRange.new(
                        step.Velocity / 200, step.Velocity / 40
                    )
                    EntryDebris.CFrame = CFrame.new(
                        step.Position, (last - step.Position).Unit
                    )

                    local hitMaterial = Humanoid and "Humanoid"
                        or tostring(step.Instance.Material):gsub(
                            "Enum.Material.", ""
                        )
                    local HitSound = Util.CreateInstance("Sound", {
                        RollOffMaxDistance = 15;
                        SoundId = Sounds[`BulletHit{hitMaterial}`]
                            or Sounds.BulletHit;
                        Parent = EntryDebris;
                        Volume = 1;
                    })
                    if HitSound.SoundId == Sounds.BulletHitHumanoid then
                        HitSound.Volume = 0.25
                    end

                    HitSound.Ended:Once(function()
                        HitSound:Destroy()
                    end)
                    
                    HitSound:Play()
                    
                    task.spawn(function()
                        Emitter.Color = ColorSequence.new(
                            Humanoid and Color3.fromRGB(255, 92, 95)
                            or step.Instance.Color
                        )
                        Emitter.EmissionDirection = Enum.NormalId.Front
                        
                        task.wait(0.15)

                        Emitter.Enabled = false

                        task.wait(Emitter.Lifetime.Max)

                        EntryDebris:Destroy()
                    end)
                    EntryDebris.Parent = workspace

                    local p = Util.Momentum(
                        feedConfig.Caliber.Mass / 1000,
                        step.Velocity
                    )
                    local damage = p * 10 * (
                        WeaponConfig.DamageModifiers[step.Instance.Name]
                        or 1
                    )

                    if Humanoid and not Humanoid:GetAttribute("NoDamage") then
                        print(
                            `{script}.FireBullet.OnServerEvent: Dealing \z
                            {Util.Round(damage, 2)} damage to \z
                            {Humanoid.Parent} from {Player}'s \z
                            {Weapon:GetAttribute("DisplayName")} {Weapon}`
                        )

                        if
                            damage > 1 and (Humanoid.Health > 0
                            or damage > step.Instance.Size.Magnitude * 100)
                        then
                            DeathHandler.Splatter(
                                Humanoid, damage, step.Position
                            )
                        end
                        DeathHandler.TakeDamage(
                            Humanoid, damage, source, Player.UserId
                        )

                        if damage > step.Instance.Size.Magnitude * 100 then
                            if
                                step.Instance.Name == "Head"
                                and step.Instance.Parent:FindFirstChild(
                                    "HeadUnion"
                                )
                            then
                                step.Instance.Parent.HeadUnion:Destroy()
                            end
                            step.Instance:Destroy()
                        end
                    end

                    if step.Instance:GetAttribute("Breakable") then
                        BreakageHandler.Damage(step.Instance, damage, Player)
                    end
                end

                if pos == #path then
                    Projectile.Transparency = 1
                    if Projectile:FindFirstChild("WhizSound") then
                        Projectile.WhizSound:Stop()
                    end
                    for j, Effect in ipairs(Projectile:GetChildren()) do
                        pcall(function()
                            Effect.Enabled = false
                        end)
                    end
                else
                    projectileStep(pos + 1)
                end
            end)
            ProjectileTween:Play()
        end
        projectileStep(1)
    end
end)

---Switch the firemode of a firearm
---@param Player Player The Player switching the firemode
---@param Weapon Tool The firearm having its mode switched
FireSelector.OnServerEvent:Connect(function(Player: Player, Weapon: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.FireSelector.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Weapon:IsA("Tool") and
        (Player.Character and Weapon.Parent == Player.Character)
    ) then
        return warn(
            `{script}.FireSelector.OnServerEvent: The item {Weapon} is not \z
            currently equipped by {Player}!`
        )
    end

    local config = FirearmsConfigs[Weapon:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.FireSelector.OnServerEvent: Unknown firearm \z
            {Weapon:GetAttribute("FileName")}!`
        )
    end

    if #config.Firemodes == 1 then
        return warn(
            `{script}.FireSelector.OnServerEvent: \z
            {Weapon:GetAttribute("FileName")} does not have a fire selector!`
        )
    end

    Weapon:SetAttribute("Firemode", Util.EnforceRange(
        (Weapon:GetAttribute("Firemode") or 1) + 1, 1, #config.Firemodes
    ))

    local SelectorSound = Util.CreateInstance("Sound", {
        RollOffMaxDistance = 20;
        Parent = Weapon.Handle;
        SoundId = Sounds.FireSelector;
        Volume = 0.5;
    })
    SelectorSound.Ended:Once(function()
        SelectorSound:Destroy()
    end)
    SelectorSound:Play()
end)

---Send the configuration file for a firearm to the client
---@param Player Player The Player requesting the configuration
---@param Weapon Tool The firearm to get the configuration for
---@return table
GetConfig.OnServerInvoke = function(Player: Player, Weapon: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.FirearmConfig.OnServerInvoke: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Weapon:IsA("Tool") and (
        Weapon.Parent == Inventory
        or (Player.Character and Weapon.Parent == Player.Character))
    ) then
        return warn(
            `{script}.FirearmConfig.OnServerInvoke: The item {Weapon} is \z
            not in {Player}'s inventory!`
        )
    end

    local config = FirearmsConfigs[Weapon:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.FirearmConfig.OnServerInvoke: Unknown firearm \z
            {Weapon:GetAttribute("FileName")}!`
        )
    end

    return config
end

---Initialize a new ammunition box
---@param Player Player The Player initializing an ammunition box
---@param Box Tool The ammunition box device to initialize
InitializeBox.OnServerEvent:Connect(function(Player: Player, Box: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.InitializeBox.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Box:IsA("Tool") and (
        Box.Parent == Inventory
        or (Player.Character and Box.Parent == Player.Character))
    ) then
        return warn(
            `{script}.InitializeBox.OnServerEvent: The item {Box} is \z
            not in {Player}'s inventory!`
        )
    end

    if initialized[Box] then
        return warn(
            `{script}.InitializeBox.OnServerEvent: The item {Box} has \z
            already been initialized!`
        )
    end

    local itemData = InventoryHandler.Items.Items[
        Box:GetAttribute("FileName")
    ]
    if not itemData then
        return warn(
            `{script}.InitializeBox.OnServerEvent: Unknown tool \z
            {Box:GetAttribute("FileName")}!`
        )
    end

    local config = BoxConfigs[Box:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.InitializeBox.OnServerEvent: Unknown ammunition box \z
            {Box:GetAttribute("FileName")}!`
        )
    end

    initialized[Box] = true

    local function updateWeight()
        local capacity = Box:GetAttribute("Capacity") or 0
        Box:SetAttribute(
            "Weight", itemData.Weight + (capacity * config.Caliber.Weight)
        )
    end
    updateWeight()

    Box:GetAttributeChangedSignal("Capacity"):Connect(updateWeight)
end)

---Initialize a new feed device
---@param Player Player The Player initializing a feed device
---@param Feed Tool The feed device to initialize
InitializeFeed.OnServerEvent:Connect(function(Player: Player, Feed: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.InitializeFeed.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Feed:IsA("Tool") and (
        Feed.Parent == Inventory
        or (Player.Character and Feed.Parent == Player.Character))
    ) then
        return warn(
            `{script}.InitializeFeed.OnServerEvent: The item {Feed} is \z
            not in {Player}'s inventory!`
        )
    end

    if initialized[Feed] then
        return warn(
            `{script}.InitializeFeed.OnServerEvent: The item {Feed} has \z
            already been initialized!`
        )
    end

    local itemData = InventoryHandler.Items.Items[
        Feed:GetAttribute("FileName")
    ]
    if not itemData then
        return warn(
            `{script}.InitializeFeed.OnServerEvent: Unknown tool \z
            {Feed:GetAttribute("FileName")}!`
        )
    end

    local config = FeedConfigs[Feed:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.InitializeFeed.OnServerEvent: Unknown feed device \z
            {Feed:GetAttribute("FileName")}!`
        )
    end

    initialized[Feed] = true

    local function updateCartridges()
        local capacity = Feed:GetAttribute("Capacity")

        Feed:SetAttribute(
            "Weight", itemData.Weight + (capacity * config.Caliber.Weight)
        )

        if Feed:FindFirstChild("Shell1") then
            for i = 1, Feed:GetAttribute("MaxCapacity") do
                local Shell = Feed:FindFirstChild(`Shell{i}`)
                if Shell then
                    Shell.Transparency = i <= capacity and 0 or 1
                end

                local Bullet = Feed:FindFirstChild(`Bullet{i}`)
                if Bullet then
                    Bullet.Transparency = i <= capacity and 0 or 1
                end
            end
        end
    end
    Feed:GetAttributeChangedSignal("Capacity"):Connect(updateCartridges)
    updateCartridges()
end)

---Initialize a new firearm
---@param Player Player The Player initializing a firearm
---@param Weapon Tool The firearm to initialize
InitializeFirearm.OnServerEvent:Connect(function(Player: Player, Weapon: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.InitializeFirearm.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Weapon:IsA("Tool") and (
        Weapon.Parent == Inventory
        or (Player.Character and Weapon.Parent == Player.Character))
    ) then
        return warn(
            `{script}.InitializeFirearm.OnServerEvent: The item {Weapon} is \z
            not in {Player}'s inventory!`
        )
    end

    if initialized[Weapon] then
        return warn(
            `{script}.InitializeFirearm.OnServerEvent: The item {Weapon} has \z
            already been initialized!`
        )
    end

    local itemData = InventoryHandler.Items.Items[
        Weapon:GetAttribute("FileName")
    ]
    if not itemData then
        return warn(
            `{script}.InitializeFirearm.OnServerEvent: Unknown tool \z
            {Weapon:GetAttribute("FileName")}!`
        )
    end

    local config = FirearmsConfigs[Weapon:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.InitializeFirearm.OnServerEvent: Unknown firearm \z
            {Weapon:GetAttribute("FileName")}!`
        )
    end

    initialized[Weapon] = true

    if config.Chambers then
        for i = 1, config.Chambers do
            local chamberKey = `Chambered{i == 1 and "" or i}`
            local function updateChamber()
                local chambered = Weapon:GetAttribute(chamberKey)
                
                local Shell = Weapon:FindFirstChild(`Chamber{i}Shell`)
                if Shell then
                    Shell.Transparency = chambered and 0 or 1
                end
        
                local Bullet = Weapon:FindFirstChild(`Chamber{i}Bullet`)
                if Bullet then
                    Bullet.Transparency = chambered == "Live" and 0 or 1
                end
            end

            Weapon:GetAttributeChangedSignal(chamberKey):Connect(updateChamber)
        end
    end

    local function updateWeight()
        local weight = itemData.Weight
        local currentFeed = Weapon:GetAttribute("FeedPart")
        if currentFeed then
            local feedConfig = FeedConfigs[currentFeed]
            if feedConfig then
                if feedConfig.Type ~= "Box" then
                    local feedItemConfig = InventoryHandler.Items.Items[
                        currentFeed
                    ]
                    if feedItemConfig then
                        weight += feedItemConfig.Weight
                    end
                end

                if config.Chambers then
                    for i = 1, config.Chambers do
                        local chamberKey = `Chambered{i == 1 and "" or i}`
                        local chambered = Weapon:GetAttribute(chamberKey)
                        if chambered == "Live" then
                            weight += feedConfig.Caliber.Weight
                        else
                            weight += feedConfig.Caliber.Weight
                                - (feedConfig.Caliber.Mass / 1000)
                        end
                    end
                elseif Weapon:GetAttribute("Chambered") then
                    local chambered = Weapon:GetAttribute("Chambered")
                    if chambered == "Live" then
                        weight += feedConfig.Caliber.Weight
                    else
                        weight += feedConfig.Caliber.Weight
                            - (feedConfig.Caliber.Mass / 1000)
                    end
                end

                local currentCapacity = Weapon:GetAttribute("Capacity") or 0
                weight += currentCapacity * feedConfig.Caliber.Weight
            end
        end
        Weapon:SetAttribute("Weight", weight)
    end
    Weapon:GetAttributeChangedSignal("Capacity"):Connect(updateWeight)
    Weapon:GetAttributeChangedSignal("FeedPart"):Connect(updateWeight)
    updateWeight()
end)

---Load bullets from a box into a feed device
---@param Player Player The player loading the bullets
---@param Box Tool The box being loaded from
---@param Feed Tool The feed device being loaded
---@param fill boolean Whether to fill the feed device as much as possible
LoadFeed.OnServerEvent:Connect(function(
    Player: Player, Box: Tool, Feed: Tool, fill: boolean
)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.LoadFeed.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Box:IsA("Tool") and
        (Player.Character and Box.Parent == Player.Character)
    ) then
        return warn(
            `{script}.LoadFeed.OnServerEvent: The ammo box {Box} is not \z
            currently equipped by {Player}!`
        )
    end

    if not (Feed:IsA("Tool") and Feed.Parent == Inventory) then
        return warn(
            `{script}.LoadFeed.OnServerEvent: The feed device {Feed} is not \z
            currently in {Player}'s inventory!`
        )
    end

    local boxConfig = BoxConfigs[Box:GetAttribute("FileName")]
    if not boxConfig then
        return warn(
            `{script}.LoadFeed.OnServerEvent: Unknown ammo box \z
            {Box:GetAttribute("FileName")}!`
        )
    end

    local feedConfig = FeedConfigs[Feed:GetAttribute("FileName")]
    if not feedConfig then
        return warn(
            `{script}.LoadFeed.OnServerEvent: Unknown feed device \z
            {Feed:GetAttribute("FileName")}!`
        )
    end

    if boxConfig.Caliber ~= feedConfig.Caliber then
        return warn(
            `{script}.LoadFeed.OnServerEvent: Caliber mismatch between \z
            {Box:GetAttribute("FileName")} and {Feed:GetAttribute("FileName")}!`
        )
    end

    local boxCapacity = Box:GetAttribute("Capacity") or 0
    if boxCapacity < 1 then
        return warn(
            `{script}.LoadFeed.OnServerEvent: Ammo box {Box} is empty!`
        )
    end

    local feedCapacity = Feed:GetAttribute("Capacity") or 0
    local feedMax = Feed:GetAttribute("MaxCapacity") or 0
    if feedCapacity >= feedMax then
        return warn(
            `{script}.LoadFeed.OnServerEvent: Feed device {Feed} is full!`
        )
    end

    local fillAmount = fill and (feedMax - feedCapacity) or 1
    if fillAmount > boxCapacity then
        fillAmount = boxCapacity
    end

    Box:SetAttribute("Capacity", boxCapacity - fillAmount)
    Feed:SetAttribute("Capacity", feedCapacity + fillAmount)

    local LoadSound = Util.CreateInstance("Sound", {
        RollOffMaxDistance = 20;
        Parent = Box.Handle;
        SoundId = Sounds.LoadBullet;
        Volume = 0.5;
    })
    LoadSound.Ended:Once(function()
        LoadSound:Destroy()
    end)
    LoadSound:Play()
end)

---Reloads a firearm
---@param Player Player The Player reloading the firearm
---@param Weapon Tool The firearm to reload
ReloadWeapon.OnServerEvent:Connect(function(Player: Player, Weapon: Tool)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return warn(
            `{script}.ReloadWeapon.OnServerEvent: No inventory found for \z
            player {Player}!`
        )
    end

    if not (Weapon:IsA("Tool") and
        (Player.Character and Weapon.Parent == Player.Character)
    ) then
        return warn(
            `{script}.ReloadWeapon.OnServerEvent: The item {Weapon} is not \z
            currently equipped by {Player}!`
        )
    end

    if Weapon:GetAttribute("InAction") then
        return warn(
            `{script}.ReloadWeapon.OnServerEvent: The item {Weapon} is \z
            currently in action!`
        )
    end

    local config = FirearmsConfigs[Weapon:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.ReloadWeapon.OnServerEvent: Unknown firearm \z
            {Weapon:GetAttribute("FileName")}!`
        )
    end

    if config.Chambers then
        local toLoad = {}
        local feedPart = Weapon:GetAttribute("FeedPart")

        if feedPart then
            local feedConfig = config.FeedParts[feedPart]
            local Cartridge = CartridgeStorage:FindFirstChild(
                feedConfig.Caliber.Name
            )

            for i = 1, config.Chambers do
                local chambered = Weapon:GetAttribute(
                    `Chambered{i == 1 and "" or i}`
                )

                if chambered ~= "Live" then
                    table.insert(toLoad, i)
                end
            end

            if #toLoad > 0 then
                Weapon:SetAttribute("Reloading", "Out")
                for i, chamber in pairs(toLoad) do
                    local chambered = Weapon:GetAttribute(
                        `Chambered{chamber == 1 and "" or chamber}`
                    )

                    if chambered then
                        Weapon:SetAttribute(
                            `Chambered{chamber == 1 and "" or chamber}`, nil
                        )
                        ejectShell(
                            Weapon, Cartridge, true, 1, 50, feedConfig.Caliber
                        )
                    end
                end

                if #toLoad == config.Chambers then
                    Weapon:SetAttribute("FeedPart", nil)
                end

                local soundProperties = {
                    RollOffMaxDistance = 50;
                    Parent = Weapon.Handle;
                    Volume = 0.5;
                }
                
                for property, value in pairs(feedConfig.MagOut.Sound) do
                    soundProperties[property] = value
                end
                local MagOutSound = Util.CreateInstance(
                    "Sound", soundProperties
                )
                MagOutSound.Ended:Once(function()
                    MagOutSound:Destroy()
                end)
                MagOutSound:Play()

                task.wait(feedConfig.MagOut.Time)
                Weapon:SetAttribute("Reloading", nil)
            end
        else
            for i = 1, config.Chambers do
                table.insert(toLoad, i)
            end
        end

        local hasAmmo
        for j, Item in ipairs(Inventory:GetChildren()) do
            local feedConfig = config.FeedParts[
                Item:GetAttribute("FileName")
            ]
            if not feedConfig then
                continue
            end

            if
                feedPart
                and feedPart ~= Item:GetAttribute("FileName")
            then
                warn(
                    `{script}.ReloadWeapon.OnServerEvent: Unable to load \z
                    {Item:GetAttribute("FileName")} for {Player}'s \z
                    {Weapon:GetAttribute("FileName")} ({Weapon}) because \z
                    it already has {Weapon:GetAttribute("FeedPart")} \z
                    loaded!`
                )
                continue
            end

            local capacity = Item:GetAttribute("Capacity") or 0
            if capacity > 0 then
                hasAmmo = true
                break
            end
        end

        if not hasAmmo then
            return warn(
                `{script}.ReloadWeapon.OnServerEvent: {Player} has no ammo to \z
                load for their {Weapon:GetAttribute("FileName")} ({Weapon})!`
            )
        end

        if #toLoad == 0 then
            return warn(
                `{script}.ReloadWeapon.OnServerEvent: {Player}'s \z
                {Weapon:GetAttribute("FileName")} ({Weapon}) is fully loaded!`
            )
        end

        for i, chamber in ipairs(toLoad) do
            local InsertFeed
            for j, Item in ipairs(Inventory:GetChildren()) do
                local feedConfig = config.FeedParts[
                    Item:GetAttribute("FileName")
                ]
                if not feedConfig then
                    continue
                end

                if
                    Weapon:GetAttribute("FeedPart")
                    and Weapon:GetAttribute("FeedPart")
                        ~= Item:GetAttribute("FileName")
                then
                    warn(
                        `{script}.ReloadWeapon.OnServerEvent: Unable to load \z
                        {Item:GetAttribute("FileName")} for {Player}'s \z
                        {Weapon:GetAttribute("FileName")} ({Weapon}) because \z
                        it already has {Weapon:GetAttribute("FeedPart")} \z
                        loaded!`
                    )
                    continue
                end

                local capacity = Item:GetAttribute("Capacity") or 0
                if capacity > 0 then
                    if
                        (not InsertFeed)
                        or (capacity > InsertFeed:GetAttribute("Capacity"))
                    then
                        InsertFeed = Item
                    end
                end
            end

            if InsertFeed then
                Weapon:SetAttribute("InAction", true)
                Weapon:SetAttribute("Reloading", "In")
                
                local capacity = InsertFeed:GetAttribute("Capacity") or 0
                local insertFeed = InsertFeed:GetAttribute("FileName")
                local feedConfig = config.FeedParts[insertFeed]

                InsertFeed:SetAttribute("Capacity", capacity - 1)

                local soundProperties = {
                    RollOffMaxDistance = 50;
                    Parent = Weapon.Handle;
                    Volume = 0.5;
                }
                
                for property, value in pairs(feedConfig.MagIn.Sound) do
                    soundProperties[property] = value
                end
                local MagInSound = Util.CreateInstance("Sound", soundProperties)
                MagInSound.Ended:Once(function()
                    MagInSound:Destroy()
                end)
                MagInSound:Play()
        
                task.wait(feedConfig.MagIn.Time)

                Weapon:SetAttribute(
                    `Chambered{chamber == 1 and "" or chamber}`,
                    "Live"
                )
                Weapon:SetAttribute("FeedPart", insertFeed)
                Weapon:SetAttribute("Reloading", nil)
                task.wait()
            end
        end

        Weapon:SetAttribute("InAction", nil)
        Weapon:SetAttribute("Reloading", nil)
        return
    end

    if config.EmptyChamber then
        local chambered = Weapon:GetAttribute("Chambered")
        if chambered then
            local feedConfig = config.FeedParts[Weapon:GetAttribute("FeedPart")]
            if not feedConfig then
                return warn(
                    `{script}.ReloadWeapon.OnServerEvent: No loaded FeedPart \z
                    found for {Player}'s {Weapon:GetAttribute("FileName")} \z
                    {Weapon}!`
                )
            end

            local Cartridge = CartridgeStorage:FindFirstChild(
                feedConfig.Caliber.Name
            )
            if not Cartridge then
                return warn(
                    `{script}.ReloadWeapon.OnServerEvent: Unable to find \z
                    cartridge for caliber {feedConfig.Caliber.Name}!`
                )
            end
            
            Cartridge = Cartridge:Clone()
            Weapon:SetAttribute("Chambered", nil)
            ejectShell(
                Weapon,
                Cartridge,
                chambered == "Spent",
                1,
                50,
                feedConfig.Caliber
            )
        end
    end

    local currentFeed = Weapon:GetAttribute("FeedPart")
    local RemovedFeed

    if currentFeed then
        local feedConfig = config.FeedParts[currentFeed]
        if not feedConfig then
            return warn(
                `{script}.ReloadWeapon.OnServerEvent: Unknown feed part \z
                {currentFeed} loaded in {Player}'s \z
                {Weapon:GetAttribute("FileName")} ({Weapon})!`
            )
        end

        if config.OpenActionOnReload then
            for i, Child in pairs(Weapon:GetChildren()) do
                if Child.Name == "ActionClosed" then
                    Child.Transparency = 1
                elseif Child.Name == "ActionOpen" then
                    Child.Transparency = 0
                end
            end
        end

        if feedConfig.Type == "Box" then
            if (
                Weapon:GetAttribute("Capacity") or 0
                ) + (
                    config.EmptyChamber
                    and Weapon:GetAttribute("Chambered") == "Live" and 1
                    or 0
                ) >= config.MaxCapacity
            then
                return warn(
                    `{script}.ReloadWeapon.OnServerEvent: {Player}'s \z
                    {Weapon:GetAttribute("FileName")} ({Weapon}) is already \z
                    full!`
                )
            end
        else
            local capacity = Weapon:GetAttribute("Capacity") or 0
            Weapon:SetAttribute("Capacity", 0)
            Weapon:SetAttribute("InAction", true)
            Weapon:SetAttribute("Reloading", "Out")
            
            for i, Child in pairs(Weapon:GetChildren()) do
                if Child.Name == currentFeed or Child.Name == "FeedClosed" then
                    Child.Transparency = 1
                elseif Child.Name == "FeedOpen" then
                    Child.Transparency = 0
                end
            end

            local soundProperties = {
                RollOffMaxDistance = 50;
                Parent = Weapon.Handle;
                Volume = 0.5;
            }
            
            for property, value in pairs(feedConfig.MagOut.Sound) do
                soundProperties[property] = value
            end
            local MagOutSound = Util.CreateInstance("Sound", soundProperties)
            MagOutSound.Ended:Once(function()
                MagOutSound:Destroy()
            end)
            MagOutSound:Play()

            task.wait(feedConfig.MagOut.Time)

            RemovedFeed = InventoryHandler.Items.new(
                currentFeed,
                `{Player:GetAttribute("FullName")}'s \z
                {Weapon:GetAttribute("DisplayName")}`,
                nil,
                Weapon:GetAttribute("FeedGUID")
            )
            RemovedFeed:SetAttribute("Capacity", capacity)
            RemovedFeed:SetAttribute("FromArmory", Weapon:GetAttribute(
                "FeedPartFromArmory"
            ))

            Weapon:SetAttribute("FeedPart", nil)
            Weapon:SetAttribute("FeedGUID", nil)
            Weapon:SetAttribute("FeedPartFromArmory", nil)
        end
    end

    local InsertFeed
    for i, Item in ipairs(Inventory:GetChildren()) do
        local feedConfig = config.FeedParts[Item:GetAttribute("FileName")]
        if not feedConfig then
            continue
        end

        if
            feedConfig.Type == "Box"
            and Weapon:GetAttribute("FeedPart")
            and Weapon:GetAttribute("FeedPart") ~= Item:GetAttribute("FileName")
        then
            warn(
                `{script}.ReloadWeapon.OnServerEvent: Unable to load \z
                {Item:GetAttribute("FileName")} for {Player}'s \z
                {Weapon:GetAttribute("FileName")} ({Weapon}) because it \z
                already has {Weapon:GetAttribute("FeedPart")} loaded!`
            )
            continue
        end

        local capacity = Item:GetAttribute("Capacity") or 0
        if capacity > 0 then
            if
                (not InsertFeed)
                or (capacity > InsertFeed:GetAttribute("Capacity"))
            then
                InsertFeed = Item
            end
        end
    end

    local capacity, feedConfig, insertFeed
    if InsertFeed then
        Weapon:SetAttribute("InAction", true)
        Weapon:SetAttribute("Reloading", "In")

        capacity = InsertFeed:GetAttribute("Capacity")
        insertFeed = InsertFeed:GetAttribute("FileName")
        feedConfig = config.FeedParts[insertFeed]

        if feedConfig.Type == "Box" then
            InsertFeed:SetAttribute("Capacity", capacity - 1)
        else
            for slot, stored in pairs(Inventory:GetAttributes()) do
                if stored == InsertFeed.Name then
                    Inventory:SetAttribute(slot, nil)
                    break
                end
            end
    
            InsertFeed:Destroy()
        end
    end

    if RemovedFeed then
        InventoryHandler.Add(Player, RemovedFeed, nil, true)
    end

    if InsertFeed then
        local soundProperties = {
            RollOffMaxDistance = 50;
            Parent = Weapon.Handle;
            Volume = 0.5;
        }
        
        for property, value in pairs(feedConfig.MagIn.Sound) do
            soundProperties[property] = value
        end
        local MagInSound = Util.CreateInstance("Sound", soundProperties)
        MagInSound.Ended:Once(function()
            MagInSound:Destroy()
        end)
        MagInSound:Play()

        task.wait(feedConfig.MagIn.Time)

        if config.OpenActionOnReload or config.OpenActionOnEmpty then
            for i, Child in pairs(Weapon:GetChildren()) do
                if Child.Name == "ActionClosed" then
                    Child.Transparency = 0
                elseif Child.Name == "ActionOpen" then
                    Child.Transparency = 1
                end
            end
        end

        for i, Child in pairs(Weapon:GetChildren()) do
            if Child.Name == insertFeed or Child.Name == "FeedClosed" then
                Child.Transparency = 0
            elseif Child.Name == "FeedOpen" then
                Child.Transparency = 1
            end
        end

        if feedConfig.Type == "Box" then
            Weapon:SetAttribute(
                "Capacity", (Weapon:GetAttribute("Capacity") or 0) + 1
            )
        else
            Weapon:SetAttribute("Capacity", capacity)
            Weapon:SetAttribute("FeedGUID", InsertFeed.Name)
            Weapon:SetAttribute("FeedPartFromArmory", InsertFeed:GetAttribute(
                "FromArmory"
            ))
        end

        if config.ChamberOnLoad then
            local chambered = Weapon:GetAttribute("Chambered")
            if not chambered then
                Weapon:SetAttribute(
                    "Capacity", Weapon:GetAttribute("Capacity") - 1
                )
                Weapon:SetAttribute("Chambered", "Live")
            end
        end
        Weapon:SetAttribute("FeedPart", insertFeed)
    end

    Weapon:SetAttribute("InAction", nil)
    Weapon:SetAttribute("Reloading", nil)
end)

---Pull the trigger on en empty weapon
---@param Player Player The Player pulling the trigger
---@param Weapon Tool The weapon of which the trigger is being pulled
TriggerPull.OnServerEvent:Connect(function(Player: Player, Weapon: Tool)
    if not (Weapon:IsA("Tool") and
        (Player.Character and Weapon.Parent == Player.Character)
    ) then
        return warn(
            `{script}.TriggerPull.OnServerEvent: The item {Weapon} is not \z
            currently equipped by {Player}!`
        )
    end

    if Weapon:GetAttribute("InAction") then
        return warn(
            `{script}.TriggerPull.OnServerEvent: The item {Weapon} is \z
            currently in action!`
        )
    end

    local config = FirearmsConfigs[Weapon:GetAttribute("FileName")]
    if not config then
        return warn(
            `{script}.TriggerPull.OnServerEvent: Unknown firearm \z
            {Weapon:GetAttribute("FileName")}!`
        )
    end

    local ClickSound = Util.CreateInstance("Sound", {
        Parent = Weapon.FirePart;
        RollOffMaxDistance = 10;
        SoundId = Sounds.WeaponEmpty;
        Volume = 0.5;
    })
    ClickSound.Ended:Once(function()
        ClickSound:Destroy()
    end)
    ClickSound:Play()

    local firemode = Weapon:GetAttribute("Conversion")
        or config.Firemodes[Weapon:GetAttribute("Firemode") or 1]
    if config.Chambers and firemode == "Double" then
        rotateChambers(Weapon, config)

        local HammerSound = Util.CreateInstance("Sound", {
            Parent = Weapon.FirePart;
            RollOffMaxDistance = 10;
            SoundId = Sounds.RevolverHammer;
            Volume = 0.5;
        })
        HammerSound.Ended:Once(function()
            HammerSound:Destroy()
        end)

        task.wait(0.1)
        HammerSound:Play()
    end
end)

local module = {}

---Creates a local reference to the InventoryHandler module
---@param InvHandler table The InventoryHandler module
module.IHPass = function(InvHandler: table)
    InventoryHandler = InvHandler
end

---Create a new firearm
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.new = function(attributes: table, itemData: table)
    local config = FirearmsConfigs[itemData.Name]
    if not config then
        return warn(`{script}.new: Unknown firearm {itemData.Name}!`)
    end

    local loaded, feedArmory
    if attributes and attributes.Loaded and attributes.FeedArmory then
        feedArmory = attributes.FeedArmory
        loaded = true
        attributes = nil
    end
    attributes = attributes or {
        Firemode = 1;
        SerialNo = Util.Serialize("Firearm");
    }

    if loaded then
        attributes.FeedPart = Util.KeysTable(config.FeedParts)[1]
        attributes.Capacity = config.FeedParts[attributes.FeedPart].Capacity
        attributes.FeedPartFromArmory = feedArmory
    end

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)
    Tool:SetAttribute("HidesMouseIcon", true)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    local FirePart = Tool:FindFirstChild("FirePart")
    if not FirePart then
        return warn(`{script}.new: No FirePart found for {itemData.Name}!`)
    end
    if not config.NoFlash then
        for i, Child in ipairs(MuzzleEffects:GetChildren()) do
            local Effect = Child:Clone()
            Effect:SetAttribute("MuzzleEffect", true)
            if Effect:IsA("ParticleEmitter") then
                Effect.Size = NumberSequence.new(
                    (config.MuzzleVelocity / 300) * (1 - config.BarrelLength), 0
                )
            end
            Effect.Parent = FirePart
        end
    end

    if attributes.FeedPart then
        for i, Child in ipairs(Tool:GetChildren()) do
            if Child.Name == attributes.FeedPart then
                Child.Transparency = 0
            end
        end
    end

    local capacity = attributes.Capacity or 0
    if
        (capacity == 0 and config.OpenActionOnEmpty)
        or (not attributes.FeedPart and config.OpenActionOnReload)
    then
        for i, Child in pairs(Tool:GetChildren()) do
            if Child.Name == "ActionClosed" then
                Child.Transparency = 1
            elseif Child.Name == "ActionOpen" then
                Child.Transparency = 0
            end
        end
    end

    ClientScript:Clone().Parent = Tool

    return Tool
end

---Create a new ammo box
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.NewBox = function(attributes: table, itemData: table)
    local config = BoxConfigs[itemData.Name]
    if not config then
        return warn(`{script}.NewBox: Unknown ammo box {itemData.Name}!`)
    end
    attributes = attributes or {
        Caliber = config.Caliber.Name;
        Capacity = config.Capacity;
    }

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)
    Tool:SetAttribute("AssociatedGui", "AmmoBox")

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    BoxScript:Clone().Parent = Tool

    return Tool
end

---Create a new feed part
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.NewFeed = function(attributes: table, itemData: table): Tool
    local config = FeedConfigs[itemData.Name]
    if not config then
        return warn(`{script}.NewFeed: Unknown feed part {itemData.Name}!`)
    end
    attributes = attributes or {
        Caliber = config.Caliber.Name;
        Capacity = 0;
        MaxCapacity = config.Capacity;
    }

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    FeedScript:Clone().Parent = Tool

    return Tool
end

return module