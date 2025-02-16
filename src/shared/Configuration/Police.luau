--All configuration relating to law enforcement
local config = {}

config.OfficerTitles = {
    Patrol = "Officer";
    Investigative = "Detective";
    Tax = "Agent";
}

config.PayRates = {
    50; --Cadet
    75; --Officer
    80; --Sergeant
    90; --Lieutenant
    100; --Captain
    125; --Colonel General
    150; --Deputy Minister of Internal Affairs
    240; --Minister of Internal Affairs
    300; --President
}

config.Ranks = {
    "Cadet"; --1
    "Officer"; --2
    "Sergeant"; --3
    "Lieutenant"; --4
    "Captain"; --5
    "Colonel General"; --6
    "Deputy Minister of Internal Affairs"; --7
    "Minister of Internal Affairs"; --8
    "President"; --9
}

config.Uniforms = {
    {
        Shirt = "MIACadet";
        Pants = "MIABottom";
        Accessories = {
            "PoliceVest";
            "PoliceBalaclava";
        };
    };
    {
        Shirt = "MIAOfficer";
        Pants = "MIABottom";
        Accessories = {
            "PoliceVest";
            "PoliceBalaclava";
        };
    };
    {
        Shirt = "MIASgt";
        Pants = "MIABottom";
        Accessories = {
            "PoliceVest";
            "PoliceBalaclava";
        };
    };
    {
        Shirt = "MIALt";
        Pants = "MIABottom";
        Accessories = {
            "PoliceVest";
            "PoliceBalaclava";
        };
    };
    {
        Shirt = "MIACaptain";
        Pants = "MIABottom";
        Accessories = {
            "PoliceVest";
        };
    };
    {
        Shirt = "MIAColonel";
        Pants = "MIABottom";
        Accessories = {
            "PoliceVest";
        };
    };
    {
        Shirt = "MIADGeneral";
        Pants = "MIABottom";
        Accessories = {
            "PoliceVest";
        };
    };
    {
        Shirt = "MIAGeneral";
        Pants = "MIABottom";
        Accessories = {
            "PoliceVest";
        };
    };
    {
        Shirt = "PresidentTop";
        Pants = "PresidentBottom";
    };
}

return config