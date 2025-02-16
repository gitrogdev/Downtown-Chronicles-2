--Handles the arrest and booking of criminals on the server
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local BookingClient = script.Booking

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local BookSuspect = ReplicatedCommunication.BookSuspect
local FadeTeleport = ReplicatedCommunication.FadeTeleport
local SendNotification = ReplicatedCommunication.SendNotification

local ServerScripts = ServerScriptService.ServerScripts
local ServerConfig = ServerScripts.Configuration
local DataHandler = require(ServerScripts.Data)
local JobHandler = require(ServerScripts.Jobs)
local PrisonHandler = require(ServerScripts.Prison)
local TeamHandler = require(ServerScripts.Teams)
local Util = require(ServerScripts.Util)
local WebhookHandler = require(ServerScripts.Webhooks)

local Charges = require(ServerConfig.Charges)

local UIStorage = ServerStorage.UserInterface
local BookingGui: ScreenGui = UIStorage.BookingGui
local HoldingGui: ScreenGui = UIStorage.HoldingGui

local booking = {}

local DONT_ARREST = {
    ["Ministry of Internal Affairs"] = true;
}

local MODS = {
    ["Accessory to"] = true;
    ["Attempting to"] = true;
    ["Conspiracy to"] = true;
}

---Book and charge a suspect
---@param Player Player The Player booking the suspect
---@param Suspect Player The suspect to be booked
---@param charges table The charges to charge the suspect with
---@param reason string The reason that the suspect is being charged
BookSuspect.OnServerInvoke = function(
    Player: Player, Suspect: Player, charges: table, reason: string
)
    if not booking[Player] then
        return warn(
            `{script}.BookSuspect.OnServerInvoke: {Player} is not currently \z
            booking any suspects!`
        )
    end

    if Suspect:IsA("Model") then
        for i, PotentialSuspect: Player in ipairs(Players:GetPlayers()) do
            if
                PotentialSuspect:GetAttribute("ID")
                == Suspect:GetAttribute("ID")
            then
                Suspect = PotentialSuspect
                break
            end
        end
    end

    local found
    for i, Option: Player in ipairs(booking[Player]) do
        if Option == Suspect then
            found = true
            break
        end
    end

    if not found then
        return warn(
            `{script}.BookSuspect.OnServerInvoke: {Player} is not currently \z
            able to book {Suspect}!`
        )
    end

    if #reason < 5 or #reason > 1000 then
        return warn(
            `{script}.BookSuspect.OnServerInvoke: {Player} submitted a reason \z
            with a length out of expected range! (Expected 5-1000 characters, \z
            got {#reason})`
        )
    end

    if Suspect:IsA("Player") and DONT_ARREST[Suspect.Team.Name] then
        return warn(
            `{script}.BookSuspect.OnServerInvoke: {Player} attempted to \z
            charge {Suspect}, who is currently on the {Suspect.Team.Name} \z
            team, which prevents them from being charged!`
        )
    end

    booking[Player] = nil

    local chargeLevel = "Misdemeanor"
    local chargeTime = 0
    local chargeWith = {}
    local writtenCharges = ""

    for i, charge: table in ipairs(charges) do
        local chargeInfo = Charges[charge.Key]
        if not chargeInfo then
            return warn(
                `{script}.BookSuspect.OnServerInvoke: {Player} attempted to \z
                charge {Suspect} with the unknown charge "{charge.Key}"!`
            )
        end

        if not (charge.Mod == nil or MODS[charge.Mod]) then
            return warn(
                `{script}.BookSuspect.OnServerInvoke: {Player} attempted to \z
                charge {Suspect} with {charge.Key} with the unknown modifier \z
                "{charge.Mod}"!`
            )
        end

        if chargeLevel == "Misdemeanor" and chargeInfo.Level == "Felony" then
            chargeLevel = "Felony"
        elseif
            (chargeLevel == "Misdemeanor" or chargeLevel == "Felony")
            and chargeInfo.Level == "Death"
        then
            chargeLevel = "Death"
        end

        chargeTime += chargeInfo.Sentence * (charge.Mod and 0.5 or 1)

        writtenCharges ..= `\n{charge.Mod or ""}\z
            {charge.Mod and ` {chargeInfo.WithMod}` or chargeInfo.Name}`

        table.insert(chargeWith, {
            At = os.time();
            Charge = charge.Key;
            Mod = charge.Mod;
        })
    end

    local startIncarceration =
        Suspect:GetAttribute("IncarceratedTo") > os.time() and
        Suspect:GetAttribute("IncarceratedTo") or os.time()

    if Util.GetAge(Suspect) < 18 then
        chargeTime *= 0.5
    end

    if Suspect:IsA("Player") then
        Suspect:SetAttribute("HasRecord", true)
        Suspect:SetAttribute("IncarceratedTo", startIncarceration + chargeTime)

        if chargeLevel == "Felony" then
            Suspect:SetAttribute("Felon", true)
        elseif chargeLevel == "Death" then
            Suspect:SetAttribute("DeathRow", true)
        end
    else DataHandler.Update("Characters", tostring(Suspect:GetAttribute("ID")),
        function(charData: table)
            charData = charData or {}

            charData.HasRecord = true
            charData.IncarceratedTo = startIncarceration + chargeTime
            
            if chargeLevel == "Felony" then
                charData.Felon = true
            elseif chargeLevel == "Death" then
                charData.DeathRow = true
            end

            return charData
        end)
    end

    DataHandler.Update("NorthRecords", tostring(Suspect:GetAttribute("ID")),
        function(record: table)
            record = record or {}
            for i, charge: table in ipairs(chargeWith) do
                table.insert(record, charge)
            end

            return record
        end
    )
    WebhookHandler.Post(
        `# {Suspect:GetAttribute("FullName")} ({Suspect:IsA("Player")
        and Suspect.UserId or Suspect:GetAttribute("UserId")}-\z
        {Suspect:GetAttribute("ID")}) has been put under arrest and charged\n\z
        **Arresting officer**: {Player:GetAttribute("FullName")} (\z
        {Player.UserId}-{Player:GetAttribute("ID")})\n\z
        Charged with:{writtenCharges}\n\n\z
        Description: {reason}\n\n\z
        {Suspect:GetAttribute("FullName")} has been sentenced to \z
        {chargeLevel == "Death" and "death" or
        `{Util.ReadableTime(chargeTime, true)} in prison.`}`,
        "BookingLog"
    )
    JobHandler.Pay(Player, 5000)

    if Suspect:IsA("Model") then
        return Suspect:Destroy()
    end

    Suspect:SetAttribute("Booked", true)
    TeamHandler.Join(Suspect, "Incarcerated")
    local Character: Model = Suspect.Character
    local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
    while Character:IsDescendantOf(workspace) and Humanoid.Health > 0 do
        local broke = true
        task.wait(1)
        for i, Cell: Part in ipairs(CollectionService:GetTagged("HoldingCell"))
        do
            local dist: number = Suspect:DistanceFromCharacter(Cell.Position)
            if dist > 0 and dist < 10 then
                broke = false
                local HoldingDisplay: ScreenGui = HoldingGui:Clone()
                local Body: TextLabel = HoldingDisplay:WaitForChild(
                    "Background"
                ):WaitForChild("Body")
                HoldingDisplay.Parent = Suspect.PlayerGui
                for j = 0, 59 do
                    dist = Suspect:DistanceFromCharacter(Cell.Position)
                    Body.Text = `You will be transported to the prison in \z
                        {60 - j} second{j == 59 and "" or "s"}. All booking \z
                        is complete. If you wish, you may leave the game, or \z
                        rejoin on a different character.`
                    if not (dist > 0 and dist < 10) then
                        broke = true
                        break
                    end
                    task.wait(1)
                end

                HoldingDisplay:Destroy()
                if not broke then
                    FadeTeleport:FireClient(Suspect, Util.RandomFrom(
                        CollectionService:GetTagged("NBCF")
                    ).CFrame + Vector3.new(0, 3, 0))
                    task.wait(1.5)
                    Suspect:SetAttribute("Booked", nil)
                    PrisonHandler.Imprison(Suspect)
                    break
                end
            end
        end
        if not broke then
            break
        end
    end
end

local module = {}

---Initiate a booking
---@param Player Player The Player initiating the booking
---@param Suspects table Any valid suspects for the booking
---@param BookingPrompt ProximityPrompt The BookingPrompt for the booking
module.Initiate = function(
    Player: Player, Suspects: table, BookingPrompt: ProximityPrompt
)
    local Character: Model = Player.Character
    if not Character then
        return warn(`{script}.Initiate: No Character found for {Player}!`)
    end

    local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then
        return warn(`{script}.Initiate: No Humanoid found for {Player}!`)
    end

    if Humanoid.Health <= 0 then
        return warn(`{script}.Initiate: {Player} is dead!`)
    end

    booking[Player] = Suspects
    local BookingInterface: ScreenGui = BookingGui:Clone()
    BookingClient:Clone().Parent = BookingInterface

    local active
    local function exitTerminal()
        if active then
            return
        end

        active = true
        booking[Player] = nil
        BookingInterface:Destroy()
    end

    Humanoid.Died:Once(exitTerminal)
    Player.AncestryChanged:Once(exitTerminal)
    
    BookingInterface.Parent = Player.PlayerGui
    BookingInterface:WaitForChild("TransferData"):FireClient(Player,
        Suspects, Charges
    )

    while
        ((not BookingPrompt) or Player:DistanceFromCharacter(
            BookingPrompt.Parent.WorldCFrame.Position
        ) < BookingPrompt.MaxActivationDistance * 2)
        and booking[Player]
    do
        task.wait(0.25)
    end
    exitTerminal()
end

---Set up a new booking camera
---@param BookCam Part The primary part of the booking camera model
---@return table
module.new = function(BookCam: Part)
    local BookingCamera = {}

    local BookingPrompt: ProximityPrompt = Util.CreateInstance(
        "ProximityPrompt",
        {
            ActionText = "Book suspect";
            ClickablePrompt = true;
            HoldDuration = 0.5;
            KeyboardKeyCode = Enum.KeyCode.E;
            MaxActivationDistance = 8;
            Parent = BookCam:FindFirstChildWhichIsA("Attachment")
                or Util.CreateInstance("Attachment", {
                    CFrame = CFrame.new(0, 0, 1.5);
                    Name = "PromptAttachment";
                    Parent = BookCam;
                });
            RequiresLineOfSight = true;
        }
    )

    BookingPrompt.Triggered:Connect(function(Player: Player)
        local Character = Player.Character
        if not Character then
            return warn(
                `{script}.{BookCam:GetFullName()}.BookingPrompt.Triggered: No \z
                Character found for {Player}!`
            )
        end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then
            return warn(
                `{script}.{BookCam:GetFullName()}.BookingPrompt.Triggered: No \z
                Humanoid found for {Player}!`
            )
        end

        if Humanoid.Health <= 0 then
            return warn(
                `{script}.{BookCam:GetFullName()}.BookingPrompt.Triggered: \z
                {Player} is dead!`
            )
        end

        if booking[Player] then
            return warn(
                `{script}.{BookCam:GetFullName()}.BookingPrompt.Triggered: \z
                {Player} is already using a booking camera!`
            )
        end

        if Player:GetAttribute("Occupation") ~= "MIA" then
            SendNotification:FireClient(Player, {
                Title = "Access restricted";
                Text = "You must be a member of the Ministry of Internal \z
                Affairs in order to use this device.";
                Duration = 10;
            })
            return warn(
                `{script}.{BookCam:GetFullName()}.BookingPrompt.Triggered: \z
                {Player} is not an officer of the MIA!`
            )
        end

        local Suspects = {}
        for i, Suspect: Player in ipairs(Players:GetPlayers()) do
            local distance = Suspect:DistanceFromCharacter(BookCam.Position)
            if
                Suspect ~= Player
                and distance > 0 and distance < 12
                and not DONT_ARREST[Suspect.Team.Name]
            then
                table.insert(Suspects, Suspect)
            end
        end
        if #Suspects == 0 then
            SendNotification:FireClient(Player, {
                Title = "No suspect found";
                Text = "No suspect found. Ensure the suspect is with you in \z
                    the booking room in order to book them.";
                Duration = 10;
            })
            return warn(
                `{script}.{BookCam:GetFullName()}.BookingPrompt.Triggered: No \z
                suspects found in the booking room with {Player}!`
            )
        end

        module.Initiate(Player, Suspects, BookingPrompt)
    end)

    return BookingCamera
end

return module