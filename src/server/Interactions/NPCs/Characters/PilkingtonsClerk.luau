---Configuration for the clerk NPC at Pilkington's
local config = {}

config.Name = "Alfred Pilkington"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to Pilkington's. Let me know if you need any assistance.";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "I'd like to browse your inventory.";
                Then = "OpenShop";
            };
        };
    };
}

config.OpenShop = {
    Text = {
        "What were you thinking of today?";
    };
    Delay = 3;
    Then = {
        Type = "Shop";
        Name = "Pilkingtons";
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "Bought";
            ["nil"] = "ServerError";
        }
    };
}

config.Bought = {
    Text = {
        "And here you are. We await your next visit.";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "You don't seem to have enough money for that. May I recommend \z
        OOrkan Apparel?";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Hm, something's not right with our computer. Come back in a bit.";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "You have a nice day.";
    };
    Then = {
        Type = "End";
    };
}

return config