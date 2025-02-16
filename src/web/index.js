const {
    ActionRowBuilder,
    Client,
    ButtonBuilder,
    ButtonStyle,
    EmbedBuilder,
    GatewayIntentBits,
    PermissionFlagsBits,
    REST,
    Routes,
    SlashCommandBuilder
} = require('discord.js');
const CLIENT = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMembers,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.GuildMessageReactions,
        GatewayIntentBits.MessageContent
    ]
});

const ANNOUNCEMENT_HANDLER = require('./announcements.js');
const API_KEYS = require('./apikeys.json');
let BotData = require('./botdata.json');
const CONFIG = require('./config.json');
const LICENSE_APPLICATIONS = require('./licenseapplications.js');
const NAME_REQUESTS = require('./namerequests.js');
const PROXY = require('./proxy.js');
const TIB_HANDLER = require('./tibhandler.js');
const TICKET_HANDLER = require('./tickethandler.js');
const UTIL = require('./util.js');

const COMMANDS = [
    new SlashCommandBuilder()
        .setName('approvename')
        .setDescription('Approve a name request.')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageNicknames)
        .setDMPermission(false)
        .addIntegerOption(option =>
            option.setName('request')
            .setDescription('The request ID of the name request.')
            .setRequired(true))
        .addStringOption(option =>
            option.setName('comment')
            .setDescription('Any additional comments to leave for the staff.')
            .setRequired(false)),
    new SlashCommandBuilder()
        .setName('rejectname')
        .setDescription('Reject a name request.')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageNicknames)
        .setDMPermission(false)
        .addIntegerOption(option =>
            option.setName('request')
            .setDescription('The request ID of the name request.')
            .setRequired(true))
        .addStringOption(option =>
            option.setName('reason')
            .setDescription('The reason to deny the request.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('editname')
        .setDescription('Edit a name request.')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageNicknames)
        .setDMPermission(false)
        .addIntegerOption(option =>
            option.setName('request')
            .setDescription('The request ID of the name request.')
            .setRequired(true))
        .addStringOption(option =>
            option.setName('reason')
            .setDescription('The reason to edit the request.')
            .setRequired(true))
        .addStringOption(option =>
            option.setName('first')
            .setDescription('The new first name.')
            .setRequired(true))
        .addStringOption(option =>
            option.setName('last')
            .setDescription('The new last name.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('overridename')
        .setDescription('Override a processed name request.')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageMessages)
        .setDMPermission(false)
        .addIntegerOption(option =>
            option.setName('request')
            .setDescription('The request ID of the name request.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('closeticket')
        .setDescription('Close the currently open moderation ticket.')
        .setDefaultMemberPermissions(PermissionFlagsBits.CreatePrivateThreads)
        .setDMPermission(false),
    new SlashCommandBuilder()
        .setName('say')
        .setDescription('Send a message as the bot user.')
        .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
        .setDMPermission(false)
        .addStringOption(option =>
            option.setName('content')
            .setDescription('The message for the bot to send.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('tib')
        .setDescription('Determine the total TIB score of a Roblox user.')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageMessages)
        .setDMPermission(false)
        .addIntegerOption(option =>
            option.setName('userid')
            .setDescription('The user\'s ID on Roblox.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('newticket')
        .setDescription('Open a moderation ticket with a given member.')
        .setDefaultMemberPermissions(PermissionFlagsBits.CreatePrivateThreads)
        .setDMPermission(false)
        .addUserOption(option =>
            option.setName('target')
            .setDescription('The user to open the ticket with.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('icnews')
        .setDescription('Post an In Character news report.')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageEvents)
        .setDMPermission(false)
        .addStringOption(option =>
            option.setName('message')
            .setDescription('The news report to send.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('dtc2startup')
        .setDescription('Host a startup on Downtown Chronicles 2.')
        .setDefaultMemberPermissions(PermissionFlagsBits.MentionEveryone)
        .setDMPermission(false),
    new SlashCommandBuilder()
        .setName('approvelicense')
        .setDescription('Approve a firearms license application.')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageNicknames)
        .setDMPermission(false)
        .addIntegerOption(option =>
            option.setName('request')
            .setDescription('The request ID of the license application.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('rejectlicense')
        .setDescription('Reject a firearms license application.')
        .setDefaultMemberPermissions(PermissionFlagsBits.ManageNicknames)
        .setDMPermission(false)
        .addIntegerOption(option =>
            option.setName('request')
            .setDescription('The request ID of the license application.')
            .setRequired(true))
        .addStringOption(option =>
            option.setName('reason')
            .setDescription('The reason to deny the license application.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('gchtousd')
        .setDescription('Convert a value in Bloxellian GCH to USD.')
        .setDMPermission(false)
        .addNumberOption(option =>
            option.setName('value')
            .setDescription('The amount in GCH.')
            .setRequired(true)),
    new SlashCommandBuilder()
        .setName('usdtogch')
        .setDescription('Convert a value in American dollars to GCH.')
        .setDMPermission(false)
        .addNumberOption(option =>
            option.setName('value')
            .setDescription('The amount in USD.')
            .setRequired(true))
];

const rest = new REST({
    version: '10'
}).setToken(API_KEYS.Discord);

(async () => {
    try {
        console.log('Began refreshing the application commands');

        await rest.put(Routes.applicationCommands('1199713747875418192'), {
            body: COMMANDS
        });

        console.log('Successfully refreshed application commands')
    }
    catch (error) {
        console.error(error);
    }
})();

CLIENT.on('interactionCreate', async interaction => {
    if (interaction.isChatInputCommand()) {
        if (
            interaction.commandName === 'approvename' 
            || interaction.commandName === 'rejectname' 
            || interaction.commandName === 'editname'
            || interaction.commandName === 'overridename'
        ) {
            NAME_REQUESTS.HandleCommand(CLIENT, interaction);
        } else if (interaction.commandName === 'newticket') {
            TICKET_HANDLER.NewTicket(CLIENT, interaction)
        } else if (interaction.commandName === 'closeticket') {
            TICKET_HANDLER.CloseTicket(CLIENT, interaction)
        } else if (interaction.commandName === 'say') {
            interaction.channel.send(interaction.options.getString('content'));
        } else if (interaction.commandName === 'tib') {
            TIB_HANDLER.Get(CLIENT, interaction);
        } else if (interaction.commandName === 'gchtousd') {
            let gch = interaction.options.getNumber('value');
            interaction.reply(
                `₲${gch} is $${Math.round((gch / 127) * 100)/100}!`
            );
        } else if (interaction.commandName === 'usdtogch') {
            let usd = interaction.options.getNumber('value');
            interaction.reply(
                `$${usd} is ₲${Math.round((usd * 127) * 100)/100}!`
            );
        } else if (interaction.commandName === 'icnews') {
            ANNOUNCEMENT_HANDLER.WriteNews(CLIENT, interaction);
        } else if (interaction.commandName === 'dtc2startup') {
            ANNOUNCEMENT_HANDLER.DTC2Startup(CLIENT, interaction);
        } else if (
            interaction.commandName === 'approvelicense' 
            || interaction.commandName === 'rejectlicense' 
        ) {
            LICENSE_APPLICATIONS.HandleCommand(CLIENT, interaction);
        }
    } else if (interaction.isButton()) {
        if (
            interaction.customId === 'helper'
            || interaction.customId === 'moderator'
            || interaction.customId === 'designer'
            || interaction.customId === 'developer'
        ) TICKET_HANDLER.RequestTicket(CLIENT, interaction)
    }
});

CLIENT.on('messageCreate', async message => {
    if (
        message.channelId === CONFIG.RequestChannel
        && message.webhookId == CONFIG.RequestWebhook
    )   return NAME_REQUESTS.Process(CLIENT, message);
    else if (
        message.channelId === CONFIG.LicenseWebhookChannel
        && message.webhookId == CONFIG.LicenseWebhook
    )   return LICENSE_APPLICATIONS.Process(CLIENT, message);
    else if(
        message.channelId == CONFIG.AlphaChannel
        && message.webhookId == CONFIG.AlphaWebhook
    ) {
        if (message.content.startsWith('GET TIB')) TIB_HANDLER.GetFromWebhook(
            message,
            message.content.substring(8)
        );
        else if (!message.content.startsWith('Given the Roblox username')) {
            message.react('👍');
            message.react('👎');
            message.startThread({
                'name': 'Application discussion',
                'reason': 'To discuss the merits of this alpha application.'
            })
        }
    }

    if (message.author.bot) return;
    if (message.content.search(/bloxwell/i) > -1)
        return message.reply('It\'s Bloxell, not Bloxwell! 😉');
    if (message.content.search(/dead game/i) > -1)
        return message.reply(
            'Downtown Chronicles 2 has not yet been released, and is in a ' +
            'limited early access period for its Alpha phase of development.'
        );
    if (message.content.search(/when update/i) > -1)
        return message.reply(
            'As this is a hobby project for us, and is not our primary or ' +
            'even significant source of income, we work on the game when we ' +
            'can in regards to other obligations we have. There are no ' +
            'planned release dates for updates, and they are generally ' +
            'released when they are finished.'
        );
    if (message.content.search('<@966923213214990366>') > -1) {
        let canPing = false
        
        for (checkId of CONFIG.StaffRoles)
            if (message.member.roles.cache.some(role => role.id === checkId)) {
                canPing = true;
                break;
            }

        if (!canPing)
            return message.reply(
                'Please refer to Discord Rule VII, and do not mention gitrog '
                + 'directly. If you need help, try opening a ticket in the '
                + `<#${CONFIG.TicketChannel}> channel.`
            )
    }
});

CLIENT.on('messageReactionAdd', async (reaction, User) => {
    if (
        reaction.message.id == BotData.RoleMessage
        && CONFIG.ReactionRoles[reaction.emoji.name]
    ) await reaction.message.guild.members.cache.get(User.id).roles.add(
        CONFIG.ReactionRoles[reaction.emoji.name]
    ).catch(err => {
        console.log(
            `Failed to give the role for reaction "${reaction.emoji.name}`
            + `to user ${User.username}: ${err.rawError.message}`
        );
    }).then(() => {
        reaction.message.guild.members.cache.get(User.id).send(
            `Successfully added the role for reaction "${reaction.emoji.name}"`
        ).catch(err => {
            console.log(
                `Failed to DM ${User.username}: ${err.rawError.message}`
            );
        });
    });
});

CLIENT.on('messageReactionRemove', async (reaction, User) => {
    if (
        reaction.message.id == BotData.RoleMessage
        && CONFIG.ReactionRoles[reaction.emoji.name]
    ) await reaction.message.guild.members.cache.get(User.id).roles.remove(
        CONFIG.ReactionRoles[reaction.emoji.name]
    ).catch(err => {
        console.log(
            `Failed to remove the role for reaction "${reaction.emoji.name}" ` 
            + `from user ${User.username}: ${err.rawError.message}`
        );
    }).then(() => {
        reaction.message.guild.members.cache.get(User.id).send(
            `Successfully removed the role for reaction `
            + `"${reaction.emoji.name}"`
        ).catch(err => {
            console.log(
                `Failed to DM ${User.username}: ${err.rawError.message}`
            );
        });
    });
});

CLIENT.on('ready', async () => {
    CLIENT.channels.cache.get(CONFIG.RequestChannel).messages.fetch({
        limit: 100
    }).then(messages => {
        messages.forEach(message => {
            if (
                message.channelId === CONFIG.RequestChannel
                && message.webhookId == CONFIG.RequestWebhook
            ) NAME_REQUESTS.Process(CLIENT, message);
        });
    });

    CLIENT.channels.cache.get(CONFIG.LicenseWebhookChannel).messages.fetch({
        limit: 100
    }).then(messages => {
        messages.forEach(message => {
            if (
                message.channelId === CONFIG.LicenseWebhookChannel
                && message.webhookId == CONFIG.LicenseWebhook
            ) LICENSE_APPLICATIONS.Process(CLIENT, message);
        });
    });

    let RoleEmbed = new EmbedBuilder()
        .setTitle('React to be notified for chosen announcements')
        .addFields(
            {
                name: '🖥️ Development Updates',
                value: 'If you\'re interested in updates about the development '
                + 'of the game, just react to this message with "🖥️"'
            },
            {
                name: '🧐 Startup Participant',
                value: 'If you\'re interested in participating in server '
                + 'startups on Downtown Chronicles 2, just react to this '
                + 'message with "🧐"'
            },
            {
                name: '🎮 Game Nights',
                value: 'If you\'re interested in playing other games with the '
                + 'the community, just react to this message with "🎮"'
            },
            {
                name: '📰 IC News',
                value: 'If you\'re interested in receiving In Character news '
                + 'about Downtown Chronicles 2, just react to this message '
                + 'with "📰"'
            }
        );

    if (BotData.RoleMessage) await CLIENT.channels.cache.get(
        CONFIG.RoleChannel
    ).messages.fetch(BotData.RoleMessage).then(RoleMessage => {
        RoleMessage.edit({embeds: [RoleEmbed]})
    });
    else await CLIENT.channels.cache.get(CONFIG.RoleChannel).send({
        embeds: [RoleEmbed]
    }).then(Message => {
        BotData.RoleMessage = Message.id;
        UTIL.writeJSON('./botdata.json', BotData);
    });

    let TicketEmbed = new EmbedBuilder()
        .setTitle('Staff Ticket Request')
        .setDescription(
            'If you have an issue with the game, a question, or a report on a '
            + 'player for staff to handle, you can request a staff ticket for '
            + 'a member of our team to handle your request.'
        )
        .addFields(
            {
                name: 'Request Helpers',
                value: 'If you have a question about the game, or are facing '
                + 'basic issues, you may request a helper\'s assistance with '
                + 'the "Request Helpers" button.'
            },
            {
                name: 'Request Moderators',
                value: 'If you have a rule violation to report, be it in game '
                + 'or in the Discord server, you may request moderative action '
                + 'with the "Request Moderators" button.'
            },
            {
                name: 'Map Bug Report',
                value: 'If you have found a bug in something relating to the '
                + 'map of the game (lighting, building, etc.), you may report '
                + ' it with the "Map Bug" button.'
            },
            {
                name: 'Script Bug Report',
                value: 'If you have found a bug in something relating to the '
                + 'scripts of the game (mechanics, glitches, etc.), you may '
                + 'report it with the "Script Bug" button.'
            }
        );

    let HelperButton = new ButtonBuilder()
        .setCustomId('helper')
        .setLabel('Request Helpers')
        .setStyle(ButtonStyle.Success);

    let ModButton = new ButtonBuilder()
        .setCustomId('moderator')
        .setLabel('Request Moderators')
        .setStyle(ButtonStyle.Danger);

    let MapButton = new ButtonBuilder()
        .setCustomId('designer')
        .setLabel('Map Bug')
        .setStyle(ButtonStyle.Primary);

    let ScriptButton = new ButtonBuilder()
        .setCustomId('developer')
        .setLabel('Script Bug')
        .setStyle(ButtonStyle.Secondary);

    let Row = new ActionRowBuilder()
        .addComponents(HelperButton, ModButton, MapButton, ScriptButton);

    if (BotData.TicketMessage) await CLIENT.channels.cache.get(
        CONFIG.TicketChannel
    ).messages.fetch(BotData.TicketMessage).then(TicketMessage => {
        TicketMessage.edit({embeds: [TicketEmbed], components: [Row]});
    });
    else await CLIENT.channels.cache.get(CONFIG.TicketChannel).send({
        embeds: [TicketEmbed],
        components: [Row]
    }).then(Message => {
        BotData.TicketMessage = Message.id;
        UTIL.writeJSON('./botdata.json', BotData);
    });
});

CLIENT.login(API_KEYS.Discord);