---Configuration for the clerk NPC at OOrkan Aparrel
local config = {}

config.Name = "Vopota Poltnova"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to OOrkan! Is there anything I can help you with?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "Can I see your clothing catalog?";
                Then = "OpenShop";
            };
        };
    };
}

config.OpenShop = {
    Text = {
        "Sure, here's our catalog, let me know what you'd like!";
    };
    Delay = 3;
    Then = {
        Type = "Shop";
        Name = "OOrkan";
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "Bought";
            ["nil"] = "ServerError";
        }
    };
}

config.Bought = {
    Text = {
        "Here you are. Can I get you anything else?";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "It doesn't seem like you have enough to buy all that...";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Something's gone wrong on our end. Try again later.";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Have a nice day!";
    };
    Then = {
        Type = "End";
    };
}

return config