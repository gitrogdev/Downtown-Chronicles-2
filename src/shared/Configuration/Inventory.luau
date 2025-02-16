--This script handles all configuration related to the inventory
local config = {}

config.DontSave = {
    "InAction";
    "Reloading";
    "Spraying";
}

config.DrawTime = {
    Back = 1.5;
    Front = 0.5;
    LeftHip = 0.75;
    LeftShoulder = 0.75;
    PocketBL = 1.25;
    PocketBR = 1;
    PocketFL = 1;
    PocketFR = 0.75;
    RightHip = 0.5;
    RightShoulder = 0.5;
}

config.IgnoreNLR = {
    ["Bloxell Intelligence Organization"] = true;
    ["Bloxford Police Department"] = true;
    ["Ministry of Internal Affairs"] = true;
}

config.InvalidSlots = {
    Equipped = true;
}

config.SlotInfo = {
    Back = {
        Type = "Back";
        AttachesTo = "BodyBackAttachment";
    };
    Front = {
        Type = "Front";
        AttachesTo = "BodyFrontAttachment";
    };
    LeftHip = {
        Type = "Hip";
        AttachesTo = "WaistCenterAttachment";
    };
    LeftShoulder = {
        Type = "Shoulder";
        AttachesTo = "LeftCollarAttachment";
    };
    PocketBL = {
        Type = "Pocket";
        AttachesTo = false;
    };
    PocketBR = {
        Type = "Pocket";
        AttachesTo = false;
    };
    PocketFL = {
        Type = "Pocket";
        AttachesTo = false;
    };
    PocketFR = {
        Type = "Pocket";
        AttachesTo = false;
    };
    RightHip = {
        Type = "Hip";
        AttachesTo = "WaistCenterAttachment";
    };
    RightShoulder = {
        Type = "Shoulder";
        AttachesTo = "RightCollarAttachment";
    };
}

config.Slots = {
    "PocketFR"; --1
    "PocketFL"; --2
    "PocketBR"; --3
    "PocketBL"; --4
    "Front"; --5
    "RightHip"; --6
    "LeftHip"; --7
    "RightShoulder"; --8
    "LeftShoulder"; --9
    "Back"; --10 (0)
}

config.SlotNumbers = {}
for i, slot in ipairs(config.Slots) do
    config.SlotNumbers[slot] = i
end

config.StarterPack = {
    "Wallet";
}

return config