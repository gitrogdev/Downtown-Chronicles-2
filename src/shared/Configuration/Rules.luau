--This script contains all the rules for the game
local config = {}

config.Rules = {
    {
        Name = "Metagaming";
        Roman = "I";
        Simple = "Do not use out of character information in character.";
        Description = "You may not use information from out of character \z
            (OOC) sources within roleplay in character (IC), or other \z
            information that your character would not have access to. This \z
            can be using information from an OOC chat, using information \z
            obtained on another character, or using knowledge that would not \z
            be reasonable for your character to possess.";
        Punishment = 1;
    };
    {
        Name = "Powergaming";
        Roman = "II";
        Simple = "Do not roleplay things beyond the abilities of your \z
            character.";
        Description = "Powergaming is roleplaying beyond your character's \z
            abilities. This can either be roleplaying out impossible actions \z
            (superpowers, etc.) or forcing roleplay onto another player \z
            without giving them any chance to react (/me breaks his neck, \z
            instantly killing him)";
        Punishment = 1;
    };
    {
        Name = "New Life Rule";
        Roman = "III";
        Simple = "When you die, you forget what happened.";
        Description = "Whenever your character dies, your character does not \z
            remember the situation leading up to their death. This means that \z
            you can not avenge your death, report your death to the police, \z
            talk about your death or the situation that led up to it with \z
            other players, or return to the location of your death. In order \z
            to maintain the New Life Rule (NLR), we forbid players from \z
            returning to the location of their death, or initiating any \z
            interaction with their killer for 15 minutes.";
        Punishment = 1;
    };
    {
        Name = "Explicit Roleplay";
        Roman = "IV";
        Simple = "No roleplay of a type that is inappropriate for Roblox.";
        Description = "Roblox is a game intended for children. Therefore, we \z
            ask you not to act out any roleplay which would not be \z
            appropriate for children. This includes any kind of sexual \z
            roleplay, without exceptions. Roleplay such involving any kind of \z
            mutilation or other disturbing but non-sexual roleplay can only \z
            be carried out with the OOC permission of all involved parties.";
        Punishment = 5;
    };
    {
        Name = "Leaving to Avoid";
        Roman = "V";
        Simple = "Don't leave the game or reset to avoid roleplay.";
        Description = "It is not permitted to leave the game during any kind \z
            of roleplay situation. This also includes leaving while being \z
            arrested, leaving while in combat, or leaving while being \z
            chased/hunted. Additionally, AFK or unresponsive players will be \z
            treated as if their character is standing unresponsive, and are \z
            not exempt to any kind of roleplay situations unfolding.";
        Punishment = 3;
    };
    {
        Name = "Self-Preservation";
        Roman = "VI";
        Simple = "Roleplay as a character who values their own life and limb.";
        Description = "You must roleplay in a way that your character would \z
            act as a human being in order to preserve themselves. The most \z
            common situation in which this would apply would be the fear of \z
            death or bodily harm. Your character should act as if they won't \z
            respawn, meaning that they will go to appropriate lengths to \z
            ensure that they are not killed or injured. This rule covers the \z
            fear of weapons, roleplaying out appropriate caution/compliance\z
            /fear when a weapon is present, especially in situations in which \z
            a player is given commands at gun point, but also situations in \z
            which a character severely injures/kills themselves in order to \z
            avoid a roleplay situation. If a character roleplays out a \z
            situation in which they kill themselves, staff may rule that this \z
            constitutes a Character Kill (CK) of said character.";
        Punishment = 3;
    };
    {
        Name = "Interactions with Staff";
        Roman = "VII";
        Simple = "Interact with staff honestly and with respect when \z
        confronted.";
        Description = "If being confronted by game staff (moderators, \z
            helpers, developers, etc.), you are respected to answer honestly \z
            and respectfully.";
        Punishment = 1;
    };
    {
        Name = "One User, One Account";
        Roman = "VIII";
        Simple = "Don't make alternative accounts.";
        Description = "Each user is only permitted one account. No \z
            alternative accounts are permitted under any circumstances. If \z
            you are unable to access your Roblox account, please contact \z
            staff, and we can transfer your data to a new account. Any sort \z
            of account sharing or trading is strictly forbidden.";
        Punishment = 365;
    };
    {
        Name = "Cheating";
        Roman = "IX";
        Simple = "Don't use exploits or abuse glitches in game.";
        Description = "The use of any sort of external client or scripts in \z
            game is strictly forbidden. Abuse of glitches within the game to \z
            provide yourself with an unfair advantage is also forbidden.";
        Punishment = 30;
    };
    {
        Name = "Impersonation";
        Roman = "X";
        Simple = "Don't pretend to be another member of the community or \z
            staff.";
        Description = "It is strictly forbidden to impersonate any member of \z
            the community, especially staff. In character impersonation, such \z
            as impersonation of a police officer, is not against the rules, \z
            but will be handled by in game law enforcement. I.e., pretending \z
            to be another player or fill another role OOC is forbidden, \z
            while pretending to be another character or fill another role IC \z
            is not against the game rules.";
        Punishment = 7;
    };
    {
        Name = "Sale of In-Game Goods";
        Roman = "XI";
        Simple = "Don't sell anything in game for any out of game currency.";
        Description = "The sale of any sort of in game goods or benefits for \z
            real-world or other out-of-game benefits is forbidden. This \z
            includes selling in game currency, items, or ranks.";
        Punishment = 21;
    };
    {
        Name = "Farming";
        Roman = "XII";
        Simple = "Don't AFK farm any in game resource.";
        Description = "Any use of a script or macro, or other abuse of game \z
            systems in order to gain TIB, money, or other in game benefits \z
            while not actively playing the game or away from the keyboard \z
            (AFK) is forbidden.";
        Punishment = 3;
    };
    {
        Name = "Deaths and Character Kills";
        Roman = "XIII";
        Simple = "Your character can be killed permanently under certain \z
            circumstances.";
        Description = "Most of the time, when your character dies, you \z
            respawn, forget what happened (see rule III on NLR), and continue \z
            playing. However, sometimes your character can be \"character \z
            killed.\" This means your character is permanently dead, and you \z
            can no longer use that character. Character kills can occur in \z
            multiple circumstances. The first, and most common one is if you \z
            agree to your character being character killed. In this case, you \z
            delete your character, and make a new one. The second is a \z
            moderator-enforced character kill. If another character acts out \z
            a well-roleplayed killing of your character, including proper \z
            motives, planning and a successful getaway, a moderator can \z
            approve the character kill and will delete your character. The \z
            standard for proper motives is higher against police officers, \z
            motives must include some sort of misconduct or corruption by \z
            that officer, not acts falling within their line of duty, such as \z
            arresting you or attempting to. This can also be done by police \z
            enforcing the death penalty, or by a character being killed by \z
            police during the execution of a felony warrant against that \z
            character. The third is punitive character kills. If you roleplay \z
            out the death of your character, such as shooting yourself or \z
            jumping off a building the character will be killed as a result \z
            of your actions leading up to that point. This also applies in \z
            situations in which the character attempts an assassination of a \z
            political figure and dies in the act, whether the killing was \z
            successful or not.";
        Punishment = 3;
    };
    {
        Name = "Character Naming";
        Roman = "XIV";
        Simple = "Create an appropriate and original name for your character.";
        Description = "When creating a character, you can not use the name of \z
            a celebrity, fictional character, or anything inappropriate. Each \z
            name will be reviewed by the staff team, and names that don't \z
            meet our standards will be rejected, and you'll have the \z
            opportunity to pick another one. However, if you continue to \z
            attempt to use/inundate the system with improper or inappropriate \z
            name requests, you will receive moderative action on your account \z
            in response to the rule violation.";
        Punishment = 1;
    };
    {
        Name = "Bypassing";
        Roman = "XV";
        Simple = "Don't bypass Roblox's moderation or filters.";
        Description = "Being a game on Roblox, we’re bound by the Roblox \z
            terms of service. Any attempts to bypass Roblox’s moderation, \z
            whether that be with using slurs or profanities in the text chat, \z
            using bypassed assets, or any other way of violating Roblox’s \z
            terms of service is not permitted.";
        Punishment = 1;
    };
    {
        Name = "Voice Chat";
        Roman = "XVI";
        Simple = "Voice chat is in character, and don't abuse soundboards.";
        Description = "All voice chat is in character. Any out of character \z
            remarks or conversations should take place through the /b or /ooc \z
            command in game, or outside of the game. The abuse of soundboards \z
            to play any explicit, loud, or otherwise disruptive audio is \z
            prohibited.";
        Punishment = 1;
    };
}

config.RomanDictionary = {}
for i, rule in ipairs(config.Rules) do
    config.RomanDictionary[rule.Roman] = rule;
end

return config