---Configuration for the recruiter NPC for the North Bloxell National Guard
local config = {}

config.Name = "Darko Horvat"
config.Range = 10

config.Initial = {
    Text = {
        "Hello there, are you interested in joining our national guard?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[NORTHERN CITIZEN] I'd like to enlist in the National \z
                    Guard.";
                ShowIf = "CanJoinNG";
                Then = "SeekWork";
            };
            {
                Text = "What are the requirements to join the National Guard?";
                Then = "JobRequirements";
            };
            {
                Text = "What are the responsibilities of the National Guard?";
                Then = "JobResponsibilities";
            };
        };
    };
}

config.JobRequirements = {
    Text = {
        "To join the National Guard, you must be a citizen of the State of \z
        North Bloxell in good standing with the law.";
        "If you'd like to join, be sure to quit any other jobs first, as \z
        this is a full time job.";
    };
    Then = config.Initial.Then;
}

config.JobResponsibilities = {
    Text = {
        "It's a simple job really, most of the time you just have to be \z
        available. Just go about your business in the city in uniform, and we \z
        pay you for being on standby.";
        "You're not a cop, so you don't have the authority to make arrests, \z
        but you should still use the influence the uniform exudes to keep \z
        our city safe.";
        "As mentioned though, you will need to be ready. If we call you, you \z
        go to the armory, grab a weapon, and be ready for assignments. If \z
        you're a guardsman, you can and should be expect to be called up at \z
        any time, there's no avoiding service if you take this job.";
    };
    Then = config.Initial.Then;
}

config.SeekWork = {
    Text = {
        "Sure, we're currently hiring guardsmen. It's a simple job really, \z
        most of the time you just have to be available. Just go about your \z
        business in the city in uniform, and we pay you for being on standby.";
        "You're not a cop, so you don't have the authority to make arrests, \z
        but you should still use the influence the uniform exudes to keep \z
        our city safe.";
        "As mentioned though, you will need to be ready. If we call you, you \z
        go to the armory, grab a weapon, and be ready for assignments. If \z
        you're a guardsman, you can and should be expect to be called up at \z
        any time, there's no avoiding service if you take this job.";
        "So, if you're interested, just hand over your documents and I can \z
        get you signed up right here today! Just know that we don't permit \z
        deserting, you'll need an officer to discharge you if you want to \z
        quit!";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[ACCEPT] *Hand over your documents*";
                ShowIf = "PBNBAccount";
                Then = "GaveInformation";
            };
            {
                Text = "[ACCEPT] *Hand over your documents*";
                ShowIf = "NoPBNBAccount";
                Then = "NoBank";
            };
            {
                Text = "[DECLINE] I think I forgot my documents... I'll come \z
                    back later.";
                Then = "RefusedInformation";
            };
        };
    };
}

config.GaveInformation = {
    Text = {
        "Roger that. Let me just put that in our system..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "TakeJob";
        Arguments = {
            "Guardsman";
        };
        Then = {
            Discharged = "Discharged";
            Emergency = "Emergency";
            Felon = "Felon";
            NoBank = "NoBank";
            NotCitizen = "NotCitizen";
            Underage = "Underage";
            ["true"] = "GotJob";
            ["nil"] = "ServerError";
        };
    };
}

config.Discharged = {
    Text = {
        "Due to your previous discharge from the National Guard, I'm unable \z
        to recruit you. You should talk to an officer if you have a serious \z
        intention to rejoin."
    };
    Then = config.Initial.Then;
}

config.Emergency = {
    Text = {
        "Due to the active state of emergency, we're unable to process your \z
        request to join right now. We advise you head home, the situation \z
        outside is dangerous for civilians."
    };
    Then = config.Initial.Then;
}

config.Felon = {
    Text = {
        "Due to your criminal record, I'm unable to recruit you."
    };
    Then = config.Initial.Then;
}

config.GotJob = {
    Text = {
        "Welcome to the National Guard! Head to the staff room, grab a \z
        uniform, and be ready for further orders!"
    };
    Then = config.Initial.Then;
}

config.NoBank = {
    Text = {
        "You seriously don't have a bank account?";
        "In order for us to pay you, you'll need to open a bank account. \z
        Head down the road to the People's Bank of North Bloxell, and go and \z
        open an account, then come back."
    };
    Then = config.Initial.Then;
}

config.NotCitizen = {
    Text = {
        "I'm only able to recruit citizens of the State of North Bloxell. If \z
        you'd like to apply for citizenship, you can do so at any police \z
        station."
    };
    Then = config.Initial.Then;
}

config.RefusedInformation = {
    Text = {
        "We're always looking for soldiers, if you change your mind later.";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Something isn't quite working with our server, must be the South... \z
        Come back later.";
    };
    Then = config.Initial.Then;
}

config.Underage = {
    Text = {
        "Since you're a minor, we're unable to recruit you until you turn \z
        seventeen. But we appreciate the youth's interest in patriotism and \z
        the defense of our country, and we hope to see you in our ranks in a \z
        few years!"
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "You have a nice day. Mama le Valake!";
    };
    Then = {
        Type = "End";
    };
}

return config