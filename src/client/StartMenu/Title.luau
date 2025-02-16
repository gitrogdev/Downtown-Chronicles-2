--This script handles the game credits
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TipConfig = require(script.Parent.Tips)

local Player = Players.LocalPlayer

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Util = require(ScriptStorage.Util)

local GameMap = workspace:WaitForChild("Map")
local MenuCameras = GameMap:WaitForChild("MenuCameras")

local module = {}

---Displays the title screen on the main menu
---@param StartMenu ScreenGui The main menu
---@param CharacterSelection table The character selection module
---@param Blackout ColorCorrectionEffect The blackout effect used
module.Display = function(
    StartMenu: ScreenGui,
    CharacterSelection: table,
    Blackout: ColorCorrectionEffect
)
    local Background = StartMenu:WaitForChild("TitleScreen")
    local DataLoading = StartMenu:WaitForChild("CharacterData")
    local SelectionBackground = StartMenu:WaitForChild("CharacterSelection")
    local TipDisplay = StartMenu:WaitForChild("GameTip")

    local VersionDisplay = Background:WaitForChild("GameVersion")
    local PlayButton = Background:WaitForChild("PlayButton")

    local clicked
    local pos = 0

    local Cameras = {}
    for i, CameraLocation in ipairs(MenuCameras:GetChildren()) do
        local Start = CameraLocation:WaitForChild("Start")
        local End = CameraLocation:WaitForChild("End")
            
        End:WaitForChild("Back").Transparency = 1
        End.Transparency = 1
        Start:WaitForChild("Back").Transparency = 1
        Start.Transparency = 1

        table.insert(Cameras, {
            Start = Start.CFrame;
            End = End.CFrame;
        })
    end

    local CameraTween
    local function updateCamera(first)
        if clicked or Player.Character then
            return
        end

        pos += 1
        if pos > #Cameras then
            pos = 1
        end

        if not (first == true) then
            TweenService:Create(Blackout, TweenInfo.new(1), {
                Brightness = -1;
            }):Play()
            task.wait(1)
        end

        if clicked or Player.Character then
            return
        end

        workspace.CurrentCamera.CFrame = Cameras[pos].Start

        TweenService:Create(Blackout, TweenInfo.new(1), {
            Brightness = 0;
        }):Play()

        CameraTween = TweenService:Create(
            workspace.CurrentCamera,
            TweenInfo.new(10),
            {
                CFrame = Cameras[pos].End;
            }
        )
        CameraTween.Completed:Connect(updateCamera)

        task.wait(0.5)

        if clicked or Player.Character then
            return
        end

        CameraTween:Play()
    end

    Player.PlayerGui.ChildAdded:Connect(function(Child: Instance)
        if Child.Name == "SelectSpawn" then
            clicked = true
            CameraTween:Cancel()
        end
    end)

    Background.Position = UDim2.fromScale(0, 1)

    local function updateVersion()
        local gameVersion = ReplicatedStorage:GetAttribute("Version")
        VersionDisplay.Text = `Downtown Chronicles 2 {gameVersion}`
    end
    updateVersion()
    ReplicatedStorage:GetAttributeChangedSignal("Version"):Connect(
        updateVersion
    )

    Background.Visible = true

    TweenService:Create(Background, TweenInfo.new(1), {
        Position = UDim2.new();
    }):Play()

    PlayButton.MouseButton1Click:Connect(function()
        if clicked then
            return
        end
        clicked = true
        VersionDisplay.Parent = StartMenu

        TweenService:Create(Background, TweenInfo.new(1), {
            Position = UDim2.fromScale(-1, 0);
        }):Play()

        while not CharacterSelection.Loaded do
            DataLoading.Visible = true
            task.wait()
        end
        DataLoading.Visible = false
        
        SelectionBackground.Visible = true
        CameraTween:Cancel()
        Util.Typewriter(TipConfig.Scroll, TipDisplay)
    end)

    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    updateCamera(true)
end

return module