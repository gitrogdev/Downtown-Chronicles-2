const AXIOS = require('axios');
const CRYPTO = require('crypto');
const {
    EmbedBuilder
} = require('discord.js');

const API_KEYS = require('./apikeys.json');
const CONFIG = require('./config.json');
let LicenseApplications = require('./licenseapplications.json');
const RESPONSE_FORMAT = require('./licenseformat.json');
const UTIL = require('./util.js');

exports.HandleCommand = async function(CLIENT, interaction) {
    let request = interaction.options.getInteger('request');
    if (request < 0 || request >= LicenseApplications.length)
        return interaction.reply(
            `License application with ID ${request} not found!`
        );

    if (interaction.channelId != CONFIG.LicenseApplicationChannel)
        return interaction.reply(
            'Command must be used in the license applications channel!'
        );

    let reqData = LicenseApplications[request];
    let licenseType = reqData.Type;
    if (reqData.Processed) return interaction.reply(
        `License applications with ID ${request} has already been handled!`
    );

    let replied = false
    const RESPONSE = await AXIOS.get(
        `${CONFIG.APIDSPrefix}${CONFIG.ExperienceId}${CONFIG.DSEntrySuffix}`,
        {
            params: {
                'datastoreName': CONFIG.MasterDSKey,
                'entryKey': `Characters_${reqData.Character}`
            },
            headers: {
                'x-api-key': API_KEYS.DataStores
            }
        }
    ).catch(err => {
        if (
            err.response.data.message == 'Entry not found in the datastore.'
        ) {
            replied = true
            return interaction.reply(
                `No character found with ID ${reqData.Character}`
            );
        }
        console.log(err.response);
    });

    if (!replied && !(RESPONSE && RESPONSE.data)) return interaction.reply(
        `Unable to access Roblox DataStores for Application ID ${request}`
    ); else if (replied) return;

    if (interaction.commandName === 'approvelicense') {
        let newData = {};
        for (let [key, value] of Object.entries(RESPONSE.data))
            newData[key] = value;

        if (newData.hasOwnProperty(`RejectedNorth${licenseType}`))
            delete newData[`RejectedNorth${licenseType}`];
        newData[`ApprovedNorth${licenseType}`] = true;

        newData = JSON.stringify(newData);
        let hashedData = await CRYPTO.createHash('md5').update(newData).digest(
            'base64'
        );
        
        const APPROVE_RESPONSE = await AXIOS.post(
            `${CONFIG.APIDSPrefix}${CONFIG.ExperienceId}`
            + `${CONFIG.DSEntrySuffix}`,
            newData, {
                params: {
                    'datastoreName': CONFIG.MasterDSKey,
                    'entryKey': `Characters_${reqData.Character}`
                },
                headers: {
                    'content-md5': hashedData,
                    'content-type': 'application/json',
                    'x-api-key': API_KEYS.DataStores
                }
            }
        ).catch(err => {
            if (
                err.response.data.message == 'Entry not found in the datastore.'
            ) {
                replied = true
                return interaction.reply(
                    `No character found with ID ${reqData.Character}`
                );
            }
            console.log(err.response);
        });

        const MESSAGE_RESPONSE = await AXIOS.post(
            `${CONFIG.APIMSPrefix}${CONFIG.ExperienceId}/topics/LicenseRespond`,
            {
                'message': JSON.stringify({
                    'ID': reqData.Character,
                    'License': licenseType,
                    'Status': 'Approved'
                })
            },
            {
                headers: {
                    'content-type': 'application/json',
                    'x-api-key': API_KEYS.DataStores
                }
            }
        ).catch(err => {
            console.log(err.response);
        });

        if (MESSAGE_RESPONSE) console.log(
            `Got code ${MESSAGE_RESPONSE.status} from MessagingService!`
        );

        if (!replied && APPROVE_RESPONSE && APPROVE_RESPONSE.data) {
            LicenseApplications[request].Processed = true;
            UTIL.writeJSON('./licenseapplications.json', LicenseApplications);

            CLIENT.channels.cache.get(
                CONFIG.LicenseApplicationChannel
            ).messages.fetch(reqData.RequestMessage).then(message => {
                message.edit({embeds: [new EmbedBuilder()
                    .setTitle(
                        `Approved ${licenseType} application from `
                        + `${reqData.Name} (${reqData.Character})`
                    )
                    .setColor(0x519E8A)
                    .addFields(
                        {
                            'name': 'Request ID',
                            'value': `${request}`
                        },
                        {
                            'name': 'Name',
                            'value': reqData.Name,
                            'inline': true
                        },
                        {
                            'name': 'License Type',
                            'value': licenseType,
                            'inline': true
                        },
                        {
                            'name': 'Content',
                            'value': reqData.Text
                        }
                    )
                    .setFooter({
                        'text': 'License application approved by '
                            + interaction.user.username
                    })
                    .setTimestamp()]})
            }).catch(err => {
                console.log(`Error with editing past message: ${err}`);
            });

            return interaction.reply(
                `Approved ${licenseType} with request ID ${request} for `
                + reqData.Name
            )
        }
    } else if (interaction.commandName === 'rejectlicense') {
        let reason = interaction.options.getString('reason');

        let newData = {};
        for (let [key, value] of Object.entries(RESPONSE.data))
            newData[key] = value;

        if (newData.hasOwnProperty(`ApprovedNorth${licenseType}`))
            delete newData[`ApprovedNorth${licenseType}`];
        newData[`RejectedNorth${licenseType}`] = reason;

        newData = JSON.stringify(newData);
        let hashedData = await CRYPTO.createHash('md5').update(newData).digest(
            'base64'
        );
        
        const REJECT_RESPONSE = await AXIOS.post(
            `${CONFIG.APIDSPrefix}${CONFIG.ExperienceId}`
            + `${CONFIG.DSEntrySuffix}`,
            newData,
            {
                params: {
                    'datastoreName': CONFIG.MasterDSKey,
                    'entryKey': `Characters_${reqData.Character}`
                },
                headers: {
                    'content-md5': hashedData,
                    'content-type': 'application/json',
                    'x-api-key': API_KEYS.DataStores
                }
            }
        ).catch(err => {
            if (
                err.response.data.message == 'Entry not found in the datastore.'
            ) {
                replied = true
                return interaction.reply(
                    `No character found with ID ${reqData.Character}`
                );
            }
            console.log(err.response);
        });

        const MESSAGE_RESPONSE = await AXIOS.post(
            `${CONFIG.APIMSPrefix}${CONFIG.ExperienceId}/topics/LicenseRespond`,
            {
                'message': JSON.stringify({
                    'ID': reqData.Character,
                    'License': licenseType,
                    'Reason': reason,
                    'Status': 'Rejected'
                })
            },
            {
                headers: {
                    'content-type': 'application/json',
                    'x-api-key': API_KEYS.DataStores
                }
            }
        ).catch(err => {
            console.log(err.response);
        });

        if (MESSAGE_RESPONSE) console.log(
            `Got code ${MESSAGE_RESPONSE.status} from MessagingService!`
        );

        if (!replied && REJECT_RESPONSE && REJECT_RESPONSE.data) {
            LicenseApplications[request].Processed = true;
            UTIL.writeJSON('./licenseapplications.json', LicenseApplications);

            CLIENT.channels.cache.get(
                CONFIG.LicenseApplicationChannel
            ).messages.fetch(reqData.RequestMessage).then(message => {
                message.edit({embeds: [new EmbedBuilder()
                    .setTitle(
                        `Rejected ${licenseType} application from `
                        + `${reqData.Name} (${reqData.Character})`
                    )
                    .setColor(0xBF1A2F)
                    .addFields(
                        {
                            'name': 'Request ID',
                            'value': `${request}`
                        },
                        {
                            'name': 'Name',
                            'value': reqData.Name,
                            'inline': true
                        },
                        {
                            'name': 'License Type',
                            'value': licenseType,
                            'inline': true
                        },
                        {
                            'name': 'Content',
                            'value': reqData.Text
                        }
                    )
                    .setFooter({
                        'text': 'License application rejected by '
                            + `${interaction.user.username}\nReason: ${reason}`
                    })
                    .setTimestamp()]})
            }).catch(err => {
                console.log(`Error with editing past message: ${err}`);
            });

            return interaction.reply(
                `Rejected ${licenseType} with request ID ${request} for `
                + reqData.Name
            )
        }
    }
}

exports.Process = async function(CLIENT, message) {
    let content = message.content;
    let nameStart = content.search(RESPONSE_FORMAT.Name);
    let typeStart = content.search(RESPONSE_FORMAT.Type);
    let idStart = content.search(RESPONSE_FORMAT.Character);
    let textStart = content.search(RESPONSE_FORMAT.Text);

    let name = content.substring(
        nameStart + RESPONSE_FORMAT.Name.length,
        typeStart
    );
    let licenseType = content.substring(
        typeStart + RESPONSE_FORMAT.Type.length,
        idStart
    );
    let character = content.substring(
        idStart + RESPONSE_FORMAT.Character.length,
        textStart
    );
    let text = content.substring(
        textStart + RESPONSE_FORMAT.Text.length
    );

    if (text.length > 1024) text = text.substring(0, 1023);

    let RequestEmbed = new EmbedBuilder()
        .setTitle(`${licenseType} application from ${name} (${character})`)
        .addFields(
            {
                'name': 'Request ID',
                'value': `${LicenseApplications.length}`
            },
            {
                'name': 'Name',
                'value': name,
                'inline': true
            },
            {
                'name': 'License Type',
                'value': licenseType,
                'inline': true
            },
            {
                'name': 'Content',
                'value': text
            }
        )
        .setFooter({
            'text': 'To approve this application, use the /approvelicense '
            + 'command.\n'
            + 'To reject this application, use the /rejectlicense command.'
        });
    CLIENT.channels.cache.get(CONFIG.LicenseApplicationChannel).send({
        embeds: [RequestEmbed]
    }).then(message => {
        LicenseApplications.push({
            Name: name,
            Character: character,
            Type: licenseType,
            Text: text,
            RequestMessage: message.id
        });
        UTIL.writeJSON('./licenseapplications.json', LicenseApplications);
    });
    message.delete();
}