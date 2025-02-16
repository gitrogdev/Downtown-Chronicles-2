---Handles the display of officer records on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts

local ReplicatedCommunication = ReplicatedScripts.Communication
local ReplicatedConfig = ReplicatedScripts.Configuration

local FireOfficer = ReplicatedCommunication.FireOfficer
local HireOfficer = ReplicatedCommunication.HireOfficer
local PromoteOfficer = ReplicatedCommunication.PromoteOfficer
local ReassignOfficer = ReplicatedCommunication.ReassignOfficer

local PoliceConfig = require(ReplicatedConfig.Police)

local module = {}

---Displays the records for an officer
---@param records table The officer records received from the server
function module:OfficerRecords(records: table)
    local Page: Frame = self:ShowPage("OfficerRecords")
    local BackButton: TextButton = Page:WaitForChild("BackButton")
    local CivilianInfo: Frame = Page:WaitForChild("CivilianInfo")
    local FireFrame: Frame = Page:WaitForChild("FireOfficer")
    local HireFrame: Frame = Page:WaitForChild("HireOfficer")
    local OfficerInfo: Frame = Page:WaitForChild("OfficerInfo")
    local PromoteFrame: Frame = Page:WaitForChild("PromoteOfficer")
    local PictureDisplay: ViewportFrame = Page:WaitForChild("PictureDisplay")
    local ReassignFrame: Frame = Page:WaitForChild("ReassignOfficer")

    local ConfirmFire: TextButton = FireFrame:WaitForChild("FireButton")

    local ConfirmHire: TextButton = HireFrame:WaitForChild("HireButton")

    local ConfirmPromo: TextButton = PromoteFrame:WaitForChild("PromoteButton")
    local RankHolder: ScrollingFrame = PromoteFrame:WaitForChild("RankHolder")

    local RankTemplate: TextButton = RankHolder:WaitForChild("RankTemplate")

    local AssignButtons = {
        Patrol = ReassignFrame:WaitForChild("PatrolButton");
        Investigative = ReassignFrame:WaitForChild("InvestigativeButton");
        Tax = ReassignFrame:WaitForChild("TaxButton");
    }

    local BackTo: RBXScriptConnection
    local connections = {}
    local function toSearch()
        self:SearchPage()

        CivilianInfo.Visible = false
        FireFrame.Visible = false
        HireFrame.Visible = false
        OfficerInfo.Visible = false
        PromoteFrame.Visible = false
        ReassignFrame.Visible = false

        for i, Connection: RBXScriptConnection in ipairs(connections) do
            Connection:Disconnect()
        end
    end
    BackTo = BackButton.MouseButton1Click:Once(toSearch)

    if records.Officer then
        local AdminActions: Frame = OfficerInfo:WaitForChild("AdminActions")
        local AdminDisplay: TextLabel = OfficerInfo:WaitForChild("AdminDisplay")
        local DivisionDisplay: TextLabel =
            OfficerInfo:WaitForChild("DivisionDisplay")
        local HiredDisplay: TextLabel = OfficerInfo:WaitForChild("HiredDisplay")
        local IDDisplay: TextLabel = OfficerInfo:WaitForChild("IDDisplay")
        local NameDisplay: TextLabel = OfficerInfo:WaitForChild("NameDisplay")
        local RankDisplay: TextLabel = OfficerInfo:WaitForChild("RankDisplay")

        local FireButton: TextButton = AdminActions:WaitForChild("FireButton")
        local PromoteButton: TextButton =
            AdminActions:WaitForChild("PromoteButton")
        local ReassignButton: TextButton =
            AdminActions:WaitForChild("ReassignButton")

        local hiredAt = os.date("!*t", records.PoliceSince - 36000)
        local rank = PoliceConfig.Ranks[records.PoliceRank]
        if rank == "Officer" then
            rank = PoliceConfig.OfficerTitles[records.PoliceDivision]
        end

        AdminDisplay.Text = `{
            records.PoliceRank > 6 and "Bloxell City" or "North Bloxford"
        } Administration`
        DivisionDisplay.Text =
            records.PoliceRank > 6 and "Federal Administration"
            or records.PoliceRank == 6 and "Municipal Administration"
            or `{records.PoliceDivision} Division`
        HiredDisplay.Text = `Employed {string.format("%02d", hiredAt.day)}/\z
            {string.format("%02d", hiredAt.month)}/{hiredAt.year}`
        IDDisplay.Text = `{records.UserId}-{records.CharacterId}`
        NameDisplay.Text = records.Name
        RankDisplay.Text = rank

        AdminActions.Visible = self.User:GetAttribute("PoliceRank") >= 5
        if self.User:GetAttribute("PoliceRank") >= 5 then
            table.insert(connections,
                FireButton.MouseButton1Click:Connect(function()
                    local OnFire: RBXScriptConnection =
                        ConfirmFire.MouseButton1Click:Once(function()
                            BackTo:Disconnect()
                            local success, result
                            self:Load(function()
                                success, result = FireOfficer:InvokeServer(
                                    records.CharacterId
                                )
                            end)

                            self:Error(result or "No response from server.",
                                function()
                                    toSearch()
                                end
                            )
                        end)

                    BackTo:Disconnect()
                    BackTo = BackButton.MouseButton1Click:Once(function()
                        FireFrame.Visible = false
                        OfficerInfo.Visible = true
                        OnFire:Disconnect()
                        BackTo = BackButton.MouseButton1Click:Once(toSearch)
                    end)

                    OfficerInfo.Visible = false
                    FireFrame:WaitForChild("IDDisplay").Text = IDDisplay.Text
                    FireFrame:WaitForChild("NameDisplay").Text =
                        NameDisplay.Text
                    FireFrame.Visible = true
                end)
            )

            table.insert(connections,
                PromoteButton.MouseButton1Click:Connect(function()
                    local selectedRank = records.PoliceRank
                    local RankButtons = {}
                    for i = 1, self.User:GetAttribute("PoliceRank") - 1 do
                        local RankButton: TextButton = RankTemplate:Clone()
                        RankButton.Text = PoliceConfig.Ranks[i]
                        RankButton.Visible = true
                        RankButton.Parent = RankHolder

                        RankButton.MouseButton1Click:Connect(function()
                            RankButtons[selectedRank].BackgroundColor3 =
                                Color3.new(1, 1, 1)
                            selectedRank = i
                            RankButton.BackgroundColor3 =
                                Color3.fromRGB(179, 179, 179)
                        end)

                        table.insert(RankButtons, RankButton)
                    end
                    RankButtons[selectedRank].BackgroundColor3 =
                    Color3.fromRGB(179, 179, 179)

                    local OnPromote: RBXScriptConnection =
                        ConfirmPromo.MouseButton1Click:Once(function()
                            BackTo:Disconnect()
                            local success, result
                            self:Load(function()
                                success, result = PromoteOfficer:InvokeServer(
                                    records.CharacterId, selectedRank
                                )
                            end)

                            for i, Button: TextButton in ipairs(RankButtons) do
                                Button:Destroy()
                            end
                            RankButtons = {}

                            self:Error(result or "No response from server.",
                                function()
                                    toSearch()
                                end
                            )
                        end)

                    BackTo:Disconnect()
                    BackTo = BackButton.MouseButton1Click:Once(function()
                        PromoteFrame.Visible = false

                        for i, Button: TextButton in ipairs(RankButtons) do
                            Button:Destroy()
                        end
                        RankButtons = {}

                        OfficerInfo.Visible = true
                        OnPromote:Disconnect()
                        BackTo = BackButton.MouseButton1Click:Once(toSearch)
                    end)

                    OfficerInfo.Visible = false
                    PromoteFrame:WaitForChild("IDDisplay").Text = IDDisplay.Text
                    PromoteFrame:WaitForChild("NameDisplay").Text =
                        NameDisplay.Text
                    PromoteFrame.Visible = true
                end)
            )

            ReassignButton.Visible = self.User:GetAttribute("PoliceRank") >= 6
                and records.PoliceRank < 6
            if ReassignButton.Visible then
                table.insert(connections,
                    ReassignButton.MouseButton1Click:Connect(function()
                        local Reassignments: table = {}
                        for division: string, Button: TextButton in pairs(
                            AssignButtons
                        ) do
                            table.insert(Reassignments,
                                Button.MouseButton1Click:Once(function()
                                    BackTo:Disconnect()
                                    for i, Reassignment: RBXScriptConnection in
                                    ipairs(Reassignments) do
                                        Reassignment:Disconnect()
                                    end
                                    local success, result
                                    self:Load(function()
                                        success, result =
                                            ReassignOfficer:InvokeServer(
                                                records.CharacterId,
                                                division
                                            )
                                    end)

                                    self:Error(
                                        result or "No response from server.",
                                        function()
                                            toSearch()
                                        end
                                    )
                                end)
                            )
                        end

                        BackTo:Disconnect()
                        BackTo = BackButton.MouseButton1Click:Once(function()
                            ReassignFrame.Visible = false
                            OfficerInfo.Visible = true
                            for i, Reassignment: RBXScriptConnection in ipairs(
                                Reassignments
                            ) do
                                Reassignment:Disconnect()
                            end
                            BackTo = BackButton.MouseButton1Click:Once(toSearch)
                        end)

                        OfficerInfo.Visible = false
                        ReassignFrame:WaitForChild("IDDisplay").Text =
                            IDDisplay.Text
                        ReassignFrame:WaitForChild("NameDisplay").Text =
                            NameDisplay.Text
                        ReassignFrame.Visible = true
                    end)
                )
            end
        end

        OfficerInfo.Visible = true
    else
        local AdminActions: Frame = CivilianInfo:WaitForChild("AdminActions")
        local CitizenshipDisplay: TextLabel =
            CivilianInfo:WaitForChild("CitizenshipDisplay")
        local IDDisplay: TextLabel = CivilianInfo:WaitForChild("IDDisplay")
        local JobDisplay: TextLabel = CivilianInfo:WaitForChild("JobDisplay")
        local NameDisplay: TextLabel = CivilianInfo:WaitForChild("NameDisplay")

        local HireButton: TextButton = AdminActions:WaitForChild("HireButton")
        
        CitizenshipDisplay.Text =
            (records.Citizenship == "North"
            and "Citizen of the State of North Bloxell") or
            (records.Citizenship == "South"
            and "Citizen of the Republic of Bloxell") or "Immigrant"
        IDDisplay.Text = `{records.UserId}-{records.CharacterId}`
        JobDisplay.Text = records.Occupation
        NameDisplay.Text = records.Name

        AdminActions.Visible = self.User:GetAttribute("PoliceRank") >= 5
        if self.User:GetAttribute("PoliceRank") >= 5 then
            table.insert(connections,
                HireButton.MouseButton1Click:Connect(function()
                    local OnHire: RBXScriptConnection =
                        ConfirmHire.MouseButton1Click:Once(function()
                            BackTo:Disconnect()
                            local success, result
                            self:Load(function()
                                success, result = HireOfficer:InvokeServer(
                                    records.CharacterId
                                )
                            end)

                            self:Error(result or "No response from server.",
                                function()
                                    toSearch()
                                end
                            )
                        end)

                    BackTo:Disconnect()
                    BackTo = BackButton.MouseButton1Click:Once(function()
                        HireFrame.Visible = false
                        CivilianInfo.Visible = true
                        OnHire:Disconnect()
                        BackTo = BackButton.MouseButton1Click:Once(toSearch)
                    end)

                    CivilianInfo.Visible = false
                    HireFrame:WaitForChild("IDDisplay").Text = IDDisplay.Text
                    HireFrame:WaitForChild("NameDisplay").Text =
                        NameDisplay.Text
                    HireFrame.Visible = true
                end)
            )
        end
        CivilianInfo.Visible = true
    end

    self:ShowPicture(PictureDisplay, records)
end

return module