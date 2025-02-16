--Adjusts slot machine odds and jackpot amounds based on previous payouts
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(script.Parent.Config)

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local Util = require(ServerScripts.Util)

local betSum = 0
local displays = {}
local games = 0
local jackpot = DataHandler.Get("Jackpot", "Cumulative") or 0
local winSum = 0

local module = {}

module.AddDisplay = function(Machine: table, Display: SurfaceGui)
    local Background = Display:WaitForChild("Background")
    local JackpotRule = Background:WaitForChild("JackpotRule")
    local MultiplierDisplay = JackpotRule:WaitForChild("Multiplier")
    local RuleHolder = JackpotRule:WaitForChild("RuleHolder")
    local GoldJackpot = RuleHolder:WaitForChild("Jackpot1")
    local SilverJackpot = RuleHolder:WaitForChild("Jackpot2")
    local BronzeJackpot = RuleHolder:WaitForChild("Jackpot3")

    local function updateDisplay()
        local add = math.floor(jackpot)
        GoldJackpot.Text = `₲\z
            {Util.ThousandsSeparate((Config.Jackpot.Rules[5] + add)
            * (Machine.Bet or 1) * 2 ^ 5 + add)}`
        SilverJackpot.Text = `₲\z
            {Util.ThousandsSeparate((Config.Jackpot.Rules[4] + add)
            * (Machine.Bet or 1) * 2 ^ 4 + add)}`
        BronzeJackpot.Text = `₲\z
            {Util.ThousandsSeparate((Config.Jackpot.Rules[3] + add)
            * (Machine.Bet or 1) * 2 ^ 3 + add)}`

        local useOdds = math.floor(module.JackpotOdds() * (
            (typeof(Machine.User) == "Instance" and Machine.User.MembershipType
            == Enum.MembershipType.Premium) and 0.8 or 1
        ))
        if useOdds < Config.Jackpot.Odds then
            MultiplierDisplay.Text =
                `+{Util.Round((1 - (useOdds / Config.Jackpot.Odds)) * 100, 1)}\z
                % Chance Multiplier`
        else
            MultiplierDisplay.Text = ""
        end
    end

    table.insert(displays, updateDisplay)

    updateDisplay()
    return updateDisplay
end

---Add the results of a game to the list of completed games
---@param won number The amount won
---@param bet number The amount bet
module.Game = function(won: number, bet: number)
    betSum += bet
    games += 1
    jackpot += bet * 0.01
    winSum += won

    for i, update in ipairs(displays) do
        update()
    end
end

---Determine the odds of rolling a jackpot reel
---@return number
module.JackpotOdds = function(log: boolean)
    --Wait until the sample size is large enough
    if games < 100 then
        return Config.Jackpot.Odds
    end

    local rtp = winSum/betSum * 100
    if rtp > Config.RTPTarget then
        return Config.Jackpot.Odds
    end

    local diff = Config.RTPTarget - rtp
    if log then
        print(rtp, diff)
    end

    return Config.Jackpot.Odds - (diff * 0.52)
end

---Payout and reset the cumulative jackpot
---@return any
module.WinJackpot = function()
    local payout = math.floor(jackpot)
    jackpot = 0
    print(`{script}.WinJackpot: Paying out cumulative jackpot of ₲{payout} \z
        (Jackpot Odds: {module.JackpotOdds(true)})!`)
    return payout
end

game:BindToClose(function()
    if not RunService:IsStudio() then
        DataHandler.Set("Jackpot", "Cumulative", jackpot)
    end
end)

return module