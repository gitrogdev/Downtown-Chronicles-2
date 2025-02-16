--The /testrtp command used for checking the current RTP of slot machines
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local InteractionHandler = require(ServerScripts.Interactions)
local Util = require(ServerScripts.Util)

local command = {
    PrimaryAlias = "/slotrtp";
    SecondaryAlias = "/testrtp";
    
    PermissionLevel = 5;
    Execute = function(Player: Player)
        local Machine
        for i, Check in ipairs(InteractionHandler.SlotMachines) do
            if not Check.User then
                Machine = Check
                break
            end
        end
        if not Machine then
            return "No available slot machine found. Try again later."
        end

        Machine.Bet = 1
        Machine.User = true
        Machine.Won = 0
        Machine.UpdateLine("Machine currently undergoing recalculation", 1)
        
        ---The nested loops and waiting avoid the script timing out
        for i = 1, 100 do
            for j = 1, 10000 do
                Machine.Spin(true)
            end
            task.wait()
        end
        local rtp = Machine.Won / (Machine.Config.MinBet * 1000000) * 100
        Machine.Reset()

        return `Slot machine RTP calculated as {Util.Round(rtp, 2)}%.`
    end
}

return command