--Handles bullet physics and firing mechanisms on the client
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local Util = require(ReplicatedScripts.Util)

local FireBullet = ReplicatedCommunication.FireBullet
local TriggerPull = ReplicatedCommunication.TriggerPull

---For studio use only, creates a part in the workspace to trace a bullet path
---@param color BrickColor The color of the part
---@param position Vector3 The position of the part
---@return Part
local function tracePart(color: BrickColor, position: Vector3)
    if not ReplicatedStorage:GetAttribute("TracePaths") then
        return
    end

    return Util.CreateInstance("Part", {
        Anchored = true;
        BrickColor = color;
        CanCollide = false;
        CanQuery = false;
        Massless = true;
        Material = Enum.Material.Neon;
        Parent = workspace;
        Position = position;
        Size = Vector3.new(0.25,0.25,0.25);
    })
end

local module = {}

---Fire a bullet
---@param config table The configuration file for the firearm in use
---@param Weapon Instance The Tool being fired
---@param Humanoid Humanoid The Humanoid to get the TargetPoint from (optional)
---@return boolean
module.Fire = function(
    config: table,
    Weapon: Instance,
    Humanoid: Humanoid
)
    local feedPart = Weapon:GetAttribute("FeedPart")
    local feedConfig = config.FeedParts[feedPart]
    if not feedConfig then
        return warn(`{script}.Fire: No feed part found! ({feedPart})`)
    end

    local chambered = Weapon:GetAttribute("Chambered")
    if chambered ~= "Live" then
        TriggerPull:FireServer(Weapon)
        return warn(
            `{script}.Fire: Weapon empty ({chambered} round in chamber!)`
        )
    end

    local RightArm: Part = Humanoid.Parent:FindFirstChild("Right Arm")
    if not RightArm then
        return warn(
            `{script}.Fire: No right arm found!`
        )
    end

    local RightGrip: Attachment =
        RightArm:FindFirstChild("RightGripAttachment")
    if not RightGrip then
        return warn(
            `{script}.Fire: No right grip found!`
        )
    end

    local FirePart: Part = Weapon:FindFirstChild("FirePart")
    
    local ObstructionParams: RaycastParams = RaycastParams.new()
    ObstructionParams.FilterDescendantsInstances = {
        workspace.Map;
    }
    ObstructionParams.FilterType = Enum.RaycastFilterType.Include
    ObstructionParams.IgnoreWater = true
    
    local Obstructions: RaycastResult = workspace:Raycast(
        RightGrip.WorldCFrame.Position,
        (FirePart.CFrame.Position - RightGrip.WorldCFrame.Position).Unit
        * ((FirePart.CFrame.Position - RightGrip.WorldCFrame.Position).Magnitude
        - FirePart.Size.X),
        ObstructionParams
    )
    if Obstructions then
        return warn(
            `{script}.Fire: Obstruction found between shoulder and muzzle, \z
            not firing! (Obstruction: {Obstructions.Instance})`
        )
    end

    local direction = FirePart.CFrame.RightVector.Unit

    local ignoreList = {}
    table.insert(ignoreList, Weapon)
    for i, Child in ipairs(Humanoid.Parent:GetChildren()) do
        if Child:IsA("BasePart") and Child.Name ~= "HeadUnion" then
            table.insert(ignoreList, Child)
        end
    end

    for i, Part in ipairs(CollectionService:GetTagged("DontShoot")) do
        table.insert(ignoreList, Part)
    end

    FireBullet:FireServer(
        Weapon,
        module.Path(
            config, feedConfig, FirePart.CFrame.Position, direction, ignoreList
        )
    )

    task.spawn(
        Util.Recoil,
        Util.MuzzleForce(
            feedConfig.Caliber.Mass,
            config.MuzzleVelocity,
            feedConfig.Caliber.Count
        ),
        Weapon:GetAttribute("Weight") or 1,
        workspace.CurrentCamera,
        Player
    )

    return true
end

---Calculate the path of a bullet
---@param config table The configuration file for the firearm in use
---@param feedConfig table The configuration file for the feed part in use
---@param originalOrigin Vector3 The origin point of the bullet
---@param originalDirection Vector3 The direction vector of the bullet
---@param ignoreList table Instances for the path of the bullet to ignore
---@return table
module.Path = function(
    config: table,
    feedConfig: table,
    originalOrigin: Vector3,
    originalDirection: Vector3,
    ignoreList: table
)
    local velocity = config.MuzzleVelocity

    ignoreList = ignoreList or {}
    local paths = {}
    local origins = {}
    for i = 1, feedConfig.Caliber.Count or 1 do
        local spread = CFrame.Angles(
            math.rad(.5 * (math.random() * 2 - 1)),
            math.rad(.5 * (math.random() * 2 - 1)),
            math.rad(.5 * (math.random() * 2 - 1))
        )

        local CastParams = RaycastParams.new()
        CastParams.FilterType = Enum.RaycastFilterType.Exclude
        CastParams.FilterDescendantsInstances = ignoreList
        CastParams.IgnoreWater = false

        local originPack = {
            Direction = originalDirection;
            Origin = originalOrigin;
            Spread = spread;
        }
        local direction = originalDirection
        local origin = originalOrigin

        local path = {}
        repeat
            local stepDirection = spread * direction
                * (Util.MetersToStuds(velocity) / 10)
            CastParams.FilterDescendantsInstances = ignoreList
            local Hit = workspace:Raycast(origin, stepDirection, CastParams)
            if Hit then
                tracePart(BrickColor.new("Really blue"), Hit.Position)

                table.insert(path, {
                    Position = Hit.Position;
                    Instance = Hit.Instance;
                    Surface = Hit.Normal;
                    WasAt = Hit.Instance.CFrame:Inverse();
                    Velocity = velocity;
                })

                table.insert(
                    CastParams.FilterDescendantsInstances, Hit.Instance
                )

                local ExitParams = RaycastParams.new()
                ExitParams.FilterDescendantsInstances = {Hit.Instance}
                ExitParams.FilterType = Enum.RaycastFilterType.Include
                local ExitHit = workspace:Raycast(
                    Hit.Position + stepDirection, -stepDirection, ExitParams
                )
                if ExitHit then
                    local thickness =
                        (Hit.Position - ExitHit.Position).Magnitude
                    local stoppingDistance = Util.StoppingDistance(
                        feedConfig.Caliber.Diameter / 1000,
                        0.5,
                        feedConfig.Caliber.Mass / 1000,
                        velocity,
                        Util.MaterialDensities[
                            Hit.Instance.Parent
                            and Hit.Instance.Parent:FindFirstChildOfClass(
                                "Humanoid"
                            ) and "Humanoid"
                            or tostring(Hit.Instance.Material)
                        ]
                    )

                    if thickness > stoppingDistance then
                        break
                    else
                        path[#path].ExitPosition = ExitHit.Position
                        path[#path].ExitInstance = ExitHit.Instance

                        origin = Hit.Position
                        table.insert(ignoreList, Hit.Instance)
                        velocity -= velocity * (thickness / stoppingDistance)

                        tracePart(
                            BrickColor.new("Really red"), ExitHit.Position
                        )
                    end
                else
                    warn(
                        `{script}.Path: No exit point found for {Hit.Instance}!`
                    )
                    break
                end
            else
                origin += stepDirection

                table.insert(path, {
                    Position = origin;
                    Velocity = velocity;
                })
                
                tracePart(BrickColor.new("Lime green"), origin)
            end
            direction -= Vector3.new(0, .032 , 0)
        until velocity < 40 or origin.Y < workspace.FallenPartsDestroyHeight
        table.insert(paths, path)
        table.insert(origins, originPack)
    end
    return paths, origins
end

return module