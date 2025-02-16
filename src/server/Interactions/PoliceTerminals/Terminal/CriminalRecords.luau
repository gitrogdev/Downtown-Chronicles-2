---Handles the display of criminal records on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local AddressLookup = ReplicatedCommunication.AddressLookup
local IssueWarrant = ReplicatedCommunication.IssueWarrant
local RecordLookup = ReplicatedCommunication.RecordLookup

local module = {}

---Displays the criminal records for a user
---@param records table The criminal records received from the server
---@param crimes table A list of all crimes a warrant can be issued for
function module:CriminalRecords(records: table, crimes: table)
    local Page: Frame = self:ShowPage("CriminalRecords")
    local BackButton: TextButton = Page:WaitForChild("BackButton")
    local InfoPage: Frame = Page:WaitForChild("InfoPage")
    local LookupFrame: Frame = Page:WaitForChild("AddressDisplay")
    local PictureDisplay: ViewportFrame = Page:WaitForChild("PictureDisplay")
    local RecordDisplay: Frame = Page:WaitForChild("RecordDisplay")
    local WarrantPage: Frame = Page:WaitForChild("IssueWarrant")

    local AddressDisplay: TextLabel = InfoPage:WaitForChild("AddressDisplay")
    local AdminActions: Frame = InfoPage:WaitForChild("AdminActions")
    local CitizenDisplay: TextLabel = InfoPage:WaitForChild("CitizenDisplay")
    local IDDisplay: TextLabel = InfoPage:WaitForChild("IDDisplay")
    local JobDisplay: TextLabel = InfoPage:WaitForChild("JobDisplay")
    local NameDisplay: TextLabel = InfoPage:WaitForChild("NameDisplay")

    local LookupButton: TextButton = AdminActions:WaitForChild("LookupButton")
    local RecordButton: TextButton = AdminActions:WaitForChild("RecordButton")
    local WarrantButton: TextButton = AdminActions:WaitForChild("WarrantButton")

    local AccessoryButton: TextButton =
        WarrantPage:WaitForChild("AccessoryButton")
    local AppliedList: ScrollingFrame = WarrantPage:WaitForChild("AppliedList")
    local AttemptButton: TextButton = WarrantPage:WaitForChild("AttemptButton")
    local WarrantChargeList: ScrollingFrame =
        WarrantPage:WaitForChild("ChargeList")
    local CommitButton: TextButton = WarrantPage:WaitForChild("CommitButton")
    local ConspiracyButton: TextButton =
        WarrantPage:WaitForChild("ConspiracyButton")
    local IssueButton: TextButton = WarrantPage:WaitForChild("IssueButton")

    local AppliedChargeTemplate: TextButton =
        AppliedList:WaitForChild("ChargeTemplate")

    local WarrantChargeTemplate: TextButton =
        WarrantChargeList:WaitForChild("ChargeTemplate")

    local AddressCount: TextLabel = LookupFrame:WaitForChild("AddressCount")
    local AddressList: ScrollingFrame = LookupFrame:WaitForChild("AddressList")

    local ChargeList: ScrollingFrame = RecordDisplay:WaitForChild("ChargeList")
    local ChargeTemplate: Frame = ChargeList:WaitForChild("ChargeTemplate")

    local AddressTemplate: TextLabel =
        AddressList:WaitForChild("AddressTemplate")

    local ModButtons = {
        [AccessoryButton] = "Accessory to";
        [AttemptButton] = "Attempting to";
        [CommitButton] = "";
        [ConspiracyButton] = "Conspiracy to";
    }

    local BackTo: RBXScriptConnection
    local connections = {}
    local function toSearch()
        self:SearchPage()

        InfoPage.Visible = false

        for i, Connection: RBXScriptConnection in ipairs(connections) do
            Connection:Disconnect()
        end
    end
    BackTo = BackButton.MouseButton1Click:Once(toSearch)

    AddressDisplay.Text = records.Address or `No place of residence found for \z
        {records.Name}`
    CitizenDisplay.Text = (records.Citizenship == "North"
        and "Citizen of the State of North Bloxell") or
        (records.Citizenship == "South"
        and "Citizen of the Republic of Bloxell") or "Immigrant"
    IDDisplay.Text = `{records.UserId}-{records.CharacterId}`
    JobDisplay.Text =
        records.Occupation == "MIA" and "Ministry of Internal Affairs"
        or records.Occupation
    NameDisplay.Text = records.Name

    table.insert(connections,
        LookupButton.MouseButton1Click:Connect(function()
            local success, result
            self:Load(function()
                success, result = AddressLookup:InvokeServer(
                    records.CharacterId
                )
            end)

            if not success then
                self:Error(result or "No response from server.", function()
                    self:ShowPage("CriminalRecords")
                end)
                return
            end

            local Addresses = {}
            for i, address: string in ipairs(result) do
                local Address: TextLabel = AddressTemplate:Clone()
                Address.Text = address
                Address.Visible = true
                Address.Parent = AddressList
                table.insert(Addresses, Address)
            end
            AddressCount.Text = `{#result} address\z
                {#result == 1 and "" or "es"} found for {records.Name}:`

            BackTo:Disconnect()
            BackTo = BackButton.MouseButton1Click:Once(function()
                LookupFrame.Visible = false
                for i, Address: TextLabel in ipairs(Addresses) do
                    Address:Destroy()
                end
                InfoPage.Visible = true
                BackTo = BackButton.MouseButton1Click:Once(toSearch)
            end)

            InfoPage.Visible = false
            LookupFrame:WaitForChild("IDDisplay").Text = IDDisplay.Text
            LookupFrame:WaitForChild("NameDisplay").Text = NameDisplay.Text
            LookupFrame.Visible = true
            self:ShowPage("CriminalRecords")
        end)
    )

    table.insert(connections,
        RecordButton.MouseButton1Click:Connect(function()
            local success, result
            self:Load(function()
                success, result = RecordLookup:InvokeServer(
                    records.CharacterId
                )
            end)

            if not success then
                self:Error(result or "No response from server.", function()
                    self:ShowPage("CriminalRecords")
                end)
                return
            end

            local Charges = {}
            for i, charge: table in ipairs(result) do
                local Charge: Frame = ChargeTemplate:Clone()
                Charge:WaitForChild("Charge").Text = charge.Charge
                Charge:WaitForChild("Date").Text = charge.At
                Charge.Visible = true
                Charge.Parent = ChargeList
                table.insert(Charges, Charge)
            end

            BackTo:Disconnect()
            BackTo = BackButton.MouseButton1Click:Once(function()
                RecordDisplay.Visible = false
                for i, Charge: Frame in ipairs(Charges) do
                    Charge:Destroy()
                end
                InfoPage.Visible = true
                BackTo = BackButton.MouseButton1Click:Once(toSearch)
            end)

            InfoPage.Visible = false
            RecordDisplay:WaitForChild("IDDisplay").Text = IDDisplay.Text
            RecordDisplay:WaitForChild("NameDisplay").Text = NameDisplay.Text
            RecordDisplay.Visible = true
            self:ShowPage("CriminalRecords")
        end)
    )

    WarrantButton.Visible = not not crimes
    if not not crimes then
        table.insert(connections,
            WarrantButton.MouseButton1Click:Connect(function()
                local AppliedButtons = {}
                local appliedCharges = {}
                local Charges = {}
                local modClicks = {}
                local id = 1
                local selectedMod

                for ModButton: TextButton, mod: string in pairs(ModButtons) do
                    table.insert(modClicks,
                        ModButton.MouseButton1Click:Connect(function()
                            for
                                OtherButton: TextButton, skipMod
                            in pairs(ModButtons) do
                                OtherButton.Style = OtherButton == ModButton and
                                    Enum.ButtonStyle.RobloxRoundDefaultButton or
                                    Enum.ButtonStyle.RobloxRoundButton
                            end
                
                            selectedMod = mod ~= "" and mod or nil
                        end)
                    )
                end

                for key, crime: table in pairs(crimes) do
                    local CrimeButton: Frame = WarrantChargeTemplate:Clone()
                    CrimeButton.Name = crime.Name
                    CrimeButton.Text = crime.Name:upper()
                    CrimeButton.Visible = true
                    CrimeButton.Parent = WarrantChargeList

                    CrimeButton.MouseButton1Click:Connect(function()
                        if #appliedCharges >= 10 then
                            StarterGui:SetCore("SendNotification", {
                                Title = "Maximum charges";
                                Text = "You have reached the maximum number \z
                                    of charges which can be applied in one \z
                                    warrant.";
                                Duration = 10;
                            })
                            return
                        end
            
                        local AppliedButton: TextButton =
                            AppliedChargeTemplate:Clone()
                        AppliedButton.Text = selectedMod
                            and `{selectedMod:upper()} {crime.WithMod:upper()}`
                            or crime.Name:upper()
                        AppliedButton.Parent = AppliedList
                        AppliedButton.Visible = true
                        table.insert(AppliedButtons, AppliedButton)
            
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

                    table.insert(Charges, CrimeButton)
                end

                table.insert(modClicks,
                    IssueButton.MouseButton1Click:Connect(function()
                        if #appliedCharges == 0 then
                            StarterGui:SetCore("SendNotification", {
                                Title = "No charges";
                                Text = `You have not added any charges to the \z
                                    warrant!`;
                                Duration = 10;
                            })
                            return
                        end

                        local success, result
                        self:Load(function()
                            success, result = IssueWarrant:InvokeServer(
                                records.CharacterId, appliedCharges
                            )
                        end)

                        WarrantPage.Visible = false
                        for i, Charge: TextButton in ipairs(Charges) do
                            Charge:Destroy()
                        end
    
                        for i, Charge: TextButton in ipairs(AppliedButtons) do
                            Charge:Destroy()
                        end
    
                        for i, ModClick: RBXScriptConnection in ipairs(
                            modClicks
                        ) do
                            ModClick:Disconnect()
                        end
                        BackTo:Disconnect()

                        if not success then
                            self:Error(result or "No response from server.",
                            function()
                                self:ShowPage("CriminalRecords")
                            end)
                            return
                        end

                        self:Error(result or "Warrant successfully issued.",
                        function()
                            toSearch()
                        end)
                    end)
                )

                BackTo:Disconnect()
                BackTo = BackButton.MouseButton1Click:Once(function()
                    WarrantPage.Visible = false
                    for i, Charge: TextButton in ipairs(Charges) do
                        Charge:Destroy()
                    end

                    for i, Charge: TextButton in ipairs(AppliedButtons) do
                        Charge:Destroy()
                    end

                    for i, ModClick: RBXScriptConnection in ipairs(modClicks) do
                        ModClick:Disconnect()
                    end
                    InfoPage.Visible = true
                    BackTo = BackButton.MouseButton1Click:Once(toSearch)
                end)

                InfoPage.Visible = false
                WarrantPage:WaitForChild("NameDisplay").Text = NameDisplay.Text
                WarrantPage.Visible = true
            end)
        )
    end

    InfoPage.Visible = true

    self:ShowPicture(PictureDisplay, records)
end

return module