--The /winnings used for getting a player's total casino winnings
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local PrivateStorage = ServerStorage.PrivateStorage

local command = {
    PrimaryAlias = "/winnings";
    SecondaryAlias = "/rtp";
    
    PermissionLevel = 2;
    ArgSequence = {
        "Player"
    };
    Execute = function(Player: Player, Target: Player)
        local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
            Target:GetAttribute("ID")
        }`)
        if not PrivatePlayer then
            return `No winnings found for {Target}!`
        end

        local winnings = PrivatePlayer:GetAttribute("CasinoWinnings") or 0
        local losses = PrivatePlayer:GetAttribute("CasinoLosses") or 0

        --Prevents dividing by 0
        if losses == 0 then
            return `No winnings found for {Target}!`
        end

        local difference = winnings - losses
        return `{Target:GetAttribute("FullName")} ({Target}) has won \z
            ₲{Util.ThousandsSeparate(winnings)} and lost \z
            ₲{Util.ThousandsSeparate(losses)} \z
            ({Util.Round(winnings/losses * 100, 2)}% RTP, total \z
            {difference > 0 and "profit" or "loss"} of \z
            ₲{Util.ThousandsSeparate(math.abs(difference))})`
    end
}

return command