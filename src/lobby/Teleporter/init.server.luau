--Handles teleportation into the reserved server for the game
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local Config = require(script.Config)

local Master_DS = DataStoreService:GetDataStore(Config.MasterKey)

local UserInterface = ServerStorage.UserInterface
local AntiAltGui: ScreenGui = UserInterface:WaitForChild("AntiAltGui")

local function getCode()
    local code = TeleportService:ReserveServer(Config.MainPlace)
    Master_DS:SetAsync(Config.ReservedKey, code)
    return code
end

local reserved = Master_DS:GetAsync(Config.ReservedKey) or getCode()

local function playerAdded(Player: Player)
    if Player.AccountAge < 365 and Player:GetRankInGroup(Config.Group) < 25 then
        local showDiscord
        local policyInfo = PolicyService:GetPolicyInfoForPlayerAsync(Player)
        for i, link in ipairs(policyInfo.AllowedExternalLinkReferences) do
            if link == "Discord" then
                showDiscord = true
                break
            end
        end

        local AltWarning: ScreenGui = AntiAltGui:Clone()
        local WarningDisplay: TextLabel = AltWarning:WaitForChild("Warning")
        WarningDisplay.Text = `In order to prevent the abuse of alternative \z
            accounts in our game, we require that any Roblox account under \z
            the age of one year be manually approved by our staff team in \z
            order to join the game. If you'd like to play, please reach out \z
            to us through {showDiscord and "our Discord server, linked in the \z
            Social Links section of the game's page" or "the Bigman Studios \z
            Roblox group"}. We apologize for any inconvenience this has \z
            caused. This is a security measure we take to ensure that our \z
            game and community remain a safe and fun experience for all of \z
            our players.`
        AltWarning.Parent = Player:WaitForChild("PlayerGui")
        return
    end

    TeleportService:TeleportToPrivateServer(
        Config.MainPlace, reserved, {Player}
    )
end

for i, Player in ipairs(Players:GetPlayers()) do
    playerAdded(Player)
end
Players.PlayerAdded:Connect(playerAdded)