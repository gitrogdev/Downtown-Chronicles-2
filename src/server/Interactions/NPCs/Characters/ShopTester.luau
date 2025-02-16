---Configuration for the shop testing NPC
local config = {}

config.Name = "shop tester"
config.Range = 10

config.Initial = {
    Text = {
        "what u claim";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "Shop";
                Then = "OpenShop";
            };
        };
    };
}

config.OpenShop = {
    Text = {
        "yeah we got the stuff";
    };
    Delay = 3;
    Then = {
        Type = "Shop";
        Name = "TestShop";
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "Bought";
            ["nil"] = "ServerError";
        }
    };
}

config.Bought = {
    Text = {
        "you got it buddy";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "brokey!";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "error";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "later loser";
    };
    Then = {
        Type = "End";
    };
}

return config