--Handles all occupation related tasks on the server
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Jobs = {}

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ClockOut = ReplicatedCommunication.ClockOut
local QuitJob = ReplicatedCommunication.QuitJob
local SendNotification = ReplicatedCommunication.SendNotification
local StartJob = ReplicatedCommunication.StartJob
local TakeJob = ReplicatedCommunication.TakeJob

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local Badges = require(ServerConfig.Badges)

local PrivateStorage = ServerStorage.PrivateStorage

---Quit the Player's current job
---@param Player Player The Player quitting the job
---@return any
QuitJob.OnServerInvoke = function(Player: Player)
    local job = Player:GetAttribute("Occupation")
    local JobHandler = Jobs[job]
    if not JobHandler then
        return warn(
            `{script}.QuitJob.OnServerInvoke: Got unknown job "{job}" from \z
            {Player}!`
        )
    end

    if Player:GetAttribute("Working") then
        return warn(
            `{script}.QuitJob.OnServerInvoke: {Player} attempted to quit \z
            their job as a {job} while on duty!`
        )
    end

    local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
        Player:GetAttribute("ID")
    }`)
    if PrivatePlayer then
        PrivatePlayer:SetAttribute(`{job}Experience`, 0)
        PrivatePlayer:SetAttribute(`{job}Paycheck`, 0)
    end
    Player:SetAttribute("Occupation", "Unemployed")
    return true
end

---Clock in for a given job
---@param Player Player The Player clocking in
---@param job string The job the Player is starting
---@return any
StartJob.OnServerInvoke = function(Player: Player, job: string)
    local JobHandler = Jobs[job]
    if not JobHandler then
        return warn(
            `{script}.StartJob.OnServerInvoke: Got unknown job "{job}" from \z
            {Player}!`
        )
    end

    if Player:GetAttribute("Occupation") ~= job then
        return warn(
            `{script}.StartJob.OnServerInvoke: {Player} is not employed as a \z
            {job}!`
        )
    end

    if Player:GetAttribute("Working") then
        return warn(
            `{script}.StartJob.OnServerInvoke: {Player} has already started a \z
            shift as a {job}!`
        )
    end

    Player:SetAttribute("Working", true)
    JobHandler.Start(Player)
    return true
end

---Assign a Player the requested job
---@param Player Player The Player requesting the job
---@param job string The job being requested
---@return any
TakeJob.OnServerInvoke = function(Player: Player, job: string)
    local JobHandler = Jobs[job]
    if not JobHandler then
        return warn(
            `{script}.TakeJob.OnServerInvoke: Got unknown job "{job}" from \z
            {Player}!`
        )
    end

    local occupation = Player:GetAttribute("Occupation")
    if occupation and occupation ~= "Unemployed" then
        return warn(
            `{script}.TakeJob.OnServerInvoke: {Player} is already employed as \z
            a {occupation}!`
        )
    end

    local success, response = JobHandler.Requirements(Player)
    if not success then
        return response
    end
    Player:SetAttribute("Occupation", job)

    local jobBadge = JobHandler.AwardBadge
    if jobBadge then
        local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
            Player:GetAttribute("ID")
        }`)
        if not PrivatePlayer:GetAttribute(`Badge{jobBadge}`) then
            BadgeService:AwardBadge(Player.UserId, Badges[jobBadge])
            if not RunService:IsStudio() then
                PrivatePlayer:SetAttribute(`Badge{jobBadge}`, true)
            end
        end
    end

    return true
end

local module = {}
---Clock out of the current job
---@param Player Player The Player clocking out
---@return any
ClockOut.OnServerInvoke = function(Player: Player)
    local job = Player:GetAttribute("Occupation")
    local JobHandler = Jobs[job]
    if not JobHandler then
        return warn(
            `{script}.ClockOut.OnServerInvoke: Got unknown job "{job}" from \z
            {Player}!`
        )
    end

    if not Player:GetAttribute("Working") then
        return warn(
            `{script}.ClockOut.OnServerInvoke: {Player} is not currently \z
            working as a {job}!`
        )
    end

    Player:SetAttribute("Working", false)

    module.Paycheck(Player, job)

    JobHandler.End(Player)
    return true
end

---Add money to a Player's next paycheck for completing a job
---@param Player Player The Player to pay
---@param amount number The amount to pay the Player
---@return number
module.Pay = function(Player: Player, amount: number)
    local payout = math.floor(amount
        * (Player.MembershipType == Enum.MembershipType.Premium and 1.2 or 1)
        * (#Players:GetPlayers() < 5 and 1.5 or 1)
    )

    local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
        Player:GetAttribute("ID")
    }`)
    if PrivatePlayer then
        PrivatePlayer:SetAttribute(
            `{Player:GetAttribute("Occupation")}Paycheck`,
            (PrivatePlayer:GetAttribute(
                `{Player:GetAttribute("Occupation")}Paycheck`
            ) or 0) + payout
        )

        PrivatePlayer:SetAttribute(
            `{Player:GetAttribute("Occupation")}Experience`,
            (PrivatePlayer:GetAttribute(
                `{Player:GetAttribute("Occupation")}Experience`
            ) or 0) + 1
        )
    end

    return payout
end

---Pay out a player's pay check
---@param Player Player The Player to pay
---@param job string The job to pay the player for
module.Paycheck = function(Player: Player, job: string)
    local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
        Player:GetAttribute("ID")
    }`)
    if PrivatePlayer then
        local pay = PrivatePlayer:GetAttribute(`{job}Paycheck`) or 0
        if pay > 0 then
            PrivatePlayer:SetAttribute(`{job}Paycheck`, 0)
            Player:SetAttribute(
                "BankBalance",
                Player:GetAttribute("BankBalance") + pay
            )
            SendNotification:FireClient(Player, {
                Title = "Paycheck received";
                Text = `You have been paid ₲{pay} for your work as a {job}!`;
                Duration = 10;
            })
            WebhookHandler.Post(
                `{Player:GetAttribute("FullName")} ({Player}) has been paid \z
                ₲{Util.ThousandsSeparate(pay)} for their work as a {job}. \z
                Current balance in bank: ₲{Util.ThousandsSeparate(
                    Player:GetAttribute("BankBalance")
                )}`,
                "BankLog"
            )
        end
    end
end

for i, Child in ipairs(script:GetChildren()) do
    Jobs[Child.Name] = require(Child)
    Jobs[Child.Name].JHPass(module)
end
return module