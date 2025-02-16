--Handles the police terminal on the client
local Players = game:GetService("Players")

local MainGui: ScreenGui = script.Parent
local Background: Frame = MainGui:WaitForChild("Background")
local CloseTerminal: RemoteEvent = MainGui:WaitForChild("CloseTerminal")

local CloseButton: TextButton = Background:WaitForChild("CloseButton")
local Footer: TextLabel = Background:WaitForChild("Footer")

local Player = Players.LocalPlayer

local Terminal = {}

Terminal.MainGui = MainGui
Terminal.User = Player

for i, Submodule: Instance in ipairs(script:GetChildren()) do
    if not Submodule:IsA("ModuleScript") then
        continue
    end

    for key, func in pairs(require(Submodule)) do
        Terminal[key] = func
    end
end

---Show a given page in the GUI
---@param page string The page to show
---@return Frame
function Terminal:ShowPage(page: string)
    local Page: Frame
    for i, Child in ipairs(Background:GetChildren()) do
        if Child:IsA("Frame") then
            Child.Visible = Child.Name == page
            if Child.Name == page then
                Page = Child
            end
        end
    end
    return Page
end

CloseButton.MouseButton1Click:Once(function()
    CloseTerminal:FireServer()
end)
Footer.Text = `Currently signed in as {Player:GetAttribute("FullName")}. \z
    Not you? <u><font color="#0070E0">Sign out</font></u>`
Terminal:SearchPage()