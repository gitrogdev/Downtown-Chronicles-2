const {
    ChannelType,
    EmbedBuilder
} = require('discord.js');
let BotData = require('./botdata.json');
const CONFIG = require('./config.json');
const TicketRequests = require('./ticketrequests.json');
const UTIL = require('./util.js');

exports.CloseTicket = async function(CLIENT, interaction) {
    if (
        interaction.channel.type != 12
        || interaction.channel.parentId != CONFIG.TicketChannel
    ) return interaction.reply(
        'This command must be used in the thread of an open staff ticket!'
    );

    interaction.channel.setLocked(true);

    return interaction.reply(
        `This ticket has been marked as closed by ${interaction.user.username}.`
        + ` If you need further assistance, don't hesitate to file a new `
        + `support request. Thank you for being an invested member of our `
        + `Downtown Chronicles community.`
    );
}

exports.NewTicket = async function(CLIENT, interaction) {
    let target = interaction.options.getUser('target');

    let ticketNumber = BotData.Tickets + 1;
    BotData.Tickets = ticketNumber;
    UTIL.writeJSON('./botdata.json', BotData);

    CLIENT.channels.cache.get(CONFIG.TicketChannel).threads.create({
        name: `ticket-${ticketNumber.toString().padStart(4, '0')}`,
        type: ChannelType.PrivateThread,
        reason: `${interaction.user.username} has opened a staff ticket `
        + `regarding ${target.username}.`
    }).then(thread => {
        thread.members.add(interaction.user.id);
        thread.members.add(target.id);
        thread.send({
            content: `<@${target.id}> ${interaction.user.username} has `
            + `initiated a private staff ticket with you. Please answer all `
            + `questions honestly and promptly.`
        })

        interaction.reply(`Ticket <#${thread.id}> opened.`);
    }).catch(err => {
        console.log(`Error creating thread ${err}`)
        interaction.reply('Error creating ticket thread.')
    });
}

exports.RequestTicket = async function(CLIENT, interaction) {
    let ticketNumber = BotData.Tickets + 1;
    BotData.Tickets = ticketNumber;
    UTIL.writeJSON('./botdata.json', BotData);

    CLIENT.channels.cache.get(CONFIG.TicketChannel).threads.create({
        name: `ticket-${ticketNumber.toString().padStart(4, '0')}`,
        type: ChannelType.PrivateThread,
        reason: `${interaction.user.username} is requesting to open a `
        + `**${interaction.customId}** ticket.`
    }).then(thread => {
        thread.members.add(interaction.user.id);
        thread.send({
            content: `<@${interaction.user.id}> you have successfully opened a `
            + `${interaction.customId} ticket. Please describe your issue, `
            + `including screenshots and videos where appropriate, and a `
            + `${interaction.customId} will be with you shortly.`
        })

        let TicketEmbed = new EmbedBuilder()
            .setTitle(`Ticket #${ticketNumber}`)
            .setDescription(
                `${interaction.user.username} has opened a `
                + `**${interaction.customId}** ticket.`
            )
            .setFooter({
                'text': `Link to the thread for this ticket above.`
            })
            .setTimestamp();
        

        CLIENT.channels.cache.get(CONFIG.TicketRequests).send({
            content: `<@&${CONFIG.RequestRoles[interaction.customId]}> Channel:`
                + ` <#${thread.id}>`,
            embeds: [TicketEmbed]
        }).then(Message => {
            interaction.reply({
                content: `Successfully opened ${interaction.customId} ticket.`
                + `\n\nPlease be patient, and know that filing multiple `
                + `tickets will not increase the response time of your ticket, `
                + `and only serves to inundate our system.`,
                ephemeral: true
            });
        }).catch(err => {
            console.log(`Failed to file ticket request: ${err}`)
            interaction.reply({
                content: `Unable to open ${interaction.customId} ticket.`,
                ephemeral: true
            })
        })
    }).catch(err => {
        console.log(`Error creating thread ${err}`)
        interaction.reply({
            content: `Unable to open ${interaction.customId} ticket.`,
            ephemeral: true
        });
    });
}