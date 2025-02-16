--All configuration related to the bartender job
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedScripts = ReplicatedStorage.ReplicatedScripts
local Util = require(ReplicatedScripts.Util)

local config = {}

config.BasePay = 25

config.Differences = {
    Small = 1.08;
    Medium = 1.089;
    Large = 0.991;
}

config.FillTime = 5
config.MaxOrder = 5
config.StartDelay = 12

config.Sizes = {
    Small = 0.144;
    Medium = 0.33;
    Large = 0.5;
}

config.Taps = {
    Cola = {
        Name = "Valak Cola";
        Color = Color3.fromRGB(49, 21, 21);
    };
    Cream = {
        Name = "Cream Soda";
        Color = Color3.fromRGB(255, 255, 204);
    };
    Kali = {
        Name = "Kali";
        Color = Color3.fromRGB(113, 35, 1);
    };
    Kvas = {
        Name = "Kvas";
        Color = Color3.fromRGB(250, 193, 50);
    };
    Milk = {
        Name = "Whole Milk";
        Color = Color3.fromRGB(255, 255, 255);
    };
    Pacatti = {
        Name = "Root Beer";
        Color = Color3.fromRGB(106, 57, 9);
    };
}

config.SizeList = Util.KeysTable(config.Sizes)
config.TapList = Util.KeysTable(config.Taps)

return config