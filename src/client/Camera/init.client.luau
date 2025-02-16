--Handle camera manipulation on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local Util = require(ReplicatedScripts.Util)

local FaceDirection = ReplicatedCommunication.FaceDirection
local Recoil = ReplicatedCommunication.Recoil
local TracePlayer = ReplicatedCommunication.TracePlayer
local UntracePlayer = ReplicatedCommunication.UntracePlayer
local ViewPlayer = ReplicatedCommunication.ViewPlayer

Player.CharacterAdded:Connect(function(Character: Model)
    local Head: Part = Character:WaitForChild("Head")
    local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
    local Torso: Part = Character:WaitForChild("Torso")

    local RootPart: Part = Humanoid.RootPart

    local Neck: Motor6D = Torso:WaitForChild("Neck")
	local LeftShoulder: Motor6D = Torso:WaitForChild("Left Shoulder")
	local RightShoulder: Motor6D = Torso:WaitForChild("Right Shoulder")

    local zoomed

    local function zoomOut()
        if zoomed then
            zoomed = false
            TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {
                FieldOfView = 70;
            }):Play()
        end
    end

    Humanoid:GetAttributeChangedSignal("LockArms"):Connect(function()
        local armsLocked = Humanoid:GetAttribute("LockArms") or 0
        if armsLocked <= 0 then
            return
        end

        if LeftShoulder then
            LeftShoulder.C1 = Util.DefaultCFrames.LeftShoulderC1
        end
        if RightShoulder then
            RightShoulder.C1 = Util.DefaultCFrames.RightShoulderC1
        end
    end)

    local updateCamera = RunService.RenderStepped:Connect(function()
        if Humanoid.Health > 0 then
            local direction = workspace.CurrentCamera.CFrame.LookVector
            local target = CFrame.Angles(0, 0, math.asin(direction.Y))

            local armsLocked = Humanoid:GetAttribute("LockArms") or 0
            if armsLocked <= 0 then
                if LeftShoulder then
                    LeftShoulder.C1 = Util.DefaultCFrames.LeftShoulderC1
                        * target
                end
                if RightShoulder then
                    RightShoulder.C1 = Util.DefaultCFrames.RightShoulderC1
                        * target:Inverse()
                end
            end
        
            Neck.C0 = Util.DefaultCFrames.NeckC0 * CFrame.Angles(
                math.asin(direction.Y), 0, 0
            ):Inverse()

            if not Humanoid.SeatPart then
                RootPart.CFrame = CFrame.new(
                    RootPart.Position, RootPart.Position + Vector3.new(
                        direction.X, 0, direction.Z
                    )
                )
            end
        end

        Humanoid.CameraOffset = RootPart.CFrame:ToObjectSpace(
            Head.CFrame
        ).Position - Vector3.new(0, 1.5, 0)

        local zoomDistance = (
            Head.Position - workspace.CurrentCamera.CFrame.Position
        ).Magnitude
        if zoomDistance >= 1 then
            zoomOut()
            return
        end

        local Target = Mouse.Target
        if Target then
            local distance = Player:DistanceFromCharacter(Target.Position)
            local Model = Target:FindFirstAncestorOfClass("Model")
            if
                distance < 4 and distance > 0
                and Model and Model:GetAttribute("ZoomIn")
            then
                if not zoomed then
                    zoomed = true
                    TweenService:Create(
                        workspace.CurrentCamera,
                        TweenInfo.new(1),
                        {
                            FieldOfView = 50;
                        }
                    ):Play()
                end
            else
                zoomOut()
            end
        else
            zoomOut()
        end
    end)

    local dead
    Humanoid.Died:Once(function()
        dead = true
        updateCamera:Disconnect()
        workspace.CurrentCamera.FieldOfView = 70
    end)

    if workspace.CurrentCamera.CameraType ~= Enum.CameraType.Custom then
        local ZoomTween = TweenService:Create(
            workspace.CurrentCamera,
            TweenInfo.new(2),
            {
                CFrame = Head.CFrame;
            }
        )

        ZoomTween.Completed:Connect(function()
            workspace.CurrentCamera.CameraSubject = Humanoid
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end)

        ZoomTween:Play()
    end

    task.spawn(function()
        while not dead do
            FaceDirection:FireServer(
                workspace.CurrentCamera.CFrame.LookVector,
                (Humanoid:GetAttribute("LockArms") or 0) > 0
            )
            task.wait(0.1)
        end
    end)
end)

---Begin tracing a Humanoid
---@param Target Humanoid The Humanoid to trace
TracePlayer.OnClientEvent:Connect(function(Target: BillboardGui)
    Target.AlwaysOnTop = true
    Target.Size = UDim2.new(1, 20, 1, 20)

    local Humanoid = Target.Parent.Parent:FindFirstAncestorOfClass("Humanoid")
    if Humanoid then
        Humanoid.Died:Once(function()
            Target.AlwaysOnTop = false
            Target.Size = UDim2.new(1, 0, 1, 0)
        end)
    end
end)

---Apply recoil to the camera
---@param force number The amount of force being exerted
Recoil.OnClientEvent:Connect(function(force: number)
    local Tool = Player.Character
        and Player.Character:FindFirstChildOfClass("Tool")
    local weight = (Tool and Tool:GetAttribute("Weight")) or 1
    Util.Recoil(force, weight, workspace.CurrentCamera, Player)
end)

---Stop tracing a Humanoid
---@param Target Humanoid The Humanoid to stop tracing
UntracePlayer.OnClientEvent:Connect(function(Target: BillboardGui)
    Target.AlwaysOnTop = false
    Target.Size = UDim2.new(1, 0, 1, 0)
end)

---Begin viewing a Humanoid
---@param Target Humanoid The Humanoid to view
ViewPlayer.OnClientEvent:Connect(function(Target: Humanoid)
    workspace.CurrentCamera.CameraSubject = Target
end)