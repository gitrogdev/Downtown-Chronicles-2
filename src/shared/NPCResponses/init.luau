--All responses used in NPC interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local Util = require(ReplicatedScripts.Util)

local MarkResponseRead = ReplicatedCommunication.MarkResponseRead

local FIREARMS_LICENSES = {
    "HDP";
    "LTC";
    "MGP";
}

local module = {}

---Responds with a Player's bank balance
---@param Player Player The Player to respond to
---@return string
module.BankBalance = function(Player: Player)
    return `The balance of your account is \z
    ₲{Util.ThousandsSeparate(Player:GetAttribute("BankBalance") or 0)}. \z
    Is there anything else I can do for you today?`
end

---Responds with the results of a Player's firearms license application
---@param Player Player The Player to respond to
---@return string
module.LicenseResults = function(Player: Player)
    for i, license in ipairs(FIREARMS_LICENSES) do
        local key = `Rejected{Player:GetAttribute("Citizenship")}{license}`
        if Player:GetAttribute(key) then
            MarkResponseRead:FireServer(license)
            return `Here's the response for your {license} application: \z
                Rejected: "{Player:GetAttribute(key)}"`
        end

        key = `Approved{Player:GetAttribute("Citizenship")}{license}`
        if Player:GetAttribute(key) then
            MarkResponseRead:FireServer(license)
            return `Your {license} application has been approved! Here's your \z
                card. Let me know if we can help you with anything else.`
        end
    end

    return "We haven't gotten any update yet. Check back soon!"
end

---Responds with a job offer to join the Ministry of Internal Affairs
---@param Player Player The Player to respond to
---@return string
module.PoliceOffer = function(Player: Player)
    if Player:GetAttribute("PoliceOffer") ~= "" then
        return `You've received an offer to join the Ministry of Internal \z
            Affairs {Player:GetAttribute("PoliceOffer")} Division! Would you \z
            like to accept this offer?`
    end

    return "You don't currently have any offers to join a division of the \z
        Ministry of Internal Affairs. If you're interested, please attend a \z
        tryout hosted by one of our captains."
end

return module