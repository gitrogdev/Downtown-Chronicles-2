--Handles all home ownership and sales on the server
local BadgeService = game:GetService("BadgeService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local AddressOverrides = require(script.Addresses)
local DuplicateClient = script.DuplicateKeys
local ListingsClient = script.PropertyListings
local ResidenceConfig = require(script.Residences)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ChangeLock = ReplicatedCommunication.ChangeLock
local DuplicateKey = ReplicatedCommunication.DuplicateKey
local GetKeysFromWarrant = ReplicatedCommunication.GetKeysFromWarrant
local GetSpawns = ReplicatedCommunication.GetSpawns
local GiveKey = ReplicatedCommunication.GiveKey
local HasResidence = ReplicatedCommunication.HasResidence
local PassBack = ReplicatedCommunication.PassBack
local PayRent = ReplicatedCommunication.PayRent
local PropertyListings = ReplicatedCommunication.PropertyListings
local RentDue = ReplicatedCommunication.RentDue
local ResidenceOwner = ReplicatedCommunication.ResidenceOwner
local SendNotification = ReplicatedCommunication.SendNotification
local SignRental = ReplicatedCommunication.SignRental

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local MoneyHandler = require(ServerScripts.Money)
local ServerConfig = ServerScripts.Configuration
local StorageHandler = require(ServerScripts.Storage)
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local BadgesIds = require(ServerConfig.Badges)
local PlaceIds = require(ServerConfig.Places)

local PrivateStorage = ServerStorage.PrivateStorage
local UIStorage = ServerStorage.UserInterface

local DuplicateKeyGui = UIStorage.DuplicateKeys
local PropertyGui = UIStorage.PropertyGui

local residences = {}

---Give a police officer the keys to residences with a search warrant
---@param Player Player The Player requesting the keys
---@return any
GetKeysFromWarrant.OnServerInvoke = function(Player: Player): string
    local searchWarrants = Player:GetAttribute("SearchWarrants") or "[]"
    if searchWarrants == "" or searchWarrants == "[]" then
        return "Invalid", warn(
            `{script}.GetKeysFromWarrant.OnServerInvoke: No valid search \z
            warrants found for {Player}!`
        )
    end

    local issued = 0
    for i, warrant in ipairs(HttpService:JSONDecode(searchWarrants)) do
        local key = warrant.Building
        if warrant.Apartment then
            key ..= `Apt{warrant.Apartment}`
        end

        local buildingConfig = ResidenceConfig[warrant.Building]
        if not buildingConfig then
            warn(
                `{script}.GetKeysFromWarrant.OnServerInvoke: Unable to find \z
                config for building {warrant.Building}!`
            )
            continue
        end

        local buildings = residences[buildingConfig.State]
        if not buildings then
            warn(
                `{script}.GetKeysFromWarrant.OnServerInvoke: Unable to find \z
                residential buildings in the {buildingConfig.State}!`
            )
            continue
        end

        local units = buildings[warrant.Building]
        if not units then
            warn(
                `{script}.GetKeysFromWarrant.OnServerInvoke: No units found \z
                in the building {warrant.Building}!`
            )
            continue
        end

        local unit = units[key]
        if not unit then
            warn(
                `{script}.GetKeysFromWarrant.OnServerInvoke: No unit found \z
                with key {key}!`
            )
            continue
        end

        table.insert(unit.HomeKeys, Player:GetAttribute("ID"))
        table.insert(unit.StorageKeys, Player:GetAttribute("ID"))
        issued += 1

        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player}, ID: \z
            {Player:GetAttribute("ID")}) has received the keys to apartment \z
            {unit.Apartment} at {ResidenceConfig[unit.Building].Address} from \z
            the locksmith.`,
            "PropertyLog"
        )
    end
    Player:SetAttribute("SearchWarrants", "[]")

    if issued > 0 then
        return true
    else return "Invalid"
    end
end

---Get a list of the apartments that a player has access to
---@param Player Player The Player to get the spawns of
---@return table
GetSpawns.OnServerInvoke = function(Player: Player)
    local id = Player:GetAttribute("ID")
    if not id then
        return warn(
            `{script}.GetSpawns.OnServerInvoke: {Player} does not have a \z
            character loaded!`
        )
    end

    local accessTo = {}
    for state, buildings in pairs(residences) do
        for building, units in pairs(buildings) do
            for buildingKey, data in pairs(units) do
                local hasAccess
                if data.Owner == Player:GetAttribute("ID") then
                    hasAccess = true
                else
                    for i, roommate in ipairs(data.HomeKeys) do
                        if roommate == id then
                            hasAccess = true
                            break
                        end
                    end
                end

                if hasAccess then
                    table.insert(accessTo, {
                        Building = data.Building;
                        Unit = data.Apartment;
                    })
                end
            end
        end
    end
    return accessTo
end

---Pay the due rent for a Player's apartment
---@param Player Player The Player requesting the property listings
---@return boolean
PayRent.OnServerInvoke = function(Player: Player)
    local state = Player:GetAttribute("Citizenship")
    local buildings = residences[state]
    if not buildings then
        return warn(
            `{script}.PayRent.OnServerInvoke: {Player} is not a citizen of \z
            a state with residences available!\z
            ({Player:GetAttribute("Citizenship")})`
        )
    end

    local building, key
    for checkBuilding, units in pairs(buildings) do
        for checkKey, data in pairs(units) do
            if data.Owner == Player:GetAttribute("ID") then
                if data.RentDue < os.time() then
                    building = checkBuilding
                    key = checkKey
                end
                break
            end
        end
    end

    if not (building and key) then
        return warn(
            `{script}.PayRent.OnServerInvoke: {Player} does not have a place \z
            of residence where rent is currently due!`
        )
    end

    local buildingConfig = ResidenceConfig[building]
    if not buildingConfig then
        return warn(
            `{script}.PayRent.OnServerInvoke: Unable to find building config \z
            for building {building}!`
        )
    end

    local price = buildingConfig.Price
    if not MoneyHandler.Charge(Player, price, "Card") then
        if not MoneyHandler.Charge(Player, price, "Cash") then
            return "Insufficient", warn(
                `{script}.PayRent.OnServerInvoke: {Player} does not have \z
                enough money to pay the monthly rent for {building}! (₲\z
                {Util.ThousandsSeparate(price)} required.)`
            )
        end
    end

    local unitData = residences[state][building][key]
    unitData.RentDue += 2592000

    WebhookHandler.Post(
        `{Player:GetAttribute("FullName")} ({Player}, ID: \z
        {Player:GetAttribute("ID")}) has paid the rent for their apartment at \z
        {buildingConfig.Address} in the amount of \z
        ₲{Util.ThousandsSeparate(price)}.`,
        "PropertyLog"
    )

    return true
end

local module = {}

---Change the locks of a player's apartment or storage
---@param Player Player The Player changing the lock
---@param lock string The type of lock being changed (Home or Storage)
---@return any
ChangeLock.OnServerInvoke = function(Player: Player, lock: string)
    if not (lock == "Home" or lock == "Storage") then
        return warn(
            `{script}.ChangeLock.OnServerInvoke: {Player} attempted to change \z
            an unknown lock type ({lock})!`
        )
    end

    if not module.HasResidence(Player) then
        return warn(
            `{script}.ChangeLock.OnServerInvoke: {Player} attempted to \z
            change a {lock} lock, but does not have a place of residence!`
        )
    end

    if not MoneyHandler.Charge(Player, 10000, "Card") then
        if not MoneyHandler.Charge(Player, 10000, "Cash") then
            return warn(
                `{script}.ChangeLock.OnServerInvoke: {Player} does not have \z
                enough money to change the locks!`
            )
        end
    end

    for state, buildings in pairs(residences) do
        for building, units in pairs(buildings) do
            for buildingKey, data in pairs(units) do
                if data.Owner == Player:GetAttribute("ID") then
                    data[`{lock}Keys`] = {}
                    WebhookHandler.Post(
                        `{Player:GetAttribute("FullName")} ({Player}, ID: \z
                        {Player:GetAttribute("ID")}) has changed the {lock} \z
                        lock at apartment {data.Apartment} at \z
                        {ResidenceConfig[data.Building].Address}.`,
                        "PropertyLog"
                    )
                    return true
                end
            end
        end
    end

    return warn(
        `{script}.ChangeLock.OnServerInvoke: Unable to change {Player}'s \z
        {lock} lock!`
    )
end

---Set up the GUI for duplicating the keys of a player's residence
---@param Player Player The Player requesting to duplicate the key
---@param key string The type of key being duplicated (Home or Storage)
---@return string
DuplicateKey.OnServerInvoke = function(Player: Player, key: string)
    if not (key == "Home" or key == "Storage") then
        return warn(
            `{script}.DuplicateKey.OnServerInvoke: {Player} attempted to \z
            duplicate an unknown key type ({key})!`
        )
    end

    if not module.HasResidence(Player) then
        return warn(
            `{script}.DuplicateKey.OnServerInvoke: {Player} attempted to \z
            duplicate a {key} key, but does not have a place of residence!`
        )
    end

    local DuplicationGui: ScreenGui = DuplicateKeyGui:Clone()
    DuplicationGui:SetAttribute("Type", key)
    DuplicateClient:Clone().Parent = DuplicationGui
    DuplicationGui.Parent = Player.PlayerGui
    return DuplicationGui.Name
end

---Duplicate a key and give it to a player
---@param Player Player The Player duplicating the key
---@param GiveTo Player The Player to give the duplicated key to
---@param key string The type of key being duplicated (Home or Storage)
GiveKey.OnServerEvent:Connect(function(
    Player: Player, GiveTo: Player, key: string
)
    local DuplicationGui = Player.PlayerGui:FindFirstChild(DuplicateKeyGui.Name)
    if not DuplicationGui then
        PassBack:FireClient(Player)
        return warn(
            `{script}.GiveKey.OnServerEvent: {Player} is not currently \z
            duplicating a key.`
        )
    end
    DuplicationGui:Destroy()

    if not (key == "Home" or key == "Storage") then
        PassBack:FireClient(Player)
        return warn(
            `{script}.GiveKey.OnServerEvent: {Player} attempted to duplicate \z
            an unknown key type ({key})!`
        )
    end

    if not module.HasResidence(Player) then
        PassBack:FireClient(Player)
        return warn(
            `{script}.GiveKey.OnServerEvent: {Player} attempted to \z
            duplicate a {key} key, but does not have a place of residence!`
        )
    end

    local RootPart = Player.Character
        and Player.Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then
        PassBack:FireClient(Player)
        return warn(
            `{script}.GiveKey.OnServerEvent: No HumanoidRootPart found for \z
            {Player}.`
        )
    end

    local distance = GiveTo:DistanceFromCharacter(RootPart.Position)
    if not (distance > 0 and distance < 24) then
        PassBack:FireClient(Player)
        return warn(
            `{script}.GiveKey.OnServerEvent: {Player} attempted to give a \z
            duplicated key to {GiveTo}, who is not present at the locksmith. \z
            (Distance: {Util.Round(distance, 2)} studs)`
        )
    end

    if not MoneyHandler.Charge(Player, 5000, "Card") then
        if not MoneyHandler.Charge(Player, 5000, "Cash") then
            PassBack:FireClient(Player, "Insufficient")
            return warn(
                `{script}.GiveKey.OnServerEvent: {Player} does not have \z
                enough money to duplicate a key!`
            )
        end
    end

    for state, buildings in pairs(residences) do
        for building, units in pairs(buildings) do
            for buildingKey, data in pairs(units) do
                if data.Owner == Player:GetAttribute("ID") then
                    table.insert(data[`{key}Keys`], GiveTo:GetAttribute("ID"))
                    WebhookHandler.Post(
                        `{Player:GetAttribute("FullName")} ({Player}, ID: \z
                        {Player:GetAttribute("ID")}) has duplicated the keys \z
                        to their {key} for apartment {data.Apartment} at \z
                        {ResidenceConfig[data.Building].Address} for \z
                        {GiveTo:GetAttribute("FullName")} ({GiveTo}, ID: \z
                        {GiveTo:GetAttribute("ID")}).`,
                        "PropertyLog"
                    )
                    return PassBack:FireClient(Player, true)
                end
            end
        end
    end

    PassBack:FireClient(Player)
    return warn(
        `{script}.GiveKey.OnServerInvoke: Unable to duplicate {Player}'s \z
        {key} key for {GiveTo}!`
    )
end)

---Get the GUI for listing and renting property
---@param Player Player The Player requesting the property listings
---@param state string The state that the property listings are in
---@return string
PropertyListings.OnServerInvoke = function(Player: Player, state: string)
    local residenceData = residences[state]
    if not residenceData then
        return warn(
            `{script}.PropertyListings.OnServerInvoke: {Player} requested \z
            residence listings for an unknown state! ({state})`
        )
    end

    if not Player:GetAttribute("Citizenship") == state then
        return warn(
            `{script}.ApplyCitizenship.OnServerInvoke: {Player} is not a \z
            citizen! ({Player:GetAttribute("Citizenship")})`
        )
    end

    if module.HasResidence(Player) then
        return warn(
            `{script}.ApplyCitizenship.OnServerInvoke: {Player} already has a \z
            place of residence!`
        )
    end

    local listings = {}
    for building, units in pairs(residenceData) do
        local listing = table.clone(ResidenceConfig[building])
        if listing.Type == "Apartment" then
            listing.Available = 0
            for key, data in pairs(units) do
                if not data.Owner then
                    listing.Available += 1
                end
            end

            if listing.Available == 0 then
                continue
            end
        end

        listing.Key = building
        table.insert(listings, listing)
    end

    if #listings == 0 then
        return "NoListings"
    end

    local ListingsGui = PropertyGui:Clone()
    local PassListings = ListingsGui:WaitForChild("PassListings")

    ListingsClient:Clone().Parent = ListingsGui

    ListingsGui.Parent = Player.PlayerGui

    PassListings:FireClient(Player, listings)

    return ListingsGui.Name
end

---Sign a rental contract and pay for an apartment
---@param Player Player The Player signing the contract
---@param building string The building that the apartment is rented in
SignRental.OnServerEvent:Connect(function(Player: Player, building: string)
    local ListingsGui = Player.PlayerGui:FindFirstChild(PropertyGui.Name)
    if not ListingsGui then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SignRental.OnServerEvent: No client GUI found for \z
            {Player}!`
        )
    end
    ListingsGui:Destroy()

    local state = Player:GetAttribute("Citizenship")
    local buildings = residences[state]
    if not buildings then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SignRental.OnServerEvent: {Player} is not a citizen of \z
            a state with residences available!\z
            ({Player:GetAttribute("Citizenship")})`
        )
    end

    if module.HasResidence(Player) then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SignRental.OnServerEvent: {Player} already has a place\z
            of residence!`
        )
    end

    local buildingConfig = ResidenceConfig[building]
    if not buildingConfig then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SignRental.OnServerEvent: {Player} signed a contract \z
            for an invalid building ({building})!`
        )
    end

    local units = buildings[building]
    if not units then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SignRental.OnServerEvent: {Player} signed a contract \z
            for a building which is not available in the {state}! ({building})`
        )
    end

    local available = {}
    for key, data in pairs(units) do
        if not data.Owner then
            table.insert(available, key)
        end
    end

    if #available == 0 then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SignRental.OnServerEvent: No units available in the \z
            building {building}!`
        )
    end

    local price = buildingConfig.Price * 2
    if not MoneyHandler.Charge(Player, price, "Card") then
        if not MoneyHandler.Charge(Player, price, "Cash") then
            PassBack:FireClient(Player, "Insufficient")
            return warn(
                `{script}.SignRental.OnServerEvent: {Player} does not \z
                have enough money to pay the down payment for {building}! (₲\z
                {Util.ThousandsSeparate(price)} required.)`
            )
        end
    end

    local unit = Util.RandomFrom(available)

    local unitData = units[unit]
    unitData.Owner = Player:GetAttribute("ID")
    unitData.RentDue = os.time() + 2592000
    unitData.Furniture.Parent = unitData.Residence
    unitData.Storage.SetLock(function(Opener: Player)
        return module.StorageAccess(
            Opener:GetAttribute("ID"),
            building,
            unitData.Residence:GetAttribute("Apartment")
        )
    end)

    print(
        `{script}.SignRental.OnServerEvent: {Player:GetAttribute("FullName")} \z
        ({Player}) paid the down payment for the apartment {unit}!`
    )

    SendNotification:FireClient(Player, {
        Title = "Apartment rented";
        Text = `You have rented an apartment at {buildingConfig.Address}, \z
        Apartment {unitData.Residence:GetAttribute("Apartment")}!`;
        Duration = 10;
    })

    WebhookHandler.Post(
        `{Player:GetAttribute("FullName")} ({Player}, ID: \z
        {Player:GetAttribute("ID")}) has rented apartment \z
        {unitData.Residence:GetAttribute("Apartment")} at \z
        {buildingConfig.Address}.`,
        "PropertyLog"
    )

    PassBack:FireClient(Player, true)

    local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
        Player:GetAttribute("ID")
    }`)
    if not PrivatePlayer:GetAttribute("BadgeHomeowner") then
        BadgeService:AwardBadge(Player.UserId, BadgesIds.Homeowner)
        if not RunService:IsStudio() then
            PrivatePlayer:SetAttribute("BadgeHomeowner", true)
        end
    end
end)

---Evict a character from their place of residence
---@param id number The ID number of the character to evict
---@param Evictor Player The Player evicting the character
---@return boolean
module.Evict = function(id: number, Evictor: Player): boolean
    if AddressOverrides[id] then
        return false
    end

    for state: string, buildings: table in pairs(residences) do
        for building, units: table in pairs(buildings) do
            for key: string, data: table in pairs(units) do
                if data.Owner == id then
                    if data.Furniture then
                        data.Furniture.Parent = nil
                    end

                    data.HomeKeys = {}
                    data.Owner = nil
                    data.RentDue = nil
                    data.StorageKeys = {}

                    WebhookHandler.Post(
                        `The tenant with ID {id} has been evicted from their \z
                        residence at {ResidenceConfig[building].Address}\z
                        {Evictor and ` by {Evictor}` or ""}.`,
                        "PropertyLog"
                    )
                    return true
                end
            end
        end
    end
    return false
end

---Get the address by character ID if it exists and return it as a string
---@param id number The ID number of the character to look up the address of
---@return string
module.GetAddress = function(id: number)
    if AddressOverrides[id] then
        return AddressOverrides[id]
    end

    for state: string, buildings: table in pairs(residences) do
        for building, units: table in pairs(buildings) do
            for key: string, data: table in pairs(units) do
                if data.Owner == id then
                    return `{ResidenceConfig[building].AddressShort}\z
                        {
                            data.Apartment and `, Apartment {data.Apartment}`
                            or ""
                        }, {ResidenceConfig[building].State} Bloxford, \z
                        {ResidenceConfig[building].State} Bloxell`
                end
            end
        end
    end
    return nil
end

---Get a list of addresses which a character has keys to
---@param id number The ID number of the character to look up the address of
---@return table
module.GetAddresses = function(id: number)
    local addresses = {}
    table.insert(addresses, module.GetAddress(id))

    for state: string, buildings: table in pairs(residences) do
        for building, units: table in pairs(buildings) do
            for key: string, data: table in pairs(units) do
                for i, roommate: number in ipairs(data.HomeKeys) do
                    if roommate == id then
                        table.insert(addresses,
                            `{ResidenceConfig[building].AddressShort}{
                                data.Apartment and `, Apartment {data.Apartment}`
                                or ""
                            }, {state} Bloxford, {state} Bloxell`
                        )
                    end
                end
            end
        end
    end

    return addresses
end

---Get a list of all occupied apartments in a state
---@param state string The state to find the apartments in
---@return table
module.GetOccupied = function(state: string): table
    local occupied = {}
    for building, units: table in pairs(residences[state]) do
        for key: string, data: table in pairs(units) do
            if not data.Owner then
                continue
            end

            table.insert(occupied, {
                Building = building;
                Apartment = data.Apartment;
                Address = `{ResidenceConfig[building].AddressShort}\z
                    {data.Apartment and `, Apartment {data.Apartment}` or ""}`
            })
        end
    end
    return occupied
end

---Determine if a player has access to an apartment
---@param id number The ID of the Player
---@param building string The building that the unit is in
---@param apartment number The apartment number in the building (optional)
---@return boolean
module.HasAccess = function(id: number, building: string, apartment: number)
    local key = building
    if apartment then
        key ..= `Apt{apartment}`
    end

    local buildingConfig = ResidenceConfig[building]
    if not buildingConfig then
        return warn(
            `{script}.HasAccess: Unable to find config for building {building}!`
        )
    end

    local buildings = residences[buildingConfig.State]
    if not buildings then
        return warn(
            `{script}.HasAccess: Unable to find residential buildings in the \z
            {buildingConfig.State}!`
        )
    end

    local units = buildings[building]
    if not units then
        return warn(
            `{script}.HasAccess: No units found in the building {building}!`
        )
    end

    local unit = units[key]
    if not unit then
        return warn(
            `{script}.HasAccess: No unit found with key {key}!`
        )
    end

    if unit.Owner == id then
        return true
    end

    for i, roommate in ipairs(unit.HomeKeys) do
        if roommate == id then
            return true
        end
    end

    return false
end

---Check if a Player has a place of residence
---@param Player Player The player to check
---@return boolean
module.HasResidence = function(Player: Player)
    for state, buildings in pairs(residences) do
        for building, units in pairs(buildings) do
            for key, data in pairs(units) do
                if data.Owner == Player:GetAttribute("ID") then
                    return true
                end
            end
        end
    end
    return false
end

---Handle a Player's rent
---@param Player Player The Player to handle the rent of
module.HandleRent = function(Player: Player)
    local state = Player:GetAttribute("Citizenship")
    local buildings = residences[state]
    if not buildings then
        return warn(
            `{script}.HandleRent: {Player} is not a citizen of a state with \z
            residences available! ({Player:GetAttribute("Citizenship")})`
        )
    end

    local building, key
    for checkBuilding, units in pairs(buildings) do
        for checkKey, data in pairs(units) do
            if data.Owner == Player:GetAttribute("ID") then
                if data.RentDue < os.time() then
                    building = checkBuilding
                    key = checkKey
                end
                break
            end
        end
    end

    if not (building and key) then
        return warn(
            `{script}.HandleRent: {Player} does not have a place of residence \z
            where rent is currently due!`
        )
    end

    local unitData = residences[state][building][key]
    unitData.RentDue += 2592000
end

---Check if a Player lives in a given building
---@param Player Player The Player to check
---@param building string The building to check
---@return boolean
module.LivesIn = function(Player: Player, building: string)
    local buildingConfig = ResidenceConfig[building]
    if not buildingConfig then
        return warn(
            `{script}.LivesIn: Unable to find config for building {building}!`
        )
    end

    local buildings = residences[buildingConfig.State]
    if not buildings then
        return warn(
            `{script}.LivesIn: Unable to find residential buildings in the \z
            {buildingConfig.State}!`
        )
    end

    local units = buildings[building]
    if not units then
        return warn(
            `{script}.LivesIn: No units found in the building {building}!`
        )
    end

    for key, data in pairs(units) do
        if data.Owner == Player:GetAttribute("ID") then
            return true
        end

        for i, roommate in ipairs(data.HomeKeys) do
            if roommate == Player:GetAttribute("ID") then
                return true
            end
        end
    end
    return false
end

---Load all the residences in a state
---@param state string The state to load the residences in
module.Load = function(state: string)
    local dsKey = "Residences"
    if game.PlaceId ~= PlaceIds.MainPlace then
        warn(`{script}.Load: Not in Main Place, reading from test DS!`)
        dsKey = "ResidencesTesting"
    end

    local residenceData = DataHandler.Get(dsKey, state) or {}
    residences[state] = {}

    for i, Residence in ipairs(CollectionService:GetTagged("Residence")) do
        local building = Residence:GetAttribute("Building")
        local residenceConfig = ResidenceConfig[building]
        if not residenceConfig then
            warn(
                `{script}.Load: Unable to find residence in building \z
                "{building}"!`
            )
            continue
        end

        if residenceConfig.State ~= state then
            continue
        end
    
        local key = building
        if residenceConfig.Type == "Apartment" then
            local apartment = Residence:GetAttribute("Apartment")
            if not apartment then
                warn(
                    `{script}.Load: Unable to find apartment number for \z
                    apartment {Residence:GetFullName()} in building {building}!`
                )
                continue
            end
    
            key ..= `Apt{apartment}`
        end

        local Furniture = Residence:FindFirstChild("Furniture")

        local fromFile = residenceData[key]

        if fromFile and fromFile.RentDue + 2592000 < os.time() then
            --Evict the tenant, rent is overdue
            print(
                `{script}.Load: Evicting tenant {fromFile.Owner} from \z
                apartment {key} for failure to pay overdue rent!`
            )
            if game.PlaceId == PlaceIds.MainPlace then
                WebhookHandler.Post(
                    `The tenant with ID {fromFile.Owner} has been evicted \z
                    from their residence at {residenceConfig.Address} for \z
                    failure to pay their rent on time.`,
                    "PropertyLog"
                )
            end
            fromFile = nil
        end
    
        residences[state][building] = residences[state][building] or {}
        residences[state][building][key] = {
            Apartment = Residence:GetAttribute("Apartment");
            Building = building;
            Furniture = Furniture;
            HomeKeys = fromFile and fromFile.HomeKeys or {};
            Owner = fromFile and fromFile.Owner;
            RentDue = fromFile and fromFile.RentDue;
            Residence = Residence;
            Storage = StorageHandler.new(
                residenceConfig.StorageType,
                `{key}Storage`,
                Furniture.Storage.Handle:FindFirstChildWhichIsA("Attachment"),
                fromFile and fromFile.Stored,
                function(Player: Player)
                    return module.StorageAccess(
                        Player:GetAttribute("ID"),
                        building,
                        Residence:GetAttribute("Apartment")
                    )
                end
            );
            StorageKeys = fromFile and fromFile.StorageKeys or {};
        }

        if Furniture and not fromFile then
            Furniture.Parent = nil
        end
    end
end

---Determine the owner of a residential unit
---@param building string The building that the unit is in
---@param apartment number The apartment number in the building (optional)
---@return any
module.Owner = function(building: string, apartment: number)
    local key = building
    if apartment then
        key ..= `Apt{apartment}`
    end

    local buildingConfig = ResidenceConfig[building]
    if not buildingConfig then
        return warn(
            `{script}.Owner: Unable to find config for building {building}!`
        )
    end

    local buildings = residences[buildingConfig.State]
    if not buildings then
        return warn(
            `{script}.Owner: Unable to find residential buildings in the \z
            {buildingConfig.State}!`
        )
    end

    local units = buildings[building]
    if not units then
        return warn(
            `{script}.Owner: No units found in the building {building}!`
        )
    end

    local unit = units[key]
    if not unit then
        return warn(
            `{script}.Owner: No unit found with key {key}!`
        )
    end

    return unit.Owner
end

---Checks if a Player's rent is due
---@param Player Player The Player to check the rent of
---@return boolean
module.RentDue = function(Player: Player)
    for state, buildings in pairs(residences) do
        for building, units in pairs(buildings) do
            for key, data in pairs(units) do
                if data.Owner == Player:GetAttribute("ID") then
                    return data.RentDue < os.time(), data.RentDue
                end
            end
        end
    end
    return false
end

---Determine if a player has access to the storage of an apartment
---@param id number The ID of the Player
---@param building string The building that the unit is in
---@param apartment number The apartment number in the building (optional)
---@return boolean
module.StorageAccess = function(id: number, building: string, apartment: number)
    local key = building
    if apartment then
        key ..= `Apt{apartment}`
    end

    local buildingConfig = ResidenceConfig[building]
    if not buildingConfig then
        return warn(
            `{script}.StorageAccess: Unable to find config for building \z
            {building}!`
        )
    end

    local buildings = residences[buildingConfig.State]
    if not buildings then
        return warn(
            `{script}.StorageAccess: Unable to find residential buildings in \z
            the {buildingConfig.State}!`
        )
    end

    local units = buildings[building]
    if not units then
        return warn(
            `{script}.StorageAccess: No units found in the building {building}!`
        )
    end

    local unit = units[key]
    if not unit then
        return warn(
            `{script}.StorageAccess: No unit found with key {key}!`
        )
    end

    if unit.Owner == id then
        return true
    end

    for i, roommate in ipairs(unit.StorageKeys) do
        if roommate == id then
            return true
        end
    end

    return false
end

game:BindToClose(function()
    local dsKey = "Residences"
    if game.PlaceId ~= PlaceIds.MainPlace then
        warn(`{script}.BindToClose: Not in Main Place, writing to test DS!`)
        dsKey = "ResidencesTesting"
    end

    for state, buildings in pairs(residences) do
        local residenceData = {}
        for building, units in pairs(buildings) do
            for key, data in pairs(units) do
                if data.Owner then
                    residenceData[key] = {
                        HomeKeys = data.HomeKeys;
                        Owner = data.Owner;
                        RentDue = data.RentDue;
                        StorageKeys = data.StorageKeys;
                        Stored = data.Storage.Export();
                    }
                end
            end
        end

        DataHandler.Set(dsKey, state, residenceData)
    end
end)

HasResidence.OnServerInvoke = module.HasResidence
RentDue.OnServerInvoke = module.RentDue
ResidenceOwner.OnServerInvoke = function(
    Player: Player, building: string, apartment: number
)
    return module.Owner(building, apartment)
end

return module