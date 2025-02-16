--This script handles the game credits
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Contributors = require(script.Contributors)

local module = {}

---Displays the credits screen on the main menu
---@param StartMenu ScreenGui The main menu
module.Display = function(StartMenu: ScreenGui)
    if RunService:IsStudio() then
        return
    end

    local Background = StartMenu:WaitForChild("CreditsScreen")
    local ContributorFrame = Background:WaitForChild("Contributors")
    local DeveloperFrame = Background:WaitForChild("Developers")

    local text = {}
    local function prepareTween(Label: TextLabel)
        Label.TextStrokeTransparency = 1
        Label.TextTransparency = 1
        table.insert(text, Label)
    end

    local function populate(Display: Frame, source: table)
        local DisplayHead = Display:WaitForChild("Head")
        local MemberHolder = Display:WaitForChild("Members")

        local MemberTemplate = MemberHolder:WaitForChild("MemberTemplate")

        prepareTween(DisplayHead)

        for i, contributorInfo in ipairs(source) do
            local CreditDisplay = MemberTemplate:Clone()
            local RoleDisplay = CreditDisplay:WaitForChild("Role")
            local UsernameDisplay = CreditDisplay:WaitForChild("Username")

            prepareTween(UsernameDisplay)
            prepareTween(RoleDisplay)

            local success, response = pcall(
                Players.GetNameFromUserIdAsync,
                Players,
                contributorInfo.UserId
            )
            
            if success then
                UsernameDisplay.Text = response
            end
            RoleDisplay.Text = contributorInfo.Role

            CreditDisplay.Visible = true
            CreditDisplay.Parent = MemberHolder
        end
    end

    populate(ContributorFrame, Contributors.Contributors)
    populate(DeveloperFrame, Contributors.Developers)
    Background.Visible = true

    for i, Label in ipairs(text) do
        TweenService:Create(Label, TweenInfo.new(1), {
            TextStrokeTransparency = 0;
            TextTransparency = 0;
        }):Play()
    end

    task.wait(6)

    for i, Label in ipairs(text) do
        TweenService:Create(Label, TweenInfo.new(1), {
            TextStrokeTransparency = 1;
            TextTransparency = 1;
        }):Play()
    end
end

return module