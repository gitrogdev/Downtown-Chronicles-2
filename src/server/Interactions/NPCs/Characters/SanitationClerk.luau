---Configuration for the clerk for the sanitation office
local config = {}

config.Name = "Rowan Hannigan"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to North Bloxford Municipal Sanitation and Waste Services. \z
        How can we help you today?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "What are the requirements for a sanitation worker?";
                ShowIf = "NotSanitation";
                Then = "JobRequirements";
            };
            {
                Text = "I'd like to apply for a job as a sanitation worker.";
                ShowIf = "CanJoinSanitation";
                Then = "SeekWork";
            };
            {
                Text = "I want to resign from my position here.";
                ShowIf = "OffdutySanitation";
                Then = "QuitRequest";
            };
        };
    };
}

config.JobRequirements = {
    Text = {
        "If you'd like to join the sanitation services, we are currently \z
        hiring power washers. You'll need to be a citizen of the State of \z
        North Bloxell, with a clean criminal record.";
    };
    Then = config.Initial.Then;
}

config.SeekWork = {
    Text = {
        "Sure, we're currently hiring street cleaners for the sanitation \z
        services. Your job is to go around the city, and to power wash any \z
        messes, including blood, mold, and other spills.";
        "You'll be issued a power washer and a uniform, but keep in mind \z
        that these are state property, and must be returned at the end of \z
        your shift, or the lost equipment will be reported to the Ministry of \z
        Internal Affairs.";
        "So, if you're ready to start working, just hand over your bank \z
        details and your ID, and we'll get you signed up.";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[ACCEPT] *Hand over your ID*";
                ShowIf = "PBNBAccount";
                Then = "GaveInformation";
            };
            {
                Text = "[ACCEPT] *Hand over your ID*";
                ShowIf = "NoPBNBAccount";
                Then = "NoBank";
            };
            {
                Text = "[DECLINE] Maybe another time.";
                Then = "RefusedInformation";
            };
        };
    };
}

config.GaveInformation = {
    Text = {
        "Looks good. Let me just do the paperwork..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "TakeJob";
        Arguments = {
            "Sanitation";
        };
        Then = {
            NoBank = "NoBank";
            ["true"] = "GotJob";
            ["nil"] = "ServerError";
        };
    };
}

config.GotJob = {
    Text = {
        "Congratulations, you've got the job. Head upstairs to grab your \z
        uniform and your equipment whenever you're ready to start working. \z
        You can refill the tank at the filling station in the parking lot."
    };
    Then = config.Initial.Then;
}

config.NoBank = {
    Text = {
        "In order to work, you'll need a bank account. You can go and open \z
        one at the People's Bank of North Bloxell, over on Božidar Nikolić St."
    };
    Then = config.Initial.Then;
}

config.RefusedInformation = {
    Text = {
        "Well, let us know if you change your mind.";
    };
    Then = config.Initial.Then;
}

config.QuitRequest = {
    Text = {
        "Tired of cleaning up gore? Can't say it comes as a huge surprise.";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "Yes, I'm sure.";
                Then = "QuitJob";
            };
            {
                Text = "Actually, I changed my mind.";
                Then = "DidntQuit";
            };
        };
    };
}

config.QuitJob = {
    Text = {
        "Sorry to hear it. Make sure you've turned all your equipment back \z
        in, and I'll get that paperwork done now..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "QuitJob";
        Then = {
            ["true"] = "QuitSuccess";
            ["nil"] = "ServerError";
        };
    };
}

config.QuitSuccess = {
    Text = {
        "Well, so long, then. If you ever want to work here again, we'll keep \z
        your information on file."
    };
    Then = config.Initial.Then;
}

config.DidntQuit = {
    Text = {
        "Glad to hear you'll be staying."
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Hm. Something isn't quite working. Come back later.";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Have a nice day.";
    };
    Then = {
        Type = "End";
    };
}

return config