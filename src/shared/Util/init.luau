--This script contains general utility functions for server and client-side scripts
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local InventoryConfig = require(ReplicatedConfig.Inventory)
local MoneyConfig = require(ReplicatedConfig.Money)
local PoliceConfig = require(ReplicatedConfig.Police)

local module = {}

module.Boundaries = {
    Min = Vector3.new(math.huge, math.huge, math.huge),
    Max = Vector3.new(-math.huge, -math.huge, -math.huge)
}

module.DaysPerMonth = {
    31;
    28;
    31;
    30;
    31;
    30;
    31;
    31;
    30;
    31;
    30;
    31;
}

module.DefaultCFrames = {
    LeftShoulderC1 = CFrame.new(.5, .5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0);
    NeckC0 = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0);
    RightShoulderC1 = CFrame.new(-.5, .5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0);
}

module.EnglishNumbers = {
    [0] = "Zero";
    [1] = "One";
    [2] = "Two";
    [3] = "Three";
    [4] = "Four";
    [5] = "Five";
    [6] = "Six";
    [7] = "Seven";
    [8] = "Eight";
    [9] = "Nine";
    [10] = "Ten";
    [11] = "Eleven";
    [12] = "Twelve";
    [13] = "Thirteen";
    [14] = "Fourteen";
    [15] = "Fifteen";
    [16] = "Sixteen";
    [17] = "Seventeen";
    [18] = "Eighteen";
    [19] = "Nineteen";
    [20] = "Twenty";
}

module.JobTitles = {
    Bartender = "Bartender";
    Guardsman = "National Guard";
    Sanitation = "Sanitation Worker";
}

module.MaterialDensities = {
    ["Enum.Material.Air"] = 0.0012;
    ["Enum.Material.Asphalt"] = 2.32;
    ["Enum.Material.Brick"] = 2;
    ["Enum.Material.Cobblestone"] = 2.83;
    ["Enum.Material.Concrete"] = 2.4;
    ["Enum.Material.CorrodedMetal"] = 5.24;
    ["Enum.Material.CrackedLava"] = 3.1;
    ["Enum.Material.DiamondPlate"] = 8.03;
    ["Enum.Material.Fabric"] = 1.14;
    ["Enum.Material.Foil"] = 2.7;
    ["Enum.Material.ForceField"] = 8 * 10^13;
    ["Enum.Material.Glacier"] = 0.92;
    ["Enum.Material.Glass"] = 2.7;
    ["Enum.Material.Granite"] = 2.75;
    ["Enum.Material.Grass"] = 1.4;
    ["Enum.Material.Ground"] = 1.22;
    ["Enum.Material.Ice"] = 0.92;
    ["Enum.Material.LeafyGrass"] = 1.4;
    ["Enum.Material.Limestone"] = 1.5;
    ["Enum.Material.Marble"] = 2.64;
    ["Enum.Material.Metal"] = 7.87;
    ["Enum.Material.Mud"] = 1.84;

    --Density of glass, neon is a gas with low density, but contained in glass
    ["Enum.Material.Neon"] = 2.7;

    ["Enum.Material.Pavement"] = 2.32;
    ["Enum.Material.Pebble"] = 1.68;
    ["Enum.Material.Plastic"] = 0.92;
    ["Enum.Material.Rock"] = 2.75;
    ["Enum.Material.Salt"] = 2.16;
    ["Enum.Material.Sand"] = 1.55;
    ["Enum.Material.Sandstone"] = 2.42;
    ["Enum.Material.Slate"] = 2.69;
    ["Enum.Material.SmoothPlastic"] = 0.92;
    ["Enum.Material.Snow"] = 0.45;
    ["Enum.Material.Water"] = 1;
    ["Enum.Material.Wood"] = 0.59;
    ["Enum.Material.WoodPlanks"] = 0.34;

    Humanoid = 1.07;
}

module.Months = {
    "January";
    "February";
    "March";
    "April";
    "May";
    "June";
    "July";
    "August";
    "September";
    "October";
    "November";
    "December";
}

local MonthsShort = {
    "JAN";
    "FEB";
    "MAR";
    "APR";
    "MAY";
    "JUN";
    "JUL";
    "AUG";
    "SEP";
    "OCT";
    "NOV";
    "DEC";
}

module.TimeUnits = {
    {
        Length = 31536000;
        Name = "year"
    };
    {
        Length = 2592000;
        Name = "month"
    };
    {
        Length = 604800;
        Name = "week"
    };
    {
        Length = 86400;
        Name = "day"
    };
    {
        Length = 3600;
        Name = "hour"
    };
    {
        Length = 60;
        Name = "minute"
    };
    {
        Length = 1;
        Name = "second"
    };
}

local ValakMonthsShort = {
    "ИАН";
    "ПЕП";
    "МАЛ";
    "АПЕ";
    "МЕИ";
    "ИУН";
    "ИУЛ";
    "АУК";
    "КЕП";
    "ОКА";
    "НОВ";
    "КЕК";
}

module.ValakNumerals = {
    ["0"] = "•";
    ["1"] = "ı";
    ["2"] = "г";
    ["3"] = "т";
    ["4"] = "+";
}

module.Vowels = {
    A = true;
    E = true;
    I = true;
    O = true;
    U = true;
}

module.VowelSoundConsonants = {
    F = true;
    H = true;
    L = true;
    M = true;
    N = true;
    R = true;
    S = true;
    X = true;
}

---Attaches an accoutrement to a Character
---@param Character Model The Character to attach the Accoutrement to
---@param Accoutrement Accoutrement The Accoutrement to attach
module.AddAccoutrement = function(Character: Model, Accoutrement: Accoutrement)
    local function findFirstMatchingAttachment(Model: Model, name: string)
        for i, Child in ipairs(Model:GetChildren()) do
            if Child:IsA("Attachment") and Child.Name == name then
                return Child
            elseif not Child:IsA("Accoutrement") and not Child:IsA("Tool") then
                local FoundAttachment = findFirstMatchingAttachment(Child, name)
                if FoundAttachment then
                    return FoundAttachment
                end
            end
        end
    end

    Accoutrement.Parent = Character

    local Handle = Accoutrement:FindFirstChild("Handle")
    if Handle then
        local AccoutrementAttachment =
            Handle:FindFirstChildOfClass("Attachment")
        if AccoutrementAttachment then
            local CharacterAttachment = findFirstMatchingAttachment(
                Character, 
                AccoutrementAttachment.Name
            )
            if CharacterAttachment then
                module.CreateInstance("Weld", {
                    Part0 = CharacterAttachment.Parent;
                    Part1 = AccoutrementAttachment.Parent;
                    C0 = CharacterAttachment.CFrame;
                    C1 = AccoutrementAttachment.CFrame;
                    Parent = CharacterAttachment.Parent;
                })
            end
        else
            local Head = Character:FindFirstChild("Head")
            if Head then
                module.CreateInstance("Weld", {
                    C0 = CFrame.new(0, 0.5, 0);
                    C1 = Accoutrement.AttachmentPoint;
                    Name = "HeadWeld";
                    Part0 = Head;
                    Part1 = Handle;
                    Parent = Head;
                })
            end
        end
    end
end

---Determine whether to use the word "a" or "an" based on vowels
---@param text string The text preceding the particle
---@param notAcronym boolean Whether the text is in all caps and not an acronym
---@param capitalize boolean Whether to capitalize the particle
module.AOrAn = function(
    text: string, notAcronym: boolean, capitalize: boolean
): string
    if module.Vowels[text:upper():sub(1,1)] then
        return capitalize and "An" or "an"
    end

    if (not notAcronym) and (module.VowelSoundConsonants[text:sub(1,1)]) then
        local secondLetter: number = text:sub(2,2):byte()
        if
            (secondLetter > 64 and secondLetter < 91)
            or (secondLetter > 47 and secondLetter < 58)
        then
            return capitalize and "An" or "an"
        end
    end
    return capitalize and "A" or "a"
end

---Associate an ID with a name for a Player
---@param Player Player The Player to add the name association for
---@param id number The ID to associate with a name
---@param name string The name to associate with the ID
module.AssociateName = function(Player: Player, id: number, name: string)
    local associated: table = HttpService:JSONDecode(Player:GetAttribute(
        "NameAssociations"
    ))
    associated[tostring(id)] = name
    Player:SetAttribute("NameAssociations", HttpService:JSONEncode(associated))
end

---Determines the lowest amount of bills required to make a stack
---@param value number The value to create a stack for
---@return table
module.BillsRequired = function(value: number)
    if value < 1 then
        return {}
    end

    local bills = {}
    for i, denomination in ipairs(MoneyConfig.Denominations) do
        local billCount = math.floor(value / denomination)
        table.move(
            table.create(billCount, denomination),
            1, billCount, #bills + 1, bills
        )
        value %= denomination

        if value == 0 then
            break
        end
    end

    return bills
end

---Colors a hair by VertexColor
---@param Hair Accoutrement The hair to color
---@param color Color3 The color of the hair
module.ColorHair = function(Hair: Accoutrement, color: Color3)
    local Handle = Hair.Handle
    local Mesh = Handle:FindFirstChildWhichIsA("SpecialMesh")
    Mesh.VertexColor = Vector3.new(color.R, color.G, color.B)
end

---Transfers the name, attributes and children of an Instance to a new Instance
---@param Original Instance The original Instance to convert
---@param to string The ClassName of the Instance to convert to
---@return Instance
module.ConvertTo = function(Original: Instance, to: string)
    local New = module.CreateInstance(to, {
        Name = Original.Name;
    }, Original:GetAttributes())

    for i, Child in ipairs(Original:GetChildren()) do
        Child.Parent = New
    end
    
    Original:Destroy()
    return New
end

---Creates an Instance with given properties and attributes in one line
---@param ClassName string The ClassName of the Instance to create
---@param properties table The properties of the Instance
---@param attributes table The attributes of the Instance
---@return Instance
module.CreateInstance = function(
    ClassName: string,
    properties: table,
    attributes: table
)
    properties = properties or {}
    attributes = attributes or {}

    local Created = Instance.new(ClassName)

    for property, value in pairs(properties) do
        --Always sets Parent last, for performance reasons
        if property ~= "Parent" then
            Created[property] = value
        end
    end

    for attribute, value in pairs(attributes) do
        Created:SetAttribute(attribute, value)
    end

    Created.Parent = properties.Parent
    return Created
end

---Determine what day of the week a given date is on
---@param day number The day of the month (1-31)
---@param month number The month (1-12)
---@param year number The year (>0)
---@return number
module.DayOfWeek = function(day: number, month: number, year: number)
    local daysSince = 0
    for i = 1, year - 1 do
        daysSince += module.LeapYear(i) and 366 or 365
    end

    for i = 1, month - 1 do
        daysSince += (month == 2 and module.LeapYear(year) and 29)
            or module.DaysPerMonth[i]
    end
    daysSince += day

    return daysSince % 7
end

---Destroy an instance after a certain amount of time has passed
---@param ToRemove Instance The instance to destroy
---@param time number The amount of time to wait (defaults to 1000)
module.Debris = function(ToRemove: Instance, time: number)
    task.spawn(function()
        CollectionService:AddTag(ToRemove, "Debris")
        task.wait(time or 1000)
        ToRemove:Destroy()
    end)
end

---Ensures a number input is in a range, and loops around if it is not
---@param input number The number to enforce the range of
---@param min number The minimum value
---@param max number The maximum value
---@return number
module.EnforceRange = function(input: number, min: number, max: number)
    if input < min then
        input = module.EnforceRange(max - (min - input - 1), min, max)
    end

    if input > max then
        input = module.EnforceRange(min + (input - max - 1), min, max)
    end

    return input
end

---Convert a number to an English string
---CURRENTLY ONLY PROGRAMMED FOR 0-20!
---@param input number The number to convert to English
---@return string
module.EnglishNumber = function(input: number)
    return module.EnglishNumbers[input]
end

---Convert a date for use in documentation
---@param day number The day of the month to display
---@param month number The month to display (1-12)
---@param year number The year to display
---@return string
module.EngVlkDDMMMYY = function(day: number, month: number, year: number)
    return `{day} {MonthsShort[month]} / {ValakMonthsShort[month]} {year}`
end

---Export the contents of an inventory into a DS-compatible table
---@param Inventory Folder The inventory to export
---@param validate function Any additional validation to perform on an item
---@return table
module.ExportInventory = function(
    Inventory: Folder, validate: (table) -> (boolean)
)
    local export = {}

    for i, Item in ipairs(Inventory:GetChildren()) do
        local attributes = Item:GetAttributes()
        
        for j, dontSave in ipairs(InventoryConfig.DontSave) do
            attributes[dontSave] = nil
        end

        if validate and not validate(attributes) then
            continue
        end

        table.insert(export, {
            GUID = Item.Name;
            FileName = attributes.FileName;
            Attributes = attributes;
        })
    end

    return export
end

---Find the first child of a class with the given attributes
---@param Parent Instance The parent to search for the child under
---@param class string The class of the child to search for
---@param attributes table The attribues of the child to search for
---@return Instance
module.FindFirstChildOfClassWithAttributes = function(
    Parent: Instance, class: string, attributes: table
): Instance
    for i, Child: Instance in ipairs(Parent:GetChildren()) do
        if Child.ClassName ~= class then
            continue
        end
        local good = true

        for attribute: string, value in pairs(attributes) do
            if Child:GetAttribute(attribute) ~= value then
                good = false
                break
            end
        end

        if good then
            return Child
        end
    end
end

---Find the first child of which is a given type with the given attributes
---@param Parent Instance The parent to search for the child under
---@param isa string The type of the child to search for
---@param attributes table The attribues of the child to search for
---@return Instance
module.FindFirstChildWhichIsAWithAttributes = function(
    Parent: Instance, isa: string, attributes: table
): Instance
    for i, Child: Instance in ipairs(Parent:GetChildren()) do
        if not Child:IsA(isa) then
            continue
        end
        local good = true

        for attribute: string, value in pairs(attributes) do
            if Child:GetAttribute(attribute) ~= value then
                good = false
                break
            end
        end

        if good then
            return Child
        end
    end
end

---Find the first child with the given attributes
---@param Parent Instance The parent to search for the child under
---@param attributes table The attribues of the child to search for
---@return Instance
module.FindFirstChildWithAttributes = function(
    Parent: Instance, attributes: table
): Instance
    for i, Child: Instance in ipairs(Parent:GetChildren()) do
        local good = true

        for attribute: string, value in pairs(attributes) do
            if Child:GetAttribute(attribute) ~= value then
                good = false
                break
            end
        end

        if good then
            return Child
        end
    end
end

---Determine how many free slots are available in an inventory for a given item
---@param Player Player The Player whose inventory to check
---@param slots table The slots that the item can be put into
---@param excludeHand boolean Whether to exclude "Equipped" as a possible slot
---@return number
module.FreeSlots = function(Player: Player, slots: table, excludeHand: boolean)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        warn(`{script}.FreeSlots: No inventory found for {Player}`)
        return 0
    end

    local free = 0
    for i, slot in ipairs(InventoryConfig.Slots) do
        if slots[InventoryConfig.SlotInfo[slot].Type]
            and not Inventory:GetAttribute(slot)
        then
            free += 1
        end
    end

    if not (excludeHand or Inventory:GetAttribute("Equipped")) then
        free += 1
    end

    print(`{script}.FreeSlots: {Player} has {free} inventory slots available.`)
    return free
end

---Return the age of a character
---@param Player Player The Player to check the character age of
---@return number
module.GetAge = function(Player: Player)
    local date = os.date("!*t", os.time() - 36000)

    local age = date.year - Player:GetAttribute("BirthYear")
    if
        date.month < Player:GetAttribute("BirthMonth")
        or (
            date.month == Player:GetAttribute("BirthMonth")
            and date.day < Player:GetAttribute("BirthDay")
        )
    then
        age -= 1
    end

    return age
end

---Calculates the minimum and maximum boundaries of the map
---@return table
module.GetBoundaries = function()
    for i, Child in ipairs(workspace.Map:GetDescendants()) do
        if Child:IsA("BasePart") then
            module.Boundaries.Min = Vector3.new(
                math.min(Child.Position.X, module.Boundaries.Min.X),
                math.min(Child.Position.Y, module.Boundaries.Min.Y),
                math.min(Child.Position.Z, module.Boundaries.Min.Z)
            )

            module.Boundaries.Max = Vector3.new(
                math.max(Child.Position.X, module.Boundaries.Max.X),
                math.max(Child.Position.Y, module.Boundaries.Max.Y),
                math.max(Child.Position.Z, module.Boundaries.Max.Z)
            )
        end
    end
    print(
        `{script}.GetBoundaries: Boundaries set to \z
        min: {module.Boundaries.Min}, max: {module.Boundaries.Max}`
    )
    return module.Boundaries
end
module.GetBoundaries()

---Find all block-shaped instances in the workspace
---@return table
module.GetBricks = function()
    module.Bricks = module.Bricks or {}
    if #module.Bricks == 0 then
        ---Check if a instance is a block-shaped part, and add it to the cache
        ---@param Child Instance The instance to check
        local function addBlock(Child: Instance)
            if
                Child:IsA("Part")
                and Child.Shape == Enum.PartType.Block
                and Child.Transparency < 1
                and not Child:FindFirstChildWhichIsA("FileMesh")
            then
                table.insert(module.Bricks, Child)
                Child.AncestryChanged:Connect(function()
                    if not Child:IsDescendantOf(workspace) then
                        for i, Brick in ipairs(module.Bricks) do
                            if Brick == Child then
                                table.remove(module.Bricks, i)
                                break
                            end
                        end
                    end
                end)
            end
        end

        for i, Child in ipairs(workspace:GetDescendants()) do
            addBlock(Child)
        end

        workspace.DescendantAdded:Connect(addBlock)
    end
    return module.Bricks
end

---Get the NormalId from a normal vector
---@param Part BasePart The part to get the NormalId of
---@param normalVector Vector3 The normal vector to convert
---@return Enum.NormalId
module.GetNormalId = function(Part: BasePart, normalVector: Vector3)
    normalVector = Part.CFrame:VectorToObjectSpace(normalVector)

    for i, normalId in ipairs(Enum.NormalId:GetEnumItems()) do
        if normalVector:FuzzyEq(Vector3.fromNormalId(normalId)) then
            return normalId
        end
    end
end

---Get a Player's TIB score
---@param Player Player The Player to get the TIB score of
---@return number
module.GetTIB = function(Player: Player)
    return math.floor((
        Player:GetAttribute("Playtime")
        + (os.time() - Player:GetAttribute("LoadedAt"))
    ) / 3600)
end

---Get the total weight of the contents of a Player's inventory
---@param Player Player The Player to get the inventory weight of
---@return number
module.GetWeight = function(Player: Player)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        warn(`{script}.GetWeight: No inventory found for {Player}`)
        return 0
    end

    local weight = 0

    for i, Tool in ipairs(Inventory:GetChildren()) do
        weight += Tool:GetAttribute("Weight") or 0
    end

    local Equipped = Player.Character
        and Player.Character:FindFirstChildOfClass("Tool")
    if Equipped then
        weight += Equipped:GetAttribute("Weight") or 0
    end

    return weight
end

module.SurfaceSpaces = {
    [Enum.NormalId.Back] = {"X", "-Y"};
    [Enum.NormalId.Bottom] = {"-Z", "-X"};
    [Enum.NormalId.Front] = {"-X", "-Y"};
    [Enum.NormalId.Left] = {"Z", "-Y"};
    [Enum.NormalId.Right] = {"-Z", "-Y"};
    [Enum.NormalId.Top] = {"-Z", "X"};
}

---Get the position for a SurfaceGui given a world position
---@param Hit Instance The part to apply the Gui to the surface of
---@param at Vector3 The world position to apply the surface at
---@param surface Enum.NormalId The surface hit
---@return UDim2
module.GuiPos = function(Hit: Instance, at: Vector3, surface: Enum.NormalId)
    local useDimensions = module.SurfaceSpaces[surface]
    if not useDimensions then
        return warn(`{script}.GuiPos: Unknown surface {surface}!`)
    end
    local objectSpace = Hit.CFrame:ToObjectSpace(CFrame.new(at))

    local coords = {}
    for i, dim in ipairs(useDimensions) do
        local negative
        if dim:sub(1, 1) == "-" then
            negative = true
            dim = dim:sub(2)
        end

        local pos =  (
            objectSpace.Position[dim] + Hit.Size[dim] / 2
        ) / Hit.Size[dim]

        if negative then
            pos = 1 - pos
        end

        table.insert(coords, pos)
    end

    return UDim2.fromScale(unpack(coords))
end

---Ensures only positive integers are entered to the property of some object
---@param Restrict Instance The object to restrict
---@param property string The property to restrict the value of (default "Text")
---@param commaSeparate boolean Whether to add commas in thousands places
---@param additional function Any additional restrictions to be applied
---@return RBXScriptConnection
module.InputPosInt = function(
    Restrict: Instance,
    property: string,
    commaSeparate: boolean,
    additional: (number) -> (number)
): RBXScriptConnection
    property = property or "Text"

    local updating
    return Restrict:GetPropertyChangedSignal(property):Connect(function()
        if #Restrict[property] == 0 or updating then
            return
        end
        updating = true

        local lengthWas = #Restrict[property]
        local number = (commaSeparate and Restrict[property]:gsub(",", ""))
            or Restrict[property]
        number = tonumber(number)

        if not number then
            Restrict[property] = ""
            updating = false
            return
        end

        --Removes negative numbers and decimals
        number = math.floor(math.abs(number))

        if additional then
            number = additional(number)
        end

        Restrict[property] = (commaSeparate and module.ThousandsSeparate(number))
            or number

        if Restrict:IsA("TextBox") and lengthWas < #Restrict[property] then
            Restrict.CursorPosition += #Restrict[property] - lengthWas
        end

        updating = false
    end)
end

---Calculates the total numeric value of stacks of cash in an inventory
---@param Player Player The Player to check the inventory of
---@param includeEquipped boolean Whether to also include the item being held
---@param includeWallet boolean Whether to also include the cash in the wallet
---@return number
---@return table
module.InventoryBalance = function(
    Player: Player,
    includeEquipped: boolean,
    includeWallet: boolean
)
    local Inventory = Player.PlayerGui:FindFirstChild("Inventory")
    if not Inventory then
        return 0, warn(
            `{script}.InventoryBalance: No inventory found for Player {Player}!`
        )
    end

    local balance = 0
    local stacks = {}
    if includeEquipped then
        local Tool = Inventory:GetAttribute("Equipped")
            and Player.Character
            and Player.Character:FindFirstChild(Inventory:GetAttribute(
                "Equipped")
            )
        if Tool and (
            Tool:GetAttribute("FileName") == "Cash"
            or (includeWallet and Tool:GetAttribute("FileName") == "Wallet")
        ) then
            balance += Tool:GetAttribute(
                    (Tool:GetAttribute("FileName") == "Wallet" and "Balance")
                    or "Value"
                ) or warn(
                    `{script}.InventoryBalance: \z
                    No value found for equipped cash item with GUID {Tool}`
                )
                or 0
            table.insert(stacks, Tool)
        end
    end

    for i, Child in ipairs(Inventory:GetChildren()) do
        if Child:GetAttribute("FileName") == "Cash"
            or (includeWallet and Child:GetAttribute("FileName") == "Wallet")
        then
            balance += Child:GetAttribute(
                    (Child:GetAttribute("FileName") == "Wallet" and "Balance")
                    or "Value"
                ) or warn(
                    `{script}.InventoryBalance: \z
                    No value found for cash item with GUID {Child}`
                )
                or 0
            table.insert(stacks, Child)
        end
    end

    return balance, stacks
end

---Convert the stored occupation value to a job title
---@param charData table The character data to display
---@return string
module.JobTitle = function(charData: table): string
    local job: string = charData.Occupation
    if (not job) or job == "Unemployed" then
        return "Unemployed"
    end

    if job == "Sanitation" and charData.Ethnicity == "Italian" then
        return "Waste Management"
    end

    local replacement: string = module.JobTitles[job]
    if replacement then
        return replacement
    end

    if job == "MIA" then
        local division: string = charData.PoliceDivision
        local rank: number = charData.PoliceRank
        return `{(rank < 6 and (not (rank == 2 and division == "Investigative")) --Just write detective as detective, instead of "Investigative Detective"
            and `{division} `) or ""}\z
            {rank == 2 and PoliceConfig.OfficerTitles[division]
            or PoliceConfig.Ranks[rank]}`
    end

    return job
end

---Returns the keys of a dictionary as an array
---@param input table The dictionary to get the keys of
---@return table
module.KeysTable = function(input: table)
    local output = {}
    for key, value in pairs(input) do
        table.insert(output, key)
    end
    return output
end

---Gets the kinetic energy of an object
---@param mass number The mass of the object (kilograms)
---@param velocity number The velocity of the object (meters per second)
---@return number
module.KineticEnergy = function(mass: number, velocity: number)
    return (mass / 2) * (velocity ^ 2)
end

---Checks if a given year is a leap year
---@param year number The year to check
---@return boolean
module.LeapYear = function(year: number)
    return year % 4 == 0 and (year % 100 > 0 or year % 400 == 0)
end

---Converts a distance in meters to studs
---@param m number The distance in meters
---@return number
module.MetersToStuds = function(m: number)
    return m * 4.101
end

---Gets the momentum of an object
---@param mass number The mass of the object (kilograms)
---@param velocity number The velocity of the object (meters per second)
---@return number
module.Momentum = function(mass: number, velocity: number)
    return mass * velocity
end

---Gets the force of a gun shot at the muzzle
---@param mass number The mass of each projectile
---@param velocity number The muzzle velocity of the weapon
---@param count number The number of projectiles
---@return any
module.MuzzleForce = function(mass: number, velocity: number, count: number)
    return mass * (count or 1) * velocity
end

---Add an ordinal number suffix to a number
---@param number number The number to add the suffix to
---@return string
module.Ordinal = function(number: number)
    number = tostring(number)
    if number:sub(#number) == "1" and number:sub(#number - 1) ~= "11" then
        return `{number}st`
    elseif number:sub(#number) == "2" and number:sub(#number - 1) ~= "12" then
        return `{number}nd`
    elseif number:sub(#number) == "3" and number:sub(#number - 1) ~= "13" then
        return `{number}rd`
    else
        return `{number}th`
    end
end

---Return a random element from a table
---@param from table The table to pull from
---@return any
---@return number
module.RandomFrom = function(from: table)
    local key = math.random(1, #from)
    return from[key], key
end

---Converts a table into an English readable list (apples, bananas, and oranges)
---@param list table The list to convert
---@return string
module.ReadableList = function(list: table)
    if #list == 0 then
        return ""
    elseif #list == 1 then
        return tostring(list[1])
    elseif #list == 2 then
        return `{list[1]} and {list[2]}`
    else
        local output = ""
        for i, element in ipairs(list) do
            output ..= tostring(element)
            if i == #list - 1 then
                output ..= ", and "
            elseif i ~= #list then
                output ..= ", "
            end
        end
        return output
    end
end

---Converts a number of seconds to a simplified time (60 seconds -> 1 minute)
---@param time number The number of seconds
---@param exact boolean Whether to write out an exact time (5 minutes 3 seconds)
---@return string
module.ReadableTime = function(time: number, exact: boolean)
    if time <= 0 then
        return "0 seconds"
    end

    if exact then
        local output = {}
        for i, unit in ipairs(module.TimeUnits) do
            local length = math.floor(time / unit.Length)
            if length > 0 then
                table.insert(
                    output, `{length} {unit.Name}{(length == 1 and "") or "s"}`
                )
                time -= length * unit.Length
            end
        end
        return module.ReadableList(output)
    else
        for i, unit in ipairs(module.TimeUnits) do
            local length = math.floor(time / unit.Length)
            if length > 0 then
                return `{length} {unit.Name}{(length == 1 and "") or "s"}`
            end
        end
    end
end

---Apply recoil to a camera
---@param force number The amount of force being applied
---@param weight number The weight of the object the force is being applied to
---@param Camera Camera The Camera to apply the recoil to
---@param Player Player The Player to factor recoil modifiers for (optional)
module.Recoil = function(
    force: number, weight: number, Camera: Camera, Player: Player
)
    local recoil = force / (weight * 1000)

    if Player then
        local age = module.GetAge(Player)
        if age < 16 or age > 60 then
            recoil *= 2
        end

        local Humanoid: Humanoid = Player.Character
            and Player.Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            if (Humanoid:GetAttribute("Prone") or 0) > 0 then
                --prone
                recoil *= 0.25
            elseif (Humanoid:GetAttribute("Crouch") or 0) > 0 then
                --crouching
                recoil *= 0.5
            end
        end
    end

    local hStep = math.random(
        -(recoil / 2) * 10, (recoil / 2) * 10
    ) / 10
    for i = 1, 5 do
        Camera.CFrame *= CFrame.Angles(
            math.rad(recoil / 5), math.rad(hStep / 5), 0)
        RunService.RenderStepped:Wait()
    end
end

---Removes whitespace from the beginning and end of a string
---@param input string The string to clean
---@return string
module.RemoveWhitespace = function(input: string)
    while input:sub(1, 1) == " " do
        input = input:sub(2)
    end

    while input:sub(#input) == " " do
        input = input:sub(1, #input - 1)
    end

    return input
end

---Rounds a number to a given number of decimal places
---@param input number The number to round
---@param places number The number of decimal places to round to
---@return number
module.Round = function(input: number, places: number)
    input *= 10 ^ places

    return math.round(input) / 10 ^ places
end

---Fill in the ID Gui for a given Player
---@param Player Player The Player to get the data from
---@param ID Frame The ID to write the data on
module.SetupID = function(Player: Player, ID: Frame)
    local BirthdayDisplay = ID:WaitForChild("BirthdayDisplay")
    local ExpireDisplay = ID:WaitForChild("ExpireDisplay")
    local IssueDisplay = ID:WaitForChild("IssueDisplay")
    local NameDisplay = ID:WaitForChild("NameDisplay")
    local NumberDisplay = ID:WaitForChild("NumberDisplay")
    local SexDisplay = ID:WaitForChild("SexDisplay")
    local SurnameDisplay = ID:WaitForChild("SurnameDisplay")

    local gender = Player:GetAttribute("Gender")

    local issued = Player:GetAttribute("CitizenshipAt")
    local issuedDate = os.date("!*t", issued)
    local expires = issued + 315360000
    local expiresDate = os.date("!*t", expires)

    BirthdayDisplay.Text = module.EngVlkDDMMMYY(
        Player:GetAttribute("BirthDay"),
        Player:GetAttribute("BirthMonth"),
        Player:GetAttribute("BirthYear")
    )
    ExpireDisplay.Text = module.EngVlkDDMMMYY(
        expiresDate.day,
        expiresDate.month,
        expiresDate.year
    )
    IssueDisplay.Text = module.EngVlkDDMMMYY(
        issuedDate.day,
        issuedDate.month,
        issuedDate.year
    )
    NameDisplay.Text = Player:GetAttribute("FirstName"):upper()
    NumberDisplay.Text = `{Player.UserId}-{Player:GetAttribute("ID")}`
    SexDisplay.Text = `{gender and "F" or "M"} / {gender and "Ф" or "Т"}`
    SurnameDisplay.Text = Player:GetAttribute("LastName"):upper()
end

---Splits a string into a table according to a regular expression pattern
---@param input string The string to split
---@param pattern string The pattern to split with (defaults to %S+)
---@return any
module.SplitString = function(input: string, pattern: string)
    local words = {}
	for word in input:gmatch(pattern or "%S+") do
		table.insert(words, word)
	end
	return words
end

---Check if a string starts with another string
---@param source string The string to check
---@param search string The string to match the start with
---@return boolean
module.StartsWith = function(source: string, search: string)
    return source:sub(1, #search) == search
end

---Determines the distance a projectile will penetrate through a mass before stopping
---@param crossSection number The cross-sectional area of the projectile
---@param dragCoef number The drag coefficient of the projectile
---@param mass number The mass of the projectile
---@param velocity number The velocity of the projectile
---@param density number The density of the material being penetrated
---@return number
module.StoppingDistance = function(
    crossSection: number,
    dragCoef: number,
    mass: number,
    velocity: number,
    density: number
)
    local dragForce = 0.5 * density * (velocity ^ 2) * dragCoef * crossSection
    return (mass / (dragForce / velocity)) * velocity
end

---Separate every three digits in a number with commas for display
---@param input number The number to separate
---@param by string The character to separate by (default ,)
---@return string
module.ThousandsSeparate = function(input: number, by: string)
    local negative: boolean = input < 0
    input = tostring(math.abs(input))
    by = by or ","

    if #input < 4 then
        return input
    end

    local needed = math.ceil(#input/3)
    local output = ""
    for i = 1, needed do
        output = `{(i == needed and "") or by}{input:sub(#input - 2)}{output}`
        input = input:sub(1, #input - 3)
    end
    return `{negative and "-" or ""}{output}`
end

---Converts a number to a given base
---@param input number The number to convert
---@param base number The base to convert to
---@return string
module.ToBase = function(input: number, base: number)
    local output = ""

    repeat
        output = (input % base) .. output
        input = math.floor(input / base)
    until input == 0

    return output
end

---Convert a number to Valakese numerals
---@param input number The number to convert
---@return any
module.ToValak = function(input: number)
    local base5 = module.ToBase(input, 5)
    local valak = ""
    for i = 1, #base5 do
        valak ..= module.ValakNumerals[base5:sub(i, i)]
    end
    return valak
end

---Writes out text character by character
---@param text string The text to type out
---@param WriteTo Instance The Instance to write the text to
---@param property string The property to write the text to (default "Text")
---@param delay number The delay in seconds in between characters (default 0.02)
---@param dontReset boolean Whether to not reset the text before writing
---@param async boolean Whether to run the function asynchronously
---@param waitAfter number The amount of time to wait after finishing writing
module.Typewriter = function(
    text: string,
    WriteTo: Instance,
    property: string,
    delay: number,
    dontReset: boolean,
    async: boolean,
    waitAfter: number
)
    property = property or "Text"
    delay = delay or 0.02
    waitAfter = waitAfter or math.ceil(#text / 30)

    if not dontReset then
        WriteTo[property] = ""
    end
    
    local typewriter = (WriteTo:GetAttribute("ActiveTypewriter") or 0) + 1
    WriteTo:SetAttribute("ActiveTypewriter", typewriter)

    local skip: boolean = false

    local inputBegan: RBXScriptConnection
    if RunService:IsClient() then
        inputBegan = UserInputService.InputBegan:Connect(
            function(input: InputObject, gameProcessed: boolean)
                if gameProcessed then
                    return
                end

                if input.KeyCode == Enum.KeyCode.Return then
                    skip = true
                end
            end
        )
    end

    local function write()
        for i = 1, #text do
            if WriteTo:GetAttribute("ActiveTypewriter") ~= typewriter then
                return
            end

            if skip then
                skip = false
                WriteTo[property] = text
                break
            end
            
            WriteTo[property] = WriteTo[property] .. text:sub(i, i)
            task.wait(delay)
        end
        
        if async and inputBegan then
            inputBegan:Disconnect()
        end
    end
    if async then
        task.spawn(write)
    else
        write()
        local waitUntil = os.time() + waitAfter
        while skip == false and os.time() < waitUntil do
            task.wait()
        end
        if inputBegan then
            inputBegan:Disconnect()
        end
    end
end

---Weld all the children of an Instance to a PrimaryPart
---@param Model Instance The Instance to weld the children of
---@param PrimaryPart BasePart The part to weld the children to
---@param unanchor boolean Whether to unanchor welded parts
---@param descendants boolean Whether to weld descendants instead of children
module.WeldChildren = function(
    Model: Instance,
    PrimaryPart: BasePart,
    unanchor: boolean,
    descendants: boolean
)
    for i, Child in ipairs(
        descendants and Model:GetDescendants() or Model:GetChildren()
    ) do
        if Child:IsA("BasePart") then
            if Child ~= PrimaryPart then
                module.CreateInstance("ManualWeld", {
                    C0 = PrimaryPart.CFrame:Inverse() * Child.CFrame;
                    Part0 = PrimaryPart;
                    Part1 = Child;
                    Parent = Child;
                })
            end

            if unanchor then
                Child.Anchored = false
            end
        end
    end
end

---Weld one part to another
---@param Object BasePart The part to weld
---@param Target BasePart The part for the object to be welded to
---@param target CFrame The CFrame to weld the object at (or Target's inverse)
---@return ManualWeld
module.WeldTo = function(Object: BasePart, Target: BasePart, target: CFrame)
    return module.CreateInstance("ManualWeld", {
        C0 = (target or Target.CFrame:Inverse()) * Object.CFrame;
        Part0 = Target;
        Part1 = Object;
        Parent = Target;
    })
end

return module