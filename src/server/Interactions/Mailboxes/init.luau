--This script handles interactions with mailboxes on the client
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local ProductIds = require(ReplicatedConfig.Products)

local SendNotification = ReplicatedCommunication.SendNotification

local ServerScripts = ServerScriptService.ServerScripts
local FirearmsLicenses = require(ServerScripts.Citizenship.FirearmsLicenses)
local HomeHandler = require(ServerScripts.Homes)
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local ResidenceConfig = require(ServerScripts.Homes.Residences)

local PrivateStorage = ServerStorage.PrivateStorage

local STIMULUS = 2500

local module = {}

module.new = function(Model: BasePart)
    local building = Model:GetAttribute("Building")
    if not building then
        return warn(
            `{script}.new: No building found for mailbox {Model:GetFullName()}!`
        )
    end

    local buildingConfig = ResidenceConfig[building]
    if not buildingConfig then
        return warn(`{script}.new: No config found for building {building}.`)
    end

    local MailboxPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Check mail";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 8;
        Parent = Model:FindFirstChildWhichIsA("Attachment")
            or Util.CreateInstance("Attachment", {
                CFrame = CFrame.new(-1.25, 0, 0);
                Name = "PromptAttachment";
                Parent = Model;
            });
        RequiresLineOfSight = true;
    })

    MailboxPrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{Model:GetFullName()}.MailboxPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Model:GetFullName()}.MailboxPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Model:GetFullName()}.MailboxPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        if not HomeHandler.LivesIn(Player, building) then
            SendNotification:FireClient(Player, {
                Title = "Not a resident";
                Text = "You do not have a mailbox in this building!";
                Duration = 10;
            })
            return warn(
                `{script}.{Model:GetFullName()}.MailboxPrompt.Triggered: \z
                {Player} does not live in {building}!`
            )
        end

        local gotMail

        local rentDue, dueAt = HomeHandler.RentDue(Player)
        if rentDue then
            gotMail = true
            local timestamp = dueAt + 2592000

            if MarketplaceService:UserOwnsGamePassAsync(
                Player.UserId, ProductIds.Squatter
            ) then
                HomeHandler.HandleRent(Player)
                SendNotification:FireClient(Player, {
                    Title = "Rent due";
                    Text = "Your rent payment arrived in the mail, but you \z
                    don't have any intention of paying it, nor do you need \z
                    to, you're not leaving.";
                    Duration = 10;
                })
            else
                SendNotification:FireClient(Player, {
                    Title = "Rent due";
                    Text = `Your rent in the amount of ₲\z
                    {Util.ThousandsSeparate(buildingConfig.Price)} is due! If \z
                    it is not paid by {os.date("%d", timestamp)} \z
                    {os.date("%B", timestamp)}, you will be evicted! You can \z
                    pay it at the People's Bank of North Bloxell.`;
                    Duration = 10;
                })
            end
        end

        local statuses = {"Approved", "Rejected"}
        for license, info in pairs(FirearmsLicenses) do
            for i, status in ipairs(statuses) do
                if Player:GetAttribute(`{status}North{license}`) then
                    gotMail = true
                    SendNotification:FireClient(Player, {
                        Title = "Application results";
                        Text = `The results of your {info.Name} application \z
                        have arrived! You can get them at the police station.`;
                        Duration = 10;
                    })
                    break
                end
            end
        end

        local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
            Player:GetAttribute("ID")
        }`)
        if PrivatePlayer then
            local date = os.date("!*t", os.time() - 36000)
            local writtenDate = `{date.day}.{date.month}.{date.year}.`
            if PrivatePlayer:GetAttribute("Stimulus") ~= writtenDate then
                gotMail = true

                local payout = STIMULUS
                if Util.GetAge(Player) > 64 then
                    payout *= 2
                end

                local balance = Player:GetAttribute("BankBalance")
                Player:SetAttribute("BankBalance", balance + payout)
                PrivatePlayer:SetAttribute("Stimulus", writtenDate)

                SendNotification:FireClient(Player, {
                    Title = "Stimulus check";
                    Text = `Your stimulus check in the amount of ₲\z
                    {Util.ThousandsSeparate(payout)} has arrived!`;
                    Duration = 10;
                })

                WebhookHandler.Post(
                    `{Player:GetAttribute("FullName")} ({Player}) has \z
                    collected their daily stimulus check of \z
                    ₲{Util.ThousandsSeparate(payout)}. Current balance in \z
                    bank: ₲{Util.ThousandsSeparate(
                        Player:GetAttribute("BankBalance")
                    )}`,
                    "BankLog"
                )
            end
        end

        if not gotMail then
            SendNotification:FireClient(Player, {
                Title = "No mail";
                Text = "You do not have any mail.";
                Duration = 10;
            })
        end
    end)

    return MailboxPrompt
end

return module