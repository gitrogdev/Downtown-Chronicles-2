--This script handles hairs and facial hairs on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Util = require(ScriptStorage.Util)

local PartStorage = ReplicatedStorage.Parts
local DisplayTemplate = PartStorage.HairDisplay
local FacialStorage = PartStorage.FacialHair
local HairStorage = PartStorage.Hair

local HAIRS = HairStorage:GetChildren()
local FACIAL_HAIRS = FacialStorage:GetChildren()

local FacialStyles, FemaleWarning

local module = {}

module.FacialHairButtons = {}
module.HairPreviews = {}

---Sets up the hair style page
---@param Pages Frame The Frame in the GUI containing the pages
---@param DisplayCharacter Model The character displayed in customization
---@return TextButton
---@return TextButton
module.Setup = function(Pages: ScreenGui, DisplayCharacter: Model)
    local HairPage = Pages:WaitForChild("HairPage")
    local HairBackground = HairPage:WaitForChild("Background")
    FacialStyles = HairBackground:WaitForChild("FacialStyles")
    FemaleWarning = HairBackground:WaitForChild("Female")
    local HairyStyles = HairBackground:WaitForChild("HairyStyles")
    local LastPage = HairBackground:WaitForChild("LastPage")
    local NextPage = HairBackground:WaitForChild("NextPage")
    local SelectedFacial = HairBackground:WaitForChild("SelectedFacial")
    local SelectedHair = HairBackground:WaitForChild("SelectedHair")

    local FacialTemplate = FacialStyles:WaitForChild("TemplateButton")

    local HairTemplate = HairyStyles:WaitForChild("TemplateButton")

    local cachedFacial
    local lastFacial, LastFacial, lastHair, LastHair
    local selectedFacial, selectedHair
    
    local function setupHair(facial: boolean, Hair: Accoutrement)
        local HairButton = ((facial and FacialTemplate) or HairTemplate):Clone()
        local Viewport = HairButton:WaitForChild("ViewportFrame")
        local WorldModel = Viewport:WaitForChild("WorldModel")

        local HairDisplay = DisplayTemplate:Clone()
        HairDisplay.Parent = WorldModel
        
        if Hair then
            Hair = Hair:Clone()
            Util.AddAccoutrement(HairDisplay, Hair)
            Util.ColorHair(Hair, Color3.fromRGB(151,121,097))
            table.insert(module.HairPreviews, Hair)
        end

        Viewport.CurrentCamera = Util.CreateInstance("Camera", {
            CFrame = HairDisplay:WaitForChild("CameraPart").CFrame;
            Parent = Viewport;
        })

        if facial then
            table.insert(module.FacialHairButtons, HairButton)
        end

        HairButton.Parent = (facial and FacialStyles) or HairyStyles
        HairButton.Visible = true

        HairButton.MouseButton1Click:Connect(function()
            if (facial and lastFacial) then
                lastFacial.BorderColor3 = Color3.new(0, 0, 0)
            elseif (not facial and lastHair) then
                lastHair.BorderColor3 = Color3.new(0, 0, 0)
            end
            HairButton.BorderColor3 = Color3.new(1, 1, 1)

            if facial then
                lastFacial = HairButton
                selectedFacial = (Hair and Hair.Name)
                SelectedFacial.Text = selectedFacial or "Clean Shaven"

                if LastFacial then
                    LastFacial:Destroy()
                end

                if Hair then
                    LastFacial = Hair:Clone()
                    LastFacial.Parent = DisplayCharacter
                    Util.AddAccoutrement(DisplayCharacter, LastFacial)
                end
            else
                lastHair = HairButton
                selectedHair = (Hair and Hair.Name)
                SelectedHair.Text = selectedHair or "Bald"

                if LastHair then
                    LastHair:Destroy()
                end

                if Hair then
                    LastHair = Hair:Clone()
                    LastHair.Parent = DisplayCharacter
                    Util.AddAccoutrement(DisplayCharacter, LastHair)
                end
            end
        end)
    end

    setupHair(true)
    for i, Facial in ipairs(FACIAL_HAIRS) do
        setupHair(true, Facial)
    end
    FacialStyles.CanvasSize = UDim2.fromOffset(
        0,
        (FacialTemplate.AbsoluteSize.Y + 10) * math.ceil((#FACIAL_HAIRS + 1) / 4)
    )

    setupHair()
    for i, Hair in ipairs(HAIRS) do
        setupHair(false, Hair)
    end
    HairyStyles.CanvasSize = UDim2.fromOffset(
        0,
        (HairTemplate.AbsoluteSize.Y + 10) * math.ceil((#HAIRS + 1) / 4)
    )

    FemaleWarning:GetPropertyChangedSignal("Visible"):Connect(function()
        if FemaleWarning.Visible and selectedFacial then
            cachedFacial = selectedFacial
            selectedFacial = nil
        elseif not FemaleWarning.Visible and cachedFacial then
            selectedFacial = cachedFacial
            cachedFacial = nil
        end

        if LastFacial then
            LastFacial.Parent = (FemaleWarning.Visible and HairPage)
                or DisplayCharacter
        end
    end)

    ---Provides the names of the selected hair and facial hair
    ---@return string
    ---@return string
    module.Results = function()
        return selectedHair, selectedFacial
    end

    return LastPage, NextPage
end

---Updates the display color of the selected hair and facial hair
---@param color Color3 The hair color
module.UpdateColor = function(color: Color3)
    for i, Hair in ipairs(module.HairPreviews) do
        Util.ColorHair(Hair, color)
    end
end

---Updates the character's gender, disabling facial hairs for female characters
---@param gender boolean The character's gender (male = false, female = true)
module.UpdateGender = function(gender: boolean)
    FacialStyles.ScrollingEnabled = not gender
    FemaleWarning.Visible = gender
    for i, Button in ipairs(module.FacialHairButtons) do
        Button.Visible = not gender
    end
end

return module