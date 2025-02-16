--This script handles ethnicity, hair color, and skin tones on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ScriptStorage.Configuration
local Util = require(ScriptStorage.Util)

local CustomizationConfig = require(ReplicatedConfig.Customization)
local HAIR_COLORS = CustomizationConfig.Colors.Hair
local SKIN_COLORS = CustomizationConfig.Colors.Skin

local module = {}

---Sets up the character coloring page
---@param Pages ScreenGui
---@param DisplayCharacter Model
---@param PageHandlers table
---@return TextButton
---@return TextButton
module.Setup = function(
    Pages: ScreenGui,
    DisplayCharacter: Model,
    PageHandlers: table
)
    local ShadingPage = Pages:WaitForChild("ShadingPage")
    local EthnicBackground = ShadingPage:WaitForChild("Background")
    local Ethnicities = EthnicBackground:WaitForChild("Ethnicities")
    local EthnicityDisplay = EthnicBackground:WaitForChild("SelectedEthnicity")
    local HairColors = EthnicBackground:WaitForChild("HairColors")
    local LastPage = EthnicBackground:WaitForChild("LastPage")
    local NextPage = EthnicBackground:WaitForChild("NextPage")
    local SkinTones = EthnicBackground:WaitForChild("SkinTones")

    local EthnicityTemplate = Ethnicities:WaitForChild("TemplateButton")
    local EthnicitySearch = Ethnicities:WaitForChild("SearchBox")

    local HairTemplate = HairColors:WaitForChild("TemplateButton")

    local SkinTemplate = SkinTones:WaitForChild("TemplateButton")

    local lastSkin, lastHair
    local selectedEthnicity, selectedHair, selectedSkin
    local EthnicityButtons, HairButtons, SkinButtons = {}, {}, {}

    for i, ethnicity in ipairs(CustomizationConfig.Ethnicities) do
        local EthnicityButton = EthnicityTemplate:Clone()
        EthnicityButton.Name = ethnicity
        EthnicityButton.Text = ethnicity
        EthnicityButton.Parent = Ethnicities
        EthnicityButton.Visible = true

        EthnicityButton.MouseButton1Click:Connect(function()
            EthnicityDisplay.Text = ethnicity
            selectedEthnicity = i

            local default = CustomizationConfig.Colors.EthnicDefaults[ethnicity]
            if default then
                if lastHair then
                    lastHair.BorderColor3 = Color3.new(0, 0, 0)
                end
                local HairButton = HairButtons[default.Hair]
                HairButton.BorderColor3 = Color3.new(1, 1, 1)
                lastHair = HairButton
    
                PageHandlers.Hairs.UpdateColor(HAIR_COLORS[default.Hair])
                selectedHair = default.Hair
    
                for j, Child in ipairs(DisplayCharacter:GetChildren()) do
                    if Child:IsA("Accoutrement") then
                        Util.ColorHair(Child, HAIR_COLORS[default.Hair])
                    end
                end

                if lastSkin then
                    lastSkin.BorderColor3 = Color3.new(0, 0, 0)
                end
                local SkinButton = SkinButtons[default.Skin]
                SkinButton.BorderColor3 = Color3.new(1, 1, 1)
                lastSkin = SkinButton
    
                selectedSkin = default.Skin
    
                for j, Child in ipairs(DisplayCharacter:GetChildren()) do
                    if Child:IsA("BasePart") then
                        Child.Color = SKIN_COLORS[default.Skin]
                    end
                end
            end
        end)

        table.insert(EthnicityButtons, EthnicityButton)
    end
    Ethnicities.CanvasSize = UDim2.fromOffset(
        0,
        EthnicityTemplate.Size.Y.Offset * (#CustomizationConfig.Ethnicities + 1)
    )

    EthnicitySearch.Name = "AAASearch"
    local function updateEthnicities()
        local searchTerm = EthnicitySearch.Text:lower()
        local visible = 1
        if searchTerm == "" then
            for i, Button in ipairs(EthnicityButtons) do
                Button.Visible = true
                visible += 1
            end
        else
            for i, Button in ipairs(EthnicityButtons) do
                if Button.Text:lower():sub(1, #searchTerm) == searchTerm then
                    Button.Visible = true
                    visible += 1
                else
                    Button.Visible = false
                end
            end
        end

        Ethnicities.CanvasSize = UDim2.fromOffset(
            0,
            EthnicityTemplate.Size.Y.Offset * (visible)
        )
    end
    EthnicitySearch.Changed:Connect(updateEthnicities)

    for i, hairColor in ipairs(HAIR_COLORS) do
        local ColorButton = HairTemplate:Clone()
        ColorButton.BackgroundColor3 = hairColor
        ColorButton.Parent = HairColors
        ColorButton.Visible = true
        table.insert(HairButtons, ColorButton)

        ColorButton.MouseButton1Click:Connect(function()
            if lastHair then
                lastHair.BorderColor3 = Color3.new(0, 0, 0)
            end
            ColorButton.BorderColor3 = Color3.new(1, 1, 1)
            lastHair = ColorButton

            PageHandlers.Hairs.UpdateColor(hairColor)
            selectedHair = i

            for j, Child in ipairs(DisplayCharacter:GetChildren()) do
                if Child:IsA("Accoutrement") then
                    Util.ColorHair(Child, hairColor)
                end
            end
        end)
    end
    local hairCount = #HAIR_COLORS
    HairColors.CanvasSize = UDim2.fromOffset(
        0,
        (HairTemplate.AbsoluteSize.Y + 10) * math.ceil(hairCount / 7)
    )

    for i, skinColor in ipairs(SKIN_COLORS) do
        local ColorButton = SkinTemplate:Clone()
        ColorButton.BackgroundColor3 = skinColor
        ColorButton.Parent = SkinTones
        ColorButton.Visible = true
        table.insert(SkinButtons, ColorButton)

        ColorButton.MouseButton1Click:Connect(function()
            if lastSkin then
                lastSkin.BorderColor3 = Color3.new(0, 0, 0)
            end
            ColorButton.BorderColor3 = Color3.new(1, 1, 1)
            lastSkin = ColorButton

            selectedSkin = i

            for j, Child in ipairs(DisplayCharacter:GetChildren()) do
                if Child:IsA("BasePart") then
                    Child.Color = skinColor
                end
            end
        end)
    end
    SkinTones.CanvasSize = UDim2.fromOffset(
        0,
        (HairTemplate.AbsoluteSize.Y + 10) * math.ceil(#SKIN_COLORS / 7)
    )

    ---Provides the indexes of the ethnicity, hair color, and skin color
    ---@return number
    ---@return number
    ---@return number
    module.Results = function()
        return selectedEthnicity, selectedHair, selectedSkin
    end

    return LastPage, NextPage
end

return module