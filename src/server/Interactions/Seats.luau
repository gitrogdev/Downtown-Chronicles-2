--This script handles the server-side portion of seat interactions
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local module = {}

---Sets up a seat prompt
---@param Seat Seat The Seat to create the prompt for
---@return ProximityPrompt
module.Setup = function(Seat: Seat)
    if Seat.Disabled then
        return warn(`{script}.Setup: Seat {Seat:GetFullName()} is disabled!`)
    end
    Seat.Disabled = true

    local SitPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Sit";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 4.5;
        Name = "SeatPrompt";
        Parent = Seat:FindFirstChildWhichIsA("Attachment")
            or Util.CreateInstance("Attachment", {
                CFrame = CFrame.new(0, Seat.Size.Y, 0);
                Name = "PromptAttachment";
                Parent = Seat;
            });
        RequiresLineOfSight = true;
    })

    Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        Seat.Disabled = not Seat.Occupant
        SitPrompt.Enabled = not Seat.Occupant
    end)

    SitPrompt.Triggered:Connect(function(Player:Player)
        if Seat.Occupant then
            return warn(`{script}.Setup.SitPrompt.Triggered: \z
                Seat {Seat:GetFullName()} is already occupied!`
            )
        end

        local Character = Player.Character
        if not Character then
            return warn(`{script}.Setup.SitPrompt.Triggered: \z
                No Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(`{script}.Setup.SitPrompt.Triggered: \z
                No Humanoid found for {Player.Name}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(`{script}.Setup.SitPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        Seat.Disabled = false
        Seat:Sit(Humanoid)
    end)
    return SitPrompt
end

return module