--This script handles team creation and assignment
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")

local TeamConfig = require(script.Teams)

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local onTeam = {}

---Determines whether to display a Team on the list
---@param Team Team The Team to be updated
---@param joining boolean Whether the team is currently being joined
local function updateTeam(Team: Team, joining: boolean)
    local playerCount = (joining and 1) or 0
    for i, Player in ipairs(Players:GetPlayers()) do
        if Player.Team == Team then
            playerCount += 1
        end
    end

    Team.Parent = (playerCount > 0 and Teams) or nil
end

Players.PlayerRemoving:Connect(function(Player: Player)
    if onTeam[Player] then
        updateTeam(onTeam[Player])
        onTeam[Player] = nil
    end
end)

local module = {}

---Adds a Player to a team
---@param Player Player The Player joining the Team
---@param team string The name of the Team to join
module.Join = function(Player: Player, team: string)
    local Team = module.Teams[team]
    if not Team then
        return warn(`{script}.Join: No team found with name {team}`)
    end

    
    local lastTeam = Player.Team
    updateTeam(Team, true)

    onTeam[Player] = Team
    Player.Team = Team

    --In case the player's previous team is now empty
    if lastTeam then
        updateTeam(lastTeam)
    end
end

---Creates all Teams used in game
module.Setup = function()
    module.Teams = {}
    for teamName, properties in pairs(TeamConfig) do
        local Team = Util.CreateInstance("Team", properties)
        Team.AutoAssignable = false
        Team.Name = teamName
        module.Teams[teamName] = Team
    end
end

return module