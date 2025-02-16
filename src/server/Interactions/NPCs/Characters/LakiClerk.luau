---Configuration for the attendant NPC at the Laki Club
local config = {}

config.Name = "Manu Utahinu"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to the Laki Club! What can I do for you?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "I'd like to buy a drink.";
                Then = "OpenShop";
            };
            {
                Text = "I'd like to play.";
                Then = "GameInfo";
            };
            {
                Text = "I'd like to claim my free drink voucher.";
                ShowIf = "LakiDrink";
                Then = "ClaimDrink";
            };
        };
    };
}

config.OpenShop = {
    Text = {
        "Sure thing, what can I get for you?";
    };
    Delay = 3;
    Then = {
        Type = "Shop";
        Name = "LakiClub";
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "Bought";
            ["nil"] = "ServerError";
        }
    };
}

config.Bought = {
    Text = {
        "Here you go. Enjoy, and best of luck!";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "Not enough for a drink? Go win big and come back!";
    };
    Then = config.Initial.Then;
}

config.GameInfo = {
    Text = {
        "So, in order to play you'll need money on your bank card. We don't \z
        take cash here, unfortunately, so if you have cash, you'll need to \z
        run down to the bank and deposit that.";
        "With your card, just tap on the machine you want to play, and you \z
        can start gaming!";
        "To win, you need to get three or more of the same symbol in adjacent \z
        reels. There are no rows on our machines, so the position in the reel \z
        isn't important.";
        "To win the jackpot, you'll need to get three or more adjacent MiG \z
        symbols. Three MiGs is a bronze jackpot, four is a silver, and five \z
        is a gold.";
        "MiG symbols also add a 2x multiplier to all wins you have on screen, \z
        which increases exponentially. So the displayed jackpot amount is \z
        like a minimum, in a way. With other wins on the screen, you could \z
        win way more!";
    };
    Then = config.Initial.Then;
}

config.ClaimDrink = {
    Text = {
        "Sure thing! Let me just check our system..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "ClaimReward";
        Arguments = {
            "LakiDrink";
        };
        Then = {
            ["true"] = "GotDrink";
            ["nil"] = "ServerError";
        };
    };
}

config.GotDrink = {
    Text = {
        "Here you are. Happy gaming!";
    };
    Then = {
        Type = "End";
    };
}

config.ServerError = {
    Text = {
        "We're having some issues with our server... At least the slot \z
        machines are working, why don't you try those!";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Best of luck!";
    };
    Then = {
        Type = "End";
    };
}

return config