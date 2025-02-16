--This script contains format information for chat messages
local config = {}

config.CommandPrefix = "/"

config.Commands = {
    ["b "] = {
        Prefix = "(( ${Username}: ";
        Substring = {4};
        Suffix = " ))";
        TextColor3 = Color3.new(0.75, 0.75, 0.75);
    };
    ["do "] = {
        Prefix = "*";
        Substring = {5};
        Suffix = "(( ${Associated} )) ";
        TextColor3 = Color3.fromRGB(170,85,255);
    };
    ["dolow "] = {
        Prefix = "*";
        Range = 10;
        Substring = {8};
        Suffix = "(( ${Associated} )) ";
        TextColor3 = Color3.fromRGB(170,85,255);
    };
    ["low "] = {
        Prefix = "${Associated} [low]: ";
        Range = 10;
        Substring = {6};
        TextColor3 = Color3.new(0.75, 0.75, 0.75);
    };
    ["me "] = {
        Prefix = "***${Associated} ";
        Substring = {5};
        TextColor3 = Color3.fromRGB(170,85,255);
    };
    ["melow "] = {
        Prefix = "***${Associated} ";
        Range = 10;
        Substring = {8};
        TextColor3 = Color3.fromRGB(170,85,255);
    };
    ["my "] = {
        Prefix = "* ${Associated}'s ";
        Substring = {5};
        TextColor3 = Color3.fromRGB(170,85,255);
    };
    ["ooc "] = {
        Prefix = "(( ${Username}: ";
        Substring = {6};
        Suffix = " ))";
        TextColor3 = Color3.new(0.75, 0.75, 0.75);
    };
    ["s "] = {
        Prefix = "${Associated} shouts: ";
        Range = 100;
        Substring = {4};
        Suffix = "!"
    };
    ["shout "] = {
        Prefix = "${Associated} shouts: ";
        Range = 100;
        Substring = {8};
        Suffix = "!"
    };
}

config.Default = {
    Prefix = "${Associated}: ";
    Range = 50;
    TextColor3 = Color3.new(1, 1, 1);
}

config.EscapeForms = {
    {"&lt;", "<"};
    {"&gt;", ">"};
    {"&quot;", "\""};
    {"&apos;", "\'"};
    {"&amp;", "&"};
}

config.Formats = {
    Username = function(Player: Player)
        return Player.Name
    end
}

config.Radio = {
    Prefix = "[Radio] ${Associated}: ";
    TextColor3 = Color3.fromRGB(80, 109, 84);
}

return config