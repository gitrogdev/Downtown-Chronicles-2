--Handle police terminals on the server
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local TerminalClient = script.Terminal

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local AddressLookup = ReplicatedCommunication.AddressLookup
local AuthorizeCadet = ReplicatedCommunication.AuthorizeCadet
local BankLookup = ReplicatedCommunication.BankLookup
local CriminalLookup = ReplicatedCommunication.CriminalLookup
local FineCharacter = ReplicatedCommunication.FineCharacter
local FireOfficer = ReplicatedCommunication.FireOfficer
local FreezeAccount = ReplicatedCommunication.FreezeAccount
local HireOfficer = ReplicatedCommunication.HireOfficer
local IssueWarrant = ReplicatedCommunication.IssueWarrant
local OfficerLookup = ReplicatedCommunication.OfficerLookup
local PromoteOfficer = ReplicatedCommunication.PromoteOfficer
local ReassignOfficer = ReplicatedCommunication.ReassignOfficer
local RecordLookup = ReplicatedCommunication.RecordLookup
local SearchableAddresses = ReplicatedCommunication.SearchableAddresses
local SearchWarrant = ReplicatedCommunication.SearchWarrant
local SendNotification = ReplicatedCommunication.SendNotification
local TacticalDeployment = ReplicatedCommunication.TacticalDeployment

local PoliceConfig = require(ReplicatedConfig.Police)

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local HomeHandler = require(ServerScripts.Homes)
local ServerConfig = ServerScripts.Configuration
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local ResidenceConfig = require(ServerScripts.Homes.Residences)

local Charges = require(ServerConfig.Charges)

local UIStorage = ServerStorage.UserInterface
local TerminalUI: ScreenGui = UIStorage.PoliceTerminal

local MODS = {
    ["Accessory to"] = true;
    ["Attempting to"] = true;
    ["Conspiracy to"] = true;
}

local usingTerminal = {}

---Look up all known addresses for a character
---@param Player Player The Player requesting the addresses
---@param id number The character ID of the character being searched for
---@return boolean
---@return any
AddressLookup.OnServerInvoke = function(Player: Player, id: number)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.AddressLookup.OnServerInvoke: {Player} is not currently \z
            logged into a police terminal!`
        )
    end

    local addresses = HomeHandler.GetAddresses(id)
    if (not addresses) or #addresses == 0 then
        return false, "No addresses found."
    end
    return true, addresses
end

---Authorize a cadet to take equipment from the armory
---@param Player Player The Player authorizing the cadet
---@param Cadet Player The cadet being authorized
AuthorizeCadet.OnServerEvent:Connect(function(Player: Player, Cadet: Player)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.AuthorizeCadet.OnServerEvent: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    local rank: number = Player:GetAttribute("PoliceRank") or 0
    if rank < 3 then
        return false, "Access denied.", warn(
            `{script}.AuthorizeCadet.OnServerEvent: {Player} is not a high \z
            enough rank to authorize a cadet to use the armory! (Expected 3, \z
            got {rank})`
        )
    end

    if Cadet:GetAttribute("PoliceRank") ~= 1 then
        return false, `{Cadet:GetAttribute("FullName")} is not a cadet.`, warn(
            `{script}.AuthorizeCadet.OnServerEvent: {Player} attempted to \z
            authorize {Cadet} to use the armory, but {Cadet} is not a cadet!`
        )
    end

    local connections = {}
    local function endNotification()
        for i, Connection: RBXScriptConnection in ipairs(connections) do
            Connection:Disconnect()
        end

        if Cadet.Parent ~= Players then
            return
        end

        SendNotification:FireClient(Cadet, {
            Title = "Patrol authorization ended";
            Text = "Your authorization to take equipment from the armory has \z
                ended. Please return all equipment to the armory at once.";
            Duration = 10;
        })
    end

    if Cadet:GetAttribute("ArmoryAuthorized") then
        Cadet:SetAttribute("ArmoryAuthorized", nil)
        endNotification()
    else
        Cadet:SetAttribute("ArmoryAuthorized", Player.UserId)
        SendNotification:FireClient(Cadet, {
            Title = "Patrol authorized";
            Text = `You have been authorized to take equipment from the \z
                armory by {Player:GetAttribute("FullName")}.`;
            Duration = 10;
        })

        table.insert(connections,
            Player:GetAttributeChangedSignal("Working"):Once(endNotification)
        )
        table.insert(connections, Player.AncestryChanged:Once(endNotification))
        table.insert(connections,
            Cadet:GetAttributeChangedSignal("ArmoryAuthorized"):Once(function()
                for i, Connection: RBXScriptConnection in ipairs(connections) do
                    Connection:Disconnect()
                end
            end)
        )

        WebhookHandler.Post(
            `{PoliceConfig.Ranks[rank]} {Player:GetAttribute("LastName")} \z
            ({Player} {Player.UserId}-{Player:GetAttribute("ID")}) has \z
            authorized Cadet {Cadet:GetAttribute("LastName")} ({Cadet} \z
            {Cadet.UserId}-{Cadet:GetAttribute("ID")}) to patrol and take \z
            equipment from the armory.`,
            "PoliceLog"
        )
    end
end)

---Look up a player's bank account information
---@param Player Player The Player requesting the data
---@param id number The ID of the character to be looked up
---@return boolean
---@return any
BankLookup.OnServerInvoke = function(Player: Player, id: number)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.BankLookup.OnServerInvoke: {Player} is not currently \z
            logged into a police terminal!`
        )
    end

    if not ((
        Player:GetAttribute("PoliceDivision") == "Tax"
        and Player:GetAttribute("PoliceRank") >= 4
    ) or Player:GetAttribute("PoliceRank") >= 6) then
        return false, "Access denied.", warn(
            `{script}.BankLookup.OnServerInvoke: {Player} does not have the \z
            required permissions to use the bank lookup function!`
        )
    end

    local charData = DataHandler.Get("Characters", tostring(id))
    if not charData then
        return false, `No records could be found of a person with ID {id}.`,
        warn(
            `{script}.BankLookup.OnServerInvoke: Could not find character with\z
            ID {id} for {Player}!`
        )
    end

    if not charData.PBNBAccount then
        return false, `{charData.FirstName} {charData.LastName} does not \z
            have an open bank account in the State of North Bloxell.`, warn(
            `{script}.BankLookup.OnServerInvoke: {charData.FirstName} \z
            {charData.LastName} does not have an open bank account in the \z
            State of North Bloxell!`
        )
    end

    local records: table = {
        Address = HomeHandler.GetAddress(id);
        CharacterId = id;
        BankBalance = charData.BankBalance;
        BankFrozen = charData.BankFrozen;
        Citizenship = charData.Citizenship;
        Name = `{charData.FirstName} {charData.LastName}`;
        Occupation = Util.JobTitle(charData);
        UserId = charData.Created and charData.Created.By;
    }

    if
        charData.Occupation == "MIA"
        or charData.Citizenship == "North"
        or charData.HasRecord
    then
        records.Appearance = {
            Face = charData.Face;
            Facial = charData.Facial;
            Hair = charData.Hair;
            HairColor = charData.HairColor;
            Pants = charData.Pants;
            Shirt = charData.Shirt;
            SkinColor = charData.SkinColor;
        }
        Util.AssociateName(Player, id, records.Name)
    end

    return true, records
end

---Look up the data for a criminal
---@param Player Player The Player requesting the data
---@param id number The ID of the character to be looked up
---@return boolean
---@return any
CriminalLookup.OnServerInvoke = function(Player: Player, id: number)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.CriminalLookup.OnServerInvoke: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    local charData = DataHandler.Get("Characters", tostring(id))
    if not charData then
        return false, `No records could be found of a person with ID {id}.`,
        warn(
            `{script}.CriminalLookup.OnServerInvoke: Could not find character \z
            with ID {id} for {Player}!`
        )
    end

    local records: table = {
        Address = HomeHandler.GetAddress(id);
        CharacterId = id;
        Citizenship = charData.Citizenship;
        Name = `{charData.FirstName} {charData.LastName}`;
        Occupation = Util.JobTitle(charData);
        UserId = charData.Created and charData.Created.By;
    }

    if
        charData.Occupation == "MIA"
        or charData.Citizenship == "North"
        or charData.HasRecord
    then
        records.Appearance = {
            Face = charData.Face;
            Facial = charData.Facial;
            Hair = charData.Hair;
            HairColor = charData.HairColor;
            Pants = charData.Pants;
            Shirt = charData.Shirt;
            SkinColor = charData.SkinColor;
        }
        Util.AssociateName(Player, id, records.Name)
    end

    local rank = Player:GetAttribute("PoliceRank")
    if rank > 5 or (
        rank == 5 and Player:GetAttribute("PoliceDivision") == "Investigative"
    ) then
        return true, {records, Charges}
    end
    return true, {records}
end

---Fire an officer from their job in the Ministry of Internal Affairs
---@param Player Player The Player offering the job
---@param id number The character ID of the character to offer the job to
---@return boolean
---@return any
FireOfficer.OnServerInvoke = function(Player: Player, id: number)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.FireOfficer.OnServerInvoke: {Player} is not currently \z
            logged into a police terminal!`
        )
    end

    if (Player:GetAttribute("PoliceRank") or 0) < 5 then
        return false, "Access denied.", warn(
            `{script}.FireOfficer.OnServerInvoke: {Player} is not a captain! \z
            (Rank 5 required, got {Player:GetAttribute("PoliceRank")})`
        )
    end

    local success, result, name
    DataHandler.Update("Characters", tostring(id), function(charData: table)
        if not charData then
            warn(
                `{script}.FireOfficer.OnServerInvoke: No character data found \z
                for officer with ID {id}! (Requested by {Player})`
            )
            success, result = false,
                `No records could be found of a person with ID {id}.`
            return charData
        end

        name = `{charData.FirstName} {charData.LastName}`
        if charData.Occupation ~= "MIA" then
            warn(
                `{script}.FireOfficer.OnServerInvoke: {Player} attempted to \z
                fire {charData.FirstName} {charData.LastName} with ID {id}, \z
                but they are not a member of the MIA!`
            )
            success, result = false,
                `{name} with ID {id} is not employed by the Ministry of \z
                Internal Affairs.`
            return charData
        end

        if (charData.PoliceRank or 0) >= Player:GetAttribute("PoliceRank") then
            warn(
                `{script}.FireOfficer.OnServerInvoke: {Player} attempted to \z
                fire {name} with ID {id}, but they outrank them ({Player}'s \z
                rank: {Player:GetAttribute("PoliceRank")}, {name}'s rank: \z
                {charData.PoliceRank})!`
            )
            success, result = false,
                `You do not have the authority to fire {name} with ID {id}.`
            return charData
        end

        if
            Player:GetAttribute("PoliceRank") < 6
            and charData.PoliceDivision ~= Player:GetAttribute("PoliceDivision")
        then
            warn(
                `{script}.FireOfficer.OnServerInvoke: {Player} attempted to \z
                fire {name} with ID {id}, but are not under {Player}'s \z
                command! ({Player}'s division: \z
                {Player:GetAttribute("PoliceDivision")}, {name}'s division: \z
                {charData.PoliceDivision})!`
            )
            success, result = false,
                `{name} with ID {id} is not an officer under your command.`
            return charData
        end

        charData.Occupation = "Unemployed"
        charData.PoliceDivision = ""
        charData.PoliceOffer = ""
        charData.PoliceRank = 0
        charData.PoliceSince = 0
        success, result = true, `{name} with ID {id} has been dismissed from \z
            their position in the Ministry of Internal Affairs.`
        return charData
    end)

    if success then
        for i, Check: Player in ipairs(Players:GetPlayers()) do
            if Check:GetAttribute("ID") == id then
                Check:SetAttribute("Occupation", "Unemployed")
                Check:SetAttribute("PoliceDivision", "")
                Check:SetAttribute("PoliceOffer", "")
                Check:SetAttribute("PoliceRank", 0)
                Check:SetAttribute("PoliceSince", 0)

                SendNotification:FireClient(Check, {
                    Title = "Dismissed from duty";
                    Text = `You have been dismissed from your position in the \z
                        Ministry of Internal Affairs. Return any weapons that \z
                        belong to them, or you will be charged for their \z
                        theft.`;
                    Duration = 10;
                })
                break
            end
        end

        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player} \z
            {Player.UserId}-{Player:GetAttribute("ID")}) has dismissed {name} \z
            with ID {id} from their position in the Ministry of Internal \z
            Affairs.`,
            "PoliceLog"
        )
    end

    return success, result
end

---Fine a character's bank account
---@param Player Player The Player issuing the fine
---@param id number The ID of the character being fined
---@param amount number The amount to fine the player for
---@return boolean
---@return string
---@return number
FineCharacter.OnServerInvoke = function(
    Player: Player, id: number, amount: number
): boolean
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.FineCharacter.OnServerInvoke: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    local rank: number = Player:GetAttribute("PoliceRank") or 0
    if rank < 5 then
        return false, "Access denied.", warn(
            `{script}.FineCharacter.OnServerInvoke: {Player} does not \z
            have the sufficient rank in order to issue a fine! \z
            (Expected 5, got {rank})`
        )
    end

    local division: string = Player:GetAttribute("PoliceDivision")
    if division ~= "Tax" and rank < 6 then
        return false, "Access denied.", warn(
            `{script}.FineCharacter.OnServerInvoke: {Player} is not a member \z
            of the tax division, and is therefore unauthorized from issuing \z
            fines! (Division: {division}, Rank: {rank})`
        )
    end

    amount = tonumber(amount)
    if not (amount and amount > 0 and math.floor(amount) == amount) then
        return false, "Invalid amount input.", warn(
            `{script}.FineCharacter.OnServerInvoke: {Player} sent an invalid \z
            amount input! (Expected positive integer, got {amount})`
        )
    end

    local success, response, balance
    DataHandler.Update("Characters", tostring(id), function(data: table)
        if not data then
            success = false
            response = `No character found with ID {id}.`
            return data
        end

        if not data.PBNBAccount then
            success = false
            response = `No open bank account found for {data.FirstName} \z
                {data.LastName} ({id}).`
            return data
        end

        data.BankBalance = (data.BankBalance or 0) - amount
        balance = data.BankBalance
        success = true
        response = `{data.FirstName} {data.LastName} has been successfully \z
            fined ₲{Util.ThousandsSeparate(amount)}.`
        return data
    end)

    if success then
        for i, Check: Player in ipairs(Players:GetPlayers()) do
            if Check:GetAttribute("ID") == id then
                Check:SetAttribute("BankBalance", balance)
                break
            end
        end
    end

    WebhookHandler.Post(
        `{Player:GetAttribute("FullName")} ({Player} {Player.UserId}-\z
        {Player:GetAttribute("ID")}) has fined the character with ID {id} \z
        ₲{Util.ThousandsSeparate(amount)}.`,
        "PoliceLog"
    )

    return success, response, balance
end

---Freeze a character's bank account
---@param Player Player The Player freezing the bank account
---@param id number The character ID which owns the bank account being frozen
---@param status boolean Whether to freeze the bank account or unfreeze it
---@return boolean
---@return string
FreezeAccount.OnServerInvoke = function(
    Player: Player, id: number, status: boolean
): boolean
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.FreezeAccount.OnServerInvoke: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    local rank: number = Player:GetAttribute("PoliceRank") or 0
    if rank < 4 then
        return false, "Access denied.", warn(
            `{script}.FreezeAccount.OnServerInvoke: {Player} does not \z
            have the sufficient rank in order to freeze a bank account! \z
            (Expected 4, got {rank})`
        )
    end

    local division: string = Player:GetAttribute("PoliceDivision")
    if division ~= "Tax" and rank < 6 then
        return false, "Access denied.", warn(
            `{script}.FreezeAccount.OnServerInvoke: {Player} is not a member \z
            of the tax division, and is therefore unauthorized from freezing \z
            bank accounts! (Division: {division}, Rank: {rank})`
        )
    end

    local success, response
    DataHandler.Update("Characters", tostring(id), function(data: table)
        if not data then
            success = false
            response = `No character found with ID {id}.`
            return data
        end

        if not data.PBNBAccount then
            success = false
            response = `No open bank account found for {data.FirstName} \z
                {data.LastName} ({id}).`
            return data
        end

        data.BankFrozen = status
        success = true
        response = `{data.FirstName} {data.LastName}'s bank account has been \z
            successfully {status and "" or "un"}frozen.`
        return data
    end)

    if success then
        for i, Check: Player in ipairs(Players:GetPlayers()) do
            if Check:GetAttribute("ID") == id then
                Check:SetAttribute("BankFrozen", status)
                break
            end
        end
    end

    WebhookHandler.Post(
        `{Player:GetAttribute("FullName")} ({Player} {Player.UserId}-\z
        {Player:GetAttribute("ID")}) has {status and "" or "un"}frozen the \z
        bank account of the character with ID {id}.`,
        "PoliceLog"
    )

    return success, response
end

---Offer a new officer a police job in the player's division
---@param Player Player The Player offering the job
---@param id number The character ID of the character to offer the job to
---@return boolean
---@return any
HireOfficer.OnServerInvoke = function(Player: Player, id: number)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.HireOfficer.OnServerInvoke: {Player} is not currently \z
            logged into a police terminal!`
        )
    end

    if (Player:GetAttribute("PoliceRank") or 0) < 5 then
        return false, "Access denied.", warn(
            `{script}.HireOfficer.OnServerInvoke: {Player} is not a captain! \z
            (Rank 5 required, got {Player:GetAttribute("PoliceRank")})`
        )
    end

    local success, result, name
    DataHandler.Update("Characters", tostring(id), function(charData: table)
        if not charData then
            warn(
                `{script}.HireOfficer.OnServerInvoke: No character data found \z
                for officer with ID {id}! (Requested by {Player})`
            )
            success, result = false,
                `No records could be found of a person with ID {id}.`
            return charData
        end

        if charData.Occupation == "MIA" then
            warn(
                `{script}.HireOfficer.OnServerInvoke: {Player} attempted to \z
                hire {charData.FirstName} {charData.LastName} with ID {id}, \z
                but they are already a member of the MIA!`
            )
            success, result = false,
                `{charData.FirstName} {charData.LastName} with ID {id} is \z
                already employed by the Ministry of Internal Affairs.`
            return charData
        end

        charData.PoliceOffer = Player:GetAttribute("PoliceDivision")
        name = `{charData.FirstName} {charData.LastName}`
        success, result = true, `Successfully extended an offer to join the \z
            {charData.PoliceOffer:lower()} division to {name} with ID {id}.`
        return charData
    end)

    if success then
        for i, Check: Player in ipairs(Players:GetPlayers()) do
            if Check:GetAttribute("ID") == id then
                Check:SetAttribute(
                    "PoliceOffer", Player:GetAttribute("PoliceDivision")
                )
                SendNotification:FireClient(Check, {
                    Title = "Job offer";
                    Text = `You have been offered a position in the Ministry \z
                        of Internal Affairs, \z
                        {Player:GetAttribute("PoliceDivision"):lower()} \z
                        division! Head to the police station to accept it!`;
                    Duration = 10;
                })
                break
            end
        end

        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player} \z
            {Player.UserId}-{Player:GetAttribute("ID")}) extended an offer to \z
            join the {Player:GetAttribute("PoliceDivision"):lower()} division \z
            to {name} with ID {id}.`,
            "PoliceLog"
        )
    end

    return success, result
end

---Issue a warrant for a character
---@param Player Player The player issuing the warrant
---@param id number The character ID for the target of the warrant
---@param charges table The charges to issue on the warrant
---@return boolean
---@return any
IssueWarrant.OnServerInvoke = function(
    Player: Player, id: number, charges: table
)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.IssueWarrant.OnServerInvoke: {Player} is not currently \z
            logged into a police terminal!`
        )
    end

    local rank = Player:GetAttribute("PoliceRank")
    if not (rank > 5 or (
        rank == 5 and Player:GetAttribute("PoliceDivision") == "Investigative"
    )) then
        return false, "Insufficient permissions.", warn(
            `{script}.IssueWarrant.OnServerInvoke: {Player} does not have \z
            sufficient permissions to issue a warrant!`
        )
    end

    local charData = DataHandler.Get("Characters", tostring(id))
    if not charData then
        return false, `No records could be found of a person with ID {id}.`,
        warn(
            `{script}.IssueWarrant.OnServerInvoke: Could not find character \z
            with ID {id} for {Player}!`
        )
    end

    local chargeWith = {}
    local writtenCharges = ""

    for i, charge: table in ipairs(charges) do
        local chargeInfo = Charges[charge.Key]
        if not chargeInfo then
            return false, `Unknown charge "{charge.Key}"` ,warn(
                `{script}.IssueWarrant.OnServerInvoke: {Player} attempted to \z
                issue a warrant for suspect with ID {id} with the unknown \z
                charge "{charge.Key}"!`
            )
        end

        if not (charge.Mod == nil or MODS[charge.Mod]) then
            return false, `Unknown modifier "{charge.Mod}"`, warn(
                `{script}.IssueWarrant.OnServerInvoke: {Player} attempted to \z
                issue a warrant for suspect with ID {id} with {charge.Key} \z
                with the unknown modifier "{charge.Mod}"!`
            )
        end

        writtenCharges ..= `\n{charge.Mod or ""}\z
            {charge.Mod and ` {chargeInfo.WithMod}` or chargeInfo.Name}`

        table.insert(chargeWith, {
            At = os.time();
            Charge = charge.Key;
            Mod = charge.Mod;
        })
    end

    local warrantId
    DataHandler.Update("WarrantIDs", "North", function(lastId: number)
        lastId = lastId or 0
        lastId += 1
        warrantId = lastId
        return lastId
    end)

    WebhookHandler.Post(
        `# Arrest warrant #{string.format("%04d", warrantId)} issued for \z
        {charData.FirstName} {charData.LastName} \z
        ({charData.Created and charData.Created.By or 0}-{id})\n\z
        **Issuing officer**: {Player:GetAttribute("FullName")} (\z
        {Player.UserId}-{Player:GetAttribute("ID")})\n\z
        Wanted for:{writtenCharges}`,
        "WarrantLog"
    )
    return true, "Warrant successfully issued."
end

---Look up the data for an officer
---@param Player Player The Player requesting the data
---@param id number The ID of the officer to be looked up
---@return boolean
---@return any
OfficerLookup.OnServerInvoke = function(Player: Player, id: number)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.OfficerLookup.OnServerInvoke: {Player} is not currently \z
            logged into a police terminal!`
        )
    end

    local charData = DataHandler.Get("Characters", tostring(id))
    if not charData then
        return false, `No records could be found of a person with ID {id}.`,
        warn(
            `{script}.OfficerLookup.OnServerInvoke: Could not find character \z
            with ID {id} for {Player}!`
        )
    end

    local records: table = {
        CharacterId = id;
        Citizenship = charData.Citizenship;
        Name = `{charData.FirstName} {charData.LastName}`;
        Occupation = Util.JobTitle(charData);
        UserId = charData.Created and charData.Created.By or 0;
    }

    if charData.Occupation == "MIA" then
        records.Officer = true
        records.PoliceRank = charData.PoliceRank or 1
        records.PoliceDivision = (
            (not charData.PoliceDivision) or charData.PoliceDivision == ""
        ) and "Patrol" or charData.PoliceDivision
        records.PoliceSince = charData.PoliceSince or 1719096170
    end

    if
        charData.Occupation == "MIA"
        or charData.Citizenship == "North"
        or charData.HasRecord
    then
        records.Appearance = {
            Face = charData.Face;
            Facial = charData.Facial;
            Hair = charData.Hair;
            HairColor = charData.HairColor;
            Pants = charData.Pants;
            Shirt = charData.Shirt;
            SkinColor = charData.SkinColor;
        }
        Util.AssociateName(Player, id, records.Name)
    end

    return true, records
end

---Promote an officer to a given rank
---@param Player Player The player promoting the officer
---@param id number The ID of the officer being promoted
---@param rank number The rank number of the rank to promote the officer to
---@return boolean
---@return string
PromoteOfficer.OnServerInvoke = function(
    Player: Player, id: number, rank: number
)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.PromoteOfficer.OnServerInvoke: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    if (Player:GetAttribute("PoliceRank") or 0) < 5 then
        return false, "Access denied.", warn(
            `{script}.PromoteOfficer.OnServerInvoke: {Player} is not a \z
            captain! (Rank 5 required, got {Player:GetAttribute("PoliceRank")})`
        )
    end

    if not PoliceConfig.Ranks[rank] then
        return false, `Unknown rank "{rank}" provided.`, warn(
            `{script}.PromoteOfficer.OnServerInvoke: {Player} provided an \z
            unknown rank "{rank}" to promote the officer with ID {id}`
        )
    end

    if rank >= Player:GetAttribute("PoliceRank") then
        return false, `You do not have the authority to promote an officer to \z
            the rank of {PoliceConfig.Ranks[rank]:lower()}.`,
        warn(
            `{script}.PromoteOfficer.OnServerInvoke: {Player} does not have \z
            the permission to rank the officer with ID {id} to {rank}. (Rank \z
            {Player:GetAttribute("PoliceRank")})`
        )
    end

    local success, result, name, direction
    DataHandler.Update("Characters", tostring(id), function(charData: table)
        if not charData then
            warn(
                `{script}.PromoteOfficer.OnServerInvoke: No character data \z
                found for officer with ID {id}! (Requested by {Player})`
            )
            success, result = false,
                `No records could be found of a person with ID {id}.`
            return charData
        end

        name = `{charData.FirstName} {charData.LastName}`
        if charData.Occupation ~= "MIA" then
            warn(
                `{script}.PromoteOfficer.OnServerInvoke: {Player} attempted \z
                to promote {charData.FirstName} {charData.LastName} with ID \z
                {id}, but they are not a member of the MIA!`
            )
            success, result = false,
                `{name} with ID {id} is not employed by the Ministry of \z
                Internal Affairs.`
            return charData
        end

        if (charData.PoliceRank or 0) >= Player:GetAttribute("PoliceRank") then
            warn(
                `{script}.PromoteOfficer.OnServerInvoke: {Player} attempted \z
                to promote {name} with ID {id}, but they outrank them \z
                ({Player}'s rank: {PoliceConfig.Ranks[
                    Player:GetAttribute("PoliceRank")]:lower()}, \z
                {name}'s rank: \z
                {PoliceConfig.Ranks[charData.PoliceRank]:lower()})!`
            )
            success, result = false,
                `You do not have the authority to promote {name} with ID {id}.`
            return charData
        end

        if
            Player:GetAttribute("PoliceRank") < 6
            and charData.PoliceDivision ~= Player:GetAttribute("PoliceDivision")
        then
            warn(
                `{script}.PromoteOfficer.OnServerInvoke: {Player} attempted \z
                to promote {name} with ID {id}, but are not under {Player}'s \z
                command! ({Player}'s division: \z
                {Player:GetAttribute("PoliceDivision")}, {name}'s division: \z
                {charData.PoliceDivision})!`
            )
            success, result = false,
                `{name} with ID {id} is not an officer under your command.`
            return charData
        end

        if (charData.PoliceRank or 1) < rank then
            direction = "Pro"
        elseif (charData.PoliceRank or 1) > rank then
            direction = "De"
        elseif (charData.PoliceRank or 1) == rank then
            success, result = false,
                `{name} with ID {id} is already a \z
                {PoliceConfig.Ranks[rank]:lower()}.`
            return charData
        end
        charData.PoliceRank = rank
        if rank > 5 then
            charData.PoliceDivision = "Patrol"
        end

        success, result = true, `{name} with ID {id} has been \z
            {direction:lower()}moted to the rank of \z
            {PoliceConfig.Ranks[rank]:lower()}.`
        return charData
    end)

    if success then
        for i, Check: Player in ipairs(Players:GetPlayers()) do
            if Check:GetAttribute("ID") == id then
                Check:SetAttribute("PoliceRank", rank)

                SendNotification:FireClient(Check, {
                    Title = `{direction}motion`;
                    Text = `You have been {direction:lower()}moted to the \z
                        rank of {PoliceConfig.Ranks[rank]:lower()}.`;
                    Duration = 10;
                })
                break
            end
        end

        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player} \z
            {Player.UserId}-{Player:GetAttribute("ID")}) has \z
            {direction:lower()}moted {name} with ID {id} to the rank of \z
            {PoliceConfig.Ranks[rank]:lower()}.`,
            "PoliceLog"
        )
    end

    return success, result
end

ReassignOfficer.OnServerInvoke = function(
    Player: Player, id: number, division: string
)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.ReassignOfficer.OnServerInvoke: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    if (Player:GetAttribute("PoliceRank") or 0) < 6 then
        return false, "Access denied.", warn(
            `{script}.ReassignOfficer.OnServerInvoke: {Player} is not a \z
            colonel general! (Rank 6 required, got \z
            {Player:GetAttribute("PoliceRank")})`
        )
    end

    if not PoliceConfig.OfficerTitles[division] then
        return false, `Unknown division "{division}" provided.`, warn(
            `{script}.ReassignOfficer.OnServerInvoke: {Player} provided an \z
            unknown division "{division}" to reassign the officer with ID {id}`
        )
    end

    local success, result, name
    DataHandler.Update("Characters", tostring(id), function(charData: table)
        if not charData then
            warn(
                `{script}.ReassignOfficer.OnServerInvoke: No character data \z
                found for officer with ID {id}! (Requested by {Player})`
            )
            success, result = false,
                `No records could be found of a person with ID {id}.`
            return charData
        end

        name = `{charData.FirstName} {charData.LastName}`
        if charData.Occupation ~= "MIA" then
            warn(
                `{script}.ReassignOfficer.OnServerInvoke: {Player} attempted \z
                to reassign {name} with ID {id}, but they are not a member of \z
                the MIA!`
            )
            success, result = false,
                `{name} with ID {id} is not employed by the Ministry of \z
                Internal Affairs.`
            return charData
        end

        if (charData.PoliceRank or 0) > 5 then
            warn(
                `{script}.ReassignOfficer.OnServerInvoke: {Player} attempted \z
                to reassign {name} with ID {id}, but their rank is too high! \z
                ({name}'s rank: {charData.PoliceRank})`
            )
            success, result = false,
                `{name} with {id} is in an administrative position, and can \z
                not be assigned to a field division without being demoted.`
            return charData
        end

        charData.PoliceDivision = division

        success, result = true, `{name} with ID {id} has been \z
            reassigned to the {division:lower()} division.`
        return charData
    end)

    if success then
        for i, Check: Player in ipairs(Players:GetPlayers()) do
            if Check:GetAttribute("ID") == id then
                Check:SetAttribute("PoliceDivision", division)

                SendNotification:FireClient(Check, {
                    Title = `Reassignment`;
                    Text = `You have been reassigned to the \z
                        {division:lower()} division of the MIA.`;
                    Duration = 10;
                })
                break
            end
        end

        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player} \z
            {Player.UserId}-{Player:GetAttribute("ID")}) has reassigned \z
            {name} with ID {id} to the {division:lower()} division of the \z
            Ministry of Internal Affairs, North Bloxford Administration.`,
            "PoliceLog"
        )
    end

    return success, result
end

---Look up a character's criminal record
---@param Player Player The Player looking up the record
---@param id number The ID of the character to find the record for
---@return boolean
---@return any
RecordLookup.OnServerInvoke = function(Player: Player, id: number)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.RecordLookup.OnServerInvoke: {Player} is not currently \z
            logged into a police terminal!`
        )
    end

    local charData = DataHandler.Get("Characters", tostring(id))
    if not charData then
        return false, `No records could be found of a person with ID {id}.`,
        warn(
            `{script}.RecordLookup.OnServerInvoke: Could not find character \z
            with ID {id} for {Player}!`
        )
    end

    local criminalRecord = DataHandler.Get("NorthRecords", tostring(id))

    if criminalRecord then
        local parsed = {}
        for i, charge: table in ipairs(criminalRecord) do
            local Charge = Charges[charge.Charge]
            local timestamp = os.date("!*t", charge.At - 36000)
            table.insert(parsed, {
                At = `{string.format("%02d", timestamp.day)}/\z
                    {string.format("%02d", timestamp.month)}/{timestamp.year}`;
                Charge = `{charge.Mod and `{charge.Mod:upper()} ` or ""}\z
                    {charge.Mod and Charge.WithMod:upper()
                    or Charge.Name:upper()}`;
            })
        end
        return true, parsed
    end
    return false, `{charData.FirstName} {charData.LastName} has a clean \z
        criminal record.`
end

---Get a list of addresses which warrants can be put out on
---@param Player Player The Player requesting the addresses
---@return boolean
---@return any
SearchableAddresses.OnServerInvoke = function(Player: Player)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.SearchableAddresses.OnServerInvoke: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    local rank: number = Player:GetAttribute("PoliceRank") or 0
    if rank < 5 then
        return false, "Access denied.", warn(
            `{script}.SearchableAddresses.OnServerInvoke: {Player} does not \z
            have the sufficient rank in order to issue a search warrant! \z
            (Expected 5, got {rank})`
        )
    end

    local division: string = Player:GetAttribute("PoliceDivision")
    if division ~= "Investigative" and rank < 6 then
        return false, "Access denied.", warn(
            `{script}.SearchableAddresses.OnServerInvoke: {Player} is not a \z
            member of the investigative division, and is therefore \z
            unauthorized from issuing search warrants! \z
            (Division: {division}, Rank: {rank})`
        )
    end

    local occupied = HomeHandler.GetOccupied("North")
    if (not occupied) or #occupied == 0 then
        return false, "No addresses found."
    end
    return true, occupied
end

SearchWarrant.OnServerInvoke = function(
    Player: Player, building: string, apartment: number
)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.SearchWarrant.OnServerInvoke: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    local rank: number = Player:GetAttribute("PoliceRank") or 0
    if rank < 5 then
        return false, "Access denied.", warn(
            `{script}.SearchWarrant.OnServerInvoke: {Player} does not \z
            have the sufficient rank in order to issue a search warrant! \z
            (Expected 5, got {rank})`
        )
    end

    local division: string = Player:GetAttribute("PoliceDivision")
    if division ~= "Investigative" and rank < 6 then
        return false, "Access denied.", warn(
            `{script}.SearchWarrant.OnServerInvoke: {Player} is not a \z
            member of the investigative division, and is therefore \z
            unauthorized from issuing search warrants! \z
            (Division: {division}, Rank: {rank})`
        )
    end

    local valid = HomeHandler.Owner(building, apartment)
    if not valid then
        return false, "Invalid residence.", warn(
            `{script}.SearchWarrant.OnServerInvoke: Unable to find owner for \z
            residence in building {building}\z
            {apartment and `, Apartment {apartment}` or ""}.`
        )
    end

    local searchWarrants = Player:GetAttribute("SearchWarrants") or "[]"
    searchWarrants = HttpService:JSONDecode(searchWarrants)
    table.insert(searchWarrants, {
        Building = building;
        Apartment = apartment;
    })
    Player:SetAttribute("SearchWarrants", HttpService:JSONEncode(
        searchWarrants
    ))

    WebhookHandler.Post(
        `{Player:GetAttribute("FullName")} ({Player} \z
        {Player.UserId}-{Player:GetAttribute("ID")}) has issued a search \z
        warrant for the residence at {ResidenceConfig[building].AddressShort}\z
        {apartment and `, Apartment {apartment}` or ""}.`,
        "PoliceLog"
    )

    return true, `Search warrant successfully issued for the residence at \z
        {ResidenceConfig[building].AddressShort}\z
        {apartment and `, Apartment {apartment}` or ""}. Please present the \z
        warrant to a locksmith, and they will provide you with the keys for \z
        the residence and the storage.`
end

---Toggle the authorization of a tactical deployment
---@param Player Player The Player toggling the tactical deployment
TacticalDeployment.OnServerEvent:Connect(function(Player: Player)
    if not usingTerminal[Player] then
        return false, "Access denied.", warn(
            `{script}.TacticalDeployment.OnServerEvent: {Player} is not \z
            currently logged into a police terminal!`
        )
    end

    local rank: number = Player:GetAttribute("PoliceRank") or 0
    if rank < 4 then
        return warn(
            `{script}.TacticalDeployment.OnServerEvent: {Player} does not \z
            have the sufficient rank in order to authorize a tactical \z
            deployment! (Expected 4, got {rank})`
        )
    end

    local division: string = Player:GetAttribute("PoliceDivision")
    if not PoliceConfig.OfficerTitles[division] then
        return warn(
            `{script}.TacticalDeployment.OnServerEvent: {Player} is a \z
            member of an unknown division! ({division})`
        )
    end

    local deployed: boolean = not ReplicatedStorage:GetAttribute(
        `{division}TacticalDeployment`
    )
    ReplicatedStorage:SetAttribute(`{division}TacticalDeployment`, deployed)

    for i, Recipient: Player in ipairs(Players:GetPlayers()) do
        if Recipient:GetAttribute("PoliceDivision") == division then
            SendNotification:FireClient(Recipient, {
                Title = `{deployed and "T" or "End of t"}actical deployment`;
                Text = `The tactical deployment of the {division} division of \z
                    the Ministry of Internal Affairs has \z
                    {deployed and "been authorized" or "ended"}. Please \z
                    {deployed and "retrieve your" or "return all"} tactical \z
                    equipment {deployed and "from" or "to"} the MIA armory.`;
                Duration = 10;
            })
        end
    end
end)

local module = {}

---Set up a new police terminal
---@param Screen Part The screen for the terminal
---@return table
module.new = function(Screen: Part)
    local Terminal = {}

    local TerminalPrompt: ProximityPrompt = Util.CreateInstance(
        "ProximityPrompt",
        {
            ActionText = "Access terminal";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Parent = Screen:FindFirstChildWhichIsA("Attachment")
                or Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(-0.5, 0, 0);
                    Name = "PromptAttachment";
                    Parent = Screen;
                });
            RequiresLineOfSight = true;
        }
    )

    TerminalPrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{Screen:GetFullName()}.TerminalPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Screen:GetFullName()}.TerminalPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Screen:GetFullName()}.TerminalPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        if Player:GetAttribute("Occupation") ~= "MIA" then
            SendNotification:FireClient(Player, {
                Title = "Access restricted";
                Text = "You must be a member of the Ministry of Internal \z
                Affairs in order to access this terminal.";
                Duration = 10;
            })
            return warn(
                `{script}.{Screen:GetFullName()}.TerminalPrompt.Triggered: \z
                {Player} is not an officer of the MIA!`
            )
        end

        TerminalPrompt.Enabled = false
        usingTerminal[Player] = true
        local PoliceTerminal: ScreenGui = TerminalUI:Clone()
        TerminalClient:Clone().Parent = PoliceTerminal

        local CloseTerminal: RemoteEvent = Util.CreateInstance("RemoteEvent", {
            Name = "CloseTerminal";
            Parent = PoliceTerminal;
        })

        local active
        local function exitTerminal()
            if active then
                return
            end

            active = true
            usingTerminal[Player] = false
            TerminalPrompt.Enabled = true
            PoliceTerminal:Destroy()
        end

        Humanoid.Died:Once(exitTerminal)
        Player.AncestryChanged:Once(exitTerminal)
        CloseTerminal.OnServerEvent:Connect(function(Closer: Player)
            if Closer ~= Player then
                return warn(
                    `{script}.{Player}.PoliceTerminal.CloseTerminal: {Closer} \z
                    attempted to close {Player}'s police terminal GUI!`
                )
            end

            exitTerminal()
        end)
        
        PoliceTerminal.Parent = Player.PlayerGui

        while
            Player:DistanceFromCharacter(
                TerminalPrompt.Parent.WorldCFrame.Position
            ) < TerminalPrompt.MaxActivationDistance * 2
        do
            task.wait(0.25)
        end
        exitTerminal()
    end)

    return Terminal
end

return module