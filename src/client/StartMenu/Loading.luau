--This script handles the loading screen
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local module = {}

---Waits for all game assets to load, while displaying a loading screen
---@param StartMenu ScreenGui The main menu to display the loading screen on
module.Load = function(StartMenu: ScreenGui)
    local Background = StartMenu:WaitForChild("LoadingScreen")
    local BarHolder = Background:WaitForChild("BarHolder")
    local LogoHolder = Background:WaitForChild("LogoHolder")

    local ProgressBar = BarHolder:WaitForChild("ProgressBar")

    local LogoBackground = LogoHolder:WaitForChild("LogoBackground")
    local BigGear = LogoBackground:WaitForChild("BigGear")
    local SmallGear = LogoBackground:WaitForChild("SmallGear")

    local completed, queueSize = true, 0

    local function rotateGears()
        if completed then
            completed = false
            local BigGearTween = TweenService:Create(BigGear,
                TweenInfo.new(1),
                {
                    Rotation = BigGear.Rotation + 45
                }
            )
            local SmallGearTween = TweenService:Create(SmallGear,
                TweenInfo.new(1),
                {
                    Rotation = SmallGear.Rotation - 45
                }
            )
            BigGearTween.Completed:Connect(function()
                completed = true
            end)

            BigGearTween:Play()
            SmallGearTween:Play()
        end
    end

    Background.Visible = true
    while ContentProvider.RequestQueueSize > 0 or not completed do
        --Prevents progress from jumping around
        if ContentProvider.RequestQueueSize > queueSize then
            queueSize = ContentProvider.RequestQueueSize
        end

        local percentage = 1 - ContentProvider.RequestQueueSize / queueSize
        ProgressBar.Size = UDim2.new(
            percentage, (percentage < 0.5 and 0) or -10,
            1, -10
        )

        rotateGears()

        task.wait()
    end

    task.wait(1)

    TweenService:Create(BarHolder, TweenInfo.new(1), {
        BackgroundTransparency = 1;
    }):Play()
    TweenService:Create(LogoHolder, TweenInfo.new(1), {
        Position = UDim2.fromScale(0, 0);
    }):Play()
    TweenService:Create(LogoHolder, TweenInfo.new(2), {
        Size = UDim2.fromScale(1, 0.175);
    }):Play()
    TweenService:Create(ProgressBar, TweenInfo.new(1), {
        BackgroundTransparency = 1;
    }):Play()

    LogoBackground.MouseEnter:Connect(rotateGears)

    task.wait(1.5)
end

return module