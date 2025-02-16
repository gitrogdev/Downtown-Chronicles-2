--Configuration related to trash interactions
local config = {}

config.BottlePayout = 5

config.Recyclable = {
    ColaBottle = true;
    CreamBottle = true;
    KaliBottle = true;
    KvasBottle = true;
    PacattiBottle = true;
}

config.RVMDefaultText = "Protect our island, recycle your bottles!"
config.RVMInteractText = `Insert a bottle into the machine, and you will be \z
    paid ₲{config.BottlePayout} for each recycled bottle!`
config.TimeoutText = "Session concluded. Let's keep keeping our island clean!"
config.UnknownText = "This item can not be recycled with this machine."

return config