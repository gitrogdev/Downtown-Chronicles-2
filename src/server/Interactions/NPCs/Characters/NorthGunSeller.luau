---Configuration for the clerk NPC at the gun store
local config = {}

config.Name = "Walther Colt"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to North Bloxford Guns & Ammo! What can I get for you today?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "I'd like to buy a firearm.";
                ShowIf = "NorthGunBuyer";
                Then = "OpenGunShop";
            };
            {
                Text = "I'd like to buy ammunition.";
                ShowIf = "NorthCitizen";
                Then = "OpenAmmoShop";
            };
            {
                Text = "What do I need to buy a weapon here?";
                Then = "WeaponRequirements";
            };
        };
    };
}

config.OpenAmmoShop = {
    Text = {
        "What are you in the market for today?";
    };
    Delay = 3;
    Then = {
        Type = "Shop";
        Name = "NorthAmmoStore";
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "Bought";
            ["nil"] = "ServerError";
        }
    };
}

config.OpenGunShop = {
    Text = {
        "What are you in the market for today?";
    };
    Delay = 3;
    Then = {
        Type = "Shop";
        Name = "NorthGunStore";
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "Bought";
            ["nil"] = "ServerError";
        }
    };
}

config.WeaponRequirements = {
    Text = {
        "In order to buy a weapon, you'll need to apply for a firearms \z
        license down at the police station.";
        "However, there are no restrictions on the sale of ammunition to the \z
        citizens of the State of North Bloxell. If you're not a citizen, you \z
        can also do that at the police station."
    };
    Then = config.Initial.Then;
}

config.Bought = {
    Text = {
        "Here you are. Always shoot responsibly.";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "If you're trying to rob the shop, you'll need a bigger gun!";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Something isn't working with the computer, come back later.";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Good luck out there, patriot.";
    };
    Then = {
        Type = "End";
    };
}

return config