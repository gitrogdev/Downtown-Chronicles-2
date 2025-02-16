---Configuration for the clerk NPC at Bakery North
local config = {}

config.Name = "Olga Tverdohleb"
config.Range = 10

config.Initial = {
    Text = {
        "Hello.";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "What have you got today?";
                Then = "OpenShop";
            };
        };
    };
}

config.OpenShop = {
    Text = {
        "What do you want?";
    };
    Delay = 3;
    Then = {
        Type = "Shop";
        Name = "BakeryNorth";
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "Bought";
            ["nil"] = "ServerError";
        }
    };
}

config.Bought = {
    Text = {
        "Enjoy.";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "That's not enough money.";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Something's not working.";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Bye.";
    };
    Then = {
        Type = "End";
    };
}

return config