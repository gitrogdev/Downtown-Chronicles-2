--Handles a box of ammo on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tool = script.Parent

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Inventory = PlayerGui:WaitForChild("Inventory")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local UIStorage = ReplicatedStorage.UserInterface

local ReplicatedCommunication = ReplicatedScripts.Communication
local InitializeBox = ReplicatedCommunication.InitializeBox
local LoadFeed = ReplicatedCommunication.LoadFeed

local AmmoUI = UIStorage.AmmoBox:Clone()

local BoxBackground = AmmoUI:WaitForChild("Background")
local BoxHead = BoxBackground:WaitForChild("Head")
local CapacityDisplay = BoxBackground:WaitForChild("Capacity")
local FeedHolder = BoxBackground:WaitForChild("FeedHolder")

local FeedTemplate = FeedHolder:WaitForChild("FeedTemplate")
local ListLayout = FeedHolder:WaitForChild("UIListLayout")
local NoFeedsDisplay = FeedHolder:WaitForChild("NoFeeds")

local displayUpdates = {}
local FeedDisplays = {}

InitializeBox:FireServer(Tool)

local function updateRounds()
    local capacity = Tool:GetAttribute("Capacity") or 0
    CapacityDisplay.Text =
        `{capacity} round{capacity == 1 and "" or "s"} remaining`
end

BoxHead.Text = Tool:GetAttribute("DisplayName")

Tool.Equipped:Connect(function()
    for i, Child in ipairs(Inventory:GetChildren()) do
        if
            Child:GetAttribute("MaxCapacity")
            and Child:GetAttribute("Caliber") == Tool:GetAttribute("Caliber")
        then
            local FeedDisplay = FeedTemplate:Clone()
            local FeedCapacity = FeedDisplay:WaitForChild("Capacity")
            local FeedHead = FeedDisplay:WaitForChild("Head")
            local FillButton = FeedDisplay:WaitForChild("Fill")
            local LoadButton = FeedDisplay:WaitForChild("Load")

            FeedHead.Text = Child:GetAttribute("DisplayName")
            
            local updateFill = function()
                local capacity = Child:GetAttribute("Capacity") or 0
                local max = Child:GetAttribute("MaxCapacity") or 0
                FeedCapacity.Text =
                    `{capacity}/{max} round{capacity == 1 and "" or "s"}`
            end
            table.insert(
                displayUpdates,
                Child:GetAttributeChangedSignal("Capacity"):Connect(updateFill)
            )
            updateFill()

            FillButton.MouseButton1Click:Connect(function()
                LoadFeed:FireServer(Tool, Child, true)
            end)

            LoadButton.MouseButton1Click:Connect(function()
                LoadFeed:FireServer(Tool, Child)
            end)

            FeedDisplay.Visible = true
            FeedDisplay.Parent = FeedHolder
            table.insert(FeedDisplays, FeedDisplay)
        end
    end

    ListLayout.VerticalAlignment =
        #FeedDisplays == 0 and Enum.VerticalAlignment.Center
        or Enum.VerticalAlignment.Top
    NoFeedsDisplay.Visible = #FeedDisplays == 0

    AmmoUI.Parent = PlayerGui
end)

Tool.Unequipped:Connect(function()
    AmmoUI.Parent = nil

    for i, updateFunc in ipairs(displayUpdates) do
        updateFunc:Disconnect()
    end
    displayUpdates = {}

    for i, FeedDisplay in ipairs(FeedDisplays) do
        FeedDisplay:Destroy()
    end
    FeedDisplays = {}
end)

Tool:GetAttributeChangedSignal("Capacity"):Connect(updateRounds)
updateRounds()