---The configuration for a test shop for studio use
local config = {}

config.Name = "shop for testing"

config.TakesCard = true
config.TakesCash = true

config.Items = {
    {
        Name = "KaliBottle";
        Type = "Item";
        Price = 130;
    };
    {
        Name = "ActiveShooter";
        Type = "Clothing";
        Price = 2000;
    };
}

return config