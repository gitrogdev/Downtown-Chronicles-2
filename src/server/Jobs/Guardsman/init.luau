--Handles all natinoal guard related tasks on the server
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedConfig = ReplicatedScripts.Configuration
local JobConfig = require(ReplicatedConfig.Jobs.Guardsman)

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local JobHandler

local module = {}

module.AwardBadge = "NorthGuard"

---Creates a local reference to the JobHandler module
---@param Handler table The JobHandler module
module.JHPass = function(Handler: table)
    JobHandler = Handler
end

---Check if a Player meets the requirements for the job
---@param Player Player The Player applying for the job
---@return boolean
---@return string
module.Requirements = function(Player: Player)
    if not Player:GetAttribute("PBNBAccount") then
        return false, "NoBank", warn(
            `{script}.Requirements: {Player} does not have a bank account!`
        )
    end

    if Player:GetAttribute("Citizenship") ~= "North" then
        return false, "NotCitizen", warn(
            `{script}.Requirements: {Player} is not a citizen of North Bloxell!`
        )
    end

    if Util.GetAge(Player) < 17 then
        return false, "Underage", warn(
            `{script}.Requirements: {Player}'s character is underage!`
        )
    end

    if Player:GetAttribute("NGDischarged") then
        return false, "Discharged", warn(
            `{script}.Requirements: {Player}'s has been previously discharged \z
            from the national guard!`
        )
    end

    if Player:GetAttribute("Felon") then
        return false, "Felon", warn(
            `{script}.Requirements: {Player} is a felon!`
        )
    end

    if ReplicatedStorage:GetAttribute("Emergency") then
        return false, "Emergency", warn(
            `{script}.Requirements: There is currently an active state of \z
            emergency!`
        )
    end

    return true
end

---Start the guardsman job for a given Player
---@param Player Player The Player to start the job for
module.Start = function(Player: Player)
    task.spawn(function()
        local session = (Player:GetAttribute("WorkSession") or 0) + 1
        Player:SetAttribute("WorkSession", session)

        while
            Player.Parent == Players
            and Player:GetAttribute("Working")
            and Player:GetAttribute("WorkSession") == session
        do
            task.wait(60)
            if
                Player.Parent == Players
                and Player:GetAttribute("Working")
                and Player:GetAttribute("WorkSession") == session
            then
                JobHandler.Pay(
                    Player, JobConfig.BasePay
                    * (ReplicatedStorage:GetAttribute("Emergency") and 3 or 1)
                )
            end
        end
    end)
end

return module