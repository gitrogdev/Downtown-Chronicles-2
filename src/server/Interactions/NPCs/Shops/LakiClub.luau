---The configuration for a test shop for studio use
local config = {}

config.Name = "Laki Club"

config.TakesCard = true
config.TakesCash = false

config.Items = {
    {
        Name = "ColaBottle";
        Type = "Item";
        Price = 150;
    };
    {
        Name = "PacattiBottle";
        Type = "Item";
        Price = 200;
    };
    {
        Name = "KaliBottle";
        Type = "Item";
        Price = 150;
    };
    {
        Name = "KvasBottle";
        Type = "Item";
        Price = 100;
    };
}

return config