---Contains all configuration for slot machines
local config = {}

config.ClickCooldown = 0.25

config.Columns = 5
config.Rows = 4

config.MinBet = 40
config.RTPTarget = 96

config.DailyBonus = 10
config.WelcomeBonus = 50
config.WelcomeCost = 2000

--Current jackpot chance is 0.002% (or ≈1 jackpot every 50,000 games)
config.Jackpot = {
    Name = "MIG";
    Image = 5754533116;
    Odds = 200;
    Rules = {
        [3] = 70;
        [4] = 150;
        [5] = 525;
    };
}

config.LightColors = {
    Base = Color3.fromRGB(92, 172, 83);
    Jackpot = Color3.fromRGB(245, 205, 48);
}

config.Reels = {
    --Canned beans
    {
        Name = "BEANS";
        Image = 16638088267;
        Rules = {
            [3] = 5;
            [4] = 20;
            [5] = 100;
        };
    };
    --Valak Cola
    {
        Name = "VALAK";
        Image = 16638116968;
        Rules = {
            [3] = 5;
            [4] = 20;
            [5] = 100;
        };
    };
    --warts on my i don't care
    {
        Name = "WARTS";
        Image = 16545710784;
        Rules = {
            [3] = 5;
            [4] = 20;
            [5] = 100;
        };
    };
    --Sheriff
    {
        Name = "SHERIFF";
        Image = 16638123472;
        Rules = {
            [3] = 5;
            [4] = 20;
            [5] = 120;
        };
    };
    --Sedan
    {
        Name = "CAR";
        Image = 16638022242;
        Rules = {
            [3] = 5;
            [4] = 20;
            [5] = 120;
        };
    };
    --Gary
    {
        Name = "GARY";
        Image = 16638056847;
        Rules = {
            [3] = 5;
            [4] = 30;
            [5] = 150;
        };
    };
    --Northern eagle
    {
        Name = "EAGLE";
        Image = 17099391593;
        Rules = {
            [3] = 20;
            [4] = 40;
            [5] = 150;
        };
    };
    --Church window
    {
        Name = "CHURCH";
        Image = 16638132711;
        Rules = {
            [3] = 20;
            [4] = 40;
            [5] = 150;
        };
    };
    --Kill people!!!
    {
        Name = "KILL";
        Image = 16638136339;
        Rules = {
            [3] = 50;
            [4] = 100;
            [5] = 200;
        };
    };
}

return config