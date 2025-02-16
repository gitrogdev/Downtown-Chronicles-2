--Handles the arrest and booking of suspects on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local MainGui: ScreenGui = script.Parent
local ChargeSelection: Frame = MainGui:WaitForChild("ChargeSelection")
local SuspectSelection: Frame = MainGui:WaitForChild("SuspectSelection")
local TransferData: RemoteEvent = MainGui:WaitForChild("TransferData")

local AppliedHolder: ScrollingFrame = ChargeSelection:WaitForChild("Applied")
local BookButton: TextButton = ChargeSelection:WaitForChild("BookButton")
local ChargeHead: TextLabel = ChargeSelection:WaitForChild("Head")
local ChargeHolder: ScrollingFrame = ChargeSelection:WaitForChild("Charges")
local ModHolder: Frame = ChargeSelection:WaitForChild("Mods")
local ReasonBox: TextBox = ChargeSelection:WaitForChild("ReasonBox")

local AppliedTemplate: TextButton = AppliedHolder:WaitForChild("ButtonTemplate")

local ChargeTemplate: TextButton = ChargeHolder:WaitForChild("ButtonTemplate")

local AccessoryButton: TextButton = ModHolder:WaitForChild("AccessoryButton")
local AttemptButton: TextButton = ModHolder:WaitForChild("AttemptButton")
local CommitButton: TextButton = ModHolder:WaitForChild("CommitButton")
local ConspiracyButton: TextButton = ModHolder:WaitForChild("ConspiracyButton")

local CharHolder: Frame = SuspectSelection:WaitForChild("CharacterHolder")
local SuspectTemplate: TextButton = CharHolder:WaitForChild("SuspectButton")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local BookSuspect = ReplicatedCommunication.BookSuspect

---Set up the charge selection screen for a given suspect
---@param Suspect Player The suspect to apply charges to
---@param charges table The list of charges to use
local function charge(Suspect: Player, charges: table)
    SuspectSelection.Visible = false

    local appliedCharges = {}
    local id = 0
    local ModButtons = {
        [AccessoryButton] = "Accessory to";
        [AttemptButton] = "Attempting to";
        [CommitButton] = "";
        [ConspiracyButton] = "Conspiracy to";
    }
    local selectedMod

    ChargeHead.Text = `Booking {Suspect:GetAttribute("FullName")}`

    for ModButton: TextButton, mod: string in pairs(ModButtons) do
        ModButton.MouseButton1Click:Connect(function()
            for OtherButton: TextButton, skipMod: string in pairs(ModButtons) do
                OtherButton.Style = OtherButton == ModButton
                    and Enum.ButtonStyle.RobloxRoundDefaultButton
                    or Enum.ButtonStyle.RobloxRoundButton
            end

            selectedMod = mod ~= "" and mod or nil
        end)
    end

    for key: string, chargeInfo: table in pairs(charges) do
        local ChargeButton: TextButton = ChargeTemplate:Clone()
        ChargeButton.Name = chargeInfo.Name
        ChargeButton.Text = ChargeButton.Name:upper()
        ChargeButton.Parent = ChargeHolder
        ChargeButton.Visible = true

        ChargeButton.MouseButton1Click:Connect(function()
            if #appliedCharges >= 10 then
                StarterGui:SetCore("SendNotification", {
                    Title = "Maximum charges";
                    Text = "You have reached the maximum number of charges \z
                        which can be applied in one booking.";
                    Duration = 10;
                })
                return
            end

            local AppliedButton: TextButton = AppliedTemplate:Clone()
            AppliedButton.Name = key
            AppliedButton.Text = selectedMod
                and `{selectedMod:upper()} {chargeInfo.WithMod:upper()}`
                or chargeInfo.Name:upper()
            AppliedButton.Parent = AppliedHolder
            AppliedButton.Visible = true

            local usedId = id
            id += 1

            AppliedButton.MouseButton1Click:Once(function()
                AppliedButton:Destroy()
                for i, applied: table in ipairs(appliedCharges) do
                    if applied.ID == usedId then
                        table.remove(appliedCharges, i)
                        break
                    end
                end
            end)

            table.insert(appliedCharges, {
                Key = key;
                Mod = selectedMod;
                ID = usedId;
            })
        end)
    end

    ReasonBox:GetPropertyChangedSignal("Text"):Connect(function()
        ReasonBox.Text = ReasonBox.Text:sub(1, 1000)
    end)

    BookButton.MouseButton1Click:Connect(function()
        if #appliedCharges == 0 then
            StarterGui:SetCore("SendNotification", {
                Title = "No charges";
                Text = `You have not charged \z
                    {Suspect:GetAttribute("FullName")} with anything!`;
                Duration = 10;
            })
            return
        end

        if #ReasonBox.Text < 5 then
            StarterGui:SetCore("SendNotification", {
                Title = "Insufficient description";
                Text = `Please briefly describe the reason which you are \z
                    arresting {Suspect:GetAttribute("FullName")} for.`;
                Duration = 10;
            })
            return
        end

        BookSuspect:InvokeServer(Suspect, appliedCharges, ReasonBox.Text)
    end)

    ChargeSelection.Visible = true
end

TransferData.OnClientEvent:Connect(function(Suspects: table, charges: table)
    local ButtonPresses = {}
    for i, Suspect: Player in ipairs(Suspects) do
        local SuspectButton: TextButton = SuspectTemplate:Clone()
        SuspectButton.Name = Suspect:GetAttribute("FullName")
        SuspectButton.Text = SuspectButton.Name
        SuspectButton.Parent = CharHolder
        SuspectButton.Visible = true

        table.insert(ButtonPresses,
            SuspectButton.MouseButton1Click:Once(function()
                for j, Press: RBXScriptConnection in ipairs(ButtonPresses) do
                    Press:Disconnect()
                end

                charge(Suspect, charges)
            end)
        )
    end
    SuspectSelection.Visible = true
end)