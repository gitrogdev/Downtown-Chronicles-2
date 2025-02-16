---Configuration for the bankteller NPC in North Bloxell
local config = {}

config.Name = "Moma Kelahimofa"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to the People's Bank of North Bloxell! \z
        How can I help you today?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[RENT DUE] I'd like to make a rent payment.";
                ShowIf = "RentDueNorth";
                Then = "PayRent";
            };
            {
                Text = "I'd like to open an account.";
                ShowIf = "NoPBNBAccount";
                Then = "OpenAccount";
            };
            {
                Text = "I'd like to access my account.";
                ShowIf = "PBNBAccount";
                Then = "AccountActions"
            };
            {
                Text = "I'd like to access my account.";
                ShowIf = "AccountFrozen";
                Then = "AccountFrozen"
            };
            {
                Text = "I'd like to rent residential property.";
                ShowIf = "HomelessNortherner";
                Then = "RentProperty";
            };
        };
    };
}

config.AccountActions = {
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "I'd like to view my account's balance.";
                ShowIf = "PBNBAccount";
                Then = "ViewBalance";
            };
            {
                Text = "I'd like to make a cash deposit.";
                ShowIf = "PBNBAccount";
                Then = "DepositCash";
            };
            {
                Text = "I'd like to withdraw cash.";
                ShowIf = "PBNBAccount";
                Then = "WithdrawCash";
            };
        };
    };
}

config.ViewBalance = {
    Text = {
        "If you could just hand me your bank card, I can check that for you \z
        right away!";
    };
    Delay = 3;
    Then = {
        Type = "Respond";
        Response = "BankBalance";
        Options = config.Initial.Then.Options;
    };
}

config.DepositCash = {
    Text = {
        "Sure thing, how much would you like to deposit?";
    };
    Then = {
        Type = "InvokeInput";
        Function = "BankDeposit";
        RestrictText = "InputPosInt";
        Then = {
            Amount = "InvalidAmount";
            Frozen = "AccountFrozen";
            Insufficent = "InsufficentFunds";
            ["true"] = "DepositSuccess";
            ["nil"] = "ServerError";
        };
    };
}

config.DepositSuccess = {
    Text = {
        "Alright, I've gone and put that in your account for you. Is there \z
        anything else I can help you with?";
    };
    Then = config.Initial.Then;
}

config.WithdrawCash = {
    Text = {
        "If you could just hand me your bank card, I can get that for you \z
        right away!";
    };
    Then = {
        Type = "InvokeInput";
        Function = "BankWithdraw";
        RestrictText = "InputPosInt";
        AdditionalRestrictions = "ClampWithdraw";
        Then = {
            Amount = "InvalidAmount";
            Frozen = "AccountFrozen";
            Insufficent = "InsufficentFunds";
            ["true"] = "WithdrawSuccess";
            ["nil"] = "ServerError";
        };
    };
}

config.WithdrawSuccess = {
    Text = {
        "Here you go! Is there anything else I can help you with?";
    };
    Then = config.Initial.Then;
}

config.OpenAccount = {
    Text = {
        "Alright, we can get you set up with an account, if you could just \z
        give me your information.";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[ACCEPT] *Fill out your information*";
                Then = "GaveInformation";
            };
            {
                Text = "[DECLINE] Actually, I've reconsidered.";
                Then = "RefusedInformation";
            };
        };
    };
}

config.GaveInformation = {
    Text = {
        "Everything seems to be in order. Give me a moment, I'll go ahead \z
        and open up the account for you..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "MakeAccount";
        Arguments = {
            "PBNB";
        };
        Then = {
            ["true"] = "MadeAccount";
            ["nil"] = "ServerError";
        };
    };
}

config.MadeAccount = {
    Text = {
        "Alright, I went and opened the account for you. Here's your card! \z
        Is there anything else I can help you with?";
    };
    Then = config.Initial.Then;
}

config.RefusedInformation = {
    Text = {
        "Oh, alright then. Is there anything else I can help you with?";
    };
    Then = config.Initial.Then;
}

config.RentProperty = {
    Text = {
        "Sure thing. Here's our listings, let me know if you'd be interested \z
        in any of these!"
    };
    Delay = 3;
    Then = {
        Type = "PassOff";
        Function = "PropertyListings";
        Arguments = {
            "North";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            NoListings = "NoListings";
            ["true"] = "BoughtProperty";
            ["nil"] = "ServerError";
        };
    };
}

config.BoughtProperty = {
    Text = {
        "Here are your keys. Congratulations on your new home! Is there \z
        anything else I can help you with?";
    };
    Then = config.Initial.Then;
}

config.NoListings = {
    Text = {
        "Hm, it doesn't seem like we actually have any available property \z
        listings right now. Is there anything else I can help you with?";
    };
    Then = config.Initial.Then;
}

config.PayRent = {
    Text = {
        "Sure thing, let me just pull up your records, and I'll go ahead and \z
        pay that for you...";
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "PayRent";
        Then = {
            ["true"] = "PaidRent";
            ["nil"] = "ServerError";
        };
    };
}

config.PaidRent = {
    Text = {
        "Alright, your rent has been paid. Is there anything else I can do \z
        for you?";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "I'm sorry, but it doesn't seem like you have enough money to do that.";
    };
    Then = config.Initial.Then;
}

config.InvalidAmount = {
    Text = {
        "Please enter a valid amount for your transaction.";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "I'm sorry, we ran into some issues with our server. Come back later.";
    };
    Then = config.Initial.Then;
}

config.AccountFrozen = {
    Text = {
        "Your account has been frozen pending an investigation by the \z
        Ministry of Internal Affairs Tax Division. I am unable to assist you \z
        further.";
    };
    Then = {
        Type = "End";
    };
}

config.Goodbye = {
    Text = {
        "Thank you for banking with the People's Bank of North Bloxell. \z
        Have a nice day!";
    };
    Then = {
        Type = "End";
    };
}

return config