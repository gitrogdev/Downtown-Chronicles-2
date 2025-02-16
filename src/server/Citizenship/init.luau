--Handles citizenship and licensing processes on the server
local BadgeService = game:GetService("BadgeService")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CitizenshipConfig = require(script.Citizenships)
local LicenseAppClient = script.LicenseApplication
local LicenseConfig = require(script.FirearmsLicenses)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ApplyCitizenship = ReplicatedCommunication.ApplyCitizenship
local ApplyLicense = ReplicatedCommunication.ApplyLicense
local MarkResponseRead = ReplicatedCommunication.MarkResponseRead
local PassBack = ReplicatedCommunication.PassBack
local SendNotification = ReplicatedCommunication.SendNotification
local SubmitApplication = ReplicatedCommunication.SubmitApplication

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local MoneyHandler = require(ServerScripts.Money)
local ServerConfig = ServerScripts.Configuration
local TeamHandler = require(ServerScripts.Teams)
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local BadgeIds = require(ServerConfig.Badges)

local UIStorage = ServerStorage.UserInterface
local LicenseGui = UIStorage.LicenseApplication

---Apply for citizenship
---@param Player Player The Player applying
---@param citizenship string The citizenship being applied for
---@return any
ApplyCitizenship.OnServerInvoke = function(Player: Player, citizenship: string)
    local citizenshipConfig = CitizenshipConfig[citizenship]
    if not citizenshipConfig then
        return warn(
            `{script}.ApplyCitizenship.OnServerInvoke: {Player} applied for \z
            an unknown citizenship! ({citizenship})`
        )
    end

    if CitizenshipConfig[Player:GetAttribute("Citizenship")] then
        return warn(
            `{script}.ApplyCitizenship.OnServerInvoke: {Player} is already a \z
            citizen! ({Player:GetAttribute("Citizenship")})`
        )
    end

    if not MoneyHandler.Charge(Player, citizenshipConfig.Fee, "Cash") then
        return "Insufficient", warn(
            `{script}.ApplyCitizenship.OnServerInvoke: {Player} does not have \z
            enough money to pay the processing fee of the {citizenship} \z
            citizenship application! (₲\z
            {Util.ThousandsSeparate(citizenshipConfig.Fee)} required.)`
        )
    end

    Player:SetAttribute("Citizenship", citizenship)
    Player:SetAttribute("CitizenshipAt", os.time())
    TeamHandler.Join(Player, citizenshipConfig.Team)
    return true
end

---Apply for a firearms license
---@param Player Player The Player applying for a license
---@param license string The license being applied for
---@return string
ApplyLicense.OnServerInvoke = function(Player: Player, license: string)
    local licenseConfig = LicenseConfig[license]
    if not licenseConfig then
        return warn(
            `{script}.ApplyLicense.OnServerInvoke: {Player} applied for an \z
            unknown firearms license! ({license})`
        )
    end

    local citizenshipConfig = CitizenshipConfig[
        Player:GetAttribute("Citizenship")
    ]
    if not citizenshipConfig then
        return warn(
            `{script}.ApplyLicense.OnServerInvoke: {Player} is not a citizen! \z
            ({Player:GetAttribute("Citizenship")})`
        )
    end

    local age = Util.GetAge(Player)
    if not (age >= 18) then
        return warn(
            `{script}.ApplyLicense.OnServerInvoke: {Player} is not an adult! \z
            ({age})`
        )
    end

    local ApplicationGui = LicenseGui:Clone()
    local Background = ApplicationGui:WaitForChild("Frame")
    local Head = Background:WaitForChild("Head")
    local Body = Background:WaitForChild("Body")

    ApplicationGui:SetAttribute("Type", license)
    Head.Text = `Application for {licenseConfig.Name}`
    Body.Text = `Why do you believe that you have a need for a \z
        {licenseConfig.Name} in the {citizenshipConfig.Name}?`

    LicenseAppClient:Clone().Parent = ApplicationGui

    ApplicationGui.Parent = Player.PlayerGui
    return ApplicationGui.Name
end

---Mark a firearms license application response as read by the client
---@param Player Player The Player that read the application
---@param license string The license that was being applied for
MarkResponseRead.OnServerEvent:Connect(function(Player: Player, license: string)
    if not LicenseConfig[license] then
        return warn(
            `{script}.MarkResponseRead.OnServerEvent: "{license}" is not a \z
            recognized license type!`
        )
    end

    local approved = false
    local key = `Rejected{Player:GetAttribute("Citizenship")}{license}`
    if not Player:GetAttribute(key) then
        key = `Approved{Player:GetAttribute("Citizenship")}{license}`
        approved = true
        if not Player:GetAttribute(key) then
            return warn(
                `{script}.MarkResponseRead.OnServerEvent: No response found \z
                for {Player:GetAttribute("FullName")} ({Player}) for license \z
                {license}!`
            )
        end
    end

    if approved then
        Player:SetAttribute(
            `{Player:GetAttribute("Citizenship")}{license}`, true
        )
        BadgeService:AwardBadge(Player.UserId, BadgeIds.Licenses[license])
    end
    
    Player:SetAttribute(key, nil)
    DataHandler.Update("Characters", tostring(Player:GetAttribute("ID")),
        function(data: table)
            data = data or {}
            data[key] = nil
            return data
        end
    )
end)

---Submit a firearms application to the server
---@param Player Player The Player applying for a license
---@param license string The license being applied for
---@param app string The application text
SubmitApplication.OnServerEvent:Connect(function(
    Player: Player, license: string, app: string
)
    local ApplicationGui = Player.PlayerGui:FindFirstChild(LicenseGui.Name)
    if not ApplicationGui then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SubmitApplication.OnServerEvent: {Player} is not \z
            currently applying for a firearms license application.`
        )
    end

    if ApplicationGui:GetAttribute("Type") ~= license then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SubmitApplication.OnServerEvent: {Player} tried to \z
            apply for a {license}, while only being authorized to apply for a \z
            {ApplicationGui:GetAttribute("Type")}.`
        )
    end
    ApplicationGui:Destroy()

    local licenseConfig = LicenseConfig[license]
    if not licenseConfig then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SubmitApplication.OnServerEvent: {Player} applied for \z
            an unknown firearms license! ({license})`
        )
    end

    local citizenshipConfig = CitizenshipConfig[
        Player:GetAttribute("Citizenship")
    ]
    if not citizenshipConfig then
        PassBack:FireClient(Player)
        return warn(
            `{script}.SubmitApplication.OnServerEvent: {Player} is not a \z
            citizen! ({Player:GetAttribute("Citizenship")})`
        )
    end

    if #app < 1 then
        PassBack:FireClient(Player, "NoContent")
        return warn(
            `{script}.SubmitApplication.OnServerEvent: {Player} did not send \z
            any content in their application.`
        )
    end

    if #app >= 1024 then
        PassBack:FireClient(Player, "TooLong")
        return warn(
            `{script}.SubmitApplication.OnServerEvent: {Player} submitted an \z
            application that was too long (Expected < 1024, got {#app}).`
        )
    end

    if not MoneyHandler.Charge(Player, licenseConfig.Fee, "Cash") then
        PassBack:FireClient(Player, "Insufficient")
        return warn(
            `{script}.ApplyCitizenship.OnServerEvent: {Player} does not have \z
            enough money to pay the processing fee of the {license} \z
            firearms license application! (₲\z
            {Util.ThousandsSeparate(licenseConfig.Fee)} required.)`
        )
    end

    WebhookHandler.Post(
        `REQUEST FROM\n\z
        NAME - {Player:GetAttribute("FullName")}\n\z
        TYPE - {license}\n\z
        ID - {Player:GetAttribute("ID")}\n\z
        TEXT - {app}`,
        "LicenseApp"
    )
    PassBack:FireClient(Player, true)
end)

local module = {}

module.Citizenships = Util.KeysTable(CitizenshipConfig)
module.Licenses = Util.KeysTable(LicenseConfig)

---Checks if a citizenship exists
---@param citizenship string The citizenship to check
---@return boolean
module.IsCitizenship = function(citizenship: string)
    return not not CitizenshipConfig[citizenship]
end

---Converts a citizenship key into a team name, or "Tourist"
---@param citizenship string The citizenship of the player
---@return string
module.ToTeam = function(citizenship: string)
    return CitizenshipConfig[citizenship]
        and CitizenshipConfig[citizenship].Team or "Tourist"
end

MessagingService:SubscribeAsync("LicenseRespond", function(message: table)
    local messageData = HttpService:JSONDecode(message.Data)
    if not messageData.ID then
        return warn(
            `{script}.MessagingService.SubscribeAsync.LicenseRespond: No ID \z
            found in request {message.Data}!`
        )
    end

    for i, Player in ipairs(Players:GetPlayers()) do
        if Player:GetAttribute("ID") == tonumber(messageData.ID) then
            Player:SetAttribute(
                `{messageData.Status}North{messageData.License}`,
                messageData.Reason or true
            )
            SendNotification:FireClient(Player, {
                Title = `{messageData.License} application`;
                Text = `There has been a response to your \z
                {messageData.License} application! Head down to the police \z
                station to see it!`;
                Duration = 10;
            })
            break
        end
    end
end)

return module