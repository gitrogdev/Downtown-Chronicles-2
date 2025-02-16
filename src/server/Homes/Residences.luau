--Contains configuration for different residence types
local config = {}

--[[
    The general order for rental pictures is:
    Exterior
    Living space
    Bedroom
    Bathroom
]]--

config["242GaryRd"] = {
    Address = "242 Gary Road, North Bloxford, North Bloxell";
    AddressShort = "242 Gary Road";
    Description = "Small, quaint apartments in Northern Bloxford. Located \z
        near the Police Station, Laki Club and the Red Stag, these apartments \z
        are great for working individuals.";
    Name = "Gary Road Apartments";
    Pictures = {
        "rbxassetid://17178824073";
        "rbxassetid://17178833815";
        "rbxassetid://17178835578";
        "rbxassetid://17178839493";
    };
    Price = 50000;
    Size = "Studio";
    State = "North";
    StorageType = "GaryHome";
    Type = "Apartment";
}

config["325BNikolicSt"] = {
    Address = "325 Božidar Nikolić Street, North Bloxford, North Bloxell";
    AddressShort = "325 Božidar Nikolić Street";
    Description = "Small, duplex apartments in the center of North Bloxford. \z
        Adjacent to the bank, and within the Božidar Nikolić Commercial \z
        District, these apartments allow easy access to most of the city, \z
        with the police station just a few buildings away for ensured safety.";
    Name = "Božidar Nikolić Street Duplex";
    Pictures = {
        "rbxassetid://18669996885";
        "rbxassetid://18669997864";
        "rbxassetid://18669997354";
        "rbxassetid://18669998188";
    };
    Price = 75000;
    Size = "Studio";
    State = "North";
    StorageType = "DuplexStudio";
    Type = "Apartment";
}

config["336BNikolicSt"] = {
    Address = "336 Božidar Nikolić Street, North Bloxford, North Bloxell";
    AddressShort = "336 Božidar Nikolić Street";
    Description = "One-bedroom apartment building on Božidar Nikolić Street \z
        with a view of North Bloxford's famous Memorial Park. Central \z
        location, next door to the highly rated Bakery North and across the \z
        street from the police station, for guaranteed security.";
    Name = "Memorial Park Apartments";
    Pictures = {
        "rbxassetid://18802239863";
        "rbxassetid://18802238589";
        "rbxassetid://18802239121";
        "rbxassetid://18802239394";
    };
    Price = 75000;
    Size = "1 Bedroom";
    State = "North";
    StorageType = "OneBedroom";
    Type = "Apartment";
}

config["409KremenchukAve"] = {
    Address = "409 Kremenchuk Avenue, North Bloxford, North Bloxell";
    AddressShort = "409 Kremenchuk Avenue";
    Description = "Housing project in Northern Bloxford, located right on the \z
        Carver River. Vibrant neighborhood, affordable prices, a great option \z
        for working individuals.";
    Name = "Kremenchutskyy Projects";
    Pictures = {
        "rbxassetid://17188068781";
        "rbxassetid://17188059194";
        "rbxassetid://17188071565";
        "rbxassetid://17188065028";
    };
    Price = 30000;
    Size = "Studio";
    State = "North";
    StorageType = "KremenchukHome";
    Type = "Apartment";
}

config["410KremenchukAve"] = {
    Address = "410 Kremenchuk Avenue, North Bloxford, North Bloxell";
    AddressShort = "410 Kremenchuk Avenue";
    Description = "Housing project in Northern Bloxford, located right on the \z
        Carver River. Vibrant neighborhood, affordable prices, a great option \z
        for working individuals.";
    Name = "Kremenchutskyy Projects";
    Pictures = {
        "rbxassetid://17188048224";
        "rbxassetid://17188059194";
        "rbxassetid://17188063021";
        "rbxassetid://17188065028";
    };
    Price = 30000;
    Size = "Studio";
    State = "North";
    StorageType = "KremenchukHome";
    Type = "Apartment";
}

config["526BlockSt"] = {
    Address = "526 Block Street, North Bloxford, North Bloxell";
    AddressShort = "526 Block Street";
    Description = "Luxury apartment in the financial district of North \z
        Bloxford. Safe, spacious, and with easy access to most of the city, \z
        these apartments are perfect for the more affluent citizens of \z
        North Bloxford.";
    Name = "Block Street Apartments";
    Pictures = {
        "rbxassetid://70972854234994";
        "rbxassetid://124325525406196";
        "rbxassetid://132542969341392";
        "rbxassetid://109103220345551";
    };
    Price = 125000;
    Size = "1 Bedroom";
    State = "North";
    StorageType = "LuxuryHome";
    Type = "Apartment";
}

return config