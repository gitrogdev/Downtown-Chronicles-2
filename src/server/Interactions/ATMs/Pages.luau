--Contains information about all screens of the ATM display
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Util = require(ReplicatedScripts.Util)

local config = {}

local inputAmount
config.AmountPage = {
    Header = "AmountSelect";

    ---Resets the custom withdrawal amount, or returns to the operation page
    ---@param ATM table The ATM in use
    Cancel = function(ATM: table)
        if inputAmount == 0 then
            ATM.SetScreen("OperationPage")
        else
            inputAmount = 0
            ATM.CurrentPage.Page.AmountDisplay.Text = `₲{inputAmount}`
        end
    end;

    ---Requests the custom withdrawal amount
    ---@param ATM table The ATM in use
    Enter = function(ATM: table)
        ATM.Withdraw(inputAmount)
    end;

    ---Adds a digit to the custom withdrawal amount
    ---@param ATM table The ATM in use
    ---@param digit number The digit to add
    NumberInput = function(ATM: table, digit: number)
        if #ATM.CurrentPage.Page.AmountDisplay.Text > 8 then
            return warn(
                `{script}.{ATM.Model:GetFullName()}.NumberInput: \z
                Maximum input size reached for {ATM.User}!`
            )
        end

        inputAmount = tonumber(tostring(inputAmount) .. digit)
        ATM.CurrentPage.Page.AmountDisplay.Text =
            `₲{Util.ThousandsSeparate(inputAmount)}`
    end;

    ---Sets up the display for the custom withdrawal amount page
    ---@param ATM table The ATM in use
    Setup = function(ATM: table)
        ATM.CurrentPage.Page.AmountDisplay.Text = "₲0"
        ATM.CurrentPage.Page.DenomDisplay.Text =
            config.Displays[ATM.Language].MultipleLimit

        inputAmount = 0
    end;
}

config.BalancePage = {
    Header = "ViewBalance";

    MFDs = {
        ---Returns to the operation page
        ---@param ATM table The ATM in use
        [6] = function(ATM: table)
            ATM.SetScreen("OperationPage")
        end;
    };

    ---Sets up the display for the balance page
    ---@param ATM table The ATM in use
    Setup = function(ATM: table)
        ATM.CurrentPage.Page.BackButton.Text =
            config.Displays[ATM.Language].BackPage
        ATM.CurrentPage.Page.BalanceHead.Text =
            config.Displays[ATM.Language].AvailableBalance
        ATM.CurrentPage.Page.BalanceDisplay.Text =
            `₲{Util[ATM.Language == "vlk" and "ToValak" or "ThousandsSeparate"](
                ATM.User:GetAttribute("BankBalance") or 0
            )}`
    end;
}

config.EndPage = {
    Header = "Complete";
}

config.FrozenPage = {
    Header = "Frozen";
}

config.HomePage = {
    Header = "TapCard";
}

config.LanguagePage = {
    Header = "LangSelect";

    MFDs = {
        ---Sets the language to English, and advances to the operation screen
        ---@param ATM table The ATM in use
        [1] = function(ATM: table)
            ATM.Language = "en"
            ATM.SetScreen("OperationPage")
        end;
        ---Sets the language to Valakese, and advances to the operation screen
        ---@param ATM table The ATM in use
        [2] = function(ATM: table)
            ATM.Language = "vlk"
            ATM.SetScreen("OperationPage")
        end;
        ---Sets the language to Croatian, and advances to the operation screen
        ---@param ATM table The ATM in use
        [3] = function(ATM: table)
            ATM.Language = "hr"
            ATM.SetScreen("OperationPage")
        end;
        ---Sets the language to Serbian, and advances to the operation screen
        ---@param ATM table The ATM in use
        [4] = function(ATM: table)
            ATM.Language = "sr"
            ATM.SetScreen("OperationPage")
        end;
    };
}

config.OperationPage = {
    Header = "OpSelect";

    MFDs = {
        ---Advances to the balance page
        ---@param ATM table The ATM in use
        [1] = function(ATM: table)
            ATM.SetScreen("BalancePage")
        end;
        ---Advances to the withdrawal page
        ---@param ATM table The ATM in use
        [2] = function(ATM: table)
            ATM.SetScreen("WithdrawPage")
        end;
    };

    ---Sets up the display for the operation page
    ---@param ATM table The ATM in use
    Setup = function(ATM: table)
        ATM.CurrentPage.Page.BalanceButton.Text =
            config.Displays[ATM.Language].BalancePage
        ATM.CurrentPage.Page.WithdrawButton.Text =
            config.Displays[ATM.Language].WithdrawPage
    end;
}

local amounts = {
    1000;
    2000;
    5000;
    10000;
    50000;
}
config.WithdrawPage = {
    Header = "AmountSelect";

    ---Returns to the operation page
    ---@param ATM table The ATM in use
    Cancel = function(ATM: table)
        ATM.SetScreen("OperationPage")
    end;

    MFDs = {
        ---Withdraws ₲1,000
        ---@param ATM table The ATM in use
        [1] = function(ATM: table)
            ATM.Withdraw(1000)
        end;
        ---Withdraws ₲2,000
        ---@param ATM table The ATM in use
        [2] = function(ATM: table)
            ATM.Withdraw(2000)
        end;
        ---Withdraws ₲5,000
        ---@param ATM table The ATM in use
        [3] = function(ATM: table)
            ATM.Withdraw(5000)
        end;
        ---Withdraws ₲10,000
        ---@param ATM table The ATM in use
        [4] = function(ATM: table)
            ATM.Withdraw(10000)
        end;
        ---Withdraws ₲50,000
        ---@param ATM table The ATM in use
        [5] = function(ATM: table)
            ATM.Withdraw(50000)
        end;
        ---Advances to the custom withdrawal amount page
        ---@param ATM table The ATM in use
        [6] = function(ATM: table)
            ATM.SetScreen("AmountPage")
        end;
    };

    ---Sets up the display for the operation page
    ---@param ATM table The ATM in use
    Setup = function(ATM: table)
        ATM.CurrentPage.Page.OtherButton.Text =
            config.Displays[ATM.Language].AmountPage
        ATM.CurrentPage.Page.ErrorLabel.Text =
            config.Displays[ATM.Language].CancelMistake
        for i, amount in ipairs(amounts) do
            ATM.CurrentPage.Page[`Button{i}`].Text =
            `₲{Util[ATM.Language == "vlk" and "ToValak" or "ThousandsSeparate"](
                amount
            )}`
        end
    end;
}

return config