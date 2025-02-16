--Handles all administrative actions on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local Util = require(ReplicatedScripts.Util)

local AuthorizeCadet = ReplicatedCommunication.AuthorizeCadet
local BankLookup = ReplicatedCommunication.BankLookup
local FineCharacter = ReplicatedCommunication.FineCharacter
local FreezeAccount = ReplicatedCommunication.FreezeAccount
local SearchableAddresses = ReplicatedCommunication.SearchableAddresses
local SearchWarrant = ReplicatedCommunication.SearchWarrant
local TacticalDeployment = ReplicatedCommunication.TacticalDeployment

local module = {}

---Display the admin page and handle all actions on it
function module:AdminPage()
    local Page: Frame = self:ShowPage("AdminActions")
    local ActionHolder: Frame = Page:WaitForChild("ActionHolder")
    local BackButton: TextButton = Page:WaitForChild("BackButton")

    local BankButton: TextButton = ActionHolder:WaitForChild("BankButton")
    local CadetButton: TextButton = ActionHolder:WaitForChild("CadetButton")
    local RevokeButton: TextButton = ActionHolder:WaitForChild("RevokeButton")
    local SerialButton: TextButton = ActionHolder:WaitForChild("SerialButton")
    local TacDepButton: TextButton = ActionHolder:WaitForChild("TacticalButton")
    local WarrantButton: TextButton = ActionHolder:WaitForChild("WarrantButton")

    local ActionButtons = {
        {
            Button = BankButton;
            Condition = function(Player: Player): boolean
                return  Player:GetAttribute("PoliceDivision") == "Tax"
                    or Player:GetAttribute("PoliceRank") >= 6
            end;
            OnClick = function()
                self:BankSearch()
            end;
        };
        {
            Button = CadetButton;
            Condition = function(Player: Player): boolean
                return Player:GetAttribute("PoliceRank") >= 3
            end;
            OnClick = function()
                self:CadetPage()
            end;
        };
        {
            Button = SerialButton;
            Condition = function(Player: Player): boolean
                return false
                --[[
                return (
                    Player:GetAttribute("PoliceDivision") == "Investigative"
                    and Player:GetAttribute("PoliceRank") >= 3
                ) or Player:GetAttribute("PoliceRank") >= 5
                ]]
            end;
            OnClick = function()
                self:SerialPage()
            end;
        };
        {
            Button = RevokeButton;
            Condition = function(Player: Player): boolean
                return false
                --[[
                return Player:GetAttribute("PoliceRank") >= 6
                ]]
            end;
            OnClick = function()
                self:RevokePage()
            end;
        };
        {
            Button = TacDepButton;
            Condition = function(Player: Player): boolean
                return Player:GetAttribute("PoliceRank") >= 4
            end;
            OnClick = function()
                TacticalDeployment:FireServer()
            end;
        };
        {
            Button = WarrantButton;
            Condition = function(Player: Player): boolean

                return (
                    Player:GetAttribute("PoliceDivision") == "Investigative"
                    and Player:GetAttribute("PoliceRank") >= 5
                ) or Player:GetAttribute("PoliceRank") >= 6
            end;
            OnClick = function()
                self:SearchWarrantAddresses()
            end;
        };
    }

    local connections = {}
    local function toSearch()
        self:SearchPage()

        for i, Connection: RBXScriptConnection in ipairs(connections) do
            Connection:Disconnect()
        end
    end
    table.insert(connections, BackButton.MouseButton1Click:Once(toSearch))

    local function updateTacticalButton()
        TacDepButton.Text = `{ReplicatedStorage:GetAttribute(
            `{self.User:GetAttribute("PoliceDivision")}TacticalDeployment`
        ) and "End" or "Authorize"} Tactical Deployment`
    end
    table.insert(connections, ReplicatedStorage:GetAttributeChangedSignal(
        `{self.User:GetAttribute("PoliceDivision")}TacticalDeployment`
    ):Connect(updateTacticalButton))
    updateTacticalButton()

    table.insert(connections, Page:GetPropertyChangedSignal("Visible"):Connect(
        function()
            if Page.Visible then
                return
            end

            for i, Connection: RBXScriptConnection in ipairs(connections) do
                Connection:Disconnect()
            end
        end
    ))

    for i, buttonData in ipairs(ActionButtons) do
        buttonData.Button.Visible = buttonData.Condition(self.User)
        if buttonData.Button.Visible then
            table.insert(connections,
                buttonData.Button.MouseButton1Click:Connect(buttonData.OnClick)
            )
        end
    end
end

---Display a character's bank records
---@param id number The character ID of the bank account owner
---@param records table The bank records retrieved from the server
function module:BankRecords(id: number, records: table)
    local Page: Frame = self:ShowPage("BankRecords")
    local BackButton: TextButton = Page:WaitForChild("BackButton")
    local FinePage: Frame = Page:WaitForChild("FinePage")
    local InfoPage: Frame = Page:WaitForChild("InfoPage")
    local PictureDisplay: ViewportFrame = Page:WaitForChild("PictureDisplay")

    local AmountBox: TextBox = FinePage:WaitForChild("AmountBox")
    local BalanceDisplay: TextLabel = FinePage:WaitForChild("BalanceDisplay")
    local IssueFine: TextButton = FinePage:WaitForChild("FineButton")

    local AddressDisplay: TextLabel = InfoPage:WaitForChild("AddressDisplay")
    local AdminActions: Frame = InfoPage:WaitForChild("AdminActions")
    local CitizenDisplay: TextLabel = InfoPage:WaitForChild("CitizenDisplay")
    local IDDisplay: TextLabel = InfoPage:WaitForChild("IDDisplay")
    local JobDisplay: TextLabel = InfoPage:WaitForChild("JobDisplay")
    local NameDisplay: TextLabel = InfoPage:WaitForChild("NameDisplay")

    local BalanceButton: TextButton = AdminActions:WaitForChild("BalanceButton")
    local FineButton: TextButton = AdminActions:WaitForChild("FineButton")
    local FreezeButton: TextButton = AdminActions:WaitForChild("FreezeButton")

    local BackTo: RBXScriptConnection
    local connections = {}

    local function toAdmin()
        self:AdminPage()

        InfoPage.Visible = false

        for i, Connection: RBXScriptConnection in ipairs(connections) do
            Connection:Disconnect()
        end
    end
    BackTo = BackButton.MouseButton1Click:Once(toAdmin)

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

    FineButton.Visible = self.User:GetAttribute("PoliceRank") > 4
    FreezeButton.Text = records.BankFrozen and "Unfreeze Account"
        or "Freeze Account"
    FreezeButton.Visible = self.User:GetAttribute("PoliceRank") > 3

    table.insert(connections, BalanceButton.MouseButton1Click:Connect(function()
        self:Error(
            `The balance of {records.Name}'s bank account with the People's \z
            Bank of North Bloxell is \z
            ₲{Util.ThousandsSeparate(records.BankBalance)}.`,
            function()
                self:ShowPage("BankRecords")
            end
        )
    end))

    if FineButton.Visible then
        table.insert(connections,
            FineButton.MouseButton1Click:Connect(function()
                local NumberEnforcement: RBXScriptConnection = Util.InputPosInt(
                    AmountBox, "Text", true
                )

                local OnFine: RBXScriptConnection =
                    IssueFine.MouseButton1Click:Once(function()
                        BackTo:Disconnect()
                        NumberEnforcement:Disconnect()

                        local success, result, balance
                        self:Load(function()
                            local amount = AmountBox.Text:gsub(",", "")
                            success, result, balance =
                                FineCharacter:InvokeServer(id, tonumber(amount))
                        end)

                        if success and balance then
                            records.BankBalance = balance
                        end

                        self:Error(result or "No response from server.",
                            function()
                                FinePage.Visible = false
                                self:ShowPage("BankRecords")
                                InfoPage.Visible = true
                                BackTo = BackButton.MouseButton1Click:Once(
                                    toAdmin
                                )
                            end
                        )
                    end)

                BackTo:Disconnect()
                BackTo = BackButton.MouseButton1Click:Once(function()
                    FinePage.Visible = false

                    InfoPage.Visible = true

                    NumberEnforcement:Disconnect()
                    OnFine:Disconnect()
                    BackTo = BackButton.MouseButton1Click:Once(toAdmin)
                end)

                InfoPage.Visible = false
                BalanceDisplay.Text = `Bank balance: \z
                    ₲{Util.ThousandsSeparate(records.BankBalance)}`
                FinePage:WaitForChild("CitizenDisplay").Text =
                    CitizenDisplay.Text
                FinePage:WaitForChild("IDDisplay").Text = IDDisplay.Text
                FinePage:WaitForChild("NameDisplay").Text = NameDisplay.Text
                FinePage.Visible = true
            end)
        )
    end

    if FreezeButton.Visible then
        table.insert(connections,
            FreezeButton.MouseButton1Click:Connect(function()
                local success, result
                self:Load(function()
                    success, result = FreezeAccount:InvokeServer(
                        id, not records.BankFrozen
                    )
                end)

                if not success then
                    self:Error(result or "No response from server.", function()
                        self:ShowPage("BankRecords")
                    end)
                    return
                end

                records.BankFrozen = not records.BankFrozen
                FreezeButton.Text = records.BankFrozen and "Unfreeze Account"
                    or "Freeze Account"
                self:Error(
                    `{records.Name}'s bank account has been successfully \z
                    {records.BankFrozen and "" or "un"}frozen.`,
                    function()
                        self:ShowPage("BankRecords")
                    end
                )
            end)
        )
    end

    InfoPage.Visible = true
    self:ShowPicture(PictureDisplay, records)
end

---Display the bank records search page
function module:BankSearch()
    local Page: Frame = self:ShowPage("BankSearch")
    local BackButton: TextButton = Page:WaitForChild("BackButton")
    local SearchBox: TextBox = Page:WaitForChild("BankSearch")
    local SearchButton: TextButton = Page:WaitForChild("BankSearchButton")

    local connections = {}

    table.insert(connections, BackButton.MouseButton1Click:Once(function()
        self:AdminPage()
    end))

    table.insert(connections, SearchButton.MouseButton1Click:Connect(function()
        local query = tonumber(SearchBox.Text)
        if not query then
            SearchBox.Text = ""
            return warn(
                `{script}.Terminal:BankSearch: "{query}" is not a valid \z
                ID number!`
            )
        end

        local success, result
        self:Load(function()
            success, result = BankLookup:InvokeServer(query)
        end)

        if not success then
            self:Error(result or "No response from server.", function()
                self:AdminPage()
            end)
            return
        end
        self:BankRecords(query, result)
    end))

    Page:GetPropertyChangedSignal("Visible"):Once(function()
        for i, Connection: RBXScriptConnection in ipairs(connections) do
            Connection:Disconnect()
        end

        SearchBox.Text = ""
    end)
end

---Display the cadet authorization page and handle all actions on it
function module:CadetPage()
    local Cadets = {}
    for i, Player: Player in ipairs(Players:GetPlayers()) do
        if Player:GetAttribute("PoliceRank") == 1 then
            table.insert(Cadets, Player)
        end
    end

    if #Cadets == 0 then
        return self:Error("No cadets online.", function()
            self:AdminPage()
        end)
    end

    local Page: Frame = self:ShowPage("CadetAuthorization")
    local BackButton: TextButton = Page:WaitForChild("BackButton")
    local CadetHolder: ScrollingFrame = Page:WaitForChild("CadetHolder")

    local CadetTemplate: Frame = CadetHolder:WaitForChild("CadetTemplate")

    local CadetFrames = {}
    local connections = {}
    
    for i, Cadet: Player in ipairs(Cadets) do
        local CadetFrame: Frame = CadetTemplate:Clone()
        local Authorize: TextButton = CadetFrame:WaitForChild("AuthorizeButton")
        local NameDisplay: TextLabel = CadetFrame:WaitForChild("Name")

        local function updateButton()
            Authorize.Text = Cadet:GetAttribute("ArmoryAuthorized")
                and "Deauthorize" or "Authorize"
        end
        table.insert(connections, Cadet:GetAttributeChangedSignal(
            "ArmoryAuthorized"
        ):Connect(updateButton))

        NameDisplay.Text = `Cadet {Cadet:GetAttribute("LastName")}, \z
            {Cadet:GetAttribute("FirstName")} ({Cadet.UserId}-\z
            {Cadet:GetAttribute("ID")})`
        table.insert(connections, Authorize.MouseButton1Click:Connect(function()
            AuthorizeCadet:FireServer(Cadet)
        end))

        CadetFrame.Parent = CadetHolder
        CadetFrame.Visible = true

        table.insert(CadetFrames, CadetFrame)
    end

    table.insert(connections, BackButton.MouseButton1Click:Once(function()
        for i, Connection: RBXScriptConnection in ipairs(connections) do
            Connection:Disconnect()
        end

        for i, CadetFrame: Frame in ipairs(CadetFrames) do
            CadetFrame:Destroy()
        end

        self:AdminPage()
    end))
end

function module:SearchWarrantAddresses()
    local success, result
    self:Load(function()
        success, result = SearchableAddresses:InvokeServer()
    end)

    if not success then
        self:Error(result or "No response from server", function()
            self:AdminPage()
        end)
        return
    end

    local Page: Frame = self:ShowPage("SearchWarrants")
    local AddressHolder: ScrollingFrame = Page:WaitForChild("AddressHolder")
    local BackButton: TextButton = Page:WaitForChild("BackButton")

    local AddressTemplate: Frame = AddressHolder:WaitForChild("AddressTemplate")

    local AddressFrames = {}
    local connections = {}

    for i, unit in ipairs(result) do
        local AddressFrame: Frame = AddressTemplate:Clone()
        local Authorize: TextButton =
            AddressFrame:WaitForChild("AuthorizeButton")
        local NameDisplay: TextLabel = AddressFrame:WaitForChild("Name")

        NameDisplay.Text = unit.Address
        table.insert(connections, Authorize.MouseButton1Click:Connect(function()
            for j, Connection: RBXScriptConnection in ipairs(connections) do
                Connection:Disconnect()
            end
    
            for j, DestroyFrame: Frame in ipairs(AddressFrames) do
                DestroyFrame:Destroy()
            end
    
            local issueSuccess, issueResult
            self:Load(function()
                issueSuccess, issueResult = SearchWarrant:InvokeServer(
                    unit.Building, unit.Apartment
                )
            end)
            
            self:Error(issueResult or "No response from server.", function()
                self:AdminPage()
            end)
        end))

        AddressFrame.Parent = AddressHolder
        AddressFrame.Visible = true

        table.insert(AddressFrames, AddressFrame)
    end

    table.insert(connections, BackButton.MouseButton1Click:Once(function()
        for i, Connection: RBXScriptConnection in ipairs(connections) do
            Connection:Disconnect()
        end

        for i, AddressFrame: Frame in ipairs(AddressFrames) do
            AddressFrame:Destroy()
        end

        self:AdminPage()
    end))
end

return module