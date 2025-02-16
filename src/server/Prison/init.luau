--Handle the incarceration of prisoners on the server
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local IncarceratedClient = script.Incarcerated

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local FadeTeleport = ReplicatedCommunication.FadeTeleport
local SendNotification = ReplicatedCommunication.SendNotification

local InventoryConfig = require(ReplicatedConfig.Inventory)

local ServerScripts = ServerScriptService.ServerScripts
local CitizenshipHandler = require(ServerScripts.Citizenship)
local EvidenceHandler = require(ServerScripts.Interactions.Evidence)
local InventoryHandler
local TeamHandler = require(ServerScripts.Teams)
local Util = require(ServerScripts.Util)

local PrivateStorage = ServerStorage.PrivateStorage
local UserInterface = ServerStorage.UserInterface
local IncarceratedGui: ScreenGui = UserInterface.IncarceratedGui
local ReleaseGui: ScreenGui = UserInterface.ReleaseGui

local lockdown
local LockdownPrompts = {}
local function toggleLockdown()
    lockdown = not lockdown
    for i, Event: BindableEvent in ipairs(
        CollectionService:GetTagged("NBCFCell")
    ) do
        Event:Fire(not lockdown)
    end

    for i, LockdownPrompt:ProximityPrompt in ipairs(LockdownPrompts) do
        LockdownPrompt.ActionText = lockdown and "Unlock cells"
            or "Lockdown cells"
    end
end

local module = {}

---Deposits all a player's belongings into evidence
---@param Player Player
module.ConfiscateInventory = function(Player: Player)
    local Inventory = Player:FindFirstChild("PlayerGui")
        and Player.PlayerGui:FindFirstChild("Inventory")
        or Player:WaitForChild("Inventory")
    if Inventory then
        for slot, guid in pairs(Inventory:GetAttributes()) do
            local Tool: Tool = Inventory:FindFirstChild(guid)
            if Tool then
                Inventory:SetAttribute(slot, nil)
                EvidenceHandler.Deposit(Tool)
            end
        end

        local Equipped: Tool = Player.Character
            and Player.Character:FindFirstChildOfClass("Tool")
        if Equipped then
            Inventory:SetAttribute("Equipped", nil)
            EvidenceHandler.Deposit(Equipped)
        end
    end
end

---Creates a local reference to the InventoryHandler module
---@param Handler table The InventoryHandler module
module.IHPass = function(Handler: table)
    InventoryHandler = Handler
end

---Imprison a player for the crimes they've been charged with
---@param Player Player The Player to imprison
module.Imprison = function(Player: Player)
    if Player:GetAttribute("Pants") ~= "NBCFBottom" then
        Player:SetAttribute("SavedPants", Player:GetAttribute("SavedPants")
            or Player:GetAttribute("Pants")
        )
        Player:SetAttribute("Pants", "NBCFBottom")
    end

    if Player:GetAttribute("Shirt") ~= "NBCFTop" then
        Player:SetAttribute("SavedShirt", Player:GetAttribute("SavedShirt")
            or Player:GetAttribute("Shirt")
        )
        Player:SetAttribute("Shirt", "NBCFTop")
    end

    Player:SetAttribute("Incarcerated", true)

    module.ConfiscateInventory(Player)

    local IncarceratedDisplay: ScreenGui = IncarceratedGui:Clone()
    IncarceratedClient:Clone().Parent = IncarceratedDisplay
    IncarceratedDisplay.Parent = Player.PlayerGui

    if not Player:GetAttribute("DeathRow") then
        task.spawn(function()
            local Character: Model = Player.Character
                or Player.CharacterAdded:Wait()
            local Humanoid: Humanoid = Character:FindFirstChildOfClass(
                "Humanoid"
            )
            repeat
                task.wait(1)
            until (
                Player:GetAttribute("IncarceratedTo") < os.time()
                or Humanoid.Health <= 0
                or not Character:IsDescendantOf(workspace)
            )
            IncarceratedDisplay:Destroy()

            if Character:IsDescendantOf(workspace) and Humanoid.Health > 0 then
                local ReleaseDisplay: ScreenGui = ReleaseGui:Clone()
                local Body: TextLabel = ReleaseDisplay:WaitForChild(
                    "Background"
                ):WaitForChild("Body")
                local originalText: string = Body.Text
                ReleaseDisplay.Parent = Player.PlayerGui

                while
                    Character:IsDescendantOf(workspace) and Humanoid.Health > 0
                do
                    local broke = true
                    task.wait(1)
                    for i, Cell: SpawnLocation in ipairs(
                        CollectionService:GetTagged("NBCF")
                    ) do
                        local dist: number = Player:DistanceFromCharacter(
                            Cell.Position
                        )
                        if dist > 0 and dist < 10 then
                            broke = false
                            for j = 0, 59 do
                                dist = Player:DistanceFromCharacter(
                                    Cell.Position
                                )
                                Body.Text = `You will be released from prison \z
                                    in {60 - j} second\z
                                    {j == 59 and "" or "s"}. Your sentence is \z
                                    complete. Your personal effects will be \z
                                    returned to you upon release.`
                                if not (dist > 0 and dist < 10) then
                                    broke = true
                                    break
                                end
                                task.wait(1)
                            end
            
                            if not broke then
                                ReleaseDisplay:Destroy()
                                FadeTeleport:FireClient(Player, Util.RandomFrom(
                                    CollectionService:GetTagged("NBCFRelease")
                                ).CFrame)
                                task.wait(1)
                                break
                            else
                                Body.Text = originalText
                            end
                        end
                    end
                    if not broke then
                        break
                    end
                end

                print(
                    `{script}.Imprison: Releasing \z
                    {Player:GetAttribute("FullName")} ({Player}) from prison!`
                )
                
                if Player.Parent == Players then
                    Player:SetAttribute("Incarcerated", false)

                    TeamHandler.Join(Player, CitizenshipHandler.ToTeam(
                        Player:GetAttribute("Citizenship")
                    ))
        
                    if Player:GetAttribute("Pants") == "NBCFBottom" then
                        Player:SetAttribute(
                            "Pants", Player:GetAttribute("SavedPants")
                        )
                        Player:SetAttribute("SavedPants", nil)
                    end
                
                    if Player:GetAttribute("Shirt") == "NBCFTop" then
                        Player:SetAttribute(
                            "Shirt", Player:GetAttribute("SavedShirt")
                        )
                        Player:SetAttribute("SavedShirt", nil)
                    end 
                end

                if Humanoid.Health > 0 and Character:IsDescendantOf(workspace) then
                    if Player:GetAttribute("Felon") then
                        module.PunishFelon(Player)
                    end

                    for i, item: string in ipairs(InventoryConfig.StarterPack) do
                        InventoryHandler.Add(
                            Player,
                            InventoryHandler.Items.new(
                                item,
                                `{Player:GetAttribute("FullName")}'s StarterPack`
                            )
                        )
                    end
                end
            end
        end)
    end
end

---Set up a lockdown button
---@param Button Part The button to be pressed
---@return RBXScriptConnection
module.LockdownButton = function(Button: Part)
    local LockdownPrompt: ProximityPrompt = Util.CreateInstance(
        "ProximityPrompt",
        {
            ActionText = "Lockdown cells";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Parent = Button:FindFirstChildWhichIsA("Attachment")
                or Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(0.25, 0, 0);
                    Name = "PromptAttachment";
                    Parent = Button;
                });
            RequiresLineOfSight = true;
        }
    )
    table.insert(LockdownPrompts, LockdownPrompt)

    return LockdownPrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{Button:GetFullName()}.LockdownPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{Button:GetFullName()}.LockdownPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{Button:GetFullName()}.LockdownPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        if Player:GetAttribute("Occupation") ~= "MIA" then
            return warn(
                `{script}.{Button:GetFullName()}.LockdownPrompt.Triggered: \z
                {Player} is not a member of the Ministry of Internal Affairs!`
            )
        end

        toggleLockdown()
    end)
end

---Take away certain legal privileges afforded to a Player after being arrested
---@param Player Player The Player to revoke the privileges from
module.PunishFelon = function(Player: Player)
    local restrictedJobs = {"Guardsman", "Sanitation"}
    local revoke = {"LTC", "HDP", "MGP"}
    for i, license: string in ipairs(revoke) do
        if Player:GetAttribute(`North{license}`) then
            Player:SetAttribute(`North{license}`, false)
            SendNotification:FireClient(Player, {
                Title = "License revoked";
                Text = `In connection with your recent felony conviction, \z
                your {license} has been revoked, effective immediately.`;
                Duration = 10;
            })
        end
    end

    for i, job: string in ipairs(restrictedJobs) do
        if Player:GetAttribute("Occupation") == job then
            Player:SetAttribute("Occupation", "Unemployed")
            local PrivatePlayer = PrivateStorage:FindFirstChild(`Character{
                Player:GetAttribute("ID")
            }`)
            if PrivatePlayer then
                PrivatePlayer:SetAttribute(`{job}Experience`, 0)
                PrivatePlayer:SetAttribute(`{job}Paycheck`, 0)
            end
            SendNotification:FireClient(Player, {
                Title = "License revoked";
                Text = `In connection with your recent felony conviction, \z
                you have been dismissed from your position as a {job}.`;
                Duration = 10;
            })
            break
        end
    end
end

return module