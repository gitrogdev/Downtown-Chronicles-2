---Configuration for the receptionist NPC at the Ministry of Internal Affairs
local config = {}

config.Name = "Koloate Fatline"
config.Range = 10

config.Initial = {
    Text = {
        "Welcome to the the North Bloxford Police Station. How can I help you?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[CADET] I'd like to accept an offer to join the \z
                    Ministry of Internal Affairs.";
                ShowIf = "PoliceOffer";
                Then = "ExtendOffer";
            };
            {
                Text = "*Ask questions about citizenship*";
                Then = "CitizenshipQuestions";
            };
            {
                Text = "*Ask questions about firearms licensing*";
                Then = "LicenseQuestions";
            };
            {
                Text = "*Ask questions about police work*";
                ShowIf = "NotMIA";
                Then = "JobQuestions";
            };
        };
    };
}

config.CitizenshipQuestions = {
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[TOURIST] I'd like to apply for citizenship.";
                ShowIf = "Tourist";
                Then = "CitizenshipApplication";
            };
            {
                Text = "What are the benefits of citizenship in North Bloxell?";
                Then = "CitizenshipBenefits";
            };
            {
                Text = "What are the requirements to obtain citizenship?";
                Then = "CitizenshipRequirements";
            };
            {
                Text = "*Change the topic*";
                Then = "ChangeTopic";
            };
        };
    };
}

config.CitizenshipBenefits = {
    Text = {
        "What are the benefits of becoming a citizen of our glorious State of \z
        North Bloxell? Well, there are lots.";
        "For one, this would be your country now. Your home. You'd no longer \z
        be a tourist or an immigrant, but truly one of us, striving towards \z
        our goal of national greatness.";
        "Secondly, you'd have all the rights we offer to citizens. Some of \z
        the big ones are the right to own property, the right to residence, \z
        the right to vote, the right to serve in our military and police \z
        forces...";
        "And there's also other privileges. You can apply for a firearms \z
        license, many higher-end jobs around the city are only interested \z
        in hiring citizens, while other jobs pay more to citizens than \z
        they do foreigners.";
        "And that's basically it then. Anything else?";
    };
    Then = config.CitizenshipQuestions.Then;
}

config.CitizenshipRequirements = {
    Text = {
        "Being a newly formed state, our requirements for citizenship are \z
        actually fairly loose.";
        "You must have a clean criminal record. That is, felons, whether \z
        arrested in South or North Bloxell, will not be permitted \z
        citizenship.";
        "Dual citizenship with South Bloxell is not permitted. That is, if \z
        you hold citizenship in the Republic of Bloxell, you will not be \z
        allowed to receive citizenship here.";
        "And there's a fee for the process of receiving citizenship. That \z
        amounts to ₲10,000, payable with cash here.";
        "And that's basically it then. Anything else?";
    };
    Then = config.CitizenshipQuestions.Then;
}

config.CitizenshipApplication = {
    Text = {
        "Great. In order to apply for citizenship, we'll need to take your \z
        fingerprints, run a background check on you, and you'll need to pay \z
        the processing fees in the amount of ₲10,000, cash payment. If you \z
        don't have cash, there are two ATMs just behind you.";
        "Do you wish to proceed?";
    };
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "[₲10,000] Yes, I wish to proceed.";
                Then = "CitizenshipApply";
            };
            {
                Text = "[DECLINE] Not at this time.";
                Then = "CitizenshipRefuse";
            };
        };
    };
}

config.CitizenshipApply = {
    Text = {
        "Alright then, just hand over the processing fee, and put your \z
        fingerprints on the scanner here..."
    };
    Delay = 3;
    Then = {
        Type = "Invoke";
        Function = "ApplyCitizenship";
        Arguments = {
            "North";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            ["true"] = "GotCitizenship";
            ["nil"] = "ServerError";
        };
    };
}

config.GotCitizenship = {
    Text = {
        "Congratulations! You're now a citizen of the State of North Bloxell! \z
        You will receive your ID card shortly. Is there anything else I can \z
        help you with?";
    };
    Then = config.Initial.Then;
}

config.CitizenshipRefuse = {
    Text = {
        "Alright then. If you change your mind, we'll be here. Is there \z
        anything else I can help you with?";
    };
    Then = config.Initial.Then;
}

config.LicenseQuestions = {
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "I'd like to see the results of my license application.";
                ShowIf = "NorthWeaponsResults";
                Then = "LicenseResults";
            };
            {
                Text = "*Apply for a firearms license*";
                ShowIf = "CanApplyNorthLicense";
                Then = "LicenseApply";
            };
            {
                Text = "What types of firearms licenses are available?";
                Then = "LicenseTypes";
            };
            {
                Text = "What are the requirements for a firearms license?";
                Then = "LicenseRequirements";
            };
            {
                Text = "*Change the topic*";
                Then = "ChangeTopic";
            };
        };
    };
}

config.LicenseTypes = {
    Text = {
        "We currently offer three types of firearms licenses. The Home \z
        Defense Permit, the License to Carry, and the Machine Gun Permit.";
        "The Home Defense Permit allows the purchase of long guns, namely \z
        shotguns and rifles, for the purpose of home defense. Holders of a \z
        Home Defense Permit are not permitted to carry such weapons outside \z
        of their place of residence.";
        "The License to Carry allows the purchase of handguns, and enables \z
        the right to carry firearms in public. This applies to both open \z
        carry and concealed carry. Carrying any type of firearm in public, \z
        be it open or concealed, without a License to Carry is forbidden.";
        "And finally, the Machine Gun Permit. Very few obtain this license, \z
        but it allows the purchase of automatic weapons of all calibers and \z
        types.";
        "And that's basically it then. Anything else?";
    };
    Then = config.LicenseQuestions.Then;
}

config.LicenseRequirements = {
    Text = {
        "For all licenses, citizenship in the State of North Bloxell is \z
        required. We remind you that citizens of the Republic of Bloxell are \z
        not permitted to purchase or possess firearms in the State of North \z
        Bloxell, even with a valid South Bloxellian license.";
        "Convicted felons are also not permitted to apply for firearms \z
        licenses of any type.";
        "For a Home Defense Permit, proof of residency is required. That is, \z
        you must own a home. An application must also be filled out, with an \z
        attached fee of ₲5,000.";
        "For a License to Carry, any citizen of the State of North Bloxell \z
        can apply. An application must be filled out, with an attached fee of \z
        ₲10,000.";
        "For a Machine Gun Permit, one must receive a certificate of good \z
        citizenship from the Office of the President. These are awarded to \z
        long-standing citizens who maintain a clean criminal record.";
        "Once such a certificate is received, one may fill out an \z
        application, with an attached fee of ₲25,000.";
        "And that's basically it then. Anything else?";
    };
    Then = config.LicenseQuestions.Then;
}

config.LicenseApply = {
    Then = {
        Type = "Options";
        Options = {
            {
                Text = "I'd like to apply for a Home Defense Permit.";
                ShowIf = "CanApplyNorthHDP";
                Then = "ApplyHDP";
            };
            {
                Text = "I'd like to apply for a License to Carry.";
                ShowIf = "CanApplyNorthLTC";
                Then = "ApplyLTC";
            };
            {
                Text = "I'd like to apply for a Machine Gun Permit.";
                ShowIf = "CanApplyNorthMGP";
                Then = "ApplyMGP";
            };
            {
                Text = "*Change the topic*";
                Then = "ChangeTopic";
            };
        };
    };
}

config.LicenseResults = {
    Text = {
        "Sure thing, if you give me your ID, I can go ahead and check if \z
        we've gotten any updates on your application...";
    };
    Delay = 3;
    Then = {
        Type = "Respond";
        Response = "LicenseResults";
        Options = config.LicenseQuestions.Then;
    };
}

config.ApplyLTC = {
    Text = {
        "Alright then, here's the form. Hand it back to me once you've filled \z
        it out. A reminder that you'll need to include a cash payment of \z
        ₲10,000 with your application."
    };
    Delay = 3;
    Then = {
        Type = "PassOff";
        Function = "ApplyLicense";
        Arguments = {
            "LTC";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            NoContent = "NoContentApp";
            ["true"] = "SubmittedLTC";
            ["nil"] = "ServerError";
        };
    };
}

config.SubmittedLTC = {
    Text = {
        "Alright, I've submitted your application for a License to Carry. You \z
        should hear back from us with a response within 24-48 hours. Check \z
        back here to see if there's been any update.";
    };
    Then = config.LicenseQuestions.Then;
}

config.ApplyHDP = {
    Text = {
        "Alright then, here's the form. Hand it back to me once you've filled \z
        it out. A reminder that you'll need to include a cash payment of \z
        ₲5,000 with your application."
    };
    Delay = 3;
    Then = {
        Type = "PassOff";
        Function = "ApplyLicense";
        Arguments = {
            "HDP";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            NoContent = "NoContentApp";
            ["true"] = "SubmittedHDP";
            ["nil"] = "ServerError";
        };
    };
}

config.SubmittedHDP = {
    Text = {
        "Alright, I've submitted your application for a Home Defense Permit. \z
        You should hear back from us with a response within 24-48 hours. \z
        Check back here to see if there's been any update.";
    };
    Then = config.LicenseQuestions.Then;
}

config.ApplyMGP = {
    Text = {
        "Alright then, here's the form. Hand it back to me once you've filled \z
        it out. A reminder that you'll need to include a cash payment of \z
        ₲25,000 with your application."
    };
    Delay = 3;
    Then = {
        Type = "PassOff";
        Function = "ApplyLicense";
        Arguments = {
            "MGP";
        };
        Then = {
            Insufficient = "InsufficentFunds";
            NoContent = "NoContentApp";
            ["true"] = "SubmittedMGP";
            ["nil"] = "ServerError";
        };
    };
}

config.SubmittedMGP = {
    Text = {
        "Alright, I've submitted your application for a Machine Gun Permit. \z
        You should hear back from us with a response within 24-48 hours. \z
        Check back here to see if there's been any update.";
    };
    Then = config.LicenseQuestions.Then;
}

config.NoContentApp = {
    Text = {
        "These applications aren't exactly cheap! If you want me to submit \z
        that, you should probably put something on the form! It's a paragraph \z
        box, fill it up!";
    };
    Then = config.LicenseQuestions.Then;
}

config.JobQuestions = {
    Text = {
        "If you want to join the police department, you'll have to attend a \z
        tryout hosted by the captain of one of our divisions. Those are the \z
        patrol, investigative, and tax divisions.";
        "You must be a citizen of the State of North Bloxell with no criminal \z
        record in order to attend the tryout. A reminder that it is forbidden \z
        to carry any kind of weapon inside the police station, and you must \z
        show up to the tryout dressed in a reasonable matter.";
    };
    Then = config.Initial.Then;
}

config.ExtendOffer = {
    Then = {
        Type = "Respond";
        Response = "PoliceOffer";
        Options = {
            {
                Text = "[ACCEPT] I accept the offer to join the Ministry of \z
                    Internal Affairs.";
                Then = "AcceptOffer";
            };
            {
                Text = "[DECLINE] I'm not interested in joining the Ministry \z
                    of Internal Affairs at this time.";
                Then = "DeclineOffer";
            };
        }
    };
}

config.AcceptOffer = {
    Text = {
        "We're glad to hear you'll be joining our ranks. I'll just process \z
        that now..."
    };
    Then = {
        Type = "Invoke";
        Function = "RespondPoliceOffer";
        Arguments = {
            true;
        };
        Then = {
            ["true"] = "RespondedOffer";
            ["nil"] = "ServerError";
        };
    };
}

config.DeclineOffer = {
    Text = {
        "We're sorry to hear that you won't be joining us at this time. Let \z
        me just record that in our system."
    };
    Then = {
        Type = "Invoke";
        Function = "RespondPoliceOffer";
        Arguments = {
            false;
        };
        Then = {
            ["true"] = "RespondedOffer";
            ["nil"] = "ServerError";
        };
    };
}

config.RespondedOffer = {
    Text = {
        "Well, that's all taken care of. Is there anything else I can help \z
        you with?"
    };
    Then = config.Initial.Then;
}

config.ChangeTopic = {
    Then = config.Initial.Then;
}

config.InsufficentFunds = {
    Text = {
        "That's not enough money, sorry. There are two ATMs just behind you, \z
        if you need to take out more cash.";
    };
    Then = config.Initial.Then;
}

config.ServerError = {
    Text = {
        "Something went wrong with our servers. Could you come back later?";
    };
    Then = config.Initial.Then;
}

config.Goodbye = {
    Text = {
        "Take care. You behave out there.";
    };
    Then = {
        Type = "End";
    };
}

return config