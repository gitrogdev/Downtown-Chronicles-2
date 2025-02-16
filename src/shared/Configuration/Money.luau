--This script handles all configuration related to money
local config = {}

config.Bills = {
    [1] = {
        Front = 16363801015;
        Back = 16363816549;
    };
    [5] = {
        Front = 16363816192;
        Back = 16363816367;
    };
    [10] = {
        Front = 16363815805;
        Back = 16363815961;
    };
    [25] = {
        Front = 16363815446;
        Back = 16363815637;
    };
    [100] = {
        Front = 16363815011;
        Back = 16363815263
    };
    [500] = {
        Front = 16363814554;
        Back = 16363814798;
    };
    [1000] = {
        Front = 16363813979;
        Back = 16363814447;
    };
    [10000] = {
        Front = 16363816691;
        Back = 16363813765;
    };
}

config.BillSides = {
    Front = 16363880074;
    Back = 16363903945;
    Left = 16363901595;
    Right = 16363879817;
}

config.Denominations = {
    10000;
    1000;
    500;
    100;
    25;
    10;
    5;
    1;
}

return config