--Handles all sirens on the server
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local AlertConfig = require(script.Config)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local SendNotification = ReplicatedCommunication.SendNotification

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local sirens = {}

local function setupAlert(Siren: Instance)
    if Siren:FindFirstChild("Siren") then
        table.insert(sirens, {
            Part = Siren.Siren;
            Sound = Util.CreateInstance("Sound", {
                Parent = Siren.Siren;
                RollOffMaxDistance = 500;
                SoundId = AlertConfig.Siren;
                Volume = 1;
            });
        })
    end
end
for i, Siren in ipairs(CollectionService:GetTagged("Siren")) do
    setupAlert(Siren)
end

CollectionService:GetInstanceAddedSignal("Siren"):Connect(setupAlert)

local activeAlert

local function playSirens(sequence: table)
    for i, siren in ipairs(sirens) do
        task.wait(math.random(1, 500) / 100)
        task.spawn(function()
            for j = 1, AlertConfig.Repeats do
                siren.Sound:Play()
                siren.Sound.Ended:Wait()
            end
        end)
    end

    task.wait(10)

    for i, soundId in ipairs(sequence) do
        task.wait(1)

        for j, siren in ipairs(sirens) do
            TweenService:Create(siren.Sound, TweenInfo.new(0.5), {
                Volume = 0.5;
            }):Play()
        end

        local length = 0
        for j, siren in ipairs(sirens) do
            local AlertSound = Util.CreateInstance("Sound", {
                Parent = siren.Part;
                RollOffMaxDistance = 500;
                SoundId = soundId;
                Volume = 3;
            })

            AlertSound:Play()

            if j == #sirens then
                AlertSound.Ended:Wait()
            end
        end

        for j, siren in ipairs(sirens) do
            TweenService:Create(siren.Sound, TweenInfo.new(0.5), {
                Volume = 1;
            }):Play()
        end
    end
end

local module = {}

module.AllClear = function()
    if not activeAlert then
        return warn(`{script}.Declare: There is no active alert!`)
    end

    activeAlert = nil
    task.spawn(playSirens, AlertConfig.AllClear)
end

module.Declare = function(alert: string)
    if activeAlert then
        return warn(
            `{script}.Declare: There is already an active {activeAlert} alert!`
        )
    end

    local config = AlertConfig.Alerts[alert]
    if not config then
        return warn(
            `{script}.Declare: Unknown alert {activeAlert}!`
        )
    end

    activeAlert = alert
    task.spawn(playSirens, config)
end

module.Emergency = function()
    if ReplicatedStorage:GetAttribute("Emergency") then
        return warn(
            `{script}.Emergency: There is already an active state of emergency!`
        )
    end
    ReplicatedStorage:SetAttribute("Emergency", true)

    for i, Player in ipairs(Players:GetPlayers()) do
        if Player:GetAttribute("Occupation") == "Guardsman" then
            SendNotification:FireClient(Player, {
                Title = "State of emergency";
                Text = "A state of emergency has been declared, and the \z
                    national guard has been activated! Report to the barracks \z
                    for further instructions.";
                Duration = 10;
            })
        end
    end

    task.spawn(playSirens, AlertConfig.Emergency)
end

module.EmergencyLift = function()
    if not ReplicatedStorage:GetAttribute("Emergency") then
        return warn(
            `{script}.EmergencyLift: There is no active state of emergency!`
        )
    end
    ReplicatedStorage:SetAttribute("Emergency", false)

    for i, Player in ipairs(Players:GetPlayers()) do
        if Player:GetAttribute("Occupation") == "Guardsman" then
            SendNotification:FireClient(Player, {
                Title = "State of emergency lifted";
                Text = "The state of emergency has been lifted, and the \z
                    national guard is no longer activated. Please return your \z
                    weapons to the armory at the barracks immediately.";
                Duration = 10;
            })
        end
    end

    task.spawn(playSirens, AlertConfig.EmergencyLift)
end

return module