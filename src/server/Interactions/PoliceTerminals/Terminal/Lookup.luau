--Handles the search page for the police terminal on the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local CriminalLookup = ReplicatedCommunication.CriminalLookup
local OfficerLookup = ReplicatedCommunication.OfficerLookup

local module = {}

---Loads the search page
function module:SearchPage()
    local Page: Frame = self:ShowPage("SearchFrame")
    local AdminButton: TextButton = Page:WaitForChild("AdminButton")
    local CriminalSearch: TextBox = Page:WaitForChild("CriminalSearch")
    local OfficerSearch: TextBox = Page:WaitForChild("OfficerSearch")
    local SearchCriminals: TextButton = Page:WaitForChild("CrimSearchButton")
    local SearchOfficers: TextButton = Page:WaitForChild("OfficerSearchButton")

    local Searches: table = {
        SearchCriminals.MouseButton1Click:Connect(function()
            local query = tonumber(CriminalSearch.Text)
            if not query then
                CriminalSearch.Text = ""
                return warn(
                    `{script}.Terminal:SearchPage: "{query}" is not a valid \z
                    ID number!`
                )
            end

            local success, result
            self:Load(function()
                success, result = CriminalLookup:InvokeServer(query)
            end)

            if not success then
                self:Error(result or "No response from server.", function()
                    self:SearchPage()
                end)
                return
            end
            self:CriminalRecords(unpack(result))
        end);
        SearchOfficers.MouseButton1Click:Connect(function()
            local query = tonumber(OfficerSearch.Text)
            if not query then
                OfficerSearch.Text = ""
                return warn(
                    `{script}.Terminal:SearchPage: "{query}" is not a valid \z
                    ID number!`
                )
            end

            local success, result
            self:Load(function()
                success, result = OfficerLookup:InvokeServer(query)
            end)

            if not success then
                self:Error(result or "No response from server.", function()
                    self:SearchPage()
                end)
                return
            end
            self:OfficerRecords(result)
        end);
    }

    AdminButton.Visible = self.User:GetAttribute("PoliceRank") >= 3
    if AdminButton.Visible then
        table.insert(Searches, AdminButton.MouseButton1Click:Connect(function()
            self:AdminPage()
        end))
    end

    Page:GetPropertyChangedSignal("Visible"):Once(function()
        OfficerSearch.PlaceholderText = "Enter ID number here:"
        OfficerSearch.Text = ""
        for i, Search: RBXScriptConnection in ipairs(Searches) do
            Search:Disconnect()
        end
    end)
end

return module