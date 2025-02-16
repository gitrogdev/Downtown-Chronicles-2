---The configuration for a test shop for studio use
local config = {}

config.Name = "The Red Stag"

config.TakesCard = true
config.TakesCash = true

config.Items = {
    {
        Name = "PacattiSmall";
        Type = "Item";
        Price = 100;
    };
    {
        Name = "PacattiMedium";
        Type = "Item";
        Price = 120;
    };
    {
        Name = "PacattiLarge";
        Type = "Item";
        Price = 140;
    };

    {
        Name = "KaliSmall";
        Type = "Item";
        Price = 70;
    };
    {
        Name = "KaliMedium";
        Type = "Item";
        Price = 90;
    };
    {
        Name = "KaliLarge";
        Type = "Item";
        Price = 110;
    };

    {
        Name = "CreamSmall";
        Type = "Item";
        Price = 280;
    };
    {
        Name = "CreamMedium";
        Type = "Item";
        Price = 300;
    };
    {
        Name = "CreamLarge";
        Type = "Item";
        Price = 320;
    };

    {
        Name = "ColaSmall";
        Type = "Item";
        Price = 60;
    };
    {
        Name = "ColaMedium";
        Type = "Item";
        Price = 80;
    };
    {
        Name = "ColaLarge";
        Type = "Item";
        Price = 100;
    };

    {
        Name = "KvasSmall";
        Type = "Item";
        Price = 20;
    };
    {
        Name = "KvasMedium";
        Type = "Item";
        Price = 40;
    };
    {
        Name = "KvasLarge";
        Type = "Item";
        Price = 60;
    };

    {
        Name = "MilkSmall";
        Type = "Item";
        Price = 70;
    };
    {
        Name = "MilkMedium";
        Type = "Item";
        Price = 90;
    };
    {
        Name = "MilkLarge";
        Type = "Item";
        Price = 110;
    };

    
    {
        Name = "PacattiBottle";
        Type = "Item";
        Price = 160;
    };
    {
        Name = "KaliBottle";
        Type = "Item";
        Price = 130;
    };
    {
        Name = "CreamBottle";
        Type = "Item";
        Price = 340;
    };
    {
        Name = "ColaBottle";
        Type = "Item";
        Price = 125;
    };
    {
        Name = "KvasBottle";
        Type = "Item";
        Price = 80;
    };
}

return config