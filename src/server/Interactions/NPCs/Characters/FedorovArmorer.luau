---Configuration for the armorer NPC for the Fedorov Center
local config = {}

config.Name = "Vanya Nahimana"
config.Range = 10

config.Initial = {
    Text = {
        "You need a piece? I'll hook you up good, man.";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[INVESTIGATIVE] I'd like to check out a service weapon.";
                ShowIf = "CheckoutMIAWeapon";
                Then = "CheckoutWeapon";
            };
            {
                Text = "[INVESTIGATIVE] I'd like to return my service weapon.";
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
        "Hey, I give straps to the people that need 'em, if you pickin up \z
        what I'm putting down.";
    };
    Then = config.Initial.Then;
}

config.CheckoutWeapon = {
    Text = {
        "Yeah, show me what I need to see, and I'll get you what you need.";
        "It's yours to keep, as long as it's yours. Just make sure nobody \z
        else ends up with it.";
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
        "Yeah, just show me what I need to see, and I'll put those back.";
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
        "Here you are man. Good luck.";
    };
    Then = {
        Type = "End";
    };
}

config.ReturnedWeapons = {
    Text = {
        "You're good to go, thanks for bringing those back."
    };
    Then = {
        Type = "End";
    };
}

config.NothingReturned = {
    Text = {
        "Hey, don't be sayin you wanna return some if you ain't got nun to \z
        return.";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Man, something just ain't workin!";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Peace.";
    };
    Then = {
        Type = "End";
    };
}

return config