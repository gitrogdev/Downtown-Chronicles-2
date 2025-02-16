--This script contains all security-related functions for the game
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(script.Config)

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local Rules = require(ReplicatedConfig.Rules)
local ClothingConfig = require(ReplicatedConfig.Clothing)

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local RemovedClothing = require(ServerConfig.RemovedClothing)

local PrivateStorage = ServerStorage:FindFirstChild("PrivateStorage") or
    Util.CreateInstance("Folder", {
        Name = "PrivateStorage";
        Parent = ServerStorage;
    })

local module = {}

---Monitor a Player's activity, and kick them if they've been idle too long
---@param Player Player The Player to monitor the activity of
module.AntiAFK = function(Player: Player)
    local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
        Player:GetAttribute("ID")
    }`)

    local updates = {
        Player.Chatted;
        Player.PlayerGui.Inventory.AttributeChanged;
        Player.PlayerGui.Inventory.ChildAdded;
        PrivatePlayer:GetAttributeChangedSignal("BartenderPaycheck");
        PrivatePlayer:GetAttributeChangedSignal("CasinoTime");
    }

    local lastTime = os.time()
    for i, update in ipairs(updates) do
        update:Connect(function()
            print(`{script}.AntiAFK: Got interaction from {Player}.`)
            lastTime = os.time()
        end)
    end

    task.spawn(function()
        while Player.Parent == Players do
            if lastTime + (Config.AFKTime * 60) < os.time() then
                Player:SetAttribute(
                    "LoadedAt",
                    Player:GetAttribute("LoadedAt") + (Config.AFKTime * 120)
                )

                local kickReason = `You have been kicked from the game for \z
                    idling for more than \z
                    {Util.ReadableTime(Config.AFKTime * 60)}.`
                if Config.ResetPay[Player:GetAttribute("Occupation")] then
                    PrivatePlayer:SetAttribute(
                        `{Player:GetAttribute("Occupation")}Paycheck`, 0
                    )
                    kickReason ..= " Your paycheck has been reset."
                end

                Player:Kick(kickReason)
                WebhookHandler.Post(
                    `{Player} has been kicked from the game for idling for \z
                    more than {Util.ReadableTime(Config.AFKTime * 60)}.`,
                    "ModLog"
                )
                break
            end
            task.wait(1)
        end
    end)
end

---Bans a player from the game, and returns the duration of the ban
---@param userId number The UserId of the Player to ban from the game
---@param reason string The Roman numeric value of the rule to ban the player for
---@param Source Player The Player credited for the ban (defaults to "Server")
---@param perm boolean Whether to ban the player permanently
---@param subtle boolean Whether to ban the player without also kicking them
---@return number
module.Ban = function(
    userId: number,
    reason: string,
    Source: Player,
    perm: boolean,
    subtle: boolean
)
    local banData = Rules.RomanDictionary[reason]
    if not banData then
        return warn(`{script}.Ban: Unable to ban {userId} for reason {reason}!`)
    end

    local duration = (perm and -1)
    or (banData.Punishment * 86400) --86,400 seconds = 1 day

    task.spawn(function()
        if subtle then
            while Players:GetPlayerByUserId(userId) do
                task.wait(1)
            end
        end
        
        local success = false
        local response
        while not success do
            success, response = pcall(Players.BanAsync, Players, {
                UserIds = {userId};
                Duration = duration;
                DisplayReason = banData.Name;
                PrivateReason = `Banned by \z
                    {Source and Source.Name or "the server"} for \z
                    {banData.Name:lower()}.`
            })
            if not success then
                warn(
                    `{script}.Ban: Failed to ban Player with User ID \z
                    {userId}: {response}`
                )
                task.wait(1)
            end
        end
    end)

    WebhookHandler.Post(
        `{Players:GetNameFromUserIdAsync(userId)} has been banned by {
            (Source and Source.Name)
            or "the server"
        } for{(
            (perm and "ever")
            or ` {Util.ReadableTime(duration)}`
        )} for {banData.Name:lower()}`,
        "ModLog"
    )

    return duration
end

---Checks for conflicts with clothing and removed clothing
---@return boolean
module.ClothingConflicts = function(): boolean
    local conflicts = false

    for key, value in pairs(RemovedClothing) do
        if ClothingConfig[key] then
            warn(
                `{script}.ClothingConflicts: Conflict found with removed \z
                clothing item "{key}" and existing clothing item!`
            )
            conflicts = true
        end
    end

    return not conflicts
end

---Ensures that all packages are from the same version of the game
---@return boolean
module.IntegrityCheck = function()
    local gameVersion
    for i, Package in ipairs(Config.Packages) do
        local PackageVersion = Package:FindFirstChild("GameVersion")
        if not PackageVersion then
            ReplicatedStorage:SetAttribute(
                "Version",
                gameVersion or "Missing version"
            )
            return warn(
                `{script}.IntegrityCheck: \z
                No package version found for {Package}!`
            )
        end

        gameVersion = gameVersion or PackageVersion.Value
        if PackageVersion.Value ~= gameVersion then
            ReplicatedStorage:SetAttribute("Version", PackageVersion.Value)
            return warn(
                `{script}.IntegrityCheck: Version misalignment detected: \z
                {Config.Packages[1]} is on \z
                {Config.Packages[1].GameVersion.Value}, \z
                while {Package} is on {PackageVersion.Value}`
            )
        end
    end

    ReplicatedStorage:SetAttribute("Version", gameVersion)
    return true
end

---Creates honeypot remotes which will ban the offender when triggered
module.PlantHoneypots = function()
    for i, honeypot in ipairs(Config.Honeypots) do
        Util.CreateInstance("RemoteFunction", {
            Name = honeypot;
            Parent = ReplicatedCommunication;
        }).OnServerInvoke = function(Player: Player)
            module.Ban(Player.UserId, "IX", nil, false, true)
        end
    end
end

---Unbans a player from the game
---@param userId number The UserId of the Player to unban from the game
---@param Source Player The Player to credit for the unban
module.Unban = function(userId: number, Source: Player)
    Players:UnbanAsync({
        UserIds = {userId};
    })

    WebhookHandler.Post(
        `{Players:GetNameFromUserIdAsync(userId)} has been unbanned by {
            (Source and Source.Name)
            or "the server"
        }`,
        "ModLog"
    )
end

return module