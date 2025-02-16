--This script contains the information for all items
local ServerScriptService = game:GetService("ServerScriptService")

local ServerScripts = ServerScriptService.ServerScripts
local FirearmsHandler = require(ServerScripts.Firearms)
local FoodHandler = require(ServerScripts.Food)
local DeathHandler = require(ServerScripts.Deaths)
local MeleeHandler = require(ServerScripts.Melee)
local MIAHandler = require(ServerScripts.Jobs.MIA)
local MoneyHandler = require(ServerScripts.Money)
local MortarHandler = require(ServerScripts.Mortars)
local RadioHandler = require(ServerScripts.Chat.Radio)
local SanitationHandler = require(ServerScripts.Jobs.Sanitation)

local config = {}

config.ACP32Box50 = {
    DisplayName = ".32 ACP 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.035;
    Weight = 0.1;
}

config.ACP380Box50 = {
    DisplayName = ".380 ACP 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.06;
    Weight = 0.1;
}

config.ACP45Box50 = {
    DisplayName = ".45 ACP 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.14;
    Weight = 0.1;
}

config.AB10 = {
    DisplayName = "AB-10";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.24;
    Weight = 1.23;
}

config.Airsoft25Bottle5000 = {
    DisplayName = ".25g Airsoft Pellet 5000-round Bottle";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.2;
    Weight = 0.1;
}

config.AK74Mag30 = {
    DisplayName = "AK-74 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.21;
    Weight = 0.23;
}

config.AKMMag30 = {
    DisplayName = "AKM 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.22;
    Weight = 0.33;
}

config.AKS74U = {
    DisplayName = "AKS-74U";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
        Shoulder = true;
    };

    Length = 0.49;
    Weight = 2.7;
}

config.AlaskanRedhawk = {
    DisplayName = "Alaskan Redhawk";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
        Pocket = true;
    };

    Length = 0.19;
    Weight = 1.25;
}

config.AP127Box10 = {
    DisplayName = "12.7 x 108mm 10-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.13;
    Weight = 0.1;
}

config.AP145Box10 = {
    DisplayName = "14.5 x 114mm 10-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.15;
    Weight = 0.1;
}

config.ASH781 = {
    DisplayName = "ASH 78-1";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.87;
    Weight = 3.8;
}

config.Berdan = {
    DisplayName = "Berdan II";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 1.3;
    Weight = 4.2;
}

config.Bird12Box25 = {
    DisplayName = "12 gauge Birdshot 25-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.35;
    Weight = 0.1;
}

config.Bird20Box25 = {
    DisplayName = "20 gauge Birdshot 25-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.35;
    Weight = 0.1;
}

config.Bread = {
    DisplayName = "Bread";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.65;
    Weight = 0.5;
}

config.Buck0012Box25 = {
    DisplayName = "12 gauge 00 Buck 25-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.35;
    Weight = 0.1;
}

config.Buck120Box25 = {
    DisplayName = "20 gauge #1 Buck 25-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.35;
    Weight = 0.1;
}

config.C9Mag8 = {
    DisplayName = "Hi-Point C-9 8-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.15;
    Weight = 0.11;
}

config.Cash = {
    DontSpawn = true;
    Setup = function(attributes: table)
        return MoneyHandler.NewStack(attributes.Value)
    end;
    Slots = {
        Pocket = true;
    };

    Length = 0.15;
}

config.CombatKnife = {
    DisplayName = "Combat Knife";
    Setup = MeleeHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.3;
    Weight = 0.32;
}

config.CZ99 = {
    DisplayName = "Zastava CZ99";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.19;
    Weight = 0.97;
}

config.CZ99Mag15 = {
    DisplayName = "Zastava CZ99 15-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.19;
    Weight = 0.09;
}

config.Cheburek = {
    DisplayName = "Cheburek";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.39;
    Weight = .11;
}

config.Corpse = {
    DestroyOnDrop = true;
    DestroyOnUnequip = true;
    DontSpawn = true;
    DontSave = true;
    Setup = DeathHandler.CorpseHandle;
    Slots = {};

    Length = 1.52;
    Weight = 30;
}

config.ColaBottle = {
    DisplayName = "Valak Cola Bottle";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.26;
    Weight = 0.88;
}

config.ColaLarge = {
    DisplayName = "Large Valak Cola";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.21;
    Weight = 1.03;
}

config.ColaMedium = {
    DisplayName = "Medium Valak Cola";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.15;
    Weight = 0.76;
}

config.ColaSmall = {
    DisplayName = "Small Valak Cola";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.16;
    Weight = 0.52;
}

config.CreamBottle = {
    DisplayName = "Orange Penguin Bottle";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.26;
    Weight = 0.88;
}

config.CreamLarge = {
    DisplayName = "Large Orange Penguin";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.21;
    Weight = 1.03;
}

config.CreamMedium = {
    DisplayName = "Medium Orange Penguin";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.15;
    Weight = 0.76;
}

config.CreamSmall = {
    DisplayName = "Small Orange Penguin";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.16;
    Weight = 0.52;
}

config.Croissant = {
    DisplayName = "Croissant";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.36;
    Weight = 0.1;
}

config.Danish = {
    DisplayName = "Danish";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.24;
    Weight = 0.1;
}

config.Donut = {
    DisplayName = "Donut";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.16;
    Weight = 0.03;
}

config.Dragon12Box25 = {
    DisplayName = "12 gauge Dragon's Breath 25-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.35;
    Weight = 0.1;
}

config.F2000 = {
    DisplayName = "FN F2000";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
    };

    Length = 0.69;
    Weight = 3.6;
}

config.FP45 = {
    DisplayName = "FP-45 Liberator";
    Setup = FirearmsHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.14;
    Weight = 0.45;
}

config.FS2000 = {
    DisplayName = "FN FS2000";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
    };

    Length = 0.69;
    Weight = 3.6;
}

config.G3 = {
    DisplayName = "H&K G3";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
    };

    Length = 1.03;
    Weight = 4.7;
}

config.G3Mag20 = {
    DisplayName = "G3 20-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.14;
    Weight = 0.4;
}

config.GlassLarge = {
    DisplayName = "Wheat Glass";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.21;
    Weight = 0.53;
}

config.GlassMedium = {
    DisplayName = "Tulip Glass";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.15;
    Weight = 0.36;
}

config.GlassSmall = {
    DisplayName = "Cooler Glass";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.16;
    Weight = 0.22;
}

config.Glock19 = {
    DisplayName = "Glock 19";
    Setup = FirearmsHandler.new;
    Slots = {
        Pocket = true;
        Hip = true;
    };

    Length = 0.19;
    Weight = 0.595;
}

config.Glock19Airsoft = {
    DisplayName = "Airsoft Glock 19";
    Setup = FirearmsHandler.new;
    Slots = {
        Pocket = true;
        Hip = true;
    };

    Length = 0.19;
    Weight = 0.595;
}

config.Glock19AirsoftMag30 = {
    DisplayName = "Airsoft Glock 19 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.1;
    Weight = 0.07;
}

config.Glock19Mag15 = {
    DisplayName = "Glock 19 15-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.1;
    Weight = 0.07;
}

config.Handcuffs = {
    DisplayName = "Handcuffs";
    Setup = MIAHandler.NewCuffs;
    Slots = {
        Pocket = true;
        Back = true;
        Front = true;
    };

    Length = 0.37;
    Weight = 0.14;
}

config.HandcuffKey = {
    DisplayName = "Handcuff Key";
    Setup = MIAHandler.NewCuffKey;
    Slots = {
        Pocket = true;
    };

    Length = 0.05;
    Weight = 0.03;
}

config.HiPointC9 = {
    DisplayName = "Hi-Point C-9";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.17;
    Weight = 0.71;
}

config.HK417Mag20 = {
    DisplayName = "HK417 20-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.18;
    Weight = 0.4;
}

config.HotDog = {
    DisplayName = "Hot Dog";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.25;
    Weight = 0.05;
}

config.KaliBottle = {
    DisplayName = "Vanaema Kali Bottle";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.26;
    Weight = 0.88;
}

config.KaliLarge = {
    DisplayName = "Large Vanaema Kali";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.21;
    Weight = 1.03;
}

config.KaliMedium = {
    DisplayName = "Medium Vanaema Kali";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.15;
    Weight = 0.76;
}

config.KaliSmall = {
    DisplayName = "Small Vanaema Kali";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.16;
    Weight = 0.52;
}

config.KvasBottle = {
    DisplayName = "Zakhidnyy Kvas Bottle";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.26;
    Weight = 0.88;
}

config.KvasLarge = {
    DisplayName = "Large Zakhidnyy Kvas";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.21;
    Weight = 1.03;
}

config.KvasMedium = {
    DisplayName = "Medium Zakhidnyy Kvas";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.15;
    Weight = 0.76;
}

config.KvasSmall = {
    DisplayName = "Small Zakhidnyy Kvas";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.16;
    Weight = 0.52;
}

config.LCP = {
    DisplayName = "Ruger LCP";
    Setup = FirearmsHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.13;
    Weight = 0.27;
}

config.LCPMag6 = {
    DisplayName = "Ruger LCP 6-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.09;
    Weight = 0.031;
}

config.Luger = {
    DisplayName = "Luger P08";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.22;
    Weight = .871;
}

config.LugerMag8 = {
    DisplayName = "Luger P08 8-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.24;
    Weight = 0.1;
}

config.M15 = {
    DisplayName = "M15";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.99;
    Weight = 2.89;
}

config.M16 = {
    DisplayName = "M16";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.99;
    Weight = 2.89;
}

config.M16Mag20 = {
    DisplayName = "M16 20-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.14;
    Weight = 0.09;
}

config.M1911 = {
    DisplayName = "M1911";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.22;
    Weight = 0.96;
}

config.M1911Mag7 = {
    DisplayName = "M1911 7-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.12;
    Weight = 0.14;
}

config.M3 = {
    DisplayName = "M3 Grease Gun";
    Setup = FirearmsHandler.new;
    Slots = {
        Front = true;
        Shoulder = true;
    };

    Length = 0.56;
    Weight = 3.7;
}


config.M37 = {
    DisplayName = "82-BM-37";
    Setup = MortarHandler.new;
    Slots = {
        Back = true;
    };

    Length = 1.22;
    Weight = 56;
}

config.M3Mag32 = {
    DisplayName = "M3 32-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.37;
    Weight = 0.14;
}

config.M57 = {
    DisplayName = "Zastava M57";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.19;
    Weight = 0.85;
}

config.M57Mag9 = {
    DisplayName = "Zastava M57 9-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.14;
    Weight = 0.1;
}

config.M6P9 = {
    DisplayName = "Izhevsk 6P9";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
        Pocket = true;
    };

    Length = 0.17;
    Weight = 0.98;
}

config.M70B3 = {
    DisplayName = "Zastava M70B3";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.89;
    Weight = 3.7;
}

config.M70Mag30 = {
    DisplayName = "Zastava M70 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.22;
    Weight = 0.34;
}

config.M72B1 = {
    DisplayName = "Zastava M72B1";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 1.03;
    Weight = 5.5;
}

config.M77 = {
    DisplayName = "Zastava M77";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.99;
    Weight = 4.8;
}

config.M77Mag20 = {
    DisplayName = "Zastava M77 20-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.18;
    Weight = 0.4;
}

config.M84 = {
    DisplayName = "Zastava M84";
    Setup = FirearmsHandler.new;
    Slots = {
        Shoulder = true;
    };

    Length = 1.18;
    Weight = 8.8;
}

config.M85Mag30 = {
    DisplayName = "Zastava M85 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.22;
    Weight = 0.36;
}

config.M9 = {
    DisplayName = "Beretta M9";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.22;
    Weight = 0.97;
}

config.M92 = {
    DisplayName = "Zastava M92";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
        Shoulder = true;
    };

    Length = 0.55;
    Weight = 3.57;
}

config.M93 = {
    DisplayName = "M93 Black Arrow";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 1.67;
    Weight = 16;
}

config.M93Mag5 = {
    DisplayName = "M93 5-round magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.27;
    Weight = 0.76;
}

config.M9Mag15 = {
    DisplayName = "M9 15-round magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.13;
    Weight = 0.11;
}

config.MAC10 = {
    DisplayName = "MAC-10";
    Setup = FirearmsHandler.new;
    Slots = {
        Front = true;
        Hip = true;
        Shoulder = true;
    };

    Length = 0.27;
    Weight = 2.84;
}

config.MAC1045Mag32 = {
    DisplayName = "MAC-10 .45 ACP 32-round magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.28;
    Weight = 0.3;
}

config.Magnum357Box50 = {
    DisplayName = ".357 Magnum 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.12;
    Weight = 0.1;
}

config.Magnum44Box50 = {
    DisplayName = ".44 Magnum 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.13;
    Weight = 0.1;
}

config.MafiaPPSh = {
    DisplayName = "PPSh-41";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.4;
    Weight = 1.45;
}

config.MakarovMag8 = {
    DisplayName = "Makarov 8-round magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.1;
    Weight = 0.09;
}

config.Makarov9Box50 = {
    DisplayName = "9 x 18mm 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.06;
    Weight = 0.1;
}

config.Mauser92Box20 = {
    DisplayName = "7.92 x 57mm Mauser 20-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.09;
    Weight = 0.1;
}

config.MilkLarge = {
    DisplayName = "Large Whole Milk";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.21;
    Weight = 1.03;
}

config.MilkMedium = {
    DisplayName = "Medium Whole Milk";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.15;
    Weight = 0.76;
}

config.MilkSmall = {
    DisplayName = "Small Whole Milk";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.16;
    Weight = 0.52;
}

config.Mortar82 = {
    DisplayName = "82mm Mortar Round";
    Setup = MortarHandler.NewRound;
    Slots = {
        Pocket = true;
    };

    Length = 0.33;
    Weight = 3.05;
}

config.Mosin = {
    DisplayName = "Mosin-Nagant";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Shoulder = true;
    };

    Length = 1;
    Weight = 4;
}

config.MosinClip5 = {
    DisplayName = "Mosin-Nagant 5-round Clip";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.05;
    Weight = 0.045;
}

config.Mossberg50012 = {
    DisplayName = "Mossberg 500 12 gauge";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 1;
    Weight = 3.52;
}

config.Mossberg50020 = {
    DisplayName = "Mossberg 500 20 gauge";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 1;
    Weight = 3.52;
}

config.MP443 = {
    DisplayName = "MP-443 Grach";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.2;
    Weight = .95;
}

config.MP443Mag18 = {
    DisplayName = "MP-443 18-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.14;
    Weight = 0.105;
}

config.MPiK74 = {
    DisplayName = "MPi-K74";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.94;
    Weight = 3.07;
}

config.MPiK74K = {
    DisplayName = "MPi-K74K";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
    };

    Length = 0.69;
    Weight = 2.97;
}

config.MPiK74NK = {
    DisplayName = "MPi-K74NK";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
        Shoulder = true;
    };

    Length = 0.49;
    Weight = 2.7;
}

config.MPiKM = {
    DisplayName = "MPi-KM";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.88;
    Weight = 3.3;
}

config.MPiKMK = {
    DisplayName = "MPi-KMK";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
        Shoulder = true;
    };

    Length = 0.49;
    Weight = 3.1;
}

config.MPiKMS = {
    DisplayName = "MPi-KMS";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
    };

    Length = 0.66;
    Weight = 3.5;
}

config.MR308 = {
    DisplayName = "H&K MR308";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.99;
    Weight = 4.37;
}

config.NATO556Box150 = {
    DisplayName = "5.56 x 45mm 150-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.21;
    Weight = 0.1;
}

config.NATO762Box50 = {
    DisplayName = "7.62 x 51mm 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.17;
    Weight = 0.1;
}

config.Nagant1895 = {
    DisplayName = "Nagant M1895";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.24;
    Weight = 0.8;
}

config.Nagant762Box50 = {
    DisplayName = "7.62 x 38mmR 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.11;
    Weight = 0.1;
}

config.P85 = {
    DisplayName = "Huntsman P85";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 1;
    Weight = 3.4;
}

config.P85Mag30 = {
    DisplayName = "P85 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.19;
    Weight = 0.19;
}

config.PacattiBottle = {
    DisplayName = "Pacatijsko Bottle";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.26;
    Weight = 0.88;
}

config.PacattiLarge = {
    DisplayName = "Large Pacatijsko";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.21;
    Weight = 1.03;
}

config.PacattiMedium = {
    DisplayName = "Medium Pacatijsko";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.15;
    Weight = 0.76;
}

config.PacattiSmall = {
    DisplayName = "Small Pacatijsko";
    Setup = FoodHandler.new;
    Slots = {};

    Length = 0.16;
    Weight = 0.52;
}

config.Parabellum9Box50 = {
    DisplayName = "9 x 19mm 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.06;
    Weight = 0.1;
}

config.PB = {
    DisplayName = "Izhevsk PB";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.31;
    Weight = 1.111;
}

config.PKMBox100 = {
    DisplayName = "PKM 100-round Box";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.26;
    Weight = 1.373;
}

config.PowerWasher = {
    DisplayName = "Power Washer";
    Setup = SanitationHandler.NewWasher;
    Slots = {
        Shoulder = true;
    };

    Length = 1;
    Weight = 4.4;
}

config.PPSh = {
    DisplayName = "PPSh-41";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
        Shoulder = true;
    };

    Length = 0.84;
    Weight = 3.63;
}

config.PPShDrum71 = {
    DisplayName = "PPSh-41 71-round Drum";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Hip = true;
        Pocket = true;
    };

    Length = 0.3;
    Weight = 0.91;
}

config.PTR91 = {
    DisplayName = "PTR 91";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
    };

    Length = 1.03;
    Weight = 4.41;
}

config.PTRD41 = {
    DisplayName = "PTRD-41";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 2.02;
    Weight = 17.3;
}

config.Russian1075Box10 = {
    DisplayName = "10.75 x 58mmR 10-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.08;
    Weight = 0.1;
}

config.Russian762Box20 = {
    DisplayName = "7.62 x 54mmR 20-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.21;
    Weight = 0.1;
}

config.Sandwich = {
    DisplayName = "Sandwich";
    Setup = FoodHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.23;
    Weight = 0.04;
}

config.SCAR16S = {
    DisplayName = "SCAR-16S";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.89;
    Weight = 3.29;
}

config.SCARLMag20 = {
    DisplayName = "SCAR-L 20-round magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.17;
    Weight = 0.113;
}

config.ShoulderRadio = {
    DisplayName = "Radio";
    Setup = RadioHandler.NewShoulder;
    Slots = {
        Shoulder = true;
    };

    Length = 0.15;
    Weight = 0.16;
}

config.Skorpion32Mag20 = {
    DisplayName = "Škorpion .32 ACP 20-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.2;
    Weight = 0.083;
}

config.Skorpion61 = {
    DisplayName = "Škorpion vz. 61";
    Setup = FirearmsHandler.new;
    Slots = {
        Front = true;
        Hip = true;
        Shoulder = true;
    };

    Length = 0.27;
    Weight = 1.3;
}

config.SKS = {
    DisplayName = "Zastava M59/66";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Shoulder = true;
    };

    Length = 1.12;
    Weight = 3.85;
}

config.SKSClip10 = {
    DisplayName = "SKS 10-round Clip";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.11;
    Weight = 0.045;
}

config.Slug12Box25 = {
    DisplayName = "12 gauge Slug 25-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.35;
    Weight = 0.1;
}

config.Slug20Box25 = {
    DisplayName = "20 gauge Slug 25-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.35;
    Weight = 0.1;
}

config.Soviet545Box30 = {
    DisplayName = "5.45 x 39mm 30-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.04;
    Weight = 0.1;
}

config.Soviet762Box20 = {
    DisplayName = "7.62 x 39mm 20-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.04;
    Weight = 0.1;
}

config.Soviet762Box1260 = {
    DisplayName = "7.62 x 39mm 1260-round Crate";
    Setup = FirearmsHandler.NewBox;
    Slots = {};

    Length = 0.55;
    Weight = 5.32;
}

config.STANAG30 = {
    DisplayName = "STANAG 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.19;
    Weight = 0.19;
}

config.Sten = {
    DisplayName = "Sten Gun";
    Setup = FirearmsHandler.new;
    Slots = {
        Shoulder = true;
    };

    Length = 0.76;
    Weight = 3.2;
}

config.StenMag32 = {
    DisplayName = "Sten 32-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.4;
    Weight = 0.5;
}

config.SuperRedhawk = {
    DisplayName = "Super Redhawk";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.38;
    Weight = 1.5;
}

config.SuperShorty = {
    DisplayName = "Serbu Super Shorty";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
        Hip = true;
    };

    Length = 0.42;
    Weight = 1.8;
}

config.Talon = {
    DisplayName = "TF Talon";
    Setup = FirearmsHandler.new;
    Slots = {
        Front = true;
        Hip = true;
    };

    Length = 0.3;
    Weight = 1.4;
}

config.TalonMag30 = {
    DisplayName = "TF Talon 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.25;
    Weight = .44;
}

config.Taurus605 = {
    DisplayName = "Taurus 605";
    Setup = FirearmsHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.16;
    Weight = .68;
}

config.TEC9 = {
    DisplayName = "TEC-9";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
        Shoulder = true;
    };

    Length = 0.32;
    Weight = 1.42;
}

config.TEC9Mag32 = {
    DisplayName = "TEC-9 32-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.21;
    Weight = 0.19;
}

config.TF17 = {
    DisplayName = "TF-17";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.2;
    Weight = 0.83;
}

config.TF17Mag17 = {
    DisplayName = "TF-17 17-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.2;
    Weight = 0.09;
}

config.Thompson = {
    DisplayName = "M1928A1 Thompson";
    Setup = FirearmsHandler.new;
    Slots = {
        Front = true;
        Shoulder = true;
    };

    Length = 0.86;
    Weight = 4.9;
}

config.ThompsonMag30 = {
    DisplayName = "Thompson 30-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.25;
    Weight = 1.5;
}

config.Tokarev762Box50 = {
    DisplayName = "7.62x25mm Tokarev 50-round Box";
    Setup = FirearmsHandler.NewBox;
    Slots = {
        Pocket = true;
    };

    Length = 0.13;
    Weight = 0.1;
}

config.TT33 = {
    DisplayName = "TT-33";
    Setup = FirearmsHandler.new;
    Slots = {
        Hip = true;
    };

    Length = 0.19;
    Weight = 0.85;
}

config.TTMag8 = {
    DisplayName = "TT 8-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.18;
    Weight = 0.91;
}

config.UZI = {
    DisplayName = "UZI";
    Setup = FirearmsHandler.new;
    Slots = {
        Front = true;
        Shoulder = true;
    };

    Length = 0.47;
    Weight = 3.5;
}

config.UZIMag32 = {
    DisplayName = "UZI 32-round Magazine";
    Setup = FirearmsHandler.NewFeed;
    Slots = {
        Pocket = true;
    };

    Length = 0.2;
    Weight = 0.24;
}

config.Wallet = {
    DontDrop = true;
    Setup = MoneyHandler.WalletHandler.new;
    Slots = {
        Pocket = true;
    };

    Length = 0.11;
    Weight = 0.06;
}

config.WasherTank = {
    DisplayName = "Power Washer Tank";
    Setup = SanitationHandler.NewTank;
    Slots = {
        Back = true;
    };

    Length = 0.49;
    Weight = 4.7;
}

config.ZPAPM70 = {
    DisplayName = "Zastava M70 ZPAP";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
    };

    Length = 0.89;
    Weight = 3.7;
}

config.ZPAPM70UF = {
    DisplayName = "Zastava M70 ZPAP UF";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
    };

    Length = 0.67;
    Weight = 3.58;
}

config.ZPAPM85 = {
    DisplayName = "Zastava M85 ZPAP";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
        Shoulder = true;
    };

    Length = 0.54;
    Weight = 3.5;
}

config.ZPAPM92 = {
    DisplayName = "Zastava M92 ZPAP";
    Setup = FirearmsHandler.new;
    Slots = {
        Back = true;
        Front = true;
        Shoulder = true;
    };

    Length = 0.55;
    Weight = 3.57;
}

for item, itemData in pairs(config) do
    itemData.Name = item
end

FoodHandler.ICPass(config)
return config