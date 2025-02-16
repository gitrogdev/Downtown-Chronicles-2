---Configuration for the armorer NPC for the Ministry of Internal Affairs
local config = {}

config.Name = "Brando Schmidt"
config.Range = 10

config.Initial = {
    Text = {
        "Looking for something? Everything's in tip-top shape.";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[POLICE] I'd like to check out my equipment.";
                ShowIf = "CheckoutMIAWeapon";
                Then = "CheckoutWeapon";
            };
            {
                Text = "[POLICE] I'd like to check my equipment back in.";
                ShowIf = "HasMIAWeapon";
                Then = "ReturnWeapons";
            };
            {
                Text = "What do you do?";
                Then = "CheckoutRequirements";
            };
        };
    };
}

config.CheckoutRequirements = {
    Text = {
        "It's my job to ensure the weapons of the police, that is, the \z
        Ministry of Internal Affairs, are kept in a ready condition and are \z
        accounted for, so that they don't end up in the wrong hands.";
    };
    Then = config.Initial.Then;
}

config.CheckoutWeapon = {
    Text = {
        "Sure, just show me your badge and let me know what you're looking \z
        to check out, and I'll get that for you.";
        "Remember, these weapons are property of the Ministry of Internal \z
        Affairs, they aren't your personal weapons. Don't carry them off \z
        duty, and don't lose them, or you'll be held responsible for it.";
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "CheckoutWeapons";
        Arguments = {
            "MIAArmory";
        };
        Then = {
            ["true"] = "GotWeapon";
            ["nil"] = "ServerError";
        };
    };
}

config.ReturnWeapons = {
    Text = {
        "Sure, just show me your badge, and I'll get those signed back in.";
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "ReturnWeapons";
        Arguments = {
            "MIAArmory";
        };
        Then = {
            NoWeapons = "NothingReturned";
            ["true"] = "ReturnedWeapons";
            ["nil"] = "ServerError";
        };
    };
}

config.GotWeapon = {
    Text = {
        "Here's your weapon. Remember to bring it and the magazines back!"
    };
    Then = {
        Type = "End";
    };
}

config.ReturnedWeapons = {
    Text = {
        "Alright, I've checked your weapons back in."
    };
    Then = {
        Type = "End";
    };
}

config.NothingReturned = {
    Text = {
        "If you want to return weapons to the armory, you should probably \z
        have them on you.";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Something went wrong with our authorization servers. You should \z
        forward this to a superior officer.";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Let's keep our city safe.";
    };
    Then = {
        Type = "End";
    };
}

return config