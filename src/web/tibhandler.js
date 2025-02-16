const AXIOS = require('axios');
const {
    EmbedBuilder
} = require('discord.js');

const CONFIG = require('./config.json');

async function makeEmbed(userId) {
    let dtcTib = '0-4 TIB';
    for (let i in CONFIG.DTCBadges) {
        let has = await AXIOS.get(
            `${CONFIG.BadgeUrlPrefix}${userId}${CONFIG.BadgeIdSuffix}`
            + `${CONFIG.DTCBadges[i]}`
        ).catch(err => {
            console.log(`Request failed: ${err}`)
        });

        if (has && has.data.data.length > 0) {
            dtcTib = CONFIG.BadgeOrder[i];
            break;
        }
    }

    let originsTib = '0-4 TIB';
    for (let i in CONFIG.OriginsBadges) {
        let has = await AXIOS.get(
            `${CONFIG.BadgeUrlPrefix}${userId}${CONFIG.BadgeIdSuffix}`
            + `${CONFIG.OriginsBadges[i]}`
        ).catch(err => {
            console.log(`Request failed: ${err}`)
        });

        if (has && has.data.data.length > 0) {
            originsTib = CONFIG.BadgeOrder[i];
            break;
        }
    }

    let dtc2Tib = '0-4 TIB';
    for (let i in CONFIG.DTC2Badges) {
        let has = await AXIOS.get(
            `${CONFIG.BadgeUrlPrefix}${userId}${CONFIG.BadgeIdSuffix}`
            + `${CONFIG.DTC2Badges[i]}`
        ).catch(err => {
            console.log(`Request failed: ${err}`)
        });

        if (has && has.data.data.length > 0) {
            dtc2Tib = CONFIG.BadgeOrder[i];
            break;
        }
    }

    return new EmbedBuilder()
        .setTitle(`TIB for Roblox user ${userId}`)
        .addFields(
            {
                'name': 'Downtown Chronicles',
                'value': dtcTib,
                'inline': true
            },
            {
                'name': 'Bloxell: Origins',
                'value': originsTib,
                'inline': true
            },
            {
                'name': 'Downtown Chronicles 2',
                'value': dtc2Tib,
                'inline': true
            }
        )
        .setFooter({
            'text': 'TIB is calculated based on the ownership of Roblox '
            + 'badges. Therefore, cumulative TIB across characters is not '
            + 'calculated, but the highest TIB on one single character.'
        })
        .setTimestamp();
}

exports.Get = async function(CLIENT, interaction) {
    let userId = interaction.options.getInteger('userid');
    if (userId < 0) return interaction.reply(
        `"${userId}" is not a valid User ID!`
    );

    let embed = await makeEmbed(userId)
    if (!embed) {
        return interaction.reply(`Unable to get TIB for user ID ${userId}.`)
    }

    interaction.channel.send({
        embeds: [embed]
    }).then(() => (
        interaction.reply({
            content: `Got TIB for user with user ID ${userId}.`,
            ephemeral: true
        }).catch(err => {
            console.log(`Unable to reply to TIB request: ${err}`)
        })
    )).catch(err => {
        console.log(`Unable to print TIB for ${userId}: ${err}`)
    });
}

exports.GetFromWebhook = async function(message, userId) {
    message.channel.send({
        embeds: [await makeEmbed(userId)]
    });
    message.delete();
}