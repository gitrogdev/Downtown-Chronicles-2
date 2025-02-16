--Handles evidence deposits on the server
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local SendNotification = ReplicatedCommunication.SendNotification

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local InventoryHandler
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local module = {}

---Deposit a piece of evidence into the locker
---@param Deposit Tool The piece of evidence being deposited to the locker
---@param Player Player The Player depositing the evidence (optional)
module.Deposit = function(Deposit: Tool, Player: Player)
    local filename: string = Deposit:GetAttribute("FileName")
    local itemName: string = Deposit:GetAttribute("DisplayName")
        or filename
        or Deposit.Name
    local itemConfig: table = InventoryHandler.Items.Items[filename]
    if not itemConfig then
        return warn(
            `{script}.Deposit: No item config found for item with file name \z
            {filename}!`
        )
    end
    
    if itemConfig.DontDrop then
        if Player then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = `{itemName} can not be dropped, and therefore cannot \z
                    be deposited!`;
                Duration = 10;
            })
        end

        return warn(
            `{script}.Deposit: The item with file name {filename} can not be \z
            dropped or thrown away!`
        )
    end

    Deposit:Destroy()

    if Player then
        Util.RoleplayAction(
            Player.Character.Head,
            `*$\{Associated} deposits a {itemName} into \z
            evidence.`
        )
    end

    local index: number
    local useSet: number = DataHandler.Get("NorthEvidence", "Sets") or 0
    DataHandler.Update("NorthEvidence", `Set{useSet}`, function(set: table)
        set = set or {}
        table.insert(set, {
            FileName = filename;
            GUID = Deposit.Name;
            Attributes = Deposit:GetAttributes();
        })
        index = #set

        if #set >= 999 then
            DataHandler.Set("NorthEvidence", "Sets", useSet + 1)
        end

        return set
    end)

    local serial: number = Deposit:GetAttribute("SerialNo")
    WebhookHandler.Post(
        `# Exhibit #{useSet}{string.format("%03d", index)} submitted to \z
        evidence\n**Deposited by**: {
            Player and `{Player:GetAttribute("FullName")} \z
            ({Player.UserId}-{Player:GetAttribute("ID")})`
            or "North Bloxford Correctional Facility"
        }\n**Item type**: {itemName} ({filename})\z
        {serial and `\n**Serial number**: {string.format("%012d", serial)}`
        or ""}`,
        "EvidenceLog"
    )
end

---Creates a local reference to the InventoryHandler module
---@param Handler table The InventoryHandler module
module.IHPass = function(Handler: table)
    InventoryHandler = Handler
end

---Set up a new evidence locker
---@param Handle Part The handle of the evidence locker
---@return table
module.NewLocker = function(Handle: Part)
    local Locker = {}

    local LockerPrompt: ProximityPrompt = Util.CreateInstance(
        "ProximityPrompt",
        {
            ActionText = "Deposit evidence";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Parent = Handle:FindFirstChildWhichIsA("Attachment")
                or Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(0, 0, 0.5);
                    Name = "PromptAttachment";
                    Parent = Handle;
                });
            RequiresLineOfSight = true;
        }
    )

    LockerPrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        if Player:GetAttribute("Occupation") ~= "MIA" then
            SendNotification:FireClient(Player, {
                Title = "Access restricted";
                Text = "You must be a member of the Ministry of Internal \z
                Affairs in order to access this locker.";
                Duration = 10;
            })
            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is not an officer of the MIA!`
            )
        end

        local Deposit: Tool = Player.Character:FindFirstChildOfClass("Tool")
        if not Deposit then
            SendNotification:FireClient(Player, {
                Title = "Error";
                Text = "You must be holding an item in your hand to use this!";
                Duration = 10;
            })

            return warn(
                `{script}.{Handle:GetFullName()}.LockerPrompt.Triggered: \z
                {Player} is not holding a tool!`
            )
        end

        module.Deposit(Deposit, Player)
    end)

    return Locker
end

return module