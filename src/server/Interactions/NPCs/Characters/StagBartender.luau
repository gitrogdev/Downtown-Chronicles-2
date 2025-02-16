---Configuration for the bartender NPC at the Red Stag
local config = {}

config.Name = "Samuel Guinness"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to the Red Stag. We have bottled and draft drinks. What can \z
        I get for you today?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[BARTENDER] *Clock in*";
                ShowIf = "OffdutyBartender";
                Then = "ClockIn";
            };
            {
                Text = "[BARTENDER] *Clock out*";
                ShowIf = "OndutyBartender";
                Then = "ClockOut";
            };
            {
                Text = "[BARTENDER] I'd like to tender my resignation.";
                ShowIf = "OffdutyBartender";
                Then = "QuitRequest";
            };
            {
                Text = "I'd like to buy a drink.";
                ShowIf = "NotOndutyBartender";
                Then = "OpenShop";
            };
            {
                Text = "I'd like to apply for a job as a bartender.";
                ShowIf = "Unemployed";
                Then = "SeekWork";
            };
        };
    };
}

config.OpenShop = {
    Text = {
        "Sure thing! What can I get you?";
    };
    Delay = 3;
    Then = {
        Type = "Shop";
        Name = "RedStag";
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "BoughtDrinks";
            ["nil"] = "ServerError";
        }
    };
}

config.BoughtDrinks = {
    Text = {
        "Here you are. Enjoy!";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "Hey, you can't afford that!";
    };
    Then = config.Initial.Then;
}

config.ClockIn = {
    Text = {
        "Sure thing! Just let me clock you in..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "StartJob";
        Arguments = {
            "Bartender";
        };
        Then = {
            ["true"] = "StartJob";
            ["nil"] = "ServerError";
        };
    };
}

config.ClockOut = {
    Text = {
        "Give me a second just to log your hours..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "ClockOut";
        Then = {
            ["true"] = "ClockedOut";
            ["nil"] = "ServerError";
        };
    };
}

config.ClockedOut = {
    Text = {
        "Alright, I'll see you later. Have a nice day!";
    };
    Then = {
        Type = "End";
    };
}

config.StartJob = {
    Text = {
        "Alright, you're clocked in. I'll give you orders as they come in, \z
        just pour the drinks, don't worry about serving them, a waiter will \z
        handle that. Just let me know when you're clocking out."
    };
    Then = {
        Type = "End";
    };
}

config.SeekWork = {
    Text = {
        "Sure, we're currently hiring bartenders. Your job responsibilities \z
        would be simple: we need you to pour drinks to order.";
        "If you're interested, just hand over your information, and you can \z
        get started right away.";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[ACCEPT] *Fill out your information.*";
                ShowIf = "PBNBAccount";
                Then = "GaveInformation";
            };
            {
                Text = "[ACCEPT] *Fill out your information.*";
                ShowIf = "NoPBNBAccount";
                Then = "NoBank";
            };
            {
                Text = "[DECLINE] Maybe another time.";
                Then = "RefusedInformation";
            };
        };
    };
}

config.GaveInformation = {
    Text = {
        "Alright then! Give me a second just to go ahead and submit your \z
        documents..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "TakeJob";
        Arguments = {
            "Bartender";
        };
        Then = {
            NoBank = "NoBank";
            ["true"] = "GotJob";
            ["nil"] = "ServerError";
        };
    };
}

config.GotJob = {
    Text = {
        "Welcome to the Red Stag crew! When you're ready to get started, just \z
        let me know and I'll clock you in."
    };
    Then = config.Initial.Then;
}

config.NoBank = {
    Text = {
        "Hm. Before I can hire you, you're going to need to open a bank \z
        account here in North Bloxell.";
        "The bank's just around the corner, head outside, take a right, take \z
        another right at the intersection, and it'll be right there.";
        "Once you've opened up your account, we can get you started right away!"
    };
    Then = config.Initial.Then;
}

config.RefusedInformation = {
    Text = {
        "Well, if you change your mind, we'll be here.";
    };
    Then = config.Initial.Then;
}

config.QuitRequest = {
    Text = {
        "You're quitting? Are you sure?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "Yes, I am.";
                Then = "QuitJob";
            };
            {
                Text = "Actually, I don't want to quit.";
                Then = "DidntQuit";
            };
        };
    };
}

config.QuitJob = {
    Text = {
        "Well, we're sorry to see you go. Give me a second just to get all \z
        the paperwork in order..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "QuitJob";
        Then = {
            ["true"] = "QuitSuccess";
            ["nil"] = "ServerError";
        };
    };
}

config.QuitSuccess = {
    Text = {
        "Well, that's it then. It's been a pleasure working with you. Can I \z
        get you anything to drink?"
    };
    Then = config.Initial.Then;
}

config.DidntQuit = {
    Text = {
        "Well, don't joke about such things then! We appreciate your work here."
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "I'm sorry, we ran into some issues with our server. Come back later.";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Let me know if I can get you anything else.";
    };
    Then = {
        Type = "End";
    };
}

return config