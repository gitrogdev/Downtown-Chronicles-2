--This script handles all character customization and appearances
local BadgeService = game:GetService("BadgeService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local VoiceChatService = game:GetService("VoiceChatService")

local BirthdayHandler = require(script.Birthdays)
local CreationClient = script.Creation
local EditedClient = script.EditName
local NameHandler = require(script.Names)
local PrivateAttributes = require(script.PrivateAttributes)
local RejectClient = script.RejectName
local SaveAttributes = require(script.SaveAttributes)
local SpawnSelection = script.SelectSpawn

local ReplicatedParts = ReplicatedStorage.Parts
local FacialStorage = ReplicatedParts.FacialHair
local HairStorage = ReplicatedParts.Hair

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Communication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local ClothingConfig = require(ReplicatedConfig.Clothing)
local CustomizationConfig = require(ReplicatedConfig.Customization)
local InventoryConfig = require(ReplicatedConfig.Inventory)
local ProductIds = require(ReplicatedConfig.Products)
local Sounds = require(ReplicatedConfig.Sounds)
local SpawnLocations = require(ReplicatedConfig.Spawns)

local CanTalk = Communication.CanTalk
local CharacterData = Communication.CharacterData
local CreateCharacter = Communication.CreateCharacter
local DeleteCharacter = Communication.DeleteCharacter
local FaceDirection = Communication.FaceDirection
local LoadCharacter = Communication.LoadCharacter
local NewCharacter = Communication.NewCharacter
local PlayCharacter = Communication.PlayCharacter
local ReplaceName = Communication.ReplaceName
local RespondEdit = Communication.RespondEdit
local SendNotification = Communication.SendNotification

local ServerScripts = ServerScriptService.ServerScripts
local ChatHandler = require(ServerScripts.Chat)
local CitizenshipHandler = require(ServerScripts.Citizenship)
local CollisionHandler = require(ServerScripts.Collisions)
local DataHandler = require(ServerScripts.Data)
local DeathHandler = require(ServerScripts.Deaths)
local InventoryHandler = require(ServerScripts.Inventory)
local PrisonHandler = require(ServerScripts.Prison)
local SecurityHandler = require(ServerScripts.Security)
local ServerConfig = ServerScripts.Configuration
local TeamHandler = require(ServerScripts.Teams)
local Util = require(ServerScripts.Util)

local Badges = require(ServerConfig.Badges)
local PlaceIds = require(ServerConfig.Places)
local RemovedClothing = require(ServerConfig.RemovedClothing)

local ServerParts = ServerStorage.Parts
local PrivateStorage = ServerStorage:FindFirstChild("PrivateStorage") or
    Util.CreateInstance("Folder", {
        Name = "PrivateStorage";
        Parent = ServerStorage;
    })
local UIStorage = ServerStorage.UserInterface

local HeadUnion = ServerParts.HeadUnion

local CreationUI = UIStorage.CharacterCreation
local EditedUI = UIStorage.EditedName
local Nametag = UIStorage.Nametag
local RejectUI = UIStorage.RejectName

local CURVE_PROPERTIES = {
    Min = 7;
    Max = 80;
    Step = 2;
}
local DEFAULT_VOICE_CURVE = {}
for i = CURVE_PROPERTIES.Min, CURVE_PROPERTIES.Max, CURVE_PROPERTIES.Step do
	DEFAULT_VOICE_CURVE[i] = (
        (i - CURVE_PROPERTIES.Min)
        - (CURVE_PROPERTIES.Max - CURVE_PROPERTIES.Min)
    ) ^ 2 / (CURVE_PROPERTIES.Max - CURVE_PROPERTIES.Min) ^ 2
end
DEFAULT_VOICE_CURVE[CURVE_PROPERTIES.Max] = 0
local FORBIDDEN_BIRTHDAYS = {
    ["11.9.2001."] = true; --9/11 attacks
}

local loadedChars, loadedData = {}, {}
CharacterData.OnServerInvoke = function(Player: Player)
    if loadedData[Player] then
        return warn(`{script}.CharacterData.OnServerInvoke: \z
            Player {Player} already got character data!`
        )
    end

    ChatHandler.Commands.CalculatePermissions(Player)

    --Stops the player from requesting user data again while in progress
    loadedData[Player] = {Characters = {}}
    
    local userData = DataHandler.Get("UserData", tostring(Player.UserId))
        or {Characters = {}}
    loadedData[Player] = userData

    if
        (not RunService:IsStudio())
        and game.PlaceId == PlaceIds.DevPlace
        and not userData.DevPlace
    then
        warn(
            `{script}.CharacterData.OnServerInvoke: {Player} attempted to \z
            access the development place without proper permission!`
        )
        return SecurityHandler.Ban(Player.UserId, "IX")
    elseif game.PlaceId == PlaceIds.DevPlace then
        DataHandler.Update("UserData", tostring(Player.UserId),
            function(data: table)
                data = data or {}

                data.DevPlace = nil

                return data
            end
        )
    end

    local characterData = {}
    for i, characterId in ipairs(userData.Characters) do
        local charData = DataHandler.Get("Characters", tostring(characterId))
        if charData then
            charData.ID = characterId
            charData.Private = nil

            if not charData.Dead then
                table.insert(characterData, charData)
            else
                warn(`{script}.CharacterData.OnServerInvoke: \z
                    Character with ID {characterId} is dead!`
                )
            end
        else
            warn(`{script}.CharacterData.OnServerInvoke: \z
                No data found for character with ID {characterId}`
            )
        end
    end

    print(`{script}.CharacterData.OnServerInvoke: \z
        Sending data for {#characterData} characters to {Player}`
    )
    return {
        Characters = characterData;
        Maximum = userData.MaxCharacters
            or (#userData.Characters > 0 and #userData.Characters) or 1;
    }
end

DeleteCharacter.OnServerInvoke = function(Player: Player, id: number)
    if loadedChars[Player] then
        return warn(`{script}.DeleteCharacter.OnServerInvoke: \z
            Character already loaded for Player {Player}!`
        )
    end

    if not loadedData[Player] then
        return warn(`{script}.DeleteCharacter.OnServerInvoke: \z
            Data not yet loaded for Player {Player}!`
        )
    end

    local found
    for i, charId in ipairs(loadedData[Player].Characters) do
        if charId == id then
            found = i
            break
        end
    end

    if not found then
        return warn(`{script}.DeleteCharacter.OnServerInvoke: \z
            Player {Player} does not own the character with ID {id}!`
        )
    end

    if Player:GetAttribute("ID") then
        return warn(`{script}.DeleteCharacter.OnServerInvoke: \z
            Player {Player} is already loaded into a character!`
        )
    end

    DataHandler.Update("UserData", tostring(Player.UserId),
        function(data: table)
            data.Characters = data.Characters or {}
            data.MaxCharacters = data.MaxCharacters
                or (#data.Characters > 0 and #data.Characters) or 1
            data.Deleted = data.Deleted or {}

            local removedId = table.remove(data.Characters, found)
            table.insert(data.Deleted, removedId)

            return data
        end
    )

    return true
end

---Face a Player's character in a certain direction
---@param Player Player The Player to look in the direction
---@param direction Vector3 The direction to face
---@param lockedArms boolean Whether the arms are locked by an animation
FaceDirection.OnServerEvent:Connect(function(
    Player: Player, direction: Vector3, lockedArms: boolean
)
    local Humanoid = Player.Character
        and Player.Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then
        return
    end

    if Humanoid.Health <= 0 then
        return
    end

    local RootPart = Humanoid.RootPart
    if not RootPart then
        return
    end

    local Torso = Player.Character:FindFirstChild("Torso")
    if not Torso then
        return
    end

	local Neck = Torso:FindFirstChild("Neck")
    if not Neck then
        return
    end

	local LeftShoulder = Torso:FindFirstChild("Left Shoulder")
	local RightShoulder = Torso:FindFirstChild("Right Shoulder")

    local target = CFrame.Angles(0, 0, math.asin(direction.Y))

    if lockedArms then
        if LeftShoulder then
            LeftShoulder.C1 = Util.DefaultCFrames.LeftShoulderC1
        end
        if RightShoulder then
            RightShoulder.C1 = Util.DefaultCFrames.RightShoulderC1
        end
    else
        if LeftShoulder then
            LeftShoulder.C1 = Util.DefaultCFrames.LeftShoulderC1 * target
        end
        if RightShoulder then
            RightShoulder.C1 = Util.DefaultCFrames.RightShoulderC1
                * target:Inverse()
        end
    end

    Neck.C0 = Util.DefaultCFrames.NeckC0 * CFrame.Angles(
        math.asin(direction.Y), 0, 0
    ):Inverse()
end)

ReplaceName.OnServerInvoke = function(
    Player: Player,
    first: string,
    last: string
)
    local Interface = Player.PlayerGui:FindFirstChild(RejectUI.Name)
    if not Interface then
        return warn(`{script}.ReplaceName.OnServerInvoke: \z
            Player {Player} is not currently responding to a rejected name.`
        )
    end

    if not NameHandler.Validate(first, last) then
        return warn(`{script}.ReplaceName.OnServerInvoke: \z
            Invalid name provided for {Player.Name}!`
        )
    end
    first = Util.RemoveWhitespace(first)
    last = Util.RemoveWhitespace(last)

    local id = Player:GetAttribute("ID")
    if not id then
        return warn(`{script}.ReplaceName.OnServerInvoke: \z
            Player {Player} does not currently have a character loaded.`
        )
    end

    Interface:Destroy()

    Player:SetAttribute("Approved", nil)
    Player:SetAttribute("Edited", nil)
    Player:SetAttribute("Rejected", nil)

    DataHandler.Update("Characters", tostring(id), function(data: table)
        data = data or {}
        
        data.FirstName = first
        data.LastName = last

        data.Approved = nil
        data.Edited = nil
        data.Rejected = nil

        return data
    end)

    NameHandler.Submit(first, last, Player:GetAttribute("Gender"), id, Player)
end

RespondEdit.OnServerInvoke = function(Player: Player, status: boolean)
    local Interface = Player.PlayerGui:FindFirstChild(EditedUI.Name)
    if not Interface then
        return warn(`{script}.RespondEdit.OnServerInvoke: \z
            Player {Player} is not currently responding to a name edit.`
        )
    end

    local id = Player:GetAttribute("ID")
    if not id then
        return warn(`{script}.RespondEdit.OnServerInvoke: \z
            Player {Player} does not currently have a character loaded!`
        )
    end

    Interface:Destroy()

    if status then
        Player:SetAttribute("Approved", true)
        Player:SetAttribute("Edited", nil)
        Player:SetAttribute("Rejected", nil)

        DataHandler.Update("Characters", tostring(id), function(data: table)
            data = data or {}
    
            data.Approved = true
            data.Edited = nil
            data.Rejected = nil
    
            return data
        end)
    else
        local RejectInterface = RejectUI:Clone()
        RejectClient:Clone().Parent = RejectInterface
        RejectInterface.Parent = Player.PlayerGui
    end
end

Players.PlayerRemoving:Connect(function(Player: Player)
    local id = Player:GetAttribute("ID")
    local loadedAt = Player:GetAttribute("LoadedAt")
    if not (id and loadedAt) then
        return
    end

    DataHandler.Update("Characters", tostring(id), function(data: table)
        if not data then
            return warn(
                `{script}.Players.PlayerRemoving: No data found for character \z
                with ID {id} ({Player})`
            )
        end

        local savedInventory, equipped = InventoryHandler.Save(Player)
        data.Equipped = equipped
        data.Inventory = savedInventory

        if Player:GetAttribute("SavedShirt") then
            Player:SetAttribute("Shirt", Player:GetAttribute("SavedShirt"))
        end

        if Player:GetAttribute("SavedPants") then
            Player:SetAttribute("Pants", Player:GetAttribute("SavedPants"))
        end

        for attribute, default in pairs(SaveAttributes) do
            data[attribute] = Player:GetAttribute(attribute) or default
        end

        local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{id}`)
        if PrivatePlayer then
            data.Private = data.Private or {}
            for attribute, default in pairs(PrivateAttributes) do
                data.Private[attribute] = PrivatePlayer:GetAttribute(attribute)
                    or default
            end
            PrivatePlayer:Destroy()
        end

        data.Playtime = (data.Playtime or 0) + (os.time() - loadedAt)
        return data
    end)
end)

local module = {}

CreateCharacter.OnServerInvoke = function(
    Player: Player,
    first: string,
    last: string,
    gender: boolean,
    birthDate: number,
    birthMonth: number,
    birthYear: number,
    ethnicity: number,
    hairColor: number,
    skinColor: number,
    face: number,
    hair: string,
    facial: string
)
    local Interface = Player.PlayerGui:FindFirstChild(CreationUI.Name)
    if not Interface then
        return false, "Customization session not recognized!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Player {Player} is not currently making a new character!`
            )
    end

    if not NameHandler.Validate(first, last) then
        return false, "Invalid name!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid name for {Player}!`
            )
    end

    if type(gender) ~= "boolean" then
        return false, "Invalid gender!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid gender for {Player}!`
            )
    end

    if not BirthdayHandler.Validate(birthDate, birthMonth, birthYear) then
        return false, "Invalid birthday!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid birthday for {Player}!`
            )
    end

    if FORBIDDEN_BIRTHDAYS[`{birthDate}.{birthMonth}.{birthYear}.`] then
        return false, "Forbidden birthday!", warn(
            `{script}.CreateCharacter.OnServerInvoke: Forbidden birthday \z
            {birthDate}.{birthMonth}.{birthYear}. for {Player}!`
        ), Player:Kick("Forbidden birthday")
    end

    if not CustomizationConfig.Ethnicities[ethnicity] then
        return false, "Invalid ethnicity!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid ethnicity for {Player}!`
            )
    end

    hairColor = CustomizationConfig.Colors.Hair[hairColor]
    if not hairColor then
        return false, "Invalid hair color!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid hair color for {Player}!`
            )
    end

    skinColor = CustomizationConfig.Colors.Skin[skinColor]
    if not skinColor then
        return false, "Invalid skin color!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid skin color for {Player}!`
            )
    end

    face = CustomizationConfig.Faces[face]
    if not face then
        return false, "Invalid face!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid face for {Player}!`
            )
    end

    if hair and not (HairStorage:FindFirstChild(hair)) then
        return false, "Invalid hair!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid hair for {Player}!`
            )
    end

    if facial and not (FacialStorage:FindFirstChild(facial)) then
        return false, "Invalid facial hair!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Invalid facial hair for {Player}!`
            )
    end

    if gender and facial then
        return false, "Facial hair is not permitted for female characters!",
            warn(`{script}.CreateCharacter.OnServerInvoke: \z
                Attempt to set facial hair for female character for {Player}!`
            )
    end

    Interface:Destroy()

    local charCount
    DataHandler.Update("Characters", "Count", function(count: number)
        count = count or 0

        charCount = count

        count += 1
        return count
    end)

    local characterData = {
        Birthday = {
            Day = birthDate;
            Month = birthMonth;
            Year = birthYear;
        };
        Created = {
            At = os.time();
            By = Player.UserId;
            Version = game:GetAttribute("Version");
        };
        Ethnicity = CustomizationConfig.Ethnicities[ethnicity];
        Face = face;
        Facial = facial;
        FirstName = first;
        LastName = last;
        Gender = gender;
        Hair = hair;
        HairColor = {
            r = hairColor.r;
            g = hairColor.g;
            b = hairColor.b;
        };
        SkinColor = {
            r = skinColor.r;
            g = skinColor.g;
            b = skinColor.b;
        };
    }
    DataHandler.Set("Characters", tostring(charCount), characterData)
    
    DataHandler.Update("UserData", tostring(Player.UserId), function(data: table)
        data = data or {}
        data.Characters = data.Characters or {}
        data.MaxCharacters = data.MaxCharacters
            or (#data.Characters > 0 and #data.Characters) or 1
        data.FirstSeen = data.FirstSeen or {
            At = os.time();
            Version = game:GetAttribute("Version");
        }
        
        table.insert(data.Characters, charCount)
        return data
    end)

    NameHandler.Submit(first, last, gender, charCount, Player)

    module.LoadData(Player, charCount, characterData)
    module.SelectSpawn(Player)
    return true
end

NewCharacter.OnServerInvoke = function(Player: Player)
    if Player.Character then
        return warn(`{script}.NewCharacter.OnServerInvoke: \z
            Player {Player.Name} has a character loaded!`
        )
    end

    if Player.PlayerGui:FindFirstChild(CreationUI.Name) then
        return warn(`{script}.NewCharacter.OnServerInvoke: \z
            Player {Player.Name} is already making a new character!`
        )
    end

    module.new(Player)

    return true
end

---Load in a player's character
---@param Player Player The Player to load in
---@param Spawn SpawnLocation The SpawnLocation to spawn at
LoadCharacter.OnServerEvent:Connect(function(
    Player: Player, Spawn: SpawnLocation
)
    local SpawnSelector = Player.PlayerGui:FindFirstChild(SpawnSelection.Name)
    if not SpawnSelector then
        return warn(
            `{script}.LoadCharacter.OnServerEvent: {Player} is not currently \z
            selecting a spawn point!`
        )
    end
    SpawnSelector:Destroy()

    if not Spawn:IsA("SpawnLocation") then
        return warn(
            `{script}.LoadCharacter.OnServerEvent: {Spawn} is not a \z
            valid spawn point!`
        )
    end

    local spawnType = Spawn:GetAttribute("SpawnType")
    if not spawnType then
        return warn(
            `{script}.LoadCharacter.OnServerEvent: Spawn type not found for \z
            spawn {Spawn:GetFullName()}!`
        )
    end

    local spawnConfig = SpawnLocations[spawnType]
    if not spawnConfig then
        return warn(
            `{script}.LoadCharacter.OnServerEvent: Unknown spawn type \z
            "{spawnType}" for spawn {Spawn:GetFullName()}!`
        )
    end

    if not spawnConfig.Check(Player, Spawn) then
        return warn(
            `{script}.LoadCharacter.OnServerEvent: {Player} does not have \z
            permission to spawn at {Spawn:GetFullName()} of type {spawnType}!`
        )
    end

    Player.RespawnLocation = Spawn
    module.LoadCharacter(Player)
end)

PlayCharacter.OnServerInvoke = function(Player: Player, id: number)
    if loadedChars[Player] then
        return warn(`{script}.PlayCharacter.OnServerInvoke: \z
            Character already loaded for Player {Player}!`
        )
    end

    if not loadedData[Player] then
        if RunService:IsStudio() then
            Player:SetAttribute("PermissionLevel", 6)
            loadedData[Player] = DataHandler.Get(
                "UserData",
                tostring(Player.UserId)
            ) or {Characters = {}}
        else
            return warn(`{script}.PlayCharacter.OnServerInvoke: \z
                Data not yet loaded for Player {Player}!`
            )
        end
    end

    local found
    for i, charId in ipairs(loadedData[Player].Characters) do
        if charId == id then
            found = true
            break
        end
    end

    if not found then
        if RunService:IsStudio()
            and ReplicatedStorage:GetAttribute("LoadAs") == id
        then
            print(
                `{script}.PlayCharacter.OnServerInvoke: The Player {Player} \z
                is loading the character with ID {id}, which is not theirs, \z
                but this is being allowed due to being a studio instance.`
            )
        else
            return warn(`{script}.PlayCharacter.OnServerInvoke: \z
                Player {Player} does not own the character with ID {id}!`
            )
        end
    end

    if Player:GetAttribute("ID") then
        return warn(`{script}.PlayCharacter.OnServerInvoke: \z
            Player {Player} is already loaded into a character!`
        )
    end
    
    loadedChars[Player] = true

    print(
        `{script}.PlayCharacter.OnServerInvoke: Loading data for character \z
        {id} for {Player}.`
    )
    module.LoadData(Player, id, DataHandler.Get("Characters", tostring(id)))

    print(
        `{script}.PlayCharacter.OnServerInvoke: Loading character for {Player}.`
    )
    module.SelectSpawn(Player)
    return true
end

---Loads the character for a Player into the workspace and displays customization
---@param Player Player The Player to load
module.LoadCharacter = function(Player: Player)
    Player.CanLoadCharacterAppearance = false

    Player:LoadCharacterWithHumanoidDescription(
        Util.CreateInstance("HumanoidDescription", {
            HeadColor = Player:GetAttribute("SkinColor");
            LeftArmColor = Player:GetAttribute("SkinColor");
            LeftLegColor = Player:GetAttribute("SkinColor");
            RightArmColor = Player:GetAttribute("SkinColor");
            RightLegColor = Player:GetAttribute("SkinColor");
            TorsoColor = Player:GetAttribute("SkinColor");
        })
    )

    local Character = Player.Character
    local Head = Character:WaitForChild("Head")
    local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

    local canTalk: boolean = CanTalk:InvokeClient(Player)
    local AudioInput: AudioDeviceInput
    if canTalk then
        AudioInput = Player:FindFirstChildOfClass(
            "AudioDeviceInput"
        ) or Util.CreateInstance("AudioDeviceInput", {
            Parent = Player;
            Player = Player;
        })
        AudioInput.Muted = Player:GetAttribute("Muted")

        local Emitter: AudioEmitter = Util.CreateInstance("AudioEmitter", {
            Parent = Character;
        })
        Emitter:SetDistanceAttenuation(DEFAULT_VOICE_CURVE)

        Util.CreateInstance("Wire", {
            Parent = Emitter;
            SourceInstance = AudioInput;
            TargetInstance = Emitter;
        })
    end

    local HeadCollisions = HeadUnion:Clone()
    HeadCollisions.CFrame = Head.CFrame
    Util.WeldTo(HeadCollisions, Head)
    HeadCollisions.Parent = Character

    for i, Child in ipairs(Character:GetChildren()) do
        if Child:IsA("BasePart") then
            CollisionHandler.Group(Child, "Players")
        end
    end

    Humanoid.BreakJointsOnDeath = false
    Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

    CollectionService:AddTag(Head, "DontShoot")
    CollectionService:AddTag(Humanoid.RootPart, "DontShoot")

    local Face = Head:WaitForChild("face")

    Face.Texture = `rbxassetid://{Player:GetAttribute("Face")}`

    local facialHair: string = Player:GetAttribute("FacialHair")
    if facialHair then
        local FacialHair: Accessory = FacialStorage:FindFirstChild(facialHair)
        if FacialHair then
            FacialHair = FacialHair:Clone()
            FacialHair:SetAttribute("FacialHair", true)
            Util.ColorHair(FacialHair, Player:GetAttribute("HairColor"))
            FacialHair.Parent = Character
        end
    end

    local hair: string = Player:GetAttribute("Hair")
    if hair then
        local Hair: Accessory = HairStorage:FindFirstChild(hair)
        if Hair then
            Hair = Hair:Clone()
            Hair:SetAttribute("Hair", true)
            Util.ColorHair(Hair, Player:GetAttribute("HairColor"))
            Hair.Parent = Character
        end
    end

    local refundPants: number = RemovedClothing[Player:GetAttribute("Pants")]
    if refundPants then
        Player:SetAttribute(
            "Pants", Player:GetAttribute("Citizenship") == "North"
            and "CITIZEN_DEFAULT_PANTS" or "IMMIGRANT_DEFAULT_PANTS"
        )
        Player:SetAttribute(
            "BankBalance", Player:GetAttribute("BankBalance") + refundPants
        )
        SendNotification:FireClient(Player, {
            Title = "Clothing refund";
            Text = `The pants equipped by your character have since been \z
                removed from the game. You have received a refund in the \z
                amount of ₲{Util.ThousandsSeparate(refundPants)}`;
            Duration = 10;
        })
    end

    local Pants = Util.CreateInstance("Pants", {
        Name = "Pants";
        PantsTemplate = (
            ClothingConfig[Player:GetAttribute("Pants")]
            or ClothingConfig.IMMIGRANT_DEFAULT_PANTS
        ).Template;
        Parent = Character;
    })

    local refundShirt: number = RemovedClothing[Player:GetAttribute("Shirt")]
    if refundShirt then
        Player:SetAttribute(
            "Shirt", Player:GetAttribute("Citizenship") == "North"
            and "CITIZEN_DEFAULT_SHIRT" or "IMMIGRANT_DEFAULT_SHIRT"
        )
        Player:SetAttribute(
            "BankBalance", Player:GetAttribute("BankBalance") + refundShirt
        )
        SendNotification:FireClient(Player, {
            Title = "Clothing refund";
            Text = `The shirt equipped by your character has since been \z
                removed from the game. You have received a refund in the \z
                amount of ₲{Util.ThousandsSeparate(refundShirt)}`;
            Duration = 10;
        })
    end

    local Shirt = Util.CreateInstance("Shirt", {
        Name = "Shirt";
        Parent = Character;
        ShirtTemplate = (
            ClothingConfig[Player:GetAttribute("Shirt")]
            or ClothingConfig.IMMIGRANT_DEFAULT_SHIRT
        ).Template;
    })

    local ShirtParts = {"Torso", "Right Arm", "Left Arm"}
    local PantsParts = {"Right Leg", "Left Leg"}

    local clothingUpdates = {
        Player:GetAttributeChangedSignal("Pants"):Connect(function()
            Pants.PantsTemplate = (
                ClothingConfig[Player:GetAttribute("Pants")]
                or Player:GetAttribute("Citizenship") == "North"
                and "CITIZEN_DEFAULT_PANTS" or "IMMIGRANT_DEFAULT_PANTS"
            ).Template

            for i, part in ipairs(PantsParts) do
                local Part = Character:FindFirstChild(part)
                if Part then
                    for j, Child in ipairs(Part:GetDescendants()) do
                        if Child:GetAttribute("Washable") then
                            Child:Destroy()
                        end
                    end
                end
            end
        end);
        Player:GetAttributeChangedSignal("Shirt"):Connect(function()
            Shirt.ShirtTemplate = (
                ClothingConfig[Player:GetAttribute("Shirt")]
                or Player:GetAttribute("Citizenship") == "North"
                and "CITIZEN_DEFAULT_SHIRT" or "IMMIGRANT_DEFAULT_SHIRT"
            ).Template
            for i, part in ipairs(ShirtParts) do
                local Part = Character:FindFirstChild(part)
                if Part then
                    for j, Child in ipairs(Part:GetDescendants()) do
                        if Child:GetAttribute("Washable") then
                            Child:Destroy()
                        end
                    end
                end
            end
        end);
    }

    local fromLocker: string = Player:GetAttribute("LockerAccessories")
    if fromLocker then
        for i, key: string in ipairs(HttpService:JSONDecode(fromLocker)) do
            local Equipped: PVInstance = Util.EquipAccessory(Character, key)
            if Equipped then
                Equipped:SetAttribute("FromLocker", Player:GetAttribute(
                    "UsingLocker"
                ))
            end
        end
    end

    local incarceratedTo = Player:GetAttribute("IncarceratedTo") or 0
    if incarceratedTo > os.time() or Player:GetAttribute("DeathRow") then
        PrisonHandler.Imprison(Player)
    elseif Player:GetAttribute("Incarcerated") then
        Player:SetAttribute("Incarcerated", false)
        if Player:GetAttribute("Felon") then
            PrisonHandler.PunishFelon(Player)
        end

        for i, item: string in ipairs(InventoryConfig.StarterPack) do
            InventoryHandler.Add(
                Player,
                InventoryHandler.Items.new(
                    item,
                    `{Player:GetAttribute("FullName")}'s StarterPack`
                )
            )
        end
    end

    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if Inventory then
        for i, Child: Tool in ipairs(Inventory:GetChildren()) do
            InventoryHandler.Show(Player, Child)
        end
    end

    if Player:GetAttribute("Rejected") then
        local RejectInterface = RejectUI:Clone()
        RejectClient:Clone().Parent = RejectInterface
        RejectInterface.Parent = Player.PlayerGui
    elseif Player:GetAttribute("Edited") then
        local EditedInterface = EditedUI:Clone()
        EditedClient:Clone().Parent = EditedInterface
        EditedInterface.Parent = Player.PlayerGui
    end

    local firstName = Player:GetAttribute("FirstName")
    local lastName = Player:GetAttribute("LastName")
    local id = Player:GetAttribute("ID")

    local CharacterNametag: BillboardGui = Nametag:Clone()
    local NameDisplay: TextLabel = CharacterNametag:WaitForChild("Display")
    NameDisplay.Text = `Stranger ({Player.UserId}-{id})`
    NameDisplay:SetAttribute("CanTalk", canTalk)
    NameDisplay:SetAttribute("FullID", `{Player.UserId}-{id}`)
    CollectionService:AddTag(NameDisplay, `Character{id}Nametag`)
    CharacterNametag.Parent = Head

    Player:SetAttribute("RespawnAt", nil)

    local highestPoint = 0
    local stillFalling
    Humanoid.FreeFalling:Connect(function(falling: boolean)
        if falling and not stillFalling then
            Humanoid.JumpPower = 0
            Humanoid:SetAttribute("DontJump", true)
            highestPoint = Humanoid.RootPart.Position.Y
            stillFalling = true
            while stillFalling do
                if Humanoid.RootPart.Position.Y > highestPoint then
                    highestPoint = Humanoid.RootPart.Position.Y
                end
                task.wait()
            end
        elseif stillFalling then
            --Stopped falling
            Humanoid.JumpPower = 50
            Humanoid:SetAttribute("DontJump", nil)
            stillFalling = false
            if Humanoid.RootPart then
                local newAltitude = Humanoid.RootPart.Position.Y
                if highestPoint > newAltitude then
                    --Fell
                    local difference = highestPoint - newAltitude
                    if difference > 20 then
                        print(
                            `{script}.LoadCharacter: {Player} fell from \z
                            {Util.Round(highestPoint, 2)} to \z
                            {Util.Round(newAltitude, 2)}!`
                        )

                        local FallSound = Util.CreateInstance("Sound", {
                            Parent = Humanoid.RootPart;
                            PlaybackSpeed = math.random(60,150)/100;
                            RollOffMinDistance = difference;
                            RollOffMaxDistance = difference * 2;
                            SoundId = (difference > Humanoid.MaxHealth
                                and math.random(1, 10) == 1
                                and Sounds.WilhelmScream) or Sounds.FallDamage;
                            Volume = difference/10;
                        })
                        if FallSound.SoundId == Sounds.WilhelmScream then
                            FallSound.PlaybackSpeed = 1;
                        end

                        FallSound:Play()
                        FallSound.Ended:Connect(function()
                            FallSound:Destroy()
                        end)

                        DeathHandler.Splatter(
                            Humanoid,
                            difference,
                            Humanoid.RootPart.Position - Vector3.new(0, 2.75, 0)
                        )
                        DeathHandler.TakeDamage(Humanoid, difference, "Falling")
                    end
                    highestPoint = 0
                end
            end
        end
    end)

    Humanoid.Died:Once(function()
        if AudioInput then
            AudioInput.Muted = true
        end

        local Emitter: AudioEmitter =
            Character:FindFirstChildOfClass("AudioEmitter")
        if Emitter then
            Emitter:Destroy()
        end
        for i, func in ipairs(clothingUpdates) do
            func:Disconnect()
        end
        DeathHandler.Kill(Player)
    end)
end

---Unpacks and applies the character data of a Player
---@param Player Player The Player to apply the data to
---@param id number The character ID of the character in use
---@param characterData table The character data to unpack
module.LoadData = function(Player: Player, id: number, characterData: table)
    Player:SetAttribute("ID", id)

    Player:SetAttribute("BirthDay", characterData.Birthday.Day)
    Player:SetAttribute("BirthMonth", characterData.Birthday.Month)
    Player:SetAttribute("BirthYear", characterData.Birthday.Year)
    
    if characterData.Approved then
        Player:SetAttribute("FirstName", characterData.FirstName)
        Player:SetAttribute("LastName", characterData.LastName)
        Player:SetAttribute("Approved", true)

        if characterData.Edited then
            Player:SetAttribute("Edited", characterData.Edited)
        end
    else
        Player:SetAttribute("FirstName", "Immigrant")
        Player:SetAttribute("LastName", `{Player.UserId}-{id}`)

        if characterData.Rejected then
            Player:SetAttribute("Rejected", characterData.Rejected)
        end
    end

    if CitizenshipHandler.IsCitizenship(characterData.Citizenship) then
        for i, license in ipairs(CitizenshipHandler.Licenses) do
            local key = `Rejected{characterData.Citizenship}{license}`
            if characterData[key] then
                Player:SetAttribute(key, characterData[key])
            else
                key = `Approved{characterData.Citizenship}{license}`
                if characterData[key] then
                    Player:SetAttribute(key, true)
                end
            end
        end
    end

    local firstName = Player:GetAttribute("FirstName")
    local lastName = Player:GetAttribute("LastName")
    Player:SetAttribute("FullName", `{firstName} {lastName}`)

    Player:SetAttribute("Face", characterData.Face)
    Player:SetAttribute("FacialHair", characterData.Facial)
    Player:SetAttribute("Gender", characterData.Gender)
    Player:SetAttribute("Hair", characterData.Hair)
    Player:SetAttribute("HairColor", Color3.new(
        characterData.HairColor.r,
        characterData.HairColor.g,
        characterData.HairColor.b
    ))
    Player:SetAttribute("SkinColor", Color3.new(
        characterData.SkinColor.r,
        characterData.SkinColor.g,
        characterData.SkinColor.b
    ))

    Player:SetAttribute("LoadedAt", os.time())
    Player:SetAttribute("Playtime", characterData.Playtime or 0)

    for attribute, default in pairs(SaveAttributes) do
        Player:SetAttribute(attribute, characterData[attribute] or default)
    end
    if
        Player:GetAttribute("Citizenship") == "Tourist"
        and MarketplaceService:UserOwnsGamePassAsync(
            Player.UserId, ProductIds.Local
        )
    then
        Player:SetAttribute("Citizenship", "North") --RETURN TO: let them pick
        if Player:GetAttribute("Shirt") == SaveAttributes.Shirt then
            Player:SetAttribute("Shirt", "CITIZEN_DEFAULT_SHIRT")
        end

        if Player:GetAttribute("Pants") == SaveAttributes.Pants then
            Player:SetAttribute("Pants", "CITIZEN_DEFAULT_PANTS")
        end
    end

    local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{id}`) or
        Util.CreateInstance("Model", {
            Name = `Character{id}`;
            Parent = PrivateStorage;
        })
    characterData.Private = characterData.Private or {}
    for attribute, default in pairs(PrivateAttributes) do
        PrivatePlayer:SetAttribute(
            attribute,
            characterData.Private[attribute] or default
        )
    end

    local incarceratedTo = Player:GetAttribute("IncarceratedTo") or 0
    if incarceratedTo > os.time() or Player:GetAttribute("DeathRow") then
        TeamHandler.Join(Player, "Incarcerated")
    else
        TeamHandler.Join(Player, CitizenshipHandler.ToTeam(
            Player:GetAttribute("Citizenship")
        ))
    end

    InventoryHandler.Load(
        Player,
        characterData.Inventory,
        characterData.Equipped
    )

    ChatHandler.Listen(Player)

    if not PrivatePlayer:GetAttribute("BadgeAlpha") then
        BadgeService:AwardBadge(Player.UserId, Badges.Alpha)
        if not RunService:IsStudio() then
            PrivatePlayer:SetAttribute("BadgeAlpha", true)
        end
    end

    local tib = math.floor(Player:GetAttribute("Playtime") / 3600)
    if tib >= 5 then
        for count, badge in pairs(Badges.TIB) do
            if
                tib >= count
                and not PrivatePlayer:GetAttribute(`Badge{count}TIB`)
            then
                BadgeService:AwardBadge(Player.UserId, badge)
                if not RunService:IsStudio() then
                    PrivatePlayer:SetAttribute(`Badge{count}TIB`, true)
                end
            end
        end
    end

    task.spawn(function()
        while Player.Parent == Players do
            if math.floor(Player:GetAttribute("Playtime") / 3600) > tib then
                tib = math.floor(Player:GetAttribute("Playtime") / 3600)
                print(
                    `{script}.LoadData: {Player:GetAttribute("FullName")} \z
                    ({Player}) has advanced to {tib} TIB.`
                )
                if Badges.TIB[tib] then
                    BadgeService:AwardBadge(Player.UserId, Badges.TIB[tib])
                    if not RunService:IsStudio() then
                        PrivatePlayer:SetAttribute(`Badge{tib}TIB`, true)
                    end
                end
            end

            task.wait(60)
        end
    end)

    SecurityHandler.AntiAFK(Player)
end

---Prompt a Player to select a spawn location
---@param Player Player The Player to prompt
module.SelectSpawn = function(Player: Player)
    local incarceratedTo = Player:GetAttribute("IncarceratedTo") or 0
    if incarceratedTo > os.time() or Player:GetAttribute("DeathRow") then
        Player.RespawnLocation = Util.RandomFrom(
            CollectionService:GetTagged("NBCF")
        )
        module.LoadCharacter(Player)
    else
        SpawnSelection:Clone().Parent = Player.PlayerGui
    end
end

---Prompts a Player to create a new character
---@param Player Player The Player to prompt
module.new = function(Player: Player)
    local CharacterCreation = CreationUI:Clone()
    CreationClient:Clone().Parent = CharacterCreation
    CharacterCreation.Parent = Player.PlayerGui
end

MessagingService:SubscribeAsync("NameRequest", function(message: table)
    local messageData = HttpService:JSONDecode(message.Data)
    if not messageData.ID then
        return warn(
            `{script}.MessagingService.SubscribeAsync.NameRequest: No ID \z
            found in request {message.Data}!`
        )
    end

    for i, Player in ipairs(Players:GetPlayers()) do
        if Player:GetAttribute("ID") == tonumber(messageData.ID) then
            if messageData.Status == "Approved" then
                local characterData = DataHandler.Get(
                    "Characters", tostring(messageData.ID)
                )
                if characterData then
                    Player:SetAttribute("FirstName", characterData.FirstName)
                    Player:SetAttribute("LastName", characterData.LastName)
                    Player:SetAttribute("Approved", true)

                    SendNotification:FireClient(Player, {
                        Title = "Name approved";
                        Text = "Your character's name has been approved!";
                        Duration = 10;
                    })
                end
            elseif messageData.Status == "Edited" then
                Player:SetAttribute("FirstName", messageData.FirstName)
                Player:SetAttribute("LastName", messageData.LastName)
                Player:SetAttribute("Approved", true)
                Player:SetAttribute("Edited", messageData.Reason)

                local EditedInterface = EditedUI:Clone()
                EditedClient:Clone().Parent = EditedInterface
                EditedInterface.Parent = Player.PlayerGui
            elseif messageData.Status == "Rejected" then
                Player:SetAttribute("FirstName", "Immigrant")
                Player:SetAttribute(
                    "LastName", `{Player.UserId}-{messageData.ID}`
                )
                Player:SetAttribute("Rejected", messageData.Reason)

                local RejectInterface = RejectUI:Clone()
                RejectClient:Clone().Parent = RejectInterface
                RejectInterface.Parent = Player.PlayerGui
            end

            local firstName = Player:GetAttribute("FirstName")
            local lastName = Player:GetAttribute("LastName")
            Player:SetAttribute("FullName", `{firstName} {lastName}`)
            break
        end
    end
end)
DeathHandler.CHPass(module)
return module