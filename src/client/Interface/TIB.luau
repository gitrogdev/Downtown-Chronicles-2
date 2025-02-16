--This script displays TIB on the client interface
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Util = require(ReplicatedScripts.Util)

local module = {}

---Starts updating the LocalPlayer's TIB and displaying on the HUD
---@param Display TextLabel The TextLabel to write the TIB to
module.Listen = function(Display: TextLabel)
    task.spawn(function()
        repeat
            Display.Text = `{Util.GetTIB(Player)} TIB`
        until not task.wait(1)
    end)
end

return module