---The configuration for buying ammo at the gun store
local config = {}

config.Name = "North Bloxford Guns and Ammo"

config.TakesCard = true
config.TakesCash = true

config.Items = {
    {
        Name = "ACP32Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 3200;
    };
    {
        Name = "ACP380Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 2850;
    };
    {
        Name = "ACP45Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 4000;
    };
    {
        Name = "AP127Box10";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 4800;
    };
    {
        Name = "Bird12Box25";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 1250;
    };
    {
        Name = "Bird20Box25";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 1200;
    };
    {
        Name = "Buck0012Box25";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 3400;
    };
    {
        Name = "Buck120Box25";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 1650;
    };
    {
        Name = "Dragon12Box25";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 19050;
    };
    {
        Name = "Magnum357Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 4200;
    };
    {
        Name = "Magnum44Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 5000;
    };
    {
        Name = "Makarov9Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 3200;
    };
    {
        Name = "Nagant762Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 4400;
    };
    {
        Name = "NATO556Box150";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 12500;
    };
    {
        Name = "NATO762Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 6600;
    };
    {
        Name = "Parabellum9Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 2900;
    };
    {
        Name = "Russian1075Box10";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 4200;
    };
    {
        Name = "Russian762Box20";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 4500;
    };
    {
        Name = "Slug12Box25";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 4200;
    };
    {
        Name = "Slug20Box25";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 1900;
    };
    {
        Name = "Soviet545Box30";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 3000;
    };
    {
        Name = "Soviet762Box20";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 1400;
    };
    {
        Name = "Tokarev762Box50";
        Type = "Item";
        SellIf = "NorthCitizen";
        Price = 3700;
    };
}

return config