--Handles spawn selection on the client
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local UIStorage = ReplicatedStorage.UserInterface

local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration
local Util = require(ReplicatedScripts.Util)

local LoadCharacter = ReplicatedCommunication.LoadCharacter

local SpawnLocations = require(ReplicatedConfig.Spawns)

local SpawnGui = UIStorage.SpawnPoint

local Camera = workspace.CurrentCamera

local setup = {}
local SpawnGuis = {}

for i, Spawn in ipairs(CollectionService:GetTagged("Spawn")) do
    local spawnType = Spawn:GetAttribute("SpawnType")
    if not spawnType then
        warn(`{script}: Spawn type not found for spawn {Spawn:GetFullName()}!`)
        continue
    end

    local spawnConfig = SpawnLocations[spawnType]
    if not spawnConfig then
        warn(
            `{script}: Unknown spawn type "{spawnType}" for spawn \z
            {Spawn:GetFullName()}!`
        )
        continue
    end

    if not spawnConfig.Check(Player, Spawn) then
        continue
    end

    local spawnName = Spawn:GetAttribute("SpawnName") or "Spawn location"
    if setup[spawnName] then
        table.insert(setup[spawnName], Spawn)
        warn(
            `{script}: Spawn with name "{spawnName}" already set up, skipping \z
            GUI creation for {Spawn:GetFullName()}!`
        )
        continue
    end

    local SpawnDisplay = SpawnGui:Clone()
    local Background = SpawnDisplay:WaitForChild("Frame")
    local Body = Background:WaitForChild("Body")
    local Head = Background:WaitForChild("Head")
    local SpawnButton = Background:WaitForChild("Spawn")

    Head.Text = spawnName
    Body.Text = spawnConfig.Display

    SpawnButton.MouseButton1Click:Once(function()
        for j, RemoveSpawn in ipairs(SpawnGuis) do
            RemoveSpawn:Destroy()
        end

        LoadCharacter:FireServer(Util.RandomFrom(setup[spawnName]))
    end)

    local rotating
    SpawnButton.MouseEnter:Connect(function()
        rotating = true
        while rotating do
            SpawnButton.Rotation += 1
            task.wait()
        end
    end)

    SpawnButton.MouseLeave:Connect(function()
        rotating = false
    end)

    table.insert(SpawnGuis, SpawnDisplay)
    setup[spawnName] = {Spawn}

    SpawnDisplay.Adornee = Spawn:FindFirstChildOfClass("Attachment") or Spawn
    SpawnDisplay.Parent = Player.PlayerGui
end

for i, ShowSpawn in ipairs(SpawnGuis) do
    ShowSpawn.Enabled = true
end

Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = CFrame.new(
    (Util.Boundaries.Min.X + Util.Boundaries.Max.X) / 2,
    Util.Boundaries.Max.X - Util.Boundaries.Min.X,
    (Util.Boundaries.Min.Z + Util.Boundaries.Max.Z) / 2
) * CFrame.Angles(math.rad(-90), 0, 0)

local BlackoutEffect = Lighting:FindFirstChild("Blackout")
if BlackoutEffect then
    BlackoutEffect.Brightness = 0
end

local DeathScreen = Player.PlayerGui:FindFirstChild("DeathScreen")
if DeathScreen then
    DeathScreen:Destroy()
end

local HealthEffect = Lighting:FindFirstChild("HealthEffect")
if HealthEffect then
    HealthEffect.Brightness = 0
    HealthEffect.Saturation = 0
end

UserInputService.MouseIconEnabled = true