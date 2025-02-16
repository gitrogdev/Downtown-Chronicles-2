--This script contains basic configuration that applies to webhooks
local config = {}

config.DiscordCharLimit = 2000
config.DiscordRateLimit = 30 --requests per 60 seconds

config.Proxy = "localhost" --replace with proxy server URL

return config