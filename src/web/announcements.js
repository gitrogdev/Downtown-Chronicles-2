let AXIOS = require('axios');

let CONFIG = require('./config.json');

exports.DTC2Startup = async function(CLIENT, interaction) {
    AXIOS.post(CONFIG.DTC2Startups, {
        content: `<@&${CONFIG.ReactionRoles['🧐']}>`,
        embeds: [{
            'author': {
                'name': interaction.user.username,
                'icon_url': interaction.user.avatarURL()
            },
            'title': 'Downtown Chronicles 2 Server Startup',
            'description': interaction.user.username
                + ' is hosting a startup on Downtown Chronicles 2!\n\n'
                + CONFIG.DTC2Game
        }]
    });
    interaction.reply({
        content: 'Announced startup on Downtown Chronicles 2.',
        ephemeral: true
    })
}

exports.WriteNews = async function(CLIENT, interaction) {
    AXIOS.post(CONFIG.BloxNews, {
        content: `<@&${CONFIG.ReactionRoles['📰']}>`,
        embeds: [{
            'title': 'Downtown Chronicler: Independent Journalism from South '
             + 'Bloxford!',
            'description': interaction.options.getString('message')
                + '\n\n*We\'re a team of independent journalists based in '
                + 'Bloxford, under the flag of the Republic of Bloxell. Our '
                + 'goal is to accurately report happenings across Bloxell, '
                + 'free from northern censorship. If you\'d like to support '
                + 'our work, you can visit our Bloxford office!* '
                + '<:flag_bx:1223550315014656020>'
        }]
    });
    interaction.reply({
        content: 'Posted story to In Character News channels.',
        ephemeral: true
    })
}