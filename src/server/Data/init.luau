--This script handles all interactions with Roblox DataStores
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(script.Config)

local Master_DS = DataStoreService:GetDataStore(Config.MasterKey)

local module = {}

---Gets an entry from a DataStore
---@param store string The DataStore to read from
---@param key string The key to read from
---@return any
module.Get = function(store: string, key:string)
    local function request()
        local dsKey = `{store}_{key}`
        print(`{script}.Get: Reading from {dsKey}`)

        local value, success
        while not success do
            success, value = pcall(Master_DS.GetAsync, Master_DS, dsKey)
            if not success then
                warn(`{script}.Get: \z
                    Encountered an error getting data from DataStore! \z
                    {value}`
                )
            end
        end

        if RunService:IsStudio() then
            print(value)
        end
        
        return value
    end

    return request()
end

---Sets an entry in a DataStore
---@param store string The DataStore to write to
---@param key string The key to write to
---@param data any The data to write
---@param async boolean Whether to make the request asynchronously
module.Set = function(store: string, key: string, data: any, async: boolean)
    local function request()
        local dsKey = `{store}_{key}`

        local success
        while not success do
            print(`{script}.Set: Writing to {dsKey}`)
            local funcSuccess, response = pcall(
                Master_DS.SetAsync,
                Master_DS,
                dsKey,
                data
            )
            if not funcSuccess then
                warn(`{script}.Set: \z
                    Encountered an error setting data to DataStore! \z
                    {response}`
                )
            elseif not module.Get(store, key) == data then
                warn(
                    `{script}.Set: Failed to write to {key} in DataStore \z
                    {store}!`
                )
            else success = true
            end
        end
    end

    if async then
        task.spawn(request)
    else
        request()
    end
end

---Removes an entry from a DataStore
---@param store string The DataStore to remove from
---@param key string The key to remove from
---@param async boolean Whether to make the request asynchronously
module.Remove = function(store: string, key:string, async: boolean)
    local function request()
        local dsKey = `{store}_{key}`
        print(`{script}.Remove: Erasing from {dsKey}`)

        local success, response
        while not success do
            success, response = pcall(
                Master_DS.RemoveAsync,
                Master_DS,
                dsKey
            )
            if not success then
                warn(`{script}.Remove: \z
                    Encountered an error removing data from DataStore! \z
                    {response}`
                )
            end
        end
    end

    if async then
        task.spawn(request)
    else
        request()
    end
end

---Updates an entry in a DataStore
---@param store string The DataStore to write to
---@param key string The key to write to
---@param update function The function used to update the data
---@param async boolean Whether to make the request asynchronously
module.Update = function(
    store: string,
    key: string,
    update: () -> (),
    async: boolean
)
    local function request()
        local dsKey = `{store}_{key}`
        print(`{script}.Update: Updating to {dsKey}`)

        local success, response
        while not success do
            success, response = pcall(
                Master_DS.UpdateAsync,
                Master_DS,
                dsKey,
                update
            )
            if not success then
                warn(`{script}.Update: \z
                    Encountered an error updating data in DataStore! \z
                    {response}`
                )
            end
        end
    end

    if async then
        task.spawn(request)
    else
        request()
    end
end

return module