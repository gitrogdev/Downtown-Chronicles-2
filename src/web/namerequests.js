const AXIOS = require('axios');
const CRYPTO = require('crypto');
const {
    EmbedBuilder
} = require('discord.js');

const API_KEYS = require('./apikeys.json');
const CONFIG = require('./config.json');
let NameRequests = require('./namerequests.json');
const RESPONSE_FORMAT = require('./responseformat.json');
const UTIL = require('./util.js');

exports.HandleCommand = async function(CLIENT, interaction) {
    let request = interaction.options.getInteger('request');
    if (request < 0 || request >= NameRequests.length)
        return interaction.reply({
            content: `Character request with ID ${request} not found!`,
            ephemeral: true
        });

    if (interaction.channelId != CONFIG.RequestPostChannel)
        return interaction.reply({
            content: 'Command must be used in the name requests channel!',
            ephemeral: true
        });

    let reqData = NameRequests[request];
    if (interaction.commandName === 'overridename') {
        if (reqData.Processed) {
            NameRequests[request].Processed = false;
            UTIL.writeJSON('./namerequests.json', NameRequests);
            return interaction.reply({
                content: `Character request with ID ${request} overriden!`,
                ephemeral: true
            });
        } else return interaction.reply({
            content: `Character request with ID ${request} was not processed!`,
            ephemeral: true
        })
    } else if (reqData.Processed) return interaction.reply({
        content: `Character request with ID ${request} has already been `
        + `handled!`,
        ephemeral: true
    });

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
            err.response &&
            err.response.data &&
            err.response.data.message == 'Entry not found in the datastore.'
        ) {
            replied = true
            return interaction.reply({
                content: `No character found with ID ${reqData.Character}`,
                ephemeral: true
            });
        }
        console.log(err.response);
    });

    if (!replied && !(RESPONSE && RESPONSE.data)) return interaction.reply({
        content: `Unable to access Roblox DataStores for Request ID ${request}`,
        ephemeral: true
    }); else if (replied) return;

    if (interaction.commandName === 'approvename') {
        let comment = interaction.options.getString('comment');

        let newData = {};
        for (let [key, value] of Object.entries(RESPONSE.data))
            newData[key] = value;

        if (newData.hasOwnProperty('Rejected')) delete newData['Rejected'];
        if (newData.hasOwnProperty('Edited')) delete newData['Edited'];
        newData.Approved = true;

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
                err.response &&
                err.response.data &&
                err.response.data.message == 'Entry not found in the datastore.'
            ) {
                replied = true
                return interaction.reply({
                    content: `No character found with ID ${reqData.Character}`,
                    ephemeral: true
                });
            }
            console.log(err.response);
        });

        const MESSAGE_RESPONSE = await AXIOS.post(
            `${CONFIG.APIMSPrefix}${CONFIG.ExperienceId}/topics/NameRequest`,
            {
                'message': JSON.stringify({
                    'ID': reqData.Character,
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
            NameRequests[request].Processed = true;
            UTIL.writeJSON('./namerequests.json', NameRequests);

            let footer = `Name approved by ${interaction.user.username}`;
            if (comment) footer += `\nComment: ${comment}`;

            CLIENT.channels.cache.get(CONFIG.RequestPostChannel).messages.fetch(
                reqData.RequestMessage
            ).then(message => {
                message.edit({embeds: [new EmbedBuilder()
                    .setTitle(`Approved name request from ${reqData.Player}`)
                    .setColor(0x519E8A)
                    .addFields(
                        {
                            'name': 'Request ID',
                            'value': `${request}`
                        },
                        {
                            'name': 'First name',
                            'value': `"${reqData.First}"`,
                            'inline': true
                        },
                        {
                            'name': 'Last name',
                            'value': `"${reqData.Last}"`,
                            'inline': true
                        },
                        {
                            'name': 'Gender',
                            'value': reqData.Gender,
                            'inline': true
                        }
                    )
                    .setFooter({
                        'text': footer
                    })
                    .setTimestamp()]})
            }).catch(err => {
                console.log(`Error with editing past message: ${err}`);
            });

            return interaction.reply({
                content: `Approved name ${reqData.First} ${reqData.Last} `
                + `with request ID ${request} for ${reqData.Player}`,
                ephemeral: true
            })
        }
    } else if (interaction.commandName === 'rejectname') {
        let reason = interaction.options.getString('reason');

        let newData = {};
        for (let [key, value] of Object.entries(RESPONSE.data))
            newData[key] = value;

        if (newData.hasOwnProperty('Approved')) delete newData['Approved'];
        if (newData.hasOwnProperty('Edited')) delete newData['Edited'];
        newData.Rejected = reason;

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
                err.response &&
                err.response.data &&
                err.response.data.message == 'Entry not found in the datastore.'
            ) {
                replied = true
                return interaction.reply({
                    content: `No character found with ID ${reqData.Character}`,
                    ephemeral: true
                });
            }
            console.log(err.response);
        });

        const MESSAGE_RESPONSE = await AXIOS.post(
            `${CONFIG.APIMSPrefix}${CONFIG.ExperienceId}/topics/NameRequest`,
            {
                'message': JSON.stringify({
                    'ID': reqData.Character,
                    'Status': 'Rejected',
                    'Reason': reason
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
            NameRequests[request].Processed = true;
            UTIL.writeJSON('./namerequests.json', NameRequests);

            CLIENT.channels.cache.get(CONFIG.RequestPostChannel).messages.fetch(
                reqData.RequestMessage
            ).then(message => {
                message.edit({embeds: [new EmbedBuilder()
                    .setTitle(`Rejected name request from ${reqData.Player}`)
                    .setColor(0xBF1A2F)
                    .addFields(
                        {
                            'name': 'Request ID',
                            'value': `${request}`
                        },
                        {
                            'name': 'First name',
                            'value': `"${reqData.First}"`,
                            'inline': true
                        },
                        {
                            'name': 'Last name',
                            'value': `"${reqData.Last}"`,
                            'inline': true
                        },
                        {
                            'name': 'Gender',
                            'value': reqData.Gender,
                            'inline': true
                        }
                    )
                    .setFooter({
                        'text': `Name rejected by ${interaction.user.username}`
                        + `\nReason: ${reason}`
                    })
                    .setTimestamp()]})
            }).catch(err => {
                console.log(`Error with editing past message: ${err}`);
            });

            return interaction.reply({
                content: `Rejected name ${reqData.First} ${reqData.Last} `
                + `with request ID ${request} for ${reqData.Player}`,
                ephemeral: true
            })
        }
    } else if (interaction.commandName === 'editname') {
        let reason = interaction.options.getString('reason');
        let first = interaction.options.getString('first');
        let last = interaction.options.getString('last');

        let newData = {};
        for (let [key, value] of Object.entries(RESPONSE.data))
            newData[key] = value;
        if (newData.hasOwnProperty('Rejected')) delete newData['Rejected'];
        newData.Approved = true;
        newData.Edited = reason;
        newData.FirstName = first;
        newData.LastName = last;

        newData = JSON.stringify(newData);
        let hashedData = await CRYPTO.createHash('md5').update(newData).digest(
            'base64'
        );
        
        const EDIT_RESPONSE = await AXIOS.post(
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
                err.response &&
                err.response.data &&
                err.response.data.message == 'Entry not found in the datastore.'
            ) {
                replied = true
                return interaction.reply({
                    content: `No character found with ID ${reqData.Character}`,
                    ephemeral: true
                });
            }
            console.log(err.response);
        });

        const MESSAGE_RESPONSE = await AXIOS.post(
            `${CONFIG.APIMSPrefix}${CONFIG.ExperienceId}/topics/NameRequest`,
            {
                'message': JSON.stringify({
                    'ID': reqData.Character,
                    'Status': 'Edited',
                    'Reason': reason,
                    'FirstName': first,
                    'LastName': last
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

        if (!replied && EDIT_RESPONSE && EDIT_RESPONSE.data) {
            NameRequests[request].Processed = true;
            UTIL.writeJSON('./namerequests.json', NameRequests);

            CLIENT.channels.cache.get(CONFIG.RequestPostChannel).messages.fetch(
                reqData.RequestMessage
            ).then(message => {
                message.edit({embeds: [new EmbedBuilder()
                    .setTitle(`Edited name request from ${reqData.Player}`)
                    .setColor(0xF7D002)
                    .addFields(
                        {
                            'name': 'Request ID',
                            'value': `${request}`
                        },
                        {
                            'name': 'First name',
                            'value': `"${reqData.First}" to "${first}"`,
                            'inline': true
                        },
                        {
                            'name': 'Last name',
                            'value': `"${reqData.Last}" to "${last}"`,
                            'inline': true
                        },
                        {
                            'name': 'Gender',
                            'value': reqData.Gender,
                            'inline': true
                        }
                    )
                    .setFooter({
                        'text': `Name edited by ${interaction.user.username}`
                        + `\nReason: ${reason}`
                    })
                    .setTimestamp()]})
            }).catch(err => {
                console.log(`Error with editing past message: ${err}`);
            });

            return interaction.reply({
                content: `Edited name ${reqData.First} ${reqData.Last} `
                + `to ${first} ${last} with request ID ${request} `
                + `for ${reqData.Player}`,
                ephemeral: true
            })
        }
    }
}

exports.Process = async function(CLIENT, message) {
    let content = message.content;
    let playerStart = content.search(RESPONSE_FORMAT.Player);
    let firstStart = content.search(RESPONSE_FORMAT.First);
    let lastStart = content.search(RESPONSE_FORMAT.Last);
    let genderStart = content.search(RESPONSE_FORMAT.Gender);
    let idStart = content.search(RESPONSE_FORMAT.Character);

    let player = content.substring(
        playerStart + RESPONSE_FORMAT.Player.length,
        firstStart
    );
    let first = content.substring(
        firstStart + RESPONSE_FORMAT.First.length,
        lastStart
    );
    let last = content.substring(
        lastStart + RESPONSE_FORMAT.Last.length,
        genderStart
    );
    let gender = content.substring(
        genderStart + RESPONSE_FORMAT.Gender.length,
        idStart
    );
    let character = content.substring(
        idStart + RESPONSE_FORMAT.Character.length
    );

    let RequestEmbed = new EmbedBuilder()
        .setTitle(`Name request from ${player}`)
        .addFields(
            {
                'name': 'Request ID',
                'value': `${NameRequests.length}`
            },
            {
                'name': 'First name',
                'value': `"${first}"`,
                'inline': true
            },
            {
                'name': 'Last name',
                'value': `"${last}"`,
                'inline': true
            },
            {
                'name': 'Gender',
                'value': gender,
                'inline': true
            }
        )
        .setFooter({
            'text': 'To approve this name, use the /approvename command.\n'
            + 'To reject this name, use the /rejectname command.\n'
            + 'To approve an edited version of this name, use the /editname ' 
            + 'command.'
        });
    CLIENT.channels.cache.get(CONFIG.RequestPostChannel).send({
        embeds: [RequestEmbed]
    }).then(message => {
        NameRequests.push({
            Player: player,
            First: first,
            Last: last,
            Gender: gender,
            Character: character,
            RequestMessage: message.id
        });
        UTIL.writeJSON('./namerequests.json', NameRequests);
    });
    message.delete();
}