---Configuration for the locksmith NPC in North Bloxell
local config = {}

config.Name = "Brava Smith"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to Brava's Locks & Keys! How can I help you today?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[POLICE] I need the keys for the property associated \z
                    with this search warrant.";
                ShowIf = "HasSearchWarrant";
                Then = "SearchWarrant";
            };
            {
                Text = "I'd like to duplicate a key.";
                ShowIf = "NorthHomeowner";
                Then = "DupeKey";
            };
            {
                Text = "I'd like to change my locks.";
                ShowIf = "NorthHomeowner";
                Then = "ChangeLocks";
            };
            {
                Text = "What services do you offer?";
                Then = "AccountActions"
            };
        };
    };
}

config.AccountActions = {
    Text = {
        "Here at Brava's Locks & Keys, we provide the best quality locks and \z
        keys in North Bloxell. We offer key duplication and lock replacement.";
        "Key duplication allows you to duplicate the key to your apartment, \z
        in order to provide it to a friend. Due to local regulations, the \z
        recipient of the duplicate key must be present in the store in order \z
        to be properly registered with the local authorities.";
        "Lock replacement allows you to change the locks to your apartment, \z
        rendering all keys useless. This is useful for when you gave a \z
        duplicate key to someone who you no longer want to have access to \z
        your apartment.";
        "In accordance with local regulation, we can not provide duplicate \z
        keys for one person. Each duplicate key must be registered with a \z
        different person, each of which must be registered here. Upon \z
        replacement of the lock, we provide you with a new key, and remove \z
        other key holders from the Ministry of Housing's registry.";
        "For our services, we charge ₲5,000 for key duplication, and ₲10,000 \z
        for lock replacement.";
    };
    Then = config.Initial.Then;
}

config.ChangeLocks = {
    Text = {
        "Sure thing! Lock replacement costs ₲10,000. What kind of lock would \z
        you like to replace?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[₲10,000] I'd like to change the locks for a \z
                    residential property.";
                ShowIf = "NorthHomeowner";
                Then = "ReplaceHomeLock";
            };
            {
                Text = "[₲10,000] I'd like to change the locks for a storage \z
                    unit.";
                ShowIf = "NorthHomeowner";
                Then = "ReplaceStorageLock";
            };
            {
                Text = "Actually, I don't need to replace my locks right now.";
                Then = "ChangeTopic"
            };
        };
    };
}

config.DupeKey = {
    Text = {
        "Sure thing! Key duplication costs ₲5,000. What kind of key would you \z
        like to duplicate?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[₲5,000] I'd like to duplicate the key for a \z
                    residential property.";
                ShowIf = "NorthHomeowner";
                Then = "DupeHomeKey";
            };
            {
                Text = "[₲5,000] I'd like to duplicate the key for a storage \z
                    unit.";
                ShowIf = "NorthHomeowner";
                Then = "DupeStorageKey";
            };
            {
                Text = "Actually, I don't need to duplicate my keys right now.";
                Then = "ChangeTopic"
            };
        };
    };
}

config.DupeHomeKey = {
    Text = {
        "Great, let me hand you the forms, and I'll get that right away!";
    };
    Then = {
        Type = "PassOff";
        Function = "DuplicateKey";
        Arguments = {
            "Home";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "DupedKey";
            ["nil"] = "ServerError";
        };
    };
}

config.DupeStorageKey = {
    Text = {
        "Great, let me hand you the forms, and I'll get that right away!";
    };
    Then = {
        Type = "PassOff";
        Function = "DuplicateKey";
        Arguments = {
            "Storage";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "DupedKey";
            ["nil"] = "ServerError";
        };
    };
}

config.ReplaceHomeLock = {
    Text = {
        "Sure thing, let's just process the payment..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "ChangeLock";
        Arguments = {
            "Home";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "ChangedLock";
            ["nil"] = "ServerError";
        };
    };
}

config.ReplaceStorageLock = {
    Text = {
        "Sure thing, let's just process the payment..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "ChangeLock";
        Arguments = {
            "Storage";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "ChangedLock";
            ["nil"] = "ServerError";
        };
    };
}

config.SearchWarrant = {
    Text = {
        "You've got a warrant, huh? Yeah, I can get you the keys, but you're \z
        going to have to show me the warrant...";
    };
    Then = {
        Type = "Invoke";
        Function = "GetKeysFromWarrant";
        Arguments = {};
        Then = {
            Invalid = "InvalidWarrant";
            ["true"] = "GotKeysFromWarrant";
            ["nil"] = "ServerError";
        };
    };
}

config.ChangeTopic = {
    Then = config.Initial.Then;
}

config.ChangedLock = {
    Text = {
        "Alright, we'll send someone out to change those locks for you, and \z
        we've updated the registry!";
    };
    Then = config.Initial.Then;
}

config.DupedKey = {
    Text = {
        "Alright, I've gone and duplicated your key, and updated the registry!";
    };
    Then = config.Initial.Then;
}

config.GotKeysFromWarrant = {
    Text = {
        "Here are the keys, officer. This one's for the door, and this one's \z
        for their storage. They'll be good until they change their locks.";
    };
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "It doesn't seem like you have enough money for that!";
    };
    Then = config.Initial.Then;
}

config.InvalidWarrant = {
    Text = {
        "That doesn't look like a real warrant. Come back with a better one.";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Hm, something doesn't seem to be working right. Come back later.";
    };
    Then = config.Initial.Then;
}


config.Goodbye = {
    Text = {
        "Thank you for visiting! Remember to lock your doors in this city, \z
        and when you lock them, lock with the best!";
    };
    Then = {
        Type = "End";
    };
}

return config