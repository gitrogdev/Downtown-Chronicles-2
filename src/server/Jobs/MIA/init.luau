--Handles all sanitation related tasks on the server
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CuffedClient = script.Cuffed
local CuffsClient = script.Handcuffs
local KeyClient = script.CuffKey
local GrabbedClient = script.Grabbed
local GrabbingClient = script.Grabbing

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local HandcuffPlayer = ReplicatedCommunication.HandcuffPlayer
local RespondPoliceOffer = ReplicatedCommunication.RespondPoliceOffer
local SendNotification = ReplicatedCommunication.SendNotification

local PoliceConfig = require(ReplicatedConfig.Police)
local Sounds = require(ReplicatedConfig.Sounds)

local ServerScripts = ServerScriptService.ServerScripts
local DataHandler = require(ServerScripts.Data)
local InventoryHandler
local JobHandler
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local PartStorage: Folder = ServerStorage.Parts
local ToolStorage: Folder = PartStorage.Tools

---Lock a player in handcuffs
---@param Player Player The player locking a player in handcuffs
---@param Target Player The player being locked in handcuffs
HandcuffPlayer.OnServerEvent:Connect(function(Player: Player, Target: Player)
    local Character: Model = Player.Character
    if not Character then
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: {Player} does not have a \z
            loaded character!`
        )
    end

    local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not (Humanoid and Humanoid.Health > 0) then
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: {Player} does not have a \z
            living Humanoid!`
        )
    end

    local Handcuffs: Tool = Player.Character:FindFirstChildOfClass("Tool")
    if
        not (Handcuffs and Handcuffs:GetAttribute("FileName") == "Handcuffs")
    then
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: {Player} does not have \z
            handcuffs equipped!`
        )
    end

    local TargetChar: Model = Target.Character
    if not TargetChar then
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: No character found for \z
            {Target}!`
        )
    end

    local TargetHuman: Humanoid = TargetChar:FindFirstChildOfClass("Humanoid")
    if not (TargetHuman and TargetHuman.Health > 0) then
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: {Target} does not have a \z
            living Humanoid!`
        )
    end

    if TargetChar:GetAttribute("Cuffed") then
        SendNotification:FireClient(Player, {
            Title = "Unable to handcuff";
            Text = `{Target:GetAttribute("FullName")} is already in handcuffs!`;
            Duration = 10;
        })
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: {Target} is already in \z
            handcuffs!`
        )
    end

    if TargetChar:FindFirstChildOfClass("Tool") then
        SendNotification:FireClient(Player, {
            Title = "Unable to handcuff";
            Text = `{Target:GetAttribute("FullName")} has a tool equipped, \z
                and can not be put in handcuffs until it is unequipped!`;
            Duration = 10;
        })
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: {Target} has a tool \z
            equipped!`
        )
    end

    local RightArm: Part = TargetChar:FindFirstChild("Right Arm")
    if not RightArm then
        SendNotification:FireClient(Player, {
            Title = "Unable to handcuff";
            Text = `{Target:GetAttribute("FullName")} is missing their right \z
                arm, and can not be handcuffed!`;
            Duration = 10;
        })
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: {Target} does not have a \z
            right arm!`
        )
    end

    local distance = Target:DistanceFromCharacter(Humanoid.RootPart.Position)
    if distance == 0 or distance > 8 then
        SendNotification:FireClient(Player, {
            Title = "Unable to handcuff";
            Text = `{Target:GetAttribute("FullName")} is too far away to be \z
                handcuffed!`;
            Duration = 10;
        })
        return warn(
            `{script}.HandcuffPlayer.OnServerInvoke: {Target} is too far from \z
            {Player} to be handcuffed! ({Util.Round(distance, 2)} studs)`
        )
    end

    local CuffAttachment: Attachment = Util.CreateInstance("Attachment", {
        CFrame = CFrame.new(-0.372, -0.97, 0.762) * CFrame.Angles(
            math.rad(10), math.rad(0), math.rad(41.155)
        );
        Name = "HandcuffAttachment";
        Parent = RightArm;
    })

    local CuffSound: Sound = Util.CreateInstance("Sound", {
        Parent = TargetHuman.RootPart;
        SoundId = Sounds.LockHandcuffs;
    })

    CuffSound.Ended:Once(function()
        CuffSound:Destroy()
    end)

    local GrabbedBy: Player
    local GrabberDied: RBXScriptConnection
    local GrabberEquipped: RBXScriptConnection
    local GrabberLeft: RBXScriptConnection
    local GrabPrompt: ProximityPrompt = Util.CreateInstance("ProximityPrompt", {
        ActionText = "Grab";
        ClickablePrompt = true;
        HoldDuration = 0.5;
        KeyboardKeyCode = Enum.KeyCode.E;
        MaxActivationDistance = 4;
        Parent = CuffAttachment;
        RequiresLineOfSight = true;
    })
    CollectionService:AddTag(GrabPrompt, "GrabPrompt")
    local ReleaseGrab: RemoteEvent
    local TargetDied: RBXScriptConnection
    local TargetLeft: RBXScriptConnection

    CuffedClient:Clone().Parent = TargetChar
    CuffSound:Play()
    TargetChar:SetAttribute("Cuffed", true)
    Handcuffs.Parent = script

    local function uncuff()
        if GrabbedBy then
            GrabbedBy.Character:SetAttribute("Grabbing", nil)
            GrabbedBy = nil
        end

        if GrabberDied then
            GrabberDied:Disconnect()
        end

        if GrabberEquipped then
            GrabberEquipped:Disconnect()
        end

        if GrabberLeft then
            GrabberLeft:Disconnect()
        end

        if ReleaseGrab then
            ReleaseGrab:Destroy()
        end
        CuffAttachment:Destroy()
        GrabPrompt:Destroy()
        TargetChar:SetAttribute("Cuffed", nil)
        TargetDied:Disconnect()
        TargetLeft:Disconnect()
    end

    GrabPrompt.Triggered:Connect(function(Triggerer: Player)
        if Triggerer == Target then
            return warn(
                `{script}.{Target}.GrabPrompt.Triggered: {Triggerer} \z
                attempted to grab themselves!`
            )
        end

        local TriggerChar: Model = Triggerer.Character
        if not TriggerChar then
            return warn(
                `{script}.{Target}.GrabPrompt.Triggered.Triggered: No \z
                Character found for {Triggerer}!`
            )
        end

        local TriggerHuman: Humanoid = TriggerChar:FindFirstChildOfClass(
            "Humanoid"
        )
        if not TriggerHuman then
            return warn(
                `{script}.{Target}.GrabPrompt.Triggered: No Humanoid found \z
                for {Player}!`
            )
        end

        if TriggerHuman.Health <= 0 then
            return warn(
                `{script}.{Target}.GrabPrompt.Triggered: {Triggerer} is dead!`
            )
        end

        if TriggerChar:GetAttribute("Grabbing") then
            SendNotification:FireClient(Triggerer, {
                Title = "Unable to grab";
                Text = "You are already grabbing another character!";
                Duration = 10;
            })
            return warn(
                `{script}.{Target}.GrabPrompt.Triggered: {Triggerer} is \z
                already grabbing a character!`
            )
        end

        local Key: Tool = TriggerChar:FindFirstChildOfClass("Tool")
        if Key and Key:GetAttribute("FileName") ~= "HandcuffKey" then
            SendNotification:FireClient(Triggerer, {
                Title = "Unable to grab";
                Text = "You currently have a tool equipped!";
                Duration = 10;
            })
            return warn(
                `{script}.{Target}.GrabPrompt.Triggered: {Triggerer} has a \z
                tool equipped!`
            )
        end

        if Key then
            local UnlockSound: Sound = Util.CreateInstance("Sound", {
                Parent = TargetHuman.RootPart;
                SoundId = Sounds.UnlockHandcuffs;
            })

            UnlockSound.Ended:Once(function()
                UnlockSound:Destroy()
            end)

            UnlockSound:Play()

            InventoryHandler.Add(Triggerer, Handcuffs, nil, true)
            return uncuff()
        end

        GrabbedBy = Triggerer
        GrabPrompt.Enabled = false
        ReleaseGrab = Util.CreateInstance("RemoteEvent", {
            Name = "ReleaseGrab";
            Parent = TargetChar;
        })
        TriggerChar:SetAttribute("Grabbing", Target.UserId)
        TargetHuman.RootPart:SetNetworkOwner(Triggerer)
        GrabbedClient:Clone().Parent = Target.PlayerGui
        GrabbingClient:Clone().Parent = Triggerer.PlayerGui

        local function release()
            if GrabbedBy.Character then
                GrabbedBy.Character:SetAttribute("Grabbing", nil)
            end

            if GrabberDied then
                GrabberDied:Disconnect()
            end

            if GrabberEquipped then
                GrabberEquipped:Disconnect()
            end
    

            if GrabberLeft then
                GrabberLeft:Disconnect()
            end

            GrabbedBy = nil
            GrabberDied = nil
            GrabberEquipped = nil
            GrabberLeft = nil
            GrabPrompt.Enabled = true
            ReleaseGrab:Destroy()
            TargetHuman.RootPart:SetNetworkOwner(Target)
        end

        ReleaseGrab.OnServerEvent:Connect(function(Releaser: Player)
            if Releaser ~= GrabbedBy then
                return warn(
                    `{script}.{Target}.ReleaseGrab.OnServerEvent: {Releaser} \z
                    is not grabbing {Target} (grabbed by {GrabbedBy})`
                )
            end

            release()
        end)

        GrabberDied = TriggerHuman.Died:Once(release)
        GrabberEquipped = TriggerChar.ChildAdded:Connect(function(
            Child: Instance
        )
            if Child:IsA("Tool") then
                release()
            end
        end)
        GrabberLeft = Triggerer.AncestryChanged:Once(release)
    end)

    TargetDied = TargetHuman.Died:Once(uncuff)
    TargetLeft = Target.AncestryChanged:Once(uncuff)
end)

---Respond to an offer to join the MIA
---@param Player Player The Player responding to the offer
---@param response boolean The response to the offer
---@return any
RespondPoliceOffer.OnServerInvoke = function(Player: Player, response: boolean)
    local division = Player:GetAttribute("PoliceOffer")
    if (not division) or division == "" then
        return warn(
            `{script}.RespondPoliceOffer.OnServerInvoke: {Player} does not \z
            have an offer to join the Ministry of Internal Affairs!`
        )
    end

    if not PoliceConfig.OfficerTitles[division] then
        return warn(
            `{script}.RespondPoliceOffer.OnServerInvoke: {Player} has an \z
            offer to join an unknown division of the Ministry of Internal \z
            Affairs! ({division})`
        )
    end

    Player:SetAttribute("PoliceOffer", "")
    if response then
        Player:SetAttribute("Occupation", "MIA")
        Player:SetAttribute("PoliceDivision", division)
        Player:SetAttribute("PoliceRank", 1)
        Player:SetAttribute("PoliceSince", os.time())

        DataHandler.Update("Characters", tostring(Player:GetAttribute("ID")),
            function(charData: table)
                charData.Occupation = "MIA"
                charData.PoliceDivision = division
                charData.PoliceOffer = ""
                charData.PoliceRank = 1
                charData.PoliceSince = os.time()

                return charData
            end
        )

        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player} \z
            {Player.UserId}-{Player:GetAttribute("ID")}) has accepted an \z
            offer to join the {division:lower()} division of the \z
            Ministry of Internal Affairs, North Bloxford Administration.`,
            "PoliceLog"
        )
    else
        WebhookHandler.Post(
            `{Player:GetAttribute("FullName")} ({Player} \z
            {Player.UserId}-{Player:GetAttribute("ID")}) has declined an \z
            offer to join the {division:lower()} division of the \z
            Ministry of Internal Affairs, North Bloxford Administration.`,
            "PoliceLog"
        )
    end
    return true
end

local module = {}

---Creates a local reference to the InventoryHandler module
---@param Handler table The JobHandler module
module.IHPass = function(Handler: table)
    InventoryHandler = Handler
end

---Creates a local reference to the JobHandler module
---@param Handler table The JobHandler module
module.JHPass = function(Handler: table)
    JobHandler = Handler
end

---Create a new handcuff key
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.NewCuffKey = function(attributes: table, itemData: table)
    attributes = attributes or {
        SerialNo = Util.Serialize("Handcuffs");
    }

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    KeyClient:Clone().Parent = Tool

    return Tool
end

---Create a new pair of handcuffs
---@param attributes table The saved attributes to load
---@param itemData table The item configuration
---@return Tool
module.NewCuffs = function(attributes: table, itemData: table)
    attributes = attributes or {
        AssociateTag = "ApplyHandcuffs";
        SerialNo = Util.Serialize("Handcuffs");
    }

    attributes.DisplayName = itemData.DisplayName
    local Tool = Util.CreateInstance("Tool", {
        CanBeDropped = false;
    }, attributes)

    for i, Child in ipairs(ToolStorage[itemData.Name]:GetChildren()) do
        Child:Clone().Parent = Tool
    end
    Util.WeldChildren(Tool, Tool.Handle, true)

    CuffsClient:Clone().Parent = Tool

    return Tool
end

---Start the MIA job for a given Player
---@param Player Player The Player to start the job for
module.Start = function(Player: Player)
    task.spawn(function()
        local session = (Player:GetAttribute("WorkSession") or 0) + 1
        Player:SetAttribute("WorkSession", session)

        while
            Player.Parent == Players
            and Player:GetAttribute("Working")
            and Player:GetAttribute("WorkSession") == session
        do
            task.wait(60)
            if
                Player.Parent == Players
                and Player:GetAttribute("Working")
                and Player:GetAttribute("WorkSession") == session
            then
                JobHandler.Pay(
                    Player,
                    PoliceConfig.PayRates[Player:GetAttribute("PoliceRank")]
                )
            end
        end
    end)
end

return module