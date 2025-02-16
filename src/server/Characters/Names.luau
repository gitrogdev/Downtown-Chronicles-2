--This script handles all processing of names on the server-side during character customization
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts

local ReplicatedConfig = ReplicatedScripts.Configuration
local CustomizationConfig = require(ReplicatedConfig.Customization)
local Config = CustomizationConfig.Names

local ServerScripts = ServerScriptService.ServerScripts
local WebhookHandler = require(ServerScripts.Webhooks)

local module = {}

---Submits a name request to the Discord webhook for staff review
---@param first string The first name
---@param last string The surname
---@param gender boolean The gender (male = false, female = true)
---@param charId number The ID of the character
---@param Player Player The Player submitting the request
module.Submit = function(
    first: string,
    last: string,
    gender: boolean,
    charId: number,
    Player: Player
)
    WebhookHandler.Post(
        `REQUEST FROM\n\z
        PLAYER - {Player} ({Player.UserId})\n\z
        FIRST - {first}\n\z
        LAST - {last}\n\z
        GENDER - {((gender and "F") or "M")}\n\z
        ID - {charId}`,
        "NameRequests"
    )
end

---Validates whether a name is valid given first name `first` and surname `last`
---@param first string The first name
---@param last string The surname
---@return boolean
module.Validate = function(first: string, last: string)
    if not (type(first) == "string" and type(last) == "string") then
        return warn(`{script}.Validate: Names must be strings!`)
    end

    if (#first < Config.MinLength or #last < Config.MinLength) then
        return warn(`{script}.Validate: Name "{first} {last}" too short!`)
    end

    if (#first > Config.MaxLength or #last > Config.MaxLength) then
        return warn(`{script}.Validate: Name "{first} {last}" too long!`)
    end

    for i, forbidden in ipairs(Config.ForbiddenCharacters) do
        if first:find(forbidden) or last:find(forbidden) then
            return warn(`{script}.Validate: \z
                Forbidden character "{forbidden}" found in name \z
                "{first} {last}"!`
            )
        end
    end

    return true
end

return module