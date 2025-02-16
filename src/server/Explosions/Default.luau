--Handles the creation of explosions with "default" behavior
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local SoundIds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local BreakageHandler = require(ServerScripts.Breakage)
local DeathHandler = require(ServerScripts.Deaths)
local Util = require(ServerScripts.Util)

local module = {}

module.Default = {
    ExplosionProperties = {
        BlastPressure = 500000;
        BlastRadius = 4;
        DestroyJointRadiusPercent = 0;
        ExplosionType = Enum.ExplosionType.NoCraters;
    };
    Hit = function(properties: table, Part: BasePart, distance: number)
        local damage = properties.MaxDamage * (1 - (
            (distance - (
                properties.MinDropoffPercent
                * properties.ExplosionProperties.BlastRadius
            )) / (properties.ExplosionProperties.BlastRadius - (
                properties.MinDropoffPercent
                * properties.ExplosionProperties.BlastRadius
            ))
        ))
        local position = Part.Position

        local Humanoid = Part.Parent:FindFirstChildWhichIsA("Humanoid")
        if Humanoid and not Humanoid:GetAttribute("NoDamage") then
            if damage > properties.MaxDamage then
                damage = properties.MaxDamage
            end

            print(
                `{script}.Explosion.Hit: Hit {Part:GetFullName()} for \z
                {Util.Round(damage, 2)} damage!`
            )

            if
                Part ~= Humanoid.RootPart
                and damage == properties.MaxDamage
                and (
                    properties.ExplosionProperties.BlastRadius
                    * properties.MaxDamage
                ) >= Part.Size.Magnitude
            then
                print(
                    `{script}.Explosion.Hit: Destroying {Part:GetFullName()} \z
                    with {properties.Source}!`
                )

                local PinkMist = Util.CreateInstance("Smoke", {
                    Color = Color3.fromRGB(255,100,100);
                    Opacity = 0.05;
                    Parent = Util.CreateInstance("Part", {
                        Anchored = true;
                        CanCollide = false;
                        CanQuery = false;
                        Massless = true;
                        Parent = workspace;
                        Position = position;
                        Size = Vector3.new(1, 1, 1);
                        Transparency = 1;
                    });
                    RiseVelocity = 0.3;
                    Size = Part.Size.Magnitude;
                })

                Part:Destroy()
                DeathHandler.Splatter(
                    Humanoid,
                    Part.Size.Magnitude
                        * properties.ExplosionProperties.BlastRadius,
                    position
                )

                local MistTween = TweenService:Create(
                    PinkMist,
                    TweenInfo.new(PinkMist.Size * 3),
                    {
                        Opacity = 0;
                    }
                )

                MistTween.Completed:Once(function()
                    PinkMist.Enabled = false
                    task.wait(5)
                    PinkMist.Parent:Destroy()
                end)
                
                MistTween:Play()
            elseif Humanoid.Health > 0 then
                DeathHandler.Splatter(Humanoid, damage, position)
            end

            DeathHandler.TakeDamage(Humanoid, damage, properties.Source)
        end

        if Part:GetAttribute("Breakable") then
            BreakageHandler.Damage(Part, damage * 5)
        end
    end;
    MaxDamage = 10; --Per part
    MinDropoffPercent = 0.2;
    Parent = workspace;
    Source = "Explosion";
}

---Creates an explosion with "default" behavior
---@param position Vector3 The position to create the explosion at
---@param properties table The properties to apply to the explosion
---@return Explosion
module.new = function(position: Vector3, properties: table)
    local Explosion = Util.CreateInstance(
        "Explosion",
        properties.ExplosionProperties
    )

    Explosion.Hit:Connect(function(Part: BasePart, distance: number)
        properties.Hit(properties, Part, distance)
    end)

    Explosion.Position = position
    Explosion.Parent = properties.Parent

    local EffectPart = Util.CreateInstance("Part", {
        Anchored = true;
        CanCollide = false;
        CanQuery = false;
        Massless = true;
        Parent = workspace;
        Position = Explosion.Position;
        Size = Vector3.new(1, 1, 1);
        Transparency = 1;
    })

    local ExplosionSound = Util.CreateInstance("Sound", {
        Parent = EffectPart;
		RollOffMaxDistance = properties.ExplosionProperties.BlastRadius * 5;
        RollOffMinDistance = properties.ExplosionProperties.BlastRadius;
		SoundId = SoundIds.Explosion;
		Volume = 1;
    })

    local ExplosionSoundFar = Util.CreateInstance("Sound", {
        Parent = EffectPart;
        RollOffMaxDistance = properties.ExplosionProperties.BlastRadius * 15;
		RollOffMinDistance = properties.ExplosionProperties.BlastRadius;
		SoundId = SoundIds.ExplosionFar;
		Volume = 0.75;
    })

    local BlastLight = Util.CreateInstance("PointLight", {
        Brightness = 5;
	    Color = Color3.fromRGB(255, 183, 14);
        Parent = EffectPart;
	    Range = 0;
    })

    local LightTween = TweenService:Create(BlastLight, TweenInfo.new(0.2), {
        Range = properties.ExplosionProperties.BlastRadius
    })

    LightTween.Completed:Once(function()
		LightTween = TweenService:Create(BlastLight, TweenInfo.new(0.2), {
            Range = 0
        })

        LightTween.Completed:Once(function()
            while ExplosionSound.IsPlaying or ExplosionSoundFar.IsPlaying do
                task.wait()
            end
            EffectPart:Destroy()
        end)

        LightTween:Play()
	end)

    ExplosionSound:Play()
    ExplosionSoundFar:Play()
    LightTween:Play()

    return Explosion
end

return module