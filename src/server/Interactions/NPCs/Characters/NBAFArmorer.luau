---Configuration for the armorer NPC for the North Bloxell National Guard
local config = {}

config.Name = "Vasil Ivanoŭ"
config.Range = 10

config.Initial = {
    Text = {
        "Hey. You need something?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "I'd like to check out my service weapon.";
                ShowIf = "CheckoutNGWeapon";
                Then = "CheckoutWeapon";
            };
            {
                Text = "I'd like to check my service weapon back in.";
                ShowIf = "HasNGWeapon";
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
        "I keep an inventory on the weapons owned and operated by the North \z
        Bloxell National Guard. During a state of emergency, I'm responsible \z
        for distributing weapons to guardsmen and ensuring their safe return.";
    };
    Then = config.Initial.Then;
}

config.CheckoutWeapon = {
    Text = {
        "Just show me your ID, and I'll get you your weapons. A reminder \z
        that you are responsible for your weapon and its safe return at the \z
        end of the state of emergency.";
        "A reminder that you are not permitted to keep your weapon longer \z
        than the duration of the state of emergency. If a guardsman falls in \z
        duty, bring his weapon back to the armory.";
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "CheckoutWeapons";
        Arguments = {
            "NGArmory";
        };
        Then = {
            ["true"] = "GotWeapon";
            ["nil"] = "ServerError";
        };
    };
}

config.ReturnWeapons = {
    Text = {
        "Alright. Just hand me your ID, and I'll check those back in for you.";
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "ReturnWeapons";
        Arguments = {
            "NGArmory";
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
        "Mama le Valake.";
    };
    Then = {
        Type = "End";
    };
}

return config