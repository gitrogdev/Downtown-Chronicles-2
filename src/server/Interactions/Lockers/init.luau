--Handles all interactions with lockers on the server
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local Lockers = {}
for i, LockerConfig in ipairs(script.Lockers:GetChildren()) do
    Lockers[LockerConfig.Name] = require(LockerConfig)
end

local ServerScripts = ServerScriptService.ServerScripts
local Util = require(ServerScripts.Util)

local module = {}

---Set up a new locker
---@param Model Instance The locker to set up
---@return table
module.new = function(Model: Instance)
    local Locker = {}

    Locker.Handle = Model:FindFirstChild("Handle")
    if not Locker.Handle then
        return warn(`{script}.new: No handle found for {Model:GetFullName()}!`)
    end

    Locker.Key = Model:GetAttribute("Key")
    if not Locker.Key then
        return warn(`{script}.new: No key found for {Model:GetFullName()}!`)
    end

    Locker.Config = Lockers[Locker.Key]
    if not Locker.Config then
        return warn(`{script}.new: No config found with key {Locker.Key}!`)
    end

    local LockerPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = Locker.Config.PromptText or "Change clothing";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 8;
        Parent = Locker.Handle:FindFirstChildWhichIsA("Attachment")
            or Util.CreateInstance("Attachment", {
                CFrame = CFrame.new(-0.25, 0, 0);
                Name = "PromptAttachment";
                Parent = Locker.Handle;
            });
        RequiresLineOfSight = true;
    })

    ---Check a player out into the locker
    ---@param Player Player
    Locker.In = function(Player: Player)
        Player:SetAttribute("UsingLocker", Locker.Key)
        
        local equippedAccessories = {}
        for clothingType, value in pairs(Locker.Config.Clothing or {}) do
            value = typeof(value) == "function" and value(Player) or value
            if clothingType == "Accessories" then
                for i, accessory_name in ipairs(value) do
                    local Equipped: PVInstance = Util.EquipAccessory(
                        Player.Character, accessory_name
                    )
                    if Equipped then
                        Equipped:SetAttribute("FromLocker", Locker.Key)
                        table.insert(equippedAccessories, accessory_name)
                    end
                end
            else
                Player:SetAttribute("ClothesStored", true)
                Player:SetAttribute(`Saved{clothingType}`,
                    Player:GetAttribute(`Saved{clothingType}`)
                    or Player:GetAttribute(clothingType)
                )
                Player:SetAttribute(
                    clothingType, value
                )
            end
        end

        if #equippedAccessories > 0 then
            Player:SetAttribute("LockerAccessories", HttpService:JSONEncode(
                equippedAccessories
            ))
        end

        if Locker.Config.In then
            Locker.Config.In(Player)
        end
    end

    ---Check a player out of the locker
    ---@param Player Player
    Locker.Out = function(Player: Player)
        Player:SetAttribute("UsingLocker", nil)

        for clothingType, key in pairs(Locker.Config.Clothing or {}) do
            Player:SetAttribute("ClothesStored", false)
            Player:SetAttribute(
                clothingType, Player:GetAttribute(`Saved{clothingType}`)
            )
            Player:SetAttribute(`Saved{clothingType}`, nil)
        end

        for i, Child: Instance in ipairs(Player.Character:GetChildren()) do
            if Child:GetAttribute("FromLocker") == Locker.Key then
                Child:Destroy()
            end
        end
        Player:SetAttribute("LockerAccessories", nil)

        if Locker.Config.Out then
            Locker.Config.Out(Player)
        end
    end

    LockerPrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{Model:GetFullName()}.LockerPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Model:GetFullName()}.LockerPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Model:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        if not Locker.Config.Restriction(Player) then
            return warn(
                `{script}.{Model:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is restricted from opening lockers with the key \z
                {Locker.Key}!`
            )
        end

        if
            Player:GetAttribute("UsingLocker")
            and Player:GetAttribute("UsingLocker") ~= Locker.Key
        then
            return warn(
                `{script}.{Model:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is currently using the locker \z
                {Player:GetAttribute("UsingLocker")} and can not therefore \z
                use the {Locker.Key} locker!`
            )
        end

        Locker[
            Player:GetAttribute("UsingLocker") and "Out" or "In"
        ](Player)
    end)

    return Locker
end

return module