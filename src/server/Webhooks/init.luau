--This script handles the processing of all webhooks
local HttpService = game:GetService("HttpService")

local Config = require(script.Config)
local Webhooks = require(script.Webhooks)

local queue = {}

---Adds a Discord webhook push to the queue
---@param post function The request to add to the queue
local function discordQueue(post: () -> ())
    table.insert(queue, post)

    --Starts looping only if the queue is empty
    if #queue == 1 then
        local i = 1
        while #queue >= i do
            task.spawn(queue[i])
            task.wait(2)

            i = i + 1
        end
        queue = {}
    end
end

local module = {}

---Posts a message to a Discord webhook
---@param message string The message to post
---@param webhook string The webhook to post to
---@return boolean
module.Post = function(message: string, webhook: string)
    if not Webhooks[webhook] then
        return warn(`{script}.Post: Unable to find Webhook with key {webhook}`)
    end
    webhook = Webhooks[webhook]

    if #message > Config.DiscordCharLimit then
        return error(
            `{script}.Post: Webhook call exceeds Discord character limit.`
        )
    end

    local payload = {
        Message = message;
    }
    local encodedURL = module.URLEncode(payload)
    
    task.spawn(function()
        if webhook.Type == "Discord" then
            discordQueue(function()
                local response = HttpService:PostAsync(
                    `{Config.Proxy}/discord/{webhook.Link}?{encodedURL}`,
                    "",
                    Enum.HttpContentType.ApplicationUrlEncoded
                )
                print(
                    `{script}.Post: HTTP Response from Proxy Server: \z
                    "{response}"`
                )
            end)
        end
    end)
    return true
end

---Encodes the contents of a table for use in a URL
---@param arguments table The table to encode
---@return string
module.URLEncode = function(arguments: table)
    local argsString = ""

    for key, value in pairs(arguments) do
        argsString ..=
            `{HttpService:UrlEncode(key)}={HttpService:UrlEncode(value)}&`
    end

    --Removes the last character as to not end the URL with an ampersand
    argsString = argsString:sub(1, #argsString-1)

    return argsString
end

return module