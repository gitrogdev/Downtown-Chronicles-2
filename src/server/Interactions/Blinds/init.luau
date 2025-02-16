---Handles all interactions with blinds on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local SoundIds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local module = {}

module.new = function(Model: Model): table
    local Blinds: table = {}
    Blinds.Parent = Model
    Blinds.Down = Model:FindFirstChild("Down")
    if not Blinds.Down then
        return warn(
            `{script}.new: No down model found for the blinds \z
            {Model:GetFullName()}!`
        )
    end

    Blinds.Up = Model:FindFirstChild("Up")
    if not Blinds.Up then
        return warn(
            `{script}.new: No up model found for the blinds \z
            {Model:GetFullName()}!`
        )
    end

    Blinds.DownHandle = Blinds.Down:FindFirstChild("Handle")
    if not Blinds.DownHandle then
        return warn(
            `{script}.new: No down handle found for the blinds \z
            {Model:GetFullName()}!`
        )
    end

    Blinds.UpHandle = Blinds.Up:FindFirstChild("Handle")
    if not Blinds.UpHandle then
        return warn(
            `{script}.new: No up handle found for the blinds \z
            {Model:GetFullName()}!`
        )
    end

    local DownAttachment: Attachment = Util.CreateInstance("Attachment", {
        CFrame = CFrame.new(0, 0, -0.25);
        Name = "DownAttachment";
        Parent = Blinds.DownHandle;
    })

    local UpAttachment: Attachment = Util.CreateInstance("Attachment", {
        CFrame = CFrame.new(0, 0, -0.25);
        Name = "UpAttachment";
        Parent = Blinds.UpHandle;
    })

    local PullPrompt: ProximityPrompt = Util.CreateInstance("ProximityPrompt", {
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        Name = "PullPrompt";
        MaxActivationDistance = 8;
        RequiresLineOfSight = true;
    })

    local function changeState(state: boolean)
        if state == nil then
            state = not Blinds.State
        end

        Blinds.Down.Parent = state == true and Blinds.Parent or nil
        Blinds.Up.Parent = state == false and Blinds.Parent or nil

        PullPrompt.ActionText = `{state and "Open" or "Close"} blinds`
        PullPrompt.Parent = state and DownAttachment or UpAttachment

        local ToggleSound: Sound = Util.CreateInstance("Sound", {
            Name = "BlindsSound";
            Parent = state == true and Blinds.DownHandle or Blinds.UpHandle;
            RollOffMaxDistance = 30;
            SoundId = SoundIds.BlindsToggle;
        })
        ToggleSound.Ended:Once(function()
            ToggleSound:Destroy()
        end)
        ToggleSound:Play()

        Blinds.State = state
    end

    PullPrompt.Triggered:Connect(function(Player: Player)
        local Character: Model = Player.Character
        if not Character then
            return warn(
                `{script}.{Model:GetFullName()}.PullPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Model:GetFullName()}.PullPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Model:GetFullName()}.PullPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        changeState()
    end)
    changeState(true)
    return Blinds
end

return module