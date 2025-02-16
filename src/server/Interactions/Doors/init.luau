--This script handles the server-side portion of door interactions
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LockTypes = require(script.LockTypes)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local CollisionHandler = require(ServerScripts.Collisions)
local Util = require(ServerScripts.Util)

local ATTACHMENTS = {"InnerAttachment", "OuterAttachment"}

local module = {}

---Sets up a door and the prompt to interact with it
---@param Model Instance
---@return table
module.Setup = function(Model: Instance)
    local Door = {}

    Door.LockType = Model:GetAttribute("LockType") 
    Door.Model = Model
    Door.Open = false

    Door.Body = Model:FindFirstChild("Door")
    if not Door.Body then
        return warn(
            `{script}.Setup: Door {Model:GetFullName()} is missing a body!`
        )
    end

    Door.CloseSound = Sounds[Model:GetAttribute("CloseSound") or "DoorClose"]
    Door.OpenSound = Sounds[Model:GetAttribute("OpenSound") or "DoorOpen"]

    if Model:GetAttribute("Sliding") then
        Door.Bar = Model:FindFirstChild("Bar")
        if not Door.Bar then
            return warn(
                `{script}.Setup: Sliding door {Model:GetFullName()} is \z
                missing a bar!`
            )
        end

        Door.Slider = Door.Bar:FindFirstChildOfClass("PrismaticConstraint")
        if not Door.Slider then
            return warn(
                `{script}.Setup: Sliding door {Model:GetFullName()} is \z
                missing a PrismaticConstraint!`
            )
        end

        Door.Slider.LinearResponsiveness = 200

        Door.Toggle = function(status: boolean)
            if status ~= nil then
                Door.Open = status
            else
                Door.Open = not Door.Open
            end
            Door.Slider.TargetPosition = (Door.Open and Door.Slider.UpperLimit)
                or 0

            local DoorSound = Util.CreateInstance("Sound", {
                Name = "DoorSound";
                Parent = Door.Body;
                RollOffMaxDistance = 100;
                SoundId = Door.Open and Door.OpenSound or Door.CloseSound;
            })
            DoorSound.Ended:Once(function()
                DoorSound:Destroy()
            end)
            DoorSound:Play()
        end
    else
        Door.HingePost = Model:FindFirstChild("HingePost")
        if not Door.HingePost then
            return warn(
                `{script}.Setup: \z
                Door {Model:GetFullName()} is missing a hinge post!`
            )
        end

        Door.Hinge = Door.HingePost:FindFirstChildOfClass("HingeConstraint")
        if not Door.Hinge then
            return warn(
                `{script}.Setup: Door {Model:GetFullName()} is missing a hinge!`
            )
        end

        Door.Direction = (Door.Hinge.UpperAngle == 90 and 1) or -1
        Door.Hinge.AngularResponsiveness = 200
        
        Door.Toggle = function(status: boolean)
            if status ~= nil then
                Door.Open = status
            else
                Door.Open = not Door.Open
            end
            Door.Hinge.TargetAngle = (Door.Open and 90 * Door.Direction) or 0

            local DoorSound = Util.CreateInstance("Sound", {
                Name = "DoorSound";
                Parent = Door.Body;
                RollOffMaxDistance = 100;
                SoundId = Door.Open and Door.OpenSound or Door.CloseSound;
            })
            DoorSound.Ended:Once(function()
                DoorSound:Destroy()
            end)
            DoorSound:Play()
        end
    end

    if not Model:GetAttribute("Gate") then
        local OpenPrompts = {}
        for i = 1, 2 do
            local OpenPrompt = Util.CreateInstance("ProximityPrompt", {
                ActionText = "Open";
                ClickablePrompt = true;
                HoldDuration = 0.5;
                KeyboardKeyCode = Enum.KeyCode.E;
                MaxActivationDistance = 8;
                Parent = Door.Body:FindFirstChild(ATTACHMENTS[i])
                    or Util.CreateInstance("Attachment", {
                        Name = "HandleAttachment";
                        Parent = Door.Body;
                        Position = Vector3.new(0, 0, 0);
                    });
                RequiresLineOfSight = true;
            })

            OpenPrompt.Triggered:Connect(function(Player: Player)
                local Character = Player.Character
                if not Character then
                    return warn(
                        `{script}.Setup.{OpenPrompt}.Triggered: No Character \z
                        found for {Player}!`
                    )
                end

                local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                if not Humanoid then
                    return warn(
                        `{script}.Setup.{OpenPrompt}.Triggered: No Humanoid \z
                        found for {Player}!`
                    )
                end

                if Humanoid.Health <= 0 then
                    return warn(
                        `{script}.Setup.{OpenPrompt}.Triggered: {Player} is \z
                        dead!`
                    )
                end

                if Door.LockType and LockTypes[Door.LockType] 
                    and not LockTypes[Door.LockType](Model, Player)
                then
                    local LockSound = Util.CreateInstance("Sound", {
                        Name = "DoorSound";
                        Parent = Door.Body;
                        RollOffMaxDistance = 100;
                        SoundId = Sounds.DoorLocked;
                    })
                    LockSound.Ended:Connect(function()
                        LockSound:Destroy()
                    end)
                    LockSound:Play()

                    return warn(
                        `{script}.Setup.{OpenPrompt}.Triggered: Door locked \z
                            for {Player}`
                    )
                end

                Door.Toggle()
                for j, Prompt in ipairs(OpenPrompts) do
                    Prompt.ActionText = (Door.Open and "Close") or "Open"
                end
            end)
            table.insert(OpenPrompts, OpenPrompt)

            if OpenPrompt.Name == "HandleAttachment" then
                break
            end
        end
    else
        local closesAt = Model:GetAttribute("ClosesAt") or 24
        local opensAt = Model:GetAttribute("OpensAt") or 0
        if typeof(opensAt) == "string" then
            local GateBind: BindableEvent = Util.CreateInstance("BindableEvent",
                {
                    Name = "ToggleGate";
                    Parent = Model;
                }
            )
            CollectionService:AddTag(GateBind, opensAt)
            GateBind.Event:Connect(function(open: boolean)
                if Door.Open ~= open then
                    Door.Toggle()
                end
            end)
        else
            if
                Lighting.ClockTime > opensAt and Lighting.ClockTime < closesAt
            then
                Door.Toggle()
            end
            Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
                if
                    Lighting.ClockTime > opensAt
                    and Lighting.ClockTime < closesAt
                then
                    if not Door.Open then
                        Door.Toggle()
                    end
                elseif Door.Open then
                    Door.Toggle()
                end
            end)
        end
    end

    if Model:GetAttribute("DefaultOpen") then
        Door.Toggle(true)
    end

    for i, Child in ipairs(Model:GetChildren()) do
        if Child:IsA("BasePart") and not Child.Anchored then
            CollisionHandler.Group(Child, "Doors")
        end
    end
    return Door
end

return module