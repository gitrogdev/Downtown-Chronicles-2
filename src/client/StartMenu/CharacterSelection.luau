--This script handles character selection on the start menu
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

local PartStorage = ReplicatedStorage.Parts
local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts

local FacialStorage = PartStorage.FacialHair
local HairStorage = PartStorage.Hair
local PreviewChar = PartStorage.PreviewChar

local ReplicatedConfig = ReplicatedScripts.Configuration
local ClothingConfig = require(ReplicatedConfig.Clothing)

local ScriptStorage = ReplicatedStorage.ReplicatedScripts
local Communication = ScriptStorage.Communication
local Configuration = ScriptStorage.Configuration
local Util = require(ScriptStorage.Util)

local CharacterData = Communication.CharacterData
local DeleteCharacter = Communication.DeleteCharacter
local NewCharacter = Communication.NewCharacter
local PlayCharacter = Communication.PlayCharacter

local ProductIds = require(Configuration.Products)

local CITIZENSHIPS = {
    North = {
        Image = "rbxassetid://16638045177";
        ImageColor = Color3.new(1, 1, 0);
    };
}

local module = {}

---Creates the character cards on the main menu
---@param StartMenu ScreenGui The main menu
---@param Blackout ColorCorrectionEffect The blackout effect used
---@param MenuMusic Sound The music playing on the main menu
module.Setup = function(
    StartMenu: ScreenGui,
    Blackout: ColorCorrectionEffect,
    MenuMusic: Sound
)
    local CharacterSelection = StartMenu:WaitForChild("CharacterSelection")

    local CharacterTemplate = CharacterSelection:WaitForChild(
        "CharacterTemplate"
    )

    local NewCharHolder = CharacterSelection:WaitForChild("NewCharacter")
    local NewCharButton = NewCharHolder:WaitForChild("CharacterButton")

    local UIPageLayout = CharacterSelection:WaitForChild("UIPageLayout")

    local cooldown

    if RunService:IsStudio() and ReplicatedStorage:GetAttribute("FastLoad") then
        if PlayCharacter:InvokeServer(
            ReplicatedStorage:GetAttribute("LoadAs") or 0
        ) then
            return StartMenu:Destroy()
        end
    end

    local characterData = CharacterData:InvokeServer()
    print(
        `{script}.Setup: Maximum character limit of {characterData.Maximum}, \z
        currently using {#characterData.Characters}.`
    )

    local NewChar: RBXScriptConnection
    local function updateNewCharButton()
        if NewChar then
            NewChar:Disconnect()
        end

        if #characterData.Characters < characterData.Maximum then
            NewCharButton.Text = "New Character"
            NewChar = NewCharButton.MouseButton1Click:Connect(function()
                if cooldown then
                    return
                end

                cooldown = true
                if NewCharacter:InvokeServer() then
                    MenuMusic.Parent = Player.PlayerGui:WaitForChild(
                        "CharacterCreation"
                    )
                    StartMenu.Parent = nil
                end
            end)
        else
            NewCharButton.Text = "Purchase Slot (R$25)"
            NewChar = NewCharButton.MouseButton1Click:Connect(function()
                MarketplaceService:PromptProductPurchase(
                    Player, ProductIds.CharacterSlot
                )
            end)
        end
    end
    updateNewCharButton()

    local updateMenu
    updateMenu = Player.PlayerGui.ChildAdded:Connect(function(Child: Instance)
        if Child.Name == "CharacterCreation" then
            MenuMusic.Parent = Child
            StartMenu.Parent = nil
            updateMenu:Disconnect()
        end
    end)

    for i, charData in ipairs(characterData.Characters) do
        if not (charData and charData.Face) then
            continue
        end

        local CharacterOption = CharacterTemplate:Clone()
        local BankDisplay = CharacterOption:WaitForChild("BankDisplay")
        local CitizenDisplay = CharacterOption:WaitForChild("CitizenDisplay")
        local DeleteButton = CharacterOption:WaitForChild("DeleteButton")
        local GenderDisplay = CharacterOption:WaitForChild("GenderDisplay")
        local JobDisplay = CharacterOption:WaitForChild("OccupationDisplay")
        local NameDisplay = CharacterOption:WaitForChild("CharacterName")
        local PlayButton = CharacterOption:WaitForChild("PlayButton")
        local TIBDisplay = CharacterOption:WaitForChild("TIBDisplay")
        local Viewport = CharacterOption:WaitForChild("ViewportFrame")
        local WorldModel = Viewport:WaitForChild("WorldModel")

        local DeleteCondition = DeleteButton:WaitForChild("DeleteCondition")
        local DeleteConfirmation = DeleteButton:WaitForChild("Confirmation")
        local DeleteConfirm = DeleteConfirmation:WaitForChild("ConfirmButton")
        local DeleteCancel = DeleteConfirmation:WaitForChild("CancelButton")

        local DisplayChar = PreviewChar:Clone()
        local Character = DisplayChar:WaitForChild("Character")

        local Head = Character:WaitForChild("Head")
        Head:WaitForChild("face").Texture = `rbxassetid://{charData.Face}`

        for j, Child in ipairs(Character:GetChildren()) do
            if Child:IsA("BasePart") then
                Child.Color = Color3.new(
                    charData.SkinColor.r,
                    charData.SkinColor.g,
                    charData.SkinColor.b
                )
            end
        end

        local hairColor = Color3.new(
            charData.HairColor.r,
            charData.HairColor.g,
            charData.HairColor.b
        )
        if charData.Facial then
            local Facial = FacialStorage:FindFirstChild(charData.Facial)
            if Facial then
                Facial = Facial:Clone()
                Util.AddAccoutrement(Character, Facial)
                Util.ColorHair(Facial, hairColor)
            end
        end

        if charData.Hair then
            local Hair = HairStorage:FindFirstChild(charData.Hair)
            if Hair then
                Hair = Hair:Clone()
                Util.AddAccoutrement(Character, Hair)
                Util.ColorHair(Hair, hairColor)
            end
        end

        if charData.Shirt then
            local Shirt = Character:FindFirstChildOfClass("Shirt")
            Shirt.ShirtTemplate = (
                ClothingConfig[charData.Shirt]
                or (charData.Citizenship == "North"
                and ClothingConfig.CITIZEN_DEFAULT_SHIRT)
                or ClothingConfig.IMMIGRANT_DEFAULT_SHIRT
            ).Template
        end

        if charData.Pants then
            local Pants = Character:FindFirstChildOfClass("Pants")
            Pants.PantsTemplate = (
                ClothingConfig[charData.Pants]
                or (charData.Citizenship == "North"
                and ClothingConfig.CITIZEN_DEFAULT_PANTS)
                or ClothingConfig.IMMIGRANT_DEFAULT_PANTS
            ).Template
        end

        local citizenshipConfig = CITIZENSHIPS[charData.Citizenship]
        if citizenshipConfig then
            CitizenDisplay.Image = citizenshipConfig.Image
            CitizenDisplay.ImageColor3 = citizenshipConfig.ImageColor
                or Color3.new(1, 1, 1)
        end

        DisplayChar.Parent = WorldModel

        Viewport.CurrentCamera = Util.CreateInstance("Camera", {
            CFrame = DisplayChar:WaitForChild("CameraPart").CFrame;
            Parent = Viewport;
        })

        local tib = math.floor((charData.Playtime or 0) / 3600)

        BankDisplay.Text =
            `₲{Util.ThousandsSeparate(charData.BankBalance or 0)}`
        GenderDisplay.Image = `rbxassetid://\z
            {(charData.Gender and 2978881122) or 2978881615}`
        JobDisplay.Text = Util.JobTitle(charData)
        TIBDisplay.Text = `{tib} TIB`

        local debounce
        if tib > 0 or RunService:IsStudio() then
            DeleteButton.MouseEnter:Connect(function()
                TweenService:Create(DeleteButton, TweenInfo.new(0.5), {
                    ImageColor3 = Color3.new(1, 0, 0);
                }):Play()
            end)

            DeleteButton.MouseLeave:Connect(function()
                TweenService:Create(DeleteButton, TweenInfo.new(0.5), {
                    ImageColor3 = Color3.new(1, 1, 1);
                }):Play()
            end)

            DeleteConfirm.MouseButton1Click:Connect(function()
                if debounce then
                    debounce = true
                end

                if DeleteCharacter:InvokeServer(charData.ID) then
                    for j, checkData in ipairs(characterData.Characters) do
                        if checkData == charData then
                            table.remove(characterData.Characters, j)
                            break
                        end
                    end
                    CharacterOption:Destroy()
                    updateNewCharButton()
                else
                    debounce = false
                end
            end)

            DeleteCancel.MouseButton1Click:Connect(function()
                DeleteConfirmation.Visible = false
            end)

            DeleteButton.MouseButton1Click:Connect(function()
                DeleteConfirmation.Visible = true
            end)
        else
            DeleteButton.ImageColor3 = Color3.new(0.5, 0.5, 0.5)
            DeleteButton.ImageTransparency = 0.5

            DeleteButton.MouseEnter:Connect(function()
                DeleteCondition.Visible = true
            end)

            DeleteButton.MouseLeave:Connect(function()
                DeleteCondition.Visible = false
            end)
        end

        PlayButton.MouseButton1Click:Connect(function()
            if debounce then
                debounce = true
            end

            TweenService:Create(Blackout, TweenInfo.new(1), {
                Brightness = -1;
            }):Play()
            
            if PlayCharacter:InvokeServer(charData.ID) then
                updateMenu:Disconnect()
                StartMenu:Destroy()
            else
                debounce = false
            end
        end)

        NameDisplay.Text =
            (charData.Rejected and `Immigrant {Player.UserId}-{charData.ID}`)
            or `{charData.FirstName} {charData.LastName}`

        CharacterOption.Parent = CharacterSelection
        CharacterOption.Visible = true
    end

    UIPageLayout:JumpToIndex(0)
    module.Loaded = true
end

return module