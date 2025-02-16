--Handles the display of pictures for records on the police terminal
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartStorage = ReplicatedStorage.Parts
local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts

local FacialStorage: Folder = PartStorage.FacialHair
local HairStorage: Folder = PartStorage.Hair
local PreviewChar: Model = PartStorage.PreviewChar

local Util = require(ReplicatedScripts.Util)

local ReplicatedConfig = ReplicatedScripts.Configuration
local ClothingConfig = require(ReplicatedConfig.Clothing)
local PoliceConfig = require(ReplicatedConfig.Police)

local module = {}

---Display a picture for the records
---@param PictureDisplay ViewportFrame The picture display frame
---@param records table The records received from the server
function module:ShowPicture(PictureDisplay: ViewportFrame, records: table)
    local NoPicture: TextLabel = PictureDisplay:WaitForChild("NoPicture")
    local WorldModel: WorldModel = PictureDisplay:WaitForChild("WorldModel")

    for i, Child: Instance in ipairs(WorldModel:GetChildren()) do
        Child:Destroy()
    end

    NoPicture.Visible = not records.Appearance
    if records.Appearance then
        local DisplayChar: Model = PreviewChar:Clone()
        local Character: Model = DisplayChar:WaitForChild("Character")

        local Head: Part = Character:WaitForChild("Head")
        Head:WaitForChild("face").Texture =
            `rbxassetid://{records.Appearance.Face}`

        for j, Child: Instance in ipairs(Character:GetChildren()) do
            if Child:IsA("BasePart") then
                Child.Color = Color3.new(
                    records.Appearance.SkinColor.r,
                    records.Appearance.SkinColor.g,
                    records.Appearance.SkinColor.b
                )
            end
        end

        local hairColor: Color3 = Color3.new(
            records.Appearance.HairColor.r,
            records.Appearance.HairColor.g,
            records.Appearance.HairColor.b
        )
        if records.Appearance.Facial then
            local Facial: Accessory =
                FacialStorage:FindFirstChild(records.Appearance.Facial)
            if Facial then
                Facial = Facial:Clone()
                Util.AddAccoutrement(Character, Facial)
                Util.ColorHair(Facial, hairColor)
            end
        end

        if records.Appearance.Hair then
            local Hair: Accessory =
                HairStorage:FindFirstChild(records.Appearance.Hair)
            if Hair then
                Hair = Hair:Clone()
                Util.AddAccoutrement(Character, Hair)
                Util.ColorHair(Hair, hairColor)
            end
        end

        local Shirt: Shirt = Character:FindFirstChildOfClass("Shirt")
        Shirt.ShirtTemplate = (ClothingConfig[
            records.Officer
            and PoliceConfig.Uniforms[records.PoliceRank].Shirt
            or records.Appearance.Shirt
        ] or ClothingConfig.IMMIGRANT_DEFAULT_SHIRT).Template

        local Pants: Pants = Character:FindFirstChildOfClass("Pants")
        Pants.PantsTemplate = (ClothingConfig[
            records.Officer
            and PoliceConfig.Uniforms[records.PoliceRank].Pants
            or records.Appearance.Pants
        ] or ClothingConfig.IMMIGRANT_DEFAULT_PANTS).Template

        DisplayChar.Parent = WorldModel

        PictureDisplay.CurrentCamera = Util.CreateInstance("Camera", {
            CFrame = DisplayChar:WaitForChild("CameraPart").CFrame;
            Parent = PictureDisplay;
        })
    end
end

return module