--Controls the Incarcerated GUI on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainGui: ScreenGui = script.Parent
local Background: Frame = MainGui:WaitForChild("Background")
local Body: TextLabel = Background:WaitForChild("Body")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Util = require(ReplicatedScripts.Util)

local Player = Players.LocalPlayer

if Player:GetAttribute("DeathRow") then
    Body.Text = "You have been put on death row. In order for your execution \z
        to take place, it must be approved by the Colonel General of North \z
        Bloxford. Do not delete your character, as your execution may not be \z
        approved."
else
    local incarceratedTo = Player:GetAttribute("IncarceratedTo") or 0
    local timestamp = os.date("!*t", incarceratedTo - 36000)
    local hour = timestamp.hour
    local afternoon = (timestamp.hour < 12 or timestamp.hour == 24) and "AM"
        or "PM"

    Player:GetAttributeChangedSignal("IncarceratedTo"):Connect(function()
        incarceratedTo = Player:GetAttribute("IncarceratedTo") or 0
        timestamp = os.date("!*t", incarceratedTo - 36000)
        hour = timestamp.hour
        afternoon = (timestamp.hour < 12 or timestamp.hour == 24) and "AM"
            or "PM"
    end)

    while incarceratedTo > os.time() do
        local timeLeft: string = Util.ReadableTime(
            incarceratedTo - os.time(), true
        )
        Body.Text = `You have been incarcerated until {hour}:\z
            {string.format("%02d", timestamp.min)} {afternoon} on \z
            {Util.Months[timestamp.month]} {Util.Ordinal(timestamp.day)}, \z
            {timestamp.year}. {timeLeft} remain\z
            {timeLeft:sub(#timeLeft) == "s" and "" or "s"} in your sentence. \z
            You do not have to remain in game to serve the sentence; you may \z
            leave the game or play on another character.`
        task.wait(1)
    end
end