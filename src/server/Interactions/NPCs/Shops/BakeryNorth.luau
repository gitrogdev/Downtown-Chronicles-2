---The configuration for a test shop for studio use
local config = {}

config.Name = "Bakery North"

config.TakesCard = false
config.TakesCash = true

config.Items = {
    {
        Name = "Bread";
        Type = "Item";
        Price = 150;
    };
    {
        Name = "Croissant";
        Type = "Item";
        Price = 80;
    };
    {
        Name = "HotDog";
        Type = "Item";
        Price = 160;
    };
    {
        Name = "Donut";
        Type = "Item";
        Price = 80;
    };
    {
        Name = "Cheburek";
        Type = "Item";
        Price = 320;
    };
    {
        Name = "Sandwich";
        Type = "Item";
        Price = 150;
    };
    {
        Name = "Danish";
        Type = "Item";
        Price = 190;
    };
}

return config