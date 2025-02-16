--This script handles faces on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ScriptStorage.Configuration
local CustomizationConfig = require(ReplicatedConfig.Customization)
local FACES = CustomizationConfig.Faces

local module = {}

---Sets up the face selection page
---@param Pages ScreenGui
---@param DisplayCharacter Model
---@return TextButton
---@return TextButton
module.Setup = function(Pages: ScreenGui, DisplayCharacter: Model)
    local FacePage = Pages:WaitForChild("FacePage")
    local FaceBackground = FacePage:WaitForChild("Background")
    local FaceOptions = FaceBackground:WaitForChild("Faces")
    local LastPage = FaceBackground:WaitForChild("LastPage")
    local NextPage = FaceBackground:WaitForChild("NextPage")

    local FaceTemplate = FaceOptions:WaitForChild("TemplateButton")

    local Head = DisplayCharacter:WaitForChild("Head")
    local Face = Head:WaitForChild("face")

    local lastFace, selectedFace
    
    for i, faceId in ipairs(FACES) do
        local FaceButton = FaceTemplate:Clone()
        FaceButton.Image = `rbxassetid://{faceId}`
        FaceButton.Parent = FaceOptions
        FaceButton.Visible = true

        FaceButton.MouseButton1Click:Connect(function()
            if lastFace then
                lastFace.BorderColor3 = Color3.new(0, 0, 0)
            end
            FaceButton.BorderColor3 = Color3.new(1, 1, 1)
            lastFace = FaceButton

            selectedFace = i

            Face.Texture = `rbxassetid://{faceId}`
        end)
    end
    FaceOptions.CanvasSize = UDim2.fromOffset(
        0,
        (FaceTemplate.AbsoluteSize.Y + 10) * math.ceil(#FACES / 4)
    )

    ---Provides the index of the selected face
    ---@return number
    module.Results = function()
        return selectedFace
    end

    return LastPage, NextPage
end

return module