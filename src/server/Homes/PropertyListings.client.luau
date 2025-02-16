--Handles home purchases on the client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainGui = script.Parent
local ApartmentBackground = MainGui:WaitForChild("Apartments")
local ContractHolder = MainGui:WaitForChild("ContractHolder")
local PassListings = MainGui:WaitForChild("PassListings")

local ListingTemplate = ApartmentBackground:WaitForChild("ApartmentTemplate")

local ContractBackground = ContractHolder:WaitForChild("Contract")
local Article1 = ContractBackground:WaitForChild("Article1")
local Article2 = ContractBackground:WaitForChild("Article2")
local SignButton = ContractBackground:WaitForChild("Sign")

local Player = Players.LocalPlayer

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local ReplicatedCommunication = ReplicatedScripts.Communication
local Util = require(ReplicatedScripts.Util)

local SignRental = ReplicatedCommunication.SignRental

PassListings.OnClientEvent:Connect(function(residenceData: table)
    for i, listing in pairs(residenceData) do
        local ListingDisplay = ListingTemplate:Clone()
        local AddressDisplay = ListingDisplay:WaitForChild("Address")
        local AvailableDisplay = ListingDisplay:WaitForChild("Available")
        local DescriptionDisplay = ListingDisplay:WaitForChild("Description")
        local ListingHead = ListingDisplay:WaitForChild("Head")
        local PriceDisplay = ListingDisplay:WaitForChild("Price")
        local RentButton = ListingDisplay:WaitForChild("Rent")
        local SizeDisplay = ListingDisplay:WaitForChild("Rooms")

        AddressDisplay.Text = listing.Address
        DescriptionDisplay.Text = listing.Description
        ListingHead.Text = listing.Name
        PriceDisplay.Text = `₲{Util.ThousandsSeparate(listing.Price)} / month`
        SizeDisplay.Text = listing.Size

        for j, image in ipairs(listing.Pictures) do
            ListingDisplay:WaitForChild(`Picture{j}`).Image = image
        end

        if listing.Available then
            AvailableDisplay.Text = `{listing.Available} \z
                unit{listing.Available == 1 and "" or "s"} available`
        end

        RentButton.MouseButton1Click:Once(function()
            ApartmentBackground.Visible = false

            Article1.Text = `This contract establishes the relationship \z
                between the RENTER, the Ministry of Housing of the State of \z
                North Bloxell, and the TENANT, \z
                {Player:GetAttribute("FullName")}.`
            Article2.Text = `The tenant agrees to pay the renter in the \z
                amount of ₲{Util.ThousandsSeparate(listing.Price)} every \z
                thirty days following the initial down payment of \z
                ₲{Util.ThousandsSeparate(listing.Price * 2)} on the day of \z
                establishment of the contract.`

            SignButton.MouseButton1Click:Once(function()
                SignRental:FireServer(listing.Key)
            end)

            ContractHolder.Visible = true
        end)

        ListingDisplay.Visible = true
        ListingDisplay.Parent = ApartmentBackground
    end
end)